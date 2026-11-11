
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CashRegister       = Parameters.CashRegister;
	Cashier         = Parameters.Cashier;
	ReadOnly = Parameters.ReadOnly;
	Document       = Parameters.Document;
	Organization    = Parameters.Organization;
	
	// Managing the visibility of the upload command from the TSD.
	TypesOfConnectedEquipment = PeripheralsTMCached.TypesOfConnectedEquipment();
	
	ThereIsTSD =
		Not Parameters.DoNotOutputTheDownloadFromTheTSD
		And TypesOfConnectedEquipment <> Undefined
		And TypesOfConnectedEquipment.Find(Enums.PeripheralTypes.PortableDataCollectionTerminal) <> Undefined;
	
	Items.ImportDataFromPDT.Visible = TMCommonUse.UsePeripherals(TypesOfConnectedEquipment) And ThereIsTSD;
	Items.SellingAGiftCertificate.Visible = Parameters.SellingAGiftCertificate;
	Items.CheckQuantityInTheDocument.Visible = Parameters.CheckQuantityInTheDocument;
	Items.GiftCertificateRefund.Visible = Parameters.GiftCertificateRefund;
	Items.Lock.Visible                 = Parameters.Lock;
	
	PrintCommandAddressInTheTemporaryStorage = Parameters.PrintCommandAddressInTheTemporaryStorage;
	PrintCommands = GetFromTempStorage(PrintCommandAddressInTheTemporaryStorage);
	
	If ValueIsFilled(Document)
		Or SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser()).Snooze Then
			
		For Each PrintCommand In PrintCommands Do
			
			ButtonName = PrintCommand.CommandName;
			
			If StrFind(ButtonName, "OutputToEmptySubmenuCommand") > 0 Then
				Break;
			EndIf;
			
			NewCommand = ThisForm.Commands.Add(ButtonName);
			NewCommand.Action = "Attachable_ProcessPrintCommand";
			NewCommand.Title = PrintCommand.Title;
			NewCommand.Representation = ButtonRepresentation.Text;
			
			NewButton = Items.Add(ButtonName, Type("FormButton"), Items.PrintGroup);
			NewButton.CommandName = NewCommand.Name;
			NewButton.Height = 3;
			NewButton.Width = 12;
			If CommonClientServer.HasAttributeOrObjectProperty(NewButton, "HorizontalStretch") Then
				NewButton.HorizontalStretch = True;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	FillInAvailableCashRegisterSalesRegisters();
	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
	SettingUpVisibilityOfLocalizationCommands();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure Attachable_ProcessPrintCommand(Command)
	
	Close();
	
	RunCallback(
		New CallbackDescription("ProcessPrintCommand", FormOwner),
		Command.Name);
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	Close();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", FormOwner),
		UUID);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocument(Command)
	
	Close();
	
	CallbackDescription = New CallbackDescription("CheckQuantityInTheDocument", FormOwner);
	RunCallback(CallbackDescription);
	
EndProcedure

&AtClient
Procedure SellingAGiftCertificate(Command)
	
	Close();
	
	NotificationProcessing = New CallbackDescription("GiftCertificateSaleNotificationProcessing", ThisObject);
	
	RetailSalesClient.ProcessShiftState(FormOwner, NotificationProcessing);
	
EndProcedure

&AtClient
Procedure GiftCertificateRefund(Command)
	
	Close();
	
	NotificationProcessing = New CallbackDescription("GiftCertificateRefundNotificationProcessing", ThisObject);
	
	RetailSalesClient.ProcessShiftState(FormOwner, NotificationProcessing);
	
EndProcedure

&AtClient
Procedure Lock(Command)
	
	Close();
	
	OpenForm("Document.CashRegisterReceipt.Form.Authorization", New Structure("Mode", "ChangeRights"), FormOwner);
	
EndProcedure

&AtClient
Procedure DeferredReceipt(Command)
	
	Close();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CashRegister",        CashRegister);
	OpeningParameters.Insert("LoyaltyCard", PredefinedValue("Catalog.LoyaltyCards.EmptyRef"));
	
	If TypeOf(Document) = Type("DocumentRef.CashRegisterReceipt") Then
		OpenForm("Document.CashRegisterReceipt.Form.SelectDeferredReceipt", OpeningParameters, FormOwner);
	ElsIf TypeOf(Document) = Type("DocumentRef.CashRegisterReceiptReturn") Then
		OpenForm("Document.CashRegisterReceiptReturn.Form.SelectDeferredReceipt", OpeningParameters, FormOwner);
	ElsIf TypeOf(Document) = Type("DocumentRef.GiftCertificateSale") Then
		OpenForm("Document.GiftCertificateSale.Form.SelectDeferredReceipt", OpeningParameters, FormOwner);
	ElsIf TypeOf(Document) = Type("DocumentRef.ReturnOfGiftCards") Then
		OpenForm("Document.ReturnOfGiftCards.Form.SelectDeferredReceipt", OpeningParameters, FormOwner);
	EndIf;
	
EndProcedure

&AtClient
Procedure BalanceOfOpenedConsumerPackagingUnits(Command)
	
	BalanceOfOpenedConsumerPackagingUnitsLocalization();
	
EndProcedure

&AtClient
Procedure BalanceOfOpenedBottlesOfUSAIS(Command)
	
	BalanceOfOpenedBottlesOfUSAISLocalization();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GiftCertificateSaleNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	FillParameters = New Structure;
	FillParameters.Insert("CashRegister", CashRegister);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Basis", FillParameters);
	OpenForm(
		"Document.GiftCertificateSale.Form.CWPDocumentForm",
		FormOpenParameters,
		FormOwner);
	
EndProcedure

&AtClient
Procedure GiftCertificateRefundNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister", CashRegister);
	FormOpenParameters.Insert("Organization", Organization);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.RegisterGiftCardReturn",
		FormOpenParameters,
		FormOwner);
	
EndProcedure

&AtServer
Procedure FillInAvailableCashRegisterSalesRegisters()
	
	GeneratingFiscalChecksServer.FillInAvailableCashRegisterSalesRegisters(AvailableCashRegisters, CashRegister);
	
EndProcedure

&AtClient
Procedure BalanceOfOpenedConsumerPackagingUnitsLocalization()
	
	
EndProcedure

&AtClient
Procedure BalanceOfOpenedBottlesOfUSAISLocalization()
	
	
EndProcedure

&AtServer
Procedure SettingUpVisibilityOfLocalizationCommands()
	
	Items.BalanceOfOpenedConsumerPackagingUnits.Visible = False;
	Items.BalanceOfOpenedBottlesOfUSAIS.Visible = False;
	
	
EndProcedure

#EndRegion
