#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Function GetNumberOfSettingsForArticle(ExpenseItem) Export
	Query = New Query();
	Query.Text = "
	|SELECT 
	|	COUNT(T.SettingsManAccounting) AS SettingsCount
	|FROM
	|	InformationRegister.SettingsOfItemizedExpensesAllocation AS T
	|WHERE
	|	T.ExpenseItem = &ExpenseItem";
	Query.SetParameter("ExpenseItem", ExpenseItem);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.SettingsCount;
	Else
		Return 0;
	EndIf;
EndFunction

#EndRegion

#EndIf
