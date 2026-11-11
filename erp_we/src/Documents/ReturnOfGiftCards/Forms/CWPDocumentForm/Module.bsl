
#Region FormEventHandlers

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ReturnOfGiftCards", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UsePaymentByCards = GetFunctionalOption("UsePaymentByCards");
	
	FiscalOperationData = RetailSales.StructureOfFiscalTransactionData();
	
	SupportedPeripheralTypes = "BarcodeScanner,
	                                              |CustomerDisplay,
	                                              |FiscalCashRegisters,
	                                              |CREWITHDATATRANSFER,
	                                              |ReceiptPrinter,
	                                              |POSTerminal,
	                                              |MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisObject, "");
	RetailSales.FillInEquipmentTable(ThisObject, SupportedPeripheralTypes);
	
	If Not Catalogs.CashRegisters.CashRegisterHasBeenSetUpForCWP() Then
		Items.GroupBottomCommandBarPayment.Enabled = False;
	EndIf;
	
	If UsePeripherals Then
		EquipmentAttached = EquipmentManagerServerCall.EquipmentByParameters(
			Undefined,
			Undefined,
			EquipmentManagerServerCall.CustomerWorkplace()).Count() > 0;
		MeaningOpenFormWithConnectedHardware = Common.CommonSettingsStorageLoad(
			"CashRegisterReceipt", "OpenFormWithPeripherals");
		If MeaningOpenFormWithConnectedHardware = Undefined Then
			OpenFormWithPeripherals = EquipmentAttached;
		Else
			OpenFormWithPeripherals = MeaningOpenFormWithConnectedHardware And EquipmentAttached;
		EndIf;
	EndIf;
	
	ParametersForProcessingGiftCertificates = GiftCertificatesServerCall.ParametersForProcessingReceivedCode();
	ParametersForProcessingGiftCertificates.RegisterNewOnes = False;	
	
	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
	
	FilterStructure1 = ParametersForProcessingGiftCertificates.Filters;
	FilterStructure1.Insert("Organization", Object.Organization);
	FilterStructure1.Insert("Status", ArrayOfStatuses);
	FilterStructure1.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
	
	SetSelectionParametersForGiftCertificate(ThisObject);
	
	OnReadCreateAtServer();

	GetHardwareLinks();
	FillInCashRegisterReceiptDetails();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	ToEstablishPossibilityOfUsingSBPPaymentOnCWPLocalizationForms();
	
	GetStatusOfSBPPaymentForPSImplementation();
	
	WhenCreatingReceipt();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UsePeripherals Then
		
		If OpenFormWithPeripherals And FormOwner = Undefined Then
			
			AttachIdleHandler("OpenConnectedHardwareWaitHandlerForm", 0.5, True);
			
		Else
			
			AttachIdleHandler("StartHardwareConnectionHandlerWaiting", 0.1, True);
			
		EndIf;
		
	EndIf;
	
	RecalculateDocumentOnClient();
	
	If ForcefullyAuthorize And FormOwner = Undefined Then
		AttachIdleHandler("OpenAuthorizationWindow", 0.5, True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Return;
	EndIf;
	
	If ForcedShutdown Or Exit Then
		Return;
	EndIf;
	
	BeforeClosingReceipt(Cancel);
	
EndProcedure

&AtClient
Procedure OnClose()

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.ReturnOfGiftCards.Form.SelectDeferredReceipt" Then
		UploadNewReceipt(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Return;
	EndIf;

	// Peripherals
	If Source = "Peripherals" And IsInputAvailable()
		And Not ReadOnly Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		ElsIf EventName ="TracksData" Then
			ProcessMagneticCardReaderData(Parameter);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "UserIsAuthorized" Then
		
		If Parameter.Mode = "ChangeRights" Then
			ConfigureRightsForUser(Parameter.User);
			RecalculateDocumentOnClient();
		ElsIf Parameter.Mode = "CloseCashReceipt" Then
			ForcedShutdown = True;
			If IsOpen() Then
				Close();
			EndIf;
		EndIf;
		
	EndIf;
	
	If EventName = "ReadingFormCommands"
		And Parameter.Form = UUID Then
		
		Notify("ReadingFormCommands", New Structure("Form, OwnerForm, AddressInTempStorage", Parameter.OwnerForm, UUID, GetFormCommands(Parameter.OwnerForm)));
		
	EndIf;
	
	If EventName = "GiftCertificateIsRead"
		And Parameter.OwnerForm = UUID Then
		
		ProcessGiftCertificate(Parameter.GiftCertificate);
		RecalculateDocumentOnClient();
		
	EndIf;
	
	If EventName = "EquipmentAttached" Then
		RetailSalesClient.ProcessHardwareConnectedEvent(ThisObject, Parameter, Source);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 1, True);
	EndIf;
	
	If EventName = "ChangingCashShift" Then
		StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
		FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InformationPanelOtherParametersValueURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure InformationPanelErrorWhenPrintingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ShowCompleteErrorWhenPrintingReceipt" Then
		ShowValue(Undefined, InformationPanelErrorWhenPrintingReceiptText);	
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConsiderAGiftCertificate(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DoNotUseManualInput", False);
	AdditionalParameters.Insert("Filter", ParametersForProcessingGiftCertificates.Filters);
	AdditionalParameters.Insert("RegisterNewOnes", ParametersForProcessingGiftCertificates.RegisterNewOnes);
	
	OpenForm(
		"Catalog.GiftCertificates.Form.ReadGiftCard",
		AdditionalParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure OpenTheSCCMOperationsMenu(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister", Object.CashRegister);
	FormOpenParameters.Insert("Cashier",   Object.Cashier);
	FormOpenParameters.Insert("ChangeTheCashRegisterOfTheKKM", True);
	FormOpenParameters.Insert("RestrictAvailableCashRegistersToOneCompany", ValueIsFilled(Object.GiftCertificateSale));
	
	OpenForm("Document.CashRegisterReceipt.Form.CashRegisterTransactions", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTheOtherOperationsMenu(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister",                Object.CashRegister);
	FormOpenParameters.Insert("Cashier",                  Object.Cashier);
	FormOpenParameters.Insert("ReadOnly",          ReadOnly);
	FormOpenParameters.Insert("Document",                Object.Ref);
	FormOpenParameters.Insert("DoNotOutputTheDownloadFromTheTSD", True);
	FormOpenParameters.Insert("Organization",             Object.Organization);
	
	FormOpenParameters.Insert("CheckQuantityInTheDocument", False);
	FormOpenParameters.Insert("SellingAGiftCertificate", False);
	FormOpenParameters.Insert("GiftCertificateRefund", False);
	FormOpenParameters.Insert("Lock",                         ForcefullyAuthorize);
	FormOpenParameters.Insert("PrintCommandAddressInTheTemporaryStorage", PrintCommandAddressInTheTemporaryStorage);
	
	OpenForm("Document.CashRegisterReceipt.Form.OtherTransactions", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure Peripherals_(Command)
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, False);
	
EndProcedure

&AtClient
Procedure PayInCash(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PayInCashHandlingAlerts", ThisObject));
	
EndProcedure

&AtClient
Procedure PayByPaymentCard(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	If TotalAmountOfPaymentByCreditCards > DocumentAmount Then
		MessageText = NStr("vi = 'Số tiền thanh toán bằng thẻ lớn hơn số tiền hàng hóa. Không hỗ trợ giao dịch.';
							|ru = 'Сумма оплаты платежными картами больше суммы товарных позиций. Операция не поддерживается.';
							|en = 'The amount of payment by payment cards exceeds the goods item amount. The transaction is not supported.'; fa = 'The amount of payment by payment cards exceeds the goods item amount. The transaction is not supported.';
							|it = 'Сумма оплаты платежными картами больше суммы товарных позиций. Операция не поддерживается.';
							|pl = 'Kwota płatności kartami płatniczymi pozycji towarowych. Operacja nie jest obsługiwana.';
							|tr = 'Kredi kartıyla ödenen tutar, ticari ürün tutarından büyüktür. İşlem desteklenmiyor.'");
		CommonClient.MessageToUser(MessageText);
    Else
		RetailSalesClient.ProcessShiftState(
			ThisObject,
			New CallbackDescription("CancelPaymentUsingPaymentCardsProcessingNotifications", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure MixedPayment(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);

	SelectedPaymentMethod = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("MixedPaymentNotificationProcessing", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure PayForSBP(Command)
	
	PayForSBPLocalization();
	
EndProcedure

&AtClient
Procedure OpenPaymentCardPayments(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	AdditionalParameters = New Structure;
	RunCallback(
		New CallbackDescription("CancelPaymentsByPaymentCards", ThisObject, AdditionalParameters));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure CloseInformationPanelErrorsWhenPrintingReceipt(Command)
	Items.InformationPanelErrorWhenPrintingReceipt.Title = "";
	InformationPanelErrorWhenPrintingReceiptText = "";
	Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible = False;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGiftCertificates

&AtClient
Procedure GiftCertificatesOnChange(Item)
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure GiftCertificatesOnActivateRow(Item)
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
EndProcedure

&AtClient
Procedure GiftCertificatesOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.GiftCertificates, ThisObject);
	
EndProcedure

&AtClient
Procedure GiftCertificatesGiftCertificateOnChange(Item)
	
	GiftCertificate = Items.GiftCertificates.CurrentData.GiftCertificate;
	ProcessGiftCertificate(GiftCertificate, Items.GiftCertificates.CurrentRow);
	
EndProcedure

&AtClient
Procedure GiftCertificatesGiftCertificateStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	
	ParametersStructure = New Structure("Filter", ParametersForProcessingGiftCertificates.Filters);	
	OpenForm("Catalog.GiftCertificates.ChoiceForm", ParametersStructure, ThisObject,,,, 
	                         New CallbackDescription("GiftCertificatesGiftCertificateStartChoiceCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure GiftCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.GiftCertificatesGiftCertificate Then
		ShowValue(Undefined, Items.GiftCertificates.CurrentData.GiftCertificate);
	EndIf;

EndProcedure

&AtClient
Procedure GiftCertificatesGiftCertificateStartChoiceCompletion(Result, AdditionalParameters) Export
	SelectedCertificate = Result;
	If SelectedCertificate = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.GiftCertificates.CurrentData;  	
	If CurrentData <> Undefined Then   		
		CurrentData.GiftCertificate = SelectedCertificate;
		ProcessGiftCertificate(SelectedCertificate, Items.GiftCertificates.CurrentRow);  
	EndIf; 	
EndProcedure

#EndRegion

#Region Private

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	If TypeOf(BarcodeData_5) = Type("Array") Then
		ArrayOfBarcodes = BarcodeData_5;
	Else
		ArrayOfBarcodes = New Array;
		ArrayOfBarcodes.Add(BarcodeData_5);
	EndIf;
	
	GiftCertificatesClient.ProcessReceivedCodeOnClient(
		ThisObject,
		ArrayOfBarcodes[0].Barcode,
		PredefinedValue("Enum.CardCodeTypes.Barcode"),
		ParametersForProcessingGiftCertificates);
	
EndProcedure

&AtClient
Procedure ProcessMagneticCardReaderData(Data)
	
	GiftCertificatesClient.ProcessReceivedCodeOnClient(
		ThisObject,
		Data,
		PredefinedValue("Enum.CardCodeTypes.MagneticCode"),
		ParametersForProcessingGiftCertificates);
	
EndProcedure

&AtClient
Procedure OpenConnectedHardwareWaitHandlerForm()
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, True);
	
EndProcedure

&AtClient
Procedure StartHardwareConnectionHandlerWaiting()
	
	CompletionDetails = New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", RetailSalesClient, New Structure("Form", ThisObject));
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(CompletionDetails, ThisObject, SupportedPeripheralTypes);
	
EndProcedure

&AtClient
Procedure DisplayInformationOnBuyerSDisplay()

	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	NumberOfWHLines = Object.GiftCertificates.Count();
	
	CurrentRow = Items.GiftCertificates.CurrentRow;
	If CurrentRow = Undefined And NumberOfWHLines > 0 Then
		CurrentData = Object.GiftCertificates[NumberOfWHLines - 1];
		Items.GiftCertificates.CurrentRow = CurrentData.GetID();
	ElsIf CurrentRow = Undefined And NumberOfWHLines = 0 Then
		CurrentData = Undefined;
	Else
		CurrentData = Object.GiftCertificates.FindByID(CurrentRow);
	EndIf;
	
	Dptext1 = NStr("vi = 'Xin chào!';
					|ru = 'Здравствуйте!';
					|en = 'Hello!'; fa = 'Hello!';
					|it = 'Salve!';
					|pl = 'Dzień dobry!';
					|tr = 'Merhaba!'");
	If CurrentData <> Undefined Then
		If ValueIsFilled(CurrentData.GiftCertificate) Then
			Dptext1 = Format(CurrentData.Nominal, "NFD=2") + " " + String(CurrentData.NominalCurrency);
		Else
			Dptext1 = "";
		EndIf;
	EndIf;
	
	Dptext2 = RetailSalesClient.PrepareLineForDisplay(
		NStr("vi = 'Tổng cộng:';
			|ru = 'Итог:';
			|en = 'Total:'; fa = 'جمع:';
			|it = 'Totale:';
			|pl = 'Wyniki:';
			|tr = 'Toplam:'"), DocumentAmount);
	
	RetailSalesClient.DisplayTextOnBuyerSDisplays(
		ThisObject,
		Displays,
		Dptext1 + Chars.LF + Dptext2);
	
EndProcedure

&AtServer
Procedure GetHardwareLinks()
	
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	
	POSTerminals.Clear();
	POSTerminals = Catalogs.POSTerminals.ParametersOfAcquiringTerminalsByOrganization(Object.Organization, Workplace, UsePeripherals);
	
	If UsePeripherals Then
		Displays.LoadValues(EquipmentManagerServerCall.EquipmentByParameters("CustomerDisplay"));
	EndIf;
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	UpdateOrganizationVATPayer();
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure OpenAuthorizationWindow()
	
	OpenForm("Document.CashRegisterReceipt.Form.Authorization", New Structure("Mode", "ChangeRights"), ThisObject);
	
EndProcedure

&AtClient
Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetryRecordingIsRequired = False;
		If AdditionalParameters.ProcedureName = "WriteAtServer" Then
			OperationResult = WriteAtServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "PostponeOnServer" Then
			OperationResult = PostponeOnServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "RecordFiscalTransactionOnServer" Then
			OperationResult = RecordFiscalTransactionOnServer(RetryRecordingIsRequired, AdditionalParameters.DetailsOfCashNodeSFiscalOperation);
		EndIf;
		
		If OperationResult Then
			
			RunCallback(
				AdditionalParameters.CallbackDescription,
				?(AdditionalParameters.ReturnFunctionResult, OperationResult, AdditionalParameters.ResultOfSuccessfulImplementation));
			
		Else
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
				AdditionalParameters.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			
		EndIf;
		
	Else
		
		RunCallback(
			AdditionalParameters.CallbackDescription,
			?(AdditionalParameters.ReturnFunctionResult, AdditionalParameters.OperationResult, AdditionalParameters.CancellationResult_));
		
	EndIf;
	
EndProcedure

&AtServer
Function WriteAtServer(RetryRecordingIsRequired = Undefined)
	
	Object.Date = CurrentSessionDate();
	
	If Not ValueIsFilled(Object.Ref) Then
		Value = FormDataToValue(Object, Type("DocumentObject.ReturnOfGiftCards"));
		Value.SetNewObjectRef(Documents.ReturnOfGiftCards.GetRef());
		ValueToFormData(Value, Object);
	EndIf;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add();
		LockItem.Region = "Document.ReturnOfGiftCards";
		LockItem.Mode = DataLockMode.Shared;
		LockItem.SetValue("Ref", Object.Ref);
		Block.Lock();
		
		Result = Write(New Structure("WriteMode, PostingMode", DocumentWriteMode.Posting, DocumentPostingMode.RealTime));
		
		CommitTransaction();
		
	Except
		
		
		RollbackTransaction();
		
		WriteLogEvent(NStr("vi = 'Bán lẻ';
							|ru = 'Розничные продажи';
							|en = 'Retail sales'; fa = 'فروش خرده‌فروشی';
							|it = 'Vendite al dettaglio';
							|pl = 'Sprzedaże detaliczne';
							|tr = 'Perakende satışlar'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		RetryRecordingIsRequired = True;
		Return False;
		
	EndTry;
	
	Return Result;
	
EndFunction

&AtClient
Function WriteAtClient(RetryRecordingIsRequired = Undefined)
	
	If Modified Then
		
		Result = WriteAtServer(RetryRecordingIsRequired);
		If Result Then
			Notify("Write_ReturnOfGiftCards", New Structure, Undefined);
		EndIf;
		
		ProcessGiftCertificatesOnServer();
		
		Return Result;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure ChangePaymentByPaymentCardsEnd(Result, AdditionalParameters) Export
	
	If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Data", Object.Ref);
		FormParameters.Insert("DataForEventLog", DataForEventLog);
		FormParameters.Insert("MessageText",
			NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
			|Chưa ghi nhận việc hủy thanh toán trong hệ thống.';
			|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
			|Отмена оплаты не зафиксирована в системе.';
			|en = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.'; fa = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.';
			|it = 'ATTENZIONE! Si è verificata una situazione eccezionale:
			| l''annullamento del pagamento non è stato registrato nel sistema.';
			|pl = 'UWAGA! Wystąpiła sytuacja wyjątkowa:
			|Anulowanie płatności nie zostało zarejestrowane w systemie.';
			|tr = 'UYARI! İstisnai bir durum meydana geldi:
			| Ödeme iptali sisteme kaydedilemedi.'"));
		
		OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, ThisObject);
		
	EndIf;

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ProcessingOfTabularForms.InitializeRowCache(Items.GiftCertificates);
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	UpdateOrganizationVATPayer();
	
	Query = New Query(
	"SELECT
	|	CAST(T.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO TempTable
	|FROM
	|	&GiftCertificates AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTable.GiftCertificate  AS GiftCertificate,
	|	GiftCertificates.Owner.Nominal AS Nominal,
	|	GiftCertificates.Owner.Currency  AS NominalCurrency
	|FROM
	|	TempTable AS TempTable
	|		LEFT JOIN Catalog.GiftCertificates AS GiftCertificates
	|		ON (TempTable.GiftCertificate = GiftCertificates.Ref)");
	
	Query.SetParameter("GiftCertificates", Object.GiftCertificates.Unload());
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do 	
	
		FoundRows = Object.GiftCertificates.FindRows(New Structure("GiftCertificate", Selection.GiftCertificate));
		For Each TSRow In FoundRows Do
			TSRow.Nominal        = Selection.Nominal;
			TSRow.NominalCurrency = Selection.NominalCurrency;
		EndDo;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure RecalculateDocumentOnClient()
	
	Items.GiftCertificates.ChangeRowSet    = AccessRights.LineAdjustment;
	
	Items.GiftCertificatesContextMenuDelete.Enabled     = AccessRights.LineAdjustment;
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	UpdateFormButtonHeaders();
	
	EstablishAvailabilityOfCWPElements(ThisObject, RetailSalesClientServer.AvailablePaymentMethods(ThisObject));
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificatesOnServer()
	
	SelectionByGiftCertificate = Object.GiftCertificates.Unload(,"GiftCertificate").UnloadColumn("GiftCertificate");
	Selection = Catalogs.GiftCertificates.SelectionOfDataOnGiftCertificatesForProcessing(SelectionByGiftCertificate, Object);
	
	For Each RowCertificate In Object.GiftCertificates Do
		
		Selection.Reset();
		If Selection.FindNext(RowCertificate.GiftCertificate, "GiftCertificate") Then
			
			RowCertificate.Sum = Selection.Sum;
			
			RowCertificate.Nominal        = Selection.Nominal;
			RowCertificate.NominalCurrency = Selection.NominalCurrency;
			
		EndIf;	
	EndDo;
	
EndProcedure

&AtServer
Procedure ProcessGiftCertificate(GiftCertificate, TSRow = Undefined)
	
	Selection = Catalogs.GiftCertificates.SelectionOfDataOnGiftCertificatesForProcessing(GiftCertificate, Object);
	If Selection.Next() Then

		If Selection.DocumentSalesOfGoodsAndServices <> Object.GiftCertificateSale Then
			If Not TSRow = Undefined Then
				FoundRow = Object.GiftCertificates.FindByID(TSRow);
				FoundRow.GiftCertificate = CachedLines.GiftCertificates.GiftCertificate;
			EndIf;
			MessageText = NStr("vi = 'Phiếu quà tặng ""%1"" không liên quan đến chứng từ trả lại. Không hỗ trợ giao dịch.';
								|ru = 'Подарочный сертификат ""%1"" не относится к документу, по которому оформляется возврат. Операция не поддерживается.';
								|en = 'The %1 gift card is not related to the document, for which the return is registered. The transaction is not supported.'; fa = 'The %1 gift card is not related to the document, for which the return is registered. The transaction is not supported.';
								|it = 'Il buono regalo ""%1"" non è riferito al documento in base a cui viene formalizzato il reso. L''operazione non è supportata.';
								|pl = 'Certyfikat podarunkowy ""%1"" nie należy do dokumentu, dla którego jest rejestrowany zwrot. Operacja nie jest obsługiwana.';
								|tr = '""%1""hediye kartı, iadenin yapıldığı belge ile ilgili değildir. İşlem desteklenmemektedir.'");
			MessageText = StrReplace(MessageText, "%1", GiftCertificate);
			Common.MessageToUser(MessageText);
			Return;
		EndIf;
			
		If TSRow = Undefined Then
			
			FoundRows = Object.GiftCertificates.FindRows(New Structure("GiftCertificate", GiftCertificate));
			If FoundRows.Count() = 0 Then
				FoundRow = Object.GiftCertificates.Add();
			Else
				FoundRow = FoundRows[0];
			EndIf;
			
		Else
			FoundRow = Object.GiftCertificates.FindByID(TSRow);
		EndIf;
		
		FoundRow.GiftCertificate = GiftCertificate;
		FoundRow.Sum = Selection.Sum;
		
		FoundRow.Nominal        = Selection.Nominal;
		FoundRow.NominalCurrency = Selection.NominalCurrency;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionParametersForGiftCertificate(Form)
	GiftCertificateSelectionParameters = New Array;
	FilterStructure1 = Form.ParametersForProcessingGiftCertificates.Filters;
	If FilterStructure1.Property("Status") Then
		GiftCertificateSelectionParameters.Add(New ChoiceParameter("Status", FilterStructure1.Status));
	EndIf;
	If FilterStructure1.Property("Organization") Then
		GiftCertificateSelectionParameters.Add(New ChoiceParameter("Organization", FilterStructure1.Organization));
	EndIf;
	Form.Items.GiftCertificatesGiftCertificate.ChoiceParameters = New FixedArray(GiftCertificateSelectionParameters);
EndProcedure

#Region PrintingReceipt

&AtServer
Function ParametersOfReceiptFiscalizationOperationOnServer(PaymentInformation)
	
	Return ParametersOfReceiptFiscalizationOperationOnServerLocalization(PaymentInformation);
	
EndFunction

&AtClient
Function ParametersOfReceiptFiscalizationOperation()
	
	Return ParametersOfReceiptFiscalizationOperationOnServer(PaymentInformation(ThisObject));
	
EndFunction

&AtClient
Procedure IssueCashReceipt()
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	HasErrors = False;
	
	If Object.DeletionMark Then
		CommonClient.MessageToUser(NStr("vi = 'Chứng từ được đặt dấu xóa';
										|ru = 'Документ помечен на удаление';
										|en = 'The document is marked for deletion'; fa = 'The document is marked for deletion';
										|it = 'Il documento è stato contrassegnato per la cancellazione';
										|pl = 'Dokument zaznaczono do usunięcia';
										|tr = 'Belge silinmek üzere işaretlendi'"), Object.Ref,,,HasErrors);
	EndIf;
	
	Modified = True;
	
	If HasErrors Or Not CheckFilling() Then
		Return;
	EndIf;
	
	ParametersOfReceiptFiscalizationOperation = ParametersOfReceiptFiscalizationOperation();
	PrintingReceiptAfterRecordingChangesLocalization(ParametersOfReceiptFiscalizationOperation);
	
EndProcedure

#Region FiscalTransaction

&AtServer
Function RecordFiscalTransactionOnServer(RetryRecordingIsRequired, DetailsOfCashNodeSFiscalOperation)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);

	Result = RetailSales.RecordFiscalTransactionOnServer(ThisObject, DetailsOfCashNodeSFiscalOperation, WriteParameters);
	
	If Not Result Then
		RetryRecordingIsRequired = True;
	EndIf;

	Return Result;
EndFunction

#EndRegion

&AtServer
Procedure UpdateTheStateOfRegisterShift()
	
	If ValueIsFilled(Object.CashRegister)
		And Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then

		StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
		If Object.CashRegisterShift <> StructureRegisterShiftState.CashRegisterShift Then
			FillPropertyValues(Object, StructureRegisterShiftState,,"Cashier");
		EndIf;

		CurrentUser = Users.CurrentUser();
		If Object.Cashier <> CurrentUser Then

			Object.Cashier = CurrentUser;
		EndIf;

	EndIf;
	
EndProcedure

#EndRegion

&AtClient
Procedure GiftCertificatesOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
EndProcedure

&AtServer
Procedure FillInCashRegisterReceiptDetails()
	
	CashRegisterReceiptDetails = New Structure;
	CashRegisterReceiptDetails.Insert("CashRegisterShift", PredefinedValue("Document.CashRegisterShift.EmptyRef"));
	CashRegisterReceiptDetails.Insert("CashRegisterShiftStatus", PredefinedValue("Enum.CashRegisterShiftStatuses.EmptyRef"));	
	CashRegisterReceiptDetails.Insert("DocumentAmount", 0);
	CashRegisterReceiptDetails.Insert("AddressOfTableOfNonCancelledPaymentsByPaymentCards", "");
	CashRegisterReceiptDetails.Insert("AmountOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards", New Array);	
	CashRegisterReceiptDetails.Insert("LowestAmountOfNonCancelledPaymentByPaymentCard", 0);
	CashRegisterReceiptDetails.Insert("NumberOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("DataOfFirstNonCancelledPaymentByPaymentCards", Undefined);
	CashRegisterReceiptDetails.Insert("LineNumbersOfCancelledPaymentsByPaymentCard", New Map);
	
	If ValueIsFilled(Object.GiftCertificateSale) Then
	
		AttributesOfCashRegisterReceipt = Common.ObjectAttributesValues(Object.GiftCertificateSale, "CashRegisterShift,CashRegisterShift.Status,DocumentAmount");
		CashRegisterReceiptDetails.CashRegisterShift = AttributesOfCashRegisterReceipt.CashRegisterShift;
		CashRegisterReceiptDetails.CashRegisterShiftStatus = AttributesOfCashRegisterReceipt.StatusOfPOSShift;
		CashRegisterReceiptDetails.DocumentAmount = AttributesOfCashRegisterReceipt.DocumentAmount;
		
		FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt()

	CashRegisterReceiptDetails.Insert("AmountOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("NumberOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards", New Array);
	CashRegisterReceiptDetails.Insert("LowestAmountOfNonCancelledPaymentByPaymentCard", 0);
	CashRegisterReceiptDetails.Insert("DataOfFirstNonCancelledPaymentByPaymentCards", Undefined);
	CashRegisterReceiptDetails.Insert("LineNumbersOfCancelledPaymentsByPaymentCard", New Map);
	
	If ValueIsFilled(Object.GiftCertificateSale) Then
		ArrayOfPaymentKinds = New Array;
		ArrayOfPaymentKinds.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
		Query = New Query(Documents.GiftCertificateSale.QueryTextForReceivingUndeliveredPaymentsByCashRegisterReceipt(True, False));
		Query.SetParameter("Ref", Object.GiftCertificateSale);
		Query.SetParameter("TypesOfPayments", ArrayOfPaymentKinds);
		TableOfNonCancelledPaymentsByPaymentCards = Query.Execute().Unload();
		
		// Checking that the acquiring terminals used for payment by sales receipt are configured.
		ConfiguredAcquiringTerminals = New Map;
		For Each Terminal In POSTerminals Do
			TerminalValue = Terminal.Value; // Structure
			ConfiguredAcquiringTerminals.Insert(TerminalValue.Ref, Terminal.Value);
		EndDo;
		ArrayOfRowsToDelete = New Array;
		For Each NonCancelledPaymentByPaymentCard In TableOfNonCancelledPaymentsByPaymentCards Do
			If NonCancelledPaymentByPaymentCard.Sum > Object.DocumentAmount 
				Or ConfiguredAcquiringTerminals[NonCancelledPaymentByPaymentCard.POSTerminal] = Undefined Then
				ArrayOfRowsToDelete.Add(NonCancelledPaymentByPaymentCard);
			EndIf;
		EndDo;
		For Each RowForDeletion In ArrayOfRowsToDelete Do
			TableOfNonCancelledPaymentsByPaymentCards.Delete(RowForDeletion);
		EndDo;
		
		TableOfNonCancelledPaymentsByPaymentCards.Columns.Add("LineNumber");
		LineNumberOfUndonePayment = 0;
		For Each LineOfUndeliveredPayments In TableOfNonCancelledPaymentsByPaymentCards Do
			LineOfUndeliveredPayments.LineNumber = LineNumberOfUndonePayment;
			LineNumberOfUndonePayment = LineNumberOfUndonePayment + 1;
		EndDo;
		
		CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards = PutToTempStorage(TableOfNonCancelledPaymentsByPaymentCards, UUID);
		
		ResultOfRecalculation = RetailSalesServerCall.RecalculateDataOfNonCanceledPaymentsByPaymentCards(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards);
		CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards = ResultOfRecalculation.DataOfFirstNonCancelledPaymentByPaymentCards;
		CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = ResultOfRecalculation.NumberOfOutstandingPaymentsByPaymentCards;
		CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards = ResultOfRecalculation.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards;
		CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard = ResultOfRecalculation.LowestAmountOfNonCancelledPaymentByPaymentCard;
		CashRegisterReceiptDetails.AmountOfOutstandingPaymentsByPaymentCards = TableOfNonCancelledPaymentsByPaymentCards.Total("Sum");
	
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrganizationVATPayer()
	
	ReturnOfGiftCardsLocalization.UpdateOrganizationVATPayer(CashRegisterParameters.Organization, VATPayerOrganization);
	
EndProcedure

&AtServer
Procedure ConfigureCWP()
	
	SetPrivilegedMode(True);
	
	GetHardwareLinks();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.AmountToReturn.Width                  = 22;
		Items.AmountToReturnByPaymentCards.Width = 22;
		Items.AmountToRefundInCash.Width         = 22;
	EndIf;
	
	Items.GiftCertificatesSum.Title = Items.GiftCertificatesSum.Title + " " + "(" + Object.Currency + ")";
	UpdateFormButtonHeadersOnServer(False);
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
	Query = New Query(
	"SELECT TOP 1
	|	ISNULL(CWPSettings.KeyboardShortcuts, UNDEFINED)              AS KeyboardShortcuts,
	|	ISNULL(CWPSettings.KeyboardShortcuts.FormCommands, UNDEFINED) AS FormCommands,
	|	CWPSettings.UseAuthorization                             AS UseAuthorization
	|FROM
	|	Catalog.CWPSettings AS CWPSettings
	|WHERE
	|	CWPSettings.Workplace = &Workplace
	|	AND CWPSettings.Ref IN (SELECT DISTINCT T.Ref FROM Catalog.CWPSettings.CashRegisters AS T WHERE T.CashRegister = &CashRegister)
	|");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.CustomerWorkplace());
	Query.SetParameter("CashRegister", Object.CashRegister);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		KeyboardShortcuts            = Selection.KeyboardShortcuts;
		ForcefullyAuthorize = Selection.UseAuthorization;
		
		If ValueIsFilled(KeyboardShortcuts) Then
			RetailSales.ConfigureQuickItemsAndHotkeys(ThisObject, Selection);
		EndIf;
		
	Else
		
		KeyboardShortcuts            = Undefined;
		ForcefullyAuthorize = False;
		
	EndIf;
	
	ConfigureRightsForUser(Object.Cashier);
	RecalculateTotalAmountOfPayments(ThisObject);
		
	AvailablePaymentMethods = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	
	If ValueIsFilled(Object.GiftCertificateSale) 
			And CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards > 0 Then
		Items.ConsiderAGiftCertificate.Enabled = False;
	EndIf;

	EstablishAvailabilityOfCWPElements(ThisObject, AvailablePaymentMethods);

	Items.PayInCash.Visible = AvailablePaymentMethods.CashPayment;
	Items.PaymentByCard.Visible    = AvailablePaymentMethods.PaymentCards;
	Items.MixedPayment.Visible   = AvailablePaymentMethods.PaymentCards;
	
	Items.CancelPaymentsByPaymentCards.Enabled = (CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard > 0);

	Items.DecorativeFieldGroupRefundAmount1.Visible = Not Items.PaymentByCard.Visible;
	Items.DecorativeFieldGroupRefundAmount2.Visible = True;
	Items.AmountToReturnByPaymentCards.Visible = Items.PaymentByCard.Visible;
	
	ElementsToRegroup = New Array;
	ElementsToRegroup.Add(Items.PayInCash);
	ElementsToRegroup.Add(Items.PaymentByCard);
	ElementsToRegroup.Add(Items.MixedPayment);
	
	ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup);
	
	RetailSales.RearrangeFormButtons(ThisObject, ElementsToRegroup);
	
	RetailSales.ConfigurePrintCommands(ThisObject, Items.MovableButtons);
	
EndProcedure

&AtServer
Procedure ConfigureRightsForUser(User)
	
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(User);
	
	Object.Cashier = User;
	DetailsOfTheCashier = RetailSales.DetailsOfTheCashier(User, Object.Organization);
	
	RefreshFormTitle();
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NStr("vi = 'Hoàn tiền (Thu ngân: %Cashier%)';
				|ru = 'Возврат (Кассир: %Cashier%)';
				|en = 'Return (Cashier: %Cashier%)'; fa = 'Return (Cashier: %Cashier%)';
				|it = 'Reso (Operatore di cassa: %Cashier%)';
				|pl = 'Zwrot (Kasjer: %Cashier%)';
				|tr = 'İade (Kasiyer: %Cashier%)'");
	Title = StrReplace(Title, "%Cashier%", Object.Cashier);
	
EndProcedure

&AtClient 
Procedure UpdateFormButtonHeaders()
	
	If ButtonHeadersAreConfigured Then
		Return;
	EndIf;
	
	UpdateFormButtonHeadersOnServer();
	
EndProcedure

&AtServer
Procedure UpdateFormButtonHeadersOnServer(SignHotkeysOnButtons = True)
	
	Command = Commands.PayByPaymentCard;
	TitleLines = New Array;
	TitleLines.Add(NStr("vi = 'Quay lại';
						|ru = 'Вернуть';
						|en = 'Return'; fa = 'مرجوعی';
						|it = 'Вернуть';
						|pl = 'Return';
						|tr = 'Karta iade'"));
	TitleLines.Add(NStr("vi = 'thanh toán đến thẻ';
						|ru = 'оплату на карту';
						|en = 'payment to card'; fa = 'payment to card';
						|it = 'оплату на карту';
						|pl = 'payment to card';
						|tr = 'edilecek ödeme'"));
	ToolTipText = NStr("vi = 'Trả lại thanh toán vào thẻ thanh toán';
						|ru = 'Вернуть оплату на платежную карту';
						|en = 'Return the payment to the payment card'; fa = 'برگشت پرداخت به کارت پرداخت';
						|it = 'Вернуть оплату на платежную карту';
						|pl = 'Return the payment to the payment card';
						|tr = 'Ücreti ödeme kartına iade et'");
	If ThisIsFullReturnOnSalesShift And TotalAmountOfPaymentByCreditCards <> 0 Then
		TitleLines.Clear();
		TitleLines.Add(NStr("vi = 'Hủy bỏ';
							|ru = 'Отменить';
							|en = 'Cancel'; fa = 'انصراف';
							|it = 'Отменить';
							|pl = 'Cancel';
							|tr = 'İptal edilecek'"));
		TitleLines.Add(NStr("vi = 'thanh toán bằng thẻ';
							|ru = 'оплату картами';
							|en = 'payment by cards'; fa = 'payment by cards';
							|it = 'оплату картами';
							|pl = 'payment by cards';
							|tr = 'kart ödemesi'"));
		ToolTipText = NStr("vi = 'Hủy thanh toán bằng thẻ';
							|ru = 'Отменить оплату платежными картами';
							|en = 'Void payment by cards'; fa = 'ابطال پرداخت با کارت‌ها';
							|it = 'Отменить оплату платежными картами';
							|pl = 'Anuluj płatność kartami płatniczymi';
							|tr = 'Ödeme kartıyla ödemeyi iptal et'");
	EndIf;
	
	Command.ToolTip                 = ToolTipText;
	Command.Title                 = StrConcat(TitleLines, Chars.LF);
	
	If SignHotkeysOnButtons Then
		RetailSales.SignHotkeyOnButton(Command);
	EndIf;
		
	ButtonHeadersAreConfigured = True;
	
EndProcedure

&AtServer
Function GetFormCommands(Var_UUID)
	
	FormCommands = New Array;
	For Each FormCommand In Commands Do
		If Not FormCommand.Shortcut.Key = Key.None Then
			FormCommands.Add(New Structure("CommandName, Title, Shortcut", FormCommand.Name, FormCommand.Title, FormCommand.Shortcut));
		EndIf;
	EndDo;
	
	Return PutToTempStorage(FormCommands, Var_UUID);
	
EndFunction

&AtClientAtServerNoContext
Procedure UpdateDashboardData(Form, DisplayChange = False)
	
	PaymentInformation = PaymentInformation(Form);

	ThisIsFullReturnToSalesShiftOfOldValue = Form.ThisIsFullReturnOnSalesShift; 
	Form.ThisIsFullReturnOnSalesShift = (ValueIsFilled(Form.Object.GiftCertificateSale) 
										And Form.DocumentAmount = Form.CashRegisterReceiptDetails.DocumentAmount
										And Form.Object.CashRegisterShift = Form.CashRegisterReceiptDetails.CashRegisterShift);
	If Form.ButtonHeadersAreConfigured Then
		Form.ButtonHeadersAreConfigured = (ThisIsFullReturnToSalesShiftOfOldValue = Form.ThisIsFullReturnOnSalesShift);
	EndIf;
	
	Form.RefundAmountInformationPanel                  = PaymentInformation.AmountToPay;
	
	Form.InformationPanelAmountToBeRefundedByPaymentCards = 0;   
	AmountByTypeOfPaymentPaymentCard = ?(Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"),
											PaymentInformation.PaymentCardsCanceled, PaymentInformation.PaymentCards);
	If AmountByTypeOfPaymentPaymentCard = 0 Then
		Form.InformationPanelAmountToBeRefundedInCash         = PaymentInformation.AmountToPay;
	Else
		Form.InformationPanelAmountToBeRefundedInCash         = PaymentInformation.AmountToPay - AmountByTypeOfPaymentPaymentCard;
		Form.InformationPanelAmountToBeRefundedByPaymentCards = AmountByTypeOfPaymentPaymentCard;
	EndIf;
	InfoBarLocalization(Form, PaymentInformation);
	
	NumberOfWHLines = Form.Object.GiftCertificates.Count();
	
	CurrentRow = Form.Items.GiftCertificates.CurrentRow;
	If CurrentRow = Undefined And NumberOfWHLines > 0 Then
		CurrentData = Form.Object.GiftCertificates[NumberOfWHLines - 1];
		Form.Items.GiftCertificates.CurrentRow = CurrentData.GetID();
	ElsIf CurrentRow = Undefined And NumberOfWHLines = 0 Then
		CurrentData = Undefined;
	Else
		CurrentData = Form.Object.GiftCertificates.FindByID(CurrentRow);
	EndIf;
	
	ProductName = "";
	If CurrentData <> Undefined Then
		ProductName = String(CurrentData.GiftCertificate);
	EndIf;
	
	RequiredDetails_ = New Array;
	
	RowData = New Structure;
	If CurrentData <> Undefined And ValueIsFilled(CurrentData.GiftCertificate) Then
		RowData.Insert("Nominal", Format(CurrentData.Nominal, "NFD=2") + " " + String(CurrentData.NominalCurrency));
	EndIf;
	
	SummaryParameters = New Structure;
	SummaryParameters.Insert("Count",                0);
	SummaryParameters.Insert("Price",                      0);
	SummaryParameters.Insert("ManualDiscount",         0);
	SummaryParameters.Insert("DiscountMarkupAmount", 0);
	SummaryParameters.Insert("Sum",                     0);
	If CurrentData <> Undefined Then
		SummaryParameters.Count = 1;
		SummaryParameters.Price       = CurrentData.Sum;
		FillPropertyValues(SummaryParameters, CurrentData);
	EndIf;
	
	Data = New Structure;
	Data.Insert("ProductName",    ProductName);
	Data.Insert("RowData",          RowData);
	Data.Insert("SummaryParameters",     SummaryParameters);
	Data.Insert("RequiredDetails_", RequiredDetails_);
	
	If DisplayChange Then
		
		TextDelivery = New FormattedString(
			StrTemplate(NStr("vi = 'Nhận trả lại: %1';
							|ru = 'Получить сдачу: %1';
							|en = 'Receive change: %1'; fa = 'Receive change: %1';
							|it = 'Ricevere resto: %1';
							|pl = 'Otrzymać resztę: %1';
							|tr = 'Para üstünü al: %1'"),
				Format(PaymentInformation.TotalPaid_ - PaymentInformation.AmountToPay, "NFD=2; NZ=0.00")));
		
		Data.Insert("DisplayChange", True);
		Data.Insert("TextDelivery",      TextDelivery);
		
	Else
		Data.Insert("DisplayChange", False);
	EndIf;
	
	RetailSalesClientServer.UpdateDashboardData(Form, Data);
	
EndProcedure

&AtClientAtServerNoContext
Function PaymentInformation(Form)
	
	PaymentWithPaymentCardsCanceled = 0;
	PaymentCards_ = RetailSalesClientServer.PaymentLinesWithPaymentCards(Form.Object.PaymentWithPaymentCards);
	For Each TSRow In PaymentCards_ Do
		If TSRow.PaymentIsCanceled Then
			PaymentWithPaymentCardsCanceled = PaymentWithPaymentCardsCanceled + TSRow.Sum;
		EndIf;
	EndDo;
	
	Form.DocumentAmount = Form.Object.GiftCertificates.Total("Sum");
	
	PaymentInformation = New Structure;
	PaymentInformation.Insert("Document",               Form.Object.Ref);
	
	PaymentInformation.Insert("CashPayment",               Form.Object.IssueInCash);
	PaymentInformation.Insert("PaymentCards",         Form.TotalAmountOfPaymentByCreditCards);
	PaymentInformation.Insert("PaymentCardsCanceled", PaymentWithPaymentCardsCanceled);
	PaymentInformation.Insert("GiftCertificates",  0);
	PaymentInformation.Insert("BonusPoints",          0);
	
	PaymentInformation.Insert("DocumentAmount",         Form.DocumentAmount);
	PaymentInformation.Insert("AmountToPay",           Form.DocumentAmount);
	PaymentInformation.Insert("DiscountAmount",            0);
	PaymentInformation.Insert("TotalPaid_",          PaymentInformation.CashPayment + PaymentWithPaymentCardsCanceled);
	
	PaymentInformation.Insert("AvailablePaymentMethods", RetailSalesClientServer.AvailablePaymentMethods(Form));
	
	PaymentInformationLocalization(Form, PaymentInformation);
	
	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	Form.TotalAmountOfPaymentByCreditCards = 0;
	If Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Form.TotalAmountOfPaymentByCreditCards = PaymentWithPaymentCardsCanceled;
	Else
		For Each CombinationOfUndeliveredPaymentAmounts In Form.CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards Do
			If CombinationOfUndeliveredPaymentAmounts <= AmountOfSurchargeIsEstimated
				And CombinationOfUndeliveredPaymentAmounts > Form.TotalAmountOfPaymentByCreditCards Then
				Form.TotalAmountOfPaymentByCreditCards = CombinationOfUndeliveredPaymentAmounts;
			EndIf;	
		EndDo;
	EndIf;	
	
	Return PaymentInformation;
	
EndFunction

&AtClient
Procedure PerformActionAfterRecording(NotificationOnCompletion, MessageText)
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParameters = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParameters.CallbackDescription         = NotificationOnCompletion;
		AdditionalParameters.MessageText             = MessageText;
		AdditionalParameters.ReturnFunctionResult = True;
		AdditionalParameters.ProcedureName               = "WriteAtServer";
		AdditionalParameters.OperationResult          = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParameters);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
			AdditionalParameters.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(NotificationOnCompletion, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PayInCashHandlingAlerts(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	PerformActionAfterRecording(
		New CallbackDescription("OpenCashPaymentForm", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure OpenCashPaymentForm(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.PaymentMethodByCash",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject));
	
EndProcedure

&AtClient
Procedure CancelPaymentUsingPaymentCardsProcessingNotifications(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	AdditionalParameters = New Structure;
	
	UpdateTheStateOfRegisterShift();

	// Calling the FormaAuthorizatiON of this connected equipment
	PerformActionAfterRecording(
		New CallbackDescription("AddCardPaymentCancellation", ThisObject),
		NStr("vi = 'Trước khi thực hiện thao tác trên thiết bị thanh toán thẻ, không thể ghi lại chứng từ.';
			|ru = 'Перед выполнением операции на ЭТ не удалось записать документ.';
			|en = 'Cannot save the document before performing the POS terminal transaction.'; fa = 'Cannot save the document before performing the POS terminal transaction.';
			|it = 'Перед выполнением операции на ЭТ не удалось записать документ.';
			|pl = 'Cannot save the document before performing the POS terminal transaction.';
			|tr = 'Перед выполнением операции на ЭТ не удалось записать документ.'"));
			
EndProcedure

&AtClient
Procedure CancelPaymentByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure MixedPaymentNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	PerformActionAfterRecording(
		New CallbackDescription("OpenMixedPaymentForm", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure OpenMixedPaymentForm(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	FormOpenParameters.Insert("ThisIsFullReturnOnSalesShift", ThisIsFullReturnOnSalesShift);
	FormOpenParameters.Insert("StatusOfSBPPaymentOfSalesReceipt", StatusOfSBPPaymentOfSalesReceipt);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.MixedPaymentForm",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject));
	
EndProcedure

#Region CancellationOfPaymentByPaymentCards

&AtClient
Procedure AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters)
	
	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	
	If ThisIsFullReturnOnSalesShift Then
		AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	Else
		AdditionalParameters.Insert("TransactionType",     "AuthorizeRefund");
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentsByPaymentCards(Result, AdditionalParameters) Export
	
	PaymentInformation = PaymentInformation(ThisObject);

	FormParameters = New Structure;
	FormParameters.Insert("AddressInStorage", CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards);
	
	FormParameters.Insert("ShowCancelPaymentsButtonSequentially", True);
	If DocumentAmount < TotalAmountOfPaymentByCreditCards Then
		FormParameters.Insert("ShowCancelPaymentButton", False);
		FormParameters.Insert("ShowCancelPaymentsButtonSequentially", False);
		FormParameters.Insert("ReadOnly", True);
	EndIf;
	FormParameters.Insert("ShowPaymentCanceledColumn", True);
	FormParameters.Insert("ThisIsReturn", True);
	FormParameters.Insert("ThisIsFullReturnOnSalesShift", ThisIsFullReturnOnSalesShift);
	
	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	FormParameters.Insert("DocumentAmount", AmountOfSurchargeIsEstimated);
	
	If AdditionalParameters.Property("ReceivedInCash") Then
		Object.IssueInCash = AdditionalParameters.ReceivedInCash;
	EndIf;
	
	OwnerForm = ThisObject;
	If AdditionalParameters.Property("Form") Then
		OwnerForm = AdditionalParameters.Form;
	EndIf;
	
	AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.TabularFormPaymentWithPaymentCards",
		FormParameters,OwnerForm,,,,
		New CallbackDescription("AddCardPaymentCancellationCompletion", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
//	Result - Structure - 
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
&AtClient
Procedure CancelPaymentsByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
	AdditionalParameters.Insert("ResultOfCancellationOfPaymentByPaymentCards", Result);
	NotificationAfterRecording = New CallbackDescription("CancelPaymentByPaymentCardsEndAfterRecording", ThisObject, AdditionalParameters);
	
	If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Data", AdditionalParameters.Form.Object.Ref);
		FormParameters.Insert("DataForEventLog", AdditionalParameters.Form.DataForEventLog);
		FormParameters.Insert("MessageText",
			NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
			|Chưa ghi nhận việc hủy thanh toán trong hệ thống.';
			|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
			|Отмена оплаты не зафиксирована в системе.';
			|en = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.'; fa = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.';
			|it = 'ATTENZIONE! Si è verificata una situazione eccezionale:
			| l''annullamento del pagamento non è stato registrato nel sistema.';
			|pl = 'UWAGA! Wystąpiła sytuacja wyjątkowa:
			|Anulowanie płatności nie zostało zarejestrowane w systemie.';
			|tr = 'UYARI! İstisnai bir durum meydana geldi:
			| Ödeme iptali sisteme kaydedilemedi.'"));
		
		OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, AdditionalParameters.Form);
	ElsIf Not Result.OperationPerformedOnDevice And Result.Property("CardPaymentCancellationData") Then
		If Result.CardPaymentCancellationData.Property("PaymentLine_") Then
			Object.PaymentWithPaymentCards.Delete(Result.CardPaymentCancellationData.PaymentLine_);
		ElsIf Result.CardPaymentCancellationData.Property("CurrentData") Then
			Object.PaymentWithPaymentCards.Delete(Result.CardPaymentCancellationData.CurrentData.LineNumber-1);
		EndIf;
		If Result.Property("TerminalUsedCorrespondsToSettings")
			And Not Result.TerminalUsedCorrespondsToSettings Then
			MessageTemplate = NStr("vi = 'Đã tắt hoặc thay đổi thiết bị thanh toán thẻ hiện tại (%1).
			|Nếu tùy chỉnh thiết bị đã thay đổi, thì để áp dụng những thay đổi này cần đóng quầy thu ngân và mở lại.';
			|ru = 'Текущий эквайринговый терминал (%1) отключен или изменен.
			|Если настройки оборудования изменены, то для их применения следует закрыть РМК и открыть заново.';
			|en = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.'; fa = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|it = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|pl = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|tr = 'PoS terminali (%1) kapatılmış veya değiştirilmiştir.
			|Ekipman ayarları değiştirilmişse, değişiklikleri uygulamak için KİY''yi kapatın ve yeniden açın.'");
			MessageText = StrTemplate(MessageTemplate, AdditionalParameters.CurrentData.POSTerminal);

			FormParameters = New Structure;
			FormParameters.Insert("Data", Object.Ref);
			FormParameters.Insert("DataForEventLog", AdditionalParameters.Form.DataForEventLog);
			FormParameters.Insert("MessageText", MessageText);
			OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, AdditionalParameters.Form);
			Return;
		EndIf;
		PerformActionAfterRecording(NotificationAfterRecording, NStr("vi = 'Trước khi mở hình thức trả lại thanh toán, không thể ghi chứng từ.';
																	|ru = 'Перед открытием формы возврата оплаты не удалось записать документ.';
																	|en = 'Cannot save the document before opening the refund form.'; fa = 'Cannot save the document before opening the refund form.';
																	|it = 'Перед открытием формы возврата оплаты не удалось записать документ.';
																	|pl = 'Cannot save the document before opening the refund form.';
																	|tr = 'Geri iade formu açılmadan önce belge kaydedilemedi.'"));
	Else
		RunCallback(NotificationAfterRecording, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentByPaymentCardsEndAfterRecording(Result, AdditionalParameters) Export
	
	If Result Then
		If ValueIsFilled(Object.GiftCertificateSale)
			And ValueIsFilled(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards)
			And CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards Then
			If AdditionalParameters.Property("ResultOfCancellationOfPaymentByPaymentCards")
				And AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.OperationPerformedOnDevice
				And AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.Property("CardPaymentCancellationData") Then
				
				IdOfPaymentLine = AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.CardPaymentCancellationData.PaymentLine_.GetID();
				LineNumberOfPaymentCardBeingCancelled = CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard[IdOfPaymentLine];
				AmountOfCancelledPayment = AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.CardPaymentCancellationData.PaymentLine_.Sum;
				
				ResultOfRecalculation = RetailSalesServerCall.RecalculateDataOfNonCanceledPaymentsByPaymentCards(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards, LineNumberOfPaymentCardBeingCancelled, AmountOfCancelledPayment);				
				CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards = ResultOfRecalculation.DataOfFirstNonCancelledPaymentByPaymentCards;
				CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = ResultOfRecalculation.NumberOfOutstandingPaymentsByPaymentCards;
				CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards = ResultOfRecalculation.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards;
				CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard = ResultOfRecalculation.LowestAmountOfNonCancelledPaymentByPaymentCard;
				CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Delete(IdOfPaymentLine);
				
			EndIf;
		EndIf;
		
		If AdditionalParameters.Property("Action") And AdditionalParameters.Action = "CancelPaymentsSequentially"
				And AdditionalParameters.Property("PaymentLinesWithPaymentCards") And AdditionalParameters.PaymentLinesWithPaymentCards.Count() Then
			RunCallback(New CallbackDescription("CancelPaymentByCreditCardsSequentially", RetailSalesClient, AdditionalParameters)
										, AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards);
		Else
			NotificationToMixedPaymentForm	= Undefined;
			NotificationParameters = AdditionalParameters;
			While ValueIsFilled(NotificationParameters) Do
				If NotificationParameters.Property("NotificationToPaymentForm", NotificationToMixedPaymentForm) Then
					Break;
				ElsIf NotificationParameters.Property("NotificationOnCompletion") Then
					NotificationParametersNotificationAtEnd = NotificationParameters.NotificationOnCompletion; // CallbackDescription
					NotificationParameters = NotificationParametersNotificationAtEnd.AdditionalParameters;
				Else
					NotificationParameters = Undefined;
				EndIf;
			EndDo;
			If NotificationToMixedPaymentForm = Undefined Then
				MixedPayment(Undefined);
			Else
				RunCallback(NotificationToMixedPaymentForm, PaymentInformation(ThisObject));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCard(Result, AdditionalParameters) Export
	
	PerformActionAfterRecording(
		New CallbackDescription("CancelCardPayment", RetailSalesClient, AdditionalParameters),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCardCompletion(Result, AdditionalParameters) Export
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  AdditionalParameters.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", AdditionalParameters.ReferenceNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    AdditionalParameters.ReceiptNumber);
	
	PaymentLine_ = Object.PaymentWithPaymentCards.Get(Object.PaymentWithPaymentCards.IndexOf(AdditionalParameters.PaymentLine_));
	PaymentLine_.PaymentIsCanceled = True;

	// Additional filling of operation acquisition data in case of a refund of an arbitrary amount
	If AdditionalParameters.Property("AnyAmountReturnedToPaymentCard") And AdditionalParameters.AnyAmountReturnedToPaymentCard = True Then
		PaymentLine_.PaymentCardNumber = AdditionalParameters.CardNumber;
		PaymentLine_.ReferenceNumber		 = AdditionalParameters.ReferenceNumber;
		PaymentLine_.POSTerminalReceiptNumber		 = AdditionalParameters.ReceiptNumber;
		PaymentLine_.AuthorizationCode		 = AdditionalParameters.AuthorizationCode;
	EndIf;

	Modified = True;
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParametersRepeatRecording = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersRepeatRecording.CallbackDescription             = AdditionalParameters.NotificationOnCompletion;
		AdditionalParametersRepeatRecording.MessageText                 = NStr("vi = 'Sau khi hoàn thành thao tác thanh toán hủy, Chứng từ không thể được ghi.';
																				|ru = 'После выполнения операции отмены оплаты не удалось записать документ.';
																				|en = 'Cannot save the document after payment cancellation transaction has been executed.'; fa = 'Cannot save the document after payment cancellation transaction has been executed.';
																				|it = 'Dopo aver annullato il pagamento non è stato possibile registrare il documento.';
																				|pl = 'Po wykonaniu operacji odwołania płatności nie udało się zapisać dokumentu.';
																				|tr = 'Bir ödeme iptal işlemi gerçekleştirildikten sonra belge kaydedilemedi.'");
		AdditionalParametersRepeatRecording.ReturnFunctionResult     = False;
		AdditionalParametersRepeatRecording.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True);
		AdditionalParametersRepeatRecording.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False);
		AdditionalParametersRepeatRecording.ProcedureName                   = "WriteAtServer";
		AdditionalParametersRepeatRecording.OperationResult              = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersRepeatRecording);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersRepeatRecording),
			AdditionalParametersRepeatRecording.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(
			AdditionalParameters.NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData",
				True, True, AdditionalParameters));
		
	EndIf;
	
EndProcedure

// Called from the complex payment form
//
// Parameters:
//  Result - Structure - 
//  AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure PaymentCancel(Result, AdditionalParameters) Export
	
	RunCallback(
		New CallbackDescription("AddCardPaymentCancellation", ThisObject, AdditionalParameters));
	
EndProcedure

// Called from the complex payment form
//
// Parameters:
//  Result - Structure - 
//  AdditionalParameters - See AdditionalCompletionProcessingParameters
&AtClient
Procedure CancelPaymentReverse(Result, AdditionalParameters) Export
	
	// Delete the lines added for canceling payments with payment cards
	TheStructureOfTheSearch = New Structure("PaymentKind_", PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard"));
	FoundRows = Object.PaymentWithPaymentCards.FindRows(TheStructureOfTheSearch);
	NeedToWrite = False;
	If FoundRows.Count() Then
		NeedToWrite = True;
		For Each FoundRow In FoundRows Do
			Object.PaymentWithPaymentCards.Delete(FoundRow);	
		EndDo;
		FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt();
	EndIf;

	// We'll click in the lines to indicate that the payment was canceled.
	TheStructureOfTheSearch = New Structure("PaymentIsCanceled", True);
	FoundRows = Object.PaymentWithPaymentCards.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() Then
		NeedToWrite = True;
		For Each FoundRow In FoundRows Do
			FoundRow.PaymentIsCanceled = False;
		EndDo;
	EndIf;
	
	NotificationOnCompletion = New CallbackDescription("PaymentCancelCompletion", ThisObject, AdditionalParameters);
	If NeedToWrite Then
		Modified = True;
		PerformActionAfterRecording(NotificationOnCompletion
									, NStr("vi = 'Trước khi đóng hình thức trả lại thanh toán, không thể ghi chứng từ.';
											|ru = 'После закрытия формы возврата оплаты не удалось записать документ.';
											|en = 'Cannot save the document after closing the refund form.'; fa = 'Cannot save the document after closing the refund form.';
											|it = 'После закрытия формы возврата оплаты не удалось записать документ.';
											|pl = 'Cannot save the document after closing the refund form.';
											|tr = 'Geri iade formu kapandıktan sonra belge kaydedilemedi.'"));
	Else
		RunCallback(NotificationOnCompletion);
	EndIf;
	
EndProcedure

&AtClient
Procedure AddCardPaymentCancellation(Result, CompletionParameters) Export
		
	CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Clear();
	If Result = False Then
		MessageText = NStr("vi = 'Trước khi thêm dữ liệu để hủy bỏ thao tác thanh toán bằng thẻ, không thể ghi lại chứng từ.';
							|ru = 'Перед добавлением данных для отмены операции оплаты картой не удалось записать документ.';
							|en = 'Cannot save the document before adding data to cancel the payment by card.'; fa = 'Cannot save the document before adding data to cancel the payment by card.';
							|it = 'Перед добавлением данных для отмены операции оплаты картой не удалось записать документ.';
							|pl = 'Cannot save the document before adding data to cancel the payment by card.';
							|tr = 'Kart ödemesi işlemini iptal etmek için veri eklenmeden önce belge kaydedilemedi.'");
		RetailSalesServerCall.LogEntry(
		MessageText, "CashRegisterReceiptReturns.CWPDocumentForm.AddCardPaymentCancellation", Object.Ref);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	PaymentInformation = PaymentInformation(ThisObject);
	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	
	ResultForContinuation = Undefined;
	
	AdditionalParameters = CompletionParameters;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("AnyAmountReturnedToPaymentCard", False);
	If CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards <= 1 
		Or CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard > AmountOfSurchargeIsEstimated Then

		If CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = 1
			And CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards <> Undefined
			And CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.Sum <= AmountOfSurchargeIsEstimated Then
			// If there is one undone card payment and the amount on it is less than or equal to the return amount according to the document
			
			SequentialCancellation = False;
			ResultForContinuation = New Structure;
			
			CardPaymentLine = Object.PaymentWithPaymentCards.Add();
			CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
			CardPaymentLine.POSTerminal = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.POSTerminal;
			CardPaymentLine.PaymentCardNumber	 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.PaymentCardNumber;
			CardPaymentLine.Sum				 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.Sum;
			CardPaymentLine.ReferenceNumber		 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.ReferenceNumber;
			CardPaymentLine.POSTerminalReceiptNumber			 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.POSTerminalReceiptNumber;
			CardPaymentLine.AuthorizationCode		 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.AuthorizationCode;
			
			ResultForContinuation.Insert("Action", "PaymentCancel");
			ResultForContinuation.Insert("RowSelected", CardPaymentLine);

			CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Insert(CardPaymentLine.GetID(), CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.LineNumber);
			
			AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
			ContinueNotification = New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters);
			
		Else
			// if the return amount according to the document exceeds the smallest amount of the non-cancelled card payment
			// or if there is not a single non-cancelled card payment
			CallbackOnCompletion = New CallbackDescription("AddCardPaymentCancellationCompletion", ThisObject, CompletionParameters);
			If ValueIsFilled(CompletionParameters) Then 
				If CompletionParameters.Property("CallbackOnCompletion") Then
					CallbackOnCompletion = CompletionParameters.CallbackOnCompletion;
				EndIf;
			EndIf;
			AdditionalParameters.Insert("CallbackOnCompletion", CallbackOnCompletion);
			
			AdditionalParameters.Insert("Form",                  ThisObject);
			AdditionalParameters.Insert("POSTerminals", POSTerminals);
			AdditionalParameters.Insert("CashRegisterParameters",      CashRegisterParameters);
			AdditionalParameters.Insert("Currency",                       Object.Currency);
			AdditionalParameters.Insert("StructureAcquiringTerminal");
			AdditionalParameters.Insert("IDOfETDevice");
			AdditionalParameters.Insert("JustFillInResultOfCardPayment", True);

			IndicatedAmountDueInCash = 0;
			If AdditionalParameters.Property("ReceivedInCash") Then
				IndicatedAmountDueInCash = AdditionalParameters.ReceivedInCash;
			EndIf;
			
			AdditionalParameters.Insert("AuthorizationForm_Amount",       PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_ - IndicatedAmountDueInCash);
			AdditionalParameters.Insert("AuthorizationForm_AmountLimit", PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_);
			
			ContinueNotification = New CallbackDescription("AddCardPayment", RetailSalesClient, AdditionalParameters);
			ResultForContinuation = True;
		EndIf;
	Else
		ContinueNotification = New CallbackDescription("CancelPaymentsByPaymentCards", ThisObject, AdditionalParameters);
	EndIf;
	
	RunCallback(ContinueNotification, ResultForContinuation);		
	
EndProcedure

&AtClient
Procedure AddCardPaymentCancellationCompletion(Result, AdditionalParameters) Export

	CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Clear();
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;

	If Not ValueIsFilled(AdditionalParameters) Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("AnyAmountReturnedToPaymentCard", False);
	
	SequentialCancellation = False;
	SelectionResult = New Structure;
	ArrayOfRowsOfCanceledPaymentsByPaymentCards = New Array;
	
	// Adding the lines for canceling the payment to the table part
	If Not Result.Property("Action") Then
		// Cancellation of payment from the CWP form or from the mixed payment form, 
		// The structure of the result of cancellation of payment by card differs from the Attributes of the tabular part.
		// Add a row to the table part
		CardPaymentLine = Object.PaymentWithPaymentCards.Add();
		CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
		CardPaymentLine.POSTerminal = Result.POSTerminal;
		CardPaymentLine.PaymentCardNumber	 = Result.CardNumber;
		CardPaymentLine.Sum				 = Result.TransactionAmount;
		CardPaymentLine.ReferenceNumber		 = Result.ReferenceNumber;
		CardPaymentLine.POSTerminalReceiptNumber			 = Result.ReceiptNumber;
		CardPaymentLine.AuthorizationCode		 = Result.AuthorizationCode;
		ArrayOfRowsOfCanceledPaymentsByPaymentCards.Add(CardPaymentLine);
		
		AdditionalParameters.AnyAmountReturnedToPaymentCard = True;
		SelectionResult.Insert("Action", "PaymentCancel");
	Else
		// Cancellation of payment from the form of the tabular part Payment by payment cards
		SelectedPaymentCancellationLinesToAdd = New Array;	
		SelectionResult.Insert("Action", Result.Action);
		If Result.Action = "PaymentCancel" Then
			// Save card payment data in the table
			SelectedPaymentCancellationLinesToAdd.Add(Result.RowSelected);
		ElsIf Result.Action = "CancelPaymentsSequentially" Then
			SequentialCancellation = True;
			SelectedPaymentCancellationLinesToAdd = Result.RowsSelected;
		EndIf;
		
		// Add rows to the table part
		If SelectedPaymentCancellationLinesToAdd.Count() Then
			For Each LineToCancel In SelectedPaymentCancellationLinesToAdd Do
				CardPaymentLine = Object.PaymentWithPaymentCards.Add();
				CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
				CardPaymentLine.POSTerminal = LineToCancel.POSTerminal;
				CardPaymentLine.PaymentCardNumber	 = LineToCancel.PaymentCardNumber;
				CardPaymentLine.Sum				 = LineToCancel.Sum;
				CardPaymentLine.ReferenceNumber		 = LineToCancel.ReferenceNumber;
				CardPaymentLine.POSTerminalReceiptNumber			 = LineToCancel.POSTerminalReceiptNumber;
				CardPaymentLine.AuthorizationCode		 = LineToCancel.AuthorizationCode;
				ArrayOfRowsOfCanceledPaymentsByPaymentCards.Add(CardPaymentLine);
				
       			CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Insert(CardPaymentLine.GetID(), LineToCancel.LineNumber);
			EndDo;
		Else
			Return;
		EndIf;
	EndIf;
	
	If SequentialCancellation Then
		SelectionResult.Insert("RowSelected", ArrayOfRowsOfCanceledPaymentsByPaymentCards);
	Else
		SelectionResult.Insert("RowSelected", ArrayOfRowsOfCanceledPaymentsByPaymentCards[0]);
	EndIf;
	
	AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
	
	CallbackDescription = New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters);
	RunCallback(CallbackDescription, SelectionResult);
	
EndProcedure

&AtClient
Procedure PaymentCancelCompletion(Result, AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation(ThisObject));
	
EndProcedure

#EndRegion

&AtClient
Procedure CompletionOfPayment(PaymentResult, AdditionalParameters) Export
	
	If TypeOf(PaymentResult) = Type("Structure")
		And PaymentResult.Property("ReceivedInCash")
		And PaymentResult.Property("ElectronicReceiptData") Then
		
		Object.IssueInCash = PaymentResult.ReceivedInCash;
		Object.Partner         = PaymentResult.ElectronicReceiptData.Partner;
		
		FiscalOperationData.OptionOfSendingElectronicReceipt  = PaymentResult.ElectronicReceiptData.OptionOfSendingElectronicReceipt;
		FiscalOperationData.ContactDetailsOfElectronicReceipt = PaymentResult.ElectronicReceiptData.ContactDetailsOfElectronicReceipt;
		
	ElsIf PaymentResult = "Cancel" Then

		RetailSalesClient.UnblockForm(ThisObject);
		RecalculateDocumentOnClient();
		Return;
		
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Exit") 
		And AdditionalParameters.Exit = True Then
		
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ProcessPaymentAddition(AdditionalParameters)
	
	PaymentInformation = PaymentInformation(ThisObject);
	// The card payment command was called from the RMK form
	If AdditionalParameters = Undefined Then
		
		If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
			
			UpdateDashboardData(ThisObject, True);
			RetailSalesClient.UnblockForm(ThisObject);
			
		Else
			
			If PaymentInformation.TotalPaid_ >= PaymentInformation.AmountToPay
				And ValueIsFilled(FiscalOperationData.OptionOfSendingElectronicReceipt) Then
				
				UpdateDashboardData(ThisObject, True);
				
				IssueCashReceipt();
				
			ElsIf PaymentInformation.TotalPaid_ > 0 Then
				
				PerformActionAfterRecording(
					New CallbackDescription("OpenMixedPaymentForm", ThisObject),
					NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
						|ru = 'Перед открытием формы оплаты не удалось записать документ.';
						|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
						|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
						|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
						|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
				
				AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
				
			Else
				
				RetailSalesClient.UnblockForm(ThisObject);
				AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
				
			EndIf;
			
		EndIf;
		
	Else
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessPrintCommand(CommandName, AdditionalParameters) Export

	AttachableCommandsClient.ExecuteCommand(ThisObject, Commands[CommandName], Object);

EndProcedure

// Constructor function for additional parameters that are returned in completion processing
// Returns:
// 	Structure - advanced setting:
// 	* Ref - Undefined - 
// 	
&AtClient
Function AdditionalCompletionProcessingParameters()
	
	Result = New Structure;
	Result.Insert("Ref", Undefined);
	
	Return Result;
	
EndFunction

&AtClient
Procedure UploadNewReceipt(Ref)
	
	If Object.Status <> PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		
		AdditionalParameters = AdditionalCompletionProcessingParameters();
		AdditionalParameters.Ref = Ref;
		
		Cancel = False;
		BeforeClosingReceipt(
			Cancel,
			New CallbackDescription("UploadNewReceiptCompletion", ThisObject, AdditionalParameters));
		If Cancel Then
			Return;
		EndIf;
		
	Else
		
		NewReceiptOnServer(Ref);
		UploadNewReceiptFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadNewReceiptFragment()
	
	RecalculateDocumentOnClient();
	
EndProcedure

// Parameters:
//  Result - Boolean, Undefined -
// 	AdditionalParameters - See AdditionalCompletionProcessingParameters
// 
&AtClient
Procedure UploadNewReceiptCompletion(Result, AdditionalParameters) Export
	
	NewReceiptOnServer(AdditionalParameters.Ref);
	
	UploadNewReceiptFragment();
	
EndProcedure

&AtServer
Function PostponeOnServer(RetryRecordingIsRequired)
	
	PostponeCompleted = True;
	
	OldStatus = Object.Status;
	Object.Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	
	Try
		
		PostponeCompleted = WriteAtServer(RetryRecordingIsRequired);
		
		If Not PostponeCompleted Then
			Object.Status = OldStatus;
		EndIf;
		
	Except
		
		Object.Status = OldStatus;
		PostponeCompleted = False;
		
	EndTry;
	
	Return PostponeCompleted;
	
EndFunction

&AtClient
Procedure DeferOnClient(NotificationOnCompletion)
	
	Modified = True;
	
	RetryRecordingIsRequired = False;
	Result = PostponeOnServer(RetryRecordingIsRequired);
		
	ProcessGiftCertificatesOnServer();
	
	If Not Result Then
		
		AdditionalParametersAttempt = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersAttempt.CallbackDescription         = NotificationOnCompletion;
		AdditionalParametersAttempt.MessageText             = NStr("vi = 'Không thể ghi chứng từ.';
																	|ru = 'Не удалось записать документ.';
																	|en = 'Cannot save the document.'; fa = 'Cannot save the document.';
																	|it = 'Non è stato possibile registrare il documento.';
																	|pl = 'Nie udało się zapisać dokumentu.';
																	|tr = 'Belge kaydedilemedi.'");
		AdditionalParametersAttempt.ReturnFunctionResult = True;
		AdditionalParametersAttempt.ProcedureName               = "PostponeOnServer";
		AdditionalParametersAttempt.OperationResult          = Result;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersAttempt);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersAttempt),
			AdditionalParametersAttempt.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(NotificationOnCompletion, Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingReceipt(Cancel, CallbackDescription = Undefined)
	
	Buttons = New ValueList;
	
	If Not ReadOnly And (Modified Or ValueIsFilled(Object.Ref)) Then
		
		If AccessRights.Snooze Then
			Buttons.Add(1, NStr("vi = 'Hoãn lại';
								|ru = 'Отложить';
								|en = 'Put on hold'; fa = 'نگه‌داشتن';
								|it = 'Rinvia';
								|pl = 'Put on hold';
								|tr = 'Ertele'"));
		EndIf;
		
		If ValueIsFilled(Object.Ref) And AccessRights.LineAdjustment Then
			Buttons.Add(4, NStr("vi = 'Xóa bỏ phiếu';
								|ru = 'Удалить чек';
								|en = 'Remove receipt'; fa = 'Remove receipt';
								|it = 'Elimina scontrino';
								|pl = 'Usuń paragon';
								|tr = 'Makbuzu sil'"));
		Else
			If Modified And AccessRights.LineAdjustment Then
				Buttons.Add(3, NStr("vi = 'Đóng không lưu';
									|ru = 'Закрыть без сохранения';
									|en = 'Close without saving'; fa = 'بستن بدون ذخیره';
									|it = 'Chiudi senza salvare';
									|pl = 'Zamknij bez zapisywania';
									|tr = 'Kaydetmeden kapat'"));
			EndIf;
			If Not Modified And AccessRights.LineAdjustment Then
				Buttons.Add(3, NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Zamknij';
									|tr = 'Kapat'"));
			EndIf;
		EndIf;
		
		Buttons.Add(99, NStr("vi = 'Hủy bỏ';
							|ru = 'Отмена';
							|en = 'Cancel'; fa = 'انصراف';
							|it = 'Annulla';
							|pl = 'Anuluj';
							|tr = 'İptal'"));
		
	EndIf;
	
	If Buttons.Count() > 0 Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("QuestionBeforeClosingCheckEnds", ThisObject, AdditionalParameters),
			NStr("vi = 'Chọn một hành động trước khi đóng.';
				|ru = 'Выберите действие перед закрытием.';
				|en = 'Select an action before closing.'; fa = 'Select an action before closing.';
				|it = 'Scegliere operazione prima della chiusura.';
				|pl = 'Wybierz czynność przed zamknięciem';
				|tr = 'Kapatmadan önce bir eylem seçin.'"),
			Buttons);
		
	Else
		
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingOperationCompletion(Result, AdditionalParameters) Export
	
	Notify("Write_ReturnOfGiftCards", New Structure, Undefined);
	
	If Result Then
		
		If AdditionalParameters.CallbackDescription = Undefined Then
			ForcedShutdown = True;
			Close(Undefined);
		Else
			RunCallback(AdditionalParameters.CallbackDescription, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingCheckEnds(QuestionResult, AdditionalParameters) Export
	
	RetailSalesClient.UnblockForm(ThisObject);
	
	If QuestionResult = 1 Then
		
		// Postpone the receipt without reservation
		DeferOnClient(New CallbackDescription("QuestionBeforeClosingOperationCompletion", ThisObject, AdditionalParameters));
		
	ElsIf QuestionResult = 3 Then
		
		// Close without saving.
		If AdditionalParameters.CallbackDescription = Undefined Then
			ForcedShutdown = True;
			Close(Undefined);
		Else
			RunCallback(AdditionalParameters.CallbackDescription, Undefined);
		EndIf;
		
	ElsIf QuestionResult = 4 Then
		
		// Delete the receipt.
		DeletionCompleted_ = RetailSalesServerCall.DeleteDocumentWhenCancelingFiscalTransaction(Object.Ref);
		
		If DeletionCompleted_ Then
			
			Notify("Write_ReturnOfGiftCards", New Structure, Undefined);
			
			If AdditionalParameters.CallbackDescription = Undefined Then
				ForcedShutdown = True;
				Close(Undefined);
			Else
				RunCallback(AdditionalParameters.CallbackDescription, Undefined);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NewReceiptOnServer(Ref)
	
	NewReceipt = Ref.GetObject();
	
	NewReceipt.Date = CurrentSessionDate();
	UnlockFormDataForEdit();
	ValueToFormData(NewReceipt, Object);
	
	ProcessGiftCertificatesOnServer();
	
	ReadOnly = False;
	Modified = False;
	
	WhenCreatingReceipt();
	
EndProcedure

&AtServer
Procedure WhenCreatingReceipt()
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
	FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	RefreshFormTitle();
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	ConfigureCWP();
	
EndProcedure

&AtServer
Procedure GetStatusOfSBPPaymentForPSImplementation()
	
	StatusOfSBPPaymentOfSalesReceipt = Enums.TypesOfSBPPaymentStatuses.EmptyRef();
	
	If ValueIsFilled(Object.GiftCertificateSale) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	GiftCertificateSalePaymentWithPaymentCards.SBPPaymentStatus
		|FROM
		|	Document.GiftCertificateSale.PaymentWithPaymentCards AS
		|		GiftCertificateSalePaymentWithPaymentCards
		|WHERE
		|	GiftCertificateSalePaymentWithPaymentCards.Ref = &Ref
		|	AND GiftCertificateSalePaymentWithPaymentCards.PaymentKind_ = &PaymentKind_";
		
		Query.SetParameter("Ref", Object.GiftCertificateSale);
		Query.SetParameter("PaymentKind_", Enums.TypesOfCashRegisterPaymentSystem.InstantPayments);
		
		SBPPaymentTable = Query.Execute().Select();
		If  SBPPaymentTable.Next() Then
			StatusOfSBPPaymentOfSalesReceipt = SBPPaymentTable.SBPPaymentStatus;
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateTotalAmountOfPayments(Form)
	
	Form.TotalAmountOfPaymentByCreditCards = RetailSalesClientServer.AmountOfPaymentByPaymentCards(Form.Object.PaymentWithPaymentCards);
	
	RecalculateTotalAmountOfPaymentsLocalization(Form);
	
EndProcedure

// Parameters:
//  Form - ClientApplicationForm
//  AvailablePaymentMethods - Structure
//
&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfCWPElements(Form, AvailablePaymentMethods)
	
	ThereAreReturnablePositions = (Form.Object.GiftCertificates.Count() > 0);
	Form.Items.PayInCash.Enabled = ThereAreReturnablePositions;
	Form.Items.PaymentByCard.Enabled    = ThereAreReturnablePositions;
	Form.Items.MixedPayment.Enabled   = ThereAreReturnablePositions;
	
	If AvailablePaymentMethods.PaymentCards Then
		If Form.TotalAmountOfPaymentByCreditCards > Form.DocumentAmount Then
			Form.Items.PaymentByCard.Enabled = False;
		EndIf;
	EndIf;
	
	EstablishAvailabilityOfCWPElementsLocalization(Form, AvailablePaymentMethods);
	
EndProcedure

&AtClient
// Called from the MENUOPERATIONISKKM form
Procedure ChangeTheCashRegisterOfTheKKMCompletion(CashRegister, AdditionalParameters) Export
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If Object.CashRegister <> CashRegister Then		
		ChangeTheCashRegisterOfTheKKM(CashRegister);
		RecalculateDocumentOnClient();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeTheCashRegisterOfTheKKM(CashRegister)
	
	Object.CashRegister = CashRegister;
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	
	If ValueIsFilled(Object.GiftCertificateSale) Then
		// We only change the Attributes associated with the cash account (except for the Cashier), the composition of the returned gift certificates does not change.
		RegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
		FillPropertyValues(Object, RegisterShiftState,,"Cashier");
	Else
		NewReceipt = Documents.ReturnOfGiftCards.CreateDocument();
		NewReceipt.Partner = Catalogs.Partners.RetailCustomer;
		NewReceipt.Filling(New Structure("CashRegister", Object.CashRegister), True);
		NewReceipt.Date = CurrentSessionDate();
		
		Cashier = ?(ValueIsFilled(Object.Cashier), Object.Cashier, NewReceipt.Cashier);
		ValueToFormData(NewReceipt, Object);
		Read();
		
		FormEvents.OnReadAtServer(ThisObject, NewReceipt);
		Object.Cashier = Cashier;
	EndIf;
	
	ReadOnly = False;
	Modified = False;
	
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	RefreshFormTitle();
	UpdateDashboardData(ThisObject, True = ReadOnly);

	ConfigureCWP();
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

// Parameters:
//  Form - ClientApplicationForm
//  AvailablePaymentMethods - Structure
&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfCWPElementsLocalization(Form, AvailablePaymentMethods)
	
	
EndProcedure

&AtClient
Procedure PrintingReceiptAfterRecordingChangesLocalization(ParametersOfReceiptFiscalizationOperation)
	
	
	//@skip-warning
	SetFiscalStatusBroken();
	
	RetailSalesClient.UnblockForm(ThisObject);
	
EndProcedure

&AtServer
Function ParametersOfReceiptFiscalizationOperationOnServerLocalization(PaymentInformation)
	
	ParametersOfReceiptFiscalizationOperation = New Structure;
	
	
	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

&AtClient
Procedure SetFiscalStatusBroken()
	
	Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_");
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
	
	Write(WriteParameters);
	
	ReadOnly = True;
	
	CommonClient.MessageToUser(
		NStr("vi = 'Chưa triển khai tính năng in phiếu đối với chứng từ. Hãy liên hệ với nhà phát triển.';
			|ru = 'Функционал печати чека для документа не реализован. Обратитесь к разработчикам.';
			|en = 'Printing a receipt for the document is not implemented. Contact the developers.'; fa = 'Printing a receipt for the document is not implemented. Contact the developers.';
			|it = 'Il funzionale di stampa dello scontrino per il documento non è venduto. Rivolgersi agli elaboratori.';
			|pl = 'Funkcja drukowania paragonu dla dokumentu nie jest zaimplementowana. Zwróć się do deweloperów.';
			|tr = 'Belge için makbuz yazdırma işlevi uygulanmamıştır. Geliştiricilerle iletişime geçin.'"));
	
EndProcedure

&AtServer
Procedure ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup)
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure PaymentInformationLocalization(Form, PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure PayForSBPLocalization()
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure InfoBarLocalization(Form, PaymentInformation)
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure RecalculateTotalAmountOfPaymentsLocalization(Form)
	
	
EndProcedure

&AtServer
Procedure ToEstablishPossibilityOfUsingSBPPaymentOnCWPLocalizationForms()
	
	
EndProcedure

#EndRegion
