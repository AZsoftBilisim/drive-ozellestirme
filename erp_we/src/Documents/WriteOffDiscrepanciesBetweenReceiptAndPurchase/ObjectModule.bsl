#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.WriteOffDiscrepanciesBetweenReceiptAndPurchase - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();

	If WriteMode = DocumentWriteMode.UndoPosting Then
		ParametersForFillingInventoryTypes.UseSeparateProcurement = True;
	EndIf;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);

EndProcedure

// Fills in the purchase conditions
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Organization)
		And PurchaseConditions.Organization <> Organization Then
		
		Organization = PurchaseConditions.Organization;
		
	EndIf;

	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse = PurchaseConditions.Warehouse;
	EndIf;
	
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Counterparty)
		And PurchaseConditions.Counterparty <> Counterparty Then
		
		Counterparty = PurchaseConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
		ContractBusinessTransaction = PairsOfSeparatePurchaseOperations.Get(Enums.BusinessTransactions.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	EndIf;
	
	FillInTypeOfActivityVAT();
	
EndProcedure

Procedure FillInDefaultPurchaseConditions() Export
	
	If ValueIsFilled(Partner) Then
		
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		
		AgreementSelectionParameters_ = New Structure;
		AgreementSelectionParameters_.Insert("SelectedAgreement",                     Terms);
		AgreementSelectionParameters_.Insert("BusinessTransactions",                   BusinessTransactions);
		AgreementSelectionParameters_.Insert("ConsiderWarehouseGroups",                  False);
		AgreementSelectionParameters_.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, AgreementSelectionParameters_);
		
		PricesAreFilledOut = False;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
			
			PairsOfSeparatePurchaseOperations	= PurchasesServer.PairsOfSeparatePurchaseOperations();
			ContractBusinessTransaction	= PairsOfSeparatePurchaseOperations.Get(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
			CurBusinessTransaction	= ContractBusinessTransaction;
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
			
			FillInTypeOfActivityVAT();
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills In The Attributes that Store information about inventory types and Inventory Accounting analysts in the tabular part of the 'Discrepancies'
// document, and also fills in the tabular part of the 'Inventory types'.
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	Else
		ParameterName = "DocumentTables";
		
		ExceptionText = NStr("vi = 'Để điền dạng vật tư, không chuyển tham số ""%1"".';
							|ru = 'Для заполнения видов запасов не передан параметр ""%1"".';
							|en = 'The ""%1"" parameter is not passed to fill the inventory owner attributes.'; fa = 'The ""%1"" parameter is not passed to fill the inventory owner attributes.';
							|it = 'Per la compilazione dei tipi di scorte non è indicato il parametro ""%1"".';
							|pl = 'Do wypełnienia rodzajów zapasów nie przekazano parametru ""%1"".';
							|tr = 'Stok türlerini tamamlamak için ""%1"" parametresi geçilmemiştir.'");
		ExceptionText = StrTemplate(ExceptionText, ParameterName);
		
		Raise ExceptionText;
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ParametersForCheckingWhetherCharacteristicsAreFilledIn = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn(); 
	ParametersForCheckingWhetherCharacteristicsAreFilledIn.TSName = "Discrepancies";
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,ParametersForCheckingWhetherCharacteristicsAreFilledIn);

	ParametersForCheckingFillingQuantity = ProductsServer.ParametersForCheckingFillingQuantity();
	ParametersForCheckingFillingQuantity.TSName = "Discrepancies";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, ParametersForCheckingFillingQuantity);

	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase),
												Cancel,
												NotCheckedAttributeArray);
	
	WorksServices = New Array;
	WorksServices.Add(Enums.ItemsTypes.Work_5);
	WorksServices.Add(Enums.ItemsTypes.OperationService);
	
	If Not ValueIsFilled(Warehouse) Then
		For CurIndex__ = 0 To Discrepancies.Count()-1 Do
			
			LineProducts_ = Discrepancies[CurIndex__]; // LineOfATabularSection
			
			If WorksServices.Find(Common.ObjectAttributeValue(LineProducts_.Products, "ItemsType")) = Undefined Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
								|ru = 'Поле ""Склад"" не заполнено.';
								|en = 'The Warehouse field is required.'; fa = 'The Warehouse field is required.';
								|it = 'Il campo ""Magazzino"" non è compilato.';
								|pl = 'Nie wypełniono pole ""Magazyn"".';
								|tr = '""Ambar"" alanı doldurulmamış.'");
					
				Common.MessageToUser(
					ErrorText,,
					"Object.Warehouse",,
					Cancel);
				
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	ThereAreOverpayments = False;
	ThereAreShortDeliveries = False;
	For Each LineProducts_ In Discrepancies Do
		If LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery Then 
			ThereAreShortDeliveries = True;
		EndIf;
		If LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Overdelivery Then 
			ThereAreOverpayments = True;
		EndIf;
	EndDo;
	If ThereAreOverpayments Then
		CheckedAttributes.Add("IncomeItem");
	EndIf;

	If ThereAreShortDeliveries Then
		CheckedAttributes.Add("ExpenseItem");
	EndIf;    
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	// Selection of articles and analytics.
	ArticleAvailabilityParameters = New Structure("ThereAreOverpayments, ThereAreShortDeliveries, FillCheckProcessing", ThereAreOverpayments, ThereAreShortDeliveries, True);
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);

	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	Var Warehouse;
	
	Author = Users.CurrentUser();
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("DocumentBasis") Then
			If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder") Then
				
				FillingData.Property("Warehouse", Warehouse);

				FillInDocumentBasedOnOrderToSupplier(FillingData.DocumentBasis, Warehouse);
				
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
				
				FillingData.Property("Warehouse", Warehouse);
				FillInDocumentBasedOnPurchaseOfGoods(FillingData.DocumentBasis,
																Warehouse,
																Common.ObjectAttributeValue(FillingData.DocumentBasis, "BusinessOperation"));
			ElsIf TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
				
				FillingData.Property("Warehouse", Warehouse);
				FillInDocumentOnBasisOfContract(FillingData.DocumentBasis);

			EndIf;
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			FillInDocumentOnBasisOfAcceptanceCertificateAfterPurchase(FillingData);
			
		EndIf;
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		
		FillInDocumentOnBasisOfContract(FillingData);

	ElsIf TypeOf(FillingData) = Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);

	// Selection of articles and analytics.
	ThereAreOverpayments = False;
	ThereAreShortDeliveries = False;
	For Each LineProducts_ In Discrepancies Do
		If LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery Then 
			ThereAreShortDeliveries = True;
		EndIf;
		If LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Overdelivery Then 
			ThereAreOverpayments = True;
		EndIf;
	EndDo;
		
	ArticleAvailabilityParameters = New Structure("ThereAreOverpayments, ThereAreShortDeliveries", ThereAreOverpayments, ThereAreShortDeliveries);
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject, DocumentWriteMode.UndoPosting);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	WriteOffDiscrepanciesBetweenReceiptAndPurchaseLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase);
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryKinds.Clear();
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Discrepancies,InventoryKinds");
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.AccountingAccountSettings_());
	// Selection of articles and analytics.
	ThereAreOverpayments = False;
	ThereAreShortDeliveries = False;
	For Each LineProducts_ In Discrepancies Do
		ThereAreShortDeliveries = LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery;
		ThereAreOverpayments = LineProducts_.DiscrepanciesKind = Enums.DiscrepanciesKindOfReceiptsPurchases.Overdelivery;
	EndDo;
	
	ArticleAvailabilityParameters = New Structure("ThereAreOverpayments, ThereAreShortDeliveries", ThereAreOverpayments, ThereAreShortDeliveries);
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ItemsAndDimensionsSelectionParameters(ArticleAvailabilityParameters);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse       = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not ValueIsFilled(ReferenceOrder) Then
		ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	EndIf;
	
	FillInTypeOfActivityVAT();
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	TypesOfBases_ = New Array;
	TypesOfBases_.Add(Type("DocumentRef.WriteOffDiscrepanciesBetweenReceiptAndPurchase"));
	TypesOfBases_.Add(Type("CatalogRef.CounterpartyContracts"));
	TypesOfBases_.Add(Type("CatalogRef.TermsOfPurchaseFromVendors"));
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And TypesOfBases_.Find(TypeOf(FillingData.DocumentBasis)) <> Undefined Then
		
		Return FillingData.DocumentBasis;
		
	ElsIf TypesOfBases_.Find(TypeOf(FillingData)) <> Undefined Then 
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function TextOfFillInRequestBasedOn(AccordingToActOfDivergence = False)
	
	QueryText = 
	"SELECT
	|	PurchaseOfGoods.Ref AS Ref,
	|	PurchaseOfGoods.Terms AS Terms,
	|	PurchaseOfGoods.Partner AS Partner,
	|	PurchaseOfGoods.Counterparty AS Counterparty,
	|	PurchaseOfGoods.Organization AS Organization,
	|	PurchaseOfGoods.Contract AS Contract,
	|	CASE
	|		WHEN PurchaseOfGoods.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
	|			THEN PurchaseOfGoods.Contract
	|		WHEN PurchaseOfGoods.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
	|			THEN PurchaseOfGoods.Terms
	|		WHEN NOT PurchaseOfGoods.ReceiptUnderOrders
	|				AND PurchaseOfGoods.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
	|			THEN PurchaseOfGoods.Ref
	|		WHEN PurchaseOfGoods.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|			THEN PurchaseOfGoods.Ref
	|		ELSE PurchaseOfGoods.PurchaseOrder
	|	END AS ReferenceOrder,
	|	PurchaseOfGoods.SalesOpportunity AS SalesOpportunity,
	|	PurchaseOfGoods.Currency AS Currency,
	|	&WarehouseForReceipt AS Warehouse,
	|	ISNULL(Terms1.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
	|	PurchaseOfGoods.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseOfGoods.VATTaxation AS VATTaxation,
	|	PurchaseOfGoods.Department AS Department,
	|	PurchaseOfGoods.PurchaseForActivity AS VATActivityType,
	|	PurchaseOfGoods.LineOfBusiness AS LineOfBusiness,
	|	NOT PurchaseOfGoods.Posted AS ThereAreErrorsPosted,
	|	FALSE AS ThereAreErrorsStatus
	|INTO TTOrder_
	|FROM
	|	Document.VendorInvoice AS PurchaseOfGoods
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON PurchaseOfGoods.Terms = Terms1.Ref
	|WHERE
	|	PurchaseOfGoods.Ref = &DocumentBasis
	|
	|INDEX BY
	|	Ref,
	|	Contract
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS Count,
	|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS NumberOfPackages
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|				AND CASE
	|					WHEN &WarehouseSpecified
	|						THEN Warehouse = &WarehouseForReceipt
	|					ELSE TRUE
	|				END) AS GoodsToReceive
	|WHERE
	|	NOT &FillInUsingInvoice
	|	AND GoodsToReceive.ToRegisterReceiptsByReferenceBalance <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Purpose,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|				AND CASE
	|					WHEN &WarehouseSpecified
	|						THEN Warehouse = &WarehouseForReceipt
	|					ELSE TRUE
	|				END) AS GoodsToReceive
	|WHERE
	|	&FillInUsingInvoice
	|	AND GoodsToReceive.ToRegisterReceiptsByInvoicesBalance <> 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackagingOfGoods.DocumentInflow AS DocumentInflow,
	|	PackagingOfGoods.Warehouse AS Warehouse,
	|	PackagingOfGoods.Products AS Products,
	|	PackagingOfGoods.Characteristic AS Characteristic,
	|	PackagingOfGoods.Purpose AS Purpose,
	|	PackagingOfGoods.Series AS Series,
	|	PackagingOfGoods.Package AS Package,
	|	&QueryTextPackagingFactor AS PackagingFactor,
	|	SUM(PackagingOfGoods.Count) AS Count,
	|	SUM(PackagingOfGoods.NumberOfPackages) AS NumberOfPackages
	|INTO TTPackagingOfGoods
	|FROM
	|	(SELECT
	|		GoodsToReceive.DocumentInflow AS DocumentInflow,
	|		GoodsToReceive.Warehouse AS Warehouse,
	|		GoodsToReceive.Products AS Products,
	|		GoodsToReceive.Characteristic AS Characteristic,
	|		GoodsToReceive.Purpose AS Purpose,
	|		GoodsToReceive.Series AS Series,
	|		AcquisitionGoods.Package AS Package,
	|		SUM(AcquisitionGoods.Count) AS Count,
	|		SUM(AcquisitionGoods.NumberOfPackages) AS NumberOfPackages
	|	FROM
	|		TTProducts_1 AS GoodsToReceive
	|			LEFT JOIN Document.VendorInvoice.Goods AS AcquisitionGoods
	|			ON GoodsToReceive.DocumentInflow = AcquisitionGoods.Ref
	|				AND GoodsToReceive.Warehouse = AcquisitionGoods.Warehouse
	|				AND GoodsToReceive.Products = AcquisitionGoods.Products
	|				AND GoodsToReceive.Characteristic = AcquisitionGoods.Characteristic
	|				AND GoodsToReceive.Purpose = AcquisitionGoods.Purpose
	|				AND (CASE
	|					WHEN AcquisitionGoods.BatchesIndicationStatus IN (14, 18)
	|						THEN GoodsToReceive.Series = AcquisitionGoods.Series
	|					ELSE TRUE
	|				END)
	|	
	|	GROUP BY
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse,
	|		GoodsToReceive.Products,
	|		GoodsToReceive.Characteristic,
	|		GoodsToReceive.Purpose,
	|		GoodsToReceive.Series,
	|		AcquisitionGoods.Package
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse,
	|		GoodsToReceive.Products,
	|		GoodsToReceive.Characteristic,
	|		GoodsToReceive.Purpose,
	|		GoodsToReceive.Series,
	|		GoodsReceipts.Package,
	|		-SUM(GoodsReceipts.Count),
	|		-SUM(GoodsReceipts.NumberOfPackages)
	|	FROM
	|		TTProducts_1 AS GoodsToReceive
	|			LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS ReceiptToWarehouse
	|			ON GoodsToReceive.DocumentInflow = ReceiptToWarehouse.ReferenceOrder
	|				AND GoodsToReceive.Warehouse = ReceiptToWarehouse.Warehouse
	|			LEFT JOIN Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
	|			ON (ReceiptToWarehouse.Ref = GoodsReceipts.Ref)
	|				AND GoodsToReceive.Products = GoodsReceipts.Products
	|				AND GoodsToReceive.Characteristic = GoodsReceipts.Characteristic
	|				AND GoodsToReceive.Purpose = GoodsReceipts.Purpose
	|				AND (CASE
	|					WHEN GoodsReceipts.BatchesIndicationStatus IN (14, 18)
	|						THEN GoodsToReceive.Series = GoodsReceipts.Series
	|					ELSE TRUE
	|				END)
	|	WHERE
	|		ISNULL(ReceiptToWarehouse.Posted, FALSE)
	|	
	|	GROUP BY
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse,
	|		GoodsToReceive.Products,
	|		GoodsToReceive.Characteristic,
	|		GoodsToReceive.Purpose,
	|		GoodsToReceive.Series,
	|		GoodsReceipts.Package) AS PackagingOfGoods
	|
	|GROUP BY
	|	PackagingOfGoods.DocumentInflow,
	|	PackagingOfGoods.Warehouse,
	|	PackagingOfGoods.Products,
	|	PackagingOfGoods.Characteristic,
	|	PackagingOfGoods.Purpose,
	|	PackagingOfGoods.Series,
	|	PackagingOfGoods.Package
	|
	|HAVING
	|	SUM(PackagingOfGoods.Count) > 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Package AS Package,
	|	GoodsToReceive.PackagingFactor AS PackagingFactor,
	|	GoodsToReceive.Count AS Count,
	|	GoodsToReceive.NumberOfPackages AS NumberOfPackages,
	|	AcquisitionGoods.Price AS Price,
	|	AcquisitionGoods.VATRate AS VATRate
	|INTO TTPricesOfGoods
	|FROM
	|	TTPackagingOfGoods AS GoodsToReceive
	|		LEFT JOIN Document.VendorInvoice.Goods AS AcquisitionGoods
	|		ON GoodsToReceive.DocumentInflow = AcquisitionGoods.Ref
	|			AND GoodsToReceive.Warehouse = AcquisitionGoods.Warehouse
	|			AND GoodsToReceive.Products = AcquisitionGoods.Products
	|			AND GoodsToReceive.Characteristic = AcquisitionGoods.Characteristic
	|			AND GoodsToReceive.Purpose = AcquisitionGoods.Purpose
	|			AND (CASE
	|				WHEN AcquisitionGoods.BatchesIndicationStatus IN (14, 18)
	|					THEN GoodsToReceive.Series = AcquisitionGoods.Series
	|				ELSE TRUE
	|			END)
	|			AND GoodsToReceive.Package = AcquisitionGoods.Package
	|
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceive.DocumentInflow AS DocumentInflow,
	|	GoodsToReceive.Warehouse AS Warehouse,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Series AS Series,
	|	GoodsToReceive.Package AS Package,
	|	COUNT(DISTINCT GoodsToReceive.Price) AS NumberOfPrices,
	|	COUNT(DISTINCT GoodsToReceive.VATRate) AS NumberOfVATRates
	|INTO TTProductPricesGrouping
	|FROM
	|	TTPricesOfGoods AS GoodsToReceive
	|
	|GROUP BY
	|	GoodsToReceive.DocumentInflow,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Purpose,
	|	GoodsToReceive.Series,
	|	GoodsToReceive.Package
	|
	|INDEX BY
	|	DocumentInflow,
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableReferenceOrder.Ref AS Ref,
	|	TableReferenceOrder.Terms AS Terms,
	|	TableReferenceOrder.Partner AS Partner,
	|	TableReferenceOrder.Counterparty AS Counterparty,
	|	TableReferenceOrder.Organization AS Organization,
	|	TableReferenceOrder.Contract AS Contract,
	|	TableReferenceOrder.ReferenceOrder AS ReferenceOrder,
	|	TableReferenceOrder.SalesOpportunity AS SalesOpportunity,
	|	TableReferenceOrder.Currency AS Currency,
	|	TableReferenceOrder.Warehouse AS Warehouse,
	|	TableReferenceOrder.VendorPriceKind AS VendorPriceKind,
	|	TableReferenceOrder.PriceIncludesVAT AS PriceIncludesVAT,
	|	TableReferenceOrder.VATTaxation AS VATTaxation,
	|	TableReferenceOrder.VATActivityType AS VATActivityType,
	|	TableReferenceOrder.LineOfBusiness AS LineOfBusiness,
	|	TableReferenceOrder.Department AS Department,
	|	TableReferenceOrder.ThereAreErrorsPosted AS ThereAreErrorsPosted,
	|	TableReferenceOrder.ThereAreErrorsStatus AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.DocumentInflow AS DocumentInflow,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	SUM(CASE
	|			WHEN GoodsTable.Count < 0
	|				THEN -GoodsTable.Count
	|			ELSE GoodsTable.Count
	|		END) AS Count,
	|	SUM(CASE
	|			WHEN GoodsTable.NumberOfPackages < 0
	|				THEN -GoodsTable.NumberOfPackages
	|			ELSE GoodsTable.NumberOfPackages
	|		END) AS NumberOfPackages,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END AS DiscrepanciesKind
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.DocumentInflow AS DocumentInflow,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.Package AS Package,
	|	Goods.PackagingFactor AS PackagingFactor,
	|	SUM(CASE
	|			WHEN Goods.Count < 0
	|				THEN -Goods.Count
	|			ELSE Goods.Count
	|		END) AS Count,
	|	SUM(Goods.NumberOfPackages) AS NumberOfPackages,
	|	Goods.Price AS Price,
	|	Goods.VATRate AS VATRate
	|FROM
	|	(SELECT DISTINCT
	|		GoodsToReceive.DocumentInflow AS DocumentInflow,
	|		GoodsToReceive.Warehouse AS Warehouse,
	|		GoodsToReceive.Products AS Products,
	|		GoodsToReceive.Characteristic AS Characteristic,
	|		GoodsToReceive.Purpose AS Purpose,
	|		GoodsToReceive.Series AS Series,
	|		GoodsToReceive.Package AS Package,
	|		GoodsToReceive.PackagingFactor AS PackagingFactor,
	|		GoodsToReceive.Count AS Count,
	|		GoodsToReceive.NumberOfPackages AS NumberOfPackages,
	|		CASE
	|			WHEN ProductPrices.NumberOfPrices = 1
	|				THEN GoodsToReceive.Price
	|			ELSE 0
	|		END AS Price,
	|		CASE
	|			WHEN ProductPrices.NumberOfVATRates = 1
	|				THEN GoodsToReceive.VATRate
	|			ELSE 0
	|		END AS VATRate
	|	FROM
	|		TTPricesOfGoods AS GoodsToReceive
	|			LEFT JOIN TTProductPricesGrouping AS ProductPrices
	|			ON GoodsToReceive.DocumentInflow = ProductPrices.DocumentInflow
	|				AND GoodsToReceive.Warehouse = ProductPrices.Warehouse
	|				AND GoodsToReceive.Products = ProductPrices.Products
	|				AND GoodsToReceive.Characteristic = ProductPrices.Characteristic
	|				AND GoodsToReceive.Purpose = ProductPrices.Purpose
	|				AND GoodsToReceive.Series = ProductPrices.Series
	|				AND GoodsToReceive.Package = ProductPrices.Package) AS Goods
	|
	|GROUP BY
	|	Goods.DocumentInflow,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Package,
	|	Goods.PackagingFactor,
	|	Goods.Price,
	|	Goods.VATRate
	|
	|ORDER BY
	|	PackagingFactor DESC";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PackagingOfGoods.Package",
									"PackagingOfGoods.Products"));
									
	Return QueryText;
	
EndFunction

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

Procedure FillInDocumentBasedOnOrderToSupplier(DocumentBasis, Warehouse = Undefined)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PurchaseOrder.Ref					AS Ref,
	|	PurchaseOrder.Terms				AS Terms,
	|	PurchaseOrder.Partner					AS Partner,
	|	PurchaseOrder.Counterparty				AS Counterparty,
	|	PurchaseOrder.Organization				AS Organization,
	|	CASE 
	|		WHEN PurchaseOrder.Warehouse.IsFolder
	|	THEN 
	|		VALUE(Catalog.Warehouses.EmptyRef)
	|	ELSE
	|		PurchaseOrder.Warehouse
	|	END 									AS Warehouse,
	|	PurchaseOrder.Contract					AS Contract,
	|	PurchaseOrder.LineOfBusiness	AS LineOfBusiness,
	|	PurchaseOrder.Department			AS Department,
	|	PurchaseOrder.Status					AS Status,
	|	NOT PurchaseOrder.Posted				AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status IN (VALUE(Enum.PurchaseOrderStatuses.NotApproved),
	|										VALUE(Enum.PurchaseOrderStatuses.Approved))
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS ThereAreErrorsStatus
	|INTO TTOrder_
	|FROM
	|	Document.PurchaseOrder AS PurchaseOrder
	|		LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms1
	|		ON PurchaseOrder.Terms = Terms1.Ref
	|WHERE
	|	PurchaseOrder.Ref = &DocumentBasis
	|
	|INDEX BY
	|	Ref,
	|	Contract
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CASE
	|		WHEN GoodsToReceive.ToRegisterReceiptsByInvoicesBalance < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END AS DiscrepanciesKind,
	|	GoodsToReceive.Products AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Purpose AS Purpose,
	|	GoodsToReceive.Series AS Series,
	|	CASE 
	|		WHEN GoodsToReceive.ToRegisterReceiptsByInvoicesBalance < 0
	|	THEN
	|		-GoodsToReceive.ToRegisterReceiptsByInvoicesBalance
	|	ELSE
	|		GoodsToReceive.ToRegisterReceiptsByInvoicesBalance
	|	END AS Count,
	|	CASE 
	|		WHEN GoodsToReceive.ToRegisterReceiptsByInvoicesBalance < 0
	|	THEN
	|		-GoodsToReceive.ToRegisterReceiptsByInvoicesBalance
	|	ELSE
	|		GoodsToReceive.ToRegisterReceiptsByInvoicesBalance
	|	END AS NumberOfPackages
	|INTO TTDiscrepancies
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance( 
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse IN (&Warehouse, VALUE(Catalog.Warehouses.EmptyRef))
	|				ELSE TRUE
	|			END
	|	) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance <> 0
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableReferenceOrder.Ref					AS Ref,
	|	TableReferenceOrder.Terms				AS Terms,
	|	TableReferenceOrder.Partner					AS Partner,
	|	TableReferenceOrder.Counterparty				AS Counterparty,
	|	&Warehouse										AS Warehouse,
	|	TableReferenceOrder.Organization				AS Organization,
	|	TableReferenceOrder.Contract					AS Contract,
	|	TableReferenceOrder.Department			AS Department,
	|	TableReferenceOrder.Status					AS DocumentStatus,
	|	TableReferenceOrder.LineOfBusiness	AS LineOfBusiness,
	|	TableReferenceOrder.ThereAreErrorsPosted		AS ThereAreErrorsPosted,
	|	TableReferenceOrder.ThereAreErrorsStatus		AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////3
	|SELECT
	|	DivergenceTable.DiscrepanciesKind			AS DiscrepanciesKind,
	|	DivergenceTable.Products				AS Products,
	|	DivergenceTable.Characteristic			AS Characteristic,
	|	DivergenceTable.Purpose				AS Purpose,
	|	DivergenceTable.Series					AS Series,
	|	SUM(DivergenceTable.Count)		AS Count,
	|	SUM(DivergenceTable.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	TTDiscrepancies AS DivergenceTable
	|
	|GROUP BY
	|	DivergenceTable.DiscrepanciesKind,
	|	DivergenceTable.Products,
	|	DivergenceTable.Characteristic,
	|	DivergenceTable.Purpose,
	|	DivergenceTable.Series
	|
	|ORDER BY
	|	DivergenceTable.Products.Description";

	
	
	Query.SetParameter("DocumentBasis",	DocumentBasis);
	Query.SetParameter("Warehouse",				Warehouse);
	Query.SetParameter("WarehouseSpecified",		ValueIsFilled(Warehouse));
	
	ReferenceOrder	= DocumentBasis;

	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[2].Select();
	VTDiscrepancies		= QueryResult[3].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Selection.DocumentStatus;
	CheckParameters.ThereAreErrorsPosted = Selection.ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;

	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(DocumentBasis, CheckParameters);
	FillPropertyValues(ThisObject, Selection);
	FillInTheDiscrepancies(VTDiscrepancies);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterPurchase(FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	VendorInvoice.Ref                    AS DocumentInflow,
	|	&OrderDocument                                             AS PurchaseOrder,
	|   &Warehouse											   AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.Ref                AS DiscrepancyCertificate,
	|	VendorInvoice.Terms                AS Terms,
	|	VendorInvoice.Organization               AS Organization,
	|	VendorInvoice.Partner                   AS Partner,
	|	VendorInvoice.Counterparty                AS Counterparty,
	|	VendorInvoice.Contract                   AS Contract,
	|	VendorInvoice.Department             AS Department,
	|	NOT DiscrepancyReportFollowingReceipt.Posted           AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingReceipt.Status                AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport,
	|	NOT VendorInvoice.Posted               AS ThereAreErrorsPurchaseDocumentHasBeenCarriedOut,
	|	CASE
	|		WHEN VendorInvoice.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
	|		THEN
	|			VendorInvoice.Contract
	|		WHEN VendorInvoice.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
	|														VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
	|		THEN
	|			VendorInvoice.Terms
	|		WHEN NOT VendorInvoice.ReceiptUnderOrders
	|			AND VendorInvoice.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
	|		THEN
	|			VendorInvoice.Ref
	|		WHEN VendorInvoice.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|		THEN
	|			VendorInvoice.Ref
	|		ELSE
	|			&OrderDocument
	|	END AS ReferenceOrder
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|		INNER JOIN Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		ON (TRUE)
	|WHERE
	|	VendorInvoice.Ref = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Products           AS Products,
	|	DiscrepancyReportFollowingReceipt.Characteristic         AS Characteristic,
	|	DiscrepancyReportFollowingReceipt.Purpose             AS Purpose,
	|	DiscrepancyReportFollowingReceipt.Series                  AS Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Package               AS Package,
	|	CASE
	|		WHEN DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		WHEN DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.EmptyRef)
	|	END                                               AS DiscrepanciesKind,
	|	SUM(
	|			CASE
	|				WHEN DiscrepancyReportFollowingReceipt.CountByDocument - DiscrepancyReportFollowingReceipt.Count < 0
	|					THEN -(DiscrepancyReportFollowingReceipt.CountByDocument - DiscrepancyReportFollowingReceipt.Count)
	|				ELSE
	|					DiscrepancyReportFollowingReceipt.CountByDocument - DiscrepancyReportFollowingReceipt.Count
	|			END
	|		)                                              AS Count,
	|	SUM(
	|			CASE
	|				WHEN DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages < 0
	|					THEN -(DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages)
	|				ELSE
	|					DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages
	|			END
	|		)                                              AS NumberOfPackages,
	|	MAX(DiscrepancyReportFollowingReceipt.Warehouse)       AS Warehouse
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceipt.Action IN (
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome),
	|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
	|		)
	|	AND DiscrepancyReportFollowingReceipt.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.PurchaseOrder = &OrderDocument
	|	AND DiscrepancyReportFollowingReceipt.Warehouse = &Warehouse
	|	AND DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages <> 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceipt.Products,
	|	DiscrepancyReportFollowingReceipt.Characteristic,
	|	DiscrepancyReportFollowingReceipt.Purpose,
	|	DiscrepancyReportFollowingReceipt.Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Package,
	|	CASE
	|		WHEN DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome)
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		WHEN DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseShortageAsOtherExpenses)
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.EmptyRef)
	|	END";
	
	Query.SetParameter("DocumentBasis",	FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",	FillingData.DiscrepancyCertificate);
	Query.SetParameter("OrderDocument",				FillingData.OrderDocument);
	Query.SetParameter("Warehouse",				FillingData.Warehouse);
	
	SetPrivilegedMode(True);
	
	QueryBatch = Query.ExecuteBatch();
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
	
	// According to the receipt document
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = HeaderSelection.ThereAreErrorsPurchaseDocumentHasBeenCarriedOut;

	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		HeaderSelection.DocumentInflow,
		CheckParameters);
		
	// According to the act of discrepancies
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = HeaderSelection.StatusOfDivergenceReport;
	CheckParameters.ThereAreErrorsPosted = HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut;
	CheckParameters.ThereAreErrorsStatus = HeaderSelection.ThereAreErrorsStatusReport;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;

	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		HeaderSelection.DiscrepancyCertificate,
		CheckParameters);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	Basis = FillingData.BasisOfAct;
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
		If Not ValueIsFilled(Warehouse) Then
			Warehouse = CurRow.Warehouse;
		EndIf;
		
		NewRow = Discrepancies.Add();
		FillPropertyValues(NewRow,CurRow);
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoods(Val DocumentBasis, Val WarehouseForReceipt = Undefined, Val EconomicOperationOfAcceptance = Undefined)
	
	Query = New Query;
	
	Query.Text = TextOfFillInRequestBasedOn(False);
	
	Query.SetParameter("DocumentBasis",		DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",		WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",			ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FillInUsingInvoice",	True);
	
	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[5].Select();
	VTOfDiscrepancies		= QueryResult[6].Unload();
	VTOfPackaging			= QueryResult[7].Unload();
	
	Selection.Next();
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = Selection.ThereAreErrorsPosted;

	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		DocumentBasis,
		CheckParameters);
	
	ReferenceOrder	= DocumentBasis;
	Warehouse			= WarehouseForReceipt;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	FillPropertyValues(ThisObject, Selection);
	FillInTheDiscrepancies(VTOfDiscrepancies);

EndProcedure

Procedure FillInDocumentOnBasisOfContract(DocumentBasis)
	
	Query = New Query(
	"SELECT
	|	Contract.Ref AS Ref,
	|	Contract.Ref AS Contract,
	|	Contract.Partner AS Partner,
	|	Contract.Counterparty AS Counterparty,
	|	Contract.Organization AS Organization,
	|	Contract.Status AS DocumentStatus,
	|	CASE
	|		WHEN Contract.Status <> VALUE(Enum.CounterpartyContractStatuses.Valid)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus,
	|	CASE
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheseAreAgencyServices,
	|	Contract.LineOfBusiness AS LineOfBusiness,
	|	Contract.Department AS Department
	|INTO TTOrder_
	|FROM
	|	Catalog.CounterpartyContracts AS Contract
	|WHERE
	|	Contract.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	GoodsToReceiveBalance.Series AS Series,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance AS Count
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &DocumentBasis) AS GoodsToReceiveBalance
	|WHERE
	|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableReferenceOrder.Ref AS Ref,
	|	TableReferenceOrder.Contract AS Contract,
	|	TableReferenceOrder.Partner AS Partner,
	|	TableReferenceOrder.Counterparty AS Counterparty,
	|	TableReferenceOrder.Organization AS Organization,
	|	TableReferenceOrder.DocumentStatus AS DocumentStatus,
	|	TableReferenceOrder.LineOfBusiness AS LineOfBusiness,
	|	TableReferenceOrder.Department AS Department,
	|	TableReferenceOrder.TheseAreAgencyServices AS TheseAreAgencyServices,
	|	TableReferenceOrder.ThereAreErrorsStatus AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Overdelivery)
	|		ELSE VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)
	|	END AS DiscrepanciesKind,
	|	GoodsTable.DocumentInflow AS DocumentInflow,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN -GoodsTable.Count
	|		ELSE GoodsTable.Count
	|	END AS NumberOfPackages,
	|	CASE
	|		WHEN GoodsTable.Count < 0
	|			THEN -GoodsTable.Count
	|		ELSE GoodsTable.Count
	|	END AS Count
	|FROM
	|	TTProducts_1 AS GoodsTable");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection		= QueryResult[2].Select();
	VTProducts_	= QueryResult[3].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);

	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Selection.DocumentStatus;
	CheckParameters.ThereAreErrorsPosted = False;
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;

	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(
		DocumentBasis,
		CheckParameters);
		
	ReferenceOrder          = DocumentBasis;

	FillPropertyValues(ThisObject, Selection);
	FillInTheDiscrepancies(VTProducts_);
	
EndProcedure

// Parameters:
// 	VTOfDiscrepancies - ValueTable - 
Procedure FillInTheDiscrepancies(VTOfDiscrepancies)
	
	Discrepancies.Clear();
	For Each LineOfDiscrepancies In VTOfDiscrepancies Do
		
		TSRow = Discrepancies.Add();
		FillPropertyValues(TSRow, LineOfDiscrepancies);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region InventoryKinds

// Returns a temporary table with the document data.
// Used for filling in inventory types.
// 
// Parameters:
//  DiscrepanciesKind - Undefined, EnumRef.DiscrepanciesKindOfReceiptsPurchases - The type of discrepancies.
//  ForProductsFromPartners - Boolean - Selection according to the analysis of the accounting of the nomenclature under The Contract.
//  OnlyImportedItems - Boolean - Selection of imported goods.
//  OnlyWorks - Boolean - Selection according to the work type nomenclature.
// 
// Returns:
//  TempTablesManager - manager of temporary tables with document data.
//
Function TemporaryDocumentDataTables(DiscrepanciesKind, ForProductsFromPartners, OnlyImportedItems, OnlyWorks = Undefined)
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	&Date AS Date,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	&StorageLocation AS StorageLocation,
	|	&BusinessOperation AS BusinessOperation,
	|	&Currency AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	&InventoryType AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	&TableOfProductsProductAccountingAnalytics AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	0 AS Price,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableOfGoods.DiscrepanciesKind AS DiscrepanciesKind
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	&Warehouse AS Warehouse,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	&PriceKind AS PriceKind,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	&ReferenceOrder AS DocumentLoggingIn
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|WHERE
	|	TableOfGoods.DiscrepanciesKind = &DiscrepanciesKind
	|	AND CAST(TableOfGoods.Products AS Catalog.Products).KeepRecordsByCCD
	|	AND &SelectionItemTypeItems
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|		OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	0 AS AmountIncludingVAT,
	|	0 AS VATAmount,
	|	TableTypesOfStocks_.DiscrepanciesKind AS DiscrepanciesKind
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.Products AS Products,
	|	Dimension.Characteristic AS Characteristic,
	|	Dimension.Series AS Series,
	|	Dimension.Purpose AS Purpose,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	Dimension.StorageLocation AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	FALSE AS InventoryOwnerAttributesAreSpecifiedManually,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	&ReferenceOrder AS DocumentLoggingIn
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	TableTypesOfStocks_.DiscrepanciesKind = &DiscrepanciesKind
	|	AND CAST(Dimension.Products AS Catalog.Products).KeepRecordsByCCD
	|	AND &SelectionTypeOfNomenclatureInventoryOwnerAttributes
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN CAST(TableOfGoods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND CAST(TableOfGoods.Products AS Catalog.Products).TracedGoods
	|			THEN
	|				&InventoryTypeOfTraceableWorks
	|			ELSE
	|				&InventoryType
	|	END AS InventoryType,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|WHERE
	|	(CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	OR CAST(TableOfGoods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND CAST(TableOfGoods.Products AS Catalog.Products).TracedGoods)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|	OR InventoryKinds.InventoryType <> &InventoryType
	|	OR InventoryKinds.Organization <> &Organization
	|	OR &RefillInventoryKinds)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsToReceive.Recorder AS Recorder,
	|	TableOfGoods.DocumentLoggingIn AS DocumentLoggingIn
	|INTO TTRecordersGoodsToBeReceived
	|FROM
	|	AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|		INNER JOIN TableOfGoods AS TableOfGoods
	|		ON TableOfGoods.DocumentLoggingIn = GoodsToReceive.DocumentInflow
	|WHERE
	|	CASE
	|		WHEN &WarehouseSpecified
	|				AND NOT GoodsToReceive.Products.ItemsType IN (&WorksServices)
	|			THEN GoodsToReceive.Warehouse = &WarehouseForReceipt
	|		ELSE TRUE
	|	END
	|
	|INDEX BY
	|	Recorder";
	
	If DiscrepanciesKind = Undefined Then
		QueryText = StrReplace(QueryText, "TableOfGoods.DiscrepanciesKind = &DiscrepanciesKind", "TRUE");
		QueryText = StrReplace(QueryText, "TableTypesOfStocks_.DiscrepanciesKind = &DiscrepanciesKind", "TRUE");
	Else
		Query.SetParameter("DiscrepanciesKind", DiscrepanciesKind);
	EndIf;
	
	If ForProductsFromPartners Then
		QueryText = StrReplace(QueryText,
									"&TableOfProductsProductAccountingAnalytics",
									"TableOfGoods.ItemsLocationAttributesGoodsAtPartners");
		Query.SetParameter("InventoryType", TypeOfInventoryByBusinessTransaction());
	Else
		
		QueryText = StrReplace(QueryText,
									"&TableOfProductsProductAccountingAnalytics",
									"TableOfGoods.ItemsLocationAttributes");
		Query.SetParameter("InventoryType", Enums.InventoryTypes.EmptyRef());
	EndIf;
	
	If OnlyWorks = Undefined Then
		
		QueryText = StrReplace(QueryText,
									"&SelectionItemTypeItems",
									"TRUE");
		
		QueryText = StrReplace(QueryText,
									"&SelectionTypeOfNomenclatureInventoryOwnerAttributes",
									"TRUE");
	ElsIf OnlyWorks Then
		
		TextOfItemsCondition = "CAST(TableOfGoods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
		QueryText = StrReplace(QueryText,
									"&SelectionItemTypeItems",
									TextOfItemsCondition);
		
		TextOfConditionOfInventoryOwnerAttributes = "CAST(TableTypesOfStocks_.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys).Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
		QueryText = StrReplace(QueryText,
									"&SelectionTypeOfNomenclatureInventoryOwnerAttributes",
									TextOfConditionOfInventoryOwnerAttributes);
	Else
		
		TextOfItemsCondition = "CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
		QueryText = StrReplace(QueryText,
									"&SelectionItemTypeItems",
									TextOfItemsCondition);
		
		TextOfConditionOfInventoryOwnerAttributes = "CAST(TableTypesOfStocks_.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) <> VALUE(Enum.ItemsTypes.Work_5)";
		QueryText = StrReplace(QueryText,
									"&SelectionTypeOfNomenclatureInventoryOwnerAttributes",
									TextOfConditionOfInventoryOwnerAttributes);
	EndIf;
	
	If Not OnlyImportedItems Then
		QueryText = StrReplace(QueryText, "CAST(TableOfGoods.Products AS Catalog.Products).KeepRecordsByCCD", "TRUE");
		QueryText = StrReplace(QueryText, "CAST(Dimension.Products AS Catalog.Products).KeepRecordsByCCD", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Discrepancies"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Discrepancies,
						Discrepancies);
	
	DetailsOfFoundation = GetAttributesOfFoundation();
	BusinessOperation = DetailsOfFoundation.BusinessOperation;
	
	If Not ForProductsFromPartners Then
		InventoryType = Enums.InventoryTypes.OwnGoods;
	ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
		InventoryType = Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery;
	Else
		InventoryType = Enums.InventoryTypes.OwnGoodsInTransit;
	EndIf;
	
	InventoryTypeOfTraceableWorks = Enums.InventoryTypes.Work_5;
	
	WorksServices = New Array;
	WorksServices.Add(Enums.ItemsTypes.Work_5);
	WorksServices.Add(Enums.ItemsTypes.OperationService);
	
	Query.SetParameter("TableOfGoods",         TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",     InventoryKinds);
	Query.SetParameter("Ref",                 Ref);
	Query.SetParameter("Date",                   Date);
	Query.SetParameter("Partner",                Partner);
	Query.SetParameter("Counterparty",             Counterparty);
	Query.SetParameter("Terms",             Terms);
	Query.SetParameter("Contract",                Contract);
	Query.SetParameter("Organization",            Organization);
	Query.SetParameter("Warehouse",                  Warehouse);
	Query.SetParameter("StorageLocation",          Warehouse);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Currency",                 Catalogs.Currencies.EmptyRef());
	Query.SetParameter("PriceKind",				Undefined);
	Query.SetParameter("Posted",				Posted);
	Query.SetParameter("InventoryType",				InventoryType);
	Query.SetParameter("InventoryTypeOfTraceableWorks", InventoryTypeOfTraceableWorks);
	Query.SetParameter("WarehouseSpecified",			ValueIsFilled(Warehouse));
	Query.SetParameter("WarehouseForReceipt",		Warehouse);
	Query.SetParameter("WorksServices",			WorksServices);
	Query.SetParameter("ReferenceOrder",			?(ValueIsFilled(ReferenceOrder), 
															ReferenceOrder, 
															?(ValueIsFilled(Basis), Basis, Undefined)));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables(Undefined, True, False);
	RefillInventoryKinds	= AdditionalProperties.Property("RefillInventoryKinds");
	
	InventoriesServer.FillStockTypesByDefault(TempTablesManager, Discrepancies);
	
	TypeOfDiscrepanciesNonDelivery	= Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery;
	TempTablesManager		= TemporaryDocumentDataTables(TypeOfDiscrepanciesNonDelivery, False, True);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		AdditionalProperties.Insert("MonitorCCDNumbers", True);
		
		ManagerOfTemporaryShortageTables = TemporaryDocumentDataTables(TypeOfDiscrepanciesNonDelivery, False, True, False);
		
		InventoryKinds.Clear();
		
		FillOutTypesOfStocksOfNonImportedGoods();
		
		TypesOfStocksIntermediate = InventoryKinds.Unload();
		
		FillParameters = ParametersForFillingInventoryTypes(True);
		FillParameters.WithoutSelectionByCCDNumbers = False;
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																ManagerOfTemporaryShortageTables,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
							"Count, QuantityByGBRN");
		
		FillInRecipientSInventoryType();
		CommonClientServer.SupplementTable(TypesOfStocksIntermediate, InventoryKinds);
		FillInAnalyticsTakingIntoAccountSeriesAndCCDNumber();
		
		TypesOfStocksIntermediate = InventoryKinds.Unload();
		
		InventoryKinds.Clear();
		
		// Work.
		FillParameters = ParametersForFillingInventoryTypes(False);
		FillParameters.WithoutSelectionByCCDNumbers = False;
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		
		ManagerOfTemporaryShortageTables = TemporaryDocumentDataTables(TypeOfDiscrepanciesNonDelivery, False, True, True);
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																ManagerOfTemporaryShortageTables,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber",
							"Count, QuantityByGBRN");
		
		FillInRecipientSInventoryType();
		CommonClientServer.SupplementTable(TypesOfStocksIntermediate, InventoryKinds);
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes(ByGoods)
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
	FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesByDefault();
	FillParameters.NameOfRemainderTable = "WriteOffOfDiscrepanciesPositiveBalance";
	FillParameters.WithoutSelectionByCCDNumbers = True;
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	
	If ByGoods Then
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
	Else
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	EndIf;
	
	FillParameters.SelectionOfStockTypes_.Organization = Organization;
	FillParameters.SelectionOfStockTypes_.PriceKind = Catalogs.VendorPriceTypes.EmptyRef();
	
	Return FillParameters;
EndFunction

Function TableOfDetailsOfStockTypesByDefault()
	
	TableOfDetailsOfStockTypesByDefault = Discrepancies.Unload(, "LineNumber, ItemsLocationAttributes"); // ValueTable
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"GoodsOwner", New TypeDescription("CatalogRef.Partners"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Contract", New TypeDescription("CatalogRef.CounterpartyContracts"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"InventoryType", New TypeDescription("EnumRef.InventoryTypes"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Organization", New TypeDescription("CatalogRef.Companies"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"InventoryOwnerAttribute", New TypeDescription("CatalogRef.InventoryKinds"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"CCDNumber", New TypeDescription("CatalogRef.CCDNumbers"));
	TableOfDetailsOfStockTypesByDefault.Columns.Add(
		"Counterparty", New TypeDescription("CatalogRef.Counterparties"));
		
	TableOfDetailsOfStockTypesByDefault.FillValues(Partner, "GoodsOwner");
	TableOfDetailsOfStockTypesByDefault.FillValues(Contract, "Contract");
	TableOfDetailsOfStockTypesByDefault.FillValues(Organization, "Organization");
	TableOfDetailsOfStockTypesByDefault.FillValues(TypeOfInventoryByBusinessTransaction(), "InventoryType");
	TableOfDetailsOfStockTypesByDefault.FillValues(Counterparty, "Counterparty");
	
	Query = New Query();
	Query.Text =
	"SELECT
	|	Goods.LineNumber AS LineNumber,
	|	CAST(Goods.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS ItemsLocationAttributes
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	Goods.LineNumber AS LineNumber
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	Goods.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND Goods.ItemsLocationAttributes.Products.TracedGoods";
	
	Query.SetParameter("Goods", TableOfDetailsOfStockTypesByDefault);
	
	Selection = Query.Execute().Select();
	FilterParameters = New Structure("LineNumber");
	While Selection.Next() Do
		FillPropertyValues(FilterParameters, Selection);
		FoundRows = TableOfDetailsOfStockTypesByDefault.FindRows(FilterParameters);
		For Each String In FoundRows Do
			String.InventoryType = Enums.InventoryTypes.Work_5;
		EndDo;
	EndDo;
	
	Return TableOfDetailsOfStockTypesByDefault;
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	AttributesNames = "Organization, Date, Partner, Warehouse, Contract, Counterparty";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT
	|	TableOfGoods.Products AS Products
	|FROM (
	|	SELECT
	|		TableOfGoods.Products		AS Products,
	|		TableOfGoods.Characteristic	AS Characteristic,
	|		TableOfGoods.Purpose		AS Purpose,
	|		TableOfGoods.Count		AS Count
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.Products		AS Products,
	|		TableTypesOfStocks_.Characteristic	AS Characteristic,
	|		TableTypesOfStocks_.Purpose		AS Purpose,
	|		-TableTypesOfStocks_.Count		AS Count
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Purpose
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0";
	
	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.WriteOffDiscrepanciesBetweenReceiptAndPurchase.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	DivergenceTable = DocumentTables.Discrepancies;
	
	DetailsOfFoundation	= GetAttributesOfFoundation();
	MainBusinessTransaction	= PurchasesServer.MainEconomicOperationOfSeparatePurchase(DetailsOfFoundation.BusinessOperation);
	
	PlacesOfAccountingWarehouse = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
						MainBusinessTransaction,
						Warehouse,
						Department,
						Partner,
						Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes	= "ItemsLocationAttributes";
	FieldsNames.BatchesIndicationStatus			= "BatchesIndicationStatusInWarehouses";

	InformationRegisters.ItemsLocationAttributes.FillInCollection(DivergenceTable, PlacesOfAccountingWarehouse, FieldsNames);
	
	PlacesOfAccountingContract = New Structure("Arbitrary", Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes	= "ItemsLocationAttributesGoodsAtPartners";
	FieldsNames.BatchesIndicationStatus			= "BatchesIndicationStatusGoodsAtPartners";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(DivergenceTable, PlacesOfAccountingContract, FieldsNames);
	
EndProcedure

Procedure FillInRecipientSInventoryType()
	
	DiscrepanciesKind		= Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery;
	RowFilter			= New Structure("DiscrepanciesKind", DiscrepanciesKind);
	UnloadedColumns	= "ItemsLocationAttributes, InventoryOwnerAttribute";
	
	GoodsTable = Discrepancies.Unload(RowFilter, UnloadedColumns);
	GoodsTable.GroupBy(UnloadedColumns);
	
	RowFilter = New Structure("ItemsLocationAttributes");
	
	For Each LineProducts_ In GoodsTable Do
		FillPropertyValues(RowFilter, LineProducts_);
		
		FilterRows = InventoryKinds.FindRows(RowFilter);
		
		For Each InventoryLine In FilterRows Do
			InventoryLine.DiscrepanciesKind		= DiscrepanciesKind;
			InventoryLine.RecipientInventoryOwnerAttribute	= LineProducts_.InventoryOwnerAttribute;
		EndDo;
	EndDo;
	
EndProcedure

Procedure FillInAnalyticsTakingIntoAccountSeriesAndCCDNumber()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	InventoryKinds.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber					AS CCDNumber,
	|	InventoryKinds.Count					AS Count,
	|	InventoryKinds.QuantityByGBRN			AS QuantityByGBRN,
	|	InventoryKinds.RecipientInventoryOwnerAttribute		AS RecipientInventoryOwnerAttribute,
	|	&DiscrepanciesKind							AS DiscrepanciesKind,
	|	CASE
	|		WHEN &BusinessTransactionOrders IN (
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|				VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|				)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS ThisIsOperationGoodsInTransit
	|INTO TypesOfStocksToRequest
	|FROM
	|	&InventoryKinds AS InventoryKinds
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	CASE
	|		WHEN DimensionKeys.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		WHEN ISNULL(DimensionKeys.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)
	|				OR ISNULL(DimensionKeys.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.ItemsLocationAttributes
	|	END									AS BalanceAnalytics,
	|	InventoryKinds.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber					AS CCDNumber,
	|	InventoryKinds.Count					AS Count,
	|	InventoryKinds.QuantityByGBRN			AS QuantityByGBRN,
	|	InventoryKinds.RecipientInventoryOwnerAttribute		AS RecipientInventoryOwnerAttribute,
	|	InventoryKinds.DiscrepanciesKind				AS DiscrepanciesKind,
	|	DimensionKeys.Products				AS Products,
	|	DimensionKeys.Characteristic			AS Characteristic,
	|	DimensionKeys.Purpose				AS Purpose,
	|	DimensionKeys.Series					AS Series,
	|	DimensionKeys.StorageLocation			AS StorageLocation,
	|	DimensionKeys.ProductCostElement		AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(DimensionKeys.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor, FALSE)
	|				OR ISNULL(DimensionKeys.Products.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries, FALSE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS AccountingForPartnerSeries,
	|	CASE
	|		WHEN NOT InventoryKinds.ThisIsOperationGoodsInTransit
	|			THEN FALSE
	|		WHEN ISNULL(DimensionKeys.Products.KeepRecordsByCCD, FALSE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS KeepRecordsByCCD,
	|	CASE
	|		WHEN NOT InventoryKinds.ThisIsOperationGoodsInTransit
	|			THEN FALSE
	|		WHEN InventoryKinds.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|				AND ISNULL(DimensionKeys.Products.KeepRecordsByCCD, FALSE)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS FillInCCD,
	|	InventoryKinds.ThisIsOperationGoodsInTransit		AS ThisIsOperationGoodsInTransit
	|INTO TypesOfInventoryToRequestExtended
	|FROM
	|	TypesOfStocksToRequest AS InventoryKinds
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON InventoryKinds.ItemsLocationAttributes = DimensionKeys.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT DISTINCT
	|	InventoryKinds.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber					AS CCDNumber,
	|	InventoryKinds.Products				AS Products,
	|	InventoryKinds.Characteristic				AS Characteristic,
	|	InventoryKinds.Purpose					AS Purpose,
	|	InventoryKinds.Series						AS Series,
	|	InventoryKinds.StorageLocation				AS StorageLocation,
	|	InventoryKinds.ProductCostElement			AS ProductCostElement,
	|	InventoryKinds.AccountingForPartnerSeries		AS AccountingForPartnerSeries,
	|	InventoryKinds.KeepRecordsByCCD				AS KeepRecordsByCCD,
	|	InventoryKinds.ThisIsOperationGoodsInTransit		AS ThisIsOperationGoodsInTransit
	|INTO TTTypesOfStocks
	|FROM
	|	TypesOfInventoryToRequestExtended AS InventoryKinds
	|
	|INDEX BY
	|	ItemsLocationAttributes,
	|	InventoryOwnerAttribute,
	|	CCDNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	Dimension.DimensionKey				AS Dimension,
	|	InventoryKinds.InventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	InventoryKinds.KeepRecordsByCCD			AS KeepRecordsByCCD,
	|	InventoryKinds.ThisIsOperationGoodsInTransit	AS ThisIsOperationGoodsInTransit
	|INTO TTSelectionAnalyticsWithSeries
	|FROM
	|	InformationRegister.ItemsLocationAttributes AS Dimension
	|		INNER JOIN TTTypesOfStocks AS InventoryKinds
	|		ON Dimension.Products = InventoryKinds.Products
	|			AND Dimension.Characteristic = InventoryKinds.Characteristic
	|			AND Dimension.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND Dimension.StorageLocation = InventoryKinds.StorageLocation
	|			AND Dimension.Purpose = InventoryKinds.Purpose
	|			AND Dimension.ProductCostElement = InventoryKinds.ProductCostElement
	|WHERE
	|	InventoryKinds.AccountingForPartnerSeries
	|	AND InventoryKinds.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|INDEX BY
	|	Dimension,
	|	InventoryOwnerAttribute,
	|	KeepRecordsByCCD
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	BalanceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	SUM(BalanceTable.Count)			AS Count
	|INTO BalanceTTWithSeries
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		-Balance.CountBalance			AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				&DocumentDate,
	|				(ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|						(SELECT
	|							FilterTable.Dimension,
	|							FilterTable.InventoryOwnerAttribute
	|						FROM
	|							TTSelectionAnalyticsWithSeries AS FilterTable
	|						WHERE
	|							FilterTable.KeepRecordsByCCD
	|							AND FilterTable.ThisIsOperationGoodsInTransit)
	|				AND Organization = &Organization
	|				AND CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|		) AS Balance
	|	WHERE
	|		Balance.CountBalance < 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Balance.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		Balance.CountBalance			AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				&DocumentDate,
	|				(ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|						(SELECT
	|							FilterTable.Dimension,
	|							FilterTable.InventoryOwnerAttribute
	|						FROM
	|							TTSelectionAnalyticsWithSeries AS FilterTable
	|						WHERE
	|							NOT FilterTable.KeepRecordsByCCD
	|							AND FilterTable.ThisIsOperationGoodsInTransit)
	|				AND Organization = &Organization
	|		) AS Balance
	|	WHERE
	|		Balance.CountBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		RegisterRecords.Count					AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS RegisterRecords
	|			INNER JOIN TTSelectionAnalyticsWithSeries AS FilterTable
	|			ON RegisterRecords.ItemsLocationAttributes = FilterTable.Dimension
	|				AND RegisterRecords.InventoryOwnerAttribute = FilterTable.InventoryOwnerAttribute
	|				AND NOT FilterTable.ThisIsOperationGoodsInTransit
	|	WHERE
	|		RegisterRecords.Period <= &DocumentDate
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|		AND (RegisterRecords.Recorder, TRUE) IN
	|				(SELECT
	|					GoodsToReceive.Recorder,
	|					TRUE
	|				FROM
	|					AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|				WHERE
	|					GoodsToReceive.DocumentInflow = &ReferenceOrder)
	|		AND RegisterRecords.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		-RegisterRecords.Count				AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS RegisterRecords
	|			INNER JOIN TTTypesOfStocks AS InventoryKinds
	|			ON RegisterRecords.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|				AND RegisterRecords.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute
	|	WHERE
	|		RegisterRecords.Recorder = &Ref
	|		AND InventoryKinds.AccountingForPartnerSeries
	|		AND InventoryKinds.ThisIsOperationGoodsInTransit
	|		AND RegisterRecords.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|		AND InventoryKinds.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	
	|	) AS BalanceTable
	|
	|GROUP BY
	|	BalanceTable.ItemsLocationAttributes,
	|	BalanceTable.InventoryOwnerAttribute
	|
	|HAVING
	|	SUM(BalanceTable.Count) > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	BalanceTable.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	BalanceTable.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	BalanceTable.CCDNumber					AS CCDNumber,
	|	SUM(BalanceTable.Count)			AS Count,
	|	SUM(BalanceTable.QuantityByGBRN)		AS QuantityByGBRN
	|INTO TTOfBalanceOfSGTD
	|FROM
	|	(SELECT
	|		Balance.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		Balance.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		Balance.CCDNumber					AS CCDNumber,
	|		Balance.CountBalance			AS Count,
	|		Balance.QuantityByGBRNBalance		AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(
	|				&DocumentDate,
	|				(ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|						(SELECT
	|							FilterTable.ItemsLocationAttributes,
	|							FilterTable.InventoryOwnerAttribute
	|						FROM
	|							TTTypesOfStocks AS FilterTable
	|						WHERE
	|							FilterTable.KeepRecordsByCCD
	|							AND FilterTable.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
	|				AND Organization = &Organization
	|				AND CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|		) AS Balance
	|	WHERE
	|		Balance.CountBalance > 0
	|		OR Balance.QuantityByGBRNBalance > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		RegisterRecords.CCDNumber					AS CCDNumber,
	|		SUM(CASE
	|				WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN RegisterRecords.Count
	|				ELSE -RegisterRecords.Count
	|			END)							AS Count,
	|		SUM(CASE
	|				WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN RegisterRecords.QuantityByGBRN
	|				ELSE -RegisterRecords.QuantityByGBRN
	|			END)							AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanyGoods AS RegisterRecords
	|	WHERE
	|		RegisterRecords.Period <= &DocumentDate
	|		AND RegisterRecords.Recorder <> &Ref
	|		AND (RegisterRecords.Recorder, TRUE) IN
	|				(SELECT
	|					GoodsToReceive.Recorder AS Recorder,
	|					TRUE
	|				FROM
	|					AccumulationRegister.GoodsToReceive AS GoodsToReceive
	|				WHERE
	|					GoodsToReceive.DocumentInflow = &ReferenceOrder)
	|		AND (RegisterRecords.ItemsLocationAttributes, RegisterRecords.InventoryOwnerAttribute) IN
	|				(SELECT
	|					FilterTable.Dimension,
	|					FilterTable.InventoryOwnerAttribute
	|				FROM
	|					TTSelectionAnalyticsWithSeries AS FilterTable
	|				WHERE
	|					FilterTable.KeepRecordsByCCD)
	|		AND RegisterRecords.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	
	|	GROUP BY
	|		RegisterRecords.ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute,
	|		RegisterRecords.CCDNumber
	|	
	|	HAVING
	|		SUM(CASE
	|				WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN RegisterRecords.Count
	|				ELSE -RegisterRecords.Count
	|			END) > 0
	|		OR SUM(CASE
	|				WHEN RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN RegisterRecords.QuantityByGBRN
	|				ELSE -RegisterRecords.QuantityByGBRN
	|			END) > 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|		RegisterRecords.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|		RegisterRecords.CCDNumber					AS CCDNumber,
	|		-RegisterRecords.Count				AS Count,
	|		-RegisterRecords.QuantityByGBRN			AS QuantityByGBRN
	|	FROM
	|		AccumulationRegister.CompanyGoods AS RegisterRecords
	|			INNER JOIN TTTypesOfStocks AS InventoryKinds
	|			ON RegisterRecords.ItemsLocationAttributes = InventoryKinds.ItemsLocationAttributes
	|				AND RegisterRecords.InventoryOwnerAttribute = InventoryKinds.InventoryOwnerAttribute
	|				AND RegisterRecords.CCDNumber = InventoryKinds.CCDNumber
	|				AND InventoryKinds.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
	|	WHERE
	|		RegisterRecords.Recorder = &Ref
	|		AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Expense)
	|	
	|	) AS BalanceTable
	|
	|GROUP BY
	|	BalanceTable.ItemsLocationAttributes,
	|	BalanceTable.InventoryOwnerAttribute,
	|	BalanceTable.CCDNumber
	|
	|HAVING
	|	SUM(BalanceTable.Count) > 0
	|	OR SUM(BalanceTable.QuantityByGBRN) > 0
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes	AS BalanceAnalytics,
	|	Dimension.DimensionKey					AS ItemsLocationAttributes,
	|	DimensionKeys.Products				AS Products,
	|	DimensionKeys.Characteristic			AS Characteristic,
	|	DimensionKeys.Purpose				AS Purpose,
	|	DimensionKeys.Series					AS Series,
	|	InventoryKinds.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN TypesOfSGTDReserves.ItemsLocationAttributes IS NULL
	|			THEN VALUE(Catalog.CCDNumbers.EmptyRef)
	|		ELSE TypesOfSGTDReserves.CCDNumber
	|	END									AS CCDNumber,
	|	CASE
	|		WHEN TypesOfSGTDReserves.ItemsLocationAttributes IS NULL
	|			THEN InventoryKinds.Count
	|		ELSE CASE
	|				WHEN TypesOfSGTDReserves.Count >= InventoryKinds.Count
	|					THEN InventoryKinds.Count
	|				ELSE TypesOfSGTDReserves.Count
	|			END
	|	END									AS QuantityConsideringCCD,
	|	CASE
	|		WHEN TypesOfSGTDReserves.ItemsLocationAttributes IS NULL
	|			THEN InventoryKinds.Count
	|		ELSE TypesOfSGTDReserves.Count
	|	END									AS AmountOfBalanceTakingIntoAccountCCD,
	|	CASE
	|		WHEN TypesOfSGTDReserves.ItemsLocationAttributes IS NULL
	|			THEN 0
	|		ELSE TypesOfSGTDReserves.QuantityByGBRN
	|	END									AS QuantityByGBRN
	|FROM
	|	BalanceTTWithSeries AS InventoryKinds
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON InventoryKinds.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Dimension.Products = DimensionKeys.Products
	|			AND Dimension.Characteristic = DimensionKeys.Characteristic
	|			AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND Dimension.StorageLocation = DimensionKeys.StorageLocation
	|			AND Dimension.Purpose = DimensionKeys.Purpose
	|			AND Dimension.ProductCostElement = DimensionKeys.ProductCostElement
	|		
	|		LEFT JOIN TTOfBalanceOfSGTD AS TypesOfSGTDReserves
	|		ON InventoryKinds.ItemsLocationAttributes = TypesOfSGTDReserves.ItemsLocationAttributes
	|
	|UNION ALL
	|
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes	AS BalanceAnalytics,
	|	InventoryKinds.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	DimensionKeys.Products				AS Products,
	|	DimensionKeys.Characteristic			AS Characteristic,
	|	DimensionKeys.Purpose				AS Purpose,
	|	DimensionKeys.Series					AS Series,
	|	InventoryKinds.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber					AS CCDNumber,
	|	InventoryKinds.Count					AS QuantityConsideringCCD,
	|	InventoryKinds.Count					AS AmountOfBalanceTakingIntoAccountCCD,
	|	InventoryKinds.QuantityByGBRN			AS QuantityByGBRN
	|FROM
	|	TTOfBalanceOfSGTD AS InventoryKinds
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON InventoryKinds.ItemsLocationAttributes = DimensionKeys.Ref
	|		
	|		LEFT JOIN BalanceTTWithSeries AS TypesOfStocksWithSeries
	|		ON InventoryKinds.ItemsLocationAttributes = TypesOfStocksWithSeries.ItemsLocationAttributes
	|WHERE
	|	TypesOfStocksWithSeries.ItemsLocationAttributes IS NULL";
	
	DetailsOfFoundation = GetAttributesOfFoundation();
	
	Query.SetParameter("Ref",			Ref);
	Query.SetParameter("DocumentDate",	EndOfDay(Date));
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("ReferenceOrder",	ReferenceOrder);
	Query.SetParameter("InventoryKinds",	InventoryKinds);
	Query.SetParameter("DiscrepanciesKind",	Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery);
	Query.SetParameter("BusinessTransactionOrders",	DetailsOfFoundation.BusinessOperation);
	
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	TableTypesOfStocks_ = QueryResult[1].Unload(); // ValueTable - 
	TableTypesOfStocks_.Indexes.Add("FillInCCD");
	TableTypesOfStocks_.Indexes.Add("BalanceAnalytics");
	
	BalanceTable = QueryResult[QueryResult.UBound()].Unload();
	BalanceTable.Indexes.Add("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber");
	
	Var_Key			= "ItemsLocationAttributes";
	Condition			= "On [Count]";
	FieldsToFillIn	= "BalanceAnalytics,CCDNumber";
	
	InvoicesServer.DistributeQuantityAndFill(
		BalanceTable,
		TableTypesOfStocks_,
		"QuantityConsideringCCD",
		Var_Key,
		Condition,
		False,
		FieldsToFillIn);
	
	RowFilter		= New Structure("FillInCCD", True);
	FilterRows	= TableTypesOfStocks_.FindRows(RowFilter);
	
	CCDSelection = New Structure("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber");
	
	For Each InventoryLine In FilterRows Do
		If Not ValueIsFilled(InventoryLine.CCDNumber) Then
			Continue;
		EndIf;
		
		If InventoryLine.Count > InventoryLine.QuantityConsideringCCD Then
			ExcessQuantity = InventoryLine.Count - InventoryLine.QuantityConsideringCCD;
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Count	= ExcessQuantity;
			NewRow.CCDNumber	= Undefined;
		EndIf;
		
		InventoryLine.Count = InventoryLine.QuantityConsideringCCD;
		
		FillPropertyValues(CCDSelection, InventoryLine);
		
		RemainderLines_ = BalanceTable.FindRows(CCDSelection);
		
		For Each SGTDString In RemainderLines_ Do
			InventoryLine.QuantityByGBRN = InventoryLine.Count * SGTDString.QuantityByGBRN
												/ SGTDString.AmountOfBalanceTakingIntoAccountCCD;
			
			Break;
		EndDo;
	EndDo;
	
	RowFilter		= New Structure("BalanceAnalytics");
	FilterRows	= TableTypesOfStocks_.FindRows(RowFilter);
	
	For Each InventoryLine In FilterRows Do
		InventoryLine.BalanceAnalytics = InventoryLine.ItemsLocationAttributes;
	EndDo;
	
	TableTypesOfStocks_.Columns.Delete("ItemsLocationAttributes");
	TableTypesOfStocks_.Columns.BalanceAnalytics.Name = "ItemsLocationAttributes";
	
	InventoryKinds.Load(TableTypesOfStocks_);
	
EndProcedure

Procedure FillOutTypesOfStocksOfNonImportedGoods()
	
	DiscrepanciesKind	= Enums.DiscrepanciesKindOfReceiptsPurchases.Underdelivery;
	RowFilter		= New Structure("DiscrepanciesKind", DiscrepanciesKind);
	
	UnloadedColumns = "Products, ItemsLocationAttributesGoodsAtPartners, Count, DiscrepanciesKind,
							|InventoryOwnerAttribute";
	
	TableOfGoods = Discrepancies.Unload(RowFilter, UnloadedColumns);
	
	If TableOfGoods.Count() = 0 Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.DiscrepanciesKind	AS DiscrepanciesKind,
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Count		AS Count,
	|	TableOfGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributes,
	|	TableOfGoods.InventoryOwnerAttribute		AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.DiscrepanciesKind				AS DiscrepanciesKind,
	|	TableOfGoods.InventoryOwnerAttribute					AS RecipientInventoryOwnerAttribute
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|
	|WHERE
	|	NOT CatalogProducts.KeepRecordsByCCD
	|	AND TableOfGoods.DiscrepanciesKind = VALUE(Enum.DiscrepanciesKindOfReceiptsPurchases.Underdelivery)";
	
	Query.SetParameter("TableOfGoods", TableOfGoods);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	InventoryKinds.Load(QueryResult.Unload());
	
EndProcedure

#EndRegion

#Region Other

Function GetAttributesOfFoundation()
	
	If ValueIsFilled(Basis) Then
		Return Common.ObjectAttributesValues(Basis, "BusinessOperation");
	Else
		Return Common.ObjectAttributesValues(ReferenceOrder, "BusinessOperation");
	EndIf;
		
EndFunction

Function TypeOfInventoryByBusinessTransaction()
	DetailsOfFoundation = GetAttributesOfFoundation();
	BusinessOperation = DetailsOfFoundation.BusinessOperation;
	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit
		
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit Then
		
		Return Enums.InventoryTypes.OwnGoodsInTransit;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery 
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
		
		Return Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery;
		
	Else
		Return Enums.InventoryTypes.EmptyRef();
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
