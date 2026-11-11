//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export 
	
	If VariantKey = "StatementOnCustomerRebatesContext" Then
		
		Settings.GenerateImmediately = True;
		Settings.EditOptionsAllowed = False;
		
	EndIf;
	
	Settings.Events.OnCreateAtServer = True; 
	Settings.Events.OnDefineSettingsFormItemsProperties = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	If Parameters.Property("CommandParameter")
	   And TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ConditionsOfCustomerRebates") Then
		
		ConditionsOfCustomerRebates = Parameters.CommandParameter; // DocumentRef.ConditionsOfCustomerRebates
		
		Attributes = "Patch, CorrectedDocument";
		AttributesValues = Common.ObjectAttributesValues(ConditionsOfCustomerRebates, Attributes);
		
		If AttributesValues.Patch = True Then
			SourceDocument_ = AttributesValues.CorrectedDocument;
		Else
			SourceDocument_ = ConditionsOfCustomerRebates;
		EndIf;
		
		Form.ParametersForm.Filter = New Structure("TermDocument", SourceDocument_);
		Form.ReportSettings.OptionSelectionAllowed = False;
		
	EndIf;
	
EndProcedure

// Called after defining the properties of form elements associated with user settings.
// See ReportsServer.SettingsFormItemsProperties()
// Allows you to override properties for the purpose of personalization of the report.
//
// Parameters:
//  FormType - ReportFormType - see Syntax Assistant
//  ItemsProperties - See ReportsServer.SettingsFormItemsProperties
//  UserSettings - DataCompositionUserSettingsItemCollection - elements of current
//                              user settings that affect the creation of related form elements.
//
Procedure OnDefineSettingsFormItemsProperties(FormType, ItemsProperties, UserSettings) Export 
	
	If FormType <> ReportFormType.Main Then 
		Return;
	EndIf;
	
	DataCompositionField = New DataCompositionField("Partner");
	
	FieldTable = ItemsProperties.Fields;
	FieldTable.Columns.Add("ChoiceParameters", New TypeDescription("FixedArray"));
	
	For Each FieldProperties In FieldTable Do
		
		If TypeOf(FieldProperties.SettingDetails) = Type("DataCompositionFilterAvailableField")
		   And FieldProperties.SettingDetails.Field = DataCompositionField Then
			
			ChoiceParameters = New Array; // Array of ChoiceParameter
			Parameter = New ChoiceParameter("Filter.Client", True); 
			ChoiceParameters.Add(Parameter);
			
			FieldProperties.ChoiceParameters = New FixedArray(ChoiceParameters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert(
			"UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#EndIf