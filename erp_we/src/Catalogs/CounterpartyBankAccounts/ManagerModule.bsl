#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function determines the Bank account of the selected counterparty or individual.
//
// Returns the recipient's Bank account if one Bank account is found.
// Returns Undefined if the Bank account is not found or there are more than one accounts.
//
// Parameters:
//	Recipient - CatalogRef.Counterparties, CatalogRef.Persons - Link to the recipient
//	Currency - CatalogRef.Currencies - Bank Account Currency
//	OffsettingAccount - CatalogRef.CompaniesBankAccounts - the invoice that the received invoice corresponds to.
//	ExcludeAccountsInTransferredCurrency - Boolean - if True, the accounts in the currency passed in the Currency parameter will be excluded.
//
// Returns:
//	CatalogRef.CounterpartyBankAccounts - The recipient's bank account found.
//
Function GetDefaultBankAccount(Recipient, Currency = Undefined, OffsettingAccount = Undefined,
	ExcludeAccountsInTransferredCurrency = False) Export
	
	CorrespondenceWithDigitalRubleAccount = Undefined;
	
	
	QueryText =
	"SELECT TOP 2
	|	CounterpartyBankAccounts.Ref AS BankAccountOfBeneficiary
	|FROM
	|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|WHERE
	|	NOT CounterpartyBankAccounts.DeletionMark
	|	AND NOT CounterpartyBankAccounts.Closed
	|	AND CounterpartyBankAccounts.Owner = &Recipient
	|	AND &ConditionByCurrency
	|	AND (CounterpartyBankAccounts.DigitalRoubleAccount = &CorrespondenceWithDigitalRubleAccount
	|		OR &CorrespondenceWithDigitalRubleAccount = UNDEFINED)";
	
	If Not ExcludeAccountsInTransferredCurrency Then
		ConditionByCurrency = "(CounterpartyBankAccounts.CashCurrency = &Currency
						|		OR &Currency = UNDEFINED)";
	Else
		ConditionByCurrency = "(CounterpartyBankAccounts.CashCurrency <> &Currency
						|		OR &Currency = UNDEFINED)";
	EndIf;
	
	Query = New Query;
	Query.Text = StrReplace(QueryText, "&ConditionByCurrency", ConditionByCurrency);
	
	Query.SetParameter("Recipient", Recipient);
	Query.SetParameter("Currency", ?(ValueIsFilled(Currency), Currency, Undefined));
	Query.SetParameter("CorrespondenceWithDigitalRubleAccount", 
		?(ValueIsFilled(CorrespondenceWithDigitalRubleAccount), CorrespondenceWithDigitalRubleAccount, Undefined));
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 
	   And Selection.Next()
	Then
		BankAccountOfBeneficiary = Selection.BankAccountOfBeneficiary;
	Else
		BankAccountOfBeneficiary = Catalogs.CounterpartyBankAccounts.EmptyRef();
	EndIf;
	
	Return BankAccountOfBeneficiary;

EndFunction

// This function checks whether the Bank account holder matches the selected counterparty or individual.
//
// Parameters:
//  BankAccount - CatalogRef.CounterpartyBankAccounts - Link to Bank account
//  Owner - CatalogRef.Counterparties, CatalogRef.Persons - Link to the owner.
//
// Returns:
//	Boolean - A sign that the bank account belongs to the specified owner.
//
Function VerifyBankAccountHolder(BankAccount, Owner) Export
	
	If Not ValueIsFilled(BankAccount) Then
		Return False;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	CounterpartyBankAccounts.Ref AS BankAccountOfBeneficiary
	|FROM
	|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|WHERE
	|	CounterpartyBankAccounts.Ref = &BankAccount
	|	AND CounterpartyBankAccounts.Owner = &Owner
	|");
	
	Query.SetParameter("BankAccount", BankAccount);
	Query.SetParameter("Owner", Owner);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		AccountCorrespondsToOwner = False;
	Else
		AccountCorrespondsToOwner = True;
	EndIf;
	
	Return AccountCorrespondsToOwner;

EndFunction

// The function gets Bank account details.
//
// Parameters:
//  BankAccount - CatalogRef.CounterpartyBankAccounts - link to the bank account.
//
// Returns:
//	Structure - Attributes of the counterparty's bank account:
//	*Currency - CatalogRef.Currencies - The currency of the bank account.
//	*PurposeText - String - purpose of payment on the invoice.
//	*AccountNumber - String - Bank account number.
//	*Bank - CatalogRef.BankClassifier, String, Undefined - the bank of the bank account.
//	*BIC - String - The bank's BIC of the bank account.
//	*CorrAccount - String - correspondence account.
//	*BankAddress - String - bank address in the bank account.
//	*CASHSETTLEMENTCENTERBIC - CatalogRef.BankClassifier, Undefined - BIC of the cash settlement center.
//	*DigitalRoubleAccount - Boolean - digital ruble account attribute.
//	*DigitalRoubleAccountID - String - ID of the digital ruble account.
//
Function GetBankAccountDetails(BankAccount) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	BankAccounts.CashCurrency AS Currency,
	|	BankAccounts.PurposeText AS PurposeText,
	|	BankAccounts.AccountNumber AS AccountNumber,
	|	BankAccounts.DigitalRoubleAccount AS DigitalRoubleAccount,
	|	BankAccounts.DigitalRoubleAccountID AS DigitalRoubleAccountID,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankDescription
	|		ELSE BankAccounts.Bank
	|	END AS Bank,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankBIC
	|		ELSE BankAccounts.Bank.Code
	|	END AS BIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCorrAccount
	|		ELSE BankAccounts.Bank.CorrAccount
	|	END AS CorrAccount,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankAddress
	|		ELSE BankAccounts.Bank.Address
	|	END AS BankAddress,
	|	BankAccounts.Bank.CashSettlementCenterBIC AS CashSettlementCenterBIC
	|FROM
	|	Catalog.CounterpartyBankAccounts AS BankAccounts
	|WHERE
	|	BankAccounts.Ref = &BankAccount";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Currency 			= Selection.Currency;
		PurposeText = Selection.PurposeText;
		AccountNumber 		= Selection.AccountNumber;
		Bank 			= Selection.Bank;
		BIC 			= Selection.BIC;
		CorrAccount 		= Selection.CorrAccount;
		BankAddress 		= Selection.BankAddress;
		CashSettlementCenterBIC 			= Selection.CashSettlementCenterBIC;
		DigitalRoubleAccount               = Selection.DigitalRoubleAccount;
		DigitalRoubleAccountID = Selection.DigitalRoubleAccountID;
	Else
		Currency 			= Catalogs.Currencies.EmptyRef();
		PurposeText = "";
		AccountNumber 		= "";
		Bank 			= Undefined;
		BIC 			= "";
		CorrAccount 		= "";
		BankAddress 		= "";
		CashSettlementCenterBIC 			= Selection.CashSettlementCenterBIC;
		DigitalRoubleAccount = False;
		DigitalRoubleAccountID = "";
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("PurposeText", PurposeText);
	AttributesStructure1.Insert("AccountNumber", AccountNumber);
	AttributesStructure1.Insert("Bank", Bank);
	AttributesStructure1.Insert("BIC", BIC);
	AttributesStructure1.Insert("CorrAccount", CorrAccount);
	AttributesStructure1.Insert("BankAddress", BankAddress);
	AttributesStructure1.Insert("CASHSETTLEMENTCENTERBIC", CashSettlementCenterBIC);
	AttributesStructure1.Insert("DigitalRoubleAccount", DigitalRoubleAccount);
	AttributesStructure1.Insert("DigitalRoubleAccountID", DigitalRoubleAccountID);
	
	Return AttributesStructure1;

EndFunction

// Defines the properties of form fields depending on the data
// 
// Returns:
//  See CashServer.InitializeFormFieldSettings.
//
Function FormFieldSettings() Export
	
	Finances = FinancialReportingServer;
	Settings = CashServer.InitializeFormFieldSettings();
	
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.TheAccountOfPhysicalPerson", True);
	Item.Properties.Insert("Title", NStr("vi = 'Cá nhân';
										|ru = 'Физическое лицо';
										|en = 'Person'; fa = 'شخص';
										|it = 'Persona fisica';
										|pl = 'Osoba fizyczna';
										|tr = 'Gerçek kişi'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.TheAccountOfPhysicalPerson", False);
	Item.Properties.Insert("Title", NStr("vi = 'Đối tác';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Controparte';
										|pl = 'Counterparty';
										|tr = 'Cari hesap'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CorrespondentText");
	Finances.NewFilter(Item.Condition, "More.UseCorrespondentText", True);
	Item.Properties.Insert("Enabled");
	
	CashServer.ElementSettings(Settings);
	
	Return Settings;
	
EndFunction

// Defines the properties of form fields depending on the data
// 
// Returns:
//  See CashServer.InitializeFormFieldSettings.
//
Function FieldSettingsOfDigitalRubleInvoiceForm() Export
	
	Finances = FinancialReportingServer;
	Settings = CashServer.InitializeFormFieldSettings();
	
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.TheAccountOfPhysicalPerson", True);
	Item.Properties.Insert("Title", NStr("vi = 'Физическое лицо';
										|ru = 'Физическое лицо';
										|en = 'Person'; fa = 'شخص';
										|it = 'Физическое лицо';
										|pl = 'Osoba fizyczna';
										|tr = 'Физическое лицо'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.TheAccountOfPhysicalPerson", False);
	Item.Properties.Insert("Title", NStr("vi = 'Контрагент';
										|ru = 'Контрагент';
										|en = 'Counterparty'; fa = 'طرف حساب';
										|it = 'Контрагент';
										|pl = 'Counterparty';
										|tr = 'Контрагент'"));
	
	Item = Settings.Add();
	Item.Fields.Add("CorrespondentText");
	Finances.NewFilter(Item.Condition, "More.UseCorrespondentText", True);
	Item.Properties.Insert("Enabled");
	
	// General item settings
	Item = Settings.Add();
	Item.Fields.Add("BankBIC");
	Item.Fields.Add("BicOfBankAtLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Item.Properties.Insert("Title", NStr("vi = 'БИК';
										|ru = 'БИК';
										|en = 'BIC'; fa = 'BIC';
										|it = 'БИК';
										|pl = 'BIC';
										|tr = 'БИК'"));
	
	Item = Settings.Add();
	Item.Fields.Add("BankCountryInternational");
	Item.Fields.Add("BankCountryInternationalByReference");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible", False);
	
	Item = Settings.Add();
	Item.Fields.Add("BankGroup1");
	Item.Fields.Add("BankGroupByLink");
	Finances.NewFilter(Item.Condition, "More.InternationalBankAccountDetails", False);
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("ShowTitle", False);
	
	Item = Settings.Add();
	Item.Fields.Add("BankGroup1");
	Item.Fields.Add("BankGroupByLink");
	Finances.NewFilter(Item.Condition, "More.NationalBankAccountDetails", True);
	Item.Properties.Insert("Visible");
	
	// Printing payment orders
	Item = Settings.Add();
	Item.Fields.Add("CorrespondentTIN");
	Finances.NewFilter(Item.Condition, "More.UseOfIncorrespondent", True);
	Item.Properties.Insert("Enabled");
	
	Item = Settings.Add();
	Item.Fields.Add("CorrespondentCRTR");
	Finances.NewFilter(Item.Condition, "More.UseAPPCReporter", True);
	Item.Properties.Insert("Enabled");
	
	Return Settings;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AttachAdditionalTables
	|ThisList AS T
	|LEFT JOIN InformationRegister.PartnerHierarchy AS T2 
	|	ON T2.Parent = T.Owner.Partner
	|;
	|AllowRead
	|WHERE
	|	( VALUETYPE(T.Owner) = TYPE(Catalog.Counterparties)
	|	AND ValueAllowed(T2.Partner)
	|	)OR( VALUETYPE(T.Owner) = TYPE(Catalog.Persons)
	|	AND ObjectReadingAllowed(T.Owner)
	|	AND ValueAllowed(T.Owner)
	|	) 
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	( VALUETYPE(Owner) = TYPE(Catalog.Counterparties)
	|	AND ValueAllowed(Owner.Partner)
	|	)OR( VALUETYPE(Owner) = TYPE(Catalog.Persons)
	|	AND( ObjectUpdateAllowed(Owner)
	|	))";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN InformationRegister.PartnerHierarchy AS PartnerHierarchy 
	|	ON PartnerHierarchy.Parent = ThisList.Owner.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = PartnerHierarchy.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners 
	|	ON ContactPersonsForPartners.Owner = ThisList.Owner.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons 
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure
// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	NewTeam = PrintCommands.Add();
	NewTeam.Id = "BankAccountDetails";
	NewTeam.Presentation = NStr("vi = 'Thông tin';
								|ru = 'Реквизиты';
								|en = 'Attributes'; fa = 'ویژگی‌ها';
								|it = 'Requisiti';
								|pl = 'Attributes';
								|tr = 'Öznitelikler'");
	NewTeam.FormCaption = NStr("vi = 'In thông tin tài khoản ngân hàng';
								|ru = 'Печать реквизитов банковского счета';
								|en = 'Print bank account details'; fa = 'Print bank account details';
								|it = 'Stampare requisiti conto corrente';
								|pl = 'Drukowanie danych rachunku bankowego';
								|tr = 'Banka hesabı bilgilerini yazdır'");
	
EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "BankAccountDetails") Then
		PrintForm = PrintManagement.PrintFormInfo(PrintFormsCollection, "BankAccountDetails");
		If PrintForm <> Undefined Then
			PrintForm.SpreadsheetDocument = PrintingAccountDetails(ObjectsArray, PrintObjects);
			PrintForm.TemplateSynonym = NStr("vi = 'Thông tin tài khoản ngân hàng';
											|ru = 'Реквизиты банковского счета';
											|en = 'Bank account details'; fa = 'Bank account details';
											|it = 'Requisiti conto corrente';
											|pl = 'Dane rachunku bankowego';
											|tr = 'Banka hesabı bilgileri'");
			PrintForm.FullTemplatePath = "CommonTemplate.PF_MXL_AccountAttributes";
		EndIf;
	EndIf;

EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#Region InfobaseUpdate

// See InfobaseUpdate.DataUpdatedForNewApplicationVersion.
Function DataUpdatedForNewApplicationVersion(MetadataAndFilter) Export
	
	Return InfobaseUpdate.DataUpdatedForNewApplicationVersion(MetadataAndFilter);
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Not FormType = "ItemForm"
		And Not FormType = "ObjectForm" Then
		Return;
	EndIf;
	
	Value = CommonClientServer.StructureProperty(Parameters, "Key");
	
	// Copy check
	If Value = Undefined Then
		Value = CommonClientServer.StructureProperty(Parameters, "CopyingValue");
	EndIf;
		
	If Value = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	If Value.DigitalRoubleAccount Then
		SelectedForm = "FormOfDigitalRubleInvoiceElement";
	Else
		SelectedForm = "ItemForm";
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("CashCurrency");
	Result.Add("Owner");
	Result.Add("ForeignBank; ForeignBank");
	Result.Add("SeparateSDOAccount");
	Result.Add("StateContract");
	
	Return Result;
	
EndFunction

Function PrintingAccountDetails(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_BankAccountDetailsCounterparty_";
	
	Template = PrintManagement.PrintFormTemplate("CommonTemplates.PF_MXL_AccountAttributes");
	
	Query = New Query;
	Query.Text = QueryTextSeals();
	Query.SetParameter("ReferencesArrray", ObjectsArray);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	TheFirstControl = True;
	
	While Selection.Next() Do
		
		Template = PrintManagement.PrintFormTemplate("CommonTemplates.PF_MXL_AccountAttributes");
		
		If TheFirstControl Then
			TheFirstControl = False;
		Else
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;

		If Selection.ThisIsAnIBAN Then
			WithdrawIBANDetails(Selection, Template, SpreadsheetDocument);
		Else
			WithdrawBankingDetails(Selection, Template, SpreadsheetDocument);
		EndIf;
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Procedure WithdrawBankingDetails(Selection, Template, SpreadsheetDocument)
	
	Area = Template.GetArea("Header");
	SpreadsheetDocument.Put(Area);
	
	NationalBankAccountDetails = GetFunctionalOption("NationalBankAccountDetails");
	InternationalBankAccountDetails = GetFunctionalOption("InternationalBankAccountDetails");
	
	If ValueIsFilled(Selection.TransferBank)
		Or ValueIsFilled(Selection.TransferBankBIC)
		Or ValueIsFilled(Selection.BankSWIFTCodeForPayments) Then
		SettlementBankUsed = True;
	Else
		SettlementBankUsed = False;
	EndIf;

	If NationalBankAccountDetails Then
		FillInNationalDetails(SettlementBankUsed, Template, Selection, SpreadsheetDocument);
	EndIf;
	
	If InternationalBankAccountDetails Then
		FillInInternationalDetails(SettlementBankUsed, Template, Selection, SpreadsheetDocument);
	EndIf;
	
EndProcedure

Procedure FillInInternationalDetails(SettlementBankUsed, Template, Selection, SpreadsheetDocument)
	
	If SettlementBankUsed Then
		Area = Template.GetArea("InternationalAndIndirectSettlements");
	Else
		If Selection.DigitalRoubleAccount Then
			Area = Template.GetArea("InternationalAttributes_DigitalRubleAccount");
		Else
			Area = Template.GetArea("InternationalDetails");
		EndIf;
	EndIf;
	
	FillPropertyValues(Area.Parameters, Selection);
	
	AddressParts = New Array;
	If Selection.ManualBankDetailsChange Then
		Bank = Selection.BankNameInt;
		SWIFT = Selection.BankSWIFTCode;
		If ValueIsFilled(Selection.CountryOfBankInternationalName) Then
			AddressParts.Add(Selection.CountryOfBankInternationalName);
		EndIf;
		If ValueIsFilled(Selection.BankCityInt) Then
			AddressParts.Add(Selection.BankCityInt);
		EndIf;
		If ValueIsFilled(Selection.BankAddressInt) Then
			AddressParts.Add(Selection.BankAddressInt);
		EndIf;
	Else
		Bank = Selection.BankInternationalName;
		SWIFT = Selection.SWIFTBIKBank;
		If ValueIsFilled(Selection.BankCountryInternationalName) Then
			AddressParts.Add(Selection.BankCountryInternationalName);
		EndIf;
		If ValueIsFilled(Selection.BankGorodInternational) Then
			AddressParts.Add(Selection.BankGorodInternational);
		EndIf;
		If ValueIsFilled(Selection.BankAddressInternational) Then
			AddressParts.Add(Selection.BankAddressInternational);
		EndIf;
	EndIf;
	Area.Parameters.InternationalNameOfBank = Bank;
	Area.Parameters.SWIFT = SWIFT;
	Area.Parameters.BankAddressInt = StrConcat(AddressParts, " ,");
	
	If SettlementBankUsed Then
		AddressParts = New Array;
		If Selection.TransferBankDetailsManualEdit Then
			TransferBank = Selection.BankNameForPaymentsInt;
			SWIFTBankForSettlements = Selection.BankSWIFTCodeForPayments;
			If ValueIsFilled(Selection.CountryOfBankForSettlementInternationalName) Then
				AddressParts.Add(Selection.CountryOfBankForSettlementInternationalName);
			EndIf;
			If ValueIsFilled(Selection.BankCityForPaymentsInt) Then
				AddressParts.Add(Selection.BankCityForPaymentsInt);
			EndIf;
			If ValueIsFilled(Selection.BankAddressForPaymentInt) Then
				AddressParts.Add(Selection.BankAddressForPaymentInt);
			EndIf;
		Else
			TransferBank = Selection.BankForSettlementsInternationalName;
			SWIFTBankForSettlements = Selection.SWIFTBIKSettlementBank;
			If ValueIsFilled(Selection.SettlementBankCountryInternationalName) Then
				AddressParts.Add(Selection.SettlementBankCountryInternationalName);
			EndIf;
			If ValueIsFilled(Selection.BankForSettlementsCityInternational) Then
				AddressParts.Add(Selection.BankForSettlementsCityInternational);
			EndIf;
			If ValueIsFilled(Selection.BankForSettlementsAddressInternational) Then
				AddressParts.Add(Selection.BankForSettlementsAddressInternational);
			EndIf;
		EndIf;
		Area.Parameters.InternationalSettlementBank = TransferBank;
		Area.Parameters.SWIFTBankForSettlements = SWIFTBankForSettlements;
		Area.Parameters.BankAddressForPaymentInt = StrConcat(AddressParts, " ,");
	EndIf;
	
	SpreadsheetDocument.Put(Area);

EndProcedure

Procedure FillInNationalDetails(SettlementBankUsed, Template, Selection, SpreadsheetDocument)

	If SettlementBankUsed Then
		Area = Template.GetArea("NationalAndIndirectCalculations");
	Else
		If Selection.DigitalRoubleAccount Then
			Area = Template.GetArea("NationalAttributes_DigitalRubleAccount");
		Else
			Area = Template.GetArea("NationalProps");
		EndIf;
	EndIf;
	
	FillPropertyValues(Area.Parameters, Selection);
	
	If ValueIsFilled(Selection.CorrespondentText) Then
		Recipient = Selection.CorrespondentText
	Else
		Recipient = Selection.OwnerFullName;
	EndIf;
	Area.Parameters.Recipient = Recipient;
	
	If ValueIsFilled(Selection.CorrespondentTIN) Then
		TIN = Selection.CorrespondentTIN
	Else
		TIN = Selection.TIN;
	EndIf;
	Area.Parameters.TIN = TIN;
	
	If Selection.ManualBankDetailsChange Then
		Bank = Selection.BankDescription;
		BIC = Selection.BankBIC
	Else
		Bank = Selection.BankName;
		BIC = Selection.Bank_Code
	EndIf;
	Area.Parameters.Bank = Bank;
	Area.Parameters.BIC = BIC;
	
	If SettlementBankUsed Then
		If Selection.TransferBankDetailsManualEdit Then
			TransferBank = Selection.TransferBankDescription;
			TransferBankBIC = Selection.TransferBankBIC
		Else
			TransferBank = Selection.BankForSettlementsName;
			TransferBankBIC = Selection.BankForSettlementsCode
		EndIf;
		Area.Parameters.CorrespondentBank = TransferBank;
		Area.Parameters.BicOfCorrespondentBank = TransferBankBIC;
	EndIf;
	
	SpreadsheetDocument.Put(Area);
	
EndProcedure

Procedure WithdrawIBANDetails(Selection, Template, SpreadsheetDocument)
	
	CAC = Mid(Selection.AccountNumber, 5);
	IBANPaper = "IBAN";
	AccountNumber = Selection.AccountNumber;
	While StrLen(AccountNumber) > 0 Do
		IBANPaper = IBANPaper + " " + Mid(AccountNumber, 1, 4);
		AccountNumber = Mid(AccountNumber, 5);
	EndDo;
	
	If Selection.ManualBankDetailsChange Then
		SWIFT = Selection.BankSWIFTCode
	Else
		SWIFT = Selection.SWIFTBIKBank
	EndIf;
		
	Area = Template.GetArea("IBAN");
	
	Area.Parameters.CAC = CAC;
	Area.Parameters.IBAN = Selection.AccountNumber;
	Area.Parameters.IBANPaper = IBANPaper;
	Area.Parameters.SWIFT = SWIFT;
	
	SpreadsheetDocument.Put(Area);
	
EndProcedure

Function QueryTextSeals()
	
	Return
	"SELECT
	|	CounterpartyBankAccounts.CorrespondentText AS CorrespondentText,
	|	CounterpartyBankAccounts.Owner.DescriptionFull AS OwnerFullName,
	|	CounterpartyBankAccounts.Owner.TIN AS TIN,
	|	CounterpartyBankAccounts.AccountNumber AS AccountNumber,
	|	CounterpartyBankAccounts.DigitalRoubleAccount AS DigitalRoubleAccount,
	|	CounterpartyBankAccounts.DigitalRoubleAccountID AS DigitalRoubleAccountID,
	|	ISNULL(Banks.Description, """") AS BankName,
	|	ISNULL(Banks.InternationalDescription, """") AS BankInternationalName,
	|	ISNULL(Banks.Code, """") AS Bank_Code,
	|	CounterpartyBankAccounts.BankCorrAccount AS BankCorrAccount,
	|	CounterpartyBankAccounts.ManualBankDetailsChange AS ManualBankDetailsChange,
	|	CounterpartyBankAccounts.BankBIC AS BankBIC,
	|	CounterpartyBankAccounts.BankCorrAccount AS CorrespondentAccountOfBankInAccount,
	|	CounterpartyBankAccounts.TransferBank AS TransferBank,
	|	CounterpartyBankAccounts.TransferBankBIC AS TransferBankBIC,
	|	CounterpartyBankAccounts.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	CounterpartyBankAccounts.Owner.DescriptionInternational AS InternationalNameOfRecipient,
	|	CounterpartyBankAccounts.BankDescription AS BankDescription,
	|	CounterpartyBankAccounts.BankNameInt AS BankNameInt,
	|	CounterpartyBankAccounts.BankAddressInt AS BankAddressInt,
	|	ISNULL(Banks.InternationalAddress, """") AS BankAddressInternational,
	|	ISNULL(Banks.SWIFTBIC, """") AS SWIFTBIKBank,
	|	CounterpartyBankAccounts.BankSWIFTCode AS BankSWIFTCode,
	|	CounterpartyBankAccounts.BankNameForPaymentsInt AS BankNameForPaymentsInt,
	|	ISNULL(BanksForSettlements.InternationalDescription, """") AS BankForSettlementsInternationalName,
	|	ISNULL(BanksForSettlements.InternationalAddress, """") AS BankForSettlementsAddressInternational,
	|	ISNULL(BankCountries.Ref, VALUE(Catalog.WorldCountries.EmptyRef)) AS BankCountry,
	|	CounterpartyBankAccounts.CountryOfBank AS CountryOfBank,
	|	CounterpartyBankAccounts.CountryOfBankForPayments AS CountryOfBankForPayments,
	|	CounterpartyBankAccounts.ThisIsAnIBAN AS ThisIsAnIBAN,
	|	CounterpartyBankAccounts.Ref AS Ref,
	|	CounterpartyBankAccounts.TransferBankDescription AS TransferBankDescription,
	|	ISNULL(BanksForSettlements.Description, """") AS BankForSettlementsName,
	|	ISNULL(BanksForSettlements.Code, """") AS BankForSettlementsCode,
	|	CounterpartyBankAccounts.BankCityInt AS BankCityInt,
	|	ISNULL(Banks.CityInternationalFormat, """") AS BankGorodInternational,
	|	ISNULL(BanksForSettlements.SWIFTBIC, """") AS SWIFTBIKSettlementBank,
	|	CounterpartyBankAccounts.CountryOfBank.InternationalDescription AS CountryOfBankInternationalName,
	|	CounterpartyBankAccounts.CountryOfBankForPayments.InternationalDescription AS
	|		CountryOfBankForSettlementInternationalName,
	|	ISNULL(BankCountries.InternationalDescription, """") AS BankCountryInternationalName,
	|	ISNULL(CountriesOfBanksForSettlements.InternationalDescription, """") AS SettlementBankCountryInternationalName,
	|	CounterpartyBankAccounts.BankCityForPaymentsInt AS BankCityForPaymentsInt,
	|	CounterpartyBankAccounts.BankAddressForPaymentInt AS BankAddressForPaymentInt,
	|	ISNULL(BanksForSettlements.CityInternationalFormat, """") AS BankForSettlementsCityInternational,
	|	CounterpartyBankAccounts.CorrespondentTIN AS CorrespondentTIN,
	|	CounterpartyBankAccounts.TransferBankDetailsManualEdit
	|FROM
	|	Catalog.CounterpartyBankAccounts AS CounterpartyBankAccounts
	|		LEFT JOIN Catalog.BankClassifier AS Banks
	|		ON CounterpartyBankAccounts.Bank = Banks.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON Banks.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS BanksForSettlements
	|		ON CounterpartyBankAccounts.TransferBank = BanksForSettlements.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlements
	|		ON BanksForSettlements.CountryCode = CountriesOfBanksForSettlements.Code
	|WHERE
	|	CounterpartyBankAccounts.Ref IN (&ReferencesArrray)";

EndFunction

#EndRegion

#EndIf
