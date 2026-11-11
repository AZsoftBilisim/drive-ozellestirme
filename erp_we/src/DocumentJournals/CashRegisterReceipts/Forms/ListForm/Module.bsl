
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If Not GetFunctionalOption("UseSeveralCashRegisters") Then
		CashRegister = Catalogs.CashRegisters.CashRegisterFiscalRegistrarByDefault();
		If Not ValueIsFilled(CashRegister) Then
			Raise NStr("vi = 'Trong cơ sở thông tin chưa tạo quầy thu ngân có kiểu: Máy ghi nhận tiền mặt.
			|Để làm việc với danh sách phiếu tính tiền, trong hệ thống cần có ít nhất một máy ghi nhận tiền mặt.';
			|ru = 'В информационной базе не создано кассы ККМ с типом: Фискальный регистратор.
			|Для работы со списком чеков ККМ в системе должен быть зарегистрирован как минимум один фискальный регистратор.';
			|en = 'Cash register with type ""Fiscal cash register"" is not created in the infobase.
			|At least one fiscal cash register should be registered in the application to operate with the list of receipts.'; fa = 'Cash register with type ""Fiscal cash register"" is not created in the infobase.
			|At least one fiscal cash register should be registered in the application to operate with the list of receipts.';
			|it = 'Nel database informatico non è stata creata alcuna cassa KKM (Macchinari di Registrazione e Controllo) con il tipo: Registratore fiscale.
			|Per lavorare con l''elenco degli scontrini KKM minimo un registratore fiscale deve essere registrato nel sistema.';
			|pl = 'W bazie informacyjnej nie utworzono kasy z typem: Rejestrator fiskalny.
			|Do pracy z listą paragonów kasy w systemie musi być zarejestrowany co najmniej jeden rejestrator fiskalny.';
			|tr = 'Infobase''da şu türde bir yazar kasa oluşturulmamıştır: Mali yazar kasa.
			|Kasa fişleri listesi ile çalışabilmek için sistemde en az bir mali yazar kasa kayıtlı olmalıdır.'");
		EndIf;
	EndIf;
	
	SupportedPeripheralTypes = "BarcodeScanner,
	                                              |CustomerDisplay,
	                                              |FiscalCashRegisters,
	                                              |CREWITHDATATRANSFER,
	                                              |ReceiptPrinter,
	                                              |POSTerminal,
	                                              |DigitalRetailScales,
	                                              |MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisForm);
	RetailSales.FillInEquipmentTable(ThisObject, SupportedPeripheralTypes);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "OpenRegisterShift", "Visible",
		AccessRight("Update", Metadata.Documents.CashRegisterShift) And AccessRight("Update", Metadata.Documents.RetailSalesReport));
	TMCommonUseClientServer.SetFormItemProperty(Items, "RemoveTheZReport", "Visible",
		AccessRight("Update", Metadata.Documents.CashRegisterShift) And AccessRight("Update", Metadata.Documents.RetailSalesReport));
	TMCommonUseClientServer.SetFormItemProperty(Items, "DepositingMoney", "Visible",
		AccessRight("Update", Metadata.Documents.DepositCashIntoCashRegister));
	TMCommonUseClientServer.SetFormItemProperty(Items, "WithdrawalOfMoney", "Visible",
		AccessRight("Update", Metadata.Documents.CashWithdrawalFromCashRegister));
	
	AvailableToAddChangeCashReceipts = AccessRight("Update", Metadata.Documents.CashRegisterReceipt);
	
	If UsePeripherals Then
		EquipmentAttached = EquipmentManagerServerCall.EquipmentByParameters(
			Undefined,
			Undefined,
			EquipmentManagerServerCall.GetClientSWorkplace()).Count() > 0;
		MeaningOpenFormWithConnectedHardware = Common.CommonSettingsStorageLoad(
			"CashRegisterReceipt", "OpenFormWithPeripherals");
		If MeaningOpenFormWithConnectedHardware = Undefined Then
			OpenFormWithPeripherals = EquipmentAttached;
		Else
			OpenFormWithPeripherals = MeaningOpenFormWithConnectedHardware And EquipmentAttached;
		EndIf;
	EndIf;
	
	UpdateStateOfCashShiftOnServer(CashRegister);
	
	SetFormItemsVisibilityLocalization();
	
	// StandardSubsystems.AttachableCommands
	TypesList = CashRegisterReceipts.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.CashRegisterReceiptsCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "CashRegisterReceipts.Date", Items.Date.Name);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	If Items.CashRegisterReceipts.ChildItems.Find("Status") <> Undefined Then
	
		Item = ConditionalAppearance.Items.Add();
	
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.CashRegisterReceipts.ChildItems.Status.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("CashRegisterReceipts.Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("CashRegisterReceipts.Type");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Type("DocumentRef.ReceiptOfCashRegisterAdjustment");
	
		StatusBar_ =  NStr("vi = 'Phiếu chưa đánh';
							|ru = 'Чек не пробит';
							|en = 'Receipt is not issued'; fa = 'رسید صادر نشده است';
							|it = 'Lo scontrino non è stato emesso';
							|pl = 'Nie wydrukowano paragonu';
							|tr = 'Makbuz kesilmedi'");
	
		Item.Appearance.SetParameterValue("Text",StatusBar_); 

		Item = ConditionalAppearance.Items.Add();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UsePeripherals Then
		
		If OpenFormWithPeripherals Then
			
			AttachIdleHandler("OpenConnectedHardwareWaitHandlerForm", 0.5, True);
			
		Else
			
			CompletionDetails = New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", RetailSalesClient, New Structure("Form", ThisObject));
			EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(CompletionDetails, ThisObject, SupportedPeripheralTypes);
			
		EndIf;
		
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
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Write_RetailSalesReport"
		Or EventName = "Write_CashRegisterReceipt"
		Or EventName = "Write_CashRegisterReceiptReturn"
		Or EventName = "Write_ReceiptOfCashRegisterAdjustment"
		Or EventName = "Write_GiftCertificateSale"
		Or EventName = "Write_ReturnOfGiftCards"
		Or EventName = "UpdateStatusOfFiscalTransactions"
		Or EventName = "ChangingCashShift" Then
		
		Items.CashRegisterReceipts.Refresh();
		UpdateCashShiftStateAndSetDynamicListSelectionOnClient(CashRegister);
		SetAvailabilityOfDocumentCreationCommandsForReturns();
		
	EndIf;
	
	If EventName = "ChangedCurSessionWorkplace" Then
		
		CheckoutSelectionOnChangeServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	CashRegister = Settings.Get("CashRegister");
	OnlyCurrentShift = Settings.Get("OnlyCurrentShift");
	
	UpdateStateOfCashShiftOnServer(CashRegister);
	
	SetDynamicListSelectionOnServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KKMOtborTicketOfficeOnChange(Item)
	
	CheckoutSelectionOnChangeServer();
	SetAvailabilityOfDocumentCreationCommandsForReturns();
	
EndProcedure

&AtClient
Procedure OnlyTheCurrentShiftSelectionOnChange(Item)
	
	SetDynamicListSelectionOnClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashRegisterReceipts

&AtClient
Procedure CashRegisterReceiptsOnActivateRow(Item)
	
	SetAvailabilityOfDocumentCreationCommandsForReturns();
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptsBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.CashRegisterReceipts.CurrentData;
	CurrentDataStatus = Undefined;
	CurrentData.Property("Status", CurrentDataStatus);
	NameOfFormToOpen_ = NameOfFormToOpen_(CurrentData.Ref, CurrentDataStatus);
	
	If ValueIsFilled(NameOfFormToOpen_)
		And HaveRightToChangeDocument(CurrentData.Ref) Then

		Cancel = True;
		OpeningParameters = New Structure("Key", CurrentData.Ref);
		OpenForm(NameOfFormToOpen_, OpeningParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.CashRegisterReceipts.CurrentData;
	CurrentDataStatus = Undefined;
	CurrentData.Property("Status", CurrentDataStatus);
	NameOfFormToOpen_ = NameOfFormToOpen_(CurrentData.Ref, CurrentDataStatus);
	
	If ValueIsFilled(NameOfFormToOpen_)
		And HaveRightToChangeDocument(CurrentData.Ref) Then

		StandardProcessing = False;
		OpeningParameters = New Structure("Key", CurrentData.Ref);
		OpenForm(NameOfFormToOpen_, OpeningParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CashRegisterReceiptsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	CurrentData = Items.CashRegisterReceipts.CurrentData;
	Cancel = True;

	If Not (ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts) Then
		Return;
	EndIf;
	
	If Copy = True Then
		TypesArray = New Array;
		TypesArray.Add(TypeOf(CurrentData.Ref));
		RefTypeDetails = New TypeDescription(TypesArray);
		CurrentDataEmptyRef = RefTypeDetails.AdjustValue();
		NameOfFormToOpen_ = NameOfFormToOpen_(CurrentDataEmptyRef,
												PredefinedValue("Enum.CashRegisterReceiptStatuses.EmptyRef"));
												
		FormOpenParameters = New Structure("Basis", CurrentData.Ref);
		OpenForm(
			NameOfFormToOpen_,
			FormOpenParameters);
		
	Else
		
		Basis = New Structure("CashRegister", CashRegister);
		FormOpenParameters = New Structure("Basis", Basis);
		
		OpenForm("Document.CashRegisterReceipt.Form.CWPDocumentForm", FormOpenParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Function HaveRightToChangeDocument(DocumentRef)
	
	Return AccessRight("Update", DocumentRef.Metadata());
	
EndFunction

&AtServerNoContext
Procedure CashRegisterReceiptsOnGetDataAtServer(TagName, Settings, Rows)

	Keys = Rows.GetKeys();
	
	Query = New Query;
	Query.Text = "
				   |SELECT
				   |	CashRegisterReceiptReturn.CashRegisterReceipt AS Ref,
				   |	CashRegisterReceiptReturn.Ref AS DeferredReceiptCashRegistersRefund
				   |FROM
				   |	Document.CashRegisterReceiptReturn AS CashRegisterReceiptReturn
				   |WHERE
				   |	CashRegisterReceiptReturn.CashRegisterReceipt IN (&Ref)
				   |	AND CashRegisterReceiptReturn.Status <> VALUE(Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_)
				   |";
	
	Query.SetParameter("Ref", Keys);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		SampleReceiptCashRegisterRefund = QueryResult.Select();
		
		For Each String In Rows Do
			String = Rows[String.Key];
			
			SampleReceiptCashRegisterRefund.Reset();
			If SampleReceiptCashRegisterRefund.FindNext(String.Data["Ref"], "Ref") Then 
				String.Data["DeferredReceiptCashRegistersRefund"] = SampleReceiptCashRegisterRefund.DeferredReceiptCashRegistersRefund;
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenRegisterShift(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If EquipmentManagerClient.UpdateClientWorkplace() Then
		
		RetailSalesClient.OpenRegisterShift(
			CashRegisterParameters,
			New CallbackDescription("AfterOpeningCashShift", ThisObject));
		
	Else
		
		MessageText = NStr("vi = 'Cần chọn trước chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace of the current session peripherals.'; fa = 'First, you need to select the workplace of the current session peripherals.';
							|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura esterna della sessione corrente.';
							|pl = 'Najpierw należy wybrań miejsce pracy sprzętu zewnętrznego bieżącej sesji.';
							|tr = 'İlk olarak, mevcut oturumdaki çevre birimlerinin çalışma alanını seçmeniz gerekir.'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseRegisterShift(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If EquipmentManagerClient.UpdateClientWorkplace() Then
		
		RetailSalesClient.CloseRegisterShift(
			CashRegisterParameters,
			New CallbackDescription("AfterOpeningCashShift", ThisObject));
		
	Else
		
		MessageText = NStr("vi = 'Cần chọn trước chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace of the current session peripherals.'; fa = 'First, you need to select the workplace of the current session peripherals.';
							|it = 'È necessario selezionare prima la postazione di lavoro dell''apparecchiatura esterna della sessione corrente.';
							|pl = 'Najpierw należy wybrań miejsce pracy sprzętu zewnętrznego bieżącej sesji.';
							|tr = 'İlk olarak, mevcut oturumdaki çevre birimlerinin çalışma alanını seçmeniz gerekir.'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetStatusesOfSBPOperations(Command)
	
	GetStatusesOfSBPOperationsOnServer();
	
EndProcedure

&AtClient
Procedure UpdateTheStateOfRegisterShift(Command)
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShiftClientServer(ThisObject, CashRegister);
	SetAvailabilityOfDocumentCreationCommandsForReturns();
	
EndProcedure

&AtClient
Procedure DepositCash(Command)
	
	ClearMessages();
	
	AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
	
	RetailSalesClient.DepositCash(
		ThisObject,
		CashRegisterParameters,
		New CallbackDescription("AfterMakingWithdrawalOfFunds", ThisObject, AdditionalNotificationParameters));
	
EndProcedure

&AtClient
Procedure CashWithdrawal(Command)
	
	ClearMessages();
	
	AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
	
	RetailSalesClient.CashWithdrawal(
		ThisObject,
		CashRegisterParameters,
		New CallbackDescription("AfterMakingWithdrawalOfFunds", ThisObject, AdditionalNotificationParameters));
	
EndProcedure

&AtClient
Procedure ToCreateACheckCcmnaReturn(Command)

	NameOfFormToOpen_ = NameOfFormToOpen_(PredefinedValue("Document.CashRegisterReceiptReturn.EmptyRef"),
											PredefinedValue("Enum.CashRegisterReceiptStatuses.EmptyRef"));
	
	Basis = New Structure("CashRegister", CashRegister);
	FormOpenParameters = New Structure("Basis", Basis);
	OpenForm(NameOfFormToOpen_, FormOpenParameters);
	
EndProcedure

&AtClient
Procedure CreateCashReceipt(Command)

	NameOfFormToOpen_ = NameOfFormToOpen_(PredefinedValue("Document.CashRegisterReceipt.EmptyRef"),
											PredefinedValue("Enum.CashRegisterReceiptStatuses.EmptyRef"));
	
	Basis = New Structure("CashRegister", CashRegister);
	FormOpenParameters = New Structure("Basis", Basis);
	OpenForm(NameOfFormToOpen_, FormOpenParameters);
	
EndProcedure

&AtClient
Procedure OpenDeferredCashRegisterReceiptForRefund(Command)
	
	CashRegisterReceiptsCurData = Items.CashRegisterReceipts.CurrentData;
	If CashRegisterReceiptsCurData <> Undefined Then
		If ValueIsFilled(CashRegisterReceiptsCurData.DeferredReceiptCashRegistersRefund) Then
			NameOfFormToOpen_ = NameOfFormToOpen_(CashRegisterReceiptsCurData.DeferredReceiptCashRegistersRefund,
													PredefinedValue("Enum.CashRegisterReceiptStatuses.EmptyRef"));
			FormOpenParameters = New Structure("Key", CashRegisterReceiptsCurData.DeferredReceiptCashRegistersRefund);
			OpenForm(NameOfFormToOpen_, FormOpenParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SendNSPKConfirmation(Command)
	
	SendNSPKConfirmationLocalization();
	
EndProcedure

&AtClient
Procedure ReconciliationOfSalesOfPreferentialGoodsPaidForByESFSS(Command)
	
	ReconciliationOfSalesOfPreferentialGoodsPaidForByESFSSLocalization();
	
EndProcedure

&AtClient
Procedure Peripherals_(Command)
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, False);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.CashRegisterReceipts);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.CashRegisterReceipts, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.CashRegisterReceipts);
EndProcedure

&AtClient
Procedure PrintReportWithoutClearance(Command)
	ClearMessages();
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If EquipmentManagerClient.UpdateClientWorkplace() Then
		
		RetailSalesClient.GenerateReportWithoutCancellation(
			CashRegisterParameters,
			New CallbackDescription("AfterReportIsGeneratedWithoutCancellation", ThisObject));
		
	Else
		
		MessageText = NStr("vi = 'Cần chọn trước chỗ làm việc của thiết bị ngoài trong phiên làm việc hiện tại.';
							|ru = 'Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';
							|en = 'First, you need to select the workplace of the current session peripherals.'; fa = 'First, you need to select the workplace of the current session peripherals.';
							|it = 'Предварительно необходимо выбрать рабочее место внешнего оборудования текущего сеанса.';
							|pl = 'Najpierw należy wybrań miejsce pracy sprzętu zewnętrznego bieżącej sesji.';
							|tr = 'İlk olarak, mevcut oturumdaki çevre birimlerinin çalışma alanını seçmeniz gerekir.'");
		CommonClientServer.MessageToUser(MessageText);
		
	EndIf;
EndProcedure    

&AtClient
Procedure AfterReportIsGeneratedWithoutCancellation(Result, AdditionalParameters) Export
	
	UpdateCashShiftStateAndSetDynamicListSelectionOnClient(CashRegister);    
	
EndProcedure

&AtClient
Procedure OpenCRVerificationOfOperations(Command)  
	
	OpenCRVerificationOfOperationsLocalization();  
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Function LinkToListItemByBarcode(Barcode)
	
	Managers = New Array();
	Managers.Add(PredefinedValue("Document.CashRegisterReceipt.EmptyRef"));
	Managers.Add(PredefinedValue("Document.CashRegisterReceiptReturn.EmptyRef"));
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
		Items.CashRegisterReceipts.CurrentRow = Ref;
		NameOfFormToOpen_ = NameOfFormToOpen_(Ref, DocumentStatus(Ref));
		
		If NameOfFormToOpen_ Then
			OpeningParameters = New Structure("Key", Ref);
			OpenForm(NameOfFormToOpen_, OpeningParameters);
		Else
			ShowValue(,Ref);
		EndIf;
		
	Else
		BarcodingOfPrintFormsClient.ObjectIsNotFound(Data.Barcode);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenConnectedHardwareWaitHandlerForm()
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServerNoContext
Function StateOfCashShiftOnServerWithoutContext(CashRegister)
	
	Return RetailSales.GetCashShiftState(CashRegister);
	
EndFunction

&AtServer
Procedure CheckoutSelectionOnChangeServer()
	
	UpdateStateOfCashShiftOnServer(CashRegister);
	SetDynamicListSelectionOnServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateTheStateOfRegisterShiftClientServer(ThisObject, CashRegister)
	
	ThisObject.ShiftIsOpened         = False;
	ThisObject.CurrentRegisterShift = Undefined;
	
	If ValueIsFilled(CashRegister) Then
		
		StructureRegisterShiftState = StateOfCashShiftOnServerWithoutContext(CashRegister);
		CashOnHand_ = Format(StructureRegisterShiftState.CashOnHand,"NFD=2");
		ThisObject.StructureRegisterShiftState = StructureRegisterShiftState;
		If ValueIsFilled(StructureRegisterShiftState.CashRegisterShiftStatus) Then
			
			MessageText = NStr("vi = 'Phiên làm việc số %ShiftNumber%, Trạng thái: %ShiftStatus% %Modified%, Trong quỹ %CashOnHand% %Currency%';
								|ru = 'Смена № %ShiftNumber%, Статус: %ShiftStatus% %Modified%, В кассе %CashOnHand% %Currency%';
								|en = 'Shift No. %ShiftNumber%, Status: %ShiftStatus% %Modified%, Cash register balance: %CashOnHand% %Currency%'; fa = 'Shift No. %ShiftNumber%, Status: %ShiftStatus% %Modified%, Cash register balance: %CashOnHand% %Currency%';
								|it = 'Turno № %ShiftNumber%, Stato: %ShiftStatus% %Modified%, In cassa %CashOnHand% %Currency%';
								|pl = 'Zmiana nr %ShiftNumber%, Status: %ShiftStatus% %Modified%, W kasie %CashOnHand% %Currency%';
								|tr = 'Vardiya No %ShiftNumber%, Durum: %ShiftStatus% %Modified%, Kasada %CashOnHand% %Currency%'");
			
			MessageText = StrReplace(MessageText, "%ShiftNumber%", TrimAll(StructureRegisterShiftState.CashShiftNumber));
			MessageText = StrReplace(MessageText, "%ShiftStatus%", StructureRegisterShiftState.CashRegisterShiftStatus);
			MessageText = StrReplace(MessageText, "%CashOnHand%", CashOnHand_);
			MessageText = StrReplace(MessageText, "%Currency%", StructureRegisterShiftState.CurrencyPresentation);
			MessageText = StrReplace(MessageText, "%Modified%", Format(StructureRegisterShiftState.StatusChangeDate, NStr("vi = 'ДФ=''дд.ММ.гг ЧЧ:мм''';
																															|ru = 'ДФ=''dd.MM.yy HH:mm''';
																															|en = 'DF=''MM/dd/yy HH:mm'''; fa = 'DF=''MM/dd/yy HH:mm''';
																															|it = 'FD=''gg.MM.aa HH:mm''';
																															|pl = 'DF=''dd.MM.yy HH:mm''';
																															|tr = 'DF=''dd.MM.yyyy HH:mm'''")));
			
			ThisObject.RegisterShiftState = MessageText;
			
		Else
			
			MessageText = NStr("vi = 'Phiên thu ngân chưa mở, Trong quỹ tiền mặt %CashOnHand% %Currency%';
								|ru = 'Смена не открыта, В кассе %CashOnHand% %Currency%';
								|en = 'Shift is not opened, cash register balance: %CashOnHand% %Currency%'; fa = 'Shift is not opened, cash register balance: %CashOnHand% %Currency%';
								|it = 'Il turno non è aperto, In cassa %CashOnHand% %Currency%';
								|pl = 'Zmiana nie jest otwarta, W kasie %CashOnHand% %Currency%';
								|tr = 'Vardiya kapalı, Kasada %CashOnHand% %Currency%'");
			MessageText = StrReplace(MessageText, "%CashOnHand%", CashOnHand_);
			MessageText = StrReplace(MessageText, "%Currency%", StructureRegisterShiftState.CurrencyPresentation);
			
			ThisObject.RegisterShiftState = MessageText;
			
		EndIf;
		
		// Form variable
		ThisObject.ShiftIsOpened = StructureRegisterShiftState.ShiftIsOpened;
		ThisObject.CurrentRegisterShift = StructureRegisterShiftState.CashRegisterShift;
		
	Else
		
		ThisObject.RegisterShiftState = NStr("vi = 'Chưa chọn quầy thu ngân';
											|ru = 'Касса ККМ не выбрана.';
											|en = 'Cash register is not selected.'; fa = 'Cash register is not selected.';
											|it = 'Registratore di cassa KKM (Macchinari di Registrazione e Controllo) non è selezionato.';
											|pl = 'Nie wybrano kasy.';
											|tr = 'Yazar kasa seçilmedi.'");
		ThisObject.CashRegisterParameters = Undefined;
		
	EndIf;
	
	// Availability management.
	Items                            = ThisObject.Items;
	AvailableToAddChangeCashReceipts = ThisObject.AvailableToAddChangeCashReceipts;
	ShiftIsOpened                        = ThisObject.ShiftIsOpened;
	AccessRights                        = ThisObject.AccessRights;
	UsedByKKTFZ54                 = RetailSalesServerCall.UsedByKKTFZ54(ThisObject.CurrentRegisterShift);
	ThisObject.UsedByKKTFZ54      = UsedByKKTFZ54;
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "RemoveTheZReport",                                  "Enabled", ShiftIsOpened And ValueIsFilled(CashRegister) And AccessRights.CloseShift);
	TMCommonUseClientServer.SetFormItemProperty(Items, "OpenRegisterShift",                         "Enabled", Not ShiftIsOpened And ValueIsFilled(CashRegister) And AccessRights.OpenShift);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsCreate",                               "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsCreateCashReceipt",                         "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsToCreateACheckCcmnaReturn",                "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts And UsedByKKTFZ54);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsCopy",                           "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksChmodding",                "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsKKMCreateAReceiptKKM",          "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksChmoddingCheckCcmnaReturn", "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts And UsedByKKTFZ54);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKmcorporate",            "Enabled", ValueIsFilled(CashRegister) And AvailableToAddChangeCashReceipts);
	TMCommonUseClientServer.SetFormItemProperty(Items, "DepositingMoney",                                "Enabled", ValueIsFilled(CashRegister) And AccessRights.DepositingMoney);
	TMCommonUseClientServer.SetFormItemProperty(Items, "WithdrawalOfMoney",                                  "Enabled", ValueIsFilled(CashRegister) And AccessRights.WithdrawalOfMoney);
	TMCommonUseClientServer.SetFormItemProperty(Items, "UpdateTheStateOfRegisterShift",               "Enabled", ValueIsFilled(CashRegister));       
	TMCommonUseClientServer.SetFormItemProperty(Items, "PrintReportWithoutClearance",                              "Enabled", ValueIsFilled(CashRegister));
	
EndProcedure 

&AtServer
Procedure UpdateStateOfCashShiftOnServer(CashRegister)
	
	If ValueIsFilled(CashRegister) Then
		CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(CashRegister));
	EndIf;
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	
	UpdateTheStateOfRegisterShiftClientServer(ThisObject, CashRegister);
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfDocumentCreationCommandsForReturns()
	
	If StructureRegisterShiftState = Undefined And ValueIsFilled(CashRegister) Then
		UpdateCashShiftStateAndSetDynamicListSelectionOnClient(CashRegister);
	EndIf;
	
	CurrentData = Items.CashRegisterReceipts.CurrentData;

	TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCorrectionGiftCertificatesCreateOnTheBasis", 				"Enabled", False);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCorrectionGiftCertificatesCreateOnTheBasis", "Enabled", False);

	TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsDocumentCashRegisterReceiptRefundOpenDeferred",                    "Enabled", False);	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsCashRegisterDocumentReceiptCashRegisterRefundOpenDeferred",     "Enabled", False);
	
	If CurrentData <> Undefined
		And StructureRegisterShiftState <> Undefined
		And CurrentData.Property("Type")
		And CurrentData.Property("Status")
		And (CurrentData.Type = Type("DocumentRef.CashRegisterReceipt")
			Or CurrentData.Type = Type("DocumentRef.GiftCertificateSale")) Then
		
		ReceiptCompleted = (CurrentData.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"));
		CurTicketOfficeIsOpenForShift = (CurrentData.Property("CashRegisterShift")
									And CurrentData.CashRegister = StructureRegisterShiftState.CashRegister
									And ShiftIsOpened);
		
		If CurrentData.Type = Type("DocumentRef.CashRegisterReceipt") Then
			
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Enabled", False);	
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",    "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsDocumentCashRegisterReceiptRefundOpenDeferred",                    "Enabled", False);	
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsCashRegisterDocumentReceiptCashRegisterRefundOpenDeferred",     "Enabled", False);
			
			If ValueIsFilled(CurrentData.DeferredReceiptCashRegistersRefund) Then

				TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Visible", False);	
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",    "Visible", False);
				TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsDocumentCashRegisterReceiptRefundOpenDeferred",                    "Visible", True);	
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsCashRegisterDocumentReceiptCashRegisterRefundOpenDeferred",     "Visible", True);
				
				TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsDocumentCashRegisterReceiptRefundOpenDeferred",                    "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift);	
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsCashRegisterDocumentReceiptCashRegisterRefundOpenDeferred",     "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift);
							
			Else

				TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Visible", True);	
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",    "Visible", True);
				TMCommonUseClientServer.SetFormItemProperty(Items, "CashRegisterReceiptsDocumentCashRegisterReceiptRefundOpenDeferred",                    "Visible", False);	
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuReceiptsCashRegisterDocumentReceiptCashRegisterRefundOpenDeferred",     "Visible", False);
				
				TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift);
				TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",    "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift);
				
			EndIf;
			
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentRefundGiftCertificatesCreateOnTheBasis",   "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",         "Enabled", ReceiptCompleted);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis", "Enabled", ReceiptCompleted);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckKmkernelBeCreatedOnTheBasis",				 "Enabled", CurTicketOfficeIsOpenForShift);

			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentRefundGiftCertificatesCreateOnTheBasis",   "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",         "Enabled", ReceiptCompleted);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis", "Enabled", ReceiptCompleted);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckKmkernelBeCreatedOnTheBasis",					"Enabled", CurTicketOfficeIsOpenForShift);
			
		ElsIf CurrentData.Type = Type("DocumentRef.GiftCertificateSale") Then
						
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentRefundGiftCertificatesCreateOnTheBasis",   "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift And UsedByKKTFZ54);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",         "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis", "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckKmkernelBeCreatedOnTheBasis",				 "Enabled", False);

			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentRefundGiftCertificatesCreateOnTheBasis",   "Enabled", ReceiptCompleted And CurTicketOfficeIsOpenForShift And UsedByKKTFZ54);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",         "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis", "Enabled", False);
			TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckKmkernelBeCreatedOnTheBasis",					"Enabled", False);
					
		EndIf;
		
	Else
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckCmosfetBeCreatedOnTheBasis",                          "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentRefundGiftCertificatesCreateOnTheBasis",          "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",                "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis",        "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ChequesCdocumentCheckKmkernelBeCreatedOnTheBasis",				 		"Enabled", False);

		TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckCmosfetBeCreatedOnTheBasis",                   "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentRefundGiftCertificatesCreateOnTheBasis",   "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheReturnOfGoodsFromCustomerToCreateOnTheBasis",         "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksKdocumentTheApplicationForTheReturnOfGoodsFromCustomerToCreateOnTheBasis", "Enabled", False);
		TMCommonUseClientServer.SetFormItemProperty(Items, "ContextMenuChecksCdocumentCheckKmkernelBeCreatedOnTheBasis",					"Enabled", False);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCashShiftStateAndSetDynamicListSelectionOnClient(CashRegister)
	
	UpdateTheStateOfRegisterShiftClientServer(ThisObject, CashRegister);
	SetAvailabilityOfDocumentCreationCommandsForReturns();
	
	SetDynamicListSelectionOnClient();
	
EndProcedure

&AtClient
Procedure SetDynamicListSelectionOnClient()
	
	CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegister", CashRegister, DataCompositionComparisonType.Equal,,ValueIsFilled(CashRegister));
	
	If OnlyCurrentShift = 0 Then // All
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", Undefined, DataCompositionComparisonType.Equal,,False);
	ElsIf OnlyCurrentShift = 1 Then // Only the current shift
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", CurrentRegisterShift, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", False, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", Undefined, DataCompositionComparisonType.Equal,,False);
	ElsIf OnlyCurrentShift = 2 Then // All deferred
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", True, DataCompositionComparisonType.Equal,,True);
	ElsIf OnlyCurrentShift = 3 Then // Deferred for the current shift
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", CurrentRegisterShift, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", False, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", True, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
EndProcedure // Install a board of dynamic lists in the Client()

&AtServer
Procedure SetDynamicListSelectionOnServer()
	
	CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegister", CashRegister, DataCompositionComparisonType.Equal,,ValueIsFilled(CashRegister));
	
	If OnlyCurrentShift = 0 Then // All
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", Undefined, DataCompositionComparisonType.Equal,,False);
	ElsIf OnlyCurrentShift = 1 Then // Only the current shift
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", CurrentRegisterShift, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", False, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", Undefined, DataCompositionComparisonType.Equal,,False);
	ElsIf OnlyCurrentShift = 2 Then // All deferred
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", Undefined, DataCompositionComparisonType.Equal,,False);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", True, DataCompositionComparisonType.Equal,,True);
	ElsIf OnlyCurrentShift = 3 Then // Deferred for the current shift
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "CashRegisterShift", CurrentRegisterShift, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Archived", False, DataCompositionComparisonType.Equal,,True);
		CommonClientServer.SetDynamicListFilterItem(CashRegisterReceipts, "Defer", True, DataCompositionComparisonType.Equal,,True);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DocumentStatus(Ref)
	
	Return Common.ObjectAttributeValue(Ref, "Status");
	
EndFunction

&AtClient
Function NameOfFormToOpen_(Ref, Status)
	
	NameOfFormToOpen_ = "";

	If Status <> Undefined And Status <> PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		If TypeOf(Ref) = Type("DocumentRef.CashRegisterReceipt") Then
			
			NameOfFormToOpen_ = "Document.CashRegisterReceipt.Form.CWPDocumentForm";
			
		ElsIf TypeOf(Ref) = Type("DocumentRef.CashRegisterReceiptReturn") Then
			
			NameOfFormToOpen_ = "Document.CashRegisterReceiptReturn.Form.CWPDocumentForm";
			
		ElsIf TypeOf(Ref) = Type("DocumentRef.ReceiptOfCashRegisterAdjustment") Then
			
			NameOfFormToOpen_ = "Document.ReceiptOfCashRegisterAdjustment.Form.DocumentForm";
			
		ElsIf TypeOf(Ref) = Type("DocumentRef.GiftCertificateSale") Then
			
			NameOfFormToOpen_ = "Document.GiftCertificateSale.Form.CWPDocumentForm";
			
		ElsIf TypeOf(Ref) = Type("DocumentRef.ReturnOfGiftCards") Then
			
			NameOfFormToOpen_ = "Document.ReturnOfGiftCards.Form.CWPDocumentForm";
			
		EndIf;
	EndIf;
	
	Return NameOfFormToOpen_;
	
EndFunction

&AtClient
Procedure StartConnectingEquipmentByIdCompletion(Data, TSRow) Export

	If Not Data.Result Then
		
		RetailSalesClient.ReportErrorOfOperationOnDevice(TSRow.Ref, "ConnectingDevice", Data.ErrorDescription);
		
		TSRow.Attached = 1;
		
	Else
		
		TSRow.Attached = 0;
		
	EndIf;
	
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
	
	UpdateTheStateOfRegisterShiftClientServer(ThisObject, CashRegister);
	
EndProcedure

&AtClient
Procedure AfterOpeningCashShift(Result, AdditionalParameters) Export
	
	UpdateCashShiftStateAndSetDynamicListSelectionOnClient(CashRegister);
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibilityLocalization()
	
	
	Items.SendNSPKConfirmation.Visible = False;
	Items.ReconciliationOfSalesOfPreferentialGoodsPaidForByESFSS.Visible = False;
	Items.GetStatusesOfSBPOperations.Visible = False;
	Items.OpenCRVerificationOfOperations.Visible  = False;
EndProcedure

&AtClient
Procedure SendNSPKConfirmationLocalization()
	
	
EndProcedure

&AtClient
Procedure ReconciliationOfSalesOfPreferentialGoodsPaidForByESFSSLocalization()
	
	
EndProcedure

&AtClient
Procedure OpenCRVerificationOfOperationsLocalization()
	
	
EndProcedure      
#EndRegion

#Region Localization

&AtServer
Procedure GetStatusesOfSBPOperationsOnServer()
	
	
EndProcedure


#EndRegion

#EndRegion

