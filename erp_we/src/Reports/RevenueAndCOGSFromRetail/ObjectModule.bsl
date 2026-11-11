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
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadVariantAtServer = True;
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
	
	// Additional command
	FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer
	Parameters = ThisForm.ReportSettings;
	
	If Parameters.Property("AdvancedFilter") Then
		AdvancedFilter = FormSettingsComposer.FixedSettings.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		AdvancedFilter.LeftValue = New DataCompositionField("Partner");
		If TypeOf(Parameters.AdvancedFilter) = Type("Array") Then
			ThisIsArray = True;
			If Parameters.AdvancedFilter.Count() > 0 Then
				TheFirstControl = Parameters.AdvancedFilter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			ThisIsArray = False;
			TheFirstControl = Parameters.AdvancedFilter;
		EndIf;
		If TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Then
			If ThisIsArray Then
				ThereAreSubordinatePartners = False;
				For Each CommandParameterElement In Parameters.AdvancedFilter Do
					If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
						ThereAreSubordinatePartners = True;
						Break;
					EndIf;
				EndDo;
			Else
				ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(Parameters.AdvancedFilter);
			EndIf;
			If ThereAreSubordinatePartners And ThisIsArray Then
				AdvancedFilter.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			ElsIf ThereAreSubordinatePartners Then
				AdvancedFilter.ComparisonType = DataCompositionComparisonType.InHierarchy;
			ElsIf ThisIsArray Then
				AdvancedFilter.ComparisonType = DataCompositionComparisonType.InList;
			Else
				AdvancedFilter.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
			AdvancedFilter.RightValue = Parameters.AdvancedFilter;
		ElsIf TypeOf(Parameters.AdvancedFilter) = Type("CatalogRef.PartnersSegments") Then
			AdvancedFilter.ComparisonType = DataCompositionComparisonType.InList;
			AdvancedFilter.RightValue = SegmentsServer.ItemArray(
				TheFirstControl);
		EndIf;
		AdvancedFilter.Use = True;
	EndIf;
	

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//  ThisForm - ClientApplicationForm - report form.
//  NewDCSettings - DataCompositionSettings - settings to upload to the settings Composer.
//  
// For more information, see the syntax Assistant "Extension of a managed form for a report.Prizagruzkevariantanaserver" in the syntax assistant.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	Parameters = ThisForm.ReportSettings;
	FormSettingsComposer = Report.SettingsComposer;
	
	If Parameters.Property("Details") And Parameters.Details <> Undefined
		And Parameters.Details.UsedSettings.AdditionalProperties.Property("FixedSettings") Then
		FormSettingsComposer.LoadSettings(Parameters.Details.UsedSettings);
	EndIf;
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.RevenueAndCOGS.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("Table.Products.UnitOfMeasure", "Table.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("Table.Products.UnitOfMeasure", "Table.Products"));

	DataCompositionSchema.DataSets.RevenueAndCOGS.Query = QueryText;

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Báo cáo không được tạo. Bao gồm ít nhất một nhóm trong các thành phần thiết kế và nhóm.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку в ""Элементы оформления и группировки"".';
					|en = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".'; fa = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".';
					|it = 'Report non generato. Includere almeno un raggruppamento in ""Elementi di progettazione e raggruppamento"".';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedno grupowanie ""Elementy sporządzenia i grupowania"".';
					|tr = 'Rapor oluşturulmamıştır. ""Düzenleme öğeleri ve gruplandırmalar"" bölümüne en az bir gruplandırma ekleyin.'") ;
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	FieldsToCheck = New Array;
	FieldsToCheck.Add("Vendor");
	CostCalculationAppliedAlgorithms.AddWarningAboutReportGenerationFeatures(ResultDocument, SettingsComposer, FieldsToCheck);
	CostCalculationAppliedAlgorithms.AddWarningAboutPreClosingMonth(ResultDocument, SettingsComposer);
	
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, SettingsComposer, True);
	
	ShowSalesParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ShowSales_");
	If ShowSalesParameter <> Undefined 
		And ShowSalesParameter.Value = Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ShowSales_", 1);
				
		UserSettingsModified = True;
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineSalesByOrders", NStr("vi = 'Bán hàng theo đơn đặt hàng';
																						|ru = 'Продажи по заказам';
																						|en = 'Sales against orders'; fa = 'Sales against orders';
																						|it = 'Vendite su ordini';
																						|pl = 'Sprzedaż wg zamówień';
																						|tr = 'Siparişe ilişkin satışlar'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineSalesWithoutOrders", NStr("vi = 'Bán hàng không có đơn hàng';
																								|ru = 'Продажи без заказов';
																								|en = 'Sales without orders'; fa = 'Sales without orders';
																								|it = 'Vendite senza ordini';
																								|pl = 'Sprzedaż bez zamówień';
																								|tr = 'Siparişsiz satışlar'"));
EndProcedure

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	CurrentVariantKey = "";
	If SettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey", CurrentVariantKey) Then
		If Not CurrentVariantKey = "DynamicsOfRetailSales"
			And Not CurrentVariantKey = "DynamicsOfRetailSalesBusinessRegions" Then
			AuxiliaryParameters.Add("Periodicity");
		EndIf;
	EndIf;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	AuxiliaryParameters.Add("MaxSeriesCount");
	AuxiliaryParameters.Add("SelectionOfChartSeries");
	AuxiliaryParameters.Add("FollowedDimensions");
	AuxiliaryParameters.Add("GradientOfChartSeries");
	AuxiliaryParameters.Add("DisplayChartPointMarkers");
	
	Return AuxiliaryParameters;

EndFunction

Function ParameterizableFieldHeaders()
	
	FieldHeaders = New Map;
	
	UseMultipleCurrencies = GetFunctionalOption("UseMultipleCurrencies");
	ReportDataParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ReportData");
	ReportData = ReportDataParameter.Value;
	
	If UseMultipleCurrencies Then
		
		ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
		
		If ReportData = 1 
			Or ReportData = 2
			Or ReportData = 3 Then
			FieldHeaders.Insert("1", "(" + ManagementAccountingCurrency + ")");
		ElsIf ReportData = 4 Then
			FieldHeaders.Insert("1", "");
		EndIf;
		
	Else
		FieldHeaders.Insert("1", "");
	EndIf;
	
	UnitFieldHeaders_ = DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
	CommonClientServer.SupplementMap(FieldHeaders, UnitFieldHeaders_, False);
	
	Return FieldHeaders;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Organization");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Warehouse");
	EndIf;
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf