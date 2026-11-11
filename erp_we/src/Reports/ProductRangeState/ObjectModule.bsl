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
//   ThisForm - ClientApplicationForm - Report form:
//   * Parameters - Structure - Shape parameter:
//     ** CommandDetails - Structure - parameters description of the Command:
//       *** AdditionalParameters - Structure - additional parameters:
//         **** CommandName - String -
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		If Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
			
			If Parameters.CommandDetails.AdditionalParameters.CommandName = "ProductRangeState" Then
				ThisForm.ParametersForm.Filter.Insert("OnDate", CurrentSessionDate());
				ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
			EndIf;
			
		Else
			ThisForm.ParametersForm.Filter.Insert("OnDate", CurrentSessionDate());
			ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf