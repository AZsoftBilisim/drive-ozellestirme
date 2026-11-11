
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.BeforeImportSettingsToComposer = True;
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
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		If NewDCUserSettings = Undefined Then
			UserSettings = Context.Report.SettingsComposer.UserSettings; // DataCompositionUserSettings -
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, UserSettings);
		Else
			ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		EndIf;
		
		ConfigureSelectionParametersByFunctionalOptions(NewDCSettings);
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
		FormSettingsComposer = Context.Report.SettingsComposer;
		Parameters = Context.Parameters;
		
		If Parameters.Property("UserParameters") Then
			DataCompositionClientServer.AddParametersToUserSettings(FormSettingsComposer, Parameters.UserParameters);
			NewDCUserSettings = FormSettingsComposer.UserSettings;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionProcessor = New DataCompositionProcessor;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	ReportSettings.DataParameters.SetParameterValue("Production",
		NStr("vi = 'Sản xuất';
			|ru = 'Производство';
			|en = 'Production'; fa = 'تولید';
			|it = 'Produzione';
			|pl = 'Production';
			|tr = 'Üretim'"));
	ReportSettings.DataParameters.SetParameterValue("OpeningBalance",
		NStr("vi = 'Dư đầu';
			|ru = 'Начальный остаток';
			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
			|it = 'Saldo iniziale';
			|pl = 'Saldo początkowe';
			|tr = 'Açılış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedMaterials22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (nguyên vật liệu) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (материалы) для 2.2';
			|en = 'Received to work-in-progress (materials) 2.2'; fa = 'Received to work-in-progress (materials) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (materiali) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (materiały) dla 2.2';
			|tr = 'Devam eden imalata alındı (malzemeler) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedMaterials21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (nguyên vật liệu) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (материалы) для 2.1';
			|en = 'Received to work-in-progress (materials) 2.1'; fa = 'Received to work-in-progress (materials) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (materiali) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (materiały) dla 2.1';
			|tr = 'Devam eden imalata alındı (malzemeler) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedWaste",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (phế liệu theo giá trị cố định)';
			|ru = 'Поступило на незавершенное производство (отходы по фиксированной стоимости)';
			|en = 'Received to work-in-progress (waste at a fixed cost)'; fa = 'Received to work-in-progress (waste at a fixed cost)';
			|it = 'Verificatosi nella produzione non ultimata (scarti a costo fisso)';
			|pl = 'Wpłynęło do niezakończonej produkcji (odpady według stałej ceny)';
			|tr = 'Devam eden imalata (sabit maliyete göre atıklar) alındı'"));
	ReportSettings.DataParameters.SetParameterValue("ServicesReceived22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (dịch vụ của người nhận gia công) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (услуги переработчика) для 2.2';
			|en = 'Received to work-in-progress (subcontractor services) 2.2'; fa = 'Received to work-in-progress (subcontractor services) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (servizi elaboratore) per 2.2';
			|pl = 'Wpłynęło do niezakończonej produkcji (usługi przetwórcy) dla 2.2';
			|tr = 'Devam eden imalata alındı (fason hizmetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("Expense22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (nguyên vật liệu) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (материалы) для 2.2';
			|en = 'Work-in-progress expense (materials) 2.2'; fa = 'Work-in-progress expense (materials) 2.2';
			|it = 'Spese della produzione non ultimata (materiali) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (materiały) dla 2.2';
			|tr = 'Devam eden imalat gideri (malzemeler) 2.2'"));	
	ReportSettings.DataParameters.SetParameterValue("Expense21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (nguyên vật liệu) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (материалы) для 2.1';
			|en = 'Work-in-progress expense (materials) 2.1'; fa = 'Work-in-progress expense (materials) 2.1';
			|it = 'Spese della produzione non ultimata (materiali) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (materiały) dla 2.1';
			|tr = 'Devam eden imalat gideri (malzemeler) 2.1'"));
		
	ReportSettings.DataParameters.SetParameterValue("InitialBalanceLaborCosts22",
		NStr("vi = 'Dư đầu (công lao động) dành cho 2.2';
			|ru = 'Начальный остаток (трудозатраты) для 2.2';
			|en = 'Opening balance (labor costs) 2.2'; fa = 'Opening balance (labor costs) 2.2';
			|it = 'Saldo iniziale (costi del lavoro) per 2.2';
			|pl = 'Saldo początkowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için açılış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("InitialBalanceLaborCosts21",
		NStr("vi = 'Dư đầu (công lao động) dành cho 2.1';
			|ru = 'Начальный остаток (трудозатраты) для 2.1';
			|en = 'Opening balance (labor costs) 2.1'; fa = 'Opening balance (labor costs) 2.1';
			|it = 'Saldo iniziale (costi del lavoro) per 2.1';
			|pl = 'Saldo początkowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için açılış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedLaborCosts22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (công lao động) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (трудозатраты) для 2.2';
			|en = 'Received to work-in-progress (labor costs) 2.2'; fa = 'Received to work-in-progress (labor costs) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (costi del lavoro) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (nakłady pracy) dla 2.2';
			|tr = 'Devam eden imalata alındı (iş gücü maliyetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedLaborCosts21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (công lao động) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (трудозатраты) для 2.1';
			|en = 'Received to work-in-progress (labor costs) 2.1'; fa = 'Received to work-in-progress (labor costs) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (costi del lavoro) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (nakłady pracy) dla 2.1';
			|tr = 'Devam eden imalata alındı (iş gücü maliyetleri) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionLaborCosts22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (công lao động) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (трудозатраты) для 2.2';
			|en = 'Work-in-progress expense (labor costs) 2.2'; fa = 'Work-in-progress expense (labor costs) 2.2';
			|it = 'Spese della produzione non ultimata (costi del lavoro) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (nakłady pracy) dla 2.2';
			|tr = 'Devam eden imalat gideri (iş gücü maliyetleri) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionLaborCosts21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (công lao động) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (трудозатраты) для 2.1';
			|en = 'Work-in-progress expense (labor costs) 2.1'; fa = 'Work-in-progress expense (labor costs) 2.1';
			|it = 'Spese della produzione non ultimata (costi del lavoro) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (nakłady pracy) dla 2.1';
			|tr = 'Devam eden imalat gideri (iş gücü maliyetleri) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("FinalBalanceLaborCosts22",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.2';
			|ru = 'Конечный остаток (трудозатраты) для 2.2';
			|en = 'Closing balance (labor costs) 2.2'; fa = 'Closing balance (labor costs) 2.2';
			|it = 'Bilancio finale (costi del lavoro) per 2.2';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için kapanış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("FinalBalanceLaborCosts21",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.1';
			|ru = 'Конечный остаток (трудозатраты) для 2.1';
			|en = 'Closing balance (labor costs) 2.1'; fa = 'Closing balance (labor costs) 2.1';
			|it = 'Bilancio finale (costi del lavoro) per 2.1';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için kapanış bakiyesi (iş gücü maliyetleri)'"));
		
	ReportSettings.DataParameters.SetParameterValue("InitialRemainderArticleByArticle22",
		NStr("vi = 'Dư đầu (mục hàng) dành cho 2.2';
			|ru = 'Начальный остаток (постатейные) для 2.2';
			|en = 'Opening balance (itemized) 2.2'; fa = 'Opening balance (itemized) 2.2';
			|it = 'Saldo iniziale (per articoli) per 2.2';
			|pl = 'Saldo początkowe (według pozycji) 2.2';
			|tr = '2.2 için açılış bakiyesi (ayrıntılı)'"));
	ReportSettings.DataParameters.SetParameterValue("InitialRemainderArticleByArticle21",
		NStr("vi = 'Dư đầu (mục hàng) dành cho 2.1';
			|ru = 'Начальный остаток (постатейные) для 2.1';
			|en = 'Opening balance (itemized) 2.1'; fa = 'Opening balance (itemized) 2.1';
			|it = 'Saldo iniziale (per articoli) per 2.1';
			|pl = 'Saldo początkowe (według pozycji) dla 2.1';
			|tr = '2.1 için açılış bakiyesi (ayrıntılı)'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedArticleByArticle22",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (mục hàng) dành cho 2.2';
			|ru = 'Поступило на незавершенное производство (постатейные) для 2.2';
			|en = 'Received to work-in-progress (itemized) 2.2'; fa = 'Received to work-in-progress (itemized) 2.2';
			|it = 'Verificatosi nella produzione non ultimata (per articoli) per 2.2';
			|pl = 'Wpłynęło do produkcji niezakończonej (według pozycji) dla 2.2';
			|tr = 'Devam eden imalata alındı (ayrıntılı) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ReceivedArticleByArticle21",
		NStr("vi = 'Đã tiếp nhận vào sản xuất dở dang (mục hàng) dành cho 2.1';
			|ru = 'Поступило на незавершенное производство (постатейные) для 2.1';
			|en = 'Received to work-in-progress (itemized) 2.1'; fa = 'Received to work-in-progress (itemized) 2.1';
			|it = 'Verificatosi nella produzione non ultimata (per articoli) per 2.1';
			|pl = 'Wpłynęło do produkcji niezakończonej (według pozycji) dla 2.1';
			|tr = 'Devam eden imalata alındı (ayrıntılı) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionArticleByArticle22",
		NStr("vi = 'Chi phí từ sản xuất dở dang (mục hàng) dành cho 2.2';
			|ru = 'Расход из незавершенного производства (постатейные) для 2.2';
			|en = 'Work-in-progress expense (itemized) 2.2'; fa = 'Work-in-progress expense (itemized) 2.2';
			|it = 'Spese della produzione non ultimata (per articoli) per 2.2';
			|pl = 'Rozchód z niezakończonej produkcji (według pozycji) dla 2.2';
			|tr = 'Devam eden imalat gideri (ayrıntılı) 2.2'"));
	ReportSettings.DataParameters.SetParameterValue("ConsumptionArticleByArticle21",
		NStr("vi = 'Chi phí từ sản xuất dở dang (mục hàng) dành cho 2.1';
			|ru = 'Расход из незавершенного производства (постатейные) для 2.1';
			|en = 'Work-in-progress expense (itemized) 2.1'; fa = 'Work-in-progress expense (itemized) 2.1';
			|it = 'Spese della produzione non ultimata (per articoli) per 2.1';
			|pl = 'Rozchód z niezakończonej produkcji (według pozycji) dla 2.1';
			|tr = 'Devam eden imalat gideri (ayrıntılı) 2.1'"));
	ReportSettings.DataParameters.SetParameterValue("FinalRemainderArticleByArticle22",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.2';
			|ru = 'Конечный остаток (трудозатраты) для 2.2';
			|en = 'Closing balance (labor costs) 2.2'; fa = 'Closing balance (labor costs) 2.2';
			|it = 'Bilancio finale (costi del lavoro) per 2.2';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.2';
			|tr = '2.2 için kapanış bakiyesi (iş gücü maliyetleri)'"));
	ReportSettings.DataParameters.SetParameterValue("FinalRemainderArticleByArticle21",
		NStr("vi = 'Dư cuối (công lao động) dành cho 2.1';
			|ru = 'Конечный остаток (трудозатраты) для 2.1';
			|en = 'Closing balance (labor costs) 2.1'; fa = 'Closing balance (labor costs) 2.1';
			|it = 'Bilancio finale (costi del lavoro) per 2.1';
			|pl = 'Saldo końcowe (nakłady pracy) dla 2.1';
			|tr = '2.1 için kapanış bakiyesi (iş gücü maliyetleri)'"));
		
	ReportSettings.DataParameters.SetParameterValue("Material_",
		NStr("vi = 'Nguyên vật liệu';
			|ru = 'Материальные';
			|en = 'Material'; fa = 'ماده';
			|it = 'Materiali';
			|pl = 'Material';
			|tr = 'Malzeme'"));
	ReportSettings.DataParameters.SetParameterValue("Services",
		NStr("vi = 'Dịch vụ';
			|ru = 'Услуги';
			|en = 'Services'; fa = 'خدمات';
			|it = 'Servizi';
			|pl = 'Services';
			|tr = 'Hizmetler'"));
	ReportSettings.DataParameters.SetParameterValue("LaborCosts",
		NStr("vi = 'Công lao động';
			|ru = 'Трудозатраты';
			|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
			|it = 'Costi di manodopera';
			|pl = 'Nakłady pracy';
			|tr = 'İş gücü maliyetleri'"));
	ReportSettings.DataParameters.SetParameterValue("Itemized",
		NStr("vi = 'Theo từng mục';
			|ru = 'Постатейные';
			|en = 'Itemized'; fa = 'تفکیک‌شده';
			|it = 'Dettagliati per voce';
			|pl = 'Itemized';
			|tr = 'Ayrıntılı'"));
	
	ReportSettings.DataParameters.SetParameterValue("InclusionExclusionOfVAT",
		NStr("vi = 'Gồm/không gồm thuế GTGT';
			|ru = 'Вкл./искл. НДС';
			|en = 'Include/exclude VAT'; fa = 'شامل/بدون VAT';
			|it = 'IVA incl./escl.';
			|pl = 'Brutto/netto';
			|tr = 'KDV dahil/hariç'"));
	
	ReportPeriodParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Period");
	WithoutFilterByPeriod = Not ReportPeriodParameter.Use;
	DataCompositionClientServer.SetParameter(ReportSettings, "WithoutFilterByPeriod", WithoutFilterByPeriod);
	
	QueryText = CostsServer.QueryTextProductionCostsByProductionLots();
	
	DataCompositionSchema.DataSets.Main.Query = QueryText.QueryText;
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CostsServer.AddSelectionForSelectedResources(QueryText.Resources, CompositionTemplate.DataSets.Main);
	
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True, False);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	SpreadsheetDocument = OutputProcessor.EndOutput();
	
	// delete the service texts
	
	ReplacementTextExtended = "%ServiceFilter% And
						|";
	ReplacementTextWithoutExtension = "%ServiceFilter%";
	
	ExtendedArea = SpreadsheetDocument.FindText(ReplacementTextExtended);
	AreaWithoutExtension = SpreadsheetDocument.FindText(ReplacementTextWithoutExtension);
	If ExtendedArea <> Undefined Then
		ExtendedArea.Text = StrReplace(ExtendedArea.Text, ReplacementTextExtended, "");
	ElsIf AreaWithoutExtension <> Undefined Then
		AreaWithoutExtension.Text = StrReplace(AreaWithoutExtension.Text, ReplacementTextWithoutExtension, "");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Adjusts the available values for the "cost Data" data layout parameter, depending on the option.
// 
// Parameters:
//	Document - Document Link.Distribution of labor costs - a decoding document.
//	NewDCSettings - DataCompositionSettings - overriding the report settings.
//	NewDCUserSettings - DataCompositionUserSettings - data layout scheme settings.
Procedure ConfigureReportParametersByReportVariant(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	OptionsKeys = KeysOfPredefinedOptions();
	PredefinedOption = GetPredefinedOption(ReportSettings.OptionRef);
	PredefinedOptionKey = Common.ObjectAttributeValue(PredefinedOption, "VariantKey");
	If Not ValueIsFilled(PredefinedOption) 
		Or OptionsKeys.Find(PredefinedOptionKey) = Undefined Then
		Return;
	EndIf;
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("Cost_Data");
	EnterpriseParameter = DataCompositionSchema.Parameters.Find("ByEnterprise");
	
	ChoiceList = New ValueList;
	
	If PredefinedOptionKey = "DistributionOfCostsForProductionBatchesByEnterprise"
		Or PredefinedOptionKey = "GroupingOfCostsByProductionBatchesByEnterprise" Then
		
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
		ChoiceList.Add(4, NStr("vi = 'Bằng tiền tệ kế toán pháp quy';
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
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("Cost_Data"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

Function GetPredefinedOption(Val Variant)
	
	OptionsKeys = KeysOfPredefinedOptions();
	
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

Function KeysOfPredefinedOptions()
	
	OptionsKeys = New Array;
	OptionsKeys.Add("AllocationOfCostsByProductionBatches");
	OptionsKeys.Add("DistributionOfCostsForProductionBatchesByEnterprise");
	OptionsKeys.Add("CostGroupingByProductionBatches");
	OptionsKeys.Add("GroupingOfCostsByProductionBatchesByEnterprise");
	
	Return OptionsKeys;
	
EndFunction

Function GetDeletedFields()
	
	FieldsToDelete__ = New Array;
	FieldsToDelete__.Add("InitialBalanceIsTA");
	FieldsToDelete__.Add("InitialBalanceOfTD");
	FieldsToDelete__.Add("InitialBalanceOfPD");
	FieldsToDelete__.Add("SpentOnProductionOfTA");
	FieldsToDelete__.Add("SpentOnProductionOfTD");
	FieldsToDelete__.Add("SpentOnProductionOfPD");
	FieldsToDelete__.Add("ProductionCostsTA");
	FieldsToDelete__.Add("CostOfProductionOfTD");
	FieldsToDelete__.Add("CostOfProductionPD");
	FieldsToDelete__.Add("FinalBalanceIsTA");
	FieldsToDelete__.Add("FinalBalanceOfTD");
	FieldsToDelete__.Add("FinalBalanceOfPD");
	
	Return FieldsToDelete__;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("ComplexAutomation") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "ProductionOrder");
	EndIf;
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False; 
	If Not CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		FieldsToDelete__ = GetDeletedFields();
		CostCalculationAppliedAlgorithms.RestrictUseOfDCSFields(FieldsToDelete__, DataCompositionSchema,
			SettingsComposer, "", True);
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, FieldsToDelete__);
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, FieldsToDelete__, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf