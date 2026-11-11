
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	#Region Filters
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "ReferenceOrder", ReferenceOrder, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Department", Department, QuickFilterStructure);
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "Status", Status, QuickFilterStructure);
	
	#EndRegion
	
	#Region UniversalMechanisms
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// Peripherals
	TMCommonUse.CustomizePeripherals(ThisForm);
	// End Peripherals
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommands);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// Peripherals
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, "BarcodeScanner");
	// End Peripherals
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	// Peripherals
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	// End Peripherals
	
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
	
	If EventName = "Write_ProductionStages" Then
		// StandardSubsystems.AttachableCommands
		AttachableCommandsClient.StartCommandUpdate(ThisObject);
		// End StandardSubsystems.AttachableCommands
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Var FiltersStructure;
	
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		
		If FiltersStructure.Property("Department") Then
			Settings.Insert("Department", FiltersStructure.Department)
		EndIf;
		
	EndIf;
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", Department, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrderSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "ReferenceOrder", ReferenceOrder, DataCompositionComparisonType.Equal,, ValueIsFilled(ReferenceOrder));
	
EndProcedure

&AtClient
Procedure DepartmentFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Department", Department, DataCompositionComparisonType.Equal,, ValueIsFilled(Department));
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status", Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
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

#Region EventHandlersForListTableElements

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Universal_

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

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

&AtClient
Procedure ChangeAStage(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	ShowValue(, SelectedStages[0]);

EndProcedure

&AtClient
Procedure ChangeStageChain(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		ProductionManagementClient.OpenStageChainEditingForm(
			RowData.ReferenceOrder,
			RowData.ProductionLot,,
			ThisForm);
		
	EndIf;

EndProcedure

&AtClient
Procedure ChangeBatch(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			New Structure("ProductionLot, Stage", RowData.ProductionLot, RowData.Ref),
			ThisForm,
			RowData.ProductionLot);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SplitParty(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionLot", RowData.ProductionLot);
		FormParameters.Insert("Stage", RowData.Ref);
		FormParameters.Insert("Split", True);
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			FormParameters,
			ThisObject,
			"" + RowData.ProductionLot.UUID() + "_Split");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RecordDefectiveGoods(Command)
	
	SelectedStages = SelectedStages();
	
	If SelectedStages.UBound() = -1 Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(SelectedStages[0]);
	
	If RowData <> Undefined Then
		
		If RowData.ProductionProcessType 
				= PredefinedValue("Enum.ProductionProcessTypes.WithoutBillsOfMaterials") Then
			ClearMessages();
			CommonClient.MessageToUser(
				NStr("vi = 'Đối với các công đoạn đơn hàng với quy trình sản xuất loại ""Không có bảng kê chi tiết các nguồn lực sản xuất"", không thể thay đổi lô';
					|ru = 'Для этапов заказа с типом производственного процесса ""Без спецификаций"" изменение партии недоступно';
					|en = 'For order stages with ""No BOM"" production process type, lot change is not available'; fa = 'For order stages with ""No BOM"" production process type, lot change is not available';
					|it = 'Per le fasi dell''ordine con il tipo di processo di produzione ""Senza specifiche"" non è possibile modificare i lotti';
					|pl = 'Dla etapów zamówienia o typie procesu produkcyjnego ""Bez specyfikacji"" zmiana partii jest niedostępna';
					|tr = '""Ürün Reçetesiz"" üretim süreci türü olan sipariş aşaması için lot değişikliği mevcut değil'"));
			Return;
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("ProductionLot", RowData.ProductionLot);
		FormParameters.Insert("Stage", RowData.Ref);
		FormParameters.Insert("RecordDefectiveGoods", True);
		
		OpenForm(
			"DataProcessor.ProductionLotDivision.Form.Workplace",
			FormParameters,
			ThisObject,
			"" + RowData.ProductionLot.UUID() + "_DefectiveGoods");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List", "Date");

EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.ProductionStage2_2);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Data)
	
	Ref = LinkToListItemByBarcode(Data.Barcode);
	If Ref <> Undefined Then
		Items.List.CurrentRow = Ref;
		ShowValue(Undefined, Ref);
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Return ProductionManagementClient.LinkToProductionStageByBarcode(Barcode);
	
EndFunction

&AtClient
Function SelectedStages()

	Return TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);

EndFunction

#EndRegion
