
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	TypeOfEquipmentOfFiscalDevice = Common.ObjectAttributeValue(Object.FiscalDevice, "EquipmentType");
	ThisIsTravelingCashRegisterOfKKM = False;
	If TypeOf(Object.CashRegister) = Type("CatalogRef.CashRegisters") Then
		ThisIsTravelingCashRegisterOfKKM = Common.ObjectAttributeValue(Object.CashRegister, "ItinerantTrade") = True;
	EndIf;
	
	ManagingElementVisibility();
	ManagingItemAvailability(ThisObject);
	
	If Parameters.Property("OpenShiftReportsTab") Then
		Items.GroupData.CurrentPage = Items.GroupReportsPerShift;
	EndIf;
	
	RegisterShiftsOverridable.DocumentFormWhenCreatedOnServer(ThisObject);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	XMLString = CurrentObject.FDOnShiftEndClosing.Get();
	If XMLString = Undefined Or Not TypeOf(XMLString) = Type("String") Or XMLString = "" Then
		AllFiscalDataIsAvailable = False;
	Else
		AllFiscalDataIsAvailable = True;
	EndIf;
	
	TransactionOnRegisterShiftEndClosing = Constants.TransactionOnRegisterShiftEndClosing.Get();
	
	SetDynamicListSelections();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	SetDynamicListSelections();
	
EndProcedure

&AtClient
Procedure ListOfReportsPerShiftSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
		
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FullFiscalData(Command)
	
	ParametersForOpeningAllData = New Structure();
	ParametersForOpeningAllData.Insert("CashRegisterShift", Object.Ref);
	
	OpenForm("Document.CashRegisterShift.Form.FiscalDataForm", ParametersForOpeningAllData,,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CloseShift(Command)
	
	If Modified Then
		
		QueryText = NStr("vi = 'Trước khi đóng phiên, sẽ ghi chứng từ. Tiếp tục?';
						|ru = 'Перед закрытием смены документ будет записан. Продолжить?';
						|en = 'The document will be saved before shift closure. Continue?'; fa = 'The document will be saved before shift closure. Continue?';
						|it = 'Prima della chiusura di turno il documento verrà registrato. Continuare?';
						|pl = 'Przed zamknięciem zmiany dokument będzie zapisany. Kontynuować?';
						|tr = 'Vardiya kapanmadan önce belge kaydedilecektir. Devam edilsin mi?'");
		ResponseDescription = New CallbackDescription("CloseShiftAfterRecordingConfirmation", ThisObject);
		ShowQueryBox(ResponseDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		CloseShiftExecute();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseShiftAfterRecordingConfirmation(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CloseShiftExecute();
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseShiftExecute()
	
	ClearMessages();
	
	SelectionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(True, , DeviceID());
	AdditionalParameters = New Structure("Command", "CloseShift");
	
	If Not SelectionResult.Result Then
		CommonClient.MessageToUser(SelectionResult.ErrorDescription);
		Return;
	EndIf;
	
	NotificationOnCompletion = New CallbackDescription("CloseShiftAfterClosingShift", ThisObject);
	FiscalDevice = SelectionResult.DeviceID;
	Context = New Structure;
	Context.Insert("FiscalDevice",         FiscalDevice);
	Context.Insert("CallbackDescriptionCompletion", NotificationOnCompletion);
	
	CurCurrentCashier = EquipmentManagerClientServer.CurCurrentCashierForFiscalTransactions();
	
	OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersForOpeningClosingShift();
	OperationParametersList.Cashier    = CurCurrentCashier.Cashier;
	OperationParametersList.CashierTIN = CurCurrentCashier.CashierTIN;
	
	PeripheralsReceiptPrintersClient.StartClosingShiftOnFiscalDevice(
				New CallbackDescription("AfterExecutingShiftCloseCommand", RetailSalesClient, Context),
					UUID, FiscalDevice, OperationParametersList);

EndProcedure

&AtServer
Function DeviceID()
	Return Common.ObjectAttributeValue(Object.Ref, "FiscalDevice");
EndFunction

&AtClient
Procedure CloseShiftAfterClosingShift(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult Then
		
		ShowUserNotification(
			NStr("vi = 'Đã đóng phiên thu ngân';
				|ru = 'Кассовая смена закрыта';
				|en = 'POS shift is closed'; fa = 'POS shift is closed';
				|it = 'Il turno di cassa è chiuso';
				|pl = 'Zamknięto zmianę kasową';
				|tr = 'Kasa vardiyası kapandı.'")
			,
			,
			,
			PictureLib.ExecuteTask);
		
		Read();
		
	Else
		
			ShowUserNotification(
			NStr("vi = 'Lỗi đóng phiên thu ngân';
				|ru = 'Ошибка закрытия кассовой смены';
				|en = 'An error occurred while closing the POS shift'; fa = 'An error occurred while closing the POS shift';
				|it = 'Errore durante la chiusura del turno di cassa';
				|pl = 'Błąd zamknięcia zmiany kasowej';
				|tr = 'Kasa vardiyasının kapanışında hata'")
			,
			,
			,
			PictureLib.Delete);
		
	EndIf;
	
	ManagingItemAvailability(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
// Controls the availability of Form elements
// Parameters:
//  Form - Application formaclientsthat
//
Procedure ManagingItemAvailability(Form)
	
	StatusOfShiftIsOpen = Form.Object.Status = PredefinedValue("Enum.CashRegisterShiftStatuses.IsOpen");
	Form.Items.SettlementAddress.Enabled =  StatusOfShiftIsOpen;
	Form.Items.PlaceOfSettlement.Enabled =  StatusOfShiftIsOpen;
	Form.Items.FormCloseShift.Enabled = StatusOfShiftIsOpen;
	
	RefillRSP = Form.TransactionOnRegisterShiftEndClosing <> PredefinedValue("Enum.TransactionsOnRegisterShiftEndClosing.DeleteCashRegisterReceipts");
	Form.Items.GlobalFormCommands.Enabled = RefillRSP;
	
EndProcedure

&AtServer
Procedure ManagingElementVisibility()
	
	Items.GroupFiscalData.Visible = TypeOfEquipmentOfFiscalDevice = Enums.PeripheralTypes.CREWithDataTransfer;
	Items.FullFiscalData.Visible = Not Object.Status = Enums.CashRegisterShiftStatuses.IsOpen;
	Items.FullFiscalData.Visible = AllFiscalDataIsAvailable;
	Items.SettlementAddress.Visible = ThisIsTravelingCashRegisterOfKKM;
	Items.PlaceOfSettlement.Visible = ThisIsTravelingCashRegisterOfKKM;
	
EndProcedure
#Region Filters

&AtServer
Procedure SetDynamicListSelections()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfReportsPerShift,
		"CashRegisterShift",
		Object.Ref,
		DataCompositionComparisonType.Equal,
		,
		True);
		
EndProcedure

#EndRegion

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
