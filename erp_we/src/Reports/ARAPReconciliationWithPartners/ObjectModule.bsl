#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;
	UserSettingsModified = False;

	Period = Undefined;
	If SettingsComposer.Settings.Filter.Items.Count() > 0 Then
		DocumentsArray = SettingsComposer.Settings.Filter.Items[0].RightValue;
		Reconciliation=Undefined;
		If TypeOf(DocumentsArray) = Type("DocumentRef.ARAPReconciliation2_4") And ValueIsFilled(DocumentsArray) Then
			Reconciliation = DocumentsArray;
		ElsIf TypeOf(DocumentsArray) = Type("ValueList") And DocumentsArray.Count() = 1 Then
			Reconciliation = DocumentsArray[0].Value;
		EndIf;
		If ValueIsFilled(Reconciliation) Then
			TimeIntervals = Common.ObjectAttributesValues(Reconciliation, "BeginOfPeriod, EndOfPeriod");
			Period = New StandardPeriod();
			Period.StartDate = TimeIntervals.BeginOfPeriod;
			Period.EndDate = TimeIntervals.EndOfPeriod;
			
			DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "Period", Period);
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings, "Period", Period);
			UserSettingsModified = True;
		EndIf;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	
	ComposerSettings = SettingsComposer.GetSettings();
	LayoutParameter = ComposerSettings.DataParameters.Items.Find("ProhibitedPaymentTypes");
	If LayoutParameter <> Undefined Then
		LayoutParameter.Use = True;
		LayoutParameter.Value.LoadValues(Documents.ARAPReconciliation2_5_11.ProhibitedPaymentTypes());
	EndIf;
	
	DetailsData = New DataCompositionDetailsData;
	
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema, 
		ComposerSettings,
		DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);

	OutputProcessor.Output(CompositionProcessor, True);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
