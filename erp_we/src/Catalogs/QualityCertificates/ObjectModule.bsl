#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;	
	
	NotCheckedAttributeArray = New Array;
	
	If Permanent Then
		NotCheckedAttributeArray.Add("ValidTo");
	EndIf;
	
	NotCheckedAttributeArray.Add("Description");

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ProductsLocalization.WhenCopying_NomenclatureCertificates(ThisObject, CopiedObject);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder
		And Not Permanent
		And ValidTo < StartDateOfValidityPeriod Then
		ValidTo = StartDateOfValidityPeriod;
	EndIf;

EndProcedure

#EndRegion

#EndIf