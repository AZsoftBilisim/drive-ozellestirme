#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the purchase of goods by the custodian.
//
// Parameters:
//	SalesTermsAndConditions - Structure - data to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Currency) Then
		Currency = SalesTermsAndConditions.Currency;
	EndIf;
	If ValueIsFilled(SalesTermsAndConditions.ARAPCurrency) Then
		ARAPCurrency = SalesTermsAndConditions.ARAPCurrency;
	EndIf;
	
	AttributesNames = 
		"LineOfBusiness,
		|PriceIncludesVAT,
		|PaymentMethod";
	
	FillPropertyValues(ThisObject, SalesTermsAndConditions, AttributesNames);
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization)
							And SalesTermsAndConditions.Organization <> Organization;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty)
			And SalesTermsAndConditions.Counterparty <> Counterparty Then
			
			Counterparty = SalesTermsAndConditions.Counterparty;
			
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined
		And SalesTermsAndConditions.ContractsAreUsed Then
		
		Handler = Documents.RedemptionOfGoodsByCustodian.ActionHandler(BusinessOperation);
		Contract = Handler.GetDefaultContract(ThisObject);
		ContractDetails_ = New Structure;
		ContractDetails_.Insert("Currency", "ARAPCurrency");
		ContractDetails_.Insert("ARAPCurrency");
		ContractDetails_.Insert("LineOfBusiness");
		ContractDetails_.Insert("Department");
		Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	EndIf;
	
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(), CompanyBankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	CompleteVATTaxation();
	
EndProcedure

// Fills in the default terms of sale in the product repurchase by the custodian.
//
// Parameters:
//	RecalculatePrices_ - Boolean - True - Indicates the need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultSalesConditions(RecalculatePrices_ = True) Export
	
	Handler = Documents.RedemptionOfGoodsByCustodian.ActionHandler(BusinessOperation);
	
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled (Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.RedemptionOfGoodsByCustodian.EmptyRef());
		FilterParameters.Insert("BusinessTransactions", Handler.ContractBusinessTransaction());
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
									Partner, FilterParameters, Handler.CustomerAgreementsAreApplicable());
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				If ToUseTermsOfSales
					And RecalculatePrices_ Then
					
					FillInPricesBySalesConditions();
					
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
				
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
			
			Contract = Handler.GetDefaultContract(ThisObject);
			
			CompleteVATTaxation();
			
			SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
			ParametersOfAccount, CounterpartyBankAccount);
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sale under the agreement in the transfer of goods to the custodian.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	FillInPricesBySalesConditions();
	
EndProcedure

// This function generates temporary document data
//
// Returns:
// 		TempTablesManager - temporary table Manager
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	&BusinessOperation AS BusinessOperation,
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
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON (BusinessStructure.Ref = &Department)
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON (SalesOpportunitiesToCustomer.Ref = &SalesOpportunity)
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
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
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Sum + TableOfGoods.VATAmount * &PriceIncludesVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&SalesOpportunity AS SalesOpportunity
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	0 AS CommissionAmount,
	|	0 AS AmountVATRemuneration,
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|	FALSE AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber AS CCDNumber
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP
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
	|	Dimension.StorageLocation AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	UNDEFINED AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	&SalesOpportunity AS SalesOpportunity,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	&InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP
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
	
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Date", Date);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("Partner", Partner);
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("Terms", Terms);
	Query.SetParameter("Contract", Contract);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("Department", Department);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers", GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
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
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.RedemptionOfGoodsByCustodian - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.RedemptionOfGoodsByCustodian.CollectionOfTabularPartsOfGoods.
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

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = GetDocumentAmount();
	
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
		
	RegistrationParameters = Documents.RedemptionOfGoodsByCustodian.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	RedemptionOfGoodsByCustodianLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
		
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.RedemptionOfGoodsFromStorage") Then
		FillInBasedOnRedemptionOfGiverSGoods(FillingData);
	EndIf;
	
	InitializeSalesConditions();
	InitializeDocument(FillingData);
	FillOutBankAccounts();
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	RedemptionOfGoodsByCustodianLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
 	ARAPAccountingServer.Filling(ThisObject, FillingData);
	 		
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
		
	NotCheckedAttributeArray.Add("PaymentDate");
	
	Handler = Documents.RedemptionOfGoodsByCustodian.ActionHandler(BusinessOperation);
	If Not Handler.ToUseTermsOfSales() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If Handler.CustomerAgreementsAreApplicable()
	   And (Not ValueIsFilled(Terms)
		  Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed")) Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	ProductsServer.CheckSeriesCompletion(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RedemptionOfGoodsByCustodian),
		Cancel,
		NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	If GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers")
		And Not BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller
		And True Then
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel);
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	RedemptionOfGoodsByCustodianLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RedemptionOfGoodsByCustodianLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(Ref);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RedemptionOfGoodsByCustodianLocalization.UndoPosting(ThisObject, Cancel);
	
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(Ref);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	InventoryOwnerAttributesAreSpecifiedManually	= False;
	DocumentBasis			= Undefined;
	
	ARAPAccountingServer.OnCopy(ThisObject);	
	
	If ValueIsFilled(CopiedObject.PaymentDate) Then
		PaymentDate = CurrentSessionDate() + (BegOfDay(CopiedObject.PaymentDate) - BegOfDay(CopiedObject.Date));
	EndIf;
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	RedemptionOfGoodsByCustodianLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
	If FillingData.Property("Organization") Then
		Organization = FillingData.Organization;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Author = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
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
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

Procedure CompleteVATTaxation()
	
	FillParameters = Documents.RedemptionOfGoodsByCustodian.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

#Region FillingInRedemptionOfGiverSGoods

Procedure FillInBasedOnRedemptionOfGiverSGoods(FillingStructure)
	
	BusinessOperation = Enums.BusinessTransactions.RedemptionOfGoodsByToller;
	
	Query = New Query;
	Query.SetParameter("Basis", FillingStructure);
	Query.Text = QueryTextFillInBasedOnRedemptionOfGiverSGoods();
	
	Result = Query.ExecuteBatch();
	HeaderAttributes = Result[Result.UBound() - 1].Select();
	GoodsTable  = Result[Result.UBound()].Unload();
	
	If HeaderAttributes.Next() Then
		FillPropertyValues(ThisObject, HeaderAttributes);
	EndIf;
	
	Goods.Load(GoodsTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages", BatchProcessingOfTablePartClientServer.StructureOfRecalculationOfNumberOfPackages());
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RedemptionOfGoodsByCustodian));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
EndProcedure

Function QueryTextFillInBasedOnRedemptionOfGiverSGoods()
	
	QueryText =
	"SELECT ALLOWED
	|	CatCompanies.Ref           AS Organization,
	|	CatCounterparties.Ref           AS Counterparty,
	|	CatCounterparties.Partner          AS Partner,
	|	CatContracts.Ref              AS Contract,
	|	CASE
	|		WHEN CatContracts.LineOfBusiness IS NULL
	|			THEN RedemptionOfGoodsFromStorage.LineOfBusiness
	|		ELSE CatContracts.LineOfBusiness
	|	END                                 AS LineOfBusiness,
	|	RedemptionOfGoodsFromStorage.Currency AS Currency,
	|	CASE
	|		WHEN CatContracts.ARAPCurrency IS NULL
	|			THEN RedemptionOfGoodsFromStorage.ARAPCurrency
	|		ELSE CatContracts.ARAPCurrency
	|	END                                 AS ARAPCurrency,
	|	RedemptionOfGoodsFromStorage.SalesOpportunity AS SalesOpportunity,
	|	RedemptionOfGoodsFromStorage.VATTaxation AS VATTaxation,
	|	RedemptionOfGoodsFromStorage.PriceIncludesVAT    AS PriceIncludesVAT,
	|	RedemptionOfGoodsFromStorage.Ref AS DocumentBasis
	|FROM
	|	Document.RedemptionOfGoodsFromStorage AS RedemptionOfGoodsFromStorage
	|	
	|	LEFT JOIN Catalog.Counterparties AS MaterialProvider
	|	ON MaterialProvider.Ref = RedemptionOfGoodsFromStorage.Counterparty
	|	
	|	LEFT JOIN Catalog.Companies AS CatCompanies
	|	ON CatCompanies.TIN = MaterialProvider.TIN
	|	AND CatCompanies.CRTR = MaterialProvider.CRTR
	|	AND NOT CatCompanies.DeletionMark
	|	
	|	LEFT JOIN Catalog.Companies AS Toller
	|	ON Toller.Ref = RedemptionOfGoodsFromStorage.Organization
	|	
	|	LEFT JOIN Catalog.Counterparties AS CatCounterparties
	|	ON CatCounterparties.TIN = Toller.TIN
	|	AND CatCounterparties.CRTR = Toller.CRTR
	|	AND NOT CatCounterparties.DeletionMark
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS MaterialProviderContract
	|	ON MaterialProviderContract.Ref = RedemptionOfGoodsFromStorage.Contract
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CatContracts
	|	ON CatContracts.Organization = CatCompanies.Ref
	|	AND CatContracts.Counterparty = CatCounterparties.Ref
	|	AND CatContracts.Number = MaterialProviderContract.Number
	|	AND CatContracts.Date = MaterialProviderContract.Date
	|	AND CatContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
	|	AND NOT CatContracts.DeletionMark
	|
	|WHERE
	|	RedemptionOfGoodsFromStorage.Ref = &Basis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	TableOfGoods.Products      AS Products,
	|	TableOfGoods.Characteristic    AS Characteristic,
	|	TableOfGoods.Series             AS Series,
	|	SUM(TableOfGoods.Count) AS Count,
	|	TableOfGoods.Price              AS Price,
	|	SUM(TableOfGoods.Sum)      AS Sum
	|FROM
	|	Document.RedemptionOfGoodsFromStorage.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref = &Basis
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	TableOfGoods.Price
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion
Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
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

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation, Partner, Contract, VATTaxation";
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.AmountARAP AS AmountARAP
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.AmountARAP AS AmountARAP
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|";
	Result_Query = Query.Execute();
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Procedure FillInAdditionalStockTypes()
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, Package";
	NamesOfSummationColumns	= "Count, NumberOfPackages, AmountARAP";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine_	= RowOfGoods.Count;
		NumberOfPackagesPerLine_	= RowOfGoods.NumberOfPackages;
		AmountOfSettlementsByLine	= RowOfGoods.AmountARAP;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			QuantityPerRow = Min(NumberOfProductsPerLine_, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			
			NewRow.Package			= RowOfGoods.Package;
			NewRow.NumberOfPackages	= ?(NumberOfProductsPerLine_ <> 0,
												NumberOfPackagesPerLine_ * QuantityPerRow / NumberOfProductsPerLine_,
												0);
			NewRow.Count			= QuantityPerRow;
			NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			NewRow.AmountIncludingVAT			= ?(InventoryLine.Count <> 0,
												QuantityPerRow * InventoryLine.AmountIncludingVAT / InventoryLine.Count,
												0);
			NewRow.VATAmount			= ?(InventoryLine.Count <> 0,
												QuantityPerRow * InventoryLine.VATAmount / InventoryLine.Count,
												0);
			NewRow.AmountARAP	= ?(InventoryLine.Count <> 0,
												QuantityPerRow * AmountOfSettlementsByLine / NumberOfProductsPerLine_,
												0);
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
			InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
			
			NumberOfProductsPerLine_	= NumberOfProductsPerLine_ - NewRow.Count;
			NumberOfPackagesPerLine_	= NumberOfPackagesPerLine_ - NewRow.NumberOfPackages;
			AmountOfSettlementsByLine	= AmountOfSettlementsByLine - NewRow.AmountARAP;
			
			If NumberOfProductsPerLine_ = 0 Then
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
	
	TempTablesManager		= TemporaryDocumentDataTables();
	RefillInventoryKinds	= InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
								"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
		FillInAdditionalStockTypes();
		
	EndIf;
	
EndProcedure

// Returns:
// 	See InventoriesServer.ParametersForFillingInventoryTypes
// 
Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.RedemptionOfGoodsByCustodian.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ThisObject);

EndFunction

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.RedemptionOfGoodsByCustodian.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.RedemptionOfGoodsByCustodian.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Contract,
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInPricesBySalesConditions()
	
	If Goods.Count() = 0
		And Not ValueIsFilled(Terms) Then
		
		Return;
		
	EndIf;
	
	FieldsNames = "PriceKind, Price, VATRate";
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields",     FieldsNames);
	FillParameters.Insert("Date",               Date);
	FillParameters.Insert("Organization",        Organization);
	FillParameters.Insert("Currency",             Currency);
	FillParameters.Insert("Terms",         Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount",  StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("ClearAmountOfSettlements");
	
	EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
	
EndProcedure

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
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
