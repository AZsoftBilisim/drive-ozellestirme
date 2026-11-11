#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the amount of undelivered order lines
//
// Parameters:
//	OnlyDepositForContainer - Boolean - indicates a Deposit for the container.
//
// Returns:
//	Number - the sum of the replacement lines.
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
	|	AND (((Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR (NOT &ToReturnReusablePackage) OR &PackageDepositIsRequired)
	|			AND NOT &OnlyDepositForContainer)
	|		OR (Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage
	|			AND &PackageDepositIsRequired
	|			AND &OnlyDepositForContainer))
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	Query.SetParameter("OnlyDepositForContainer", OnlyDepositForContainer);
	
	Upload0 = Query.Execute().Unload();
	SumOfOrderedRows = Upload0[0].AmountIncludingVAT;
	Return SumOfOrderedRows;
	
EndFunction

// Calculates the number of ordered order lines
// 
// Returns:
// 	Number - 
Function GetNumberOfRowsOrdered() Export
	
	FoundRows = Goods.FindRows(New Structure("Canceled", False));
	Return FoundRows.Count();
	
EndFunction

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.ARAPCurrency) Then
		Currency = SalesTermsAndConditions.ARAPCurrency;
	EndIf;
	BusinessOperation = SalesTermsAndConditions.BusinessOperation;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	PriceIncludesVAT      		   = SalesTermsAndConditions.PriceIncludesVAT;
	ToReturnReusablePackage 	   = SalesTermsAndConditions.ReturnReusablePackage;
	ReusablePackageReturnCycleLength = SalesTermsAndConditions.ReusablePackageReturnCycleLength;
	PackageDepositIsRequired 		   = SalesTermsAndConditions.PackageDepositIsRequired;
	LineOfBusiness 	   = SalesTermsAndConditions.LineOfBusiness;

	DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ConsignmentSales25, BusinessOperation");
	ConsignmentSales25 = ?(BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not GetFunctionalOption("ToUseTermsOfSales")
			Or (ValueIsFilled(Terms)
				And DetailsOfAgreement.ConsignmentSales25
				And DetailsOfAgreement.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)), True, False);
			
	If (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		 And ConsignmentSales25) Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		ToReturnReusablePackage      = False;
		ReusablePackageReturnCycleLength = 0;
		PackageDepositIsRequired           = False;
	EndIf;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization    			= Organization;
		ParametersStructure.LineOfBusiness = LineOfBusiness;
		ParametersStructure.PaymentMethod 			= PaymentMethod;
		ParametersStructure.Individual			= Courier;

		CashAccount  = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) Then
			Counterparty = SalesTermsAndConditions.Counterparty;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.ContactPerson) 
			And Not ValueIsFilled(ContactPerson) Then
			ContactPerson = SalesTermsAndConditions.ContactPerson;
		EndIf;
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then

		Contract = SalesServer.GetDefaultContract(ThisObject, BusinessOperation, Currency);
		
		If ValueIsFilled(Contract) Then
			PaymentInCurrencyUnderContract = Common.ObjectAttributeValue(Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> PaymentInCurrencyUnderContract Then
				ForeignCurrencyTransaction = PaymentInCurrencyUnderContract;
				BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
			BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;

	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		OrganizationSDefaultAccountParameters(),
		BankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays)
		And Not ThisIsOrderAsInvoice
		And GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
		
		StartDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
		ShipmentDateInLine = TMCommonUseClientServer.CalculatePeriodEndDate(StartDate,Enums.Periodicity.Day, SalesTermsAndConditions.DeliveryPeriodDays) + 1;
		If NotShipInInstallments Then
			DateOfShipment = ShipmentDateInLine;
		EndIf;
		
		For Each TSRow In Goods Do
			TSRow.DateOfShipment = ShipmentDateInLine;
		EndDo;
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the customer's order
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled (Partner) Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("SelectedAgreement", Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.SalesOrder.EmptyRef());
		BusinessTransactions = Documents.SalesOrder.BusinessOperationsOfDocument(True);
		FilterParameters.Insert("BusinessTransactions", BusinessTransactions);
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
			
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales Then
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					FillParameters = New Structure;
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
					FillParameters.Insert("CalculateSets", True);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind, DeliveryPeriodDays");
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
					StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
					
					EnterprisePricesFillingServer.FillInPrices(
						Goods,
						, // Array of rows or selection structure
						FillParameters,
						StructureOfActions);
				EndIf;
			Else
				Terms = DefaultSalesTerms.Terms;
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
		Else
			Terms = Undefined;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner,ContactPerson);
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
		
EndProcedure

// Fills in the terms of sales by agreement in the customer's order.
//
// Parameters:
// 	RecalculatePrices_2 - Boolean - indication that prices need to be recalculated
//
// Returns:
// 	Boolean - result of overfilling
//
Function FillInTermsOfSalesUnderAgreement(RecalculatePrices_2 = True) Export
	
	PricesCalculated = False;
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfActions = New Structure;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(ThisObject));
	
	If RecalculatePrices_2 = True Then
		
		FillParameters = New Structure;
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("Terms", Terms);
		FillParameters.Insert("CalculateSets", True);
		FillParameters.Insert("VATTaxation", VATTaxation);
		FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
		FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind, DeliveryPeriodDays");
		
		StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
		StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
		StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
		StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
		
		PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
			Goods,,
			FillParameters,
			StructureOfActions);
		
	EndIf;
	
	StructureOfRecalculationOfAmount =
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions.Clear();
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
	Return PricesCalculated;
	
EndFunction

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
	
	MeaningOfNewStatus = Enums.SalesOrderStatuses[NewStatus];
	
	If MeaningOfNewStatus = Enums.SalesOrderStatuses.NotApproved Then
		
		If Approved Then
			Approved = False;
		EndIf;
		
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		
		OrderChanged = OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SalesOrder);
	
	ThisIsOrderFromWarehouse = Not ThisIsOrderAsInvoice
		And Not GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	If ThisIsOrderFromWarehouse Then
		StructureOfActions = New Structure();
		DocumentParameters = Documents.SalesOrder.DocumentParametersForSoftwareActions(ThisObject);
		StringFields_ = "SupplyOption";
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
		BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If IsNew() And Not ThisIsOrderAsInvoice Then 
	// if this order account = true - then the Attribute was filled in earlier in the form – no need to change
		ThisIsOrderAsInvoice  = Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting
			And ThisIsOrderAsInvoice And Status <> Enums.SalesOrderStatuses.NotApproved Then
		
		ErrorText = NStr("vi = 'Đơn hàng này giống như hóa đơn cần có trạng thái ""Để thống nhất"".';
						|ru = 'Заказ как счет должен иметь статус ""На согласовании"".';
						|en = 'Order as a commercial invoice must have the ""Pending approval"" status.'; fa = 'Order as a commercial invoice must have the ""Pending approval"" status.';
						|it = 'Ordine come conto deve avere stato ""In negoziazione"".';
						|pl = 'Zamówienie jako rachunek powinno mieć status ""Na uzgodnieniu"".';
						|tr = 'Fatura olarak siparişin durumu ""Onay bekliyor"" olmalıdır.'");
		Common.MessageToUser(ErrorText, Ref, , , Cancel);
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting 
		And GetFunctionalOption("UseDiscountsMarkupsInSales")
		And Not DiscountsAreCalculated
		And SalesServer.GoodsTransferOperations().Find(BusinessOperation) = Undefined Then
		
			Cancel = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1, chiết khấu tự động (tỷ suất lợi nhuận) không được tính. Không thể kết chuyển. Để tính chiết khấu tự động (tỷ suất lợi nhuận), hãy kết chuyển chứng từ từ mẫu.';
				|ru = 'В документе %1 не рассчитаны автоматические скидки (наценки). Проведение невозможно. Для расчёта автоматических скидок (наценок) проведите документ из формы документа.';
				|en = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.'; fa = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.';
				|it = 'Nel documento %1 gli sconti (sovraprezzi) automatici non sono calcolati. Impossibile registrare. Per calcolare automaticamente gli sconti (sovraprezzi) registrate il documento dal modulo del documento.';
				|pl = 'W dokumencie %1 nie obliczono automatycznych rabatów (marży). Zatwierdzenie jest niemożliwe. Aby obliczyć automatyczne rabaty (marże) zatwierdź dokument z formularza dokumentu.';
				|tr = 'Otomatik indirimler (marj) %1 belgesinde hesaplanmamıştır. Gerçekleştirilemez. Otomatik indirimleri (marj) hesaplamak için, belgeyi belge formundan çalıştırın.'"),
			Ref);
		
			CommonClientServer.MessageToUser(
				ErrorText,
				Ref,
				,
				,
				Cancel);
		
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	
	TransferOperations_ = SalesServer.GoodsTransferOperations();
	
	DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ConsignmentSales25, BusinessOperation");
	ConsignmentSales25 = ?(BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not GetFunctionalOption("ToUseTermsOfSales")
			Or (ValueIsFilled(Terms)
				And DetailsOfAgreement.ConsignmentSales25
				And DetailsOfAgreement.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)), True, False);
			
	If BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		ToReturnReusablePackage = False;
		PackageDepositIsRequired      = False;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			  And ConsignmentSales25 Then
		ToReturnReusablePackage      = False;
		ReusablePackageReturnCycleLength = 0;
		PackageDepositIsRequired           = False;
	EndIf;

	If (TransferOperations_.Find(BusinessOperation) <> Undefined
			Or Not ToReturnReusablePackage)
		And PackageDepositIsRequired Then
		
		PackageDepositIsRequired = False;
		
	EndIf;
	
	DocumentAmount = GetSumOfOrderedRows();
	ReturnablePackagingAmount = GetReturnTareAmount();
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	DocumentApproved = Approved;
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode,
		Enums.SalesOrderStatuses.NotApproved);
	
	// We will set the date of approval, if the document is agreed
	If Not DocumentApproved And Approved Then
		ApprovalDate = CurrentSessionDate();
		ARAPAccountingServer.WhenChangingApprovalDate(ThisObject);
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	ExecutionScheduleInContract = False;
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Contract) Then
		ExecutionScheduleInContract = Common.ObjectAttributeValue(Contract, "ExecutionScheduleIsSpecified");
	EndIf;
	
	If TransferOperations_.Find(BusinessOperation) <> Undefined
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or ExecutionScheduleInContract Then
		
		AmountPrepaymentBeforeGoodsIssue = 0;
		AmountOfPrepaymentBeforeShipment = 0;
		
	Else

		SalesServer.FillInAdvancePrepaymentAmounts(ThisObject);
		
	EndIf;
	
	If Not NotShipInInstallments Then
		NewShipmentDate = Date(1,1,1);
		
		If Goods.Count() > 0 Then
			
			If Status = Enums.SalesOrderStatuses.ToSupply
				Or Status = Enums.SalesOrderStatuses.ToShip
				Or Status = Enums.SalesOrderStatuses.Closed Then
				
				FilterParameters = New Structure;
				FilterParameters.Insert("Canceled", False);
				RequirementsForProvision = Goods.FindRows(FilterParameters);
				
				If RequirementsForProvision.Count() > 0 Then
					
					TableOfRowsToProvide = Goods.Unload(RequirementsForProvision, "DateOfShipment");
					TableOfRowsToProvide.Sort("DateOfShipment Asc");
					NewShipmentDate = TableOfRowsToProvide[0].DateOfShipment;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		DateOfShipment = NewShipmentDate;
	Else
		ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, Goods, "DateOfShipment");
	EndIf;
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.SalesOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
	AttributesArray = New Array;
	If ValueIsFilled(PaymentMethod) And Not (PaymentMethod = Enums.PaymentForms.CashAccountPayment_) Then
		AttributesArray.Add("CashAccount");
	EndIf;
	
	CashServer.ClearUnusedProps(ThisObject, AttributesArray, New Array);
	
	ProductsServer.ClearUnusedSeries(ThisObject, ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SalesOrder));
	
	DestinationPattern = Documents.SalesOrder.DestinationPattern(ThisObject);
	
	DetailsForCheckingAppointment = "LineOfBusiness,Contract,Partner";
	Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, DetailsForCheckingAppointment, Cancel);

	PartnersProductsServer.FillInPartnerProductsByProductsInTable(Goods, Partner);
	If WriteMode = DocumentWriteMode.Posting Then
		PartnersProductsServer.FillInEmptyMappingInProductPartnerSProductPartner(Goods, Cancel);
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(ThisObject, Metadata.Documents.SalesOrder.TabularSections.Goods.Name);
	EndIf;
	
	SalesOrderLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DeliveryBeforeWrite(Cancel, WriteMode);
	
	If IsNew() And Not ValueIsFilled(Author) Then
		Author = Users.AuthorizedUser();
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.SalesOrder.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Partner,
		VATAccountingERP.TypeOfVATTaxationActivity(VATTaxation, Organization, Date));
	
	SalesOrderLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.AuthorizedUser();
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		FillInSelectionDocument(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		FillInDocumentOnBasisOfSaleTransaction(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.JobForSalesRepresentative") Then
		FillInDocumentBasedOnTaskToSalesRepresentative(FillingData);
	Else
		Sales.WhenProcessingCustomerOrderFilling(ThisObject, FillingData, StandardProcessing);
	EndIf;
	
	DetailsOfAgreement = Common.ObjectAttributesValues(Terms, "ConsignmentSales25, BusinessOperation");
	ConsignmentSales25 = ?(BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		And (Not GetFunctionalOption("ToUseTermsOfSales")
			Or (ValueIsFilled(Terms)
				And DetailsOfAgreement.ConsignmentSales25
				And DetailsOfAgreement.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)), True, False);
			
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		 And ConsignmentSales25 Then
		ToReturnReusablePackage      = False;
		ReusablePackageReturnCycleLength = 0;
		PackageDepositIsRequired           = False;
	EndIf;
	
	InitializeSalesConditions();
	
	FillOutBankAccounts();
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ResponsiblePersonsServer.InstallManager(ThisObject, DocumentBasis);
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	SalesOrderLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
	Priority = SettingsValueCached.GetDefaultPriority(Priority);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("Goods.VATRate");
	EndIf;
	
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel);
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.SalesOrder),
												Cancel,
												NotCheckedAttributeArray);
	
	ProductsServer.CheckContentCompletion(ThisObject,Cancel,"Goods");

	// The validity period of the order must be at least the date of the document
	If Status = Enums.SalesOrderStatuses.NotApproved
		And Not ThisIsOrderAsInvoice
		And ValueIsFilled(ApprovalDate) And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày điều chỉnh không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата согласования должна быть не меньше даты документа %Date%';
						|en = 'Approval date shall not be less than document date %Date%'; fa = 'Approval date shall not be less than document date %Date%';
						|it = 'La data della definizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data uzgodnienia powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Onay tarihi belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ApprovalDate",
			,
			Cancel);
		
	EndIf;
	
	AllLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "Goods", "Canceled");
	
	NotCheckedAttributeArray.Add("DateOfShipment");
	
	// The date of shipment in the header must be at least the date of the document
	If NotShipInInstallments And 
		ValueIsFilled(DateOfShipment) And 
		DateOfShipment < BegOfDay(Date) Then
	
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfShipment",
			,
			Cancel);

	EndIf;
	
	NotCheckedAttributeArray.Add("Goods.CancellationReason");
	NotCheckedAttributeArray.Add("Goods.DateOfShipment");
	
	EmbeddingParameters = Documents.SalesOrder.AvailableRemainingEmbeddingOptions();
	ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
	
	DateOfShipmentRequired_ = False;
	TextTemplateShipmentDate = NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% trong danh sách ""Hàng hóa""';
									|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Товары""';
									|en = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the Item list is not filled in';
									|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Товары""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Sevkiyat tarihi"" sütunu eksik'");
	
	For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
		
		ErrorString = ErrorsTable[CurIndex__];
		
		If ErrorString.DateOfShipmentRequired_ And Not NotShipInInstallments And ErrorString.ShipmentDateNotFilledIn Then
			
			ErrorText   = StrReplace(TextTemplateShipmentDate, "%LineNumber%", ErrorString.LineNumber);
			PathToTop = CommonClientServer.PathToTabularSection("Goods", ErrorString.LineNumber, "DateOfShipment");
			CommonClientServer.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
			
		EndIf;
		DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
		
	EndDo;
	
	If DateOfShipmentRequired_ And NotShipInInstallments And Not ValueIsFilled(DateOfShipment) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
						|ru = 'Поле ""Дата отгрузки"" не заполнено';
						|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
						|it = 'Il campo ""Data di spedizione"" non è compilato';
						|pl = 'Nie wypełniono pole ""Data отгрузки""';
						|tr = '""Sevkiyat tarihi"" alanı doldurulmamış'");
		CommonClientServer.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
		
	EndIf;
	
	MatchingLineCodes = New Map;
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Hàng hóa""';
									|ru = 'в строке %LineNumber% списка ""Товары""';
									|en = 'in line %LineNumber% of the ""Goods"" list'; fa = 'in line %LineNumber% of the ""Goods"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci""';
									|pl = 'w wierszu %LineNumber% listy ""Towary""';
									|tr = '""Ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", LineProducts_.LineNumber);
		
		// The reason for cancellation is mandatory in the lines without the Canceled attribute
		If GetFunctionalOption("UseReasonsForSalesOrderCancellations")
			And LineProducts_.Canceled And
			Not ValueIsFilled(LineProducts_.CancellationReason) Then
			
			ErrorText = NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ';
							|ru = 'Необходимо указать причину отмены';
							|en = 'Cancellation reason is required'; fa = 'Cancellation reason is required';
							|it = 'È necessario specificare il motivo di annullamento';
							|pl = 'Należy wskazać przyczynę anulowania';
							|tr = 'İptal nedeni belirtilmelidir'");
			CommonClientServer.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "CancellationReason"),
				,
				Cancel);
			
		EndIf;
		
		// The date of shipment in pm Goods must be at least the date of the document
		If Not NotShipInInstallments 
			And ValueIsFilled(LineProducts_.DateOfShipment) 
			And LineProducts_.DateOfShipment < BegOfDay(Date) Then
			
			ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ ""%Date%""';
							|ru = 'Дата отгрузки должна быть не меньше даты документа ""%Date%""';
							|en = 'Shipment date cannot be less than document date ""%Date%""'; fa = 'Shipment date cannot be less than document date ""%Date%""';
							|it = 'La data della spedizione non deve essere inferiore alla data del documento ""%Date%""';
							|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%""';
							|tr = 'Sevkiyat tarihi, belgenin ""%Date%""tarihinden daha önce olmamalıdır'");
			ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
			
			CommonClientServer.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "DateOfShipment"),
				,
				Cancel);
			
		EndIf;
		
		OrdersServer.CheckDuplicatesOfRowCodesInTable(ThisObject,
			LineProducts_.RowCode,
			LineProducts_.LineNumber,
			MatchingLineCodes,
			Cancel);
		
	EndDo;
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	ContractIsBindingByAgreement = ToUseTermsOfSales And ValueIsFilled(Terms)
		And TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed");
		
	If Not ContractIsBindingByAgreement
		And Not BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal
		And Not BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale
		And Not (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent And Not ToUseTermsOfSales) Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	
	DeliveryIsApplicable =
		(GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(BusinessOperation)
			And GoodsDeliveryClientServer.UsedDelivery());
	If Not Partner.IsEmpty()
		And DeliveryIsApplicable
		And Organization <> Catalogs.Companies.ManagementCompany Then
		
		DeliveryVerificationSettings = DocumentDeliveryVerificationSettings();
		GoodsDelivery.CheckCompletionOfDeliveryDetails(DeliveryVerificationSettings, NotCheckedAttributeArray, Cancel);
		
	Else
		
		NotCheckedAttributeArray.Add("DeliveryAddress");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		NotCheckedAttributeArray.Add("DeliveryMethod");
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("SpecialTransportationConditionsDescription");
		
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	CheckChangesInBusinessOperations(Cancel);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	DocumentAmount = GetSumOfOrderedRows();
	ReturnablePackagingAmount = GetReturnTareAmount();
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	
	If Status <> Enums.SalesOrderStatuses.NotApproved And Not AllLinesAreCanceled Then
		
		SalesServer.CheckShipmentBan(Partner, Cancel);
		
	EndIf;
	
	SalesOrderLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	SalesOrderLocalization.Posting(ThisObject, Cancel, PostingMode);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	InformationRegisters.AssemblyAndDeliveryStatuses.RecordStatusFromOrder(Ref, Cancel);
	
	SalesServer.PerformOrderControlAfterConducting(Ref, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	SalesOrderLocalization.UndoPosting(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	InformationRegisters.AssemblyAndDeliveryStatuses.RecordStatusFromOrder(Ref, Cancel, True);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status                 = Enums.SalesOrderStatuses.EmptyRef();
	DateOfShipment           = Date(1,1,1);
	ApprovalDate       = Date(1,1,1);
	MaximumRowCode  = 0;
	Approved             = False;
	DocumentBasis      = Undefined;
	NumberAccordingToCustomerData   = "";
	DateAccordingToInformationFromCustomer    = Date(1,1,1);
	Purpose             = Undefined;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	If Common.ObjectAttributeValue(Contract, "Status") = Enums.CounterpartyContractStatuses.Closed Then
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	ShipmentDateInLine = Date(1,1,1);
	If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True);
		If SalesTermsAndConditions.AgreementStatus <> Enums.StatusesOfTermsOfSales.Closed Then
			If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays) And Not ThisIsOrderAsInvoice Then
				ShipmentDateInLine = TMCommonUseClientServer.CalculatePeriodEndDate(
					CurrentSessionDate(),
					Enums.Periodicity.Day,
					SalesTermsAndConditions.DeliveryPeriodDays) + 1;
			EndIf;
		Else
			Terms = Undefined;
		EndIf;
	EndIf;
	
	If NotShipInInstallments Then
		DateOfShipment = ShipmentDateInLine;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ConsignmentSales25 = SalesServer.ThisIsContractForNewCommission(Contract);
	Else
		ConsignmentSales25 = False;
	EndIf;
	
	If ConsignmentSales25 Or BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		ToReturnReusablePackage      = False;
		ReusablePackageReturnCycleLength = 0;
		PackageDepositIsRequired           = False;
	EndIf;

	For Each TSRow In Goods Do
		
		TSRow.RowCode      = 0;
		TSRow.DateOfShipment   = ShipmentDateInLine;
		TSRow.Canceled = False;
		TSRow.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.EmptyRef();
		
	EndDo;
	
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "Goods", True,,True);
	
	For Each TSRow In Goods Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;

	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	SalesOrderLocalization.OnCopy(ThisObject, CopiedObject);

	Author = Users.AuthorizedUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	Partner = Basis;
	SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
	If GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfSaleTransaction(Basis)
	
	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	CommercialProposalForCustomer.Ref AS Ref
		|INTO TT_CommercialProposals
		|FROM
		|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
		|WHERE
		|	CommercialProposalForCustomer.SalesOpportunity = &Basis
		|	AND NOT CommercialProposalForCustomer.DeletionMark
		|	AND CommercialProposalForCustomer.Posted
		|	AND CommercialProposalForCustomer.Status = VALUE(Enum.StatusesOfCommercialProposalsForCustomers.Valid)
		|
		|ORDER BY
		|	CommercialProposalForCustomer.PointInTime DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
		|	SalesOpportunitiesToCustomer.Partner AS Partner,
		|	SalesOpportunitiesToCustomer.CustomerTermsOfSales AS Terms,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson AS ContactPerson,
		|	ISNULL(TT_CommercialProposals.Ref, UNDEFINED) AS CommercialProposal
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
		|		ON (SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|		LEFT JOIN TT_CommercialProposals AS TT_CommercialProposals
		|		ON (TRUE)
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &Basis");
		
	Query.SetParameter("Basis",Basis);
		
	Selection = Query.Execute().Select();
	
	Selection.Next();
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Partner);
	FillPropertyValues(ThisObject, Selection);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		If ValueIsFilled(Terms) Then
			FillInTermsOfSalesUnderAgreement(Not ValueIsFilled(Selection.CommercialProposal));
		Else
			FillInDefaultSalesConditions();
		EndIf;
	EndIf;
	
	// Add data from the last commercial offer
	If ValueIsFilled(Selection.CommercialProposal) Then
		Sales.WhenProcessingCustomerOrderFilling(ThisObject, Selection.CommercialProposal, True);
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	CustomerTermsOfSales.Ref         AS Terms,
		|	CustomerTermsOfSales.Partner        AS Partner,
		|	CustomerTermsOfSales.ContactPerson AS ContactPerson,
		|	TRUE                             AS NotShipInInstallments,
		|
		|	CustomerTermsOfSales.Status      AS DocumentStatus,
		|	CASE
		|		WHEN
		|			CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	CustomerTermsOfSales.Standard_ AS ThereAreErrorsTypical,
		|	CustomerTermsOfSales.LineOfBusiness AS LineOfBusiness
		|
		|FROM
		|	Catalog.TermsOfSale AS CustomerTermsOfSales
		|WHERE
		|	CustomerTermsOfSales.Ref = &DocumentBasis
		|");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
		
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfSales.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(Selection.ThereAreErrorsTypical);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.Terms,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	FillInTermsOfSalesUnderAgreement();

EndProcedure

Procedure FillInDocumentBasedOnTaskToSalesRepresentative(Val Basis)
	
	Query = New Query(
		"SELECT
		|	JobForSalesRepresentative.Ref AS DocumentBasis,
		|	JobForSalesRepresentative.Organization AS Organization,
		|	JobForSalesRepresentative.Partner AS Partner,
		|	JobForSalesRepresentative.Counterparty AS Counterparty,
		|	JobForSalesRepresentative.Contract AS Contract,
		|	JobForSalesRepresentative.Terms AS Terms,
		|	JobForSalesRepresentative.Terms.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
		|	JobForSalesRepresentative.Currency AS Currency,
		|	JobForSalesRepresentative.PriceIncludesVAT AS PriceIncludesVAT,
		|	JobForSalesRepresentative.PaymentSchedule AS PaymentSchedule,
		|	JobForSalesRepresentative.Warehouse AS Warehouse,
		|	JobForSalesRepresentative.PaymentMethod AS PaymentMethod,
		|	CASE WHEN JobForSalesRepresentative.NotShipInInstallments THEN
		|			JobForSalesRepresentative.RequestShipmentOn
		|		ELSE
		|			DATETIME(1, 1, 1)
		|		END AS DateOfShipment,
		|	JobForSalesRepresentative.NotShipInInstallments AS NotShipInInstallments,
		|	JobForSalesRepresentative.Status AS DocumentStatus,
		|	JobForSalesRepresentative.VATTaxation AS VATTaxation,
		|	JobForSalesRepresentative.BusinessOperation AS BusinessOperation,
		|	JobForSalesRepresentative.ReusablePackageFillingStatus AS ReusablePackageFillingStatus,
		|	JobForSalesRepresentative.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	JobForSalesRepresentative.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	JobForSalesRepresentative.PackageDepositIsRequired AS PackageDepositIsRequired,
		|	CASE
		|		WHEN JobForSalesRepresentative.Status = VALUE(Enum.SalesRepresentativeTaskStatuses.Processed_)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	JobForSalesRepresentative.Goods.(
		|		Products AS Products,
		|		Characteristic AS Characteristic,
		|		Count AS Count,
		|		Package AS Package,
		|		NumberOfPackages AS NumberOfPackages,
		|		Price AS Price,
		|		Sum AS Sum,
		|		PriceKind AS PriceKind,
		|		VATRate AS VATRate,
		|		VATAmount AS VATAmount,
		|		AmountIncludingVAT AS AmountIncludingVAT,
		|		PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
		|		ManualDiscount AS ManualDiscount,
		|		CancellationReason AS CancellationReason,
		|		Content AS Content,
		|		CASE
		|			WHEN JobForSalesRepresentative.Goods.CancellationReason = VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef)
		|				THEN FALSE
		|			ELSE TRUE
		|		END AS Canceled,
		|		CASE
		|			WHEN JobForSalesRepresentative.Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|				THEN VALUE(Catalog.Warehouses.EmptyRef)
		|			ELSE JobForSalesRepresentative.Warehouse
		|		END AS Warehouse
		|	) AS Goods,
		|	JobForSalesRepresentative.PaymentScheduleSteps.(
		|		PaymentOption AS PaymentOption,
		|		CalculateFrom AS CalculateFrom,
		|		PaymentDate AS PaymentDate,
		|		PaymentPercentage AS PaymentPercentage,
		|		PaymentAmount AS PaymentAmount,
		|		PackageDepositPercentage AS PackageDepositPercentage,
		|		PackageDepositValue AS PackageDepositValue,
		|		LineNumber AS LineNumber
		|	) AS PaymentScheduleSteps
		|FROM
		|	Document.JobForSalesRepresentative AS JobForSalesRepresentative
		|WHERE
		|	JobForSalesRepresentative.Ref = &Basis");
	
	Query.SetParameter("Basis",Basis);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	Selection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.SalesRepresentativeTaskStatuses.Processed_);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Selection.DocumentBasis,
		Selection.DocumentStatus,
		,
		Selection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, Selection);
	
	If Not ValueIsFilled(Contract) Then
		Contract = SalesServer.GetDefaultContract(ThisObject, BusinessOperation, Currency);
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract, BankAccount, CounterpartyBankAccount);
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.SalesOrderStatuses.NotApproved;
	EndIf;
	
	GoodsTable = Selection.Goods.Unload();
	
	FilterParameters = New Structure();
	FilterParameters.Insert("Count",0);
	
	// Find and delete rows with zero number from the table
	NullLines = GoodsTable.FindRows(FilterParameters);
	
	For Each CurItem In NullLines Do
		GoodsTable.Delete(CurItem);
	EndDo;
	
	Goods.Load(GoodsTable);

	ParametersStructure1 = New Structure;
	ParametersStructure1.Insert("ApplyToObject",                True);
	ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
	ParametersStructure1.Insert("RestoreManagedDiscounts", False);
	ParametersStructure1.Insert("ManagedDiscounts", Undefined);
	
	DiscountsMarkupsServer.Calculate(ThisObject, ParametersStructure1);
	DiscountsAreCalculated = True;
	
	TableOfPaymentStages = Selection.PaymentScheduleSteps.Unload();
	
	// If the stages of payment schedules are filled in the task, we will copy them
	If TableOfPaymentStages.Count() > 0 Then
		PaymentScheduleSteps.Load(TableOfPaymentStages);
	EndIf;
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		SalesServer.CheckPossibilityOfEnteringBasedOnClientSPartner(Partner, ThisObject);
		If FillingData.Property("Counterparty")
			And TypeOf(FillingData.Counterparty) = Type("CatalogRef.Counterparties") Then
			Counterparty = FillingData.Counterparty;
		EndIf;
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
		
	ElsIf FillingData.Property("SalesOpportunity") Then
		
		FillInDocumentOnBasisOfSaleTransaction(FillingData.SalesOpportunity);
		
	EndIf;
	If Not ValueIsFilled(Organization)
		And FillingData.Property("Organization")
		And TypeOf(FillingData.Organization) = Type("CatalogRef.Companies") Then
		Organization = FillingData.Organization;
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	ThisIsOrderAsInvoice = Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
		
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	ParametersOfAccount.OffsettingAccount = BankAccount;
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization    	= Organization;
	ParametersStructure.PaymentMethod 	= PaymentMethod;
	ParametersStructure.CashAccount 			= CashAccount;
	ParametersStructure.Individual	= Courier;
	CashAccount                     = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		
	Warehouse                     = SettingsValueCached.GetDefaultWarehouse(Warehouse,
		GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));
	Priority                 = SettingsValueCached.GetDefaultPriority(Priority);
	NotShipInInstallments        = True;
	If ThisIsOrderAsInvoice Then
		Status = Enums.SalesOrderStatuses.NotApproved;
	Else
		Status = Enums.SalesOrderStatuses.ToSupply;
		If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
			DateOfShipment = CurrentSessionDate();
		EndIf;
	EndIf; 
	
	StructureOfActions = New Structure();
	DocumentParameters = Documents.SalesOrder.DocumentParametersForSoftwareActions(ThisObject);
	StringFields_ = "SupplyOption";
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, Undefined);
	
	FillParameters = Documents.SalesOrder.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, True);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
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
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") And Not ValueIsFilled(DocumentBasis) Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(BankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(BankAccount), Undefined, BankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(BankAccount) Then
		ParametersOfAccount = OrganizationSDefaultAccountParameters();
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
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

#Region Delivery

Function WarehousesUsedForDelivery()
	
	Result = New Array; // Array of CatalogRef.Warehouses
	
	If Not DeliveryIsRequired Then
		Return Result;
	EndIf;
	
	SearchParameters = New Structure;
	SearchParameters.Insert("Canceled", False);
	TableOfGoods = Goods.Unload(SearchParameters, "Products, Warehouse");
	
	Query = New Query;
	RequestText_1 =
	"SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Warehouse AS Warehouse
	|INTO TTData
	|FROM
	|	&GoodsTable AS GoodsTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTData.Warehouse AS Warehouse
	|FROM
	|	TTData AS TTData
	|WHERE
	|	CAST(TTData.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)";
	Query.Text = RequestText_1;
	Query.SetParameter("GoodsTable", TableOfGoods);
	
	If Not Warehouse.IsEmpty() Then
		
		SetPrivilegedMode(True);
		IsFolder = Common.ObjectAttributeValue(Warehouse, "IsFolder");
		SetPrivilegedMode(False);
		If Not IsFolder Then
			Result.Add(Warehouse);
		EndIf;
		
	EndIf;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result.Add(Selection.Warehouse);
	EndDo;
	
	Result = CommonClientServer.CollapseArray(Result);
	
	Return Result;
	
EndFunction

Function DocumentDeliveryVerificationSettings()
	
	DeliveryVerificationSettings = GoodsDelivery.NewSettingsForCheckingUseOfDeliveryDetails();
	DeliveryVerificationSettings.DeliveryIsRequired = DeliveryIsRequired;
	DeliveryVerificationSettings.DocumentObject = ThisObject;
	DeliveryVerificationSettings.OwnerOfDeliveryPoints = Partner;
	
	If DeliveryIsRequired Then
		DeliveryVerificationSettings.DeliveryWarehouses = WarehousesUsedForDelivery();
	EndIf;
	
	If DeliveryIsRequired
		And DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("Canceled", False);
		GoodsFieldNames = "LineNumber, Products, Characteristic, Series, RowCode";
		TableOfGoods = Goods.Unload(FilterParameters, GoodsFieldNames);
		
		DeliveryTable = GoodsToDeliver.Unload();
		
		Query = New Query;
		QueryText =
		"SELECT
		|	TableOfGoods.LineNumber AS LineNumber,
		|	TableOfGoods.RowCode AS RowCode,
		|	TableOfGoods.Products AS Products,
		|	TableOfGoods.Characteristic AS Characteristic,
		|	TableOfGoods.Series AS Series
		|INTO TTTableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsToDeliver.LineNumber AS LineNumber,
		|	GoodsToDeliver.RowCode AS RowCode,
		|	GoodsToDeliver.DeliveryMethod AS DeliveryMethod,
		|	GoodsToDeliver.DeliveryPoint AS DeliveryPoint,
		|	GoodsToDeliver.DeliveryZone AS DeliveryZone,
		|	GoodsToDeliver.DeliveryToCarrier AS DeliveryToCarrier,
		|	GoodsToDeliver.Carrier AS Carrier,
		|	GoodsToDeliver.CarrierDeliveryPoint AS CarrierDeliveryPoint,
		|	GoodsToDeliver.CarrierSDeliveryArea AS CarrierSDeliveryArea,
		|	GoodsToDeliver.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	GoodsToDeliver.DeliveryTimeTo AS DeliveryTimeTo,
		|	GoodsToDeliver.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	GoodsToDeliver.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	GoodsToDeliver.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
		|INTO TTDeliveryTable
		|FROM
		|	&DeliveryTable AS GoodsToDeliver
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTTableOfGoods.LineNumber AS DocumentRowNumber,
		|	TTTableOfGoods.RowCode AS RowCode,
		|	TTTableOfGoods.Products AS Products,
		|	TTTableOfGoods.Characteristic AS Characteristic,
		|	TTTableOfGoods.Series AS Series,
		|	ISNULL(TTDeliveryTable.DeliveryMethod, VALUE(Enum.TransportMethods25.OwnDelivery)) AS DeliveryMethod,
		|	ISNULL(TTDeliveryTable.DeliveryPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS DeliveryPoint,
		|	ISNULL(TTDeliveryTable.DeliveryZone, VALUE(Catalog.DeliveryZones.EmptyRef)) AS DeliveryZone,
		|	ISNULL(TTDeliveryTable.DeliveryToCarrier, FALSE) AS DeliveryToCarrier,
		|	ISNULL(TTDeliveryTable.Carrier, VALUE(Catalog.Partners.EmptyRef)) AS Carrier,
		|	ISNULL(TTDeliveryTable.CarrierDeliveryPoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS CarrierDeliveryPoint,
		|	ISNULL(TTDeliveryTable.CarrierSDeliveryArea, VALUE(Catalog.DeliveryZones.EmptyRef)) AS CarrierSDeliveryArea,
		|	ISNULL(TTDeliveryTable.DeliveryTimeFrom, DATETIME(1, 1, 1)) AS DeliveryTimeFrom,
		|	ISNULL(TTDeliveryTable.DeliveryTimeTo, DATETIME(1, 1, 1)) AS DeliveryTimeTo,
		|	ISNULL(TTDeliveryTable.AdditionalDeliveryInformation, """") AS AdditionalDeliveryInformation,
		|	ISNULL(TTDeliveryTable.SpecialTransportationConditions, FALSE) AS SpecialTransportationConditions,
		|	ISNULL(TTDeliveryTable.SpecialTransportationConditionsDescription, """") AS SpecialTransportationConditionsDescription
		|FROM
		|	TTTableOfGoods AS TTTableOfGoods
		|		LEFT JOIN TTDeliveryTable AS TTDeliveryTable
		|		ON TTTableOfGoods.RowCode = TTDeliveryTable.RowCode
		|WHERE
		|	CAST(TTTableOfGoods.Products AS Catalog.Products).ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|
		|ORDER BY
		|	TTTableOfGoods.LineNumber";
		Query.Text = QueryText;
		Query.SetParameter("TableOfGoods", TableOfGoods);
		Query.SetParameter("DeliveryTable", DeliveryTable);
		Table = Query.Execute().Unload();
		DeliveryVerificationSettings.DeliveryGoodsTable = Table;
		
	EndIf;
	
	Return DeliveryVerificationSettings;
	
EndFunction

Procedure DeliveryBeforeWrite(Cancel, Val WriteMode)
	
	GoodsDelivery.BeforeWrite(ThisObject, Cancel, WriteMode);
	DeliveryVerificationSettings = DocumentDeliveryVerificationSettings();
	
	DeliveryIsApplicable =
		(GoodsDeliveryClientServer.BusinessTransactionIsInvolvedInDelivery(BusinessOperation)
			And DeliveryIsRequired)
		And Organization <> Catalogs.Companies.ManagementCompany
		And GoodsDeliveryClientServer.UsedDelivery();
	
	If Not DeliveryIsApplicable Then
		
		DeliveryIsRequired = False;
		DeliveryVerificationSettings.DeliveryIsRequired = DeliveryIsRequired;
		GoodsDelivery.ClearUnusedDeliveryFields(DeliveryVerificationSettings, Cancel);
		
	ElsIf Partner.IsEmpty() Then
		
		DeliveryAddress = "";
		DeliveryAddressValue = "";
		DeliveryAddressFieldValues = "";
		
	ElsIf Not Partner.IsEmpty() Then
		
		ToOutputErrors =
			(WriteMode = DocumentWriteMode.Posting
				And DeliveryPlanning = Enums.DeliveryPlanningKinds.ByCurrentDocument);
		
		GoodsDelivery.UpdateDeliveryFieldData(DeliveryVerificationSettings, ToOutputErrors, Cancel);
		GoodsDelivery.UpdateDeliveryWarehouseDetails(DeliveryVerificationSettings, ToOutputErrors, Cancel);
		
		If DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
			
			FieldNamesOfDeliveryPointAddresses = "Address, AddressValue, FieldValueAddress";
			DeliveryPointAddressFields = Common.ObjectAttributesValues(DeliveryPoint, FieldNamesOfDeliveryPointAddresses);
			
			DeliveryAddress = DeliveryPointAddressFields.Address;
			DeliveryAddressValue = DeliveryPointAddressFields.AddressValue;
			DeliveryAddressFieldValues = DeliveryPointAddressFields.FieldValueAddress;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure CheckChangesInBusinessOperations(Cancel)
	
	TransferOperations_ = SalesServer.GoodsTransferOperations();
	
	If Not IsNew()
		And TransferOperations_.Find(BusinessOperation) <> Undefined Then
	
		Query = New Query("
		|SELECT
		|	CustomersARAPAccounting.SumExpense AS PayAmount
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Turnovers(,,Period,
		|		ARAPObject = &ARAPObject
		|	) AS CustomersARAPAccounting
		|
		|	INNER JOIN
		|		Document.SalesOrder AS DocumentData
		|	ON
		|		DocumentData.Ref = &Ref
		|		AND DocumentData.BusinessOperation <> &BusinessOperation
		|WHERE
		|	CustomersARAPAccounting.SumExpense > 0
		|");
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("BusinessOperation", BusinessOperation);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đơn hàng của khách đã được thanh toán. Không thể lập giao dịch %1';
					|ru = 'Заказ клиента оплачен. Нельзя устанавливать операцию %1';
					|en = 'Sales order is paid. Cannot set transaction %1'; fa = 'Sales order is paid. Cannot set transaction %1';
					|it = 'Ordine del cliente è stato pagato. Impossibile impostare l''operazione %1';
					|pl = 'Zamówienie sprzedaży opłacono. Nie można ustawiać operację %1';
					|tr = 'Müşterinin siparişi için ödeme yapıldı. Bir %1işlemi ayarlayamazsınız '"),
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

Function GetReturnTareAmount()
	
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

#EndRegion

#EndRegion

#EndIf
#EndIf
