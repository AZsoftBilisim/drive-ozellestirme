#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	ChoiceData.Add(Enums.OptionsOfMaterialAssignmentInProduction.LineOfBusiness);
	ChoiceData.Add(Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts);
	ChoiceData.Add(Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder);
	ChoiceData.Add(Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage);
	
EndProcedure

#EndRegion

#EndIf