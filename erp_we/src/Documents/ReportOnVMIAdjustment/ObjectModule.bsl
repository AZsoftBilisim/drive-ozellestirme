#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function creates temporary tables with document data.
// Used for filling in inventory types.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query("
	|SELECT
	|	&Date                                                      AS Date,
	|	&Partner                                                   AS Partner,
	|	&Counterparty                                                AS Counterparty,
	|	&Terms                                                AS Terms,
	|	&Contract                                                   AS Contract,
	|	&Organization                                               AS Organization,
	|	UNDEFINED                                               AS Warehouse,
	|	&BusinessOperation                                     AS BusinessOperation,
	|	UNDEFINED                                               AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	FALSE                                                       AS ThereAreTransactionsInTablePart,
	|	&Department                                             AS Department,
	|	&Manager                                                  AS Manager,
	|	VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                AS LineNumber,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	TableOfGoods.Purpose                 AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.Package                   AS Package,
	|	TableOfGoods.Count                 AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END                                     AS QuantityByGBRN,
	|	&FieldTextTableOfGoodsCCDNumber_         AS CCDNumber
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber                         AS LineNumber,
	|	TableOfGoods.Products                        AS Products,
	|	TableOfGoods.ItemsLocationAttributes 		   AS ItemsLocationAttributes,
	|	TableOfGoods.Characteristic                      AS Characteristic,
	|	TableOfGoods.Series                               AS Series,
	|	TableOfGoods.BatchesIndicationStatus                 AS BatchesIndicationStatus,
	|	TableOfGoods.Purpose                          AS Purpose,
	|	TableOfGoods.Count                          AS Count,
	|	VALUE(Catalog.VATRates.EmptyRef)      AS VATRate,
	|	Dimension.StorageLocation							   AS Warehouse,
	|	TableOfGoods.Package                            AS Package,
	|	0                                                  AS Price,
	|	0                                                  AS VATAmount,
	|	0                                                  AS AmountIncludingVAT,
	|	0                                                  AS CommissionAmount,
	|	0                                                  AS AmountVATRemuneration,
	|	TRUE                                             AS SelectTypesOfStocks,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)        AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	TableTypesOfStocks_.Package                        AS Package
	|
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	UNDEFINED                                       AS DocumentSalesOfGoodsAndServices,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS ItemsLocationAttributes,
	|	Dimension.Products                             AS Products,
	|	Dimension.Characteristic                           AS Characteristic,
	|	Dimension.Series                                    AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	VALUE(Catalog.VATRates.EmptyRef)      AS VATRate,
	|	0                                                  AS Price,
	|	TableTypesOfStocks_.Package                        AS Package,
	|	0                                                  AS AmountIncludingVAT,
	|	0                                                  AS VATAmount,
	|	0                                                  AS CommissionAmount,
	|	0                                                  AS AmountVATRemuneration,
	|	VALUE(Catalog.Warehouses.EmptyRef)           AS OriginWarehouse,
	|	Dimension.StorageLocation							   AS Warehouse,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	FALSE                         					   AS InventoryOwnerAttributesAreSpecifiedManually
	|
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|");
	
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("Ref",                Ref);
	Query.SetParameter("Date",                  Date);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Terms",            Terms);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Manager",              Manager);
	Query.SetParameter("TableOfGoods",        Goods);
	Query.SetParameter("TableTypesOfStocks_",    InventoryKinds);
	Query.SetParameter("Department",         Department);
	
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
	
	Return Query.TempTablesManager;
	
EndFunction

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table manager.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes                  AS ItemsLocationAttributes,
	|	TableOfGoods.Products                                AS Products,
	|	TableOfGoods.Characteristic                              AS Characteristic,
	|	TableOfGoods.Purpose                                  AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus IN (14,18)
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Count                                  AS Count,
	|	DocumentDataTable.Partner                             AS Partner,
	|	DocumentDataTable.Terms                          AS Terms,
	|	DocumentDataTable.Department                       AS Department,
	|	TableOfGoods.Warehouse                                       AS Warehouse,
	|	DocumentDataTable.Manager                            AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)         AS SalesOpportunity,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation
	|
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON (TRUE)";
	
	Query.Execute();
	
EndProcedure

// Fills in the purchase conditions in the document for debiting goods accepted for storage according to the specified parameters.
//
// Parameters:
//	PurchaseConditions - Structure - structure for filling in the document details.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	WriteOffAtOurExpense =
		BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
		Or False;
	
	If WriteOffAtOurExpense Then
		Currency               = PurchaseConditions.Currency;
		PaymentMethod          = PurchaseConditions.PaymentMethod;
		ARAPCurrency = PurchaseConditions.ARAPCurrency;
	EndIf;
	
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization)
		And PurchaseConditions.Organization <> Organization Then
		
		Organization = PurchaseConditions.Organization;
		
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty)
		And PurchaseConditions.Counterparty <> Counterparty Then
		
		Counterparty = PurchaseConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If WriteOffAtOurExpense And TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = ARAPCurrency;
		AddlParameters.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
			Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff;
		
		Contract = PurchasesServer.GetDefaultContract(ThisObject,
			Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale, AddlParameters);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
		If WriteOffAtOurExpense Then
			If ValueIsFilled(Contract) Then
				PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
				If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
					ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
					CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
				EndIf;
			EndIf;
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount,
				CounterpartyBankAccount);
		EndIf;
		
	Else
		
		If WriteOffAtOurExpense And ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	If WriteOffAtOurExpense Then
		
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			CompanyBankAccount);
		
		If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
		EndIf;
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, , Contract);
	
EndProcedure

// Fills in the default purchase conditions in the document for debiting goods accepted for storage.
//
// Parameters:
//  RecalculatePrices_ - Boolean - indicates whether prices need to be recalculated.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		FilterParameters = New Structure();
		FilterParameters.Insert("SelectedAgreement",   Terms);
		
		WriteOffAtOurExpense =
			BusinessOperation = Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses
			Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses
			Or False;
		
		If ValueIsFilled(Contract)
			And GeneralPurposeTMServerCall.ObjectAttributeValue(Contract, "ContractType") = Enums.ContractTypes.CustomerInvoiceOutsourcedSale Then
				
			If WriteOffAtOurExpense Then
				SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
			EndIf;
			
		Else
			DefaultPurchasingConditions = Undefined;
			If BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
				And BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
				FilterParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
				DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, FilterParameters);
			EndIf;
			TheCounterpartyPriorToTheChange = Counterparty;
			
			If DefaultPurchasingConditions <> Undefined Then
				
				If Terms <> DefaultPurchasingConditions.Terms
					And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
					
					Terms = DefaultPurchasingConditions.Terms;
					FillInTermsOfPurchase(DefaultPurchasingConditions);
					TheCounterpartyPriorToTheChange = Counterparty;
					
					If RecalculatePrices_
						And ValueIsFilled(Terms) Then
						
						FillParameters = New Structure;
						FillParameters.Insert("PopulationFields", "Price");
						FillParameters.Insert("Date",           Date);
						FillParameters.Insert("Currency",         Currency);
						FillParameters.Insert("Terms",     Terms);
						
						StructureOfActions = New Structure;
						StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
						StructureOfActions.Insert("ClearAmountOfSettlements");
						
					EndIf;
					
				Else
					Terms = DefaultPurchasingConditions.Terms;
					
					PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
					If TheCounterpartyPriorToTheChange <> Counterparty Then
						CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
					EndIf;
				EndIf;
				
			Else
				Terms = Undefined;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				If TheCounterpartyPriorToTheChange <> Counterparty Then
					CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
				EndIf;
				
				AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
				AddlParameters.ARAPCurrency = ARAPCurrency;
				AddlParameters.RegistrationOfWriteOffOfInventoryShortageAcceptedForStorage =
					Enums.RegistrationOfWriteOffOfGoodsAcceptedForStorage.RegisterWriteOff;
				If BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
					Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
					ContractBusinessTransaction = TollingSchemeClientServer.ContractBusinessTransaction();
				Else
					ContractBusinessTransaction = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
				EndIf;
				Contract = PurchasesServer.GetDefaultContract(ThisObject,
					ContractBusinessTransaction, AddlParameters);
				
				If WriteOffAtOurExpense Then
					PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
				EndIf;
				
			EndIf;
			
			If WriteOffAtOurExpense Then
				ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
				CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
					ParametersOfAccount, CounterpartyBankAccount, PaymentMethod);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the terms of purchases under the agreement in the document for debiting goods accepted for storage.
//
Procedure FillInTermsOfPurchaseUnderAgreement() Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
	FillInTermsOfPurchase(PurchaseConditions);
	
EndProcedure

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.ReportOnVMIAdjustment - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	ParametersForFillingInventoryTypes = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.ReportOnVMIAdjustment.CollectionOfTabularPartsOfGoods.
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

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
		FillInSelectionDocument(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
	
	EndIf;
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	InitializeDocument();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	ReportOnVMIAdjustmentLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	SeriesSpecificationParameters        = ProductsServer.SeriesSpecificationParameters(ThisObject,
										Documents.ReportOnVMIAdjustment);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel,
		NotCheckedAttributeArray);
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.ReportOnVMIAdjustment.FillInNamesOfBusinessTransactionDetails(BusinessOperation,
		ArrayOfAllProps, ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(ArrayOfAllProps, ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	If BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
	 Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		
		NotCheckedAttributeArray.Add("Partner");
		
		If Not ValueIsFilled(Partner) Then
			ErrorText = NStr("vi = 'Chưa điền trường ""Bên đặt gia công""';
							|ru = 'Поле ""Давалец"" не заполнено';
							|en = 'The ""Material provider"" field is not filled'; fa = 'The ""Material provider"" field is not filled';
							|it = 'Campo ""Fornitore"" non compilato';
							|pl = 'Pole ""Właściciel surowców"" nie jest wypełnione';
							|tr = '""Malzeme tedarikçisi"" alanı doldurulmamış'");
			Common.MessageToUser(ErrorText, ThisObject, "Partner",, Cancel);
		EndIf;
		
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
		ItemsAndDimensionsSelectionParameters);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	RoundingParameters = Undefined;
	If BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		Or BusinessOperation = Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		
		RoundingParameters = ProductsServer.ParametersForCheckingFillingQuantity();
		RoundingParameters.AdditionalFields.Insert("Warehouse", "Goods.Warehouse");
		RoundingParameters.ConditionForSelectingRowsByAdditionalFields =
			"(VALUETYPE(Goods.Warehouse) <> TYPE(Catalog.Warehouses)
			|OR " + ProductionServer.ConditionForSelectingRowsForRounding("Goods", "Warehouse") + ")";
		
	EndIf;
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
		ThisObject,
		Documents.ReportOnVMIAdjustment);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	DocumentAmount = Goods.Total("Sum");
	
	If WriteMode = DocumentWriteMode.Posting Then
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	//Setting up accounting accounts
	GLAccountSettingsServer.BeforeWrite(ThisObject,
		Documents.ReportOnVMIAdjustment.AccountingAccountSettings_(BusinessOperation));
	// Selection of articles and analytics.
	ItemsAndDimensionsSelectionParameters =
		Documents.ReportOnVMIAdjustment.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;

	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	ReportOnVMIAdjustmentLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReportOnVMIAdjustmentLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReportOnVMIAdjustmentLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReportOnVMIAdjustmentLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	InventoryOwnerAttributesAreSpecifiedManually = False;
	
	If InventoryKinds.Count() > 0 Then
		InventoryKinds.Clear();
	EndIf;
	
	TMCommonUseClientServer.FillInCollectionPropertyValues(Goods, 0, "AmountARAP");
	
	ReportOnVMIAdjustmentLocalization.OnCopy(ThisObject, CopiedObject);
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		Query = New Query();
		Query.Text = 
		"SELECT
		|	InventoryKinds.Ref AS InventoryOwnerAttribute
		|INTO InventoryTable
		|FROM
		|	Catalog.InventoryKinds AS InventoryKinds
		|WHERE
		|	InventoryKinds.GoodsOwner = &Partner
		|	AND InventoryKinds.Organization = &Organization
		|	AND InventoryKinds.Contract = &Contract
		|	AND CASE
		|		WHEN &BusinessOperation IN(
		|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider),
		|				VALUE(Enum.BusinessTransactions.ProviderGoodsWriteOffAsExpenses))
		|			THEN InventoryKinds.InventoryType IN (
		|								VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
		|								VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
		|								VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider))
		|		WHEN TRUE
		|			THEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
		|	  END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToWriteOff.ItemsLocationAttributes AS Dimension,
		|	GoodsToWriteOff.ToRegisterGoodsIssueBalance AS Count
		|INTO TTItemsToBeDebited
		|FROM
		|	AccumulationRegister.CompanyGoods.Balance(
		|			,
		|			Organization = &Organization
		|				AND InventoryOwnerAttribute IN
		|					(SELECT
		|						InventoryTable.InventoryOwnerAttribute
		|					FROM
		|						InventoryTable AS InventoryTable)) AS GoodsToWriteOff
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Goods.Dimension.Products AS Products,
		|	Goods.Dimension.Characteristic AS Characteristic,
		|	Goods.Dimension.Series AS Series,
		|	Goods.Dimension.Purpose AS Purpose,
		|	Goods.Dimension.Contract AS Contract,
		|	Goods.Dimension.Partner AS Custodian,
		|	Goods.Dimension.Counterparty AS Counterparty,
		|	Goods.Dimension.WarehouseArea AS Warehouse,
		|	Goods.Dimension.Department AS Department,
		|	Goods.Dimension.StorageType AS StorageType,
		|	Goods.Count AS Count
		|FROM
		|	TTItemsToBeDebited AS Goods";
		
		Query.SetParameter("Contract", FillingData.Contract);
		Query.SetParameter("Partner", FillingData.Partner);
		Query.SetParameter("Organization", FillingData.Organization);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		ProductsToFillIn_ = Query.Execute().Unload();
		
		Goods.Load(ProductsToFillIn_);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.ReportOnVMIAdjustment);
		ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
		
		StructureOfActions = New Structure;
		
		StructureOfActions.Insert("FillInProductNameOfProductPartner", FillingData.Partner);
		StructureOfActions.Insert("CheckFillPackageByOwner");
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
		
		FillInDefaultPurchaseConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument()
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	If ValueIsFilled(Contract)
	   And Common.ObjectAttributeValue(Contract, "BusinessOperation") =
											TollingSchemeClientServer.ContractBusinessTransaction() Then
		Department = Common.ObjectAttributeValue(Contract, "Department");
	Else
		Department = SettingsValueCached.UserDivision(Manager, Department);
	EndIf;
	Operations = New Array;
	Operations.Add(Enums.BusinessTransactions.ConsumptionOfGoodsReceivedAsExpenses);
	Operations.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
	If Operations.Find(BusinessOperation) <> Undefined Then
		
		If Not ValueIsFilled(CompanyBankAccount) Or Not ValueIsFilled(CounterpartyBankAccount) Then
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
				?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
				?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
		EndIf;
		
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			CompanyBankAccount);
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount, PaymentMethod);
		
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

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager  = TemporaryDocumentDataTables();
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or InventoriesServer.CheckProductChangesByQuantity(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(
			ThisObject, TempTablesManager, Cancel, FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count");
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.NameOfRemainderTable = "ItemsAcceptedForWriteOff";
	
	FillParameters.SelectTypesOfStocksForIntercampany = False;
	
	FillParameters.ReportFillingErrors = True;
	FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
	FillParameters.IgnoreOrganizationSProductControlIfFillingInByDefaultIsProhibited = True;
	
	FillParameters.ReversedDocument = ReversedDocument;
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	SelectionOfStockTypes_.Organization = Organization;
	SelectionOfStockTypes_.GoodsOwner = Partner;
	SelectionOfStockTypes_.Counterparty = Counterparty;
	SelectionOfStockTypes_.Contract = Contract;
	If BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider
		And BusinessOperation <> Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses Then
		SelectionOfStockTypes_.InventoryType = Enums.InventoryTypes.GoodsInStorageWithRightToSell;
	Else
		SelectionOfStockTypes_.InventoryType = New Array;
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.MaterialOfMaterialProvider);
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.SemiFinishedProductOfMaterialProvider);
		SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.ProductsOfMaterialProvider);
	EndIf;
	Return FillParameters;
	
EndFunction

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, Partner, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

// The procedure fills in additional columns in the table part of the document's' types of items'.
//
Procedure FillInAdditionalStockTypes() Export
	
	UnloadedColumns = "ItemsLocationAttributes, Package, NumberOfPackages, Count, Price, Sum,
						|AmountARAP";
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy("ItemsLocationAttributes, Package, Price",
							"Count, NumberOfPackages, Sum, AmountARAP");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		GoodsQuantity  = RowOfGoods.Count;
		NumberOfPackages = RowOfGoods.NumberOfPackages;
		
		Sum                     = RowOfGoods.Sum;
		AmountOfMutualSettlementsOfLine = RowOfGoods.AmountARAP;
		
		If GoodsQuantity = 0 Then
			Continue;
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Package = RowOfGoods.Package;
			NewRow.Price     = RowOfGoods.Price;
			
			NewRow.Count = Count;
			
			If GoodsQuantity <> 0 Then
				NewRow.NumberOfPackages = Count * NumberOfPackages / GoodsQuantity;
				
				NewRow.Sum               = Count * Sum / GoodsQuantity;
				NewRow.AmountARAP = Count * AmountOfMutualSettlementsOfLine / GoodsQuantity;
			EndIf;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			
			GoodsQuantity  = GoodsQuantity - NewRow.Count;
			NumberOfPackages = NumberOfPackages - NewRow.NumberOfPackages;
			
			Sum                     = Sum - NewRow.Sum;
			AmountOfMutualSettlementsOfLine = AmountOfMutualSettlementsOfLine - NewRow.AmountARAP;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Filter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(Filter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.ReportOnVMIAdjustment.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.ReportOnVMIAdjustment.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Undefined,
																		Undefined,
																		Undefined,
																		Undefined);
	
	WarehouseFieldText =
		"CASE
		|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.Warehouse)
		|		THEN Collection.Warehouse
		|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.CounterpartyContract)
		|		THEN Collection.Contract
		|	WHEN Collection.StorageType = VALUE(Enum.StorageLocationTypes.Department)
		|		THEN Collection.Department
		|	ELSE UNDEFINED
		|END";
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("OwnGoods", New Structure("FieldText", WarehouseFieldText));
	FieldsNames.Insert("ReusablePackage", New Structure("FieldText", WarehouseFieldText));
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
