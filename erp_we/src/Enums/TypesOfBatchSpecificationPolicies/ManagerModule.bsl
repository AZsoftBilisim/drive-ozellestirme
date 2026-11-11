#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	If GetFunctionalOption("UseWarehouseManagementSystem") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	ChoiceData = New ValueList;
	ChoiceData.Add(Enums.TypesOfBatchSpecificationPolicies.ReferenceBatchSpecification);
	
EndProcedure

#EndRegion