#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  FillingText - String - This parameter is passed to indicate that standard (system) event processing is performed.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, FillingText, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	
	Return;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command to create a "document Production order".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
EndProcedure

#EndRegion

#Region Print

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	
EndProcedure

// The function receives data for forming the MX - 18 printing form
// 
// Parameters:
// 	PrintParameters - Structure
// 	ObjectsArray - Array
// Returns:
// 	Structure
Function GetDataForPrintingPlateMX18(PrintParameters, ObjectsArray) Export
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	If Not ValueIsFilled(ColumnOfCodes) Then
		ColumnOfCodes = "Code";
	EndIf;
	
	Query = New Query;

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	DateOfMigrationToPriceManagementSystem25 = PriceManagementSystemServerCall.DateOfTransitionToPricingVersion25();

	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref
	|INTO PrintingDocuments
	|FROM
	|	Document.BackflushProduction AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|	AND TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.BackflushProduction.ManufacturedProducts AS ProductTable_
	|				INNER JOIN Catalog.Warehouses AS CatWarehouses
	|				ON ProductTable_.Recipient = CatWarehouses.Ref
	|		WHERE
	|			ProductTable_.Ref = DocumentData.Ref
	|			AND NOT CatWarehouses.ShopFloorStockroom
	|
	|		UNION ALL
	|
	|		SELECT
	|			TRUE
	|		FROM
	|			Document.BackflushProduction.SideAndIntermediateRelease AS ProductTable_
	|				INNER JOIN Catalog.Warehouses AS CatWarehouses
	|				ON ProductTable_.Recipient = CatWarehouses.Ref
	|		WHERE
	|			ProductTable_.Ref = DocumentData.Ref
	|			AND NOT CatWarehouses.ShopFloorStockroom)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref                          AS Ref,
	|	GoodsTable.CostGroupNumber               AS CostGroupNumber,
	|	MAX(GoodsTable.InternalSubcontracting) AS InternalSubcontracting,
	|	MAX(GoodsTable.MaterialProviderCompany)    AS MaterialProviderCompany
	|INTO CostGroups
	|FROM
	|	PrintingDocuments AS PrintingDocuments
	|	
	|	INNER JOIN Document.BackflushProduction.ManufacturedProducts AS GoodsTable
	|	ON GoodsTable.Ref = PrintingDocuments.Ref
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.CostGroupNumber
	|
	|INDEX BY
	|	Ref,
	|	CostGroupNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                            AS Ref,
	|	Goods.Organization                       AS Organization,
	|	Goods.PMNumber                           AS PMNumber,
	|	MIN(Goods.LineNumber)              AS LineNumber,
	|	Goods.Warehouse                             AS Warehouse,
	|	Goods.Products                      AS Products,
	|	Goods.Characteristic                    AS Characteristic,
	|	Goods.Series                             AS Series,
	|	Goods.Package                          AS Package,
	|	SUM(Goods.NumberOfPackages)         AS NumberOfPackages,
	|	Goods.DateOfPriceReceipt                 AS DateOfPriceReceipt
	|INTO Goods
	|FROM
	|	(SELECT
	|		Goods.Ref                            AS Ref,
	|		CASE
	|			WHEN Goods.InternalSubcontracting
	|				THEN Goods.MaterialProviderCompany
	|			WHEN TRUE
	|				THEN Goods.Ref.Organization
	|		END                                    AS Organization,
	|		1                                        AS PMNumber,
	|		Goods.LineNumber                       AS LineNumber,
	|		Goods.Recipient                        AS Warehouse,
	|		Goods.Products                      AS Products,
	|		Goods.Characteristic                    AS Characteristic,
	|		Goods.Series                             AS Series,
	|		Goods.Package                          AS Package,
	|		Goods.NumberOfPackages                AS NumberOfPackages,
	|		ENDOFPERIOD(Goods.Ref.Date, DAY)   AS DateOfPriceReceipt
	|	FROM
	|		Document.BackflushProduction.ManufacturedProducts AS Goods
	|		
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON Goods.Recipient = CatWarehouses.Ref
	|		
	|	WHERE
	|		Goods.Ref IN
	|			(SELECT
	|				PrintingDocuments.Ref AS Ref
	|			FROM
	|				PrintingDocuments AS PrintingDocuments)
	|		AND NOT CatWarehouses.ShopFloorStockroom
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.Ref                            AS Ref,
	|		CASE
	|			WHEN NOT Goods.ProductOwner = VALUE(Catalog.Companies.EmptyRef)
	|				THEN Goods.ProductOwner
	|			WHEN CostGroups.MaterialProviderCompany IS NOT NULL
	|				THEN CostGroups.MaterialProviderCompany
	|			WHEN TRUE
	|				THEN Goods.Ref.Organization
	|		END                                    AS Organization,
	|		2                                        AS PMNumber,
	|		Goods.LineNumber                       AS LineNumber,
	|		Goods.Recipient                        AS Warehouse,
	|		Goods.Products                      AS Products,
	|		Goods.Characteristic                    AS Characteristic,
	|		Goods.Series                             AS Series,
	|		Goods.Package                          AS Package,
	|		Goods.NumberOfPackages                AS NumberOfPackages,
	|		ENDOFPERIOD(Goods.Ref.Date, DAY)   AS DateOfPriceReceipt
	|	FROM
	|		Document.BackflushProduction.SideAndIntermediateRelease AS Goods
	|		
	|		INNER JOIN Catalog.Warehouses AS CatWarehouses
	|		ON Goods.Recipient = CatWarehouses.Ref
	|		
	|		LEFT JOIN CostGroups AS CostGroups
	|		ON CostGroups.Ref = Goods.Ref
	|		AND CostGroups.CostGroupNumber = Goods.CostGroupNumber
	|		AND CostGroups.InternalSubcontracting
	|	
	|	WHERE
	|		Goods.Ref IN
	|			(SELECT
	|				PrintingDocuments.Ref AS Ref
	|			FROM
	|				PrintingDocuments AS PrintingDocuments)
	|		AND NOT CatWarehouses.ShopFloorStockroom) AS Goods
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Organization,
	|	Goods.PMNumber,
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.Package,
	|	Goods.DateOfPriceReceipt
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PMNumber AS PMNumber,
	|	Goods.LineNumber AS LineNumber,
	|	ItemsPrices.PriceKind AS PriceKind,
	|	ItemsPrices.Products AS Products,
	|	ItemsPrices.Characteristic AS Characteristic,
	|	MAX(ItemsPrices.Period) AS Period
	|INTO ProductPricePeriods
	|FROM
	|	Goods AS Goods
	|		INNER JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|		ON (&PriceKind = ItemsPrices.PriceKind)
	|		AND (&PriceCurrency = ItemsPrices.Currency)
	|		AND Goods.Products = ItemsPrices.Products
	|		AND Goods.Characteristic = ItemsPrices.Characteristic
	|		AND Goods.DateOfPriceReceipt >= ItemsPrices.Period
	|		AND (CASE
	|			WHEN &UsePriceManagementSystem25
	|				THEN Goods.DateOfPriceReceipt < &DateOfMigrationToPriceManagementSystem25
	|			ELSE TRUE
	|		END)
	|GROUP BY
	|	Goods.Ref,
	|	Goods.PMNumber,
	|	Goods.LineNumber,
	|	ItemsPrices.PriceKind,
	|	ItemsPrices.Products,
	|	ItemsPrices.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PMNumber AS PMNumber,
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.DateOfPriceReceipt AS DateOfPriceReceipt,
	|	ISNULL(CASE
	|		WHEN
	|			ItemKinds.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE Goods.Characteristic.ItemsCharacteristicForPricing
	|	END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)) AS PricingVariant,
	|	ISNULL(CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByBatch = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE Goods.Series.ItemsBatchForPricing
	|	END, VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)) AS PricingBatch,
	|	CASE
	|		WHEN ItemKinds.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|			THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		ELSE Goods.Package
	|	END AS PricingPackage,
	|	Goods.NumberOfPackages AS NumberOfPackages
	|INTO GoodsAttributes25
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|		ON (ItemKinds.Ref = Goods.Products.ProductKind)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.PMNumber AS PMNumber,
	|	Goods.LineNumber AS LineNumber,
	|	ItemsPrices.PriceKind AS PriceKind,
	|	ItemsPrices.Products AS Products,
	|	ItemsPrices.PricingVariant AS PricingVariant,
	|	ItemsPrices.PricingBatch AS PricingBatch,
	|	ItemsPrices.PricingPackage AS PricingPackage,
	|	MAX(ItemsPrices.Period) AS Period
	|INTO ProductPricePeriods25
	|FROM
	|	GoodsAttributes25 AS Goods
	|		INNER JOIN InformationRegister.ItemsPrices25 AS ItemsPrices
	|		ON (&PriceKind = ItemsPrices.PriceKind)
	|		AND Goods.Products = ItemsPrices.Products
	|		AND Goods.PricingVariant = ItemsPrices.PricingVariant
	|		AND Goods.PricingBatch = ItemsPrices.PricingBatch
	|		AND Goods.PricingPackage = ItemsPrices.PricingPackage
	|		AND Goods.DateOfPriceReceipt >= ItemsPrices.Period
	|		AND (&UsePriceManagementSystem25)
	|		AND (Goods.DateOfPriceReceipt >= &DateOfMigrationToPriceManagementSystem25)
	|GROUP BY
	|	Goods.Ref,
	|	Goods.PMNumber,
	|	Goods.LineNumber,
	|	ItemsPrices.PriceKind,
	|	ItemsPrices.Products,
	|	ItemsPrices.PricingVariant,
	|	ItemsPrices.PricingBatch,
	|	ItemsPrices.PricingPackage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TabDocuments.Ref AS Ref,
	|	MAX(ExchangeRates.Period) AS Period,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.BaseCurrency AS BaseCurrency
	|INTO PeriodsOfExchangeRatesAccordingToDocuments
	|FROM
	|	Document.BackflushProduction AS TabDocuments
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON &PriceCurrency = ExchangeRates.Currency
	|		AND TabDocuments.Organization.LocalAccountingCurrency = ExchangeRates.BaseCurrency
	|		AND TabDocuments.Date >= ExchangeRates.Period
	|WHERE
	|	TabDocuments.Ref IN (&DocumentsArray)
	|GROUP BY
	|	TabDocuments.Ref,
	|	ExchangeRates.Currency,
	|	ExchangeRates.BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductPricePeriods.Ref AS Ref,
	|	ProductPricePeriods.PMNumber AS PMNumber,
	|	ProductPricePeriods.LineNumber AS LineNumber,
	|	ItemsPrices.Price AS Price,
	|	ItemsPrices.Package AS Package
	|INTO Prices
	|FROM
	|	ProductPricePeriods AS ProductPricePeriods
	|		INNER JOIN InformationRegister.ItemsPrices AS ItemsPrices
	|		ON ProductPricePeriods.Period = ItemsPrices.Period
	|		AND ProductPricePeriods.PriceKind = ItemsPrices.PriceKind
	|		AND ProductPricePeriods.Products = ItemsPrices.Products
	|		AND ProductPricePeriods.Characteristic = ItemsPrices.Characteristic
	|
	|UNION ALL
	|
	|SELECT
	|	ProductPricePeriods.Ref,
	|	ProductPricePeriods.PMNumber,
	|	ProductPricePeriods.LineNumber,
	|	ItemsPrices.Price,
	|	ItemsPrices.Package
	|FROM
	|	ProductPricePeriods25 AS ProductPricePeriods
	|		INNER JOIN InformationRegister.ItemsPrices25 AS ItemsPrices
	|		ON ProductPricePeriods.Period = ItemsPrices.Period
	|		AND ProductPricePeriods.PriceKind = ItemsPrices.PriceKind
	|		AND ProductPricePeriods.Products = ItemsPrices.Products
	|		AND ProductPricePeriods.PricingVariant = ItemsPrices.PricingVariant
	|		AND ProductPricePeriods.PricingBatch = ItemsPrices.PricingBatch
	|		AND ProductPricePeriods.PricingPackage = ItemsPrices.PricingPackage
	|
	|INDEX BY
	|	Ref,
	|	PMNumber,
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsOfExchangeRatesAccordingToDocuments.Ref AS Ref,
	|	ExchangeRates.Currency AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	PeriodsOfExchangeRatesAccordingToDocuments AS PeriodsOfExchangeRatesAccordingToDocuments
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON PeriodsOfExchangeRatesAccordingToDocuments.Period = ExchangeRates.Period
	|		AND PeriodsOfExchangeRatesAccordingToDocuments.Currency = ExchangeRates.Currency
	|		AND PeriodsOfExchangeRatesAccordingToDocuments.BaseCurrency = ExchangeRates.BaseCurrency
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.BackflushProduction AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&DocumentsArray)
	|	AND NOT DocumentData.Ref IN
	|		(SELECT
	|			PrintingDocuments.Ref AS Ref
	|		FROM
	|			PrintingDocuments AS PrintingDocuments)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// REQUEST BY HEADER
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	ISNULL(DocumentData.CorrectedDocument.Number, DocumentData.Number) AS Number,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date) AS Date,
	|	ISNULL(DocumentData.CorrectedDocument.Date, DocumentData.Date) AS DocumentDate,
	|	DocumentData.Department.Presentation                               AS DivisionRepresentation
	|FROM
	|	Document.BackflushProduction AS DocumentData
	|WHERE
	|	DocumentData.Ref IN
	|		(SELECT
	|			PrintingDocuments.Ref AS Ref
	|		FROM
	|			PrintingDocuments AS PrintingDocuments)
	|
	|ORDER BY
	|	DocumentData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// QUERY BY TABLE PARTS
	|SELECT
	|	GoodsTable.Ref												AS Ref,
	|	GoodsTable.Organization											AS Organization,
	|	GoodsTable.Organization.Prefix									AS Prefix,
	|	GoodsTable.Products											AS Products,
	|	GoodsTable.Products.DescriptionFull						AS NomenclatureName,
	|	&ColumnOfCodes														AS ProductsCode,
	|	GoodsTable.Characteristic.DescriptionFull						AS CharacteristicName,
	|	GoodsTable.Characteristic										AS Characteristic,
	|	GoodsTable.Series.Description									AS SeriesName_,
	|	GoodsTable.Series 												AS Series,
	|	&QueryTextUnitOfMeasureDescription 							AS UnitOfMeasurementName,
	|	&QueryTextUnitCode 									AS UnitOfMeasureCode,
	|	&QueryTextUnitOfMeasureDescription 							AS PackageKind,
	|	CASE
	|		WHEN GoodsTable.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor1, 1)
	|	END																AS QuantityInOnePlace,
	|	GoodsTable.NumberOfPackages * &QueryTextWeight					AS GrossWeight,
	|	GoodsTable.NumberOfPackages									AS Count,
	|	GoodsTable.NumberOfPackages 									AS NumberOfSeats,
	|	GoodsTable.LineNumber											AS LineNumber,
	|	FALSE																AS ThisIsReusablePackage,
	|	CAST(ISNULL(Prices.Price, 0) 
	|		/ ISNULL(&QueryTextPackagingFactor2, 1) 
	|		* ISNULL(&QueryTextPackagingFactor1, 1) 
	|		* ISNULL(ExchangeRates.CourseNumerator, 1)
	|		/ ISNULL(ExchangeRates.CourseDenominator, 1) AS NUMBER(31,2))			AS Price,
	|	(CAST(ISNULL(Prices.Price, 0) 
	|		/ ISNULL(&QueryTextPackagingFactor2, 1) 
	|		* ISNULL(&QueryTextPackagingFactor1, 1) 
	|		* ISNULL(ExchangeRates.CourseNumerator, 1)
	|		/ ISNULL(ExchangeRates.CourseDenominator, 1) AS NUMBER(31,2))) * GoodsTable.NumberOfPackages AS Sum,
	|	GoodsTable.Warehouse.Presentation									AS Recipient
	|
	|FROM
	|	Goods AS GoodsTable
	|		LEFT JOIN ExchangeRates AS ExchangeRates
	|		ON GoodsTable.Ref = ExchangeRates.Ref
	|		LEFT JOIN Prices AS Prices
	|		ON GoodsTable.Ref = Prices.Ref
	|		AND GoodsTable.PMNumber = Prices.PMNumber
	|		AND GoodsTable.LineNumber = Prices.LineNumber
	|
	|ORDER BY
	|	GoodsTable.Ref,
	|	GoodsTable.PMNumber,
	|	GoodsTable.LineNumber
	|TOTALS
	|BY
	|	Ref,
	|	Organization,
	|	Recipient";
	
	QueryText = StrReplace(QueryText,
		"&ColumnOfCodes",
		"GoodsTable.Products." + ColumnOfCodes);
	
	QueryText = StrReplace(QueryText,
		"&QueryTextWeight",
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"GoodsTable.Package",
			"GoodsTable.Products"));
			
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsTable.Package",
			"GoodsTable.Products"));
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Prices.Package",
			"GoodsTable.Products"));
			
	QueryText = StrReplace(QueryText,
		"&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"GoodsTable.Package",
			"GoodsTable.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextUnitCode",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Code",
			"GoodsTable.Package",
			"GoodsTable.Products"));
	
	Query.Text = QueryText;
	
	PriceKind = Constants.PriceKindOfPlannedCostOfMaterialsAndWorks.Get();
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	Query.SetParameter("PriceKind", PriceKind);
	Query.SetParameter("PriceCurrency", Common.ObjectAttributeValue(PriceKind, "PriceCurrency"));
	Query.SetParameter("UsePriceManagementSystem25", UsePriceManagementSystem25);
	Query.SetParameter("DateOfMigrationToPriceManagementSystem25", DateOfMigrationToPriceManagementSystem25);
	
	ResultsArray = Query.ExecuteBatch();
	
	ReleaseOnlyToPantries = ResultsArray[ResultsArray.UBound() - 2].Select();
	While ReleaseOnlyToPantries.Next() Do
		
		Text =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ ""%1"", tất cả sản phẩm đều được chuyển đến kho của xưởng. In hóa đơn không khả dụng.';
					|ru = 'В документе ""%1"" все изделия выпускаются в цеховые кладовые. Печать накладной не доступна.';
					|en = 'All the items are released to the shop floor stockrooms in document ""%1"". Invoice printing is not available.'; fa = 'All the items are released to the shop floor stockrooms in document ""%1"". Invoice printing is not available.';
					|it = 'Nel documento ""%1"" tutti i prodotti vengono rilasciati nei magazzini del negozio. Stampa della fattura non disponibile.';
					|pl = 'W dokumencie ""%1"" wszystkie wyroby są wypuszczane do magazynów spiżarni. Wydrukowanie faktury nie jest dostępne.';
					|tr = '""%1"" belgesinde, tüm nihai ürünler atölye deposuna serbest bırakıldı. Fatura yazdırma erişilebilir değil.'"),
				ReleaseOnlyToPantries.Ref);
		
		Common.MessageToUser(
			Text,
			ReleaseOnlyToPantries.Ref);
		
	EndDo;
	
	HeaderResults = ResultsArray[ResultsArray.UBound() - 1];
	ResultForTabularPart = ResultsArray[ResultsArray.UBound()];
	
	DataStructureForPrinting = New Structure(
		"HeaderResults, ResultForTabularPart",
		HeaderResults,
		ResultForTabularPart);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryTexts = New Array;
	
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction


#EndRegion
#EndRegion

#Region Internal

#Region FillingInDocumentOnOrdersOrders

#Region SelectionOfMarkedProductsFromOrders

// Fill in the barcodes of packages.
// 
// Parameters:
//  ReferencesForOrders - Array of DocumentRef - Orders for orders
//  Goods - ValueTable - Goods
//  PackageBarcodes - ValueTable - Barcodes of packages
Procedure FillInBarcodesOfPackages(ReferencesForOrders, Goods, PackageBarcodes) Export


EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

#Region Posting


#EndRegion

#Region Other


#Region GosIs

#EndRegion

#EndRegion


#EndRegion
