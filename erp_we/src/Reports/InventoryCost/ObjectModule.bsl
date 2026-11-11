#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Report.InventoryCost.ObjectModule.OnComposeResult");
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	MonitoringUseOfTurnoverAnalytics(SettingsComposer);
	// Disables the detail selection if the report is being built for less than a month(s).
	CheckAndSetDetailOutputParameter(SettingsComposer, ResultDocument);
	
	DefaultParameters = New Structure;
	Reports.InventoryCost.AddDefaultParameters(DefaultParameters);
	
	For Each Parameter In DefaultParameters Do//Z2
		DataCompositionClientServer.SetParameter(SettingsComposer, Parameter.Key, Parameter.Value);
	EndDo;
	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);//Z2
	
	ReportSettings = SettingsComposer.GetSettings();
	
	RemoveMetricsFromDecryptionSelections(SettingsComposer, ReportSettings);
	DeletePriceIndicatorsFromSelectedDecryptionFields(SettingsComposer, ReportSettings);
	
	If ResourceSelectionsAreUsed(ReportSettings.Filter.Items, ResultDocument) Then
		Return;
	EndIf;
	
	ReportSettings.DataParameters.SetParameterValue("CustomFieldExpressionOpeningBalance",
		NStr("vi = 'Số dư đầu';
			|ru = 'Начальный остаток';
			|en = 'Opening balance'; fa = 'مانده ابتدای دوره';
			|it = 'Saldo iniziale';
			|pl = 'Saldo początkowe';
			|tr = 'Açılış bakiyesi'"));
	ReportSettings.DataParameters.SetParameterValue("UserFieldExpressionTotalInpayment",
		NStr("vi = 'Tổng số nhập';
			|ru = 'Всего приход';
			|en = 'Total receipt'; fa = 'کل دریافت';
			|it = 'Totale entrata';
			|pl = 'Razem przychodów';
			|tr = 'Giriş toplamı'"));
	ReportSettings.DataParameters.SetParameterValue("UserFieldExpressionTotalExpense",
		NStr("vi = 'Tổng số xuất';
			|ru = 'Всего расход';
			|en = 'Total expenses'; fa = 'جمع هزینه‌ها';
			|it = 'Totale uscita';
			|pl = 'Razem rozchodów';
			|tr = 'Gider toplamı'"));
	ReportSettings.DataParameters.SetParameterValue("CustomFieldExpressionClosingBalance",
		NStr("vi = 'Số dư cuối';
			|ru = 'Конечный остаток';
			|en = 'Closing balance'; fa = 'مانده پایان دوره';
			|it = 'Saldo finale';
			|pl = 'Saldo końcowe';
			|tr = 'Kapanış bakiyesi'"));
		
	PeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "Period").Value; // StandardPeriod
	If Not ValueIsFilled(PeriodParameter.EndDate) Then
		PeriodOfRecentRegisteredRecords = BatchAccountingServer.PeriodOfLastRegisteredRecordsOfRegisterCost();   
		PeriodParameter.EndDate = Min(CurrentSessionDate(), PeriodOfRecentRegisteredRecords);
		ReportSettings.DataParameters.SetParameterValue("Period", PeriodParameter);
	EndIf;
	
	ArrayOfCDFieldsUsed = New Array();
	CostCalculationAppliedAlgorithms.AddSelectedDataLayoutFieldsToArray(ReportSettings.Selection.Items,
		ArrayOfCDFieldsUsed);
	CostCalculationAppliedAlgorithms.ReplacePathInSelectedDataLayoutField(ArrayOfCDFieldsUsed,
		"DimensionOfProductItem.Products.UnitOfMeasure",
		"DimensionOfProductItem.Products.ReportUnitOfMeasurement");
		
	EnableDisplayOfGroupOfResourceFieldsForAdditionalExpenseAmounts(ReportSettings.Structure);
	
	QueryText = QueryText();
	
	DataSet = DataCompositionSchema.DataSets.CostWithDetails; // DataCompositionSchemaDataSetUnion
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
	
	// Let's check whether the turnover analysts are used
	DataCompositionServer.OptimizingUseOfReverseAnalytics(CompositionTemplate, DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfFieldHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	FieldsToCheck = New Array;
	FieldsToCheck.Add("Partner");
	FieldsToCheck.Add("Manager");
	FieldsToCheck.Add("Department");
	FieldsToCheck.Add("SalesOpportunity");
	
	CostCalculationAppliedAlgorithms.AddWarningAboutReportGenerationFeatures(
		ResultDocument,
		SettingsComposer,
		FieldsToCheck,
		False,  // Update batches
		"BusinessStructure.Organization");
	
	CostCalculationAppliedAlgorithms.UpdateBatchesForReports(
		ResultDocument,
		SettingsComposer,
		"BusinessStructure.Organization");
		
	CostCalculationAppliedAlgorithms.AddWarningAboutPreClosingMonth(ResultDocument, SettingsComposer, "BusinessStructure.Organization");
	
	DetailOutputControl(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.CreateReportDiagrams(SettingsComposer, ResultDocument);
	
	AuxiliaryParameters = New Array;
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(
		DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryParameters);
	DataCompositionServer.HideAuxiliaryReportParameters(
		DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ResultDocument.TableHeight);
	
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
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeLoadVariantAtServer = True;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportParametersByReportVariant(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
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
	
	CostCalculationAppliedAlgorithms.DeleteUnusedReportDimensions(NewDCSettings, UnusedReportFields());
	
EndProcedure

#EndRegion

#Region Private

Procedure EnableDisplayOfGroupOfResourceFieldsForAdditionalExpenseAmounts(CollectionOfElementsOfCDSettingsStructure)
	
	For Each CDSettingsStructureElement In CollectionOfElementsOfCDSettingsStructure Do
		If CDSettingsStructureElement.UserSettingPresentation = NStr("vi = 'Chi tiết đến chi phí gốc';
																	|ru = 'Детализация до исходных затрат';
																	|en = 'Itemize up to initial costs'; fa = 'تفکیک تا هزینه‌های اولیه';
																	|it = 'Specificazione fino alle spese iniziali';
																	|pl = 'Szczegóły do kosztów źródłowych';
																	|tr = 'Birincil maliyetlerden önce ayrıntılar'") Then
			If CDSettingsStructureElement.Use = False Then
				Return;
			EndIf;
			
			KD_IndicatorsAdditionalExpensesAmountField = New DataCompositionField("Indicators.AddExpensesForGoods");
			SelectedCDElements = CDSettingsStructureElement.Selection.Items;
			For Each Item In SelectedCDElements Do
				If TypeOf(Item) = Type("DataCompositionSelectedFieldGroup")
					And Item.Field = KD_IndicatorsAdditionalExpensesAmountField Then
					
					SelectedCDElements.Delete(Item);
					Return;
				EndIf;
			EndDo;
			Return;
		
		ElsIf TypeOf(CDSettingsStructureElement) = Type("DataCompositionGroup")
			And TypeOf(CDSettingsStructureElement.Structure) = Type("DataCompositionSettingStructureItemCollection") Then
			
			EnableDisplayOfGroupOfResourceFieldsForAdditionalExpenseAmounts(CDSettingsStructureElement.Structure);
		EndIf;
	EndDo;
	
EndProcedure

Procedure MonitoringUseOfTurnoverAnalytics(Var_SettingsComposer)
	Groups = DataCompositionClientServer.GetGroupings(Var_SettingsComposer);
	
	For Each Group In Groups Do
		FieldGrouping = Group.Value.GroupFields; // DataCompositionGroupFields
		GroupFields = FieldGrouping.Items;
		NumberOfRevolutionAnalysisFields = 0;
		For Each GroupingField In GroupFields Do 
			If Find(String(GroupingField.Field), "TurnoverDimension") >0 Then
				NumberOfRevolutionAnalysisFields = NumberOfRevolutionAnalysisFields + 1; 
			EndIf;
			If NumberOfRevolutionAnalysisFields > 1 Then
				Raise NStr("vi = 'Không hỗ trợ sử dụng nhiều trường đối tượng phân tích phát sinh trong gom nhóm.';
							|ru = 'Множественное использование полей аналитики оборотов в группировках не поддерживается.';
							|en = 'Multiple usage of turnover dimension fields is not supported in groupings.'; fa = 'Multiple usage of turnover dimension fields is not supported in groupings.';
							|it = 'L''uso multiplo dei campi di analisi del fatturato nei raggruppamenti non è supportato.';
							|pl = 'Wielokrotne użycie pól analityki obrotów w grupowaniach nie jest obsługiwane.';
							|tr = 'Boyut alanlarının gruplamalardaki cirolarının çoklu kullanımı desteklenmiyor.'") ;
			EndIf;
		EndDo;
		If NumberOfRevolutionAnalysisFields >= 1 And GroupFields.Count() > 1 Then
			Raise NStr("vi = 'Không hỗ trợ sử dụng chung trong gom nhóm trường đối tượng phân tích phát sinh và các trường khác.';
						|ru = 'Совместное использование в группировках полей аналитики оборотов и других полей не поддерживается.';
						|en = 'You cannot use both turnover dimension field and other fields together in groupings.'; fa = 'You cannot use both turnover dimension field and other fields together in groupings.';
						|it = 'La condivisione nei raggruppamenti dei campi di analisi del fatturato e di altri campi non è supportata.';
						|pl = 'Łączne użycie w grupowaniach pól analitycznych obrotów oraz innych pól nie jest obsługiwane.';
						|tr = 'Boyut alanlarının gruplamalardaki cirolarının birlikte kullanımı ve diğer alanlar desteklenmiyor.'") ;
		EndIf;
	EndDo;
EndProcedure

// The function of checking the availability of resource fields in selections.
//
// Parameters:
//	FilterItems1 - DataCompositionFilterItemCollection - report selection elements
//	ResultDocument - SpreadsheetDocument - the main tabular document of the report
//
// Returns:
//	Boolean - indicates whether there are selections by resource fields.
//
Function ResourceSelectionsAreUsed(FilterItems1, ResultDocument)
	
	HasFilter = False;
	
	ResourceFieldsWithSelections = New Array;
	
	For Each ResultsField In DataCompositionSchema.TotalFields Do
		
		FilterField = New DataCompositionField(ResultsField.DataPath);
		
		If DataCompositionClientServer.SelectionIsUsed_(FilterItems1, FilterField, True) Then
			ResourceFieldsWithSelections.Add(ResultsField.DataPath);
		EndIf;
		
	EndDo;
	
	If ResourceFieldsWithSelections.Count() > 0 Then 
		DisplayWarningAboutResourceSelection(ResultDocument, ResourceFieldsWithSelections);
		HasFilter = True;
	EndIf;
	
	Return HasFilter;
	
EndFunction

// The procedure for displaying a warning in a tabular document.
//
// Parameters:
//	ResultDocument - SpreadsheetDocument - the main tabular document of the report
//	FieldList - Array - array of strings with field names
//	
Procedure DisplayWarningAboutResourceSelection(ResultDocument, FieldList)
	
	WarningText = NStr("vi = 'Trong báo cáo ""Giá vốn hàng hóa"" không hỗ trợ bộ lọc chung theo chỉ tiêu giá trị và số lượng đối với toàn bộ báo cáo (tùy chỉnh báo cáo - thẻ ""Lọc"").
								|Cần chuyển bộ lọc này vào bộ lọc gom nhóm (tùy chỉnh báo cáo -> thẻ ""Cấu trúc"" -> nút ""Nâng cao"" phía dưới cửa sổ tùy chỉnh -> mở gom nhóm cụ thể và đặt bộ lọc trên thẻ ""Lọc"").
								|Cần thêm bộ lọc trong tất cả gom nhóm được đánh dấu để hiển thị trong báo cáo (đánh dấu bởi hộp kiểm trên thẻ ""Cấu trúc"").
								|Gom nhóm ""Chi tiết đến chi phí gốc"" không hỗ trợ lọc theo số lượng.
								|
								|Cần tắt bộ lọc theo các trường sau hoặc chuyển đến gom nhóm:';
								|ru = 'В отчете ""Себестоимость товаров"" не поддерживаются общие отборы по количественным и стоимостным показателям для всего отчета (настройки отчета - закладка ""Фильтры"").
								|Такие отборы следует перенести в отборы группировок (настройки отчета -> закладка ""Структура"" -> кнопка ""Расширенный"" внизу окна настроек -> открыть конкретную группировку и установить отбор на закладке ""Фильтры"").
								|Отборы необходимо добавить во всех группировках, отмеченных для вывода в отчете (отмечены галочками на закладке ""Структура"").
								|Группировка ""Детализация до исходных затрат"" не поддерживает отборы по количеству.
								|
								|Отборы по следующим полям неоходимо отключить или перенести в группировки:';
								|en = 'The Inventory cost report does not support common filters by quantity and cost for the entire report (the Filters tab in the report settings).
								|Move such filters to grouping filters. Go to the report settings, open the Structure tab, and click Advanced at the bottom of the settings window. Open a grouping and set a filter on the Filters tab.
								|Add the filters in all the groupings marked for display in the report. These groupings are selected on the Structure tab.
								|The Itemize up to initial costs grouping does not support filters by quantity.
								|
								|Disable filters by the following fields or move them to groupings:'; fa = 'The Inventory cost report does not support common filters by quantity and cost for the entire report (the Filters tab in the report settings).
								|Move such filters to grouping filters. Go to the report settings, open the Structure tab, and click Advanced at the bottom of the settings window. Open a grouping and set a filter on the Filters tab.
								|Add the filters in all the groupings marked for display in the report. These groupings are selected on the Structure tab.
								|The Itemize up to initial costs grouping does not support filters by quantity.
								|
								|Disable filters by the following fields or move them to groupings:';
								|it = 'Nel report ""Prezzo di costo delle merci"" non sono supportati i filtri comuni per indicatori di quantità e prezzo per tutto il report (impostazioni report - scheda ""Filtri"").
								|Questi filtri devono essere spostati nei filtri di raggruppamento (impostazioni report -> scheda ""Struttura"" -> pulsante ""Esteso"" in basso nella finestra delle impostazioni -> aprire il raggruppamento concreto e impostare il filtro nella scheda ""Filtri"").
								|I filtri devono essere aggiunti in tutti i raggruppamenti contrassegnati per la visualizzazione nel report (contrassegnati nella scheda ""Struttura"").
								| Il raggruppamento ""Dettaglio fino ai costi iniziali"" non supporta i filtri per quantità.
								|
								|I filtri per i seguenti campi devono essere disattivati o spostati nei raggruppamenti:';
								|pl = 'W raporcie ""Koszt własny towarów"" nie są obsługiwane ogólne filtry według wskaźników ilościowych i wartościowych dla całego raportu (ustawienia raportu - zakładka ""Filtry"").
								|Takie filtry należy przenieść do filtrów zgrupowań (ustawienia raportu -> zakładka ""Struktura"" -> przycisk ""Rozszerzony"" w dolnej części okna ustawień -> otwórz konkretne zgrupowanie i ustaw filtr na zakładce ""Filtry"").
								|Filtry należy dodać do wszystkich zgrupowań, zaznaczonych do wyświetlenia w raporcie (są zaznaczone flagami na zakładce ""Struktura"").
								|Zgrupowanie ""Szczegóły do kosztów źródłowych"" nie obsługuje filtry według ilości.
								|
								|Filtry według następujących pól należy wyłączyć lub przenieść do zgrupowania:';
								|tr = '""Ürünlerin maliyeti"" raporunda nicelik olarak ortak filtreler ve tüm raporlar için değer göstergeleri desteklenmiyor (rapor ayarları - ""Filtreler"" sekmesi).
								|Böyle filtrelerin gruplama filtrelerindeki yerleri değiştirilmeli (rapor ayarları -> ""Yapılandırma"" sekmesi -> ayarlar penceresinin altındaki ""Gelişmiş"" düğmesi -> somut gruplamayı açın ve ""Filtreler"" sekmesine filtre kurun).
								|Sekmelerin tüm gruplamalara eklenmeleri ve raporların sonuçlarının işaretlenmeleri gerekli (""Yapılandırma"" sekmesindeki kutucukların işaretlenmeleri).
								|""İlk giderler öncesinin detaylandırılması"" nitelik filtrelerini desteklemiyor.
								|
								|Sonraki alanlardaki filtrelerin seçilmelerine veya gruplamalara transfer edilmelerine gerek yoktur:'");
	
	For Each Field In FieldList Do
		WarningText = WarningText + Chars.LF
			+ StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = ' - %1';
							|ru = ' - %1';
							|en = ' - %1'; fa = ' - %1';
							|it = ' - %1';
							|pl = ' - %1';
							|tr = ' - %1'"),
						Field);
	EndDo; 
		
	WarningTable_ = New SpreadsheetDocument;
	AreaWarning = WarningTable_.Area(1,1,1,1);
	
	AreaWarning.Text 	 = WarningText;
	AreaWarning.TextColor = StyleColors.NegativeTextColor;
	
	ResultDocument.InsertArea(
		AreaWarning,
		ResultDocument.Area(1,1,1,1),
		SpreadsheetDocumentShiftType.Vertical);
	
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
	
	If PredefinedOption.VariantKey = "CostOfGoodsForEnterprise"
	 Or PredefinedOption.VariantKey = "CostOfGoodsForOperationsOnEnterprise"
	 Or PredefinedOption.VariantKey = "EnterprisePurchaseTrends" Then
		
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
		ChoiceList.Add(4, NStr("vi = 'Theo tiền tệ kế toán tài chính';
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
	
	OptionsKeys = New Array;
	OptionsKeys.Add("CostOfGoodsBasic");
	OptionsKeys.Add("CostOfGoodsForOperationsBasic");
	OptionsKeys.Add("EnterprisePurchaseTrends");
	OptionsKeys.Add("CompanyPurchaseTrends");
	OptionsKeys.Add("CostOfGoodsByOrganization");
	OptionsKeys.Add("CostOfGoodsForOperationsByOrganizations");
	OptionsKeys.Add("CostOfGoodsForEnterprise");
	OptionsKeys.Add("CostOfGoodsForOperationsOnEnterprise");
	
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

Function QueryText()
	
	QueryTexts = New Array;
	QueryTexts.Add(Reports.InventoryCost.TempTablesQueryText());
	QueryTexts.Add(Reports.InventoryCost.QueryTextSamples());
	
	Return StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndFunction

// The procedure for checking the period and setting the parameter "Display"
//
// Parameters:
//	Var_SettingsComposer - DataCompositionSettingsComposer - Report Settings builder.
//	ResultDocument - SpreadsheetDocument - the main tabular document of the report.
Procedure CheckAndSetDetailOutputParameter(Var_SettingsComposer, ResultDocument)
	
	PeriodParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Period").Value; // StandardPeriod
	
	BeginOfPeriod = PeriodParameter.StartDate;
	EndOfPeriod  = PeriodParameter.EndDate;
	
	DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Output_Details", True);
	
	// Let's check the beginning and end of the period. They must coincide with the beginning and end of the months on which they fall.
	If BeginOfPeriod = BegOfMonth(BeginOfPeriod) And EndOfPeriod = EndOfMonth(EndOfPeriod) Then
		Return;	
	EndIf;
	
	// If the period doesn't cover months completely, we'll check the use of detail in dimensions.
	Groups = DataCompositionClientServer.GetGroupings(Var_SettingsComposer);
	NumberOfAnalyticsFieldsForAdditionalExpenses = 0;
	For Each Group In Groups Do
		// We check only active groupings.
		If Not Group.Value.Use Then
			Continue;
		EndIf;
		FieldGrouping = Group.Value.GroupFields; // DataCompositionGroupFields
		GroupFields = FieldGrouping.Items;
		For Each GroupingField In GroupFields Do 
			If Find(String(GroupingField.Field), "AdditionalCostAnalytics") > 0 Then
				NumberOfAnalyticsFieldsForAdditionalExpenses = NumberOfAnalyticsFieldsForAdditionalExpenses + 1; 
			EndIf;
		EndDo;
	EndDo; 
	
	// If at least 1 grouping by detail fields is used, we disable the selection of data by detail.
	If NumberOfAnalyticsFieldsForAdditionalExpenses >= 1 Then
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "Output_Details", False);
	EndIf;

EndProcedure

// The procedure for controlling the parameter "Display the customization".
//
// Parameters:
//	ResultDocument - SpreadsheetDocument - the main tabular document of the report.
Procedure DetailOutputControl(ResultDocument)
	
	Output_Details = DataCompositionClientServer.GetParameter(SettingsComposer, "Output_Details").Value; 
	
	If Not Output_Details Then
		DisplayWarningAboutUseOfGranularityAndIncompletePeriod(ResultDocument);	
	EndIf;
	
EndProcedure

// The procedure for displaying a warning in a tabular document.
//
// Parameters:
//	ResultDocument - SpreadsheetDocument - the main tabular document of the report.
Procedure DisplayWarningAboutUseOfGranularityAndIncompletePeriod(ResultDocument)
	
	WarningText = NStr("vi = 'Báo cáo ""Giá vốn hàng hóa"" không hỗ trợ gom nhóm theo chi tiết đến chi phí ban đầu (các trường từ nhóm ""Đối tượng phân tích chi phí bổ sung""),
								|khi tạo báo cáo cho (các) tháng thiếu. 
								|Để hiển thị gom nhóm theo chi tiết đến chi phí ban đầu, bạn nên chọn khoảng thời gian bao gồm cả (các) tháng đầy đủ.';
								|ru = 'В отчете ""Себестоимость товаров"" не поддерживается группировка по детализации до исходных затрат (поля из группы ""Аналитика доп. расходов""), 
								|при формировании отчета за неполный месяц(-ы). 
								|Для вывода группировки по детализации до исходных затрат следует выбрать период, который включает в себя месяц(-ы) полностью.';
								|en = 'The ""Inventory cost"" report does not support grouping by itemization up to initial costs (fields from the ""Dimension (Additional expenses)"" group) 
								|when the report is generated for a part of the month(s). 
								|To display grouping by itemization up to initial costs, select a period that includes the whole month(s).'; fa = 'The ""Inventory cost"" report does not support grouping by itemization up to initial costs (fields from the ""Dimension (Additional expenses)"" group) 
								|when the report is generated for a part of the month(s). 
								|To display grouping by itemization up to initial costs, select a period that includes the whole month(s).';
								|it = 'В отчете ""Себестоимость товаров"" не поддерживается группировка по детализации до исходных затрат (поля из группы ""Аналитика доп. расходов""), 
								|при формировании отчета за неполный месяц(-ы). 
								|Для вывода группировки по детализации до исходных затрат следует выбрать период, который включает в себя месяц(-ы) полностью.';
								|pl = 'The ""Inventory cost"" report does not support grouping by itemization up to initial costs (fields from the ""Dimension (Additional expenses)"" group) 
								|when the report is generated for a part of the month(s). 
								|To display grouping by itemization up to initial costs, select a period that includes the whole month(s).';
								|tr = '""Stok maliyeti"" raporu, kısmi ay(lar) için rapor oluştururken kaynak giderler (Ek giderler boyutu grubundaki alanlar) kapsamındaki detaylandırmaya göre
								|gruplandırmayı desteklememektedir.
								|Detaylandırmaya göre gruplandırmayı kaynak giderlerine çıkarmak için ay(lar)ı tamamen içeren bir dönem seçmelisiniz.'");
	
	WarningTable_ = New SpreadsheetDocument;
	AreaWarning = WarningTable_.Area(1,1,1,1);
	
	AreaWarning.Text 	 = WarningText;
	AreaWarning.TextColor = StyleColors.NegativeTextColor;
	
	ResultDocument.InsertArea(
		AreaWarning,
		ResultDocument.Area(1,1,1,1),
		SpreadsheetDocumentShiftType.Vertical);
	
EndProcedure

#Region ConfiguringReportParameters

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	CurrentVariantKey = "";
	If SettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey", CurrentVariantKey) Then
		If Not CurrentVariantKey = "PurchasingDynamics" Then
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

Function StructureOfFieldHeaders()
	StructureOfFieldHeaders = New Structure;
	
	StructureOfUnitFieldHeaders_ = DataCompositionServer.UnitFieldHeaders(SettingsComposer);
	CommonClientServer.SupplementStructure(StructureOfFieldHeaders, StructureOfUnitFieldHeaders_, False);
	
	Return StructureOfFieldHeaders;
EndFunction

Procedure RemoveMetricsFromDecryptionSelections(Var_SettingsComposer, ReportSettings)
	If Var_SettingsComposer.FixedSettings.AdditionalProperties.Property("DetailsMode")
		And Var_SettingsComposer.FixedSettings.AdditionalProperties.DetailsMode Then
		Indicators = New Array;
		Indicators.Add("Indicators.Count.CountOpeningBalance");
		Indicators.Add("Indicators.Count.CountReceipt");
		Indicators.Add("Indicators.Count.CountExpense");
		Indicators.Add("Indicators.Count.CountClosingBalance");
		Indicators.Add("Indicators.Weight.WeightOpeningBalance");
		Indicators.Add("Indicators.Weight.WeightReceipt");
		Indicators.Add("Indicators.Weight.WeightExpense");
		Indicators.Add("Indicators.Weight.WeightClosingBalance");
		Indicators.Add("Indicators.VolumeM3.VolumeM3OpeningBalance");
		Indicators.Add("Indicators.VolumeM3.VolumeM3Receipt");
		Indicators.Add("Indicators.VolumeM3.VolumeM3Expense");
		Indicators.Add("Indicators.VolumeM3.VolumeM3ClosingBalance");
		Indicators.Add("Indicators.CostOfAdmission.CostOfAdmissionOpeningBalance");
		Indicators.Add("Indicators.CostOfAdmission.CostOfAdmissionReceipt");
		Indicators.Add("Indicators.CostOfAdmission.CostOfAdmissionExpense");
		Indicators.Add("Indicators.CostOfAdmission.CostOfAdmissionClosingBalance");
		Indicators.Add("Indicators.AddExpensesForGoods.AddExpensesForGoodsOpeningBalance");
		Indicators.Add("Indicators.AddExpensesForGoods.AddExpensesForGoodsReceipt");
		Indicators.Add("Indicators.AddExpensesForGoods.AddExpensesForGoodsExpense");
		Indicators.Add("Indicators.AddExpensesForGoods.AddExpensesForGoodsClosingBalance");
		Indicators.Add("Indicators.LaborCosts.LaborCostsOpeningBalance");
		Indicators.Add("Indicators.LaborCosts.LaborCostsReceipt");
		Indicators.Add("Indicators.LaborCosts.LaborCostsExpense");
		Indicators.Add("Indicators.LaborCosts.LaborCostsClosingBalance");
		Indicators.Add("Indicators.ItemizedFixed.ItemizedFixedOpeningBalance");
		Indicators.Add("Indicators.ItemizedFixed.ItemizedFixedReceipt");
		Indicators.Add("Indicators.ItemizedFixed.ItemizedFixedExpense");
		Indicators.Add("Indicators.ItemizedFixed.ItemizedFixedClosingBalance");
		Indicators.Add("Indicators.ItemizedVariable.ItemizedVariableOpeningBalance");
		Indicators.Add("Indicators.ItemizedVariable.ItemizedVariableReceipt");
		Indicators.Add("Indicators.ItemizedVariable.ItemizedVariableExpense");
		Indicators.Add("Indicators.ItemizedVariable.ItemizedVariableClosingBalance");
		Indicators.Add("Indicators.Cost_.Cost_OpeningBalance");
		Indicators.Add("Indicators.Cost_.Cost_Receipt");
		Indicators.Add("Indicators.Cost_.Cost_Expense");
		Indicators.Add("Indicators.Cost_.Cost_ClosingBalance");
		Indicators.Add("Indicators.TaxAccounting.TaxAccountingOpeningBalance");
		Indicators.Add("Indicators.TaxAccounting.TaxAccountingReceipt");
		Indicators.Add("Indicators.TaxAccounting.TaxAccountingExpense");
		Indicators.Add("Indicators.TaxAccounting.TaxAccountingClosingBalance");
		Indicators.Add("Indicators.PermanentDifference.PermanentDifferenceOpeningBalance");
		Indicators.Add("Indicators.PermanentDifference.PermanentDifferenceReceipt");
		Indicators.Add("Indicators.PermanentDifference.PermanentDifferenceExpense");
		Indicators.Add("Indicators.PermanentDifference.PermanentDifferenceClosingBalance");
		Indicators.Add("Indicators.CostTD.CostTDOpeningBalance");
		Indicators.Add("Indicators.CostTD.CostTDReceipt");
		Indicators.Add("Indicators.CostTD.CostTDExpense");
		Indicators.Add("Indicators.CostTD.CostTDClosingBalance");
		Indicators.Add("Indicators.AIT.AITOpeningBalance");
		Indicators.Add("Indicators.AIT.AITReceipt");
		Indicators.Add("Indicators.AIT.AITExpense");
		Indicators.Add("Indicators.AIT.AITClosingBalance");
		Indicators.Add("Indicators.OffBalanceSheetValue.OffBalanceCostOpeningBalance");
		Indicators.Add("Indicators.OffBalanceSheetValue.OffBalanceCostReceipt");
		Indicators.Add("Indicators.OffBalanceSheetValue.OffBalanceCostExpense");
		Indicators.Add("Indicators.OffBalanceSheetValue.OffBalanceCostClosingBalance");
		
		For Each Factor In Indicators Do 
			DataCompositionServer.RemoveSelectionItemFromAllReportSettings(ReportSettings, Factor);
		EndDo;
	EndIf;
EndProcedure

Procedure DeletePriceIndicatorsFromSelectedDecryptionFields(Var_SettingsComposer, ReportSettings)
	If Var_SettingsComposer.FixedSettings.AdditionalProperties.Property("DetailsMode")
		And Var_SettingsComposer.FixedSettings.AdditionalProperties.DetailsMode Then
		Indicators = New Array;
		Indicators.Add("Indicators.ReceiptPrice.ReceiptPriceOpeningBalance");
		Indicators.Add("Indicators.ReceiptPrice.ReceiptPriceReceipt");
		Indicators.Add("Indicators.ReceiptPrice.ReceiptPriceExpense");
		Indicators.Add("Indicators.ReceiptPrice.ReceiptPriceClosingBalance");
		Indicators.Add("Indicators.AveragePrice.AveragePriceOpeningBalance");
		Indicators.Add("Indicators.AveragePrice.AveragePriceReceipt");
		Indicators.Add("Indicators.AveragePrice.AveragePriceExpense");
		Indicators.Add("Indicators.AveragePrice.AveragePriceClosingBalance");
		
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(ReportSettings, Indicators);
	EndIf;
EndProcedure

Function UnusedReportFields()
	
	FieldArray = New Array;


	FieldArray.Add("VATIsIncludedInCostOfProducts");
	FieldArray.Add("ProductCostElementArticle");
	FieldArray.Add("DetailingCostOfProductsOpeningBalance");
	FieldArray.Add("DetailingCostOfProductsClosingBalance");
	FieldArray.Add("DetailingCostOfProductsReceipt");
	FieldArray.Add("DetailingCostOfProductsExpense");
	
	Return FieldArray;
	
EndFunction

#EndRegion 

#EndRegion 

#EndIf
