////////////////////////////////////////////////////////////////////////////////
// General procedures and functions used in the subsystem 
// of international financial accounting.
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Returns whether documents can be reflected in international accounting for the current user.
// 
// Returns:
// 	Boolean - Availability of rights to reflect documents in the regl. accounting
//
Function ThereIsRightToReflectDocumentsInInternationalAccounting() Export
	
	Return AccessRight("Use", Metadata.DataProcessors.DocumentPostingInFinancialAccounting);
	
EndFunction

// Returns the accounting currencies in the chart of accounts
// 
// Parameters:
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - The chart of accounts to get accounting currencies for.
// 	Organization - CatalogRef.Companies - The organization for which it is necessary to obtain a functional currency.
// 	
// Returns:
//	Structure - Keys:
//		* Functional - CatalogRef.Currencies - Functional currency
//		* Presentations - CatalogRef.Currencies -  Presentation currency
//		* AccountingInFunctionalCurrency - EnumRef.AccountingKindsInFunctionalCurrency - Source of amounts to be accounted for in the functional currency
//
Function AccountingCurrencies(ChartOfAccounts, Organization) Export
	
	SetPrivilegedMode(True);
	DetailsOfChartOfAccounts = Common.ObjectAttributesValues(
								ChartOfAccounts, "PresentationCurrency, AccountingInFunctionalCurrency");
	If DetailsOfChartOfAccounts.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal Then
		FunctionalCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		FunctionalCurrency = SettingsValueCached.ManagementAccountingCurrency();
	EndIf;
	
	SetPrivilegedMode(False);
	
	Return New Structure("Functional, Presentations, AccountingInFunctionalCurrency",
							FunctionalCurrency,
							DetailsOfChartOfAccounts.PresentationCurrency,
							DetailsOfChartOfAccounts.AccountingInFunctionalCurrency);
	
EndFunction

// Defines the use of the financial accounting group
// in the settings for refining accounting accounts in international financial accounting.
//
// Parameters:
//  FinancialAccountingGroup - CatalogRef.InventoryAccountingGroups -
//	                       - CatalogRef.FinancialAccountingGroupsOfARAP -
//	                       - CatalogRef.GroupsOfFinancialAccountingOfCash -
//	                       - CatalogRef.IncomeExpensesAccountingGroups - the group of financial accounting
//                               of the nomenclature, settlements with counterparties, cash, income /expenses.
//
// Returns:
//  Structure - Keys:
//    * NumberOfRelatedTemplates - Number - number of transaction templates that use invoice refinement using this type of financial accounting groups
//    * NumberOfConfiguredTemplates - Number - the number of transaction templates that the accounting accounts for this financial accounting group are configured for.
//
Function StateOfAccountingInvoiceRefinement(FinancialAccountingGroup) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	RulesForClarifyingInvoices.PostingTemplate,
	|	RulesForClarifyingInvoices.RecordType,
	|	RulesForClarifyingInvoices.GLAccount
	|INTO RulesForClarifyingInvoices
	|FROM
	|	InformationRegister.RulesOfSpecifyingAccountsFinancialAccounting AS RulesForClarifyingInvoices
	|WHERE
	|	RulesForClarifyingInvoices.FinancialAccountingGroup = &FinancialAccountingGroup
	|;
	|
	|SELECT
	|	PostingTemplates.Ref AS PostingTemplate,
	|	VALUE(Enum.AccountingMovementKinds.Debit) AS RecordType,
	|	RulesForClarifyingInvoices.GLAccount AS GLAccount
	|INTO PostingTemplates
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|		LEFT JOIN RulesForClarifyingInvoices AS RulesForClarifyingInvoices
	|		ON (RulesForClarifyingInvoices.PostingTemplate = PostingTemplates.Ref)
	|			AND (RulesForClarifyingInvoices.RecordType = VALUE(Enum.AccountingMovementKinds.Debit))
	|WHERE
	|	PostingTemplates.AccountSpecificationSourceTypeDr IN (&AccountSpecificationSourceTypes)
	|
	|UNION ALL
	|
	|SELECT
	|	PostingTemplates.Ref,
	|	VALUE(Enum.AccountingMovementKinds.Credit),
	|	RulesForClarifyingInvoices.GLAccount
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|		LEFT JOIN RulesForClarifyingInvoices AS RulesForClarifyingInvoices
	|		ON (RulesForClarifyingInvoices.PostingTemplate = PostingTemplates.Ref)
	|			AND (RulesForClarifyingInvoices.RecordType = VALUE(Enum.AccountingMovementKinds.Credit))
	|WHERE
	|	PostingTemplates.AccountSpecificationSourceTypeCr IN (&AccountSpecificationSourceTypes)
	|;
	|
	|SELECT
	|	COUNT(PostingTemplates.PostingTemplate) AS NumberOfRelatedTemplates
	|FROM
	|	PostingTemplates AS PostingTemplates
	|;
	|
	|SELECT
	|	COUNT(PostingTemplates.PostingTemplate) AS NumberOfConfiguredTemplates
	|FROM
	|	PostingTemplates AS PostingTemplates
	|WHERE
	|	NOT PostingTemplates.GLAccount IS NULL
	|";
	
	Query.SetParameter("FinancialAccountingGroup", FinancialAccountingGroup);  
	Query.SetParameter("AccountSpecificationSourceTypes", FinancialAccountingClientServer.AccountSpecificationSourceTypes(FinancialAccountingGroup));
	
	ResultsArray = Query.ExecuteBatch();
	
	NumberOfRelatedTemplates = 0;
	NumberOfConfiguredTemplates = 0;
	
	QueryResultRelatedTemplates = ResultsArray[2]; // QueryResult - 
	SamplingRelatedTemplates = QueryResultRelatedTemplates.Select();
	If SamplingRelatedTemplates.Next() Then
		NumberOfRelatedTemplates = SamplingRelatedTemplates.NumberOfRelatedTemplates;
	EndIf;
	QueryResultConfiguredTemplates = ResultsArray[3]; // QueryResult -
	SelectionOfCustomizedTemplates = QueryResultConfiguredTemplates.Select();
	If SelectionOfCustomizedTemplates.Next() Then
		NumberOfConfiguredTemplates = SelectionOfCustomizedTemplates.NumberOfConfiguredTemplates;
	EndIf;
	
	Return New Structure("NumberOfRelatedTemplates, NumberOfConfiguredTemplates",
							NumberOfRelatedTemplates, NumberOfConfiguredTemplates);
	
EndFunction

// Returns an element of the business operations Settings reference list by reference to the value of the business Operations enumeration.
//
// Parameters:
//  EnumerationValue - EnumRef.BusinessTransactions - reference to the value of the business Operation enumeration.
//
// Returns:
// CatalogRef.BusinessTransactionsSettings - an element of the business operation settings directory.
//
Function BusinessTransferOperation(EnumerationValue) Export

	BusinessOperation = Undefined;
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BsnsTransactionsSettings.Ref AS BusinessOperation 
	|FROM
	|	Catalog.BusinessTransactionsSettings AS BsnsTransactionsSettings
	|WHERE
	|	BsnsTransactionsSettings.BusinessOperation = &EnumerationValue
	|";
	
	Query.SetParameter("EnumerationValue", EnumerationValue);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		BusinessOperation = Selection.BusinessOperation;
	EndIf;
	
	Return BusinessOperation;

EndFunction

// Converts the amount of the functional currency to the presentation currency
//
// Parameters:
// 	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Plan accounts for which it is necessary to recalculate
// 	Organization - CatalogRef.Companies - The organization for which the recalculation is required
//  Sum - Number - Amount in functional currency 
//  Date - Date - the date when the exchange rate was determined.
//
// Returns:
//  Number - The amount in the presentation currency.
//
Function CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum, Date = Undefined) Export
	
	If Date = Undefined Then
		Date = CurrentSessionDate();
	EndIf;
	
	CurrenciesOfInternationalAccounting = AccountingCurrencies(ChartOfAccounts, Organization);
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
					CurrenciesOfInternationalAccounting.Functional, 
					CurrenciesOfInternationalAccounting.Presentations,
					Date,
					LocalAccountingCurrency);
	
	Return Sum * ZoomRatio;
	
EndFunction

// The function gets conversion coefficients for amounts from the specified currency to the functional currency and the presentation currency.
//
// Parameters:
//  ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Chart of accounts for which you want to translate
//  Organization - CatalogRef.Companies - The organization for which the recalculation is required
//  SourceCurrency - CatalogRef.Currencies - the currency to convert which you need to get coefficients.
//  Period - Date - the date when the exchange rate was determined.
//
// Returns:
//  Structure - containing conversion factors in keys:
//  	* ToFunctionalCurrency - Number -
//  	* CurrencyOfPresentation - Number - 
//
Function GetCurrencyConversionRates_(ChartOfAccounts, Organization, SourceCurrency, Period)Export

	CurrenciesOfInternationalAccounting = AccountingCurrencies(ChartOfAccounts, Organization);
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	Query = New Query("
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, 
	|		BaseCurrency = &BaseCurrency
	|		AND (Currency = &CurrencyFunctional 
	|				OR Currency = &PresentationCurrency 
	|				OR Currency = &SourceCurrency)
	|	) AS ExchangeRates
	|");
	Query.SetParameter("Period",               Period);
	Query.SetParameter("BaseCurrency",        LocalAccountingCurrency);
	Query.SetParameter("CurrencyFunctional", CurrenciesOfInternationalAccounting.Functional);
	Query.SetParameter("PresentationCurrency",  CurrenciesOfInternationalAccounting.Presentations);
	Query.SetParameter("SourceCurrency",       SourceCurrency);

	ExchangeRateNumeratorOfFunctionalCurrency   = 1;
	ExchangeRateDenominatorOfFunctionalCurrency = 1;

	ExchangeRateNumeratorOfPresentationCurrency  = 1;
	ExchangeRateDenominatorOfPresentationCurrency = 1;

	ExchangeRateNumeratorOfOriginalCurrency = 1;
	RateDenominatorOfOriginalCurrency = 1;

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		If Selection.Currency = CurrenciesOfInternationalAccounting.Functional Then

			ExchangeRateNumeratorOfFunctionalCurrency      = Selection.CourseNumerator;
			ExchangeRateDenominatorOfFunctionalCurrency = Selection.CourseDenominator;

		EndIf;

		If Selection.Currency = CurrenciesOfInternationalAccounting.Presentations Then

			ExchangeRateNumeratorOfPresentationCurrency      = Selection.CourseNumerator;
			ExchangeRateDenominatorOfPresentationCurrency = Selection.CourseDenominator;

		EndIf;

		If Selection.Currency = SourceCurrency Then

			ExchangeRateNumeratorOfOriginalCurrency      = Selection.CourseNumerator;
			RateDenominatorOfOriginalCurrency = Selection.CourseDenominator;

		EndIf;
	EndDo;

	Result = New Structure("ToFunctionalCurrency, CurrencyOfPresentation");

	Result.ToFunctionalCurrency = 
		(ExchangeRateNumeratorOfOriginalCurrency * ExchangeRateDenominatorOfFunctionalCurrency) 
		/ (RateDenominatorOfOriginalCurrency * ExchangeRateNumeratorOfFunctionalCurrency);
		
	Result.CurrencyOfPresentation = 
		(ExchangeRateNumeratorOfOriginalCurrency * ExchangeRateDenominatorOfPresentationCurrency)
		/ (RateDenominatorOfOriginalCurrency * ExchangeRateNumeratorOfPresentationCurrency);

	Return Result;

EndFunction

// Checks whether the international financial accounting settings are readable.
//
// Returns:
//  Boolean - True if reading the international accounting settings is allowed.
//
Function InternationalAccountingSettingsCanBeRead() Export

	Return	AccessRight("Read", Metadata.Catalogs.PostingTemplatesForFinancialAccounting);

EndFunction

// Checks whether changes to international financial accounting settings are available.
//
// Returns:
//  Boolean - True if changing the international accounting settings is allowed.
//
Function InternationalAccountingSettingsCanBeChanged() Export

	Return AccessRight("Update", Metadata.Catalogs.PostingTemplatesForFinancialAccounting);

EndFunction

// To establish the conditional registration of transactions of international account.
// The fields of the transaction form table are drawn up: Subconto, Viewsubconto, Currency, and wiring Type.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - collection of elements of the form's conditional design.
//  TableOfTransactions - String - Name of the form table that displays the transaction.
//  Correspondence - Boolean - Indicates that the transactions are supported by correspondence.
//
Procedure SetTransactionLayout(ConditionalAppearance, TableOfTransactions, Correspondence = True) Export
	
	// The "Wiring type" field is not filled in to display the gray text "Normal"
	Item = ConditionalAppearance.Items.Add();
	
	PathsToTableData = StrSplit(TableOfTransactions, ".");
	NameOfTransactionTable = PathsToTableData[PathsToTableData.UBound()];
	
	ItemField = Item.Fields.Items.Add();
	If NameOfTransactionTable = "TransactionsWithoutCorrespondence" Then
		ItemField.Field = New DataCompositionField("TransactionsWithoutCorrespondencePostingType");
	ElsIf NameOfTransactionTable = "InternationalWithoutCorrespondence" Then
		ItemField.Field = New DataCompositionField("InternationalWithoutCorrespondencePostingType");
	Else
		ItemField.Field = New DataCompositionField("PostingType");
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.PostingTypesFinancialAccounting.EmptyRef();
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Normal'; fa = 'عادی';
													|it = 'Regolare';
													|pl = 'Normal';
													|tr = 'Normal'"));
	
	// Fields depending on the account side
	MaxExtDimensionCount = Metadata.ChartsOfAccounts.International.MaxExtDimensionCount;
	
	If Correspondence Then
		// Dr
		For IndexOf = 1 To MaxExtDimensionCount Do
			SetExtdimensionClearance(ConditionalAppearance, TableOfTransactions, "Dr", IndexOf);
		EndDo;
		SetCurrencyRegistration(ConditionalAppearance, TableOfTransactions, "Dr");
		SetQuantityClearance(ConditionalAppearance, TableOfTransactions, "Dr");
			
		// Cr
		For IndexOf = 1 To MaxExtDimensionCount Do
			SetExtdimensionClearance(ConditionalAppearance, TableOfTransactions, "Cr", IndexOf);
		EndDo;
		SetCurrencyRegistration(ConditionalAppearance, TableOfTransactions, "Cr");
		SetQuantityClearance(ConditionalAppearance, TableOfTransactions, "Dr");
	Else
		For IndexOf = 1 To MaxExtDimensionCount Do
			SetExtdimensionClearance(ConditionalAppearance, TableOfTransactions, "", IndexOf);
		EndDo;
		SetCurrencyRegistration(ConditionalAppearance, TableOfTransactions, "");
		SetQuantityClearance(ConditionalAppearance, TableOfTransactions, "");
	EndIf
	
EndProcedure

// Fills in the auxiliary fields of the view of sub-konto types
//
// Parameters:
//  FormTable  - FormDataCollection - Form details (table) containing the transaction.
//  DrCr - String - The side of the types of subconto
Procedure FillInPresentationOfExtdimensionSpecies(FormTable, DrCr) Export

	For Each TableRow In FormTable Do
		FillPropertyValues(TableRow, PresentationOfExtdimensionSpecies(TableRow["Account" + DrCr], DrCr));
	EndDo;

EndProcedure

// Gets string representations of sub-account types.
//
// Parameters:
//  Account - Structure - Account description of the international chart of accounts
//  DrCr - String - The wiring side is " Dt " or "CT".
//
// Returns:
//   Structure - The name of the field of the Presentation of the ExtDimension type on the form ("RepresentatioNidSubcontoDt1", "RepresentatioNidSubcontoDt2", etc.) The value of the structure is a string Presentation of the ExtDimension type:
//   *PresentationViewOfExtdimensionDr1 - String
//   *CurrencyAccountingDr1 - Boolean
//   *QuantitativeAccountingDr1 - Boolean
//   *ExtDimensionCountDr1 - Number
//
Function PresentationOfExtdimensionSpecies(Account, DrCr) Export

	PresentationOfExtdimensionSpecies = New Structure;
	MaxExtDimensionCount = Metadata.ChartsOfAccounts.International.MaxExtDimensionCount;
	NumberOfExtdimensionSpecies = Account.ExtDimensionTypes.Count();
	For K = 1 To MaxExtDimensionCount Do
		PresentationOfExtdimensionView = ?(NumberOfExtdimensionSpecies >= K, "<" + Account.ExtDimensionTypes[K - 1].ExtDimensionType + ">", Undefined);
		PresentationOfExtdimensionSpecies.Insert("PresentationViewOfExtdimension" + DrCr + K, PresentationOfExtdimensionView);
	EndDo;
	CurrencyAccount_ = FinancialAccountingServerCached.AccountProperties(Account).Currency1;
	PresentationOfExtdimensionSpecies.Insert("CurrencyAccounting" + DrCr, CurrencyAccount_);
	QuantitativeAccount = FinancialAccountingServerCached.AccountProperties(Account).Quantitative;
	PresentationOfExtdimensionSpecies.Insert("QuantitativeAccounting" + DrCr, QuantitativeAccount);
	PresentationOfExtdimensionSpecies.Insert("ExtDimensionCount" + DrCr, NumberOfExtdimensionSpecies);

	Return PresentationOfExtdimensionSpecies;

EndFunction

// Gets the title of the button for calling the setdate command.
//
// Parameters:
//  PeriodEndClosingDate  - Date - date of prohibition of the formation transactions, international accounting.
//
// Returns:
//   String - The text of the button title.
//
Function PresentationOfCommandToSetBanDate(PeriodEndClosingDate = Undefined) Export
	
	Template = NStr("vi = 'Ngày cấm lập bút toán %PeriodEndClosingDate%';
					|ru = 'Дата запрета формирования проводок %PeriodEndClosingDate%';
					|en = 'Closing date of posting generation %PeriodEndClosingDate%'; fa = 'Closing date of posting generation %PeriodEndClosingDate%';
					|it = 'Data del divieto di creazione dei movimenti  %PeriodEndClosingDate%';
					|pl = 'Data zakazu tworzenia księgowań %PeriodEndClosingDate%';
					|tr = 'Giriş kaydetme kapanış tarihi %PeriodEndClosingDate%''dir'");
	Replacement = ?(ValueIsFilled(PeriodEndClosingDate),Format(PeriodEndClosingDate, "DLF=DD"),NStr("vi = 'chưa thiết lập';
																									|ru = 'не установлена';
																									|en = 'not set'; fa = 'not set';
																									|it = 'non installato';
																									|pl = 'nie zainstalowana';
																									|tr = 'kurulmadı'"));
	Return StrReplace(Template, "%PeriodEndClosingDate%", Replacement);
	
EndFunction

// Sets visibility of settings for international accounting depending on the enabled ones
// FO of international accounting and availability of customized transaction templates for international accounting.
// 
// Parameters:
//  Ref - CatalogRef.GroupsOfFinancialAccountingOfCash -
//         - CatalogRef.IncomeExpensesAccountingGroups -
//         - CatalogRef.InventoryAccountingGroups -
//         - CatalogRef.FinancialAccountingGroupsOfARAP - the financial accounting group being audited.
//  MFPSettingsGroup - FormGroup - a group of form elements that contains the MFP settings.
//  ToConfigureAccountSpecification - FormButton - hyperlink to the settings of transaction templates for international accounting.
//
Procedure SetVisibilityOfMFPSettings(Ref, MFPSettingsGroup, ToConfigureAccountSpecification) Export
	
	If (GetFunctionalOption("ConfigurePostingsForBusinessTransactions")
		Or GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData"))
		And InternationalAccountingSettingsCanBeRead() Then
		
		SettingsData = StateOfAccountingInvoiceRefinement(Ref);
		NumberOfRelatedTemplates = SettingsData.NumberOfRelatedTemplates;
		NumberOfConfiguredTemplates = SettingsData.NumberOfConfiguredTemplates;
		
		VisibilityOfSettings = False;
		ChangingMFPSettingsIsAvailable = InternationalAccountingSettingsCanBeChanged();
		
		If NumberOfRelatedTemplates > 0 And NumberOfConfiguredTemplates > 0 Then
			SettingsHyperlinkHeader = NStr("vi = 'Xem cài đặt tài khoản kế toán bằng cách đăng mẫu';
											|ru = 'Посмотреть настройки счетов учета по шаблонам проводок';
											|en = 'View ledger account settings by posting templates'; fa = 'View ledger account settings by posting templates';
											|it = 'Vedere le configurazioni dei conti di registrazione per modelli di registrazioni contabili';
											|pl = 'Zobacz ustawienia rachunków ewidencji wg szablonów księgowań';
											|tr = 'Kayıt şablonuna göre defterikebir hesabı ayarlarını görmek'");
			If ChangingMFPSettingsIsAvailable Then
				SettingsHyperlinkHeader = NStr("vi = 'Thay đổi cài đặt tài khoản kế toán theo mẫu bút toán';
												|ru = 'Изменить настройки счетов учета по шаблонам проводок';
												|en = 'Change ledger account settings by posting templates'; fa = 'Change ledger account settings by posting templates';
												|it = 'Cambiare le configurazioni dei conti di registrazione per modelli di registrazioni contabili';
												|pl = 'Zmień ustawienia rachunków ewidencji wg szablonów księgowań';
												|tr = 'Kayıt şablonuna göre defterikebir hesabı ayarlarını değiştirmek'");
			EndIf;
			VisibilityOfSettings = True;
		ElsIf NumberOfRelatedTemplates > 0 And NumberOfConfiguredTemplates = 0 Then
			SettingsHyperlinkHeader = NStr("vi = 'Thiết lập tài khoản kế toán bằng cách đăng mẫu';
											|ru = 'Настроить счета учета по шаблонам проводок';
											|en = 'Configure ledger account by posting templates'; fa = 'Configure ledger account by posting templates';
											|it = 'Configurare i conti di registrazione per modelli di registrazioni contabili';
											|pl = 'Ustaw konta księgwoe wg szablonów księgowań';
											|tr = 'Kayıt şablonuna göre defterikebir hesabını ayarlamak'");
			VisibilityOfSettings = ChangingMFPSettingsIsAvailable;
		EndIf;
		If ToConfigureAccountSpecification <> Undefined Then
			ToConfigureAccountSpecification.Title = SettingsHyperlinkHeader;
		EndIf;
		MFPSettingsGroup.Visible = VisibilityOfSettings;
	EndIf;
	
EndProcedure

// Sets the visibility of the inscriptions of titles of areas of activity
//
// Parameters:
//  UnitElement - FormField - column of the table part of the document.
//  Postfix - String - The Dt or Ct postfix in the element header.
Procedure SetUnitHeaders(UnitElement, Postfix = "") Export
	
	Title = ?(Postfix = "", NStr("vi = 'Bộ phận';
								|ru = 'Подразделение';
								|en = 'Business unit'; fa = 'Business unit';
								|it = 'Reparto';
								|pl = 'Dział';
								|tr = 'Departman'"), NStr("vi = 'Bộ phận %1';
																|ru = 'Подразделение %1';
																|en = 'Business unit %1'; fa = 'Business unit %1';
																|it = 'Reparto %1';
																|pl = 'Dział: %1';
																|tr = 'Departman: %1'"));
	If Catalogs.LinesOfBusiness.AccountingByDirectionsIsUsed() Then
		Title = Title + ", " + ?(Postfix = "", NStr("vi = 'Hướng';
													|ru = 'Направление';
													|en = 'Line of business'; fa = 'خط کسب‌وکار';
													|it = 'Destinazione';
													|pl = 'Kierunek';
													|tr = 'Yön'"), NStr("vi = 'Hướng %1';
																					|ru = 'Направление %1';
																					|en = 'Line of business %1'; fa = 'Line of business %1';
																					|it = 'Direzione %1';
																					|pl = 'Kierunek %1';
																					|tr = 'Yön %1'"))
	EndIf;
	If Postfix <> "" Then
		Title = StrTemplate(Title, Postfix);
	EndIf;
	UnitElement.Title = Title;
	
EndProcedure

// Checks the subconto fill expression for the specified settings string and fills in the expression representation in the string.
// 
// Parameters:
//  SetupStrings - FormDataCollectionItem- A row in the table part containing the expression for filling in the ExtDimension:
//							*Expression - String - The ExtDimension filling expression.
//							*MissingInAvailableFields - Boolean - Flag for passing the field check in the schema.
//							*RepresentationOfTheExpression - String - Presentation of the ExtDimension filling expression,
//						given the form of the tree element,
//						An array of Tree element data forms - An array of strings is supported to optimize obtaining Presentations for characteristics in expressions,
//						Array from the given formelementcollection.
//							
// 	SettingsComposer - DataCompositionSettingsComposer - The linker settings, which are checked expressions.
//
Procedure CheckExtdimensionFillingExpression(SetupStrings, SettingsComposer) Export
	
	Expressions = New Array;
	
	If TypeOf(SetupStrings) = Type("Array") Then
		ArrayOfConfigurationLines = SetupStrings;
	Else
		ArrayOfConfigurationLines = New Array;
		ArrayOfConfigurationLines.Add(SetupStrings);
	EndIf;
	
	For Each SettingString In ArrayOfConfigurationLines Do // FormDataCollectionItem -
		Expressions.Add(SettingString.Expression);
	EndDo;
	ExpressionPresentations = ProcessingOfFormulas.ExpressionsWithPresentationsOfCharacteristicsForOnlineVerification(Expressions);
	
	For Each SettingString In ArrayOfConfigurationLines Do // Dataformelementcollection -
		If Not SettingString.FillInFromSource Then
			SettingString.Expression = "";
		EndIf;
		
		If SettingString.Expression = "" Then
			SettingString.MissingInAvailableFields = False;
			SettingString.RepresentationOfTheExpression = "";
			Return;
		EndIf;
		
		ExpressionWithPresentationOfCharacteristics = ExpressionPresentations.Get(SettingString.Expression);
		
		Field = New DataCompositionField(ExpressionWithPresentationOfCharacteristics); 
		AvailableField = SettingsComposer.Settings.SelectionAvailableFields.FindField(Field);
		
		If AvailableField = Undefined Then
			SettingString.MissingInAvailableFields = True;
			SettingString.RepresentationOfTheExpression = SettingString.Expression;
		Else
			SettingString.MissingInAvailableFields = False;
			SettingString.RepresentationOfTheExpression = AvailableField.Title;
		EndIf;
	EndDo;
	
EndProcedure

// Gets the current date when international accounting transactions are prohibited from being generated
//
// Parameters:
//  Organization - CatalogRef.Companies - the organization (or array of organizations) 
//                 for which you want to get the date of the ban on the formation of transactions
//                 if not specified, you will get the minimum ban date for all organizations.
//
// Returns:
//   Date - date of prohibition of the formation transactions, international accounting.
//
Function ClosingDateOfPostingGeneration(Organization = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ENDOFPERIOD(ClosingDates.PeriodEndClosingDate, DAY) AS PeriodEndClosingDate
	|FROM
	|	InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS ClosingDates
	|WHERE
	|	(ClosingDates.Organization = VALUE(Catalog.Companies.EmptyRef) OR &AllCompanies)
	|	AND ClosingDates.PeriodEndClosingDate <> DATETIME(1, 1, 1) 
	|
	|ORDER BY
	|	ClosingDates.PeriodEndClosingDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ENDOFPERIOD(ClosingDates.PeriodEndClosingDate, DAY) AS PeriodEndClosingDate
	|FROM
	|	InformationRegister.ClosingDatesOfFinancialAccountingPostingGeneration AS ClosingDates
	|WHERE
	|	ClosingDates.Organization IN(&Companies)
	|	AND ClosingDates.PeriodEndClosingDate <> DATETIME(1, 1, 1)
	|
	|ORDER BY
	|	ClosingDates.PeriodEndClosingDate";
	
	Query.SetParameter("Companies", Organization);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));

	ClosingDates = Query.ExecuteBatch();
	
	QueryResultForOrganization = ClosingDates[1]; // QueryResult - 
	ByCompany = QueryResultForOrganization.Select();
	If ByCompany.Next() Then
		Return ByCompany.PeriodEndClosingDate;
	EndIf;
	
	QueryResultForAll = ClosingDates[0]; // QueryResult -
	ForAll = QueryResultForAll.Select();
	If ForAll.Next() Then
		Return ForAll.PeriodEndClosingDate;
	EndIf;
	
	Return Date(1,1,1);

EndFunction

// Returns a combination of the values of the functional options for generating MFP transactions,
// which uses the settings for accounting objects or regulated accounting,
// but the settings for business operations are not used.
// 
// Returns:
// 	Boolean - The settings for accounting objects or Local settings are used.accounting, household.operations are not used
//
Function SettingUpTransactionsForAccountingObjectsOrLocalAccounting() Export
	
	Return GetFunctionalOption("SettingOfPostingByAccountingObjects")
		Or (GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData")
			And Not GetFunctionalOption("FinancialAccountingEntriesBasedOnOperationalAccountingData"));
	
EndFunction

// Returns an option for generating transactions on an international accounting account
// 
// Parameters:
//  GLAccount - ChartOfAccountsRef.International - Accounting account
// 
// Returns:
//  EnumRef.EntryGenerationOptions, Undefined - Option for generating transactions
//
Function OptionForGeneratingTransactionsByAccount(GLAccount) Export
	
	Return FinancialAccountingServerCached.AccountProperties(GLAccount).OptionForGeneratingTransactions;
	
EndFunction

// Returns the name of the accounting register for international accounting account transactions
// 
// Parameters:
//  GLAccount - ChartOfAccountsRef.International - Accounting account
// 
// Returns:
//  String, Undefined - Name of the accounting register
//
Function NameOfAccountingRegisterForTransactionsOnAccountingAccount(GLAccount) Export
	
	OptionForGeneratingTransactions = FinancialAccountingServerCached.AccountProperties(GLAccount).OptionForGeneratingTransactions;
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		Return Metadata.AccountingRegisters.InternationalWithoutCorrespondence.Name;
	ElsIf OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence Then
		Return Metadata.AccountingRegisters.International.Name;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// Adds the value Reverse or Reverse to the Wiring Type control selection list, depending
// on the method of canceling transactions set in the wiring generation settings.
// 
// Parameters:
//  MethodOfCancelingTransactions - EnumRef.MethodsOfCancelingPostingsInFinancialAccounting - method of cancellation of transactions
//  ChoiceList - ValueList - control selection list with transaction type
//
Procedure AddTypesOfInvalidTransactions(MethodOfCancelingTransactions, ChoiceList) Export
	
	If ChoiceList.Count() = 0 Then
		Return;
	EndIf;
	
	DeletedTypesOfTransactions = New Array();
	TypesOfTransactionsToAdd = New ValueList();
	
	If Not ValueIsFilled(MethodOfCancelingTransactions) Then
		TypesOfTransactionsToAdd.Add(Enums.PostingTypesFinancialAccounting.Reverse, NStr("vi = 'Đảo ngược';
																						|ru = 'Реверс';
																						|en = 'Reverse'; fa = 'معکوس';
																						|it = 'Inversa';
																						|pl = 'Rewers';
																						|tr = 'Ters'"));
		TypesOfTransactionsToAdd.Add(Enums.PostingTypesFinancialAccounting.ReversingEntry, NStr("vi = 'Đảo ngược';
																								|ru = 'Сторно';
																								|en = 'Storno'; fa = 'استورنو';
																								|it = 'Storno';
																								|pl = 'Storno';
																								|tr = 'İptal'"));
	ElsIf MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings Then
		DeletedTypesOfTransactions.Add(Enums.PostingTypesFinancialAccounting.ReversingEntry);
		TypesOfTransactionsToAdd.Add(Enums.PostingTypesFinancialAccounting.Reverse, NStr("vi = 'Đảo ngược';
																						|ru = 'Реверс';
																						|en = 'Reverse'; fa = 'معکوس';
																						|it = 'Inversa';
																						|pl = 'Rewers';
																						|tr = 'Ters'"));
	Else
		DeletedTypesOfTransactions.Add(Enums.PostingTypesFinancialAccounting.Reverse);
		TypesOfTransactionsToAdd.Add(Enums.PostingTypesFinancialAccounting.ReversingEntry, NStr("vi = 'Đảo ngược';
																								|ru = 'Сторно';
																								|en = 'Storno'; fa = 'استورنو';
																								|it = 'Storno';
																								|pl = 'Storno';
																								|tr = 'İptal'"));
	EndIf;
	
	For Each PostingType In DeletedTypesOfTransactions Do
		ListItemToDelete = ChoiceList.FindByValue(PostingType);
		If ListItemToDelete <> Undefined Then
			ChoiceList.Delete(ListItemToDelete);
		EndIf;
	EndDo;
	
	For Each TransactionTypeDescription In TypesOfTransactionsToAdd Do
		If ChoiceList.FindByValue(TransactionTypeDescription.Value) = Undefined Then
			ChoiceList.Insert(1, TransactionTypeDescription.Value, TransactionTypeDescription.Presentation);
		EndIf;
	EndDo;
	
EndProcedure

#Region KBSPConnection

// (See ReportsOptionsOverridable.CustomizeReportsOptions
// 
Procedure CustomizeReportsOptions(Settings) Export
	
	DisplayReportOptions = False;
	
	Reports.UseAccountsAndExtraDimensionInSettings.CustomizeReportOptions(Settings);
	Reports.FinancialReport.CustomizeReportOptions(Settings);
	Reports.AccountingReportFinancialAccounting.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.AccountingReportWithCorrespondenceFinancialAccounting.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.AccountCardFinancialAccounting.CustomizeReportOptions(Settings, DisplayReportOptions);
	Reports.ArticulationStatementFinancialAccounting.CustomizeReportOptions(Settings);

	FinancialAccountingByFinancialRegisterData.CustomizeReportsOptions(Settings);
	FinancialAccountingUponOperationalAccountingData.CustomizeReportsOptions(Settings);
	FinancialAccountingUponLocalAccounting.CustomizeReportsOptions(Settings);
	
EndProcedure

// Parameters:
// 	Objects - Array of MetadataObject -
//
Procedure DefineObjectsWithReportCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.TransactionFinancialAccounting);
	Objects.Add(Metadata.ChartsOfAccounts.International);
	Objects.Add(Metadata.Catalogs.FinancialAccountingPostingGenerationSetting);
	Objects.Add(Metadata.Documents.FinancialStatementCopy);
	Objects.Add(Metadata.Documents.PeriodEndTransactionFinancialAccounting);
	Objects.Add(Metadata.Documents.PostingPayrollExpensesInFinancialAccounting2_5);
	
EndProcedure

// (See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck)
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources, "Document.PeriodEndTransactionFinancialAccounting"	, "Date", "FinancialAccounting", "Organization");
	PeriodClosingDates.AddRow(DataSources, "Document.TransactionFinancialAccounting"					, "Date", "FinancialAccounting", "Organization");
	
EndProcedure

// Fills in the matching of method names to their aliases for calling from the task queue.
//
// (See JobsQueueOverridable.OnDefineHandlerAliases)
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.MonthEndTransactions.MethodName);
	
EndProcedure

// Generates a list of queue task templates.
//
// (See JobsQueueOverridable.OnGetTemplateList)
// 
// Parameters:
// 	JobTemplates - Array of String -
//
Procedure OnGetTemplateList(JobTemplates) Export
	
	JobTemplates.Add(Metadata.ScheduledJobs.DocumentPostingInFinancialAccounting.Name);
	
EndProcedure

// Defines the following properties of routine tasks:
//  - dependence on functional options.
//  - ability to run the program in different modes.
//  - other parameters.
//
// (See ScheduledJobsOverridable.OnDefineScheduledJobSettings)
// 
// Parameters:
// 	Settings - See ScheduledJobsOverridable.OnDefineScheduledJobSettings.Settings 
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.DocumentPostingInFinancialAccounting;
	Setting.FunctionalOption = Metadata.FunctionalOptions.UseFinancialAccounting;
	Setting.EnableOnEnableFunctionalOption = False;	
	
EndProcedure

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
// 	Objects - Array of MetadataObject -
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export
	
	Objects.Add(Metadata.Documents.TransactionFinancialAccounting);
	Objects.Add(Metadata.Documents.FinancialStatementCopy);
	Objects.Add(Metadata.Documents.PeriodEndTransactionFinancialAccounting);
	Objects.Add(Metadata.Documents.PostingPayrollExpensesInFinancialAccounting2_5);
	Objects.Add(Metadata.Documents.ReverseVATAccrual);
	
EndProcedure

// Allows you to specify lists where metadata objects contain a description
// of the access restriction logic in the Manager modules or the module being redefined.
//
// (See AccessManagementOverridable.OnFillListsWithAccessRestriction)
//
Procedure OnFillListsWithAccessRestriction(Lists) Export
	Lists.Insert(Metadata.Catalogs.StandardTransactionsOfFinancialAccounting, True);
	Lists.Insert(Metadata.Documents.PeriodEndTransactionFinancialAccounting, True);
	Lists.Insert(Metadata.InformationRegisters.DocumentPostingInFinancialAccounting, True);
	Lists.Insert(Metadata.Documents.FinancialStatementCopy, True);
	Lists.Insert(Metadata.Catalogs.StandardTransactionsOfFinancialAccounting, True);
	Lists.Insert(Metadata.AccountingRegisters.International, True);
	Lists.Insert(Metadata.AccountingRegisters.InternationalWithoutCorrespondence, True);
	Lists.Insert(Metadata.Documents.TransactionFinancialAccounting, True);
EndProcedure

// Define metadata objects whose Manager modules restrict the ability 
// to edit details during group changes.
// (See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes)
//
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs.FinancialAccountingPostingGenerationSettingAttachedFiles.FullName(), "AttributesToEditInBatchProcessing");
	
EndProcedure

// See PrintManagementOverridable.OnDefinePrintSettings
//
Procedure OnDefinePrintSettings(Settings) Export

	ListOfObjects = Settings.PrintObjects;	
	ListOfObjects.Add(Documents.TransactionFinancialAccounting)	
EndProcedure
#EndRegion

#EndRegion

#Region Private

// To set a conditional execution field of Subconto and Predstavlyayuschie table for forms of transaction.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - collection of elements of the form's conditional design.
//  TableOfTransactions - String - Name of the form table that displays the transaction.
//  DrCr - String - The wiring side is " Dt " or "CT".
//  ExtDimensionNumber - Number,String - the ordinal number of the sub-konto.
//
Procedure SetExtdimensionClearance(ConditionalAppearance, TableOfTransactions, DrCr, ExtDimensionNumber)
	
	Number = String(ExtDimensionNumber);
	ExtDimensionField = New DataCompositionField(TableOfTransactions + ".ExtDimension" + DrCr + Number);
	ExtdimensionViewField = New DataCompositionField("PresentationViewOfExtdimension" + DrCr + Number);
	
	// Grey text of the sub-account fields if the account is specified and its available sub-accounts are not filled in.
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = ExtdimensionViewField;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".Account" + DrCr);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ExtDimensionField;
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	// If the account does not have a sub-account, then hide the input prompts
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = ExtdimensionViewField;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = ExtDimensionField;
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Show", False);
	
EndProcedure

// Set the conditional design of the Currency and currency Sum fields for the transaction form table.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - collection of elements of the form's conditional design.
//  TableOfTransactions - String - Name of the form table that displays the transaction.
//  DrCr - String - The wiring side is " Dt " or "CT".
//  Subconto number - Number, String-ordinal number of the subconto.
//
Procedure SetCurrencyRegistration(ConditionalAppearance, TableOfTransactions, DrCr)
	
	// If the account has currency accounting and the currency is not specified, then highlight the blank field.
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Currency" + DrCr);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".CurrencyAccounting" + DrCr);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".Currency" + DrCr);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

// Set the conditional design of the Quantity field for the transaction form table.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - collection of elements of the form's conditional design.
//  TableOfTransactions - String - Name of the form table that displays the transaction.
//  DrCr - String - The wiring side is " Dt " or "CT".
//
Procedure SetQuantityClearance(ConditionalAppearance, TableOfTransactions, DrCr)
	
	// If quantitative accounting is conducted on the account and the quantity is not specified, then highlight the blank field.
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("Count" + DrCr);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".QuantitativeAccounting" + DrCr);
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TableOfTransactions + ".Count" + DrCr);
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

#EndRegion

