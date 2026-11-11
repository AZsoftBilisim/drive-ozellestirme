#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "Components";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "Components";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	NotCheckedAttributeArray.Add("Components.CancellationReason");
	NotCheckedAttributeArray.Add("Components.DateOfShipment");
	
	If NumberOfSets Then
		CheckParameters = DataProcessors.EditSet.SetValidationParameters(ThisObject);
		
		If ValueIsFilled(CheckParameters.ProductsOfMainComponent) Then
			AccountingForTraceableGoodsLocalization.CheckIfKitIsCorrect(ThisObject, Cancel, CheckParameters);
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndIf