#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Owner) Then
    	NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	If Not LimitByWeight Then
    	NotCheckedAttributeArray.Add("LimitationByWeight");
	EndIf;
	
	If Not LimitByVolume Then
    	NotCheckedAttributeArray.Add("LimitationByVolume");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#EndIf