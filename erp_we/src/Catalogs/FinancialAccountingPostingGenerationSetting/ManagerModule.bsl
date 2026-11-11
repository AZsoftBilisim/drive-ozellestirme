#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the transaction generation setting, if there is one for the chart of accounts. Otherwise returns Undefined.
// 
// Parameters:
//   ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
//   
// Returns:
//   CatalogRef.FinancialAccountingPostingGenerationSetting, Undefined - 
//
Function ConfiguringDefaultPostingGeneration(ChartOfAccounts) Export
	
	If Not ValueIsFilled(ChartOfAccounts) Then
		Return Undefined;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 2
	|	TransactionGenerationSettings.Ref
	|FROM
	|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|WHERE
	|	TransactionGenerationSettings.Owner = &ChartOfAccounts
	|	AND NOT TransactionGenerationSettings.DeletionMark";
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	
	Selection = Query.Execute().Select();
	Count = Selection.Count();
	
	If Count = 0 Then
		
		BasicSetup = Catalogs.FinancialAccountingPostingGenerationSetting.CreateItem();
		BasicSetup.Description = NStr("vi = 'Chính';
										|ru = 'Основная';
										|en = 'Main'; fa = 'اصلی';
										|it = 'Principale';
										|pl = 'Main';
										|tr = 'Ana'", Common.DefaultLanguageCode());
		BasicSetup.Owner = ChartOfAccounts;
		BasicSetup.Fill(Undefined);
		BasicSetup.Write();
		
		Return BasicSetup.Ref;
		
	ElsIf Count = 1 Then
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;

EndFunction // Closure Account()

// The structure of the details of the reference list element containing the closing accounts of the period.
// 
// Returns:
//  Structure - the structure keys contain the names of the Attributes (table parts) of the closing accounts:
// * GLAccountOfIncome - ChartOfAccountsRef.International - 
// * GLAccountOfExpenses - ChartOfAccountsRef.International - 
// * GLAccountOfRetainedProfitLoss - ChartOfAccountsRef.International - 
// * IncomeAccounts - ValueTable - :
// 		** Account - ChartOfAccountsRef.International - 
// * ExpenseAccounts - ValueTable - :
// 		** Account - ChartOfAccountsRef.International - 
// * AccountsOfProfitLoss - ValueTable - :
// 		** Account - ChartOfAccountsRef.International - 
Function ClosingAccounts() Export

	Result = New Structure;
	
	EmptyAccount = ChartsOfAccounts.International.EmptyRef();
	Result.Insert("GLAccountOfIncome",	EmptyAccount);
	Result.Insert("GLAccountOfExpenses", EmptyAccount);
	Result.Insert("GLAccountOfRetainedProfitLoss", EmptyAccount);
	
	EmptyVT = New ValueTable;
	EmptyVT.Columns.Add("Account", New TypeDescription("ChartOfAccountsRef.International"));
	Result.Insert("IncomeAccounts",	EmptyVT);
	Result.Insert("ExpenseAccounts",	EmptyVT);
	Result.Insert("AccountsOfProfitLoss",EmptyVT);
	
	Return Result;

EndFunction // Closure Account()

// The structure of the details of the reference list element containing accounts reflecting exchange differences.
// 
// Returns:
//  Structure - the structure keys contain the names of the Attributes (tabular parts) of the exchange rate reflection accounts:
// * ForeignExchangeGain - ChartOfAccountsRef.International - 
// * IncomeItemForExchangeDifferences - Undefined, ChartOfCharacteristicTypesRef.IncomeItems - 
// * GLAccountOfExchangeLoss - ChartOfAccountsRef.International - 
// * ExpenseItemForExchangeLoss - Undefined, ChartOfCharacteristicTypesRef.ExpenseItems - 
// * IncomeFromTranslationToPresentationCurrency - ChartOfAccountsRef.International - 
// * IncomeExpenseItemForRecalculationVariances - Undefined, ChartOfCharacteristicTypesRef.IncomeItems - 
// * ExpensesDifferencesArisingFromConversionToPresentationCurrency - ChartOfAccountsRef.International - 
// * ExpenseItemForTranslationsReserve - Undefined, ChartOfCharacteristicTypesRef.ExpenseItems - 
// * ExcludeFromTheCalculationOfTheKR - ValueTable - :
// 		** Account - ChartOfAccountsRef.International - 
// * ExcludeFromRecalculationToPresentationCurrency - ValueTable - :
//		** Account - ChartOfAccountsRef.International - 
Function ForeignExchangeAccounts() Export

	Result = New Structure;
	
	EmptyAccount = ChartsOfAccounts.International.EmptyRef();
	Result.Insert("ForeignExchangeGain", EmptyAccount);
	Result.Insert("IncomeItemForExchangeDifferences", Undefined);
	
	Result.Insert("GLAccountOfExchangeLoss", EmptyAccount);
	Result.Insert("ExpenseItemForExchangeLoss", Undefined);
	
	Result.Insert("IncomeFromTranslationToPresentationCurrency", EmptyAccount);
	Result.Insert("IncomeExpenseItemForRecalculationVariances", Undefined);
	
	Result.Insert("ExpensesDifferencesArisingFromConversionToPresentationCurrency", EmptyAccount);
	Result.Insert("ExpenseItemForTranslationsReserve", Undefined);
	
	EmptyVT = New ValueTable;
	EmptyVT.Columns.Add("Account", New TypeDescription("ChartOfAccountsRef.International"));
	Result.Insert("ExcludeFromTheCalculationOfTheKR",	EmptyVT);
	Result.Insert("ExcludeFromRecalculationToPresentationCurrency",EmptyVT);
	
	Return Result;

EndFunction // Account of Course differences()

// Returns the table of accounts excluded from the calculation of exchange differences.
// 
// Parameters:
//	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
//	
// Returns:
//  ValueTable - accounting accounts excluded from the calculation of exchange differences:
//  	* Account - ChartOfAccountsRef.International - 
//  	* Exclude - Boolean - 
//  	* Order - String - 
Function AccountsForCalculationOfKR(ChartOfAccounts) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	International.Ref AS Account,
	|	International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency AS Exclude,
	|	International.Order AS Order
	|FROM
	|	ChartOfAccounts.International AS International
	|WHERE
	|	International.ChartOfAccounts = &ChartOfAccounts
	|	AND International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency = TRUE
	|
	|ORDER BY
	|	Order";
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the table of accounts excluded from the calculation of exchange differences.
// 
// Parameters:
//	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - 
//	ExceptionAccounts - ValueTable - table with columns:
//		* GLAccount - ChartOfAccountsRef.International - 
//
Procedure RecordInvoicesForCalculatingKr(ChartOfAccounts, ExceptionAccounts) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ExceptionAccounts.Account AS Ref
	|INTO ExceptionAccounts
	|FROM
	|	&ExceptionAccounts AS ExceptionAccounts
	|WHERE
	|	ExceptionAccounts.Exclude
	|INDEX BY
	|	Ref
	|;
	|
	|SELECT
	|	International.Ref AS Ref,
	|	CASE
	|		WHEN International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|				AND ExceptionAccounts.Ref IS NULL
	|			THEN FALSE
	|		WHEN NOT International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|				AND NOT ExceptionAccounts.Ref IS NULL
	|			THEN TRUE
	|		ELSE International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|	END AS ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|FROM
	|	ChartOfAccounts.International AS International
	|	LEFT JOIN 
	|		ExceptionAccounts AS ExceptionAccounts
	|	ON
	|		International.Ref = ExceptionAccounts.Ref
	|WHERE
	|	CASE
	|		WHEN International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|				AND ExceptionAccounts.Ref IS NULL
	|			THEN FALSE
	|		WHEN NOT International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|				AND NOT ExceptionAccounts.Ref IS NULL
	|			THEN TRUE
	|		ELSE International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency
	|	END <> International.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency  
	|	AND International.ChartOfAccounts = &ChartOfAccounts
	|";
	Query.SetParameter("ExceptionAccounts", ExceptionAccounts);
	Query.SetParameter("ChartOfAccounts", ChartOfAccounts);
	Selection  = Query.Execute().Select();
	While Selection.Next() Do
		
		Object = Selection.Ref.GetObject(); // ChartOfAccountsObject.International - 
		Object.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency = Selection.ExcludeFromExchangeDifferenceCalculationInFunctionalCurrency;
		Object.Write();
		
	EndDo
	
EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	AttributesToLock.Add("MethodOfCancelingTransactions");
	AttributesToLock.Add("DivisionIntoShortTermLongTermAssetsAndLiabilities");
	AttributesToLock.Add("RevenueTransactionsExcludingVAT");
	AttributesToLock.Add("ClosingOfIncomeAndExpenseAccounts");
	
	Return AttributesToLock;
	
EndFunction

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Parameters.Property("Organization") 
		And Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		
		StandardProcessing = False;
		ChoiceData = New ValueList();
		Query = New Query;
		Query.Text = 
		"SELECT
		|	TransactionGenerationSettings.Ref AS Ref,
		|	MAX(ISNULL(BusinessAccountPlans.Period, &DateEmpty)) AS PeriodOfApplication
		|INTO TTSettingsForGeneratingTransactions
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|	LEFT JOIN
		|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
		|	ON
		|		BusinessAccountPlans.Organization = &Organization
		|		AND BusinessAccountPlans.PostingGenerationSetting = TransactionGenerationSettings.Ref
		|WHERE
		|	NOT TransactionGenerationSettings.DeletionMark
		|	AND TransactionGenerationSettings.Owner = &ChartOfAccounts
		|
		|GROUP BY
		|	Ref
		|;
		|
		|SELECT
		|	TransactionGenerationSettings.Ref AS Ref,
		|	REFPRESENTATION(TransactionGenerationSettings.Ref) AS Presentation,
		|	TransactionGenerationSettings.PeriodOfApplication AS PeriodOfApplication
		|FROM
		|	TTSettingsForGeneratingTransactions AS TransactionGenerationSettings
		|
		|ORDER BY
		|	PeriodOfApplication DESC
		|";
		Query.SetParameter("Organization", Parameters.Organization);
		Query.SetParameter("ChartOfAccounts", Parameters.Filter.Owner);
		Query.SetParameter("DateEmpty", Date(1,1,1));
		Selection = Query.Execute().Select();
		IndexOf = 0;
		While Selection.Next() Do
			
			If Not ValueIsFilled(Selection.PeriodOfApplication) Then
				Presentation = Selection.Presentation;
			ElsIf IndexOf = 0 Then
				Presentation = StrTemplate(NStr("vi = '%1 (áp dụng từ %2)';
												|ru = '%1 (применяется с %2)';
												|en = '%1 (applied since %2)'; fa = '%1 (applied since %2)';
												|it = '%1 (si applica dal %2)';
												|pl = '%1 (jest stosowana od %2)';
												|tr = '%1 (%2 itibarıyla uygulanır)'"), 
					Selection.Presentation, Format(Selection.PeriodOfApplication, "DLF=D"));
			Else
				Presentation = StrTemplate(NStr("vi = '%1 (đã áp dụng từ %2)';
												|ru = '%1 (применялась с %2)';
												|en = '%1 (has been applied since %2)'; fa = '%1 (has been applied since %2)';
												|it = '%1 (applicata con %2)';
												|pl = '%1 (nie było stosowano z%2)';
												|tr = '%1 (%2 ile uygulandı)'"), 
					Selection.Presentation, Format(Selection.PeriodOfApplication, "DLF=D"));
			EndIf;
			ChoiceData.Add(Selection.Ref, Presentation);
			IndexOf = IndexOf + 1;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Returns the structure of the transaction generation settings. If an element of the settings Catalog is passed, the structure is filled
// in with the values of the Attributes of the passed element. If the Fill parameter is always set to True, an attempt 
// is made to fill in the structure properties with the values of the corresponding Attributes that are identical in all Catalog elements.
// 
// Parameters:
//  PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting - an element of the settings directory
//  FillInForAll - Boolean - Determines the need to fill in the properties with the values of the requisites that are the same in all elements of the directory
//
// Returns:
//  Structure - Contains keys:
//   * OptionForGeneratingTransactions - Undefined, EnumRef.EntryGenerationOptions - 
//   * MethodOfAccountingForImproperValues - Undefined, EnumRef.MethodsOfNotOwnedControlledValuesAccounting - 
//   * MethodOfCancelingTransactions - Undefined, EnumRef.MethodsOfCancelingPostingsInFinancialAccounting - 
//   * AllocationOfLongTermAssetsAndLiabilities - Undefined, Boolean - 
//   * RevenueExcludingVAT - Undefined, Boolean -
//   * ClosingOfIncomeAndExpenseAccounts - Undefined, EnumRef.ClosingOfIncomeAndExpenseAccounts - 
//
Function TransactionGenerationSettings(PostingGenerationSetting = Undefined, FillInForAll = True) Export
	
	TransactionSettings = New Structure();
	TransactionSettings.Insert("OptionForGeneratingTransactions", Undefined);
	TransactionSettings.Insert("MethodOfAccountingForImproperValues", Undefined);
	TransactionSettings.Insert("MethodOfCancelingTransactions", Undefined);
	TransactionSettings.Insert("AllocationOfLongTermAssetsAndLiabilities", Undefined);
	TransactionSettings.Insert("RevenueExcludingVAT", Undefined);
	TransactionSettings.Insert("ClosingOfIncomeAndExpenseAccounts", Undefined);
	
	If ValueIsFilled(PostingGenerationSetting) Then
		TransactionSettings.OptionForGeneratingTransactions = "Owner.OptionForGeneratingTransactions";
		TransactionSettings.MethodOfAccountingForImproperValues = "Owner.MethodOfNotOwnedControlledValuesAccounting";
		TransactionSettings.MethodOfCancelingTransactions = "MethodOfCancelingTransactions";
		TransactionSettings.AllocationOfLongTermAssetsAndLiabilities = "DivisionIntoShortTermLongTermAssetsAndLiabilities";
		TransactionSettings.RevenueExcludingVAT = "RevenueTransactionsExcludingVAT";
		TransactionSettings.ClosingOfIncomeAndExpenseAccounts = "ClosingOfIncomeAndExpenseAccounts";
		
		TransactionSettings = Common.ObjectAttributesValues(
			PostingGenerationSetting, TransactionSettings);
	ElsIf FillInForAll Then
		QueryText = "
		|SELECT
		|	COUNT(DISTINCT TransactionGenerationSettings.Owner.OptionForGeneratingTransactions) AS NumberOfOptionsForGeneratingTransactions,
		|	COUNT(DISTINCT TransactionGenerationSettings.Owner.MethodOfNotOwnedControlledValuesAccounting) AS QuantityMethodOfAccountingForImproperValues,
		|	COUNT(DISTINCT TransactionGenerationSettings.MethodOfCancelingTransactions) AS NumberOfTransactionsCancellationMethod,
		|	COUNT(DISTINCT TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities) AS NumberOfAllocationOfLongTermAssetsLiabilities,
		|	COUNT(DISTINCT TransactionGenerationSettings.RevenueTransactionsExcludingVAT) AS QuantityRevenueExcludingVAT,
		|	COUNT(DISTINCT TransactionGenerationSettings.ClosingOfIncomeAndExpenseAccounts) AS NumberOfIncomeAndExpenseAccountClosures,
		|	MAX(TransactionGenerationSettings.Owner.OptionForGeneratingTransactions) AS OptionForGeneratingTransactions,
		|	MAX(TransactionGenerationSettings.Owner.MethodOfNotOwnedControlledValuesAccounting) AS MethodOfAccountingForImproperValues,
		|	MAX(TransactionGenerationSettings.MethodOfCancelingTransactions) AS MethodOfCancelingTransactions,
		|	MAX(TransactionGenerationSettings.DivisionIntoShortTermLongTermAssetsAndLiabilities) AS AllocationOfLongTermAssetsAndLiabilities,
		|	MAX(TransactionGenerationSettings.RevenueTransactionsExcludingVAT) AS RevenueExcludingVAT,
		|	MAX(TransactionGenerationSettings.ClosingOfIncomeAndExpenseAccounts) AS ClosingOfIncomeAndExpenseAccounts
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|WHERE
		|	NOT TransactionGenerationSettings.DeletionMark
		|";
		Query = New Query(QueryText);
		Result = Query.Execute();
		
		If Not Result.IsEmpty() Then
			Selection = Result.Select();
			Selection.Next();
			If Selection.NumberOfOptionsForGeneratingTransactions = 1 Then
				TransactionSettings.OptionForGeneratingTransactions = Selection.OptionForGeneratingTransactions;
			EndIf;
			If Selection.QuantityMethodOfAccountingForImproperValues = 1 Then
				TransactionSettings.MethodOfAccountingForImproperValues = Selection.MethodOfAccountingForImproperValues;
			EndIf;
			If Selection.NumberOfTransactionsCancellationMethod = 1 Then
				TransactionSettings.MethodOfCancelingTransactions = Selection.MethodOfCancelingTransactions;
			EndIf;
			If Selection.NumberOfAllocationOfLongTermAssetsLiabilities = 1 Then
				TransactionSettings.AllocationOfLongTermAssetsAndLiabilities = Selection.AllocationOfLongTermAssetsAndLiabilities;
			EndIf;
			If Selection.QuantityRevenueExcludingVAT = 1 Then
				TransactionSettings.RevenueExcludingVAT = Selection.RevenueExcludingVAT;
			EndIf;
			If Selection.NumberOfIncomeAndExpenseAccountClosures = 1 Then
				TransactionSettings.ClosingOfIncomeAndExpenseAccounts = Selection.ClosingOfIncomeAndExpenseAccounts;
			EndIf;
		EndIf;
	EndIf;
	
	Return TransactionSettings;
	
EndFunction

// The transaction generation setting is used.
// 
// Parameters:
//  PostingGenerationSetting - CatalogRef.FinancialAccountingPostingGenerationSetting -  Setting up the formation of transactions
// 
// Returns:
//  Boolean - Setting Up The Formation Of Transactions Is Used
Function SettingUpFormationOfTransactionsIsUsed(PostingGenerationSetting) Export
	
	If Not ValueIsFilled(PostingGenerationSetting) Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
	
	Query.Text = "
	|SELECT
	|	BusinessAccountPlans.ChartOfAccounts AS ChartOfAccounts,
	|	BusinessAccountPlans.Organization AS Organization,
	|	BusinessAccountPlans.Period AS BeginOfPeriod,
	|	ISNULL(MIN(ExpirationPeriodsForSettings.Period), &CurrentDate) AS PeriodEnding
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
	|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS ExpirationPeriodsForSettings
	|		ON BusinessAccountPlans.ChartOfAccounts = ExpirationPeriodsForSettings.ChartOfAccounts
	|		 AND BusinessAccountPlans.Organization = ExpirationPeriodsForSettings.Organization
	|		 AND BusinessAccountPlans.Period < ExpirationPeriodsForSettings.Period
	|WHERE
	|	BusinessAccountPlans.PostingGenerationSetting = &PostingGenerationSetting
	|GROUP BY
	|	BusinessAccountPlans.ChartOfAccounts,
	|	BusinessAccountPlans.Organization,
	|	BusinessAccountPlans.Period
	|";
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return False;
	EndIf;

	TransactionRequestText = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	AccountingRegister.International AS International
	|WHERE
	|	International.Period BETWEEN &BeginOfPeriod77 AND &PeriodEnding77
	|	AND International.ChartOfAccounts = &ChartOfAccounts77
	|	AND International.Organization = &Organization77
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence AS International
	|WHERE
	|	International.Period BETWEEN &BeginOfPeriod77 AND &PeriodEnding77
	|	AND International.ChartOfAccounts = &ChartOfAccounts77
	|	AND International.Organization = &Organization77
	|";
	
	Selection = Result.Select();
	QueriesTexts = New Array();
	QueryNumber = 1;
	
	While Selection.Next() Do
		QueriesTexts.Add(StrReplace(TransactionRequestText, "77", QueryNumber));
		Query.SetParameter("BeginOfPeriod" + QueryNumber, Selection.BeginOfPeriod);
		Query.SetParameter("PeriodEnding" + QueryNumber, Selection.PeriodEnding);
		Query.SetParameter("ChartOfAccounts" + QueryNumber, Selection.ChartOfAccounts);
		Query.SetParameter("Organization" + QueryNumber, Selection.Organization);
		QueryNumber = QueryNumber + 1;
	EndDo;
	
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();
	
EndFunction

#EndRegion

#EndIf
