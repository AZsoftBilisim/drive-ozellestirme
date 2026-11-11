#If Not MobileStandaloneServer Then

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Caches information about item barcodes, based on the data found in the information database, based on the transmitted
// collection of barcodes.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Barcodes - Array of String - barcodes for which you need to get information.
//	ReceiveNonUniqueBarcodes - Boolean - indicates whether data about non-unique item barcodes is received.
//
Procedure GetBarcodeData(CachedValues, Barcodes, ReceiveNonUniqueBarcodes = False) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Barcodes.Barcode				AS Barcode,
	|	COUNT(Barcodes.Barcode)	AS NumberOfBarcodes
	|INTO BarcodesInformation
	|FROM
	|	InformationRegister.ItemsBarcodes AS Barcodes
	|WHERE
	|	Barcodes.Barcode IN (&ArrayOfBarcodes)
	|
	|GROUP BY
	|	Barcodes.Barcode
	|
	|INDEX BY
	|	Barcode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBarcodes.Barcode					AS Barcode,
	|	ItemsBarcodes.Products				AS Products,
	|	CatalogProducts.PackagingGroup			AS PackagingGroup,
	|	CatalogProducts.UnitOfMeasure			AS UnitOfMeasure,
	|	ItemsBarcodes.Characteristic			AS Characteristic,
	|	ItemsBarcodes.Series						AS Series,
	|	ItemsBarcodes.Package					AS Package,
	|	BarcodesInformation.NumberOfBarcodes > 1	AS NonUniqueBarcode
	|INTO TTBarcodesOfNomenclature
	|FROM
	|	BarcodesInformation AS BarcodesInformation
	|		INNER JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON BarcodesInformation.Barcode = ItemsBarcodes.Barcode
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBarcodes.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|INTO ProductPackages
	|FROM
	|	TTBarcodesOfNomenclature AS ItemsBarcodes
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ItemsBarcodes.Products = ProductPackages.Owner
	|			AND ItemsBarcodes.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND ItemsBarcodes.PackagingGroup = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|UNION ALL
	|
	|SELECT
	|	ItemsBarcodes.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|FROM
	|	TTBarcodesOfNomenclature AS ItemsBarcodes
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ItemsBarcodes.PackagingGroup = ProductPackages.Owner
	|			AND ItemsBarcodes.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND ItemsBarcodes.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBarcodes.Barcode						AS Barcode,
	|	CatalogProducts.Ref						AS Products,
	|	CatalogProducts.ItemsType				AS ItemsType,
	|	&DetailsOfItemSelection,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END												AS SpecifyQuantityWhenRegisteringBatch,
	|	ItemsBarcodes.Characteristic				AS Characteristic,
	|	ItemsBarcodes.Series							AS Series,
	|	ISNULL(CatalogProducts.ProductKind.KeepAccountingByBatch, FALSE) AS SeriesAreUsed,
	|	ItemsBarcodes.Package						AS Package,
	|	ISNULL(CatalogOfPackagingUnits.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem) AS CargoItem,
	|	PRESENTATION(CatalogProducts.Ref)		AS ProductsPresentation,
	|	PRESENTATION(ItemsBarcodes.Characteristic)	AS CharacteristicPresentation,
	|	ISNULL(&QueryTextPackagingFactor1, 1)		AS ZoomRatio,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.UseVariants, UNDEFINED) = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END													AS ItemVariantsAreUsed,
	|	CatalogProducts.SuppliedInReusablePackage	AS SuppliedInReusablePackage,
	|	CatalogProducts.UsePackages				AS UsePackages,
	|	MAX(ProductPackages.Package)					AS SinglePackaging,
	|	COUNT(DISTINCT ProductPackages.Package)		AS NumberOfSinglePackages,
	|	ItemsBarcodes.NonUniqueBarcode				AS NonUniqueBarcode,
	|	CASE
	|		WHEN ProductKitConfigurations.SetPricingOption IS NULL
	|			THEN VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		ELSE ProductKitConfigurations.SetPricingOption
	|	END													AS SetPricingOption,
	|	ItemsBarcodes.UnitOfMeasure					AS UnitOfMeasure
	|FROM
	|	TTBarcodesOfNomenclature AS ItemsBarcodes
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogOfPackagingUnits
	|		ON ItemsBarcodes.Package = CatalogOfPackagingUnits.Ref
	|		
	|		LEFT JOIN ProductPackages AS ProductPackages
	|		ON ItemsBarcodes.Products = ProductPackages.Products
	|		
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = ItemsBarcodes.Products
	|			AND ProductKitConfigurations.Characteristic = ItemsBarcodes.Characteristic
	|			AND ProductKitConfigurations.Main
	|	, ConnectionTable
	|GROUP BY
	|	ItemsBarcodes.Barcode,
	|	CatalogProducts.Ref,
	|	&DetailsOfItemGrouping,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END,
	|	ItemsBarcodes.Characteristic,
	|	ItemsBarcodes.Series,
	|	ISNULL(CatalogProducts.ProductKind.KeepAccountingByBatch, FALSE),
	|	ItemsBarcodes.Package,
	|	CatalogOfPackagingUnits.Ref,
	|	ItemsBarcodes.NonUniqueBarcode,
	|	CASE
	|		WHEN ProductKitConfigurations.SetPricingOption IS NULL
	|			THEN VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		ELSE ProductKitConfigurations.SetPricingOption
	|	END,
	|	ItemsBarcodes.UnitOfMeasure";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ItemsBarcodes.Package",
		"CatalogProducts"));
	
	QueryTextsForItemDetails = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem(
		"CatalogProducts",
		QueryTextsForItemDetails);
	
	Query.Text = StrReplace(Query.Text,
								"&DetailsOfItemSelection",
								QueryTextsForItemDetails.DetailsOfItemSelection);
	Query.Text = StrReplace(Query.Text,
								"&DetailsOfItemGrouping",
								QueryTextsForItemDetails.DetailsOfItemGrouping);
	Query.Text = StrReplace(Query.Text,
								", ConnectionTable",
								QueryTextsForItemDetails.DetailsOfConnectionNomenclature);
	
	ArrayOfBarcodes = New Array;
	
	For Each CurBarcode In Barcodes Do
		Barcode = Upper(TrimAll(CurBarcode));
		ArrayOfBarcodes.Add(Barcode);
		
		BarcodesInformation_ = BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode();
		BarcodesInformation_.Barcode = Barcode;
		
		CachedValues.Barcodes.Insert(Barcode, BarcodesInformation_);
	EndDo;
	
	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	BarcodeData_ = QueryResult.Unload();
	BarcodeData_.Indexes.Add("Barcode");
	
	FillInCachedValuesAccordingToInfobaseData(CachedValues,
											BarcodeData_,
											ArrayOfBarcodes,
											ReceiveNonUniqueBarcodes);
	
EndProcedure

// Caches information about item barcodes, based on the data found in the information database, based on the transmitted
// collection of barcodes.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Barcodes - Array of String - barcodes for which you need to get information.
//	ReceiveNonUniqueBarcodes - Boolean - indicates whether data about non-unique item barcodes is received.
//
Procedure GetDataOnBarcodesAdvanced(CachedValues, Barcodes, ReceiveNonUniqueBarcodes = False) Export
	
	GetBarcodeData(CachedValues, Barcodes, ReceiveNonUniqueBarcodes);
	GetDataOnBarcodesOfBatchLabels(CachedValues, Barcodes, ReceiveNonUniqueBarcodes);
	
EndProcedure

// Caches information about item barcodes based on the data found in the information database, based on the transmitted
// collection of information about item barcodes.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	ItemsBarcodes - Array of Structure- a collection of information about item barcodes that contains the following properties:
//		* Barcode - String - The item barcode.
//		* Products - CatalogRef.Products - Nomenclature.
//		* Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//		* Series - CatalogRef.ItemsBatches - a series of Products.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - Item packaging units.
//
Procedure GetDataOnItemBarcodes(CachedValues, ItemsBarcodes) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Barcodes.Barcode			AS Barcode,
	|	Barcodes.Products		AS Products,
	|	Barcodes.Characteristic	AS Characteristic,
	|	Barcodes.Series				AS Series,
	|	Barcodes.Package			AS Package
	|INTO BarcodesInformation
	|FROM
	|	&BarcodeData_ AS Barcodes
	|
	|INDEX BY
	|	Barcode,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Barcodes.Barcode				AS Barcode,
	|	COUNT(Barcodes.Barcode)	AS NumberOfBarcodes
	|INTO NonUniqueBarcodes
	|FROM
	|	BarcodesInformation AS BarcodesInformation
	|		INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|		ON BarcodesInformation.Barcode = Barcodes.Barcode
	|
	|GROUP BY
	|	Barcodes.Barcode
	|
	|HAVING
	|	COUNT(Barcodes.Barcode) > 1
	|
	|INDEX BY
	|	Barcode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ItemsBarcodes.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|INTO ProductPackages
	|FROM
	|	BarcodesInformation AS ItemsBarcodes
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON ItemsBarcodes.Products = ProductPackages.Owner
	|			AND CatalogProducts.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND ISNULL(CatalogProducts.PackagingGroup, UNDEFINED) = VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|UNION ALL
	|
	|SELECT
	|	ItemsBarcodes.Products	AS Products,
	|	ProductPackages.Ref			AS Package
	|FROM
	|	BarcodesInformation AS ItemsBarcodes
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON CatalogProducts.PackagingGroup = ProductPackages.Owner
	|			AND CatalogProducts.UnitOfMeasure = ProductPackages.UnitOfMeasure
	|			AND ProductPackages.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.Package)
	|			AND ISNULL(ProductPackages.Denominator, 0) <> 0
	|
	|WHERE
	|	NOT ProductPackages.DeletionMark
	|	AND CatalogProducts.PackagingGroup <> VALUE(Catalog.PackagingGroups.SpecialForItem)
	|	AND CAST(ProductPackages.Numerator / ProductPackages.Denominator AS NUMBER(27, 11)) = 1
	|
	|INDEX BY
	|	Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BarcodesInformation.Barcode								AS Barcode,
	|	CatalogProducts.Ref								AS Products,
	|	CatalogProducts.ItemsType						AS ItemsType,
	|	&DetailsOfItemSelection,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END														AS SpecifyQuantityWhenRegisteringBatch,
	|	BarcodesInformation.Characteristic						AS Characteristic,
	|	BarcodesInformation.Series									AS Series,
	|	ISNULL(CatalogProducts.ProductKind.KeepAccountingByBatch, FALSE) AS SeriesAreUsed,
	|	BarcodesInformation.Package								AS Package,
	|	ISNULL(CatalogOfPackagingUnits.PackageType, UNDEFINED) = VALUE(Enum.TypesOfItemsPackages.CargoItem) AS CargoItem,
	|	PRESENTATION(CatalogProducts.Ref)				AS ProductsPresentation,
	|	PRESENTATION(BarcodesInformation.Characteristic)			AS CharacteristicPresentation,
	|	ISNULL(&QueryTextPackagingFactor1, 1)				AS ZoomRatio,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.UseVariants, UNDEFINED) = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END														AS ItemVariantsAreUsed,
	|	CatalogProducts.SuppliedInReusablePackage		AS SuppliedInReusablePackage,
	|	CatalogProducts.UsePackages					AS UsePackages,
	|	MAX(ProductPackages.Package)						AS SinglePackaging,
	|	COUNT(DISTINCT ProductPackages.Package)			AS NumberOfSinglePackages,
	|	CASE
	|		WHEN ProductKitConfigurations.SetPricingOption IS NULL
	|			THEN VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		ELSE ProductKitConfigurations.SetPricingOption
	|	END														AS SetPricingOption,
	|	CatalogProducts.UnitOfMeasure						AS UnitOfMeasure,
	|	NOT NonUniqueBarcodes.Barcode IS NULL					AS NonUniqueBarcode,
	|	NOT ItemsBarcodes.Barcode IS NULL					AS ReceivedAccordingToInfobaseData
	|FROM
	|	BarcodesInformation AS BarcodesInformation
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON BarcodesInformation.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS CatalogOfPackagingUnits
	|		ON BarcodesInformation.Package = CatalogOfPackagingUnits.Ref
	|		
	|		LEFT JOIN NonUniqueBarcodes AS NonUniqueBarcodes
	|		ON BarcodesInformation.Barcode = NonUniqueBarcodes.Barcode
	|		
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON BarcodesInformation.Barcode = ItemsBarcodes.Barcode
	|			AND BarcodesInformation.Products = ItemsBarcodes.Products
	|			AND BarcodesInformation.Characteristic = ItemsBarcodes.Characteristic
	|			AND BarcodesInformation.Series = ItemsBarcodes.Series
	|			AND BarcodesInformation.Package = ItemsBarcodes.Package
	|		
	|		LEFT JOIN ProductPackages AS ProductPackages
	|		ON ItemsBarcodes.Products = ProductPackages.Products
	|		
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = BarcodesInformation.Products
	|			AND ProductKitConfigurations.Characteristic = BarcodesInformation.Characteristic
	|			AND ProductKitConfigurations.Main
	|	, ConnectionTable
	|
	|GROUP BY
	|	BarcodesInformation.Barcode,
	|	CatalogProducts.Ref,
	|	&DetailsOfItemGrouping,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN ISNULL(CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch, FALSE)
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END,
	|	BarcodesInformation.Characteristic,
	|	BarcodesInformation.Series,
	|	CatalogProducts.ProductKind.KeepAccountingByBatch,
	|	BarcodesInformation.Package,
	|	CatalogOfPackagingUnits.Ref,
	|	CASE
	|		WHEN ProductKitConfigurations.SetPricingOption IS NULL
	|			THEN VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		ELSE ProductKitConfigurations.SetPricingOption
	|	END,
	|	NOT NonUniqueBarcodes.Barcode IS NULL,
	|	NOT ItemsBarcodes.Barcode IS NULL";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("BarcodesInformation.Package",
		"CatalogProducts"));
	
	QueryTextsForItemDetails = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem(
		"CatalogProducts",
		QueryTextsForItemDetails);
	
	Query.Text = StrReplace(Query.Text,
								"&DetailsOfItemSelection",
								QueryTextsForItemDetails.DetailsOfItemSelection);
	Query.Text = StrReplace(Query.Text,
								"&DetailsOfItemGrouping",
								QueryTextsForItemDetails.DetailsOfItemGrouping);
	Query.Text = StrReplace(Query.Text,
								", ConnectionTable",
								QueryTextsForItemDetails.DetailsOfConnectionNomenclature);
	
	BarcodeData_	= BarcodesDataTable();
	
	For Each BarcodeData_1 In ItemsBarcodes Do
		Barcode = Upper(TrimAll(BarcodeData_1.Barcode));
		
		NewRow = BarcodeData_.Add();
		FillPropertyValues(NewRow, BarcodeData_1);
		
		NewRow.Barcode = Barcode;
		
		BarcodesInformation_ = BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode();
		BarcodesInformation_.Barcode = Barcode;
		
		CachedValues.Barcodes.Insert(Barcode, BarcodesInformation_);
	EndDo;
	
	Query.SetParameter("BarcodeData_", BarcodeData_);
	
	SetPrivilegedMode(True);
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	SetPrivilegedMode(False);
	
	Selection = QueryResult[QueryResult.UBound()].Select();
	
	While Selection.Next() Do
		BarcodeInformation_ = CachedValues.Barcodes[Selection.Barcode];
		FillInBarcodeInformation(BarcodeInformation_, Selection);
	EndDo;
	
EndProcedure

// The function calculates the control character of the EAN code.
//
// Parameters:
//  Barcode - String - the barcode (without the check digit).
//  Type      - Number - barcode type (13 for EAN13, 8 for EAN8).
//
// Returns:
//  String - The barcode control character.
//
Function EanControlSymbol(Barcode, Type) Export

	Chetn   = 0;
	Odd = 0;

	IterationCount = ?(Type = 13, 6, 4);

	For IndexOf = 1 To IterationCount Do
		If (Type = 8) And (IndexOf = IterationCount) Then
		Else
			Chetn   = Chetn   + Mid(Barcode, 2 * IndexOf, 1);
		EndIf;
		Odd = Odd + Mid(Barcode, 2 * IndexOf - 1, 1);
	EndDo;

	If Type = 13 Then
		Chetn = Chetn * 3;
	Else
		Odd = Odd * 3;
	EndIf;

	ContFigure = 10 - (Chetn + Odd) % 10;

	Return ?(ContFigure = 10, "0", String(ContFigure));

EndFunction

// Performs the conversion of the barcode obtained from the scales with label printing into a barcode suitable for searching in
// the information database.
//
// Parameters:
//	CurBarcode - See BarcodingOfItemsClient.BarcodeDataStructure.
//	WeightBarCodePrefixes - See SettingsValueCached.GetWeightBarCodePrefixes.
//
Procedure ConvertWeightBarcode(CurBarcode, WeightBarCodePrefixes) Export
	
	If StrLen(CurBarcode.Barcode) = 13 // EAN13
		And Left(CurBarcode.Barcode, 1) = "2" // Internal barcode
		And WeightBarCodePrefixes.Find(Mid(CurBarcode.Barcode, 2, 1)) <> Undefined Then // The prefix of the weight product was found
		
		// The barcode is a weight code, we perform the conversion.
		// Barcode weight format: 2 + N + HHH + BBBBB + K
		// Where,
		//  P - Prefix of the weight product
		//  HHH - code of the weight product
		//  BBBBB - Weight
		//  K is a control number.
		
		Code = Mid(CurBarcode.Barcode, 3, 5);
		Weight = Number(Mid(CurBarcode.Barcode, 8, 2)) + Number(Mid(CurBarcode.Barcode, 10, 3)) / 1000;
		
		CurBarcode.Barcode   = GetBarcodeOfWeightProductByCode(Code,,True);
		CurBarcode.Count = CurBarcode.Count * Weight;
		
	EndIf;
	
EndProcedure

// Returns the barcode prefix for the current database node
//
// Returns:
//  String - The prefix of the barcode node.
//
Function BarcodeNodePrefix() Export
	
	Return Format(Constants.DIBNodeBarcodePrefix.Get(),"ND=1; NZ=; NLZ=");
	
EndFunction

// The function returns the weight barcode format for requests.
//
// Parameters:
//  WeightBarcodePrefix - String - Prefis weight barcode.
//  Load - Boolean - Prefis loading data.
//
// Returns:
//  String - The template of the weight barcode.
//
Function WeightBarcodeFormat(WeightBarcodePrefix, Load = False) Export
	
	If Load Then
		Return "2[\_][0-9][0-9][0-9][0-9][0-9]00000[\_]";
	Else
		Return "2[\_]" + String(StrReplace(WeightBarcodePrefix, "_", "\_")) + "[0-9][0-9][0-9][0-9]00000[\_]";
	EndIf;
	
EndFunction

// Returns a collection containing parameters for selecting item barcodes.
//
// Returns:
//	Structure - a collection containing the following properties:
//		* Products - CatalogRef.Products
//		* Characteristic - CatalogRef.ItemsCharacteristics
//		* Series - CatalogRef.ItemsBatches
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure
//
Function DefaultParametersForSelectingItemBarcodes() Export
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Products",	Catalogs.Products.EmptyRef());
	FilterParameters.Insert("Characteristic",	Catalogs.ItemsCharacteristics.EmptyRef());
	FilterParameters.Insert("Series",			Catalogs.ItemsBatches.EmptyRef());
	FilterParameters.Insert("Package",		Catalogs.PackagesAndUnitsOfMeasure.EmptyRef());
	
	Return FilterParameters;
	
EndFunction

// Returns a collection of item barcodes for the assigned selection.
//
// Parameters:
//	FilterParameters - See DefaultParametersForSelectingItemBarcodes.
//
// Returns:
//	Array of String - Barcodes of the nomenclature.
//
Function ItemsBarcodes(FilterParameters) Export
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	ItemsBarcodes.Barcode AS Barcode
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Products = &Products
	|	AND ItemsBarcodes.Characteristic = &Characteristic
	|	AND (NOT &FilterByBatch
	|		OR ItemsBarcodes.Series = &Series)
	|	AND ItemsBarcodes.Package = &Package";
	
	Query.SetParameter("Products",	FilterParameters.Products);
	Query.SetParameter("Characteristic",	FilterParameters.Characteristic);
	Query.SetParameter("FilterByBatch",	ValueIsFilled(FilterParameters.Series));
	Query.SetParameter("Series",			FilterParameters.Series);
	Query.SetParameter("Package",		FilterParameters.Package);
	
	Barcodes = Query.Execute().Unload().UnloadColumn("Barcode");
	
	ReturnValue = New Array;
	
	For Each ArrayElement In Barcodes Do
		ReturnValue.Add(PrepareBarcode(ArrayElement));
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// The weight barcode template is supplemented with a node prefix and a check number.
//
// Parameters:
//  Barcode - String - Barcode
//
// Returns:
//  String - Barcode
//
Function PrepareBarcode(Val Barcode) Export
	
	If StrLen(Barcode) = 13 And Left(Barcode, 2) = "2_" Then
		Span = SettingsValueCached.DefaultRangeOfWeightBarcodes();
		
		If Span = Undefined Then
			Raise NStr("vi = 'Chưa xác định khoảng mã vạch theo cân.';
						|ru = 'Не определены диапазоны весовых штрихкодов.';
						|en = 'Weight barcode ranges are not determined.'; fa = 'Weight barcode ranges are not determined.';
						|it = 'Non sono stati definiti gli intervalli dei codici a barre delle merci sfuse.';
						|pl = 'Nie zdefiniowano zakresów kodów kreskowych wagowych.';
						|tr = 'Ağırlık barkod aralıkları tanımlanmadı.'");
		EndIf;
		
		String = Span + Mid(Barcode, 3, 5) + "00000";
		Return String + EanControlSymbol(String, 13);
	EndIf;
	
	Return Barcode;
	
EndFunction

// Returns the text of a message about a lack of free weight barcodes
//
// Returns:
//  String - Message text
//
Function MessageTextNoFreeWeightBarcodesCodes() Export
	Return NStr("vi = 'Không có mã vạch theo cân tự do.
		               |Chưa tạo mã vạch.';
		               |ru = 'Нет свободных кодов весовых штрихкодов.
		               |Штрихкод не сформирован.';
		               |en = 'No available weight barcode codes. 
		               |Barcode is not generated.'; fa = 'No available weight barcode codes. 
		               |Barcode is not generated.';
		               |it = 'Nessun codice a barre libero per le merci sfuse.
		               |Il codice a barre non è stato generato.';
		               |pl = 'Brak wolnych wagowych kodów kreskowych.
		               |Kod kreskowy nie jest utworzony.';
		               |tr = 'Boş ağırlık barkod kodları mevcut değildir.
		               |Barkod oluşturulmadı.'")	
EndFunction

// Returns the text of the message about the lack of free codes for individual barcodes
//
// Returns:
//  String - Message text
//
Function MessageTextNoFreeCodesPieceBarcodes() Export
	Return NStr("vi = 'Không có mã tự do trong khoảng mã vạch khả dụng.
		               |Chưa tạo mã vạch.';
		               |ru = 'Нет свободных кодов в доступных диапазонах штучных штрихкодов.
		               |Штрихкод не сформирован.';
		               |en = 'No available codes in the available manual barcode ranges. 
		               |Barcode is not generated.'; fa = 'No available codes in the available manual barcode ranges. 
		               |Barcode is not generated.';
		               |it = 'Nessun codice a barre libero negli intervalli disponibili per la merce venduta al pezzo.
		               |Il codice a barre non è stato generato.';
		               |pl = 'W dostępnych zakresach kodów kreskowych brak sztukowych kodów.
		               |Kod kreskowy nie jest utworzony.';
		               |tr = 'Erişilebilir parça barkod aralıklarında boş kod yok.
		               |Barkod oluşturulmadı.'")	
EndFunction

// Returns the text of the message about the absence of customizing the ranges of individual barcodes
//
// Returns:
//  String - Message text
//
Function MessageTextAvailableRangesOfUnitBarcodesAreNotConfigured() Export
	Return NStr("vi = 'Chưa tùy chỉnh khoảng mã vạch hợp lệ.
		               |Chưa tạo mã vạch.';
		               |ru = 'Не настроены доступные диапазоны штучных штрихкодов.
		               |Штрихкод не сформирован.';
		               |en = 'Available barcode ranges not configured.
		               |Barcode is not generated.'; fa = 'Available barcode ranges not configured.
		               |Barcode is not generated.';
		               |it = 'Non sono stati configurati intervalli disponibili di codici a barre singoli.
		               |Codice a barre non generato.';
		               |pl = 'Nie ustawiono dostępnych zakresów pojedynczych kodów kreskowych.
		               |Nie utworzono kodu kreskowego.';
		               |tr = 'Erişilebilir parça barkod aralıkları ayarlanmadı.
		               |Barkod oluşturulmadı.'")	
EndFunction

// This function generates the EAN13 barcode for
// a piece product.
//
// Returns:
//  String - Barcode of a piece product.
//
Function GenerateBarcodeEAN13() Export

	BarcodeNodePrefix = BarcodeNodePrefix();
	
	Code = Undefined;
	Span = Undefined;
	Ranges = GetMaximumValuesOfUnitBarcodes();
	If Ranges = Undefined Then
		Common.MessageToUser(MessageTextAvailableRangesOfUnitBarcodesAreNotConfigured());
		Return Undefined;
	EndIf;
	For Each TSRow In Ranges Do
		Code = TSRow.Code + 1;
		Span = TSRow.Span;
		Break;
	EndDo;
	
	If Code = Undefined Then
		Common.MessageToUser(MessageTextNoFreeCodesPieceBarcodes());
		Return Undefined;
	EndIf;
	
	Return GetBarcodeByCode(Code, Span, BarcodeNodePrefix);

EndFunction

// This function generates the EAN13 barcode for
// a weight product.
//
// Returns:
//  String - Barcode of the weight product.
//
Function GenerateBarcodeOfWeightProductEAN13() Export

	BarcodeNodePrefix = BarcodeNodePrefix();

	Code = GetMaximumCodeValueOfWeightBarcodes();
	
	If Code = Undefined Then
		Common.MessageToUser(MessageTextNoFreeWeightBarcodesCodes());
		Return Undefined;
	EndIf;
	
	Return GetBarcodeOfWeightProductByCode(Code + 1, BarcodeNodePrefix);

EndFunction

// The function returns a barcode generated from a code with prefixes and a control character.
//
// Parameters:
//  Code                  - Number  - code.
//  Span             - String - Range.
//  BarcodeNodePrefix - String - The prefix of the node.
//
// Returns:
//  String - barcode.
//
Function GetBarcodeByCode(Code, Span, BarcodeNodePrefix) Export

	Barcode = String(Span) + BarcodeNodePrefix + Format(Code, "ND=9; NLZ=; NG=");
	Barcode = Barcode + EanControlSymbol(Barcode, 13);

	Return Barcode;

EndFunction

// Returns the barcode of the weight product created from the code with the prefix of the weight product and the control symbol.
//
// Parameters:
//  Code                   - Number  - code.
//  BarcodeNodePrefix - String - The prefix of the weight product.
//  Load              - Boolean - indicates whether it is loading.
//
// Returns:
//  String - Barcode template for a weight product.
//
Function GetBarcodeOfWeightProductByCode(Code, BarcodeNodePrefix = "_", Load = False) Export

	If Load Then
		ProductCode = Format(Code, "ND=5; NLZ=; NG=");
	Else
		ProductCode = String(BarcodeNodePrefix) + Format(Code, "ND=4; NLZ=; NG=");
	EndIf;
	
	Barcode = "2_" + ProductCode + "00000";
	
	EanControlSymbol = "_";
	Barcode = Barcode + EanControlSymbol;

	Return Barcode;

EndFunction

// Returns the default settings for barcode ranges.
//
// Returns:
//	Array of See SettingBarcodeRange.
//
Function DefaultBarcodeRangeSettings() Export
	
	SettingsForBarcodeRanges = New Array;
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(False,	"20"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"21"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"22"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"23"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"24"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"25"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"26"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"27"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"28"));
	SettingsForBarcodeRanges.Add(SettingBarcodeRange(True,	"29"));
	
	Return SettingsForBarcodeRanges;
	
EndFunction

// Returns settings for barcode ranges.
//
// Returns:
//	Array of See SettingBarcodeRange.
//
Function SettingsForBarcodeRanges() Export
	
	Settings = Constants.BarcodePrefixationSettings.Get().Get();
	SettingsForBarcodeRanges = New Array;
	
	If Settings = Undefined Then
		SettingsForBarcodeRanges = DefaultBarcodeRangeSettings();
	Else
		
		Try
			For Each TSRow In Settings Do
				SettingsForBarcodeRanges.Add(SettingBarcodeRange(TSRow.SoldByWeight, TSRow.Span));
			EndDo;
		Except
			MessageText = NStr("vi = 'Lỗi thiết lập cài đặt phạm vi mã vạch. Đã kết nhập tùy chỉnh theo mặc định.';
								|ru = 'Ошибка формата настроек диапазонов штрихкодов. Загружены настройки по умолчанию.';
								|en = 'An error of barcode range setting format. Default settings are imported.'; fa = 'An error of barcode range setting format. Default settings are imported.';
								|it = 'Errore del formato delle impostazioni degli intervalli dei codici a barre. Sono state caricate le impostazioni default.';
								|pl = 'Błąd formatu ustawień kodu kreskowego. Pobrano ustawienia domyślne.';
								|tr = 'Barkod aralık ayarlarının format hatası. Varsayılan ayarlar yüklendi.'");
			
			Common.MessageToUser(MessageText);
			
			SettingsForBarcodeRanges = DefaultBarcodeRangeSettings();
		EndTry
		
	EndIf;
	
	Return SettingsForBarcodeRanges;
	
EndFunction

// Returns the setting of the barcode range according to the specified parameters.
//
// Parameters:
//	SoldByWeight - Boolean - True if the barcode is weighted.
//	Span - String - numeric value of the range.
//
// Returns:
//	Structure - the structure of the barcode range settings for the specified parameters, which contains the properties:
//		* SoldByWeight - Boolean - Truth is a sign that the barcode is weighted.
//		* Span - String - numeric value of the range.
//
Function SettingBarcodeRange(SoldByWeight, Span) Export
	
	SettingBarcodeRange = New Structure("SoldByWeight, Span", SoldByWeight, Span);
	
	Return SettingBarcodeRange;
	
EndFunction

// The function returns an array of the maximum values of individual barcode
// codes by range.
//
// Returns:
//  ValueTable - Maximum values of codes by ranges.
//
Function GetMaximumValuesOfUnitBarcodes() Export
	
	RangesOfUnitBarcodes = SettingsValueCached.RangesOfUnitBarcodes();
	
	If RangesOfUnitBarcodes.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	DescriptionOfNumberType = Common.TypeDescriptionNumber(15, 0);
	
	MaximumValues = New ValueTable();
	MaximumValues.Columns.Add("Code",		DescriptionOfNumberType);
	MaximumValues.Columns.Add("Span",	Common.StringTypeDetails(2));
	
	NodePrefix			= String(Constants.DIBNodeBarcodePrefix.Get());
	QueriesTexts		= New Array;
	LinesOfCodeStart	= New Array;
	
	For Each TSRow In RangesOfUnitBarcodes Do
		
		QueryTextRows =
		"SELECT
		|	""#StringTSRange""							AS Span,
		|	SUBSTRING(ItemsBarcodes.Barcode, 4, 9)	AS CodeString_,
		|	ItemsBarcodes.Barcode					AS Barcode
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|WHERE
		|	ItemsBarcodes.Barcode LIKE ""#LineTSStartOfCode__________""";
		
		LineTSStartOfCode = TSRow.Span + NodePrefix;
		
		QueryTextRows = StrReplace(QueryTextRows, "#StringTSRange", TSRow.Span);
		QueryTextRows = StrReplace(QueryTextRows, "#LineTSStartOfCode", LineTSStartOfCode);
		
		QueriesTexts.Add(QueryTextRows);
		
		StringOfMaximumValue = MaximumValues.Add();
		StringOfMaximumValue.Span	= TSRow.Span;
		StringOfMaximumValue.Code			= 0;
		
		LinesOfCodeStart.Add(LineTSStartOfCode);
		
	EndDo;
	
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	Query.Text = Query.Text + "
	|ORDER BY
	|	CodeString_ DESC";
	
	QueryResult = Query.Execute().Unload();
	
	TestedRanges = New Array;
	NumberOfRanges = MaximumValues.Count();
	
	MaximumUnitProductCode = MaximumUnitProductCode();
	
	For Each TSRow In QueryResult Do
		
		If TestedRanges.Count() = NumberOfRanges Then
			Break;
		ElsIf LinesOfCodeStart.Find(Left(TSRow.Barcode, 3)) = Undefined
			Or TestedRanges.Find(TSRow.Span) <> Undefined Then
			
			Continue;
			
		EndIf;
		
		Code = DescriptionOfNumberType.AdjustValue(TSRow.CodeString_);
		StringOfMaximumValue = MaximumValues.Find(TSRow.Span, "Span");
		
		If Code = 0 Then
			Continue;
		ElsIf Code >= MaximumUnitProductCode Then
			TestedRanges.Add(TSRow.Span);
			MaximumValues.Delete(StringOfMaximumValue);
			
			Continue;
		EndIf;
		
		StringOfMaximumValue.Code = Code;
		
		TestedRanges.Add(TSRow.Span);
		
	EndDo;
	
	Return MaximumValues;
	
EndFunction

// The function returns the maximum value of the weight product code
// from the barcodes registered in the system.
//
// Returns:
//  Number - Maximum product weight code.
//
Function GetMaximumCodeValueOfWeightBarcodes() Export
	
	NodePrefix = String(Constants.DIBNodeBarcodePrefix.Get());
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsBarcodes.Barcode					AS Barcode,
	|	SUBSTRING(ItemsBarcodes.Barcode, 4, 4)	AS CodeString_
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|WHERE
	|	ItemsBarcodes.Barcode LIKE ""2_#Prefix#____00000_""
	|
	|ORDER BY
	|	CodeString_ DESC";
	
	Query.Text = StrReplace(Query.Text, "#NodePrefix#", NodePrefix);
	
	QueryResult = Query.Execute().Unload();
	
	DescriptionOfNumberType				= Common.TypeDescriptionNumber(15, 0);
	NumberOfStringValues		= 0;
	MaximumCodeOfGoodsSoldByWeight	= MaximumCodeOfGoodsSoldByWeight();
	
	LinesOfCodeStart = New Array;
	LinesOfCodeStart.Add("20" + NodePrefix);
	LinesOfCodeStart.Add("21" + NodePrefix);
	LinesOfCodeStart.Add("22" + NodePrefix);
	LinesOfCodeStart.Add("23" + NodePrefix);
	LinesOfCodeStart.Add("24" + NodePrefix);
	LinesOfCodeStart.Add("25" + NodePrefix);
	LinesOfCodeStart.Add("26" + NodePrefix);
	LinesOfCodeStart.Add("27" + NodePrefix);
	LinesOfCodeStart.Add("28" + NodePrefix);
	LinesOfCodeStart.Add("29" + NodePrefix);
	LinesOfCodeStart.Add("2_" + NodePrefix);
	
	ControlCharacters_ = New Array;
	ControlCharacters_.Add("0");
	ControlCharacters_.Add("1");
	ControlCharacters_.Add("2");
	ControlCharacters_.Add("3");
	ControlCharacters_.Add("4");
	ControlCharacters_.Add("5");
	ControlCharacters_.Add("6");
	ControlCharacters_.Add("7");
	ControlCharacters_.Add("8");
	ControlCharacters_.Add("9");
	ControlCharacters_.Add("_");
	
	For Each TSRow In QueryResult Do
		
		If LinesOfCodeStart.Find(Left(TSRow.Barcode, 3)) = Undefined
			Or ControlCharacters_.Find(Right(TSRow.Barcode, 1)) = Undefined Then
			
			NumberOfStringValues = NumberOfStringValues + 1;
			
			Continue;
			
		EndIf;
		
		Code = DescriptionOfNumberType.AdjustValue(TSRow.CodeString_);
		
		If Code >= MaximumCodeOfGoodsSoldByWeight Then
			Continue;
		ElsIf Code = 0 Then
			NumberOfStringValues = NumberOfStringValues + 1;
			
			Continue;
		EndIf;
		
		Return Code;
		
	EndDo;
	
	If MaximumCodeOfGoodsSoldByWeight > 0
		And NumberOfStringValues = QueryResult.Count() Then
		
		Code = 0;
		
		Return Code;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// The function returns the maximum item code.
//
// Returns:
//  Number - The maximum code of a piece product.
//
Function MaximumUnitProductCode() Export
	
	Return 999999999;
	
EndFunction

// The function returns the maximum code of the weight item.
//
// Returns:
//  Number - Maximum product weight code.
//
Function MaximumCodeOfGoodsSoldByWeight() Export
	
	Return 9999;
	
EndFunction

// The update handler UT 11.1.5.7
// 
Procedure FillInConstantsOfBarcodingSubsystem() Export

	SettingsForBarcodeRanges = InformationRegisters.ItemsBarcodes.DefaultBarcodeRangeSettings();
	PrefixOfPieceBarcode = Constants.PrefixOfPieceBarcode.Get();
	
	If ValueIsFilled(TrimAll(PrefixOfPieceBarcode)) Then
		Constants.DIBNodeBarcodePrefix.Set(PrefixOfPieceBarcode);
	Else
		Constants.DIBNodeBarcodePrefix.Set("0");
	EndIf;
	
	Constants.ExportInternalBarcodesOfPieceGoods.Set(True);
	Constants.BarcodePrefixationSettings.Set(New ValueStorage(SettingsForBarcodeRanges));
	
EndProcedure

// Checks the recorded information for the correctness of the indication of the packaging unit for the goods with the policy of accounting for the series
// of items specified occasionally.
//
// Parameters:
//	ItemsBarcodes - FormDataCollection - A table containing information about item barcodes.
//	Cancel - Boolean - indicates that the verification was successful. True - errors were detected during verification.
//	BarcodeIndicationMode - Boolean - a sign of the mode for clarifying information about barcodes. True - the information is specified for
//										one barcode entry.
//
Procedure CheckBatchCompletion(ItemsBarcodes, Cancel, BarcodeIndicationMode = False) Export
	
	If Not GetFunctionalOption("UseItemsBatchWarehouse") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic,
	|	TableOfGoods.Series			AS Series,
	|	TableOfGoods.Package			AS Package
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|WHERE
	|	NOT TableOfGoods.Registered
	|	AND TableOfGoods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND TableOfGoods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|
	|INDEX BY
	|	Products,
	|	Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic,
	|	TableOfGoods.Series			AS Series,
	|	TableOfGoods.Package			AS Package
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON TableOfGoods.Package = Packages.Ref
	|			AND Packages.Denominator <> 0
	|			AND Packages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|
	|WHERE
	|	CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch = FALSE
	|	AND Packages.PackageType <> VALUE(Enum.TypesOfItemsPackages.CargoItem)
	|	AND Packages.Numerator / Packages.Denominator <> 1";
	
	UnloadedColumns = "Registered, Products, Characteristic, Series, Package";
	
	Query.SetParameter("TableOfGoods", ItemsBarcodes.Unload(, UnloadedColumns));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	ColumnsNames = "Products, Characteristic, Series, Package";
	
	TableOfGoods = QueryResult.Unload();
	TableOfGoods.Indexes.Add(ColumnsNames);
	
	RowFilter = New Structure(ColumnsNames);
	
	MessageTemplate = NStr("ru = 'Политика учета серий номенклатуры ""%1"" предусматривает, что серии указываются для каждого экземпляра. Укажите единичную упаковку.';
							|vi = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|en = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.'; fa = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|it = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|pl = 'According to the batch accounting policy of the ""%1"" item, batches are specified for each item. Specify a single packaging unit.';
							|tr = '""%1"" öğe parti takip politikası, partilerin her bir birim için belirtilmesini öngörür. Tekil ambalajı belirtin.'");
	
	LineNumber = 0;
	
	For Each BarcodeString_ In ItemsBarcodes Do
		LineNumber = LineNumber + 1;
		
		If Not (Not BarcodeString_.Registered
			And ValueIsFilled(BarcodeString_.Series)
			And ValueIsFilled(BarcodeString_.Package)) Then
			
			Continue;
			
		EndIf;
		
		FillPropertyValues(RowFilter, BarcodeString_);
		FoundRows = TableOfGoods.FindRows(RowFilter);
		
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
										TrimAll(String(BarcodeString_.Products)),
										TrimAll(String(BarcodeString_.Characteristic)));
		
		MessageText	= StrTemplate(MessageTemplate, ProductPresentation);
		Field			= ?(BarcodeIndicationMode,
							"Package",
							"ItemsBarcodes[" + (LineNumber - 1) + "].Package");
		
		Common.MessageToUser(MessageText, Undefined, Field, "", Cancel);
	EndDo;
	
EndProcedure

// Performs a check of the recorded information for the presence of non-unique records according to the information database.
//
// Parameters:
//	ItemsBarcodes - FormDataCollection - A table containing information about item barcodes.
//	Cancel - Boolean - indicates that the verification was successful. True - errors were detected during verification.
//	BarcodeIndicationMode - Boolean - a sign of the mode for clarifying information about barcodes. True - the information is specified for
//										one barcode entry.
//
Procedure CheckingNonUniqueItemBarcodes(ItemsBarcodes, Cancel, BarcodeIndicationMode = False) Export
	
	QueriesTexts = New Array;
	
	PartOfTheRequestText =
	"SELECT DISTINCT
	|	CAST(Barcodes.Barcode AS STRING(200)) AS Barcode,
	|	Barcodes.Products		AS Products,
	|	Barcodes.Characteristic	AS Characteristic,
	|	Barcodes.Series				AS Series,
	|	Barcodes.Package			AS Package
	|INTO BarcodesInformation
	|FROM
	|	&BarcodeData_ AS Barcodes
	|WHERE
	|	NOT Barcodes.Registered
	|
	|INDEX BY
	|	Barcode,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package";
	QueriesTexts.Add(PartOfTheRequestText);
	
	If GetFunctionalOption("UseNonUniqueItemBarcodes") Then
		PartOfTheRequestText =
		"SELECT TOP 1
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN BarcodesInformation AS BarcodesInformation
		|		ON ItemsBarcodes.Barcode = BarcodesInformation.Barcode
		|		
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		INNER JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND UniquenessControlDetails.Uniqueness
		|WHERE
		|	NOT (ItemsBarcodes.Products, ItemsBarcodes.Characteristic, ItemsBarcodes.Series, ItemsBarcodes.Package) IN
		|			(SELECT
		|				Barcodes.Products		AS Products,
		|				Barcodes.Characteristic	AS Characteristic,
		|				Barcodes.Series				AS Series,
		|				Barcodes.Package			AS Package
		|			FROM
		|				BarcodesInformation AS Barcodes
		|			WHERE
		|				Barcodes.Barcode = ItemsBarcodes.Barcode)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN BarcodesInformation AS BarcodesInformation
		|		ON ItemsBarcodes.Barcode = BarcodesInformation.Barcode
		|		
		|		INNER JOIN Catalog.Products AS CatalogProducts
		|		ON ItemsBarcodes.Products = CatalogProducts.Ref
		|		
		|		LEFT JOIN Catalog.ItemKinds.AttributesForProductsControl AS UniquenessControlDetails
		|		ON CatalogProducts.ProductKind = UniquenessControlDetails.Ref
		|			AND UniquenessControlDetails.AttributeName = &PropsNameBarcode
		|			AND NOT UniquenessControlDetails.Uniqueness
		|WHERE
		|	NOT ISNULL(UniquenessControlDetails.Uniqueness, FALSE)
		|	AND NOT (ItemsBarcodes.Products, ItemsBarcodes.Characteristic, ItemsBarcodes.Series, ItemsBarcodes.Package) IN
		|			(SELECT
		|				Barcodes.Products		AS Products,
		|				Barcodes.Characteristic	AS Characteristic,
		|				Barcodes.Series				AS Series,
		|				Barcodes.Package			AS Package
		|			FROM
		|				BarcodesInformation AS Barcodes
		|			WHERE
		|				Barcodes.Barcode = ItemsBarcodes.Barcode)
		|	AND TRUE IN
		|			(SELECT
		|				TRUE
		|			FROM
		|				BarcodesInformation AS Barcodes
		|					INNER JOIN Catalog.Products AS CatalogProducts
		|					ON Barcodes.Products = CatalogProducts.Ref
		|					
		|					INNER JOIN Catalog.ItemKinds.AttributesForProductsControl AS ControlAttributes
		|					ON CatalogProducts.ProductKind = ControlAttributes.Ref
		|						AND ControlAttributes.AttributeName = &PropsNameBarcode
		|						AND ControlAttributes.Uniqueness
		|			WHERE
		|				Barcodes.Barcode = ItemsBarcodes.Barcode)
		|";
	Else
		PartOfTheRequestText =
		"SELECT
		|	ItemsBarcodes.Barcode						AS Barcode,
		|	PRESENTATION(ItemsBarcodes.Products)	AS Products,
		|	PRESENTATION(ItemsBarcodes.Characteristic)	AS Characteristic,
		|	PRESENTATION(ItemsBarcodes.Series)			AS Series,
		|	PRESENTATION(ItemsBarcodes.Package)		AS Package
		|FROM
		|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
		|		INNER JOIN BarcodesInformation AS BarcodesInformation
		|		ON ItemsBarcodes.Barcode = BarcodesInformation.Barcode
		|WHERE
		|	NOT (ItemsBarcodes.Products, ItemsBarcodes.Characteristic, ItemsBarcodes.Series, ItemsBarcodes.Package) IN
		|			(SELECT
		|				Barcodes.Products		AS Products,
		|				Barcodes.Characteristic	AS Characteristic,
		|				Barcodes.Series				AS Series,
		|				Barcodes.Package			AS Package
		|			FROM
		|				BarcodesInformation AS Barcodes)";
	EndIf;
	
	QueriesTexts.Add(PartOfTheRequestText);
	
	Query = New Query;
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	UnloadedColumns = "Registered, Barcode, Products, Characteristic, Series, Package";
	
	Query.SetParameter("PropsNameBarcode",	"Barcode");
	Query.SetParameter("BarcodeData_",		ItemsBarcodes.Unload(, UnloadedColumns));
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BarcodeData_5 = QueryResult.Unload();
	BarcodeData_5.Indexes.Add("Barcode");
	
	MessageTextTemplate = NStr("ru = 'Такой штрихкод уже назначен для номенклатуры %1.';
								|vi = 'Such barcode is already specified  for the %1 item.';
								|en = 'Such barcode is already specified  for the %1 item.'; fa = 'Such barcode is already specified  for the %1 item.';
								|it = 'Such barcode is already specified  for the %1 item.';
								|pl = 'Such barcode is already specified  for the %1 item.';
								|tr = 'Bu barkod, %1 öğe için zaten atanmış.'");
	
	LineNumber = 0;
	
	For Each BarcodeString_ In ItemsBarcodes Do
		LineNumber = LineNumber + 1;
		
		If BarcodeString_.Registered Then
			Continue;
		EndIf;
		
		RegisterRecord = BarcodeData_5.Find(BarcodeString_.Barcode, "Barcode");
		
		If RegisterRecord = Undefined Then
			Continue;
		EndIf;
		
		ItemRepresentations = New Array;
		
		ItemsTemplate = NStr("vi = '""%1""';
							|ru = '""%1""';
							|en = '""%1""'; fa = '""%1""';
							|it = '""%1""';
							|pl = '""%1""';
							|tr = '""%1""'");
		
		ProductPresentation = ProductsClientServer.ProductPresentation(
										TrimAll(RegisterRecord.Products),
										TrimAll(RegisterRecord.Characteristic));
		ProductPresentation = StrTemplate(ItemsTemplate, ProductPresentation);
		ItemRepresentations.Add(ProductPresentation);
		
		If Not IsBlankString(RegisterRecord.Series) Then
			BatchPresentation = NStr("ru = 'с серией ""%1""';
									|vi = 'with batch %1';
									|en = 'with batch %1'; fa = 'with batch %1';
									|it = 'with batch %1';
									|pl = 'with batch %1';
									|tr = '""%1"" partisi ile'");
			BatchPresentation = StrTemplate(BatchPresentation, TrimAll(RegisterRecord.Series));
			
			ItemRepresentations.Add(BatchPresentation);
		EndIf;
		
		If Not IsBlankString(RegisterRecord.Package) Then
			PackagingPresentation = NStr("ru = 'в упаковке ""%1""';
										|vi = 'in the ""%1"" packaging unit';
										|en = 'in the ""%1"" packaging unit'; fa = 'in the ""%1"" packaging unit';
										|it = 'in the ""%1"" packaging unit';
										|pl = 'in the ""%1"" packaging unit';
										|tr = '""%1"" ambalajında'");
			PackagingPresentation = StrTemplate(PackagingPresentation, TrimAll(RegisterRecord.Package));
			
			ItemRepresentations.Add(PackagingPresentation);
		EndIf;
		
		MessageText = StrTemplate(MessageTextTemplate, StrConcat(ItemRepresentations, " "));
		Field			= ?(BarcodeIndicationMode,
							"Barcode",
							"ItemsBarcodes[" + (LineNumber - 1) + "].Barcode");
		
		Common.MessageToUser(MessageText, Undefined, Field, "", Cancel);
	EndDo;
	
EndProcedure

// Registers the barcodes of the labels of the item series. Updates the information of cached values by barcodes.
//
// Parameters:
//	BatchBarcodes - Array of String - collection of barcodes of item label series.
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//
Procedure RegisterBarcodesOfLabelsOfBatchesOfItems(BatchBarcodes, CachedValues) Export
	
	BarcodeData_ = BarcodesDataTable();
	
	For Each Barcode In BatchBarcodes Do
		BarcodeData_1 = CachedValues.Barcodes.Get(Barcode);
		
		If BarcodeData_1 = Undefined Then
			Continue;
		EndIf;
		
		NewRow = BarcodeData_.Add();
		FillPropertyValues(NewRow, BarcodeData_1);
	EndDo;
	
	If Not CachedValues.ProductBarcodeRegistrationRightIsAvailable Then
		SetPrivilegedMode(True);
	EndIf;
	
	HasErrors = False;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.ItemsBarcodes");
		LockItem.DataSource = BarcodeData_;
		
		LockItem.UseFromDataSource("Barcode",			"Barcode");
		LockItem.UseFromDataSource("Products",		"Products");
		LockItem.UseFromDataSource("Characteristic",	"Characteristic");
		LockItem.UseFromDataSource("Series",			"Series");
		LockItem.UseFromDataSource("Package",			"Package");
		
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		RecordSet.Load(BarcodeData_);
		RecordSet.Write(ReplacementMode.Merge);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		HasErrors = True;
		
		EventText = NStr("ru = 'Регистрация штрихкодов этикеток серий номенклатуры.';
						|vi = 'Register barcodes of item batch labels.';
						|en = 'Register barcodes of item batch labels.'; fa = 'Register barcodes of item batch labels.';
						|it = 'Register barcodes of item batch labels.';
						|pl = 'Register barcodes of item batch labels.';
						|tr = 'Öğe serileri etiketlerinin barkod kaydı.'");
		
		ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		Comment = NStr("ru = 'Не удалось зарегистрировать штрихкоды номенклатуры по причине: %1';
						|vi = 'Cannot register item barcodes due to: %1';
						|en = 'Cannot register item barcodes due to: %1'; fa = 'Cannot register item barcodes due to: %1';
						|it = 'Cannot register item barcodes due to: %1';
						|pl = 'Cannot register item barcodes due to: %1';
						|tr = 'Öğe barkodları şu nedenden dolayı tescil edilemedi: %1'");
		Comment = StrTemplate(Comment, ErrorText);
		
		WriteLogEvent(
			EventText,
			EventLogLevel.Error,
			Metadata.InformationRegisters.ItemsBarcodes,
			,
			Comment);
		
	EndTry;
	
	If HasErrors Then
		Return;
	EndIf;
	
	For Each Barcode In BatchBarcodes Do
		BarcodeData_1 = CachedValues.Barcodes.Get(Barcode);
		
		If BarcodeData_1 = Undefined Then
			Continue;
		EndIf;
		
		BarcodeData_1.ItemsBarcode = True;
	EndDo;
	
EndProcedure

// Registers information about item barcodes.
//
// Parameters:
//	ItemsBarcodes - ValueTable - collection of information about item barcodes.
//
Procedure RegisterProductsBarcodes(ItemsBarcodes) Export
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add("InformationRegister.ItemsBarcodes");
		LockItem.DataSource = ItemsBarcodes;
		
		LockItem.UseFromDataSource("Barcode",			"Barcode");
		LockItem.UseFromDataSource("Products",		"Products");
		LockItem.UseFromDataSource("Characteristic",	"Characteristic");
		LockItem.UseFromDataSource("Series",			"Series");
		LockItem.UseFromDataSource("Package",			"Package");
		
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		RecordSet.Load(ItemsBarcodes);
		RecordSet.Write(ReplacementMode.Merge);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		Raise;
	EndTry;
	
EndProcedure

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
//
// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowRead
	|WHERE TRUE
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ValueAllowed(Products)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ItemsBarcodes.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.73";
	Handler.ExecutionMode = "Deferred";
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.Id = New UUID("21caedb2-58d8-43d1-8eff-3cc479fa23c8");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.ItemsBarcodes.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Crucial;
	Handler.Comment = NStr("ru = 'Выполняет перенос сведений из ресурсов ""Номенклатура"", ""Характеристика"" и ""Упаковка"" регистра сведений ""Штрихкоды номенклатуры"" в добавленные одноименные измерения.';
							|vi = 'Transfers information records from the ""Item"", ""Variant"" and ""Packaging unit"" resources of the ""Item barcodes"" information register to the added dimensions of the same name.';
							|en = 'Transfers information records from the ""Item"", ""Variant"" and ""Packaging unit"" resources of the ""Item barcodes"" information register to the added dimensions of the same name.'; fa = 'Transfers information records from the ""Item"", ""Variant"" and ""Packaging unit"" resources of the ""Item barcodes"" information register to the added dimensions of the same name.';
							|it = 'Transfers information records from the ""Item"", ""Variant"" and ""Packaging unit"" resources of the ""Item barcodes"" information register to the added dimensions of the same name.';
							|pl = 'Transfers information records from the ""Item"", ""Variant"" and ""Packaging unit"" resources of the ""Item barcodes"" information register to the added dimensions of the same name.';
							|tr = '""Öğe barkodları"" bilgi kaydının ""Öğe"", ""Varyant"" ve ""Ambalaj"" kaynaklarındaki verileri eklenen aynı adlı boyutlara aktarır.'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.ItemsBarcodes.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.ItemsBarcodes.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers register entries for processing.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export 
	
	FullRegisterName = "InformationRegister.ItemsBarcodes";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ObjectData.Barcode AS Barcode
	|FROM
	|	InformationRegister.ItemsBarcodes AS ObjectData
	|WHERE
	|	ObjectData.Products = VALUE(Catalog.Products.EmptyRef)
	|	AND ObjectData.NotUsedItem <> VALUE(Catalog.Products.EmptyRef)";
	
	InfobaseUpdate.MarkForProcessing(Parameters,
													Query.Execute().Unload(),
													AdditionalParameters);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.ItemsBarcodes.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																							FullRegisterName);
		
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ObjectData.Barcode				AS Barcode,
	|	ObjectData.NotUsedItem	AS Products,
	|	ObjectData.DeleteItemVariant	AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	ObjectData.DeletePackage		AS Package,
	|	ObjectData.NotUsedItem	AS NotUsedItem,
	|	ObjectData.DeleteItemVariant	AS DeleteItemVariant,
	|	ObjectData.DeletePackage		AS DeletePackage
	|FROM
	|	InformationRegister.ItemsBarcodes AS ObjectData
	|WHERE
	|	ObjectData.Barcode IN (&ProcessedBarcodes)
	|	AND ObjectData.Products = VALUE(Catalog.Products.EmptyRef)
	|	AND ObjectData.NotUsedItem <> VALUE(Catalog.Products.EmptyRef)";
	
	Query.SetParameter("ProcessedBarcodes", UpdatedData.UnloadColumn("Barcode"));
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;
	
	Block = New DataLock;
	LockItem = Block.Add(FullRegisterName);
	LockItem.DataSource = UpdatedData;
	
	LockItem.UseFromDataSource("Barcode",			"Barcode");
	LockItem.UseFromDataSource("Products",		"Products");
	LockItem.UseFromDataSource("Characteristic",	"Characteristic");
	LockItem.UseFromDataSource("Series",			"Series");
	LockItem.UseFromDataSource("Package",			"Package");
	
	ThereIsBadData = False;
	
	BeginTransaction();
	
	Try
		Block.Lock();
		
		QueryResults = Query.Execute();
		
		RecordSet = CreateRecordSet();
		
		RecordSet.DataExchange.Load = True;
		RecordSet.DataExchange.Recipients.AutoFill = False;
		
		RecordSet.Load(UpdatedData);
		RecordSet.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB", False);
		
		RecordSet.Write(ReplacementMode.Delete);
		
		If Not QueryResults.IsEmpty() Then
			RecordSet = CreateRecordSet();
			RecordSet.Load(QueryResults.Unload());
			
			InfobaseUpdate.WriteRecordSet(RecordSet, False);
		EndIf;
		
		InfobaseUpdate.MarkProcessingCompletion(UpdatedData, AdditionalParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ThereIsBadData = True;
		
		MessageText = NStr("vi = 'Không thể cập nhật dữ liệu trong biểu ghi %1 do nguyên nhân: %2';
							|ru = 'Не удалось обновить данные в регистре %1 по причине: %2';
							|en = 'Cannot update data in the %1 register due to: %2'; fa = 'Cannot update data in the %1 register due to: %2';
							|it = 'Cannot update data in the %1 register due to: %2';
							|pl = 'Cannot update data in the %1 register due to: %2';
							|tr = '%1 kaydındaki veriler şu nedenden dolayı güncellenemedi: %2'");
		MessageText = StrTemplate(MessageText,
									FullRegisterName,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
									EventLogLevel.Warning,
									Metadata.InformationRegisters.ItemsBarcodes,
									,
									MessageText);
	EndTry;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать записи регистра сведений ""Штрихкоды номенклатуры"".';
								|vi = 'Cannot process the ""Item barcodes"" information register records.';
								|en = 'Cannot process the ""Item barcodes"" information register records.'; fa = 'Cannot process the ""Item barcodes"" information register records.';
								|it = 'Cannot process the ""Item barcodes"" information register records.';
								|pl = 'Cannot process the ""Item barcodes"" information register records.';
								|tr = '""Öğe barkodları"" bilgi kaydının kayıtları işlenemedi.'"));
	
	If ThereIsBadData Then
		
		For Each RegisterRecord In UpdatedData Do
			BeginTransaction();
			
			Try
				ExceptionReason = "Block";
				
				Block = New DataLock;
				
				LockItem = Block.Add(FullRegisterName);
				LockItem.SetValue("Barcode", RegisterRecord.Barcode);
				LockItem.Mode = DataLockMode.Exclusive;
				
				Block.Lock();
				
				RecordSet = InformationRegisters.ItemsBarcodes.CreateRecordSet();
				RecordSet.Filter.Barcode.Set(RegisterRecord.Barcode);
				RecordSet.Read();
				
				For Each SetRecord In RecordSet Do
					If Not ValueIsFilled(SetRecord.Products)
						And ValueIsFilled(SetRecord.NotUsedItem) Then
						
						SetRecord.Products = SetRecord.NotUsedItem;
						
					EndIf;
					
					If Not ValueIsFilled(SetRecord.Characteristic)
						And ValueIsFilled(SetRecord.DeleteItemVariant) Then
						
						SetRecord.Characteristic = SetRecord.DeleteItemVariant;
						
					EndIf;
					
					If Not ValueIsFilled(SetRecord.Package)
						And ValueIsFilled(SetRecord.DeletePackage) Then
						
						SetRecord.Package = SetRecord.DeletePackage;
						
					EndIf;
				EndDo;
				
				ExceptionReason = "Record";
				
				If RecordSet.Modified() Then
					InfobaseUpdate.WriteRecordSet(RecordSet);
				Else
					InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				EndIf;
				
				ObjectsProcessed = ObjectsProcessed + 1;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				
				ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
				
				MessageText = NStr("vi = 'Không thể cập nhật dữ liệu trong biểu ghi %1 do nguyên nhân: %2';
									|ru = 'Не удалось обновить данные в регистре %1 по причине: %2';
									|en = 'Cannot update data in the %1 register due to: %2'; fa = 'Cannot update data in the %1 register due to: %2';
									|it = 'Cannot update data in the %1 register due to: %2';
									|pl = 'Cannot update data in the %1 register due to: %2';
									|tr = '%1 kaydındaki veriler şu nedenden dolayı güncellenemedi: %2'");
				MessageText = StrTemplate(MessageText,
											FullRegisterName,
											ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(InfobaseUpdate.EventLogEvent(),
											EventLogLevel.Warning,
											Metadata.InformationRegisters.ItemsBarcodes,
											,
											MessageText);
				
				If ExceptionReason = "Record" Then
					InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating,
																		ObjectsProcessed,
																		Parameters);
					
					Raise StrConcat(ListOfDescriptions, Chars.LF);
				EndIf;
				
			EndTry;
			
		EndDo;
		
	EndIf;
	
	If ObjectsProcessed = 0
		And ObjectsWithIssuesCount <> 0 Then
		
		ListOfDescriptions.Add(NStr("vi = 'Tổng số bỏ qua: %1';
									|ru = 'Всего пропущено: %1';
									|en = 'Skipped: %1'; fa = 'Skipped: %1';
									|it = 'Всего пропущено: %1';
									|pl = 'Skipped: %1';
									|tr = 'Toplam atlanan: %1'"));
		
		MessageText = StrTemplate(StrConcat(ListOfDescriptions, Chars.LF), String(ObjectsWithIssuesCount));
		
		Raise MessageText;
		
	EndIf;
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																						FullRegisterName);
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTableParts

// Adds a request to the request package to check the presence of the item barcode based on the measurement values
// of the Item Barcode information register.
//
// Parameters:
//	StructureOfActions - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	QueryDetails - See BatchProcessingOfTablePartServer.QueryDetails.
//	CachedValues - Structure
//
Procedure CompleteQueryTextCheckBarcodeRegistration(StructureOfActions, QueryDetails, CachedValues) Export
	
	Var ActionParameters;
	
	If BatchProcessingOfTablePartServer.YouNeedToPerformAction(
			"CheckBarcodeRegistration",
			StructureOfActions,
			CachedValues,
			ActionParameters) Then
		
		ListOfRequests = QueryTextsCheckBarcodeRegistration();
		
		For Each ListItem In ListOfRequests Do
			QueryDetails.QueriesTexts.Add(ListItem.Value, ListItem.Presentation);
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Other

// Caches information about item barcodes, based on the data found in the information database, based on the transmitted
// collection of barcodes.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	Barcodes - Array of String - barcodes for which you need to get information.
//	ReceiveNonUniqueBarcodes - Boolean - indicates whether data about non-unique item barcodes is received.
//
Procedure GetDataOnBarcodesOfBatchLabels(CachedValues, Barcodes, ReceiveNonUniqueBarcodes)
	
	If Not GetFunctionalOption("UseItemsBatchWarehouse") Then
		Return;
	EndIf;
	
	ArrayOfBarcodes		= New Array;
	DataOnBatchBarcodes	= TableDataOnBatchBarcodes();
	
	// Some of the barcodes were processed earlier according to the information register.
	For Each CurBarcode In Barcodes Do
		Barcode			= Upper(TrimAll(CurBarcode));
		BarcodeData	= CachedValues.Barcodes[Barcode];
		
		If TypeOf(BarcodeData) = Type("Array") Then
			Continue;
		ElsIf Not BarcodeData.UnknownBarcode Then
			Continue;
		EndIf;
		
		SeriesInformation = BarcodingOfItemsServer.SeriesInformationFromBarcode(Barcode, True, True, False);
		
		If SeriesInformation.HasError Then
			Continue;
		EndIf;
		
		NewRow = DataOnBatchBarcodes.Add();
		NewRow.Barcode	= Barcode;
		NewRow.BatchNumber	= SeriesInformation.Number;
		NewRow.ValidUntil_		= SeriesInformation.ValidUntil_;
		
		ArrayOfBarcodes.Add(Barcode);
	EndDo;
	
	If DataOnBatchBarcodes.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Barcodes.Barcode		AS Barcode,
	|	Barcodes.BatchNumber	AS BatchNumber,
	|	Barcodes.ValidUntil_		AS ValidUntil_
	|INTO SeriesData_
	|FROM
	|	&ItemsBarcodes AS Barcodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SeriesData_.Barcode				AS Barcode,
	|	GoodsBatchMovement.Products	AS Products,
	|	GoodsBatchMovement.Characteristic	AS Characteristic,
	|	GoodsBatchMovement.Series			AS Series
	|INTO DataOfRegisteredRecordedBatches
	|FROM
	|	AccumulationRegister.GoodsBatchMovement AS GoodsBatchMovement
	|		INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|		ON GoodsBatchMovement.Series = ItemsBatches.Ref
	|		
	|		INNER JOIN SeriesData_ AS SeriesData_
	|		ON ItemsBatches.Number = SeriesData_.BatchNumber
	|			AND ItemsBatches.ValidUntil_ = SeriesData_.ValidUntil_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Barcodes.Barcode				AS Barcode,
	|	COUNT(Barcodes.Barcode)	AS NumberOfBarcodes
	|INTO BarcodesInformation
	|FROM
	|	DataOfRegisteredRecordedBatches AS Barcodes
	|
	|GROUP BY
	|	Barcodes.Barcode
	|
	|INDEX BY
	|	Barcode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BarcodesInformation.Barcode					AS Barcode,
	|	ItemsBarcodes.Products				AS Products,
	|	CatalogProducts.ItemsType			AS ItemsType,
	|	&DetailsOfItemSelection,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.BatchOwner, UNDEFINED) = VALUE(Catalog.ItemKinds.EmptyRef)
	|			THEN CatalogProducts.ProductKind.SpecifyQuantityWhenRegisteringBatch
	|		ELSE CatalogProducts.BatchOwner.SpecifyQuantityWhenRegisteringBatch
	|	END											AS SpecifyQuantityWhenRegisteringBatch,
	|	ItemsBarcodes.Characteristic			AS Characteristic,
	|	ItemsBarcodes.Series						AS Series,
	|	TRUE											AS SeriesAreUsed,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	FALSE											AS CargoItem,
	|	PRESENTATION(ItemsBarcodes.Products) AS ProductsPresentation,
	|	PRESENTATION(ItemsBarcodes.Characteristic) AS CharacteristicPresentation,
	|	1												AS ZoomRatio,
	|	CASE
	|		WHEN ISNULL(CatalogProducts.UseVariants, UNDEFINED) = VALUE(Enum.ItemVariantsUsageOptions.DontUse)
	|			THEN FALSE
	|		ELSE TRUE
	|	END											AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN CatalogProducts.SuppliedInReusablePackage
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS SuppliedInReusablePackage,
	|	CatalogProducts.UsePackages		AS UsePackages,
	|	UNDEFINED									AS SinglePackaging,
	|	0												AS NumberOfSinglePackages,
	|	CASE
	|		WHEN ProductKitConfigurations.SetPricingOption IS NULL
	|			THEN VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		ELSE ProductKitConfigurations.SetPricingOption
	|	END											AS SetPricingOption,
	|	CatalogProducts.UnitOfMeasure			AS UnitOfMeasure,
	|	BarcodesInformation.NumberOfBarcodes > 1	AS NonUniqueBarcode,
	|	FALSE											AS ItemsBarcode
	|FROM
	|	BarcodesInformation AS BarcodesInformation
	|		INNER JOIN DataOfRegisteredRecordedBatches AS ItemsBarcodes
	|		ON BarcodesInformation.Barcode = ItemsBarcodes.Barcode
	|		
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON ItemsBarcodes.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ItemsBarcodes.Products = ProductKitConfigurations.Owner
	|			AND ItemsBarcodes.Characteristic = ProductKitConfigurations.Characteristic
	|			AND ProductKitConfigurations.Main
	|	, ConnectionTable";
	
	QueryTextsForItemDetails = ProductsLocalization.QueryTextsForItemDetails();
	ProductsLocalization.FillInQueryTextDetailsOfItem(
		"CatalogProducts",
		QueryTextsForItemDetails);
	
	Query.Text = StrReplace(Query.Text,
								"&DetailsOfItemSelection",
								QueryTextsForItemDetails.DetailsOfItemSelection);
	Query.Text = StrReplace(Query.Text,
								", ConnectionTable",
								QueryTextsForItemDetails.DetailsOfConnectionNomenclature);
	
	Query.SetParameter("ItemsBarcodes", DataOnBatchBarcodes);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	BarcodeData_ = QueryResult.Unload();
	BarcodeData_.Indexes.Add("Barcode");
	
	FillInCachedValuesAccordingToInfobaseData(CachedValues,
											BarcodeData_,
											ArrayOfBarcodes,
											ReceiveNonUniqueBarcodes);
	
EndProcedure

// Returns an empty table containing a description of the barcode information of the series.
//
// Returns:
//	ValueTable - an empty table containing a description of the item barcodes:
//		* Barcode - String - The item barcode.
//		* Series - CatalogRef.ItemsBatches - a series of Products.
//		* BatchNumber - DefinedType.BatchNumber - the serial number of the item.
//		* ValidUntil_ - Date - expiration date of a series of items.
//
Function TableDataOnBatchBarcodes()
	
	DataOnBatchBarcodes = New ValueTable;
	DataOnBatchBarcodes.Columns.Add("Barcode",
											Metadata.InformationRegisters.ItemsBarcodes.Dimensions.Barcode.Type);
	DataOnBatchBarcodes.Columns.Add("BatchNumber",
											Metadata.DefinedTypes.BatchNumber.Type);
	DataOnBatchBarcodes.Columns.Add("ValidUntil_",
											New TypeDescription("Date"));
	
	Return DataOnBatchBarcodes;
	
EndFunction

// Returns an empty table containing a description of the item's barcode information.
//
// Returns:
//	ValueTable - an empty table containing a description of the item barcodes:
//		* Barcode - String - The item barcode.
//		* Products - CatalogRef.Products - Nomenclature.
//		* Characteristic - CatalogRef.ItemsCharacteristics - Characteristics of the item.
//		* Series - CatalogRef.ItemsBatches - a series of Products.
//		* Package - CatalogRef.PackagesAndUnitsOfMeasure - Item packaging units.
//
Function BarcodesDataTable()
	
	BarcodeData_ = New ValueTable;
	BarcodeData_.Columns.Add("Barcode",
										Metadata.InformationRegisters.ItemsBarcodes.Dimensions.Barcode.Type);
	BarcodeData_.Columns.Add("Products",
										New TypeDescription("CatalogRef.Products"));
	BarcodeData_.Columns.Add("Characteristic",
										New TypeDescription("CatalogRef.ItemsCharacteristics"));
	BarcodeData_.Columns.Add("Series",
										New TypeDescription("CatalogRef.ItemsBatches"));
	BarcodeData_.Columns.Add("Package",
										New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	Return BarcodeData_;
	
EndFunction

// Fills the collection of cached values with information security data.
//
// Parameters:
//	CachedValues - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	BarcodeData_ - ValueTable - a table containing the result of receiving data from information security.
//	Barcodes - Array of String - barcodes for which you need to get information.
//	ReceiveNonUniqueBarcodes - Boolean - indicates whether data about non-unique item barcodes is received.
//
Procedure FillInCachedValuesAccordingToInfobaseData(CachedValues, BarcodeData_, Barcodes, ReceiveNonUniqueBarcodes)
	
	RowFilter = New Structure("Barcode");
	
	For Each CurBarcode In Barcodes Do
		Barcode			= Upper(TrimAll(CurBarcode));
		RowFilter.Barcode	= Barcode;
		FoundRows		= BarcodeData_.FindRows(RowFilter);
		DataVolume	= FoundRows.Count();
		
		If DataVolume = 0 Then
			Continue;
		ElsIf ReceiveNonUniqueBarcodes Then
			BarcodeData_1 = New Array;
			
			For Each BarcodeString_ In FoundRows Do
				BarcodeInformation_ = BatchProcessingOfTablePartClientServer.CachedInformationStructureByBarcode();
				FillInBarcodeInformation(BarcodeInformation_, BarcodeString_);
				
				BarcodeData_1.Add(BarcodeInformation_);
			EndDo;
			
			CachedValues.Barcodes.Insert(Barcode, BarcodeData_1);
		Else
			BarcodeInformation_ = CachedValues.Barcodes[Barcode];
			
			If DataVolume > 1 Then
				BarcodeInformation_.NonUniqueBarcode = True;
			ElsIf DataVolume = 1 Then
				FillInBarcodeInformation(BarcodeInformation_, FoundRows[0]);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Fills in the barcode information with information security data.
//
// Parameters:
//	BarcodeInformation_ - See BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues.
//	BarcodeData_1 - ValueTableRow, QueryResultSelection - information about the item barcode.
//
Procedure FillInBarcodeInformation(BarcodeInformation_, BarcodeData_1)
	
	FillPropertyValues(BarcodeInformation_, BarcodeData_1);
	
	BarcodeInformation_.Barcode						= Upper(TrimAll(BarcodeData_1.Barcode));
	BarcodeInformation_.NumberOfPackages			= 1;
	BarcodeInformation_.SinglePackaging				= ?(BarcodeData_1.NumberOfSinglePackages = 1
																And BarcodeData_1.ZoomRatio = 1,
															BarcodeData_1.SinglePackaging,
															Undefined);
	BarcodeInformation_.MultipleUnitPackages	= BarcodeData_1.NumberOfSinglePackages > 1
															And Not BarcodeData_1.CargoItem;
	BarcodeInformation_.UnknownBarcode			= False;
	BarcodeInformation_.ProductPresentation		= ProductsClientServer.PresentationOfProductsForPrinting(
															BarcodeData_1.ProductsPresentation,
															BarcodeData_1.CharacteristicPresentation);
	
EndProcedure

#EndRegion

#Region BatchProcessingOfTablePartsIsService

// Returns a list of requests to check the registration of the item barcode in the information database.
//
// Returns:
// 	ValueList of String
//
Function QueryTextsCheckBarcodeRegistration()
	
	Result = New ValueList;
	
	QueryText =
	"SELECT
	|	TTDataSource.IdOfTTRow	AS IdOfTTRow,
	|	CASE
	|		WHEN ItemsBarcodes.Barcode IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END									AS Registered
	|FROM
	|	TTDataSource AS TTDataSource
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON TTDataSource.Barcode = ItemsBarcodes.Barcode
	|			AND TTDataSource.Products = ItemsBarcodes.Products
	|			AND TTDataSource.Characteristic = ItemsBarcodes.Characteristic
	|			AND TTDataSource.Series = ItemsBarcodes.Series
	|			AND TTDataSource.Package = ItemsBarcodes.Package";
	
	Result.Add(QueryText, "CheckBarcodeRegistration");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#EndIf