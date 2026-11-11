
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region SourceDetails

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
	ReflectionParameters.DataPathLogger = "DocumentRecorder";
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.AllocationOfLongTermAssetsAndLiabilities = True;
	ReflectionParameters.DataPathConfigurationObject = "ARAPObject.FinancialAccountingGroup";
	ReflectionParameters.PathToDataLineOfBusiness = "ARAPObject.LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "ARAPObject.Department";
	ReflectionParameters.DataPathMaturityDate = "PlannedRepaymentDate";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("PrepaymentMan");
	ReflectionParameters.ManResources.Add("ARAPMan");
	ReflectionParameters.LocalResources.Add("PrepaymentLocal");
	ReflectionParameters.LocalResources.Add("DebtLocal");
	ReflectionParameters.ShaftResources.Add("Prepayment");
	ReflectionParameters.ShaftResources.Add("Debt");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Counterparties;
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.DocumentRecorder REFS Document.RetailSalesReport
		|			AND DataSourceAlias.ARAPObject.Object REFS Catalog.GiftCertificates
		|			AND DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CustomerPrepaymentSettlement)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentByGiftCard)
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	IdentifyIndicators(ReflectionParameters);
	
	ReflectionParameters.DebitCondition = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.Debt <> 0
		|		  OR DataSourceAlias.ARAPMan <> 0
		|		  OR DataSourceAlias.DebtLocal <> 0
		|			THEN DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		WHEN DataSourceAlias.Prepayment <> 0
		|		  OR DataSourceAlias.PrepaymentMan <> 0
		|		  OR DataSourceAlias.PrepaymentLocal <> 0
		|			THEN DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)
		|		ELSE FALSE
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	ReflectionParameters.ConditionCredit = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.Debt <> 0
		|		  OR DataSourceAlias.ARAPMan <> 0
		|		  OR DataSourceAlias.DebtLocal <> 0
		|			THEN DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Expense)
		|		WHEN DataSourceAlias.Prepayment <> 0
		|		  OR DataSourceAlias.PrepaymentMan <> 0
		|		  OR DataSourceAlias.PrepaymentLocal <> 0
		|			THEN DataSourceAlias.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		ELSE FALSE
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);

	Return ReflectionParameters;
	
EndFunction

// Determines the sources to clarify the account is available in the register and their properties.
//
// Parameters:
//  SourceProperties - String - "Field name" - the name of the attribute of the accumulation register, from which you plan to get the source of account refinement.
//
// Returns:
//  Map - The key is the name of the source of the invoice refinement. 
//                 Value - the structure of the properties of the invoice refinement source.
//
Function SourcesOfInvoiceRefinement(SourceProperties) Export
	
	SourcesOfInvoiceRefinement = New Map;
	
	SourcesOfInvoiceRefinement.Insert(Enums.AccountSpecificationSourceTypes.FinancialAccountingGroupOfARAP,
		New Structure(SourceProperties, "HFCCalculations"));
		
	Return SourcesOfInvoiceRefinement;
	
EndFunction

// Defines the sources of register divisions and their properties.
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDivisions() Export

	SourcesOfDivisions = New Map;
	
	SourcesOfDivisions.Insert(Enums.SourcesOfBusinessUnitsOfAnalyticalRegister.OrderDocument, "Department");

	Return SourcesOfDivisions;

EndFunction

// Defines the sources of register directions and their properties.
//
// Returns:
//  Map - The key is the name of the source. 
//                 Value - the structure of the source properties. 
//
Function SourcesOfDirections() Export

	Result = New Map;
	
	SourcesOfDirections = Enums.SourceOfLinesOfBusinessOfAnalyticalRegister;
	Result.Insert(SourcesOfDirections.CounterpartyLineOfBusiness, "CounterpartyLineOfBusiness");

	Return Result;

EndFunction

// Defines the sources of sub-content filling.
//
// Returns:
//  Array - array of register attributes.
//
Function SourcesOfExtdimension() Export

	ExtDimensionArray = New Array;
	ExtDimensionArray.Add("Partner");
	ExtDimensionArray.Add("Counterparty");
	ExtDimensionArray.Add("OrderDocument");
	ExtDimensionArray.Add("Contract");

	Return New Structure("ExtDimensionDr, ExtDimensionCr", ExtDimensionArray, ExtDimensionArray);

EndFunction

// Identifies indicators in the currency of the register.
//
// Parameters:
//  PropertiesOfIndicators - String - "Sourcecurrency" - the currency source for the register indicator.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function IndicatorsInCurrency(PropertiesOfIndicators) Export

	IndicatorsInCurrency = New Map;
	
	IndicatorsInCurrency.Insert(Enums.IndicatorsOfAnalyticalRegisters.AmountInARAPCurrency, New Structure(PropertiesOfIndicators, "Currency"));
	
	Return IndicatorsInCurrency;

EndFunction

// Identifies indicators in the currency of the register.
//
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function QuantityIndicators() Export

	QuantityIndicators = New Map;
	Return QuantityIndicators;

EndFunction

// Defines register metrics.
//
// Parameters:
//  Properties - Structure - containing keys for property Indicators and resource Properties
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentMan", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "PrepaymentLocal", "ComplCurrency"));
    ArrayOfResources.Add(New Structure(ResourceProperties, "Prepayment", "Currency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.Sum, New Structure(PropertiesOfIndicators, ArrayOfResources));
	
	Return Indicators;
	
EndFunction

#EndRegion

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
	|	ValueAllowed(T1.Organization)
	|	AND ValueAllowed(T1.Partner)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
	|	ON AccountingDimensionByPartners.DimensionKey = ThisList.AccountingDimensionByPartners
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = AccountingDimensionByPartners.Partner
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks of non-operational additional verification of documents according to temporary tables.
// 
// Parameters:
//  TempTablesManager - TempTablesManager - The data from the temporary tables will be used when creating new tasks.
//  TableName - String - Table name in MW
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalAdditionalVerificationOfDocumentsAccordingToTTData(TempTablesManager, TableName, KindsOfTasks) Export
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = "
	|SELECT DISTINCT
	|	CatalogAccountingDimensionByPartners.Organization AS Organization,
	|	DataForProcessing_.Period AS TaskPeriod,
	|	DataForProcessing_.DocumentRecorder AS Document
	|FROM
	|	TableName AS DataForProcessing_
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS CatalogAccountingDimensionByPartners
	|		ON DataForProcessing_.AccountingDimensionByPartners = CatalogAccountingDimensionByPartners.Ref
	|WHERE
	|	NOT DataForProcessing_.DocumentRecorder REFS Document.ExchangeDifferenceCalculation";
	Query.Text = StrReplace(Query.Text, "TableName", TableName);

	DataForProcessing_ = Query.Execute().Unload();

	For Each Record In DataForProcessing_ Do

		For Each CurrentTypeOfTask In KindsOfTasks Do

			NewRow = DataTable.Add();
			FillPropertyValues(NewRow, Record);
			NewRow.JobKind = CurrentTypeOfTask;

		EndDo;

	EndDo;

	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// Prepayment amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("PrepaymentMan");
	IndicatorReflectionParameters.LocalResources.Add("PrepaymentLocal");
	IndicatorReflectionParameters.ShaftResources.Add("Prepayment");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PrepaymentAmountMan, IndicatorReflectionParameters);
	
	// Postpaid amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("ARAPMan");
	IndicatorReflectionParameters.LocalResources.Add("DebtLocal");
	IndicatorReflectionParameters.ShaftResources.Add("Debt");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.PostpaymentAmount, IndicatorReflectionParameters);
	
EndProcedure

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.CustomersARAPAccountingByDueDates.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.48";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("489f7d26-6bd5-7943-a55c-3d06d325974a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.CustomersARAPAccountingByDueDates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = StrTemplate(NStr("vi = 'Xóa mục tin ""%1"" và chỉnh sửa mục tin ""%2"" đối với bản ghi kết chuyển của các chứng từ ""%3"".
	                                              |Chỉnh sửa mục tin ""%4"" đối với bản ghi kết chuyển nhập số dư đầu ứng trước.';
	                                              |ru = 'Очищает реквизит ""%1"" и исправляет реквизит ""%2"" для движений документов ""%3"".
	                                              |Исправляет реквизит ""%4"" для движений ввода начальных остатков авансов.';
	                                              |en = 'Clears the ""%1"" attribute and corrects the ""%2"" attribute for the ""%3"" document register records.
	                                              |Corrects the ""%4"" attribute for opening prepayment balance entry transfer records.'; fa = 'Clears the ""%1"" attribute and corrects the ""%2"" attribute for the ""%3"" document register records.
	                                              |Corrects the ""%4"" attribute for opening prepayment balance entry transfer records.';
	                                              |it = 'Clears the ""%1"" attribute and corrects the ""%2"" attribute for the ""%3"" document register records.
	                                              |Corrects the ""%4"" attribute for opening prepayment balance entry transfer records.';
	                                              |pl = 'Clears the ""%1"" attribute and corrects the ""%2"" attribute for the ""%3"" document register records.
	                                              |Corrects the ""%4"" attribute for opening prepayment balance entry transfer records.';
	                                              |tr = '""%1"" özniteliğini temizler ve ""%3"" belge hareketleri için ""%2"" özniteliğini düzeltir.
	                                              |Ön ödemelerin açılış bakiyelerinin giriş hareketleri için ""%4"" özniteliğini düzeltir.'"),
		Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Attributes.DocumentCurrency.Presentation(),
		Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Attributes.SettlementProcedure.Presentation(),
		Metadata.Documents.ExchangeDifferenceCalculation.Presentation(),
		Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.Attributes.OperationProcedure.Presentation());
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingByDueDates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ObjectsToLock = "";
	
EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName  = "AccumulationRegister.CustomersARAPAccountingByDueDates";

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	#Region QueryText
	Query.Text = "
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.DocumentRecorder REFS Document.ExchangeDifferenceCalculation
	|	AND (Calculations.OperationProcedure <> Calculations.SettlementProcedure
	|		OR Calculations.DocumentCurrency <> VALUE(Catalog.Currencies.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	(Calculations.DocumentRecorder REFS Document.OBEntryARAP
	|		OR Calculations.DocumentRecorder REFS Document.OBEntry)
	|	AND Calculations.Period <> Calculations.OccurrenceDate
	|	AND Calculations.SettlementRecordType IN (VALUE(Enum.TypesOfSettlementRecords.PaymentPrepaymentIncrease),
	|	                                     VALUE(Enum.TypesOfSettlementRecords.PaymentDebtDecrease))
	|	AND Calculations.OccurrenceDate >= DATETIME(2010,1,1)
	|	AND (STRING(YEAR(Calculations.Period) - 2000) <> SUBSTRING(Calculations.OperationProcedure, 3, 2)
	|		OR CASE WHEN MONTH(Calculations.Period) > 9
	|				THEN STRING(MONTH(Calculations.Period)) <> SUBSTRING(Calculations.OperationProcedure, 5, 2)
	|				ELSE STRING(MONTH(Calculations.Period)) <> SUBSTRING(Calculations.OperationProcedure, 6, 1)
	|					OR SUBSTRING(Calculations.OperationProcedure, 5, 1) <> ""0""
	|			END
	|		OR CASE WHEN DAY(Calculations.Period) > 9
	|				THEN STRING(DAY(Calculations.Period)) <> SUBSTRING(Calculations.OperationProcedure, 7, 2)
	|				ELSE STRING(DAY(Calculations.Period)) <> SUBSTRING(Calculations.OperationProcedure, 8, 1)
	|					OR SUBSTRING(Calculations.OperationProcedure, 7, 1) <> ""0""
	|			END)
	|";
	#EndRegion
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters, 
		Recorders,
		FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "AccumulationRegister.CustomersARAPAccountingByDueDates";

	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each RowOfUpdatedData In UpdatedData Do
		
		UpdatedRecorder = RowOfUpdatedData.Recorder;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			#Region Locks
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.CustomersARAPAccountingByDueDates.RecordSet");
			LockItem.SetValue("Recorder", UpdatedRecorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			#EndRegion
			
			ExceptionReason = "BadData";
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Recorder.Set(UpdatedRecorder);
			RecordSet.Read();

			#Region CorrectionOfRevaluationRegisteredRecords
			For Each Record In RecordSet Do
				If TypeOf(Record.DocumentRecorder) = Type("DocumentRef.ExchangeDifferenceCalculation")
					And (Record.OperationProcedure <> Record.SettlementProcedure
						Or Record.DocumentCurrency <> Catalogs.Currencies.EmptyRef()) Then
					Record.SettlementProcedure = Record.OperationProcedure;
					Record.DocumentCurrency = Catalogs.Currencies.EmptyRef();
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CorrectionOfOfOperationProceduresForEnteringAdvanceBalances
			For Each Record In RecordSet Do
				If (TypeOf(Record.DocumentRecorder) = Type("DocumentRef.OBEntryARAP")
						Or TypeOf(Record.DocumentRecorder) = Type("DocumentRef.OBEntry"))
					And Record.Period <> Record.OccurrenceDate
					And (Record.SettlementRecordType = Enums.TypesOfSettlementRecords.PaymentPrepaymentIncrease
						Or Record.SettlementRecordType = Enums.TypesOfSettlementRecords.PaymentDebtDecrease)
					And Record.OccurrenceDate >= Date(2010, 1, 1)
					And Left(Record.OperationProcedure, 8) <> Format(Record.Period, "DF=yyyyMMdd") Then
					
					DateAsString = Format(Record.Period, "DF=yyyyMMdd");
					Record.OperationProcedure = DateAsString + Mid(Record.OperationProcedure, 9);
					
				EndIf;
			EndDo;
			#EndRegion
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If ExceptionReason = "BadData" Then
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), UpdatedRecorder);
				If ValueIsFilled(UpdatedRecorder) Then
					InfobaseUpdate.MarkProcessingCompletion(RecordSet);
					InfobaseUpdate.FileIssueWithData(
						UpdatedRecorder,
						AccumulationRegisters.CustomersARAPAccounting.ErrorMessageText(ErrorInfo(), UpdatedRecorder));
				EndIf;
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndIf