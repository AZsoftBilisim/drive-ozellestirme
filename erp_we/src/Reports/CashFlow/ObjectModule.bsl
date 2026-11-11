#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	If DataCompositionClientServer.GetParameter(SettingsComposer, "DisplayPlannedRegisteredRecords").Value Then
		SetPrivilegedMode(True);
		InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForReceiptsFromBankForAcquiring();
		SetPrivilegedMode(False);
	EndIf;
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	// Generate a report
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(MatchingFieldHeaders(), CompositionTemplate);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, DataCompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, Var_SettingsComposer, True, "TimeIntervals.");
	
EndProcedure

Function MatchingFieldHeaders()
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	ReportData = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportData").Value;
	
	MatchingFieldHeaders = New Map;
	If UseMultipleCurrencies Then
		If ReportData = 1 Or ReportData = 3 Then
			MatchingFieldHeaders.Insert("1", "");
		ElsIf ReportData = 2 Then
			CurrencyParameter = Constants.ManagementAccountingCurrency.Get();
			MatchingFieldHeaders.Insert("1", "(" + CurrencyParameter + ")");
		EndIf;
	Else
		MatchingFieldHeaders.Insert("1", "");
	EndIf;
	
	Return MatchingFieldHeaders;
	
EndFunction

#EndRegion

#EndIf