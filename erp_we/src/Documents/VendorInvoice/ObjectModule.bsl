#If Not MobileStandaloneServer Then
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
	
	Currency               = PurchaseConditions.Currency;
	ARAPCurrency = PurchaseConditions.ARAPCurrency;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization <> Organization Then
		Organization = PurchaseConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If ValueIsFilled(PurchaseConditions.Warehouse) Then
		Warehouse = PurchaseConditions.Warehouse;
		StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
		If StructureOfResponsible <> Undefined Then
			ReceivedBy = StructureOfResponsible.EmployeeResponsible;
			AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	LineOfBusiness = PurchaseConditions.LineOfBusiness;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty <> Counterparty Then
		Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
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
		AddlParameters.ARAPCurrency	= ARAPCurrency;
		AddlParameters.Taxation		= VATTaxation;
		
		Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
		
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
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	FillInPaymentTerms_(PurchaseConditions);
	
	If ValueIsFilled(PurchaseConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = PurchaseConditions.FinancialAccountingGroup;
	EndIf;
	
	PriceIncludesVAT				= PurchaseConditions.PriceIncludesVAT;
	ToReturnReusablePackage	= PurchaseConditions.ReturnReusablePackage;
	PackageDepositIsRequired		= PurchaseConditions.PackageDepositIsRequired;
	
	ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(ThisObject,
																										PurchaseConditions.ReusablePackageReturnCycleLength,
																										PurchaseConditions.CalculatePackageReturnDateAccordingToCalendar,
																										PurchaseConditions.ScheduleOfPackageReturn);
	
	RegisterVendorPrices = PurchaseConditions.RegisterVendorPrices;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, , Contract);
	
EndProcedure

// Fills in the terms of purchases under a trade agreement with the supplier
//
// Parameters:
//	RecalculatePrices_ - Boolean - True if you need to recalculate prices in the table part of the document.
//
Procedure FillInDefaultPurchaseConditions(RecalculatePrices_ = True) Export
	
	If ValueIsFilled(Partner) Then
		
		PurchaseTermsKeys			= "ConsiderWarehouseGroups, ExcludeWarehouseGroupsAvailableInOrders, SelectedAgreement";
		SelectionOfProcurementConditions			= New Structure(PurchaseTermsKeys, True, True, Terms);
		If ValueIsFilled(BusinessOperation) Then
			BusinessTransactions = PurchasesServer.MainEconomicOperationOfSeparatePurchase(BusinessOperation);
			SelectionOfProcurementConditions.Insert("BusinessTransactions", BusinessTransactions);
			If PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Then
				SelectionOfProcurementConditions.Insert("ContractsAreUsed", True);
			EndIf;
		EndIf;
		DefaultPurchasingConditions	= PurchasesServer.GetDefaultPurchaseTerms(Partner, SelectionOfProcurementConditions);
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultPurchasingConditions <> Undefined Then
			
			If Terms <> DefaultPurchasingConditions.Terms
				And ValueIsFilled(DefaultPurchasingConditions.Terms) Then
				
				Terms = DefaultPurchasingConditions.Terms;
				FillInTermsOfPurchase(DefaultPurchasingConditions);
				
				FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(ThisObject);
				VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
				
				FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(ThisObject);
				VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
				
				If RecalculatePrices_
					And ValueIsFilled(Terms) Then
					
					StructureOfRecalculationOfAmount				= BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					RecalculateAmountTakingIntoAccountManualDiscount	= New Structure("Clear", False);
					
					FillParameters = PartnerPricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("PopulationFields",		"Price, VATRate, VendorPriceKind");
					FillParameters.Insert("Date",				Date);
					FillParameters.Insert("Currency",				Currency);
					FillParameters.Insert("Terms",			Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount",						"NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT",					StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount",					StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount",			"NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",	RecalculateAmountTakingIntoAccountManualDiscount);
					
					PartnerPricesFillingServer.FillInPrices(Goods,
												Undefined, // Array of strings
												FillParameters,
												StructureOfActions);
					
				EndIf;
				
			Else
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
				If TheCounterpartyPriorToTheChange <> Counterparty Then
					CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
				EndIf;
				Terms = DefaultPurchasingConditions.Terms;
			EndIf;
			
		Else
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			Terms = Undefined;
			
			ContractBusinessTransaction = ?(BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
													Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder,
												Enums.BusinessTransactions.PurchaseFromSupplier,
												BusinessOperation);
			ContractBusinessTransaction = PurchasesServer.BusinessOperationsOnMain(ContractBusinessTransaction);
			
			AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
			AddlParameters.ARAPCurrency = ARAPCurrency;
			
			Contract = PurchasesServer.GetDefaultContract(ThisObject, ContractBusinessTransaction, AddlParameters);
			
			PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract,
																	CompanyBankAccount,
																	CounterpartyBankAccount);
			
			FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(ThisObject);
			VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
			
			FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(ThisObject);
			VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
			
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount);
		
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
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
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
		StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		
		If Not PartnerPricesFillingServer.FillInPrices(
				Goods,
				Undefined, // Array of strings
				FillParameters,
				StructureOfActions) Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
			BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.VendorInvoice - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	
	UseSeparateProcurement = PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation);
	FillParameters.UseSeparateProcurement = UseSeparateProcurement;
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.VendorInvoice.CollectionOfTabularPartsOfGoods.
//
Procedure FillOutTypesOfStockWhenExchanging(Cancel, DocumentTables) Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	FillStockTypes(Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If (Not ValueIsFilled(Terms)
			Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed"))
		And Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation)
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
		
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.VendorInvoice));
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.VendorInvoice.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
	
	OrderList = New Array();
	
	UseAgencyPurchasing = GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", LineProducts_.LineNumber);
		
		If ReceiptUnderOrders And
			Not ValueIsFilled(PurchaseOrder) And
			Not ValueIsFilled(LineProducts_.PurchaseOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Đơn hàng đặt nhà cung cấp""';
							|ru = 'Не заполнено поле ""Заказ поставщику""';
							|en = '""Purchase order"" is required'; fa = '""Purchase order"" is required';
							|it = 'Il campo ""Ordine al fornitore"" non è compilato';
							|pl = 'Nie wypełnione pole ""Zamówienie dla dostawcy""';
							|tr = '""Satın alma siparişi"" alanı doldurulmamış'");
			
			CommonClientServer.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "PurchaseOrder"),
				,
				Cancel);
			
		EndIf;
		
		If ValueIsFilled(LineProducts_.PurchaseOrder) 
			And OrderList.Find(LineProducts_.PurchaseOrder) = Undefined Then
				OrderList.Add(LineProducts_.PurchaseOrder);
		EndIf;
		
		If UseAgencyPurchasing
			And ValueIsFilled(LineProducts_.Purpose) Then
			AssignmentType = Common.ObjectAttributeValue(LineProducts_.Purpose, "AssignmentType");
				If AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal Then
					CheckRecordParametersForPurchasingUnderPrincipal(LineProducts_.LineNumber, ErrorAddress,
						LineProducts_.Purpose, Cancel);
				EndIf;
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseReceiptForMultipleOrders")
		And OrderList.Count() > 1
		And PurchasesServerCall.CheckCompatibilityOfOrdersInOneDocument(OrderList,"VendorInvoice") Then
		Cancel = True;
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
	
	NotCheckedAttributeArray.Add("Goods.Department");
	NotCheckedAttributeArray.Add("Goods.QuantityByGBRN");
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract,
		"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
		
	CheckExpenseAnalytics = Not (OperationsOfUnfacturedDelivery.Find(BusinessOperation) <> Undefined
		And (ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
		Or Not ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed));
	
	If CheckExpenseAnalytics Then
		
		ItemsTypes = New Array;
		ItemsTypes.Add(Enums.ItemsTypes.OperationService);
		ErrorText = NStr("vi = 'Chưa chỉ ra người nhận dịch vụ trong dòng %1 của danh sách Hàng hóa';
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
		ErrorText = NStr("vi = 'Chưa chỉ ra người nhận công việc trong dòng %1 của danh sách Hàng hóa';
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
						|tr = 'Ürünler listesinin %1satırında malların alıcısı belirtilmemiş'");
		InventoriesServer.CheckFillingOfDivisionInTablePart(ThisObject, ItemsTypes, ErrorText, Cancel);
		
	Else
		
		NotCheckedAttributeArray.Add("Goods.DimensionOfExpenses");
		
	EndIf;
	
	If Not ToReturnReusablePackage Then
		NotCheckedAttributeArray.Add("ReusablePackagesReturnDate");
	EndIf;
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServerCall.BusinessOperationsOnMain(
		PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
	
	BusinessTransactionsImportPurchase = PurchasesServerCall.BusinessOperationsOnMain(
		PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		NotCheckedAttributeArray.Add("Partner");
		NotCheckedAttributeArray.Add("Counterparty");
		
		If VATTaxation <> Enums.VATTaxationTypes.SaleIsNotSubjectToVAT Then
			
			RepresentationsOfVATTaxation = VATAccountingERPClientServer.ApplicableTypesOfVATTaxation(False, True);
			
			If Not ValueIsFilled(Partner) Then
				
				ErrorText = StrTemplate(
					NStr("vi = 'Trường ""Nhà cung cấp"" trống. Khi mua thông qua một người tạm ứng, chỉ định của nhà cung cấp là bắt buộc đối với chế độ thuế ""%1"".';
						|ru = 'Поле ""Поставщик"" не заполнено. При закупке через подотчетное лицо указание поставщика обязательно для режима налогообложения ""%1"".';
						|en = '""Vendor"" is required. When purchasing through an advance holder, specify the vendor for the ""%1"" tax regime.'; fa = '""Vendor"" is required. When purchasing through an advance holder, specify the vendor for the ""%1"" tax regime.';
						|it = 'Campo ""Fornitore"" non è compilato. Durante l''acquisto tramite persona subordinata è obbligatorio indicare il fornitore per il regime di tassazione ""%1"".';
						|pl = 'Nie wypełniono pola ""Dostawca"". Podczas zakupu przez osobę rozliczającą się za wydatki podanie dostawcy jest obowiązkowe dla formy opodatkowania ""%1"".';
						|tr = '""Tedarikçi"" alanı doldurulmadı. Sorumlu bir kişi aracılığıyla satın alma yapıldığında, tedarikçi ""%1"" vergilendirmesi için gereklidir.'"),
					RepresentationsOfVATTaxation.FindByValue(VATTaxation));
					
				CommonClientServer.MessageToUser(
					ErrorText,,
					"Object.Partner",,
					Cancel);
			EndIf;
			
			If Not ValueIsFilled(Counterparty) And GetFunctionalOption("UsePartnersAndCounterparties") Then
				
				ErrorText = StrTemplate(
					NStr("vi = 'Trường ""Đối tác"" chưa điền. Khi mua thông qua một người tạm ứng, chỉ dẫn đối tác là bắt buộc đối với chế độ thuế, ''''%1''''.';
						|ru = 'Поле ""Контрагент"" не заполнено. При закупке через подотчетное лицо указание контрагента обязательно для режима налогообложения ""%1"".';
						|en = '""Counterparty"" is required. When purchasing through an advance holder, specify the counterparty for the ""%1"" tax regime.'; fa = '""Counterparty"" is required. When purchasing through an advance holder, specify the counterparty for the ""%1"" tax regime.';
						|it = 'Campo ""Controparte"" non è compilato. Durante l''acquisto tramite persona subordinata è obbligatorio indicare la controparte per il regime di tassazione ""%1"".';
						|pl = 'Nie wypełniono pola ""Kontrahent"". Podczas zakupu przez osobę rozliczającą się za wydatki podanie kontrahenta jest obowiązkowe dla formy opodatkowania ""%1"".';
						|tr = '""Cari hesap"" alanı doldurulmadı. Sorumlu bir kişi aracılığıyla satın alma yapıldığında, cari hesabın belirtilmesi ""%1"" vergilendirmesi için gereklidir.'"),
					RepresentationsOfVATTaxation.FindByValue(VATTaxation));
					
				CommonClientServer.MessageToUser(
					ErrorText,,
					"Object.Counterparty",,
					Cancel);
			EndIf;
		EndIf;
		
		CashServer.CheckPurchaseDocumentsOfAdvanceReport(ThisObject, Cancel);
		
	ElsIf BusinessTransactionsImportPurchase.Find(BusinessOperation) <> Undefined
		Or BusinessTransactionsProcurementInEAEUCountries.Find(BusinessOperation) <> Undefined Then
		
		NotCheckedAttributeArray.Add("VATTaxation");
		
	EndIf;
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.VendorInvoice),
												Cancel,
												NotCheckedAttributeArray);
	
	ThisIsTraceableDocument		= AccountingForTraceableGoodsLocalization.ThisIsTraceableDocument(Goods, Date);
	EconomicImportOperations	= PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseByImport);
	
	NotCheckedAttributeArray.Add("Goods.CCDNumber");
	
	If (ThisIsTraceableDocument
			Or GetFunctionalOption("RestrictGoodsReceiptWithoutCCDNumbers"))
		And EconomicImportOperations.Find(BusinessOperation) = Undefined Then
		
		CheckParameters = InventoriesServer.ParametersForCheckingFillingInOfCCDNumbers();
		CheckParameters.BusinessOperation = BusinessOperation;
		CheckParameters.CheckWorks       = True;
		
		InventoriesServer.CheckFillingOfCCDNumbers(ThisObject, Cancel, CheckParameters);
		
	EndIf;
	
	If ThisIsTraceableDocument Then
		AccountingForTraceableGoodsLocalization.CheckCorrectSettingsOfRNPTProducts(ThisObject, Goods, Date);
	EndIf;
	
	If Not PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation) Then
		NotCheckedAttributeArray.Add("Goods.VendorPriceKind");
	EndIf;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel, ReceiptUnderOrders);
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		"DateOfReceipt");
		
	QualityControl.ProcessingVerificationOfCorrectnessOfConnectionWithBatches(
		ThisObject,
		SeriesSpecificationParameters.LinkFields,
		"Goods",
		NStr("vi = 'Hàng hóa';
			|ru = 'Товары';
			|en = 'Items'; fa = 'اقلام';
			|it = 'Merci';
			|pl = 'Wiersze pozycji';
			|tr = 'Ürünler'"),
		Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CheckChangesInBusinessOperations(Cancel);
	
	PurchasesServer.CheckCorrectnessOfPurchaseDocument(ThisObject,Cancel);
	TMCommonUse.CheckCorrectnessOfIndicationOfBusinessOperation(ThisObject, Cancel);
	
	If ValueIsFilled("ReusablePackagesReturnDate") And ToReturnReusablePackage And ReusablePackagesReturnDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày trả lại bao bì luân chuyển không thể nhỏ hơn ngày chứng từ.';
						|ru = 'Дата возврата многооборотной тары не должна быть меньше даты документа.';
						|en = 'Reusable packaging units return date can not be later than the document date.'; fa = 'Reusable packaging units return date can not be later than the document date.';
						|it = 'La data di reso dell''imballaggio riutilizzabile non deve essere precedente alla data del documento.';
						|pl = 'Data zwrotu tary wielokrotnego użytku nie może być mniejsza, niż data dokumentu.';
						|tr = 'Yeniden kullanılabilir ambalajların iade tarihi, belgenin tarihinden daha önce olmamalıdır.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			"Object.ReusablePackagesReturnDate",
			,
			Cancel);
		
	EndIf;
	
	If GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")
		And CheckExpenseAnalytics Then
		ItemsAndDimensionsSelectionParameters = Documents.VendorInvoice.ItemsAndDimensionsSelectionParameters(BusinessOperation);
		IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
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
	
	PurchasesServer.CheckSeparateRegistrationOfGoods(Organization, BusinessOperation, Contract, 
		Goods.Unload(, "LineNumber, Products"), Cancel);
	
	Documents.VendorInvoice.CheckItemTypes(BusinessOperation, Organization, Contract, 
		Goods.UnloadColumn("Products"), Cancel);
	
	VendorInvoiceLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var HeaderAttributes;
	Var WarehouseForReceipt;
	Var EconomicOperationOfAcceptance;
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		If FillingData.Property("DocumentBasis")
			And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(FillingData.DocumentBasis) = Type("Array")) Then
			
			FillingData.Property("WarehouseForReceipt", WarehouseForReceipt);
			FillingData.Property("HeaderAttributes", HeaderAttributes);
			FillInDocumentBasedOnOrderToSupplier(FillingData.DocumentBasis, WarehouseForReceipt, HeaderAttributes);
			
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReturnOfGoodsToVendor") Then
				FillInDocumentOnBasisOfAcceptanceCertificateAfterShipment(FillingData);
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.VendorInvoice") Then
				FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData);
			EndIf;
		ElsIf FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
			
			FillingData.Property("WarehouseForReceipt",				WarehouseForReceipt);
			FillingData.Property("EconomicOperationOfAcceptance",	EconomicOperationOfAcceptance);
			
			FillInDocumentBasedOnAgreementWithSupplier(FillingData.DocumentBasis,
																WarehouseForReceipt,
																EconomicOperationOfAcceptance);
			
		ElsIf FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.CounterpartyContracts") Then
			
			FillingData.Property("WarehouseForReceipt", WarehouseForReceipt);
			FillInDocumentOnBasisOfContractWithCounterparty(FillingData.DocumentBasis, WarehouseForReceipt);
		ElsIf FillingData.Property("DocumentBasis")
			And TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
			
			FillInDocumentBasedOnReceiptOfServicesToUnit(FillingData.DocumentBasis);
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("DocumentRef.PurchaseOrder") Then
		FillInDocumentBasedOnOrderToSupplier(FillingData, WarehouseForReceipt);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.ApplicationForCollateral") Then
		FillInDocumentBasedOnSupplyRequest(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReturnOfGoodsToVendor") Then
		FillInDocumentBasedOnReturnOfGoodsToSupplier(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		FillInDocumentBasedOnAgreementWithSupplier(FillingData);
	ElsIf TypeOf(FillingData) = Type("DocumentRef.SubcontractorReport2_5") Then
		FillInDocumentBasedOnReportOfProcessor2_5(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
		FillInDocumentBasedOnReceiptOfServicesToUnit(FillingData);
	EndIf;
	
	FillOutBankAccounts();
	
	Author = Users.CurrentUser();
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);

	OrderBase = PurchasesServer.DocumentBasis(ThisObject, "ReceiptUnderOrders, PurchaseOrder, Goods.PurchaseOrder");
	ResponsiblePersonsServer.InstallManager(ThisObject, OrderBase);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoice.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);

	If ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice And Not ReceiptUnderOrders 
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		
		If ValueIsFilled(Terms) Then
			DetailsOfAgreement = Common.ObjectAttributesValues(Terms,"ContractsAreUsed,FinancialAccountingGroup");
			If DetailsOfAgreement.ContractsAreUsed 
				And ValueIsFilled(Contract) Then
				FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
			Else
				FinancialAccountingGroup = DetailsOfAgreement.FinancialAccountingGroup;
			EndIf;
		ElsIf ValueIsFilled(Contract) Then
			FinancialAccountingGroup = Common.ObjectAttributeValue(Contract,"FinancialAccountingGroup");
		EndIf;
		
	EndIf;
	
	VendorInvoiceLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
	ThereAreAdjustingEntries = False;
	ThereIsSF = False;
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereIsSF);
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWTCProcurementDocuments(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False, "ToExpenseAs");
	
	RecalculateNumberOfRNPT();
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If Not ValueIsFilled(ServiceReceiptOption) Then
		ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	EndIf;
	
	ThereAreAdjustingEntries = False;
	ThereIsSF = False;
	PurchasesServer.CheckForAdjustmentsAndInvoices(Ref, Ref, ThereAreAdjustingEntries, ThereIsSF);
	If WriteMode = DocumentWriteMode.UndoPosting And ThereAreAdjustingEntries Then
		PurchasesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	AdditionalProperties.Insert("ExpenseReport", Common.ObjectAttributeValue(Ref, "ExpenseReport"));
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.VendorInvoice.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	If (BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
		Or Not ToReturnReusablePackage)
		And PackageDepositIsRequired Then
		PackageDepositIsRequired = False;
	EndIf;
	
	DocumentAmount = GetDocumentAmount();
	
	If ReceiptUnderOrders And ValueIsFilled(PurchaseOrder) Then
		
		For Each CurRow In Goods Do
			
			If Not ValueIsFilled(CurRow.PurchaseOrder) Then
				CurRow.PurchaseOrder = PurchaseOrder;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
		And ValueIsFilled(Counterparty) Then
		
		For Each TSRow In Goods Do
			TSRow.IncomingDocumentNumber = Undefined;
			TSRow.IncomingDocumentDate = Undefined;
			TSRow.ExternalDocumentName = Undefined;
		EndDo;
	EndIf;
	
	ProductsServer.ClearUnusedSeries(ThisObject, 
								ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.VendorInvoice));
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(ThisObject, WriteMode);
	
	RegistrationParameters = Documents.VendorInvoice.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	ItemsAndDimensionsSelectionParameters = Documents.VendorInvoice.ItemsAndDimensionsSelectionParameters(BusinessOperation);
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	If Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	AccountingForTraceableGoodsLocalization.ClearGTDUNumbersOfTraceableWorks(ThisObject);
	AccountingForTraceableGoodsLocalization.ClearGTDUNumberOfTraceableGoodsInDocumentPurchaseOfGoodsServices(ThisObject);
	
	If WriteMode = DocumentWriteMode.Posting Then
		If BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
			ARAPAccountingServer.FillInAmountOfPaymentDecryptionForDocumentAmount(
				DocumentAmount,
				ARAPDetails);
			ARAPAccountingServer.FillInAmountOfSettlementsInTablePart(
				Currency,
				Date,
				ARAPDetails,
				Organization);
				
			AdvancedParameters = ARAPAccountingServer.AugmentedMechanismParameters(ThisObject);
			
			For Each ParametersStructure In AdvancedParameters.ParametersArray Do
				
				If ParametersStructure.Organization <> Catalogs.Companies.ManagementCompany Then
					Continue;
				EndIf;
				
				If IsNew() Then
					RefToNew = GetNewObjectRef();
					If Not ValueIsFilled(RefToNew) Then
						RefToNew = Common.ObjectManagerByRef(Ref).GetRef();
						SetNewObjectRef(RefToNew);
					EndIf;
					ParametersStructure.Insert("RefToNew", RefToNew);
				EndIf;
				
				APARObjectDetails = ARAPObjectsServer.DetailsOfObjectOfCalculationsByStructure(ThisObject,Ref,ParametersStructure, WriteMode);
				ObjectOfManCalculations = ARAPObjectsServer.CheckCreateCalculationObject(APARObjectDetails);
				
			EndDo;
			
		ElsIf Organization <> Catalogs.Companies.ManagementCompany Then
			If ValueIsFilled(ObjectOfManCalculations) Then
				ObjectOfManCalculations = Catalogs.ARAPObjects.EmptyRef();
			EndIf;
			ObjectOfCalculationsForManOfOrganization = ARAPObjectsServer.GetCalculationObjectFromLink(Ref, 
				Catalogs.Companies.ManagementCompany, Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
			If ValueIsFilled(ObjectOfCalculationsForManOfOrganization) Then
				ARAPObjectsServer.CheckDeleteCalculationObject(ObjectOfCalculationsForManOfOrganization, Cancel, True);
			EndIf;
		EndIf;
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		InventoryKinds.Clear();
	EndIf;
	
	CurrentTotal = 0;
	For Each TSRow In Goods Do
		CurrentTotal = CurrentTotal + TSRow.AmountIncludingVAT;
		TSRow.AmountTotal = CurrentTotal;
	EndDo;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	// The mechanism of "Controlled Lot references".
	KeyAttributes = QualityControl.DetailsOfDeterminingNeedForLotReferenceInDocument(Warehouse, BusinessOperation);
	QualityControl.FillInControlledLotReferenceBeforeWritingDocument(ThisObject, KeyAttributes);
	
	VendorInvoiceLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	RegistrationParameters = Documents.VendorInvoice.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedDuring(RegistrationParameters);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	VendorInvoiceLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RegistrationParameters = Documents.VendorInvoice.ParametersForRegisteringInvoicesReceived(ThisObject);
	VATAccountingERP.UpdateInvoicesReceivedWhenDeletingData(RegistrationParameters);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	VendorInvoiceLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Approved      = False;
	ReceiptUnderOrders = False;
	PurchaseOrder = Documents.PurchaseOrder.EmptyRef();
	IncomingDocumentDate = Date(1,1,1);
	IncomingDocumentNumber = "";
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ExpenseReport = Undefined;
	NewWayToCreateApplicationForGoodsImportFromEAEU = True;
	DocumentBasis = Undefined;
	ControlledLotReference = Catalogs.ControlledLots.EmptyRef();
	
	If ValueIsFilled(Terms) Then
		DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ReusablePackageReturnCycleLength, CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn");
		ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			ThisObject,
			DetailsOfAgreement.ReusablePackageReturnCycleLength,
			DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
			DetailsOfAgreement.ScheduleOfPackageReturn);
	Else
		ReusablePackagesReturnDate = Date(1,1,1);
	EndIf;
	
	If Not GetFunctionalOption("UsePaymentsToSelfEmployedPersons") Then
		OperationWithSelfEmployedPerson = False;
	EndIf;
	
	For Each CurRow In Goods Do
		
		CurRow.PurchaseOrder = Documents.PurchaseOrder.EmptyRef();
		CurRow.RowCode = 0;
		CurRow.InventoryOwnerAttribute = Catalogs.InventoryKinds.EmptyRef();
		CurRow.RowID = "";
		CurRow.IncomingDocumentNumber = "";
		CurRow.IncomingDocumentDate = Undefined;
		CurRow.ExternalDocumentName = "";
	EndDo;
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();

	InitializeDocument();
	
	RecalculateNumberOfRNPT();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	VendorInvoiceLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	If ValueIsFilled(ExpenseReport)
		And Not AdditionalProperties.Property("DoNotUpdateAdvanceReport") Then
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(ExpenseReport, "DocumentsRegistry");
		InformationRegisters.DocumentsRegistry.WriteData(TablesForRegisteredRecords, ExpenseReport, Undefined, Cancel);
	EndIf;
	
	If AdditionalProperties.Property("ExpenseReport")
		And Not AdditionalProperties.Property("DoNotUpdateAdvanceReport")
		And ValueIsFilled(AdditionalProperties.ExpenseReport)
		And AdditionalProperties.ExpenseReport <> ExpenseReport Then
		
		TablesForRegisteredRecords = DocumentsPosting.DocumentDataForPosting(
			AdditionalProperties.ExpenseReport, "DocumentsRegistry");
		InformationRegisters.DocumentsRegistry.WriteData(
			TablesForRegisteredRecords,
		 	AdditionalProperties.ExpenseReport,
		 	Undefined,
		 	Cancel);
	EndIf;
	
	// The mechanism of "Controlled Lot references".
	QualityControl.CreateUpdateControlledLotReferenceWhenWritingDocument(ThisObject);
	
	VendorInvoiceLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure CheckRecordParametersForPurchasingUnderPrincipal(LineNumber, ErrorAddress, Purpose, Cancel)
	
	SetPrivilegedMode(True);
	
	If Not BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		ErrorText = StrTemplate(
				NStr("vi = 'Đối với mặt hàng %1 được mua theo chương trình đại lý, bạn chỉ có thể sử dụng  giao dịch ""Mua hàng từ nhà cung cấp""';
					|ru = 'Для номенклатуры %1, закупаемой по агентской схеме, можно использовать только операцию ""Закупка у поставщика""';
					|en = 'Only the ""Purchase from vendor"" transaction can be used for the products %1 purchased by agency.'; fa = 'Only the ""Purchase from vendor"" transaction can be used for the products %1 purchased by agency.';
					|it = 'Per l''articolo %1 acquistato in regime di agenzia si può usare solo l''operazione ""Acquisto dal fornitore""';
					|pl = 'Dla nomenklatury %1, kupowanej wg schematu agencyjnego, można używać tylko operacji ""Zakup u dostawcy""';
					|tr = 'Acente programı kapsamında satın alınan %1öğeler için yalnızca ""tedarikçiden satın alım"" işlemi kullanılabilir'"),
				ErrorAddress);
		
		CommonClientServer.MessageToUser(
		ErrorText ,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods",LineNumber, "Purpose"),
		,
		Cancel);
	EndIf;
		
	CurrencyOfDestinationAgreement  = Common.ObjectAttributeValue(Purpose, "Contract.ARAPCurrency");
	If CurrencyOfDestinationAgreement <> Currency Then
		ErrorText = StrTemplate(
			NStr("vi = 'Đối với mặt hàng %1 được mua theo sơ đồ đại lý, loại tiền được chỉ định trong thỏa thuận đích phải khớp với loại tiền trong chứng từ';
				|ru = 'Для номенклатуры %1, закупаемой по агентской схеме, валюта, указанная в договоре назначения, должна совпадать с валютой документа';
				|en = 'The currency specified in the assignment contract must match with the currency of the document to the %1products purchased on agency basis.'; fa = 'The currency specified in the assignment contract must match with the currency of the document to the %1products purchased on agency basis.';
				|it = 'Per l''articolo %1, acquistato secondo lo schema d''agente, la valuta indicata nel contratto di destinazione deve coincidere con la valuta del documento';
				|pl = 'Dla nomenklatury %1, nabywanej wg schematu agencyjnego, waluta, podana w umowie przeznaczenia, powinna zbiegać się z walutą dokumentu';
				|tr = 'Acente programı kapsamında satın alınan %1öğeler için varış sözleşmesinde belirtilen para birimi belgenin para birimiyle eşleşmelidir'"),
			ErrorAddress);
		
		CommonClientServer.MessageToUser(
		ErrorText ,
		ThisObject,
		CommonClientServer.PathToTabularSection("Goods", LineNumber, "Purpose"),
		,
		Cancel);
	EndIf;
	
	OrganizationOfContractOfAppointment  = Common.ObjectAttributeValue(Purpose, "Contract.Organization");
	If OrganizationOfContractOfAppointment <> Organization Then
		ErrorText = StrTemplate(
			NStr("vi = 'Đối với mặt hàng %1 được mua theo sơ đồ đại lý, doanh nghiệp được chỉ định trong hợp đồng đích phải trùng với doanh nghiệp trong chứng từ';
				|ru = 'Для номенклатуры %1, закупаемой по агентской схеме, организация, указанная в договоре назначения, должна совпадать с организацией документа';
				|en = 'The company specified in the assignment contract must match the company specified in the document for the %1 products purchased on the agency basis.'; fa = 'The company specified in the assignment contract must match the company specified in the document for the %1 products purchased on the agency basis.';
				|it = 'Per l''articolo %1, acquistato secondo lo schema d''agente, l''azienda indicata nel contratto di destinazione deve coincidere con l''azienda nel documento';
				|pl = 'Dla nomenklatury %1, nabywanej wg schematu agencyjnego, firma, podana w umowie przeznaczenia, powinna zbiegać się z firmą dokumentu';
				|tr = 'Acente programı kapsamında satın alınan %1 öğesi için varış sözleşmesinde adı geçen iş yeri, belgenin düzenlendiği iş yeriyle aynı olmalıdır'"),
			ErrorAddress);
		
		CommonClientServer.MessageToUser(
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

Procedure FillInDocumentBasedOnOrderToSupplier(Val OrderBase, Val WarehouseForReceipt = Undefined, OrderDetails = Undefined)

	BasisType = TypeOf(OrderBase);
	FillInByLeftovers = False;
	ReceiptUnderOrders = True;
	
	If BasisType = Type("DocumentRef.PurchaseOrder") Then
		
		Query = New Query;
		Query.SetParameter("OrderBase", OrderBase);
		Query.Text =
		"SELECT
		|	PurchaseOrder.SalesOpportunity AS SalesOpportunity,
		|	PurchaseOrder.Terms.RegisterVendorPrices AS RegisterVendorPrices,
		|	PurchaseOrder.Ref AS PurchaseOrder,
		|	PurchaseOrder.Partner AS Partner,
		|	PurchaseOrder.Counterparty AS Counterparty,
		|	PurchaseOrder.Contract AS Contract,
		|	PurchaseOrder.ServiceReceiptOption AS ServiceReceiptOption,
		|	PurchaseOrder.Contract.OptionForRegisteringServiceReceiptDocuments AS OptionForRegisteringServiceReceiptDocuments,
		|	PurchaseOrder.Contract.PurchaseRegistrationOption AS PurchaseRegistrationOption,
		|	PurchaseOrder.Organization AS Organization,
		|	PurchaseOrder.Terms AS Terms,
		|	PurchaseOrder.Currency AS Currency,
		|	PurchaseOrder.Currency AS ARAPCurrency,
		|	CASE
		|		WHEN PurchaseOrder.Warehouse.IsFolder
		|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE PurchaseOrder.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN PurchaseOrder.Warehouse.IsFolder
		|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ItIsForbiddenToSelectWarehouseGroup,
		|	PurchaseOrder.PaymentMethod AS PaymentMethod,
		|	PurchaseOrder.PriceIncludesVAT AS PriceIncludesVAT,
		|	PurchaseOrder.VATTaxation AS VATTaxation,
		|	PurchaseOrder.PurchaseForActivity AS PurchaseForActivity,
		|	PurchaseOrder.BusinessOperation AS BusinessOperation,
		|	PurchaseOrder.Status AS DocumentStatus,
		|	PurchaseOrder.Department AS Department,
		|	PurchaseOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	PurchaseOrder.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	PurchaseOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	PurchaseOrder.PackageDepositIsRequired AS PackageDepositIsRequired,
		|	ISNULL(PurchaseOrder.Terms.CalculatePackageReturnDateAccordingToCalendar,FALSE) AS CalculatePackageReturnDateAccordingToCalendar,
		|	ISNULL(PurchaseOrder.Terms.ScheduleOfPackageReturn,VALUE(Catalog.BusinessCalendars.EmptyRef)) AS ScheduleOfPackageReturn,
		|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|				OR PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	PurchaseOrder.BankAccount AS CompanyBankAccount,
		|	PurchaseOrder.ARAPObjectSettings AS ARAPObjectSettings,
		|	PurchaseOrder.LineOfBusiness AS LineOfBusiness,
		|	PurchaseOrder.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	PurchaseOrder.RegisterVendorPrices,
		|	PurchaseOrder.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Ref = &OrderBase
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrdersBalance.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder = &OrderBase) AS OrdersBalance";
		
		QueryResult = Query.ExecuteBatch();
		
		OrderDetails = QueryResult[0].Select();
		OrderDetails.Next();
		
		ArrayOfValidStatuses = New Array();
		ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Confirmed_);
		ArrayOfValidStatuses.Add(Enums.PurchaseOrderStatuses.Closed);
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.PurchaseOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted,
			OrderDetails.ThereAreErrorsStatus,
			ArrayOfValidStatuses);
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		PurchaseRegistrationOption = Common.ObjectAttributeValue(OrderDetails.Contract, "PurchaseRegistrationOption");
		OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(OrderDetails.Contract, "OptionForRegisteringServiceReceiptDocuments");
		
		If Not PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices 
			And OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
			EconomicOperationOfFoundation = Common.ObjectAttributeValue(OrderBase, "BusinessOperation");	
			
			If EconomicOperationOfFoundation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
				BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
			ElsIf EconomicOperationOfFoundation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
			EndIf;
		EndIf;
		
		ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			ThisObject,
			OrderDetails.ReusablePackageReturnCycleLength,
			OrderDetails.CalculatePackageReturnDateAccordingToCalendar,
			OrderDetails.ScheduleOfPackageReturn);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = QueryResult[1].Unload().UnloadColumn("Warehouse");
		EndIf;
		
	ElsIf BasisType = Type("Array") Then
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		
		PurchaseRegistrationOption = Common.ObjectAttributeValue(OrderDetails.Contract, "PurchaseRegistrationOption");
		OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(OrderDetails.Contract, "OptionForRegisteringServiceReceiptDocuments");
		
		If Not PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices 
			And OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed 
			And Not OrderBase.Count() = 0 Then
			EconomicOperationOfFoundation = Common.ObjectAttributeValue(OrderBase.Get(0), "BusinessOperation");	
			
			If EconomicOperationOfFoundation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
				BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
			ElsIf EconomicOperationOfFoundation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
			EndIf;
		EndIf;
		
		Currency = ARAPCurrency;
		
		ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			ThisObject,
			OrderDetails.ReusablePackageReturnCycleLength,
			OrderDetails.CalculatePackageReturnDateAccordingToCalendar,
			OrderDetails.ScheduleOfPackageReturn);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			Query = New Query;
			Query.SetParameter("DocumentsArray", OrderBase);
			Query.Text =
			"SELECT DISTINCT
			|	OrdersBalance.Warehouse AS Warehouse
			|FROM
			|	AccumulationRegister.PurchaseOrders.Balance(
			|		,
			|		PurchaseOrder IN (&DocumentsArray)
			|) AS OrdersBalance
			|";
			
			RequestResultForWarehouses = Query.Execute();
			WarehouseArray = RequestResultForWarehouses.Unload().UnloadColumn("Warehouse");
			Warehouse = OrderDetails.WarehouseForReceipt;
			
		EndIf;
		
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
	EndIf;
	
	UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
	If UseLinesOfBusiness And Not (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders) Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
		FillInPaymentTerms_(PurchaseConditions);
	EndIf;
	
	// Filling in incl. goods.
	If Not ValueIsFilled(WarehouseForReceipt) Then
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			FillInByLeftovers = True;
			For Each WarehouseTS In WarehouseArray Do
				If ValueIsFilled(WarehouseTS) Then
					WarehouseForReceipt = WarehouseTS;
					Warehouse = WarehouseForReceipt;
					Break;
				EndIf;
			EndDo;
		Else
			FillInByLeftovers = True;
			WarehouseForReceipt = Warehouse;
		EndIf;
	Else
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			Warehouse = WarehouseForReceipt;
		Else
			WarehouseForReceipt = Warehouse;
		EndIf;
		FillInByLeftovers = True;
	EndIf;
	
	If FillInByLeftovers Then
		
		If BasisType = Type("Array") Then
			AnArrayOfOrders = OrderBase;
		Else
			AnArrayOfOrders = New Array();
			AnArrayOfOrders.Add(PurchaseOrder);
		EndIf;
		
		Documents.VendorInvoice.FillByOrderBalances(
			ThisObject,
			Goods,
			?(WarehouseForReceipt=Undefined, Catalogs.Warehouses.EmptyRef(), WarehouseForReceipt),
			AnArrayOfOrders);
		
		OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
	
		If Not ValueIsFilled(PurchaseOrder)
			And AnArrayOfOrders.Count() = 1
			And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.PurchaseOrder") Then
			PurchaseOrder = AnArrayOfOrders[0];
		EndIf;

	EndIf;
	
	If GetFunctionalOption("UseReceiptForMultipleOrders") Then
		SalesOpportunity = Catalogs.SalesOpportunitiesToCustomer.EmptyRef();
	EndIf;
	
EndProcedure

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
	ARAPCurrency = Currency;
	
	DocumentBasis = ApplicationForCollateral;
	
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

Procedure FillInDocumentBasedOnReturnOfGoodsToSupplier(Val OrderBase)

	Query = New Query;
	Query.SetParameter("OrderBase", OrderBase);
	Query.SetParameter("AdjustmentOfStockWithProductBatchID", AdjustmentOfStockWithProductBatchID);
	Query.Text =
	"SELECT
	|	ReturnOfGoodsToVendor.Ref                         AS Ref,
	|	ReturnOfGoodsToVendor.Organization                    AS Organization,
	|	ReturnOfGoodsToVendor.Partner                        AS Partner,
	|	ReturnOfGoodsToVendor.Counterparty                     AS Counterparty,
	|	ReturnOfGoodsToVendor.Department                  AS Department,
	|	ReturnOfGoodsToVendor.Currency                         AS Currency,
	|	ReturnOfGoodsToVendor.Currency                         AS ARAPCurrency,
	|	ReturnOfGoodsToVendor.DocumentAmount                 AS DocumentAmount,
	|	ReturnOfGoodsToVendor.DocumentAmount                 AS AmountARAP,
	|	ReturnOfGoodsToVendor.Warehouse                          AS Warehouse,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT                AS PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.VATTaxation             AS VATTaxation,
	|	ReturnOfGoodsToVendor.CounterpartyBankAccount      AS CounterpartyBankAccount,
	|	ReturnOfGoodsToVendor.Shipper               AS Shipper,
	|	ReturnOfGoodsToVendor.ShipperBankAccount AS ShipperBankAccount,
	|	ReturnOfGoodsToVendor.Contract                        AS Contract,
	|	ReturnOfGoodsToVendor.Terms                     AS Terms,
	|	CASE
	|		WHEN
	|			ReturnOfGoodsToVendor.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToConsignor)
	|		THEN
	|			VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|	END AS BusinessOperation,
	|	ReturnOfGoodsToVendor.ReturnOfReceivedReusablePackages AS ToReturnReusablePackage,
	|	ReturnOfGoodsToVendor.DepositForPackageIsRequired AS PackageDepositIsRequired,
	|	ReturnOfGoodsToVendor.LineOfBusiness AS LineOfBusiness,
	|	ReturnOfGoodsToVendor.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|
	|	NOT ReturnOfGoodsToVendor.Posted AS ThereAreErrorsPosted,
	|
	|	ReturnOfGoodsToVendor.Goods.(
	|		PartnerProducts   AS PartnerProducts,
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		CASE
	|			WHEN &AdjustmentOfStockWithProductBatchID
	|				THEN Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END AS Series,
	|		CASE
	|			WHEN &AdjustmentOfStockWithProductBatchID
	|				THEN BatchesIndicationStatus
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END AS BatchesIndicationStatus,
	|		CASE
	|			WHEN &AdjustmentOfStockWithProductBatchID
	|				THEN Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END AS Purpose,
	|		Package                 AS Package,
	|		NumberOfPackages       AS NumberOfPackages,
	|		Count               AS Count,
	|		Price                     AS Price,
	|		Sum                    AS Sum,
	|		VATRate                AS VATRate,
	|		VATAmount                 AS VATAmount,
	|		AmountIncludingVAT                AS AmountIncludingVAT,
	|		Ref.Warehouse             AS Warehouse
	|	) AS Goods,
	|
	|	ReturnOfGoodsToVendor.SetOfSeries.(
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		Series                    AS Series,
	|		CASE
	|			WHEN &AdjustmentOfStockWithProductBatchID
	|				THEN Purpose
	|			ELSE VALUE(Catalog.Assignments.EmptyRef)
	|		END AS Purpose,
	|		CASE
	|			WHEN &AdjustmentOfStockWithProductBatchID
	|				THEN Ref.Warehouse
	|			ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|		END AS Warehouse,
	|		Count               AS Count
	|	) AS SetOfSeries
	|
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|WHERE
	|	ReturnOfGoodsToVendor.Ref = &OrderBase";
	Selection = Query.Execute().Select();
	Selection.Next();

	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Ref,
		,
		Selection.ThereAreErrorsPosted,);
	
	// Filling in the header and tabular parts
	FillPropertyValues(ThisObject, Selection);
	
	Goods.Load(Selection.Goods.Unload());
	SetOfSeries.Load(Selection.SetOfSeries.Unload());
	
EndProcedure

Procedure FillInDocumentBasedOnAgreementWithSupplier(Val OrderBase,
															Val WarehouseForReceipt = Undefined,
															Val EconomicOperationOfAcceptance = Undefined)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	TermsOfPurchases.Ref AS Terms,
	|	TermsOfPurchases.Partner AS Partner,
	|	TermsOfPurchases.Status AS DocumentStatus,
	|	CASE
	|		WHEN TermsOfPurchases.Status <> VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThereAreErrorsStatus,
	|	CASE
	|		WHEN TermsOfPurchases.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS TheseAreAgencyServices,
	|	TermsOfPurchases.LineOfBusiness AS LineOfBusiness,
	|	TermsOfPurchases.BusinessOperation AS BusinessOperation
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchases
	|WHERE
	|	TermsOfPurchases.Ref = &OrderBase
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsReadyForReceiptBalance.Warehouse,
	|	GoodsReadyForReceiptBalance.DocumentInflow,
	|	GoodsReadyForReceiptBalance.Products,
	|	GoodsReadyForReceiptBalance.Characteristic,
	|	GoodsReadyForReceiptBalance.Purpose,
	|	GoodsReadyForReceiptBalance.Series,
	|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS Count,
	|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			DocumentInflow = &OrderBase
	|			AND CASE
	|				WHEN &WarehouseSpecified
	|					THEN Warehouse = &WarehouseForReceipt
	|				ELSE TRUE
	|			END
	|			AND (NOT &FilterByBusinessTransaction
	|				OR BusinessOperation IN(&BusinessOperation))) AS GoodsReadyForReceiptBalance
	|WHERE
	|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance > 0";
		
	Query.SetParameter("OrderBase",					OrderBase);
	Query.SetParameter("WarehouseForReceipt",				WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified",					ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("FilterByBusinessTransaction",	ValueIsFilled(EconomicOperationOfAcceptance));
	Query.SetParameter("BusinessOperation",			EconomicOperationOfAcceptance);
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array;
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfPurchase.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(Selection.Terms,
															Selection.DocumentStatus,
															,
															Selection.ThereAreErrorsStatus,
															ArrayOfValidStatuses);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(False, Selection.TheseAreAgencyServices);
	
	FillPropertyValues(ThisObject, Selection);
	
	If ValueIsFilled(EconomicOperationOfAcceptance) Then
		BusinessOperation = EconomicOperationOfAcceptance;
	EndIf;
	
	If ValueIsFilled(WarehouseForReceipt) Then
		Warehouse = WarehouseForReceipt;
	EndIf;
	
	Goods.Load(QueryResult[1].Unload());
	FillInTermsOfPurchaseUnderAgreement();
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterShipment(Val FillingData)
	
	SetPrivilegedMode(True);
	
	Query = New Query("
	|SELECT
	|	ReturnOfGoodsToVendor.Ref AS Ref,
	|	ReturnOfGoodsToVendor.Terms AS Terms,
	|	ReturnOfGoodsToVendor.Organization AS Organization,
	|	ReturnOfGoodsToVendor.Partner AS Partner,
	|	ReturnOfGoodsToVendor.Counterparty AS Counterparty,
	|	ReturnOfGoodsToVendor.Currency AS Currency,
	|	ReturnOfGoodsToVendor.SalesOpportunity AS SalesOpportunity,
	|	ReturnOfGoodsToVendor.Department AS Department,
	|	ReturnOfGoodsToVendor.Warehouse AS Warehouse,
	|	CASE 
	|		WHEN ReturnOfGoodsToVendor.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor) THEN
	|			VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN ReturnOfGoodsToVendor.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsToConsignor) THEN
	|			VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|	END AS BusinessOperation,
	|	ReturnOfGoodsToVendor.PriceIncludesVAT AS PriceIncludesVAT,
	|	ReturnOfGoodsToVendor.VATTaxation AS VATTaxation,
	|	ReturnOfGoodsToVendor.Contract AS Contract,
	|	ReturnOfGoodsToVendor.ReturnOfReceivedReusablePackages AS ReturnOfReceivedReusablePackages,
	|	ReturnOfGoodsToVendor.DepositForPackageIsRequired AS DepositForPackageIsRequired,
	|	NOT ReturnOfGoodsToVendor.Posted AS ThereAreErrorsPosted,
	|	ReturnOfGoodsToVendor.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|WHERE
	|	ReturnOfGoodsToVendor.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Count - CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument) AS Count,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum - CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument) AS Sum,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument) AS VATAmount,
	|	SUM(CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument) AS AmountIncludingVAT
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument > 0
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package,
	|	Price,
	|	VATRate,
	|	SaleOfGoodsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Products AS Products,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Characteristic AS Characteristic,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Series AS Series,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Purpose AS Purpose,
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Warehouse AS Warehouse,
	|	SUM(DiscrepancyReportFollowingShipmentSetOfSeries.Count - DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS DiscrepancyReportFollowingShipmentSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingShipmentSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.SaleOfGoodsAndServices = &DocumentBasis
	|	AND DiscrepancyReportFollowingShipmentSetOfSeries.Count - DiscrepancyReportFollowingShipmentSetOfSeries.CountByDocument > 0
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse,
	|	Purpose
	|;");
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		,
		HeaderSelection.ThereAreErrorsPosted,
		,
		);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	SubsequentDeliveryByDocument = FillingData.BasisOfAct;
	
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
	
EndProcedure

Procedure FillInDocumentOnBasisOfAcceptanceCertificateAfterReceipt(FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	VendorInvoice.Ref                    AS DocumentInflow,
	|	DiscrepancyReportFollowingReceipt.Ref               AS DiscrepancyCertificate,
	|	VendorInvoice.Terms                AS Terms,
	|	VendorInvoice.Organization               AS Organization,
	|	VendorInvoice.Partner                   AS Partner,
	|	VendorInvoice.Counterparty                AS Counterparty,
	|	VendorInvoice.Currency                    AS Currency,
	|	VendorInvoice.SalesOpportunity                    AS SalesOpportunity,
	|	VendorInvoice.Department             AS Department,
	|	VendorInvoice.Warehouse                     AS Warehouse,
	|	VendorInvoice.BusinessOperation     AS BusinessOperation,
	|	VendorInvoice.PriceIncludesVAT           AS PriceIncludesVAT,
	|	VendorInvoice.VATTaxation        AS VATTaxation,
	|	VendorInvoice.Contract                   AS Contract,
	|	VendorInvoice.Manager                  AS Manager,
	|	VendorInvoice.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	VendorInvoice.PackageDepositIsRequired      AS PackageDepositIsRequired,
	|	NOT DiscrepancyReportFollowingReceipt.Posted          AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	DiscrepancyReportFollowingReceipt.Status               AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport,
	|	NOT VendorInvoice.Posted               AS ThereAreErrorsInReceiptDocument

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
	|	DiscrepancyReportFollowingReceipt.PartnerProducts AS PartnerProducts,
	|	DiscrepancyReportFollowingReceipt.Characteristic         AS Characteristic,
	|	DiscrepancyReportFollowingReceipt.Purpose             AS Purpose,
	|	DiscrepancyReportFollowingReceipt.Series                  AS Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Package               AS Package,
	|	DiscrepancyReportFollowingReceipt.VendorPriceKind      AS VendorPriceKind,
	|	DiscrepancyReportFollowingReceipt.Price                   AS Price,
	|	DiscrepancyReportFollowingReceipt.VATRate              AS VATRate,
	|	DiscrepancyReportFollowingReceipt.PurchaseOrder        AS PurchaseOrder,
	|	DiscrepancyReportFollowingReceipt.RowCode              AS RowCode,
	|	DiscrepancyReportFollowingReceipt.Warehouse                  AS Warehouse,
	|	DiscrepancyReportFollowingReceipt.ExpenseItem         AS ExpenseItem,
	|	DiscrepancyReportFollowingReceipt.DimensionOfExpenses      AS DimensionOfExpenses,
	|	DiscrepancyReportFollowingReceipt.Department          AS Department,
	|	DiscrepancyReportFollowingReceipt.SalesOpportunity                 AS SalesOpportunity,
	|	DiscrepancyReportFollowingReceipt.CCDNumber               AS CCDNumber,
	|	DiscrepancyReportFollowingReceipt.Action               AS GoodsAction,
	|
	|	SUM(DiscrepancyReportFollowingReceipt.CountByDocument - DiscrepancyReportFollowingReceipt.Count)                AS Count,
	|	SUM(DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages) AS NumberOfPackages,
	|	SUM(DiscrepancyReportFollowingReceipt.SumByDocument - DiscrepancyReportFollowingReceipt.Sum)                           AS Sum,
	|	SUM(DiscrepancyReportFollowingReceipt.VATAmountByDocument - DiscrepancyReportFollowingReceipt.VATAmount)                     AS VATAmount,
	|	SUM(DiscrepancyReportFollowingReceipt.AmountIncludingVATByDocument - DiscrepancyReportFollowingReceipt.AmountIncludingVAT)                   AS AmountIncludingVAT
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceipt.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument - DiscrepancyReportFollowingReceipt.NumberOfPackages > 0
	|GROUP BY
	|	Products,
	|	PartnerProducts,
	|	Characteristic,
	|	Purpose,
	|	Series,
	|	BatchesIndicationStatus,
	|	Package,
	|	VendorPriceKind,
	|	Price,
	|	VATRate,
	|	PurchaseOrder,
	|	RowCode,
	|	Warehouse,
	|	ExpenseItem,
	|	DimensionOfExpenses,
	|	Department,
	|	SalesOpportunity,
	|	CCDNumber,
	|	Action
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products                                                                 AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic                                                               AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series                                                                        AS Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose                                                                   AS Purpose,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse                                                                        AS Warehouse,
	|	SUM( DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument - DiscrepancyReportFollowingReceiptSetOfSeries.Count) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument - DiscrepancyReportFollowingReceiptSetOfSeries.Count > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Warehouse,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
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
	
	SubsequentDeliveryByDocument = FillingData.BasisOfAct;
	
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
			
		If ValueIsFilled(CurRow.PurchaseOrder) Then
			ReceiptUnderOrders = True;
		EndIf;

		ThisIsTwoWay = PurchasesServer.EconomicOperationsOfSeparatePurchaseWithoutSelections().Find(BusinessOperation) <> Undefined;
		
		// Delivery in excess of the order
		If HeaderSelection.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepancyReportsFollowingReceipt.CreateReceiptAdjustingEntries
			And CurRow.GoodsAction = Enums.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndWaitForGoodsReceiptWithoutInvoices
			And Not ThisIsTwoWay Then
			NewRow.RowCode = 0;
		EndIf;	
		
	EndDo;
		
	OrdersServer.FillInOrderInOrderHeaderInTableSection(PurchaseOrder, Goods, "PurchaseOrder");
	
	SetOfSeries.Load(QueryBatch[2].Unload());
	
EndProcedure
Procedure FillInDocumentBasedOnReportOfProcessor2_5(FillingData)
	
	Query = New Query;
	Query.SetParameter("Ref", FillingData);
	Query.Text =
	"SELECT
	|	SubcontractorReport.Organization				AS Organization,
	|	SubcontractorReport.Currency					AS Currency,
	|	SubcontractorReport.ARAPCurrency		AS ARAPCurrency,
	|	SubcontractorReport.Manager					AS Manager,
	|	SubcontractorReport.Counterparty				AS Counterparty,
	|	SubcontractorReport.Partner					AS Partner,
	|	SubcontractorReport.Contract					AS Contract,
	|	SubcontractorReport.Department			AS Department,
	|	SubcontractorReport.PurchaseForActivity	AS PurchaseForActivity,
	|	SubcontractorReport.ForeignCurrencyTransaction			AS ForeignCurrencyTransaction,
	|	SubcontractorReport.BusinessOperation    AS BusinessOperation
	|FROM
	|	Document.SubcontractorReport2_5 AS SubcontractorReport
	|WHERE
	|	SubcontractorReport.Ref = &Ref";
	
	Result = Query.Execute();
	Header = Result.Select();
	Header.Next();
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header, , "BusinessOperation");
	
	If Header.BusinessOperation = Enums.BusinessTransactions.ProductionAtProcessorInEAEUCountries2_5 Then
		BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
	EndIf;
	
EndProcedure
Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Warehouse") Then
		
		Warehouse = FillingData.Warehouse;
		
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		FillInDefaultPurchaseConditions();
		
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	Department             = SettingsValueCached.UserDivision(Manager, Department);

	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, GetFunctionalOption(
		"UseWarehousesInTabularSectionsOfPurchaseDocuments"), True);
	
	StructureOfResponsible = PurchasesServer.GetWarehouseManager(Warehouse, Manager);
	If StructureOfResponsible <> Undefined Then
		ReceivedBy = StructureOfResponsible.EmployeeResponsible;
		AcceptedPosition = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	ProcessingOfExchangeRatesTM.FillInDefaultDocumentCourse(CourseNumerator, CourseDenominator, Currency, ARAPCurrency, Organization, , Contract);
	
	ReferenceOrder = DocumentBaseWhenFillingIn(FillingData);
	GoodsReceiptOption = PurchasesServer.GetProductAcceptanceOption(ReferenceOrder, Contract);
	ServiceReceiptOption = PurchasesServer.GetServiceAcceptanceOption(Contract);
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATTaxationPurchases(ThisObject);
	VATAccountingERP.FillInVATTaxationPurchases(VATTaxation, FillParameters);
	
	FillParameters = Documents.VendorInvoice.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, False, ToReturnReusablePackage);
	StructureOfFillingInVATRate.InitializingIncomingDocument = True;
	StructureOfActions.Insert("AdjustVATRate",StructureOfFillingInVATRate);
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
EndProcedure

Procedure FillInDocumentOnBasisOfContractWithCounterparty(Val ContractWithCounterparty, Val WarehouseForReceipt = Undefined)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	SupplierContract.Ref AS Contract,
		|	SupplierContract.Partner AS Partner,
		|	SupplierContract.Counterparty AS Counterparty,
		|	SupplierContract.Organization AS Organization,
		|	&WarehouseForReceipt AS Warehouse,
		|	SupplierContract.ARAPCurrency AS ARAPCurrency,
		|	SupplierContract.Status AS DocumentStatus,
		|	CASE
		|		WHEN SupplierContract.Status <> VALUE(Enum.CounterpartyContractStatuses.Valid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ThereAreErrorsStatus,
		|	CASE
		|		WHEN
		|			SupplierContract.BusinessOperation = VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
		|			THEN TRUE
		|		ELSE FALSE
		|	END										AS TheseAreAgencyServices,
		|	SupplierContract.LineOfBusiness	AS LineOfBusiness,
		|	SupplierContract.BusinessOperation	AS BusinessOperation,
		|	SupplierContract.ContractWithSelfEmployedPerson		AS OperationWithSelfEmployedPerson
		|FROM
		|	Catalog.CounterpartyContracts AS SupplierContract
		|WHERE
		|	SupplierContract.Ref = &ContractWithCounterparty
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS Count,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance AS NumberOfPackages
		|INTO ResultTable1
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &ContractWithCounterparty
		|	AND CASE
		|		WHEN &WarehouseSpecified
		|			THEN Warehouse = &WarehouseForReceipt
		|		ELSE TRUE
		|	END) AS GoodsReadyForReceiptBalance
		|WHERE
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance AS Count,
		|	-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance AS NumberOfPackages
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &ContractWithCounterparty
		|	AND Warehouse = &WarehouseForReceipt) AS GoodsReadyForReceiptBalance
		|WHERE
		|	&WarehouseSpecified
		|	AND NOT (CAST(&WarehouseForReceipt AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsReceipt
		|	AND &DocumentDate >= CAST(&WarehouseForReceipt AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsReceipt)
		|	AND GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance < 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance,
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &ContractWithCounterparty
		|	AND (Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|	OR Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))) AS
		|		GoodsReadyForReceiptBalance
		|WHERE
		|	GoodsReadyForReceiptBalance.ToRegisterGoodsReceiptsBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsReadyForReceiptBalance.Warehouse,
		|	GoodsReadyForReceiptBalance.DocumentInflow,
		|	GoodsReadyForReceiptBalance.Products,
		|	GoodsReadyForReceiptBalance.Characteristic,
		|	GoodsReadyForReceiptBalance.Purpose,
		|	GoodsReadyForReceiptBalance.Series,
		|	-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance,
		|	-GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance
		|FROM
		|	AccumulationRegister.GoodsToReceive.Balance(, DocumentInflow = &ContractWithCounterparty
		|	AND (Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|	OR Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5))) AS
		|		GoodsReadyForReceiptBalance
		|WHERE
		|	GoodsReadyForReceiptBalance.ToRegisterReceiptsByInvoicesBalance < 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ResultTable1.Warehouse AS Warehouse,
		|	ResultTable1.DocumentInflow AS DocumentInflow,
		|	ResultTable1.Products AS Products,
		|	ResultTable1.Characteristic AS Characteristic,
		|	ResultTable1.Purpose AS Purpose,
		|	ResultTable1.Series AS Series,
		|	ResultTable1.Count AS Count,
		|	ResultTable1.NumberOfPackages AS NumberOfPackages
		|FROM
		|	ResultTable1 AS ResultTable1
		|
		|ORDER BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	DocumentInflow";
		
	Query.SetParameter("ContractWithCounterparty", ContractWithCounterparty);
	Query.SetParameter("WarehouseForReceipt", WarehouseForReceipt);
	Query.SetParameter("WarehouseSpecified", ValueIsFilled(WarehouseForReceipt));
	Query.SetParameter("DocumentDate", CurrentSessionDate());
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.CounterpartyContractStatuses.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Contract,
		Selection.DocumentStatus,,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	Goods.Load(QueryResult[QueryResult.UBound()].Unload());
	FillInTermsOfPurchaseUnderAgreement();
	
	ARAPCurrency = Selection.ARAPCurrency;
	
EndProcedure

Function DocumentBaseWhenFillingIn(FillingData)
	
	If TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.PurchaseOrder")
			Or TypeOf(FillingData.DocumentBasis) = Type("CatalogRef.TermsOfPurchaseFromVendors")) Then
		
		Return FillingData.DocumentBasis;
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DocumentBasis")
		And TypeOf(FillingData.DocumentBasis) = Type("Array") Then
		
		Return FillingData.DocumentBasis[0];
		
	ElsIf TypeOf(FillingData) = Type("Structure")
		And FillingData.Property("DiscrepancyCertificate") 
		And FillingData.Property("BasisOfAct")
		And (TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReturnOfGoodsToVendor") 
			Or TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.VendorInvoice")) Then
		
		Return FillingData.BasisOfAct;
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef.PurchaseOrder")
		Or TypeOf(FillingData) = Type("DocumentRef.ReturnOfGoodsToVendor")
		Or TypeOf(FillingData) = Type("CatalogRef.TermsOfPurchaseFromVendors") Then
		
		Return FillingData;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure FillInDocumentBasedOnReceiptOfServicesToUnit(Val DocumentBasis)
	
	If TypeOf(DocumentBasis) = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
		DetailsOfFoundation = Common.ObjectAttributesValues(DocumentBasis, "ReferenceOrder, Contract");
		OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(DetailsOfFoundation.Contract, "OptionForRegisteringServiceReceiptDocuments");	
		FillingOutCostAnalytics = (OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed);
		
		Query = New Query;
		Query.SetParameter("FillingOutCostAnalytics", FillingOutCostAnalytics);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		If TypeOf(DetailsOfFoundation.ReferenceOrder) = Type("DocumentRef.PurchaseOrder") Then
			Query.SetParameter("AnArrayOfOrders", DetailsOfFoundation.ReferenceOrder);
			Query.Text = 
			"SELECT
			|	PurchaseOrder.Ref AS Ref,
			|	PurchaseOrder.SalesOpportunity AS SalesOpportunity,
			|	PurchaseOrder.Terms.RegisterVendorPrices AS RegisterVendorPrices,
			|	PurchaseOrder.Ref AS PurchaseOrder,
			|	PurchaseOrder.Partner AS Partner,
			|	PurchaseOrder.Counterparty AS Counterparty,
			|	PurchaseOrder.Contract AS Contract,
			|	PurchaseOrder.ServiceReceiptOption AS ServiceReceiptOption,
			|	PurchaseOrder.Contract.OptionForRegisteringServiceReceiptDocuments AS OptionForRegisteringServiceReceiptDocuments,
			|	PurchaseOrder.Contract.PurchaseRegistrationOption AS PurchaseRegistrationOption,
			|	PurchaseOrder.Organization AS Organization,
			|	PurchaseOrder.Terms AS Terms,
			|	PurchaseOrder.Currency AS Currency,
			|	PurchaseOrder.Currency AS ARAPCurrency,
			|	CASE
			|		WHEN PurchaseOrder.Warehouse.IsFolder
			|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
			|			THEN VALUE(Catalog.Warehouses.EmptyRef)
			|		ELSE PurchaseOrder.Warehouse
			|	END AS Warehouse,
			|	CASE
			|		WHEN PurchaseOrder.Warehouse.IsFolder
			|				AND PurchaseOrder.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS ItIsForbiddenToSelectWarehouseGroup,
			|	PurchaseOrder.PaymentMethod AS PaymentMethod,
			|	PurchaseOrder.PriceIncludesVAT AS PriceIncludesVAT,
			|	PurchaseOrder.VATTaxation AS VATTaxation,
			|	PurchaseOrder.PurchaseForActivity AS PurchaseForActivity,
			|	PurchaseOrder.BusinessOperation AS BusinessOperation,
			|	PurchaseOrder.Status AS DocumentStatus,
			|	PurchaseOrder.Department AS Department,
			|	PurchaseOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
			|	PurchaseOrder.ToReturnReusablePackage AS ToReturnReusablePackage,
			|	PurchaseOrder.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
			|	PurchaseOrder.PackageDepositIsRequired AS PackageDepositIsRequired,
			|	ISNULL(PurchaseOrder.Terms.CalculatePackageReturnDateAccordingToCalendar, FALSE) AS CalculatePackageReturnDateAccordingToCalendar,
			|	ISNULL(PurchaseOrder.Terms.ScheduleOfPackageReturn, VALUE(Catalog.BusinessCalendars.EmptyRef)) AS ScheduleOfPackageReturn,
			|	NOT PurchaseOrder.Posted AS ThereAreErrorsPosted,
			|	CASE
			|		WHEN PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
			|				OR PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Closed)
			|			THEN FALSE
			|		ELSE TRUE
			|	END AS ThereAreErrorsStatus,
			|	PurchaseOrder.BankAccount AS CompanyBankAccount,
			|	PurchaseOrder.ARAPObjectSettings AS ARAPObjectSettings,
			|	PurchaseOrder.LineOfBusiness AS LineOfBusiness,
			|	PurchaseOrder.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
			|	PurchaseOrder.RegisterVendorPrices AS RegisterVendorPrices1,
			|	PurchaseOrder.OperationWithSelfEmployedPerson AS OperationWithSelfEmployedPerson
			|FROM
			|	Document.PurchaseOrder AS PurchaseOrder
			|WHERE
			|	PurchaseOrder.Ref IN(&AnArrayOfOrders)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED
			|	OrdersTable.PurchaseOrder AS PurchaseOrder,
			|	OrdersTable.Products AS Products,
			|	OrdersTable.Characteristic AS Characteristic,
			|	OrdersTable.RowCode AS RowCode,
			|	OrdersTable.Warehouse AS Warehouse,
			|	SUM(OrdersTable.ToRegister) AS Count
			|INTO TableBalance
			|FROM
			|	(SELECT
			|		OrdersBalance.PurchaseOrder AS PurchaseOrder,
			|		OrdersBalance.Products AS Products,
			|		OrdersBalance.Characteristic AS Characteristic,
			|		OrdersBalance.RowCode AS RowCode,
			|		OrdersBalance.Warehouse AS Warehouse,
			|		OrdersBalance.ToRegisterBalance AS ToRegister
			|	FROM
			|		AccumulationRegister.PurchaseOrders.Balance(
			|				,
			|				PurchaseOrder IN (&AnArrayOfOrders)
			|					AND Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
			|					AND Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))) AS OrdersBalance) AS OrdersTable
			|
			|GROUP BY
			|	OrdersTable.PurchaseOrder,
			|	OrdersTable.Products,
			|	OrdersTable.Characteristic,
			|	OrdersTable.RowCode,
			|	OrdersTable.Warehouse
			|
			|HAVING
			|	SUM(OrdersTable.ToRegister) > 0
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(TableBalance.PurchaseOrder, CAST(ReceiptOfServicesToBusinessUnitServices.Ref.ReferenceOrder AS Document.PurchaseOrder)) AS PurchaseOrder,
			|	ISNULL(OrderingProducts.Ref.ARAPObjectSettings, VALUE(Enum.ARAPObjectSettings.EmptyRef)) AS ARAPObjectSettings,
			|	ReceiptOfServicesToBusinessUnitServices.Products AS Products,
			|	ReceiptOfServicesToBusinessUnitServices.Characteristic AS Characteristic,
			|	ISNULL(TableBalance.RowCode, 0) AS RowCode,
			|	ReceiptOfServicesToBusinessUnitServices.Count AS Count,
			|	ISNULL(TableBalance.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)) AS Warehouse,
			|	ISNULL(OrderingProducts.Count, 0) AS QuantityInOrder,
			|	ISNULL(OrderingProducts.LineNumber, 0) AS LineNumber,
			|	ISNULL(OrderingProducts.Ref.SalesOpportunity, VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)) AS SalesOpportunity,
			|	CASE
			|		WHEN &FillingOutCostAnalytics
			|			THEN OrderingProducts.ExpenseItem
			|		ELSE UNDEFINED
			|	END AS ExpenseItem,
			|	CASE
			|		WHEN &FillingOutCostAnalytics
			|			THEN OrderingProducts.DimensionOfExpenses
			|		ELSE UNDEFINED
			|	END AS DimensionOfExpenses,
			|	CASE
			|		WHEN &FillingOutCostAnalytics
			|			THEN OrderingProducts.Department
			|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
			|	END AS Department,
			|	CASE
			|		WHEN &FillingOutCostAnalytics
			|			THEN OrderingProducts.ToExpenseAs
			|		ELSE FALSE
			|	END AS ToExpenseAs,
			|	OrderingProducts.DateOfReceipt AS DateOfReceipt,
			|	ISNULL(OrderingProducts.Package, ReceiptOfServicesToBusinessUnitServices.Package) AS Package,
			|	ISNULL(OrderingProducts.VendorPriceKind, VALUE(Catalog.VendorPriceTypes.EmptyRef)) AS VendorPriceKind,
			|	ISNULL(OrderingProducts.Count, 0) AS QuantityByOrder,
			|	ReceiptOfServicesToBusinessUnitServices.Price AS Price,
			|	ReceiptOfServicesToBusinessUnitServices.VATRate AS VATRate,
			|	ReceiptOfServicesToBusinessUnitServices.Sum AS Sum,
			|	ReceiptOfServicesToBusinessUnitServices.VATAmount AS VATAmount,
			|	ReceiptOfServicesToBusinessUnitServices.AmountIncludingVAT AS AmountIncludingVAT,
			|	ISNULL(OrderingProducts.PercentRateOfManualDiscount, 0) AS PercentRateOfManualDiscount,
			|	ISNULL(OrderingProducts.ManualDiscount, 0) AS ManualDiscount,
			|	ReceiptOfServicesToBusinessUnitServices.Products.ItemsType AS ItemsType,
			|	ISNULL(OrderingProducts.PartnerProducts, VALUE(Catalog.ProductCrossReferences.EmptyRef)) AS PartnerProducts,
			|	ReceiptOfServicesToBusinessUnitServices.Purpose AS Purpose,
			|	1 AS ZoomRatio,
			|	ReceiptOfServicesToBusinessUnitServices.Count AS NumberOfPackages,
			|	FALSE AS AdvancedWarehousingOnShipment
			|FROM
			|	Document.ReceiptOfServicesToBusinessUnit.Services AS ReceiptOfServicesToBusinessUnitServices
			|		LEFT JOIN TableBalance AS TableBalance
			|			INNER JOIN Document.PurchaseOrder.Goods AS OrderingProducts
			|			ON TableBalance.Products = OrderingProducts.Products
			|				AND TableBalance.Characteristic = OrderingProducts.Characteristic
			|				AND TableBalance.RowCode = OrderingProducts.RowCode
			|				AND TableBalance.PurchaseOrder = OrderingProducts.Ref
			|		ON (ReceiptOfServicesToBusinessUnitServices.Products = OrderingProducts.Products)
			|			AND (OrderingProducts.Characteristic = ReceiptOfServicesToBusinessUnitServices.Characteristic)
			|			AND (ReceiptOfServicesToBusinessUnitServices.Purpose = OrderingProducts.Purpose)
			|			AND (OrderingProducts.ExpenseItem = ReceiptOfServicesToBusinessUnitServices.ExpenseItem)
			|			AND (ReceiptOfServicesToBusinessUnitServices.DimensionOfExpenses = OrderingProducts.DimensionOfExpenses)
			|WHERE
			|	ReceiptOfServicesToBusinessUnitServices.Ref = &DocumentBasis";
		Else
			Query.Text = 
			"SELECT
			|	ReceiptOfServicesToBusinessUnit.Ref AS Ref,
			|	ReceiptOfServicesToBusinessUnit.ReferenceOrder AS ReferenceOrder,
			|	FALSE AS ReceiptUnderOrders,
			|	ReceiptOfServicesToBusinessUnit.ReferenceOrder AS PurchaseOrder,
			|	ReceiptOfServicesToBusinessUnit.SalesOpportunity AS SalesOpportunity,
			|	ReceiptOfServicesToBusinessUnit.Partner AS Partner,
			|	ReceiptOfServicesToBusinessUnit.Counterparty AS Counterparty,
			|	ReceiptOfServicesToBusinessUnit.Contract AS Contract,
			|	ReceiptOfServicesToBusinessUnit.ServiceReceiptOption AS ServiceReceiptOption,
			|	ReceiptOfServicesToBusinessUnit.Contract.OptionForRegisteringServiceReceiptDocuments AS OptionForRegisteringServiceReceiptDocuments,
			|	ReceiptOfServicesToBusinessUnit.Organization AS Organization,
			|	ReceiptOfServicesToBusinessUnit.Terms AS Terms,
			|	ReceiptOfServicesToBusinessUnit.Currency AS Currency,
			|	ReceiptOfServicesToBusinessUnit.Currency AS ARAPCurrency,
			|	ReceiptOfServicesToBusinessUnit.PriceIncludesVAT AS PriceIncludesVAT,
			|	ReceiptOfServicesToBusinessUnit.VATTaxation AS VATTaxation,
			|	ReceiptOfServicesToBusinessUnit.Department AS Department,
			|	ReceiptOfServicesToBusinessUnit.LineOfBusiness AS LineOfBusiness,
			|	ReceiptOfServicesToBusinessUnit.RegisterVendorPrices AS RegisterVendorPrices,
			|	ReceiptOfServicesToBusinessUnit.IncomingDocumentNumber AS IncomingDocumentNumber,
			|	ReceiptOfServicesToBusinessUnit.IncomingDocumentDate AS IncomingDocumentDate,
			|	ReceiptOfServicesToBusinessUnit.ExternalDocumentName AS ExternalDocumentName,
			|	VALUE(Enum.BusinessTransactions.PurchaseFromSupplier) AS BusinessOperation,
			|	NOT ReceiptOfServicesToBusinessUnit.Posted AS ThereAreErrorsPosted
			|FROM
			|	Document.ReceiptOfServicesToBusinessUnit AS ReceiptOfServicesToBusinessUnit
			|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
			|		ON ReceiptOfServicesToBusinessUnit.Contract = CounterpartyContracts.Ref
			|WHERE
			|	ReceiptOfServicesToBusinessUnit.Ref = &DocumentBasis
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ReceiptOfServicesToBusinessUnit.Ref AS Ref,
			|	ReceiptOfServicesToBusinessUnit.LineNumber AS LineNumber,
			|	ReceiptOfServicesToBusinessUnit.Products AS Products,
			|	ReceiptOfServicesToBusinessUnit.PartnerProducts AS PartnerProducts,
			|	ReceiptOfServicesToBusinessUnit.Characteristic AS Characteristic,
			|	ReceiptOfServicesToBusinessUnit.Count AS Count,
			|	ReceiptOfServicesToBusinessUnit.Count AS NumberOfPackages,
			|	ReceiptOfServicesToBusinessUnit.Price AS Price,
			|	ReceiptOfServicesToBusinessUnit.Sum AS Sum,
			|	ReceiptOfServicesToBusinessUnit.VATRate AS VATRate,
			|	ReceiptOfServicesToBusinessUnit.VATAmount AS VATAmount,
			|	ReceiptOfServicesToBusinessUnit.AmountIncludingVAT AS AmountIncludingVAT,
			|	ReceiptOfServicesToBusinessUnit.Purpose AS Purpose,
			|	ReceiptOfServicesToBusinessUnit.Department AS Department,
 			|	CASE
			|		WHEN &FillingOutCostAnalytics 
			|			THEN  ReceiptOfServicesToBusinessUnit.ToExpenseAs
			|		ELSE FALSE
			|	END AS ToExpenseAs,
			|	ReceiptOfServicesToBusinessUnit.ExpenseItem AS ExpenseItem,
			|	ReceiptOfServicesToBusinessUnit.DimensionOfExpenses AS DimensionOfExpenses,
			|	ReceiptOfServicesToBusinessUnit.LotVendorAttributes AS LotVendorAttributes,
			|	ReceiptOfServicesToBusinessUnit.ItemsLocationAttributes AS ItemsLocationAttributes,
			|	ReceiptOfServicesToBusinessUnit.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
			|	ReceiptOfServicesToBusinessUnit.RowID AS RowID,
			|	ReceiptOfServicesToBusinessUnit.Ref.ReferenceOrder AS PurchaseOrder,
			|	ReceiptOfServicesToBusinessUnit.Package AS Package
			|FROM
			|	Document.ReceiptOfServicesToBusinessUnit.Services AS ReceiptOfServicesToBusinessUnit
			|WHERE
			|	ReceiptOfServicesToBusinessUnit.Ref = &DocumentBasis";
		EndIf;
		
		QueryResult = Query.ExecuteBatch();		
		HeaderAttributes = QueryResult[0].Select();
		HeaderAttributes.Next(); 
		
		CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
		CheckParameters.ThereAreErrorsPosted = HeaderAttributes.ThereAreErrorsPosted;
		TMCommonUse.CheckPossibilityOfInputBasedOnParameters(HeaderAttributes.Ref, CheckParameters);
		
		FillPropertyValues(ThisObject, HeaderAttributes);
		
		If Not TypeOf(DetailsOfFoundation.ReferenceOrder) = Type("CatalogRef.CounterpartyContracts") Then
			ReceiptUnderOrders = True;
		EndIf;
		
		If TypeOf(DetailsOfFoundation.ReferenceOrder) = Type("DocumentRef.PurchaseOrder") Then 
			ServiceAttributes = QueryResult[2].Select(); 
		Else
			ServiceAttributes = QueryResult[1].Select(); 
		EndIf;
		
		While ServiceAttributes.Next() Do
			FillPropertyValues(Goods.Add(), ServiceAttributes); 
		EndDo;
		
		UseLinesOfBusiness = GetFunctionalOption("UseCostAccountingByLinesOfBusiness");
		If UseLinesOfBusiness And Not (ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders) Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
			PurchaseConditions = PurchasesServer.GetPurchaseTermsAndConditions(Terms);
			FillInPaymentTerms_(PurchaseConditions);
		EndIf;
		
		EconomicOperationOfFoundation = Common.ObjectAttributeValue(DocumentBasis, "BusinessOperation");
		
		If OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
			If EconomicOperationOfFoundation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU;
			ElsIf EconomicOperationOfFoundation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
			EndIf;
		ElsIf OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced Then
			If EconomicOperationOfFoundation = Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
			ElsIf EconomicOperationOfFoundation = Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery Then
				BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
			EndIf;
		EndIf;
	EndIf;
	
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

Procedure CheckChangesInBusinessOperations(Cancel)
	
	If Not IsNew()
	 And (BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
	 Or BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder) Then
	
		Query = New Query("
		|SELECT
		|	VendorsARAPAccounting.SumReceipt AS PayAmount
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting.Turnovers(,,Period,
		|		ARAPObject.Object = &Object
		|	) AS VendorsARAPAccounting
		|
		|	INNER JOIN
		|		Document.VendorInvoice AS DocumentData
		|	ON
		|		DocumentData.Ref = &Ref
		|		AND DocumentData.BusinessOperation <> &BusinessOperation
		|WHERE
		|	VendorsARAPAccounting.SumReceipt > 0
		|");
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("Object", ?(ValueIsFilled(PurchaseOrder), PurchaseOrder, Ref));
		Query.SetParameter("BusinessOperation", BusinessOperation);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã thanh toán hàng hóa tiếp nhận. Không nên đặt giao dịch %1';
					|ru = 'Поступление оплачено. Нельзя устанавливать операцию %1';
					|en = 'Receipt is paid. Cannot set transaction %1'; fa = 'Receipt is paid. Cannot set transaction %1';
					|it = 'L''arrivo è stato pagato. Impossibile impostare operazione %1';
					|pl = 'Wpływ jest oplacony. Nie można ustawić operacji %1';
					|tr = 'Makbuz ödendi. %1böyle bir işlem gerçekleştirilemez'"),
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

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	UseSeparateProcurement = PurchasesServer.ThisIsEconomicOperationOfSeparatePurchase(BusinessOperation);
	
	TempTablesManager = TemporaryDocumentDataTables(UseSeparateProcurement);
	
	If Not UseSeparateProcurement Then
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Goods);
	Else
		InventoriesServer.FillStockTypesByDefault(TempTablesManager, Undefined);
		FillInInventoryOwnerAttributeOfWorksBeingTracked();
	EndIf;
	
	RefillInventoryKinds = Not Posted
								Or InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject)
								Or CheckChangesToDocumentDetails(TempTablesManager)
								Or CheckProductChanges_(TempTablesManager);
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
		And RefillInventoryKinds Then
		
		FillParameters = ParametersForFillingInventoryTypes(UseSeparateProcurement);
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber", "Count, QuantityByGBRN");
		FillInInventoryViewRegistration();
		FillInAdditionalStockTypes();
		
	ElsIf UseSeparateProcurement
		And RefillInventoryKinds Then
		
		ThisIsNonfacturing = BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt;
		
		If Not ThisIsNonfacturing Then
			AdditionalProperties.Insert("MonitorCCDNumbers", False); // we allow you to write off balances on empty GTD numbers
		EndIf;
		
		TempTablesManager = TemporaryDocumentDataTables(UseSeparateProcurement, False);

		FillParameters = ParametersForFillingInventoryTypes(UseSeparateProcurement);
		InventoriesServer.FillOutTypesOfStocksOnBalancesForRegistration(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
		
		If ThisIsNonfacturing Then
			FillInByAnalystsTakingIntoAccountSeries();
		EndIf;
		
		FillInAdditionalStockTypes(ThisIsNonfacturing);
		
	ElsIf Not UseSeparateProcurement
		And BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		
		InventoryKinds.Clear();
		
	EndIf;
	
EndProcedure

Function GetFinalBalances()
	
	QueryText = "
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN Goods.BatchesIndicationStatus = 18
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS BatchSelectionIsRequired,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.PurchaseOrder AS PurchaseOrder
	|INTO TTGoodsOriginalWarehouse
	|FROM
	|	&Goods AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose AS Purpose,
	|	Goods.Series AS Series,
	|	Goods.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|	Goods.PurchaseOrder AS PurchaseOrder	
	|INTO TTGoodsWithoutWarehouses
	|FROM
	|	TTGoodsOriginalWarehouse AS Goods
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber
	|INTO TTInitialStockInventoryOwnerAttributes
	|FROM
	|	&InventoryKinds AS InventoryKinds
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Purpose AS Purpose,
	|	CASE
	|		WHEN Goods.Products IS NULL
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE Goods.Series
	|	END AS Series,
	|	DimensionKeys.StorageLocation AS StorageLocation,
	|	DimensionKeys.ProductCostElement AS ProductCostElement,
	|	CASE
	|		WHEN Goods.Products IS NULL
	|			THEN FALSE
	|		ELSE Goods.BatchSelectionIsRequired
	|	END AS BatchSelectionIsRequired,
	|	InventoryKinds.CCDNumber AS CCDNumber
	|
	|INTO TTTypesOfStocks
	|FROM
	|	TTInitialStockInventoryOwnerAttributes AS InventoryKinds
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON InventoryKinds.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN TTGoodsWithoutWarehouses AS Goods
	|		ON (DimensionKeys.Products = Goods.Products)
	|			AND (DimensionKeys.Characteristic = Goods.Characteristic)
	|			AND (DimensionKeys.Purpose = Goods.Purpose)
	|			AND (NOT Goods.BatchSelectionIsRequired
	|				OR Goods.BatchSelectionIsRequired
	|					AND DimensionKeys.Series = Goods.Series)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	StorageLocation,
	|	ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	InventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.DimensionKey AS DimensionKey,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|	CASE
	|		WHEN InventoryKinds.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsCCD
	|INTO TTAnalyst
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON InventoryKinds.Products = Dimension.Products
	|			AND InventoryKinds.Characteristic = Dimension.Characteristic
	|			AND InventoryKinds.StorageLocation = Dimension.StorageLocation
	|			AND InventoryKinds.Purpose = Dimension.Purpose
	|			AND InventoryKinds.ProductCostElement = Dimension.ProductCostElement
	|
	|INDEX BY
	|	DimensionKey,
	|	InventoryOwnerAttribute
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsOriginalWarehouse.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Dimension.DimensionKey AS DimensionKey,
	|	GoodsOriginalWarehouse.Warehouse AS Warehouse,
	|	GoodsOriginalWarehouse.CCDNumber AS CCDNumber,
	|	CASE
	|		WHEN &GoodsReceiptOption IN(
	|			VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
	|			VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
	|		// only for one-way traffic, in two-way traffic the order does not make a Receipt
	|			VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
	|		THEN &Terms
	|		WHEN &GoodsReceiptOption IN(
	|			VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
	|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
	|		// only for one-way traffic, in two-way traffic the order does not make a Receipt
	|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
	|		THEN &Contract
	|		WHEN &GoodsReceiptOption IN(
	|			VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices),
	|		// only for one-way traffic, in two-way traffic the order does not make a Receipt. A feature, since the RegisterRecorded makes an order, the receipt document cannot be a bill of lading.
	|			VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly),
	|		// in some documents, the Product Acceptance option field is not filled in
	|			VALUE(Enum.GoodsReceiptOptions.EmptyRef),
	|		// in some documents, there is no option field for accepting products
	|			UNDEFINED)
	|		THEN GoodsOriginalWarehouse.PurchaseOrder
	|	END AS DocumentInflow,
	|	CASE
	|		WHEN GoodsOriginalWarehouse.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThereIsCCD
	|INTO TTSelectionAnalystWarehouse
	|FROM
	|	TTGoodsOriginalWarehouse AS GoodsOriginalWarehouse
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsOriginalWarehouse.Products = Dimension.Products
	|			AND GoodsOriginalWarehouse.Characteristic = Dimension.Characteristic
	|			AND GoodsOriginalWarehouse.Warehouse = Dimension.StorageLocation
	|			AND GoodsOriginalWarehouse.Purpose = Dimension.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTAnalyst.DimensionKey AS DimensionKey,
	|	TTSelectionAnalystWarehouse.DimensionKey AS WarehouseAnalyticsKey,
	|	TTAnalyst.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTSelectionAnalystWarehouse.Warehouse AS Warehouse,
	|	TTAnalyst.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|	TTSelectionAnalystWarehouse.DocumentInflow AS DocumentInflow
	|INTO TTSelectionIsGeneralAnalyst
	|FROM
	|	TTAnalyst AS TTAnalyst
	|		INNER JOIN TTSelectionAnalystWarehouse AS TTSelectionAnalystWarehouse
	|		ON TTAnalyst.ItemsLocationAttributes = TTSelectionAnalystWarehouse.ItemsLocationAttributes
	|			AND TTAnalyst.DimensionKey.Products = TTSelectionAnalystWarehouse.DimensionKey.Products
	|			AND TTAnalyst.DimensionKey.Purpose = TTSelectionAnalystWarehouse.DimensionKey.Purpose
	|			AND TTAnalyst.DimensionKey.Characteristic = TTSelectionAnalystWarehouse.DimensionKey.Characteristic
	|			AND TTAnalyst.DimensionKey.Series = TTSelectionAnalystWarehouse.DimensionKey.Series
	|			AND TTAnalyst.DimensionKey.ProductCostElement = TTSelectionAnalystWarehouse.DimensionKey.ProductCostElement
	|			AND TTAnalyst.CCDNumber = TTSelectionAnalystWarehouse.CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MAX(-Balance.CountBalance) AS Count
	|INTO DataOnBalancesTT
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&DocumentDate,
	|			Organization = &Organization
	|				AND (ItemsLocationAttributes, InventoryOwnerAttribute) IN
	|					(SELECT
	|						FilterTable.DimensionKey,
	|						FilterTable.InventoryOwnerAttribute
	|					FROM
	|						TTAnalyst AS FilterTable)) AS Balance
	|
	|GROUP BY
	|	Balance.ItemsLocationAttributes
	|
	|HAVING
	|	MAX(Balance.CountBalance) < 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Balance.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	MAX(Balance.CountBalance) AS Count
	|INTO TTWarehouseBalanceData
	|FROM
	|	AccumulationRegister.CompanyGoods.Balance(
	|			&DocumentDate,
	|			Organization = &Organization
	|				AND ItemsLocationAttributes IN
	|					(SELECT
	|						FilterTable.DimensionKey
	|					FROM
	|						TTSelectionAnalystWarehouse AS FilterTable)) AS Balance
	|
	|GROUP BY
	|	Balance.ItemsLocationAttributes
	|
	|HAVING
	|	MAX(Balance.CountBalance) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionOfAnalystIsGeneral.DimensionKey AS DimensionKey,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Purpose AS Purpose,
	|	DimensionKeys.Series AS Series,
	|	SelectionOfAnalystIsGeneral.WarehouseAnalyticsKey.StorageLocation AS Warehouse,
	|	CASE
	|		WHEN MIN(BalanceData.Count) > MIN(WarehouseBalanceData.Count)
	|			THEN MIN(WarehouseBalanceData.Count)
	|		ELSE MIN(BalanceData.Count)
	|	END AS Count,
	|	MIN(CASE
	|			WHEN NOT InventoryKinds.BatchSelectionIsRequired
	|					OR InventoryKinds.BatchSelectionIsRequired
	|						AND DimensionKeys.Series = InventoryKinds.Series
	|				THEN 2
	|			ELSE 3
	|		END) AS Priority,
	|	MAX(CASE
	|			WHEN InventoryKinds.BatchSelectionIsRequired
	|					AND DimensionKeys.Series = InventoryKinds.Series
	|				THEN TRUE
	|			ELSE FALSE
	|		END) AS BatchSelectionIsRequired,
	|		SelectionOfAnalystIsGeneral.DocumentInflow AS DocumentInflow
	|INTO TTBalancesGoodsOfOrganizationsTotal
	|FROM
	|	TTSelectionIsGeneralAnalyst AS SelectionOfAnalystIsGeneral
	|
	|		INNER JOIN DataOnBalancesTT AS BalanceData
	|		ON SelectionOfAnalystIsGeneral.DimensionKey = BalanceData.ItemsLocationAttributes
	|
	|		INNER JOIN TTWarehouseBalanceData AS WarehouseBalanceData
	|		ON SelectionOfAnalystIsGeneral.WarehouseAnalyticsKey = WarehouseBalanceData.ItemsLocationAttributes 
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON SelectionOfAnalystIsGeneral.DimensionKey = DimensionKeys.Ref
	|
	|		INNER JOIN TTTypesOfStocks AS InventoryKinds
	|		ON DimensionKeys.Products = InventoryKinds.Products
	|			AND DimensionKeys.Characteristic = InventoryKinds.Characteristic
	|			AND DimensionKeys.StorageLocation = InventoryKinds.StorageLocation
	|			AND DimensionKeys.Purpose = InventoryKinds.Purpose
	|			AND DimensionKeys.ProductCostElement = InventoryKinds.ProductCostElement
	|
	|GROUP BY
	|	SelectionOfAnalystIsGeneral.DimensionKey,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	SelectionOfAnalystIsGeneral.WarehouseAnalyticsKey.StorageLocation,
	|	SelectionOfAnalystIsGeneral.DocumentInflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
	|	GoodsToReceiveBalance.Products AS Products,
	|	GoodsToReceiveBalance.Characteristic AS Characteristic,
	|	GoodsToReceiveBalance.Purpose AS Purpose,
	|	GoodsToReceiveBalance.Warehouse AS Warehouse,
	|	GoodsToReceiveBalance.Series AS Series,
	|	MAX(-GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesBalance) AS Count
	|INTO TTBalanceOfReceipts
	|FROM
	|	AccumulationRegister.GoodsToReceive.Balance(
	|			,
	|			(DocumentInflow, Products, Characteristic, Purpose, Warehouse) IN
	|				(SELECT
	|					BalancesOfOrganizationsGoodsTotal.DocumentInflow,
	|					BalancesOfOrganizationsGoodsTotal.Products,
	|					BalancesOfOrganizationsGoodsTotal.Characteristic,
	|					BalancesOfOrganizationsGoodsTotal.Purpose,
	|					BalancesOfOrganizationsGoodsTotal.Warehouse
	|				FROM
	|					TTBalancesGoodsOfOrganizationsTotal AS BalancesOfOrganizationsGoodsTotal)) AS GoodsToReceiveBalance
	|
	|GROUP BY
	|	GoodsToReceiveBalance.DocumentInflow,
	|	GoodsToReceiveBalance.Products,
	|	GoodsToReceiveBalance.Characteristic,
	|	GoodsToReceiveBalance.Purpose,
	|	GoodsToReceiveBalance.Warehouse,
	|	GoodsToReceiveBalance.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SelectionOfAnalystIsGeneral.DimensionKey AS ItemsLocationAttributes,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Purpose AS Purpose,
	|	DimensionKeys.Series AS Series,
	|	DimensionKeys.StorageLocation AS StorageLocation,
	|	SelectionOfAnalystIsGeneral.Warehouse AS Warehouse,
	|	DimensionKeys.ProductCostElement AS ProductCostElement,
	|	RegisterRecords.CCDNumber,
	|	MAX(RegisterRecords.Count) AS Count
	|INTO TTDocumentRegisterRecords
	|FROM
	|	AccumulationRegister.CompanyGoods AS RegisterRecords
	|	INNER JOIN TTSelectionIsGeneralAnalyst AS SelectionOfAnalystIsGeneral
	|		ON RegisterRecords.ItemsLocationAttributes = SelectionOfAnalystIsGeneral.WarehouseAnalyticsKey
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON SelectionOfAnalystIsGeneral.DimensionKey = DimensionKeys.Ref
	|WHERE
	|	RegisterRecords.Recorder = &Ref
	|	AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND (RegisterRecords.ItemsLocationAttributes, CCDNumber) IN
	|			(SELECT
	|				FilterTable.DimensionKey, CCDNumber
	|			FROM
	|				TTSelectionAnalystWarehouse AS FilterTable
	|			WHERE FilterTable.ThereIsCCD)
	|
	|GROUP BY
	|	SelectionOfAnalystIsGeneral.DimensionKey,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	DimensionKeys.StorageLocation,
	|	DimensionKeys.ProductCostElement,
	|	RegisterRecords.CCDNumber,
	|	SelectionOfAnalystIsGeneral.Warehouse
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionKeys.Ref AS ItemsLocationAttributes,
	|	DimensionKeys.Products AS Products,
	|	DimensionKeys.Characteristic AS Characteristic,
	|	DimensionKeys.Purpose AS Purpose,
	|	DimensionKeys.Series AS Series,
	|	DimensionKeys.StorageLocation AS StorageLocation,
	|	UNDEFINED AS Warehouse,
	|	DimensionKeys.ProductCostElement AS ProductCostElement,
	|	RegisterRecords.CCDNumber,
	|	SUM(RegisterRecords.Count) AS Count
	|FROM
	|	AccumulationRegister.CompanyGoods AS RegisterRecords
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON RegisterRecords.ItemsLocationAttributes = DimensionKeys.Ref
	|WHERE
	|	RegisterRecords.Recorder = &Ref
	|	AND RegisterRecords.RecordType = VALUE(AccumulationRecordType.Receipt)
	|	AND RegisterRecords.ItemsLocationAttributes IN
	|			(SELECT
	|				FilterTable.DimensionKey
	|			FROM
	|				TTAnalyst AS FilterTable
	|			WHERE
	|				NOT FilterTable.ThereIsCCD)
	|
	|GROUP BY
	|	RegisterRecords.ItemsLocationAttributes,
	|	DimensionKeys.Ref,
	|	DimensionKeys.Products,
	|	DimensionKeys.Characteristic,
	|	DimensionKeys.Purpose,
	|	DimensionKeys.Series,
	|	DimensionKeys.StorageLocation,
	|	RegisterRecords.CCDNumber,
	|	DimensionKeys.ProductCostElement
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	StorageLocation,
	|	ProductCostElement
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfOrganizationsGoodsTotal.DimensionKey AS DimensionKey,
	|	BalanceReceipts.Products AS Products,
	|	BalanceReceipts.Characteristic AS Characteristic,
	|	BalanceReceipts.Purpose AS Purpose,
	|	BalanceReceipts.Warehouse AS Warehouse,
	|	BalanceReceipts.Series AS Series,
	|	BalancesOfOrganizationsGoodsTotal.Priority AS Priority,
	|	BalancesOfOrganizationsGoodsTotal.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|	CASE
	|		WHEN BalanceReceipts.Count > BalancesOfOrganizationsGoodsTotal.Count
	|			THEN BalancesOfOrganizationsGoodsTotal.Count
	|		ELSE BalanceReceipts.Count
	|	END AS Count
	|INTO TTTotalBalance
	|FROM
	|	TTBalanceOfReceipts AS BalanceReceipts
	|		INNER JOIN TTBalancesGoodsOfOrganizationsTotal AS BalancesOfOrganizationsGoodsTotal
	|		ON (BalancesOfOrganizationsGoodsTotal.DocumentInflow = BalanceReceipts.DocumentInflow)
	|			AND (BalancesOfOrganizationsGoodsTotal.Products = BalanceReceipts.Products)
	|			AND (BalancesOfOrganizationsGoodsTotal.Characteristic = BalanceReceipts.Characteristic)
	|			AND (BalancesOfOrganizationsGoodsTotal.Purpose = BalanceReceipts.Purpose)
	|			AND (BalancesOfOrganizationsGoodsTotal.Warehouse = BalanceReceipts.Warehouse)
	|			AND (CASE
	|				WHEN BalancesOfOrganizationsGoodsTotal.BatchSelectionIsRequired
	|					THEN BalancesOfOrganizationsGoodsTotal.Series = BalanceReceipts.Series
	|			ELSE TRUE
	|			END)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Set.Products AS Products,
	|	Set.Characteristic AS Characteristic,
	|	Set.Purpose AS Purpose,
	|	Set.Series AS Series,
	|	SUM(Set.Count) AS Count,
	|	Set.Priority AS Priority,
	|	Set.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|	Set.Warehouse AS Warehouse,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber
	|FROM
	|	(SELECT
	|		Balance.DimensionKey AS ItemsLocationAttributes,
	|		Balance.Products AS Products,
	|		Balance.Characteristic AS Characteristic,
	|		Balance.Purpose AS Purpose,
	|		Balance.Series AS Series,
	|		Balance.Count AS Count,
	|		Balance.Priority AS Priority,
	|		Balance.BatchSelectionIsRequired AS BatchSelectionIsRequired,
	|		Balance.Warehouse AS Warehouse
	|	FROM
	|		TTTotalBalance AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		RegisterRecords.ItemsLocationAttributes,
	|		RegisterRecords.Products,
	|		RegisterRecords.Characteristic,
	|		RegisterRecords.Purpose,
	|		RegisterRecords.Series,
	|		MAX(RegisterRecords.Count),
	|		MIN(CASE
	|				WHEN NOT InventoryKinds.BatchSelectionIsRequired
	|						OR InventoryKinds.BatchSelectionIsRequired
	|							AND RegisterRecords.Series = InventoryKinds.Series
	|					THEN 0
	|				ELSE 1
	|			END),
	|		MAX(CASE
	|				WHEN InventoryKinds.BatchSelectionIsRequired
	|						AND RegisterRecords.Series = InventoryKinds.Series
	|					THEN TRUE
	|				ELSE FALSE
	|			END),
	|		RegisterRecords.Warehouse AS Warehouse
	|	FROM
	|		TTDocumentRegisterRecords AS RegisterRecords
	|			INNER JOIN TTTypesOfStocks AS InventoryKinds
	|			ON RegisterRecords.Products = InventoryKinds.Products
	|				AND RegisterRecords.Characteristic = InventoryKinds.Characteristic
	|				AND RegisterRecords.StorageLocation = InventoryKinds.StorageLocation
	|				AND RegisterRecords.Purpose = InventoryKinds.Purpose
	|				AND RegisterRecords.ProductCostElement = InventoryKinds.ProductCostElement
	|	
	|	GROUP BY
	|		RegisterRecords.ItemsLocationAttributes,
	|		RegisterRecords.Products,
	|		RegisterRecords.Characteristic,
	|		RegisterRecords.Purpose,
	|		RegisterRecords.Warehouse,
	|		RegisterRecords.Series) AS Set
	|
	|GROUP BY
	|	Set.ItemsLocationAttributes,
	|	Set.Products,
	|	Set.Characteristic,
	|	Set.Purpose,
	|	Set.Series,
	|	Set.Priority,
	|	Set.BatchSelectionIsRequired,
	|	Set.Warehouse
	|
	|ORDER BY
	|	Priority,
	|	ItemsLocationAttributes,
	|	Count DESC
	|";
	
	Return QueryText;
	
EndFunction

Procedure FillInByAnalystsTakingIntoAccountSeries()
	
	DescriptionGoods		= Metadata().TabularSections.Goods.Attributes;
	SearchKey			= "Products, Characteristic, Purpose, Series";
	SearchKeyWithoutSeries	= "Products, Characteristic, Purpose";
	
	TableTypesOfStocks_ = InventoryKinds.Unload();
	// Service fields for quantity distribution.
	TableTypesOfStocks_.Columns.Add("AnalysisOfProductAccountingByRegister",
										DescriptionGoods.ItemsLocationAttributes.Type);
	TableTypesOfStocks_.Columns.Add("Products",
										DescriptionGoods.Products.Type);
	TableTypesOfStocks_.Columns.Add("Characteristic",
										DescriptionGoods.Characteristic.Type);
	TableTypesOfStocks_.Columns.Add("Purpose",
										DescriptionGoods.Purpose.Type);
	TableTypesOfStocks_.Columns.Add("Series",
										DescriptionGoods.Series.Type);
	TableTypesOfStocks_.Columns.Add("NumberByCase",
										DescriptionGoods.Count.Type);
	// Service fields for recalculating amounts.
	TableTypesOfStocks_.Columns.Add("Sum",
										DescriptionGoods.Sum.Type);
	TableTypesOfStocks_.Columns.Add("NumberOfPackages",
										DescriptionGoods.NumberOfPackages.Type);
	// Service field for determining the filling error.
	TableTypesOfStocks_.Columns.Add("BatchIsSelectedCorrectly",
										New TypeDescription("Boolean"));
	
	TableTypesOfStocks_.Indexes.Add(SearchKey);
	TableTypesOfStocks_.Indexes.Add(SearchKeyWithoutSeries);
	
	NomenclatureAnalysts	= TableTypesOfStocks_.UnloadColumn("ItemsLocationAttributes");
	AnalystKeys			= Common.ObjectsAttributesValues(NomenclatureAnalysts, SearchKey);
	
	For Each InventoryLine In TableTypesOfStocks_ Do
		KeyValues = AnalystKeys.Get(InventoryLine.ItemsLocationAttributes);
		FillPropertyValues(InventoryLine, KeyValues);
		
		// The price is not filled in when selecting inventory types. It is required to calculate based on known data.
		If InventoryLine.Count <> 0 Then
			InventoryLine.Price = Round(?(PriceIncludesVAT,
										InventoryLine.AmountIncludingVAT / InventoryLine.Count,
										(InventoryLine.AmountIncludingVAT - InventoryLine.VATAmount) / InventoryLine.Count),
									2,
									RoundMode.Round15as20);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.Text = GetFinalBalances();
	UnloadedGoodsColumns = "Products, Characteristic, Purpose, Series, BatchesIndicationStatus, Warehouse, ItemsLocationAttributes, CCDNumber, PurchaseOrder";
	
	Query.SetParameter("Ref",			Ref);
	Query.SetParameter("DocumentDate",	EndOfDay(Date));
	Query.SetParameter("Organization",	Organization);
	Query.SetParameter("InventoryKinds",	TableTypesOfStocks_);
	Query.SetParameter("Goods",			Goods.Unload(, UnloadedGoodsColumns));
	Query.SetParameter("Contract",		Contract);
	Query.SetParameter("Terms",		Terms);
	Query.SetParameter("GoodsReceiptOption", GoodsReceiptOption);
	
	BalanceTable = Query.Execute().Unload();
	
	ProcessedRows = New Array;
	GoodsForDistribution = Goods.Unload(, "Products, Characteristic, Purpose, Warehouse, Series, CCDNumber, Count");
	GoodsForDistribution.GroupBy("Products, Characteristic, Purpose, Warehouse, Series, CCDNumber", "Count");
	For Each RowGoods In GoodsForDistribution Do
		
		FilterFields = "Products, Characteristic, Purpose, Warehouse";
		FillingFieldsArray = New Array;
		
		If ValueIsFilled(RowGoods.Series) Then
			FilterFields = FilterFields + ", Series";
			FillingFieldsArray.Add("Series");
		EndIf;
		
		If ValueIsFilled(RowGoods.CCDNumber) Then
			FillingFieldsArray.Add("CCDNumber");
		EndIf;
		
		PopulationFields = StrConcat(FillingFieldsArray, ", ");
		
		If PopulationFields = "" Then
			Continue;
		EndIf;
		
		PoskStructure = New Structure(FilterFields);
		FillPropertyValues(PoskStructure, RowGoods);
		FoundRows = BalanceTable.FindRows(PoskStructure);
		
		For Each RemainderLine In FoundRows Do
			
			If RemainderLine.Count = 0 Then
				Continue;
			EndIf;
			
			If ProcessedRows.Find(RemainderLine) <> Undefined Then
				Continue;
			EndIf;
			
			QuantityToDistribution = Min(RemainderLine.Count, RowGoods.Count);
			If QuantityToDistribution <> RemainderLine.Count Then 
				NewRow = BalanceTable.Add();
				FillPropertyValues(NewRow, RemainderLine);
				FillPropertyValues(NewRow, RowGoods, PopulationFields);
				NewRow.Count = QuantityToDistribution;
				RemainderLine.Count = RemainderLine.Count - QuantityToDistribution;
				ProcessedRows.Add(NewRow);
			Else
				FillPropertyValues(RemainderLine, RowGoods, PopulationFields);
				ProcessedRows.Add(RemainderLine);
			EndIf;
			
			RowGoods.Count = RowGoods.Count - QuantityToDistribution;
			
			If RowGoods.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;

	RowFilter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = BalanceTable.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		BalanceTable.Delete(TableRow);
	EndDo;

	SearchKey			= SearchKey + ", CCDNumber";
	SearchKeyWithoutSeries	= SearchKeyWithoutSeries + ", CCDNumber";
	
	RowFilter			= New Structure(SearchKey);
	FilterRowsWithoutSeries	= New Structure(SearchKeyWithoutSeries);
	
	For Each RemainderLine In BalanceTable Do
		Filter = ?(RemainderLine.BatchSelectionIsRequired, RowFilter, FilterRowsWithoutSeries);
		FillPropertyValues(Filter, RemainderLine);
		
		FillInRows = TableTypesOfStocks_.FindRows(Filter);
		
		For Each InventoryLine In FillInRows Do
			AllocationBalance = InventoryLine.Count - InventoryLine.NumberByCase;
			
			If AllocationBalance = 0 Then
				Continue;
			EndIf;
			
			Count				= Min(RemainderLine.Count, AllocationBalance);
			FillingInCurrentLine = Not ValueIsFilled(InventoryLine.AnalysisOfProductAccountingByRegister)
										Or InventoryLine.AnalysisOfProductAccountingByRegister = RemainderLine.ItemsLocationAttributes;
			
			If FillingInCurrentLine Then
				InventoryLine.AnalysisOfProductAccountingByRegister	= RemainderLine.ItemsLocationAttributes;
				InventoryLine.NumberByCase					= InventoryLine.NumberByCase + Count;
				InventoryLine.BatchIsSelectedCorrectly				= ?(Not ValueIsFilled(InventoryLine.Series),
																		True,
																		InventoryLine.Series = RemainderLine.Series);
			Else
				NewRow = TableTypesOfStocks_.Add();
				FillPropertyValues(NewRow, InventoryLine);
				
				NewRow.Count								= Count;
				NewRow.QuantityByGBRN						= ?(Count <> 0,
					Count * NewRow.QuantityByGBRN / InventoryLine.Count, 0);
				NewRow.AnalysisOfProductAccountingByRegister	= RemainderLine.ItemsLocationAttributes;
				NewRow.NumberByCase					= Count;
				NewRow.BatchIsSelectedCorrectly					= ?(Not ValueIsFilled(NewRow.Series),
																		True,
																		NewRow.Series = RemainderLine.Series);
				
				InventoryLine.Count		= InventoryLine.Count - Count;
				InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			EndIf;
			
			RemainderLine.Count = RemainderLine.Count - Count;
			
			If RemainderLine.Count = 0 Then
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	AnalyticsWithErrors	= New Map;
	BalanceAnalysts	= TableTypesOfStocks_.UnloadColumn("AnalysisOfProductAccountingByRegister");
	
	TableTypesOfStocksAdditional = TableTypesOfStocks_.Copy();
	TableTypesOfStocksAdditional.Clear();
	
	For Each InventoryLine In TableTypesOfStocks_ Do
		If Not ValueIsFilled(InventoryLine.AnalysisOfProductAccountingByRegister) Then
			InventoryLine.NumberOfPackages = InventoryLine.Count;
			
			Continue;
		EndIf;
		
		CurAnalytics	= InventoryLine.ItemsLocationAttributes;
		Count			= InventoryLine.Count;
		QuantityByGBRN	= InventoryLine.QuantityByGBRN;
		
		InventoryLine.ItemsLocationAttributes	= InventoryLine.AnalysisOfProductAccountingByRegister;
		InventoryLine.Count					= InventoryLine.NumberByCase;
		InventoryLine.QuantityByGBRN				= ?(Count <> 0,
			InventoryLine.Count * InventoryLine.QuantityByGBRN / Count, 0);
		InventoryLine.NumberOfPackages			= InventoryLine.NumberByCase;
		
		If Count > InventoryLine.Count Then
			LineAdd = TableTypesOfStocksAdditional.Add();
			FillPropertyValues(LineAdd, InventoryLine);
			LineAdd.ItemsLocationAttributes = CurAnalytics;
			LineAdd.Count = Count - InventoryLine.Count;
			LineAdd.NumberOfPackages = Count - InventoryLine.Count;
			LineAdd.QuantityByGBRN = QuantityByGBRN - InventoryLine.QuantityByGBRN;
		EndIf;
		
		If Not InventoryLine.BatchIsSelectedCorrectly
			And BalanceAnalysts.Find(CurAnalytics) = Undefined Then
			
			ErrorDescription = AnalyticsWithErrors.Get(CurAnalytics);
			
			If ErrorDescription = Undefined Then
				ProductPresentation = ProductsClientServer.ProductPresentation(InventoryLine.Products,
																								InventoryLine.Characteristic,
																								Undefined,
																								InventoryLine.Series,
																								InventoryLine.Purpose);
				
				AnalyticsWithErrors.Insert(CurAnalytics, ProductPresentation);
			EndIf;
			
		EndIf;
	EndDo;
	
	MessageTemplate = NStr("vi = 'Không thể nhận số dư đối với mặt hàng ""%1"" có bộ lọc theo sê-ri. Sê-ri được lựa chọn theo số dư.
							|Hãy kiểm tra rằng, đã chỉ ra hàng hóa ""%2"" trong chứng từ ""Tiếp nhận hàng hóa vào kho"".';
							|ru = 'Не удалось получить остаток для товара ""%1"" с отбором по серии. Серия подобрана по остаткам.
							|Проверьте, что товар ""%2"" указан в документе ""Поступление товаров на склад"".';
							|en = 'Cannot retrieve the balance for the ""%1"" item with filtering by batch. The batch is picked by the balance.
							|Check if the ""%2"" item is specified in the ""Warehouse receipt"" document.'; fa = 'Cannot retrieve the balance for the ""%1"" item with filtering by batch. The batch is picked by the balance.
							|Check if the ""%2"" item is specified in the ""Warehouse receipt"" document.';
							|it = 'Cannot retrieve the balance for the ""%1"" item with filtering by batch. The batch is picked by the balance.
							|Check if the ""%2"" item is specified in the ""Warehouse receipt"" document.';
							|pl = 'Cannot retrieve the balance for the ""%1"" item with filtering by batch. The batch is picked by the balance.
							|Check if the ""%2"" item is specified in the ""Warehouse receipt"" document.';
							|tr = 'Partiye göre filtrelenen ""%1"" ürünü için kalan bakiye alınamadı. Parti, bakiyelere göre seçildi.
							|""Ambara ürün girişi"" belgesinde ""%2"" ürününün belirtildiğini kontrol edin.'");
	
	For Each KeyAndValue In AnalyticsWithErrors Do
		ProductPresentation	= KeyAndValue.Value;
		MessageText				= StrTemplate(MessageTemplate, ProductPresentation, ProductPresentation);
		
		Common.MessageToUser(MessageText, Ref);
	EndDo;
	
	CommonClientServer.SupplementTable(TableTypesOfStocksAdditional, TableTypesOfStocks_);
	// When distributing quantities into series, the amounts are copied as is. Recalculation is required.
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateVATAmount",	StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT",	StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(TableTypesOfStocks_, StructureOfActions);
	
	InventoryKinds.Load(TableTypesOfStocks_);
	InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, CCDNumber, Price, VATRate",
							"Count, QuantityByGBRN, AmountIncludingVAT, VATAmount");
	
EndProcedure

Procedure FillInInventoryViewRegistration()
	
	GoodsTable = Goods.Unload();
	GoodsTable.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute", "Count");
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In GoodsTable Do
		
		NumberOfProductsPerLine = RowOfGoods.Count;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(NumberOfProductsPerLine, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			NewRow.RecipientInventoryOwnerAttribute	= RowOfGoods.InventoryOwnerAttribute;
			NewRow.Count				= Count;
			NewRow.QuantityByGBRN		= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			InventoryLine.Count = InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN = InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			NumberOfProductsPerLine = NumberOfProductsPerLine - NewRow.Count;
			
			If NumberOfProductsPerLine = 0 Then
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

Procedure FillInInventoryOwnerAttributeOfWorksBeingTracked()
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Goods.Products AS Products
	|INTO TTProducts_1
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products
	|FROM
	|	TTProducts_1 AS Goods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON Goods.Products = CatalogProducts.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods";
	
	Query.SetParameter("Goods", Goods.Unload(, "Products"));
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = QueryResult.Select();
	RowFilter = New Structure("Products");
	TaxationOfOrganization = VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
	
	NamesOfDocumentDetails = "Organization, InventoryType, GoodsOwner, Counterparty, Terms, Contract, Currency,
								|VATTaxation, TaxationOfOrganization, InventoryOwnerAttribute, FinancialAccountingGroup,
								|ProductsGroup, BusinessOperation, PriceKind, RetainedStockType";
	
	DocumentAttributes = New Structure(NamesOfDocumentDetails);
	DocumentAttributes.Organization = Organization;
	DocumentAttributes.InventoryType = Enums.InventoryTypes.Work_5;
	DocumentAttributes.TaxationOfOrganization = TaxationOfOrganization;
	
	InventoryOwnerAttributeOfTraceableWorks = Catalogs.InventoryKinds.DocumentInventoryView(
										Organization,
										Enums.BusinessTransactions.PurchaseFromSupplier,
										DocumentAttributes);
	
	While Selection.Next() Do
		FillPropertyValues(RowFilter, Selection);
		FoundRows = Goods.FindRows(RowFilter);
		
		For Each FoundRow In FoundRows Do
			FoundRow.InventoryOwnerAttribute = InventoryOwnerAttributeOfTraceableWorks;
		EndDo;
	EndDo;
	
EndProcedure

Procedure FillInAdditionalStockTypes(AdditionalDistributionWithoutAnalytics = False)
	
	TableTypesOfStocks_ = InventoryKinds.Unload();
	
	If AdditionalDistributionWithoutAnalytics Then
		// in the case of an unfactured delivery, analysts may differ by series (an empty series in TS of goods
		// filled in TS of inventory types). In this case, the search will be performed by the main fields of analytics.
		TableTypesOfStocks_.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		TableTypesOfStocks_.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		TableTypesOfStocks_.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		
		NomenclatureAnalysts	= TableTypesOfStocks_.UnloadColumn("ItemsLocationAttributes");
		AnalystKeys			= Common.ObjectsAttributesValues(
									NomenclatureAnalysts,
									"Products, Characteristic, Purpose");
		
		For Each String In TableTypesOfStocks_ Do
			AttributesValues = AnalystKeys.Get(String.ItemsLocationAttributes);
			FillPropertyValues(String, AttributesValues);
		EndDo;
	EndIf;
	
	ListOfFieldsToBeRetrieved = "ItemsLocationAttributes, Products, Characteristic, Purpose, PurchaseOrder, Price, VATRate, ARAPObject,
	|ToExpenseAs, ExpenseItem, DimensionOfExpenses, Department, CCDNumber";
	ListOfFieldsToFillIn = "PurchaseOrder, Price, VATRate, ARAPObject,
	|ToExpenseAs, ExpenseItem, DimensionOfExpenses, Department";

	Resources = "Count, QuantityByGBRN, AmountARAP, AmountVATARAP, AmountIncludingVAT, VATAmount, ManualDiscount";
	
	TheStructureOfTheSearch		= New Structure("ItemsLocationAttributes");
	StructureOfCCDSearch = New Structure("ItemsLocationAttributes, CCDNumber");
	SearchAttributesWithoutAnalytics = "Products, Characteristic, Purpose";
	SearchStructureWithoutAnalyticsWithoutCCD = New Structure(SearchAttributesWithoutAnalytics);
	SearchAttributesWithoutAnalytics = SearchAttributesWithoutAnalytics + ", CCDNumber";
	SearchStructureWithoutSGTDAnalytics = New Structure(SearchAttributesWithoutAnalytics);
	
	ResourcesStructure	= New Structure(Resources);
	ArrayOfResources		= StrSplit(Resources, ", ", False);
	
	GoodsTable = Goods.Unload(, ListOfFieldsToBeRetrieved + ", " + Resources);
	GoodsTable.GroupBy(ListOfFieldsToBeRetrieved, Resources); 
	ProcessedRows = New Array;
	
	For Each RowOfGoods In GoodsTable Do
		
		FillPropertyValues(ResourcesStructure, RowOfGoods);
		
		ThereIsCCDNumber = ValueIsFilled(RowOfGoods.CCDNumber);
		FoundRows = New Array;
		
		If ThereIsCCDNumber Then
			FillPropertyValues(StructureOfCCDSearch, RowOfGoods);
			FoundRows = TableTypesOfStocks_.FindRows(StructureOfCCDSearch);
		EndIf;
		
		If Not ThereIsCCDNumber Then
			FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
			FoundRows = TableTypesOfStocks_.FindRows(TheStructureOfTheSearch);
		EndIf;
		
		NotDistributedWithoutAnalytics = True;
		
		If FoundRows.Count() = 0
			And AdditionalDistributionWithoutAnalytics Then
			
			If ThereIsCCDNumber Then
				FillPropertyValues(SearchStructureWithoutSGTDAnalytics, RowOfGoods);
				FoundRows = TableTypesOfStocks_.FindRows(SearchStructureWithoutSGTDAnalytics);
			EndIf;
			
			If Not ThereIsCCDNumber Then
				FillPropertyValues(SearchStructureWithoutAnalyticsWithoutCCD, RowOfGoods);
				FoundRows = TableTypesOfStocks_.FindRows(SearchStructureWithoutAnalyticsWithoutCCD);
			EndIf;
			
			NotDistributedWithoutAnalytics = False;
		EndIf;
		
		For Each InventoryLine In FoundRows Do
			
			If InventoryLine.Count = 0
				And InventoryLine.AmountIncludingVAT = 0 Then
				
				Continue;
				
			EndIf;
			
			QuantityPerRow = Min(ResourcesStructure.Count, InventoryLine.Count);
			
			NewRow = TableTypesOfStocks_.Add();
			ProcessedRows.Add(NewRow);
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, ListOfFieldsToFillIn);
			
			NewRow.Count = QuantityPerRow;
			NewRow.QuantityByGBRN = QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If ResourcesStructure.Count Then
				For Each ResourceElement In ArrayOfResources Do
					NewRow[ResourceElement] = QuantityPerRow * ResourcesStructure[ResourceElement] / ResourcesStructure.Count;
				EndDo;
			EndIf;
			
			For Each ResourceElement In ArrayOfResources Do
				ResourcesStructure[ResourceElement] = ResourcesStructure[ResourceElement] - NewRow[ResourceElement];
			EndDo;
			
			OldQuantity = InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			If OldQuantity Then
				For Each ResourceElement In ArrayOfResources Do
					If ResourceElement <> "Count"
						And ResourceElement <> "QuantityByGBRN" Then
						
						InventoryLine[ResourceElement] = InventoryLine.Count * InventoryLine[ResourceElement]
														/ OldQuantity;
						
					EndIf;
				EndDo;
			EndIf;
			
			If ResourcesStructure.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	If ResourcesStructure.Count > 0
		And AdditionalDistributionWithoutAnalytics 
		And NotDistributedWithoutAnalytics Then
		
		If ThereIsCCDNumber Then
			FillPropertyValues(SearchStructureWithoutSGTDAnalytics, RowOfGoods);
			FoundRows = TableTypesOfStocks_.FindRows(SearchStructureWithoutSGTDAnalytics);
		EndIf;
		
		If Not ThereIsCCDNumber Then
			FillPropertyValues(SearchStructureWithoutAnalyticsWithoutCCD, RowOfGoods);
			FoundRows = TableTypesOfStocks_.FindRows(SearchStructureWithoutAnalyticsWithoutCCD);
		EndIf;
		
		For Each InventoryLine In FoundRows Do
			
			If (InventoryLine.Count = 0
				And InventoryLine.AmountIncludingVAT = 0)
				Or ProcessedRows.Find(InventoryLine) <> Undefined Then
				
				Continue;
				
			EndIf;
			
			QuantityPerRow = Min(ResourcesStructure.Count, InventoryLine.Count);
			
			NewRow = TableTypesOfStocks_.Add();
			FillPropertyValues(NewRow, InventoryLine);
			FillPropertyValues(NewRow, RowOfGoods, ListOfFieldsToFillIn);
			
			NewRow.Count = QuantityPerRow;
			NewRow.QuantityByGBRN = QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If ResourcesStructure.Count Then
				For Each ResourceElement In ArrayOfResources Do
					NewRow[ResourceElement] = QuantityPerRow * ResourcesStructure[ResourceElement] / ResourcesStructure.Count;
				EndDo;
			EndIf;
			
			For Each ResourceElement In ArrayOfResources Do
				ResourcesStructure[ResourceElement] = ResourcesStructure[ResourceElement] - NewRow[ResourceElement];
			EndDo;
			
			OldQuantity = InventoryLine.Count;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			
			If OldQuantity Then
				For Each ResourceElement In ArrayOfResources Do
					If ResourceElement <> "Count"
						And ResourceElement <> "QuantityByGBRN" Then
						
						InventoryLine[ResourceElement] = InventoryLine.Count * InventoryLine[ResourceElement]
														/ OldQuantity;
						
					EndIf;
				EndDo;
			EndIf;
			
			If ResourcesStructure.Count = 0 Then
				Break;
			EndIf;
			
		EndDo;

	EndIf;
		
	EndDo;
	
	InventoryKinds.Load(TableTypesOfStocks_);
	
	RowFilter = New Structure("Count, AmountIncludingVAT", 0, 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.VendorInvoice.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.VendorInvoice.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
	
	OperationsInTransitAndInvoicing = New Array;
	OperationsInTransitAndInvoicing.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	OperationsInTransitAndInvoicing.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	OperationsInTransitAndInvoicing.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsInTransitAndInvoicing.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	OperationsInTransitAndInvoicing.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
 	If InvoicingOperations.Find(BusinessOperation) <> Undefined
		And (Not Common.ObjectAttributeValue(Contract, "OptionForRegisteringServiceReceiptDocuments") = 
			Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed) Then
		
		PlacesOfAccounting.Work_5 = Contract;
		PlacesOfAccounting.Insert("OperationService", Contract);
		
	Else
		
		FieldsNames.Insert("Work_5", "Department");
		
	EndIf;
	
	TextOfWarehouseProductField = "
		|CASE
		|	WHEN Collection.ToExpenseAs
		|		THEN Collection.Department
		|	ELSE UNDEFINED
		|END";
	
	If ValueIsFilled(Warehouse) Then
		WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	Else
		WarehouseDetails = New Structure;
		WarehouseDetails.Insert("IsFolder",	False);
		WarehouseDetails.Insert("SelectGroup",	Undefined);
	EndIf;
	
	If WarehouseDetails.IsFolder
		And OperationsInTransitAndInvoicing.Find(BusinessOperation) = Undefined
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
		
		TextOfWarehouseProductField = "
			|CASE
			|	WHEN Collection.ToExpenseAs
			|		THEN Collection.Department
			|	ELSE Collection.Warehouse
			|END";
		
	EndIf;
	
	FieldsNames.Insert("OwnGoods", New Structure("FieldText", TextOfWarehouseProductField));
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

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
	|	OR &PackageDepositIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

Procedure FillInPaymentTerms_(Val PurchaseConditions)
	
	PaymentMethod = PurchaseConditions.PaymentMethod;
	
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization = Organization Then
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			CompanyBankAccount);
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation";
	
	If BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		AttributesNames = AttributesNames + ",Partner,Counterparty,Terms,Currency,VATTaxation";
	EndIf;
		
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.PurchaseOrder AS PurchaseOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.CCDNumber
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.PurchaseOrder AS PurchaseOrder,
	|		TableOfGoods.ARAPObject AS ARAPObject,
	|		TableOfGoods.CCDNumber AS CCDNumber,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|		TableOfGoods.Price AS Price,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.AmountARAP AS AmountARAP,
	|		TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|		TableOfGoods.ManualDiscount AS ManualDiscount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes,
	|		TableTypesOfStocks_.PurchaseOrder,
	|		TableTypesOfStocks_.ARAPObject,
	|		TableTypesOfStocks_.CCDNumber,
	|		-TableTypesOfStocks_.Count,
	|		-TableTypesOfStocks_.QuantityByGBRN,
	|		-TableTypesOfStocks_.Price,
	|		-TableTypesOfStocks_.VATAmount,
	|		-TableTypesOfStocks_.AmountIncludingVAT,
	|		-TableTypesOfStocks_.AmountARAP,
	|		-TableTypesOfStocks_.AmountVATARAP,
	|		-TableTypesOfStocks_.ManualDiscount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.PurchaseOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.CCDNumber
	|
	|HAVING
	|	(SUM(TableOfGoods.Count) <> 0
	|		OR SUM(TableOfGoods.QuantityByGBRN) <> 0
	|		OR SUM(TableOfGoods.Price) <> 0
	|		OR SUM(TableOfGoods.VATAmount) <> 0
	|		OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|		OR SUM(TableOfGoods.AmountARAP) <> 0
	|		OR SUM(TableOfGoods.AmountVATARAP) <> 0
	|		OR SUM(TableOfGoods.ManualDiscount) <> 0)";
	
	Query.TempTablesManager = TempTablesManager;
	
	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function TemporaryDocumentDataTables(UseSeparateProcurement, IncludeTraceableWorks = True)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	&Currency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&BusinessOperation AS BusinessOperation,
	|	FALSE AS ThereAreTransactionsInTablePart,
	|	&InventoryType AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.VendorPriceKind AS PriceKind,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableOfGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.PurchaseOrder AS PurchaseOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	CAST(TableOfGoods.Products AS Catalog.Products) AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	CAST(TableOfGoods.Purpose AS Catalog.Assignments) AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.PriceKind AS PriceKind,
	|	TableOfGoods.Warehouse AS Warehouse,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.PurchaseOrder AS PurchaseOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.PriceKind AS PriceKind,
	|	Dimension.StorageLocation AS Warehouse,
	|	TableOfGoods.CCDNumber AS CCDNumber,
	|	TableOfGoods.VATRate AS VATRate,
	|	TableOfGoods.Count AS Count,
	|	TableOfGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfGoods.Price AS Price,
	|	TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount AS VATAmount,
	|	TableOfGoods.AmountARAP AS AmountARAP,
	|	TableOfGoods.AmountVATARAP AS AmountVATARAP,
	|	TableOfGoods.ManualDiscount AS ManualDiscount,
	|	TableOfGoods.PurchaseOrder AS PurchaseOrder,
	|	TableOfGoods.ARAPObject AS ARAPObject,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose AS Purpose,
	|	TableOfGoods.Series AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TableOfGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.Products = Dimension.Ref
	|WHERE
	|	&IncludeTraceableWorks
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableOfGoods.Products.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.PurchaseOrder AS PurchaseOrder,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject
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
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.PurchaseOrder AS PurchaseOrder,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	Dimension.StorageLocation AS Warehouse
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
	|	&OrganizationOfExodus AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.ConsignedGoods) AS InventoryType,
	|	&Terms AS Terms,
	|	&ARAPCurrency AS Currency,
	|	&VATTaxation AS VATTaxation,
	|	&TaxationOfOrganization AS TaxationOfOrganization,
	|	&Partner AS GoodsOwner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract
	|INTO DocumentAttributes
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|
	|UNION ALL
	|
	|SELECT
	|	&OrganizationOfExodus,
	|	&BusinessOperation,
	|	VALUE(Enum.InventoryTypes.OwnGoods),
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef),
	|	VALUE(Catalog.Currencies.EmptyRef),
	|	CASE
	|		WHEN &UseSeparateAccountingByTaxation
	|				AND NOT &BatchAccountingVersion22
	|			THEN &PurchaseForActivity
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END,
	|	&TaxationOfOrganization,
	|	UNDEFINED,
	|	VALUE(Catalog.Counterparties.EmptyRef),
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|WHERE
	|	&BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
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
	|	CASE
	|		WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND &ToReturnReusablePackage
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsReusablePackage,
	|	InventoryTypeDetails.Organization AS Organization,
	|	InventoryTypeDetails.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|				AND TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		ELSE InventoryTypeDetails.InventoryType
	|	END AS InventoryType,
	|	InventoryTypeDetails.Terms AS Terms,
	|	InventoryTypeDetails.Currency AS Currency,
	|	InventoryTypeDetails.VATTaxation AS VATTaxation,
	|	InventoryTypeDetails.TaxationOfOrganization AS TaxationOfOrganization,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|				AND TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Partner
	|		ELSE InventoryTypeDetails.GoodsOwner
	|	END AS GoodsOwner,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement) 
	|				AND TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract.Counterparty
	|		ELSE InventoryTypeDetails.Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement) 
	|				AND TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|			THEN TableOfGoods.Purpose.Contract
	|		ELSE InventoryTypeDetails.Contract
	|	END AS Contract
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		LEFT JOIN DocumentAttributes AS InventoryTypeDetails
	|		ON TRUE
	|WHERE
	|	CatalogProducts.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR InventoryKinds.InventoryType <> CASE
	|				WHEN TableOfGoods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|						AND &ToReturnReusablePackage
	|					THEN VALUE(Enum.InventoryTypes.OwnGoods)
	|				ELSE CASE
	|						WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement) 
	|								AND TableOfGoods.Purpose.AssignmentType = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|							THEN VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|						ELSE &InventoryType
	|					END
	|			END
	|		OR InventoryKinds.Organization <> &OrganizationOfExodus
	|		OR &RefillInventoryKinds)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	TableOfGoods.Products AS Products,
	|	CASE
	|		WHEN &Posted
	|			THEN TableOfGoods.InventoryOwnerAttribute
	|		ELSE VALUE(Catalog.InventoryKinds.EmptyRef)
	|	END AS CurViewOfStocks,
	|	FALSE AS ThisIsReusablePackage,
	|	InventoryTypeDetails.Organization AS Organization,
	|	InventoryTypeDetails.BusinessOperation AS BusinessOperation,
	|	VALUE(Enum.InventoryTypes.Work_5) AS InventoryType,
	|	UNDEFINED AS Terms,
	|	InventoryTypeDetails.Currency AS Currency,
	|	InventoryTypeDetails.VATTaxation AS VATTaxation,
	|	InventoryTypeDetails.TaxationOfOrganization AS TaxationOfOrganization,
	|	UNDEFINED AS GoodsOwner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON TableOfGoods.InventoryOwnerAttribute = InventoryKinds.Ref
	|		
	|		LEFT JOIN DocumentAttributes AS InventoryTypeDetails
	|		ON TRUE
	|WHERE
	|	CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND (TableOfGoods.InventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR InventoryKinds.InventoryType <> VALUE(Enum.InventoryTypes.Work_5)
	|		OR InventoryKinds.Organization <> &OrganizationOfExodus
	|		OR &RefillInventoryKinds)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP DocumentAttributes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTableOfGoods";
	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	TableOfGoods = Goods.Unload();
	If Not UseSeparateProcurement Then
		TableOfGoods.FillValues(Catalogs.VendorPriceTypes.EmptyRef(), "VendorPriceKind");
	EndIf;
	
	Query.SetParameter("TableOfGoods", 			TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", 		InventoryKinds);
	Query.SetParameter("OrganizationOfExodus",			Organization);
	Query.SetParameter("Organization",				
		?(BusinessOperation = 
			Enums.BusinessTransactions.PurchaseFromVendorLocal, 
			Catalogs.Companies.ManagementCompany,
			Organization));
	Query.SetParameter("Date",						Date);
	Query.SetParameter("Partner",					Partner);
	Query.SetParameter("Counterparty",					Counterparty);
	Query.SetParameter("Terms",					Terms);
	Query.SetParameter("Contract",					Contract);
	Query.SetParameter("Currency",						Currency);
	Query.SetParameter("ARAPCurrency",		ARAPCurrency);
	Query.SetParameter("VATTaxation",			VATTaxation);
	Query.SetParameter("PurchaseForActivity",		PurchaseForActivity);
	Query.SetParameter("TaxationOfOrganization",	VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales);
	Query.SetParameter("BusinessOperation",		BusinessOperation);
	Query.SetParameter("InventoryType",					TypeOfInventoryByBusinessTransaction());
	Query.SetParameter("ReceiptUnderOrders",		ReceiptUnderOrders);
	Query.SetParameter("ToReturnReusablePackage",	ToReturnReusablePackage);
	Query.SetParameter("UseSeparateAccountingByTaxation",
		AccountingPoliciesTaxSettingsCached.SeparateAccountingOfGoodsByVATTaxation(Organization, Date));
	Query.SetParameter("BatchAccountingVersion22",
		CalculationOfCostCached.BatchAccountingVersion22(BegOfMonth(Date)));
	Query.SetParameter("Posted",					Posted);
	Query.SetParameter("IncludeTraceableWorks", IncludeTraceableWorks);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
	Query.Execute();
	
	Return TempTablesManager;
	
EndFunction

Function ParametersForFillingInventoryTypes(UseSeparateProcurement)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	
	If UseSeparateProcurement Then
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = True;
		FillParameters.TableOfDetailsOfStockTypesByDefault = TableOfDetailsOfStockTypesByDefault();
		FillParameters.NameOfRemainderTable = "PartnerProductsHaveNegativeBalance";
		FillParameters.WithoutSelectionByCCDNumbers = True;
		FillParameters.SelectionOfStockTypes_.InventoryType.Clear();
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(TypeOfInventoryByBusinessTransaction());
		FillParameters.SelectionOfStockTypes_.Organization = Organization;
		FillParameters.SelectionOfStockTypes_.PriceKind = Goods.UnloadColumn("VendorPriceKind");
	Else
		FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
		FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
		FillParameters.CompanyFieldName1 = "";
		FillParameters.SelectionOfStockTypes_.Organization = Catalogs.Companies.ManagementCompany;
		FillParameters.SelectionOfStockTypes_.InventoryType.Add(Enums.InventoryTypes.Work_5);
	EndIf;
	
	Return FillParameters;
	
EndFunction

Function TableOfDetailsOfStockTypesByDefault()
	
	TableOfDetailsOfStockTypesByDefault = Goods.Unload(, "LineNumber, ItemsLocationAttributes, VendorPriceKind");
	TableOfDetailsOfStockTypesDefaultColumnsSupplierPriceType = TableOfDetailsOfStockTypesByDefault.Columns.VendorPriceKind; // ValueTableColumn
	TableOfDetailsOfStockTypesDefaultColumnsSupplierPriceType.Name = "PriceKind";
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

Function TypeOfInventoryByBusinessTransaction()

	If BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit Then
		
		Return Enums.InventoryTypes.OwnGoodsInTransit;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt Then
		
		Return Enums.InventoryTypes.OwnGoodsOfUninvoicedDelivery;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		Return Enums.InventoryTypes.ConsignedGoods;
	Else
		Return Enums.InventoryTypes.OwnGoods;
	EndIf;
	
EndFunction

Function GetAmountOfSettlementsByContainer() Export
	
	Query = New Query("
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.AmountARAP AS AmountARAP
	|INTO
	|	Goods
	|FROM
	|	&Goods AS Goods
	|;
	|SELECT
	|	ISNULL(SUM(Goods.AmountARAP),0) AS AmountARAP
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &PackageDepositIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountARAP"));
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountARAP;
	Return TotalAmount__;
	
EndFunction

Procedure RecalculateNumberOfRNPT()
	
	BusinessTransactionsImportPurchase = PurchasesServerCall.BusinessOperationsOnMain(
									PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	
	If BusinessTransactionsImportPurchase.Find(BusinessOperation) = Undefined Then
		ParametersForObtainingRnptCoefficient = AccountingForTraceableGoodsClientServerLocalization.ParametersForObtainingRnptCoefficient(
												ThisObject,
												"Warehouse",
												True);
		AccountingForTraceableGoodsLocalization.FillInQuantityByRNPTVOfTablePart(ParametersForObtainingRnptCoefficient,
																						Goods);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
