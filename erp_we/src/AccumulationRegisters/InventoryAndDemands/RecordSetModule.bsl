#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	InstalledLocks = AccumulationRegisters.InventoryAndDemands.SetBlockingOrdersAndProducts(
		ThisObject, Filter.Recorder.Value, False);

	DeferredCollateralIsPossible = False;
	If Constants.OptionOfOrderingDemandsByOrdersForSupply.Get()
				<> Enums.OptionsOfOrderingDemandsByOrdersForSupply.PriorityAndDocumentDate
			And Not Constants.ControlBalanceOfGoodsToBeReservedUponReceipt.Get() Then
		
		For Each String In ThisObject Do
			If ValueIsFilled(String.EventDate) And String.ReserveAsReceived <> 0 Then
				DeferredCollateralIsPossible = True;
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	If DeferredCollateralIsPossible Then
		AccumulationRegisters.InventoryAndDemands.AddDeferredCollateralRecordsToSet(ThisObject);
	EndIf;
	
	// The conducted document is a document for which it is necessary to put the estimated records
	// of the closing of the receipt schedule or the closing of the unlocking schedule.
	// The records are placed in the processing before recording, so as not to record the primary records first
	// and then, when recording, the calculated records for the same document.
	Recorder = Filter.Recorder.Value;
	If InstalledLocks.RecordersAndOrders.Find(Recorder, "Recorder") <> Undefined Then
		
		AttachableSet = ThisObject;
		Query = New Query();
		Query.TempTablesManager = New TempTablesManager;
		
		AccumulationRegisters.InventoryAndDemands.TempTableOfChartClosure(
			Query,
			"GraphCalculationResults",
			InstalledLocks,
			AttachableSet);
		
		Query.SetParameter("Recorder", Recorder);
		Query.Text =
			"SELECT
			|	CalculationResults.Period AS Period,
			|	CalculationResults.RecordType AS RecordType,
			|	CalculationResults.Active AS Active,
			|	CalculationResults.Products AS Products,
			|	CalculationResults.Characteristic AS Characteristic,
			|	CalculationResults.Warehouse AS Warehouse,
			|	CalculationResults.Purpose AS Purpose,
			|	CalculationResults.OrderDocument AS OrderDocument,
			|	CalculationResults.EventDate AS EventDate,
			|	CalculationResults.InStock AS InStock,
			|	CalculationResults.Received_1 AS Received_1,
			|	CalculationResults.Ordered AS Ordered,
			|	CalculationResults.ReserveAtWarehouse AS ReserveAtWarehouse,
			|	CalculationResults.ReserveAsReceived AS ReserveAsReceived,
			|	CalculationResults.SnoozeReservation AS SnoozeReservation,
			|	CalculationResults.ToSupply AS ToSupply,
			|	CalculationResults.NotProvide AS NotProvide,
			|	CalculationResults.LockedInStock AS LockedInStock,
			|	CalculationResults.LockedReceipt AS LockedReceipt,
			|	CalculationResults.ToUnlock AS ToUnlock,
			|	CalculationResults.ReserveAtWarehouseFromLocked AS ReserveAtWarehouseFromLocked,
			|	CalculationResults.ReserveUponReceiptFromLocked AS ReserveUponReceiptFromLocked,
			|	CalculationResults.CloseReceiptSchedule AS CloseReceiptSchedule,
			|	CalculationResults.ToControlQuality AS ToControlQuality,
			|	CalculationResults.SubjectToUnlocking AS SubjectToUnlocking,
			|	CalculationResults.CloseScheduleShipping AS CloseScheduleShipping,
			|	UNDEFINED AS OrderToShip,
			|	CalculationResults.EntryType AS EntryType,
			|	CalculationResults.ReversingEntry AS ReversingEntry
			|FROM
			|	GraphCalculationResults AS CalculationResults
			|WHERE
			|	CalculationResults.Recorder = &Recorder";
		
		Table = Query.Execute().Unload();
		For IndexOf = 0 To Table.Count() - 1 Do
			FillPropertyValues(Add(), Table[IndexOf]);
		EndDo;
		
		AccumulationRegisters.InventoryAndDemands.RecordResultOfGraphCalculation(
			InstalledLocks,
			Query,
			Recorder);
		
	ElsIf InstalledLocks.Orders.Count() > 0 Then
		AdditionalProperties.Insert("InstalledLocks", InstalledLocks);
	EndIf;
	
	If TypeOf(Filter.Recorder.Value) = Type("DocumentRef.RegisterAdjustment") Then
		AdditionalProperties.Insert("CalculateChanges_", True);
		AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		Document = DocumentsPosting.DocumentEmulation(Filter.Recorder.Value, Undefined);
		AdditionalProperties.Insert("DocumentProperties",
			Document.AdditionalProperties.DocumentsPosting.DocumentProperties);
		AdditionalProperties.Insert("ControlTables", New Structure());
	EndIf;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		GenerateTableOfInitialRegisteredRecords();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InstalledLocks = Undefined;
	If AdditionalProperties.Property("InstalledLocks", InstalledLocks) Then
		
		Query = New Query();
		Query.TempTablesManager = New TempTablesManager;
		
		AccumulationRegisters.InventoryAndDemands.TempTableOfChartClosure(
			Query,
			"GraphCalculationResults",
			InstalledLocks);
			
		AccumulationRegisters.InventoryAndDemands.RecordResultOfGraphCalculation(InstalledLocks, Query);
		
	EndIf;
	
	If DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		GenerateTableOfMotionChanges();
	EndIf;
	
	If TypeOf(Filter.Recorder.Value) = Type("DocumentRef.RegisterAdjustment") Then
		Document = DocumentsPosting.DocumentEmulation(Filter.Recorder.Value, Undefined);
		TempTablesManager = AdditionalProperties.TempTablesManager;
		DocumentEmulation = DocumentsPosting.DocumentEmulation(Undefined, Undefined);
		StockAllocationRecords.ReflectInventoryAllocationTasks(DocumentEmulation, TempTablesManager);
		DocumentsStates.ReflectDocumentStates(Document, TempTablesManager);
		OrderStructureDocumentPosting.CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(Document, TempTablesManager);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

Procedure EnableBlockingOfSetInformationRegister() Export
	
	AdditionalProperties.Insert("EnableBlockingOfSetInformationRegister");
	
EndProcedure

#EndRegion

#Region Private

#Region CaseChangeTables

Procedure GenerateTableOfInitialRegisteredRecords()
	
	// The current state of the set is placed in the temporary table "Motion by Recording"
	// in order to get a change in the new set relative to the current one when recording.
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("IsNew", AdditionalProperties.DocumentProperties.IsNew);
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	Query.Text = StockAllocationRecords.QueryTextOfInitialRegisteredRecordedInventoryAndNeeds();
	Query.Execute();
	
EndProcedure

Procedure GenerateTableOfMotionChanges()
	
	Query = New Query;
	Query.SetParameter("Recorder", Filter.Recorder.Value);
	Query.SetParameter("ControlExcessOfSeparateProvision",
		SupplyCached.ControlExcessOfSeparateProvision());
	Query.TempTablesManager = AdditionalProperties.TempTablesManager;
	
	// The change of the new set relative to the current one is calculated taking into account the accumulated changes
	// and placed in a temporary table.
	
	Texts = New Array();
	Text = StockAllocationRecords.QueryTextOfChangesInRegisteredRecordedInventoryAndNeeds(True);
	Texts.Add(Text);
	Text =
		"SELECT DISTINCT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument
		|INTO InventoryAndNeedsAffectedOrders
		|FROM
		|	AccumulationRegister.InventoryAndDemands AS Table
		|WHERE
		|	Table.Recorder = &Recorder
		|		AND Table.Active
		|
		|UNION
		|
		|SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	Table.Purpose AS Purpose,
		|	Table.OrderDocument AS OrderDocument
		|FROM
		|	InventoryAndDemandsBeforeWrite AS Table
		|
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose, OrderDocument";
	Texts.Add(Text);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[Result.UBound() - 1].Select();
	HasChanges = Selection.Next() And Selection.Count > 0;
	DocumentsPosting.RegisterControlTable(AdditionalProperties, "InventoryAndDemandsUpdate", HasChanges);
	DocumentsPosting.RegisterControlTable(AdditionalProperties, "InventoryAndDemandsBeforeWrite", HasChanges);
	DocumentsPosting.RegisterControlTable(AdditionalProperties, "InventoryAndNeedsAffectedOrders", HasChanges);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

