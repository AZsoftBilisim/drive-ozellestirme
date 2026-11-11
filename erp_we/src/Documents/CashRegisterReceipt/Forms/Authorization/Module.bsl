
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SupportedPeripheralTypes = "BarcodeScanner,MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisForm, SupportedPeripheralTypes);
	Activate();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not CloseForm And Not Exit Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisForm);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetUserByBarcode(Barcode)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	UserIdentityDetails.User AS User
	|FROM
	|	InformationRegister.UserIdentityDetails AS UserIdentityDetails
	|WHERE
	|	UserIdentityDetails.Barcode = &Barcode");
	
	Query.SetParameter("Barcode", Barcode);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.User;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

&AtServer
Function GetUserByMagneticCode(MagneticCode)
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT TOP 1
	|	UserIdentityDetails.User AS User
	|FROM
	|	InformationRegister.UserIdentityDetails AS UserIdentityDetails
	|WHERE
	|	UserIdentityDetails.MagneticCode = &MagneticCode");
	
	Query.SetParameter("MagneticCode", MagneticCode);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		Return Selection.User;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#Region BarcodesAndTradeEquipment

// ExternalEquipmentMechanism
&AtClient
Procedure ProcessBarcodes(BarcodeData_1)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_1) Then
		Return;
	EndIf;
	
	User = GetUserByBarcode(BarcodeData_1[0].Barcode);
	If ValueIsFilled(User) Then
		AttachIdleHandler("SelectUser", 0.1, True);
	Else
		ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy người sử dụng.';
										|ru = 'Пользователь не обнаружен.';
										|en = 'User is not found.'; fa = 'User is not found.';
										|it = 'Utente non identificato';
										|pl = 'Nie znaleziono użytkownika.';
										|tr = 'Kullanıcı tespit edilmedi.'"));
	EndIf;
	
EndProcedure
// End ExternalEquipmentMechanism

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	ListOfCodes = New ValueList;
	
	DecryptedData = Data[1][3];
	If DecryptedData <> Undefined Then
		For Each Structure In DecryptedData Do
			
			MagneticStripeCardTemplate = Structure.Template;
			CardCode             = Undefined;
			For Each FieldData In Structure.TrackData Do
				If FieldData.Field = PredefinedValue("Enum.MagneticStripeCardTemplateFields.Code") Then
					ListOfCodes.Add(FieldData.Simple);
				EndIf;
			EndDo;
			
		EndDo;
	EndIf;
	
	If ListOfCodes.Count() = 1 Then
		MagneticCode = ListOfCodes.Get(0).Value;
	ElsIf ListOfCodes.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Mã thẻ không tương ứng với một trong các khuôn mẫu thẻ từ.';
										|ru = 'Код карты не соответствует ни одному из шаблонов магнитных карт.';
										|en = 'Card code matches no templates of magnetic stripe cards.'; fa = 'Card code matches no templates of magnetic stripe cards.';
										|it = 'Il codice della carta non corrisponde a nessuno dei modelli delle carte magnetiche.';
										|pl = 'Kod karty nie odpowiada żadnemu szablonowi kart magnetycznych.';
										|tr = 'Kart kodu manyetik kart şablonlarından hiçbiriyle eşleşmiyor.'"));
		Return;
	Else
		ValueSelected = Undefined;

		ListOfCodes.ShowChooseItem(New CallbackDescription("ProcessMagneticCardReaderDataCompletion", ThisObject), NStr("vi = 'Chọn mã thẻ từ';
																														|ru = 'Выбор кода магнитной карты';
																														|en = 'Select magnetic stripe card code'; fa = 'Select magnetic stripe card code';
																														|it = 'Scelta del codice della carta magnetica';
																														|pl = 'Wybór kodu karty magnetycznej';
																														|tr = 'Manyetik şeritli kartın kodunu seçin'"));
        Return;
	EndIf;
	
	ProcessMagneticCardReaderDataFragment(MagneticCode);
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderDataCompletion(SelectedElement, AdditionalParameters) Export
    
    ValueSelected = SelectedElement;
    If ValueSelected <> Undefined Then
        MagneticCode = ValueSelected.Value;
    EndIf;
    
    ProcessMagneticCardReaderDataFragment(MagneticCode);

EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderDataFragment(Val MagneticCode)
    
    User = GetUserByMagneticCode(MagneticCode);
    If ValueIsFilled(User) Then
        AttachIdleHandler("SelectUser", 0.1, True);
    Else
        ShowMessageBox(Undefined, NStr("vi = 'Không tìm thấy người sử dụng.';
										|ru = 'Пользователь не обнаружен.';
										|en = 'User is not found.'; fa = 'User is not found.';
										|it = 'Utente non identificato';
										|pl = 'Nie znaleziono użytkownika.';
										|tr = 'Kullanıcı tespit edilmedi.'"));
    EndIf;

EndProcedure

&AtClient
Procedure SelectUser()
	
	CloseForm = True;
	Notify("UserIsAuthorized", New Structure(
		"OwnerForm, User, Mode", ThisForm.FormOwner.UUID, User, "ChangeRights"));
	Close();
	
EndProcedure

&AtClient
Procedure CloseCashReceipt(Command)
	
	CloseForm = True;
	Notify("UserIsAuthorized",
		New Structure(
			"OwnerForm, User, Mode",,
			User,
			"CloseCashReceipt"));
			
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
