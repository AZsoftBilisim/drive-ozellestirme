#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	#If MobileClient Then
	OpenForm("Catalog.PerformanceDashboards.ListForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	#Else
	OpenForm("Report.PerformanceDashboard.Form.PerformanceDashboardForm", , CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	#EndIf
EndProcedure

#EndRegion 