// @strict-types

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.WorkplaceOfDeliveryOfficer.Form.Form",,,, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion

