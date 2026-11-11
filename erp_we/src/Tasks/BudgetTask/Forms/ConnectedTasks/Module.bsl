
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Task = Parameters.CommandParameter;
	GenerateOnServer();
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	Var ChosenAction, ChosenActionParameter;
	
	StandardProcessing = False;
	
	DetailProcessing = New DataCompositionDetailsProcess(
		ExplanationAddress, New DataCompositionAvailableSettingsSource(SchemaURL));
	
	AvailableAction = New Array;
	AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
	
	AddlParameters = New Structure("ChosenActionParameter", ChosenActionParameter);
	CallbackDescription = New CallbackDescription("ResultDetailProcessingCompletion",
	                                              ThisObject,
	                                              AddlParameters);
	DetailProcessing.ShowActionChoice(CallbackDescription, Details, AvailableAction,, True,);
	
EndProcedure

&AtClient
Procedure ResultDetailProcessingCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
		
	ShowValue(, ChosenActionParameter);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure GenerateOnServer()
	
	Result.Clear();
	
	SetPrivilegedMode(True);
	
	LineUp = Reports.PerformanceOfBudgetProcessTasks.GetTemplate("MainDataCompositionSchema");
	
	Variant = LineUp.SettingVariants.Find("ConnectedTasks");
	
	ConfigurationManager = New DataCompositionSettingsComposer;
	ConfigurationManager.Initialize(New DataCompositionAvailableSettingsSource(LineUp));
	ConfigurationManager.LoadSettings(Variant.Settings);
	
	Filter = ConfigurationManager.Settings.Filter;
	NewFilter = Filter.Items.Add(Type("DataCompositionFilterItem"));
	NewFilter.LeftValue = New DataCompositionField("Task");
	NewFilter.ComparisonType = DataCompositionComparisonType.InHierarchy;
	NewFilter.Use = True;
	NewFilter.RightValue = Task;
	
	FilterElement = ConfigurationManager.Settings.DataParameters.Items.Find("DisplayOnlySubordinateTasks");
	FilterElement.Value = True;
	FilterElement.Use = True;
	
	DetailsData = New DataCompositionDetailsData;
	
	DataCompositionSettings = ConfigurationManager.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(LineUp, DataCompositionSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template, , DetailsData);
	CompositionProcessor.Reset();
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(Result);
	OutputProcessor.Output(CompositionProcessor);
	
	SetPrivilegedMode(False);
	
	ExplanationAddress = PutToTempStorage(DetailsData, ThisForm.UUID);
	SchemaURL = PutToTempStorage(LineUp, ThisForm.UUID);
	
EndProcedure

#EndRegion
