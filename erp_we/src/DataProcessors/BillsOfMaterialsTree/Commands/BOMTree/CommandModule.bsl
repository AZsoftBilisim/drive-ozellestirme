
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.BillsOfMaterialsTree.Command.BOMTree");
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("BillOfMaterials", CommandParameter);
	OpeningParameters.Insert("GenerateOnOpen", True);
	OpeningParameters.Insert("ViewMode", "BillOfMaterials");
	
	OpenForm("DataProcessor.BillsOfMaterialsTree.Form", OpeningParameters,
		CommandExecuteParameters.Source, CommandParameter, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion