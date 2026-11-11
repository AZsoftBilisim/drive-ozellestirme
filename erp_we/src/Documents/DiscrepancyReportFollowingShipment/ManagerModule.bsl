#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	
	DiscrepancyReportFollowingShipmentLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.DiscrepancyReportFollowingShipment") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	ArrangeShipmentOfGoods(Query, QueryTexts, Registers);
	
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
		
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
	
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.NotApproved);
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.Approved);	
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.ForCompletion);	
	TMCommonUse.AddRowToTableOfStatusesToChangeFromList(Table, Enums.StatusesOfDiscrepancyReport.Processed_);

	Return Table;
	
EndFunction

// Names of the details that the parameters for specifying the series depend on
//
// Returns:
//   String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Date,TypeOfBaseDocumentForNonConformanceCertificate";
	
	Return AttributesNames;
	
EndFunction

//Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//		Object - Structure - structure of object details values required for filling in parameters for specifying series
//	Returns:
//		Structure - See ProductsServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.DiscrepancyReportFollowingShipment";
	
	WarehouseSeriesParameters = New Structure;
	WarehouseSeriesParameters.Insert("UseItemsBatch", GetFunctionalOption("UseItemsBatch"));
	WarehouseSeriesParameters.Insert("UseCostAccountingByBatches",GetFunctionalOption("UseCostAccountingByBatchesWarehouse"));
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
	
	If Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice
		Or Not ValueIsFilled(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate =
		Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToVendor Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor);
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(Object.TypeOfBaseDocumentForNonConformanceCertificate) Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor);
	ElsIf Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		  Or Object.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentUnderReturnToVendor);
	Else
		ExceptionText = NStr("vi = 'Lấy các tham số chuỗi cho một biên bản với loại cơ sở %TypeOfAct% không được hỗ trợ.';
							|ru = 'Не поддерживается получение параметров серий для акта с типом основания %TypeOfAct%.';
							|en = 'Receipt of batch parameters for certificate with base document type %TypeOfAct% is not supported.'; fa = 'Receipt of batch parameters for certificate with base document type %TypeOfAct% is not supported.';
							|it = 'La ricezione dei parametri delle serie per un atto con il tipo di causale %TypeOfAct% non è supportata.';
							|pl = 'Nie jest obsługiwane pobieranie parametrów serii dla aktu z typem podstawy %TypeOfAct%.';
							|tr = '%TypeOfAct%temel tipe sahip bir eylem için seri parametrelerinin alınması desteklenmez.'");
		ExceptionText = StrReplace(ExceptionText, "%TypeOfAct%", Object.TypeOfBaseDocumentForNonConformanceCertificate);
		Raise ExceptionText;
	EndIf;
	
	SeriesSpecificationParameters.LinkFields.Add("FilledInBySale");
	SeriesSpecificationParameters.LinkFields.Add("SaleOfGoodsAndServices");
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentSender");
	SeriesSpecificationParameters.LinkFields.Add("Action");
	SeriesSpecificationParameters.LinkFields.Add("DiscrepancyTreatment");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice  = False;
	SeriesSpecificationParameters.ShipmentPlanning         = False;
	SeriesSpecificationParameters.SelectionPlanning           = False;
	SeriesSpecificationParameters.FactOfSelection                   = True;
	SeriesSpecificationParameters.Date                         = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.FilledInBySale,
	|	Goods.SaleOfGoodsAndServices,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.AssignmentSender,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.Action,
	|	Goods.DiscrepancyTreatment,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse,
	|	Goods.FilledInBySale,
	|	Goods.SaleOfGoodsAndServices,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.AssignmentSender,
	|	Goods.Action,
	|	Goods.DiscrepancyTreatment,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.FilledInBySale,
	|	Goods.SaleOfGoodsAndServices,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.AssignmentSender,
	|	Goods.Action,
	|	Goods.DiscrepancyTreatment,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledInBySale,
	|	SetOfSeries.SaleOfGoodsAndServices,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.Action,
	|	SetOfSeries.DiscrepancyTreatment,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledInBySale,
	|	SetOfSeries.SaleOfGoodsAndServices,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.Action,
	|	SetOfSeries.DiscrepancyTreatment,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.FilledInBySale,
	|	SetOfSeries.SaleOfGoodsAndServices,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.AssignmentSender,
	|	SetOfSeries.Action,
	|	SetOfSeries.DiscrepancyTreatment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND (ProductsToRequest.Count > 0
	|											OR ProductsToRequest.FilledInBySale)
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND (ProductsToRequest.Count > 0
	|											OR ProductsToRequest.FilledInBySale)
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND (BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
	|						AND &ShipmentToCustomer
	|					OR BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentByReturnToVendor
	|						AND &ShipmentUnderReturnToVendor)
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND (ProductsToRequest.Count > 0
	|											OR ProductsToRequest.FilledInBySale)
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND (ProductsToRequest.Count > 0
	|											OR ProductsToRequest.FilledInBySale)
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.AssignmentSender = SeriesToRequest.AssignmentSender
	|				AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|				AND ProductsToRequest.SaleOfGoodsAndServices = SeriesToRequest.SaleOfGoodsAndServices
	|				AND ProductsToRequest.FilledInBySale = SeriesToRequest.FilledInBySale
	|				AND ProductsToRequest.Action = SeriesToRequest.Action
	|				AND ProductsToRequest.DiscrepancyTreatment = SeriesToRequest.DiscrepancyTreatment
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.AssignmentSender = ProductsToRequest.AssignmentSender
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|			AND Goods.SaleOfGoodsAndServices = ProductsToRequest.SaleOfGoodsAndServices
	|			AND Goods.FilledInBySale = ProductsToRequest.FilledInBySale
	|			AND Goods.Action = ProductsToRequest.Action
	|			AND Goods.DiscrepancyTreatment = ProductsToRequest.DiscrepancyTreatment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

// Returns the request text that fills in the re-delivered product in the request for return and return of goods
//	Returns:
//		String - Query text
//
Function RequestTextForOverDeliveredGoods() Export
	
	QueryText = 
	"SELECT DISTINCT
	|	GoodsTable.ARAPObject AS ARAPObject
	|INTO ARAPObjects
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CustomerInvoice.Ref AS DocumentSalesOfGoodsAndServices,
	|	CustomerInvoice.Ref AS Ref,
	|	CustomerInvoice.Terms AS Terms,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.Partner AS Partner,
	|	CustomerInvoice.Counterparty AS Counterparty,
	|	CustomerInvoice.Currency AS Currency,
	|	CustomerInvoice.ARAPCurrency AS ARAPCurrency,
	|	CustomerInvoice.SalesOpportunity AS SalesOpportunity,
	|	CustomerInvoice.Department AS Department,
	|	CustomerInvoice.Status AS DocumentStatus,
	|	CASE
	|		WHEN CustomerInvoice.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE CustomerInvoice.Warehouse
	|	END AS Warehouse,
	|	CustomerInvoice.BusinessOperation AS EconomicOperationImplementation,
	|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
	|	CustomerInvoice.VATTaxation AS VATTaxation,
	|	CustomerInvoice.Contract AS Contract,
	|	CustomerInvoice.ToReturnReusablePackage AS ReusablePackageReturn,
	|	CustomerInvoice.PackageDepositIsRequired AS DepositForPackageIsRequired,
	|	NOT CustomerInvoice.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
	|				OR CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereAreErrorsStatus,
	|	CustomerInvoice.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	CustomersARAPAccounting.ARAPObject AS ARAPObject,
	|	CustomersARAPAccounting.Currency AS ARAPCurrency,
	|	ISNULL(CustomersARAPAccounting.SumBalance, 0) AS SumBalance
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.Balance(
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					ARAPObject
	|				FROM
	|					ARAPObjects)) AS CustomersARAPAccounting
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT TOP 1
	|	SaleAdjustment.Ref AS Ref
	|INTO LastAdjustmentData
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|WHERE
	|	SaleAdjustment.Posted
	|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
	|
	|ORDER BY
	|	SaleAdjustment.PointInTime DESC
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount
	|INTO ProductsForSale
	|FROM
	|	Document.SaleAdjustment.Goods AS GoodsTable
	|		INNER JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON GoodsTable.Ref = LastAdjustmentData.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Products.ItemsType,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Purpose,
	|	GoodsTable.Package,
	|	GoodsTable.NumberOfPackages,
	|	GoodsTable.Price,
	|	GoodsTable.PriceKind,
	|	GoodsTable.Count,
	|	GoodsTable.Sum,
	|	GoodsTable.VATRate,
	|	GoodsTable.VATAmount,
	|	GoodsTable.AmountIncludingVAT,
	|	GoodsTable.RowCode,
	|	GoodsTable.Warehouse,
	|	GoodsTable.SalesOrder,
	|	GoodsTable.ManualDiscount,
	|	GoodsTable.DiscountMarkupAmount
	|FROM
	|	Document.CustomerInvoice.Goods AS GoodsTable
	|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
	|		ON (TRUE)
	|WHERE
	|	LastAdjustmentData.Ref IS NULL
	|	AND GoodsTable.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	ProductsForSale.Products AS Products,
	|	ProductsForSale.ItemsType AS ItemsType,
	|	ProductsForSale.Characteristic AS Characteristic,
	|	ProductsForSale.Series AS Series,
	|	ProductsForSale.Purpose AS Purpose,
	|	ProductsForSale.Package AS Package,
	|	SUM(ProductsForSale.NumberOfPackages) AS NumberOfPackages,
	|	AVG(ProductsForSale.Price) AS Price,
	|	SUM(ProductsForSale.Count) AS Count,
	|	SUM(ProductsForSale.Sum) AS Sum,
	|	ProductsForSale.VATRate AS VATRate,
	|	SUM(ProductsForSale.VATAmount) AS VATAmount,
	|	SUM(ProductsForSale.AmountIncludingVAT) AS AmountIncludingVAT,
	|	SUM(ProductsForSale.ManualDiscount) AS ManualDiscount,
	|	SUM(ProductsForSale.DiscountMarkupAmount) AS DiscountMarkupAmount
	|INTO GoodsSales_
	|FROM
	|	ProductsForSale AS ProductsForSale
	|
	|GROUP BY
	|	ProductsForSale.Products,
	|	ProductsForSale.ItemsType,
	|	ProductsForSale.Characteristic,
	|	ProductsForSale.Series,
	|	ProductsForSale.Package,
	|	ProductsForSale.VATRate,
	|	ProductsForSale.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	ReturnOfGoodsFromCustomerGoods.Products AS Products,
	|	ReturnOfGoodsFromCustomerGoods.Products.ItemsType AS ItemsType,
	|	ReturnOfGoodsFromCustomerGoods.Characteristic AS Characteristic,
	|	ReturnOfGoodsFromCustomerGoods.Series AS Series,
	|	ReturnOfGoodsFromCustomerGoods.Purpose AS Purpose,
	|	ReturnOfGoodsFromCustomerGoods.Package AS Package,
	|	SUM(ReturnOfGoodsFromCustomerGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(ReturnOfGoodsFromCustomerGoods.Count) AS Count,
	|	SUM(ReturnOfGoodsFromCustomerGoods.Sum) AS Sum,
	|	ReturnOfGoodsFromCustomerGoods.VATRate AS VATRate,
	|	SUM(ReturnOfGoodsFromCustomerGoods.VATAmount) AS VATAmount,
	|	SUM(ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	AVG(ReturnOfGoodsFromCustomerGoods.Price) AS Price
	|INTO ProductsFromPreviousRefunds
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
	|WHERE
	|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|	AND ReturnOfGoodsFromCustomerGoods.Ref.Posted
	|
	|GROUP BY
	|	ReturnOfGoodsFromCustomerGoods.Products,
	|	ReturnOfGoodsFromCustomerGoods.Products.ItemsType,
	|	ReturnOfGoodsFromCustomerGoods.Characteristic,
	|	ReturnOfGoodsFromCustomerGoods.Series,
	|	ReturnOfGoodsFromCustomerGoods.Package,
	|	ReturnOfGoodsFromCustomerGoods.VATRate,
	|	ReturnOfGoodsFromCustomerGoods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsSales_.Products AS Products,
	|	GoodsSales_.ItemsType AS ItemsType,
	|	GoodsSales_.Characteristic AS Characteristic,
	|	GoodsSales_.Series AS Series,
	|	GoodsSales_.Purpose AS Purpose,
	|	GoodsSales_.Count - ISNULL(ProductsFromPreviousRefunds.Count, 0) AS Count,
	|	GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0) AS NumberOfPackages,
	|	GoodsSales_.Package AS Package,
	|	GoodsSales_.VATRate AS VATRate,
	|	CASE
	|		WHEN GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0) = 0
	|			THEN GoodsSales_.Price
	|		ELSE (GoodsSales_.Sum - ISNULL(ProductsFromPreviousRefunds.Sum, 0)) / (GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0))
	|	END AS Price,
	|	GoodsSales_.Sum - ISNULL(ProductsFromPreviousRefunds.Sum, 0) AS Sum,
	|	GoodsSales_.VATAmount - ISNULL(ProductsFromPreviousRefunds.VATAmount, 0) AS VATAmount,
	|	GoodsSales_.AmountIncludingVAT - ISNULL(ProductsFromPreviousRefunds.AmountIncludingVAT, 0) AS AmountIncludingVAT,
	|	&DocumentBasis AS DocumentSalesOfGoodsAndServices
	|INTO TTProducts_1
	|FROM
	|	GoodsSales_ AS GoodsSales_
	|		LEFT JOIN ProductsFromPreviousRefunds AS ProductsFromPreviousRefunds
	|		ON GoodsSales_.Products = ProductsFromPreviousRefunds.Products
	|			AND GoodsSales_.Characteristic = ProductsFromPreviousRefunds.Characteristic
	|			AND GoodsSales_.Series = ProductsFromPreviousRefunds.Series
	|			AND GoodsSales_.Purpose = ProductsFromPreviousRefunds.Purpose
	|WHERE
	|	GoodsSales_.Count - ISNULL(ProductsFromPreviousRefunds.Count, 0) > 0
	|	AND (GoodsSales_.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|			OR GoodsSales_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND NOT CAST(&DocumentBasis AS Document.CustomerInvoice).ToReturnReusablePackage)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransferredReturnablePackagingBalance.Products AS Products,
	|	TransferredReturnablePackagingBalance.Characteristic AS Characteristic,
	|	TransferredReturnablePackagingBalance.Partner AS Partner,
	|	TransferredReturnablePackagingBalance.DocumentTransfers_ AS DocumentTransfers_,
	|	TransferredReturnablePackagingBalance.CountBalance AS Count,
	|	TransferredReturnablePackagingBalance.SumBalance AS Sum
	|INTO TTTransferredReturnPackaging
	|FROM
	|	AccumulationRegister.TransferredReturnablePackaging.Balance(, DocumentTransfers_ = &DocumentBasis) AS TransferredReturnablePackagingBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTTransferredReturnPackaging.Products AS Products,
	|	TTTransferredReturnPackaging.Characteristic AS Characteristic,
	|	TTTransferredReturnPackaging.DocumentTransfers_ AS DocumentSalesOfGoodsAndServices,
	|	SUM(TTTransferredReturnPackaging.Count) AS Count,
	|	SUM(TTTransferredReturnPackaging.Count) AS NumberOfPackages,
	|	SUM(TTTransferredReturnPackaging.Sum) AS Sum,
	|	SUM(TTTransferredReturnPackaging.Sum) AS AmountIncludingVAT,
	|	CASE
	|		WHEN SUM(TTTransferredReturnPackaging.Count) = 0
	|			THEN SUM(TTTransferredReturnPackaging.Sum)
	|		ELSE SUM(TTTransferredReturnPackaging.Sum) / SUM(TTTransferredReturnPackaging.Count)
	|	END AS Price,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate
	|INTO TTTare
	|FROM
	|	TTTransferredReturnPackaging AS TTTransferredReturnPackaging
	|
	|GROUP BY
	|	TTTransferredReturnPackaging.Products,
	|	TTTransferredReturnPackaging.Characteristic,
	|	TTTransferredReturnPackaging.DocumentTransfers_
	|
	|HAVING
	|	SUM(TTTransferredReturnPackaging.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTGoodsTare.Products AS Products,
	|	TTGoodsTare.Characteristic AS Characteristic,
	|	TTGoodsTare.Series AS Series,
	|	TTGoodsTare.Purpose AS Purpose,
	|	TTGoodsTare.Count AS Count,
	|	TTGoodsTare.NumberOfPackages AS NumberOfPackages,
	|	TTGoodsTare.Package AS Package,
	|	TTGoodsTare.VATRate AS VATRate,
	|	TTGoodsTare.Price AS Price,
	|	TTGoodsTare.Sum AS Sum,
	|	TTGoodsTare.VATAmount AS VATAmount,
	|	TTGoodsTare.AmountIncludingVAT AS AmountIncludingVAT,
	|	TTGoodsTare.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|INTO TTGoodsTare
	|FROM
	|	(SELECT
	|		TTProducts_1.Products AS Products,
	|		TTProducts_1.Characteristic AS Characteristic,
	|		TTProducts_1.Series AS Series,
	|		TTProducts_1.Purpose AS Purpose,
	|		TTProducts_1.Count AS Count,
	|		TTProducts_1.NumberOfPackages AS NumberOfPackages,
	|		TTProducts_1.Package AS Package,
	|		TTProducts_1.VATRate AS VATRate,
	|		TTProducts_1.Price AS Price,
	|		TTProducts_1.Sum AS Sum,
	|		TTProducts_1.VATAmount AS VATAmount,
	|		TTProducts_1.AmountIncludingVAT AS AmountIncludingVAT,
	|		TTProducts_1.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|	FROM
	|		TTProducts_1 AS TTProducts_1
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TTTare.Products,
	|		TTTare.Characteristic,
	|		VALUE(Catalog.ItemsBatches.EmptyRef),
	|		VALUE(Catalog.Assignments.EmptyRef),
	|		TTTare.Count,
	|		TTTare.NumberOfPackages,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef),
	|		TTTare.VATRate,
	|		TTTare.Price,
	|		TTTare.Sum,
	|		0,
	|		TTTare.AmountIncludingVAT,
	|		TTTare.DocumentSalesOfGoodsAndServices
	|	FROM
	|		TTTare AS TTTare) AS TTGoodsTare
	|
	|GROUP BY
	|	TTGoodsTare.Products,
	|	TTGoodsTare.Characteristic,
	|	TTGoodsTare.Series,
	|	TTGoodsTare.Count,
	|	TTGoodsTare.NumberOfPackages,
	|	TTGoodsTare.Package,
	|	TTGoodsTare.VATRate,
	|	TTGoodsTare.Price,
	|	TTGoodsTare.Sum,
	|	TTGoodsTare.VATAmount,
	|	TTGoodsTare.AmountIncludingVAT,
	|	TTGoodsTare.DocumentSalesOfGoodsAndServices,
	|	TTGoodsTare.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.AssignmentSender AS AssignmentSender,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Count - CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument) AS Count,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum - CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument) AS Sum,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument) AS VATAmount,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument) AS AmountIncludingVAT
	|INTO TTCertificateOfDiscrepanciesAfterShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.AssignmentSender
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTGoodsTare.Products AS Products,
	|	TTGoodsTare.Characteristic AS Characteristic,
	|	TTGoodsTare.Series AS Series,
	|	TTGoodsTare.Purpose AS Purpose,
	|	TTGoodsTare.Purpose AS AssignmentSender,
	|	CASE
	|		WHEN TTGoodsTare.Count < TTCertificateOfDiscrepanciesAfterShipment.Count
	|			THEN TTGoodsTare.Count
	|		ELSE TTCertificateOfDiscrepanciesAfterShipment.Count
	|	END AS Count,
	|	CASE
	|		WHEN TTGoodsTare.NumberOfPackages < TTCertificateOfDiscrepanciesAfterShipment.NumberOfPackages
	|			THEN TTGoodsTare.NumberOfPackages
	|		ELSE TTCertificateOfDiscrepanciesAfterShipment.NumberOfPackages
	|	END AS NumberOfPackages,
	|	TTGoodsTare.Package AS Package,
	|	TTGoodsTare.VATRate AS VATRate,
	|	TTGoodsTare.Price AS Price,
	|	CASE
	|		WHEN TTGoodsTare.Sum < TTCertificateOfDiscrepanciesAfterShipment.Sum
	|			THEN TTGoodsTare.Sum
	|		ELSE TTCertificateOfDiscrepanciesAfterShipment.Sum
	|	END AS Sum,
	|	CASE
	|		WHEN TTGoodsTare.VATAmount < TTCertificateOfDiscrepanciesAfterShipment.VATAmount
	|			THEN TTGoodsTare.VATAmount
	|		ELSE TTCertificateOfDiscrepanciesAfterShipment.VATAmount
	|	END AS VATAmount,
	|	CASE
	|		WHEN TTGoodsTare.AmountIncludingVAT < TTCertificateOfDiscrepanciesAfterShipment.AmountIncludingVAT
	|			THEN TTGoodsTare.AmountIncludingVAT
	|		ELSE TTCertificateOfDiscrepanciesAfterShipment.AmountIncludingVAT
	|	END AS AmountIncludingVAT,
	|	TTGoodsTare.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices
	|FROM
	|	TTGoodsTare AS TTGoodsTare
	|		INNER JOIN TTCertificateOfDiscrepanciesAfterShipment AS TTCertificateOfDiscrepanciesAfterShipment
	|		ON TTGoodsTare.Products = TTCertificateOfDiscrepanciesAfterShipment.Products
	|			AND TTGoodsTare.Characteristic = TTCertificateOfDiscrepanciesAfterShipment.Characteristic
	|			AND (TTGoodsTare.Series = TTCertificateOfDiscrepanciesAfterShipment.Series
	|				OR TTGoodsTare.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND TTGoodsTare.Package = TTCertificateOfDiscrepanciesAfterShipment.Package
	|			AND TTGoodsTare.DocumentSalesOfGoodsAndServices = TTCertificateOfDiscrepanciesAfterShipment.DocumentSalesOfGoodsAndServices
	|			AND TTGoodsTare.Purpose = TTCertificateOfDiscrepanciesAfterShipment.Purpose
	|			AND TTGoodsTare.Purpose = TTCertificateOfDiscrepanciesAfterShipment.AssignmentSender
	|";
	
	Return QueryText;

EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	CreateBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreateBasedOnCommand <> Undefined Then
		ActStatuses = New Array;
		ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
		ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"Status",
															ActStatuses,
															ComparisonType.InList);
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"DiscrepanciesPostingMethod",
															Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
															ComparisonType.Equal);
	EndIf;
	
	DiscrepancyReportFollowingShipmentLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Report of discrepancies after shipment".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.DiscrepancyReportFollowingShipment) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.DiscrepancyReportFollowingShipment.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.DiscrepancyReportFollowingShipment);
		CreateBasedOnCommand.WriteMode = "Post";
		
		FunctionalOptions = "UseReportsOfDiscrepanciesAfterShipment";
		FunctionalOptions = FunctionalOptions
			+ ", UseCertificatesOfDiscrepanciesAfterShipmentForShipmentsOfGoodsToGiver2_5";
		FunctionalOptions = FunctionalOptions
			+ ", UseDiscrepancyReportFollowingShipmentByTransfersToSubcontractor2_5";
		CreateBasedOnCommand.FunctionalOptions = FunctionalOptions;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	DiscrepancyReportFollowingShipmentLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation NOT IN (
		|					VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));

	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation IN (
		|					VALUE(Enum.BusinessTransactions.TransferToMaterialProvider2_5),
		|					VALUE(Enum.BusinessTransactions.ReturnToMaterialProvider2_5))";
	
	DestinationPattern.Partner                      = "Object.Partner";
	DestinationPattern.Contract                      = "Object.Contract";
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(
		FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
		
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	DescriptionOfColumns.DefaultColumns.Add("InStock");
	
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse          = "Object.Goods.Warehouse";
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#Region Rounding

// Returns the parameters for rounding
// 
// Parameters:
//  AdditionalPropsSuffix - String - 
// 
// Returns:
//  Structure - the elements contain a structure of rounding parameters:
//   *Goods - See ProductsServer.ParametersForRoundingNumberOfUnitProducts
// 
Function TSParametersForRounding(AdditionalPropsSuffix = "") Export
	
	TSParameters = Undefined;
	TSName = "Goods";
	WarehouseFieldName = "Warehouse";
	
	If AdditionalPropsSuffix = "ByDocument" Then
		TSParameters = New Structure;
		TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
		TSParameters[TSName].FieldNameQuantitySuffix = "CountByDocument";
	EndIf;
	If TSParameters = Undefined Then
		TSParameters = New Structure;
		TSParameters.Insert(TSName, ProductsServer.ParametersForCheckingFillingQuantity());
	EndIf;
	
	TSParameters[TSName].TSName = TSName;
	TSParameters[TSName].AdditionalFields.Insert(WarehouseFieldName, TSName + "." + WarehouseFieldName);
	TSParameters[TSName].ConditionForSelectingRowsByAdditionalFields = 
			ProductionServer.ConditionForSelectingRowsForRounding(TSName, WarehouseFieldName);
	Return TSParameters;

EndFunction

#EndRegion

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Biên bản chênh lệch';
							|ru = 'Акт о расхождениях';
							|en = 'Discrepancy report'; fa = 'گزارش مغایرت';
							|it = 'Atto di discrepanza';
							|pl = 'Protokół o odchyleniu';
							|tr = 'Tutarsızlık raporu'"));
	DiscrepancyReportFollowingShipmentLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(TypeOfBaseDocumentForNonConformanceCertificate)";
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array - the elements of which is the structure (See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand)
//          .
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	PrintRules = New Array;
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.SurplusesRecord		= True;
	JobPrintingRules.VHFWarehouses				= True;
	
	PrintRules.Add(JobPrintingRules);
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses = True;
	
	PrintRules.Add(JobPrintingRules);
	
	Return PrintRules;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		StandardProcessing = False;
		If FormType = "ObjectForm" Then
			SelectedForm = "SelfServiceWorkplaceDocumentForm";
		ElsIf FormType = "ListForm" Then
			SelectedForm = "SelfServiceWorkplaceListForm";
		EndIf;
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("TypeOfBaseDocumentForNonConformanceCertificate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(Data.TypeOfBaseDocumentForNonConformanceCertificate) Then
		
		If Data.BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và chuyển quyền sở hữu %1 ngày %2';
											|ru = 'Акт о расхождениях после отгрузки товаров клиенту и перехода права собственности %1 от %2';
											|en = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2'; fa = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
											|it = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
											|pl = 'The ""%1"" sales dispute after goods shipment to customer and transfer of title to goods dated %2';
											|tr = 'Ürünlerin müşteriye sevk edilmesinden sonra ve %1 mülkiyetinin %2 öğesine devredilmesinde tutarsızlık beyanı'");
		Else
			TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi bán hàng %1 ngày %2';
											|ru = 'Акт о расхождениях после реализации %1 от %2';
											|en = 'Customer invoice dispute %1 dated %2'; fa = 'Customer invoice dispute %1 dated %2';
											|it = 'Atto di accettazione con riserva dopo la vendita %1 di %2';
											|pl = 'Protokół o odchyleniu po sprzedaży %1 z dn. %2';
											|tr = '%1 Satışı sonrası %2 tarihli tutarsızlık raporu'");
		EndIf;
	
	ElsIf DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(Data.TypeOfBaseDocumentForNonConformanceCertificate) Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng cho khách và trước khi chuyển quyền sở hữu %1 ngày %2';
										|ru = 'Акт о расхождениях после отгрузки товаров клиенту и до перехода права собственности %1 от %2';
										|en = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2'; fa = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
										|it = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
										|pl = 'The ""%1"" sales dispute after goods shipment to customer and before transfer of title to goods dated %2';
										|tr = 'Ürünlerin müşteriye sevk edilmesinden sonra ve %1 mülkiyetinin %2 öğesine devredilmesinden öncesi tutarsızlık beyanı'");
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(Data.TypeOfBaseDocumentForNonConformanceCertificate) Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi trả lại hàng cho nhà cung cấp %1 ngày %2';
										|ru = 'Акт о расхождениях после возврата поставщику %1 от %2';
										|en = 'Discrepancy report following the return of goods to a vendor %1 dated %2'; fa = 'Discrepancy report following the return of goods to a vendor %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il reso al fornitore %1 di %2';
										|pl = 'Protokół o odchyleniu po zwrocie do dostawcy %1 z dn. %2';
										|tr = '%1Tedarikçiye iade sonrası %2tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferOfGoodsToBailee  Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa cho bên lưu kho %1 ngày %2';
										|ru = 'Акт о расхождениях после передачи товаров хранителю %1 от %2';
										|en = 'Discrepancy report following VMI fill-up %1 dated %2'; fa = 'Discrepancy report following VMI fill-up %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il trasferimento delle merci in stoccaggio %1 di %2';
										|pl = 'Protokół o odchyleniu po przekazaniu towarów do depozytariusza %1 z dn. %2';
										|tr = 'Malların %1 emanetçiye transferi sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.GoodsTransferToSubcontractor Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao nguyên vật liệu cho bên nhận gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после передачи сырья переработчику %1 от %2';
										|en = 'Discrepancy report following customer stock fill-up %1 dated %2'; fa = 'Discrepancy report following customer stock fill-up %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il trasferimento di materie prime al gestore %1 di %2';
										|pl = 'Protokół o odchyleniu po przekazaniu surowców przetwórcom %1 z dn. %2';
										|tr = 'Hammaddelerin %1 fason üreticiye transferi sonrası %2 tarihli tutarsızlık raporu'");
	ElsIf DiscrepanciesClientServer.TypeOfBasisTransferToCommission(Data.TypeOfBaseDocumentForNonConformanceCertificate) Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa vào ký gửi %1 ngày %2';
										|ru = 'Акт о расхождениях после передачи товаров на комиссию %1 от %2';
										|en = 'Discrepancy report following consignment sales %1 dated %2'; fa = 'Discrepancy report following consignment sales %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo il trasferimento di merci in commissione %1 di %2';
										|pl = 'Protokół o odchyleniu po przekazaniu towarów do komisu %1 z dn. %2';
										|tr = 'Malların %1konsinyeye transferinden sonra %2tarihli tutarsızlık raporu'");
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi chuyển giao hàng hóa cho bên đặt gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после передачи давальцу %1 от %2';
										|en = 'Discrepancy report following the transfer of goods to a provider %1 dated %2'; fa = 'Discrepancy report following the transfer of goods to a provider %1 dated %2';
										|it = 'Акт о расхождениях после передачи давальцу %1 от %2';
										|pl = 'Discrepancy report following the transfer of goods to a provider %1 dated %2';
										|tr = '%1Sağlayıcıya transfer sonrası %2 tarihli tutarsızlık raporu'"); 
	ElsIf Data.TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider Then
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi trả lại cho bên đặt gia công %1 ngày %2';
										|ru = 'Акт о расхождениях после возврата давальцу %1 от %2';
										|en = 'Discrepancy report following Goods return — Subcontracting services delivered %1 dated %2'; fa = 'Discrepancy report following Goods return — Subcontracting services delivered %1 dated %2';
										|it = 'Discrepancy report following Goods return — Subcontracting services delivered %1 dated %2';
										|pl = 'Discrepancy report following Goods return — Subcontracting services delivered %1 dated %2';
										|tr = '%1Sağlayıcıya iade sonrası %2 tarihli tutarsızlık raporu'");
	Else
		TemplateOfPresentation = NStr("vi = 'Biên bản chênh lệch sau khi giao hàng từ lưu kho %1 ngày %2';
										|ru = 'Акт о расхождениях после отгрузки товаров с хранения %1 от %2';
										|en = 'VMI pick-up discrepancy report %1 dated %2'; fa = 'VMI pick-up discrepancy report %1 dated %2';
										|it = 'Atto di accettazione con riserva dopo la spedizione di merci dallo stoccaggio %1 di %2';
										|pl = 'Protokół o odchyleniu po wysyłce towarów z przechowywania %1 z dn. %2';
										|tr = 'Malların %1depodan sevkiyatından sonra %2tarihli tutarsızlık raporu'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
		Data.Number,
		Data.Date);
		
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "DiscrepancyReportFollowingShipment");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function FullObjectName()
	Return "Document.DiscrepancyReportFollowingShipment";
EndFunction

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	HeaderData_.Date                         AS Period,
	|	HeaderData_.Partner                      AS Partner,
	|	HeaderData_.Counterparty                   AS Counterparty,
	|	HeaderData_.Ref                       AS DiscrepancyReportFollowingShipment,
	|	HeaderData_.Organization                  AS Organization,
	|	HeaderData_.Currency                       AS Currency,
	|	HeaderData_.Status                       AS Status,
	|	HeaderData_.PriceIncludesVAT              AS PriceIncludesVAT,
	|	HeaderData_.BusinessOperation        AS BusinessOperation,
	|	HeaderData_.Department                AS Department,
	|	HeaderData_.IncomingDocumentNumber      AS IncomingDocumentNumber,
	|	HeaderData_.IncomingDocumentDate       AS IncomingDocumentDate,
	|	HeaderData_.ExternalDocumentName AS ExternalDocumentName,
	|	HeaderData_.Contract                      AS Contract,
	|	HeaderData_.DiscrepanciesPostingMethod   AS DiscrepanciesPostingMethod,
	|	HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate AS TypeOfBaseDocumentForNonConformanceCertificate,
	|	HeaderData_.SenderWarehouse       AS SenderWarehouse,
	|	HeaderData_.Manager                     AS Manager,
	|	HeaderData_.Author                        AS Author,
	|	HeaderData_.Number                        AS Number,
	|	HeaderData_.Comment                  AS Comment,
	|	HeaderData_.DeletionMark              AS DeletionMark,
	|	HeaderData_.Posted                     AS Posted
	|
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                        Attributes.Period);
	Query.SetParameter("DiscrepancyReportFollowingShipment", Attributes.DiscrepancyReportFollowingShipment);
	Query.SetParameter("Period",                        Attributes.Period);
	Query.SetParameter("Partner",                       Attributes.Partner);
	Query.SetParameter("Counterparty",                    Attributes.Counterparty);
	Query.SetParameter("Currency",                        Attributes.Currency);
	Query.SetParameter("Status",                        Attributes.Status);
	Query.SetParameter("Organization",                   Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT",               Attributes.PriceIncludesVAT);
	Query.SetParameter("BusinessOperation",         Attributes.BusinessOperation);
	Query.SetParameter("Department",                 Attributes.Department);
	Query.SetParameter("IncomingDocumentNumber",       ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber));
	Query.SetParameter("IncomingDocumentDate",        Attributes.IncomingDocumentDate);
	Query.SetParameter("Contract",                       Attributes.Contract);
	Query.SetParameter("DiscrepanciesPostingMethod",    Attributes.DiscrepanciesPostingMethod);
	Query.SetParameter("EmptyAssignment",              Catalogs.Assignments.EmptyRef());
	Query.SetParameter("WarehouseOperation",             WarehouseOperationByBaseType(Attributes.TypeOfBaseDocumentForNonConformanceCertificate));
	Query.SetParameter("ExternalDocumentName",     Attributes.ExternalDocumentName);
	Query.SetParameter("Number",                         Attributes.Number);
	Query.SetParameter("Manager",                      Attributes.Manager);
	Query.SetParameter("MetadataIdentifier",       Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("Comment",                   Attributes.Comment);
	Query.SetParameter("DeletionMark",               Attributes.DeletionMark);
	Query.SetParameter("Posted",                      Attributes.Posted);
	Query.SetParameter("Author",                         Attributes.Author);
	ContractInformation = "";
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
EndProcedure

Function QueryTextTTSetOfSeries(Query, QueryTexts)
	
	RegisterName = "TTSeries";
	
	QueryText = "
	|SELECT
	|	SeriesTable.Products                                AS Products,
	|	SeriesTable.Characteristic                              AS Characteristic,
	|	SeriesTable.Series                                       AS Series,
	|	SeriesTable.Warehouse                                       AS Warehouse,
	|	SeriesTable.Action                                    AS Action,
	|	SeriesTable.DiscrepancyTreatment                            AS DiscrepancyTreatment,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssignmentSender.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.AssignmentSender
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                    AS Purpose,
	|	
	|	&WarehouseOperation                                       AS WarehouseOperation,
	|
	|	CASE WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END         AS AdvancedWarehousingOnShipment,
	|	
	|	CASE WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END         AS OrderSchemeWhenReflectingSurplusShortages,
	|
	|	CASE WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END                                                AS ThisIsWarehouseRecord,
	|
	|	SeriesTable.Count - CountByDocument          AS Discrepancies
	|
	|INTO TTSeries
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS SeriesTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON CatWarehouse.Ref = SeriesTable.Warehouse
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> SeriesTable.CountByDocument
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND NOT SeriesTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND SeriesTable.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	AND &Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Action,
	|	GoodsTable.DiscrepancyTreatment,
	|	CASE
	|		WHEN ISNULL(GoodsTable.AssignmentSender.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.AssignmentSender
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	&WarehouseOperation,
	|
	|	CASE WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END,
	|	
	|	CASE WHEN CatWarehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages AND CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END,
	|
	|	CASE WHEN NOT CatWarehouse.UseWarehouseManagemantSystemForGoodsIssue OR CatWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue > &Period THEN
	|				TRUE
	|			ELSE
	|				FALSE
	|		END,
	|	GoodsTable.Count - GoodsTable.CountByDocument
	|
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS GoodsTable
	|		INNER JOIN Catalog.Warehouses AS CatWarehouse
	|		ON CatWarehouse.Ref = GoodsTable.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.CountByDocument <> GoodsTable.Count
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND NOT GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.GoodsShortageIsControversial)
	|	AND NOT GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DisregardShortage)
	|	AND GoodsTable.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	AND &Status IN(
	|		VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|		VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSeries", QueryTexts) Then
		QueryTextTTSetOfSeries(Query, QueryTexts)
	EndIf;
	
	QueryText =
	// Write-off of shortfall (Discrepancies < 0)
	"SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord)
	|	                                       AS WarehouseOperation,
	|	
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|			AND GoodsTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|	AND GoodsTable.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|
	|UNION ALL
	|
	// Recording of surpluses (Discrepancies > 0)
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	UNDEFINED                           AS Recipient,
	|	VALUE(Catalog.Assignments.EmptyRef)
	|	                                       AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord)
	|	                                       AS WarehouseOperation,
	|	
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(&DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|			AND GoodsTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery)))
	|	AND GoodsTable.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|
	|UNION ALL
	|
	// Pre-shipment in case of shortage in an irregular warehouse (Discrepancies < 0)
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                               AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation                     AS WarehouseOperation,
	|
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	NOT GoodsTable.AdvancedWarehousingOnShipment
	|	AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|			AND GoodsTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|
	|	AND GoodsTable.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	
	|UNION ALL
	|
	// Reflection of the surplus in the order warehouse for shipment with an irregular pattern of reflection of the surplus, in case of shortage at the customer
	// (Discrepancies < 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                               AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation                     AS WarehouseOperation,
	|	
	|	-GoodsTable.Discrepancies             AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.AdvancedWarehousingOnShipment
	|	AND NOT GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND(GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|	
	|		OR &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|			AND GoodsTable.Action IN(
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired)))
	|
	|	AND GoodsTable.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	
	|UNION ALL
	|
	// Compensation of the over-order invoice for the shipment of excess in an irregular warehouse (Discrepancies > 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                               AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation                     AS WarehouseOperation,
	|	
	|	-GoodsTable.Discrepancies             AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	NOT GoodsTable.AdvancedWarehousingOnShipment
	|	AND GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
	|
	|	AND GoodsTable.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|	
	|UNION ALL
	|
	// Reflection of the shortage in the order warehouse for shipment with an irregular pattern of reflecting surpluses, with a surplus from the client
	// (Discrepancies > 0).
	|SELECT
	|	&Period                                AS Period,
	|	&Ref                                AS Document,
	|	
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Warehouse                    AS Sender,
	|	&Partner                               AS Recipient,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.Series                    AS Series,
	|	GoodsTable.ThisIsWarehouseRecord     AS ThisIsWarehouseRecord,
	|	&WarehouseOperation                     AS WarehouseOperation,
	|	
	|	GoodsTable.Discrepancies              AS Count
	|FROM
	|	TTSeries AS GoodsTable
	|WHERE
	|	GoodsTable.AdvancedWarehousingOnShipment
	|	AND NOT GoodsTable.OrderSchemeWhenReflectingSurplusShortages
	|	
	|	AND &DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|	AND GoodsTable.Action IN(
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
	|
	|	AND GoodsTable.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	CASE
	|		WHEN DocumentData.NumberOfStorageLocations = 1
	|			THEN DocumentData.StorageLocation
	|		ELSE UNDEFINED
	|	END                    AS StorageLocation,
	|	&Department           AS Department,
	|	&Manager                AS EmployeeResponsible,
	|	&Comment             AS Comment,
	|	&Currency                  AS Currency,
	|	0                        AS Sum,
	|	&Status                  AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&IncomingDocumentDate  AS SourceDocumentDate,
	|	&IncomingDocumentNumber AS SourceDocumentNumber,
	|	&ExternalDocumentName AS SourceDocumentName,
	|	&Author                   AS Author,
	|	FALSE                     AS ReverseTransactionCorrection,
	|	UNDEFINED             AS ReversedDocument,
	|	UNDEFINED             AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.SubcontractOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.SubcontractOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN (DocumentGoods.SalesOrder REFS Document.SalesOrder
	|			OR DocumentGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice IS NULL
	|			AND DocumentGoods.SalesOrder.ThisIsOrderAsInvoice
	|			THEN DocumentGoods.SaleOfGoodsAndServices
	|		WHEN (DocumentGoods.SalesOrder REFS Document.SalesOrder
	|			OR DocumentGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice IS NULL
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice
	|			THEN DocumentGoods.SalesOrder
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN 
	|						(UNDEFINED,
	|						VALUE(Document.SalesOrder.EmptyRef),
	|						VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
	|			THEN DocumentGoods.SalesOrder
	|		ELSE DocumentGoods.SaleOfGoodsAndServices
	|	END								AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.AssignmentSender AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	-(DocumentGoods.Count - DocumentGoods.CountByDocument) AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS Canceled,
	|	TRUE								AS ThisIsAnInvoice,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DocumentGoods
	|		LEFT JOIN Document.DiscrepancyReportFollowingShipment AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status IN(VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|							VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND (DocumentGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|		OR ((HeaderData_.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|				OR HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer))
	|			AND DocumentGoods.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))))
	|	AND DocumentGoods.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	AND DocumentGoods.Count <> DocumentGoods.CountByDocument";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
												
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ArrangeShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Period,
	|	CASE
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.MaterialProviderOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.MaterialProviderOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN VALUETYPE(DocumentGoods.SalesOrder) = TYPE(Document.SubcontractOrder2_5)
	|			AND NOT DocumentGoods.SalesOrder = VALUE(Document.SubcontractOrder2_5.EmptyRef)
	|			THEN DocumentGoods.SalesOrder
	|		WHEN (DocumentGoods.SalesOrder REFS Document.SalesOrder
	|			OR DocumentGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice IS NULL
	|			AND DocumentGoods.SalesOrder.ThisIsOrderAsInvoice
	|			THEN DocumentGoods.SaleOfGoodsAndServices
	|		WHEN (DocumentGoods.SalesOrder REFS Document.SalesOrder
	|			OR DocumentGoods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer)
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice IS NULL
	|			AND NOT DocumentGoods.SalesOrder.ThisIsOrderAsInvoice
	|			THEN DocumentGoods.SalesOrder
	|		WHEN &UseAdvancedOrderFeatures
	|				AND NOT DocumentGoods.SalesOrder IN
	|						(UNDEFINED,
	|						VALUE(Document.SalesOrder.EmptyRef),
	|						VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef))
	|			THEN DocumentGoods.SalesOrder
	|		ELSE DocumentGoods.SaleOfGoodsAndServices
	|	END								AS OrderDocument,
	|	DocumentGoods.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.AssignmentSender AS Purpose,
	|	DocumentGoods.Purpose 			AS PurposeForConnection,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	-(DocumentGoods.Count - DocumentGoods.CountByDocument) AS Count,
	|	FALSE								AS ExceedingOrder,
	|	FALSE								AS ShipmentByOrder
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DocumentGoods
	|		LEFT JOIN Document.DiscrepancyReportFollowingShipment AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status IN(VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|							VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND (DocumentGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|		OR ((HeaderData_.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|				OR HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer))
	|			AND DocumentGoods.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))))
	|	AND DocumentGoods.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|
	|	AND DocumentGoods.Count <> DocumentGoods.CountByDocument";
	
	UseAdvancedOrderFeatures = ?(GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
												"TRUE",
												"FALSE");
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&UseAdvancedOrderFeatures",
												UseAdvancedOrderFeatures);
	
	SubstitutionOfSeriesFields = New Map();
	SubstitutionOfSeriesFields.Insert("SeriesData_.Count",
		"-(SeriesData_.Count - SeriesData_.CountByDocument)");
	
	RedefinedSeriesConnectionFields = New Map;
	RedefinedSeriesConnectionFields.Insert("Purpose", "PurposeForConnection");
	
	ParametersOfModularHolding = WarehousesServer.ParametersOfModularHolding();
	ParametersOfModularHolding.MetadataObject = Metadata.Documents.DiscrepancyReportFollowingShipment;
	ParametersOfModularHolding.TSSeriesName = "SetOfSeries";
	ParametersOfModularHolding.ThisIsDiscrepancyReport = True;
	ParametersOfModularHolding.SynonymForDocumentTable = "DocumentGoods";
	ParametersOfModularHolding.SubstitutionOfSeriesFields = SubstitutionOfSeriesFields;
	ParametersOfModularHolding.RedefinedSeriesConnectionFields = RedefinedSeriesConnectionFields;
	
	WarehousesServer.IssueShipmentOfGoodsActs(Query,
											QueryTexts,
											Registers,
											TextOfDocumentDataRequest,
											ParametersOfModularHolding);
	
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	HeaderData_.Date					AS Date,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	DocumentGoods.AssignmentSender AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	-(DocumentGoods.Count - DocumentGoods.CountByDocument)	AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DocumentGoods
	|		LEFT JOIN Document.DiscrepancyReportFollowingShipment AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND HeaderData_.Status IN(VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
	|							VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
	|	AND (DocumentGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
	|		OR ((HeaderData_.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
	|				OR HeaderData_.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer))
	|			AND DocumentGoods.Action IN(VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|										VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered))))
	|	AND DocumentGoods.DiscrepancyTreatment IN (
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
	|			VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
	|			)
	|	AND DocumentGoods.Count <> DocumentGoods.CountByDocument";
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.SaleOfGoodsAndServices.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	MAX(GoodsTable.Warehouse)                                       AS StorageLocation,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.SaleOfGoodsAndServices.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities,
	|	COUNT(DISTINCT GoodsTable.Warehouse)                           AS NumberOfStorageLocations
	|INTO TTBases
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DocumentData
	|		LEFT JOIN Document.DiscrepancyReportFollowingShipment.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function WarehouseOperationByBaseType(TypeOfBaseDocumentForNonConformanceCertificate)
	
	If DiscrepanciesClientServer.TypeOfBasisSaleOfGoodsServices(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfItemsToCustomer(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferOfGoodsToCustodian(TypeOfBaseDocumentForNonConformanceCertificate)
		Or DiscrepanciesClientServer.TypeOfBasisTransferToCommission(TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		WarehouseOperation = Enums.WarehouseTransactions.ShipmentToCustomer;
		
	ElsIf DiscrepanciesClientServer.TypeOfBasisRefundToSupplier(TypeOfBaseDocumentForNonConformanceCertificate)
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.TransferToMaterialProvider
		Or TypeOfBaseDocumentForNonConformanceCertificate = Enums.TypesOfBaseDocumentsForDiscrepancyReport.ReturnToMaterialProvider
		Or DiscrepanciesClientServer.TypeOfBasisShipmentOfGoodsFromStorage(TypeOfBaseDocumentForNonConformanceCertificate)
		Then
		
		WarehouseOperation = Enums.WarehouseTransactions.ShipmentUnderReturnToVendor;
		
	Else
		WarehouseOperation = Undefined;
	EndIf;
	
	Return WarehouseOperation;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingShipment - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Contract = Object.Contract;
	FillParameters.Department = Object.Department;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Or
		Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Or
		Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.DiscrepancyReportFollowingShipment - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period =  Object.Date;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
		
		FillParameters.ReturnOfGoodsToVendor = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		
		FillParameters.ReturnOfGoodsToConsignor = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList();
	
	FullDocumentName           = "Document.DiscrepancyReportFollowingShipment";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation,
		TemporaryTableQueryTexts);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	VALUE(Enum.SupplyOptions.ToSupply) AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	DATETIME(1, 1, 1) AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.DiscrepancyReportFollowingShipment.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Approved)
		|		AND TabPart.CountByDocument - TabPart.Count > 0
		|		AND (TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
		|			OR TabPart.Action IN(
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
		|					VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired))
		|				AND (TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
		|					OR TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer)))
		|		AND TabPart.DiscrepancyTreatment IN (
		|				VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
		|				VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
		|				)
		|";
	
	// Formation of the shipment schedule of the additional goods in the preliminary status.
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		// Compensation for order changes in the order to reflect surpluses/shortages in the warehouse.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.AssignmentSender AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.CountByDocument - TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.DiscrepancyReportFollowingShipment.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND TabPart.Ref.Status IN(
		|			VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion),
		|			VALUE(Enum.StatusesOfDiscrepancyReport.Processed_))
		|		AND (TabPart.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ShipNow)
		|			OR (TabPart.Action IN(
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
		|						VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery))
		|				) AND (TabPart.Ref.DiscrepanciesPostingMethod = VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments)
		|					OR TabPart.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.GoodsShipmentToCustomer)))
		|		AND TabPart.DiscrepancyTreatment IN (
		|				VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount),
		|				VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.To_Write_Off)
		|				)
		|		 AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|		 AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages <= TabPart.Ref.Date";
		
		StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	ActStatuses = New Array;
	ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.ForCompletion);
	ActStatuses.Add(Enums.StatusesOfDiscrepancyReport.Processed_);
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														ActStatuses,
														ComparisonType.InList);
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"DiscrepanciesPostingMethod",
														Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
														DataCompositionComparisonType.Equal);
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"SelectionTask");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														ActStatuses,
														ComparisonType.InList);
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"DiscrepanciesPostingMethod",
														Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.CorrectSourceDocuments,
														DataCompositionComparisonType.Equal);
	
	DiscrepancyReportFollowingShipmentLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	DiscrepancyReportFollowingShipmentLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

// Fills in data for recipients of printed forms
// 
// Parameters:
//  PrintObjectDataStructure - See PrintFormGeneration.NewPrintObjectDataStructure
//
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
EndProcedure

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfDiscrepancyReport[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN (&DocumentsArray)
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample         - QueryResultSelection - Current selection string
//	NewStatus             - EnumRef.StatusesOfDiscrepancyReport - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True;
	
EndFunction

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.DiscrepancyReportFollowingShipment.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.61";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Id = New UUID("4f28da79-079d-400e-a491-663c89ebbdcd");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.DiscrepancyReportFollowingShipment.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(
		NStr("vi = 'Cập nhật chứng từ ""Biên bản chênh lệch sau khi giao hàng"":';
			|ru = 'Обновление документов ""Акт о расхождениях после отгрузки"":';
			|en = 'Update the ""Sales dispute"" documents:'; fa = 'Update the ""Sales dispute"" documents:';
			|it = 'Update the ""Sales dispute"" documents:';
			|pl = 'Update the ""Sales dispute"" documents:';
			|tr = '""Sevkiyat Sonrası Tutarsızlık Tutanağı"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(
		NStr("vi = '- điền mục tin ""Cách xử lý chênh lệch với hàng hóa"" trong phần bảng ""Hàng hóa"".';
			|ru = '- заполнение реквизита ""Как отработать расхождение с товаром"" в табличной части ""Товары"".';
			|en = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.'; fa = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|it = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|pl = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|tr = '""Ürünler"" tablo bölümünde ""Ürün tutarsızlığı nasıl işlenecek"" özniteliğinin doldurulması.'"));
	ListOfDescriptions.Add(
		NStr("vi = '- cập nhật mục tin ""Cách xử lý chênh lệch"" trong phần bảng ""Hàng hóa"" đối với chứng từ có thao tác ""Chuyển giao quyền sở hữu"".';
			|ru = '- актуализация реквизита ""Как отработать расхождение"" в табличной части ""Товары"" для документов с операцией ""Переход права собственности"".';
			|en = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.'; fa = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|it = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|pl = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|tr = '- ""Mülkiyet hakkı devri"" işlemi olan belgeler için ""Ürünler"" tablo bölümündeki ""Tutarsızlık nasıl işlenecek"" özniteliğinin güncellenmesi.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	FullName = Metadata.Documents.DiscrepancyReportFollowingShipment.FullName();
	
	Editable1 = New Array;
	Editable1.Add(FullName);
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(FullName);
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Registers documents for processing for modification.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export

	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ProductData_9.Ref AS Ref
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ProductData_9
	|WHERE
	|	ProductData_9.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|	AND ProductData_9.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|
	|UNION
	|
	|SELECT
	|	SeriesData_.Ref AS Ref
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS SeriesData_
	|WHERE
	|	SeriesData_.Action <> VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|	AND SeriesData_.DiscrepancyTreatment = VALUE(Enum.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.EmptyRef)
	|";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
//
// Parameters:
//	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName  = EmptyRef().Metadata().FullName();
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	ObjectsProcessed = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(
		NStr("vi = 'Không thể xử lý chứng từ ""Biên bản chênh lệch sau khi giao hàng"" theo hàm sự kiện:';
			|ru = 'Не удалось обработать документы ""Акт о расхождениях после отгрузки"" по обработчику:';
			|en = 'Cannot process the ""Sales dispute"" document by the handler:'; fa = 'Cannot process the ""Sales dispute"" document by the handler:';
			|it = 'Cannot process the ""Sales dispute"" document by the handler:';
			|pl = 'Cannot process the ""Sales dispute"" document by the handler:';
			|tr = '""Sevkiyat Sonrası Tutarsızlık Tutanağı"" belgeleri işleyiciye göre işlenemedi:'"));
	ListOfDescriptions.Add(
		NStr("vi = '- điền mục tin ""Cách xử lý chênh lệch với hàng hóa"" trong phần bảng ""Hàng hóa"".';
			|ru = '- заполнение реквизита ""Как отработать расхождение с товаром"" в табличной части ""Товары"".';
			|en = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.'; fa = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|it = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|pl = '- Fill in the ""Discrepancy treatment"" attribute in the ""Goods"" table.';
			|tr = '""Ürünler"" tablo bölümünde ""Ürün tutarsızlığı nasıl işlenecek"" özniteliğinin doldurulması.'"));
	ListOfDescriptions.Add(
		NStr("vi = '- cập nhật mục tin ""Cách xử lý chênh lệch"" trong phần bảng ""Hàng hóa"" đối với chứng từ có thao tác ""Chuyển giao quyền sở hữu"".';
			|ru = '- актуализация реквизита ""Как отработать расхождение"" в табличной части ""Товары"" для документов с операцией ""Переход права собственности"".';
			|en = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.'; fa = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|it = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|pl = '- Update the ""Discrepancy treatment"" attribute in the ""Goods"" table for documents with the ""Transfer of title to goods"" transaction.';
			|tr = '""Mülkiyet hakkı devri"" işlemli belgeler için ""Ürünler"" tablo bölümünde ""Tutarsızlık nasıl işlenecek"" özniteliğinin güncellenmesi.'"));
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentsTable.Ref AS Ref
	|INTO DocumentsTable
	|FROM
	|	&DataForUpdate AS DocumentsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsTable.Ref     AS Ref,
	|	DocumentData.DataVersion AS DataVersion
	|FROM
	|	DocumentsTable AS DocumentsTable
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS DocumentData
	|		ON DocumentsTable.Ref = DocumentData.Ref";
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	SelectionOfDocuments = Query.Execute().Select();
	While SelectionOfDocuments.Next() Do
		
		ExceptionReason = "";
		Recommendation = "";
		
		BeginTransaction();
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", SelectionOfDocuments.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(
				SelectionOfDocuments.Ref, SelectionOfDocuments.DataVersion, Parameters.Queue); // DocumentObject.DiscrepancyReportFollowingShipment - 
			If DocumentObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(SelectionOfDocuments.Ref);
				CommitTransaction();
				Continue;
			EndIf;
			
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			For Each RowOfProduct In DocumentObject.Goods Do
				
				If Not ValueIsFilled(RowOfProduct.Action) Then
					Continue;
				EndIf;
				
				NewOptionsForAction = NewOptionsForSwitchingToNewVersion(RowOfProduct.Action);
				
				If ValueIsFilled(NewOptionsForAction.Action) Then
					RowOfProduct.Action = NewOptionsForAction.Action;
				EndIf;
				If ValueIsFilled(NewOptionsForAction.DiscrepancyTreatment) Then
					RowOfProduct.DiscrepancyTreatment = NewOptionsForAction.DiscrepancyTreatment;
				EndIf;
				
			EndDo;
			
			For Each RowSeries In DocumentObject.SetOfSeries Do
				
				If Not ValueIsFilled(RowSeries.Action) Then
					Continue;
				EndIf;
				
				NewOptionsForAction = NewOptionsForSwitchingToNewVersion(RowSeries.Action);
				
				If ValueIsFilled(NewOptionsForAction.Action) Then
					RowSeries.Action = NewOptionsForAction.Action;
				EndIf;
				If ValueIsFilled(NewOptionsForAction.DiscrepancyTreatment) Then
					RowSeries.DiscrepancyTreatment = NewOptionsForAction.DiscrepancyTreatment;
				EndIf;
				
			EndDo;
			
			ExceptionReason = "Record";
			
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(SelectionOfDocuments.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
		Except
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), SelectionOfDocuments.Ref);
			
			If ExceptionReason = "BadData" Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					SelectionOfDocuments.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = "Record" Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise NStr("vi = 'Không thể xử lý chứng từ ""Biên bản chênh lệch sau khi giao hàng"".';
							|ru = 'Не удалось обработать документ ""Акт о расхождениях после отгрузки"".';
							|en = 'Cannot process the ""Sales dispute"" document.'; fa = 'Cannot process the ""Sales dispute"" document.';
							|it = 'Cannot process the ""Sales dispute"" document.';
							|pl = 'Cannot process the ""Sales dispute"" document.';
							|tr = '""Sevkiyat Sonrası Tutarsızlık Tutanağı"" belgesi işlenemedi.'");
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	If ObjectsProcessed > 0 Then
		InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
	EndIf;
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

Function NewOptionsForSwitchingToNewVersion(PossibleAction)
	
	NewOptionsForAction = New Structure;
	NewOptionsForAction.Insert("Action", Undefined);
	NewOptionsForAction.Insert("DiscrepancyTreatment", Undefined);
	
	// Shortages
	If PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteReduceTransferOfTitleToGoods Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired); // ApplyAppearance
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.Wait);
	ElsIf PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteWriteOff Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired); // ApplyAppearance
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
	ElsIf PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteWriteOffAndSupplyAdditionally Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired); // Issue and add
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.WriteOffInTransit);
	// Surpluses
	ElsIf PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteReRegisterTransferOfTitleToGoods Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery); // ApplyAppearance
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
	ElsIf PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteReceiptIsRequired Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery); // ApplyAppearance
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
	ElsIf PossibleAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.DeleteReceiveAndCreateGoodsReturn Then
		NewOptionsForAction.Insert("Action", Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered); // Issue and return
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.ReceiveInTransit);
	Else
		NewOptionsForAction.Insert("DiscrepancyTreatment", Enums.OptionsForActionsOnGoodsInCustomerInvoiceAfterGoodsIssue.TakeIntoAccountDuringPhysicalInventoryCount);
	EndIf;
	
	Return NewOptionsForAction;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
