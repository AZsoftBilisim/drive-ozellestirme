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
	
	NewDCSettings = FormSettingsComposer.Settings;
	

EndProcedure

#EndRegion

#Region Public

// Sets the layout for the transmitted series
// 
// Parameters:
//	Series - ChartSeries - changeable chart series.
//
Procedure InstallExtendedSeriesDesign(Series) Export
	
	If StrFind(Series.Text, NStr("vi = 'vừa qua';
								|ru = 'прошлый';
								|en = 'previous'; fa = 'previous';
								|it = 'passato';
								|pl = 'previous';
								|tr = 'geçmiş'")) Then
		Series.Color = WebColors.LightSteelBlue;	
	ElsIf StrFind(Series.Text, NStr("vi = 'vừa qua';
									|ru = 'прошлый';
									|en = 'previous'; fa = 'previous';
									|it = 'passato';
									|pl = 'previous';
									|tr = 'geçmiş'")) Then
		Series.Color = WebColors.LightGray;
	ElsIf StrFind(Series.Text, NStr("vi = 'Doanh thu';
									|ru = 'Выручка';
									|en = 'Revenue'; fa = 'درآمد';
									|it = 'Ricavo';
									|pl = 'Utarg';
									|tr = 'Gelir'"))
		Or StrFind(Series.Text, NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'")) Then
		Series.Color = WebColors.SteelBlue;
	ElsIf StrFind(Series.Text, NStr("vi = 'Sụt giảm';
									|ru = 'Спад';
									|en = 'Slippage'; fa = 'افت';
									|it = 'Recessione';
									|pl = 'Slippage';
									|tr = 'Düşüş'")) > 0 Then
		Series.Color = WebColors.LightSalmon;
	ElsIf StrFind(Series.Text, NStr("vi = 'Tăng dưới trung bình';
									|ru = 'Прирост ниже среднего';
									|en = 'Growth is below-average'; fa = 'رشد کمتر از میانگین است';
									|it = 'Accrescimento sotto la media';
									|pl = 'Wzrost poniżej średniej';
									|tr = 'Ortalamanın altında artış'")) > 0 Then
		Series.Color = WebColors.LightGoldenRod;
	ElsIf StrFind(Series.Text, NStr("vi = 'Tăng';
									|ru = 'Прирост';
									|en = 'Growth'; fa = 'رشد';
									|it = 'Accrescimento';
									|pl = 'Growth';
									|tr = 'Artış'")) > 0 Then
		Series.Color = New Color(55,201,117);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Generate a report
	MainCircuitSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.Sales.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DimensionOfProductItem.Products.UnitOfMeasure", "DimensionOfProductItem.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DimensionOfProductItem.Products.UnitOfMeasure", "DimensionOfProductItem.Products"));

	DataCompositionSchema.DataSets.Sales.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, MainCircuitSettings, DetailsData);
	
	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Báo cáo không được tạo. Bao gồm ít nhất một nhóm trong các thành phần thiết kế và nhóm.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку в ""Элементы оформления и группировки"".';
					|en = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".'; fa = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".';
					|it = 'Report non generato. Includere almeno un raggruppamento in ""Elementi di progettazione e raggruppamento"".';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedno grupowanie ""Elementy sporządzenia i grupowania"".';
					|tr = 'Rapor oluşturulmamıştır. ""Düzenleme öğeleri ve gruplandırmalar"" bölümüne en az bir gruplandırma ekleyin.'") ;
	EndIf;
	
	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument, ChartParameters());
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)

	ShowSalesParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ShowSales_");
	If ShowSalesParameter <> Undefined 
		And ShowSalesParameter.Value = Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ShowSales_", 1);
				
		UserSettingsModified = True;
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

Function ChartParameters()
	// Redefine and add chart parameters
	ChartParameters = DataCompositionServer.ChartParameters(SettingsComposer);
	
	ChartParameters.Insert("Report", ThisObject);
	ChartParameters.Insert("ExtendedSeriesDesign", True);
	
	Return ChartParameters;
EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
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