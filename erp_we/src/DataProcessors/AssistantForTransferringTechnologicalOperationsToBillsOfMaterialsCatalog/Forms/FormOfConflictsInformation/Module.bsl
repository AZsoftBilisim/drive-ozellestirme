
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	AddressConflictData = Parameters.AddressConflictData;
	
	InitializeComposer();
	
	GenerateOnServer();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	StandardProcessing = False;
	
	DetailProcessing = New DataCompositionDetailsProcess(AddressDecryptionData,
		New DataCompositionAvailableSettingsSource(AddressLayoutDiagram));
	
	AvailableAction = New Array;
	AvailableAction.Add(DataCompositionDetailsProcessingAction.OpenValue);
	
	CallbackDescription = New CallbackDescription("ResultDetailProcessingCompletion",
		ThisObject,
		New Structure("ChosenActionParameter"));
		
	DetailProcessing.ShowActionChoice(CallbackDescription,
		Details,
		AvailableAction,,
		True,);
	
EndProcedure

&AtClient
Procedure ResultDetailProcessingCompletion(ChosenAction, ChosenActionParameter, AdditionalParameters) Export
	
	If ValueIsFilled(ChosenActionParameter) Then
	
		ShowValue(, ChosenActionParameter);
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	
	GenerateOnServer();
	
EndProcedure

&AtServer
Procedure GenerateOnServer()
	
	Result.Clear();
	
	DetailsData = New DataCompositionDetailsData();
		
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
		GetFromTempStorage(AddressLayoutDiagram),
		SettingsComposer.GetSettings(),
		DetailsData);
		
	DataCompositionProcessor = New DataCompositionProcessor();
	DataCompositionProcessor.Initialize(
		DataCompositionTemplate,
		New Structure("DataSet", GetFromTempStorage(AddressConflictData)),
		DetailsData);
		
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor();
	OutputProcessor.SetDocument(Result);
	OutputProcessor.Output(DataCompositionProcessor);
	
	AddressDecryptionData = PutToTempStorage(DetailsData, UUID);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeComposer()
	
	CompositionSchema = DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.GetTemplate("ConflictInformation");
	AddressLayoutDiagram = PutToTempStorage(CompositionSchema, UUID);
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressLayoutDiagram));
	
	SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

#EndRegion