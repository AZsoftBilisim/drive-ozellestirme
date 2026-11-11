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
				EndIf;
				
			ElsIf PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
				
				If SeparatePurchaseOperations.Find(Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery) <> Undefined Then
					OperationByAgreement = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery;
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
					
					PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(Services, Undefined, FillParameters, ActionsWithStrings);
					
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
			
			BusinessTransactions = PurchasesServer.EconomicOperationsOfSeparatePurchase("Document.ReceiptOfServicesToBusinessUnit",
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

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "Services";
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel, CheckParameters);
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		ItemsAndDimensionsSelectionParameters = Documents.ReceiptOfServicesToBusinessUnit.ItemsAndDimensionsSelectionParameters(BusinessOperation, Contract);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName = "Services";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	ReceiptOfServicesToBusinessUnitLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	FillInDataType = TypeOf(FillingData);
	PropertiesToExclude = "";
	EconomicOperationOfAcceptance = Undefined;
	
	If TypeOf(FillingData) = Type("Structure") And FillingData.Property("DocumentDate") Then
		Date = FillingData.DocumentDate;
	EndIf;
	
	If FillInDataType = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And ValueIsFilled(FillingData.DocumentBasis) Then
		
		FillInUsingInvoice = ?(FillingData.Property("FillInUsingInvoice"), FillingData.FillInUsingInvoice, False);;
		FillingData.Property("PropertiesToExclude", PropertiesToExclude);
		FillingData.Property("EconomicOperationOfAcceptance", EconomicOperationOfAcceptance);
		BaseValueType = TypeOf(FillingData.DocumentBasis);
		
		If BaseValueType = Type("DocumentRef.PurchaseOrder") Then
	 		FillingDataContract = Common.ObjectAttributeValue(FillingData.DocumentBasis, "Contract");
			
 			If BasisContract(FillingDataContract) Then
				FillInDocumentOnBasisOfContract(FillingDataContract, EconomicOperationOfAcceptance);
			Else
				FillInDocumentBasedOnOrderToSupplier(FillingData.DocumentBasis, FillInUsingInvoice, EconomicOperationOfAcceptance);
			EndIf;
		ElsIf BaseValueType = Type("DocumentRef.VendorInvoice") Then
			FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData.DocumentBasis, PropertiesToExclude, EconomicOperationOfAcceptance);
		ElsIf BaseValueType = Type("CatalogRef.CounterpartyContracts") Then
			FillInDocumentOnBasisOfContract(FillingData.DocumentBasis, EconomicOperationOfAcceptance);
		EndIf;
	
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
	
 		FillingDataContract = Common.ObjectAttributeValue(FillingData, "Contract");
 		If BasisContract(FillingDataContract) Then
			FillInDocumentOnBasisOfContract(FillingDataContract);
		Else
			FillInDocumentBasedOnOrderToSupplier(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then
		
		FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData, PropertiesToExclude);
		
	ElsIf FillInDataType = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	EndIf;
	
	ResponsiblePersonsServer.InstallManager(ThisObject, ReferenceOrder);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	ReceiptOfServicesToBusinessUnitLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode); 
	
	DocumentAmount = Services.Total("AmountIncludingVAT");
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Services");
	
	ReceiptOfServicesToBusinessUnitLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	ReceiptOfServicesToBusinessUnitLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	ReceiptOfServicesToBusinessUnitLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	For Each CurRow In Services Do
		
		CurRow.LotVendorAttributes = Catalogs.KeysForLotVendorAttributes.EmptyRef();
		
	EndDo;
	
	CompleteVATTaxation();
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfActions.Insert("AdjustVATRate", ParametersForFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Services, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Services,
		CachedValues);
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Services");
	
	ReceiptOfServicesToBusinessUnitLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	ReceiptOfServicesToBusinessUnitLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnOrderToSupplier(DocumentBasis, FillInUsingInvoice = False, EconomicOperationOfAcceptance = Undefined)
	
	CheckContractProcurementOption(DocumentBasis);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PurchaseOrder.Ref AS Ref,
	|	PurchaseOrder.Terms AS Terms,
	|	PurchaseOrder.Partner AS Partner,
	|	PurchaseOrder.Counterparty AS Counterparty,
	|	PurchaseOrder.Organization AS Organization,
	|	PurchaseOrder.Status AS DocumentStatus,
	|	PurchaseOrder.Contract AS Contract,
	|	PurchaseOrder.SalesOpportunity AS SalesOpportunity,
	|	PurchaseOrder.Currency AS Currency,
	|	ISNULL(Terms1.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
	|	PurchaseOrder.PriceIncludesVAT AS PriceIncludesVAT,
	|	PurchaseOrder.VATTaxation AS VATTaxation,
	|	PurchaseOrder.PurchaseForActivity AS VATActivityType,
	|	PurchaseOrder.LineOfBusiness AS LineOfBusiness,
	|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN PurchaseOrder.Status IN (VALUE(Enum.PurchaseOrderStatuses.NotApproved), VALUE(Enum.PurchaseOrderStatuses.Approved))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus,
	|	PurchaseOrder.BusinessOperation AS EconomicOperationOfAcceptance
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
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicesForAdmission.DocumentInflow AS DocumentInflow,
	|	ServicesForAdmission.Products AS Products,
	|	ServicesForAdmission.Characteristic AS Characteristic,
	|	ServicesForAdmission.Purpose AS Purpose,
	|	SUM(CASE
	|			WHEN CAST(ServicesForAdmission.DocumentInflow AS Document.PurchaseOrder).Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
	|				AND NOT CAST(ServicesForAdmission.DocumentInflow AS Document.PurchaseOrder).Contract.ServiceReceiptOption IN (
	|								VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|								VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
	|				THEN ServicesForAdmission.ToRegisterInvoicesByReferenceBalance
	|			ELSE ServicesForAdmission.ToRegisterReceiptsByReferenceBalance
	|		END) AS Count
	|INTO TTServices
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|				AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))) AS ServicesForAdmission
	|WHERE
	|	&FillByOrderDocument
	|	AND CASE
	|			WHEN CAST(ServicesForAdmission.DocumentInflow AS Document.PurchaseOrder).Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
	|				AND NOT CAST(ServicesForAdmission.DocumentInflow AS Document.PurchaseOrder).Contract.ServiceReceiptOption IN (
	|								VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|								VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
	|				THEN ServicesForAdmission.ToRegisterInvoicesByReferenceBalance > 0
	|			ELSE ServicesForAdmission.ToRegisterReceiptsByReferenceBalance > 0
	|		END
	|
	|GROUP BY
	|	ServicesForAdmission.Characteristic,
	|	ServicesForAdmission.Purpose,
	|	ServicesForAdmission.Products,
	|	ServicesForAdmission.DocumentInflow
	|
	|UNION ALL
	|
	|SELECT
	|	ServicesForAdmission.DocumentInflow,
	|	ServicesForAdmission.Products,
	|	ServicesForAdmission.Characteristic,
	|	ServicesForAdmission.Purpose,
	|	SUM(ServicesForAdmission.ToRegisterReceiptsByInvoicesBalance)
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &DocumentBasis
	|				AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))) AS ServicesForAdmission
	|WHERE
	|	&FillInUsingInvoice
	|	AND ServicesForAdmission.ToRegisterReceiptsByInvoicesBalance > 0
	|
	|GROUP BY
	|	ServicesForAdmission.Purpose,
	|	ServicesForAdmission.Characteristic,
	|	ServicesForAdmission.Products,
	|	ServicesForAdmission.DocumentInflow
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOrderGoods.Ref,
	|	PurchaseOrderGoods.Products,
	|	PurchaseOrderGoods.Characteristic,
	|	PurchaseOrderGoods.Purpose,
	|	SUM(PurchaseOrderGoods.NumberOfPackages)
	|FROM
	|	Document.PurchaseOrder.Goods AS PurchaseOrderGoods
	|WHERE
	|	PurchaseOrderGoods.Ref = &DocumentBasis
	|	AND PurchaseOrderGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|	AND PurchaseOrderGoods.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed)
	|	AND NOT PurchaseOrderGoods.Ref.Contract.ServiceReceiptOption IN (
	|		VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|		VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
	|
	|GROUP BY
	|	PurchaseOrderGoods.Purpose,
	|	PurchaseOrderGoods.Products,
	|	PurchaseOrderGoods.Characteristic,
	|	PurchaseOrderGoods.Ref
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PackagingOfGoods.DocumentInflow AS DocumentInflow,
	|	PackagingOfGoods.Products AS Products,
	|	PackagingOfGoods.Characteristic AS Characteristic,
	|	PackagingOfGoods.Purpose AS Purpose,
	|	PackagingOfGoods.Department AS Department,
	|	PackagingOfGoods.ToExpenseAs AS ToExpenseAs,
	|	PackagingOfGoods.ExpenseItem AS ExpenseItem,
	|	PackagingOfGoods.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(PackagingOfGoods.Count) AS Count
	|INTO TTPackagingOfGoods
	|FROM
	|	(SELECT
	|		ServicesForAdmission.DocumentInflow AS DocumentInflow,
	|		ServicesForAdmission.Products AS Products,
	|		ServicesForAdmission.Characteristic AS Characteristic,
	|		ServicesForAdmission.Purpose AS Purpose,
	|		GoodsFromOrder.Department AS Department,
	|		GoodsFromOrder.ToExpenseAs AS ToExpenseAs,
	|		GoodsFromOrder.ExpenseItem AS ExpenseItem,
	|		GoodsFromOrder.DimensionOfExpenses AS DimensionOfExpenses,
	|		SUM(GoodsFromOrder.Count) AS Count
	|	FROM
	|		TTServices AS ServicesForAdmission
	|			LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
	|			ON ServicesForAdmission.DocumentInflow = GoodsFromOrder.Ref
	|				AND ServicesForAdmission.Products = GoodsFromOrder.Products
	|				AND ServicesForAdmission.Characteristic = GoodsFromOrder.Characteristic
	|				AND ServicesForAdmission.Purpose = GoodsFromOrder.Purpose
	|	WHERE
	|		NOT ISNULL(GoodsFromOrder.Canceled, FALSE)
	|	
	|	GROUP BY
	|		ServicesForAdmission.DocumentInflow,
	|		ServicesForAdmission.Products,
	|		ServicesForAdmission.Characteristic,
	|		ServicesForAdmission.Purpose,
	|		GoodsFromOrder.Department,
	|		GoodsFromOrder.ToExpenseAs,
	|		GoodsFromOrder.ExpenseItem,
	|		GoodsFromOrder.DimensionOfExpenses
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ServicesForAdmission.DocumentInflow,
	|		ServicesForAdmission.Products,
	|		ServicesForAdmission.Characteristic,
	|		ServicesForAdmission.Purpose,
	|		AdmissionServices.Department,
	|		AdmissionServices.ToExpenseAs,
	|		AdmissionServices.ExpenseItem,
	|		AdmissionServices.DimensionOfExpenses,
	|		-SUM(AdmissionServices.Count)
	|	FROM
	|		TTServices AS ServicesForAdmission
	|			LEFT JOIN Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServicesToBusinessUnit
	|			ON ServicesForAdmission.DocumentInflow = ReceiptOfServicesToBusinessUnit.ReferenceOrder
	|			LEFT JOIN Document.ReceiptOfServicesToBusinessUnit.Services AS AdmissionServices
	|			ON (ReceiptOfServicesToBusinessUnit.Ref = AdmissionServices.Ref)
	|				AND ServicesForAdmission.Products = AdmissionServices.Products
	|				AND ServicesForAdmission.Characteristic = AdmissionServices.Characteristic
	|				AND ServicesForAdmission.Purpose = AdmissionServices.Purpose
	|			LEFT JOIN InformationRegister.DocumentsRegistry AS RegisterOfDocumentsStorno
	|			ON ReceiptOfServicesToBusinessUnit.Ref = RegisterOfDocumentsStorno.ReversedDocument
	|				AND RegisterOfDocumentsStorno.RefType = &RefType
	|				AND RegisterOfDocumentsStorno.Posted
	|				AND NOT RegisterOfDocumentsStorno.AdditionalRecord
	|				AND NOT VALUETYPE(RegisterOfDocumentsStorno.Ref)= TYPE(Document.ReversingEntry)
	|	WHERE
	|		ISNULL(ReceiptOfServicesToBusinessUnit.Posted, FALSE)
	|		AND RegisterOfDocumentsStorno.Ref IS NULL
	|	
	|	GROUP BY
	|		ServicesForAdmission.DocumentInflow,
	|		ServicesForAdmission.Products,
	|		ServicesForAdmission.Characteristic,
	|		ServicesForAdmission.Purpose,
	|		AdmissionServices.Department,
	|		AdmissionServices.ToExpenseAs,
	|		AdmissionServices.ExpenseItem,
	|		AdmissionServices.DimensionOfExpenses) AS PackagingOfGoods
	|
	|GROUP BY
	|	PackagingOfGoods.DocumentInflow,
	|	PackagingOfGoods.Products,
	|	PackagingOfGoods.Characteristic,
	|	PackagingOfGoods.Purpose,
	|	PackagingOfGoods.Department,
	|	PackagingOfGoods.ToExpenseAs,
	|	PackagingOfGoods.ExpenseItem,
	|	PackagingOfGoods.DimensionOfExpenses
	|
	|HAVING
	|	SUM(PackagingOfGoods.Count) > 0
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Department,
	|	ToExpenseAs,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	ServicesForAdmission.DocumentInflow AS DocumentInflow,
	|	ServicesForAdmission.Products AS Products,
	|	ServicesForAdmission.Characteristic AS Characteristic,
	|	ServicesForAdmission.Purpose AS Purpose,
	|	ServicesForAdmission.Department AS Department,
	|	ServicesForAdmission.ToExpenseAs AS ToExpenseAs,
	|	ServicesForAdmission.ExpenseItem AS ExpenseItem,
	|	ServicesForAdmission.DimensionOfExpenses AS DimensionOfExpenses,
	|	ServicesForAdmission.Count AS Count,
	|	GoodsFromOrder.Price AS Price,
	|	GoodsFromOrder.VATRate AS VATRate,
	|	GoodsFromOrder.LineNumber AS LineNumber
	|INTO TTPricesOfGoods
	|FROM
	|	TTPackagingOfGoods AS ServicesForAdmission
	|		LEFT JOIN Document.PurchaseOrder.Goods AS GoodsFromOrder
	|		ON ServicesForAdmission.DocumentInflow = GoodsFromOrder.Ref
	|			AND ServicesForAdmission.Products = GoodsFromOrder.Products
	|			AND ServicesForAdmission.Characteristic = GoodsFromOrder.Characteristic
	|			AND ServicesForAdmission.Purpose = GoodsFromOrder.Purpose
	|			AND ServicesForAdmission.Department = GoodsFromOrder.Department
	|			AND ServicesForAdmission.ToExpenseAs = GoodsFromOrder.ToExpenseAs
	|			AND ServicesForAdmission.ExpenseItem = GoodsFromOrder.ExpenseItem
	|			AND ServicesForAdmission.DimensionOfExpenses = GoodsFromOrder.DimensionOfExpenses
	|WHERE
	|	NOT ISNULL(GoodsFromOrder.Canceled, FALSE)
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Department,
	|	ToExpenseAs,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicesForAdmission.DocumentInflow AS DocumentInflow,
	|	ServicesForAdmission.Products AS Products,
	|	ServicesForAdmission.Characteristic AS Characteristic,
	|	ServicesForAdmission.Purpose AS Purpose,
	|	ServicesForAdmission.Department AS Department,
	|	ServicesForAdmission.ToExpenseAs AS ToExpenseAs,
	|	ServicesForAdmission.ExpenseItem AS ExpenseItem,
	|	ServicesForAdmission.DimensionOfExpenses AS DimensionOfExpenses,
	|	COUNT(DISTINCT ServicesForAdmission.Price) AS NumberOfPrices,
	|	COUNT(DISTINCT ServicesForAdmission.VATRate) AS NumberOfVATRates
	|INTO TTProductPricesGrouping
	|FROM
	|	TTPricesOfGoods AS ServicesForAdmission
	|
	|GROUP BY
	|	ServicesForAdmission.DocumentInflow,
	|	ServicesForAdmission.Products,
	|	ServicesForAdmission.Characteristic,
	|	ServicesForAdmission.Purpose,
	|	ServicesForAdmission.Department,
	|	ServicesForAdmission.ToExpenseAs,
	|	ServicesForAdmission.ExpenseItem,
	|	ServicesForAdmission.DimensionOfExpenses
	|
	|INDEX BY
	|	DocumentInflow,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Department,
	|	ToExpenseAs,
	|	ExpenseItem,
	|	DimensionOfExpenses
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableReferenceOrder.Ref AS Ref,
	|	TableReferenceOrder.Terms AS Terms,
	|	TableReferenceOrder.Partner AS Partner,
	|	TableReferenceOrder.Counterparty AS Counterparty,
	|	TableReferenceOrder.Organization AS Organization,
	|	TableReferenceOrder.DocumentStatus AS DocumentStatus,
	|	TableReferenceOrder.Contract AS Contract,
	|	TableReferenceOrder.SalesOpportunity AS SalesOpportunity,
	|	TableReferenceOrder.Currency AS Currency,
	|	TableReferenceOrder.VendorPriceKind AS VendorPriceKind,
	|	TableReferenceOrder.PriceIncludesVAT AS PriceIncludesVAT,
	|	TableReferenceOrder.VATTaxation AS VATTaxation,
	|	TableReferenceOrder.VATActivityType AS VATActivityType,
	|	TableReferenceOrder.LineOfBusiness AS LineOfBusiness,
	|	TableReferenceOrder.ThereAreErrorsPosted AS ThereAreErrorsPosted,
	|	TableReferenceOrder.ThereAreErrorsStatus AS ThereAreErrorsStatus,
	|	TableReferenceOrder.EconomicOperationOfAcceptance AS EconomicOperationOfAcceptance
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Services.DocumentInflow AS DocumentInflow,
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	Services.Purpose AS Purpose,
	|	Services.Department AS Department,
	|	Services.ToExpenseAs AS ToExpenseAs,
	|	Services.ExpenseItem AS ExpenseItem,
	|	Services.DimensionOfExpenses AS DimensionOfExpenses,
	|	SUM(Services.Count) AS Count,
	|	Services.Price AS Price,
	|	Services.VATRate AS VATRate,
	|	MIN(Services.LineNumber) AS LineNumber
	|FROM
	|	(SELECT DISTINCT
	|		ServicesForAdmission.DocumentInflow AS DocumentInflow,
	|		ServicesForAdmission.Products AS Products,
	|		ServicesForAdmission.Characteristic AS Characteristic,
	|		ServicesForAdmission.Purpose AS Purpose,
	|		ServicesForAdmission.Department AS Department,
	|		ServicesForAdmission.ToExpenseAs AS ToExpenseAs,
	|		ServicesForAdmission.ExpenseItem AS ExpenseItem,
	|		ServicesForAdmission.DimensionOfExpenses AS DimensionOfExpenses,
	|		ServicesForAdmission.Count AS Count,
	|		CASE
	|			WHEN ProductPrices.NumberOfPrices = 1
	|				THEN ServicesForAdmission.Price
	|			ELSE 0
	|		END AS Price,
	|		ServicesForAdmission.VATRate AS VATRate,
	|		ServicesForAdmission.LineNumber AS LineNumber
	|	FROM
	|		TTPricesOfGoods AS ServicesForAdmission
	|			LEFT JOIN TTProductPricesGrouping AS ProductPrices
	|			ON ServicesForAdmission.DocumentInflow = ProductPrices.DocumentInflow
	|				AND ServicesForAdmission.Products = ProductPrices.Products
	|				AND ServicesForAdmission.Characteristic = ProductPrices.Characteristic
	|				AND ServicesForAdmission.Purpose = ProductPrices.Purpose
	|				AND ServicesForAdmission.Department = ProductPrices.Department
	|				AND ServicesForAdmission.ToExpenseAs = ProductPrices.ToExpenseAs
	|				AND ServicesForAdmission.ExpenseItem = ProductPrices.ExpenseItem
	|				AND ServicesForAdmission.DimensionOfExpenses = ProductPrices.DimensionOfExpenses) AS Services
	|
	|GROUP BY
	|	Services.DocumentInflow,
	|	Services.Products,
	|	Services.Characteristic,
	|	Services.Purpose,
	|	Services.Price,
	|	Services.VATRate,
	|	Services.Department,
	|	Services.ToExpenseAs,
	|	Services.ExpenseItem,
	|	Services.DimensionOfExpenses
	|
	|ORDER BY
	|	LineNumber";

	Query.SetParameter("DocumentBasis",		DocumentBasis);
	Query.SetParameter("FillByOrderDocument",		Not FillInUsingInvoice);
	Query.SetParameter("FillInUsingInvoice",	FillInUsingInvoice);
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.ReceiptOfServicesToBusinessUnit"));

	QueryResult	= Query.ExecuteBatch();
	Selection				= QueryResult[5].Select();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
	ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Selection.DocumentStatus;
	CheckParameters.ThereAreErrorsPosted = Selection.ThereAreErrorsPosted;
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(DocumentBasis,
																		CheckParameters);
	
	ReferenceOrder	= DocumentBasis;
	
	FillPropertyValues(ThisObject, Selection);
	
	If EconomicOperationOfAcceptance = Undefined Then
		
		EconomicOperationOfAcceptance = Selection.EconomicOperationOfAcceptance;
		
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	SampleProducts_ = QueryResult[6].Select();

	While SampleProducts_.Next() Do
		
		TSRow = Services.Add();
		
		FillPropertyValues(TSRow, SampleProducts_);
		FillInSummaryIndicatorsOfProductLine(TSRow);
		
	EndDo;

	FillThePricesByTermsOfSales(False);

EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(DocumentBasis, PropertiesToExclude, EconomicOperationOfAcceptance = Undefined)
	
	CheckContractProcurementOption(DocumentBasis);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DocumentHeader.Currency AS Currency,
	|	DocumentHeader.Partner AS Partner,
	|	DocumentHeader.Terms AS Terms,
	|	DocumentHeader.Organization AS Organization,
	|	DocumentHeader.Department AS Department,
	|	DocumentHeader.Counterparty AS Counterparty,
	|	DocumentHeader.Manager AS Manager,
	|	DocumentHeader.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentHeader.VATTaxation AS VATTaxation,
	|	DocumentHeader.SalesOpportunity AS SalesOpportunity,
	|	DocumentHeader.Contract AS Contract,
	|	DocumentHeader.LineOfBusiness AS LineOfBusiness,
	|	DocumentHeader.RegisterVendorPrices AS RegisterVendorPrices,
	|	DocumentHeader.ServiceReceiptOption AS ServiceReceiptOption,
	|	DocumentHeader.PurchaseForActivity AS VATActivityType,
	|	DocumentHeader.BusinessOperation AS EconomicOperationOfAcceptance
	|FROM
	|	Document.VendorInvoice AS DocumentHeader
	|WHERE
	|	DocumentHeader.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TSDocument_.Products AS Products,
	|	TSDocument_.PartnerProducts AS PartnerProducts,
	|	TSDocument_.Characteristic AS Characteristic,
	|	TSDocument_.Count AS Count,
	|	TSDocument_.Price AS Price,
	|	TSDocument_.Sum AS Sum,
	|	TSDocument_.VATRate AS VATRate,
	|	TSDocument_.VATAmount AS VATAmount,
	|	TSDocument_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TSDocument_.Purpose AS Purpose,
	|	TSDocument_.Department AS Department,
	|	CASE
	|		WHEN TSDocument_.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN TRUE
	|		ELSE TSDocument_.ToExpenseAs
	|	END AS ToExpenseAs,
	|	TSDocument_.ExpenseItem AS ExpenseItem,
	|	TSDocument_.DimensionOfExpenses AS DimensionOfExpenses
	|FROM
	|	Document.VendorInvoice.Goods AS TSDocument_
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON TSDocument_.Products = CatProducts.Ref
	|			AND (TSDocument_.Products.ItemsType IN (&ItemsType))
	|WHERE
	|	TSDocument_.Ref = &Ref";
		
	ItemsType = New Array;
	ItemsType.Add(Enums.ItemsTypes.OperationService);
	ItemsType.Add(Enums.ItemsTypes.Work_5);
	
	Query.SetParameter("ItemsType", ItemsType);
	Query.SetParameter("Ref", DocumentBasis);
	Query.SetParameter("Period", CurrentSessionDate());
	
	QueryPackage = Query.ExecuteBatch();
	HeaderSelection = QueryPackage[0].Select();
	If HeaderSelection.Next() Then
		
		FillPropertyValues(ThisObject, HeaderSelection,, PropertiesToExclude);
		
		If EconomicOperationOfAcceptance = Undefined Then
			
			EconomicOperationOfAcceptance = HeaderSelection.EconomicOperationOfAcceptance;
			
		EndIf;
		
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
															EconomicOperationOfAcceptance,
															EconomicOperationOfAcceptanceActualReceipt);
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	TSSampling = QueryPackage[1].Select();
	While TSSampling.Next() Do
		
		FillPropertyValues(Services.Add(), TSSampling);
		
	EndDo;
	
	DocumentAmount = Services.Total("Sum");
	
EndProcedure

Procedure FillInDocumentOnBasisOfContract(DocumentBasis, EconomicOperationOfAcceptance = Undefined)
	
	Query = New Query;
	Query.Text =
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
	|	CASE
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEU)
	|			THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseByImport)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
	|		WHEN Contract.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
	|			THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
	|		ELSE Contract.BusinessOperation
	|	END AS EconomicOperationOfAcceptance
	|INTO TTOrder_
	|FROM
	|	Catalog.CounterpartyContracts AS Contract
	|WHERE
	|	Contract.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ServicesForAdmission.Products AS Products,
	|	ServicesForAdmission.Characteristic AS Characteristic,
	|	ServicesForAdmission.Purpose AS Purpose,
	|	ServicesForAdmission.ToRegisterReceiptsByReferenceBalance AS Count,
	|	ServicesForAdmission.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService) AS ToExpenseAs
	|INTO TTServices
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &DocumentBasis
	|	AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND CAST(DocumentInflow AS
	|		Catalog.CounterpartyContracts).OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)) AS
	|		ServicesForAdmission
	|WHERE
	|	ServicesForAdmission.ToRegisterReceiptsByReferenceBalance > 0
	|
	|UNION ALL
	|
	|SELECT
	|	PurchaseOrdersBalance.Products,
	|	PurchaseOrdersBalance.Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef),
	|	PurchaseOrdersBalance.OrderedBalance,
	|	PurchaseOrdersBalance.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, CAST(PurchaseOrder AS
	|		Document.PurchaseOrder).Contract = &DocumentBasis
	|	AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND CAST(PurchaseOrder AS Document.PurchaseOrder).BusinessOperation IN
	|	(VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|	AND CAST(PurchaseOrder AS
	|		Document.PurchaseOrder).Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed)) AS
	|		PurchaseOrdersBalance
	|WHERE
	|	PurchaseOrdersBalance.OrderedBalance > 0
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
	|	TableReferenceOrder.TheseAreAgencyServices AS TheseAreAgencyServices,
	|	TableReferenceOrder.ThereAreErrorsStatus AS ThereAreErrorsStatus,
	|	TableReferenceOrder.EconomicOperationOfAcceptance AS EconomicOperationOfAcceptance,
	|	TableReferenceOrder.Contract.OptionForRegisteringServiceReceiptDocuments AS
	|		OptionForRegisteringServiceReceiptDocuments,
	|	TableReferenceOrder.Contract.ServiceReceiptOption AS ServiceReceiptOption
	|FROM
	|	TTOrder_ AS TableReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableServices.Products AS Products,
	|	TableServices.Characteristic AS Characteristic,
	|	TableServices.Purpose AS Purpose,
	|	SUM(TableServices.Count) AS Count,
	|	TableServices.ToExpenseAs AS ToExpenseAs
	|FROM
	|	TTServices AS TableServices
	|GROUP BY
	|	TableServices.Characteristic,
	|	TableServices.Products,
	|	TableServices.Purpose,
	|	TableServices.ToExpenseAs
	|HAVING
	|	SUM(TableServices.Count) > 0";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection		= QueryResult[2].Select();
	VTServices	= QueryResult[3].Unload();
	
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.Status = Selection.DocumentStatus;
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	CheckParameters.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Selection.Contract, CheckParameters);
	
	If EconomicOperationOfAcceptance = Undefined Then
		
		EconomicOperationOfAcceptance = Selection.EconomicOperationOfAcceptance;
		
	EndIf;
	
	PairsOfSeparatePurchaseOperations = PurchasesServer.PairsOfSeparatePurchaseOperations(True);
	EconomicOperationOfAcceptanceActualReceipt = PairsOfSeparatePurchaseOperations.Get(EconomicOperationOfAcceptance);
	EconomicOperationOfAcceptanceActualReceipt = ?(Not ValueIsFilled(EconomicOperationOfAcceptanceActualReceipt),
		EconomicOperationOfAcceptance,
		EconomicOperationOfAcceptanceActualReceipt);
	
	ReceiptOfServicesNotUsed = Not ValueIsFilled(Selection.OptionForRegisteringServiceReceiptDocuments)
		Or Selection.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed;
	
	If ReceiptOfServicesNotUsed Or ReceiptOfServicesIsUsedUnderContracts(Selection) Then
		ReferenceOrder = DocumentBasis;
	EndIf;
	
	BusinessOperation = EconomicOperationOfAcceptanceActualReceipt;
	
	FillPropertyValues(ThisObject, Selection);
	CompleteVATTaxation();
	
	Services.Load(VTServices);
	
	FillThePricesByTermsOfSales();
	
EndProcedure

Procedure CheckContractProcurementOption(DocumentBasis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CounterpartyContracts.OptionForRegisteringServiceReceiptDocuments AS OptionForRegisteringServiceReceiptDocuments
	|FROM
	|	&HeaderDataPath AS DocumentHeader
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentHeader.Contract = CounterpartyContracts.Ref
	|WHERE
	|	DocumentHeader.Ref = &Ref";
	
	Query.Text = StrReplace(Query.Text, "&HeaderDataPath", 
		StringFunctionsClientServer.SubstituteParametersToString("Document.%1", DocumentBasis.Metadata().Name));
	
	Query.SetParameter("Ref", DocumentBasis);
	
	Selection = Query.Execute().Select();
	If Selection.Next()
		And (Not ValueIsFilled(Selection.OptionForRegisteringServiceReceiptDocuments) 
		Or Selection.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed) Then
		
		Raise NStr("ru = 'Поступление услуг в подразделение можно создавать только если в договоре основания включена схема ""Раздельная закупка для работ и услуг"".';
					|vi = 'You can create the receipt of services to business unit only if the base contract contains the ""Unbilled inventory for works and services"" scheme.';
					|en = 'You can create the receipt of services to business unit only if the base contract contains the ""Unbilled inventory for works and services"" scheme.'; fa = 'You can create the receipt of services to business unit only if the base contract contains the ""Unbilled inventory for works and services"" scheme.';
					|it = 'You can create the receipt of services to business unit only if the base contract contains the ""Unbilled inventory for works and services"" scheme.';
					|pl = 'You can create the receipt of services to business unit only if the base contract contains the ""Unbilled inventory for works and services"" scheme.';
					|tr = 'Departmana hizmet girişi, sadece temel sözleşmede ""İşler ve hizmetler için ayrı satın alma"" şeması etkinleştirilmişse oluşturulabilir.'");
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Not ValueIsFilled(ReferenceOrder) Then
		ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	EndIf;
	
	ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	
	If Not ValueIsFilled(VATTaxation) Then
		CompleteVATTaxation();
	EndIf;
	
	FillInTypeOfActivityVAT();
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	TypesOfBases_ = New Array;
	TypesOfBases_.Add(Type("DocumentRef.PurchaseOrder"));
	TypesOfBases_.Add(Type("DocumentRef.VendorInvoice"));
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And TypesOfBases_.Find(TypeOf(FillingData.DocumentBasis)) <> Undefined Then
		
		Return FillingData.DocumentBasis;
		
	ElsIf TypesOfBases_.Find(TypeOf(FillingData)) <> Undefined Then 
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure CompleteVATTaxation()
	
	FillParameters = Documents.ReceiptOfServicesToBusinessUnit.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
EndProcedure

Procedure FillInTypeOfActivityVAT()
	
	FillParameters = Documents.ReceiptOfGoodsToWarehouse.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(VATActivityType, FillParameters);
	
EndProcedure

Function BasisContract(Contract)
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, 
		"OptionForRegisteringServiceReceiptDocuments, ServiceReceiptOption");
	
	Return ReceiptOfServicesIsUsedUnderContracts(ContractDetails_);
	
EndFunction

Function ReceiptOfServicesIsUsedUnderContracts(ContractDetails_)
	
	If (ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
		And (ContractDetails_.ServiceReceiptOption = Enums.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices 
		Or ContractDetails_.ServiceReceiptOption = Enums.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices) Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region Other

//Fills in the inventory tracking analytics in the tabular parts of the document that store information about products.
//If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
////
//
//Parameters: See Documents.VendorInvoice.CollectionOfTabularPartsOfGoods.
////
//T Document Table -
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		
		DocumentTables = Documents.ReceiptOfServicesToBusinessUnit.CollectionOfTabularPartsOfGoods();
		FillPropertyValues(DocumentTables, ThisObject);
		
	EndIf;
	
	TableServices = DocumentTables.Services;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Catalogs.Warehouses.EmptyRef(),
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.Insert("Work_5", "Department");
	FieldsNames.Insert("OperationService", "Department"); 
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Series = "";
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(TableServices, PlacesOfAccounting, FieldsNames);
	
	PlacesOfAccounting = New Structure("Arbitrary", Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesGoodsAtPartners"; 
	FieldsNames.BatchesIndicationStatus = "";
	FieldsNames.Series = "";	InformationRegisters.ItemsLocationAttributes.FillInCollection(TableServices, PlacesOfAccounting, FieldsNames);
	
EndProcedure

Procedure FillInSummaryIndicatorsOfProductLine(RowOfGoods)
	
	ActionsWithString = New Structure;
	
	If ValueIsFilled(RowOfGoods.Price) Then
		ParametersForRecalculatingAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		
		ActionsWithString.Insert("RecalculateAmount",		"Count");
		ActionsWithString.Insert("RecalculateVATAmount",	ParametersForRecalculatingAmount);
		ActionsWithString.Insert("RecalculateAmountWithVAT",	ParametersForRecalculatingAmount);
	EndIf;
	
	If Not ValueIsFilled(RowOfGoods.VATRate) Then
		
		ParametersForFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
		ActionsWithString.Insert("FillInVATRate", ParametersForFillingInVATRate);
	EndIf;
	
	If ValueIsFilled(ActionsWithString) Then
		BatchProcessingOfTablePartServer.ProcessTSString(RowOfGoods, ActionsWithString, Undefined);
	EndIf;
	
EndProcedure

Procedure FillThePricesByTermsOfSales(FillInAllLines = True)
	
	LinesWithoutPrices = Undefined;
	
	If Not FillInAllLines Then
		LinesWithoutPrices = New Array;
		
		For Each TSRow In Services Do
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
	ActionsWithStrings.Insert("RecalculateAmount",		"Count");
	ActionsWithStrings.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
	ActionsWithStrings.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
	
	PartnerPricesFillingServer.FillInPrices(Services, LinesWithoutPrices, FillParameters, ActionsWithStrings);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
