#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function returns the state table of the orders of clients and companies
//
// Parameters:
// 	ReferencesArrray - Array of DocumentRef - array of orders whose status tables you want to get
//
// Returns:
// 	Structure - a State structure containing values:
// 		* OrderStateTable - ValueTable
// 		* TableOfPreviousOrderStates - ValueTable
//
Function OrderStateTables(ReferencesArrray) Export
	
	OrderStateTable = OrderStateTable(ReferencesArrray);
	TableOfPreviousOrderStates = TableOfPreviousOrderStates(ReferencesArrray);
	
	Result = New Structure;
	Result.Insert("OrderStateTable", OrderStateTable);
	Result.Insert("TableOfPreviousOrderStates", TableOfPreviousOrderStates);
	
	Return Result;
	
EndFunction

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
	|	Table.Ref AS OrderDocument,
	|	NOT Table.Posted AS RemovalOfBody
	|FROM
	|	Document.SalesOrder AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS OrderDocument,
	|	NOT Table.Posted AS RemovalOfBody
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS OrderDocument,
	|	NOT Table.Posted AS RemovalOfBody
	|FROM
	|	Document.MaterialProviderOrder2_5 AS Table
	|WHERE
	|	Table.Ref IN (&Orders)
	|	AND TRUE
	|	AND TRUE";
	
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
//	Map of String - matching the names of the register change tables and query texts.
//	
Function MatchingRequestsToControlRegisters(Query) Export
	
	MatchingTasks = New Map();
	MatchingTasks.Insert("RegisterOfDocumentsChanges", QueryTextDocumentsRegistry(Query));
	MatchingTasks.Insert("RegisteredRecordsOfShipmentOrderUpdate", QueryTextShipmentReferences(Query));
	MatchingTasks.Insert("SettlementsWithCustomersChanges", QueryTextCustomersARAPAccounting(Query));
	MatchingTasks.Insert("RegisteredRecordsGoodsForIssueUpdate", QueryTextGoodsForIssue(Query));
	MatchingTasks.Insert("GoodsToReceiveUpdate", QueryTextGoodsToReceive(Query));
	
	If Not InventoryAllocation.CountRegisterWithRoutineTask() Then
		
		MatchingTasks.Insert("SalesOrderStatesUpdate",
			QueryTextSalesOrderStatesUpdate(Query));
		
	EndIf;
	
	Return MatchingTasks;
	
EndFunction

// Adds tasks to reflect the State of orders in the document management mechanism.
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
	
EndProcedure

#Region InterfaceImplementation

// When determining the available types of user alerts.
// 
// Parameters:
//  DescriptionOfNotificationKinds - See UserNotificationsOfEvents.DescriptionOfUserNotificationKinds
Procedure OnDeterminingAvailableUserNotificationKinds(DescriptionOfNotificationKinds) Export
	
	SalesNotificationTypeGroup = UserNotificationsOfEvents.NotificationTypeGroup("Sales");
	
	NewTypeOfAlerts = UserNotificationsOfEvents.AddDescriptionOfTypeOfUserAlerts(DescriptionOfNotificationKinds);
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "97303299-a061-4401-af2c-cf94765427e7";
	NewTypeOfAlerts.Description = NStr("vi = 'Các đơn hàng (bán) đang chờ thống nhất';
										|ru = 'Ожидающие согласования заказы (Продажи)';
										|en = 'Orders pending approval (Sales)'; fa = 'Orders pending approval (Sales)';
										|it = 'Orders pending approval (Sales)';
										|pl = 'Orders pending approval (Sales)';
										|tr = 'Onay bekleyen siparişler (Satışlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.InformationRegisters.SalesOrderStates.Templates.Notifications_PendingApproval.FullName();
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
	NewTypeOfAlerts.NotificationTypeGroup = SalesNotificationTypeGroup;
	NewTypeOfAlerts.Id = "857b24b4-8f05-4829-8cf4-9cc879494dea";
	NewTypeOfAlerts.Description = NStr("vi = 'Các đơn hàng (bán) chuẩn bị đóng';
										|ru = 'Готовые к закрытию заказы (Продажи)';
										|en = 'Fulfilled orders (Sales)'; fa = 'Fulfilled orders (Sales)';
										|it = 'Fulfilled orders (Sales)';
										|pl = 'Fulfilled orders (Sales)';
										|tr = 'Kapatılmaya hazır siparişler (Satışlar)'", Common.DefaultLanguageCode());
	NewTypeOfAlerts.NotificationType = Enums.UserNotificationTypes.NonOperational;
	NewTypeOfAlerts.DCSTemplateName = Metadata.InformationRegisters.SalesOrderStates.Templates.Notifications_ReadyForClosure.FullName();
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

// Returns parameters for updating the State of orders.
//
// Returns:
// 	Structure:
// 		* RecordSelectionRule - String
// 		* RecordComparisonFunction - String
// 		* FunctionForComparingRecordsInTemporaryTable - String
//
Function ParametersForUpdatingOrderStates() Export
	
	Result = New Structure;
	
	Result.Insert("RecordSelectionRule",
		"SELECT DISTINCT
		|	InventoryAllocation.ShipmentOrder AS ShipmentOrder
		|INTO TableOverridable
		|FROM
		|	FilterOverridable AS Goods
		|		
		|		LEFT JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|		ON InventoryAllocation.Products  = Goods.Products
		|		AND InventoryAllocation.Characteristic = Goods.Characteristic
		|		AND InventoryAllocation.Warehouse          = Goods.Warehouse
		|		AND InventoryAllocation.Purpose     = Goods.Purpose
		|		AND InventoryAllocation.InventoryState IN(
		|			VALUE(Enum.InventoryStates.NotProvided),
		|			VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|			VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|			VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|		AND InventoryAllocation.DemandCharacteristic IN(
		|			VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|			VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|			VALUE(Enum.DemandCharacteristics.ToSupply))
		|			
		|WHERE
		|	NOT InventoryAllocation.Products IS NULL
		|		AND VALUETYPE(InventoryAllocation.ShipmentOrder) IN(
		|			TYPE(Document.SalesOrder),
		|			TYPE(Document.MaterialProviderOrder2_5),
		|			TYPE(Document.RequestForReturnOfGoodsFromCustomer))
		|INDEX BY
		|	ShipmentOrder");
		
	Result.Insert("FunctionForComparingRecordsInTemporaryTable",
		"SELECT
		|	BeforeWrite.ShipmentOrder AS OrderDocument
		|INTO UpdateOverridable
		|FROM
		|	BeforeWriteOverridable AS BeforeWrite
		|		
		|		LEFT JOIN OnWriteOverridable AS OnWrite
		|		ON OnWrite.ShipmentOrder = BeforeWrite.ShipmentOrder
		|WHERE
		|		OnWrite.ShipmentOrder IS NULL
		|
		|UNION
		|
		|SELECT
		|	OnWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	OnWriteOverridable AS OnWrite
		|		
		|		LEFT JOIN BeforeWriteOverridable AS BeforeWrite
		|		ON BeforeWrite.ShipmentOrder = OnWrite.ShipmentOrder
		|WHERE
		|	BeforeWrite.ShipmentOrder IS NULL");
	
	Result.Insert("RecordComparisonFunction",
		StrReplace(Result.FunctionForComparingRecordsInTemporaryTable,
			"INTO UpdateOverridable", ""));
	
	Return Result;
	
EndFunction

// Returns the types of orders for which States should be reflected.
//
// Returns:
//  Array of Type - Types of State reflection orders
//
Function TypesOfOrdersToReflectStates() Export
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.SalesOrder"));
	OrderTypes.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	OrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	
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
//	Parameters:
//  Orders - DocumentRef - a document that is used to recalculate the state
//  RemovalOfBody - Boolean - indicates whether the deletion is processed.
//  Errors - See ReflectOrderStates.Errors
//
Procedure ReflectOrderState(Orders, RemovalOfBody = False, Errors = Undefined)
	
	If RemovalOfBody Then
		
		For Each OrderDocument In Orders Do
			
			Set = InformationRegisters.SalesOrderStates.CreateRecordSet();
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
		
		Return;
		
	EndIf;
	
	TheStructureOfTheSearch = New Structure("OrderDocument, State, EventDate, 
		|PayAmount, PayPercentage, AmountByShipment, OrderShipmentPercentage, AmountOfDebt, DebtPercentage, ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice");
	
	OrderStateTable = OrderStateTable(Orders);
	TableOfPreviousOrderStates = TableOfPreviousOrderStates(Orders);
	
	For Each TableRow In OrderStateTable Do
		
		FillPropertyValues(TheStructureOfTheSearch, TableRow);
		ArrayOfValidStates = TableOfPreviousOrderStates.FindRows(TheStructureOfTheSearch);
		
		StateChanged = Not Boolean(ArrayOfValidStates.Count());
		If StateChanged Then
			
			Set = InformationRegisters.SalesOrderStates.CreateRecordSet();
			Set.Filter.OrderDocument.Set(TableRow.OrderDocument);
			
			SetRow = Set.Add();
			
			RoundUpPercentages(TableRow.OrderShipmentPercentage);
			RoundUpPercentages(TableRow.PayPercentage);
			RoundUpPercentages(TableRow.DebtPercentage);
			
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

Function EventLogEvent()
	
	Return NStr("vi = 'Lỗi phản ánh trạng thái đơn hàng theo trình tự';
				|ru = 'Ошибка отражения состояния заказов в очереди';
				|en = 'Error recording order states in the queue'; fa = 'Error recording order states in the queue';
				|it = 'Errore di registrazione dello stato degli ordini in coda';
				|pl = 'Błąd odzwierciedlenie statusu zamówień w kolejce';
				|tr = 'Kuyruktaki siparişlerin durumlarının yansıtılma hatası'", Common.DefaultLanguageCode());
	
EndFunction

Function ReflectionErrorText(OrderDocument, ErrorInfo)
	
	If TypeOf(OrderDocument) = Type("DocumentRef.SalesOrder") Then
		
		Template = NStr("vi = 'Không thể phản ánh trạng thái đơn hàng của khách: %1 do: %2';
						|ru = 'Не удалось отразить состояние заказа клиента: %1 по причине: %2';
						|en = 'Cannot record the state of the sales order: %1. Reason: %2'; fa = 'Cannot record the state of the sales order: %1. Reason: %2';
						|it = 'Не удалось отразить состояние заказа клиента: %1 по причине: %2';
						|pl = 'Cannot record the state of the sales order: %1. Reason: %2';
						|tr = 'Müşteri siparişinin durumu yansıtılamadı: %1 nedeni: %2'");
		
	ElsIf TypeOf(OrderDocument) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		Template = NStr("vi = 'Không thể phản ánh trạng thái của giấy đề nghị trả lại: %1 do: %2';
						|ru = 'Не удалось отразить состояние заявки на возврат: %1 по причине: %2';
						|en = 'Cannot record the state of the return request: %1. Reason: %2'; fa = 'Cannot record the state of the return request: %1. Reason: %2';
						|it = 'Не удалось отразить состояние заявки на возврат: %1 по причине: %2';
						|pl = 'Cannot record the state of the return request: %1. Reason: %2';
						|tr = 'İade talebinin durumu yansıtılamadı: %1 nedeni: %2'");
		
	ElsIf TypeOf(OrderDocument) = Type("DocumentRef.MaterialProviderOrder2_5") Then
		
		Template = NStr("vi = 'Không thể phản ánh trạng thái đơn hàng của người đặt gia công: %1 theo nguyên nhân: %2';
						|ru = 'Не удалось отразить состояние заказа давальца: %1 по причине: %2';
						|en = 'Cannot record the state of the subcontracting sales order: %1. Reason: %2'; fa = 'Cannot record the state of the subcontracting sales order: %1. Reason: %2';
						|it = 'Не удалось отразить состояние заказа давальца: %1 по причине: %2';
						|pl = 'Odzwierciedlenie statusu zamówienia właścicieli surowców nie powiodło się: %1 z powodu: %2';
						|tr = '%2 nedeniyle tedarikçi siparişinin durumu yansıtılamadı: %1'");
	EndIf;
	
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
//		ReferencesArrray - Array of DocumentRef - links to documents that
//					need to be used to calculate the status. A function must be defined in the document manager module
//					The text of the request is for the calculation of the actual status of orders(), which returns the Query Text by date of relevance and
//					The text of the request is for calculating the order statuses(), which returns the Query Text by order statuses.
//	Returns:
//		ValueTable:
//			Order - Document Link
//			Status - Listing link.Client statesacases, enumerationslink.Client's states of returnreferences
//			Dates of the event - Date
//			The payment amount is a number
//			Percentage payments - Number
//			The loading amount is a number
//			Percentage of load - Number
//			Sum Debt - Number
//			Debt percentage is a number
//			There is a difference between the order of the layout - Boolean.
//
Function OrderStateTable(ReferencesArrray)
	
	ConformityOfTypes = TMCommonUse.MatchingArraysByObjectType(ReferencesArrray);
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	PackageTexts = New Array;
	PackageTexts.Add(RequestTextForCalculatingDatesOfOrderStateEvents());
	PackageTexts.Add(RequestTextForCalculatingOrderSecurityStates());
	PackageTexts.Add(QueryTextPartiallyInStock());
	PackageTexts.Add(RequestTextForCalculatingDiscrepanciesOrderInvoice());
	PackageTexts.Add(TextOfRequestForPaymentOfServicesToGiverForRegistration());
	RequestTextForAcceptableDeviations = RequestTextForAcceptableDeviations(ConformityOfTypes);
	If Not IsBlankString(RequestTextForAcceptableDeviations) Then
		PackageTexts.Add(RequestTextForAcceptableDeviations);
	EndIf;
	
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
		
		If DocumentType.Key = "Document.SalesOrder"
			Or DocumentType.Key = "Document.MaterialProviderOrder2_5"
			Or DocumentType.Key = "Document.RequestForReturnOfGoodsFromCustomer" Then
			
			ObjectManager             = Common.ObjectManagerByFullName(DocumentType.Key);
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
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = StrConcat(PackageTexts, Common.QueryBatchSeparator());
	Query.SetParameter("AnArrayOfOrders", ReferencesArrray);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("ManagerCreatesOrders", Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.ByManager);
	Query.SetParameter("MonitorOrderClosing", 
			GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
				Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment"));
				
	
	Query.SetParameter(
			"ControlClosingOfGiverSOrder2_5",
			GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompletePayment2_5")
			Or GetFunctionalOption("DoNotCloseMaterialProviderOrdersWithoutCompleteFulfillment2_5"));
	Query.SetParameter("DimensionalTypesOfQuantities", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("ShipmentAndReturnReferences",
																"ReferenceOrder IN (&AnArrayOfOrders)",
																Query.Parameters);
	
	Query.SetParameter("InitialCustomerOrders", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodCustomerOrders", SpeedLimits.MaxDate);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("GoodsForIssue",
																"DocumentShipments IN (&AnArrayOfOrders)",
																Query.Parameters);
	
	Query.SetParameter("InitialGoodsForShipment", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriodGoodsReadyForShipment", SpeedLimits.MaxDate);
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
		|	MIN(InventoryAndDemands.EventDate) AS MinimumShipmentDate,
		|	InventoryAndDemands.OrderDocument AS SalesOrder
		|INTO ShippingDatesOfCustomerOrders
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(, OrderDocument IN(&AnArrayOfOrders)) AS InventoryAndDemands
		|WHERE
		|	InventoryAndDemands.ReserveAtWarehouseBalance > 0
		|		OR InventoryAndDemands.ReserveAsReceivedBalance > 0
		|		OR InventoryAndDemands.SnoozeReservationBalance > 0
		|		OR InventoryAndDemands.ToSupplyBalance > 0
		|		OR InventoryAndDemands.NotProvideBalance > 0
		|GROUP BY
		|	InventoryAndDemands.OrderDocument";
	
	Return QueryText;
	
EndFunction

// The function returns the text of the query to calculate the States of the orders.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingOrderSecurityStates()
	
	QueryText = "
		|SELECT
		|	Table.Ref AS Ref,
		|	MAX(Table.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|				AND Table.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))) AS ThereIsToProvision,
		|	MAX(Table.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.ToSupply),
		|				VALUE(Enum.SupplyOptions.ReserveAsReceived))) AS ThereAreThoseRequiringDistributionOfStocks,
		|	
		|	MIN(Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)) AS ShipEverything
		|INTO TTOrderAssurance
		|FROM
		|	Document.SalesOrder.Goods AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND NOT Table.Canceled
		|
		|GROUP BY
		|	Table.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	MAX(Table.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|				AND Table.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))) AS ThereIsToProvision,
		|	MAX(Table.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.ToSupply),
		|				VALUE(Enum.SupplyOptions.ReserveAsReceived))) AS ThereAreThoseRequiringDistributionOfStocks,
		|	
		|	MIN(Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)) AS ShipEverything
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|		AND NOT Table.Canceled
		|
		|GROUP BY
		|	Table.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref AS Ref,
		|	MAX(Table.SupplyOption = VALUE(Enum.SupplyOptions.NotRequired)
		|				AND Table.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))) AS ThereIsToProvision,
		|	
		|	MAX(Table.SupplyOption IN(
		|				VALUE(Enum.SupplyOptions.ToSupply),
		|				VALUE(Enum.SupplyOptions.ReserveAsReceived))) AS ThereAreThoseRequiringDistributionOfStocks,
		|	
		|	MIN(CASE WHEN Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship) THEN
		|				TRUE
		|			ELSE
		|				FALSE
		|		END) AS ShipEverything
		|FROM
		|	Document.MaterialProviderOrder2_5.ManufacturedProduct AS Table
		|WHERE
		|	Table.Ref IN(&AnArrayOfOrders)
		|	AND NOT Table.Canceled
		|
		|GROUP BY
		|	Table.Ref
		|";
	
	Return QueryText
	
EndFunction

// The function returns the request text for getting data about services to the giver for registration.
//
// Returns:
//	String - Query text
//
Function TextOfRequestForPaymentOfServicesToGiverForRegistration()
	
	QueryText =
	"SELECT
	|	ShippingOrdersTurnover.ReferenceOrder AS OrderDocument,
	|	(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|		ShippingOrdersTurnover.IssuedQuantityTurnover) AS ToRegister
	|INTO TTServicesToGiverForRegistration
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
	|WHERE
	|	(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
	|		ShippingOrdersTurnover.IssuedQuantityTurnover) <> 0
	|INDEX BY
	|	OrderDocument";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN (&AnArrayOfOrders)
		|		AND VALUETYPE(ReferenceOrder) = TYPE(Document.MaterialProviderOrder2_5)";
	TableFormationParameters.Group = "ReferenceOrder";
	TableFormationParameters.Indicators = "ToRegister, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Return StrReplace(QueryText,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
EndFunction
// The function returns the request text for calculating order-invoice discrepancies.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingDiscrepanciesOrderInvoice()
	
	QueryText = RequestTextForCalculationThereIsOrder() + "
		|SELECT
		|	GoodsForIssue.DocumentShipments AS SalesOrder,
		|	MAX(CASE
		|		WHEN GoodsForIssue.ToRegisterReceipt > 0 
		|			AND GoodsForIssue.ToRegisterExpense <> (GoodsForIssue.AssembledReceipt + GoodsForIssue.ToShipExpense) THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
		|	MAX(CASE
		|		WHEN &ManagerCreatesOrders
		|			AND (GoodsForIssue.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|				AND GoodsForIssue.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= ISNULL(DetailsOfOrder.IBDocumentDate, DATETIME(1,1,1)))
		|			AND TTHasWarrant.ThereSWarrant IS NULL THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END) AS WarrantRequired
		|INTO TTDiscrepanciesOrderInvoice
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(,,,,DocumentShipments IN (&AnArrayOfOrders)) AS GoodsForIssue
		|		LEFT JOIN TTHasWarrant AS TTHasWarrant
		|			ON GoodsForIssue.DocumentShipments = TTHasWarrant.SalesOrder
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS DetailsOfOrder
		|			ON GoodsForIssue.DocumentShipments = DetailsOfOrder.Ref
		|				AND NOT DetailsOfOrder.AdditionalRecord
		|
		|GROUP BY
		|	GoodsForIssue.DocumentShipments
		|
		|INDEX BY
		|	SalesOrder
		|";
	
	Return QueryText;
	
EndFunction

// The function returns the query text for searching for spending orders.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculationThereIsOrder()
	
	QueryText = "
		|SELECT
		|	GoodsForIssue.DocumentShipments AS SalesOrder,
		|	TRUE AS ThereSWarrant
		|INTO TTHasWarrant
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(, , Recorder, , DocumentShipments IN (&AnArrayOfOrders)) AS GoodsForIssue
		|WHERE
		|	GoodsForIssue.Recorder REFS Document.GoodsIssueNote
		|GROUP BY
		|	GoodsForIssue.DocumentShipments
		|INDEX BY
		|	SalesOrder
		|;
		|";
	
	Return QueryText
	
EndFunction

// The function returns a table of values with document States.
//
//	Parameters:
//		ReferencesArrray - Array of DocumentRef - links to documents that
//					need to be used to calculate the status. A function must be defined in the document manager module
//					The text of the request is for the calculation of the actual status of orders(), which returns the Query Text by date of relevance and
//					The text of the request is for calculating the order statuses(), which returns the Query Text by order statuses.
//	Returns:
//		ValueTable:
//			Order - Document Link
//			Status - Listing link.Client statesacases, enumerationslink.Client's states of returnreferences
//			Dates of the event - Date
//			The payment amount is a number
//			Percentage payments - Number
//			The loading amount is a number
//			Percentage of load - Number
//			Sum Debt - Number
//			Debt percentage is a number
//			There is a difference between the order of the layout - Boolean.
//
Function TableOfPreviousOrderStates(ReferencesArrray)
	
	Query = New Query("SELECT
	|	SalesOrderStates.OrderDocument AS OrderDocument,
	|	SalesOrderStates.State AS State,
	|	SalesOrderStates.EventDate AS EventDate,
	|	SalesOrderStates.PayAmount AS PayAmount,
	|	SalesOrderStates.PayPercentage AS PayPercentage,
	|	SalesOrderStates.AmountByShipment AS AmountByShipment,
	|	SalesOrderStates.OrderShipmentPercentage AS OrderShipmentPercentage,
	|	SalesOrderStates.AmountOfDebt AS AmountOfDebt,
	|	SalesOrderStates.DebtPercentage AS DebtPercentage,
	|	SalesOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
	|FROM
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|WHERE
	|	SalesOrderStates.OrderDocument IN(&ReferencesArrray)");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Return Query.Execute().Unload();
	
EndFunction

Function QueryTextPartiallyInStock()
	
	QueryText =
		"
		|SELECT
		|	Orders.Ref AS Ref
		|INTO TTPartiallyInStock
		|FROM
		|	TTOrderAssurance AS Orders
		|WHERE
		|	Orders.ThereAreThoseRequiringDistributionOfStocks
		|	AND(
		|		TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				InformationRegister.InventoryAllocation AS InformationRecords
		|			WHERE
		|				InformationRecords.ShipmentOrder = Orders.Ref
		|					AND InformationRecords.InventoryState IN(
		|						VALUE(Enum.InventoryStates.NotProvided),
		|						VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|						VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|						VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|					AND InformationRecords.DemandCharacteristic IN(
		|						VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|						VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|						VALUE(Enum.DemandCharacteristics.ToSupply)))
		// the document was not held
		|		OR NOT TRUE IN(
		|			SELECT TOP 1
		|				TRUE AS ThereAreRecords
		|			FROM
		|				InformationRegister.InventoryAllocation AS InformationRecords
		|			WHERE
		|				InformationRecords.ShipmentOrder = Orders.Ref))
		|";
	
	Return QueryText
	
EndFunction

// The function returns the request text for calculating the permissible deviations of measured products.
Function RequestTextForAcceptableDeviations(ConformityOfTypes)
	
	If ConformityOfTypes["Document.SalesOrder"] <> Undefined
		Or ConformityOfTypes["Document.RequestForReturnOfGoodsFromCustomer"] <> Undefined
		Or ConformityOfTypes["Document.MaterialProviderOrder2_5"] <> Undefined
		Then
		
		QueryText =
		"SELECT
		|	TableOfRevolutions.ReferenceOrder AS ReferenceOrder,
		|	TableOfRevolutions.RowCode AS RowCode,
		|	MAX(TableOfRevolutions.Warehouse) AS Warehouse,
		|	MAX(TableOfRevolutions.Series) AS Series
		|INTO TableSeriesWarehouses
		|FROM
		|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(,,, ReferenceOrder IN (&AnArrayOfOrders)
		|	AND CASE
		|		WHEN Factor IN
		|		(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
		|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted))
		|			THEN Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE TRUE
		|	END
		|	AND RowCode <> 0
		|	AND Factor IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered),
		|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip),
		|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped))) AS TableOfRevolutions
		|GROUP BY
		|	TableOfRevolutions.ReferenceOrder,
		|	TableOfRevolutions.RowCode
		|
		|INDEX BY
		|	ReferenceOrder,
		|	RowCode
		|;
		|
		|SELECT
		|	Subquery.ReferenceOrder AS SalesOrder,
		|	Subquery.Products AS Products,
		|	Subquery.Characteristic AS Characteristic,
		|	Subquery.Warehouse AS Warehouse,
		|	Subquery.Series AS Series,
		|	SUM(Subquery.QuantityToBeShippedTurnover - Subquery.ShippedQuantityTurnover) AS ToShipClosingBalance,
		|	SUM(Subquery.QuantityToBeShippedTurnover) AS ToShipReceipt,
		|	SUM(Subquery.ForRegistrationQuantityTurnover - Subquery.IssuedQuantityTurnover) AS ToRegisterClosingBalance,
		|	SUM(Subquery.ForRegistrationQuantityTurnover) AS ToRegisterReceipt,
		|	SUM(CASE
		|			WHEN Subquery.RowCode = 0
		|				THEN CASE
		|					WHEN &TextOfConditionIsSalesDocument
		|						THEN Subquery.QuantityToBeShippedTurnover
		|					ELSE Subquery.ForRegistrationQuantityTurnover
		|				END
		|			ELSE Subquery.OrderedQuantityTurnover
		|		END
		|		- CASE
		|			WHEN &TextOfConditionIsSalesDocument
		|				THEN (Subquery.ShippedQuantityTurnover
		|				- Subquery.DeductedToPPPQuantityTurnover
		|				- Subquery.QuantityAccepted_Turnover)
		|			ELSE Subquery.IssuedQuantityTurnover
		|		END) AS OrderedClosingBalance,
		|	SUM(CASE
		|			WHEN Subquery.RowCode = 0
		|				THEN CASE
		|					WHEN &TextOfConditionIsSalesDocument
		|						THEN Subquery.AmountToBeShippedTurnover
		|					ELSE Subquery.AmountToBeProcessedTurnover
		|				END
		|			ELSE Subquery.Ordered_AmountTurnover
		|		END
		|		- CASE
		|			WHEN &TextOfConditionIsSalesDocument
		|				THEN (Subquery.ShippedAmountTurnover
		|				- Subquery.DebitedToPPPAmountTurnover
		|				- Subquery.AcceptedAmountTurnover)
		|			ELSE Subquery.IssuedAmountTurnover
		|		END) AS SumClosingBalance,
		|	SUM(CASE
		|			WHEN Subquery.RowCode = 0
		|				THEN Subquery.ForRegistrationQuantityTurnover
		|			ELSE Subquery.Ordered_AmountTurnover
		|		END) AS SumReceipt,
		|	SUM(Subquery.IssuedAmountTurnover) AS SumExpense
		|INTO TTBalancesAndRevolutions
		|FROM
		|	(SELECT
		|		BalanceAndTurnovers.ReferenceOrder AS ReferenceOrder,
		|		BalanceAndTurnovers.Products AS Products,
		|		BalanceAndTurnovers.Characteristic AS Characteristic,
		|		BalanceAndTurnovers.RowCode AS RowCode,
		|		CASE
		|			WHEN BalanceAndTurnovers.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|				THEN ISNULL(TableSeriesWarehouses.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
		|			ELSE BalanceAndTurnovers.Warehouse
		|		END AS Warehouse,
		|		CASE
		|			WHEN BalanceAndTurnovers.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|				THEN ISNULL(TableSeriesWarehouses.Series, VALUE(Catalog.ItemsBatches.EmptyRef))
		|			ELSE BalanceAndTurnovers.Series
		|		END AS Series,
		|		BalanceAndTurnovers.OrderedQuantityTurnover,
		|		BalanceAndTurnovers.ForRegistrationQuantityTurnover,
		|		BalanceAndTurnovers.IssuedQuantityTurnover,
		|		BalanceAndTurnovers.QuantityToBeShippedTurnover,
		|		BalanceAndTurnovers.ShippedQuantityTurnover,
		|		BalanceAndTurnovers.DeductedToPPPQuantityTurnover,
		|		BalanceAndTurnovers.QuantityAccepted_Turnover,
		|		BalanceAndTurnovers.AmountToBeShippedTurnover,
		|		BalanceAndTurnovers.ShippedAmountTurnover,
		|		BalanceAndTurnovers.Ordered_AmountTurnover,
		|		BalanceAndTurnovers.AmountToBeProcessedTurnover,
		|		BalanceAndTurnovers.IssuedAmountTurnover,
		|		BalanceAndTurnovers.DebitedToPPPAmountTurnover,
		|		BalanceAndTurnovers.AcceptedAmountTurnover
		|	FROM
		|		#ShipmentOrdersTurnoverExpanded AS BalanceAndTurnovers
		|			LEFT JOIN TableSeriesWarehouses AS TableSeriesWarehouses
		|			ON BalanceAndTurnovers.ReferenceOrder = TableSeriesWarehouses.ReferenceOrder
		|			AND BalanceAndTurnovers.RowCode = TableSeriesWarehouses.RowCode
		|			AND BalanceAndTurnovers.Warehouse = VALUE(Catalog.Warehouses.EmptyRef)) AS Subquery
		|GROUP BY
		|	Subquery.ReferenceOrder,
		|	Subquery.Products,
		|	Subquery.Characteristic,
		|	Subquery.Warehouse,
		|	Subquery.Series
		|HAVING
		|	SUM(Subquery.QuantityToBeShippedTurnover - Subquery.ShippedQuantityTurnover) <> 0
		|	OR SUM(Subquery.QuantityToBeShippedTurnover) <> 0
		|	OR SUM(Subquery.ForRegistrationQuantityTurnover - Subquery.IssuedQuantityTurnover) <> 0
		|	OR SUM(Subquery.ForRegistrationQuantityTurnover) <> 0
		|	OR SUM(Subquery.OrderedQuantityTurnover - Subquery.ShippedQuantityTurnover) <> 0
		|	OR SUM(Subquery.Ordered_AmountTurnover - Subquery.ShippedAmountTurnover) <> 0
		|	OR SUM(Subquery.Ordered_AmountTurnover) <> 0
		|	OR SUM(Subquery.IssuedAmountTurnover) <> 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrdersBalance.SalesOrder AS SalesOrder,
		|	SUM(OrdersBalance.ToRegisterClosingBalance) AS ToRegisterClosingBalance,
		|	SUM(OrdersBalance.ToShipClosingBalance) AS ToShipClosingBalance,
		|	SUM(OrdersBalance.OrderedClosingBalance) AS OrderedClosingBalance,
		|	SUM(OrdersBalance.SumClosingBalance) AS SumClosingBalance,
		|	SUM(OrdersBalance.AmountOfExpenditureIncludingMeasuredGoods) AS AmountOfExpenditureIncludingMeasuredGoods,
		|	SUM(OrdersBalance.SumExpense) AS SumExpense
		|INTO TTCustomerOrdersBalance
		|FROM
		|	(SELECT
		|		SalesOrdersBalance.SalesOrder AS SalesOrder,
		|		SalesOrdersBalance.Products AS Products,
		|		SalesOrdersBalance.Characteristic AS Characteristic,
		|		SalesOrdersBalance.Warehouse AS Warehouse,
		|		SalesOrdersBalance.Series AS Series,
		|		CASE
		|			WHEN SalesOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|					WHEN SalesOrdersBalance.ToRegisterClosingBalance <= SalesOrdersBalance.ToRegisterReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|					AND SalesOrdersBalance.ToRegisterClosingBalance >= -(SalesOrdersBalance.ToRegisterReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|						THEN 0
		|					ELSE ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0)
		|				END
		|			ELSE ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0)
		|		END AS ToRegisterClosingBalance,
		|		CASE
		|			WHEN SalesOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|					WHEN SalesOrdersBalance.ToShipClosingBalance <= SalesOrdersBalance.ToShipReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|					AND SalesOrdersBalance.ToShipClosingBalance >= -(SalesOrdersBalance.ToShipReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|						THEN 0
		|					ELSE ISNULL(SalesOrdersBalance.ToShipClosingBalance, 0)
		|				END
		|			ELSE ISNULL(SalesOrdersBalance.ToShipClosingBalance, 0)
		|		END AS ToShipClosingBalance,
		|		CASE
		|			WHEN SalesOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|					WHEN SalesOrdersBalance.OrderedClosingBalance <= SalesOrdersBalance.ToRegisterReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|					AND SalesOrdersBalance.OrderedClosingBalance >= -(SalesOrdersBalance.ToRegisterReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|						THEN 0
		|					ELSE ISNULL(SalesOrdersBalance.OrderedClosingBalance, 0)
		|				END
		|			ELSE ISNULL(SalesOrdersBalance.OrderedClosingBalance, 0)
		|		END AS OrderedClosingBalance,
		|		ISNULL(SalesOrdersBalance.SumClosingBalance, 0) AS SumClosingBalance,
		|		CASE
		|			WHEN SalesOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|					WHEN SalesOrdersBalance.SumClosingBalance <= SalesOrdersBalance.SumReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|					AND SalesOrdersBalance.SumClosingBalance >= -SalesOrdersBalance.SumReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|						THEN SalesOrdersBalance.SumReceipt
		|					ELSE SalesOrdersBalance.SumExpense
		|				END
		|			ELSE SalesOrdersBalance.SumExpense
		|		END AS AmountOfExpenditureIncludingMeasuredGoods,
		|		ISNULL(SalesOrdersBalance.SumExpense, 0) AS SumExpense
		|	FROM
		|		TTBalancesAndRevolutions AS SalesOrdersBalance) AS OrdersBalance
		|GROUP BY
		|	OrdersBalance.SalesOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsBalance.SalesOrder AS SalesOrder,
		|	SUM(GoodsBalance.ToShipBalance) AS ToShipBalance
		|INTO TTGoodsForShipmentBalance
		|FROM
		|	(SELECT
		|		GoodsForIssueBalance.DocumentShipments AS SalesOrder,
		|		GoodsForIssueBalance.Products AS Products,
		|		GoodsForIssueBalance.Characteristic AS Characteristic,
		|		GoodsForIssueBalance.Warehouse AS Warehouse,
		|		GoodsForIssueBalance.Series AS Series,
		|		CASE
		|			WHEN GoodsForIssueBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|					WHEN GoodsForIssueBalance.ToShipClosingBalance <= GoodsForIssueBalance.ToShipReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|					AND GoodsForIssueBalance.ToShipClosingBalance >= -(GoodsForIssueBalance.ToShipReceipt *
		|						(&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|						THEN 0
		|					ELSE ISNULL(GoodsForIssueBalance.ToShipClosingBalance, 0)
		|				END
		|			ELSE ISNULL(GoodsForIssueBalance.ToShipClosingBalance, 0)
		|		END AS ToShipBalance
		|	FROM
		|		AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(&InitialGoodsForShipment, &ConPeriodGoodsReadyForShipment,,,
		|			DocumentShipments IN (&AnArrayOfOrders)) AS GoodsForIssueBalance) AS GoodsBalance
		|GROUP BY
		|	GoodsBalance.SalesOrder";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.BeginOfPeriod = "&InitialCustomerOrders";
		TableFormationParameters.EndOfPeriod = "&ConPeriodCustomerOrders";
		TableFormationParameters.ConditionText =
			"ReferenceOrder IN (&AnArrayOfOrders)
			|	AND CASE
			|		WHEN Factor IN
			|		(VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
			|		VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted))
			|			THEN Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
			|		ELSE TRUE
			|	END";
		TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse, Series";
		TableFormationParameters.Indicators = "Ordered, ToRegister, ToShip, Issued_1, Shipped, WrittenOffBeforeTransferOfTitleToGoods, Accepted";
		TableFormationParameters.Resources = "Count, Sum";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"&TextOfConditionIsSalesDocument",
			SalesServer.TextOfConditionIsSalesDocument("Subquery.ReferenceOrder"));
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Return QueryText;
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

Function PaymentRequestText()
	
	Texts = New Array();
	
	QueryText = "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject,
		|	ARAPObjects.Object AS SalesOrder
		|INTO TTCalculationObjects_
		|FROM
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object IN (&AnArrayOfOrders)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BEGINOFPERIOD(CustomersARAPAccounting.Period, DAY) AS Period,
		|	SUM(CustomersARAPAccounting.AmountDue) AS AmountDueReceipt,
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject
		|INTO CalculationSteps
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.ARAPObject IN (
		|		SELECT ARAPObject FROM TTCalculationObjects_)
		|	AND CustomersARAPAccounting.Active
		|	AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|	AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = ARAPObject.Organization
		|	AND CustomersARAPAccounting.AmountDue <> 0
		|GROUP BY
		|	CustomersARAPAccounting.ARAPObject,
		|	BEGINOFPERIOD(CustomersARAPAccounting.Period, DAY)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
		|	SUM(CustomersARAPAccounting.AmountDue) AS AmountDueExpense
		|INTO PaidForOrders
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
		|WHERE
		|	CustomersARAPAccounting.ARAPObject IN (
		|		SELECT ARAPObject FROM TTCalculationObjects_)
		|	AND CustomersARAPAccounting.Active
		|	AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
		|	AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = ARAPObject.Organization
		|GROUP BY
		|	CustomersARAPAccounting.ARAPObject
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CalculationSteps.Period AS Period,
		|	CalculationSteps.ARAPObject AS ARAPObject
		|INTO CalculationResult_1
		|FROM
		|	CalculationSteps AS CalculationSteps
		|		INNER JOIN CalculationSteps AS CustomersARAPAccounting
		|		ON (CustomersARAPAccounting.Period <= CalculationSteps.Period)
		|			AND (CustomersARAPAccounting.ARAPObject = CalculationSteps.ARAPObject)
		|		LEFT JOIN PaidForOrders AS Paid
		|		ON CalculationSteps.ARAPObject = Paid.ARAPObject
		|
		|GROUP BY
		|	CalculationSteps.Period,
		|	CalculationSteps.ARAPObject,
		|	Paid.AmountDueExpense
		|
		|HAVING
		|	SUM(CustomersARAPAccounting.AmountDueReceipt) - ISNULL(Paid.AmountDueExpense, 0) > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MIN(CalculationResult_1.Period) AS UpdateDate,
		|	CalculationResult_1.ARAPObject AS ARAPObject
		|INTO CustomerOrderValidityDates
		|FROM
		|	CalculationResult_1 AS CalculationResult_1
		|
		|GROUP BY
		|	CalculationResult_1.ARAPObject";
		
	Texts.Add(QueryText);
	
	Texts.Add(
		"DROP CalculationSteps;
		|DROP CalculationResult_1
		|");
	
	QueryText = "
	|SELECT ALLOWED
	|	ARAPObjects.Ref AS ARAPObjectInvoice,
	|	TTCalculationObjects_.ARAPObject AS ARAPObjectOrder,
	|	TTCalculationObjects_.SalesOrder AS SalesOrder,
	|	SUM(CASE
	|			WHEN ARAPObjects.Sum = 0
	|				THEN 0
	|			ELSE SettlementsWithCustomersTurnover.ToShipReceipt / ARAPObjects.Sum
	|		END) AS OrderShare
	|INTO TTCommunicationOrdersINVOICES
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Turnovers(, , Recorder, ARAPObject IN (SELECT T.ARAPObject FROM TTCalculationObjects_ AS T)) AS SettlementsWithCustomersTurnover
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON SettlementsWithCustomersTurnover.Recorder = ARAPObjects.Object
	|			AND NOT ARAPObjects.DeletionMark
	|		INNER JOIN TTCalculationObjects_ AS TTCalculationObjects_
	|		ON SettlementsWithCustomersTurnover.ARAPObject = TTCalculationObjects_.ARAPObject
	|
	|GROUP BY
	|	ARAPObjects.Ref,
	|	TTCalculationObjects_.ARAPObject,
	|	TTCalculationObjects_.SalesOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	SettlementsData.ARAPObject AS ARAPObject,
	|	ISNULL(SUM(SettlementsData.PaymentFact), 0) AS PaymentFact,
	|	ISNULL(SUM(SettlementsData.AmountDue), 0) AS AmountDueClosingBalance
	|INTO TTDataOnSettlementsWithCustomers
	|FROM
	|	(SELECT
	|		CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|		CASE
	|			WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)
	|				OR CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.ReserveCustomerPrepayment) 
	|				THEN CASE
	|					WHEN CustomersARAPAccounting.CorARAPObject = VALUE(Catalog.ARAPObjects.EmptyRef)
	|						THEN CASE 
	|								WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|									THEN -CustomersARAPAccounting.Sum
	|								ELSE CustomersARAPAccounting.Sum
	|							END
	|					ELSE CustomersARAPAccounting.Sum
	|				END
	|			WHEN CustomersARAPAccounting.BusinessOperation = VALUE(Enum.BusinessTransactions.PaymentTransferBetweenBranchOffices)
	|				AND CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN 0
	|			ELSE CASE
	|					WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|						OR CustomersARAPAccounting.Recorder REFS Document.SaleAdjustment
	|					THEN 0
	|					ELSE CustomersARAPAccounting.Sum
	|				END
	|		END AS PaymentFact,
	|		CASE
	|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CustomersARAPAccounting.AmountDue
	|			ELSE -CustomersARAPAccounting.AmountDue
	|		END AS AmountDue
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|	WHERE
	|		CustomersARAPAccounting.ARAPObject.Object IN (&AnArrayOfOrders)
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TTCommunicationOrdersINVOICES.ARAPObjectOrder AS ARAPObject,
	|		0 AS PaymentFact,
	|		CASE
	|			WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN CustomersARAPAccounting.AmountDue
	|			ELSE -CustomersARAPAccounting.AmountDue
	|		END AS AmountDue
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
	|			ON CustomersARAPAccounting.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice
	|	WHERE
	|		CustomersARAPAccounting.ARAPObject IN
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
	
	Return "
	|SELECT
	|		CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|		ISNULL(SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|				AND CustomersARAPAccounting.BusinessOperation <> VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle)
	|			THEN CustomersARAPAccounting.AmountDue
	|			ELSE 0
	|		END), 0) AS AmountDueExpense,
	|		ISNULL(SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN - CustomersARAPAccounting.AmountDue
	|			ELSE CustomersARAPAccounting.AmountDue
	|		END), 0) AS AmountDueClosingBalance,
	|		ISNULL(SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN CustomersARAPAccounting.ToShip
	|			ELSE 0
	|		END), 0) AS ToShipReceipt,
	|		ISNULL(SUM(CASE WHEN CustomersARAPAccounting.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN - CustomersARAPAccounting.Sum
	|			ELSE CustomersARAPAccounting.Sum
	|		END), 0) AS SumClosingBalance
	|INTO TTSettlementsWithCustomersBalance
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|	WHERE
	|		CustomersARAPAccounting.ARAPObject IN (SELECT T.ARAPObject FROM TTCalculationObjects_ AS T)
	|		AND CustomersARAPAccounting.AccountingDimensionByPartners.Organization = ARAPObject.Organization
	|		AND CustomersARAPAccounting.Active
	|GROUP BY
	|	CustomersARAPAccounting.ARAPObject
	|";
	
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
		|SELECT ALLOWED
		|	SettlementsWithCustomersTurnover.Recorder AS Recorder,
		|	SettlementsWithCustomersTurnover.ARAPObject AS ARAPObject,
		|	SettlementsWithCustomersTurnover.ToShipReceipt AS ToShipReceipt
		|INTO TTSettlementsWithCustomers
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Turnovers(
		|			,
		|			,
		|			Recorder,
		|			ARAPObject IN
		|				(SELECT
		|					TTOrders.Ref
		|				FROM
		|					TTOrders)) AS SettlementsWithCustomersTurnover
		|
		|INDEX BY
		|	Recorder,
		|	ARAPObject
		|;
		|
		|SELECT ALLOWED
		|	ARAPObjects.Ref                AS ARAPObjectInvoice,
		|	ARAPObjectsOrder.Ref           AS ARAPObjectOrder,
		|	ARAPObjectsOrder.Object           AS OrderDocument,
		|	SUM(CAST(CASE
		|			WHEN ARAPObjects.AmountARAP = 0
		|				THEN CASE
		|						WHEN ARAPObjects.Sum = 0
		|							THEN 0
		|						ELSE SettlementsWithCustomersTurnover.ToShipReceipt / ARAPObjects.Sum
		|					END
		|			ELSE SettlementsWithCustomersTurnover.ToShipReceipt / ARAPObjects.AmountARAP
		|		END AS NUMBER(20,10))) AS OrderShare,
		|	MAX(CASE
		|			WHEN ARAPObjectsOrder.AmountARAP = 0
		|				THEN ARAPObjectsOrder.Sum
		|			ELSE ARAPObjectsOrder.AmountARAP
		|		END) AS OrderAmount
		|INTO TTCommunicationOrdersINVOICES
		|FROM
		|	TTSettlementsWithCustomers AS SettlementsWithCustomersTurnover
		|		INNER JOIN TTOrders AS ARAPObjectsOrder
		|		ON SettlementsWithCustomersTurnover.ARAPObject = ARAPObjectsOrder.Ref
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON SettlementsWithCustomersTurnover.Recorder = ARAPObjects.Object
		|		AND NOT ARAPObjects.DeletionMark
		|WHERE
		|	ARAPObjectsOrder.Object IN (&AnArrayOfOrders)
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
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(
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
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
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
		|	AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
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
		|INTO CustomerOrderValidityDates
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
		|	CAST(ISNULL(SUM(Calculations.RemainsToPay), 0) AS NUMBER(31,2)) AS RemainsToPay,
		|	
		|	CAST(ISNULL(SUM(Calculations.AmountByShipments), 0) AS NUMBER(31,2)) AS AmountByShipment,
		|	CAST(ISNULL(SUM(Calculations.DebtAmount), 0) AS NUMBER(31,2)) AS AmountOfDebt,
		|	
		|	CASE WHEN CAST(ISNULL(SUM(Calculations.AmountOfPayments), 0) AS NUMBER(31,2)) = 0
		|		OR ISNULL(MAX(Calculations.AmountOfInitialSettlements), 0) = 0
		|			THEN 0
		|		ELSE CAST(CAST(SUM(Calculations.AmountOfPayments) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|	END AS PayPercentage,
		|	
		|	CASE WHEN CAST(ISNULL(SUM(Calculations.AmountByShipments), 0) AS NUMBER(31,2)) = 0
		|		OR ISNULL(MAX(Calculations.AmountOfInitialSettlements), 0) = 0
		|			THEN 0
		|		ELSE CAST(CAST(SUM(Calculations.AmountByShipments) AS NUMBER(31,2)) * 100 / MAX(Calculations.AmountOfInitialSettlements) AS NUMBER(20, 10))
		|	END AS OrderShipmentPercentage,
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
		|		&TemplateOfShippedField   AS AmountByShipments,
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
		|			AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
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
		|		TTCommunicationOrdersINVOICES.OrderDocument                                                           AS OrderDocument,
		|		CAST((&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))  AS AmountOfPayments,
		|		CAST((&TemplateForPaidField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))  AS AmountOfPaymentsForOrder,
		|		CAST((&TemplateForWriteOffField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))  AS AmountOfWriteOff,
		|		CAST((&TemplateOfShippedField) * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10)) AS AmountByShipments,
		|		
		|		CAST(CASE WHEN CalculationsByTerms.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN CalculationsByTerms.Debt - CalculationsByTerms.Prepayment
		|			ELSE CalculationsByTerms.Prepayment - CalculationsByTerms.Debt
		|		END * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10))                           AS DebtAmount,
		|		
		|		0                                                                                       AS RemainsToPay,
		|		TTCommunicationOrdersINVOICES.OrderAmount                                                     AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
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
		|		TTCommunicationOrdersINVOICES.OrderDocument AS OrderDocument,
		|		0 AS AmountOfPayments,
		|		0 AS AmountOfPaymentsForOrder,
		|		0 AS AmountOfWriteOff,
		|		0 AS AmountByShipments,
		|		0 AS DebtAmount,
		|		
		|		CAST(CalculationsByTerms.DebtBalance * TTCommunicationOrdersINVOICES.OrderShare AS NUMBER(20, 10)) AS RemainsToPay,
		|		TTCommunicationOrdersINVOICES.OrderAmount AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
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
		|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(
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
		|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(
		|				,
		|				ARAPObject.Object IN (&AnArrayOfOrders)
		|					AND AccountingDimensionByPartners.Organization = ARAPObject.Organization) AS ScheduledPayments_
		|			INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ScheduledPayments_.ARAPObject = ARAPObjects.Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		ARAPObjects.Object AS OrderDocument,
		|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Calculations.BeingPaid
		|			ELSE -Calculations.BeingPaid
		|		END                  AS AmountOfPayments,
		|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Calculations.BeingPaid
		|			ELSE -Calculations.BeingPaid
		|		END                  AS AmountOfPaymentsForOrder,
		|		0                      AS AmountOfWriteOff,
		|		0                      AS AmountByShipments,
		|		0                      AS DebtAmount,
		|		0                      AS RemainsToPay,
		|		CASE WHEN ARAPObjects.AmountARAP = 0
		|			THEN ARAPObjects.Sum
		|			ELSE ARAPObjects.AmountARAP
		|		END                  AS AmountOfInitialSettlements
		|		
		|	FROM
		|			AccumulationRegister.CustomersARAPAccounting AS Calculations
		|				INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|				ON Calculations.ARAPObject = ARAPObjects.Ref
		|		WHERE
		|			ARAPObjects.Object IN (&AnArrayOfOrders)
		|			AND Calculations.AccountingDimensionByPartners.Organization = ARAPObjects.Organization
		|			AND Calculations.Active
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTCommunicationOrdersINVOICES.OrderDocument       AS OrderDocument,
		|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Calculations.BeingPaid
		|			ELSE -Calculations.BeingPaid
		|		END                               AS AmountOfPayments,
		|		CASE WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
		|			THEN Calculations.BeingPaid
		|			ELSE -Calculations.BeingPaid
		|		END                               AS AmountOfPaymentsForOrder,
		|		0                                   AS AmountOfWriteOff,
		|		0                                   AS AmountByShipments,
		|		0                                   AS DebtAmount,
		|		0                                   AS RemainsToPay,
		|		TTCommunicationOrdersINVOICES.OrderAmount AS AmountOfInitialSettlements
		|	FROM
		|		AccumulationRegister.CustomersARAPAccounting AS Calculations
		|			INNER JOIN TTCommunicationOrdersINVOICES AS TTCommunicationOrdersINVOICES
		|			ON Calculations.ARAPObject = TTCommunicationOrdersINVOICES.ARAPObjectInvoice 
		|	WHERE
		|		Calculations.ARAPObject IN (SELECT
		|							T.ARAPObjectInvoice
		|						FROM
		|							TTCommunicationOrdersINVOICES AS T)
		|		AND Calculations.AccountingDimensionByPartners.Organization = Calculations.ARAPObject.Organization
		|		AND Calculations.Active
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
		|	WHEN VALUETYPE(CalculationsByTerms.DocumentRecorder) = TYPE(Document.SaleAdjustment)
		|		AND CalculationsByTerms.SettlementRecordType = VALUE(Enum.TypesOfSettlementRecords.ShipmentDebtIncrease)
		|		THEN -Debt
		|	ELSE 0
		|END";
	QueryText = StrReplace(
		QueryText,
		"&TemplateOfShippedField",
		StrTemplate(
			"%1 + %2",
			ARAPAccountingReports.TemplateOfShippedField(),
			TemplateForAmountOfAdjustmentsField));
	QueryText = StrReplace(QueryText, "&TemplateForWriteOffField", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	Return QueryText;
	
EndFunction

Function RequestTextStateOfOfflineSettlements(DocumentTypeByString)
	
	QueryText = "
		|SELECT 
		|	DocumentOrderDocument.Ref                            AS OrderDocument,
		|	DocumentOrderDocument.DocumentAmount                    AS OrderAmount,
		|	CustomersARAPAccountingBalance.AmountDueExpense          AS PaidByOrder,
		|	TTDataOnSettlementsWithCustomers.AmountDueClosingBalance AS RemainsToPay,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|			THEN CASE
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					THEN CAST (ISNULL(PaidForOrders.AmountDueExpense, 0) AS NUMBER(31,2))
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|					THEN CAST (ISNULL(TTDataOnSettlementsWithCustomers.PaymentFact, 0) AS NUMBER(31,2))
		|				ELSE 0
		|			END
		|		ELSE 0
		|	END                                           AS PayAmount,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|			THEN CASE
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					THEN CAST ((ISNULL(PaidForOrders.AmountDueExpense, 0)) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|				WHEN DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		|					THEN CAST ((ISNULL(TTDataOnSettlementsWithCustomers.PaymentFact, 0)) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|				ELSE 0
		|			END
		|		ELSE 0
		|	END                                           AS PayPercentage,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN ISNULL(CustomersARAPAccountingBalance.ToShipReceipt, 0)
		|		ELSE 0
		|	END                                           AS AmountByShipment,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.ToShipReceipt, 0) * 100 / DocumentOrderDocument.DocumentAmount AS NUMBER(20, 10))
		|		ELSE 0
		|	END                                           AS OrderShipmentPercentage,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		|		ELSE 0
		|	END                                           AS AmountOfDebt,
		|	CASE
		|		WHEN DocumentOrderDocument.Posted
		|				AND DocumentOrderDocument.DocumentAmount > 0
		|				AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|			THEN CAST((CASE 
		|				WHEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) > 0 
		|					THEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0)
		|				ELSE ISNULL(-CustomersARAPAccountingBalance.SumClosingBalance, 0)
		|			END * 100 / DocumentOrderDocument.DocumentAmount) AS NUMBER(20, 10))
		|		ELSE 0
		|	END                                           AS DebtPercentage
		|
		|INTO TTStateOfSETTLEMENTS
		|FROM
		|	#DocumentName AS DocumentOrderDocument
		|	LEFT JOIN TTSettlementsWithCustomersBalance AS CustomersARAPAccountingBalance
		|		ON DocumentOrderDocument.ARAPObject = CustomersARAPAccountingBalance.ARAPObject 
		|	LEFT JOIN PaidForOrders AS PaidForOrders
		|		ON DocumentOrderDocument.ARAPObject = PaidForOrders.ARAPObject
		|	LEFT JOIN TTDataOnSettlementsWithCustomers AS TTDataOnSettlementsWithCustomers
		|		ON DocumentOrderDocument.ARAPObject = TTDataOnSettlementsWithCustomers.ARAPObject
		|WHERE
		|	DocumentOrderDocument.Ref IN (&AnArrayOfOrders)
		|";
	
	QueryText = StrReplace(QueryText, "#DocumentName", DocumentTypeByString);
	
	Return QueryText;
	
EndFunction

#Region ServiceMethodsForGeneratingStates

#Region RequestTextsByControlRegisters

Function QueryTextShipmentReferences(Query)
	
	QueryText =
	"SELECT
	|	Table.ReferenceOrder AS ReflectedDocument
	|FROM
	|	RegisteredRecordsOfShipmentOrderUpdate AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextCustomersARAPAccounting(Query)
	
	QueryText =
	"SELECT
	|	ARAPObjects.Object AS ReflectedDocument
	|FROM
	|	SettlementsWithCustomersChanges AS Table
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Ref = Table.ARAPObject
	|WHERE
	|	ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|
	|UNION ALL
	|
	|SELECT 
	|	CustomersARAPAccounting.SaleByOrder AS ReflectedDocument
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting AS CustomersARAPAccounting
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON ARAPObjects.Object = CustomersARAPAccounting.SaleByOrder
	|		AND NOT ARAPObjects.DeletionMark
	|		INNER JOIN SettlementsWithCustomersChanges AS SettlementsWithCustomersChanges
	|		ON CustomersARAPAccounting.AccountingDimensionByPartners = SettlementsWithCustomersChanges.AccountingDimensionByPartners
	|		AND CustomersARAPAccounting.ARAPObject = SettlementsWithCustomersChanges.ARAPObject
	|WHERE
	|	CustomersARAPAccounting.SaleByOrder <> UNDEFINED 
	|	AND ARAPObjects.ARAPObjectType = VALUE(Enum.ARAPObjectTypes.OrderDocument)
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextGoodsForIssue(Query)
	
	QueryText =
	"SELECT
	|	Table.DocumentShipments AS ReflectedDocument
	|FROM
	|	RegisteredRecordsOfGoodsToShipAreReReflected AS Table
	|WHERE
	|	(Table.ToRegisterUpdate <> 0
	|	OR Table.ToShipUpdate <> 0
	|	OR Table.AssemblyInProgressUpdate <> 0
	|	OR Table.AssembledUpdate <> 0)
	|	AND VALUETYPE(Table.DocumentShipments) IN (TYPE(Document.SalesOrder),
	|	TYPE(Document.MaterialProviderOrder2_5),
	|	TYPE(Document.RequestForReturnOfGoodsFromCustomer))
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
	|	VALUETYPE(Table.DocumentInflow) IN (TYPE(Document.RequestForReturnOfGoodsFromCustomer))
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function QueryTextSalesOrderStatesUpdate(Query)
	
	QueryText =
	"SELECT
	|	Table.OrderDocument AS ReflectedDocument
	|FROM
	|	SalesOrderStatesUpdate AS Table
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
	|	Table.Status IN (
	|		VALUE(Enum.SalesOrderStatuses.NotApproved),
	|		VALUE(Enum.StatusesOfMaterialProviderOrders.NotApproved),
	|		VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon))
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndIf
