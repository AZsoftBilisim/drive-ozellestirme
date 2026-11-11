#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Reflects changes in order States in the register.
//
// Parameters:
//  Orders - Array of DocumentRef.ProductionOrder2_2 - array of reflected orders.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectOrderStates(Orders, Errors = Undefined) Export
	
	OrdersByType = TMCommonUse.MatchingArraysByObjectType(Orders);
	
	For Each OrdersByType_ In OrdersByType Do
		
		If OrdersByType_.Key = "Document.ProductionOrder2_2" Then
			
			Selection = ChangesSelection(OrdersByType_.Value);
			RecordStates(Selection, Errors);
			
			Break;
			
		EndIf;
		
	EndDo;
	
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

	MatchingQueryTexts = New Map;
	
	MatchingQueryTexts.Insert(
		"RegisteredRecordsProductionOrdersChanges",
		QueryTextProductionOrders(Query));
	
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
	
	OrderTypes = TypesOfOrdersToReflectStates();
	
	If TypeOf(Orders) = Type("Array") Then
		
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
		
	ElsIf OrderTypes.Find(TypeOf(Orders)) <> Undefined Then
		
		InformationRegisters.JobsToReflectOrderState.AddTasks(Orders, Action, TaskTable);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Returns the types of orders for which States should be reflected.
//
// Returns:
//  Array of Type - Types of State reflection orders
//
Function TypesOfOrdersToReflectStates() Export
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.ProductionOrder2_2"));
	
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

#Region RequestTextsByControlRegisters

Function QueryTextProductionOrders(Query)
	
	QueryText =
	"SELECT
	|	Table.ProductionOrder AS ReflectedDocument
	|FROM
	|	RegisteredRecordsProductionOrdersChanges AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

#EndRegion

#Region Other

Function ChangesSelection(ReferencesArrray)

	Query = New Query();
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	Query.Text = 
		"SELECT
		|	MAX(Table.DynamicStructure) AS ThereAreOrdersDynamicStructure,
		|	MAX(NOT Table.DynamicStructure) AS ThereAreOrdersStaticStructure
		|FROM
		|	Document.ProductionOrder2_2 AS Table
		|WHERE
		|	Table.Ref IN(&ReferencesArrray)";
	
	SelectionOrderTypes = Query.Execute().Select();
	SelectionOrderTypes.Next();

	Query.Text = Documents.ProductionOrder2_2.RequestTextForCalculatingOrderStates(SelectionOrderTypes);
		
	Query.SetParameter("StatusWorkingSchedule", InformationRegisters.ScheduleOfProductionStages2_2.StatusWorkingSchedule());
	Query.SetParameter("TheProductionScheduleIsUsed", ProductionManagementCached.TheProductionScheduleIsUsed());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving", Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());

	Return Query.Execute().Select();
	
EndFunction

Function RecordStates(Selection, Errors = Undefined)
	
	SetPrivilegedMode(True);
	
	While Selection.Next() Do
		
		Set = InformationRegisters.StatesOfProductionOrders.CreateRecordSet();
		Set.Filter.OrderDocument.Set(Selection.OrderDocument);
		
		If Selection.ActiveStatus Then 
			FillPropertyValues(Set.Add(), Selection);
		EndIf;
		
		Try
			Set.Write(True);
		Except
			MessageText = NStr("vi = 'Không thể phản ánh trạng thái đơn hàng vì lý do: %Cause%';
								|ru = 'Не удалось отразить состояние заказа по причине: %Cause%';
								|en = 'Cannot record state of order. Reason: %Cause%'; fa = 'Cannot record state of order. Reason: %Cause%';
								|it = 'Не удалось отразить состояние заказа по причине: %Cause%';
								|pl = 'Cannot record state of order. Reason: %Cause%';
								|tr = 'Sipariş durumu şu nedenden dolayı yansıtılamadı: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(EventLogEvent(), EventLogLevel.Warning,
				Selection.OrderDocument.Metadata(), Selection.OrderDocument, MessageText);
			
			If Errors <> Undefined Then
				Errors.Insert(Selection.OrderDocument, MessageText);
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndFunction

Function EventLogEvent()
	
	Return NStr("vi = 'Quản lý liên xưởng';
				|ru = 'Межцеховое управление';
				|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
				|it = 'Gestione interna dei reparti';
				|pl = 'Zarządzanie międzyresortowe';
				|tr = 'Üretim planlama ve kontrolü'", CommonClientServer.DefaultLanguageCode()) + "."
			+ NStr("vi = 'Lỗi phản ánh trạng thái đơn hàng theo trình tự';
					|ru = 'Ошибка отражения состояния заказов в очереди';
					|en = 'Error recording order states in the queue'; fa = 'Error recording order states in the queue';
					|it = 'Errore di registrazione dello stato degli ordini in coda';
					|pl = 'Błąd odzwierciedlenie statusu zamówień w kolejce';
					|tr = 'Kuyruktaki siparişlerin durumlarının yansıtılma hatası'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

#EndRegion

#EndRegion

#EndIf
