#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If Not IsFolder Then
		Organization = Catalogs.Companies.DefaultCompany();
		ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(ReserveKind);
		IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	DiscountingOfEstimatedObligation = False;
	If ValueIsFilled(ReserveKind) Then
		DiscountingOfEstimatedObligation = Common.ObjectAttributeValue(ReserveKind, "ProvisionDiscounting");
	EndIf;
	
	If DiscountingOfEstimatedObligation Then
		CheckedAttributes.Add("EndOfPeriod");
	EndIf;
	
	AttributesNotToCheck = New Array;
	
	AttributesNotToCheck.Add("UseReserve.DimensionOfExpenses");
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	If Not IsFolder Then
		ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(ReserveKind);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(ReserveKind);
		IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf