#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the return of goods to the supplier
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	
	PriceIncludesVAT      = PurchaseConditions.PriceIncludesVAT;
	ReturnOfReceivedReusablePackages = PurchaseConditions.ReturnReusablePackage;
	DepositForPackageIsRequired = PurchaseConditions.PackageDepositIsRequired;
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Organization Then
		Organization = PurchaseConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse = PurchaseConditions.Warehouse;
	EndIf;
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(PurchaseConditions.BusinessOperation);
	
	BusinessOperationsOfTheContract = New Array;
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.PurchaseByImport);
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		BusinessOperationsOfTheContract.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		Contract = PurchasesServer.GetDefaultContract(ThisObject, BusinessOperationsOfTheContract, AddlParameters);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
			Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
EndProcedure

// Fills in the default purchase conditions in the return of goods to the supplier
//
Procedure FillInDefaultPurchaseConditions() Export
	
	If ValueIsFilled(Terms) Then
		Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
	EndIf;
	
	If ValueIsFilled (Partner) Then
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner);
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				FillParameters = Documents.ReturnOfGoodsToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
				VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
				
			Else
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
				
		Else
			TheCounterpartyPriorToTheChange = Counterparty;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			Terms = Undefined;
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount);
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25() Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
EndProcedure

// Fills in the terms of sales under the agreement in the return of goods to the supplier
//
Procedure FillInTermsOfPurchaseUnderAgreement() Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	
	FillParameters = Documents.ReturnOfGoodsToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	TheCounterpartyPriorToTheChange = Counterparty;
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25() Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
EndProcedure

// Generates temporary document data
//
// Parameters:
//  AccordingToReceiptDocument  - Boolean, Undefined - Selection by the corresponding field of the Goods tabular part.
// 
// Returns:
//  TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables(AccordingToReceiptDocument = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Warehouse AS Warehouse,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END AS SalesOpportunity,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToConsignor)
	|			THEN VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END AS QuantityByGBRN,
	|	TableOfGoods.DocumentInflow AS DocumentInflow,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.Warehouse AS Warehouse
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count,
	|	TableOfGoods.QuantityByGBRN,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.DocumentInflow,
	|	CASE
	|		WHEN TableOfGoods.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableOfGoods.DocumentInflow
	|	END AS DocumentTransfers_,
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.Price,
	|	TableOfGoods.AmountIncludingVAT,
	|	TableOfGoods.VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	TRUE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|WHERE
	|	&FilterDocumentInflow
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.DocumentInflow AS DocumentInflow,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount
	|INTO InitialTypesOfStocks
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
	|	TableTypesOfStocks_.DocumentInflow AS DocumentInflow,
	|	CASE
	|		WHEN TableTypesOfStocks_.DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.DocumentInflow
	|	END AS DocumentTransfers_,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	&Warehouse AS Warehouse,
	|	&SalesOpportunity AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	InitialTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&FilterDocumentInflow
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("Currency", Currency);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	
	If AccordingToReceiptDocument = Undefined Then
		Query.Text = StrReplace(Query.Text, "&FilterDocumentInflow", "TRUE");
	ElsIf AccordingToReceiptDocument Then
		FilterDocumentInflow = "DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)";
		Query.Text = StrReplace(Query.Text, "&FilterDocumentInflow", FilterDocumentInflow);
	ElsIf Not AccordingToReceiptDocument Then
		FilterDocumentInflow = "DocumentInflow = VALUE(Document.VendorInvoice.EmptyRef)";
		Query.Text = StrReplace(Query.Text, "&FilterDocumentInflow", FilterDocumentInflow);
	EndIf;
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
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
	
	Return TempTablesManager;
	
EndFunction

// Returns the amount of the document including multi-sided containers
//
// Returns:
//  Number - The amount of the document
//
Function GetDocumentAmount() Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.AmountIncludingVAT),0) AS AmountIncludingVAT
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage
	|	OR &DepositForPackageIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	Query.SetParameter("ToReturnReusablePackage", ReturnOfReceivedReusablePackages);
	Query.SetParameter("DepositForPackageIsRequired", DepositForPackageIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReturnOfGoodsToVendor - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ReturnOfGoodsToVendor.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
	If DocumentTables <> Undefined Then
		FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables);
		AdditionalProperties.Insert("TablesOfFillingOfTypesOfStocksAtExchange", DocumentTables);
	EndIf;
	
	FillStockTypes(Cancel);
	AdditionalProperties.Delete("TablesOfFillingOfTypesOfStocksAtExchange");
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)

	FillInDataType = TypeOf(FillingData);
		
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("Basis")
				And TypeOf(FillingData.Basis) = Type("DocumentRef.GoodsQualityControlCertificate") Then
			FillInCertificateOfQualityControl(FillingData);
		ElsIf FillingData.Property("FillInAcceptedContainer") Then
			FillOutDocumentOnBasisOfAcceptedContainer(FillingData);
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
				FillOutOnBasisOfActOfDiscrepancyOnReturnToSupplier(FillingData);
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.VendorInvoice") Then
				FillOutOnBasisOfActOfDiscrepancyOnAdmission(FillingData);
			EndIf;
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then
		FillInDocumentBasedOnReceiptOfGoodsAndServices(FillingData);
	EndIf;
	
	FillOutBankAccounts();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ReturnOfGoodsToVendorLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or
		 Not Documents.ReturnOfGoodsToVendor.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	DonTCheckAmountDetails = (BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor);
	
	If DonTCheckAmountDetails Then
		
		NotCheckedAttributeArray.Add("Goods.Price");
		NotCheckedAttributeArray.Add("Goods.Sum");
		NotCheckedAttributeArray.Add("Goods.VATRate");
		NotCheckedAttributeArray.Add("Goods.VATAmount");
		NotCheckedAttributeArray.Add("ARAPDetails.Sum");
		
	EndIf;

	CashServer.CheckCompletionOfPaymentDecryption(
		ThisObject,
		GetDocumentAmount(),
		BusinessOperation,
		Cancel);
		
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsToVendor),
												Cancel,
												NotCheckedAttributeArray);
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	PurchasesServer.CheckCorrectnessOfReturnedProducts(ThisObject, Cancel);
		
	ReturnOfGoodsToVendorLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	AdditionalProperties.Insert("DisableProductControlForIssuingReportsToPurchasingCommittee", True);
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	If Not ReturnOfReceivedReusablePackages
		And DepositForPackageIsRequired Then
		DepositForPackageIsRequired = False;
	EndIf;
	
	DocumentAmount = GetDocumentAmount();
	
	ProductsServer.ClearUnusedSeries(ThisObject,
															ProductsServer.SeriesSpecificationParameters(ThisObject,
															Documents.ReturnOfGoodsToVendor));
															
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	ReturnOfGoodsToVendorLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReturnOfGoodsToVendorLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReturnOfGoodsToVendorLocalization.UndoPosting(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	RegistrationParameters = Documents.ReturnOfGoodsToVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	InitializeDocument();
	
	InventoryKinds.Clear();
	SetOfSeries.Clear();
	
	PaymentID = Undefined;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	ReturnOfGoodsToVendorLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReturnOfGoodsToVendorLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultPurchaseConditions();
		
	EndIf;

EndProcedure

Procedure FillInDocumentBasedOnReceiptOfGoodsAndServices(Val DocumentBasis)
	
	Query = New Query(
		"SELECT DISTINCT
		|	GoodsTable.ARAPObject AS ARAPObject
		|INTO ARAPObjects
		|FROM
		|	Document.VendorInvoice.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorInvoice.Ref AS DocumentInflow,
		|	VendorInvoice.Partner AS Partner,
		|	VendorInvoice.Counterparty AS Counterparty,
		|	CASE
		|		WHEN VendorInvoice.Currency = VendorInvoice.Contract.ARAPCurrency
		|			THEN VendorInvoice.Contract
		|		ELSE VALUE(Catalog.CounterpartyContracts.EmptyRef)
		|	END AS Contract,
		|	VendorInvoice.Terms AS Terms,
		|	VendorInvoice.Organization AS Organization,
		|	VendorInvoice.CompanyBankAccount AS CompanyBankAccount,
		|	VendorInvoice.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	VendorInvoice.Shipper AS GoodsRecipient,
		|	VendorInvoice.ShipperBankAccount AS GoodsRecipientBankAccount,
		|	VendorInvoice.Department AS Department,
		|	VendorInvoice.SalesOpportunity AS SalesOpportunity,
		|	CASE
		|		WHEN VendorInvoice.Warehouse.IsFolder
		|				AND VendorInvoice.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE VendorInvoice.Warehouse
		|	END AS Warehouse,
		|	VendorInvoice.Currency AS Currency,
		|	VendorInvoice.ARAPCurrency AS ARAPCurrency,
		|	VendorInvoice.DocumentAmount AS DocumentAmount,
		|	VendorInvoice.AmountARAP AS AmountARAP,
		|	VendorInvoice.Manager AS Manager,
		|	VendorInvoice.PurchaseOrder AS PurchaseOrder,
		|	VendorInvoice.AdvanceHolder AS AdvanceHolder,
		|	VendorInvoice.PriceIncludesVAT AS PriceIncludesVAT,
		|	VendorInvoice.VATTaxation AS VATTaxation,
		|	VendorInvoice.BusinessOperation AS BusinessOperation,
		|	VendorInvoice.ToReturnReusablePackage AS ReturnOfReceivedReusablePackages,
		|	VendorInvoice.PackageDepositIsRequired AS DepositForPackageIsRequired,
		|	NOT VendorInvoice.Posted AS ThereAreErrorsPosted,
		|	VendorInvoice.LineOfBusiness AS LineOfBusiness,
		|	VendorInvoice.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	VendorInvoice.FinancialAccountingGroup AS FinancialAccountingGroup
		|FROM
		|	Document.VendorInvoice AS VendorInvoice
		|WHERE
		|	VendorInvoice.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
		|	VendorsARAPAccounting.Currency AS ARAPCurrency,
		|	-ISNULL(VendorsARAPAccounting.SumBalance, 0) AS SumBalance
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Balance(, ARAPObject IN
		|		(SELECT
		|			ARAPObject
		|		FROM
		|			ARAPObjects)) AS VendorsARAPAccounting
		|
		|ORDER BY
		|	VendorsARAPAccounting.ARAPObject.Date
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	PurchaseAdjustment.Ref AS Ref
		|INTO LastAdjustmentData
		|FROM
		|	Document.PurchaseAdjustment AS PurchaseAdjustment
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON PurchaseAdjustment.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|		AND RegisterOfDocumentsStornoCorrection.Posted
		|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	PurchaseAdjustment.Posted
		|	AND PurchaseAdjustment.DocumentBasis = &DocumentBasis
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|
		|ORDER BY
		|	PurchaseAdjustment.PointInTime DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsTable.LineNumber,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.PartnerProducts AS PartnerProducts,
		|	GoodsTable.Products.ItemsType AS ItemsType,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Price AS Price,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.Sum AS Sum,
		|	GoodsTable.VATRate AS VATRate,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.Warehouse AS Warehouse,
		|	0 AS ManualDiscount
		|INTO GoodsOfReceiptDocument
		|FROM
		|	Document.PurchaseAdjustment.Goods AS GoodsTable
		|		INNER JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON GoodsTable.Ref = LastAdjustmentData.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber,
		|	GoodsTable.Products,
		|	GoodsTable.PartnerProducts,
		|	GoodsTable.Products.ItemsType,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.Series,
		|	GoodsTable.Package,
		|	GoodsTable.NumberOfPackages,
		|	GoodsTable.Price,
		|	GoodsTable.Count,
		|	GoodsTable.Sum,
		|	GoodsTable.VATRate,
		|	GoodsTable.VATAmount,
		|	GoodsTable.AmountIncludingVAT,
		|	GoodsTable.RowCode,
		|	GoodsTable.Warehouse,
		|	GoodsTable.ManualDiscount
		|FROM
		|	Document.VendorInvoice.Goods AS GoodsTable
		|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON TRUE
		|WHERE
		|	LastAdjustmentData.Ref IS NULL
		|	AND GoodsTable.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsOfReceiptDocument.PartnerProducts,
		|	GoodsOfReceiptDocument.Products AS Products,
		|	GoodsOfReceiptDocument.ItemsType AS ItemsType,
		|	GoodsOfReceiptDocument.Characteristic AS Characteristic,
		|	GoodsOfReceiptDocument.Purpose AS Purpose,
		|	GoodsOfReceiptDocument.Series AS Series,
		|	GoodsOfReceiptDocument.Package AS Package,
		|	SUM(GoodsOfReceiptDocument.NumberOfPackages) AS NumberOfPackages,
		|	AVG(GoodsOfReceiptDocument.Price) AS Price,
		|	SUM(GoodsOfReceiptDocument.Count) AS Count,
		|	SUM(GoodsOfReceiptDocument.Sum) AS Sum,
		|	GoodsOfReceiptDocument.VATRate AS VATRate,
		|	SUM(GoodsOfReceiptDocument.VATAmount) AS VATAmount,
		|	SUM(GoodsOfReceiptDocument.AmountIncludingVAT) AS AmountIncludingVAT,
		|	SUM(GoodsOfReceiptDocument.ManualDiscount) AS ManualDiscount,
		|	MIN(GoodsOfReceiptDocument.LineNumber) AS LineNumber,
		|	GoodsOfReceiptDocument.Warehouse AS Warehouse
		|INTO GoodsReceipts
		|FROM
		|	GoodsOfReceiptDocument AS GoodsOfReceiptDocument
		|GROUP BY
		|	GoodsOfReceiptDocument.PartnerProducts,
		|	GoodsOfReceiptDocument.Products,
		|	GoodsOfReceiptDocument.ItemsType,
		|	GoodsOfReceiptDocument.Characteristic,
		|	GoodsOfReceiptDocument.Purpose,
		|	GoodsOfReceiptDocument.Series,
		|	GoodsOfReceiptDocument.Package,
		|	GoodsOfReceiptDocument.VATRate,
		|	GoodsOfReceiptDocument.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReturnOfGoodsToSupplier.PartnerProducts,
		|	ReturnOfGoodsToSupplier.Products,
		|	ReturnOfGoodsToSupplier.Products.ItemsType AS ItemsType,
		|	ReturnOfGoodsToSupplier.Characteristic,
		|	ReturnOfGoodsToSupplier.Purpose,
		|	ReturnOfGoodsToSupplier.Series,
		|	ReturnOfGoodsToSupplier.Package,
		|	SUM(ReturnOfGoodsToSupplier.NumberOfPackages) AS NumberOfPackages,
		|	SUM(ReturnOfGoodsToSupplier.Count) AS Count,
		|	AVG(ReturnOfGoodsToSupplier.Price) AS Price,
		|	SUM(ReturnOfGoodsToSupplier.Sum) AS Sum,
		|	ReturnOfGoodsToSupplier.VATRate,
		|	SUM(ReturnOfGoodsToSupplier.VATAmount) AS VATAmount,
		|	SUM(ReturnOfGoodsToSupplier.AmountIncludingVAT) AS AmountIncludingVAT,
		|	ReturnOfGoodsToSupplier.Warehouse AS Warehouse
		|INTO ReturnItems
		|FROM
		|	Document.ReturnOfGoodsToVendor.Goods AS ReturnOfGoodsToSupplier
		|		LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStornoCorrection
		|		ON ReturnOfGoodsToSupplier.Ref = RegisterOfDocumentsStornoCorrection.ReversedDocument
		|		AND RegisterOfDocumentsStornoCorrection.Posted
		|		AND NOT RegisterOfDocumentsStornoCorrection.AdditionalRecord
		|WHERE
		|	ReturnOfGoodsToSupplier.DocumentInflow = &DocumentBasis
		|	AND ReturnOfGoodsToSupplier.Ref.Posted
		|	AND RegisterOfDocumentsStornoCorrection.Ref IS NULL
		|GROUP BY
		|	ReturnOfGoodsToSupplier.PartnerProducts,
		|	ReturnOfGoodsToSupplier.Products,
		|	ReturnOfGoodsToSupplier.Products.ItemsType,
		|	ReturnOfGoodsToSupplier.Characteristic,
		|	ReturnOfGoodsToSupplier.Purpose,
		|	ReturnOfGoodsToSupplier.Series,
		|	ReturnOfGoodsToSupplier.Package,
		|	ReturnOfGoodsToSupplier.VATRate,
		|	ReturnOfGoodsToSupplier.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(GoodsReceipts.PartnerProducts, ReturnItems.PartnerProducts) AS PartnerProducts,
		|	ISNULL(GoodsReceipts.Products, ReturnItems.Products) AS Products,
		|	ISNULL(GoodsReceipts.Characteristic, ReturnItems.Characteristic) AS Characteristic,
		|	ISNULL(GoodsReceipts.Purpose, ReturnItems.Purpose) AS Purpose,
		|	ISNULL(GoodsReceipts.Series, ReturnItems.Series) AS Series,
		|	ISNULL(GoodsReceipts.Package, ReturnItems.Package) AS Package,
		|	0 AS NumberOfPackages,
		|	ISNULL(GoodsReceipts.Count, 0) - ISNULL(ReturnItems.Count, 0) AS Count,
		|	ISNULL(GoodsReceipts.Sum, 0) - ISNULL(ReturnItems.Sum, 0) AS Sum,
		|	ISNULL(GoodsReceipts.VATRate, ReturnItems.VATRate) AS VATRate,
		|	ISNULL(GoodsReceipts.VATAmount, 0) - ISNULL(ReturnItems.VATAmount, 0) AS VATAmount,
		|	ISNULL(GoodsReceipts.AmountIncludingVAT, 0) - ISNULL(ReturnItems.AmountIncludingVAT, 0) AS AmountIncludingVAT,
		|	ISNULL(GoodsReceipts.Products.ItemsType, ReturnItems.Products.ItemsType) AS
		|		ItemsType,
		|	&DocumentBasis AS DocumentInflow,
		|	ISNULL(GoodsReceipts.LineNumber, 0) AS LineNumber,
		|	ISNULL(GoodsReceipts.Warehouse, ReturnItems.Warehouse) AS Warehouse
		|INTO GoodsTable
		|FROM
		|	GoodsReceipts AS GoodsReceipts
		|		FULL JOIN ReturnItems AS ReturnItems
		|		ON GoodsReceipts.Products = ReturnItems.Products
		|		AND GoodsReceipts.PartnerProducts = ReturnItems.PartnerProducts
		|		AND GoodsReceipts.Characteristic = ReturnItems.Characteristic
		|		AND GoodsReceipts.Series = ReturnItems.Series
		|		AND GoodsReceipts.Purpose = ReturnItems.Purpose
		|		AND GoodsReceipts.Package = ReturnItems.Package
		|		AND GoodsReceipts.Warehouse = ReturnItems.Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.PartnerProducts AS PartnerProducts,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Package AS Package,
		|	Goods.NumberOfPackages AS NumberOfPackages,
		|	Goods.Count AS Count,
		|	Goods.Sum AS Sum,
		|	Goods.VATRate AS VATRate,
		|	Goods.VATAmount AS VATAmount,
		|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
		|	Goods.ItemsType AS ItemsType,
		|	Goods.DocumentInflow AS DocumentInflow,
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Warehouse AS Warehouse
		|FROM
		|	GoodsTable AS Goods
		|WHERE
		|	Goods.Count > 0
		|
		|ORDER BY
		|	LineNumber,
		|	PartnerProducts,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	Series,
		|	Package
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.ItemsType AS ItemsType,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.VATRate AS VATRate,
		|	Goods.Count AS Count,
		|	Goods.Sum AS Sum,
		|	Goods.VATAmount AS VATAmount,
		|	Goods.AmountIncludingVAT AS AmountIncludingVAT
		|FROM
		|	GoodsTable AS Goods
		|WHERE
		|	Goods.Count < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ReceivedReturnablePackagingBalance.Products AS Products,
		|	ReceivedReturnablePackagingBalance.Characteristic AS Characteristic,
		|	ReceivedReturnablePackagingBalance.Partner AS Partner,
		|	ReceivedReturnablePackagingBalance.DocumentInflow AS DocumentInflow,
		|	ReceivedReturnablePackagingBalance.CountBalance AS Count,
		|	ReceivedReturnablePackagingBalance.SumBalance AS Sum
		|INTO TTAcceptedReturnPackaging
		|FROM
		|	AccumulationRegister.ReceivedReturnablePackaging.Balance(, DocumentInflow = &DocumentBasis) AS
		|		ReceivedReturnablePackagingBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTAcceptedReturnPackaging.Products AS Products,
		|	TTAcceptedReturnPackaging.Characteristic AS Characteristic,
		|	SUM(TTAcceptedReturnPackaging.Count) AS Count,
		|	SUM(TTAcceptedReturnPackaging.Count) AS NumberOfPackages,
		|	SUM(TTAcceptedReturnPackaging.Sum) AS Sum,
		|	SUM(TTAcceptedReturnPackaging.Sum) AS AmountIncludingVAT,
		|	CASE
		|		WHEN SUM(TTAcceptedReturnPackaging.Count) = 0
		|			THEN SUM(TTAcceptedReturnPackaging.Sum)
		|		ELSE SUM(TTAcceptedReturnPackaging.Sum) / SUM(TTAcceptedReturnPackaging.Count)
		|	END AS Price,
		|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
		|	TTAcceptedReturnPackaging.DocumentInflow AS DocumentInflow
		|FROM
		|	TTAcceptedReturnPackaging AS TTAcceptedReturnPackaging
		|GROUP BY
		|	TTAcceptedReturnPackaging.Products,
		|	TTAcceptedReturnPackaging.Characteristic,
		|	TTAcceptedReturnPackaging.DocumentInflow,
		|	VALUE(Catalog.VATRates.EXCLUDINGVAT)
		|HAVING
		|	SUM(TTAcceptedReturnPackaging.Count) > 0
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	DocumentInflow");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[1].Select();
	SamplingBaseCalculations = QueryBatch[2].Select();
	
	HeaderSelection.Next();
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		DocumentBasis,
		,
		HeaderSelection.ThereAreErrorsPosted);
		
	FillPropertyValues(ThisObject, HeaderSelection);
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(HeaderSelection.BusinessOperation);
	
	TableOfGoods = QueryBatch[8].Unload();
	SamplingToDistribution = QueryBatch[9].Select();
	TheStructureOfTheSearch = New Structure("Products, Warehouse, Characteristic,
			|Series, Purpose, ItemsType, VATRate");
	
	While SamplingToDistribution.Next() Do
		
		Count = -SamplingToDistribution.Count;
		Sum      = -SamplingToDistribution.Sum;
		VATAmount   = -SamplingToDistribution.VATAmount;
		AmountIncludingVAT  = -SamplingToDistribution.AmountIncludingVAT;
		
		FillPropertyValues(TheStructureOfTheSearch, SamplingToDistribution);
		PurchaseLines = TableOfGoods.FindRows(TheStructureOfTheSearch);
		
		For Each PurchaseLine In PurchaseLines Do
			
			If PurchaseLine.Count <= 0 Then
				Continue;
			EndIf;
			
			If Count > PurchaseLine.Count Then
				AmountToDeduct 	= PurchaseLine.Count;
				AmountToDeduct_ 		= PurchaseLine.Sum;
				AmountOfVATDeducted 	= PurchaseLine.VATAmount;
				AmountWithVATDeductible 	= PurchaseLine.AmountIncludingVAT;
			Else
				AmountToDeduct 	= Count;
				AmountToDeduct_ 		= Sum;
				AmountOfVATDeducted 	= VATAmount;
				AmountWithVATDeductible 	= AmountIncludingVAT;
			EndIf;
			
			PurchaseLine.Count 	= PurchaseLine.Count - AmountToDeduct;
			Count 					= Count - AmountToDeduct;
			
			PurchaseLine.Sum 		= PurchaseLine.Sum - AmountToDeduct_;
			Sum 						= Sum - AmountToDeduct_;
			
			PurchaseLine.VATAmount 		= PurchaseLine.VATAmount - AmountOfVATDeducted;
			VATAmount 					= VATAmount - AmountOfVATDeducted;
			
			PurchaseLine.AmountIncludingVAT 	= PurchaseLine.AmountIncludingVAT - AmountWithVATDeductible;
			AmountIncludingVAT 					= AmountIncludingVAT - AmountWithVATDeductible;
			
			If Count <= 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	ArrayOfRowsToDelete_1 = New Array();
	For Each String In TableOfGoods Do 
		If String.Count <= 0 Then
			ArrayOfRowsToDelete_1.Add(String);
		EndIf;
	EndDo;
	For Each String In ArrayOfRowsToDelete_1 Do
		TableOfGoods.Delete(String);
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(TableOfGoods, StructureOfActions);
		
	For Each CurRow In TableOfGoods Do
		
		If CurRow.ItemsType = Enums.ItemsTypes.OwnGoods
			Or (CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage And Not HeaderSelection.ReturnOfReceivedReusablePackages) Then
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow,CurRow);
			
			If VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer Then
				PriceManagementSystem.RecalculateAmountsInRowWithVAT(
					NewRow, 
					True,
					False,
					False,
					True);
				For Each TSRow In Goods Do
					TSRow.VATAmount = 0;
				EndDo;
			Else
				PriceManagementSystem.RecalculateAmountsInRowWithVAT(
					NewRow, 
					HeaderSelection.PriceIncludesVAT,
					False,
					False,
					True);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	PackageTable = QueryBatch[11].Unload();
	
	For Each CurrentRow In PackageTable Do
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurrentRow);
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(NewRow, HeaderSelection.PriceIncludesVAT, False, False, True);
		
	EndDo;
	
	DistributeCalculationsOnGrounds(SamplingBaseCalculations);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsToVendor);
	ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure FillOutOnBasisOfActOfDiscrepancyOnReturnToSupplier(Val FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|
	|SELECT
	|	DiscrepancyReportFollowingShipment.Ref                       AS DiscrepancyCertificate,
	|	ReturnOfGoodsToVendor.Ref                            AS Ref,
	|	ReturnOfGoodsToVendor.Terms                        AS Terms,
	|	ReturnOfGoodsToVendor.Organization                       AS Organization,
	|	ReturnOfGoodsToVendor.Partner                           AS Partner,
	|	ReturnOfGoodsToVendor.Counterparty                        AS Counterparty,
	|	ReturnOfGoodsToVendor.Currency                            AS Currency,
	|	ReturnOfGoodsToVendor.SalesOpportunity                            AS SalesOpportunity,
	|	ReturnOfGoodsToVendor.Department                     AS Department,
	|	ReturnOfGoodsToVendor.Warehouse                             AS Warehouse,
	|	ReturnOfGoodsToVendor.BusinessOperation             AS BusinessOperation,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT                   AS PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.VATTaxation                AS VATTaxation,
	|	ReturnOfGoodsToVendor.Contract                           AS Contract,
	|	ReturnOfGoodsToVendor.ReturnOfReceivedReusablePackages AS ReturnOfReceivedReusablePackages,
	|	ReturnOfGoodsToVendor.DepositForPackageIsRequired           AS DepositForPackageIsRequired,
	|	NOT ReturnOfGoodsToVendor.Posted                       AS ThereAreErrorsPosted,
	|	NOT DiscrepancyReportFollowingShipment.Posted                  AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingShipment.Status                       AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingShipment.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|		ON (TRUE)
	|WHERE
	|	ReturnOfGoodsToVendor.Ref = &DocumentBasis
	|	AND DiscrepancyReportFollowingShipment.Ref = &DiscrepancyCertificate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow AS DocumentInflow,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count) AS Count,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum) AS Sum,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount) AS VATAmount,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages > 0
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.DocumentInflow,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.LineNumber,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse
	|
	|ORDER BY
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose AS Purpose,
	|	SUM(-DiscrepancyReportFollowingShipmentSetOfSeries.Count + DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS Count,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse AS Warehouse
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &DocumentBasis
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument - DiscrepancyReportFollowingShipmentSetOfSeries.Count > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse");
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// On return to the supplier
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		,
		HeaderSelection.ThereAreErrorsPosted,
		,
		);
		
	// According to the act of discrepancies
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
	
	FillPropertyValues(ThisObject, HeaderSelection);
	AdditionalReturnWithinGoodsReturn = FillingData.BasisOfAct;
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
			
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		PriceManagementSystem.RecalculateAmountsInRow(
			NewRow,
			False,
			False,
			False,
			HeaderSelection.PriceIncludesVAT);
		
	EndDo;
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure FillOutOnBasisOfActOfDiscrepancyOnAdmission(Val FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Ref AS DiscrepancyCertificate,
	|	DiscrepancyReportFollowingReceipt.Organization AS Organization,
	|	DiscrepancyReportFollowingReceipt.Partner AS Partner,
	|	DiscrepancyReportFollowingReceipt.Counterparty AS Counterparty,
	|	DiscrepancyReportFollowingReceipt.Terms AS Terms,
	|	DiscrepancyReportFollowingReceipt.Department AS Department,
	|	DiscrepancyReportFollowingReceipt.Currency AS Currency,
	|	&Warehouse AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.PriceIncludesVAT AS PriceIncludesVAT,
	|	DiscrepancyReportFollowingReceipt.BusinessOperation AS BusinessOperation,
	|	DiscrepancyReportFollowingReceipt.Manager AS Manager,
	|	DiscrepancyReportFollowingReceipt.ContactPerson AS ContactPerson,
	|	DiscrepancyReportFollowingReceipt.VATTaxation AS VATTaxation,
	|	VendorInvoice.Ref AS DocumentInflow,
	|	VendorInvoice.CompanyBankAccount AS CompanyBankAccount,
	|	VendorInvoice.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	VendorInvoice.SalesOpportunity AS SalesOpportunity,
	|	DiscrepancyReportFollowingReceipt.Contract AS Contract,
	|	VendorInvoice.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	VendorInvoice.Director AS Director,
	|	NOT DiscrepancyReportFollowingReceipt.Posted AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport,
	|	NOT VendorInvoice.Posted AS ThereAreErrorsInReceiptDocument
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		INNER JOIN Document.VendorInvoice AS VendorInvoice
	|		ON (TRUE)
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND VendorInvoice.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis AS DocumentInflow,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VendorPriceKind AS VendorPriceKind,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate AS VATRate,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Count - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.CountByDocument) AS Count,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Sum - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.SumByDocument) AS Sum,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmount - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATAmountByDocument) AS VATAmount,
	|	SUM(CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVAT - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.AmountIncludingVATByDocument) AS AmountIncludingVAT
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS CertificateOfDiscrepanciesAfterAcceptanceOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis = &DocumentBasis
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse = &Warehouse
	|	AND CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterAcceptanceOfGoods.NumberOfPackagesByDocument > 0
	|
	|GROUP BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Products,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Characteristic,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Series,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Package,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Warehouse,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Purpose,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VendorPriceKind,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.Price,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.VATRate,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.DocumentBasis,
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber
	|
	|ORDER BY
	|	CertificateOfDiscrepanciesAfterAcceptanceOfGoods.LineNumber
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse AS Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose AS Purpose,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.Count - DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse = &Warehouse
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Count - DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VendorInvoice.ARAPObject AS Ref
	|INTO ARAPObjects
	|FROM
	|	Document.VendorInvoice.Goods AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &DocumentBasis
	|
	|UNION 
	|
	|SELECT DISTINCT
	|	ARAPObjects.Ref AS ARAPObject
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS GoodsTable
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|			ON ARAPObjects.Object = GoodsTable.PurchaseOrder
	|				AND NOT ARAPObjects.DeletionMark
	|WHERE
	|	GoodsTable.Ref = &DiscrepancyCertificate
	|	AND GoodsTable.DocumentBasis = &DocumentBasis
	|	AND GoodsTable.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND GoodsTable.PurchaseOrder <> VALUE(Document.PurchaseOrder.EmptyRef)
	|	AND GoodsTable.PurchaseOrder <> UNDEFINED
	|	AND GoodsTable.Warehouse = &Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
	|	VendorsARAPAccounting.Currency AS ARAPCurrency,
	|	-ISNULL(VendorsARAPAccounting.SumBalance, 0) AS SumBalance
	|FROM
	|	AccumulationRegister.VendorsARAPAccounting.Balance(
	|			,
	|			ARAPObject IN
	|				(SELECT
	|					Ref
	|				FROM
	|					ARAPObjects)) AS VendorsARAPAccounting
	|
	|ORDER BY
	|	VendorsARAPAccounting.ARAPObject.Date ";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	Query.SetParameter("Warehouse", FillingData.Warehouse);
	
	SetPrivilegedMode(True);

	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
		
	// According to the receipt document
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DocumentInflow,
		,
		HeaderSelection.ThereAreErrorsInReceiptDocument,
		,
		);
		
	// According to the act of discrepancies
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.DiscrepancyCertificate,
		HeaderSelection.StatusOfDivergenceReport,
		HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
		HeaderSelection.ThereAreErrorsStatusReport,
		DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn());
		
	FillPropertyValues(ThisObject, HeaderSelection);
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(HeaderSelection.BusinessOperation);
	
	TableOfGoods = QueryBatch[1].Unload();
	
	For Each CurRow In TableOfGoods Do
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		PriceManagementSystem.RecalculateAmountsInRow(
			NewRow,
			False,
			False,
			False,
			HeaderSelection.PriceIncludesVAT);
		
	EndDo;
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	SamplingBaseCalculations = QueryBatch[4].Select();
	DistributeCalculationsOnGrounds(SamplingBaseCalculations);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsToVendor);
	ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure FillInCertificateOfQualityControl(Val FillingData)
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager;
	Documents.GoodsQualityControlCertificate.GoodsToCreateBasedOn(
		Query,
		FillingData.Basis,
		FillingData.Warehouse,
		Enums.ActionsOnGoodsInQualityControlCertificate.RegisterReturn);
	
	Query.SetParameter("Ref", FillingData.Basis);
	Query.Text =
		"SELECT
		|	Attributes.ControlledLotReference.Organization AS Organization,
		|	Attributes.ControlledLotReference.Partner AS Partner,
		|	Attributes.ControlledLotReference.Counterparty AS Counterparty,
		|	Attributes.ControlledLotReference.Lot AS Lot,
		|	Attributes.ControlledLotReference.BusinessOperation AS BusinessOperation,
		|	Attributes.ControlledLotReference.Contract AS Contract,
		|	Attributes.ControlledLotReference.LineOfBusiness AS LineOfBusiness,
		|	Attributes.ControlledLotReference.Department AS Department,
		|	Attributes.Status AS Status
		|INTO ActHeader
		|FROM
		|	Document.GoodsQualityControlCertificate AS Attributes
		|WHERE
		|	Attributes.Ref = &Ref
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	*
		|FROM
		|	ActHeader
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.Organization AS Organization,
		|	Attributes.Partner AS Partner,
		|	Attributes.Lot AS Lot,
		|	Attributes.Counterparty AS Counterparty,
		|	Attributes.Contract AS Contract,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	Attributes.Department AS Department,
		|	&Warehouse AS Warehouse,
		|	VendorInvoice.Terms AS Terms,
		|	VendorInvoice.PriceIncludesVAT AS PriceIncludesVAT,
		|	VendorInvoice.Manager AS Manager,
		|	VendorInvoice.VATTaxation AS VATTaxation,
		|	VendorInvoice.Ref AS DocumentInflow,
		|	VendorInvoice.CompanyBankAccount AS CompanyBankAccount,
		|	VendorInvoice.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	VendorInvoice.SalesOpportunity AS SalesOpportunity,
		|	VendorInvoice.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	VendorInvoice.ChiefAccountant AS ChiefAccountant,
		|	VendorInvoice.Director AS Director
		|INTO Header
		|FROM
		|	ActHeader AS Attributes
		|		LEFT JOIN Document.VendorInvoice AS VendorInvoice
		|		ON VendorInvoice.Ref = Attributes.Lot
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.Organization AS Organization,
		|	Attributes.Partner AS Partner,
		|	Attributes.Lot AS Lot,
		|	Attributes.Counterparty AS Counterparty,
		|	Attributes.Contract AS Contract,
		|	Attributes.Department AS Department,
		|	Attributes.Warehouse AS Warehouse,
		|	Attributes.Terms AS Terms,
		|	Attributes.LineOfBusiness AS LineOfBusiness,
		|	Attributes.PriceIncludesVAT AS PriceIncludesVAT,
		|	Attributes.Manager AS Manager,
		|	Attributes.VATTaxation AS VATTaxation,
		|	Attributes.DocumentInflow AS DocumentInflow,
		|	Attributes.CompanyBankAccount AS CompanyBankAccount,
		|	Attributes.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	Attributes.SalesOpportunity AS SalesOpportunity,
		|	Attributes.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	Attributes.ChiefAccountant AS ChiefAccountant,
		|	Attributes.Director AS Director
		|FROM
		|	Header AS Attributes
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Warehouse AS Warehouse,
		|	MAX(Attributes.DocumentInflow) AS DocumentInflow,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	Goods.Package AS Package,
		|	SUM(Goods.Count) AS Count,
		|	SUM(Goods.NumberOfPackages) AS NumberOfPackages
		|FROM
		|	Goods AS Goods
		|		LEFT JOIN Header AS Attributes
		|		ON TRUE
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Warehouse,
		|	CASE
		|		WHEN Goods.BatchesIndicationStatus IN(10,14)
		|			THEN Goods.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END,
		|	Goods.Package
		|;
		|
		|/////////////////////////////////////////////////////
		|SELECT
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Purpose AS Purpose,
		|	Goods.Series AS Series,
		|	Goods.Warehouse AS Warehouse,
		|	SUM(Goods.Count) AS Count
		|FROM
		|	Goods AS Goods
		|WHERE
		|	NOT Goods.BatchesIndicationStatus IN(10,14)
		|	AND Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND NOT (Goods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
		|		AND &DocumentDate <= Goods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue)
		|GROUP BY
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Purpose,
		|	Goods.Series,
		|	Goods.Warehouse";
	
	SetPrivilegedMode(True);
	
	ResultsPackage = Query.ExecuteBatch();
	AttributesOfReport = ResultsPackage[1].Select();
	AttributesOfReport.Next();
	HeaderAttributes = ResultsPackage[3].Select();
	HeaderAttributes.Next();
	QualityControl.RaiseExceptionWhenCreatingBasedOnAct(AttributesOfReport);
	BaseGoods = ResultsPackage[4].Unload();
	BaseSeries = ResultsPackage[5].Unload();
	
	If BaseGoods.Count() = 0 Then
		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa với thao tác ""Lập chứng từ trả lại"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Документ %Document% не содержит товаров c действием ""Оформить возврат"". Ввод на основании документа запрещен.';
						|en = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.'; fa = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|it = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|pl = 'The ""%Document%"" document does not have any goods with the ""Register return"" action. Generation from such base documents is not allowed.';
						|tr = '%Document% belgesi ""İade düzenle"" işlemine sahip ürün içermemektedir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrReplace(ErrorText, "%Document%", FillingData.Basis);
		Raise ErrorText;
	EndIf;
	
	BusinessOperation = PurchasesServer.GetRefundTransactionOnReceipt(AttributesOfReport.BusinessOperation);
	AllDocumentOperationsOfOperations = New ValueList();
	Documents.ReturnOfGoodsToVendor.FillInListOfBusinessOperations(AllDocumentOperationsOfOperations);
	
	If AllDocumentOperationsOfOperations.FindByValue(BusinessOperation) = Undefined Then
		ErrorText = NStr("vi = 'Đối với nghiệp vụ ""%1"" mà theo đó đã nhập hàng, không đề xuất tạo chứng từ ""Trả lại hàng cho nhà cung cấp"". Việc nhập trên cơ sở chứng từ bị cấm.';
						|ru = 'Для операции ""%1"", по которой поступил товар, не предполагается создание документа ""Возврат товаров поставщику"". Ввод на основании документа запрещен.';
						|en = 'Cannot create a ""Return of goods to vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.'; fa = 'Cannot create a ""Return of goods to vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|it = 'Cannot create a ""Return of goods to vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|pl = 'Cannot create a ""Return of goods to vendor"" document based on the ""%1"" transaction, under which the goods were received. Generation based on the document is not allowed.';
						|tr = 'Malın girişinin yapıldığı ""%1"" işlemi için ""Tedarikçiye mal iadesi"" belgesi oluşturulması öngörülmemiştir. Belgeye dayanarak giriş yapılması yasaktır.'");
		ErrorText = StrTemplate(ErrorText, AttributesOfReport.BusinessOperation);
		Raise ErrorText;
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderAttributes,
		"Organization,
		|Partner,
		|Counterparty,
		|Contract,
		|Department,
		|Warehouse,
		|Terms,
		|LineOfBusiness,
		|PriceIncludesVAT,
		|Manager,
		|VATTaxation,
		|DocumentInflow,
		|CompanyBankAccount,
		|CounterpartyBankAccount,
		|SalesOpportunity,
		|FinancialAccountingGroup,
		|ChiefAccountant,
		|Director");
	
	If TypeOf(HeaderAttributes.Lot) <> Type("CatalogRef.CounterpartyContracts")
			And TypeOf(HeaderAttributes.Lot) <> Type("DocumentRef.RequestForGoodsQualityControl") Then
		Currency = Common.ObjectAttributeValue(HeaderAttributes.Lot, "Currency");
	EndIf;
	Goods.Load(BaseGoods);
	SetOfSeries.Load(BaseSeries);
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentFromStorage);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure FillOutDocumentOnBasisOfAcceptedContainer(Val DetailsOfFillingInForm)
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm.HeaderAttributes);
	ReturnOfReceivedReusablePackages = True;
	
	If Not ValueIsFilled(Terms) Then
		FillInDefaultPurchaseConditions();
	EndIf;
	
	If IsTempStorageURL(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage) Then
		
		ReceivedPackage = GetFromTempStorage(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage);
		Goods.Load(ReceivedPackage);
		
		For Each CurrentRow In Goods Do
			
			CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
			CurrentRow.NumberOfPackages = CurrentRow.Count;
			CurrentRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
			
		EndDo;
		
	EndIf;
	
	// We will fill out mutual settlements.
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
	
		Query = New Query(
			"SELECT DISTINCT
			|	VendorInvoice.ARAPObject AS ARAPObject
			|INTO ARAPObjects
			|FROM
			|	Document.VendorInvoice.Goods AS VendorInvoice
			|WHERE
			|	VendorInvoice.Ref IN (&DocumentBasis)
			|
			|UNION 
			|
			|SELECT DISTINCT
			|	GoodsTable.ARAPObject AS ARAPObject
			|FROM
			|	Document.VendorInvoice.Goods AS GoodsTable
			|WHERE
			|	GoodsTable.Ref IN (&DocumentBasis)
			|	AND GoodsTable.Ref.ReceiptUnderOrders
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	VendorsARAPAccounting.ARAPObject AS ARAPObject,
			|	VendorsARAPAccounting.Currency AS ARAPCurrency,
			|	-ISNULL(VendorsARAPAccounting.SumBalance, 0) AS SumBalance
			|FROM
			|	AccumulationRegister.VendorsARAPAccounting.Balance(
			|			,
			|			ARAPObject IN
			|				(SELECT
			|					ARAPObject
			|				FROM
			|					ARAPObjects)) AS VendorsARAPAccounting
			|
			|ORDER BY
			|	VendorsARAPAccounting.ARAPObject.Date
			|");
			
		Query.SetParameter("DocumentBasis", Goods.UnloadColumn("DocumentInflow"));
		SetPrivilegedMode(True);
		SamplingBaseCalculations = Query.Execute().Select();
		
		AmountForAllocation = GetDocumentAmount();
		
		While AmountForAllocation > 0 And SamplingBaseCalculations.Next() Do
			
			If SamplingBaseCalculations.SumBalance > 0 Then
				
				NewRow = ARAPDetails.Add();
				NewRow.ARAPCurrency = SamplingBaseCalculations.ARAPCurrency;
				NewRow.ARAPObject = SamplingBaseCalculations.ARAPObject;
				
				If AmountForAllocation > SamplingBaseCalculations.SumBalance Then
					NewRow.Sum = SamplingBaseCalculations.SumBalance;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndDo;
		
		If AmountForAllocation > 0 Then
			
			NewRow = ARAPDetails.Add();
			NewRow.ARAPCurrency = Currency;
			NewRow.Sum = AmountForAllocation;
			
		EndIf;
		
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReturnOfGoodsToVendor);
	ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
	
	BaseStructure = Documents.ReturnOfGoodsToVendor.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, BaseStructure);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	Author = Users.CurrentUser();
	
	ResponsiblePersonsServer.InstallManager(
		ThisObject, PurchasesServer.DocumentBasis(ThisObject, "DocumentInflow, Goods.DocumentInflow"));
	
	Currency                    = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	ARAPCurrency      = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(ARAPCurrency);
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse                     = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	FillParameters = Documents.ReturnOfGoodsToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	If ValueIsFilled(DocumentInflow) Then
			StructureOfFillingInVATRate.Date = Common.ObjectAttributeValue(DocumentInflow, "Date");
	EndIf;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods);
	
	CurrencyOfPayment  = CashServer.GetPaymentCurrency(, CompanyBankAccount);
	ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, Organization);

EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
EndProcedure

Function OrganizationSDefaultAccountParameters()
	
	If ValueIsFilled(Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	ParametersOfAccount.LineOfBusiness = LineOfBusiness;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	Return ParametersOfAccount;
	
EndFunction

#EndRegion

#Region InventoryKinds

Function ThereAreGoodsTableEntriesInTemporaryTableManager(TempTablesManager)
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	TableOfGoods AS TableOfGoods";
	Selection = Query.Execute().Select();
	
	Return Selection.Count() > 0;
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		ManagerOfTemporaryTablesForReceiptDocument = TemporaryDocumentDataTables(True);
		ManagerOfTemporaryTablesWithoutReceiptDocument = TemporaryDocumentDataTables(False);
		
		TypesOfStocksIntermediate = InventoryKinds.Unload(New Array);
		
		// 1. Returns on the receipt document are processed first, with the extraction of Balances on the receipt document.
		If ThereAreGoodsTableEntriesInTemporaryTableManager(ManagerOfTemporaryTablesForReceiptDocument) Then
			FillParameters = ParametersForFillingInventoryTypes();
			FillParameters.NameOfRemainderTable = "AcceptedGoods";
			FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			
			InventoryKinds.Clear();
			TypesOfStocksToFillIn = InventoryKinds.Unload();
			TypesOfStocksToFillIn.Columns.Add("DocumentTransfers_", 
				New TypeDescription("DocumentRef.VendorInvoice"));
			
			FillParameters.TableTypesOfStocks_ = TypesOfStocksToFillIn;
			
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	ManagerOfTemporaryTablesForReceiptDocument,
																	Cancel,
																	FillParameters);
			TypesOfStocksToFillIn.Columns.DocumentInflow.Name = "DeleteReceiptDocument";														
			TypesOfStocksToFillIn.Columns.DocumentTransfers_.Name = "DocumentInflow";
			
			CommonClientServer.SupplementTable(TypesOfStocksToFillIn, TypesOfStocksIntermediate);
		EndIf;
		
		// 2. Returns without specifying the purchase document are processed in the second turn, according to the total Balances of Goods of organizations.
		If ThereAreGoodsTableEntriesInTemporaryTableManager(ManagerOfTemporaryTablesWithoutReceiptDocument) Then
			FillParameters = ParametersForFillingInventoryTypes();
			
			InventoryKinds.Clear();
			InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																	ManagerOfTemporaryTablesWithoutReceiptDocument,
																	Cancel,
																	FillParameters);
			
			CommonClientServer.SupplementTable(InventoryKinds, TypesOfStocksIntermediate);
		EndIf;
		
		InventoryKinds.Load(TypesOfStocksIntermediate);
		
		InventoryKinds.GroupBy("DocumentInflow, ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Warehouse";
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then 
		AttributesNames = AttributesNames + ", Partner, Terms";
	EndIf;
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.DocumentInflow AS DocumentInflow,
	|	TableOfGoods.VATRate AS VATRate
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.DocumentInflow AS DocumentInflow,
	|		TableOfGoods.Price AS Price,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType  IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.DocumentInflow AS DocumentInflow,
	|		TableTypesOfStocks_.Price AS Price,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.DocumentInflow,
	|	TableOfGoods.Price
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAdditionalStockTypes() Export
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, Package, Price, DocumentInflow, VATRate";
	NamesOfSummationColumns	= "Count, NumberOfPackages, AmountIncludingVAT, VATAmount";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
	
	TheStructureOfTheSearch = New Structure("DocumentInflow, ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity	= RowOfGoods.Count;
		NumberOfPackages	= RowOfGoods.NumberOfPackages;
		
		If GoodsQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() = 0 Then
			TheStructureOfTheSearch.DocumentInflow = Documents.VendorInvoice.EmptyRef();
			FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		FillInAdditionalColumnsOfTypesOfStocksInTableOfGoods(RowOfGoods, FoundRows, GoodsQuantity, NumberOfPackages);
		
		If GoodsQuantity <> 0
			And TheStructureOfTheSearch.DocumentInflow <> Documents.VendorInvoice.EmptyRef() Then
			TheStructureOfTheSearch.DocumentInflow = Documents.VendorInvoice.EmptyRef();
			FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
			FillInAdditionalColumnsOfTypesOfStocksInTableOfGoods(RowOfGoods, FoundRows, GoodsQuantity, NumberOfPackages);
		EndIf;
		
	EndDo;
	
	SearchParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(SearchParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInAdditionalColumnsOfTypesOfStocksInTableOfGoods(RowOfGoods, FoundRows, GoodsQuantity, NumberOfPackages)

		For Each InventoryLine In FoundRows Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Price				= RowOfGoods.Price;
			NewRow.VATRate			= RowOfGoods.VATRate;
			NewRow.Package			= RowOfGoods.Package;
			NewRow.DocumentInflow	= RowOfGoods.DocumentInflow;
			NewRow.NumberOfPackages	= NumberOfPackages * Count / GoodsQuantity;
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.AmountIncludingVAT			= ?(Count = GoodsQuantity,
												RowOfGoods.AmountIncludingVAT,
												Count * RowOfGoods.AmountIncludingVAT / GoodsQuantity);
			NewRow.VATAmount			= ?(Count = GoodsQuantity,
												RowOfGoods.VATAmount,
												Count * RowOfGoods.VATAmount / GoodsQuantity);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			
			GoodsQuantity		= GoodsQuantity - NewRow.Count;
			NumberOfPackages		= NumberOfPackages - NewRow.NumberOfPackages;
			RowOfGoods.AmountIncludingVAT	= RowOfGoods.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			RowOfGoods.VATAmount	= RowOfGoods.VATAmount - NewRow.VATAmount;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReturnOfGoodsToVendor.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ReturnOfGoodsToVendor.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner);

	// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	If ValueIsFilled(Warehouse) Then
		WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	Else
		WarehouseDetails = New Structure;
		WarehouseDetails.Insert("IsFolder",	False);
		WarehouseDetails.Insert("SelectGroup",	Undefined);
	EndIf;
	
	If WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

// Creates a temporary table of products with separate accounting Analytics
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	DocumentDataTable.Department AS Department,
	|	DocumentDataTable.Manager AS Manager,
	|	DocumentDataTable.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|	CASE
	|		WHEN &ThisIsReturnToCommitee
	|			THEN DocumentDataTable.Partner
	|		ELSE VALUE(Catalog.Partners.EmptyRef)
	|	END AS Partner,
	|	CASE
	|		WHEN &ThisIsReturnToCommitee
	|			THEN DocumentDataTable.Terms
	|		ELSE VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|	END AS Terms,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	TableOfGoods.Count AS Count
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON (TRUE)");
	Query.SetParameter("ThisIsReturnToCommitee", (BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor));
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

#EndRegion

#Region Other

Procedure DistributeCalculationsOnGrounds(SamplingBaseCalculations)

	// We will fill out mutual settlements.
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToVendor Then
		
		AmountForAllocation = GetDocumentAmount();
		
		While AmountForAllocation > 0 And SamplingBaseCalculations.Next() Do
			
			If SamplingBaseCalculations.SumBalance > 0 Then
				
				NewRow = ARAPDetails.Add();
				NewRow.ARAPCurrency = SamplingBaseCalculations.ARAPCurrency;
				NewRow.ARAPObject = SamplingBaseCalculations.ARAPObject;
				
				Coefficients  = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
					Currency, SamplingBaseCalculations.ARAPCurrency, CurrentSessionDate(), Organization);
				LineAmount_ = ?(Coefficients.ConversionRateToSettlementCurrency <> 0, SamplingBaseCalculations.SumBalance / Coefficients.ConversionRateToSettlementCurrency, 0);
				
				If AmountForAllocation > LineAmount_ Then
					NewRow.Sum = LineAmount_;
				Else
					NewRow.Sum = AmountForAllocation;
				EndIf;
				
				AmountForAllocation = AmountForAllocation - NewRow.Sum;
				
			EndIf;
			
		EndDo;
		
		If AmountForAllocation > 0 Then
			
			NewRow = ARAPDetails.Add();
			NewRow.ARAPCurrency = Currency;
			NewRow.Sum = AmountForAllocation;
			
		EndIf;
		
	EndIf;

EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.SelectionOfStockTypes_.VATTaxation = VATTaxation;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
		FillParameters.SelectTypesOfStocksForIntercampany = False;
		FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
		
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization = Organization;
		SelectionOfStockTypes_.GoodsOwner  = Partner;
		SelectionOfStockTypes_.Counterparty = ?(ValueIsFilled(Counterparty), Counterparty, Undefined);
		SelectionOfStockTypes_.Contract = Contract;
		SelectionOfStockTypes_.Terms = Terms;
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ConsignedGoods;
	Else
		FillParameters.SelectTypesOfStocksForIntercampany = True;
		FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.OwnGoods);
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.GoodsInStorageWithRightToSell);
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
