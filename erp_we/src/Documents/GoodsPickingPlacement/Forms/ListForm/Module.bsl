
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Status = "All";
	
	If Not GetFunctionalOption("UseOrderSupplyWithAssignment") Then
		Items.CreateAutomaticTransferJob.Title = NStr("vi = 'Nhiệm vụ tiếp nhiên liệu (tự động)...';
														|ru = 'Задание на подпитку (автоматически)...';
														|en = 'Replenishment task (automatically)...'; fa = 'Replenishment task (automatically)...';
														|it = 'Task di reintegro (automaticamente)...';
														|pl = 'Zadanie podładowania (automatycznie)...';
														|tr = 'Stok yenileme görevi (otomatik)...'");
	EndIf;
	
	WarehouseSpaceWhenServerChanges();
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.StandardListActions);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	TMCommonUse.ClearFormSettingsOrDetailsFromNonexistentLinks(Settings, ThisObject);
	WarehouseSpaceWhenServerChanges();
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseSelectionOnChange(Item)
	WarehouseSpaceWhenServerChanges();
EndProcedure

&AtClient
Procedure RoomSelection_OnChange(Item)
	WarehouseSpaceWhenServerChanges();
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	SetSelectionsInLists();
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	SetSelectionsInLists();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure TakeUpTheJobs(Command)
	
	Notification = New CallbackDescription("TakeUpTheJobsCompletion", ThisObject);
	
	WarehousesClient.TakeUpTheJobs(ThisForm, Items.List , "FilterLocation", Notification);
	
EndProcedure

&AtClient
Procedure TakeUpTheJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInLists();

EndProcedure

&AtClient
Procedure CompleteJobs(Command)
	
	Notification = New CallbackDescription("CompleteJobsCompletion", ThisObject);
	
	WarehousesClient.MarkCompletionOfTasksWithoutErrors(ThisForm, Items.List, "FilterLocation", Notification);
	
EndProcedure

&AtClient
Procedure CompleteJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInLists();

EndProcedure

&AtClient
Procedure CreateGoodsTransferJob(Command)
	FillParameters = New Structure;
	FillParameters.Insert("Warehouse", Warehouse);
	FillParameters.Insert("Premise", Premise);
	FillParameters.Insert("OperationKind", PredefinedValue("Enum.OperationKindsOfGoodsPlacementPicking.Move"));
	
	OpenForm("Document.GoodsPickingPlacement.ObjectForm", New Structure("FillingValues",FillParameters), ThisForm);
EndProcedure

&AtClient
Procedure CreatePlacementJob(Command)
	FillParameters = New Structure;
	FillParameters.Insert("Warehouse", Warehouse);
	FillParameters.Insert("Premise", Premise);
	FillParameters.Insert("OperationKind", PredefinedValue("Enum.OperationKindsOfGoodsPlacementPicking.Location"));
	
	OpenForm("Document.GoodsPickingPlacement.ObjectForm", New Structure("FillingValues",FillParameters), ThisForm);
EndProcedure

&AtClient
Procedure SettingsOfBinLocationWarehouses(Command)
	FormParameters = New Structure("Key", KeyForRecordingAddressWarehouseSettings(Warehouse, Premise));
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.RecordForm", FormParameters, ThisForm,,);
EndProcedure

&AtClient
Procedure CreateAutomaticTransferJob(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Warehouse);
	FormParameters.Insert("Premise", Premise);
	FormParameters.Insert("ScheduledJobAction", "CreateJobs");
		
	NotificationEndOfEditingCreateMoveJobAutomatically = 
		New CallbackDescription("CreateAutomaticTransferJobCompletion", ThisForm);
		
	OpenForm("InformationRegister.SettingsOfBinLocationWarehouses.Form.SettingsFormOfWarehouseTransferGoodsJobsCreation", 
		FormParameters, 
		ThisForm,,,,
		NotificationEndOfEditingCreateMoveJobAutomatically, 
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	UseWarerooms = WarehousesServer.UseWarerooms(Warehouse);
	Items.RoomSelection_.Visible = UseWarerooms;
	Items.WarehouseZone.Visible = WarehousesServer.UseWarehouseZones(Warehouse, Premise);
	Items.SettingsOfBinLocationWarehouses.Enabled = ValueIsFilled(Warehouse) 
		And (Not UseWarerooms Or ValueIsFilled(Premise));
	Items.MovingTaskGroup.Enabled = ValueIsFilled(Warehouse) 
		And (Not UseWarerooms Or ValueIsFilled(Premise));
	SetSelectionsInLists();
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.GoodsPickingPlacement.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		Items.List.CurrentRow = ReferencesArrray[0];
		ShowValue(Undefined, ReferencesArrray[0]);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region AutomaticCreationOfRelocationTasks

&AtServerNoContext
Function KeyForRecordingAddressWarehouseSettings(Warehouse, Premise)
	DimensionStructure = New Structure;
	DimensionStructure.Insert("Warehouse", Warehouse);
	DimensionStructure.Insert("Premise", Premise);
	
	Return InformationRegisters.SettingsOfBinLocationWarehouses.CreateRecordKey(DimensionStructure);
EndFunction

&AtClient
Procedure CreateAutomaticTransferJobCompletion(ClosingResult, AdditionalParameters) Export
	
	If ValueIsFilled(ClosingResult)
		And ClosingResult.Action <> "Cancel" Then
			
		CreateMoveJobOnServer(ClosingResult.SettingsForCreatingMoves);
		NotifyChanged(Type("DocumentRef.GoodsPickingPlacement"));
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CreateMoveJobOnServer(SettingsForCreatingMoves)
	
	WarehousesServer.CreateTasksToMoveByRule(SettingsForCreatingMoves);
	
EndProcedure

#EndRegion

&AtServer
Procedure SetSelectionsInLists()
	
	CommonClientServer.SetDynamicListFilterItem(List, "Premise", Premise,
		DataCompositionComparisonType.Equal,, True);
	CommonClientServer.SetDynamicListFilterItem(List, "Warehouse", Warehouse,
		DataCompositionComparisonType.Equal,, True);
	
	If Status = "All" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status",,,,False);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted",,,,False);
	ElsIf Status = "Incomplete" Then
		StatusesList = New ValueList;
		StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
		StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
		
		CommonClientServer.SetDynamicListFilterItem(List, "Status", StatusesList, DataCompositionComparisonType.InList,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "PreparedReportDistributionDetails" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", Enums.StatusesOfGoodsPickingPlacement.Prepared2, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "InProgress" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", Enums.StatusesOfGoodsPickingPlacement.InProgress, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "Executed_WithErrors" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", Enums.StatusesOfGoodsPickingPlacement.DoneWithErrors, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,,True);
	ElsIf Status = "ExecutedWithoutErrors" Then
		CommonClientServer.SetDynamicListFilterItem(List, "Status", Enums.StatusesOfGoodsPickingPlacement.CompletedWithoutErrors, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(List, "Posted", True, DataCompositionComparisonType.Equal,,True);
	EndIf;
		
	CommonClientServer.SetDynamicListFilterItem(List, "OperationKind", OperationKindPicking, DataCompositionComparisonType.Equal,, ValueIsFilled(OperationKindPicking));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
