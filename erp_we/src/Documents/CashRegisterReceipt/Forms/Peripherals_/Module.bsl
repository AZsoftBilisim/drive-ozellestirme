
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	MeaningOpenFormWithConnectedHardware = Common.CommonSettingsStorageLoad("CashRegisterReceipt", "OpenFormWithPeripherals");
	If MeaningOpenFormWithConnectedHardware = Undefined Then
		DontShowAgain = False;
	Else
		DontShowAgain = Not MeaningOpenFormWithConnectedHardware;
	EndIf;
	
	OwnerForm                        = Parameters.UUID;
	ConnectEquipmentOnOpening    = Parameters.ConnectEquipmentOnOpening;
	UsePeripherals = True;
	
	IsFullUser = Users.IsFullUser();
	Items.OpenGroupPeripherals.Visible = IsFullUser;
	Items.GroupOpenCurrentCWPSettings.Visible = IsFullUser;
	
	SupportedPeripheralTypes = Parameters.SupportedPeripheralTypes;
	RetailSales.FillInEquipmentTable(ThisObject, SupportedPeripheralTypes);
	
	Items.EquipmentGroupDeviceManagement.Enabled = Equipment.Count() > 0;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	//EquipmentAttached
	
	If ConnectEquipmentOnOpening Then
		
		CompletionDetails = New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", RetailSalesClient, New Structure("Form", ThisObject));
		EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(CompletionDetails, FormOwner, SupportedPeripheralTypes);
		
	Else
		
		ConnectedEquipmentParameters = EquipmentManagerClient.Peripherals().SoftwareConnectionParameters; // Array of See Catalogs.Peripherals.DeviceData
		
		For Each TSRow In ConnectedEquipmentParameters Do
			
			Filter = New Structure("Ref", TSRow.Ref);
			FoundRows = Equipment.FindRows(Filter);
			For Each StringEquipment In FoundRows Do
				StringEquipment.Attached = 0;
			EndDo;
			
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	If Not Exit Then
		BeforeCloseAtServer();
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenPeripherals(Command)
	
	EquipmentManagerClient.UpdateClientWorkplace();
	
	OpenForm("Catalog.Peripherals.ListForm", , ThisForm);
	
EndProcedure

&AtClient
Procedure OpenTheCurrentCWPSettings(Command)
	
	CurrentCWPSettings = CurrentCWPSettings();
	If ValueIsFilled(CurrentCWPSettings) Then
		ShowValue(Undefined, CurrentCWPSettings);
	Else
		OpenForm("Catalog.CWPSettings.ObjectForm",,ThisForm);
	EndIf;
	
EndProcedure

&AtClient
Procedure Connect(Command)
	
	ClearMessages();
	
	CurrentData = Items.Equipment.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	If CurrentData.Attached = 0 Then
		ShowMessageBox(,NStr("vi = 'Các thiết bị đã được kết nối.';
							|ru = 'Оборудование уже подключено.';
							|en = 'Equipment is already connected.'; fa = 'Equipment is already connected.';
							|it = 'Attrezzatura già collegata.';
							|pl = 'Sprzęt jest już podłączony.';
							|tr = 'Ekipman zaten bağlı.'"));
		Return;
	EndIf;
	
	EquipmentManagerClient.StartConnectingEquipmentById(
		New CallbackDescription("StartConnectingEquipmentByIdCompletion", ThisObject, CurrentData),
		FormOwner.UUID,
		CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure Disconnect(Command)
	
	ClearMessages();
	
	CurrentData = Items.Equipment.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(,NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chỉ ra!';
							|ru = 'Команда не может быть выполнена для указанного объекта!';
							|en = 'Cannot execute this command for the specified object.'; fa = 'Cannot execute this command for the specified object.';
							|it = 'Il comando non può essere eseguito per oggetto indicato!';
							|pl = 'Nie można wykonać polecenia dla wskazanego obiektu!';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'"));
		Return;
	EndIf;
	
	If CurrentData.Attached = 1 Then
		ShowMessageBox(,NStr("vi = 'Các thiết bị không được kết nối.';
							|ru = 'Оборудование не подключено.';
							|en = 'Equipment not connected.'; fa = 'Equipment not connected.';
							|it = 'Attrezzatura non collegata.';
							|pl = 'Sprzęt nie jest jeszcze podłączony.';
							|tr = 'Ekipman bağlı değil'"));
		Return;
	EndIf;
	
	EquipmentManagerClient.Start_DisablingEquipmentById(
		New CallbackDescription("Start_DisablingEquipmentByIdCompletion", ThisObject, CurrentData),
		FormOwner.UUID,
		CurrentData.Ref);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServerNoContext
Function CurrentCWPSettings()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	CWPSettings.Ref
	|FROM
	|	Catalog.CWPSettings AS CWPSettings
	|WHERE
	|	CWPSettings.Workplace = &Workplace";
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		Return Selection.Ref;
		
	Else
		
		Return Catalogs.CWPSettings.EmptyRef();
		
	EndIf;
	
EndFunction

&AtServer
Procedure BeforeCloseAtServer()
	
	Common.CommonSettingsStorageSave("CashRegisterReceipt", "OpenFormWithPeripherals", Not DontShowAgain);
	
EndProcedure

// Start connecting equipment by the completion ID.
// 
// Parameters:
//  Data - Structure - Connection result
//  TSRow - FormDataCollectionItem:
//		Link - Reference link.Pluggable equipment - 
&AtClient
Procedure StartConnectingEquipmentByIdCompletion(Data, TSRow) Export

	If Not Data.Result Then
		
		RetailSalesClient.ReportErrorOfOperationOnDevice(TSRow.Ref, "ConnectingDevice", Data.ErrorDescription,
						CommonClientServer.PathToTabularSection("Equipment", Equipment.IndexOf(TSRow) + 1, "Presentation"));
		
		TSRow.Attached = 1;
		
	Else
		
		TSRow.Attached = 0;
		
	EndIf;
	
	Notify("EquipmentAttached", New Structure("HardwareId,Attached", TSRow.Ref, TSRow.Attached), ThisObject);
	
EndProcedure

// Start disabling equipment by the completion ID.
// 
// Parameters:
//  Data - Structure - Connection result
//  TSRow - FormDataCollectionItem:
//		Link - Reference link.Pluggable equipment - 
&AtClient
Procedure Start_DisablingEquipmentByIdCompletion(Data, TSRow) Export

	If Not Data.Result Then
		
		RetailSalesClient.ReportErrorOfOperationOnDevice(TSRow.Ref, "DisablingDevice", Data.ErrorDescription,
						CommonClientServer.PathToTabularSection("Equipment", Equipment.IndexOf(TSRow) + 1, "Presentation"));
		
	Else
		
		TSRow.Attached = 1;
		
	EndIf;
	
	Notify("EquipmentAttached", New Structure("HardwareId,Attached", TSRow.Ref, TSRow.Attached), ThisObject);
	
EndProcedure

#EndRegion

#EndRegion
