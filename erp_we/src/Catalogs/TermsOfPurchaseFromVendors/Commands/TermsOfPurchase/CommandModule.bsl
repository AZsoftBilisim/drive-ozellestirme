&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("Partner", CommandParameter));
	
	OpenForm("Catalog.TermsOfPurchaseFromVendors.ListForm",
	             FormParameters,
	             CommandExecuteParameters.Source,
	             CommandExecuteParameters.Uniqueness,
	             CommandExecuteParameters.Window);
	
EndProcedure