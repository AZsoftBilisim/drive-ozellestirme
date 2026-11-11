#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Reflects changes in order States in the register.
//
// Parameters:
//  Orders - Array of DocumentRef - array of reflected orders.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectOrderStates(Orders, Errors = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PurchaseOrder.Ref      AS OrderDocument,
	|	NOT PurchaseOrder.Posted AS RemovalOfBody
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|WHERE
	|	PurchaseOrder.Ref IN (&Orders)
	|";
	
	Query.SetParameter("Orders", Orders);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	TheOrdersTable = Result.Unload();
	
	OrdersCount = TheOrdersTable.Count();
	If OrdersCount = 1 Then
		
		TableRow = TheOrdersTable[0];
		
		SelectedOrders_1 = New Array;
		SelectedOrders_1.Add(TableRow.OrderDocument);
		
		RemovalOfBody = TableRow.RemovalOfBody;
		
		ReflectOrderState(SelectedOrders_1, RemovalOfBody, Errors);
		
	ElsIf OrdersCount > 1 Then
		
		TheOrdersTable.Indexes.Add("RemovalOfBody");
		
		Filter = New Structure("RemovalOfBody");
		
		Filter.RemovalOfBody = True;
		TableOfSelectedOrders = TheOrdersTable.Copy(Filter, "OrderDocument");
		If TableOfSelectedOrders.Count() > 0 Then
			
			SelectedOrders_1 = TableOfSelectedOrders.UnloadColumn("OrderDocument");
			ReflectOrderState(SelectedOrders_1, Filter.RemovalOfBody, Errors);
			
		EndIf;
		
		Filter.RemovalOfBody = False;
		TableOfSelectedOrders = TheOrdersTable.Copy(Filter, "OrderDocument");
		If TableOfSelectedOrders.Count() > 0 Then
			
			SelectedOrders_1 = TableOfSelectedOrders.UnloadColumn("OrderDocument");
			ReflectOrderState(SelectedOrders_1, Filter.RemovalOfBody, Errors);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Complements the request text of the state calculation engine.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function MatchingRequestsToControlRegisters(Query) Export

	MatchingQueryTexts = New Map();
	MatchingQueryTexts.Insert("RegisterOfDocumentsChanges", QueryTextDocumentsRegistry(Query));
	MatchingQueryTexts.Insert("MovementOfOrdersToSuppliersChange", QueryTextPurchaseOrders(Query));
	MatchingQueryTexts.Insert("VendorsARAPAccountingChanges", QueryTextVendorsARAPAccounting(Query));
	MatchingQueryTexts.Insert("GoodsToReceiveUpdate", QueryTextGoodsToReceive(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Adds tasks to the State of orders.
// 
// Parameters:
//  Source       - See DocumentsStates.AddTasksToStateOfOrders.Source
//  Orders         - See DocumentsStates.AddTasksToStateOfOrders.Reflected_Documents
//  Action       - See DocumentsStates.AddTasksToStateOfOrders.Action
//  TaskTable - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddTasksToStateOfOrders(
			Source,
			Orders,
			Action = "",
			TaskTable = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(Source) = Type("DocumentObject.PurchaseOrder") Then
		
		InformationRegisters.JobsToReflectOrderState.AddTasks(Source.Ref, Action, TaskTable);
		
	Else
		
		OrderTypes = TypesOfOrdersToReflectStates();
		
		SourceRef = ?(Source = Undefined, Undefined, Source.Ref);
		
		If SourceRef <> Undefined
			And OrderTypes.Find(TypeOf(SourceRef)) <> Undefined
			And Orders.Find(SourceRef) = Undefined Then
				InformationRegisters.JobsToReflectOrderState.AddTasks(
					SourceRef,
					Action,
					TaskTable);
		EndIf;
		
		For Each OrderDocument In Orders Do
			
			If OrderTypes.Find(TypeOf(OrderDocument)) = Undefined Then
				Continue;
			EndIf;
			
			InformationRegisters.JobsToReflectOrderState.AddTasks(OrderDocument, Action, TaskTable);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#Region InterfaceImplementation

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	PurchasingNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Purchases");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "f80c5160-b86d-4732-bc2d-595831870299";
	NewTypeOfAlerts.Description = NStr("vi = 'Các đơn hàng (mua) đang chờ thống nhất';
										|ru = 'Ожидающие согласования заказы (Закупки)';
										|en = 'Orders pending approval (Purchasing)'; fa = 'Orders pending approval (Purchasing)';
										|it = 'Orders pending approval (Purchasing)';
										|pl = 'Orders pending approval (Purchasing)';
										|tr = 'Onay bekleyen siparişler (Satın alımlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.InformationRegisters.PurchaseOrderStates.Templates.Notifications_PendingApproval.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Chờ thống nhất.';
												|ru = 'Ожидает согласования.';
												|en = 'Pending approval.';
												|it = 'Pending approval.';
												|pl = 'Pending approval.';
												|tr = 'Onay bekleniyor.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Các đơn hàng đang chờ thống nhất.';
												|ru = 'Ожидающие согласования заказы.';
												|en = 'Orders pending approval.';
												|it = 'Orders pending approval.';
												|pl = 'Orders pending approval.';
												|tr = 'Onay bekleyen siparişler.'"; // @NStr-1
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = PurchasingNotificationTypeGroup;
	NewTypeOfAlerts.Id = "284a23b1-d5c6-4dd8-a484-c5d6f3f51116";
	NewTypeOfAlerts.Description = NStr("vi = 'Các đơn hàng (mua) chuẩn bị đóng';
										|ru = 'Готовые к закрытию заказы (Закупки)';
										|en = 'Fulfilled orders (Purchasing)'; fa = 'Fulfilled orders (Purchasing)';
										|it = 'Fulfilled orders (Purchasing)';
										|pl = 'Fulfilled orders (Purchasing)';
										|tr = 'Kapatılmaya hazır siparişler (Satın alımlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.InformationRegisters.PurchaseOrderStates.Templates.Notifications_ReadyForClosure.FullName();
	NewTypeOfAlerts.NotificationTextTemplate = "vi = 'Chuẩn bị đóng.';
												|ru = 'Готов к закрытию.';
												|en = 'Fulfilled.';
												|it = 'Fulfilled.';
												|pl = 'Fulfilled.';
												|tr = 'Kapatılmaya hazır.'"; // @NStr-1
	NewTypeOfAlerts.GroupedNotificationText = "vi = 'Đơn hàng chuẩn bị đóng.';
												|ru = 'Готовые к закрытию заказы.';
												|en = 'Fulfilled orders.';
												|it = 'Fulfilled orders.';
												|pl = 'Fulfilled orders.';
												|tr = 'Kapatılmaya hazır siparişler.'"; // @NStr-1
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Returns the types of orders for which States should be reflected.
//
// Returns:
//  Array of Type - Types of State reflection orders
//
Function TypesOfOrdersToReflectStates() Export
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
	
	Return OrderTypes;
	
EndFunction

// Returns an action table to reflect the State of orders.
// Detailed description in the function of document statesadocuments.Initialize the Action table to reflect the status of orders.
// 
// Returns:
//  - Undefined,
//  - See DocumentsStates.InitializeActionTableToReflectStateOfOrders
//
Function ActionsToReflectStateOfOrders() Export
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Private

// The procedure uses the passed order link to calculate and record the order status in the data register.
//
// Parameters:
//  Orders - DocumentRef - a document that is used to recalculate the state
//  RemovalOfBody - Boolean - flag for processing deletion.
//  Errors - See ReflectOrderStates.Errors
//
Procedure ReflectOrderState(Orders, RemovalOfBody = False, Errors = Undefined)
	
	If RemovalOfBody Then
		
		For Each OrderDocument In Orders Do
			
			Set = InformationRegisters.PurchaseOrderStates.CreateRecordSet();
			Set.Filter.OrderDocument.Set(OrderDocument);
			
			Try
				Set.Write(True);
			Except
				
				ErrorText = ReflectionErrorText(OrderDocument, ErrorInfo());
				
				WriteLogEvent(
					EventLogEvent(),
					EventLogLevel.Warning,
					OrderDocument.Metadata(),
					OrderDocument,
					ErrorText);
				
				If Errors <> Undefined Then
					Errors.Insert(OrderDocument, ErrorText);
				EndIf;
				
			EndTry;
			
		EndDo;
		
		Return
		
	EndIf;
	
	TheStructureOfTheSearch = New Structure("OrderDocument, State, EventDate, 
		|PayAmount, PayPercentage, OrderReceiptAmount, PercentageOfOrderReceipt, AmountOfDebt, DebtPercentage, ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice");
	
	OrderStateTable = OrderStateTable(Orders);
	TableOfPreviousOrderStates = TableOfPreviousOrderStates(Orders);
		
	For Each TableRow In OrderStateTable Do
		
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		ArrayOfValidStates = TableOfPreviousOrderStates.FindRows(TheStructureOfTheSearch);
		
		StateChanged = Not Boolean(ArrayOfValidStates.Count());
		If StateChanged Then
			
			Set = InformationRegisters.PurchaseOrderStates.CreateRecordSet();
			Set.Filter.OrderDocument.Set(TableRow.OrderDocument);
			
			SetRow = Set.Add();
			ProcessStateTableRow(TableRow);
			FillPropertyValues(SetRow, TableRow);
			
			Try
				Set.Write(True);
			Except
				
				ErrorText = ReflectionErrorText(TableRow.OrderDocument, ErrorInfo());
				
				WriteLogEvent(
					EventLogEvent(),
					EventLogLevel.Warning,
					TableRow.OrderDocument.Metadata(),
					TableRow.OrderDocument,
					ErrorText);
				
				If Errors <> Undefined Then
					Errors.Insert(TableRow.OrderDocument, ErrorText);
				EndIf;
				
			EndTry;
		EndIf;
	EndDo;
EndProcedure

Procedure ProcessStateTableRow(TableRow)

	RoundUpPercentages(TableRow.PercentageOfOrderReceipt);
	RoundUpPercentages(TableRow.PayPercentage);
	RoundUpPercentages(TableRow.DebtPercentage);
	
EndProcedure

Function EventLogEvent()
	
	Return NStr("vi = 'Lỗi phản ánh trạng thái đơn hàng theo trình tự';
				|ru = 'Ошибка отражения состояния заказов в очереди';
				|en = 'Error recording order states in the queue'; fa = 'Error recording order states in the queue';
				|it = 'Errore di registrazione dello stato degli ordini in coda';
				|pl = 'Błąd odzwierciedlenie statusu zamówień w kolejce';
				|tr = 'Kuyruktaki siparişlerin durumlarının yansıtılma hatası'", Common.DefaultLanguageCode());
	
EndFunction

Function ReflectionErrorText(OrderDocument, ErrorInfo)
	
	Template = NStr("vi = 'Không thể phản ánh trạng thái đơn hàng đặt nhà cung cấp: %1 do: %2';
					|ru = 'Не удалось отразить состояние заказа поставщику: %1 по причине: %2';
					|en = 'Cannot record the state of the purchase order: %1. Reason: %2'; fa = 'Cannot record the state of the purchase order: %1. Reason: %2';
					|it = 'Не удалось отразить состояние заказа поставщику: %1 по причине: %2';
					|pl = 'Cannot record the state of the purchase order: %1. Reason: %2';
					|tr = 'Sipariş durumu tedarikçiye yansıtılamadı: %1 nedeni: %2'");
	
	Return StrTemplate(Template, OrderDocument, ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
EndFunction

// Rounds up the percentages of shipment, payment, and debt
//
// Parameters:
//	RoundedNumber - Number - to round a number.
//
Procedure RoundUpPercentages(RoundedNumber)
	
	If RoundedNumber > 99
		And RoundedNumber < 100 Then
		
		RoundedNumber = 99;
		
	EndIf;
	
	If RoundedNumber > 0
		And RoundedNumber < 1 Then
		
		RoundedNumber = 1;
		
	EndIf;
	
	RoundedNumber = Round(RoundedNumber);
	
EndProcedure

// The function returns a table of values with document States.
//
//	Parameters:
//		Referencedocuments-Array - (consisting of a document Link) links to documents that
//					need to calculate the state. The document Manager module must have a function defined
//					Request text for calculating the actual order status (), which returns the request text by date of relevance and
//					Request text for order statesaccount (), which returns the request text for order States.
//	Returns:
//		ValueTable:
//			Order-Document Link
//			State-Enum Link.Castaneocoronata
//			Databyte - Date
//			Payment Amount-Number
//			Interest Payments - Number
//			Access Totals - Number
//			Percentage Of Access - Number
//			Amadala - Number
//			Percent Of Debt - Number
//
Function OrderStateTable(ReferencesArrray)
	
	ConformityOfTypes = TMCommonUse.MatchingArraysByObjectType(ReferencesArrray);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	PackageTexts = New Array;
	PackageTexts.Add(RequestTextForCalculatingDatesOfOrderStateEvents());
	
	If NewOnlineARAPAccounting Then
		PackageTexts.Add(QueryTextMutualSettlementsStatus());
	Else
		PackageTexts.Add(PaymentRequestText());
		PackageTexts.Add(TextOfRequestForBalancesOfSettlements());
	EndIf;
	
	TextsOnDocuments = New Array;
	TextsOfOfflinePaymentStatus = New Array;
	
	FirstQuery = True;
	
	For Each DocumentType In ConformityOfTypes Do
		
		If DocumentType.Key = "Document.PurchaseOrder" Then
			ObjectManager = Common.ObjectManagerByFullName(DocumentType.Key);
			TextsOnDocuments.Add(ObjectManager.RequestTextForCalculatingOrderStates());
		
			If Not NewOnlineARAPAccounting Then
				If FirstQuery Then
					TextsOfOfflinePaymentStatus.Add(RequestTextStateOfOfflineSettlements(DocumentType.Key));
				Else
					TextsOfOfflinePaymentStatus.Add(
						StrReplace(RequestTextStateOfOfflineSettlements(DocumentType.Key), "INTO TTStateOfSETTLEMENTS", ""));
				EndIf;
			EndIf;
			
			FirstQuery = False;
		EndIf;
	EndDo;
	
	If TextsOfOfflinePaymentStatus.Count() > 0 Then
		PackageTexts.Add(StrConcat(TextsOfOfflinePaymentStatus, TMCommonUse.QuerySeparatorInJoin()));
	EndIf;
	PackageTexts.Add(StrConcat(TextsOnDocuments, TMCommonUse.QuerySeparatorInJoin()));
	
	Query = New Query;
	Query.Text = StrConcat(PackageTexts, Common.QueryBatchSeparator());
	Query.SetParameter("AnArrayOfOrders", ReferencesArrray);
	Query.SetParameter("NotUsePurchaseOrderStatuses", Not GetFunctionalOption("UsePurchaseOrderStatuses"));
	Query.SetParameter("MonitorOrderClosing", 
			GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived")
				Or GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment"));
	
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
	Query.SetParameter("DimensionalTypesOfQuantities", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("ReportData", 4);
	
	StateTable = Query.Execute().Unload();
	
	Return StateTable;
	
EndFunction

// The function returns the request text for calculating the date when order States are up-to-date.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingDatesOfOrderStateEvents()
	
	QueryText =
		"SELECT
		|	MIN(InventoryAndDemands.EventDate) AS MinimumReceiptDate,
		|	InventoryAndDemands.OrderDocument AS PurchaseOrder
		|INTO DatesOfReceiptOfOrdersToSuppliers
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&AnArrayOfOrders)) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.OrderedBalance > 0
		|GROUP BY
		|	InventoryAndDemands.OrderDocument";
	
	Return QueryText;
	
EndFunction

// The function returns a table of values with document States.
//
//	Parameters:
//		ReferencesArrray - Array - (consisting of a document Link) links to documents that
//					you need to calculate the state from. The document Manager module must have a function defined
//					Request text for calculating the actual order status (), which returns the request text by date of relevance and
//					Request text for order statesaccount (), which returns the request text for order States.
//	Returns:
//		ValueTable:
//			Order-Document Link
//			State-Enum Link.Castaneocoronata
//			Databyte - Date
//			Payment Amount-Number
//			Interest Payments - Number
//			Access Totals - Number
//			Percentage Of Access - Number
//			Amadala - Number
//			Percent Of Debt - Number
//			Estrangedestranged - Boolean
//
Function TableOfPreviousOrderStates(ReferencesArrray)
	
	Query = New Query("SELECT
	|	PurchaseOrderStates.OrderDocument AS OrderDocument,
	|	PurchaseOrderStates.State AS State,
	|	PurchaseOrderStates.EventDate AS EventDate,
	|	PurchaseOrderStates.PayAmount AS PayAmount,
	|	PurchaseOrderStates.PayPercentage AS PayPercentage,
	|	PurchaseOrderStates.OrderReceiptAmount AS OrderReceiptAmount,
	|	PurchaseOrderStates.PercentageOfOrderReceipt AS PercentageOfOrderReceipt,
	|	PurchaseOrderStates.AmountOfDebt AS AmountOfDebt,
	|	PurchaseOrderStates.DebtPercentage AS DebtPercentage,
	|	PurchaseOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
	|FROM
	|	InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
	|WHERE
	|	PurchaseOrderStates.OrderDocument IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Return Query.Execute().Unload();
	
EndFunction

#Region ServiceMethodsForGeneratingStates

#Region RequestTextsByControlRegisters

Function QueryTextPurchaseOrders(Query)
	
	QueryText =
	"SELECT
	|	Table.PurchaseOrder AS ReflectedDocument
	|FROM
	|	MovementOfOrdersToSuppliersChange AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function PaymentRequestText()
	
	Texts = New Array();
	
	QueryText = "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Object AS PurchaseOrder
		|INTO TTCalculationObjects_
		|FROM Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN (&AnArrayOfOrders)
		|;
		|SELECT
		|	BEGINOFPERIOD(VendorsARAPAccounting.Period, DAY) AS Period,
		|	SUM(VendorsARAPAccounting.AmountDue) AS AmountDueExpense,
		|	VendorsARAPAccounting.ARAPObject.Object AS PurchaseOrder
		|INTO CalculationSteps
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.ARAPObject IN (
		|		SELECT ARAPObject FROM TTCalculationObjects_)
		|	AND VendorsARAPAccounting.Active
		|	AND VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEU)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|	AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = VendorsARAPAccounting.ARAPObject.Organization
		|	AND VendorsARAPAccounting.AmountDue <> 0
		|GROUP BY
		|	VendorsARAPAccounting.ARAPObject,
		|	BEGINOFPERIOD(VendorsARAPAccounting.Period, DAY)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.ARAPObject.Object AS PurchaseOrder,
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEU)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|			THEN VendorsARAPAccounting.AmountDue
		|		ELSE 0
		|	END) AS AmountDueReceipt,
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN VendorsARAPAccounting.ToReceive
		|		ELSE 0
		|	END) AS ToReceiveExpense
		|INTO PaidForOrders
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.ARAPObject IN (
		|				SELECT ARAPObject FROM TTCalculationObjects_)
		|	AND VendorsARAPAccounting.Active
		|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = VendorsARAPAccounting.ARAPObject.Organization
		|GROUP BY
		|	VendorsARAPAccounting.ARAPObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalculationSteps.Period AS Period,
		|	CalculationSteps.PurchaseOrder AS PurchaseOrder
		|INTO CalculationResult_1
		|FROM
		|	CalculationSteps AS CalculationSteps
		|		INNER JOIN CalculationSteps AS VendorsARAPAccounting
		|		ON (VendorsARAPAccounting.Period <= CalculationSteps.Period)
		|			AND (VendorsARAPAccounting.PurchaseOrder = CalculationSteps.PurchaseOrder)
		|		LEFT JOIN PaidForOrders AS Paid
		|		ON CalculationSteps.PurchaseOrder = Paid.PurchaseOrder
		|
		|GROUP BY
		|	CalculationSteps.Period,
		|	CalculationSteps.PurchaseOrder,
		|	Paid.AmountDueReceipt
		|
		|HAVING
		|	SUM(VendorsARAPAccounting.AmountDueExpense) - ISNULL(Paid.AmountDueReceipt, 0) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(CalculationResult_1.Period) AS UpdateDate,
		|	CalculationResult_1.PurchaseOrder AS ARAPObject
		|INTO DatesWhenOrdersToSuppliersAreUpToDate
		|FROM
		|	CalculationResult_1 AS CalculationResult_1
		|
		|GROUP BY
		|	CalculationResult_1.PurchaseOrder";
	Texts.Add(QueryText);
	
	Texts.Add(
		"DROP CalculationSteps;
		|DROP CalculationResult_1
		|");
	
	QueryText = "
		|SELECT ALLOWED
		|	ARAPObjects.Ref AS ARAPObjectInvoice,
		|	TTCalculationObjects_.ARAPObject AS ARAPObjectOrder,
		|	TTCalculationObjects_.PurchaseOrder AS PurchaseOrder,
		|	SUM(CASE
		|			WHEN ARAPObjects.Sum = 0
		|				THEN 0
		|			ELSE SettlementsWithSuppliersTurnover.ToReceiveExpense / ARAPObjects.Sum
		|		END) AS OrderShare
		|INTO TTCommunicationOrdersINVOICES
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Turnovers(, , Recorder, ARAPObject IN (SELECT T.ARAPObject FROM TTCalculationObjects_ AS T)) AS SettlementsWithSuppliersTurnover
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON SettlementsWithSuppliersTurnover.Recorder = ARAPObjects.Object
		|			AND NOT ARAPObjects.DeletionMark
		|		INNER JOIN TTCalculationObjects_ AS TTCalculationObjects_
		|		ON SettlementsWithSuppliersTurnover.ARAPObject = TTCalculationObjects_.ARAPObject
		|
		|GROUP BY
		|	ARAPObjects.Ref,
		|	TTCalculationObjects_.ARAPObject,
		|	TTCalculationObjects_.PurchaseOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SettlementsData.ARAPObject AS ARAPObject,
		|	ISNULL(SUM(SettlementsData.PaymentFact), 0) AS PaymentFact,
		|	ISNULL(SUM(SettlementsData.AmountDue), 0) AS AmountDueClosingBalance
		|INTO TTDataOnSettlementsWithSuppliers
		|FROM
		|	(SELECT
		|		VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|		CASE
		|			WHEN VendorsARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
		|				THEN CASE
		|						WHEN NOT VendorsARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
		|							THEN VendorsARAPAccounting.Sum
		|							ELSE -VendorsARAPAccounting.Sum
		|					END
		|				ELSE CASE
		|					WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|							OR VendorsARAPAccounting.Recorder REFS Document.PurchaseAdjustment
		|							THEN 0
		|						ELSE VendorsARAPAccounting.Sum
		|					END
		|		END AS PaymentFact,
		|		CASE
		|			WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN VendorsARAPAccounting.AmountDue
		|			ELSE -VendorsARAPAccounting.AmountDue
		|		END AS AmountDue
		|	FROM
		|		Document.PurchaseOrder AS DocumentPurchaseOrder
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|			ON DocumentPurchaseOrder.ARAPObject = VendorsARAPAccounting.ARAPObject
		|	WHERE
		|		DocumentPurchaseOrder.Ref IN (&AnArrayOfOrders)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTCommunicationOrdersINVOICES.ARAPObjectOrder AS ARAPObject,
		|		0 AS PaymentFact,
		|		CASE
		|			WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|				THEN VendorsARAPAccounting.AmountDue
		|			ELSE -VendorsARAPAccounting.AmountDue
		|		END AS AmountDue
		|	FROM
		|		AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
		|			ON VendorsARAPAccounting.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice
		|	WHERE
		|		VendorsARAPAccounting.ARAPObject IN
		|				(SELECT
		|					T.ARAPObjectInvoice
		|				FROM
		|					TTCommunicationOrdersINVOICES AS T)) AS SettlementsData
		|
		|GROUP BY
		|	SettlementsData.ARAPObject
		|";
	
	Texts.Add(QueryText);
	
	QueryText = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

Function TextOfRequestForBalancesOfSettlements()
	
	QueryText = "
		|SELECT
		|	VendorsARAPAccounting.ARAPObject         AS ARAPObject,
		|	ISNULL(SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEU)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|			AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|		THEN VendorsARAPAccounting.AmountDue
		|		ELSE 0
		|	END), 0)                                       AS AmountDueReceipt,
		|	ISNULL(SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN VendorsARAPAccounting.AmountDue
		|		ELSE - VendorsARAPAccounting.AmountDue
		|	END), 0)                                       AS AmountDueClosingBalance,
		|	ISNULL(SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|		THEN VendorsARAPAccounting.ToReceive
		|		ELSE 0
		|	END), 0)                                       AS ToReceiveExpense,
		|	ISNULL(SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|		THEN VendorsARAPAccounting.Sum
		|		ELSE - VendorsARAPAccounting.Sum
		|	END), 0)                                       AS SumClosingBalance
		|INTO TTSettlementsWithSuppliersBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.ARAPObject IN (SELECT T.ARAPObject FROM TTCalculationObjects_ AS T)
		|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = VendorsARAPAccounting.ARAPObject.Organization
		|	AND VendorsARAPAccounting.Active
		|GROUP BY
		|	VendorsARAPAccounting.ARAPObject
		|";
	
	Return QueryText;
	
EndFunction

Function RequestTextStateOfOfflineSettlements(DocumentTypeByString)
	
	QueryText = "
		|SELECT 
		|	DocumentOrderDocument.Ref                               AS OrderDocument,
		|	DocumentOrderDocument.DocumentAmount                       AS OrderAmount,
		|	VendorsARAPAccountingBalance.AmountDueReceipt          AS PaidByOrder,
		|	TTDataOnSettlementsWithSuppliers.AmountDueClosingBalance AS RemainsToPay,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|			THEN CASE
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					THEN CAST (ISNULL(PaidForOrders.AmountDueReceipt, 0) AS NUMBER(31,2))
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|					THEN CAST (ISNULL(TTDataOnSettlementsWithSuppliers.PaymentFact, 0) AS NUMBER(31,2))
		|				ELSE 0
		|			END
		|		ELSE 0
		|	END                                           AS PayAmount,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|			THEN CASE
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					THEN CAST ((ISNULL(PaidForOrders.AmountDueReceipt, 0)) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|					THEN CAST ((ISNULL(TTDataOnSettlementsWithSuppliers.PaymentFact, 0)) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|				ELSE 0
		|			END
		|		ELSE 0
		|	END                                           AS PayPercentage,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN ISNULL(VendorsARAPAccountingBalance.ToReceiveExpense, 0)
		|		ELSE 0
		|	END                                           AS OrderReceiptAmount,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.ToReceiveExpense, 0) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|		ELSE 0
		|	END                                           AS PercentageOfOrderReceipt,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END                                           AS AmountOfDebt,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST((CASE 
		|				WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0 
		|					THEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0)
		|				ELSE ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0)
		|			END * 100 / DocumentOrderDocument.DocumentAmount) AS NUMBER(20, 10))
		|		ELSE 0
		|	END                                           AS DebtPercentage
		|
		|INTO TTStateOfSETTLEMENTS
		|FROM
		|	#DocumentName AS DocumentOrderDocument
		|	LEFT JOIN TTSettlementsWithSuppliersBalance AS VendorsARAPAccountingBalance
		|		ON DocumentOrderDocument.ARAPObject = VendorsARAPAccountingBalance.ARAPObject 
		|	LEFT JOIN PaidForOrders AS PaidForOrders
		|		ON DocumentOrderDocument.Ref = PaidForOrders.PurchaseOrder
		|	LEFT JOIN TTDataOnSettlementsWithSuppliers AS TTDataOnSettlementsWithSuppliers
		|		ON DocumentOrderDocument.ARAPObject = TTDataOnSettlementsWithSuppliers.ARAPObject
		|WHERE
		|	DocumentOrderDocument.Ref IN (&AnArrayOfOrders)
		|";
	
	QueryText = StrReplace(QueryText, "#DocumentName", DocumentTypeByString);
	
	Return QueryText;
	
EndFunction

Function QueryTextMutualSettlementsStatus()
	
	QueryText = "
		|SELECT ALLOWED
		|	ARAPObjects.Ref AS Ref,
		|	ARAPObjects.Object AS Object,
		|	ARAPObjects.Sum AS Sum,
		|	ARAPObjects.AmountARAP AS AmountARAP
		|INTO TTOrders
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN(&AnArrayOfOrders)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.ARAPObject.Object AS PurchaseOrder,
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|					AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEU)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseByImport)
		|						AND VendorsARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|			THEN VendorsARAPAccounting.AmountDue
		|		ELSE 0
		|	END) AS AmountDueReceipt,
		|	SUM(CASE WHEN VendorsARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|			THEN VendorsARAPAccounting.ToReceive
		|		ELSE 0
		|	END) AS ToReceiveExpense
		|INTO PaidForOrders
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
		|WHERE
		|	VendorsARAPAccounting.ARAPObject IN (
		|				SELECT T.Ref FROM TTOrders AS T)
		|	AND VendorsARAPAccounting.Active
		|	AND VendorsARAPAccounting.AccountingDimensionByPartners.Organization = VendorsARAPAccounting.ARAPObject.Organization
		|GROUP BY
		|	VendorsARAPAccounting.ARAPObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	SettlementsWithSuppliersTurnover.Recorder AS Recorder,
		|	SettlementsWithSuppliersTurnover.ARAPObject AS ARAPObject,
		|	SettlementsWithSuppliersTurnover.ToReceiveExpense AS ToReceiveExpense
		|INTO TTSettlementsWithSuppliers
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Turnovers(
		|			,
		|			,
		|			Recorder,
		|			ARAPObject IN
		|				(SELECT
		|					TTOrders.Ref
		|				FROM
		|					TTOrders)) AS SettlementsWithSuppliersTurnover
		|
		|INDEX BY
		|	Recorder,
		|	ARAPObject
		|;
		|
		|SELECT ALLOWED
		|	ARAPObjects.Ref AS ARAPObjectInvoice,
		|	ARAPObjectsOrder.Ref AS ARAPObjectOrder,
		|	ARAPObjectsOrder.Object AS PurchaseOrder,
		|	SUM(CAST(CASE
		|			WHEN ARAPObjects.AmountARAP = 0
		|				THEN CASE
		|						WHEN ARAPObjects.Sum = 0
		|							THEN 0
		|						ELSE SettlementsWithSuppliersTurnover.ToReceiveExpense / ARAPObjects.Sum
		|					END
		|			ELSE SettlementsWithSuppliersTurnover.ToReceiveExpense / ARAPObjects.AmountARAP
		|		END AS NUMBER(20,10))) AS OrderShare,
		|	MAX(CASE
		|			WHEN ARAPObjectsOrder.AmountARAP = 0
		|				THEN ARAPObjectsOrder.Sum
		|			ELSE ARAPObjectsOrder.AmountARAP
		|		END) AS OrderAmount
		|INTO TTCommunicationOrdersINVOICES
		|FROM
		|	TTSettlementsWithSuppliers AS SettlementsWithSuppliersTurnover
		|		INNER JOIN TTOrders AS ARAPObjectsOrder
		|		ON SettlementsWithSuppliersTurnover.ARAPObject = ARAPObjectsOrder.Ref
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON SettlementsWithSuppliersTurnover.Recorder = ARAPObjects.Object
		|			AND NOT ARAPObjects.DeletionMark
		|
		|GROUP BY
		|	ARAPObjects.Ref,
		|	ARAPObjectsOrder.Ref,
		|	ARAPObjectsOrder.Object
		|INDEX BY
		|	ARAPObjectInvoice
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PaymentPlan_.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	PaymentPlan_.ARAPObject AS ARAPObject,
		|	PaymentPlan_.AmountDueBalance AS Sum
		|INTO TTBalancesAmountDue
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(
		|			,
		|			ARAPObject IN
		|				(SELECT
		|					T.Ref
		|				FROM
		|					TTOrders AS T)) AS PaymentPlan_
		|WHERE
		|	PaymentPlan_.AmountDueBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	CalculationsByTerms.ARAPObject AS ARAPObject,
		|	CalculationsByTerms.DebtBalance AS Sum
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|			,
		|			ARAPObject IN
		|				(SELECT
		|					T.Ref
		|				FROM
		|					TTOrders AS T)) AS CalculationsByTerms
		|WHERE
		|	CalculationsByTerms.DebtBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	CalculationsByTerms.PlannedRepaymentDate AS PlannedRepaymentDate,
		|	TTCommunicationOrdersINVOICES.ARAPObjectOrder AS ARAPObject,
		|	CalculationsByTerms.DebtBalance AS Sum
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|			,
		|			ARAPObject IN
		|				(SELECT
		|					T.ARAPObjectInvoice
		|				FROM
		|					TTCommunicationOrdersINVOICES AS T)) AS CalculationsByTerms
		|		INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
		|		ON CalculationsByTerms.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
		|WHERE
		|	CalculationsByTerms.DebtBalance > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(BalanceAmountsDue.PlannedRepaymentDate) AS UpdateDate,
		|	BalanceAmountsDue.ARAPObject AS ARAPObject
		|INTO DatesWhenOrdersToSuppliersAreUpToDate
		|FROM
		|	TTBalancesAmountDue AS BalanceAmountsDue
		|
		|GROUP BY
		|	BalanceAmountsDue.ARAPObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTBalancesAmountDue
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	Calculations.OrderDocument AS OrderDocument,
		|	MAX(Calculations.AmountOfInitialSettlements) AS OrderAmount,
		|	CAST(ISNULL(SUM(Calculations.AmountOfPayments), 0) AS NUMBER(31,2)) AS PayAmount,
		|	CAST(ISNULL(SUM(Calculations.AmountOfPaymentsForOrder), 0) AS NUMBER(31,2)) AS PaidByOrder,
		|	
		|	-CAST(ISNULL(SUM(Calculations.RemainsToPay), 0) AS NUMBER(31,2)) AS RemainsToPay,
		|	
		|	CAST(ISNULL(SUM(Calculations.AmountOfDeliveries), 0) AS NUMBER(31,2)) AS OrderReceiptAmount,
		|	-CAST(ISNULL(SUM(Calculations.DebtAmount), 0) AS NUMBER(31,2)) AS AmountOfDebt,
		|	
		|	CASE WHEN CAST(ISNULL(SUM(Calculations.AmountOfPayments), 0) AS NUMBER(31,2)) = 0
		|		OR ISNULL(MAX(Calculations.AmountOfInitialSettlements), 0) = 0
		|			THEN 0
		|		ELSE CAST(CAST(SUM(Calculations.AmountOfPayments) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|	END AS PayPercentage,
		|	
		|	CASE WHEN CAST(ISNULL(SUM(Calculations.AmountOfDeliveries), 0) AS NUMBER(31,2)) = 0
		|		OR ISNULL(MAX(Calculations.AmountOfInitialSettlements), 0) = 0
		|			THEN 0
		|		ELSE CAST(CAST(SUM(Calculations.AmountOfDeliveries) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|	END AS PercentageOfOrderReceipt,
		|	
		|	CASE WHEN CAST(ISNULL(SUM(Calculations.DebtAmount), 0) AS NUMBER(31,2)) = 0
		|		OR ISNULL(MAX(Calculations.AmountOfInitialSettlements), 0) = 0
		|			THEN 0 
		|		WHEN ISNULL(SUM(Calculations.DebtAmount), 0) > 0
		|			THEN CAST(CAST(SUM(Calculations.DebtAmount) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|		ELSE - CAST(CAST(SUM(Calculations.DebtAmount) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|	END AS DebtPercentage
		|	
		|INTO TTStateOfSETTLEMENTS
		|FROM (SELECT
		|		ARAPObjects.Object AS OrderDocument,
		|		&TemplateForPaidField    AS AmountOfPayments,
		|		&TemplateForPaidField    AS AmountOfPaymentsForOrder,
		|		&TemplateForWriteOffField    AS AmountOfWriteOff,
		|		&FieldTemplateSupplied  AS AmountOfDeliveries,
		|		
		|		CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
		|			ELSE CalculationsByTerms.Prepayment - CalculationsByTerms.Debt
		|		END                  AS DebtAmount,
		|		
		|		0                      AS RemainsToPay,
		|		CASE WHEN ARAPObjects.AmountARAP = 0
		|			THEN ARAPObjects.Sum
		|			ELSE ARAPObjects.AmountARAP
		|		END                  AS AmountOfInitialSettlements
		|		
		|	FROM
		|			AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
		|				INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|				ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
		|		WHERE
		|			ARAPObjects.Object IN (&AnArrayOfOrders)
		|			AND CalculationsByTerms.AccountingDimensionByPartners.Organization = ARAPObjects.Organization
		|			AND CalculationsByTerms.Active
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTCommunicationOrdersINVOICES.PurchaseOrder                                                  AS OrderDocument,
		|		CAST((&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))   AS AmountOfPayments,
		|		CAST((&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))   AS AmountOfPaymentsForOrder,
		|		CAST((&TemplateForWriteOffField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))   AS AmountOfWriteOff,
		|		CAST((&FieldTemplateSupplied) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10)) AS AmountOfDeliveries,
		|		
		|		CAST(CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
		|			ELSE CalculationsByTerms.Prepayment - CalculationsByTerms.Debt
		|		END * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))                            AS DebtAmount,
		|		
		|		0                                                                                        AS RemainsToPay,
		|		TTCommunicationOrdersINVOICES.OrderAmount                                                      AS AmountOfInitialSettlements
		|		
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
		|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
		|			ON CalculationsByTerms.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
		|	WHERE
		|		CalculationsByTerms.ARAPObject IN (SELECT
		|							T.ARAPObjectInvoice
		|						FROM
		|							TTCommunicationOrdersINVOICES AS T)
		|		AND CalculationsByTerms.AccountingDimensionByPartners.Organization = CalculationsByTerms.ARAPObject.Organization
		|		AND CalculationsByTerms.Active
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTCommunicationOrdersINVOICES.PurchaseOrder AS OrderDocument,
		|		0 AS AmountOfPayments,
		|		0 AS AmountOfPaymentsForOrder,
		|		0 AS AmountOfWriteOff,
		|		0 AS AmountByShipments,
		|		0 AS DebtAmount,
		|		
		|		CAST(CalculationsByTerms.DebtBalance * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10)) AS RemainsToPay,
		|		TTCommunicationOrdersINVOICES.OrderAmount AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|				,
		|				ARAPObject IN
		|						(SELECT
		|							T.ARAPObjectInvoice
		|						FROM
		|							TTCommunicationOrdersINVOICES AS T)
		|					AND AccountingDimensionByPartners.Organization = ARAPObject.Organization) AS CalculationsByTerms
		|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
		|			ON CalculationsByTerms.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ARAPObjects.Object AS OrderDocument,
		|		0 AS AmountOfPayments,
		|		0 AS AmountOfPaymentsForOrder,
		|		0 AS AmountOfWriteOff,
		|		0 AS AmountByShipments,
		|		0 AS DebtAmount,
		|		
		|		CalculationsByTerms.DebtBalance AS RemainsToPay,
		|		CASE
		|			WHEN ARAPObjects.AmountARAP = 0
		|				THEN ARAPObjects.Sum
		|			ELSE ARAPObjects.AmountARAP
		|		END AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(
		|				,
		|				ARAPObject.Object IN (&AnArrayOfOrders)
		|					AND AccountingDimensionByPartners.Organization = ARAPObject.Organization) AS CalculationsByTerms
		|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON CalculationsByTerms.ARAPObject = ARAPObjects.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ARAPObjects.Object OrderDocument,
		|		0 AS AmountOfPayments,
		|		0 AS AmountOfPaymentsForOrder,
		|		0 AS AmountOfWriteOff,
		|		0 AS AmountByShipments,
		|		0 AS DebtAmount,
		|		
		|		ScheduledPayments_.AmountDueBalance AS RemainsToPay,
		|		CASE
		|			WHEN ARAPObjects.AmountARAP = 0
		|				THEN ARAPObjects.Sum
		|			ELSE ARAPObjects.AmountARAP
		|		END AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(
		|				,
		|				ARAPObject.Object IN (&AnArrayOfOrders)
		|					AND AccountingDimensionByPartners.Organization = ARAPObject.Organization) AS ScheduledPayments_
		|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ScheduledPayments_.ARAPObject = ARAPObjects.Ref
		|	) AS Calculations
		|GROUP BY
		|	Calculations.OrderDocument
		|INDEX BY
		|	OrderDocument
		|";
	
	QueryText = StrReplace(
		QueryText,
		"&TemplateForPaidField",
		StrTemplate(
			"%1 + %2",
			ARAPAccountingReports.TemplateForPaidField(),
			ARAPAccountingReports.TemplateOfCreditedField()));
	// It is needed to compensate for the amount of adjustments from the template of the Shipped field
	TemplateForAmountOfAdjustmentsField = "
		|CASE 
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoicePrepaymentIncrease)
		|		THEN Prepayment
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.InvoiceAdjustmentDebtDecrease)
		|		THEN Debt
		|	WHEN CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.AdjustmentOfInvoiceDebtIncrease)
		|		THEN -Debt
		|	WHEN VALUETYPE(CalculationsByTerms.DocumentRecorder) = TYPE(Document.PurchaseAdjustment)
		|		AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease)
		|		THEN -Debt
		|	ELSE 0
		|END";
	QueryText = StrReplace(
		QueryText,
			"&FieldTemplateSupplied",
			StrTemplate(
				"%1 + %2",
				ARAPAccountingReports.TemplateOfShippedField(),
				TemplateForAmountOfAdjustmentsField));
	QueryText = StrReplace(QueryText, "&TemplateForWriteOffField", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	Return QueryText;
	
EndFunction

Function QueryTextVendorsARAPAccounting(Query)
	
	QueryText =
	"SELECT
	|	ARAPObjects.Object AS ReflectedDocument
	|FROM
	|	VendorsARAPAccountingChanges AS Table
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Ref = Table.ARAPObject
	|WHERE
	|	ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|
	|UNION ALL
	|
	|SELECT 
	|	VendorsARAPAccounting.PurchaseByOrder AS ReflectedDocument
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting AS VendorsARAPAccounting
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = VendorsARAPAccounting.PurchaseByOrder
	|		AND NOT ARAPObjects.DeletionMark
	|		INNER JOIN VendorsARAPAccountingChanges AS VendorsARAPAccountingChanges
	|		ON VendorsARAPAccounting.AccountingDimensionByPartners = VendorsARAPAccountingChanges.AccountingDimensionByPartners
	|		AND VendorsARAPAccounting.ARAPObject = VendorsARAPAccountingChanges.ARAPObject
	|WHERE
	|	VendorsARAPAccounting.PurchaseByOrder <> UNDEFINED
	|	AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextGoodsToReceive(Query)
	
	QueryText =
	"SELECT
	|	Table.DocumentInflow AS ReflectedDocument
	|FROM
	|	GoodsToReceiveUpdate AS Table
	|WHERE
	|	VALUETYPE(Table.DocumentInflow) IN (TYPE(Document.PurchaseOrder))
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextDocumentsRegistry(Query)
	
	QueryText =
	"SELECT
	|	Table.Ref AS ReflectedDocument
	|FROM
	|	RegisterOfDocumentsChanges AS Table
	|WHERE
	|	Table.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

#EndRegion

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.PurchaseOrderStates.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.21";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("d3bf7218-7da7-48b7-96f7-9858407977b6");
	Handler.Multithreaded = True;
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.PurchaseOrderStates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Cập nhật trong biểu ghi thông tin ""Trạng thái đơn hàng đặt nhà cung cấp"" trạng thái của đơn hàng
	| có trong các chứng từ ""Biên bản chênh lệch sau khi nhập hàng"", khi việc lập chứng từ mua hàng
	| và ""Điều chỉnh mua hàng"" được thực hiện riêng biệt, khi lập chứng từ mua hàng hoặc nội dung công việc được thực hiện riêng biệt.';
	|ru = 'Обновляет в регистре сведений ""Состояния заказов поставщикам"" состояния заказов
	| содержащихся в оформленных документах ""Акт о расхождениях после приемки"", при раздельном оформлении закупок
	| и ""Корректировка приобретения"", при раздельном оформлении закупок, либо содержащих работы.';
	|en = 'Updates order states in the ""Purchase order states"" information register
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" documents with separate registration of purchases or with works.'; fa = 'Updates order states in the ""Purchase order states"" information register
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" documents with separate registration of purchases or with works.';
	|it = 'Updates order states in the ""Purchase order states"" information register
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" documents with separate registration of purchases or with works.';
	|pl = 'Updates order states in the ""Purchase order states"" information register
	|contained in the issued ""Receipt discrepancy report"" documents with separate registration of purchases
	| and in the ""Purchase adjustment"" documents with separate registration of purchases or with works.';
	|tr = '""Satın alma siparişlerinin durumu"" bilgi kaydında, ayrı ayrı düzenlenen satın alımlarda ""Stok farkları raporu""
	| belgesinde yer alan siparişlerin durumunu ve ayrı ayrı düzenlenen satın alımlarda veya işleri içeren ""Satın alma düzeltmesi""
	| belgesinde yer alan siparişlerin durumunu günceller.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.PurchaseOrderStates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.GoodsToReceive.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = "InformationRegister.PurchaseOrderStates";
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", "InformationRegister.PurchaseOrderStates");
	
	NameOfRegisterOfGoodsToBeReceived = "GoodsToReceive";
	FullNameOfRegisterGoodsToBeReceived = "AccumulationRegister.GoodsToReceive";
	
	AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	AddlParameters.GetQueryTexts = True;
	
	QueryTexts = Documents.DiscrepancyReportFollowingReceipt.DocumentDataForPosting(
		Undefined,
		NameOfRegisterOfGoodsToBeReceived,
		AddlParameters);
	
	CommonTemporaryTables = New Array();
	Documents.DiscrepancyReportFollowingReceipt.QueryTextDocumentData(CommonTemporaryTables);
	RecordersCertificatesAfterAcceptance = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterGoodsToBeReceived,
		"Document.DiscrepancyReportFollowingReceipt",
		CommonTemporaryTables);
	
	QueryTexts = Documents.PurchaseAdjustment.DocumentDataForPosting(
		Undefined,
		NameOfRegisterOfGoodsToBeReceived,
		AddlParameters);
	
	AcquisitionAdjustmentRecorders = DocumentsPosting.CallLoggers(
		QueryTexts,
		FullNameOfRegisterGoodsToBeReceived,
		"Document.PurchaseAdjustment");
	
	Query = New Query;
	Query.SetParameter("RecordersCertificatesAfterAcceptance", RecordersCertificatesAfterAcceptance);
	Query.SetParameter("AcquisitionAdjustmentRecorders", AcquisitionAdjustmentRecorders);
	Query.Text =
		"SELECT
		|	DocumentTable.PurchaseOrder AS OrderDocument
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS DocumentTable
		|WHERE
		|	DocumentTable.Ref.Posted
		|	AND DocumentTable.Ref IN (&RecordersCertificatesAfterAcceptance)
		|	AND DocumentTable.Ref.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
		|	AND VALUETYPE(DocumentTable.PurchaseOrder) = TYPE(Document.PurchaseOrder)
		|	AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
		|
		|UNION
		|
		// The transfer of RegisteredRecords to reflect discrepancies in the acquisition adjustment.
		|SELECT
		|	DocumentTable.PurchaseOrder AS OrderDocument
		|FROM
		|	Document.PurchaseAdjustment.Discrepancies AS DocumentTable
		|WHERE
		|	DocumentTable.Ref.Posted
		|	AND DocumentTable.Ref IN (&AcquisitionAdjustmentRecorders)
		|	AND DocumentTable.Ref.BusinessOperation IN(
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
		|		VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit))
		|	AND VALUETYPE(DocumentTable.PurchaseOrder) = TYPE(Document.PurchaseOrder)
		|	AND DocumentTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)";
	
	RecordedMeasurements = Query.Execute().Unload();
	InfobaseUpdate.MarkForProcessing(Parameters, RecordedMeasurements, AdditionalParameters);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.PurchaseOrderStates";
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "AccumulationRegister.GoodsToReceive") Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;

	TableUpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	For Each String In TableUpdatedData Do
		
		Set = Undefined;
		
		BeginTransaction();
		Try
			
			Block = New DataLock();
			
			LockItem = Block.Add("InformationRegister.PurchaseOrderStates");
			LockItem.SetValue("OrderDocument", String.OrderDocument);
			
			Block.Lock();
			
			OrderStateTable = OrderStateTable(CommonClientServer.ValueInArray(String.OrderDocument));
			
			TableRow = OrderStateTable[0];
			ProcessStateTableRow(TableRow);
			
			Set = InformationRegisters.PurchaseOrderStates.CreateRecordSet();
			Set.Filter.OrderDocument.Set(TableRow.OrderDocument);
			SetRow = Set.Add();
			FillPropertyValues(SetRow, TableRow);
			
			InfobaseUpdate.WriteRecordSet(Set);
			CommitTransaction();
			
		Except
			RollbackTransaction();
			If Set = Undefined Then
				Set = CreateRecordSet();
				Set.Filter.OrderDocument.Set(String.OrderDocument);
			EndIf;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Set);
		EndTry;
		
	EndDo;
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf