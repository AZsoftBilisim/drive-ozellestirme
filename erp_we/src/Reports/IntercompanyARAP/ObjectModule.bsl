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

Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.ParametersForm;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("SettlementsData");
	UserSetting = SettingsComposer.UserSettings.Items.Find(
		DataParameter.UserSettingID);
		
	If UserSetting <> Undefined Then
		
		If UserSetting.Value = 2 // In the currency of the accounting department
			Or UserSetting.Value = 3 Then // In the currency of the regl. accounting
				#Region UpdatingSettlements
				SetPrivilegedMode(True);
				FilterFields = ARAPAllocationServerCall.DefaultSelectionFields();
				AuxProperties = SettingsComposer.UserSettings.AdditionalProperties;
				ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties);
				SetPrivilegedMode(False);
				#EndRegion
		EndIf;
		
	EndIf;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	#Region CheckingSettlements
	ARAPAllocationServerCall.DeduceRelevanceOfCalculations(ResultDocument, AuxProperties);
	#EndRegion
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf