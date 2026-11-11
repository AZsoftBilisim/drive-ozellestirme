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
	Settings.SelectAndEditOptionsWithoutSavingAllowed = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.AdditionalParameters.Property("CommandName") Then 
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "SalesTermsAndConditions" Then
			ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "TermsOfSalesByPartner" Then
			ThisForm.ParametersForm.Filter.Insert("Partner", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	// If the report is not opened from a document, you need to show only standard agreements.
	
	ParameterFilledIn = False;
	
	AgreementParameter = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Document");
	ParameterFilledIn   = ParameterFilledIn(AgreementParameter);
	
	AgreementParameter = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Document");
	ParameterFilledIn   = ParameterFilledIn(AgreementParameter) Or ParameterFilledIn;
	
	PartnerParameter  = DataCompositionClientServer.GetParameter(SettingsComposer.FixedSettings, "Partner");
	ParameterFilledIn = ParameterFilledIn(PartnerParameter) Or ParameterFilledIn;
	
	PartnerParameter  = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Partner");
	ParameterFilledIn = ParameterFilledIn(PartnerParameter) Or ParameterFilledIn;
	
	If Not ParameterFilledIn Then
		ParameterTypicalOnly = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "OnlyStandard");
		If ParameterTypicalOnly <> Undefined Then
			ParameterTypicalOnly.Value      = True;
			ParameterTypicalOnly.Use = True;
		EndIf;
	EndIf;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

#EndRegion

#Region Private

// Checks whether the layout parameter is full
//
// Parameters:
//	Parameter - DataCompositionSettingsParameterValue - parameter to check if it is full.
//
// Returns:
//	Boolean - True if the parameter is filled in, False otherwise.
//
Function ParameterFilledIn(Parameter)
	
	If Parameter <> Undefined Then
		
		ParameterValue = Parameter.Value;
		ParameterType      = TypeOf(ParameterValue);
		ParameterFilledIn  = ValueIsFilled(ParameterValue);
		
		If ParameterType = Type("ValueList") Then
			If ParameterValue.Count() = 0 Then
				ParameterFilledIn = False;
			Else
				ParameterFilledIn = True;
			EndIf;
		EndIf;
		
	Else
		
		ParameterFilledIn = False;
		
	EndIf;
	
	Return ParameterFilledIn;

EndFunction

#EndRegion

#EndIf