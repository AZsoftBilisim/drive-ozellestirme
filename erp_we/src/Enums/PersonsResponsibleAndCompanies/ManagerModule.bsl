
#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceData = New ValueList;
	
	// Overall
	ChoiceData.Add(Enums.PersonsResponsibleAndCompanies.Director);
	ChoiceData.Add(Enums.PersonsResponsibleAndCompanies.ChiefAccountant);
	ChoiceData.Add(Enums.PersonsResponsibleAndCompanies.Cashier);
	
	
EndProcedure

#EndRegion
