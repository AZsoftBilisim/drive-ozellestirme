#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ChoiceData = New ValueList;
	
	If Parameters.Property("AttachmentType") And Parameters.AttachmentType = Enums.PeripheralsTypes.SharedAccess Then
		ChoiceData.LoadValues(EquipmentManager.AvailableTypesOfPublicEquipment());
	Else
		ChoiceData.LoadValues(EquipmentManager.AvailableTypesOfEquipment());
	EndIf;
	StandardProcessing = False;
	
EndProcedure

#EndIf

#EndRegion