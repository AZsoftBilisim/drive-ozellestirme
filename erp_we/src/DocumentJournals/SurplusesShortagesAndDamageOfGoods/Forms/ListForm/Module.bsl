
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	UseGoodsQuality = GetFunctionalOption("UseGoodsQuality");
	
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	WarehouseSpaceWhenServerChanges();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.GroupCommandPanelOfOrders;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	Items.ListOfOrdersCreateAnOrderToReflectSurpluses.Visible = AccessRight("Update", Metadata.Documents.GoodsSurplusesNote);
	Items.ListOfOrdersCreateAnOrderToReflectShortfalls.Visible = AccessRight("Update", Metadata.Documents.GoodsShortageNote);
	Items.TheListOfOrdersCreateAnOrderForTheReflectedDamage.Visible    = AccessRight("Update", Metadata.Documents.DamageNote);
	Items.ListOfOrdersCreateAnOrderToReflectTheReSortingOfGoods.Visible = AccessRight("Update", Metadata.Documents.GoodsMisgradingNote);
		
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "OrdersList.Date", Items.OrdersListDate.Name);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();
	
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

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	Warehouse = Settings.Get("Warehouse");
	Premise = Settings.Get("Premise");
	WarehouseSpaceWhenServerChanges();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	WarehouseSpaceWhenServerChanges();
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	WarehouseSpaceWhenServerChanges();
	EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue();
EndProcedure

&AtClient
Procedure ThereIsAProblemURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If URL = "StartGeneration" Then
		
		ClearMessages();
		StartCreatingAdjustments();		
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AttentionClick(Item)
	ClearMessages();
	StartCreatingAdjustments();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOrdersList

&AtClient
Procedure OrdersListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		
		Cancel = True;
		
		ValueList = New ValueList;
		ValueList.Add(Type("DocumentRef.GoodsSurplusesNote"),,,PictureLib.Document);
		ValueList.Add(Type("DocumentRef.GoodsShortageNote"),,,PictureLib.Document);
		ValueList.Add(Type("DocumentRef.GoodsMisgradingNote"),,,PictureLib.Document);
		
		If UseGoodsQuality Then
			ValueList.Add(Type("DocumentRef.DamageNote"),,,PictureLib.Document);
		EndIf;
		
		ValueSelected = Undefined;

		
		ValueList.ShowChooseItem(New CallbackDescription("OrdersListBeforeAddRowCompletion", ThisObject), NStr("vi = 'Chọn dạng chứng từ';
																												|ru = 'Выбор типа документа';
																												|en = 'Select document type'; fa = 'Select document type';
																												|it = 'Selezione del tipo di documento';
																												|pl = 'Wybór typu dokumentu';
																												|tr = 'Belge türü seçimi'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OrdersListBeforeAddRowCompletion(SelectedElement, AdditionalParameters) Export
    
    ValueSelected = SelectedElement;
    
    If ValueSelected <> Undefined Then
        CreateNoteClient(ValueSelected.Value)
    EndIf;

EndProcedure

&AtClient
Procedure OrdersListOnActivateRow(Item)
	
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateGoodsSurplusNote(Command)
	
	CreateNoteClient(Type("DocumentRef.GoodsSurplusesNote"));
	
EndProcedure

&AtClient
Procedure CreateGoodsShortageNote(Command)
	
	CreateNoteClient(Type("DocumentRef.GoodsShortageNote"));
	
EndProcedure

&AtClient
Procedure CreateAGoodsMisgradingNote(Command)
	
	CreateNoteClient(Type("DocumentRef.GoodsMisgradingNote"));
	
EndProcedure

&AtClient
Procedure CreateADamageNote(Command)
	
	CreateNoteClient(Type("DocumentRef.DamageNote"));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.OrdersList);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.OrdersList, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.OrdersList);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
	If WarehousesServer.UseWarerooms(Warehouse) Then
		Items.GroupRoom.CurrentPage = Items.PageWareroom;
	Else
		Items.GroupRoom.CurrentPage = Items.BlankPage;
	EndIf;
	
	UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
	
	CommonClientServer.SetDynamicListFilterItem(OrdersList, "Warehouse",Warehouse, DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(OrdersList, "Premise",Premise, DataCompositionComparisonType.Equal,,True);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.GoodsSurplusesNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsShortageNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsMisgradingNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.DamageNote.EmptyRef"));
	Return BarcodingOfPrintFormsClient.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	ReferencesArrray = LinkToListItemByBarcode(Data.Barcode);
	If ReferencesArrray.Count() > 0 Then
		
		Ref = ReferencesArrray[0];
		Items.List.CurrentRow = Ref;
		
		ShowValue(Undefined, Ref);
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNoteClient(Type)
	Basis = New Structure;
	Basis.Insert("Warehouse", Warehouse);
	Basis.Insert("Premise", Premise);
	
	If Type = Type("DocumentRef.GoodsSurplusesNote") Then
		OpenForm("Document.GoodsSurplusesNote.ObjectForm",New Structure("Basis",Basis));
	ElsIf Type = Type("DocumentRef.GoodsShortageNote") Then
		OpenForm("Document.GoodsShortageNote.ObjectForm",New Structure("Basis",Basis));
	ElsIf Type = Type("DocumentRef.GoodsMisgradingNote") Then
		OpenForm("Document.GoodsMisgradingNote.ObjectForm",New Structure("Basis",Basis));
	ElsIf Type = Type("DocumentRef.DamageNote") Then
		OpenForm("Document.DamageNote.ObjectForm",New Structure("Basis",Basis));
	EndIf;
	
EndProcedure

#EndRegion

#Region BackgroundTaskForCreatingAdjustments

&AtServer
Procedure StartCreatingAdjustments()
	
	HasError = WarehousesServer.GenerateAdjustmentsForSurplusShortagesByProductLocationsForAllWarehousePremises(Warehouse);
	
	Items.StateOfAutomaticAdjustmentGeneration.Visible = HasError;
	
EndProcedure

&AtClient
Procedure MonitoringOperationOfBackgroundQueueFormationTasks()
		
	MonitoringOperationOfBackgroundQueueGenerationTasksOnServer();
			
EndProcedure

&AtServer
Procedure MonitoringOperationOfBackgroundQueueGenerationTasksOnServer()
		
	Items.StateOfAutomaticAdjustmentGeneration.Visible = 
		WarehousesServer.ThereArePremisesForWhichThereIsNoBackgroundTaskForFormationOfAdjustmentsForSurplusShortagesInCommodityPlaces(Warehouse);
				
EndProcedure

&AtClient
Procedure EnableWaitingHandlerForMonitoringOperationOfBackgroundJobsFormingQueue()
	
	If Not UseBinLocationWarehousing Then
		Items.StateOfAutomaticAdjustmentGeneration.Visible = False;
		DetachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks");
		Return;
	EndIf; 
	
	MonitoringOperationOfBackgroundQueueFormationTasks();
	AttachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks", 600);
	
EndProcedure

#EndRegion

#EndRegion
