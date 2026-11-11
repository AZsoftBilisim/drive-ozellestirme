#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ThisIsTheTranscript;
Var StartDateOfAnalysisPeriod;
Var EndDateOfAnalysisPeriod;
Var StartDateOfComparisonPeriod;
Var EndDateOfComparisonPeriod;

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	ReportResult = GenerateReport();
	If ThisIsTheTranscript Then
		SettingsComposer.FixedSettings.Filter.Items.Clear();
		For Each SettingsItem In SettingsComposer.FixedSettings.DataParameters.Items Do
			SettingsItem.Use = False;
		EndDo;
	EndIf;
	ResultDocument.FitToPage = True;
	ResultDocument.FixedTop = ReportResult.FixedTop;
	ResultDocument.FixedLeft = ReportResult.FixedLeft;
	ResultDocument.Put(ReportResult);
	
EndProcedure

#EndRegion

#Region Private

Function GenerateReport()
	
	ThisIsTheTranscript = SettingsComposer.FixedSettings.AdditionalProperties.Property("Details");
	If ThisIsTheTranscript Then
		DetailsStructure2 = SettingsComposer.FixedSettings.AdditionalProperties.Details;
		AnalyzedPeriod = DetailsStructure2.AnalyzedPeriod;
		PeriodToCompareWith = DetailsStructure2.PeriodToCompareWith;
		DrillDownColumnNumber = DetailsStructure2.DrillDownColumnNumber;
	Else
		For Each Item In SettingsComposer.UserSettings.Items Do
			If TypeOf(Item) = Type("DataCompositionSettingsParameterValue") Then
				If TrimAll(Item.Parameter) = "AnalyzedPeriod" Then
					AnalyzedPeriod = Item.Value;
				ElsIf TrimAll(Item.Parameter) = "PeriodToCompareWith" Then
					PeriodToCompareWith = Item.Value;
				EndIf;
			EndIf;
		EndDo;
		DrillDownColumnNumber = 0;
	EndIf;
	TabularDocumentResult = New SpreadsheetDocument;
	FilterPresentation = "";
	FieldArray = New Array;
	Result = DataSamplingResult(FilterPresentation, FieldArray);
	
	If Result = Undefined Then
		Return TabularDocumentResult;
	EndIf;
	
	SamplingLevel0=Result.Select(QueryResultIteration.ByGroups);
	
	Template=GetTemplate("Template");
	HeaderArea_=Template.GetArea("Title");
	HeaderArea_.Parameters.ReportHeader =  NStr("vi = 'Phân tích so sánh biến động danh điểm mặt hàng và bán hàng';
												|ru = 'Сравнительный анализ динамики ассортимента и продаж';
												|en = 'Comparative analysis of product range and sales trends'; fa = 'Comparative analysis of product range and sales trends';
												|it = 'Analisi comparativa della dinamica dell''assortimento e delle vendite';
												|pl = 'Analiza porównawcza dynamiki asortymentu i sprzedaży';
												|tr = 'Ürün gamı ve satış dinamiklerinin karşılaştırmalı analizi'") 
	+ ?(ThisIsTheTranscript, NStr("vi = '(chi tiết theo mặt hàng)';
									|ru = '(детально по номенклатуре)';
									|en = '(detailed by items)'; fa = '(detailed by items)';
									|it = '(dettagli in base agli articoli)';
									|pl = '(szczegółowy według nomenklatury)';
									|tr = '(öğeye göre ayrıntılı)'"), "");
	TabularDocumentResult.Put(HeaderArea_);
	
	TabularDocumentResult.StartRowAutoGrouping();
	TabularDocumentResult.StartColumnAutoGrouping();
	ReportParametersArea=Template.GetArea("ReportParameters");
	ParameterText_ = 
	  NStr("vi = 'Kỳ phân tích: từ';
			|ru = 'Период анализа : с';
			|en = 'Analysis period: from'; fa = 'Analysis period: from';
			|it = 'Periodo di analisi : dal';
			|pl = 'Okres analizy: od';
			|tr = 'Analiz dönemi : başlangıcı'")
	  + " " + Format(StartDateOfAnalysisPeriod, "DLF=D") + " "
	  + NStr("vi = 'đến';
			|ru = 'по';
			|en = 'to'; fa = 'تا';
			|it = 'al';
			|pl = 'do';
			|tr = 'bitişi'") + " "
	  + Format(EndDateOfAnalysisPeriod, "DLF=D")
	  + Chars.LF
	  + NStr("vi = 'Kỳ so sánh: từ';
			|ru = 'Период сравнения : с';
			|en = 'Comparison period: from'; fa = 'Comparison period: from';
			|it = 'Periodo di confronto : dal';
			|pl = 'Okres porównania: od';
			|tr = 'Karşılaştırma dönemi: başlangıcı'") + " "
	  + Format(StartDateOfComparisonPeriod, "DLF=D")
	  + " " + NStr("vi = 'đến';
					|ru = 'по';
					|en = 'to'; fa = 'تا';
					|it = 'al';
					|pl = 'do';
					|tr = 'bitişi'") + " "
	  + Format(EndDateOfComparisonPeriod, "DLF=D")
	  + Chars.LF;
	ReportParametersArea.Parameters.ReportParameters = ParameterText_;
	TabularDocumentResult.Put(ReportParametersArea,1);
	
	FixedTop = 5;
	If Not IsBlankString(FilterPresentation) Then
		ReportSelectionArea=Template.GetArea("ReportSelections");
		ReportSelectionArea.Parameters.ReportSelections = FilterPresentation;
		TabularDocumentResult.Put(ReportSelectionArea,1);
		FixedTop = 7;
	EndIf;
	
	DetailsStructure2 = New Structure;
	DetailsStructure2.Insert("StoreFormat", Undefined);
	DetailsStructure2.Insert("Store", Undefined);
	DetailsStructure2.Insert("ProductKind", Undefined);
	DetailsStructure2.Insert("ProductCategory", Undefined);
	DetailsStructure2.Insert("GroupName", Undefined);
	DetailsStructure2.Insert("GroupingLevel", Undefined);
	DetailsStructure2.Insert("AddDecryption", Not ThisIsTheTranscript);
	
	DisplayDimensions(SamplingLevel0, TabularDocumentResult, Template, 0, FieldArray, DetailsStructure2);
	
	TabularDocumentResult.EndColumnAutoGrouping();
	TabularDocumentResult.EndRowAutoGrouping();
	TabularDocumentResult.FixedTop = FixedTop;
	TabularDocumentResult.FixedLeft = 1;
	
	Return TabularDocumentResult;
EndFunction

Function DataSamplingResult(FilterPresentation, FieldArray)
	Query=New Query;
	Query.SetParameter("OtherBrands", NStr("vi = 'Nhãn hiệu khác';
											|ru = 'Прочие марки';
											|en = 'Other brands'; fa = 'Other brands';
											|it = 'Altri marchi';
											|pl = 'Inne marki';
											|tr = 'Diğer markalar'"));
	
	QueryText = InitialRequestText();
	
	StartDateOfAnalysisPeriod = AnalyzedPeriod.StartDate;
	EndDateOfAnalysisPeriod = AnalyzedPeriod.EndDate;
	StartDateOfComparisonPeriod = PeriodToCompareWith.StartDate;
	EndDateOfComparisonPeriod = PeriodToCompareWith.EndDate;
	If ValueIsFilled(StartDateOfAnalysisPeriod) Then
		Query.Parameters.Insert("StartDateOfAnalysisPeriod", StartDateOfAnalysisPeriod);
	Else
		MessageString = NStr("vi = 'Chưa chỉ ra ngày đầu kỳ phân tích';
							|ru = 'Не указана дата начала периода анализа';
							|en = 'Start date of analysis period is not specified'; fa = 'Start date of analysis period is not specified';
							|it = 'La data di inizio del periodo di analisi non è indicata';
							|pl = 'Nie podano daty rozpoczęcia okresu analizy';
							|tr = 'Analiz döneminin başlangıç tarihi belirtilmedi'");
		CommonClientServer.MessageToUser(MessageString);
		Return Undefined;
	EndIf;
	If ValueIsFilled(EndDateOfAnalysisPeriod) Then
		Query.Parameters.Insert("EndDateOfAnalysisPeriod", EndOfDay(EndDateOfAnalysisPeriod));
	Else
		MessageString = NStr("vi = 'Chưa chỉ ra ngày cuối kỳ phân tích';
							|ru = 'Не указана дата окончания периода анализа';
							|en = 'Analysis period end date is not specified'; fa = 'Analysis period end date is not specified';
							|it = 'La data di fine del periodo di analisi non è indicata';
							|pl = 'Nie podano daty zakończenia okresu analizy';
							|tr = 'Analiz döneminin bitiş tarihi belirtilmedi'");
		CommonClientServer.MessageToUser(MessageString);
		Return Undefined;
	EndIf;
	If ValueIsFilled(StartDateOfComparisonPeriod) Then
		Query.Parameters.Insert("StartDateOfComparisonPeriod", StartDateOfComparisonPeriod);
	Else
		MessageString = NStr("vi = 'Chưa chỉ ra ngày đầu kỳ so sánh';
							|ru = 'Не указана дата начала периода сравнения';
							|en = 'Specify the start date of comparison period'; fa = 'Specify the start date of comparison period';
							|it = 'La data di inizio del periodo di confronto non è indicata';
							|pl = 'Nie podano daty rozpoczęcia okresu porównania';
							|tr = 'Karşılaştırma döneminin başlangıç tarihi belirtilmedi'");
		CommonClientServer.MessageToUser(MessageString);
		Return Undefined;
	EndIf;
	If ValueIsFilled(EndDateOfComparisonPeriod) Then
		Query.Parameters.Insert("EndDateOfComparisonPeriod", EndOfDay(EndDateOfComparisonPeriod));
	Else
		MessageString = NStr("vi = 'Chưa chỉ ra ngày cuối kỳ so sánh';
							|ru = 'Не указана дата окончания периода сравнения';
							|en = 'Comparison period end date is not specified'; fa = 'Comparison period end date is not specified';
							|it = 'La data di fine del periodo di confronto non è indicata';
							|pl = 'Nie podano daty zakończenia okresu porównania';
							|tr = 'Karşılaştırma döneminin bitiş tarihi belirtilmedi'");
		CommonClientServer.MessageToUser(MessageString);
		Return Undefined;
	EndIf;
	
	If ThisIsTheTranscript Then
		DataParameters = SettingsComposer.FixedSettings.DataParameters;
		FilterParameters = SettingsComposer.FixedSettings.Filter;
	Else
		DataParameters = SettingsComposer.UserSettings;
		FilterParameters = SettingsComposer.UserSettings;
	EndIf;
	
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
				CommonClientServer.MessageToUser(MessageString);
				Return Undefined;
			EndIf;
			FilterPresentation = FilterPresentation + LeftValue + " " + CurViewOfComparison + " """ + RightValue + """" + Chars.LF;
		EndDo;
	EndIf;
	
	AddConditionsAndParameters(Query, QueryText, FilterItems1);
	
	Query.Text = QueryText;
	TableResultOfAnalysisPeriod = Query.Execute().Unload();
	
	QueryText = StrReplace(QueryText, "StartDateOfAnalysisPeriod", "StartDateOfComparisonPeriod");
	QueryText = StrReplace(QueryText, "EndDateOfAnalysisPeriod", "EndDateOfComparisonPeriod");
	RequestComparisonPeriod = New Query;
	RequestComparisonPeriod.Text = QueryText;
	For Each QueryParameter In Query.Parameters Do
		RequestComparisonPeriod.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	TableResultOfComparisonPeriod = RequestComparisonPeriod.Execute().Unload();
	Query = Undefined;
	RequestComparisonPeriod = Undefined;
	
	RequestTT = New Query;
	TempTablesManager = New TempTablesManager;
	RequestTT.TempTablesManager = TempTablesManager;
	RequestTT.Text = "SELECT
	|	T.StoreFormat AS StoreFormat,
	|	T.Store AS Store,
	|	T.ProductKind AS ProductKind,
	|	T.ProductCategory AS ProductCategory,
	|	T.Brand AS Brand,
	|	&QueryTextProducts,
	|	T.CountTurnover AS CountTurnover,
	|	T.RTNTurnover AS RTNTurnover,
	|	T.RevenueAmountExclVATLocalTurnover AS RevenueAmountExclVATLocalTurnover,
	|	T.Representation_ AS Representation_,
	|	T.Fullness_ AS Fullness_,
	|	&RequestTextRepresentationOfProducts AS RepresentationProducts,
	|	&RequestTextFullnessOfProducts AS FullnessOfProducts,
	|	T.Quota AS Quota,
	|	T.VariancePercentage AS VariancePercentage,
	|	T.RepresentationFormat AS RepresentationFormat,
	|	T.FullnessFormat AS FullnessFormat,
	|	T.QuotaFormat AS QuotaFormat,
	|	T.PercentageOfDeviationFormat AS PercentageOfDeviationFormat
	|INTO TableResultOfAnalysisPeriod
	|FROM
	|	&TableResultOfAnalysisPeriod AS T
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.StoreFormat AS StoreFormat,
	|	T.Store AS Store,
	|	T.ProductKind AS ProductKind,
	|	T.ProductCategory AS ProductCategory,
	|	T.Brand AS Brand,
	|	&QueryTextProducts,
	|	T.CountTurnover AS CountTurnover,
	|	T.RTNTurnover AS RTNTurnover,
	|	T.RevenueAmountExclVATLocalTurnover AS RevenueAmountExclVATLocalTurnover,
	|	T.Representation_ AS Representation_,
	|	T.Fullness_ AS Fullness_,
	|	&RequestTextRepresentationOfProducts AS RepresentationProducts,
	|	&RequestTextFullnessOfProducts AS FullnessOfProducts,
	|	T.Quota AS Quota,
	|	T.VariancePercentage AS VariancePercentage,
	|	T.RepresentationFormat AS RepresentationFormat,
	|	T.FullnessFormat AS FullnessFormat,
	|	T.QuotaFormat AS QuotaFormat,
	|	T.PercentageOfDeviationFormat AS PercentageOfDeviationFormat
	|INTO TableResultOfComparisonPeriod
	|FROM
	|	&TableResultOfComparisonPeriod AS T";
	
	RequestTT.SetParameter("TableResultOfAnalysisPeriod",TableResultOfAnalysisPeriod);
	RequestTT.SetParameter("TableResultOfComparisonPeriod",TableResultOfComparisonPeriod);
	
	RequestTT.Text = StrReplace(
		RequestTT.Text, 
		"&QueryTextProducts,", 
		?(ThisIsTheTranscript, "T.Products AS Products,", ""));
	
	RequestTT.Text = StrReplace(
		RequestTT.Text, 
		"&RequestTextRepresentationOfProducts", 
		?(ThisIsTheTranscript, "T.RepresentationProducts", "0"));
	
	RequestTT.Text = StrReplace(
		RequestTT.Text, 
		"&RequestTextFullnessOfProducts", 
		?(ThisIsTheTranscript, "T.FullnessOfProducts", "0"));
	
	RequestTT.Execute();
	RequestTT = Undefined;
	
	SummaryRequest = New Query;
	SummaryRequest.TempTablesManager = TempTablesManager;
	
	If ThisIsTheTranscript Then
		FieldArray.Add("StoreFormat");
		FieldArray.Add("Store");
		FieldArray.Add("ProductKind");
		FieldArray.Add("ProductCategory");
		FieldArray.Add("Brand");
		FieldArray.Add("Products");
		
		TextOfSelectedFields_ = "SELECT
		|	SubqueryResult.StoreFormat AS StoreFormat,
		|	SubqueryResult.StoreFormat.Description AS StoreFormatName,
		|	SubqueryResult.StoreFormat.DeletionMark AS MarkDeleteStoreFormat,
		|	SubqueryResult.Store AS Store,
		|	SubqueryResult.Store.DeletionMark AS TagDeleteStore,
		|	SubqueryResult.Store.Description AS StoreName,
		|	SubqueryResult.ProductKind AS ProductKind,
		|	SubqueryResult.ProductKind.DeletionMark AS MarkingDeletionTypeOfProduct,
		|	SubqueryResult.ProductKind.Description AS NameTypeOfProduct,
		|	SubqueryResult.ProductCategory AS ProductCategory,
		|	SubqueryResult.ProductCategory.DeletionMark AS TagDeletionProductCategory,
		|	SubqueryResult.ProductCategory.Description AS NameProductCategory,
		|	SubqueryResult.Brand AS Brand,
		|	SubqueryResult.Brand.DeletionMark AS MarkMark,
		|	SubqueryResult.Brand.Description AS NameAndBrand,
		|	SubqueryResult.Products AS Products,
		|	SubqueryResult.Products.DeletionMark AS MarkingAndProducts,
		|	SubqueryResult.Products.Description AS NameProductRange" + ",";
		
		DimensionsText = "
		|	SubqueryResult.StoreFormat,
		|	SubqueryResult.Store,
		|	SubqueryResult.ProductKind,
		|	SubqueryResult.ProductCategory,
		|	SubqueryResult.Brand,
		|	SubqueryResult.Products
		|";
		
		TextOfResults = "
		|	StoreFormat,
		|	Store,
		|	ProductKind,
		|	ProductCategory,
		|	Brand
		|";
		
		OrderingText = "
		|	StoreFormat.Description,
		|	StoreFormat,
		|	Store.Description,
		|	Store,
		|	ProductKind.Parent.Description,
		|	ProductKind.Description,
		|	ProductKind,
		|	ProductCategory.Parent.Parent.Description,
		|	ProductCategory.Parent.Description,
		|	ProductCategory.Description,
		|	ProductCategory,
		|	Brand.Description,
		|	Brand,
		|	Products.Description,
		|	Products
		|";
		
		ConditionIndicators = "";
		
		AdditionalConditionHaving = "
		|";
		If DrillDownColumnNumber = 2 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.CountTurnover) <> 0
			|	OR SUM(SubqueryResult.NumberOfDaysOfComparisonPeriod) <> 0
			|";
		ElsIf DrillDownColumnNumber = 3 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.RevenueAmountExclVATLocalTurnover) <> 0
			|	OR SUM(SubqueryResult.AmountOfRevenueLocalTurnoverOfComparisonPeriod) <> 0
			|";
		ElsIf DrillDownColumnNumber = 4 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.RTNTurnover) <> 0
			|	OR SUM(SubqueryResult.RTNTurnoverOfComparisonPeriod) <> 0
			|";
		ElsIf DrillDownColumnNumber = 5 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.Quota) <> 0
			|	OR SUM(SubqueryResult.ComparisonPeriodQuota) <> 0
			|";
		ElsIf DrillDownColumnNumber = 6 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.Fullness_) <> 0
			|	OR SUM(SubqueryResult.FullnessOfProducts) <> 0
			|	OR SUM(SubqueryResult.FullnessOfComparisonPeriod) <> 0
			|	OR SUM(SubqueryResult.FullnessProductRangeOfComparisonPeriod) <> 0
			|";
		ElsIf DrillDownColumnNumber = 7 Then
			AdditionalConditionHaving = "
			|	SUM(SubqueryResult.Representation_) <> 0
			|	OR SUM(SubqueryResult.RepresentationProducts) <> 0
			|	OR SUM(SubqueryResult.RepresentationOfComparisonPeriod) <> 0
			|	OR SUM(SubqueryResult.RepresentationProductsOfComparisonPeriod) <> 0
			|";
		EndIf;
		
	Else
		FieldArray.Add("StoreFormat");
		FieldArray.Add("Store");
		FieldArray.Add("ProductKind");
		FieldArray.Add("ProductCategory");
		
		TextOfSelectedFields_ = "SELECT
		|	SubqueryResult.StoreFormat AS StoreFormat,
		|	SubqueryResult.StoreFormat.Description AS StoreFormatName,
		|	SubqueryResult.StoreFormat.DeletionMark AS MarkDeleteStoreFormat,
		|	SubqueryResult.Store AS Store,
		|	SubqueryResult.Store.DeletionMark AS TagDeleteStore,
		|	SubqueryResult.Store.Description AS StoreName,
		|	SubqueryResult.ProductKind AS ProductKind,
		|	SubqueryResult.ProductKind.DeletionMark AS MarkingDeletionTypeOfProduct,
		|	SubqueryResult.ProductKind.Description AS NameTypeOfProduct,
		|	SubqueryResult.ProductCategory AS ProductCategory,
		|	SubqueryResult.ProductCategory.DeletionMark AS TagDeletionProductCategory,
		|	SubqueryResult.ProductCategory.Description AS NameProductCategory" + ",";
		
		DimensionsText = "
		|	SubqueryResult.StoreFormat,
		|	SubqueryResult.Store,
		|	SubqueryResult.ProductKind,
		|	SubqueryResult.ProductCategory
		|";
		
		TextOfResults = "
		|	StoreFormat,
		|	Store,
		|	ProductKind
		|";
		
		OrderingText = "
		|	StoreFormat.Description,
		|	StoreFormat,
		|	Store.Description,
		|	Store,
		|	ProductKind.Parent.Description,
		|	ProductKind.Description,
		|	ProductKind,
		|	ProductCategory.Parent.Parent.Description,
		|	ProductCategory.Parent.Description,
		|	ProductCategory.Description,
		|	ProductCategory
		|";
		
		AdditionalConditionHaving = "
		|	SUM(SubqueryResult.CountTurnover) <> 0
		|	OR SUM(SubqueryResult.RevenueAmountExclVATLocalTurnover) <> 0
		|	OR SUM(SubqueryResult.RTNTurnover) <> 0
		|	OR SUM(SubqueryResult.Representation_) <> 0
		|	OR SUM(SubqueryResult.Fullness_) <> 0
		|	OR SUM(SubqueryResult.RepresentationProducts) <> 0
		|	OR SUM(SubqueryResult.FullnessOfProducts) <> 0
		|	OR SUM(SubqueryResult.Quota) <> 0
		|	OR SUM(SubqueryResult.NumberOfDaysOfComparisonPeriod) <> 0
		|	OR SUM(SubqueryResult.AmountOfRevenueLocalTurnoverOfComparisonPeriod) <> 0
		|	OR SUM(SubqueryResult.RTNTurnoverOfComparisonPeriod) <> 0
		|	OR SUM(SubqueryResult.RepresentationOfComparisonPeriod) <> 0
		|	OR SUM(SubqueryResult.FullnessOfComparisonPeriod) <> 0
		|	OR SUM(SubqueryResult.ComparisonPeriodQuota) <> 0
		|";
	EndIf;
	RequestTextSummary = TextOfSelectedFields_ + "
	|	SUM(SubqueryResult.CountTurnover) AS CountTurnover,
	|	SUM(SubqueryResult.NumberOfDaysOfComparisonPeriod) AS NumberOfDaysOfComparisonPeriod,
	|	SUM(SubqueryResult.CountTurnover) - SUM(SubqueryResult.NumberOfDaysOfComparisonPeriod) AS ChangeQuantityAbsolute,
	|	0 AS RelativeNumberChange,
	|	SUM(SubqueryResult.RevenueAmountExclVATLocalTurnover) AS RevenueTurnover,
	|	SUM(SubqueryResult.AmountOfRevenueLocalTurnoverOfComparisonPeriod) AS RevenueTurnoverOfComparisonPeriod,
	|	SUM(SubqueryResult.RevenueAmountExclVATLocalTurnover) - SUM(SubqueryResult.AmountOfRevenueLocalTurnoverOfComparisonPeriod) AS ChangeInRevenueAmountAbsolute,
	|	0 AS RelativeRevenueAmountChange,
	|	SUM(SubqueryResult.RTNTurnover) AS RTNTurnover,
	|	SUM(SubqueryResult.RTNTurnoverOfComparisonPeriod) AS RTNTurnoverOfComparisonPeriod,
	|	SUM(SubqueryResult.RTNTurnover) - SUM(SubqueryResult.RTNTurnoverOfComparisonPeriod) AS ChangeInRtnabsolute,
	|	0 AS RelativeGrossProfitChange,
	|	SUM(SubqueryResult.Representation_) AS Representation_,
	|	SUM(SubqueryResult.RepresentationOfComparisonPeriod) AS RepresentationOfComparisonPeriod,
	|	SUM(SubqueryResult.Fullness_) AS Fullness_,
	|	SUM(SubqueryResult.FullnessOfComparisonPeriod) AS FullnessOfComparisonPeriod,
	|	SUM(SubqueryResult.RepresentationProducts) AS RepresentationProducts,
	|	SUM(SubqueryResult.RepresentationProductsOfComparisonPeriod) AS RepresentationProductsOfComparisonPeriod,
	|	SUM(SubqueryResult.FullnessOfProducts) AS FullnessOfProducts,
	|	SUM(SubqueryResult.FullnessProductRangeOfComparisonPeriod) AS FullnessProductRangeOfComparisonPeriod,
	|	SUM(SubqueryResult.Quota) AS Quota,
	|	SUM(SubqueryResult.ComparisonPeriodQuota) AS ComparisonPeriodQuota,
	|	MAX(SubqueryResult.VariancePercentage) AS VariancePercentage,
	|	MAX(SubqueryResult.PercentageDeviationOfComparisonPeriod) AS PercentageDeviationOfComparisonPeriod,
	|	0 AS RejectionOfRepresentation,
	|	0 AS DeviationOfFullness,
	|	MAX(SubqueryResult.RepresentationFormat) AS RepresentationFormat,
	|	MAX(SubqueryResult.RepresentationFormatOfComparisonPeriod) AS RepresentationFormatOfComparisonPeriod,
	|	MAX(SubqueryResult.FullnessFormat) AS FullnessFormat,
	|	MAX(SubqueryResult.FullnessFormatOfComparisonPeriod) AS FullnessFormatOfComparisonPeriod,
	|	MAX(SubqueryResult.QuotaFormat) AS QuotaFormat,
	|	MAX(SubqueryResult.QuotaFormatOfComparisonPeriod) AS QuotaFormatOfComparisonPeriod,
	|	MAX(SubqueryResult.PercentageOfDeviationFormat) AS PercentageOfDeviationFormat,
	|	MAX(SubqueryResult.PercentageOfDeviationFormatOfComparisonPeriod) AS PercentageOfDeviationFormatOfComparisonPeriod
	|
	|INTO TTSubqueryResult
	|FROM
	|	(SELECT
	|		T.StoreFormat AS StoreFormat,
	|		T.Store AS Store,
	|		T.ProductKind AS ProductKind,
	|		T.ProductCategory AS ProductCategory,
	|		T.Brand AS Brand,
	|		" + ?(ThisIsTheTranscript, "T.Products AS Products,", "") + "
	|		T.CountTurnover AS CountTurnover,
	|		T.RTNTurnover AS RTNTurnover,
	|		T.RevenueAmountExclVATLocalTurnover AS RevenueAmountExclVATLocalTurnover,
	|		T.Representation_ AS Representation_,
	|		T.Fullness_ AS Fullness_,
	|		T.RepresentationProducts AS RepresentationProducts,
	|		T.FullnessOfProducts AS FullnessOfProducts,
	|		T.Quota AS Quota,
	|		T.VariancePercentage AS VariancePercentage,
	|		T.RepresentationFormat AS RepresentationFormat,
	|		T.FullnessFormat AS FullnessFormat,
	|		T.QuotaFormat AS QuotaFormat,
	|		T.PercentageOfDeviationFormat AS PercentageOfDeviationFormat,
	|		0 AS NumberOfDaysOfComparisonPeriod,
	|		0 AS RTNTurnoverOfComparisonPeriod,
	|		0 AS AmountOfRevenueLocalTurnoverOfComparisonPeriod,
	|		0 AS RepresentationOfComparisonPeriod,
	|		0 AS FullnessOfComparisonPeriod,
	|		0 AS RepresentationProductsOfComparisonPeriod,
	|		0 AS FullnessProductRangeOfComparisonPeriod,
	|		0 AS ComparisonPeriodQuota,
	|		0 AS PercentageDeviationOfComparisonPeriod,
	|		0 AS RepresentationFormatOfComparisonPeriod,
	|		0 AS FullnessFormatOfComparisonPeriod,
	|		0 AS QuotaFormatOfComparisonPeriod,
	|		0 AS PercentageOfDeviationFormatOfComparisonPeriod
	|	FROM
	|		TableResultOfAnalysisPeriod AS T
	|	WHERE
	|		NOT T.Store IS NULL
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		T.StoreFormat,
	|		T.Store,
	|		T.ProductKind,
	|		T.ProductCategory,
	|		T.Brand,
	|		" + ?(ThisIsTheTranscript, "T.Products,", "") + "
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		T.CountTurnover,
	|		T.RTNTurnover,
	|		T.RevenueAmountExclVATLocalTurnover,
	|		T.Representation_,
	|		T.Fullness_,
	|		T.RepresentationProducts,
	|		T.FullnessOfProducts,
	|		T.Quota,
	|		T.VariancePercentage,
	|		T.RepresentationFormat,
	|		T.FullnessFormat,
	|		T.QuotaFormat,
	|		T.PercentageOfDeviationFormat
	|	FROM
	|		TableResultOfComparisonPeriod AS T
	|	WHERE
	|		NOT T.Store IS NULL
	|		) AS SubqueryResult
	|
	|GROUP BY " + DimensionsText + "
	|HAVING " + AdditionalConditionHaving + "
	|;
	|" + TextOfSelectedFields_ + "
	|	SubqueryResult.CountTurnover AS CountTurnover,
	|	SubqueryResult.NumberOfDaysOfComparisonPeriod AS NumberOfDaysOfComparisonPeriod,
	|	SubqueryResult.ChangeQuantityAbsolute AS ChangeQuantityAbsolute,
	|	CASE WHEN SubqueryResult.NumberOfDaysOfComparisonPeriod = 0 THEN 0
	|		ELSE (SubqueryResult.CountTurnover - SubqueryResult.NumberOfDaysOfComparisonPeriod) * 100 / SubqueryResult.NumberOfDaysOfComparisonPeriod
	|	END AS RelativeNumberChange,
	|	SubqueryResult.RevenueTurnover AS RevenueTurnover,
	|	SubqueryResult.RevenueTurnoverOfComparisonPeriod AS RevenueTurnoverOfComparisonPeriod,
	|	SubqueryResult.ChangeInRevenueAmountAbsolute AS ChangeInRevenueAmountAbsolute,
	|	CASE WHEN SubqueryResult.RevenueTurnoverOfComparisonPeriod = 0 THEN 0
	|		ELSE (SubqueryResult.RevenueTurnover - SubqueryResult.RevenueTurnoverOfComparisonPeriod) * 100 / SubqueryResult.RevenueTurnoverOfComparisonPeriod
	|	END AS RelativeRevenueAmountChange,
	|	SubqueryResult.RTNTurnover AS RTNTurnover,
	|	SubqueryResult.RTNTurnoverOfComparisonPeriod AS RTNTurnoverOfComparisonPeriod,
	|	SubqueryResult.ChangeInRtnabsolute AS ChangeInRtnabsolute,
	|	CASE WHEN SubqueryResult.RTNTurnoverOfComparisonPeriod = 0 THEN 0
	|		ELSE (SubqueryResult.RTNTurnover - SubqueryResult.RTNTurnoverOfComparisonPeriod) * 100 / SubqueryResult.RTNTurnoverOfComparisonPeriod
	|	END AS RelativeGrossProfitChange,
	|	SubqueryResult.Representation_ AS Representation_,
	|	SubqueryResult.RepresentationOfComparisonPeriod AS RepresentationOfComparisonPeriod,
	|	SubqueryResult.Fullness_ AS Fullness_,
	|	SubqueryResult.FullnessOfComparisonPeriod AS FullnessOfComparisonPeriod,
	|	SubqueryResult.RepresentationProducts AS RepresentationProducts,
	|	SubqueryResult.RepresentationProductsOfComparisonPeriod AS RepresentationProductsOfComparisonPeriod,
	|	SubqueryResult.FullnessOfProducts AS FullnessOfProducts,
	|	SubqueryResult.FullnessProductRangeOfComparisonPeriod AS FullnessProductRangeOfComparisonPeriod,
	|	SubqueryResult.Quota AS Quota,
	|	SubqueryResult.ComparisonPeriodQuota AS ComparisonPeriodQuota,
	|	SubqueryResult.VariancePercentage AS VariancePercentage,
	|	SubqueryResult.PercentageDeviationOfComparisonPeriod AS PercentageDeviationOfComparisonPeriod,
	|	CASE WHEN SubqueryResult.Quota < SubqueryResult.Fullness_ THEN
	|		CASE WHEN SubqueryResult.Quota = 0 THEN 0
	|			ELSE (SubqueryResult.Representation_ - SubqueryResult.Quota) * 100 / SubqueryResult.Quota
	|		END 
	|	ELSE
	|		CASE WHEN SubqueryResult.Fullness_ = 0 THEN 0
	|			ELSE (SubqueryResult.Representation_ - SubqueryResult.Fullness_) * 100 / SubqueryResult.Fullness_
	|		END 
	|	END AS RejectionOfRepresentation,
	|	CASE WHEN SubqueryResult.Quota = 0 THEN 0
	|		ELSE (SubqueryResult.Fullness_ - SubqueryResult.Quota) * 100 / SubqueryResult.Quota
	|	END AS DeviationOfFullness,
	|	SubqueryResult.RepresentationFormat AS RepresentationFormat,
	|	SubqueryResult.RepresentationFormatOfComparisonPeriod AS RepresentationFormatOfComparisonPeriod,
	|	SubqueryResult.FullnessFormat AS FullnessFormat,
	|	SubqueryResult.FullnessFormatOfComparisonPeriod AS FullnessFormatOfComparisonPeriod,
	|	SubqueryResult.QuotaFormat AS QuotaFormat,
	|	SubqueryResult.QuotaFormatOfComparisonPeriod AS QuotaFormatOfComparisonPeriod,
	|	SubqueryResult.PercentageOfDeviationFormat AS PercentageOfDeviationFormat,
	|	SubqueryResult.PercentageOfDeviationFormatOfComparisonPeriod AS PercentageOfDeviationFormatOfComparisonPeriod
	|FROM TTSubqueryResult AS SubqueryResult
	|WHERE TRUE AND &ConditionIndicators
	|
	|ORDER BY " + OrderingText + "
	|TOTALS
	|	SUM(CountTurnover) AS CountTurnover,
	|	SUM(RevenueTurnover) AS RevenueTurnover,
	|	SUM(RTNTurnover) AS RTNTurnover,
	|	SUM(Representation_) AS Representation_,
	|	SUM(Fullness_) AS Fullness_,
	|	SUM(RepresentationProducts) AS RepresentationProducts,
	|	SUM(FullnessOfProducts) AS FullnessOfProducts,
	|	SUM(Quota) AS Quota,
	|	CAST(AVG(VariancePercentage) AS NUMBER(10, 0)) AS VariancePercentage,
	|	MAX(RepresentationFormat),
	|	MAX(FullnessFormat),
	|	MAX(QuotaFormat),
	|	CAST(AVG(PercentageOfDeviationFormat) AS NUMBER(10, 0)) AS PercentageOfDeviationFormat,
	|	SUM(NumberOfDaysOfComparisonPeriod),
	|	SUM(RevenueTurnoverOfComparisonPeriod),
	|	SUM(RTNTurnoverOfComparisonPeriod),
	|	SUM(RepresentationOfComparisonPeriod),
	|	SUM(FullnessOfComparisonPeriod),
	|	SUM(RepresentationProductsOfComparisonPeriod),
	|	SUM(FullnessProductRangeOfComparisonPeriod),
	|	SUM(ComparisonPeriodQuota),
	|	CAST(AVG(PercentageDeviationOfComparisonPeriod) AS NUMBER(10, 0)) AS PercentageDeviationOfComparisonPeriod,
	|	MAX(RepresentationFormatOfComparisonPeriod),
	|	MAX(FullnessFormatOfComparisonPeriod),
	|	MAX(QuotaFormatOfComparisonPeriod),
	|	CAST(AVG(PercentageOfDeviationFormatOfComparisonPeriod) AS NUMBER(10, 0)) AS PercentageOfDeviationFormatOfComparisonPeriod
	|BY " + TextOfResults + "
	|";

	ConditionCounter = 0;
	ParameterCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("RelativeNumberChange", "_ConditionChangeInQuantityRelative");
	MatchingConditionFields.Insert("RelativeRevenueAmountChange", "_ConditionChangeInRevenueAmountRelative");
	MatchingConditionFields.Insert("RelativeGrossProfitChange", "_ConditionChangeInGrossProfitRelative");
	InitialConditionText = "WHERE";
	GroupCondition = "";
	ConditionText = "";
	GenerateConditionText(SummaryRequest,
							 FilterItems1,
							 ConditionText,
							 ConditionCounter,
							 ParameterCounter,
							 InitialConditionText,
							 GroupCondition,
							 MatchingConditionFields);
	RequestTextSummary = StrReplace(RequestTextSummary, "&ConditionIndicators", TrimAll(ConditionText));
	RequestTextSummary = StrReplace(RequestTextSummary,
										"_ConditionChangeInQuantityRelative",
										"CASE WHEN SubqueryResult.NumberOfDaysOfComparisonPeriod = 0 THEN 0
										|		ELSE (SubqueryResult.CountTurnover - SubqueryResult.NumberOfDaysOfComparisonPeriod) * 100 / SubqueryResult.NumberOfDaysOfComparisonPeriod
										|	END");
	RequestTextSummary = StrReplace(RequestTextSummary,
										"_ConditionChangeInRevenueAmountRelative",
										"CASE WHEN SubqueryResult.RevenueTurnoverOfComparisonPeriod = 0 THEN 0
										|		ELSE (SubqueryResult.RevenueTurnover - SubqueryResult.RevenueTurnoverOfComparisonPeriod) * 100 / SubqueryResult.RevenueTurnoverOfComparisonPeriod
										|	END");
	RequestTextSummary = StrReplace(RequestTextSummary,
										"_ConditionChangeInGrossProfitRelative",
										"CASE WHEN SubqueryResult.RTNTurnoverOfComparisonPeriod = 0 THEN 0
										|		ELSE (SubqueryResult.RTNTurnover - SubqueryResult.RTNTurnoverOfComparisonPeriod) * 100 / SubqueryResult.RTNTurnoverOfComparisonPeriod
										|	END");
										
	SummaryRequest.Text = RequestTextSummary;
	Result = SummaryRequest.Execute();
	Return Result;
EndFunction

Function InitialRequestText()
	QueryText = RequestTextForDaysOfPeriod()
		+ FormatTableQueryText()
		+ QueryTextQuotas()
		+ RequestTextTurnoverOfGoodsInWarehouses()
		+ QueryTextProductRange()
		+ QueryTextRevenue()
		+ RequestTextSubtotals()
		+ QueryTextSummaryTables();
	
	Return QueryText;
EndFunction

Function RequestTextForDaysOfPeriod()
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// A temporary table of all days of the period 
	|// between the datachal period and the end period is formed
	|SELECT
	|	0 AS Figure
	|INTO TableOfFigures
	|
	|UNION ALL
	|
	|SELECT
	|	1
	|
	|UNION ALL
	|
	|SELECT
	|	2
	|
	|UNION ALL
	|
	|SELECT
	|	3
	|
	|UNION ALL
	|
	|SELECT
	|	4
	|
	|UNION ALL
	|
	|SELECT
	|	5
	|
	|UNION ALL
	|
	|SELECT
	|	6
	|
	|UNION ALL
	|
	|SELECT
	|	7
	|
	|UNION ALL
	|
	|SELECT
	|	8
	|
	|UNION ALL
	|
	|SELECT
	|	9
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DATEADD(&StartDateOfAnalysisPeriod, DAY, TableOfFigures1.Figure + 10 * TableOfFigures2.Figure + 100 * TableOfFigures3.Figure + 1000 * TableOfFigures4.Figure) AS Day
	|INTO TTDays
	|FROM
	|	TableOfFigures AS TableOfFigures1,
	|	TableOfFigures AS TableOfFigures2,
	|	TableOfFigures AS TableOfFigures3,
	|	TableOfFigures AS TableOfFigures4
	|WHERE
	|	DATEADD(&StartDateOfAnalysisPeriod, DAY, TableOfFigures1.Figure + 10 * TableOfFigures2.Figure + 100 * TableOfFigures3.Figure + 1000 * TableOfFigures4.Figure) <= &EndDateOfAnalysisPeriod
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// A temporary table of all months of the period
	|// is formed according to the vtDays table
	|SELECT
	|	BEGINOFPERIOD(SD.Day, MONTH) AS Month
	|INTO TableOfMonths
	|FROM
	|	TTDays AS SD
	|
	|GROUP BY
	|	BEGINOFPERIOD(SD.Day, MONTH)
	|;
	|";
	
	Return QueryText;
EndFunction

Function FormatTableQueryText()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	HistoryOfFormats.StoreFormat AS StoreFormat,
	|	HistoryOfFormats.Warehouse AS Warehouse
	|INTO HistoryOfFormats
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&StartDateOfAnalysisPeriod, Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)) AS HistoryOfFormats
	|WHERE
	|	HistoryOfFormats.StoreFormat <> VALUE(Catalog.StoreFormats.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// auxiliary tables of days and months of the period are formed according to the formats of stores, stores
	|SELECT
	|	ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)) AS StoreFormat,
	|	HistoryOfFormats.Warehouse AS Warehouse,
	|	TTTD.Day AS Day
	|INTO TableOfDaysAndWarehouses
	|FROM
	|	TTDays AS TTTD
	|		LEFT JOIN HistoryOfFormats AS HistoryOfFormats
	|		ON TRUE
	|		AND &ConditionStores
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Formats.Ref AS StoreFormat,
	|	TTTD.Day AS Day
	|INTO TableOfDaysAndFormats
	|FROM
	|	TTDays AS TTTD
	|		LEFT JOIN Catalog.StoreFormats AS Formats
	|		ON (NOT Formats.IsFolder)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Formats.Ref AS StoreFormat,
	|	TM.Month AS Month
	|INTO TableOfMonthsAndFormats
	|FROM
	|	TableOfMonths AS TM
	|		LEFT JOIN Catalog.StoreFormats AS Formats
	|		ON (NOT Formats.IsFolder)
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextQuotas()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// At the beginning of each month, a cut of the assortment quotas is obtained
	|SELECT
	|	TableOfMonthsAndFormats.Month AS Period,
	|	TableOfMonthsAndFormats.StoreFormat AS StoreFormat,
	|	Quotas.ProductCategory.Owner AS ProductKind,
	|	Quotas.ProductCategory AS ProductCategory,
	|	CASE
	|		WHEN Quotas.Brand = VALUE(Catalog.Brands.EmptyRef)
	|			THEN &OtherBrands
	|		ELSE Quotas.Brand
	|	END AS Brand,
	|	Quotas.Quota AS Quota,
	|	Quotas.VariancePercentage AS VariancePercentage
	|INTO TTCurQuotasWithoutStores
	|FROM
	|	TableOfMonthsAndFormats AS TableOfMonthsAndFormats
	|		LEFT JOIN InformationRegister.ProductMixQuotas AS Quotas
	|		ON TableOfMonthsAndFormats.StoreFormat = Quotas.PlanningObject
	|			AND &QuotaCondition
	|			AND (Quotas.Period IN
	|				(SELECT
	|					MAX(K.Period)
	|				FROM
	|					InformationRegister.ProductMixQuotas AS K
	|				WHERE
	|					K.Period <= TableOfMonthsAndFormats.Month
	|					AND K.PlanningObject = TableOfMonthsAndFormats.StoreFormat))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTCurQuotasWithoutStores.Period,
	|	TTCurQuotasWithoutStores.StoreFormat,
	|	HistoryOfFormats.Warehouse AS Store,
	|	TTCurQuotasWithoutStores.ProductKind,
	|	TTCurQuotasWithoutStores.ProductCategory,
	|	TTCurQuotasWithoutStores.Brand,
	|	TTCurQuotasWithoutStores.Quota,
	|	TTCurQuotasWithoutStores.VariancePercentage
	|INTO TTCurQuotas
	|FROM
	|	TTCurQuotasWithoutStores AS TTCurQuotasWithoutStores
	|		LEFT JOIN HistoryOfFormats AS HistoryOfFormats
	|		ON TTCurQuotasWithoutStores.StoreFormat = HistoryOfFormats.StoreFormat
	|			AND &ConditionStores
	|;
	|";
	If ThisIsTheTranscript Then
		QueryText = QueryText + "
		|////////////////////////////////////////////////////////////////////////////////
		|// additional temporary quota table for 
		|// subsequent connection from the connection to the Product
		|// list by Brand field
		|SELECT
		|	Quotas.PlanningObject AS StoreFormat,
		|	Quotas.ProductCategory.Owner AS ProductKind,
		|	Quotas.ProductCategory AS ProductCategory,
		|	Quotas.Brand AS Brand,
		|	Quotas.Quota AS Quota,
		|	Quotas.VariancePercentage AS VariancePercentage
		|INTO TTCurQuotasNormal
		|FROM
		|	InformationRegister.ProductMixQuotas.SliceLast(&EndDateOfAnalysisPeriod, &QuotaCutCondition
		|	) AS Quotas
		|		INNER JOIN Catalog.StoreFormats AS Formats
		|		ON Quotas.PlanningObject = Formats.Ref
		|			AND (Quotas.Period IN
		|				(SELECT
		|					MAX(K.Period)
		|				FROM
		|					InformationRegister.ProductMixQuotas AS K
		|				WHERE
		|					K.Period <= &EndDateOfAnalysisPeriod
		|					AND K.PlanningObject = Formats.Ref))
		|;
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextTurnoverOfGoodsInWarehouses()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.Warehouse AS Warehouse,
	|	Turnovers.Period AS Period,
	|	Turnovers.Products AS Products,
	|	SUM(Turnovers.InStockReceipt) AS RevenueForPeriod,
	|	SUM(Turnovers.InStockExpense) AS ExpenseForPeriod
	|INTO TTRevolutions
	|FROM
	|	AccumulationRegister.ProductStock.Turnovers(&StartDateOfAnalysisPeriod, &EndDateOfAnalysisPeriod, Day, Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) 
	|	AND &ConditionBalancesAndRevolutions
	|	) AS Turnovers
	|
	|GROUP BY
	|	Turnovers.Warehouse,
	|	Turnovers.Period,
	|	Turnovers.Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Warehouse AS Warehouse,
	|	Balance.Products AS Products,
	|	SUM(Balance.InStockBalance) AS OpeningBalance
	|INTO TTBalances
	|FROM
	|	AccumulationRegister.ProductStock.Balance(&StartDateOfAnalysisPeriod, Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|	AND &ConditionBalancesAndRevolutions
	|	) AS Balance
	|
	|GROUP BY
	|	Balance.Warehouse,
	|	Balance.Products
	|;
	|";
	If ThisIsTheTranscript Then
		QueryText = QueryText + "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|		ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)) AS StoreFormat,
		|		BalanceAndTurnovers.Warehouse AS Store,
		|		BalanceAndTurnovers.Products.ProductKind AS ProductKind,
		|		BalanceAndTurnovers.Products.ProductCategory AS ProductCategory,
		|		CASE
		|			WHEN CurQuotas.Brand.Description IS NULL 
		|				THEN &OtherBrands
		|			ELSE CurQuotas.Brand
		|		END AS Brand,
		|		BalanceAndTurnovers.Products AS Products
		|INTO TTRepresentationProductRange
		|FROM (SELECT 
		|		Turnovers.Warehouse AS Warehouse,
		|		Turnovers.Period AS Period,
		|		Turnovers.Products AS Products
		|	FROM
		|		TTRevolutions AS Turnovers
		|	UNION ALL
		|	SELECT
		|		Balance.Warehouse AS Warehouse,
		|		&StartDateOfAnalysisPeriod AS Period,
		|		Balance.Products AS Products
		|	FROM
		|		TTBalances AS Balance
		|) AS BalanceAndTurnovers
		|		LEFT JOIN TTCurQuotas AS CurQuotas
		|		ON (CurQuotas.Period = BEGINOFPERIOD(BalanceAndTurnovers.Period, MONTH))
		|			AND (CurQuotas.ProductCategory = BalanceAndTurnovers.Products.ProductCategory)
		|			AND (CurQuotas.Brand = BalanceAndTurnovers.Products.Brand)
		|			AND (CurQuotas.Store = BalanceAndTurnovers.Warehouse)
		|		LEFT JOIN HistoryOfFormats AS HistoryOfFormats
		|		ON BalanceAndTurnovers.Warehouse = HistoryOfFormats.Warehouse
		|;
		|";
	EndIf;
	QueryText = QueryText + "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfDays.StoreFormat AS StoreFormat,
	|	TableOfDays.Store AS Store,
	|	TableOfDays.ProductKind AS ProductKind,
	|	TableOfDays.ProductCategory AS ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END AS Brand,
	|	TableOfDays.Day AS Day,
	|	TableOfDays.Products AS Products,
	|	SUM(TableOfDays.OpeningBalance) AS OpeningBalance,
	|	SUM(TableOfDays.RevenueForPeriod) AS RevenueForPeriod,
	|	SUM(TableOfDays.ExpenseForPeriod) AS ExpenseForPeriod,
	|	SUM(TableOfDays.OpeningBalance) + SUM(TableOfDays.RevenueForPeriod) - SUM(TableOfDays.ExpenseForPeriod) AS ClosingBalance
	|INTO TTTableOfDaysWithGoods
	|FROM
	|	(SELECT
	|		SD.StoreFormat AS StoreFormat,
	|		SD.Warehouse AS Store,
	|		TTBalances.Products.ProductKind AS ProductKind,
	|		TTBalances.Products.ProductCategory AS ProductCategory,
	|		TTBalances.Products.Brand AS Brand,
	|		SD.Day AS Day,
	|		&StartDateOfAnalysisPeriod AS TrafficDay,
	|		TTBalances.Products AS Products,
	|		ISNULL(TTBalances.OpeningBalance, 0) AS OpeningBalance,
	|		0 AS RevenueForPeriod,
	|		0 AS ExpenseForPeriod
	|	FROM
	|		TableOfDaysAndWarehouses AS SD
	|			LEFT JOIN TTBalances AS TTBalances
	|			ON SD.Warehouse = TTBalances.Warehouse
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		SD.StoreFormat,
	|		SD.Warehouse,
	|		TTRevolutions.Products.ProductKind,
	|		TTRevolutions.Products.ProductCategory,
	|		TTRevolutions.Products.Brand,
	|		SD.Day,
	|		BEGINOFPERIOD(TTRevolutions.Period, Day),
	|		TTRevolutions.Products,
	|		0,
	|		ISNULL(TTRevolutions.RevenueForPeriod, 0),
	|		ISNULL(TTRevolutions.ExpenseForPeriod, 0)
	|	FROM
	|		TableOfDaysAndWarehouses AS SD
	|			LEFT JOIN TTRevolutions AS TTRevolutions
	|			ON SD.Warehouse = TTRevolutions.Warehouse
	|				AND (SD.Day >= BEGINOFPERIOD(TTRevolutions.Period, Day))) AS TableOfDays
	|		LEFT JOIN TTCurQuotas AS CurQuotas
	|		ON (CurQuotas.Period = BEGINOFPERIOD(TableOfDays.Day, MONTH))
	|			AND (CurQuotas.ProductCategory = TableOfDays.ProductCategory)
	|			AND (CurQuotas.Brand = TableOfDays.Brand)
	|			AND (CurQuotas.Store = TableOfDays.Store)
	|
	|GROUP BY
	|	TableOfDays.StoreFormat,
	|	TableOfDays.Store,
	|	TableOfDays.ProductKind,
	|	TableOfDays.ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END,
	|	TableOfDays.Day,
	|	TableOfDays.Products
	|
	|HAVING
	|	(SUM(TableOfDays.OpeningBalance) + SUM(TableOfDays.RevenueForPeriod) - SUM(TableOfDays.ExpenseForPeriod) > 0
	|		OR MAX(TableOfDays.TrafficDay) = TableOfDays.Day
	|			AND NOT TableOfDays.Products IS NULL )
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextProductRange()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// A temporary table of days with assortment products is being formed
	|SELECT
	|	TableOfDays.StoreFormat AS StoreFormat,
	|	TableOfDays.ProductKind AS ProductKind,
	|	TableOfDays.ProductCategory AS ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END AS Brand,
	|	TableOfDays.Day AS Day,
	|	TableOfDays.Products AS Products
	|INTO TTTableOfDaysWithAssortmentProducts
	|FROM
	|	(SELECT
	|		SD.StoreFormat AS StoreFormat,
	|		CatalogProducts.ProductKind AS ProductKind,
	|		CatalogProducts.ProductCategory AS ProductCategory,
	|		CatalogProducts.Brand AS Brand,
	|		SD.Day AS Day,
	|		CatalogProducts.Ref AS Products
	|	FROM
	|		TableOfDaysAndFormats AS SD
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON (NOT CatalogProducts.IsFolder)
	|			AND &ProductRangeCondition
	|			INNER JOIN InformationRegister.ProductRange AS ProductRange
	|			ON (ProductRange.Products = CatalogProducts.Ref)
	|				AND (ProductRange.PurchasesAreAllowed)
	|				AND (ProductRange.PlanningObject = SD.StoreFormat)
	|				AND &ConditionAssortment
	|				AND (ProductRange.Period IN
	|					(SELECT MAX(Assorted.Period) AS Period
	|					FROM
	|						InformationRegister.ProductRange AS Assorted
	|					WHERE
	|						Assorted.Products = ProductRange.Products
	|						AND Assorted.PlanningObject = ProductRange.PlanningObject
	|						AND Assorted.Period <= SD.Day))) AS TableOfDays
	|		LEFT JOIN TTCurQuotasWithoutStores AS CurQuotas
	|		ON (CurQuotas.Period = BEGINOFPERIOD(TableOfDays.Day, MONTH))
	|			AND (CurQuotas.ProductCategory = TableOfDays.ProductCategory)
	|			AND (CurQuotas.Brand = TableOfDays.Brand)
	|			AND (CurQuotas.StoreFormat = TableOfDays.StoreFormat)
	|
	|GROUP BY
	|	TableOfDays.StoreFormat,
	|	TableOfDays.ProductKind,
	|	TableOfDays.ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END,
	|	TableOfDays.Day,
	|	TableOfDays.Products
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextRevenue()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// a temporary revenue table is being generated
	|SELECT ALLOWED
	|	ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)) AS StoreFormat,
	|	RevenueTurnover_.ItemsLocationAttributes.StorageLocation AS Store,
	|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductKind AS ProductKind,
	|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory AS ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END AS Brand,
	|	SUM(RevenueTurnover_.CountTurnover) AS CountTurnover,
	|	SUM(RevenueTurnover_.LocalCostTurnover) AS CostLocalTurnover,
	|	SUM(RevenueTurnover_.RevenueAmountExclVATLocalTurnover) AS RevenueAmountExclVATLocalTurnover
	|INTO RevenueTurnover_
	|FROM
	|	AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateOfAnalysisPeriod, &EndDateOfAnalysisPeriod, Day, ItemsLocationAttributes.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|	AND &RevenueCondition
	|	) AS RevenueTurnover_
	|		LEFT JOIN TTCurQuotas AS CurQuotas
	|		ON (CurQuotas.Period = BEGINOFPERIOD(RevenueTurnover_.Period, MONTH))
	|			AND (CurQuotas.ProductCategory = RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory)
	|			AND (CurQuotas.Brand = RevenueTurnover_.ItemsLocationAttributes.Products.Brand)
	|			AND (CurQuotas.Store = RevenueTurnover_.ItemsLocationAttributes.StorageLocation)
	|		LEFT JOIN HistoryOfFormats AS HistoryOfFormats
	|		ON RevenueTurnover_.ItemsLocationAttributes.StorageLocation = HistoryOfFormats.Warehouse
	|
	|GROUP BY
	|	ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)),
	|	RevenueTurnover_.ItemsLocationAttributes.StorageLocation,
	|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductKind,
	|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory,
	|	CASE
	|		WHEN CurQuotas.Brand.Description IS NULL 
	|			THEN &OtherBrands
	|		ELSE CurQuotas.Brand
	|	END
	|;
	|";
	If ThisIsTheTranscript Then
		QueryText = QueryText + "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)) AS StoreFormat,
		|	RevenueTurnover_.ItemsLocationAttributes.StorageLocation AS Store,
		|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductKind AS ProductKind,
		|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory AS ProductCategory,
		|	CASE
		|		WHEN CurQuotas.Brand.Description IS NULL 
		|			THEN &OtherBrands
		|		ELSE CurQuotas.Brand
		|	END AS Brand,
		|	RevenueTurnover_.ItemsLocationAttributes.Products AS Products,
		|	SUM(RevenueTurnover_.CountTurnover) AS CountTurnover,
		|	SUM(RevenueTurnover_.LocalCostTurnover) AS CostLocalTurnover,
		|	SUM(RevenueTurnover_.RevenueAmountExclVATLocalTurnover) AS RevenueAmountExclVATLocalTurnover
		|INTO RevenueTurnoverProducts
		|FROM
		|	AccumulationRegister.RevenueAndCOGS.Turnovers(&StartDateOfAnalysisPeriod, &EndDateOfAnalysisPeriod, , ItemsLocationAttributes.WarehouseArea.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore)
		|	AND &RevenueCondition
		|	) AS RevenueTurnover_
		|		LEFT JOIN HistoryOfFormats AS HistoryOfFormats
		|		ON RevenueTurnover_.ItemsLocationAttributes.StorageLocation = HistoryOfFormats.Warehouse
		|		LEFT JOIN TTCurQuotasNormal AS CurQuotas
		|		ON (CurQuotas.ProductCategory = RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory)
		|			AND (CurQuotas.Brand = RevenueTurnover_.ItemsLocationAttributes.Products.Brand)
		|			AND (CurQuotas.StoreFormat = ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)))
		|
		|GROUP BY
		|	ISNULL(HistoryOfFormats.StoreFormat, VALUE(Catalog.StoreFormats.EmptyRef)),
		|	RevenueTurnover_.ItemsLocationAttributes.StorageLocation,
		|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductKind,
		|	RevenueTurnover_.ItemsLocationAttributes.Products.ProductCategory,
		|	CASE
		|		WHEN CurQuotas.Brand.Description IS NULL 
		|			THEN &OtherBrands
		|		ELSE CurQuotas.Brand
		|	END,
		|	RevenueTurnover_.ItemsLocationAttributes.Products
		|;
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextSubtotals()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|// interim totals are calculated by day and additional tables are generated
	|SELECT
	|	TDT.StoreFormat AS StoreFormat,
	|	TDT.Store AS Store,
	|	TDT.ProductKind AS ProductKind,
	|	TDT.ProductCategory AS ProductCategory,
	|	TDT.Brand AS Brand,
	|	TDT.Day AS Day,
	|	COUNT(DISTINCT TDT.Products) AS QuantityOfProducts
	|INTO ResultsOfRepresentationByDay
	|FROM
	|	TTTableOfDaysWithGoods AS TDT
	|
	|GROUP BY
	|	TDT.StoreFormat,
	|	TDT.Store,
	|	TDT.ProductKind,
	|	TDT.ProductCategory,
	|	TDT.Brand,
	|	TDT.Day
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TDT.StoreFormat AS StoreFormat,
	|	TDT.ProductKind AS ProductKind,
	|	TDT.ProductCategory AS ProductCategory,
	|	TDT.Brand AS Brand,
	|	TDT.Day AS Day,
	|	COUNT(DISTINCT TDT.Products) AS QuantityOfProducts
	|INTO ResultsOfRepresentationByDaysFormat
	|FROM
	|	TTTableOfDaysWithGoods AS TDT
	|
	|GROUP BY
	|	TDT.StoreFormat,
	|	TDT.ProductKind,
	|	TDT.ProductCategory,
	|	TDT.Brand,
	|	TDT.Day
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Subquery2.StoreFormat,
	|	Subquery2.Store,
	|	Subquery2.ProductKind,
	|	Subquery2.ProductCategory,
	|	Subquery2.Brand,
	|	CAST(AVG(Subquery2.QuantityOfProducts) AS NUMBER(15, 0)) AS QuantityOfProducts
	|INTO ResultsOfRepresentationDetailed
	|FROM
	|	(SELECT
	|		Subquery.StoreFormat AS StoreFormat,
	|		Subquery.Store AS Store,
	|		Subquery.ProductKind AS ProductKind,
	|		Subquery.ProductCategory AS ProductCategory,
	|		Subquery.Brand AS Brand,
	|		Subquery.Day AS Day,
	|		SUM(Subquery.QuantityOfProducts) AS QuantityOfProducts
	|	FROM
	|		(SELECT
	|			TDS.StoreFormat AS StoreFormat,
	|			TDS.Warehouse AS Store,
	|			SoleProprietor.ProductKind AS ProductKind,
	|			SoleProprietor.ProductCategory AS ProductCategory,
	|			SoleProprietor.Brand AS Brand,
	|			TDS.Day AS Day,
	|			CASE
	|				WHEN TDS.Day = SoleProprietor.Day
	|					THEN SoleProprietor.QuantityOfProducts
	|				ELSE 0
	|			END AS QuantityOfProducts
	|		FROM
	|			TableOfDaysAndWarehouses AS TDS
	|				LEFT JOIN ResultsOfRepresentationByDay AS SoleProprietor
	|				ON (SoleProprietor.StoreFormat = TDS.StoreFormat)
	|					AND (SoleProprietor.Store = TDS.Warehouse)) AS Subquery
	|	
	|	GROUP BY
	|		Subquery.StoreFormat,
	|		Subquery.Store,
	|		Subquery.ProductKind,
	|		Subquery.ProductCategory,
	|		Subquery.Brand,
	|		Subquery.Day) AS Subquery2
	|
	|GROUP BY
	|	Subquery2.StoreFormat,
	|	Subquery2.Store,
	|	Subquery2.ProductKind,
	|	Subquery2.ProductCategory,
	|	Subquery2.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Subquery2.StoreFormat,
	|	CAST(AVG(Subquery2.QuantityOfProducts) AS NUMBER(10, 0)) AS QuantityOfProducts
	|INTO ResultsOfRepresentationFormat
	|FROM
	|	(SELECT
	|		Subquery.StoreFormat AS StoreFormat,
	|		Subquery.Day AS Day,
	|		SUM(Subquery.QuantityOfProducts) AS QuantityOfProducts
	|	FROM
	|		(SELECT
	|			TDF.StoreFormat AS StoreFormat,
	|			SoleProprietor.ProductKind AS ProductKind,
	|			SoleProprietor.ProductCategory AS ProductCategory,
	|			SoleProprietor.Brand AS Brand,
	|			TDF.Day AS Day,
	|			CASE
	|				WHEN TDF.Day = SoleProprietor.Day
	|					THEN SoleProprietor.QuantityOfProducts
	|				ELSE 0
	|			END AS QuantityOfProducts
	|		FROM
	|			TableOfDaysAndFormats AS TDF
	|				LEFT JOIN ResultsOfRepresentationByDaysFormat AS SoleProprietor
	|				ON (SoleProprietor.StoreFormat = TDF.StoreFormat)) AS Subquery
	|	
	|	GROUP BY
	|		Subquery.StoreFormat,
	|		Subquery.Day) AS Subquery2
	|
	|GROUP BY
	|	Subquery2.StoreFormat
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfFullness.StoreFormat,
	|	TableOfFullness.ProductKind,
	|	TableOfFullness.ProductCategory,
	|	TableOfFullness.Brand,
	|	CAST(AVG(TableOfFullness.QuantityOfProducts) AS NUMBER(15, 0)) AS QuantityOfProducts
	|INTO ResultsOfFullnessDetailed
	|FROM
	|	(SELECT
	|		TDTA.StoreFormat AS StoreFormat,
	|		TDTA.ProductKind AS ProductKind,
	|		TDTA.ProductCategory AS ProductCategory,
	|		TDTA.Brand AS Brand,
	|		TDTA.Day AS Day,
	|		COUNT(DISTINCT TDTA.Products) AS QuantityOfProducts
	|	FROM
	|		TTTableOfDaysWithAssortmentProducts AS TDTA
	|	
	|	GROUP BY
	|		TDTA.StoreFormat,
	|		TDTA.ProductKind,
	|		TDTA.ProductCategory,
	|		TDTA.Brand,
	|		TDTA.Day) AS TableOfFullness
	|
	|GROUP BY
	|	TableOfFullness.StoreFormat,
	|	TableOfFullness.ProductKind,
	|	TableOfFullness.ProductCategory,
	|	TableOfFullness.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfFullness.StoreFormat,
	|	CAST(AVG(TableOfFullness.QuantityOfProducts) AS NUMBER(15, 0)) AS QuantityOfProducts
	|INTO ResultsOfFullnessOfFormat
	|FROM
	|	(SELECT
	|		TDTA.StoreFormat AS StoreFormat,
	|		TDTA.Day AS Day,
	|		COUNT(DISTINCT TDTA.Products) AS QuantityOfProducts
	|	FROM
	|		TTTableOfDaysWithAssortmentProducts AS TDTA
	|	
	|	GROUP BY
	|		TDTA.StoreFormat,
	|		TDTA.Day) AS TableOfFullness
	|
	|GROUP BY
	|	TableOfFullness.StoreFormat
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuotaTable.StoreFormat AS StoreFormat,
	|	QuotaTable.ProductKind AS ProductKind,
	|	QuotaTable.ProductCategory AS ProductCategory,
	|	QuotaTable.Brand AS Brand,
	|	CAST(AVG(QuotaTable.Quota) AS NUMBER(15, 0)) AS Quota,
	|	CAST(AVG(QuotaTable.VariancePercentage) AS NUMBER(10, 0)) AS VariancePercentage
	|INTO QuotaResultsAreDetailed
	|FROM
	|	(SELECT
	|		TableOfDaysAndFormats.StoreFormat AS StoreFormat,
	|		CurQuotas.ProductKind AS ProductKind,
	|		CurQuotas.ProductCategory AS ProductCategory,
	|		CurQuotas.Brand AS Brand,
	|		TableOfDaysAndFormats.Day AS Day,
	|		ISNULL(CurQuotas.Quota, 0) AS Quota,
	|		ISNULL(CurQuotas.VariancePercentage, 0) AS VariancePercentage
	|	FROM
	|		TableOfDaysAndFormats AS TableOfDaysAndFormats
	|			LEFT JOIN TTCurQuotasWithoutStores AS CurQuotas
	|			ON TableOfDaysAndFormats.StoreFormat = CurQuotas.StoreFormat
	|				AND (BEGINOFPERIOD(TableOfDaysAndFormats.Day, MONTH) = CurQuotas.Period)) AS QuotaTable
	|
	|GROUP BY
	|	QuotaTable.StoreFormat,
	|	QuotaTable.ProductKind,
	|	QuotaTable.ProductCategory,
	|	QuotaTable.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuotaTable.ProductKind AS ProductKind,
	|	QuotaTable.ProductCategory AS ProductCategory,
	|	QuotaTable.Brand AS Brand,
	|	MAX(QuotaTable.Quota) AS Quota,
	|	CAST(AVG(QuotaTable.VariancePercentage) AS NUMBER(10, 0)) AS VariancePercentage
	|INTO QuotaTotalsWithoutFormats
	|FROM
	|	QuotaResultsAreDetailed AS QuotaTable
	|
	|GROUP BY
	|	QuotaTable.ProductKind,
	|	QuotaTable.ProductCategory,
	|	QuotaTable.Brand
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	QuotaTable.StoreFormat AS StoreFormat,
	|	SUM(QuotaTable.Quota) AS Quota,
	|	CAST(AVG(QuotaTable.VariancePercentage) AS NUMBER(10, 0)) AS VariancePercentage
	|INTO QuotaTotalsFormat
	|FROM
	|	QuotaResultsAreDetailed AS QuotaTable
	|
	|GROUP BY
	|	QuotaTable.StoreFormat
	|;
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextSummaryTables()
	
	QueryText = "
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TResult.StoreFormat AS StoreFormat,
	|	TResult.Store AS Store,
	|	TResult.ProductKind AS ProductKind,
	|	TResult.ProductCategory AS ProductCategory,
	|	TResult.Brand,
	|	SUM(TResult.CountTurnover) AS CountTurnover,
	|	SUM(TResult.RevenueAmountExclVATLocalTurnover) - SUM(TResult.CostLocalTurnover) AS RTNTurnover,
	|	SUM(TResult.RevenueAmountExclVATLocalTurnover) AS RevenueAmountExclVATLocalTurnover,
	|	SUM(TResult.Representation_) AS Representation_,
	|	SUM(TResult.Fullness_) AS Fullness_,
	|	SUM(TResult.Quota) AS Quota,
	|	AVG(TResult.VariancePercentage) AS VariancePercentage,
	|	MAX(ResultsOfRepresentationFormat.QuantityOfProducts) AS RepresentationFormat,
	|	MAX(ResultsOfFullnessOfFormat.QuantityOfProducts) AS FullnessFormat,
	|	MAX(QuotaTotalsFormat.Quota) AS QuotaFormat,
	|	MAX(QuotaTotalsFormat.VariancePercentage) AS PercentageOfDeviationFormat
	|" + ?(ThisIsTheTranscript, "INTO TTResultIntermediate", "") + "
	|FROM
	|	(SELECT
	|		RevenueTurnover_.StoreFormat AS StoreFormat,
	|		RevenueTurnover_.Store AS Store,
	|		RevenueTurnover_.ProductKind AS ProductKind,
	|		RevenueTurnover_.ProductCategory AS ProductCategory,
	|		RevenueTurnover_.Brand AS Brand,
	|		RevenueTurnover_.CountTurnover AS CountTurnover,
	|		RevenueTurnover_.CostLocalTurnover AS CostLocalTurnover,
	|		RevenueTurnover_.RevenueAmountExclVATLocalTurnover AS RevenueAmountExclVATLocalTurnover,
	|		0 AS Representation_,
	|		0 AS Fullness_,
	|		0 AS Quota,
	|		0 AS VariancePercentage
	|	FROM
	|		RevenueTurnover_ AS RevenueTurnover_
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Fullness_.StoreFormat,
	|		HistoryOfFormats.Warehouse,
	|		Fullness_.ProductKind,
	|		Fullness_.ProductCategory,
	|		Fullness_.Brand,
	|		0,
	|		0,
	|		0,
	|		0,
	|		Fullness_.QuantityOfProducts,
	|		0,
	|		0
	|	FROM
	|		ResultsOfFullnessDetailed AS Fullness_
	|			LEFT JOIN HistoryOfFormats AS HistoryOfFormats
	|			ON Fullness_.StoreFormat = HistoryOfFormats.StoreFormat
	|				AND &ConditionStores
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Representation_.StoreFormat,
	|		Representation_.Store,
	|		Representation_.ProductKind,
	|		Representation_.ProductCategory,
	|		Representation_.Brand,
	|		0,
	|		0,
	|		0,
	|		Representation_.QuantityOfProducts,
	|		0,
	|		0,
	|		0
	|	FROM
	|		ResultsOfRepresentationDetailed AS Representation_
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Quotas.StoreFormat,
	|		HistoryOfFormats.Warehouse,
	|		Quotas.ProductKind,
	|		Quotas.ProductCategory,
	|		Quotas.Brand,
	|		0,
	|		0,
	|		0,
	|		0,
	|		0,
	|		Quotas.Quota,
	|		Quotas.VariancePercentage
	|	FROM
	|		QuotaResultsAreDetailed AS Quotas
	|			LEFT JOIN HistoryOfFormats AS HistoryOfFormats
	|			ON Quotas.StoreFormat = HistoryOfFormats.StoreFormat
	|				AND &ConditionStores
	|				) AS TResult
	|		LEFT JOIN ResultsOfRepresentationFormat AS ResultsOfRepresentationFormat
	|		ON TResult.StoreFormat = ResultsOfRepresentationFormat.StoreFormat
	|		LEFT JOIN ResultsOfFullnessOfFormat AS ResultsOfFullnessOfFormat
	|		ON TResult.StoreFormat = ResultsOfFullnessOfFormat.StoreFormat
	|		LEFT JOIN QuotaTotalsFormat AS QuotaTotalsFormat
	|		ON TResult.StoreFormat = QuotaTotalsFormat.StoreFormat
	|
	|GROUP BY
	|	TResult.StoreFormat,
	|	TResult.Store,
	|	TResult.ProductKind,
	|	TResult.ProductCategory,
	|	TResult.Brand
	|";
	If ThisIsTheTranscript Then
		QueryText = QueryText + "
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TDA.StoreFormat,
		|	TDA.ProductKind,
		|	TDA.ProductCategory,
		|	TDA.Brand,
		|	TDA.Products
		|INTO TTTableWithAssortmentProducts
		|FROM
		|	TTTableOfDaysWithAssortmentProducts AS TDA
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Warehouses.StoreFormat AS StoreFormat,
		|	Warehouses.Warehouse AS Warehouse
		|INTO WarehouseTable
		|FROM
		|	TableOfDaysAndWarehouses AS Warehouses
		|;
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TResult.StoreFormat AS StoreFormat,
		|	TResult.Store AS Store,
		|	TResult.ProductKind AS ProductKind,
		|	TResult.ProductCategory AS ProductCategory,
		|	TResult.Brand AS Brand,
		|	TResult.Products AS Products,
		|	SUM(TResult.RepresentationProducts) AS RepresentationProducts,
		|	SUM(TResult.FullnessOfProducts) AS FullnessOfProducts,
		|	SUM(TResult.CountTurnover) AS CountTurnover,
		|	SUM(TResult.RTNTurnover) AS RTNTurnover,
		|	SUM(TResult.RevenueAmountExclVATLocalTurnover) AS RevenueAmountExclVATLocalTurnover,
		|	SUM(TResult.Representation_) AS Representation_,
		|	SUM(TResult.Fullness_) AS Fullness_,
		|	SUM(TResult.Quota) AS Quota,
		|	AVG(TResult.VariancePercentage) AS VariancePercentage,
		|	MAX(TResult.RepresentationFormat) AS RepresentationFormat,
		|	MAX(TResult.FullnessFormat) AS FullnessFormat,
		|	MAX(TResult.QuotaFormat) AS QuotaFormat,
		|	MAX(TResult.PercentageOfDeviationFormat) AS PercentageOfDeviationFormat
		|FROM
		|	(SELECT
		|		RP.StoreFormat AS StoreFormat,
		|		RP.Store AS Store,
		|		RP.ProductKind AS ProductKind,
		|		RP.ProductCategory AS ProductCategory,
		|		RP.Brand AS Brand,
		|		NULL AS Products,
		|		0 AS RepresentationProducts,
		|		0 AS FullnessOfProducts,
		|		0 AS CountTurnover,
		|		0 AS RTNTurnover,
		|		0 AS RevenueAmountExclVATLocalTurnover,
		|		RP.Representation_ AS Representation_,
		|		RP.Fullness_ AS Fullness_,
		|		RP.Quota AS Quota,
		|		RP.VariancePercentage AS VariancePercentage,
		|		RP.RepresentationFormat AS RepresentationFormat,
		|		RP.FullnessFormat AS FullnessFormat,
		|		RP.QuotaFormat AS QuotaFormat,
		|		RP.PercentageOfDeviationFormat AS PercentageOfDeviationFormat
		|	FROM
		|		TTResultIntermediate AS RP
		|	
		|	UNION ALL
		|	SELECT
		|		Vo.StoreFormat,
		|		Vo.Store,
		|		Vo.ProductKind,
		|		Vo.ProductCategory,
		|		Vo.Brand,
		|		Vo.Products,
		|		0 AS RepresentationProducts,
		|		0 AS FullnessOfProducts,
		|		Vo.CountTurnover,
		|		Vo.RevenueAmountExclVATLocalTurnover - Vo.CostLocalTurnover,
		|		Vo.RevenueAmountExclVATLocalTurnover,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM RevenueTurnoverProducts AS Vo
		|UNION ALL
		|SELECT
		|	Mo.StoreFormat,
		|	Mo.Store,
		|	Mo.ProductKind,
		|	Mo.ProductCategory,
		|	Mo.Brand,
		|	Mo.Products,
		|	1,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0
		|FROM TTRepresentationProductRange AS Mo
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		TTA.StoreFormat,
		|		Vehicle_.Warehouse,
		|		TTA.ProductKind,
		|		TTA.ProductCategory,
		|		TTA.Brand,
		|		TTA.Products,
		|		0,
		|		1,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0
		|	FROM
		|		TTTableWithAssortmentProducts AS TTA
		|			INNER JOIN WarehouseTable AS Vehicle_
		|			ON (Vehicle_.StoreFormat = TTA.StoreFormat)
		|			
		|			) AS TResult
		|GROUP BY
		|	TResult.StoreFormat,
		|	TResult.Store,
		|	TResult.ProductKind,
		|	TResult.ProductCategory,
		|	TResult.Brand,
		|	TResult.Products
		|";
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure AddConditionsAndParameters(Query, QueryText, FilterItems1)
	
	ParameterCounter = 0;
	ConditionCounter = 0;
	
	UseCollectionManagement = GetFunctionalOption("UseCollectionManagement");
	
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
	
	If ThisIsTheTranscript Then
		ConditionCounter = 0;
		MatchingConditionFields = New Map;
		MatchingConditionFields.Insert("StoreFormat", "PlanningObject");
		MatchingConditionFields.Insert("ProductKind", "ProductCategory.Owner");
		MatchingConditionFields.Insert("ProductCategory", "ProductCategory");
		MatchingConditionFields.Insert("Brand", "Brand");
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
		QueryText=StrReplace(QueryText,"&QuotaCutCondition", TrimAll(ConditionText));
	EndIf;
	
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("Store", "HistoryOfFormats.Warehouse");
	MatchingConditionFields.Insert("Store.", "HistoryOfFormats.Warehouse.");
	MatchingConditionFields.Insert("StoreFormat", "HistoryOfFormats.StoreFormat");
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
	QueryText=StrReplace(QueryText,"&ConditionStores", TrimAll(ConditionText));
	
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("ProductKind", "CatalogProducts.ProductKind");
	MatchingConditionFields.Insert("ProductCategory", "CatalogProducts.ProductCategory");
	MatchingConditionFields.Insert("Brand", "CatalogProducts.Brand");
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
	QueryText=StrReplace(QueryText,"&ProductRangeCondition", TrimAll(ConditionText));
	
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("StoreFormat", "ProductRange.PlanningObject");
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
	
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("Store", "Warehouse");
	MatchingConditionFields.Insert("ProductKind", "Products.ProductKind");
	MatchingConditionFields.Insert("ProductCategory", "Products.ProductCategory");
	MatchingConditionFields.Insert("Brand", "Products.Brand");
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
	QueryText=StrReplace(QueryText,"&ConditionBalancesAndRevolutions", TrimAll(ConditionText));
	
	ConditionCounter = 0;
	MatchingConditionFields = New Map;
	MatchingConditionFields.Insert("Store", "ItemsLocationAttributes.StorageLocation");
	MatchingConditionFields.Insert("ProductKind", "ItemsLocationAttributes.Products.ProductKind");
	MatchingConditionFields.Insert("ProductCategory", "ItemsLocationAttributes.Products.ProductCategory");
	MatchingConditionFields.Insert("Brand", "ItemsLocationAttributes.Products.Brand");
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
	QueryText=StrReplace(QueryText,"&RevenueCondition", TrimAll(ConditionText));
	
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
			ParameterName = StrReplace(DataPath, ".", "") + Format(ParameterCounter, "NZ=0; NG=0");
			ParameterName = StrReplace(ParameterName, "_", "");
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
	
	If ConditionText = "" Then
		ConditionText = "TRUE";
	EndIf;

EndProcedure

Procedure OutputHeader(TabularDocumentResult, Template)
	DimensionHeaderArea = Template.GetArea("Header|Groups");
	
	If ThisIsTheTranscript Then
		DimensionHeaderArea.Parameters.DimensionsHeader = NStr("vi = 'Thể loại hàng hóa / Nhãn hiệu / Mặt hàng';
																|ru = 'Товарная категория / Марка / Номенклатура';
																|en = 'Product category/Brand/Items'; fa = 'Product category/Brand/Items';
																|it = 'Categoria dell''articolo / Marchio / Articoli';
																|pl = 'Kategoria towarowa / Marka / Nomenklatura';
																|tr = 'Ürün kategorisi / Marka / Öğe'");
	Else
		DimensionHeaderArea.Parameters.DimensionsHeader = NStr("vi = 'Dạng mặt hàng / Thể loại hàng hóa';
																|ru = 'Вид номенклатуры / Товарная категория';
																|en = 'Item kind / Product category'; fa = 'Item kind / Product category';
																|it = 'Tipo di articoli / Categoria dell''articolo';
																|pl = 'Rodzaj pozycji / Kategoria towarowa';
																|tr = 'Ürün türü / Ürün kategorisi'");
	EndIf;
	
	TabularDocumentResult.Put(DimensionHeaderArea, 1);
	
	If ThisIsTheTranscript Then
		If DrillDownColumnNumber < 5 Then
			IndicatorHeaderArea = Template.GetArea("Header|SalesFigure");
		Else
			IndicatorHeaderArea = Template.GetArea("Header|AssortmentIndicator");
		EndIf;
		
		ColumnsArray1 = New Array;
		If DrillDownColumnNumber = 2 Then
			ColumnsArray1.Add(NStr("vi = 'Số lượng kỳ phân tích';
									|ru = 'Количество периода анализа';
									|en = 'Analysis period quantity'; fa = 'Analysis period quantity';
									|it = 'Quantità periodo di analisi';
									|pl = 'Liczba okresu analizy';
									|tr = 'Analiz dönemi sayısı'"));
			ColumnsArray1.Add(NStr("vi = 'Số lượng kỳ so sánh';
									|ru = 'Количество периода сравнения';
									|en = 'Quantity comparison period'; fa = 'Quantity comparison period';
									|it = 'Quantità periodo di confronto';
									|pl = 'Liczba okresu porównania';
									|tr = 'Karşılaştırma dönemi sayısı'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi số lượng tuyệt đối';
									|ru = 'Изменение количества абсолютное';
									|en = 'Absolute change of quantity'; fa = 'Absolute change of quantity';
									|it = 'Variazione della quantità assoluta';
									|pl = 'Zmiana ilości absolutna';
									|tr = 'Mutlak miktar değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi số lượng %';
									|ru = 'Изменение количества %';
									|en = 'Quantity change, %'; fa = 'تغییر مقدار، درصد';
									|it = 'Variazione della quantità %';
									|pl = 'Zmiana ilości %';
									|tr = 'Miktar değişikliği %'"));
		ElsIf DrillDownColumnNumber = 3 Then
			ColumnsArray1.Add(NStr("vi = 'Doanh thu kỳ phân tích';
									|ru = 'Выручка периода анализа';
									|en = 'Revenue of analysis period'; fa = 'Revenue of analysis period';
									|it = 'Ricavo del periodo di analisi';
									|pl = 'Utarg okresu analizy';
									|tr = 'Analiz dönemi geliri'"));
			ColumnsArray1.Add(NStr("vi = 'Doanh thu kỳ so sánh';
									|ru = 'Выручка периода сравнения';
									|en = 'Revenue of comparison period'; fa = 'Revenue of comparison period';
									|it = 'Ricavo del periodo di confronto';
									|pl = 'Utarg okresu porównania';
									|tr = 'Karşılaştırma dönemi geliri'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi doanh thu tuyệt đối';
									|ru = 'Изменение выручки абсолютное';
									|en = 'Absolute revenue change'; fa = 'Absolute revenue change';
									|it = 'Variazione del ricavo assoluta';
									|pl = 'Zmiana utargu absolutna';
									|tr = 'Mutlak gelir değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi doanh thu %';
									|ru = 'Изменение выручки %';
									|en = 'Revenue change, %'; fa = 'تغییر درآمد، درصد';
									|it = 'Variazione del ricavo, %';
									|pl = 'Zmiana utargu %';
									|tr = 'Gelir değişikliği %'"));
		ElsIf DrillDownColumnNumber = 4 Then
			ColumnsArray1.Add(NStr("vi = 'Lãi gộp trong kỳ phân tích';
									|ru = 'Валовая прибыль периода анализа';
									|en = 'Gross profit of analysis period'; fa = 'Gross profit of analysis period';
									|it = 'Profitto lordo del periodo di analisi';
									|pl = 'Zysk brutto okresu analizy';
									|tr = 'Analiz döneminin brüt kârı'"));
			ColumnsArray1.Add(NStr("vi = 'Lãi gộp trong kỳ so sánh';
									|ru = 'Валовая прибыль периода сравнения';
									|en = 'Gross profit of the comparison period'; fa = 'Gross profit of the comparison period';
									|it = 'Profitto lordo del periodo di confronto';
									|pl = 'Zysk brutto okresu porównawczego';
									|tr = 'Karşılaştırma döneminin brüt kârı'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi lãi gộp tuyệt đối';
									|ru = 'Изменение валовой прибыли абсолютное';
									|en = 'Absolute gross profit change'; fa = 'Absolute gross profit change';
									|it = 'Variazione del profitto lordo assoluta';
									|pl = 'Zmiana zysku brutto absolutna';
									|tr = 'Mutlak brüt kâr değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi lãi gộp %';
									|ru = 'Изменение валовой прибыли %';
									|en = 'Gross profit change, %'; fa = 'Gross profit change, %';
									|it = 'Variazione del profitto lordo %';
									|pl = 'Zmiana zysku brutto %';
									|tr = 'Brüt kâr değişikliği %'"));
		ElsIf DrillDownColumnNumber = 5 Then
			ColumnsArray1.Add(NStr("vi = 'Hạn mức kỳ phân tích';
									|ru = 'Квота периода анализа';
									|en = 'Analysis period quota'; fa = 'Analysis period quota';
									|it = 'Quota del periodo di analisi';
									|pl = 'Kwota okresu analizy';
									|tr = 'Analiz dönemi kotası'"));
			ColumnsArray1.Add(NStr("vi = 'Hạn mức kỳ so sánh';
									|ru = 'Квота периода сравнения';
									|en = 'Comparison period quota'; fa = 'Comparison period quota';
									|it = 'Quota del periodo di confronto';
									|pl = 'Kwota okresu porównania';
									|tr = 'Karşılaştırma dönemi kotası'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi hạn mức tuyệt đối';
									|ru = 'Изменение квоты абсолютное';
									|en = 'Absolute quota change'; fa = 'Absolute quota change';
									|it = 'Variazione della quota assoluta';
									|pl = 'Zmiana kwoty absolutna';
									|tr = 'Mutlak kota değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi hạn mức %';
									|ru = 'Изменение квоты %';
									|en = 'Quota change, %'; fa = 'Quota change, %';
									|it = 'Variazione della quota %';
									|pl = 'Zmiana kwoty %';
									|tr = 'Kota değişikliği %'"));
		ElsIf DrillDownColumnNumber = 6 Then
			ColumnsArray1.Add(NStr("vi = 'Tổng số bổ sung trong kỳ phân tích';
									|ru = 'Общая наполнен- ность периода анализа';
									|en = 'Total completeness of the analysis period'; fa = 'Total completeness of the analysis period';
									|it = 'Contenuto totale del periodo di analisi';
									|pl = 'Całkowite napełnienie okresu analizy';
									|tr = 'Analiz döneminin genel doluluğu'"));
			ColumnsArray1.Add(NStr("vi = 'Bổ sung trung bình trong kỳ phân tích';
									|ru = 'Средняя наполнен- ность периода анализа';
									|en = 'Average completeness of the analysis period'; fa = 'Average completeness of the analysis period';
									|it = 'Contenuto medio del periodo di analisi';
									|pl = 'Średnie napełnienie okresu analizy';
									|tr = 'Analiz döneminin ortalama doluluğu'"));
			ColumnsArray1.Add(NStr("vi = 'Tổng số bổ sung trong kỳ so sánh';
									|ru = 'Общая наполнен- ность периода сравнения';
									|en = 'Total completeness of the comparison period'; fa = 'Total completeness of the comparison period';
									|it = 'Contenuto totale del periodo di confronto';
									|pl = 'Całkowite napełnienie okresu porównawczego';
									|tr = 'Karşılaştırma döneminin genel doluluğu'"));
			ColumnsArray1.Add(NStr("vi = 'Bổ sung trung bình trong kỳ so sánh';
									|ru = 'Средняя наполнен- ность периода сравнения';
									|en = 'Average completeness of the comparison period'; fa = 'Average completeness of the comparison period';
									|it = 'Contenuto medio del periodo di confronto';
									|pl = 'Średnie napełnienie okresu porównawczego';
									|tr = 'Karşılaştırma döneminin ortalama doluluğu'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi bổ sung trung bình tuyệt đối';
									|ru = 'Изменение средней наполнен- ности абсолютное';
									|en = 'Absolute change of the average completeness'; fa = 'Absolute change of the average completeness';
									|it = 'Variazione del contenuto medio assoluta';
									|pl = 'Zmiana średniego napełnienia absolutna';
									|tr = 'Mutlak ortalama doluluk değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi bổ sung trung bình %';
									|ru = 'Изменение средней наполнен- ности %';
									|en = 'Change average completeness %'; fa = 'Change average completeness %';
									|it = 'Variazione del contenuto medio assoluta %';
									|pl = 'Zmiana średniego napełnienia %';
									|tr = 'Ortalama doluluk değişikliği %'"));
		ElsIf DrillDownColumnNumber = 7 Then
			ColumnsArray1.Add(NStr("vi = 'Trình bày tổng thể trong kỳ phân tích';
									|ru = 'Общая представлен- ность периода анализа';
									|en = 'Total representation of the analysis period'; fa = 'Total representation of the analysis period';
									|it = 'Rappresentazione generale del periodo di analisi';
									|pl = 'Całkowita reprezentacja okresu analizy';
									|tr = 'Analiz döneminin genel sunumu'"));
			ColumnsArray1.Add(NStr("vi = 'Trình bày trung bình trong kỳ phân tích';
									|ru = 'Средняя представлен- ность периода анализа';
									|en = 'Average representation of the analysis period'; fa = 'Average representation of the analysis period';
									|it = 'Rappresentazione media del periodo di analisi';
									|pl = 'Średnia reprezentacja okresu analizy';
									|tr = 'Analiz döneminin ortalama sunumu'"));
			ColumnsArray1.Add(NStr("vi = 'Trình bày tổng thể trong kỳ so sánh';
									|ru = 'Общая представлен- ность периода сравнения';
									|en = 'Total representation of the comparison period'; fa = 'Total representation of the comparison period';
									|it = 'Rappresentazione generale del periodo di confronto';
									|pl = 'Całkowita reprezentacja okresu porównawczego';
									|tr = 'Karşılaştırma döneminin genel sunumu'"));
			ColumnsArray1.Add(NStr("vi = 'Trình bày trung bình trong kỳ so sánh';
									|ru = 'Средняя представлен- ность периода сравнения';
									|en = 'Average representation of the comparison period'; fa = 'Average representation of the comparison period';
									|it = 'Rappresentazione media del periodo di confronto';
									|pl = 'Średnia reprezentacja okresu porównawczego';
									|tr = 'Karşılaştırma döneminin ortalama sunumu'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi trình bày trung bình tuyệt đối';
									|ru = 'Изменение средней представлен- ности абсолютное';
									|en = 'Absolute change of the average representation'; fa = 'Absolute change of the average representation';
									|it = 'Variazione della rappresentazione media assoluta';
									|pl = 'Zmiana średniej reprezentacji absolutna';
									|tr = 'Mutlak ortalama sunum değişikliği'"));
			ColumnsArray1.Add(NStr("vi = 'Thay đổi trình bày trung bình %';
									|ru = 'Изменение средней представлен- ности %';
									|en = 'Change average representation %'; fa = 'Change average representation %';
									|it = 'Variazione della rappresentazione media assoluta %';
									|pl = 'Zmiana średniej reprezentacji %';
									|tr = 'Mutlak sunum değişikliği %'"));
		EndIf;
		For Each ArrayColumn In ColumnsArray1 Do
			IndicatorHeaderArea.Parameters.IndicatorTitle = ArrayColumn;
			TabularDocumentResult.Join(IndicatorHeaderArea, 1, , True);
		EndDo;
	Else
		AreaHeaderSalesIndicator = Template.GetArea("Header|SalesFigure");
		AreaHeaderProductRangeIndicator = Template.GetArea("Header|AssortmentIndicator");
		
		AreaHeaderSalesIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi số lượng %';
																	|ru = 'Изменение количества %';
																	|en = 'Quantity change, %'; fa = 'تغییر مقدار، درصد';
																	|it = 'Variazione della quantità %';
																	|pl = 'Zmiana ilości %';
																	|tr = 'Miktar değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderSalesIndicator, 1, , True);
		
		AreaHeaderSalesIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi doanh thu %';
																	|ru = 'Изменение выручки %';
																	|en = 'Revenue change, %'; fa = 'تغییر درآمد، درصد';
																	|it = 'Variazione del ricavo, %';
																	|pl = 'Zmiana utargu %';
																	|tr = 'Gelir değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderSalesIndicator, 1, , True);
		
		AreaHeaderSalesIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi lãi gộp %';
																	|ru = 'Изменение валовой прибыли %';
																	|en = 'Gross profit change, %'; fa = 'Gross profit change, %';
																	|it = 'Variazione del profitto lordo %';
																	|pl = 'Zmiana zysku brutto %';
																	|tr = 'Brüt kâr değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderSalesIndicator, 1, , True);
		
		AreaHeaderProductRangeIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi hạn mức %';
																		|ru = 'Изменение квоты %';
																		|en = 'Quota change, %'; fa = 'Quota change, %';
																		|it = 'Variazione della quota %';
																		|pl = 'Zmiana kwoty %';
																		|tr = 'Kota değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderProductRangeIndicator, 1, , True);
		
		AreaHeaderProductRangeIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi bổ sung %';
																		|ru = 'Изменение наполнен- ности %';
																		|en = 'Completeness change, %'; fa = 'Completeness change, %';
																		|it = 'Variazione del contenuto %';
																		|pl = 'Zmiana napełnienia %';
																		|tr = 'Doluluk değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderProductRangeIndicator, 1, , True);
		
		AreaHeaderProductRangeIndicator.Parameters.IndicatorTitle = NStr("vi = 'Thay đổi trình bày %';
																		|ru = 'Изменение представлен- ности %';
																		|en = 'Representation change, %'; fa = 'Representation change, %';
																		|it = 'Variazione della rappresentazione %';
																		|pl = 'Zmiana reprezentacji %';
																		|tr = 'Sunum değişikliği %'");
		TabularDocumentResult.Join(AreaHeaderProductRangeIndicator, 1, , True);
	EndIf;
	
EndProcedure

Procedure DisplayDimensions(Selection, TabularDocumentResult, Template, AreaLevel_, FieldArray, DetailsStructure2)
	
	LevelName = FieldArray[AreaLevel_];
	NextLevel = AreaLevel_+1;
	
	If AreaLevel_ = FieldArray.Count() - 1 Then
		TRegionIndex = "6";
	Else
		TRegionIndex = Format(AreaLevel_ + 1,"NZ=0; NG=0");
	EndIf;
	If AreaLevel_ = 1 Then
		GroupingArea_ = Template.GetArea("AreaLevel0|Groups");
		AreaSalesIndicator = Template.GetArea("AreaLevel0|SalesFigure");
		ScopeOfProductRange = Template.GetArea("AreaLevel0|AssortmentIndicator");
		StoreFormatArea = Template.GetArea("StoreFormatArea");
	Else
		GroupingArea_ = Template.GetArea("AreaLevel"+TRegionIndex+"|Groups");
		AreaSalesIndicator = Template.GetArea("AreaLevel"+TRegionIndex+"|SalesFigure");
		ScopeOfProductRange = Template.GetArea("AreaLevel"+TRegionIndex+"|AssortmentIndicator");
		StoreFormatArea = Template.GetArea("StoreFormatArea");
	EndIf;
	
	ArrayOfAreas = New Array;
	ArrayOfAreas.Add(GroupingArea_);
	ArrayOfAreas.Add(AreaSalesIndicator);
	ArrayOfAreas.Add(ScopeOfProductRange);

	While Selection.Next() Do
		If AreaLevel_ = 0 Then
			SamplingNextLevel = Selection.Select(QueryResultIteration.ByGroups);
			DisplayDimensions(SamplingNextLevel, TabularDocumentResult, Template, NextLevel, FieldArray, DetailsStructure2);
		ElsIf AreaLevel_ = 1 Then
			If Not ThisIsTheTranscript Then
				DetailsStructure2.StoreFormat = Selection.StoreFormat;
				DetailsStructure2.Store = Selection.Store;
			EndIf;
			
			StoreFormatArea.Parameters.Fill(Selection);
			TabularDocumentResult.Put(StoreFormatArea, 0);
			OutputHeader(TabularDocumentResult, Template);
			
			SamplingNextLevel = Selection.Select(QueryResultIteration.ByGroups);
			DisplayDimensions(SamplingNextLevel, TabularDocumentResult, Template, NextLevel, FieldArray, DetailsStructure2);
			FillInParametersAndDisplayArea(Selection, "", TabularDocumentResult, ArrayOfAreas, 1, DetailsStructure2);
		Else
			If Not ThisIsTheTranscript Then
				DetailsStructure2.GroupName = LevelName;
				DetailsStructure2[LevelName] = Selection[LevelName];
			EndIf;
			If LevelName = "Products" Then
				If DrillDownColumnNumber <> 5 And
					Selection.Products <> NULL Then
					FillInParametersAndDisplayArea(Selection, LevelName, TabularDocumentResult, ArrayOfAreas, -1, DetailsStructure2);
				EndIf;
			Else
				FillInParametersAndDisplayArea(Selection, LevelName, TabularDocumentResult, ArrayOfAreas, -1, DetailsStructure2);
			EndIf;
			
			SamplingNextLevel = Selection.Select(QueryResultIteration.ByGroups);
			If SamplingNextLevel.Count() > 0 Then
				DisplayDimensions(SamplingNextLevel, TabularDocumentResult, Template, NextLevel, FieldArray, DetailsStructure2);
			EndIf;
		EndIf;
	EndDo;	
EndProcedure

Procedure FillInParametersAndDisplayArea(Selection,
	GroupName,
	TabularDocumentResult,
	ArrayOfAreas,
	ExternalGroupingLevel,
	DetailsStructure2)
	
	GroupingArea_ = ArrayOfAreas[0]; // SpreadsheetDocument - 
	AreaSalesIndicator = ArrayOfAreas[1]; // SpreadsheetDocument - 
	ScopeOfProductRange = ArrayOfAreas[2]; // SpreadsheetDocument -
	
	If ExternalGroupingLevel = -1 Then
		GroupingLevel = Selection.Level() + 1;
	Else
		GroupingLevel = ExternalGroupingLevel;
	EndIf;
	If Not IsBlankString(GroupName) Then
		GroupingArea_.Parameters.DimensionValue_1=Selection[GroupName];
		GroupingArea_.Parameters.PerformanceGroup=Selection[GroupName];
	EndIf;
	
	If ThisIsTheTranscript Or GroupingLevel = 1 Then
		StructureOfDecryptionValue = Undefined;
	Else
		StructureOfDecryptionValue = New Structure;
		For Each ElementStukr1 In DetailsStructure2 Do
			StructureOfDecryptionValue.Insert(ElementStukr1.Key, ElementStukr1.Value);
		EndDo;
	EndIf;
	
	TabularDocumentResult.Put(GroupingArea_,GroupingLevel);
	
	ChangeAbsoluteRTN = Selection.RTNTurnover - Selection.RTNTurnoverOfComparisonPeriod;
	ChangeInAbsoluteRevenue = Selection.RevenueTurnover - Selection.RevenueTurnoverOfComparisonPeriod;
	ChangeAbsoluteQuantity = Selection.CountTurnover - Selection.NumberOfDaysOfComparisonPeriod;
	Representation_ = Selection.Representation_;
	RepresentationOfComparisonPeriod = Selection.RepresentationOfComparisonPeriod;
	Quota = Selection.Quota;
	ComparisonPeriodQuota = Selection.ComparisonPeriodQuota;
	Fullness_ = Selection.Fullness_;
	FullnessOfComparisonPeriod = Selection.FullnessOfComparisonPeriod;
	AllowableVariance = Selection.VariancePercentage;
	
	ChangeAbsoluteRepresentation = Representation_ - RepresentationOfComparisonPeriod;
	ChangeAbsoluteQuota = Quota - ComparisonPeriodQuota;
	ChangeAbsoluteFullness = Selection.Fullness_ - Selection.FullnessOfComparisonPeriod;
	
	If ThisIsTheTranscript Then
		
		If DrillDownColumnNumber < 5 Then
			ScopeOfApplication_4 = AreaSalesIndicator;
		Else
			ScopeOfApplication_4 = ScopeOfProductRange;
		EndIf;
		
		ColumnsArray1 = New Array;
		If DrillDownColumnNumber = 2 Then
			ColumnsArray1.Add(Selection.CountTurnover);
			ColumnsArray1.Add(Selection.NumberOfDaysOfComparisonPeriod);
			ColumnsArray1.Add(ChangeAbsoluteQuantity);
			ColumnsArray1.Add(?(Selection.NumberOfDaysOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteQuantity * 100 / Selection.NumberOfDaysOfComparisonPeriod, 2)));
		ElsIf DrillDownColumnNumber = 3 Then
			ColumnsArray1.Add(Selection.RevenueTurnover);
			ColumnsArray1.Add(Selection.RevenueTurnoverOfComparisonPeriod);
			ColumnsArray1.Add(ChangeInAbsoluteRevenue);
			ColumnsArray1.Add(?(Selection.RevenueTurnoverOfComparisonPeriod = 0, 0, Round(ChangeInAbsoluteRevenue * 100 / Selection.RevenueTurnoverOfComparisonPeriod, 2)));
		ElsIf DrillDownColumnNumber = 4 Then
			ColumnsArray1.Add(Selection.RTNTurnover);
			ColumnsArray1.Add(Selection.RTNTurnoverOfComparisonPeriod);
			ColumnsArray1.Add(ChangeAbsoluteRTN);
			ColumnsArray1.Add(?(Selection.RTNTurnoverOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteRTN * 100 / Selection.RTNTurnoverOfComparisonPeriod, 2)));
		ElsIf DrillDownColumnNumber = 5 Then
			ColumnsArray1.Add(Selection.Quota);
			ColumnsArray1.Add(Selection.ComparisonPeriodQuota);
			ColumnsArray1.Add(ChangeAbsoluteQuota);
			ColumnsArray1.Add(?(Selection.ComparisonPeriodQuota = 0, 0, Round(ChangeAbsoluteQuota * 100 / Selection.ComparisonPeriodQuota, 2)));
		ElsIf DrillDownColumnNumber = 6 Then
			ColumnsArray1.Add(Selection.FullnessOfProducts);
			ColumnsArray1.Add(Selection.Fullness_);
			ColumnsArray1.Add(Selection.FullnessProductRangeOfComparisonPeriod);
			ColumnsArray1.Add(Selection.FullnessOfComparisonPeriod);
			ColumnsArray1.Add(ChangeAbsoluteFullness);
			ColumnsArray1.Add(?(Selection.FullnessOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteFullness * 100 / Selection.FullnessOfComparisonPeriod, 2)));
		ElsIf DrillDownColumnNumber = 7 Then
			ColumnsArray1.Add(Selection.RepresentationProducts);
			ColumnsArray1.Add(Selection.Representation_);
			ColumnsArray1.Add(Selection.RepresentationProductsOfComparisonPeriod);
			ColumnsArray1.Add(Selection.RepresentationOfComparisonPeriod);
			ColumnsArray1.Add(ChangeAbsoluteRepresentation);
			ColumnsArray1.Add(?(Selection.RepresentationOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteRepresentation * 100 / Selection.RepresentationOfComparisonPeriod, 2)));
		EndIf;
		For Each ArrayColumn In ColumnsArray1 Do
			ScopeOfApplication_4.Parameters.IndicatorValue_ = ArrayColumn;
			ScopeOfApplication_4.Parameters.StructureOfDecryptionValue = Undefined;
			CurrentArea = TabularDocumentResult.Join(ScopeOfApplication_4, 1, , True);
			CurrentArea.Details = Undefined;
		EndDo;
	Else
		
		//Count
		AreaSalesIndicator.Parameters.IndicatorValue_ = ?(Selection.NumberOfDaysOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteQuantity * 100 / Selection.NumberOfDaysOfComparisonPeriod, 2));
		AreaSalesIndicator.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(AreaSalesIndicator, 1, , True);
		
		//Revenue
		AreaSalesIndicator.Parameters.IndicatorValue_ = ?(Selection.RevenueTurnoverOfComparisonPeriod = 0, 0, Round(ChangeInAbsoluteRevenue * 100 / Selection.RevenueTurnoverOfComparisonPeriod, 2));
		AreaSalesIndicator.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(AreaSalesIndicator, 1, , True);
		
		//RTN;
		AreaSalesIndicator.Parameters.IndicatorValue_ = ?(Selection.RTNTurnoverOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteRTN * 100 / Selection.RTNTurnoverOfComparisonPeriod, 2));
		AreaSalesIndicator.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(AreaSalesIndicator, 1, , True);
		
		//Quota
		ScopeOfProductRange.Parameters.IndicatorValue_ = ?(ComparisonPeriodQuota = 0, 0, Round(ChangeAbsoluteQuota * 100 / ComparisonPeriodQuota, 2));
		ScopeOfProductRange.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(ScopeOfProductRange, 1, , True);
		
		//ContentContent
		ScopeOfProductRange.Parameters.IndicatorValue_ = ?(Selection.FullnessOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteFullness * 100 / Selection.FullnessOfComparisonPeriod, 2));
		ScopeOfProductRange.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(ScopeOfProductRange, 1, , True);
		
		//Representation_
		ScopeOfProductRange.Parameters.IndicatorValue_ = ?(RepresentationOfComparisonPeriod = 0, 0, Round(ChangeAbsoluteRepresentation * 100 / RepresentationOfComparisonPeriod, 2));
		ScopeOfProductRange.Parameters.StructureOfDecryptionValue = StructureOfDecryptionValue;
		TabularDocumentResult.Join(ScopeOfProductRange, 1, , True);
	EndIf;
	
EndProcedure


#EndRegion

#EndIf