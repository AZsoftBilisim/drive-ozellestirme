
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	OpenForm(
		"Catalog.ItemKinds.Form.ListFormForPricingSettings",
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window,
		,
		,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure