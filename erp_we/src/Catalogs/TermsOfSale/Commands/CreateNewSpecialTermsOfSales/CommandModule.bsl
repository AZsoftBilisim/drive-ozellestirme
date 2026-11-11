&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm(
		"Catalog.TermsOfSale.Form.ItemForm",
		New Structure("Basis",CommandParameter),
		,
		,);

EndProcedure
