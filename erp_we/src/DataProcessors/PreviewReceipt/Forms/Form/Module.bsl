#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// refund upon receipt of the form for analysis
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	DocumentRef         = Parameters.OperationParametersList.DocumentRef;
	Organization            = Parameters.OperationParametersList.Organization;
	Counterparty             = Parameters.OperationParametersList.Counterparty;
	Partner                = Parameters.OperationParametersList.Partner;
	DocumentCurrency        = Parameters.OperationParametersList.Currency;
	DocumentAmount         = Parameters.OperationParametersList.DocumentAmount;
	ReceiptPrintingCommandName = Parameters.OperationParametersList.ReceiptPrintingCommandName;
	AcquiringTransactionParameters = Parameters.OperationParametersList.AcquiringTransactionParameters;
	
	If TypeOf(AcquiringTransactionParameters) = Type("Structure")
		And AcquiringTransactionParameters.Property("POSTerminal") Then
		
		Terminal = AcquiringTransactionParameters.POSTerminal;
	EndIf;
	
	EquipmentTable.Load(TMCommonUse.ArrayToValueTable(Parameters.ConnectedReceiptPrintingEquipment));
	Items.ChangeCRE.Visible = (EquipmentTable.Count()>1);

	ReceiptPreviewParameters = GeneratingFiscalChecksServer.ReceiptPreviewParameters(Parameters.OperationParametersList);
	
	ParametersOfReceiptFiscalizationOperation = ReceiptPreviewParameters.ParametersOfReceiptFiscalizationOperation;	
	
	RetailFacility = Undefined;
	If Not ValueIsFilled(ParametersOfReceiptFiscalizationOperation.RetailFacility)
			And Parameters.OperationParametersList.Property("RetailFacility", RetailFacility) 
			And ValueIsFilled(RetailFacility) Then
		ParametersOfReceiptFiscalizationOperation.RetailFacility = RetailFacility;
	EndIf;
	
	AutomaticallyUpdatePartnerContacts = Constants.UpdatePartnersContactDetailsWhenSendingElectronicReceipts.Get();
	
	CustomerPersonalDataType = "TIN";
	TextConsentToTheProcessingOfPersonalDataReceived = TextOnObtainingConsentToProcessingOfPersonalData();
	
	ARAPObjects.Load(ReceiptPreviewParameters.ObjectsOfCalculationsForDocument);
	
	SingleReceiptDocuments.Load(ReceiptPreviewParameters.SingleReceiptDocuments);
	SingleReceipt = SingleReceiptDocuments.Count() > 0;
	
	If SingleReceipt And GeneratingFiscalChecksServer.DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Then
		
		If AccordingToDeliveryDocumentThereIsOnlyOnePaymentByCreditCard() Then
			AccordingToDeliveryDocumentFillInPaymentDetailsWithPaymentCard();
		Else
			SingleReceipt = False;
			Items.TheGroupIsOneCheck.Enabled = False;
			
			MessageText = NStr("vi = 'Chỉ có thể gắn phiếu duy nhất với một chứng từ thanh toán bằng thẻ.';
								|ru = 'Единый чек может быть только с одним документом оплаты платежной картой.';
								|en = 'A single receipt can only contain one card payment document.'; fa = 'A single receipt can only contain one card payment document.';
								|it = 'Единый чек может быть только с одним документом оплаты платежной картой.';
								|pl = 'A single receipt can only contain one card payment document.';
								|tr = 'Tek bir fiş sadece bir ödeme kartlı ödeme belgesi ile birlikte olabilir.'");
			Common.MessageToUser(MessageText);
		EndIf;
		
	ElsIf SingleReceipt Then
		
		CheckCorrectnessOfRetailPriceOfTobaccoProducts();
		
	ElsIf TypeOf(DocumentRef) = Type("DocumentRef.SaleAdjustment") Then
		
		If Not CheckCorrectnessOfRetailPriceOfTobaccoProductsInAdjustmentOfSales() Then
			Cancel = True;
			Return;
		EndIf;
		
	EndIf;
	
	AmountOfPrepaymentWithinOneDay = ReceiptPreviewParameters.AmountOfPrepaymentWithinOneDay;
	PrepaymentAmountOutsideOfOneDay = ReceiptPreviewParameters.PrepaymentAmountOutsideOfOneDay;
	
	FiscalOperationData = ReceiptPreviewParameters.FiscalOperationData;
	
	AutoCalculationMethodFlags.Load(
		ArrayToValueTable(ReceiptPreviewParameters.AutoCalculationMethodFlags)
	);
	
	PersonalDataInputIsAllowed = ReceiptPreviewParameters.PersonalDataInputIsAllowed;
	
	AccessRights = ReceiptPreviewParameters.AccessRights;
	
	RetailSales.FillInParametersForSendingElectronicReceiptToPartner(ThisObject);
	Phone = RetailSalesClientServer.FormatPhoneNumber(PhoneNumber10Characters);
	
	GetProcessPaymentDataInOnlineStoreFromDocument();
	
	ConfigureListOfValuesForSelectingTypeOfFiscalDocument();
	SetUpListOfValuesForSelectingTimeAreaOfTransferOfGoods();
	
	DateOfAdjustedCalculation = GeneratingFiscalChecksServer
		.DateOfAdjustedCalculation(DocumentRef);
	DateOfCorrectedCalculationOnServer();
	
	AdjustmentReceiptType = Enums.TypesOfAdjustmentReceipts.Independently_;
	TypeOfCorrectionReceiptForChangesOnServer_();
	
	
	
	ConfigureAvailabilityOfCashRegisterReceiptPenetration();
	AdjustVisibilityOfTerminalPresentation();
	
	EstablishVisibilityOfBuyerSPersonalDataEntryDetails();
	SetVisibilityAvailabilityOfPaymentDetailsPaymentMethodAttribute();
	SetVisibilityOfAmountCorrectionOfPaymentTypes();
	SetVisibilityOfPaymentAttributesInOnlineStore(ThisObject);
	SetAvailabilityOfPaymentAttributesInOnlineStore(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ClearMessages();
	
	If Not ValueIsFilled(DocumentRef) Then
		Return;
	EndIf;
	
	TMPeripheralsClient.SetHardwareConnectionStatus(
		True,
		ThisObject,
		ConnectEquipmentUsed(),
		EquipmentTable,
		New CallbackDescription("UpdateHardwareConnectionStatus", ThisObject)
	);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	CloseKmVerificationSessionOnCCT(Cancel);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	DoNotTurnOffCCT = TMPeripheralsClient.CashRegisterEquipmentIsConnectedToDocument(DocumentRef);
	
	TMPeripheralsClient.SetHardwareConnectionStatus(
		False,
		ThisObject,
		DisableEquipmentUsed(DoNotTurnOffCCT),
		EquipmentTable);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextConsentToTheProcessingOfPersonalDataReceivedURLProcessing(
	Item,
	Var_URL,
	StandardProcessing)
	
	If "OpenPrintedFormForObtainingConsentToProcessingOfPersonalData" = Var_URL Then
		
		StandardProcessing = False;
		
		PrintManager = "DataProcessor.PreviewReceipt";
		Id = "PersonalDataProcessingConsent";
		
		PrintObjects = New Array();
		PrintObjects.Add(DocumentRef);
		
		PrintParameters = New Structure();
		PrintParameters.Insert("PersonalDataType", CustomerPersonalDataType);
		
		PrintManagementClient.ExecutePrintCommand(
			PrintManager,
			Id,
			PrintObjects,
			ThisObject,
			PrintParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FiscalDocumentTypeOnChange(Item)
	
	ClearMessages();
	
	If TypeOf(DocumentRef) = Type("DocumentRef.PaymentCardTransaction") Then
		MessageText = NStr("vi = 'Trước khi đánh phiếu điều chỉnh ""Không sử dụng MST"", hãy chắc chắn rằng việc thanh toán bằng thẻ ngân hàng đã được thực hiện thành công trước đó.';
							|ru = 'Перед пробитием чека коррекции ""Неприменение ККТ"" убедитесь, что оплата банковской картой была ранее проведена успешно.';
							|en = 'Before issuing the ""Cash register non-application"" adjustment voucher, make sure that the bank card payment was previously made successfully.'; fa = 'Before issuing the ""Cash register non-application"" adjustment voucher, make sure that the bank card payment was previously made successfully.';
							|it = 'Before issuing the ""Cash register non-application"" adjustment voucher, make sure that the bank card payment was previously made successfully.';
							|pl = 'Before issuing the ""Cash register non-application"" adjustment voucher, make sure that the bank card payment was previously made successfully.';
							|tr = '""Yazar kasanın kullanılmaması"" düzeltme fişini kesmeden önce, daha önce banka kartıyla ödemenin başarıyla yapıldığından emin olun.'");
		CommonClient.MessageToUser(MessageText);
	EndIf;
	
	TypeOfFiscalDocumentWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure FiscalDocumentTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FlagSingleReceiptOnChange(Item)
	
	ClearMessages();
	
	SingleCheckForChangesOnServer();
	
EndProcedure

&AtClient
Procedure CashSettlementTypeOnChange(Item)
	
	ClearMessages();
	
	TypeOfCashSettlementWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CashSettlementTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure ShowsCalculationMethodOnChange(Item)
	
	ClearMessages();
	
	FlagForCalculationMethodWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure ShowsCalculationMethodClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PrepaymentAmountManOnChange(Item)
	
	ClearMessages();
	
	RecalculatePaymentTypesByAmount(Item);
	
EndProcedure

&AtClient
Procedure PaymentAmountInCashOnChange(Item)
	
	ClearMessages();
	
	RecalculatePaymentTypesByAmount(Item);
	
EndProcedure

&AtClient
Procedure PaymentAmountElectronicallyOnChange(Item)
	
	ClearMessages();
	
	RecalculatePaymentTypesByAmount(Item)
	
EndProcedure

&AtClient
Procedure CreditAmountOnChange(Item)
	
	ClearMessages();
	
	RecalculatePaymentTypesByAmount(Item);
	
EndProcedure

&AtClient
Procedure TypeOfAdjustmentReceiptOnChange(Item)
	
	ClearMessages();
	
	TypeOfCorrectionReceiptForChangesOnServer();
	
EndProcedure

&AtClient
Procedure TypeOfAdjustmentReceiptClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure AdjustmentReceiptTypeOnChange(Item)
	
	ClearMessages();
	
	TypeOfCorrectionReceiptForChangesOnServer_();
	
EndProcedure

&AtClient
Procedure AdjustmentReceiptTypeClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure PrescriptionNumberOfTaxAuthorityOnChange(Item)
	
	ClearMessages();
	
	NumberOfTaxAuthoritySOrderWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure AdjustmentDescriptionOnChange(Item)
	
	ClearMessages();
	
	DescriptionOfCorrectionForChangesOnServer();
	
EndProcedure

&AtClient
Procedure PaymentInOnlineStoreOnChange(Item)
	
	If PaymentInOnlineStore
		And OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend") Then
		OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS");
		OptionToSendElectronicCheckWhenChangingOnServer();
	EndIf;
	
	If PaymentInOnlineStore Then
		OnlineStoreAddress = AddressOfOnlineStoreInActivationContract;
	Else
		OnlineStoreAddress = "";
	EndIf;
	
	UpdateFiscalReceiptParameters();
	
	SetAvailabilityOfPaymentAttributesInOnlineStore(ThisObject);
	
EndProcedure

&AtClient
Procedure OnlineStoreAddressOnChange(Item)
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtClient
Procedure OptionToSendAnElectronicReceiptDoNotSendOnChange(Item)
	
	ClearMessages();
	
	OptionToSendElectronicCheckWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure OptionToSendElectronicSMSReceiptOnChange(Item)
	
	ClearMessages();
	
	OptionToSendElectronicCheckWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure OptionToSendElectronicCheckEmailOnChange(Item)
	
	ClearMessages();
	
	OptionToSendElectronicCheckWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure PhoneOnChange(Item)
	
	ClearMessages();
	
	PhoneNumberWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure EmailOnChange(Item)
	
	ClearMessages();
	
	EmailWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure TheOperationInvolvesEnteringTheBuyerSPersonalDataOnChange(Item)
	
	ClearMessages();
	
	OperationProvidesForEntryOfPersonalDataOfBuyerWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	ClearMessages();
	
	BuyerNameWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure BuyerCitizenshipOnChange(Item)
	
	ClearMessages();
	
	BuyerChangesWhenChangingOnServer();
	
EndProcedure

&AtClient
Procedure BuyerDateOfBirthOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ClearMessages();
	
	BuyerDateOfBirthWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure CustomerPersonalDataTypeOnChange(Item)
	
	ClearMessages();
	
	BuyerTypeOfPersonalDataWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure BuyerPersonalDataWhenChanging(Item)
	
	ClearMessages();
	
	BuyerPersonalDataWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DecorationDocumentsOfASingleReceiptClick(Item)
	
	ArrayOfDocumentsForSingleReceipt = New Array;
	
	For Each DocumentData In SingleReceiptDocuments Do
		ArrayOfDocumentsForSingleReceipt.Add(
			New Structure("Document, Sum", DocumentData.Document, DocumentData.Sum));
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("SingleReceiptDocuments", ArrayOfDocumentsForSingleReceipt);
	
	OpenForm(
		"DataProcessor.PreviewReceipt.Form.SingleReceiptDocuments",
		FormParameters, ThisObject,,,,, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure TimeAreaOfTransferOfGoodsOnChange(Item)
	
	ClearMessages();
	
	TimeAreaOfTransferOfGoodsOnChangeAtServer();
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueCashReceipt(Command)
	
	ClearMessages();
	
	LockForm(ThisObject);
	
	If Not PaymentsInOnlineStoreAreFilledInCorrectly() Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
	
	If Not ReceiptWasFilledInCorrectly() Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
		
	If ThisIsReturnViaSBP(ThisObject) Then
		
		ReturnViaSBPLocalization();
		
	ElsIf ValueIsFilled(EquipmentTerminal)
		And FiscalDocumentType = PredefinedValue("Enum.TypesOfCREFiscalDocuments.SALESSLIP") Then
		
		If AcquiringTransactionParameters = Undefined Then
			
			RetailSalesClient.ProcessShiftState(
				ThisObject,
				New CallbackDescription("AfterProcessingShiftState", ThisObject));
			
		Else
			
			FormOpenParameters = New Structure;
			FormOpenParameters.Insert("TransactionType",               AcquiringTransactionParameters.TransactionType);
			FormOpenParameters.Insert("Sum",                       AcquiringTransactionParameters.Sum);
			FormOpenParameters.Insert("AmountLimit",                 AcquiringTransactionParameters.Sum);
			FormOpenParameters.Insert("SpecifyAdditionalData", AcquiringTransactionParameters.TransactionType = "AuthorizeRefund");
			
			If TypeOf(DocumentRef) = Type("DocumentRef.PaymentCardTransaction") Then
				FormOpenParameters.Insert("NoAmountEditingAllowed", True);
				FormOpenParameters.Insert("DocumentBasis", DocumentRef);
			EndIf;
			
			OpenForm(
				"Catalog.Peripherals.Form.POSTerminalAuthorizationForm",
				FormOpenParameters,,,,,
				New CallbackDescription(
					"PaymentByCardCompletion",
					ThisObject,
					FormOpenParameters),
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	Else
		RetailSalesClient.ProcessShiftState(
			ThisObject,
			New CallbackDescription("AfterProcessingShiftState", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeCRE(Command)
	
	ArrayOfKKTEquipment = New Array();
	For Each HardwareTableRow In EquipmentTable Do
		EquipmentParameters = New Structure("Equipment, FDFVersion, Attached");
		FillPropertyValues(EquipmentParameters, HardwareTableRow);
		
		ArrayOfKKTEquipment.Add(EquipmentParameters);
	EndDo;
	
	FormParameters = New Structure("EquipmentTable", ArrayOfKKTEquipment);
	CallbackDescription = New CallbackDescription("FormSelectionOfConnectedCCTCompletion", ThisObject);
	
	OpenForm(
		"DataProcessor.PreviewReceipt.Form.SelectConnectedCRE",
		FormParameters, ThisObject,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure DisplayPaymentAttributesInOnlineStore(Command)
	
	PaymentAttributesInOnlineStoreAreAvailable = Not PaymentAttributesInOnlineStoreAreAvailable;
	Items.DisplayPaymentAttributesInOnlineStore.Check = PaymentAttributesInOnlineStoreAreAvailable;
	
	If Not PaymentAttributesInOnlineStoreAreAvailable Then
		PaymentInOnlineStore = False;
		OnlineStoreAddress   = "";
	EndIf;
	
	SetVisibilityOfPaymentAttributesInOnlineStore(ThisObject);
	
EndProcedure


#EndRegion

#Region Private

#Region NotifiesDescriptions

&AtClient
Procedure CloseReceiptPenetrationForm(Result) Export
	
	Close();
	
EndProcedure

&AtClient
Procedure FormSelectionOfConnectedCCTCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Structure")
		And Result.Property("Equipment")
		And Result.Property("FDFVersion") Then
		
		CREEquipment = Result.Equipment;
		FDFVersion = Result.FDFVersion;
		
		KktEquipmentWhenChangedOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormHeaderAttributesAtServer

&AtServer
Procedure TypeOfFiscalDocumentWhenChangedOnServer()
	
	ConfigureListOfValuesForSelectingTypeOfPaymentInCash();
	SetVisibilityAvailabilityOfPropsTypeOfPaymentInCash();
	
	ConfigureListOfValuesForSelectingDefaultCorrectionType();
	SetVisibilityAndAvailabilityOfPaymentDetails();
	
	AdjustVisibilityOfTerminalPresentation();
	SetVisibilityAvailabilityOfTimeAreaOfTransferOfGoods();
	
EndProcedure

&AtServer
Procedure SingleCheckForChangesOnServer()
	
	ParametersForCheckingPermissionToEnterPersonalData = New Structure;
	ParametersForCheckingPermissionToEnterPersonalData.Insert("SingleReceipt", SingleReceipt);
	ParametersForCheckingPermissionToEnterPersonalData.Insert("DocumentRef", DocumentRef);
	ParametersForCheckingPermissionToEnterPersonalData.Insert("Counterparty", Counterparty);
	PersonalDataInputIsAllowed = GeneratingFiscalChecksServerOverridable.PersonalDataInputIsAllowed(ParametersForCheckingPermissionToEnterPersonalData);
	If Not PersonalDataInputIsAllowed Then
		TheOperationInvolvesEnteringTheBuyerSPersonalData = False;
		ClearPersonalData();
	EndIf;
	
	UpdateFiscalReceiptParameters();
	
	If SingleReceipt And GeneratingFiscalChecksServer.DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Then
		AccordingToDeliveryDocumentFillInPaymentDetailsWithPaymentCard();
	ElsIf Not SingleReceipt And GeneratingFiscalChecksServer.DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Then
		ClearPaymentCardDetailsAccordingToDeliveryDocument();
	EndIf;
		
	EstablishVisibilityOfBuyerSPersonalDataEntryDetails();
	SetVisibilityAvailabilityOfPaymentDetailsPaymentMethodAttribute();
	SetVisibilityAvailabilityOfTimeAreaOfTransferOfGoods();
	
EndProcedure

&AtServer
Procedure TypeOfCashSettlementWhenChangedOnServer()
	
	ConfigureListOfValuesForSelectingCalculationMethodAttribute();
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure FlagForCalculationMethodWhenChangingOnServer()
	
	SpecifyPaymentTypeByAmount();
	
	UpdateFiscalReceiptParameters();
	
	ConfigureSingleReceiptGroupVisibility();
	ConfigureVisibilityOfRefinePaymentTypeByAmountGroup();
	
EndProcedure

&AtClient
Procedure RecalculatePaymentTypesByAmount(Item)
	
	If ShowsCalculationMethod = PredefinedValue("Enum.CalculationMethodFlags.TransferWithFullPayment")
		Or ShowsCalculationMethod = PredefinedValue("Enum.CalculationMethodFlags.TransferWithPartialPayment") Then
		
		ThisIsTransferWithPartialPayment = (ShowsCalculationMethod = PredefinedValue("Enum.CalculationMethodFlags.TransferWithPartialPayment"));
		
		If Item.Name = "PrepaymentAmountMan" Then
			PaymentAmountInCash   = DocumentAmount - PrepaymentAmountMan;
			PaymentAmountElectronically = 0;
			CreditAmount          = 0;
		ElsIf Item.Name = "PaymentAmountInCash" Then
			PaymentAmountElectronically = DocumentAmount - PrepaymentAmountMan - PaymentAmountInCash - CreditAmount;
		ElsIf Item.Name = "PaymentAmountElectronically"
			And Not ThisIsTransferWithPartialPayment Then
			PaymentAmountInCash   = DocumentAmount - PrepaymentAmountMan - PaymentAmountElectronically - CreditAmount;
		ElsIf Item.Name = "PaymentAmountElectronically"
			And ThisIsTransferWithPartialPayment Then
			CreditAmount      = DocumentAmount - PrepaymentAmountMan - PaymentAmountElectronically - PaymentAmountInCash;
		ElsIf Item.Name = "CreditAmount" Then
			PaymentAmountElectronically = DocumentAmount - PrepaymentAmountMan - PaymentAmountInCash - CreditAmount;
		EndIf;
		
		PrepaymentAmountMan = DocumentAmount - PaymentAmountInCash - PaymentAmountElectronically - CreditAmount;
		
		If PrepaymentAmountMan + PaymentAmountInCash + PaymentAmountElectronically + CreditAmount > DocumentAmount Then
			If Item.Name = "PrepaymentAmountMan" Then
				PrepaymentAmountMan       = DocumentAmount;
			ElsIf Item.Name = "PaymentAmountInCash" Then
				PaymentAmountInCash   = DocumentAmount;
			ElsIf Item.Name = "PaymentAmountElectronically" Then
				PaymentAmountElectronically = DocumentAmount;
			ElsIf Item.Name = "CreditAmount" Then
				CreditAmount = DocumentAmount;
			EndIf;
		EndIf;
		
	EndIf;
	
	RecalculatePaymentTypesByAmountsOnServer();
	
EndProcedure

&AtServer
Procedure RecalculatePaymentTypesByAmountsOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure DateOfCorrectedCalculationOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure TypeOfCorrectionReceiptForChangesOnServer()
	
	SetDefaultCorrectionDescription();
	SetAvailabilityOfCorrectionDescription();
	
EndProcedure

&AtServer
Procedure TypeOfCorrectionReceiptForChangesOnServer_()
	
	PrescriptionNumberOfTaxAuthority = 0;
	EstablishVisibilityOfTaxAuthorityPrescriptionNumber();
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure NumberOfTaxAuthoritySOrderWhenChangedOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure SetDefaultCorrectionDescription()
	
	If TypeOfAdjustmentReceipt = Enums.KindsOfAdjustmentReceipts.CRENonApplication Then
		AdjustmentDescription = NStr("vi = 'Không sử dụng MTT';
									|ru = 'Неприменение ККТ';
									|en = 'Cash register non-application'; fa = 'عدم استفاده از صندوق فروش';
									|it = 'Mancata applicazione del turno registratore di cassa';
									|pl = 'Niestosowanie kasy';
									|tr = 'Yazar kasa kullanılmaması'");
	Else
		AdjustmentDescription = "";
	EndIf;
	
	DescriptionOfCorrectionForChangesOnServer();
	
EndProcedure

&AtServer
Procedure DescriptionOfCorrectionForChangesOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure OptionToSendElectronicCheckWhenChangingOnServer()
	
	NeedForDataProcessing = RetailSalesClientServer.CheckWhetherElectronicReceiptDataNeedsToBeProcessed(ThisObject);
	If NeedForDataProcessing.NeedToUpdateContactInformation
		Or NeedForDataProcessing.YouNeedToCreatePartner
		Or NeedForDataProcessing.YouNeedToUpdateOptionForSendingPartnerSElectronicReceipt Then
			
		ProcessElectronicReceiptData();
	EndIf;
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure PhoneNumberWhenChangingOnServer()
	
	If Items.OptionToSendAnElectronicReceiptDoNotSend.Enabled Then
		OptionOfSendingElectronicReceipt = ?(ValueIsFilled(Phone),
			PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS"),
			PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend"));
	EndIf;
		
	OptionToSendElectronicCheckWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure EmailWhenChangingOnServer()
	
	If Items.OptionToSendAnElectronicReceiptDoNotSend.Enabled Then
		OptionOfSendingElectronicReceipt = ?(ValueIsFilled(Email),
			PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail"),
			PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend"));
	EndIf;
		
	OptionToSendElectronicCheckWhenChangingOnServer();
	
EndProcedure

&AtServer
Procedure OperationProvidesForEntryOfPersonalDataOfBuyerWhenChangingOnServer()
	
	If Not TheOperationInvolvesEnteringTheBuyerSPersonalData Then
		ClearPersonalData();		
	EndIf;
	
	UpdateFiscalReceiptParameters();
	
	EstablishVisibilityOfBuyerSPersonalDataEntryDetails();
	
EndProcedure

&AtServer
Procedure BuyerNameWhenChangedOnServer()
	
	BuyerCitizenship();
	BuyerDateOfBirth();
	CustomerPersonalData();
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure BuyerChangesWhenChangingOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure BuyerDateOfBirthWhenChangedOnServer()
	
	UpdateFiscalReceiptParameters();
	
EndProcedure

&AtServer
Procedure BuyerTypeOfPersonalDataWhenChangedOnServer()
	
	BuyerDateOfBirth();
	CustomerPersonalData();
	
	UpdateFiscalReceiptParameters();
	
	EstablishVisibilityOfBuyerSPersonalDataEntryDetails();
	
EndProcedure

&AtServer
Procedure BuyerPersonalDataWhenChangedOnServer()
	
	UpdateFiscalReceiptParameters();
	
	If CustomerPersonalDataType = "TIN" Then
		
		MessageText = "";
		If Not GeneratingFiscalChecksServer.TinMeetsRequirementsOnServer(DocumentRef, CustomerPersonalData, MessageText) Then
			Common.MessageToUser(
				MessageText,
				,"Item.CustomerPersonalData",,);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure KktEquipmentWhenChangedOnServer()
	
	SetKKTParameters();
	SetStructureOfCashShiftState();
	
	UpdateCCTPresentation();
	//Update the representation of the caseload();

	InstallHardwareTerminal();
	UpdateTerminalPresentation();
	
	ConfigureDisplayOfCCTPresentationHint();
	ConfigureAvailabilityOfCashRegisterReceiptPenetration();
	
	UpdateFiscalReceiptParameters();
	
	SetVisibilityAvailabilityOfTimeAreaOfTransferOfGoods();
	
EndProcedure

&AtServer
Procedure HardwareTerminalWhenChangedOnServer()
	
	UpdateTerminalPresentation();
	
EndProcedure

&AtServer
Procedure StructureOfCashShiftStateWhenChangingOnServer()
	
	ConfigureCurPageDisplay();
	
EndProcedure

&AtServer
Procedure TimeAreaOfTransferOfGoodsOnChangeAtServer()
	
	UpdateFiscalReceiptParameters(False);
	
EndProcedure

#EndRegion

#Region ConfiguringVisibilityOfFormElements

&AtServer
Procedure ConfigureCurPageDisplay()
	
	If Not StructureRegisterShiftState.ShiftIsOpened
		And Not AccessRights.OpenShift Then
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.PageRegisterShiftIsClosed;
	
	ElsIf StructureRegisterShiftState.Error24Hours
		And (Not AccessRights.OpenShift Or Not AccessRights.CloseShift) Then
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.PageRegisterShiftError24Hours;
		
	Else
		
		Items.Pages.CurrentPage = Items.Pages.ChildItems.CashReceiptParametersPage;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureAvailabilityOfCashRegisterReceiptPenetration()
	
	Items.IssueCashReceipt.Enabled       = ValueIsFilled(CREEquipment) And ParametersOfReceiptFiscalizationOperation <> Undefined;
	Items.CashReceiptParameters.Enabled = ValueIsFilled(CREEquipment);
	
EndProcedure

&AtServer
Procedure AdjustVisibilityOfTerminalPresentation()
	
	Items.ThePerformanceOfTheTerminal.Visible = ValueIsFilled(Terminal)
		And FiscalDocumentType = Enums.TypesOfCREFiscalDocuments.SALESSLIP;
	
EndProcedure

&AtServer
Procedure ConfigureDisplayOfCCTPresentationHint()
	
	DisplayingCCTPresentationHint = ToolTipRepresentation.None;
	If ValueIsFilled(CREParameters) 
		And ValueIsFilled(CREParameters.DeviceID)
		And ValueIsFilled(StructureRegisterShiftState)
		And StructureRegisterShiftState.ItinerantTrade
		And Not StructureRegisterShiftState.ShiftIsOpened Then
		DisplayingCCTPresentationHint = ToolTipRepresentation.ShowBottom;
	EndIf;	
	Items.RepresentationOfTheKKT.ToolTipRepresentation = DisplayingCCTPresentationHint;
	
EndProcedure

&AtServer
Procedure ConfigureSingleReceiptGroupVisibility()
	
	If ShowsCalculationMethod = "<Auto>" Then
		Items.TheGroupIsOneCheck.Visible = SingleReceiptDocuments.Count() > 0;
	Else
		Items.TheGroupIsOneCheck.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureVisibilityOfRefinePaymentTypeByAmountGroup()
	
	If TypeOf(DocumentRef) <> Type("DocumentRef.SaleAdjustment")
		And (ShowsCalculationMethod = Enums.CalculationMethodFlags.TransferWithFullPayment
		Or ShowsCalculationMethod = Enums.CalculationMethodFlags.TransferWithPartialPayment) Then
		
		Items.GroupSpecifyingPaymentTypeByAmount.Visible = True;
		If ShowsCalculationMethod = Enums.CalculationMethodFlags.TransferWithPartialPayment Then
			Items.CreditAmount.Visible = True;
		Else
			Items.CreditAmount.Visible = False;
		EndIf;
	Else	
		Items.GroupSpecifyingPaymentTypeByAmount.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfPaymentDetailsPaymentMethodAttribute()
	
	Items.ShowsCalculationMethod.ReadOnly = SingleReceipt;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfAmountCorrectionOfPaymentTypes()
	
	If GeneratingFiscalChecksServer.PaymentByGiftCard(DocumentRef) Then
		Items.GroupSpecifyingPaymentTypeByAmount.Visible = False;
	Else
		Items.GroupSpecifyingPaymentTypeByAmount.Visible = True;
	EndIf;
	
EndProcedure

// Set the visibility of the availability of online payment Attributes.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//
&AtClientAtServerNoContext
Procedure SetVisibilityOfPaymentAttributesInOnlineStore(Form)
	
	ShowItems = TypeOf(Form.DocumentRef) = Type("DocumentRef.PaymentCardTransaction")
		And (Form.MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InternetAcquiring")
			Or Form.MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InstantPayments"));
	ShowItems = ShowItems Or Form.PaymentAttributesInOnlineStoreAreAvailable;
	
	If ShowItems Then
		Form.Items.OnlineStorePaymentGroup.Visible = True;
	Else
		Form.Items.OnlineStorePaymentGroup.Visible = False;
	EndIf;
	
	If TypeOf(Form.DocumentRef) = Type("DocumentRef.CustomerInvoiceServices")
		Or TypeOf(Form.DocumentRef) = Type("DocumentRef.SaleAdjustment")
		Or TypeOf(Form.DocumentRef) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(Form.DocumentRef) = Type("DocumentRef.CustomerInvoiceServicesAndAssets") Then
		
		Form.Items.DisplayPaymentAttributesInOnlineStore.Visible = True;
	Else
		Form.Items.DisplayPaymentAttributesInOnlineStore.Visible = False;
	EndIf;
	
EndProcedure

// Set the visibility of the availability of online payment Attributes.
// 
// Parameters:
//  Form - ClientApplicationForm - Form
//
&AtClientAtServerNoContext
Procedure SetAvailabilityOfPaymentAttributesInOnlineStore(Form)
	
	If Form.PaymentInOnlineStoreInActivationContract Then
		Form.Items.PaymentInOnlineStore.Enabled = False;
		Form.Items.OnlineStoreAddress.Enabled = False;
		Form.Items.OptionToSendAnElectronicReceiptDoNotSend.Enabled = False;
	ElsIf Form.PaymentInOnlineStore Then
		Form.Items.PaymentInOnlineStore.Enabled = True;
		Form.Items.OnlineStoreAddress.Enabled = True;
		Form.Items.OptionToSendAnElectronicReceiptDoNotSend.Enabled = False;
	Else
		Form.Items.PaymentInOnlineStore.Enabled = True;
		Form.Items.OnlineStoreAddress.Enabled = False;
		Form.Items.OptionToSendAnElectronicReceiptDoNotSend.Enabled = True;
	EndIf;
	
	If ValueIsFilled(Form.AddressOfOnlineStoreInActivationContract) Then
		Form.Items.OnlineStoreAddress.Enabled = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfPropsTypeOfPaymentInCash()
	
	Items.CashSettlementType.ReadOnly = (Items.CashSettlementType.ChoiceList.Count() = 1);
	
EndProcedure

&AtServer
Procedure SetVisibilityAndAvailabilityOfPaymentDetails()
	
	Items.TypeOfAdjustmentReceipt.ReadOnly = (Items.TypeOfAdjustmentReceipt.ChoiceList.Count() = 1);
	
	Items.AdditionalDetailsOfTheCorrectionReceipt.Visible = (FiscalDocumentType = Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip);
	
EndProcedure

&AtServer
Procedure EstablishVisibilityOfTaxAuthorityPrescriptionNumber()
	
	Items.PrescriptionNumberOfTaxAuthority.Visible = (AdjustmentReceiptType = Enums.TypesOfAdjustmentReceipts.ByPrescription);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfCorrectionDescription()
	
	Items.AdjustmentDescription.ReadOnly = (TypeOfAdjustmentReceipt = Enums.KindsOfAdjustmentReceipts.CRENonApplication);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailabilityOfTimeAreaOfTransferOfGoods()
	Items.TimeAreaOfTransferOfGoods.Visible = False;
EndProcedure

#EndRegion

#Region ConfiguringListsOfFormElementSelectionValues

&AtServer
Procedure ConfigureListOfValuesForSelectingTypeOfFiscalDocument()
	
	Items.FiscalDocumentType.ChoiceList.Clear();
	Items.FiscalDocumentType.ChoiceList.LoadValues(
		GeneratingFiscalChecksServer.TypesOfFiscalDocument(DocumentRef, ReceiptPrintingCommandName)
	);
	
	If Items.FiscalDocumentType.ChoiceList.Count() > 0 Then
		FiscalDocumentType = Items.FiscalDocumentType.ChoiceList.Get(0).Value;
		TypeOfFiscalDocumentWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureListOfValuesForSelectingTypeOfPaymentInCash()
	
	Items.CashSettlementType.ChoiceList.Clear();
	Items.CashSettlementType.ChoiceList.LoadValues(
		GeneratingFiscalChecksServer.CashSettlementTypes(DocumentRef, ReceiptPrintingCommandName, FiscalDocumentType)
	);
	
	If Items.CashSettlementType.ChoiceList.Count() > 0 Then
		CashSettlementType = Items.CashSettlementType.ChoiceList.Get(0).Value;
		TypeOfCashSettlementWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureListOfValuesForSelectingCalculationMethodAttribute()
	
	PossibleSignsOfCalculationMethodForDocument = GeneratingFiscalChecksServer.TypesOfPossibleAttributesOfCalculationMethodForDocument(
		DocumentRef,
		ARAPObjects,
		CashSettlementType,
		DocumentAmount);
		
	If SingleReceipt
		And PossibleSignsOfCalculationMethodForDocument.Count() > 0
		And PossibleSignsOfCalculationMethodForDocument[0] <> "<Auto>" Then
		
		PossibleSignsOfCalculationMethodForDocument.Insert(0, "<Auto>");
	EndIf;
		
	Items.ShowsCalculationMethod.ChoiceList.LoadValues(PossibleSignsOfCalculationMethodForDocument);
	
	If Items.ShowsCalculationMethod.ChoiceList.Count() > 0 Then
		FlagForDefaultPaymentMethod = GeneratingFiscalChecksServer.FlagForDefaultPaymentMethod(
			DocumentRef,
			ARAPObjects,
			CashSettlementType,
			DocumentAmount);
		
		If SingleReceipt And FlagForDefaultPaymentMethod <> "<Auto>" Then
			FlagForDefaultPaymentMethod = "<Auto>";
		EndIf;
		
		ShowsCalculationMethod = FlagForDefaultPaymentMethod;
		FlagForCalculationMethodWhenChangingOnServer();
		
		CalculationObjectsWithCalculationMethodAttributes = GeneratingFiscalChecksServerOverridable.CalculationObjectsWithCalculationMethodAttributes(
			DocumentRef,
			PossibleSignsOfCalculationMethodForDocument,
			AutoCalculationMethodFlags,
			ShowsCalculationMethod,
			ARAPObjects,
			DocumentAmount,
			AmountOfPrepaymentWithinOneDay
		);
		DocumentAmount = CalculationObjectsWithCalculationMethodAttributes.Total("Sum");
	EndIf;
	
	ConfigureVisibilityOfRefinePaymentTypeByAmountGroup();
	
EndProcedure

&AtServer
Procedure ConfigureListOfValuesForSelectingDefaultCorrectionType()
	
	Items.TypeOfAdjustmentReceipt.ChoiceList.Clear();
	Items.TypeOfAdjustmentReceipt.ChoiceList.LoadValues(
		GeneratingFiscalChecksServer.TypesOfCorrectionReceipt(DocumentRef, ReceiptPrintingCommandName)
	);
	
	If Items.TypeOfAdjustmentReceipt.ChoiceList.Count() > 0 Then
		TypeOfAdjustmentReceipt = Items.TypeOfAdjustmentReceipt.ChoiceList.Get(0).Value;
		TypeOfCorrectionReceiptForChangesOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetUpListOfValuesForSelectingTimeAreaOfTransferOfGoods()
	
	Items.TimeAreaOfTransferOfGoods.ChoiceList.Clear();
	TimeAreaOfTransferOfGoods = 0;
	
	
EndProcedure

#EndRegion

#Region SettingFormDetailsValues

&AtServer
Procedure SetKKTParameters()
	
	DetailsOfKKTEquipment = Common.ObjectAttributesValues(
		CREEquipment,
		"EquipmentType,
		|SerialNumber");
	
	CREParameters = New Structure;
	CREParameters.Insert("EquipmentType",         DetailsOfKKTEquipment.EquipmentType);
	CREParameters.Insert("SerialNumber",           DetailsOfKKTEquipment.SerialNumber);
	CREParameters.Insert("DeviceID", CREEquipment);
	
EndProcedure

&AtServer
Procedure InstallHardwareTerminal()
	
	EquipmentTerminal = Undefined;
	If Not ThisIsReturnViaSBP(ThisObject) Then
		ConnectedEquipmentToTerminal = TMPeripheralsServerCall.EquipmentConnectedToTerminal(Terminal);
		If ConnectedEquipmentToTerminal.CREWITHDATATRANSFER = CREEquipment Then
			EquipmentTerminal = ConnectedEquipmentToTerminal.Terminal;
		EndIf;
	EndIf;
	
	HardwareTerminalWhenChangedOnServer();
	
EndProcedure

&AtServer
Procedure SetStructureOfCashShiftState()
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(
		CREParameters.DeviceID);
	
	StructureOfCashShiftStateWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region EquipmentOperation

&AtServer
Procedure UpdateCCTPresentation()
	
	Items.RepresentationOfTheKKTExtendedTooltip.Title = "<" + NStr("vi = 'Không có dữ liệu về trạng thái phiên thu ngân';
																	|ru = 'Нет данных о состоянии кассовой смены';
																	|en = 'There is no data on the register shift status'; fa = 'There is no data on the register shift status';
																	|it = 'Нет данных о состоянии кассовой смены';
																	|pl = 'There is no data on the register shift status';
																	|tr = 'POS vardiyası durumuna ilişkin veri yok'") + ">";
	If ValueIsFilled(CREEquipment) Then
		Items.RepresentationOfTheKKT.Title = ("" +  Common.ObjectAttributeValue(CREEquipment, "Description") + " (" + NStr("vi = 'Phiên bản FFD';
																															|ru = 'Версия ФФД';
																															|en = 'FDF version'; fa = 'نسخه FDF';
																															|it = 'Versione Formati Documenti Fiscali';
																															|pl = 'Wersja FDF';
																															|tr = 'Mali belge formatı sürümü'") + ": " + FDFVersion + ")");
		If ValueIsFilled(StructureRegisterShiftState) Then
			If StructureRegisterShiftState.ShiftIsOpened Then
					Items.RepresentationOfTheKKTExtendedTooltip.Title = NStr("vi = 'Phiên đang mở.';
																			|ru = 'Смена открыта.';
																			|en = 'Shift is opened.'; fa = 'Shift is opened.';
																			|it = 'Смена открыта.';
																			|pl = 'Shift is opened.';
																			|tr = 'Vardiya açık.'");
			ElsIf StructureRegisterShiftState.ItinerantTrade Then
				Items.RepresentationOfTheKKTExtendedTooltip.Title = NStr("vi = 'Phiên đang mở. Quầy thu ngân dùng để bán hàng lưu động. Khi mở phiên thu ngân sẽ yêu cầu nhập địa điểm và địa chỉ thanh toán.';
																		|ru = 'Смена закрыта. Касса используется для разъездной торговли. При открытии смены будут запрошены место расчетов и адрес расчетов.';
																		|en = 'The POS shift is closed. The cash register is used for itinerant trade. When you open a shift, the AR/AP accounting location and address will be requested.'; fa = 'The POS shift is closed. The cash register is used for itinerant trade. When you open a shift, the AR/AP accounting location and address will be requested.';
																		|it = 'Смена закрыта. Касса используется для разъездной торговли. При открытии смены будут запрошены место расчетов и адрес расчетов.';
																		|pl = 'The POS shift is closed. The cash register is used for itinerant trade. When you open a shift, the AR/AP accounting location and address will be requested.';
																		|tr = 'Vardiya kapalı. Kasa hesabı, seyahat amaçlı ticaret için kullanılmaktadır. Vardiya açılışı esnasında ödeme yeri ve ödeme adresi talep edilecektir.'");
			Else
				Items.RepresentationOfTheKKTExtendedTooltip.Title = NStr("vi = 'Phiên đã đóng.';
																		|ru = 'Смена закрыта.';
																		|en = 'Shift is closed.'; fa = 'Shift is closed.';
																		|it = 'Смена закрыта.';
																		|pl = 'Shift is closed.';
																		|tr = 'Vardiya kapalı.'");
			EndIf;
		EndIf;
	Else
		Items.RepresentationOfTheKKT.Title = "<" + NStr("vi = 'Chưa kết nối thiết bị máy ghi nhận tiền mặt';
														|ru = 'Фискальное устройство не подключено';
														|en = 'Fiscal device is not connected.'; fa = 'Fiscal device is not connected.';
														|it = 'Dispositivo fiscale non collegato.';
														|pl = 'Urządzenie fiskalne nie jest podłączone';
														|tr = 'Mali cihaz bağlı değil'") + ">";
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateTerminalPresentation()
	
	If ValueIsFilled(EquipmentTerminal) Then
		Items.ThePerformanceOfTheTerminal.Title = "" +  Common.ObjectAttributeValue(EquipmentTerminal, "Description") + NStr("vi = '(Trước khi đánh phiếu, cần kết chuyển giao dịch với thiết bị)';
																															|ru = '(Перед пробитием фискального чека необходимо провести операцию по экварингу)';
																															|en = '(Before to issue the fiscal receipt, you need to carry out an acquiring transaction)'; fa = '(Before to issue the fiscal receipt, you need to carry out an acquiring transaction)';
																															|it = '(Prima di emettere lo scontrino fiscale è necessario effettuare l''operazione di acquisizione)';
																															|pl = '(Przed wydaniem paragonu fiskalnego należy wykonać operację acquiringu)';
																															|tr = '(Edinme işlemi mali makbuz düzenlenmeden önce yapılmalıdır)'");
	Else
		Items.ThePerformanceOfTheTerminal.Title = NStr("vi = '<Chưa kết nối thiết bị đến MTT. Khi đánh phiếu sẽ in chỉ phiếu ghi nhận tiền mặt.>';
														|ru = '<Терминал к ККТ не подключен. При пробитии чека будет распечатан только фискальный чек.>';
														|en = '<Terminal is not connected to cash register. When issuing a receipt, only the fiscal receipt will be printed.>'; fa = '<پایانه به صندوق فروش متصل نیست. هنگام صدور رسید، فقط رسید مالی چاپ خواهد شد.>';
														|it = '<Il tеrminale nel registratore di cassa non è collegato. Durante la registrazione dello scontrino sarà stampato solo lo scontrino fiscale.>';
														|pl = '<Terminal nie jest podłączony do kasy. Podczas wydania paragonu będzie wydrukowany tylko paragon fiskalny.>';
														|tr = '<Terminal YKE''ye bağlı değil. Bir makbuz girildiğinde, sadece mali makbuz yazdırılacaktır.>'");
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateHardwareConnectionStatus(ExecutionResult, AdditionalParameters) Export
	
	If CREEquipment = PredefinedValue("Catalog.Peripherals.EmptyRef") Then
		CREEquipment = ExecutionResult.Equipment;
		FDFVersion = ExecutionResult.FDFVersion;
		
		KktEquipmentWhenChangedOnServer();
	EndIf;
	
EndProcedure

&AtClient
Function ConnectEquipmentUsed()
	
	UsedEquipment = New Array;
	
	If AcquiringTransactionParameters <> Undefined And ValueIsFilled(EquipmentTerminal) Then
		UsedEquipment.Add(EquipmentTerminal);
	EndIf;
	
	For Each HardwareTableRow In EquipmentTable Do
		UsedEquipment.Add(HardwareTableRow.Equipment);
	EndDo;
	
	Return UsedEquipment;
	
EndFunction

&AtServer
Function DisableEquipmentUsed(DoNotTurnOffCCT = False)
	
	UsedEquipment = New Array;
	
	If AcquiringTransactionParameters <> Undefined And ValueIsFilled(EquipmentTerminal) Then
		UsedEquipment.Add(EquipmentTerminal);
	EndIf;
	
	ArrayOfEquipment = EquipmentTable.Unload().UnloadColumn("Equipment");
	TypesOfEquipment = Common.ObjectsAttributeValue(ArrayOfEquipment, "EquipmentType");
	
	TypeOfEquipmentCCT = PredefinedValue("Enum.PeripheralTypes.CREWithDataTransfer");
	
	For Each EquipmentType In TypesOfEquipment Do
		If EquipmentType.Value = TypeOfEquipmentCCT And DoNotTurnOffCCT Then
			Continue;
		EndIf;
		
		UsedEquipment.Add(EquipmentType.Key);
	EndDo;
	
	Return UsedEquipment;
	
EndFunction

&AtClient
Procedure PaymentByCardCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result = DialogReturnCode.Cancel Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
	
	OperationParametersList = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquiringOperation();
	OperationParametersList.TransactionType  = AdditionalParameters.TransactionType;
	OperationParametersList.TransactionAmount  = Result.Sum;
	OperationParametersList.ReceiptNumber      = Result.ReceiptNumber;
	OperationParametersList.ReferenceNumber = Result.ReferenceNumber;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.PaymentCardTransaction") Then
		OperationParametersList.DocumentBasis = DocumentRef;
	EndIf;
	
	Notification = New CallbackDescription("AfterPerformingOperationOnAcquiringTerminal", ThisObject, AdditionalParameters);
	PeripheralsPaymentSystemsServerClient.StartOperationOnAcquiringTerminal(
		Notification,
		UUID,
		EquipmentTerminal,
		OperationParametersList,
		,
		CREParameters.DeviceID);
	
EndProcedure

&AtClient
Procedure AfterPerformingOperationOnAcquiringTerminal(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		If DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Then
			
			RecordCardPaymentDataOnServer(ExecutionResult);
			
			RunCallback(
				New CallbackDescription(
					"AfterRecordingPaymentCardTransaction",
					ThisObject,
					AdditionalParameters),
				True);
			
		Else
			
			RecordCardPaymentDataOnClient(ExecutionResult, AdditionalParameters);
			
		EndIf;
		
	Else
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi thực hiện giao dịch, đã xảy ra lỗi:
				|""%1"".
				|Chưa thực hiện thanh toán theo thẻ.';
				|ru = 'При выполнении операции возникла ошибка:
				|""%1"".
				|Оплата по карте не была произведена.';
				|en = 'An error occurred while executing the transaction:
				|""%1"".
				|Payment by card was not performed.'; fa = 'An error occurred while executing the transaction:
				|""%1"".
				|Payment by card was not performed.';
				|it = 'Durante l''esecuzione dell''operazione si è verificato un errore:
				|""%1"". 
				| Il pagamento con la carta non è stato effettuato.';
				|pl = 'Podczas operacji wystąpił błąd:
				|""%1"".
				|Płatność na mapie nie została przeprowadzona.';
				|tr = 'İşlem gerçekleştirilirken hata oluştu:
				|""%1"".
				|Kart ödemesi yapılmadı.'"),
			ExecutionResult.ErrorDescription);
		RetailSalesServerCall.LogEntry(
			MessageText, "PreviewReceipt.Form.AfterPerformingOperationOnAcquiringTerminal");
		CommonClient.MessageToUser(MessageText);
		
		UnblockForm(ThisObject);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterRecordingPaymentCardTransaction(Result, AdditionalParameters) Export
	
	If Result <> Undefined
		And Result Then
		
		RetailSalesClient.ProcessShiftState(
			ThisObject,
			New CallbackDescription("AfterProcessingShiftState", ThisObject));
			
	Else
		
		UnblockForm(ThisObject);
		Return;
			
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithParametersOfReceiptFiscalizationOperation

&AtServer
Procedure UpdateFiscalReceiptParameters(UpdateReceiptTemplate = True)
	
	If Not ValueIsFilled(CREEquipment) Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
	
	ReceiptOperationParameters = New Structure;
	ReceiptOperationParameters.Insert("DocumentRef", DocumentRef);
	ReceiptOperationParameters.Insert("Organization", Organization);
	ReceiptOperationParameters.Insert("Counterparty", Counterparty);
	ReceiptOperationParameters.Insert("DocumentAmount", DocumentAmount);
	
	ReceiptOperationParameters.Insert("SingleReceipt", SingleReceipt);
	ReceiptOperationParameters.Insert("SingleReceiptDocuments", SingleReceiptDocuments);
	
	ReceiptOperationParameters.Insert("FiscalDocumentType", FiscalDocumentType);
	ReceiptOperationParameters.Insert("CashSettlementType", CashSettlementType);
	ReceiptOperationParameters.Insert("TypeOfAdjustmentReceipt", TypeOfAdjustmentReceipt);
	
	ReceiptOperationParameters.Insert("CREEquipment", CREEquipment);
	ReceiptOperationParameters.Insert("EquipmentSerialNumber", Common.ObjectAttributeValue(CREEquipment, "SerialNumber"));
	
	If Not GeneratingFiscalChecksServerOverridable.PaymentDocumentWithAbilityToBreakChecks(DocumentRef)
		And ValueIsFilled(StructureRegisterShiftState)
		And StructureRegisterShiftState.Property("Warehouse") Then
		
		ReceiptOperationParameters.Insert("Warehouse", StructureRegisterShiftState.Warehouse);
	Else
		ReceiptOperationParameters.Insert("Warehouse", Undefined);
	EndIf;
	
	ReceiptOperationParameters.Insert("OptionOfSendingElectronicReceipt", OptionOfSendingElectronicReceipt);
	ReceiptOperationParameters.Insert("ContactOfRecipientOfElectronicCheck", ?(OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail, Email, Phone));
	
	If PaymentInOnlineStore Then
		ReceiptOperationParameters.Insert("OnlineStoreAddress", OnlineStoreAddress);
	EndIf;
	
	ReceiptOperationParameters.Insert("SpecifiedAttributeForCalculationMethod", ShowsCalculationMethod);
	ReceiptOperationParameters.Insert("CalculationObjectsWithCalculationMethodAttributes", CalculationObjectsWithCalculationMethodAttributes());
	ReceiptOperationParameters.Insert("AutoCalculationMethodFlags", AutoCalculationMethodFlags.Unload());
	
	If PrepaymentAmountMan <> 0 Or PaymentAmountInCash <> 0 Or PaymentAmountElectronically <> 0 Or AmountOfPrepaymentWithinOneDay <> 0 Then
		SpecifyingPaymentTypeByAmount = New Structure;
		SpecifyingPaymentTypeByAmount.Insert("PrepaymentAmountMan", PrepaymentAmountMan);
		SpecifyingPaymentTypeByAmount.Insert("PaymentAmountInCash", PaymentAmountInCash);
		SpecifyingPaymentTypeByAmount.Insert("PaymentAmountElectronically", PaymentAmountElectronically);
		SpecifyingPaymentTypeByAmount.Insert("CreditAmount", CreditAmount);
		SpecifyingPaymentTypeByAmount.Insert("AmountOfPrepaymentWithinOneDay", AmountOfPrepaymentWithinOneDay);
		ReceiptOperationParameters.Insert("SpecifyingPaymentTypeByAmount", SpecifyingPaymentTypeByAmount);
	EndIf;
	
	ReceiptOperationParameters.Insert("PrepaymentAmountOutsideOfOneDay", PrepaymentAmountOutsideOfOneDay);

	ReceiptOperationParameters.Insert("CorrectionData", CorrectionData());
	
	ReceiptOperationParameters.Insert("TheOperationInvolvesEnteringTheBuyerSPersonalData", TheOperationInvolvesEnteringTheBuyerSPersonalData);
	ReceiptOperationParameters.Insert("CustomerPersonalDataType", CustomerPersonalDataType);
	ReceiptOperationParameters.Insert("CustomerName", CustomerName);
	ReceiptOperationParameters.Insert("CustomerPersonalData", CustomerPersonalData);
	ReceiptOperationParameters.Insert("BuyerCitizenship", BuyerCitizenship);
	ReceiptOperationParameters.Insert("BuyerDateOfBirth", BuyerDateOfBirth);
	
	ReceiptOperationParameters.Insert("ReceiptPrintingCommandName", ReceiptPrintingCommandName);
	
	AddParametersOfOperationOfLocalizationReceipt(ReceiptOperationParameters, FDFVersion);
	
	ParametersOfReceiptFiscalizationOperation = GeneratingFiscalChecksServer.UpdateFiscalReceiptParameters(ReceiptOperationParameters, FDFVersion);
	
	If UpdateReceiptTemplate Then
		UpdateReceiptTemplate();
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateReceiptTemplate()
	
	TextDocument.SetText(
		GeneratingFiscalChecksServer.UpdateReceiptTemplate(ParametersOfReceiptFiscalizationOperation, FDFVersion)
	);
	
EndProcedure

#EndRegion

#Region SettlementsWithClients

&AtServer
Function CalculationObjectsWithCalculationMethodAttributes()
	
	PossibleSignsOfCalculationMethodForDocument = GeneratingFiscalChecksServer.TypesOfPossibleAttributesOfCalculationMethodForDocument(
		DocumentRef,
		ARAPObjects,
		CashSettlementType,
		DocumentAmount
	);
	
	Return GeneratingFiscalChecksServerOverridable.CalculationObjectsWithCalculationMethodAttributes(
		DocumentRef,
		PossibleSignsOfCalculationMethodForDocument,
		AutoCalculationMethodFlags,
		ShowsCalculationMethod,
		ARAPObjects,
		DocumentAmount,
		AmountOfPrepaymentWithinOneDay
	);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure GetProcessPaymentDataInOnlineStoreFromDocument()
	
	TheseAreInternetPaymentDocuments = TypeOf(DocumentRef) = Type("DocumentRef.PaymentCardTransaction");
	
	If Not TheseAreInternetPaymentDocuments Then
		Return;
	EndIf;
		
	Query = New Query;
	Query.Text = "
	|SELECT
	|	AcquiringContracts.Ref AS Ref,
	|	AcquiringContracts.MakingPaymentMethod AS MakingPaymentMethod,
	|	AcquiringContracts.PaymentInOnlineStore AS PaymentInOnlineStore,
	|	AcquiringContracts.OnlineStoreAddress AS OnlineStoreAddress
	|FROM
	|	Document.PaymentCardTransaction AS PaymentCardTransaction
	|		INNER JOIN Catalog.AcquiringContracts AS AcquiringContracts
	|		ON PaymentCardTransaction.AcquiringContract = AcquiringContracts.Ref
	|WHERE
	|	PaymentCardTransaction.Ref = &Ref
	|";
	Query.SetParameter("Ref", DocumentRef);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ContractForConnectionToPaymentSystems = Selection.Ref;
		MakingPaymentMethod = Selection.MakingPaymentMethod;
		
		PaymentInOnlineStoreInActivationContract = Selection.PaymentInOnlineStore;
		PaymentInOnlineStore = PaymentInOnlineStoreInActivationContract;
		
		AddressOfOnlineStoreInActivationContract = Selection.OnlineStoreAddress;
		If PaymentInOnlineStoreInActivationContract Then
			OnlineStoreAddress = AddressOfOnlineStoreInActivationContract;
		EndIf;
	EndIf;
	
	If PaymentInOnlineStoreInActivationContract
		And OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.DontSend Then
		OptionOfSendingElectronicReceipt = Enums.OptionsOfSendingElectronicReceiptToCustomer.SendSMS;
		OptionToSendElectronicCheckWhenChangingOnServer();
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure LockForm(Form)
	
	If Form.Enabled = True Then
		Form.Enabled = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UnblockForm(Form)
	
	If Form.Enabled = False Then
		Form.Enabled = True;
	EndIf;
	
EndProcedure

&AtClient
Function PaymentsInOnlineStoreAreFilledInCorrectly()
	
	PaymentsInOnlineStoreAreFilledInCorrectly = True;
	
	If PaymentInOnlineStore And Not ValueIsFilled(OnlineStoreAddress) Then
		PaymentsInOnlineStoreAreFilledInCorrectly = False;
		MessageText = NStr("vi = 'Chưa điền địa chỉ của cửa hàng trực tuyến';
							|ru = 'Не заполнен адрес интернет-магазина';
							|en = 'Online store address is required'; fa = 'Online store address is required';
							|it = 'Online store address is required';
							|pl = 'Online store address is required';
							|tr = 'İnternet mağazasının adresi doldurulmadı'");
		CommonClient.MessageToUser(
				MessageText,
				,"Item.OnlineStoreAddress",,);
	EndIf;
	
	Return PaymentsInOnlineStoreAreFilledInCorrectly;
	
EndFunction

&AtClient
Function ReceiptWasFilledInCorrectly()
	
	If Not DetailsOfFormForEnteringReceiptWereFilledInCorrectly() Then
		Return False;
	EndIf;
	
	If GeneratingFiscalChecksServerCall.FiscalCheckOnDocumentIsBroken(DocumentRef) Then
		
		ShowMessageBox(
			New CallbackDescription("CloseReceiptPenetrationForm", ThisObject),
			NStr("vi = 'Theo chứng từ đã đánh phiếu';
				|ru = 'По документу уже был пробит чек';
				|en = 'Receipt of the document was printed already'; fa = 'Receipt of the document was printed already';
				|it = 'In base al documento è stato già registrato lo scontrino';
				|pl = 'W dokumencie został już skasowany paragon';
				|tr = 'Belgeye göre fiş kesildi'"));
			
		Return False;
		
	EndIf;
	
	If Not PersonalDataEnteredCorrectly() Then
		Return False;
	EndIf;
	
	If FiscalDocumentType = PredefinedValue("Enum.TypesOfCREFiscalDocuments.AdjustmentSalesSlip") Then
		If Not ValueIsFilled(AdjustmentDescription) Then
			MessageText = NStr("vi = 'Chưa điền trường ""Mô tả điều chỉnh""';
								|ru = 'Поле ""Описание коррекции"" не заполнено';
								|en = '""Adjustment description"" is not filled in'; fa = '""Adjustment description"" is not filled in';
								|it = 'Campo ""Descrizione della correzione"" non è compilato';
								|pl = 'Pole „Opis korekty” nie jest wypełnione';
								|tr = '""Düzeltmenin ayrıntısı"" alanı doldurulmadı'");
			
			CommonClient.MessageToUser(
				MessageText,
				,
				"AdjustmentDescription");
				
			Return False;
		EndIf;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Procedure SpecifyPaymentTypeByAmount()
	
	PrepaymentAmountMan = 0;
	PaymentAmountInCash = 0;
	PaymentAmountElectronically = 0;
	
	If ShowsCalculationMethod = Enums.CalculationMethodFlags.TransferWithFullPayment
		Or ShowsCalculationMethod = Enums.CalculationMethodFlags.TransferWithPartialPayment Then
		
		PrepaymentAmountMan = DocumentAmount;
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseKmVerificationSessionOnCCT(Val Cancel)
	
	CloseKmVerificationSessionOnCCTLocalization(Cancel);

EndProcedure

&AtClient
Procedure CloseKmVerificationSessionOnCCTLocalization(Val Cancel)
	

EndProcedure

&AtClient
Function DetailsOfFormForEnteringReceiptWereFilledInCorrectly()
	
	DetailsOfFormForEnteringReceiptWereFilledInCorrectly = True;
	
	If OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail")
		And Not ValueIsFilled(Email) Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền Email để gửi phiếu điện tử.';
					|ru = 'Email для отправки электронного чека не заполнен.';
					|en = 'Email for sending electronic receipts is not filled in.'; fa = 'Email for sending electronic receipts is not filled in.';
					|it = 'Email per l''invio dello scontrino elettronico non è compilato.';
					|pl = 'Nie wypełniono e-maila do wysyłki paragonu elektronicznego.';
					|tr = 'Elektronik makbuz gönderimi için email doldurulmadı.'"),
				Email
			);
		
		CommonClient.MessageToUser(MessageText);
		
		DetailsOfFormForEnteringReceiptWereFilledInCorrectly = False;
	EndIf;
	
	If OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS")
		And Not ValueIsFilled(Phone) Then
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền điện thoại để gửi phiếu điện tử.';
					|ru = 'Телефон для отправки электронного чека не заполнен.';
					|en = 'Phone for sending electronic receipts is not filled in.'; fa = 'Phone for sending electronic receipts is not filled in.';
					|it = 'Il telefono per l''invio dello scontrino elettronico non è compilato.';
					|pl = 'Nie wypełniono telefonu do wysyłki paragonu elektronicznego.';
					|tr = 'Elektronik makbuz gönderimi için telefon doldurulmadı.'"),
				Phone
			);
		
		CommonClient.MessageToUser(MessageText);
		
		DetailsOfFormForEnteringReceiptWereFilledInCorrectly = False;
	EndIf;
	
	If OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS")
		And ValueIsFilled(Phone) Then
		
		PhoneNumberWithoutFormatting = "+7" + RetailSalesClientServer.PhoneNumberIn10CharactersFormat(Phone);
		PhoneNumberFormatted = RetailSalesClientServer.FormatPhoneNumber(
											RetailSalesClientServer.PhoneNumberIn10CharactersFormat(Phone));
	
		If TrimAll(Phone) <> PhoneNumberWithoutFormatting
			And TrimAll(Phone) <> PhoneNumberFormatted Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Đã điền sai số điện thoại để gửi phiếu điện tử.
								|Số điện thoại cần có dạng như: +8412345678 hoặc (+84)123 456 7890.';
								|ru = 'Телефон для отправки электронного чека заполнен некорректно.
								|Номера телефона должен соответствовать шаблону: +71234567890 или +7(123)4567890.';
								|en = 'Phone number for sending electronic receipts is not filled in correctly.
								|Phone numbers must follow the template: +71234567890 or +7(123)4567890.'; fa = 'Phone number for sending electronic receipts is not filled in correctly.
								|Phone numbers must follow the template: +71234567890 or +7(123)4567890.';
								|it = 'Il telefono per l''invio dello scontrino elettronico non è compilato correttamente. 
								| Il numero di telefono deve corrispondere al modello: +71234567890 oppure +7(123)4567890.';
								|pl = 'Telefon do wysyłki paragonu elektronicznego jest wypełniony niepoprawnie.
								|Numer telefonu powinien odpowiadać szablonowi: +71234567890 lub +7(123)4567890.';
								|tr = 'Elektronik makbuz gönderimi için telefon numarası doğru doldurulmadı.
								|Telefon numarası şu numuneye karşılık gelmelidir: +71234567890 veya +7(123)4567890.'"),
					Phone
				);
			
			CommonClient.MessageToUser(MessageText);
			
			DetailsOfFormForEnteringReceiptWereFilledInCorrectly = False;
		EndIf;
	EndIf;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.SaleAdjustment") Then
		
		DocumentBasis = GetDocumentBase(DocumentRef);
		FiscalTransaction = DataOfPunchedFiscalCheckForDocument(DocumentBasis);
		
		If FiscalTransaction = Undefined
			And TypeOfAdjustmentReceipt = PredefinedValue("Enum.KindsOfAdjustmentReceipts.CorrectionOfErrors") Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Theo chứng từ cơ sở ""%1"" cần kiểm tra trước việc đánh phiếu.';
					|ru = 'По документу-основанию ""%1"" необходимо предварительно пробить чек.';
					|en = 'You need to issue a receipt first under the base document ""%1"".'; fa = 'You need to issue a receipt first under the base document ""%1"".';
					|it = 'Per documento-causale ""%1"" è necessario prima emettere uno scontrino.';
					|pl = 'Według dokumentu-podstawy ""%1"" należy najpierw wydać paragon,';
					|tr = '""%1"" temel belgesi için makbuz önceden düzenlenmelidir.'"),
				DocumentBasis
			);
			
			CommonClient.MessageToUser(MessageText);
			
			DetailsOfFormForEnteringReceiptWereFilledInCorrectly = False;
		EndIf;
		
	EndIf;
	
	Return DetailsOfFormForEnteringReceiptWereFilledInCorrectly;
	
EndFunction

&AtServerNoContext
Function GetDocumentBase(DocumentRef)
	
	AttributeName = "DocumentBasis";
	Return Common.ObjectAttributeValue(DocumentRef, AttributeName);
	
EndFunction

&AtServerNoContext
Function DataOfPunchedFiscalCheckForDocument(DocumentRef)
	
	Return GeneratingFiscalChecksServer.DataOfPunchedFiscalCheckForDocument(DocumentRef);
	
EndFunction

&AtServer
Function ProcessElectronicReceiptData()
	
	Return RetailSales.ProcessElectronicReceiptData(ThisObject);
	
EndFunction

&AtClient
Procedure StartCheckFiscalizationOnFiscalDevice(NotificationOnCompletion, NotificationAfterReceiptOpening)
	
	If FiscalDocumentType = PredefinedValue("Enum.TypesOfCREFiscalDocuments.SALESSLIP") Then
		
		AdditionalParameters = EquipmentManagerClientServer.AdditionalOperationParameters();
			AdditionalParameters.NotificationAfterReceiptOpening = NotificationAfterReceiptOpening;
		
		PeripheralsReceiptPrintersClient.StartCheckFiscalizationOnFiscalDevice(
			NotificationOnCompletion,
			UUID,
			CREParameters.DeviceID,
			ParametersOfReceiptFiscalizationOperation,
			AdditionalParameters);
			
	Else
		
		PeripheralsReceiptPrintersClient.StartGeneratingCorrectionReceiptOnFiscalDevice(
			NotificationOnCompletion,
			UUID,
			CREParameters.DeviceID,
			ParametersOfReceiptFiscalizationOperation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterProcessingShiftState(Result, AdditionalParameters) Export
	
	If Not Result Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
	
	// In the case of traveling trade, you need to update the parameters of operation of the receipt fiscalization
	If StructureRegisterShiftState.ItinerantTrade Then
		UpdateFiscalReceiptParameters(False);
	EndIf;
	
	Notification        = New CallbackDescription("PrintingReceipt_Completion", ThisObject);
	AfterOpeningReceipt = New CallbackDescription("PrintingReceipt_AfterOpeningReceipt", ThisObject);
	
	If Not TypeOf(DocumentRef) = Type("DocumentRef.SaleAdjustment")
		And RetailSalesClient.VerificationOfMarkingCodesByMeansOfKKTIsRequired(ParametersOfReceiptFiscalizationOperation) Then
		CheckMarkingCodeByMeansOfKKT(Notification, AfterOpeningReceipt);
	Else
		StartCheckFiscalizationOnFiscalDevice(Notification, AfterOpeningReceipt);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckMarkingCodeByMeansOfKKT(NotificationOnCompletion, NotificationAfterReceiptOpening)
	
	ReceiptPositions = ParametersOfReceiptFiscalizationOperation.ReceiptPositions;	
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
	AdditionalParameters.Insert("NotificationAfterReceiptOpening", NotificationAfterReceiptOpening);
	
	CallbackOnCompletion = New CallbackDescription(
		"CheckMarkingCodeByMeansOfKKTCompletion",
		ThisObject,
		AdditionalParameters);
	
	ButtonText = NStr("vi = 'Đánh phiếu';
						|ru = 'Пробить чек';
						|en = 'Issue cash receipt'; fa = 'صدور رسید نقدی';
						|it = 'Emettere lo scontrino';
						|pl = 'Wydrukuj paragon';
						|tr = 'Fiş kes'");
	RetailSalesClient.CheckMarkingCodeByMeansOfKKT(
		ReceiptPositions,
		FormOwner,
		ButtonText,
		CallbackOnCompletion,
		ThisObject);
	
EndProcedure

&AtClient
Procedure CheckMarkingCodeByMeansOfKKTCompletion(Result, AdditionalParameters) Export
	
	CheckMarkingCodeByMeansOfKKTCompletionLocalization(Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CheckMarkingCodeByMeansOfKKTCompletionLocalization(Result, AdditionalParameters)
	
	
EndProcedure

&AtServer
Procedure AddParametersOfOperationOfLocalizationReceipt(ReceiptOperationParameters, FDFVersion)
EndProcedure

&AtClientAtServerNoContext
Function ThisIsReturnViaSBP(Form)
	
	ThisIsReturnViaSBP = False;
	
	Return ThisIsReturnViaSBP;
	
EndFunction

&AtClient
Procedure ReturnViaSBPLocalization()
	
	NeedToUnblockForm = True;
	
	
	If NeedToUnblockForm Then
		UnblockForm(ThisObject);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintingReceipt_AfterOpeningReceipt(ExecutionParameters, AdditionalParameters) Export
	
	ReceiptHeader = ExecutionParameters.InputParameters;
	
	ReceiptHeader.CREShiftNumber = ExecutionParameters.ShiftNumber;
	ReceiptHeader.KKTReceiptNumber  = ExecutionParameters.ReceiptNumber;
	
	RunCallback(ExecutionParameters.ContinueNotification, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure PrintingReceipt_Completion(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		FiscalizationParameters = Undefined;
		
		// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
		If ExecutionResult.Property("OutputParametersSet") And ExecutionResult.OutputParametersSet.Count() > 8 Then
			FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
		EndIf;
		
		CompletionParameters = New Structure;
		CompletionParameters.Insert("CloseForm",                True);
		CompletionParameters.Insert("Form",                       ThisObject);
		CompletionParameters.Insert("FiscalOperationDetails", FiscalizationParameters);
		
		// in any case, even with a successful recording, we proceed to perform actions after recording 
		TMPeripheralsClient.PerformActionAfterRecordingFiscalTransactionInLog(
			ThisObject,
			New CallbackDescription("FiscalTransactionIsRecordedInLog", TMPeripheralsClient, CompletionParameters),
			NStr("vi = 'Không thể ghi dữ liệu vào nhật ký giao dịch tài chính.';
				|ru = 'Не удалось записать данные в журнал фискальных операций.';
				|en = 'Cannot save data to the fiscal transactions log.'; fa = 'Cannot save data to the fiscal transactions log.';
				|it = 'Non è stato possibile salvare i dati nel registro delle operazioni fiscali.';
				|pl = 'Nie udało się zapisać dane do dziennika operacji fiskalnych.';
				|tr = 'Mali işlem günlüğüne veri yazılamadı.'"));
		
		PrintingReceiptCompletionLocalization();
		
	Else
		
		MessageText = NStr("vi = 'Khi in phiếu đã xảy ra lỗi.
		                            |Chưa in phiếu trên thiết bị ghi nhận tiền mặt.
		                            |Mô tả bổ sung:
		                            |%AdditionalDetails%';
		                            |ru = 'При печати чека произошла ошибка.
		                            |Чек не напечатан на фискальном устройстве.
		                            |Дополнительное описание:
		                            |%AdditionalDetails%';
		                            |en = 'An error occurred when printing a receipt. 
		                            |The receipt is not printed on a fiscal device. 
		                            |Additional description:
		                            |%AdditionalDetails%'; fa = 'An error occurred when printing a receipt. 
		                            |The receipt is not printed on a fiscal device. 
		                            |Additional description:
		                            |%AdditionalDetails%';
		                            |it = 'Durante la stampa di scontrino si è verificato un errore. 
		                            |Scontrino non è stato stampato dal dispositivo fiscale. 
		                            |Descrizione aggiuntiva:
		                            | %AdditionalDetails%';
		                            |pl = 'Podczas drukowania paragonu wystąpił błąd.
		                            |Paragon nie został wydrukowany na urządzeniu fiskalnym.
		                            |Dodatkowy opis:
		                            |%AdditionalDetails%';
		                            |tr = 'Fiş yazdırılırken hata oluştu.
		                            |Fiş mali cihazda yazdırılmadı.
		                            |Ek ayrıntılar: 
		                            |%AdditionalDetails%'");
		
		MessageText = StrReplace(
			MessageText,
			"%AdditionalDetails%",
			ExecutionResult.ErrorDescription);
		
		CommonClient.MessageToUser(MessageText);
		
		// Close the KM check session on the CCT if it was opened
		CloseKmVerificationSessionOnCCT(False);
		
		UnblockForm(ThisObject);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintingReceiptCompletionLocalization()
	
	
EndProcedure


&AtServer
Procedure CheckCorrectnessOfRetailPriceOfTobaccoProducts()
	
	
	
EndProcedure

&AtServer
Function CheckCorrectnessOfRetailPriceOfTobaccoProductsInAdjustmentOfSales()
	CheckResult = True;
	Return CheckResult;
EndFunction

&AtServer
Function TextOnObtainingConsentToProcessingOfPersonalData()
	
	HyperlinkArray = New Array;
	HyperlinkArray.Add(NStr("vi = 'Đã nhận';
							|ru = 'Получено';
							|en = 'Received'; fa = 'دریافت‌شده';
							|it = 'Ricevuto';
							|pl = 'Received';
							|tr = 'Alındı'"));
	HyperlinkArray.Add(" ");
	
	HyperlinkArray.Add(
		New FormattedString(
			NStr("vi = 'thống nhất';
				|ru = 'согласие';
				|en = 'consent'; fa = 'consent';
				|it = 'consenso';
				|pl = 'consent';
				|tr = 'onay'"),,
			StyleColors.HyperlinkColor,,
			"OpenPrintedFormForObtainingConsentToProcessingOfPersonalData"));
	
	HyperlinkArray.Add(" ");
	HyperlinkArray.Add(NStr("vi = 'về xử lý dữ liệu cá nhân';
							|ru = 'на обработку персональных данных';
							|en = 'to personal data processing'; fa = 'برای پردازش داده‌های شخصی';
							|it = 'al trattamento dei dati personali';
							|pl = 'na przetwarzanie danych osobowych';
							|tr = 'kişisel bilgilerin i̇şlenmesi̇ne ilişkin'"));
			
	Result = New FormattedString(HyperlinkArray);
	
	Return Result;
	
EndFunction

&AtServer
Procedure EstablishVisibilityOfBuyerSPersonalDataEntryDetails()
	Items.GroupPersonalData.Visible = PersonalDataInputIsAllowed;
	Items.GroupOfPersonalDataEntryFields.Visible = TheOperationInvolvesEnteringTheBuyerSPersonalData;
	
	If CustomerPersonalDataType = Items.CustomerPersonalDataType.ChoiceList[0].Value Then // TIN
		Items.BuyerDateOfBirth.Visible = False;
		Items.BuyerPersonalDataTIN.Visible = True;
		Items.BuyerPersonalDataPassport.Visible = False;
	Else
		Items.BuyerDateOfBirth.Visible = True;
		Items.BuyerPersonalDataTIN.Visible = False;
		Items.BuyerPersonalDataPassport.Visible = True;
	EndIf;
EndProcedure

&AtServer
Function PersonalDataEnteredCorrectly()
	
	PersonalDataEnteredCorrectly = True;
	
	If TheOperationInvolvesEnteringTheBuyerSPersonalData Then
		
		If Not ConsentToPersonalDataProcessingIsReceived Then
			PersonalDataEnteredCorrectly = False;
			
			MessageText = NStr("vi = 'Cần đặt dấu hộp kiểm xác nhận việc nhận thống nhất xử lý dữ liệu cá nhân của khách hàng';
								|ru = 'Необходимо установить флаг подтверждения получения согласия на обработку персональных данных покупателя';
								|en = 'You should set the flag of confirmation of consent to the processing of customer''s personal data'; fa = 'You should set the flag of confirmation of consent to the processing of customer''s personal data';
								|it = 'È necessario impostare il flag della conferma ricevuta di autorizzazione al trattamento di dati personali dell''acquirente';
								|pl = 'Należy ustawić zaznaczenie potwierdzenia otrzymania zgody do przetwarzania danych osobowych nabywcy';
								|tr = 'Müşterinin kişisel verilerinin işlenmesine ilişkin onayın alındığını onaylamak için bayrağın ayarlanması gerekir'");
			Common.MessageToUser(MessageText);
		EndIf;
		
		If Not ValueIsFilled(CustomerName) Then
			PersonalDataEnteredCorrectly = False;
			
			MessageText = NStr("vi = 'Chưa điền họ tên của khách hàng.';
								|ru = 'Не заполнено ФИО покупателя.';
								|en = 'Customer''s full name is not filled in.'; fa = 'Customer''s full name is not filled in.';
								|it = 'Nome dell''acquirente non compilato';
								|pl = 'Nie wypełniono nazwiska i imięnia nabywcy.';
								|tr = 'Müşterinin tam adı doldurulmadı.'");
			Common.MessageToUser(MessageText);
		EndIf;
		
		If CustomerPersonalDataType = "TIN" Then
			MessageText = "";
			If Not GeneratingFiscalChecksServer.TinMeetsRequirementsOnServer(DocumentRef, CustomerPersonalData, MessageText) Then
				PersonalDataEnteredCorrectly = False;
				
				Common.MessageToUser(MessageText);
			EndIf;
		Else
			If Not ValueIsFilled(CustomerPersonalData) Then
				PersonalDataEnteredCorrectly = False;
				
				MessageText = NStr("vi = 'Chưa điền dữ liệu hộ chiếu của khách hàng';
									|ru = 'Не заполнены паспортные данные покупателя';
									|en = 'Customer''s passport details is not filled in'; fa = 'Customer''s passport details is not filled in';
									|it = 'Dati del passaporto dell''acquirente non compilati';
									|pl = 'Nie wypełniono danych paszportowych nabywcy';
									|tr = 'Müşterinin pasaport bilgileri doldurulmadı'");
				Common.MessageToUser(MessageText);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return PersonalDataEnteredCorrectly;
	
EndFunction

&AtServer
Procedure ClearPersonalData()
	
	CustomerName = PredefinedValue("Catalog.Persons.EmptyRef");
	BuyerCitizenship = PredefinedValue("Catalog.WorldCountries.EmptyRef");
	BuyerDateOfBirth = Date(1,1,1);
	CustomerPersonalData = "";
	ConsentToPersonalDataProcessingIsReceived = False;
		
EndProcedure

&AtServer
Function CorrectionData()
	
	If FiscalDocumentType = Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip Then
	
		CorrectionData = New Structure();
		CorrectionData.Insert("AdjustmentType"		, Number(AdjustmentReceiptType = Enums.TypesOfAdjustmentReceipts.ByPrescription));
		CorrectionData.Insert("AdjustmentDescription", AdjustmentDescription);
		CorrectionData.Insert("CorrectionDate_"	, DateOfAdjustedCalculation);
		CorrectionData.Insert("PrescriptionNumber"	, PrescriptionNumberOfTaxAuthority);
		
		Return CorrectionData;
		
	Else
		
		Return Undefined;
		
	EndIf;
	
EndFunction
 
// Converts an array of structures into a table of values.
// The general purpose method is out.An array of table values is not suitable - in this variant, the values of the columns are of a composite type.
// 
// Parameters:
//  StructuresArray - Array of Structure - Massy structures
// 
// Returns:
//  ValueTable - Pattern in a table of values
&AtServer
Function ArrayToValueTable(StructuresArray)
	Table = New ValueTable;
	
	If TypeOf(StructuresArray) = Type("Array")
		And StructuresArray.Count() <> 0 Then
		
		FirstStructure = StructuresArray[0];
		For Each Property In FirstStructure Do 
			Table.Columns.Add(Property.Key);
		EndDo;
		
		For Each Structure In StructuresArray Do 
			NewRow = Table.Add();
			FillPropertyValues(NewRow, Structure);
		EndDo;
	EndIf;
	
	Return Table;
EndFunction

&AtServer
Procedure BuyerCitizenship()
	
	BuyerCitizenship = RetailSales.BuyerCitizenship(CustomerName);
	
EndProcedure

&AtServer
Procedure BuyerDateOfBirth()
	
	If CustomerPersonalDataType = Items.CustomerPersonalDataType.ChoiceList[0].Value Then // TIN
		BuyerDateOfBirth = "";
	Else
		BuyerDateOfBirth = RetailSales.BuyerDateOfBirth(CustomerName);
		If Not ValueIsFilled(BuyerDateOfBirth) Then
			MessageText = NStr("vi = 'Trên thẻ cá nhân chưa điền ngày sinh.';
								|ru = 'В карточке физ. лица не заполнена дата рождения.';
								|en = 'Date of birth is not filled in a personal profile. '; fa = 'Date of birth is not filled in a personal profile. ';
								|it = 'Nella scheda della persona fisica non è compilata la data di nascita.';
								|pl = 'W karcie osoby fizycznej nie wypełniono daty urodzenia.';
								|tr = 'Gerçek kişi kartında doğum tarihi doldurulmadı.'");
			Common.MessageToUser(MessageText);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CustomerPersonalData()
	
	If CustomerPersonalDataType = Items.CustomerPersonalDataType.ChoiceList[0].Value Then // TIN
		
		CustomerPersonalData = RetailSales.BuyerTin(CustomerName);
		
		If Not ValueIsFilled(CustomerPersonalData) Then
			MessageText = NStr("vi = 'Trên thẻ cá nhân chưa điền MST.';
								|ru = 'В карточке физ. лица не заполнен ИНН.';
								|en = 'TIN in a personal card is not filled in.'; fa = 'TIN in a personal card is not filled in.';
								|it = 'Nella scheda della persona fisica non è compilato il Codice Fiscale.';
								|pl = 'W karcie osoby fizycznej nie wypełniono NIPu.';
								|tr = 'Gerçek kişi kartında VKN doldurulmadı.'");
			Common.MessageToUser(MessageText);
		EndIf;
		
	Else
		
		CustomerPersonalData = RetailSales.BuyerPassportData(CustomerName);
		
		If Not ValueIsFilled(CustomerPersonalData) Then
			MessageText = NStr("vi = 'Trên thẻ cá nhân chưa chỉ ra dữ liệu hộ chiếu.';
								|ru = 'В карточке физ. лица не указаны паспортные данные.';
								|en = 'Passport data in a personal card is not filled in.'; fa = 'Passport data in a personal card is not filled in.';
								|it = 'Nella scheda della persona fisica non sono indicati i dati del passaporto.';
								|pl = 'W karcie osoby fizycznej nie podano danych paszportowych.';
								|tr = 'Gerçek kişi kartında pasaport verileri doldurulmadı.'");
			Common.MessageToUser(MessageText);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function DeliveryDocumentWithPossibilityOfPunchingChecks(Delivery_Document)
	
	Return GeneratingFiscalChecksServer.DeliveryDocumentWithPossibilityOfPunchingChecks(Delivery_Document);
	
EndFunction

&AtClient
Procedure RecordCardPaymentDataOnClient(ExecutionResult, AdditionalParameters)
	
	Modified = True;
	FormOwner.Object.PaymentCardNumber = ExecutionResult.CardNumber;
	FormOwner.Object.AuthorizationCode      = ExecutionResult.AuthorizationCode;
	FormOwner.Object.PaymentCompleted     = True;
	
	TMPeripheralsClient.WriteObject(
		FormOwner,
		DocumentWriteMode.Posting,
		New CallbackDescription("AfterRecordingPaymentCardTransaction", ThisObject, AdditionalParameters));
	
EndProcedure

&AtServer
Procedure RecordCardPaymentDataOnServer(ExecutionResult)
	
	Try
	
		PaymentARAPTransactionWithPaymentCardObject = PaymentARAPTransactionWithPaymentCard.GetObject();
		
		PaymentARAPTransactionWithPaymentCardObject.PaymentCardNumber = ExecutionResult.CardNumber;
		PaymentARAPTransactionWithPaymentCardObject.AuthorizationCode      = ExecutionResult.AuthorizationCode;
		PaymentARAPTransactionWithPaymentCardObject.PaymentCompleted     = True;
		
		PaymentARAPTransactionWithPaymentCardObject.Write(
			DocumentWriteMode.Write,
			DocumentPostingMode.Regular);
			
	Except
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi thực hiện giao dịch, đã xảy ra lỗi:
				|""%1"".
				|Chưa ghi lại dữ liệu thanh toán bằng thẻ vào chứng từ ""%2"":
				|- Số thẻ: %3.
				|- Mã ủy quyền: %4';
				|ru = 'При выполнении операции возникла ошибка:
				|""%1"".
				|Запись данных оплаты платежной картой в документ ""%2"" не выполнена:
				|- Номер карты: %3.
				|- Код авторизации: %4';
				|en = 'An error occurred while executing the transaction:
				|""%1"".
				|Card payment data is not recorded to the ""%2"" document:
				|- Card number: %3.
				|- Authorization code: %4'; fa = 'An error occurred while executing the transaction:
				|""%1"".
				|Card payment data is not recorded to the ""%2"" document:
				|- Card number: %3.
				|- Authorization code: %4';
				|it = 'При выполнении операции возникла ошибка:
				|""%1"".
				|Запись данных оплаты платежной картой в документ ""%2"" не выполнена:
				|- Номер карты: %3.
				|- Код авторизации: %4';
				|pl = 'An error occurred while executing the transaction:
				|""%1"".
				|Card payment data is not recorded to the ""%2"" document:
				|- Card number: %3.
				|- Authorization code: %4';
				|tr = 'İşlem gerçekleştirilirken hata oluştu:
				|""%1"".
				|Ödeme kartının verilerinin ""%2"" belgesine kaydı gerçekleştirilmedi:
				|- Kart numarası: %3.
				|- Kimlik doğrulama kodu: %4'"),
			ExecutionResult.ErrorDescription,
			PaymentARAPTransactionWithPaymentCard,
			ExecutionResult.CardNumber,
			ExecutionResult.AuthorizationCode);
		
		RetailSalesServerCall.LogEntry(
			MessageText,
			"PreviewReceipt.Form.AfterPerformingOperationOnAcquiringTerminal");
		
		Common.MessageToUser(MessageText);
		
	EndTry;
	
EndProcedure

&AtServer
Function AccordingToDeliveryDocumentThereIsOnlyOnePaymentByCreditCard()
	
	AccordingToDeliveryDocumentThereIsOnlyOnePaymentByCreditCard = True;
	
	NumberOfARAPTransactionsByCard = 0;
	For Each TableRowDocumentsOfSingleReceipt In SingleReceiptDocuments Do
		If TypeOf(TableRowDocumentsOfSingleReceipt.Document) <> Type("DocumentRef.PaymentCardTransaction") Then
			Continue;
		EndIf;
		
		NumberOfARAPTransactionsByCard = NumberOfARAPTransactionsByCard + 1;
	EndDo;
	
	If NumberOfARAPTransactionsByCard > 1 Then
		AccordingToDeliveryDocumentThereIsOnlyOnePaymentByCreditCard = False;
	EndIf;
	
	Return AccordingToDeliveryDocumentThereIsOnlyOnePaymentByCreditCard;
	
EndFunction

&AtServer
Procedure AccordingToDeliveryDocumentFillInPaymentDetailsWithPaymentCard()
	
	For Each TableRowDocumentsOfSingleReceipt In SingleReceiptDocuments Do
		
		If TypeOf(TableRowDocumentsOfSingleReceipt.Document) <> Type("DocumentRef.PaymentCardTransaction") Then
			Continue;
		EndIf;
		
		AttributesOfPayment = Common.ObjectAttributesValues(
			TableRowDocumentsOfSingleReceipt.Document,
			"POSTerminal, PaymentCompleted, BusinessOperation");
		
		If Not AttributesOfPayment.PaymentCompleted Then
			
			PaymentARAPTransactionWithPaymentCard = TableRowDocumentsOfSingleReceipt.Document;
			Terminal                      = AttributesOfPayment.POSTerminal;
			
			If AttributesOfPayment.BusinessOperation = Enums.BusinessTransactions.CashReceiptFromCustomer Then
				TransactionType = "AuthorizeSales";
			Else
				TransactionType = "AuthorizeRefund";
			EndIf;
			
			AcquiringTransactionParameters = New Structure;
			AcquiringTransactionParameters.Insert("Sum",                 TableRowDocumentsOfSingleReceipt.Sum);
			AcquiringTransactionParameters.Insert("TransactionType",         TransactionType);
			AcquiringTransactionParameters.Insert("POSTerminal", Terminal);
		EndIf;
		
		Break;
		
	EndDo;
	
	InstallHardwareTerminal();
	UpdateTerminalPresentation();
	
EndProcedure

&AtServer
Procedure ClearPaymentCardDetailsAccordingToDeliveryDocument()
	
	PaymentARAPTransactionWithPaymentCard = Undefined;
	Terminal                      = Undefined;
	
	AcquiringTransactionParameters = Undefined;
	
	InstallHardwareTerminal();
	UpdateTerminalPresentation();
	
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
	If Item.Name = "sh_ShamsiInput_F_BuyerDateOfBirth" Then
		BuyerDateOfBirthOnChange(Items.BuyerDateOfBirth);
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
