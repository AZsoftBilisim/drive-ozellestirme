
#Region Public

// The function returns an additional column that is output to the table of printed form products.
// 
// Parameters:
// 	LanguageCode - Undefined, String - Code of the language to get the string in. If undefined, then the main language Code.
// Returns:
// 	Structure:
// 		* ColumnName - String - Name of the column (for use in the code).
// 		* ColumnPresentation - String - Name of the column (for display based on the user's language).
Function AdditionalColumnOfDocumentPrintForms(LanguageCode = Undefined) Export
	If LanguageCode = Undefined Then
		LanguageCode = Common.DefaultLanguageCode();
	EndIf;
	AdditionalColumn = Constants.AdditionalColumnOfDocumentPrintForms.Get();
	Result = New Structure("ColumnName, ColumnPresentation", "", "");
	If AdditionalColumn = Enums.AdditionalColumnOfDocumentPrintForms.SKU Then
		Result.ColumnName = "SKU";
		Result.ColumnPresentation = NStr("vi = 'Mã hiệu';
										|ru = 'Артикул';
										|en = 'Item ID'; fa = 'شناسه قلم';
										|it = 'Articolo';
										|pl = 'Artykuł';
										|tr = 'Ürün kodu'", LanguageCode);
	ElsIf AdditionalColumn = Enums.AdditionalColumnOfDocumentPrintForms.Code Then
		Result.ColumnName = "Code";
		Result.ColumnPresentation = NStr("vi = 'Mã';
										|ru = 'Код';
										|en = 'Code'; fa = 'کد';
										|it = 'Codice';
										|pl = 'Kod';
										|tr = 'Kod'", LanguageCode);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a string with a summary description of the organization / counterparty / individual.
//
// Parameters: 
//  ListOfInformation - Structure - parameter values of the organization, is formed by the function Vedenyapina()
//  List         - String - comma-separated list of requested organization parameters
//  WithPrefix     - Boolean - indicates whether the organization parameter prefix is displayed.
//
// Returns:
//  String - description of the organization / counterparty / individual.
//
Function OrganizationDescription(ListOfInformation, List = "", WithPrefix = True) Export
	
	If IsBlankString(List) Then
		// Default description format
		List = "FullDescr,TIN,LegalAddress,Phones,AccountNumber,Bank,BIC,CorrAccount";
	EndIf;
	
	// The list of details displayed in the description
	AttributesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(List, ",", True);
	
	// The list of details that go as an addition to the "main" details: Account number and Certificate.
	AdditionalAttributes = New Structure("Bank,BIC,CorrAccount,SertificateDateOfIssue,CASHSETTLEMENTCENTERBIC,DigitalRoubleAccount");
	FillPropertyValues(AdditionalAttributes, ListOfInformation);
	
	// Explanations for some types of details displayed in the description
	BankingDetailsPrefixes = New Structure;
	BankingDetailsPrefixes.Insert("TIN",			NStr("vi = 'MST %1';
														|ru = 'ИНН %1';
														|en = 'TIN %1'; fa = 'TIN %1';
														|it = 'Codice Fiscale %1';
														|pl = 'NIP %1';
														|tr = 'VKN %1'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("CRTR",			NStr("vi = 'Mã chi nhánh %1';
															|ru = 'КПП %1';
															|en = 'KPP %1'; fa = 'KPP %1';
															|it = 'Codice Causale Di Registrazione Fiscale %1';
															|pl = 'KPP %1';
															|tr = 'KPP %1'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("CertificateOfOwnership",NStr("vi = '%1 ngày %2';
																|ru = '%1 от %2';
																|en = '%1 from %2'; fa = '%1 from %2';
																|it = '%1 del %2';
																|pl = '%1 z dn. %2';
																|tr = '%2 itibaren %1'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("Phones",		NStr("vi = 'đt.: %1';
														|ru = 'тел.: %1';
														|en = 'phone: %1'; fa = 'phone: %1';
														|it = 'Tel.: %1';
														|pl = 'tel.: %1';
														|tr = 'tel.: %1'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("AccountNumber",	NStr("vi = '%1 %2 tại ngân hàng %3 %4 %5 %6 %7';
															|ru = '%1 %2 в банке %3 %4 %5 %6 %7';
															|en = '%1 %2 in the bank %3 %4 %5 %6 %7'; fa = '%1 %2 in the bank %3 %4 %5 %6 %7';
															|it = '%1 %2 nella banca %3 %4 %5 %6 %7';
															|pl = '%1 %2 w banku %3 %4 %5 %6 %7';
															|tr = '%1 %2 bankada %3 %4 %5 %6 %7'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("NCBOCode",	NStr("vi = 'Mã doanh nghiệp %1';
														|ru = 'Код по ОКПО %1';
														|en = 'OKPO code %1'; fa = 'OKPO code %1';
														|it = 'Codice in base all''OKPO (Classificatore Panrusso delle Imprese e degli Enti) %1';
														|pl = 'Kod wg OKPO %1';
														|tr = 'OKPO kodu %1'", Common.DefaultLanguageCode()));
	BankingDetailsPrefixes.Insert("BusinessActivityClassifierCode",		NStr("vi = 'Mã hoạt động xuất nhập khẩu %1';
																				|ru = 'Код ОКВЭД %1';
																				|en = 'OKVED code %1'; fa = 'OKVED code %1';
																				|it = 'Codice OKVED (Classificazione Panrussa delle Attività Economiche) %1';
																				|pl = 'Kod KRS %1';
																				|tr = 'Kod OKVED %1'", Common.DefaultLanguageCode()));
	
	LongDesc = "";
	PropsPrefix  = Undefined;
	AttributeValue = Undefined;
	
	For Each AttributeName In AttributesArray Do
		
		If WithPrefix And AdditionalAttributes.Property(AttributeName) Then
			Continue; // it will be displayed together with the "main" props
		EndIf;
		
		ListOfInformation.Property(AttributeName, AttributeValue);
		If Not ValueIsFilled(AttributeValue) Then
			Continue; // either there are no such props at all, or it is not filled in
		EndIf;
		
		If WithPrefix Then
			BankingDetailsPrefixes.Property(AttributeName, PropsPrefix);
		EndIf;
		
		If WithPrefix And AttributeName = "AccountNumber" Then
			
			If ValueIsFilled(AdditionalAttributes.DigitalRoubleAccount)
				And AdditionalAttributes.DigitalRoubleAccount Then
				
				AdditionToDetails = StrTemplate(NStr("vi = 'счет цифрового рубля %1';
													|ru = 'счет цифрового рубля %1';
													|en = 'Digital rouble account %1'; fa = 'Digital rouble account %1';
													|it = 'счет цифрового рубля %1';
													|pl = 'Digital rouble account %1';
													|tr = 'счет цифрового рубля %1'"), AttributeValue);
				
			Else
			
				BankPresentation = 
					?(ValueIsFilled(AdditionalAttributes.CASHSETTLEMENTCENTERBIC), TrimAll(AdditionalAttributes.CASHSETTLEMENTCENTERBIC) + "//", "")
					+ TrimAll(AdditionalAttributes.Bank);
				
				NameOfCurrentAccount = 
					?(CashClientServerLocalization.ThisIsTreasuryAccount(AttributeValue),
						"kazn.account",
						"r/From1");
				
				NameOfBIC = 
					?(CashClientServerLocalization.ThisIsBICTOFC(AdditionalAttributes.BIC),
						"BIC TOFC",
						"BIC");
						
				NameOfCorrespondentAccount = 
					?(CashClientServerLocalization.ThisIsSingleTreasuryAccount(AdditionalAttributes.CorrAccount),
						"EKS",
						"k/From1");
				
				AdditionToDetails = StringFunctionsClientServer.SubstituteParametersToString(
					PropsPrefix,
					NameOfCurrentAccount,
					TrimAll(AttributeValue),
					BankPresentation,
					NameOfBIC,
					TrimAll(AdditionalAttributes.BIC),
					NameOfCorrespondentAccount,
					TrimAll(AdditionalAttributes.CorrAccount));
				
			EndIf;
			
		ElsIf WithPrefix And AttributeName = "CertificateOfOwnership"
		 And ValueIsFilled(AdditionalAttributes.SertificateDateOfIssue) Then
			
			AdditionToDetails = StringFunctionsClientServer.SubstituteParametersToString(
				PropsPrefix,
				TrimAll(AttributeValue),
				TrimAll(AdditionalAttributes.SertificateDateOfIssue));
			
		ElsIf ValueIsFilled(PropsPrefix) Then
			
			// All other details, except those mentioned above, have only one parameter in the prefix.
			AdditionToDetails = StringFunctionsClientServer.SubstituteParametersToString(
				PropsPrefix,
				TrimAll(AttributeValue));
			
		Else
			
			AdditionToDetails = TrimAll(AttributeValue);
			
		EndIf;
		
		LongDesc = LongDesc	+ ?(IsBlankString(LongDesc), "", ", ") + AdditionToDetails;
		
	EndDo;
	
	Return TrimAll(LongDesc);
	
EndFunction

// This function generates information about the specified legal entity or individual.
// Information includes: name, address, phone number, Bank details.
//
// Parameters: 
//  LegalEntityIndividual   - CatalogRef.Companies, CatalogRef.Counterparties - the organization or individual that information is collected about.
//  PeriodDate_ - Date - the date on which information about the legal Entity is selected.
//  ForEachPersonOnlyInitials - Boolean - For Phys. only print the initials of the first name and patronymic.
//  BankAccount - Undefined, CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts - Bank account, if the account is not the main one.
//
// Returns:
//  Structure - collected information.
//
Function InformationAboutLegalEntity(LegalEntityIndividual, PeriodDate_, ForEachPersonOnlyInitials = True, Val BankAccount = Undefined, CompanyIsMajorTaxpayer = False ) Export
	FieldList = "Presentation, NameAbbreviated, FullDescr, NameForPrintedForms, Email, RegistrationCountry, TaxNumberInCountryOfRegistration,
		|NCBOCode, BusinessActivityClassifierCode, TIN, CRTR, Phones, Email, LegalAddress, ActualAddress, Bank, BIC, CorrAccount, AccountNumber";
	PrintManagementLocalization.AddInformationAboutLegalEntityToListOfFields(FieldList);
	InformationRecords = New Structure(FieldList);
	
	FillInInformationAboutLegalEntity(InformationRecords, LegalEntityIndividual, PeriodDate_, ForEachPersonOnlyInitials, BankAccount, CompanyIsMajorTaxpayer);
	
	Return InformationRecords;
EndFunction

// Generates information about the specified legal entity or individual.
// Information includes: name, address, phone number, Bank details.
//
// Parameters: 
//  InformationRecords                 - Structure - collected information.
//  LegalEntityIndividual                - CatalogRef.Companies, CatalogRef.Counterparties - the organization or individual that information is collected about.
//  PeriodDate_              - Date - the date on which information about the legal Entity is selected.
//  ForEachPersonOnlyInitials - Boolean - For Phys. only print the initials of the first name and patronymic.
//  BankAccount           - Undefined, CatalogRef.CounterpartyBankAccounts, CatalogRef.CompaniesBankAccounts - Bank account, if the account is not the main one.
//  CompanyIsMajorTaxpayer - Boolean - If the company is the largest taxpayer, fill in the checkpoint of the checkpoint of the largest.
//
Procedure FillInInformationAboutLegalEntity(InformationRecords, LegalEntityIndividual, PeriodDate_, ForEachPersonOnlyInitials = True, Val BankAccount = Undefined, CompanyIsMajorTaxpayer = False ) Export
	If ValueIsFilled(LegalEntityIndividual)
		And (TypeOf(LegalEntityIndividual) = Type("CatalogRef.Companies")
		Or TypeOf(LegalEntityIndividual) = Type("CatalogRef.Counterparties")) Then
		
		Email = "";
		AccountAttributes = New Structure();
		If TypeOf(LegalEntityIndividual) = Type("CatalogRef.Companies") Then
			Attributes = Catalogs.Companies.GetBusinessDetails(LegalEntityIndividual);
			NamesAsOfDate = CompaniesCached.NamesAsOfDate(LegalEntityIndividual, PeriodDate_);
			If Not IsBlankString(NamesAsOfDate.AbbreviatedDescription) Then
				Attributes.Description = NamesAsOfDate.AbbreviatedDescription;
				Attributes.Presentation = NamesAsOfDate.AbbreviatedDescription;	
			EndIf;
			If Not ValueIsFilled(BankAccount) Then
				ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount(LegalEntityIndividual);
				BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
			EndIf;
			AccountAttributes = Catalogs.CompaniesBankAccounts.GetCompanySBankAccountDetails(BankAccount);
			Email = ContactsManager.ObjectContactInformation(LegalEntityIndividual, 
				Catalogs.ContactInformationKinds.EmailCompanies,
				PeriodDate_);
			
		ElsIf TypeOf(LegalEntityIndividual) = Type("CatalogRef.Counterparties") Then
			Attributes = PartnersAndCounterparties.CounterpartyDetails_(LegalEntityIndividual, PeriodDate_);
			If Not ValueIsFilled(BankAccount) Then
				BankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(LegalEntityIndividual);
			EndIf;
			AccountAttributes = Catalogs.CounterpartyBankAccounts.GetBankAccountDetails(BankAccount);
			Email = ContactsManager.ObjectContactInformation(LegalEntityIndividual, 
				Catalogs.ContactInformationKinds.EmailCounterparty_,
				PeriodDate_);
		EndIf;

		InformationRecords.Insert("Presentation", 				 Attributes.Presentation);
		InformationRecords.Insert("NameAbbreviated", 	 Attributes.Presentation);
		InformationRecords.Insert("FullDescr", 		 Attributes.Description);
		InformationRecords.Insert("NameForPrintedForms", Attributes.Description);
		InformationRecords.Insert("DescriptionInternational",   Attributes.DescriptionInternational);
		InformationRecords.Insert("LegalEntityIndividual", 					 Attributes.LegalEntityIndividual);
		InformationRecords.Insert("FullNameOfIndividual_", 				 "");
		InformationRecords.Insert("TIN", 						 Attributes.TIN);
		
		If TypeOf(LegalEntityIndividual) = Type("CatalogRef.Companies") Then
			InformationRecords.Insert("OfficialName", Attributes.DescriptionFull);
			InformationRecords.Insert("CertificateOfOwnership", 			 Attributes.CertificateOfOwnership);
			If Attributes.LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur
				Or Attributes.LegalEntityIndividual = Enums.LegalEntityIndividual.Person Then
				FullNameOfIndividual_ = PersonsTM.FullName(Attributes.IndividualEntrepreneur, PeriodDate_);
				FullNameOfIndividual_1 = ?(IsBlankString(FullNameOfIndividual_.LastName), "", FullNameOfIndividual_.LastName
					+ ?(IsBlankString(FullNameOfIndividual_.Name), "", " " + FullNameOfIndividual_.Name
					+ ?(IsBlankString(FullNameOfIndividual_.MiddleName), "", " " + FullNameOfIndividual_.MiddleName)));
				InformationRecords.Insert("FullNameOfIndividual_", FullNameOfIndividual_1);
			EndIf;
		Else
			InformationRecords.Insert("OfficialName", Attributes.Description);
			InformationRecords.Insert("CertificateOfOwnership", 			 "");
		EndIf;
		
		InformationRecords.Insert("Phones", 		  PrintFormGeneration.GetPhoneNumberFromContactInformation(LegalEntityIndividual));
		InformationRecords.Insert("Email", PrintFormGeneration.GetEmailFromContactInformation(LegalEntityIndividual));

		InformationRecords.Insert("LegalAddress", GetAddressFromContactInformation(LegalEntityIndividual, "Legal", PeriodDate_));
		InformationRecords.Insert("ActualAddress", GetAddressFromContactInformation(LegalEntityIndividual, "Actual", PeriodDate_));
		InformationRecords.Insert("International_Address", GetAddressFromContactInformation(LegalEntityIndividual, "International", PeriodDate_));
		
		PrintManagementLocalization.AddInformationAboutLegalEntity(InformationRecords,Attributes, LegalEntityIndividual, PeriodDate_, CompanyIsMajorTaxpayer);
		
		InformationRecords.Insert("AccountNumber",            AccountAttributes.AccountNumber);
		InformationRecords.Insert("Bank",                  AccountAttributes.Bank);
		InformationRecords.Insert("CorrAccount",              AccountAttributes.CorrAccount);
		InformationRecords.Insert("BankAddress",            AccountAttributes.BankAddress);
		InformationRecords.Insert("Email", Email);
		
		PrintManagementLocalization.AddBankAccountInformation(AccountAttributes, InformationRecords, BankAccount);
		
	EndIf;
	
EndProcedure

// The function finds the current address value in the contact information.
//
// Parameters:
//  Object - CatalogRef - contact information object
//  AddressType - String - type of contact information
//	Date - Date - The date on which to get the legal address of the organization. If the parameter is empty 
//                   , the current address will be received. For other types of addresses, you don't need to fill in this parameter.
//
// Returns:
//  String - representation of the found address.
//
Function GetAddressFromContactInformation(Object, AddressType = "", Date = Undefined) Export
	
	Address = "";
	ContactInformationKind = "Address";
	
	If ValueIsFilled(Object) Then
		
		If AddressType = "Actual" Then
			If TypeOf(Object) = Type("CatalogRef.Companies") Then
				ContactInformationKind = "ActualDataAddressOfCompany";
			ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
				ContactInformationKind = "ActualDataCounterpartyAddress";
			ElsIf TypeOf(Object) = Type("CatalogRef.Partners") Then
				ContactInformationKind = "PartnerSEmailAddress_";
			ElsIf TypeOf(Object) = Type("CatalogRef.Warehouses") Then
				ContactInformationKind = "FactWarehouseAddress";
			Else
				PrintManagementLocalization.GetTypeOfContactInformation(
					Object, AddressType, ContactInformationKind);
			EndIf;
		ElsIf AddressType = "Registrations" Or AddressType = "Legal" Then
			If TypeOf(Object) = Type("CatalogRef.Companies") Then
				ContactInformationKind = "LegalAddressOfCompany";
			ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
				ContactInformationKind = "LegalAddressOfCounterparty";
			ElsIf TypeOf(Object) = Type("CatalogRef.Partners") Then
				ContactInformationKind = "PartnerSLegalEntityAddress";
			ElsIf TypeOf(Object) = Type("CatalogRef.Warehouses") Then
				ContactInformationKind = "LegalEntityWarehouseAddress";
			Else
				PrintManagementLocalization.GetTypeOfContactInformation(
					Object, AddressType, ContactInformationKind);
			EndIf;
		ElsIf AddressType = "International" Then
			If TypeOf(Object) = Type("CatalogRef.Companies") Then
				ContactInformationKind = "InternationalAddressOfCompany";
			ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
				ContactInformationKind = "InternationalAddressOfCounterparty";
			EndIf;
		Else
			If TypeOf(Object) = Type("CatalogRef.Companies") Then
				ContactInformationKind = "OrganizationAddress";
			ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
				ContactInformationKind = "CounterpartyAddress";
			ElsIf TypeOf(Object) = Type("CatalogRef.Partners") Then
				ContactInformationKind = "PartnerAddress";
			ElsIf TypeOf(Object) = Type("CatalogRef.Warehouses") Then
				ContactInformationKind = "WarehouseAddress";
			Else
				PrintManagementLocalization.GetTypeOfContactInformation(
					Object, AddressType, ContactInformationKind);
			EndIf;
		EndIf;
		
		AddressKind = Common.ObjectAttributeValue(
			Catalogs.ContactInformationKinds[ContactInformationKind], "Ref");
		
		Address = ContactsManager.ObjectContactInformation(Object, AddressKind, Date);
		
	EndIf;
	
	Return Address;
	
EndFunction

// The function finds the current phone number value in the contact information.
//
// Parameters:
//  Object - CatalogRef - contact information object.
//
// Returns:
//  String - representation of the found phone.
//
Function GetPhoneNumberFromContactInformation(Object) Export

	If ValueIsFilled(Object) Then
	
		If TypeOf(Object) = Type("CatalogRef.Companies") Then
			Name = "CompanyPhone";
		ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
			Name = "CounterpartySPhoneNumber";
		ElsIf TypeOf(Object) = Type("CatalogRef.Partners") Then
			Name = "PartnerSPhoneNumber";
		ElsIf TypeOf(Object) = Type("CatalogRef.Warehouses") Then
			Name = "WarehousePhone";
		EndIf;
		
		PhoneType = Common.ObjectAttributeValue(Catalogs.ContactInformationKinds[Name], "Ref");
		
		Return ContactsManager.ObjectContactInformation(Object, PhoneType, CurrentSessionDate());
		
	EndIf;
	
	Return "";
	
EndFunction

// The function finds the current email value in the contact information.
//
// Parameters:
//  Object - CatalogRef - contact information object.
//
// Returns:
//  String - representation of the found email.
//
Function GetEmailFromContactInformation(Object) Export

	If ValueIsFilled(Object) Then
		
		Ending = "";
		If TypeOf(Object) = Type("CatalogRef.Companies") Then
			Ending = "Companies";
		ElsIf TypeOf(Object) = Type("CatalogRef.Counterparties") Then
			Ending = "Counterparty_";
		ElsIf TypeOf(Object) = Type("CatalogRef.Partners") Then
			Ending = "Partner_";
		EndIf;
		
		If ValueIsFilled(Ending) Then
			CIKind = Common.ObjectAttributeValue(Catalogs.ContactInformationKinds["Email" + Ending], "Ref");
			Return ContactsManager.ObjectContactInformation(Object, CIKind, CurrentSessionDate());
		EndIf;
		
	EndIf;
	
	Return "";
	
EndFunction

// APK:142-off is an implementation feature.
// The sum formatting function is standard for this configuration
//
// Parameters: 
//  Sum  - Number - the number we want to format, 
//  Currency - CatalogRef.Currencies - link to the directory item of currency, if set, then in the result string
//           will be added to the presentation currency
//  NZ     - String - a string representing the null value of a number,
//  NGS    - String - character-separator for groups of the integer part of the number.
//  LanguageCode - String - Name of the language and country for which the number will be formatted
//
// Returns:
//  String - properly formatted string representation of the sum.
//
Function SumFormat(Val Sum, Currency = Undefined, NZ = "", NGS = "", LanguageCode = Undefined) Export
	
	FormatString = "NFD=2"
					+ ?(Not ValueIsFilled(NZ), "", ";" + "NZ=" + NZ)
					+ ?(Not ValueIsFilled(NGS),"", ";" + "NGS=" + NGS)
					+ ?(Not ValueIsFilled(LanguageCode),"", ";" + "L=" + LanguageCode);
	ResultingLine = TrimL(Format(Sum, FormatString));
	
	If ValueIsFilled(Currency) Then
		ResultingLine = ResultingLine + " " + TrimR(Currency);
	EndIf;

	Return ResultingLine;

EndFunction // FormatSumm()
// APK:142-on

// Formats the amount of the Bank payment document.
//
// Parameters:
//  Sum - Number - The amount that you want to format.
//  OutputAmountWithoutFractionalPart - Boolean - Flag for representing the amount without kopecks.
//
// Returns:
//  String - Formatted string.
//
Function AmountOfPaymentDocument(Sum, OutputAmountWithoutFractionalPart) Export
	
	Result  = Sum;
	IntegerPart = Int(Sum);
	
	If Result = IntegerPart Then
		
		If OutputAmountWithoutFractionalPart Then
			
			Result = Format(Result, "NFD=2; NDS='='; NG=0");
			Result = Left(Result, StrFind(Result, "="));
			
		Else
			
			Result = Format(Result, "NFD=2; NDS='-'; NG=0");
			
		EndIf;
		
	Else
		
		Result = Format(Result, "NFD=2; NDS='-'; NG=0");
		
	EndIf;
	
	Return Result;
	
EndFunction // The sum of the payment document()

// The function forms a representation of the amount in rubles and kopecks.
//
// Parameters:
//  Sum - Number - The amount that you want to format.
//  Currency - CatalogRef.Currencies - the currency in which to submit the amount.
//  LocalAccountingCurrency - CatalogRef.Currencies - Currency of regulated accounting.
//
// Returns:
//  String - Formatted amount.
//
Function AmountRubCop(Sum, Currency, LocalAccountingCurrency) Export
	
	If Currency = LocalAccountingCurrency Then
		Rubles = Int(Sum);
		Pennies = Round(100 * (Sum - Rubles), 0, 1);
		AmountRubCop = "" 
			+ Format(Rubles, "NFD=0; NG=0")
			+ " rub. " 
			+ Int(Pennies /10) 
			+ (Pennies - 10 * Int(Pennies / 10))
			+" cop."
		;
	Else
		AmountRubCop = AmountOfPaymentDocument(Sum, False);
	EndIf;
	
	Return AmountRubCop;
	
EndFunction // SummaRubKop()

// The function returns a structure with the Discount or mark-Up headers for the print form table,
// as well as the have Discounts and only mark-Up flags.
// 
// Parameters:
//  Goods 	- ValueTable - tabular part of the document 
//  UseDiscounts 	- Boolean - Indicates whether the discount is being used.
//
// Returns:
//   Structure - Discount Parameters:
//       * Discount 			- String - Text for the discount (mark-up).
//       * DiscountAmount    	- String - Text for the amount.
//       * ThereAreDiscounts   	- Boolean - Indicates whether there is a discount or mark-up.
//       * OnlyMarkUp 	- Boolean - Indicates that there is only a mark-up.
//
Function YouNeedToDisplayDiscounts(Val Goods, UseDiscounts) Export
	
	ThereAreMargins = False;
	ThereAreDiscounts  = False;
	
	HeaderStructure_ = New Structure("Discount, DiscountAmount, ThereAreDiscounts, OnlyMarkUp");
	
	If UseDiscounts Then
		
		If TypeOf(Goods) = Type("ValueTable") Or TypeOf(Goods) = Type("Array") Then
			
			For Each RowOfGoods In Goods Do
				If RowOfGoods.DiscountAmount>0 Then
					ThereAreDiscounts = True;
					Break;
				EndIf;
			EndDo;
			
			For Each RowOfGoods In Goods Do
				If RowOfGoods.DiscountAmount<0 Then
					ThereAreMargins = True;
					Break;
				EndIf;
			EndDo;
		
		ElsIf TypeOf(Goods) = Type("QueryResultSelection") Then
			
			While Goods.Next() Do
				If Goods.DiscountAmount>0 Then
					ThereAreDiscounts = True;
				ElsIf Goods.DiscountAmount<0 Then
					ThereAreMargins = True;
				EndIf;
			EndDo;
			
		EndIf;
		
		If ThereAreMargins And ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Chiết khấu (Phụ thu)';
													|ru = 'Скидка (Наценка)';
													|en = 'Discount (markup)'; fa = 'تخفیف (افزایش قیمت)';
													|it = 'Sconto (sovrapprezzo)';
													|pl = 'Rabat (marża)';
													|tr = 'İndirim (zam)'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode())
				+ Chars.LF + NStr("vi = 'không có chiết khấu (phụ thu)';
									|ru = 'без скидки (наценки)';
									|en = 'without discount (markups)'; fa = 'without discount (markups)';
									|it = 'senza sconto (sovrapprezzo)';
									|pl = 'bez zniżek (dopłata)';
									|tr = 'indirim/zam olmadan'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("OnlyMarkUp", False);
		ElsIf ThereAreMargins And Not ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Phụ thu';
													|ru = 'Наценка';
													|en = 'Markup'; fa = 'افزایش قیمت';
													|it = 'Sovrapprezzo';
													|pl = 'Marża';
													|tr = 'Marj'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode())
				+ Chars.LF + NStr("vi = 'không có phụ thu';
									|ru = 'без наценки';
									|en = 'without markup'; fa = 'without markup';
									|it = 'senza sovrapprezzo';
									|pl = 'bez dodatkowych opłat';
									|tr = 'zam olmadan'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("OnlyMarkUp", True);
		ElsIf ThereAreDiscounts Then
			HeaderStructure_.Insert("Discount", NStr("vi = 'Chiết khấu';
													|ru = 'Скидка';
													|en = 'Discount'; fa = 'تخفیف';
													|it = 'Sconto';
													|pl = 'Rabat';
													|tr = 'İndirim'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("DiscountAmount", NStr("vi = 'Tổng số';
															|ru = 'Сумма';
															|en = 'Amount'; fa = 'مبلغ';
															|it = 'Importo';
															|pl = 'Wartość';
															|tr = 'Tutar'", Common.DefaultLanguageCode())
				+ Chars.LF + NStr("vi = 'không có chiết khấu';
									|ru = 'без скидки';
									|en = 'without discount'; fa = 'without discount';
									|it = 'senza sconto';
									|pl = 'bez zniżek';
									|tr = 'indirim olmadan'", Common.DefaultLanguageCode()));
			HeaderStructure_.Insert("OnlyMarkUp", False);
		EndIf;
	EndIf;
	
	HeaderStructure_.Insert("ThereAreDiscounts", ThereAreMargins Or ThereAreDiscounts);

	Return HeaderStructure_;

EndFunction // Need to get rid of the throws()

// The function checks that the item line is filled
// in and returns a message if it is not filled in.
// 
// Parameters:
//  LineProducts_ 	- ValueTableRow - String of the table part of the document 
//  LineNumber 	- Number - Number of the line to be passed from the PM document.
//
// Returns:
//  Boolean - The result of the check.
//
Function CheckFillingInProducts(LineProducts_, LineNumber) Export
	
	If Not ValueIsFilled(LineProducts_.Products) Then
		
		ErrorText = NStr("vi = 'Trong dòng %LineNumber% không điền giá trị mặt hàng - bỏ qua dòng khi in.';
						|ru = 'В строке %LineNumber% не заполнено значение номенклатуры - строка при печати пропущена.';
						|en = 'Item value is required in line %LineNumber%. Skipped the line when printing.'; fa = 'Item value is required in line %LineNumber%. Skipped the line when printing.';
						|it = 'Nella riga %LineNumber% non è compilato il valore dell''articolo - manca la riga durante la stampa.';
						|pl = 'W wierszu %LineNumber% nie jest wypełnione znaczenie nomenklatury - wiersz podczas druku pominięty.';
						|tr = 'Öğe değeri %LineNumber% satırına doldurulmadı - yazdırma sırasında satır atlandı.'");
		ErrorText = StrReplace(ErrorText, "%LineNumber%", LineNumber);
		CommonClientServer.MessageToUser(ErrorText);
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction // Check the filling of the Nomenclature()

// Generates the VAT rate text for the printed invoice and order form
//
// Parameters:
//  VATRate       - CatalogRef.VATRates - the VAT rate to generate the text for
//  PriceIncludesVAT - Boolean - Indicates whether VAT is included in the price.
//
// Returns:
//  String - line.
//
Function VATRateText(VATRate, PriceIncludesVAT) Export
	
	VATRateText = ?(PriceIncludesVAT, NStr("vi = 'Trong đó thuế GTGT (%VATRate%):';
											|ru = 'В т.ч. НДС (%VATRate%):';
											|en = 'Including VAT (%VATRate%):'; fa = 'Including VAT (%VATRate%):';
											|it = 'Inclusa IVA (%VATRate%):';
											|pl = 'W tym VAT (%VATRate%):';
											|tr = 'KDV dahil (%VATRate%):'"), NStr("vi = 'Thuế GTGT (%VATRate%):';
																						|ru = 'НДС (%VATRate%):';
																						|en = 'VAT (%VATRate%):'; fa = 'VAT (%VATRate%):';
																						|it = 'IVA (%VATRate%):';
																						|pl = 'VAT (%VATRate%):';
																						|tr = 'KDV (%VATRate%):'"));
	VATRateText = StrReplace(VATRateText, "%VATRate%", VATRate);
	
	Return VATRateText;
	
EndFunction // Text in Delivery()

// Creates a match between VAT rates and amounts
//
// Returns:
//  Map - compliance of VAT rates and amounts.
//
Function ComplianceOfVATRatesAndAmounts() Export
	
	ComplianceWithVATRates = New Map();
	
	VATRates = Catalogs.VATRates.Select();
	
	While VATRates.Next() Do
		If Not VATRates = PredefinedValue("Catalog.VATRates.EXCLUDINGVAT") Then
			ComplianceWithVATRates.Insert(VATRates, 0);
		EndIf;
	EndDo;
	
	Return ComplianceWithVATRates;
	
EndFunction // Get the corresponding Windows()

// Generates the VAT text for the payment stage
//
// Parameters:
//  ComplianceWithVATRates - Map - compliance obtained through functions of Politicoadministrative()
//  PaymentPercentage       - Number - A percentage of the payment stage.
//
// Returns:
//  String - VAT text.
//
Function GenerateTextOfVATPaymentStage(ComplianceWithVATRates, PaymentPercentage) Export
	
	VATText = "";
	
	If ComplianceWithVATRates.Count() > 0 Then
		
		For Each CurVATRate In ComplianceWithVATRates Do
			
			If CurVATRate.Value <> 0 Then
				
				VATText = VATText + ?(IsBlankString(VATText), NStr("vi = 'Thuế GTGT(%VATRate%) %VATAmount%';
																	|ru = 'НДС(%VATRate%) %VATAmount%';
																	|en = 'VAT(%VATRate%) %VATAmount%'; fa = 'VAT(%VATRate%) %VATAmount%';
																	|it = 'IVA(%VATRate%) %VATAmount%';
																	|pl = 'VAT(%VATRate%) %VATAmount%';
																	|tr = 'KDV(%VATRate%) %VATAmount%'"), NStr("vi = ', thuế GTGT(%VATRate%) %VATAmount%';
																												|ru = ', НДС(%VATRate%) %VATAmount%';
																												|en = ', VAT(%VATRate%) %VATAmount%'; fa = ', VAT(%VATRate%) %VATAmount%';
																												|it = ', IVA(%VATRate%) %VATAmount%';
																												|pl = ', VAT(%VATRate%) %VATAmount%';
																												|tr = ', KDV(%VATRate%) %VATAmount%'"));
				VATText = StrReplace(VATText, "%VATRate%", CurVATRate.Key);
				VATText = StrReplace(VATText, "%VATAmount%",  Format(CurVATRate.Value / 100 * PaymentPercentage, "NFD=2"));
			
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If ValueIsFilled(VATText) Then
		VATText = NStr("vi = 'trong đó';
						|ru = 'В т.ч.';
						|en = 'Including'; fa = 'شامل';
						|it = 'Incl.';
						|pl = 'W tym';
						|tr = 'Tablo bölümünde'") + " " + VATText;
	Else
		VATText = NStr("vi = 'Không thuế (GTGT)';
						|ru = 'Без налога (НДС)';
						|en = 'Without tax (VAT)'; fa = 'بدون مالیات (مالیات بر ارزش افزوده)';
						|it = 'senza imposta (IVA)';
						|pl = 'bez podatku (VAT)';
						|tr = 'Vergisiz (KDV)'");
	EndIf;
	
	Return VATText;
	
EndFunction // Form the text of this Payment step()

// Generates a string description of the validity period
//
// Parameters:
// 		ValidityStartDate - Date - Start date
// 		ValidityEndDate - Date - Expiration date.
//
// Returns:
// 		String - String description of the validity period.
//
Function GenerateTextValidityPeriod(ValidityStartDate, ValidityEndDate) Export
	
	DateEmpty = Date(1,1,1);
	
	If ValidityStartDate = DateEmpty And ValidityEndDate = DateEmpty Then
		
		Return NStr("vi = 'Thời hạn hiệu lực không hạn chế';
					|ru = 'Срок действия не ограничен.';
					|en = 'Validity is unlimited.'; fa = 'Validity is unlimited.';
					|it = 'Validità illimitata.';
					|pl = 'Czas trwania nie jest ograniczony.';
					|tr = 'İşlem süresi sınırlı değil.'");
		
	ElsIf  ValidityStartDate <> DateEmpty And ValidityEndDate = DateEmpty Then
		
		Return  StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hiệu lực từ %1.';
				|ru = 'Действует с %1.';
				|en = 'Valid from %1.'; fa = 'Valid from %1.';
				|it = 'In vigore dal %1.';
				|pl = 'Ważny od %1.';
				|tr = '%1 tarihinden geçerlidir.'"),
			Format(ValidityStartDate,"DLF=DD"));
		
	ElsIf ValidityStartDate = DateEmpty And ValidityEndDate <> DateEmpty Then
		
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Có hiệu lực đến %1.';
				|ru = 'Действует по %1.';
				|en = 'Valid until %1.'; fa = 'Valid until %1.';
				|it = 'In vigore al %1';
				|pl = 'Ważny do %1.';
				|tr = '%1 kadar geçerlidir.'"),
			Format(ValidityEndDate,"DLF=DD"));
		
	Else
		
		Return StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hiệu lực từ %1 đến %2.';
				|ru = 'Действует с %1 по %2.';
				|en = 'Valid from %1 to %2.'; fa = 'Valid from %1 to %2.';
				|it = 'In vigore dal %1 al %2';
				|pl = 'Ważny od %1 do %2.';
				|tr = '%1 tarihinden %2 kadar geçerlidir.'"),
			Format(ValidityStartDate,"DLF=DD"),
			Format(ValidityEndDate,"DLF=DD"));
		
	EndIf;
	
EndFunction // Form the text of the action period()

// Generates the VAT text
//
// Parameters:
//  VATTaxation  - String - Type name Nalogooblozhenija for which you want to generate the text
//  PriceIncludesVAT 	- Boolean - Indicates whether VAT is included in the price.
//
// Returns:
//  String - the generated text.
//
Function GenerateVATText(VATTaxation, PriceIncludesVAT)Export
	
	If IsBlankString(VATTaxation) Then
		Return ?(PriceIncludesVAT, NStr("vi = 'Đơn giá gồm thuế GTGT.';
										|ru = 'Цена включает НДС.';
										|en = 'Price includes VAT.'; fa = 'Price includes VAT.';
										|it = 'Цена включает НДС.';
										|pl = 'Price includes VAT.';
										|tr = 'Fiyata KDV dahildir.'"), NStr("vi = 'Đơn giá không gồm thuế GTGT.';
																			|ru = 'Цена не включает НДС.';
																			|en = 'Price excludes VAT.'; fa = 'Price excludes VAT.';
																			|it = 'Цена не включает НДС.';
																			|pl = 'Price excludes VAT.';
																			|tr = 'KDV hariç fiyat.'"));
	Else
		Return VATTaxation
			+ ?(PriceIncludesVAT, NStr("vi = '. Giá đã có thuế GTGT.';
										|ru = '. Цена включает НДС.';
										|en = '. Price includes VAT.'; fa = '. Price includes VAT.';
										|it = '. Il prezzo include l''IVA.';
										|pl = '. Cena zawiera VAT.';
										|tr = '. Fiyata KDV dahildir.'"), NStr("vi = '. Giá chưa có thuế GTGT.';
																			|ru = '. Цена не включает НДС.';
																			|en = '. Price excludes VAT.'; fa = '. Price excludes VAT.';
																			|it = '. Il prezzo non include l''IVA.';
																			|pl = '. Cena nie zawiera VAT.';
																			|tr = '. KDV hariç fiyat.'"));
	EndIf;
	
EndFunction // Form textnds()

// Fills in the structure of parameters for possible recipients of printed forms when sending by email.
//
// Parameters:
// 		SendOptions - Structure - contains parameters for sending generated print forms
// 		PrintObjectData - Array,Map - data on the printing objects
// 		PrintFormsCollection - ValueTable - contains information about the generated print forms.
//
Procedure FillInSendingParameters(SendOptions, PrintObjectData, PrintFormsCollection)  Export
	
	If Not EmailOperations.AvailableEmailAccounts(True).Count() > 0 Then
		Return;
	EndIf;
	
	If TypeOf(PrintObjectData) = Type("Array") Then
		MatchingPrintObjectDataTypes = TMCommonUse.MatchingArraysByObjectType(PrintObjectData);
	Else
		MatchingPrintObjectDataTypes = PrintObjectData;
	EndIf;
	
	MatchingPrintObjectDataTypes = CompleteCorrespondenceOfThesePrintObjects(MatchingPrintObjectDataTypes);
	
	If Not FillingInSendingParametersIsPossible(MatchingPrintObjectDataTypes) Then
		Return;
	EndIf;
	
	FillRecipients(MatchingPrintObjectDataTypes, SendOptions, PrintFormsCollection);
	
EndProcedure

// Displays the logo in a tabular document. If there is no logo image in the passed layout area
// , there is a separate area with the logo in the layout and the logo is displayed
// in this area.
//
// Parameters:
// 		Template - SpreadsheetDocument - Layout of the printed form
// 		TemplateArea - TextDocument - The layout of the printed form
// 		AreaName - String - Name of the transmitted area
// 		Organization - CatalogRef.Companies - Contains a link to the organization to get the logo.
//
Procedure PrintLogoInTabularDocument(Template, TemplateArea, AreaName, Organization)Export
	
	PicturesFile = Common.ObjectAttributeValue(Organization, "Logo");
	
	If Not TMCommonUseClientServer.HasObjectAttribute(TemplateArea.Drawings, "Logo") Then
		// There is no logo image in this area of the layout.
		
		If Template.Areas.Find(AreaName) <> Undefined Then
			
			// Checking the logo image in the area with the logo
			LogoTemplateArea = Template.GetArea(AreaName);
			If TMCommonUseClientServer.HasObjectAttribute(LogoTemplateArea.Drawings, "Logo") 
				And ValueIsFilled(PicturesFile) Then
				
				TemplateArea = LogoTemplateArea;
			Else
				Return;
			EndIf;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(PicturesFile) Then
		TemplateArea.Drawings.Delete(TemplateArea.Drawings.Logo);
		Return;
	EndIf;
	
	FileBinaryData = FilesOperations.FileBinaryData(PicturesFile);
	
	If TypeOf(FileBinaryData) = Type("Picture") Then
		Picture = FileBinaryData;
	ElsIf TypeOf(FileBinaryData) = Type("BinaryData") Then
		Picture = New Picture(FileBinaryData);
	Else
		Picture = New Picture;
	EndIf; 
	
	TemplateArea.Drawings.Logo.Picture = Picture;
	
EndProcedure

// Outputs a facsimile to a table document, replacing the passed area with a facsimile image.
//
// Parameters:
// 		Template - SpreadsheetDocument - Layout of the printed form
// 		TemplateArea - TextDocument - The layout of the printed form
// 		Organization - CatalogRef.Companies - Contains a link to the organization to receive the facsimile
// 		PrintParameters - Structure - Contains the structure of print parameters.
//
Procedure OutputFacsimileToTabularDocument(Template, TemplateArea, Organization, PrintParameters = Undefined) Export
	
	DisplayFacsimiles = False;
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayFacsimiles") Then
		DisplayFacsimiles = PrintParameters.DisplayFacsimiles;
	EndIf;
	
	If Not DisplayFacsimiles Then
		Return
	EndIf;
	
	PicturesFile = Common.ObjectAttributeValue(Organization, "FacsimileStamp");
	
	If DisplayFacsimiles And Not ValueIsFilled(PicturesFile) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chỉ ra dấu chữ ký cho doanh nghiệp. 
			|Hãy chỉ ra tệp có dấu chữ ký trên thẻ doanh nghiệp, phân hệ ""Tùy chỉnh in"".';
			|ru = 'Факсимиле для организации не указано. 
			|Укажите файл с факсимиле в карточке организации, раздел ""Настройка печати"".';
			|en = 'Facsimile is not specified for the company.
			|Specify the file with facsimile in the company profile, section ""Print settings"".'; fa = 'Facsimile is not specified for the company.
			|Specify the file with facsimile in the company profile, section ""Print settings"".';
			|it = 'Facsimile per l''azienda non indicato. 
			| Indicare file con facsimile nella scheda dell''azienda, sezione ""Impostazione di stampa"".';
			|pl = 'Faks dla firmy nie jest określony. 
			|Określ plik za pomocą telefaksu na karcie firmy, sekcja ""Ustawienia drukowania"".';
			|tr = 'İş yeri için kaşe belirtilmedi. 
			|İş yeri kartı, ""Yazdırma ayarı"" bölümünde kaşe dosyası belirt.'"));
	EndIf;
	
	If Not TMCommonUseClientServer.HasObjectAttribute(TemplateArea.Drawings, "Facsimile") Then
		// There is no facsimile image in this area of the layout.
		
		If Template.Areas.Find("FacsimileArea") <> Undefined Then
			
			// Check the facsimile image in the "Facsimile area"
			FacsimileTemplateArea = Template.GetArea("FacsimileArea");
			If TMCommonUseClientServer.HasObjectAttribute(FacsimileTemplateArea.Drawings, "Facsimile")
				And ValueIsFilled(PicturesFile) Then
				
				TemplateArea = FacsimileTemplateArea;
			Else
				Return;
			EndIf;
		Else
			Return;
		EndIf;
		
	EndIf;
	
	If Not ValueIsFilled(PicturesFile) Then
		TemplateArea.Drawings.Delete(TemplateArea.Drawings.Facsimile);
		Return;
	EndIf;
	
	FileBinaryData = FilesOperations.FileBinaryData(PicturesFile);
	
	If TypeOf(FileBinaryData) = Type("Picture") Then
		Picture = FileBinaryData;
	ElsIf TypeOf(FileBinaryData) = Type("BinaryData") Then
		Picture = New Picture(FileBinaryData);
	Else
		Picture = New Picture;
	EndIf; 
	
	TemplateArea.Drawings.Facsimile.Picture = Picture;
	
EndProcedure

// Standard formatting function for the quantity register
//
// Parameters:
//  Count - Number - the number that you want to format.
//
// Returns:
//  String - properly formatted string representation of the quantity.
//
Function QuantityInWords(Count) Export

	IntegerPart   = Int(Count);
	FractionalPart = Round(Count - IntegerPart, 3);

	If FractionalPart = Round(FractionalPart,0) Then
		AmountInWordsParameters = ", , , , , , , , 0";
	ElsIf FractionalPart = Round(FractionalPart, 1) Then
		AmountInWordsParameters = "whole, whole_, whole_, railroad, tenth, tenths, tenths, m, 1";
	ElsIf FractionalPart = Round(FractionalPart, 2) Then
		AmountInWordsParameters = "whole, whole_, whole_, railroad, hundredth, hundredths, hundredths, m, 2";
	Else
		AmountInWordsParameters = "whole, whole_, whole_, railroad, thousandth, thousandths, thousandths, m, 3";
	EndIf;

	Return NumberInWords(Count, ,AmountInWordsParameters);

EndFunction

#EndRegion

#Region Private

#Region FormationOfParametersForSendingPrintedFormsByEMail

Procedure FillRecipients(MatchingPrintObjectDataTypes, SendOptions, PrintFormsCollection) 
	
	ArrayOfParentsDocuments = New Array;
	
	CreateSubjectAndText(MatchingPrintObjectDataTypes, SendOptions, PrintFormsCollection, ArrayOfParentsDocuments);
	GenerateSendOptions(MatchingPrintObjectDataTypes, SendOptions, ArrayOfParentsDocuments);
	
EndProcedure

Procedure CreateSubjectAndText(MatchingPrintObjectDataTypes, SendOptions, PrintFormsCollection, ArrayOfParentsDocuments)
	
	Query = New Query;
		
	Counter = 1;
	NumberOfElementsAccordingTo = MatchingPrintObjectDataTypes.Count();
		
	For Each MapItem In MatchingPrintObjectDataTypes Do
		
		RequestTextForMatchElement = "
		|SELECT DISTINCT ALLOWED
		|	MetadataObject.Presentation AS PresentationOfPrintObject,
		|	MetadataObject.Ref AS ReferenceToPrintingObject,
		|	&SynonymForMetadataObject AS SynonymForMetadataObject,
		|	&DocumentNumber AS DocumentNumber,
		|	&DocumentDate AS DocumentDate
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Ref IN (&ReferencesArrray) 
		|
		|AND &UnionAll
		|";
		
		Query.SetParameter("ReferencesArrray_" + String(Counter), MapItem.Value.DataArray);
		Query.SetParameter("SynonymForMetadataObject_" + String(Counter),Metadata.FindByFullName(MapItem.Key).Synonym);
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&ReferencesArrray", "&ReferencesArrray_" + String(Counter));
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&SynonymForMetadataObject", "&SynonymForMetadataObject_" + String(Counter));
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&MetadataObject", MapItem.Key);
		
		If Counter > 1 Then
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "ALLOWED", "");
		EndIf;
		
		If StrFind(MapItem.Key,"Document") > 0 Then
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&DocumentNumber", "MetadataObject.Number");
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&DocumentDate", "MetadataObject.Date");
		Else
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&DocumentNumber", "NULL");
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&DocumentDate", "NULL");
		EndIf;
		
		If Counter = NumberOfElementsAccordingTo Then
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "AND &UnionAll", "");
		Else
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "AND &UnionAll", "UNION ALL");
		EndIf;
		
		Counter = Counter + 1;
		
		Query.Text = Query.Text + RequestTextForMatchElement;
		
	EndDo;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	If PrintFormsCollection.Count() = 1 Then
		SendOptions.Subject = PrintFormsCollection[0].TemplateSynonym;
		
	Else 
		SendOptions.Subject = NStr("vi = 'Chứng từ';
									|ru = 'Документы';
									|en = 'Documents'; fa = 'اسناد';
									|it = 'Documenti';
									|pl = 'Documents';
									|tr = 'Belgeler'");
	EndIf;
	
	SendOptions.Text = NStr("vi = 'Trong mẫu in lồng trong.';
							|ru = 'Во вложении печатные формы.';
							|en = 'Print forms attached.'; fa = 'Print forms attached.';
							|it = 'In allegato i moduli di stampa.';
							|pl = 'Załączone są drukowane formularze.';
							|tr = 'Yazdırma formlarında iç içe.'") + Chars.LF;
	
	Selection = Result.Select();
	
	For Each PrintForm In PrintFormsCollection Do
		SendOptions.Text = SendOptions.Text + "   " + PrintForm.TemplateSynonym + Chars.LF;
	EndDo;
	
	SendOptions.Text = SendOptions.Text + NStr("vi = 'Đối với chứng từ:';
												|ru = 'Для документов:';
												|en = 'For documents:'; fa = 'For documents:';
												|it = 'Per i documenti:';
												|pl = 'W przypadku dokumentów:';
												|tr = 'Belgeler için:'") + Chars.LF;
	
	While Selection.Next() Do
		SendOptions.Text = SendOptions.Text + "   " + PresentationOfPrintObject(Selection, True) + Chars.LF;
		GetParentDocuments(ArrayOfParentsDocuments,Selection.ReferenceToPrintingObject);
	EndDo;
	
EndProcedure

Procedure AddRecipientOfPrintedForm(Recipients, RecipientData, Explanation = "") Export
	
	If Not ValueIsFilled(RecipientData.Address) Then
		Return;
	EndIf;
	
	For Each PossibleRecipient In Recipients Do
		
		If PossibleRecipient.EmailAddressKind = String(RecipientData.EmailAddressKind)
			And TrimAll(PossibleRecipient.Address) = TrimAll(RecipientData.Address) Then
			
			Return;
			
		EndIf;
		
	EndDo;
	
	If IsBlankString(Explanation) Then
		Recipient = Undefined;
		For Each Recipient In Recipients Do
			If Recipient.ContactInformationSource = RecipientData.ContactInformationSource Then
				If StrFind(Recipient.Address, RecipientData.Address) = 0 Then
					Recipient.Address = Recipient.Address + "; " + RecipientData.Address;
				EndIf;
				Explanation = PresentationOfPrintObject(RecipientData);
				If StrFind(Recipient.Explanation, Explanation) = 0 Then
					Recipient.Explanation = Recipient.Explanation + ", " + Explanation;
				EndIf;
				Return;
			EndIf;
		EndDo;
		PresentationOfPrintObject = PresentationOfPrintObject(RecipientData);
		Explanation = RecipientData.SynonymForRecipientSBankingDetails + " " 
		            + ?(IsBlankString(PresentationOfPrintObject),"", NStr("vi = 'từ';
																			|ru = 'из';
																			|en = 'from'; fa = 'از';
																			|it = 'da';
																			|pl = 'z';
																			|tr = '-den/dan'")) + " " + PresentationOfPrintObject;
	EndIf;
	
	RecipientStructure = New Structure;
	RecipientStructure.Insert("Address", RecipientData.Address);
	RecipientStructure.Insert("Presentation", RecipientData.RecipientPresentation1);
	RecipientStructure.Insert("ContactInformationSource", RecipientData.ContactInformationSource);
	RecipientStructure.Insert("EmailAddressKind", String(RecipientData.EmailAddressKind));
	RecipientStructure.Insert("Explanation", Explanation);
	RecipientStructure.Insert("SourceObject", RecipientData.ReferenceToPrintingObject);
	
	Recipients.Add(RecipientStructure);
	
EndProcedure

Function PresentationOfPrintObject(RecipientData,TransformDocumentPresentation = False)
	
	RefType = TypeOf(RecipientData.ReferenceToPrintingObject);
	
	If RefType = Type("CatalogRef.CounterpartyContracts") Then
		Return NStr("vi = 'Hợp đồng';
					|ru = 'Договор';
					|en = 'Contract'; fa = 'قرارداد';
					|it = 'Contratto';
					|pl = 'Contract';
					|tr = 'Sözleşme'") + " '" +  RecipientData.PresentationOfPrintObject + "'";
	ElsIf RefType = Type("CatalogRef.TermsOfSale") Then
		Return NStr("vi = 'Thỏa thuận với người mua';
					|ru = 'Соглашение с клиентом';
					|en = 'Customer agreement'; fa = 'توافق‌نامه مشتری';
					|it = 'Accordo con il cliente';
					|pl = 'Umowa z klientem';
					|tr = 'Satış koşulları'") + " '" +  RecipientData.PresentationOfPrintObject + "'";
	ElsIf RefType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		Return NStr("vi = 'Vụ việc với khách hàng';
					|ru = 'Сделка с клиентом';
					|en = 'Sales opportunity'; fa = 'فرصت فروش';
					|it = 'Transazione con il cliente';
					|pl = 'Umowa z klientem';
					|tr = 'Müşteriyle yapılan satış fırsatı'") + " '" +  RecipientData.PresentationOfPrintObject + "'";
	ElsIf RefType = Type("CatalogRef.Partners") Then
		Return "";
	Else
		If TransformDocumentPresentation Then
			
			DocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(RecipientData.DocumentNumber, False, True);
			DocumentDate  = RecipientData.DocumentDate;
			
			PresentationOfDocument = NStr("vi = '%Synonym% Số%Number% ngày %Date%';
											|ru = '%Synonym% №%Number% от %Date%';
											|en = '%Synonym% No.%Number% dated %Date%'; fa = '%Synonym% No.%Number% dated %Date%';
											|it = '%Synonym% №%Number% da %Date%';
											|pl = '%Synonym% nr%Number% od %Date%';
											|tr = '%Date% itibaren %Synonym% №%Number%'");
			PresentationOfDocument = StrReplace(PresentationOfDocument, "%Number%", DocumentNumber);
			PresentationOfDocument = StrReplace(PresentationOfDocument, "%Date%", Format(DocumentDate, "DLF=D"));
			PresentationOfDocument = StrReplace(PresentationOfDocument, "%Synonym%", RecipientData.SynonymForMetadataObject);
			Return PresentationOfDocument;
			
		Else
			Return RecipientData.PresentationOfPrintObject;
		EndIf;
	EndIf;
	
EndFunction 

// Constructor function-creates the data structure of the print object
// 
// Returns:
// 	Structure - consists of:
// * PrimaryRecipient - String - 
// * ArrayOfRecipientDetails - Array of String - 
// * DataArray - Array of AnyRef - 
// 
Function NewPrintObjectDataStructure() Export
	
	Result = New Structure();
	
	Result.Insert("PrimaryRecipient", "");
	Result.Insert("ArrayOfRecipientDetails", New Array);
	Result.Insert("DataArray");
	
	Return Result;
	
EndFunction

Function CompleteCorrespondenceOfThesePrintObjects(MatchingPrintObjectDataTypes)

	AugmentedCompliance = New Map;
	
	For Each MapItem In MatchingPrintObjectDataTypes Do
		
		PrintObjectDataStructure = NewPrintObjectDataStructure();
		PrintObjectDataStructure.DataArray = MapItem.Value;

		FillInRecipientStructureDataByObjectType(MapItem.Key , PrintObjectDataStructure);
		
		AugmentedCompliance.Insert(MapItem.Key, PrintObjectDataStructure);
	
	EndDo;
	
	Return AugmentedCompliance;

EndFunction

// Fills in the objects integrated with the subsystem of formation of printed forms
//
// Parameters:
//  ControlModules - Map of KeyAndValue - Control modules of objects:
//   * Key     - String                        - Full name of the embedded object metadata
//   * Value - CommonModule, DocumentManager - The object in which the logic of integration 
//                                                with the mechanism of formation of printed forms is located
//
// Comment:
//  If the control module is the module of the manager of the corresponding document, 
//  then the matching value can be omitted.
//  If the control module differs from the document manager module, 
//  then a link to the desired module should be specified in the value.
//
// Example 1:
//  The document of the completed works is integrated into the mechanism of the formation of printed forms.
//  The integration methods are located in the module of the document manager of the completed work.
//  Control modules.Insert(Metadata.Documents.Actvperformed works.Fullname());
//
// Example 2:
//  The document of the commercial offer to the client is integrated into the mechanism of formation of printed forms.
//  The integration methods are in the Commercial Clientoute module.
//  Control modules.Insert(Metadata.Documents.Commercial offer to the client.Fullname(), 
//  	Commercial Offer Clientout);
//
// The method to fill in the structure of the recipients of the printed forms will be called in the control module.
Procedure WhenFillingControlModules(ControlModules) Export

	ControlModules.Insert(Metadata.Catalogs.Partners.FullName());
	ControlModules.Insert(Metadata.Catalogs.Complaints.FullName());
	ControlModules.Insert(Metadata.Documents.CustomerInvoiceServices.FullName());
	ControlModules.Insert(Metadata.Documents.DiscrepancyReportFollowingShipment.FullName());
	ControlModules.Insert(Metadata.Documents.DiscrepancyReportFollowingReceipt.FullName());
	ControlModules.Insert(Metadata.Documents.ARAPSettlement.FullName());
	ControlModules.Insert(Metadata.Documents.IntercompanyGoodsReturn.FullName());
	ControlModules.Insert(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ControlModules.Insert(Metadata.Documents.ReturnOfGoodsToVendor.FullName());
	ControlModules.Insert(Metadata.Documents.CommercialProposalForCustomer.FullName(), 
		SalesQuotationTM);
	ControlModules.Insert(Metadata.Documents.SalesOrder.FullName());
	ControlModules.Insert(Metadata.Documents.MaterialProviderOrder2_5.FullName());
	ControlModules.Insert(Metadata.Documents.PurchaseOrder.FullName());
	ControlModules.Insert(Metadata.Documents.SubcontractOrder2_5.FullName());
	ControlModules.Insert(Metadata.Documents.RequestForReturnOfGoodsFromCustomer.FullName());
	ControlModules.Insert(Metadata.Documents.SaleAdjustment.FullName());
	ControlModules.Insert(Metadata.Documents.GoodsShipmentFromStorage.FullName());
	ControlModules.Insert(Metadata.Documents.RedemptionOfGoodsFromStorage.FullName());
	ControlModules.Insert(Metadata.Documents.GoodsReceiptForStorage.FullName());
	ControlModules.Insert(Metadata.Documents.ReceiptOfGoodsFromCustodian.FullName());
	ControlModules.Insert(Metadata.Documents.TransferOfGoodsToBailee.FullName());
	ControlModules.Insert(Metadata.Documents.DamageAtCustodian.FullName());
	ControlModules.Insert(Metadata.Documents.MisgradingOfGoodsAtCustodian.FullName());
	ControlModules.Insert(Metadata.Documents.ConsignmentReportFromCustomer.FullName());
	ControlModules.Insert(Metadata.Documents.WriteOffReportFromCommissionAgent.FullName());
	ControlModules.Insert(Metadata.Documents.ConsignmentReportToVendor.FullName());
	ControlModules.Insert(Metadata.Documents.PurchaseInvoiceConsignmentStockLost.FullName());
	ControlModules.Insert(Metadata.Documents.CommissionReportIntercompany.FullName());
	ControlModules.Insert(Metadata.Documents.CustomerInvoiceIntercompany.FullName());
	ControlModules.Insert(Metadata.Documents.InventoryTransfer.FullName());
	ControlModules.Insert(Metadata.Documents.VendorInvoice.FullName());
	ControlModules.Insert(Metadata.Documents.CashAccountReceiptNote.FullName());
	ControlModules.Insert(Metadata.Documents.CashVoucher.FullName());
	ControlModules.Insert(Metadata.Documents.CustomerInvoice.FullName());
	ControlModules.Insert(Metadata.Documents.CustomerInvoiceServicesAndAssets.FullName());
	ControlModules.Insert(Metadata.Documents.ARAPReconciliation2_4.FullName());
	ControlModules.Insert(Metadata.Documents.ARAPReconciliation2_5_11.FullName());
	ControlModules.Insert(Metadata.Documents.BankAccountIssue.FullName());
	ControlModules.Insert(Metadata.Documents.WriteOffOfShippedGoods.FullName());
	ControlModules.Insert(Metadata.Documents.CustomerCommercialInvoice.FullName());
	ControlModules.Insert(Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.FullName());
	
	PrintManagementLocalization.WhenFillingControlModules(ControlModules);
	
EndProcedure

// Parameters:
// 	FullMetadataObjectName - String - 
// 	PrintObjectDataStructure - Structure - consists of:
// * PrimaryRecipient - String -
// * ArrayOfRecipientDetails - Array of String -
// * DataArray - Array of DocumentRef -
// 
Procedure FillInRecipientStructureDataByObjectType(FullMetadataObjectName, PrintObjectDataStructure) Export
	
	ControlModule = PrintFormGenerationCached.ControlModules().Get(FullMetadataObjectName);
	
	If ControlModule = Undefined Then
		Return;
	EndIf;
	
	ControlModule.FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure);
		
EndProcedure

Function FillingInSendingParametersIsPossible(MatchingPrintObjectDataTypes)
	
	Query = New Query;
	
	Counter = 1;
	ThisIsFirstElementOfQuery = True;
	
	For Each MapItem In MatchingPrintObjectDataTypes Do
		
		If Not ValueIsFilled(MapItem.Value.PrimaryRecipient) Then
			Counter = Counter + 1;
			Continue;
		EndIf;
		
		If Not IsBlankString(Query.Text) Then
		Query.Text = Query.Text  + "
			|
			|UNION ALL
			|";
		EndIf;
		
		RequestTextForMatchElement = "
		|SELECT DISTINCT ALLOWED TOP 2
		|	&AttributeName AS PrimaryRecipient
		|FROM
		|	&MetadataObject AS MetadataObject
		|WHERE
		|	MetadataObject.Ref IN (&ReferencesArrray)
		|";
		
		Query.SetParameter("ReferencesArrray_" + String(Counter), MapItem.Value.DataArray);
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&ReferencesArrray", "&ReferencesArrray_" + String(Counter));
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&MetadataObject", MapItem.Key);
		RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "&AttributeName", "MetadataObject."+MapItem.Value.PrimaryRecipient);
		
		If ThisIsFirstElementOfQuery Then
			ThisIsFirstElementOfQuery = False;
		Else
			RequestTextForMatchElement = StrReplace(RequestTextForMatchElement, "ALLOWED TOP 2", "");
		EndIf;
		
		Counter = Counter + 1;
		
		Query.Text = Query.Text + RequestTextForMatchElement;
		
	EndDo;
	
	// If the main recipients are not specified, then there is no point in sending
	If IsBlankString(Query.Text) Then
		Return False;
	EndIf;
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return False;
	EndIf;
	
	Selection = Result.Select();
	If Selection.Count() = 1 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction 

Procedure GetParentDocuments(ArrayOfParentsDocuments, DocumentSeals) Export

	If DocumentSeals.Metadata().Attributes.Find("ContactPerson") = Undefined Then
		Return;
	EndIf;
	
	DocumentTree = New ValueTree;
	DocumentTree.Columns.Add("Ref");
	AddParentDocumentTree(DocumentSeals, DocumentTree);
	
	AddParentDocumentsToArrayFromTree(DocumentTree, ArrayOfParentsDocuments)

EndProcedure

Procedure AddParentDocumentsToArrayFromTree(ParentTree, ArrayOfParentsDocuments)

	TreeRows = ParentTree.Rows;
	For Each TreeRow In TreeRows Do
		If ArrayOfParentsDocuments.Find(TreeRow.Ref) = Undefined Then
			ArrayOfParentsDocuments.Add(TreeRow.Ref);
		EndIf;
		AddParentDocumentsToArrayFromTree(TreeRow, ArrayOfParentsDocuments);
	EndDo;

EndProcedure

Function PropsMeetFollowingConditions(Attribute)

	Return Metadata.FilterCriteria.RelatedDocuments.Content.Contains(Attribute) Or 
	        Attribute.Type.ContainsType(Type("CatalogRef.CounterpartyContracts")) Or
	        Attribute.Type.ContainsType(Type("CatalogRef.TermsOfSale")) Or
	        Attribute.Type.ContainsType(Type("CatalogRef.SalesOpportunitiesToCustomer"));

EndFunction

Procedure AddParentDocumentTree(CurrentDocument, ParentTree)

	TreeRows = ParentTree.Rows;
	MetadataOfDocument        = CurrentDocument.Metadata();
	FullMetadataObjectName = MetadataOfDocument.FullName();
	
	DataToReceive = New Structure;
	
	AttributesList    = New ValueList;
	
	DetailsToReceive = New Array;
	
	For Each Attribute In MetadataOfDocument.Attributes Do
		
		If PropsMeetFollowingConditions(Attribute) Then
			
			For Each Current_Type In Attribute.Type.Types() Do
				
				AttributeMetadata = Metadata.FindByType(Current_Type);
				
				If AttributeMetadata <> Undefined
					And (Metadata.Documents.Contains(AttributeMetadata) Or Metadata.Catalogs.Contains(AttributeMetadata))
					And AccessRight("Read", AttributeMetadata) Then
					
					DetailsToReceive.Add(Attribute.Name);
					
					Break;
					
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	If DetailsToReceive.Count() > 0 Then
		DataToReceive.Insert("HeaderAttributes", DetailsToReceive);
	EndIf;
	
	For Each TS In MetadataOfDocument.TabularSections Do
		
		DetailsToReceive = New Array;

		For Each Attribute In TS.Attributes Do

			If PropsMeetFollowingConditions(Attribute) Then
				
				For Each Current_Type In Attribute.Type.Types() Do
					
					AttributeMetadata = Metadata.FindByType(Current_Type);
					
					If AttributeMetadata<>Undefined
						And (Metadata.Documents.Contains(AttributeMetadata) Or Metadata.Catalogs.Contains(AttributeMetadata))
						And AccessRight("Read", AttributeMetadata) Then
						
						DetailsToReceive.Add(Attribute.Name);
						Break;
						
					EndIf;
				EndDo;
				
			EndIf;
			
		EndDo;
		
		If DetailsToReceive.Count() > 0 Then
			DataToReceive.Insert(TS.Name, DetailsToReceive);
		EndIf;
		
	EndDo;
	
	QueryIndex = 0;
	
	QueryText = "";
	
	For Each KeyAndValue In DataToReceive Do
		
		If KeyAndValue.Key = "HeaderAttributes" Then
			
			RequestPackageText = "
			|SELECT ALLOWED
			|	&AttributeName 
			|FROM
			|	&FullMetadataObjectName AS TableName
			|WHERE
			|	TableName.Ref = &CurrentDocument";
			
			AttributesString = "";
			
			AttributesString = StrConcat(KeyAndValue.Value, "," + Chars.LF + Chars.Tab);
			
			RequestPackageText = StrReplace(RequestPackageText, "&FullMetadataObjectName", FullMetadataObjectName);
			RequestPackageText = StrReplace(RequestPackageText, "&AttributeName",               AttributesString);
			
		Else
			
			RequestPackageText = "
			|SELECT ALLOWED
			|	&AttributeName 
			|FROM
			|	&TabularSectionName AS TableName
			|WHERE
			|	TableName.Ref = &CurrentDocument";
			
			AttributesString = "";
			
			AttributesString = StrConcat(KeyAndValue.Value, "," + Chars.LF + Chars.Tab);
			
			RequestPackageText = StrReplace(RequestPackageText, "&TabularSectionName",  FullMetadataObjectName + "." + KeyAndValue.Key);
			RequestPackageText = StrReplace(RequestPackageText, "&AttributeName",       AttributesString);
			
		EndIf;
		
		If QueryIndex > 0 Then
			
			QueryText = QueryText + "
			|;
			|
			|///////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
		QueryText = QueryText + RequestPackageText;
		
		QueryIndex = QueryIndex + 1;
		
	EndDo;
	
	If IsBlankString(QueryText) Then
		Return;
	EndIf;
	
	Query       = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CurrentDocument", CurrentDocument);
	
	QueryResult = Query.ExecuteBatch();
	
	QueryIndex = 0;
	
	For Each KeyAndValue In DataToReceive Do
		
		DataSelection = QueryResult[QueryIndex].Select();
		
		While DataSelection.Next() Do
			
			For Each AttributeName In KeyAndValue.Value Do
				
				AttributeValue = DataSelection[AttributeName];
				
				ValueMetadata = Metadata.FindByType(TypeOf(AttributeValue));
				If ValueMetadata <> Undefined Then
				
					If ValueIsFilled(AttributeValue)
						And (Metadata.Documents.Contains(ValueMetadata) Or Metadata.Catalogs.Contains(ValueMetadata))
						And AttributeValue <> CurrentDocument
						And AttributesList.FindByValue(AttributeValue) = Undefined Then
						
							AttributesList.Add(AttributeValue);
						
					EndIf;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		QueryIndex = QueryIndex + 1;
		
	EndDo;
	
	For Each ListItem In AttributesList Do
		
		If ContainedInSubsystem("Sales", MetadataOfDocument) 
			And ContainedInSubsystem("Purchases", ListItem.Value.Metadata()) Then
			
			Continue;
			
		ElsIf ContainedInSubsystem("Purchases", MetadataOfDocument) 
			And ContainedInSubsystem("Sales", ListItem.Value.Metadata()) Then
			
			Continue;
			
		EndIf;
		
		NewRow = TreeRows.Add();
		NewRow.Ref = ListItem.Value;
		If Not AddedReferenceIsAmongParents(ParentTree, ListItem.Value) Then
			AddParentDocumentTree(ListItem.Value, NewRow);
		EndIf;
		
	EndDo;
	
EndProcedure
Function ContainedInSubsystem(SubsystemName, MetadataObject)
	
	MetadataSubsystems = Metadata.Subsystems[SubsystemName];
	
	If MetadataSubsystems.Content.Contains(MetadataObject) Then
		
		Return True;
	
	EndIf;
	
	For Each SubordinateSubsystem In MetadataSubsystems.Subsystems Do
		
		If SubordinateSubsystem.Content.Contains(MetadataObject) Then
			
			Return True;
			
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

Function AddedReferenceIsAmongParents(ParentRow,RequiredDocument)
	
	If TypeOf(ParentRow) = Type("ValueTree") Then
		Return False; 
	EndIf;
	
	CurrentParent = ParentRow;
	While CurrentParent <> Undefined Do
		If CurrentParent.Ref = RequiredDocument Then
			Return True;
		EndIf;
		CurrentParent = CurrentParent.Parent;
	EndDo;
	
	Return False;
	
EndFunction

Procedure GenerateSendOptions(MatchingPrintObjectDataTypes, SendOptions, ArrayOfParentsDocuments, PhoneNumbersRequired = False) Export
	
	Query = New Query;
	MetadataObjectCounter = 1;
	FirstQueryInJoin = True;
	NumberOfElementsAccordingTo = MatchingPrintObjectDataTypes.Count();
	
	For Each MapItem In MatchingPrintObjectDataTypes Do
		
		ArrayOfRecipientDetails = MapItem.Value.ArrayOfRecipientDetails;
		
		If ArrayOfRecipientDetails.Count() = 0 Then
			Continue;
		EndIf;
		
		RecipientObjectMetadata = Metadata.FindByFullName(MapItem.Key);
		If RecipientObjectMetadata = Undefined Then
			Continue;
		EndIf;
		
		CounterForRecipientDetails = 1;
		ArrayElementsCount = ArrayOfRecipientDetails.Count();
		
		For Each RecipientAttributeName In ArrayOfRecipientDetails Do
			
			TabularSection = Undefined;
			If RecipientAttributeName = "Ref" Then
				SynonymForRecipientSBankingDetails = RecipientObjectMetadata.ObjectPresentation;
				DescriptionOfPropsTypes = New TypeDescription((StrReplace(MapItem.Key, "Catalog", "CatalogRef")));
				PrintObjectTable = MapItem.Key;
			Else
				RecipientSDetails = RecipientObjectMetadata.Attributes.Find(RecipientAttributeName);
				PrintObjectTable = MapItem.Key;
				
				If RecipientSDetails = Undefined Then
					AttributeData = StringFunctionsClientServer.SplitStringIntoSubstringsArray(RecipientAttributeName,".");
					If AttributeData.Count() = 2 Then
						TabularSectionName = AttributeData[0];
						TabularSection    = RecipientObjectMetadata.TabularSections.Find(TabularSectionName);
						If TabularSection <> Undefined Then
							RecipientAttributeName = AttributeData[1];
							RecipientSDetails = TabularSection.Attributes.Find(RecipientAttributeName);
							If RecipientSDetails = Undefined Then
								Continue;
							Else
								PrintObjectTable = MapItem.Key + "." + TabularSectionName;
							EndIf;
						Else
							AttributeMetadata = RecipientObjectMetadata.Attributes.Find(AttributeData[0]);
							If AttributeMetadata <> Undefined Then
								For Each AttributeType In AttributeMetadata.Type.Types() Do
									MetadataOfPropsType = Metadata.FindByType(AttributeType);
									If MetadataOfPropsType <> Undefined Then
										RecipientSDetails = MetadataOfPropsType.Attributes.Find(AttributeData[1]);
										If RecipientSDetails = Undefined Then
											Continue;
										EndIf;
									Else
										Continue;
									EndIf;
								EndDo;
								If RecipientSDetails = Undefined Then
									Continue;
								EndIf;
							Else
								Continue;
							EndIf;
						EndIf;
					Else
						Continue;
					EndIf;
				EndIf;
				
				SynonymForRecipientSBankingDetails = RecipientSDetails.Synonym;
				DescriptionOfPropsTypes     = RecipientSDetails.Type;
				
			EndIf;
			
			RecipientPresentation1 = "PRESENTATION(PrintObject."+RecipientAttributeName + ")";
			If DescriptionOfPropsTypes.ContainsType(Type("CatalogRef.Partners")) Then
					NameOfTheContactInformationTable = "Catalog.Partners.ContactInformation";
				ElsIf DescriptionOfPropsTypes.ContainsType(Type("CatalogRef.Counterparties")) Then
					NameOfTheContactInformationTable = "Catalog.Counterparties.ContactInformation";
					RecipientPresentation1 = "PrintObject."+RecipientAttributeName + ".DescriptionFull";
				ElsIf DescriptionOfPropsTypes.ContainsType(Type("CatalogRef.ContactPersonsForPartners")) Then
					NameOfTheContactInformationTable = "Catalog.ContactPersonsForPartners.ContactInformation";
				Else
					
					Continue;
					
			EndIf;
			
			RequestTextByBankingDetails_ ="
			|
			|%UNIONALL%
			|" ;
			
			RequestTextByBankingDetails_ = RequestTextByBankingDetails_ + "
			|SELECT ALLOWED DISTINCT
			|	&PresentationOfPrintObject               AS PresentationOfPrintObject,
			|	PrintObject.Ref                       AS ReferenceToPrintingObject,
			|	&SynonymForRecipientSBankingDetails               AS SynonymForRecipientSBankingDetails,
			|	&RecipientAttributeName                   AS ContactInformationSource,
			|	&RecipientPresentation1                  AS RecipientPresentation1,
			|	ContactInformationTable1.Presentation AS Address,
			|	ContactInformationTable1.Kind           AS EmailAddressKind
			|FROM
			|	&PrintObject AS PrintObject
			|		INNER JOIN &ContactInformationTable1 AS ContactInformationTable1
			|		ON &RecipientAttributeName = ContactInformationTable1.Ref
			|WHERE
			|	PrintObject.Ref IN(&ReferencesArrray)
			|	AND ContactInformationTable1.Type = VALUE(Enum.ContactInformationTypes.Email)";
			
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&ReferencesArrray", "&ReferencesArrray_" + String(MetadataObjectCounter));
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&SynonymForRecipientSBankingDetails", "&SynonymForRecipientSBankingDetails_" + String(MetadataObjectCounter) + "_" + String(CounterForRecipientDetails));
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&RecipientAttributeName", "PrintObject."+RecipientAttributeName);
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&RecipientPresentation1", RecipientPresentation1);
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&PrintObject", PrintObjectTable);
			RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&ContactInformationTable1", NameOfTheContactInformationTable);
			
			Query.SetParameter("SynonymForRecipientSBankingDetails_" + String(MetadataObjectCounter) + "_" + String(CounterForRecipientDetails), SynonymForRecipientSBankingDetails);
			
			If FirstQueryInJoin Then
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "%UNIONALL%", "");
				FirstQueryInJoin = False;
			Else
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "ALLOWED", "");
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "%UNIONALL%", "UNION ALL");
			EndIf;
			
			If TabularSection = Undefined Then
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&PresentationOfPrintObject", "PrintObject.Presentation");
			Else
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "&PresentationOfPrintObject", "PrintObject.Ref.Presentation");
			EndIf;
			
			If PhoneNumbersRequired Then
				
				RequestTextByBankingDetails_ = StrReplace(RequestTextByBankingDetails_, "Email", "Phone");
				
			EndIf;
			
			Query.Text = Query.Text + RequestTextByBankingDetails_;
			CounterForRecipientDetails = CounterForRecipientDetails + 1;
			
		EndDo;
		
		Query.SetParameter("ReferencesArrray_" + String(MetadataObjectCounter), MapItem.Value.DataArray);
		MetadataObjectCounter = MetadataObjectCounter + 1;
		
	EndDo;
	
	If ArrayOfParentsDocuments.Count() > 0 Then
		
		TagTypesDocumentsParents = 1;
		MatchingDataTypesOfParentDocuments = TMCommonUse.MatchingArraysByObjectType(ArrayOfParentsDocuments);
		For Each MapItem In MatchingDataTypesOfParentDocuments Do
			
			If Metadata.FindByFullName(MapItem.Key).Attributes.Find("ContactPerson") = Undefined Then
				Continue;
			EndIf;
			
			RequestTextForParentDocument = "
			|
			|%UNIONALL%
			|";
			RequestTextForParentDocument = RequestTextForParentDocument + "
			|SELECT ALLOWED
			|	DocumentParent.Presentation AS PresentationOfPrintObject,
			|	DocumentParent.Ref AS ReferenceToPrintingObject,
			|	&ContactPerson AS SynonymForRecipientSBankingDetails,
			|	DocumentParent.ContactPerson AS ContactInformationSource,
			|	PRESENTATION(DocumentParent.ContactPerson) AS RecipientPresentation1,
			|	ContactInformationTable1.Presentation AS Address,
			|	ContactInformationTable1.Kind AS EmailAddressKind
			|FROM
			|	&DocumentParent AS DocumentParent
			|		INNER JOIN Catalog.ContactPersonsForPartners.ContactInformation AS ContactInformationTable1
			|		ON DocumentParent.ContactPerson = ContactInformationTable1.Ref
			|WHERE
			|	DocumentParent.Ref IN(&ReferencesArrray)
			|	AND ContactInformationTable1.Type = VALUE(Enum.ContactInformationTypes.Email)";
			
			RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "&DocumentParent", MapItem.Key);
			RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "&ReferencesArrray", "&ArrayOfLinksDocumentsParents_" + String(TagTypesDocumentsParents));
			
			If FirstQueryInJoin Then
				RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "%UNIONALL%", "");
				FirstQueryInJoin = False;
			Else
				RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "ALLOWED", "");
				RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "%UNIONALL%", "UNION ALL");
			EndIf;
			
			If PhoneNumbersRequired Then
				RequestTextForParentDocument = StrReplace(RequestTextForParentDocument, "Email", "Phone");
			EndIf;

			Query.SetParameter("ArrayOfLinksDocumentsParents_" + String(TagTypesDocumentsParents), MapItem.Value);
			
			Query.Text = Query.Text + RequestTextForParentDocument;
			
			TagTypesDocumentsParents = TagTypesDocumentsParents + 1;
			
		EndDo;
		
		Query.SetParameter("ContactPerson", NStr("vi = 'Người liên hệ';
												|ru = 'Контактное лицо';
												|en = 'Contact person'; fa = 'شخص تماس';
												|it = 'Contatto';
												|pl = 'Osoba do kontaktu';
												|tr = 'İrtibat kişisi'"));
		
	EndIf;
	
	If IsBlankString(Query.Text) Then
		Return;
	EndIf;
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	SendOptions.Recipient = New Array;
	While Selection.Next() Do
		
		AddRecipientOfPrintedForm(SendOptions.Recipient, Selection);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FillingInMessageRecipientsUsingTemplates

Procedure FillInRecipientsOfMessageUsingTemplate(Recipients, TemplateAssignment, MessageSubject, ForSMS) Export

	SendOptions = New Structure("Recipient", New Array);
	ParametersArray = New Array;
	
	If TypeOf(MessageSubject) = Type("Structure") Then
		
		AddParameterToArrayToDefineRecipients(ParametersArray, MessageSubject.SubjectOf);
		
		For Each AdditionalParameter In MessageSubject.ArbitraryParameters  Do
			AddParameterToArrayToDefineRecipients(ParametersArray, AdditionalParameter);
		EndDo;
		
	Else
		
		AddParameterToArrayToDefineRecipients(ParametersArray, MessageSubject);
		
	EndIf;
	
	If ParametersArray.Count() = 0 Then
		Return;
	EndIf;
	
	MatchingParameterDataTypes = TMCommonUse.MatchingArraysByObjectType(ParametersArray);
	
	ArrayOfParentsDocuments = New Array;
	AugmentedCompliance = New Map;
	
	For Each MapItem In MatchingParameterDataTypes Do
		
		StructureOfParameterData = NewPrintObjectDataStructure();
		StructureOfParameterData.DataArray = MapItem.Value;
		
		FillInRecipientStructureDataByObjectType(MapItem.Key , StructureOfParameterData);
		
		AugmentedCompliance.Insert(MapItem.Key, StructureOfParameterData);
		
		For Each Parameter In MapItem.Value Do
			GetParentDocuments(ArrayOfParentsDocuments,Parameter);
		EndDo;
		
	EndDo;
	
	GenerateSendOptions(AugmentedCompliance, SendOptions, ArrayOfParentsDocuments, ForSMS);
	
	For Each Recipient In SendOptions.Recipient Do
		
		AddressesArray = StrSplit(Recipient.Address, ";", False);
		
		For Each Address In AddressesArray Do
		
			SearchParameters = New Structure;
			SearchParameters.Insert("Contact", Recipient.ContactInformationSource);
			If ForSMS Then
				SearchParameters.Insert("PhoneNumber", TrimAll(Address));
			Else
				SearchParameters.Insert("Address", TrimAll(Address));
			EndIf;
			
			FoundRows = Recipients.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then
				Continue;
			EndIf;
			
			NewRow = Recipients.Add();
			NewRow.Presentation = Recipient.Presentation;
			NewRow.Contact = Recipient.ContactInformationSource;
			If ForSMS Then
				NewRow.PhoneNumber = Address;
			Else
				NewRow.Address = Address;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure AddParameterToArrayToDefineRecipients(ParametersArray, Parameter) Export

	If ValueIsFilled(Parameter) And Common.IsReference(TypeOf(Parameter))
		And (Common.ObjectKindByRef(Parameter) = "Catalog" Or Common.ObjectKindByRef(Parameter) = "Document") Then
		
		ParametersArray.Add(Parameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
