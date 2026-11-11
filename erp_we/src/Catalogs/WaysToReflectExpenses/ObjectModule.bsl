#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)

	If Not IsFolder Then
		ItemsAndDimensionsSelectionParameters = Catalogs.WaysToReflectExpenses.ItemsAndDimensionsSelectionParameters();
		IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;

	AttributesNotToCheck = New Array;

	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentAttributes_WaysToReflectExpenses(ThisObject);
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, AttributesNotToCheck);
	
	ItemsAndDimensionsSelectionParameters = Catalogs.WaysToReflectExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);

	If Not IsFolder Then
		ItemsAndDimensionsSelectionParameters = Catalogs.WaysToReflectExpenses.ItemsAndDimensionsSelectionParameters();
		IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;

EndProcedure

#EndRegion

#EndIf