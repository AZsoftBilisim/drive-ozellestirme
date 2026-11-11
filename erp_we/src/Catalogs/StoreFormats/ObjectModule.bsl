#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)

	If Not IsFolder Then
		SpecialPriceType = Catalogs.TypesOfPrices.EmptyRef();
	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
		
	NotCheckedAttributeArray = New Array;

	If Not IsFolder Then
		
		If Not GetFunctionalOption("UseSeveralPriceTypes") Then
			NotCheckedAttributeArray.Add("RetailPriceType");
		EndIf;
		
	EndIf;
	
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion
	
#EndIf
