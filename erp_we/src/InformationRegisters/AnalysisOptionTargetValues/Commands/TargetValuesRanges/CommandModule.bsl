#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	FiltersStructure = New Structure("AnalysisOption", CommandParameter);
	FormParameters = New Structure("Filter", FiltersStructure);
	OpenForm("InformationRegister.AnalysisOptionTargetValues.ListForm", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
EndProcedure

#EndRegion 