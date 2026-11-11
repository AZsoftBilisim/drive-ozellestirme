
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormName = "Document.CustomerInvoice.Form.DocumentForm";
	
	BasisParameters = New Structure;
	
	BasisParameters.Insert("DocumentBasis",   CommandParameter);
	BasisParameters.Insert("FillInByLeftovers", True);
	BasisParameters.Insert("SaleRegistrationOption",
		PredefinedValue("Enum.SalesRegistrationOptions.DeedOfTransfer"));
	
	OpenForm(FormName, New Structure("Basis", BasisParameters));
EndProcedure
