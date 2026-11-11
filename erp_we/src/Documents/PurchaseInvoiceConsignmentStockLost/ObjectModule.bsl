#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.PurchaseInvoiceConsignmentStockLost - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	Return;
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.PurchaseInvoiceConsignmentStockLost.CollectionOfTabularPartsOfGoods.
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
	
	Author = Users.CurrentUser();
	
	If TypeOf(FillingData) = Type("Structure")
	   And FillingData.Property("FillInByTheGoodsForRegistration") Then
		
		Partner = FillingData.Partner;
		Counterparty = FillingData.Counterparty;
		Terms = FillingData.Terms;
		Contract = FillingData.Contract;
		VATTaxation = FillingData.VATTaxation;
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		BeginOfPeriod = FillingData.BeginOfPeriod;
		EndOfPeriod = FillingData.EndOfPeriod;
		If BegOfMonth(EndOfPeriod) < BegOfMonth(CurrentSessionDate()) Then
			Date = EndOfPeriod;
		EndIf;
		If ValueIsFilled(Terms) Then
			FillInTermsOfPurchaseUnderAgreement();
			Organization = FillingData.Organization;
			Contract = FillingData.Contract;
			Counterparty = FillingData.Counterparty;
		Else
			Currency = FillingData.Currency;
			Organization = FillingData.Organization;
			If Not ValueIsFilled(Counterparty) Then
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			If Not ValueIsFilled(Contract) Then
				
				AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
				AddlParameters.ARAPCurrency = Currency;
				Contract = PurchasesServer.GetDefaultContract(
					ThisObject,
					Enums.BusinessTransactions.ConsignmentProcurement,
					AddlParameters);
					
			EndIf;
		EndIf;
		
		PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
		
		FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
		
		ConsignmentSalesServer.FillInInformationOnBalancesForMakingReportsToCommitteeOnWriteOffs(ThisObject,, True);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	InitializeDocument(FillingData);
	
 	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	PurchaseInvoiceConsignmentStockLostLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If ValueIsFilled(EndOfPeriod)
		And BegOfMonth(Date) <> BegOfMonth(EndOfPeriod) Then
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Ngày chứng từ và ngày đầu kỳ %1 phải trong một tháng';
							|ru = 'Дата документа и дата окончания периода %1 должны быть в одном месяце';
							|en = 'Document date and period end date %1 shall be in one month'; fa = 'Document date and period end date %1 shall be in one month';
							|it = 'La data del documento e la data del termine periodo %1 devono essere dello stesso mese';
							|pl = 'Data dokumentu i data wygaśnięcia okresu %1 muszą wynosić jeden miesiąc';
							|tr = 'Belgenin tarihi ve son geçerlilik tarihi%1 aynı ay içinde olmalıdır'"),
						Format(EndOfPeriod, "DLF=DD"));
		
		Common.MessageToUser(ErrorText, ThisObject, "Date", , Cancel);
	EndIf;
	
	PurchaseInvoiceConsignmentStockLostLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	CalculationDocumentAmount = Goods.Total("AmountIncludingVAT");
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	PurchaseInvoiceConsignmentStockLostLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	PurchaseInvoiceConsignmentStockLostLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	PurchaseInvoiceConsignmentStockLostLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	PurchaseInvoiceConsignmentStockLostLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	InventoryKinds.Clear();

	PurchaseInvoiceConsignmentStockLostLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions <> Undefined Then
	
		DocumentPurchases = ThisObject;
		DocumentPurchases.Currency = PurchaseConditions.Currency;
		LineOfBusiness = PurchaseConditions.LineOfBusiness;
		
		If ValueIsFilled(PurchaseConditions.Organization) Then
			DocumentPurchases.Organization = PurchaseConditions.Organization;
		EndIf;
			
		If ValueIsFilled(PurchaseConditions.Counterparty) Then
			DocumentPurchases.Counterparty = PurchaseConditions.Counterparty;
		EndIf;
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
		If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			Contract = PurchasesServer.GetDefaultContract(
				ThisObject,
				Enums.BusinessTransactions.ConsignmentProcurement,
				AddlParameters);
				
			If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
				Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
				LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
			EndIf;
		
		EndIf;
		
		If Not ValueIsFilled(PurchaseConditions.ContractsAreUsed) 
			Or Not PurchaseConditions.ContractsAreUsed Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
		Else
			ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
		EndIf;
		
		DocumentPurchases.PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
		
		If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	If RecalculatePrices_ Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price, VATRate");
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("Terms", Terms);
		FillParameters.Insert("VATTaxation", VATTaxation);
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
		
		PartnerPricesFillingServer.FillInPrices(
			Goods,
			Undefined, // Array of strings
			FillParameters,
			StructureOfActions);
			
	EndIf;
	
	ConsignmentSalesServer.FillInAmountWithVAT(Goods, PriceIncludesVAT);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	Organization     = SettingsValueCached.GetDefaultOrganization(Organization);
	
	FillParameters = Documents.ConsignmentReportToVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or InventoriesServer.CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Then
	 
		FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		FillParameters.WithoutSelectionByCCDNumbers = True;
		FillParameters.ReversedDocument = ReversedDocument;
		
		SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
		SelectionOfStockTypes_.Organization = Organization;
		SelectionOfStockTypes_.GoodsOwner = Partner;
		SelectionOfStockTypes_.Contract = Contract;
		SelectionOfStockTypes_.Currency = Currency;
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.ConsignedGoods;
		
		FillParameters.NameOfRemainderTable = "RequirementsForIssuingReportsToCommitteeOnWriteOffs";
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
	EndIf;
	
EndProcedure

Function TemporaryDocumentDataTables()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date			AS Date,
	|	&Organization	AS Organization,
	|	&Partner		AS Partner,
	|	&Counterparty		AS Counterparty,
	|	&Terms		AS Terms,
	|	&Contract		AS Contract,
	|	&Currency			AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.PurchaseInvoiceConsignmentStockLost) AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|	0													AS BatchesIndicationStatus,
	|	TableOfGoods.Count							AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END												AS QuantityByGBRN,
	|	TableOfGoods.VATRate							AS VATRate,
	|	TableOfGoods.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount								AS VATAmount,
	|	0													AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	TRUE												AS SelectTypesOfStocks,
	|	&FieldTextTableOfGoodsCCDNumber_					AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	0													AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS OriginWarehouse,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually							AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	UNDEFINED									AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	0												AS CommissionAmount,
	|	0												AS AmountVATRemuneration,
	|	TableTypesOfStocks_.OriginWarehouse				AS OriginWarehouse,
	|	TableTypesOfStocks_.Warehouse						AS Warehouse,
	|	TableTypesOfStocks_.SalesOpportunity						AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually
	|	
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref",						Ref);
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Organization",				Organization);
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually",	InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("TableOfGoods",				TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",			InventoryKinds);
	
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

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Terms, Currency";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.PurchaseInvoiceConsignmentStockLost.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.PurchaseInvoiceConsignmentStockLost.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ConsignmentReportToVendor,
					Undefined,
					Department,
					Partner);
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Purpose = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
