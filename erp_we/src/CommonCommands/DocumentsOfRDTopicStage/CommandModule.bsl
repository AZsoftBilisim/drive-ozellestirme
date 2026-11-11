
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
		"CommonCommand.DocumentsOfRDTopicStage,, True");
	
	FormParameters = New Structure;
	FormParameters.Insert("TopicStageOfResearchAndDevelopment", CommandParameter);
	
	// In order to open several forms, you need to determine the uniqueness.
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm")
		And CommandExecuteParameters.Source.FormName = "Catalog.RDTopicsStages.Form.ItemForm" Then
		UniquenessOfForm = CommandExecuteParameters.Source;
	Else
		UniquenessOfForm = CommandParameter;
	EndIf; 
	
	FormName = "DataProcessor.JournalOfIADocuments2_4.Form";
	
	OpenForm(FormName, 
		FormParameters, 
		CommandExecuteParameters.Source, 
		UniquenessOfForm, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
