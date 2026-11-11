#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the names of blocked details for the BSP details blocking mechanism.
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("Organization");
	Result.Add("Department");
	Result.Add("ExpensesOccur");
	Result.Add("CostAllocationOptionManag");
	Result.Add("CostAllocationOptionLocal");
	Result.Add("CostAllocationOptionTax");
	
	ExpenseItemsLocalization.AddBlockedItemDetails(Result);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers
Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If Not FormType = "ChoiceForm" Then
		Return;
	EndIf;
	If Not Parameters.Property("Filter") Then
		Parameters.Insert("Filter", New Structure);
	EndIf;
	If Parameters.Property("Organization") Then
		Parameters.Filter.Insert("Organization", Parameters.Organization);
	EndIf;
	If Parameters.Property("Department") Then
		Parameters.Filter.Insert("Department", Parameters.Department);
	EndIf;
	If Not Parameters.Filter.Property("NotUsed") Then
		Parameters.Filter.Insert("NotUsed", False);
	EndIf;
EndProcedure

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	If Not Parameters.Filter.Property("NotUsed") Then
		Parameters.Filter.Insert("NotUsed", False);
	EndIf;
EndProcedure

#EndRegion

