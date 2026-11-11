#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	Filter = New Structure("AnalysisOptionFilter", CommandParameter);
	FormParameters = New Structure("PurposeUseKey, Filter, GenerateOnOpen", 
		"Variant analysis_ = " + CommandParameter,
		Filter,
		True);
		
	OpenForm("Report.PerformanceDashboard.Form.AnalysisOptionPrintForm", 
		FormParameters, 
		CommandExecuteParameters, 
		New UUID());
EndProcedure

#EndRegion 