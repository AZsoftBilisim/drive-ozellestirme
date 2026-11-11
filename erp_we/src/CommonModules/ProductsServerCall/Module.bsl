#Region Private

// Server-side event handler Obrabatyvaniya Handbook of Sereinement.
//
Procedure ProductSeriesSelectionDataAcquisitionProcessing(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	If Parameters.Property("ProductKind") Then
		
		QueryText =
		"SELECT TOP 50
		|	ItemsBatches.Ref AS Series,
		|	ItemsBatches.Description AS Description,
		|	&RequestTextForSeriesFields
		|FROM
		|	Catalog.ItemsBatches AS ItemsBatches
		|WHERE
		|	ItemsBatches.ProductKind = &ProductKind
		|	AND &TextOfConditionRequestBySeriesFields
		|
		|ORDER BY
		|	Number,
		|	ValidUntil_";
		
		Query = New Query;
		If Not Parameters.Property("SeriesUseSettings") Then
			SeriesUseSettings = Catalogs.ItemKinds.SeriesUseSettings(Parameters.ProductKind);
		Else
			SeriesUseSettings = Parameters.SeriesUseSettings;
		EndIf;
		
		Query.SetParameter("ProductKind", SeriesUseSettings.BatchOwner);
		
		TemplateForConditionText = " 
		|		CASE
		|			WHEN ItemsBatches.ProductKind.%SettingName%
		|				THEN &DetailsNotFilledIn_
		|						OR ItemsBatches.%AttributeName% %ComparisonType% &AttributeValue
		|			ELSE TRUE
		|		END";
		
		ArrayOfConditionTexts = New Array;
		NamesOfDetailsOfSeries = New Array;
		
		For Each Attribute In SeriesUseSettings.DescriptionsOfUseOfSeriesProps Do
			
			If Attribute.Use
				And Attribute.SettingName <> "UseRFIDTags" Then
				
				ConditionText = StrReplace(TemplateForConditionText, "%SettingName%", Attribute.SettingName);
				ConditionText = StrReplace(ConditionText, "%AttributeName%", Attribute.AttributeName);
				ConditionText = StrReplace(ConditionText, "&DetailsNotFilledIn_", "&DetailsNotFilledIn_" + Attribute.AttributeName);
				ConditionText = StrReplace(ConditionText, "&AttributeValue", "&AttributeValue" + Attribute.AttributeName);
				
				If TypeOf(Parameters[Attribute.AttributeName]) = Type("String") Then
					ConditionText = StrReplace(ConditionText, "%ComparisonType%", "LIKE");
					Query.SetParameter("DetailsNotFilledIn_" + Attribute.AttributeName, IsBlankString(Parameters[Attribute.AttributeName]));
					Query.SetParameter("AttributeValue" + Attribute.AttributeName, "%" + TrimAll(Parameters[Attribute.AttributeName]) + "%");
				Else
					ConditionText = StrReplace(ConditionText, "%ComparisonType%", "=");
					Query.SetParameter("DetailsNotFilledIn_" + Attribute.AttributeName, Not ValueIsFilled(Parameters[Attribute.AttributeName]));
					Query.SetParameter("AttributeValue" + Attribute.AttributeName, Parameters[Attribute.AttributeName]);
				EndIf;
				
				ArrayOfConditionTexts.Add(ConditionText);
				
			EndIf;
			
			NamesOfDetailsOfSeries.Add(Attribute.AttributeName);
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "&RequestTextForSeriesFields",
				DataProcessors.SelectBatchToDocuments.RequestTextDetailsOfSeries("ItemsBatches", SeriesUseSettings, False, False));
				
		QueryText = StrReplace(QueryText, "&TextOfConditionRequestBySeriesFields", StrConcat(ArrayOfConditionTexts, Chars.LF + "And" + Chars.NBSp));
		
		Query.Text = QueryText;
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			Value = New Structure("Series," + StrConcat(NamesOfDetailsOfSeries, ","));
			FillPropertyValues(Value, Selection);
			
			ChoiceData.Add(Value, Selection.Description);
			
		EndDo;
		
	ElsIf Parameters.Property("Products")
		And ValueIsFilled(Parameters.Products) Then
		
		SearchString = Parameters.SearchString;
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 50
		|	CatSetOfSeries.Ref AS Series,
		|	CatSetOfSeries.Description AS SeriesPresentation
		|FROM
		|	Catalog.Products AS CatProducts
		|		INNER JOIN Catalog.ItemsBatches AS CatSetOfSeries
		|		ON (CatSetOfSeries.ProductKind = CASE
		|				WHEN CatProducts.ProductKind.BatchSettingsAreTakenFromOtherItemsKind
		|					THEN CatProducts.ProductKind.BatchOwner
		|				ELSE CatProducts.ProductKind
		|			END)  
		|WHERE
		|	CatProducts.Ref = &Products
		|	" + ?(SearchString = Undefined, "", "AND CatSetOfSeries.Description LIKE &SearchString ESCAPE ""~""") + "
		|ORDER BY
		|	SeriesPresentation";
		
		Query.SetParameter("Products", Parameters.Products);
		
		If SearchString <> Undefined Then
			Query.SetParameter("SearchString", "%" + Common.GenerateSearchQueryString(TrimAll(SearchString)) + "%");
		EndIf;
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ChoiceData.Add(Selection.Series, Selection.SeriesPresentation);
		EndDo;
		
	ElsIf Parameters.SearchString <> Undefined Then
		
		QueryText =
		"SELECT ALLOWED DISTINCT TOP 50
		|	ItemsBatches.Ref AS Series,
		|	ItemsBatches.Description AS SeriesPresentation,
		|	ISNULL(GoodsBatchMovement.Products, UNDEFINED) AS Products,
		|	ISNULL(GoodsBatchMovement.Products.Presentation, """") AS ProductsPresentation,
		|	ISNULL(GoodsBatchMovement.Characteristic, UNDEFINED) AS Characteristic,
		|	ISNULL(GoodsBatchMovement.Characteristic.Presentation, """") AS CharacteristicPresentation
		|FROM
		|	Catalog.ItemsBatches AS ItemsBatches
		|		LEFT JOIN AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
		|		ON (GoodsBatchMovement.Series = ItemsBatches.Ref)
		|WHERE
		|	&ComparisonCondition
		|
		|ORDER BY
		|	SeriesPresentation,
		|	ProductsPresentation";
		
		ComparisonCondition = "ItemsBatches.Description %ComparisonType% &SearchString";
		
		Query = New Query;
		Query.Text = StrReplace(QueryText, "&ComparisonCondition", 
							StrReplace(ComparisonCondition, "%ComparisonType%", "="));
		Query.SetParameter("SearchString", TrimAll(Parameters.SearchString));
		
		Result = Query.Execute();
		
		If Result.IsEmpty() Then
			
			Query = New Query;
			Query.Text = StrReplace(QueryText, "&ComparisonCondition", 
								StrReplace(ComparisonCondition, "%ComparisonType%", "LIKE") + " ESCAPE ""~""");
			Query.SetParameter("SearchString", "%" + Common.GenerateSearchQueryString(TrimAll(Parameters.SearchString)) + "%");
			
			Result = Query.Execute();
			
		EndIf;
		
		Selection = Result.Select();
		
		ChoiceData = New ValueList;
		
		While Selection.Next() Do
			
			If ValueIsFilled(Selection.Products) Then
				
				ProductPresentation = ProductsClientServer.ProductPresentation(
					Selection.ProductsPresentation,
					Selection.CharacteristicPresentation);
					
					ValuePresentation = StringFunctionsClientServer.SubstituteParametersToString(
																			NStr("vi = '%1 (%2)';
																				|ru = '%1 (%2)';
																				|en = '%1 (%2)'; fa = '%1 (%2)';
																				|it = '%1 (%2)';
																				|pl = '%1 (%2)';
																				|tr = '%1 (%2)'"),
																			Selection.SeriesPresentation,
																			ProductPresentation);
			Else
				
				ValuePresentation = Selection.SeriesPresentation;
				
			EndIf; 
			
			ChoiceData.Add(Selection.Series, ValuePresentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Server handler for the event processingreceiving data for The selection of the directory Politikiuchetaseries.
//
Procedure SeriesAccountingPoliciesProcessingSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If Not Parameters.Property("Filter") Then
		Parameters.Insert("Filter", New Structure);
	ElsIf Not TypeOf(Parameters.Filter) = Type("Structure") Then
		Parameters.Filter = New Structure;
	EndIf;
	
	CommonClientServer.SupplementStructure(Parameters.Filter, ProductsServer.SelectionOfSeriesAccountingPoliciesByParameters(Parameters));
	
EndProcedure

Procedure PackagingUnitsOfMeasurementFormReceiptProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export 
	
	If FormType = "ObjectForm" Then
		
		StandardProcessing = False;
		
		If Parameters.Property("Key") 
			And Common.ObjectAttributeValue(Parameters.Key, "MeasuredValueType") = Enums.TypesOfMeasuredValues.Package Then 				
			SelectedForm = "PackageItemForm";
			Return;
		EndIf;
		
		If Parameters.Property("CopyingValue") 
			And Common.ObjectAttributeValue(Parameters.CopyingValue, "MeasuredValueType") = Enums.TypesOfMeasuredValues.Package Then
			SelectedForm = "PackageItemForm";
			Return;
		EndIf;
		
		If Parameters.Property("ChoiceParameters") 
			And Parameters.ChoiceParameters.Property("MeasuredValueType") 
			And Parameters.ChoiceParameters.MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then  			
			SelectedForm = "PackageItemForm";
			Return;
		EndIf;
		
		SelectedForm = "ItemFormUnitsOfMeasure";
		
 	ElsIf FormType = "ChoiceForm" Then
		MeasuredValueType = Undefined;
		
		If Parameters.Property("Filter") 
			And (Parameters.Filter.Property("MeasuredValueType",MeasuredValueType)
			Or Parameters.Property("MeasuredValueType",MeasuredValueType)) Then
			
			If MeasuredValueType = Enums.TypesOfMeasuredValues.Package Then
				SelectedForm = "PackageChoiceForm";
			Else
				SelectedForm = "UnitOfMeasureChoiceForm";
			EndIf;
			
			StandardProcessing = False;
		ElsIf Parameters.Property("Products")
			And Not (Parameters.Property("AlwaysChooseUnitOfMeasurement") And Not ValueIsFilled(Parameters.Products)) Then 
			SelectedForm = "FormOfSelectionFromDocuments";
			StandardProcessing = False;
		Else
			SelectedForm = "UnitOfMeasureChoiceForm";
			If Not Parameters.Property("Filter") Then
				Parameters.Insert("Filter", New Structure);
			EndIf;
			ArrayOfUnitTypes = New Array;
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Weight);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.VolumeM3);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.AreaTypeOfMeasurement);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Length);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.NumberOfPieces);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Capacity);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Energy);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.ElectricCharge);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.Time);
			ArrayOfUnitTypes.Add(Enums.TypesOfMeasuredValues.EmptyRef());
			Parameters.Filter.Insert("MeasuredValueType", ArrayOfUnitTypes);
			StandardProcessing = False;
		EndIf;
		
	ElsIf FormType = "ListForm" Then
		StandardProcessing = False;		

		CurrentRow = Undefined;
		
		If Parameters.Property("CurrentRow", CurrentRow) Then
			Owner = Common.ObjectAttributeValue(CurrentRow, "Owner");
		ElsIf Parameters.Property("Filter")
			And Parameters.Filter.Property("Owner") Then
			Owner = Parameters.Filter.Owner;	
		Else
			Owner = Undefined;
		EndIf;
		
		If Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure Then
			SelectedForm = "FormOfUnitsOfMeasureList";
		Else
			SelectedForm = "PackageListForm";
		EndIf;
		
		If Owner <> Undefined Then
			
			If Not Parameters.Property("Filter") Then
				Parameters.Insert("Filter", New Structure);
			EndIf;
			
			Parameters.Filter.Insert("Owner", Owner);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Server handler for the event processingreceiving data For the selection of the Nomenclature reference list.
//
Procedure ProductsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	// We get the structure of the possible selection fields of the nomenclature directory
	AttributesStructure1 = SettingsValueCached.CatalogAttributes("Products");
	
	Query        = New Query;
	SearchString  = Parameters.SearchString;
	
	QueryText =
	"SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark AS DeletionMark,
	|	CatProducts.Description AS PresentationOfMatch,
	|	CatProducts.Quality.Order AS Quality,
	|	0 AS Order,
	|	CatProducts.Code AS ProductPresentation,
	|	CatProducts.IsFolder
	|INTO ProductSearch
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.Description LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|
	|UNION ALL
	|
	|SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark AS DeletionMark,
	|	CatProducts.DescriptionLanguage1 AS PresentationOfMatch,
	|	CatProducts.Quality.Order AS Quality,
	|	1 AS Order,
	|	CatProducts.Code AS ProductPresentation,
	|	CatProducts.IsFolder
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	&AdditionalLanguagesAreUsed = TRUE
	|	AND CatProducts.DescriptionLanguage1 LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|
	|UNION ALL
	|
	|SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark AS DeletionMark,
	|	CatProducts.DescriptionLanguage2 AS PresentationOfMatch,
	|	CatProducts.Quality.Order AS Quality,
	|	2 AS Order,
	|	CatProducts.Code AS ProductPresentation,
	|	CatProducts.IsFolder
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	&AdditionalLanguagesAreUsed = TRUE
	|	AND CatProducts.DescriptionLanguage2 LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|
	|UNION ALL
	|
	|SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark,
	|	CatProducts.Code,
	|	CatProducts.Quality.Order,
	|	3,
	|	CatProducts.Description,
	|	NULL
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.Code LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|
	|UNION ALL
	|
	|SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark,
	|	CatProducts.SKU,
	|	CatProducts.Quality.Order,
	|	4,
	|	CatProducts.Description,
	|	NULL
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.SKU LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|
	|UNION ALL
	|
	|SELECT TOP 50
	|	CatProducts.Ref,
	|	CatProducts.DeletionMark,
	|	CatProducts.SearchCode,
	|	CatProducts.Quality.Order,
	|	5,
	|	CatProducts.Description,
	|	NULL
	|FROM
	|	Catalog.Products AS CatProducts
	|WHERE
	|	CatProducts.SearchCode LIKE &SearchString ESCAPE ""~""
	|	AND &FilterCriterion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ProductSearch.Ref,
	|	MIN(ProductSearch.Order) AS Order
	|INTO ProductsInOrder
	|FROM
	|	ProductSearch AS ProductSearch
	|
	|GROUP BY
	|	ProductSearch.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT TOP 50
	|	ISNULL(ProductSearch.Quality, 0) AS Quality,
	|	ProductSearch.DeletionMark AS DeletionMark,
	|	ProductSearch.Ref AS Ref,
	|	ISNULL(ProductSearch.Order, 0) AS Order,
	|	ISNULL(ProductSearch.PresentationOfMatch, """") AS PresentationOfMatch,
	|	ISNULL(ProductSearch.ProductPresentation, """") AS ProductPresentation
	|FROM
	|	ProductsInOrder AS ProductsInOrder
	|		LEFT JOIN ProductSearch AS ProductSearch
	|		ON ProductsInOrder.Ref = ProductSearch.Ref
	|			AND ProductsInOrder.Order = ProductSearch.Order
	|
	|ORDER BY
	|	Order,
	|	Quality,
	|	PresentationOfMatch,
	|	ProductPresentation";
	
	ProductsLocalization.ChoiceDataGetProcessing(Parameters, Query, QueryText);
	
	FilterCriterion = "TRUE";
	
	NamesOfNonStandardSelections = New Structure;
	NamesOfNonStandardSelections.Insert("ItemsType", "ItemsType");
	
	For Each SelectionKeyAndValue In Parameters.Filter Do
		FilterName = SelectionKeyAndValue.Key;
		FilterValue = SelectionKeyAndValue.Value;
		
		NameOfNonStandardSelection = "";
		If NamesOfNonStandardSelections.Property(FilterName, NameOfNonStandardSelection) Then
			
			If NameOfNonStandardSelection = "ItemsType" 
				And TypeOf(FilterValue) = Type("Array")
				And FilterValue.Find(Enums.ItemsTypes.Set) <> Undefined Then
				
				FilterValue = Common.CopyRecursive(FilterValue); // A copy for the immutability of the incoming parameter
				FilterValue.Delete(FilterValue.Find(Enums.ItemsTypes.Set));
				Query.SetParameter("ItemsType", FilterValue);
				
				LimitSetsByService = FilterValue.Find(Enums.ItemsTypes.OperationService) <> Undefined
					Or FilterValue.Find(Enums.ItemsTypes.Work_5) <> Undefined;
				LimitSetsByProduct = FilterValue.Find(Enums.ItemsTypes.ReusablePackage) <> Undefined
					Or FilterValue.Find(Enums.ItemsTypes.OwnGoods) <> Undefined;
						
				FilterText1 = "
				|	AND (CatProducts.ItemsType IN (&ItemsType)
				|		OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
				|			AND &TextOfSetRestriction 
				|			AND CatProducts.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
				|		OR CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
				|			AND CatProducts.UseVariants <> VALUE(Enum.ItemVariantsUsageOptions.DontUse))";
				
				If LimitSetsByProduct And Not LimitSetsByService Then
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"NOT ProductKitConfigurations.ContainsServices AND ProductKitConfigurations.ContainsGoods");
				ElsIf Not LimitSetsByProduct And LimitSetsByService Then
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"ProductKitConfigurations.ContainsServices AND NOT ProductKitConfigurations.ContainsGoods");
				Else
					FilterText1 = StrReplace(
						FilterText1,
						"&TextOfSetRestriction",
						"TRUE");
				EndIf;
				
				FilterCriterion = FilterCriterion + FilterText1;
					
				TableDetails = 
					RequestSchemes.TableDetails(
					Type("QuerySchemaTable"),
					"Catalog.ProductKitConfigurations",
					"ProductKitConfigurations",
					"Owner, ContainsGoods, ContainsServices");
				
				IConnectionShort =
					RequestSchemes.IConnectionShort(
					TableDetails,
					"CatProducts.Ref = ProductKitConfigurations.Owner
					|AND VALUE(Catalog.ItemsCharacteristics.EmptyRef) = ProductKitConfigurations.Characteristic
					|AND ProductKitConfigurations.Main",
					QuerySchemaJoinType.LeftOuter);
				
				QueryText =
					RequestSchemes.AddConnectionToRequest(
					QueryText,
					"CatProducts",
					IConnectionShort,
					0);
					
				Continue;
				
			EndIf;
			
		EndIf;
		
		If AttributesStructure1.Property(FilterName) Then
			FilterCriterion = FilterCriterion + "
				|	AND CatProducts." + SelectionKeyAndValue.Key + " IN (&" + SelectionKeyAndValue.Key + ")";
			Query.SetParameter(SelectionKeyAndValue.Key,SelectionKeyAndValue.Value);
		EndIf;
		
	EndDo;
	
	If Not Parameters.Filter.Property("IsFolder") And Parameters.Property("ChoiceFoldersAndItems") Then
		If Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
			FilterCriterion = FilterCriterion + "
				|	AND CatProducts.IsFolder";
		ElsIf Parameters.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
			FilterCriterion = FilterCriterion + "
				|	AND NOT CatProducts.IsFolder";
		EndIf;
	EndIf;
	
	If Parameters.Property("SelectGoodsOfOtherQuality")
		And Parameters.SelectGoodsOfOtherQuality
		And Parameters.Property("ProductOfOriginalQuality") Then
		
		Query.SetParameter("ProductOfOriginalQuality", Parameters.ProductOfOriginalQuality);
		
		If GetFunctionalOption("UseSummaryAccountingOfLowQualityGoods") Then
			
			FilterCriterion = FilterCriterion + "
				|	AND NOT CatProducts.Quality = VALUE(Enum.QualityLevels.New)";
			
			ProductsFields = New Structure;
			ProductsFields.Insert("ProductKind");
			ProductsFields.Insert("KeepAccountingByBatch",           "ProductKind.KeepAccountingByBatch");
			ProductsFields.Insert("BatchUsageSettings", "ProductKind.BatchUsageSettings");
			
			ProductAttributes = Common.ObjectAttributesValues(Parameters.ProductOfOriginalQuality, ProductsFields);
			
			If ProductAttributes.KeepAccountingByBatch = True
				And Not ProductAttributes.BatchUsageSettings =
						Enums.ItemsBatchUsageSettings.InventoryItem Then
				
				FilterCriterion = FilterCriterion + "
					|	AND CatProducts.ProductKind =
					|		 CAST(&ProductOfOriginalQuality AS Catalog.Products).ProductKind";
				
			EndIf;
			
		Else
			
			TableDetails = 
				RequestSchemes.TableDetails(
					Type("QuerySchemaTable"),
					"InformationRegister.AnotherQualityGoods",
					"AnotherQualityGoods",
					"OtherQualityGoods, Products");
			
			IConnectionShort =
			RequestSchemes.IConnectionShort(
				TableDetails,
				"AnotherQualityGoods.OtherQualityGoods = CatProducts.Ref
				|AND AnotherQualityGoods.Products = &ProductOfOriginalQuality",
				QuerySchemaJoinType.Inner);
			
			QueryText =
				RequestSchemes.AddConnectionToRequest(
					QueryText,
					"CatProducts",
					IConnectionShort,
					0);
			
		EndIf;
		
	EndIf;
	
	SetPriceCalculationOptions = New Array;
	If Parameters.Property("SetPriceCalculationOptions", SetPriceCalculationOptions) Then
		
		Query.SetParameter("SetPriceCalculationOptions", SetPriceCalculationOptions);
		
		FilterCriterion = FilterCriterion +
			Chars.LF +
			"	AND CASE
			|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Set)
			|			THEN CatProducts.Ref NOT IN
			|			(SELECT
			|				Sets.Owner AS Owner
			|			FROM
			|				Catalog.ProductKitConfigurations AS Sets
			|			WHERE
			|				NOT Sets.DeletionMark
			|				AND Sets.Main
			|				AND Sets.SetPricingOption NOT IN (&SetPriceCalculationOptions))
			|		ELSE TRUE
			|	END";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FilterCriterion", FilterCriterion);
	
	Query.Text = QueryText;
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	Query.SetParameter("AdditionalLanguagesAreUsed", Not NationalLanguageSupportCached.ConfigurationUsesOnlyOneLanguage(False));
	
	ChoiceData = New ValueList;

	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ValueText = TrimR(Selection.PresentationOfMatch) + " (" + Selection.ProductPresentation + ")";
		
		ListValue = New Structure;
		ListValue.Insert("Value", Selection.Ref);
		ListValue.Insert("DeletionMark", Selection.DeletionMark);
	
		ChoiceData.Add(ListValue, ValueText);
		
	EndDo;
	
	
EndProcedure

// Server handler for the event processingreceiving data From the list of Nomenclature types.
//
Procedure TypesOfProductsProcessingOfSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
    If Parameters.Property("Products")
        And ValueIsFilled(Parameters.Products) Then
        
        ConditionsForSelectingNewTypeOfProduct = Catalogs.Products.ConditionsForSelectingNewTypeOfProduct();
        
		Query = New Query;
        Query.Text =
        "SELECT TOP 50
        |	NewTypeOfProduct.Ref AS Ref,
        |	NewTypeOfProduct.DeletionMark AS DeletionMark,
        |	NewTypeOfProduct.Description AS Description
        |FROM
        |	Catalog.ItemKinds AS NewTypeOfProduct
        |WHERE
        |	NOT NewTypeOfProduct.IsFolder
        |	";
        
        For Each KeyValue In ConditionsForSelectingNewTypeOfProduct Do
            
            Query.Text = Query.Text + " AND NOT " + KeyValue.Value;
            
        EndDo;
		
        QueryOptions = Query.FindParameters();
        
        AttributesNames = New Structure;
        For Each Parameter In QueryOptions Do
            AttributesNames.Insert(Parameter.Name, "ProductKind." + Parameter.Name);
        EndDo;
        
        OldDetails = Common.ObjectAttributesValues(Parameters.Products, AttributesNames);
        For Each Parameter In QueryOptions Do
            Query.SetParameter(Parameter.Name, OldDetails[Parameter.Name]);
        EndDo;
		
		Query.Text = Query.Text + "
		|	AND (&SearchTerms)
		|
		|ORDER BY
		|	NewTypeOfProduct.Description";
		
		SearchTerms = "NewTypeOfProduct.Description LIKE &SearchString ESCAPE ""~""";
		
		For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
			
			If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
				
				LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
				If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
					
					Continue;
					
				EndIf;
				
				AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
				SearchTerms = SearchTerms + "
				|	OR " + StringFunctionsClientServer.SubstituteParametersToString("NewTypeOfProduct.%1 LIKE &SearchString ESCAPE ""~""",
					AttributesNames["Description"]);
				
			EndIf;
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "&SearchTerms", SearchTerms);
		
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
        
        ChoiceData = New ValueList;
        
        Selection = Query.Execute().Select();
        While Selection.Next() Do
            
			SelectionValue = New Structure;
			SelectionValue.Insert("Value", Selection.Ref); 
			SelectionValue.Insert("DeletionMark", Selection.DeletionMark); 
			SelectionValue.Insert("Warning ", ""); 
			
			ChoiceData.Add(SelectionValue, Selection.Description);
			
		EndDo;
	Else
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 50
		|	NewTypeOfProduct.Ref AS Ref,
		|	NewTypeOfProduct.DeletionMark AS DeletionMark,
		|	NewTypeOfProduct.Description AS Description
		|FROM
		|	Catalog.ItemKinds AS NewTypeOfProduct
		|WHERE
		|	NOT NewTypeOfProduct.IsFolder
		|	AND &FilterConditions
		|	AND (&SearchTerms)
		|
		|ORDER BY
		|	NewTypeOfProduct.Description";
		
		FilterConditions = "TRUE";
		For Each Filter In Parameters.Filter Do
			
			If TypeOf(Filter.Value) = Type("FixedArray")
				Or TypeOf(Filter.Value) = Type("Array") Then
				
				FIlterRow = "NewTypeOfProduct.%1 IN (&%2)"
				
			Else
				
				FIlterRow = "NewTypeOfProduct.%1 = &%2"
				
			EndIf;
			
			FilterConditions = FilterConditions + "
			|	AND " + StringFunctionsClientServer.SubstituteParametersToString(FIlterRow, Filter.Key, Filter.Key);
			
			Query.SetParameter(Filter.Key, Filter.Value);
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "&FilterConditions", FilterConditions);
		
		SearchTerms = "NewTypeOfProduct.Description LIKE &SearchString ESCAPE ""~""";
		
		For AdditionalLanguageNumber = 1 To NationalLanguageSupportServer.AdditionalLanguagesCount() Do
			
			If NationalLanguageSupportServer.IsAdditionalLangUsed(AdditionalLanguageNumber) Then
				
				LanguageConstantName = NationalLanguageSupportServer.LanguageConstantName(AdditionalLanguageNumber);
				If Metadata.Constants.Find(LanguageConstantName) = Undefined Then
					
					Continue;
					
				EndIf;
				
				AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description", Constants[LanguageConstantName].Get());
				SearchTerms = SearchTerms + "
				|	OR " + StringFunctionsClientServer.SubstituteParametersToString("NewTypeOfProduct.%1 LIKE &SearchString ESCAPE ""~""",
					AttributesNames["Description"]);
				
			EndIf;
			
		EndDo;
		
		Query.Text = StrReplace(Query.Text, "&SearchTerms", SearchTerms);
		Query.SetParameter("SearchString", Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
		
		ChoiceData = New ValueList;
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			SelectionValue = New Structure;
			SelectionValue.Insert("Value", Selection.Ref); 
			SelectionValue.Insert("DeletionMark", Selection.DeletionMark); 
			SelectionValue.Insert("Warning ", ""); 
			
			ChoiceData.Add(SelectionValue, Selection.Description);
			
		EndDo;
		
	EndIf;

EndProcedure

// Server handler for the event processingreceiving data For the selection of a set of Packages directory.
//
Procedure PackingSetsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	Query = New Query;
	StandardProcessing = False;
	
	Query.Text = 
	"SELECT
	|	PackagingGroups.Ref AS Value,
	|	PackagingGroups.Description AS Presentation
	|FROM
	|	Catalog.PackagingGroups AS PackagingGroups
	|WHERE
	|	PackagingGroups.Ref <> VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|	AND PackagingGroups.Ref <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|
	|ORDER BY
	|	PackagingGroups.Description";
	
	Selection = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Value, Selection.Presentation);
	EndDo;
	
EndProcedure

// Server handler for the event processingreceiving data For selecting the inventory Groupnumber directory.
//
Procedure WarehouseGroupsProductsProcessingOfSelectionData(ChoiceData, Parameters, StandardProcessing) Export
	
	StandardProcessing = False;
	
	// We get the structure of the possible selection fields of the nomenclature directory
	AttributesStructure1 = SettingsValueCached.CatalogAttributes("WarehouseGroupsOfItems");
	
	If Parameters.Property("AssignedPurchaseSale") Then
		AssignedPurchaseSale = Parameters.AssignedPurchaseSale;
	Else
		AssignedPurchaseSale = True;
	EndIf;
	
	FilterCriterion = "";
	Query = New Query;
	SearchString = Parameters.SearchString;
	
	For Each SelectionKeyAndValue In Parameters.Filter Do
		If AttributesStructure1.Property(SelectionKeyAndValue.Key) Then
			FilterCriterion = FilterCriterion + "
				|	AND WarehouseGroupsOfItems." + SelectionKeyAndValue.Key + " IN (&" + SelectionKeyAndValue.Key + ")";
			Query.SetParameter(SelectionKeyAndValue.Key,SelectionKeyAndValue.Value);
		EndIf;
	EndDo;
	
	QueryText =
	"SELECT
	|	WarehouseGroupsOfItems.Ref AS Ref,
	|	WarehouseGroupsOfItems.Description AS Description
	|FROM
	|	Catalog.WarehouseGroupsOfItems AS WarehouseGroupsOfItems
	|WHERE
	|	WarehouseGroupsOfItems.Description LIKE &SearchString ESCAPE ""~""
	|	AND (NOT &OnlyPhysicallyDifferentFromDestination
	|			OR &OnlyPhysicallyDifferentFromDestination
	|				AND NOT WarehouseGroupsOfItems.PhysicallyDifferentFromAssignment)
	|
	|ORDER BY
	|	Description";
	
	If ValueIsFilled(FilterCriterion) Then 
		QueryText = StrReplace(
			QueryText, 
			"WarehouseGroupsOfItems.Description LIKE &SearchString ESCAPE ""~""",
			"WarehouseGroupsOfItems.Description LIKE &SearchString ESCAPE ""~""" + FilterCriterion);
	EndIf;
	
	Query.SetParameter("OnlyPhysicallyDifferentFromDestination", Not AssignedPurchaseSale);
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	
	Query.Text = QueryText;
	
	ChoiceData = New ValueList;
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ChoiceData.Add(Selection.Ref, Selection.Description);
	EndDo;
	
EndProcedure

// Server handler for the event processingreceiving data from the time unit enumeration Selection.
//
Procedure ExpirationDateUnitsProcessingOfSelectionDataAcquisition(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.Property("ProductKind") Then
		
		StandardProcessing = False;
		
		ProductKind = Parameters.ProductKind;
		ShelfLifeUnitOfMeasure = Undefined;
		
		ExcludedValues = New Array;
		ExcludedValues.Add(Enums.TimeMeasureUnits.Second);
		ExcludedValues.Add(Enums.TimeMeasureUnits.Minute);
		ExcludedValues.Add(Enums.TimeMeasureUnits.Day);
		
		If ValueIsFilled(ProductKind) Then
			ShelfLifeUnitOfMeasure = Common.ObjectAttributeValue(ProductKind,
																					"ShelfLifeUnitOfMeasure");
		EndIf;
		
		If ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.Days1 Then
			ExcludedValues.Add(Enums.TimeMeasureUnits.Hour);
		ElsIf ShelfLifeUnitOfMeasure = Enums.TimeMeasureUnits.Month Then
			ExcludedValues.Add(Enums.TimeMeasureUnits.Hour);
			ExcludedValues.Add(Enums.TimeMeasureUnits.Days1);
		EndIf;
		
		GeneralPurposeTMServerCall.SelectableEnumerationValues("TimeMeasureUnits",
																			ChoiceData,
																			Parameters,
																			ExcludedValues);
		
	EndIf;
	
EndProcedure

// Returns the item's storage unit.
//
// Parameters:
//  Products - CatalogRef.Products - item reference,
//
// Returns:
//  CatalogRef.PackagesAndUnitsOfMeasure - the item storage unit.
//
Function ProductStorageUnit(Val Products) Export
	
	Return Catalogs.PackagesAndUnitsOfMeasure.ProductStorageUnit(Products);
	
EndFunction

#Region QualityCertificates

// Runs a background task to set the Status of certificates of the item.
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - See ProductsClientServer.ParametersForSettingStatusOfCertificatesOfDefaultNomenclature.
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function SetStatusOfNomenclatureCertificates(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Thay đổi trạng thái chứng nhận mặt hàng';
														|ru = 'Изменение статуса сертификатов номенклатуры';
														|en = 'Change quality certificate status'; fa = 'Change quality certificate status';
														|it = 'Изменение статуса сертификатов номенклатуры';
														|pl = 'Change quality certificate status';
														|tr = 'Kalite belgeleri durumunu düzenle'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"Catalogs.QualityCertificates.SetStatusOfNomenclatureCertificates",
							FillParameters);
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

#EndRegion
