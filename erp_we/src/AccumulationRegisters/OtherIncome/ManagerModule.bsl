#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.OtherIncome.Name;
	NameOfChangeTable = "ChangesTableOtherIncome"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)";

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
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathConfigurationObject = "IncomeItem.FinancialAccountingGroup";
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.PathToDataLineOfBusiness = "LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.IncomeExpenses;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.IncomeAndExpenseItem.DataPath = "IncomeItem";
	ReflectionParameters.StructureOfAnalytics.DimensionOfExpenses.Insert("Value", Undefined);
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.OtherCashReceipt)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.OtherIncome)
		|		WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.CurrencyConversion)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.ExchangeDifferencesForCashExchangeGain)
		|		WHEN DataSourceAlias.Recorder REFS Document.SaleAdjustment
		|			THEN CASE
		|				WHEN DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer)
		|					OR DataSourceAlias.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.ARAPAdjustment)
		|					THEN VALUE(Catalog.BusinessTransactionsSettings.AccountsReceivableAdjustmentWithRecognionOfOtherIncome)
		|				ELSE DataSourceAlias.BusinessTransactionSetting
		|			END
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	ReflectionParameters.DebitCondition = "FALSE";
	ReflectionParameters.ConditionCredit = "TRUE";
	
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
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.OtherIncome.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.35";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e8ea5d4b-ae61-4d81-a34e-ce03ce438a26");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.OtherIncome.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("ru = 'Заполняет регистр ""Прочие доходы"" по данным регистра ""(Не используется) Прочие доходы"".';
							|vi = 'Fills in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
							|en = 'Fills in the ""Other income"" register based on the ""(Not used) Other income"" register data.'; fa = 'Fills in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
							|it = 'Fills in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
							|pl = 'Fills in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
							|tr = '""Diğer gelirler"" kaydını ""(Kullanılmıyor) Diğer gelirler"" kaydının verilerine göre doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.NotUsedOtherIncome.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.OtherIncome.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.NotUsedOtherIncome.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.OtherIncome.ProcessDataToUpgradeToNewVersion_TasksByEndOfMonth";
	Handler.Version = "11.5.26.61";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("40473867-7bfa-4291-9ff5-147d8c5c5e64");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.OtherIncome.RegisterDataForProcessingToUpgradeToNewVersion_TasksByEndOfMonth";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("ru = 'Создает задания к закрытию месяца по данным регистра ""Прочие доходы"".';
							|vi = 'Creates jobs for month-end closing based on the ""Other income"" register data.';
							|en = 'Creates jobs for month-end closing based on the ""Other income"" register data.'; fa = 'Creates jobs for month-end closing based on the ""Other income"" register data.';
							|it = 'Creates jobs for month-end closing based on the ""Other income"" register data.';
							|pl = 'Creates jobs for month-end closing based on the ""Other income"" register data.';
							|tr = '""Diğer gelirler"" kaydının verilerine göre ay kapanışı için görevler oluşturur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.NotUsedOtherIncome.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.NotUsedOtherIncome.FullName());
	ToLock.Add(Metadata.InformationRegisters.JobsForMonthEndClosing.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName	= "AccumulationRegister.NotUsedOtherIncome";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	NotUsedOtherIncome.Recorder AS Ref
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome AS NotUsedOtherIncome
	|	LEFT JOIN AccumulationRegister.OtherIncome AS OtherIncome
	|		ON NotUsedOtherIncome.Recorder = OtherIncome.Recorder
	|WHERE
	|	OtherIncome.Recorder IS NULL
	|	AND NOT (NotUsedOtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|		AND NotUsedOtherIncome.LineOfBusiness = NotUsedOtherIncome.CorLineOfBusiness)
	|";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataForProcessingToUpgradeToNewVersion_TasksByEndOfMonth(Parameters) Export
	
	FullRegisterName	= Metadata.InformationRegisters.JobsForMonthEndClosing.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);

	Query = New Query;
	Query.Text =
	"SELECT
	|	OtherIncomeTurnover.Period AS Month,
	|	VALUE(Catalog.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness) AS Operation,
	|	OtherIncomeTurnover.Organization AS Organization
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome.Turnovers(, , Month, ) AS OtherIncomeTurnover
	|		LEFT JOIN InformationRegister.SetUpLockFromChanges AS SetUpLockFromChanges
	|		ON OtherIncomeTurnover.Organization = SetUpLockFromChanges.Organization
	|		LEFT JOIN InformationRegister.JobsForMonthEndClosing AS JobsForMonthEndClosing
	|		ON OtherIncomeTurnover.Period = JobsForMonthEndClosing.Month
	|			AND OtherIncomeTurnover.Organization = JobsForMonthEndClosing.Organization
	|			AND JobsForMonthEndClosing.Operation = VALUE(Catalog.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness)
	|WHERE
	|	JobsForMonthEndClosing.Month IS NULL
	|	AND (SetUpLockFromChanges.LockUntil IS NULL
	|		OR OtherIncomeTurnover.Period > SetUpLockFromChanges.LockUntil)
	|	AND (OtherIncomeTurnover.SumTurnover <> 0
	|			OR OtherIncomeTurnover.SumManTurnover <> 0
	|			OR OtherIncomeTurnover.SumComplTurnover <> 0)";
	
	RegisterDimensions = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, RegisterDimensions, AdditionalParameters);

EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	FullRegisterName	= "AccumulationRegister.NotUsedOtherIncome";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Recorders = UpdatedData.UnloadColumn("Recorder");
	
	Query = New Query;
	Query.SetParameter("Recorders", Recorders);
	Query.Text = 
	"SELECT
	|	NotUsedOtherIncome.Period AS Period,
	|	NotUsedOtherIncome.Recorder AS Recorder,
	|	NotUsedOtherIncome.Organization AS Organization,
	|	NotUsedOtherIncome.Department AS Department,
	|	NotUsedOtherIncome.LineOfBusiness,
	|	NotUsedOtherIncome.IncomeItem AS IncomeItem,
	|	NotUsedOtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	CASE WHEN NotUsedOtherIncome.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -NotUsedOtherIncome.Sum
	|		ELSE NotUsedOtherIncome.Sum
	|	END AS Sum,
	|	CASE WHEN NotUsedOtherIncome.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -NotUsedOtherIncome.SumCompl
	|		ELSE NotUsedOtherIncome.SumCompl
	|	END AS SumCompl,
	|	CASE
	|		WHEN NOT NotUsedOtherIncome.IncomeItem.EnteredInTaxAccounting
	|			THEN CASE
	|				WHEN NOT InventoryCost.Recorder IS NULL
	|					THEN InventoryCost.LocalCost - InventoryCost.CostTD
	|				WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|					THEN OtherAssetsAndLiabilitiesRecords.SumCompl - OtherAssetsAndLiabilitiesRecords.CostTD
	|				WHEN NOT IACost.Recorder IS NULL
	|					THEN IACost.LocalCost - IACost.CostTemporaryDifference
	|				WHEN NOT FACost.Recorder IS NULL
	|					THEN FACost.LocalCost - FACost.CostTemporaryDifference
	|				WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|					THEN IntangibleAssetsAmortizationCharge.DepreciationLocal - IntangibleAssetsAmortizationCharge.DepreciationTD
	|				WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|					THEN FixedAssetsDepreciationCharge.DepreciationLocal - FixedAssetsDepreciationCharge.DepreciationTD
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN NOT InventoryCost.Recorder IS NULL
	|				THEN InventoryCost.PermanentDifference
	|			WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|				THEN OtherAssetsAndLiabilitiesRecords.PermanentDifference
	|			WHEN NOT IACost.Recorder IS NULL
	|				THEN IACost.CostPermanentDifference
	|			WHEN NOT FACost.Recorder IS NULL
	|				THEN FACost.CostPermanentDifference
	|			WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|				THEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|			WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE 0
	|		END
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN NOT InventoryCost.Recorder IS NULL
	|			THEN InventoryCost.CostTD
	|		WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|			THEN OtherAssetsAndLiabilitiesRecords.CostTD
	|		WHEN NOT IACost.Recorder IS NULL
	|			THEN IACost.CostTemporaryDifference
	|		WHEN NOT FACost.Recorder IS NULL
	|			THEN FACost.CostTemporaryDifference
	|		WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|			THEN IntangibleAssetsAmortizationCharge.DepreciationTD
	|		WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|			THEN FixedAssetsDepreciationCharge.DepreciationTD
	|		WHEN VALUETYPE(NotUsedOtherIncome.Recorder) IN (
	|			TYPE(Document.VendorInvoiceLeasedAssets),
	|			TYPE(Document.LeaseTermAdjustment),
	|			TYPE(Document.AccrualOfLeaseInterest),
	|			TYPE(Document.ProvideAssetsToLeasee2_4),
	|			TYPE(Document.LeaseTermination))
	|		THEN NotUsedOtherIncome.SumCompl
	|		ELSE 0
	|	END AS CostTD,
	|	CASE WHEN NotUsedOtherIncome.RecordType = VALUE(AccumulationRecordType.Expense)
	|		THEN -NotUsedOtherIncome.SumMan
	|		ELSE NotUsedOtherIncome.SumMan
	|	END AS SumMan,
	|	NotUsedOtherIncome.BusinessOperation AS BusinessOperation,
	|	NotUsedOtherIncome.CalculationOfCost AS CalculationOfCost,
	|	NotUsedOtherIncome.CorLineOfBusiness AS CorLineOfBusiness,
	|	NotUsedOtherIncome.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NotUsedOtherIncome.FinRecordID AS FinRecordID,
	|	NotUsedOtherIncome.ReversingEntry AS ReversingEntry,
	|	NotUsedOtherIncome.DocumentCalculation AS DocumentCalculation,
	|	NotUsedOtherIncome.MonthEndClosingMode AS MonthEndClosingMode,
	|	NotUsedOtherIncome.SourceKind AS SourceKind
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome AS NotUsedOtherIncome
	|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
	|		ON NotUsedOtherIncome.Recorder = InventoryCost.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = InventoryCost.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = InventoryCost.Department
	|				AND NotUsedOtherIncome.Sum = InventoryCost.Cost
	|				AND NotUsedOtherIncome.IncomeItem = InventoryCost.IncomeItem
	|				AND NotUsedOtherIncome.DimensionOfRevenue = InventoryCost.DimensionOfRevenue))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = InventoryCost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = InventoryCost.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = InventoryCost.Organization
	|			AND (ISNULL(InventoryCost.PermanentDifference, 0) <> 0
	|				OR ISNULL(InventoryCost.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|		ON NotUsedOtherIncome.Recorder = OtherAssetsAndLiabilitiesRecords.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = OtherAssetsAndLiabilitiesRecords.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = OtherAssetsAndLiabilitiesRecords.Department
	|				AND NotUsedOtherIncome.Sum = OtherAssetsAndLiabilitiesRecords.SumCompl))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = OtherAssetsAndLiabilitiesRecords.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = OtherAssetsAndLiabilitiesRecords.Organization
	|			AND (ISNULL(OtherAssetsAndLiabilitiesRecords.PermanentDifference, 0) <> 0
	|				OR ISNULL(OtherAssetsAndLiabilitiesRecords.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IACost AS IACost
	|		ON NotUsedOtherIncome.Recorder = IACost.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = IACost.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = IACost.Department
	|				AND NotUsedOtherIncome.Sum = IACost.Cost))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FACost AS FACost
	|		ON NotUsedOtherIncome.Recorder = FACost.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = FACost.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = FACost.Department
	|				AND NotUsedOtherIncome.Sum = FACost.Cost))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|		ON NotUsedOtherIncome.Recorder = IntangibleAssetsAmortizationCharge.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = IntangibleAssetsAmortizationCharge.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = IntangibleAssetsAmortizationCharge.Department
	|				AND NotUsedOtherIncome.Sum = IntangibleAssetsAmortizationCharge.Depreciation))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IntangibleAssetsAmortizationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IntangibleAssetsAmortizationCharge.Organization
	|			AND (ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|		ON NotUsedOtherIncome.Recorder = FixedAssetsDepreciationCharge.Recorder
	|		AND ((NotUsedOtherIncome.FinRecordID <> """" AND NotUsedOtherIncome.FinRecordID = FixedAssetsDepreciationCharge.FinRecordID)
	|			OR (NotUsedOtherIncome.Department = FixedAssetsDepreciationCharge.Department
	|				AND NotUsedOtherIncome.Sum = FixedAssetsDepreciationCharge.Depreciation))
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FixedAssetsDepreciationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FixedAssetsDepreciationCharge.Organization
	|			AND (ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0) <> 0)
	|WHERE
	|	NotUsedOtherIncome.Recorder IN (&Recorders)
	|	AND NOT NotUsedOtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|	AND NOT NotUsedOtherIncome.Recorder REFS Document.OtherIncomeExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	NotUsedOtherIncome.Period AS Period,
	|	NotUsedOtherIncome.Recorder,
	|	NotUsedOtherIncome.Organization AS Organization,
	|	NotUsedOtherIncome.Department AS Department,
	|	NotUsedOtherIncome.LineOfBusiness,
	|	NotUsedOtherIncome.IncomeItem AS IncomeItem,
	|	NotUsedOtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	NotUsedOtherIncome.Sum AS Sum,
	|	NotUsedOtherIncome.SumCompl AS SumCompl,
	|	OtherIncome.PermanentDifference,
	|	OtherIncome.CostTD,
	|	NotUsedOtherIncome.SumMan AS SumMan,
	|	NotUsedOtherIncome.BusinessOperation AS BusinessOperation,
	|	NotUsedOtherIncome.CalculationOfCost AS CalculationOfCost,
	|	NotUsedOtherIncome.CorLineOfBusiness AS CorLineOfBusiness,
	|	NotUsedOtherIncome.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NotUsedOtherIncome.FinRecordID AS FinRecordID,
	|	NotUsedOtherIncome.ReversingEntry AS ReversingEntry,
	|	NotUsedOtherIncome.DocumentCalculation AS DocumentCalculation,
	|	NotUsedOtherIncome.MonthEndClosingMode AS MonthEndClosingMode,
	|	NotUsedOtherIncome.SourceKind AS SourceKind
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome AS NotUsedOtherIncome
	|		LEFT JOIN Document.OtherIncomeExpenses.OtherIncome AS OtherIncome
	|		ON NotUsedOtherIncome.Recorder = OtherIncome.Ref
	|			AND (NotUsedOtherIncome.FinRecordID = OtherIncome.RowID
	|					AND OtherIncome.RowID <> """"
	|				OR NotUsedOtherIncome.Department = OtherIncome.Department
	|					AND NotUsedOtherIncome.IncomeItem = OtherIncome.IncomeItem
	|					AND NotUsedOtherIncome.DimensionOfRevenue = OtherIncome.DimensionOfRevenue
	|					AND NotUsedOtherIncome.Sum = OtherIncome.Sum)
	|WHERE
	|	NotUsedOtherIncome.Recorder IN (&Recorders)
	|	AND NotUsedOtherIncome.Recorder REFS Document.OtherIncomeExpenses
	|
	|UNION ALL
	|
	|SELECT
	|	NotUsedOtherIncome.Period AS Period,
	|	NotUsedOtherIncome.Recorder,
	|	NotUsedOtherIncome.Organization AS Organization,
	|	NotUsedOtherIncome.Department AS Department,
	|	NotUsedOtherIncome.LineOfBusiness,
	|	NotUsedOtherIncome.IncomeItem AS IncomeItem,
	|	NotUsedOtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	-NotUsedOtherIncome.Sum AS Sum,
	|	-NotUsedOtherIncome.SumCompl AS SumCompl,
	|	-CASE
	|		WHEN NOT NotUsedOtherIncome.IncomeItem.EnteredInTaxAccounting
	|			THEN CASE
	|				WHEN NOT InventoryCost.Recorder IS NULL
	|					THEN InventoryCost.LocalCost - InventoryCost.CostTD
	|				WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|					THEN OtherAssetsAndLiabilitiesRecords.SumCompl - OtherAssetsAndLiabilitiesRecords.CostTD
	|				WHEN NOT IACost.Recorder IS NULL
	|					THEN IACost.LocalCost - IACost.CostTemporaryDifference
	|				WHEN NOT FACost.Recorder IS NULL
	|					THEN FACost.LocalCost - FACost.CostTemporaryDifference
	|				WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|					THEN IntangibleAssetsAmortizationCharge.DepreciationLocal - IntangibleAssetsAmortizationCharge.DepreciationTD
	|				WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|					THEN FixedAssetsDepreciationCharge.DepreciationLocal - FixedAssetsDepreciationCharge.DepreciationTD
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN NOT InventoryCost.Recorder IS NULL
	|				THEN InventoryCost.PermanentDifference
	|			WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|				THEN OtherAssetsAndLiabilitiesRecords.PermanentDifference
	|			WHEN NOT IACost.Recorder IS NULL
	|				THEN IACost.CostPermanentDifference
	|			WHEN NOT FACost.Recorder IS NULL
	|				THEN FACost.CostPermanentDifference
	|			WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|				THEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|			WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE 0
	|		END
	|	END AS PermanentDifference,
	|	-CASE
	|		WHEN NOT InventoryCost.Recorder IS NULL
	|			THEN InventoryCost.CostTD
	|		WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|			THEN OtherAssetsAndLiabilitiesRecords.CostTD
	|		WHEN NOT IACost.Recorder IS NULL
	|			THEN IACost.CostTemporaryDifference
	|		WHEN NOT FACost.Recorder IS NULL
	|			THEN FACost.CostTemporaryDifference
	|		WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|			THEN IntangibleAssetsAmortizationCharge.DepreciationTD
	|		WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|			THEN FixedAssetsDepreciationCharge.DepreciationTD
	|		ELSE 0
	|	END AS CostTD,
	|	-NotUsedOtherIncome.SumMan AS SumMan,
	|	NotUsedOtherIncome.BusinessOperation AS BusinessOperation,
	|	NotUsedOtherIncome.CalculationOfCost AS CalculationOfCost,
	|	NotUsedOtherIncome.LineOfBusiness AS CorLineOfBusiness,
	|	NotUsedOtherIncome.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NotUsedOtherIncome.FinRecordID AS FinRecordID,
	|	NotUsedOtherIncome.ReversingEntry AS ReversingEntry,
	|	NotUsedOtherIncome.DocumentCalculation AS DocumentCalculation,
	|	NotUsedOtherIncome.MonthEndClosingMode AS MonthEndClosingMode,
	|	NotUsedOtherIncome.SourceKind AS SourceKind
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome AS NotUsedOtherIncome
	|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
	|		ON NotUsedOtherIncome.Recorder = InventoryCost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = InventoryCost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = InventoryCost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = InventoryCost.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = InventoryCost.Organization
	|			AND (ISNULL(InventoryCost.PermanentDifference, 0) <> 0
	|				OR ISNULL(InventoryCost.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|		ON NotUsedOtherIncome.Recorder = OtherAssetsAndLiabilitiesRecords.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = OtherAssetsAndLiabilitiesRecords.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = OtherAssetsAndLiabilitiesRecords.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = OtherAssetsAndLiabilitiesRecords.Organization
	|			AND (ISNULL(OtherAssetsAndLiabilitiesRecords.PermanentDifference, 0) <> 0
	|				OR ISNULL(OtherAssetsAndLiabilitiesRecords.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IACost AS IACost
	|		ON NotUsedOtherIncome.Recorder = IACost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = IACost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FACost AS FACost
	|		ON NotUsedOtherIncome.Recorder = FACost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = FACost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|		ON NotUsedOtherIncome.Recorder = IntangibleAssetsAmortizationCharge.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = IntangibleAssetsAmortizationCharge.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IntangibleAssetsAmortizationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IntangibleAssetsAmortizationCharge.Organization
	|			AND (ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|		ON NotUsedOtherIncome.Recorder = FixedAssetsDepreciationCharge.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = FixedAssetsDepreciationCharge.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FixedAssetsDepreciationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FixedAssetsDepreciationCharge.Organization
	|			AND (ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0) <> 0)
	|WHERE
	|	NotUsedOtherIncome.Recorder IN (&Recorders)
	|	AND NotUsedOtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|	AND NOT NotUsedOtherIncome.LineOfBusiness = NotUsedOtherIncome.CorLineOfBusiness
	|
	|UNION ALL
	|
	|SELECT
	|	NotUsedOtherIncome.Period AS Period,
	|	NotUsedOtherIncome.Recorder,
	|	NotUsedOtherIncome.Organization AS Organization,
	|	NotUsedOtherIncome.Department AS Department,
	|	NotUsedOtherIncome.CorLineOfBusiness,
	|	NotUsedOtherIncome.IncomeItem AS IncomeItem,
	|	NotUsedOtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	NotUsedOtherIncome.Sum AS Sum,
	|	NotUsedOtherIncome.SumCompl AS SumCompl,
	|	CASE
	|		WHEN NOT NotUsedOtherIncome.IncomeItem.EnteredInTaxAccounting
	|			THEN CASE
	|				WHEN NOT InventoryCost.Recorder IS NULL
	|					THEN InventoryCost.LocalCost - InventoryCost.CostTD
	|				WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|					THEN OtherAssetsAndLiabilitiesRecords.SumCompl - OtherAssetsAndLiabilitiesRecords.CostTD
	|				WHEN NOT IACost.Recorder IS NULL
	|					THEN IACost.LocalCost - IACost.CostTemporaryDifference
	|				WHEN NOT FACost.Recorder IS NULL
	|					THEN FACost.LocalCost - FACost.CostTemporaryDifference
	|				WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|					THEN IntangibleAssetsAmortizationCharge.DepreciationLocal - IntangibleAssetsAmortizationCharge.DepreciationTD
	|				WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|					THEN FixedAssetsDepreciationCharge.DepreciationLocal - FixedAssetsDepreciationCharge.DepreciationTD
	|				ELSE 0
	|			END
	|		ELSE CASE
	|			WHEN NOT InventoryCost.Recorder IS NULL
	|				THEN InventoryCost.PermanentDifference
	|			WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|				THEN OtherAssetsAndLiabilitiesRecords.PermanentDifference
	|			WHEN NOT IACost.Recorder IS NULL
	|				THEN IACost.CostPermanentDifference
	|			WHEN NOT FACost.Recorder IS NULL
	|				THEN FACost.CostPermanentDifference
	|			WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|				THEN IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences
	|			WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|				THEN FixedAssetsDepreciationCharge.DepreciationPermanentDifferences
	|			ELSE 0
	|		END
	|	END AS PermanentDifference,
	|	CASE
	|		WHEN NOT InventoryCost.Recorder IS NULL
	|			THEN InventoryCost.CostTD
	|		WHEN NOT OtherAssetsAndLiabilitiesRecords.Recorder IS NULL
	|			THEN OtherAssetsAndLiabilitiesRecords.CostTD
	|		WHEN NOT IACost.Recorder IS NULL
	|			THEN IACost.CostTemporaryDifference
	|		WHEN NOT FACost.Recorder IS NULL
	|			THEN FACost.CostTemporaryDifference
	|		WHEN NOT IntangibleAssetsAmortizationCharge.Recorder IS NULL
	|			THEN IntangibleAssetsAmortizationCharge.DepreciationTD
	|		WHEN NOT FixedAssetsDepreciationCharge.Recorder IS NULL
	|			THEN FixedAssetsDepreciationCharge.DepreciationTD
	|		ELSE 0
	|	END AS CostTD,
	|	NotUsedOtherIncome.SumMan AS SumMan,
	|	NotUsedOtherIncome.BusinessOperation AS BusinessOperation,
	|	NotUsedOtherIncome.CalculationOfCost AS CalculationOfCost,
	|	NotUsedOtherIncome.LineOfBusiness AS CorLineOfBusiness,
	|	NotUsedOtherIncome.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	NotUsedOtherIncome.FinRecordID AS FinRecordID,
	|	NotUsedOtherIncome.ReversingEntry AS ReversingEntry,
	|	NotUsedOtherIncome.DocumentCalculation AS DocumentCalculation,
	|	NotUsedOtherIncome.MonthEndClosingMode AS MonthEndClosingMode,
	|	NotUsedOtherIncome.SourceKind AS SourceKind
	|FROM
	|	AccumulationRegister.NotUsedOtherIncome AS NotUsedOtherIncome
	|		LEFT JOIN AccumulationRegister.InventoryCost AS InventoryCost
	|		ON NotUsedOtherIncome.Recorder = InventoryCost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = InventoryCost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = InventoryCost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = InventoryCost.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = InventoryCost.Organization
	|			AND (ISNULL(InventoryCost.PermanentDifference, 0) <> 0
	|				OR ISNULL(InventoryCost.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.OtherAssetsAndLiabilitiesRecords AS OtherAssetsAndLiabilitiesRecords
	|		ON NotUsedOtherIncome.Recorder = OtherAssetsAndLiabilitiesRecords.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = OtherAssetsAndLiabilitiesRecords.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = OtherAssetsAndLiabilitiesRecords.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.ReversingEntry = OtherAssetsAndLiabilitiesRecords.ReversingEntry
	|			AND NotUsedOtherIncome.Organization = OtherAssetsAndLiabilitiesRecords.Organization
	|			AND (ISNULL(OtherAssetsAndLiabilitiesRecords.PermanentDifference, 0) <> 0
	|				OR ISNULL(OtherAssetsAndLiabilitiesRecords.CostTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IACost AS IACost
	|		ON NotUsedOtherIncome.Recorder = IACost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = IACost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FACost AS FACost
	|		ON NotUsedOtherIncome.Recorder = FACost.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = FACost.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FACost.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FACost.Organization
	|			AND (ISNULL(IACost.CostPermanentDifference, 0) <> 0
	|				OR ISNULL(IACost.CostTemporaryDifference, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.IntangibleAssetsAmortizationCharge AS IntangibleAssetsAmortizationCharge
	|		ON NotUsedOtherIncome.Recorder = IntangibleAssetsAmortizationCharge.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = IntangibleAssetsAmortizationCharge.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = IntangibleAssetsAmortizationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = IntangibleAssetsAmortizationCharge.Organization
	|			AND (ISNULL(IntangibleAssetsAmortizationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(IntangibleAssetsAmortizationCharge.DepreciationTD, 0) <> 0)
	|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge AS FixedAssetsDepreciationCharge
	|		ON NotUsedOtherIncome.Recorder = FixedAssetsDepreciationCharge.Recorder
	|			AND NotUsedOtherIncome.FinRecordID = FixedAssetsDepreciationCharge.FinRecordID
	|			AND NotUsedOtherIncome.BusinessTransactionSetting = FixedAssetsDepreciationCharge.BusinessTransactionSetting
	|			AND NotUsedOtherIncome.Organization = FixedAssetsDepreciationCharge.Organization
	|			AND (ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) <> 0
	|				OR ISNULL(FixedAssetsDepreciationCharge.DepreciationTD, 0) <> 0)
	|WHERE
	|	NotUsedOtherIncome.Recorder IN (&Recorders)
	|	AND NotUsedOtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|	AND NOT NotUsedOtherIncome.LineOfBusiness = NotUsedOtherIncome.CorLineOfBusiness
	|
	|TOTALS
	|BY
	|	Recorder";	

	SamplingLogger = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		
		Recorder = SamplingLogger.Recorder;
		ExceptionReason = "";
		Recommendation = "";
	
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("ru = 'Не удалось выполнить заполнение регистра ""Прочие доходы"" по данным регистра ""(Не используется) Прочие доходы"".';
									|vi = 'Cannot fill in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
									|en = 'Cannot fill in the ""Other income"" register based on the ""(Not used) Other income"" register data.'; fa = 'Cannot fill in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
									|it = 'Cannot fill in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
									|pl = 'Cannot fill in the ""Other income"" register based on the ""(Not used) Other income"" register data.';
									|tr = '""Diğer gelirler"" kaydının ""(Kullanılmıyor) Diğer gelirler"" kaydının verilerine göre doldurulması gerçekleştirilemedi.'"));
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.NotUsedOtherIncome.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
				
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.OtherIncome.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			
			Selection = SamplingLogger.Select();
			
			While Selection.Next() Do
				Record = RecordSet.Add();
				FillPropertyValues(Record, Selection);
			EndDo;
			
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			EndIf;
			PreviousRecordSet = AccumulationRegisters.NotUsedOtherIncome.CreateRecordSet();
			PreviousRecordSet.Filter.Recorder.Set(Recorder);
			
			InfobaseUpdate.MarkProcessingCompletion(PreviousRecordSet);

			TheStructureOfTheSearch = New Structure("Recorder", Recorder);
			Rows = UpdatedData.FindRows(TheStructureOfTheSearch);
			If Rows.Count() > 0 Then
				TMCommonUse.DeleteTableRows(UpdatedData, Rows);
			EndIf;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Recorder);
			
			If ExceptionReason = "BadData" Then
				
				InfobaseUpdate.FileIssueWithData(Recorder, Recommendation, Parameters);
				
			ElsIf ExceptionReason = "Record" Then
				
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
	
	EndDo;
	
	If UpdatedData.Count() > 0 Then 
		For Each String In UpdatedData Do 
			PreviousRecordSet = AccumulationRegisters.NotUsedOtherIncome.CreateRecordSet();
			PreviousRecordSet.Filter.Recorder.Set(String.Recorder);
			
			InfobaseUpdate.MarkProcessingCompletion(PreviousRecordSet);
		EndDo;
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "AccumulationRegister.NotUsedOtherIncome");

EndProcedure

Procedure ProcessDataToUpgradeToNewVersion_TasksByEndOfMonth(Parameters) Export

	SelectedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	RegisterMetadata = Metadata.InformationRegisters.JobsForMonthEndClosing;
	FullRegisterName= RegisterMetadata.FullName();
	
	For Each CurrentData In SelectedData Do
		Set = InformationRegisters.JobsForMonthEndClosing.CreateRecordSet();
		Set.Filter.Month.Set(CurrentData.Month);
		Set.Filter.Operation.Set(CurrentData.Operation);
		Set.Filter.Organization.Set(CurrentData.Organization);
		BeginTransaction();
		Try
			DataLock = New DataLock;
			
			LockItem= DataLock.Add(FullRegisterName);
			LockItem.SetValue("Month",   CurrentData.Month);
			LockItem.SetValue("Operation", CurrentData.Operation);
			LockItem.SetValue("Organization", CurrentData.Organization);
			
			DataLock.Lock();
			
			Record = Set.Add();
			FillPropertyValues(Record, CurrentData);
			Record.JobNumber = InformationRegisters.JobsForMonthEndClosing.GetTaskNumber();
			
			InfobaseUpdate.WriteRecordSet(Set);
			CommitTransaction();
		Except
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Set);
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
