#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,DocumentCreationOption,BusinessOperation,SalesOrderStatus,StatusOfCustomerInvoice,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	OrderDocument = ProductsClientServer.SeriesSpecificationParameters();
	
	OrderDocument.FullObjectName = "DataProcessor.SalesWizard";
	OrderDocument.TSSeriesName = "Goods";
	
	If Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal
		And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		
		OrderDocument.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
		OrderDocument.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	Else
		OrderDocument.UseItemsBatch  = False;
		OrderDocument.UseCostAccountingByBatches = False;
	EndIf;
		
	OrderDocument.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	OrderDocument.LinkFields.Add("RegistrationOption");
	OrderDocument.LinkFields.Add("Warehouse");
	
	OrderDocument.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	OrderDocument.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	OrderDocument.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	OrderDocument.ThisIsOrder = True;
	
	OrderDocument.ShipmentPlanning = True;
	OrderDocument.RegisterSeries = False;
	
	OrderDocument.Date = CurrentSessionDate();
	
	SaleOfGoodsAndServices = ProductsClientServer.SeriesSpecificationParameters();
	
	SaleOfGoodsAndServices.FullObjectName = "DataProcessor.SalesWizard";
	
	TransferOfGoodsForStorage = False;
	ImplementationOfLocalAccounting = Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting;
	TransferOfGoodsForStorage = Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
	If Object.DocumentCreationOption <> Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Then
		SaleOfGoodsAndServices.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		
		If ImplementationOfLocalAccounting Then
			SaleOfGoodsAndServices.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
		Else
			SaleOfGoodsAndServices.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch;
		EndIf;	
	Else
		SaleOfGoodsAndServices.UseItemsBatch  = False;
		SaleOfGoodsAndServices.UseCostAccountingByBatches = False;
	EndIf;
	
	SaleOfGoodsAndServices.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
	
	SaleOfGoodsAndServices.LinkFields.Add("RegistrationOption");
	SaleOfGoodsAndServices.LinkFields.Add("Warehouse");
	
	SaleOfGoodsAndServices.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SaleOfGoodsAndServices.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SaleOfGoodsAndServices.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	SaleOfGoodsAndServices.ThisIsAnInvoice = True;
	
	SaleOfGoodsAndServices.SeriesOnlyForCostPrice = ImplementationOfLocalAccounting;
	
	If GetFunctionalOption("UseStatusesOfGoodsServicesSales") Then
		SaleStatus = Object.StatusOfCustomerInvoice;
	Else
		SaleStatus = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
	If TransferOfGoodsForStorage Then
		SaleOfGoodsAndServices.SelectionPlanning = True;
		SaleOfGoodsAndServices.FactOfSelection         = True;
	Else
		SaleOfGoodsAndServices.ShipmentPlanning = SaleStatus = Enums.StatusesOfCustomerInvoices.ForPrepayment;
		SaleOfGoodsAndServices.SelectionPlanning = SaleStatus = Enums.StatusesOfCustomerInvoices.Shipped;
		SaleOfGoodsAndServices.FactOfSelection = SaleStatus = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
	SaleOfGoodsAndServices.RegisterSeries = ProductsClientServer.ItIsNecessaryToRegisterSeries(SaleOfGoodsAndServices);
	
	SaleOfGoodsAndServices.Date = CurrentSessionDate();
	
	SeriesSpecificationParameters = New Structure;
	SeriesSpecificationParameters.Insert("SaleOfGoodsAndServices", SaleOfGoodsAndServices);
	SeriesSpecificationParameters.Insert("OrderDocument", OrderDocument);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	If SeriesSpecificationParameters.ThisIsAnInvoice Then
		QueryText = 
		"SELECT
		|	Goods.RegistrationOption,
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Series,
		|	Goods.Count,
		|	Goods.BatchesIndicationStatus,
		|	Goods.BatchesIndicationStatusInWarehouses,
		|	Goods.BatchesIndicationStatusOfGoodsTransferred,
		|	Goods.LineNumber
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.RegistrationOption,
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SetOfSeries.Count
		|INTO SetOfSeries
		|FROM
		|	&SetOfSeries AS SetOfSeries
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.RegistrationOption,
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	SUM(Goods.Count) AS Count,
		|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
		|INTO ProductsToRequest
		|FROM
		|	Goods AS Goods
		|
		|GROUP BY
		|	Goods.RegistrationOption,
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	CAST(Goods.Products AS Catalog.Products).ProductKind
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SetOfSeries.RegistrationOption,
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic,
		|	SUM(SetOfSeries.Count) AS Count
		|INTO SeriesToRequest
		|FROM
		|	SetOfSeries AS SetOfSeries
		|
		|GROUP BY
		|	SetOfSeries.RegistrationOption,
		|	SetOfSeries.Warehouse,
		|	SetOfSeries.Products,
		|	SetOfSeries.Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
		|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
		|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
		|	CASE
		|		WHEN Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal)
		|			THEN 0
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
		|			THEN 0
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
		|			THEN CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 14
		|					ELSE 13
		|				END
		|		WHEN &SeriesOnlyForCostPrice
		|			THEN 0
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
		|				AND &SelectionPlanning
		|			THEN CASE
		|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
		|						THEN CASE
		|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|										AND ProductsToRequest.Count > 0
		|									THEN 6
		|								ELSE 5
		|							END
		|					ELSE CASE
		|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|									AND ProductsToRequest.Count > 0
		|								THEN 8
		|							ELSE 7
		|						END
		|				END
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
		|				AND &FactOfSelection
		|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnShipmentToCustomer
		|			THEN CASE
		|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
		|						THEN CASE
		|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|										AND ProductsToRequest.Count > 0
		|									THEN 4
		|								ELSE 3
		|							END
		|					ELSE CASE
		|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
		|									AND ProductsToRequest.Count > 0
		|								THEN 2
		|							ELSE 1
		|						END
		|				END
		|		ELSE 0
		|	END AS BatchesIndicationStatus,
		|	CASE
		|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
		|				AND NOT &UseTransferForSafekeeping
		|			THEN 0
		|		ELSE
		|			CASE
		|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
		|					THEN
		|						CASE
		|							WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
		|								THEN
		|									CASE
		|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|											THEN 18
		|										ELSE 17
		|									END
		|								ELSE 0
		|						END
		|					ELSE 0
		|			END
		|	END AS BatchesIndicationStatusOfGoodsTransferred
		|INTO Statuses
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN ProductsToRequest AS ProductsToRequest
		|			LEFT JOIN SeriesToRequest AS SeriesToRequest
		|			ON ProductsToRequest.Products = SeriesToRequest.Products
		|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
		|				AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
		|				AND ProductsToRequest.RegistrationOption = SeriesToRequest.RegistrationOption
		|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|				INNER JOIN Catalog.Warehouses AS Warehouses
		|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
		|			ON BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse
		|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
		|		ON Goods.Products = ProductsToRequest.Products
		|			AND Goods.Characteristic = ProductsToRequest.Characteristic
		|			AND Goods.Warehouse = ProductsToRequest.Warehouse
		|			AND Goods.RegistrationOption = ProductsToRequest.RegistrationOption
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Statuses.LineNumber AS LineNumber,
		|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatusInWarehouses,
		|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
		|	CASE
		|		WHEN Statuses.BatchesIndicationStatus = 0
		|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
		|		ELSE Statuses.BatchesIndicationStatus
		|	END AS BatchesIndicationStatus
		|FROM
		|	Statuses AS Statuses
		|WHERE
		|	CASE
		|		WHEN Statuses.BatchesIndicationStatus = 0
		|			THEN Statuses.BatchesIndicationStatusOfGoodsTransferred
		|		ELSE Statuses.BatchesIndicationStatus
		|	END <> Statuses.OldStatusOfSpecifyingSeries
		|	OR Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
		|	OR Statuses.BatchesIndicationStatusOfGoodsTransferred <> Statuses.OldStatusOfSpecifyingSeriesOfTransferredGoods
		|
		|ORDER BY
		|	LineNumber";
	ElsIf SeriesSpecificationParameters.ThisIsOrder Then
		QueryText = 
		"SELECT
		|	Goods.Warehouse,
		|	Goods.Products,
		|	Goods.Series,
		|	Goods.Canceled,
		|	Goods.SupplyOption,
		|	Goods.Count,
		|	Goods.BatchesIndicationStatus,
		|	Goods.BatchesIndicationStatusInWarehouses,
		|	Goods.BatchesIndicationStatusOfGoodsTransferred,
		|	Goods.LineNumber,
		|	Goods.RegistrationOption
		|INTO Goods
		|FROM
		|	&Goods AS Goods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
		|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
		|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
		|	CASE
		|		WHEN Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.CustomerInvoice)
		|				OR Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee)
		|				OR Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer)
		|				OR Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice)
		|			THEN Goods.BatchesIndicationStatus
		|		WHEN Goods.Canceled
		|				OR Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.CommercialProposal)
		|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL
		|				OR NOT Goods.SupplyOption IN(
		|						VALUE(Enum.SupplyOptions.FromWarehouse),
		|						VALUE(Enum.SupplyOptions.Ship))
		|			THEN 0
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
		|			THEN CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 14
		|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
		|						THEN 15
		|					ELSE 13
		|				END
		|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
		|			THEN CASE
		|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|						THEN 10
		|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
		|						THEN 11
		|					ELSE 9
		|				END
		|		ELSE 0
		|	END AS BatchesIndicationStatus,
		|	0 AS BatchesIndicationStatusOfGoodsTransferred
		|INTO Statuses
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
		|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
		|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Statuses.LineNumber AS LineNumber,
		|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatusInWarehouses,
		|	Statuses.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
		|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
		|FROM
		|	Statuses AS Statuses
		|WHERE
		|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
		|
		|ORDER BY
		|	LineNumber";
	Else
		ExceptionText = NStr("vi = 'Lỗi xác định nội dung truy vấn để điền trạng thái chỉ ra sê-ri.';
							|ru = 'Ошибка определения текста запроса для заполнения статуса указания серий.';
							|en = 'An error occurred while determining a query text to fill in the batch specification status.'; fa = 'An error occurred while determining a query text to fill in the batch specification status.';
							|it = 'Errore nella definizione del testo della domanda di compilazione dello stato dell''indicazione serie.';
							|pl = 'Błąd ustalenia tekstu żądania dla wypełnienia statusu wskazania serii.';
							|tr = 'Seri göstergesinin durumunu doldurmak için sorgu metninin tanımlanmasında hata.'");
		
		Raise ExceptionText;
	EndIf;
	
	QueryCondition = "FALSE";
	
	UseTransferForSafekeeping = GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
	QueryCondition = ?(UseTransferForSafekeeping,
						"(Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.TransferOfGoodsToBailee)
						|	OR Goods.RegistrationOption = VALUE(Enum.OptionsOfRegisteringSalesDocuments.OrderTransfer))",
						QueryCondition);
	
	QueryText = StrReplace(QueryText, "&UseTransferForSafekeeping", QueryCondition);
	
	Return QueryText;
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DataProcessorObject.SalesWizard - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;
	FillParameters.Date = Object.Date;
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	If Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CommercialProposal Or
		Object.DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		
		FillParameters.ThisIsOrder = True;
		
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Or
		Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle  Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;

	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer Then
		
		FillParameters.GoodsSales = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation,
			|DocumentCreationOption");
		BusinessOperation       = StructureFillingData.BusinessOperation;
		DocumentCreationOption = StructureFillingData.DocumentCreationOption;
	ElsIf FillingData = Undefined Then
		BusinessOperation       = Undefined;
		DocumentCreationOption = Undefined
	Else
		BusinessOperation       = FillingData.BusinessOperation;
		DocumentCreationOption = FillingData.DocumentCreationOption;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomerLocalAccounting")
		Or BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToStorageWithRightOfSale");
	ParametersStructure.ModifiesDeliveryShipmentPlan     = True;
	
	If DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrder Then
		ParametersStructure.ThisIsOrder                         = True;
		ParametersStructure.ThisIsSalePurchase                = False;
	ElsIf DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.CustomerInvoice Then
		ParametersStructure.ThisIsOrder                         = False;
		ParametersStructure.ThisIsSalePurchase                = True;
	ElsIf DocumentCreationOption = Enums.OptionsOfRegisteringSalesDocuments.SalesOrderCustomerInvoice Then
		ParametersStructure.ThisIsOrder                         = True;
		ParametersStructure.ThisIsSalePurchase                = True;
	Else
		ParametersStructure.ChangesPaymentPlan               = False;
		ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
	EndIf;
	
	ParametersStructure.ARAPCurrency             = "";
	ParametersStructure.AmountARAP              = "";
	ParametersStructure.AmountARAPByPackage        = "";
	ParametersStructure.CompanyBankAccount		 = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount		 = "Object.CounterpartyBankAccount";
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.PaymentMethod                      = "Object.PaymentMethod";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	ParametersStructure.SourceOfAmountsTabularPart       = True;

	ParametersStructure.PaymentID			 = "";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.DateOfShipment                     = "Object.DateOfShipment"; 
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSOrder              = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "";
	
	ParametersStructure.Manager                         = "Object.Manager";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.DocumentAmountForm              = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	ParametersStructure.ToReturnReusablePackage        = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired             = "Object.PackageDepositIsRequired";
	
	Return ParametersStructure;
	
EndFunction

// Forms the structure of the document parameters for embedding the document in the software algorithms.
//
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions() Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "Goods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "GoodsSupplyOption";
	FormItems.Available           = "GoodsAvailable";
	FormItems.Series              = "GoodsSeries";
	FormItems.WithAssignment        = "GoodsWithAssignment";
	FormItems.Warehouse              = "GoodsWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.Goods.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.Goods.Canceled";
	DataPaths.ItemsType = "Object.Goods.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.Goods.CurrentData.Available";
	Links.NumberOfPackages    = "Items.Goods.CurrentData.NumberOfPackages";
	Links.Count            = "Items.Goods.CurrentData.Count";
	Links.ShipIfAvailable = "Items.Goods.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.Goods.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.Goods.CurrentData.ItemsType";
	Links.Package              = "Items.Goods.CurrentData.Package";
	Links.Products          = "Items.Goods.CurrentData.Products";
	Links.SupplyOption    = "Items.Goods.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.Goods.CurrentData.Warehouse";
	Links.MultipleWarehouses      = "WarehouseGroup_";
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "ShipmentAndReturnReferences";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Form";
	EmbeddingParameters.TableName = "Form.Object.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	Attributes.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.SalesOrderStatus IN(
		|			VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip),
		|			VALUE(Enum.SalesOrderStatuses.Closed)
		|		) AS ReadyForSupply,
		|	TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		OR Attributes.SalesOrderStatus IN(
		|			VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip),
		|			VALUE(Enum.SalesOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	VALUE(Catalog.Priorities.EmptyRef) AS Priority,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				UNDEFINED
		|		END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Form.Object.Goods AS TabPart
		|		
		|		LEFT JOIN Form.Object AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	Goods = New Structure();
	Goods.Insert("LineNumber",        New TypeDescription("Number"));
	Goods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	Goods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Goods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Goods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	Goods.Insert("Count",         New TypeDescription("Number"));
	Goods.Insert("NumberOfPackages", New TypeDescription("Number"));
	Goods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Insert("DateOfShipment",       New TypeDescription("Date"));
	Goods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Insert("Canceled",           New TypeDescription("Boolean"));
	Goods.Insert("RowCode",          New TypeDescription("Number"));
	
	Object = New Structure();
	Object.Insert("Department",       New TypeDescription("CatalogRef.BusinessStructure"));
	Object.Insert("Purpose",          New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",              New TypeDescription("DocumentRef.SalesOrder"));
	Object.Insert("SalesOrderStatus", New TypeDescription("EnumRef.SalesOrderStatuses"));
	Object.Insert("NotShipInInstallments",  New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",        New TypeDescription("Date"));
	Object.Insert("Date",                New TypeDescription("Date"));
	Object.Insert("Warehouse",               New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Goods",              Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	Return EmbeddingParameters;
	
EndFunction

#Region BasisForPrint

// Returns a table of default values for the "Base" attribute"
//
// Parameters:
//	Object - FormDataStructure, DataProcessorObject.SalesWizard - The object to get the selection list for.
//
// Returns:
//	ValueTable - A table of values with the details of the bases.
//
Function PrintBasisTable(Object) Export
	
	ThisIsTransferToCommission = (Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	ThisIsTransferToStorage = 
		(Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	
	TableOfBases_ = New ValueTable;
	TableOfBases_.Columns.Add("Basis",      New TypeDescription("String",,,,New StringQualifiers(300)));
	TableOfBases_.Columns.Add("ReferenceDocumentDateForPrintForms",  New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.Date))); 
	TableOfBases_.Columns.Add("BaseDocumentNumber", New TypeDescription("String",,,,New StringQualifiers(128)));
	
	BaseStructure = BaseStructure(Object, Enums.ARAPObjectSettings.ByCounterpartyContracts);
	If ValueIsFilled(BaseStructure.Basis) Then
		AddedRow = TableOfBases_.Add();
		FillPropertyValues(AddedRow, BaseStructure);
		AddedRow.Basis = BaseStructure.Basis
						+ ?(ThisIsTransferToCommission, ", " + NStr("vi = 'chuyển đi ký gửi';
																	|ru = 'передача на комиссию';
																	|en = 'consignment sales'; fa = 'consignment sales';
																	|it = 'trasferimento in conto vendita';
																	|pl = 'przekazanie do komisu';
																	|tr = 'konsinye satış'"),
							?(ThisIsTransferToStorage, ", " + NStr("vi = 'Chuyển đến lưu trữ.';
																	|ru = 'передача на хранение';
																	|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
																	|it = 'trasferimento in deposito';
																	|pl = 'przekazanie do przechowywania';
																	|tr = 'depoya transfer'"), ""));
	EndIf;
	
	If (ThisIsTransferToCommission
			Or ThisIsTransferToStorage)
		And TableOfBases_.Count()=0 Then
		
		AddedRow = TableOfBases_.Add();
		AddedRow.Basis = ?(ThisIsTransferToCommission,
										NStr("vi = 'chuyển đi ký gửi';
											|ru = 'передача на комиссию';
											|en = 'consignment sales'; fa = 'consignment sales';
											|it = 'trasferimento in conto vendita';
											|pl = 'przekazanie do komisu';
											|tr = 'konsinye satış'"),
										NStr("vi = 'Chuyển đến lưu trữ.';
											|ru = 'передача на хранение';
											|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
											|it = 'trasferimento in deposito';
											|pl = 'przekazanie do przechowywania';
											|tr = 'depoya transfer'"));
		
	EndIf;
	
	Return TableOfBases_;
	
EndFunction

// Returns the base text based on the document data
//
// Parameters:
//	Object - FormDataStructure, DataProcessorObject.SalesWizard - Object to get the base text from
//	ARAPObjectSettings - EnumRef.ARAPObjectSettings - The procedure for calculating the document.
//
// Returns:
//	Structure - Structure with the name, date and number of the foundation.
//
Function BaseStructure(Object, ARAPObjectSettings) Export
	
	StructureBase = New Structure("Basis, BaseDocumentNumber, ReferenceDocumentDateForPrintForms");
	
	If ValueIsFilled(Object.Contract)
		And ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts Then
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CounterpartyContracts.NameForPrinting AS Basis,
		|	CounterpartyContracts.Date                  AS ReferenceDocumentDateForPrintForms,
		|	CounterpartyContracts.Number                 AS BaseDocumentNumber
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Ref = &Ref";
		
		Query.SetParameter("Ref", Object.Contract);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			StructureBase.Basis      = TrimAll(Selection.Basis);
			StructureBase.ReferenceDocumentDateForPrintForms  = Selection.ReferenceDocumentDateForPrintForms;
			StructureBase.BaseDocumentNumber = TrimAll(Selection.BaseDocumentNumber);
		EndIf;
		
	EndIf;
	
	Return StructureBase; // Returning the default value
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Internal

#EndRegion

#Region Other

Function OrderAmounts(ObjectReference_,AttributesValues) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Goods.AmountIncludingVAT           AS Sum,
	|	Goods.Products        AS Products
	|INTO TTProducts_1
	|FROM &Table AS Goods
	|;
	|SELECT 
	|	UNDEFINED                                     AS OrderDocument,
	|	DATETIME(1,1,1)                                 AS OrderDate,
	|	DATETIME(1,1,1)                                 AS ApprovalDate,
	|	FALSE                                             AS ExceedingOrder,
	|	SUM(NestedQuery.PaymentAmount)              AS PaymentAmount,
	|	0                                                AS AmountARAP,
	|	SUM(NestedQuery.PackageDepositValue)         AS PackageDepositValue,
	|	0                                                AS AmountARAPByPackage
	|FROM (SELECT
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT &ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                             AS PaymentAmount,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue
	|	FROM TTProducts_1 AS Goods) AS NestedQuery
	|;";
	
	Query.SetParameter("ToReturnReusablePackage", AttributesValues.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", AttributesValues.PackageDepositIsRequired);
	Query.SetParameter("Table", AttributesValues.ValueTable);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndRegion

#EndIf
