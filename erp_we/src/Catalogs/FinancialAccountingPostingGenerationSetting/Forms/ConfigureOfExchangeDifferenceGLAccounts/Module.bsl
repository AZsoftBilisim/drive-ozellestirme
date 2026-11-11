#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AddressOfAccountSettings = Parameters.AddressOfAccountSettings;
	PostingGenerationSetting = Parameters.PostingGenerationSetting;
	ChartOfAccounts = Parameters.ChartOfAccounts;
	
	If Not AccessRight("Edit", Metadata.Catalogs.FinancialAccountingPostingGenerationSetting) Then
		ReadOnly = True;
	EndIf;

	ReadSettingsData();
	FormControl();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		For Each Account In ValueSelected Do
			AddInvoice(Account);
		EndDo;
	Else
		AddInvoice(ValueSelected);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ForeignExchangeGainOnChange(Item)
	KRRevenuesOnChangeAtServer();
EndProcedure

&AtClient
Procedure GLAccountOfExchangeLossOnChange(Item)
	CDExpensesOnChangesAtServer();
EndProcedure

&AtClient
Procedure IncomeFromTranslationToPresentationCurrencyOnChange(Item)
	IncomeFromDifferencesInRecalculationOfVPOnChangesAtServer();
EndProcedure

&AtClient
Procedure ExpensesDifferencesArisingFromConversionToPresentationCurrencyOnChange(Item)
	ExpensesFromDifferencesInRecalculationOfVPOnChangesAtServer();
EndProcedure
#EndRegion

#Region FormTableItemsEventHandlersExcludeFromTheCalculationOfTheKR

&AtClient
Procedure ExcludeFromTheCalculationOfTheKRBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	SelectionTableName = "ExcludeFromTheCalculationOfTheKR";
	OpenInvoiceSelectionForm(True);
	
EndProcedure

&AtClient
Procedure ExcludeFromTheCalculationOfTheKRAccountOnChange(Item)
	
	Items.ExcludeFromTheCalculationOfTheKR.CurrentData.Exclude = True;
	
EndProcedure

&AtClient
Procedure ExcludeFromTheCalculationOfTheKRBeforeDeleteRow(Item, Cancel)
	
	RemovedAccount = Item.CurrentData.Account;
	
EndProcedure

&AtClient
Procedure ExcludeFromTheCalculationOfTheKRAfterDeleteRow(Item)
	
	NewAccount_ = ExcludeFromTheCalculationOfTheKR.Add();
	NewAccount_.Account = RemovedAccount;
	ExcludeFromTheCalculationOfTheKR.Sort("Account");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExcludeFromRecalculationToPresentationCurrency

&AtClient
Procedure ExcludeFromRecalculationToPresentationCurrencyBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	SelectionTableName = "ExcludeFromRecalculationToPresentationCurrency";
	OpenInvoiceSelectionForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateExceptionAccounts(Command)
	UpdateExceptionAccountsOnServer();
EndProcedure

&AtClient
Procedure SelectCalculationExceptionAccounts(Command)
	
	SelectionTableName = "ExcludeFromTheCalculationOfTheKR";
	AccountSelection_(True);
	
EndProcedure

&AtClient
Procedure SelectRecalculationExceptionAccounts(Command)
	
	SelectionTableName = "ExcludeFromRecalculationToPresentationCurrency";
	AccountSelection_();
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	SaveForeignExchangeAccounts();
	Close(QuestionDialogMode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AccountSelection_(CurrencyOnly = False)
	
	OpenInvoiceSelectionForm(CurrencyOnly, True);
	
EndProcedure

&AtClient
Procedure OpenInvoiceSelectionForm(CurrencyOnly = False, Pickup = False)
	
	FormParameters = New Structure;
	// Standard form parameters.
	FormParameters.Insert("CloseOnChoice",            Not Pickup);
	FormParameters.Insert("CloseOnOwnerClose", True);
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	
	// Standard options for the selection form (see the Managed Form Extension for a dynamic list) .
	FormParameters.Insert("MultipleChoice",            Pickup);
	FormParameters.Insert("ChoiceMode",                   True);
	// Assumed banking details.
	FormParameters.Insert("WindowOpeningMode",             FormWindowOpeningMode.LockOwnerWindow);
	FormParameters.Insert("EnableStartDrag", False);
	
	FormParameters.Insert("OnlyAllowed", True);
	
	Filter = New Structure;
	Filter.Insert("ChartOfAccounts", ChartOfAccounts);
	If CurrencyOnly Then
		Filter.Insert("Currency1", True);
	EndIf;
	FormParameters.Insert("Filter", Filter);
	
	OpenForm("ChartOfAccounts.International.ChoiceForm",FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure AddInvoice(Account)
	
	Exceptions = ThisObject[SelectionTableName]; // ValueTable - 
	NewRow = Exceptions.Add();
	NewRow.Account = Account;
	If SelectionTableName = "ExcludeFromTheCalculationOfTheKR" Then
		NewRow.Exclude = True;
		Items.ExcludeFromTheCalculationOfTheKR.Refresh();
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSettingsData()
	
	If ValueIsFilled(AddressOfAccountSettings) Then
		ForeignExchangeAccounts = GetFromTempStorage(AddressOfAccountSettings);
	Else
		Query = New Query;
		Query.Text = 
		"SELECT
		|	TransactionGenerationSettings.ForeignExchangeGain,
		|	TransactionGenerationSettings.IncomeItemForExchangeDifferences,
		|	TransactionGenerationSettings.GLAccountOfExchangeLoss,
		|	TransactionGenerationSettings.ExpenseItemForExchangeLoss,
		|	TransactionGenerationSettings.IncomeFromTranslationToPresentationCurrency,
		|	TransactionGenerationSettings.IncomeExpenseItemForRecalculationVariances,
		|	TransactionGenerationSettings.ExpensesDifferencesArisingFromConversionToPresentationCurrency,
		|	TransactionGenerationSettings.ExpenseItemForTranslationsReserve
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|WHERE
		|	TransactionGenerationSettings.Ref = &PostingGenerationSetting
		|;
		|
		|////////////////////////////
		|SELECT
		|	ExcludeTransactionGenerationSettingsFromEAPRecalculation.Account AS Account
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting.ExcludeFromRecalculationToPresentationCurrency AS ExcludeTransactionGenerationSettingsFromEAPRecalculation
		|WHERE
		|	ExcludeTransactionGenerationSettingsFromEAPRecalculation.Ref = &PostingGenerationSetting
		|";
		Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
		
		QueryResults = Query.ExecuteBatch();
		HeaderSelection = QueryResults[0].Select();
		HeaderSelection.Next();
		
		ForeignExchangeAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ForeignExchangeAccounts();
		ForeignExchangeAccounts.ForeignExchangeGain = HeaderSelection.ForeignExchangeGain;
		ForeignExchangeAccounts.IncomeItemForExchangeDifferences = HeaderSelection.IncomeItemForExchangeDifferences;
		ForeignExchangeAccounts.GLAccountOfExchangeLoss = HeaderSelection.GLAccountOfExchangeLoss;
		ForeignExchangeAccounts.ExpenseItemForExchangeLoss = HeaderSelection.ExpenseItemForExchangeLoss;
		ForeignExchangeAccounts.IncomeFromTranslationToPresentationCurrency = HeaderSelection.IncomeFromTranslationToPresentationCurrency;
		ForeignExchangeAccounts.IncomeExpenseItemForRecalculationVariances = HeaderSelection.IncomeExpenseItemForRecalculationVariances;
		ForeignExchangeAccounts.ExpensesDifferencesArisingFromConversionToPresentationCurrency = HeaderSelection.ExpensesDifferencesArisingFromConversionToPresentationCurrency;
		ForeignExchangeAccounts.ExpenseItemForTranslationsReserve = HeaderSelection.ExpenseItemForTranslationsReserve;
		
		ForeignExchangeAccounts.ExcludeFromRecalculationToPresentationCurrency = QueryResults[1].Unload();
		ForeignExchangeAccounts.ExcludeFromTheCalculationOfTheKR = 
			Catalogs.FinancialAccountingPostingGenerationSetting.AccountsForCalculationOfKR(ChartOfAccounts);
		
	EndIf;
	FillPropertyValues(ThisObject, ForeignExchangeAccounts,,"ExcludeFromTheCalculationOfTheKR,ExcludeFromRecalculationToPresentationCurrency");
	CommonClientServer.SupplementTable(ForeignExchangeAccounts.ExcludeFromTheCalculationOfTheKR, ExcludeFromTheCalculationOfTheKR);
	CommonClientServer.SupplementTable(ForeignExchangeAccounts.ExcludeFromRecalculationToPresentationCurrency, ExcludeFromRecalculationToPresentationCurrency);
	
EndProcedure

&AtServer
Procedure SaveForeignExchangeAccounts()
	
	ForeignExchangeAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ForeignExchangeAccounts();
	FillPropertyValues(ForeignExchangeAccounts,ThisObject, ,"ExcludeFromTheCalculationOfTheKR,ExcludeFromRecalculationToPresentationCurrency");
	ForeignExchangeAccounts.ExcludeFromTheCalculationOfTheKR = ExcludeFromTheCalculationOfTheKR.Unload();
	ForeignExchangeAccounts.ExcludeFromRecalculationToPresentationCurrency = ExcludeFromRecalculationToPresentationCurrency.Unload();
	
	If ValueIsFilled(AddressOfAccountSettings) Then
		PutToTempStorage(ForeignExchangeAccounts, AddressOfAccountSettings);
	ElsIf ValueIsFilled(PostingGenerationSetting) Then
		BeginTransaction();
		Try
			CatalogObject = PostingGenerationSetting.GetObject();
			CatalogObject.Lock();
			CatalogObject.ForeignExchangeGain = ForeignExchangeAccounts.ForeignExchangeGain;
			CatalogObject.IncomeItemForExchangeDifferences = ForeignExchangeAccounts.IncomeItemForExchangeDifferences;
			CatalogObject.ExpenseItemForExchangeLoss = ForeignExchangeAccounts.ExpenseItemForExchangeLoss;
			CatalogObject.IncomeFromTranslationToPresentationCurrency = ForeignExchangeAccounts.IncomeFromTranslationToPresentationCurrency;
			CatalogObject.IncomeExpenseItemForRecalculationVariances = ForeignExchangeAccounts.IncomeExpenseItemForRecalculationVariances;
			CatalogObject.ExpensesDifferencesArisingFromConversionToPresentationCurrency = ForeignExchangeAccounts.ExpensesDifferencesArisingFromConversionToPresentationCurrency;
			CatalogObject.ExpenseItemForTranslationsReserve = ForeignExchangeAccounts.ExpenseItemForTranslationsReserve;
			CatalogObject.ExcludeFromRecalculationToPresentationCurrency.Load(ForeignExchangeAccounts.ExcludeFromRecalculationToPresentationCurrency);
			CatalogObject.Write();
			
			Catalogs.FinancialAccountingPostingGenerationSetting.RecordInvoicesForCalculatingKr(
				ChartOfAccounts,
				ForeignExchangeAccounts.ExcludeFromTheCalculationOfTheKR);
				
			CommitTransaction();
		Except
			RollbackTransaction();
			ErrorText = DetailErrorDescription(ErrorInfo());
			Raise ErrorText
		EndTry;
		
	EndIf;
EndProcedure

&AtServer
Procedure UpdateExceptionAccountsOnServer()
	
	ExcludeFromTheCalculationOfTheKR.Load(Catalogs.FinancialAccountingPostingGenerationSetting.AccountsForCalculationOfKR(ChartOfAccounts));
	
EndProcedure

&AtServer
Procedure KRRevenuesOnChangeAtServer()
	AccountProperties = FinancialAccountingServerCached.AccountProperties(ForeignExchangeGain);
	ThereIsRevenueAnalytics = AccountHasAnalyticsOfIncomeExpenses(AccountProperties);
	If Not ThereIsRevenueAnalytics Then
		IncomeItemForExchangeDifferences = Undefined;
	EndIf;
	Items.IncomeItemForExchangeDifferences.Enabled = ThereIsRevenueAnalytics;
EndProcedure

&AtServer
Procedure CDExpensesOnChangesAtServer()
	AccountProperties = FinancialAccountingServerCached.AccountProperties(GLAccountOfExchangeLoss);
	ThereIsAnalyticsOfExpenses = AccountHasAnalyticsOfIncomeExpenses(AccountProperties);
	If Not ThereIsAnalyticsOfExpenses Then
		ExpenseItemForExchangeLoss = Undefined;
	EndIf;
	Items.ExpenseItemForExchangeLoss.Enabled = ThereIsAnalyticsOfExpenses;
EndProcedure

&AtServer
Procedure IncomeFromDifferencesInRecalculationOfVPOnChangesAtServer()
	AccountProperties = FinancialAccountingServerCached.AccountProperties(IncomeFromTranslationToPresentationCurrency);
	ThereIsRevenueAnalytics = AccountHasAnalyticsOfIncomeExpenses(AccountProperties);
	If Not ThereIsRevenueAnalytics Then
		IncomeExpenseItemForRecalculationVariances = Undefined;
	EndIf;
	Items.IncomeExpenseItemForRecalculationVariances.Enabled = ThereIsRevenueAnalytics;
EndProcedure

&AtServer
Procedure ExpensesFromDifferencesInRecalculationOfVPOnChangesAtServer()
	AccountProperties = FinancialAccountingServerCached.AccountProperties(ExpensesDifferencesArisingFromConversionToPresentationCurrency);
	ThereIsAnalyticsOfExpenses = AccountHasAnalyticsOfIncomeExpenses(AccountProperties);
	If Not ThereIsAnalyticsOfExpenses Then
		ExpenseItemForTranslationsReserve = Undefined;
	EndIf;
	Items.ExpenseItemForTranslationsReserve.Enabled = ThereIsAnalyticsOfExpenses;
EndProcedure

&AtServer
Function AccountHasAnalyticsOfIncomeExpenses(AccountProperties)
	
	IndexOf = 1;
	While IndexOf < 3 Do
		If AccountProperties["ExtDimensionType" + IndexOf] = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.ExpenseItems
			Or AccountProperties["ExtDimensionType" + IndexOf] = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.IncomeItems Then
			Return True;
		EndIf;
		IndexOf = IndexOf + 1;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure FormControl()
	
	Items.IncomeItemForExchangeDifferences.Enabled = AccountHasAnalyticsOfIncomeExpenses(FinancialAccountingServerCached.AccountProperties(ForeignExchangeGain));
	Items.ExpenseItemForExchangeLoss.Enabled = AccountHasAnalyticsOfIncomeExpenses(FinancialAccountingServerCached.AccountProperties(GLAccountOfExchangeLoss));
	Items.IncomeExpenseItemForRecalculationVariances.Enabled = AccountHasAnalyticsOfIncomeExpenses(FinancialAccountingServerCached.AccountProperties(IncomeFromTranslationToPresentationCurrency));
	Items.ExpenseItemForTranslationsReserve.Enabled = AccountHasAnalyticsOfIncomeExpenses(FinancialAccountingServerCached.AccountProperties(ExpensesDifferencesArisingFromConversionToPresentationCurrency));
	
	Items.ExcludeFromTheCalculationOfTheKR.RowFilter = New FixedStructure(New Structure("Exclude", True));
	
EndProcedure
	
#EndRegion