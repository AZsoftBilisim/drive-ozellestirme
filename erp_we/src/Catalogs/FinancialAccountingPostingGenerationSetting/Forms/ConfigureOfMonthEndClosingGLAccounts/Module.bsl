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
		
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

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

#Region TableEventHandlersForms

&AtClient
Procedure IncomeAccountsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	SelectionTableName = "IncomeAccounts";
	OpenInvoiceSelectionForm();
	
EndProcedure

&AtClient
Procedure ExpenseAccountsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	SelectionTableName = "ExpenseAccounts";
	OpenInvoiceSelectionForm();
	
EndProcedure

&AtClient
Procedure AccountsOfProfitLossBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	SelectionTableName = "AccountsOfProfitLoss";
	OpenInvoiceSelectionForm();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectIncomeAccounts(Command)
	
	SelectionTableName = "IncomeAccounts";
	AccountSelection_();
	
EndProcedure

&AtClient
Procedure SelectExpenseAccounts(Command)
	
	SelectionTableName = "ExpenseAccounts";
	AccountSelection_();
	
EndProcedure

&AtClient
Procedure SelectAccountsOfProfitsLosses(Command)
	
	SelectionTableName = "AccountsOfProfitLoss";
	AccountSelection_();
	
EndProcedure

&AtClient
Procedure CompleteEditing(Command)
	
	SaveClosingAccounts();
	Close(QuestionDialogMode.OK);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AccountSelection_()
	
	OpenInvoiceSelectionForm(True);
	
EndProcedure

&AtClient
Procedure OpenInvoiceSelectionForm(Pickup = False)
	
	FormParameters = New Structure;
	// Standard form parameters.
	FormParameters.Insert("CloseOnChoice",            Not Pickup);
	FormParameters.Insert("CloseOnOwnerClose", True);
	FormParameters.Insert("OnlyAllowed", True);
	
	// Standard options for the selection form (see the Managed Form Extension for a dynamic list) .
	FormParameters.Insert("MultipleChoice",            Pickup);
	FormParameters.Insert("ChoiceMode",                   True);
	// Assumed banking details.
	FormParameters.Insert("WindowOpeningMode",             FormWindowOpeningMode.LockOwnerWindow);
	FormParameters.Insert("EnableStartDrag", False);
	
	FormParameters.Insert("Filter", New Structure("ChartOfAccounts", ChartOfAccounts));
	
	OpenForm("ChartOfAccounts.International.ChoiceForm",FormParameters,ThisForm);
	
EndProcedure

&AtClient
Procedure AddInvoice(Account)
	
	TabularSection = ThisObject[SelectionTableName];// CatalogTabularSection.FinancialAccountingPostingGenerationSetting.IncomeAccounts - 
	NewRow = TabularSection.Add(); 
	NewRow.Account = Account;
	
EndProcedure

&AtServer
Procedure ReadSettingsData()
	
	If ValueIsFilled(AddressOfAccountSettings) Then
		ClosingAccounts = GetFromTempStorage(AddressOfAccountSettings);
	Else
		Query = New Query;
		Query.Text = 
		"SELECT
		|	TransactionGenerationSettings.GLAccountOfIncome,
		|	TransactionGenerationSettings.GLAccountOfExpenses,
		|	TransactionGenerationSettings.GLAccountOfRetainedProfitLoss
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
		|WHERE
		|	TransactionGenerationSettings.Ref = &PostingGenerationSetting
		|;
		|
		|////////////////////////////
		|SELECT
		|	RevenueAccountPostingSettings.Account AS Account
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting.IncomeAccounts AS RevenueAccountPostingSettings
		|WHERE
		|	RevenueAccountPostingSettings.Ref = &PostingGenerationSetting
		|;
		|
		|////////////////////////////
		|SELECT
		|	SettingsForGeneratingExpenseAccountTransactions.Account AS Account
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting.ExpenseAccounts AS SettingsForGeneratingExpenseAccountTransactions
		|WHERE
		|	SettingsForGeneratingExpenseAccountTransactions.Ref = &PostingGenerationSetting
		|;
		|
		|////////////////////////////
		|SELECT
		|	SettingsForGeneratingProfitLossAccountTransactions.Account AS Account
		|FROM
		|	Catalog.FinancialAccountingPostingGenerationSetting.AccountsOfProfitLoss AS SettingsForGeneratingProfitLossAccountTransactions
		|WHERE
		|	SettingsForGeneratingProfitLossAccountTransactions.Ref = &PostingGenerationSetting
		|";
		Query.SetParameter("PostingGenerationSetting", PostingGenerationSetting);
		
		QueryResults = Query.ExecuteBatch();
		
		HeaderSelection = QueryResults[0].Select();
		HeaderSelection.Next();
		
		ClosingAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ClosingAccounts();
		ClosingAccounts.GLAccountOfIncome = HeaderSelection.GLAccountOfIncome;
		ClosingAccounts.GLAccountOfExpenses = HeaderSelection.GLAccountOfExpenses;
		ClosingAccounts.GLAccountOfRetainedProfitLoss = HeaderSelection.GLAccountOfRetainedProfitLoss;
		
		ClosingAccounts.IncomeAccounts = QueryResults[1].Unload();
		ClosingAccounts.ExpenseAccounts = QueryResults[2].Unload();
		ClosingAccounts.AccountsOfProfitLoss = QueryResults[3].Unload();
		
	EndIf;
	
	FillPropertyValues(ThisForm,ClosingAccounts,,"IncomeAccounts,ExpenseAccounts,AccountsOfProfitLoss");
	CommonClientServer.SupplementTable(ClosingAccounts.IncomeAccounts, IncomeAccounts);
	CommonClientServer.SupplementTable(ClosingAccounts.ExpenseAccounts, ExpenseAccounts);
	CommonClientServer.SupplementTable(ClosingAccounts.AccountsOfProfitLoss, AccountsOfProfitLoss);
	
EndProcedure

&AtServer
Procedure SaveClosingAccounts()
	
	ClosingAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ClosingAccounts();
	FillPropertyValues(ClosingAccounts,ThisForm,,"IncomeAccounts,ExpenseAccounts,AccountsOfProfitLoss");
	ClosingAccounts.IncomeAccounts = IncomeAccounts.Unload();
	ClosingAccounts.ExpenseAccounts = ExpenseAccounts.Unload();
	ClosingAccounts.AccountsOfProfitLoss = AccountsOfProfitLoss.Unload();
	
	If ValueIsFilled(AddressOfAccountSettings) Then
		PutToTempStorage(ClosingAccounts, AddressOfAccountSettings);
	ElsIf ValueIsFilled(PostingGenerationSetting) Then
		CatalogObject = PostingGenerationSetting.GetObject();
		CatalogObject.Lock();
		CatalogObject.GLAccountOfIncome = ClosingAccounts.GLAccountOfIncome;
		CatalogObject.GLAccountOfExpenses = ClosingAccounts.GLAccountOfExpenses;
		CatalogObject.GLAccountOfRetainedProfitLoss = ClosingAccounts.GLAccountOfRetainedProfitLoss;
		CatalogObject.IncomeAccounts.Load(ClosingAccounts.IncomeAccounts);
		CatalogObject.ExpenseAccounts.Load(ClosingAccounts.ExpenseAccounts);
		CatalogObject.AccountsOfProfitLoss.Load(ClosingAccounts.AccountsOfProfitLoss);
		CatalogObject.Write();
	EndIf;
	
EndProcedure

#EndRegion