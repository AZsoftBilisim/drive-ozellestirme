#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.GiftCertificates.Name;
	NameOfChangeTable = "ChangesTableGiftCertificates"; 
	
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	UNDEFINED AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
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
	ReflectionParameters.DataPathOrganization = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.GiftCertificate.Organization <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN DataSourceAlias.GiftCertificate.Organization
		|		WHEN DataSourceAlias.GiftCertificate.Owner.Organization <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN DataSourceAlias.GiftCertificate.Owner.Organization
		|		ELSE DataSourceAlias.Recorder.Organization
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.InversionOfRegisteredRecords = True;
	ReflectionParameters.DataPathCurrency = "GiftCertificate.Owner.Currency";
	ReflectionParameters.LocalResources.Add("0");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("Sum");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Partner.DataPath = "GiftCertificate.Partner";
	ReflectionParameters.StructureOfAnalytics.Counterparty.DataPath = "GiftCertificate.Counterparty";
	ReflectionParameters.StructureOfAnalytics.ARAPObject.DataPath = "GiftCertificate.ARAPObject";
	ReflectionParameters.StructureOfAnalytics.Contract.Insert("Value", Undefined);
	ReflectionParameters.StructureOfAnalytics.ARAPDocument.Insert("Value", Undefined);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
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
	TempTablesManager, DataForRegisteringTasks = Undefined) Export

	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();

	If KindsOfTasks.Find(Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) <> Undefined Then

		Query = New Query;
		Query.TempTablesManager = TempTablesManager;
		Query.Text = "
		|SELECT DISTINCT
		|	DataForProcessing_.TaskPeriod AS TaskPeriod,
		|	DataForProcessing_.Document AS Document,
		|	GiftCertificates.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords) AS JobKind
		|FROM
		|	QueueDataForAdditionalDocumentsManBalance AS DataForProcessing_
		|		INNER JOIN Catalog.GiftCertificates AS GiftCertificates
		|		ON DataForProcessing_.GiftCertificate = GiftCertificates.Ref
		|WHERE
		|	GiftCertificates.Organization <> VALUE(Catalog.Companies.EmptyRef)";

		DataTable = Query.Execute().Unload();

		For Each CurrentTypeOfTask In KindsOfTasks Do

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then

				Return DataTable;

			EndIf;

		EndDo;

	EndIf;

	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion
	
#Region InterfaceImplementation

#EndRegion

#Region Private

#Region InfobaseUpdate

#EndRegion

#EndRegion

#EndIf