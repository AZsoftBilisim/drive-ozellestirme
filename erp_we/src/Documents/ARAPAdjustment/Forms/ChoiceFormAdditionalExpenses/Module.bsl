
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	VT = Documents.ARAPAdjustment.AdditionalCostsForReturnsToSupplier(Parameters.Organization, Parameters.Counterparty);
	AddExpensesForGoods.Load(VT);
	
EndProcedure

#EndRegion

#Region EventHandlersAndCosts

&AtClient
Procedure AddExpensesForGoodsSelectionOnChange(Item)

	SelectedCurrency = Items.AddExpensesForGoods.CurrentData.Currency;
	For Each Expense In AddExpensesForGoods Do
		If Expense.Selection And Expense.Currency <> SelectedCurrency Then
			Items.AddExpensesForGoods.CurrentData.Selection = False;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure MoveDocuments(Command)
	
	Result = New Array;
	For Each Expense In AddExpensesForGoods Do
		If Expense.Selection Then
			NewRow = New Structure("DocumentReturnPolicy,Claim,AdditExpenseAmount");
			FillPropertyValues(NewRow, Expense);
			Result.Add(NewRow);
		EndIf;
	EndDo;
	Close(Result);
	
EndProcedure

#EndRegion
