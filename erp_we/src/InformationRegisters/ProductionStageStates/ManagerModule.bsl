#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates and records the States of stages.
//
// Parameters:
//  StepsToUpdate - Array	 - list of steps to update the status
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef.ProductionStage2_2 -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectStateOfStages(StepsToUpdate, Errors = Undefined) Export
	
	ArrayOfLinksToUpdate = ProductionManagementClientServer.ArrayOfValues(StepsToUpdate);
	
	If ArrayOfLinksToUpdate.Count() > 0 Then
		
		CalculationParameters = CalculationParametersConstructor(ArrayOfLinksToUpdate);
		
		ChangesSelection = SamplingStateChanges(CalculationParameters);
		
		If CalculationParameters.WriteSets Then
			RecordStatesByOrders(ChangesSelection, Errors);
		Else
			RecordStatesByStages(ChangesSelection, Errors);
		EndIf;
		
	EndIf;
	
EndProcedure

// Updates the state of security of the stages in the change of a separate provision.
//
// Parameters:
//  Stages - Array - list of steps to update the status.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef.ProductionStage2_2 -
//                          *Value - String - detailed representation of the error.
//
// Returns:
//	Array - the list of stages for which the status update was performed.
//	
Function UpdateSoftwareState(Stages, Errors = Undefined) Export
	
	ReferencesArrray = ProductionManagementClientServer.ArrayOfValues(Stages);
	If ReferencesArrray.Count() = 0 Then
		Return New Array;
	EndIf;
	
	Indicators = New Array;
	Indicators.Add("RequiresSupply");
	Indicators.Add("SupplyState");
	
	CalculationParameters = CalculationParametersConstructor(
		ReferencesArrray,
		,
		Indicators);
	
	ProcessedOrders_ = New Array;
	ProcessedStages = New Array;
	
	Selection = SamplingStateChanges(CalculationParameters);
	RecordStatesByStagesSelectively(Selection, Indicators, ProcessedOrders_, ProcessedStages, Errors);
	
	If ProcessedOrders_.Count() > 0 Then
		InformationRegisters.StatesOfProductionOrders.ReflectOrderStates(ProcessedOrders_, Errors);
	EndIf;
	
	Return ProcessedStages;
	
EndFunction

// Updates the status of operations.
//
// Parameters:
//  Stages - Array - list of steps to update the status.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef.ProductionStage2_2 -
//                          *Value - String - detailed representation of the error.
//
Procedure UpdateStateOfOperations(Stages, Errors = Undefined) Export
	
	ReferencesArrray = ProductionManagementClientServer.ArrayOfValues(Stages);
	If ReferencesArrray.Count() = 0 Then
		Return;
	EndIf;
	
	Indicators = New Array;
	Indicators.Add("OperationStatus");
	
	CalculationParameters = CalculationParametersConstructor(
		ReferencesArrray,
		,
		Indicators);
	
	Selection = SamplingStateChanges(CalculationParameters);
	RecordStatesByStagesSelectively(Selection, Indicators,,, Errors);
	
EndProcedure

// Updates the design States of the stage development when the development parameters change.
//
// Parameters:
//  Stages	 - Array	 - list of steps to update the status.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef.ProductionStage2_2 -
//                          *Value - String - detailed representation of the error.
//
Procedure UpdateDesignState(Stages, Errors = Undefined) Export
	
	ReferencesArrray = ProductionManagementClientServer.ArrayOfValues(Stages);
	If ReferencesArrray.Count() = 0 Then
		Return;
	EndIf;
	
	Indicators = New Array;
	Indicators.Add("RequiresOutputRegistration");
	
	CalculationParameters = CalculationParametersConstructor(
		ReferencesArrray,
		,
		Indicators);
	
	Selection = SamplingStateChanges(CalculationParameters);
	RecordStatesByStagesSelectively(Selection, Indicators,,, Errors);
	
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

	MatchingTasks = New Map();
	If Not InventoryAllocation.CountRegisterWithRoutineTask() Then
		MatchingTasks.Insert("ProductionStageStatesUpdate",
			QueryTextProductionStageStatesUpdate(Query));
	EndIf;
	Return MatchingTasks;
	
EndFunction

// Reflects changes in order States in the register.
//
// Parameters:
//  Orders - Array of DocumentRef.ProductionStage2_2 - array of reflected orders.
//  Errors - Undefined, Map of KeyAndValue - with structure:
//                          *Key     - DocumentRef -
//                          *Value - String - detailed representation of the error.
//
Procedure ReflectOrderStates(Orders, Errors = Undefined) Export
	
	ProductionSupply.WhenSoftwareChanges(Orders, Errors);
	
EndProcedure

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

Function ParametersForUpdatingOrderStates() Export
	
	// Changes are monitored to solve two tasks:
	//	Recalculation of the State of stage support - See UpdateSoftwareState
	//	Control of compliance with the terms of provision and start dates of stages according to the production schedule
	//		- See ProductionManagement.CheckTimingOfProvisionOfStages
	
	Result = New Structure("RecordSelectionRule,RecordComparisonFunction,FunctionForComparingRecordsInTemporaryTable");
	
	Result.RecordSelectionRule =
		"SELECT DISTINCT
		|	InventoryAllocation.InventoryState      AS InventoryState,
		|	InventoryAllocation.ShipmentOrder      AS ShipmentOrder,
		|	InventoryAllocation.ReceiptOrder   AS ReceiptOrder,
		|	InventoryAllocation.RequestShipmentOn AS RequestShipmentOn,
		|	InventoryAllocation.AvailabilityDate      AS AvailabilityDate
		|INTO TableOverridable
		|FROM
		|	InformationRegister.InventoryAllocation AS InventoryAllocation
		|WHERE
		|	InventoryAllocation.InventoryState IN(
		|		VALUE(Enum.InventoryStates.NotProvided),
		|		VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|	AND InventoryAllocation.DemandCharacteristic IN(
		|		VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|		VALUE(Enum.DemandCharacteristics.ToSupply))
		|	AND InventoryAllocation.ShipmentOrder REFS Document.ProductionStage2_2
		|	AND TRUE IN (
		|				SELECT TOP 1
		|					TRUE
		|				FROM
		|					FilterOverridable AS Goods
		|				WHERE
		|					Goods.Products = InventoryAllocation.Products
		|					AND Goods.Characteristic = InventoryAllocation.Characteristic
		|					AND Goods.Warehouse = InventoryAllocation.Warehouse
		|					AND Goods.Purpose = InventoryAllocation.Purpose)
		|INDEX BY
		|	ShipmentOrder, InventoryState, AvailabilityDate, RequestShipmentOn, ReceiptOrder";
	
	Result.FunctionForComparingRecordsInTemporaryTable =
		"// Before recording - Ensure
		|SELECT DISTINCT
		|	BeforeWrite.ShipmentOrder AS OrderDocument
		|INTO UpdateOverridable
		|FROM
		|	BeforeWriteOverridable AS BeforeWrite
		|WHERE
		|	BeforeWrite.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						OnWriteOverridable AS OnWrite
		|					WHERE
		|						OnWrite.ShipmentOrder = BeforeWrite.ShipmentOrder
		|						AND OnWrite.InventoryState = BeforeWrite.InventoryState)
		|
		|UNION
		|
		|// Before recording - provided by the date
		|SELECT DISTINCT
		|	BeforeWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	BeforeWriteOverridable AS BeforeWrite
		|WHERE
		|	BeforeWrite.InventoryState IN(
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						OnWriteOverridable AS OnWrite
		|					WHERE
		|						OnWrite.ShipmentOrder = BeforeWrite.ShipmentOrder
		|						AND OnWrite.InventoryState = BeforeWrite.InventoryState
		|						AND OnWrite.ReceiptOrder = BeforeWrite.ReceiptOrder
		|						AND OnWrite.AvailabilityDate = BeforeWrite.AvailabilityDate
		|						AND OnWrite.RequestShipmentOn = BeforeWrite.RequestShipmentOn)
		|
		|UNION
		|
		|// Before recording - Waiting for a non-confirmed order
		|SELECT DISTINCT
		|	BeforeWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	BeforeWriteOverridable AS BeforeWrite
		|WHERE
		|	BeforeWrite.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						OnWriteOverridable AS OnWrite
		|					WHERE
		|						OnWrite.ShipmentOrder = BeforeWrite.ShipmentOrder
		|						AND OnWrite.InventoryState = BeforeWrite.InventoryState)
		|
		|UNION
		|
		|// When recording - Provide
		|SELECT DISTINCT
		|	OnWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	OnWriteOverridable AS OnWrite
		|WHERE
		|	OnWrite.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						BeforeWriteOverridable AS BeforeWrite
		|					WHERE
		|						BeforeWrite.ShipmentOrder = OnWrite.ShipmentOrder
		|						AND BeforeWrite.InventoryState = OnWrite.InventoryState)
		|
		|UNION
		|
		|// When recording - provided by the date
		|SELECT DISTINCT
		|	OnWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	OnWriteOverridable AS OnWrite
		|WHERE
		|	OnWrite.InventoryState IN(
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|		VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|		VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						BeforeWriteOverridable AS BeforeWrite
		|					WHERE
		|						BeforeWrite.ShipmentOrder = OnWrite.ShipmentOrder
		|						AND BeforeWrite.InventoryState = OnWrite.InventoryState
		|						AND BeforeWrite.ReceiptOrder = OnWrite.ReceiptOrder
		|						AND BeforeWrite.AvailabilityDate = OnWrite.AvailabilityDate
		|						AND BeforeWrite.RequestShipmentOn = OnWrite.RequestShipmentOn)
		|
		|UNION
		|
		|// When recording - Waiting for a non-confirmed order
		|SELECT DISTINCT
		|	OnWrite.ShipmentOrder AS OrderDocument
		|FROM
		|	OnWriteOverridable AS OnWrite
		|WHERE
		|	OnWrite.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|	AND NOT TRUE IN (
		|					SELECT TOP 1
		|						TRUE
		|					FROM
		|						BeforeWriteOverridable AS BeforeWrite
		|					WHERE
		|						BeforeWrite.ShipmentOrder = OnWrite.ShipmentOrder
		|						AND BeforeWrite.InventoryState = OnWrite.InventoryState)";
	
	Result.RecordComparisonFunction = StrReplace(Result.FunctionForComparingRecordsInTemporaryTable,
		"INTO UpdateOverridable", "");
	
	Return Result;
	
EndFunction

// Returns the types of orders for which States should be reflected.
//
// Returns:
//  Array of Type - Types of State reflection orders
//
Function TypesOfOrdersToReflectStates() Export
	
	OrderTypes = New Array;
	OrderTypes.Add(Type("DocumentRef.ProductionStage2_2"));
	
	Return OrderTypes;
	
EndFunction

// Returns an action table to reflect the State of orders.
// Detailed description in the function of document statesadocuments.Initialize the Action table to reflect the status of orders.
// 
// Returns:
//  See DocumentsStates.InitializeActionTableToReflectStateOfOrders
//
Function ActionsToReflectStateOfOrders() Export
	
	ActionsTable = DocumentsStates.InitializeActionTableToReflectStateOfOrders();
	
	TableRow = ActionsTable.Add();
	TableRow.Action  = "ACTION_REFRESH_STATE_WORK_DESIGN";
	TableRow.MethodName = "InformationRegisters.ProductionStageStates.UpdateDesignState";
	
	TableRow = ActionsTable.Add();
	TableRow.Action  = "ACTION_FEFLECT_STAGES_STATE";
	TableRow.MethodName = "InformationRegisters.ProductionStageStates.ReflectStateOfStages";
	
	TableRow = ActionsTable.Add();
	TableRow.Action  = "ACTION_REFRESH_SUPPLY_STATE";
	TableRow.MethodName = "InformationRegisters.ProductionStageStates.UpdateSoftwareState";
	
	TableRow = ActionsTable.Add();
	TableRow.Action  = "Action_Refresh_State_operations";
	TableRow.MethodName = "InformationRegisters.ProductionStageStates.UpdateStateOfOperations";
	
	Return ActionsTable;
	
EndFunction

#EndRegion

#Region Private

#Region UpdatingAllStates

Function SamplingStateChanges(CalculationParameters)
	
	Query = New Query();
	
	Query.SetParameter("ReferencesArrray",         CalculationParameters.ArrayOfLinksToUpdate);
	Query.SetParameter("ArrayOfLinksToCleanUp", CalculationParameters.ArrayOfLinksToCleanUp);
	
	Query.SetParameter("StatusIsGenerated", Enums.StatusesOfProductionStages2_2.BeingGenerated);
	Query.SetParameter("GeneratedStatus", Enums.StatusesOfProductionStages2_2.Generated1);
	Query.SetParameter("StatusPending", Enums.StatusesOfProductionStages2_2.ForCompletion);
	Query.SetParameter("StatusStarted",       Enums.StatusesOfProductionStages2_2.Initiated);
	Query.SetParameter("StatusCompleted_1",    Enums.StatusesOfProductionStages2_2.Completed);
	
	Query.SetParameter("NoPredecessors",      Enums.StatesOfProductionStagePredecessors.NoPredecessors);
	Query.SetParameter("NotPredecessorsAreStarted",  Enums.StatesOfProductionStagePredecessors.NotPredecessorsAreStarted);
	Query.SetParameter("PredecessorsAreStarted",    Enums.StatesOfProductionStagePredecessors.PredecessorsAreStarted);
	Query.SetParameter("PredecessorsAreCompleted", Enums.StatesOfProductionStagePredecessors.PredecessorsAreCompleted);
	
	Query.SetParameter("EmptyStateAtInterShopLevel",    Enums.StateOfProductionStagesAtIntershopLevel.EmptyRef());
	Query.SetParameter("EmptyStateAtIntraShopLevel", Enums.ShopfloorLevelStagesStates.EmptyRef());
	
	Query.SetParameter("StoreOperationsInBillsOfMaterials",
		GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	
	Query.Text = StateCalculationRequestText(CalculationParameters);
	
	SetPrivilegedMode(True);
	
	QueryResult  = Query.ExecuteBatch();
	NumberOfPackages_ = QueryResult.Count();
	
	If CalculationParameters.DefineRecordingMethod Then
		ChangesSelection = QueryResult[NumberOfPackages_-2].Select();
		CalculationParameters.WriteSets = Not QueryResult[NumberOfPackages_-1].IsEmpty();
	Else
		ChangesSelection = QueryResult[NumberOfPackages_-1].Select();
		CalculationParameters.WriteSets = False;
	EndIf;
	
	Return ChangesSelection;

EndFunction

Function StateCalculationRequestText(CalculationParameters)
	
	TemporaryDocumentTables = Documents.ProductionStage2_2.TemporaryTablesForStateCalculation();
	
	QueryTexts = New Array;
	
	QueryTexts.Add(TemporaryDocumentTables.Attributes);
	
	If CalculationParameters.CalculateCollateral Then
		QueryText = QueryTextTTSupply();
		QueryTexts.Add(QueryText);
	EndIf;
	
	If CalculationParameters.CalculateDesignOfOutput Then
		QueryText = QueryTextTTLaborCostsToRegister();
		QueryTexts.Add(QueryText);
	EndIf;
	
	If CalculationParameters.CalculateStateOfStages Then
		QueryTexts.Add(TemporaryDocumentTables.PredecessorStates);
	EndIf;
	
	If CalculationParameters.CalculateStateOfOperations Then
		QueryText = QueryTextTTStatesOfOperations();
		QueryTexts.Add(QueryText);
	EndIf;
	
	QueryText = QueryTextProductionStageStates(CalculationParameters);
	QueryTexts.Add(QueryText);
	
	If CalculationParameters.DefineRecordingMethod Then
		QueryText = QueryTextWriteSets();
		QueryTexts.Add(QueryText);
	EndIf;
	
	Return ProductionManagement.CombineRequestTextsIntoPackage(QueryTexts);
	
EndFunction

Procedure RecordStatesByOrders(Selection, Errors = Undefined)
	
	SetPrivilegedMode(True);
	
	ThereAreRecordsInSelection = Selection.Next();
	
	While ThereAreRecordsInSelection Do
		
		CurrentOrder = Selection.ReferenceOrder;
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister.ProductionStageStates");
			LockItem.SetValue("ReferenceOrder", CurrentOrder);
			
			Block.Lock();
			
			Set = InformationRegisters.ProductionStageStates.CreateRecordSet();
			Set.Filter.ReferenceOrder.Set(CurrentOrder);
			
			Set.Read();
			
			MatchingRecords = New Map;
			For Each Record In Set Do
				MatchingRecords.Insert(Record.Stage,Record);
			EndDo;
			
			While ThereAreRecordsInSelection
				And Selection.ReferenceOrder = CurrentOrder Do
				
				Record = MatchingRecords[Selection.Stage];
				If Not Selection.Posted
				 Or Selection.StatusCompleted_1 And Not Selection.RequiresOutputRegistration Then
					
					If Record <> Undefined Then
						Set.Delete(Record);
					EndIf;
					
				ElsIf Record = Undefined Then
					FillPropertyValues(Set.Add(), Selection);
				Else
					FillPropertyValues(Record, Selection);
				EndIf;
				
				ThereAreRecordsInSelection = Selection.Next();
				
			EndDo;
			
			Set.Write(True);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể phản ánh trạng thái của công đoạn theo lệnh: %Ref% vì lý do: %Cause%';
								|ru = 'Не удалось отразить состояние этапа по распоряжению: %Ref% по причине: %Cause%';
								|en = 'Cannot record state of stage by reference: %Ref%. Reason: %Cause%'; fa = 'Cannot record state of stage by reference: %Ref%. Reason: %Cause%';
								|it = 'Impossibile riflettere lo stato della fase per ordine:%Ref% a causa di: %Cause%';
								|pl = 'Odzwierciedlenie stanu etapu wg zamówienia nie powiodło się: %Ref% z powodu: %Cause%';
								|tr = 'Talimata göre aşama durumu yansıtılamadı: %Ref% çünkü: %Cause%'");
			
			MessageText = StrReplace(MessageText, "%Ref%", CurrentOrder);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(EventLogEvent(), 
				EventLogLevel.Warning, CurrentOrder.Metadata(), CurrentOrder, MessageText);
			
			If Errors <> Undefined Then
				Errors.Insert(CurrentOrder, MessageText);
			EndIf;
			
			While ThereAreRecordsInSelection
				And Selection.ReferenceOrder = CurrentOrder Do
				ThereAreRecordsInSelection = Selection.Next();
				Continue;
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure RecordStatesByStages(Selection, Errors = Undefined)
	
	SetPrivilegedMode(True);
	
	While Selection.Next() Do
		
		Set = InformationRegisters.ProductionStageStates.CreateRecordSet();
		Set.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
		Set.Filter.Stage.Set(Selection.Stage);
		
		If Selection.Posted
		   And (Not Selection.StatusCompleted_1 Or Selection.RequiresOutputRegistration) Then
			FillPropertyValues(Set.Add(), Selection);
		EndIf;
		
		Try
			
			Set.Write(True);
			
		Except
			
			MessageText = NStr("vi = 'Không thể phản ánh trạng thái công đoạn: %Ref%  vì lý do: %Cause%';
								|ru = 'Не удалось отразить состояние этапа: %Ref% по причине: %Cause%';
								|en = 'Cannot record state of stage: %Ref%. Reason: %Cause%'; fa = 'Cannot record state of stage: %Ref%. Reason: %Cause%';
								|it = 'Impossibile riflettere lo stato della fase: %Ref%: a causa di: %Cause%';
								|pl = 'Odzwierciedlenie stanu etapu nie powiodło się: %Ref% z powodu: %Cause%';
								|tr = 'Aşama durumu yansıtılamadı: %Ref% çünkü: %Cause%'");
			
			MessageText = StrReplace(MessageText, "%Ref%", Selection.Stage);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			EventLogEvent = EventLogEvent();
			
			WriteLogEvent(EventLogEvent, EventLogLevel.Warning,
				EventLogLevel.Warning, Selection.Stage.Metadata(), Selection.Stage, MessageText);
			
			If Errors <> Undefined Then
				Errors.Insert(Selection.Stage, MessageText);
			EndIf;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region UpdateOnIndicators

Procedure RecordStatesByStagesSelectively(
			Selection,
			Indicators,
			ProcessedOrders_ = Undefined,
			ProcessedStages = Undefined,
			Errors = Undefined)
	
	SetPrivilegedMode(True);
	
	LiseIndicators = StrConcat(Indicators, ",");
	CalculateDesignOfOutput = Indicators.Find("RequiresOutputRegistration") <> Undefined;
	
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			LockItem = Block.Add("InformationRegister.ProductionStageStates");
			LockItem.SetValue("Stage", Selection.Stage);
			Block.Lock();
			
			WriteSet = False;
			
			Set = InformationRegisters.ProductionStageStates.CreateRecordSet();
			Set.Filter.Stage.Set(Selection.Stage);
		
			Set.Read();
			
			If Set.Count() > 0 Then
				
				Record = Set[0];
				
				If Selection.StatusCompleted_1
					And (CalculateDesignOfOutput And Not Selection.RequiresOutputRegistration
						Or Not CalculateDesignOfOutput And Not Record.RequiresOutputRegistration) Then
					
					Set.Delete(Record);
					
				Else
					
					FillPropertyValues(Record, Selection, LiseIndicators);
					
				EndIf;
				
				WriteSet = True;
				
			ElsIf Selection.Posted
					And (Not Selection.StatusCompleted_1
						Or CalculateDesignOfOutput And Selection.RequiresOutputRegistration) Then
				
				FillPropertyValues(Set.Add(), Selection);
				
				WriteSet = True;
				
			EndIf;
			
			If WriteSet Then
				Set.Write(True);
			EndIf;
			
			CommitTransaction();
			
			If ProcessedStages <> Undefined Then
				ProcessedStages.Add(Selection.Stage);
			EndIf;
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể phản ánh trạng thái đảm bảo công đoạn: %Ref%  vì lý do: %Cause%';
								|ru = 'Не удалось отразить состояние обеспечения этапа: %Ref% по причине: %Cause%';
								|en = 'Cannot record stage supply forecast: %Ref%. Reason: %Cause%'; fa = 'Cannot record stage supply forecast: %Ref%. Reason: %Cause%';
								|it = 'Impossibile riflettere lo stato della fornitura della fase: %Ref%: a causa di: %Cause%';
								|pl = 'Odzwierciedlenie stanu zaopatrzenia etapu nie powiodło się: %Ref% z powodu: %Cause%';
								|tr = 'Aşama temininin durumu yansıtılamadı: %Ref% çünkü: %Cause%'");
			
			MessageText = StrReplace(MessageText, "%Ref%", Selection.Stage);
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			EventLogEvent = EventLogEvent();
			
			WriteLogEvent(
				EventLogEvent,
				EventLogLevel.Warning,
				Selection.Stage.Metadata(),
				Selection.Stage,
				MessageText);
			
			If Errors <> Undefined Then
				Errors.Insert(Selection.Stage, MessageText);
			EndIf;
			
			Continue;
			
		EndTry;
		
		If ProcessedOrders_ <> Undefined 
			And ProcessedOrders_.Find(Selection.ReferenceOrder) = Undefined Then
			ProcessedOrders_.Add(Selection.ReferenceOrder);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region QueriesTexts

Function QueryTextTTSupply()
	
	QueryText =
		"SELECT
		|	Balance.OrderDocument AS Ref
		|INTO StagesRequiringInventoryAllocation
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		OrderDocument IN(
		|			SELECT
		|				DocumentAttributes.Ref AS OrderDocument
		|			FROM
		|				TTDocumentDetails AS DocumentAttributes
		|			WHERE
		|				NOT DocumentAttributes.DynamicStructure)) AS Balance
		|WHERE
		|	Balance.ReserveAsReceivedBalance > 0
		|		OR Balance.SnoozeReservationBalance > 0
		|		OR Balance.ToSupplyBalance > 0
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////
		// Completed stages for which the inventory allocation task has not yet been completed, so there are no entries in the information register for them.
		|SELECT
		|	Stages.Ref AS Ref,
		// We believe that they certainly require support.
		|	TRUE AS RequiresSupply
		|INTO StagesAreExpectedToBeProvided
		|FROM
		|	StagesRequiringInventoryAllocation AS Stages
		|		
		|		LEFT JOIN InformationRegister.InventoryAllocation AS InventoryAllocation
		|		ON InventoryAllocation.ShipmentOrder = Stages.Ref
		|			AND InventoryAllocation.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|				VALUE(Enum.DemandCharacteristics.ToSupply))
		|WHERE
		|	InventoryAllocation.ShipmentOrder IS NULL
		|
		|UNION ALL
		|
		// Stages for which the inventory allocation task has been completed and not all the quantity has been distributed in the warehouse Balance.
		|SELECT
		|	Stages.Ref AS Ref,
		// We need to check whether they really require collateral.
		|	FALSE AS RequiresSupply
		|FROM
		|	StagesRequiringInventoryAllocation AS Stages
		|WHERE
		|	TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS PendingSupply
		|		FROM
		|			InformationRegister.InventoryAllocation AS InventoryAllocation
		|		WHERE
		|			InventoryAllocation.ShipmentOrder = Stages.Ref
		|			AND InventoryAllocation.InventoryState IN(
		|				VALUE(Enum.InventoryStates.NotProvided),
		|				VALUE(Enum.InventoryStates.PendingSupplyApproval),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|				VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|				VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|			AND InventoryAllocation.DemandCharacteristic IN(
		|				VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|				VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|				VALUE(Enum.DemandCharacteristics.ToSupply)))
		|INDEX BY
		|	Ref
		|;
		|
		|/////////////////////////////////////////////////////////
		|SELECT
		|	Stages.Ref AS Ref,
		|	TRUE AS RequiresSupply
		|INTO StagesRequireProvision
		|FROM
		|	StagesAreExpectedToBeProvided AS Stages
		|WHERE
		|	NOT Stages.RequiresSupply
		|	AND TRUE IN(
		|		SELECT TOP 1
		|			TRUE AS RequiresSupply
		|		FROM
		|			InformationRegister.InventoryAllocation AS InventoryAllocation
		|		WHERE
		|			InventoryAllocation.ShipmentOrder = Stages.Ref
		|				AND InventoryAllocation.DemandCharacteristic IN(
		|							VALUE(Enum.DemandCharacteristics.ReserveAsReceived),
		|							VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|							VALUE(Enum.DemandCharacteristics.ToSupply))
		|				AND (InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.NotProvided)
		|					OR InventoryAllocation.InventoryState = VALUE(Enum.InventoryStates.PendingSupplyApproval)
		|						AND NOT InventoryAllocation.ReceiptOrder REFS Document.ProductionStage2_2
		|					OR InventoryAllocation.InventoryState IN(
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithoutLock),
		|							VALUE(Enum.InventoryStates.ExpectedForReceiptWithLock),
		|							VALUE(Enum.InventoryStates.AvailablePendingUnlocking))
		|						AND InventoryAllocation.AvailabilityDate > InventoryAllocation.RequestShipmentOn))
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OrderStructure.Products AS Products,
		|	OrderStructure.Characteristic AS Characteristic,
		|	OrderStructure.Warehouse AS Warehouse,
		|	OrderStructure.Purpose AS Purpose,
		|	OrderStructure.ProductionOrder AS ProductionOrder,
		|	OrderStructure.KeyProducts AS KeyProducts
		|INTO DimensionDynamicStructure
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	OrderStructure.KeySet IN
		|			(SELECT
		|				DocumentAttributes.DocumentID
		|			FROM
		|				TTDocumentDetails AS DocumentAttributes
		|			WHERE
		|				DocumentAttributes.DynamicStructure)
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose,
		|	ProductionOrder,
		|	KeyProducts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	MAX(CASE
		|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
		|				THEN OrderStructure.Stage
		|			ELSE UNDEFINED
		|		END) AS Ref,
		|	FALSE AS RequiresSupply, // The resource is not calculated for the stages of the dynamic structure
		|	TRUE AS PendingSupply
		|INTO SupplyingDynamicStages
		|FROM
		|	InformationRegister.OrderStructure AS OrderStructure
		|WHERE
		|	TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				DimensionDynamicStructure AS DimensionDynamicStructure
		|			WHERE
		|				DimensionDynamicStructure.Products = OrderStructure.Products
		|				AND DimensionDynamicStructure.Characteristic = OrderStructure.Characteristic
		|				AND DimensionDynamicStructure.Warehouse = OrderStructure.Warehouse
		|				AND DimensionDynamicStructure.Purpose = OrderStructure.Purpose
		|				AND DimensionDynamicStructure.ProductionOrder = OrderStructure.ProductionOrder
		|				AND DimensionDynamicStructure.KeyProducts = OrderStructure.KeyProducts)
		|	AND OrderStructure.LineKind IN (
		|			VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), 
		|			VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
		|	AND OrderStructure.ReceiptOrder = UNDEFINED
		|
		|GROUP BY
		|	OrderStructure.KeyProducts
		|
		|HAVING
		|	SUM(OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) < SUM(OrderStructure.ToSupply - OrderStructure.Replaced)
		|
		|INDEX BY
		|	Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Stages.Ref AS Ref,
		|	ISNULL(StagesRequireProvision.RequiresSupply, Stages.RequiresSupply) AS RequiresSupply,
		|	TRUE AS PendingSupply
		|INTO TTSoftware
		|FROM
		|	StagesAreExpectedToBeProvided AS Stages
		|		LEFT JOIN StagesRequireProvision AS StagesRequireProvision
		|		ON (StagesRequireProvision.Ref = Stages.Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	SupplyingDynamicStages.Ref,
		|	SupplyingDynamicStages.RequiresSupply,
		|	SupplyingDynamicStages.PendingSupply
		|FROM
		|	SupplyingDynamicStages AS SupplyingDynamicStages
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DimensionDynamicStructure;
		|DROP StagesRequiringInventoryAllocation;
		|DROP StagesAreExpectedToBeProvided;
		|DROP StagesRequireProvision";
	
	Return QueryText
	
EndFunction

Function QueryTextTTStatesOfOperations()
	
	RequestTextParameters = InformationRegisters.QueueOfProductionOperations.RequestTextParametersQueueOfOperations();
	RequestTextParameters.ExecutionIndicators = True;
	RequestTextParameters.OutputTableName = "TTQueue";
	RequestTextParameters.Filters.Add("Queue.Stage IN (&ReferencesArrray)");
	
	QueryText = InformationRegisters.QueueOfProductionOperations.QueryTextOperationQueue(RequestTextParameters) + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|
		|SELECT
		|	NestedQuery.Ref AS Ref,
		|	CASE MAX(NestedQuery.State)
		|		WHEN 3
		|			THEN VALUE(Enum.StatesOfProductionStageOperations.PendingCompletion)
		|		WHEN 2
		|			THEN VALUE(Enum.StatesOfProductionStageOperations.PendingOperationAssignment)
		|		ELSE VALUE(Enum.StatesOfProductionStageOperations.Completed2)
		|	END AS State
		|	INTO TTStateOfOperations
		|FROM
		|	(SELECT
		|		DocumentAttributes.Ref AS Ref,
		|		CASE
		|			WHEN ISNULL(MIN(CASE
		|							WHEN Queue.CreatedOn >= Queue.Scheduled
		|									AND Queue.CreatedOn = Queue.Completed2 + Queue.DefectiveGoods + Queue.Skipped3
		|								THEN TRUE
		|							ELSE FALSE
		|						END), FALSE) = TRUE
		|				THEN 1
		|			WHEN ISNULL(MAX(CASE
		|						WHEN Queue.CreatedOn > Queue.Completed2 + Queue.DefectiveGoods + Queue.Skipped3
		|									OR OperationsAssignedToNW.ShiftTask IS NOT NULL
		|								THEN TRUE
		|							ELSE FALSE
		|						END), FALSE) = TRUE
		|				THEN 3
		|			ELSE 2
		|		END                     AS State
		|	FROM
		|		TTDocumentDetails AS DocumentAttributes
		|
		|			INNER JOIN TTQueue AS Queue
		|			ON DocumentAttributes.Ref = Queue.Stage
		|
		|			LEFT JOIN InformationRegister.OperationsToCreateShiftTasks AS OperationsAssignedToNW
		|			ON DocumentAttributes.Ref = OperationsAssignedToNW.Stage
		|				AND OperationsAssignedToNW.ShiftTask <> VALUE(Document.ShiftTask.EmptyRef)
		|
		|	WHERE
		|		CASE
		|			WHEN (ISNULL(DocumentAttributes.Department.UseManufacturingExecutionSystem, FALSE)
		|				OR ISNULL(DocumentAttributes.Department.UseShiftTasks, FALSE))
		|					AND DocumentAttributes.Status IN (
		|						VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
		|						VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
		|				THEN TRUE
		|			WHEN ISNULL(DocumentAttributes.Department.UseOperationManagement, FALSE)
		|					AND DocumentAttributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
		|				THEN TRUE
		|			ELSE FALSE
		|		END
		|		AND NOT DocumentAttributes.ProductionByThirdParty
		|
		|	GROUP BY
		|		DocumentAttributes.Ref
		|
		|	UNION ALL
		|	
		|	SELECT
		|		ProductionOperation.Stage AS Ref,
		|		MAX(CASE
		|					WHEN ProductionOperation.Status = VALUE(Enum.ProductionOperationStatuses.BeingGenerated)
		|						THEN 2
		|					WHEN ProductionOperation.Status = VALUE(Enum.ProductionOperationStatuses.CreatedOn_)
		|						OR ProductionOperation.Status = VALUE(Enum.ProductionOperationStatuses.Running)
		|					THEN 3
		|				ELSE 1
		|			END)                    AS State
		|	FROM
		|		TTDocumentDetails AS DocumentAttributes
		|
		|			INNER JOIN Document.ProductionOperation2_2 AS ProductionOperation
		|			ON DocumentAttributes.Ref = ProductionOperation.Stage
		|				AND ProductionOperation.Posted
		|				AND NOT ProductionOperation.BasedOnMasterData
		|				AND NOT ProductionOperation.IncludedInTechnologicalProcess
		|
		|	WHERE
		|		CASE
		|			WHEN (ISNULL(DocumentAttributes.Department.UseManufacturingExecutionSystem, FALSE)
		|				OR ISNULL(DocumentAttributes.Department.UseShiftTasks, FALSE))
		|					AND DocumentAttributes.Status IN (
		|						VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
		|						VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
		|				THEN TRUE
		|			WHEN ISNULL(DocumentAttributes.Department.UseOperationManagement, FALSE)
		|					AND DocumentAttributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated) 
		|				THEN TRUE
		|			ELSE FALSE
		|		END
		|	
		|	GROUP BY
		|		ProductionOperation.Stage) AS NestedQuery
		|
		|GROUP BY
		|	NestedQuery.Ref";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLaborCostsToRegister()
	
	QueryText =
		"SELECT
		|	LaborCostsToRegisterBalance.ReferenceOrder AS Ref
		|INTO TTLaborCostsForRegistration
		|FROM
		|	AccumulationRegister.LaborCostsToRegister.Balance(
		|				,
		|				ReferenceOrder IN
		|					(SELECT
		|						T.Ref AS ReferenceOrder
		|					FROM
		|						TTDocumentDetails AS T)) AS LaborCostsToRegisterBalance";
	
	Return QueryText
	
EndFunction

Function QueryTextProductionStageStates(CalculationParameters)
	
	QueryText = "SELECT
			|	CASE
			|		WHEN TTDocumentDetails.Status = &StatusIsGenerated THEN
			|			VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification)
			|		WHEN TTDocumentDetails.Status = &GeneratedStatus
			|			THEN CASE
			|					WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
			|						THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment)
			|					ELSE &EmptyStateAtInterShopLevel
			|				END
			|		WHEN TTDocumentDetails.Status = &StatusPending
			|			THEN CASE
			|					WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
			|						THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingStart)
			|					ELSE VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingPredecessors)
			|				END
			|		WHEN TTDocumentDetails.Status = &StatusStarted
			|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingCompletion)
			|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
			|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.Completed)
			|		ELSE &EmptyStateAtInterShopLevel
			|
			|	END                               AS StateAtIntershopLevel,
			|
			|	CASE
			|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
			|			THEN VALUE(Enum.ShopfloorLevelStagesStates.Completed)
			|		WHEN TTDocumentDetails.Status = &StatusStarted
			|			THEN VALUE(Enum.ShopfloorLevelStagesStates.Initiated)
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
			|			THEN VALUE(Enum.ShopfloorLevelStagesStates.ExecutionIsAllowed)
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &PredecessorsAreStarted
			|			THEN VALUE(Enum.ShopfloorLevelStagesStates.PreviousOnesStarted)
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &NotPredecessorsAreStarted
			|			THEN VALUE(Enum.ShopfloorLevelStagesStates.PendingPredecessorCompletion)
			|		ELSE &EmptyStateAtIntraShopLevel
			|
			|	END                               AS ShopfloorLevelStatus,
			|
			|	CASE
			|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
			|			THEN 5
			|		WHEN TTDocumentDetails.Status = &StatusStarted
			|			THEN 4
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
			|			THEN 3
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &PredecessorsAreStarted
			|			THEN 2
			|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &NotPredecessorsAreStarted
			|			THEN 1
			|		ELSE 0
			|
			|	END                               AS ShopfloorLevelStatusCode,
			|
			|	CASE
			|		WHEN NOT StatesOfOperations.Ref IS NULL
			|			THEN StatesOfOperations.State
			|		ELSE VALUE(Enum.StatesOfProductionStageOperations.EmptyRef)
			|
			|	END                               AS OperationStatus,
			|
			|	ISNULL(Supply.RequiresSupply, FALSE) AS RequiresSupply,
			|
			|	CASE
			|		WHEN ISNULL(Supply.PendingSupply, FALSE)
			|			THEN VALUE(Enum.SupplyStateOfProductionStage.PendingSupply)
			|		ELSE VALUE(Enum.SupplyStateOfProductionStage.SuppliedFully)
			|	END AS SupplyState,
			|
			|	CASE
			|		WHEN LaborCostsToRegister.Ref IS NULL
			|			THEN FALSE
			|		ELSE TRUE
			|	END 								AS RequiresOutputRegistration,
			|
			|	TTDocumentDetails.ReferenceOrder   AS ReferenceOrder,
			|	TTDocumentDetails.Ref         AS Stage,
			|	TTDocumentDetails.StatusCompleted_1 AS StatusCompleted_1,
			|	TTDocumentDetails.Posted       AS Posted
			|FROM
			|	TTDocumentDetails AS TTDocumentDetails
			|
			|		LEFT JOIN TTSoftware AS Supply
			|		ON Supply.Ref = TTDocumentDetails.Ref
			|
			|		LEFT JOIN TTLaborCostsForRegistration AS LaborCostsToRegister
			|		ON LaborCostsToRegister.Ref = TTDocumentDetails.Ref
			|
			|		LEFT JOIN TTStateOfOperations AS StatesOfOperations
			|		ON StatesOfOperations.Ref = TTDocumentDetails.Ref
			|
			|		LEFT JOIN TTStatesOfPredecessors AS PredecessorStates
			|		ON PredecessorStates.Ref = TTDocumentDetails.Ref
			|
			|ORDER BY
			|	ReferenceOrder";
	
	QueryText = ?(CalculationParameters.CalculateStateOfStages, QueryText, StrReplace(QueryText,"
		|	CASE
		|		WHEN TTDocumentDetails.Status = &StatusIsGenerated THEN
		|			VALUE(Enum.StateOfProductionStagesAtIntershopLevel.RequiresClarification)
		|		WHEN TTDocumentDetails.Status = &GeneratedStatus
		|			THEN CASE
		|					WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
		|						THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.ReadyForFulfillment)
		|					ELSE &EmptyStateAtInterShopLevel
		|				END
		|		WHEN TTDocumentDetails.Status = &StatusPending
		|			THEN CASE
		|					WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
		|						THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingStart)
		|					ELSE VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingPredecessors)
		|				END
		|		WHEN TTDocumentDetails.Status = &StatusStarted
		|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.PendingCompletion)
		|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
		|			THEN VALUE(Enum.StateOfProductionStagesAtIntershopLevel.Completed)
		|		ELSE &EmptyStateAtInterShopLevel
		|
		|	END                               AS StateAtIntershopLevel,
		|
		|	CASE
		|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
		|			THEN VALUE(Enum.ShopfloorLevelStagesStates.Completed)
		|		WHEN TTDocumentDetails.Status = &StatusStarted
		|			THEN VALUE(Enum.ShopfloorLevelStagesStates.Initiated)
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
		|			THEN VALUE(Enum.ShopfloorLevelStagesStates.ExecutionIsAllowed)
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &PredecessorsAreStarted
		|			THEN VALUE(Enum.ShopfloorLevelStagesStates.PreviousOnesStarted)
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &NotPredecessorsAreStarted
		|			THEN VALUE(Enum.ShopfloorLevelStagesStates.PendingPredecessorCompletion)
		|		ELSE &EmptyStateAtIntraShopLevel
		|
		|	END                               AS ShopfloorLevelStatus,
		|
		|	CASE
		|		WHEN TTDocumentDetails.Status = &StatusCompleted_1
		|			THEN 5
		|		WHEN TTDocumentDetails.Status = &StatusStarted
		|			THEN 4
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) IN (&NoPredecessors, &PredecessorsAreCompleted)
		|			THEN 3
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &PredecessorsAreStarted
		|			THEN 2
		|		WHEN ISNULL(PredecessorStates.State, &NoPredecessors) = &NotPredecessorsAreStarted
		|			THEN 1
		|		ELSE 0
		|
		|	END                               AS ShopfloorLevelStatusCode,", ""));
	
	QueryText = ?(CalculationParameters.CalculateStateOfOperations, QueryText, StrReplace(QueryText, "
		|	CASE
		|		WHEN NOT StatesOfOperations.Ref IS NULL
		|			THEN StatesOfOperations.State
		|		ELSE VALUE(Enum.StatesOfProductionStageOperations.EmptyRef)
		|
		|	END                               AS OperationStatus,",""));
	
	QueryText = ?(CalculationParameters.CalculateCollateral, QueryText, StrReplace(QueryText, "
			|	ISNULL(Supply.RequiresSupply, FALSE) AS RequiresSupply,",""));
			
	QueryText = ?(CalculationParameters.CalculateCollateral, QueryText, StrReplace(QueryText, "
			|	CASE
			|		WHEN ISNULL(Supply.PendingSupply, FALSE)
			|			THEN VALUE(Enum.SupplyStateOfProductionStage.PendingSupply)
			|		ELSE VALUE(Enum.SupplyStateOfProductionStage.SuppliedFully)
			|	END AS SupplyState,",""));
	
	QueryText = ?(CalculationParameters.CalculateDesignOfOutput, QueryText, StrReplace(QueryText, "
			|	CASE
			|		WHEN LaborCostsToRegister.Ref IS NULL
			|			THEN FALSE
			|		ELSE TRUE
			|	END 								AS RequiresOutputRegistration,",""));
	
	QueryText = ?(CalculationParameters.CalculateCollateral, QueryText, StrReplace(QueryText, "
			|		LEFT JOIN TTSoftware AS Supply
			|		ON Supply.Ref = TTDocumentDetails.Ref",""));
	
	QueryText = ?(CalculationParameters.CalculateDesignOfOutput, QueryText, StrReplace(QueryText, "
			|		LEFT JOIN TTLaborCostsForRegistration AS LaborCostsToRegister
			|		ON LaborCostsToRegister.Ref = TTDocumentDetails.Ref",""));
	
	QueryText = ?(CalculationParameters.CalculateStateOfOperations, QueryText, StrReplace(QueryText, "
			|		LEFT JOIN TTStateOfOperations AS StatesOfOperations
			|		ON StatesOfOperations.Ref = TTDocumentDetails.Ref",""));
	
	QueryText = ?(CalculationParameters.CalculateStateOfStages, QueryText, StrReplace(QueryText, "
			|		LEFT JOIN TTStatesOfPredecessors AS PredecessorStates
			|		ON PredecessorStates.Ref = TTDocumentDetails.Ref",""));
	
	Return QueryText;
	
EndFunction

Function QueryTextWriteSets()
	
	QueryText =
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	TTDocumentDetails AS Table
		|
		|GROUP BY
		|	Table.ReferenceOrder
		|
		|HAVING
		|	COUNT(Table.Ref) > 100";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function QueryTextProductionStageStatesUpdate(Query)
	
	QueryText =
	"SELECT
	|	Table.OrderDocument AS ReflectedDocument
	|FROM
	|	ProductionStageStatesUpdate AS Table
	|";
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_;
	
EndFunction

Function EventLogEvent()
	
	Return NStr("vi = 'Quản lý liên xưởng';
				|ru = 'Межцеховое управление';
				|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
				|it = 'Gestione interna dei reparti';
				|pl = 'Zarządzanie międzyresortowe';
				|tr = 'Üretim planlama ve kontrolü'", CommonClientServer.DefaultLanguageCode()) + "."
			+ NStr("vi = 'Lỗi phản ánh trạng thái đảm bảo các công đoạn';
					|ru = 'Ошибка отражения состояния обеспечения этапов';
					|en = 'Error recording stage supply forecast'; fa = 'Error recording stage supply forecast';
					|it = 'Errore di registrazione dello stato di controllo delle fasi';
					|pl = 'Błąd odzwierciedlenia statusu zabezpieczenia etapów';
					|tr = 'Aşama temini durumunun yansıtılma hatası'", CommonClientServer.DefaultLanguageCode());
	
EndFunction

Function CalculationParametersConstructor(ArrayOfLinksToUpdate = Undefined, ArrayOfLinksToCleanUp = Undefined, Indicators = Undefined)
	
	CalculationParameters = New Structure;
	
	If ArrayOfLinksToUpdate <> Undefined Then
		CalculationParameters.Insert("ArrayOfLinksToUpdate", ArrayOfLinksToUpdate);
	Else
		CalculationParameters.Insert("ArrayOfLinksToUpdate", New Array);
	EndIf;
	
	If ArrayOfLinksToCleanUp <> Undefined Then
		CalculationParameters.Insert("ArrayOfLinksToCleanUp", ArrayOfLinksToCleanUp);
	Else
		CalculationParameters.Insert("ArrayOfLinksToCleanUp", New Array);
	EndIf;
	
	If Indicators = Undefined Then
		Indicators = PerformanceIndicators();
	EndIf;
	
	CalculationParameters.Insert("CalculateCollateral", 
		Indicators.Find("RequiresSupply") <> Undefined
		Or Indicators.Find("SupplyState") <> Undefined);
	CalculationParameters.Insert("CalculateDesignOfOutput", Indicators.Find("RequiresOutputRegistration") <> Undefined);
	CalculationParameters.Insert("CalculateStateOfStages", Indicators.Find("StateAtIntershopLevel") <> Undefined);
	CalculationParameters.Insert("CalculateStateOfOperations", Indicators.Find("OperationStatus") <> Undefined);
	
	CalculationParameters.Insert("Indicators", Indicators);
	
	If ArrayOfLinksToUpdate <> Undefined
		And ArrayOfLinksToUpdate.Count() > 100 Then
		CalculationParameters.Insert("DefineRecordingMethod", True);
	Else
		CalculationParameters.Insert("DefineRecordingMethod", False);
	EndIf;

	CalculationParameters.Insert("WriteSets", False);
	
	Return CalculationParameters;
	
EndFunction

Function PerformanceIndicators()
	
	Indicators = New Array;
	
	Indicators.Add("RequiresSupply");
	Indicators.Add("SupplyState");
	Indicators.Add("RequiresOutputRegistration");
	Indicators.Add("StateAtIntershopLevel");
	Indicators.Add("ShopfloorLevelStatus");
	Indicators.Add("OperationStatus");
	
	Return Indicators;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ProductionStageStates.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.49";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("24dd6f4b-8e6c-4620-808c-68a4c05b6401");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.ProductionStageStates.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("ru = 'Обновление поля ""Состояние обеспечения"" для динамических этапов производства.';
							|vi = 'Update the ""Supply forecast"" field for dynamic production stages.';
							|en = 'Update the ""Supply forecast"" field for dynamic production stages.'; fa = 'Update the ""Supply forecast"" field for dynamic production stages.';
							|it = 'Update the ""Supply forecast"" field for dynamic production stages.';
							|pl = 'Update the ""Supply forecast"" field for dynamic production stages.';
							|tr = 'Dinamik üretim aşamaları için ""Tedarik durumu"" alanının güncellenmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.ProductionStageStates.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.OrderStructure.FullName());
	ItemsToRead.Add(Metadata.Documents.ProductionStage2_2.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.ProductionStageStates.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.ProductionStageStates";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Stage.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Stage");
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	QueryText = 
	"SELECT
	|	ProductionStageStates.ReferenceOrder AS ReferenceOrder,
	|	ProductionStageStates.Stage AS Stage
	|INTO DynamicStagesAwaitingSupply
	|FROM
	|	InformationRegister.ProductionStageStates AS ProductionStageStates
	|WHERE
	|	ProductionStageStates.SupplyState = VALUE(Enum.SupplyStateOfProductionStage.PendingSupply)
	|	AND TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				Document.ProductionStage2_2 AS Stages
	|			WHERE
	|				Stages.Ref = ProductionStageStates.Stage
	|				AND Stages.DynamicStructure)
	|
	|INDEX BY
	|	Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.DynamicStructure AS DynamicStructure,
	|	UUID(Table.Ref) AS DocumentID
	|INTO TTDocumentDetails
	|FROM
	|	Document.ProductionStage2_2 AS Table
	|WHERE
	|	Table.Ref IN
	|			(SELECT
	|				T.Stage AS Ref
	|			FROM
	|				DynamicStagesAwaitingSupply AS T)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrderStructure.Products AS Products,
	|	OrderStructure.Characteristic AS Characteristic,
	|	OrderStructure.Warehouse AS Warehouse,
	|	OrderStructure.Purpose AS Purpose,
	|	OrderStructure.ProductionOrder AS ProductionOrder,
	|	OrderStructure.KeyProducts AS KeyProducts
	|INTO DimensionDynamicStructure
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	OrderStructure.KeySet IN
	|			(SELECT
	|				DocumentAttributes.DocumentID
	|			FROM
	|				TTDocumentDetails AS DocumentAttributes
	|			WHERE
	|				DocumentAttributes.DynamicStructure)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Warehouse,
	|	Purpose,
	|	ProductionOrder,
	|	KeyProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MAX(CASE
	|			WHEN OrderStructure.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)
	|				THEN OrderStructure.Stage
	|			ELSE UNDEFINED
	|		END) AS Ref,
	|	FALSE AS RequiresSupply,
	|	TRUE AS PendingSupply
	|INTO SecurityTable
	|FROM
	|	InformationRegister.OrderStructure AS OrderStructure
	|WHERE
	|	TRUE IN
	|			(SELECT
	|				TRUE
	|			FROM
	|				DimensionDynamicStructure AS DimensionDynamicStructure
	|			WHERE
	|				DimensionDynamicStructure.Products = OrderStructure.Products
	|				AND DimensionDynamicStructure.Characteristic = OrderStructure.Characteristic
	|				AND DimensionDynamicStructure.Warehouse = OrderStructure.Warehouse
	|				AND DimensionDynamicStructure.Purpose = OrderStructure.Purpose
	|				AND DimensionDynamicStructure.ProductionOrder = OrderStructure.ProductionOrder
	|				AND DimensionDynamicStructure.KeyProducts = OrderStructure.KeyProducts)
	|	AND OrderStructure.LineKind IN (
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption), 
	|		VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
	|	AND OrderStructure.ReceiptOrder = UNDEFINED
	|
	|GROUP BY
	|	OrderStructure.KeyProducts
	|
	|HAVING
	|	SUM(OrderStructure.AllocatedFromAvailableInventory + OrderStructure.AllocatedFromAvailableInventoryWithAssignment) < SUM(OrderStructure.ToSupply - OrderStructure.Replaced)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DynamicStagesAwaitingSupply.Stage AS Stage,
	|	DynamicStagesAwaitingSupply.ReferenceOrder AS ReferenceOrder
	|FROM
	|	DynamicStagesAwaitingSupply AS DynamicStagesAwaitingSupply
	|WHERE
	|	NOT TRUE IN
	|				(SELECT
	|					TRUE
	|				FROM
	|					SecurityTable AS SecurityTable
	|				WHERE
	|					SecurityTable.Ref = DynamicStagesAwaitingSupply.Stage)";
	
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(
		Parameters,
		Query.Execute().Unload(),
		AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.ProductionStageStates";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	OtherStages = New Array;
	For Each Selection In UpdatedData Do
		OtherStages.Add(Selection.Stage);
	EndDo;
	
	BeginTransaction();
	
	Try
	
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			OtherStages,
			"ACTION_REFRESH_SUPPLY_STATE",
			"ProductionStageStates");
			
		AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
		AdditionalParameters.Insert("IsIndependentInformationRegister", True);
		AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
				
		InfobaseUpdate.MarkProcessingCompletion(UpdatedData, AdditionalParameters);
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		MessageText = StrTemplate(
			NStr("ru = 'Не удалось выполнить обновление данных регистра ""Состояния этапов производства"" по причине: %1';
				|vi = 'Cannot update the data of the ""Production stage states"" register. Reason: %1';
				|en = 'Cannot update the data of the ""Production stage states"" register. Reason: %1'; fa = 'Cannot update the data of the ""Production stage states"" register. Reason: %1';
				|it = 'Cannot update the data of the ""Production stage states"" register. Reason: %1';
				|pl = 'Cannot update the data of the ""Production stage states"" register. Reason: %1';
				|tr = '""Üretim aşamalarının durumları"" kayıt tablosu verileri şu nedenle güncellenemedi: %1'"),
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.InformationRegisters.ProductionStageStates,,
			MessageText);
		
	EndTry;
	
	DeferredJobs.Run(Metadata.InformationRegisters.JobsToReflectOrderState.Name);
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
