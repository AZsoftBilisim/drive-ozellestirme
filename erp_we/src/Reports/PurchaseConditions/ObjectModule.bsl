#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsOptionsOverridable.CustomizeReportsOptions.Settings.
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
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
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "SupplierPurchaseConditions" Then
			ThisForm.ParametersForm.Filter.Insert("Partner", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);	
	
	QueryText = DataCompositionSchema.DataSets.SupplierPrices.Query;
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor1",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package",
																							"PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor2",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("MaximumPricesOfCrossSectionProductRange.Package",
																							"MaximumPricesOfCrossSectionProductRange.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor3",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ItemsPrices.Package",
																							"ItemsPrices.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("ItemsPrices.Package",
																							"ItemsPrices.Products"));
	DataCompositionSchema.DataSets.SupplierPrices.Query = QueryText;	
	
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");	
	If CurrencyParameter <> Undefined And Not CurrencyParameter.Use Then
		CurrencyParameter.Use = True;
	EndIf;

	ConfiguringReportGrouping = DataCompositionClientServer.GetParameter(SettingsComposer, "Group");
	ListOfDimensions = DataCompositionClientServer.GetGroupings(SettingsComposer);
	For Each Group In ListOfDimensions  Do
		If Group.Value.Name = "VerticalGrouping" Then
			Group.Value.Use = Not Boolean(ConfiguringReportGrouping.Value);
		ElsIf Group.Value.Name = "HorizontalGrouping" Then
			Group.Value.Use = Boolean(ConfiguringReportGrouping.Value);
		EndIf;
	EndDo;
	
	ParameterCountryOfVATRates = DataCompositionClientServer.GetParameter(SettingsComposer, "CountryOfVATRates");
	If ParameterCountryOfVATRates <> Undefined Then
		If Not ValueIsFilled(ParameterCountryOfVATRates.Value) Then
			ParameterCountryOfVATRates.Value = SettingsValueClientServerCached.MainCountry();
		EndIf;
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	PriceManagementSystem.SetVSKDPricingOption(SettingsComposer);
	
EndProcedure

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("Group");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

#EndRegion

#EndIf
