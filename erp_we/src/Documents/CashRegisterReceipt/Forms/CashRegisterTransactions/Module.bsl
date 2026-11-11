#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CloseTheFormOnceTheTransactionIsCompleted = Common.CommonSettingsStorageLoad("Documents.CashRegisterReceipt.Form.SKKMOperationsMenu", "CloseTheFormOnceTheTransactionIsCompleted", False);
	
	Cashier = Parameters.Cashier;
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Cashier);
	
	CashRegister = Parameters.CashRegister;
	WhenChangingCashRegister();
	
	ConfigureCWP();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveSettingsWhenClosing And Not Exit Then
		ShouldSaveSettings();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure CloseTheFormOnceTheTransactionIsCompletedOnChange(Item)
	SaveSettingsWhenClosing = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeTheCashRegisterOfTheKKM(Command)
	
	Filter = New Structure("Ref", AvailableCashRegisters);
	OpeningParameters = New Structure("Filter", Filter);
	
	OpenForm(
		"Catalog.CashRegisters.ChoiceForm",
		OpeningParameters,,,,,
		New CallbackDescription("AfterChangingCashRegister", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CloseRegisterShift(Command)
	
	ClearMessages();
	
	RetailSalesClient.CloseRegisterShift(
		CashRegisterParameters,
		New CallbackDescription("AfterCompletionOfCashShiftOperation", ThisObject));
	
EndProcedure

&AtClient
Procedure OpenRegisterShift(Command)
	
	ClearMessages();
	
	RetailSalesClient.OpenRegisterShift(
		CashRegisterParameters,
		New CallbackDescription("AfterCompletionOfCashShiftOperation", ThisObject));
	
	EndProcedure
	
&AtClient
Procedure PrintReportWithoutClearance(Command)
	ClearMessages();
	
	RetailSalesClient.GenerateReportWithoutCancellation(
		CashRegisterParameters,
		New CallbackDescription("AfterReportIsGeneratedWithoutCancellation", ThisObject)); 
		
EndProcedure

&AtClient
Procedure DepositCash(Command)
	
	ClearMessages();
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("DepositingFundsAfterProcessingShiftState", ThisObject));
	
EndProcedure

&AtClient
Procedure CashWithdrawal(Command)
	
	ClearMessages();
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("WithdrawalOfFundsAfterProcessingStateOfShift", ThisObject));
	
EndProcedure

&AtClient
Procedure OpenCashDrawer(Command)
	
	ClearMessages();
	
	PeripheralsReceiptPrintersClient.StartOpeningCashDrawer(
		New CallbackDescription("AfterCompletingOperationOfOpeningCashDrawer", ThisObject),
		UUID,
		CashRegisterParameters.DeviceID);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure UpdateFormHeaders(Form)
	
	Form.StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Form.CashRegister);
	
	Form.Items.OpenRegisterShift.Enabled = Form.AccessRights.OpenShift And Not Form.StructureRegisterShiftState.ShiftIsOpened;
	Form.Items.CloseRegisterShift.Enabled = Form.AccessRights.CloseShift And    Form.StructureRegisterShiftState.ShiftIsOpened;
	
	Form.Items.DepositCash.Enabled = Form.AccessRights.DepositingMoney;
	Form.Items.CashWithdrawal.Enabled   = Form.AccessRights.WithdrawalOfMoney;
	
	If ValueIsFilled(Form.CashRegister) Then
		Form.Items.CashRegisterGroupOfOperationsWithCashRegister.Title = String(Form.CashRegister);
	EndIf;
	
	If ValueIsFilled(Form.StructureRegisterShiftState.CashRegisterShiftStatus) Then
		
		TitleOfCashShiftOperationsGroup = NStr("vi = 'Trạng thái thay đổi:%ShiftStatus% %Modified%';
												|ru = 'Статус смены: %ShiftStatus% %Modified%';
												|en = 'Shift status: %ShiftStatus% %Modified%'; fa = 'Shift status: %ShiftStatus% %Modified%';
												|it = 'Stato turni: %ShiftStatus%%Modified%';
												|pl = 'Status zmiany: %ShiftStatus% %Modified%';
												|tr = 'Vardiya durumu: %ShiftStatus% %Modified%'");
		
		TitleOfCashShiftOperationsGroup = StrReplace(TitleOfCashShiftOperationsGroup, "%ShiftStatus%", Form.StructureRegisterShiftState.CashRegisterShiftStatus);
		TitleOfCashShiftOperationsGroup = StrReplace(TitleOfCashShiftOperationsGroup, "%Modified%", Format(Form.StructureRegisterShiftState.StatusChangeDate, NStr("vi = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																																									|ru = 'ДФ=''dd.MM.yy HH:mm''';
																																									|en = 'DF=''MM/dd/yy HH:mm'''; fa = 'DF=''MM/dd/yy HH:mm''';
																																									|it = 'FD=''gg.MM.aa HH:mm''';
																																									|pl = 'DF=''dd.MM.yy HH:mm''';
																																									|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
		
	Else
		
		TitleOfCashShiftOperationsGroup = NStr("vi = 'Chưa mở phiên làm việc';
												|ru = 'Смена не открыта';
												|en = 'Shift is not opened'; fa = 'Shift is not opened';
												|it = 'Turno non aperto';
												|pl = 'Zmiana nie otwarta';
												|tr = 'Vardiya açılmadı.'");
		
	EndIf;
	Form.Items.CashShiftOperationsGroup.Title = TitleOfCashShiftOperationsGroup;
	
	GroupTitleMoneyTransactions = NStr("vi = 'Tại quỹ %CashOnHand% %Currency%';
										|ru = 'В кассе %CashOnHand% %Currency%';
										|en = 'Cash register balance: %CashOnHand% %Currency%'; fa = 'Cash register balance: %CashOnHand% %Currency%';
										|it = 'In casse %CashOnHand% %Currency%';
										|pl = 'W ksaie %CashOnHand% %Currency%';
										|tr = 'Kasada %CashOnHand% %Currency%'");
	
	CashOnHand_ = Format(Form.StructureRegisterShiftState.CashOnHand, "NFD=2; NZ=0");
	GroupTitleMoneyTransactions = StrReplace(GroupTitleMoneyTransactions, "%CashOnHand%", CashOnHand_);
	GroupTitleMoneyTransactions = StrReplace(GroupTitleMoneyTransactions, "%Currency%", Form.StructureRegisterShiftState.CurrencyPresentation);
	Form.Items.GroupTransactions.Title = GroupTitleMoneyTransactions;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Common.CommonSettingsStorageSave("Documents.CashRegisterReceipt.Form.SKKMOperationsMenu", "CloseTheFormOnceTheTransactionIsCompleted", CloseTheFormOnceTheTransactionIsCompleted);
	
EndProcedure

&AtServer
Procedure ConfigureCWP()
	
	RestrictAvailableCashRegistersToOneCompany = (Parameters.Property("RestrictAvailableCashRegistersToOneCompany") 
		And Parameters.RestrictAvailableCashRegistersToOneCompany = True);
	
	GeneratingFiscalChecksServer.FillInAvailableCashRegisterSalesRegisters(AvailableCashRegisters, CashRegister, RestrictAvailableCashRegistersToOneCompany);
	
	Items.ChangeTheCashRegisterOfTheKKM.Visible = AvailableCashRegisters.Count() > 1 And Parameters.ChangeTheCashRegisterOfTheKKM;
	Items.OpenCashDrawer.Visible = Not CashRegisterParameters.UseWithoutConnectingPeripherals;
	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenChangingCashRegister()
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(CashRegister);
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(CashRegister));
	UpdateFormHeaders(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterCompletingOperationOfOpeningCashDrawer(ExecutionResult, AdditionalParameters) Export
	
	If Not ExecutionResult.Result Then  
		InformationTitle = NStr("vi = 'Khi mở hộp tiền, đã xảy ra lỗi.';
								|ru = 'При открытии денежного ящика возникла ошибка.';
								|en = 'An error occurred while opening the cash till'; fa = 'An error occurred while opening the cash till';
								|it = 'Si è verificato un errore all''apertura della cassetto contanti.';
								|pl = 'Wystąpił błąd podczas otwierania szuflady na gotówkę.';
								|tr = 'Kasa çekmecesi açılırken bir hata oluştu.'");
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterChangingCashRegister(SelectedCashRegister, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedCashRegister) Then
		Return;
	Else
		
		NotificationParameters = New Structure("SelectedCashRegister", SelectedCashRegister);	
		CallbackOnCompletion = New CallbackDescription("ApplyChangingOfCashRegisterCashAccount", ThisObject, NotificationParameters);
		
		If TypeOf(FormOwner) = Type("ClientApplicationForm") 
			And TypeOf(FormOwner.Object.Ref) = Type("DocumentRef.CashRegisterReceiptReturn")
			And ValueIsFilled(FormOwner.Object.CashRegisterReceipt)
			And FormOwner.Object.CashRegister <> SelectedCashRegister Then
		
			StateOfNewPOSShift = RetailSalesServerCall.RegisterShiftState(SelectedCashRegister);
			If FormOwner.CashRegisterReceiptDetails.CashRegisterShift <> StateOfNewPOSShift.CashRegisterShift
				And FormOwner.CashRegisterReceiptDetails.CashRegisterShiftStatus <> PredefinedValue("Enum.CashRegisterShiftStatuses.Closed_") Then
				
				QueryText = NStr("vi = 'Còn chưa đóng phiên thu ngân của phiếu bán. 
									|Nếu sẽ đóng phiên thu ngân theo quầy thu ngân được chọn trước phiên thu ngân của phiếu bán thì điều này có thể dẫn đến phản ánh sai khi ghi nhận dữ liệu về trả lại. Tiếp tục?';
									|ru = 'Кассовая смена чека продажи еще не закрыта. 
									|Если кассовая смена по выбранной кассе ККМ будет закрыта раньше, чем кассовая смена чека продажи, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
									|en = 'The POS shift of the selected sales receipt is not yet closed.
									|If the POS shift of the selected cash register is closed earlier than the POS shift of the sales receipt, this may lead to incorrect recording of the return data in accounting. Continue?'; fa = 'The POS shift of the selected sales receipt is not yet closed.
									|If the POS shift of the selected cash register is closed earlier than the POS shift of the sales receipt, this may lead to incorrect recording of the return data in accounting. Continue?';
									|it = 'Кассовая смена чека продажи еще не закрыта. 
									|Если кассовая смена по выбранной кассе ККМ будет закрыта раньше, чем кассовая смена чека продажи, это может привести к неправильному отражению в учете данных о возврате. Продолжить?';
									|pl = 'The POS shift of the selected sales receipt is not yet closed.
									|If the POS shift of the selected cash register is closed earlier than the POS shift of the sales receipt, this may lead to incorrect recording of the return data in accounting. Continue?';
									|tr = 'Satış fişinin kasa değişimi henüz kapatılmadı. 
									|Seçilen kasanın kasa vardiyasının, satış fişinin kasa vardiyasından önce kapatılması, iade verilerinin muhasebeye hatalı yansımasına neden olabilir. Devam edilsin mi?'");
				ShowQueryBox(CallbackOnCompletion, QueryText, QuestionDialogMode.YesNo);
				Return;
			EndIf;

		EndIf;
		
		RunCallback(CallbackOnCompletion, DialogReturnCode.Yes);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyChangingOfCashRegisterCashAccount(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CashRegister = AdditionalParameters.SelectedCashRegister;
		
		WhenChangingCashRegister();
		
		CallbackDescription = New CallbackDescription("ChangeTheCashRegisterOfTheKKMCompletion", FormOwner);
		
		RunCallback(CallbackDescription, CashRegister);
		
		If CloseTheFormOnceTheTransactionIsCompleted And IsOpen() Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterCompletionOfCashShiftOperation(Result, AdditionalParameters) Export
	
	UpdateFormHeaders(ThisObject);
	
	If CloseTheFormOnceTheTransactionIsCompleted And IsOpen() Then
		Close();
	EndIf;
	
	Notify("ChangingCashShift");
	
EndProcedure 

&AtClient
Procedure AfterReportIsGeneratedWithoutCancellation(Result, AdditionalParameters) Export
	
	UpdateFormHeaders(ThisObject);
	If CloseTheFormOnceTheTransactionIsCompleted And IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure DepositingFundsAfterProcessingShiftState(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
	
	RetailSalesClient.DepositCash(
		ThisObject,
		CashRegisterParameters,
		New CallbackDescription("AfterMakingWithdrawalOfFunds", ThisObject, AdditionalNotificationParameters));
	
EndProcedure

&AtClient
Procedure WithdrawalOfFundsAfterProcessingStateOfShift(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;

	AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
	
	RetailSalesClient.CashWithdrawal(
		ThisObject,
		CashRegisterParameters,
		New CallbackDescription("AfterMakingWithdrawalOfFunds", ThisObject, AdditionalNotificationParameters));
	
EndProcedure

&AtClient
Procedure AfterMakingWithdrawalOfFunds(Result, AdditionalParameters) Export
	
	ResultOfFiscalOperation = Undefined;
	If Result = False 
		And TypeOf(AdditionalParameters) = Type("Structure") 
		And AdditionalParameters.Property("ResultOfFiscalOperation", ResultOfFiscalOperation) 
		And TypeOf(ResultOfFiscalOperation) = Type("Structure")
		And ResultOfFiscalOperation.Property("Result")
		And Not ResultOfFiscalOperation.Result Then
		
		DocumentReference = Undefined;
		AdditionalParameters.Property("DocumentReference", DocumentReference);
		
	EndIf;
	
	UpdateFormHeaders(ThisObject);
	
	If CloseTheFormOnceTheTransactionIsCompleted And IsOpen() Then
		Close();
	EndIf;
	
EndProcedure


#EndRegion