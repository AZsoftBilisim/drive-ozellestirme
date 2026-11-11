#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DCSettings = SettingsComposer.Settings;
	If ValueIsFilled(TMReportsServer.FilterValue("ReferenceOrder", DCSettings.Filter.Items)) Then
		DCSettings.DataParameters.SetParameterValue("ContextReport", True);
	Else
		DCSettings.DataParameters.SetParameterValue("ContextReport", False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//  Form        - ClientApplicationForm - Report form
//  VariantKey - String - The name of the predefined version of the report or the unique identifier of the user
//  Settings    - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//  Form                - ClientApplicationForm - Report form
//  Cancel                - Boolean -
//  StandardProcessing - Boolean -
//
// See also:
//  "Formaclient Applications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		Form.ReportSettings.OptionSelectionAllowed = False;
		
		ParametersForm = Form.ParametersForm;
		ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ParametersForm.Filter.Insert("ReferenceOrder", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf