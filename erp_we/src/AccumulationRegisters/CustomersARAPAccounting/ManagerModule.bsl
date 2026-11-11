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

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	GroupOfTypeOfNotificationsARAPAccounting = UserNotificationsOfEvents.NotificationTypeGroup("SettlementsWithClients");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "427cb1f4-48be-44a1-9384-874a73f96380";
	NewTypeOfAlerts.Description = NStr("vi = 'Nhận thanh toán từ khách hàng';
										|ru = 'Поступление оплаты от клиента';
										|en = 'Customer payment'; fa = 'Customer payment';
										|it = 'Pervenimento di pagamento dal cliente';
										|pl = 'Wpływ płatności od klienta';
										|tr = 'Müşteriden ödeme alınması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.Nonexclusive;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccounting.Templates.Notifications_PaymentReceipt.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã nhận khoản thanh toán với số tiền [PaymentAmount] [Currency] [PaymentDate]. [DocumentPayments]';
												|ru = 'Поступила оплата на сумму [PaymentAmount] [Currency] [PaymentDate]. [DocumentPayments]';
												|en = 'Payment in the amount of [PaymentAmount] [Currency] is received on [PaymentDate]. [DocumentPayments]';
												|it = 'Payment in the amount of [PaymentAmount] [Currency] is received on [PaymentDate]. [DocumentPayments]';
												|pl = 'Payment in the amount of [PaymentAmount] [Currency] is received on [PaymentDate]. [DocumentPayments]';
												|tr = '[PaymentDate] [PaymentAmount] [Currency] tutarında ödeme alındı. [DocumentPayments]'"; // @NStr-1
	UserNotificationsOfEvents.AddDescriptionOfDataSource(NewTypeOfAlerts,
		Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
		
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = GroupOfTypeOfNotificationsARAPAccounting;
	NewTypeOfAlerts.Id = "f1ebc4d4-2e23-49f3-8fdf-677a69c3cdf6";
	NewTypeOfAlerts.Description = NStr("vi = 'Vượt hạn mức công nợ theo hợp đồng';
										|ru = 'Превышение лимита задолженности по договору';
										|en = 'Debt limit is exceeded under the contract'; fa = 'Debt limit is exceeded under the contract';
										|it = 'Debt limit is exceeded under the contract';
										|pl = 'Debt limit is exceeded under the contract';
										|tr = 'Sözleşme kapsamındaki borç limitinin aşılması'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.AccumulationRegisters.CustomersARAPAccounting.Templates.Notifications_DebtLimitIsExceeded.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Đã vượt hạn mức công nợ trong [AllowableAmountPayable] [Currency] theo hợp đồng với [ExcessAmount] [Currency]';
												|ru = 'Превышен лимит задолженности в [AllowableAmountPayable] [Currency] по договору на [ExcessAmount] [Currency]';
												|en = 'The debt limit of [AllowableAmountPayable] [Currency] is exceeded for [ExcessAmount] [Currency] under the contract';
												|it = 'The debt limit of [AllowableAmountPayable] [Currency] is exceeded for [ExcessAmount] [Currency] under the contract';
												|pl = 'The debt limit of [AllowableAmountPayable] [Currency] is exceeded for [ExcessAmount] [Currency] under the contract';
												|tr = '[ExcessAmount] [Currency] için sözleşme kapsamında [AllowableAmountPayable] [Currency] borç limiti aşıldı'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đã vượt hạn mức công nợ theo hợp đồng.';
												|ru = 'Превышен лимит задолженности по договорам.';
												|en = 'The debt limit under contracts is exceeded.';
												|it = 'The debt limit under contracts is exceeded.';
												|pl = 'The debt limit under contracts is exceeded.';
												|tr = 'Sözleşmeler kapsamındaki borç limiti aşıldı.'"; // @NStr-1
	
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
				If TempTablesManager.Tables.Find("TasksForDistributionOfMutualSettlementsClients") <> Undefined Then
					RawData = TempTablesManager.Tables["TasksForDistributionOfMutualSettlementsClients"].GetData().Unload();

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
	
	QueryText = 
	"SELECT
	|	MIN(BEGINOFPERIOD(CASE WHEN SettlementsWithCustomersChanges.Sum = 0
	|								AND (SettlementsWithCustomersChanges.AmountDue <> 0 OR SettlementsWithCustomersChanges.ToShip <> 0)
	|								AND VALUETYPE(SettlementsWithCustomersChanges.Document) <> TYPE(Document.OBEntry)
	|								AND VALUETYPE(SettlementsWithCustomersChanges.Document) <> TYPE(Document.OBEntryARAP)
	|							THEN SettlementsWithCustomersChanges.RecorderDate
	|							ELSE SettlementsWithCustomersChanges.Period
	|						END, DAY)) AS Period,
	|	MIN(CASE
	|			WHEN &DoNotCheckBanDateAndDoNotCreateChildTasks
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE BEGINOFPERIOD(SettlementsWithCustomersChanges.Period, DAY)
	|		END) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	SettlementsWithCustomersChanges.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	SettlementsWithCustomersChanges.ARAPObject AS ARAPObject,
	|	SettlementsWithCustomersChanges.Currency AS Currency
	|INTO MinimumChangePeriodsClients
	|FROM
	|	SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
	|WHERE
	|	(SettlementsWithCustomersChanges.Sum <> 0
	|	OR SettlementsWithCustomersChanges.AmountDue <> 0
	|	OR SettlementsWithCustomersChanges.ToShip <> 0
	|	OR SettlementsWithCustomersChanges.SumCompl <> 0
	|	OR SettlementsWithCustomersChanges.SumMan <> 0)
	|	AND &NewCalculations
	|	AND &CreateTasksForDistributionOfMutualSettlements
	|GROUP BY
	|	SettlementsWithCustomersChanges.AccountingDimensionByPartners,
	|	SettlementsWithCustomersChanges.ARAPObject,
	|	SettlementsWithCustomersChanges.Currency
	|
	|INDEX BY
	|	AccountingDimensionByPartners,
	|	ARAPObject,
	|	Currency,
	|	Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(AssignmentsForDistribution.TaskPeriod) AS TaskPeriod,
	|	MIN(AssignmentsForDistribution.PeriodForMonitoringChangesAndCreatingTasks) AS PeriodForMonitoringChangesAndCreatingTasks,
	|	AssignmentsForDistribution.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	AssignmentsForDistribution.ARAPObject AS ARAPObject,
	|	AssignmentsForDistribution.Currency AS Currency,
	|	AssignmentsForDistribution.Document AS Document,
	|	AssignmentsForDistribution.Organization AS Organization
	|INTO TasksForDistributionOfMutualSettlementsClients
	|FROM
	|	(SELECT
	|		CASE WHEN CustomersARAPAccounting.Sum = 0
	|				AND (CustomersARAPAccounting.AmountDue <> 0 OR CustomersARAPAccounting.ToShip <> 0)
	|				AND VALUETYPE(CustomersARAPAccounting.Recorder) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(CustomersARAPAccounting.Recorder) <> TYPE(Document.OBEntryARAP)
	|			THEN CustomersARAPAccounting.RecorderDate
	|			ELSE CustomersARAPAccounting.Period
	|		END AS TaskPeriod,
	|		MinimumChangePeriodsClients.PeriodForMonitoringChangesAndCreatingTasks AS PeriodForMonitoringChangesAndCreatingTasks,
	|		CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|		CustomersARAPAccounting.Currency AS Currency,
	|		CustomersARAPAccounting.Recorder AS Document,
	|		CustomersARAPAccounting.AccountingDimensionByPartners.Organization AS Organization
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|			INNER JOIN MinimumChangePeriodsClients AS MinimumChangePeriodsClients
	|			ON CustomersARAPAccounting.AccountingDimensionByPartners = MinimumChangePeriodsClients.AccountingDimensionByPartners
	|			AND CustomersARAPAccounting.ARAPObject = MinimumChangePeriodsClients.ARAPObject
	|			AND CustomersARAPAccounting.Currency = MinimumChangePeriodsClients.Currency
	|			AND CASE WHEN CustomersARAPAccounting.Sum = 0
	|				AND (CustomersARAPAccounting.AmountDue <> 0 OR CustomersARAPAccounting.ToShip <> 0)
	|				AND VALUETYPE(CustomersARAPAccounting.Recorder) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(CustomersARAPAccounting.Recorder) <> TYPE(Document.OBEntryARAP)
	|			THEN CustomersARAPAccounting.RecorderDate
	|			ELSE CustomersARAPAccounting.Period
	|			END >= MinimumChangePeriodsClients.Period
	|	WHERE
	|		CustomersARAPAccounting.Active
	|		AND &NewCalculations
	|		AND &CreateTasksForDistributionOfMutualSettlements
	|		AND (CustomersARAPAccounting.Sum <> 0
	|		OR CustomersARAPAccounting.AmountDue <> 0
	|		OR CustomersARAPAccounting.ToShip <> 0
	|		OR CustomersARAPAccounting.SumCompl <> 0
	|		OR CustomersARAPAccounting.SumMan <> 0)
	|
	|	UNION ALL
	|
	|	SELECT
	|		CASE WHEN SettlementsWithCustomersChanges.Sum = 0
	|				AND (SettlementsWithCustomersChanges.AmountDue <> 0 OR SettlementsWithCustomersChanges.ToShip <> 0)
	|				AND VALUETYPE(SettlementsWithCustomersChanges.Document) <> TYPE(Document.OBEntry)
	|				AND VALUETYPE(SettlementsWithCustomersChanges.Document) <> TYPE(Document.OBEntryARAP)
	|			THEN SettlementsWithCustomersChanges.RecorderDate
	|			ELSE SettlementsWithCustomersChanges.Period
	|		END,
	|		CASE
	|			WHEN &DoNotCheckBanDateAndDoNotCreateChildTasks
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE BEGINOFPERIOD(SettlementsWithCustomersChanges.Period, DAY)
	|		END,
	|		SettlementsWithCustomersChanges.AccountingDimensionByPartners,
	|		SettlementsWithCustomersChanges.ARAPObject,
	|		SettlementsWithCustomersChanges.Currency,
	|		SettlementsWithCustomersChanges.Document,
	|		SettlementsWithCustomersChanges.Organization
	|	FROM
	|		SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
	|	WHERE
	|		(SettlementsWithCustomersChanges.Sum <> 0
	|		OR SettlementsWithCustomersChanges.AmountDue <> 0
	|		OR SettlementsWithCustomersChanges.ToShip <> 0
	|		OR SettlementsWithCustomersChanges.SumCompl <> 0
	|		OR SettlementsWithCustomersChanges.SumMan <> 0)
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

#Region InfobaseUpdate

// Corrects the order of operations within a recordset document.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet.CustomersARAPAccounting, AccumulationRegisterRecordSet.VendorsARAPAccounting - A set for correction
//  DocumentNumber - String - Number of the registrar being updated
Procedure CorrectOrderOfOperationsWithinDocument(RecordSet, DocumentNumber) Export
	
	For Each Record In RecordSet Do
		
		OrderOfOperationWithoutOrderInsideDocument = GetOrderOfOperationsWithoutOrderInsideDocument(Record.OperationProcedure, DocumentNumber);
		If Not ValueIsFilled(OrderOfOperationWithoutOrderInsideDocument)
			Or Not ValueIsFilled(Record.OperationProcedure) Then
			Continue;
		EndIf;
		
		If Record.ReversingEntry Then 
			// Storno records should always be before the rest of the records, their order among themselves is not important
			If Record.OperationProcedure <> OrderOfOperationWithoutOrderInsideDocument Then
				Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument;
			EndIf;
		ElsIf StrLen(Record.OperationProcedure) - StrLen(OrderOfOperationWithoutOrderInsideDocument) > 1 Then 
			// If the handler mistakenly added the order of operations within document 2 or 3, new documents 
			// with the already completed order of operations within the document
			Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument + Mid(Record.OperationProcedure, StrLen(OrderOfOperationWithoutOrderInsideDocument) + 1, 1);
		ElsIf Record.SettlementTransaction = Enums.SettlementOperations.Shipment
			And Record.OperationProcedure <> OrderOfOperationWithoutOrderInsideDocument + "4" Then
			// Shipments with the order of operations inside document 1
			Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument + "4";
		ElsIf Record.BusinessOperation = Enums.BusinessTransactions.DebtTransferBetweenBranchOffices
			And TypeOf(Record.Recorder) <> Type("DocumentRef.ReturnOfGoodsFromCustomer")
			And TypeOf(Record.Recorder) <> Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			And TypeOf(Record.Recorder) <> Type("DocumentRef.IntercompanyGoodsReturn")
			And TypeOf(Record.Recorder) <> Type("DocumentRef.RedemptionOfGoodsFromStorage")
			And TypeOf(Record.Recorder) <> Type("DocumentRef.ReturnOfGoodsToVendor")
			
			And TypeOf(Record.Recorder) <> Type("DocumentRef.ElectronicTicketTransaction")
			And Record.OperationProcedure <> OrderOfOperationWithoutOrderInsideDocument + "5" Then
			// The transfer of the task should be done of operations with the order of the operation inside the document 2
			Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument + "5";
		ElsIf Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument Then
			// Correctly fill in the order of operations within document 2 or 3 for sources, receivers
			If ValueIsFilled(Record.DestinationAccountingDimensionByPartners) Then
				Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument + "2";
			ElsIf ValueIsFilled(Record.CorPartnerAccountingDimension) Then
				Record.OperationProcedure = OrderOfOperationWithoutOrderInsideDocument + "3";
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// Truncates characters of operation order after the document length number
// 
// Parameters:
//  OperationProcedure - String - Initial order of operation
//  DocumentNumber - String - The number of the document that is being searched of operation
// 
// Returns:
//  String - Order of Operation Without Order Inside The Document
Function GetOrderOfOperationsWithoutOrderInsideDocument(OperationProcedure, DocumentNumber) Export
	
	Number_Position = StrFind(OperationProcedure, DocumentNumber, SearchDirection.FromEnd);
	If Number_Position > 0 Then
		Return Left(OperationProcedure, Number_Position - 1 + StrLen(DocumentNumber));
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ControlOfResults

// There are changes in the recruitment results.
// 
// Parameters:
//  Set - AccumulationRegisterRecordSet.CustomersARAPAccounting,
//          The register of the recording set.Payments by suppliers,
//          The register of the recording set.Computersposters,
//          register, and set of records.calculationsclientamiposrocam.
// 
// Returns:
//  Boolean - There Are Changes In The Recruitment Results
Function ThereAreChangesInSetResults(Set) Export
	
	If Not Set.Modified() Then
		Return False;
	EndIf;
	
	TheseAreSettlementsWithCustomers = 
		TypeOf(Set) = Type("AccumulationRegisterRecordSet.CustomersARAPAccounting")
		Or TypeOf(Set) = Type("AccumulationRegisterRecordSet.CustomersARAPAccountingByDueDates");
		
	If TypeOf(Set) = Type("AccumulationRegisterRecordSet.CustomersARAPAccounting")
		Or TypeOf(Set) = Type("AccumulationRegisterRecordSet.VendorsARAPAccounting") Then
		QueryText = QueryTextCalculations(TheseAreSettlementsWithCustomers);
		
	ElsIf TypeOf(Set) = Type("AccumulationRegisterRecordSet.CustomersARAPAccountingByDueDates")
		Or TypeOf(Set) = Type("AccumulationRegisterRecordSet.VendorsARAPAccountingByDueDates") Then
		QueryText = QueryTextCalculationsByTerms(TheseAreSettlementsWithCustomers);
		
	Else
		ErrorText = NStr("vi = 'Không thể xác định bảng để so sánh tổng số của tập hợp bản ghi.';
						|ru = 'Не удалось определить таблицу для сравнения итогов набора записей.';
						|en = 'Cannot identify the table for comparing record set totals.'; fa = 'Cannot identify the table for comparing record set totals.';
						|it = 'Cannot identify the table for comparing record set totals.';
						|pl = 'Cannot identify the table for comparing record set totals.';
						|tr = 'Kayıt kümesinin toplamlarını karşılaştırmak için tablolar belirlenemedi.'");
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	UpdatedRecorder = Set.Filter.Recorder.Value;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Recorder", UpdatedRecorder);
	Query.SetParameter("NewRegisteredRecords_", Set.Unload());
	ComparisonResult = Query.Execute().Unload();
	
	HasChanges = ComparisonResult.Count() > 0;
	If HasChanges Then
		ComparisonResult.GroupBy("Recorder");
		For Each Record In ComparisonResult Do
			LinesOfText = New Array;
			LinesOfText.Add(NStr("vi = 'Sau khi cập nhật, đã thay đổi tổng số của các số đo trong các bản ghi kết chuyển của chứng từ. Đã hủy bỏ cập nhật chứng từ.';
								|ru = 'После обновления изменились итоги ресурсов в движениях документа. Обновление документа отменено.';
								|en = 'After the update, the resource totals in the document register records were changed. The document update is cancelled.'; fa = 'After the update, the resource totals in the document register records were changed. The document update is cancelled.';
								|it = 'После обновления изменились итоги ресурсов в движениях документа. Обновление документа отменено.';
								|pl = 'After the update, the resource totals in the document register records were changed. The document update is cancelled.';
								|tr = 'После обновления изменились итоги ресурсов в движениях документа. Обновление документа отменено.'"));
			LinesOfText.Add(TextDoubleCheckDocumentManually());
			RecommendationText = StrConcat(LinesOfText, Chars.LF);
			InfobaseUpdate.FileIssueWithData(
				Record.Recorder,
				RecommendationText);
		EndDo;
	EndIf;
	
	Return HasChanges;
	
EndFunction

Function QueryTextCalculations(TheseAreSettlementsWithCustomers)
	
	QueryText = 
	"SELECT
	|	Calculations.RecordType AS RecordType,
	|	Calculations.Recorder AS Recorder,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	Calculations.Sum AS Sum
	|INTO TTNewRegisteredRecords
	|FROM
	|	&NewRegisteredRecords_ AS Calculations
	|;
	|
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.Sum) AS Sum
	|FROM
	|	(SELECT
	|		Calculations.Recorder AS Recorder,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		-CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -Calculations.Sum
	|			ELSE Calculations.Sum
	|		END AS Sum
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Recorder = &Recorder
	|
	|	UNION ALL
	|
	|	SELECT
	|		NewRegisteredRecords_.Recorder AS Recorder,
	|		NewRegisteredRecords_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|		NewRegisteredRecords_.Currency AS Currency,
	|		CASE WHEN NewRegisteredRecords_.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -NewRegisteredRecords_.Sum
	|			ELSE NewRegisteredRecords_.Sum
	|		END AS Sum
	|	FROM
	|		TTNewRegisteredRecords AS NewRegisteredRecords_
	|	) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Recorder,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.Currency
	|
	|HAVING
	|	SUM(NestedQuery.Sum) <> 0
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText,
			"AccumulationRegister.CustomersARAPAccounting",
			"AccumulationRegister.VendorsARAPAccounting"
		);
	EndIf;
	
	Return QueryText;
	
EndFunction

Function QueryTextCalculationsByTerms(TheseAreSettlementsWithCustomers)

	
	QueryText = 
	"SELECT
	|	Calculations.RecordType AS RecordType,
	|	Calculations.DocumentRecorder AS DocumentRecorder,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.ARAPObject AS ARAPObject,
	|	Calculations.Currency AS Currency,
	|	Calculations.Prepayment AS Prepayment,
	|	Calculations.Debt AS Debt
	|INTO TTNewRegisteredRecords
	|FROM
	|	&NewRegisteredRecords_ AS Calculations
	|;
	|
	|SELECT
	|	NestedQuery.Recorder AS Recorder,
	|	NestedQuery.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject AS ARAPObject,
	|	NestedQuery.Currency AS Currency,
	|	SUM(NestedQuery.Prepayment) AS Prepayment,
	|	SUM(NestedQuery.Debt) AS Debt
	|FROM
	|	(SELECT
	|		Calculations.DocumentRecorder AS Recorder,
	|		Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Calculations.ARAPObject AS ARAPObject,
	|		Calculations.Currency AS Currency,
	|		-CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -Calculations.Prepayment
	|			ELSE Calculations.Prepayment
	|		END AS Prepayment,
	|		-CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -Calculations.Debt
	|			ELSE Calculations.Debt
	|		END AS Debt
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS Calculations
	|WHERE
	|	Calculations.Recorder = &Recorder
	|
	|	UNION ALL
	|
	|	SELECT
	|		NewRegisteredRecords_.DocumentRecorder AS Recorder,
	|		NewRegisteredRecords_.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		NewRegisteredRecords_.ARAPObject AS ARAPObject,
	|		NewRegisteredRecords_.Currency AS Currency,
	|		CASE WHEN NewRegisteredRecords_.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -NewRegisteredRecords_.Prepayment
	|			ELSE NewRegisteredRecords_.Prepayment
	|		END AS Prepayment,
	|		CASE WHEN NewRegisteredRecords_.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -NewRegisteredRecords_.Debt
	|			ELSE NewRegisteredRecords_.Debt
	|		END AS Debt
	|	FROM
	|		TTNewRegisteredRecords AS NewRegisteredRecords_
	|	) AS NestedQuery
	|GROUP BY
	|	NestedQuery.Recorder,
	|	NestedQuery.AccountingDimensionByPartners,
	|	NestedQuery.ARAPObject,
	|	NestedQuery.Currency
	|
	|HAVING
	|	SUM(NestedQuery.Prepayment) <> 0
	|	OR SUM(NestedQuery.Debt) <> 0
	|";
	
	If Not TheseAreSettlementsWithCustomers Then
		QueryText = StrReplace(QueryText,
			"AccumulationRegister.CustomersARAPAccountingByDueDates",
			"AccumulationRegister.VendorsARAPAccountingByDueDates"
		);
	EndIf;
	
	Return QueryText;
	
EndFunction

// Returns:
//  String - The text of the recommendation for the document in case of a failed register update
//
Function TextDoubleCheckDocumentManually() Export
	
	Return NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
				|ru = 'Перепроведите документ вручную.';
				|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
				|it = 'Перепроведите документ вручную.';
				|pl = 'Repost the document manually.';
				|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
	
EndFunction

// Parameters:
//  ErrorInfo - ErrorInfo
//  UpdatedRecorder - DocumentRef - The updated Recorder
// 
// Returns:
//  String - the text of the error message
Function ErrorMessageText(ErrorInfo, UpdatedRecorder) Export
	
	MessageText = NStr("vi = 'Không thể cập nhật chứng từ: %Object% do: %Cause%';
						|ru = 'Не удалось обновить документ: %Object% по причине: %Cause%';
						|en = 'Cannot update the document: %Object%. Reason: %Cause%'; fa = 'Cannot update the document: %Object%. Reason: %Cause%';
						|it = 'Cannot update the document: %Object%. Reason: %Cause%';
						|pl = 'Cannot update the document: %Object%. Reason: %Cause%';
						|tr = '%Cause% sebebiyle %Object% belgesi güncellenemiyor'");
	MessageText = StrReplace(MessageText, "%Object%", UpdatedRecorder);
	MessageText = StrReplace(MessageText, "%Cause%", ErrorProcessing.BriefErrorDescription(ErrorInfo));
	
	Return MessageText;
	
EndFunction

#EndRegion

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
	Handler.Procedure = "AccumulationRegisters.CustomersARAPAccounting.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.21";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("489f7d26-6bd5-7943-a55c-3d06d445974a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.CustomersARAPAccounting.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.Comment = StrTemplate(NStr("ru = 'Исправляет реквизит ""%1"" для движений расчетов.
	                                              |Исправляет реквизит ""%2"" для движений платежей без даты погашения.
	                                              |Исправляет реквизит ""%3"" для движений документов ""%4"". 
												  |Заполняет реквизиты курсов валют взаиморасчетов и упр. учета.';
												  |vi = 'Corrects the ""%1"" attribute for calculation records.
												  |Corrects the ""%2"" attribute for payment records without a repayment date.
												  |Corrects the ""%3"" attribute for ""%4"" document register records. 
												  |Fills in attributes of AR/AP currency and management accounting currency rates.';
												  |en = 'Corrects the ""%1"" attribute for calculation records.
												  |Corrects the ""%2"" attribute for payment records without a repayment date.
												  |Corrects the ""%3"" attribute for ""%4"" document register records. 
												  |Fills in attributes of AR/AP currency and management accounting currency rates.'; fa = 'Corrects the ""%1"" attribute for calculation records.
	                                              |Corrects the ""%2"" attribute for payment records without a repayment date.
	                                              |Corrects the ""%3"" attribute for ""%4"" document register records. 
	                                              |Fills in attributes of AR/AP currency and management accounting currency rates.';
												  |it = 'Corrects the ""%1"" attribute for calculation records.
												  |Corrects the ""%2"" attribute for payment records without a repayment date.
												  |Corrects the ""%3"" attribute for ""%4"" document register records. 
												  |Fills in attributes of AR/AP currency and management accounting currency rates.';
												  |pl = 'Corrects the ""%1"" attribute for calculation records.
												  |Corrects the ""%2"" attribute for payment records without a repayment date.
												  |Corrects the ""%3"" attribute for ""%4"" document register records. 
												  |Fills in attributes of AR/AP currency and management accounting currency rates.';
												  |tr = 'Hesap hareketleri için ""%1"" özniteliğini düzeltir. 
												  | Vade tarihi olmayan ödeme hareketleri için ""%2"" özniteliğini düzeltir. 
												  | %4 belgelerinin hareketleri için ""%3"" özniteliğini düzeltir. 
												  | Karşılıklı hesaplaşmalar ve yönetim muhasebesi için döviz kuru özniteliklerini doldurur.'"), 
		Metadata.AccumulationRegisters.CustomersARAPAccounting.Attributes.OperationProcedure.Presentation(),
		Metadata.AccumulationRegisters.CustomersARAPAccounting.Attributes.SettlementProcedureByPaymentDate.Presentation(),
		Metadata.AccumulationRegisters.CustomersARAPAccounting.Attributes.RecorderDate.Presentation(),
		Metadata.Documents.CustomerBonusCertificate.Presentation());
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ObjectsToLock = "";
	
EndProcedure

// The procedure for registering data for the update handler is to process the data for the transition Version.
// 
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName  = "AccumulationRegister.CustomersARAPAccounting";

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	#Region QueryText
	Query.Text = "
	|// CorrectionOfPaymentOperationProceduresWithoutRepaymentDate
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|INTO TTToProcessing
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.PaymentDate = DATETIME(1,1,1)
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND Calculations.Sum > 0
	|	AND CAST(LEFT(Calculations.SettlementProcedureByPaymentDate, 4) AS STRING(4))<> ""3000""
	|
	|UNION ALL
	|
	|// CorrectionOfOfOperationProceduresForEnteringAdvanceBalances
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	(Calculations.Recorder REFS Document.OBEntryARAP
	|		OR Calculations.Recorder REFS Document.OBEntry)
	|	AND Calculations.Period <> Calculations.RecorderDate
	|	AND Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
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
	|// CorrectionOfDateOfRegistrarOfActsOfAwardToClient
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.Recorder REFS Document.CustomerBonusCertificate
	|	AND Calculations.Period <> Calculations.RecorderDate
	|
	|UNION ALL
	|
	|// CorrectionOfOrdersOfOperationStorno
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND SUBSTRING(Calculations.OperationProcedure, 9, 1) = ""1""
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND SUBSTRING(Calculations.OperationProcedure, 9, 1) = ""9""
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	CustomersARAPAccounting.Sum <> 0
	|	AND CustomersARAPAccounting.SumCompl <> 0
	|	AND CustomersARAPAccounting.Currency <> Companies.LocalAccountingCurrency
	|	AND CustomersARAPAccounting.DocumentCurrency <> Companies.LocalAccountingCurrency
	|	AND CustomersARAPAccounting.RateARAPCurrencyNumerator = 0
	|	AND CustomersARAPAccounting.RateARAPCurrencyDenominator = 0
	|	AND NOT CustomersARAPAccounting.BusinessOperation IN (&ManualCourseOfOperations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency
	|		ON CustomersARAPAccounting.Currency <> ManagementAccountingCurrency.Value
	|			AND CustomersARAPAccounting.DocumentCurrency <> ManagementAccountingCurrency.Value
	|WHERE
	|	CustomersARAPAccounting.Sum <> 0
	|	AND CustomersARAPAccounting.SumMan <> 0
	|	AND CustomersARAPAccounting.ExchangeRateNumeratorOfManSCurrency = 0
	|	AND CustomersARAPAccounting.ExchangeRateDenominatorCurrencyMan = 0
	|	AND NOT CustomersARAPAccounting.BusinessOperation IN (&ManualCourseOfOperations)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
	|			INNER JOIN Catalog.Companies AS Companies
	|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
	|WHERE
	|	VALUETYPE(CustomersARAPAccounting.Recorder) IN (TYPE(Document.OBEntry), TYPE(Document.OBEntryARAP))
	|	AND CustomersARAPAccounting.Sum <> 0
	|	AND CustomersARAPAccounting.SumCompl <> 0
	|	AND CustomersARAPAccounting.Currency <> Companies.LocalAccountingCurrency
	|	AND CustomersARAPAccounting.RateARAPCurrencyNumerator = 0
	|	AND CustomersARAPAccounting.RateARAPCurrencyDenominator = 0
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CustomersARAPAccounting.Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Constant.ManagementAccountingCurrency AS ManagementAccountingCurrency
	|		ON CustomersARAPAccounting.Currency <> ManagementAccountingCurrency.Value
	|WHERE
	|	VALUETYPE(CustomersARAPAccounting.Recorder) IN (TYPE(Document.OBEntry), TYPE(Document.OBEntryARAP))
	|	AND CustomersARAPAccounting.Sum <> 0
	|	AND CustomersARAPAccounting.SumMan <> 0
	|	AND CustomersARAPAccounting.ExchangeRateNumeratorOfManSCurrency = 0
	|	AND CustomersARAPAccounting.ExchangeRateDenominatorCurrencyMan = 0
	|
	|UNION ALL
	|
	|// CleaningReceiversOfSourcesFromStorno
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|WHERE
	|	Calculations.ReversingEntry
	|	AND Calculations.DestinationAccountingDimensionByPartners <> VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Calculations.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS Register3
	|		ON Calculations.Recorder = Register3.Ref
	|			AND NOT Register3.AdditionalRecord
	|		LEFT JOIN TTToProcessing AS TTToProcessing
	|		ON Calculations.Recorder = TTToProcessing.Recorder
	|			AND TTToProcessing.Recorder IS NULL
	|WHERE
	|	Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|	AND NOT VALUETYPE(Calculations.Recorder) IN (TYPE(Document.ReturnOfGoodsFromCustomer),
	|	                                         TYPE(Document.RequestForReturnOfGoodsFromCustomer),
	|	                                         TYPE(Document.IntercompanyGoodsReturn),
	|	                                         TYPE(Document.RedemptionOfGoodsFromStorage))
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
		Metadata.Documents.CustomerInvoiceServices.StandardAttributes.Number.Name); 
	VTRecordersWithNumbers = New ValueTable;
	VTRecordersWithNumbers.Columns.Add("Recorder",
		New TypeDescription(Metadata.AccumulationRegisters.CustomersARAPAccounting.StandardAttributes.Recorder.Type.Types()));
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
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
	|	AccumulationRegister.CustomersARAPAccounting AS Calculations
	|		INNER JOIN TTNumbers AS TTNumbers
	|		ON Calculations.Recorder = TTNumbers.Recorder
	|WHERE
	|	Calculations.BusinessOperation = VALUE(Enum.BusinessTransactions.DebtTransferBetweenBranchOffices)
	|	AND NOT Calculations.ReversingEntry
	|	AND NOT VALUETYPE(Calculations.Recorder) IN (TYPE(Document.ReturnOfGoodsFromCustomer),
	|	                                         TYPE(Document.RequestForReturnOfGoodsFromCustomer),
	|	                                         TYPE(Document.IntercompanyGoodsReturn),
	|	                                         TYPE(Document.RedemptionOfGoodsFromStorage))
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
	
	FullObjectName = "AccumulationRegister.CustomersARAPAccounting";

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
		|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
		|	CustomersARAPAccounting.Currency AS Currency,
		|	CustomersARAPAccounting.RecordType AS RecordType,
		|	CustomersARAPAccounting.Sum AS Sum,
		|	CustomersARAPAccounting.AmountDue AS AmountDue,
		|	CustomersARAPAccounting.ToShip AS ToShip,
		|	SUBSTRING(CustomersARAPAccounting.OperationProcedure, 9, 1) AS TypeOfOperationForSorting
		|FROM
		|	TTDocumentsToBeCancelled AS ReversedDocuments
		|		INNER JOIN AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|			ON ReversedDocuments.ReversedDocument = CustomersARAPAccounting.Recorder
		|WHERE
		|	NOT CustomersARAPAccounting.ReversingEntry
		|	AND (CustomersARAPAccounting.Sum <> 0
		|		OR CustomersARAPAccounting.AmountDue <> 0
		|		OR CustomersARAPAccounting.ToShip <> 0)
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
		|	CustomersARAPAccounting.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	Companies.LocalAccountingCurrency AS LocalAccountingCurrency
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|		INNER JOIN Catalog.DimensionKeysOfAccountingByPartners AS DimensionKeysOfAccountingByPartners
		|			INNER JOIN Catalog.Companies AS Companies
		|			ON DimensionKeysOfAccountingByPartners.Organization = Companies.Ref
		|		ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionKeysOfAccountingByPartners.Ref
		|WHERE
		|	CustomersARAPAccounting.Recorder IN(SELECT T.Recorder FROM TTToProcess AS T)
		|";
	
	QueryResult = Query.ExecuteBatch();
	
	DataOfCancelledDocuments = QueryResult[2].Unload();
	DataOfCancelledDocuments.Indexes.Add("Recorder");
	DataOfCancelledDocuments.Indexes.Add("Recorder, AccountingDimensionByPartners, ARAPObject, Currency, RecordType, Sum, AmountDue, ToShip");
	
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
			
			LockItem = Block.Add("AccumulationRegister.CustomersARAPAccounting.RecordSet");
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
			
			#Region CorrectionOfOrdersOfOperationsInsideDocument
			LinesDocumentNumber = DocumentNumbers.FindRows(New Structure("Recorder", UpdatedRecorder));
			If LinesDocumentNumber.Count() > 0
				And ValueIsFilled(LinesDocumentNumber[0].DocumentNumber) Then
				DocumentNumber = LinesDocumentNumber[0].DocumentNumber;
			Else
				DocumentNumber = Common.ObjectAttributeValue(UpdatedRecorder,
					Metadata.Documents.CustomerInvoiceServices.StandardAttributes.Number.Name);
			EndIf;
			CorrectOrderOfOperationsWithinDocument(RecordSet, DocumentNumber);
			#EndRegion
			
			#Region CorrectionOfPaymentOperationProceduresWithoutRepaymentDate
			For Each Record In RecordSet Do
				If Record.RecordType = AccumulationRecordType.Expense
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
					And Record.RecordType = AccumulationRecordType.Expense
					And Record.RecorderDate >= Date(2010, 1, 1)
					And Left(Record.OperationProcedure, 8) <> Format(Record.Period, "DF=yyyyMMdd") Then
					
					DateAsString = Format(Record.Period, "DF=yyyyMMdd");
					Record.OperationProcedure = DateAsString + Mid(Record.OperationProcedure, 9);
					
				EndIf;
			EndDo;
			#EndRegion
			
			#Region CorrectionOfDateOfRegistrarOfActsOfAwardToClient
			For Each Record In RecordSet Do
				If TypeOf(UpdatedRecorder) = Type("DocumentRef.CustomerBonusCertificate")
					And Record.RecorderDate <> Record.Period Then
					
					Record.RecorderDate = Record.Period;
					
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
						FilterStructure1.Insert("ToShip",               - Record.ToShip);
						
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
				ResultsHaveChanged = ThereAreChangesInSetResults(RecordSet);
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
						ErrorMessageText(ErrorInfo(), UpdatedRecorder)
						+ Chars.LF + TextDoubleCheckDocumentManually());
				EndIf;
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
