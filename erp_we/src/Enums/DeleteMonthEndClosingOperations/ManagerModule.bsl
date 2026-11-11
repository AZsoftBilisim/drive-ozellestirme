#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Property("ForTasksByEndOfMonth") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	// Only the enumeration values that are supported in the month closing mechanism are available for selection in the form of the register list of tasks for closing the month
	// .
	// see using the Close the Month Server function.Check the identity of the closing tasks of the month().
	ChoiceData = New ValueList;
	
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.RevaluationOfCashAndFinancialInstruments);
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		ChoiceData.Add(Catalogs.MonthEndClosingOperations.PostingToPartnersARAPAccountingAndARAPRevaluation);
	EndIf;
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.AllocationOfExpensesByLinesOfBusiness);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.AllocationOfIncomeByLinesOfBusiness);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.VATAllocation);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.AccualOfInventoryImpairmentProvision);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.GenerateLossAllowance);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.RDExpenseRecognition);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.ImpairmentFA);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.ClosingExpensesFromDisposalOfFixedAssets);
	ChoiceData.Add(Catalogs.MonthEndClosingOperations.UpdatingFARecordsBeforeCalculatingDepreciation);
	If GetFunctionalOption("TransferToRentalSubleaseBasedOnRussianGAAPFSBU25") Then
		ChoiceData.Add(Catalogs.MonthEndClosingOperations.AccrueProfitableRentalInterest);
		ChoiceData.Add(Catalogs.MonthEndClosingOperations.CalculateRentalInvestmentCost);
	EndIf;
	If GetFunctionalOption("AccountingForDiscountedAccountsPayableToVendors") Then
		ChoiceData.Add(Catalogs.MonthEndClosingOperations.CalculationOfDiscountInterestExpenses);
	EndIf;
	MonthEndTransactionsLocalization.AddDataForSelectingMonthClosingOperations(ChoiceData);
	
	ChoiceData.SortByValue();
	
EndProcedure

#EndRegion

#Region Private

// Returns unused month closing operations of operations for which there should be no entries in the Month Closing task register.
// 
// Returns:
// Array of CatalogRef.MonthEndClosingOperations - Unused Operations
Function UnusedOperations() Export
	
	Result = New Array;
	Result.Add(Enums.DeleteMonthEndClosingOperations.EmptyRef());
	Result.Add(Enums.DeleteMonthEndClosingOperations.DeleteCorrectionOfErrorsInCorrespondenceOfFinancialRegisters);
	Result.Add(Enums.DeleteMonthEndClosingOperations.NotUsedRegisterTransferOfMaterialsToProduction);
	Result.Add(Enums.DeleteMonthEndClosingOperations.DeleteCheckingCorrespondenceErrorsOfFinancialRegisters);
	
	Return Result; 
	
EndFunction


#EndRegion

#EndIf
