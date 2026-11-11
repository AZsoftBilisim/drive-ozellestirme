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
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	ConfigureDefaultSelectionParameters(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	
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
				JobName = ARAPAllocationServerCall.NameOfCustomerSettlementBackgroundJob();
				ARAPAllocationServerCall.RestoreSelectionCalculations(SettingsComposer, FilterFields, AuxProperties, JobName);
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
	InformationRegisters.JobsForAllocatingCustomersARAP.DisplayRelevanceOfCalculation(ResultDocument, AuxProperties);
	#EndRegion       
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
EndProcedure

#EndRegion

#Region Private
	
Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
EndProcedure

Procedure ConfigureDefaultSelectionParameters(FormSettingsComposer, UserSettings = False)
	FixedPeriodSetting = FixedParameterSetting(FormSettingsComposer, "Period");
	
	If FixedPeriodSetting.Use = True Then
		
		UsesPeriodSetting = CustomParameterSetting(FormSettingsComposer, "Period");
		UsesPeriodSetting.Use = True;
		StandardPeriod = UsesPeriodSetting.Value; //StandardPeriod
		FixedStandardPeriod = FixedPeriodSetting.Value; //StandardPeriod
		StandardPeriod.StartDate = FixedStandardPeriod.StartDate;
		StandardPeriod.EndDate = FixedStandardPeriod.EndDate;
		
		FixedPeriodSetting.Use = False;
		
	EndIf;
EndProcedure

// LongDesc
// 
// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer
// 	ParameterName - String - LongDesc
// Returns:
// 	DataCompositionSettingsParameterValue - LongDesc
Function FixedParameterSetting(FormSettingsComposer, ParameterName)

	DataParameter = FormSettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	
	Return DataParameter;

EndFunction

// LongDesc
// 
// Parameters:
// 	FormSettingsComposer - DataCompositionSettingsComposer 
// 	ParameterName - String - LongDesc
// Returns:
// 	DataCompositionSettingsParameterValue - LongDesc
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