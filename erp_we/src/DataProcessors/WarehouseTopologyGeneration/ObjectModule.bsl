#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;

	If Not WarehousesServer.UseWarerooms(Warehouse) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	If Not WarehousesServer.UseBinLocationWarehousing(Warehouse, Premise) Then
		NotCheckedAttributeArray.Add("StorageBinType");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

EndProcedure

#EndRegion

#EndIf