
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TMCommonUse.CustomizePeripherals(ThisForm);
	
	Warehouse     = Parameters.Warehouse;
	Premise = Parameters.Premise;
	
	WarehouseIDOfPremises = String(Warehouse.UUID()) + String(Premise.UUID());
	
	Settings = Common.CommonSettingsStorageLoad("FormSpecifyingFormSettingCell"+WarehouseIDOfPremises, "");
 	If Settings <> Undefined Then
 		If Settings.Property("CellSelectionHistory") Then	
			Items.Cell.ChoiceList.LoadValues(Settings.CellSelectionHistory);		
		EndIf;
 		If Settings.Property("SelectedCell") Then	
			Cell = Settings.SelectedCell; 	
		EndIf;
    EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Cell) Then
		MessageText = NStr("vi = 'Hãy chỉ ra ô.';
							|ru = 'Укажите ячейку.';
							|en = 'Specify a storage bin.'; fa = 'Specify a storage bin.';
							|it = 'Specificare la cella.';
							|pl = 'Wskaż komórkę.';
							|tr = 'Hücre belirt.'");
		
		CommonClientServer.MessageToUser(MessageText,,"Cell");
	Else
		WarehouseIDOfPremises = String(Warehouse.UUID()) + String(Premise.UUID());
		
		SelectionListsClientServer.UpdateSelectionList(Items.Cell.ChoiceList, Cell, 7);
		ClosingParameters = New Structure;
		ClosingParameters.Insert("CellSelectionHistory", Items.Cell.ChoiceList.UnloadValues());
		ClosingParameters.Insert("SelectedCell", Cell);
		
		CommonSettingsStorageSave(WarehouseIDOfPremises, ClosingParameters);
		Close(Cell);
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure CommonSettingsStorageSave(WarehouseIDOfPremises, ClosingParameters)
	
	Common.CommonSettingsStorageSave("FormSpecifyingFormSettingCell" + WarehouseIDOfPremises, "", ClosingParameters);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close(Undefined);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Data)
	
	Managers = New Array();
	Managers.Add(Catalogs.StorageBins);
	ReferencesArrray = BarcodingOfPrintForms.GetLinkFromBarcodeOfTabularDocument(Data.Barcode, Managers);
	
	If ReferencesArrray.Count() > 0 Then
    	Cell = ReferencesArrray[0];
	Else
		MessageText = NStr("vi = 'Ô hàng có mã vạch %Barcode% không tìm thấy';
							|ru = 'Складская ячейка со штрихкодом %Barcode% не найдена';
							|en = 'Storage bin with barcode %Barcode% is not found'; fa = 'Storage bin with barcode %Barcode% is not found';
							|it = 'La cella di stoccaggio del codice a barre %Barcode% non è stata trovata';
							|pl = 'Nie znaleziono komórki magazynowej z kodem kreskowym %Barcode%';
							|tr = 'Barkodlu %Barcode% depo yeri bulunamadı'");
	    MessageText = StrReplace(MessageText,"%Barcode%",Data.Barcode);
		
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
