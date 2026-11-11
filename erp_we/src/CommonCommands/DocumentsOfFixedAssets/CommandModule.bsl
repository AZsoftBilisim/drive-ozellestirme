
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "CommonCommand.DocumentsOfFixedAssets");
	
	FormParameters = New Structure;
	FormParameters.Insert("Asset", CommandParameter);
	
	// In order to open several forms, you need to determine the uniqueness.
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm")
		And CommandExecuteParameters.Source.FormName = "Catalog.Assets.Form.ItemForm" Then
		UniquenessOfForm = CommandExecuteParameters.Source;
	Else
		UniquenessOfForm = CommandParameter;
	EndIf; 
	
	FormName = NonCurrentAssetsClientLocalization.NameOfFormDocumentsForMainFacility();
	If FormName = Undefined Then
		FormName = "DataProcessor.FADocumentLog2_4.Form";
	EndIf; 
	
	OpenForm(FormName, 
		FormParameters, 
		CommandExecuteParameters.Source, 
		UniquenessOfForm,
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
