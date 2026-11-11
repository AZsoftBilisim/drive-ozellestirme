#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Return;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
// Form - ClientApplicationForm - report form.
// VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
// Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export

	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;

EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// ThisForm - ClientApplicationForm - Report form:
// 	 * Parameters - Structure - may contain properties:
//				** CommandParameter -
//				** CommandDetails - Structure -
// Cancel - Boolean - passed from the handler parameters "as is".
// StandardProcessing - Boolean - Passed from the handler parameters "as is".
//
// See also:
// "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export

	Parameters = ThisForm.Parameters;

	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then

		ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;
		Parameters.PurposeUseKey = Parameters.CommandDetails.AdditionalParameters.CommandName;

	EndIf;

EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// Form - ClientApplicationForm - report form.
// NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form extension for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export

	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer; // DataCompositionSettingsComposer -

	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#EndIf
