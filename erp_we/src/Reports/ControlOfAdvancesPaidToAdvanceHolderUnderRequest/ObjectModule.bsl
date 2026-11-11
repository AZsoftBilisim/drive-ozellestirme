#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		Form.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
		Form.ReportSettings.OptionSelectionAllowed = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Document");
	
	If ValueIsFilled(DocumentParameter.Value) Then
		
		If TypeOf(DocumentParameter.Value) = Type("DocumentRef.PaymentRequest") Then
			
			DocumentAttributes = Common.ObjectAttributesValues(
				DocumentParameter.Value, "Organization, AdvanceHolder");
			
			DataCompositionClientServer.AddFilter(SettingsComposer,"Organization",DocumentAttributes["Organization"],DataCompositionComparisonType.Equal);
			DataCompositionClientServer.AddFilter(SettingsComposer,"AdvanceHolder",DocumentAttributes["AdvanceHolder"],DataCompositionComparisonType.Equal);
				
		ElsIf TypeOf(DocumentParameter.Value) = Type("DocumentRef.ApplicationForBusinessTrip") Then
			
			DocumentAttributes = Common.ObjectAttributesValues(
				DocumentParameter.Value, "Organization, Employee, PersonsList");
			
			DataCompositionClientServer.AddFilter(SettingsComposer,"Organization",DocumentAttributes["Organization"],DataCompositionComparisonType.Equal);
			
			If DocumentAttributes["PersonsList"] Then
				Query = New Query("SELECT Employee FROM Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder WHERE Ref = &Ref");
				Query.SetParameter("Ref", DocumentParameter.Value);
				ListOfEmployees = New ValueList;
				ListOfEmployees.LoadValues(Query.Execute().Unload().UnloadColumn("Employee"));
				DataCompositionClientServer.AddFilter(SettingsComposer,"AdvanceHolder",ListOfEmployees,DataCompositionComparisonType.InList);
			Else
				DataCompositionClientServer.AddFilter(SettingsComposer,"AdvanceHolder",DocumentAttributes["Employee"],DataCompositionComparisonType.Equal);
			EndIf;
		EndIf;
	EndIf;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf