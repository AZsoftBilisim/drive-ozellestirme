
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(
		True, "CommonCommand.IntangibleAssetDocuments");
	
	FormParameters = New Structure;
	FormParameters.Insert("IntangibleAsset", CommandParameter);
	
	// In order to open several forms, you need to determine the uniqueness.
	If TypeOf(CommandExecuteParameters.Source) = Type("ClientApplicationForm")
		And CommandExecuteParameters.Source.FormName = "Catalog.IntangibleAssets.Form.ItemForm" Then
		UniquenessOfForm = CommandExecuteParameters.Source;
	Else
		UniquenessOfForm = CommandParameter;
	EndIf; 
	
	FormName = NonCurrentAssetsClientLocalization.FormNameDocumentsOnIntangibleAsset();
	If FormName = Undefined Then
		FormName = "DataProcessor.JournalOfIADocuments2_4.Form";
	EndIf; 
	
	OpenForm(FormName, 
		FormParameters, 
		CommandExecuteParameters.Source, 
		UniquenessOfForm, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure

#EndRegion
