#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// If a single chart of accounts is used, a link to it is returned.
// If there are several, an empty link is returned.
// 
// Returns:
// 	CatalogRef.FinancialAccountingChartsOfAccounts - 
Function DefaultChartOfAccounts() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 2
	|	ChartsOfAccounts.Ref AS Ref
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
	|WHERE
	|	NOT ChartsOfAccounts.DeletionMark";
	
	Selection = Query.Execute().Select();
	Count = Selection.Count();
	If Count = 1 Then
		Selection.Next();
		Return Selection.Ref;
	EndIf;
	
	Return Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef();
	
EndFunction

// Returns the account plans for which transactions are generated with correspondence
// 
// Returns:
// 	ValueList - 
Function ChartOfAccountsWithTransactionsAndCorrespondence() Export
	
	Result = New ValueList;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ChartsOfAccounts.Ref AS Ref,
	|	ChartsOfAccounts.Description AS Description
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
	|WHERE
	|	NOT ChartsOfAccounts.DeletionMark
	|	AND ChartsOfAccounts.OptionForGeneratingTransactions = VALUE(Enum.EntryGenerationOptions.WithCorrespondence)";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Ref, Selection.Description);
	EndDo;
	
	Return Result;
	
EndFunction

// accounting in Man currency is available.
// 
// Returns:
//  Boolean - accounting in Man currency is available
Function AccountingInManCurrencyIsAvailable() Export
	
	AccountingInManCurrencyIsAvailable = True;
	If Not GetFunctionalOption("FinancialAccountingEntriesBasedOnOperationalAccountingData")
 		And GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData")
		And Not GetFunctionalOption("KeepManagementAccountingOnSelfFinancingChartOfAccounts") Then
		AccountingInManCurrencyIsAvailable = False;	
	EndIf;
	
	Return AccountingInManCurrencyIsAvailable;
	
EndFunction

// Defines the configuration for the initial fill of elements
//
// Parameters:
//  Settings - Structure - filling settings:
//   * OnInitialItemFilling - Boolean - if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// Called when the directory is initially filled in.
//
// Parameters:
//  LanguagesCodes - Array - list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable - fill-in data. The composition of columns corresponds to the set
//                                 of reference book details.
//  TabularSections - Structure - Key - Name of the table part of the object.
//                               Value-Uploads an empty table part to the table of values.
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	#Region International
	Item = Items.Add();
	Item.PredefinedDataName = "International";
	Item.Description = NStr("vi = 'Quốc tế';
							|ru = 'Международный';
							|en = 'Financial'; fa = 'Financial';
							|it = 'Internazionale';
							|pl = 'Financial';
							|tr = 'Finansal'", Common.DefaultLanguageCode());
	Item.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal;
	Item.PresentationCurrency = Constants.ManagementAccountingCurrency.Get();
	Item.MethodOfNotOwnedControlledValuesAccounting = Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts;
	Item.AccountsPresentation = Enums.PresentationOfFinancialAccountingAccounts.AsCodeAndName;
	If GetFunctionalOption("LocalizationRFService") Then
		Item.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
		Item.TransactionsWithoutCorrespondence = False;
		Item.TransactionsWithCorrespondence = True;
	Else
		Item.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence;
		Item.TransactionsWithoutCorrespondence = True;
		Item.TransactionsWithCorrespondence = False;
	EndIf;
	#EndRegion

EndProcedure

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array of String - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	AttributesToLock = New Array;
	AttributesToLock.Add("AccountingInFunctionalCurrency;AccountingInFunctionalCurrency");
	AttributesToLock.Add("PresentationCurrency;PresentationCurrency");
	AttributesToLock.Add("OptionForGeneratingTransactions;OptionForGeneratingTransactions");
	AttributesToLock.Add("MethodOfNotOwnedControlledValuesAccounting;MethodOfNotOwnedControlledValuesAccounting");
	
	Return AttributesToLock;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

Procedure CreateInternationalChartOfAccountsFirstRun() Export
	
	BeginTransaction();
	
	Try
		Block = New DataLock();
		LockItem = Block.Add("Catalog.FinancialAccountingChartsOfAccounts");
		LockItem.SetValue("Ref", International);
		Block.Lock();
		
		InternationalChartOfAccounts_ = International.GetObject();
		If Not ValueIsFilled(InternationalChartOfAccounts_.Description) Then
			InternationalChartOfAccounts_.Description = NStr("vi = 'Quốc tế';
															|ru = 'Международный';
															|en = 'Financial'; fa = 'Financial';
															|it = 'Internazionale';
															|pl = 'Financial';
															|tr = 'Finansal'", Common.DefaultLanguageCode()); // the string is written to the IB
			InternationalChartOfAccounts_.AccountingInFunctionalCurrency = Enums.AccountingKindsInFunctionalCurrency.InCurrencyOfLocal;
			InternationalChartOfAccounts_.MethodOfNotOwnedControlledValuesAccounting = Enums.MethodsOfNotOwnedControlledValuesAccounting.NotRecordedOnAccounts;
			InternationalChartOfAccounts_.AccountsPresentation = Enums.PresentationOfFinancialAccountingAccounts.AsCodeAndName;
			InternationalChartOfAccounts_.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithCorrespondence;
			InternationalChartOfAccounts_.TransactionsWithCorrespondence = True;
			InfobaseUpdate.WriteData(InternationalChartOfAccounts_);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
