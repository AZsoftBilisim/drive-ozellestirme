&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("Standard_", True);
	FormParameters.Insert("FillingValues", New Structure("Standard_", True));
	
	OpenForm(
		"Catalog.TermsOfSale.ObjectForm",
		FormParameters,
		,
		,);

EndProcedure
