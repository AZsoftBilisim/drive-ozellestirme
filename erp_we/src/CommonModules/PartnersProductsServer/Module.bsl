
#Region Public

#Region FillingInPartnerProductsInDocuments

// Generates the request text for checking the products table part for duplicates of the partner's item.
//
// Parameters:
//  QueryText     - String    - text string to which you want to add the query text.
//  QueryOptions - Structure - structure containing the request parameters.
//
Procedure GenerateRequestForFillingInPartnerProductListCorrectly(QueryText, QueryOptions) Export
	
	TheTextOfTheSearchQuery = "SELECT
	|	MAX(NestedRequestForDuplicates.LineNumber) AS LineNumber,
	|	NestedRequestForDuplicates.ProductCrossReference AS ProductCrossReference
	|FROM
	|	(SELECT
	|		MAX(DocumentGoods.LineNumber) AS LineNumber,
	|		DocumentGoods.ProductCrossReference AS ProductCrossReference,
	|		DocumentGoods.Products AS Products,
	|		DocumentGoods.Characteristic AS Characteristic,
	|		DocumentGoods.Package AS Package
	|	FROM
	|		TemporaryTableOfGoods_ AS DocumentGoods
	|	WHERE
	|		DocumentGoods.Products <> &EmptyItemList
	|		AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductCrossReferences AS ProductCrossReferences
	|				WHERE
	|					ProductCrossReferences.Ref = DocumentGoods.ProductCrossReference
	|					AND ProductCrossReferences.Products =&EmptyItemList)
	|	
	|	GROUP BY
	|		DocumentGoods.ProductCrossReference,
	|		DocumentGoods.Products,
	|		DocumentGoods.Characteristic,
	|		DocumentGoods.Package) AS NestedRequestForDuplicates
	|
	|GROUP BY
	|	NestedRequestForDuplicates.ProductCrossReference
	|
	|HAVING
	|	COUNT(*) > 1";
	
	QueryText = QueryText + TheTextOfTheSearchQuery + Common.QueryBatchSeparator();
	QueryOptions.Insert("EmptyItemList", Catalogs.Products.EmptyRef());
		
EndProcedure

// Displays error messages about duplicates in the table part of All documents.
//
// Parameters:
//  Selection         - QueryResultSelection - query result selection:
//   * ProductCrossReference - CatalogRef.ProductCrossReferences - link to the partner's nomenclature.
//   * LineNumber             - Number                                     - line number in the document.
//  Document        - DocumentObject             - document to display error messages for
//  Cancel           - Boolean                     - indicates that the document was rejected.
//
Procedure ReportErrorsCorrectFillingOfPartnerProducts(Selection, Document, Cancel) Export
	
	While Selection.Next() Do
		
		ErrorText = NStr("vi = 'Trong dòng không thể chọn ""%PartnerProducts%"" bởi vì trong các dòng trước đó, mặt hàng này tương ứng với mặt hàng khác.';
						|ru = 'В строке не может быть выбрана ""%PartnerProducts%"", т.к. в предыдущих строках она соответствует другой номенклатуре.';
						|en = 'Cannot select ""%PartnerProducts%"" in the line, as it corresponds to other item in previous lines.'; fa = 'Cannot select ""%PartnerProducts%"" in the line, as it corresponds to other item in previous lines.';
						|it = 'Nella riga non può essere selezionato ""%PartnerProducts%"", poiché nelle righe precedenti coincide con un altro articolo.';
						|pl = 'W wierszu nie może być wybrana ""%PartnerProducts%"", ponieważ w poprzednich wierszach ona odpowiada innej nomenklaturze.';
						|tr = 'Satırda ""%PartnerProducts%"" seçilemez, çünkü önceki satırlarda farklı bir öğeye karşılık gelir.'");
		ErrorText = StrReplace(ErrorText, "%PartnerProducts%", Selection.ProductCrossReference);
		
		Common.MessageToUser(
			ErrorText,
			Document,
			CommonClientServer.PathToTabularSection("Goods", Selection.LineNumber, "PartnerProducts"),
			,
			Cancel);
		
	EndDo;
	
EndProcedure

// Fills in the partner item when the partner changes in the document
//
// Parameters:
//  Table - FormDataCollection, ValueTable - the table where you need to fill in the partner's item.
//  Partner - CatalogRef.Partners             - the partner that the item belongs to.
//
Procedure FillInPartnerProductListByProductNameWhenPartnerChanges(Table, Partner) Export

	If Not GetFunctionalOption("UsePartnersProducts") Or Table.Count() = 0 Then
		Return;
	EndIf;
	
	GoodsTable = CreateTableOfProductsToComparePartnerProducts(Table);
	QueryResult = ProductCrossReferencesMapping.ResultOfCounterpartyProductSearchQueryWhenOwnerChanges(Partner, GoodsTable);
	
	Selection = QueryResult.Select();
	
	For Each CurRow In Table Do
		
		If Selection.FindNext(CurRow.LineNumber, "LineNumber") Then
			CurRow.PartnerProducts = Selection.ProductCrossReference;
			Selection.Reset();
		Else
			CurRow.PartnerProducts = Catalogs.ProductCrossReferences.EmptyRef();
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the item partner's item list in the table part row.
//
// Parameters:
//  Partner              - CatalogRef.Partners - link partner.
//  CurrentRow        - Structure                 - data of the processed string.
//  StructureOfActions    - Structure                 - describes the steps.
//  CachedValues - Structure                 - saved values of parameters used during processing.
//
Procedure FillInPartnerProductNameByProductNameInTSLine(Partner, CurrentRow, StructureOfActions, CachedValues) Export
	
	Query = New Query;
	Query.SetParameter("Products", CurrentRow.Products);
	Query.SetParameter("Package"    , ?(CurrentRow.Package = Undefined, Catalogs.PackagesAndUnitsOfMeasure.EmptyRef(),CurrentRow.Package));
	
	QueryText = TextOfRequestToSearchForProductsOfDifferentQualityInTSLine();
	Query.Text = QueryText + "
	|SELECT
	|	CASE
	|		WHEN AnotherQualityGoods.Products IS NULL
	|			THEN &Products
	|		ELSE AnotherQualityGoods.Products
	|	END AS Products,
	|	CASE
	|		WHEN &Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN ISNULL(AnotherQualityGoods.UnitOfMeasure, CatalogProducts.UnitOfMeasure)
	|		ELSE ISNULL(AnotherQualityGoods.Package, &Package)
	|	END AS Package
	|FROM
	|	Catalog.Products AS CatalogProducts
	|		LEFT JOIN AnotherQualityGoods AS AnotherQualityGoods
	|		ON CatalogProducts.Ref = AnotherQualityGoods.OtherQualityGoods
	|WHERE
	|	CatalogProducts.Ref = &Products";
	
	Selection = Query.Execute().Select();
	
	InformationSecurityProducts = ProductCrossReferencesMappingClientServer.NewProductsForInformationBase();

	InformationSecurityProducts.Characteristic          = CurrentRow.Characteristic;
	InformationSecurityProducts.ProductCrossReference = CurrentRow.PartnerProducts;

	If Selection.Next() Then
		InformationSecurityProducts.Products = Selection.Products;
		InformationSecurityProducts.Package     = Selection.Package;
	EndIf;
	
	PartnerProducts = ProductCrossReferencesMapping.CounterpartyProductsByProductsInTableRow(Partner, InformationSecurityProducts);
	
	CurrentRow.PartnerProducts = PartnerProducts;

EndProcedure

// Fills in the item for the partner's item in the table part row.
//
// Parameters:
//  CurrentRow        - Structure - data of the processed string.
//  StructureOfActions    - Structure - describes the steps.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure FillInProductsByPartnerProductsInTSLine(CurrentRow, StructureOfActions, CachedValues) Export
	
	Query = New Query;
	Query.Text =  
	"SELECT ALLOWED
	|	PartnersProducts.Products AS Products,
	|	PartnersProducts.Characteristic AS Characteristic,
	|	PartnersProducts.Package AS Package,
	|	CASE
	|		WHEN PartnersProducts.Products.UseVariants IN
	|		(VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|			VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN PartnersProducts.Products <> &Products
	|		AND AnotherQualityGoods.Products IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS YouNeedToFillInProductList,
	|	CASE
	|		WHEN PartnersProducts.Characteristic <> &Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicsMustBeRefilled,
	|	CASE
	|		WHEN AnotherQualityGoods.OtherQualityGoods IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS InDocumentNomenclatureIsOfDifferentQuality,
	|	CatalogProducts.UnitOfMeasure AS BasicUnitOfProductMeasurementInDocument,
	|	AnotherQualityGoods.OtherQualityGoods AS OtherQualityGoods
	|INTO PartnerProducts
	|FROM
	|	Catalog.ProductCrossReferences AS PartnersProducts
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|			LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|			ON CatalogProducts.Ref = AnotherQualityGoods.OtherQualityGoods
	|		ON CatalogProducts.Ref = &Products
	|WHERE
	|	PartnersProducts.Ref = &PartnerProducts
	|	AND PartnersProducts.Products <> VALUE(Catalog.Products.EmptyRef)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MAX(PackingUnitsSearch.Ref) AS PackagingOfDefectiveGoods,
	|	PackagesAndUnitsOfMeasure.Ref AS PartnerProductPackaging
	|INTO PackagingOfDefectiveGoodsInDocument
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingUnitsSearch
	|		ON PackagesAndUnitsOfMeasure.Description = PackingUnitsSearch.Description
	|		AND PackingUnitsSearch.Owner = &Products
	|		AND
	|		NOT PackingUnitsSearch.DeletionMark
	|		AND ISNULL(&RequestTextForPackingCoefficient, 1) = ISNULL(&SearchQueryTextForPackingFactor, 1)
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			PartnerProducts AS PartnerProducts
	|		WHERE
	|			PartnerProducts.Package = PackagesAndUnitsOfMeasure.Ref)
	|GROUP BY
	|	PackagesAndUnitsOfMeasure.Ref
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|			THEN PartnerProducts.OtherQualityGoods
	|		ELSE PartnerProducts.Products
	|	END AS Products,
	|	PartnerProducts.Characteristic AS Characteristic,
	|	CASE
	|		WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|		AND PartnerProducts.Package.Owner <> VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|			THEN PackagingOfDefectiveGoodsInDocument.PackagingOfDefectiveGoods
	|		ELSE PartnerProducts.Package
	|	END AS Package,
	|	PartnerProducts.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	PartnerProducts.YouNeedToFillInProductList AS YouNeedToFillInProductList,
	|	PartnerProducts.CharacteristicsMustBeRefilled AS CharacteristicsMustBeRefilled,
	|	CASE
	|		WHEN PartnerProducts.Package.Owner <> VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|			THEN CASE
	|				WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|					THEN CASE
	|						WHEN PartnerProducts.Package <> &Package
	|						AND PartnerProducts.Package <> PackagingOfDefectiveGoodsInDocument.PackagingOfDefectiveGoods
	|							THEN TRUE
	|						ELSE FALSE
	|					END
	|				ELSE CASE
	|					WHEN PartnerProducts.Package <> &Package
	|						THEN TRUE
	|					ELSE FALSE
	|				END
	|			END
	|		ELSE CASE
	|			WHEN PartnerProducts.Package <> PartnerProducts.BasicUnitOfProductMeasurementInDocument
	|			OR &Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN TRUE
	|			ELSE FALSE
	|		END
	|	END AS NeedToReFillPackages
	|FROM
	|	PartnerProducts AS PartnerProducts
	|		LEFT JOIN PackagingOfDefectiveGoodsInDocument AS PackagingOfDefectiveGoodsInDocument
	|		ON PartnerProducts.Package = PackagingOfDefectiveGoodsInDocument.PartnerProductPackaging";
	
	Query.SetParameter("PartnerProducts", CurrentRow.PartnerProducts);
	Query.SetParameter("Products"        , CurrentRow.Products);
	Query.SetParameter("Characteristic"      , CurrentRow.Characteristic);
	Query.SetParameter("Package"            , CurrentRow.Package);
	
	Query.Text = StrReplace(Query.Text, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));
		
	Query.Text = StrReplace(Query.Text, "&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackingUnitsSearch", "PackingUnitsSearch.Owner"));
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		If Selection.YouNeedToFillInProductList Then
			CurrentRow.Products   = Selection.Products;
		EndIf;
		If Selection.CharacteristicsMustBeRefilled Then
			CurrentRow.Characteristic = Selection.Characteristic;
			If StructureOfActions.Property("CheckCharacteristicsByOwner") Then
				StructureOfActions.Insert("CheckCharacteristicsByOwner", Selection.Characteristic);
			EndIf;
			CurrentRow.ItemVariantsAreUsed = Selection.ItemVariantsAreUsed;
		EndIf;
		If Selection.NeedToReFillPackages Then
			CurrentRow.Package = Selection.Package;
			If StructureOfActions.Property("CheckFillPackageByOwner") Then
				StructureOfActions.Insert("CheckFillPackageByOwner", Selection.Package);
			EndIf;
		EndIf;
		
	EndIf;
		
EndProcedure

// Fills in an item, characteristic, or package in the partner's item with an empty item in the comparison.
//
// Parameters:
//  Goods - ValueTable - a table containing data for linking an item to a partner item.
//  Cancel  - Boolean - True if the item could not be linked to the supplier's item.
//
Procedure FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel) Export

	If Not GetFunctionalOption("UsePartnersProducts") Then
		Return;
	EndIf;
	
	TableOfGoods = Goods.Unload(,"PartnerProducts,Products,Characteristic,Package");
	
	ProductCrossReferencesMapping.FillInEmptyMappingInCounterpartySProductNameForInformationSecurityProductName(TableOfGoods, Cancel);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.TextOfSearchRequestForUnmappedProductListOfCounterpartiesForInformationSecurityProductList
Procedure TextOfSearchRequestForUnmappedProductListOfCounterpartiesForInformationSecurityProductList(QueryText, Val DefaultProductTable) Export
	
	If Not DefaultProductTable Then
		
		QueryText = 
		"SELECT
		|	Goods.PartnerProducts AS ProductCrossReference,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|WHERE
		|	Goods.Products <> VALUE(Catalog.Products.EmptyRef)
		|	AND Goods.PartnerProducts <> VALUE(Catalog.ProductCrossReferences.EmptyRef)";
		
		QueryText = QueryText + Common.QueryBatchSeparator();
		
	EndIf;
	
	QueryText = QueryText +
	"SELECT ALLOWED
	|	Goods.ProductCrossReference AS ProductCrossReference,
	|	CASE
	|		WHEN NOT AnotherQualityGoods.Products IS NULL
	|			THEN AnotherQualityGoods.Products
	|		ELSE Goods.Products
	|	END AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CatalogProducts.UnitOfMeasure
	|		ELSE Goods.Package
	|	END AS Package,
	|	CASE
	|		WHEN NOT AnotherQualityGoods.Products IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDifferentQualityProduct,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS BasicPackaging
	|INTO TemporaryTable_Products
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON Goods.Products = AnotherQualityGoods.OtherQualityGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		INNER JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON Goods.ProductCrossReference = ProductCrossReferences.Ref
	|WHERE
	|	ProductCrossReferences.Products = &EmptyItemList
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTable_Products.ProductCrossReference AS ProductCrossReference,
	|	TemporaryTable_Products.Products AS Products,
	|	TemporaryTable_Products.Characteristic AS Characteristic,
	|	MAX(ISNULL(PackagesAndUnitsOfMeasure.Ref, TemporaryTable_Products.Package)) AS Package
	|FROM
	|	TemporaryTable_Products AS TemporaryTable_Products
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (TemporaryTable_Products.ThisIsDifferentQualityProduct)
	|		AND (NOT TemporaryTable_Products.BasicPackaging)
	|		AND TemporaryTable_Products.Package.Description = PackagesAndUnitsOfMeasure.Description
	|		AND (ISNULL(&RequestTextForPackingCoefficient, 1) = ISNULL(&SearchQueryTextForPackingFactor, 1))
	|		AND TemporaryTable_Products.Products = PackagesAndUnitsOfMeasure.Owner
	|GROUP BY
	|	TemporaryTable_Products.ProductCrossReference,
	|	TemporaryTable_Products.Products,
	|	TemporaryTable_Products.Characteristic";
	
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("TemporaryTable_Products.Package", "TemporaryTable_Products.Products"));
		
	QueryText = StrReplace(QueryText, "&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));
		
EndProcedure

// Fills in the item partner's item list in the table.
//
// Parameters:
//  Goods  -ValueTable            - a table containing data for linking an item to a partner item.
//  Partner - CatalogRef.Partners - link partner.
//
Procedure FillInPartnerProductsByProductsInTable(Goods, Partner) Export

	If Not GetFunctionalOption("UsePartnersProducts") Or Goods.Count() = 0 Then
		Return;
	EndIf;
	
	GoodsTable = CreateTableOfProductsToComparePartnerProducts(Goods);
	QueryResult = ProductCrossReferencesMapping.ResultOfSearchQueryForCounterpartyProductsByInformationSecurityProducts(Partner, GoodsTable);

	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	
	For Each CurRow In Goods Do
		
		If Selection.FindNext(CurRow.LineNumber, "LineNumber") Then
			CurRow.PartnerProducts = Selection.ProductCrossReference;
			Selection.Reset();
		EndIf;
		
	EndDo;
	
EndProcedure


// See ProductCrossReferencesMappingOverridable.RequestTextForCounterpartyProductSelectionList
Procedure RequestTextForCounterpartyProductSelectionList(Query) Export
		
	QueryText = TextOfRequestToSearchForProductsOfDifferentQualityInTSLine();

	Query.Text = QueryText +
	"SELECT ALLOWED
	|	PartnersProducts.Ref AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS PartnersProducts
	|WHERE
	|	PartnersProducts.ItemOwner = &ItemOwner
	|	AND PartnersProducts.Products = &Products
	|	AND PartnersProducts.Characteristic = &Characteristic
	|	AND CASE
	|			WHEN &Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN PartnersProducts.Package = PartnersProducts.Products.UnitOfMeasure
	|			ELSE PartnersProducts.Package = &Package
	|		END
	|	AND NOT PartnersProducts.DeletionMark
	|	AND NOT PartnersProducts.Invalid
	|
	|UNION
	|
	|SELECT
	|	PartnersProducts.Ref
	|FROM
	|	Catalog.ProductCrossReferences AS PartnersProducts
	|WHERE
	|	PartnersProducts.ItemOwner = &ItemOwner
	|	AND PartnersProducts.Characteristic = &Characteristic
	|	AND (PartnersProducts.Products, PartnersProducts.Package) IN
	|			(SELECT
	|				AnotherQualityGoods.Products,
	|				CASE
	|					WHEN &Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|						THEN AnotherQualityGoods.UnitOfMeasure = PartnersProducts.Package
	|					ELSE AnotherQualityGoods.Package = PartnersProducts.Package
	|				END
	|			FROM
	|				AnotherQualityGoods AS AnotherQualityGoods)
	|	AND NOT PartnersProducts.DeletionMark
	|	AND NOT PartnersProducts.Invalid";
	
EndProcedure

#EndRegion

#Region RedefiningCounterpartyProductCatalog

// See ProductCrossReferencesMappingOverridable.WhenCreatingCounterpartyProductGroupFormOnServer
Procedure WhenCreatingCounterpartyProductGroupFormOnServer(Form, Cancel, StandardProcessing) Export
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(Form);
	// End StandardSubsystems.ObjectsVersioning
	
	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenCreatingListOfCounterpartyProductsOnServer_Form
Procedure WhenCreatingListOfCounterpartyProductsOnServer_Form(Form, Cancel, StandardProcessing) Export
	
	If Form.Parameters.Property("Filter")
		And Form.Parameters.Filter.Property("ItemOwner") Then
		Form.Parameters.Filter.Insert("Owner", Form.Parameters.Filter.ItemOwner);
	EndIf;
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(Form);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenReadingOnServer_FormOfCounterpartyProductItem
Procedure WhenReadingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject) Export
	
	ConfigurationModificationOverridable.OnReadAtServer(Form, CurrentObject);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.BeforeRecordingOnServer_FormOfCounterpartyProductItem
Procedure BeforeRecordingOnServer_FormOfCounterpartyProductItem(Form, Cancel, CurrentObject, WriteParameters) Export
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(Form, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(Form, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.AfterRecordingOnServer_FormOfCounterpartyProductItem
Procedure AfterRecordingOnServer_FormOfCounterpartyProductItem(Form, CurrentObject, WriteParameters) Export
	
	ConfigurationModificationOverridable.AfterWriteAtServer(Form, CurrentObject, WriteParameters);

EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenCreatingCounterpartyProductItemFormOn_Server
Procedure WhenCreatingCounterpartyProductItemFormOn_Server(Form, Cancel, StandardProcessing) Export
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(Form);
	// End StandardSubsystems.ObjectsVersioning
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(Form);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);

EndProcedure

// See ProductCrossReferencesMappingOverridable.ProcessingOfSelectionDataAcquisition_ProductListOfCounterparties
Procedure ProcessingOfSelectionDataAcquisition_ProductListOfCounterparties(ChoiceData, Parameters, StandardProcessing) Export
	
	If Parameters.Filter.Property("Products") Then
		Products = Parameters.Filter.Products;
		Parameters.Filter.Delete("Products");
	EndIf;
	
	If Parameters.Filter.Property("Characteristic") Then
		Characteristic = Parameters.Filter.Characteristic;
		Parameters.Filter.Delete("Characteristic");
	EndIf;
	
	If Parameters.Filter.Property("Package") Then
		Package = Parameters.Filter.Package;
		Parameters.Filter.Delete("Package");
	EndIf;
	
	If Parameters.Filter.Property("ItemOwner") Then
		ItemOwner = Parameters.Filter.ItemOwner;
	EndIf;
	
	If Parameters.Filter.Property("ItemsType")
		Or Parameters.Property("ItemsType") Then
		
		StandardProcessing = False;
		
		If Parameters.Filter.Property("ItemsType") Then
			ItemsType = Parameters.Filter.ItemsType;
		Else
			ItemsType = Parameters.ItemsType;
		EndIf;
		
	Else
		
		ItemsType = New Array();
		ItemsType.Add(Enums.ItemsTypes.OwnGoods);
		ItemsType.Add(Enums.ItemsTypes.ReusablePackage);
		ItemsType.Add(Enums.ItemsTypes.Work_5);
		ItemsType.Add(Enums.ItemsTypes.OperationService);		
		
	EndIf;
	
	SearchString = TrimAll(Parameters.SearchString);
	
	Query = New Query;
	QueryText = 
	"SELECT ALLOWED
	|	ProductCrossReferences.Ref AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferences
	|WHERE
	|	NOT ProductCrossReferences.DeletionMark
	|	AND ProductCrossReferences.Products.ItemsType IN(&ItemsType)
	|	AND (ProductCrossReferences.SKU LIKE &SearchString ESCAPE ""~""
	|			OR ProductCrossReferences.Code LIKE &SearchString ESCAPE ""~""
	|			OR ProductCrossReferences.Description LIKE &SearchString ESCAPE ""~"")
	|	AND NOT ProductCrossReferences.Invalid
	|	AND &OtherConditions";
	
	Query.SetParameter("ItemsType", ItemsType);
	Query.SetParameter("SearchString", Common.GenerateSearchQueryString(SearchString) + "%");
	
	OtherConditions = "True";
	ConditionPart = " AND ProductCrossReferences.%Parameter = &%Parameter";
	If ValueIsFilled(ItemOwner) Then
		Query.SetParameter("ItemOwner", ItemOwner);
		OtherConditions = OtherConditions + StrReplace(ConditionPart, "%Parameter", "ItemOwner");
	EndIf;
	If ValueIsFilled(Products) Then
		Query.SetParameter("Products", Products);
		OtherConditions = OtherConditions + StrReplace(ConditionPart, "%Parameter", "Products");
	EndIf;
	If ValueIsFilled(Characteristic) Then
		Query.SetParameter("Characteristic", Characteristic);
		OtherConditions = OtherConditions + StrReplace(ConditionPart, "%Parameter", "Characteristic");
	EndIf;
	If ValueIsFilled(Package) Then
		Query.SetParameter("Package", Package);
		OtherConditions = OtherConditions + StrReplace(ConditionPart, "%Parameter", "Package");
	EndIf;
	Query.Text = StrReplace(QueryText,"&OtherConditions", OtherConditions);
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenMatchingProductRangeChanges_CounterpartyProductRange
Procedure WhenMatchingProductRangeChanges_CounterpartyProductRange(Form, ComparisonData) Export
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner"   , ComparisonData.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", ComparisonData.Package);

	StructureOfActions.Insert("ProductsOnChangeOverridable", 
		New Structure("FormName, TabularSectionName",
		Form.FormName, "Object"));
		
	ComparisonData.Insert("ItemVariantsAreUsed", ComparisonData.UseCharacteristics);

	BatchProcessingOfTablePartServer.ProcessTSString(ComparisonData, StructureOfActions, Undefined);

	ComparisonData.UseCharacteristics = ComparisonData.ItemVariantsAreUsed;
	ComparisonData.Delete("ItemVariantsAreUsed");
	
	ComparisonData.DefaultUnitOfMeasurement = Catalogs.PackagesAndUnitsOfMeasure.ProductStorageUnit(ComparisonData.Products);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenCreatingOnServer_FormForSelectingProductListOfCounterparties
Procedure WhenCreatingOnServer_FormForSelectingProductListOfCounterparties(Form, Cancel, StandardProcessing) Export
	
	FormEvents.OnCreateAtServer(Form, Cancel, StandardProcessing);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(Form);
	// End IntegrationWith1CDocumentManagementSubsystem

EndProcedure

// See ProductCrossReferencesMappingOverridable.DynamicListRequestText_CounterpartyProductSelectionForm
Procedure DynamicListRequestText_CounterpartyProductSelectionForm(QueryText) Export
	
	QueryText =  
	"SELECT DISTINCT
	|	ProductCrossReferencesOverridable.Ref AS Ref,
	|	ProductCrossReferencesOverridable.DeletionMark AS DeletionMark,
	|	ProductCrossReferencesOverridable.Predefined AS Predefined,
	|	ProductCrossReferencesOverridable.ItemOwner AS ItemOwner,
	|	ProductCrossReferencesOverridable.Parent AS Parent,
	|	ProductCrossReferencesOverridable.IsFolder AS IsFolder,
	|	ProductCrossReferencesOverridable.Code AS Code,
	|	ProductCrossReferencesOverridable.Description AS Description,
	|	ProductCrossReferencesOverridable.Products AS Products,
	|	ProductCrossReferencesOverridable.Characteristic AS Characteristic,
	|	ProductCrossReferencesOverridable.Package AS Package,
	|	ProductCrossReferencesOverridable.SKU AS SKU,
	|	ProductCrossReferencesOverridable.Barcode AS Barcode,
	|	ProductCrossReferencesOverridable.VATRate AS VATRate,
	|	ProductCrossReferencesOverridable.ServiceItemID AS ServiceItemID,
	|	ProductCrossReferencesOverridable.ServiceVariantID AS ServiceVariantID,
	|	ProductCrossReferencesOverridable.ItemName AS ItemName,
	|	ProductCrossReferencesOverridable.ItemVariantName AS ItemVariantName,
	|	ProductCrossReferencesOverridable.PackageName AS PackageName,
	|	ProductCrossReferencesOverridable.BaseUnitOfMeasureDescription AS BaseUnitOfMeasureDescription,
	|	ProductCrossReferencesOverridable.BaseUnitOfMeasureARCMUCode AS BaseUnitOfMeasureARCMUCode,
	|	CASE
	|		WHEN ProductCrossReferencesOverridable.Products = &EmptyItemList
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheCounterpartySNomenclatureIsNotMatched,
	|	CASE
	|		WHEN &NomenclatureSelection <> &EmptyItemList
	|		AND (&NomenclatureSelection <> ProductCrossReferencesOverridable.Products
	|		AND ProductsOfDifferentQuality.Products IS NULL
	|		OR &FeatureSelection <> ProductCrossReferencesOverridable.Characteristic
	|		OR &PackagingSelection <> ProductCrossReferencesOverridable.Package
	|		AND ProductsOfDifferentQuality.Package IS NULL)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheCounterpartySNomenclatureDoesNotMatchTheSelection,
	|	CAST(CASE
	|		WHEN ProductCrossReferencesOverridable.Products = &EmptyItemList
	|			THEN &ToolTip1
	|		WHEN &NomenclatureSelection <> &EmptyItemList
	|		AND (&NomenclatureSelection <> ProductCrossReferencesOverridable.Products
	|		AND ProductsOfDifferentQuality.Products IS NULL
	|		OR &FeatureSelection <> ProductCrossReferencesOverridable.Characteristic
	|		OR &PackagingSelection <> ProductCrossReferencesOverridable.Package
	|		AND ProductsOfDifferentQuality.Package <> ProductCrossReferencesOverridable.Package)
	|			THEN &ToolTip2
	|		ELSE &ToolTip3
	|	END AS STRING(100)) AS ToolTip,
	|	(CASE
	|		WHEN (&NomenclatureSelection = ProductCrossReferencesOverridable.Products
	|		OR
	|		NOT ProductsOfDifferentQuality.Products IS NULL)
	|		AND &FeatureSelection = ProductCrossReferencesOverridable.Characteristic
	|		AND (&PackagingSelection = ProductCrossReferencesOverridable.Package
	|		OR ProductsOfDifferentQuality.Package = ProductCrossReferencesOverridable.Package)
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS TheCounterpartySNomenclatureIsFullyMatched,
	|	CASE
	|		WHEN (&NomenclatureSelection = ProductCrossReferencesOverridable.Products
	|		OR
	|		NOT ProductsOfDifferentQuality.Products IS NULL)
	|		AND &FeatureSelection = ProductCrossReferencesOverridable.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheCounterpartySNomenclatureIsMatchedByTheCharacteristicNomenclature
	|{WHERE
	|	(ProductCrossReferencesOverridable.Products = VALUE(Catalog.Products.EmptyRef)
	|	OR ProductCrossReferencesOverridable.Products.ItemsType IN (&ItemsTypes))}
	|FROM
	|	Catalog.ProductCrossReferences AS ProductCrossReferencesOverridable
	|		LEFT JOIN (SELECT
	|			AnotherQualityGoods.Products,
	|			MAX(PackingUnitsSearch.Ref) AS Package
	|		FROM
	|			InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|				LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingUnitsSearch
	|					INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|					ON PackingUnitsSearch.Description = PackagesAndUnitsOfMeasure.Description
	|					AND ISNULL(&SearchQueryTextForPackingFactor, 1) = ISNULL(&RequestTextForPackingCoefficient, 1)
	|					AND PackagesAndUnitsOfMeasure.Ref = &PackagingSelection
	|				ON AnotherQualityGoods.Products = PackingUnitsSearch.Owner
	|		WHERE
	|			AnotherQualityGoods.OtherQualityGoods = &NomenclatureSelection
	|		GROUP BY
	|			AnotherQualityGoods.Products) AS ProductsOfDifferentQuality
	|		ON ProductCrossReferencesOverridable.Products = ProductsOfDifferentQuality.Products
	|WHERE
	|	NOT ProductCrossReferencesOverridable.Invalid";
	
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));
		
	QueryText = StrReplace(QueryText, "&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackingUnitsSearch", "PackingUnitsSearch.Owner"));
		
EndProcedure

// See ProductCrossReferencesMappingOverridable.SetDynamicListParameters_CounterpartyProductSelectionForm
Procedure SetDynamicListParameters_CounterpartyProductSelectionForm(Parameters, List) Export
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("ItemOwner") Then
		Parameters.Filter.Insert("Owner", Parameters.Filter.ItemOwner);
	EndIf;
	
	If Parameters.Property("Filter") Then
	
		If Parameters.Filter.Property("ItemsType") Then
			
			If TypeOf(Parameters.Filter.ItemsType) = Type("EnumRef.ItemsTypes") Then
				FilterOfProductItem = New Array();
				FilterOfProductItem.Add(Parameters.Filter.ItemsType);
			ElsIf TypeOf(Parameters.Filter.ItemsType) = Type("FixedArray")
						Or TypeOf(Parameters.Filter.ItemsType) = Type("Array") Then
				FilterOfProductItem = Parameters.Filter.ItemsType;
			EndIf;
			
			List.Parameters.SetParameterValue("ItemsTypes", FilterOfProductItem);
			Parameters.Filter.Delete("ItemsType");
			
		EndIf;
		
	EndIf;
	
	If Parameters.Property("ItemsType") Then
		If TypeOf(Parameters.ItemsType) = Type("EnumRef.ItemsTypes") Then
			FilterOfProductItem = New Array();
			FilterOfProductItem.Add(Parameters.ItemsType);
		ElsIf TypeOf(Parameters.ItemsType) = Type("FixedArray") Then
			FilterOfProductItem = Parameters.ItemsType;
		ElsIf TypeOf(Parameters.ItemsType) = Type("ValueList") Then
			FilterOfProductItem = Parameters.ItemsType.UnloadValues();
		EndIf;
		If ValueIsFilled(FilterOfProductItem) Then
			List.Parameters.SetParameterValue("ItemsTypes", FilterOfProductItem);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region AccessManagement

// See ProductCrossReferencesMappingOverridable.WhenFillingInTypesOfRightsRestrictionsForMetadataObjects_ProductListOfCounterparties
Procedure WhenFillingInTypesOfRightsRestrictionsForMetadataObjects_ProductListOfCounterparties(LongDesc) Export
	
	LongDesc = LongDesc + "
	|Catalog.ProductCrossReferences.Read.PartnerGroups
	|Catalog.ProductCrossReferences.Update.PartnerGroups
	|";
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenFillingInAccessRestriction_ProductListOfCounterparties
Procedure WhenFillingInAccessRestriction_ProductListOfCounterparties(Restriction) Export
	
	Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	IsFolder OR
		|	ValueAllowed(ItemOwner)";
	
	Restriction.TextForExternalUsers1 = Restriction.Text;

EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenFillingInListsWithRestrictedAccess_ProductsOfCounterparties
Procedure WhenFillingInListsWithRestrictedAccess_ProductsOfCounterparties(Lists) Export
	
	Lists.Insert(Metadata.Catalogs.ProductCrossReferences, True);
	
EndProcedure

#EndRegion

#Region WorkingWithInformationSecurityData

// Returns the item reference for the partner item.
//
// Parameters:
//  PartnersProducts - CatalogRef.ProductCrossReferences - link to the partner's item list.
//
// Returns:
//  CatalogRef.Products - the link of the item.
//
Function FindLinkToProductsByPartnerProducts(PartnersProducts) Export
	
	Result = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	CatProducts.Products AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS CatProducts
	|WHERE
	|	CatProducts.Ref = &PartnersProducts";
	
	Query.SetParameter("PartnersProducts", PartnersProducts);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a link to the item by the partner item ID.
//
// Parameters:
//  Id - String - ID of the partner item.
//
// Returns:
//  CatalogRef.Products - the link of the item.
//
Function FindLinkToProductByPartnerProductID(Id) Export
	
	Result = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	CatProducts.Products AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS CatProducts
	|WHERE
	|	CatProducts.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a link by the ID of the partner item.
//
// Parameters:
//  Id - String - ID of the partner item.
//
// Returns:
//  CatalogRef.ProductCrossReferences - link to the partner's nomenclature.
//
Function FindLinkToPartnerSItemById(Id) Export
	
	Result = Undefined;
	
	Query = New Query;
	Query.Text = "SELECT ALLOWED
	|	CatProducts.Ref AS Ref
	|FROM
	|	Catalog.ProductCrossReferences AS CatProducts
	|WHERE
	|	CatProducts.Id = &Id";
	
	Query.SetParameter("Id", Id);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.Ref;
	EndIf;
	
	Return Result;
	
EndFunction

// See ProductCrossReferencesMappingOverridable.WhenDeterminingStructureOfProductOfInformationBase
Procedure WhenDeterminingStructureOfProductOfInformationBase(ProductStructure_) Export
	ProductStructure_.NameOfCharacteristicLinkParameter = "Products";
	ProductStructure_.NameOfPackageConnectionParameter       = "Products";
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenDeterminingOwnerOfCounterpartySProductList
Procedure WhenDeterminingOwnerOfCounterpartySProductList(Val Counterparty, Owner) Export
	If TMCommonUseClientServer.HasObjectAttribute(Counterparty, "Partner") Then
		Owner = Counterparty.Partner;
	Else
		Owner = Counterparty;
	EndIf;
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenDeterminingPropertiesOfInformationBaseProduct
Procedure WhenDeterminingPropertiesOfInformationBaseProduct(Val SetOfProducts, PropertiesOfInformationSecurityProducts) Export
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Products.Ref AS Products,
	|	ISNULL(ItemKinds.UseCharacteristics, FALSE) AS UseCharacteristics,
	|	Products.UseVariants AS UseVariants,
	|	Products.UsePackages AS UsePackages,
	|	Products.UnitOfMeasure AS DefaultUnitOfMeasurement
	|FROM
	|	Catalog.Products AS Products
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON Products.ProductKind = ItemKinds.Ref
	|WHERE
	|	Products.Ref IN(&SetOfProducts)";
	
	Query.SetParameter("SetOfProducts", SetOfProducts);
	QueryResult = Query.Execute();
	
	FOUseProductCharacteristics = GetFunctionalOption("UseItemVariants");
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		If Selection.UseVariants = Enums.ItemVariantsUsageOptions.DontUse Then
			UseCharacteristics = False;
		Else
			ProductTypeAndCharacteristics = Selection.UseCharacteristics;
			UseCharacteristics = FOUseProductCharacteristics And ProductTypeAndCharacteristics;
		EndIf;
		UsePackages        = Selection.UsePackages;
		DefaultUnitOfMeasurement = Selection.DefaultUnitOfMeasurement;
		
		ProductProperties_ = ProductCrossReferencesMappingClientServer.NewPropertiesOfInformationSecurityProducts();
		ProductProperties_.Insert("UseCharacteristics"          , UseCharacteristics);
		ProductProperties_.Insert("UsePackages"                , UsePackages);
		ProductProperties_.Insert("DefaultUnitOfMeasurement"         , DefaultUnitOfMeasurement);

		PropertiesOfInformationSecurityProducts.Insert(Selection.Products, ProductProperties_);
		
	EndDo;
EndProcedure


// See ProductCrossReferencesMappingOverridable.WhenDeterminingBarcodesOfCounterpartySProductRange
Procedure WhenDeterminingBarcodesOfCounterpartySProductRange(Val InformationSecurityProducts, Barcode, OtherProductsBarcodes) Export
	
		If InformationSecurityProducts.Package = Catalogs.PackagesAndUnitsOfMeasure.ProductStorageUnit(InformationSecurityProducts.Products) Then
			Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
		Else
			Package = InformationSecurityProducts.Package;
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Products", InformationSecurityProducts.Products);
		Query.SetParameter("Characteristic", InformationSecurityProducts.Characteristic);
		Query.SetParameter("Package", Package);
		Query.Text = TextOfBarCodeSearchRequestForProductLine();
		
		ResultOfPackages = Query.ExecuteBatch();
		
		FetchingCombinationBarcode = ResultOfPackages[1].Select();
		If FetchingCombinationBarcode.Next() Then
			Barcode = FetchingCombinationBarcode.Barcode;
		EndIf;
		
		
		SamplingProductBarcodes = ResultOfPackages[2].Select();
		While SamplingProductBarcodes.Next() Do
			OtherProductsBarcodes.Add(SamplingProductBarcodes.Barcode);
		EndDo;
		
EndProcedure

#EndRegion

#Region WorkingWithUnitsOfMeasurement

// See ProductCrossReferencesMappingOverridable.FindUnitNameByOkeyCode
Procedure FindUnitNameByOkeyCode(OceaniaUnitCode, UnitOfMeasureDescription) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PackagesAndUnitsOfMeasure.Description AS Description,
	|	PackagesAndUnitsOfMeasure.MeasuredValueType
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Code = &Code
	|	AND
	|	NOT PackagesAndUnitsOfMeasure.DeletionMark
	|	AND PackagesAndUnitsOfMeasure.Owner = VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)";
	
	Query.SetParameter("Code", OceaniaUnitCode);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		UnitOfMeasureDescription = "";
		Return;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		
		UnitOfMeasureDescription = Selection.Description;
		
	EndIf;
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.BasicUnitOfProductMeasurement
Procedure BasicUnitOfProductMeasurement(Val Products, UnitOfMeasure) Export

	UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.ProductStorageUnit(Products);
	
EndProcedure

// See ProductCrossReferencesMappingOverridable.PackageOwnerUnitsOfMeasurementProducts
Procedure PackageOwnerUnitsOfMeasurementProducts(Val Package, PackagingOwnerProductRange) Export
	Query = New Query;
	Query.SetParameter("Ref", Package);
	Query.Text =
	"SELECT
	|	PackagesAndUnitsOfMeasure.Description
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Owner REFS Catalog.Products
	|	AND PackagesAndUnitsOfMeasure.Ref = &Ref";
	
	QueryResult = Query.Execute();
	
	PackagingOwnerProductRange = Not QueryResult.IsEmpty();
EndProcedure

// See ProductCrossReferencesMappingOverridable.WhenDeterminingPropertiesOfPackagingUnitsOfMeasurementOfNomenclature
Procedure WhenDeterminingPropertiesOfPackagingUnitsOfMeasurementOfNomenclature(Val Package, Val Products, PackingProperties) Export
	
	Query = New Query;
	Query.SetParameter("Package", Package);
	Query.SetParameter("Products", Products);
	QueryText =
	"SELECT
	|	Products.UnitOfMeasure.Description AS BaseUnitOfMeasureDescription,
	|	Products.UnitOfMeasure.Code AS BaseUnitOfMeasureARCMUCode,
	|	PackagesAndUnitsOfMeasure.Description AS PackageName,
	|	ISNULL(&RequestTextForPackingCoefficient, 1) AS QuantityInBaseUnitOfMeasure,
	|	1 AS NumberOfPackages
	|FROM
	|	Catalog.Products AS Products
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON PackagesAndUnitsOfMeasure.Ref = &Package
	|WHERE
	|	Products.Ref = &Products";

	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));

	Query.Text = QueryText;
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		FillPropertyValues(PackingProperties, Selection);
	EndDo;

EndProcedure

#EndRegion

#Region FillingOutFormsBasedOnProductListOfCounterparties


// See ProductCrossReferencesMappingOverridable.WhenDefiningPresentationsOfProductCollation
Procedure WhenDefiningPresentationsOfProductCollation(Presentations) Export
	Presentations.FeaturePresentationOfObject = NStr("vi = 'Đặc tính';
													|ru = 'Характеристика';
													|en = 'Variant'; fa = 'گونه';
													|it = 'Caratteristica';
													|pl = 'Variant';
													|tr = 'Varyant'");

	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		Presentations.ProductsAndListPresentation  = NStr("vi = 'Mặt hàng của bạn hàng';
															|ru = 'Номенклатура партнеров';
															|en = 'Partners products'; fa = 'محصولات شرکای تجاری';
															|it = 'Articoli del partner';
															|pl = 'Pozycja partnerów';
															|tr = 'İş ortağı öğesi'");
		Presentations.ItemProductsAndPresentation = NStr("vi = 'Mặt hàng của bạn hàng';
														|ru = 'Номенклатура партнера';
														|en = 'Partner products'; fa = 'کالاهای شرکا';
														|it = 'Articoli del partner';
														|pl = 'Pozycja partnera';
														|tr = 'İş ortağı ürünleri'");
		Presentations.OwnerOfProductItemPresentation    = NStr("vi = 'Bạn hàng';
																|ru = 'Партнер';
																|en = 'Partner'; fa = 'شریک تجاری';
																|it = 'Partner';
																|pl = 'Partner';
																|tr = 'İş ortağı'");
		Presentations.OwnerOfProductInGenitiveCase      = NStr("vi = 'Bạn hàng';
																|ru = 'Партнера';
																|en = 'Partner'; fa = 'شریک تجاری';
																|it = 'Del partner';
																|pl = 'Partner';
																|tr = 'İş ortağının'");
		
	Else
		Presentations.OwnerOfProductItemPresentation = NStr("vi = 'Đối tác';
															|ru = 'Контрагент';
															|en = 'Counterparty'; fa = 'طرف حساب';
															|it = 'Controparte';
															|pl = 'Counterparty';
															|tr = 'Cari hesap'");
		Presentations.OwnerOfProductInGenitiveCase   = NStr("vi = 'Đối tác';
															|ru = 'Контрагента';
															|en = 'Counterparty'; fa = 'طرف حساب';
															|it = 'Della controparte';
															|pl = 'Counterparty';
															|tr = 'Cari hesabın'");
	EndIf;
EndProcedure

#EndRegion


#Region WorkingWithInformationSecurityBarcodes

// Initializes the text of the search query for combination barcodes and item barcodes in the "Products" table part of the document
// that has columns: Nomenclature, Characteristics, And Packaging.
// The query uses temporary table "Uttara", which should contain columns: Nomenclature, Characteristics, And Packaging.
// If you don't have your own temporary table, you must fill in the "document Name" parameter and set the "Link"parameter in the request.
// 
// Parameters:
//  QueryText    - String - text of the barcode search query based on the data in the table part of the document.
//  DocumentName    - String - the name of the metadata object of the document in which there is a tabular part "Products" with columns:
//                             Nomenclature, Characteristics, Packaging.
//  LotsOfLinks - Boolean - indicates whether to search for barcodes using multiple document links.
//
Procedure InitializingTextOfBarcodeSearchQueryInTemporaryProductTable(
		QueryText, Val DocumentName = Undefined, Val LotsOfLinks = False) Export
		
	RequestPackages = New Array;
	RequestPackages.Add(QueryText);
		
	If DocumentName <> Undefined Then
		QueryText = "SELECT ALLOWED
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	&Package AS Package
		|INTO TT_Goods
		|FROM
		|	&TS AS Goods
		|WHERE
		|	&LinkCondition_1
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Package";
		
		QueryText = StrReplace(QueryText, "&LinkCondition_1", ?(LotsOfLinks, "Goods.Ref IN (&Ref)", "Goods.Ref = &Ref"));
		
		If DocumentName = "CustomerInvoiceServices" Then
			QueryText = StrReplace(QueryText, "&TS", "Document." + DocumentName + ".Services");
			QueryText = StrReplace(QueryText, "&Package", "Value(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		ElsIf DocumentName = "IssuedTaxInvoicePrepayment" Then
			QueryText = StrReplace(QueryText, "&TS", "Document." + DocumentName + ".Prepayments");
			QueryText = StrReplace(QueryText, "&Package", "Value(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
		Else
			QueryText = StrReplace(QueryText, "&TS", "Document." + DocumentName + ".Goods");
			QueryText = StrReplace(QueryText, "&Package", "Goods.Package");		
		EndIf;
		
		RequestPackages.Add(QueryText);
	EndIf;
	
	QueryText = TextOfBarCodeSearchQueryForProductTable();
	
	RequestPackages.Add(QueryText);

	QueryText = StrConcat(RequestPackages, Common.QueryBatchSeparator());
	
EndProcedure


// Adds to the structure the field barcodes of the nomenclature And barcodes Of the combination in the comparison of the BAD nomenclature.
//
// Parameters:
//  Comparison_         - Structure        - comparison of the BAD nomenclature.
//  ItemsBarcodes - Array of String - a set of item barcodes.
//  CombinationBarcodes_   - Array of String - a set of barcodes for a combination of lines: nomenclature, characteristics, packaging.
//  InformationSecurityProducts        - DefinedType.EDLProducts               - link to the item.
//  CharacteristicsOfIB      - DefinedType.ItemsCharacteristicEDL - Link to the characteristic.
//  UnitOfMeasurementIB    - DefinedType.PackageEDLItems       - reference to the unit of measurement / package.
//
Procedure FillInProductBarcodesInMapping(Comparison_, ItemsBarcodes, CombinationBarcodes_,
		InformationSecurityProducts, CharacteristicsOfIB, UnitOfMeasurementIB) Export

	DisplayBasicUnitsOfMeasureInPrintForms = Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get();
		
	ProductBarcodes_ = New Array;
	SelectingBarcodes = New Structure;
	SelectingBarcodes.Insert("Products", InformationSecurityProducts);
	FoundBarcodeStrings = ItemsBarcodes.FindRows(SelectingBarcodes);
	For Each BarcodeString_ In FoundBarcodeStrings Do
		ProductBarcodes_.Add(BarcodeString_.Barcode);
	EndDo;
	Comparison_.Insert("ItemsBarcodes", ProductBarcodes_);
	
	SelectingBarcodes = New Structure;
	SelectingBarcodes.Insert("Products"    , InformationSecurityProducts);
	SelectingBarcodes.Insert("Characteristic"  , CharacteristicsOfIB);
	If DisplayBasicUnitsOfMeasureInPrintForms Then
		UnitOfMeasurementIB = InformationSecurityProducts.UnitOfMeasure;
	EndIf;
	If UnitOfMeasurementIB <> ProductsServerCall.ProductStorageUnit(InformationSecurityProducts) Then
		SelectingBarcodes.Insert("Package", UnitOfMeasurementIB);
	EndIf;
	SearchString = CombinationBarcodes_.FindRows(SelectingBarcodes);
	If ValueIsFilled(SearchString) Then
		Comparison_.Insert("CombinationBarcode", SearchString[0].Barcode);
	EndIf;
	
EndProcedure

// Gets barcodes of the item and combination (item, characteristic, packaging) for a set of products.
//
// Parameters:
//  SetOfProducts_          - QueryResultSelection - selection of products from the tabular part of the document.
//  CombinationBarcodes_   - Array of String           - a set of combination barcodes: nomenclature, characteristic, packaging.
//  ItemsBarcodes - Array of String           - a set of item barcodes.
//
Procedure ProductBarcodes(SetOfProducts_, CombinationBarcodes_, ItemsBarcodes) Export
	
	Goods = New ValueTable;
	Goods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	Goods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	ProductSetType = TypeOf(SetOfProducts_);

	DisplayBasicUnitsOfMeasureInPrintForms = Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get();
	
	If ProductSetType = Type("QueryResultSelection") Then
		SetOfProducts_.Reset();
		While SetOfProducts_.Next() Do
			RowOfProduct = Goods.Add();
			FillPropertyValues(RowOfProduct, SetOfProducts_);

			DocumentSalesOfGoodsAndServices = SetOfProducts_.Ref;
			
			If TypeOf(DocumentSalesOfGoodsAndServices) = Type("DocumentRef.CustomerInvoice") 
					Or TypeOf(DocumentSalesOfGoodsAndServices) = Type("DocumentRef.SaleAdjustment") Then
				
				Goods = Common.ObjectAttributeValue(DocumentSalesOfGoodsAndServices, "Goods");
				Goods = ?(TypeOf(Goods) = Type("QueryResult"), Goods.Unload(), Goods);
				
				If SetOfProducts_.LineNumber <> Null And ValueIsFilled(Goods) And Goods.Count() >= SetOfProducts_.LineNumber Then
					If SetOfProducts_.LineNumber > 0 Then
						TabSectionRow = Goods[SetOfProducts_.LineNumber - 1];
					Else
						TabSectionRow = Goods[SetOfProducts_.LineNumber];
					EndIf;	
					PackagingFromDocument = TabSectionRow.Package;
				Else
					PackagingFromDocument = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				EndIf;
				
			EndIf;
			If DisplayBasicUnitsOfMeasureInPrintForms Then
				RowOfProduct.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();				
			Else 
				RowOfProduct.Package = PackagingFromDocument;
			EndIf;
		EndDo;
		SetOfProducts_.Reset();
	Else
		For Each OwnGoods In SetOfProducts_ Do
			RowOfProduct = Goods.Add();
			FillPropertyValues(RowOfProduct, OwnGoods);
		EndDo;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("Goods", Goods);
	Query.Text = 
	"SELECT DISTINCT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package
	|INTO TT_Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package";
	
	InitializingTextOfBarcodeSearchQueryInTemporaryProductTable(Query.Text);
	
	RequestPackages = Query.ExecuteBatch();
	
	CombinationBarcodes_ = RequestPackages[2].Unload();
	CombinationBarcodes_.Indexes.Add("Products, Characteristic, Package");

	ItemsBarcodes = RequestPackages[3].Unload();
	ItemsBarcodes.Indexes.Add("Products");
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTableParts

// Adds a request to the request package to get the data needed to fill in the partner item.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInPartnerSItemItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInProductNameOfProductPartner",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		ListOfRequests = QueryTextsFillInPartnerItemsBatchProcessing(CachedValues);
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		// Instead of the link "True", if the partner in the table
		QueryDetails.QueryOptions.Insert("OwnerOfPartnerItem", ActionParameters); 
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to fill in the item according to the partner's item.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextAndFillInItemAccordingToPartnerSItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
		"FillInTheItemByThePartnerSItem",
		StructureOfActions,
		CachedValues,
		ActionParameters) Then
		
		ListOfRequests = QueryTextsFillInItemAccordingToPartnerSItem();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

// Adds a request to the request package to get the data needed to verify the matched partner item.
//
// Parameters:
//  StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues
//  QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails
//  CachedValues - Structure
//
Procedure CompleteQueryTextCheckMatchedPartnerItem(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If GetFunctionalOption("UsePartnersProducts")
		And BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckMatchedPartnerProducts",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsCheckMatchedPartnerItem();
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
		QueryDetails.QueryOptions.Insert("OwnerOfPartnerItem", ActionParameters.Partner);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private


Function CreateTableOfProductsToComparePartnerProducts(Table)
	
	Query = New Query;
	
	If TypeOf(Table) = Type("FormDataCollection") Then
		If Table[0].Property("Package") Then
			Query.SetParameter("Goods", Table.Unload(, "LineNumber,Products,Characteristic,Package,PartnerProducts"));
		Else
			TableOfGoods =  Table.Unload(, "LineNumber,Products,Characteristic,PartnerProducts");
			TableOfGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
			Query.SetParameter("Goods", TableOfGoods);			
		EndIf;
	Else
		Query.SetParameter("Goods", Table);
	EndIf;
	
	QueryText=
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.PartnerProducts AS PartnerProducts
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Goods.LineNumber AS LineNumber,
	|	Goods.PartnerProducts AS ProductCrossReference,
	|	Goods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN NOT AnotherQualityGoods.Products IS NULL
	|			THEN AnotherQualityGoods.Products
	|		ELSE Goods.Products
	|	END AS Products,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CatalogProducts.UnitOfMeasure
	|		ELSE Goods.Package
	|	END AS Package,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN CatalogProducts.UnitOfMeasure.Description
	|		ELSE CAST(Goods.Package AS Catalog.PackagesAndUnitsOfMeasure).Description
	|	END AS PackageName,
	|	CASE
	|		WHEN NOT AnotherQualityGoods.Products IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsDifferentQualityProduct,
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS BasicPackaging
	|INTO TemporaryTable_Products
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON Goods.Products = AnotherQualityGoods.OtherQualityGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTable_Products.LineNumber AS LineNumber,
	|	TemporaryTable_Products.ProductCrossReference AS ProductCrossReference,
	|	TemporaryTable_Products.Products AS Products,
	|	TemporaryTable_Products.Characteristic AS Characteristic,
	|	MAX(ISNULL(PackagesAndUnitsOfMeasure.Ref, TemporaryTable_Products.Package)) AS Package
	|FROM
	|	TemporaryTable_Products AS TemporaryTable_Products
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON (TemporaryTable_Products.ThisIsDifferentQualityProduct)
	|		AND (NOT TemporaryTable_Products.BasicPackaging)
	|		AND TemporaryTable_Products.PackageName = PackagesAndUnitsOfMeasure.Description
	|		AND (ISNULL(&RequestTextForPackingCoefficient, 1) = ISNULL(&SearchQueryTextForPackingFactor, 1))
	|		AND TemporaryTable_Products.Products = PackagesAndUnitsOfMeasure.Owner
	|GROUP BY
	|	TemporaryTable_Products.LineNumber,
	|	TemporaryTable_Products.ProductCrossReference,
	|	TemporaryTable_Products.Products,
	|	TemporaryTable_Products.Characteristic";
	
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("TemporaryTable_Products.Package", "TemporaryTable_Products.Products"));
		
	QueryText = StrReplace(QueryText, "&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));
	
	Query.Text = QueryText;
	
	Return Query.Execute().Unload();

EndFunction

Function TextOfRequestToSearchForProductsOfDifferentQualityInTSLine(Val PutInTemporaryTable = True)
	
	QueryText = 
	"SELECT ALLOWED
	|	AnotherQualityGoods.Products,
	|	AnotherQualityGoods.Products.UnitOfMeasure AS UnitOfMeasure,
	|	MAX(PackingUnitsSearch.Ref) AS Package,
	|	AnotherQualityGoods.OtherQualityGoods
	|INTO AnotherQualityGoods
	|FROM
	|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingUnitsSearch
	|			INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|			ON CASE
	|				WHEN &Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|					THEN PackingUnitsSearch.Description = PackagesAndUnitsOfMeasure.Description
	|					AND PackagesAndUnitsOfMeasure.Ref = &Package
	|					AND ISNULL(&SearchQueryTextForPackingFactor, 1) = ISNULL(&RequestTextForPackingCoefficient, 1)
	|				ELSE FALSE
	|			END
	|		ON AnotherQualityGoods.Products = PackingUnitsSearch.Owner
	|WHERE
	|	AnotherQualityGoods.OtherQualityGoods = &Products
	|GROUP BY
	|	AnotherQualityGoods.Products,
	|	AnotherQualityGoods.Products.UnitOfMeasure,
	|	AnotherQualityGoods.OtherQualityGoods";
	
	QueryText = StrReplace(QueryText, "&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackagesAndUnitsOfMeasure", "PackagesAndUnitsOfMeasure.Owner"));
		
	QueryText = StrReplace(QueryText, "&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("PackingUnitsSearch", "PackingUnitsSearch.Owner"));
	
	If PutInTemporaryTable Then
		QueryText = QueryText + Common.QueryBatchSeparator();
	Else
		QueryText = StrReplace(QueryText, "INTO AnotherQualityGoods", "");
	EndIf;
	
	Return QueryText;

EndFunction

Function TextOfBarCodeSearchQueryForProductTable(NameOfTemporaryProductTable = Undefined)
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Barcodes.Barcode AS Barcode,
	|	Barcodes.Products AS Products,
	|	Barcodes.Characteristic AS Characteristic,
	|	Barcodes.Package AS Package
	|INTO ListOfBarcodesByCombination
	|FROM
	|	InformationRegister.ItemsBarcodes AS Barcodes
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON (TT_Goods.Products = Barcodes.Products)
	|		AND (TT_Goods.Characteristic = Barcodes.Characteristic)
	|		AND (TT_Goods.Package = Barcodes.Package)
	|
	|INDEX BY
	|	Barcode,
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CombinationBarcodes.Barcode AS Barcode,
	|	CombinationBarcodes.Products AS Products,
	|	CombinationBarcodes.Characteristic AS Characteristic,
	|	CombinationBarcodes.Package AS Package
	|FROM
	|	ListOfBarcodesByCombination AS CombinationBarcodes
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	Barcodes.Barcode AS Barcode,
	|	Barcodes.Products AS Products
	|FROM
	|	InformationRegister.ItemsBarcodes AS Barcodes
	|		INNER JOIN TT_Goods AS TT_Goods
	|		ON TT_Goods.Products = Barcodes.Products";
	
	If NameOfTemporaryProductTable <> Undefined Then
		QueryText = StrReplace(QueryText, "TT_Goods", NameOfTemporaryProductTable);
	EndIf;
	
	Return QueryText;

EndFunction

Function TextOfBarCodeSearchRequestForProductLine()
	
	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Barcodes.Barcode AS Barcode,
	|	Barcodes.Products AS Products,
	|	Barcodes.Characteristic AS Characteristic,
	|	Barcodes.Package AS Package
	|INTO ListOfBarcodesByCombination
	|FROM
	|	InformationRegister.ItemsBarcodes AS Barcodes
	|
	|WHERE
	|		Barcodes.Products = &Products
	|		AND Barcodes.Characteristic = &Characteristic
	|		AND Barcodes.Package = &Package
	|
	|INDEX BY
	|	Barcode,
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CombinationBarcodes.Barcode AS Barcode,
	|	CombinationBarcodes.Products AS Products,
	|	CombinationBarcodes.Characteristic AS Characteristic,
	|	CombinationBarcodes.Package AS Package
	|FROM
	|	ListOfBarcodesByCombination AS CombinationBarcodes
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			ListOfBarcodesByCombination AS ListOfBarcodesByCombination
	|		WHERE
	|			ListOfBarcodesByCombination.Products = CombinationBarcodes.Products
	|			AND ListOfBarcodesByCombination.Characteristic = CombinationBarcodes.Characteristic
	|			AND ListOfBarcodesByCombination.Package = CombinationBarcodes.Package
	|		HAVING
	|			COUNT(DISTINCT ListOfBarcodesByCombination.Barcode) = 1)
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED DISTINCT
	|	Barcodes.Barcode AS Barcode,
	|	Barcodes.Products AS Products
	|FROM
	|	InformationRegister.ItemsBarcodes AS Barcodes
	|WHERE
	|		Barcodes.Products = &Products";
		
	Return QueryText;

EndFunction

#Region BatchProcessingOfTablePartsIsService

// Returns a list of requests to get the partner item.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsFillInPartnerItemsBatchProcessing(CachedValues)
	
	Result = New ValueList;
	
	QueryText = 
	"SELECT ALLOWED
	|	TTDataSource.IdOfTTRow                                                       AS IdOfTTRow,
	|	&PartnerField                                                                                 AS Partner,
	|	TTDataSource.PartnerProducts                                                        AS PartnerSItemListIsOriginalOne,
	|	TTDataSource.Products                                                                AS SourceProducts_,
	|	TTDataSource.Products.UnitOfMeasure                                               AS UnitOfMeasurementInitial,
	|	TTDataSource.Characteristic                                                              AS InitialCharacteristic,
	|   
	|	AnotherQualityGoods.Products IS NOT NULL                                              AS ThereIsItemOfDifferentQuality,
	|	ISNULL(AnotherQualityGoods.Products, VALUE(Catalog.Products.EmptyRef)) AS ProductsOfDifferentQuality,
	|
	|	PackagesAndUnitsOfMeasure.Ref                                                              AS PackagingUnitsOriginal,
	|	PackagesAndUnitsOfMeasure.Description                                                        AS PackagingUnitOriginalName,
	|	PackagesAndUnitsOfMeasure.Ref IS NOT NULL                                                 AS OriginalPackagingUnitIsFull,
	|	&PackagingUnitIsOriginalCoefficient                                                                 AS PackagingUnitIsOriginalCoefficient
	|
	|INTO ProductParameters_
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|		ON TTDataSource.Products = AnotherQualityGoods.OtherQualityGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON TTDataSource.Package = PackagesAndUnitsOfMeasure.Ref";
	
	If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Partner", CachedValues) Then
		QueryText = StrReplace(QueryText, "&PartnerField", "TTDataSource.Partner"); // @query-part-2
	Else
		QueryText = StrReplace(QueryText, "&PartnerField", "&OwnerOfPartnerItem"); // @query-part-2
	EndIf;
	
	QueryText = StrReplace(QueryText,
		"&PackagingUnitIsOriginalCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PackagesAndUnitsOfMeasure",
		"TTDataSource.Products"));
		
	Result.Add(QueryText, "ProductParameters_");
	
	If BatchProcessingOfTablePartServer.ThereIsColumnInDataSource("Partner", CachedValues) Then 
		
		// It is necessary to check the use of the Contract by agreement
		QueryText = StrReplace(QueryText,
			"&Partner",
			"TTDataSource.Partner");
				
	EndIf;
		
	QueryText = 
	"SELECT DISTINCT ALLOWED
	|	ProductParameters_.IdOfTTRow                                                                  AS IdOfTTRow,
	|	ProductParameters_.Partner                                                                                AS Partner,
	|	ProductParameters_.PartnerSItemListIsOriginalOne                                                           AS PartnerSItemListIsOriginalOne,
	|	ProductParameters_.SourceProducts_                                                                   AS Products,
	|	ProductParameters_.InitialCharacteristic                                                                 AS Characteristic,
	|	CASE
	|		WHEN ProductParameters_.OriginalPackagingUnitIsFull
	|			THEN ProductParameters_.PackagingUnitsOriginal
	|		ELSE ProductParameters_.UnitOfMeasurementInitial
	|	END                                                                                                        AS Package,
	|	FALSE                                                                                                         AS ThisIsDifferentQualityProduct
	|INTO CounterpartyItemSearchParameters
	|FROM
	|	ProductParameters_ AS ProductParameters_
	|
	|UNION ALL
	|
	|SELECT
	|	ProductParameters_.IdOfTTRow                                                                  AS IdOfTTRow,
	|	ProductParameters_.Partner                                                                                AS Partner,
	|	ProductParameters_.PartnerSItemListIsOriginalOne                                                           AS PartnerSItemListIsOriginalOne,
	|	ProductParameters_.ProductsOfDifferentQuality                                                            AS Products,
	|	ProductParameters_.InitialCharacteristic                                                                 AS Characteristic,
	|	CASE
	|		WHEN ProductParameters_.OriginalPackagingUnitIsFull
	|			THEN ISNULL(OtherQualityItemPackagingUnits.Ref, ProductParameters_.PackagingUnitsOriginal)
	|		ELSE ProductParameters_.ProductsOfDifferentQuality.UnitOfMeasure
	|	END                                                                                                        AS Package,
	|	TRUE                                                                                                       AS ThisIsDifferentQualityProduct
	|FROM
	|	ProductParameters_ AS ProductParameters_
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS OtherQualityItemPackagingUnits
	|		ON ProductParameters_.ProductsOfDifferentQuality = OtherQualityItemPackagingUnits.Owner
	|			AND ProductParameters_.PackagingUnitOriginalName = OtherQualityItemPackagingUnits.Description
	|			AND (ProductParameters_.OriginalPackagingUnitIsFull)
	|			AND (ProductParameters_.PackagingUnitIsOriginalCoefficient = &PackagingUnitsOfDifferentQualityCoefficient)
	|WHERE
	|	ProductParameters_.ThereIsItemOfDifferentQuality";
	
	QueryText = StrReplace(QueryText,
		"&PackagingUnitsOfDifferentQualityCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"OtherQualityItemPackagingUnits",
		"ProductParameters_.ProductsOfDifferentQuality"));
	
	Result.Add(QueryText, "CounterpartyItemSearchParameters");
	
	QueryText =
	"SELECT ALLOWED
	|	PartnerItemSearchParameters.IdOfTTRow AS IdOfTTRow,
	|	// If the original nomenclature has been selected, then select it. If not, then we get the counterparty's nomenclature with priority for a goods of a different quality.:
	|	ISNULL(ISNULL(MAX(CASE
	|					WHEN ProductCrossReferences.Ref = PartnerItemSearchParameters.PartnerSItemListIsOriginalOne
	|						THEN ProductCrossReferences.Ref
	|					ELSE NULL
	|				END), MAX(CASE
	|					WHEN PartnerItemSearchParameters.ThisIsDifferentQualityProduct
	|						THEN ProductCrossReferences.Ref
	|					ELSE NULL
	|				END)), ISNULL(MAX(CASE
	|					WHEN PartnerItemSearchParameters.ThisIsDifferentQualityProduct
	|						THEN NULL
	|					ELSE ProductCrossReferences.Ref
	|				END), VALUE(Catalog.ProductCrossReferences.EmptyRef))) AS PartnerProducts
	|
	|FROM
	|	CounterpartyItemSearchParameters AS PartnerItemSearchParameters
	|		LEFT JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON PartnerItemSearchParameters.Partner = ProductCrossReferences.Owner 
	|			AND PartnerItemSearchParameters.Products = ProductCrossReferences.Products
	|			AND PartnerItemSearchParameters.Characteristic = ProductCrossReferences.Characteristic
	|			AND PartnerItemSearchParameters.Package = ProductCrossReferences.Package
	|			AND NOT ProductCrossReferences.DeletionMark
	|			AND NOT ProductCrossReferences.Invalid
	|
	|GROUP BY
	|	PartnerItemSearchParameters.IdOfTTRow";
	Result.Add(QueryText, "FillInProductNameOfProductPartner");
	
	Return Result;
	
EndFunction

// Returns a list of requests to get items by partner item.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsFillInItemAccordingToPartnerSItem()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT ALLOWED
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	TTDataSource.Products AS ItemSource,
	|	TTDataSource.Package AS PackagingUnitSource,
	|	PartnersProducts.Products AS Products,
	|	PartnersProducts.Characteristic AS Characteristic,
	|	PartnersProducts.Package AS Package,
	|	CASE
	|		WHEN PartnersProducts.Products.UseVariants IN (VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind), VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind), VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN PartnersProducts.Products IS NULL
	|			THEN FALSE
	|		WHEN PartnersProducts.Products <> TTDataSource.Products
	|				AND AnotherQualityGoods.Products IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS YouNeedToFillInProductList,
	|	CASE
	|		WHEN PartnersProducts.Characteristic IS NULL
	|			THEN FALSE
	|		WHEN PartnersProducts.Characteristic <> TTDataSource.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CharacteristicsMustBeRefilled,
	|	CASE
	|		WHEN AnotherQualityGoods.OtherQualityGoods IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS InDocumentNomenclatureIsOfDifferentQuality,
	|	CatalogProducts.UnitOfMeasure AS BasicUnitOfProductMeasurementInDocument,
	|	AnotherQualityGoods.OtherQualityGoods AS OtherQualityGoods
	|INTO PartnerProducts
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.ProductCrossReferences AS PartnersProducts
	|		ON TTDataSource.PartnerProducts = PartnersProducts.Ref
	|			AND (PartnersProducts.Products <> VALUE(Catalog.Products.EmptyRef))
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|			LEFT JOIN InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
	|			ON CatalogProducts.Ref = AnotherQualityGoods.OtherQualityGoods
	|		ON (CatalogProducts.Ref = TTDataSource.Products)";
	
	Result.Add(QueryText, "PartnerProducts");
	
	QueryText =
	"SELECT
	|	PartnerProducts.IdOfTTRow AS IdOfTTRow,
	|	MAX(PackingUnitsSearch.Ref) AS PackagingOfDefectiveGoods,
	|	PackagesAndUnitsOfMeasure.Ref AS PartnerProductPackaging
	|INTO PackagingOfDefectiveGoodsInDocument
	|FROM
	|	PartnerProducts AS PartnerProducts
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|		ON PartnerProducts.Package = PackagesAndUnitsOfMeasure.Ref
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS PackingUnitsSearch
	|		ON PackagesAndUnitsOfMeasure.Description = PackingUnitsSearch.Description
	|		AND PackingUnitsSearch.Owner = PartnerProducts.ItemSource
	|		AND NOT PackingUnitsSearch.DeletionMark
	|		AND ISNULL(&RequestTextForPackingCoefficient, 1) = ISNULL(&SearchQueryTextForPackingFactor, 1)
	|GROUP BY
	|	PartnerProducts.IdOfTTRow,
	|	PackagesAndUnitsOfMeasure.Ref";
	
	QueryText = StrReplace(QueryText,
		"&RequestTextForPackingCoefficient", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackagesAndUnitsOfMeasure"));
		
	QueryText = StrReplace(QueryText,
		"&SearchQueryTextForPackingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PackingUnitsSearch"));
	
	Result.Add(QueryText, "PackagingOfDefectiveGoodsInDocument");
	
	QueryText = 
	"SELECT
	|	PartnerProducts.IdOfTTRow AS IdOfTTRow,
	|	CASE
	|		WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|			THEN PartnerProducts.OtherQualityGoods
	|		ELSE PartnerProducts.Products
	|	END AS Products,
	|	PartnerProducts.Characteristic AS Characteristic,
	|	CASE
	|		WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|				AND PartnerProducts.Package.Owner <> VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|			THEN PackagingOfDefectiveGoodsInDocument.PackagingOfDefectiveGoods
	|		ELSE PartnerProducts.Package
	|	END AS Package,
	|	PartnerProducts.ItemVariantsAreUsed AS ItemVariantsAreUsed,
	|	PartnerProducts.YouNeedToFillInProductList AS YouNeedToFillInProductList,
	|	PartnerProducts.CharacteristicsMustBeRefilled AS CharacteristicsMustBeRefilled,
	|	CASE
	|		WHEN PartnerProducts.Package IS NULL
	|			THEN FALSE
	|		WHEN PartnerProducts.Package.Owner <> VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|			THEN CASE
	|					WHEN PartnerProducts.InDocumentNomenclatureIsOfDifferentQuality
	|						THEN CASE
	|								WHEN PartnerProducts.Package <> PartnerProducts.PackagingUnitSource
	|										AND PartnerProducts.Package <> PackagingOfDefectiveGoodsInDocument.PackagingOfDefectiveGoods
	|									THEN TRUE
	|								ELSE FALSE
	|							END
	|					ELSE CASE
	|							WHEN PartnerProducts.Package <> PartnerProducts.PackagingUnitSource
	|								THEN TRUE
	|							ELSE FALSE
	|						END
	|				END
	|		ELSE CASE
	|				WHEN PartnerProducts.Package <> PartnerProducts.BasicUnitOfProductMeasurementInDocument
	|						OR PartnerProducts.PackagingUnitSource <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|					THEN TRUE
	|				ELSE FALSE
	|			END
	|	END AS NeedToReFillPackages
	|FROM
	|	PartnerProducts AS PartnerProducts
	|		LEFT JOIN PackagingOfDefectiveGoodsInDocument AS PackagingOfDefectiveGoodsInDocument
	|		ON PartnerProducts.Package = PackagingOfDefectiveGoodsInDocument.PartnerProductPackaging";
	
	Result.Add(QueryText, "FillInTheItemByThePartnerSItem");
	
	Return Result;
	
EndFunction

// Returns a list of requests to check the matched partner item.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsCheckMatchedPartnerItem()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow AS IdOfTTRow,
	|	SUM(CASE
	|		WHEN ProductCrossReferences.Ref IS NOT NULL
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfPartnerProducts
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN Catalog.ProductCrossReferences AS ProductCrossReferences
	|		ON (ProductCrossReferences.Owner = &OwnerOfPartnerItem)
	|		AND (NOT ProductCrossReferences.DeletionMark)
	|		AND TTDataSource.Products = ProductCrossReferences.Products
	|		AND TTDataSource.Characteristic = ProductCrossReferences.Characteristic
	|		AND TTDataSource.Package = ProductCrossReferences.Package
	|		AND TTDataSource.PartnerProducts <> ProductCrossReferences.Ref
	|		AND (CAST(TTDataSource.PartnerProducts AS
	|			Catalog.ProductCrossReferences).Products = VALUE(Catalog.Products.EmptyRef))
	|GROUP BY
	|	TTDataSource.IdOfTTRow";
	
	Result.Add(QueryText, "CheckMatchedPartnerProducts");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
