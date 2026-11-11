// @strict-types

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("DeliveryKind", PredefinedValue("Enum.DeliveryKinds.ToWarehouse"));
	OpenForm(
		"DataProcessor.WorkplaceOfDeliveryOfficer.Form.Form",
		FormParameters,
		,
		,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

