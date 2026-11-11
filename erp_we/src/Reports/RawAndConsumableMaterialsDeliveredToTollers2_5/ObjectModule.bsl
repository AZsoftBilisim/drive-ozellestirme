#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;

	SetRequiredSettings(UserSettingsModified);
	
	SetOfProducts_1 = DataCompositionSchema.DataSets.Goods; // DataCompositionSchemaDataSetUnion
	
	QueryText = SetOfProducts_1.Items.RawAndConsumableMaterialsDeliveredToTollersBalance.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	
	SetOfProducts_1.Items.RawAndConsumableMaterialsDeliveredToTollersBalance.Query = QueryText;

	QueryText = SetOfProducts_1.Items.GoodsTransferredToProcessorsTurnover.Query;
	
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeightWithoutDimension",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("Orders.Products.UnitOfMeasure",
																							"Orders.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextItemVolumeWithoutDimension",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("Orders.Products.UnitOfMeasure",
																							"Orders.Products"));
	
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	
	SetOfProducts_1.Items.GoodsTransferredToProcessorsTurnover.Query = QueryText;	
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(FieldHeaders(), CompositionTemplate);
	
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
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	
	FixedPeriodSetting = FixedParameterSetting("Period");
	If FixedPeriodSetting.Use = True Then
		
		UsesPeriodSetting = CustomParameterSetting("Period");
		UsesPeriodSetting.Use = True;
		
		UserPeriod = UsesPeriodSetting.Value; // StandardPeriod
		FixedPeriod = FixedPeriodSetting.Value; // StandardPeriod
		UserPeriod.StartDate = FixedPeriod.StartDate;
		UserPeriod.EndDate = FixedPeriod.EndDate;
		
		FixedPeriodSetting.Use = False;
		
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);

EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction


// Returns a fixed setting based on the passed name
// 
// Parameters:
// 	ParameterName - String - parameter name
// Returns:
// 	DataCompositionParameterValue, Undefined, DataCompositionSettingsParameterValue - parameter object
Function FixedParameterSetting(ParameterName)

	DataParameter = SettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	
	Return DataParameter;

EndFunction


// Returns a custom setting based on the passed name
// 
// Parameters:
// 	ParameterName - String - LongDesc
// Returns:
// 	DataCompositionParameterValue, Undefined, DataCompositionSettingsParameterValue - parameter object
Function CustomParameterSetting(ParameterName)

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

Function FieldHeaders()
	
	Return DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf