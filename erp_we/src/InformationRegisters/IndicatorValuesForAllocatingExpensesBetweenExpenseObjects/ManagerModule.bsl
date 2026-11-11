#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	If Parameters.Property("FilterToDecrypt") Then
		Parameters.Insert("Period", Parameters.FilterToDecrypt.Period);
		Parameters.Insert("Factor", Parameters.FilterToDecrypt.Factor);
		Parameters.Insert("OnlyValues", True);
		SelectedForm = "Catalog.CostAllocationRules.Form.ListFormManually";
		StandardProcessing = False;
	EndIf;

EndProcedure

#EndRegion

#EndIf