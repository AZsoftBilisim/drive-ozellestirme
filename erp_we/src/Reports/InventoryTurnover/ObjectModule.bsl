
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
	Settings.Events.OnDefineSelectionParameters = True;
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
	If SettingProperties.DCField = New DataCompositionField("DataParameters.ExcludedExpensesGoodsInWarehouses") Then
		If TypeOf(SettingProperties.ValuesForSelection) = Type("ValueList") Then
			DeletedSelectionValue = SettingProperties.ValuesForSelection.FindByValue("MaterialTransferToProduction");
			If DeletedSelectionValue <> Undefined Then
				SettingProperties.ValuesForSelection.Delete(DeletedSelectionValue);
			EndIf;
		EndIf;
		
		If TypeOf(SettingProperties.Value) = Type("ValueList") Then
			ValueToDelete = SettingProperties.Value.FindByValue("MaterialTransferToProduction");
			If ValueToDelete <> Undefined Then
				SettingProperties.Value.Delete(ValueToDelete);
			EndIf;
		EndIf;
		
		If TypeOf(SettingProperties.MarkedValues) = Type("ValueList") Then
			MarkedValueToDelete = SettingProperties.MarkedValues.FindByValue("MaterialTransferToProduction");
			If MarkedValueToDelete <> Undefined Then
				SettingProperties.MarkedValues.Delete(MarkedValueToDelete);
			EndIf;
		EndIf;
	EndIf;
EndProcedure

#EndRegion
 
#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	// Checking the required parameter
	If GetFunctionalOption("UseSeveralPriceTypes") Then
		SettingPriceView = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
		If SettingPriceView.Use And Not ValueIsFilled(SettingPriceView.Value) Then
			CommonClientServer.MessageToUser(NStr("vi = 'Chưa điền trường bắt buộc ""Dạng giá"".';
													|ru = 'Не заполнено обязательное поле ""Вид цены"".';
													|en = 'Required ""Price type"" is not filled in.'; fa = 'Required ""Price type"" is not filled in.';
													|it = 'Il campo obbligatorio ""tipo di prezzo"" non è compilato.';
													|pl = 'Pole obowiązkowe ""Rodzaj ceny"" nie jest wypełnione.';
													|tr = '""Fiyat türü"" zorunlu alanı doldurulmadı.'"), , , , Cancel);
		EndIf;
	Else
		DefaultPriceType = PriceManagementSystem.PriceTypePriceList_();
		If ValueIsFilled(DefaultPriceType) Then
			DataCompositionClientServer.SetParameter(SettingsComposer, "PriceKind", DefaultPriceType);
		Else
			CommonClientServer.MessageToUser(NStr("vi = 'Hệ thống chưa cài đặt các tham số bảng giá.';
													|ru = 'В системе не настроены параметры прайс-листа.';
													|en = 'Price list parameters are not set in the application.'; fa = 'Price list parameters are not set in the application.';
													|it = 'Il sistema non ha configurato i parametri dell''elenco di prezzi.';
													|pl = 'W systemie nie skonfigurowano parametrów cennika.';
													|tr = 'Fiyat listesi parametreleri sistemde ayarlanmadı.'"), , , , Cancel);
		EndIf;
	EndIf;
	
	SettingUpPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "Period");
	SettingPeriodValue = SettingUpPeriod.Value; // StandardPeriod - 
	
	SettingFrequency = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");	
	
	If Not ValueIsFilled(SettingPeriodValue) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Trường bắt buộc ""Thời gian"" không được điền.';
												|ru = 'Не заполнено обязательное поле ""Период"".';
												|en = 'Required ""Period"" is not filled in.'; fa = 'Required ""Period"" is not filled in.';
												|it = 'Il campo obbligatorio ""Periodo"" non è stato compilato.';
												|pl = 'Pole obowiązkowe ""Okres"" nie jest wypełnione.';
												|tr = '""Dönem"" zorunlu alanı doldurulmadı.'"), , , , Cancel);
	EndIf;
	
	If Not ValueIsFilled(SettingFrequency.Value) Then
		CommonClientServer.MessageToUser(NStr("vi = 'Trường bắt buộc ""Tần suất"" không được điền.';
												|ru = 'Не заполнено обязательное поле ""Периодичность"".';
												|en = 'Required ""Frequency"" is not filled in.'; fa = 'Required ""Frequency"" is not filled in.';
												|it = 'Il campo obbligatorio ""Periodicità"" non è stato compilato.';
												|pl = 'Pole obowiązkowe ""Okresowość"" nie jest wypełnione.';
												|tr = '""Sıklık"" zorunlu alanı doldurulmadı.'"), , , , Cancel);
	EndIf;
	
	// Checking for the correctness of user-defined periods
	If ValueIsFilled(SettingPeriodValue) 
		And ValueIsFilled(SettingFrequency.Value) Then
		If Not PeriodSettingIsSetCorrectly(SettingPeriodValue.StartDate,
			SettingPeriodValue.EndDate,
			SettingFrequency.Value) Then
			
			CommonClientServer.MessageToUser(NStr("vi = 'Định kỳ tính toán cần phải nhỏ hơn kỳ báo cáo.';
													|ru = 'Периодичность расчета должна быть короче периода отчета.';
													|en = 'Periodicity of calculation should be less than the report period.'; fa = 'Periodicity of calculation should be less than the report period.';
													|it = 'La frequenza di calcolo dovrebbe essere inferiore al periodo di riferimento.';
													|pl = 'Częstotliwość obliczeń powinna być krótsza niż okres sprawozdawczy.';
													|tr = 'Hesaplama sıklığı rapor döneminden daha kısa olmalıdır.'"), , , , Cancel);
		EndIf;
	EndIf;
EndProcedure
	
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	UserSettingsModified = False;
	
	// Generate a report
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		DataCompositionClientServer.SetParameter(SettingsComposer, "PriceKind", PriceManagementSystem.PriceTypePriceList_());
	EndIf;
	
	SettingUpPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "Period");
	SettingPeriodValue = SettingUpPeriod.Value; // StandardPeriod - 
	ReportSettings = SettingsComposer.GetSettings();
	ReportSettings.AdditionalProperties.Insert("BeginOfPeriod", SettingPeriodValue.StartDate);
	ReportSettings.AdditionalProperties.Insert("EndOfPeriod", SettingPeriodValue.EndDate);
	
	// Initialization of the report table.
	DCSAuxiliaryTable = GetTemplate("DataCompositionSchemaTable");
	ReportTable = ReportDataTable(ReportSettings, DCSAuxiliaryTable);
	
	SetPrivilegedMode(True);
	
	// Initialization of the report table for the same period last year.
	HowToCompareWithSamePeriodLastYear = DataCompositionClientServer.GetParameter(SettingsComposer, "CompareWithTheSamePeriodOfThePreviousYear");
	CompareWithTheSamePeriodOfThePreviousYear = HowToCompareWithSamePeriodLastYear.Value;
	If CompareWithTheSamePeriodOfThePreviousYear Then
		
		ParameterValueForSamePeriodLastYear = DataCompositionClientServer.GetParameter(SettingsComposer, "SamePeriodOfThePreviousYear"); // DataCompositionSettingsParameterValue -
		PeriodValue_ = New StandardPeriod();
		If ParameterValueForSamePeriodLastYear <> Undefined Then
			PeriodValue_ = ParameterValueForSamePeriodLastYear.Value; // StandardPeriod - 
		EndIf;
			
		If ValueIsFilled(PeriodValue_.StartDate) Or ValueIsFilled(PeriodValue_.EndDate) Then
			BeginningOfSamePeriod = PeriodValue_.StartDate;
			EndOfSamePeriod = PeriodValue_.EndDate;
		Else
			BeginningOfSamePeriod = AddMonth(SettingPeriodValue.StartDate, -12);
			EndOfSamePeriod = AddMonth(SettingPeriodValue.EndDate, -12);
		EndIf;
		
		ReportSettings.AdditionalProperties.Insert("BeginOfPeriod", BeginningOfSamePeriod);
		ReportSettings.AdditionalProperties.Insert("EndOfPeriod", EndOfSamePeriod);
		
		// We will get data for the same period last year and load them into the report table.
		LastYearSReportTable = ReportDataTable(ReportSettings, DCSAuxiliaryTable);
		For Each ReportRow_ In ReportTable Do
			FilterForSearch = New Structure("GoodsStatus, PartnerWarehouse_, Products, Characteristic");
			FilterForSearch.Insert("GoodsStatus", ReportRow_.GoodsStatus);
			FilterForSearch.Insert("PartnerWarehouse_", ReportRow_.PartnerWarehouse_);
			FilterForSearch.Insert("Products", ReportRow_.Products);
			FilterForSearch.Insert("Characteristic", ReportRow_.Characteristic);
			
			RowsArray = LastYearSReportTable.FindRows(FilterForSearch);
			
			If RowsArray.Count() <> 0 Then
				ReportRow_.AverageBalanceForPeriodLastYear			= RowsArray[0].AverageBalanceForThePeriod;
				ReportRow_.AverageBalanceForPeriodLastYear_		= RowsArray[0].AverageBalanceForPeriodAmount;
				ReportRow_.ExpenditureForPeriodLastYear					= RowsArray[0].ExpenseForPeriod;
				ReportRow_.ExpenseForPeriodLastYear 			= RowsArray[0].ExpenseForPeriodAmount;
				ReportRow_.TurnoverLastYear					= RowsArray[0].Turnover_;
				ReportRow_.TurnoverLastYear_			= RowsArray[0].TurnoverAmount;
				ReportRow_.NumberOfIntervalsInPeriodLastYear	= RowsArray[0].NumberOfIntervalsInPeriod;
			EndIf;																  
			
		EndDo;	
		
		SamePeriodOfThePreviousYear = New StandardPeriod;
		SamePeriodOfThePreviousYear.Variant = StandardPeriodVariant.Custom;
		SamePeriodOfThePreviousYear.StartDate = BeginningOfSamePeriod;
		SamePeriodOfThePreviousYear.EndDate = EndOfSamePeriod;
		DataCompositionClientServer.SetParameter(ReportSettings, "SamePeriodOfThePreviousYear", SamePeriodOfThePreviousYear);
	EndIf;
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverLastYear",	CompareWithTheSamePeriodOfThePreviousYear);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverLastYear_",		CompareWithTheSamePeriodOfThePreviousYear);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsOfLastYear",					CompareWithTheSamePeriodOfThePreviousYear);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsOverPastYear",				CompareWithTheSamePeriodOfThePreviousYear);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverLastYearGiven",		CompareWithTheSamePeriodOfThePreviousYear);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsLastYearGiven",					CompareWithTheSamePeriodOfThePreviousYear);
	
	// Initialization of the report table for the previous period.
	SettingCompareWithPreviousPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "CompareWithThePreviousPeriod");
	CompareWithThePreviousPeriod = SettingCompareWithPreviousPeriod.Value;
	If CompareWithThePreviousPeriod Then
		
		ParameterValuePreviousPeriod = DataCompositionClientServer.GetParameter(SettingsComposer, "PreviousPeriod_"); // DataCompositionSettingsParameterValue -
		PeriodValue_ = New StandardPeriod();
		If ParameterValuePreviousPeriod <> Undefined Then
			PeriodValue_ = ParameterValuePreviousPeriod.Value; // StandardPeriod - 
		EndIf;
		
		If ValueIsFilled(PeriodValue_.StartDate) Or ValueIsFilled(PeriodValue_.EndDate) Then
			BeginningOfSamePeriod = PeriodValue_.StartDate;
			EndOfSamePeriod = PeriodValue_.EndDate;
		Else
			PeriodValue_ = PreviousPeriod_(SettingPeriodValue.StartDate, SettingPeriodValue.EndDate);
			BeginningOfSamePeriod = PeriodValue_.StartDate;
			EndOfSamePeriod = PeriodValue_.EndDate;
		EndIf;
		
		ReportSettings.AdditionalProperties.Insert("BeginOfPeriod", BeginningOfSamePeriod);
		ReportSettings.AdditionalProperties.Insert("EndOfPeriod", EndOfSamePeriod);
		
		// We will get the data for the previous period and load them into the report table.
		ReportTablePreviousPeriod = ReportDataTable(ReportSettings, DCSAuxiliaryTable);
		For Each ReportRow_ In ReportTable Do
			FilterForSearch = New Structure("GoodsStatus, PartnerWarehouse_, Products, Characteristic");
			FilterForSearch.Insert("GoodsStatus", ReportRow_.GoodsStatus);
			FilterForSearch.Insert("PartnerWarehouse_", ReportRow_.PartnerWarehouse_);
			FilterForSearch.Insert("Products", ReportRow_.Products);
			FilterForSearch.Insert("Characteristic", ReportRow_.Characteristic);
			
			RowsArray = ReportTablePreviousPeriod.FindRows(FilterForSearch);

			If RowsArray.Count() <> 0 Then
				ReportRow_.AverageBalanceForPeriodPriorPeriod 	   = RowsArray[0].AverageBalanceForThePeriod;
				ReportRow_.AverageBalanceForPeriodAmountOfPreviousPeriod  = RowsArray[0].AverageBalanceForPeriodAmount;
				ReportRow_.ExpenseForPeriodPreviousPeriod 	 		   = RowsArray[0].ExpenseForPeriod;
				ReportRow_.ExpenseForPeriodAmountOfPreviousPeriod 		   = RowsArray[0].ExpenseForPeriodAmount;
				ReportRow_.TurnoverPreviousPeriod 	 		   = RowsArray[0].Turnover_;
				ReportRow_.TurnoverAmountPreviousPeriod 		   = RowsArray[0].TurnoverAmount;
				ReportRow_.NumberOfIntervalsInPeriodPreviousPeriod = RowsArray[0].NumberOfIntervalsInPeriod;
			EndIf;																  
			
		EndDo;	
		
		DataCompositionClientServer.SetParameter(ReportSettings, "PreviousPeriod_", PeriodValue_);
	EndIf;
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverPreviousPeriod",				CompareWithThePreviousPeriod);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverAmountPreviousPeriod",			CompareWithThePreviousPeriod);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsPreviousPeriod",						CompareWithThePreviousPeriod);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsForPreviousPeriod",				CompareWithThePreviousPeriod);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "TurnoverPreviousPeriodGiven",	CompareWithThePreviousPeriod);
	SetRemoveUseFromSelectedField(ReportSettings.Selection.Items, "DynamicsOfPreviousPeriodGiven",			CompareWithThePreviousPeriod);
	
	SetPrivilegedMode(False);
	
	SettingPriceView = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	Currency = ?(ValueIsFilled(SettingPriceView.Value), String(SettingPriceView.Value.PriceCurrency), "");
	AddCurrencyToHeaderOfSelectedFields(ReportSettings.Selection.Items, Currency);
	AddCurrencyToHeaderOfSelectedDimensionFields(ReportSettings.Structure, Currency);
	
	ExternalDataSets = New Structure("ReportTable", ReportTable);
	
	// Generate a data layout layout using the layout builder.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	// Check that at least one report grouping is enabled
	If CompositionTemplate.DataSets.Count() = 0 Then
		Raise NStr("vi = 'Báo cáo không được tạo. Bao gồm ít nhất một nhóm trong các thành phần thiết kế và nhóm.';
					|ru = 'Отчет не сформирован. Включите хотя бы одну группировку в ""Элементы оформления и группировки"".';
					|en = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".'; fa = 'Report is not generated. Include at least one grouping in ""Items of appearance and grouping"".';
					|it = 'Report non generato. Includere almeno un raggruppamento in ""Elementi di progettazione e raggruppamento"".';
					|pl = 'Raport nie został wygenerowany. Dodaj, co najmniej, jedno grupowanie ""Elementy sporządzenia i grupowania"".';
					|tr = 'Rapor oluşturulmamıştır. ""Düzenleme öğeleri ve gruplandırmalar"" bölümüne en az bir gruplandırma ekle.'") ;
	EndIf;
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
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

#Region GeneratingReportData

// Prepares the main data table for report output.
//
// Parameters:
//  Settings  		   - DataCompositionSettings - Settings that are used to initialize the report table layout scheme.
//
// Returns:
//   ValueTable - A table with data.
//
Function ReportDataTable(Settings, CompositionSchema)
	AdditionalProperties = Settings.AdditionalProperties;
	
	SettingFrequency = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	Periodicity = SettingFrequency.Value;
	
	ProductStatusSettings = DataCompositionClientServer.GetParameter(SettingsComposer, "GoodsStatus");
	GoodsStatus = ProductStatusSettings.Value;
	
	// We change the text of the request - we set the necessary frequency.
	SearchText = "";
	If Periodicity = Enums.Periodicity.Year Then
		PeriodicityText = "YEAR";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		PeriodicityText = "TENDAYS";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Day Then
		PeriodicityText = "DAY";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		PeriodicityText = "QUARTER";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Month Then
		PeriodicityText = "MONTH";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.Week Then
		PeriodicityText = "WEEK";//@Query-part
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		PeriodicityText = "HALFYEAR";//@Query-part
	EndIf;
	
	SearchText = "MONTH";//@Query-part
	
	QueryDataSet = CompositionSchema.DataSets.QueryDataSet;
	QueryDataSet.Query = StrReplace(QueryDataSet.Query, SearchText, PeriodicityText);
	
	DCSSettingsTable = CompositionSchema.DefaultSettings;
	SetDCSSettings(DCSSettingsTable, Settings);
	
	// Setting the parameters.
	CurrentParameters = DCSSettingsTable.DataParameters;
	CurrentParameters.SetParameterValue("AllGoods", 			 GoodsStatus = 0);
	CurrentParameters.SetParameterValue("ProductStock", 	 GoodsStatus = 1);
	CurrentParameters.SetParameterValue("GoodsFromCommissionAgents", GoodsStatus = 2);
	
	// The parameters of the beginning of the period and the end of the period are always present - they contain the period of formation 
	// of auxiliary tables with data.
	CurrentParameters.SetParameterValue("StrtDate", AdditionalProperties.BeginOfPeriod);
	CurrentParameters.SetParameterValue("FinishDate", AdditionalProperties.EndOfPeriod);
	
	// Generate a data layout layout using the layout builder.
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(CompositionSchema, DCSSettingsTable,,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Let's create and initialize the layout processor.
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	
	// Let's create and initialize the output processor of the result.
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	ResultTable1 = New ValueTable;
	OutputProcessor.SetObject(ResultTable1);
	OutputProcessor.Output(CompositionProcessor, True);
	
	// There may be no characteristics in the table of values (according to the functional option) - we will add a column.
	If ResultTable1.Columns.Find("Characteristic") = Undefined Then
		ResultTable1.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		ResultTable1.FillValues(Catalogs.ItemsCharacteristics.EmptyRef(), "Characteristic");
		SetRemoveUseFromSelectedField(Settings.Selection.Items,, False);
		SetRemoveUsageFromDimension(Settings.Structure,, False);
	EndIf;
	// There may not be a partner in the table of values (according to the functional option) - we will add a column.
	If ResultTable1.Columns.Find("Partner") = Undefined Then
		ResultTable1.Columns.Add("Partner");
		ResultTable1.FillValues(Null, "Partner");
	EndIf;
	// ABC/XYZ may not be in the table of values (according to the functional option) - add columns.
	If ResultTable1.Columns.Find("ABC") = Undefined Then
		ResultTable1.Columns.Add("ABC");
		ResultTable1.FillValues(Enums.ABCClassification.EmptyRef(), "ABC");
	EndIf;
	If ResultTable1.Columns.Find("XYZ") = Undefined Then
		ResultTable1.Columns.Add("XYZ");
		ResultTable1.FillValues(Enums.XYZClassification.EmptyRef(), "XYZ");
	EndIf;
	
	DataTable = TableOfTurnoverIndicators(Settings, ResultTable1);
	
	Return DataTable;
EndFunction

// Calculates the required report metrics from the table.
//
// Parameters:
//  ExpandedTable - ValueTable - The table on which indicators are calculated.
//
// Returns:
//   ValueTable - A table with calculated data.
//
Function TableOfTurnoverIndicators(Settings, ExpandedTable)
	AdditionalProperties = Settings.AdditionalProperties;
	
	// Creating a data table with a column structure identical to the column structure of the expanded table.
	DataTable = ExpandedTable.Copy();
	DataTable.Clear();
	
	// Add the necessary columns.
	TableColumns1 = DataTable.Columns;
	ColumnRow = "RegulatoryTurnover, 
	|AverageBalanceForThePeriod, 					AverageBalanceForPeriodAmount, 					ExpenseForPeriod,					ExpenseForPeriodAmount, 
	|AverageBalanceForPeriodLastYear, 		AverageBalanceForPeriodLastYear_, 			ExpenditureForPeriodLastYear, 		ExpenseForPeriodLastYear,
	|AverageBalanceForPeriodPriorPeriod,	AverageBalanceForPeriodAmountOfPreviousPeriod,	ExpenseForPeriodPreviousPeriod,	ExpenseForPeriodAmountOfPreviousPeriod,
	|
	|Turnover_, 				TurnoverAmount,					NumberOfIntervalsInPeriod,
	|TurnoverLastYear,		TurnoverLastYear_,			NumberOfIntervalsInPeriodLastYear,
	|TurnoverPreviousPeriod,	TurnoverAmountPreviousPeriod,	NumberOfIntervalsInPeriodPreviousPeriod,
	|
	|DynamicsOfLastYear,				DynamicsOverPastYear,
	|DynamicsPreviousPeriod,		DynamicsForPreviousPeriod,
	|
	|TurnoverRatio,		TurnoverRatioSum,
	|TurnoverDeviation,		TurnoverDeviationAmount,
	|MediumExpense,					AverageExpenseAmount, 
	|StockLevel,					StockLevelAmount, 
	|Reserve,							ReserveAmount, 
	|
	|InventoryReplenishmentMethod, Currency, FinalBalanceAmount";

	ColumnStructure1 = New Structure(ColumnRow);
	For Each ColumnToAdd In ColumnStructure1 Do
		If TableColumns1.Find(ColumnToAdd.Key) = Undefined Then
			TableColumns1.Add(ColumnToAdd.Key);
		EndIf;	
	EndDo;
	
	ProductsTable = ExpandedTable.Copy();
	CollapseLine_ = "PartnerWarehouse_, Products, Characteristic, GoodsStatus, ABC, XYZ";
	ProductsTable.GroupBy(CollapseLine_);
	
	FilterOfProductItem = ProductsTable.Copy();
	FilterOfProductItem.GroupBy("Products, Characteristic");
	SetOfProducts  = FilterOfProductItem.UnloadColumn("Products"); 
	SetOfCharacteristics = FilterOfProductItem.UnloadColumn("Characteristic"); 
	
	SetOfWarehouses = New Array;
	SetOfWarehouses.Add(Catalogs.Warehouses.EmptyRef());
	RecruitmentOfPartners = New Array;
	RecruitmentOfPartners.Add(Catalogs.Partners.EmptyRef());
	FilterPartnerWarehouse_ = ProductsTable.Copy();
	FilterPartnerWarehouse_.GroupBy("PartnerWarehouse_");
	For Each StringSelection_ In FilterPartnerWarehouse_ Do
		If TypeOf(StringSelection_.PartnerWarehouse_) = Type("CatalogRef.Warehouses") Then
			SetOfWarehouses.Add(StringSelection_.PartnerWarehouse_);
		ElsIf TypeOf(StringSelection_.PartnerWarehouse_) = Type("CatalogRef.Partners") Then
			RecruitmentOfPartners.Add(StringSelection_.PartnerWarehouse_);
		EndIf;	
	EndDo;	
	
	ProductPriceTable			   = ProductPriceTable(Settings, FilterOfProductItem);
	TableOfConsumptionOfGoodsInWarehouses 	   = TableOfExpenditureForPeriodGoodsInWarehouses(Settings, ProductPriceTable, SetOfWarehouses, SetOfProducts, SetOfCharacteristics);
	TableOfConsumptionOfGoodsFromCommissionAgents = TableOfExpenditureForPeriodGoodsFromCommissionAgents(Settings, ProductPriceTable, RecruitmentOfPartners, SetOfProducts, SetOfCharacteristics);
	TableOfRegulatoryTurnover  = TableOfNormativeTurnoverOfGoodsInWarehouses(SetOfWarehouses, FilterOfProductItem);
	
	CalculationVariables = New Structure("
		|Products, 
		|Characteristic, 
		|Price_Table,
		|ControlPoints, 
		|TotalBalanceByQuantity, 
		|TotalAmountBalance, 
		|ClosingBalance, 
		|PointOfReference, 
		|ExcludeTheDaysWhenTheGoodsAreOutOfStock"); 
	
	SettingToExcludeDaysOfAbsenceOfGoods = DataCompositionClientServer.GetParameter(SettingsComposer, "ExcludeTheDaysWhenTheGoodsAreOutOfStock");
	
	CalculationVariables.ExcludeTheDaysWhenTheGoodsAreOutOfStock = SettingToExcludeDaysOfAbsenceOfGoods.Value;
	
	ProductPriceTable.Indexes.Add("Products, Characteristic");
	CalculationVariables.Price_Table = ProductPriceTable;
	
	SettingUpTurnoverUnit = DataCompositionClientServer.GetParameter(SettingsComposer, "UnitOfTurnover");
	UnitOfTurnover = SettingUpTurnoverUnit.Value;
	
	SettingPriceView = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	PriceKind = SettingPriceView.Value;
		
	For Each Row_Products In ProductsTable Do
		CurWarehousePartner   = Row_Products.PartnerWarehouse_;
		CurProducts   = Row_Products.Products;
		CurCharacteristic = Row_Products.Characteristic;
		CurStatusOfGoods  = Row_Products.GoodsStatus;
		CurClassABC		  = Row_Products.ABC;
		CurClassXYZ		  = Row_Products.XYZ;
		
		CalculationVariables.Products = CurProducts; 
		CalculationVariables.Characteristic = CurCharacteristic; 
				
		CalculationVariables.ControlPoints = -1; 
		CalculationVariables.TotalBalanceByQuantity = 0; 
		CalculationVariables.TotalAmountBalance = 0; 
		CalculationVariables.ClosingBalance = 0;
		
		CalculationVariables.PointOfReference	= AdditionalProperties.BeginOfPeriod;
		StartingPoint_ 			= AdditionalProperties.BeginOfPeriod;
		EndOfPeriod 					= BegOfDay(AdditionalProperties.EndOfPeriod);
		
		FilterForSearch = New Structure("PartnerWarehouse_, Products, Characteristic, GoodsStatus, ABC, XYZ");
		FilterForSearch.Insert("PartnerWarehouse_", CurWarehousePartner);
		FilterForSearch.Insert("Products", CurProducts);
		FilterForSearch.Insert("Characteristic", CurCharacteristic);
		FilterForSearch.Insert("GoodsStatus", CurStatusOfGoods);
		FilterForSearch.Insert("ABC", CurClassABC);
		FilterForSearch.Insert("XYZ", CurClassXYZ);
		
		TableOfProductData = ExpandedTable.Copy(FilterForSearch);
		TableOfProductData.Sort("Period Asc");
		For Each ProductDataRow In TableOfProductData Do
			If Not ValueIsFilled(ProductDataRow.Period) Then
				Continue;
			EndIf;
			
			If CalculationVariables.ControlPoints = -1 Then
				CalculationVariables.PointOfReference = ?(CalculationVariables.PointOfReference = Date(1, 1, 1), 
					ProductDataRow.Period, CalculationVariables.PointOfReference);
				StartingPoint_ = CalculationVariables.PointOfReference;
				CalculationVariables.ControlPoints = CalculationVariables.ControlPoints + 1;
			EndIf;
			
			While CalculationVariables.PointOfReference < ProductDataRow.Period Do
				// While the control points are located earlier than the date of the balance change, we calculate the average balance for the period.
				CalculateTotalBalanceByControlPoints(CalculationVariables);
			EndDo;
			
			CalculationVariables.ClosingBalance = ProductDataRow.ClosingBalance;
			
			CalculateTotalBalanceByControlPoints(CalculationVariables);
			
		EndDo;	
		
		// If the balance at the end of the period is zero and the Exclude the absence of the product flag is set,
		// the last checkpoint will not be taken into account in the calculation - we will fix it.
		If CalculationVariables.ClosingBalance = 0 And CalculationVariables.ExcludeTheDaysWhenTheGoodsAreOutOfStock Then
			CalculationVariables.ControlPoints = CalculationVariables.ControlPoints + 1;
		EndIf;	
		
		FinalBalanceAmount = Round(CalculationVariables.ClosingBalance 
			* ProductPrice_(CalculationVariables.Products, CalculationVariables.Characteristic, CalculationVariables.Price_Table), 2);
		
		CalculationVariables.TotalBalanceByQuantity = CalculationVariables.TotalBalanceByQuantity;
		CalculationVariables.TotalAmountBalance		 = CalculationVariables.TotalAmountBalance;
		
		NumberOfControlPoints   = CalculationVariables.ControlPoints;
		
		AverageBalanceForThePeriod = ?(NumberOfControlPoints = 0, 0, CalculationVariables.TotalBalanceByQuantity / NumberOfControlPoints);
		AverageBalanceForThePeriod = Round(AverageBalanceForThePeriod, 3);
		AverageBalanceForPeriodAmount = ?(NumberOfControlPoints = 0, 0, CalculationVariables.TotalAmountBalance / NumberOfControlPoints);
		AverageBalanceForPeriodAmount = Round(AverageBalanceForPeriodAmount, 2);
		
		FlowStructure = New Structure("Expense, ExpenseAmount_", 0, 0);
		If CurStatusOfGoods = "ProductStock" Then
			
			FlowStructure.Insert("NumberOfPeriods", 0);
			TheStructureOfTheSearch = New Structure("Warehouse, Products, Characteristic", 
				CurWarehousePartner, CalculationVariables.Products, CalculationVariables.Characteristic);
			TableRows = TableOfConsumptionOfGoodsInWarehouses.FindRows(TheStructureOfTheSearch);
			For Each TableRow In TableRows Do
				FlowStructure.Expense 			= FlowStructure.Expense 			  + TableRow.Expense;
				FlowStructure.ExpenseAmount_		= FlowStructure.ExpenseAmount_ 		  + TableRow.ExpenseAmount_;
				FlowStructure.NumberOfPeriods = FlowStructure.NumberOfPeriods + TableRow.NumberOfPeriods;
			EndDo;	
			
		ElsIf CurStatusOfGoods = "GoodsFromCommissionAgents" Then
			TheStructureOfTheSearch = New Structure("Partner, Products, Characteristic", 
				CurWarehousePartner, CalculationVariables.Products, CalculationVariables.Characteristic);
			TableRows = TableOfConsumptionOfGoodsFromCommissionAgents.FindRows(TheStructureOfTheSearch);
			For Each TableRow In TableRows Do
				FlowStructure.Expense 	 = FlowStructure.Expense 		+ TableRow.Expense;
				FlowStructure.ExpenseAmount_ = FlowStructure.ExpenseAmount_ + TableRow.ExpenseAmount_;
			EndDo;	
			
		EndIf;
		ExpenseForPeriod 		= Round(FlowStructure.Expense, 		3);
		ExpenseForPeriodAmount = Round(FlowStructure.ExpenseAmount_, 2);
		
		TurnoverRatio = ?(AverageBalanceForThePeriod = 0, 0, ExpenseForPeriod / AverageBalanceForThePeriod);
		TurnoverRatio = Round(TurnoverRatio, 3);
		TurnoverRatioSum = ?(AverageBalanceForPeriodAmount = 0, 0, ExpenseForPeriodAmount / AverageBalanceForPeriodAmount);
		TurnoverRatioSum = Round(TurnoverRatioSum, 3);
		
		FinalReferencePoint = ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, CalculationVariables.PointOfReference);
		If Not ValueIsFilled(StartingPoint_) Or Not ValueIsFilled(FinalReferencePoint) Then
			NumberOfIntervalsInPeriod = 0;
		Else
			If FlowStructure.Property("NumberOfPeriods") Then
				NumberOfIntervalsInPeriod = FlowStructure.NumberOfPeriods; // the number of intervals was calculated earlier - we use this value
			Else	
				NumberOfSecondsInPeriod = FinalReferencePoint - StartingPoint_;
				
				If UnitOfTurnover = "Day" Then
					NumberOfIntervalsInPeriod = NumberOfSecondsInPeriod / (60 * 60 * 24) + 1;
				EndIf;
			EndIf;	
		EndIf;
		Turnover_ = ?(ExpenseForPeriod = 0, 0, NumberOfIntervalsInPeriod * AverageBalanceForThePeriod / ExpenseForPeriod);
		Turnover_ = Round(Turnover_, 3);
		TurnoverAmount = ?(ExpenseForPeriodAmount = 0, 0, NumberOfIntervalsInPeriod * AverageBalanceForPeriodAmount / ExpenseForPeriodAmount);
		TurnoverAmount = Round(TurnoverAmount, 3);
		
		MediumExpense = ?(NumberOfIntervalsInPeriod = 0, 0, ExpenseForPeriod / NumberOfIntervalsInPeriod);
		MediumExpense = Round(MediumExpense, 3);
		AverageExpenseAmount = ?(NumberOfIntervalsInPeriod = 0, 0, ExpenseForPeriodAmount / NumberOfIntervalsInPeriod);
		AverageExpenseAmount = Round(AverageExpenseAmount, 2);
		
		StockLevel = ?(MediumExpense = 0, 0, CalculationVariables.ClosingBalance / MediumExpense);
		StockLevel = Round(StockLevel, 3);
		StockLevelAmount = ?(AverageExpenseAmount = 0, 0, FinalBalanceAmount / AverageExpenseAmount);
		StockLevelAmount = Round(StockLevelAmount, 3);
		
		InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.OrderAgainstOrder;
		
		RegulatoryTurnover = 0; 
		Reserve = 0; ReserveAmount = 0;
		If CurStatusOfGoods = "ProductStock" Then
			TableRows = TableOfRegulatoryTurnover.FindRows(New Structure("Warehouse, Products, Characteristic", CurWarehousePartner, CurProducts, CurCharacteristic));
			If TableRows.Count() <> 0 Then
				ProductRestrictions = TableRows[0];
				
				InventoryReplenishmentMethod = ProductRestrictions.InventoryReplenishmentMethod;
				
				If InventoryReplenishmentMethod = Enums.InventoryReplenishmentMethods.StockReplenishmentByStandard Then
					If ProductRestrictions.ConsumptionRate = 0 Then
						RegulatoryTurnover = 0;
					Else
						RegulatoryTurnover = (ProductRestrictions.MaximumInventoryAmount + ProductRestrictions.SafetyStockQuantity)/(2*ProductRestrictions.ConsumptionRate);
					EndIf;
				Else
					If MediumExpense = 0 Then
						RegulatoryTurnover = 0;
					Else
						RegulatoryTurnover = (ProductRestrictions.MaximumInventoryAmount + ProductRestrictions.SafetyStockQuantity)/(2*MediumExpense);
					EndIf;
				EndIf;
			EndIf;	
			
			Reserve = (Turnover_ - RegulatoryTurnover) * MediumExpense;
			Reserve = Round(Reserve, 3);
			Reserve = ?(Reserve < 0, 0, Reserve);
			ReserveAmount = (TurnoverAmount - RegulatoryTurnover) * AverageExpenseAmount;
			ReserveAmount = Round(ReserveAmount, 2);
			ReserveAmount = ?(ReserveAmount < 0, 0, ReserveAmount);
			
		EndIf;	
		
		If RegulatoryTurnover <> 0 Then
			TurnoverDeviation = (Turnover_ - RegulatoryTurnover) / RegulatoryTurnover * 100;
			TurnoverDeviationAmount = (TurnoverAmount - RegulatoryTurnover) / RegulatoryTurnover * 100;
			// We do not display 100% deviations in the report.
			TurnoverDeviation = ?(TurnoverDeviation = 100 Or TurnoverDeviation = -100, 0, TurnoverDeviation);
			TurnoverDeviationAmount = ?(TurnoverDeviationAmount = 100 Or TurnoverDeviationAmount = -100, 0, TurnoverDeviationAmount);
		Else
			TurnoverDeviation = 0;
			TurnoverDeviationAmount = 0;
		EndIf;	
		
		// Adding the final row to the report data table.
		NewDataLine = DataTable.Add();
		FillPropertyValues(NewDataLine, ProductDataRow);
		
		NewDataLine.FinalBalanceAmount	 	  	  = FinalBalanceAmount;
		NewDataLine.AverageBalanceForThePeriod 	  	  = AverageBalanceForThePeriod;
		NewDataLine.AverageBalanceForPeriodAmount 	  = AverageBalanceForPeriodAmount;
		NewDataLine.ExpenseForPeriod 	  		  	  = ExpenseForPeriod;
		NewDataLine.ExpenseForPeriodAmount 		 	  = ExpenseForPeriodAmount;
		NewDataLine.TurnoverRatio 	  = TurnoverRatio;
		NewDataLine.TurnoverRatioSum = TurnoverRatioSum;
		NewDataLine.Turnover_ 	  			  = Turnover_;
		NewDataLine.TurnoverAmount 			  = TurnoverAmount;
		NewDataLine.TurnoverDeviation		  = TurnoverDeviation;
		NewDataLine.TurnoverDeviationAmount  = TurnoverDeviationAmount;
		NewDataLine.NumberOfIntervalsInPeriod	  = NumberOfIntervalsInPeriod;
		NewDataLine.MediumExpense 	  			  = MediumExpense;
		NewDataLine.AverageExpenseAmount 			  = AverageExpenseAmount;
		NewDataLine.StockLevel 	  			  = StockLevel;
		NewDataLine.StockLevelAmount 			  = StockLevelAmount;
		NewDataLine.RegulatoryTurnover	  = RegulatoryTurnover;
		NewDataLine.Reserve 	  			  		  = Reserve;
		NewDataLine.ReserveAmount	 	 			  = ReserveAmount;
		
		NewDataLine.InventoryReplenishmentMethod	  = InventoryReplenishmentMethod;
		
		NewDataLine.Currency						  = ?(ValueIsFilled(PriceKind), PriceKind.PriceCurrency, Catalogs.Currencies.EmptyRef());
		
		NewDataLine.TurnoverLastYear		  			   = 0;
		NewDataLine.TurnoverLastYear_		  	   = 0;
		NewDataLine.AverageBalanceForPeriodLastYear 			   = 0;
		NewDataLine.AverageBalanceForPeriodLastYear_ 	   = 0;
		NewDataLine.ExpenditureForPeriodLastYear 	 			 	   = 0;
		NewDataLine.ExpenseForPeriodLastYear 		 	   = 0;
		NewDataLine.NumberOfIntervalsInPeriodLastYear 	   = 0;
		NewDataLine.TurnoverPreviousPeriod		 	   = 0;
		NewDataLine.TurnoverAmountPreviousPeriod		   = 0;
		NewDataLine.AverageBalanceForPeriodPriorPeriod 	   = 0;
		NewDataLine.AverageBalanceForPeriodAmountOfPreviousPeriod  = 0;
		NewDataLine.ExpenseForPeriodPreviousPeriod 	 		   = 0;
		NewDataLine.ExpenseForPeriodAmountOfPreviousPeriod 		   = 0;
		NewDataLine.NumberOfIntervalsInPeriodPreviousPeriod = 0;
	EndDo;	
	
	Return DataTable;
EndFunction

// Gets a table of expense data for the period for goods in warehouses.
//
// Parameters:
//  Price_Table	   - ValueTable - The table from which the item price is selected.
//  Warehouse  		   - Array 		 - Array of warehouses for which the expense is calculated.
//  Products   - Array 		 - Array of the item for which the expense is calculated.
//  Characteristic - Array 		 - Array of characteristics of the item for which the expense is calculated.
//
// Returns:
//   ValueTable   - A table that contains the values of the expense by quantity and amount, the number of periods.
//
Function TableOfExpenditureForPeriodGoodsInWarehouses(Settings, Price_Table, Warehouse, Products, Characteristic)
	AdditionalProperties = Settings.AdditionalProperties;
	BeginOfPeriod = AdditionalProperties.BeginOfPeriod;
	EndOfPeriod = AdditionalProperties.EndOfPeriod;

	ThisIsTradeManagement = Constants.TradeManagement.Get();
	
	SettingExcludedExpensesGoodsInWarehouses = DataCompositionClientServer.GetParameter(SettingsComposer, "ExcludedExpensesGoodsInWarehouses");
	If SettingExcludedExpensesGoodsInWarehouses.Value <> Undefined Then
		If TypeOf(SettingExcludedExpensesGoodsInWarehouses.Value) = Type("String") Then
			ArrayOfExcludedDocuments = New Array;
			ArrayOfExcludedDocuments.Add(SettingExcludedExpensesGoodsInWarehouses.Value);
		Else
			ArrayOfExcludedDocuments = SettingExcludedExpensesGoodsInWarehouses.Value.UnloadValues();
		EndIf;
		
		If ThisIsTradeManagement Then 
			ValueToDelete = ArrayOfExcludedDocuments.Find("MaterialTransferToProduction");
			If ValueToDelete <> Undefined Then
				ArrayOfExcludedDocuments.Delete(ValueToDelete);
			EndIf;
		EndIf;
		
		ThereAreExcludedCostsOfGoodsInWarehouses = ArrayOfExcludedDocuments.Count() <> 0;
	Else
		ThereAreExcludedCostsOfGoodsInWarehouses = False;
	EndIf;
	
	SettingUpDeductibleReceiptsProductsInWarehouses = DataCompositionClientServer.GetParameter(SettingsComposer, "DeductedReceiptsGoodsInWarehouses");
	If SettingUpDeductibleReceiptsProductsInWarehouses.Value <> Undefined Then
		If TypeOf(SettingUpDeductibleReceiptsProductsInWarehouses.Value) = Type("String") Then
			ArrayOfSubtractedDocuments = New Array;
			ArrayOfSubtractedDocuments.Add(SettingUpDeductibleReceiptsProductsInWarehouses.Value);
		Else 
			ArrayOfSubtractedDocuments = SettingUpDeductibleReceiptsProductsInWarehouses.Value.UnloadValues();
		EndIf;
		ThereAreDeductibleReceiptsOfGoodsInWarehouses = ArrayOfSubtractedDocuments.Count() <> 0;
	Else
		ThereAreDeductibleReceiptsOfGoodsInWarehouses = False;
	EndIf;
	
	SettingUpExcludedWarehouseOperationsInSpendingOrders = DataCompositionClientServer.GetParameter(SettingsComposer, "ExcludedOperationsInSpendingOrders");
	If SettingUpExcludedWarehouseOperationsInSpendingOrders.Value <> Undefined Then
		If TypeOf(SettingUpExcludedWarehouseOperationsInSpendingOrders.Value) = Type("String") Then
			ArrayOfExcludedWarehouseOperations = New Array;
			ArrayOfExcludedWarehouseOperations.Add(SettingUpExcludedWarehouseOperationsInSpendingOrders.Value);
		Else
			ArrayOfExcludedWarehouseOperations = SettingUpExcludedWarehouseOperationsInSpendingOrders.Value.UnloadValues();
		EndIf;
		
		ThereAreExcludedWarehouseOperationsInSpendingOrders = ArrayOfExcludedWarehouseOperations.Count() <> 0;
	Else
		ThereAreExcludedWarehouseOperationsInSpendingOrders = False;
	EndIf;
	     
	SettingUpDeductibleWarehouseOperationsInIncomingOrders = DataCompositionClientServer.GetParameter(SettingsComposer, "DeductibleOfOperationsInIncomingOrders");
	If SettingUpDeductibleWarehouseOperationsInIncomingOrders.Value <> Undefined Then
		If TypeOf(SettingUpDeductibleWarehouseOperationsInIncomingOrders.Value) = Type("String") Then
			ArrayOfDeductibleWarehouseOperations = New Array;
			ArrayOfDeductibleWarehouseOperations.Add(SettingUpDeductibleWarehouseOperationsInIncomingOrders.Value);
		Else
			ArrayOfDeductibleWarehouseOperations = SettingUpDeductibleWarehouseOperationsInIncomingOrders.Value.UnloadValues();
		EndIf;
		
		ThereAreDeductibleWarehouseOperationsInIncomingOrders = ArrayOfDeductibleWarehouseOperations.Count() <> 0;
	Else
		ThereAreDeductibleWarehouseOperationsInIncomingOrders = False;
	EndIf;
	
	MainEnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
	
	Query = New Query;
	Query.Text = RequestTextExpenseForPeriodGoodsInWarehouses();
	Query.SetParameter("StrtDate", 							   BeginOfPeriod);
	Query.SetParameter("FinishDate", 							   EndOfPeriod);
	Query.SetParameter("ThereAreExcludedCostsOfGoodsInWarehouses", ThereAreExcludedCostsOfGoodsInWarehouses);
	Query.SetParameter("ThereAreDeductibleReceiptsOfGoodsInWarehouses",  ThereAreDeductibleReceiptsOfGoodsInWarehouses);
	Query.SetParameter("ThereAreExcludedWarehouseOperationsInSpendingOrders", ThereAreExcludedWarehouseOperationsInSpendingOrders);
	Query.SetParameter("ThereAreDeductibleWarehouseOperationsInIncomingOrders", ThereAreDeductibleWarehouseOperationsInIncomingOrders);
	Query.SetParameter("MainEnterpriseCalendar",  MainEnterpriseCalendar);
	
	SettingUpToIncludeSalesForCommissionInExpenseOfGoodsInWarehouses = DataCompositionClientServer.GetParameter(SettingsComposer, "IncludeImplementationOfCommissionInExpenseOfGoodsInWarehouses");
	Query.SetParameter("IncludeImplementationOnCommission", 		   SettingUpToIncludeSalesForCommissionInExpenseOfGoodsInWarehouses.Value);
	
	// If there are excluded or subtracted documents, we will reflect them in the text of the request.
	SearchStringOrder = "&ConditionForSearchingForDeductibleExpenseItem";
	ReplacementStringOrder = "FALSE";
	SearchStringLogger	 = "&SearchConditionForDeductibleExpenseLogger";
	StringReplacementLogger	 = 
		"NOT GoodsInWarehousesTurnover.Recorder REFS Document.ReturnOfGoodsToVendor
		|AND NOT GoodsInWarehousesTurnover.Recorder REFS Document.InventoryAssignmentAdjustment";
	SearchBarWarehouseOperation	 = "&SearchConditionForDeductibleWarehouseOperationOfSpendingOrder";
	ReplacementLineWarehouseOperation	 = "TRUE";
	If ThereAreExcludedCostsOfGoodsInWarehouses Then
		ReplacementStringOrder = "";
		StringReplacementLogger	 = "NOT GoodsInWarehousesTurnover.Recorder REFS Document.InventoryAssignmentAdjustment";
		For Each DocumentName In ArrayOfExcludedDocuments Do
			If DocumentName = "InventoryConsumption" 
				Or DocumentName = "ReturnOfGoodsToVendor" 
				Or DocumentName = "InventoryTransfer"
				Or DocumentName = "MaterialTransferToProduction" 
				Or DocumentName = "CustomerInvoice" 
				Or DocumentName = "AssemblyFromComponents" Then
				// For the props, the order of the PM Goods of the document consumable supplies are checked only for its types of values!
				ReplacementStringOrder = ?(ReplacementStringOrder = "TRUE", "", ReplacementStringOrder);
				ReplacementStringOrder = ReplacementStringOrder + ?(ReplacementStringOrder = "", "", " And ") + "NOT DocumentShipments REFS Document." + DocumentName;
			Else
				ReplacementStringOrder = ?(ReplacementStringOrder = "", "TRUE", ReplacementStringOrder);
			EndIf;	
			
			StringReplacementLogger = StringReplacementLogger + ?(StringReplacementLogger = "", "", " And ") + "NOT GoodsInWarehousesTurnover.Recorder REFS Document." + DocumentName;
			
		EndDo;
	EndIf;
	
	If ThereAreExcludedWarehouseOperationsInSpendingOrders Then
		ReplacementLineWarehouseOperation = "";
		For Each WarehouseOperationName In ArrayOfExcludedWarehouseOperations Do
				ReplacementLineWarehouseOperation = ReplacementLineWarehouseOperation + ?(ReplacementLineWarehouseOperation = "", "", " And ") + "NOT CAST(GoodsInWarehousesTurnover.Recorder AS Document.GoodsIssueNote).WarehouseOperation = VALUE(Enum.WarehouseTransactions." + WarehouseOperationName + ")";		
		EndDo;
	EndIf;
	
	Query.Text = StrReplace(Query.Text, SearchStringOrder, ReplacementStringOrder);
	Query.Text = StrReplace(Query.Text, SearchStringLogger,  StringReplacementLogger);
	Query.Text = StrReplace(Query.Text, SearchBarWarehouseOperation,  ReplacementLineWarehouseOperation);
	
	SearchStringLogger	= "&SearchCriteriaForSubtractedParishes";
	StringReplacementLogger	= 
		"GoodsInWarehousesTurnover.Recorder REFS Document.ReturnOfGoodsFromCustomer
		|OR GoodsInWarehousesTurnover.Recorder REFS Document.InventoryAssignmentAdjustment";
	If ThereAreDeductibleReceiptsOfGoodsInWarehouses Then
		StringReplacementLogger	= "GoodsInWarehousesTurnover.Recorder REFS Document.InventoryAssignmentAdjustment";
		For Each DocumentName In ArrayOfSubtractedDocuments Do
			StringReplacementLogger = StringReplacementLogger + ?(StringReplacementLogger = "", "", " OR ") + "GoodsInWarehousesTurnover.Recorder REFS Document." + DocumentName;
		EndDo;	
	EndIf;
	
	SearchBarWarehouseOperation	 = "&SearchConditionForDeductibleWarehouseOperationOfIncomingOrder";
	ReplacementLineWarehouseOperation	 = "FALSE";
	If ThereAreDeductibleWarehouseOperationsInIncomingOrders Then
		ReplacementLineWarehouseOperation = "";
		For Each WarehouseOperationName In ArrayOfDeductibleWarehouseOperations Do
				ReplacementLineWarehouseOperation = ReplacementLineWarehouseOperation + ?(ReplacementLineWarehouseOperation = "", "", " OR ") + "CAST(GoodsInWarehousesTurnover.Recorder AS Document.GoodsReceiptNote).WarehouseOperation = VALUE(Enum.WarehouseTransactions." + WarehouseOperationName + ")";		
		EndDo;
	EndIf;
	
	Query.Text = StrReplace(Query.Text, SearchStringLogger,  StringReplacementLogger);
	Query.Text = StrReplace(Query.Text, SearchBarWarehouseOperation,  ReplacementLineWarehouseOperation);
	
	ResultTable1 = Query.Execute().Unload();
	For Each TableRw In ResultTable1 Do
		TableRw.ExpenseAmount_ = TableRw.Expense * ProductPrice_(TableRw.Products, TableRw.Characteristic, Price_Table);
		TableRw.Calendar   = ?(ValueIsFilled(TableRw.Calendar), TableRw.Calendar, MainEnterpriseCalendar);
	EndDo;	
	
	ProductsTable = ResultTable1.Copy();
	ProductsTable.GroupBy("Warehouse, Calendar, Products, Characteristic", "Expense, ExpenseAmount_");
	ProductsTable.Columns.Add("NumberOfPeriods");
	
	CalendarWeekends = New Map;
	
	ResultTable1.Indexes.Add("Warehouse, Products, Characteristic, BeginOfPeriod");
	
	For Each Row_Products In ProductsTable Do
		CurReferencePoint   = BegOfDay(BeginOfPeriod);
		FinalReferencePoint  = BegOfDay(EndOfPeriod);
		NumberOfPeriods	  = 0;
		CalendarData       = CalendarWeekends.Get(Row_Products.Calendar);
		While CurReferencePoint <= FinalReferencePoint Do
			
			CalendarYearData = ?(CalendarData = Undefined,
										Undefined, 
										CalendarData.Get(Number(Format(CurReferencePoint, "DF=yyyy"))));
			
			If CalendarYearData = Undefined Then
				
				ItSDayOff = Classification.ItSDayOff(
									CurReferencePoint,
									Row_Products.Calendar,
									CalendarWeekends);
				
				CalendarData = CalendarWeekends.Get(Row_Products.Calendar);
				
			Else
				ItSDayOff = CalendarYearData.Find(CurReferencePoint) <> Undefined;
			EndIf;
			
			If ItSDayOff Then
				
				ExpenditureForDayOff = 0;
				
				FilterForSearch = New Structure("Warehouse, Products, Characteristic, BeginOfPeriod");
				FilterForSearch.Insert("Warehouse", Row_Products.Warehouse);
				FilterForSearch.Insert("Products", Row_Products.Products);
				FilterForSearch.Insert("Characteristic", Row_Products.Characteristic);
				FilterForSearch.Insert("BeginOfPeriod", CurReferencePoint);
				
				ExpenseLinesForDayOff = ResultTable1.FindRows(FilterForSearch);
				For Each ExpenseLine In ExpenseLinesForDayOff Do
					ExpenditureForDayOff = ExpenditureForDayOff + ExpenseLine.Expense;
				EndDo;	
				
				If ExpenditureForDayOff > 0 Then
					// There was an expense on the day off
					NumberOfPeriods  = NumberOfPeriods + 1; 
				EndIf;;
				
			Else
				// We take into account the working day regardless of whether there was an expense on that day
				NumberOfPeriods  = NumberOfPeriods + 1; 
			EndIf;
			
			CurReferencePoint = CurReferencePoint + 60 * 60 * 24;
		EndDo;	
		Row_Products.NumberOfPeriods = NumberOfPeriods;
	EndDo;
	
	Return ProductsTable;
EndFunction

// Gets a table of expense data for the period for products from Commission agents.
//
// Parameters:
//  Settings      - DataCompositionSettings - report settings
//  Price_Table	   - ValueTable - The table from which the item price is selected.
//  Partner		   - Array		   - Array of partners for which the expense is calculated.
//  Products   - Array 		   - Array of the item for which the expense is calculated.
//  Characteristic - Array 		   - Array of characteristics of the item for which the expense is calculated.
//
// Returns:
//   ValueTable   - A table that contains the flow values by quantity and amount.
//
Function TableOfExpenditureForPeriodGoodsFromCommissionAgents(Settings, Price_Table, Partner, Products, Characteristic)
	AdditionalProperties = Settings.AdditionalProperties;
	BeginOfPeriod = AdditionalProperties.BeginOfPeriod;
	EndOfPeriod = AdditionalProperties.EndOfPeriod;
	
	SettingExcludedExpensesGoodsFromCommissionAgent = DataCompositionClientServer.GetParameter(SettingsComposer, "ExcludedExpensesGoodsFromConsignee");
	If SettingExcludedExpensesGoodsFromCommissionAgent.Value <> Undefined Then
		If TypeOf(SettingExcludedExpensesGoodsFromCommissionAgent.Value) = Type("String") Then
			ArrayOfExcludedDocuments = New Array;
			ArrayOfExcludedDocuments.Add(SettingExcludedExpensesGoodsFromCommissionAgent.Value);
		Else
			ArrayOfExcludedDocuments = SettingExcludedExpensesGoodsFromCommissionAgent.Value.UnloadValues();
		EndIf;
		ThereAreExcludedExpensesGoodsFromCommissionAgent = ArrayOfExcludedDocuments.Count() <> 0;
	Else
		ThereAreExcludedExpensesGoodsFromCommissionAgent = False;
	EndIf;
	
	Query = New Query;
	Query.Text = RequestTextExpenseForPeriodGoodsFromCommissionAgents();
	Query.SetParameter("StrtDate", 							   	   BeginOfPeriod);
	Query.SetParameter("FinishDate", 							   	   EndOfPeriod);
	Query.SetParameter("ThereAreExcludedExpensesGoodsFromCommissionAgent", ThereAreExcludedExpensesGoodsFromCommissionAgent);
	Query.SetParameter("Partner", 								   Partner);
	Query.SetParameter("Products",  		 				       Products);
	Query.SetParameter("Characteristic", 					   	   Characteristic);
	
	// If there are excluded documents, we will reflect them in the text of the request.
	SearchStringLogger	 = "&SearchCriteriaForDeductibleExpensesFromCommissionAgent";
	StringReplacementLogger	 = "NOT GoodsTransferredToCommissionTurnover.Recorder REFS Document.ReturnOfGoodsFromCustomer";
	If ThereAreExcludedExpensesGoodsFromCommissionAgent Then
		StringReplacementLogger	 = "";
		For Each DocumentName In ArrayOfExcludedDocuments Do
			StringReplacementLogger = StringReplacementLogger + ?(StringReplacementLogger = "", "", " And ") + "NOT GoodsTransferredToCommissionTurnover.Recorder REFS Document." + DocumentName;
		EndDo;	
	EndIf;
	Query.Text = StrReplace(Query.Text, SearchStringLogger,  StringReplacementLogger);
	
	ResultTable1 = Query.Execute().Unload();
	For Each TableRw In ResultTable1 Do
		TableRw.ExpenseAmount_ = TableRw.Expense * ProductPrice_(TableRw.Products, TableRw.Characteristic, Price_Table);
	EndDo;	
	
	ProductsTable = ResultTable1.Copy();
	ProductsTable.GroupBy("Partner, Products, Characteristic", "Expense, ExpenseAmount_");
	
	Return ProductsTable;
EndFunction

// Gets a data table of the standard turnover of goods by warehouse.
//
// Parameters:
//  Warehouse             - Array - Array of warehouses that the request is being made for.
//  FilterOfProductItem - ValueTable - The table of items and characteristics that the request is being made for.
//
// Returns:
//   ValueTable   - A table containing the normative turnover of the goods.
//
Function TableOfNormativeTurnoverOfGoodsInWarehouses(Warehouse, FilterOfProductItem)
	
	Query = New Query;
	Query.Text = TextOfRequestForRegulatoryTurnoverByWarehouse();
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("FilterOfProductItem", FilterOfProductItem);
	Query.TempTablesManager = New TempTablesManager;
	Query.Execute();
	TempTableManager = GenerateTTParametersForProvisionOfGoods(Query.TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text = 
		"SELECT ALLOWED
		|	TTParametersForSecuringGoods.Warehouse AS Warehouse,
		|	TTParametersForSecuringGoods.Products AS Products,
		|	TTParametersForSecuringGoods.Characteristic AS Characteristic,
		|	TTParametersForSecuringGoods.MaximumInventoryAmount AS MaximumInventoryAmount,
		|	TTParametersForSecuringGoods.SafetyStockQuantity AS SafetyStockQuantity,
		|	TTParametersForSecuringGoods.ConsumptionRate AS ConsumptionRate,
		|	TTParametersForSecuringGoods.InventoryReplenishmentMethod AS InventoryReplenishmentMethod
		|FROM
		|	TTParametersForSecuringGoods AS TTParametersForSecuringGoods
		|WHERE
		|	TTParametersForSecuringGoods.InventoryReplenishmentMethod <> VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)";
	
	ResultTable1 = Query.Execute().Unload();
	
	Return ResultTable1;
	
EndFunction

// Gets the request text for calculating the expense for the period for goods in warehouses.
//
// Returns:
//   String - query text.
//
Function RequestTextExpenseForPeriodGoodsInWarehouses()
	QueryText =
	"SELECT ALLOWED
	|	NestedQuery.Warehouse                       AS Warehouse,
	|	NestedQuery.Calendar                   AS Calendar,
	|	NestedQuery.Products                AS Products,
	|	NestedQuery.Characteristic              AS Characteristic,
	|	SUM(NestedQuery.Expense)               AS Expense,
	|	0                                           AS ExpenseAmount_,
	|	NestedQuery.Period                      AS Period,
	|	BEGINOFPERIOD(NestedQuery.Period, DAY) AS BeginOfPeriod
	|FROM
	|	(SELECT
	|		GoodsInWarehousesTurnover.Warehouse          AS Warehouse,
	|		CASE
	|			WHEN Warehouses.Calendar = VALUE(Catalog.Calendars.EmptyRef)
	|				THEN &MainEnterpriseCalendar
	|			ELSE Warehouses.Calendar
	|		END                                 AS Calendar,
	|		GoodsInWarehousesTurnover.Products   AS Products,
	|		GoodsInWarehousesTurnover.Characteristic AS Characteristic,
	|		GoodsInWarehousesTurnover.InStockExpense AS Expense,
	|		GoodsInWarehousesTurnover.SecondPeriod  AS Period
	|	FROM
	|		AccumulationRegister.ProductStock.Turnovers(&StrtDate, &FinishDate, Auto, ) AS GoodsInWarehousesTurnover
	|			LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON GoodsInWarehousesTurnover.Warehouse = Warehouses.Ref
	|	WHERE
	|		CASE
	|			WHEN NOT &ThereAreExcludedCostsOfGoodsInWarehouses
	|					THEN TRUE
	|				ELSE &SearchConditionForDeductibleExpenseLogger
	|			END
	|		AND CASE
	|			WHEN NOT &ThereAreExcludedWarehouseOperationsInSpendingOrders
	|					THEN TRUE
	|				ELSE CASE
	|						WHEN GoodsInWarehousesTurnover.Recorder REFS Document.GoodsIssueNote
	|							THEN &SearchConditionForDeductibleWarehouseOperationOfSpendingOrder
	|						ELSE TRUE 
	|					END
	|			END
	|		AND CASE
	|			WHEN &IncludeImplementationOnCommission
	|				THEN TRUE
	|			ELSE CASE
	|					WHEN GoodsInWarehousesTurnover.Recorder REFS Document.CustomerInvoice
	|						THEN CAST(GoodsInWarehousesTurnover.Recorder AS Document.CustomerInvoice).BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|					ELSE TRUE
	|				END
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ExcludedRevolutions.Warehouse            AS Warehouse,
	|		CASE
	|			WHEN Warehouses.Calendar = VALUE(Catalog.Calendars.EmptyRef)
	|				THEN &MainEnterpriseCalendar
	|			ELSE Warehouses.Calendar
	|		END                               AS Calendar,
	|		ExcludedRevolutions.Products     AS Products,
	|		ExcludedRevolutions.Characteristic   AS Characteristic,
	|		-ExcludedRevolutions.ToShipExpense AS Expense,
	|		ExcludedRevolutions.SecondPeriod    AS Period
	|	FROM
	|		AccumulationRegister.GoodsForIssue.Turnovers(&StrtDate, &FinishDate, Auto, &ConditionForSearchingForDeductibleExpenseItem) AS ExcludedRevolutions
	|			LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON ExcludedRevolutions.Warehouse = Warehouses.Ref
	|	WHERE
	|		CASE
	|			WHEN &IncludeImplementationOnCommission
	|				THEN FALSE
	|			ELSE CASE
	|					WHEN ExcludedRevolutions.DocumentShipments REFS Document.CustomerInvoice
	|						THEN CAST(ExcludedRevolutions.DocumentShipments AS Document.CustomerInvoice).BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|					ELSE FALSE
	|				END
	|		END
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsInWarehousesTurnover.Warehouse                            AS Warehouse,
	|		CASE
	|			WHEN Warehouses.Calendar = VALUE(Catalog.Calendars.EmptyRef)
	|				THEN &MainEnterpriseCalendar
	|			ELSE Warehouses.Calendar
	|		END                                                   AS Calendar,
	|		GoodsInWarehousesTurnover.Products                     AS Products,
	|		GoodsInWarehousesTurnover.Characteristic                   AS Characteristic,
	|		-1 * ISNULL(GoodsInWarehousesTurnover.InStockReceipt, 0) AS Expense,
	|		GoodsInWarehousesTurnover.SecondPeriod                    AS Period
	|	FROM
	|		AccumulationRegister.ProductStock.Turnovers(&StrtDate, &FinishDate, Auto, ) AS GoodsInWarehousesTurnover
	|			LEFT JOIN Catalog.Warehouses AS Warehouses
	|			ON GoodsInWarehousesTurnover.Warehouse = Warehouses.Ref
	|	WHERE
	|		CASE
	|			WHEN NOT &ThereAreDeductibleReceiptsOfGoodsInWarehouses
	|				THEN &ThereAreDeductibleWarehouseOperationsInIncomingOrders
	|			ELSE &SearchCriteriaForSubtractedParishes
	|		END
	|		AND CASE
	|			WHEN NOT &ThereAreDeductibleWarehouseOperationsInIncomingOrders
	|					THEN &ThereAreDeductibleReceiptsOfGoodsInWarehouses
	|				ELSE CASE
	|						WHEN GoodsInWarehousesTurnover.Recorder REFS Document.GoodsReceiptNote
	|							THEN &SearchConditionForDeductibleWarehouseOperationOfIncomingOrder
	|						ELSE FALSE 
	|					END
	|			END
	|		AND CASE
	|			WHEN GoodsInWarehousesTurnover.Recorder REFS Document.ReturnOfGoodsFromCustomer
	|				THEN CAST(GoodsInWarehousesTurnover.Recorder AS Document.ReturnOfGoodsFromCustomer).BusinessOperation <> VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			ELSE TRUE
	|		END) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Warehouse,
	|	NestedQuery.Calendar,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Period";
	
	Return QueryText;
EndFunction	

// Gets the request text for calculating the expense for the period for goods from Commission agents.
//
// Returns:
//   String - query text.
//
Function RequestTextExpenseForPeriodGoodsFromCommissionAgents()
	QueryText =
	"SELECT ALLOWED
	|	DimensionOfProductItem.Partner AS Partner,
	|	DimensionOfProductItem.Products,
	|	DimensionOfProductItem.Characteristic,
	|	SUM(ISNULL(GoodsTransferredToCommissionTurnover.CountExpense, 0)) AS Expense,
	|	0 AS ExpenseAmount_,
	|	GoodsTransferredToCommissionTurnover.Period
	|FROM
	|	Catalog.InventoryLocationAttributeKeys AS DimensionOfProductItem
	|		LEFT JOIN AccumulationRegister.GoodsTransferredToCommissionAgent.Turnovers(
	|				&StrtDate,
	|				&FinishDate,
	|				Record,
	|				ItemsLocationAttributes.Partner IN (&Partner)
	|					AND ItemsLocationAttributes.Products IN (&Products)
	|					AND ItemsLocationAttributes.Characteristic IN (&Characteristic)) AS GoodsTransferredToCommissionTurnover
	|		ON GoodsTransferredToCommissionTurnover.ItemsLocationAttributes = DimensionOfProductItem.Ref
	|WHERE
	|	CASE
	|			WHEN NOT &ThereAreExcludedExpensesGoodsFromCommissionAgent
	|				THEN TRUE
	|			ELSE &SearchCriteriaForDeductibleExpensesFromCommissionAgent
	|		END
	|
	|GROUP BY
	|	DimensionOfProductItem.Partner,
	|	DimensionOfProductItem.Products,
	|	DimensionOfProductItem.Characteristic,
	|	GoodsTransferredToCommissionTurnover.Period";
	
	Return QueryText;
EndFunction	

// Gets the text of the request for the standard turnover of goods by warehouse.
//
// Returns:
//   String - query text.
//
Function TextOfRequestForRegulatoryTurnoverByWarehouse()
	
	QueryText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO TTSelectionOfProducts
		|FROM
		|	&FilterOfProductItem AS Table
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.Ref AS Warehouse,
		|	ProductsTable.Products AS Products,
		|	ProductsTable.Characteristic AS Characteristic
		|INTO TTProducts_1
		|FROM
		|	Catalog.Warehouses AS Table
		|		LEFT JOIN TTSelectionOfProducts AS ProductsTable
		|		ON (TRUE)
		|WHERE
		|	Table.Ref IN(&Warehouse)
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTSelectionOfProducts";
	
	Return QueryText;
	
EndFunction

// Retrieves the item price table by type of report price.
//
// Parameters:
//  Settings      - DataCompositionSettings - report settings
//  FilterOfProductItem - ValueTable - The table of items and characteristics that the request is being made for.
//
// Returns:
//   ValueTable - A table containing the prices of the item.
//
Function ProductPriceTable(Settings, FilterOfProductItem)
	AdditionalProperties = Settings.AdditionalProperties;
	BeginOfPeriod = AdditionalProperties.BeginOfPeriod;
	EndOfPeriod = AdditionalProperties.EndOfPeriod;
	
	Price_Table = New ValueTable;
	SettingPriceView = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	PriceKind = SettingPriceView.Value;
	If Not ValueIsFilled(PriceKind) Then
		Return Price_Table;
	EndIf;	
	
	Query = New Query;
	Query.Text = QueryTextProductPriceTable();
	Query.SetParameter("EndOfPeriod",	EndOfPeriod);
	Query.SetParameter("PriceKind", 		PriceKind);
	Query.SetParameter("FilterOfProductItem",	FilterOfProductItem);
	
	Query.TempTablesManager = New TempTablesManager;
	ResultTable1 = Query.Execute().Unload();
	
	Return ResultTable1;
EndFunction

// Gets the text of the query to retrieve the table of item prices.
//
// Returns:
//   String - query text.
//
Function QueryTextProductPriceTable()
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		QueryText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO TTSelectionOfSubGProducts
		|FROM
		|	&FilterOfProductItem AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTSelectionOfProducts.Products AS Products,
		|	TTSelectionOfProducts.Characteristic AS Characteristic,
		|	ISNULL(CASE
		|		WHEN
		|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
		|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
		|		ELSE TTSelectionOfProducts.Characteristic.ItemsCharacteristicForPricing
		|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
		|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS PricingPackage
		|INTO TTSelectionOfProducts
		|FROM
		|	TTSelectionOfSubGProducts AS TTSelectionOfProducts
		|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|		ON ItemKinds.Ref = TTSelectionOfProducts.Products.ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ItemsPrices.PriceKind,
		|	ItemsPrices.Products,
		|	TTSelectionOfProducts.Characteristic AS Characteristic,
		|	ItemsPrices.Price / ISNULL(&RequestTextForPackingCoefficient, 1) AS Price,
		|	ItemsPrices.Currency
		|FROM
		|	InformationRegister.ItemsPrices25.SliceLast(&EndOfPeriod, PriceKind = &PriceKind
		|	AND (Products, PricingVariant, PricingBatch, PricingPackage) IN
		|		(SELECT
		|			TTSelectionOfProducts.Products,
		|			TTSelectionOfProducts.PricingVariant,
		|			TTSelectionOfProducts.PricingBatch,
		|			TTSelectionOfProducts.PricingPackage
		|		FROM
		|			TTSelectionOfProducts AS TTSelectionOfProducts)) AS ItemsPrices
		|		LEFT JOIN TTSelectionOfProducts AS TTSelectionOfProducts
		|		ON ItemsPrices.Products = TTSelectionOfProducts.Products
		|		AND ItemsPrices.PricingVariant = TTSelectionOfProducts.PricingVariant
		|
		|ORDER BY
		|	ItemsPrices.Period DESC";
	Else
		QueryText =
		"SELECT
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic
		|INTO TTSelectionOfProducts
		|FROM
		|	&FilterOfProductItem AS Table
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ItemsPrices.PriceKind,
		|	ItemsPrices.Products,
		|	ItemsPrices.Characteristic,
		|	ItemsPrices.Price / ISNULL(&RequestTextForPackingCoefficient, 1) AS Price,
		|	ItemsPrices.Currency
		|FROM
		|	InformationRegister.ItemsPrices.SliceLast(&EndOfPeriod, PriceKind = &PriceKind
		|	AND (Products, Characteristic) IN
		|		(SELECT
		|			TTSelectionOfProducts.Products,
		|			TTSelectionOfProducts.Characteristic
		|		FROM
		|			TTSelectionOfProducts AS TTSelectionOfProducts)) AS ItemsPrices
		|ORDER BY
		|	ItemsPrices.Period DESC";
	EndIf;
	
	ReplaceSubstring = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ItemsPrices.Package",
		"ItemsPrices.Products");
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", ReplaceSubstring);

	Return QueryText;
	
EndFunction	

// Gets the price of the item
//
// Parameters:
//  Products   - CatalogRef.Products  		   - The item to determine the price for.
//  Characteristic - CatalogRef.ItemsCharacteristics - A characteristic of an item, the price of which
//                                                                   you need to determine.
//  Price_Table	   - ValueTable							   - The table from which the price is selected.
//
// Returns:
//   Number 	   - The received price of the item.
//
Function ProductPrice_(Products, Characteristic, Price_Table)
	Price = 0;
	If Price_Table.Count() = 0 Then
		Return Price;
	EndIf;	
	
	Products   = ?(Products = Undefined,   Catalogs.Products.EmptyRef(),				 Products);
	Characteristic = ?(Characteristic = Undefined, Catalogs.ItemsCharacteristics.EmptyRef(), Characteristic);
	
	ArrayOfPrices = Price_Table.FindRows(New Structure("Products, Characteristic", Products, Characteristic));
	If ArrayOfPrices.Count() > 0 Then
		Price = ArrayOfPrices[0].Price;
	EndIf;
	
	Return Price;
EndFunction

#EndRegion

#Region ReportSettings

// Sets the settings (selection and parameters) ACL table based on the ACL.
//
// Parameters:
//  ReceiverSettings_  - DataCompositionSettings - Where settings are loaded.
//  SettingSource  - DataCompositionSettings - Where settings are loaded from.
//
Procedure SetDCSSettings(ReceiverSettings_, SettingSource)
	If SettingSource = Undefined Then
		Return;
	EndIf;	
	
	// Copying the selection
	StructureOfAvailableSelectionFields = New Structure;
	StructureOfAvailableSelectionFields.Insert("Warehouse");
	StructureOfAvailableSelectionFields.Insert("Partner");
	StructureOfAvailableSelectionFields.Insert("Products");
	StructureOfAvailableSelectionFields.Insert("Characteristic");
	StructureOfAvailableSelectionFields.Insert("ABC");
	StructureOfAvailableSelectionFields.Insert("XYZ");
	StructureOfAvailableSelectionFields.Insert("OnlyGoodsOfSupportedStock");
	
	FilterSource = SettingSource.Filter.Items;
	FilterReceiver = ReceiverSettings_.Filter.Items;
	FilterReceiver.Clear();
	BypassSelectionElements(StructureOfAvailableSelectionFields, FilterSource, FilterReceiver);
	
	// Setting the parameters
	DestinationParameters = ReceiverSettings_.DataParameters;
	SourceParametersElements = SettingSource.DataParameters.Items;
	
	// Resetting the values of the main parameters
	DestinationParameters.SetParameterValue("ClassificationParameterType", Enums.TypesOfClassificationParameters.EmptyRef());
	
	// Resetting the values of the decryption parameters
	DestinationParameters.SetParameterValue("Products", Catalogs.Products.EmptyRef());
	DestinationParameters.SetParameterValue("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	DestinationParameters.SetParameterValue("PartnerWarehouse_", Undefined);
	DestinationParameters.SetParameterValue("OnlyGoodsOfSupportedStock", True);
	For Each SourceParameter_ In SourceParametersElements Do
		StringParameter = String(SourceParameter_.Parameter);
		If SourceParameter_.Use Then
			ParameterValue = SourceParameter_.Value;
			If StringParameter = "Period" And TypeOf(ParameterValue) = Type("StandardPeriod") Then
				// The period in the main SKD is set using the Standard Period type
				DestinationParameters.SetParameterValue("StrtDate", ParameterValue.StartDate);
				DestinationParameters.SetParameterValue("FinishDate", ParameterValue.EndDate);
			Else
				DesiredParameter = New DataCompositionParameter(StringParameter);
				If DestinationParameters.FindParameterValue(DesiredParameter) <> Undefined Then
					DestinationParameters.SetParameterValue(DesiredParameter, ParameterValue);
				EndIf;
			EndIf;
		EndIf;
	EndDo;	
EndProcedure

#EndRegion

#Region CalculationOfIndicatorsAccordingToDataTable

// Calculates the total balance for control points and related parameters.
//
// Parameters:
//  CalculationVariables - Structure
//    Summarytabletitle - Number - Increasing the total balance by the number of control points.
//    Totalstatokposumme-Number - the Cumulative total remainder of the total for the control points.
//    Endcap-Number-the Remainder on the checkpoint date.
//    Control points-Number - Increasing number of control points.
//    Point of account 				 - The date - the Current date reference point.
//    Nomenclature-Reference Link.Item - the Item for which the total balance is calculated.
//    Feature-Reference Link.Nomenclature characteristic - a Characteristic of the nomenclature for which the total balance is calculated.
//    Value table - The table from which the item price is selected.
//
Procedure CalculateTotalBalanceByControlPoints(CalculationVariables)
	CalculationVariables.TotalBalanceByQuantity = CalculationVariables.TotalBalanceByQuantity + CalculationVariables.ClosingBalance;
	
	CalculationVariables.TotalAmountBalance 	 = CalculationVariables.TotalAmountBalance
		+ CalculationVariables.ClosingBalance 
		* ProductPrice_(CalculationVariables.Products, CalculationVariables.Characteristic, CalculationVariables.Price_Table);
		
	AddCheckpoint(CalculationVariables.ClosingBalance, CalculationVariables.ControlPoints, CalculationVariables.ExcludeTheDaysWhenTheGoodsAreOutOfStock);
	
	AddPeriod_(CalculationVariables.PointOfReference);
EndProcedure

// Adds a period to the date with the selected frequency.
//
// Parameters:
//  PointOfReference - Date - The date to add the period to.
//
Procedure AddPeriod_(PointOfReference)
	SettingFrequency = DataCompositionClientServer.GetParameter(SettingsComposer, "Periodicity");
	Periodicity = SettingFrequency.Value;
	Days1 = 60 * 60 * 24;
	
	If Periodicity = Enums.Periodicity.Year Then
		PointOfReference = AddMonth(PointOfReference, 12);
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		PointOfReference = AddMonth(PointOfReference, 6);
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		PointOfReference = AddMonth(PointOfReference, 3);
	ElsIf Periodicity = Enums.Periodicity.Month Then
		PointOfReference = AddMonth(PointOfReference, 1);
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		PointOfReference = PointOfReference + Days1 * 10;
	ElsIf Periodicity = Enums.Periodicity.Week Then
		PointOfReference = PointOfReference + Days1 * 7;
	ElsIf Periodicity = Enums.Periodicity.Day Then
		PointOfReference = PointOfReference + Days1;
	EndIf;
EndProcedure

// Adds a control point.
//
// Parameters:
//  ClosingBalance  - Number - Balance as of the checkpoint date.
//  ControlPoints - Number - Increasing number of control points.
//
Procedure AddCheckpoint(ClosingBalance, ControlPoints, ExcludeTheDaysWhenTheGoodsAreOutOfStock)
	ControlPoints = ControlPoints + 1;
	If ClosingBalance = 0 And ExcludeTheDaysWhenTheGoodsAreOutOfStock Then
		// We exclude the control point with zero remainder
		ControlPoints = ControlPoints - 1; 
	EndIf;	
EndProcedure

#EndRegion

#Region DetailProcessing

// Reads the elements of the source selection (main CDS) and download them to the items in the selection of the receiver (ACL table).
//
// Parameters:
//  StructureOfAvailableReceiverSelectionFields - Structure 					 		    - A structure containing the names of the available SCD selection fields of the receiver.
//  SelectionElementsSource 		  		   - DataCompositionFilterItemCollection - The elements of the selection source.
//  SelectionElementsReceiver  	  		   - DataCompositionFilterItemCollection - The elements of selection of the receiver.
//
Procedure BypassSelectionElements(StructureOfAvailableReceiverSelectionFields, SelectionElementsSource, SelectionElementsReceiver)
	For Each SourceFilterItem In SelectionElementsSource Do
		If SourceFilterItem.Use Then
			If TypeOf(SourceFilterItem) = Type("DataCompositionFilterItem") Then
				// Let's check if the field is available in the receiver selection. The upper parent field (separated by a dot) also needs to be checked.
				LeftValueString = String(SourceFilterItem.LeftValue);
				PointPosition = StrFind(LeftValueString, ".");
				If PointPosition <> 0 Then
					// Upper parent
					LeftValueString = Left(LeftValueString, PointPosition - 1);
				EndIf;	
				If Not StructureOfAvailableReceiverSelectionFields.Property(LeftValueString) Then
					// There is no suitable field in the available receiver selection elements
					Continue; 
				EndIf;	
				
				NewSelectionElementReceiver = SelectionElementsReceiver.Add(Type("DataCompositionFilterItem"));
				LayoutField = New DataCompositionField(String(SourceFilterItem.LeftValue));
				NewSelectionElementReceiver.LeftValue  = LayoutField;
				NewSelectionElementReceiver.ComparisonType   = SourceFilterItem.ComparisonType;
				NewSelectionElementReceiver.RightValue = SourceFilterItem.RightValue;
				NewSelectionElementReceiver.Application  	  = SourceFilterItem.Application;
				NewSelectionElementReceiver.Use  = SourceFilterItem.Use;
			ElsIf TypeOf(SourceFilterItem) = Type("DataCompositionFilterItemGroup") Then
				NewSelectionElementReceiver = SelectionElementsReceiver.Add(Type("DataCompositionFilterItemGroup"));
				NewSelectionElementReceiver.GroupType  	 = SourceFilterItem.GroupType;
				BypassSelectionElements(StructureOfAvailableReceiverSelectionFields, SourceFilterItem.Items, NewSelectionElementReceiver.Items);
				NewSelectionElementReceiver.Application  	 = SourceFilterItem.Application;
				NewSelectionElementReceiver.Use = SourceFilterItem.Use;
			Else
				Continue;
			EndIf;	
		EndIf;	
	EndDo;
EndProcedure

#EndRegion

#Region Private

// Sets / removes the use flag for the selected SCD field.
//
// Parameters:
//  SelectionElements  - DataCompositionSelectedFieldCollection - Selected field.
//  FieldName  		- String - Name of the field to analyze.
//  Use   - Boolean - Set the usage flag.
//
Procedure SetRemoveUseFromSelectedField(SelectionElements, FieldName = "Characteristic", Use = True)
	For Each ChoiceItem In SelectionElements Do
		LayoutField = New DataCompositionField(FieldName);
		If TypeOf(ChoiceItem) = Type("DataCompositionSelectedField") Then
			
			If ChoiceItem.Field = LayoutField Then
				ChoiceItem.Use = Use;
			EndIf;	
			
		ElsIf TypeOf(ChoiceItem) = Type("DataCompositionSelectedFieldGroup") Then
			
			SetRemoveUseFromSelectedField(ChoiceItem.Items, FieldName, Use);
			
		Else
			Continue;
		EndIf;	
	EndDo;
EndProcedure

// Sets/removes the use flag for the selected SKD grouping.
//
// Parameters:
//  Structure  	   - DataCompositionSettingStructureItemCollection - Structure element.
//  GroupName - String 											   - Name of the grouping to analyze.
//  Use  - Boolean											   - Set the usage flag.
//
Procedure SetRemoveUsageFromDimension(Structure, GroupName = "Characteristic", Use = True)
	For Each StructureItem In Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			LayoutField = New DataCompositionField(GroupName);
			For Each GroupingField In StructureItem.GroupFields.Items Do
				
				If TypeOf(GroupingField) = Type("DataCompositionGroupField") And
					GroupingField.Field = LayoutField Then
					GroupingField.Use = Use;
				EndIf;	
				
			EndDo;	
			
			SetRemoveUseFromSelectedField(StructureItem.Selection.Items, GroupName, Use);
			SetRemoveUsageFromDimension(StructureItem.Structure, GroupName, Use);
		EndIf;
	EndDo;
EndProcedure

// Adds the currency to the header of the selected fields.
//
// Parameters:
//  SelectionElements  - DataCompositionSelectedFieldCollection - Selected field.
//  Currency  		- String 									- Currency to add to the header.
//  FieldName  		- String 									- Name of the field to analyze.
//
Procedure AddCurrencyToHeaderOfSelectedFields(SelectionElements, Currency, FieldName = "Sum")
	If Currency = "" Then
		Return;
	EndIf;	
	
	For Each ChoiceItem In SelectionElements Do
		LayoutField = New DataCompositionField(FieldName);
		If TypeOf(ChoiceItem) = Type("DataCompositionSelectedField") Then
			If StrFind(String(ChoiceItem.Field), FieldName) <> 0 And ChoiceItem.Title = FieldName Then
				ChoiceItem.Title = ChoiceItem.Title + " (" + Currency + ")";
			EndIf;	
		ElsIf TypeOf(ChoiceItem) = Type("DataCompositionSelectedFieldGroup") Then
			AddCurrencyToHeaderOfSelectedFields(ChoiceItem.Items, Currency, FieldName);
		Else
			Continue;
		EndIf;	
	EndDo;
EndProcedure

// Adds the currency to the header of the selected grouping fields.
//
// Parameters:
//  Structure  	   - DataCompositionSettingStructureItemCollection - Structure element.
//  Currency  	   - String 											   - Currency to add to the header.
//  FieldName  	   - String 											   - Name of the field to analyze.
//
Procedure AddCurrencyToHeaderOfSelectedDimensionFields(Structure, Currency, FieldName = "Sum")
	If Currency = "" Then
		Return;
	EndIf;	
	
	For Each StructureItem In Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			AddCurrencyToHeaderOfSelectedFields(StructureItem.Selection.Items, Currency, FieldName);
			AddCurrencyToHeaderOfSelectedDimensionFields(StructureItem.Structure, Currency, FieldName);
		EndIf;
	EndDo;
EndProcedure

// Defines the previous period for the current period.
//
// Parameters:
//  StartDate 	 - Date - Start date of the current period.
//  EndDate  	 - Date - End date of the current period.
//
// Returns:
//   Structure - Structure (keys of the beginning of the period, the end of the period) containing the previous period.
//
Function PreviousPeriod_(Val StartDate, Val EndDate)
	PreviousPeriod_ = New StandardPeriod;
	PreviousPeriod_.Variant = StandardPeriodVariant.Custom;
	
	If BegOfDay(StartDate) = BegOfMonth(StartDate) And EndOfDay(EndDate) = EndOfMonth(EndDate) Then
		// The case when the period is set to a multiple of a month. Let's count the number of years and months.
		NumberOfYears 	  = Year(EndDate) - Year(StartDate);
		NumberOfMonths = Month(EndDate) - Month(StartDate) + 1;
		
		SubtractMonths = -(NumberOfMonths + NumberOfYears * 12);
		
		PreviousPeriod_.StartDate = BegOfMonth(AddMonth(StartDate, SubtractMonths));
		PreviousPeriod_.EndDate  = EndOfMonth(AddMonth(EndDate,   SubtractMonths));
	Else
		// The general case is when the period is set to a multiple of one day.
		DateDifferenceSeconds = EndDate - StartDate;
		PreviousPeriod_.StartDate = StartDate - DateDifferenceSeconds - 1;
		PreviousPeriod_.EndDate  = EndDate  - DateDifferenceSeconds - 1;
	EndIf;	
	
	Return PreviousPeriod_;
EndFunction

Function PeriodSettingIsSetCorrectly(StartDate, EndDate, Periodicity)
	SecondsPerMinute = 60;
	MinutesPerHour = 60;
	HoursPerDay = 24;
	DaysPerWeek = 7;
	DaysInDecade = 10;
	DaysPerMonth = 31;
	DaysPerQuarter = 92;
	DaysInHalfYear = 184;
	DaysYear = 366;
	
	Number_Of_DaysInPeriod = (EndDate + 1 - StartDate) / (SecondsPerMinute * MinutesPerHour * HoursPerDay);
	
	If Periodicity = Enums.Periodicity.Year Then
		Return Number_Of_DaysInPeriod >= DaysYear;
	ElsIf Periodicity = Enums.Periodicity.HalfYear Then
		Return Number_Of_DaysInPeriod >= DaysInHalfYear;
	ElsIf Periodicity = Enums.Periodicity.Quarter Then
		Return Number_Of_DaysInPeriod >= DaysPerQuarter;
	ElsIf Periodicity = Enums.Periodicity.Month Then
		Return Number_Of_DaysInPeriod >= DaysPerMonth;
	ElsIf Periodicity = Enums.Periodicity.TenDays Then
		Return Number_Of_DaysInPeriod >= DaysInDecade;
	ElsIf Periodicity = Enums.Periodicity.Week Then
		Return Number_Of_DaysInPeriod >= DaysPerWeek;
	ElsIf Periodicity = Enums.Periodicity.Day Then
		Return Number_Of_DaysInPeriod >= 1;
	Else
		Return False;
	EndIf;
EndFunction

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	// Add auxiliary report parameters 
	AuxiliaryParameters.Add("CompareWithThePreviousPeriod");
	AuxiliaryParameters.Add("CompareWithTheSamePeriodOfThePreviousYear");
	AuxiliaryParameters.Add("ExcludedExpensesGoodsInWarehouses");
	AuxiliaryParameters.Add("IncludeImplementationOfCommissionInExpenseOfGoodsInWarehouses");
	AuxiliaryParameters.Add("ExcludedExpensesGoodsFromConsignee");
	AuxiliaryParameters.Add("DeductedReceiptsGoodsInWarehouses");
	AuxiliaryParameters.Add("DisplayTurnoverChartInRelativeValues");
	AuxiliaryParameters.Add("YearNumberToCompareInTheChart");
	AuxiliaryParameters.Add("PeriodNumberToCompareInTheChart");
	
	Return AuxiliaryParameters;
EndFunction

Function GenerateTTParametersForProvisionOfGoods(TempTablesManager)
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	SupplyServer.SetParametersForStatisticsCalculationRequest(Query);
	
	SetPrivilegedMode(True);
	
	Query.Text = Catalogs.StoreFormats.QueryTextTTWarehouseFormats() +
		"SELECT
		|	T.Warehouse          AS Warehouse,
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	
		|	ISNULL(ProductRestrictions.MinimumInventoryQuantity, 0)            AS MinimumInventoryQuantity,
		|	ISNULL(ProductRestrictions.MaximumInventoryAmount, 0)           AS MaximumInventoryAmount,
		|	ISNULL(ProductRestrictions.SafetyStockQuantity, 0)              AS SafetyStockQuantity,
		|	ISNULL(ProductRestrictions.ConsumptionRate, 0)                       AS ConsumptionRate,
		|	ISNULL(ProductRestrictions.InventoryReplenishmentMethod,
		|		VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)) AS InventoryReplenishmentMethod,
		|	
		|	ISNULL(CatMethod.Ref,
		|		VALUE(Catalog.ProcurementStrategies.EmptyRef)) AS SupplyMethod
		|
		|INTO TTProductsParameters
		|FROM
		|	TTProducts_1 AS T
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction
		|		
		|		LEFT JOIN Catalog.ProcurementStrategies AS CatMethod
		|		ON &MainSupplyMethodSubstitution
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|DROP TTWarehouseFormats
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.SupplyMethod AS SupplyMethod
		|INTO SupplyMethods
		|FROM
		|	TTProductsParameters AS Goods
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.Warehouse              AS Warehouse,
		|	T.Products       AS Products,
		|	T.SupplyMethod  AS SupplyMethod
		|INTO TTItemsWarehousesAndSupplyMethods
		|FROM
		|	TTProductsParameters AS T";
		
	Query.Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Query.Text,
		"SubstituteGoodsRestriction");
	Query.Text = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(Query.Text,
		"MainSupplyMethodSubstitution");
	
	Query.Execute();
	
	ProvisionInDocumentsServer.TempTableNearestCycleBySupplyMethods(TempTablesManager);
	
	UseQualityControl = GetFunctionalOption("UseGoodsQualityControl");
	
	QueriesTexts = New Array();
	
	If UseQualityControl Then
		
		QueriesTexts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
		
		Text =
			"SELECT DISTINCT
			|	Goods.Products AS Products,
			|	Goods.Warehouse AS Warehouse,
			|	Table.Ref AS Ref,
			|	CASE
			|		WHEN Table.ShipmentDate = DATETIME(1, 1, 1)
			|			THEN DATETIME(1, 1, 1)
			|		ELSE CalculationOfControlPeriodsOverridable.DateFound
			|	END AS ShipmentDate,
			|	Table.BoundaryOfCoveredPeriod AS BoundaryOfCoveredPeriod
			|INTO NextCycleOfSupplyMethodsIsStage1
			|FROM
			|	TTItemsWarehousesAndSupplyMethods AS Goods
			|		INNER JOIN NextCycleBySupplyMethods AS Table
			|		ON Table.Ref = Goods.SupplyMethod
			|		LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE
			|INDEX BY
			|	Products, Warehouse";
			
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.ShipmentDate",
				"CASE
				|	WHEN Goods.Products.ControlQualityOfReceivedGoods
				|			AND CAST(Goods.Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
				|		THEN Goods.Products.TermOfQualityControl
				|	ELSE 0
				|END");
			
			Text = StrReplace(Text, "CalculationOfControlPeriodsOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE", Substitutions.Joins);
			
		QueriesTexts.Add(Text);
		
		Text =
			"SELECT
			|	Table.Products AS Products,
			|	Table.Warehouse AS Warehouse,
			|	Table.Ref AS Ref,
			|	Table.ShipmentDate AS ShipmentDate,
			|	CASE
			|		WHEN Table.BoundaryOfCoveredPeriod = DATETIME(1, 1, 1)
			|			THEN DATETIME(1, 1, 1)
			|		ELSE CalculationOfControlPeriodsOverridable.DateFound 
			|	END AS BoundaryOfCoveredPeriod
			|INTO NextCycleOnSupplyMethodsTakingIntoAccountQualityControl
			|FROM
			|	NextCycleOfSupplyMethodsIsStage1 AS Table
			|		LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE
			|INDEX BY
			|	Ref, Products, Warehouse";
			
			Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
				"Table.BoundaryOfCoveredPeriod",
				"CASE
				|	WHEN Table.Products.ControlQualityOfReceivedGoods
				|			AND CAST(Table.Warehouse AS Catalog.Warehouses).ControlQualityOfReceivedGoods
				|		THEN Table.Products.TermOfQualityControl
				|	ELSE 0
				|END");
			
			Text = StrReplace(Text, "CalculationOfControlPeriodsOverridable.DateFound", Substitutions.Field);
			Text = StrReplace(Text, "LEFT JOIN CalculationOfControlPeriodsOverridable ON TRUE", Substitutions.Joins);
			
		QueriesTexts.Add(Text);
		
	EndIf;
	
	Text =
		// Calendars where to look for the delivery date and the period provided.
		"SELECT DISTINCT
		|	Set.Calendar AS Calendar,
		|	Set.PeriodStartDate AS PeriodStartDate,
		|	Set.PeriodEndDate AS PeriodEndDate,
		|	Set.YearOfStartInterval AS YearOfStartInterval,
		|	Set.YearOfEndOfInterval AS YearOfEndOfInterval
		|INTO ToSearchForNumberOfDaysInInterval
		|FROM(
		|	SELECT
		|		CASE
		|			WHEN ISNULL(CAST(Table.Warehouse AS Catalog.Warehouses).Calendar,
		|					VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|				THEN MainEnterpriseCalendar.Value
		|			ELSE CAST(Table.Warehouse AS Catalog.Warehouses).Calendar
		|		END AS Calendar,
		|		&CurrentDayStart PeriodStartDate,
		|		Method.ShipmentDate PeriodEndDate,
		|		YEAR(&CurrentDayStart) AS YearOfStartInterval,
		|		YEAR(Method.ShipmentDate) AS YearOfEndOfInterval
		|FROM
		|	TTItemsWarehousesAndSupplyMethods AS Table
		|		
		|		INNER JOIN NextCycleBySupplyMethods AS Method
		|		ON Method.Ref = Table.SupplyMethod
		|		AND &GoodsConnectionQualityControl
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|WHERE
		// Calculation of warehouse working days, to calculate the minimum stock.
		|	Method.ShipmentDate > DATETIME(1, 1, 1)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		CASE
		|			WHEN ISNULL(CAST(Table.Warehouse AS Catalog.Warehouses).Calendar,
		|					VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|				THEN MainEnterpriseCalendar.Value
		|			ELSE CAST(Table.Warehouse AS Catalog.Warehouses).Calendar
		|		END AS Calendar,
		|		Method.ShipmentDate PeriodStartDate,
		|		Method.BoundaryOfCoveredPeriod PeriodEndDate,
		|		YEAR(Method.ShipmentDate) AS YearOfStartInterval,
		|		YEAR(Method.BoundaryOfCoveredPeriod) AS YearOfEndOfInterval
		|FROM
		|	TTItemsWarehousesAndSupplyMethods AS Table
		|		
		|		INNER JOIN NextCycleBySupplyMethods AS Method
		|		ON Method.Ref = Table.SupplyMethod
		|		AND &GoodsConnectionQualityControl
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|WHERE
		// Calculation of workdays of the warehouse, between the date of delivery and the border of the secured period
		|		Method.ShipmentDate > DATETIME(1, 1, 1)
		|			AND Method.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)) AS Set
		|INDEX BY
		|	Calendar, YearOfStartInterval, YearOfEndOfInterval";
		
	GoodsConnectionQualityControl = "TRUE";
	If UseQualityControl Then
		GoodsConnectionQualityControl =
		"(Method.Products = Table.Products
		|AND Method.Warehouse = Table.Warehouse)";
		Text = StrReplace(Text, "NextCycleBySupplyMethods", "NextCycleOnSupplyMethodsTakingIntoAccountQualityControl");
	EndIf;
	Text = StrReplace(Text, "&GoodsConnectionQualityControl", GoodsConnectionQualityControl);
	
	QueriesTexts.Add(Text);
	QueriesTexts.Add(ProvisionInDocumentsServer.TempTableResultsOfCalculationOfNumberOfDaysInInterval());
	
	Text =
		"SELECT
		|	T.Warehouse          AS Warehouse,
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic
		|INTO TTProductsByStatistics
		|FROM
		|	TTProductsParameters AS T
		|WHERE
		|	T.InventoryReplenishmentMethod = VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics)";
		
	QueriesTexts.Add(Text);
	
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("CurrentDayStart", BegOfDay(CurrentSessionDate()));
	Query.Execute();
	
	SupplyServer.AddTemporaryTableOfConsumptionStatistics(Query, "TTProductsByStatistics");
	
	Query.Text =
		"SELECT
		|	T.Products   AS Products,
		|	T.Characteristic AS Characteristic,
		|	T.Warehouse          AS Warehouse,
		|	
		|	T.SupplyMethod                              AS ProcurementStrategy,
		|	T.InventoryReplenishmentMethod                   AS InventoryReplenishmentMethod,
		|	T.ConsumptionRate                               AS ConsumptionRate,
		|	ISNULL(Statistics.AverageDailyConsumption, 0) AS AverageDailyConsumption,
		|	T.SafetyStockQuantity                      AS SafetyStockQuantity,
		|	ISNULL(CASE T.InventoryReplenishmentMethod
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax) THEN T.MaximumInventoryAmount
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard) THEN T.ConsumptionRate * 
		|			CASE
		|				WHEN IntervalBetweenDeliveries.DaysCount IS NULL
		|					AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|					AND TableOfSecurityMethods.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)
		|					THEN DATEDIFF(TableOfSecurityMethods.ShipmentDate, TableOfSecurityMethods.BoundaryOfCoveredPeriod, DAY)
		|				ELSE ISNULL(IntervalBetweenDeliveries.DaysCount, 0)
		|			END
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics) THEN Statistics.AverageDailyConsumption *
		|			CASE
		|				WHEN IntervalBetweenDeliveries.DaysCount IS NULL
		|					AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|					AND TableOfSecurityMethods.BoundaryOfCoveredPeriod > DATETIME(1, 1, 1)
		|					THEN DATEDIFF(TableOfSecurityMethods.ShipmentDate, TableOfSecurityMethods.BoundaryOfCoveredPeriod, DAY)
		|				ELSE ISNULL(IntervalBetweenDeliveries.DaysCount, 0)
		|			END
		|		ELSE 0
		|	END, 0)                                        AS MaximumInventoryAmount,
		|	ISNULL(CASE T.InventoryReplenishmentMethod
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentMinMax) THEN T.MinimumInventoryQuantity
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStandard) THEN T.ConsumptionRate *
		|			CASE
		|				WHEN IntervalBeforeDeliveryDate.DaysCount IS NULL AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|					THEN DATEDIFF(&CurrentDayStart, TableOfSecurityMethods.ShipmentDate, DAY)
		|				ELSE ISNULL(IntervalBeforeDeliveryDate.DaysCount, 0)
		|			END
		|		WHEN VALUE(Enum.InventoryReplenishmentMethods.StockReplenishmentByStatistics) THEN ISNULL(Statistics.AverageDailyConsumption, 0) *
		|			CASE
		|				WHEN IntervalBeforeDeliveryDate.DaysCount IS NULL AND TableOfSecurityMethods.ShipmentDate > DATETIME(1, 1, 1)
		|					THEN DATEDIFF(&CurrentDayStart, TableOfSecurityMethods.ShipmentDate, DAY)
		|				ELSE ISNULL(IntervalBeforeDeliveryDate.DaysCount, 0)
		|			END
		|		ELSE 0
		|	END, 0)                                        AS MinimumInventoryQuantity
		|INTO TTParametersForSecuringGoods
		|FROM
		|	TTProductsParameters AS T
		|		LEFT JOIN TTConsumptionStatistics AS Statistics
		|		ON T.Products = Statistics.Products
		|			AND T.Characteristic = Statistics.Characteristic
		|			AND T.Warehouse = Statistics.Warehouse
		|		
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON TRUE
		|		
		|		LEFT JOIN NextCycleBySupplyMethods AS TableOfSecurityMethods
		|		ON TableOfSecurityMethods.Ref = T.SupplyMethod
		|		
		|		LEFT JOIN ResultsOfCalculatingNumberOfDaysInInterval AS IntervalBeforeDeliveryDate
		|		ON IntervalBeforeDeliveryDate.Calendar =
		|			CASE
		|				WHEN ISNULL(CAST(T.Warehouse AS Catalog.Warehouses).Calendar,
		|						VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN MainEnterpriseCalendar.Value
		|				ELSE CAST(T.Warehouse AS Catalog.Warehouses).Calendar
		|			END
		|		 AND IntervalBeforeDeliveryDate.PeriodStartDate = &CurrentDayStart
		|		 AND IntervalBeforeDeliveryDate.PeriodEndDate = TableOfSecurityMethods.ShipmentDate
		|
		|		LEFT JOIN ResultsOfCalculatingNumberOfDaysInInterval AS IntervalBetweenDeliveries
		|		ON IntervalBetweenDeliveries.Calendar =
		|			CASE
		|				WHEN ISNULL(CAST(T.Warehouse AS Catalog.Warehouses).Calendar,
		|						VALUE(Catalog.Calendars.EmptyRef)) = VALUE(Catalog.Calendars.EmptyRef)
		|					THEN MainEnterpriseCalendar.Value
		|				ELSE CAST(T.Warehouse AS Catalog.Warehouses).Calendar
		|			END
		|		 AND IntervalBetweenDeliveries.PeriodStartDate = TableOfSecurityMethods.ShipmentDate
		|		 AND IntervalBetweenDeliveries.PeriodEndDate = TableOfSecurityMethods.BoundaryOfCoveredPeriod";
	
	GoodsConnectionQualityControl = "TRUE";
	If UseQualityControl Then
		GoodsConnectionQualityControl =
		"(T.Products = TableOfSecurityMethods.Products
		|AND T.Warehouse = TableOfSecurityMethods.Warehouse)";
		Query.Text = StrReplace(Query.Text, "NextCycleBySupplyMethods", "NextCycleOnSupplyMethodsTakingIntoAccountQualityControl");
	EndIf;
	Query.Text = StrReplace(Query.Text, "&GoodsConnectionQualityControl", GoodsConnectionQualityControl);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

#EndRegion

#EndIf
