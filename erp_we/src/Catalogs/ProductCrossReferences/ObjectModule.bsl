#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder 
		And Not DeletionMark
		And Not Invalid Then
		Keys = ProductCrossReferencesMappingInternal.HashesOfNaturalKeysOfNomenclature(
			Description,
			SKU,
			ProductsAndServicesCode,
			Barcode);
			
		FillPropertyValues(ThisObject, Keys);
	EndIf;

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not IsFolder And Not UseCharacteristics Then
		
		NotCheckedAttributeArray.Add("Characteristic");
	
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf