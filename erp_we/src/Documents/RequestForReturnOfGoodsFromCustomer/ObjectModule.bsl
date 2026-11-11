#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the amount of undelivered request lines
//
// Parameters:
//	OnlyDepositForContainer - Boolean - indicates a Deposit for the container.
//
// Returns:
//	Number - the sum of the replacement lines.
Function GetSumOfReplacementStrings(OnlyDepositForContainer = False) Export
	
	SumOfReplacementRows = 0;
	
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
	
	Query.SetParameter("Goods", SubstituteGoods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	Query.SetParameter("OnlyDepositForContainer", OnlyDepositForContainer);
	
	Upload0 = Query.Execute().Unload();
	SumOfReplacementRows = Upload0[0].AmountIncludingVAT;
	
	Return SumOfReplacementRows;
	
EndFunction

// Calculates the number of undelivered request lines
//
// Returns:
//	Number - the number of undelivered rows.
//
Function GetNumberOfRowsOrdered() Export
	
	FoundRows = SubstituteGoods.FindRows(New Structure("Canceled", False));
	Return FoundRows.Count();
	
EndFunction

// Fills in the terms of sales in the customer's order
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in
//	FillInDetailsOfBase - Boolean - indicates whether the base's audit details are filled in.
//
Procedure FillIn_TermsOfSales(Val SalesTermsAndConditions, Val FillInDetailsOfBase = True) Export
	
	If SalesTermsAndConditions = Undefined Then
		Return;
	EndIf;
	
	If FillInDetailsOfBase Then
		
		If ValueIsFilled(SalesTermsAndConditions.Currency) Then
			Currency = SalesTermsAndConditions.Currency;
		EndIf;
		
		PriceIncludesVAT      = SalesTermsAndConditions.PriceIncludesVAT;
		
		If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
			Warehouse = SalesTermsAndConditions.Warehouse;
		EndIf;
		
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		BusinessOperation = SalesServer.GetRefundTransactionForSale(SalesTermsAndConditions.BusinessOperation);
		ToReturnReusablePackage = SalesTermsAndConditions.ReturnReusablePackage;
		ReusablePackageReturnCycleLength = SalesTermsAndConditions.ReusablePackageReturnCycleLength;
		PackageDepositIsRequired = SalesTermsAndConditions.PackageDepositIsRequired;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		UseCustomerContracts   = GetFunctionalOption("UseCustomerContracts");
		SelectConsignmentSalesVersion = GetFunctionalOption("SelectConsignmentSalesVersion");
		OnlyConsignmentSales25      = UseCustomerContracts 
			And (GetFunctionalOption("OnlyConsignmentSales25")
				Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion);
			
		ConsignmentSales25 = False;
		If OnlyConsignmentSales25 Then
			ConsignmentSales25 = True;
		ElsIf ValueIsFilled(Terms) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Terms, "ConsignmentSales25");
		ElsIf ValueIsFilled(Contract) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Contract, "ConsignmentSales25");
		EndIf;
			
		If ConsignmentSales25 Then
			ToReturnReusablePackage      = False;
			ReusablePackageReturnCycleLength = 0;
			PackageDepositIsRequired           = False;
		EndIf;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
			ToReturnReusablePackage      = False;
			ReusablePackageReturnCycleLength = 0;
			PackageDepositIsRequired           = False;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.PaymentSchedule) Then
		PaymentSchedule = SalesTermsAndConditions.PaymentSchedule;
	EndIf;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization    			= Organization;
		ParametersStructure.LineOfBusiness = LineOfBusiness;
		ParametersStructure.PaymentMethod 			= PaymentMethod;
		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);

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
	
	ContractBusinessTransaction = SelfServiceClientServer.ContractBusinessTransaction(BusinessOperation);
	
	If SalesTermsAndConditions.ContractsAreUsed <> Undefined And SalesTermsAndConditions.ContractsAreUsed Then
		
		If ValueIsFilled(ContractBusinessTransaction) Then
			ConsignmentSales25 = Undefined;
			If ValueIsFilled(Terms)
				And Common.ObjectAttributeValue(Terms,"BusinessOperation") = Enums.BusinessTransactions.TransferToCommissionAgent Then
				ConsignmentSales25 = Common.ObjectAttributeValue(Terms,"ConsignmentSales25");
			ElsIf ContractBusinessTransaction = Enums.BusinessTransactions.TransferToCommissionAgent Then
				ConsignmentSales25 = Not GetFunctionalOption("ToUseTermsOfSales");
			EndIf;
			
			Contract = SalesServer.GetDefaultContract(ThisObject,
																ContractBusinessTransaction,
																Currency,
																,
																ConsignmentSales25);
		EndIf;
		
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
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays) And Not ThisIsOrderAsInvoice Then
		ShipmentDateInLine = Date(1,1,1);
		StartDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
		ShipmentDateInLine = TMCommonUseClientServer.CalculatePeriodEndDate(StartDate, Enums.Periodicity.Day, SalesTermsAndConditions.DeliveryPeriodDays) + 1;
		If NotShipInInstallments Then
			DateOfShipment = ShipmentDateInLine;
		EndIf;
		
		For Each TSRow In SubstituteGoods Do
			TSRow.DateOfShipment = ShipmentDateInLine;
		EndDo;
		
	EndIf;
	
EndProcedure

// Fills in the default sales terms in the customer's order
//
// Parameters:
//  RecalculatePrices_ - Boolean - re-fill prices.
//
Procedure FillInDefaultSalesConditions(RecalculatePrices_ = True) Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("SelectedAgreement", Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
		BusinessTransactions = SalesServer.GetBusinessTransactionOfRefundAgreement(BusinessOperation);
		FilterParameters.Insert("BusinessTransactions", BusinessTransactions);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True); 
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner, FilterParameters);
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
				VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				
				If ToUseTermsOfSales And RecalculatePrices_ Then
					
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					FillParameters = New Structure;
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind");
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					
					EnterprisePricesFillingServer.FillInPrices(
						ReturnedGoods,
						, // Array of rows or selection structure
						FillParameters,
						StructureOfActions);
						
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
						SubstituteGoods,
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
	
	If Not ToUseTermsOfSales Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
		
EndProcedure

// Fills in the terms of sale under the agreement in the refund request
//
// Parameters:
//	FillInReplacementPrices - Boolean - Indicates whether prices are recalculated.
//
Procedure FillInTermsOfSalesUnderAgreement(FillInReplacementPrices = True) Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	AccountingPriceType = Catalogs.TypesOfPrices.EmptyRef();
	If SalesTermsAndConditions.NewCommissionScheme Then
		// The price type in the "New Commission" is used from the Contract 
		AccountingPriceType = Common.ObjectAttributeValue(Contract, "PriceTypeAccountingPriceType");
	EndIf;
	
	FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	FillParameters = New Structure;
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Terms", Terms);
	If SalesTermsAndConditions.NewCommissionScheme Then
		FillParameters.Insert("PriceKind", AccountingPriceType);
	EndIf;
	
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	SaleDate = ?(ValueIsFilled(DocumentSalesOfGoodsAndServices), Common.ObjectAttributeValue(DocumentSalesOfGoodsAndServices, "Date"), Date);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	ParametersFillInVATRate.Date = SaleDate;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(ThisObject);
	ParametersFillInVATRate.Date = SaleDate;
	StructureOfActions.Insert("FillInVATRateByPriceType", ParametersFillInVATRate);
	
	EnterprisePricesFillingServer.FillInPrices(
		ReturnedGoods,
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
		
	If FillInReplacementPrices Then
		FillParameters = New Structure;
		FillParameters.Insert("Date", Date);
		FillParameters.Insert("Organization", Organization);
		FillParameters.Insert("Currency", Currency);
		FillParameters.Insert("Terms", Terms);
		If SalesTermsAndConditions.NewCommissionScheme Then
			FillParameters.Insert("PriceKind", AccountingPriceType);
		EndIf;
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
			SubstituteGoods,
			, // Array of rows or selection structure
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
	
	MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers[NewStatus];
	
	If MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon
		Or MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected Then
		
		If Approved Then
			Approved = False;
		EndIf;
		
	ElsIf MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn
		Or MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
		Or MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
		Or MeaningOfNewStatus = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed Then
		
		If ReturnedGoods.Count() > 0 Then
			
			If PurchasesServerCall.ReceiptDateIsBlank(ThisObject, "ReturnedGoods") Then
				If ValueIsFilled(RequestedDeliveryDate) And RequestedDeliveryDate >= Date Then
					DateOfReceipt = RequestedDeliveryDate;
				Else
					DateOfReceipt = CurrentSessionDate();
				EndIf;
			EndIf;
			
			RowsToProcess = New Array();
			For Each TSRow In ReturnedGoods Do
				If OneDateReceipt Or Not ValueIsFilled(TSRow.DateOfReceipt) Then
					TSRow.DateOfReceipt = DateOfReceipt;
					RowsToProcess.Add(TSRow);
				EndIf;
			EndDo;
			CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
			StructureOfActions = New Structure();
			StructureOfActions.Insert("FillInCheckQualityDateOfQualityConfirmation",
				CacheQualityControl);
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				RowsToProcess,
				StructureOfActions,
				ReturnedGoods);
			
		EndIf;
		
	EndIf;
	
	If AdditionalParameters <> Undefined Then
		
		OrderChanged = OrdersServer.AdjustOrderLines(ThisObject, AdditionalParameters);
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RequestForReturnOfGoodsFromCustomer);
	
	ThisIsOrderFromWarehouse = Not ThisIsOrderAsInvoice
		And Not GetFunctionalOption("UseShipmentByRowsInSalesOrder");
	
	If ThisIsOrderFromWarehouse Then
		StructureOfActions = New Structure();
		DocumentParameters = Documents.RequestForReturnOfGoodsFromCustomer.DocumentParametersForSoftwareActions(ThisObject);
		StringFields_ = "SupplyOption";
		ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
		BatchProcessingOfTablePartServer.TreatTS(SubstituteGoods, StructureOfActions, Undefined);
	EndIf;
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Substitutes_);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters.Returned_);
	
	Return CheckFilling();
	
EndFunction

// Cancels all lines for which the refund was not documented
//
// Parameters:
//	ParametersStructure - Structure
//
// Returns:
//	Number - The number of canceled rows.
//
Function AdjustOrderLines(ParametersStructure) Export
	
	NumberOfCanceledLines = 0;
	
	ReturnStructure = New Structure("RowsCount",0);
	
	CheckBalance             = ParametersStructure.CheckBalance;
	CancelUnprocessedLines = ParametersStructure.CancelUnprocessedLines;
	CorrectMeasuringGoods  = ParametersStructure.AdjustTheMeasuredGoodsUponAcceptance;
	GoodsTable                = ThisObject[ParametersStructure.TabularSectionName];
	ReturnOnReceipt         = BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian;
	
	PropertiesOfCanceledRow = New Structure(
		"Canceled",
		True);
	
	If Not CheckBalance Then
		For Cnt = 0 To GoodsTable.Count() - 1 Do
			If Not GoodsTable[Cnt].Canceled Then
				FillPropertyValues(GoodsTable[Cnt], PropertiesOfCanceledRow);
				NumberOfCanceledLines = NumberOfCanceledLines + 1;
			EndIf;
		EndDo;
		ReturnStructure.RowsCount = NumberOfCanceledLines;
		Return ReturnStructure;
	EndIf;
	
	Query = New Query;
	If ReturnOnReceipt Then
		Query.Text = QueryTextForItemsToBeReceived();
	Else
		Query.Text = QueryTextForRequestsForReturnOfGoodsFromCustomers();
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"GoodsTable.Package",
		"GoodsTable.Products"));
	
	Query.SetParameter("GoodsTable",
		ReturnedGoods.Unload(,
			"LineNumber, RowCode, Warehouse, Products, Characteristic, Package,
			|Damage, ProductsRecordingAsReceived, CharacteristicRecordingAsReceived,
			|Count, AmountIncludingVAT, Canceled, Series"));
	
	Query.SetParameter("RequestForReturnOfGoodsFromCustomer", Ref);
	Query.SetParameter("DimensionalTypesOfUnits",
		Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits());
	Query.SetParameter("AllowableDeviationOfMeasuringGoodsShipmentAndReceiving",
		Constants.AllowableDeviationOfMeasuringGoodsShipmentAndReceiving.Get() / 100);
	
	SpeedLimits = TMCommonUse.BoundariesOfRegisterTurns(
		"ShipmentAndReturnReferences",
		"ReferenceOrder = &RequestForReturnOfGoodsFromCustomer",
		Query.Parameters);
	
	Query.SetParameter("StartPeriod_", SpeedLimits.MinDate);
	Query.SetParameter("ConPeriod", SpeedLimits.MaxDate);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	If Result[4].IsEmpty() And Result[5].IsEmpty() Then
		Return ReturnStructure;
	EndIf;

	AcceptableDeviations = Result[1].Unload();
	Selection = Result[4].Select();
	SelectingCancellationsWithoutChecks = Result[5].Select();

	While SelectingCancellationsWithoutChecks.Next() Do
		
		String = GoodsTable[SelectingCancellationsWithoutChecks.LineNumber-1];
			
		FillPropertyValues(String, PropertiesOfCanceledRow);
		NumberOfCanceledLines = NumberOfCanceledLines + 1;
			
		Continue;
			
	EndDo;
	
	ItemSearchParameters = New Structure;
	SearchParametersForInventoryItem = New Structure;
	
	While Selection.Next() Do
		
		ItemSearchParameters = New Structure;
		ItemSearchParameters.Insert("Products", Selection.Products);
		ItemSearchParameters.Insert("Characteristic", Selection.Characteristic);
		ItemSearchParameters.Insert("Warehouse", Selection.Warehouse);
		If ReturnOnReceipt Then
			ItemSearchParameters.Insert("Series", Selection.Series);
		EndIf;
		ItemSearchParameters.Insert("Canceled", False);
		ItemSearchParameters.Insert("Damage", False);
		
		OrderLines_ = GoodsTable.FindRows(ItemSearchParameters);
		
		SearchParametersForInventoryItem.Insert("ProductsRecordingAsReceived", Selection.Products);
		SearchParametersForInventoryItem.Insert("CharacteristicRecordingAsReceived", Selection.Characteristic);
		SearchParametersForInventoryItem.Insert("Warehouse", Selection.Warehouse);
		If ReturnOnReceipt Then
			SearchParametersForInventoryItem.Insert("Series", Selection.Series);
		EndIf;
		SearchParametersForInventoryItem.Insert("Canceled", False);
		SearchParametersForInventoryItem.Insert("Damage", True);
		
		CommonClientServer.SupplementArray(OrderLines_, GoodsTable.FindRows(SearchParametersForInventoryItem));
		
		Deviation = Selection.ToRegisterBalance;
		
		For Cnt = 0 To OrderLines_.Count()-1 Do
			
			String = OrderLines_[Cnt];
			
			If Deviation = 0 Then
				Break;
			EndIf;
			
			DeviationSearchStructure = New Structure;
			DeviationSearchStructure.Insert("Products", String.Products);
			DeviationSearchStructure.Insert("Characteristic", String.Characteristic);
			DeviationSearchStructure.Insert("Warehouse", String.Warehouse);
			
			If ReturnOnReceipt Then
				DeviationSearchStructure.Insert("Series", String.Series);
			EndIf;
			
			ToleranceLines = AcceptableDeviations.FindRows(DeviationSearchStructure);
			If ToleranceLines.Count() > 0 
				And ToleranceLines[0].AllowableVariance > 0 Then
				AcceptableDeviation = ToleranceLines[0].AllowableVariance;
			Else
				AcceptableDeviation = 0;
			EndIf;
			
			PackagingFactor = ?(String.Count > 0, String.Count / String.NumberOfPackages, 1);
			
			If Deviation > 0 
				And (CancelUnprocessedLines Or (CorrectMeasuringGoods And AcceptableDeviation >= Deviation)) Then
				If String.Count <= Deviation Then
					FillPropertyValues(String, PropertiesOfCanceledRow);
					Deviation = Deviation - String.Count;
				ElsIf String.Count > 0 Then
					
					NewRow = ReturnedGoods.Add();
					FillPropertyValues(NewRow, String);
					FillPropertyValues(NewRow, PropertiesOfCanceledRow);
					NewRow.RowCode = 0;
					MinDeviation = Min(Deviation, String.Count);
					NewCount = String.Count - MinDeviation;
					
					String.Count              = NewCount;
					String.NumberOfPackages      = NewCount / PackagingFactor;
					NewRow.Count         = MinDeviation;
					NewRow.NumberOfPackages = MinDeviation / PackagingFactor;
					
					PriceManagementSystem.RecalculateAmountsInRow(String, False, False, False, PriceIncludesVAT);
					PriceManagementSystem.RecalculateAmountsInRow(NewRow, False, False, False, PriceIncludesVAT);
					
					Deviation = Deviation - NewRow.Count;
					
				EndIf;
			ElsIf Deviation < 0 And (CorrectMeasuringGoods And AcceptableDeviation >= Deviation * (-1)) Then 
				String.Count = String.Count + Deviation * (-1);
				String.NumberOfPackages = String.Count / PackagingFactor;;
				PriceManagementSystem.RecalculateAmountsInRow(String, False, False, False, PriceIncludesVAT);
			EndIf;
			
			NumberOfCanceledLines = NumberOfCanceledLines + 1;
			
		EndDo;
		
	EndDo;
	
	ReturnStructure.RowsCount = NumberOfCanceledLines;
	
	Return ReturnStructure;
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	Status                  = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.EmptyRef();
	RequestedDeliveryDate = Date(1,1,1);
	ApprovalDate        = Date(1,1,1);
	DateOfReceipt         = Date(1,1,1);
	DateOfShipment            = Date(1,1,1);
	Approved              = False;
	DocumentSalesOfGoodsAndServices      = Undefined;
	Purpose              = Undefined;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	
	SubstituteGoodsMaximumLineCode   = 0;
	ReturnedGoodsMaximumRowCode = 0;
	
	ShipmentDateInLine = Date(1,1,1);
	
	If GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms) Then
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
		If SalesTermsAndConditions.AgreementStatus <> Enums.StatusesOfTermsOfSales.Closed Then
			If ValueIsFilled(SalesTermsAndConditions.DeliveryPeriodDays) And Not ThisIsOrderAsInvoice Then
				StartDate = ?(ValueIsFilled(Date), Date, CurrentSessionDate());
				ShipmentDateInLine = TMCommonUseClientServer.CalculatePeriodEndDate(StartDate, Enums.Periodicity.Day, SalesTermsAndConditions.DeliveryPeriodDays) + 1;
			EndIf;
		Else
			Terms = Undefined;
		EndIf;
	EndIf;
	
	For Each TSRow In ReturnedGoods Do
		
		TSRow.RowCode = 0;
		TSRow.DateOfReceipt = Date(1,1,1);
		
	EndDo;
	
	If NotShipInInstallments Then
		DateOfShipment = ShipmentDateInLine;
	EndIf;
	
	For Each TSRow In SubstituteGoods Do
		
		TSRow.RowCode    = 0;
		TSRow.DateOfShipment = ShipmentDateInLine;
		TSRow.Canceled = False;
		TSRow.CancellationReason = Catalogs.ReasonsForSaleOrderCancellation.EmptyRef();
		
	EndDo;
	
	InitializeDocument();
	
	ReturnedBatch.Clear();
	
	DiscountsAreCalculated = False;
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "SubstituteGoods", True,,True);
	
	For Each TSRow In SubstituteGoods Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;

	ARAPAccountingServer.OnCopy(ThisObject);
		
	RequestForReturnOfGoodsFromCustomerLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.AuthorizedUser();
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	FilledInBasedOnDocument = False;
	
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		If FillingData.Property("FillInTransferredContainer") Then
			FillInDocumentOnBasisOfTransferredContainer(FillingData);
			FilledInBasedOnDocument = True;
		ElsIf FillingData.Property("DiscrepancyCertificate")
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.CustomerInvoice") Then
				FillInDocumentOnBasisOfActOfImplementation(FillingData);
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.TransferOfGoodsToBailee") Then
				FillInDocumentOnBasisOfActOfTransfer(FillingData);
			EndIf;
			
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
	ElsIf FillInDataType = Type("CatalogRef.Partners") Then
		FillInDocumentBasedOnPartner(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		FillInDocumentOnBasisOfSaleTransaction(FillingData);
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		FillInDocumentBasedOnSaleOfGoodsAndServices(FillingData);
		FilledInBasedOnDocument = True;
	ElsIf FillInDataType = Type("DocumentRef.TransferOfGoodsToBailee") Then
		FillInDocumentOnBasisOfTransferOfGoodsToCustodian(FillingData);
		FilledInBasedOnDocument = True;
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		UseCustomerContracts   = GetFunctionalOption("UseCustomerContracts");
		SelectConsignmentSalesVersion = GetFunctionalOption("SelectConsignmentSalesVersion");
		OnlyConsignmentSales25      = UseCustomerContracts 
			And (GetFunctionalOption("OnlyConsignmentSales25")
				Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion);
			
		ConsignmentSales25 = False;
		If OnlyConsignmentSales25 Then
			ConsignmentSales25 = True;
		ElsIf ValueIsFilled(Terms) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Terms, "ConsignmentSales25");
		ElsIf ValueIsFilled(Contract) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Contract, "ConsignmentSales25");
		EndIf;
			
		If ConsignmentSales25 Then
			ToReturnReusablePackage      = False;
			ReusablePackageReturnCycleLength = 0;
			PackageDepositIsRequired           = False;
		EndIf;
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	FillOutBankAccounts();
	
	Author = Users.AuthorizedUser();
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.ReturnOfGoodsFromCustomer;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	If Not FilledInBasedOnDocument Then
		InitializeSalesConditions();
	EndIf;
	
	ResponsiblePersonsServer.InstallManager(
		ThisObject, SalesServer.DocumentBasis(ThisObject, "DocumentSalesOfGoodsAndServices, ReturnedGoods.DocumentSalesOfGoodsAndServices"));
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	RequestForReturnOfGoodsFromCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	InitializeDocument(FillingData);

	If Not ValueIsFilled(Manager) Then
		Manager = SelfServiceServer.DefaultDocumentManager();
	EndIf;
	
	FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);
	
EndProcedure

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
			And ThisIsOrderAsInvoice And Status <> Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon Then
		
		ErrorText = NStr("vi = 'Đơn hàng này giống như hóa đơn cần có trạng thái ""Để thống nhất"".';
						|ru = 'Заказ как счет должен иметь статус ""На согласовании"".';
						|en = 'Order as a commercial invoice must have the ""Pending approval"" status.'; fa = 'Order as a commercial invoice must have the ""Pending approval"" status.';
						|it = 'Ordine come conto deve avere stato ""In negoziazione"".';
						|pl = 'Zamówienie jako rachunek powinno mieć status ""Na uzgodnieniu"".';
						|tr = 'Fatura olarak siparişin durumu ""Onay bekliyor"" olmalıdır.'");
		Common.MessageToUser(ErrorText, Ref, , , Cancel);
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn") Or
			Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply") Or
			Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip") Or
			Status = PredefinedValue("Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed") Then
			
			Documents.RequestForReturnOfGoodsFromCustomer.FillIn_BlankReceiptDates(ThisObject);
			
		EndIf;
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting 
		And GetFunctionalOption("UseDiscountsMarkupsInSales")
		And Not DiscountsAreCalculated
		And Not FillInPricesOfSubstituteGoodsByReturned
		And BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCommissionAgent")
		And BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.ReturnFromCustodian")
		And CompensationMethod = PredefinedValue("Enum.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods") 
		And SubstituteGoods.Count() > 0 Then
		
			Cancel = True;
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong chứng từ %1, chiết khấu tự động (tỷ suất lợi nhuận) không được tính. Không thể kết chuyển. Để tính chiết khấu tự động (tỷ suất lợi nhuận), hãy kết chuyển chứng từ từ mẫu.';
				|ru = 'В документе %1 не рассчитаны автоматические скидки (наценки). Проведение невозможно. Для расчёта автоматических скидок (наценок) проведите документ из формы документа.';
				|en = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.'; fa = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.';
				|it = 'Nel documento %1 gli sconti (sovraprezzi) automatici non sono calcolati. Impossibile registrare. Per calcolare automaticamente gli sconti (sovraprezzi) registrate il documento dal modulo del documento.';
				|pl = 'W dokumencie %1 nie obliczono automatycznych rabatów (marży). Zatwierdzenie jest niemożliwe. Aby obliczyć automatyczne rabaty (marże) zatwierdź dokument z formularza dokumentu.';
				|tr = 'Otomatik indirimler (marj) %1 belgesinde hesaplanmamıştır. Gerçekleştirilemez. Otomatik indirimleri (marj) hesaplamak için, belgeyi belge formundan çalıştırın.'"),
			Ref);
		
			Common.MessageToUser(
				ErrorText,
				Ref,
				,
				,
				Cancel);
		
	EndIf;
	
	RoundingParameters = ProductsServer.ParametersForRoundingNumberOfUnitProducts();
	RoundingParameters.TSName = "ReturnedGoods";
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		RoundingParameters.TSName = "SubstituteGoods";
		ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters);
	Else
		SubstituteGoods.Clear();
	EndIf;
	
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "ReturnedGoods", "ReturnedGoodsMaximumRowCode");
	OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "SubstituteGoods", "SubstituteGoodsMaximumLineCode");
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RequestForReturnOfGoodsFromCustomer);
	ProductsServer.ClearUnusedSeries(ThisObject,SeriesSpecificationParameters.Returned_);
	ProductsServer.ClearUnusedSeries(ThisObject,SeriesSpecificationParameters.Substitutes_);
	
	If GetFunctionalOption("UseGoodsQuality") Then
		ReturnOfSpoiledGoods = False;
		For Each RowOfTables In ReturnedGoods Do
			If RowOfTables.Damage Then
				ReturnOfSpoiledGoods = True;
				Break;
			EndIf;
		EndDo;
	EndIf;
		
	ExecutionScheduleInContract = False;
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByCounterpartyContracts
		And ValueIsFilled(Contract) Then
		ExecutionScheduleInContract = Common.ObjectAttributeValue(Contract, "ExecutionScheduleIsSpecified");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
		Or CompensationMethod <> Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods
		Or ExecutionScheduleInContract Then
		
		AmountPrepaymentBeforeGoodsIssue = 0;
		AmountOfPrepaymentBeforeShipment = 0;
		
	Else
		
		If Not PackageDepositIsRequired Then
			For Each PaymentStage In PaymentScheduleSteps Do
				PaymentStage.PackageDepositValue = 0;
			EndDo;
		EndIf;
		
	EndIf;
	
	DocumentAmount = GetDocumentAmount();
	
	If BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
		And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments
		And CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		
		SalesServer.FillInAdvancePrepaymentAmounts(ThisObject);
		
	EndIf;
	
	ReplacementAmount = GetSumOfReplacementStrings();
	ReturnablePackagingAmount = GetReturnTareAmount();
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	If ARAPObjectSettings <> Enums.ARAPObjectSettings.ByARAPDocuments Then
		PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	Else
		PaymentID = Undefined;
	EndIf;
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
		
	NewReceiptDate = Date(1,1,1);
	
	If ReturnedGoods.Count() > 0 Then
			
		If Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn Then
			
			If ReturnedGoods.Count() > 0 Then
				
				TableOfGoods = ReturnedGoods.Unload(, "DateOfReceipt");
				TableOfGoods.Sort("DateOfReceipt Asc");
				NewReceiptDate = TableOfGoods[0].DateOfReceipt;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	DateOfFirstReceipt = NewReceiptDate;
	
	If Not NotShipInInstallments Then
		NewShipmentDate = Date(1,1,1);
		
		If SubstituteGoods.Count() > 0 Then
			
		If Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply 
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed Then
				
				FilterParameters = New Structure;
				FilterParameters.Insert("Canceled", False);
				RequirementsForProvision = SubstituteGoods.FindRows(FilterParameters);
				
				If RequirementsForProvision.Count() > 0 Then
					
					TableOfRowsToProvide = SubstituteGoods.Unload(RequirementsForProvision, "DateOfShipment");
					TableOfRowsToProvide.Sort("DateOfShipment Asc");
					NewShipmentDate = TableOfRowsToProvide[0].DateOfShipment;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		DateOfShipment = NewShipmentDate;
		
	Else
		ProvisionInDocumentsServer.FillInShippingDatesInTable(DateOfShipment, SubstituteGoods, "DateOfShipment");
	EndIf;
	
	DocumentApproved = Approved;
	
	ArrayOfStatusesNotConsistent = New Array();
	ArrayOfStatusesNotConsistent.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon);
	ArrayOfStatusesNotConsistent.Add(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected);
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
		ThisObject,
		WriteMode,
		ArrayOfStatusesNotConsistent);
	
	// We will set the date of approval, if the document is agreed
	If Not DocumentApproved And Approved Then
		ApprovalDate = CurrentSessionDate();
	EndIf;
	
	// We will clear the details of the document that are not used for the business operation.
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		Department = Undefined;
		For Each LineReplacementProducts In SubstituteGoods Do
			LineReplacementProducts.PercentRateOfManualDiscount = Undefined;
			LineReplacementProducts.ManualDiscount = Undefined;
			LineReplacementProducts.PercentRateOfAutomaticDiscountMarkup = Undefined;
			LineReplacementProducts.DiscountMarkupAmount = Undefined;
		EndDo;
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		Contract = Undefined;
	EndIf;
	
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		CashRegisterReceipt = Undefined;
	EndIf;
	
	AttributesArray = New Array;
	If PaymentMethod <> Enums.PaymentForms.CashAccountPayment_ Then
		CashAccount = Undefined;
	EndIf;
	
	DestinationPattern = Documents.RequestForReturnOfGoodsFromCustomer.DestinationPattern(ThisObject);
	Catalogs.Assignments.CheckFillBeforeRecording(Purpose, DestinationPattern, ThisObject, "LineOfBusiness", Cancel);
	
	If WriteMode = DocumentWriteMode.Posting Then
		TMCommonUse.FillInDocumentIDs(ThisObject, 
			Metadata.Documents.RequestForReturnOfGoodsFromCustomer.TabularSections.ReturnedGoods.Name);
		TMCommonUse.FillInDocumentIDs(ThisObject,
			Metadata.Documents.RequestForReturnOfGoodsFromCustomer.TabularSections.SubstituteGoods.Name);
	EndIf;
	
	RequestForReturnOfGoodsFromCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);

	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		UseCustomerContracts   = GetFunctionalOption("UseCustomerContracts");
		SelectConsignmentSalesVersion = GetFunctionalOption("SelectConsignmentSalesVersion");
		OnlyConsignmentSales25      = UseCustomerContracts 
			And (GetFunctionalOption("OnlyConsignmentSales25")
				Or Not ToUseTermsOfSales Or Not SelectConsignmentSalesVersion);
			
		ConsignmentSales25 = False;
		If OnlyConsignmentSales25 Then
			ConsignmentSales25 = True;
		ElsIf ValueIsFilled(Terms) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Terms, "ConsignmentSales25");
		ElsIf ValueIsFilled(Contract) Then
			ConsignmentSales25 = Common.ObjectAttributeValue(Contract, "ConsignmentSales25");
		EndIf;
			
		If ConsignmentSales25 Then
			ToReturnReusablePackage      = False;
			ReusablePackageReturnCycleLength = 0;
			PackageDepositIsRequired           = False;
		EndIf;
	EndIf;
	
	If IsNew() And Not ValueIsFilled(Author) Then
		Author = Users.AuthorizedUser();
	EndIf;

EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	DestinationPattern = Documents.RequestForReturnOfGoodsFromCustomer.DestinationPattern(ThisObject);
	Catalogs.Assignments.OnWriteDocument(Purpose, DestinationPattern, ThisObject, Partner,
		VATAccountingERP.TypeOfVATTaxationActivity(VATTaxation, Organization, Date));
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		RegisterRecords.ShipmentAndReturnReferences.AdditionalProperties.Insert("GenerateSummaryTableOfRefundRequest");
	EndIf;
	
	RequestForReturnOfGoodsFromCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		NotCheckedAttributeArray.Add("VATTaxation");
		NotCheckedAttributeArray.Add("ReturnedGoods.VATRate");
	EndIf;
	
	If (BusinessOperation <> Enums.BusinessTransactions.ReturnFromCustodian
		And BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent)
		And (Not ValueIsFilled(Terms)
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed")) Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	NotCheckedAttributeArray.Add("DateOfShipment");
	
	CheckParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	CheckParameters.TSName = "ReturnedGoods";
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
	
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		CheckParameters.TSName = "SubstituteGoods";
		ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, CheckParameters);
		ProductsServer.CheckContentCompletion(ThisObject, Cancel, "SubstituteGoods");
	EndIf;
	
	If CompensationMethod <> Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian Then
		NotCheckedAttributeArray.Add("SubstituteGoods");
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCustodian
		Or BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		NotCheckedAttributeArray.Add("CompensationMethod");
		NotCheckedAttributeArray.Add("VATRate");
	EndIf;
	
	// The warehouse must be filled in statuses greater than Agreed
	AllReplacementLinesAreCancelled = TMCommonUse.AllLinesAreCanceled(ThisObject, "SubstituteGoods", "Canceled");
	AllReturnedLinesAreCanceled = TMCommonUse.AllLinesAreCanceled(ThisObject, "ReturnedGoods", "Canceled");
	If Not ValueIsFilled(Warehouse) 
		And Status <> Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon
		And (ReturnedGoods.Count() > 0 And Not AllReturnedLinesAreCanceled)
		And (SubstituteGoods.Count() = 0 Or AllReplacementLinesAreCancelled) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
						|ru = 'Поле ""Склад"" не заполнено.';
						|en = '""Warehouse"" is required.'; fa = '""Warehouse"" is required.';
						|it = 'Il campo ""Magazzino"" non è compilato.';
						|pl = 'Nie wypełniono pole ""Magazyn"".';
						|tr = '""Ambar"" alanı doldurulmamış.'");
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"Warehouse",
			,
			Cancel);
		
	EndIf;

	// The validity period of the order must be at least the date of the document
	If Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon And
		ValueIsFilled(ApprovalDate) And ApprovalDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày điều chỉnh không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата согласования должна быть не меньше даты документа %Date%';
						|en = 'Approval date shall not be less than document date %Date%'; fa = 'Approval date shall not be less than document date %Date%';
						|it = 'La data della definizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data uzgodnienia powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Onay tarihi belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date, "DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"ApprovalDate",
			,
			Cancel);
		
	EndIf;
	
	// The desired date of receipt in the header must be at least the date of the document
	If ValueIsFilled(RequestedDeliveryDate) And RequestedDeliveryDate < BegOfDay(Date) Then
	
		If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
			ErrorText = NStr("vi = 'Ngày trả lại dự kiến phải nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Желаемая дата возврата должна быть не меньше даты документа %Date%';
							|en = 'Required return date should not be less than document date %Date%'; fa = 'Required return date should not be less than document date %Date%';
							|it = 'La data di reso richiesta non deve essere precedente alla data del documento %Date%';
							|pl = 'Pożądana data zwrotu powinna być nie mniejsza niż daty dokumentu %Date%';
							|tr = 'İstenen iade tarihi, belgenin %Date%tarihinden daha önce olmamalıdır'");
		Else
			ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
							|en = 'Date of receipt cannot be less than document date %Date%'; fa = 'Date of receipt cannot be less than document date %Date%';
							|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
							|tr = 'Kabul tarihi, belgenin %Date%tarihinden daha önce olmamalıdır '");
		EndIf;
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"RequestedDeliveryDate",
			,
			Cancel);

	EndIf;

	NotCheckedAttributeArray.Add("ReturnedGoods.ProductsRecordingAsReceived");
	NotCheckedAttributeArray.Add("ReturnedGoods.DateOfReceipt");
	
	AllReturnedItemsAreCancelled = True;
	
	For CurIndex__ = 0 To ReturnedGoods.Count()-1 Do
		
		CurRowReturnedProducts = ReturnedGoods[CurIndex__]; // LineOfATabularSection
		
		If Not CurRowReturnedProducts.Canceled Then
			AllReturnedItemsAreCancelled = False;
		EndIf;
		
		ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách hàng trả lại';
									|ru = 'в строке %LineNumber% списка ""Возвращаемые товары""';
									|en = 'in line %LineNumber% of the ""Goods pending return"" list'; fa = 'in line %LineNumber% of the ""Goods pending return"" list';
									|it = 'nella riga %LineNumber% dell''elenco ""Merci in corso di resa""';
									|pl = 'w wierszu %LineNumber% listy ""Возвращаемые товары""';
									|tr = '""iade edilen ürünler"" listesinin %LineNumber% satırında'");
		ErrorAddress =  StrReplace(ErrorAddress, "%LineNumber%", CurRowReturnedProducts.LineNumber);
		
		// The date of receipt in pm of the returned goods is required to be filled in only for applications in 
		// the status of return, security, delivery, Completed.
		If Not OneDateReceipt
			And (Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn Or
			Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply Or
			Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip Or
			Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed) And
			Not CurRowReturnedProducts.Canceled And
			Not ValueIsFilled(CurRowReturnedProducts.DateOfReceipt) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Ngày tiếp nhận""';
							|ru = 'Не заполнена колонка ""Дата поступления""';
							|en = 'The ""Date of receipt"" column is not filled in'; fa = 'The ""Date of receipt"" column is not filled in';
							|it = 'La colonna ""Data dell''arrivo"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Дата поступления""';
							|tr = '""Teslim alım tarihi"" sütunu eksik'");
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", CurRowReturnedProducts.LineNumber, "DateOfReceipt"),
				,
				Cancel);
			
		EndIf;
			
		// The date of receipt of the returned returned goods in PM must be at least the date of the document.
		If Not OneDateReceipt
			And ValueIsFilled(CurRowReturnedProducts.DateOfReceipt) And CurRowReturnedProducts.DateOfReceipt < BegOfDay(Date) Then
		
			ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
							|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
							|en = 'Date of receipt cannot be less than document date %Date%'; fa = 'Date of receipt cannot be less than document date %Date%';
							|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
							|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
							|tr = 'Kabul tarihi, belgenin %Date%tarihinden daha önce olmamalıdır '");
			ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
			
			Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", CurRowReturnedProducts.LineNumber, "DateOfReceipt"),
				,
				Cancel);
			
		EndIf;
		
		// If the customer returns a low-quality product, then you need to check the data of the low-quality product.
		If CurRowReturnedProducts.Damage Then
			If Not ValueIsFilled(CurRowReturnedProducts.ProductsRecordingAsReceived) Then
				ErrorText = NStr("vi = 'Cột ""mặt hàng (đăng)"" không được điền';
								|ru = 'Не заполнена колонка ""Номенклатура (оприходование)""';
								|en = 'Column ""Items (recording as received)"" is not filled in'; fa = 'Column ""Items (recording as received)"" is not filled in';
								|it = 'La colonna ""Articolo (registrazione in contabilità)"" non è compilata';
								|pl = 'Nie wypełniono kolumny ""Номенклатура (оприходование)""';
								|tr = '""Öğe (Envanter)"" sütunu eksik'");
				Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", CurRowReturnedProducts.LineNumber, "ProductsRecordingAsReceived"),
				,
				Cancel);
			ElsIf CurRowReturnedProducts.ProductsRecordingAsReceived = CurRowReturnedProducts.Products Then
				ErrorText = NStr("vi = 'Hàng hóa bị trả lại có chất lượng khác trùng với hàng hóa đã giao trước đây.';
								|ru = 'Возвращаемый товар другого качества совпадает с ранее отгруженным товаром.';
								|en = 'Goods pending return of other quality match the goods that were shipped earlier.'; fa = 'Goods pending return of other quality match the goods that were shipped earlier.';
								|it = 'Le merci in corso di resa di un''altra qualità coincidono con le merci precedentemente spedite.';
								|pl = 'Zwracany towar o innej jakości zbiega się z wcześniej wysłanym towarem.';
								|tr = 'İade edilen malların daha önce gönderilen mallardan farklı kalitede olması.'");
				Common.MessageToUser(
				ErrorText + ErrorAddress,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", CurRowReturnedProducts.LineNumber, "ProductsRecordingAsReceived"),
				,
				Cancel);
			EndIf;
		EndIf;
		
		If ValueIsFilled(Warehouse) And Not ValueIsFilled(CurRowReturnedProducts.Warehouse) Then
			
			ErrorText = NStr("vi = 'Chưa điền cột ""Người nhận"" trong dòng %LineNumber% của danh sách ""%TSName%""';
							|ru = 'Не заполнена колонка ""Получатель"" в строке %LineNumber% списка ""%TSName%""';
							|en = 'The ""Recipient"" column in line %LineNumber% of the ""%TSName%"" list is not filled in.'; fa = 'The ""Recipient"" column in line %LineNumber% of the ""%TSName%"" list is not filled in.';
							|it = 'Не заполнена колонка ""Получатель"" в строке %LineNumber% списка ""%TSName%""';
							|pl = 'The ""Recipient"" column in line %LineNumber% of the ""%TSName%"" list is not filled in.';
							|tr = 'Не заполнена колонка ""Получатель"" в строке %LineNumber% списка ""%TSName%""'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  CurRowReturnedProducts.LineNumber);
			ErrorText = StrReplace(ErrorText, "%TSName%",        NStr("vi = 'Hàng hóa trả lại';
																		|ru = 'Возвращаемые товары';
																		|en = 'Goods pending return'; fa = 'کالای در انتظار برگشت';
																		|it = 'Возвращаемые товары';
																		|pl = 'Zwracane wiersze pozycji';
																		|tr = 'İade edilen ürünler'"));
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", CurRowReturnedProducts.LineNumber, "Warehouse"),
				,
				Cancel);
			
		EndIf;	
		
	EndDo;
	
	If AllReturnedItemsAreCancelled
		Or Not OneDateReceipt
		Or (OneDateReceipt 
			And Not (Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed)) Then
			
		NotCheckedAttributeArray.Add("DateOfReceipt");
		
	EndIf;

	// The date of shipment in the header must be at least the date of the document
	If NotShipInInstallments And 
		ValueIsFilled(DateOfShipment) And 
		DateOfShipment < BegOfDay(Date) And 
		CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
	
		ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата отгрузки должна быть не меньше даты документа %Date%';
						|en = 'Shipment date cannot be less than document date%Date%'; fa = 'Shipment date cannot be less than document date%Date%';
						|it = 'La data della spedizione non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Sevkiyat tarihi, belgenin %Date%tarihinden daha önce olmamalıdır'");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfShipment",
			,
			Cancel);

	EndIf;
	
	// The date of receipt in the header must be at least the date of the document
	If OneDateReceipt And 
		ValueIsFilled(DateOfReceipt) And 
		DateOfReceipt < BegOfDay(Date) Then
	
		ErrorText = NStr("vi = 'Ngày tiếp nhận không được nhỏ hơn ngày chứng từ %Date%';
						|ru = 'Дата поступления должна быть не меньше даты документа %Date%';
						|en = 'Date of receipt cannot be less than document date %Date%'; fa = 'Date of receipt cannot be less than document date %Date%';
						|it = 'La data dell''arrivo non deve essere inferiore alla data del documento %Date%';
						|pl = 'Data wpłaty powinna być nie mniejsza niż data dokumentu %Date%';
						|tr = 'Kabul tarihi, belgenin %Date%tarihinden daha önce olmamalıdır '");
		ErrorText = StrReplace(ErrorText, "%Date%", Format(Date,"DLF=DD"));
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"DateOfReceipt",
			,
			Cancel);

	EndIf;
	
	NotCheckedAttributeArray.Add("SubstituteGoods.CancellationReason");
	NotCheckedAttributeArray.Add("SubstituteGoods.DateOfShipment");
	
	DateOfShipmentRequired_ = False;
	WarehouseIsRequired         = False;
	
	MatchingLineCodes = New Map;
	
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		
		EmbeddingParameters = Documents.RequestForReturnOfGoodsFromCustomer.AvailableRemainingEmbeddingOptions();
		ErrorsTable = ProvisionInDocumentsServer.TableOfFillingErrors(ThisObject, EmbeddingParameters);
		
		For CurIndex__ = 0 To ErrorsTable.Count() - 1 Do
			
			TextTemplate1 = NStr("vi = 'Chưa điền cột ""Ngày giao hàng"" tại dòng %LineNumber% của danh sách ""Hàng hóa thay thế""';
								|ru = 'Не заполнена колонка ""Дата отгрузки"" в строке %LineNumber% списка ""Заменяющие товары""';
								|en = 'Column ""Shipment date"" in line %LineNumber% of the ""Exchange goods"" list is not filled in'; fa = 'Column ""Shipment date"" in line %LineNumber% of the ""Exchange goods"" list is not filled in';
								|it = 'Non è compilata la colonna ""Data di spedizione"" nella riga %LineNumber% dell''elenco ""Merci sostitutive""';
								|pl = 'Nie wypełniono kolumny ""Data wysyłki"" w wierszu %LineNumber% listy ""Wiersze pozycji zastępcze""';
								|tr = '""İkame ürünler"" listesinin %LineNumber% satırındaki ""Sevkiyat tarihi"" sütunu eksik'");
			ErrorString = ErrorsTable[CurIndex__];
			
			If ErrorString.DateOfShipmentRequired_ And Not NotShipInInstallments And ErrorString.ShipmentDateNotFilledIn Then
				
				ErrorText = StrReplace(TextTemplate1, "%LineNumber%", ErrorString.LineNumber);
				PathToTop = CommonClientServer.PathToTabularSection(
					"SubstituteGoods",
					ErrorString.LineNumber,
					"DateOfShipment");
				Common.MessageToUser(ErrorText, ThisObject, PathToTop, , Cancel);
				
			EndIf;
			
			WarehouseIsRequired = WarehouseIsRequired Or ErrorString.WarehouseIsRequired;
			DateOfShipmentRequired_ = DateOfShipmentRequired_ Or ErrorString.DateOfShipmentRequired_;
			
		EndDo;
		
		If NotShipInInstallments And DateOfShipmentRequired_ And Not ValueIsFilled(DateOfShipment) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Ngày giao hàng""';
							|ru = 'Поле ""Дата отгрузки"" не заполнено';
							|en = '""Shipment date"" is not filled in'; fa = '""Shipment date"" is not filled in';
							|it = 'Il campo ""Data di spedizione"" non è compilato';
							|pl = 'Nie wypełniono pole ""Data отгрузки""';
							|tr = '""Sevkiyat tarihi"" alanı doldurulmamış'");
			Common.MessageToUser(ErrorText, ThisObject, "DateOfShipment", , Cancel);
			
		EndIf;
		
		// Checking the filling of the warehouse in the status lower than "To ensure". Starting from the "To secure" status,
		// the warehouse filling checks are performed in the Sales Server module.Check the correctness of the completion of the sale document.
		If WarehouseIsRequired And Not ValueIsFilled(Warehouse)
				And (Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon
					Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi""';
							|ru = 'Поле ""Склад"" не заполнено';
							|en = '""Warehouse"" is required'; fa = '""Warehouse"" is required';
							|it = 'Il campo ""Magazzino"" non è compilato';
							|pl = 'Nie wypełniono pola ""Magazyn""';
							|tr = '""Ambar"" alanı doldurulmamış'");
			Common.MessageToUser(ErrorText, ThisObject, "Warehouse", , Cancel);
			
		EndIf;
		
		For CurIndex__ = 0 To SubstituteGoods.Count()-1 Do
			
			CurRowReplacementProducts = SubstituteGoods[CurIndex__]; // LineOfATabularSection
			ErrorAddress = " " + NStr("vi = 'trong dòng %LineNumber% của danh sách ""Thay thế hàng hóa""';
										|ru = 'в строке %LineNumber% списка ""Заменяющие товары""';
										|en = 'in line %LineNumber% of the ""Exchange goods"" list'; fa = 'in line %LineNumber% of the ""Exchange goods"" list';
										|it = 'nella riga %LineNumber% dell''elenco ""Merci sostitutive""';
										|pl = 'w wierszu %LineNumber% listy ""Заменяющие товары""';
										|tr = '""ikame ürünler"" listesinin %LineNumber%satırında'");
			ErrorAddress = StrReplace(ErrorAddress, "%LineNumber%", CurRowReplacementProducts.LineNumber);
			
			// The reason for cancellation is mandatory in the lines without the Canceled attribute
			If GetFunctionalOption("UseReasonsForSalesOrderCancellations")
				And CurRowReplacementProducts.Canceled
				And Not ValueIsFilled(CurRowReplacementProducts.CancellationReason) Then
					
				ErrorText = NStr("vi = 'Cần chỉ ra nguyên nhân hủy bỏ';
								|ru = 'Необходимо указать причину отмены';
								|en = 'Cancellation reason is required'; fa = 'Cancellation reason is required';
								|it = 'È necessario specificare il motivo di annullamento';
								|pl = 'Należy wskazać przyczynę anulowania';
								|tr = 'İptal nedeni belirtilmelidir'");
				Common.MessageToUser(
					ErrorText + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("SubstituteGoods", CurRowReplacementProducts.LineNumber, "CancellationReason"),
					,
					Cancel);
				
			EndIf;
				
			// The date of shipment in pm Goods must be at least the date of the document
			If Not NotShipInInstallments And
				ValueIsFilled(CurRowReplacementProducts.DateOfShipment)	And 
				CurRowReplacementProducts.DateOfShipment < BegOfDay(Date) Then
					
				ErrorText = NStr("vi = 'Ngày giao hàng không được nhỏ hơn ngày chứng từ ""%Date%""';
								|ru = 'Дата отгрузки должна быть не меньше даты документа ""%Date%""';
								|en = 'Shipment date cannot be less than document date ""%Date%""'; fa = 'Shipment date cannot be less than document date ""%Date%""';
								|it = 'La data della spedizione non deve essere inferiore alla data del documento ""%Date%""';
								|pl = 'Data wysyłki powinna być nie mniejsza niż data dokumentu ""%Date%""';
								|tr = 'Sevkiyat tarihi, belgenin ""%Date%""tarihinden daha önce olmamalıdır'");
				ErrorText = StrReplace(ErrorText,"%Date%", Format(Date, "DLF=DD"));
					
				Common.MessageToUser(
					ErrorText + ErrorAddress,
					ThisObject,
					CommonClientServer.PathToTabularSection("SubstituteGoods", CurRowReplacementProducts.LineNumber, "DateOfShipment"),
					,
					Cancel);
				
			EndIf;

			OrdersServer.CheckDuplicatesOfRowCodesInTable(ThisObject,
				CurRowReplacementProducts.RowCode,
				CurRowReplacementProducts.LineNumber,
				MatchingLineCodes,
				Cancel,
				"SubstituteGoods");
		EndDo;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent Then
		NotCheckedAttributeArray.Add("Department");
		NotCheckedAttributeArray.Add("SubstituteGoods.PercentRateOfManualDiscount");
		NotCheckedAttributeArray.Add("SubstituteGoods.ManualDiscount");
		NotCheckedAttributeArray.Add("SubstituteGoods.PercentRateOfAutomaticDiscountMarkup");
		NotCheckedAttributeArray.Add("SubstituteGoods.DiscountMarkupAmount");
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
		NotCheckedAttributeArray.Add("Contract");
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.RequestForReturnOfGoodsFromCustomer);
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = "ReturnedGoods";
	CheckParameters.FieldNamesWithSuffix.Insert("Products", "ProductsRecordingAsReceived");
	CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "CharacteristicRecordingAsReceived");
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
	ParametersArray = New Array;
	ParametersArray.Add(SeriesSpecificationParameters.Returned_);
	
	If CompensationMethod = Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "SubstituteGoods";
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject,NotCheckedAttributeArray,Cancel,CheckParameters);
		ParametersArray.Add(SeriesSpecificationParameters.Substitutes_);
	EndIf;
	
	ProductsServer.CheckSeriesCompletion(ThisObject,
	                                            ParametersArray,
	                                            Cancel,
	                                            NotCheckedAttributeArray);
	
	NotCheckedAttributeArray.Add("Department");
	
	If CompensationMethod <> Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods 
		Or UsersClientServer.IsExternalUserSession() Then
		NotCheckedAttributeArray.Add("SubstituteGoods");
		NotCheckedAttributeArray.Add("SubstituteGoods.Products");
		NotCheckedAttributeArray.Add("SubstituteGoods.Characteristic");
		NotCheckedAttributeArray.Add("SubstituteGoods.NumberOfPackages");
		NotCheckedAttributeArray.Add("SubstituteGoods.Count");
		NotCheckedAttributeArray.Add("SubstituteGoods.VATRate");
		NotCheckedAttributeArray.Add("SubstituteGoods.Price");
	EndIf;
	
	ProductsServer.CheckTypeOfProductDescription(ThisObject,Cancel,"ReturnedGoods");
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel);
	
	QualityConfirmationDateRequired_ =
		Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
			Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed;
	
	QualityControl.ProcessingVerificationOfFillingInReceiptDocument(
		ThisObject,
		NotCheckedAttributeArray,
		Cancel,
		"ReturnedGoods",
		NStr("ru = 'Возвращаемые товары';
			|vi = 'Goods pending return';
			|en = 'Goods pending return'; fa = 'کالای در انتظار برگشت';
			|it = 'Merci da rendere';
			|pl = 'Zwracane wiersze pozycji';
			|tr = 'İade edilen ürünler'"),
		".DateOfReceipt",
		QualityConfirmationDateRequired_);
		
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not Cancel And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		Cancel = True;
	EndIf;
	ReplacementAmount = GetSumOfReplacementStrings();
	ReturnablePackagingAmount = GetReturnTareAmount();
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	If BusinessOperation <> Enums.BusinessTransactions.ReturnFromCustodian Then
		SalesServer.CheckCorrectnessOfReturnedProducts(ThisObject, "ReturnedGoods", Cancel);
	EndIf;
	ControlOfFillingOfPricesOfReturnedGoods(Cancel);
	
	If (Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply
		Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip
		Or Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed)
		And SubstituteGoods.Count() > 0 Then
		
		SalesServer.CheckShipmentBan(Partner, Cancel);
		
	EndIf;
	
	RequestForReturnOfGoodsFromCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);

EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	SalesServer.PerformOrderControlAfterConducting(Ref, Cancel);
	
	RequestForReturnOfGoodsFromCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	RequestForReturnOfGoodsFromCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Initialization and filling in

Procedure FillInDocumentBasedOnPartner(Val Basis)
	
	Partner = Basis;
	If GetFunctionalOption("ToUseTermsOfSales") Then
		FillInDefaultSalesConditions();
	Else
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfSaleTransaction(Basis)
	
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
		|	SalesOpportunitiesToCustomer.Partner AS Partner,
		|	SalesOpportunitiesToCustomer.CustomerTermsOfSales AS Terms,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
		|		ON (SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &Basis");
		
	Query.SetParameter("Basis",Basis);
		
	Selection = Query.Execute().Select();
	
	Selection.Next();
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Partner);
	FillPropertyValues(ThisObject, Selection);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		If ValueIsFilled(Terms) Then
			FillInTermsOfSalesUnderAgreement();
		Else
			FillInDefaultSalesConditions();
		EndIf;
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query("
		|SELECT
		|	CustomerTermsOfSales.Ref                       AS Terms,
		|	CustomerTermsOfSales.Partner                      AS Partner,
		|	CustomerTermsOfSales.ContactPerson               AS ContactPerson,
		|	CustomerTermsOfSales.AvailableToExternalUsers AS AvailableToExternalUsers,
		|
		|	CustomerTermsOfSales.Status                       AS DocumentStatus,
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
		ArrayOfValidStatuses,
		Selection.AvailableToExternalUsers);
	
	FillPropertyValues(ThisObject, Selection);
	FillInTermsOfSalesUnderAgreement();

EndProcedure

Procedure FillInDocumentBasedOnSaleOfGoodsAndServices(Val DocumentBasis)
	
	Query = New Query(
		"SELECT TOP 1
		|	SaleAdjustment.Ref AS Ref
		|INTO LastAdjustmentData
		|FROM
		|	Document.SaleAdjustment AS SaleAdjustment
		|WHERE
		|	SaleAdjustment.Posted
		|	AND SaleAdjustment.DocumentBasis = &DocumentBasis
		|	AND NOT SaleAdjustment.AdjustmentKind IN (VALUE(Enum.BusinessTransactions.SaleOfOverdeliveredGoods), VALUE(Enum.BusinessTransactions.ReturnOfUnderdeliveredGoods))
		|
		|ORDER BY
		|	SaleAdjustment.PointInTime DESC
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 1
		|SELECT
		|	CustomerInvoice.Ref AS DocumentSalesOfGoodsAndServices,
		|	CustomerInvoice.Ref AS Ref,
		|	CustomerInvoice.Terms AS Terms,
		|	CustomerInvoice.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	CASE
		|		WHEN CustomerInvoice.SalesOrder = UNDEFINED
		|				OR CustomerInvoice.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
		|				OR CustomerInvoice.SalesOrder = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|				OR CustomerInvoice.SalesOrder.PaymentSchedule = VALUE(Catalog.PaymentSchedules.EmptyRef)
		|			THEN CustomerInvoice.Terms.PaymentSchedule
		|		ELSE CustomerInvoice.SalesOrder.PaymentSchedule
		|	END AS PaymentSchedule,
		|	CASE
		|		WHEN CustomerInvoice.SalesOrder = UNDEFINED
		|				OR CustomerInvoice.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
		|				OR CustomerInvoice.SalesOrder = VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef)
		|				OR CustomerInvoice.SalesOrder.PaymentSchedule = VALUE(Catalog.PaymentSchedules.EmptyRef)
		|			THEN CustomerInvoice.Terms.PaymentSchedule.PaymentMethod
		|		ELSE CustomerInvoice.SalesOrder.PaymentMethod
		|	END AS PaymentMethod,
		|	CustomerInvoice.Organization AS Organization,
		|	CustomerInvoice.Partner AS Partner,
		|	CustomerInvoice.Counterparty AS Counterparty,
		|	CustomerInvoice.ContactPerson AS ContactPerson,
		|	CustomerInvoice.Contract AS Contract,
		|	CustomerInvoice.Currency AS Currency,
		|	CustomerInvoice.ARAPCurrency AS ARAPCurrency,
		|	CustomerInvoice.SalesOpportunity AS SalesOpportunity,
		|	CustomerInvoice.Department AS Department,
		|	CASE
		|		WHEN CustomerInvoice.Warehouse.IsFolder
		|				AND CustomerInvoice.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE CustomerInvoice.Warehouse
		|	END AS Warehouse,
		|	CustomerInvoice.BusinessOperation AS EconomicOperationImplementation,
		|	CustomerInvoice.PriceIncludesVAT AS PriceIncludesVAT,
		|	CustomerInvoice.VATTaxation AS VATTaxation,
		|	CustomerInvoice.ARAPObjectSettings AS ARAPObjectSettings,
		|	CustomerInvoice.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	CustomerInvoice.Shipper AS Shipper,
		|	CustomerInvoice.GoodsRecipient AS GoodsRecipient,
		|	CustomerInvoice.ShipperBankAccount AS ShipperBankAccount,
		|	CustomerInvoice.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CustomerInvoice.DeliveryAddress AS DeliveryAddress,
		|	CustomerInvoice.ToReturnReusablePackage AS ToReturnReusablePackage,
		|	CustomerInvoice.Terms.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	CustomerInvoice.PackageDepositIsRequired AS PackageDepositIsRequired,
		|	CustomerInvoice.Status AS DocumentStatus,
		|	CustomerInvoice.LoyaltyCard AS LoyaltyCard,
		|	NOT CustomerInvoice.Posted AS ThereAreErrorsPosted,
		|	CASE
		|		WHEN CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped)
		|				OR CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomerLocalAccounting)
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreErrorsStatus,
		|	CustomerInvoice.Terms.AvailableToExternalUsers AS AgreementIsAvailableToExternalUsers,
		|	CustomerInvoice.LineOfBusiness AS LineOfBusiness
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|WHERE
		|	CustomerInvoice.Ref = &DocumentBasis
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 2
		|SELECT
		|	GoodsTable.ProductsInSet AS ProductsInSet,
		|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Products.ItemsType AS ItemsType,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Series AS Series,
		|	GoodsTable.Purpose AS Purpose,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.NumberOfPackages AS NumberOfPackages,
		|	GoodsTable.Price AS Price,
		|	GoodsTable.PriceKind AS PriceKind,
		|	GoodsTable.Count AS Count,
		|	GoodsTable.Sum AS Sum,
		|	GoodsTable.VATRate AS VATRate,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
		|	GoodsTable.RowCode AS RowCode,
		|	GoodsTable.Warehouse AS Warehouse,
		|	GoodsTable.SalesOrder AS SalesOrder,
		|	0 AS ManualDiscount,
		|	0 AS DiscountMarkupAmount
		|INTO ProductsForSale
		|FROM
		|	Document.SaleAdjustment.Goods AS GoodsTable
		|		INNER JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON GoodsTable.Ref = LastAdjustmentData.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.ProductsInSet,
		|	GoodsTable.ItemVariantOfSet,
		|	GoodsTable.Products,
		|	GoodsTable.Products.ItemsType,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	GoodsTable.Purpose,
		|	GoodsTable.Package,
		|	GoodsTable.NumberOfPackages,
		|	GoodsTable.Price,
		|	GoodsTable.PriceKind,
		|	GoodsTable.Count,
		|	GoodsTable.Sum,
		|	GoodsTable.VATRate,
		|	GoodsTable.VATAmount,
		|	GoodsTable.AmountIncludingVAT,
		|	GoodsTable.RowCode,
		|	GoodsTable.Warehouse,
		|	GoodsTable.SalesOrder,
		|	GoodsTable.ManualDiscount,
		|	GoodsTable.DiscountMarkupAmount
		|FROM
		|	Document.CustomerInvoice.Goods AS GoodsTable
		|		LEFT JOIN LastAdjustmentData AS LastAdjustmentData
		|		ON (TRUE)
		|WHERE
		|	LastAdjustmentData.Ref IS NULL
		|	AND GoodsTable.Ref = &DocumentBasis
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 3
		|SELECT
		|	ProductsForSale.ProductsInSet AS ProductsInSet,
		|	ProductsForSale.ItemVariantOfSet AS ItemVariantOfSet,
		|	ISNULL(ProductKitConfigurations.ContainsServices, FALSE) AS SetContainsServices,
		|	ProductsForSale.Products AS Products,
		|	ProductsForSale.ItemsType AS ItemsType,
		|	ProductsForSale.Characteristic AS Characteristic,
		|	ProductsForSale.Series AS Series,
		|	ProductsForSale.Purpose AS Purpose,
		|	ProductsForSale.Package AS Package,
		|	SUM(ProductsForSale.NumberOfPackages) AS NumberOfPackages,
		|	AVG(ProductsForSale.Price) AS Price,
		|	SUM(ProductsForSale.Count) AS Count,
		|	SUM(ProductsForSale.Sum) AS Sum,
		|	ProductsForSale.VATRate AS VATRate,
		|	SUM(ProductsForSale.VATAmount) AS VATAmount,
		|	SUM(ProductsForSale.AmountIncludingVAT) AS AmountIncludingVAT,
		|	SUM(ProductsForSale.ManualDiscount) AS ManualDiscount,
		|	SUM(ProductsForSale.DiscountMarkupAmount) AS DiscountMarkupAmount,
		|	ProductsForSale.Warehouse AS Warehouse
		|INTO GoodsSales_
		|FROM
		|	ProductsForSale AS ProductsForSale
		|		
		|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
		|		ON ProductKitConfigurations.Owner = ProductsForSale.ProductsInSet
		|			AND ProductKitConfigurations.Characteristic = ProductsForSale.ItemVariantOfSet
		|			AND ProductKitConfigurations.Main
		|		
		|GROUP BY
		|	ProductsForSale.ProductsInSet,
		|	ProductsForSale.ItemVariantOfSet,
		|	ISNULL(ProductKitConfigurations.ContainsServices, FALSE),
		|	ProductsForSale.Products,
		|	ProductsForSale.ItemsType,
		|	ProductsForSale.Characteristic,
		|	ProductsForSale.Series,
		|	ProductsForSale.Package,
		|	ProductsForSale.VATRate,
		|	ProductsForSale.Purpose,
		|	ProductsForSale.Warehouse
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 4
		|SELECT
		|	ReturnOfGoodsFromCustomerGoods.ProductsInSet AS ProductsInSet,
		|	ReturnOfGoodsFromCustomerGoods.ItemVariantOfSet AS ItemVariantOfSet,
		|	ReturnOfGoodsFromCustomerGoods.Products AS Products,
		|	ReturnOfGoodsFromCustomerGoods.Products.ItemsType AS ItemsType,
		|	ReturnOfGoodsFromCustomerGoods.Characteristic AS Characteristic,
		|	ReturnOfGoodsFromCustomerGoods.Series AS Series,
		|	ReturnOfGoodsFromCustomerGoods.Purpose AS Purpose,
		|	ReturnOfGoodsFromCustomerGoods.Package AS Package,
		|	SUM(ReturnOfGoodsFromCustomerGoods.NumberOfPackages) AS NumberOfPackages,
		|	SUM(ReturnOfGoodsFromCustomerGoods.Count) AS Count,
		|	SUM(ReturnOfGoodsFromCustomerGoods.Sum) AS Sum,
		|	ReturnOfGoodsFromCustomerGoods.VATRate AS VATRate,
		|	SUM(ReturnOfGoodsFromCustomerGoods.VATAmount) AS VATAmount,
		|	SUM(ReturnOfGoodsFromCustomerGoods.AmountIncludingVAT) AS AmountIncludingVAT,
		|	AVG(ReturnOfGoodsFromCustomerGoods.Price) AS Price,
		|	ReturnOfGoodsFromCustomerGoods.Warehouse AS Warehouse
		|INTO ProductsFromPreviousRefunds
		|FROM
		|	Document.ReturnOfGoodsFromCustomer.Goods AS ReturnOfGoodsFromCustomerGoods
		|WHERE
		|	ReturnOfGoodsFromCustomerGoods.DocumentSalesOfGoodsAndServices = &DocumentBasis
		|	AND ReturnOfGoodsFromCustomerGoods.Ref.Posted
		|
		|GROUP BY
		|	ReturnOfGoodsFromCustomerGoods.ProductsInSet,
		|	ReturnOfGoodsFromCustomerGoods.ItemVariantOfSet,
		|	ReturnOfGoodsFromCustomerGoods.Products,
		|	ReturnOfGoodsFromCustomerGoods.Products.ItemsType,
		|	ReturnOfGoodsFromCustomerGoods.Characteristic,
		|	ReturnOfGoodsFromCustomerGoods.Series,
		|	ReturnOfGoodsFromCustomerGoods.Package,
		|	ReturnOfGoodsFromCustomerGoods.VATRate,
		|	ReturnOfGoodsFromCustomerGoods.Purpose,
		|	ReturnOfGoodsFromCustomerGoods.Warehouse
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 5
		|SELECT
		|	GoodsSales_.ProductsInSet AS ProductsInSet,
		|	GoodsSales_.ItemVariantOfSet AS ItemVariantOfSet,
		|	GoodsSales_.SetContainsServices AS SetContainsServices,
		|	GoodsSales_.Products AS Products,
		|	GoodsSales_.ItemsType AS ItemsType,
		|	GoodsSales_.Characteristic AS Characteristic,
		|	GoodsSales_.Series AS Series,
		|	GoodsSales_.Purpose AS Purpose,
		|	GoodsSales_.Count - ISNULL(ProductsFromPreviousRefunds.Count, 0) AS Count,
		|	GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0) AS NumberOfPackages,
		|	GoodsSales_.Package AS Package,
		|	GoodsSales_.VATRate AS VATRate,
		|	CASE
		|		WHEN GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0) = 0
		|			THEN GoodsSales_.Price
		|		ELSE (GoodsSales_.Sum - ISNULL(ProductsFromPreviousRefunds.Sum, 0)) / (GoodsSales_.NumberOfPackages - ISNULL(ProductsFromPreviousRefunds.NumberOfPackages, 0))
		|	END AS Price,
		|	GoodsSales_.Sum - ISNULL(ProductsFromPreviousRefunds.Sum, 0) AS Sum,
		|	GoodsSales_.VATAmount - ISNULL(ProductsFromPreviousRefunds.VATAmount, 0) AS VATAmount,
		|	GoodsSales_.AmountIncludingVAT - ISNULL(ProductsFromPreviousRefunds.AmountIncludingVAT, 0) AS AmountIncludingVAT,
		|	&DocumentBasis AS DocumentSalesOfGoodsAndServices,
		|	GoodsSales_.Warehouse AS Warehouse
		|FROM
		|	GoodsSales_ AS GoodsSales_
		|		LEFT JOIN ProductsFromPreviousRefunds AS ProductsFromPreviousRefunds
		|		ON GoodsSales_.Products = ProductsFromPreviousRefunds.Products
		|			AND GoodsSales_.ProductsInSet = ProductsFromPreviousRefunds.ProductsInSet
		|			AND GoodsSales_.ItemVariantOfSet = ProductsFromPreviousRefunds.ItemVariantOfSet
		|			AND GoodsSales_.Characteristic = ProductsFromPreviousRefunds.Characteristic
		|			AND GoodsSales_.Series = ProductsFromPreviousRefunds.Series
		|			AND GoodsSales_.Purpose = ProductsFromPreviousRefunds.Purpose
		|WHERE
		|	GoodsSales_.Count - ISNULL(ProductsFromPreviousRefunds.Count, 0) > 0
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 6
		|SELECT
		|	TransferredReturnablePackagingBalance.Products AS Products,
		|	TransferredReturnablePackagingBalance.Characteristic AS Characteristic,
		|	TransferredReturnablePackagingBalance.Partner AS Partner,
		|	TransferredReturnablePackagingBalance.DocumentTransfers_ AS DocumentTransfers_,
		|	TransferredReturnablePackagingBalance.CountBalance AS Count,
		|	TransferredReturnablePackagingBalance.SumBalance AS Sum
		|INTO TTTransferredReturnPackaging
		|FROM
		|	AccumulationRegister.TransferredReturnablePackaging.Balance(, DocumentTransfers_ = &DocumentBasis) AS TransferredReturnablePackagingBalance
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsSales_.Products,
		|	GoodsSales_.Characteristic,
		|	CAST(&DocumentBasis AS Document.CustomerInvoice).Partner,
		|	&DocumentBasis,
		|	-GoodsSales_.Count + ISNULL(ProductsFromPreviousRefunds.Count, 0),
		|	-GoodsSales_.Sum + ISNULL(ProductsFromPreviousRefunds.Sum, 0)
		|FROM
		|	GoodsSales_ AS GoodsSales_
		|		LEFT JOIN ProductsFromPreviousRefunds AS ProductsFromPreviousRefunds
		|		ON GoodsSales_.Products = ProductsFromPreviousRefunds.Products
		|			AND GoodsSales_.ProductsInSet = ProductsFromPreviousRefunds.ProductsInSet
		|			AND GoodsSales_.ItemVariantOfSet = ProductsFromPreviousRefunds.ItemVariantOfSet
		|			AND GoodsSales_.Characteristic = ProductsFromPreviousRefunds.Characteristic
		|			AND GoodsSales_.Series = ProductsFromPreviousRefunds.Series
		|			AND GoodsSales_.Warehouse = ProductsFromPreviousRefunds.Warehouse
		|WHERE
		|	GoodsSales_.Count - ISNULL(ProductsFromPreviousRefunds.Count, 0) > 0
		|	AND NOT GoodsSales_.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
		|	AND GoodsSales_.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
		|	AND &DocumentBasis REFS Document.CustomerInvoice
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////// 7
		|SELECT
		|	TTTransferredReturnPackaging.Products AS Products,
		|	TTTransferredReturnPackaging.Characteristic AS Characteristic,
		|	TTTransferredReturnPackaging.DocumentTransfers_ AS DocumentSalesOfGoodsAndServices,
		|	SUM(TTTransferredReturnPackaging.Count) AS Count,
		|	SUM(TTTransferredReturnPackaging.Count) AS NumberOfPackages,
		|	SUM(TTTransferredReturnPackaging.Sum) AS Sum,
		|	SUM(TTTransferredReturnPackaging.Sum) AS AmountIncludingVAT,
		|	CASE
		|		WHEN SUM(TTTransferredReturnPackaging.Count) = 0
		|			THEN SUM(TTTransferredReturnPackaging.Sum)
		|		ELSE SUM(TTTransferredReturnPackaging.Sum) / SUM(TTTransferredReturnPackaging.Count)
		|	END AS Price,
		|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate
		|FROM
		|	TTTransferredReturnPackaging AS TTTransferredReturnPackaging
		|
		|GROUP BY
		|	TTTransferredReturnPackaging.Products,
		|	TTTransferredReturnPackaging.Characteristic,
		|	TTTransferredReturnPackaging.DocumentTransfers_
		|
		|HAVING
		|	SUM(TTTransferredReturnPackaging.Count) > 0");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	
	HeaderSelection = Result[1].Select();
	HeaderSelection.Next();
	
	BusinessOperation = SalesServer.GetRefundTransactionForSale(HeaderSelection.EconomicOperationImplementation);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(DocumentBasis,
								"RequestForReturnOfGoodsFromCustomer",
								BusinessOperation);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses,
		HeaderSelection.AgreementIsAvailableToExternalUsers);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = Result[5].Unload();
	TableOfGoods.Sort("ProductsInSet,ItemVariantOfSet,Products,ItemsType,Characteristic,Series,Package");

	For Each CurRow In TableOfGoods Do
		
		IsRecordsSet = ValueIsFilled(CurRow.ProductsInSet);
		
		If CurRow.ItemsType = Enums.ItemsTypes.OwnGoods
					And Not IsRecordsSet
				Or (CurRow.ItemsType = Enums.ItemsTypes.ReusablePackage
					And Not HeaderSelection.ToReturnReusablePackage
					And Not IsRecordsSet)
				Or (IsRecordsSet And Not CurRow.SetContainsServices) Then
			
			NewRow = ReturnedGoods.Add();
			FillPropertyValues(NewRow,CurRow);
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(
				NewRow,
				HeaderSelection.PriceIncludesVAT,
				False,
				False,
				True);
		EndIf;
		
	EndDo;
	
	PackageTable = Result[7].Unload();
	PackageTable.Sort("Products,Characteristic,DocumentSalesOfGoodsAndServices");
	
	For Each CurrentRow In PackageTable Do
		
		NewRow = ReturnedGoods.Add();
		FillPropertyValues(NewRow,CurrentRow);
		
		PriceManagementSystem.RecalculateAmountsInRowWithVAT(NewRow, HeaderSelection.PriceIncludesVAT, False, False, True);
		
	EndDo;
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)
	
	If FillingData.Property("BusinessOperation") Then
		BusinessOperation = FillingData.BusinessOperation;
		If FillingData.BusinessOperation = Enums.BusinessTransactions.ReturnFromRetailCustomer Then
			Partner = Catalogs.Partners.RetailCustomer;
			If GetFunctionalOption("ToUseTermsOfSales") Then
				FillInDefaultSalesConditions();
			EndIf;
		EndIf;
	ElsIf FillingData.Property("Partner") Then
		Partner = FillingData.Partner;
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
	EndIf;
	If Not ValueIsFilled(Organization)
		And FillingData.Property("Organization")
		And TypeOf(FillingData.Organization) = Type("CatalogRef.Companies") Then
		Organization = FillingData.Organization;
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransferredContainer(Val DetailsOfFillingInForm)
	
	FillPropertyValues(ThisObject, DetailsOfFillingInForm.HeaderAttributes);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		If Not ValueIsFilled(Terms) Then
			FillInDefaultSalesConditions(False);
		Else
			ReusablePackageReturnCycleLength = Common.ObjectAttributeValue(
				Terms,
				"ReusablePackageReturnCycleLength");
		EndIf;
	Else
		
		If DetailsOfFillingInForm.HeaderAttributes.PriceIncludesVAT = Undefined Then
			
			DetailsOfDefaultPrice = Catalogs.TypesOfPrices.PriceTypeAndPriceIncludesVATAttributeByDefault(
				New Structure("UseWhileSellingToCustomers", True),
				Documents.RequestForReturnOfGoodsFromCustomer.EmptyRef());
			
			FillPropertyValues(ThisObject, DetailsOfDefaultPrice);
		EndIf;
		
	EndIf;
	
	ToReturnReusablePackage = True;
	PackageDepositIsRequired = DetailsOfFillingInForm.HeaderAttributes.DepositForPackageIsRequired;
	
	If IsTempStorageURL(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage) Then
		
		TransferredPackage = GetFromTempStorage(DetailsOfFillingInForm.ContainerAddressInTemporaryStorage);
		ReturnedGoods.Load(TransferredPackage);
		
		For Each CurrentRow In ReturnedGoods Do
			
			CurrentRow.AmountIncludingVAT = CurrentRow.Sum;
			CurrentRow.NumberOfPackages = CurrentRow.Count;
			CurrentRow.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			
			PriceManagementSystem.RecalculateAmountsInRowWithVAT(CurrentRow, PriceIncludesVAT, False, False, True);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfActOfImplementation(Val FillingData)
	
	SetPrivilegedMode(True);
	
	QueryText = Documents.DiscrepancyReportFollowingShipment.RequestTextForOverDeliveredGoods();
	Query = New Query(QueryText);
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[1].Select();
	HeaderSelection.Next();
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfCustomerInvoices.Shipped);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	If HeaderSelection.EconomicOperationImplementation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		BusinessOperation = Enums.BusinessTransactions.ReturnFromCommissionAgent;
	EndIf;
	
	TableOfGoods = QueryBatch[12].Unload();
	
	For Each CurRow In TableOfGoods Do
			
		NewRow = ReturnedGoods.Add();
		FillPropertyValues(NewRow,CurRow);
		PriceManagementSystem.RecalculateAmountsInRow(
			NewRow,
			False,
			False,
			False,
			HeaderSelection.PriceIncludesVAT);
		
	EndDo;

EndProcedure

Procedure FillInDocumentOnBasisOfActOfTransfer(Val FillingData)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsHandover.Ref        AS Ref,
	|	UNDEFINED                  AS DocumentStatus,
	|	GoodsHandover.Partner       AS Partner,
	|	GoodsHandover.Counterparty    AS Counterparty,
	|	GoodsHandover.Terms    AS Terms,
	|	CASE
	|		WHEN GoodsHandover.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|		ELSE VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|	END                         AS BusinessOperation,
	|	GoodsHandover.Organization   AS Organization,
	|	CASE
	|		WHEN GoodsHandover.Warehouse.IsFolder
	|				AND GoodsHandover.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsHandover.Warehouse
	|	END AS Warehouse,
	|	GoodsHandover.Contract       AS Contract,
	|	GoodsHandover.Currency        AS Currency,
	|	GoodsHandover.Currency        AS ARAPCurrency,
	|	GoodsHandover.SalesOpportunity        AS SalesOpportunity,
	|	GoodsHandover.Department AS Department,
	|	GoodsHandover.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	FALSE                          AS PriceIncludesVAT,
	|	GoodsHandover.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	FALSE                          AS DepositForPackageIsRequired,
	|	NOT GoodsHandover.Posted   AS ThereAreErrorsPosted,
	|	FALSE                          AS ThereAreErrorsStatus
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref = &DocumentBasisCorrectionOfBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Purpose      AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|	0                               AS VATAmount,
	|	SUM(DocumentGoods.Sum)    AS AmountIncludingVAT
	|INTO TransferGoods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref = &DocumentBasisCorrectionOfBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Series,
	|	DocumentGoods.Package
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Purpose      AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum,
	|	DocumentGoods.VATRate       AS VATRate,
	|	SUM(DocumentGoods.VATAmount) AS VATAmount,
	|	SUM(DocumentGoods.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO ProductsFromPreviousRefunds
	|FROM
	|	Document.ReturnOfGoodsFromCustomer.Goods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref.Posted
	|	AND DocumentGoods.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Package,
	|	DocumentGoods.Series,
	|	DocumentGoods.VATRate
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	&DocumentBasis             AS DocumentSalesOfGoodsAndServices,
	|	TransferGoods.Products    AS Products,
	|	TransferGoods.ItemsType AS ItemsType,
	|	TransferGoods.Characteristic  AS Characteristic,
	|	TransferGoods.Purpose      AS Purpose,
	|	TransferGoods.Package        AS Package,
	|	TransferGoods.Series           AS Series,
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) AS Count,
	|	TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) AS NumberOfPackages,
	|	TransferGoods.VATRate       AS VATRate,
	|	CASE
	|		WHEN TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) = 0
	|			THEN TransferGoods.Price
	|		ELSE (TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0)) / (TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0))
	|	END                          AS Price,
	|	TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0) AS Sum,
	|	TransferGoods.VATAmount - ISNULL(RefundProducts.VATAmount, 0) AS VATAmount,
	|	TransferGoods.AmountIncludingVAT - ISNULL(RefundProducts.AmountIncludingVAT, 0) AS AmountIncludingVAT
	|INTO TTProducts_1
	|FROM
	|	TransferGoods AS TransferGoods
	|		LEFT JOIN ProductsFromPreviousRefunds AS RefundProducts
	|		ON TransferGoods.Products = RefundProducts.Products
	|			AND TransferGoods.Characteristic = RefundProducts.Characteristic
	|			AND TransferGoods.Purpose = RefundProducts.Purpose
	|			AND TransferGoods.Series = RefundProducts.Series
	|WHERE
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) > 0
	|	AND (TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		OR TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT CAST(&DocumentBasis AS Document.TransferOfGoodsToBailee).ToReturnReusablePackage)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	&DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	DiscrepancyCertificate.SaleOfGoodsAndServices     AS DocumentSalesOfGoodsAndServices,
	|	DiscrepancyCertificate.Products   AS Products,
	|	DiscrepancyCertificate.Characteristic AS Characteristic,
	|	DiscrepancyCertificate.Purpose     AS Purpose,
	|	DiscrepancyCertificate.Package       AS Package,
	|	DiscrepancyCertificate.Series          AS Series,
	|	SUM(DiscrepancyCertificate.Count - DiscrepancyCertificate.CountByDocument) AS Count,
	|	SUM(DiscrepancyCertificate.NumberOfPackages - DiscrepancyCertificate.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(DiscrepancyCertificate.Sum - DiscrepancyCertificate.SumByDocument) AS Sum,
	|	SUM(DiscrepancyCertificate.VATAmount - DiscrepancyCertificate.VATAmountByDocument) AS VATAmount,
	|	SUM(DiscrepancyCertificate.AmountIncludingVAT - DiscrepancyCertificate.AmountIncludingVATByDocument) AS AmountIncludingVAT
	|INTO TTCertificateOfDiscrepanciesAfterShipment
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS DiscrepancyCertificate
	|WHERE
	|	DiscrepancyCertificate.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyCertificate.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|	AND DiscrepancyCertificate.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DiscrepancyCertificate.SaleOfGoodsAndServices,
	|	DiscrepancyCertificate.Products,
	|	DiscrepancyCertificate.Characteristic,
	|	DiscrepancyCertificate.Purpose,
	|	DiscrepancyCertificate.Package,
	|	DiscrepancyCertificate.Series
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Package,
	|	Series,
	|	DocumentSalesOfGoodsAndServices
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT
	|	TTProducts_1.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TTProducts_1.Products   AS Products,
	|	TTProducts_1.Characteristic AS Characteristic,
	|	TTProducts_1.Purpose     AS Purpose,
	|	TTProducts_1.Series          AS Series,
	|	TTProducts_1.Package       AS Package,
	|	CASE
	|		WHEN TTProducts_1.Count < DiscrepancyCertificate.Count
	|			THEN TTProducts_1.Count
	|		ELSE DiscrepancyCertificate.Count
	|	END                   AS Count,
	|	CASE
	|		WHEN TTProducts_1.NumberOfPackages < DiscrepancyCertificate.NumberOfPackages
	|			THEN TTProducts_1.NumberOfPackages
	|		ELSE DiscrepancyCertificate.NumberOfPackages
	|	END                   AS NumberOfPackages,
	|	TTProducts_1.Price           AS Price,
	|	CASE
	|		WHEN TTProducts_1.Sum < DiscrepancyCertificate.Sum
	|			THEN TTProducts_1.Sum
	|		ELSE DiscrepancyCertificate.Sum
	|	END                   AS Sum,
	|	TTProducts_1.VATRate      AS VATRate,
	|	CASE
	|		WHEN TTProducts_1.VATAmount < DiscrepancyCertificate.VATAmount
	|			THEN TTProducts_1.VATAmount
	|		ELSE DiscrepancyCertificate.VATAmount
	|	END                   AS VATAmount,
	|	CASE
	|		WHEN TTProducts_1.AmountIncludingVAT < DiscrepancyCertificate.AmountIncludingVAT
	|			THEN TTProducts_1.AmountIncludingVAT
	|		ELSE DiscrepancyCertificate.AmountIncludingVAT
	|	END                   AS AmountIncludingVAT
	|FROM
	|	TTProducts_1 AS TTProducts_1
	|		INNER JOIN TTCertificateOfDiscrepanciesAfterShipment AS DiscrepancyCertificate
	|		ON TTProducts_1.Products = DiscrepancyCertificate.Products
	|			AND TTProducts_1.Characteristic = DiscrepancyCertificate.Characteristic
	|			AND TTProducts_1.Purpose = DiscrepancyCertificate.Purpose
	|			AND TTProducts_1.Package = DiscrepancyCertificate.Package
	|			AND TTProducts_1.Series = DiscrepancyCertificate.Series
	|			AND TTProducts_1.DocumentSalesOfGoodsAndServices = DiscrepancyCertificate.DocumentSalesOfGoodsAndServices
	|
	|ORDER BY
	|	TTProducts_1.DocumentSalesOfGoodsAndServices,
	|	TTProducts_1.Products,
	|	TTProducts_1.Characteristic,
	|	TTProducts_1.Purpose,
	|	TTProducts_1.Series,
	|	TTProducts_1.Package
	|";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	// Filling in the act if there is a correction of the grounds of the act.
	If FillingData.Property("CorrectionOfBasis") And ValueIsFilled(FillingData.CorrectionOfBasis) Then
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.CorrectionOfBasis);
	Else
		Query.SetParameter("DocumentBasisCorrectionOfBasis", FillingData.BasisOfAct);
	EndIf;
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus);
	
	DocumentSalesOfGoodsAndServices = FillingData.BasisOfAct;
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[5].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = ReturnedGoods.Add();
		FillPropertyValues(NewRow,CurRow);
		
		PriceManagementSystem.RecalculateAmountsInRow(NewRow, False, False, False, HeaderSelection.PriceIncludesVAT);
	EndDo;
	
EndProcedure

Procedure FillInDocumentOnBasisOfTransferOfGoodsToCustodian(Val FillingData)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	GoodsHandover.Ref        AS DocumentSalesOfGoodsAndServices,
	|	GoodsHandover.Ref        AS Ref,
	|	UNDEFINED                  AS DocumentStatus,
	|	GoodsHandover.Partner       AS Partner,
	|	GoodsHandover.Counterparty    AS Counterparty,
	|	GoodsHandover.Terms    AS Terms,
	|	CASE
	|		WHEN GoodsHandover.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|		ELSE VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|	END                         AS BusinessOperation,
	|	GoodsHandover.Organization   AS Organization,
	|	CASE
	|		WHEN GoodsHandover.Warehouse.IsFolder
	|			THEN VALUE(Catalog.Warehouses.EmptyRef)
	|		ELSE GoodsHandover.Warehouse
	|	END                         AS Warehouse,
	|	GoodsHandover.Contract       AS Contract,
	|	GoodsHandover.Currency        AS Currency,
	|	GoodsHandover.Currency        AS ARAPCurrency,
	|	GoodsHandover.SalesOpportunity        AS SalesOpportunity,
	|	GoodsHandover.Department AS Department,
	|	GoodsHandover.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	GoodsHandover.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	FALSE                          AS DepositForPackageIsRequired,
	|	NOT GoodsHandover.Posted   AS ThereAreErrorsPosted,
	|	FALSE                          AS ThereAreErrorsStatus
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|WHERE
	|	GoodsHandover.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Catalog.Assignments.EmptyRef)
	|		ELSE DocumentGoods.Purpose
	|	END                           AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	DocumentGoods.Warehouse 		    AS Warehouse,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT) AS VATRate,
	|	0                               AS VATAmount,
	|	MAX(DocumentGoods.PriceKind) AS PriceKind,
	|	SUM(DocumentGoods.Sum)    AS AmountIncludingVAT
	|INTO TransferGoods
	|FROM
	|	Document.TransferOfGoodsToBailee.Goods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref = &DocumentBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Series,
	|	DocumentGoods.Warehouse,
	|	DocumentGoods.Package,
	|	DocumentGoods.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	DocumentGoods.Products    AS Products,
	|	CatProducts.ItemsType AS ItemsType,
	|	DocumentGoods.Characteristic  AS Characteristic,
	|	DocumentGoods.Purpose      AS Purpose,
	|	DocumentGoods.Package        AS Package,
	|	DocumentGoods.Series           AS Series,
	|	SUM(DocumentGoods.Count) AS Count,
	|	SUM(DocumentGoods.NumberOfPackages) AS NumberOfPackages,
	|	AVG(DocumentGoods.Price)   AS Price,
	|	SUM(DocumentGoods.Sum)    AS Sum,
	|	DocumentGoods.VATRate       AS VATRate,
	|	SUM(DocumentGoods.VATAmount) AS VATAmount,
	|	SUM(DocumentGoods.AmountIncludingVAT) AS AmountIncludingVAT
	|INTO ProductsFromPreviousRefunds
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS DocumentGoods
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|WHERE
	|	DocumentGoods.Ref.Posted
	|	AND DocumentGoods.DocumentSalesOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	DocumentGoods.Products,
	|	CatProducts.ItemsType,
	|	DocumentGoods.Characteristic,
	|	DocumentGoods.Purpose,
	|	DocumentGoods.Package,
	|	DocumentGoods.Series,
	|	DocumentGoods.VATRate
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	&DocumentBasis             AS DocumentSalesOfGoodsAndServices,
	|	TransferGoods.Products    AS Products,
	|	TransferGoods.ItemsType AS ItemsType,
	|	TransferGoods.Characteristic  AS Characteristic,
	|	TransferGoods.Purpose      AS Purpose,
	|	TransferGoods.Package        AS Package,
	|	TransferGoods.Series           AS Series,
	|	TransferGoods.Warehouse           AS Warehouse,
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) AS Count,
	|	TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) AS NumberOfPackages,
	|	TransferGoods.VATRate       AS VATRate,
	|	TransferGoods.PriceKind         AS PriceKind,
	|	CASE
	|		WHEN TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0) = 0
	|			THEN TransferGoods.Price
	|		ELSE (TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0)) / (TransferGoods.NumberOfPackages - ISNULL(RefundProducts.NumberOfPackages, 0))
	|	END                          AS Price,
	|	TransferGoods.Sum - ISNULL(RefundProducts.Sum, 0) AS Sum,
	|	TransferGoods.VATAmount - ISNULL(RefundProducts.VATAmount, 0) AS VATAmount,
	|	TransferGoods.AmountIncludingVAT - ISNULL(RefundProducts.AmountIncludingVAT, 0) AS AmountIncludingVAT
	|FROM
	|	TransferGoods AS TransferGoods
	|		LEFT JOIN ProductsFromPreviousRefunds AS RefundProducts
	|		ON TransferGoods.Products = RefundProducts.Products
	|			AND TransferGoods.Characteristic = RefundProducts.Characteristic
	|			AND TransferGoods.Purpose = RefundProducts.Purpose
	|			AND TransferGoods.Series = RefundProducts.Series
	|WHERE
	|	TransferGoods.Count - ISNULL(RefundProducts.Count, 0) > 0
	|	AND (TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|		OR TransferGoods.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND NOT CAST(&DocumentBasis AS Document.TransferOfGoodsToBailee).ToReturnReusablePackage)
	|
	|ORDER BY
	|	&DocumentBasis,
	|	TransferGoods.Products,
	|	TransferGoods.ItemsType,
	|	TransferGoods.Characteristic,
	|	TransferGoods.Purpose,
	|	TransferGoods.Warehouse,
	|	TransferGoods.Package,
	|	TransferGoods.Series";
	
	Query.SetParameter("DocumentBasis", FillingData);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		HeaderSelection.DocumentStatus,
		HeaderSelection.ThereAreErrorsPosted,
		HeaderSelection.ThereAreErrorsStatus);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	TableOfGoods = QueryBatch[3].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = ReturnedGoods.Add();
		FillPropertyValues(NewRow,CurRow);
		
		PriceManagementSystem.RecalculateAmountsInRow(NewRow, False, False, False, False);
	EndDo;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		
		WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
		WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, ReturnedGoods, False);
		
		StructureOfActionsReturned = New Structure();
		CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
		StructureOfActionsReturned.Insert("FillInCheckQualityDateOfQualityConfirmation",
			CacheQualityControl);
		BatchProcessingOfTablePartServer.TreatTS(ReturnedGoods, StructureOfActionsReturned);
		
		Return;
	EndIf;
	
	ThisIsOrderAsInvoice = Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	Organization               = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	Warehouse                     = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, BankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization = Organization;
	ParametersStructure.CashAccount 		= CashAccount;
	ParametersStructure.PaymentMethod = PaymentMethod;

	CashAccount                     = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	Priority                 = SettingsValueCached.GetDefaultPriority(Priority);
	NotShipInInstallments        = True;
	OneDateReceipt     = True;
	If ThisIsOrderAsInvoice Then
		Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon;
	Else
		Status = Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn;
		If Not GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
			DateOfShipment = CurrentSessionDate();
		EndIf;
	EndIf; 
	
	StructureOfActions = New Structure();
	DocumentParameters = Documents.RequestForReturnOfGoodsFromCustomer.DocumentParametersForSoftwareActions(ThisObject);
	StringFields_ = "SupplyOption";
	ProvisionInDocumentsClientServer.AddCollateralActions(StructureOfActions, StringFields_, DocumentParameters);
	BatchProcessingOfTablePartServer.TreatTS(SubstituteGoods, StructureOfActions, Undefined);

	GoodsReceiptOption = Constants.GoodsReceiptOption.Get();
	
	FillParameters = Documents.RequestForReturnOfGoodsFromCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject, False, ToReturnReusablePackage);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);

	StructureOfActions = New Structure();
	StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	CacheReturnedItems = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	CacheReplacementProducts = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	If Not ValueIsFilled(DocumentSalesOfGoodsAndServices) Then
		BatchProcessingOfTablePartServer.TreatTS(ReturnedGoods, StructureOfActions, CacheReturnedItems);
	EndIf;
		
	BatchProcessingOfTablePartServer.TreatTS(SubstituteGoods, StructureOfActions, CacheReplacementProducts);

	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, ReturnedGoods, False);
	
	StructureOfSubstituteActions = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfSubstituteActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfSubstituteActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);

	StructureOfActionsReturned = New Structure;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	StructureOfActionsReturned.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActionsReturned.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CacheReturnedItems.ProcessedRows,
		StructureOfActionsReturned,
		ReturnedGoods,
		Undefined);
		
	StructureOfActionsReturned = New Structure();
	CacheQualityControl = QualityControl.DataCacheOfMechanism(ThisObject);
	StructureOfActionsReturned.Insert("FillInCheckQualityDateOfQualityConfirmation", CacheQualityControl);
	BatchProcessingOfTablePartServer.TreatTS(ReturnedGoods, StructureOfActionsReturned);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CacheReplacementProducts.ProcessedRows,
		StructureOfSubstituteActions,
		SubstituteGoods,
		Undefined);
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales")
		Or ValueIsFilled(Partner) And Not ValueIsFilled(Terms) Then
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
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
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

#Region Other

Function GetDocumentAmount()
	
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
	|	NOT Goods.Canceled AND
	|	(Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage
	|	OR &PackageDepositIsRequired)
	|");
	
	Query.SetParameter("Goods", ReturnedGoods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

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
	
	Query.SetParameter("Goods", SubstituteGoods.Unload(,"Products,AmountIncludingVAT,Canceled"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	SumOfReturnTareOfReplacementRows = Upload0[0].AmountIncludingVAT;
	Return SumOfReturnTareOfReplacementRows;
	
EndFunction

// Generates a check for filling in prices in the document
//
// Parameters:
// Cancel - Boolean
//
Procedure ControlOfFillingOfPricesOfReturnedGoods(Cancel)
	
	FilterParameters = New Structure("Canceled", False); 
	TableOfCheckedProducts = ThisObject.ReturnedGoods.Unload(FilterParameters);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReturnOfGoodsFromCustomerGoods.Products  AS Products,
	|	ReturnOfGoodsFromCustomerGoods.LineNumber   AS LineNumber,
	|	ReturnOfGoodsFromCustomerGoods.Price          AS Price
	|INTO InspectedGoods
	|FROM
	|	&TableOfCheckedProducts AS ReturnOfGoodsFromCustomerGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableOfGoods_.LineNumber,
	|	CASE
	|		WHEN
	|			TemporaryTableOfGoods_.Price = 0
	|			AND (TemporaryTableOfGoods_.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|			OR &PackageDepositIsRequired
	|			OR NOT &ReturnOfMultiTurnContainers)
	|			AND NOT &BusinessOperation IN (VALUE(Enum.BusinessTransactions.ReturnFromCustodian),
	|				VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)) THEN
	|				TRUE
	|		ELSE
	|				FALSE
	|	END                                            AS ThereAreErrorsFillingPrices
	|FROM
	|	InspectedGoods AS TemporaryTableOfGoods_";
	
	Query.SetParameter("TableOfCheckedProducts", TableOfCheckedProducts);
	Query.SetParameter("ReturnOfMultiTurnContainers", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	
	Result = Query.Execute();

	Selection = Result.Select();

	While Selection.Next() Do
		If Selection.ThereAreErrorsFillingPrices Then
			
			ErrorText = NStr("vi = 'Cột ""Giá"" trong dòng %LineNumber% của danh sách ""Hàng trả lại"" không được điền';
							|ru = 'Не заполнена колонка ""Цена"" в строке %LineNumber% списка ""Возвращаемые товары""';
							|en = 'Column ""Price"" in line %LineNumber% of the ""Goods pending return"" list is not filled in'; fa = 'Column ""Price"" in line %LineNumber% of the ""Goods pending return"" list is not filled in';
							|it = 'La colonna ""Prezzo"" nella riga %LineNumber% dell''elenco ""Merci in corso di resa"" non è stata compilata';
							|pl = 'Kolumna „Cena” nie jest wypełniona w wierszu %LineNumber% listy „wiersze pozycji zwracane”';
							|tr = '""İade edilen ürünler"" listesinin %LineNumber% satırında ""Fiyat"" sütunu eksik'");
			ErrorText = StrReplace(ErrorText, "%LineNumber%",  Selection.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("ReturnedGoods", Selection.LineNumber,"Price"),
				,
				Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Function QueryTextForItemsToBeReceived()
	
	QueryText = "SELECT
	|	CAST(GoodsTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(GoodsTable.RowCode AS NUMBER) AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN CAST(GoodsTable.ProductsRecordingAsReceived AS Catalog.Products)
	|		ELSE CAST(GoodsTable.Products AS Catalog.Products)
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN CAST(GoodsTable.CharacteristicRecordingAsReceived AS Catalog.ItemsCharacteristics)
	|		ELSE CAST(GoodsTable.Characteristic AS Catalog.ItemsCharacteristics)
	|	END AS Characteristic,
	|	CAST(GoodsTable.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(GoodsTable.Count AS NUMBER) AS Count,
	|	CAST(GoodsTable.AmountIncludingVAT AS NUMBER) AS AmountIncludingVAT,
	|	CAST(GoodsTable.Canceled AS BOOLEAN) AS Canceled,
	|	CAST(GoodsTable.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(GoodsTable.Series AS Catalog.ItemsBatches) AS Series,
	|	&RequestForReturnOfGoodsFromCustomer AS Request
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
	|	GoodsToReceive.Products   AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	SUM(GoodsToReceive.ToRegisterInvoicesByReferenceReceipt
	|		* &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving) AS AllowableVariance,
	|	GoodsToReceive.Warehouse          AS Warehouse,
	|	GoodsToReceive.Series          AS Series
	|FROM
	|	AccumulationRegister.GoodsToReceive.Turnovers(&StartPeriod_,&ConPeriod,,
	|		DocumentInflow = &RequestForReturnOfGoodsFromCustomer) AS GoodsToReceive
	|	INNER JOIN Catalog.Products AS ProductData_1
	|		ON ProductData_1.Ref = GoodsToReceive.Products
	|	INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS DataOfUnit
	|		ON DataOfUnit.Ref = ProductData_1.UnitOfMeasure
	|		AND DataOfUnit.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|			
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	GoodsToReceive.Warehouse,
	|	GoodsToReceive.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Request                             AS Request,
	|	GoodsTable.Products                       AS Products,
	|	GoodsTable.Characteristic                     AS Characteristic,
	|	GoodsTable.Package                           AS Package,
	|	GoodsTable.Warehouse                              AS Warehouse,
	|	SUM(GoodsTable.AmountIncludingVAT)                   AS AmountIncludingVAT,
	|	SUM(GoodsTable.Count)                  AS Count,
	|	GoodsTable.Series                              AS Series
	|
	|INTO TTTableOfGoodsForInspection
	|FROM
	|	GoodsTable AS GoodsTable
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|		ON RequestForReturnOfGoodsFromCustomer.Ref = GoodsTable.Request
	|		AND NOT RequestForReturnOfGoodsFromCustomer.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
	|													VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|
	|GROUP BY 
	|	GoodsTable.Request,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Package,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Inflow.OrderDocument 		   AS OrderDocument,
	|	Inflow.Products   AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	Inflow.Warehouse 		   AS Warehouse,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                        AS AdvancedWarehousingOnReceiving,
	|	Inflow.Series            AS Series,
	|	SUM(Inflow.Issued_1) AS Issued_1,
	|	SUM(Inflow.Accepted)   AS Accepted,
	|	SUM(Inflow.Ordered)  AS Ordered,
	|	SUM(Inflow.ByNotes) AS ByNotes
	|
	|INTO TTAccepted
	|FROM (SELECT
	|		Balance.DocumentInflow                             AS OrderDocument,
	|		Balance.Products                                    AS Products,
	|		Balance.Characteristic                                  AS Characteristic,
	|		Balance.ToRegisterInvoicesByReferenceExpense        AS Issued_1,
	|		0                                                       AS Accepted,
	|		Balance.Warehouse                                           AS Warehouse,
	|		Balance.Series                                           AS Series,
	|		0                                                       AS Ordered,
	|		Balance.ToRegisterGoodsReceiptsTurnover           AS ByNotes
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(,,,,
	|			DocumentInflow = &RequestForReturnOfGoodsFromCustomer) AS Balance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Request                                 AS OrderDocument,
	|		GoodsTable.Products                           AS Products,
	|		GoodsTable.Characteristic                         AS Characteristic,
	|		0                                                    AS Issued_1,
	|		0                                                    AS Accepted,
	|		GoodsTable.Warehouse                                  AS Warehouse,
	|		GoodsTable.Series                                  AS Series,
	|		GoodsTable.Count                             AS Ordered,
	|		0                                                    AS ByNotes
	|	FROM
	|		TTTableOfGoodsForInspection AS GoodsTable) AS Inflow
	|GROUP BY
	|	Inflow.OrderDocument,
	|	Inflow.Products,
	|	Inflow.Characteristic,
	|	Inflow.Warehouse,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	Inflow.Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products                          AS Products,
	|	Inflow.Characteristic                        AS Characteristic,
	|	Inflow.Warehouse                                 AS Warehouse,
	|	Inflow.Series                                 AS Series,
	|	CASE 
	|		WHEN Inflow.Ordered - Inflow.Issued_1 < 0 
	|			THEN Inflow.Ordered - Inflow.Issued_1
	|		WHEN NOT Inflow.AdvancedWarehousingOnReceiving 
	|			THEN  Inflow.Ordered - Inflow.Issued_1
	|		ELSE CASE 
	|					WHEN Inflow.Issued_1 > Inflow.Accepted
	|						THEN Inflow.Ordered - Inflow.Issued_1
	|					ELSE Inflow.Ordered - Inflow.Accepted
	|			END
	|	END - 
	|	CASE
	|		WHEN Inflow.ByNotes > 0
	|			THEN Inflow.ByNotes
	|		ELSE 0
	|	END                                             AS ToRegisterBalance,
	|	Inflow.Ordered                              AS Count
	|FROM
	|	TTAccepted AS Inflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowCode AS RowCode,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	GoodsTable.Count AS Count,
	|	0,
	|	FALSE
	|FROM
	|	GoodsTable AS GoodsTable
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|		ON RequestForReturnOfGoodsFromCustomer.Ref = GoodsTable.Request
	|		AND RequestForReturnOfGoodsFromCustomer.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
	|													VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|
	|ORDER BY
	|	LineNumber
	|";

	Return QueryText;

EndFunction

Function QueryTextForRequestsForReturnOfGoodsFromCustomers()
	
	QueryText =
	"SELECT
	|	CAST(GoodsTable.LineNumber AS NUMBER) AS LineNumber,
	|	CAST(GoodsTable.RowCode AS NUMBER) AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN CAST(GoodsTable.ProductsRecordingAsReceived AS Catalog.Products)
	|		ELSE CAST(GoodsTable.Products AS Catalog.Products)
	|	END AS Products,
	|	CASE
	|		WHEN GoodsTable.Damage
	|			THEN CAST(GoodsTable.CharacteristicRecordingAsReceived AS Catalog.ItemsCharacteristics)
	|		ELSE CAST(GoodsTable.Characteristic AS Catalog.ItemsCharacteristics)
	|	END AS Characteristic,
	|	CAST(GoodsTable.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	CAST(GoodsTable.Count AS NUMBER) AS Count,
	|	CAST(GoodsTable.AmountIncludingVAT AS NUMBER) AS AmountIncludingVAT,
	|	CAST(GoodsTable.Canceled AS BOOLEAN) AS Canceled,
	|	CAST(GoodsTable.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	&RequestForReturnOfGoodsFromCustomer AS Request
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
	|	GoodsToReceive.Products   AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	SUM(GoodsToReceive.ForRegistrationOnReturnsQuantityTurnover
	|		* &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving) AS AllowableVariance,
	|	RequestForReturnOfGoodsFromCustomerReturnedGoods.Warehouse AS Warehouse
	|FROM
	|	#RequestsForReturnsTurnoverExpanded1 AS GoodsToReceive
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
	|		ON GoodsToReceive.ReferenceOrder = RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref
	|			 AND GoodsToReceive.RowCode = RequestForReturnOfGoodsFromCustomerReturnedGoods.RowCode
	|	INNER JOIN Catalog.Products AS ProductData_1
	|		ON ProductData_1.Ref = GoodsToReceive.Products
	|	INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS DataOfUnit
	|		ON DataOfUnit.Ref = ProductData_1.UnitOfMeasure
	|		AND DataOfUnit.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|			
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	RequestForReturnOfGoodsFromCustomerReturnedGoods.Warehouse
	|
	|	UNION ALL
	|
	|SELECT
	|	GoodsToReceive.Products   AS Products,
	|	GoodsToReceive.Characteristic AS Characteristic,
	|	SUM(GoodsToReceive.ForRegistrationOnReturnsQuantityTurnover
	|		* &AllowableDeviationOfMeasuringGoodsShipmentAndReceiving) AS AllowableVariance,
	|	RequestForReturnOfGoods.Warehouse AS Warehouse
	|FROM
	|	#RequestsForReturnsTurnoverExpanded2 AS GoodsToReceive
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoods
	|		ON GoodsToReceive.ReferenceOrder = RequestForReturnOfGoods.Ref
	|	INNER JOIN Catalog.Products AS ProductData_1
	|		ON ProductData_1.Ref = GoodsToReceive.Products
	|	INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS DataOfUnit
	|		ON DataOfUnit.Ref = ProductData_1.UnitOfMeasure
	|		AND DataOfUnit.MeasuredValueType IN (&DimensionalTypesOfUnits)
	|
	|GROUP BY
	|	GoodsToReceive.Products,
	|	GoodsToReceive.Characteristic,
	|	RequestForReturnOfGoods.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Request                             AS Request,
	|	GoodsTable.Products                       AS Products,
	|	GoodsTable.Characteristic                     AS Characteristic,
	|	GoodsTable.Package                           AS Package,
	|	GoodsTable.Warehouse                              AS Warehouse,
	|	SUM(GoodsTable.AmountIncludingVAT)                   AS AmountIncludingVAT,
	|	SUM(GoodsTable.Count)                  AS Count
	|INTO TTTableOfGoodsForInspection
	|FROM
	|	GoodsTable AS GoodsTable
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|		ON RequestForReturnOfGoodsFromCustomer.Ref = GoodsTable.Request
	|		AND NOT RequestForReturnOfGoodsFromCustomer.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
	|													VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|
	|GROUP BY 
	|	GoodsTable.Request,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Package,
	|	GoodsTable.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	Inflow.OrderDocument          AS OrderDocument,
	|	Inflow.Products   AS Products,
	|	Inflow.Characteristic AS Characteristic,
	|	Inflow.Warehouse          AS Warehouse,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END                        AS AdvancedWarehousingOnReceiving,
	|	SUM(Inflow.Issued_1) AS Issued_1,
	|	SUM(Inflow.Accepted)   AS Accepted,
	|	SUM(Inflow.Ordered)  AS Ordered
	|INTO TTAccepted
	|FROM (SELECT
	|		Balance.ReferenceOrder                                    AS OrderDocument,
	|		Balance.Products                                    AS Products,
	|		Balance.Characteristic                                  AS Characteristic,
	|		Balance.IssuedByReturnsQuantityTurnover            AS Issued_1,
	|		0                                                       AS Accepted,
	|		RequestForReturnOfGoodsFromCustomerReturnedGoods.Warehouse AS Warehouse,
	|		0                                                       AS Ordered
	|	FROM
	|		#RequestsForReturnsTurnoverExpanded3 AS Balance
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
	|			ON Balance.ReferenceOrder = RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref
	|				 AND Balance.RowCode = RequestForReturnOfGoodsFromCustomerReturnedGoods.RowCode
	|				
	|	
	|	UNION ALL
	|
	|		SELECT
	|		Balance.ReferenceOrder                                 AS OrderDocument,
	|		Balance.Products                                 AS Products,
	|		Balance.Characteristic                               AS Characteristic,
	|		Balance.IssuedByReturnsQuantityTurnover         AS Issued_1,
	|		0                                                    AS Accepted,
	|		RequestForReturnOfGoods.Warehouse                         AS Warehouse,
	|		0                                                    AS Ordered
	|	FROM
	|		#RequestsForReturnsTurnoverExpanded4 AS Balance
	|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoods
	|			ON Balance.ReferenceOrder = RequestForReturnOfGoods.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsToReceiveBalance.DocumentInflow        AS OrderDocument,
	|		GoodsToReceiveBalance.Products               AS Products,
	|		GoodsToReceiveBalance.Characteristic             AS Characteristic,
	|		0                                                    AS Issued_1,
	|		GoodsToReceiveBalance.GoodsReceiptNotesToRegisterExpense   AS Accepted,
	|		GoodsToReceiveBalance.Warehouse                      AS Warehouse,
	|		0                                                    AS Ordered
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(,,,,
	|			DocumentInflow = &RequestForReturnOfGoodsFromCustomer) AS GoodsToReceiveBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.Request                                 AS OrderDocument,
	|		GoodsTable.Products                           AS Products,
	|		GoodsTable.Characteristic                         AS Characteristic,
	|		0                                                    AS Issued_1,
	|		0                                                    AS Accepted,
	|		GoodsTable.Warehouse                                  AS Warehouse,
	|		GoodsTable.Count                             AS Ordered
	|	FROM
	|		TTTableOfGoodsForInspection AS GoodsTable) AS Inflow
	|GROUP BY
	|	Inflow.OrderDocument,
	|	Inflow.Products,
	|	Inflow.Characteristic,
	|	Inflow.Warehouse,
	|	CASE
	|		WHEN Inflow.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				AND Inflow.OrderDocument.Date >= Inflow.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Inflow.Products                          AS Products,
	|	Inflow.Characteristic                        AS Characteristic,
	|	Inflow.Warehouse                                 AS Warehouse,
	|	CASE 
	|		WHEN Inflow.Ordered - Inflow.Issued_1 < 0
	|			THEN Inflow.Ordered - Inflow.Issued_1
	|		WHEN NOT Inflow.AdvancedWarehousingOnReceiving 
	|			THEN  Inflow.Ordered - Inflow.Issued_1
	|		ELSE CASE 
	|					WHEN Inflow.Issued_1 > Inflow.Accepted
	|						THEN Inflow.Ordered - Inflow.Issued_1
	|					ELSE Inflow.Ordered - Inflow.Accepted
	|			END
	|	END                                             AS ToRegisterBalance,
	|	Inflow.Ordered                              AS Count
	|FROM
	|	TTAccepted AS Inflow
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowCode AS RowCode,
	|	ISNULL(&QueryTextPackagingFactor, 1) AS PackagingFactor,
	|	GoodsTable.Count AS Count,
	|	0,
	|	FALSE
	|FROM
	|	GoodsTable AS GoodsTable
	|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
	|		ON RequestForReturnOfGoodsFromCustomer.Ref = GoodsTable.Request
	|		AND RequestForReturnOfGoodsFromCustomer.Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon),
	|													VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected))
	|
	|ORDER BY
	|	LineNumber";
	
	// RequestsForReturnsTurnoverExpanded1
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.BeginOfPeriod = "&StartPeriod_";
	TableFormationParameters.EndOfPeriod = "&ConPeriod";
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &RequestForReturnOfGoodsFromCustomer
		|	AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "ToRegisterForReturns";
	TableFormationParameters.Resources = "Count";
	
	RequestsForReturnsTurnoverExpanded1 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnsTurnoverExpanded1",
		RequestsForReturnsTurnoverExpanded1);
	
	// RequestsForReturnsTurnoverExpanded2
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &RequestForReturnOfGoodsFromCustomer
		|	AND RowCode = 0";
	
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
	
	RequestsForReturnsTurnoverExpanded2 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnsTurnoverExpanded2",
		RequestsForReturnsTurnoverExpanded2);
	
	// RequestsForReturnsTurnoverExpanded3
	TableFormationParameters.BeginOfPeriod = "";
	TableFormationParameters.EndOfPeriod = "";
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &RequestForReturnOfGoodsFromCustomer
		|	AND RowCode <> 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic, RowCode";
	TableFormationParameters.Indicators = "RegisteredOnReturns";
	
	RequestsForReturnsTurnoverExpanded3 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnsTurnoverExpanded3",
		RequestsForReturnsTurnoverExpanded3);
	
	// RequestsForReturnsTurnoverExpanded4
	TableFormationParameters.ConditionText =
		"ReferenceOrder = &RequestForReturnOfGoodsFromCustomer
		|	AND RowCode = 0";
	TableFormationParameters.Group = "ReferenceOrder, Products, Characteristic";
	
	RequestsForReturnsTurnoverExpanded4 =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	QueryText = StrReplace(QueryText,
		"#RequestsForReturnsTurnoverExpanded4",
		RequestsForReturnsTurnoverExpanded4);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
