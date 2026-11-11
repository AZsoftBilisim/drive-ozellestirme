#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.WriteOffReportFromCommissionAgent - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.WriteOffReportFromCommissionAgent.CollectionOfTabularPartsOfGoods.
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

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryOwnerAttributesAreSpecifiedManually	= False;
	
	InventoryKinds.Clear();
	ARAPDetails.Clear();
	
	FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = True;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
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
	
	If Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms) Then
		RecalculationParameters = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
								ThisObject,
								"Partner");
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(RecalculationParameters, Goods);
	EndIf;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "InventoryKinds");
	
	WriteOffReportFromCommissionAgentLocalization.OnCopy(ThisObject, CopiedObject);
	Author = Users.CurrentUser();

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	DefaultBusinessTransaction = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		If FillingData.Property("FillInByAgreement") Then
	 
			Partner = FillingData.Partner;
			Terms = FillingData.Terms;
			Organization = FillingData.Organization;
			If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
				FillInTermsOfSalesUnderAgreement(FillingData.Organization);
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				Contract = SalesServer.GetDefaultContract(
					ThisObject,
					DefaultBusinessTransaction,
					Currency,,
					False);
					
				FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
			EndIf;
			
			ConsignmentSalesServer.FillInBalanceOfGoodsTransferredToCommission(
				ThisObject, 
				FillingData.EndOfPeriod,
				False); // ThereIsSaleAmount
			
		ElsIf FillingData.Property("Partner") Then
			
			Partner = FillingData.Partner;
			If GetFunctionalOption("ToUseTermsOfSales") Then
				FillInDefaultSalesConditions();
				
				FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
			EndIf;
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	InitializeSalesConditions();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	InitializeDocument(FillingData);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffReportFromCommissionAgent.ItemsAndDimensionsSelectionParameters(DefaultBusinessTransaction);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	WriteOffReportFromCommissionAgentLocalization.Filling(ThisObject, FillingData, StandardProcessing);

	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	If Goods.Total("AmountIncludingVAT") = 0 Then
		NotCheckedAttributeArray.Add("IncomeItem");
		NotCheckedAttributeArray.Add("PaymentDate");
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);	
	
	BusinessOperation = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffReportFromCommissionAgent.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
		
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	Common.DeleteNotCheckedAttributesFromArray(
		CheckedAttributes,
		NotCheckedAttributeArray);
	
	ConsignmentSalesServer.CheckIfPeriodIsCorrect(ThisObject, Cancel);
	
	If ByPhysicalCountResults Then
		
		KeyAttributes = New Array;
		KeyAttributes.Add("Products");
		KeyAttributes.Add("Characteristic");
		TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject, "Goods", KeyAttributes, Cancel);
		
	EndIf;
	
	WriteOffReportFromCommissionAgentLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DefaultBusinessTransaction = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();

	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	CalculationDocumentAmount = Goods.Total("AmountIncludingVAT");
	If DocumentAmount <> CalculationDocumentAmount Then
		DocumentAmount = CalculationDocumentAmount;
	EndIf;
	
	AccountingForTraceableGoodsLocalization.ClearDataOnImportedGoodsInCommissionAgentSDocuments(ThisObject);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "InventoryKinds");
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;

	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ItemsAndDimensionsSelectionParameters = Documents.WriteOffReportFromCommissionAgent.ItemsAndDimensionsSelectionParameters(DefaultBusinessTransaction);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);

	WriteOffReportFromCommissionAgentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	WriteOffReportFromCommissionAgentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	WriteOffReportFromCommissionAgentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	WriteOffReportFromCommissionAgentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions <> Undefined Then
		
		If ValueIsFilled(SalesTermsAndConditions.Currency) Then
			Currency = SalesTermsAndConditions.Currency;
		EndIf;
		
		LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
		
		PriceIncludesVAT = SalesTermsAndConditions.PriceIncludesVAT;
			
		If ValueIsFilled(SalesTermsAndConditions.Organization) Then
			Organization = SalesTermsAndConditions.Organization;
		EndIf;
		
		If Not SalesTermsAndConditions.Standard_
		 And ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
		
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
		If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
			DefaultBusinessTransaction = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();
			Contract = SalesServer.GetDefaultContract(
				ThisObject,
				DefaultBusinessTransaction,
				Currency,,
				False);
				
			If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
				LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
			EndIf;
		
		EndIf;
		
		If Not ValueIsFilled(SalesTermsAndConditions.ContractsAreUsed) 
			Or Not SalesTermsAndConditions.ContractsAreUsed Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
		Else
			ForeignCurrencyTransaction = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
		EndIf;
		
		If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	DefaultBusinessTransaction = Documents.WriteOffReportFromCommissionAgent.DefaultBusinessTransaction();
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
			Partner,
			New Structure("BusinessTransactions, SelectedAgreement, EmptyDocumentLink", 
			DefaultBusinessTransaction, 
			Terms,
			Documents.WriteOffReportFromCommissionAgent.EmptyRef()));
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					FillParameters = New Structure;
					FillParameters.Insert("Date", ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, Date));
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					
					EnterprisePricesFillingServer.FillInPrices(
						Goods, // Table part
						, // Array of rows or selection structure
						FillParameters,
						StructureOfActions);
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
			EndIf;
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInTermsOfSalesUnderAgreement(Organization = Undefined) Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
	If Organization <> Undefined Then
		SalesTermsAndConditions.Organization = Organization;
	EndIf;
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.WriteOffReportFromCommissionAgent.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", ?(ValueIsFilled(EndOfPeriod), EndOfPeriod, Date));
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Terms", Terms);
	If SalesTermsAndConditions.NewCommissionScheme Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Contract, "PriceTypeAccountingPriceType"));
	EndIf;
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	EnterprisePricesFillingServer.FillInPrices(
		Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization		= SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

#EndRegion

#Region InventoryKinds

Function TemporaryDocumentDataTables() Export
	
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
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
	|	FALSE			AS ThereAreTransactionsInTablePart,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes			AS ItemsLocationAttributes,
	|	TableOfGoods.Products							AS Products,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|	VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|	0													AS BatchesIndicationStatus,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.QuantityByGBRN						AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	TableOfGoods.VATRate							AS VATRate,
	|	TableOfGoods.AmountIncludingVAT							AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount								AS VATAmount,
	|	0													AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber								AS CCDNumber,
	|	&Terms											AS Terms,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	TRUE												AS SelectTypesOfStocks
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT (&UseTraceableImportedGoodsAccounting
	|					AND BEGINOFPERIOD(&Date, MONTH) >= &DateOfTraceableImportedGoodsAccountingStart)
	|				OR NOT ISNULL(AgreementData.CommissionAgentUsesInventoryAccountingByProductBatchID, FALSE)
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END										AS QuantityByGBRN,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.CommissionAmount			AS CommissionAmount,
	|	TableOfGoods.AmountVATRemuneration		AS AmountVATRemuneration,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.SalesOpportunity						AS SalesOpportunity,
	|	TableOfGoods.SelectTypesOfStocks			AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.TermsOfSale AS AgreementData
	|		ON TableOfGoods.Terms = AgreementData.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count						AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END												AS QuantityByGBRN,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS Warehouse,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	0													AS CommissionAmount,
	|	0													AS AmountVATRemuneration,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	VALUE(Catalog.Warehouses.EmptyRef)			AS OriginWarehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)	AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually							AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	UNDEFINED										AS RecipientInventoryOwnerAttribute,
	|	Dimension.Products								AS Products,
	|	Dimension.Characteristic							AS Characteristic,
	|	Dimension.Series										AS Series,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityByGBRN,
	|	TableTypesOfStocks_.Warehouse							AS Warehouse,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount				AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration			AS AmountVATRemuneration,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.OriginWarehouse					AS OriginWarehouse,
	|	TableTypesOfStocks_.SalesOpportunity							AS SalesOpportunity,
	|	TableTypesOfStocks_.InventoryOwnerAttributesAreSpecifiedManually		AS InventoryOwnerAttributesAreSpecifiedManually
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
	
	Query.SetParameter("Ref",				Ref);
	Query.SetParameter("Date",				Date);
	Query.SetParameter("Organization",		Organization);
	Query.SetParameter("Partner",			Partner);
	Query.SetParameter("Counterparty",			Counterparty);
	Query.SetParameter("Terms",			Terms);
	Query.SetParameter("Contract",			Contract);
	Query.SetParameter("Currency",				Currency);
	Query.SetParameter("TableOfGoods",		TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",	InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager = TemporaryDocumentDataTables();
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		FillParameters.SelectTypesOfStocksForIntercampany = False;
		FillParameters.NameOfRemainderTable = "GoodsTransferredToCommissionAgent";
		FillParameters.WithoutSelectionByCCDNumbers = Not Catalogs.TermsOfSale.CommissionAgentUsesInventoryAccountingByProductBatchID(Terms)
													Or Not AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date);
		FillParameters.ReversedDocument = ReversedDocument;
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Terms";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0
	|	OR SUM(TableOfGoods.AmountVATRemuneration) <> 0";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.WriteOffReportFromCommissionAgent.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.WriteOffReportFromCommissionAgent.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(
					Enums.BusinessTransactions.ConsignmentReportFromCustomer,
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
