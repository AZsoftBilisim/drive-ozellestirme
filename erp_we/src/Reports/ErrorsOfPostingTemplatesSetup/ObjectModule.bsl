#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// For the General "report Form" form of the "report Options" subsystem.
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean -passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	If Parameters.Property("CommandParameter") Then
		
		ThisForm.ParametersForm.Insert("PostingGenerationSetting", Parameters.CommandParameter);
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	

	Parameters = ThisForm.ParametersForm;
	If Parameters.Property("PostingGenerationSetting") Then
		
		FormSettingsComposer = ThisForm.Report.SettingsComposer;
		
		// Setting parameter values during a context call
		ConfigureParameters(FormSettingsComposer, Parameters);
		
		NewDCSettings = FormSettingsComposer.UserSettings;
		
	EndIf;
	

EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	SettingUpAccountingPolicy = ParameterSetting("PostingGenerationSetting");
	If Not ValueIsFilled(SettingUpAccountingPolicy.Value) Then
		MessageText = NStr("vi = 'Không có chính sách kế toán được lựa chọn.';
							|ru = 'Не выбрана учетная политика.';
							|en = 'Accounting policy is not selected.'; fa = 'Accounting policy is not selected.';
							|it = 'Non è stata selezionata una politica contabile.';
							|pl = 'Nie wybrano polityka ewidencyjna.';
							|tr = 'Muhasebe politikası seçilmedi'");
		CommonClientServer.MessageToUser(MessageText,,,, Cancel); 
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Function ParameterSetting(ParameterName)

	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = SettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	Return Undefined;

EndFunction

Procedure ConfigureParameters(FormSettingsComposer, Parameters)
	
	UsesSetting = CustomParameterSetting(FormSettingsComposer, "PostingGenerationSetting");
	If UsesSetting <> Undefined Then
		UsesSetting.Value = Parameters.PostingGenerationSetting;
		UsesSetting.Use = True;
	EndIf;
	
EndProcedure

// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer - 
// 	ParameterName - String - LongDesc
// Returns:
// 	Undefined - LongDesc
Function CustomParameterSetting(FormSettingsComposer, ParameterName)

	DataParameter = FormSettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = FormSettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	Return Undefined;

EndFunction

#EndRegion

#EndIf