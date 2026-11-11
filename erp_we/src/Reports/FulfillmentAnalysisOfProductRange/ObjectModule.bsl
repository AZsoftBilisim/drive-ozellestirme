#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ThisIsTheTranscript;
Var ColorRed;
Var CarColor;

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	TabularDocumentResult = GenerateReport();
	If ThisIsTheTranscript Then
		SettingsComposer.FixedSettings.Filter.Items.Clear();
		For Each SettingsItem In SettingsComposer.FixedSettings.DataParameters.Items Do
			SettingsItem.Use = False;
		EndDo;
	EndIf;
	ResultDocument.FitToPage = True;
	ResultDocument.Put(TabularDocumentResult);
	
EndProcedure

#EndRegion

#Region Private

Function GenerateReport()
	
	ThisIsTheTranscript = SettingsComposer.FixedSettings.AdditionalProperties.Property("Details");
	TabularDocumentResult = New SpreadsheetDocument;
	Query = New Query;
	QueryText = InitialRequestText();
	
	Query.SetParameter("TextOtherBrands", NStr("vi = 'Nhãn hiệu khác';
												|ru = 'Прочие марки';
												|en = 'Other brands'; fa = 'Other brands';
												|it = 'Altri marchi';
												|pl = 'Inne marki';
												|tr = 'Diğer markalar'"));
	
	ParameterElement_ = Undefined;
	PeriodParameter = "";
	If ThisIsTheTranscript Then
		DataParameters = SettingsComposer.Settings.DataParameters;
		FilterParameters = SettingsComposer.Settings.Filter;
	Else
		DataParameters = SettingsComposer.UserSettings;
		FilterParameters = SettingsComposer.UserSettings;
	EndIf;
	For Each SettingsItem In DataParameters.Items Do
		If TypeOf(SettingsItem) = Type("DataCompositionSettingsParameterValue") Then
			If TrimAll(SettingsItem.Parameter) = "Period" Then
				ParameterElement_ = SettingsItem;
				Break;
			EndIf;
		EndIf;
	EndDo;
	If ParameterElement_ <> Undefined Then
		If ParameterElement_.Use Then
			If TypeOf(ParameterElement_.Value) = Type("Date") Then
				PeriodParameter = ParameterElement_.Value;
			Else
				PeriodParameter = ParameterElement_.Value.Date;
			EndIf;
		EndIf;
	EndIf;
	If Not ValueIsFilled(PeriodParameter) Then
		PeriodParameter = DrillDownPeriod;
		If Not ValueIsFilled(PeriodParameter) Then
			MessageString = NStr("vi = 'Chưa đặt giá trị tham số ""Ngày báo cáo"".';
								|ru = 'Не установлено значение параметра ""Дата отчета"".';
								|en = 'Value of the ""Report date"" parameter is not set.'; fa = 'Value of the ""Report date"" parameter is not set.';
								|it = 'Valore del parametro ""Data del report"" non impostato.';
								|pl = 'Nie jest ustawiona wartość parametru ""Data raportu"".';
								|tr = '""Rapor Tarihi"" parametre değeri yapılandırılmadı.'");
			Raise MessageString;
		EndIf;
	EndIf;
	Query.Parameters.Insert(TrimAll(ParameterElement_.Parameter),PeriodParameter);
	
	AllSelection = Undefined;
	FilterItems1 = New Array;
	For Each SettingsItem In FilterParameters.Items Do
		If TypeOf(SettingsItem) = Type("DataCompositionFilter") Then
			AllSelection = SettingsItem;
		ElsIf TypeOf(SettingsItem) = Type("DataCompositionFilterItem") Then
			If SettingsItem.Use Then
				FilterItems1.Add(SettingsItem);
			EndIf;
		EndIf;
	EndDo;
	If AllSelection <> Undefined Then
		For Each ElementOfWholeSelection In AllSelection.Items Do
			If ElementOfWholeSelection.Use Then
				If FilterItems1.Find(ElementOfWholeSelection) = Undefined Then
					FilterItems1.Add(ElementOfWholeSelection);
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	ComplianceOfIndicators=New Map;
	ComplianceOfIndicators.Insert("Fullness_","Fullness_");
	ComplianceOfIndicators.Insert("Quota","Quota");
	ComplianceOfIndicators.Insert("Representation_","Representation_");
	ComplianceOfIndicators.Insert("ViolationOfFullness","ViolationOfFullness");
	
	ComplianceWithIndicatorsLevel1=New Map;
	ComplianceWithIndicatorsLevel1.Insert("Fullness_","Fullness_");
	ComplianceWithIndicatorsLevel1.Insert("Quota","QuotaTotalFormat");
	ComplianceWithIndicatorsLevel1.Insert("Representation_","Representation_");
	ComplianceWithIndicatorsLevel1.Insert("ViolationOfFullness","ViolationOfFullnessOfForm");
	
	ComplianceWithIndicatorsLevel0=New Map;
	ComplianceWithIndicatorsLevel0.Insert("Fullness_","Fullness_");
	ComplianceWithIndicatorsLevel0.Insert("Quota","QuotaTotal");
	ComplianceWithIndicatorsLevel0.Insert("Representation_","Representation_");
	ComplianceWithIndicatorsLevel0.Insert("ViolationOfFullness","ViolationOfFullnessOfForm");
	
	ColorRed = New Color(255,0,0);
	CarColor = New Color();
	
	Template=GetTemplate("Template");
	HeaderArea_=Template.GetArea("Title");
	HeaderArea_.Parameters.ReportHeader = NStr("vi = 'Phân tích thực hiện danh điểm mặt hàng';
												|ru = 'Анализ исполнения ассортимента';
												|en = 'Administration of product mix'; fa = 'مدیریت ترکیب محصول';
												|it = 'Analisi di esecuzione dell''assortimento';
												|pl = 'Analiza wykonania asortymentu';
												|tr = 'Ürün yelpazesi yönetimi analizi'")
													+ ?(ThisIsTheTranscript, " " + NStr("vi = '(chi tiết theo mặt hàng)';
																						|ru = '(детально по номенклатуре)';
																						|en = '(detailed by items)'; fa = '(detailed by items)';
																						|it = '(dettagli in base agli articoli)';
																						|pl = '(szczegółowy według nomenklatury)';
																						|tr = '(öğeye göre ayrıntılı)'"), "");
	TabularDocumentResult.Put(HeaderArea_);
	
	TabularDocumentResult.StartRowAutoGrouping();
	ReportParametersArea = Template.GetArea("ReportParameters");
	ParameterText_ = NStr("vi = 'Ngày báo cáo:';
							|ru = 'Дата отчета :';
							|en = 'Report date:'; fa = 'Report date:';
							|it = 'Data del report :';
							|pl = 'Data raportu :';
							|tr = 'Rapor tarihi :'") + " " + PeriodParameter;
	ReportParametersArea.Parameters.ReportParameters = ParameterText_;
	TabularDocumentResult.Put(ReportParametersArea, 1);
	
	SelectionByPerformance = "";
	If FilterItems1.Count() > 0 Then
		FilterPresentation = "";
		For Each FilterElement In FilterItems1 Do
			If IsBlankString(FilterElement.UserSettingID) Then
				LeftValue = TrimAll(FilterElement.LeftValue);
			Else
				For Each BasicElement In SettingsComposer.Settings.Filter.Items Do
					If BasicElement.UserSettingID = FilterElement.UserSettingID Then
						LeftValue = TrimAll(BasicElement.UserSettingPresentation);
						Break;
					EndIf;
				EndDo;
			EndIf;
			RightValue = TrimAll(FilterElement.RightValue);
			CurViewOfComparison = TrimAll(FilterElement.ComparisonType);
			If FilterElement.ComparisonType = DataCompositionComparisonType.Filled
				Or FilterElement.ComparisonType = DataCompositionComparisonType.NotFilled Then
				MessageString = NStr("vi = 'Không thể sử dụng dạng so sánh ""%1"" trong phương án báo cáo này.';
									|ru = 'Вид сравнения ""%1"" не может быть использован в данном варианте отчета.';
									|en = 'The ""%1"" comparison kind cannot be used in this report option.'; fa = 'The ""%1"" comparison kind cannot be used in this report option.';
									|it = 'Il tipo di confronto ""%1"" non può essere utilizzato in questa variante di report.';
									|pl = 'W tej wersji raportu nie można użyć widoku porównania ""%1"".';
									|tr = '""%1"" eşleştirme türü bu rapor seçeneğinde kullanılamaz.'");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, CurViewOfComparison);
				CommonClientServer.MessageToUser(MessageString, , , , True);
				Return TabularDocumentResult;
			EndIf;
			FilterPresentation = FilterPresentation + LeftValue + " " + CurViewOfComparison + " """ + RightValue + """" + Chars.LF;
			If LeftValue = NStr("vi = 'Đang thực hiện phân loại mặt hàng';
								|ru = 'Ассортимент исполняется';
								|en = 'Product range is being performed'; fa = 'دامنه محصول در حال اجرا است';
								|it = 'Assortimento in esecuzione';
								|pl = 'Asortyment w toku wykonania';
								|tr = 'Ürün gamı yürütülüyor'") Then
				If RightValue Then
					SelectionByPerformance = "Yes";
				Else
					SelectionByPerformance = "None";
				EndIf;
			EndIf;
		EndDo;
		ReportSelectionArea=Template.GetArea("ReportSelections");
		ReportSelectionArea.Parameters.ReportSelections = FilterPresentation;
		TabularDocumentResult.Put(ReportSelectionArea,1);
	EndIf;
	
	AddConditionsAndParameters(Query, QueryText, FilterItems1, SelectionByPerformance);
	
	Query.Text=QueryText;
	Result=Query.Execute();
	
	SamplingLevel0=Result.Select(QueryResultIteration.ByGroups);
	
	SectionHeader=Template.GetArea("Header");
	If ThisIsTheTranscript Then
		SectionHeader.Parameters.DimensionsHeader = NStr("vi = 'Thể loại hàng hóa / Mã hiệu / Mặt hàng';
														|ru = 'Товарная категория / Марка / Номенклатура';
														|en = 'Product category/Brand/Items'; fa = 'Product category/Brand/Items';
														|it = 'Categoria dell''articolo / Marchio / Articoli';
														|pl = 'Kategoria towarowa / Marka / Nomenklatura';
														|tr = 'Ürün kategorisi / Marka / Öğe'");
		
		AreaLevel3 = Template.GetArea("AreaLevel3|Groups");
		AreaLevel3_Indicators = Template.GetArea("AreaLevel3|Indicators");
		
		AreaLevel4 = Template.GetArea("AreaLevel4_1|Groups");
		AreaLevel4_Indicators = Template.GetArea("AreaLevel4_1|Indicators");
		
		AreaLevel5 = Template.GetArea("AreaLevel5|Groups");
		AreaLevel5_Indicators = Template.GetArea("AreaLevel5|Indicators");
		
		AreaLevel6 = Template.GetArea("AreaLevel6|Groups");
		AreaLevel6_Indicators = Template.GetArea("AreaLevel6|Indicators");
	Else
		SectionHeader.Parameters.DimensionsHeader= NStr("vi = 'Dạng mặt hàng / Thể loại hàng hóa';
														|ru = 'Вид номенклатуры / Товарная категория';
														|en = 'Item kind / Product category'; fa = 'Item kind / Product category';
														|it = 'Tipo di articoli / Categoria dell''articolo';
														|pl = 'Rodzaj pozycji / Kategoria towarowa';
														|tr = 'Ürün türü / Ürün kategorisi'");
		AreaLevel3 = Template.GetArea("AreaLevel3|Groups");
		AreaLevel3_Indicators = Template.GetArea("AreaLevel3|Indicators");
		
		AreaLevel4 = Template.GetArea("AreaLevel4|Groups");
		AreaLevel4_Indicators = Template.GetArea("AreaLevel4|Indicators");
		
		AreaLevel5 = Template.GetArea("AreaLevel5|Groups");
		AreaLevel5_Indicators = Template.GetArea("AreaLevel5|Indicators");
		
		AreaLevel6 = Template.GetArea("AreaLevel6|Groups");
		AreaLevel6_Indicators = Template.GetArea("AreaLevel6|Indicators");
	EndIf;
	AreaFormat = Template.GetArea("StoreFormatArea");
	AreaTotal = Template.GetArea("InTotal|Groups");
	AreaTotal_Indicators = Template.GetArea("InTotal|Indicators");
	
	StructureOfAreas = New Structure;
	StructureOfAreas.Insert("TabularDocumentResult", TabularDocumentResult);
	StructureOfAreas.Insert("AreaLevel", Undefined);
	StructureOfAreas.Insert("AreaLevel_Indicators", Undefined);
	
	DetailsStructure2 = New Structure;
	DetailsStructure2.Insert("Period", PeriodParameter);
	DetailsStructure2.Insert("StoreFormat", Undefined);
	DetailsStructure2.Insert("Store", Undefined);
	DetailsStructure2.Insert("ProductKind", Undefined);
	DetailsStructure2.Insert("ProductCategory", Undefined);
	DetailsStructure2.Insert("GroupName", Undefined);
	DetailsStructure2.Insert("GroupingLevel", Undefined);
	DetailsStructure2.Insert("AddDecryption", Not ThisIsTheTranscript);
	
	While SamplingLevel0.Next() Do
		// The total result is NOT displayed
		SamplingLevel1=SamplingLevel0.Select(QueryResultIteration.ByGroups);
		
		While SamplingLevel1.Next() Do
			
			SamplingLevel2=SamplingLevel1.Select(QueryResultIteration.ByGroups);
			DetailsStructure2.StoreFormat = SamplingLevel1.StoreFormat;
			
			While SamplingLevel2.Next() Do
				
				DetailsStructure2.Store = SamplingLevel2.Store;
				
				If Not ThisIsTheTranscript Then
					AreaFormat.Parameters.Fill(SamplingLevel2);
					TabularDocumentResult.Put(AreaFormat, 0);
				EndIf;
				TabularDocumentResult.Put(SectionHeader, 1);
				SamplingLevel3=SamplingLevel2.Select(QueryResultIteration.ByGroups);
				
				While SamplingLevel3.Next() Do
					If Not ThisIsTheTranscript Then
						DetailsStructure2.ProductKind = SamplingLevel3.ProductKind;
						DetailsStructure2.GroupName = "ProductKind";
						DetailsStructure2.GroupingLevel = SamplingLevel3.Level();
						
						StructureOfAreas.AreaLevel = AreaLevel3;
						StructureOfAreas.AreaLevel_Indicators = AreaLevel3_Indicators;
						FillInParametersAndDisplayArea(StructureOfAreas, SamplingLevel3, DetailsStructure2, ComplianceOfIndicators);
					EndIf;
					If SamplingLevel3.RecordType()=QueryRecordType.TotalByHierarchy Then
						Continue;
					EndIf;
					
					SamplingLevel4=SamplingLevel3.Select(QueryResultIteration.ByGroups);
					
					While SamplingLevel4.Next() Do
						
						DetailsStructure2.ProductCategory = SamplingLevel4.ProductCategory;
						DetailsStructure2.GroupName = "ProductCategory";
						DetailsStructure2.GroupingLevel = SamplingLevel4.Level();
						
						StructureOfAreas.AreaLevel = AreaLevel4;
						StructureOfAreas.AreaLevel_Indicators = AreaLevel4_Indicators;
						FillInParametersAndDisplayArea(StructureOfAreas, SamplingLevel4, DetailsStructure2, ComplianceOfIndicators);
						
						If SamplingLevel4.RecordType()=QueryRecordType.TotalByHierarchy Then
							Continue;
						EndIf;
						
						If ThisIsTheTranscript Then
							SamplingLevel5=SamplingLevel4.Select(QueryResultIteration.ByGroups);
							
							While SamplingLevel5.Next() Do
								DetailsStructure2.GroupName = "Brand";
								DetailsStructure2.GroupingLevel = SamplingLevel5.Level();
								
								StructureOfAreas.AreaLevel = AreaLevel5;
								StructureOfAreas.AreaLevel_Indicators = AreaLevel5_Indicators;
								FillInParametersAndDisplayArea(StructureOfAreas, SamplingLevel5, DetailsStructure2, ComplianceOfIndicators);
								SamplingLevel6=SamplingLevel5.Select(QueryResultIteration.ByGroups);
								
								While SamplingLevel6.Next() Do
									If SamplingLevel6.Products <> Null Then
										DetailsStructure2.GroupName = "Products";
										DetailsStructure2.GroupingLevel = SamplingLevel6.Level();
										StructureOfAreas.AreaLevel = AreaLevel6;
										StructureOfAreas.AreaLevel_Indicators = AreaLevel6_Indicators;
										FillInParametersAndDisplayArea(StructureOfAreas, SamplingLevel6, DetailsStructure2, ComplianceOfIndicators);
									EndIf;
								EndDo;
								
							EndDo;
						EndIf;
					EndDo;
				EndDo;
				StructureOfAreas.AreaLevel = AreaTotal;
				StructureOfAreas.AreaLevel_Indicators = AreaTotal_Indicators;
				DetailsStructure2.GroupName = "";
				DetailsStructure2.GroupingLevel = 1;
				FillInParametersAndDisplayArea(StructureOfAreas, SamplingLevel2, DetailsStructure2, ComplianceOfIndicators);
			EndDo;
		EndDo;
	EndDo;
	TabularDocumentResult.EndRowAutoGrouping();
	
	Return TabularDocumentResult;
EndFunction

Procedure FillInParametersAndDisplayArea(StructureOfAreas, Selection, DetailsStructure2, ComplianceOfIndicators)
	
	TabularDocumentResult = StructureOfAreas.TabularDocumentResult;
	Area = StructureOfAreas.AreaLevel; // SpreadsheetDocument - 
	AreaIndicators = StructureOfAreas.AreaLevel_Indicators; // SpreadsheetDocument -
	
	GroupingLevel = DetailsStructure2.GroupingLevel;
	GroupName = DetailsStructure2.GroupName;
	
	StructureOfDecryptionValue = New Structure;
	If DetailsStructure2.AddDecryption Then
		For Each ElementStukr1 In DetailsStructure2 Do
			StructureOfDecryptionValue.Insert(ElementStukr1.Key, ElementStukr1.Value);
		EndDo;
	EndIf;
	
	If Not IsBlankString(GroupName) Then
		Area.Parameters.DimensionValue_1=Selection[GroupName];
		If GroupName="Products" Then
			Area.Parameters.PerformanceGroup=""+Selection.NameProductRange+"; "+Selection.ProductRangeRole;
		Else
			Area.Parameters.PerformanceGroup=Selection[NameOfGrouping(GroupName)];
		EndIf;
	EndIf;
	For Each Factor In ComplianceOfIndicators Do
		AreaIndicators.Parameters[Factor.Key]=Selection[Factor.Value];
		If DetailsStructure2.AddDecryption Then
			AreaIndicators.Parameters.DetailsStructure2 = StructureOfDecryptionValue;
		Else
			AreaIndicators.Parameters.DetailsStructure2 = Undefined;
		EndIf;
	EndDo;
	If GroupName="Products" Then
		AreaIndicators.Parameters.QuotaDeviationIsAbsolute=0;
		AreaIndicators.Parameters.QuotaDeviationRelative=0;
	Else
		QuotaFullness = Min(AreaIndicators.Parameters.Quota, AreaIndicators.Parameters.Fullness_);
		QuotaDeviationIsAbsolute = AreaIndicators.Parameters.Representation_-QuotaFullness;
		AreaIndicators.Parameters.QuotaDeviationIsAbsolute = QuotaDeviationIsAbsolute;
		If QuotaFullness=0 Then
			AreaIndicators.Parameters.QuotaDeviationRelative=0;
		Else
			AreaIndicators.Parameters.QuotaDeviationRelative=Round(QuotaDeviationIsAbsolute*100/QuotaFullness,2)
		EndIf;
	EndIf;
	
	AreaColor = CarColor;
	IndicatorAreaColor = CarColor;
	
	If AreaIndicators.Parameters.ViolationOfFullness <> 0 Then
		IndicatorAreaColor = ColorRed;
	EndIf;
	
	If GroupName <> "Products" Then
		If AreaIndicators.Parameters.QuotaDeviationRelative > Selection.VariancePercentage
			Or AreaIndicators.Parameters.QuotaDeviationRelative < -Selection.VariancePercentage Then
			IndicatorAreaColor = ColorRed;
		ElsIf QuotaDeviationIsAbsolute <> 0 And AreaIndicators.Parameters.Quota = 0 Then
			IndicatorAreaColor = ColorRed;
		EndIf;
	EndIf;
	
	Area.CurrentArea.TextColor = AreaColor;
	For AreaNumber = 1 To 6 Do
		UnderArea = AreaIndicators.Area(1,AreaNumber,1,AreaNumber);
		UnderArea.TextColor = IndicatorAreaColor;
	EndDo;
	
	TabularDocumentResult.Put(Area,GroupingLevel);
	CurrentArea = TabularDocumentResult.Join(AreaIndicators);
	If Not DetailsStructure2.AddDecryption Then
		CurrentArea.Details = Undefined;
	EndIf;
	
EndProcedure

Function NameOfGrouping(GroupName)
	
	If GroupName = "Brand" Then
		Return "NameBrand"
	ElsIf GroupName = "ProductCategory" Then
		Return "NameProductCategory"
	ElsIf GroupName = "ProductKind" Then
		Return "NameTypeOfProduct"
	ElsIf GroupName = "FulfillmentAnalysisOfProductRange" Then
		Return "NameAnalysisOfAssortmentExecution"
	Else
		Return "Description"
	EndIf;
	
EndFunction

Function InitialRequestText()
	QueryText = 
	"SELECT
	|	K.PlanningObject AS PlanningObject,
	|	MAX(K.Period) AS Period
	|INTO CurQuotas
	|FROM
	|	InformationRegister.ProductMixQuotas AS K
	|WHERE
	|	K.Period <= &Period
	|
	|GROUP BY
	|	K.PlanningObject
	|
	|INDEX BY
	|	Period,
	|	PlanningObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Quotas.PlanningObject AS StoreFormat,
	|	Quotas.ProductCategory.Owner AS ProductKind,
	|	Quotas.ProductCategory AS ProductCategory,
	|	CASE WHEN Quotas.Brand = VALUE(Catalog.Brands.EmptyRef) THEN &TextOtherBrands ELSE Quotas.Brand END AS Brand,
	|	Quotas.Quota AS Quota,
	|	Quotas.VariancePercentage AS VariancePercentage
	|INTO TTCurQuotasWithoutStores
	|FROM
	|	InformationRegister.ProductMixQuotas.SliceLast(&Period, &QuotaCondition
	|	) AS Quotas
	|		INNER JOIN CurQuotas
	|		ON Quotas.Period = CurQuotas.Period
	|			AND Quotas.PlanningObject = CurQuotas.PlanningObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCurQuotasWithoutStores.StoreFormat AS StoreFormat,
	|	Shops.Warehouse AS Store,
	|	TTCurQuotasWithoutStores.ProductKind AS ProductKind,
	|	TTCurQuotasWithoutStores.ProductCategory AS ProductCategory,
	|	TTCurQuotasWithoutStores.Brand AS Brand,
	|	TTCurQuotasWithoutStores.Quota AS Quota,
	|	TTCurQuotasWithoutStores.VariancePercentage AS VariancePercentage
	|INTO TTCurQuotas
	|FROM
	|	TTCurQuotasWithoutStores AS TTCurQuotasWithoutStores
	|		INNER JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Period,) AS Shops
	|		ON (Shops.StoreFormat = TTCurQuotasWithoutStores.StoreFormat)
	|		AND (Shops.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore))
	|		AND &ConditionStoresQuotasAndAssortment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurQuotas.ProductCategory AS ProductCategory,
	|	CurQuotas.Brand AS Brand,
	|	MAX(CurQuotas.Quota) AS Quota,
	|	AVG(CurQuotas.VariancePercentage) AS VariancePercentage
	|INTO TTCurQuotasWithoutFormats
	|FROM
	|	TTCurQuotas AS CurQuotas
	|
	|GROUP BY
	|	CurQuotas.ProductCategory,
	|	CurQuotas.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCurQuotasWithoutStores.StoreFormat AS StoreFormat,
	|	SUM(TTCurQuotasWithoutStores.Quota) AS Quota,
	|	AVG(TTCurQuotasWithoutStores.VariancePercentage) AS VariancePercentage
	|INTO TTQuotasTotalFormat
	|FROM
	|	TTCurQuotasWithoutStores AS TTCurQuotasWithoutStores
	|GROUP BY
	|	TTCurQuotasWithoutStores.StoreFormat
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductRange.Products AS Products,
	|	ProductRange.Products.ProductKind AS ProductKind,
	|	ProductRange.Products.ProductCategory AS ProductCategory,
	|	ProductRange.Products.Brand AS Brand,
	|	ProductRange.PlanningObject AS PlanningObject,
	|	ProductRange.ProductRangeRole AS ProductRangeRole,
	|	ProductRange.PurchasesAreAllowed AS PurchasesAreAllowed,
	|	ProductRange.SalesAreAllowed AS SalesAreAllowed,
	|	ProductRange.Period AS Period,
	|	ProductRange.Recorder AS Recorder
	|INTO TTCurFullnessOfFormats
	|FROM
	|	InformationRegister.ProductRange.SliceLast(ENDOFPERIOD(&Period, DAY), 
	|			&ConditionAssortment
	|			) AS ProductRange
	|WHERE
	|	ProductRange.PurchasesAreAllowed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductRange.PlanningObject AS StoreFormat,
	|	Shops.Warehouse AS Store,
	|	ProductRange.ProductKind AS ProductKind,
	|	ProductRange.ProductCategory AS ProductCategory,
	|	ProductRange.Brand AS Brand,
	|	ProductRange.Products AS Products,
	|	ProductRange.ProductRangeRole AS ProductRangeRole,
	|	ProductRange.Period AS Period,
	|	ProductRange.Recorder AS Recorder
	|INTO TTCurFullness
	|FROM
	|	TTCurFullnessOfFormats AS ProductRange
	|		INNER JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Period,) AS Shops
	|		ON (Shops.StoreFormat = ProductRange.PlanningObject)
	|		AND (Shops.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore))
	|	AND &ConditionStoresQuotasAndAssortment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Shops.StoreFormat AS StoreFormat,
	|	ProductStockBalance.Warehouse AS Store,
	|	ProductStockBalance.Products AS Products,
	|	ProductStockBalance.Products.ProductCategory.Owner AS ProductKind,
	|	ProductStockBalance.Products.ProductCategory AS ProductCategory,
	|	ProductStockBalance.Products.Brand AS Brand,
	|	SUM(ProductStockBalance.InStockBalance) AS InStockBalance
	|INTO TTCurBalances
	|FROM
	|	AccumulationRegister.ProductStock.Balance(ENDOFPERIOD(&Period, DAY), 
	|	(Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore))
	|	AND &ConditionBalance
	|	) AS ProductStockBalance
	|		INNER JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast(&Period,) AS Shops
	|		ON ProductStockBalance.Warehouse = Shops.Warehouse
	|
	|
	|GROUP BY
	|	ProductStockBalance.Warehouse,
	|	ProductStockBalance.Products,
	|	Shops.StoreFormat
	|
	|HAVING
	|	SUM(ProductStockBalance.InStockBalance) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UnitedCommon.StoreFormat AS StoreFormat,
	|	UnitedCommon.Store AS Store,
	|	UnitedCommon.ProductKind AS ProductKind,
	|	UnitedCommon.ProductCategory AS ProductCategory,
	|	UnitedCommon.Brand AS Brand,
	|	UnitedCommon.Products AS Products,
	|	MAX(UnitedCommon.ProductsRange) AS ProductsRange,
	|	MAX(UnitedCommon.ResidueProducts) AS ResidueProducts,
	|	MAX(UnitedCommon.ProductRangeRole) AS ProductRangeRole,
	|	MAX(UnitedCommon.ThisIsNotSummary) AS ThisIsNotSummary,
	|	MAX(UnitedCommon.Quota) AS Quota,
	|	MAX(UnitedCommon.VariancePercentage) AS VariancePercentage,
	|	MAX(UnitedCommon.Fullness_) AS Fullness_,
	|	MAX(UnitedCommon.Representation_) AS Representation_,
	|	MAX(UnitedCommon.QuotaTotalFormat) AS QuotaTotalFormat
	|INTO TTSummaryTablePreliminary
	|FROM
	|	(SELECT
	|		GeneralQueryAssociation.StoreFormat AS StoreFormat,
	|		GeneralQueryAssociation.Store AS Store,
	|		GeneralQueryAssociation.ProductKind AS ProductKind,
	|		GeneralQueryAssociation.ProductCategory AS ProductCategory,
	|		CASE WHEN CurQuotas.Brand.Description IS NULL THEN &TextOtherBrands ELSE CurQuotas.Brand END AS Brand,
	|		CASE
	|			WHEN GeneralQueryAssociation.Products IS NULL 
	|				THEN GeneralQueryAssociation.ResidueProducts
	|			ELSE GeneralQueryAssociation.Products
	|		END AS Products,
	|		GeneralQueryAssociation.Products AS ProductsRange,
	|		GeneralQueryAssociation.ResidueProducts AS ResidueProducts,
	|		MAX(GeneralQueryAssociation.ProductRangeRole) AS ProductRangeRole,
	|		MAX(GeneralQueryAssociation.ThisIsNotSummary) AS ThisIsNotSummary,
	|		MAX(GeneralQueryAssociation.Quota) AS Quota,
	|		MAX(GeneralQueryAssociation.VariancePercentage) AS VariancePercentage,
	|		MAX(GeneralQueryAssociation.Fullness_) AS Fullness_,
	|		MAX(GeneralQueryAssociation.Representation_) AS Representation_,
	|		MAX(GeneralQueryAssociation.QuotaTotalFormat) AS QuotaTotalFormat
	|	FROM
	|		(SELECT
	|			CurQuotas.StoreFormat AS StoreFormat,
	|			CurQuotas.Store AS Store,
	|			CurQuotas.ProductKind AS ProductKind,
	|			CurQuotas.ProductCategory AS ProductCategory,
	|			CurQuotas.Brand AS Brand,
	|			NULL AS Products,
	|			NULL AS ProductRangeRole,
	|			NULL AS ResidueProducts,
	|			TRUE AS ThisIsNotSummary,
	|			CurQuotas.Quota AS Quota,
	|			CurQuotas.VariancePercentage AS VariancePercentage,
	|			0 AS Fullness_,
	|			0 AS Representation_,
	|			ISNULL(QuotasTotalFormat.Quota, 0) AS QuotaTotalFormat
	|		FROM
	|			TTCurQuotas AS CurQuotas
	|				LEFT JOIN TTQuotasTotalFormat AS QuotasTotalFormat
	|				ON (QuotasTotalFormat.StoreFormat = CurQuotas.StoreFormat)
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CurFullness.StoreFormat,
	|			CurFullness.Store,
	|			CurFullness.ProductKind,
	|			CurFullness.ProductCategory,
	|			CurFullness.Brand,
	|			CurFullness.Products,
	|			CurFullness.ProductRangeRole,
	|			NULL,
	|			TRUE,
	|			0,
	|			0,
	|			1,
	|			0,
	|			0
	|		FROM
	|			TTCurFullness AS CurFullness
	|		
	|		UNION ALL
	|		
	|		SELECT
	|			CurRepresentation.StoreFormat,
	|			CurRepresentation.Store,
	|			CurRepresentation.ProductKind,
	|			CurRepresentation.ProductCategory,
	|			CurRepresentation.Brand,
	|			NULL,
	|			NULL,
	|			CurRepresentation.Products,
	|			FALSE,
	|			0,
	|			0,
	|			0,
	|			1,
	|			0
	|		FROM
	|			TTCurBalances AS CurRepresentation) AS GeneralQueryAssociation
	|			LEFT JOIN TTCurQuotas AS CurQuotas
	|			ON (CurQuotas.ProductCategory = GeneralQueryAssociation.ProductCategory)
	|				AND (CurQuotas.Brand = GeneralQueryAssociation.Brand)
	|				AND (CurQuotas.Store = GeneralQueryAssociation.Store)
	|	
	|	GROUP BY
	|		GeneralQueryAssociation.StoreFormat,
	|		GeneralQueryAssociation.Store,
	|		GeneralQueryAssociation.ProductKind,
	|		GeneralQueryAssociation.ProductCategory,
	|		CASE WHEN CurQuotas.Brand.Description IS NULL THEN &TextOtherBrands ELSE CurQuotas.Brand END,
	|		GeneralQueryAssociation.Products,
	|		GeneralQueryAssociation.ResidueProducts) AS UnitedCommon
	|
	|GROUP BY
	|	UnitedCommon.StoreFormat,
	|	UnitedCommon.Store,
	|	UnitedCommon.ProductKind,
	|	UnitedCommon.ProductCategory,
	|	UnitedCommon.Brand,
	|	UnitedCommon.Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TablePreliminary.StoreFormat AS StoreFormat,
	|	TablePreliminary.Store AS Store,
	|	TablePreliminary.ProductKind AS ProductKind,
	|	TablePreliminary.ProductCategory AS ProductCategory,
	|	TablePreliminary.Brand AS Brand,
	|	TablePreliminary.Products AS Products,
	|	TablePreliminary.ProductsRange AS ProductsRange,
	|	TablePreliminary.ResidueProducts AS ResidueProducts,
	|	TablePreliminary.ProductRangeRole AS ProductRangeRole,
	|	TablePreliminary.ThisIsNotSummary AS ThisIsNotSummary,
	|	TablePreliminary.Quota AS Quota,
	|	TablePreliminary.VariancePercentage AS VariancePercentage,
	|	TablePreliminary.Fullness_ AS Fullness_,
	|	TablePreliminary.Representation_ AS Representation_,
	|	TablePreliminary.QuotaTotalFormat AS QuotaTotalFormat,
	|	CASE
	|		WHEN TablePreliminary.Representation_ > TablePreliminary.Fullness_
	|			THEN 1
	|		WHEN TablePreliminary.Fullness_ > TablePreliminary.Representation_
	|				AND TablePreliminary.ProductRangeRole = VALUE(Enum.ProductRangeRoles.RegularProductRange)
	|			THEN 1
	|		ELSE 0
	|	END AS ViolationOfFullness
	|INTO TTSummaryTable
	|FROM TTSummaryTablePreliminary AS TablePreliminary
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTSummaryTable.StoreFormat,
	|	TTSummaryTable.Store,
	|	TTSummaryTable.ProductCategory,
	|	TTSummaryTable.Brand,
	|	SUM(TTSummaryTable.ViolationOfFullness) AS ViolationOfFullness
	|INTO TTTotalsFullnessIntermediate1
	|FROM
	|	TTSummaryTable AS TTSummaryTable
	|
	|GROUP BY
	|	TTSummaryTable.StoreFormat,
	|	TTSummaryTable.Store,
	|	TTSummaryTable.ProductCategory,
	|	TTSummaryTable.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTotalsFullnessIntermediate1.StoreFormat,
	|	TTTotalsFullnessIntermediate1.ProductCategory,
	|	TTTotalsFullnessIntermediate1.Brand,
	|	MAX(TTTotalsFullnessIntermediate1.ViolationOfFullness) AS ViolationOfFullness
	|INTO TTTotalsFullnessIntermediate
	|FROM
	|	TTTotalsFullnessIntermediate1 AS TTTotalsFullnessIntermediate1
	|
	|GROUP BY
	|	TTTotalsFullnessIntermediate1.StoreFormat,
	|	TTTotalsFullnessIntermediate1.ProductCategory,
	|	TTTotalsFullnessIntermediate1.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTotalsFullnessIntermediate.StoreFormat,
	|	SUM(TTTotalsFullnessIntermediate.ViolationOfFullness) AS ViolationOfFullness
	|INTO TTTotalsViolationOfFullnessFormat
	|FROM
	|	TTTotalsFullnessIntermediate AS TTTotalsFullnessIntermediate
	|
	|GROUP BY
	|	TTTotalsFullnessIntermediate.StoreFormat
	|;";
	If ThisIsTheTranscript Then
		QueryText = QueryText + "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SummaryTable.StoreFormat AS StoreFormat,
		|	SummaryTable.StoreFormat.Description AS StoreFormatName,
		|	SummaryTable.StoreFormat.DeletionMark AS MarkDeleteStoreFormat,
		|	SummaryTable.Store AS Store,
		|	SummaryTable.Store.Description AS StoreName,
		|	SummaryTable.Store.DeletionMark AS TagDeleteStore,
		|	SummaryTable.ProductKind AS ProductKind,
		|	SummaryTable.ProductKind.Description AS NameTypeOfProduct,
		|	SummaryTable.ProductKind.DeletionMark AS MarkingDeletionTypeOfProduct,
		|	SummaryTable.ProductCategory AS ProductCategory,
		|	SummaryTable.ProductCategory.Description AS NameProductCategory,
		|	SummaryTable.ProductCategory.DeletionMark AS TagDeletionProductCategory,
		|	SummaryTable.Brand AS Brand,
		|	CASE
		|		WHEN SummaryTable.Brand REFS Catalog.Brands
		|			THEN SummaryTable.Brand.Description
		|		ELSE SummaryTable.Brand
		|	END AS NameBrand,
		|	CASE
		|		WHEN SummaryTable.Brand REFS Catalog.Brands
		|			THEN SummaryTable.Brand.DeletionMark
		|		ELSE FALSE
		|	END AS MarkMark,
		|	SummaryTable.Products,
		|	SummaryTable.Products.Description AS NameProductRange,
		|	SummaryTable.Products.DeletionMark AS MarkingAndProducts,
		|	SummaryTable.ProductsRange AS ProductsRange,
		|	SummaryTable.ResidueProducts AS ResidueProducts,
		|	SummaryTable.ProductRangeRole AS ProductRangeRole,
		|	SummaryTable.ThisIsNotSummary AS ThisIsNotSummary,
		|	SummaryTable.Quota AS Quota,
		|	SummaryTable.VariancePercentage AS VariancePercentage,
		|	SummaryTable.Fullness_ AS Fullness_,
		|	SummaryTable.Representation_ AS Representation_,
		|	SummaryTable.QuotaTotalFormat AS QuotaTotalFormat,
		|	SummaryTable.ViolationOfFullness AS ViolationOfFullness,
		|	TTTotalsViolationOfFullnessFormat.ViolationOfFullness AS ViolationOfFullnessOfForm
		|FROM
		|	TTSummaryTable AS SummaryTable
		|		LEFT JOIN TTTotalsViolationOfFullnessFormat AS TTTotalsViolationOfFullnessFormat
		|		ON (TTTotalsViolationOfFullnessFormat.StoreFormat = SummaryTable.StoreFormat)
		|WHERE
		|	NOT (SummaryTable.Quota = 0
		|	AND SummaryTable.Fullness_ = 0
		|	AND SummaryTable.Representation_ = 0)
		|
		|
		|ORDER BY
		|	StoreFormatName,
		|	StoreName,
		|	SummaryTable.ProductKind.Parent.Description,
		|	NameTypeOfProduct,
		|	SummaryTable.ProductCategory.Parent.Parent.Description,
		|	SummaryTable.ProductCategory.Parent.Description,
		|	NameProductCategory,
		|	NameBrand,
		|	NameProductRange
		|TOTALS
		|	FALSE AS ThisIsNotSummary,
		|	SUM(Quota) AS Quota,
		|	MAX(VariancePercentage) AS VariancePercentage,
		|	COUNT(DISTINCT SummaryTable.ProductsRange) AS Fullness_,
		|	COUNT(DISTINCT SummaryTable.ResidueProducts) AS Representation_,
		|	MAX(QuotaTotalFormat) AS QuotaTotalFormat,
		|	SUM(ViolationOfFullness) AS ViolationOfFullness,
		|	MAX(ViolationOfFullnessOfForm) AS ViolationOfFullnessOfForm
		|BY
		|	OVERALL,
		|	StoreFormat,
		|	Store,
		|	ProductKind,
		|	ProductCategory,
		|	Brand
		|";
	Else
		QueryText = QueryText + "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SummaryTable.StoreFormat AS StoreFormat,
		|	SummaryTable.Store AS Store,
		|	SummaryTable.ProductKind AS ProductKind,
		|	SummaryTable.ProductCategory AS ProductCategory,
		|	FALSE AS ThisIsNotSummary,
		|	SUM(SummaryTable.Quota) AS Quota,
		|	MAX(SummaryTable.VariancePercentage) AS VariancePercentage,
		|	COUNT(DISTINCT SummaryTable.ProductsRange) AS Fullness_,
		|	COUNT(DISTINCT SummaryTable.ResidueProducts) AS Representation_,
		|	MAX(SummaryTable.QuotaTotalFormat) AS QuotaTotalFormat,
		|	SUM(SummaryTable.ViolationOfFullness) AS ViolationOfFullness,
		|	MAX(TTTotalsViolationOfFullnessFormat.ViolationOfFullness) AS ViolationOfFullnessOfForm
		|INTO SummaryTableOfCategories
		|FROM
		|	TTSummaryTable AS SummaryTable
		|		LEFT JOIN TTTotalsViolationOfFullnessFormat AS TTTotalsViolationOfFullnessFormat
		|		ON (TTTotalsViolationOfFullnessFormat.StoreFormat = SummaryTable.StoreFormat)
		|WHERE
		|	NOT (SummaryTable.Quota = 0
		|	AND SummaryTable.Fullness_ = 0
		|	AND SummaryTable.Representation_ = 0)
		|GROUP BY
		|	SummaryTable.StoreFormat,
		|	SummaryTable.Store,
		|	SummaryTable.ProductKind,
		|	SummaryTable.ProductCategory
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SummaryTable.StoreFormat AS StoreFormat,
		|	SummaryTable.StoreFormat.Description AS StoreFormatName,
		|	SummaryTable.StoreFormat.DeletionMark AS MarkDeleteStoreFormat,
		|	SummaryTable.Store AS Store,
		|	SummaryTable.Store.Description AS StoreName,
		|	SummaryTable.Store.DeletionMark AS TagDeleteStore,
		|	SummaryTable.ProductKind AS ProductKind,
		|	SummaryTable.ProductKind.Description AS NameTypeOfProduct,
		|	SummaryTable.ProductKind.DeletionMark AS MarkingDeletionTypeOfProduct,
		|	SummaryTable.ProductCategory AS ProductCategory,
		|	SummaryTable.ProductCategory.Description AS NameProductCategory,
		|	SummaryTable.ProductCategory.DeletionMark AS TagDeletionProductCategory,
		|	SummaryTable.ThisIsNotSummary AS ThisIsNotSummary,
		|	SummaryTable.Quota AS Quota,
		|	SummaryTable.VariancePercentage AS VariancePercentage,
		|	SummaryTable.Fullness_ AS Fullness_,
		|	SummaryTable.Representation_ AS Representation_,
		|	SummaryTable.QuotaTotalFormat AS QuotaTotalFormat,
		|	SummaryTable.ViolationOfFullness AS ViolationOfFullness,
		|	SummaryTable.ViolationOfFullnessOfForm AS ViolationOfFullnessOfForm
		|FROM
		|	SummaryTableOfCategories AS SummaryTable
		|WHERE
		|	NOT (SummaryTable.Quota = 0
		|	AND SummaryTable.Fullness_ = 0
		|	AND SummaryTable.Representation_ = 0)
		|	AND &ConditionHaving
		|
		|ORDER BY
		|	StoreFormatName,
		|	StoreName,
		|	SummaryTable.ProductKind.Parent.Description,
		|	NameTypeOfProduct,
		|	SummaryTable.ProductCategory.Parent.Parent.Description,
		|	SummaryTable.ProductCategory.Parent.Description,
		|	NameProductCategory
		|TOTALS
		|	FALSE AS ThisIsNotSummary,
		|	SUM(Quota) AS Quota,
		|	MAX(VariancePercentage) AS VariancePercentage,
		|	SUM(Fullness_) AS Fullness_,
		|	SUM(Representation_) AS Representation_,
		|	MAX(QuotaTotalFormat) AS QuotaTotalFormat,
		|	SUM(ViolationOfFullness) AS ViolationOfFullness,
		|	MAX(ViolationOfFullnessOfForm) AS ViolationOfFullnessOfForm
		|BY
		|	OVERALL,
		|	StoreFormat,
		|	Store,
		|	ProductKind
		|";		
	EndIf;
	
	Return QueryText;
EndFunction

Procedure AddConditionsAndParameters(Query, QueryText, FilterItems1, SelectionByPerformance)
	
	ConditionCounter = 0;
	ParameterCounter = 0;
	
	UseCollectionManagement = GetFunctionalOption("UseCollectionManagement");
	
	// &QuotaCondition
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("StoreFormat", "PlanningObject");
	MatchingConditionFields.Insert("ProductKind", "ProductCategory.Owner");
	MatchingConditionFields.Insert("ProductCategory", "ProductCategory");
	MatchingConditionFields.Insert("Brand", "Brand");
	If UseCollectionManagement Then
		MatchingConditionFields.Insert("ItemsCollection", "ItemsCollection");
	EndIf; 
	InitialConditionText = "";
	GroupCondition = "";
	ConditionText = "";
	GenerateConditionText(Query,
							 FilterItems1,
							 ConditionText,
							 ConditionCounter,
							 ParameterCounter,
							 InitialConditionText,
							 GroupCondition,
							 MatchingConditionFields);
	QueryText=StrReplace(QueryText,"&QuotaCondition", TrimAll(ConditionText));
	
	// &ConditionStoresQuotasAndAssortment
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("Store", "Shops.Warehouse");
	MatchingConditionFields.Insert("Store.", "Shops.");
	InitialConditionText = "And";
	GroupCondition = "";
	ConditionText = "";
	GenerateConditionText(Query,
							 FilterItems1,
							 ConditionText,
							 ConditionCounter,
							 ParameterCounter,
							 InitialConditionText,
							 GroupCondition,
							 MatchingConditionFields);
	QueryText=StrReplace(QueryText,"AND &ConditionStoresQuotasAndAssortment", TrimAll(ConditionText));
	
	// &ConditionAssortment
	ConditionCounter = 0;
	
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("StoreFormat", "PlanningObject");
	MatchingConditionFields.Insert("ProductKind", "Products.ProductKind");
	MatchingConditionFields.Insert("ProductCategory", "Products.ProductCategory");
	MatchingConditionFields.Insert("Brand", "Products.Brand");
	If UseCollectionManagement Then
		MatchingConditionFields.Insert("ItemsCollection", "Products.ItemsCollection");
	EndIf; 
	InitialConditionText = "";
	GroupCondition = "";
	ConditionText = "";
	GenerateConditionText(Query,
							 FilterItems1,
							 ConditionText,
							 ConditionCounter,
							 ParameterCounter,
							 InitialConditionText,
							 GroupCondition,
							 MatchingConditionFields);
	QueryText=StrReplace(QueryText,"&ConditionAssortment", TrimAll(ConditionText));

	// &ConditionBalance
	ConditionCounter = 0;
	
	MatchingConditionFields = New Map;
	//Correspond to the field conditions.Insert("Store Format", "Stores.Store format");
	MatchingConditionFields.Insert("Store", "Warehouse");
	MatchingConditionFields.Insert("ProductKind", "Products.ProductKind");
	MatchingConditionFields.Insert("ProductCategory", "Products.ProductCategory");
	MatchingConditionFields.Insert("Brand", "Products.Brand");
	If UseCollectionManagement Then
		MatchingConditionFields.Insert("ItemsCollection", "Products.ItemsCollection");
	EndIf;
	InitialConditionText = "And";
	GroupCondition = "";
	ConditionText = "";
	GenerateConditionText(Query,
							 FilterItems1,
							 ConditionText,
							 ConditionCounter,
							 ParameterCounter,
							 InitialConditionText,
							 GroupCondition,
							 MatchingConditionFields);
	QueryText=StrReplace(QueryText,"AND &ConditionBalance", TrimAll(ConditionText));
	
	// &ConditionHaving
	TextOfConditionHaving = "";
	If Not IsBlankString(SelectionByPerformance) Then
		If SelectionByPerformance = "None" Then
			TextOfConditionHaving = "	AND (SummaryTable.ViolationOfFullness <> 0
			|			OR (SummaryTable.Quota = 0 AND SummaryTable.Representation_ <> 0)
			|			OR (CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END > SummaryTable.VariancePercentage
			|				AND CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END > 0)
			|			OR (CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END < - SummaryTable.VariancePercentage
			|				AND CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END < 0))
			|";
		ElsIf SelectionByPerformance = "Yes" Then
			TextOfConditionHaving = "	AND NOT (SummaryTable.ViolationOfFullness <> 0
			|			OR (SummaryTable.Quota = 0 AND SummaryTable.Representation_ <> 0)
			|			OR (CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END > SummaryTable.VariancePercentage
			|				AND CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END > 0)
			|			OR (CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END < - SummaryTable.VariancePercentage
			|				AND CASE
			|					WHEN SummaryTable.Quota > SummaryTable.Fullness_
			|							AND SummaryTable.Fullness_ <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Fullness_) * 100 / SummaryTable.Fullness_
			|					WHEN SummaryTable.Quota < SummaryTable.Fullness_
			|							AND SummaryTable.Quota <> 0
			|						THEN (SummaryTable.Representation_ - SummaryTable.Quota) * 100 / SummaryTable.Quota
			|					ELSE 0
			|				END < 0))
			|";
		EndIf;
	EndIf;
	QueryText=StrReplace(QueryText,"AND &ConditionHaving", TrimAll(TextOfConditionHaving));
	
EndProcedure

Procedure GenerateConditionText(Query,
	FilterItems1,
	ConditionText,
	ConditionCounter,
	ParameterCounter,
	InitialConditionText,
	GroupCondition,
	MatchingConditionFields)
	
	InternalCounter = 0;
	If IsBlankString(GroupCondition) Then
		GroupCondition = "And";
		InternalCounter = 1;
	EndIf;
	For Each FilterElement In FilterItems1 Do
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			
			If FilterElement.GroupType = DataCompositionFilterItemsGroupType.AndGroup Then
				GroupCondition2 = "And";
				BeginningOfGroup = "(";
			ElsIf FilterElement.GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
				GroupCondition2 = "And";
				BeginningOfGroup = "NOT (";
			ElsIf FilterElement.GroupType = DataCompositionFilterItemsGroupType.OrGroup Then
				GroupCondition2 = "OR";
				BeginningOfGroup = "(";
			EndIf;
			NestedConditionText = "";
			ConditionCounterBeforeNested = ConditionCounter;
			GenerateConditionText(Query,
									 FilterElement.Items,
									 NestedConditionText,
									 ConditionCounter,
									 ParameterCounter,
									 "",
									 GroupCondition2,
									 MatchingConditionFields);
			If Not IsBlankString(NestedConditionText) Then
				If ConditionCounterBeforeNested = 0 Then
					ConditionText = ConditionText + InitialConditionText + BeginningOfGroup;
				Else
					ConditionText = ConditionText + GroupCondition+ " " + BeginningOfGroup;
				EndIf;
				ConditionText = ConditionText + NestedConditionText + ")" + Chars.LF;
			EndIf;
		ElsIf TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			If IsBlankString(FilterElement.UserSettingID) Then
				DataPath = TrimAll(FilterElement.LeftValue);
			Else
				For Each BasicElement In SettingsComposer.Settings.Filter.Items Do
					If BasicElement.UserSettingID = FilterElement.UserSettingID Then
						DataPath = TrimAll(BasicElement.LeftValue);
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			PositionOfFirstPoint = StrFind(DataPath,".");
			If PositionOfFirstPoint = 0 Then
				SearchPath = DataPath;
				EndOfPath = "";
				NewBeginning = MatchingConditionFields.Get(SearchPath);
			Else
				SearchPath = Left(DataPath, PositionOfFirstPoint);
				NewBeginning = MatchingConditionFields.Get(SearchPath);
				If NewBeginning = Undefined Then
					SearchPath = Left(DataPath, PositionOfFirstPoint-1);
					NewBeginning = MatchingConditionFields.Get(SearchPath);
					PathLength = StrLen(DataPath);
					EndOfPath = Right(DataPath, PathLength-PositionOfFirstPoint+1);
				Else
					PathLength = StrLen(DataPath);
					EndOfPath = Right(DataPath, PathLength-PositionOfFirstPoint);
				EndIf;
			EndIf;
			If NewBeginning = Undefined Then
				Continue;
			Else
				DataPath = NewBeginning + EndOfPath;
			EndIf;
			ParameterName = StrReplace(DataPath, ".", "")+Format(ParameterCounter, "NZ=0; NG=0");
			ConditionTextInternal = "";
			ConditionIsLike = False;
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
				ConditionTextInternal = ""+DataPath+" = &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.NotEqual Then
				ConditionTextInternal = ""+DataPath+" <> &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.Greater Then
				ConditionTextInternal = ""+DataPath+" > &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.GreaterOrEqual Then
				ConditionTextInternal = ""+DataPath+" >= &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.Less Then
				ConditionTextInternal = ""+DataPath+" < &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.LessOrEqual Then
				ConditionTextInternal = ""+DataPath+" <= &"+ParameterName;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.Contains Then
				ConditionTextInternal = ""+DataPath+" LIKE &"+ParameterName;
				ConditionIsLike = True;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				ConditionTextInternal = ""+DataPath+" IN (&"+ParameterName+")";
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy
				Or FilterElement.ComparisonType = DataCompositionComparisonType.InListByHierarchy Then
				ConditionTextInternal = ""+DataPath+" IN HIERARCHY(&"+ParameterName+")";
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.NotInList Then
				ConditionTextInternal = "NOT "+DataPath+" IN (&"+ParameterName+")";
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.NotInHierarchy
				Or FilterElement.ComparisonType = DataCompositionComparisonType.NotInListByHierarchy Then
				ConditionTextInternal = "NOT "+DataPath+" IN HIERARCHY(&"+ParameterName+")";
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.Contains Then
				ConditionTextInternal = "NOT "+DataPath+" LIKE &"+ParameterName;
				ConditionIsLike = True;
			EndIf;
			If ConditionIsLike Then
				Query.SetParameter(ParameterName, "%"+FilterElement.RightValue+"%");
			Else
				Query.SetParameter(ParameterName, FilterElement.RightValue);
			EndIf;
			
			If InternalCounter = 0 Then
				// Condition group
				ConditionText = ConditionText + "" + InitialConditionText + "	(" + ConditionTextInternal + ")"  + Chars.LF;
			Else
				If ConditionCounter = 0 Then
					ConditionText = ConditionText + "" + InitialConditionText + "	(" + ConditionTextInternal + ")"  + Chars.LF;
				Else
					ConditionText = ConditionText + "	"+GroupCondition+" (" + ConditionTextInternal + ")" + Chars.LF;
				EndIf;
			EndIf;
			ConditionCounter = ConditionCounter + 1;
			ParameterCounter = ParameterCounter + 1;
			InternalCounter = InternalCounter + 1;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf