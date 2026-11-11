
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ProductionOrder = CommandParameter;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ProductionOrder", ProductionOrder);
	OpeningParameters.Insert("ToHideOrder", True);
	
	OpenForm("Report.MonitorOrder.Form.ReportForm", OpeningParameters,
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure
