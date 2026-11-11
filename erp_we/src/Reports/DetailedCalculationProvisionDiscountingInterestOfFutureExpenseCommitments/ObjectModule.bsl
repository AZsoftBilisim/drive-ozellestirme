
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ReserveAccountingObjectParameter = ReportSettings.DataParameters.Items.Find("ProvisionObject");
	
	ProvisionObject = ReserveAccountingObjectParameter.Value;
	If Not ValueIsFilled(ReserveAccountingObjectParameter.Value) Then
		ProvisionObject = PredefinedValue("Catalog.AccountingObjectsOfFutureExpenseCommitments.EmptyRef");
	EndIf;
	
	ESDDetails = Common.ObjectAttributesValues(ProvisionObject, "Organization, ReserveKind");
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Organization"));
	If Parameter <> Undefined Then
		Parameter.Value = ESDDetails.Organization;
		Parameter.Use = True;
	EndIf;
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReserveKind"));
	If Parameter <> Undefined Then
		Parameter.Value = ESDDetails.ReserveKind;
		Parameter.Use = True;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure - see the return value of the Clientserver report.Get a setup report for silence().
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("ProvisionObject") And Not ThisForm.ParametersForm.Filter.Property("ProvisionObject") Then
		ThisForm.ParametersForm.Filter.Insert("ProvisionObject", Parameters.ProvisionObject);
	EndIf;
	
	If Parameters.Property("Period") And Not ThisForm.ParametersForm.Filter.Property("Period") Then
		If Parameters.Property("Recorder") And ValueIsFilled(Parameters.Recorder) 
			And Not ValueIsFilled(Parameters.Period) Then
			ReportPeriod = Common.ObjectAttributeValue(Parameters.Recorder, "Date");	
			ThisForm.ParametersForm.Filter.Insert("Period", ReportPeriod);
		Else
			ThisForm.ParametersForm.Filter.Insert("Period", Parameters.Period);			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
