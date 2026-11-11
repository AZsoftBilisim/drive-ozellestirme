#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	AgreementStatusParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ContractStatus");
	If AgreementStatusParameter <> Undefined Then
		If AgreementStatusParameter.Value = Undefined Then
			DataCompositionClientServer.SetParameter(SettingsComposer, "ContractStatus", Enums.CounterpartyContractStatuses.EmptyRef());
			
			UserSettingsModified = True;
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ARAPCurrency");
		CurrencyParameter.Value = Constants.DefaultBaseCurrency.Get();
		Template6 = DataCompositionSchema.Templates.Template6; // DataCompositionSchemaTemplateDescription
		CurrencyParameter = Template6.Parameters.Currency; // DataCompositionExpressionAreaParameter 
		CurrencyParameter.Expression = "Presentation(DataParameters.ARAPCurrency)";
		PaymentInCurrencyParameter = Template6.Parameters.ForeignCurrencyTransaction; // DataCompositionExpressionAreaParameter 
		PaymentInCurrencyParameter.Expression = "Presentation(DataParameters.ARAPCurrency)";
	EndIf;
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
