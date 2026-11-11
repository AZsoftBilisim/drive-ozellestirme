#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sales in the order to the supplier
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	ARAPCurrency = PurchaseConditions.ARAPCurrency;
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization <> Organization Then
		Organization = PurchaseConditions.Organization;
		
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse = PurchaseConditions.Warehouse;
		StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
		If StructureOfResponsible <> Undefined Then
			ReceivedBy = StructureOfResponsible.EmployeeResponsible;
			AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = ARAPCurrency;
		Contract = PurchasesServer.GetDefaultContract(
			ThisObject,
			Enums.BusinessTransactions.PurchaseFromSupplier,
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
	
	PaymentMethod = PurchaseConditions.PaymentMethod;
	
	If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
	EndIf;
	
	PriceIncludesVAT         = PurchaseConditions.PriceIncludesVAT;
	DepositForPackageIsRequired = PurchaseConditions.PackageDepositIsRequired;
	
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		DefaultPurchasingConditions = PurchasesServer.GetDefaultPurchaseTerms(
			Partner,
			New Structure("SelectedAgreement", Terms));
		
		PricesAreFilledOut = False;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
			
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				FillParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
				VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
				
				If RecalculatePrices_ And ValueIsFilled(Terms) Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
					
					PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(
						Goods,
						Undefined, // Array of strings
						FillParameters,
						StructureOfActions);
					
				EndIf;
								
			Else
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the order to the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True, True);
	FillInTermsOfPurchase(PurchaseConditions);
	
	FillParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	If RecalculatePrices_ Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");
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
		
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not ValueIsFilled(Terms) Or
		 Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If DepositForPackageIsRequired Then
		NotCheckedAttributeArray.Add("ARAPCurrency");
	EndIf;
	
	BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	

	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject,Cancel);
																		
	RedemptionOfReturnablePackagingFromVendorLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)

	Var WarehouseForReceipt;
	Var HeaderAttributes;
	
	FillInDataType = TypeOf(FillingData);

	If FillInDataType = Type("Structure") Then
		If FillingData.Property("FillInAcceptedContainer") Then
			FillOutDocumentOnBasisOfAcceptedContainer(FillingData);
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then
		FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData);
	EndIf;
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument();

	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.Filling(ThisObject, FillingData, StandardProcessing);

EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Goods, PriceIncludesVAT);
	
	RegistrationParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods");
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);

	EndIf;
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
 	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
 	
	RedemptionOfReturnablePackagingFromVendorLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	RegistrationParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.UndoPosting(ThisObject, Cancel);
	
	RegistrationParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	PaymentDate     = Date(1,1,1);
	Approved      = False;
	InventoryOwnerAttribute      = Undefined;
	IncomingDocumentDate = Date(1,1,1);
	IncomingDocumentNumber = "";
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);	
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods");
	
	RedemptionOfReturnablePackagingFromVendorLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.CurrentUser();

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	RedemptionOfReturnablePackagingFromVendorLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillOutDocumentOnBasisOfAcceptedContainer(Val DetailsOfFillingInForm)
	
	Partner = DetailsOfFillingInForm.HeaderAttributes.Partner;
	
	If DetailsOfFillingInForm.HeaderAttributes.Property("Terms", Terms) And ValueIsFilled(Terms) Then
		FillInTermsOfPurchaseUnderAgreement(False);
	Else
		FillInDefaultPurchaseConditions(False);
	EndIf;
	
	PropertiesToExclude = "";
	If Not ValueIsFilled(DetailsOfFillingInForm.HeaderAttributes.Organization) Then
		PropertiesToExclude = "Organization, Counterparty, Terms";
	EndIf;
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm.HeaderAttributes, , PropertiesToExclude);
	
	If Not ValueIsFilled(VATTaxation) Then
		VATTaxation = Metadata.Documents.RedemptionOfReturnablePackagingFromVendor.Attributes.VATTaxation.FillValue;
	EndIf;
	
	If IsTempStorageURL(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage) Then
		
		ReceivedPackage = GetFromTempStorage(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage);
		Goods.Load(ReceivedPackage);
		
		ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
		
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
			
		For Each CurrentRow In Goods Do
			
			CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
			CurrentRow.NumberOfPackages = CurrentRow.Count;
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	VendorInvoice.Ref                       AS DocumentBasis,
		|	VendorInvoice.Currency                       AS Currency,
		|	VendorInvoice.Partner                      AS Partner,
		|	VendorInvoice.Terms                   AS Terms,
		|	VendorInvoice.Organization                  AS Organization,
		|	VendorInvoice.Counterparty                   AS Counterparty,
		|	VendorInvoice.PriceIncludesVAT              AS PriceIncludesVAT,
		|	VendorInvoice.VATTaxation           AS VATTaxation,
		|	VendorInvoice.ARAPCurrency         AS ARAPCurrency,
		|	VendorInvoice.PaymentMethod                  AS PaymentMethod,
		|	VendorInvoice.PackageDepositIsRequired         AS DepositForPackageIsRequired,
		|	VendorInvoice.ARAPObjectSettings              AS ARAPObjectSettings,
		|	NOT VendorInvoice.Posted                  AS ThereAreErrorsPosted,
		|	NOT VendorInvoice.ToReturnReusablePackage AS ThereAreErrorsToReturnMultiTurnContainer,
		|	VendorInvoice.LineOfBusiness      AS LineOfBusiness,
		|	VendorInvoice.ForeignCurrencyTransaction                AS ForeignCurrencyTransaction
		|FROM
		|	Document.VendorInvoice AS VendorInvoice
		|WHERE
		|	VendorInvoice.Ref = &DocumentBasis
		|;
		|SELECT
		|	ReceivedReturnablePackagingBalance.Products        AS Products,
		|	ReceivedReturnablePackagingBalance.Characteristic      AS Characteristic,
		|	ReceivedReturnablePackagingBalance.DocumentInflow AS DocumentInflow,
		|	ReceivedReturnablePackagingBalance.SumBalance        AS Sum,
		|	ReceivedReturnablePackagingBalance.CountBalance   AS Count,
		|	ReceivedReturnablePackagingBalance.CountBalance   AS NumberOfPackages
		|FROM
		|	AccumulationRegister.ReceivedReturnablePackaging.Balance(, DocumentInflow = &DocumentBasis) AS ReceivedReturnablePackagingBalance
		|");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfRedemptionOfContainers(
		DocumentBasis,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsToReturnMultiTurnContainer);
		
	FillPropertyValues(ThisObject, HeaderSelection);
	Goods.Load(QueryBatch[1].Unload());
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	For Each CurrentRow In Goods Do
		
		CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
		CurrentRow.NumberOfPackages = CurrentRow.Count;
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
		
	EndDo;
	
EndProcedure


Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultPurchaseConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument()
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	If Not ValueIsFilled(ARAPCurrency) Then
		ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	FillParameters = Documents.RedemptionOfReturnablePackagingFromVendor.ParametersForFillingInVATTaxationPurchases(ThisObject);
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
		Undefined);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
