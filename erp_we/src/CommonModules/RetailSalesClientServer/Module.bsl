
#Region Public

#Region FiscalTransactions

Procedure FillInFiscalTransactionData(ParametersOfReceiptFiscalizationOperation, FiscalOperationData) Export
	
	If Not FiscalOperationData.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend") Then
		ParametersOfReceiptFiscalizationOperation.Electronically = FiscalOperationData.DoNotPrintFiscalCheck;
	EndIf;
	
	If FiscalOperationData.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS")
		And ValueIsFilled(FiscalOperationData.ContactDetailsOfElectronicReceipt) Then
		ParametersOfReceiptFiscalizationOperation.Sends1CSMS = Not FiscalOperationData.SendSMSViaOFD;
		ParametersOfReceiptFiscalizationOperation.BuyerNumber = FiscalOperationData.ContactDetailsOfElectronicReceipt;
	EndIf;
	
	If FiscalOperationData.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail")
		And ValueIsFilled(FiscalOperationData.ContactDetailsOfElectronicReceipt) Then
		ParametersOfReceiptFiscalizationOperation.Sends1CEmail = Not FiscalOperationData.SendEmailViaOFD;
		ParametersOfReceiptFiscalizationOperation.BuyerEmail = FiscalOperationData.ContactDetailsOfElectronicReceipt;
	EndIf;
	
	ParametersOfReceiptFiscalizationOperation.EmailSender = FiscalOperationData.EmailSender;
	
EndProcedure

Function VATRateOfFiscalTransaction(VATRate, SettlementRatesApply = False) Export
	
	If VATRate = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT")
		Or VATRate = PredefinedValue("Catalog.VATRates.EmptyRef") Then
		Return Undefined;
	Else
		Return PriceManagementSystemClientServer.GetVATRateAsNumber(VATRate);
	EndIf;
	
EndFunction

// Calculates the attribute of the subject of calculation of the fiscal transaction.
// 
// Parameters:
//  ItemsType - EnumRef.ItemsTypes - 
//  ExcisableGoods - Boolean - 
//  KMIsSpecified - Boolean - Whether to specify a control stamp in the receipt line
//  LineOfReceiptPosition - Structure - :
// * AccountingFeature - EnumRef.ItemAccountingFeatures - .
// 
// Returns:
//  EnumRef.SettlementSubjectFlags, Undefined - Attribute For The Subject Of The Fiscal Transaction Calculation
Function AttributeForSubjectOfFiscalTransactionCalculation(ItemsType, ExcisableGoods, KMIsSpecified = True,
	LineOfReceiptPosition = Undefined) Export
	
	ReturnValue = Undefined;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.Work_5") Then
		Return PredefinedValue("Enum.SettlementSubjectFlags.Work_5");
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OperationService") Then
		Return PredefinedValue("Enum.SettlementSubjectFlags.OperationService");
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		And (Not KMIsSpecified Or WithoutAccountingFeatures(LineOfReceiptPosition)) Then
		
		If ExcisableGoods Then
			Return PredefinedValue("Enum.SettlementSubjectFlags.ExcisableGoods");
		Else
			Return PredefinedValue("Enum.SettlementSubjectFlags.OwnGoods");
		EndIf;
		
	EndIf;
	
	If ItemsType = PredefinedValue("Enum.ItemsTypes.OwnGoods")
		And KMIsSpecified And Not WithoutAccountingFeatures(LineOfReceiptPosition) Then
		
		If ExcisableGoods Then
			
			If TMCommonUseClientServer.HasObjectAttribute(LineOfReceiptPosition, "AllocationResult")
				And ValueIsFilled(LineOfReceiptPosition.AllocationResult)
				And LineOfReceiptPosition.AllocationResult.PartialDisposal Then
				
				ConsumerPackagingCapacity = LineOfReceiptPosition.AllocationResult.ConsumerPackagingCapacity;
				PartialDisposalQuantity = LineOfReceiptPosition.AllocationResult.PartialDisposalQuantity;
				
				If ConsumerPackagingCapacity = PartialDisposalQuantity Then
					Return PredefinedValue("Enum.SettlementSubjectFlags.ExcisableGoodsMarkedByIdentificationToolWithMarkingCode");
				Else
					Return PredefinedValue("Enum.SettlementSubjectFlags.ExcisableGoodsMarkedByIdentificationToolWithoutMarkingCode");
				EndIf;
				
			EndIf;
			
		Else
			
			If TMCommonUseClientServer.HasObjectAttribute(LineOfReceiptPosition, "AllocationResult")
				And ValueIsFilled(LineOfReceiptPosition.AllocationResult)
				And LineOfReceiptPosition.AllocationResult.PartialDisposal Then
				
				ConsumerPackagingCapacity = LineOfReceiptPosition.AllocationResult.ConsumerPackagingCapacity;
				PartialDisposalQuantity = LineOfReceiptPosition.AllocationResult.PartialDisposalQuantity;
				
				If ConsumerPackagingCapacity = PartialDisposalQuantity Then
					Return PredefinedValue("Enum.SettlementSubjectFlags.GoodsMarkedByIdentificationToolWithMarkingCode");
				Else
					Return PredefinedValue("Enum.SettlementSubjectFlags.GoodsMarkedByIdentificationToolWithoutMarkingCode");
				EndIf;
				
			
			Else
				Return PredefinedValue("Enum.SettlementSubjectFlags.OwnGoods");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If ReturnValue = Undefined Then
		ReturnValue = PredefinedValue("Enum.SettlementSubjectFlags.OwnGoods");
	EndIf;
	Return ReturnValue;
	
EndFunction

#EndRegion

// Returns available types of payments by document
// Parameters:
//  Form - ClientApplicationForm -
//
// Returns:
//  Structure:
//   *CashPayment - Boolean
//   *PaymentCards - Boolean
//   *BonusPoints - Boolean
//   *GiftCertificates - Boolean
//
Function AvailablePaymentMethods(Form) Export
	
	AvailablePaymentMethods = New Structure;
	AvailablePaymentMethods.Insert("CashPayment",              False);
	AvailablePaymentMethods.Insert("PaymentCards",        False);
	AvailablePaymentMethods.Insert("BonusPoints",         False);
	AvailablePaymentMethods.Insert("GiftCertificates", False);
	
	If TypeOf(Form.Object.Ref) = Type("DocumentRef.GiftCertificateSale") 
			Or TypeOf(Form.Object.Ref) = Type("DocumentRef.CashRegisterReceiptReturn")
			Or TypeOf(Form.Object.Ref) = Type("DocumentRef.ReturnOfGiftCards") Then
		
		PaymentWithPaymentCards = (Form.UsePaymentByCards
								And Form.POSTerminals.Count() > 0);
		
		AvailablePaymentMethods.Insert("CashPayment",              True);
		AvailablePaymentMethods.Insert("PaymentCards",        PaymentWithPaymentCards);
		
	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.CashRegisterReceipt") Then
		
		PaymentWithPaymentCards = (Form.UsePaymentByCards
								And Form.POSTerminals.Count() > 0);
		
		PaymentWithBonusPoints = (Form.UseLoyaltyPrograms 
								And ValueIsFilled(Form.Object.LoyaltyCard));
		
		AvailablePaymentMethods.Insert("CashPayment",              True);
		AvailablePaymentMethods.Insert("PaymentCards",        PaymentWithPaymentCards);
		AvailablePaymentMethods.Insert("BonusPoints",         PaymentWithBonusPoints);
		AvailablePaymentMethods.Insert("GiftCertificates", Form.UseGiftCards);

	ElsIf TypeOf(Form.Object.Ref) = Type("DocumentRef.PaymentCardTransaction") Then
		
		AvailablePaymentMethods.Insert("PaymentCards",        Form.POSTerminalsAreUsed);
		
	EndIf;
	
	RetailSalesClientServerLocalization.SupplementAvailablePaymentMethods(Form, AvailablePaymentMethods);

	Return AvailablePaymentMethods;
	
EndFunction

// Updates the data dashboard
//
// Parameters:
//  Form - ClientApplicationForm - The form where the dashboard is located
//  Data - Structure - Structure with dashboard data.
//
Procedure UpdateDashboardData(Form, Data) Export
	
	If Data = Undefined Then
		Form.InformationPanelProductName      = "";
		Form.InformationPanelCalculationOfTheAmount             = "";
		Form.InformationPanelOtherParametersName      = "";
		Form.InformationPanelOtherParametersValue = "";
		Return;
	EndIf;
	
	If Data.DisplayChange Then
		
		TextAccruedBonusPoints = "";
		If Data.Property("TextAccruedBonusPoints") Then
			TextAccruedBonusPoints = Data.TextAccruedBonusPoints;
		EndIf;
		
		Form.InformationPanelProductName      = TextAccruedBonusPoints;
		Form.InformationPanelCalculationOfTheAmount             = Data.TextDelivery;
		Form.InformationPanelOtherParametersName      = "";
		Form.InformationPanelOtherParametersValue = "";
		Return;
	EndIf;
	
	ProductName = New FormattedString(Data.ProductName);
	RowData       = Data.RowData;
	SummaryParameters  = Data.SummaryParameters;
	
	CalculatingAmount = New FormattedString("");
	
	Format = FormatString(SummaryParameters.Price, 2);
	
	If SummaryParameters.Sum <> 0 Then
		
		// Quantity x Price
		FormatQuantity = FormatString(SummaryParameters.Count, 3);
		PriceQuantity = StrTemplate("%1 x %2",
			Format(SummaryParameters.Count, FormatQuantity),
			Format(SummaryParameters.Price, Format));
			
		// Manual discount
		Format = FormatString(SummaryParameters.ManualDiscount, 2);
		ManualDiscount = New FormattedString("");
		If SummaryParameters.Property("ManualDiscount") Then
			If  SummaryParameters.Property("PercentRateOfManualDiscount") Then
				PercentageFormat = FormatString(SummaryParameters.PercentRateOfManualDiscount, 2);
			Else
				PercentageFormat = Format;
			EndIf;
			If SummaryParameters.ManualDiscount > 0 Then
				ManualDiscount = New FormattedString(
					ManualDiscount,
					" - ",
					New FormattedString(Format(SummaryParameters.ManualDiscount, Format),,,,"ManualDiscount"));
				ManualDiscount = New FormattedString(
					ManualDiscount,
					New FormattedString(" ( " + Format(SummaryParameters.PercentRateOfManualDiscount, PercentageFormat) + "%" + " )",,,,"ManualDiscount"));
			EndIf;
			If SummaryParameters.ManualDiscount < 0 Then
				ManualDiscount = New FormattedString(
					ManualDiscount,
					" + ",
					New FormattedString(Format(-SummaryParameters.ManualDiscount, Format),,,,"ManualDiscount"));
				ManualDiscount = New FormattedString(
					ManualDiscount,
					New FormattedString(" ( " + Format(-SummaryParameters.PercentRateOfManualDiscount, PercentageFormat) + "%" + " )",,,,"ManualDiscount"));
			EndIf;
		EndIf;
		
		// Automatic discount
		Format = FormatString(SummaryParameters.DiscountMarkupAmount, 2);
		AutomaticDiscount = New FormattedString("");
		If SummaryParameters.Property("DiscountMarkupAmount") Then
			If  SummaryParameters.Property("PercentRateOfAutomaticDiscountMarkup") Then
				PercentageFormat = FormatString(SummaryParameters.PercentRateOfAutomaticDiscountMarkup, 2);
			Else
				PercentageFormat = Format;
			EndIf;
			If SummaryParameters.DiscountMarkupAmount > 0 Then
				AutomaticDiscount = New FormattedString(
					AutomaticDiscount,
					" - ",
					New FormattedString(Format(SummaryParameters.DiscountMarkupAmount, Format),,,,"AutomaticDiscount"));
				AutomaticDiscount = New FormattedString(
					AutomaticDiscount,
					New FormattedString(" ( " + Format(SummaryParameters.PercentRateOfAutomaticDiscountMarkup,  PercentageFormat) + "%" + " )",,,,"AutomaticDiscount"));
			EndIf;
			If SummaryParameters.DiscountMarkupAmount < 0 Then
				AutomaticDiscount = New FormattedString(
					AutomaticDiscount,
					" + ",
					New FormattedString(Format(-SummaryParameters.DiscountMarkupAmount, Format),,,,"AutomaticDiscount"));
				AutomaticDiscount = New FormattedString(
					AutomaticDiscount,
					New FormattedString(" ( " + Format(-SummaryParameters.PercentRateOfAutomaticDiscountMarkup, PercentageFormat) + "%" + " )",,,,"AutomaticDiscount"));
			EndIf;
		EndIf;
		
		// Sum
		Format = FormatString(SummaryParameters.Sum, 2);
		Sum  = " = " + Format(SummaryParameters.Sum, Format);
		
		CalculatingAmount = New FormattedString(
			PriceQuantity,
			ManualDiscount,
			AutomaticDiscount,
			Sum
		);
		
	EndIf;
	
	DisplayMessageIconNearMap = False;
	If Data.Property("TheStructureOfTheMessages")
		And Data.TheStructureOfTheMessages <> Undefined
		And Data.TheStructureOfTheMessages.Messages.Count() > 0 Then
		
		If RowData.Count() <= 2
			Or (RowData.Property("Map") And Not ValueIsFilled(RowData.Map)) Then
			
			UnreadMessages = 0;
			For Each TSRow In Data.TheStructureOfTheMessages.Messages Do
				If TSRow.RemindLater Then
					UnreadMessages = UnreadMessages + 1;
				EndIf;
			EndDo;
			
			If UnreadMessages > 0 Then
				Text = StrTemplate(NStr("vi = 'Mới ( %1)';
										|ru = 'Новые (%1)';
										|en = 'New (%1)'; fa = 'New (%1)';
										|it = 'Nuovi (%1)';
										|pl = 'Nowe (%1)';
										|tr = 'Yeni (%1)'"), UnreadMessages);
			Else
				Text = Data.TheStructureOfTheMessages.Messages.Count();
			EndIf;
			
			RowData.Insert("Messages", Text);
			
		Else
			DisplayMessageIconNearMap = True;
		EndIf;
		
	EndIf;
	
	Names = New FormattedString("");
	Values = New FormattedString("");
	For Each StructureItem In RowData Do
		
		Separator = "";
		If ValueIsFilled(Names) Then
			Separator = Chars.LF;
		EndIf;
		
		Suffix = "";
		Color = Undefined;
		
		If StructureItem.Key = "Map" And DisplayMessageIconNearMap Then
			Value = New FormattedString(
				String(StructureItem.Value),
				New FormattedString(PictureLib.Information16,,,,"Messages"));
		Else
			Value = String(StructureItem.Value);
		EndIf;
		
		If Data.RequiredDetails_.Find(StructureItem.Key) <> Undefined
			And Not ValueIsFilled(StructureItem.Value) Then
			
			#If Client Then
				Color = CommonClientCached.StyleColor("ErrorNoteText");
			#Else
				Color = StyleColors.ErrorNoteText;
			#EndIf
			
			Value = NStr("vi = '<chưa điền>';
						|ru = '<не заполнено>';
						|en = '<not filled in>'; fa = '<not filled in>';
						|it = '<Non compilato>';
						|pl = '<nie wypełniono>';
						|tr = '<doldurulmadı>'");
			Suffix = "ValueNotFilledIn";
			
		ElsIf Not ValueIsFilled(StructureItem.Value) Then
			
			Continue;
			
		EndIf;
		
		Names = New FormattedString(
			Names,
			Separator,
			PresentationOfDashboardDataKey(StructureItem.Key) + ":");
		
		Values = New FormattedString(
			Values,
			Separator,
			New FormattedString(Value,,Color,,StructureItem.Key + Suffix));
		
	EndDo;
	
	Form.InformationPanelCalculationOfTheAmount             = CalculatingAmount;
	Form.InformationPanelProductName      = ProductName;
	Form.InformationPanelOtherParametersName      = Names;
	Form.InformationPanelOtherParametersValue = Values;
	
EndProcedure

// Data structure for repeating a write operation.
// 
// Returns:
//  Structure - Data for repeating the write operation.
//
Function RecordingRepeatStructure() Export
	
	RecordingRepeatStructure = New Structure;
	RecordingRepeatStructure.Insert("DetailsOfCashNodeSFiscalOperation");
	RecordingRepeatStructure.Insert("CallbackDescription");
	RecordingRepeatStructure.Insert("MessageText");
	RecordingRepeatStructure.Insert("ReturnFunctionResult");
	RecordingRepeatStructure.Insert("ResultOfSuccessfulImplementation");
	RecordingRepeatStructure.Insert("CancellationResult_");
	RecordingRepeatStructure.Insert("ProcedureName");
	RecordingRepeatStructure.Insert("ProcedureParameters");
	RecordingRepeatStructure.Insert("OperationResult");
	
	Return RecordingRepeatStructure;
	
EndFunction

// Structure of the receipt line for USAIS
// 
// Returns:
//  Structure - The structure of the receipt line for the USAIS.
//
Function StructureOfUSAISReceiptLine() Export
	
	RowOfProduct = New Structure;
	RowOfProduct.Insert("LineNumber");
	RowOfProduct.Insert("Description");
	RowOfProduct.Insert("ItemsType");
	RowOfProduct.Insert("ExcisableGoods");
	RowOfProduct.Insert("Products");
	RowOfProduct.Insert("Characteristic");
	RowOfProduct.Insert("Package");
	RowOfProduct.Insert("Count");
	RowOfProduct.Insert("NumberOfPackages");
	RowOfProduct.Insert("Price");
	RowOfProduct.Insert("PercentRateOfAutomaticDiscountMarkup");
	RowOfProduct.Insert("DiscountMarkupAmount");
	RowOfProduct.Insert("PercentRateOfManualDiscount");
	RowOfProduct.Insert("ManualDiscount");
	RowOfProduct.Insert("Sum");
	RowOfProduct.Insert("VATRate");
	RowOfProduct.Insert("VATAmount");
	RowOfProduct.Insert("Barcode");
	
	RowOfProduct.Insert("USAISProducts");
	RowOfProduct.Insert("AlcoholContainingProducts");
	RowOfProduct.Insert("AlcoholContainingProductsOpenPackage");
	RowOfProduct.Insert("Matched");
	RowOfProduct.Insert("ExciseStampCode");
	RowOfProduct.Insert("MarkedProducts");
	RowOfProduct.Insert("ProductType");
	RowOfProduct.Insert("CodeOfTypeOfAlcoholicProducts");
	RowOfProduct.Insert("VolumeM3");
	RowOfProduct.Insert("Strength");
	RowOfProduct.Insert("TIN");
	RowOfProduct.Insert("CRTR");
	RowOfProduct.Insert("ManufacturerImporterOfAlcoholicBeverages");
	
	Return RowOfProduct;
	
EndFunction

// Checking the contact information in the partner's card
//
// Parameters:
//  OptionOfSendingElectronicReceipt - EnumRef.OptionsOfSendingElectronicReceiptToCustomer -
//  ContactDetailsForVerification - Map -
//  Cancel - Boolean - 
//
Procedure CheckIndicationOfPartnerSContactDetails(OptionOfSendingElectronicReceipt, ContactDetailsForVerification, Cancel) Export
	
	ContactDetailsItemInstanceAddress = ContactDetailsForVerification[PredefinedValue("Enum.ContactInformationTypes.Email")];
	ContactDetailsPhoneNumber = ContactDetailsForVerification[PredefinedValue("Enum.ContactInformationTypes.Phone")];
	
	If OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail")
		And (ContactDetailsItemInstanceAddress = Undefined Or IsBlankString(ContactDetailsItemInstanceAddress)) Then
		
		MessageText = NStr("vi = 'Cần chỉ ra địa chỉ E-mail để có thể gửi phiếu điện tử.';
							|ru = 'Необходимо указать адрес E-mail для возможности отправки электронного чека.';
							|en = 'Specify an email address to send an electronic receipt.'; fa = 'Specify an email address to send an electronic receipt.';
							|it = 'Необходимо указать адрес E-mail для возможности отправки электронного чека.';
							|pl = 'Specify an email address to send an electronic receipt.';
							|tr = 'Elektronik fatura gönderebilmek için E-posta adresinin belirtilmesi gerekmektedir.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	ElsIf OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS")
		And (ContactDetailsPhoneNumber = Undefined Or IsBlankString(ContactDetailsPhoneNumber)) Then
		
		MessageText = NStr("vi = 'Cần chỉ ra số điện thoại để có thể gửi phiếu điện tử.';
							|ru = 'Необходимо указать номер телефона для возможности отправки электронного чека.';
							|en = 'Specify a phone number to send an electronic receipt.'; fa = 'Specify a phone number to send an electronic receipt.';
							|it = 'Необходимо указать номер телефона для возможности отправки электронного чека.';
							|pl = 'Specify a phone number to send an electronic receipt.';
							|tr = 'Elektronik fatura gönderebilmek için bir telefon numarası belirtilmesi gerekmektedir.'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
EndProcedure

// Returns an array of payment card payment lines for a document
// 
// Parameters:
//  PaymentWithPaymentCards - FormDataCollection, ValueTable, TabularSection - Payment by credit card:
//  * PaymentKind_ - EnumRef.TypesOfCashRegisterPaymentSystem -
// 
// Returns:
//  Number - the amount of payment for the SBP according to the document
//
Function PaymentLinesWithPaymentCards(Val PaymentWithPaymentCards) Export
	
	FilterPaymentCards_ = New Structure("PaymentKind_", PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard"));
	Return PaymentWithPaymentCards.FindRows(FilterPaymentCards_);
	
EndFunction

// Returns the amount of payment by payment cards for the document
// 
// Parameters:
//  PaymentWithPaymentCards - FormDataCollection, ValueTable, TabularSection - Payment by credit card:
//  * PaymentKind_ - EnumRef.TypesOfCashRegisterPaymentSystem -
//  * Sum - Number - 
// 
// Returns:
//  Number - the amount of payment by payment cards according to the document
//
Function AmountOfPaymentByPaymentCards(Val PaymentWithPaymentCards) Export
	
	PaymentCards_ = 0;
	
	FilterPaymentCards_ = New Structure("PaymentKind_", PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard"));
	For Each PaymentLine_ In PaymentWithPaymentCards.FindRows(FilterPaymentCards_) Do
		PaymentCards_ = PaymentCards_ + PaymentLine_.Sum;
	EndDo;
	
	Return PaymentCards_;
	
EndFunction

#Region WorkWithContractInformationFZ54

// Set the activity of form elements: Polepoluchenonalny, Phone, Email.
// Active elements are associated with the numeric keypad of the form.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
//
Procedure SetElementActivity(Form) Export
	
	FormFieldReceivedInCash = Form.Items.FieldReceivedInCash; // FormField
	If Form.CurrentItem = FormFieldReceivedInCash
		And Form.ActiveField <> FormFieldReceivedInCash.Name Then
		
		RetailSalesClientServer.SetActiveElement(Form, FormFieldReceivedInCash);
		
	EndIf;
	
	PhoneFormField = Form.Items.Phone; // FormField
	If Form.CurrentItem = PhoneFormField
		And Form.ActiveField <> PhoneFormField.Name Then
		
		RetailSalesClientServer.SetActiveElement(Form, PhoneFormField);
		
	EndIf;
		
	
EndProcedure

// Enable keyboard usage for the form element.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
//  Item - FormField - The form element for which you want to enable the keyboard.
//
Procedure SetActiveElement(Form, Item) Export
	
	Form.ActiveField = Item.Name;
	
	ItemArray = New Array; // Array of FormFieldExtensionForATextBox
	ItemArray.Add(Form.Items.FieldReceivedInCash);
	ItemArray.Add(Form.Items.Phone);
	ItemArray.Add(Form.Items.Email);
	For Each FormItem In ItemArray Do
		FormItem.BackColor = New Color;
	EndDo;
	
	ActiveFieldElements = Form.Items[Form.ActiveField]; // FormFieldExtensionForATextBox
	ActiveFieldElements.BackColor = Form.FieldSelectionBackColor;
	
	EmailElements = Form.Items.Email; // FormField
	
	If Form.ActiveField = EmailElements.Name Then
		Form.Items.GroupPageRightKeyboard.Visible = False;
		Form.Items.GroupPageOther.Visible = False;
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupKeyboardMode;
		Form.CurrentItem = EmailElements;
	Else
		Form.Items.GroupPageRightKeyboard.Visible = True;
		Form.Items.GroupPageOther.Visible = True;
		Form.Items.GroupPages.CurrentPage = Form.Items.GroupPageRightKeyboard;
	EndIf;
	
EndProcedure

// Procedure-Set the option for sending an electronic receipt.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
//  OptionOfSendingElectronicReceipt - EnumRef.OptionsOfSendingElectronicReceiptToCustomer - Option for sending
//                                                                                                    an electronic receipt.
//
Procedure SetOptionToSendElectronicReceipt(Form, OptionOfSendingElectronicReceipt) Export
	
	If Form.OptionOfSendingElectronicReceipt = OptionOfSendingElectronicReceipt Then
		Return;
	EndIf;
	
	Form.OptionOfSendingElectronicReceipt = OptionOfSendingElectronicReceipt;
	
	If TMCommonUseClientServer.HasObjectAttribute(Form.Items, "SendSMSCommand") Then
		
		ItemArray = New Array; // Array of FormFieldExtensionForATextBox
		ItemArray.Add(Form.Items.SendSMSCommand);
		ItemArray.Add(Form.Items.SendEmailCommand);
		ItemArray.Add(Form.Items.TheSendCommandIsNotRequired);
		
		For Each FormItem In ItemArray Do
			FormItem.BackColor = New Color;
		EndDo;
		
		If Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS") Then
			ElementsSendSMSCommand = Form.Items.SendSMSCommand; // FormFieldExtensionForATextBox
			ElementsSendSMSCommand.BackColor = Form.FieldSelectionBackColor;
		ElsIf Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail") Then
			ElementsSendEmailCommand = Form.Items.SendEmailCommand; // FormFieldExtensionForATextBox
			ElementsSendEmailCommand.BackColor = Form.FieldSelectionBackColor;
		ElsIf Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend") Then
			ElementsSendCommandIsNotRequired = Form.Items.TheSendCommandIsNotRequired; // FormFieldExtensionForATextBox
			ElementsSendCommandIsNotRequired.BackColor = Form.FieldSelectionBackColor;
		EndIf;
		
	EndIf;
	
EndProcedure

// Format the phone number. From a number like 9999999999, it forms +7(999) 999-99-99.
//
// Parameters:
//  Phone - String - phone number.
// 
// Returns:
//  String - Formatted phone number.
//
Function FormatPhoneNumber(Phone) Export
	
	If ValueIsFilled(Phone) Then
		
		If StrLen(Phone) > 3 Then;
			Buffer = Mid(Phone, 4, StrLen(Phone) - 3);
		Else
			Buffer = "";
		EndIf;
		
		Return "+7(" + Left(Phone, 3) + ")" + Buffer;
		
	Else
		
		Return "+7";
		
	EndIf;
	
EndFunction

// Get 10 digits of the phone number from the transmitted view.
//
// Parameters:
//  Phone - String - Representation of the phone number.
// 
// Returns:
//  String - 10 digits of the phone number.
//
Function PhoneNumberIn10CharactersFormat(Phone) Export
	
	PhoneNumber10Characters = "";
	Numbers_1 = "0123456789";
	
	LengthOfPhonePresentation = StrLen(Phone);
	For IndexOf = 1 To LengthOfPhonePresentation Do
		
		Char = Mid(Phone, IndexOf, 1);
		If StrFind(Numbers_1, Char) > 0 Then
			PhoneNumber10Characters = PhoneNumber10Characters + Char;
		EndIf;
		
	EndDo;
	
	Return Right(PhoneNumber10Characters, 10);
	
EndFunction

// Returns an empty structure for the payment result of the KKM receipt.
// 
// Returns:
//  Structure - structure with properties:
//   * ReceivedInCash - Number - The amount of the cash payment.
//   * ElectronicReceiptData - Structure - Electronic receipt data, See StructureElectronicReceiptData.
//
Function PaymentResultStructure() Export
	
	PaymentResult = New Structure;
	PaymentResult.Insert("ReceivedInCash",      0);
	PaymentResult.Insert("ElectronicReceiptData", Undefined);
	
	Return PaymentResult;
	
EndFunction

// Returns an empty data structure for the KKM electronic receipt.
// 
// Returns:
//  Structure - structure with properties:
//   * Partner - CatalogRef.Partners - Partner.
//   * OptionOfSendingElectronicReceipt - EnumRef.OptionsOfSendingElectronicReceiptToCustomer - Option
//       for sending an electronic receipt.
//   * ContactDetailsOfElectronicReceipt - String - Phone number or email address.
//
Function StructureElectronicReceiptData() Export
	
	ElectronicReceiptData = New Structure;
	ElectronicReceiptData.Insert("Partner",                          PredefinedValue("Catalog.Partners.RetailCustomer"));
	ElectronicReceiptData.Insert("OptionOfSendingElectronicReceipt",  PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend"));
	ElectronicReceiptData.Insert("ContactDetailsOfElectronicReceipt", "");
	
	Return ElectronicReceiptData;
	
EndFunction

// Get the details of the electronic receipt.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
// 
// Returns:
//  Structure - Electronic receipt data, See StructureElectronicReceiptData.
//
Function ElectronicReceiptData(Form) Export
	
	ElectronicReceiptData = StructureElectronicReceiptData();
	
	ContactDetailsOfElectronicReceipt = "";
	If Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS") Then
		
		ContactDetailsOfElectronicReceipt = "+7" + PhoneNumberIn10CharactersFormat(Form.Phone);
		
	ElsIf Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail") Then
		
		ContactDetailsOfElectronicReceipt = Form.Email;
		
	EndIf;
	
	If (Not ValueIsFilled(Form.Partner) Or Form.Partner = PredefinedValue("Catalog.Partners.RetailCustomer"))
		And ValueIsFilled(ContactDetailsOfElectronicReceipt) Then
		SearchResult = RetailSalesServerCall.FindPartnerUsingContactDetailsOfElectronicReceipt(
			Form.OptionOfSendingElectronicReceipt,
			ContactDetailsOfElectronicReceipt);
		If SearchResult <> Undefined Then
			
			Form.Partner                                 = SearchResult.Partner;
			Form.OptionToSendThePartnerSElectronicReceipt = SearchResult.OptionOfSendingElectronicReceipt;
			
			If ValueIsFilled(SearchResult.Phone) Then
				Form.PhoneNumber10Characters = RetailSalesClientServer.PhoneNumberIn10CharactersFormat(SearchResult.Phone);
				Form.Phone = RetailSalesClientServer.FormatPhoneNumber(Form.PhoneNumber10Characters);
				Form.Items.Phone.ChoiceList.Add(Form.Phone);
			EndIf;
			
			If ValueIsFilled(SearchResult.Email) Then
				Form.Email = SearchResult.Email;
				Form.Items.Email.ChoiceList.Add(Form.Email);
			EndIf;
			
			If Form.Items.Phone.ChoiceList.Count() > 0 Then
				Form.Items.Phone.DropListButton = True;
			EndIf;
			
			If Form.Items.Email.ChoiceList.Count() > 0 Then
				Form.Items.Email.DropListButton = True;
			EndIf;
			
		EndIf;
	EndIf;
	
	ElectronicReceiptData.Partner                          = Form.Partner;
	ElectronicReceiptData.OptionOfSendingElectronicReceipt  = Form.OptionOfSendingElectronicReceipt;
	ElectronicReceiptData.ContactDetailsOfElectronicReceipt = ContactDetailsOfElectronicReceipt;
	
	Return ElectronicReceiptData;
	
EndFunction

// Check whether the electronic receipt data needs to be processed on the server.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
// 
// Returns:
//  Structure - structure with properties:
//   * NeedToUpdateContactInformation - Boolean - You need to update your contact information.
//   * YouNeedToCreatePartner - Boolean - You need to create a partner.
//
Function CheckWhetherElectronicReceiptDataNeedsToBeProcessed(Form) Export
	
	ReturnValue = New Structure;
	ReturnValue.Insert("NeedToUpdateContactInformation", False);
	ReturnValue.Insert("YouNeedToCreatePartner", False);
	ReturnValue.Insert("YouNeedToUpdateOptionForSendingPartnerSElectronicReceipt", False);
	
	PartnerCreated = ValueIsFilled(Form.Partner)
	             And (Form.Partner <> PredefinedValue("Catalog.Partners.RetailCustomer"));
	
	UpdateContactInformation_ = (PartnerCreated And Form.AutomaticallyUpdatePartnerContacts)
	                                 Or (Form.AutomaticallyCreatePartners And Not PartnerCreated);
	
	If Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendSMS") Then
		
		Phones = New Array;
		For Each ValueListItem In Form.Items.Phone.ChoiceList Do
			Phones.Add(PhoneNumberIn10CharactersFormat(ValueListItem.Value));
		EndDo;
		
		If Phones.Find(PhoneNumberIn10CharactersFormat(Form.Phone)) = Undefined Then
			ReturnValue.NeedToUpdateContactInformation = UpdateContactInformation_;
		EndIf;
		
	ElsIf Form.OptionOfSendingElectronicReceipt = PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.SendByEmail") Then
		
		AddressesEmail = New Array;
		For Each ValueListItem In Form.Items.Email.ChoiceList Do
			AddressesEmail.Add(ValueListItem.Value);
		EndDo;
		
		If AddressesEmail.Find(Form.Email) = Undefined Then
			ReturnValue.NeedToUpdateContactInformation = UpdateContactInformation_;
		EndIf;
		
	EndIf;
	
	ReturnValue.YouNeedToUpdateOptionForSendingPartnerSElectronicReceipt
		= UpdateContactInformation_
		And Form.OptionOfSendingElectronicReceipt <> Form.OptionToSendThePartnerSElectronicReceipt;
		
	If Form.OptionOfSendingElectronicReceipt <> PredefinedValue("Enum.OptionsOfSendingElectronicReceiptToCustomer.DontSend") Then
		ReturnValue.YouNeedToCreatePartner = Form.AutomaticallyCreatePartners And Not PartnerCreated;
	Else
		ReturnValue.YouNeedToCreatePartner = False;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// The function casts a string to a number.
//
// Parameters:
//  NumberAsString           - String - String to be converted to a number.
//  Return undefined-Boolean - if True and the string contains an invalid value, then return Undefined.
//
// Returns:
//  Number - The given value.
//
Function Convert_String_To_Number(NumberAsString) Export
	
	DescriptionOfNumberType = New TypeDescription("Number");
	Value_Number = DescriptionOfNumberType.AdjustValue(NumberAsString);
	
	Return Value_Number;
	
EndFunction

// Controls the availability of keyboard buttons on the mixed payment form.
//
// Parameters:
//  Form - ClientApplicationForm - Form (cash payment Form or mixed payment Form).
//
Procedure SetAccessibilityOfKeyboardButtonsOfMixedPaymentForm(Form) Export

	FullNonCashPayment = (Form.AmountDue 
								- Form.PaidWithPaymentCards 
								- Form.PaidByCertificates 
								- Form.PaidWithBonusPoints
								- Form.PaidBySBP) = 0;
							
	ActiveFieldReceivedInCash = (Form.ActiveField = Form.Items.FieldReceivedInCash.Name);
	
	Form.Items.GroupPageRightKeyboard.Enabled = Not ActiveFieldReceivedInCash Or ActiveFieldReceivedInCash And Not FullNonCashPayment;
	Form.Items.GroupPageOther.Enabled = Not ActiveFieldReceivedInCash Or ActiveFieldReceivedInCash And Not FullNonCashPayment;
	
EndProcedure

#EndRegion

#Region CachingDataOfDynamicFormDetails

// Caches table row IDs in relation to the data of dynamic Attributes of form tables
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure SaveDataOfDynamicAttributesOfFormTablesToCache(Form) Export

	RetailSalesClientServerLocalization.SaveDataOfDynamicAttributesOfFormTablesToCache(Form);
	
EndProcedure

// Retrieves data from the cache of dynamic Attributes of Form tables.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure RecoverDataFromCacheOfDynamicDetailsOfFormTables(Form) Export

	RetailSalesClientServerLocalization.RecoverDataFromCacheOfDynamicDetailsOfFormTables(Form);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function FormatString(Number, FractionDigits)
	
	If Int(Number) = Number Then
		Return "NZ=0; NFD=;";
	Else
		Return "NZ=0; NFD=" + FractionDigits;
	EndIf
	
EndFunction

// Returns:
//	String -
Function PresentationOfDashboardDataKey(Val DataKey)
	RepresentationsOfDataKeys = New Structure;
	RepresentationsOfDataKeys.Insert("Seller", NStr("vi = 'Người bán';
													|ru = 'Продавец';
													|en = 'Seller'; fa = 'فروشنده';
													|it = 'Venditore';
													|pl = 'Seller';
													|tr = 'Satıcı'"));
	RepresentationsOfDataKeys.Insert("Premise", NStr("vi = 'Nhà kho';
													|ru = 'Помещение';
													|en = 'Premise'; fa = 'Premise';
													|it = 'Locale';
													|pl = 'Premise';
													|tr = 'Depolama alanı'"));
	RepresentationsOfDataKeys.Insert("Map", NStr("vi = 'Thẻ';
												|ru = 'Карта';
												|en = 'Card'; fa = 'کارت';
												|it = 'Mappa';
												|pl = 'Card';
												|tr = 'Harita'"));
	DataKeyRepresentation = DataKey;
	If RepresentationsOfDataKeys.Property(DataKey) Then
		DataKeyRepresentation = RepresentationsOfDataKeys[DataKey];
	EndIf;
	Return DataKeyRepresentation;
EndFunction

Function WithoutAccountingFeatures(LineOfReceiptPosition)
	
	If Not ValueIsFilled(LineOfReceiptPosition) Then
		Return True;
	EndIf;
	
	If ValueIsFilled(LineOfReceiptPosition)
		And Not TMCommonUseClientServer.HasObjectAttribute(LineOfReceiptPosition, "ProductTypeIS") Then
		
		Return True;
		
	EndIf;
	
	
	Return False;
	
EndFunction

//Sets the availability of Form commands for BB payment
// 
// Parameters:
//  FormItems - FormAllItems - Form elements that contain the desired element
//  Date - Date - Document date
//
Procedure SetAvailabilityOfBonusPointsPaymentTeams(FormItems, Date) Export
	
	StartDateOfBonusPointsMechanism_2_5 = GeneralPurposeTMServerCall.ConstantValue("StartDateOfBonusPointsMechanism_2_5");
	
	ItemArray = New Array();
	ItemArray.Add("GroupProductsBonusPoints");

	TMCommonUseClientServer.SetPropertyOfFormElements(FormItems, ItemArray, "Enabled",
	BegOfDay(Date) >= BegOfDay(StartDateOfBonusPointsMechanism_2_5));
	
EndProcedure

// Calculates the period interval
//
// Parameters:
// StartDate - Date - the start date from which the end date of the period will be calculated
// Periodicity - Date - value of the "Frequency" enumeration"
// NumberOfPeriods - Number - the number of repetitions of the period.
//
// Returns:
// 	Date -
//
Function CalculatePeriodInterval(StartDate, Periodicity, NumberOfPeriods) Export

	OneDay = 86400;

	If Periodicity = PredefinedValue("Enum.Periodicity.Day") Then
		
		EndDate = StartDate + OneDay * NumberOfPeriods;

	ElsIf Periodicity = PredefinedValue("Enum.Periodicity.Week") Then
		
		EndDate = StartDate + OneDay * 7 * NumberOfPeriods;

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.TenDays")) Then
		
		MonthDay = Day(StartDate);
		BeginningOfMonth = BegOfMonth(StartDate);
		If MonthDay <= 10 Then
			DecadeNumber = 1;
		ElsIf MonthDay <= 20 Then
			DecadeNumber = 2;
		Else
			DecadeNumber = 3;
		EndIf;
			
		DecadeNumber = DecadeNumber + NumberOfPeriods;
		
		If DecadeNumber > 0 Then
			OfMonths = Int((DecadeNumber-1)/3);
		Else
			OfMonths = -1 - Int((-DecadeNumber)/3);
		EndIf;
			
		DecadeNumber = DecadeNumber - 3*OfMonths;
		Dr = AddMonth(BeginningOfMonth, OfMonths) + (DecadeNumber-1) * 10 * OneDay;

		If NumberOfPeriods > 0 Then
			EndDate = Dr;
		Else 
			MonthDay = Day(Dr);

			If MonthDay <= 10 Then
				EndDate = EndOfDay(BegOfMonth(Dr) + OneDay * 9);
			ElsIf MonthDay <= 20 Then
				EndDate = EndOfDay(BegOfMonth(Dr) + OneDay * 19);
			Else
				EndDate = EndOfMonth(Dr);
			EndIf;
		EndIf;

	ElsIf (Periodicity= PredefinedValue("Enum.Periodicity.Month")) Then
		
		EndDate = AddMonth(StartDate, NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Quarter")) Then
		
		EndDate = AddMonth(StartDate, 3 * NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.HalfYear")) Then
		
		EndDate = AddMonth(StartDate, 6 * NumberOfPeriods);

	ElsIf (Periodicity = PredefinedValue("Enum.Periodicity.Year")) Then
		
		EndDate = AddMonth(StartDate, 12 * NumberOfPeriods);

	EndIf;
			
	Return EndOfDay(EndDate);

EndFunction // Calculate the date of the end of the period()

// Returns an array of names of document forms that support the functionality of the cashier's workplace.
//
// Returns:
//  Array of String -
Function NamesOfCWPForms() Export

	NamesOfCWPForms = New Array;
	NamesOfCWPForms.Add("Document.CashRegisterReceipt.Form.CWPDocumentForm");
	NamesOfCWPForms.Add("Document.CashRegisterReceiptReturn.Form.CWPDocumentForm");
	NamesOfCWPForms.Add("Document.GiftCertificateSale.Form.CWPDocumentForm");
	NamesOfCWPForms.Add("Document.ReturnOfGiftCards.Form.CWPDocumentForm");
	
	Return NamesOfCWPForms;
EndFunction

#EndRegion
