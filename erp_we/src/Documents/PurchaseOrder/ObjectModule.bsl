#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the amount of undelivered order lines
//
// Parameters:
//	OnlyDepositForContainer - Boolean - True if you only need to take into account the lines of the Deposit for the container.
//
// Returns:
//	Number - The sum of the ordered lines.
//
Function GetSumOfOrderedRows(OnlyDepositForContainer = False) Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|	Goods.Canceled AS Canceled
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
	|	NOT Goods.Canceled
	|	AND ((Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR (NOT &ToReturnReusablePackage) OR &PackageDepositIsRequired)
	|			AND NOT &OnlyDepositForContainer)
	|		OR (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage
	|			AND &PackageDepositIsRequired
	|			AND &OnlyDepositForContainer)
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	Query.SetParameter("OnlyDepositForContainer", OnlyDepositForContainer);
	
	Upload0 = Query.Execute().Unload();
	SumOfOrderedRows = Upload0[0].AmountIncludingVAT;
	Return SumOfOrderedRows;
	
EndFunction

// Calculates the amount of returnable containers
//
// Returns:
//	Number - The amount of the returnable container.
//
Function GetReturnTareAmount() Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountIncludingVAT AS AmountIncludingVAT,
	|	Goods.Canceled AS Canceled
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
	|	NOT Goods.Canceled
	|	AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &ToReturnReusablePackage
	|	AND NOT &PackageDepositIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	ReturnTareAmountOfOrderedLines = Upload0[0].AmountIncludingVAT;
	Return ReturnTareAmountOfOrderedLines;
	
EndFunction

// Calculates the number of ordered order lines
//
// Returns:
//	Number - The number of rows ordered.
//
Function GetNumberOfRowsOrdered() Export
	
	FoundRows = Goods.FindRows(New Structure("Canceled", False));
	Return FoundRows.Count();
	
EndFunction

// Fills in the terms of sales in the order to the supplier
//
// Parameters:
//	PurchaseConditions - Structure - Structure to fill in.
//	ReFillDates - Boolean - Indicates that the shipment date needs to be filled in again.
//
Procedure FillInTermsOfPurchase(Val PurchaseConditions, ReFillDates = True) Export
	
	If PurchaseConditions = Undefined Then
		Return;
	EndIf;
	
	Currency = PurchaseConditions.Currency;
	
	If ValueIsFilled(PurchaseConditions.PaymentMethod) Then
		PaymentMethod = PurchaseConditions.PaymentMethod;
	EndIf;
	
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Organization Then
		Organization = PurchaseConditions.Organization;
		
		BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization    			= Organization;
		ParametersStructure.PaymentMethod 			= PaymentMethod;
		ParametersStructure.LineOfBusiness	= LineOfBusiness;

		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse = PurchaseConditions.Warehouse;
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If ValueIsFilled(PurchaseConditions.BusinessOperation) Then
		OperationByAgreement		= BusinessOperation;
		SeparatePurchaseOperations	= PurchasesServer.BusinessOperationsOnMain(PurchaseConditions.BusinessOperation);
		
		If SeparatePurchaseOperations.Find(BusinessOperation) = Undefined
			And Not (OperationByAgreement = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
				And PurchaseConditions.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier) Then
			OperationByAgreement = PurchaseConditions.BusinessOperation;
		EndIf;
		
		BusinessOperation = OperationByAgreement;
	EndIf;
	
	ContractBusinessTransaction = ?(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
											Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder,
										Enums.BusinessTransactions.PurchaseFromSupplier,
										BusinessOperation);
	ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
	
	If PurchaseConditions.ContractsAreUsed <> Undefined
		And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
		ContractDetails_ = Common.ObjectAttributesValues(Contract, "ForeignCurrencyTransaction, FinancialAccountingGroup");
		If ForeignCurrencyTransaction <> ContractDetails_.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = ContractDetails_.ForeignCurrencyTransaction;
			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness")
			Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
			FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
		EndIf;
		
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		PriceIncludesVAT = PurchaseConditions.PriceIncludesVAT;
	EndIf;
	
	If Not ValueIsFilled(PurchaseConditions.ContractsAreUsed) 
		Or Not PurchaseConditions.ContractsAreUsed Then
		
	Else
		
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	If ValueIsFilled(PurchaseConditions.ShipmentDueDate) And ReFillDates Then
		DocumentDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
		DateOfShipment = Documents.PurchaseOrder.DateAccordingToCompanyCalendar(DocumentDate, PurchaseConditions.ShipmentDueDate);
		ProvisionInDocumentsServer.FillInDetailsInCollection(Goods, "DateOfShipment", DateOfShipment);
		DateOfReceipt = Undefined;
	EndIf;
	
	RegisterVendorPrices = PurchaseConditions.RegisterVendorPrices;
	ToReturnReusablePackage = PurchaseConditions.ReturnReusablePackage;
	ReusablePackageReturnCycleLength = PurchaseConditions.ReusablePackageReturnCycleLength;
	PackageDepositIsRequired = PurchaseConditions.PackageDepositIsRequired;
	DeliveryDuration = PurchaseConditions.DeliveryDuration;
	If ValueIsFilled(DateOfReceipt) Then
		RecalculateDatesByCalendar(-DeliveryDuration, False);
	ElsIf ValueIsFilled(DateOfShipment) Then
		RecalculateDatesByCalendar(DeliveryDuration);
	EndIf;
	RequestedDeliveryDate = DateOfReceipt;
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		SelectionOfProcurementConditions = New Structure("ConsiderWarehouseGroups, SelectedAgreement", True, Terms);
		If ValueIsFilled(BusinessOperation) Then
			BusinessTransactions = PurchasesServer.MainEconomicOperationOfSeparatePurchase(BusinessOperation);
			SelectionOfProcurementConditions.Insert("BusinessTransactions", BusinessTransactions);
			If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Then
				SelectionOfProcurementConditions.Insert("ContractsAreUsed", True);
			EndIf;
		EndIf;
		
		DefaultPurchasingConditions	= PurchasesServer.GetDefaultPurchaseTerms(Partner, SelectionOfProcurementConditions);
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
		
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
			
				FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
				VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
				
				FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
				VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
				
				If RecalculatePrices_
					And ValueIsFilled(Terms) Then
					
					FillThePricesByTermsOfSales();
					
				EndIf;
			Else
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
			EndIf;
		Else
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			Terms = Undefined;
			
			ContractBusinessTransaction = ?(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
													Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder,
												Enums.BusinessTransactions.PurchaseFromSupplier,
												BusinessOperation);
			ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			AddlParameters.LineOfBusiness = LineOfBusiness;
			Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
			
			FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
			VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
			
			FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
			VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
			
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
			
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sales under the agreement in the order to the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//	ReFillDates - Boolean - True if you need to fill in the shipment and receipt dates in the document.
//
Procedure FillInTermsOfPurchaseUnderAgreement(RecalculatePrices_ = True, ReFillDates = True) Export
	
	PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True);
	FillInTermsOfPurchase(PurchaseConditions, ReFillDates);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	If RecalculatePrices_ Then
		StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
		RecalculateAmountTakingIntoAccountManualDiscount	= New Structure("Clear", False);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountWithVAT",StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateVATAmount",StructureOfRecalculationOfAmount);
		StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);
		
		FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
		FillParameters.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");
		FillParameters.Insert("Date",       Date);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("Currency",     Currency);
		FillParameters.Insert("Terms", Terms);
		FillParameters.Insert("VATTaxation", VATTaxation);
		
		PartnerPricesFillingServer.FillInPrices(
			Goods,
			Undefined, // Array of strings
			FillParameters,
			StructureOfActions);
	EndIf;
	
EndProcedure

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PurchaseOrderStatuses[NewStatus];
	
	If Approved And
		MeaningOfNewStatus <> Enums.PurchaseOrderStatuses.Approved
		And MeaningOfNewStatus <> Enums.PurchaseOrderStatuses.Confirmed_
		And MeaningOfNewStatus <> Enums.PurchaseOrderStatuses.Closed Then
		
		Approved = False;
		
	EndIf;
	
	If Goods.Count() > 0 Then
		
		// In the status "Confirmed" or "Closed" - we will put all the undelivered lines in the expected receipt
		If Status <> Enums.PurchaseOrderStatuses.Closed 
			And Status <> Enums.PurchaseOrderStatuses.Confirmed_ 
			And (MeaningOfNewStatus = Enums.PurchaseOrderStatuses.Confirmed_ 
				Or	MeaningOfNewStatus = Enums.PurchaseOrderStatuses.Closed) Then
			
			FillInBlankReceiptDate();
			
		EndIf;
		
	EndIf;

	
	If AdditionalParameters <> Undefined Then
		
		OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

// Verifies the completion of the accounts payable
//
// Returns:
//	Boolean - True, if there is no debt to the supplier.
//
Function CheckCompletionOfCalculations() Export
	
	ControlOfCompletionOfCalculations = GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
	
	If Not ControlOfCompletionOfCalculations Then
		Return True
	EndIf;
	
	ErrorText = NStr("vi = 'Chưa thực hiện thanh toán theo đơn hàng.
	|Để đóng đơn hàng, cần thanh toán %AmountToPay% %Currency%.
	|Chỉ có thể đóng đơn hàng với các dòng đã thanh toán/hủy bỏ toàn bộ';
	|ru = 'Расчеты по заказу не завершены.
	|Для закрытия заказа требуется оплата %AmountToPay% %Currency%.
	|Закрытие заказа возможно только с полностью оплаченными/отмененными строками';
	|en = 'There is an outstanding payment due for this order: 
	|%AmountToPay% %Currency%.
	|To close the order, pay the outstanding amount or cancel the outstanding items.'; fa = 'There is an outstanding payment due for this order: 
	|%AmountToPay% %Currency%.
	|To close the order, pay the outstanding amount or cancel the outstanding items.';
	|it = 'Le regolazioni dei conti relativi all''ordine non sono completi.
	|Per la chiusura dell''ordine è richiesto il pagamento di %AmountToPay% %Currency%.
	|È possibile concludere l''ordine soltanto se le righe sono completamente pagate/cancellate';
	|pl = 'Obliczenia z tytułu zamówienia nie są zakończone.
	|W celu zamknięcia zamówienia jest konieczna płatność %AmountToPay% %Currency%.
	|Zamknięcie zamówienia jest możliwe tylko z całkowicie opłaconymi/anulowanymi wierszami';
	|tr = 'Siparişin kapatılması tamamlanmamıştır.
	| Siparişi kapatmak için %AmountToPay% %Currency%bir ödeme yapılması gerekmektedir.
	| Sipariş yalnızca tamamen ödenmiş/iptal edilmiş satırlarla kapatılabilir'");
	
	SumOfOrderedRows = GetSumOfOrderedRows();
	
	Query = New Query(
		"SELECT
		|	VendorsARAPAccountingBalance.Currency AS Currency,
		|	VendorsARAPAccountingBalance.AmountDueReceipt AS Paid
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject.Object = &Ref) AS VendorsARAPAccountingBalance
		|");
	Query.SetParameter("Ref", Ref);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	
	If Selection.Next() Then
		If Selection.Paid < SumOfOrderedRows Then
			ErrorText = StrReplace(ErrorText, "%AmountToPay%",      String(SumOfOrderedRows - Selection.Paid));
			ErrorText = StrReplace(ErrorText, "%Currency%",      String(Selection.Currency));
			CommonClientServer.MessageToUser(
				ErrorText,,,,);
			Return False
		EndIf;
	EndIf;
	
	Return True
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	FillInDataType = TypeOf(FillingData);
	
	InitializationIsRequired = True;
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("Basis") Then
			
			BasisType = TypeOf(FillingData.Basis);
			
			If BasisType = Type("DocumentRef.SalesOrder") Then
				
				FillInDocumentBasedOnCustomerSOrder(FillingData);
				
			ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
				
				FillInDocumentBasedOnRequestForRefund(FillingData);
				
			ElsIf BasisType = Type("DocumentRef.TransferOrder") Then
				
				FillInDocumentBasedOnTransferOrder(FillingData);
				
			ElsIf BasisType = Type("DocumentRef.InventoryConsumptionOrder") Then
				
				FillInDocumentBasedOnOrderForDomesticConsumption(FillingData);
			ElsIf BasisType = Type("DocumentRef.OrderOfMaterialsForProduction") Then
				
				FillInDocumentBasedOnOrderOfMaterialsInProduction(FillingData);
			
			ElsIf BasisType = Type("DocumentRef.SubcontractOrder2_5") Then
				
				FillInDocumentBasedOnOrderToProcessor2_5(FillingData);
			ElsIf BasisType = Type("DocumentRef.ProductionStage2_2") Then
				
				FillInDocumentBasedOnProductionStage(FillingData);	
			ElsIf BasisType = Type("DocumentRef.ByAssemblyDisassemblyOrder") Then
				
				FillInDocumentBasedOnAssemblyOrder(FillingData);
				
			ElsIf BasisType = Type("DocumentRef.PurchaseRequest") Then
				
				FillInDocumentBasedOnPurchaseRequest(FillingData);
				
			EndIf;
			
		Else
			
			FillInSelectionDocument(FillingData);
			
		EndIf;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
			
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		
		FillInDocumentBasedOnPartner(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		FillInDocumentBasedOnAgreementWithSupplier(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.CounterpartyContracts") Then
		
		FillInDocumentOnBasisOfContract(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		FillInDocumentBasedOnTransaction(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ProductRangeChange") Then
		
		InitializeDocument(FillingData);
		InitializationIsRequired = False;
		FillInDocumentBasedOnChangeOfAssortment(FillingData);
		
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	If Not ValueIsFilled(BankAccount) Then
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, BankAccount);
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	PurchaseOrderLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	WarehouseValue_ = Warehouse;
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If TypeOf(FillingData) = Type("Structure") Then
		
		// When creating from a common domain.The creation of the basis and the definition of the assignable quantity may deliberately be empty
		// if data is transferred to the document for several warehouses. Filling in statistics can fill in this empty value,
		// you need to clear it
		If FillingData.Property("Basis") Then
			Warehouse = WarehouseValue_;
		EndIf;
		
	EndIf;
	
	If Not (TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("Goods")
		And FillingData.Property("Manager")) Then
		ResponsiblePersonsServer.InstallManager(ThisObject);
	EndIf;
	
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	If InitializationIsRequired Then
		InitializeDocument(FillingData);
	EndIf;
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	If FillInDataType = Type("DocumentRef.SalesOrder") Or
		FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		If PurchaseForActivity <> VATTaxation Then
			
			StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, True));
			StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
			StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
			
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(ServiceReceiptOption) Then
		ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps     = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PurchaseOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If (BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
		Or Not ToReturnReusablePackage)
		And PackageDepositIsRequired Then
		PackageDepositIsRequired = False;
	EndIf;
	
	DocumentAmount = GetSumOfOrderedRows();
	ReturnablePackagingAmount = GetReturnTareAmount();
	
	ExecutionScheduleInContract = False;
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Contract) Then
		ExecutionScheduleInContract = Common.ObjectAttributeValue(Contract, "ExecutionScheduleIsSpecified");
	EndIf;
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	DocumentApproved = Approved;
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode,
		Enums.PurchaseOrderStatuses.NotApproved);
	
	// We will set the date of approval, if the document is agreed
	If Not DocumentApproved And Approved Then
		ApprovalDate = CurrentSessionDate();
		ARAPAccountingServer.WhenChangingApprovalDate(ThisObject);
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
		Or ExecutionScheduleInContract Then
		
		AmountAdvanceBeforeConfirmation = 0;
		PrepaymentAmountBeforeReceipt = 0;
		
	Else
		
		If Not PackageDepositIsRequired Then
			For Each PaymentStage In PaymentScheduleSteps Do
				PaymentStage.PackageDepositValue = 0;
			EndDo;
		EndIf;
		
		StepsTable = PaymentScheduleSteps.Unload(, "PaymentOption, PaymentAmount, PackageDepositValue");
		StepsTable.GroupBy("PaymentOption", "PaymentAmount,PackageDepositValue");
		
		AdvancePaymentLineBeforeConfirmation = StepsTable.Find(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation,"PaymentOption");
		
		If AdvancePaymentLineBeforeConfirmation = Undefined Then
			AmountAdvanceBeforeConfirmation = 0;
		Else
			AmountAdvanceBeforeConfirmation = AdvancePaymentLineBeforeConfirmation.PaymentAmount + AdvancePaymentLineBeforeConfirmation.PackageDepositValue;
		EndIf;
		
		PrepaymentLineBeforeReceipt = StepsTable.Find(Enums.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt,"PaymentOption");
		
		If PrepaymentLineBeforeReceipt = Undefined Then
			PrepaymentAmountBeforeReceipt = 0;
		Else
			PrepaymentAmountBeforeReceipt = PrepaymentLineBeforeReceipt.PaymentAmount + PrepaymentLineBeforeReceipt.PackageDepositValue;
		EndIf;
	EndIf;
	
	NewReceiptDate = Date(1,1,1);
	
	If Goods.Count() > 0 Then
			
		If Status = Enums.PurchaseOrderStatuses.Approved
			Or Status = Enums.PurchaseOrderStatuses.Confirmed_
			Or Status = Enums.PurchaseOrderStatuses.Closed Then
			
			FilterParameters = New Structure;
			FilterParameters.Insert("Canceled", False);
			ConfirmedRows = Goods.FindRows(FilterParameters);
			
			If ConfirmedRows.Count() > 0 Then
				
				TableOfConfirmedRows = Goods.Unload(ConfirmedRows, "DateOfReceipt");
				TableOfConfirmedRows.Sort("DateOfReceipt Asc");
				NewReceiptDate = TableOfConfirmedRows[0].DateOfReceipt;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DateOfFirstReceipt = NewReceiptDate;
	
	CashServer.ClearUnusedPaymentFormDetails(ThisObject, PaymentMethod);
	
	ImportOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	OperationsInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	
	TransactionIsNotSubjectToVAT = (ImportOperations.Find(BusinessOperation) <> Undefined
								Or OperationsInEAEUCountries.Find(BusinessOperation) <> Undefined);
	
	If TransactionIsNotSubjectToVAT Then
		VATTaxation = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;
	EndIf;
	
	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Goods, Partner);
	
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(ThisObject, Metadata.Documents.PurchaseOrder.TabularSections.Goods.Name);
	EndIf;
	
	PurchaseOrderLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If (BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale)
		And Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation)
		And (Not ValueIsFilled(Terms)
			Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed")) Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	// The validity period of the order must be at least the date of the document
	If Status = Enums.PurchaseOrderStatuses.NotApproved And
		ValueIsFilled(ApprovalDate) And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày thống nhất không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата согласования должна быть не меньше даты документа %Date%';
						|en = 'Date of approval cannot be before the document creation: %Date%'; fa = 'Date of approval cannot be before the document creation: %Date%';
						|it = 'La data della definizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data uzgodnienia powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Onay tarihi, belgenin %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ApprovalDate",
			,
			Cancel);
		
	EndIf;
	
	AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "Goods", "Canceled");
	
	If Not OneDateReceipt Or 
		OneDateReceipt And 
		Not(Status = Enums.PurchaseOrderStatuses.Confirmed_ Or
			Status = Enums.PurchaseOrderStatuses.Closed) 
		Or OneDateReceipt And AllLinesAreCanceled Then
		
		NotCheckedAttributeArray.Add("DateOfShipment");
		NotCheckedAttributeArray.Add("DateOfReceipt");
		
	EndIf;
	
	If DeliveryDuration = 0 Then
		NotCheckedAttributeArray.Add("DateOfReceipt");
	EndIf;
	
	// The desired date of receipt in the header must be at least the date of the document
	If ValueIsFilled(RequestedDeliveryDate) And RequestedDeliveryDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày tiếp nhận mong muốn không được nhỏ hơn ngày của chứng từ %Date%';
						|ru = 'Желаемая дата поступления должна быть не меньше даты документа %Date%';
						|en = 'Requested delivery date cannot be before the document creation: %Date%'; fa = 'Requested delivery date cannot be before the document creation: %Date%';
						|it = 'La data preferibile dell''arrivo non deve essere precedente alla data del documento %Date%';
						|pl = 'Planowana data wpaty powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'İstenen kabul tarihi, belgenin %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"RequestedDeliveryDate",
			,
			Cancel);
		
	EndIf;
	
	// The date of receipt in the header must be at least the date of the document
	If OneDateReceipt 
		And ValueIsFilled(DateOfReceipt) 
		And DateOfReceipt < BegOfDay(Date)
		And Not AllLinesAreCanceled
		And DeliveryDuration <> 0 Then
	
		ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
						|en = 'Date of receipt cannot be before the document date: %Date%'; fa = 'Date of receipt cannot be before the document date: %Date%';
						|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Kabul tarihi, belgenin %Date% tarihinden daha önce olmamalıdır '");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfReceipt",
			,
			Cancel);
		
	EndIf;
	
	// The date of receipt in the header must be at least the date of the document
	If OneDateReceipt
		And ValueIsFilled(DateOfShipment)
		And DateOfShipment < BegOfDay(Date)
		And Not AllLinesAreCanceled Then
	
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfShipment",
			,
			Cancel);
		
	EndIf;
	
	If OneDateReceipt
		And DateOfReceipt < DateOfShipment
		And Not AllLinesAreCanceled Then
		
		ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày giao hàng %Date%';
						|ru = 'Дата поступления должна быть не меньше даты отгрузки %Date%';
						|en = 'Date of receipt must be later than shipment date %Date%'; fa = 'Date of receipt must be later than shipment date %Date%';
						|it = 'La data di ricezione non deve essere precedente alla data di spedizione %Date%';
						|pl = 'Data wpływu powinna być nie mniejsza niż data wysyłki %Date%';
						|tr = 'Kabul tarihi, sevkiyat %Date% tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(DateOfShipment, "DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfReceipt",
			,
			Cancel);
		
	EndIf;
	
	InvoiceIsOrder = PurchasesServer.OrderForAcceptanceOfGoodsConsignmentNote(GoodsReceiptOption);
	
	UnfacturedDeliveryIsUsed = GetFunctionalOption("UseUninvoicedDeliveries");
	UnfacturedDeliveryIsUsed = UnfacturedDeliveryIsUsed
											And ?(ValueIsFilled(Contract),
												Common.ObjectAttributeValue(Contract, "PurchaseRegistrationOption") = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoods,
												False);
	
	OperationsOfUnfacturedDelivery = New Array;
	OperationsOfUnfacturedDelivery.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	OperationsOfUnfacturedDelivery.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	
	If InvoiceIsOrder
		And UnfacturedDeliveryIsUsed Then
		
		If OperationsOfUnfacturedDelivery.Find(BusinessOperation) <> Undefined Then
			ErrorText = NStr("vi = 'Không hỗ trợ sử dụng phương án tiếp nhận ""theo hóa đơn"" đối với giao dịch giao hàng mà chưa có hóa đơn.
								|Nên sử dụng phương án tiếp nhận theo hợp đồng hoặc theo đơn hàng.';
								|ru = 'Использование варианта приемки ""по накладным"" не поддерживается для операций неотфактурованной поставки.
								|Рекомендуется использовать вариант приемки по договорам или по заказам.';
								|en = 'Cannot use ""By invoices"" receiving option for uninvoiced delivery operations.
								| It is recommended that you use ""By contracts"" or ""By orders"" receiving option instead.'; fa = 'Cannot use ""By invoices"" receiving option for uninvoiced delivery operations.
								| It is recommended that you use ""By contracts"" or ""By orders"" receiving option instead.';
								|it = 'L''utilizzo della variante di accettazione ""per bolle"" non è supportato per operazioni di consegna non fatturata.
								|Si consiglia di utilizzare la variante di accettazione per accordi o ordini.';
								|pl = 'Korzystanie z wariantu akceptacji ""na podstawie listów przewozowych"" nie jest obsługiwane w przypadku niezafakturowanych dost
								|.Zaleca się korzystanie z opcji akceptacji na podstawie umowy lub zamówienia.';
								|tr = 'Faturasız teslimat işlemleri için ""fatura"" seçeneğinin kullanımı desteklenmemektedir.
								| Sözleşmeye veya siparişe göre kabul seçeneğinin kullanılması önerilir.'");
			
			CommonClientServer.MessageToUser(ErrorText, ThisObject, , , Cancel);
		EndIf;
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.CancellationReason");
	NotCheckedAttributeArray.Add("Goods.DateOfReceipt");
	NotCheckedAttributeArray.Add("Goods.DateOfShipment");
	
	// Auxiliary details for checking VAT accounting
	ByItsUse			= (PurchaseForActivity = Enums.VATTaxationTypes.ByActualUsage);
	FromDocument					= Enums.SeparateVATAccountingOptions.FromDocument;
	ToLinesOfBusiness	= Enums.CostAllocationOptions.ToLinesOfBusiness;
	ToCurrentPeriodExpensesDirectly    = Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly;
	ToProductionCosts	= Enums.CostAllocationOptions.ToProductionCosts;
	BatchAccountingIsEnabled		= CalculationOfCostCached.BatchAccountingIsEnabled(BegOfMonth(Date));
	UseIncomeExpenses	= GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	
	MatchingLineCodes = New Map;

	UseAgencyPurchasing = GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	
	For CurIndex__ = 0 To Goods.Count()-1 Do

		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
			
		// The date of receipt of PM Goods is mandatory only for orders in 
		// the statuses Confirmed, Available, Closed.
		If Not OneDateReceipt
			And (Status = Enums.PurchaseOrderStatuses.Confirmed_
				Or Status = Enums.PurchaseOrderStatuses.Closed)
			And Not LineProducts_.Canceled
			And Not ValueIsFilled(LineProducts_.DateOfReceipt)
			And DeliveryDuration <> 0 Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền cột ""Ngày tiếp nhận'''' trong dòng %1';
					|ru = 'Не заполнена колонка ""Дата поступления"" в строке %1';
					|en = 'The ""Date of receipt"" column in line %1 is not filled in'; fa = 'The ""Date of receipt"" column in line %1 is not filled in';
					|it = 'La colonna ""Data dell''arrivo"" nella riga %1 non è compilata';
					|pl = 'Nie wypełniono kolumny ""Data wpływu"" w wierszu %1';
					|tr = '%1Satırındaki ""Teslim alım tarihi"" sütunu boş'"),
				LineProducts_.LineNumber);
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfReceipt"),
				,
				Cancel);
			
		EndIf;
		
		If Not OneDateReceipt
			And (Status = Enums.PurchaseOrderStatuses.Confirmed_
				Or Status = Enums.PurchaseOrderStatuses.Closed)
			And Not LineProducts_.Canceled
			And Not ValueIsFilled(LineProducts_.DateOfShipment) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" trong dòng %1';
					|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %1';
					|en = 'The ""Shipment date"" column in the %1 line is not filled in'; fa = 'The ""Shipment date"" column in the %1 line is not filled in';
					|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %1';
					|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %1';
					|tr = '%1Satırındaki ""Sevkiyat tarihi"" sütunu boş'"),
				LineProducts_.LineNumber);
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfShipment"),
				,
				Cancel);
			
		EndIf;
		
		// The date of receipt of PM Goods must be at least the date of the document
		If Not OneDateReceipt 
			And ValueIsFilled(LineProducts_.DateOfReceipt) 
			And LineProducts_.DateOfReceipt < BegOfDay(Date)
			And DeliveryDuration <> 0 Then
		
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %1 trong dòng %2';
					|ru = 'Дата поступления должна быть не меньше даты документа %1 в строке %2';
					|en = 'Date of receipt cannot be earlier than the %1 document date in line %2'; fa = 'Date of receipt cannot be earlier than the %1 document date in line %2';
					|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %1 nella riga %2';
					|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %1 w wierszu %2';
					|tr = 'Kabul tarihi, %2satırındaki %1belgesinin tarihinden önce olmamalıdır'"),
				Format(Date,"DLF=DD"), LineProducts_.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfReceipt"),
				,
				Cancel);
			
		EndIf;
		
		If Not OneDateReceipt 
			And ValueIsFilled(LineProducts_.DateOfReceipt) 
			And LineProducts_.DateOfReceipt < LineProducts_.DateOfShipment Then
		
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày giao hàng %1 trong dòng %2';
					|ru = 'Дата поступления должна быть не меньше даты отгрузки %1 в строке %2';
					|en = 'Date of receipt must be later than shipment date %1 in line %2'; fa = 'Date of receipt must be later than shipment date %1 in line %2';
					|it = 'La data di ricezione non deve essere precedente alla data di spedizione %1 nella riga %2';
					|pl = 'Data wpływu powinna być nie mniejsza niż data wysyłki %1 w wierszu %2';
					|tr = 'Kabul tarihi, %2satırındaki %1sevkiyatının tarihinden önce olmamalıdır'"),
				Format(LineProducts_.DateOfShipment,"DLF=DD"), LineProducts_.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfReceipt"),
				,
				Cancel);
			
		EndIf;
		
		// The date of receipt of PM Goods must be at least the date of the document
		If Not OneDateReceipt And ValueIsFilled(LineProducts_.DateOfShipment) And LineProducts_.DateOfShipment < BegOfDay(Date) Then
		
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %1 trong dòng %2';
					|ru = 'Дата отгрузки должна быть не меньше даты документа %1 в строке %2';
					|en = 'Shipment date must be later than the %1 document date in the %2 line'; fa = 'Shipment date must be later than the %1 document date in the %2 line';
					|it = 'La data di spedizione non deve essere precedente alla data del documento %1 nella riga %2';
					|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %1 w wierszu %2';
					|tr = 'Sevkiyat tarihi, %2satırındaki %1belgesinin tarihinden önce olmamalıdır'"),
				Format(Date,"DLF=DD"), LineProducts_.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfShipment"),
				,
				Cancel);
			
		EndIf;
		
		// The reason for cancellation is mandatory in the lines without the Canceled attribute
		If GetFunctionalOption("UseReasonsForPurchaseOrderCancellations")
			And LineProducts_.Canceled
			And Not ValueIsFilled(LineProducts_.CancellationReason) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Cần chỉ ra lý do hủy trong dòng %1';
					|ru = 'Необходимо указать причину отмены в строке %1';
					|en = 'Specify a cancellation reason in line %1'; fa = 'Specify a cancellation reason in line %1';
					|it = 'È necessario specificare il motivo di annullamento nella riga %1';
					|pl = 'Należy podać przyczynę anulowania w wierszu %1';
					|tr = 'İptal nedeni %1satırında belirtilmelidir'"),
				LineProducts_.LineNumber);
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "CancellationReason"),
				,
				Cancel);
			
		EndIf;
		
		// The item of expenditure should not refer to taxation in the procurement document
		// if the organization has included taxation by fact. use.
		If BatchAccountingIsEnabled
			And ByItsUse
			And Not LineProducts_.Canceled
			And ValueIsFilled(LineProducts_.ExpenseItem) Then
			
			Attributes = Common.ObjectAttributesValues(
				LineProducts_.ExpenseItem,
				"SeparateVATAccountingOption, CostAllocationOptionLocal");
			
				If (Attributes.CostAllocationOptionLocal = ToLinesOfBusiness
					Or Attributes.CostAllocationOptionLocal = ToCurrentPeriodExpensesDirectly
					Or Attributes.CostAllocationOptionLocal = ToProductionCosts
					)
					And Attributes.SeparateVATAccountingOption = FromDocument Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Khi sử dụng kế toán thuế GTGT theo thực tế sử dụng, trong dạng chi phí cần chọn kế toán riêng biệt thuế GTGT theo chi phí: ""Thuế GTGT được phân bổ theo dạng thuế tỷ lệ với doanh thu"" trong dòng %1';
						|ru = 'При использовании учета НДС по фактическому использованию, у статьи расходов должен быть выбран раздельный учет НДС по расходам: ""НДС распределяется по видам налогообложения пропорционально выручке"" в строке %1';
						|en = 'When using VAT accounting by actual usage, separate VAT accounting is to be selected for the expense item: ""VAT is allocated by taxation kinds in proportion to revenue"" in line %1'; fa = 'When using VAT accounting by actual usage, separate VAT accounting is to be selected for the expense item: ""VAT is allocated by taxation kinds in proportion to revenue"" in line %1';
						|it = 'Quando viene effettuata la contabilizzazione IVA per l''uso effettivo, per la voce di spesa deve essere selezionata la contabilizzazione IVA separata per le spese: ""IVA viene ripartita per tipi di tassazione in proporzione ai ricavi"" nella riga %1';
						|pl = 'W przypadku rozliczania podatku VAT za faktyczne wykorzystanie dla pozycji wydatków należy wybrać oddzielne rozliczanie podatku VAT według wydatków: ""VAT jest przydzielany według rodzajów opodatkowania proporcjonalnie do wpływów"" w wierszu %1';
						|tr = 'Fiili kullanımda KDV muhasebesi kullanılırken, gider kaleminin giderler için ayrı KDV muhasebesi olmalıdır: %1satırda ""KDV, vergilendirme türüne göre gelirle orantılı olarak tahsis edilir""'"),
					LineProducts_.LineNumber);
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "ExpenseItem"),
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If UseAgencyPurchasing
			And ValueIsFilled(LineProducts_.Purpose) Then
			AssignmentType = Common.ObjectAttributeValue(LineProducts_.Purpose, "AssignmentType");
				If AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal Then
					CheckRecordParametersForPurchasingUnderPrincipal(LineProducts_.LineNumber,
						LineProducts_.Purpose, Cancel);
				EndIf;
		EndIf;
		
		OrdersServer.CheckDuplicatesOfRowCodesInTable(ThisObject,
			LineProducts_.RowCode,
			LineProducts_.LineNumber,
			MatchingLineCodes,
			Cancel);
		
	EndDo;
	
	NotCheckedAttributeArray.Add("Goods.Department");
	ItemsTypes = New Array;
	ItemsTypes.Add(Enums.ItemsTypes.OperationService);
	ErrorText = NStr("vi = 'Người nhận dịch vụ không được chỉ định trong dòng %1 của danh sách hàng hóa';
					|ru = 'Не указан получатель услуг в строке %1 списка Товары';
					|en = 'Service recipient is not specified in line # %1 of the Item list'; fa = 'Service recipient is not specified in line # %1 of the Item list';
					|it = 'Il destinatario di servizi non è specificato nella riga %1 dell''elenco Merci';
					|pl = 'Nie wskazano odiorcy usług w wierszu %1 listy Wiersze pozycji';
					|tr = 'Mal listesinin %1satırında hizmet alıcısı belirtilmemiş'");
	ListOfBusinessOperationsExcludingServices = ProductsServer.ListOfBusinessOperationsExcludingServices();
	If  ListOfBusinessOperationsExcludingServices.FindByValue(BusinessOperation) = Undefined Then
		InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
	EndIf;
	
	ItemsTypes = New Array;
	ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	ErrorText = NStr("vi = 'Người nhận công việc không được chỉ định trong dòng %1 của danh sách hàng hóa';
					|ru = 'Не указан получатель работ в строке %1 списка Товары';
					|en = 'Work recipient is not specified in line #%1 of the Item list'; fa = 'Work recipient is not specified in line #%1 of the Item list';
					|it = 'Il destinatario di lavori non è specificato nella riga %1 dell''elenco Merci';
					|pl = 'Nie wskazano odbiorcy robót w wierszu %1 listy Wiersze pozycji';
					|tr = 'Mal listesinin %1satırında işin alıcısı belirtilmemiş'");
	ListOfBusinessOperationsExcludingWork = ProductsServer.ListOfBusinessOperationsExcludingWork();
	If ListOfBusinessOperationsExcludingWork.FindByValue(BusinessOperation) = Undefined Then
		InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
	EndIf;
	
	ItemsTypes = New Array;
	ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ErrorText = NStr("vi = 'Chưa chỉ ra người nhận hàng hóa tại dòng %1 của danh sách Hàng hóa';
					|ru = 'Не указан получатель товаров в строке %1 списка Товары';
					|en = 'Recipient of goods is not specified in line %1 of the Goods list'; fa = 'Recipient of goods is not specified in line %1 of the Goods list';
					|it = 'Destinatario articoli non indicato nella riga %1 dell''elenco Articoli';
					|pl = 'Nie wskazano odbiorcy towarów w wierszu %1 listy Towary';
					|tr = 'Ürün listesinin %1satırında ürünlerin alıcısı belirtilmemiş'");
	InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.PurchaseOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	QualityConfirmationDateRequired_ =
		Status = Enums.PurchaseOrderStatuses.Confirmed_
			Or Status = Enums.PurchaseOrderStatuses.Closed;
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Goods'; fa = 'کالاها';
			|it = 'Goods';
			|pl = 'Goods';
			|tr = 'Ürünler'"),
		".DateOfReceipt",
		QualityConfirmationDateRequired_);
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckChangesInBusinessOperations(Cancel);
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject, Cancel);
	
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses") Then
		ItemsAndDimensionsSelectionParameters = Documents.PurchaseOrder.ItemsAndDimensionsSelectionParameters(BusinessOperation);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes,
			ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	CheckParameters = VATAccountingERP.VerificationParametersFillingInDocumentOnVATTaxationPurchases();
	CheckParameters.TabularSectionName = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	VATAccountingERP.CheckCompletionOfPurchaseDocumentForVATTaxation(ThisObject, VATTaxation, CheckParameters, Cancel);
	
	CheckParameters = VATAccountingERP.ParametersForCheckingDocumentFillingByTypeOfActivity();
	CheckParameters.TabularSectionName = "Goods";
	CheckParameters.BankingDetailsNameExpenseItem = "ExpenseItem";
	CheckParameters.ExpenseAnalystDetailsName = "DimensionOfExpenses";
	VATAccountingERP.CheckCompletionOfDocumentByTypeOfVATActivity(ThisObject, PurchaseForActivity, CheckParameters, Cancel);
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
	
	DisableVerificationOfSeparateRegistrationOfGoods = ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
		And (ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced);
	
	If Not DisableVerificationOfSeparateRegistrationOfGoods Then
		PurchasesServer.CheckSeparateRegistrationOfGoods(Organization, BusinessOperation, Contract, 
			Goods.Unload(, "LineNumber, Products"), False);
	EndIf;
	
	CheckSeparateRegistrationOfServices(Goods.Unload(, "LineNumber, Products"));
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	PurchasesServer.PerformOrderControlAfterConducting(Ref, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status                  = Enums.PurchaseOrderStatuses.EmptyRef();
	RequestedDeliveryDate = Date(1,1,1);
	DateOfReceipt         = Date(1,1,1);
	DateOfShipment            = Date(1,1,1);
	ApprovalDate        = Date(1,1,1);
	MaximumRowCode   = 0;
	Approved              = False;
	VendorReferenceNumber = "";
	VendorReferenceDate  = Date(1,1,1);
	DocumentBasis       = Undefined;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	If ValueIsFilled(Terms) Then
		AgreementStatus = Common.ObjectAttributeValue(Terms, "Status");
		If AgreementStatus = Enums.StatusesOfTermsOfPurchase.Valid Then
			PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True);
			DeliveryDuration = PurchaseConditions.DeliveryDuration;
			If ValueIsFilled(PurchaseConditions.ShipmentDueDate) Then
				DocumentDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
				RequestedDeliveryDate = Documents.PurchaseOrder.DateAccordingToCompanyCalendar(DocumentDate,
					PurchaseConditions.ShipmentDueDate + DeliveryDuration);
				DateOfShipment = Documents.PurchaseOrder.DateAccordingToCompanyCalendar(DocumentDate,
					PurchaseConditions.ShipmentDueDate);
				DateOfReceipt = RequestedDeliveryDate;
			EndIf;
		Else
			Terms = Catalogs.TermsOfPurchaseFromVendors.EmptyRef();
		EndIf;
	EndIf;
	
	If Not GetFunctionalOption("UsePaymentsToSelfEmployedPersons") Then
		OperationWithSelfEmployedPerson = False;
	EndIf;
	
	For Each TSRow In Goods Do
		
		TSRow.RowCode       = 0;
		TSRow.DateOfReceipt = Date(1,1,1);
		TSRow.DateOfShipment = Date(1,1,1);
		TSRow.Canceled = False;
		TSRow.CancellationReason = Catalogs.ReasonsForPurchaseOrderCancellation.EmptyRef();
		
	EndDo;
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	InitializeDocument();
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure CheckRecordParametersForPurchasingUnderPrincipal(LineNumber, Purpose, Cancel)
	
	SetPrivilegedMode(True);
	
	If Not BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đối với mặt hàng trong dòng %1 được mua theo chương trình đại lý, chỉ có thể sử dụng giao dịch ''''Mua hàng từ nhà cung cấp''''';
					|ru = 'Для номенклатуры в строке %1, закупаемой по агентской схеме, можно использовать только операцию ""Закупка у поставщика""';
					|en = 'Only the ""Purchase from vendor"" transaction can be used for the items in line %1 purchased on agency basis'; fa = 'Only the ""Purchase from vendor"" transaction can be used for the items in line %1 purchased on agency basis';
					|it = 'Per l''articolo nella riga %1, acquistato in regime di agenzia, si può usare solo l''operazione ""Acquisto dal fornitore""';
					|pl = 'Dla nomenklatury w wierszu %1, kupowanej według schematu agencyjnego, można używać tylko operacji ""Zakup u dostawcy""';
					|tr = '%1Satırındaki acente programı kapsamında satın alınan öğeler için yalnızca ""tedarikçiden satın alım"" işlemi kullanılabilir'"),
				LineNumber);
		
		Common.MessageToUser(
		ErrorText ,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods",LineNumber, "Purpose"),
		,
		Cancel);
	EndIf;
		
	CurrencyOfDestinationAgreement  = Common.ObjectAttributeValue(Purpose, "Contract.ARAPCurrency");
	If CurrencyOfDestinationAgreement <> Currency Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với mặt hàng trong dòng %1 được mua theo sơ đồ đại lý, loại tiền được chỉ định trong hợp đồng đích phải khớp với loại tiền của chứng từ';
				|ru = 'Для номенклатуры в строке %1, закупаемой по агентской схеме, валюта, указанная в договоре назначения, должна совпадать с валютой документа';
				|en = 'The currency specified in the assignment contract must match the document currency for the items in line %1 purchased on agency basis'; fa = 'The currency specified in the assignment contract must match the document currency for the items in line %1 purchased on agency basis';
				|it = 'Per l''articolo nella riga %1, acquistato con il regime di agenzia, la valuta indicata nel contratto deve coincidere con la valuta del documento';
				|pl = 'Dla pozycji w wierszu %1, nabywanej według schematu agencyjnego, waluta, podana w umowie przeznaczenia, powinna zbiegać się z walutą dokumentu';
				|tr = '%1Satırındaki acente programı kapsamında satın alınan ürünler için varış sözleşmesinde belirtilen para birimi belgenin para birimiyle eşleşmelidir'"),
			LineNumber);
		
		Common.MessageToUser(
		ErrorText ,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods", LineNumber, "Purpose"),
		,
		Cancel);
	EndIf;
	
	OrganizationOfContractOfAppointment  = Common.ObjectAttributeValue(Purpose, "Contract.Organization");
	If OrganizationOfContractOfAppointment <> Organization Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đối với mặt hàng trong dòng %1 được mua theo sơ đồ đại lý, doanh nghiệp được chỉ định trong hợp đồng đích phải trùng với doanh nghiệp của chứng từ';
				|ru = 'Для номенклатуры в строке %1, закупаемой по агентской схеме, организация, указанная в договоре назначения, должна совпадать с организацией документа';
				|en = 'The company specified in the assignment contract must match the company specified in the document for the items in line %1 purchased on agency basis'; fa = 'The company specified in the assignment contract must match the company specified in the document for the items in line %1 purchased on agency basis';
				|it = 'Per l''articolo nella riga %1, acquistato secondo lo schema di agenzia, l''azienda indicata nel contratto di destinazione deve coincidere con l''azienda nel documento';
				|pl = 'Dla pozycji w wierszu %1, nabywanej według schematu agencyjnego, firma, podana w umowie przeznaczenia, powinna zbiegać się z firmą dokumentu';
				|tr = '%1 satırındaki acente programı kapsamında satın alınan öğeler için varış sözleşmesinde adı geçen iş yeri, belgenin düzenlendiği iş yeriyle aynı olmalıdır'"),
			LineNumber);
		
		Common.MessageToUser(
		ErrorText ,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods", LineNumber, "Purpose"),
		,
		Cancel);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnSupplyRequest(ApplicationForCollateral)
	
	ReceivingParameters = Documents.ApplicationForCollateral.ParametersForReceivingFillInDataBasedOn();
	ReceivingParameters.ItemsType = ProductsServer.SupportedDocumentItemTypes(Ref);
	FillingData = Documents.ApplicationForCollateral.FillingDataBasedOn(
		ApplicationForCollateral,
		ReceivingParameters);
	
	// Safe filling of the header:
	HeaderProperties = New Structure;
	HeaderProperties.Insert("Organization");
	HeaderProperties.Insert("Warehouse");
	HeaderProperties.Insert("Department");
	HeaderProperties.Insert("LineOfBusiness");
	HeaderProperties.Insert("Currency");
	FillPropertyValues(HeaderProperties, FillingData.Header);
	FillPropertyValues(ThisObject, HeaderProperties);
	
	DocumentBasis = ApplicationForCollateral;
	BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier; // When selecting a supplier, the write-off flag for expenses should not be recalculated.
	
	// Filling PM: 
	If FillingData.Goods.Columns.Find("Department") = Undefined Then
		// To write off expenses, fill in the division from the header:
		FillingData.Goods.Columns.Add(
			"Department",
			New TypeDescription("CatalogRef.BusinessStructure"));
		
		FillingData.Goods.FillValues(Department, "Department");
	EndIf;
	
	Goods.Load(FillingData.Goods);
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False, "ToExpenseAs");
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
		ThisObject, 
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	Partner = Basis;
	PurchasesServer.CheckPossibilityOfEnteringBasedOnPartnerSupplierCompetitor(Partner);
	FillInDefaultPurchaseConditions();
	
EndProcedure

Procedure FillInDocumentBasedOnAgreementWithSupplier(Val CatalogBasis)
	
	Query = New Query("
		|SELECT
		|	TermsOfPurchases.Ref  AS Terms,
		|	TermsOfPurchases.Partner AS Partner,
		|
		|	TermsOfPurchases.Status  AS DocumentStatus,
		|	CASE
		|		WHEN
		|			TermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsStatus,
		|	CASE
		|		WHEN TermsOfPurchases.BusinessOperation
		|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS TheseAreAgencyServices,
		|	TermsOfPurchases.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
		|WHERE
		|	TermsOfPurchases.Ref = &CatalogBasis
		|");
		
	Query.SetParameter("CatalogBasis", CatalogBasis);
		
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfPurchase.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Terms,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
		
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(,Selection.TheseAreAgencyServices);
	
	FillPropertyValues(ThisObject, Selection);

	FillInTermsOfPurchaseUnderAgreement();

EndProcedure

Procedure FillInDocumentBasedOnTransaction(CustomerTransaction)

	If Documents.SalesOrder.ThereAreSeparateOrdersForTransaction(CustomerTransaction) Then

		FillInDocumentOnBasisOfTransactionOnSeparateOrders(CustomerTransaction);

	Else

		FillInDocumentOnBasisOfTransactionInSummary(CustomerTransaction);

	EndIf;

EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	// List of Attributes that cannot be copied from the selection:
	NotDetailsToFillIn = New Array;
	NotDetailsToFillIn.Add("Posted");
	NotDetailsToFillIn.Add("DeletionMark");
	NotDetailsToFillIn.Add("Manager");
	
	AttributesToExclude = New Array;
	For Each AttributesThatCannotBeFilledIn In NotDetailsToFillIn Do
		If Not FillingData.Property(AttributesThatCannotBeFilledIn) Then
			Continue;
		EndIf;
		
		AttributesToExclude.Add(AttributesThatCannotBeFilledIn);
		
	EndDo;
	
	If ValueIsFilled(AttributesToExclude) Then
		AttributesToExclude = StrConcat(AttributesToExclude, ", ");
	Else
		AttributesToExclude = Undefined;
	EndIf;
	
	FillPropertyValues(ThisObject, FillingData,, AttributesToExclude);
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If FillingData.Property("Goods") Then
		If TypeOf(FillingData.Goods) = Type("Array") Then
			UploadProducts(FillingData.Goods);
		Else
			Goods.Load(FillingData.Goods);
		EndIf;
		UseAccountingOfOtherIncomeExpenses = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
		If UseAccountingOfOtherIncomeExpenses Then
			For Each RowOfProduct In Goods Do
				If Common.ObjectAttributeValue(RowOfProduct.Products, "ItemsType") = Enums.ItemsTypes.OperationService Then
					RowOfProduct.ToExpenseAs = True;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	PurchasesServer.CheckPossibilityOfEnteringBasedOnPartnerSupplierCompetitor(Partner);
	CheckToFillInReceiptByOneDate();
	
	If FillingData.Property("LineOfBusiness") 
		And ValueIsFilled(FillingData.LineOfBusiness) Then
		If Not Common.ObjectAttributeValue(FillingData.LineOfBusiness,"CostAccounting") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
	EndIf;
	
	If FillingData.Property("Goods") Then //Filling out of the "Provision of Needs" processing.
		
		If ValueIsFilled(Partner) And Not ValueIsFilled(Terms) Then
			FillInDefaultPurchaseConditions(False);
		EndIf;
		
		If ValueIsFilled(Terms) Then
			LineOfBusinessBeforeChange = LineOfBusiness;
			ReFillDates = Not ValueIsFilled(DateOfReceipt);
			FillInTermsOfPurchaseUnderAgreement(False, ReFillDates);
			If LineOfBusinessBeforeChange <> LineOfBusiness And ValueIsFilled(LineOfBusiness) Then
				Query = New Query();
				Query.SetParameter("Assignments", Goods.Unload(, "Purpose").UnloadColumn("Purpose"));
				Query.SetParameter("LineOfBusiness", LineOfBusiness);
				Query.Text =
					"SELECT TOP 1
					|	TRUE AS HasError
					|FROM
					|	Catalog.Assignments AS AllAssignments
					|WHERE
					|	AllAssignments.Ref IN(&Assignments)
					|		AND AllAssignments.LineOfBusiness <> VALUE(Catalog.LinesOfBusiness.EmptyRef)
					|		AND AllAssignments.LineOfBusiness <> &LineOfBusiness";
				If Not Query.Execute().IsEmpty() Then
					LineOfBusiness = LineOfBusinessBeforeChange;
					Terms = Undefined;
					Contract = Undefined;
					FillInTermsOfPurchaseUnderAgreement(False, ReFillDates);
				EndIf;
			EndIf;
		Else
			
			BusinessOperation = Metadata.Documents.PurchaseOrder.Attributes.BusinessOperation.FillValue;
			
			FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
			VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
			
			FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
			VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
			
		EndIf;
		
		If FillingData.Property("Warehouse") Then // so that the agreement does not override the warehouse.
			ThisObject.Warehouse = FillingData.Warehouse;
		EndIf;
		
		If FillingData.Property("Manager") Then
			Manager = FillingData.Manager;
		EndIf;
		
		If Not ValueIsFilled(Currency) Then
			Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
		EndIf;

		FillInPricesByPriceType(); //filling in prices according to the types of prices specified in the "Products" table.
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);

	ElsIf ValueIsFilled(Terms) Then
		
		If Not ValueIsFilled(Contract) Then
			
			ContractBusinessTransaction = ?(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
													Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder,
												Enums.BusinessTransactions.PurchaseFromSupplier,
												BusinessOperation);
			ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = Currency;
			Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
			
		EndIf;
	
		FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
		VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
		
		FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
		VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
		
		FillThePricesByTermsOfSales();
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		
	Else
		FillInDefaultPurchaseConditions();
	EndIf;

	PartnersProductsServer.FillInPartnerProductListByProductNameWhenPartnerChanges(Goods, Partner);
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.SalesOrder") Then
		DocumentBasisDetails = Common.ObjectAttributesValues(DocumentBasis, "BusinessOperation, PriceIncludesVAT");
		If DocumentBasisDetails.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
			PriceIncludesVAT = DocumentBasisDetails.PriceIncludesVAT;
			FillInPricesOrderedByPrincipal();
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInPricesByPriceType()

	CachedValues = Undefined;
	FillParameters = New Structure;
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Terms", Terms);
	
	RecalculateAmountTakingIntoAccountManualDiscount	= New Structure("Clear", False);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);

	// Filling in the prices
	Parameters = New Structure;
	Parameters.Insert("PopulationFields", "Price, VATRate");
	Parameters.Insert("ColumnsByValue", New Structure);
	Parameters.Insert("OtherColumnNames", New Structure);
	
	TMCommonUseClientServer.SupplementStructure(Parameters, FillParameters, True);

	// Getting the upload by the tabular part
	Table = TMCommonUse.ExportValuesTable(
		Goods,
		Undefined,
		"LineNumber, Products, Characteristic, Package, VendorPriceKind",
		Parameters.ColumnsByValue,
		Parameters.OtherColumnNames);

	// Receiving the request.
	ParametersForGettingPrices = PartnerPricesFillingServer.NewParametersForGettingPartnerProductPrices();
	ParametersForGettingPrices.Date                         = ?(ValueIsFilled(Parameters.Date), Parameters.Date, CurrentSessionDate());
	ParametersForGettingPrices.Currency                       = Parameters.Currency;
	ParametersForGettingPrices.VATTaxation           = VATTaxation;
	ParametersForGettingPrices.ReturnReusablePackage = ToReturnReusablePackage;
	
	QueryResult = PartnerPricesFillingServer.PartnerProductPrices(Table, ParametersForGettingPrices);
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	RowsToProcess = New Array();
	FillingStructure = New Structure(Parameters.PopulationFields);
	Selection = QueryResult.Select();
	While Selection.Next() Do
		FillPropertyValues(FillingStructure, Selection);
		TSRow = Goods[Selection.LineNumber - 1];
		If Not ValueIsFilled(TSRow.VendorPriceKind) Then
			Continue;
		EndIf; 
		FillPropertyValues(TSRow, FillingStructure);
		RowsToProcess.Add(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		CachedValues);
		
EndProcedure

Procedure FillInDocumentBasedOnCustomerSOrder(Val FillingData)
	
	SalesOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.SalesOpportunity AS SalesOpportunity,
		|	SalesOrder.Warehouse AS DocumentWarehouse,
		|	ISNULL(SalesOrder.Warehouse.IsFolder, FALSE) AS IsFolder,
		|	SalesOrder.VATTaxation AS PurchaseForActivity,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|				OR SalesOrder.LineOfBusiness.VendorARAP
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &SalesOrder");
	Query.SetParameter("SalesOrder", SalesOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization            = Attributes.Organization;
	SalesOpportunity                 = Attributes.SalesOpportunity;
	DocumentBasis      = SalesOrder;
	Priority              = Attributes.Priority;
	PurchaseForActivity = Attributes.PurchaseForActivity;
	LineOfBusiness= Attributes.LineOfBusiness;
	
	Warehouse = FillingData.Warehouse;
	If Not ValueIsFilled(Warehouse)
			And Attributes.IsFolder
			And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		
		Warehouse = Attributes.DocumentWarehouse;
		
	EndIf;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
	FoundationDocumentData = Common.ObjectAttributesValues(DocumentBasis,
								"BusinessOperation, PriceIncludesVAT, Currency, VATTaxation");
	
	If FoundationDocumentData.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		PriceIncludesVAT    = FoundationDocumentData.PriceIncludesVAT;
		Currency             = FoundationDocumentData.Currency;
		VATTaxation = FoundationDocumentData.VATTaxation;
		
		FillInPricesOrderedByPrincipal();
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnRequestForRefund(Val FillingData)
	
	ReturnRequest = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	SalesOrder.Priority AS Priority,
		|	SalesOrder.Organization AS Organization,
		|	SalesOrder.SalesOpportunity AS SalesOpportunity,
		|	SalesOrder.VATTaxation AS PurchaseForActivity,
		|	CASE
		|		WHEN SalesOrder.LineOfBusiness.CostAccounting
		|				OR SalesOrder.LineOfBusiness.VendorARAP
		|			THEN SalesOrder.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS SalesOrder
		|WHERE
		|	SalesOrder.Ref = &ReturnRequest");
	Query.SetParameter("ReturnRequest", ReturnRequest);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization            = Attributes.Organization;
	Priority              = Attributes.Priority;
	SalesOpportunity                 = Attributes.SalesOpportunity;
	DocumentBasis      = ReturnRequest;
	PurchaseForActivity = Attributes.PurchaseForActivity;
	LineOfBusiness= Attributes.LineOfBusiness;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnTransferOrder(Val FillingData)
	
	TransferOrder = FillingData.Basis;
		Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderDocument.Department AS Department,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|				OR OrderDocument.LineOfBusiness.VendorARAP
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness,
		|	OrderDocument.TransferForActivity AS PurchaseForActivity
		|FROM
		|	Document.TransferOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &TransferOrder");
	
	Query.SetParameter("TransferOrder", TransferOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	DocumentBasis       = TransferOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	PurchaseForActivity  = Attributes.PurchaseForActivity;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
	CheckCorrectnessOfDirectionOfActivity();
	
EndProcedure

Procedure FillInDocumentBasedOnOrderForDomesticConsumption(Val FillingData)
	
	ConsumptionOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderDocument.Department AS Department,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|				OR OrderDocument.LineOfBusiness.VendorARAP
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness,
		|	OrderDocument.ConsumptionForActivity AS ConsumptionForActivity
		|FROM
		|	Document.InventoryConsumptionOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &ConsumptionOrder");
	
	Query.SetParameter("ConsumptionOrder", ConsumptionOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	DocumentBasis       = ConsumptionOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	PurchaseForActivity  = Attributes.ConsumptionForActivity;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnAssemblyOrder(Val FillingData)
	
	ByAssemblyDisassemblyOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.SalesOpportunity AS SalesOpportunity,
		|	OrderDocument.Department AS Department,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|				OR OrderDocument.LineOfBusiness.VendorARAP
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness,
		|	OrderDocument.AssemblyForActivity AS AssemblyForActivity
		|FROM
		|	Document.ByAssemblyDisassemblyOrder AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &ByAssemblyDisassemblyOrder");
	
	Query.SetParameter("ByAssemblyDisassemblyOrder", ByAssemblyDisassemblyOrder);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	SalesOpportunity                  = Attributes.SalesOpportunity;
	Priority               = Attributes.Priority;
	DocumentBasis       = ByAssemblyDisassemblyOrder;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	PurchaseForActivity  = Attributes.AssemblyForActivity;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseRequest(FillingData)
	
	FillPropertyValues(ThisObject, FillingData);
	FillInGoodsFromBase(FillingData.Goods);
	DocumentBasis = FillingData.Basis;
	
	Date = CurrentSessionDate();
	
	NamesOfContractDetails = New Array;
	NamesOfContractDetails.Add("BusinessOperation");
	NamesOfContractDetails.Add("ForeignCurrencyTransaction");
	NamesOfContractDetails.Add("FinancialAccountingGroup");
	ContractDetails_ = Common.ObjectAttributesValues(Contract, NamesOfContractDetails);
	
	PurchaseConditions = Undefined;
	
	If ValueIsFilled(Terms) Then
		
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms, True);
		
	ElsIf ValueIsFilled(Partner) Then
		
		SelectionOfProcurementConditions = New Structure;
		SelectionOfProcurementConditions.Insert("ConsiderWarehouseGroups", True);
		SelectionOfProcurementConditions.Insert("PriceIncludesVAT", PriceIncludesVAT);
		If ValueIsFilled(Contract) Then
			SelectionOfProcurementConditions.Insert("ContractsAreUsed", True);
		EndIf;
		
		PurchaseConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner, SelectionOfProcurementConditions);
		
	EndIf;
	
	ToFillInAccordingToTermsOfPurchase = ValueIsFilled(PurchaseConditions);
	
	#Region Terms
	If ToFillInAccordingToTermsOfPurchase Then
		Terms = PurchaseConditions.Terms;
	EndIf;
	#EndRegion
	
	#Region BusinessOperation
	If ValueIsFilled(ContractDetails_.BusinessOperation) Then
		BusinessOperation = ContractDetails_.BusinessOperation;
	ElsIf ToFillInAccordingToTermsOfPurchase Then
		BusinessOperation = PurchaseConditions.BusinessOperation;
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Ref.Metadata().Attributes.BusinessOperation.FillValue;
	EndIf;
	#EndRegion
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	#Region Contract
	// The Contract has not been transferred and the agreement has not been completed, or supports the use of Contracts
	If Not ValueIsFilled(Contract)
		And (Not ToFillInAccordingToTermsOfPurchase
			Or (PurchaseConditions.ContractsAreUsed <> Undefined
					And PurchaseConditions.ContractsAreUsed)) Then

		ContractBusinessTransaction = ?(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
												Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder,
											Enums.BusinessTransactions.PurchaseFromSupplier,
											BusinessOperation);
    	
		ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Currency;
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
		ContractDetails_ = Common.ObjectAttributesValues(Contract, NamesOfContractDetails); // Updating the Contract Attributes
		
	EndIf;
	#EndRegion
	
	ARAPObjectSettings = ARAPAccountingServer.ARAPObjectSettings(True, Undefined, Terms, Contract);
	
	#Region LineOfBusiness
	If Not ValueIsFilled(LineOfBusiness)
		And GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	#EndRegion

	#Region PaymentInCurrency_FinancialAccountingGroup
	
	ContractsAreNotUsedByAgreement = ToFillInAccordingToTermsOfPurchase
		And (Not ValueIsFilled(PurchaseConditions.ContractsAreUsed) 
			Or Not PurchaseConditions.ContractsAreUsed);
	
	If ContractsAreNotUsedByAgreement Then
			
		// The agreement under which Contracts are not used is indicated
		ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
		FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
		
	Else
		
		ForeignCurrencyTransaction = ContractDetails_.ForeignCurrencyTransaction;
		FinancialAccountingGroup = ContractDetails_.FinancialAccountingGroup;
		
	EndIf;
	
	#EndRegion
	
	If ToFillInAccordingToTermsOfPurchase Then
		
		RegisterVendorPrices   = PurchaseConditions.RegisterVendorPrices;
		ToReturnReusablePackage      = PurchaseConditions.ReturnReusablePackage;
		ReusablePackageReturnCycleLength = PurchaseConditions.ReusablePackageReturnCycleLength;
		PackageDepositIsRequired           = PurchaseConditions.PackageDepositIsRequired;
		DeliveryDuration           = PurchaseConditions.DeliveryDuration;
		PaymentMethod                    = PurchaseConditions.PaymentMethod;
		
	EndIf;
	
	#Region CashAccount
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization             = Organization;
	ParametersStructure.PaymentMethod             = PaymentMethod;
	ParametersStructure.LineOfBusiness = LineOfBusiness;
	
	CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	#EndRegion
	
	#Region Taxation
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	#EndRegion
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	#Region Dates
	If ToFillInAccordingToTermsOfPurchase And ValueIsFilled(PurchaseConditions.ShipmentDueDate) Then
		DateOfShipment = Documents.PurchaseOrder.DateAccordingToCompanyCalendar(Date, PurchaseConditions.ShipmentDueDate);
	Else
		DateOfShipment = Date;
	EndIf;
	
	OneDateReceipt = True;
	ProvisionInDocumentsServer.FillInDetailsInCollection(Goods, "DateOfShipment", DateOfShipment);
	 
	RecalculateDatesByCalendar(DeliveryDuration); // DateOfReceipt
	RequestedDeliveryDate = DateOfReceipt;
	#EndRegion
	
EndProcedure

Procedure FillInDocumentBasedOnOrderOfMaterialsInProduction(Val FillingData)
	
	OrderOfMaterials = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	OrderDocument.Priority AS Priority,
		|	OrderDocument.Organization AS Organization,
		|	OrderDocument.Department AS Department,
		|	CASE
		|		WHEN OrderDocument.LineOfBusiness.CostAccounting
		|				OR OrderDocument.LineOfBusiness.VendorARAP
		|			THEN OrderDocument.LineOfBusiness
		|	END AS LineOfBusiness,
		|	OrderDocument.ConsumptionForActivity AS ConsumptionForActivity
		|FROM
		|	Document.OrderOfMaterialsForProduction AS OrderDocument
		|WHERE
		|	OrderDocument.Ref = &OrderOfMaterials");
	
	Query.SetParameter("OrderOfMaterials", OrderOfMaterials);
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization             = Attributes.Organization;
	Priority               = Attributes.Priority;
	DocumentBasis       = OrderOfMaterials;
	Department           = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	PurchaseForActivity  = Attributes.ConsumptionForActivity;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
	CheckCorrectnessOfDirectionOfActivity();
	
EndProcedure


Procedure FillInDocumentBasedOnOrderToProcessor2_5(Val FillingData)
	
	SubcontractOrder = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	Table.Priority AS Priority,
		|	Table.Organization AS Organization,
		|	Table.Department AS Department,
		|	Table.MaterialsWarehouse AS DocumentWarehouse,
		|	ISNULL(Table.MaterialsWarehouse.IsFolder, FALSE) AS IsFolder,
		|	CASE
		|		WHEN Table.LineOfBusiness.CostAccounting
		|				OR Table.LineOfBusiness.VendorARAP
		|			THEN Table.LineOfBusiness
		|	END AS LineOfBusiness
		|FROM
		|	Document.SubcontractOrder2_5 AS Table
		|WHERE
		|	Table.Ref = &OrderDocument");
	Query.SetParameter("OrderDocument", SubcontractOrder);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	// Filling in the header
	Organization = Attributes.Organization;
	DocumentBasis = SubcontractOrder;
	Department = Attributes.Department;
	Priority = Attributes.Priority;
	LineOfBusiness = Attributes.LineOfBusiness;
	
	Warehouse = FillingData.Warehouse;
	If Not ValueIsFilled(Warehouse)
			And Attributes.IsFolder
			And GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments") Then
		
		Warehouse = Attributes.DocumentWarehouse;
		
	EndIf;
	
	FillInGoodsFromBase(FillingData.AddressGoods);
	
EndProcedure

Procedure FillInDocumentBasedOnProductionStage(Val FillingData)
	
	ProductionStage = FillingData.Basis;
	Query = New Query(
		"SELECT
		|	Table.Organization AS Organization,
		|	Table.Department AS Department,
		|	CASE
		|		WHEN Table.LineOfBusiness.CostAccounting
		|				OR Table.LineOfBusiness.VendorARAP
		|			THEN Table.LineOfBusiness
		|	END AS LineOfBusiness,
		|	Table.ProductionIssueForActivity AS ProductionIssueForActivity
		|FROM
		|	Document.ProductionStage2_2 AS Table
		|WHERE
		|	Table.Ref = &OrderDocument");
	Query.SetParameter("OrderDocument", ProductionStage);
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Organization = Attributes.Organization;
	DocumentBasis = ProductionStage;
	Department = Attributes.Department;
	LineOfBusiness = Attributes.LineOfBusiness;
	PurchaseForActivity = Attributes.ProductionIssueForActivity;
	
	Warehouse = FillingData.Warehouse;
	
	FillInGoodsFromBase(FillingData.AddressGoods);

EndProcedure

Procedure InitializeDocument(FillingData = Undefined)

	Organization           = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Department         = SettingsValueCached.UserDivision(Manager, Department);
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		BankAccount, PaymentMethod);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    	= Organization;
	ParametersStructure.PaymentMethod 	= PaymentMethod;
	ParametersStructure.CashAccount 			= CashAccount;
	CashAccount                 = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	Warehouse                 = SettingsValueCached.GetDefaultWarehouse(
		Warehouse, 
		GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments"));
	Priority             = SettingsValueCached.GetDefaultPriority(Priority);
	
	If Not (TypeOf(FillingData) = Type("Structure") And FillingData.Property("Goods")) Then
		OneDateReceipt = True;
	EndIf;
	
	If Not GetFunctionalOption("UsePurchaseOrderStatuses") Then
		Status = Enums.PurchaseOrderStatuses.Closed;
	Else
		Status = Enums.PurchaseOrderStatuses.Approved;
	EndIf;
	
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(Undefined, Contract);
	ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.PurchaseOrder.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, True);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	If TypeOf(FillingData) <> Type("Structure") Then
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
		WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False, "ToExpenseAs");
	EndIf;
	
	If Not ValueIsFilled(DeliveryAddressForVendor)
		And (DeliveryMethod = Enums.TransportMethods.EmptyRef()
			Or DeliveryMethod = Enums.TransportMethods.ByVendorToOurWarehouse)
		And ValueIsFilled(Warehouse) Then
			
			If Not Catalogs.Warehouses.IsFolder(Warehouse) Then
				AvailableWarehouses = New Array;
				AvailableWarehouses.Add(Warehouse);
			Else
				AvailableWarehouses = Goods.UnloadColumn("Warehouse");
			EndIf;
			
			Documents.PurchaseOrder.FillInDeliveryAddressForSupplier(DeliveryAddressForVendor, AvailableWarehouses, Date);
		
	EndIf;
	
	StructureOfActions = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInDocumentOnBasisOfContract(Val CatalogBasis)
	
	Query = New Query("
		|SELECT
		|	Contract.Ref  AS Contract,
		|	Contract.Partner AS Partner,
		|
		|	Contract.Status AS  DocumentStatus,
		|	CASE
		|		WHEN
		|			Contract.Status <> VALUE(Enum.CounterpartyContractStatuses.Valid)
		|		THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS ThereAreErrorsStatus,
		|	Contract.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Catalog.CounterpartyContracts AS Contract
		|WHERE
		|	Contract.Ref = &CatalogBasis
		|");
		
	Query.SetParameter("ContractBasis", CatalogBasis);
		
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Contract,
		Selection.DocumentStatus,
		False,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);

	FillInTermsOfPurchaseUnderAgreement();

EndProcedure

#EndRegion

#Region Other

Procedure CheckChangesInBusinessOperations(Cancel)
	
	OrderIsNotPaidFor = BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale;
	
	If Not IsNew() And OrderIsNotPaidFor Then
	
		Query = New Query("
		|SELECT
		|	VendorsARAPAccounting.SumReceipt AS PayAmount
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Turnovers(,,Period,
		|		ARAPObject.Object = &Ref
		|	) AS VendorsARAPAccounting
		|
		|	INNER JOIN
		|		Document.PurchaseOrder AS DocumentData
		|	ON
		|		DocumentData.Ref = &Ref
		|		AND DocumentData.BusinessOperation <> &BusinessOperation
		|WHERE
		|	VendorsARAPAccounting.SumReceipt > 0
		|");
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đơn hàng đặt nhà cung cấp đã được thanh toán. Không thể lập giao dịch %1';
					|ru = 'Заказ поставщику оплачен. Нельзя устанавливать операцию %1';
					|en = 'Purchase order is paid. Cannot perform the ""%1"" operation'; fa = 'Purchase order is paid. Cannot perform the ""%1"" operation';
					|it = 'Ordine è stato pagato al fornitore. Impossibile impostare l''operazione %1';
					|pl = 'Zamówienie zakupu opłacono. Nie można ustawić operacji %1';
					|tr = 'Satın alma siparişi ödenmiş. %1 işlemi ayarlanamaz'"),
				BusinessOperation);
			CommonClientServer.MessageToUser(
				Text,
				ThisObject,
				"BusinessOperation",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckSeparateRegistrationOfServices(GoodsTable) Export
	
	If Not(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery) Then
		Return;
	EndIf;
	
	PurchaseRegistrationOption = Common.ObjectAttributeValue(Contract, "PurchaseRegistrationOption");
	
	If Not PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices Then
		Return;
	EndIf;
	
	OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(Contract, "OptionForRegisteringServiceReceiptDocuments");
	
	If OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTProducts_1.LineNumber AS LineNumber,
	|	CatProducts.ItemsType AS ItemsType,
	|	CatProducts.Ref AS Ref
	|FROM
	|	Catalog.Products AS CatProducts
	|		INNER JOIN TTProducts_1 AS TTProducts_1
	|		ON CatProducts.Ref = TTProducts_1.Products
	|WHERE
	|	CatProducts.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))";
	
	Query.SetParameter("GoodsTable", GoodsTable);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		MessageTemplate = NStr("vi = 'Theo doanh nghiệp ""%1"" trong hợp đồng ""%2"" chưa thiết lập tạo dịch vụ / công việc riêng biệt, 
			|Không cho phép kết chuyển chứng từ với giao dịch kinh tế ""%3"" đối với dịch vụ/công việc';
			|ru = 'По организации ""%1"" в договоре ""%2"" не установлено раздельное оформление услуг/работ, 
			|Проведение документа с хозяйственной операцией ""%3"" для услуг/работ не допускается';
			|en = 'Separate registration of services/works is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for services/works'; fa = 'Separate registration of services/works is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for services/works';
			|it = 'Separate registration of services/works is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for services/works';
			|pl = 'Separate registration of services/works is not set for the ""%1"" company in the ""%2"" contract. 
			|Cannot post the document with the ""%3"" business transaction for services/works';
			|tr = '""%1"" iş yeri için ""%2"" sözleşmesinde hizmetlerin/işlerin ayrı düzenlenmesi belirlenmemiş, 
			|""%3"" işlem türüne sahip belgenin hizmetler/işler için işlenmesine izin verilmez'");
		
		MessageText = StrTemplate(MessageTemplate, Organization, Contract, BusinessOperation);
		
		Common.MessageToUser(MessageText);
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			MessageTemplate = NStr("vi = 'Trong dòng %1 của danh sách ""Hàng hóa"" đã chọn mặt hàng ""%2"" có kiểu ""%3""';
									|ru = 'В строке %1 списка ""Товары"" выбрана номенклатура ""%2"" с типом ""%3""';
									|en = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected'; fa = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|it = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|pl = 'In line %1 of the ""Goods"" list, the ""%2"" item with the ""%3"" type is selected';
									|tr = '""Ürünler"" listesinin %1 satırında ""%3"" türünde ""%2"" öğesi seçilmiştir'");
			
			MessageText = StrTemplate(MessageTemplate, Selection.LineNumber, Selection.Ref, Selection.ItemsType);
			
			CommonClientServer.MessageToUser(MessageText);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransactionOnSeparateOrders(Val CatalogBasis)
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder IN
		|		(SELECT
		|				T.SalesOrder
		|			FROM
		|				TTOrdersByTransaction AS T)";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode, Warehouse";
	TableFormationParameters.Indicators = "Ordered, Shipped";
	TableFormationParameters.Resources = "Count";
	TableFormationParameters.Indexes = TableFormationParameters.Group;
	TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
	
	TT_ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	T.Ref AS SalesOrder
	|
	|INTO TTOrdersByTransaction
	|
	|FROM
	|	Document.SalesOrder AS T
	|WHERE
	|	T.SalesOpportunity = &SalesOpportunity
	|	AND T.Status IN (VALUE(Enum.SalesOrderStatuses.ToSupply),
	|					VALUE(Enum.SalesOrderStatuses.ToShip))
	|" +
	Common.QueryBatchSeparator() +
	TT_ShipmentOrdersTurnoverExpanded +
	Common.QueryBatchSeparator() +
	"SELECT
	|	T.Products          AS Products,
	|	T.Characteristic        AS Characteristic,
	|	T.Warehouse                 AS Warehouse,
	|	T.Purpose            AS Purpose,
	|	MAX(T.LineNumber) AS LineNumber,
	|	MIN(T.OrderDate)   AS OrderDate,
	|	SUM(T.Ordered)       AS Ordered
	|	
	|INTO OrderProducts_0
	|
	|FROM
	|	(SELECT
	|		References.ReferenceOrder.Date AS OrderDate,
	|		References.Products      AS Products,
	|		References.Characteristic    AS Characteristic,
	|		References.Warehouse             AS Warehouse,
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL THEN
	|				GoodsFromOrder.LineNumber
	|			ELSE
	|				ApplicationProducts_.LineNumber
	|		END                    AS LineNumber,
	|		(References.OrderedQuantityTurnover
	|			- References.ShippedQuantityTurnover) AS Ordered,
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL THEN
	|				GoodsFromOrder.Ref.Purpose
	|			ELSE
	|				ApplicationProducts_.Ref.Purpose
	|		END                    AS Purpose
	|	FROM
	|		TT_ShipmentOrdersTurnoverExpanded AS References
	|
	|		LEFT JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON References.ReferenceOrder      = GoodsFromOrder.Ref
	|			AND References.Products   = GoodsFromOrder.Products
	|			AND References.Characteristic = GoodsFromOrder.Characteristic
	|			AND References.RowCode      = GoodsFromOrder.RowCode
	|
	|		LEFT JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS ApplicationProducts_
	|		ON References.ReferenceOrder      = ApplicationProducts_.Ref
	|			AND References.Products   = ApplicationProducts_.Products
	|			AND References.Characteristic = ApplicationProducts_.Characteristic
	|			AND References.RowCode      = ApplicationProducts_.RowCode
	|			AND (GoodsFromOrder.Ref IS NULL )
	|	WHERE
	|		CASE
	|			WHEN NOT GoodsFromOrder.Ref IS NULL THEN
	|				GoodsFromOrder.SupplyOption IN(
	|					VALUE(Enum.SupplyOptions.ReserveAsReceived),
	|					VALUE(Enum.SupplyOptions.ToSupply))
	|					AND GoodsFromOrder.WithAssignment
	|			ELSE
	|				ApplicationProducts_.SupplyOption IN(
	|					VALUE(Enum.SupplyOptions.ReserveAsReceived),
	|					VALUE(Enum.SupplyOptions.ToSupply))
	|					AND ApplicationProducts_.WithAssignment
	|			END
	|		AND (References.OrderedQuantityTurnover
	|			- References.ShippedQuantityTurnover) > 0) AS T
	|
	|GROUP BY
	|	T.Products,
	|	T.Characteristic,
	|	T.Warehouse,
	|	T.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.OrderDocument AS OrderDocument,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ToUnlockBalance AS ToUnlockBalance,
	|	Inventories.ReserveAtWarehouseFromLockedBalance AS ReserveAtWarehouseFromLockedBalance,
	|	Inventories.ReserveUponReceiptFromLockedBalance AS ReserveUponReceiptFromLockedBalance
	|INTO InventoryAndNeedsBalanceOfControlledLotsReference
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				OrderProducts_0 AS FilterOfProducts_)) AS Inventories
	|INDEX BY
	|	Products, Characteristic, Warehouse, Purpose
	|;
	|
	|////////////////////////////////////////////////////////
	|SELECT
	|	Inventories.Products AS Products,
	|	Inventories.Characteristic AS Characteristic,
	|	Inventories.Warehouse AS Warehouse,
	|	Inventories.Purpose AS Purpose,
	|	Inventories.InStockBalance AS InStockBalance,
	|	Inventories.LockedInStockBalance AS LockedInStockBalance,
	|	Inventories.OrderedBalance AS OrderedBalance,
	|	Inventories.Received_1Balance AS Received_1Balance,
	|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
	|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
	|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
	|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
	|	Inventories.ToSupplyBalance AS ToSupplyBalance,
	|	Inventories.NotProvideBalance AS NotProvideBalance
	|INTO InventoryAndDemandsBalance
	|FROM
	|	AccumulationRegister.InventoryAndDemands.Balance(,
	|		(Products, Characteristic, Warehouse, Purpose) IN(
	|			SELECT
	|				FilterOfProducts_.Products AS Products,
	|				FilterOfProducts_.Characteristic AS Characteristic,
	|				FilterOfProducts_.Warehouse AS Warehouse,
	|				FilterOfProducts_.Purpose AS Purpose
	|			FROM
	|				OrderProducts_0 AS FilterOfProducts_)) AS Inventories
	|;
	|
	|/////////////////////////////////////////////////////////
	|SELECT
	|	TTGoodsOrders.OrderDate     AS OrderDate,
	|	TTGoodsOrders.LineNumber    AS LineNumber,
	|	TTGoodsOrders.Products   AS Products,
	|	TTGoodsOrders.Characteristic AS Characteristic,
	|	TTGoodsOrders.Warehouse          AS Warehouse,
	|	TTGoodsOrders.Purpose     AS Purpose,
	|	CASE
	|		WHEN
	|			TTGoodsOrders.Ordered
	|				> Calculation.NotProvided_ReserveAsNeeded
	|					+ Calculation.NotProvided_Postpone
	|					+ Calculation.Supply_CIsNotProvided
	|			THEN
	|				Calculation.NotProvided_ReserveAsNeeded
	|					+ Calculation.NotProvided_Postpone
	|					+ Calculation.Supply_CIsNotProvided
	|		ELSE TTGoodsOrders.Ordered
	|	END AS Count
	|INTO OrderProducts_2
	|FROM
	|	OrderProducts_0 AS TTGoodsOrders
	|		INNER JOIN SubstitutionInventoryAllocation AS Calculation
	|		ON TTGoodsOrders.Products      = Calculation.Products
	|			AND TTGoodsOrders.Characteristic = Calculation.Characteristic
	|			AND TTGoodsOrders.Warehouse          = Calculation.Warehouse
	|			AND TTGoodsOrders.Purpose     = Calculation.Purpose
	|WHERE
	|	TTGoodsOrders.Products.ItemsType IN(
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND Calculation.NotProvided_ReserveAsNeeded
	|		+ Calculation.NotProvided_Postpone
	|		+ Calculation.Supply_CIsNotProvided > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	T.Warehouse AS Warehouse
	|
	|INTO TTWarehouses
	|
	|FROM
	|	OrderProducts_2 AS T
	|
	|ORDER BY 
	|	OrderDate
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.Products           AS Products,
	|	ISNULL(ProductsVATRates.VATRate, ISNULL(BasicVATRates.VATRate,
	|		VALUE(Catalog.VATRates.EmptyRef))) AS VATRate,
	|	T.Characteristic         AS Characteristic,
	|	T.Warehouse                  AS Warehouse,
	|	T.Purpose             AS Purpose,
	|	T.Count             AS Count,
	|	T.Count             AS NumberOfPackages
	|
	|FROM
	|	OrderProducts_2 AS T
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
	|				Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|			ON T.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
	|			ON (TRUE)
	|WHERE
	|	T.Warehouse IN (SELECT Tab.Warehouse FROM TTWarehouses AS Tab)
	|
	|ORDER BY T.Purpose, T.LineNumber";
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForInventoryAllocation();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.BalanceSheetsOfControlledLotREFERENCES = "InventoryAndNeedsBalanceOfControlledLotsReference"; // @query-part-1
	TablesNames.Result = "SubstitutionInventoryAllocation"; // @query-part-1
	ProvisionInDocumentsServer.InventoryAllocation(Query.Text, TablesNames);
	
	Query.SetParameter("SalesOpportunity", CatalogBasis);
	Query.SetParameter("Date", Date);
	Query.SetParameter("RegistrationCountry", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));
	SalesOpportunity = CatalogBasis;

	SetPrivilegedMode(True);
	GoodsTable = Query.Execute().Unload();
	SetPrivilegedMode(False);

	If GoodsTable.Count() > 0 Then 

		Goods.Load(GoodsTable);
		Warehouse = Goods[0].Warehouse;

	EndIf;

EndProcedure

Procedure FillInDocumentOnBasisOfTransactionInSummary(Val CatalogBasis)

	Query = New Query("
	|SELECT
	|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|WHERE
	|	SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|	AND SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShipmentReferences.Products   AS Products,
	|	ShipmentReferences.Characteristic AS Characteristic,
	|	(ShipmentReferences.OrderedQuantityTurnover
	|		- ShipmentReferences.IssuedQuantityTurnover) AS Count
	|INTO SalesOrders
	|FROM
	|	#ShipmentOrdersTurnoverExpanded AS ShipmentReferences
	|WHERE
	|	(ShipmentReferences.OrderedQuantityTurnover
	|		- ShipmentReferences.IssuedQuantityTurnover) <> 0
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PurchaseOrders.Products AS Products,
	|	PurchaseOrders.Characteristic AS Characteristic,
	|	PurchaseOrders.OrderedReceipt AS Count
	|INTO PurchaseOrders
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(,, Period,
	|		PurchaseOrder.SalesOpportunity = &SalesOpportunity
	|	) AS PurchaseOrders
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrders.Products        AS Products,
	|	SalesOrders.Characteristic      AS Characteristic,
	|	SalesOrders.Count
	|		- ISNULL(PurchaseOrders.Count, 0) AS Count,
	|
	|	SalesOrders.Count
	|		- ISNULL(PurchaseOrders.Count, 0) AS NumberOfPackages
	|FROM
	|	SalesOrders AS SalesOrders
	|
	|	LEFT JOIN
	|		PurchaseOrders AS PurchaseOrders
	|	ON
	|		SalesOrders.Products = PurchaseOrders.Products
	|		AND SalesOrders.Characteristic = PurchaseOrders.Characteristic
	|WHERE
	|	(SalesOrders.Count - ISNULL(PurchaseOrders.Count, 0)) > 0
	|");
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"ReferenceOrder.SalesOpportunity = &SalesOpportunity
		|		AND ReferenceOrder.Status IN
		|			(VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip))";
	TableFormationParameters.Group = "Products, Characteristic";
	TableFormationParameters.Indicators = "Ordered, Issued_1";
	TableFormationParameters.Resources = "Count";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	Query.SetParameter("SalesOpportunity", CatalogBasis);

	SetPrivilegedMode(True);
	ResultsArray = Query.ExecuteBatch();
	SetPrivilegedMode(False);

	TransactionResult			= ResultsArray[0]; // QueryResult
	// The array of results[1] is a temporary table of customer orders
	// Array of results[2] - Temporary table of the order to the suppliers.
	ResultsByProducts			= ResultsArray[3]; // QueryResult
	
	TransactionSelection = TransactionResult.Select();
	ProductSelection_1 = ResultsByProducts.Select();
	
	If TransactionSelection.Next() Then
		SalesOpportunity = TransactionSelection.SalesOpportunity;
	EndIf;
	
	While ProductSelection_1.Next() Do
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, ProductSelection_1);
		
	EndDo;
	
EndProcedure

Procedure FillInDocumentBasedOnChangeOfAssortment(Val ProductRangeChange)
	
	//
	FoundationIsCarriedOut = Common.ObjectAttributeValue(ProductRangeChange, "Posted");
	If Not FoundationIsCarriedOut Then
		ExceptionText = NStr("vi = 'Chứng từ cơ sở %1 chưa kết chuyển. Không thể điền chứng từ.';
							|ru = 'Документ-основание %1 не проведен. Заполнение документа не возможно.';
							|en = 'Cannot populate the document. Post its base document first: %1.'; fa = 'Cannot populate the document. Post its base document first: %1.';
							|it = 'Documento-causale %1 non è registrato. Impossibile compilare il documento.';
							|pl = 'Nie zatwierdzono dokumentu podstawy %1. Wypełnienie dokumentu jest niemożliwe.';
							|tr = '%1 Temel belge geçerli bir belge değil. Belge tamamlanamıyor.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, ProductRangeChange);
		Raise ExceptionText;
	EndIf;
	//
	DocumentBasis = ProductRangeChange;
	
	Query = New Query;
	Query.Text = "SELECT
	|	ChangingProductRange.Products
	|FROM
	|	Document.ProductRangeChange.Goods AS ChangingProductRange
	|WHERE
	|	ChangingProductRange.Ref = &Ref
	|
	|ORDER BY
	|	ChangingProductRange.LineNumber";
	Query.SetParameter("Ref", ProductRangeChange);
	
	SamplingFromBase = Query.Execute().Select();
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, True));
	
	RowsToProcess = New Array();
	
	While SamplingFromBase.Next() Do
		
		NewRow = Goods.Add();
		FillPropertyValues(NewRow, SamplingFromBase);
		
		RowsToProcess.Add(NewRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		CachedValues);
	
EndProcedure

Function FillThePricesByTermsOfSales()

	FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Terms", Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("PopulationFields", "Price, VATRate, VendorPriceKind");

	RecalculateAmountTakingIntoAccountManualDiscount = New Structure("Clear", False);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);

	PricesAreFilledOut = PartnerPricesFillingServer.FillInPrices(
		Goods,
		Undefined,
		FillParameters,
		StructureOfActions);
	Return PricesAreFilledOut;

EndFunction

Procedure CheckToFillInReceiptByOneDate()

	OneDateReceipt = True;
	If Goods.Count() > 0 Then

		DateOfReceipt = Goods[0].DateOfReceipt;
		DateOfShipment = ?(ValueIsFilled(Goods[0].DateOfShipment), Goods[0].DateOfShipment, DateOfReceipt);
		
		For Each String In Goods Do

			If String.DateOfReceipt <> DateOfReceipt Then
				OneDateReceipt = False;
			EndIf;
			If Not ValueIsFilled(String.DateOfShipment) Then
				String.DateOfShipment = String.DateOfReceipt;
			EndIf;
			
		EndDo;

		If OneDateReceipt Then
			RequestedDeliveryDate = DateOfReceipt;
		EndIf;

	EndIf;

EndProcedure

// Parameters:
//    Table - ValueTable - the description of the link See AccessManagement.FillAccessValuesSets.
//
Procedure FillAccessValuesSets(Table) Export

	TabRow = Table.Add();
	If ValueIsFilled(Partner) Then
		TabRow.AccessValue = Partner;
	Else
		// Always allowed.
		TabRow.AccessValue = Enums.AdditionalAccessValues.AccessAllowed;
	EndIf;

EndProcedure // Fill in the set of access values()

// Corrects lines that had not been issued a receipt or warehouse warrant or there are differences in the measured products.
//
// Parameters:
// 		ParametersStructure - Structure - Structure of adjustment parameters, constructor: order Server.Structurecorrectionslist of orders().
//
// Returns:
// 		Structure
// 		* Number of rows - the Number of canceled / adjusted rows
// 		* Adoration amount - The amount of increase in the order due to excess shipment of measured goods.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	NumberOfCanceledLines = 0;
	MeasuringGoodsVarianceAmount = 0;
	
	ReturnStructure = New Structure("RowsCount, VarianceAmount",0,0);

	CancellationReason                = ParametersStructure.CancellationReason;
	CancelUnprocessedLines = ParametersStructure.CancelUnprocessedLines;
	CorrectMeasuringGoods  = ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
	CheckBalance             = ParametersStructure.CheckBalance;
	GoodsTable                = ThisObject[ParametersStructure.TabularSectionName];
	
	If Not CancelUnprocessedLines And Not CorrectMeasuringGoods Then
		Return ReturnStructure;
	EndIf;
	
	PropertiesOfCanceledRow = New Structure(
		"Canceled, CancellationReason",
		True, CancellationReason);
	
	If Not CheckBalance Then
		For N1 = 0 To GoodsTable.Count() - 1 Do
			If Not GoodsTable[N1].Canceled Then
				FillPropertyValues(Goods[N1], PropertiesOfCanceledRow);
				NumberOfCanceledLines = NumberOfCanceledLines + 1;
			EndIf;
		EndDo;
		ReturnStructure.RowsCount = NumberOfCanceledLines;
		Return ReturnStructure;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CAST(GoodsTable.Products AS Catalog.Products) AS Products,
	|	CAST(GoodsTable.Characteristic AS Catalog.ItemsCharacteristics) AS Characteristic,
	|	CAST(GoodsTable.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(GoodsTable.Count AS NUMBER) AS Count,
	|	CAST(GoodsTable.Canceled AS BOOLEAN) AS Canceled,
	|	CAST(GoodsTable.RowCode AS NUMBER) AS RowCode,
	|	&PurchaseOrder AS PurchaseOrder
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.Canceled = FALSE
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceive.Products   AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	GoodsToReceive.Warehouse          AS Warehouse,
	|	SUM(GoodsToReceive.ToRegisterReceipt
	|		* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)) AS AllowableVariance
	|FROM
	|	AccumulationRegister.PurchaseOrders.Turnovers(&StartPeriod_,&ConPeriod,, PurchaseOrder = &PurchaseOrder) AS GoodsToReceive
	|WHERE
	|	GoodsToReceive.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.Products        AS Products,
	|	Balance.Characteristic      AS Characteristic,
	|	Balance.Warehouse               AS Warehouse,
	|	Balance.RowCode           AS RowCode,
	|	CASE
	|		WHEN CAST(Balance.PurchaseOrder AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
	|			THEN Balance.ToRegisterBalance
	|		ELSE Balance.OrderedBalance
	|	END AS ToRegisterBalance	
	|INTO TTBalance
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &PurchaseOrder) AS Balance
	|WHERE
	|	Balance.ToRegisterBalance <> 0
	|	OR Balance.OrderedBalance <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.RowCode AS RowCode,
	|	Balance.ToRegisterBalance AS ToRegisterBalance
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN TTBalance AS Balance
	|		ON GoodsTable.Products = Balance.Products
	|			AND GoodsTable.Characteristic = Balance.Characteristic
	|			AND GoodsTable.Warehouse = Balance.Warehouse
	|			AND GoodsTable.RowCode = Balance.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.RowCode AS RowCode,
	|	0
	|FROM
	|	GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.PurchaseOrder.Status NOT IN (VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
	|							VALUE(Enum.PurchaseOrderStatuses.Closed))");
		
	Table = GoodsTable.Unload(,"Products, Characteristic, Warehouse, Count, Canceled, RowCode");  // ValueTable
	Table.GroupBy("Products, Characteristic, Warehouse, Canceled, RowCode", "Count");
	Query.SetParameter("GoodsTable", Table);
		
	Query.SetParameter("PurchaseOrder", Ref);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get());
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns("PurchaseOrders",
																"PurchaseOrder = &PurchaseOrder",
																Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	Result = Query.ExecuteBatch();
	
	AcceptableDeviations = Result[1].Unload();  // ValueTable
	Selection              = Result[3].Select();
	
	If Selection.Count() = 0 Then
		Return ReturnStructure;
	EndIf;
	
	AcceptableDeviations.Indexes.Add("Products, Characteristic, Warehouse");
	ReasonForCancellationOfMeasuredGoods = Catalogs.ReasonsForPurchaseOrderCancellation.VarianceOnDimensionalGoodsReceiving;

	RowsToProcess = New Array;
	If GoodsTable = Goods Then
		ProcessedLinesAreNew = RowsToProcess;
	Else
		ProcessedLinesAreNew = New Array;
	EndIf;

	While Selection.Next() Do
		
		If Selection.ToRegisterBalance > 0 Then
				
				ThisIsTolerance = False;
				TheStructureOfTheSearch = New Structure;
				TheStructureOfTheSearch.Insert("Products", Selection.Products);
				TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
				TheStructureOfTheSearch.Insert("Warehouse", Selection.Warehouse);
				ToleranceLines = AcceptableDeviations.FindRows(TheStructureOfTheSearch);
				If ToleranceLines.Count() > 0 Then
					AcceptableDeviationLine = ToleranceLines[0];
					
					If Selection.ToRegisterBalance <= AcceptableDeviationLine.AllowableVariance Then
						ThisIsTolerance = True;
						AcceptableDeviationLine.AllowableVariance =
							AcceptableDeviationLine.AllowableVariance - Selection.ToRegisterBalance;
					EndIf;
					
				EndIf;
				
				If Not ThisIsTolerance And Not CancelUnprocessedLines Then
					Continue;
				EndIf;
				
				TheStructureOfTheSearch.Insert("Canceled", False);
				TheStructureOfTheSearch.Insert("RowCode", Selection.RowCode);
				ProductLines_2 = Goods.FindRows(TheStructureOfTheSearch);
				
				If ProductLines_2.Count() > 0 Then
					
					CountCancel = Selection.ToRegisterBalance;
					
					For Each String In ProductLines_2 Do
						
						If CountCancel = 0 Then
							Break;
						EndIf;
						
						If String.Count <= CountCancel Then
							FillPropertyValues(String, PropertiesOfCanceledRow);
							CountCancel = CountCancel-String.Count;
						Else
						
							NewRow = GoodsTable.Add();
							FillPropertyValues(NewRow, String);
							FillPropertyValues(NewRow, PropertiesOfCanceledRow);
							NewRow.RowCode = 0;
							
							String.Count              = String.Count - CountCancel;
							NewRow.Count         = CountCancel;
							
							If ThisIsTolerance Then
								NewRow.CancellationReason = ReasonForCancellationOfMeasuredGoods;
							EndIf;
							
							RowsToProcess.Add(String);
							ProcessedLinesAreNew.Add(NewRow);
							
							CountCancel = 0;
						
						EndIf;
					EndDo;
				EndIf;
				
		ElsIf Selection.ToRegisterBalance < 0 And CorrectMeasuringGoods Then
			
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Products", Selection.Products);
			TheStructureOfTheSearch.Insert("Characteristic", Selection.Characteristic);
			TheStructureOfTheSearch.Insert("Warehouse", Selection.Warehouse);
			
			ToleranceLines = AcceptableDeviations.FindRows(TheStructureOfTheSearch);
			QuantityToDistribute = Selection.ToRegisterBalance*(-1);
			
			If ToleranceLines.Count() > 0 Then
				AcceptableDeviationLine = ToleranceLines[0];
				
				ProductLines_2 = GoodsTable.FindRows(TheStructureOfTheSearch);
				RowOfGoods = ProductLines_2[0];
				RowOfGoods.NumberOfPackages = RowOfGoods.NumberOfPackages
					+ QuantityToDistribute / (RowOfGoods.Count / RowOfGoods.NumberOfPackages);
				RowOfGoods.Count = RowOfGoods.Count + QuantityToDistribute;
				
				PriceManagementSystem.RecalculateAmountsInRow(RowOfGoods, False, False, True, PriceIncludesVAT);
				
				AcceptableDeviationLine.AllowableVariance =
					AcceptableDeviationLine.AllowableVariance - QuantityToDistribute;
				
			EndIf;
			
		EndIf;
		
		NumberOfCanceledLines = NumberOfCanceledLines + 1;
		
	EndDo;

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		CachedValues);
		
	For Each RowOfGoods In RowsToProcess Do
		PriceManagementSystem.RecalculateAmountsInRow(RowOfGoods, False, False, True, PriceIncludesVAT);
	EndDo;
	
	If GoodsTable <> Goods Then
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ProcessedLinesAreNew,
			StructureOfActions,
			GoodsTable,
			CachedValues);
			
			For Each RowOfGoods In ProcessedLinesAreNew Do
				PriceManagementSystem.RecalculateAmountsInRow(RowOfGoods, False, False, True, PriceIncludesVAT);
			EndDo;
	EndIf;

	ControlledStringLotReferences = Goods.FindRows(New Structure("Canceled", True));
	QualityControl.ClearCheckQualityInReceiptDocument(Goods, ControlledStringLotReferences);
	
	ReturnStructure.RowsCount = NumberOfCanceledLines;
	
	Return ReturnStructure;
	
EndFunction

// Sets the prices in the order to the prices in the invoices
//
// Parameters:
// 		OrderObject - DocumentObject.PurchaseOrder - Corrected order to the supplier.
// 		PriceVariances - ValueTable  - Price deviations by order:
// 		* Products                   - CatalogRef.Products
// 		* Characteristic                 - CatalogRef.ItemsCharacteristics
// 		* RowCode                      - Number - Code of the order line to the supplier.
// 		* ReceiptPrice                - Number - The price at which the product was received.
// 		* OrderReceiptAmount               - Number - The amount of the goods receipt.
// 		* PriceChanged                 - Boolean - Whether the price has changed.
// 		* TheAmountHasChanged                - Boolean - Whether the amount has changed.
// 		* PercentageOfManualReceiptDiscount - Number - Discount percentage in the receipt.
// 		* ManualDiscountAmountGoodsReceipt   - Number - The amount of the manual discount in the receipt.
// 		* PackagingConversionFactor   - Number - Conversion factor of the receipt package to the order packages.
//
Procedure AdjustOrderPrices(OrderObject,PriceVariances) Export
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(OrderObject);
	RecalculateAmountTakingIntoAccountManualDiscount	= New Structure("Clear", False);
	
	StructureOfPriceChangeActions = New Structure;
	StructureOfPriceChangeActions.Insert("RecalculateAmount");
	StructureOfPriceChangeActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfPriceChangeActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfPriceChangeActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfPriceChangeActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);
	
	StructureOfActionsForChangingAmounts = New Structure;
	StructureOfActionsForChangingAmounts.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActionsForChangingAmounts.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsForChangingAmounts.Insert("RecalculateAmountOfManualDiscount");
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	ProcessedLinesAmount = New Array();
	ProcessedPricesLines = New Array();
	
	For Each DeviationLine In PriceVariances Do
		
		FoundRow = OrderObject.Goods.Find(DeviationLine.RowCode, "RowCode");
		
		If Not DeviationLine.PriceChanged And DeviationLine.TheAmountHasChanged Then
			
			If FoundRow <> Undefined Then
				
				FoundRow.Sum = DeviationLine.OrderReceiptAmount;
				
				If DeviationLine.ManualDiscountAmountGoodsReceipt <> 0 Then
					StructureOfActionsForChangingAmounts.Delete("RecalculateAmountOfManualDiscount");
					FoundRow.ManualDiscount = DeviationLine.ManualDiscountAmountGoodsReceipt;
					FoundRow.PercentRateOfManualDiscount = -(DeviationLine.OrderReceiptAmount * 100
						/ (FoundRow.NumberOfPackages*FoundRow.Price)-100);
				Else
					StructureOfActionsForChangingAmounts.Delete("RecalculateAmountOfManualDiscount");
					FoundRow.PercentRateOfManualDiscount = 0;
				EndIf;
				ProcessedLinesAmount.Add(FoundRow);
				
			EndIf;
		Else
			If FoundRow <> Undefined Then
				
				FoundRow.Price = DeviationLine.ReceiptPrice;
				
				If DeviationLine.ManualDiscountAmountGoodsReceipt <> 0 Then
					StructureOfPriceChangeActions.Delete("RecalculateAmountOfManualDiscount");
					StructureOfPriceChangeActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", 
						New Structure("Clear,RecalculateAmountOfManualDiscount_", False, False));
					FoundRow.ManualDiscount = DeviationLine.ManualDiscountAmountGoodsReceipt;
					FoundRow.PercentRateOfManualDiscount = 0;
				Else
					StructureOfPriceChangeActions.Delete("RecalculateAmountOfManualDiscount");
					StructureOfPriceChangeActions.Delete("RecalculateAmountTakingIntoAccountManualDiscount");
					FoundRow.PercentRateOfManualDiscount = 0;
				EndIf;
				ProcessedPricesLines.Add(FoundRow);
				
			EndIf;
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedLinesAmount,
		StructureOfActionsForChangingAmounts,
		OrderObject.Goods,
		CachedValues);
					
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedPricesLines,
		StructureOfPriceChangeActions,
		OrderObject.Goods,
		CachedValues);
	
EndProcedure

// Cancels all lines for which the receipt was not documented
//
// Parameters:
//	CancellationReason - CatalogRef.ReasonsForPurchaseOrderCancellation
//	CheckBalance - Boolean
//
// Returns:
//	Number - The number of canceled rows.
//
Function CancelUndeliveredLines(CancellationReason, Val CheckBalance = False) Export
	
	NumberOfCanceledLines = 0;
	
	PropertiesOfCanceledRow = New Structure(
		"Canceled, CancellationReason",
		True, CancellationReason);
	
	If Not CheckBalance Then
		For Cnt = 0 To Goods.Count() - 1 Do
			If Not Goods[Cnt].Canceled Then
				FillPropertyValues(Goods[Cnt], PropertiesOfCanceledRow);
				NumberOfCanceledLines = NumberOfCanceledLines + 1;
			EndIf;
		EndDo;
		Return NumberOfCanceledLines;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CAST(GoodsTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(GoodsTable.RowCode AS NUMBER) AS RowCode,
	|	CAST(GoodsTable.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(GoodsTable.Count AS NUMBER) AS Count,
	|	CAST(GoodsTable.Canceled AS BOOLEAN) AS Canceled,
	|	&PurchaseOrder AS PurchaseOrder
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.Canceled = FALSE
	|
	|INDEX BY
	|	RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowCode AS RowCode,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	CASE WHEN GoodsTable.Count > Balance.ToRegisterReceipt THEN
	|			GoodsTable.Count - Balance.ToRegisterExpense
	|		ELSE 0
	|	END AS QuantityInExcessOfIssued,
	|	GoodsTable.Count AS Count,
	|	Balance.ToRegisterClosingBalance AS ToRegisterBalance,
	|	CASE
	|		WHEN GoodsTable.Count = Balance.ToRegisterClosingBalance
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS SplitRow
	|FROM
	|	GoodsTable AS GoodsTable
	|		INNER JOIN AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(,,,, PurchaseOrder = &PurchaseOrder) AS Balance
	|		ON GoodsTable.RowCode = Balance.RowCode
	|			AND (Balance.ToRegisterClosingBalance > 0)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowCode AS RowCode,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	0,
	|	GoodsTable.Count AS Count,
	|	0,
	|	FALSE
	|FROM
	|	GoodsTable AS GoodsTable
	|WHERE
	|	CAST(GoodsTable.PurchaseOrder AS Document.PurchaseOrder).Status NOT IN (VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
	|							VALUE(Enum.PurchaseOrderStatuses.Closed))
	|ORDER BY
	|	LineNumber;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	GoodsToReceiveBalance.Warehouse AS Warehouse,
	|	GoodsToReceiveBalance.GoodsReceiptNotesToRegisterExpense + GoodsToReceiveBalance.AcceptsReceipt AS Count
	|FROM
	|	AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
	|		,,,,
	|		DocumentInflow = &PurchaseOrder) AS GoodsToReceiveBalance");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsTable.Package", Undefined));
		
	Query.SetParameter(
		"GoodsTable",
		Goods.Unload(
			, // Array of rows to upload
			"LineNumber, RowCode, Package, Count, Canceled"));
	Query.SetParameter("PurchaseOrder", Ref);
	
	Result = Query.ExecuteBatch();
	
	Selection = Result[1].Select();
	OrderOrder = Documents.PurchaseOrder.OrderIsOrderForAcceptanceOfGoods(Ref);
	ReceivedGoods_ = Result[2].Unload();
	If OrderOrder Then
		While Selection.Next() Do
			
			String = Goods[Selection.LineNumber-1];
				
			SearchParameters = New Structure;
			SearchParameters.Insert("Products", String.Products);
			SearchParameters.Insert("Characteristic", String.Characteristic);
			SearchParameters.Insert("Warehouse", String.Warehouse);
			SearchParameters.Insert("Purpose", String.Purpose);
				
			AcceptedQuantity = 0;
			AcceptedString     = Undefined;
			
			FoundRows = ReceivedGoods_.FindRows(SearchParameters);
			If FoundRows.Count() > 0 Then
				AcceptedString = FoundRows[0];
				AcceptedQuantity = AcceptedString.Count;
			EndIf;
			
			CancelQuantity = 0;
			
			If Selection.ToRegisterBalance = 0 And AcceptedQuantity = 0 Then
				CancelQuantity = Selection.Count;
			ElsIf Selection.Count >= AcceptedQuantity Then
				CancelQuantity = Min(Selection.ToRegisterBalance, Selection.Count - AcceptedQuantity);
				If AcceptedString <> Undefined Then
					If AcceptedQuantity > (Selection.Count - Selection.QuantityInExcessOfIssued - Selection.ToRegisterBalance) Then
						AcceptedString.Count = AcceptedQuantity - (Selection.Count - Selection.QuantityInExcessOfIssued - Selection.ToRegisterBalance);
					Else
						AcceptedString.Count = 0;
					EndIf;
				EndIf;
			Else
				AcceptedString.Count = AcceptedString.Count - Selection.Count;
			EndIf;
			
			If CancelQuantity = Selection.Count Then
				
				FillPropertyValues(String, PropertiesOfCanceledRow);
				
			ElsIf CancelQuantity > 0 Then
				
				CancelQuantity = CancelQuantity + Selection.QuantityInExcessOfIssued;
				
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, String);
				FillPropertyValues(NewRow, PropertiesOfCanceledRow);
				NewRow.RowCode = 0;
				
				String.Count         = Selection.Count - CancelQuantity;
				String.NumberOfPackages = (Selection.Count - CancelQuantity) / Selection.PackagingFactor;
				NewRow.Count         = CancelQuantity;
				NewRow.NumberOfPackages = CancelQuantity / Selection.PackagingFactor;
				NewRow.AmountIncludingVAT          = String.AmountIncludingVAT * CancelQuantity/Selection.Count;
				
				PriceManagementSystem.RecalculateAmountsInRow(String, False, False, True, PriceIncludesVAT);
				PriceManagementSystem.RecalculateAmountsInRow(NewRow, False, False, True, PriceIncludesVAT);
				
			Else
				
				Continue;
				
			EndIf;
			
			NumberOfCanceledLines = NumberOfCanceledLines + 1;
			
		EndDo;
	Else
		If Result[1].IsEmpty() Then
			Return NumberOfCanceledLines;
		EndIf;
		
		While Selection.Next() Do
			
			String = Goods[Selection.LineNumber-1];
			
			If Selection.SplitRow Then
				
				NewRow = Goods.Add();
				FillPropertyValues(NewRow, String);
				FillPropertyValues(NewRow, PropertiesOfCanceledRow);
				NewRow.RowCode = 0;
				
				String.Count              = Selection.Count - Selection.ToRegisterBalance;
				String.NumberOfPackages      = (Selection.Count - Selection.ToRegisterBalance) / Selection.PackagingFactor;
				NewRow.Count         = Selection.ToRegisterBalance;
				NewRow.NumberOfPackages = Selection.ToRegisterBalance / Selection.PackagingFactor;
				
				PriceManagementSystem.RecalculateAmountsInRow(String, False, False, True, PriceIncludesVAT);
				PriceManagementSystem.RecalculateAmountsInRow(NewRow, False, False, True, PriceIncludesVAT);
				
			Else
				
				FillPropertyValues(String, PropertiesOfCanceledRow);
				
			EndIf;
			
			NumberOfCanceledLines = NumberOfCanceledLines + 1;
			
		EndDo;
	EndIf;
	
	ControlledStringLotReferences = Goods.FindRows(New Structure("Canceled", True));
	QualityControl.ClearCheckQualityInReceiptDocument(Goods, ControlledStringLotReferences);
	
	Return NumberOfCanceledLines;
	
EndFunction

Procedure CheckCorrectnessOfDirectionOfActivity()
	
	If ValueIsFilled(LineOfBusiness) Then
		
		Query = New Query;
		Query.Text = 
			"SELECT
			|	Assignments.LineOfBusiness AS LineOfBusiness
			|FROM
			|	Catalog.Assignments AS Assignments
			|WHERE
			|	Assignments.Ref IN(&Assignments)
			|	AND Assignments.LineOfBusiness <> &LineOfBusiness";
		
		Query.SetParameter("Assignments", Goods.UnloadColumn("Purpose"));
		Query.SetParameter("LineOfBusiness", LineOfBusiness);
		
		If Not Query.Execute().IsEmpty() Then
			LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInBlankReceiptDate()
	
	If Goods.Count() = 0 Then
		Return;
	EndIf;
	
	If CheckEmptyReceiptDate() Then
		If ValueIsFilled(RequestedDeliveryDate) And RequestedDeliveryDate >= Date Then
			DateOfReceipt = RequestedDeliveryDate;
		Else
			DateOfReceipt = CurrentSessionDate();
		EndIf;
		
		ModifiedRows = Goods;
		If OneDateReceipt Then
			FillInReceiptDatesForProduct();
			StructureOfActions = New Structure();
			CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
		Else
			ModifiedRows = FillInBlankReceiptDatesForProduct();
		EndIf;
		
		StructureOfActions = New Structure();
		CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
		StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
		BatchProcessingOfTablePartServer.ProcessTSStrings(ModifiedRows, StructureOfActions, Goods);
		
	EndIf;
	
EndProcedure

Function CheckEmptyReceiptDate()
	
	For Each TSRow In Goods Do
		
		If Not TSRow.Canceled
			And Not ValueIsFilled(TSRow.DateOfReceipt) Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function FillInBlankReceiptDatesForProduct()
	
	Rows = New Array();
	For Each TSRow In Goods Do
		If Not ValueIsFilled(TSRow.DateOfReceipt) Then
			TSRow.DateOfReceipt = DateOfReceipt;
			Rows.Add(TSRow);
		EndIf;
	EndDo;
	
	Return Rows;
	
EndFunction

Procedure FillInReceiptDatesForProduct()

	For Each TSRow In Goods Do
		TSRow.DateOfReceipt = DateOfReceipt;		
	EndDo;
	
EndProcedure

Procedure RecalculateDatesByCalendar(NumberOfDays, FromShipmentDate = True) Export
	
	FieldNameDate = ?(FromShipmentDate, "DateOfShipment", "DateOfReceipt");
	NameOfCalculatedField = ?(FromShipmentDate, "DateOfReceipt", "DateOfShipment");
	
	Texts = New Array();
	
	Text = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(Text);
	
	Text =
	"SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.DateOfShipment AS DateOfShipment,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	&DateField_ AS DateByCalendar
	|INTO WTableData
	|FROM
	|	&Table AS Table
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS LineNumber,
	|	&DateOfShipment AS DateOfShipment,
	|	&DateOfReceipt AS DateOfReceipt,
	|	&DateByCalendar AS DateByCalendar
	|INTO TTFillData
	|WHERE
	|	&DateByCalendar <> DATETIME(1, 1, 1)
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber,
	|	Table.DateOfShipment,
	|	Table.DateOfReceipt,
	|	Table.DateByCalendar
	|FROM
	|	WTableData AS Table
	|WHERE
	|	Table.DateByCalendar <> DATETIME(1, 1, 1)
	|
	|INDEX BY
	|	LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber AS LineNumber,
	|	Table.DateOfShipment AS DateOfShipment,
	|	Table.DateOfReceipt AS DateOfReceipt,
	|	CalculationOfDeliveryDateOverridable.DateFound AS DateByCalendar
	|FROM
	|	TTFillData AS Table
	|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
	|
	|ORDER BY
	|	LineNumber";
	
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar("Table.DateByCalendar", "&NumberOfDays");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.DateFound", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	Text = StrReplace(Text, "&DateField_", StrTemplate("Table.%1", FieldNameDate));
	
	Texts.Add(Text);
	
	Query = New Query;
	Query.SetParameter("Table", Goods.Unload(, "LineNumber, DateOfShipment, DateOfReceipt"));
	Query.SetParameter("DateByCalendar", ThisObject[FieldNameDate]);
	Query.SetParameter("DateOfShipment", DateOfShipment);
	Query.SetParameter("DateOfReceipt", DateOfReceipt);
	Query.SetParameter("NumberOfDays", NumberOfDays);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.LineNumber) Then
			Page1 = Goods[Selection.LineNumber - 1];
			If ValueIsFilled(Selection.DateByCalendar) Then
				Page1[NameOfCalculatedField] = Selection.DateByCalendar;
			Else
				Page1[NameOfCalculatedField] = TMCommonUseClientServer.CalculatePeriodEndDate(
					Page1[FieldNameDate], Enums.Periodicity.Day, NumberOfDays) + 1;
			EndIf;
		Else
			If ValueIsFilled(Selection.DateByCalendar) Then
				ThisObject[NameOfCalculatedField] = Selection.DateByCalendar;
			Else
				ThisObject[NameOfCalculatedField] = TMCommonUseClientServer.CalculatePeriodEndDate(
					ThisObject[FieldNameDate], Enums.Periodicity.Day, NumberOfDays) + 1;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInPricesOrderedByPrincipal()
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	StructureOfActionsForRecalculationOfManualDiscount = New Structure;
	StructureOfActionsForRecalculationOfManualDiscount.Insert("RecalculatePriceDiscountForAmountInPurchases",
		BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
			Goods,
			BusinessOperation = PredefinedValue("Enum.BusinessTransactions.ConsignmentProcurement")));
	
	CachedValues = Undefined;
	
	GoodsOfFoundationDocument = Common.ObjectAttributeValue(DocumentBasis, "Goods");
	GoodsOfFoundationDocument = ?(TypeOf(GoodsOfFoundationDocument) = Type("QueryResult"), GoodsOfFoundationDocument.Unload(), GoodsOfFoundationDocument);
	
	RowsToProcess = New Array();
	ProcessedRowsRecalculationOfManualDiscount = New Array();
	
	For Each RowOfProduct In Goods Do
		FilterByProduct = New Structure();
		FilterByProduct.Insert("Products", RowOfProduct.Products);
		OrderLines_ = GoodsOfFoundationDocument.FindRows(FilterByProduct);
		ItemPrice = 0;
		ProductAmount = 0;
		ProductAmountWithVAT = 0;
		ProductAmountVAT = 0;
		ProductQuantity_ = 0;
		VATRateChanged = False;
		VATRate = Undefined;
		
		If OrderLines_.Count() > 0 Then
			For Each OrderLine In OrderLines_ Do
				ItemPrice = ItemPrice + OrderLine.Price;
			EndDo;
			ProductAmount = ProductAmount + OrderLine.Sum;
			ProductAmountWithVAT = ProductAmountWithVAT + OrderLine.AmountIncludingVAT;
			ProductAmountVAT = ProductAmountVAT + OrderLine.VATAmount;
			ItemPrice = ItemPrice / OrderLines_.Count();
			ProductQuantity_ = ProductQuantity_ + OrderLine.Count;
			If VATRate = Undefined Then
				VATRate = OrderLine.VATRate;
			ElsIf Not VATRate = OrderLine.VATRate Then
				VATRateChanged = True;
			EndIf;
		EndIf;
		
		RowOfProduct.Price = ItemPrice;
		RowOfProduct.VATRate = VATRate;
		RecalculateAmounts = (ProductQuantity_ <> RowOfProduct.Count) Or VATRateChanged;
		
		If RecalculateAmounts Then
			RowsToProcess.Add(RowOfProduct);
		Else
			RowOfProduct.Sum = ProductAmount;
			RowOfProduct.AmountIncludingVAT = ProductAmountWithVAT;
			RowOfProduct.VATAmount = ProductAmountVAT;
			ProcessedRowsRecalculationOfManualDiscount.Add(RowOfProduct);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Goods,
		CachedValues);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ProcessedRowsRecalculationOfManualDiscount,
		StructureOfActionsForRecalculationOfManualDiscount,
		Goods,
		CachedValues);
	
EndProcedure

Procedure FillInGoodsFromBase(AddressGoodsOfFoundation)
	
	BaseGoods = GetFromTempStorage(AddressGoodsOfFoundation); // ValueTable
	ColumnDateOfShipment = BaseGoods.Columns.Find("DateOfShipment");
	If ColumnDateOfShipment <> Undefined Then
		BaseGoods.Columns.Delete(ColumnDateOfShipment);
	EndIf;
	Goods.Load(BaseGoods);
	DeleteFromTempStorage(AddressGoodsOfFoundation);
	
EndProcedure

Procedure UploadProducts(Source)
	
	Goods.Clear();
	For Each String In Source Do
		FillPropertyValues(Goods.Add(), String);
	EndDo;
	
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

#EndRegion

#EndIf
#EndIf
