#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The procedure fills in the tabular part of the preview according to the rule of filling in the planning data sources,
// is intended to be filled in the background.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//  StorageAddressAdditional - String
//
Procedure FillInPreview(Val Parameters, Val StorageAddress, Val StorageAddressAdditional = "") Export
	
	Settings = Common.CommonSettingsStorageLoad(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID);
	
	If TypeOf(Settings) <> Type("Structure") Then
		
		Return;
		
	EndIf;
	
	Parameters.Insert("TimeIntervals", Settings.TimeIntervals);
	
	Parameters.Insert("FillingRule", Settings.FillingRule);
	Parameters.Insert("UserSettings", Settings.UserSettings);
	Parameters.Insert("PopulatedTS", Settings.PopulatedTS);
	
	FillInAccordingToTheFillingRule(Parameters, StorageAddress);
	
	SetPrivilegedMode(True);
	Common.CommonSettingsStorageDelete(Parameters.GeneralSettingsKey, 
		"BackgroundJobSettings_"+Parameters.UUID, Users.CurrentUser());
	
EndProcedure


// The procedure fills in the preview according to the filling rule from various sources.
//
// Parameters:
//  Parameters  - Structure - Settings to fill in:
//  	* PopulatedTS - ValueTable -
//  	* TimeIntervals See Planning.TablePeriods
//  StorageAddress - String - The address of the temporary storage where the result of the task will be placed
//
Procedure FillInAccordingToTheFillingRule(Val Parameters, Val StorageAddress) Export
	
	PeriodColumnName = "Date";
	
	TimeIntervals = Parameters.TimeIntervals;
	
	FoundPeriodStrings = TimeIntervals.FindRows(New Structure("Active_", True));
	TotalPeriods = FoundPeriodStrings.Count();
	If Parameters.CrossTable And TotalPeriods = 0 Then 
		
		Return;
		
	EndIf;
	
	Coefficients = New Array;
	For IndexOf = 1 To TotalPeriods Do
		Coefficients.Add(1);
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataParameters", Planning.GetPlanParameters(Parameters));
	If Parameters.Property("Filter") Then
		AdditionalParameters.Insert("Filter", Parameters.Filter);
	EndIf;
	AdditionalParameters.Insert("Top25", Parameters.Top25);
	
	If ValueIsFilled(Parameters.ChangeResultTo) Then
		
		AdditionalParameters.DataParameters.Insert("ZoomRatio", (100 + Parameters.ChangeResultTo) / 100);
		
	EndIf;
	
	If Parameters.Property("RoundingPrecision") Then
		AdditionalParameters.DataParameters.Insert("RoundingPrecision", Parameters.RoundingPrecision);
	EndIf;
	
	FillingRule = Parameters.FillingRule;
	UserSettings = Parameters.UserSettings;
	
	
	Result = Planning.SelectDataByRules(
		Parameters.PlanType, 
		FillingRule, 
		UserSettings, 
		AdditionalParameters);
	
	PopulatedTS = Parameters.PopulatedTS;
	
	If Result <> Undefined Then
		
		BitRounding = Parameters.RoundingPrecision + 3;
		
		For Each ResultString1 In Result Do
			
			If ResultString1.Count = null Then
				Continue;
			EndIf;
			
			If Int(ResultString1.Count * Pow(10, BitRounding)) = 0 Then
				
				Continue;
				
			EndIf;
			
			Count = Round(ResultString1.Count, BitRounding);
			
			If Parameters.CrossTable Then
				
				If ValueIsFilled(ResultString1.Period) 
					And ResultString1.Period >= Parameters.BeginOfPeriod 
					And ResultString1.Period <= Parameters.PeriodEnding Then
					
					// It is not necessary to distribute by periods
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = ResultString1.Period;
					
					Continue;
					
				ElsIf ValueIsFilled(ResultString1.Period) Then
					// Exclude the line because it does not fall within the specified period of the plan
					Continue;
					
				EndIf; 
				
				If ResultString1.Count < 0 Then
					QuantitySign = -1;
				Else
					QuantitySign = 1;
				EndIf;
				
				QuantityDistribution = Planning.DistributeAmountInProportionToCoefficients(QuantitySign * ResultString1.Count, Coefficients, BitRounding);
				If QuantityDistribution = Undefined Then
					Continue;
				EndIf; 
				
				// With a uniform distribution, the remainder of the rounding is subtracted from the first element, so we reset it if it went into negative.
				If QuantityDistribution[0] < 0 Then
					QuantityDistribution[0] = 0;
				EndIf;
				
				// The distribution is made starting from the last element, because the first one may be smaller than the others.
				IndexOf = QuantityDistribution.UBound();
				While IndexOf >= 0 Do
				
					Count = QuantityDistribution[IndexOf];
					PeriodDate_ = FoundPeriodStrings[FoundPeriodStrings.UBound() - IndexOf].StartDate;
					IndexOf = IndexOf - 1;
					
					If Count = 0 Then
						Continue;
					EndIf;
					
					NewRow = PopulatedTS.Add();
					FillPropertyValues(NewRow, ResultString1);
					
					NewRow.Count = QuantitySign * Count;
					NewRow.NumberOfPackages = NewRow.Count;
					NewRow[PeriodColumnName] = PeriodDate_;
					
				EndDo; 
				
			Else
				
				NewRow = PopulatedTS.Add();
				FillPropertyValues(NewRow, ResultString1);
				NewRow.Count = Count;
				NewRow.NumberOfPackages = NewRow.Count;
				NewRow[PeriodColumnName] = ResultString1.Period;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	PutToTempStorage(PopulatedTS, StorageAddress);
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	SearchString = Undefined;
	ChoiceFoldersAndItems = Undefined;
	
	Parameters.Property("SearchString", SearchString);
	
	If SearchString = Undefined Then
		
		SearchString = "";
		
	EndIf;
	
	Parameters.Property("ChoiceFoldersAndItems", ChoiceFoldersAndItems);
	
	If ChoiceFoldersAndItems = Undefined Then
		
		ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems;
		
	EndIf;
	
	StandardProcessing = False;
	ChoiceData = New ValueList();
	
	Query = New Query(
	"SELECT ALLOWED
	|	PlanningDataSources.Ref AS Value,
	|	REFPRESENTATION(PlanningDataSources.Ref) AS Presentation,
	|	PlanningDataSources.DeletionMark AS DeletionMark,
	|	PlanningDataSources.SettingOfFilterByPeriod AS SettingOfFilterByPeriod
	|FROM
	|	Catalog.PlanningDataSources AS PlanningDataSources
	|WHERE
	|	(PlanningDataSources.IsFolder
	|				AND &Groups
	|			OR NOT PlanningDataSources.IsFolder
	|				AND &Items)
	|	AND PlanningDataSources.Description LIKE &SearchString");
	
	Query.SetParameter("Groups", ChoiceFoldersAndItems = FoldersAndItemsUse.Folders 
		Or ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems);
	Query.SetParameter("Items", ChoiceFoldersAndItems = FoldersAndItemsUse.Items 
		Or ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems);
	Query.SetParameter("SearchString", SearchString + "%");
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		
		While Selection.Next() Do
			
			StructureValue = New Structure("Value, SettingOfFilterByPeriod", 
				Selection.Value, Selection.SettingOfFilterByPeriod);
			ChoiceStructure = New Structure("Value", StructureValue);
			
			If Selection.DeletionMark Then
				
				ChoiceStructure.Insert("DeletionMark", Selection.DeletionMark);
				
			EndIf;
			
			ChoiceData.Add(ChoiceStructure, Selection.Presentation);
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Other

// Enables the use of dimensions in the settings and user settings of the report.
//
// Parameters:
//  DataCompositionSettings - DataCompositionSettings
//  TagName  - String - name of the element to be included.
//
Procedure EnableGroupingInAllReportSettings(DataCompositionSettings, TagName)
	
	If TypeOf(DataCompositionSettings) = Type("DataCompositionSettingsComposer") Then
		Settings = DataCompositionSettings.Settings;
		UserSettings = DataCompositionSettings.UserSettings;
	Else	
		Return
	EndIf;
	
	SearchValue  = New DataCompositionField(TagName);
	MatchingElements = New Map;
	
	GroupingStructure   = Settings.Structure;
	FindGroupingRecursively(GroupingStructure, MatchingElements, SearchValue);
	For Each Group In MatchingElements Do
		Group.Value.Use = True;
	EndDo;
	
	MatchingElements = New Map;
	
	For Each Item In UserSettings.Items Do
		If TypeOf(Item) = Type("DataCompositionSettingStructure") Then
			StructureOfDimensionsUserSettings = Item.Structure;
			FindGroupingRecursively(StructureOfDimensionsUserSettings, MatchingElements, SearchValue);
			For Each Group In MatchingElements Do
				Group.Value.Use = True;
			EndDo;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FindGroupingRecursively(ItemsCollection, MatchingElements, SearchValue)
	For Each Item In ItemsCollection Do
		If TypeOf(Item) = Type("DataCompositionGroup") Then
			For Each GroupingField In Item.GroupFields.Items Do 
				If GroupingField.Field = SearchValue Then
					MatchingElements.Insert(Item, GroupingField)
				EndIf;
			EndDo;
			FindGroupingRecursively(Item.Structure, MatchingElements, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionTable") Then
			FindGroupingRecursively(Item.Rows, MatchingElements, SearchValue);
			FindGroupingRecursively(Item.Columns, MatchingElements, SearchValue);
		ElsIf TypeOf(Item) = Type("DataCompositionChart") Then
			FindGroupingRecursively(Item.Series, MatchingElements, SearchValue);
			FindGroupingRecursively(Item.Points, MatchingElements, SearchValue);
		EndIf;
	EndDo;
EndProcedure

// Parameters:
// 	DataSourceParameters - Structure - Where:
// 	 * PlanningDataSource - CatalogRef.PlanningDataSources -
// 	UserSettings - DataCompositionUserSettings - 
// 	AdditionalParameters - Structure - Content:
//    * Period - StandardPeriod - 
// 	DataCompositionSettingsComposer - DataCompositionSettingsComposer -
// Returns:
// 	ValueTable - LongDesc:
// * Count - Number -
Function SubstringData(DataSourceParameters, UserSettings, AdditionalParameters, DataCompositionSettingsComposer = Undefined) Export
	
	// The circuit layout data
	Attributes = Common.ObjectAttributesValues(DataSourceParameters.PlanningDataSource, 
		"DCSTemplateName, DataCompositionSchema, StorageOfDataCompositionSettings, SettingOfFilterByPeriod");
	If ValueIsFilled(Attributes.DCSTemplateName) Then
		DataCompositionSchema = LayoutSchemeByTemplateName(Attributes.DCSTemplateName);
		If DataCompositionSchema = Undefined Then
			DataCompositionSchema = Attributes.DataCompositionSchema.Get();
		EndIf; 
	Else
		DataCompositionSchema = Attributes.DataCompositionSchema.Get();
	EndIf;
	
	SubstitutionOfMainMethodOfSupplyAndBalances(DataCompositionSchema);
	SettingOfFilterByPeriod = Attributes.SettingOfFilterByPeriod;
	
	If DataSourceParameters.Property("ChangeResultTo") 
		And ValueIsFilled(DataSourceParameters.ChangeResultTo) Then
		
		ZoomRatio = (100 + DataSourceParameters.ChangeResultTo) / 100;
		
		// Adding predefined parameters and setting values.
		NewParameter1 = DataCompositionSchema.Parameters.Add();
		NewParameter1.Name = "ZoomRatio";
		NewParameter1.ValueType = New TypeDescription("Number");
		NewParameter1.Value = ZoomRatio;
		NewParameter1.UseRestriction = False;
		NewParameter1.Use = DataCompositionParameterUse.Always;
		
		For Each TotalField In DataCompositionSchema.TotalFields Do
			If Not (TotalField.DataPath = "Price" Or TotalField.DataPath = "Count") Then
				Continue;
			EndIf;
			TotalField.Expression = TotalField.Expression+" * &ZoomRatio";
			
		EndDo;
		
	EndIf; 
	
	// Loading Settings
	DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
	DataCompositionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(DataCompositionSchema));
	
	Try
		DataCompositionSettings = Attributes.StorageOfDataCompositionSettings.Get();
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong nguồn điền dữ liệu ""%1"" có lỗi trong tùy chỉnh. Để quy tắc điền hoạt động chính xác, cần tạo mới nguồn tương tự như nguồn hiện tại.';
				|ru = 'В источнике заполнения данных ""%1"" имеются ошибки в настройках. Для корректной работы правила заполнения необходимо создать новый источник аналогичный текущему.';
				|en = 'There are errors in the settings in the ""%1"" data filling source. Create a new source similar to the current one for the correct operation of the filling rule.'; fa = 'There are errors in the settings in the ""%1"" data filling source. Create a new source similar to the current one for the correct operation of the filling rule.';
				|it = 'Nell''origine di compilazione dati ""%1"" vi sono errori di impostazioni. Per il corretto funzionamento della regola di compilazione è necessario creare una nuova origine analoga alla corrente.';
				|pl = 'Źródło wypełnienia danych ""%1."" zawiera błędy w ustawieniach. Aby reguła wypełnienia działała poprawnie należy utworzyć nowe źródło podobne do bieżącego.';
				|tr = 'Kaynakta ""%1"" verisinin doldurulması esnasında ayarlarda hata meydana geldi. Doldurma kuralının doğru çalışması için mevcut kaynağa benzer yeni bir kaynak oluşturmak gerekiyor.'"), DataSourceParameters.PlanningDataSource);
	EndTry;
	
	If DataCompositionSettings <> Undefined Then
		DataCompositionSettingsComposer.LoadSettings(DataCompositionSettings);
	Else
		DataCompositionSettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	EndIf;
	DataCompositionSettingsComposer.Refresh();
	
	If UserSettings <> Undefined Then
		
		DataCompositionSettingsComposer.LoadUserSettings(UserSettings);
		
	EndIf;
	
	If Attributes.DCSTemplateName = "DataProcessor.PlanningDataSources.SalesPlansComponentsPredefined"
		Or Attributes.DCSTemplateName = "DataProcessor.PlanningDataSources.SalesComponentsPredefined" Then
		If Not DataCompositionClientServer.FieldUsed_(DataCompositionSettingsComposer, "Warehouse") Then
			EnableGroupingInAllReportSettings(DataCompositionSettingsComposer, "Warehouse");
		EndIf;
		If Not DataCompositionClientServer.FieldUsed_(DataCompositionSettingsComposer, "Products") Then
			EnableGroupingInAllReportSettings(DataCompositionSettingsComposer, "Products");
		EndIf;
		If Not DataCompositionClientServer.FieldUsed_(DataCompositionSettingsComposer, "Characteristic") Then
			EnableGroupingInAllReportSettings(DataCompositionSettingsComposer, "Characteristic");
		EndIf;
	EndIf;
	
	// Setting Data parameters
	ParameterUsedPeriodOffset = DataCompositionSchema.Parameters.Find("PeriodOffsetIsUsed");
	
	If SettingOfFilterByPeriod <> 3 And ParameterUsedPeriodOffset <> Undefined Then
		
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("PeriodOffsetIsUsed", False);
		
	EndIf;
	
	StartOfPeriodParameter = DataCompositionSchema.Parameters.Find("BeginOfPeriod");
	
	If (SettingOfFilterByPeriod = 2 Or SettingOfFilterByPeriod = 3) 
		And StartOfPeriodParameter <> Undefined 
		And AdditionalParameters.Property("Period") <> Undefined Then
		
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("BeginOfPeriod", AdditionalParameters.Period.StartDate);
		
	EndIf;
	
	EndOfPeriodParameter = DataCompositionSchema.Parameters.Find("EndOfPeriod");
	
	If (SettingOfFilterByPeriod = 2 Or SettingOfFilterByPeriod = 3) 
		And EndOfPeriodParameter <> Undefined 
		And AdditionalParameters.Property("Period") <> Undefined Then
		
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("EndOfPeriod", AdditionalParameters.Period.EndDate);
		
	EndIf;
	
	PeriodParameter = DataCompositionSchema.Parameters.Find("Period");
	
	If SettingOfFilterByPeriod = 1 
		And PeriodParameter <> Undefined 
		And AdditionalParameters.Property("Date") <> Undefined Then
		
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("Period", AdditionalParameters.Date.Date);
		
	EndIf;
	
	ScenarioCurrencyParameter = DataCompositionSchema.Parameters.Find("ScenarioCurrency");
	
	If ScenarioCurrencyParameter <> Undefined
		And AdditionalParameters.Property("DataParameters") <> Undefined
		And AdditionalParameters.DataParameters.Property("Scenario") <> Undefined Then
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("ScenarioCurrency",
			Common.ObjectAttributeValue(AdditionalParameters.DataParameters.Scenario, "Currency"));
	EndIf;
	
	If SettingOfFilterByPeriod = 3 
		And AdditionalParameters.Property("DataParameters") <> Undefined
		And AdditionalParameters.DataParameters.Property("BeginOfPeriod") <> Undefined
		And DataCompositionSchema.Parameters.Find("OffsetPeriodStart") <> Undefined Then
	
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("PeriodOffsetIsUsed", True);
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("OffsetPeriodStart", AdditionalParameters.DataParameters.BeginOfPeriod);
	
	EndIf;
	
	If SettingOfFilterByPeriod = 3 
		And AdditionalParameters.Property("DataParameters") <> Undefined
		And AdditionalParameters.DataParameters.Property("PeriodEnding") <> Undefined
		And DataCompositionSchema.Parameters.Find("OffsetPeriodEnd") <> Undefined Then
	
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("PeriodOffsetIsUsed", True);
		DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue("OffsetPeriodEnd", EndOfDay(AdditionalParameters.DataParameters.PeriodEnding));
	
	EndIf;
	
	// Setting selection by item segments
	If DataCompositionClientServer.GetParameter(DataCompositionSettingsComposer.Settings, "FilterByProductSegmentIsUsed") <> Undefined Then
		
		SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(DataCompositionSettingsComposer);
		
	EndIf;
	
	// Setting selection by item type
	DetailsOfPlanType = Common.ObjectAttributesValues(AdditionalParameters.DataParameters.PlanProfile, "PlanType, ProductionProcessType");
	If DetailsOfPlanType.PlanType = Enums.TypesOfPlans.ProductionPlan
		And DetailsOfPlanType.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		
		FilterItemsType = DataCompositionClientServer.AddFilter(
			DataCompositionSettingsComposer,
			"Products.ItemsType",
			Enums.ItemsTypes.Work_5,
			DataCompositionComparisonType.Equal,
			True,
			New Structure("ToUserSettings", True));
		
		FilterItemsType.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
	EndIf;
	// Adding parameters from additional parameters and setting values.
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("DataParameters") <> Undefined Then
		
		For Each Parameter In AdditionalParameters.DataParameters Do
			If Parameter.Key = "ZoomRatio" Then  // Skip the system parameter
				Continue;
			EndIf;
			If Parameter.Key = "BeginOfPeriod" Or Parameter.Key = "EndOfPeriod" Then  // The parameters are set by the source settings
				Continue;
			EndIf;
			NewParameter1 = DataCompositionSchema.Parameters.Find(Parameter.Key);
			
			SettingsParameter = DataCompositionSettingsComposer.Settings.DataParameters.Items.Find(Parameter.Key);
			If NewParameter1 <> Undefined And (SettingsParameter = Undefined Or Not SettingsParameter.Use) Then
				
				DataCompositionSettingsComposer.Settings.DataParameters.SetParameterValue(Parameter.Key, Parameter.Value);
				
			EndIf;
		EndDo;
	EndIf;
	
	// Disabling the output of total totals
	DataCompositionSettingsComposer.Settings.OutputParameters.SetParameterValue("HorizontalOverallPlacement", DataCompositionTotalPlacement.None);
	DataCompositionSettingsComposer.Settings.OutputParameters.SetParameterValue("VerticalOverallPlacement", DataCompositionTotalPlacement.None);
	
	// Installation of query texts for coefficients of measurement units / packages
	If DataCompositionSchema.DataSets.Find("ItemsPrices") <> Undefined Then 
		QueryText = DataCompositionSchema.DataSets.ItemsPrices.Query;
		If StrFind(QueryText, "ItemPricesCrossSectionOfTheLatest")<>0 Then
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ItemPricesCrossSectionOfTheLatest.Package", "ItemPricesCrossSectionOfTheLatest.Products"));
		ElsIf StrFind(QueryText, "PricesOfSupplierNomenclatureCrossSectionOfTheLatest")<>0 Then
			QueryText = StrReplace(
				QueryText, 
				"&QueryTextPackagingFactor", 
				Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Package", "PricesOfSupplierNomenclatureCrossSectionOfTheLatest.Products"));
		EndIf;
		DataCompositionSchema.DataSets.ItemsPrices.Query = QueryText;
	EndIf;
	If Attributes.DCSTemplateName = "DataProcessor.PlanningDataSourcesERP.ItemPlanPredefined"
		Or Attributes.DCSTemplateName = "DataProcessor.PlanningDataSourcesERP.SupplyOfProductionOrdersPredefined" Then
		QueryText = DataCompositionSchema.DataSets[0].Query;
		ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
		DataCompositionSchema.DataSets[0].Query = QueryText;
	EndIf;
	If AdditionalParameters.Property("Top25") And AdditionalParameters.Top25 Then
		QueryText = DataCompositionSchema.DataSets[0].Query;
		SelectAllowedLines = "SELECT ALLOWED";//@Query-part
		SelectLine = "SELECT";//@Query-part
		LineFirst = "TOP 25";//@Query-part
		QueriesArray = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryText, ";", True);
		NewRequestText = "";
		
		If QueriesArray.Count() = 0 Then
			QueriesArray.Add(QueryText);
		EndIf;
		
		For Each Query In QueriesArray Do
			If QueriesArray.Find(Query) = QueriesArray.UBound() Then
				Begin = StrFind(Query, SelectAllowedLines);
				LengthToChoose = StrLen(SelectAllowedLines);
				If Begin = 0 Then
					Begin = StrFind(Query, SelectLine);
					LengthToChoose = StrLen(SelectLine);
				EndIf;
				NewRequestText = NewRequestText + Left(Query, Begin + LengthToChoose - 1) + " " + LineFirst + Mid(Query, Begin + LengthToChoose);
			Else
				NewRequestText = NewRequestText + Query + ";";
			EndIf;
		EndDo;
		
		DataCompositionSchema.DataSets[0].Query = NewRequestText;
		
	EndIf;
	DataCompositionSettings = DataCompositionSettingsComposer.GetSettings();
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("Filter") Then
		SetSelectionsBasedOnPlanAttributes(DataCompositionSettingsComposer, AdditionalParameters.Filter);
	EndIf;
	
	// Layout layout
	DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
	DataCompositionTemplate = DataCompositionTemplateComposer.Execute(DataCompositionSchema, DataCompositionSettingsComposer.GetSettings(),,, Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate, , , True);
	
	// The table of values in which the result will be received
	Result = New ValueTable;
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(Result);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	If DataSourceParameters.Exclude And Result.Columns.Find("Count") <> Undefined Then
		
		If Result.Columns.Count.ValueType.NumberQualifiers.AllowedSign = AllowedSign.Nonnegative Then
			
			KCH = New NumberQualifiers(Result.Columns.Count.ValueType.NumberQualifiers.Digits,
				Result.Columns.Count.ValueType.NumberQualifiers.FractionDigits);
			Result.Columns.Count.Name = "OldQuantity";
			
			Result.Columns.Add("Count", New TypeDescription("Number", KCH));
			
			For Each ResultString1 In Result Do
				
				ResultString1.Count = -ResultString1.OldQuantity;
				
			EndDo;
			
			Result.Columns.Delete(Result.Columns.OldQuantity);
			
		Else
			For Each ResultString1 In Result Do
				
				ResultString1.Count = -ResultString1.Count;
				
			EndDo;
		EndIf;
		
	EndIf;
	
	Result.Columns.Add("Details", New TypeDescription("String"));
	Result.Columns.Add("NumericalRepresentation", New TypeDescription("String"));
	
	If Result.Columns.Find("Count") <> Undefined Then
		
		SourceName_ = Common.ObjectAttributeValue(DataSourceParameters["PlanningDataSource"], "Description");
		
		For Each String In Result Do
			
			If TypeOf(String.Count) <> Type("Number") Then
				Continue;
			EndIf;
			
			String.Details = SourceName_;
			String.NumericalRepresentation = String(String.Count);
			
			If ZoomRatio <> 1 And ZoomRatio <> Undefined Then
				String.Details = SourceName_ + " * " + NStr("vi = 'Hệ số';
															|ru = 'Коэфф';
															|en = 'Coeff'; fa = 'Coeff';
															|it = 'Коэфф';
															|pl = 'Coeff';
															|tr = 'Oran'");
				String.NumericalRepresentation = String(String.Count / ZoomRatio) + " * " + String(ZoomRatio);
			EndIf;
			
		EndDo;
		
	EndIf;

	ParameterChangeToSeasonalFactor = DataCompositionClientServer.GetParameter(DataCompositionSettingsComposer,
		"ChangeToTheSeasonalIndex");
		
	If GetFunctionalOption("UseSeasonalIndexes")
		And ParameterChangeToSeasonalFactor <> Undefined
		And ParameterChangeToSeasonalFactor.Use
		And ParameterChangeToSeasonalFactor.Value = True
		And (SettingOfFilterByPeriod = 2 Or SettingOfFilterByPeriod = 3) Then
		
		PeriodOffset = 0;
		If SettingOfFilterByPeriod = 2 Then
		
			StartDate    = AdditionalParameters.Period.StartDate;
			EndDate = AdditionalParameters.Period.EndDate;
		
		ElsIf SettingOfFilterByPeriod = 3 Then
			
			PeriodOffsetParameter = DataCompositionClientServer.GetParameter(DataCompositionSettingsComposer, "PeriodOffset");
			If PeriodOffsetParameter.Value <> 0 Then
				
				PeriodOffset = PeriodOffsetParameter.Value;
				
				StartDate = TMCommonUseClientServer.CalculatePeriodEndDate(
					BegOfDay(AdditionalParameters.DataParameters.BeginOfPeriod), 
					AdditionalParameters.DataParameters.Periodicity, 
					PeriodOffset)+1;
				EndDate = TMCommonUseClientServer.CalculatePeriodEndDate(
					EndOfDay(AdditionalParameters.DataParameters.PeriodEnding)+1, 
					AdditionalParameters.DataParameters.Periodicity,
					PeriodOffset);
				
			Else
				
				StartDate    = AdditionalParameters.DataParameters.BeginOfPeriod;
				EndDate    = AdditionalParameters.DataParameters.PeriodEnding;
				
			EndIf; 
		EndIf;
		
		Result.Columns.Add("SeasonalFactor", New TypeDescription("Number"));
		
		Result.FillValues(1, "SeasonalFactor");
		
		Parameters = New Structure;
		Parameters.Insert("StartDate",         StartDate);
		Parameters.Insert("EndDate",      EndDate);
		Parameters.Insert("StartDateShift",    AdditionalParameters.DataParameters.BeginOfPeriod);
		Parameters.Insert("EndDateShift", EndOfDay(AdditionalParameters.DataParameters.PeriodEnding));
		Parameters.Insert("Periodicity",      AdditionalParameters.DataParameters.Periodicity);
		Parameters.Insert("PeriodOffsetIsUsed", SettingOfFilterByPeriod = 3);
		Parameters.Insert("PeriodOffset",    PeriodOffset);
		Parameters.Insert("Warehouse",              AdditionalParameters.DataParameters.Warehouse);
		Parameters.Insert("Partner",            AdditionalParameters.DataParameters.Partner);
		Parameters.Insert("FieldName",            "Count");
		Parameters.Insert("FieldNameCoefficient", "SeasonalFactor");
		If AdditionalParameters.DataParameters.Property("RoundingPrecision") Then
			Parameters.Insert("RoundingPrecision", AdditionalParameters.DataParameters.RoundingPrecision);
		Else
			Parameters.Insert("RoundingPrecision", 0);
		EndIf; 
		
		InformationRegisters.SeasonalIndexes.ChangeToTheSeasonalIndex(Result, Parameters);
		
		For Each String In Result Do
			String.Details = String.Details + " * " + NStr("vi = 'Hệ số thời vụ';
															|ru = 'Сез. коэфф';
															|en = 'Seasonal index'; fa = 'شاخص فصلی';
															|it = 'Сез. коэфф';
															|pl = 'Seasonal index';
															|tr = 'Sezonsal oran'");
			String.NumericalRepresentation = String.NumericalRepresentation + " * " + String(String.SeasonalFactor);
			
		EndDo;
	EndIf;
	
	AfterFetchingData(Result, DataSourceParameters, UserSettings, AdditionalParameters, DataCompositionSettingsComposer);
	
	Return Result;
	
EndFunction

Function DataLayoutSchemaTemplates() Export
	
	Templates = New Array;
	
	UTTemplates = DataProcessors.PlanningDataSources.DataLayoutSchemaTemplates();
	
	For Each ArrayElement In UTTemplates Do
		Templates.Add(ArrayElement);
	EndDo;
	UPTemplates = DataProcessors.PlanningDataSourcesCA.DataLayoutSchemaTemplates();
	
	For Each ArrayElement In UPTemplates Do
		Templates.Add(ArrayElement);
	EndDo;
	UPTemplates = DataProcessors.PlanningDataSourcesERP.DataLayoutSchemaTemplates();
	
	For Each ArrayElement In UPTemplates Do
		Templates.Add(ArrayElement);
	EndDo;
	Return Templates;
	
EndFunction

Function CurVersionOfDCSTemplates() Export 

	Return 2;

EndFunction

Function LayoutSchemeByTemplateName(DCSTemplateName) Export 
	
	NamesArray = StrSplit(DCSTemplateName, ".", False);
	If NamesArray.Count() = 3 Then
		
		TemplateName = NamesArray[2];
		NamesArray.Delete(2);
		FullNameOfTemplateSource = StrConcat(NamesArray, ".");
		SetPrivilegedMode(True);
		FoundTemplate = Common.ObjectManagerByFullName(FullNameOfTemplateSource).GetTemplate(TemplateName);
		If TemplateName = "ItemsPricesPredefined" Then
			PriceManagementSystemServerCall.GetPricingScheme(FoundTemplate, True);
		EndIf;
		
		Return FoundTemplate;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Set selections based on plan Attributes.
// 
// Parameters:
//  SettingsComposer - DataCompositionSettingsComposer - Settings Composer
//  Filters - Map of CatalogRef, Structure -
Procedure SetSelectionsBasedOnPlanAttributes(SettingsComposer, Filters) Export
	
	If ValueIsFilled(Filters) Then
		For Each Parameter In Filters Do
			FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(SettingsComposer.Settings.Filter, Parameter.Key);
			If FilterItems1.Count() <> 0 Then
				For Each FilterElement In FilterItems1 Do
					UserSelection_ = SettingsComposer.UserSettings.Items.Find(FilterElement.UserSettingID);
					
					If UserSelection_ = Undefined Then
						Continue;
					EndIf;
					
					If UserSelection_.Use And ValueIsFilled(UserSelection_.RightValue) Then
						If TypeOf(UserSelection_.RightValue) = Type("ValueList") Then
							If UserSelection_.RightValue.FindByValue(Parameter.Value) = Undefined Then
								 UserSelection_.RightValue.Add(Parameter.Value)
							EndIf;
						ElsIf Not UserSelection_.RightValue = Parameter.Value Then
							FilterList = New ValueList;
							FilterList.Add(UserSelection_.RightValue);
							FilterList.Add(Parameter.Value);
							UserSelection_.ComparisonType = DataCompositionComparisonType.InList;
							UserSelection_.RightValue = FilterList;
						EndIf;
					Else
						UserSelection_.Use = True;
						UserSelection_.ComparisonType = DataCompositionComparisonType.Equal;
						UserSelection_.RightValue = Parameter.Value;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure SubstitutionOfMainMethodOfSupplyAndBalances(DataCompositionSchema)
	
	Substitutions = New Structure();
	
	ParameterName   = "CustomerOrdersSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "OrdersForInternalConsumptionMainSupplyMethodSubstitution";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "TransferOrdersShipmentMainSupplyMethodSubstitution";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.SourceWarehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "MoveOrdersReceiptSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.DestinationWarehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyOrdersShipmentSubstitutionOfMainMethodOfProvisionHeader";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyOrdersShipmentSubstitutionOfMainMethodOfProvidingTS";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyOrdersGoodsReceiptMainSupplyMethodSubstitutionHeader";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyOrdersReceiptSubstitutionOfMainMethodOfProvidingTS";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "OrdersToSuppliersSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "ProcurementSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "InventoryLocationAttributeKeys.Products,InventoryLocationAttributeKeys.Characteristic,InventoryLocationAttributeKeys.StorageLocation";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "PurchasePlansMainSupplyMethodSubstitution";
	ConnectionFields = "PurchasePlansTurnovers.Products,PurchasePlansTurnovers.Characteristic,PurchasePlansTurnovers.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesPlansSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "SalesPlansTurnovers.Products,SalesPlansTurnovers.Characteristic,SalesPlansTurnovers.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesForecastsByCategoriesSubstituteTheMainFulfillmentMethodSalesForecast";
	ConnectionFields = "CatProducts.Ref,ItemsCharacteristics.Ref,SalesPlansByCategoryTurnover_.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesForecastsByCategoriesSubstituteTheMainFulfillmentMethodFormats";
	ConnectionFields = "CatProducts.Ref,ItemsCharacteristics.Ref,HistoryOfChangesToStoreFormatsCrossSection.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesPlansSubstitutionOfMainWayToProvideSalesPlan";
	ConnectionFields = "SalesPlansTurnovers.Products,SalesPlansTurnovers.Characteristic,SalesPlansTurnovers.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesPlansSubstitutionOfMainWayToEnsureSales";
	ConnectionFields = "SalesPlansTurnovers.Products,SalesPlansTurnovers.Characteristic,HistoryOfChangesToStoreFormatsCrossSection.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "BuildPlansComponentsMainSupplyMethodSubstitution";
	ConnectionFields = "PlansForConsumptionOfComponentsTurnover.Products,PlansForConsumptionOfComponentsTurnover.Characteristic,PlansForConsumptionOfComponentsTurnover.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyPlansDisassemblyKitsSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "AssemblyPlansDisassemblyRevolutions.Products,AssemblyPlansDisassemblyRevolutions.Characteristic,AssemblyPlansDisassemblyRevolutions.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "InventoryLocationAttributeKeys.Products,InventoryLocationAttributeKeys.Characteristic,InventoryLocationAttributeKeys.StorageLocation";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SalesComponentsSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "InventoryLocationAttributeKeys.Products,InventoryLocationAttributeKeys.Characteristic,InventoryLocationAttributeKeys.StorageLocation";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "AssemblyDisassemblySubstitutionOfMainMethodOfProvision";
	ConnectionFields = "InventoryLocationAttributeKeys.Products,InventoryLocationAttributeKeys.Characteristic,InventoryLocationAttributeKeys.StorageLocation";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "FreeResiduesSubstitutionOfMainMethodOfEnsuring";
	ConnectionFields = "Set.Products,Set.Characteristic,Set.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "ActualBalancesSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "Balance.Products,Balance.Characteristic,Balance.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);

	ParameterName   = "ResiduePlansSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "TurnoverBalancePlans.Products,TurnoverBalancePlans.Characteristic,TurnoverBalancePlans.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "ProductRestrictionsSubstitutionOfMainMethodOfProvision";
	ConnectionFields = "ProductRestrictions.Products,ProductRestrictions.Characteristic,ProductRestrictions.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "MaterialOrdersInProductionMainSupplyMethodSubstitution";
	ConnectionFields = "Orders.Products,Orders.Characteristic,Orders.Ref.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "ProductionPlansMaterialsMainSupplyMethodSubstitution";
	ConnectionFields = "MaterialConsumptionPlansTurnovers.Products,MaterialConsumptionPlansTurnovers.Characteristic,MaterialConsumptionPlansTurnovers.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "InventoryConsumptionPlansMainSupplyMethodSubstitution";
	ConnectionFields = "InventoryConsumptionPlansTurnovers.Products,InventoryConsumptionPlansTurnovers.Characteristic,InventoryConsumptionPlansTurnovers.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	ParameterName   = "SecuringProductionOrdersSubstitutingMainMethodOfSecuring";
	ConnectionFields = "Demands.Products,Demands.Characteristic,Demands.Warehouse";
	Substitutions.Insert(ParameterName, ConnectionFields);
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	
	For Each DataSet In DataCompositionSchema.DataSets Do
		
		If TypeOf(DataSet) <> Type("DataCompositionSchemaDataSetQuery") Then
			Continue;
		EndIf;
		
		If StrFind(DataSet.Query, TablesNames.Result) > 0 Then
			
			ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(DataSet.Query, TablesNames);
			
		EndIf;
		
		For Each Substitution In Substitutions Do
			
			If StrFind(DataSet.Query, Substitution.Key) > 0 Then
				
				If StrFind(DataSet.Query, "(&" + Substitution.Key + ")") Then
					
					DataSet.Query = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
						DataSet.Query,
						"(&" + Substitution.Key + ")",
						Substitution.Value);
					
				Else
					
					DataSet.Query = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
						DataSet.Query,
						Substitution.Key,
						Substitution.Value);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// The procedure calls handlers for the result obtained from the layout
Procedure AfterFetchingData(ResultTable2, DataSourceParameters, UserSettings, AdditionalParameters, DataCompositionSettingsComposer)
	
	DataProcessors.PlanningDataSources.AfterFetchingData(ResultTable2, DataSourceParameters, UserSettings, AdditionalParameters, DataCompositionSettingsComposer);
	
EndProcedure

#Region InfobaseUpdate

Procedure AfterImportData(Container) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	PlanningDataSources.Ref,
	|	PlanningDataSources.DCSTemplateName
	|FROM
	|	Catalog.PlanningDataSources AS PlanningDataSources";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If IsBlankString(Selection.DCSTemplateName) Then
			CatalogObject = Selection.Ref.GetObject(); // CatalogObject.PlanningDataSources -
			CatalogObject.DataCompositionSchema = New ValueStorage("");
			
			CatalogObject.Write();
		EndIf;
	EndDo;
	
EndProcedure


#EndRegion

#EndRegion

#EndIf
