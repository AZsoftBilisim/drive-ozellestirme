#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the purchase conditions
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	
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
	
	If ValueIsFilled(PurchaseConditions.BusinessOperation) Then
		
		OperationByAgreement		= BusinessOperation;
		SeparatePurchaseOperations	= PurchasesServer.BusinessOperationsOnMain(
										PurchaseConditions.BusinessOperation);
		
		If SeparatePurchaseOperations.Find(BusinessOperation) = Undefined Then
			
			If PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
				
				If SeparatePurchaseOperations.Find(Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery;
				ElsIf SeparatePurchaseOperations.Find(Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit;
				EndIf;
				
			ElsIf PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
				
				If SeparatePurchaseOperations.Find(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery;
				ElsIf SeparatePurchaseOperations.Find(Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit;
				EndIf;
				
			ElsIf PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport Then
				
				If SeparatePurchaseOperations.Find(Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit;
				EndIf;
				
			EndIf;
		EndIf;
		
		BusinessOperation = OperationByAgreement;
		
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations();
		ContractBusinessTransaction = PairsOfSeparatePurchaseOperations.Get(BusinessOperation);
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
		CompleteVATTaxation();
		
	EndIf;
	
	PriceIncludesVAT   = PurchaseConditions.PriceIncludesVAT;
	VendorPriceKind = PurchaseConditions.VendorPriceKind;
	
	FillInTypeOfActivityVAT();
	
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		BusinessTransactions = New Array;
		BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		
		If GetFunctionalOption("UseImports") Then
			BusinessTransactions.Add(Enums.BusinessTransactions.PurchaseByImport);
			BusinessTransactions.Add(Enums.BusinessTransactions.ImportFromEAEU);
		EndIf;
		
		AgreementSelectionParameters_ = New Structure;
		AgreementSelectionParameters_.Insert("SelectedAgreement",                     Terms);
		AgreementSelectionParameters_.Insert("BusinessTransactions",                   BusinessTransactions);
		AgreementSelectionParameters_.Insert("ConsiderWarehouseGroups",                  False);
		AgreementSelectionParameters_.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		AgreementSelectionParameters_.Insert("ContractsAreUsed",        True);
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, AgreementSelectionParameters_);
		
		PricesAreFilledOut = False;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				If RecalculatePrices_ And ValueIsFilled(Terms) Then
					
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields",     "Price, VATRate");
					FillParameters.Insert("Date",               Date);
					FillParameters.Insert("Currency",             Currency);
					FillParameters.Insert("Terms",         Terms);
					FillParameters.Insert("VendorPriceKind",  VendorPriceKind);
					FillParameters.Insert("VATTaxation", VATTaxation);
					
					ActionsWithStrings = New Structure;
					ActionsWithStrings.Insert("RecalculateAmount",     "NumberOfPackages");
					ActionsWithStrings.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
					ActionsWithStrings.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					
					PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, ActionsWithStrings);
					
				EndIf;
				
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
			
			PairsOfSeparatePurchaseOperations	= PurchasesServer.PairsOfSeparatePurchaseOperations();
			ContractBusinessTransaction	= PairsOfSeparatePurchaseOperations.Get(BusinessOperation);
			CurBusinessTransaction	= BusinessOperation;
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
			
			BusinessTransactions = PurchasesServer.EconomicOperationsOfSeparatePurchase("Document.ReceiptOfGoodsToWarehouse",
																						Terms,
																						Contract);
			If BusinessTransactions.Count() > 0 Then
				BusinessOperation = BusinessTransactions[0];
				
				If Not ValueIsFilled(Contract)
					And ValueIsFilled(CurBusinessTransaction)
					And BusinessOperation <> CurBusinessTransaction Then
					
					BusinessOperation = CurBusinessTransaction;
					
				EndIf;
				
				CompleteVATTaxation();
				FillInTypeOfActivityVAT();
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReceiptOfGoodsToWarehouse - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	ParametersForFillingInventoryTypes.UseSeparateProcurement = True;
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ReceiptOfGoodsToWarehouse.CollectionOfTabularPartsOfGoods.
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
							|en = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.'; fa = 'The ""%1"" parameter is not transferred to fill in the inventory owner attributes.';
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
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReceiptOfGoodsToWarehouse);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												SeriesSpecificationParameters,
												Cancel,
												NotCheckedAttributeArray);
	
	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit
		Or VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
		
		NotCheckedAttributeArray.Add("Currency");
		NotCheckedAttributeArray.Add("VendorPriceKind");
		NotCheckedAttributeArray.Add("Goods.VATRate");
		
	EndIf;
	
	TheseAreGoodsInTransit = Documents.ReceiptOfGoodsToWarehouse.ThisIsReceiptOfGoodsInTransit(BusinessOperation);
	If TheseAreGoodsInTransit Then
		NotCheckedAttributeArray.Add("VATActivityType");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Towary';
			|tr = 'Ürünler'"),
		Undefined);
		
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Towary';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	
	ReceiptOfGoodsToWarehouseLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var WarehouseForReceipt;
	Var EconomicOperationOfAcceptance;
	Var FillInUsingInvoice;
	Var FillByWarehouseDocument;
	
	Author = Users.CurrentUser();
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis") Then
			
			FillingData.Property("WarehouseForReceipt",             WarehouseForReceipt);
			FillingData.Property("EconomicOperationOfAcceptance", EconomicOperationOfAcceptance);
			FillingData.Property("FillInUsingInvoice",         FillInUsingInvoice);
			FillingData.Property("FillByWarehouseDocument",            FillByWarehouseDocument);
		
			If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder") Then
				
				FillInDocumentBasedOnOrderToSupplier(FillingData.DocumentBasis,
															WarehouseForReceipt,
															EconomicOperationOfAcceptance,
															FillInUsingInvoice,
															FillByWarehouseDocument);
				
			EndIf;
			
			If TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
				
				FillInDocumentBasedOnAgreementWithSupplier(FillingData.DocumentBasis,
																	WarehouseForReceipt,
																	EconomicOperationOfAcceptance,
																	FillInUsingInvoice);
				
			EndIf;
			
			If TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
				
				FillInDocumentOnBasisOfContract(FillingData.DocumentBasis,
													WarehouseForReceipt,
													EconomicOperationOfAcceptance,
													FillInUsingInvoice,
													FillByWarehouseDocument);
				
			EndIf;
			
			If TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.VendorInvoice") Then
				
				FillInDocumentBasedOnPurchaseOfGoods(FillingData.DocumentBasis,
																WarehouseForReceipt,
																EconomicOperationOfAcceptance,
																FillInUsingInvoice);
				
			EndIf;
			
		EndIf;
		
		If FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData);
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("CorrectedDocument") Then
			DocumentCorrection.FillInCorrection(ThisObject, FillingData.CorrectedDocument);
			FillInCorrectionOnBasisOfAcceptanceCertificateAfterReceipt(FillingData);
		EndIf;
		
		CollapseProductLines();
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ReceiptOfGoodsToWarehouse") Then
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);

	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		FillInDocumentBasedOnOrderToSupplier(FillingData, FillingData.Warehouse, 
			FillingData.BusinessOperation);

	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	ResponsiblePersonsServer.InstallManager(ThisObject, ReferenceOrder);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	InitializeDocument(FillingData);
	
	ReceiptOfGoodsToWarehouseLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	EconomicImportOperations     = PurchasesServer.BusinessOperationsOnMain(
											Enums.BusinessTransactions.PurchaseByImport);
	EconomicOperationsOfImportFromEAEU = PurchasesServer.BusinessOperationsOnMain(
											Enums.BusinessTransactions.ImportFromEAEU);
	
	TransactionIsNotSubjectToVAT = EconomicImportOperations.Find(BusinessOperation) <> Undefined
								Or EconomicOperationsOfImportFromEAEU.Find(BusinessOperation) <> Undefined;
	
	If TransactionIsNotSubjectToVAT Then
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
		
		For Each String In Goods Do
			String.Price      = 0;
			String.Sum     = 0;
			String.VATAmount  = 0;
			String.AmountIncludingVAT = 0;
		EndDo;
		
		VendorPriceKind = Catalogs.VendorPriceTypes.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
		Documents.ReceiptOfGoodsToWarehouse);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = Goods.Total("AmountIncludingVAT");
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryKinds.Clear();
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	ReceiptOfGoodsToWarehouseLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReceiptOfGoodsToWarehouseLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReceiptOfGoodsToWarehouseLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	IncomingDocumentDate = Date(1,1,1);
	IncomingDocumentNumber = "";
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	For Each CurRow In Goods Do
		
		CurRow.LotVendorAttributes = Catalogs.KeysForLotVendorAttributes.EmptyRef();

	EndDo;
	
	CompleteVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	ReceiptOfGoodsToWarehouseLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReceiptOfGoodsToWarehouseLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse       = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(ReferenceOrder) Then
		ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	EndIf;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Contract);
	
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	FillInTypeOfActivityVAT();
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Function TextOfFillInRequestBasedOn(AccordingToActOfDivergence = False)
	
	QueryTextGoods = "";
	If AccordingToActOfDivergence Then
		QueryTextGoods = "
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	ISNULL(HeaderData_.ReferenceOrder, UNDEFINED)	AS DocumentInflow,
		|	GoodsToReceive.Warehouse				AS Warehouse,
		|	GoodsToReceive.Products			AS Products,
		|	GoodsToReceive.Characteristic		AS Characteristic,
		|	GoodsToReceive.Purpose			AS Purpose,
		|	GoodsToReceive.Series				AS Series,
		|	GoodsToReceive.CountByDocument - GoodsToReceive.Count AS Count,
		|	GoodsToReceive.NumberOfPackagesByDocument - GoodsToReceive.NumberOfPackages AS NumberOfPackages
		|INTO TTProducts_1
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsToReceive
		|		LEFT JOIN TTOrder_ AS HeaderData_
		|		ON TRUE
		|WHERE
		|	GoodsToReceive.Ref = &DiscrepancyCertificate
		|	AND GoodsToReceive.Warehouse = &Warehouse 
		|	AND GoodsToReceive.Action IN
		|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices),
		|		VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.WaitForGoodsReceiptWithoutInvoices))
		|
		|UNION ALL
		|
		|	SELECT
		|	ISNULL(HeaderData_.ReferenceOrder, UNDEFINED)	AS DocumentInflow,
		|	GoodsToReceive.Warehouse				AS Warehouse,
		|	GoodsToReceive.Products			AS Products,
		|	GoodsToReceive.Characteristic		AS Characteristic,
		|	GoodsToReceive.Purpose			AS Purpose,
		|	GoodsToReceive.Series				AS Series,
		|	(GoodsToReceive.CountByDocument - GoodsToReceive.Count) AS Count,
		|	(GoodsToReceive.NumberOfPackagesByDocument - GoodsToReceive.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsToReceive
		|		LEFT JOIN TTOrder_ AS HeaderData_
		|		ON TRUE
		|WHERE
		|	GoodsToReceive.Ref = &DiscrepancyCertificate
		|	AND GoodsToReceive.Action IN
		|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration))
		|	AND (GoodsToReceive.CountByDocument - GoodsToReceive.Count) > 0
		|
		|INDEX BY
		|	DocumentInflow,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	Warehouse
		|;
		|";
	Else
		QueryTextGoods = "
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
		|	GoodsToReceive.Warehouse				AS Warehouse,
		|	GoodsToReceive.Products			AS Products,
		|	GoodsToReceive.Characteristic		AS Characteristic,
		|	GoodsToReceive.Purpose			AS Purpose,
		|	GoodsToReceive.Series				AS Series,
		|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS Count,
		|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS NumberOfPackages
		|INTO TTProducts_1
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(
		|			,
		|			DocumentInflow = &DocumentBasis
		|			AND CASE
		|				WHEN &WarehouseSpecified
		|					THEN Warehouse = &WarehouseForReceipt
		|				ELSE TRUE
		|			END
		|	) AS GoodsToReceive
		|WHERE
		|	NOT &FillInUsingInvoice
		|	AND GoodsToReceive.ToRegisterReceiptsByReferenceBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
		|	GoodsToReceive.Warehouse				AS Warehouse,
		|	GoodsToReceive.Products			AS Products,
		|	GoodsToReceive.Characteristic		AS Characteristic,
		|	GoodsToReceive.Purpose			AS Purpose,
		|	GoodsToReceive.Series				AS Series,
		|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS Count,
		|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(
		|			,
		|			DocumentInflow = &DocumentBasis
		|			AND CASE
		|				WHEN &WarehouseSpecified
		|					THEN Warehouse = &WarehouseForReceipt
		|				ELSE TRUE
		|			END
		|	) AS GoodsToReceive
		|WHERE
		|	&FillInUsingInvoice
		|	AND GoodsToReceive.ToRegisterReceiptsByInvoicesBalance > 0
		|
		|INDEX BY
		|	DocumentInflow,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	Warehouse
		|;
		|";
	EndIf;
	
	QueryText = 
	"SELECT
	|	PurchaseOfGoods.Ref					AS Ref,
	|	PurchaseOfGoods.Terms				AS Terms,
	|	PurchaseOfGoods.Partner					AS Partner,
	|	PurchaseOfGoods.Counterparty				AS Counterparty,
	|	PurchaseOfGoods.Organization				AS Organization,
	|	PurchaseOfGoods.Contract					AS Contract,
	|	CASE
	|		WHEN PurchaseOfGoods.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
	|		THEN
	|			PurchaseOfGoods.Contract
	|		WHEN PurchaseOfGoods.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
	|														VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
	|														VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
	|		THEN
	|			PurchaseOfGoods.Terms
	// If the order is divided by a waybill and it is a waybill and not an order, it means an invoice:
	|		WHEN NOT PurchaseOfGoods.ReceiptUnderOrders
	|			AND PurchaseOfGoods.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
	|		THEN
	|			PurchaseOfGoods.Ref
	|
	// If it is divided by a bill of lading and it is a bill of lading, it means an invoice:
	|		WHEN PurchaseOfGoods.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
	|		THEN
	|			PurchaseOfGoods.Ref
	|		ELSE
	|			PurchaseOfGoods.PurchaseOrder
	|	END										AS ReferenceOrder,
	|	PurchaseOfGoods.SalesOpportunity					AS SalesOpportunity,
	|	PurchaseOfGoods.Currency					AS Currency,
	|	ISNULL(Terms1.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
	|	PurchaseOfGoods.PriceIncludesVAT			AS PriceIncludesVAT,
	|	PurchaseOfGoods.VATTaxation		AS VATTaxation,
	|	PurchaseOfGoods.PurchaseForActivity	AS VATActivityType,
	|	PurchaseOfGoods.LineOfBusiness	AS LineOfBusiness,
	|	NOT PurchaseOfGoods.Posted				AS ThereAreErrorsPosted,
	|	FALSE										AS ThereAreErrorsStatus
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
	|"
	+ QueryTextGoods
	+ "
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	PackagingOfGoods.DocumentInflow			AS DocumentInflow,
	|	PackagingOfGoods.Warehouse						AS Warehouse,
	|	PackagingOfGoods.Products				AS Products,
	|	PackagingOfGoods.Characteristic				AS Characteristic,
	|	PackagingOfGoods.Purpose					AS Purpose,
	|	PackagingOfGoods.Series						AS Series,
	|	PackagingOfGoods.Package					AS Package,
	|	&QueryTextPackagingFactor			AS PackagingFactor,
	|	SUM(PackagingOfGoods.Count)			AS Count,
	|	SUM(PackagingOfGoods.NumberOfPackages)	AS NumberOfPackages
	|INTO TTPackagingOfGoods
	|FROM
	|	(SELECT
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		AcquisitionGoods.Package				AS Package,
	|		SUM(AcquisitionGoods.Count)	AS Count,
	|		SUM(AcquisitionGoods.NumberOfPackages) AS NumberOfPackages
	|	FROM
	|		TTProducts_1 AS GoodsToReceive
	|			LEFT JOIN Document.VendorInvoice.Goods AS AcquisitionGoods
	|			ON AcquisitionGoods.Ref = &DocumentBasis
	|				AND GoodsToReceive.Warehouse = AcquisitionGoods.Warehouse
	|				AND GoodsToReceive.Products = AcquisitionGoods.Products
	|				AND GoodsToReceive.Characteristic = AcquisitionGoods.Characteristic
	|				AND GoodsToReceive.Purpose = AcquisitionGoods.Purpose
	|				AND CASE
	|					WHEN AcquisitionGoods.BatchesIndicationStatus IN(14, 18)
	|						THEN GoodsToReceive.Series = AcquisitionGoods.Series
	|					ELSE TRUE
	|				END
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
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		GoodsReceipts.Package				AS Package,
	|		-SUM(GoodsReceipts.Count)	AS Count,
	|		-SUM(GoodsReceipts.NumberOfPackages) AS NumberOfPackages
	|	FROM
	|		TTProducts_1 AS GoodsToReceive
	|			LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS ReceiptToWarehouse
	|			ON GoodsToReceive.DocumentInflow = ReceiptToWarehouse.ReferenceOrder
	|				AND GoodsToReceive.Warehouse = ReceiptToWarehouse.Warehouse
	|		
	|			LEFT JOIN Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
	|			ON ReceiptToWarehouse.Ref = GoodsReceipts.Ref
	|				AND GoodsToReceive.Products = GoodsReceipts.Products
	|				AND GoodsToReceive.Characteristic = GoodsReceipts.Characteristic
	|				AND GoodsToReceive.Purpose = GoodsReceipts.Purpose
	|				AND CASE
	|					WHEN GoodsReceipts.BatchesIndicationStatus IN(14, 18)
	|						AND GoodsToReceive.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN GoodsToReceive.Series = GoodsReceipts.Series
	|					ELSE TRUE
	|				END
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
	|		GoodsReceipts.Package
	|	) AS PackagingOfGoods
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
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceive.Warehouse				AS Warehouse,
	|	GoodsToReceive.Products			AS Products,
	|	GoodsToReceive.Characteristic		AS Characteristic,
	|	GoodsToReceive.Purpose			AS Purpose,
	|	GoodsToReceive.Series				AS Series,
	|	GoodsToReceive.Package				AS Package,
	|	GoodsToReceive.PackagingFactor	AS PackagingFactor,
	|	GoodsToReceive.Count			AS Count,
	|	GoodsToReceive.NumberOfPackages	AS NumberOfPackages,
	|	AcquisitionGoods.Price					AS Price,
	|	AcquisitionGoods.VATRate			AS VATRate
	|INTO TTPricesOfGoods
	|FROM
	|	TTPackagingOfGoods AS GoodsToReceive
	|		LEFT JOIN Document.VendorInvoice.Goods AS AcquisitionGoods
	|		ON AcquisitionGoods.Ref = &DocumentBasis
	|			AND GoodsToReceive.Warehouse = AcquisitionGoods.Warehouse
	|			AND GoodsToReceive.Products = AcquisitionGoods.Products
	|			AND GoodsToReceive.Characteristic = AcquisitionGoods.Characteristic
	|			AND GoodsToReceive.Purpose = AcquisitionGoods.Purpose
	|				AND CASE
	|					WHEN AcquisitionGoods.BatchesIndicationStatus IN(14, 18)
	|						THEN GoodsToReceive.Series = AcquisitionGoods.Series
	|					ELSE TRUE
	|				END
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
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsToReceive.DocumentInflow				AS DocumentInflow,
	|	GoodsToReceive.Warehouse							AS Warehouse,
	|	GoodsToReceive.Products						AS Products,
	|	GoodsToReceive.Characteristic					AS Characteristic,
	|	GoodsToReceive.Purpose						AS Purpose,
	|	GoodsToReceive.Series							AS Series,
	|	GoodsToReceive.Package							AS Package,
	|	COUNT(DISTINCT GoodsToReceive.Price)		AS NumberOfPrices,
	|	COUNT(DISTINCT GoodsToReceive.VATRate)	AS NumberOfVATRates
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
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	TableReferenceOrder.Ref					AS Ref,
	|	TableReferenceOrder.Terms				AS Terms,
	|	TableReferenceOrder.Partner					AS Partner,
	|	TableReferenceOrder.Counterparty				AS Counterparty,
	|	TableReferenceOrder.Organization				AS Organization,
	|	TableReferenceOrder.Contract					AS Contract,
	|	TableReferenceOrder.ReferenceOrder			AS ReferenceOrder,
	|	TableReferenceOrder.SalesOpportunity					AS SalesOpportunity,
	|	TableReferenceOrder.Currency					AS Currency,
	|	TableReferenceOrder.VendorPriceKind		AS VendorPriceKind,
	|	TableReferenceOrder.PriceIncludesVAT			AS PriceIncludesVAT,
	|	TableReferenceOrder.VATTaxation		AS VATTaxation,
	|	TableReferenceOrder.VATActivityType		AS VATActivityType,
	|	TableReferenceOrder.LineOfBusiness	AS LineOfBusiness,
	|	TableReferenceOrder.ThereAreErrorsPosted		AS ThereAreErrorsPosted,
	|	TableReferenceOrder.ThereAreErrorsStatus		AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	AcquisitionGoods.Products AS Products,
	|	AcquisitionGoods.Characteristic AS Characteristic,
	|	AcquisitionGoods.Package AS Package,
	|	AcquisitionGoods.Purpose AS Purpose,
	|	AcquisitionGoods.Series AS Series,
	|	MAX(AcquisitionGoods.PartnerProducts) AS PartnerProducts
	|
	|INTO TTItemsOfPartnerForPurchase
	|FROM
	|	Document.VendorInvoice.Goods AS AcquisitionGoods
	|
	|WHERE
	|	&UsePartnersProducts
	|	AND AcquisitionGoods.Ref = &DocumentBasis
	|
	|GROUP BY
	|	AcquisitionGoods.Products,
	|	AcquisitionGoods.Characteristic,
	|	AcquisitionGoods.Package,
	|	AcquisitionGoods.Purpose,
	|	AcquisitionGoods.Series
	|
	|HAVING
	|	COUNT(DISTINCT AcquisitionGoods.PartnerProducts) = 1
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	GoodsTable.DocumentInflow		AS DocumentInflow,
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	GoodsTable.Purpose				AS Purpose,
	|	GoodsTable.Series						AS Series,
	|	SUM(GoodsTable.Count)			AS Count,
	|	SUM(GoodsTable.NumberOfPackages)	AS NumberOfPackages
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	DocumentInflow
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	Goods.DocumentInflow			AS DocumentInflow,
	|	Goods.Products					AS Products,
	|	Goods.Characteristic				AS Characteristic,
	|	Goods.Purpose					AS Purpose,
	|	Goods.Series						AS Series,
	|	Goods.Package						AS Package,
	|	Goods.PackagingFactor			AS PackagingFactor,
	|	SUM(Goods.Count)			AS Count,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages,
	|	Goods.Price							AS Price,
	|	Goods.VATRate					AS VATRate,
	|	AcquisitionPartnerItemList.PartnerProducts AS PartnerProducts
	|FROM
	|	(SELECT DISTINCT
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		GoodsToReceive.Package				AS Package,
	|		GoodsToReceive.PackagingFactor	AS PackagingFactor,
	|		GoodsToReceive.Count			AS Count,
	|		GoodsToReceive.NumberOfPackages	AS NumberOfPackages,
	|		CASE
	|			WHEN ProductPrices.NumberOfPrices = 1
	|				THEN GoodsToReceive.Price
	|			ELSE 0
	|		END									AS Price,
	|		CASE
	|			WHEN ProductPrices.NumberOfVATRates = 1
	|				THEN GoodsToReceive.VATRate
	|			ELSE 0
	|		END									AS VATRate
	|	FROM
	|		TTPricesOfGoods AS GoodsToReceive
	|			LEFT JOIN TTProductPricesGrouping ProductPrices
	|			ON GoodsToReceive.DocumentInflow = ProductPrices.DocumentInflow
	|				AND GoodsToReceive.Warehouse = ProductPrices.Warehouse
	|				AND GoodsToReceive.Products = ProductPrices.Products
	|				AND GoodsToReceive.Characteristic = ProductPrices.Characteristic
	|				AND GoodsToReceive.Purpose = ProductPrices.Purpose
	|				AND GoodsToReceive.Series = ProductPrices.Series
	|				AND GoodsToReceive.Package = ProductPrices.Package
	|	) AS Goods
	|
	|	LEFT JOIN TTItemsOfPartnerForPurchase AS AcquisitionPartnerItemList
	|		ON Goods.Products = AcquisitionPartnerItemList.Products
	|		AND Goods.Characteristic = AcquisitionPartnerItemList.Characteristic
	|		AND Goods.Package = AcquisitionPartnerItemList.Package
	|		AND Goods.Purpose = AcquisitionPartnerItemList.Purpose
	|		AND Goods.Series = AcquisitionPartnerItemList.Series
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
	|	Goods.VATRate,
	|	AcquisitionPartnerItemList.PartnerProducts
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package,
	|	DocumentInflow,
	|	PackagingFactor DESC";
	
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PackagingOfGoods.Package",
									"PackagingOfGoods.Products"));
									
	Return QueryText;
	
EndFunction

Procedure FillInDocumentBasedOnAgreementWithSupplier(Val DocumentBasis, Val WarehouseForReceipt = Undefined, Val EconomicOperationOfAcceptance = Undefined, Val FillInUsingInvoice = False)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TermsOfPurchases.Ref					AS Ref,
	|	TermsOfPurchases.Status					AS DocumentStatus,
	|	TermsOfPurchases.Partner					AS Partner,
	|	TermsOfPurchases.Counterparty				AS Counterparty,
	|	TermsOfPurchases.Ref					AS Terms,
	|	TermsOfPurchases.Organization				AS Organization,
	|	TermsOfPurchases.Currency					AS Currency,
	|	TermsOfPurchases.VendorPriceKind		AS PriceKind,
	|	TermsOfPurchases.PriceIncludesVAT			AS PriceIncludesVAT,
	|	TermsOfPurchases.LineOfBusiness	AS LineOfBusiness,
	|	CASE
	|		WHEN TermsOfPurchases.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS TheseAreAgencyServices,
	|	CASE
	|		WHEN TermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS ThereAreErrorsStatus
	|INTO TTOrder_
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|WHERE
	|	TermsOfPurchases.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceiveBalance.Products			AS Products,
	|	GoodsToReceiveBalance.Characteristic		AS Characteristic,
	|	GoodsToReceiveBalance.Purpose			AS Purpose,
	|	GoodsToReceiveBalance.Series					AS Series,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance	AS Count,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance	AS NumberOfPackages
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND (NOT &FilterByBusinessTransaction
	|				OR BusinessOperation IN(&BusinessOperation))) AS GoodsToReceiveBalance
	|WHERE
	|	NOT &FillInUsingInvoice
	|	AND GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceiveBalance.Products			AS Products,
	|	GoodsToReceiveBalance.Characteristic		AS Characteristic,
	|	GoodsToReceiveBalance.Purpose			AS Purpose,
	|	GoodsToReceiveBalance.Series					AS Series,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance	AS Count,
	|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance	AS NumberOfPackages
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND (NOT &FilterByBusinessTransaction
	|				OR BusinessOperation IN(&BusinessOperation))) AS GoodsToReceiveBalance
	|WHERE
	|	&FillInUsingInvoice
	|	AND GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance > 0
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableReferenceOrder.Ref					AS Ref,
	|	TableReferenceOrder.Terms				AS Terms,
	|	TableReferenceOrder.Partner					AS Partner,
	|	TableReferenceOrder.Counterparty				AS Counterparty,
	|	TableReferenceOrder.Organization				AS Organization,
	|	TableReferenceOrder.DocumentStatus			AS DocumentStatus,
	|	TableReferenceOrder.Currency					AS Currency,
	|	TableReferenceOrder.PriceKind					AS PriceKind,
	|	TableReferenceOrder.PriceIncludesVAT			AS PriceIncludesVAT,
	|	TableReferenceOrder.LineOfBusiness	AS LineOfBusiness,
	|	TableReferenceOrder.TheseAreAgencyServices		AS TheseAreAgencyServices,
	|	TableReferenceOrder.ThereAreErrorsStatus		AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	GoodsTable.DocumentInflow	AS DocumentInflow,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Purpose			AS Purpose,
	|	GoodsTable.Series					AS Series,
	|	GoodsTable.Count			AS Count,
	|	GoodsTable.NumberOfPackages	AS NumberOfPackages
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	DocumentInflow";
		
	Query.SetParameter("DocumentBasis",				DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",				WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",					ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FillInUsingInvoice",			FillInUsingInvoice = True);
	Query.SetParameter("FilterByBusinessTransaction",	ValueIsFilled(EconomicOperationOfAcceptance));
	Query.SetParameter("BusinessOperation",			EconomicOperationOfAcceptance);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection		= QueryResult[2].Select();
	VTProducts_	= QueryResult[3].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfPurchase.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Selection.Terms,
															Selection.DocumentStatus,
															,
															Selection.ThereAreErrorsStatus,
															ArrayOfValidStatuses);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(,Selection.TheseAreAgencyServices);
	
	ReferenceOrder = DocumentBasis;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	If ValueIsFilled(WarehouseForReceipt) Then
		Warehouse = WarehouseForReceipt;
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	
	Goods.Load(VTProducts_);
	
	RecalculateNumberOfPackagesFillInVATRate();
	FillThePricesByTermsOfSales();
	
EndProcedure

Procedure FillInDocumentBasedOnOrderToSupplier(DocumentBasis,
														WarehouseForReceipt = Undefined,
														EconomicOperationOfAcceptance = Undefined,
														FillInUsingInvoice = False,
														FillByWarehouseDocument = False)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PurchaseOrder.Ref					AS Ref,
	|	PurchaseOrder.Terms				AS Terms,
	|	PurchaseOrder.Partner					AS Partner,
	|	PurchaseOrder.Counterparty				AS Counterparty,
	|	PurchaseOrder.Organization				AS Organization,
	|	PurchaseOrder.Status					AS DocumentStatus,
	|	PurchaseOrder.Contract					AS Contract,
	|	PurchaseOrder.SalesOpportunity					AS SalesOpportunity,
	|	PurchaseOrder.Currency					AS Currency,
	|	ISNULL(Terms1.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
	|	PurchaseOrder.PriceIncludesVAT			AS PriceIncludesVAT,
	|	PurchaseOrder.VATTaxation		AS VATTaxation,
	|	PurchaseOrder.PurchaseForActivity	AS VATActivityType,
	|	PurchaseOrder.LineOfBusiness	AS LineOfBusiness,
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
	|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceive.Warehouse				AS Warehouse,
	|	GoodsToReceive.Products			AS Products,
	|	GoodsToReceive.Characteristic		AS Characteristic,
	|	GoodsToReceive.Purpose			AS Purpose,
	|	GoodsToReceive.Series				AS Series,
	|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS Count,
	|	GoodsToReceive.ToRegisterReceiptsByReferenceBalance AS NumberOfPackages
	|INTO TTProducts_1
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND Products.ItemsType IN (&Goods)
	|	) AS GoodsToReceive
	|WHERE
	|	&FillByOrderDocument
	|	AND GoodsToReceive.ToRegisterReceiptsByReferenceBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceive.Warehouse				AS Warehouse,
	|	GoodsToReceive.Products			AS Products,
	|	GoodsToReceive.Characteristic		AS Characteristic,
	|	GoodsToReceive.Purpose			AS Purpose,
	|	GoodsToReceive.Series				AS Series,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS Count,
	|	GoodsToReceive.ToRegisterReceiptsByInvoicesBalance AS NumberOfPackages
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND Products.ItemsType IN (&Goods)
	|	) AS GoodsToReceive
	|WHERE
	|	&FillInUsingInvoice
	|	AND GoodsToReceive.ToRegisterReceiptsByInvoicesBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceive.Warehouse				AS Warehouse,
	|	GoodsToReceive.Products			AS Products,
	|	GoodsToReceive.Characteristic		AS Characteristic,
	|	GoodsToReceive.Purpose			AS Purpose,
	|	GoodsToReceive.Series				AS Series,
	|	GoodsToReceive.ToRegisterGoodsReceiptsBalance AS Count,
	|	GoodsToReceive.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND Products.ItemsType IN (&Goods)
	|	) AS GoodsToReceive
	|WHERE
	|	&FillByWarehouseDocument
	|	AND GoodsToReceive.ToRegisterGoodsReceiptsBalance > 0
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
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	PackagingOfGoods.DocumentInflow			AS DocumentInflow,
	|	PackagingOfGoods.Warehouse						AS Warehouse,
	|	PackagingOfGoods.Products				AS Products,
	|	PackagingOfGoods.Characteristic				AS Characteristic,
	|	PackagingOfGoods.Purpose					AS Purpose,
	|	PackagingOfGoods.Series						AS Series,
	|	PackagingOfGoods.Package					AS Package,
	|	&QueryTextPackagingFactor			AS PackagingFactor,
	|	SUM(PackagingOfGoods.Count)			AS Count,
	|	SUM(PackagingOfGoods.NumberOfPackages)	AS NumberOfPackages
	|INTO TTPackagingOfGoods
	|FROM
	|	(SELECT
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		GoodsFromOrder.Package					AS Package,
	|		SUM(GoodsFromOrder.Count)			AS Count,
	|		SUM(GoodsFromOrder.NumberOfPackages)	AS NumberOfPackages
	|	FROM
	|		TTProducts_1 AS GoodsToReceive
	|			LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
	|			ON GoodsToReceive.DocumentInflow = GoodsFromOrder.Ref
	|				AND GoodsToReceive.Warehouse = GoodsFromOrder.Warehouse
	|				AND GoodsToReceive.Products = GoodsFromOrder.Products
	|				AND GoodsToReceive.Characteristic = GoodsFromOrder.Characteristic
	|				AND GoodsToReceive.Purpose = GoodsFromOrder.Purpose
	|	WHERE
	|		NOT ISNULL(GoodsFromOrder.Canceled, FALSE)
	|	
	|	GROUP BY
	|		GoodsToReceive.DocumentInflow,
	|		GoodsToReceive.Warehouse,
	|		GoodsToReceive.Products,
	|		GoodsToReceive.Characteristic,
	|		GoodsToReceive.Purpose,
	|		GoodsToReceive.Series,
	|		GoodsFromOrder.Package
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		GoodsReceipts.Package				AS Package,
	|		-SUM(GoodsReceipts.Count)	AS Count,
	|		-SUM(GoodsReceipts.NumberOfPackages) AS NumberOfPackages
	|FROM
	|	TTProducts_1 AS GoodsToReceive
	|		LEFT JOIN Document.ReceiptOfGoodsToWarehouse AS ReceiptToWarehouse
	|		ON GoodsToReceive.DocumentInflow = ReceiptToWarehouse.ReferenceOrder
	|			AND GoodsToReceive.Warehouse = ReceiptToWarehouse.Warehouse
	|		
	|		LEFT JOIN Document.ReceiptOfGoodsToWarehouse.Goods AS GoodsReceipts
	|		ON ReceiptToWarehouse.Ref = GoodsReceipts.Ref
	|			AND GoodsToReceive.Products = GoodsReceipts.Products
	|			AND GoodsToReceive.Characteristic = GoodsReceipts.Characteristic
	|			AND GoodsToReceive.Purpose = GoodsReceipts.Purpose
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
	|		GoodsReceipts.Package
	|	) AS PackagingOfGoods
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
	|	Package
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT DISTINCT
	|	GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|	GoodsToReceive.Warehouse				AS Warehouse,
	|	GoodsToReceive.Products			AS Products,
	|	GoodsToReceive.Characteristic		AS Characteristic,
	|	GoodsToReceive.Purpose			AS Purpose,
	|	GoodsToReceive.Series				AS Series,
	|	GoodsToReceive.Package				AS Package,
	|	GoodsToReceive.PackagingFactor	AS PackagingFactor,
	|	GoodsToReceive.Count			AS Count,
	|	GoodsToReceive.NumberOfPackages	AS NumberOfPackages,
	|	GoodsFromOrder.Price						AS Price,
	|	GoodsFromOrder.VATRate					AS VATRate
	|INTO TTPricesOfGoods
	|FROM
	|	TTPackagingOfGoods AS GoodsToReceive
	|		LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
	|		ON GoodsToReceive.DocumentInflow = GoodsFromOrder.Ref
	|			AND GoodsToReceive.Warehouse = GoodsFromOrder.Warehouse
	|			AND GoodsToReceive.Products = GoodsFromOrder.Products
	|			AND GoodsToReceive.Characteristic = GoodsFromOrder.Characteristic
	|			AND GoodsToReceive.Purpose = GoodsFromOrder.Purpose
	|			AND GoodsToReceive.Package = GoodsFromOrder.Package
	|WHERE
	|	NOT ISNULL(GoodsFromOrder.Canceled, FALSE)
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
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsToReceive.DocumentInflow				AS DocumentInflow,
	|	GoodsToReceive.Warehouse							AS Warehouse,
	|	GoodsToReceive.Products						AS Products,
	|	GoodsToReceive.Characteristic					AS Characteristic,
	|	GoodsToReceive.Purpose						AS Purpose,
	|	GoodsToReceive.Series							AS Series,
	|	GoodsToReceive.Package							AS Package,
	|	COUNT(DISTINCT GoodsToReceive.Price)		AS NumberOfPrices,
	|	COUNT(DISTINCT GoodsToReceive.VATRate)	AS NumberOfVATRates
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
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	TableReferenceOrder.Ref					AS Ref,
	|	TableReferenceOrder.Terms				AS Terms,
	|	TableReferenceOrder.Partner					AS Partner,
	|	TableReferenceOrder.Counterparty				AS Counterparty,
	|	TableReferenceOrder.Organization				AS Organization,
	|	TableReferenceOrder.DocumentStatus			AS DocumentStatus,
	|	TableReferenceOrder.Contract					AS Contract,
	|	TableReferenceOrder.SalesOpportunity					AS SalesOpportunity,
	|	TableReferenceOrder.Currency					AS Currency,
	|	TableReferenceOrder.VendorPriceKind		AS VendorPriceKind,
	|	TableReferenceOrder.PriceIncludesVAT			AS PriceIncludesVAT,
	|	TableReferenceOrder.VATTaxation		AS VATTaxation,
	|	TableReferenceOrder.VATActivityType		AS VATActivityType,
	|	TableReferenceOrder.LineOfBusiness	AS LineOfBusiness,
	|	TableReferenceOrder.ThereAreErrorsPosted		AS ThereAreErrorsPosted,
	|	TableReferenceOrder.ThereAreErrorsStatus		AS ThereAreErrorsStatus
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	PurchaseOrderGoods.Products AS Products,
	|	PurchaseOrderGoods.Characteristic AS Characteristic,
	|	PurchaseOrderGoods.Package AS Package,
	|	MAX(PurchaseOrderGoods.PartnerProducts) AS PartnerProducts
	|
	|INTO TTItemOfPartnerOnBasisOf
	|FROM
	|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|WHERE
	|	&UsePartnersProducts
	|	AND PurchaseOrderGoods.Ref = &DocumentBasis
	|
	|GROUP BY
	|	PurchaseOrderGoods.Products,
	|	PurchaseOrderGoods.Characteristic,
	|	PurchaseOrderGoods.Package	
	|HAVING
	|	COUNT(DISTINCT PurchaseOrderGoods.PartnerProducts) = 1
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	GoodsTable.DocumentInflow		AS DocumentInflow,
	|	GoodsTable.Products				AS Products,
	|	GoodsTable.Characteristic			AS Characteristic,
	|	GoodsTable.Purpose				AS Purpose,
	|	GoodsTable.Series						AS Series,
	|	SUM(GoodsTable.Count)			AS Count,
	|	SUM(GoodsTable.NumberOfPackages)	AS NumberOfPackages
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|GROUP BY
	|	GoodsTable.DocumentInflow,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	DocumentInflow
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT
	|	Goods.DocumentInflow			AS DocumentInflow,
	|	Goods.Products					AS Products,
	|	Goods.Characteristic				AS Characteristic,
	|	Goods.Purpose					AS Purpose,
	|	Goods.Series						AS Series,
	|	Goods.Package						AS Package,
	|	Goods.PackagingFactor			AS PackagingFactor,
	|	SUM(Goods.Count)			AS Count,
	|	SUM(Goods.NumberOfPackages)	AS NumberOfPackages,
	|	Goods.Price							AS Price,
	|	Goods.VATRate					AS VATRate,
	|	PartnerSItemByBase.PartnerProducts AS PartnerProducts
	|FROM
	|	(SELECT DISTINCT
	|		GoodsToReceive.DocumentInflow	AS DocumentInflow,
	|		GoodsToReceive.Warehouse				AS Warehouse,
	|		GoodsToReceive.Products			AS Products,
	|		GoodsToReceive.Characteristic		AS Characteristic,
	|		GoodsToReceive.Purpose			AS Purpose,
	|		GoodsToReceive.Series				AS Series,
	|		GoodsToReceive.Package				AS Package,
	|		GoodsToReceive.PackagingFactor	AS PackagingFactor,
	|		GoodsToReceive.Count			AS Count,
	|		GoodsToReceive.NumberOfPackages	AS NumberOfPackages,
	|		CASE
	|			WHEN ProductPrices.NumberOfPrices = 1
	|				THEN GoodsToReceive.Price
	|			ELSE 0
	|		END									AS Price,
	|		CASE
	|			WHEN ProductPrices.NumberOfVATRates = 1
	|				THEN GoodsToReceive.VATRate
	|			ELSE 0
	|		END									AS VATRate
	|	FROM
	|		TTPricesOfGoods AS GoodsToReceive
	|			LEFT JOIN TTProductPricesGrouping ProductPrices
	|			ON GoodsToReceive.DocumentInflow = ProductPrices.DocumentInflow
	|				AND GoodsToReceive.Warehouse = ProductPrices.Warehouse
	|				AND GoodsToReceive.Products = ProductPrices.Products
	|				AND GoodsToReceive.Characteristic = ProductPrices.Characteristic
	|				AND GoodsToReceive.Purpose = ProductPrices.Purpose
	|				AND GoodsToReceive.Series = ProductPrices.Series
	|				AND GoodsToReceive.Package = ProductPrices.Package
	|	) AS Goods
	|
	|	LEFT JOIN TTItemOfPartnerOnBasisOf AS PartnerSItemByBase
	|		ON Goods.Products = PartnerSItemByBase.Products
	|		AND Goods.Characteristic = PartnerSItemByBase.Characteristic
	|		AND Goods.Package = PartnerSItemByBase.Package
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
	|	Goods.VATRate,
	|	PartnerSItemByBase.PartnerProducts
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	Package,
	|	DocumentInflow,
	|	PackagingFactor DESC";
	
	Query.Text = StrReplace(Query.Text,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"PackagingOfGoods.Package",
									"PackagingOfGoods.Products"));
	
	Query.SetParameter("DocumentBasis",		DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",		WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",			ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FillByOrderDocument",		Not (FillInUsingInvoice = True Or FillByWarehouseDocument = True));
	Query.SetParameter("FillInUsingInvoice",	FillInUsingInvoice = True);
	Query.SetParameter("FillByWarehouseDocument",		FillByWarehouseDocument = True);
	Query.SetParameter("UsePartnersProducts", GetFunctionalOption("UsePartnersProducts"));
	
	TypeOfGoods = New Array;
	TypeOfGoods.Add(Enums.ItemsTypes.OwnGoods);
	TypeOfGoods.Add(Enums.ItemsTypes.ReusablePackage);
	
	Query.SetParameter("Goods",					TypeOfGoods);

	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[5].Select();
	VTProducts_			= QueryResult[7].Unload();
	VTOfPackaging			= QueryResult[8].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DocumentBasis,
															Selection.DocumentStatus,
															Selection.ThereAreErrorsPosted,
															Selection.ThereAreErrorsStatus,
															ArrayOfValidStatuses);
	
	ReferenceOrder	= DocumentBasis;
	Warehouse			= WarehouseForReceipt;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	TheseAreGoodsInTransit = Documents.ReceiptOfGoodsToWarehouse.ThisIsReceiptOfGoodsInTransit(BusinessOperation);
	PropertiesToExclude = ?(TheseAreGoodsInTransit, "VATActivityType", "");
	
	FillPropertyValues(ThisObject, Selection, , PropertiesToExclude);
	FillInPartnerSPackagingPricesItemList(VTProducts_, VTOfPackaging);
	RecalculateNumberOfPackagesFillInVATRate();
	FillThePricesByTermsOfSales(False);
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoods(Val DocumentBasis, Val WarehouseForReceipt = Undefined, Val EconomicOperationOfAcceptance = Undefined, Val FillInUsingInvoice = False)
	
	Query = New Query;
	
	Query.Text = TextOfFillInRequestBasedOn(False);
	
	Query.SetParameter("DocumentBasis",		DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",		WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",			ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FillInUsingInvoice",	FillInUsingInvoice = True);
	Query.SetParameter("UsePartnersProducts", GetFunctionalOption("UsePartnersProducts"));
	
	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[5].Select();
	VTProducts_			= QueryResult[7].Unload();
	VTOfPackaging			= QueryResult[8].Unload();
	
	Selection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DocumentBasis,
															Undefined,
															Selection.ThereAreErrorsPosted,
															Selection.ThereAreErrorsStatus);
	
	ReferenceOrder	= DocumentBasis;
	Warehouse			= WarehouseForReceipt;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	TheseAreGoodsInTransit = Documents.ReceiptOfGoodsToWarehouse.ThisIsReceiptOfGoodsInTransit(BusinessOperation);
	PropertiesToExclude = ?(TheseAreGoodsInTransit, "VATActivityType", "");
	
	FillPropertyValues(ThisObject, Selection, , PropertiesToExclude);
	FillInPartnerSPackagingPricesItemList(VTProducts_, VTOfPackaging);
	RecalculateNumberOfPackagesFillInVATRate();
	FillThePricesByTermsOfSales(False);
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData)
	
	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	DiscrepancyReportFollowingReceiptBaseDocument = DiscrepancyCertificate;
	DocumentPurchase = Undefined;
	
	If FillingData.Property("BasisOfAct") Then
		DocumentPurchase = FillingData.BasisOfAct;
		DocumentBasis = FillingData.BasisOfAct;
	ElsIf FillingData.Property("CorrectedDocument") Then
		DocumentPurchase = FillingData.Purchase;
		DocumentBasis = FillingData.CorrectedDocument;
	EndIf;
		
	If FillingData.Property("Warehouse") Then 
		Warehouse = FillingData.Warehouse;
	Else
		Warehouse = Common.ObjectAttributeValue(DocumentBasis, "Warehouse");   
	EndIf;
		
	Query = New Query;
	
	Query.Text = TextOfFillInRequestBasedOn(True);
	
	Query.SetParameter("DiscrepancyCertificate",		DiscrepancyCertificate);
	Query.SetParameter("Warehouse",		Warehouse);
	Query.SetParameter("DocumentBasis",		DocumentPurchase);
	Query.SetParameter("UsePartnersProducts", GetFunctionalOption("UsePartnersProducts"));
	
	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[5].Select();
	VTProducts_			= QueryResult[7].Unload();
	VTOfPackaging			= QueryResult[8].Unload();
	
	Selection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(DocumentBasis,
															Undefined,
															Selection.ThereAreErrorsPosted,
															Selection.ThereAreErrorsStatus);
	
	EconomicOperationOfAcceptance = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	TheseAreGoodsInTransit = Documents.ReceiptOfGoodsToWarehouse.ThisIsReceiptOfGoodsInTransit(BusinessOperation);
	PropertiesToExclude = ?(TheseAreGoodsInTransit, "VATActivityType", "");
	
	FillPropertyValues(ThisObject, Selection, , PropertiesToExclude);
	FillInPartnerSPackagingPricesItemList(VTProducts_, VTOfPackaging);
	RecalculateNumberOfPackagesFillInVATRate();
	FillThePricesByTermsOfSales(False);
	
	SubsequentDelivery = True;
	
EndProcedure

// Parameters:
// 	VTProducts_ - ValueTable - 
// 	VTOfPackaging - ValueTable - 
Procedure FillInPartnerSPackagingPricesItemList(VTProducts_, VTOfPackaging)
	
	PropertiesOfPackages	= "Package, Count, NumberOfPackages, Price, VATRate, PartnerProducts";
	ProductProperties_1		= "DocumentInflow, Products, Characteristic, Purpose";
	SearchProperties		= New Structure(ProductProperties_1);
	
	VTOfPackaging.Indexes.Add(ProductProperties_1);
	
	For Each RowOfGoods In VTProducts_ Do
		
		TSRow = Goods.Add();
		FillPropertyValues(TSRow, RowOfGoods);
		FillPropertyValues(SearchProperties, RowOfGoods);
		
		Count			= RowOfGoods.Count;
		ProductPackaging_		= VTOfPackaging.FindRows(SearchProperties);
		RemovablePackages	= New Array;
		
		For Each StringOfPackages In ProductPackaging_ Do
			
			If Count >= StringOfPackages.Count Then
				
				NewLineTS = Goods.Add();
				FillPropertyValues(NewLineTS, TSRow, , PropertiesOfPackages);
				FillPropertyValues(NewLineTS, StringOfPackages, PropertiesOfPackages);
				FillInSummaryIndicatorsOfProductLine(NewLineTS);
				
				Count = Count - StringOfPackages.Count;
				
				If Count > 0 Then
					TSRow.Count			= Count;
					TSRow.NumberOfPackages	= Count;
					
					FillInSummaryIndicatorsOfProductLine(TSRow);
				Else
					Goods.Delete(TSRow);
				EndIf;
				
				RemovablePackages.Add(StringOfPackages);
				
			EndIf;
			
			If Count <= 0 Then
				Break;
			EndIf;
			
		EndDo;
		
		For Each RowToDelete In RemovablePackages Do
			VTOfPackaging.Delete(RowToDelete);
		EndDo;
		
	EndDo;
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	TypesOfBases_ = New Array;
	TypesOfBases_.Add(Type("DocumentRef.PurchaseOrder"));
	TypesOfBases_.Add(Type("DocumentRef.VendorInvoice"));
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

Procedure FillInCorrectionOnBasisOfAcceptanceCertificateAfterReceipt(FillingData)
	
	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	DocumentPurchase = Undefined;
	ThisIsInputOfFix = False;
	
	If FillingData.Property("BasisOfAct") Then
		DocumentPurchase = FillingData.BasisOfAct;
	ElsIf FillingData.Property("CorrectedDocument") Then
		DocumentPurchase = FillingData.Purchase;
		ThisIsInputOfFix = True;
	EndIf;
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	Table.Products,
	|	Table.Characteristic,
	|	Table.Purpose,
	|	Table.CountByDocument - Table.Count AS Count,
	|	Table.Series
	|INTO TTProductsAct
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS Table
	|WHERE
	|	Table.Ref = &DiscrepancyCertificate
	|	AND Table.Action IN 
	|		(VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.ReturnOverdeliveredWithoutRegistration),
	|		 VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RecogniseOverdeliveredAsOtherIncome))
	|;
	|
	|SELECT
	|	JoinTable.Products,
	|	JoinTable.Characteristic,
	|	JoinTable.Purpose,
	|	JoinTable.Series,
	|	SUM(JoinTable.Count) AS QuantityAfterChange,
	|	TRUE AS LineOverfilled
	|FROM
	|	(
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.Count AS Count,
	|		Table.Series
	|	FROM
	|		TTProductsAct AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Purpose,
	|		Table.Count,
	|		Table.Series
	|	FROM
	|		Document.ReceiptOfGoodsToWarehouse.Goods AS Table
	|			INNER JOIN TTProductsAct AS ProductsOfAct
	|			ON ProductsOfAct.Products = Table.Products
	|			AND ProductsOfAct.Characteristic = Table.Characteristic
	|			AND ProductsOfAct.Purpose = Table.Purpose
	|	WHERE
	|		Table.Ref = &CorrectedDocument
	|	) AS JoinTable
	|
	|GROUP BY
	|	JoinTable.Products,
	|	JoinTable.Characteristic,
	|	JoinTable.Purpose,
	|	JoinTable.Series
	|
	|ORDER BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|";
	
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("CorrectedDocument", FillingData.CorrectedDocument);
	
	Result = Query.Execute().Unload();
	
	VTProducts_ = Goods.Unload();
	VTProducts_.Columns.Add("LineOverfilled", New TypeDescription("Boolean"));
	
	Var_Key = "Products, Characteristic, Purpose";
	
	Condition = "On [Count]";
	InvoicesServer.DistributeQuantityAndFill(Result, VTProducts_, "QuantityAfterChange", Var_Key, Condition, True, "LineOverfilled");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	RowsToProcess = New Array;
	
	For Each String In VTProducts_ Do
		If String.LineOverfilled Then
			String.Count = String.QuantityAfterChange;
			RowsToProcess.Add(String);
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		VTProducts_);
	
	InvoicesServer.DeleteEmptyLines(VTProducts_, "Count");
	
	Goods.Load(VTProducts_);
	
EndProcedure

Procedure FillInDocumentOnBasisOfContract(DocumentBasis,
												WarehouseForReceipt = Undefined,
												EconomicOperationOfAcceptance = Undefined,
												FillInUsingInvoice = False,
												FillByWarehouseDocument = False)
	
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
		|	Contract.LineOfBusiness AS LineOfBusiness
		|INTO TTOrder_
		|FROM
		|	Catalog.CounterpartyContracts AS Contract
		|WHERE
		|	Contract.Ref = &DocumentBasis
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow,
		|	GoodsToReceiveBalance.Products,
		|	GoodsToReceiveBalance.Characteristic,
		|	GoodsToReceiveBalance.Purpose,
		|	GoodsToReceiveBalance.Series,
		|	GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance AS Count,
		|	GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance AS NumberOfPackages
		|INTO TTProducts_1
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow = &DocumentBasis 
		|		AND CASE WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|			ELSE Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|	END) AS GoodsToReceiveBalance
		|WHERE
		|	NOT &FillInUsingInvoice
		|	AND NOT &FillByWarehouseDocument
		|	AND GoodsToReceiveBalance.ToRegisterReceiptsByReferenceBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow,
		|	GoodsToReceiveBalance.Products,
		|	GoodsToReceiveBalance.Characteristic,
		|	GoodsToReceiveBalance.Purpose,
		|	GoodsToReceiveBalance.Series,
		|	GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance AS Count,
		|	GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow = &DocumentBasis 
		|		AND CASE WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|			ELSE Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|	END) AS GoodsToReceiveBalance
		|WHERE
		|	NOT &FillInUsingInvoice
		|	AND &FillByWarehouseDocument
		|	AND GoodsToReceiveBalance.ToRegisterGoodsReceiptsBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsToReceiveBalance.DocumentInflow,
		|	GoodsToReceiveBalance.Products,
		|	GoodsToReceiveBalance.Characteristic,
		|	GoodsToReceiveBalance.Purpose,
		|	GoodsToReceiveBalance.Series,
		|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance AS Count,
		|	GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(,DocumentInflow = &DocumentBasis 
		|		AND CASE WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|			ELSE Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|	END) AS GoodsToReceiveBalance
		|WHERE
		|	&FillInUsingInvoice
		|	AND GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance > 0
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	TableReferenceOrder.Ref          AS Ref,
		|	TableReferenceOrder.Contract         AS Contract,
		|	TableReferenceOrder.Partner         AS Partner,
		|	TableReferenceOrder.Counterparty      AS Counterparty,
		|	TableReferenceOrder.Organization     AS Organization,
		|	TableReferenceOrder.DocumentStatus AS DocumentStatus,
		|	TableReferenceOrder.LineOfBusiness AS LineOfBusiness,
		|	TableReferenceOrder.TheseAreAgencyServices AS TheseAreAgencyServices,
		|	TableReferenceOrder.ThereAreErrorsStatus   AS ThereAreErrorsStatus
		|FROM
		|	TTOrder_ AS TableReferenceOrder
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	GoodsTable.DocumentInflow AS DocumentInflow,
		|	GoodsTable.Products        AS Products,
		|	GoodsTable.Characteristic      AS Characteristic,
		|	GoodsTable.Purpose          AS Purpose,
		|	GoodsTable.Series               AS Series,
		|	GoodsTable.Count          AS Count,
		|	GoodsTable.NumberOfPackages  AS NumberOfPackages
		|FROM
		|	TTProducts_1 AS GoodsTable
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	DocumentInflow");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("WarehouseForReceipt",  WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",       ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FillInUsingInvoice", FillInUsingInvoice = True);
	Query.SetParameter("FillByWarehouseDocument", FillByWarehouseDocument = True);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection		= QueryResult[2].Select();
	VTProducts_	= QueryResult[3].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Contract,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	Partner = Selection.Partner;
	FillInDefaultPurchaseConditions();
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
		EconomicOperationOfAcceptance,
		EconomicOperationOfAcceptanceActualReceipt);
	
	ReferenceOrder          = DocumentBasis;
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	If ValueIsFilled(WarehouseForReceipt) Then
		Warehouse = WarehouseForReceipt;
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	CompleteVATTaxation();
	
	Goods.Load(VTProducts_);
	
	RecalculateNumberOfPackagesFillInVATRate(True);
	FillThePricesByTermsOfSales();
	
EndProcedure

Procedure CompleteVATTaxation()
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

// Returns a temporary table with the document data.
// Used for filling in inventory types.
//
//	Parameters:
//		ForProductsFromPartners	- Boolean - Replaces the item accounting Analytics.
//		AccountingByCCDNumbers		- Boolean - Selection of nomenclature with the Keep records by CCD numbers attribute.
//
//	Returns:
//		TempTablesManager - manager of temporary tables with document data.
//
Function TemporaryDocumentDataTables(ForProductsFromPartners, AccountingByCCDNumbers = False)
	
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
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatusGoodsAtPartners = 18
	|			OR (TableOfGoods.BatchesIndicationStatusGoodsAtPartners = 0
	|				AND TableOfGoods.BatchesIndicationStatusInWarehouses = 14)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Package AS Package,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber
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
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	&TableTypesOfStocksAnalysisOfAccountingProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount
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
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
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
	|	&InventoryType AS InventoryType,
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
	|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|			OR InventoryKinds.InventoryType <> &InventoryType
	|			OR InventoryKinds.Organization <> &Organization
	|			OR &RefillInventoryKinds)";
	
	If ForProductsFromPartners Then
		
		QueryText = StrReplace(QueryText,
									"&TableOfProductsProductAccountingAnalytics",
									"TableOfGoods.ItemsLocationAttributesGoodsAtPartners");
		QueryText = StrReplace(QueryText,
									"&TableTypesOfStocksAnalysisOfAccountingProducts",
									"TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners");
		Query.SetParameter("InventoryType", TypeOfInventoryByBusinessTransaction());
	Else
		
		QueryText = StrReplace(QueryText,
									"&TableOfProductsProductAccountingAnalytics",
									"TableOfGoods.ItemsLocationAttributes");
		QueryText = StrReplace(QueryText,
									"&TableTypesOfStocksAnalysisOfAccountingProducts",
									"TableTypesOfStocks_.ItemsLocationAttributes");
		Query.SetParameter("InventoryType", Enums.InventoryTypes.EmptyRef());
	EndIf;
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
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
	Query.SetParameter("BusinessOperation", 	BusinessOperation);
	Query.SetParameter("Manager",               Manager);
	Query.SetParameter("Currency",                 Currency);
	Query.SetParameter("PriceKind",				VendorPriceKind);
	Query.SetParameter("Posted",				Posted);
	Query.SetParameter("AccountingByCCDNumbers",		AccountingByCCDNumbers);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsQuantityByGBRN_",
		"TableOfGoods",
		"QuantityByGBRN",
		"TableOfGoods.QuantityByGBRN",
		"0");
	
	TMCommonUse.ReplaceMissingValueTableFieldsInQueryText(
		TableOfGoods,
		Query.Text,
		"&FieldTextTableOfGoodsCCDNumber_",
		"TableOfGoods",
		"CCDNumber",
		"TableOfGoods.CCDNumber",
		"VALUE(Catalog.CCDNumbers.EmptyRef)");
	
	Query.Execute();
	
	Return Query.TempTablesManager;
	
EndFunction

Procedure FillInProductListFromPartners() Export
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity	= RowOfGoods.Count;
		AmountIncludingVAT			= RowOfGoods.AmountIncludingVAT;
		VATAmount			= RowOfGoods.VATAmount;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		TheStructureOfTheSearch.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributesGoodsAtPartners;
		
		FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
		
		For Each InventoryLine In FoundRows Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.ItemsLocationAttributesGoodsAtPartners = RowOfGoods.ItemsLocationAttributesGoodsAtPartners;
			NewRow.ItemsLocationAttributes = RowOfGoods.ItemsLocationAttributes;
			
			NewRow.WarehouseInventoryAttributes	= RowOfGoods.InventoryOwnerAttribute;
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If GoodsQuantity <> 0 Then
				NewRow.AmountIncludingVAT	= Count * AmountIncludingVAT / GoodsQuantity;
				NewRow.VATAmount	= Count * VATAmount / GoodsQuantity;
			EndIf;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			
			GoodsQuantity	= GoodsQuantity - NewRow.Count;
			AmountIncludingVAT			= AmountIncludingVAT - NewRow.AmountIncludingVAT;
			VATAmount			= VATAmount - NewRow.VATAmount;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	ManagerOfTemporaryTablesOwnProducts		= TemporaryDocumentDataTables(False);
	RefillInventoryKinds	= AdditionalProperties.Property("RefillInventoryKinds");
	
	InventoriesServer.FillStockTypesByDefault(ManagerOfTemporaryTablesOwnProducts, Goods);
	
	TempTablesManager = TemporaryDocumentDataTables(True);
	
	InventoryTypesAreOverfilled = False;
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or InventoriesServer.CheckChangesInGoodsByQuantityAndAmount(ManagerOfTemporaryTablesOwnProducts)
		Or InventoriesServer.CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Then
		
		// we allow you to write off the balances for empty GTD numbers.
		AdditionalProperties.Insert("MonitorCCDNumbers", False);
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, VATRate, CCDNumber",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
		InventoryTypesAreOverfilled = True;
		
	EndIf;
	
	If InventoryTypesAreOverfilled Then
		
		FillInProductListFromPartners();
		
		If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
			FillInCCDNumbers();
		EndIf;
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, ItemsLocationAttributesGoodsAtPartners,
		|LotVendorAttributes, InventoryOwnerAttribute, CCDNumber, VATRate, WarehouseInventoryAttributes",
		"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
	EndIf;
	
EndProcedure

Procedure ExtractDetailedFieldsFromAnalytics(DataTable)
	
	BasicAnalytics = "Products, Characteristic, Purpose";
	
	NomenclatureAnalysts = DataTable.UnloadColumn("ItemsLocationAttributes");
	DetailedAnalytics = Common.ObjectsAttributesValues(NomenclatureAnalysts, BasicAnalytics);
	
	DataTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DataTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
	DataTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	For Each String In DataTable Do
		KeyValue = DetailedAnalytics[String.ItemsLocationAttributes];
		FillPropertyValues(String, KeyValue);
	EndDo;
	
EndProcedure

Procedure FillInCCDNumbers()
	
	QueryText = 
	"SELECT DISTINCT
	|	CAST(SourceTable.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS
	|		ItemsLocationAttributes
	|INTO TTTypesOfStocks
	|FROM
	|	&SourceTable AS SourceTable
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CAST(SourceTable.ItemsLocationAttributes AS Catalog.InventoryLocationAttributeKeys) AS
	|		ItemsLocationAttributes,
	|	SourceTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	SourceTable.BatchesIndicationStatusGoodsAtPartners AS BatchesIndicationStatusGoodsAtPartners
	|INTO TTTableSeriesIndicationStatus
	|FROM
	|	&AdditionalTable AS SourceTable
	|INDEX BY
	|	ItemsLocationAttributes,
	|	BatchesIndicationStatus,
	|	BatchesIndicationStatusGoodsAtPartners
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SourceTable.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS SourceTable
	|		INNER JOIN TTTableSeriesIndicationStatus AS TableOfSeries
	|		ON SourceTable.ItemsLocationAttributes.Products = TableOfSeries.ItemsLocationAttributes.Products
	|WHERE
	|	SourceTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND SourceTable.ItemsLocationAttributes.Products.KeepRecordsByCCD
	|	AND TableOfSeries.BatchesIndicationStatus = 14
	|	AND TableOfSeries.BatchesIndicationStatusGoodsAtPartners = 0
	|INDEX BY
	|	ItemsLocationAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DimensionKey.Ref AS ItemsLocationAttributes
	|INTO TTSelectionOfOrganizationsProductsFromPartners
	|FROM
	|	TableTypesOfStocks_ AS GoodsTable
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKey
	|		ON DimensionKey.Products = GoodsTable.ItemsLocationAttributes.Products
	|			AND DimensionKey.Characteristic = GoodsTable.ItemsLocationAttributes.Characteristic
	|			AND DimensionKey.Purpose = GoodsTable.ItemsLocationAttributes.Purpose
	|			AND DimensionKey.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND DimensionKey.StorageLocation = GoodsTable.ItemsLocationAttributes.StorageLocation
	|INDEX BY
	|	ItemsLocationAttributes";

	If ValueIsFilled(ReferenceOrder) 
			And BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
		QueryText = QueryText + Common.QueryBatchSeparator() +
			"SELECT
			|	RegisterData.ItemsLocationAttributes.Products AS Products,
			|	RegisterData.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	RegisterData.ItemsLocationAttributes.Purpose AS Purpose,
			|	RegisterData.CCDNumber AS CCDNumber,
			|	SUM(RegisterData.Count) AS Count,
			|	SUM(RegisterData.QuantityByGBRN) AS QuantityByGBRN
			|INTO ttResult
			|FROM
			|	(SELECT
			|		CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		CompanyGoods.CCDNumber AS CCDNumber,
			|		SUM(CASE
			|				WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|					THEN 1
			|				ELSE -1
			|			END * CompanyGoods.Count) AS Count,
			|		SUM(CASE
			|				WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|					THEN 1
			|				ELSE -1
			|			END * CompanyGoods.QuantityByGBRN) AS QuantityByGBRN
			|	FROM
			|		AccumulationRegister.CompanyGoods AS CompanyGoods
			|	WHERE
			|		CompanyGoods.Period <= &DocumentDate
			|		AND (CompanyGoods.Recorder, TRUE) IN
			|				(SELECT
			|					GoodsToReceive.Recorder AS Recorder,
			|					TRUE
			|				FROM
			|					AccumulationRegister.GoodsToReceive AS GoodsToReceive
			|				WHERE
			|					GoodsToReceive.DocumentInflow = &ReferenceOrder)
			|		AND (CompanyGoods.ItemsLocationAttributes, TRUE) IN
			|				(SELECT
			|					Table_Selection.ItemsLocationAttributes,
			|					TRUE
			|				FROM
			|					TTSelectionOfOrganizationsProductsFromPartners AS Table_Selection)
			|		AND CompanyGoods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
			|	
			|	GROUP BY
			|		CompanyGoods.ItemsLocationAttributes,
			|		CompanyGoods.CCDNumber
			|	
			|	HAVING
			|		(SUM(CASE
			|					WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						THEN 1
			|					ELSE -1
			|				END * CompanyGoods.Count) > 0
			|			OR SUM(CASE
			|					WHEN CompanyGoods.RecordType = VALUE(AccumulationRecordType.Receipt)
			|						THEN 1
			|					ELSE -1
			|				END * CompanyGoods.QuantityByGBRN) > 0)
			|	
			|	UNION ALL
			|	
			|	SELECT
			|		CompanyGoods.ItemsLocationAttributes,
			|		CompanyGoods.CCDNumber,
			|		CompanyGoods.Count,
			|		CompanyGoods.QuantityByGBRN
			|	FROM
			|		AccumulationRegister.CompanyGoods AS CompanyGoods
			|			INNER JOIN TTSelectionOfOrganizationsProductsFromPartners AS GoodsTable
			|			ON CompanyGoods.ItemsLocationAttributes = GoodsTable.ItemsLocationAttributes
			|				AND (CompanyGoods.Recorder = &Recorder)
			|				AND (CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense))
			|				AND (CompanyGoods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef))) AS RegisterData
			|
			|GROUP BY
			|	RegisterData.ItemsLocationAttributes.Products,
			|	RegisterData.ItemsLocationAttributes.Characteristic,
			|	RegisterData.ItemsLocationAttributes.Purpose,
			|	RegisterData.CCDNumber
			|
			|HAVING
			|	(SUM(RegisterData.Count) <> 0
			|		OR SUM(RegisterData.QuantityByGBRN) <> 0)
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	CCDNumber";
		
	Else
		QueryText = QueryText + Common.QueryBatchSeparator() +
			"SELECT
			|	RegisterData.ItemsLocationAttributes.Products AS Products,
			|	RegisterData.ItemsLocationAttributes.Characteristic AS Characteristic,
			|	RegisterData.ItemsLocationAttributes.Purpose AS Purpose,
			|	RegisterData.CCDNumber AS CCDNumber,
			|	SUM(RegisterData.Count) AS Count,
			|	SUM(RegisterData.QuantityByGBRN) AS QuantityByGBRN
			|INTO ttResult
			|FROM (
			|	SELECT
			|		CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		CompanyGoods.CCDNumber AS CCDNumber,
			|		CompanyGoods.CountBalance AS Count,
			|		CompanyGoods.QuantityByGBRNBalance AS QuantityByGBRN
			|	FROM
			|		AccumulationRegister.CompanyGoods.Balance(&DocumentDate,
			|			(ItemsLocationAttributes) IN
			|			(SELECT
			|				Table_Selection.ItemsLocationAttributes
			|			FROM
			|				TTSelectionOfOrganizationsProductsFromPartners AS Table_Selection)
			|			AND CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)) AS CompanyGoods
			|	WHERE
			|		(CompanyGoods.CountBalance > 0
			|			OR CompanyGoods.QuantityByGBRNBalance > 0)
			|	
			|	UNION ALL
			|
			|	SELECT
			|		CompanyGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
			|		CompanyGoods.CCDNumber AS CCDNumber,
			|		CompanyGoods.Count AS Count,
			|		CompanyGoods.QuantityByGBRN AS QuantityByGBRN
			|	FROM
			|		AccumulationRegister.CompanyGoods AS CompanyGoods
			|			INNER JOIN TTSelectionOfOrganizationsProductsFromPartners AS GoodsTable
			|			ON CompanyGoods.ItemsLocationAttributes = GoodsTable.ItemsLocationAttributes
			|				AND CompanyGoods.Recorder = &Recorder
			|				AND CompanyGoods.RecordType = VALUE(AccumulationRecordType.Expense)
			|				AND CompanyGoods.CCDNumber <> VALUE(Catalog.CCDNumbers.EmptyRef)
			|) AS RegisterData
			|
			|GROUP BY
			|	RegisterData.ItemsLocationAttributes.Products,
			|	RegisterData.ItemsLocationAttributes.Characteristic,
			|	RegisterData.ItemsLocationAttributes.Purpose,
			|	RegisterData.CCDNumber
			|
			|HAVING
			|	SUM(RegisterData.Count) <> 0
			|	OR SUM(RegisterData.QuantityByGBRN) <> 0
			|
			|INDEX BY
			|	Products,
			|	Characteristic,
			|	Purpose,
			|	CCDNumber";
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() +
	"SELECT DISTINCT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose
	|FROM
	|	ttResult AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Count AS QuantityConsideringCCD,
	|	GoodsTable.Count AS NumberConsideringCCDIsSecondPass,
	|	GoodsTable.QuantityByGBRN AS NumberOfRNPTTakingIntoAccountCCD
	|FROM
	|	ttResult AS GoodsTable
	|";
	
	TypesOfStocksToFill = InventoryKinds.Unload();
	ProductsWithSeries = Goods.Unload();
	
	Query = New Query();
	
	Query.Text = QueryText;
	Query.SetParameter("SourceTable", TypesOfStocksToFill);
	Query.SetParameter("AdditionalTable", ProductsWithSeries);
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("DocumentDate", EndOfDay(Date));
	Query.SetParameter("ReferenceOrder", ReferenceOrder);

	Package = Query.ExecuteBatch();
	SampleAnalytics = Package[5].Select();
	SGTDKDistributionAnalytics = Package[6].Unload();
	
	ExtractDetailedFieldsFromAnalytics(TypesOfStocksToFill);

	While SampleAnalytics.Next() Do
		
		Filter = New Structure();
		Filter.Insert("Products", SampleAnalytics.Products);
		Filter.Insert("Characteristic", SampleAnalytics.Characteristic);
		Filter.Insert("Purpose", SampleAnalytics.Purpose);
		
		FoundRows = SGTDKDistributionAnalytics.FindRows(Filter);
		SGTDAnalysts = SGTDKDistributionAnalytics.Copy(FoundRows);

		FoundRowsTypesOfInventory = TypesOfStocksToFill.FindRows(Filter);
		TypesOfStocksByAnalytics = TypesOfStocksToFill.Copy(FoundRowsTypesOfInventory);
		TypesOfStocksByAnalytics.FillValues(Undefined, "CCDNumber");

		Var_Key = "Products, Characteristic, Purpose";
		
		// Distribution of the quantity and filling in the GTD number.
		Condition = "On [Count]";
		InvoicesServer.DistributeQuantityAndFill(SGTDAnalysts, TypesOfStocksByAnalytics, "QuantityConsideringCCD", Var_Key, Condition, False, "CCDNumber");
		
		// Distribution of quantity by RNPT.
		For Each SGTDString In SGTDAnalysts Do
			Filter = New Structure();
			Filter.Insert("Products", SGTDString.Products);
			Filter.Insert("Characteristic", SGTDString.Characteristic);
			Filter.Insert("Purpose", SGTDString.Purpose);
			Filter.Insert("CCDNumber", SGTDString.CCDNumber);
			
			FoundRows = TypesOfStocksByAnalytics.FindRows(Filter);
			ForAllocation = SGTDString.NumberOfRNPTTakingIntoAccountCCD;
			For Each String In FoundRows Do
				String.QuantityByGBRN = Round(ForAllocation * (String.QuantityConsideringCCD / SGTDString.NumberConsideringCCDIsSecondPass), 5);
			EndDo;
		EndDo;
		
		For Each String In FoundRowsTypesOfInventory Do
			TypesOfStocksToFill.Delete(String);
		EndDo;
		
		For IndexOf = 0 To TypesOfStocksByAnalytics.Count() - 1 Do
			String = TypesOfStocksByAnalytics[IndexOf];
			If String.Count > String.QuantityConsideringCCD Then
				Difference = String.Count - String.QuantityConsideringCCD;
				String.Count = String.QuantityConsideringCCD;
				
				// The Surplus Is Taken Into Account without a specific CCD Number, because which number came is not explicitly indicated.
				// So The Item Is Registered, but The CCD Number will Need to be set separately.
				// The Amount Of RNPT is Cleared, since it makes No Sense with An Empty CCD (RNPT).
				NewRow = TypesOfStocksByAnalytics.Add();
				FillPropertyValues(NewRow, String);
				NewRow.Count = Difference;
				NewRow.QuantityByGBRN = 0;
				NewRow.CCDNumber = Undefined;
			Else
				String.Count = String.QuantityConsideringCCD;
			EndIf;
		EndDo;
		CommonClientServer.SupplementTable(TypesOfStocksByAnalytics, TypesOfStocksToFill);
		
	EndDo;
	
	InventoryKinds.Load(TypesOfStocksToFill);
	
EndProcedure

Function ParametersForFillingInventoryTypes(AccountingByCCDNumbers = False)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	MonitorRemainsOfCCDNumbers = False;
	
	FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
	FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesByDefault();
	FillParameters.NameOfRemainderTable = "ProductsFromPartnersHavePositiveBalance";
	
	FillParameters.WithoutSelectionByCCDNumbers = True;
	If AccountingByCCDNumbers Then
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = Not MonitorRemainsOfCCDNumbers;
	Else
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
	EndIf;
	
	FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
	FillParameters.SelectionOfStockTypes_.InventoryType.Add(TypeOfInventoryByBusinessTransaction());
	FillParameters.SelectionOfStockTypes_.Organization = Organization;
	FillParameters.SelectionOfStockTypes_.PriceKind = VendorPriceKind;
	
	FillParameters.ReversedDocument = ReversedDocument;
	
	Return FillParameters;
	
EndFunction

Function TableOfDetailsOfStockTypesByDefault()
	
	TableOfDetailsOfStockTypesByDefault = Goods.Unload(, "LineNumber, ItemsLocationAttributes"); // ValueTable
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
	
	Return TableOfDetailsOfStockTypesByDefault;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Warehouse, Contract, BusinessOperation, Counterparty";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReceiptOfGoodsToWarehouse.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ReceiptOfGoodsToWarehouse.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	MainBusinessTransaction = PurchasesServer.MainEconomicOperationOfSeparatePurchase(BusinessOperation);
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(MainBusinessTransaction,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
		
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatus";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
	PlacesOfRegistrationWithPartners = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																					Contract,
																					Department,
																					Partner,
																					Contract);
	
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesGoodsAtPartners";
	
	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
		
		FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusGoodsAtPartners";
		
	Else
		// The non-invoicing operation reports the series to the Acquisition by moving the series as in a warehouse.
		FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatus";
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfRegistrationWithPartners, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Function TypeOfInventoryByBusinessTransaction()

	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportReceiptFromGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit Then
		
		Return Enums.InventoryTypes.OwnGoodsInTransit;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery Then
		
		Return Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery;
		
	Else
		Return Enums.InventoryTypes.EmptyRef();
	EndIf;
	
EndFunction

Procedure FillInSummaryIndicatorsOfProductLine(RowOfGoods)
	
	ActionsWithString = New Structure;
	
	If ValueIsFilled(RowOfGoods.Price) Then
		ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		ActionsWithString.Insert("RecalculateAmount",		"NumberOfPackages");
		ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
		ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	EndIf;
	
	If Not ValueIsFilled(RowOfGoods.VATRate) Then
		ActionsWithString.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	EndIf;
	
	If ValueIsFilled(ActionsWithString) Then
		BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, ActionsWithString, Undefined);
	EndIf;
	
EndProcedure

Procedure RecalculateNumberOfPackagesFillInVATRate(FillInVATRate = False)
	
	StructureOfActions = New Structure("RecalculateNumberOfPackages",
										BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	If FillInVATRate Then
		StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	
EndProcedure

Procedure FillThePricesByTermsOfSales(FillInAllLines = True)
	
	LinesWithoutPrices = Undefined;
	
	If Not FillInAllLines Then
		LinesWithoutPrices = New Array;
		
		For Each TSRow In Goods Do
			If Not ValueIsFilled(TSRow.Price) Then
				LinesWithoutPrices.Add(TSRow);
			EndIf;
		EndDo;
	EndIf;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("PopulationFields",		"Price, VATRate");
	FillParameters.Insert("Date",				Date);
	FillParameters.Insert("Currency",				Currency);
	FillParameters.Insert("Terms",			Terms);
	FillParameters.Insert("VendorPriceKind",	VendorPriceKind);
	FillParameters.Insert("VATTaxation",	VATTaxation);
	
	ActionsWithStrings = New Structure;
	ActionsWithStrings.Insert("RecalculateAmount",		"NumberOfPackages");
	ActionsWithStrings.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
	
	PartnerPricesFillingServer.FillInPrices(Goods, LinesWithoutPrices, FillParameters, ActionsWithStrings);
	
EndProcedure

Procedure CollapseProductLines()
	
	OperationGoodsInTransit = Documents.ReceiptOfGoodsToWarehouse.ThisIsReceiptOfGoodsInTransit(BusinessOperation);
	
	If OperationGoodsInTransit Then
		GroupColumns	= "Products, PartnerProducts, Characteristic, Purpose, Series, Package";
		TotalingColumns	= "Count, NumberOfPackages";
	Else
		GroupColumns	= "Products, PartnerProducts, Characteristic, Purpose, Series, Package, Price, VATRate";
		TotalingColumns	= "Count, NumberOfPackages, Sum, VATAmount, AmountIncludingVAT";
	EndIf;
	
	Goods.GroupBy(GroupColumns, TotalingColumns);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
