#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function determines the bank account of the organization according to the specified parameters.
//
// Returns the organization's bank account if one bank account is found.
// Returns an empty link if no bank account was found or there are more than one accounts.
//
// Parameters:
//  ParametersStructure - See CashServer.ParametersForFillingOutOrganizationSBankAccount.
//
// Returns:
//	CatalogRef.CompaniesBankAccounts - The found bank account of the organization.
//
Function GetDefaultBankAccount(ParametersStructure) Export
	
	Organization = ParametersStructure.Organization;
	Currency = ParametersStructure.Currency;
	LineOfBusiness = ParametersStructure.LineOfBusiness;
	OffsettingAccount = ParametersStructure.OffsettingAccount;
	ExcludeAccountsInTransferredCurrency = ParametersStructure.ExcludeCurrencyAccounts;
	
	CorrespondenceWithDigitalRubleAccount = Undefined;
	
	
	QueryText =
	"SELECT ALLOWED TOP 2
	|	CompaniesBankAccounts.Ref AS CompanyBankAccount,
	|	CompaniesBankAccounts.Ref = &MainBankAccount AS Main
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	NOT CompaniesBankAccounts.DeletionMark
	|	AND NOT CompaniesBankAccounts.Closed
	|	AND (CompaniesBankAccounts.Owner = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND &ConditionByCurrency
	|	AND (CompaniesBankAccounts.LineOfBusiness = &LineOfBusiness
	|			OR &LineOfBusiness = UNDEFINED)
	|	AND NOT CompaniesBankAccounts.IsFolder
	|	AND (CompaniesBankAccounts.DigitalRoubleAccount = &CorrespondenceWithDigitalRubleAccount
	|		OR &CorrespondenceWithDigitalRubleAccount = UNDEFINED)
	|
	|ORDER BY
	|	Main DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED TOP 2
	|	CompaniesBankAccounts.Ref AS CompanyBankAccount,
	|	CompaniesBankAccounts.Ref = &MainBankAccount AS Main
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	NOT CompaniesBankAccounts.DeletionMark
	|	AND NOT CompaniesBankAccounts.Closed
	|	AND (CompaniesBankAccounts.Owner = &Organization
	|		OR &Organization = UNDEFINED)
	|	AND &ConditionByCurrency
	|	AND NOT CompaniesBankAccounts.IsFolder
	|	AND (CompaniesBankAccounts.DigitalRoubleAccount = &CorrespondenceWithDigitalRubleAccount
	|		OR &CorrespondenceWithDigitalRubleAccount = UNDEFINED)
	|
	|ORDER BY
	|	Main DESC";
	
	If Not ExcludeAccountsInTransferredCurrency Then
		ConditionByCurrency = "(CompaniesBankAccounts.CashCurrency = &Currency
						|		OR &Currency = UNDEFINED)";
	Else
		ConditionByCurrency = "(CompaniesBankAccounts.CashCurrency <> &Currency
						|		OR &Currency = UNDEFINED)";
	EndIf;
	
	Query = New Query;
	Query.Text = StrReplace(QueryText, "&ConditionByCurrency", ConditionByCurrency);
	
	If ValueIsFilled(Organization) Then
		MainBankAccount = Catalogs.Companies.GetPrimaryBankAccount(Organization);
	Else
		MainBankAccount = Undefined;
	EndIf;
	
	Query.SetParameter("Organization", ?(ValueIsFilled(Organization), Organization, Undefined));
	Query.SetParameter("Currency", ?(ValueIsFilled(Currency), Currency, Undefined));
	Query.SetParameter("LineOfBusiness", ?(ValueIsFilled(LineOfBusiness), LineOfBusiness, Undefined));
	Query.SetParameter("CorrespondenceWithDigitalRubleAccount", 
		?(ValueIsFilled(CorrespondenceWithDigitalRubleAccount), CorrespondenceWithDigitalRubleAccount, Undefined));
	Query.SetParameter("MainBankAccount", MainBankAccount);
	
	Result = Query.ExecuteBatch();
	SamplingByDirection  = Result[0].Select();
	SamplingWithoutDirection = Result[1].Select();
	
	If SamplingByDirection.Next() And (SamplingByDirection.Count() = 1 Or SamplingByDirection.Main) Then
		
		CompanyBankAccount = SamplingByDirection.CompanyBankAccount;
		
	ElsIf SamplingWithoutDirection.Next() And (SamplingWithoutDirection.Count() = 1 Or SamplingWithoutDirection.Main) Then
		
		CompanyBankAccount = SamplingWithoutDirection.CompanyBankAccount;
		
	Else
		
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
	EndIf;
	
	Return CompanyBankAccount;

EndFunction

// This function determines the organization and currency of the selected Bank account.
//
// Parameters:
//  BankAccount - CatalogRef.CompaniesBankAccounts - link to the bank account.
//
// Returns:
//	Structure - The company and the Attributes of the company's bank account:
//		* Organization - CatalogRef.Companies, Undefined - An company that owns a bank account.
//		* Currency - CatalogRef.Currencies, Undefined - Currency of cash accounting.
//		* EnableCreatingCashIssueWithoutPaymentRequest - Boolean - indicates that it is possible to make a Outgoing payment-Bank account without 
//		                                      the document "Request for disbursement of funds".
//		* AccountNumber - String - The company's current account number.
//		* AccountType - EnumRef.BankAccountTypes, Undefined - classification of a bank account.
//		* Bank - CatalogRef.BankClassifier, String, Undefined - The bank where the company's current account is opened.
//		* BankDescription - String - The official name of the bank.
//		* BIC - String - Russian bank identification code of the bank.
//		* CorrAccount - String - Bank's correspondent account.
//		* BankAddress - String - Bank address.
//		* CASHSETTLEMENTCENTERBIC - CatalogRef.BankClassifier, Undefined - Bank identification code of the cash settlement center.
//		* BankNameInt - String - The official name of the bank in English.
//		* BankSWIFTCode - String - The bank's code in the SWIFT payment system.
//		* BankCityInt - String - The bank's city is in English.
//		* BankAddressInt - String - The bank's address is in English.
//		* Country - CatalogRef.WorldCountries, Undefined - bank country.
//		* DigitalRoubleAccount - Boolean - digital ruble account attribute.
//		* DigitalRoubleAccountID - String - ID of the digital ruble account.
//		* IsFolder - Boolean - flag for a group in the Catalog.
//		* PersonalAccountSection - String - personal account section for treasury account.
//		* PersonalAccountNumber - String - personal account number for the Treasury account.
//
Function GetCompanySBankAccountDetails(BankAccount) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT ALLOWED
	|	BankAccounts.Owner                          AS Organization,
	|	BankAccounts.CashCurrency             AS Currency,
	|	BankAccounts.EnableCreatingCashIssueWithoutPaymentRequest AS EnableCreatingCashIssueWithoutPaymentRequest,
	|	BankAccounts.AccountNumber                        AS AccountNumber,
	|	BankAccounts.DigitalRoubleAccount                AS DigitalRoubleAccount,
	|	BankAccounts.DigitalRoubleAccountID  AS DigitalRoubleAccountID,
	|	BankAccounts.AccountType                          AS AccountType,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankDescription
	|		ELSE BankAccounts.Bank
	|	END AS Bank,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankDescription
	|		ELSE ISNULL(Banks.Description, """")
	|	END AS BankDescription,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankBIC
	|		ELSE ISNULL(Banks.Code, """")
	|	END AS BIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCorrAccount
	|		ELSE ISNULL(Banks.CorrAccount, """")
	|	END AS CorrAccount,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankAddress
	|		ELSE ISNULL(Banks.Address, """")
	|	END AS BankAddress,
	|	Banks.CashSettlementCenterBIC AS CashSettlementCenterBIC,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankNameInt
	|		ELSE ISNULL(Banks.InternationalDescription, """")
	|	END AS BankNameInt,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankSWIFTCode
	|		ELSE ISNULL(Banks.SWIFTBIC, """")
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankCityInt
	|		ELSE ISNULL(Banks.CityInternationalFormat, """")
	|	END AS BankCityInt,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.BankAddressInt
	|		ELSE ISNULL(Banks.InternationalAddress, """")
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN BankAccounts.ManualBankDetailsChange
	|			THEN BankAccounts.CountryOfBank
	|		ELSE ISNULL(WorldCountries.Ref, VALUE(Catalog.WorldCountries.EmptyRef))
	|	END AS Country,
	|	BankAccounts.IsFolder AS IsFolder
	|FROM
	|	Catalog.CompaniesBankAccounts AS BankAccounts
	|		LEFT JOIN Catalog.BankClassifier AS Banks
	|		ON BankAccounts.Bank = Banks.Ref
	|		LEFT JOIN Catalog.WorldCountries AS WorldCountries
	|		ON Banks.CountryCode = WorldCountries.Code
	|WHERE
	|	BankAccounts.Ref = &BankAccount
	|";
	
	Query.SetParameter("BankAccount", BankAccount);
	
	AccountAttributes = New Structure;
	AccountAttributes.Insert("Organization", Undefined);
	AccountAttributes.Insert("Currency", Undefined);
	AccountAttributes.Insert("EnableCreatingCashIssueWithoutPaymentRequest", False);
	AccountAttributes.Insert("AccountNumber", "");
	AccountAttributes.Insert("AccountType", Undefined);
	AccountAttributes.Insert("Bank", Undefined);
	AccountAttributes.Insert("BankDescription", "");
	AccountAttributes.Insert("BIC", "");
	AccountAttributes.Insert("CorrAccount", "");
	AccountAttributes.Insert("BankAddress", "");
	AccountAttributes.Insert("CASHSETTLEMENTCENTERBIC", Undefined);
	AccountAttributes.Insert("BankNameInt", "");
	AccountAttributes.Insert("BankSWIFTCode", "");
	AccountAttributes.Insert("BankCityInt", "");
	AccountAttributes.Insert("BankAddressInt", "");
	AccountAttributes.Insert("Country", Undefined);
	AccountAttributes.Insert("DigitalRoubleAccount", False);
	AccountAttributes.Insert("DigitalRoubleAccountID", "");

	AccountAttributes.Insert("IsFolder", False);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(AccountAttributes, Selection);
	EndIf;
	
	Return AccountAttributes;
	
EndFunction

// Default upload file function for all Bank accounts
//
// Returns the found path of the Bank upload file if a single Bank account is found.
// Returns Undefined if the Bank account is not found or there are more than one accounts.
//
// Parameters:
//    Bank - CatalogRef.BankClassifier - Link to the Bank of the Bank account.
//
// Returns:
//    String - The found path of the bank's upload file.
//
Function DefaultUploadFile(Bank) Export
	
	DefaultUploadFile = Undefined;
	
	Query = New Query("SELECT ALLOWED TOP 2
	|	CompaniesBankAccounts.ExportFile AS ExportFile
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	NOT CompaniesBankAccounts.DeletionMark
	|	AND CompaniesBankAccounts.Bank = &Bank
	|
	|GROUP BY
	|	CompaniesBankAccounts.ExportFile");
	
	Query.SetParameter("Bank", Bank);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DefaultUploadFile = Selection.ExportFile;
	EndIf;
	
	Return DefaultUploadFile;
	
EndFunction

// Default upload file function for all Bank accounts
//
// Returns the found path of the Bank upload file if a single Bank account is found.
// Returns Undefined if the Bank account is not found or there are more than one accounts.
//
// Parameters:
//    Bank - CatalogRef.BankClassifier - Link to the Bank of the Bank account.
//
// Returns:
//    String - The found path of the bank download file.
//
Function DefaultDownloadFile(Bank) Export
	
	DefaultDownloadFile = Undefined;
	
	Query = New Query("SELECT ALLOWED TOP 2
	|	CompaniesBankAccounts.ImportFile AS ImportFile
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|WHERE
	|	NOT CompaniesBankAccounts.DeletionMark
	|	AND CompaniesBankAccounts.Bank = &Bank
	|
	|GROUP BY
	|	CompaniesBankAccounts.ImportFile");
	
	Query.SetParameter("Bank", Bank);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		DefaultDownloadFile = Selection.ImportFile;
	EndIf;
	
	Return DefaultDownloadFile;
	
EndFunction

// Defines the properties of form fields depending on the data
// 
// Returns:
//  See CashServer.InitializeFormFieldSettings.
//
Function FormFieldSettings() Export
	
	Finances = FinancialReportingServer;
	Settings = CashServer.InitializeFormFieldSettings();
	
	// Header
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCompanies", True);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("SettlementBankUsed");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "SeparateSDOAccount", True);
	Finances.NewFilter(OrGroup, "AccountType", Enums.BankAccountTypes.Transit);
	Item.Properties.Insert("Enabled", False);
	
	Item = Settings.Add();
	Item.Fields.Add("MainBankAccount");
	Finances.NewFilter(Item.Condition, "AccountType", Enums.BankAccountTypes.Transit);
	Item.Properties.Insert("Visible");
	
	// Exchange with the bank
	Item = Settings.Add();
	Item.Fields.Add("ExportFile");
	Item.Fields.Add("ImportFile");
	Item.Fields.Add("ExchangeFormatAndEncoding");
	Item.Fields.Add("UseUploadDirectory");
	Item.Fields.Add("UseDownloadDirectory");
	Finances.NewFilter(Item.Condition, "BankEDIEnabled", True);
	Finances.NewFilter(Item.Condition, "UseBankClientDataExchange", True);
	Finances.NewFilter(Item.Condition, "DirectEDIWithBankIsUsed", False);
	//++WE
	Finances.NewFilter(Item.Condition, "UseBankFeedsBankExchange", False);
	//-- WE
	
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Encoding");
	ListOfExchangeFiles = New ValueList;
	ListOfExchangeFiles.Add(Enums.ExchangeFormatWithBank.ClientBankExchange1c); 
	ListOfExchangeFiles.Add(Enums.ExchangeFormatWithBank.MT940);
	Finances.NewFilter(Item.Condition, "ExchangeFormat", ListOfExchangeFiles, , DataCompositionComparisonType.InList);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("VersionOfUploadFormat");
	Finances.NewFilter(Item.Condition, "ExchangeFormat", Enums.ExchangeFormatWithBank.ISO20022);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("DirectExchangeGroup");
	Finances.NewFilter(Item.Condition, "More.UseExchangesWithBanks", True);
	Finances.NewFilter(Item.Condition, "AccountType", Enums.BankAccountTypes.Treasury, , DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("BankFeedsGroup");
	Finances.NewFilter(Item.Condition, "More.UseEDIWithBanksBankFeeds", True);
	Item.Properties.Insert("Visible");
	
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
	
	// Header
	Item = Settings.Add();
	Item.Fields.Add("Owner");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCompanies", True);
	Item.Properties.Insert("Visible");
	
	// Exchange with the bank
	Item = Settings.Add();
	Item.Fields.Add("ExportFile");
	Item.Fields.Add("ImportFile");
	Item.Fields.Add("ExchangeFormatAndEncoding");
	Item.Fields.Add("UseUploadDirectory");
	Item.Fields.Add("UseDownloadDirectory");
	Finances.NewFilter(Item.Condition, "BankEDIEnabled", True);
	Finances.NewFilter(Item.Condition, "UseBankClientDataExchange", True);
	Finances.NewFilter(Item.Condition, "DirectEDIWithBankIsUsed", False);
	//++ WE
	Finances.NewFilter(Item.Condition, "UseBankFeedsBankExchange", False);
	//-- WE
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Encoding");
	ListOfExchangeFiles = New ValueList;
	ListOfExchangeFiles.Add(Enums.ExchangeFormatWithBank.ClientBankExchange1c); 
	ListOfExchangeFiles.Add(Enums.ExchangeFormatWithBank.MT940);
	Finances.NewFilter(Item.Condition, "ExchangeFormat", ListOfExchangeFiles, , DataCompositionComparisonType.InList);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("VersionOfUploadFormat");
	Finances.NewFilter(Item.Condition, "ExchangeFormat", Enums.ExchangeFormatWithBank.ISO20022);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("DirectExchangeGroup");
	Finances.NewFilter(Item.Condition, "More.UseExchangesWithBanks", True);
	Finances.NewFilter(Item.Condition, "AccountType", Enums.BankAccountTypes.Treasury, , DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	// General item settings
	Item = Settings.Add();
	Item.Fields.Add("BankBIC");
	Item.Fields.Add("BicOfBankAtLink");
	Finances.NewFilter(Item.Condition, "ForeignBank", False);
	Item.Properties.Insert("Title", NStr("vi = 'Mã ngân hàng';
										|ru = 'БИК';
										|en = 'Bank code'; fa = 'کد بانک';
										|it = 'БИК';
										|pl = 'Bank code';
										|tr = 'BIC'"));
	
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
	
	Return Settings;
	
EndFunction

// Retrieves the list of the organization's bank accounts from the selected folder.
// 
// Parameters:
//  Directory - CatalogRef.CompaniesBankAccounts - the group is in the Catalog.
// 
// Returns:
//  Array of CatalogRef.CompaniesBankAccounts - list of bank accounts.
//
Function CatalogBankAccounts(Directory) Export

	Query = New Query;
	Query.Text = 
		"SELECT ALLOWED
		|	CompaniesBankAccounts.Ref AS BankAccount
		|FROM
		|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
		|WHERE
		|	CompaniesBankAccounts.Ref IN HIERARCHY(&Ref)
		|	AND NOT CompaniesBankAccounts.IsFolder
		|	AND CompaniesBankAccounts.Ref <> &Ref";
	
	Query.SetParameter("Ref", Directory);
	
	Return Query.Execute().Unload().UnloadColumn("BankAccount");

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
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Owner)";

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
	NewTeam.Presentation = NStr("vi = 'Mục tin';
								|ru = 'Реквизиты';
								|en = 'Bank details'; fa = 'جزئیات بانکی';
								|it = 'Requisiti';
								|pl = 'Bank details';
								|tr = 'Öznitelikler'");
	NewTeam.FormCaption = NStr("vi = 'In thông tin tài khoản ngân hàng';
								|ru = 'Печать реквизитов банковского счета';
								|en = 'Print bank account details'; fa = 'Print bank account details';
								|it = 'Stampare requisiti conto corrente';
								|pl = 'Drukowanie danych rachunku bankowego';
								|tr = 'Banka hesabı bilgilerini yazdır'");
	
	CompaniesBankAccountsLocalization.AddPrintCommands(PrintCommands);
	
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
	
	CompaniesBankAccountsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

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

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. You should use get a Bank account in silence.
// The function defines the bank account of the selected organization.
//
// Returns the organization's bank account if one bank account is found.
// Returns Undefined if no bank account was found or there are more than one accounts.
//
// Parameters:
//  Organization - CatalogRef.Companies - Link to the organization
//	Currency - CatalogRef.Currencies - The currency of the bank account.
//	LineOfBusiness - CatalogRef.LinesOfBusiness
//	OffsettingAccount - CatalogRef.CompaniesBankAccounts - the invoice that the received invoice corresponds to.
//	Exclude a Currency account - Boolean - if True, the accounts in the currency passed in the Currency parameter will be excluded.
//
// Returns:
//	CatalogRef.CompaniesBankAccounts - The found bank account of the organization.
//
Function GetOrganizationSDefaultBankAccount(Organization, Currency = Undefined,
	LineOfBusiness = Undefined, OffsettingAccount = Undefined) Export
	
	ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersStructure.Organization = Organization;
	ParametersStructure.Currency = Currency;
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	ParametersStructure.OffsettingAccount = OffsettingAccount;
	
	Return GetDefaultBankAccount(ParametersStructure);
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("SelectingAccountsOfParentCompany") Then
		
		If Not GetFunctionalOption("UseBranchOfficesWithSeparateBalanceSheets") Then
			Return;
		EndIf;
		
		Organization = Undefined;
		Parameters.Filter.Property("Owner", Organization);
		
		If Not ValueIsFilled(Organization)
			Or Not GeneralPurposeTMServerCall.ObjectAttributeValue(Organization, "BranchOffice") Then
			Return;
		EndIf;
		
		BusinessOperation = Undefined;
		If Parameters.Property("BusinessOperation", BusinessOperation) Then
			
			If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
				Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
				ThereAreCustomersARAP = True;
			Else
				ThereAreCustomersARAP = False;
			EndIf;
			
			ThereAreVendorsARAP = Not ThereAreCustomersARAP;
			
		Else
		
			ThereAreCustomersARAP = Parameters.Property("ThereAreCustomersARAP");
			ThereAreVendorsARAP = Parameters.Property("ThereAreVendorsARAP");
			
		EndIf;
		
		StandardProcessing = False;
		Query = New Query("SELECT
		|	&Organization
		|INTO AvailableCompanies
		|
		|UNION ALL
		|
		|SELECT
		|	Companies.ParentCompany
		|FROM
		|	Catalog.Companies AS Companies
		|WHERE
		|	Companies.Ref = &Organization
		|	AND Companies.TransactionsUsingParentCompanyAreAllowed
		|	AND (&ThereAreCustomersARAP OR &ThereAreVendorsARAP)
		|	AND Companies.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CompaniesBankAccounts.Ref,
		|	CompaniesBankAccounts.Description,
		|	CompaniesBankAccounts.Owner
		|INTO Data
		|FROM
		|	AvailableCompanies AS AvailableCompanies
		|		INNER JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
		|		ON AvailableCompanies.Organization = CompaniesBankAccounts.Owner
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Data.Ref
		|FROM
		|	Data AS Data
		|WHERE
		|	&SearchCriteria_ AND &OtherConditions
		|
		|ORDER BY
		|	Data.Owner,
		|	Data.Description
		|AUTOORDER");
		Query.SetParameter("Organization", Organization);
		Query.SetParameter("ThereAreCustomersARAP", ThereAreCustomersARAP);
		Query.SetParameter("ThereAreVendorsARAP", ThereAreVendorsARAP);
		
	ElsIf Parameters.Property("IncludeBranchAccounts") 
				And Parameters.IncludeBranchAccounts
				And Parameters.Filter.Property("Owner")
				And (ValueIsFilled(Parameters.Filter.Owner)
					Or Parameters.Property("OnlyCompaniesWithBranches") 
						And Parameters.OnlyCompaniesWithBranches) Then
		
		CompanyArray = Catalogs.Companies.ArrayOfInterconnectedOrganizations(Parameters.Filter.Owner);
		CompanyArray.Add(Parameters.Filter.Owner);
		
		StandardProcessing = False;
		Query = New Query("
			|SELECT ALLOWED
			|	Data.Ref
			|FROM
			|	Catalog.CompaniesBankAccounts AS Data
			|WHERE
			|	Data.Owner IN (&CompanyArray)
			|	AND &SearchCriteria_
			|	AND &OtherConditions
			|
			|ORDER BY
			|	Data.Owner,
			|	Data.Description
			|AUTOORDER");
		Query.SetParameter("CompanyArray", CompanyArray);
		
	EndIf;
	
	If Not StandardProcessing Then
		
		Query.Text = StrReplace(Query.Text, "&SearchCriteria_", "Data.Description LIKE &SearchString");
		Query.SetParameter("SearchString", ?(Parameters.SearchString = Undefined, "", Parameters.SearchString) + "%");
		
		OtherConditions = "";
		For Each Item In Parameters.Filter Do
			
			If Item.Key = "Owner" Then
				Continue;
			Else
				
				OtherConditions = OtherConditions + "Data.Ref." + Item.Key 
					+ ?(TypeOf(Item.Value) = Type("FixedArray"), " IN (&", " = (&") 
					+ Item.Key + ") AND ";
				Query.SetParameter(Item.Key, Item.Value);
				
			EndIf;
			
		EndDo;
		
		If OtherConditions = "" Then
			OtherConditions = "True";
		Else
			OtherConditions = Left(OtherConditions, StrLen(OtherConditions) - 3);
		EndIf;
			
		Query.Text = StrReplace(Query.Text, "&OtherConditions", OtherConditions);
		
		ChoiceData = New ValueList;
		ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
		
	EndIf;
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" And Not GetFunctionalOption("UseMultipleBankAccounts") Then
		Parameters.Insert("Key", GeneralPurposeTMServerCall.OrganizationSDefaultBankAccount());
		SelectedForm = "ItemForm";
		StandardProcessing = False;
	Else
		
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
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function PrintingAccountDetails(ObjectsArray, PrintObjects)
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersKey = "PRINT_OPTIONS_BankAccountDetailsCompanies";
	
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

Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	
	Result.Add("CashCurrency");
	Result.Add("Owner");
	Result.Add("ForeignBank; ForeignBank");
	Result.Add("AccountType");
	Result.Add("FinancialAccountingGroup");
	Result.Add("Department");
	Result.Add("LineOfBusiness");
	Result.Add("SeparateSDOAccount");
	Result.Add("StateContract");
	Result.Add("SettingUpAccountingAccountsAccountingAccountCash");
	Return Result;
	
EndFunction

Function QueryTextSeals()
	
	Return
	"SELECT
	|	CompaniesBankAccounts.CorrespondentText AS CorrespondentText,
	|	CompaniesBankAccounts.Owner.DescriptionFull AS OwnerFullName,
	|	CompaniesBankAccounts.Owner.TIN AS TIN,
	|	CompaniesBankAccounts.AccountNumber AS AccountNumber,
	|	CompaniesBankAccounts.DigitalRoubleAccount AS DigitalRoubleAccount,
	|	CompaniesBankAccounts.DigitalRoubleAccountID AS DigitalRoubleAccountID,
	|	ISNULL(Banks.Description, """") AS BankName,
	|	ISNULL(Banks.InternationalDescription, """") AS BankInternationalName,
	|	ISNULL(Banks.Code, """") AS Bank_Code,
	|	CompaniesBankAccounts.BankCorrAccount AS BankCorrAccount,
	|	CompaniesBankAccounts.ManualBankDetailsChange AS ManualBankDetailsChange,
	|	CompaniesBankAccounts.BankBIC AS BankBIC,
	|	CompaniesBankAccounts.BankCorrAccount AS CorrespondentAccountOfBankInAccount,
	|	CompaniesBankAccounts.TransferBank AS TransferBank,
	|	CompaniesBankAccounts.TransferBankBIC AS TransferBankBIC,
	|	CompaniesBankAccounts.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	CompaniesBankAccounts.Owner.DescriptionInternational AS InternationalNameOfRecipient,
	|	CompaniesBankAccounts.BankDescription AS BankDescription,
	|	CompaniesBankAccounts.BankNameInt AS BankNameInt,
	|	CompaniesBankAccounts.BankAddressInt AS BankAddressInt,
	|	ISNULL(Banks.InternationalAddress, """") AS BankAddressInternational,
	|	ISNULL(Banks.SWIFTBIC, """") AS SWIFTBIKBank,
	|	CompaniesBankAccounts.BankSWIFTCode AS BankSWIFTCode,
	|	CompaniesBankAccounts.BankNameForPaymentsInt AS BankNameForPaymentsInt,
	|	ISNULL(BanksForSettlements.InternationalDescription, """") AS BankForSettlementsInternationalName,
	|	ISNULL(BanksForSettlements.InternationalAddress, """") AS BankForSettlementsAddressInternational,
	|	ISNULL(BankCountries.Ref, VALUE(Catalog.WorldCountries.EmptyRef)) AS BankCountry,
	|	CompaniesBankAccounts.CountryOfBank AS CountryOfBank,
	|	CompaniesBankAccounts.CountryOfBankForPayments AS CountryOfBankForPayments,
	|	CompaniesBankAccounts.ThisIsAnIBAN AS ThisIsAnIBAN,
	|	CompaniesBankAccounts.Ref AS Ref,
	|	CompaniesBankAccounts.TransferBankDescription AS TransferBankDescription,
	|	ISNULL(BanksForSettlements.Description, """") AS BankForSettlementsName,
	|	ISNULL(BanksForSettlements.Code, """") AS BankForSettlementsCode,
	|	CompaniesBankAccounts.BankCityInt AS BankCityInt,
	|	ISNULL(Banks.CityInternationalFormat, """") AS BankGorodInternational,
	|	ISNULL(BanksForSettlements.SWIFTBIC, """") AS SWIFTBIKSettlementBank,
	|	CompaniesBankAccounts.CountryOfBank.InternationalDescription AS CountryOfBankInternationalName,
	|	CompaniesBankAccounts.CountryOfBankForPayments.InternationalDescription AS
	|		CountryOfBankForSettlementInternationalName,
	|	ISNULL(BankCountries.InternationalDescription, """") AS BankCountryInternationalName,
	|	ISNULL(CountriesOfBanksForSettlements.InternationalDescription, """") AS SettlementBankCountryInternationalName,
	|	CompaniesBankAccounts.BankCityForPaymentsInt AS BankCityForPaymentsInt,
	|	CompaniesBankAccounts.BankAddressForPaymentInt AS BankAddressForPaymentInt,
	|	ISNULL(BanksForSettlements.CityInternationalFormat, """") AS BankForSettlementsCityInternational,
	|	CompaniesBankAccounts.TransferBankDetailsManualEdit
	|FROM
	|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|		LEFT JOIN Catalog.BankClassifier AS Banks
	|		ON CompaniesBankAccounts.Bank = Banks.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON Banks.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS BanksForSettlements
	|		ON CompaniesBankAccounts.TransferBank = BanksForSettlements.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfBanksForSettlements
	|		ON BanksForSettlements.CountryCode = CountriesOfBanksForSettlements.Code
	|WHERE
	|	CompaniesBankAccounts.Ref IN (&ReferencesArrray)";

EndFunction

#EndRegion

#EndIf
