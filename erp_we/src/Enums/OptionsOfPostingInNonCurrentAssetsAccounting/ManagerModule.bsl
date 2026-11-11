#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If Not Parameters.Property("TheSelectionListIsSpecified") Then
		StandardProcessing = False;
		ChoiceData = New ValueList;
		ChoiceData.Add(Enums.OptionsOfPostingInNonCurrentAssetsAccounting.ManagementAndLocalAccounting);
		ChoiceData.Add(Enums.OptionsOfPostingInNonCurrentAssetsAccounting.InManagementAccounting);
		ChoiceData.Add(Enums.OptionsOfPostingInNonCurrentAssetsAccounting.InLocalAccounting);
	EndIf; 
	
EndProcedure

#EndRegion

#EndIf
