#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnDefineSelectionParameters = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the report form before displaying the settings.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   SettingProperties - Structure - Description of the report settings that will be displayed in the report form:
//       * TypeDescription - TypeDescription -
//           type of setting.
//       * ValuesForSelection - ValueList -
//           Objects that will be offered to the user in the selection list.
//           Completes the list of objects already selected by the user earlier.
//       * SelectionValuesQuery - Query -
//           returns objects that need to be supplemented with the values for the selection.
//           The first column (with the 0 index) should select the object
//           to be added to the values for the selection.Meaning.
//           To disable autofill
//           in the Request value property of the selection.The text should be written as an empty string.
//       * RestrictSelectionBySpecifiedValues - Boolean -
//           when true, the user's choice will be limited to the values
//           specified in the value for the selection (its final State).
//
Procedure OnDefineSelectionParameters(Form, SettingProperties) Export
	If SettingProperties.Type = "SettingsParameterValue"
		And SettingProperties.DCField = New DataCompositionField("DataParameters.AnalysisType") Then
		ConfigureSelectionParametersByFunctionalOptions(SettingProperties);
	EndIf;
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//	ThisForm - ClientApplicationForm - from which form the handler is called.
//  NewDCUserSettings - DataCompositionUserSettings - processed settings.
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCUserSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer);
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;

	SetRequiredSettings(UserSettingsModified);
	
	DataSet = DataCompositionSchema.DataSets.IncomeAndExpenses; // DataCompositionSchemaDataSetUnion
	DataSet.Items.Income.Query = QueryTextIncome();
	DataSet.Items.Expenses.Query = QueryTextExpenses();
	
	ConfigureUserSettingsByFunctionalOptions(SettingsComposer);
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	CostCalculationAppliedAlgorithms.AddWarningAboutPreClosingMonth(ResultDocument, SettingsComposer);
	
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
EndProcedure

#EndRegion

#Region Private

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
	ManOnlyParameter = DataCompositionSchema.Parameters.Find("ManagementAccountingOnly");
	ManOnlyParameter.Value = False;
	
	KeepManagementRecordsOfOrganizations = CalculationOfCostCached.CompanyManagementAccounting();
	UseAccountingOfOtherIncomeExpensesInLocalAccounting = GetFunctionalOption("UseAccountingOfOtherIncomeExpensesInLocalAccounting");
	
	ChoiceList = New ValueList;
	
	If PredefinedOption.VariantKey = "IncomeAndExpensesOfEnterprise"
	 Or PredefinedOption.VariantKey = "EnterpriseExpenses" Then
		
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
		
	ElsIf PredefinedOption.VariantKey = "IncomeAndExpensesForOrganizations"
	 Or PredefinedOption.VariantKey = "ExpensesOfOrganizations" Then
		
		If KeepManagementRecordsOfOrganizations Then
			ChoiceList.Add(3, NStr("vi = 'Theo tiền tệ kế toán quản trị';
									|ru = 'В валюте упр. учета';
									|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
									|it = 'In valuta della contabilità gestionale';
									|pl = 'W walucie ewidencji zarządczej';
									|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
		EndIf;
		If UseAccountingOfOtherIncomeExpensesInLocalAccounting Then
			ChoiceList.Add(4, NStr("vi = 'Bằng tiền kế toán tài chính';
									|ru = 'В валюте регл. учета';
									|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
									|it = 'In valuta della contabilità regolamentata';
									|pl = 'W walucie ewidencji reglamentowanej';
									|tr = 'Yerel muhasebe para birimi cinsinden'"));
		EndIf;
		EnterpriseParameter.Value = False;
		
	Else
		
		ManOnlyParameter.Value = True;
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
	
	OptionsKeys = New Array;
	OptionsKeys.Add("IncomeAndExpensesForOrganizations");
	OptionsKeys.Add("IncomeAndExpensesOfEnterprise");
	OptionsKeys.Add("EnterpriseExpenses");
	OptionsKeys.Add("ExpensesOfOrganizations");
	
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
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	ParameterCurrencyOfManagementAccounting = DataCompositionClientServer.GetParameter(SettingsComposer, "ManagementAccountingCurrency");
	If ParameterCurrencyOfManagementAccounting <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ManagementAccountingCurrency", ManagementAccountingCurrency);
	EndIf;
	
	CurrencyParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Currency");
	If CurrencyParameter <> Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "Currency", ManagementAccountingCurrency);
	EndIf;
	
	ShowSalesParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "ShowSales_");
	If ShowSalesParameter <> Undefined 
		And ShowSalesParameter.Value = Undefined Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "ShowSales_", 0);
	EndIf;
	
	ParameterIncludingPlannedExpenses = DataCompositionClientServer.GetParameter(SettingsComposer, "IncludingPlannedExpenses");
	If ParameterIncludingPlannedExpenses.Use
	 And ParameterIncludingPlannedExpenses.Value Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "PlannedExpenses", True);
	Else
		DataCompositionClientServer.SetParameter(SettingsComposer, "PlannedExpenses", False);
	EndIf;
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Period");
	Period = ReportPeriodParameter.Value; // StandardPeriod
	
	CurDateOfSession = CurrentSessionDate();
	EndOfPeriod = ?(ReportPeriodParameter.Use, Period.EndDate, CurDateOfSession);
	
	ParameterIncludingPlannedSales = DataCompositionClientServer.GetParameter(SettingsComposer,
		"IncludingPlannedSales");
	PlannedSales = ParameterIncludingPlannedSales.Use 
		And ParameterIncludingPlannedSales.Value;
	
	If PlannedSales And CurDateOfSession > EndOfPeriod Then
		MessageString = NStr("vi = 'Tắt sử dụng tham số ""Bao gồm doanh thu dự tính"" hoặc đặt cuối kỳ báo cáo lớn hơn hoặc bằng ngày hiện tại.';
							|ru = 'Выключите параметр ""Включая запланированные продажи"" или поставьте конечный период отчета большим или равным текущей дате.';
							|en = 'Disable the ""Including planned sales"" parameter or set the end period of the report greater than or equal to the current date.'; fa = 'Disable the ""Including planned sales"" parameter or set the end period of the report greater than or equal to the current date.';
							|it = 'Выключите параметр ""Включая запланированные продажи"" или поставьте конечный период отчета большим или равным текущей дате.';
							|pl = 'Disable the ""Including planned sales"" parameter or set the end period of the report greater than or equal to the current date.';
							|tr = '""Planlanan satışlar dahil"" parametresini kapatın veya raporun bitiş süresini mevcut tarihe eşit veya daha büyük olarak ayarlayın.'");
		
		Raise MessageString;
	EndIf;
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "PlannedSales", PlannedSales);
	
	CompanyManagementAccounting = CalculationOfCostCached.CompanyManagementAccounting(EndOfPeriod);
	DataCompositionClientServer.SetParameter(SettingsComposer, "CompanyManagementAccounting", CompanyManagementAccounting);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineSummary_",                             NStr("vi = 'Tổng hợp';
																												|ru = 'Сводно';
																												|en = 'Overall'; fa = 'Overall';
																												|it = 'Riassuntivo';
																												|pl = 'Overall';
																												|tr = 'Özet'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "RevenueLine_",                             NStr("vi = 'Thu nhập khác';
																												|ru = 'Прочие доходы';
																												|en = 'Income'; fa = 'درآمد';
																												|it = 'Altri ricavi';
																												|pl = 'Inne dochody';
																												|tr = 'Diğer gelirler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "OtherIncomeLine",                       NStr("vi = 'Thu nhập khác';
																											|ru = 'Прочие доходы';
																											|en = 'Income'; fa = 'درآمد';
																											|it = 'Altri ricavi';
																											|pl = 'Inne dochody';
																											|tr = 'Diğer gelirler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineExpenses",                            NStr("vi = 'Chi phí';
																												|ru = 'Расходы';
																												|en = 'Expenses'; fa = 'هزینه‌ها';
																												|it = 'Spese';
																												|pl = 'Rozchody';
																												|tr = 'Giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineOtherExpenses",                      NStr("vi = 'Chi phí khác';
																												|ru = 'Прочие расходы';
																												|en = 'Other expenses'; fa = 'سایر هزینه‌ها';
																												|it = 'Altre spese';
																												|pl = 'Inne rozchody';
																												|tr = 'Diğer giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineProductionCosts",            NStr("vi = 'Chi phí sản xuất';
																										|ru = 'Производственные затраты';
																										|en = 'Production costs'; fa = 'هزینه‌های تولید';
																										|it = 'Mezzi di produzione';
																										|pl = 'Koszty produkcyjne';
																										|tr = 'Üretim maliyetleri'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineOfSale",                            NStr("vi = 'Bán hàng';
																											|ru = 'Продажи';
																											|en = 'Sales'; fa = 'فروش';
																											|it = 'Vendite';
																											|pl = 'Sales';
																											|tr = 'Satışlar'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineCostOfSalesPreliminary", NStr("vi = 'Chi phí bán hàng (sơ bộ)';
																									|ru = 'Себестоимость продаж (предварительная)';
																									|en = 'COGS (preliminary)'; fa = 'COGS (preliminary)';
																									|it = 'Costo del venduto (preliminare)';
																									|pl = 'Koszty własne sprzedaży (szacunkowe)';
																									|tr = 'Satılan malların maliyeti (ön)'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TKRString",                                NStr("vi = 'Chi phí vận chuyển và thu mua';
																												|ru = 'ТЗР';
																												|en = 'TPE'; fa = 'TPE';
																												|it = 'Spese di spedizione e di gestione';
																												|pl = 'TPE';
																												|tr = 'Nakliye ve Tedarik Masrafları'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "RBPLine",                                NStr("vi = 'Chi phí trả trước';
																												|ru = 'РБП';
																												|en = 'Deferred expense'; fa = 'Deferred expense';
																												|it = 'Spese future';
																												|pl = 'Deferred expense';
																												|tr = 'Ertelenmiş giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StringFixedAssets",                 NStr("vi = 'Tài sản dài hạn';
																										|ru = 'Внеоборотные активы';
																										|en = 'Fixed assets'; fa = 'دارایی‌های ثابت';
																										|it = 'Attivi non circolanti';
																										|pl = 'Środki trwałe';
																										|tr = 'Duran varlıklar'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "StringDoNotDistribute",                     NStr("vi = 'Không phân bổ';
																												|ru = 'Не распределять';
																												|en = 'Do not allocate'; fa = 'تسهیم نشود';
																												|it = 'Non allocare';
																												|pl = 'Nie przydzielać';
																												|tr = 'Dağıtma'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineFutureSales",                     NStr("vi = 'Bán hàng trước';
																											|ru = 'Будущие продажи';
																											|en = 'Future sales'; fa = 'فروش‌های آتی';
																											|it = 'Vendite future';
																											|pl = 'Przyszłe sprzedaży';
																											|tr = 'İleri tarihli satışlar'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineFutureExpenses",                     NStr("vi = 'Chi phí trả trước';
																												|ru = 'Будущие расходы';
																												|en = 'Deferred expenses'; fa = 'هزینه‌های معوق';
																												|it = 'Spese future';
																												|pl = 'Koszty przyszłe';
																												|tr = 'İleri tarihli giderler'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineCommissionFee",         NStr("vi = 'Hoa hồng ký gửi';
																								|ru = 'Комиссионное вознаграждение';
																								|en = 'Commission'; fa = 'کارمزد';
																								|it = 'Commissione';
																								|pl = 'Wynagrodzenie komisowe';
																								|tr = 'Komisyon ücreti'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "OtherRevenueLine",                      NStr("vi = 'Doanh thu khác';
																											|ru = 'Прочая выручка';
																											|en = 'Revenue — Services and Assets'; fa = 'درآمد — خدمات و دارایی‌ها';
																											|it = 'Altro fatturato';
																											|pl = 'Utarg pozostały';
																											|tr = 'Diğer gelir'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineHIA",                                NStr("vi = 'SXDD';
																												|ru = 'ОВЗ';
																												|en = 'Cost center'; fa = 'مرکز هزینه';
																												|it = 'CdC';
																												|pl = 'Cost center';
																												|tr = 'MOM'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineSellingExpenses",                   NStr("vi = 'Chi phí bán hàng';
																											|ru = 'Расходы на продажу';
																											|en = 'Sales expenses'; fa = 'هزینه‌های فروش';
																											|it = 'Spese di vendita';
																											|pl = 'Rozchody na sprzedaż';
																											|tr = 'Satış giderleri'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineForCostOfGoodsSold",              NStr("vi = 'Cho giá vốn hàng bán';
																											|ru = 'На себестоимость продаж';
																											|en = 'To cost of goods sold'; fa = 'به بهای تمام‌شده کالای فروش‌رفته';
																											|it = 'Per costo delle vendite';
																											|pl = 'Na koszty własne sprzedaży';
																											|tr = 'Satış maliyetleri üzerine'"));
	
	UserSettingsModified = True;
EndProcedure

Function StructureOfFieldHeaders()
	StructureOfFieldHeaders = New Structure;
	
	ParameterTypeOfAnalysis = DataCompositionClientServer.GetParameter(SettingsComposer, "AnalysisType");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, ParameterTypeOfAnalysis);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues[ParameterTypeOfAnalysis.Value - 1];
		StructureOfFieldHeaders.Insert("AnalysisType", PresentationOfParameterValue);
	EndIf;
	
	Return StructureOfFieldHeaders;
EndFunction

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("AnalysisType");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
EndFunction

Function QueryTextIncome()
	
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
	|;
	|	
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherIncome.Organization AS Organization,
	|	OtherIncome.IncomeItem AS IncomeItem,
	|	OtherIncome.DimensionOfRevenue AS DimensionOfRevenue,
	|	OtherIncome.Department AS Department,
	|	OtherIncome.LineOfBusiness AS LineOfBusiness,
	|	OtherIncome.SecondPeriod AS SecondPeriod,
	|	OtherIncome.MonthPeriod AS MonthPeriod,
	|	OtherIncome.DayPeriod AS DayPeriod,
	|	OtherIncome.WeekPeriod AS WeekPeriod,
	|	OtherIncome.TenDaysPeriod AS TenDaysPeriod,
	|	OtherIncome.QuarterPeriod AS QuarterPeriod,
	|	OtherIncome.HalfYearPeriod AS HalfYearPeriod,
	|	OtherIncome.YearPeriod AS YearPeriod,
	|	OtherIncome.Recorder AS Recorder,
	|	CASE
	|		WHEN NOT OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumTurnover
	|		ELSE 0
	|	END AS SumReceipt,
	|	CASE
	|		WHEN NOT OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumManTurnover
	|		ELSE 0
	|	END AS SumManReceipt,
	|	CASE
	|		WHEN NOT OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumComplTurnover
	|		ELSE 0
	|	END AS SumComplReceipt,
	|	CASE
	|		WHEN OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumTurnover
	|		ELSE 0
	|	END AS SumExpense,
	|	CASE
	|		WHEN OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumManTurnover
	|		ELSE 0
	|	END AS SumManExpense,
	|	CASE
	|		WHEN OtherIncome.Recorder REFS Document.AllocationOfIncomeByLinesOfBusiness
	|			THEN OtherIncome.SumComplTurnover
	|		ELSE 0
	|	END AS SumComplExpense,
	|	OtherIncome.SumTurnover AS SumClosingBalance,
	|	OtherIncome.SumManTurnover AS SumManClosingBalance,
	|	OtherIncome.SumComplTurnover AS SumComplClosingBalance
	|INTO OtherIncomeBalancesTurnover
	|FROM
	|	AccumulationRegister.OtherIncome.Turnovers(, , Auto, {(DimensionOfRevenue IN
	|			        (SELECT
	|			            SelectionByPartnerSegment.Partner
	|			        FROM
	|			            SelectionByPartnerSegment
	|			        WHERE
	|			            SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed)
	|			    OR DimensionOfRevenue.Partner IN
	|			        (SELECT
	|			            SelectionByPartnerSegment.Partner
	|			        FROM
	|			            SelectionByPartnerSegment
	|			        WHERE
	|			            SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}) AS OtherIncome
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	&OtherIncomeLine AS Section,
	|	&RevenueLine_ AS StandardSection,
	|	TRUE AS ThisIsIncome,
	|	CASE 
	|		WHEN &ReportData = 4
	|			THEN OtherIncome.Organization.LocalAccountingCurrency
	|		ELSE &ManagementAccountingCurrency
	|	END AS Currency,
	|
	|	OtherIncome.IncomeItem,
	|	OtherIncome.DimensionOfRevenue,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) AS ExpenseItem,
	|
	|	OtherIncome.Organization,
	|	OtherIncome.Department,
	|	OtherIncome.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	VALUE(Document.SalesOrder.EmptyRef) AS OrderDocument,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue.SalesOpportunity <> VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END AS DealWithCustomers,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.Partner
	|		WHEN OtherIncome.DimensionOfRevenue REFS Catalog.Partners
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Catalog.Partners.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Partner,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.Terms
	|		ELSE NULL
	|	END AS Terms,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Document.PurchaseOrder
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue.Contract
	|		ELSE NULL
	|	END AS Contract,
	|
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	CASE
	|		WHEN OtherIncome.DimensionOfRevenue REFS Catalog.Assets
	|				AND OtherIncome.DimensionOfRevenue <> VALUE(Catalog.Assets.EmptyRef)
	|			THEN OtherIncome.DimensionOfRevenue
	|		ELSE VALUE(Catalog.Assets.EmptyRef)
	|	END AS Asset,
	|
	|	OtherIncome.SecondPeriod AS SecondPeriod,
	|	OtherIncome.SecondPeriod AS Period,
	|	OtherIncome.MonthPeriod AS MonthPeriod,
	|	OtherIncome.DayPeriod AS DayPeriod,
	|	OtherIncome.WeekPeriod AS WeekPeriod,
	|	OtherIncome.TenDaysPeriod AS TenDaysPeriod,
	|	OtherIncome.QuarterPeriod AS QuarterPeriod,
	|	OtherIncome.HalfYearPeriod AS HalfYearPeriod,
	|	OtherIncome.YearPeriod AS YearPeriod,
	|	DATETIME(1,1,1) AS VariancePeriod,
	|	CASE
	|		WHEN OtherIncome.Recorder = UNDEFINED
	|			THEN NULL
	|		ELSE OtherIncome.Recorder
	|	END AS Recorder,
	|
	|	0 AS IncomeBalanceOfThePreviousPeriod,
	|	CASE 
	|		WHEN &ReportData = 1 OR &ManagementAccountingOnly THEN
	|			OtherIncome.SumReceipt
	|		WHEN &ReportData = 2 OR &ReportData = 3 THEN
	|			OtherIncome.SumManReceipt
	|		WHEN &ReportData = 4 THEN
	|			OtherIncome.SumComplReceipt
	|		ELSE
	|			0
	|	END AS IncomeAmount,
	|	CASE 
	|		WHEN &ReportData = 1 OR &ManagementAccountingOnly THEN
	|			OtherIncome.SumExpense
	|		WHEN &ReportData = 2 OR &ReportData = 3 THEN
	|			OtherIncome.SumManExpense
	|		WHEN &ReportData = 4 THEN
	|			OtherIncome.SumComplExpense
	|		ELSE
	|			0
	|	END AS AllocatedIncome,
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|		 AND (OtherIncome.SumReceipt >= OtherIncome.SumExpense
	|				OR OtherIncome.SumExpense = 0)
	|			THEN OtherIncome.SumClosingBalance
	|		WHEN (&ReportData = 2 OR &ReportData = 3)
	|		 AND (OtherIncome.SumManReceipt >= OtherIncome.SumManExpense
	|				OR OtherIncome.SumManExpense = 0)
	|			THEN OtherIncome.SumManClosingBalance
	|		WHEN &ReportData = 4
	|		 AND (OtherIncome.SumComplReceipt >= OtherIncome.SumComplExpense
	|				OR OtherIncome.SumComplExpense = 0)
	|			THEN OtherIncome.SumComplClosingBalance
	|		ELSE 0
	|	END AS NotAllocatedIncome,
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|		 AND (OtherIncome.SumReceipt < OtherIncome.SumExpense
	|				AND OtherIncome.SumExpense <> 0)
	|			THEN -OtherIncome.SumClosingBalance
	|		WHEN (&ReportData = 2 OR &ReportData = 3)
	|		 AND (OtherIncome.SumManReceipt < OtherIncome.SumManExpense
	|				AND OtherIncome.SumManExpense <> 0)
	|			THEN -OtherIncome.SumManClosingBalance
	|		WHEN &ReportData = 4
	|		 AND (OtherIncome.SumComplReceipt < OtherIncome.SumComplExpense
	|				AND OtherIncome.SumComplExpense <> 0)
	|			THEN -OtherIncome.SumComplClosingBalance
	|		ELSE 0
	|	END AS DistributionExceedsRevenues
	|FROM
	|	OtherIncomeBalancesTurnover AS OtherIncome";
	
	Return QueryText;
EndFunction
Function QueryTextExpenses()
	
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
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	(CASE
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		ELSE &LineOtherExpenses END) AS Section,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.SecondPeriod AS SecondPeriod,
	|	OtherExpenses.SecondPeriod AS Period,
	|	OtherExpenses.MonthPeriod AS MonthPeriod,
	|	OtherExpenses.DayPeriod AS DayPeriod,
	|	OtherExpenses.WeekPeriod AS WeekPeriod,
	|	OtherExpenses.TenDaysPeriod AS TenDaysPeriod,
	|	OtherExpenses.QuarterPeriod AS QuarterPeriod,
	|	OtherExpenses.HalfYearPeriod AS HalfYearPeriod,
	|	OtherExpenses.YearPeriod AS YearPeriod,
	|
	|	DATETIME(1,1,1) AS VariancePeriod,
	|
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|			THEN OtherExpenses.SumOpeningBalance
	|		WHEN &ReportData = 2
	|			THEN OtherExpenses.AmountExcludingVATOpeningBalance
	|		WHEN &ReportData = 3
	|			THEN OtherExpenses.SumManOpeningBalance
	|		WHEN &ReportData = 4
	|			THEN OtherExpenses.SumComplOpeningBalance
	|		ELSE 0
	|	END AS SumOpeningBalance,
	|	0 AS SumReceipt,
	|	0 AS SumExpense,
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|			THEN OtherExpenses.SumClosingBalance
	|		WHEN &ReportData = 2
	|			THEN OtherExpenses.AmountExcludingVATClosingBalance
	|		WHEN &ReportData = 3
	|			THEN OtherExpenses.SumManClosingBalance
	|		WHEN &ReportData = 4
	|			THEN OtherExpenses.SumComplClosingBalance
	|		ELSE 0
	|	END AS SumClosingBalance
	|
	|INTO OtherExpenses
	|FROM
	|	AccumulationRegister.OtherExpenses.BalanceAndTurnovers(, , Auto, , 
	|		{(DimensionOfExpenses IN
	|		        (SELECT
	|		            SelectionByPartnerSegment.Partner
	|		        FROM
	|		            SelectionByPartnerSegment
	|		        WHERE
	|		            SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed)
	|		    OR DimensionOfExpenses.Partner IN
	|		        (SELECT
	|		            SelectionByPartnerSegment.Partner
	|		        FROM
	|		            SelectionByPartnerSegment
	|		        WHERE
	|		            SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}) AS OtherExpenses
	|LEFT JOIN
	|	Catalog.CostCenters AS ConstCenter
	|	ON OtherExpenses.DimensionOfExpenses = ConstCenter.Ref
	|
	// The Receipt of Registered Recorded traffic.
	|UNION ALL
	|SELECT
	|	(CASE
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		ELSE &LineOtherExpenses END) AS Section,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation,
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Period AS SecondPeriod,
	|	OtherExpenses.Period AS Period,
	|	BEGINOFPERIOD(OtherExpenses.Period, MONTH) AS MonthPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, DAY),
	|	BEGINOFPERIOD(OtherExpenses.Period, WEEK) AS WeekPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, TENDAYS) AS TenDaysPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, QUARTER) AS QuarterPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, YEAR) AS YearPeriod,
	|
	|	BEGINOFPERIOD(OtherExpenses.VariancePeriod, MONTH) AS VariancePeriod,
	|
	|	0 AS SumOpeningBalance,
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|			THEN OtherExpenses.Sum
	|		WHEN &ReportData = 2
	|			THEN OtherExpenses.AmountExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN OtherExpenses.SumMan
	|		WHEN &ReportData = 4
	|			THEN OtherExpenses.SumCompl
	|		ELSE 0
	|	END AS SumReceipt,
	|	0 AS SumExpense,
	|	0 AS SumClosingBalance
	|
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|LEFT JOIN
	|	Catalog.CostCenters AS ConstCenter
	|	ON OtherExpenses.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND OtherExpenses.Active
	|	AND OtherExpenses.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate)
	|{WHERE
	|	(OtherExpenses.DimensionOfExpenses IN
	|		(SELECT
	|			SelectionByPartnerSegment.Partner
	|		FROM
	|			SelectionByPartnerSegment
	|		WHERE
	|			SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed)
	|	OR OtherExpenses.DimensionOfExpenses.Partner IN
	|		(SELECT
	|			SelectionByPartnerSegment.Partner
	|		FROM
	|			SelectionByPartnerSegment
	|		WHERE
	|			SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|
	// Distribution of expenses.
	|UNION ALL
	|SELECT
	|	(CASE
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		ELSE &LineOtherExpenses END) AS Section,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	OtherExpenses.BusinessOperation AS BusinessOperation,
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Period AS SecondPeriod,
	|	OtherExpenses.Period AS Period,
	|	BEGINOFPERIOD(OtherExpenses.Period, MONTH)     AS MonthPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, DAY)      AS DayPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, WEEK)    AS WeekPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, TENDAYS)    AS TenDaysPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, QUARTER)   AS QuarterPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, YEAR)       AS YearPeriod,
	|
	|	BEGINOFPERIOD(OtherExpenses.VariancePeriod, MONTH) AS VariancePeriod,
	|
	|	0 AS SumOpeningBalance,
	|	0 AS SumReceipt,
	|	CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|			THEN OtherExpenses.Sum
	|		WHEN &ReportData = 2
	|			THEN OtherExpenses.AmountExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN OtherExpenses.SumMan
	|		WHEN &ReportData = 4
	|			THEN OtherExpenses.SumCompl
	|		ELSE 0
	|	END AS SumExpense,
	|	0 AS SumClosingBalance
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|LEFT JOIN
	|	Catalog.CostCenters AS ConstCenter
	|	ON OtherExpenses.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Expense)
	|	AND OtherExpenses.Active
	|	AND OtherExpenses.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate)
	|
	// Exclusion of expenses reflected in the documents "Transfer of goods between organizations".
	|UNION ALL
	|SELECT
	|	(CASE
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData <> 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData <> 4
	|		 AND &CostAllocationOptionManag 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToDeferredExpenses)
	|			THEN &RBPLine
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal IN (
	|				VALUE(Enum.CostAllocationOptions.ToProductionCosts),
	|				VALUE(Enum.CostAllocationOptions.ToProductionCostDirect))
	|			THEN &LineProductionCosts
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|			THEN &StringFixedAssets
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.DoNotAllocate)
	|			THEN &StringDoNotDistribute
	|		WHEN &ReportData = 4
	|		 AND OtherExpenses.ExpenseItem.CostAllocationOptionLocal
	|				= VALUE(Enum.CostAllocationOptions.ToInventoryCost)
	|			THEN &TKRString
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostCenters)
	|			THEN &LineHIA
	|		WHEN &ReportData = 4
	|		 AND &CostAllocationOptionLocal 
	|				= VALUE(Enum.CostAllocationOptions.ToCostOfGoodsSold)
	|			THEN &LineForCostOfGoodsSold
	|		ELSE &LineOtherExpenses END) AS Section,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	OtherExpenses.BusinessOperation AS BusinessOperation,
	|	OtherExpenses.Recorder AS Recorder,
	|	OtherExpenses.Period AS SecondPeriod,
	|	OtherExpenses.Period AS Period,
	|	BEGINOFPERIOD(OtherExpenses.Period, MONTH)     AS MonthPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, DAY)      AS DayPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, WEEK)    AS WeekPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, TENDAYS)    AS TenDaysPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, QUARTER)   AS QuarterPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(OtherExpenses.Period, YEAR)       AS YearPeriod,
	|
	|	BEGINOFPERIOD(OtherExpenses.VariancePeriod, MONTH) AS VariancePeriod,
	|
	|	0 AS SumOpeningBalance,
	|	-(CASE
	|		WHEN (&ReportData = 1 OR &ManagementAccountingOnly)
	|			THEN OtherExpenses.Sum
	|		WHEN &ReportData = 2
	|			THEN OtherExpenses.AmountExcludingVAT
	|		WHEN &ReportData = 3
	|			THEN OtherExpenses.SumMan
	|		WHEN &ReportData = 4
	|			THEN OtherExpenses.SumCompl
	|		ELSE 0
	|	END) AS SumReceipt,
	|	0 AS SumExpense,
	|	0 AS SumClosingBalance
	|FROM
	|	AccumulationRegister.OtherExpenses AS OtherExpenses
	|	INNER JOIN Document.CustomerInvoiceIntercompany AS Transfer_
	|		ON Transfer_.Ref = OtherExpenses.Recorder
	|LEFT JOIN
	|	Catalog.CostCenters AS ConstCenter
	|	ON OtherExpenses.DimensionOfExpenses = ConstCenter.Ref
	|WHERE
	|	(OtherExpenses.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1,1,1))
	|	AND OtherExpenses.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND OtherExpenses.Active
	|	AND &ShowSales_ = 1 // Except for sales between organizations
	|	AND OtherExpenses.BusinessOperation <> VALUE(Enum.BusinessTransactions.WriteOffVariancesToAllocate)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	OtherExpenses.Section AS Section,
	|	&LineExpenses AS StandardSection,
	|	FALSE AS ThisIsIncome,
	|	CASE 
	|	WHEN &ReportData = 4
	|			THEN OtherExpenses.Organization.LocalAccountingCurrency
	|		ELSE &ManagementAccountingCurrency
	|	END AS Currency,
	|	
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) AS IncomeItem,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses,
	|	
	|	OtherExpenses.Organization,
	|	OtherExpenses.Department,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|
	|	CASE
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.SalesOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoice.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoiceIntercompany
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.PurchaseOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.VendorInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.Warehouse
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.Warehouses
	|			THEN OtherExpenses.DimensionOfExpenses
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	
	|	CASE
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.SalesOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoice.EmptyRef)
	|		THEN OtherExpenses.DimensionOfExpenses
	|		ELSE VALUE(Document.SalesOrder.EmptyRef)
	|	END AS OrderDocument,
	|	CASE
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.SalesOpportunitiesToCustomer
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.SalesOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoice.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END AS DealWithCustomers,
	|	
	|	CASE
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.SalesOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoice.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoiceIntercompany
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.PurchaseOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.VendorInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.Manager
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.TransferOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.TransferOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.InventoryTransfer
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.InventoryTransfer.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.EmployeeResponsible
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	CASE
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.Partners
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Catalog.Partners.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.SalesOpportunitiesToCustomer
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.Partner
	|		WHEN OtherExpenses.DimensionOfExpenses REFS Document.SalesOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.SalesOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoice.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.PurchaseOrder
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.PurchaseOrder.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.CustomerInvoiceIntercompany
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|			OR OtherExpenses.DimensionOfExpenses REFS Document.VendorInvoice
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses.Partner
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Partner,
	|	CASE WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.Products
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Catalog.Products.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END AS Products,
	|	CASE WHEN OtherExpenses.DimensionOfExpenses REFS Catalog.Assets
	|				AND OtherExpenses.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|			THEN OtherExpenses.DimensionOfExpenses
	|		ELSE VALUE(Catalog.Assets.EmptyRef)
	|	END AS Asset,
	|	
	|	CASE
	|		WHEN OtherExpenses.Recorder = UNDEFINED
	|			THEN NULL
	|		ELSE OtherExpenses.Recorder
	|	END AS Recorder,
	|	OtherExpenses.SecondPeriod AS SecondPeriod,
	|	OtherExpenses.SecondPeriod AS Period,
	|	OtherExpenses.MonthPeriod AS MonthPeriod,
	|	OtherExpenses.DayPeriod AS DayPeriod,
	|	OtherExpenses.WeekPeriod AS WeekPeriod,
	|	OtherExpenses.TenDaysPeriod AS TenDaysPeriod,
	|	OtherExpenses.QuarterPeriod AS QuarterPeriod,
	|	OtherExpenses.HalfYearPeriod AS HalfYearPeriod,
	|	OtherExpenses.YearPeriod AS YearPeriod,
	|
	|	OtherExpenses.VariancePeriod AS VariancePeriod,
	|	
	|	OtherExpenses.SumOpeningBalance AS ExpenseBalanceOfThePreviousPeriod,
	|	OtherExpenses.SumReceipt AS ExpenseAmount,
	|	OtherExpenses.SumClosingBalance AS ExpenseBalance,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS AllocatedToFinancialResult,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS AllocatedToFutureExpenses,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.ProductsRelease)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS AllocatedToProduction,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.ExpenseWithCorrespondenceToProvisions)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS WrittenOffAtTheExpenseOfReserves,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS AllocatedToGoodsCost,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.ExpenseAllocationOnCostOfGoodsSold)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS AllocatedToCostOfGoodsSold,
	|	(CASE
	|		WHEN OtherExpenses.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters)
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS TransitBetweenHIA,
	|	(CASE
	|		WHEN NOT OtherExpenses.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.AllocationOfExpensesByLinesOfBusiness),
	|				VALUE(Enum.BusinessTransactions.DeferredExpenseAllocation),
	|				VALUE(Enum.BusinessTransactions.ProductsRelease),
	|				VALUE(Enum.BusinessTransactions.ExpenseAllocationToCost),
	|				VALUE(Enum.BusinessTransactions.ExpenseAllocationOnCostOfGoodsSold),
	|				VALUE(Enum.BusinessTransactions.ExpenseWithCorrespondenceToProvisions),
	|				VALUE(Enum.BusinessTransactions.TransitOfExpensesBetweenCostCenters))
	|			THEN OtherExpenses.SumExpense
	|		ELSE 0 END) AS OtherWriteOffOfExpenses
	|FROM
	|	OtherExpenses AS OtherExpenses
	|WHERE
	|	NOT (&ExcludeTransportationCostAndDeferredExpense
	|		AND OtherExpenses.Section IN (&TKRString,
	|									&RBPLine,
	|									&LineProductionCosts,
	|									&StringFixedAssets,
	|									&StringDoNotDistribute,
	|									&LineForCostOfGoodsSold,
	|									&LineHIA)
	|		)
	|";
	
	CostAllocationOptionManag = "OtherExpenses.ExpenseItem.CostAllocationOptionManag";
	CostAllocationOptionLocal = "OtherExpenses.ExpenseItem.CostAllocationOptionLocal";
	If GetFunctionalOption("UseAccountingByExpenseObjects") Then
		CostAllocationOptionManag = "ISNULL(ConstCenter.CostAllocationOptionManag, OtherExpenses.ExpenseItem.CostAllocationOptionManag)";
		CostAllocationOptionLocal = "ISNULL(ConstCenter.CostAllocationOptionLocal, OtherExpenses.ExpenseItem.CostAllocationOptionLocal)";
	EndIf;
	QueryText = StrReplace(QueryText, 
		"&CostAllocationOptionManag", 
		CostAllocationOptionManag);
	QueryText = StrReplace(QueryText, 
		"&CostAllocationOptionLocal", 
		CostAllocationOptionLocal);
	
	Return QueryText;
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(SettingProperties)
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(2);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If Not GetFunctionalOption("UseBusinessUnits") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(3);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralWarehouses") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(4);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If Not GetFunctionalOption("EmployeeInChargeInDocuments") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(5);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If Not GetFunctionalOption("UseSalesOrders") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(7);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If Not GetFunctionalOption("UseSalesOpportunitiesToCustomer") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(8);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Then
		FoundListItem = SettingProperties.ValuesForSelection.FindByValue(10);
		SettingProperties.ValuesForSelection.Delete(FoundListItem);
	EndIf;
	
EndProcedure

Procedure ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer)
	
	SettingsToDelete = New Array;
	
	UseProductionManagement = GetFunctionalOption("UseProductionManagement")
		Or GetFunctionalOption("UseProductionManagement2_2");
	If Not UseProductionManagement Then
		SettingsToDelete.Add(
			"AllocatedToProduction");
	EndIf;
	
	GenerateFutureExpenseCommitments = False;
	GenerateFutureExpenseCommitments = GetFunctionalOption("GenerateFutureExpenseCommitments");
	If Not GenerateFutureExpenseCommitments Then
		SettingsToDelete.Add(
			"WrittenOffAtTheExpenseOfReserves");
	EndIf;
	
	UseAccountingByExpenseObjects = False;
	UseAccountingByExpenseObjects = GetFunctionalOption("UseAccountingByExpenseObjects");
	If Not UseAccountingByExpenseObjects Then
		SettingsToDelete.Add(
			"TransitBetweenHIA");
	EndIf;
	
	DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer,
		SettingsToDelete, True);
	
EndProcedure

#EndRegion

#EndIf