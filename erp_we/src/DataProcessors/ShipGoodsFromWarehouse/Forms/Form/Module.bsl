#Region Variables

&AtClient
Var CurOrders; //used to pass parameters to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetConditionalAppearance();
	
	TMCommonUse.CustomizePeripherals(ThisForm,"ShipmentPanelAutomaticCreation,ShipmentPanel");
	
	FillDefaultWarehouse();
	
	DateOfShipment = CurrentSessionDate();
	SelectionState = "";
	
	SetColumnHeadersWeightVolume();
	
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	If QuickFilterStructure <> Undefined Then
		
		QuickFilterStructure.Property("Warehouse", Warehouse);
		QuickFilterStructure.Property("FilterReferences", FilterReferences);
		
	EndIf;
	
	SetSelectionsInMainLists();
	SetVisibilityOfPremises();
	
	UsePackingLists = GetFunctionalOption("UsePackingLists");
	GoodsIssueNoteGenerationMode = Constants.GoodsIssueNoteGenerationMode.Get();
	AutomaticallyCreateGoodsIssueNotes = GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically;
	GoodsIssueNoteCreationIsAvailable = GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.ByWarehouseman;
	
	WarehouseSpaceWhenServerChanges();	
	SetVisibilityCreateSpendingOrdersNotAvailable(); 
	
	
	// StandardSubsystems.AttachableCommands
	TypesList = NotesInProgress.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.OrderInTheGroupCommandPanelToChange;
	PlacementParameters.GroupsPrefix = "NotesInProgress";
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
		
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("UpdateStatesOfSelectionOrdersClient",120);
	If AutomaticallyCreateGoodsIssueNotes Then
		MonitoringOperationOfBackgroundQueueFormationTasks();
		AttachIdleHandler("MonitoringOperationOfBackgroundQueueFormationTasks", 300);
	EndIf;
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	

	SetSelectionsInDependentLists(CurOrders());

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
	
	
	If EventName = "ChangingList_OrdersInProgress"
		Or EventName = "ChangingListOf_TasksInProgress"
		Or EventName = "Write_Trip"
		Or EventName = "Write_ReturnOfGoodsToVendor"
		Or EventName = "Write_InventoryTransfer"
		Or EventName = "Write_CustomerInvoice"
		Or EventName = "Write_AssemblyFromComponents"
		Or EventName = "Write_InventoryConsumption"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Write_GoodsTransferNote"
		Or EventName = "Write_RequestForReturnOfGoodsFromCustomer"
		Or EventName = "Write_ByAssemblyDisassemblyOrder"
		Or EventName = "Write_TransferOrder"
		Or EventName = "Write_SalesOrder"
		Or EventName = "Write_InventoryConsumptionOrder"
		Or EventName = "Write_ProductionOrder"
		Or EventName = "Write_RMOrder"
		Or EventName = "Write_MaterialProviderOrder2_5"
		Or EventName = "Write_GoodsShipmentFromStorage"
		Or EventName = "Write_OrderOfMaterialsForProduction"
		Or EventName = "Write_SubcontractOrder2_5"
		Or EventName = "Write_MaterialTransferToProduction"
		Then
		NotificationProcessingServer(EventName,CurOrders());
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	TMCommonUse.ClearFormSettingsOrDetailsFromNonexistentLinks(Settings);
	
	GettingInventoryFromSettings =
		Warehouse = Settings.Get("Warehouse")
		Or GetFunctionalOption("UseSeveralWarehouses");
	
	If GettingInventoryFromSettings Then
		If QuickFilterStructure = Undefined Then
			Warehouse 		  = Settings.Get("Warehouse");
			Premise 	  = Settings.Get("Premise");
			ShippingZone  = Settings.Get("ShippingZone");
		Else
			
			If Not QuickFilterStructure.Property("Warehouse") Then
				Warehouse = Settings.Get("Warehouse");
			EndIf;
			
			If Not QuickFilterStructure.Property("Premise") Then
				Premise = Settings.Get("Premise");
			EndIf;
			
			If Not QuickFilterStructure.Property("ShippingZone") Then
				ShippingZone = Settings.Get("ShippingZone");
			EndIf;
			
		EndIf;
	EndIf;
	
	FilterJobs = Settings.Get("FilterJobs");
	FilterNotes = Settings.Get("FilterNotes");
	
	// We have already downloaded these settings
	Settings.Delete("Warehouse");
	Settings.Delete("Premise");
	Settings.Delete("ShippingZone");
	Settings.Delete("FilterJobs");
	Settings.Delete("FilterNotes");
		
	WarehouseSpaceWhenServerChanges();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PremiseOnChange(Item)
	WarehouseSpaceWhenServerChanges();
	SetSelectionsInDependentLists(CurOrders());
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.ShipGoodsFromWarehouse.Form.Item.Warehouse.OnChange");
	
	ShowDetailsShipment = False;
	WarehouseSpaceWhenServerChanges();
	SetSelectionsInDependentLists(CurOrders());
	MonitoringOperationOfBackgroundQueueFormationTasks();
EndProcedure

&AtClient
Procedure DateOfShipmentOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOfShipmentOnChangeServer();
	SetSelectionsInDependentLists(CurOrders());
EndProcedure

&AtClient
Procedure TheConditionOfTheShipmentWhenYouChange(Item)
		
	SetSelectionsInMainLists();
	SetSelectionsInDependentLists(CurOrders());
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	UpdateStatesOfSelectionOrdersClient();
	GroupPagesOnCurrentPageChangeServer(CurOrders(), CurrentPage.Name);
EndProcedure

&AtClient
Procedure FilterNotesOnChange(Item)
	SetSelectionsInDependentLists(CurOrders());
EndProcedure

&AtClient
Procedure FilterJobsOnChange(Item)
	FilterNotesOnChange(CurOrders());
EndProcedure

&AtClient
Procedure ProblemWithBackgroundTasksURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	
	If Var_URL = "StartOrderFormation" Then
		ClearMessages();
		StartOrderFormation();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersShipmentReferences

&AtClient
Procedure ShipmentReferencesOnActivateRow(Item)
	CurOrders = CurOrders();
	
	AttachIdleHandler("MainListWhenActivatingClientLine",0.2,True);
EndProcedure

&AtClient
Procedure ShipmentReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If (TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.TransportationJob")
			Or TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.Trip"))
		And Field <> Items.ShipmentReferencesState Then
		
		If Field = Items.ShipmentOrdersOrderNumber
			And Not ShowDetailsShipment Then
			
			ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
			
		Else
			
			CurrentTransportationJobShipment = Item.CurrentData.ReferenceOrder;
			ShowDetailsShipment = Not ShowDetailsShipment;
			
			SetSelectionsInMainLists();
			SetSelectionsInDependentLists(CurOrders());
			
		EndIf;
		
	ElsIf Field = Items.ShipmentReferencesState Then
		
		If TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.TransportationJob") Then
			
			Filter = New Structure("Warehouse, TransportationJob", Warehouse, Item.CurrentData.ReferenceOrder);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", Filter);
			FormParameters.Insert("PurposeUseKey", "AssemblingGoodsInWarehouseContext");
			FormParameters.Insert("VariantKey", "AssemblingGoodsInWarehouseContext");
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.GoodsForIssue.Form",
				FormParameters,
				ThisForm);
				
		ElsIf TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.Trip") Then
			
			Trip = Item.CurrentData.ReferenceOrder;
			ReportVariant = VersionOfReportKitsAccordingToTripOrders(Trip);
			
			OpeningParameters = New Structure;
			OpeningParameters.Insert("CommandParameter", Trip);
			OpeningParameters.Insert("ReportOptionsCommandsVisibility", False);
			
			If ValueIsFilled(ReportVariant) Then
				
				ReportsOptionsClient.OpenReportForm(ThisObject, ReportVariant, OpeningParameters);
				
			EndIf;
			
		Else
			
			Filter = New Structure("Warehouse, DocumentShipments", Warehouse, Item.CurrentData.ReferenceOrder);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", Filter);
			FormParameters.Insert("PurposeUseKey", "AssemblingGoodsInWarehouseContext");
			FormParameters.Insert("VariantKey", "AssemblingGoodsInWarehouseContext");
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.GoodsForIssue.Form",
				FormParameters,
				ThisForm);
				
		EndIf;
			
	Else
		ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure ShipmentOrdersOrderNumberClick(Item, StandardProcessing)
	ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
EndProcedure

&AtClient
Procedure ShipmentReferencesBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ShipmentReferencesBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPickingReferences

&AtClient
Procedure PickingReferencesOnActivateRow(Item)
	CurOrders = CurOrders();
	
	AttachIdleHandler("MainListWhenActivatingClientLine",0.2,True);
EndProcedure

&AtClient
Procedure PickingReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If (TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.TransportationJob")
			Or TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.Trip"))
		And Field <> Items.PickingReferencesState Then
		If Field = Items.PickingReferencesNumber
			And Not ShowDetailsShipment Then
			ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
		Else
			CurrentTransportationJobFilter = Item.CurrentData.ReferenceOrder;
			ShowDetailsFilter = Not ShowDetailsFilter;
			UpdateStatesOfSelectionOrders();
		EndIf;
		
	ElsIf Field = Items.PickingReferencesState Then
		
		If TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.TransportationJob") Then
			
			Filter = New Structure("TransportationJob", Item.CurrentData.ReferenceOrder);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", Filter);
			FormParameters.Insert("PurposeUseKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("VariantKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.GoodsForPicking.Form",
				FormParameters,
				ThisForm);
			
		ElsIf TypeOf(Item.CurrentData.ReferenceOrder) = Type("DocumentRef.Trip") Then
			
			Trip = Item.CurrentData.ReferenceOrder;
			GoodsIssueNotes = FlightExpenseOrders(Trip, Warehouse);
			
			Filter = New Structure("ReferenceOrder", GoodsIssueNotes);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", Filter);
			FormParameters.Insert("PurposeUseKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("VariantKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.GoodsForPicking.Form", FormParameters, ThisObject);
			
		Else
			
			Filter = New Structure("ReferenceOrder", Item.CurrentData.ReferenceOrder);
			
			FormParameters = New Structure;
			FormParameters.Insert("Filter", Filter);
			FormParameters.Insert("PurposeUseKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("VariantKey", "PerformingSelectionOfGoodsByWarehouseContext");
			FormParameters.Insert("GenerateOnOpen", True);
			
			OpenForm("Report.GoodsForPicking.Form",
				FormParameters,
				ThisForm);
			
		EndIf;
		
	Else
		ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
	EndIf;
	
EndProcedure

&AtClient
Procedure PickingReferencesNumberClick(Item, StandardProcessing)
	ShowValue(Undefined, Item.CurrentData.ReferenceOrder);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNotesInProgress

&AtClient
Procedure NotesInProgressOnChange(Item)
	Notify("ChangingList_OrdersInProgress", New Structure);
	Notify("Write_GoodsIssueNote", New Structure);
EndProcedure

&AtClient
Procedure NotesInProgressOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersJobsInProgress

&AtClient
Procedure JobsInProgressOnChange(Item)
	Notify("ChangingListOf_TasksInProgress", New Structure);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreatePickingJobs(Command)
	CreateTasksOnClient();	
EndProcedure

&AtClient
Procedure CreateRepackagingJobs(Command)
	CreateTasksOnClient(True);	
EndProcedure

&AtClient
Procedure CreateNotes(Command)
	ClearMessages();
	Cancel = False;
	
	CheckWarehousePremises(Cancel);
		
	CreateNewFragment(Cancel);
EndProcedure

&AtClient
Procedure CreateNewFragment(Val Cancel)
	
	Var ParametersForm;
	
	If Not Cancel Then
		
		If UseBinLocationWarehousing Then
			AssignShippingArea = True;
			
			ParametersForm = New Structure;
			ParametersForm.Insert("Operation", "FormationOfOrdersAddressWarehouse");
			ParametersForm.Insert("Warehouse", Warehouse);
			ParametersForm.Insert("Premise", Premise);
			ParametersForm.Insert("UseWarerooms", UseWarerooms);
		Else
			ParametersForm = New Structure;
			ParametersForm.Insert("Operation", "FormationOfOrders");
			ParametersForm.Insert("Warehouse", Warehouse);
			ParametersForm.Insert("Premise", Premise);
			ParametersForm.Insert("UseWarerooms", UseWarerooms);
			
			AssignShippingArea = False;
		EndIf;
		
		OpenForm("DataProcessor.ShipGoodsFromWarehouse.Form.SettingsForm",ParametersForm,ThisForm,,,, New CallbackDescription("CreateNotesCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;

EndProcedure

&AtClient
Procedure CreateNotesCompletion(Result, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.ShipGoodsFromWarehouse.Form.Notification.CreateNotesCompletion");
	
    Response = Result;
    
    If Response = DialogReturnCode.OK Then
        CreateNotesServer();
    EndIf;

EndProcedure

&AtClient
Procedure AssignShippingArea(Command)
	ClearMessages();
	Cancel = False;
	
	CheckWarehousePremises(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ParametersForm = New Structure("Operation, Warehouse, Premise", "SelectingShippingZone", Warehouse, Premise);
	Response = Undefined;
	
	OpenForm("DataProcessor.ShipGoodsFromWarehouse.Form.SettingsForm",ParametersForm,ThisForm,,,, New CallbackDescription("AssignShippingAreaCompletion", ThisObject, New Structure("DocumentsArray", DocumentsArray)), FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure AssignShippingAreaCompletion(Result, AdditionalParameters) Export
    
    DocumentsArray = AdditionalParameters.DocumentsArray;
    
    
    Response = Result;
    
    If Response <> DialogReturnCode.OK Then
        Return;
    EndIf;
    
    ArrayOfChangedDocuments = SetShippingZonesServer(DocumentsArray);
    
    If ArrayOfChangedDocuments.Count() > 0 Then
        
        MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% trong số %TotalCount1% các phiếu xuất hàng đã chọn trong danh sách có ấn định khu vực giao hàng ""Khu vực giao hàng""';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке ордеров на отгрузку товаров назначена зона отгрузки ""Зона отгрузки""';
							|en = 'Outbound area ""Outbound area"" is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes'; fa = 'Outbound area ""Outbound area"" is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes';
							|it = 'Per %ProcessedItemsCount% da %TotalCount1% dei mandati selezionati nell''elenco per la spedizione delle merci, viene assegnata l''area di spedizione ""Area di spedizione""';
							|pl = 'Dla %ProcessedItemsCount% z %TotalCount1% wybranych w liście zleceń do wysyłki towarów wyznaczono strefę wysyłki ""Strefa wysyłki""';
							|tr = 'Ürün sevkiyatı %ProcessedItemsCount% için %TotalCount1% listede seçilen siparişlerden, sevkiyat  alanı ""Yükleme alanı"" atanır'");
        MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ArrayOfChangedDocuments.Count());
        MessageText = StrReplace(MessageText, "%TotalCount1%",        DocumentsArray.Count());
        MessageText = StrReplace(MessageText, "%ShippingZone%",           ShippingZone);
        
        TitleText = NStr("vi = 'Khu vực giao hàng ""%ShippingZone%"" được ấn định';
						|ru = 'Зона отгрузки ""%ShippingZone%"" назначена';
						|en = 'Outbound area ""%ShippingZone%"" is assigned'; fa = 'Outbound area ""%ShippingZone%"" is assigned';
						|it = 'Area di spedizione ""%ShippingZone%"" assegnata';
						|pl = 'Strefa wysyłki ""%ShippingZone%"" została wyznaczona';
						|tr = 'Yükleme alanı ""%ShippingZone%"" atandı'");
        TitleText = StrReplace(TitleText, "%ShippingZone%", ShippingZone);
        ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
        
    Else
        
        MessageText = NStr("vi = 'Chưa ấn định khu vực giao hàng ""%ShippingZone%"" đối với bất kỳ phiếu giao hàng nào';
							|ru = 'Зона отгрузки ""%ShippingZone%"" не назначена ни для одного ордере на отгрузку товаров';
							|en = 'Outbound area ""%ShippingZone%"" is not assigned to any goods issue note'; fa = 'Outbound area ""%ShippingZone%"" is not assigned to any goods issue note';
							|it = 'Area di spedizione ""%ShippingZone%"" non è assegnata per alcun mandato di spedizione delle merci';
							|pl = 'Strefa wysyłki ""%ShippingZone%"" nie została wyznaczona dla żadnego zlecenia do wysyki towarów';
							|tr = 'Sevkiyat bölgesi ""%ShippingZone%"" herhangi bir sevkiyat siparişine atanmadı'");
        MessageText = StrReplace(MessageText, "%ShippingZone%",                 ShippingZone);
        
        TitleText = NStr("vi = 'Chưa ấn định khu vực giao hàng ""%ShippingZone%""';
						|ru = 'Зона отгрузки ""%ShippingZone%"" не назначена';
						|en = 'Outbound area ""%ShippingZone%"" is not assigned'; fa = 'Outbound area ""%ShippingZone%"" is not assigned';
						|it = 'Area di spedizione ""%ShippingZone%"" non è assegnata';
						|pl = 'Strefa wysyłki ""%ShippingZone%"" nie została wyznaczona';
						|tr = 'Yükleme alanı ""%ShippingZone%"" atanmadı'");
        TitleText = StrReplace(TitleText, "%ShippingZone%", ShippingZone);
        ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
        
    EndIf;

EndProcedure

&AtClient
Procedure AssignTransportationJob(Command)
	
	ClearMessages();
	
	Orders_3 					= New Array;
	DocumentsArray 		= New Array;
	RawStrings 	= New Array;
	
	OrdersList 		= Items.NotesInProgress;
	SelectedRows 	= TMCommonUseClient.CheckGetLinksHighlightedInList(OrdersList);
	
	For Each SelectedRow In SelectedRows Do
		OrdersString = OrdersList.RowData(SelectedRow);
		
		If Not OrdersString.ShipmentUnderTransportationJob
			Or TypeOf(SelectedRow) <> Type("DocumentRef.GoodsIssueNote") Then
			
			RowParameters = New Structure("Ref, ShipmentUnderTransportationJob");
			FillPropertyValues(RowParameters, OrdersString);
			
			RawStrings.Add(RowParameters);
			
		Else
			RowParameters = New Structure("Ref, Status");
			FillPropertyValues(RowParameters, OrdersString);
			
			Orders_3.Add(RowParameters);
			DocumentsArray.Add(SelectedRow);
		EndIf;
	EndDo;
	
	If DocumentsArray.Count() = 0 Then
		NotifyUsAboutErrorsInTransportTaskSelection(RawStrings);
		Return;
	ElsIf DocumentsArray.Count() = 1 Then
		FormParameters = New Structure("WarehouseDocument", DocumentsArray[0]);
	Else
		FormParameters = New Structure("Orders_3, Warehouse", DocumentsArray, Warehouse);
	EndIf;
	
	AdditionalParameters = New Structure("Orders_3, UnprocessedOrders", Orders_3, RawStrings);
	CallbackDescription = New CallbackDescription(
		"AssignTransportationJobCompletion",
		ThisObject,
		AdditionalParameters);
	
	OpenForm("Document.GoodsIssueNote.Form.TransportationJobChoiceForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure AssignTransportationJobCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		AssignTransportationJobServer(Result, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignShipmentPriority(Command)
	ClearMessages();
		
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
			
	ParametersForm = New Structure;
	ParametersForm.Insert("Title", NStr("vi = 'Hãy chọn ưu tiên giao hàng';
										|ru = 'Выберите приоритет отгрузки';
										|en = 'Select shipment priority'; fa = 'Select shipment priority';
										|it = 'Selezionare la priorità di spedizione';
										|pl = 'Wybierz priotytet wysyłki';
										|tr = 'Sevkiyat önceliğini seç'"));
	
	Priority = Undefined;

	
	OpenForm("Catalog.Priorities.ChoiceForm",ParametersForm,ThisForm,,,, New CallbackDescription("AssignShipmentPriorityCompletion", ThisObject, New Structure("DocumentsArray", DocumentsArray)), FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure AssignShipmentPriorityCompletion(Result, AdditionalParameters) Export
    
    DocumentsArray = AdditionalParameters.DocumentsArray;
    
    
    Priority = Result;
    
    If Not ValueIsFilled(Priority) Then
        Return;
    EndIf;
    
    ArrayOfChangedDocuments = AssignShipmentPriorityServer(DocumentsArray, Priority);
    
    If ArrayOfChangedDocuments.Count() > 0 Then
        
        MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% từ %TotalCount1% của các phiếu giao hàng đã chọn trong danh sách ấn định mức ưu tiên giao hàng ""%Priority%""';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке ордеров на отгрузку товаров назначен приоритет отгрузки ""%Priority%""';
							|en = 'Shipment priority ""%Priority%"" is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes'; fa = 'Shipment priority ""%Priority%"" is assigned for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes';
							|it = 'Per %ProcessedItemsCount% da %TotalCount1% dei mandati selezionati nell''elenco per la spedizione delle merci, viene assegnata la priorità della spedizione ""%Priority%""';
							|pl = 'Dla %ProcessedItemsCount% z %TotalCount1% wybranych zleceń do wysyłki towarów jest wyznaczony priorytet wysyłki ""%Priority%""';
							|tr = 'Listede seçilen ürünlerin sevkiyatı %ProcessedItemsCount% için %TotalCount1% siparişlere sevkiyat önceliği ""%Priority%"" atanır'");
        MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ArrayOfChangedDocuments.Count());
        MessageText = StrReplace(MessageText, "%TotalCount1%",        DocumentsArray.Count());
        MessageText = StrReplace(MessageText, "%Priority%",              Priority);
        
        TitleText = NStr("vi = 'Chưa ấn định mức ưu tiên giao hàng ""%Priority%""';
						|ru = 'Приоритет отгрузки ""%Priority%"" назначен';
						|en = 'Shipment priority ""%Priority%"" is assigned'; fa = 'Shipment priority ""%Priority%"" is assigned';
						|it = 'La priorità della spedizione ""%Priority%"" è assegnata';
						|pl = 'Priorytet wysyłki ""%Priority%"" został wyznaczony';
						|tr = 'Sevkiyat önceliği ""%Priority%"" atandı'");
        TitleText = StrReplace(TitleText, "%Priority%", Priority);
        ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
        
    Else
        
        MessageText = NStr("vi = 'Chưa ấn định mức ưu tiên giao hàng ""%Priority%"" đối với bất kỳ phiếu xuất kho nào';
							|ru = 'Приоритет отгрузки ""%Priority%"" не назначен ни для одного ордера на отгрузку товаров';
							|en = 'Shipment priority ""%Priority%"" is not assigned to any goods issue note'; fa = 'Shipment priority ""%Priority%"" is not assigned to any goods issue note';
							|it = 'La priorità di spedizione ""%Priority%"" non è assegnata per alcun mandato di spedizione delle merci';
							|pl = 'Priorytet wysyłki ""%Priority%"" nie został wyznaczona dla żadnego zleenia do wysyłki towarów';
							|tr = 'Sevkiyat önceliği ""%Priority%"" herhangi bir sevkiyat siparişine atanmadı'");
        MessageText = StrReplace(MessageText, "%Priority%", Priority);
        
        TitleText = NStr("vi = 'Chưa ấn định mức ưu tiên ""%Priority%""';
						|ru = 'Приоритет ""%Priority%"" не назначена';
						|en = 'Priority ""%Priority%"" is not assigned'; fa = 'Priority ""%Priority%"" is not assigned';
						|it = 'La priorità ""%Priority%"" non è assegnata';
						|pl = 'Priorytet ""%Priority%"" nie został wyznaczony';
						|tr = 'Öncelik ""%Priority%"" atanmadı'");
        TitleText = StrReplace(TitleText, "%Priority%", Priority);
        ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
        
    EndIf;

EndProcedure

&AtClient
Procedure NotesShip(Command)
	ClearMessages();
		
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = ChangeServerStatusOrders(DocumentsArray,"Shipped_");
	
	If ArrayOfChangedDocuments.Count() Then
		Notify("Write_GoodsIssueNote", New Structure);
	EndIf;
	
	NotifyUserAboutSettingOrderStatus(ArrayOfChangedDocuments.Count(), DocumentsArray.Count(),
													PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_"));
	
EndProcedure

&AtClient
Procedure NotesToShip(Command)
	ClearMessages();
	
	If Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.GroupShipment Then
		DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	Else
		DocumentsArray = New Array;
		RowsArray      = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.PickingReferences);
		For Each ArrRow In RowsArray Do
			If TypeOf(Items.PickingReferences.RowData(ArrRow).ReferenceOrder) <> Type("DocumentRef.TransportationJob") Then
				DocumentsArray.Add(Items.PickingReferences.RowData(ArrRow).ReferenceOrder);
			EndIf;
		EndDo;
	EndIf;
	
	If DocumentsArray.Count() = 0 Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = ChangeServerStatusOrders(DocumentsArray,"ToShip");
	
	If ArrayOfChangedDocuments.Count() > 0 Then
		If ShowDetailsFilter And PickingReferences.Count() <= 1 Then
			ShowDetailsFilter = False; // there are no more orders in the "For selection" status for the shipment task
		EndIf;
		UpdateStatesOfSelectionOrders();
		SetSelectionsInDependentLists(CurOrders());
	EndIf;
	
	NotifyUserAboutSettingOrderStatus(ArrayOfChangedDocuments.Count(), DocumentsArray.Count(),
													PredefinedValue("Enum.GoodsIssueNoteStatuses.ToShip"));
	
EndProcedure

&AtClient
Procedure NotesToCheck(Command)
	ClearMessages();
	
	If Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.GroupShipment Then
		DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	Else
		DocumentsArray = New Array;
		RowsArray      = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.PickingReferences);
		For Each ArrRow In RowsArray Do
			If TypeOf(Items.PickingReferences.RowData(ArrRow).ReferenceOrder) <> Type("DocumentRef.TransportationJob") Then
				DocumentsArray.Add(Items.PickingReferences.RowData(ArrRow).ReferenceOrder);
			EndIf;
		EndDo;
	EndIf;
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = ChangeServerStatusOrders(DocumentsArray,"ForChecking");
	
	If ArrayOfChangedDocuments.Count() > 0 Then
		If ShowDetailsFilter And PickingReferences.Count() <= 1 Then
			ShowDetailsFilter = False; // there are no more orders in the "For selection" status for the shipment task
		EndIf;
		UpdateStatesOfSelectionOrders();
    	SetSelectionsInDependentLists(CurOrders());
	EndIf;
	
	NotifyUserAboutSettingOrderStatus(ArrayOfChangedDocuments.Count(), DocumentsArray.Count(),
													PredefinedValue("Enum.GoodsIssueNoteStatuses.ForChecking"));
	
EndProcedure

&AtClient
Procedure NotesToFilter(Command)
	ClearMessages();
		
	DocumentsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.NotesInProgress);
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = ChangeServerStatusOrders(DocumentsArray,"ForPicking");
	
	NotifyUserAboutSettingOrderStatus(ArrayOfChangedDocuments.Count(), DocumentsArray.Count(),
													PredefinedValue("Enum.GoodsIssueNoteStatuses.ForPicking"));
EndProcedure

&AtClient
Procedure TakeUpTheJobs(Command)
	
	Notification = New CallbackDescription("TakeUpTheJobsCompletion", ThisObject);
	
	WarehousesClient.TakeUpTheJobs(ThisForm, Items.JobsInProgress , "ShipGoodsFromWarehouse", Notification);
	
EndProcedure

&AtClient
Procedure TakeUpTheJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInMainLists();

EndProcedure

&AtClient
Procedure CompleteJobs(Command)
	
	Notification = New CallbackDescription("CompleteJobsCompletion", ThisObject);
	
	WarehousesClient.MarkCompletionOfTasksWithoutErrors(ThisForm, Items.JobsInProgress, "ShipGoodsFromWarehouse", Notification);
	
EndProcedure

&AtClient
Procedure CompleteJobsCompletion(Result, AdditionalParameters) Export
	
	SetSelectionsInMainLists();

EndProcedure

&AtClient
Procedure UpdatedList_4(Command)
	SetSelectionsInMainLists();
	SetSelectionsInDependentLists(CurOrders());
EndProcedure

&AtClient
Procedure AssemblyStateReport(Command)
	
	Filter = New Structure("Warehouse", Warehouse);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("PurposeUseKey", "AssemblingGoodsInWarehouseContext");
	FormParameters.Insert("VariantKey", "AssemblingGoodsInWarehouseContext");
	FormParameters.Insert("GenerateOnOpen", "True");
	
	OpenForm("Report.GoodsForIssue.Form",
				FormParameters,
				ThisForm);
EndProcedure

&AtClient
Procedure CreateTransferNote(Command)
	
	Basis = New Structure;
	Basis.Insert("Warehouse", Warehouse);
	Basis.Insert("SenderWareroom", Premise);
	
	OpenForm("Document.GoodsTransferNote.Form.DocumentForm",New Structure("Basis",Basis));
	
EndProcedure

&AtClient
Procedure VerifyQuantity(Command)
	If Items.NotesInProgress.CurrentData <> Undefined Then
		
		If Not Items.NotesInProgress.CurrentData.Property("Ref") Then
			MessageText = NStr("vi = 'Thao tác không được phép đối với dòng gom nhóm danh sách.';
								|ru = 'Действие недоступно для строки группировки списка.';
								|en = 'The action is not available for the list grouping row.'; fa = 'The action is not available for the list grouping row.';
								|it = 'L''azione non è disponibile per la riga di raggruppamento dell''elenco.';
								|pl = 'Działanie nie jest dostępne dla wiersza grupowania listy.';
								|tr = 'Eylem, liste gruplama satırı için mevcut değildir.'");
			                        			
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
		
		CurrentData = Items.NotesInProgress.CurrentData;
		
		ThisIsSpendingOrder = (TypeOf(CurrentData.Ref) = Type("DocumentRef.GoodsIssueNote"));
		UsePackingListsForDocument = UsePackingLists;
		
		If ThisIsSpendingOrder And UsePackingLists Then
			UsePackingListsForDocument = Not ThereAreLabeledProductsServer(CurrentData.Ref);
		EndIf;
		
		If ThisIsSpendingOrder
			And UsePackingListsForDocument Then
			Action = NStr("vi = 'Kiểm tra số lượng và đóng gói';
							|ru = 'Проверка количества и упаковка';
							|en = 'Quantity check and packaging unit'; fa = 'Quantity check and packaging unit';
							|it = 'Controllo di quantità e imballaggio';
							|pl = 'Weryfikacja ilości i opakowanie';
							|tr = 'Miktar ve paketleme ünitesi kontrolü'");
		Else
			Action = NStr("vi = 'Kiểm tra số lượng';
							|ru = 'Проверка количества';
							|en = 'Check quantity'; fa = 'Check quantity';
							|it = 'Controllo di quantità';
							|pl = 'Weryfikacja ilości';
							|tr = 'Miktar kontrolü'");
		EndIf;
		
		HeaderParameter_ = NStr("vi = '%CheckPackaging% hàng hóa trong chứng từ %Document%';
								|ru = '%CheckPackaging% товаров в документе %Document%';
								|en = '%CheckPackaging% of goods in the %Document% document'; fa = '%CheckPackaging% of goods in the %Document% document';
								|it = '%CheckPackaging% delle merci nel documento %Document%';
								|pl = '%CheckPackaging% towarów w dokumencie %Document%';
								|tr = '%CheckPackaging% belgedeki ürünler %Document%'");
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", CurrentData.Ref);
		HeaderParameter_ = StrReplace(HeaderParameter_, "%CheckPackaging%", Action);
		
		FormParameters = New Structure;
		FormParameters.Insert("Title", HeaderParameter_);
		FormParameters.Insert("WarehouseDocument", CurrentData.Ref);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("UsePackingLists", UsePackingListsForDocument);
		
		OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.Form", FormParameters, ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure CorrectQuantity(Command)
	If Items.NotesInProgress.CurrentData <> Undefined Then
		
		If Not Items.NotesInProgress.CurrentData.Property("Ref") Then
			MessageText = NStr("vi = 'Thao tác không được phép đối với dòng gom nhóm danh sách.';
								|ru = 'Действие недоступно для строки группировки списка.';
								|en = 'The action is not available for the list grouping row.'; fa = 'The action is not available for the list grouping row.';
								|it = 'L''azione non è disponibile per la riga di raggruppamento dell''elenco.';
								|pl = 'Działanie nie jest dostępne dla wiersza grupowania listy.';
								|tr = 'Eylem, liste gruplama satırı için mevcut değildir.'");
			
			ShowMessageBox(Undefined, MessageText);
			Return;
		EndIf;
		
		CurrentData = Items.NotesInProgress.CurrentData;
		
		ThisIsSpendingOrder = (TypeOf(CurrentData.Ref) = Type("DocumentRef.GoodsIssueNote"));
		UsePackingListsForDocument = UsePackingLists;
		
		If ThisIsSpendingOrder And UsePackingLists Then
			UsePackingListsForDocument = Not ThereAreLabeledProductsServer(CurrentData.Ref);
		EndIf;
		
		If ThisIsSpendingOrder
			And UsePackingListsForDocument Then
			Action = NStr("vi = 'Chỉnh sửa số lượng và đóng gói';
							|ru = 'Исправление количества и упаковка';
							|en = 'Quantity correction and packaging unit'; fa = 'Quantity correction and packaging unit';
							|it = 'Rettifica di quantità e imballaggio';
							|pl = 'Korekta ilości i opakowanie';
							|tr = 'Miktar düzeltmesi ve paketleme ünitesi'");
		Else
			Action = NStr("vi = 'Chỉnh sửa số lượng';
							|ru = 'Исправление количества';
							|en = 'Correct quantity'; fa = 'اصلاح مقدار';
							|it = 'Rettifica di quantità';
							|pl = 'Korekta ilości';
							|tr = 'Miktar düzeltmesi'");
		EndIf;
		
		HeaderParameter_ = NStr("vi = '%CorrectionPackaging% hàng hóa trong chứng từ %Document%';
								|ru = '%CorrectionPackaging% товаров в документе %Document%';
								|en = '%CorrectionPackaging% of goods in the %Document% document'; fa = '%CorrectionPackaging% of goods in the %Document% document';
								|it = '%CorrectionPackaging% delle merci nel documento %Document%';
								|pl = '%CorrectionPackaging% towarów w dokumencie %Document%';
								|tr = '%CorrectionPackaging% belgedeki ürünler %Document%'");
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", CurrentData.Ref);
		HeaderParameter_ = StrReplace(HeaderParameter_, "%CorrectionPackaging%", Action);
		
		Premise = ?(CurrentData.Property("SenderWareroom"), CurrentData.SenderWareroom, Undefined);
		
		FormParameters = New Structure;
		FormParameters.Insert("Title", HeaderParameter_);
		FormParameters.Insert("WarehouseDocument", CurrentData.Ref);
		FormParameters.Insert("Warehouse", Warehouse);
		FormParameters.Insert("Premise", Premise);
		FormParameters.Insert("CorrectionMode", True);
		FormParameters.Insert("UsePackingLists", UsePackingListsForDocument);
		
		OpenForm("DataProcessor.GoodsQuantityCheckInDocument.Form.Form", FormParameters, ThisForm);
	EndIf;
EndProcedure

&AtClient
Procedure UploadVTSDData(Command)
	
	FormParameters = New Structure("FillingVariant, OriginWarehouse, DateOfShipment", "ByShipmentReferences", Warehouse, DateOfShipment);
	OpenForm("DataProcessor.ExportGoodsDatabaseToPDT.Form", FormParameters);
	
EndProcedure

&AtClient
Procedure ReduceNotes(Command)
	ClearMessages();
	
	RowsArray = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.PickingReferences);
	DocumentsArray = New Array;
	For Each ArrRow In RowsArray Do
		DocumentsArray.Add(Items.PickingReferences.RowData(ArrRow).ReferenceOrder);	
	EndDo;
	
	If DocumentsArray.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfChangedDocuments = ReduceNotesServer(DocumentsArray);
	
	If ArrayOfChangedDocuments.Count() > 0 Then
		SetSelectionsInDependentLists(CurOrders());
		
		MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% / %TotalCount1% đã chọn trong danh sách lệnh lấy ra số lượng đã điền tương ứng với số lượng hàng hóa được lấy ra';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке распоряжений на отбор количество заполнено в соотвестии с количеством отобранных товаров';
							|en = 'Quantity is populated in accordance with the quantity of selected goods for %ProcessedItemsCount% out of %TotalCount1% selected in the list of picking references'; fa = 'Quantity is populated in accordance with the quantity of selected goods for %ProcessedItemsCount% out of %TotalCount1% selected in the list of picking references';
							|it = 'Per %ProcessedItemsCount% da %TotalCount1% mandati selezionati nell''elenco per la selezione, la quantità è compilata in base alla quantità dei prodotti selezionati';
							|pl = 'Dla %ProcessedItemsCount% z%TotalCount1% wybranych na liście zamówień do wyboru ilość wypełniono zgodnie z ilością wybranych towarów';
							|tr = '%ProcessedItemsCount% listesi için %TotalCount1% seçilen filtre siparişlerinde, seçilen ürün sayısına göre miktar doldurulur.'");
		MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ArrayOfChangedDocuments.Count());
		MessageText = StrReplace(MessageText, "%TotalCount1%",        DocumentsArray.Count());
		
		TitleText = NStr("vi = 'Điền phiếu theo hàng hóa đã chọn';
						|ru = 'Заполнение ордеров по отобранным товарам';
						|en = 'Fill in notes by selected goods'; fa = 'Fill in notes by selected goods';
						|it = 'Compilazione dei mandati per prodotti selezionati';
						|pl = 'Wypełnienie zleceń według dobranych towarów';
						|tr = 'Seçilen ürünler için sipariş doldurma'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	Else
		
		MessageText = NStr("vi = 'Số lượng hàng hóa chưa được điền lại trong bất kỳ lệnh lấy ra hàng hóa nào';
							|ru = 'Количество товаров не перезаполнялось ни в одном распоряжения на отбор товаров';
							|en = 'Quantity of goods was not refilled in any goods picking reference'; fa = 'Quantity of goods was not refilled in any goods picking reference';
							|it = 'La quantità delle merci non è stata ricompilata in alcun mandato per la selezione delle merci';
							|pl = 'Nie wypełniono ponownie ilości towarów w żadnym zamówieniu doboru towarów';
							|tr = 'Ürün filtresi için herhangi bir siparişte ürün miktarı yeniden doldurulmadı'");
		
		TitleText = NStr("vi = 'Điền phiếu từ hàng hóa đã chọn';
						|ru = 'Заполнение ордеров от отобранным товарам';
						|en = 'Fill in notes from selected goods'; fa = 'Fill in notes from selected goods';
						|it = 'Compilazione dei mandati per prodotti selezionati';
						|pl = 'Wypełnienie zleceń dobranymi towarami';
						|tr = 'Seçilen ürünlerden siparişlerin doldurulması'");
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.NotesInProgress);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.NotesInProgress, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.NotesInProgress);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
EndProcedure

#Region FillingAndInitialization

&AtServer
Procedure FillDefaultWarehouse()
	
	FillingStructure = New Structure("Warehouse");
	TMCommonUse.Filling(FillingStructure, Undefined, Undefined);
	Warehouse = FillingStructure.Warehouse;
	
	If Not ValueIsFilled(Warehouse) Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EndIf;
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.GoodsTransferNote.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsPickingPlacement.EmptyRef"));
	Managers.Add(PredefinedValue("Document.GoodsIssueNote.EmptyRef"));
	
	ReferencesArrray = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Barcode, Managers);
	
	If ReferencesArrray.Count() > 0 Then
		DocumentLink_ = ReferencesArrray[0];
		
		If TypeOf(DocumentLink_) = Type("DocumentRef.GoodsPickingPlacement")
			And Items.GroupPages.CurrentPage = Items.GroupShipment Then
			
			RefOfOrder = Common.ObjectAttributeValue(DocumentLink_, "ReferenceOrder");
			Items.NotesInProgress.CurrentRow = RefOfOrder;
			
			Return RefOfOrder;
			
		Else
			If TypeOf(DocumentLink_) = Type("DocumentRef.GoodsPickingPlacement") Then
				Items.JobsInProgress.CurrentRow = DocumentLink_;
			ElsIf Items.GroupPages.CurrentPage = Items.GroupFilter Then
				Items.PickingReferences.CurrentRow = DocumentLink_;
			Else
				Items.NotesInProgress.CurrentRow = DocumentLink_;
			EndIf;
			
			Return DocumentLink_;
		EndIf;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtClient
Procedure ProcessBarcodes(Data)
		
	If Not BarcodingOfItemsClient.BarcodesAreValid(Data) Then
		Return;
	EndIf;
	
	DocumentLink_ = LinkToListItemByBarcode(Data.Barcode);
	
	If DocumentLink_ <> Undefined Then
		ShowValue(Undefined, DocumentLink_);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Interface

&AtClient
Procedure MainListWhenActivatingClientLine()
	
	If CurrentPickingReference <> CurOrders.SelectionOrder_
	 Or TheCurrentOrderForShipment <> CurOrders.ShipmentReferenceOrder Then
		
		// Caching the selected lines
		SelectedLinesForShipment = New Array;
		For Each TableRow In Items.ShipmentReferences.SelectedRows Do
			TableRow = ShipmentReferences.FindByID(TableRow);
			If TableRow <> Undefined Then
				TableRow = TableRow.ReferenceOrder;
			EndIf;
			SelectedLinesForShipment.Add(TableRow);
		EndDo;
		
		SelectedRowsForSelection = New Array;
		For Each TableRow In Items.PickingReferences.SelectedRows Do
			TableRow = PickingReferences.FindByID(TableRow);
			If TableRow <> Undefined Then
				TableRow = TableRow.ReferenceOrder;
			EndIf;
			SelectedRowsForSelection.Add(TableRow);
		EndDo;
		
		SetSelectionsInDependentLists(CurOrders);
		
		// Restoring the selected lines
		TableRows = ShipmentReferences.FindRows(New Structure("ReferenceOrder", CurOrders.ShipmentReferenceOrder));
		If TableRows.Count() > 0 Then
			Items.ShipmentReferences.CurrentRow = TableRows[0].GetID();
		EndIf;
		
		Items.ShipmentReferences.SelectedRows.Clear();
		For Each TableRow In SelectedLinesForShipment Do
			TableRows = ShipmentReferences.FindRows(New Structure("ReferenceOrder", TableRow));
			If TableRows.Count() = 0 Then
				Continue;
			EndIf;
			Items.ShipmentReferences.SelectedRows.Add(TableRows[0].GetID());
		EndDo;
		
		TableRows = PickingReferences.FindRows(New Structure("ReferenceOrder", CurOrders.SelectionOrder_));
		If TableRows.Count() > 0 Then
			Items.PickingReferences.CurrentRow = TableRows[0].GetID();
		EndIf;
		
		Items.PickingReferences.SelectedRows.Clear();
		For Each TableRow In SelectedRowsForSelection Do
			TableRows = PickingReferences.FindRows(New Structure("ReferenceOrder", TableRow));
			If TableRows.Count() = 0 Then
				Continue;
			EndIf;
			Items.PickingReferences.SelectedRows.Add(TableRows[0].GetID());
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Function CurOrders()
	
	ReturnStructure = New Structure("SelectionOrder_, ShipmentReferenceOrder");
	
	If Items.ShipmentReferences.CurrentData <> Undefined Then
		ReturnStructure.ShipmentReferenceOrder = Items.ShipmentReferences.CurrentData.ReferenceOrder;
	EndIf;
	
	If Items.PickingReferences.CurrentData <> Undefined Then
		ReturnStructure.SelectionOrder_ = Items.PickingReferences.CurrentData.ReferenceOrder;
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

&AtServer
Procedure WarehouseSpaceWhenServerChanges()
		
	StructureOfSetParameters = New Structure;
	
	If ValueIsFilled(Warehouse) Then
		StructureOfSetParameters.Insert("Warehouse",Warehouse);
		StructureOfSetParameters.Insert("Premise",Premise);
		
		UseBinLocationWarehousing = WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise);
		
		If UseBinLocationWarehousing Then
			ShippingZone = Catalogs.StorageBins.DefaultShippingZone(Warehouse, Premise);
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Else
			Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		EndIf;
		
		SetPrivilegedMode(True);
		Items.NotesInProgressDeliveryProcedure.Visible = Common.ObjectAttributeValue(Warehouse, "StartShipmentOnceDeliveryOrderIsCreated");
		SetPrivilegedMode(False);
		
	Else
		StructureOfSetParameters.Insert("Warehouse",Undefined);
		StructureOfSetParameters.Insert("Premise",Undefined);
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
		UseBinLocationWarehousing = False;
	EndIf;	
	
	SetFormFunctionalOptionParameters(StructureOfSetParameters);
	UseGoodsIssueNoteStatuses = GetFunctionalOption("UseGoodsIssueNoteStatuses", 
																			New Structure("Warehouse", Warehouse));
																			
	Items.NotesInProgressStatus.Visible = UseGoodsIssueNoteStatuses;
	
	Items.State.ChoiceList.Clear();
	
	If UseGoodsIssueNoteStatuses Then
		Items.State.ChoiceList.Add("AllInProgress", NStr("vi = 'Tất cả đang làm việc';
														|ru = 'Все в работе';
														|en = 'All in progress'; fa = 'All in progress';
														|it = 'Tutto in esecuzione';
														|pl = 'Wszystkie w toku';
														|tr = 'Tümü işte'"));		
		Items.State.ChoiceList.Add("PendingPicking", NStr("vi = 'Lựa chọn chờ xử lý';
															|ru = 'Ожидается отбор';
															|en = 'Pending picking'; fa = 'در انتظار برداشت';
															|it = 'In attesa della selezione';
															|pl = 'Oczekuje się dobór';
															|tr = 'Filtre bekleniyor'"));
		Items.State.ChoiceList.Add("PendingShipment", NStr("vi = 'Đang chờ giao hàng';
															|ru = 'Ожидается отгрузка';
															|en = 'Pending shipment'; fa = 'در انتظار ارسال';
															|it = 'In attesa della spedizione';
															|pl = 'Oczekuje się wysyłka';
															|tr = 'Sevkiyat bekleniyor'"));		
		Items.State.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Trong Kỳ chờ giao hóa đơn';
																		|ru = 'Ожидается оформление накладных';
																		|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																		|it = 'È prevista l''emissione dei documenti di trasporto';
																		|pl = 'Oczekiwanie sporządzenia faktur';
																		|tr = 'İrsaliye düzenleme bekleniyor'"));
		Items.State.ChoiceList.Add("", NStr("vi = 'Tất cả';
											|ru = 'Все';
											|en = 'All'; fa = 'همه';
											|it = 'Tutti';
											|pl = 'Wszystkie';
											|tr = 'Tümü'"));
		ShipmentStatus = "AllInProgress";
	Else
		Items.State.ChoiceList.Add("PendingPicking", NStr("vi = 'Lựa chọn chờ xử lý';
															|ru = 'Ожидается отбор';
															|en = 'Pending picking'; fa = 'در انتظار برداشت';
															|it = 'In attesa della selezione';
															|pl = 'Oczekuje się dobór';
															|tr = 'Filtre bekleniyor'"));
		Items.State.ChoiceList.Add("PendingInvoiceRegistration", NStr("vi = 'Trong Kỳ chờ giao hóa đơn';
																		|ru = 'Ожидается оформление накладных';
																		|en = 'Pending invoice registration'; fa = 'در انتظار ثبت فاکتور';
																		|it = 'È prevista l''emissione dei documenti di trasporto';
																		|pl = 'Oczekiwanie sporządzenia faktur';
																		|tr = 'İrsaliye düzenleme bekleniyor'"));
		Items.State.ChoiceList.Add("", NStr("vi = 'Tất cả';
											|ru = 'Все';
											|en = 'All'; fa = 'همه';
											|it = 'Tutti';
											|pl = 'Wszystkie';
											|tr = 'Tümü'"));		
		ShipmentStatus = "PendingPicking";
	EndIf;
	
	WarehouseZone = Catalogs.WarehouseZones.EmptyRef();
	AssignShippingArea   = False;
	
	ShowHyperlinks = WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Warehouse);
	Items.ShipmentOrdersOrderNumber.CellHyperlink = ShowHyperlinks;
	Items.PickingReferencesNumber.CellHyperlink 			   = ShowHyperlinks;
	
	SetSelectionsInMainLists();
	
	FillOrderFilterSelectionList();
	SetVisibilityOfPremises();
		
EndProcedure

&AtServer
Procedure SetVisibilityCreateSpendingOrdersNotAvailable()
	
	If Not GoodsIssueNoteCreationIsAvailable Then	
		
		Items.ExpenseOrdersGroup.ShowTitle = False;
		Items.ExpenseOrdersGroup.Representation = UsualGroupRepresentation.None;
		Items.FilterNotes.Visible = False;
		
		Items.TheGroupSelectionCommandBarOrdersForShipment.Visible = False;
		Items.GroupOrdersForShipment.Visible = False;
		Items.GroupHeaderShipmentsExpenseOrders.Visible = True;
		Items.AutomaticallyCreateGoodsIssueNotes.Visible = AutomaticallyCreateGoodsIssueNotes;
		Items.CustomizeForm2.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure GroupPagesOnCurrentPageChangeServer(CurOrders, CurrentPageName);
	
	CurrentPage = Items[CurrentPageName];
	
	If CurrentPage = Items.GroupShipment Then
		Items.Warehouse.Enabled = True;
		Items.Premise.Enabled = True;
	ElsIf CurrentPage = Items.GroupFilter Then
		Items.Warehouse.Enabled = False;
		Items.Premise.Enabled = False;
	EndIf;
	
	SetSelectionsInDependentLists(CurOrders);
	SetVisibilityOfPremises();
	
EndProcedure

&AtServer
Procedure DateOfShipmentOnChangeServer()
	
	SetSelectionsInMainLists();
	SetVisibilityOfPremises();
	
EndProcedure

&AtServer
Procedure SetColumnHeadersWeightVolume()
	UnitOfMeasureForVolume 	= String(Constants.UnitOfMeasureForVolume.Get());
	UnitOfMeasureForWeight 	= String(Constants.UnitOfMeasureForWeight.Get());
	
	ItemTitle = NStr("vi = 'Thể tích, %UnitOfMeasure%';
					|ru = 'Объем, %UnitOfMeasure%';
					|en = 'Volume, %UnitOfMeasure%'; fa = 'Volume, %UnitOfMeasure%';
					|it = 'Volume, %UnitOfMeasure%';
					|pl = 'Objętość, %UnitOfMeasure%';
					|tr = 'Hacim, %UnitOfMeasure%'");
	ItemTitle = StrReplace(ItemTitle, "%UnitOfMeasure%", UnitOfMeasureForVolume); 
	Items.JobsInProgress.ChildItems.MovementInWorkVolumeSelection.Title = ItemTitle;
	
	ItemTitle = NStr("vi = 'Trọng lượng (cả bì), %UnitOfMeasure%';
					|ru = 'Вес (брутто), %UnitOfMeasure%';
					|en = 'Weight (gross), %UnitOfMeasure%'; fa = 'Weight (gross), %UnitOfMeasure%';
					|it = 'Peso (lordo), %UnitOfMeasure%';
					|pl = 'Waga (brutto), %UnitOfMeasure%';
					|tr = 'Ağırlık (brüt), %UnitOfMeasure%'");
	ItemTitle = StrReplace(ItemTitle, "%UnitOfMeasure%", UnitOfMeasureForWeight); 
	Items.JobsInProgress.ChildItems.MovementInWorkWeightSelection.Title   = ItemTitle;
EndProcedure

&AtServer
Procedure SetSelectionsInMainLists()
	
	FillOutShippingOrders();
	
	If Items.GroupPages.CurrentPage = Items.GroupFilter Then
		UpdateStatesOfSelectionOrders();
		Items.JobsInProgress.Refresh();
	Else
		Items.NotesInProgress.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetSelectionsInDependentLists(CurOrders)
	
	If CurOrders = Undefined Then
		CurrentPickingReference = Undefined;
		TheCurrentOrderForShipment = Undefined;
	Else
		CurrentPickingReference    = CurOrders.SelectionOrder_;
		TheCurrentOrderForShipment = CurOrders.ShipmentReferenceOrder;
	EndIf;
	
	//JobsInProgress
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Warehouse", Warehouse, DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Premise", Premise, DataCompositionComparisonType.Equal,,True);
	
	// We will reset the selection set for hiding tasks in the case of the filter "flowing to the attraction" in the absence of orders.
	CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Ref", Undefined,,,False);
	
	If FilterJobs = "" Then
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Status", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "ReferenceOrder", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "TransportationJob", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Posted", True,,,False);
	ElsIf FilterJobs = "AllIncomplete" Then
		
		StatusesList = New ValueList;
		StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.InProgress);
		StatusesList.Add(Enums.StatusesOfGoodsPickingPlacement.Prepared2);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,True);
		
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "ReferenceOrder", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "TransportationJob", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Posted", True,,,True);
		
	ElsIf FilterJobs = "ByCurrentReference" Then
		
		If Not CurOrders = Undefined Then
			
			If CurOrders.SelectionOrder_ = Undefined Then
				// There is no current order, we will hide the tasks
				CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Ref", Documents.GoodsPickingPlacement.EmptyRef(),,,True);
			Else
				CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Status", Undefined,,,False);
				
				If TypeOf(CurOrders.SelectionOrder_) = Type("DocumentRef.TransportationJob")
					Or TypeOf(CurOrders.SelectionOrder_) = Type("DocumentRef.Trip") Then
					CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "ReferenceOrder", Undefined,,,False);
					CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "TransportationJob", CurOrders.SelectionOrder_,,,True);
				Else
					CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "ReferenceOrder", CurOrders.SelectionOrder_,,,True);
					CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "TransportationJob", Undefined,,,False);
				EndIf;
				CommonClientServer.SetDynamicListFilterItem(JobsInProgress, "Posted", True,,,False);
			EndIf;
			
		EndIf;
		
	EndIf;	
	
	//NotesInProgress
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Warehouse", Warehouse, DataCompositionComparisonType.Equal,,True);
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "SenderWareroom", Premise,
														DataCompositionComparisonType.Equal,,ValueIsFilled(Premise));
	
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "DateOfShipment", EndOfDay(DateOfShipment),
														DataCompositionComparisonType.LessOrEqual,,ValueIsFilled(DateOfShipment));
	FillOutShippingOrders(False);
	
	// We will reset the selection set for hiding orders in the case of a filter "flowing to the attraction" in the absence of orders.
	CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Undefined,,,False);
	
	If FilterNotes = "" Then
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "ReferenceOrder", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True,,,False);
	ElsIf FilterNotes = "AllUnshipped" Then
		
		StatusesList = New ValueList;
		StatusesList.Add(Enums.GoodsIssueNoteStatuses.Prepared);
		StatusesList.Add(Enums.GoodsIssueNoteStatuses.ForPicking);
		StatusesList.Add(Enums.GoodsIssueNoteStatuses.ForChecking);
		StatusesList.Add(Enums.GoodsIssueNoteStatuses.Verified);
		StatusesList.Add(Enums.GoodsIssueNoteStatuses.ToShip);
		StatusesList.Add(Enums.TransferNoteStatuses.ForPicking);
		StatusesList.Add(Enums.TransferNoteStatuses.ForChecking);
		StatusesList.Add(Enums.TransferNoteStatuses.ToShip);
		
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status", StatusesList, DataCompositionComparisonType.InList,,True);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "ReferenceOrder", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", Undefined,,,False);
		CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True,,,True);
		
	ElsIf FilterNotes = "ByCurrentReference" Then
		
		If Not CurOrders = Undefined Then
			If CurOrders.ShipmentReferenceOrder = Undefined Then
				// There is no current order, we do not show orders
				CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Documents.GoodsIssueNote.EmptyRef(),,,True);
			Else
				CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Status",   Undefined,,,False);
				CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Posted", True,,,False);
				If TypeOf(CurOrders.ShipmentReferenceOrder) = Type("DocumentRef.TransportationJob")
					Or TypeOf(CurOrders.ShipmentReferenceOrder) = Type("DocumentRef.Trip") Then
					
					CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Undefined,,, False);
					CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", CurOrders.ShipmentReferenceOrder,,, True);
					
				Else
					
					Query = New Query;
					Query.Text = 
					"SELECT ALLOWED DISTINCT
					|	GoodsIssueNoteGoodsByReferences.Ref AS Ref
					|FROM
					|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
					|WHERE
					|	GoodsIssueNoteGoodsByReferences.ReferenceOrder = &ReferenceOrder";
					Query.SetParameter("ReferenceOrder", CurOrders.ShipmentReferenceOrder);
					GoodsIssueNotes = Query.Execute().Unload().UnloadColumn("Ref");
					
					CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", GoodsIssueNotes, DataCompositionComparisonType.InList,,True);
					CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", Undefined,,,False);
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;	
	
EndProcedure

&AtServer
Procedure FillOutShippingOrders(CheckParameterChanges = False)
	
	If Not ValueIsFilled(Warehouse) Then
		ShipmentReferences.Clear();
		Return;
	EndIf;
	
	If Not Users.IsFullUser(Undefined) Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	Warehouses.Ref
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref = &Warehouse";
		
		Query.SetParameter("Warehouse", Warehouse);
		
		If Query.Execute().IsEmpty() Then
			ShipmentReferences.Clear();
			Return;
		EndIf;
		
		SetPrivilegedMode(True);
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("Warehouse", 				Warehouse);
	Query.SetParameter("TransportationJob", CurrentTransportationJobShipment);
	Query.SetParameter("DateOfShipment", 		?(ValueIsFilled(DateOfShipment), EndOfDay(DateOfShipment) + 1, DateOfShipment));
	Query.SetParameter("DateOfShipmentDelivery", BegOfDay(DateOfShipment));
	Query.SetParameter("ShipmentDateFilledIn", ValueIsFilled(DateOfShipment));
	
	IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("ShowDetailsShipment", ShowDetailsShipment);
	
	States1 = New Array;
	If ShipmentStatus = "AllInProgress" Then 
		States1.Add(Enums.GoodsPickingStates.DuringSelection);
		States1.Add(Enums.GoodsPickingStates.PendingPicking);
		States1.Add(Enums.GoodsPickingStates.PendingShipment);
	ElsIf ShipmentStatus = "" Then
		For Each Value In Enums.GoodsPickingStates Do 
			States1.Add(Value);
		EndDo;
	Else
		States1.Add(Enums.GoodsPickingStates[ShipmentStatus]);
	EndIf;
	Query.SetParameter("States1", States1);			
		
	// If the parameters have not changed, then you do not need to form the list again
	If CheckParameterChanges
	 And TypeOf(ShipmentReferenceParameters) = Type("FixedStructure")
	 And TMCommonUseClientServer.StructuresAreEqual(ShipmentReferenceParameters, Query.Parameters, "") Then 
		Return;
	EndIf;
	
	// Caching the current parameters
	ShipmentReferenceParameters = New Structure("Warehouse, TransportationJob, DateOfShipment");
	FillPropertyValues(ShipmentReferenceParameters, Query.Parameters);
	ShipmentReferenceParameters.Insert("ShowDetailsShipment", ShowDetailsShipment);
	ShipmentReferenceParameters = New FixedStructure(ShipmentReferenceParameters);
	
	QueryText = "";
	
	AllowableDeviationOfMeasuringGoodsShipmentAndReceiving =
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get();
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0
		And Not (GoodsDeliveryClientServer.UsedDelivery25()
				And WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Warehouse)) Then
		
		QueryText = QueryText + "
		|SELECT
		|	GoodsForShipmentTurnover.DocumentShipments AS DocumentShipments,
		|	GoodsForShipmentTurnover.Products     AS Products,
		|	GoodsForShipmentTurnover.Characteristic   AS Characteristic,
		|	GoodsForShipmentTurnover.Purpose       AS Purpose,
		|	GoodsForShipmentTurnover.Series            AS Series,
		|	GoodsForShipmentTurnover.Warehouse            AS Warehouse,
		|	GoodsForShipmentTurnover.Recipient       AS Recipient,
		|	GoodsForShipmentTurnover.ToShipReceipt  AS Count
		|
		|INTO GoodsForShipmentTurnover
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			&ConnectionConditionRevolutions) AS GoodsForShipmentTurnover
		|
		|INDEX BY
		|	Warehouse,
		|	Recipient,
		|	DocumentShipments,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	If Not ShowDetailsShipment Then
		
		If WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Warehouse) Then
			
			GoodsDelivery.AddDeliveryDataToShipmentManagementQueryText(Query, QueryText);
			
		Else
			QueryText = QueryText + "
			|SELECT DISTINCT
			|	NestedQuery.DocumentShipments AS ReferenceOrder,
			|	NestedQuery.Recipient AS Recipient,
			|	CASE
			|		WHEN MIN(NestedQuery.State) = 0
			|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
			|		WHEN MIN(NestedQuery.State) = 1
			|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
			|		WHEN MIN(NestedQuery.State) = 2
			|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
			|		WHEN MIN(NestedQuery.State) = 3
			|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
			|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
			|	END AS State
			|INTO OrdersAndStates
			|FROM
			|	(SELECT
			|		ReferencesToShip.DocumentShipments AS DocumentShipments,
			|		ReferencesToShip.Recipient AS Recipient,
			|		ReferencesToShip.Products AS Products,
			|		ReferencesToShip.Characteristic AS Characteristic,
			|		ReferencesToShip.Purpose AS Purpose,
			|		ReferencesToShip.Series AS Series,
			|		CASE
			|			WHEN &PendingPicking
			|				THEN 0
			|			WHEN ReferencesToShip.AssemblyInProgressBalance <> 0
			|				THEN 1
			|			WHEN ReferencesToShip.AssembledBalance <> 0
			|				THEN 2
			|			WHEN ReferencesToShip.ToRegisterBalance <> 0
			|				THEN 3
			|			ELSE 404
			|		END AS State
			|	FROM
			|		AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS ReferencesToShip
			|	WHERE &ConditionGoodsForSelection) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.DocumentShipments,
			|	NestedQuery.Recipient
			|
			|HAVING
			|	CASE
			|		WHEN MIN(NestedQuery.State) = 0
			|			THEN VALUE(Enum.GoodsPickingStates.PendingPicking)
			|		WHEN MIN(NestedQuery.State) = 1
			|			THEN VALUE(Enum.GoodsPickingStates.DuringSelection)
			|		WHEN MIN(NestedQuery.State) = 2
			|			THEN VALUE(Enum.GoodsPickingStates.PendingShipment)
			|		WHEN MIN(NestedQuery.State) = 3
			|			THEN VALUE(Enum.GoodsPickingStates.PendingInvoiceRegistration)
			|		ELSE VALUE(Enum.GoodsPickingStates.EmptyRef)
			|	END IN (&States1)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	OrdersAndStates.ReferenceOrder AS ReferenceOrder,
			|	OrdersAndStates.Recipient AS Recipient,
			|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS Number,
			|	ISNULL(DocumentsRegistry.IBDocumentDate, DATETIME(1,1,1)) AS Date,
			|	CASE
			|		WHEN OrdersAndStates.ReferenceOrder REFS Document.MovementOfProductsAndMaterials
			|			THEN PRESENTATION(ISNULL(DocumentsRegistry.BusinessOperation, VALUETYPE(OrdersAndStates.ReferenceOrder)))
			|		ELSE 
			|	VALUETYPE(OrdersAndStates.ReferenceOrder)
			|	END
			| 	AS DocumentType,
			|	OrdersAndStates.State,
			|	0 AS PictureIndex
			|FROM
			|	OrdersAndStates AS OrdersAndStates
			|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
			|		ON OrdersAndStates.ReferenceOrder = DocumentsRegistry.Ref
			|			AND (NOT DocumentsRegistry.AdditionalRecord)
			|
			|ORDER BY
			|	DocumentsRegistry.IBDocumentDate";
		EndIf;
		
	Else // ShowDetailsShipment
		
		GoodsDelivery.CompleteQueryTextOfShipmentManagementWithDeliveryDataShipmentDetails(QueryText);
		
	EndIf;
	
	If AllowableDeviationOfMeasuringGoodsShipmentAndReceiving <> 0 Then
		
		PendingPicking = 
		"		&IssueInvoicesFirst
		|			AND CASE
		|				WHEN ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance >= 0
		|					THEN ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance
		|				ELSE -(ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance)
		|			END > CASE
		|				WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|					THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|				ELSE 0
		|			END
		|		OR NOT &IssueInvoicesFirst
		|			AND CASE
		|				WHEN ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance >= 0
		|					THEN ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance
		|				ELSE -(ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance)
		|			END > CASE
		|				WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|					THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|				ELSE 0
		|			END";
				
		ConditionGoodsForSelection = "
		|		INNER JOIN GoodsForShipmentTurnover AS GoodsForShipmentTurnover
		|		ON ReferencesToShip.DocumentShipments = GoodsForShipmentTurnover.DocumentShipments
		|			AND ReferencesToShip.Products = GoodsForShipmentTurnover.Products
		|			AND ReferencesToShip.Characteristic = GoodsForShipmentTurnover.Characteristic
		|			AND ReferencesToShip.Purpose = GoodsForShipmentTurnover.Purpose
		|			AND ReferencesToShip.Series = GoodsForShipmentTurnover.Series
		|			AND ReferencesToShip.Warehouse = GoodsForShipmentTurnover.Warehouse
		|			AND ReferencesToShip.Recipient = GoodsForShipmentTurnover.Recipient
		|WHERE
		|
		|	ReferencesToShip.ToRegisterBalance >
		|		CASE
		|			WHEN ReferencesToShip.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
		|				THEN &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100 * GoodsForShipmentTurnover.Count
		|					ELSE 0
		|		END
		|
		|	OR ReferencesToShip.AssemblyInProgressBalance <> 0
		|	OR ReferencesToShip.AssembledBalance <> 0
		|	OR (&PendingPicking)";
		
		ConditionGoodsForSelection = StrReplace(ConditionGoodsForSelection,"&PendingPicking", PendingPicking);
		
		QueryText = StrReplace(QueryText,"WHERE &ConditionGoodsForSelection", ConditionGoodsForSelection);
		QueryText = StrReplace(QueryText,"&PendingPicking", PendingPicking);
		Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",AllowableDeviationOfMeasuringGoodsShipmentAndReceiving);
		Query.SetParameter("DimensionalTypesOfUnits", Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Else
		
		PendingPicking = 
		"&IssueInvoicesFirst
		|			AND ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0
		|		OR NOT &IssueInvoicesFirst
		|			AND ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0";
		
		ConditionGoodsForSelection = 
		"WHERE 
		|	(ReferencesToShip.ToRegisterBalance <> 0
		|			OR (&PendingPicking)
		|			OR ReferencesToShip.AssemblyInProgressBalance <> 0
		|			OR ReferencesToShip.AssembledBalance <> 0)";
		
		ConditionGoodsForSelection = StrReplace(ConditionGoodsForSelection,"&PendingPicking", PendingPicking);
		
		QueryText = StrReplace(QueryText,"WHERE &ConditionGoodsForSelection", ConditionGoodsForSelection);
		QueryText = StrReplace(QueryText,"&PendingPicking", PendingPicking);
		
	EndIf;
	
	If ShowDetailsShipment Then
		ConnectionConditionRevolutions = "Warehouse = &Warehouse
		|					AND DocumentShipments IN
		|						(SELECT
		|							TransportationTask.ReferenceOrder AS DocumentShipments
		|						FROM
		|							Document.TransportationJob.References AS TransportationTask
		|						WHERE
		|							TransportationTask.Ref = &TransportationJob)";
	Else
		ConnectionConditionRevolutions = "Warehouse = &Warehouse";
	EndIf;
	
	QueryText = StrReplace(QueryText,"&ConnectionConditionRevolutions", ConnectionConditionRevolutions);
	
	Query.Text = QueryText;
	
	// Let's remember the current row of the orders table
	If ValueIsFilled(Items.ShipmentReferences.CurrentRow) Then
		CurLineOfShipmentOrder = 
			ShipmentReferences.FindByID(Items.ShipmentReferences.CurrentRow);
		If CurLineOfShipmentOrder <> Undefined Then
			CurrentOrder = CurLineOfShipmentOrder.ReferenceOrder;
		EndIf;		
	Else
		CurrentOrder = Undefined;
	EndIf;
	
	ShipmentReferences.Load(Query.Execute().Unload());
	
	// Restore the current line
	If ValueIsFilled(CurrentOrder) Then
		Rows = ShipmentReferences.FindRows(New Structure("ReferenceOrder", CurrentOrder));
		If Rows.Count() > 0 Then
			Items.ShipmentReferences.CurrentRow = Rows[0].GetID();
		EndIf;
	ElsIf ShipmentReferences.Count() > 0 Then
		Items.ShipmentReferences.CurrentRow = ShipmentReferences[0].GetID();
	EndIf;
	
EndProcedure

&AtServer
Procedure NotificationProcessingServer(EventName, StructureOfOrders)
			
	If EventName = "ChangingList_OrdersInProgress" Then
		
		FillOutShippingOrders(True);
		UpdateStatesOfSelectionOrders();
		Items.NotesInProgress.Refresh();
		
	ElsIf EventName = "ChangingList_OrdersInProgress"
		Or EventName = "Write_GoodsIssueNote"
		Or EventName = "Write_GoodsTransferNote" Then 
		
		SetSelectionsInMainLists();
		
	ElsIf EventName = "ChangingListOf_TasksInProgress"
				Or EventName = "Write_Trip" Then
		
		UpdateStatesOfSelectionOrders();
		
	EndIf;
	
	SetSelectionsInDependentLists(StructureOfOrders);
	
EndProcedure

&AtClient
Procedure UpdateStatesOfSelectionOrdersClient()
	If Items.GroupPages.CurrentPage = Items.GroupFilter Then
		UpdateStatesOfSelectionOrders();
	EndIf;
EndProcedure

&AtServer
Procedure UpdateStatesOfSelectionOrders()	
	Var CurrentOrder;
	
	// Let's remember the current line
	Id = Items.PickingReferences.CurrentRow;
	If Id <> Undefined Then
		CollectionItem = PickingReferences.FindByID(Id);
		If CollectionItem <> Undefined Then
			CollectionItem.Property("ReferenceOrder", CurrentOrder);
		EndIf;
	EndIf;
	
	WarehousesServer.CalculateStatesOfOrdersForSelection(
		Warehouse,
	 	Premise,
		PickingReferences,
		ShowDetailsFilter,
		CurrentTransportationJobFilter,
		SelectionState);
	
	// Restore the current line
	If ValueIsFilled(CurrentOrder) Then
		Rows = PickingReferences.FindRows(New Structure("ReferenceOrder", CurrentOrder));
		If Rows.Count() > 0 Then
			Items.PickingReferences.CurrentRow = Rows[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillOrderFilterSelectionList()
	
	// We will add OR remove the "All Loaded" element from the Filter Order field selection list
	// , depending on the use of order statuses in the selected warehouse.
	
	If Not GoodsIssueNoteCreationIsAvailable Then
		ChoiceList  = Items.OrderFilterAutomaticGenerationOfExpenseOrders.ChoiceList;
		SelectListElement = Items.OrderFilterAutomaticGenerationOfExpenseOrders; 
	Else
		ChoiceList  = Items.FilterNotes.ChoiceList;
		SelectListElement = Items.FilterNotes;
	EndIf;
	
	ListItem = ChoiceList.FindByValue("AllUnshipped");
	
	If WarehousesServer.UseOrderStatuses(Warehouse, False, True) Then
		If ListItem = Undefined Then
			ListItem = ChoiceList.Insert(1, "AllUnshipped");
		EndIf;
		ListItem.Presentation = NStr("vi = 'Tất cả chưa được giao hàng';
									|ru = 'Все неотгруженные';
									|en = 'All unshipped'; fa = 'همه ارسال‌نشده‌ها';
									|it = 'Tutti non spediti';
									|pl = 'Wszystkie niewysłane';
									|tr = 'Tüm sevk edilmeyenler'");
	Else
		If ListItem <> Undefined Then
			ChoiceList.Delete(ListItem);
			If FilterNotes = "AllUnshipped" Then
				FilterNotes = ChoiceList[0].Value; // the new selection will be set later, when calling installselection of dependent lists
			EndIf;
		EndIf;
	EndIf;
	
	If Not GoodsIssueNoteCreationIsAvailable Then	
		ListItem = ChoiceList.FindByValue("ByCurrentReference");
		If ListItem <> Undefined Then
			ChoiceList.Delete(ListItem);	
		EndIf;
		If FilterNotes = "ByCurrentReference" Then
			FilterNotes = ChoiceList[0].Value; // the new selection will be set later, when calling installselection of dependent lists
		EndIf;
	EndIf;
	
	If ChoiceList.Count() = 1 Then
		SelectListElement.Visible = False;
	Else
		SelectListElement.Visible = True;
	EndIf;	
	
EndProcedure

#EndRegion

#Region OrderProcessing

&AtServer
Procedure CreateNotesServer()
	If Not AssignShippingArea Then
		ShippingZone = Catalogs.StorageBins.EmptyRef();
	EndIf;
	
	Recipients = New Map;
	
	StructureOfParametersForCreatingSpendingOrders = WarehousesServer.ParametersForReissuingSpendingOrders();
	StructureOfParametersForCreatingSpendingOrders.Warehouse = Warehouse;
	If ByOneWareroom Then
		StructureOfParametersForCreatingSpendingOrders.Premise = WareroomToCreateGoodsIssueNotes;
	EndIf;	
	StructureOfParametersForCreatingSpendingOrders.ShippingZone = ShippingZone;
	
	If ByAllReferences = 0 Then
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	NestedQuery.Recipient AS Recipient
		|FROM
		|	(SELECT
		|		ReferencesToShip.DocumentShipments AS DocumentShipments,
		|		ReferencesToShip.Recipient AS Recipient,
		|		ReferencesToShip.Products AS Products,
		|		ReferencesToShip.Characteristic AS Characteristic,
		|		ReferencesToShip.Purpose AS Purpose,
		|		ReferencesToShip.Series AS Series
		|	FROM
		|		AccumulationRegister.GoodsForIssue.Balance(&DateOfShipment, Warehouse = &Warehouse) AS ReferencesToShip
		|	WHERE
		|		(&IssueInvoicesFirst
		|					AND ReferencesToShip.ToShipBalance - ReferencesToShip.ToRegisterBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0
		|				OR NOT &IssueInvoicesFirst
		|					AND ReferencesToShip.ToShipBalance - ReferencesToShip.AssemblyInProgressBalance - ReferencesToShip.AssembledBalance > 0
		|				OR ReferencesToShip.AssemblyInProgressBalance <> 0
		|				OR ReferencesToShip.AssembledBalance <> 0)) AS NestedQuery";
		
		ShippingDateForRequest = ?(ValueIsFilled(DateOfShipment),
			EndOfDay(DateOfShipment) + 1,
			DateOfShipment);
		
		IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get()
			= Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
		
		Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
		Query.SetParameter("Warehouse", Warehouse);
		Query.SetParameter("DateOfShipment", ShippingDateForRequest);
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			Recipients.Insert(Selection.Recipient, New Array);
		EndDo;
	Else
		For Each RwID In Items.ShipmentReferences.SelectedRows Do
			
			RowOfTables = ShipmentReferences.FindByID(RwID);
			
			If RowOfTables = Undefined Then
				WarningText = NStr("vi = 'Chọn lệnh để giao hàng.';
									|ru = 'Выберите распоряжение на отгрузку товаров.';
									|en = 'Select a goods shipment reference.'; fa = 'Select a goods shipment reference.';
									|it = 'Selezionare il mandato per la spedizione merci.';
									|pl = 'Wybierz zamówienie do wysyłki towarów.';
									|tr = 'Ürünlerin sevkiyatı için siparişi seç.'");
				CommonClientServer.MessageToUser(WarningText);
				Return;
			EndIf;
			
			If TypeOf(RowOfTables.ReferenceOrder) = Type("DocumentRef.TransportationJob") Then
				
				StructureOfParametersForCreatingSpendingOrders.TransportationJob = RowOfTables.ReferenceOrder;
				Query = New Query;
				Query.Text =
				"SELECT
				|	TransportationTask.ReferenceOrder,
				|	TransportationTask.RecipientSender AS Recipient
				|FROM
				|	Document.TransportationJob.References AS TransportationTask
				|WHERE
				|	TransportationTask.Ref = &Ref
				|
				|ORDER BY
				|	Recipient";
				Query.SetParameter("Ref", RowOfTables.ReferenceOrder);
				
				Selection = Query.Execute().Select();
				While Selection.NextByFieldValue("Recipient") Do
					
					StructureOfParametersForCreatingSpendingOrders.Recipient = Selection.Recipient;
					StructureOfParametersForCreatingSpendingOrders.ShipmentReferences.Clear();
					While Selection.Next() Do
						StructureOfParametersForCreatingSpendingOrders.ShipmentReferences.Add(Selection.ReferenceOrder);
					EndDo;
					WarehousesServer.ReissueSpendingOrders(StructureOfParametersForCreatingSpendingOrders);
					
				EndDo;
				
				If ShowDetailsShipment Then
					
					Recipients.Clear();
					Break;
					
				EndIf;
				
			ElsIf TypeOf(RowOfTables.ReferenceOrder) = Type("DocumentRef.Trip") Then
				
				StructureOfParametersForCreatingSpendingOrders.TransportationJob = RowOfTables.ReferenceOrder;
				Query = New Query;
				Query.Text =
				"SELECT
				|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
				|	DeliveryTurnover.PlanningDocument AS PlanningDocument,
				|	DeliveryTurnover.Recipient AS Recipient,
				|	MIN(DeliveryTurnover.RowCode) AS RowCode
				|INTO TripDataTT
				|FROM
				|	AccumulationRegister.Delivery.Turnovers(
				|			,
				|			,
				|			,
				|			Trip = &Trip
				|				AND Arm = 1) AS DeliveryTurnover
				|
				|GROUP BY
				|	DeliveryTurnover.ReferenceOrder,
				|	DeliveryTurnover.Recipient,
				|	DeliveryTurnover.PlanningDocument
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT DISTINCT
				|	TripDataTT.ReferenceOrder AS ReferenceOrder,
				|	ISNULL(DocumentsRegistry.Partner, VALUE(Catalog.Partners.EmptyRef)) AS Recipient
				|FROM
				|	TripDataTT AS TripDataTT
				|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
				|		ON TripDataTT.ReferenceOrder = DocumentsRegistry.Ref
				|			AND (NOT DocumentsRegistry.AdditionalRecord)
				|
				|ORDER BY
				|	Recipient";
				Query.SetParameter("Trip", RowOfTables.ReferenceOrder);
				
				Selection = Query.Execute().Select();
				While Selection.NextByFieldValue("Recipient") Do
					
					StructureOfParametersForCreatingSpendingOrders.Recipient = Selection.Recipient;
					StructureOfParametersForCreatingSpendingOrders.ShipmentReferences.Clear();
					While Selection.Next() Do
						StructureOfParametersForCreatingSpendingOrders.ShipmentReferences.Add(Selection.ReferenceOrder);
					EndDo;
					WarehousesServer.ReissueSpendingOrders(StructureOfParametersForCreatingSpendingOrders);
					
				EndDo;
				
				If ShowDetailsShipment Then
					
					Recipients.Clear();
					Break;
					
				EndIf;
				
			Else
				ReferenceArray = Recipients.Get(RowOfTables.Recipient);
				If ReferenceArray = Undefined Then
					ReferenceArray = New Array;
					Recipients.Insert(RowOfTables.Recipient, ReferenceArray);
				EndIf;
				ReferenceArray.Add(RowOfTables.ReferenceOrder);
			EndIf;	
		EndDo;
	EndIf;
	
	If Recipients.Count() > 0 Then
		
		If ShowDetailsShipment Then
			StructureOfParametersForCreatingSpendingOrders.TransportationJob = CurrentTransportationJobShipment;
		Else
			StructureOfParametersForCreatingSpendingOrders.TransportationJob = Undefined;
		EndIf;
		
		For Each Recipient In Recipients Do
			StructureOfParametersForCreatingSpendingOrders.Recipient = Recipient.Key;
			StructureOfParametersForCreatingSpendingOrders.ShipmentReferences = Recipient.Value;
			WarehousesServer.ReissueSpendingOrders(StructureOfParametersForCreatingSpendingOrders);
		EndDo;
		
	EndIf;
	
	SetSelectionsInMainLists();
	
	If FilterNotes = "ByCurrentReference" Then
		
		If TypeOf(TheCurrentOrderForShipment) = Type("DocumentRef.TransportationJob")
			Or TypeOf(TheCurrentOrderForShipment) = Type("DocumentRef.Trip") Then
			
			CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", Undefined,,, False);
			CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", TheCurrentOrderForShipment,,, True);
			
		Else
			
			Query = New Query;
			Query.Text = 
			"SELECT ALLOWED DISTINCT
			|	GoodsIssueNoteGoodsByReferences.Ref AS Ref
			|FROM
			|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
			|WHERE
			|	(GoodsIssueNoteGoodsByReferences.ReferenceOrder = &ReferenceOrder
			|			OR GoodsIssueNoteGoodsByReferences.Ref.TransportationJob = &ReferenceOrder)";
			Query.SetParameter("ReferenceOrder", TheCurrentOrderForShipment);
			GoodsIssueNotes = Query.Execute().Unload().UnloadColumn("Ref");
			
			CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "Ref", GoodsIssueNotes, DataCompositionComparisonType.InList,,True);
			CommonClientServer.SetDynamicListFilterItem(NotesInProgress, "TransportationJob", Undefined,,,False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartOrderFormation()
	
	Recipients = RecipientsForWhichThereIsNoBackgroundTaskForReissuingOrders(Warehouse);
	
	StructureOfParametersForCreatingSpendingOrders = WarehousesServer.ParametersForReissuingSpendingOrders();
	StructureOfParametersForCreatingSpendingOrders.Warehouse = Warehouse;
	
	For Each Recipient In Recipients Do
		StructureOfParametersForCreatingSpendingOrders.Recipient = Recipient;
		WarehousesServer.ReissueSpendingOrders(StructureOfParametersForCreatingSpendingOrders);
	EndDo;
	
	SetSelectionsInMainLists();
	MonitoringOperationOfBackgroundQueueFormationTasksServer();
	
EndProcedure

&AtServer
Function SetShippingZonesServer(Val DocumentsArray)

	ArrayOfChangedDocuments = New Array;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsIssueNote.Ref AS Ref
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.ShippingZone <> &ShippingZone
	|	AND GoodsIssueNote.Ref IN(&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTransferNote.Ref
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|WHERE
	|	GoodsTransferNote.ShippingZone <> &ShippingZone
	|	AND GoodsTransferNote.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("ShippingZone", ShippingZone);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		Try
			DocumentObject = Selection.Ref.GetObject();
			
			DocumentObject.Lock();
			
			DocumentObject.ShippingZone = ShippingZone;
			
			DocumentObject.Write(DocumentWriteMode.Write);
			ArrayOfChangedDocuments.Add(Selection.Ref);
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	Items.NotesInProgress.Refresh();
	
	Return ArrayOfChangedDocuments;
	
EndFunction

&AtServer
Function AssignShipmentPriorityServer(Val DocumentsArray, Priority)
	
	ArrayOfChangedDocuments = New Array;
	
    Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsIssueNote.Ref AS Ref
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Priority <> &Priority
	|	AND GoodsIssueNote.Ref IN(&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTransferNote.Ref
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|WHERE
	|	GoodsTransferNote.Priority <> &Priority
	|	AND GoodsTransferNote.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("Priority", Priority);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		Try
			DocumentObject = Selection.Ref.GetObject(); // DocumentObject.GoodsIssueNote, DocumentObject.GoodsTransferNote
			
			DocumentObject.Lock();
			
			DocumentObject.Priority = Priority;
			
			DocumentObject.Write(DocumentWriteMode.Write);
			ArrayOfChangedDocuments.Add(Selection.Ref);
			
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
	EndDo;
	
	Items.NotesInProgress.Refresh();
	
	Return ArrayOfChangedDocuments;
	
EndFunction

&AtServer
Function ChangeServerStatusOrders(ArrayOfDocumentsToProcess, DocumentStatus)
	
	ArrayOfChangedDocuments = New Array;
	
	ReplaceTransportationTasksWithReferencesToSpendingOrdersInArray(ArrayOfDocumentsToProcess);
	
	DocumentsArray = CommonClientServer.CopyArray(ArrayOfDocumentsToProcess);
	
	IndexOf = DocumentsArray.Count();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsIssueNote.Ref AS Ref,
	|	GoodsIssueNote.Posted AS Posted,
	|	GoodsIssueNote.Status AS Status,
	|	CASE
	|		WHEN SettingsOfBinLocationWarehouses.UseBinLocationWarehousing
	|				AND GoodsIssueNote.DateOfShipment >= SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseBinLocationWarehousing
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|		LEFT JOIN InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|		ON (SettingsOfBinLocationWarehouses.Warehouse = GoodsIssueNote.Warehouse)
	|			AND (SettingsOfBinLocationWarehouses.Premise = GoodsIssueNote.Premise)
	|WHERE
	|	GoodsIssueNote.Ref IN(&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTransferNote.Ref,
	|	GoodsTransferNote.Posted,
	|	GoodsTransferNote.Status,
	|	CASE
	|		WHEN SettingsOfBinLocationWarehouses.UseBinLocationWarehousing
	|				AND GoodsTransferNote.DateOfShipment >= SettingsOfBinLocationWarehouses.StartDateOfUsingWarehouseBinSystem
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|		LEFT JOIN InformationRegister.SettingsOfBinLocationWarehouses AS SettingsOfBinLocationWarehouses
	|		ON (SettingsOfBinLocationWarehouses.Warehouse = GoodsTransferNote.Warehouse)
	|			AND (SettingsOfBinLocationWarehouses.Premise = GoodsTransferNote.SenderWareroom)
	|WHERE
	|	GoodsTransferNote.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	DocumentDataTable_ = Query.Execute().Unload();
	
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		ArrRow = DocumentsArray[IndexOf];
		
		DocumentAttributes = DocumentDataTable_.Find(ArrRow,"Ref");
		
		If Not DocumentAttributes.Posted Then
			MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng từ %Document%: có thể thay đổi trạng thái bằng bộ xử lý theo nhóm chỉ đối với các chứng từ đã kết chuyển.';
								|ru = 'Статус документа %Document% не изменен: групповой обработкой можно изменять статусы только для проведенных документов.';
								|en = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.'; fa = 'Status of document %Document% is not changed: group processing can change statuses only for posted documents.';
								|it = 'Lo stato del documento %Document% non è modificato: tramite elaborazione collettiva è possibile modificare lo stato solo per i documenti registrati.';
								|pl = 'Status dokumentu %Document% nie jest zmieniony: przetwarzaniem grupowym można zmieniać statusy tylko dla zatwierdzonych dokumentów.';
								|tr = 'Belge durumu %Document% değiştirilmedi: Grup işleme, yalnızca kaydedilen belgelerin durumlarını değiştirebilir.'");
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			
			CommonClientServer.MessageToUser(MessageText);
			DocumentsArray.Delete(IndexOf);
		ElsIf DocumentStatus = "Shipped_"
			And TypeOf(ArrRow) <> Type("DocumentRef.GoodsIssueNote") Then
			MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng từ %Document%: trạng thái %Shipped_% chỉ có thể thiết lập đối với phiếu xuất kho.';
								|ru = 'Статус документа %Document% не изменен: статус %Shipped_% может быть установлен только для расходных ордеров.';
								|en = 'Status of document %Document% is not changed: status %Shipped_% can be set only for goods issue notes.'; fa = 'Status of document %Document% is not changed: status %Shipped_% can be set only for goods issue notes.';
								|it = 'Lo stato del documento %Document% non è modificato: lo stato %Shipped_% può essere impostato solo per mandati di pagamento.';
								|pl = 'Status dokumentu %Document% nie jest zmieniony %Shipped_% można ustawić tylko dla zleceń wydania.';
								|tr = 'Belge durumu %Document% değiştirilmedi: %Shipped_% durum yalnızca ambar çıkış fişleri için ayarlanabilir.'");
			MessageText = StrReplace(MessageText, "%Document%", ArrRow);
			MessageText = StrReplace(MessageText, "%Shipped_%", Enums.GoodsIssueNoteStatuses.Shipped_);
		
			CommonClientServer.MessageToUser(MessageText);
			DocumentsArray.Delete(IndexOf);
		Else
			If TypeOf(ArrRow) = Type("DocumentRef.GoodsIssueNote") Then
				StatusEnumerationValue = Enums.GoodsIssueNoteStatuses[DocumentStatus];
			Else
				StatusEnumerationValue = Enums.TransferNoteStatuses[DocumentStatus];
			EndIf;
			
			If DocumentAttributes.Status = StatusEnumerationValue Then
				
				MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng từ %Document% vì chứng từ đã có trạng thái %Status%';
									|ru = 'Статус документа %Document% не изменен, т.к. документ уже находится в статусе %Status%';
									|en = 'Status of document %Document% is not changed, as the document is already in status %Status%'; fa = 'Status of document %Document% is not changed, as the document is already in status %Status%';
									|it = 'Lo stato del documento %Document% non è modificato, perché il documento ha già lo stato %Status%';
									|pl = 'Status dokumentu %Document% nie jest zmieniony, ponieważ już jest w statusie %Status%';
									|tr = 'Belge durumu %Document% değiştirilmedi, çünkü belge zaten durumda %Status%'");
				MessageText = StrReplace(MessageText, "%Document%", ArrRow);
				MessageText = StrReplace(MessageText, "%Status%", StatusEnumerationValue);
				
				CommonClientServer.MessageToUser(MessageText);
				DocumentsArray.Delete(IndexOf);
			EndIf;
		EndIf;
		
	EndDo;
	
	DocumentsArray = WarehousesServer.CheckOrdersForStatusChanges(DocumentsArray);
	
	If DocumentsArray.Count() = 0 Then
		Return ArrayOfChangedDocuments;
	EndIf;
	
	IndexOf = DocumentsArray.Count();
	
	While IndexOf > 0 Do
		
		IndexOf = IndexOf - 1;
		DocRef = DocumentsArray[IndexOf];
		
		YouCanChangeStatusWithoutOverfilling = False;
		
		DocumentAttributes = DocumentDataTable_.Find(DocRef,"Ref");
		
		If TypeOf(DocRef) = Type("DocumentRef.GoodsIssueNote") Then
			StatusEnumerationValue = Enums.GoodsIssueNoteStatuses[DocumentStatus];
			
			If Not DocumentAttributes.UseBinLocationWarehousing
				Or (DocumentAttributes.Status = Enums.GoodsIssueNoteStatuses.ForChecking
						Or DocumentAttributes.Status = Enums.GoodsIssueNoteStatuses.Verified
						Or DocumentAttributes.Status = Enums.GoodsIssueNoteStatuses.ToShip
						Or DocumentAttributes.Status = Enums.GoodsIssueNoteStatuses.Shipped_)
					And (StatusEnumerationValue = Enums.GoodsIssueNoteStatuses.Verified
						Or StatusEnumerationValue = Enums.GoodsIssueNoteStatuses.ToShip
						Or StatusEnumerationValue= Enums.GoodsIssueNoteStatuses.Shipped_)
				Or (DocumentAttributes.Status = Enums.GoodsIssueNoteStatuses.Prepared
					And StatusEnumerationValue = Enums.GoodsIssueNoteStatuses.ForPicking) Then
				
				YouCanChangeStatusWithoutOverfilling = True;
			EndIf;
		Else
			StatusEnumerationValue = Enums.TransferNoteStatuses[DocumentStatus];
			If Not DocumentAttributes.UseBinLocationWarehousing
				Or DocumentAttributes.Status = Enums.TransferNoteStatuses.ForChecking
					And StatusEnumerationValue = Enums.TransferNoteStatuses.ToShip Then
				
				YouCanChangeStatusWithoutOverfilling = True;
			EndIf;
		EndIf;
		
		If YouCanChangeStatusWithoutOverfilling Then
			Try
				DocumentObject = DocRef.GetObject(); // DocumentObject
				DocumentObject.Lock();
			Except
				DocumentsArray.Delete(IndexOf);
				CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
				Continue;
			EndTry;
			
			DocumentManager = Documents[DocumentObject.Metadata().Name];
			DocumentObject.Status = StatusEnumerationValue;
			
			If TypeOf(DocRef) = Type("DocumentRef.GoodsIssueNote") Then
				SeriesSpecificationParameters = New FixedStructure(
										ProductsServer.SeriesSpecificationParameters(DocumentObject,DocumentManager).ShippedGoods);
			Else
				SeriesSpecificationParameters = New FixedStructure(
										ProductsServer.SeriesSpecificationParameters(DocumentObject,DocumentManager));
			EndIf;
									
			If StatusEnumerationValue = Enums.GoodsIssueNoteStatuses.Shipped_ Then
				// For move orders, the date changes when the "Accepted" Status is set
				DocumentObject.DateOfShipment = CurrentSessionDate();
			ElsIf StatusEnumerationValue = Enums.GoodsIssueNoteStatuses.ForPicking Then
				ProductsServer.FillInSeriesByFEFO(DocumentObject, SeriesSpecificationParameters, False); 
			EndIf;                                          
			
			DocumentManager.FillInActionInLines(DocumentObject);
			ProductsServer.FillInStatusesForSpecifyingSeries(DocumentObject, SeriesSpecificationParameters);
			
			If DocumentObject.CheckFilling() Then
				Try
					DocumentObject.Write(DocumentWriteMode.Posting);
					ArrayOfChangedDocuments.Add(DocRef);
				Except
					CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
				EndTry;
			Else
				ArrayOfMessages = GetUserMessages(True);
				MessageText = NStr("vi = 'Chưa thay đổi trạng thái chứng từ %OrderLink% vì có lỗi điền.';
									|ru = 'Статус документа %OrderLink% не изменен, т.к. есть ошибки заполнения.';
									|en = 'Status of document %OrderLink% is not changed, as there are population errors.'; fa = 'Status of document %OrderLink% is not changed, as there are population errors.';
									|it = 'Lo stato del documento%OrderLink% non è modificato, perché ci sono errori di compilazione.';
									|pl = 'Status dokumentu %OrderLink% nie jest zmieniony, ponieważ istnieją błędy wypełnienia.';
									|tr = 'Belge durumu %OrderLink% değiştirilmedi, çünkü doldurma hataları mevcut.'");
				MessageText = StrReplace(MessageText,"%OrderLink%",DocumentObject.Ref);
				CommonClientServer.MessageToUser(MessageText,DocumentObject.Ref);
				For Each Message In ArrayOfMessages Do
					Message.Message();
				EndDo;
			EndIf;
			DocumentsArray.Delete(IndexOf);
			
		EndIf;
		
	EndDo;
	
	If DocumentsArray.Count() = 0 Then
		SetSelectionsInMainLists();
		Return ArrayOfChangedDocuments;
	EndIf;
	
	ArrayOfRefilledDocuments = FillOrders_WithSelectedProductsServer(DocumentsArray, True, DocumentStatus);
	CommonClientServer.SupplementArray(ArrayOfChangedDocuments,ArrayOfRefilledDocuments);
	
	SetSelectionsInMainLists();
	
	Return ArrayOfChangedDocuments;
	
EndFunction

&AtServer
Procedure ReplaceTransportationTasksWithReferencesToSpendingOrdersInArray(DocumentsArray)
	
	If Not WarehousesServer.StartShipmentOnceDeliveryOrderIsCreated(Warehouse) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsIssueNote.Ref AS Ref
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ForPicking)
	|	AND GoodsIssueNote.Posted
	|	AND GoodsIssueNote.TransportationJob IN(&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsIssueNote.Ref
	|FROM
	|	Document.GoodsIssueNote AS GoodsIssueNote
	|WHERE
	|	GoodsIssueNote.Ref IN(&DocumentsArray)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTransferNote.Ref
	|FROM
	|	Document.GoodsTransferNote AS GoodsTransferNote
	|WHERE
	|	GoodsTransferNote.Ref IN(&DocumentsArray)";
	
	Query.SetParameter("DocumentsArray",DocumentsArray);
	
	DocumentsArray = Query.Execute().Unload().UnloadColumn("Ref");
	
EndProcedure

&AtClient
Procedure NotifyUserAboutSettingOrderStatus(ProcessedItemsCount, TotalCount1, Status)
	
	If ProcessedItemsCount > 0 Then
		
		MessageText = NStr("vi = 'Đối với %ProcessedItemsCount% từ %TotalCount1% đã chọn trong danh sách phiếu giao hàng có đặt trạng thái ""%Status%""';
							|ru = 'Для %ProcessedItemsCount% из %TotalCount1% выделенных в списке ордеров на отгрузку товаров установлен статус ""%Status%""';
							|en = 'Status ""%Status%"" is set for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes'; fa = 'Status ""%Status%"" is set for %ProcessedItemsCount% out of %TotalCount1% selected in the list of goods issue notes';
							|it = 'Per %ProcessedItemsCount% da %TotalCount1% dei mandati selezionati nell''elenco per la spedizione delle merci, viene impostato lo stato ""%Status%""';
							|pl = 'Dla %ProcessedItemsCount% z %TotalCount1% wybranych na liście  zleceń do wysyłki towarów jest ustawiony status ""%Status%""';
							|tr = '%ProcessedItemsCount% listesi için %TotalCount1%  seçilen ürün sevkiyatı siparişleri için ""%Status%"" durumu ayarlanır'");
		MessageText = StrReplace(MessageText, "%ProcessedItemsCount%", ProcessedItemsCount);
		MessageText = StrReplace(MessageText, "%TotalCount1%",        TotalCount1);
		MessageText = StrReplace(MessageText, "%Status%",                 Status);
		TitleText = NStr("vi = 'Đã đặt trạng thái ""%Status%""';
						|ru = 'Статус ""%Status%"" установлен';
						|en = 'Status ""%Status%"" is set'; fa = 'Status ""%Status%"" is set';
						|it = 'Lo stato ""%Status%"" è impostato';
						|pl = 'Ustawiono status ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlandı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	Else
		
		MessageText = NStr("vi = 'Chưa thiết lập trạng thái ""%Status%"" đối với bất kỳ phiếu xuất kho nào';
							|ru = 'Статус ""%Status%"" не установлен ни для одного ордера на отгрузку';
							|en = 'Status ""%Status%"" is not set for any goods issue note'; fa = 'Status ""%Status%"" is not set for any goods issue note';
							|it = 'Lo stato ""%Status%"" non è impostato per alcun mandato di spedizione';
							|pl = 'Status ""%Status%"" nie jest ustawiony ani dla jednego zlecenia do wysyłki';
							|tr = '""%Status%"" durumu herhangi bir sevkiyat siparişi için ayarlanmadı'");
		MessageText = StrReplace(MessageText, "%Status%", Status);
		TitleText = NStr("vi = 'Trạng thái ""%Status%"" chưa đặt';
						|ru = 'Статус ""%Status%"" не установлен';
						|en = 'Status ""%Status%"" is not set'; fa = 'Status ""%Status%"" is not set';
						|it = 'Lo stato ""%Status%"" non è impostato';
						|pl = 'Nie ustawiono statusu ""%Status%""';
						|tr = 'Durum ""%Status%"" ayarlanmadı'");
		TitleText = StrReplace(TitleText, "%Status%", Status);
		ShowUserNotification(TitleText,, MessageText, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtServer
Function FillOrders_WithSelectedProductsServer(DocumentsArray, StatusChange, DocumentStatus = Undefined)
	
	ReplaceTransportationTasksWithReferencesToSpendingOrdersInArray(DocumentsArray);
	
	FillParameters = WarehousesServer.ParametersForFillingOrdersWithSelectedGoods();
	FillParameters.FillMode   = "Plural_";	
	FillParameters.StatusChange  = StatusChange;	
	FillParameters.DocumentStatus   = DocumentStatus;	
	FillParameters.DocumentsArray  = DocumentsArray;	
	
	Return WarehousesServer.FillOrders_WithSelectedProducts(FillParameters);
	
EndFunction

// Parameters:
// 	AdditionalParameters - Structure - contains including:
// 		* Orders_3 - ValueTable - contains including:
// 			** Ref - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsTransferNote -
// 		* UnprocessedOrders -  ValueTable - contains including:
// 			** Ref - DocumentRef.GoodsReceiptNote, DocumentRef.GoodsIssueNote, DocumentRef.GoodsTransferNote -
&AtServer
Procedure AssignTransportationJobServer(TransportationJob, AdditionalParameters)
	
	ProcessedOrders = AdditionalParameters.Orders_3;
	UnprocessedOrders = AdditionalParameters.UnprocessedOrders;
	
	OrdersList = Items.NotesInProgress;
	JobStatus = Common.ObjectAttributeValue(TransportationJob, "Status");
	
	NotifyUsAboutErrorsInTransportTaskSelection(UnprocessedOrders);
	
	StatusShipped = Enums.GoodsIssueNoteStatuses.Shipped_;
	
	For Each WarehouseDocument In ProcessedOrders Do
		
		If WarehouseDocument.Status <> StatusShipped
			And (JobStatus = Enums.StatusesOfTransportationJobs.Sent
				Or JobStatus = Enums.StatusesOfTransportationJobs.Closed) Then
			
			MessageText = NStr("vi = 'Nhiệm vụ vận chuyển đã chọn ở trạng thái ""%JobStatus%"", vì vậy không thể chỉ ra nhiệm vụ đó ở lệnh ""%Document%"" ở trạng thái ""%NoteStatus%"". Hãy thay đổi trạng thái lệnh sang ""%StatusShipped%"".';
								|ru = 'Выбранное задание на перевозку находится в статусе ""%JobStatus%"", поэтому его нельзя указать в ордере ""%Document%"", который находится в статусе ""%NoteStatus%"". Измените статус ордера на ""%StatusShipped%"".';
								|en = 'Selected itinerary has the ""%JobStatus%"" status that is why it cannot be specified in the ""%Document%"" note which has the ""%NoteStatus%"" status. Change the note status to ""%StatusShipped%"".'; fa = 'Selected itinerary has the ""%JobStatus%"" status that is why it cannot be specified in the ""%Document%"" note which has the ""%NoteStatus%"" status. Change the note status to ""%StatusShipped%"".';
								|it = 'Il task di trasporto selezionato è nello stato ""%JobStatus%"", pertanto non può essere indicato nel mandato ""%Document%"", che si trova nello stato ""%NoteStatus%"". Modificare lo stato del mandato in ""%StatusShipped%"".';
								|pl = 'Wybrane zadanie przewozu ma status ""%JobStatus%"", więc nie można go podać w zleceniu ""%Document%"", który ma status ""%NoteStatus%"". Zmień status zlecenia na ""%StatusShipped%"".';
								|tr = 'Seçilen taşıma planı ""%JobStatus%"" durumunda yer almakta, bu yüzden ""%NoteStatus%"" durumundaki""%Document%"" siparişte belirtilemez. Sipariş durumunu ""%StatusShipped%"" değiştir.'");
			MessageText = StrReplace(MessageText, "%JobStatus%", 	JobStatus);
			MessageText = StrReplace(MessageText, "%Document%", 			WarehouseDocument.Ref);
			MessageText = StrReplace(MessageText, "%NoteStatus%", 		WarehouseDocument.Status);
			MessageText = StrReplace(MessageText, "%StatusShipped%", 	StatusShipped);
			
			CommonClientServer.MessageToUser(MessageText);
			Continue;
			
		EndIf;
		
		Try
			DocumentObject = WarehouseDocument.Ref.GetObject();
			
			DocumentObject.Lock();
			
			DocumentObject.TransportationJob 	= TransportationJob;
			DocumentObject.DeliveryProcedure 		= GoodsDelivery.DeliveryOrderInTransportOrder(TransportationJob,
				DocumentObject.Recipient);
			
			DocumentObject.Write(DocumentWriteMode.Write);
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	Items.NotesInProgress.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure NotifyUsAboutErrorsInTransportTaskSelection(UnprocessedOrders)
	
	For Each WarehouseDocument In UnprocessedOrders Do
		
		If Not WarehouseDocument.ShipmentUnderTransportationJob
			Or TypeOf(WarehouseDocument.Ref) <> Type("DocumentRef.GoodsIssueNote") Then
			
			MessageText = NStr("vi = 'Đặt hàng ""%Document%"" không yêu cầu giao hàng.';
								|ru = 'Для ордера ""%Document%"" не требуется доставка.';
								|en = 'Delivery is not required for the ""%Document%"" note.'; fa = 'Delivery is not required for the ""%Document%"" note.';
								|it = 'Il mandato ""%Document%"" non richiede la consegna.';
								|pl = 'Dla zlecenia ""%Document%"" nie jest wymagana dostawa.';
								|tr = '""%Document%"" siparişi teslimat gerektirmiyor.'");
			MessageText = StrReplace(MessageText, "%Document%", WarehouseDocument.Ref);
			
			CommonClientServer.MessageToUser(MessageText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region TaskProcessing

&AtServer
Procedure PrepareProductsForTasks(Val ReferenceArray,
												Repackaging = False)
	
	ParametersStructure = WarehousesServer.StructureOfParametersForCreatingTasksForSelectionAndReplenishment();
	ParametersStructure.Warehouse = Warehouse;
	ParametersStructure.Premise = Premise;
	ParametersStructure.CustomizeGenerationByWorkAreas = CustomizeGenerationByWorkAreas;
	ParametersStructure.LimitByWeight = LimitByWeight;
	ParametersStructure.LimitByVolume = LimitByVolume;
	ParametersStructure.LimitationByWeight = LimitationByWeight;
	ParametersStructure.LimitationByVolume = LimitationByVolume;
	ParametersStructure.WarehouseZone = WarehouseZone;
	ParametersStructure.Performer = Performer;
	ParametersStructure.ByAllReferences = ByAllReferences = 0;
	ParametersStructure.ActionInCaseOfShortageOfPackages = RepackagingJobs; // used only when creating selection tasks
																						// 0 - create only selection tasks
																						// 1 - create selection and repackaging tasks
																						// 2 - create repackaging tasks only.
	If AssignAssignee Then
		ParametersStructure.Performer = Performer;
	EndIf;
	If ByAllReferences <> 0 Then
		ParametersStructure.ReferenceArray = ReferenceArray;
	EndIf;
	
	If Repackaging Then
		WarehousesServer.CreateRepackagingJobs(ParametersStructure);
	Else
		WarehousesServer.CreatePickingJobs(ParametersStructure);
	EndIf;
	SetSelectionsInMainLists();
	Return;
EndProcedure

&AtClient
Procedure CreateTasksOnClient(Repackaging = False)
	
	ClearMessages();
	Cancel = False;
	
	CheckWarehousePremises(Cancel);
	
	If Not Cancel Then
		
		DocumentsArray = New Array;
		
		StateRequiresRecharge = PredefinedValue("Enum.StatesOfGoodsPickingReferences.ReplenishmentIsRequired");
		
		For Each ArrRow In Items.PickingReferences.SelectedRows Do
			DocumentsArray.Add(Items.PickingReferences.RowData(ArrRow).ReferenceOrder);
		EndDo;
		
		If DocumentsArray.Count() > 0 Then
			
			OperationStructure = New Structure;
			OperationStructure.Insert("Premise",Premise);
			OperationStructure.Insert("Warehouse",Warehouse);
			
			ParametersForm = New Structure("Title, Operation, ParameterObject");
			ParametersForm.Insert("Title", "ShipGoodsFromWarehouse");
			ParametersForm.Insert("Operation", ?(Repackaging, "RepackagingJobs", "JobGeneration"));
			ParametersForm.Insert("ParameterObject", OperationStructure);
			
			Response = Undefined;
			
			NotificationParameters = New Structure("Repackaging, DocumentsArray",
				Repackaging,
				DocumentsArray
			);
			CallbackDescription = New CallbackDescription("CreateTasksOnClientCompletion",
				ThisObject,
				NotificationParameters
			);
			
			OpenForm("Document.GoodsPickingPlacement.Form.SettingsForm",
				ParametersForm,ThisForm,,,,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow
			);
			
		Else
			
			MessageText = NStr("vi = 'Để tạo các nhiệm vụ, cần chọn đơn đặt hàng vận chuyển.';
								|ru = 'Для создания заданий необходимо выделить распоряжения на отгрузку.';
								|en = 'To create jobs, you need to select shipping orders.'; fa = 'To create jobs, you need to select shipping orders.';
								|it = 'Per cerare i task è necessario evidenziare disposizioni di scarico.';
								|pl = 'Do utworzenia zadań należy zaznaczyć zamówienia do wysyłki.';
								|tr = 'İş oluşturmak için sevkiyat siparişleri seçilmeli.'");
			ShowMessageBox(, MessageText);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateTasksOnClientCompletion(Result, AdditionalParameters) Export
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.ShipGoodsFromWarehouse.Form.Notification.CreateTasksOnClientCompletion"
	);
	
	Repackaging = AdditionalParameters.Repackaging;
	DocumentsArray = AdditionalParameters.DocumentsArray;
	
	Response = Result;
	If Response = DialogReturnCode.OK Then
		PrepareProductsForTasks(DocumentsArray, Repackaging);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure MonitoringOperationOfBackgroundQueueFormationTasks()
	
	If Not AutomaticallyCreateGoodsIssueNotes Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Warehouse) Then
		Return;
	EndIf;
	
	MonitoringOperationOfBackgroundQueueFormationTasksServer();
	
EndProcedure

&AtServer
Procedure MonitoringOperationOfBackgroundQueueFormationTasksServer()
	
	QueueHasBeenUpdated = False;
	
	Recipients = RecipientsForWhichThereIsNoBackgroundTaskForReissuingOrders(Warehouse, QueueHasBeenUpdated);
	
	If QueueHasBeenUpdated Then
		Items.AutomaticallyCreateGoodsIssueNotes.CurrentPage = Items.PageRequiresManualLaunch;
	ElsIf Recipients.Count() > 0 Then
		Items.AutomaticallyCreateGoodsIssueNotes.CurrentPage = Items.PageProblem;
	Else
		Items.AutomaticallyCreateGoodsIssueNotes.CurrentPage = Items.PageNoProblem;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function RecipientsForWhichThereIsNoBackgroundTaskForReissuingOrders(Warehouse, QueueHasBeenUpdated = False)
	
	Return WarehousesServer.RecipientsForWhichThereIsNoBackgroundTaskForReissuingOrders(Warehouse, QueueHasBeenUpdated);
	
EndFunction

&AtClient
Procedure CheckWarehousePremises(Cancel)
	
	If Not ValueIsFilled(Warehouse) Then
		MessageText = NStr("vi = 'Trước khi thực hiện giao dịch, cần chọn kho.';
							|ru = 'Перед выполнением операции необходимо выбрать склад.';
							|en = 'Before executing the operation it is required to select the warehouse.'; fa = 'Before executing the operation it is required to select the warehouse.';
							|it = 'Prima di eseguire l''operazione è necessario selezionare un magazzino.';
							|pl = 'Przed wykonaniem operacji należy wybrać magazyn.';
							|tr = 'İşlemi gerçekleştirmeden önce bir ambar seçilmeli.'");
		CommonClientServer.MessageToUser(MessageText,,,,Cancel);
	EndIf;
	
EndProcedure

&AtServer
Function  ReduceNotesServer(DocumentsArray)
	
	ArrayOfChangedDocuments = FillOrders_WithSelectedProductsServer(DocumentsArray, False);
	SetSelectionsInMainLists();
	
	Return ArrayOfChangedDocuments;
	
EndFunction

&AtServer
Procedure SetVisibilityOfPremises()
	
	If Items.GroupPages.CurrentPage = Items.GroupPages.ChildItems.GroupShipment
		And ValueIsFilled(DateOfShipment) Then
		UseWarerooms = WarehousesServer.UseWarerooms(Warehouse,DateOfShipment);
	Else
		UseWarerooms = WarehousesServer.UseWarerooms(Warehouse,,False);
	EndIf;
	Items.Premise.Visible                    = UseWarerooms;
	Items.OrdersAreInOperation.Visible       = UseWarerooms;
	
EndProcedure

&AtClient
Procedure SelectionStateOnChange(Item)
		
	SelectionStateWhenChangedOnServer();
	
EndProcedure
	
&AtServer
Procedure SelectionStateWhenChangedOnServer()
	
	UpdateStatesOfSelectionOrders();
	Items.JobsInProgress.Refresh();
	
EndProcedure

&AtServer
Function ThereAreLabeledProductsServer(DocumentRef)
	
	Return (WarehousesLocalization.MarkedProductsAreUsed() And (WarehousesLocalization.DocumentProductsTypes(DocumentRef).Count() > 0));
	
EndFunction

&AtServerNoContext
Function VersionOfReportKitsAccordingToTripOrders(Val Trip)
	
	Variant = Reports.PickingUnderTrip.VersionOfFlightReport(Trip);
	Return Variant;
	
EndFunction

&AtServerNoContext
Function FlightExpenseOrders(Val Trip, Val Warehouse)
	
	QueryText = 
	"SELECT DISTINCT
	|	GoodsForIssue.Recorder AS ExpenseOrder
	|FROM
	|	AccumulationRegister.GoodsForIssue AS GoodsForIssue
	|WHERE
	|	GoodsForIssue.Warehouse = &Warehouse
	|	AND GoodsForIssue.TransportationJob = &Trip
	|	AND GoodsForIssue.Active
	|	AND VALUETYPE(GoodsForIssue.Recorder) = TYPE(Document.GoodsIssueNote)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Trip", Trip);
	Query.SetParameter("Warehouse", Warehouse);
	
	Orders_3 = Query.Execute().Unload().UnloadColumn("ExpenseOrder");
	
	Return Orders_3;
	
EndFunction

#EndRegion

#EndRegion

#Region Performance

&AtClient
Procedure NotesInProgressSelection(Item, RowSelected, Field, StandardProcessing)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.ShipGoodsFromWarehouse.Form.Item.NotesInProgress.Selection");
	
	StandardProcessing = False;
	
	TMCommonUseClient.ChangeElement(Item);
	
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_DateOfShipment" Then
		DateOfShipmentOnChange(Items.DateOfShipment);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
