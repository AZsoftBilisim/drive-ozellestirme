#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;

	SetRequiredSettings(UserSettingsModified);
	
	DataLayoutSchemeDataSetsSettlementsWithCommissionAgents = DataCompositionSchema.DataSets.CommissionAgentsARAPAccounting; // DataCompositionSchemaDataSetUnion
	
	QueryText = DataLayoutSchemeDataSetsSettlementsWithCommissionAgents.Items.GoodsTransferredToCommissionAgent.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DimensionOfProductItem.Products.UnitOfMeasure",
																							"DimensionOfProductItem.Products"));
	DataLayoutSchemeDataSetsSettlementsWithCommissionAgents.Items.GoodsTransferredToCommissionAgent.Query = QueryText;	

	QueryText = DataLayoutSchemeDataSetsSettlementsWithCommissionAgents.Items.SalesOrders.Query;
	QueryText = StrReplace(QueryText,
								"&QueryTextItemWeight",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("SalesOrders.Products.UnitOfMeasure",
																							"SalesOrders.Products"));
	QueryText = StrReplace(QueryText,
								"&QueryTextTheVolumeOfTheItem",
								Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("SalesOrders.Products.UnitOfMeasure",
																							"SalesOrders.Products"));
	DataLayoutSchemeDataSetsSettlementsWithCommissionAgents.Items.SalesOrders.Query = QueryText;	
	
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
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	If ThisForm.Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("ConsignmentReportFromCustomer", ThisForm.Parameters.CommandParameter);
	EndIf;
	
	Parameters = ThisForm.ParametersForm;
	
	If Parameters.Property("Filter")
	   And Parameters.Filter.Property("ConsignmentReportFromCustomer") Then
		If TypeOf(Parameters.Filter.ConsignmentReportFromCustomer) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			Attributes = Documents.ConsignmentReportFromCustomer.DocumentAttributes(Parameters.Filter.ConsignmentReportFromCustomer);
			
		ElsIf TypeOf(Parameters.Filter.ConsignmentReportFromCustomer) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
			Attributes = Documents.WriteOffReportFromCommissionAgent.DocumentAttributes(Parameters.Filter.ConsignmentReportFromCustomer);
			
		Else
			Attributes = Undefined;
			
		EndIf;
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Partner) Then
				Parameters.Filter.Insert("Consignee", Attributes.Partner);
			EndIf;
			If ValueIsFilled(Attributes.Organization) Then
				Parameters.Filter.Insert("Organization", Attributes.Organization);
			EndIf;
			Period = New StandardPeriod;
			Period.Variant = StandardPeriodVariant.Custom;
			Period.StartDate = Attributes.BeginOfPeriod;
			Period.EndDate = Attributes.EndOfPeriod;
			Parameters.Filter.Insert("Period", Period);
		EndIf;
		Parameters.Filter.Delete("ConsignmentReportFromCustomer");
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
// Form - ClientApplicationForm - report form.
// NewDCSettings - DataCompositionSettings - Settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form extension for the report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(Form, NewDCSettings) Export
	
	If Form.ReportSettings.PredefinedOptions.FindByValue(Form.CurrentVariantKey) <> Undefined Then
		
		Form.ReportCurrentOptionDescription = 
			ConsignmentSalesServer.AddCommissionPostfix25(Form.CurrentVariantPresentation);
		
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
// Parameters:
//	Context							- Arbitrary								- parameters of the context in which the report is used.
//	SchemaKey							- String									- ID of the current configuration Builder schema.
//	VariantKey						- String									- name of the predefined or unique ID of the custom
//																						version of the report.
//										- Undefined 								- a call for a decryption option or without context.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//										
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	SchemaKey		= VariantKey;
	FieldHeaders	= ParameterizableFieldHeaders();
	
	DataCompositionServer.SetHeadersOfSelectedFields(NewDCSettings.Selection.Items, FieldHeaders);
	
	If TypeOf(NewDCUserSettings) <> Type("DataCompositionUserSettings") Then
		Return;
	EndIf;
	
	SettingID = NewDCSettings.Selection.UserSettingID;
	
	If ValueIsFilled(SettingID) Then
		FoundSettingElement = NewDCUserSettings.Items.Find(SettingID);
		
		If FoundSettingElement <> Undefined Then 
			DataCompositionServer.SetHeadersOfSelectedFields(FoundSettingElement.Items, FieldHeaders);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	
	FixedPeriodSetting = FixedParameterSetting("Period");
	If FixedPeriodSetting.Use = True Then
		
		UsesPeriodSetting = CustomParameterSetting("Period");
		UsesPeriodSetting.Use = True;
		UsesPeriodSettingValue = UsesPeriodSetting.Value; // StandardPeriod
		FixedPeriodSettingValue  = FixedPeriodSetting.Value;  // StandardPeriod
		UsesPeriodSettingValue.StartDate    = FixedPeriodSettingValue.StartDate;
		UsesPeriodSettingValue.EndDate = FixedPeriodSettingValue.EndDate;
		
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

Function FixedParameterSetting(ParameterName)

	DataParameter = SettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	
	Return DataParameter;

EndFunction

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

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseSalesOrders") Then
		ItemsNames = StrSplit("Ordered,OrderedWeight,OrderedAmount", ",");
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, ItemsNames);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf