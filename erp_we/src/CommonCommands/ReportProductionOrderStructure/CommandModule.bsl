
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If DynamicStructure(CommandParameter) Then
		FormName = "Report.ProductionOrderStructureDynamic.Form.ReportForm";
		
		PerformanceMonitorClient.TimeMeasurement(
			"Report.ProductionOrderStructureDynamic.ReportForm.Opening");
	Else
		FormName = "Report.ProductionOrderStructure2_2.Form.OrderStructure";
	EndIf;
	
	OpenForm(
		FormName,
		New Structure("OrderDocument", CommandParameter), 
		CommandExecuteParameters.Source, 
		CommandParameter,
		CommandExecuteParameters.Window,
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DynamicStructure(OrderDocument)
	
	Return Common.ObjectAttributeValue(OrderDocument, "DynamicStructure");
	
EndFunction

#EndRegion