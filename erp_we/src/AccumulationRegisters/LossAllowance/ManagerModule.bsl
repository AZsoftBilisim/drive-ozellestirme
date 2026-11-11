#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.LossAllowance.Name;
	NameOfChangeTable = "ChangesTableLossAllowance"; 
	
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	PartnerAccountingAnalyticsKeys.Organization AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
	|	INNER JOIN
	|		InformationRegister.AccountingDimensionByPartners AS PartnerAccountingAnalyticsKeys
	|	ON
	|		Table.AccountingDimensionByPartners = PartnerAccountingAnalyticsKeys.DimensionKey
	|";
	
	ParameterNameRegisterName = "RegisterName" + RegisterName;
	NameOfSectionParameter = "Section" + RegisterName;
	
	QueryText = StrReplace(QueryText,"&RegisterName", "&" + ParameterNameRegisterName);
	QueryText = StrReplace(QueryText,"&Section", "&" + NameOfSectionParameter);
	QueryText = StrReplace(QueryText,"&NameOfChangeTable", NameOfChangeTable);
	
	Query.SetParameter(ParameterNameRegisterName, RegisterName);
	Query.SetParameter(NameOfSectionParameter, "FinancialOutline");
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS T1 
	|	ON T.AccountingDimensionByPartners = T1.DimensionKey
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(T1.Organization)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	ReflectionParameters.DataPathOrganization = "AccountingDimensionByPartners.Organization";
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject = StrReplace(
		"CASE
		|		WHEN VALUETYPE(DataSourceAlias.ARAPObject) = TYPE(Catalog.ARAPObjects)
		|		AND DataSourceAlias.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|			THEN CAST(DataSourceAlias.ARAPObject AS Catalog.ARAPObjects).FinancialAccountingGroup
		|		WHEN VALUETYPE(DataSourceAlias.ARAPObject) = TYPE(Catalog.LeaseContract)
		|		AND DataSourceAlias.ARAPObject <> VALUE(Catalog.LeaseContract.EmptyRef)
		|			THEN CAST(DataSourceAlias.ARAPObject AS Catalog.LeaseContract).FinancialAccountingGroup
		|		WHEN VALUETYPE(DataSourceAlias.ARAPObject) = TYPE(Catalog.LoanAndDepositContracts)
		|		AND DataSourceAlias.ARAPObject <> VALUE(Catalog.LoanAndDepositContracts.EmptyRef)
		|			THEN CAST(DataSourceAlias.ARAPObject AS Catalog.LoanAndDepositContracts).FinancialAccountingGroup
		|		ELSE UNDEFINED
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	ReflectionParameters.PathToDataLineOfBusiness = "ARAPObject.LineOfBusiness";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("Sum");
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties;
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();

	If Not TempTablesManager = Undefined 
		And TempTablesManager.Tables.Find("QueueDataForAdditionalDocuments") <> Undefined Then
		
		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "
		|SELECT DISTINCT
		|	DataForProcessing_.TaskPeriod AS TaskPeriod,
		|	DataForProcessing_.Document AS Document,
		|	DataForProcessing_.SumMan AS SumMan,
		|	CatalogAccountingDimensionByPartners.Organization AS Organization
		|FROM
		|	QueueDataForAdditionalDocuments AS DataForProcessing_
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS CatalogAccountingDimensionByPartners
		|		ON DataForProcessing_.AccountingDimensionByPartners = CatalogAccountingDimensionByPartners.Ref";

		DataForProcessing_ = Query.Execute().Unload();

		For Each Record In DataForProcessing_ Do

			For Each CurrentTypeOfTask In KindsOfTasks Do

				If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then

					If Record.SumMan <> 0 Then
						NewRow = DataTable.Add();
						FillPropertyValues(NewRow, Record);
						NewRow.JobKind = CurrentTypeOfTask;
					EndIf;

				EndIf;

				If CurrentTypeOfTask = Catalogs.BackdateJobKinds.UpdateCounterpartyCounterpartyRegisterRecords Then
					If TypeOf(Record.Document) = Type("DocumentRef.ARAPAdjustment") Then
						NewRow = DataTable.Add();
						FillPropertyValues(NewRow, Record);
						NewRow.JobKind = CurrentTypeOfTask;
					EndIf;
				EndIf;

			EndDo;
			
		EndDo;
		
	EndIf;

	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
