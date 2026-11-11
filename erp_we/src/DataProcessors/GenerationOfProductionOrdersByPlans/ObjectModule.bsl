#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If Not ProductDataManagement.DescriptionOfManufacturingProcessTypeIsAvailable() Then
		
		IndexOf = CheckedAttributes.Find("ProductionProcessType");
		If IndexOf <> Undefined Then
			CheckedAttributes.Delete(IndexOf);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf