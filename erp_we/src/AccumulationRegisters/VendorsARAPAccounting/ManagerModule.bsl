#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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

EndProcedure

// End StandardSubsystems.AccessManagement

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	GroupOfTypeOfNotificationsARAPAccounting = UserNotificationsOfEvents.NotificationTypeGroup("SettlementsWithSuppliers");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "bd8bbddb-fdc1-4629-b533-f3c6ceeca4f8";
	NewTypeOfAlerts.Description = NStr("vi = 'Lập chứng từ thanh toán cho nhà cung cấp';
										|ru = 'Оформление оплаты поставщику';
										|en = 'Creation of payment to vendor'; fa = 'Creation of payment to vendor';
										|it = 'Creation of payment to vendor';
										|pl = 'Creation of payment to vendor';
										|tr = 'Tedarikçiye ödemenin düzenlenmesi'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.VendorsARAPAccounting.Templates.Notifications_PaymentReceipt.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã lập chứng từ thanh toán cho nhà cung cấp với số tiền [PaymentAmount] [Currency] [PaymentDate]. [DocumentPayments]';
												|ru = 'Оформлена оплата поставщику на сумму [PaymentAmount] [Currency] [PaymentDate]. [DocumentPayments]';
												|en = 'Payment to vendor is registered in the amount of [PaymentAmount] [Currency] on [PaymentDate]. [DocumentPayments]';
												|it = 'Payment to vendor is registered in the amount of [PaymentAmount] [Currency] on [PaymentDate]. [DocumentPayments]';
												|pl = 'Payment to vendor is registered in the amount of [PaymentAmount] [Currency] on [PaymentDate]. [DocumentPayments]';
												|tr = '[PaymentDate] [PaymentAmount] [Currency] tutarında tedarikçiye ödeme düzenlendi. [DocumentPayments]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	
EndProcedure

#EndRegion

#Region BackdateJobQueue

// Data for the formation of tasks of non-operational additional verification of documents and the distribution of mutual settlements.
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
	
	If Not TempTablesManager = Undefined Then

		For Each CurrentTypeOfTask In KindsOfTasks Do

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordBalanceSheetStatementRegisterRecords Then
				
				DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
				
				If ExchangePlans.MasterNode() = Undefined
					And Not TempTablesManager = Undefined 
					And TempTablesManager.Tables.Find("QueueDataForAdditionalDocumentsManBalance") <> Undefined Then
					DataTable = TempTablesManager.Tables["QueueDataForAdditionalDocumentsManBalance"].GetData().Unload();
				EndIf;
				
				Return DataTable;
				
			EndIf;

			If CurrentTypeOfTask = Catalogs.BackdateJobKinds.ARAPAllocationByDueDates Then
				DataTable = InformationRegisters.JobsForARAPAllocating.TaskGenerationTable();
				If TempTablesManager.Tables.Find("TasksForDistributionOfMutualSettlementsSuppliers") <> Undefined Then
					RawData = TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsSuppliers"].GetData().Unload();

					For Each Record In RawData Do
						NewRow = DataTable.Add();
						FillPropertyValues(NewRow, Record);
						NewRow.RecordDate = CurrentSessionDate();
						NewRow.ChangeControlPeriod = Record.PeriodForMonitoringChangesAndCreatingTasks;
					EndDo;
				EndIf;
				
				Return DataTable;
			EndIf;
		EndDo;

	EndIf;

	Return DataTable;
	
EndFunction

// Generates the text of the request to receive data for registering tasks in the register of the queue "Tasks for the distribution of mutual settlements".
// The tasks in the queue register will be generated according to the RegisteredRecords change table, as well as according to the Registered Records of the documents of this register of settlements 
// located in the chain after the mutual settlements changed by the same distribution granules (analytics Accounting partners, object accounts, Currency).
// 
// Returns:
//  String - Query text
Function QueryTextDataForRegistrationOfTasksForDistributionOfSettlements() Export
	
	QueryText = "
	|SELECT
	|	MIN(BEGINOFPERIOD(CASE WHEN VendorsARAPAccountingChanges.Sum = 0
	|								AND (VendorsARAPAccountingChanges.AmountDue <> 0 OR VendorsARAPAccountingChanges.ToReceive <> 0)
	|								AND VALUETYPE(VendorsARAPAccountingChanges.Document) <> TYPE(Document.OBEntry)
	|								AND VALUETYPE(VendorsARAPAccountingChanges.Document) <> TYPE(Document.OBEntryARAP)
	|							THEN VendorsARAPAccountingChanges.RecorderDate
	|							ELSE VendorsARAPAccountingChanges.Period
	|						END, DAY)) AS Period,
	|	MIN(CASE
	|			WHEN &DoNotCheckBanDateAndDoNotCreateChildTasks
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE BEGINOFPERIOD(VendorsARAPAccountingChanges.Period, DAY)
	|		END) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	VendorsARAPAccountingChanges.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	VendorsARAPAccountingChanges.ARAPObject AS ARAPObject,
	|	VendorsARAPAccountingChanges.Currency AS Currency
	|INTO MinimumChangePeriodsSuppliers
	|FROM
	|	VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
	|WHERE
	|	(VendorsARAPAccountingChanges.Sum <> 0
	|	OR VendorsARAPAccountingChanges.AmountDue <> 0
	|	OR VendorsARAPAccountingChanges.ToReceive <> 0
	|	OR VendorsARAPAccountingChanges.SumCompl <> 0
	|	OR VendorsARAPAccountingChanges.SumMan <> 0)
	|	AND &NewCalculations
	|	AND &CreateTasksForDistributionOfMutualSettlements
	|GROUP BY
	|	VendorsARAPAccountingChanges.AccountingDimensionByPartners,
	|	VendorsARAPAccountingChanges.ARAPObject,
	|	VendorsARAPAccountingChanges.Currency
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency;
	|SELECT
	|	MIN(AssignmentsForDistribution.TaskPeriod) AS TaskPeriod,
	|	MIN(AssignmentsForDistribution.PeriodForMonitoringChangesAndCreatingTasks) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	AssignmentsForDistribution.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	AssignmentsForDistribution.ARAPObject AS ARAPObject,
	|	AssignmentsForDistribution.Currency AS Currency,
	|	AssignmentsForDistribution.Document AS Document,
	|	AssignmentsForDistribution.Organization AS Organization
	|INTO TasksForDistributionOfMutualSettlementsSuppliers
	|FROM
	|	(SELECT
	|		CASE WHEN VendorsARAPAccounting.Sum = 0
	|				AND (VendorsARAPAccounting.AmountDue <> 0 OR VendorsARAPAccounting.ToReceive <> 0)
	|				AND VALUETYPE(VendorsARAPAccounting.Recorder) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(VendorsARAPAccounting.Recorder) <> TYPE(Document.OBEntryARAP)
	|			THEN VendorsARAPAccounting.RecorderDate
	|			ELSE VendorsARAPAccounting.Period
	|		END AS TaskPeriod,
	|		MinimumChangePeriodsSuppliers.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
	|		VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|		VendorsARAPAccounting.Currency AS Currency,
	|		VendorsARAPAccounting.Recorder AS Document,
	|		VendorsARAPAccounting.AccountingDimensionByPartners.Organization AS Organization
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|			INNER JOIN MinimumChangePeriodsSuppliers AS MinimumChangePeriodsSuppliers
	|			ON VendorsARAPAccounting.AccountingDimensionByPartners = MinimumChangePeriodsSuppliers.AccountingDimensionByPartners
	|			AND VendorsARAPAccounting.ARAPObject = MinimumChangePeriodsSuppliers.ARAPObject
	|			AND VendorsARAPAccounting.Currency = MinimumChangePeriodsSuppliers.Currency
	|			AND CASE WHEN VendorsARAPAccounting.Sum = 0
	|				AND (VendorsARAPAccounting.AmountDue <> 0 OR VendorsARAPAccounting.ToReceive <> 0)
	|				AND VALUETYPE(VendorsARAPAccounting.Recorder) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(VendorsARAPAccounting.Recorder) <> TYPE(Document.OBEntryARAP)
	|			THEN VendorsARAPAccounting.RecorderDate
	|			ELSE VendorsARAPAccounting.Period
	|			END >= MinimumChangePeriodsSuppliers.Period
	|	WHERE
	|		VendorsARAPAccounting.Active
	|		AND (VendorsARAPAccounting.Sum <> 0
	|		OR VendorsARAPAccounting.AmountDue <> 0
	|		OR VendorsARAPAccounting.ToReceive <> 0
	|		OR VendorsARAPAccounting.SumCompl <> 0
	|		OR VendorsARAPAccounting.SumMan <> 0)
	|		AND &NewCalculations
	|		AND &CreateTasksForDistributionOfMutualSettlements
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE WHEN VendorsARAPAccountingChanges.Sum = 0
	|				AND (VendorsARAPAccountingChanges.AmountDue <> 0 OR VendorsARAPAccountingChanges.ToReceive <> 0)
	|				AND VALUETYPE(VendorsARAPAccountingChanges.Document) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(VendorsARAPAccountingChanges.Document) <> TYPE(Document.OBEntryARAP)
	|			THEN VendorsARAPAccountingChanges.RecorderDate
	|			ELSE VendorsARAPAccountingChanges.Period
	|		END,
	|		CASE
	|			WHEN &DoNotCheckBanDateAndDoNotCreateChildTasks
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE BEGINOFPERIOD(VendorsARAPAccountingChanges.Period, DAY)
	|		END,
	|		VendorsARAPAccountingChanges.AccountingDimensionByPartners,
	|		VendorsARAPAccountingChanges.ARAPObject,
	|		VendorsARAPAccountingChanges.Currency,
	|		VendorsARAPAccountingChanges.Document,
	|		VendorsARAPAccountingChanges.Organization
	|	FROM
	|		VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
	|	WHERE
	|		(VendorsARAPAccountingChanges.Sum <> 0
	|		OR VendorsARAPAccountingChanges.AmountDue <> 0
	|		OR VendorsARAPAccountingChanges.ToReceive <> 0
	|		OR VendorsARAPAccountingChanges.SumCompl <> 0
	|		OR VendorsARAPAccountingChanges.SumMan <> 0)
	|		AND &NewCalculations
	|		AND &CreateTasksForDistributionOfMutualSettlements) AS AssignmentsForDistribution
	|GROUP BY
	|	AssignmentsForDistribution.AccountingDimensionByPartners,
	|	AssignmentsForDistribution.ARAPObject,
	|	AssignmentsForDistribution.Currency,
	|	AssignmentsForDistribution.Document,
	|	AssignmentsForDistribution.Organization";
		
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.VendorsARAPAccounting.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.21";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("a2f265d9-44a0-4a59-a251-a9dcd21023bc");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.VendorsARAPAccounting.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.Comment = StrTemplate(NStr("ru = 'Исправляет реквизит ""%1"" для движений расчетов.
	                                              |Исправляет дату регистратора ""Бронирование"".
	                                              |Исправляет реквизит ""%2"" для движений платежей без даты погашения.
	                                              |Заполняет реквизиты курсов валют взаиморасчетов и упр. учета.';
	                                              |vi = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""Booking"" register date.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.';
	                                              |en = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""Booking"" register date.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.'; fa = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""Booking"" register date.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.';
	                                              |it = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""Booking"" register date.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.';
	                                              |pl = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""Booking"" register date.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.';
	                                              |tr = 'Alacak/Borç muhasebesi işlemleri için ""%1"" özniteliğini düzeltir.
	                                              |""Rezervasyon"" kayıt tarihini düzeltir.
	                                              |Geri ödeme tarihi olmayan ödeme işlemleri için ""%2"" özniteliğini düzeltir.
	                                              | Karşılıklı hesaplaşmalar ve yönetim muhasebesi için döviz kuru alanlarını doldurur.'"),
		Metadata.AccumulationRegisters.VendorsARAPAccounting.Attributes.OperationProcedure.Presentation(),
		Metadata.AccumulationRegisters.VendorsARAPAccounting.Attributes.SettlementProcedureByPaymentDate.Presentation());
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ObjectsToLock = "";

EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.VendorsARAPAccounting";
	
	TypesArray = New Array;
	For Each TypeOfRegistrar In Metadata.AccumulationRegisters.VendorsARAPAccounting.StandardAttributes.Recorder.Type.Types() Do
		TypesArray.Add(Metadata.FindByType(TypeOfRegistrar).FullName());
	EndDo;
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = StrConcat(TypesArray, ",");
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	#Region QueryText
	Query.Text = "
	|// Correct the date of the Recorder of the ""Booking"" documents
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|INTO TTToProcessing
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN Document.ElectronicTicketTransaction AS ElectronicTicketTransaction
	|		ON Calculations.Recorder = ElectronicTicketTransaction.Ref
	|WHERE
	|	NOT Calculations.Period = Calculations.RecorderDate
	|
	|UNION ALL
	|
	|// CorrectionOfPaymentOperationProceduresWithoutRepaymentDate
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.PaymentDate = DATETIME(1,1,1)
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND Calculations.Sum > 0
	|	AND CAST(LEFT(Calculations.SettlementProcedureByPaymentDate, 4) AS STRING(4))<> ""3000""
	|
	|UNION ALL
	|
	|// CorrectionOfOfOperationProceduresForEnteringAdvanceBalances
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	(Calculations.Recorder REFS Document.OBEntryARAP
	|		OR Calculations.Recorder REFS Document.OBEntry)
	|	AND Calculations.Period <> Calculations.RecorderDate
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND Calculations.RecorderDate >= DATETIME(2010,1,1)
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
	|
	|UNION ALL
	|
	|// CorrectionOfOrdersOfOperationStorno
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND SUBSTRING(Calculations.OperationProcedure, 9, 1) = ""1""
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND SUBSTRING(Calculations.OperationProcedure, 9, 1) = ""9""
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	VendorsARAPAccounting.Sum <> 0
	|	AND VendorsARAPAccounting.SumCompl <> 0
	|	AND VendorsARAPAccounting.Currency <> Companies.LocalAccountingCurrency
	|	AND VendorsARAPAccounting.DocumentCurrency <> Companies.LocalAccountingCurrency
	|	AND VendorsARAPAccounting.RateARAPCurrencyNumerator = 0
	|	AND VendorsARAPAccounting.RateARAPCurrencyDenominator = 0
	|	AND NOT VendorsARAPAccounting.BusinessOperation IN (&ManualCourseOfOperations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency
	|		ON VendorsARAPAccounting.Currency <> ManagementAccountingCurrency.Value
	|			AND VendorsARAPAccounting.DocumentCurrency <> ManagementAccountingCurrency.Value
	|WHERE
	|	VendorsARAPAccounting.Sum <> 0
	|	AND VendorsARAPAccounting.SumMan <> 0
	|	AND VendorsARAPAccounting.ExchangeRateNumeratorOfManSCurrency = 0
	|	AND VendorsARAPAccounting.ExchangeRateDenominatorCurrencyMan = 0
	|	AND NOT VendorsARAPAccounting.BusinessOperation IN (&ManualCourseOfOperations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	VALUETYPE(VendorsARAPAccounting.Recorder) IN (TYPE(Document.OBEntry), TYPE(Document.OBEntryARAP))
	|	AND VendorsARAPAccounting.Sum <> 0
	|	AND VendorsARAPAccounting.SumCompl <> 0
	|	AND VendorsARAPAccounting.Currency <> Companies.LocalAccountingCurrency
	|	AND VendorsARAPAccounting.RateARAPCurrencyNumerator = 0
	|	AND VendorsARAPAccounting.RateARAPCurrencyDenominator = 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	VendorsARAPAccounting.Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency
	|		ON VendorsARAPAccounting.Currency <> ManagementAccountingCurrency.Value
	|WHERE
	|	VALUETYPE(VendorsARAPAccounting.Recorder) IN (TYPE(Document.OBEntry), TYPE(Document.OBEntryARAP))
	|	AND VendorsARAPAccounting.Sum <> 0
	|	AND VendorsARAPAccounting.SumMan <> 0
	|	AND VendorsARAPAccounting.ExchangeRateNumeratorOfManSCurrency = 0
	|	AND VendorsARAPAccounting.ExchangeRateDenominatorCurrencyMan = 0
	|
	|UNION ALL
	|
	|// CleaningReceiversOfSourcesFromStorno
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND Calculations.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|
	|INDEX BY 
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// CorrectionOfOperationProceduresForTransferringCalculations
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder,
	|	Register3.IBDocumentNumber AS DocumentNumber
	|INTO TTToReceiveNumbers
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Calculations.Recorder = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|		LEFT JOIN TTToProcessing AS TTToProcessing
	|		ON Calculations.Recorder = TTToProcessing.Recorder
	|			AND TTToProcessing.Recorder IS NULL
	|WHERE
	|	NOT Calculations.ReversingEntry
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|
	|UNION ALL
	|
	|// CorrectionOfOrdersOfOperationStorno
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder,
	|	Register3.IBDocumentNumber AS DocumentNumber
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Calculations.Recorder = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|		LEFT JOIN TTToProcessing AS TTToProcessing
	|		ON Calculations.Recorder = TTToProcessing.Recorder
	|			AND TTToProcessing.Recorder IS NULL
	|WHERE
	|	Calculations.ReversingEntry
	|
	|UNION ALL
	|
	|// CorrectionOfProceduresOfOperationShipment
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder,
	|	Register3.IBDocumentNumber AS DocumentNumber
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Calculations.Recorder = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|		LEFT JOIN TTToProcessing AS TTToProcessing
	|		ON Calculations.Recorder = TTToProcessing.Recorder
	|			AND TTToProcessing.Recorder IS NULL
	|WHERE
	|	Calculations.SettlementTransaction = VALUE(Enum.SettlementOperations.Shipment)
	|
	|UNION ALL
	|
	|// CorrectionOfProceduresOfOperationTransferOfDebtOnCD
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder,
	|	Register3.IBDocumentNumber AS DocumentNumber
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Calculations.Recorder = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|		LEFT JOIN TTToProcessing AS TTToProcessing
	|		ON Calculations.Recorder = TTToProcessing.Recorder
	|			AND TTToProcessing.Recorder IS NULL
	|WHERE
	|	Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|	AND NOT VALUETYPE(Calculations.Recorder) IN (TYPE(Document.ReturnOfGoodsToVendor),
	|	                                         TYPE(Document.IntercompanyGoodsReturn),
	
	|	                                         TYPE(Document.ElectronicTicketTransaction))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTToReceiveNumbers.Recorder AS Recorder,
	|	CAST(ISNULL(TTToReceiveNumbers.DocumentNumber, """") AS STRING) AS DocumentNumber
	|INTO TTNumbersFilledInAccordingToRegistry
	|FROM
	|	TTToReceiveNumbers AS TTToReceiveNumbers
	|WHERE
	|	STRINGLENGTH(CAST(ISNULL(TTToReceiveNumbers.DocumentNumber, """") AS STRING)) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTToReceiveNumbers.Recorder AS Recorder
	|FROM
	|	TTToReceiveNumbers AS TTToReceiveNumbers
	|WHERE
	|	STRINGLENGTH(CAST(ISNULL(TTToReceiveNumbers.DocumentNumber, """") AS STRING) ) = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTToReceiveNumbers
	|";
	#EndRegion
	
	Query.SetParameter("ManualCourseOfOperations", OnlineARAPAccountingServer.BusinessOfOperationsWithManualCourse());
	RecordersWithBlankNumbers = Query.Execute().Unload().UnloadColumn("Recorder");
	RecordersWithNumbers = Common.ObjectsAttributeValue(
		RecordersWithBlankNumbers,
		Metadata.Documents.VendorInvoice.StandardAttributes.Number.Name); 
	VTRecordersWithNumbers = New ValueTable;
	VTRecordersWithNumbers.Columns.Add("Recorder",
		New TypeDescription(Metadata.AccumulationRegisters.VendorsARAPAccounting.StandardAttributes.Recorder.Type.Types()));
	VTRecordersWithNumbers.Columns.Add("DocumentNumber", New TypeDescription("String"));
	For Each KeyAndValue In RecordersWithNumbers Do
		If Not ValueIsFilled(KeyAndValue.Value) Then
			Continue;
		EndIf;
		NewRow = VTRecordersWithNumbers.Add();
		NewRow.Recorder = KeyAndValue.Key;
		NewRow.DocumentNumber = KeyAndValue.Value;
	EndDo;
	
	Query.SetParameter("VTRecordersWithNumbers", VTRecordersWithNumbers);
	#Region QueryText
	Query.Text = "
	|SELECT
	|	Table.Recorder AS Recorder,
	|	CAST(Table.DocumentNumber AS STRING) AS DocumentNumber
	|INTO TTNumbersFilledOutOutsideRequest
	|FROM
	|	&VTRecordersWithNumbers AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Recorder AS Recorder,
	|	Table.DocumentNumber AS DocumentNumber
	|INTO TTNumbers
	|FROM
	|	TTNumbersFilledOutOutsideRequest AS Table
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Recorder AS Recorder,
	|	Table.DocumentNumber AS DocumentNumber
	|FROM
	|	TTNumbersFilledInAccordingToRegistry AS Table
	|
	|INDEX BY 
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// Documents for processing found before receiving numbers
	|SELECT DISTINCT
	|	TTToProcessing.Recorder AS Recorder
	|FROM
	|	TTToProcessing AS TTToProcessing
	|
	|UNION ALL
	|
	|// Storno with the completed order of operations inside the document
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.ReversingEntry
	|	AND STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 1) <> """"
	|
	|UNION ALL
	|
	|// Documents with extra characters in the order of operation within the document
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND STRINGLENGTH(SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 2)) > 1
	|
	|UNION ALL
	|
	|// Sources with no order of operation within the document
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND NOT Calculations.ReversingEntry
	|	AND STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND STRINGLENGTH(SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 2)) = 0
	|
	|UNION ALL
	|
	|// Receivers with no order of operation inside the document
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.CorPartnerAccountingDimension <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|	AND NOT Calculations.ReversingEntry
	|	AND STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND STRINGLENGTH(SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 2)) = 0
	|
	|UNION ALL
	|
	|// Shipment with the order of operation inside document 1
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.SettlementTransaction = VALUE(Enum.SettlementOperations.Shipment)
	|	AND NOT Calculations.ReversingEntry
	|	AND STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 1) <> ""4""
	|
	|UNION ALL
	|
	|// The transfer of the task should be done of operations with the order of the operation inside the document 2
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|	AND NOT Calculations.ReversingEntry
	|	AND NOT VALUETYPE(Calculations.Recorder) IN (TYPE(Document.ReturnOfGoodsToVendor),
	|	                                         TYPE(Document.IntercompanyGoodsReturn),
	
	|	                                         TYPE(Document.ElectronicTicketTransaction))
	|	AND STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) > 0
	|	AND SUBSTRING(Calculations.OperationProcedure, STRFIND(Calculations.OperationProcedure, TTNumbers.DocumentNumber) + STRINGLENGTH(TTNumbers.DocumentNumber), 1) <> ""5""
	|";
	#EndRegion
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters, 
		Recorders,
		FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "AccumulationRegister.VendorsARAPAccounting";

	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("UpdatedData", UpdatedData);
	Query.Text = "
		|SELECT DISTINCT
		|	UpdatedData.Recorder AS Recorder
		|INTO TTToProcess
		|FROM
		|	&UpdatedData AS UpdatedData
		|INDEX BY
		|	Recorder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReferencesToProcess.Recorder AS Recorder,
		|	DocumentsRegistry.ReversedDocument AS ReversedDocument
		|INTO TTDocumentsToBeCancelled
		|FROM
		|	TTToProcess AS ReferencesToProcess
		|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			ON ReferencesToProcess.Recorder = DocumentsRegistry.Ref
		|				AND DocumentsRegistry.ReverseTransactionCorrection
		|				AND NOT DocumentsRegistry.AdditionalRecord
		|INDEX BY
		|	ReversedDocument
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReversedDocuments.Recorder AS Recorder,
		|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|	VendorsARAPAccounting.Currency AS Currency,
		|	VendorsARAPAccounting.RecordType AS RecordType,
		|	VendorsARAPAccounting.Sum AS Sum,
		|	VendorsARAPAccounting.AmountDue AS AmountDue,
		|	VendorsARAPAccounting.ToReceive AS ToReceive,
		|	SUBSTRING(VendorsARAPAccounting.OperationProcedure, 9, 1) AS TypeOfOperationForSorting
		|FROM
		|	TTDocumentsToBeCancelled AS ReversedDocuments
		|		INNER JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|			ON ReversedDocuments.ReversedDocument = VendorsARAPAccounting.Recorder
		|WHERE
		|	NOT VendorsARAPAccounting.ReversingEntry
		|	AND (VendorsARAPAccounting.Sum <> 0
		|		OR VendorsARAPAccounting.AmountDue <> 0
		|		OR VendorsARAPAccounting.ToReceive <> 0)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ReferencesToProcess.Recorder AS Recorder,
		|	DocumentsRegistry.IBDocumentNumber AS DocumentNumber
		|FROM
		|	TTToProcess AS ReferencesToProcess
		|		INNER JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|			ON ReferencesToProcess.Recorder = DocumentsRegistry.Ref
		|				AND NOT DocumentsRegistry.AdditionalRecord
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	VendorsARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Companies.LocalAccountingCurrency AS LocalAccountingCurrency
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|			INNER JOIN Catalog.Companies AS Companies
		|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
		|		ON VendorsARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	VendorsARAPAccounting.Recorder IN(SELECT T.Recorder FROM TTToProcess AS T)
		|";
	
	QueryResult = Query.ExecuteBatch();
	
	DataOfCancelledDocuments = QueryResult[2].Unload();
	DataOfCancelledDocuments.Indexes.Add("Recorder");
	DataOfCancelledDocuments.Indexes.Add("Recorder, AccountingDimensionByPartners, ARAPObject, Currency, RecordType, Sum, AmountDue, ToReceive");
	
	DocumentNumbers = QueryResult[3].Unload();
	DocumentNumbers.Indexes.Add("Recorder");
	
	LocalCurrencies = QueryResult[4].Unload();
	LocalCurrencies.Indexes.Add("AccountingDimensionByPartners");
	CurrencyOfMan = TMCommonUseCached.ConstantValue("ManagementAccountingCurrency");
	BitDepthOfWholePartOfCourse = Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.Digits
	                           - Metadata.DefinedTypes.CurrencyExchangeRate.Type.NumberQualifiers.FractionDigits;
	LimitingWholePart = Pow(10, BitDepthOfWholePartOfCourse - 1);
	
	For Each RowOfUpdatedData In UpdatedData Do
		
		UpdatedRecorder = RowOfUpdatedData.Recorder;
				
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			#Region Locks
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.VendorsARAPAccounting.RecordSet");
			LockItem.SetValue("Recorder", UpdatedRecorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			#EndRegion
			
			ExceptionReason = "BadData";
			RecordSet = CreateRecordSet();
			RecordSet.Filter.Recorder.Set(UpdatedRecorder);
			RecordSet.Read();
			
			#Region CleaningReceiversOfSourcesFromStorno
			For Each Record In RecordSet Do
				If Record.ReversingEntry 
					And (Record.ByDataOfSourceARAPObject
						Or ValueIsFilled(Record.CorPartnerAccountingDimension)
						Or ValueIsFilled(Record.CorARAPObject)
						Or ValueIsFilled(Record.DestinationAccountingDimensionByPartners)
						Or ValueIsFilled(Record.CalculationObjectReceiver)
						Or ValueIsFilled(Record.CurrencyReceiver)
						Or Record.AmountReceiver <> 0) Then
						Record.ByDataOfSourceARAPObject  = False;
						Record.CorPartnerAccountingDimension      = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
						Record.CorARAPObject                 = Catalogs.ARAPObjects.EmptyRef();
						Record.DestinationAccountingDimensionByPartners = Catalogs.DimensionKeysOfAccountingByPartners.EmptyRef();
						Record.CalculationObjectReceiver            = Catalogs.ARAPObjects.EmptyRef();
						Record.CurrencyReceiver                    = Catalogs.Currencies.EmptyRef();
						Record.AmountReceiver                     = 0;
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CorrectionOfRegistrarSDate
			If TypeOf(UpdatedRecorder) = Type("DocumentRef.ElectronicTicketTransaction") Then
				For Each Record In RecordSet Do
					If Not Record.RecorderDate = Record.Period Then
						
						Record.RecorderDate = Record.Period;
						DateAsString  = Format(Record.RecorderDate, "DF=yyyyMMdd");
						NewOrder = DateAsString + Mid(Record.OperationProcedure, 9);
						Record.OperationProcedure = NewOrder;
						
					EndIf;
				EndDo;
			EndIf;
			#EndRegion
			
			#Region CorrectionOfOrdersOfOperationsInsideDocument
			LinesDocumentNumber = DocumentNumbers.FindRows(New Structure("Recorder", UpdatedRecorder));
			If LinesDocumentNumber.Count() > 0
				And ValueIsFilled(LinesDocumentNumber[0].DocumentNumber) Then
				DocumentNumber = LinesDocumentNumber[0].DocumentNumber;
			Else
				DocumentNumber = Common.ObjectAttributeValue(UpdatedRecorder,
					Metadata.Documents.VendorInvoice.StandardAttributes.Number.Name);
			EndIf;
			AccumulationRegisters.CustomersARAPAccounting.CorrectOrderOfOperationsWithinDocument(RecordSet, DocumentNumber);
			#EndRegion
			
			#Region CorrectionOfPaymentOperationProceduresWithoutRepaymentDate
			For Each Record In RecordSet Do
				If Record.RecordType = AccumulationRecordType.Receipt
					And Record.Sum > 0 
					And Record.PaymentDate = Date(1,1,1)
					And Left(Record.SettlementProcedureByPaymentDate,4) <> "3000" Then
					Record.SettlementProcedureByPaymentDate = "30000101" + Right(Record.SettlementProcedureByPaymentDate,StrLen(Record.SettlementProcedureByPaymentDate)-8);
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CorrectionOfOfOperationProceduresForEnteringAdvanceBalances
			For Each Record In RecordSet Do
				If (TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntryARAP")
						Or TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntry"))
					And Record.RecorderDate <> Record.Period
					And Record.RecordType = AccumulationRecordType.Receipt
					And Record.RecorderDate >= Date(2010, 1, 1)
					And Left(Record.OperationProcedure, 8) <> Format(Record.Period, "DF=yyyyMMdd") Then
					
					DateAsString = Format(Record.Period, "DF=yyyyMMdd");
					Record.OperationProcedure = DateAsString + Mid(Record.OperationProcedure, 9);
					
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CorrectionOfOrdersOfOperationStorno
			RegisteredRecordsOfCancelledDocument = DataOfCancelledDocuments.FindRows(New Structure("Recorder", UpdatedRecorder));
			For Each Record In RecordSet Do
				If Record.ReversingEntry
					And (Mid(Record.OperationProcedure, 9, 1) = "1"
						Or Mid(Record.OperationProcedure, 9, 1) = "9") Then
					
					// Let's check the number of different types of operations in the movements of the document being corrected
					ThereAreDifferentTypesOfOperations = False;
					TypeOfOperationForSorting = "";
					For Each StringOfRegisteredRecords In RegisteredRecordsOfCancelledDocument Do
						If ValueIsFilled(StringOfRegisteredRecords.TypeOfOperationForSorting) Then
							If Not ValueIsFilled(TypeOfOperationForSorting) Then
								TypeOfOperationForSorting = StringOfRegisteredRecords.TypeOfOperationForSorting;
							ElsIf StringOfRegisteredRecords.TypeOfOperationForSorting <> TypeOfOperationForSorting Then
								ThereAreDifferentTypesOfOperations = True;
							EndIf;
						EndIf;
					EndDo;
					
					// If there are several different types of operations, then you need to fill in the type of operation of operation to sort
					// by key fields and resources of the document being corrected, otherwise we take the only type of operation.
					If ThereAreDifferentTypesOfOperations Then
						
						FilterStructure1 = New Structure;
						FilterStructure1.Insert("Recorder",               UpdatedRecorder);
						FilterStructure1.Insert("AccountingDimensionByPartners", Record.AccountingDimensionByPartners);
						FilterStructure1.Insert("ARAPObject",            Record.ARAPObject);
						FilterStructure1.Insert("Currency",                    Record.Currency);
						FilterStructure1.Insert("RecordType",               Record.RecordType);
						FilterStructure1.Insert("Sum",                   - Record.Sum);
						FilterStructure1.Insert("AmountDue",                 - Record.AmountDue);
						FilterStructure1.Insert("ToReceive",            - Record.ToReceive);
						
						TypesOfOperationsOnKeyFields = DataOfCancelledDocuments.FindRows(FilterStructure1);
						
						TypeOfOperationForSorting = "";
						For Each StringOfRegisteredRecords In TypesOfOperationsOnKeyFields Do
							If ValueIsFilled(StringOfRegisteredRecords.TypeOfOperationForSorting) Then
								TypeOfOperationForSorting = StringOfRegisteredRecords.TypeOfOperationForSorting;
								Break;
							EndIf;
						EndDo;
						
						Record.OperationProcedure = Left(Record.OperationProcedure, 8) 
							+ ?(ValueIsFilled(TypeOfOperationForSorting), TypeOfOperationForSorting, "2")
							+ Mid(Record.OperationProcedure, 10);
						
					Else
						
						Record.OperationProcedure = Left(Record.OperationProcedure, 8) 
							+ ?(ValueIsFilled(TypeOfOperationForSorting), TypeOfOperationForSorting, "2")
							+ Mid(Record.OperationProcedure, 10);
						
					EndIf;
					
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CompletingCourses
			For Each Record In RecordSet Do
				If Record.Sum <> 0
					And Record.SumCompl <> 0
					And Record.RateARAPCurrencyNumerator = 0
					And Record.RateARAPCurrencyDenominator = 0 Then
					LocalCurrencyString = LocalCurrencies.Find(Record.AccountingDimensionByPartners, "AccountingDimensionByPartners");
					If LocalCurrencyString <> Undefined 
						And Record.Currency <> LocalCurrencyString.LocalAccountingCurrency
						And (Record.DocumentCurrency <> LocalCurrencyString.LocalAccountingCurrency
							Or TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntry")
							Or TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntryARAP")) Then
						MutualSettlementsExchangeRate = Record.SumCompl / Record.Sum;
						NumeratorIsGiven = MutualSettlementsExchangeRate;
						DenominatorGiven = 1;
						While NumeratorIsGiven < LimitingWholePart
							And DenominatorGiven < LimitingWholePart Do
							NumeratorIsGiven = NumeratorIsGiven * 10;
							DenominatorGiven = DenominatorGiven * 10;
						EndDo;
						Record.RateARAPCurrencyNumerator = NumeratorIsGiven;
						Record.RateARAPCurrencyDenominator = DenominatorGiven;
					EndIf;
				EndIf;
				If Record.SumCompl <> 0
					And Record.SumMan <> 0
					And Record.ExchangeRateNumeratorOfManSCurrency = 0
					And Record.ExchangeRateDenominatorCurrencyMan = 0
					And Record.Currency <> CurrencyOfMan
					And (Record.DocumentCurrency <> CurrencyOfMan
						Or TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntry")
						Or TypeOf(UpdatedRecorder) = Type("DocumentRef.OBEntryARAP")) Then
					ManSExchangeRate = Record.SumCompl / Record.SumMan;
					NumeratorIsGiven = ManSExchangeRate;
					DenominatorGiven = 1;
					While NumeratorIsGiven < LimitingWholePart
						And DenominatorGiven < LimitingWholePart Do
						NumeratorIsGiven = NumeratorIsGiven * 10;
						DenominatorGiven = DenominatorGiven * 10;
					EndDo;
					Record.ExchangeRateNumeratorOfManSCurrency = NumeratorIsGiven;
					Record.ExchangeRateDenominatorCurrencyMan = DenominatorGiven;
				EndIf;
			EndDo;
			#EndRegion
			
			ResultsHaveChanged = False;
			If RecordSet.Count() > 0 Then
				ResultsHaveChanged = AccumulationRegisters.CustomersARAPAccounting.ThereAreChangesInSetResults(RecordSet);
			EndIf;
			
			If RecordSet.Modified() And Not ResultsHaveChanged Then
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
						AccumulationRegisters.CustomersARAPAccounting.ErrorMessageText(ErrorInfo(), UpdatedRecorder)
						+ Chars.LF + AccumulationRegisters.CustomersARAPAccounting.TextDoubleCheckDocumentManually());
				EndIf;
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf