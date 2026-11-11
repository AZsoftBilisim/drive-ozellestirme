///////////////////////////////////////////////////////////////////////////////
// PROCEDURES AND FUNCTIONS FOR FILLING MULTI-TURN CONTAINERS IN DOCUMENTS
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Fills in the multi-turn container selected by processing in the document.
//
// Parameters:
//  Object                  - DocumentObject - The document from which you need to select a multi-turn container.
//  TableName              - String - The table name of the document for which you want to pick up reusable containers.
//  ColumnsNames            - String - Names of columns in the table that should be used for container selection.
//  UUID - String - unique form ID.
//  UseWarehouse       - Boolean - Indicates whether there is a warehouse in the table part of the document.
//  UseDate        - Boolean - Indicates whether the date is in the table part of the document.
//
// Returns:
//  String - The address in the temporary storage in which the container is placed.
//
Function PlaceGoodsForSelectionOfContainersInTemporaryStorage(Val Object,
	                                                      Val TableName,
	                                                      Val ColumnsNames,
	                                                      Val UUID,
	                                                      Val UseWarehouse,
	                                                      Val UseDate,
                                                          Val UseReceiptDate = False) Export
	
	TableOfGoods = New ValueTable();
	TableOfGoods.Columns.Add("Products");
	TableOfGoods.Columns.Add("Characteristic");
	TableOfGoods.Columns.Add("Package");
	TableOfGoods.Columns.Add("Count");
	TableOfGoods.Columns.Add("Warehouse");
	TableOfGoods.Columns.Add("Date");
	TableOfGoods.Columns.Add("DateOfReceipt");
	
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ColumnsNames, ",");
	
	If TypeOf(Object.Ref) = Type("DocumentRef.GoodsReceiptNote") Then
		ObjectProducts = TableOfProductsWithProductLocations(Object[TableName])
	Else
		ObjectProducts = Object[TableName];
	EndIf;
	
	For Each CurRow In ObjectProducts Do
		
		NewRow = TableOfGoods.Add();
		NewRow.Products = CurRow[ColumnsArray1[0]];
		NewRow.Characteristic = CurRow[ColumnsArray1[1]];
		NewRow.Count = CurRow[ColumnsArray1[2]];
		
		If (TypeOf(Object.Ref) = Type("DocumentRef.GoodsReceiptNote") And ObjectProducts.Columns.Find("Package")<>Undefined)
		Or (TypeOf(Object.Ref) <> Type("DocumentRef.GoodsReceiptNote") And CurRow.Property("Package")) Then
			NewRow.Package = CurRow["Package"]; 
		EndIf;
		
		If UseWarehouse Then
			NewRow.Warehouse = CurRow[ColumnsArray1[3]];
		EndIf;
		
		If UseDate Then
			NewRow.Date = CurRow[ColumnsArray1[4]];
		EndIf;
		
		If UseReceiptDate Then
			NewRow.DateOfReceipt = CurRow[ColumnsArray1[5]];
		EndIf;
		
	EndDo;
	
	AddressOfTheGoodsInTheTemporaryStorage = PutToTempStorage(
		TableOfGoods,
		UUID);
		
	Return AddressOfTheGoodsInTheTemporaryStorage;
	
EndFunction

// Checks whether the document contains products that may require multi-turn packaging.
//
// Parameters:
//  Object       - DocumentObject - The document from which you need to select a multi-turn container.
//  TableName   - String - The table name of the document for which you want to verify.
//  ColumnsNames - String - Names of table columns to be checked against.
//
// Returns:
//  Boolean - True if the user needs to be prompted to add a container to the document.
//
Function AskQuestionAboutFillingMultiTurnContainers(Val Object,
	                                                 Val TableName,
	                                                 Val ColumnsNames) Export
	
	If Not GetFunctionalOption("OfferToSupplementReusablePackageDocuments") Then
		Return False;
	EndIf;
	
	ColumnsArray1 = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ColumnsNames, ",");
	ColumnNameProducts = ColumnsArray1[0];
	ColumnNameQuantity = ColumnsArray1[2];
	ColumnsList = StrTemplate("%1,%2", ColumnNameProducts, ColumnNameQuantity);
	TableOfGoods = Object[TableName].Unload(, ColumnsList);

	QueryText =
	"SELECT
	|	CAST(&ColumnProducts AS Catalog.Products) AS Products,
	|	CAST(&ColumnQuantity AS NUMBER(15, 3)) AS Count
	|INTO DocumentTableSource
	|FROM
	|	&DocumentTable AS DocumentTableSource
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Products AS Products,
	|	SUM(DocumentTable.Count) AS Count,
	|	CatalogProducts.PackagingGroup AS PackagingGroup
	|INTO DocumentTable
	|FROM
	|	DocumentTableSource AS DocumentTable
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON (CatalogProducts.Ref = DocumentTable.Products)
	|WHERE
	|	DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|
	|GROUP BY
	|	DocumentTable.Products,
	|	CatalogProducts.PackagingGroup
	|
	|INDEX BY
	|	PackagingGroup,
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentTable.Products AS Products,
	|	DocumentTable.Count AS Count,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS ZoomRatio,
	|	ISNULL(ProductPackages.MinimumNumberOfReusablePackages, 0) AS MinimumNumber
	|INTO PackagingInContainers
	|FROM
	|	DocumentTable AS DocumentTable
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (DocumentTable.PackagingGroup = ProductPackages.Owner
	|				OR DocumentTable.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|					AND DocumentTable.Products = ProductPackages.Owner)
	|WHERE
	|	ProductPackages.SuppliedInReusablePackage
	|	AND NOT ProductPackages.DeletionMark
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	PackagingInContainers.Products AS Products
	|FROM
	|	PackagingInContainers AS PackagingInContainers
	|WHERE
	|	(PackagingInContainers.Count / PackagingInContainers.ZoomRatio >= 1
	|			OR PackagingInContainers.MinimumNumber > 0
	|				AND PackagingInContainers.Count / PackagingInContainers.MinimumNumber >= 1)
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	DocumentTable.Products
	|FROM
	|	DocumentTable AS DocumentTable
	|WHERE
	|	DocumentTable.Products.SuppliedInReusablePackage";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ProductPackages",
		"DocumentTable.Products"));

	QueryText = StrReplace(QueryText,
		"&ColumnProducts",
		StrTemplate("DocumentTableSource.%1", ColumnNameProducts));
	QueryText = StrReplace(QueryText,
		"&ColumnQuantity",
		StrTemplate("DocumentTableSource.%1", ColumnNameQuantity));
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentTable", TableOfGoods);
	QueryResult = Query.Execute();
	Return Not QueryResult.IsEmpty();
	
EndFunction

#EndRegion

#Region Private

Function TableOfProductsWithProductLocations(DocumentGoods)
	
	Query = New Query;
	
	Query.Text = 
	"SELECT
	|	DocumentGoods.Products                                               AS Products,
	|	DocumentGoods.Characteristic                                             AS Characteristic,
	|	CAST(DocumentGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	DocumentGoods.Count                                                 AS Count
	|INTO TypesOfDocumentToRequest
	|FROM
	|	&DocumentGoods AS DocumentGoods
	|WHERE
	|	DocumentGoods.Count > 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentGoods.Products      AS Products,
	|	DocumentGoods.Characteristic    AS Characteristic,
	|	DocumentGoods.Package          AS Package,
	|	SUM(DocumentGoods.Count) AS Count
	|INTO GoodsOfDocumentOnCommodityPlaces
	|FROM
	|	TypesOfDocumentToRequest AS DocumentGoods
	|WHERE
	|	ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentGoods.Products   AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentGoods.Count     AS Count
	|FROM
	|	TypesOfDocumentToRequest AS DocumentGoods
	|WHERE
	|	ISNULL(DocumentGoods.Package.PackageType, UNDEFINED) <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic,
	|	MIN(CASE
	|		WHEN DocumentGoods.Count - (CAST(DocumentGoods.Count AS NUMBER(15, 0))) >= 0
	|			THEN CAST(DocumentGoods.Count AS NUMBER(15, 0))
	|		ELSE (CAST(DocumentGoods.Count AS NUMBER(15, 0))) - 1
	|	END)
	|FROM
	|	GoodsOfDocumentOnCommodityPlaces AS DocumentGoods
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	DocumentGoods.Characteristic";
	
	Query.SetParameter("DocumentGoods", DocumentGoods.Unload());
	
	Goods = Query.Execute().Unload();
	
	Return Goods;
	
EndFunction

#EndRegion
