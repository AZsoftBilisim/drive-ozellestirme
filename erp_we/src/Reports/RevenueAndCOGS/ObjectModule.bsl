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
	If Not VariantKey = "SalesOfOrganizationsByCounterparty" Then
		Settings.Events.BeforeImportSettingsToComposer = True;
	EndIf;
	
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
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "Sales" Then
			
			GenerateParametersOfSalesForm(Parameters.CommandParameter, ThisForm.ParametersForm);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "SalesByOrder" Then
			ThisForm.ParametersForm.Filter.Insert("SalesOrder", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "SalesByProducts" Then
			ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "SalesBySegment" Then
			
			Parameters.FixedSettings = GetFixedSalesSettingsBySegment(Parameters.CommandParameter);
			ThisForm.ParametersForm.FixedSettings = Parameters.FixedSettings;
			
		EndIf;
		
	EndIf;
	
	// Additional command
	FormSettingsComposer = ThisForm.Report.SettingsComposer; // DataCompositionSettingsComposer
	ReportSettings = ThisForm.ReportSettings;
	
	If ReportSettings.Property("AdvancedFilter") Then
		AdvancedFilter = FormSettingsComposer.FixedSettings.Filter.Items.Add(
			Type("DataCompositionFilterItem"));
		AdvancedFilter.LeftValue = New DataCompositionField("Partner");
		If TypeOf(ReportSettings.AdvancedFilter) = Type("Array") Then
			ThisIsArray = True;
			If ReportSettings.AdvancedFilter.Count() > 0 Then
				TheFirstControl = ReportSettings.AdvancedFilter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			ThisIsArray = False;
			TheFirstControl = ReportSettings.AdvancedFilter;
		EndIf;
		If TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Then
			If ThisIsArray Then
				ThereAreSubordinatePartners = False;
				For Each CommandParameterElement In ReportSettings.AdvancedFilter Do
					If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
						ThereAreSubordinatePartners = True;
						Break;
					EndIf;
				EndDo;
			Else
				ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(ReportSettings.AdvancedFilter);
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
			AdvancedFilter.RightValue = ReportSettings.AdvancedFilter;
		ElsIf TypeOf(ReportSettings.AdvancedFilter) = Type("CatalogRef.PartnersSegments") Then
			AdvancedFilter.ComparisonType = DataCompositionComparisonType.InList;
			AdvancedFilter.RightValue = SegmentsServer.ItemArray(
				TheFirstControl);
		EndIf;
		AdvancedFilter.Use = True;
	EndIf;
EndProcedure

// It is called in the handler of the report form event of the same name and the report configuration
// form. See "Managed Form extension for the report.Before loading the variant on the server" in the syntax assistant.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form or report settings.
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	NewDCSettings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);

	CostCalculationAppliedAlgorithms.DeleteUnusedReportDimensions(NewDCSettings, UnusedReportFields());
	
EndProcedure

// Called in the handler for the report form event of the same name after executing the form code.
//  See "Managed Form Extension for Report.Prizagruzkevariantanaserver" in the syntax assistant.
//
// Parameters:
//   ThisForm - ClientApplicationForm
//         - ManagedFormExtensionForReports - The Form of the report, where:
//     * Report - FormDataStructure
//             - ReportObject
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure OnLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	Parameters = ThisForm.ReportSettings;
	FormSettingsComposer = Report.SettingsComposer;
	
	If Parameters.Property("Details") And Parameters.Details <> Undefined
		And Parameters.Details.UsedSettings.AdditionalProperties.Property("FixedSettings") Then
		FormSettingsComposer.LoadSettings(Parameters.Details.UsedSettings);
		NewDCSettings = FormSettingsComposer.Settings;
	EndIf;
	

EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	NeedToAttachableCircuit = False;
	
	If GetFunctionalOption("TradeManagement") Then
		NeedToAttachableCircuit = True;
		SetFieldUsageLimit("ExciseTaxAmount");
	EndIf;
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		NeedToAttachableCircuit = True;
		ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
	EndIf;
	
	If NeedToAttachableCircuit Then
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	#Region DetailUpToInitialCosts
	
	ArrayOfCDFieldsUsed = New Array();
	CostCalculationAppliedAlgorithms.GetUsedFieldsOfAllDimensions(ReportSettings.Structure,
		ArrayOfCDFieldsUsed);
	
	ArrayOfVerifiedCDFields = New Array();
	ArrayOfVerifiedCDFields.Add("ExpenseItem");
	ArrayOfVerifiedCDFields.Add("DimensionOfExpenses");
	ArrayOfVerifiedCDFields.Add("SourceProducts_");
	ArrayOfVerifiedCDFields.Add("InitialCharacteristic");
	ArrayOfVerifiedCDFields.Add("SourceReceiptDocument");
	DetailUpToInitialCosts = False;
	For Each DCField In ArrayOfCDFieldsUsed Do 
		If ArrayOfVerifiedCDFields.Find(StrSplit(String(DCField.Field), ".", False)[0]) <> Undefined Then
			DetailUpToInitialCosts = True;
			Break;
		EndIf;
	EndDo;
	DataCompositionClientServer.SetParameter(SettingsComposer, "DetailUpToInitialCosts",
		DetailUpToInitialCosts);
	
	#EndRegion
	
	ShowSales_ = ReportSettings.DataParameters.FindParameterValue(
		New DataCompositionParameter("ShowSales_")).Value;
	QueryText = QueryText(ShowSales_);

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("Table.Products.UnitOfMeasure", "Table.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("Table.Products.UnitOfMeasure", "Table.Products"));

	DataSet = DataCompositionSchema.DataSets.RevenueAndCostOfSalesWithDetails;
	DataSet.Query = QueryText;

	// Delete the fields that are not used in this configuration.
	FieldArray = UnusedReportFields();
	
	For Each FieldName In FieldArray Do
		
		ArrayOfTotalFields = New Array;
		FieldToBeDeleted = DataSet.Fields.Find(FieldName);
		
		If FieldToBeDeleted <> Undefined Then
			DataSet.Fields.Delete(FieldToBeDeleted);
		EndIf;
		
		For Each TotalField In DataCompositionSchema.TotalFields Do
			If StrFind(Lower(TotalField.Expression), Lower(FieldName)) > 0 Then
				ArrayOfTotalFields.Add(TotalField);
			EndIf;
		EndDo;

		For Each TotalField In ArrayOfTotalFields Do
			DataCompositionSchema.TotalFields.Delete(TotalField);
		EndDo;
		
	EndDo;
	
	If FieldArray.Count() > 0 Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(ReportSettings, FieldArray, True);
		CostCalculationAppliedAlgorithms.DeleteUnusedReportDimensions(ReportSettings, FieldArray);
	EndIf;
	
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

// Parameters:
// 	ReportSettings - Structure
// 	NewDCSettings - DataCompositionSettings
// 	NewDCUserSettings - DataCompositionUserSettings
//
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	
	If Not GetFunctionalOption("UseProduction") Then
		FieldArray = New Array();
		FieldArray.Add("LaborCosts");
		FieldArray.Add("ItemizedFixed");
		FieldArray.Add("ItemizedVariable"); 
		
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldArray, DataCompositionSchema,
			SettingsComposer, "RevenueAndCostOfSalesWithDetails");
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("ReportData");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "SalesByEnterpriseTransactions"
		Or PredefinedOption.VariantKey = "SalesByEnterprisePartners"
		Or PredefinedOption.VariantKey = "SalesSummary" Then
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	ElsIf PredefinedOption.VariantKey = "SalesByTransactionsByOrganizations"
		Or PredefinedOption.VariantKey = "SalesByOrganizationPartners"
		Or PredefinedOption.VariantKey = "SalesOfOrganizations"
		Or PredefinedOption.VariantKey = "SalesOfOrganizationsByCounterparty" Then	
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
	Else
		
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị gồm thuế GTGT';
								|ru = 'В валюте упр. учета с НДС';
								|en = 'In management accounting currency, including VAT'; fa = 'به ارز حسابداری مدیریت، با احتساب مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale con IVA';
								|pl = 'W walucie zarz. ewidencji z VAT';
								|tr = 'KDV dahil yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán quản trị không gồm thuế GTGT';
								|ru = 'В валюте упр. учета без НДС';
								|en = 'In management accounting currency, excluding VAT'; fa = 'به ارز حسابداری مدیریت، بدون مالیات بر ارزش افزوده';
								|it = 'In valuta della contabilità gestionale senza IVA';
								|pl = 'W walucie zarz. ewidencji bez VAT';
								|tr = 'KDV hariç yönetim muhasebesi para birimi cinsinden'"));
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = True;
		
	EndIf;
	
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportData"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = New Array;
	OptionsKeys.Add("SalesSummary");
	OptionsKeys.Add("SalesSummaryBasic");
	OptionsKeys.Add("SalesByOrganizationPartners");
	OptionsKeys.Add("SalesByPartnersBasic");
	OptionsKeys.Add("SalesBySupplier");
	OptionsKeys.Add("SalesByTransactionsByOrganizations");
	OptionsKeys.Add("SalesDynamicsBusinessRegions");
	OptionsKeys.Add("SalesDynamics");
	OptionsKeys.Add("SalesByOrderContext");
	OptionsKeys.Add("ByProductContext");
	OptionsKeys.Add("SalesDynamicsContext");
	OptionsKeys.Add("SalesOfOrganizations");
	OptionsKeys.Add("SalesByEnterpriseTransactions");
	OptionsKeys.Add("SalesByEnterprisePartners");
	OptionsKeys.Add("SalesOfOrganizationsByCounterparty");
	
	// If the option is not specified, then we will take the first one from the default list
	If Variant = Undefined Then
		Return New Structure("VariantKey", OptionsKeys[0]);
	EndIf;
	
	While OptionsKeys.Find(Variant.VariantKey) = Undefined
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

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
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "TypesOfTaxationVATIsIncludedInCost", 
		VATAccountingERP.ActivitiesVATIsIncludedInCost());
	
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
		If Not CurrentVariantKey = "SalesDynamics"
			And Not CurrentVariantKey = "SalesDynamicsBusinessRegions" Then
			AuxiliaryParameters.Add("Periodicity");
		EndIf;
	EndIf;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	AuxiliaryParameters.Add("MaxSeriesCount");
	AuxiliaryParameters.Add("SelectionOfChartSeries");
	AuxiliaryParameters.Add("FollowedDimensions");
	AuxiliaryParameters.Add("GradientOfChartSeries");
	AuxiliaryParameters.Add("DisplayChartPointMarkers");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
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

Procedure GenerateParametersOfSalesForm(CommandParameter, FormParameters)

	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		ThisIsArray = False;
		TheFirstControl = CommandParameter;
	EndIf;
	
	If ThisIsArray Then
		ThereAreSubordinatePartners = False;
		For Each CommandParameterElement In CommandParameter Do
			If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
				ThereAreSubordinatePartners = True;
				Break;
			EndIf;
		EndDo;
	Else
		ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
	EndIf;
	
	If ThereAreSubordinatePartners Then
		AddDownstreamPartnersToArray(CommandParameter, CommandParameter);
		FormParameters.Filter = New Structure("Partner", CommandParameter);
		FormParameters.PurposeUseKey = "Partners_Group";
	Else
		FormParameters.Filter = New Structure("Partner", CommandParameter);
		FormParameters.PurposeUseKey = "Partner";
	EndIf;
	
EndProcedure

Procedure AddDownstreamPartnersToArray(Val ArrayOfPartners, NewArrayOfPartners)
	
	For Each Partner In ArrayOfPartners Do
		
		ArrayOfDownstreamPartners = PartnersAndCounterparties.GetDownstreamPartners(Partner);
		For Each DownstreamPartner In ArrayOfDownstreamPartners Do
			If DownstreamPartner <> Partner Then
				NewArrayOfPartners.Add(DownstreamPartner);
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Function GetFixedSalesSettingsBySegment(CommandParameter)
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		ThisIsArray = False;
		TheFirstControl = CommandParameter;
	EndIf;
	
	FixedSettings = New DataCompositionSettings();
	FilterElement = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Partner");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	
	FilterElement.RightValue = SegmentsOfCallServer.ValueList(TheFirstControl);
	
	Return FixedSettings;
	
EndFunction

Function QueryText(ShowSales_)
	
	#Region SelectionByPartnerSegment
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	TRUE AS FilterByPartnerSegmentIsUsed
	|INTO SelectionByPartnerSegment
	|FROM
	|	InformationRegister.SegmentPartners AS Segments
	|{WHERE
	|	Segments.Segment.* AS PartnersSegment,
	|	Segments.Partner.* AS Partner}
	|
	|INDEX BY
	|	Partner,
	|	FilterByPartnerSegmentIsUsed
	|;";
	#EndRegion
	
	#Region SelectionByProductSegment
	QueryText = QueryText + "
	|SELECT ALLOWED DISTINCT
	|	Segments.Products AS Products,
	|	Segments.Characteristic AS Characteristic,
	|	TRUE AS FilterByProductSegmentIsUsed
	|INTO SelectionByProductSegment
	|FROM
	|	InformationRegister.SegmentProducts AS Segments
	|{WHERE
	|	Segments.Segment.* AS ProductSegment,
	|	Segments.Products.* AS Products,
	|	Segments.Characteristic.* AS Characteristic}
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	FilterByProductSegmentIsUsed
	|;";
	#EndRegion
	
	#Region Sales
	QueryText = QueryText + "
	|SELECT ALLOWED
	|	0 AS DataSet,
	|	Table.Recorder,
	|	
	|	Table.SecondPeriod,
	|	Table.DayPeriod,
	|	Table.WeekPeriod,
	|	Table.TenDaysPeriod,
	|	Table.MonthPeriod,
	|	Table.QuarterPeriod,
	|	Table.HalfYearPeriod,
	|	Table.YearPeriod,
	|	Table.AdjustmentPeriod_,
	|	
	|	SUM(Table.Count) AS Count,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.Revenue)
	|		WHEN &ReportData = 2 OR &ReportData = 3
	|			THEN SUM(Table.RevenueExcludingVAT)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.LocalRevenueExcludingVAT)
	|		ELSE SUM(Table.RevenueExcludingVAT)
	|	END AS Revenue,
	|	CASE
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.RevenueCompl) - SUM(Table.LocalRevenueExcludingVAT)
	|		ELSE
	|			SUM(Table.Revenue) - SUM(Table.RevenueExcludingVAT)
	|	END AS VATRevenue,
	|	CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2
	|			THEN SUM(Table.ManualDiscountTurnover)
	|		ELSE 0
	|	END AS ManualDiscount,
	|	CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2
	|			THEN SUM(Table.DiscountMarkupAmountTurnover)
	|		ELSE 0
	|	END AS DiscountMarkupAmount,
	|	CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2
	|			THEN SUM(Table.ManualDiscountTurnover)
	|		ELSE 0
	|	END + CASE
	|		WHEN &ReportData = 1 OR &ReportData = 2
	|			THEN SUM(Table.DiscountMarkupAmountTurnover)
	|		ELSE 0
	|	END AS TotalOfDiscounts,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.Cost_)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.CostExcludingVAT_)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.ManagementCost)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.CostLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.CostExcludingVAT_)
	|			ELSE
	|				SUM(Table.ManagementCost)
	|			END
	|	END AS Cost_,
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.AddExpensesForGoods)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.AdditionalExpensesExcludingVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.AddExpensesMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.AddExpensesLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.AdditionalExpensesExcludingVAT)
	|			ELSE
	|				SUM(Table.AddExpensesMan)
	|			END
	|	END AS AddExpensesForGoods,
	|
	|	CASE
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.ExciseAmountInCurrencyLocal)
	|		ELSE
	|			SUM(Table.ExciseAmountInCurrencyMgmt)
	|	END AS ExciseTaxAmount,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.LaborCosts)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.LaborCosts)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.LaborCostsMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.LaborCostsLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.LaborCosts)
	|			ELSE
	|				SUM(Table.LaborCostsMan)
	|			END
	|	END AS LaborCosts,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.ItemizedFixedCostsIncludingVAT)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.ItemizedFixedCostsExcludingVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.ItemizedFixedCostsManag)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.ItemizedFixedCostsCompl)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.ItemizedFixedCostsExcludingVAT)
	|			ELSE
	|				SUM(Table.ItemizedFixedCostsManag)
	|			END
	|	END AS ItemizedFixed,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.ItemizedVariableCostsIncludingVAT)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.ItemizedVariableCostsExcludingVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.ItemizedVariableCostsManag)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.ItemizedVariableCostsCompl)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.ItemizedVariableCostsExcludingVAT)
	|			ELSE
	|				SUM(Table.ItemizedVariableCostsManag)
	|			END
	|	END AS ItemizedVariable,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.SellingExpensesIncludingVAT)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.SellingExpensesExcludingVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.SellingExpensesMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.SellingExpensesLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.SellingExpensesExcludingVAT)
	|			ELSE
	|				SUM(Table.SellingExpensesMan)
	|			END
	|	END AS SellingExpenses_,
	|
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN 0
	|		WHEN &ReportData = 2
	|			THEN 0
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.ProvisionForImpairmentMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.ProvisionForImpairmentLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				0
	|			ELSE
	|				SUM(Table.ProvisionForImpairmentMan)
	|			END
	|	END AS ProvisionForImpairment,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.Cost_Preliminary)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.PreliminaryCostPriceWithoutVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.CostOfPreliminaryMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.PreLocalCostPrice)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.PreliminaryCostPriceWithoutVAT)
	|			ELSE
	|				SUM(Table.CostOfPreliminaryMan)
	|			END
	|	END AS Cost_Preliminary,
	|	
	|	CASE
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.Cost_)
	|			+ SUM(Table.AddExpensesForGoods)
	|			+ SUM(Table.LaborCosts)
	|			+ SUM(Table.ItemizedFixedCostsIncludingVAT)
	|			+ SUM(Table.ItemizedVariableCostsIncludingVAT)
	|			- SUM(Table.Cost_Preliminary)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.CostExcludingVAT_)
	|			+ SUM(Table.AdditionalExpensesExcludingVAT)
	|			+ SUM(Table.LaborCosts)
	|			+ SUM(Table.ItemizedFixedCostsExcludingVAT)
	|			+ SUM(Table.ItemizedVariableCostsExcludingVAT)
	|			- SUM(Table.PreliminaryCostPriceWithoutVAT)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.ManagementCost)
	|			+ SUM(Table.AddExpensesMan)
	|			+ SUM(Table.LaborCostsMan)
	|			+ SUM(Table.ItemizedFixedCostsManag)
	|			+ SUM(Table.ItemizedVariableCostsManag)
	|			+ SUM(Table.ProvisionForImpairmentMan)
	|			- SUM(Table.CostOfPreliminaryMan)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.CostLocal)
	|			+ SUM(Table.AddExpensesLocal)
	|			+ SUM(Table.LaborCostsLocal)
	|			+ SUM(Table.ItemizedFixedCostsCompl)
	|			+ SUM(Table.ItemizedVariableCostsCompl)
	|			+ SUM(Table.ProvisionForImpairmentLocal)
	|			- SUM(Table.PreLocalCostPrice)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.CostExcludingVAT_)
	|				+ SUM(Table.AdditionalExpensesExcludingVAT)
	|				+ SUM(Table.LaborCosts)
	|				+ SUM(Table.ItemizedFixedCostsExcludingVAT)
	|				+ SUM(Table.ItemizedVariableCostsExcludingVAT)
	|				- SUM(Table.PreliminaryCostPriceWithoutVAT)
	|			ELSE
	|				SUM(Table.ManagementCost)
	|				+ SUM(Table.AddExpensesMan)
	|				+ SUM(Table.LaborCostsMan)
	|				+ SUM(Table.ItemizedFixedCostsManag)
	|				+ SUM(Table.ItemizedVariableCostsManag)
	|				+ SUM(Table.ProvisionForImpairmentMan)
	|				- SUM(Table.CostOfPreliminaryMan)
	|			END
	|	END AS CostDeviation_,
	|	
	|	CASE
	|		WHEN Table.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN 0
	|		WHEN &ReportData = 1
	|			THEN SUM(Table.Revenue)
	|			- SUM(Table.Cost_)
	|			- SUM(Table.AddExpensesForGoods)
	|			- SUM(Table.LaborCosts)
	|			- SUM(Table.ItemizedFixedCostsIncludingVAT)
	|			- SUM(Table.ItemizedVariableCostsIncludingVAT)
	|			- SUM(Table.SellingExpensesIncludingVAT)
	|			- SUM(Table.ExciseAmountInCurrencyMgmt)
	|		WHEN &ReportData = 2
	|			THEN SUM(Table.RevenueExcludingVAT)
	|			- SUM(Table.CostExcludingVAT_)
	|			- SUM(Table.AdditionalExpensesExcludingVAT)
	|			- SUM(Table.LaborCosts)
	|			- SUM(Table.ItemizedFixedCostsExcludingVAT)
	|			- SUM(Table.ItemizedVariableCostsExcludingVAT)
	|			- SUM(Table.SellingExpensesExcludingVAT)
	|			- SUM(Table.ExciseAmountInCurrencyMgmt)
	|		WHEN &ReportData = 3
	|			THEN SUM(Table.RevenueExcludingVAT)
	|			- SUM(Table.ManagementCost)
	|			- SUM(Table.AddExpensesMan)
	|			- SUM(Table.LaborCostsMan)
	|			- SUM(Table.ItemizedFixedCostsManag)
	|			- SUM(Table.ItemizedVariableCostsManag)
	|			- SUM(Table.SellingExpensesMan)
	|			- SUM(Table.ProvisionForImpairmentMan)
	|			- SUM(Table.ExciseAmountInCurrencyMgmt)
	|		WHEN &ReportData = 4
	|			THEN SUM(Table.LocalRevenueExcludingVAT)
	|			- SUM(Table.CostLocal)
	|			- SUM(Table.AddExpensesLocal)
	|			- SUM(Table.LaborCostsLocal)
	|			- SUM(Table.ItemizedFixedCostsCompl)
	|			- SUM(Table.ItemizedVariableCostsCompl)
	|			- SUM(Table.SellingExpensesLocal)
	|			- SUM(Table.ProvisionForImpairmentLocal)
	|			- SUM(Table.ExciseAmountInCurrencyLocal)
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				SUM(Table.RevenueExcludingVAT)
	|				- SUM(Table.CostExcludingVAT_)
	|				- SUM(Table.AdditionalExpensesExcludingVAT)
	|				- SUM(Table.LaborCosts)
	|				- SUM(Table.ItemizedFixedCostsExcludingVAT)
	|				- SUM(Table.ItemizedVariableCostsExcludingVAT)
	|				- SUM(Table.SellingExpensesExcludingVAT)
	|			ELSE
	|				SUM(Table.RevenueExcludingVAT)
	|				- SUM(Table.ManagementCost)
	|				- SUM(Table.AddExpensesMan)
	|				- SUM(Table.LaborCostsMan)
	|				- SUM(Table.ItemizedFixedCostsManag)
	|				- SUM(Table.ItemizedVariableCostsManag)
	|				- SUM(Table.SellingExpensesMan)
	|				- SUM(Table.ProvisionForImpairmentMan)
	|			END 
	|				- SUM(Table.ExciseAmountInCurrencyMgmt)
	|	END AS GrossProfit,
	|	CASE
	|		WHEN Table.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN 0
	|		WHEN &ReportData = 1
	|			THEN CAST(CASE
	|					WHEN SUM(Table.Revenue) <> 0
	|						THEN (SUM(Table.Revenue)
	|							- SUM(Table.Cost_)
	|							- SUM(Table.AddExpensesForGoods)
	|							- SUM(Table.LaborCosts)
	|							- SUM(Table.ItemizedFixedCostsIncludingVAT)
	|							- SUM(Table.ItemizedVariableCostsIncludingVAT)
	|							- SUM(Table.SellingExpensesIncludingVAT)
	|							- SUM(Table.ExciseAmountInCurrencyMgmt)
	|						) / CASE WHEN SUM(Table.Revenue) > 0
	|								THEN SUM(Table.Revenue)
	|								ELSE -1*SUM(Table.Revenue)
	|							END
	|					ELSE 0
	|				END * 100 AS NUMBER(31,2))
	|		WHEN &ReportData = 2
	|			THEN CAST(CASE
	|					WHEN SUM(Table.RevenueExcludingVAT) <> 0
	|						THEN (SUM(Table.RevenueExcludingVAT)
	|							- SUM(Table.CostExcludingVAT_)
	|							- SUM(Table.AdditionalExpensesExcludingVAT)
	|							- SUM(Table.LaborCosts)
	|							- SUM(Table.ItemizedFixedCostsExcludingVAT)
	|							- SUM(Table.ItemizedVariableCostsExcludingVAT)
	|							- SUM(Table.SellingExpensesExcludingVAT)
	|							- SUM(Table.ExciseAmountInCurrencyMgmt)
	|						) / CASE WHEN SUM(Table.RevenueExcludingVAT) > 0
	|								THEN SUM(Table.RevenueExcludingVAT)
	|								ELSE -1*SUM(Table.RevenueExcludingVAT)
	|							END
	|					ELSE 0
	|				END * 100 AS NUMBER(31,2))
	|		WHEN &ReportData = 3
	|			THEN CAST(CASE
	|					WHEN SUM(Table.RevenueExcludingVAT) <> 0
	|						THEN (SUM(Table.RevenueExcludingVAT)
	|							- SUM(Table.ManagementCost)
	|							- SUM(Table.AddExpensesMan)
	|							- SUM(Table.LaborCostsMan)
	|							- SUM(Table.ItemizedFixedCostsManag)
	|							- SUM(Table.ItemizedVariableCostsManag)
	|							- SUM(Table.SellingExpensesMan)
	|							- SUM(Table.ProvisionForImpairmentMan)
	|							- SUM(Table.ExciseAmountInCurrencyMgmt)
	|						) / CASE WHEN SUM(Table.RevenueExcludingVAT) > 0
	|								THEN SUM(Table.RevenueExcludingVAT)
	|								ELSE -1*SUM(Table.RevenueExcludingVAT)
	|							END
	|					ELSE 0
	|				END * 100 AS NUMBER(31,2))
	|		WHEN &ReportData = 4
	|			THEN CAST(CASE
	|					WHEN SUM(Table.LocalRevenueExcludingVAT) <> 0
	|						THEN (SUM(Table.LocalRevenueExcludingVAT)
	|							- SUM(Table.CostLocal)
	|							- SUM(Table.AddExpensesLocal)
	|							- SUM(Table.LaborCostsLocal)
	|							- SUM(Table.ItemizedFixedCostsCompl)
	|							- SUM(Table.ItemizedVariableCostsCompl)
	|							- SUM(Table.SellingExpensesLocal)
	|							- SUM(Table.ProvisionForImpairmentLocal)
	|							- SUM(Table.ExciseAmountInCurrencyLocal)
	|						) / CASE WHEN SUM(Table.LocalRevenueExcludingVAT) > 0
	|								THEN SUM(Table.LocalRevenueExcludingVAT)
	|								ELSE -1*SUM(Table.LocalRevenueExcludingVAT)
	|							END
	|					ELSE 0
	|				END * 100 AS NUMBER(31,2)) 
	|		ELSE
	|			CASE WHEN &ByEnterprise THEN
	|				CAST(CASE
	|						WHEN SUM(Table.RevenueExcludingVAT) <> 0
	|							THEN (SUM(Table.RevenueExcludingVAT)
	|								- SUM(Table.CostExcludingVAT_)
	|								- SUM(Table.AdditionalExpensesExcludingVAT)
	|								- SUM(Table.LaborCosts)
	|								- SUM(Table.ItemizedFixedCostsExcludingVAT)
	|								- SUM(Table.ItemizedVariableCostsExcludingVAT)
	|								- SUM(Table.SellingExpensesExcludingVAT)
	|								- SUM(Table.ExciseAmountInCurrencyMgmt)
	|							) / CASE WHEN SUM(Table.RevenueExcludingVAT) > 0
	|									THEN SUM(Table.RevenueExcludingVAT)
	|									ELSE -1*SUM(Table.RevenueExcludingVAT)
	|								END
	|						ELSE 0
	|					END * 100 AS NUMBER(31,2))
	|			ELSE
	|				CAST(CASE
	|						WHEN SUM(Table.RevenueExcludingVAT) <> 0
	|							THEN (SUM(Table.RevenueExcludingVAT)
	|								- SUM(Table.ManagementCost)
	|								- SUM(Table.AddExpensesMan)
	|								- SUM(Table.LaborCostsMan)
	|								- SUM(Table.ItemizedFixedCostsManag)
	|								- SUM(Table.ItemizedVariableCostsManag)
	|								- SUM(Table.SellingExpensesMan)
	|								- SUM(Table.ProvisionForImpairmentMan)
	|								- SUM(Table.ExciseAmountInCurrencyMgmt)
	|							) / CASE WHEN SUM(Table.RevenueExcludingVAT) > 0
	|									THEN SUM(Table.RevenueExcludingVAT)
	|									ELSE -1*SUM(Table.RevenueExcludingVAT)
	|								END
	|						ELSE 0
	|					END * 100 AS NUMBER(31,2))
	|			END
	|	END AS Profitability,
	|	CASE
	|		WHEN Table.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS IntercompanySales,
	|	Table.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Table.Products AS Products,
	|	Table.Products.UnitOfMeasure AS StorageUnit,
	|	Table.Products.UnitForReports AS UnitForReports,
	|	Table.Products.UnitFactorForReports AS UnitFactorForReports,
	|	&QueryTextItemWeight1 AS ProductsWeight,
	|	&QueryTextTheVolumeOfTheItem1 AS ProductsVolume,
	|	Table.Products.AnalyticalGroup AS AnalyticalGroup,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.Organization AS Organization,
	|	Table.Seller AS Seller,
	|	Table.Partner AS Partner,
	|	Table.SalesOrder AS SalesOrder,
	|	Table.Department AS Department,
	|	Table.Warehouse AS Warehouse,
	|	Table.Counterparty AS Counterparty,
	|	Table.Customer AS Customer,
	|	Table.Vendor AS Vendor,
	|	Table.Manager AS Manager,
	|	Table.SalesOpportunity AS SalesOpportunity,
	|	Table.Terms AS Terms,
	|	Table.Contract AS Contract,
	|	Table.OpportunityManager AS OpportunityManager,
	|	Table.InventoryType AS InventoryType,
	|	Table.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Table.AccountingSection AS AccountingSection,
	|	Table.Lot AS Lot,
	|	Table.LotVendorAttributes AS LotVendorAttributes,
	|	Table.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Table.VATActivityType AS VATActivityType,
	|	Table.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Table.SalesOpportunityKind,
	|	Table.CounterpartyLineOfBusiness,
	|	Table.ProductLineOfBusiness,
	|	Table.SetAccountingDimension,
	|	CASE WHEN &ReportData = 4 THEN
	|		Table.Organization.LocalAccountingCurrency
	|	ELSE
	|		&ManagementAccountingCurrency
	|	END AS Currency,
	|	Table.VATIsIncludedInCost,
	|	Table.NoCostDetailingIsRequired,
	|	Table.BusinessOperation,
	|	Table.VATRate
	|{SELECT
	|	SalesOrder.*,
	|	SalesOpportunity.*,
	|	OpportunityManager,
	|	Department.*,
	|	ItemsLocationAttributes.*,
	|	AccountingDimensionByPartners.*,
	|	Products.*,
	|	Characteristic.*,
	|	Warehouse.*,
	|	Organization.*,
	|	Seller.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Customer.*,
	|	Vendor.*,
	|	Manager.*,
	|	InventoryOwnerAttribute.*,
	|	FinancialAccountingGroup.*,
	|	Recorder,
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	AdjustmentPeriod_,
	|	SalesOpportunityKind,
	|	CounterpartyLineOfBusiness.*,
	|	ProductLineOfBusiness.*,
	|	Terms.*,
	|	Contract.*,
	|	SetAccountingDimension.*,
	|	BusinessOperation.*,
	|	VATIsIncludedInCost,
	|	NoCostDetailingIsRequired,
	|	VATRate.*,
	|	Count,
	|	Revenue,
	|	VATRevenue,
	|	ManualDiscount,
	|	DiscountMarkupAmount,
	|	TotalOfDiscounts,
	|	Cost_,
	|	AddExpensesForGoods,
	|	ExciseTaxAmount,
	|	LaborCosts,
	|	ItemizedVariable,
	|	SellingExpenses_,
	|	ProvisionForImpairment,
	|	Cost_Preliminary,
	|	CostDeviation_,
	|	GrossProfit,
	|	Profitability,
	|	IntercompanySales
	|	}
	|
	|INTO Sales
	|FROM
	|	(SELECT
	|		CASE
	|			WHEN Sales.Recorder = UNDEFINED
	|				THEN NULL
	|			ELSE Sales.Recorder
	|		END AS Recorder,
	|		
	|		Sales.Period                           AS SecondPeriod,
	|		BEGINOFPERIOD(Sales.Period, DAY)      AS DayPeriod,
	|		BEGINOFPERIOD(Sales.Period, WEEK)    AS WeekPeriod,
	|		BEGINOFPERIOD(Sales.Period, TENDAYS)    AS TenDaysPeriod,
	|		BEGINOFPERIOD(Sales.Period, MONTH)     AS MonthPeriod,
	|		BEGINOFPERIOD(Sales.Period, QUARTER)   AS QuarterPeriod,
	|		BEGINOFPERIOD(Sales.Period, HALFYEAR) AS HalfYearPeriod,
	|		BEGINOFPERIOD(Sales.Period, YEAR)       AS YearPeriod,
	|		Sales.AdjustmentPeriod_              AS AdjustmentPeriod_,
	|		
	|		ISNULL(Sales.SalesOrder.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)) AS SalesOpportunity,
	|		ISNULL(Sales.SalesOrder.SalesOpportunity.EmployeeResponsible, VALUE(Catalog.Users.EmptyRef)) AS OpportunityManager,
	|		CASE
	|			WHEN Sales.Manager = VALUE(Catalog.Users.EmptyRef)
	|				THEN ISNULL(Sales.SalesOrder.Manager, VALUE(Catalog.Users.EmptyRef))
	|			ELSE Sales.Manager
	|		END AS Manager,
	|		Sales.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|		Sales.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Sales.ItemsLocationAttributes.Products AS Products,
	|		Sales.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		Sales.ItemsLocationAttributes.Series AS Series,
	|		Sales.AccountingDimensionByPartners.Organization AS Organization,
	|		Sales.AccountingDimensionByPartners.Organization AS Seller,
	|		Sales.AccountingDimensionByPartners.Partner AS Partner,  
	|		Sales.InventoryType AS InventoryType,
	|		Sales.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|		Sales.InventoryOwnerAttribute.FinancialAccountingGroup AS FinancialAccountingGroup,
	|		Sales.AccountingSection AS AccountingSection,
	|		Sales.Lot AS Lot,
	|		Sales.LotVendorAttributes AS LotVendorAttributes,
	|		Sales.FinancialAccountingDimension AS FinancialAccountingDimension,
	|		Sales.VATActivityType AS VATActivityType,
	|		Sales.Department AS Department,
	|		Sales.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|		CASE
	|			WHEN Sales.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.InventoryOwnerAttribute.GoodsOwner
	|		ELSE
	|			Sales.LotVendorAttributes.Vendor
	|		END AS Vendor,
	|		Sales.SalesOrder AS SalesOrder,
	|		CASE
	|			WHEN Sales.AccountingDimensionByPartners.Counterparty REFS Catalog.Counterparties
	|				THEN Sales.AccountingDimensionByPartners.Counterparty
	|			ELSE NULL
	|		END AS Counterparty,
	|		CASE
	|			WHEN Sales.AccountingDimensionByPartners.Counterparty REFS Catalog.Companies
	|				THEN Sales.AccountingDimensionByPartners.Counterparty
	|			ELSE NULL
	|		END AS Customer,
	|		CASE
	|			WHEN NOT Sales.SalesOrder.SalesOpportunity.SalesOpportunityKind IS NULL 
	|				THEN Sales.SalesOrder.SalesOpportunity.SalesOpportunityKind.Description
	|			WHEN Sales.SalesOrder REFS Document.SalesOrder
	|					OR Sales.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN &LineSalesByOrders
	|			ELSE &LineSalesWithoutOrders
	|		END AS SalesOpportunityKind,
	|		Sales.CounterpartyLineOfBusiness,
	|		Sales.ProductLineOfBusiness,
	|		Sales.Terms AS Terms,
	|		Sales.Contract AS Contract,
	|		Sales.SetAccountingDimension,
	|		(CASE
	|			WHEN Sales.VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN TRUE ELSE FALSE END) AS VATIsIncludedInCost,
	// For records of inclusion/exclusion of VAT from the cost, it is not required to add cost details, because
	// cost detail lines, taking into account the inclusion of VAT, are added to records with the amounts of additional expenses.
	|		(CASE
	|			WHEN Sales.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			 OR Sales.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.EmptyRef)
	|				THEN TRUE ELSE FALSE END) AS NoCostDetailingIsRequired,
	| 
	|		Sales.Count AS Count,
	|		Sales.RevenueAmount AS Revenue,
	|		Sales.RevenueAmountExclVATLocal AS LocalRevenueExcludingVAT,
	|		Sales.RevenueAmountIncludingVATLocal AS RevenueCompl,
	|		Sales.RevenueAmountExcludingVAT AS RevenueExcludingVAT,
	|		CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.RevenueAmount
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.Cost, 0) AS NUMBER(31,2))
	|			ELSE Sales.Cost
	|		END AS Cost_,
	|		CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.RevenueAmountExcludingVAT
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.CostExcludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.CostExcludingVAT
	|		END AS CostExcludingVAT_,
	|		CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.RevenueAmountExclVATLocal
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.LocalCost, 0) AS NUMBER(31,2))
	|			ELSE Sales.LocalCost
	|		END AS CostLocal,
	|		CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.RevenueAmountExcludingVAT
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.CostMan, 0) AS NUMBER(31,2))
	|			ELSE Sales.CostMan
	|		END AS ManagementCost,
	|		
	|		// Additional expenses
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.AdditionalExpenseCost, 0) AS NUMBER(31,2))
	|			ELSE Sales.AddExpensesForGoods
	|		END AS AddExpensesForGoods,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.AddExpensesMan, 0) AS NUMBER(31,2))
	|			ELSE Sales.AddExpensesMan
	|		END AS AddExpensesMan,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.AdditionalExpensesCostExcludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.AdditionalExpensesExcludingVAT
	|		END AS AdditionalExpensesExcludingVAT,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.AddExpensesLocal, 0) AS NUMBER(31,2))
	|			ELSE Sales.AddExpensesLocal
	|		END AS AddExpensesLocal,
	|		
	|		// LaborCosts
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.LaborCosts, 0) AS NUMBER(31,2))
	|			ELSE Sales.LaborCosts
	|		END AS LaborCosts,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.LaborCostsMan, 0) AS NUMBER(31,2))
	|			ELSE Sales.LaborCostsMan
	|		END AS LaborCostsMan,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.LaborCostsLocal, 0) AS NUMBER(31,2))
	|			ELSE Sales.LaborCostsLocal
	|		END AS LaborCostsLocal,
	|		
	|		// Permanent posts
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedFixedCostsIncludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedFixedCostsIncludingVAT
	|		END AS ItemizedFixedCostsIncludingVAT,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedFixedCostsExcludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedFixedCostsExcludingVAT
	|		END AS ItemizedFixedCostsExcludingVAT,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedFixedCostsManag, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedFixedCostsManag
	|		END AS ItemizedFixedCostsManag,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedFixedCostsCompl, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedFixedCostsCompl
	|		END AS ItemizedFixedCostsCompl,
	|		
	|		// Variables are optional
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedVariableCostsIncludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedVariableCostsIncludingVAT
	|		END AS ItemizedVariableCostsIncludingVAT,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedVariableCostsExcludingVAT, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedVariableCostsExcludingVAT
	|		END AS ItemizedVariableCostsExcludingVAT,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedVariableCostsManag, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedVariableCostsManag
	|		END AS ItemizedVariableCostsManag,
	|		CASE
	|			WHEN ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|				THEN CAST(Sales.Count * ISNULL(CostOfProducts.ItemizedVariableCostsCompl, 0) AS NUMBER(31,2))
	|			ELSE Sales.ItemizedVariableCostsCompl
	|		END AS ItemizedVariableCostsCompl,
	|		
	|		// ExciseDuty
	|		Sales.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|		Sales.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|		
	|		(CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN 0
	|			WHEN Sales.MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|				THEN Sales.Cost
	|				+ Sales.AddExpensesForGoods
	|				+ Sales.LaborCosts
	|				+ Sales.ItemizedFixedCostsIncludingVAT
	|				+ Sales.ItemizedVariableCostsIncludingVAT
	|			ELSE 0 END) AS Cost_Preliminary,
	|		(CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN 0
	|			WHEN Sales.MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|				THEN Sales.CostExcludingVAT
	|				+ Sales.AdditionalExpensesExcludingVAT
	|				+ Sales.LaborCosts
	|				+ Sales.ItemizedFixedCostsExcludingVAT
	|				+ Sales.ItemizedVariableCostsExcludingVAT
	|			ELSE 0 END) AS PreliminaryCostPriceWithoutVAT,
	|		(CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN 0
	|			WHEN Sales.MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|				THEN Sales.LocalCost
	|				+ Sales.AddExpensesLocal
	|				+ Sales.LaborCostsLocal
	|				+ Sales.ItemizedFixedCostsCompl
	|				+ Sales.ItemizedVariableCostsCompl
	|			ELSE 0 END) AS PreLocalCostPrice,
	|		(CASE
	|			WHEN Sales.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN 0
	|			WHEN Sales.MonthEndClosingMode = VALUE(Enum.MonthEndClosingModes.PreliminaryClosing)
	|				THEN Sales.CostMan
	|				+ Sales.AddExpensesMan
	|				+ Sales.LaborCostsMan
	|				+ Sales.ItemizedFixedCostsManag
	|				+ Sales.ItemizedVariableCostsManag
	|			ELSE 0 END) AS CostOfPreliminaryMan,
	|		
	|		Sales.SellingExpensesIncludingVAT AS SellingExpensesIncludingVAT,
	|		Sales.SellingExpensesExcludingVAT AS SellingExpensesExcludingVAT,
	|		Sales.SellingExpensesLocal AS SellingExpensesLocal,
	|		Sales.SellingExpensesMan AS SellingExpensesMan,
	|
	|		Sales.ProvisionForImpairmentLocal AS ProvisionForImpairmentLocal,
	|		Sales.ProvisionForImpairmentMan AS ProvisionForImpairmentMan,
	|		
	|		Sales.ManualDiscount AS ManualDiscountTurnover,
	|		Sales.DiscountMarkupAmount AS DiscountMarkupAmountTurnover,
	|		Sales.BusinessOperation AS BusinessOperation,
	|		Sales.VATRate AS VATRate
	|	FROM
	|		AccumulationRegister.RevenueAndCOGS AS Sales
	|		
	|		LEFT JOIN Document.InventoryCostCalculation.Companies AS InventoryCostCalculation
	|			ON (BEGINOFPERIOD(Sales.Period, MONTH) = BEGINOFPERIOD(InventoryCostCalculation.Ref.Date, MONTH))
	|			AND (Sales.AccountingDimensionByPartners.Organization = InventoryCostCalculation.Organization)
	|			AND InventoryCostCalculation.Ref.EntryType = VALUE(Enum.LotRecordTypes.EmptyRef)
	|			AND (InventoryCostCalculation.Ref.Posted)
	|		LEFT JOIN InformationRegister.GoodsCost AS CostOfProducts
	|			ON Sales.ItemsLocationAttributes = CostOfProducts.ItemsLocationAttributes
	|			AND (Sales.AccountingDimensionByPartners.Organization = CostOfProducts.Organization)
	|			AND Sales.InventoryOwnerAttribute = CostOfProducts.InventoryOwnerAttribute
	|			AND (CostOfProducts.Period = BEGINOFPERIOD(Sales.Period, MONTH))
	|			AND Sales.AccountingSection = CostOfProducts.AccountingSection
	|			AND ISNULL(InventoryCostCalculation.Ref.PreliminaryCalculation, FALSE)
	|	WHERE
	|		(&ShowSales_ = 1
	|					AND Sales.AccountingDimensionByPartners.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|				OR &ShowSales_ = 2
	|					AND Sales.AccountingDimensionByPartners.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|				OR &ShowSales_ = 0)
	|		AND (Sales.Period >= &BeginOfPeriod AND (Sales.Period <= &EndOfPeriod OR &EndOfPeriod = DATETIME(1, 1, 1)))
	|	{WHERE
	|		Sales.ItemsLocationAttributes.Products.* AS Products,
	|		Sales.ItemsLocationAttributes.Characteristic.* AS Characteristic,
	|		Sales.ItemsLocationAttributes.StorageLocation.* AS Warehouse,
	|		((Sales.ItemsLocationAttributes.Products, Sales.ItemsLocationAttributes.Characteristic) IN
	|				(SELECT
	|					SelectionByProductSegment.Products,
	|					SelectionByProductSegment.Characteristic
	|				FROM
	|					SelectionByProductSegment
	|				WHERE
	|					SelectionByProductSegment.FilterByProductSegmentIsUsed = &FilterByProductSegmentIsUsed)),
	|		(Sales.AccountingDimensionByPartners.Partner IN
	|				(SELECT
	|					SelectionByPartnerSegment.Partner
	|				FROM
	|					SelectionByPartnerSegment
	|				WHERE
	|					SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed)),
	|		(ISNULL(Sales.SalesOrder.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef))).* AS SalesOpportunity,
	|		Sales.Contract.* AS Contract,
	|		(CASE
	|				WHEN Sales.AccountingDimensionByPartners.Counterparty REFS Catalog.Counterparties
	|					THEN Sales.AccountingDimensionByPartners.Counterparty
	|				ELSE NULL
	|			END).* AS Counterparty,
	|		(CASE
	|				WHEN Sales.AccountingDimensionByPartners.Counterparty REFS Catalog.Companies
	|					THEN Sales.AccountingDimensionByPartners.Counterparty
	|				ELSE NULL
	|			END).* AS Customer,
	|		Sales.BusinessOperation.*,
	|		Sales.VATRate.*,
	|		Sales.AccountingDimensionByPartners.Organization.* AS Organization,
	|		Sales.AccountingDimensionByPartners.Partner.* AS Partner,
	|		(ISNULL(Sales.SalesOrder.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef))).* AS SalesOpportunity,
	|		(ISNULL(Sales.SalesOrder.SalesOpportunity.EmployeeResponsible, VALUE(Catalog.Users.EmptyRef))).* AS OpportunityManager, 
	|		(CASE
	|		    WHEN Sales.Manager = VALUE(Catalog.Users.EmptyRef)
	|		        THEN ISNULL(Sales.SalesOrder.Manager, VALUE(Catalog.Users.EmptyRef))
	|		    ELSE Sales.Manager
	|		END).* AS Manager,
	|		(CASE
	|			WHEN Sales.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN Sales.InventoryOwnerAttribute.GoodsOwner
	|			ELSE
	|				Sales.LotVendorAttributes.Vendor
	|		END).* AS Vendor,
	|		(Sales.InventoryOwnerAttribute.FinancialAccountingGroup).* AS FinancialAccountingGroup,
	|		(CASE
	|		    WHEN NOT Sales.SalesOrder.SalesOpportunity.SalesOpportunityKind IS NULL 
	|				THEN Sales.SalesOrder.SalesOpportunity.SalesOpportunityKind.Description
	|			WHEN Sales.SalesOrder REFS Document.SalesOrder
	|			 OR Sales.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN &LineSalesByOrders
	|			ELSE &LineSalesWithoutOrders
	|		END) AS SalesOpportunityKind
	|		}
	|	) AS Table
	|
	|GROUP BY
	|	Table.SalesOpportunity,
	|	Table.OpportunityManager,
	|	CASE
	|		WHEN Table.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			THEN TRUE
	|		ELSE FALSE
	|	END, // IntercompanySales
	|	Table.ItemsLocationAttributes,
	|	Table.AccountingDimensionByPartners,
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Series,
	|	Table.Organization,
	|	Table.Seller,
	|	Table.Partner,
	|	Table.Recorder,
	|	Table.SecondPeriod,
	|	Table.DayPeriod,
	|	Table.WeekPeriod,
	|	Table.TenDaysPeriod,
	|	Table.MonthPeriod,
	|	Table.QuarterPeriod,
	|	Table.HalfYearPeriod,
	|	Table.YearPeriod,
	|	Table.AdjustmentPeriod_,
	|	Table.SalesOrder,
	|	Table.Department,
	|	Table.Warehouse,
	|	Table.Counterparty,
	|	Table.Customer,
	|	Table.Vendor,
	|	Table.Manager,
	|	Table.InventoryType,
	|	Table.InventoryOwnerAttribute,
	|	Table.AccountingSection,
	|	Table.Lot,
	|	Table.LotVendorAttributes,
	|	Table.FinancialAccountingDimension,
	|	Table.VATActivityType,
	|	Table.FinancialAccountingGroup,
	|	Table.SalesOpportunityKind,
	|	Table.CounterpartyLineOfBusiness,
	|	Table.ProductLineOfBusiness,
	|	Table.Terms,
	|	Table.Contract,
	|	Table.SetAccountingDimension,
	|	Table.Products.UnitOfMeasure,
	|	Table.Products.UnitForReports,
	|	Table.Products.UnitFactorForReports,
	|	&QueryTextItemWeight1,
	|	&QueryTextTheVolumeOfTheItem1,
	|	CASE WHEN &ReportData = 4 THEN
	|		Table.Organization.LocalAccountingCurrency
	|	ELSE
	|		&ManagementAccountingCurrency
	|	END,
	|	Table.VATIsIncludedInCost,
	|	Table.NoCostDetailingIsRequired,
	|	Table.BusinessOperation,
	|	Table.VATRate
	|
	|INDEX BY
	|	Lot,
	|	LotVendorAttributes,
	|	Organization,
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic
	|;";

	#EndRegion
	
	#Region InitialSales
	QueryText = QueryText + "
	|SELECT DISTINCT
	|	Sales.SalesOrder AS SalesOrder,
	|	Sales.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO AnalyticsForSelection
	|FROM
	|	Sales AS Sales
	|WHERE
	// In the temporary Sales table, there is already a selection according to the analytics column for partners.
	|	Sales.Count <> 0
	// See comment 1531.
	|	AND Sales.SalesOrder <> UNDEFINED
	|	AND &DetailUpToInitialCosts
	|
	|INDEX BY SETS
	|	(
	// Indexing for the first index of the turnover table.
	|		(ItemsLocationAttributes, SalesOrder),
	// Indexing for an additional index.
	// Selectivity is higher with a large number of sales of identical inventory accounting analysts.
	|		(SalesOrder, ItemsLocationAttributes)
	|	)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	InitialSales.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InitialSales.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	InitialSales.SalesOrder AS SalesOrder,
	|	InitialSales.Department AS Department,
	|	InitialSales.Manager AS Manager,
	|	InitialSales.Terms AS Terms,
	|	InitialSales.Contract AS Contract,
	|	InitialSales.InventoryType AS InventoryType,
	|	InitialSales.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InitialSales.AccountingSection AS AccountingSection,
	|	InitialSales.Lot AS Lot,
	|	InitialSales.LotVendorAttributes AS LotVendorAttributes,
	|	InitialSales.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	InitialSales.VATActivityType AS VATActivityType,
	|	InitialSales.CountTurnover AS Count
	|INTO InitialSales
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(
	|			DATETIME(1,1,1) {(DATETIME(1,1,1))}, &EndOfPeriod {(&EndOfPeriod)}, Auto,
	|			(ItemsLocationAttributes, SalesOrder) IN
	|					(SELECT
	|						AnalyticsForSelection.ItemsLocationAttributes,
	|						AnalyticsForSelection.SalesOrder
	|					FROM
	|						AnalyticsForSelection AS AnalyticsForSelection)
	// Commentary 1531.
	// Customer's order is excluded in the temporary table of analyticsfor selection = It is uncertain, based on this:
	//   1. Selection by analytical accounting partners is redundant, since selection by customer order is sufficient.
	//   2. Batch selection is also excluded based on the fact that usually all batches are needed for each customer order.
	//   The exclusion of this selection is caused by the fact that on PostgreSQL, an inefficient query plan may be formed,
	//   with scanning of a non-selective index by batch.
	//   When you set the selection by batch, in the report settings, the selection condition is passed to the virtual table parameters.
	|				) AS InitialSales
	|WHERE
	|	InitialSales.CountTurnover <> 0
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	SalesOrder,
	|	AccountingDimensionByPartners,
	|	Department,
	|	Manager,
	|	Terms,
	|	Contract,
	|	InventoryOwnerAttribute,
	|	AccountingSection,
	|	Lot,
	|	LotVendorAttributes,
	|	FinancialAccountingDimension,
	|	VATActivityType
	|;
	|";
		
	#EndRegion
	
	#Region GranularityGrouped
	QueryText = QueryText + " 
	|//!!! TAGS ARE USED !!!
	|
	|SELECT ALLOWED
	|	DATETIME(1,1,1) AS MonthPeriod,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	ItemizeGoodsLotCost.Lot AS PartyDetail,
	|	ItemizeGoodsLotCost.LotVendorAttributes AS AnalysisOfAccountingAndDetailing,
	|	ItemizeGoodsLotCost.Organization AS OrganizationDetail,
	|	ItemizeGoodsLotCost.InventoryOwnerAttribute AS TypeAndDetail,
	|	ItemizeGoodsLotCost.Products AS ProductDetailing,
	|	ItemizeGoodsLotCost.Characteristic AS CharacteristicDetail,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	ItemizeGoodsLotCost.LotVendorAttributesOfReceiptDocument.AssetTaxClass AS AssetTaxClass,
	|	ItemizeGoodsLotCost.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument AS InventoryLocationAttributesOfReceiptDocument,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument.Products AS SourceProducts_,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument.Characteristic AS InitialCharacteristic,
	|	ItemizeGoodsLotCost.DocumentInflow AS SourceReceiptDocument,
	|	SUM(CASE
	|		WHEN &ReportData = 1
	|			THEN ItemizeGoodsLotCost.CostInclVAT
	|		WHEN &ReportData = 2
	|			THEN ItemizeGoodsLotCost.CostExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsLotCost.CostExcludingVATMan
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsLotCost.CostExcludingVATLocal
	|		ELSE CASE
	|			WHEN &ByEnterprise
	|				THEN ItemizeGoodsLotCost.CostExcludingVAT
	|			ELSE ItemizeGoodsLotCost.CostExcludingVATMan
	|		END
	|	END) AS InitialMaterialCostsPerUnit,
	|	SUM(0) AS InitialArticleByArticleConstantsPerUnit,
	|	SUM(0) AS InitialArticleByArticleVariablesPerUnit,
	|	SUM(0) AS InitialAdditionalCostsPerUnit,
	|	SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsLotCost.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsLotCost.VATLocal
	|		ELSE 0
	|	END) AS InitialVATPerUnit,
	|	SUM(0) AS LotQuantity
	|INTO GranularityGrouped
	|FROM
	|	InformationRegister.ItemizeGoodsLotCost AS ItemizeGoodsLotCost
	|WHERE
	|	TRUE IN (SELECT  TOP 1 TRUE
	|				FROM Sales AS Sales
	|				WHERE
	|					ItemizeGoodsLotCost.Products = Sales.Products
	|					AND ItemizeGoodsLotCost.Characteristic = Sales.Characteristic 
	|					AND ItemizeGoodsLotCost.InventoryOwnerAttribute = Sales.InventoryOwnerAttribute 
	|					AND ItemizeGoodsLotCost.Organization = Sales.Organization
	|					AND ItemizeGoodsLotCost.Lot = Sales.Lot 
	|					AND ItemizeGoodsLotCost.LotVendorAttributes = Sales.LotVendorAttributes
	|				)
	|{WHERE
	|	ItemizeGoodsLotCost.Products.* AS Products,
	|	ItemizeGoodsLotCost.Characteristic.* AS Characteristic,
	|	ItemizeGoodsLotCost.Organization.* AS Organization,
	|	ItemizeGoodsLotCost.InventoryOwnerAttribute.* AS InventoryOwnerAttribute}
	|
	|GROUP BY
	|	ItemizeGoodsLotCost.Lot,
	|	ItemizeGoodsLotCost.LotVendorAttributes,
	|	ItemizeGoodsLotCost.Organization,
	|	ItemizeGoodsLotCost.InventoryOwnerAttribute,
	|	ItemizeGoodsLotCost.Products,
	|	ItemizeGoodsLotCost.Characteristic,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef),
	|	ItemizeGoodsLotCost.LotVendorAttributesOfReceiptDocument.AssetTaxClass,
	|	ItemizeGoodsLotCost.LotVendorAttributesOfReceiptDocument,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument.Products,
	|	ItemizeGoodsLotCost.InventoryLocationAttributesOfReceiptDocument.Characteristic,
	|	ItemizeGoodsLotCost.DocumentInflow
	|	
	|HAVING
	|	SUM(CASE
	|		WHEN &ReportData = 1
	|			THEN ItemizeGoodsLotCost.CostInclVAT
	|		WHEN &ReportData = 2
	|			THEN ItemizeGoodsLotCost.CostExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsLotCost.CostExcludingVATMan
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsLotCost.CostExcludingVATLocal
	|		ELSE CASE
	|			WHEN &ByEnterprise
	|				THEN ItemizeGoodsLotCost.CostExcludingVAT
	|			ELSE ItemizeGoodsLotCost.CostExcludingVATMan
	|		END
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsLotCost.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsLotCost.VATLocal
	|		ELSE
	|			0
	|	END) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	DATETIME(1,1,1) AS MonthPeriod,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	ItemizeLotCostItemizedAndOtherCosts.Lot AS PartyDetail,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributes AS AnalysisOfAccountingAndDetailing,
	|	ItemizeLotCostItemizedAndOtherCosts.Organization AS OrganizationDetail,
	|	ItemizeLotCostItemizedAndOtherCosts.InventoryOwnerAttribute AS TypeAndDetail,
	|	ItemizeLotCostItemizedAndOtherCosts.Products AS ProductDetailing,
	|	ItemizeLotCostItemizedAndOtherCosts.Characteristic AS CharacteristicDetail,
	|	CASE
	|		WHEN ItemizeLotCostItemizedAndOtherCosts.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE ItemizeLotCostItemizedAndOtherCosts.ExpenseItem
	|	END AS ExpenseItem,
	|	ItemizeLotCostItemizedAndOtherCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass AS AssetTaxClass,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	VALUE(Catalog.Products.EmptyRef) AS SourceProducts_,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS InitialCharacteristic,
	|	ItemizeLotCostItemizedAndOtherCosts.DocumentInflow AS DocumentInflow,
	|	SUM(0) AS InitialMaterialCostsPerUnit,
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|					ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|						FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialArticleByArticleConstantsPerUnit,
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialArticleByArticleVariablesPerUnit,
	|	SUM(CASE
	|		WHEN ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialAdditionalCostsPerUnit,
	|	SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeLotCostItemizedAndOtherCosts.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeLotCostItemizedAndOtherCosts.VATLocal
	|		ELSE 0
	|	END) AS InitialVATPerUnit,
	|	SUM(0) AS LotQuantity
	|FROM
	|	InformationRegister.ItemizeLotCostItemizedAndOtherCosts AS ItemizeLotCostItemizedAndOtherCosts
	|WHERE
	|	TRUE IN (SELECT  TOP 1 TRUE
	|				FROM Sales AS Sales
	|				WHERE
	|					ItemizeLotCostItemizedAndOtherCosts.Products = Sales.Products
	|					AND ItemizeLotCostItemizedAndOtherCosts.Characteristic = Sales.Characteristic 
	|					AND ItemizeLotCostItemizedAndOtherCosts.InventoryOwnerAttribute = Sales.InventoryOwnerAttribute 
	|					AND ItemizeLotCostItemizedAndOtherCosts.Organization = Sales.Organization
	|					AND ItemizeLotCostItemizedAndOtherCosts.Lot = Sales.Lot 
	|					AND ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributes = Sales.LotVendorAttributes
	|				)
	|{WHERE
	|	ItemizeLotCostItemizedAndOtherCosts.Products.* AS Products,
	|	ItemizeLotCostItemizedAndOtherCosts.Characteristic.* AS Characteristic,
	|	ItemizeLotCostItemizedAndOtherCosts.Organization.* AS Organization,
	|	ItemizeLotCostItemizedAndOtherCosts.InventoryOwnerAttribute.* AS InventoryOwnerAttribute}
	|GROUP BY
	|	ItemizeLotCostItemizedAndOtherCosts.Lot,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributes,
	|	ItemizeLotCostItemizedAndOtherCosts.Organization,
	|	ItemizeLotCostItemizedAndOtherCosts.InventoryOwnerAttribute,
	|	ItemizeLotCostItemizedAndOtherCosts.Products,
	|	ItemizeLotCostItemizedAndOtherCosts.Characteristic,
	|	CASE
	|		WHEN ItemizeLotCostItemizedAndOtherCosts.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE ItemizeLotCostItemizedAndOtherCosts.ExpenseItem
	|	END,
	|	ItemizeLotCostItemizedAndOtherCosts.DimensionOfExpenses,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass,
	|	ItemizeLotCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	ItemizeLotCostItemizedAndOtherCosts.DocumentInflow
	|	
	|HAVING
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|					ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|					OR
	|						FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(ItemizeLotCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeLotCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeLotCostItemizedAndOtherCosts.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeLotCostItemizedAndOtherCosts.VATLocal
	|		ELSE 0
	|	END) <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(ItemizeGoodsCostItemizedAndOtherCosts.Period, MONTH) AS MonthPeriod,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	ItemizeGoodsCostItemizedAndOtherCosts.Lot AS PartyDetail,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributes AS AnalysisOfAccountingAndDetailing,
	|	ItemizeGoodsCostItemizedAndOtherCosts.Organization AS OrganizationDetail,
	|	ItemizeGoodsCostItemizedAndOtherCosts.InventoryOwnerAttribute AS TypeAndDetail,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Products AS ProductDetailing,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Characteristic AS CharacteristicDetail,
	|	CASE
	|		WHEN ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem
	|	END AS ExpenseItem,
	|	ItemizeGoodsCostItemizedAndOtherCosts.DimensionOfExpenses AS DimensionOfExpenses,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass AS AssetTaxClass,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS InventoryLocationAttributesOfReceiptDocument,
	|	VALUE(Catalog.Products.EmptyRef) AS SourceProducts_,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS InitialCharacteristic,
	|	ItemizeGoodsCostItemizedAndOtherCosts.DocumentInflow AS DocumentInflow,
	|	SUM(0) AS InitialMaterialCostsPerUnit,
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialArticleByArticleConstantsPerUnit,
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialArticleByArticleVariablesPerUnit,
	|	SUM(CASE
	|		WHEN ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) AS InitialAdditionalCostsPerUnit,
	|	SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.VATLocal
	|		ELSE 0
	|	END) AS InitialVATPerUnit,
	|	SUM(ItemizeGoodsCostItemizedAndOtherCosts.LotQuantity)
	|FROM
	|	InformationRegister.ItemizeGoodsCostItemizedAndOtherCosts AS ItemizeGoodsCostItemizedAndOtherCosts
	|WHERE
	|	ItemizeGoodsCostItemizedAndOtherCosts.AccountingSection = VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	AND TRUE IN (SELECT  TOP 1 TRUE
	|				FROM Sales AS Sales
	|				WHERE
	|					ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Products = Sales.Products
	|					AND ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Characteristic = Sales.Characteristic 
	|					AND ItemizeGoodsCostItemizedAndOtherCosts.InventoryOwnerAttribute = Sales.InventoryOwnerAttribute 
	|					AND ItemizeGoodsCostItemizedAndOtherCosts.Organization = Sales.Organization
	|					AND ItemizeGoodsCostItemizedAndOtherCosts.Lot = Sales.Lot 
	|					AND ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributes = Sales.LotVendorAttributes
	|				)
	|{WHERE 
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Products.* AS Products,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Characteristic.* AS Characteristic,
	|	ItemizeGoodsCostItemizedAndOtherCosts.Organization.* AS Organization,
	|	ItemizeGoodsCostItemizedAndOtherCosts.InventoryOwnerAttribute.* AS InventoryOwnerAttribute
	|}
	|GROUP BY
	|	BEGINOFPERIOD(ItemizeGoodsCostItemizedAndOtherCosts.Period, MONTH),
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes,
	|	ItemizeGoodsCostItemizedAndOtherCosts.Lot,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributes,
	|	ItemizeGoodsCostItemizedAndOtherCosts.Organization,
	|	ItemizeGoodsCostItemizedAndOtherCosts.InventoryOwnerAttribute,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Products,
	|	ItemizeGoodsCostItemizedAndOtherCosts.ItemsLocationAttributes.Characteristic,
	|	CASE
	|		WHEN ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass
	|		ELSE ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem
	|	END,
	|	ItemizeGoodsCostItemizedAndOtherCosts.DimensionOfExpenses,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument.AssetTaxClass,
	|	ItemizeGoodsCostItemizedAndOtherCosts.LotVendorAttributesOfReceiptDocument,
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef),
	|	VALUE(Catalog.Products.EmptyRef),
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	ItemizeGoodsCostItemizedAndOtherCosts.DocumentInflow
	|	
	|HAVING
	|	SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Constant)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN (&ReportData = 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR &ReportData <> 4
	|				AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) <> VALUE(Enum.CostAllocationOptions.ToInventoryCost))
	|				AND (
	|				ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.ProductionCostType, VALUE(Enum.ProductionCostType.EmptyRef)) = VALUE(Enum.ProductionCostType.Variables1)
	|				OR
	|				FALSE)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)) = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				OR &ReportData = 4
	|					AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionLocal, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|				OR NOT &ReportData = 4
	|					AND ISNULL(ItemizeGoodsCostItemizedAndOtherCosts.ExpenseItem.CostAllocationOptionManag, VALUE(Enum.CostAllocationOptions.EmptyRef)) = VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN CASE
	|					WHEN &ReportData = 1
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostInclVAT
	|					WHEN &ReportData = 2
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVAT
	|					WHEN &ReportData = 3
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATMan
	|					WHEN &ReportData = 4
	|						THEN ItemizeGoodsCostItemizedAndOtherCosts.CostExcludingVATLocal
	|				END
	|		ELSE 0
	|	END) <> 0
	|	OR SUM(CASE
	|		WHEN &ReportData = 3
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.VATManag
	|		WHEN &ReportData = 4
	|			THEN ItemizeGoodsCostItemizedAndOtherCosts.VATLocal
	|		ELSE 0
	|	END) <> 0
	|
	|INDEX BY
	|	PartyDetail,
	|	AnalysisOfAccountingAndDetailing
	|;";

	#EndRegion


	#Region DataSet
	QueryText = QueryText + "
	|SELECT ALLOWED
	|	Sales.DataSet AS DataSet,
	|	(CASE
	|		WHEN Sales.Recorder = UNDEFINED 
	|			THEN NULL
	|		ELSE Sales.Recorder 
	|	END) AS Recorder,
	|	Sales.SecondPeriod AS SecondPeriod,
	|	Sales.DayPeriod AS DayPeriod,
	|	Sales.WeekPeriod AS WeekPeriod,
	|	Sales.TenDaysPeriod AS TenDaysPeriod,
	|	Sales.MonthPeriod AS MonthPeriod,
	|	Sales.QuarterPeriod AS QuarterPeriod,
	|	Sales.HalfYearPeriod AS HalfYearPeriod,
	|	Sales.YearPeriod AS YearPeriod,
	|	Sales.AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Sales.Products AS Products,
	|	Sales.StorageUnit AS StorageUnit,
	|	Sales.UnitForReports AS UnitForReports,
	|	Sales.UnitFactorForReports AS UnitFactorForReports,
	|	Sales.ProductsWeight AS ProductsWeight,
	|	Sales.ProductsVolume AS ProductsVolume,
	|	Sales.AnalyticalGroup AS AnalyticalGroup,
	|	Sales.Characteristic AS Characteristic,
	|	Sales.Series AS Series,
	|	Sales.Organization AS Organization,
	|	Sales.Seller AS Seller,
	|	Sales.Partner AS Partner,
	|	CASE
	|		WHEN Sales.SalesOrder = UNDEFINED
	|			THEN VALUE(Document.SalesOrder.EmptyRef)
	|		ELSE Sales.SalesOrder
	|	END AS SalesOrder,
	|	Sales.Department AS Department,
	|	Sales.Warehouse AS Warehouse,
	|	Sales.Counterparty AS Counterparty,
	|	Sales.Customer AS Customer,
	|	Sales.Vendor AS Vendor,
	|	Sales.Manager AS Manager,
	|	Sales.SalesOpportunity AS SalesOpportunity,
	|	Sales.OpportunityManager AS OpportunityManager,
	|	Sales.InventoryType AS InventoryType,
	|	Sales.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Sales.AccountingSection AS AccountingSection,
	|	Sales.Lot AS Lot,
	|	Sales.LotVendorAttributes AS LotVendorAttributes,
	|	Sales.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Sales.VATActivityType AS VATActivityType,
	|	Sales.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Sales.SalesOpportunityKind AS SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	Sales.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	Sales.Terms AS Terms,
	|	Sales.Contract AS Contract,
	|	Sales.SetAccountingDimension AS SetAccountingDimension,
	|	Sales.Currency AS Currency,
	|	Sales.BusinessOperation AS BusinessOperation,
	|	Sales.VATRate AS VATRate,
	|	Sales.Count AS Count,
	|	Sales.Revenue AS Revenue,
	|	Sales.VATRevenue AS VATRevenue,
	|	Sales.ManualDiscount AS ManualDiscount,
	|	Sales.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	Sales.TotalOfDiscounts AS TotalOfDiscounts,
	|	Sales.Cost_ AS Cost_,
	|	Sales.AddExpensesForGoods AS AddExpensesForGoods,
	|	Sales.ExciseTaxAmount AS ExciseTaxAmount,
	|	Sales.LaborCosts AS LaborCosts,
	|	Sales.ItemizedFixed AS ItemizedFixed,
	|	Sales.ItemizedVariable AS ItemizedVariable,
	|	Sales.SellingExpenses_ AS SellingExpenses_,
	|	Sales.ProvisionForImpairment AS ProvisionForImpairment,
	|	Sales.Cost_Preliminary AS Cost_Preliminary,
	|	Sales.CostDeviation_ AS CostDeviation_,
	|	Sales.GrossProfit AS GrossProfit,
	|	Sales.Profitability AS Profitability,
	|	Sales.IntercompanySales AS IntercompanySales,
	|	UNDEFINED AS PartyDetail,
	|
	|	NULL AS AnalysisOfAccountingAndDetailing,
	|	NULL AS OrganizationDetail,
	|	NULL AS TypeAndDetail,
	|	NULL AS ProductDetailing,
	|	NULL AS CharacteristicDetail,
	|	NULL AS ExpenseItem,
	|	NULL AS DimensionOfExpenses,
	|	VALUE(Enum.AssetKinds.EmptyRef) AS AssetTaxClass,
	|	NULL AS LotVendorAttributesOfReceiptDocument,
	|	NULL AS InventoryLocationAttributesOfReceiptDocument,
	|	NULL AS SourceProducts_,
	|	NULL AS InitialCharacteristic,
	|	NULL AS SourceReceiptDocument,
	|	0 AS InitialMaterialCosts,
	|	0 AS InitialArticleByArticleConstants,
	|	0 AS InitialArticleByArticleVariables,
	|	0 AS InitialAdditionalCosts,
	|	0 AS LotQuantity
	|
	|{SELECT
	|	Recorder,
	|	SecondPeriod,
	|	DayPeriod,
	|	WeekPeriod,
	|	TenDaysPeriod,
	|	MonthPeriod,
	|	QuarterPeriod,
	|	HalfYearPeriod,
	|	YearPeriod,
	|	AdjustmentPeriod_,
	|	ItemsLocationAttributes.*,
	|	Products.*,
	|	StorageUnit.*,
	|	UnitForReports.*,
	|	UnitFactorForReports,
	|	ProductsWeight,
	|	ProductsVolume,
	|	AnalyticalGroup.*,
	|	Characteristic.*,
	|	Series.*,
	|	Organization.*,
	|	Seller.*,
	|	Partner.*,
	|	SalesOrder.*,
	|	Department.*,
	|	Warehouse.*,
	|	Counterparty.*,
	|	Customer.*,
	|	Vendor.*,
	|	Manager.*,
	|	SalesOpportunity.*,
	|	OpportunityManager.*,
	|	InventoryType.*,
	|	InventoryOwnerAttribute.*,
	|	AccountingSection.*,
	|	Lot.*,
	|	LotVendorAttributes.*,
	|	FinancialAccountingDimension.*,
	|	VATActivityType.*,
	|	FinancialAccountingGroup.*,
	|	SalesOpportunityKind.*,
	|	CounterpartyLineOfBusiness.*,
	|	ProductLineOfBusiness.*,
	|	Terms.*,
	|	Contract.*,
	|	SetAccountingDimension.*,
	|	Currency.*,
	|	BusinessOperation.*,
	|	VATRate.*,
	|	Count,
	|	Revenue,
	|	VATRevenue,
	|	ManualDiscount,
	|	DiscountMarkupAmount,
	|	TotalOfDiscounts,
	|	Cost_,
	|	AddExpensesForGoods,
	|	ExciseTaxAmount,
	|	LaborCosts,
	|	ItemizedFixed,
	|	ItemizedVariable,
	|	SellingExpenses_,
	|	ProvisionForImpairment,
	|	Cost_Preliminary,
	|	CostDeviation_,
	|	GrossProfit,
	|	Profitability,
	|	IntercompanySales,
	|	PartyDetail.*,
	|	AnalysisOfAccountingAndDetailing.*,
	|	OrganizationDetail.*,
	|	TypeAndDetail.*,
	|	ProductDetailing.*,
	|	CharacteristicDetail.*,
	|	ExpenseItem.*,
	|	DimensionOfExpenses.*,
	|	AssetTaxClass.*,
	|	LotVendorAttributesOfReceiptDocument.*,
	|	InventoryLocationAttributesOfReceiptDocument.*,
	|	SourceProducts_.*,
	|	InitialCharacteristic.*,
	|	SourceReceiptDocument.*,
	|	InitialMaterialCosts,
	|	InitialArticleByArticleConstants,
	|	InitialArticleByArticleVariables,
	|	InitialAdditionalCosts,
	|	LotQuantity}
	|FROM
	|	Sales AS Sales
	|{WHERE
	|	Sales.Recorder,
	|	Sales.SecondPeriod,
	|	Sales.DayPeriod,
	|	Sales.WeekPeriod,
	|	Sales.TenDaysPeriod,
	|	Sales.MonthPeriod,
	|	Sales.QuarterPeriod,
	|	Sales.HalfYearPeriod,
	|	Sales.YearPeriod,
	|	Sales.AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes.*,
	|	Sales.Products.*,
	|	Sales.StorageUnit.*,
	|	Sales.UnitForReports.*,
	|	Sales.UnitFactorForReports,
	|	Sales.ProductsWeight,
	|	Sales.ProductsVolume,
	|	Sales.AnalyticalGroup.*,
	|	Sales.Characteristic.*,
	|	Sales.Series.*,
	|	Sales.Organization.*,
	|	Sales.Seller.*,
	|	Sales.Partner.*,
	|	Sales.SalesOrder.*,
	|	Sales.Department.*,
	|	Sales.Warehouse.*,
	|	Sales.Counterparty.*,
	|	Sales.Customer.*,
	|	Sales.Vendor.*,
	|	Sales.Manager.*,
	|	Sales.SalesOpportunity.*,
	|	Sales.OpportunityManager.*,
	|	Sales.InventoryType.*,
	|	Sales.InventoryOwnerAttribute.*,
	|	Sales.AccountingSection.*,
	|	Sales.Lot.*,
	|	Sales.LotVendorAttributes.*,
	|	Sales.FinancialAccountingDimension.*,
	|	Sales.VATActivityType.*,
	|	Sales.FinancialAccountingGroup.*,
	|	Sales.SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness.*,
	|	Sales.ProductLineOfBusiness.*,
	|	Sales.Terms.*,
	|	Sales.Contract.*,
	|	Sales.SetAccountingDimension.*,
	|	Sales.Currency.*,
	|	Sales.BusinessOperation.*,
	|	Sales.VATRate.*,
	|	Sales.Count,
	|	Sales.Revenue,
	|	Sales.VATRevenue,
	|	Sales.ManualDiscount,
	|	Sales.DiscountMarkupAmount,
	|	Sales.TotalOfDiscounts,
	|	Sales.Cost_,
	|	Sales.AddExpensesForGoods,
	|	Sales.ExciseTaxAmount,
	|	Sales.LaborCosts,
	|	Sales.ItemizedFixed,
	|	Sales.ItemizedVariable,
	|	Sales.SellingExpenses_,
	|	Sales.ProvisionForImpairment,
	|	Sales.Cost_Preliminary,
	|	Sales.CostDeviation_,
	|	Sales.GrossProfit,
	|	Sales.Profitability,
	|	Sales.IntercompanySales
	|	}
	|
	|UNION ALL
	|
	// Additional sales expenses in the reporting period.
	|SELECT
	|	Sales.DataSet + 2 AS DataSet,
	|	(CASE
	|		WHEN Sales.Recorder = UNDEFINED 
	|			THEN NULL
	|		ELSE Sales.Recorder 
	|	END) AS Recorder,
	|	Sales.SecondPeriod AS SecondPeriod,
	|	Sales.DayPeriod AS DayPeriod,
	|	Sales.WeekPeriod AS WeekPeriod,
	|	Sales.TenDaysPeriod AS TenDaysPeriod,
	|	Sales.MonthPeriod AS MonthPeriod,
	|	Sales.QuarterPeriod AS QuarterPeriod,
	|	Sales.HalfYearPeriod AS HalfYearPeriod,
	|	Sales.YearPeriod AS YearPeriod,
	|	Sales.AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Sales.Products AS Products,
	|	Sales.StorageUnit AS StorageUnit,
	|	Sales.UnitForReports AS UnitForReports,
	|	Sales.UnitFactorForReports AS UnitFactorForReports,
	|	Sales.ProductsWeight AS ProductsWeight,
	|	Sales.ProductsVolume AS ProductsVolume,
	|	Sales.AnalyticalGroup AS AnalyticalGroup,
	|	Sales.Characteristic AS Characteristic,
	|	Sales.Series AS Series,
	|	Sales.Organization AS Organization,
	|	Sales.Seller AS Seller,
	|	Sales.Partner AS Partner,
	|	CASE
	|		WHEN Sales.SalesOrder = UNDEFINED
	|			THEN VALUE(Document.SalesOrder.EmptyRef)
	|		ELSE Sales.SalesOrder
	|	END AS SalesOrder,
	|	Sales.Department AS Department,
	|	Sales.Warehouse AS Warehouse,
	|	Sales.Counterparty AS Counterparty,
	|	Sales.Customer AS Customer,
	|	Sales.Vendor AS Vendor,
	|	Sales.Manager AS Manager,
	|	Sales.SalesOpportunity AS SalesOpportunity,
	|	Sales.OpportunityManager AS OpportunityManager,
	|	Sales.InventoryType AS InventoryType,
	|	Sales.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Sales.AccountingSection AS AccountingSection,
	|	Sales.Lot AS Lot,
	|	Sales.LotVendorAttributes AS LotVendorAttributes,
	|	Sales.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Sales.VATActivityType AS VATActivityType,
	|	Sales.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Sales.SalesOpportunityKind AS SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	Sales.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	Sales.Terms AS Terms,
	|	Sales.Contract AS Contract,
	|	Sales.SetAccountingDimension AS SetAccountingDimension,
	|	Sales.Currency AS Currency,
	|	Sales.BusinessOperation AS BusinessOperation,
	|	Sales.VATRate AS VATRate,
	|	0 AS Count,
	|	0 AS Revenue,
	|	0 AS VATRevenue,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	0 AS TotalOfDiscounts,
	|	0 AS Cost_,
	|	0 AS AddExpensesForGoods,
	|	0 AS ExciseTaxAmount,
	|	0 AS LaborCosts,
	|	0 AS ItemizedFixed,
	|	0 AS ItemizedVariable,
	|	0 AS SellingExpenses_,
	|	0 AS ProvisionForImpairment,
	|	0 AS Cost_Preliminary,
	|	0 AS CostDeviation_,
	|	0 AS GrossProfit,
	|	0 AS Profitability,
	|	0 AS IntercompanySales,
	|	GranularityGrouped.PartyDetail AS PartyDetail,
	|	GranularityGrouped.AnalysisOfAccountingAndDetailing AS AnalysisOfAccountingAndDetailing,
	|	GranularityGrouped.OrganizationDetail AS OrganizationDetail,
	|	GranularityGrouped.TypeAndDetail AS TypeAndDetail,
	|	GranularityGrouped.ProductDetailing AS ProductDetailing,
	|	GranularityGrouped.CharacteristicDetail AS CharacteristicDetail,
	|	GranularityGrouped.ExpenseItem AS ExpenseItem,
	|	GranularityGrouped.DimensionOfExpenses AS DimensionOfExpenses,
	|	GranularityGrouped.AssetTaxClass AS AssetTaxClass,
	|	GranularityGrouped.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	GranularityGrouped.InventoryLocationAttributesOfReceiptDocument AS InventoryLocationAttributesOfReceiptDocument,
	|	GranularityGrouped.SourceProducts_ AS SourceProducts_,
	|	GranularityGrouped.InitialCharacteristic AS InitialCharacteristic,
	|	GranularityGrouped.SourceReceiptDocument AS SourceReceiptDocument,
	|	Sales.Count * (GranularityGrouped.InitialMaterialCostsPerUnit
	|		+ (CASE WHEN Sales.VATIsIncludedInCost
	|			THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|		) AS InitialMaterialCosts,
	|	Sales.Count * GranularityGrouped.InitialArticleByArticleConstantsPerUnit AS InitialArticleByArticleConstants,
	|	Sales.Count * GranularityGrouped.InitialArticleByArticleVariablesPerUnit AS InitialArticleByArticleVariables,
	|	Sales.Count * GranularityGrouped.InitialAdditionalCostsPerUnit AS InitialAdditionalCosts,
	|	GranularityGrouped.LotQuantity AS LotQuantity
	|FROM
	|	Sales AS Sales
	// In the detail table, the grouped empty PeriodMonth field defines the detail generated in the month
	// when the batch of goods was reflected. Such detailing is used to decipher the sales of a batch of goods. 
	// In the register "Revenue and cost of sales" such movements are reflected with an indication of the quantity.
	// In the detail table, the grouped filled-in Period-Month field determines the details of additional expenses and cost adjustments
	// reflected in the following periods. Such additional expenses and adjustments may be included in the cost of sales
	// in the period of distribution of additional expenses, and may also relate to sales of the previous period.
	|	INNER JOIN GranularityGrouped AS GranularityGrouped
	|	ON Sales.Products = GranularityGrouped.ProductDetailing
	|		AND Sales.Characteristic = GranularityGrouped.CharacteristicDetail
	|		AND Sales.InventoryOwnerAttribute = GranularityGrouped.TypeAndDetail
	|		AND Sales.Organization = GranularityGrouped.OrganizationDetail
	|		AND Sales.Lot = GranularityGrouped.PartyDetail
	|		AND Sales.LotVendorAttributes = GranularityGrouped.AnalysisOfAccountingAndDetailing
	|		AND (CASE
	|			WHEN GranularityGrouped.MonthPeriod = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE Sales.MonthPeriod = GranularityGrouped.MonthPeriod
	|		END)
	|		AND (CASE
	|			WHEN GranularityGrouped.ItemsLocationAttributes = UNDEFINED
	|				THEN TRUE
	|			ELSE Sales.ItemsLocationAttributes = GranularityGrouped.ItemsLocationAttributes
	|		END)
	|		AND NOT Sales.NoCostDetailingIsRequired
	|WHERE
	|	Sales.Count <> 0
	|{WHERE
	|	Sales.Recorder,
	|	Sales.SecondPeriod,
	|	Sales.DayPeriod,
	|	Sales.WeekPeriod,
	|	Sales.TenDaysPeriod,
	|	Sales.MonthPeriod,
	|	Sales.QuarterPeriod,
	|	Sales.HalfYearPeriod,
	|	Sales.YearPeriod,
	|	Sales.AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes.*,
	|	Sales.Products.*,
	|	Sales.StorageUnit.*,
	|	Sales.UnitForReports.*,
	|	Sales.UnitFactorForReports,
	|	Sales.ProductsWeight,
	|	Sales.ProductsVolume,
	|	Sales.AnalyticalGroup.*,
	|	Sales.Characteristic.*,
	|	Sales.Series.*,
	|	Sales.Organization.*,
	|	Sales.Seller.*,
	|	Sales.Partner.*,
	|	Sales.SalesOrder.*,
	|	Sales.Department.*,
	|	Sales.Warehouse.*,
	|	Sales.Counterparty.*,
	|	Sales.Customer.*,
	|	Sales.Vendor.*,
	|	Sales.Manager.*,
	|	Sales.InventoryType.*,
	|	Sales.InventoryOwnerAttribute.*,
	|	Sales.AccountingSection.*,
	|	Sales.Lot.*,
	|	Sales.LotVendorAttributes.*,
	|	Sales.FinancialAccountingDimension.*,
	|	Sales.VATActivityType.*,
	|	Sales.FinancialAccountingGroup.*,
	|	Sales.SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness.*,
	|	Sales.ProductLineOfBusiness.*,
	|	Sales.Terms.*,
	|	Sales.Contract.*,
	|	Sales.SetAccountingDimension.*,
	|	Sales.Currency.*,
	|	Sales.BusinessOperation.*,
	|	Sales.VATRate.*,
	|	Sales.Count,
	|	Sales.Revenue,
	|	Sales.VATRevenue,
	|	Sales.ManualDiscount,
	|	Sales.DiscountMarkupAmount,
	|	Sales.TotalOfDiscounts,
	|	Sales.Cost_,
	|	Sales.AddExpensesForGoods,
	|	Sales.ExciseTaxAmount,
	|	Sales.LaborCosts,
	|	Sales.ItemizedFixed,
	|	Sales.ItemizedVariable,
	|	Sales.SellingExpenses_,
	|	Sales.ProvisionForImpairment,
	|	Sales.Cost_Preliminary,
	|	Sales.CostDeviation_,
	|	Sales.GrossProfit,
	|	Sales.Profitability,
	|	Sales.IntercompanySales,
	|	(ISNULL(GranularityGrouped.PartyDetail, UNDEFINED)).* AS PartyDetail,
	|	(ISNULL(GranularityGrouped.AnalysisOfAccountingAndDetailing, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))).* AS AnalysisOfAccountingAndDetailing,
	|	(ISNULL(GranularityGrouped.OrganizationDetail, VALUE(Catalog.Companies.EmptyRef))).* AS OrganizationDetail,
	|	(ISNULL(GranularityGrouped.TypeAndDetail, VALUE(Catalog.InventoryKinds.EmptyRef))).* AS TypeAndDetail,
	|	(ISNULL(GranularityGrouped.ProductDetailing, VALUE(Catalog.Products.EmptyRef))).* AS ProductDetailing,
	|	(ISNULL(GranularityGrouped.CharacteristicDetail, VALUE(Catalog.ItemsCharacteristics.EmptyRef))).* AS CharacteristicDetail,
	|	(ISNULL(GranularityGrouped.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))).* AS ExpenseItem,
	|	(ISNULL(GranularityGrouped.DimensionOfExpenses, UNDEFINED)).* AS DimensionOfExpenses,
	|	(ISNULL(GranularityGrouped.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))).* AS AssetTaxClass,
	|	(ISNULL(GranularityGrouped.LotVendorAttributesOfReceiptDocument, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))).* AS LotVendorAttributesOfReceiptDocument,
	|	(ISNULL(GranularityGrouped.InventoryLocationAttributesOfReceiptDocument, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))).* AS InventoryLocationAttributesOfReceiptDocument,
	|	(ISNULL(GranularityGrouped.SourceProducts_, VALUE(Catalog.Products.EmptyRef))).* AS SourceProducts_,
	|	(ISNULL(GranularityGrouped.InitialCharacteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))).* AS InitialCharacteristic,
	|	(ISNULL(GranularityGrouped.SourceReceiptDocument, UNDEFINED)).* AS SourceReceiptDocument
	|}
	|
	|UNION ALL
	|
	// Additional sales expenses of the previous period.
	|SELECT
	|	Sales.DataSet + 3 AS DataSet,
	|	(CASE
	|		WHEN Sales.Recorder = UNDEFINED 
	|			THEN NULL
	|		ELSE Sales.Recorder 
	|	END) AS Recorder,
	|	Sales.SecondPeriod AS SecondPeriod,
	|	Sales.DayPeriod AS DayPeriod,
	|	Sales.WeekPeriod AS WeekPeriod,
	|	Sales.TenDaysPeriod AS TenDaysPeriod,
	|	Sales.MonthPeriod AS MonthPeriod,
	|	Sales.QuarterPeriod AS QuarterPeriod,
	|	Sales.HalfYearPeriod AS HalfYearPeriod,
	|	Sales.YearPeriod AS YearPeriod,
	|	Sales.AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Sales.Products AS Products,
	|	Sales.StorageUnit AS StorageUnit,
	|	Sales.UnitForReports AS UnitForReports,
	|	Sales.UnitFactorForReports AS UnitFactorForReports,
	|	Sales.ProductsWeight AS ProductsWeight,
	|	Sales.ProductsVolume AS ProductsVolume,
	|	Sales.AnalyticalGroup AS AnalyticalGroup,
	|	Sales.Characteristic AS Characteristic,
	|	Sales.Series AS Series,
	|	Sales.Organization AS Organization,
	|	Sales.Seller AS Seller,
	|	Sales.Partner AS Partner,
	|	CASE
	|		WHEN Sales.SalesOrder = UNDEFINED
	|			THEN VALUE(Document.SalesOrder.EmptyRef)
	|		ELSE Sales.SalesOrder
	|	END AS SalesOrder,
	|	Sales.Department AS Department,
	|	Sales.Warehouse AS Warehouse,
	|	Sales.Counterparty AS Counterparty,
	|	Sales.Customer AS Customer,
	|	Sales.Vendor AS Vendor,
	|	Sales.Manager AS Manager,
	|	Sales.SalesOpportunity AS SalesOpportunity,
	|	Sales.OpportunityManager AS OpportunityManager,
	|	Sales.InventoryType AS InventoryType,
	|	Sales.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Sales.AccountingSection AS AccountingSection,
	|	Sales.Lot AS Lot,
	|	Sales.LotVendorAttributes AS LotVendorAttributes,
	|	Sales.FinancialAccountingDimension AS FinancialAccountingDimension,
	|	Sales.VATActivityType AS VATActivityType,
	|	Sales.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Sales.SalesOpportunityKind AS SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness AS CounterpartyLineOfBusiness,
	|	Sales.ProductLineOfBusiness AS ProductLineOfBusiness,
	|	Sales.Terms AS Terms,
	|	Sales.Contract AS Contract,
	|	Sales.SetAccountingDimension AS SetAccountingDimension,
	|	Sales.Currency AS Currency,
	|	Sales.BusinessOperation AS BusinessOperation,
	|	Sales.VATRate AS VATRate,
	|	0 AS Count,
	|	0 AS Revenue,
	|	0 AS VATRevenue,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	0 AS TotalOfDiscounts,
	|	0 AS Cost_,
	|	0 AS AddExpensesForGoods,
	|	0 AS ExciseTaxAmount,
	|	0 AS LaborCosts,
	|	0 AS ItemizedFixed,
	|	0 AS ItemizedVariable,
	|	0 AS SellingExpenses_,
	|	0 AS ProvisionForImpairment,
	|	0 AS Cost_Preliminary,
	|	0 AS CostDeviation_,
	|	0 AS GrossProfit,
	|	0 AS Profitability,
	|	0 AS IntercompanySales,
	|	GranularityGrouped.PartyDetail AS PartyDetail,
	|	GranularityGrouped.AnalysisOfAccountingAndDetailing AS AnalysisOfAccountingAndDetailing,
	|	GranularityGrouped.OrganizationDetail AS OrganizationDetail,
	|	GranularityGrouped.TypeAndDetail AS TypeAndDetail,
	|	GranularityGrouped.ProductDetailing AS ProductDetailing,
	|	GranularityGrouped.CharacteristicDetail AS CharacteristicDetail,
	|	GranularityGrouped.ExpenseItem AS ExpenseItem,
	|	GranularityGrouped.DimensionOfExpenses AS DimensionOfExpenses,
	|	GranularityGrouped.AssetTaxClass AS AssetTaxClass,
	|	GranularityGrouped.LotVendorAttributesOfReceiptDocument AS LotVendorAttributesOfReceiptDocument,
	|	GranularityGrouped.InventoryLocationAttributesOfReceiptDocument AS InventoryLocationAttributesOfReceiptDocument,
	|	GranularityGrouped.SourceProducts_ AS SourceProducts_,
	|	GranularityGrouped.InitialCharacteristic AS InitialCharacteristic,
	|	GranularityGrouped.SourceReceiptDocument AS SourceReceiptDocument,
	|	InitialSales.Count * (GranularityGrouped.InitialMaterialCostsPerUnit
	|		+ (CASE WHEN Sales.VATIsIncludedInCost
	|			THEN GranularityGrouped.InitialVATPerUnit ELSE 0 END)
	|		) AS InitialMaterialCosts,
	|	InitialSales.Count * GranularityGrouped.InitialArticleByArticleConstantsPerUnit AS InitialArticleByArticleConstants,
	|	InitialSales.Count * GranularityGrouped.InitialArticleByArticleVariablesPerUnit AS InitialArticleByArticleVariables,
	|	InitialSales.Count * GranularityGrouped.InitialAdditionalCostsPerUnit AS InitialAdditionalCosts,
	|	GranularityGrouped.LotQuantity AS LotQuantity
	|FROM
	|	Sales AS Sales
	// The table of initial expenses is used to determine the total quantity of goods sold to detail
	// the amounts of distribution of additional expenses and the amounts of cost adjustments for the disposal of goods in past periods.
	// In the register "Revenue and cost of goods" such movements are reflected with zero quantity. 
	|	INNER JOIN InitialSales AS InitialSales
	|		ON Sales.ItemsLocationAttributes = InitialSales.ItemsLocationAttributes
	|		AND Sales.SalesOrder = InitialSales.SalesOrder
	|		AND Sales.AccountingDimensionByPartners = InitialSales.AccountingDimensionByPartners
	|		AND Sales.Department = InitialSales.Department
	|		AND Sales.Manager = InitialSales.Manager
	|		AND Sales.Terms = InitialSales.Terms
	|		AND Sales.Contract = InitialSales.Contract
	|		AND Sales.InventoryOwnerAttribute = InitialSales.InventoryOwnerAttribute
	|		AND Sales.AccountingSection = InitialSales.AccountingSection
	|		AND Sales.Lot = InitialSales.Lot
	|		AND Sales.LotVendorAttributes = InitialSales.LotVendorAttributes
	|		AND Sales.FinancialAccountingDimension = InitialSales.FinancialAccountingDimension
	|		AND Sales.VATActivityType = InitialSales.VATActivityType
	|		AND Sales.Count = 0
	// In the detail table, the grouped filled-in Period-Month field determines the details of additional expenses and cost adjustments
	// reflected in the following periods. Such additional expenses and adjustments may be included in the cost of sales
	// in the period of distribution of additional expenses, and may also relate to sales of the previous period.
	|	INNER JOIN GranularityGrouped AS GranularityGrouped
	|	ON Sales.Products = GranularityGrouped.ProductDetailing
	|		AND Sales.Characteristic = GranularityGrouped.CharacteristicDetail
	|		AND Sales.InventoryOwnerAttribute = GranularityGrouped.TypeAndDetail
	|		AND Sales.Organization = GranularityGrouped.OrganizationDetail
	|		AND Sales.Lot = GranularityGrouped.PartyDetail
	|		AND Sales.LotVendorAttributes = GranularityGrouped.AnalysisOfAccountingAndDetailing
	|		AND Sales.MonthPeriod = GranularityGrouped.MonthPeriod
	|		AND (CASE
	|			WHEN GranularityGrouped.ItemsLocationAttributes = UNDEFINED
	|				THEN TRUE
	|			ELSE Sales.ItemsLocationAttributes = GranularityGrouped.ItemsLocationAttributes
	|		END)
	|		AND NOT Sales.NoCostDetailingIsRequired
	|{WHERE
	|	Sales.Recorder,
	|	Sales.SecondPeriod,
	|	Sales.DayPeriod,
	|	Sales.WeekPeriod,
	|	Sales.TenDaysPeriod,
	|	Sales.MonthPeriod,
	|	Sales.QuarterPeriod,
	|	Sales.HalfYearPeriod,
	|	Sales.YearPeriod,
	|	Sales.AdjustmentPeriod_,
	|	Sales.ItemsLocationAttributes.*,
	|	Sales.Products.*,
	|	Sales.StorageUnit.*,
	|	Sales.UnitForReports.*,
	|	Sales.UnitFactorForReports,
	|	Sales.ProductsWeight,
	|	Sales.ProductsVolume,
	|	Sales.AnalyticalGroup.*,
	|	Sales.Characteristic.*,
	|	Sales.Series.*,
	|	Sales.Organization.*,
	|	Sales.Seller.*,
	|	Sales.Partner.*,
	|	Sales.SalesOrder.*,
	|	Sales.Department.*,
	|	Sales.Warehouse.*,
	|	Sales.Counterparty.*,
	|	Sales.Customer.*,
	|	Sales.Vendor.*,
	|	Sales.Manager.*,
	|	Sales.InventoryType.*,
	|	Sales.InventoryOwnerAttribute.*,
	|	Sales.AccountingSection.*,
	|	Sales.Lot.*,
	|	Sales.LotVendorAttributes.*,
	|	Sales.FinancialAccountingDimension.*,
	|	Sales.VATActivityType.*,
	|	Sales.FinancialAccountingGroup.*,
	|	Sales.SalesOpportunityKind,
	|	Sales.CounterpartyLineOfBusiness.*,
	|	Sales.ProductLineOfBusiness.*,
	|	Sales.Terms.*,
	|	Sales.Contract.*,
	|	Sales.SetAccountingDimension.*,
	|	Sales.Currency.*,
	|	Sales.BusinessOperation.*,
	|	Sales.VATRate.*,
	|	Sales.Count,
	|	Sales.Revenue,
	|	Sales.VATRevenue,
	|	Sales.ManualDiscount,
	|	Sales.DiscountMarkupAmount,
	|	Sales.TotalOfDiscounts,
	|	Sales.Cost_,
	|	Sales.AddExpensesForGoods,
	|	Sales.ExciseTaxAmount,
	|	Sales.LaborCosts,
	|	Sales.ItemizedFixed,
	|	Sales.ItemizedVariable,
	|	Sales.SellingExpenses_,
	|	Sales.ProvisionForImpairment,
	|	Sales.Cost_Preliminary,
	|	Sales.CostDeviation_,
	|	Sales.GrossProfit,
	|	Sales.Profitability,
	|	Sales.IntercompanySales,
	|	(ISNULL(GranularityGrouped.PartyDetail, UNDEFINED)).* AS PartyDetail,
	|	(ISNULL(GranularityGrouped.AnalysisOfAccountingAndDetailing, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))).* AS AnalysisOfAccountingAndDetailing,
	|	(ISNULL(GranularityGrouped.OrganizationDetail, VALUE(Catalog.Companies.EmptyRef))).* AS OrganizationDetail,
	|	(ISNULL(GranularityGrouped.TypeAndDetail, VALUE(Catalog.InventoryKinds.EmptyRef))).* AS TypeAndDetail,
	|	(ISNULL(GranularityGrouped.ProductDetailing, VALUE(Catalog.Products.EmptyRef))).* AS ProductDetailing,
	|	(ISNULL(GranularityGrouped.CharacteristicDetail, VALUE(Catalog.ItemsCharacteristics.EmptyRef))).* AS CharacteristicDetail,
	|	(ISNULL(GranularityGrouped.ExpenseItem, VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef))).* AS ExpenseItem,
	|	(ISNULL(GranularityGrouped.DimensionOfExpenses, UNDEFINED)).* AS DimensionOfExpenses,
	|	(ISNULL(GranularityGrouped.AssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef))).* AS AssetTaxClass,
	|	(ISNULL(GranularityGrouped.LotVendorAttributesOfReceiptDocument, VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef))).* AS LotVendorAttributesOfReceiptDocument,
	|	(ISNULL(GranularityGrouped.InventoryLocationAttributesOfReceiptDocument, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))).* AS InventoryLocationAttributesOfReceiptDocument,
	|	(ISNULL(GranularityGrouped.SourceProducts_, VALUE(Catalog.Products.EmptyRef))).* AS SourceProducts_,
	|	(ISNULL(GranularityGrouped.InitialCharacteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))).* AS InitialCharacteristic,
	|	(ISNULL(GranularityGrouped.SourceReceiptDocument, UNDEFINED)).* AS SourceReceiptDocument
	|}
	|
	|";
	
	#EndRegion
	
	Return QueryText;
	
EndFunction

Procedure SetFieldUsageLimit(FieldName, Restrict = True)
	
	For Each Current_Set In DataCompositionSchema.DataSets Do
		
		CurrentField = Current_Set.Fields.Find(FieldName);
		
		If CurrentField <> Undefined Then
			
			CurrentField.UseRestriction.Group = Restrict;
			CurrentField.UseRestriction.Field = Restrict;
			CurrentField.UseRestriction.Order = Restrict;
			CurrentField.UseRestriction.Condition = Restrict;
			
			CurrentField.AttributeUseRestriction.Group = Restrict;
			CurrentField.AttributeUseRestriction.Field = Restrict;
			CurrentField.AttributeUseRestriction.Order = Restrict;
			CurrentField.AttributeUseRestriction.Condition = Restrict;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function UnusedReportFields()
	
	FieldArray = New Array;


	FieldArray.Add("ProductCostElementArticle");
	FieldArray.Add("InitialCostOfProduction");
	
	Return FieldArray;
	
EndFunction

#EndRegion

#EndIf