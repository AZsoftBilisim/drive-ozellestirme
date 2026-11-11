
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ConfigureDependentFormElements();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetFilters(ThisObject);

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
Procedure FilterStatusOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterAssetOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterOperatingBusinessUnitOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterClassOnChange(Item)
	
	SetFilters(ThisObject);

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

&AtClient
Procedure GenerateBarcodes(Command)
	
	If Items.List.SelectedRows.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Cần chọn nút';
								|ru = 'Необходимо выбрать узлы';
								|en = 'Select sub-assets'; fa = 'Select sub-assets';
								|it = 'È necessario selezionare i nodi';
								|pl = 'Należy wybrać węzły';
								|tr = 'Alt varlıklar seçilmeli'"));
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Khởi tạo mã vạch đối với các nút đã chọn?';
					|ru = 'Сгенерировать штрихкоды для выбранных узлов?';
					|en = 'Generate barcodes for selected sub-assets?'; fa = 'Generate barcodes for selected sub-assets?';
					|it = 'Generare codici a barre per i nodi selezionati?';
					|pl = 'Wygenerować kody kreskowe dla wybranych węzłów?';
					|tr = 'Seçilen alt varlıklar için barkodlar oluşturulsun mu?'");
	CallbackDescription = New CallbackDescription("GenerateBarcodesCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);

EndProcedure

#Region StandardSubsystems

// StandardSubsystems.AttachableCommands

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion

#Region Private

#Region StandardSubsystems

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ConfigureDependentFormElements()
	
	If Not AccessRight("Edit", Metadata.Catalogs.SubAssets) Then
		Items.GenerateBarcodes.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	List = Form.List;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Status",
		Form.FilterStatus,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterStatus));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner",
		Form.FilterAsset,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterAsset));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner.OperatingBusinessUnit",
		Form.FilterOperatingBusinessUnit,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterOperatingBusinessUnit));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Class",
		Form.FilterClass,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterClass));
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	Result = FindNodeByBarcode(BarcodeData_5);
	If Result = Undefined Then
		ShowMessageBox(, NStr("vi = 'Không thể tìm thấy nút theo mã vạch';
								|ru = 'Не удалось найти узел по штрихкоду';
								|en = 'Cannot find a sub-asset using the barcode'; fa = 'Cannot find a sub-asset using the barcode';
								|it = 'Non è stato possibile trovare il nodo per codice a barre';
								|pl = 'Nie udało się znaleźć węzła wg kodu kreskowego';
								|tr = 'Barkoda ilişkin alt varlık bulunamadı'"));
		Return;
	EndIf;
	
	Items.List.CurrentRow = Result;
	ShowValue(, Result);
	
EndProcedure

&AtServer
Function FindNodeByBarcode(Val BarcodeData_5)
	
	Result = RMManagement.FindNodesByBarcodes(BarcodeData_5);
	If Result.ObjectsArray.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	Return Result.ObjectsArray[0];
	
EndFunction

&AtClient
Procedure GenerateBarcodesCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RMManagementClient.GenerateNodeBarcodes(Items.List.SelectedRows);
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

#EndRegion

#EndRegion