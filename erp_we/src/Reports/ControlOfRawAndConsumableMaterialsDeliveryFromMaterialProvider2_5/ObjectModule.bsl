#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//  Form        - ClientApplicationForm - report form.
//  VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//  Settings    - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//  Form                - ClientApplicationForm - report form.
//  Cancel                - Boolean -
//  StandardProcessing - Boolean -
//
// See also:
//  "Formaclient Applications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ParametersForm = Form.ParametersForm;
		
		ParametersForm.PurposeUseKey = Parameters.CommandParameter;
		ParametersForm.Filter.Insert("PurchaseOrder", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf