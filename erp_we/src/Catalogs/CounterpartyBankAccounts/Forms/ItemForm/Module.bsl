#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	MainCountry = Constants.MainCountry.Get();
	
	Items.GroupErrorInAccountNumber.Visible = False;
	Items.BankDetailsPages.PagesRepresentation = FormPagesRepresentation.None;
	Items.PagesOfBankDetailsForSettlements.PagesRepresentation = FormPagesRepresentation.None;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel)
	
	If Object.ManualBankDetailsChange Then
		FillPropertyValues(Object, ThisObject, CashClientServer.BankingDetails(True));
	EndIf;
	
	Object.BankNameInt = BankNameInt;
	
	If Object.TransferBankDetailsManualEdit Then
		FillPropertyValues(Object, ThisObject, CashClientServer.BankingDetails(True, True));
	EndIf;
	
	Object.BankNameForPaymentsInt = BankNameForPaymentsInt;
	
	If Not SettlementBankUsed Then
		Object.TransferBankDetailsManualEdit = False;
	EndIf;
	
	If IsBlankString(Object.Description) Then
		Object.Description = GenerateAutoName(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	AttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	CashClientLocalization.BeforeClosingBankAccountForm(ThisObject);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	OwnerOnChangeServer();
	
EndProcedure

&AtClient
Procedure AccountNumberOnChange(Item)
	
	AccountNumberOnChangeServer();
	CashClientServer.FillInMainBankDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure AccountNumberTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	Return;
	
EndProcedure


&AtClient
Procedure ThisIsAnIBANOnChange(Item)

	Items.GroupErrorInAccountNumber.Visible = False;
	
	Object.ForeignBank = True;
	
	
	If Object.ThisIsAnIBAN Then
		CheckIBAN(ThisObject)
	EndIf;
	
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	CashClientServer.FillInMainBankDetails(ThisObject);

EndProcedure

&AtClient
Procedure BankOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankIndicationMethodOnChange(Item)
	
	Object.ManualBankDetailsChange = BankIndicationMethod = "ManualFillingInOfBankingDetails";
	WhenChangingManuallyChangeBankDetails()
	
EndProcedure

&AtClient
Procedure BankInGroupOnChange(Item)
	
	WhenChangingBank();
	
EndProcedure

&AtClient
Procedure BankBICOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankCorrAccountOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankAccountForPaymentsOnChange(Item)

	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankDescriptionOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClient
Procedure BankSWIFTCodeOnChange(Item)
	
	CashClientServer.FillInMainBankDetails(ThisObject)

EndProcedure

&AtClient
Procedure BankNameIntOnChange(Item)

	CashClientServer.FillInMainBankDetails(ThisObject);

EndProcedure

&AtClient
Procedure CashCurrencyOnChange(Item)
	
	CurrencyAccount = (ValueIsFilled(Object.CashCurrency) And Object.CashCurrency <> CurrencyOfComplianceAccounting);
	CashCurrencyOnChangeServer();
	
EndProcedure

&AtClient
Procedure SettlementBankUsedOnChange(Item)
	
	If SettlementBankUsed Then
		TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
											|ru = 'Ввести реквизиты банка вручную...';
											|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
											|it = 'Inserire i requisiti bancari manualmente...';
											|pl = 'Wpisz dane banku ręcznie...';
											|tr = 'Banka bilgilerini manuel olarak gir...'");
	Else
		Object.TransferBank = Undefined;
		AttributesList = CashClientServer.BankingDetails(True, True);
		CashClientServer.ClearBankDetailsOnForm(ThisObject, AttributesList);
		FillPropertyValues(Object, ThisObject, AttributesList);
		Object.TransferBankDetailsManualEdit = True;
	EndIf;
	
	ConfigureDependentFormElements();
	CashClientServer.FillInMainBankDetails(ThisObject);
	
EndProcedure

&AtClient
Procedure TransferBankOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure MethodOfSpecifyingBankForSettlementsOnChange(Item)
	
	Object.TransferBankDetailsManualEdit = MethodOfSpecifyingBankForSettlements = "ManualFillingInOfBankingDetails";
	WhenChangingManuallyChangingBankDetailsForSettlements()
	
EndProcedure

&AtClient
Procedure BankForSettlementsInGroupOnChange(Item)
	
	WhenChangingBankForSettlements();
	
EndProcedure

&AtClient
Procedure TransferBankBICOnChange(Item)

	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure TransferBankDescriptionOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankSWIFTCodeForPaymentsOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure BankNameForPaymentsIntOnChange(Item)
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject)

EndProcedure

&AtClient
Procedure CorrespondentCRTRTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	Return;
	
EndProcedure

&AtClient
Procedure CorrespondentTINOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure SeparateSDOAccountOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure StateContractOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure UseAPPCReporterOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure UseCorrespondentTextOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure UseOfIncorrespondentOnChange(Item)
	
	Return;
	
EndProcedure

&AtClient
Procedure CountryOfBankOnChange(Item)
	
	Object.CountryOfBank = CountryOfBank;
	
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	If Not Object.Ref.IsEmpty() Then
		OpenForm("Catalog.CounterpartyBankAccounts.Form.AttributeUnlocking",,,,,, 
			New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject), 
			FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
	EndIf;
	
EndProcedure

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

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure CheckIBAN(Form)

	If IsBlankString(Form.Object.AccountNumber) Then
		Return;
	EndIf;

	If CashClientServer.CorrectIBANLength(Form.Object.AccountNumber) Then
		If CashClientServer.ValidIBANControlKey(Form.Object.AccountNumber) Then
			If Form.Object.ManualBankDetailsChange Then
				SWIFT = Form.Object.BankSWIFTCode;
			ElsIf ValueIsFilled(Form.Object.Bank) Then
				SWIFT = CashServerCall.SWIFT(Form.Object.Bank);
			EndIf;
			
			If ValueIsFilled(SWIFT) Then
				If CashClientServer.AccountNumberCorrespondsToBank(Form.Object.AccountNumber, SWIFT) Then
					Form.Items.GroupErrorInAccountNumber.Visible = False;
				Else
					Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'IBAN không khớp với ngân hàng';
																|ru = 'IBAN не соответствует банку';
																|en = 'IBAN does not match the bank'; fa = 'IBAN does not match the bank';
																|it = 'L''IBAN non corrisponde alla banca';
																|pl = 'IBAN nie jest zgodny z bankiem';
																|tr = 'IBAN bankayla eşleşmiyor'");
					Form.Items.GroupErrorInAccountNumber.Visible = True;
				EndIf;
			EndIf;
		Else
			Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'Số tài khoản không chính xác';
														|ru = 'Номер счета введен некорректно';
														|en = 'Incorrect account number'; fa = 'Incorrect account number';
														|it = 'Numero di conto inserito errato';
														|pl = 'Numer rachunku został wprowadzony niepoprawnie';
														|tr = 'Hesap numarası yanlış girildi'");
			Form.Items.GroupErrorInAccountNumber.Visible = True;
		EndIf
	Else
		Form.Items.ErrorInAccountNumber.Title = NStr("vi = 'Số tài khoản không khớp với định dạng IBAN';
													|ru = 'Номер счета не соответствует формату IBAN';
													|en = 'The account number does not match the IBAN format'; fa = 'شماره حساب با قالب IBAN مطابقت ندارد';
													|it = 'Il numero di conto non corrisponde al formato IBAN';
													|pl = 'Numer rachunku nie jest zgodny z formatem IBAN';
													|tr = 'Hesap numarası, IBAN formatı ile uyumlu değildir'");
		Form.Items.GroupErrorInAccountNumber.Visible = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure AccountNumberOnChangeServer()
	
	Items.GroupErrorInAccountNumber.Visible = False;
	AccountNumber = Upper(StrReplace(StrReplace(TrimAll(AccountNumber), " ", ""), ".", ""));
	Object.AccountNumber = AccountNumber;
	
	If InternationalBankAccountDetails Then
		Object.ForeignBank = True;
		If Mid(AccountNumber, 1, 4) = "IBAN" Then
			AccountNumber = Mid(AccountNumber, 5);
			Object.AccountNumber = AccountNumber;
		EndIf;
		If CashClientServer.CorrectIBANLength(Object.AccountNumber) Then
			Object.ThisIsAnIBAN = True;
			IdentifyCountryAndBankByIBAN();
		EndIf;
		If Object.ThisIsAnIBAN Then
			CheckIBAN(ThisObject)
		EndIf;
	EndIf;

	GenerateAutoName(ThisObject);
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));

EndProcedure

&AtServer
Procedure IdentifyCountryAndBankByIBAN()
	
	CountryCode = CashClientServer.CountryCodeIBAN(Object.AccountNumber);
	Country = CashServer.Country(CountryCode);
	If ValueIsFilled(Country) Then
		CountryOfBank = Country;
		Object.CountryOfBank = Country;
		NationalBankCode = CashServer.NationalBankCode(Object.AccountNumber);
		FoundBank = CashServer.Bank(Country, NationalBankCode);
		If ValueIsFilled(FoundBank) Then
			Object.Bank = FoundBank;
			Object.ManualBankDetailsChange = False;
			BankIndicationMethod = "SelectionFromCatalog";
			FillInBankDetailsByBank("Bank", Object.Bank);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure CashCurrencyOnChangeServer()
	
	GenerateAutoName(ThisObject);
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangeBankDetails()
	
	FormAttributes = FormAttributes(ThisObject);
	If Object.ManualBankDetailsChange Then
		Items.Bank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
									|ru = '<реквизиты банка введены вручную>';
									|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
									|it = '<requisiti bancari inseriti manualmente>';
									|pl = '<dane banku zostały wprowadzone ręcznie>';
									|tr = '<banka bilgileri manuel olarak girildi>'");
		Object.Bank = Undefined;
	Else
		Items.Bank.InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsWhenChangingOnServer();
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	CustomizeFormElements(ThisObject, , FormAttributes);
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsWhenChangingOnServer()
	
	If Object.ManualBankDetailsChange Then
		FillInBankDetailsByBank("Bank", Catalogs.BankClassifier.EmptyRef(), True);
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	
	If Not Object.ManualBankDetailsChange Then
		FillInBankDetailsForBIC("Bank", BankBIC, True)
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingBank()
	
	Items.GroupErrorInAccountNumber.Visible = False;
	Items.Bank.InputHint = "";
	If ValueIsFilled(Object.Bank) Then
		Object.ManualBankDetailsChange = False;
		BankIndicationMethod = "SelectionFromCatalog";
		FillInBankDetailsByBank("Bank", Object.Bank, True);
	Else
		Object.ManualBankDetailsChange = True;
		BankIndicationMethod = "ManualFillingInOfBankingDetails";
		FillInBankDetailsByBank("Bank", PredefinedValue("Catalog.BankClassifier.EmptyRef"), True);
	EndIf;
	
	
	If Object.ThisIsAnIBAN Then
		CheckIBAN(ThisObject)
	EndIf;
	
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	
	If ValueIsFilled(Object.Bank) Then
		CashClientServer.FillInMainBankDetails(ThisObject);
	Else
		TitlePageBank = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
							|ru = 'Ввести реквизиты банка вручную...';
							|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
							|it = 'Inserire i requisiti bancari manualmente...';
							|pl = 'Wpisz dane banku ręcznie...';
							|tr = 'Banka bilgilerini manuel olarak gir...'");
	EndIf;
	
EndProcedure

&AtServer
Procedure OwnerOnChangeServer()
	
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
EndProcedure

&AtServer
Function FillInBankDetailsForBIC(BankType, Val BIC = "", TransferBankingDetailsValues = False)
	
	FoundByBIC   = False;
	RecordAboutBank = Undefined;
	
	AttributesNames = CashClientServer.BankingDetails(True, BankType <> "Bank");
	CashClientServer.ClearBankDetailsOnForm(ThisObject, AttributesNames);
	
	If ValueIsFilled(BIC) Then
		
		BankManager.GetClassifierData(BIC,, RecordAboutBank);
		
		If ValueIsFilled(RecordAboutBank) Then
			FillInBankDetailsByBank(BankType, RecordAboutBank, TransferBankingDetailsValues);
			Object[BankType] = RecordAboutBank;
			FoundByBIC = True;
		EndIf;
	EndIf;
	
	Return FoundByBIC;
	
EndFunction

&AtServer
Procedure FillInBankDetailsByBank(BankType, Bank = "", TransferBankingDetailsValues = False)
	
	ComplianceWithBankDetails = CashServer.AccountDetailsByBankClassifier();
	
	If BankType = "Bank" Then
		
		AttributesStructure1 = New Structure;
		AttributesNames = StrSplit(CashClientServer.BankingDetails(), ",", False);
		For Each AttributeName In AttributesNames Do
			AttributesStructure1.Insert(AttributeName, ComplianceWithBankDetails[TrimAll(AttributeName)]);
		EndDo;
		AttributesStructure1.Insert("BankBIC", "Code");
		AttributesStructure1.Insert("BankSWIFTCode", "SWIFTBIC");
		AttributesStructure1.Insert("BankNameInt", "InternationalDescription");
		
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		CountryOfBank = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		
		If TransferBankingDetailsValues Then
			FillPropertyValues(Object, BankingDetails);
			Object.CountryOfBank = CountryOfBank;
			Object.Bank = Undefined;
		EndIf;
		
		Object.BankAccountForPayments = BankingDetails.BankCorrAccount;
		
	ElsIf BankType = "TransferBank" Then
		
		AttributesStructure1 = New Structure;
		AttributesNames = StrSplit(CashClientServer.BankingDetails(, True), ",", False);
		For Each AttributeName In AttributesNames Do
			AttributesStructure1.Insert(AttributeName, ComplianceWithBankDetails[TrimAll(AttributeName)]);
		EndDo;
		AttributesStructure1.Insert("TransferBankBIC", "Code");
		AttributesStructure1.Insert("BankSWIFTCodeForPayments", "SWIFTBIC");
		AttributesStructure1.Insert("BankNameForPaymentsInt", "InternationalDescription");
		
		BankingDetails = CashServer.BankAttributes(Bank, AttributesStructure1);
		
		FillPropertyValues(ThisObject, BankingDetails);
		
		CountryOfBankForPayments = CashServer.BankCountryByCode(BankingDetails.CountryCode);
		
		If TransferBankingDetailsValues Then
			FillPropertyValues(Object, BankingDetails);
			Object.CountryOfBankForPayments = CountryOfBankForPayments;
			Object.TransferBank = Undefined;
		EndIf;
		
		CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
		
	EndIf;
	
	GenerateAutoName(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeFormElements(Form, ChangedProps = "", AdditionalAttributes = Undefined)
	
	CashClientServer.CustomizeFormElements(Form, ChangedProps, AdditionalAttributes);
	
	If Not ValueIsFilled(ChangedProps) Then
		CommonClientServer.SetFormItemProperty(Form.Items,
			"CorrespondentBankAccountInternational", "Visible",
			Not Form.Items.BankGroup1.Visible And Form.Items.BankCorrAccount.Visible);
		CommonClientServer.SetFormItemProperty(Form.Items,
			"CorrespondentAccountOfBankInternationalByReference", "Visible",
			Not Form.Items.BankGroupByLink.Visible And Form.Items.CorrespondentBankAccountAtLink.Visible);
		CommonClientServer.SetFormItemProperty(Form.Items,
			"BankAccountForSettlementsInternational", "Visible",
			Not Form.Items.BankGroup1.Visible And Form.Items.BankAccountForPayments.Visible);
	EndIf;

	If Form.Object.ManualBankDetailsChange Then
		Form.Items.BankDetailsPages.CurrentPage = Form.Items.ManualBankDetails;
	Else
		Form.Items.BankDetailsPages.CurrentPage = Form.Items.BankDetailsByLink;
	EndIf;
	
	If Form.Object.TransferBankDetailsManualEdit Then
		Form.Items.PagesOfBankDetailsForSettlements.CurrentPage = Form.Items.ManualBankDetailsForSettlements;
	Else
		Form.Items.PagesOfBankDetailsForSettlements.CurrentPage = Form.Items.BankDetailsForPaymentsViaLink;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FormFieldSettings = Catalogs.CounterpartyBankAccounts.FormFieldSettings();
	ValueToFormAttribute(FormFieldSettings, "FieldSettings");
	DependenciesOfFormFields = CashServer.DependenciesOfFormFields(FormFieldSettings);
	ValueToFormAttribute(DependenciesOfFormFields, "FieldDependencies");
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	InternationalBankAccountDetails = GetFunctionalOption("InternationalBankAccountDetails");
	NationalBankAccountDetails = GetFunctionalOption("NationalBankAccountDetails");
	
	ReadPersons = AccessRight("Read", Metadata.Catalogs.Persons);
	
	CurrencyOfComplianceAccounting = SettingsValueCached.DefaultBaseCurrency();
	CurrencyAccount = (ValueIsFilled(Object.CashCurrency) And Object.CashCurrency <> CurrencyOfComplianceAccounting);
	
	AccountNumber = Object.AccountNumber;
	
	If ValueIsFilled(Object.Ref) Or ValueIsFilled(Parameters.CopyingValue) Then
		If InternationalBankAccountDetails And Object.ThisIsAnIBAN Then
			CheckIBAN(ThisObject);
		EndIf;
		If Object.ManualBankDetailsChange Then
			Items.Bank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
										|ru = '<реквизиты банка введены вручную>';
										|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
										|it = '<requisiti bancari inseriti manualmente>';
										|pl = '<dane banku zostały wprowadzone ręcznie>';
										|tr = '<banka bilgileri manuel olarak girildi>'");
		EndIf;
		If Object.TransferBankDetailsManualEdit Then
			Items.TransferBank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
												|ru = '<реквизиты банка введены вручную>';
												|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
												|it = '<requisiti bancari inseriti manualmente>';
												|pl = '<dane banku zostały wprowadzone ręcznie>';
												|tr = '<banka bilgileri manuel olarak girildi>'");
		EndIf;
	Else
		If InternationalBankAccountDetails Then
			Object.ForeignBank = True;
		Else
			Object.CountryOfBank = MainCountry;
		EndIf;
		If Not ValueIsFilled(Object.Bank) Then
			Object.ManualBankDetailsChange = True;
		EndIf;
		If Not ValueIsFilled(Object.TransferBankAddress) Then
			Object.TransferBankDetailsManualEdit = True;
		EndIf;
	EndIf;
	
	BankIndicationMethod = ?(Object.ManualBankDetailsChange, "ManualFillingInOfBankingDetails", "SelectionFromCatalog");
	MethodOfSpecifyingBankForSettlements = ?(Object.TransferBankDetailsManualEdit, "ManualFillingInOfBankingDetails",
										"SelectionFromCatalog");
	
	FillInBankDetails();
	GenerateAutoName(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
	CashClientServer.FillInMainBankDetails(ThisObject);
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInBankDetails()
	
	BankNameInt = Object.BankNameInt;
	BankNameForPaymentsInt = Object.BankNameForPaymentsInt;
	
	If Object.ManualBankDetailsChange Then
		FillPropertyValues(ThisObject, Object, CashClientServer.BankingDetails(True));
	Else
		If Not Object.Bank.IsEmpty() Then
			FillInBankDetailsByBank("Bank", Object.Bank, False);
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.Ref) Then
		If ValueIsFilled(Object.TransferBank)
			Or ValueIsFilled(Object.TransferBankBIC)
			Or ValueIsFilled(Object.BankSWIFTCodeForPayments) Then
			SettlementBankUsed = True;
		Else
			SettlementBankUsed = False;
		EndIf;
	EndIf;
	
	If Object.TransferBankDetailsManualEdit Then
		FillPropertyValues(ThisObject, Object, CashClientServer.BankingDetails(True, True));
	Else
		If Not Object.TransferBank.IsEmpty() Then
			FillInBankDetailsByBank("TransferBank", Object.TransferBank, False);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function GenerateAutoName(Form)
	
	Form.Items.Description.ChoiceList.Clear();
	
	If Form.Object.ManualBankDetailsChange Then
		
		If ValueIsFilled(Form.BankDescription) Then
			DescriptionTemplate = NStr("vi = '%1 trong %2, (%3)';
										|ru = '%1 в %2 (%3)';
										|en = '%1 in %2 (%3)'; fa = '%1 in %2 (%3)';
										|it = '%1 in %2 (%3)';
										|pl = '%1 w %2 (%3)';
										|tr = '%2''de %1 (%3)'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.BankDescription), String(Form.Object.CashCurrency));
		Else
			DescriptionTemplate = NStr("vi = '%1 (%2)';
										|ru = '%1 (%2)';
										|en = '%1 (%2)'; fa = '%1 (%2)';
										|it = '%1 (%2)';
										|pl = '%1 (%2)';
										|tr = '%1 (%2)'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.Object.CashCurrency));
		EndIf;
		
		NameString_ = Left(NameString_, 150);
		Form.Items.Description.ChoiceList.Add(NameString_);
		
		NameString_ = ?(ValueIsFilled(Form.BankDescription), String(Form.BankDescription), "")
			+ " (" + String(Form.Object.CashCurrency) + ")";
		NameString_ = Left(NameString_, 150);
		Form.Items.Description.ChoiceList.Add(NameString_);
	Else
		
		If ValueIsFilled(Form.Object.Bank) Then
			DescriptionTemplate = NStr("vi = '%1 trong %2, (%3)';
										|ru = '%1 в %2 (%3)';
										|en = '%1 in %2 (%3)'; fa = '%1 in %2 (%3)';
										|it = '%1 in %2 (%3)';
										|pl = '%1 w %2 (%3)';
										|tr = '%2''de %1 (%3)'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.Object.Bank), String(Form.Object.CashCurrency));
		Else
			DescriptionTemplate = NStr("vi = '%1 (%2)';
										|ru = '%1 (%2)';
										|en = '%1 (%2)'; fa = '%1 (%2)';
										|it = '%1 (%2)';
										|pl = '%1 (%2)';
										|tr = '%1 (%2)'");
			NameString_ = StrTemplate(DescriptionTemplate, Right(TrimAll(Form.Object.AccountNumber), 4),
				String(Form.Object.CashCurrency));
		EndIf;
		
		NameString_ = Left(NameString_, 150);
		Form.Items.Description.ChoiceList.Add(NameString_);
		
		NameString_ = ?(ValueIsFilled(Form.Object.Bank), String(Form.Object.Bank), "")
			+ " (" + String(Form.Object.CashCurrency) + ")";
		NameString_ = Left(NameString_, 150);
		Form.Items.Description.ChoiceList.Add(NameString_);
	EndIf;
	
	Return NameString_;
	
EndFunction

&AtClient
Procedure ConfigureDependentFormElements(ChangedProps = "")
	
	CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedProps = "")
	
	CustomizeFormElements(ThisObject, ChangedProps, FormAttributes(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Function FormAttributes(Form)
	
	FormAttributes = New Structure;
	FormAttributes.Insert("PaymentSupport275FZ");
	FormAttributes.Insert("UseCurrencyPayments");
	FormAttributes.Insert("UseMultipleCurrencies");
	FormAttributes.Insert("SettlementBankUsed");
	FormAttributes.Insert("CurrencyAccount");
	FormAttributes.Insert("UseCorrespondentText");
	FormAttributes.Insert("UseOfIncorrespondent");
	FormAttributes.Insert("UseAPPCReporter");
	FormAttributes.Insert("TheAccountOfPhysicalPerson");
	FormAttributes.Insert("CounterpartyIndividual");
	FormAttributes.Insert("InternationalBankAccountDetails");
	FormAttributes.Insert("NationalBankAccountDetails");
	
	FillPropertyValues(FormAttributes, Form);
	
	Return FormAttributes;
	
EndFunction

&AtClient
Procedure WhenChangingBankForSettlements()
	
	Items.TransferBank.InputHint = "";
	If ValueIsFilled(Object.TransferBank) Then
		Object.TransferBankDetailsManualEdit = False;
		MethodOfSpecifyingBankForSettlements = "SelectionFromCatalog";
		FillInBankDetailsByBank("TransferBank", Object.TransferBank, True);
		CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	Else
		TitleBankPageForSettlements = NStr("vi = 'Nhập thông tin ngân hàng thủ công...';
											|ru = 'Ввести реквизиты банка вручную...';
											|en = 'Enter the bank details manually...'; fa = 'Enter the bank details manually...';
											|it = 'Inserire i requisiti bancari manualmente...';
											|pl = 'Wpisz dane banku ręcznie...';
											|tr = 'Banka bilgilerini manuel olarak gir...'")
	EndIf;
	
	CustomizeFormElements(ThisObject, , FormAttributes(ThisObject));
	
EndProcedure

&AtClient
Procedure WhenChangingManuallyChangingBankDetailsForSettlements()
	
	FormAttributes = FormAttributes(ThisObject);
	If Object.TransferBankDetailsManualEdit Then
		Items.TransferBank.InputHint = NStr("vi = '<thông tin ngân hàng được nhập thủ công>';
											|ru = '<реквизиты банка введены вручную>';
											|en = '<the bank details are entered manually>'; fa = '<the bank details are entered manually>';
											|it = '<requisiti bancari inseriti manualmente>';
											|pl = '<dane banku zostały wprowadzone ręcznie>';
											|tr = '<banka bilgileri manuel olarak girildi>'");
		Object.TransferBank = Undefined;
	Else
		Items.TransferBank.InputHint = "";
	EndIf;

	ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer();
	
	CashClientServer.FillInMainBankDetailsForSettlements(ThisObject);
	CustomizeFormElements(ThisObject, , FormAttributes);
	
EndProcedure

&AtServer
Procedure ManualChangeOfBankDetailsForSettlementsWhenChangingOnServer()
	
	If Not Object.TransferBankDetailsManualEdit Then
		FillInBankDetailsForBIC("TransferBank", TransferBankBIC, True)
	EndIf;
	
	If Not Object.TransferBank.IsEmpty() Then
		FillInBankDetailsByBank("TransferBank", Object.TransferBank);
	EndIf;
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

