
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FilterParameters = New Structure("Products", CommandParameter);
	FormParameters = New Structure("Filter, GenerateOnOpen, ReportOptionsCommandsVisibility", 
		FilterParameters, 
		True,
		False);
		
	OpenForm(
		"Report.ProductRangeState.Form",
		FormParameters,
		,
		"Products = " + CommandParameter,
		CommandExecuteParameters.Window);
EndProcedure

#EndRegion
