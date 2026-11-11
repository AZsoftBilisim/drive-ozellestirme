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
	Settings.Events.BeforeImportSettingsToComposer = True;
	
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
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = DataCompositionSchema.DataSets.CostOfBatches.Query;
	CalculationOfCostLocalization.StatementOnLotsOfGoods_AddRequestText(QueryText);
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight("DimensionOfProductItem.Products.UnitOfMeasure", "DimensionOfProductItem.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextVolumeM3", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume("DimensionOfProductItem.Products.UnitOfMeasure", "DimensionOfProductItem.Products"));
	
	DataCompositionSchema.DataSets.CostOfBatches.Query = QueryText;
	
	// Separation of data by periods of PU 2.1 and PU 2.2
	DateOfMigrationToBatchAccounting22 = CalculationOfCostCached.DateOfMigrationToBatchAccounting22();
	UseBullets = CalculationOfCostCached.BatchAccountingVersion22();
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Period");
	Period = ReportPeriodParameter.Value; // StandardPeriod -
	If ReportPeriodParameter.Use
		And Not (Period.StartDate = '00010101'
			And Period.EndDate = '00010101') Then
		
		StartDate = Period.StartDate;
		EndDate = Period.EndDate;
		
		If UseBullets 
		 And (StartDate >= DateOfMigrationToBatchAccounting22 Or EndDate >= DateOfMigrationToBatchAccounting22) Then
			ReportSettings.DataParameters.SetParameterValue("BeginOfPeriod22", Max(StartDate, DateOfMigrationToBatchAccounting22));
			ReportSettings.DataParameters.SetParameterValue("BulletData", UseBullets);
		ElsIf UseBullets And EndDate <= DateOfMigrationToBatchAccounting22 Then
			ReportSettings.DataParameters.SetParameterValue("BeginOfPeriod22", StartDate);
			ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", True);
			ReportSettings.DataParameters.SetParameterValue("BulletData", False);
		Else
			ReportSettings.DataParameters.SetParameterValue("BeginOfPeriod22", StartDate);
			ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", Not UseBullets);
			ReportSettings.DataParameters.SetParameterValue("BulletData", UseBullets);
		EndIf;
		
		If UseBullets And StartDate < DateOfMigrationToBatchAccounting22 Then
			ReportSettings.DataParameters.SetParameterValue("EndOfPeriod21", Min(EndDate, DateOfMigrationToBatchAccounting22 - 1));
			ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", True);
		ElsIf Not UseBullets Then
			If ValueIsFilled(EndDate) Then
				ReportSettings.DataParameters.SetParameterValue("EndOfPeriod21", EndDate);
			EndIf;
			ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", True);
		Else
			ReportSettings.DataParameters.SetParameterValue("EndOfPeriod21", EndDate);
			ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", False);
		EndIf;
		
	Else
		If UseBullets Then
			ReportSettings.DataParameters.SetParameterValue("EndOfPeriod21", DateOfMigrationToBatchAccounting22 - 1);
		Else
			ReportSettings.DataParameters.SetParameterValue("EndOfPeriod21", Date(1,1,1));
		EndIf;
		ReportSettings.DataParameters.SetParameterValue("BeginOfPeriod22", DateOfMigrationToBatchAccounting22);
		ReportSettings.DataParameters.SetParameterValue("DataofBatchAccounting21", True);
		ReportSettings.DataParameters.SetParameterValue("BulletData", UseBullets);
	EndIf;
	
	ExcludedBusinessTransactions = CostCalculationAppliedAlgorithms.EconomicOperationsOfMovements();
	ReportSettings.DataParameters.SetParameterValue("ExcludedBusinessTransactions", ExcludedBusinessTransactions);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	CostCalculationAppliedAlgorithms.UpdateBatchesForReports(ResultDocument, SettingsComposer);
	CostCalculationAppliedAlgorithms.AddWarningAboutPreClosingMonth(ResultDocument, SettingsComposer);
	
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified.
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert(
		"ReportIsBlank",
		ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor));
	
EndProcedure

#EndRegion

#Region Private
	
Procedure SetRequiredSettings(UserSettingsModified)
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

Function StructureOfFieldHeaders()
	StructureOfFieldHeaders = New Structure;
	
	StructureOfUnitFieldHeaders_ = DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	CommonClientServer.SupplementStructure(StructureOfFieldHeaders, StructureOfUnitFieldHeaders_, False);
	
	Return StructureOfFieldHeaders;
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	If Not GetFunctionalOption("UseGoodsTransfer") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "ExcludeBusinessTransactions");
	EndIf;
	
EndProcedure

// Procedure for configuring report parameters.
//
// Parameters:
//	ReportSettings - Structure - report settings
//	NewDCSettings - DataCompositionSettings - customize the layout data
//	NewDCUserSettings - DataCompositionUserSettings - custom setting 
//
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("ReportData");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "EnterpriseBatchList" Then
		
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
		
	Else
		
		If CalculationOfCostCached.CompanyManagementAccounting() Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		ChoiceList.Add(4, NStr("vi = 'Theo tiền tệ kế toán pháp quy';
								|ru = 'В валюте регл. учета';
								|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
								|it = 'In valuta della contabilità regolamentata';
								|pl = 'W walucie ewidencji reglamentowanej';
								|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EnterpriseParameter.Value = False;
		
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
	
	// If the option is not specified, then take the list of the parties of the goods of the enterprise
	If Variant = Undefined Then
		Return New Structure("VariantKey", "EnterpriseBatchList");
	EndIf;
	
	While Not Variant.VariantKey = "EnterpriseBatchList"
		And Not Variant.VariantKey = "CompanyBatchList"
		And ValueIsFilled(Variant.Parent) Do
		Variant = Variant.Parent;
	EndDo;
	
	Return Variant;
	
EndFunction

#EndRegion

#EndIf
