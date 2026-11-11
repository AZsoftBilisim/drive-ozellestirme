
#Region FormEventHandlers

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
	ParametersForProcessingGiftCertificates.RegisterNewOnes = True;

	ArrayOfStatuses = New Array;
	ArrayOfStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.NotActivated"));
	ParametersForProcessingGiftCertificates.Filters.Insert("Status", ArrayOfStatuses);
	ParametersForProcessingGiftCertificates.Filters.Insert("Organization", Object.Organization);
	ParametersForProcessingGiftCertificates.Filters.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));
	
	SetSelectionParametersForGiftCertificate(ThisObject);
	
	OnReadCreateAtServer();
	ToEstablishPossibilityOfUsingSBPPaymentOnCWPLocalizationForms();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	WhenCreatingReceipt();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.PeriodClosingDates
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.PeriodClosingDates
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
	
	If ChoiceSource.FormName = "Document.GiftCertificateSale.Form.SelectDeferredReceipt" 
		And Object.Ref <> ValueSelected Then
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

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_GiftCertificateSale", WriteParameters, Object.Ref);
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
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

#Region FormTableItemsEventHandlersGiftCertificates

&AtClient
Procedure GiftCertificatesOnActivateRow(Item)
	
	UpdateDashboardData(True = ReadOnly);
	
EndProcedure

&AtClient
Procedure GiftCertificatesOnChange(Item)
	
	RecalculateDocumentOnClient();
	
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
	
	RetailSalesClient.ProcessShiftState(
		ThisObject, 
		New CallbackDescription("PayByCreditCardProcessingNotifications", ThisObject));
	
EndProcedure

&AtClient
Procedure MixedPayment(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("MixedPaymentNotificationProcessing", ThisObject));
	
EndProcedure

&AtClient
Procedure PayForSBP(Command)
	
	PayForSBPLocalization();
	
EndProcedure

&AtClient
Procedure NewReceipt(Command)
	
	UploadNewReceipt();
	
EndProcedure

&AtClient
Procedure GoodsReturn(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	NotificationProcessing = New CallbackDescription("ReturnOfGoodsProcessingOfNotification", ThisObject);
	
	RetailSalesClient.ProcessShiftState(ThisObject, NotificationProcessing);
	
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
	
	If ShowForPaymentOnACustomerDisplay Then
		
		PaymentInformation = PaymentInformation(ThisObject);
		Dptext1 = RetailSalesClient.PrepareLineForDisplay(
			NStr("vi = 'Cần thanh toán:';
				|ru = 'К оплате:';
				|en = 'Amount due:'; fa = 'Amount due:';
				|it = 'Da pagare:';
				|pl = 'Do płatności:';
				|tr = 'Ödenecek:'"), PaymentInformation.AmountToPay);
		Dptext2 = "";
		
	Else
		
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
		
	EndIf;
	
	RetailSalesClient.DisplayTextOnBuyerSDisplays(
		ThisObject,
		Displays,
		Dptext1 + Chars.LF + Dptext2);
	
EndProcedure

#EndRegion

#Region Other

&AtClient
Procedure OpenAuthorizationWindow()
	
	OpenForm("Document.CashRegisterReceipt.Form.Authorization", New Structure("Mode", "ChangeRights"), ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	UpdateOrganizationVATPayer();
	
	Query = New Query(
	"SELECT
	|	CAST(T.GiftCertificate AS Catalog.GiftCertificates) AS GiftCertificate
	|INTO TempTable
	|FROM
	|	&GiftCertificates AS T
	|
	|INDEX BY
	|	GiftCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTable.GiftCertificate AS GiftCertificate,
	|	GiftCertificates.Owner.Nominal AS Nominal,
	|	GiftCertificates.Owner.Currency AS NominalCurrency
	|FROM
	|	TempTable AS TempTable
	|		LEFT JOIN Catalog.GiftCertificates AS GiftCertificates
	|		ON TempTable.GiftCertificate = GiftCertificates.Ref");
	
	Query.SetParameter("GiftCertificates", Object.GiftCertificates.Unload());
	CurrentSessionDate = CurrentSessionDate();
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		FoundRows = Object.GiftCertificates.FindRows(New Structure("GiftCertificate", Selection.GiftCertificate));
		For Each TSRow In FoundRows Do
			TSRow.Nominal        = Selection.Nominal;
			TSRow.NominalCurrency = Selection.NominalCurrency;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetryRecordingIsRequired = False;
		If AdditionalParameters.ProcedureName = "WriteAtServer" Then
			OperationResult = WriteAtServer(RetryRecordingIsRequired);
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
		Value = FormDataToValue(Object, Type("DocumentObject.GiftCertificateSale"));
		Value.SetNewObjectRef(Documents.GiftCertificateSale.GetRef());
		ValueToFormData(Value, Object);
	EndIf;
	
	Result = False;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add();
		LockItem.Region = "Document.GiftCertificateSale";
		LockItem.Mode = DataLockMode.Shared;
		LockItem.SetValue("Ref", Object.Ref);
		Block.Lock();
		
		Result = Write(New Structure("WriteMode, PostingMode", DocumentWriteMode.Posting, DocumentPostingMode.RealTime));
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		RetryRecordingIsRequired = True;
		
	EndTry;
	
	Return Result;
	
EndFunction

&AtClient
Function WriteAtClient(RetryRecordingIsRequired = Undefined)
	
	If Modified Then
		
		Result = WriteAtServer(RetryRecordingIsRequired);
		
		If Result Then
			Notify("Write_GiftCertificateSale", New Structure, Undefined);
		EndIf;
		
		ProcessGiftCertificatesOnServer();
		
		Return Result;
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure RecalculateDocumentOnClient()
	
	Items.GoodsReturn.Enabled                    = AccessRights.GoodsReturn;
	
	Items.GiftCertificates.ChangeRowSet    = AccessRights.LineAdjustment;
	
	Items.GiftCertificatesContextMenuDelete.Enabled     = AccessRights.LineAdjustment;
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	UpdateDashboardData(True = ReadOnly);
	
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

&AtServer
Function PlaceTabularPartOfPaymentByPaymentCardsInVault()
	
	Return PutToTempStorage(Object.PaymentWithPaymentCards.Unload(), UUID);
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionParametersForGiftCertificate(Form)
	GiftCertificateSelectionParameters = New Array;
	FilterStructure1 = Form.ParametersForProcessingGiftCertificates.Filters;
	If FilterStructure1.Property("Status") Then
		GiftCertificateSelectionParameters.Add(New ChoiceParameter("Status", FilterStructure1.Status));
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
		RetailSalesClient.UnblockForm(ThisObject);
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
// Called from the MENUOPERATIONISKKM form
Procedure ChangeTheCashRegisterOfTheKKMCompletion(CashRegister, AdditionalParameters) Export
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	ChangeTheCashRegisterOfTheKKM(CashRegister);
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure ChangeTheCashRegisterOfTheKKM(CashRegister)
	
	Object.CashRegister = CashRegister;
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	If ValueIsFilled(CashRegisterParameters.Organization) And 
		CashRegisterParameters.Organization <> Object.Organization Then
		NewReceiptOnServer();
		ParametersForProcessingGiftCertificates.Filters.Insert("Organization", Object.Organization);
		UpdateOrganizationVATPayer();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateOrganizationVATPayer()
	
	GiftCertificateSaleLocalization.UpdateOrganizationVATPayer(CashRegisterParameters.Organization, VATPayerOrganization);
	
EndProcedure

&AtServer
Procedure ConfigureCWP()
	
	SetPrivilegedMode(True);
	
	GetHardwareLinks();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.AmountWithoutADiscount.Width = 22;
		Items.AmountToPay.Width   = 22;
	EndIf;
	
	Title_Text = Items.GiftCertificatesSum.Title;
	TextOfCurrency = "(" + Object.Currency + ")";
	If StrFind(Title_Text, TextOfCurrency) > 0 Then
		Title_Text = TrimAll(Left(Title_Text, StrFind(Title_Text, TextOfCurrency) - 1));
	EndIf;
	Items.GiftCertificatesSum.Title = Title_Text + " " + TextOfCurrency;
	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
	Query = New Query(
	"SELECT TOP 1
	|	ISNULL(CWPSettings.KeyboardShortcuts, UNDEFINED)               AS KeyboardShortcuts,
	|	ISNULL(CWPSettings.KeyboardShortcuts.FormCommands, UNDEFINED)  AS FormCommands,
	|	CWPSettings.UseAuthorization                              AS UseAuthorization
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
		
		KeyboardShortcuts                          = Undefined;
		ForcefullyAuthorize               = False;
		
	EndIf;
	
	ConfigureRightsForUser(Object.Cashier);
	
	AvailablePaymentMethods = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	Items.PayInCash.Visible = AvailablePaymentMethods.CashPayment;
	Items.PaymentByCard.Visible    = AvailablePaymentMethods.PaymentCards;
	Items.MixedPayment.Visible   = AvailablePaymentMethods.PaymentCards;

	Items.PayInCash.Enabled = True;
	Items.PaymentByCard.Enabled    = True;
	Items.MixedPayment.Enabled   = True;
	
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
	
	Title = NStr("vi = 'Bán hàng (Thu ngân: %Cashier%)';
				|ru = 'Продажа (Кассир: %Cashier%)';
				|en = 'Issue (Cashier: %Cashier%)'; fa = 'Issue (Cashier: %Cashier%)';
				|it = 'Vendita (Cassiere: %Cashier%)';
				|pl = 'Sprzedaż (Kasjer: %Cashier%)';
				|tr = 'Satış (Kasiyer: %Cashier%)'");
	Title = StrReplace(Title, "%Cashier%", Object.Cashier);
	
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

&AtClient
Procedure UpdateDashboardData(DisplayChange = False)
	
	PaymentInformation = PaymentInformation(ThisObject);
	
	InformationPanelAmountToBePaid   = PaymentInformation.AmountToPay;
	InfoBarAmountWithoutDiscount = PaymentInformation.DocumentAmount;
	
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
			StrTemplate(NStr("vi = 'Thay đổi: %1';
							|ru = 'Сдача: %1';
							|en = 'Change: %1'; fa = 'Change: %1';
							|it = 'Resto: %1';
							|pl = 'Reszta: %1';
							|tr = 'Para üstü: %1'"),
				Format(PaymentInformation.TotalPaid_ - PaymentInformation.AmountToPay, "NFD=2; NZ=0.00")));
		
		Data.Insert("DisplayChange", True);
		Data.Insert("TextDelivery",      TextDelivery);
		
	Else
		Data.Insert("DisplayChange", False);
	EndIf;

	RetailSalesClientServer.UpdateDashboardData(ThisObject, Data);
	
EndProcedure

&AtClient
Function PaymentInformation(Form)
	
	DocumentAmount = Object.GiftCertificates.Total("Sum");
	
	PaymentInformation = New Structure;
	PaymentInformation.Insert("Document",              Object.Ref);
	
	PaymentInformation.Insert("CashPayment",              Object.ReceivedInCash);
	PaymentInformation.Insert("PaymentCards",        RetailSalesClientServer.AmountOfPaymentByPaymentCards(Form.Object.PaymentWithPaymentCards));
	PaymentInformation.Insert("GiftCertificates", 0);
	PaymentInformation.Insert("BonusPoints",         0);
	
	PaymentInformation.Insert("DocumentAmount",        DocumentAmount);
	PaymentInformation.Insert("AmountToPay",          DocumentAmount);
	PaymentInformation.Insert("DiscountAmount",           0);
	PaymentInformation.Insert("TotalPaid_",         PaymentInformation.CashPayment + PaymentInformation.PaymentCards);
	
	PaymentInformation.Insert("AvailablePaymentMethods", RetailSalesClientServer.AvailablePaymentMethods(ThisObject));

	PaymentInformationLocalization(Form, PaymentInformation);
	
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
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
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
Procedure PayByCreditCardProcessingNotifications(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	PerformActionAfterRecording(
		New CallbackDescription("AddCardPayment", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
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
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.MixedPaymentForm",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject));
	
EndProcedure

#Region PaymentWithPaymentCards

// Called from the complex payment form
// 
//	Parameters:
//   ModifiedDataIsRecorded - Boolean
//   CompletionParameters - Structure
//
&AtClient
Procedure AddCardPayment(ModifiedDataIsRecorded, CompletionParameters) Export
	
	If Not ModifiedDataIsRecorded Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	If CompletionParameters <> Undefined Then
		Object.ReceivedInCash = CompletionParameters.ReceivedInCash;
	EndIf;
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	PaymentInformation = PaymentInformation(ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CallbackOnCompletion", New CallbackDescription("AddCardPaymentCompletion", ThisObject, CompletionParameters));
	
	AdditionalParameters.Insert("Form",                  ThisObject);
	AdditionalParameters.Insert("POSTerminals", POSTerminals);
	AdditionalParameters.Insert("CashRegisterParameters",      CashRegisterParameters);
	AdditionalParameters.Insert("AuthorizationForm_Amount",       PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_);
	AdditionalParameters.Insert("AuthorizationForm_AmountLimit", PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_ + PaymentInformation.CashPayment);
	AdditionalParameters.Insert("Currency",                       Object.Currency);
	AdditionalParameters.Insert("StructureAcquiringTerminal");
	AdditionalParameters.Insert("IDOfETDevice");
	
	PerformActionAfterRecording(
		New CallbackDescription("AddCardPayment", RetailSalesClient, AdditionalParameters),
		NStr("vi = 'Trước khi thanh toán bằng thẻ thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед оплатой платежной картой не удалось записать документ.';
			|en = 'Cannot save the document before paying by payment card.'; fa = 'Cannot save the document before paying by payment card.';
			|it = 'Prima del pagamento tramite carta non è stato possibile registrare il documento.';
			|pl = 'Przed płatnością kartą płatniczą nie udało się zapisać dokumentu.';
			|tr = 'Ödeme kartı ile ödeme yapmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure AddCardPaymentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		ProcessPaymentAddition(AdditionalParameters);
		Return;
	EndIf;
	
	// Save card payment data in the table
	CardPaymentLine = Object.PaymentWithPaymentCards.Add();
	
	CardPaymentLine.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
	CardPaymentLine.POSTerminal = Result.POSTerminal;
	CardPaymentLine.PaymentCardNumber   = Result.CardNumber; // It is possible to record an empty card number or a type number "****************"
	CardPaymentLine.Sum                 = Result.TransactionAmount;
	CardPaymentLine.ReferenceNumber        = Result.ReferenceNumber;
	CardPaymentLine.POSTerminalReceiptNumber           = Result.ReceiptNumber;
	CardPaymentLine.AuthorizationCode        = Result.AuthorizationCode;
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  Result.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", Result.ReferenceNumber);
	DataForEventLog.Insert("CardNumber",     Result.CardNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    Result.ReceiptNumber);
	DataForEventLog.Insert("AuthorizationCode", Result.AuthorizationCode);
	
	Modified = True;
	
	RecalculateDocumentOnClient();
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParametersCompletion = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersCompletion.CallbackDescription             = New CallbackDescription("AddCardPaymentEntryCompletion", ThisObject, AdditionalParameters);
		AdditionalParametersCompletion.MessageText                 = NStr("vi = 'Sau khi thanh toán bằng thẻ thanh toán, Chứng từ không thể được lưu.';
																			|ru = 'После проведения оплаты платежной картой не удалось сохранить документ.';
																			|en = 'Cannot save the document after payment by payment card.'; fa = 'Cannot save the document after payment by payment card.';
																			|it = 'Dopo l''esecuzione del pagamento tramite carta non è stato possibile salvare il documento.';
																			|pl = 'Po zaksięgowaniu płatności kartą płatniczą nie udało się zapisać dokumentu.';
																			|tr = 'Ödeme kartı ile ödeme yapıldıktan sonra belge kaydedilemedi.'");
		AdditionalParametersCompletion.ReturnFunctionResult     = False;
		AdditionalParametersCompletion.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True);
		AdditionalParametersCompletion.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False);
		AdditionalParametersCompletion.ProcedureName                   = "WriteAtServer";
		AdditionalParametersCompletion.OperationResult              = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersCompletion);
			Return;
		EndIf;
	
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersCompletion),
			AdditionalParametersCompletion.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		ProcessPaymentAddition(AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddCardPaymentEntryCompletion(Result, AdditionalParameters) Export
	
	ProcessPaymentAddition(AdditionalParameters);
	
	If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Data", Object.Ref);
		FormParameters.Insert("DataForEventLog", DataForEventLog);
		FormParameters.Insert("MessageText",
			NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
			|Đã thực hiện thanh toán, nhưng chưa được ghi nhận trong hệ thống.';
			|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
			|Оплата произведена, но не зафиксирована в системе.';
			|en = 'WARNING! An exception is thrown. 
			|The payment is made but it was not recorded in the application.'; fa = 'WARNING! An exception is thrown. 
			|The payment is made but it was not recorded in the application.';
			|it = 'ATTENZIONE! si è verificata una situazione eccezionale: 
			|il pagamento è stato effettuato, ma non è stato registrato nel sistema.';
			|pl = 'UWAGA! Wystąpiła sytuacja wyjątkowa:
			|Płatność wykonana, ale nie została zarejestrowana w systemie.';
			|tr = 'UYARI! İstisnai bir durum meydana geldi:
			| Ödeme yapıldı ancak sisteme kaydedilmedi.'"));
		
		OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region CancellationOfPaymentByPaymentCards

&AtClient
Procedure CancelPaymentsByPaymentCards(Result, AdditionalParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInStorage", PlaceTabularPartOfPaymentByPaymentCardsInVault());
	SelectionResult = Undefined;
	
	If AdditionalParameters.Property("ReceivedInCash") Then
		Object.ReceivedInCash = AdditionalParameters.ReceivedInCash;
	EndIf;

	AdditionalParameters.Insert("ShowCancelPaymentsButtonSequentially", False);
	AdditionalParameters.Insert("ShowOnlyPaymentsWithPaymentCards", True);
	AdditionalParameters.Insert("DocumentAmount", DocumentAmount);

	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.TabularFormPaymentWithPaymentCards",
		FormParameters,,,,,
		New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
//  Result - Structure -
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef.GiftCertificateSale
//
&AtClient
Procedure CancelPaymentsByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
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
		
	EndIf;
	
	If AdditionalParameters.Property("NotificationToPaymentForm") Then
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation(ThisObject));
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
Procedure CancelPaymentByPaymentCards(CallbackOnCompletion)
	
	PaymentLinesWithPaymentCards = New Array;
	For Each PaymentLine_ In Object.PaymentWithPaymentCards Do
		PaymentLinesWithPaymentCards.Add(PaymentLine_);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationOnCompletion",       CallbackOnCompletion);
	AdditionalParameters.Insert("PaymentLinesWithPaymentCards", PaymentLinesWithPaymentCards);
	
	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	
	RetailSalesClient.CancelPaymentByCreditCardsSequentially(
		Undefined,
		AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCardCompletion(Result, AdditionalParameters) Export
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  AdditionalParameters.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", AdditionalParameters.ReferenceNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    AdditionalParameters.ReceiptNumber);
	
	Object.PaymentWithPaymentCards.Delete(Object.PaymentWithPaymentCards.IndexOf(AdditionalParameters.PaymentLine_));
	Modified = True;
	
	RecalculateDocumentOnClient();
	
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
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded",
				True, True));
		
	EndIf;
	
EndProcedure

// Called from the complex payment form
// 
// Parameters:
//  Result - Structure -
// 	AdditionalParameters - Structure - 
//
&AtClient
Procedure PaymentCancel(Result, AdditionalParameters) Export
	
	Object.ReceivedInCash = 0;
	
	CancelPaymentByPaymentCards(
		New CallbackDescription("PaymentCancelCompletion", ThisObject, AdditionalParameters));
	
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
		
		Object.ReceivedInCash = PaymentResult.ReceivedInCash;
		Object.Partner           = PaymentResult.ElectronicReceiptData.Partner;
		
		FiscalOperationData.OptionOfSendingElectronicReceipt  = PaymentResult.ElectronicReceiptData.OptionOfSendingElectronicReceipt;
		FiscalOperationData.ContactDetailsOfElectronicReceipt = PaymentResult.ElectronicReceiptData.ContactDetailsOfElectronicReceipt;
		
	ElsIf PaymentResult = "Cancel" Then
		RetailSalesClient.UnblockForm(ThisObject);
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
	
	ShowForPaymentOnACustomerDisplay = False;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	PaymentInformation = PaymentInformation(ThisObject);
	
	// The card payment command was called from the RMK form
	If AdditionalParameters = Undefined Then
		
		If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
			
			ShowForPaymentOnACustomerDisplay = True;
			
			UpdateDashboardData(True);
			RetailSalesClient.UnblockForm(ThisObject);
			
		Else
			
			If PaymentInformation.TotalPaid_ >= PaymentInformation.AmountToPay
				And ValueIsFilled(FiscalOperationData.OptionOfSendingElectronicReceipt) Then
				
				ShowForPaymentOnACustomerDisplay = True;
				
				UpdateDashboardData(True);
				
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
					
			ElsIf PaymentInformation.SBPWaiting > 0 Then
				
				DeferOnClient(Undefined);
				ConfigureCWP();
				
			Else
				
				RetailSalesClient.UnblockForm(ThisObject);
				
			EndIf;
			
		EndIf;
		
	Else
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadNewReceipt(Ref = Undefined)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	If Object.Status <> PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Ref", Ref);
		
		Cancel = False;
		BeforeClosingReceipt(
			Cancel,
			New CallbackDescription("UploadNewReceiptCompletion", ThisObject, AdditionalParameters));
		If Cancel Then
			Return;
		EndIf;
		
	Else
		
		NewReceiptOnServer();
		UploadNewReceiptFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadNewReceiptFragment()
	
	RecalculateDocumentOnClient();
	
EndProcedure

// Parameters:
//  Result - Boolean, Undefined -
// 	AdditionalParameters - Structure:
// 		* Ref - DocumentRef
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
	
	If SBPAmountHasBeenCompleted > 0 Or SBPAmountPending > 0 Then
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Undefined);
		EndIf;
		
		Return;
	EndIf;
	
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
	
	Notify("Write_GiftCertificateSale", New Structure, Object.Ref);
	
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
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	If QuestionResult = 1 Then
		
		// Postpone the receipt
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
			
			Notify("Write_GiftCertificateSale", New Structure, Undefined);
			
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
Procedure NewReceiptOnServer(Ref = Undefined)
	
	If Ref = Undefined Or Ref.Date = Date(1, 1, 1) Then
		NewReceipt = Documents.GiftCertificateSale.CreateDocument();
		NewReceipt.Filling(New Structure("CashRegister", Object.CashRegister), True);
		NewReceipt.Date = BegOfDay(CurrentSessionDate());
	Else
		NewReceipt = Ref.GetObject();
	EndIf;
	
	NewReceipt.Date = CurrentSessionDate();
	UnlockFormDataForEdit();
	ValueToFormData(NewReceipt, Object);
	
	ProcessGiftCertificatesOnServer();
	
	ReadOnly = False;
	Modified = False;
	ShowForPaymentOnACustomerDisplay = False;
	
	WhenCreatingReceipt();
	
EndProcedure

&AtServer
Procedure WhenCreatingReceipt()
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
	FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	ConfigureCWP();
	
	RefreshFormTitle();
	
EndProcedure

&AtClient
Procedure ReturnOfGoodsProcessingOfNotification(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister", Object.CashRegister);
	FormOpenParameters.Insert("Organization", Object.Organization);
	
	OpenForm("Document.CashRegisterReceipt.Form.RegisterGiftCardReturn", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ProcessPrintCommand(CommandName, AdditionalParameters) Export

	AttachableCommandsClient.ExecuteCommand(ThisObject, Commands[CommandName], Object);

EndProcedure

#EndRegion

#EndRegion

#Region Localization

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


&AtServer
Procedure ToEstablishPossibilityOfUsingSBPPaymentOnCWPLocalizationForms()
	
	
EndProcedure

#EndRegion