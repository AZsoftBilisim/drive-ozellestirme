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

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	PriceViewParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
	If PriceViewParameter <> Undefined Then
		If Not ValueIsFilled(PriceViewParameter.Value) Then
			If Not GetFunctionalOption("UseSeveralPriceTypes") Then
				DataCompositionClientServer.SetParameter(SettingsComposer, "EstimationOfStocksByTypeOfPrices", 3);
				DataCompositionClientServer.SetParameter(SettingsComposer, "PriceKind", PriceManagementSystemServerCall.PriceTypePriceList_());
			EndIf;
		EndIf;
	EndIf;
	
	ParameterEstimationOfStocksByTypeOfPrices = DataCompositionClientServer.GetParameter(SettingsComposer, "EstimationOfStocksByTypeOfPrices");
	If ParameterEstimationOfStocksByTypeOfPrices.Value = 3 Then
		PriceViewParameter = DataCompositionClientServer.GetParameter(SettingsComposer, "PriceKind");
		If Not ValueIsFilled(PriceViewParameter.Value) Then
			Raise NStr("vi = 'Chưa chỉ ra ""Dạng giá"".';
						|ru = 'Не указан ""Вид цены"".';
						|en = '""Price type"" is not specified'; fa = '""Price type"" is not specified';
						|it = 'Non è indicato ""tipo di prezzo"".';
						|pl = 'Nie określono ""Rodzaj ceny"".';
						|tr = '""Fiyat türü"" belirtilmedi.'");
		EndIf;
	EndIf;
	
	DataCompositionSchema = GetTemplate("MainDataCompositionSchema");
	
	DataSet25 = DataCompositionSchema.DataSets.Find("Query2_5");
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		DataSet = DataCompositionSchema.DataSets.Find("Query");
		DataSet.Query = DataSet25.Query;
	EndIf;
	DataCompositionSchema.DataSets.Delete(DataSet25);

	QueryText = DataCompositionSchema.DataSets[0].Query;
	
	If GetFunctionalOption("UseItemPackages") Then
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProduct.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor1, 0) = 0
		|			THEN PricesOfProduct.Price
		|		ELSE PricesOfProduct.Price / &QueryTextPackagingFactor1
		|	END";
		
		QueryText = StrReplace(QueryText, "&CurrentPrice", ReplacementText);
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProductB.Price IS NULL
		|			THEN 0
		|		WHEN PricesOfProductB.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor2, 0) = 0
		|			THEN PricesOfProductB.Price
		|		ELSE PricesOfProductB.Price / &QueryTextPackagingFactor2
		|	END";

		QueryText = StrReplace(QueryText, "&OldPrice", ReplacementText);
		
		ReplacementText = 
		"CASE
		|		WHEN PricesOfProduct.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor1, 0) = 0
		|			THEN PricesOfProduct.Price
		|		ELSE PricesOfProduct.Price / &QueryTextPackagingFactor1
		|	END - CASE
		|		WHEN PricesOfProductB.Price IS NULL
		|			THEN 0
		|		WHEN PricesOfProductB.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|				OR ISNULL(&QueryTextPackagingFactor2, 0) = 0
		|			THEN PricesOfProductB.Price
		|		ELSE PricesOfProductB.Price / &QueryTextPackagingFactor2
		|	END";

		QueryText = StrReplace(QueryText, "&Delta", ReplacementText);
		
	Else
		
		ReplacementText = 
		"PricesOfProduct.Price";
		
		QueryText = StrReplace(QueryText, "&CurrentPrice", ReplacementText);

		ReplacementText = 
		"CASE
		|		WHEN
		|			PricesOfProductB.Price IS NULL
		|		THEN
		|			0
		|		ELSE
		|			PricesOfProductB.Price
		|	END";
		
		QueryText = StrReplace(QueryText, "&OldPrice", ReplacementText);

		ReplacementText = 
		"PricesOfProduct.Price
		|		- CASE
		|			WHEN
		|				PricesOfProductB.Price IS NULL
		|			THEN
		|				0
		|			ELSE
		|				PricesOfProductB.Price
		|		END";
		QueryText = StrReplace(QueryText, "&Delta", ReplacementText);
		
	EndIf;
		
	DataCompositionSchema.DataSets[0].Query = QueryText;
		
	QueryText = DataCompositionSchema.DataSets[0].Query;
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfProduct.Package",
			"PricesOfProduct.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PricesOfProductB.Package",
			"PricesOfProductB.Products"));
					
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"TableGoodsInWarehousesMaximumPeriod.Products.UnitOfMeasure", 
			"TableGoodsInWarehousesMaximumPeriod.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem1", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"TableGoodsInWarehousesMaximumPeriod.Products.UnitOfMeasure", 
			"TableGoodsInWarehousesMaximumPeriod.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextItemWeight2", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"NearestRemnantsByProductName.Products.UnitOfMeasure", 
			"NearestRemnantsByProductName.Products"));
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextTheVolumeOfTheItem2", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"NearestRemnantsByProductName.Products.UnitOfMeasure", 
			"NearestRemnantsByProductName.Products"));
	
	DataCompositionSchema.DataSets[0].Query = QueryText;
	
	FIlterRow = "";
	SearchString = "&ValueOfSelectionByResources";
	ArrayOfSelections = New Array();
	MatchingCharacters = Undefined;

	ListOfAllowedResources = New ValueList();
	For Each TotalLine In DataCompositionSchema.TotalFields Do
		If StrFind(TotalLine.Expression, SearchString) = 0 Then
			Continue;
		EndIf;
		
		ListOfAllowedResources.Add(TotalLine.DataPath);
	EndDo;

	Groups = DataCompositionClientServer.GetGroupings(SettingsComposer);
	For Each Group In Groups Do
		If Not Group.Value.Name = "GroupingGoods" Then
			Continue;
		EndIf;
		
		Filters = Group.Value.Filter; //DataCompositionFilter
		
		FillError = False;
		ArrayOfSelections = CreateArrayOfSelections(Filters, MatchingCharacters, ListOfAllowedResources, FillError);
		
		If FillError Then
			Raise NStr("vi = 'Trong gom nhóm ""Hàng hóa"" có áp dụng bộ lọc không theo số đo. Cần lọc chi tiết đối với báo cáo, không phải trong gom nhóm.';
						|ru = 'В группировке ""Товары"" применены отборы не по ресурсам. Необходимо подобные отборы применить к отчету, а не к группировке.';
						|en = 'Filters not by resources are applied in the ""Goods"" grouping. Such filters must be applied to the report and not the grouping.'; fa = 'Filters not by resources are applied in the ""Goods"" grouping. Such filters must be applied to the report and not the grouping.';
						|it = 'Nel raggruppamento ""Merci"", le selezioni non sono state applicate alle risorse. Queste selezioni devono essere applicate al report e non al raggruppamento.';
						|pl = 'W grupowaniu ""Towary"" są stosowane filtry nie według zasobów. Należy podobne filtry stosować do raportu, a nie do grupowania.';
						|tr = '""Ürünler"" gruplandırmasında filtreler kaynaklara göre uygulanmamış. Bu tür filtreleri gruplamaya değil rapora uygulamak gerekir.'");
		EndIf;
		
		Break;
		
	EndDo;

	FIlterRow = CreateSelectionLine(ArrayOfSelections);
	
	SubstituteSelection = Not IsBlankString(FIlterRow);
	
	If SubstituteSelection Then
		FIlterRow = """" + FIlterRow + """";
	EndIf;
	
	For Each TotalLine In DataCompositionSchema.TotalFields Do
		If StrFind(TotalLine.Expression, SearchString) = 0 Then
			Continue;
		EndIf;
		
		TotalLine.Expression = StrReplace(TotalLine.Expression, SearchString, FIlterRow);
	EndDo;
		
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		SettingsComposer.GetSettings(),
		DetailsData);

	DataCompositionServer.SetLayoutTemplateHeaders(ParameterizableFieldHeaders(), CompositionTemplate);
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor, True);

	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
EndProcedure


#EndRegion

#Region Private

#Region ConversionOfSelections

// Create an array of selections.
// 
// Parameters:
//  Filters - DataCompositionFilter - Filters
//  MatchingCharacters - Undefined, Map of DataCompositionComparisonType - - Matching Characters
//  ListOfAllowedResources - ValueList of String - allowed resources
//  FillError - Boolean 
// 
// Returns:
//  Array of String - Create An Array Of Selections
Function CreateArrayOfSelections(Filters, MatchingCharacters, ListOfAllowedResources, FillError = False)
	
	ArrayOfSelections = New Array();
	
	For Each FilterElement In Filters.Items Do
		
			If Not FilterElement.Use Then
				Continue;
			EndIf;
			
			If Type(FilterElement) = Type("DataCompositionFilterItemGroup") Then
				
				NestedArrayOfSelections = CreateArrayOfSelections(FilterElement, 
																	MatchingCharacters, 
																	ListOfAllowedResources, 
																	FillError);
				
				If FillError Then
					Return ArrayOfSelections;
				EndIf;
				
				GroupTypeSign = GetSelectionBadge(FilterElement.GroupType, MatchingCharacters);
				
				StringOfNestedSelections = CreateSelectionLine(NestedArrayOfSelections, GroupTypeSign);
				
				If FilterElement.GroupType = DataCompositionFilterItemsGroupType.NotGroup Then
					StringOfNestedSelections = "Not (" + StringOfNestedSelections + ")";
				EndIf;
				
				If Not IsBlankString(StringOfNestedSelections) Then
					ArrayOfSelections.Add(StringOfNestedSelections);
				EndIf;
				
				Continue;
				
			EndIf;
			
			If ListOfAllowedResources.FindByValue(String(FilterElement.LeftValue)) = Undefined Then
				
				FillError = True;
				Return ArrayOfSelections;
				
			EndIf;
			
			
			SignOfComparison = GetSelectionBadge(FilterElement.ComparisonType, MatchingCharacters);
			
			RightValue = ?(FilterElement.RightValue = Undefined, 0, FilterElement.RightValue);
			
			If SignOfComparison = Undefined Then
				If FilterElement.ComparisonType = DataCompositionComparisonType.InList 
					Or FilterElement.ComparisonType = DataCompositionComparisonType.NotInList Then 
					
					ArrayOfValues = New Array();
					SignOfComparison = "=";
					
					For Each ListItem In FilterElement.RightValue Do
						
						ArrayOfValues.Add(StrTemplate("Sum(%1)%2%3",
													FilterElement.LeftValue,
													SignOfComparison,
													ListItem.Value));
													
					EndDo;
					
					StringOfSelectionValues = CreateSelectionLine(ArrayOfValues, "OR");
					
					If FilterElement.ComparisonType = DataCompositionComparisonType.NotInList Then
						StringOfSelectionValues = "Not (" + StringOfSelectionValues + ")";
					EndIf;
						
					If Not IsBlankString(StringOfSelectionValues) Then
						ArrayOfSelections.Add(StringOfSelectionValues);
					EndIf;
					
					Continue;
					
				Else
					Continue;
				EndIf;
			EndIf;

			ArrayOfSelections.Add(StrTemplate("Sum(%1)%2%3",
										FilterElement.LeftValue,
										SignOfComparison,
										RightValue));
			
	EndDo;
	
	Return ArrayOfSelections;
	
EndFunction

// Get a selection mark.
// 
// Parameters:
//  Var_ComparisonType - DataCompositionComparisonType - Type of comparison
//  MatchingCharacters - Undefined, Map of DataCompositionComparisonType - - Matching Characters
// 
// Returns:
//  String, Undefined - Sign Of Comparison
Function GetSelectionBadge(Var_ComparisonType, MatchingCharacters = Undefined)

	If MatchingCharacters = Undefined Then
		ToFormMatchOfSigns(MatchingCharacters);
	EndIf;
	
	Return MatchingCharacters.Get(Var_ComparisonType);
	
EndFunction

Function CreateSelectionLine(ArrayOfSelections, Connector = "And")
	
	Return StrConcat(ArrayOfSelections, Chars.LF +" " + Connector + " ");
	
EndFunction

// To form a correspondence of signs.
// 
// Parameters:
//  MatchingCharacters - Undefined, Map of DataCompositionComparisonType, DataCompositionFilterItemsGroupType -
Procedure ToFormMatchOfSigns(MatchingCharacters)
	
	MatchingCharacters = New Map();
	
	MatchingCharacters.Insert(DataCompositionComparisonType.Greater, ">");
	MatchingCharacters.Insert(DataCompositionComparisonType.GreaterOrEqual, ">=");
	MatchingCharacters.Insert(DataCompositionComparisonType.Filled, "<>");
	MatchingCharacters.Insert(DataCompositionComparisonType.Less, "<");
	MatchingCharacters.Insert(DataCompositionComparisonType.LessOrEqual, "<=");
	MatchingCharacters.Insert(DataCompositionComparisonType.NotFilled, "=");
	MatchingCharacters.Insert(DataCompositionComparisonType.NotEqual, "<>");
	MatchingCharacters.Insert(DataCompositionComparisonType.Equal, "=");

	MatchingCharacters.Insert(DataCompositionFilterItemsGroupType.AndGroup, "And");
	MatchingCharacters.Insert(DataCompositionFilterItemsGroupType.OrGroup, "OR");
	MatchingCharacters.Insert(DataCompositionFilterItemsGroupType.NotGroup, "And");
	
EndProcedure

#EndRegion

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	ParameterEstimationOfStocksByTypeOfPrices = DataCompositionClientServer.GetParameter(SettingsComposer, "EstimationOfStocksByTypeOfPrices");
	If Not ParameterEstimationOfStocksByTypeOfPrices.Value = 3 Then
		AuxiliaryParameters.Add("PriceKind");
	EndIf;
	
	If Not GetFunctionalOption("UseSeveralPriceTypes") Then
		AuxiliaryParameters.Add("EstimationOfStocksByTypeOfPrices");
	EndIf;
	
	AuxiliaryParameters.Add("QuantitativeResultsForUnits");
		
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;
EndFunction

Function ParameterizableFieldHeaders()
	
	Return DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
EndFunction

Function StructureOfDynamicHeaders()
	DynamicHeaders = New Structure;
	
	Parameter = DataCompositionClientServer.GetParameter(SettingsComposer, "GroupingProducts");
	AvailableSetting = ReportsClientServer.FindAvailableSetting(SettingsComposer.Settings, Parameter);
	If AvailableSetting <> Undefined Then
		PresentationOfParameterValue = AvailableSetting.AvailableValues[Parameter.Value-1];
		DynamicHeaders.Insert("GroupingProducts", PresentationOfParameterValue);
	EndIf;
	
	Return DynamicHeaders;
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseUnitsOfMeasureForReports") Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(FormSettingsComposer, "QuantityUnits");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
