#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object.
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	TransitionDate = Date('00010101');
	If AdditionalParameters <> Undefined Then
		AdditionalParameters.Property("NewDate", TransitionDate);
	EndIf;
	
	CurrentStatus = Status;
	
	Status = Enums.StatusesOfCustomerInvoices[NewStatus];
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	Cancel = False;
	SeriesFillCheckParameters = ProductsServer.SeriesFillCheckParameters();
	SeriesFillCheckParameters.IssueMessages = False;
	ProductsServer.CheckSeriesCompletion(ThisObject,SeriesSpecificationParameters,Cancel,,SeriesFillCheckParameters);
	
	If Cancel Then
		MessageText = NStr("vi = 'Chưa đặt trạng thái ""%Status%"" - có hàng hóa cần chỉ ra sê-ri.';
							|ru = 'Статус ""%Status%"" не установлен - есть товары, по которым нужно указать серии.';
							|en = 'Status ""%Status%"" is not set, there are goods by which it is required to specify batch.'; fa = 'Status ""%Status%"" is not set, there are goods by which it is required to specify batch.';
							|it = 'Lo stato ""%Status%"" non è impostato - esistono merci per le quali è necessario indicare le serie.';
							|pl = 'Status ""%Status%"" nie jest ustawiony - istnieją wiersze pozycji, dla których musisz określić serie.';
							|tr = 'Durum ""%Status%"" ayarlanmamıştır - bir erinin belirtilmesi gereken ürünler vardır.'");
		MessageText = StrReplace(MessageText,"%Status%",Status); 
		Common.MessageToUser(MessageText);
		
		Status = CurrentStatus;
	Else
		// Setting the date of transfer of ownership
		If ValueIsFilled(TransitionDate) Then
			
			If BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
				Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
				DateOfTransferOfTitleToGoods = TransitionDate;
			EndIf;
			
			Calendar = Catalogs.BusinessCalendars.EmptyRef();
			
			If GetFunctionalOption("ToUseTermsOfSales") Then
				
				DetailsOfAgreement = Common.ObjectAttributesValues(Terms,
					"ReusablePackageReturnCycleLength, CalculatePackageReturnDateAccordingToCalendar, ScheduleOfPackageReturn, Calendar");
					
				ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
					ThisObject,
					DetailsOfAgreement.ReusablePackageReturnCycleLength,
					DetailsOfAgreement.CalculatePackageReturnDateAccordingToCalendar,
					DetailsOfAgreement.ScheduleOfPackageReturn);
				
				Calendar = DetailsOfAgreement.Calendar;
				
			EndIf;
			
			For Each Page1 In PaymentScheduleSteps Do
				If Page1.CalculateFrom = Enums.PaymentDateCalculationOptions.FromDateOfTransferOfTitleToGoods Then
					ParametersForFillingInPaymentDate = PaymentStepsClientServer.PaymentDateCalculationParameters();
					ParametersForFillingInPaymentDate.CalculateFrom = Page1.CalculateFrom;
					ParametersForFillingInPaymentDate.OrderDate = Date(1,1,1);
					ParametersForFillingInPaymentDate.DateOfShipment = Date;
					ParametersForFillingInPaymentDate.DateOfTransferOfTitleToGoods = DateOfTransferOfTitleToGoods;
					ParametersForFillingInPaymentDate.ApprovalDate = Date(1,1,1);
					ParametersForFillingInPaymentDate.Calendar = Calendar;
					ParametersForFillingInPaymentDate.Move = Page1.Move;
					ParametersForFillingInPaymentDate.DeadlineOfTransferOfTitleToGoods = 0;
					
					If ValueIsFilled(Calendar) Then
						Page1.PaymentDate = PaymentStepsServerCall.PaymentDateByCalendar(ParametersForFillingInPaymentDate);
					Else
						Page1.PaymentDate = PaymentStepsServerCall.PaymentDateWithoutCalendar(ParametersForFillingInPaymentDate);
					EndIf;
				EndIf;
			EndDo;
			
		EndIf;
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);
	
	Return Not Cancel;
	
EndFunction

// This function generates temporary document data
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	&Date					AS Date,
	|	&Organization			AS Organization,
	|	UNDEFINED			AS Partner,
	|	UNDEFINED			AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	&VATTaxation		AS VATTaxation,
	|	&BusinessOperation	AS BusinessOperation,
	|	FALSE					AS ThereAreTransactionsInTablePart,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END					AS Department,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END					AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END					AS SalesOpportunity,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension		AS SetAccountingDimension,
	|	TableOfGoods.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END										AS QuantityByGBRN,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	TableOfGoods.Warehouse						AS Warehouse,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.FEACNCode						AS FEACNCode,
	|	TableOfGoods.Package						AS Package,
	|	TableOfGoods.Price							AS Price,
	|	TableOfGoods.Sum + (TableOfGoods.VATAmount * &PriceIncludesVAT) AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	TableOfGoods.ManualDiscount			AS ManualDiscount,
	|	TableOfGoods.DiscountMarkupAmount	AS DiscountMarkupAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	TableOfGoods.SalesOrder					AS OrderDocument,
	|	TableOfGoods.ARAPObject				AS ARAPObject,
	|	&FieldTextTableOfGoodsCCDNumber_			AS CCDNumber,
	|	TableOfGoods.PartnerProducts			AS PartnerProducts
	|INTO TTTableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension		AS SetAccountingDimension,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	CASE
	|		WHEN &SalesViaCommissionAgent
	|			THEN Dimension.StorageLocation
	|		ELSE TableOfGoods.Warehouse
	|	END 										AS Warehouse,
	|	TableOfGoods.OrderDocument						AS SalesOrder,
	|	TableOfGoods.ARAPObject				AS ARAPObject,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.FEACNCode						AS FEACNCode,
	|	TableOfGoods.Package						AS Package,
	|	TableOfGoods.Price							AS Price,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	TableOfGoods.ManualDiscount			AS ManualDiscount,
	|	TableOfGoods.DiscountMarkupAmount	AS DiscountMarkupAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.PartnerProducts			AS PartnerProducts
	|INTO TableOfGoods
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	CatalogProducts.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|												VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfGoods.LineNumber					AS LineNumber,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	TableOfGoods.Series						AS Series,
	|	TableOfGoods.BatchesIndicationStatus			AS BatchesIndicationStatus,
	|	TableOfGoods.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableOfGoods.SetAccountingDimension		AS SetAccountingDimension,
	|	TableOfGoods.Count					AS Count,
	|	TableOfGoods.QuantityByGBRN				AS QuantityByGBRN,
	|	TableOfGoods.NumberOfPackages			AS NumberOfPackages,
	|	Dimension.StorageLocation						AS Warehouse,
	|	TableOfGoods.OrderDocument						AS SalesOrder,
	|	TableOfGoods.ARAPObject				AS ARAPObject,
	|	TableOfGoods.VATRate					AS VATRate,
	|	TableOfGoods.FEACNCode						AS FEACNCode,
	|	TableOfGoods.Package						AS Package,
	|	TableOfGoods.Price							AS Price,
	|	TableOfGoods.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableOfGoods.VATAmount						AS VATAmount,
	|	TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|	TableOfGoods.VATAmountMan AS VATAmountMan,
	|	TableOfGoods.AmountARAP			AS AmountARAP,
	|	TableOfGoods.ManualDiscount			AS ManualDiscount,
	|	TableOfGoods.DiscountMarkupAmount	AS DiscountMarkupAmount,
	|	0											AS CommissionAmount,
	|	0											AS AmountVATRemuneration,
	|	&SalesOpportunity										AS SalesOpportunity,
	|	TableOfGoods.Purpose					AS Purpose,
	|	TRUE										AS SelectTypesOfStocks,
	|	TableOfGoods.CCDNumber						AS CCDNumber,
	|	TableOfGoods.PartnerProducts			AS PartnerProducts
	|FROM
	|	TTTableOfGoods AS TableOfGoods
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|		ON TableOfGoods.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableOfGoods.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	&UseTraceableImportedGoodsAccounting
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND CatalogProducts.TracedGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension		AS SetAccountingDimension,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.Package						AS Package,
	|	TableTypesOfStocks_.Price							AS Price,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject				AS ARAPObject,
	|	TableTypesOfStocks_.Count					AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END											AS QuantityByGBRN,
	|	TableTypesOfStocks_.NumberOfPackages			AS NumberOfPackages,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	TableTypesOfStocks_.ExciseTaxAmount					AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ManualDiscount			AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount	AS DiscountMarkupAmount
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableTypesOfStocks_.LineNumber					AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.SetAccountingDimension		AS SetAccountingDimension,
	|	Dimension.Products							AS Products,
	|	Dimension.Characteristic						AS Characteristic,
	|	Dimension.Series									AS Series,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber						AS CCDNumber,
	|	TableTypesOfStocks_.FEACNCode						AS FEACNCode,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|	TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|	TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|	TableTypesOfStocks_.Package						AS Package,
	|	TableTypesOfStocks_.Price							AS Price,
	|	VALUE(Catalog.Warehouses.EmptyRef)		AS OriginWarehouse,
	|	Dimension.StorageLocation							AS Warehouse,
	|	TableTypesOfStocks_.SalesOrder					AS SalesOrder,
	|	TableTypesOfStocks_.ARAPObject				AS ARAPObject,
	|	&SalesOpportunity											AS SalesOpportunity,
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN				AS QuantityByGBRN,
	|	TableTypesOfStocks_.NumberOfPackages			AS NumberOfPackages,
	|	TableTypesOfStocks_.AmountIncludingVAT					AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount						AS VATAmount,
	|	TableTypesOfStocks_.AmountARAP			AS AmountARAP,
	|	TableTypesOfStocks_.ManualDiscount			AS ManualDiscount,
	|	TableTypesOfStocks_.DiscountMarkupAmount	AS DiscountMarkupAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount					AS ExciseTaxAmount,
	|	&InventoryOwnerAttributesAreSpecifiedManually						AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = Dimension.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTTypesOfStocks";
	
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
	Query.SetParameter("Manager", Manager);
	Query.SetParameter("Department", Department);
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.SetParameter("PriceIncludesVAT", ?(PriceIncludesVAT, 0, 1));
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("OrderSales", OrderSales);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers"));
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities",
								GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities"));
	Query.SetParameter("SalesAgainstSeveralOrders", OrderSales
																And Not ValueIsFilled(SalesOrder));
	Query.SetParameter("TableOfGoods", TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_", InventoryKinds);
	Query.SetParameter("SalesViaCommissionAgent", 
								ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation));
	
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

// Fills the given dimensions of the item. Used in the leftovers report for organizations.
//
Procedure FillInProductTrackingForm() Export
	
	FillInProductTrackingDataInTabularPartsOfProducts();
	
EndProcedure

// Fills in the terms of sales for the sale of goods and services
//
// Parameters:
//	SalesTermsAndConditions - Structure - Structure to fill in.
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
	
	If SalesTermsAndConditions.NewCommissionScheme
		And SalesTermsAndConditions.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		If Not (BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit 
			And ValueIsFilled(Terms)
			And Common.ObjectAttributeValue(Terms, "SaleWithDeferredTransferOfTitleIsAllowed")) Then
			BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent;
		EndIf;
	Else
		BusinessOperation = SalesTermsAndConditions.BusinessOperation;
	EndIf;
	
	PriceIncludesVAT       = SalesTermsAndConditions.PriceIncludesVAT;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization) And SalesTermsAndConditions.Organization <> Organization;
	PaymentFormChanged = ValueIsFilled(SalesTermsAndConditions.PaymentMethod) And SalesTermsAndConditions.PaymentMethod <> PaymentMethod;
	
	PaymentMethod = SalesTermsAndConditions.PaymentMethod;
	
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	
	If OrganizationChanged Or PaymentFormChanged Then
		
		ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
		ParametersStructure.Organization    			= Organization;
		ParametersStructure.LineOfBusiness	= LineOfBusiness;
		ParametersStructure.PaymentMethod				= PaymentMethod;
		ParametersStructure.Individual			= Courier;
		CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);

	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_ Then
		If ValueIsFilled(SalesTermsAndConditions.Counterparty) And SalesTermsAndConditions.Counterparty<>Counterparty Then
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
		
		Contract = SalesServer.GetDefaultContract(
			ThisObject,
			?(SalesTermsAndConditions.BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting,
				Enums.BusinessTransactions.SaleToCustomer,
				SalesTermsAndConditions.BusinessOperation
			),
			?(ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation), Undefined, ARAPCurrency),
			,
			ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation));
			
		If ValueIsFilled(Contract) Then
			ContractDetails_ = Common.ObjectAttributesValues(Contract,
				"ForeignCurrencyTransaction, MarkedProductOutflowOption");
			MarkedProductOutflowOption = ContractDetails_.MarkedProductOutflowOption;
			If ForeignCurrencyTransaction <> ContractDetails_.ForeignCurrencyTransaction Then
				ForeignCurrencyTransaction = ContractDetails_.ForeignCurrencyTransaction;
				CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
		
		If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
		EndIf;
		
	Else
		
		If ForeignCurrencyTransaction <> SalesTermsAndConditions.ForeignCurrencyTransaction Then
			ForeignCurrencyTransaction = SalesTermsAndConditions.ForeignCurrencyTransaction;
			CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount =
		CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount, CompanyBankAccount);
	
	ToReturnReusablePackage = SalesTermsAndConditions.ReturnReusablePackage;
	ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
		ThisObject,
		SalesTermsAndConditions.ReusablePackageReturnCycleLength,
		SalesTermsAndConditions.CalculatePackageReturnDateAccordingToCalendar,
		SalesTermsAndConditions.ScheduleOfPackageReturn);
	PackageDepositIsRequired = SalesTermsAndConditions.PackageDepositIsRequired;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
		StructureOfResponsible = SalesServer.GetWarehouseManager(Warehouse);
		If StructureOfResponsible <> Undefined Then
			IssuiedBy = StructureOfResponsible.EmployeeResponsible;
			IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.FinancialAccountingGroup) Then
		FinancialAccountingGroup = SalesTermsAndConditions.FinancialAccountingGroup;
	EndIf;
	
	DiscountsMarkups.Clear();
	
EndProcedure

// Fills in the default sales terms in the customer's order
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner) Or Not ToUseTermsOfSales Then
		
		ConsignmentSales25 = ?(BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
									Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent, True, False);
		
		FilterParameters = New Structure();
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("SelectedAgreement", Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.CustomerInvoice.EmptyRef());
		FilterParameters.Insert("ConsignmentSales25", ConsignmentSales25);
		FilterParameters.Insert("BusinessTransactions", TMCommonUse.PermissibleBusinessOperationsOfDocument("CustomerInvoice"));
		
		DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(Partner,FilterParameters);
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales Or 
				(Terms <> DefaultSalesTerms.Terms And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				
				If Not OrderSales
					Or BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
					
					FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(ThisObject);
					VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				EndIf;
				
				If ToUseTermsOfSales Then
					RecalculateAmountTakingIntoAccountManualDiscount = New Structure("Clear", False);
					StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
					
					StructureOfActions = New Structure;
					StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
					StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
					StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
					StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
					StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
					StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
					StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);
					
					FillParameters = EnterprisePricesFillingServer.NewFillOptionsFillPrices();
					FillParameters.Insert("Date", Date);
					FillParameters.Insert("Organization", Organization);
					FillParameters.Insert("Currency", Currency);
					FillParameters.Insert("Terms", Terms);
					FillParameters.Insert("VATTaxation", VATTaxation);
					FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
					FillParameters.Insert("CalculateSets", True);
					FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind, DeliveryPeriodDays");
					
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
			TheCounterpartyPriorToTheChange = Counterparty;
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			If TheCounterpartyPriorToTheChange <> Counterparty Then
				CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
			EndIf;
			Terms = Undefined;
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			CounterpartyBankAccount);
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
EndProcedure

// Fills in the terms of sales under the agreement in the sale of goods and services
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	If Not OrderSales
		Or BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	RecalculateAmountTakingIntoAccountManualDiscount = New Structure("Clear", False);
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisObject);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject));
	StructureOfActions.Insert("RecalculateAmount", "NumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount", "NumberOfPackages");
	StructureOfActions.Insert("ClearAutomaticDiscount", Undefined);
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", RecalculateAmountTakingIntoAccountManualDiscount);
	
	FillParameters = New Structure();
	FillParameters.Insert("Date", Date);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Terms", Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("ReturnReusablePackage", ToReturnReusablePackage);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, VATRate, PriceKind, DeliveryPeriodDays");
	
	EnterprisePricesFillingServer.FillInPrices(
		Goods, // Table part
		, // Array of rows or selection structure
		FillParameters,
		StructureOfActions);
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
EndProcedure

// Initializes parameters for filling in inventory types for additional document properties that are used when writing a document
// in the 'Hold' or 'Cancel hold' mode.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoice - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	FillParameters = ParametersForFillingInventoryTypes(True);
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", FillParameters);
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.CustomerInvoice.CollectionOfTabularPartsOfGoods.
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
	
	ThereAreAdjustingEntries = False;
	SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
	If WriteMode = DocumentWriteMode.UndoPosting And ThereAreAdjustingEntries Then
		SalesServer.ReportErrorsCancellationsAndAdjustments(Ref,Cancel);
	EndIf;

	If WriteMode = DocumentWriteMode.Posting 
		And BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent")
		And Not ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation)
		And GetFunctionalOption("UseDiscountsMarkupsInSales")
		And Not DiscountsAreCalculated Then
		
		Cancel = True;
		
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trong chứng từ %1, chiết khấu tự động (tỷ suất lợi nhuận) không được tính. Không thể kết chuyển. Để tính chiết khấu tự động (tỷ suất lợi nhuận), hãy kết chuyển chứng từ từ mẫu.';
							|ru = 'В документе %1 не рассчитаны автоматические скидки (наценки). Проведение невозможно. Для расчёта автоматических скидок (наценок) проведите документ из формы документа.';
							|en = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.'; fa = 'Discounts/markups are not calculated in the %1document. Posting is impossible. To calculate discounts/markups, post the document from the document form.';
							|it = 'Nel documento %1 gli sconti (sovraprezzi) automatici non sono calcolati. Impossibile registrare. Per calcolare automaticamente gli sconti (sovraprezzi) registrate il documento dal modulo del documento.';
							|pl = 'W dokumencie %1 nie obliczono automatycznych rabatów (marży). Zatwierdzenie jest niemożliwe. Aby obliczyć automatyczne rabaty (marże) zatwierdź dokument z formularza dokumentu.';
							|tr = 'Otomatik indirimler (marj) %1 belgesinde hesaplanmamıştır. Gerçekleştirilemez. Otomatik indirimleri (marj) hesaplamak için, belgeyi belge formundan çalıştırın.'"),
						Ref);
		
		Common.MessageToUser(ErrorText, Ref, , , Cancel);
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		For Each String In Goods Do
			If Not ValueIsFilled(String.VATRate) Then
				String.VATRate = Catalogs.VATRates.EXCLUDINGVAT;
			EndIf;
		EndDo;
	EndIf;
	
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode);
	
	DeliveryBeforeWrite(Cancel, WriteMode);
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.CustomerInvoice.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	If (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or Not ToReturnReusablePackage)
		And PackageDepositIsRequired Then
		PackageDepositIsRequired = False;
	EndIf;
	
	DocumentAmount = GetDocumentAmount();
	
	ProductsServer.ClearUnusedSeries(
		ThisObject,
		ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice));
	
	RegistrationParameters = Documents.CustomerInvoice.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	TMCommonUse.ChangeDocumentConsistencyAttribute(
	ThisObject,
		WriteMode);
	
	If OrderSales And ValueIsFilled(SalesOrder) Then
		
		For Each CurRow In Goods Do
			
			If Not ValueIsFilled(CurRow.SalesOrder) Then
				CurRow.SalesOrder = SalesOrder;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		If BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
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
			
		ElsIf BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			
			FillInVATAmountsLocalMans();
			
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
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		InformationRegisters.SetAccountingDimension.FillInCollection(Goods);
		
	EndIf;
	
	PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
		Status = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
	If Not BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		And Not BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		DateOfTransferOfTitleToGoods = Date('00010101');
	Else
		If Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		
			DateOfTransferOfTitleToGoods = Date('00010101');
		EndIf;
	EndIf;
	
	If ThisObject.AdditionalProperties.Property("FilledInVersionOfSale") Then
		SaleRegistrationOption = ThisObject.AdditionalProperties.FilledInVersionOfSale;
	EndIf; 
	
	SetPropertiesForChangingBankingDetails(ThisObject, AdditionalProperties);
	
	CustomerInvoiceLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If Not ValueIsFilled(Author) And IsNew() Then
		Author = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	Var OriginWarehouse;
	Var HeaderAttributes;
	Var RegistrationOption;
	Var DesignParameters;
	
	FillInDataType = TypeOf(FillingData);
	FilledInBasedOnDocument = False;
	ReFillVATRate = False;
	
	If FillInDataType = Type("Structure") Then
		
		// Filling out the list of orders from the form.
		If FillingData.Property("DocumentBasis")
			And (TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.SalesOrder") 
			Or TypeOf(FillingData.DocumentBasis) = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer")
			Or TypeOf(FillingData.DocumentBasis) = Type("Array")) Then
			
			EconomicOperationOfRealization = Enums.BusinessTransactions.EmptyRef();
			
			// If a warehouse has been transferred, it is necessary to fill in the goods only for the specified warehouse.
			FillingData.Property("OriginWarehouse", OriginWarehouse);
			FillingData.Property("HeaderAttributes", HeaderAttributes);
			FillingData.Property("SaleRegistrationOption", RegistrationOption);
			FillingData.Property("DesignParameters", DesignParameters);
			FillingData.Property("DesignParameters", DesignParameters);
			FillingData.Property("BusinessOperation", EconomicOperationOfRealization);
			
			FillInDocumentBasedOnCustomerSOrder(FillingData.DocumentBasis,
				OriginWarehouse,
				RegistrationOption,
				HeaderAttributes,
				DesignParameters,
				EconomicOperationOfRealization);
			
			FilledInBasedOnDocument = False;
			
		ElsIf FillingData.Property("DiscrepancyCertificate") 
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.CustomerInvoice") Then
				FillInDocumentOnBasisOfActOfDiscrepanciesAfterShipment(FillingData);
				FilledInBasedOnDocument = True;
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
				FillInDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(FillingData);
				FilledInBasedOnDocument = True;
			EndIf;
			
		ElsIf FillingData.Property("BusinessOperation")
			And FillingData.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent Then
			
			FillInDataOnGoodsTransferredToCommission(FillingData);
			If ValueIsFilled(Contract) Then
				FilledInBasedOnDocument = True;
			Else
				FillInDefaultSalesConditions();
			EndIf;
			
		Else

			FillInSelectionDocument(FillingData);

		EndIf;

	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then

		FillInDocumentOnBasisOfSaleTransaction(FillingData);

	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Or
		FillInDataType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		FillInDocumentBasedOnCustomerSOrder(FillingData, OriginWarehouse, RegistrationOption);
		FilledInBasedOnDocument = True;
		
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then

		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);

	ElsIf FillInDataType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then

		FillInDocumentBasedOnReturnOfGoodsFromClient(FillingData);
		FilledInBasedOnDocument = True;
		
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then

		FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData);
		FilledInBasedOnDocument = True;
		ReFillVATRate = Not FillingData.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement;
	EndIf;
	
	If Not FilledInBasedOnDocument Then
		InitializeSalesConditions();
	EndIf;
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	FillOutBankAccounts();

	Author = Users.CurrentUser();
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	ResponsiblePersonsServer.InstallManager(
		ThisObject, SalesServer.DocumentBasis(ThisObject, "OrderSales, SalesOrder, Goods.SalesOrder"));
	
	// Filling in subordinate Attributes according to statistics, after filling in the key Attribute "Manager"
	ObjectsFillingByStatistics.FillInSubordinateDetailsOfObject(ThisObject, "Manager",, True);
	
	CustomerInvoiceLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
	If ConsignmentSalesServer.SalesViaCommissionAgent(BusinessOperation) Then
		Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	InitializeDocument(FillingData, ReFillVATRate);
	
	ThereAreAdjustingEntries = False;
	SalesServer.CheckForAdjustments(Ref, Ref, ThereAreAdjustingEntries);
	
	ARAPAccountingServer.Filling(ThisObject, FillingData);

	If OrderSales And (ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice
			Or ARAPObjectSettings = Enums.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)
		Or (Not OrderSales And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts) Then
		
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
												ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice),
												Cancel,
												NotCheckedAttributeArray);
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	
	Documents.CustomerInvoice.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	
	For Each ArrayElement In ArrayOfAllProps Do
		
		// If the account details are not used for a business transaction, we exclude this account from verification.
		If ArrayOfOperationDetails.Find(ArrayElement) = Undefined Then
			NotCheckedAttributeArray.Add(ArrayElement);
		EndIf;
		
	EndDo;
	
	If Goods.FindRows(New Structure("AmountARAP", 0)).Count()=0 Then
		AdditionalProperties.Insert("AmountInARAPCurrency", GetAmountOfSettlementsForTS());
		AdditionalProperties.Insert("AmountOfCollateralInCurrencyOfMutualSettlements", GetAmountOfSettlementsByContainer());
	Else
		ParametersStructure = New Structure("Date, Currency, ARAPCurrency, AmountARAP, Organization");
		FillPropertyValues(ParametersStructure, ThisObject);
		ParametersStructure.Insert("DocumentAmount", ThisObject.Goods.Total("AmountIncludingVAT"));
		ARAPAccountingServer.FillInAmountOfSettlements(ParametersStructure);
		AdditionalProperties.Insert("AmountInARAPCurrency", Round(ParametersStructure.AmountARAP, 2));
		ParametersStructure.Insert("DocumentAmount", GetDocumentAmountByContainer());
		ARAPAccountingServer.FillInAmountOfSettlements(ParametersStructure);
		AdditionalProperties.Insert("AmountOfCollateralInCurrencyOfMutualSettlements", Round(ParametersStructure.AmountARAP, 2));
	EndIf;
	
	If Not OrderSales
		And BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then

		ErrorText = NStr("vi = 'Chỉ được phép chuyển giao quyền sở hữu theo lệnh.';
						|ru = 'Переход права собственности должен формироваться только по распоряжению.';
						|en = 'Transfer of title to goods must be generated only based on the reference.'; fa = 'Transfer of title to goods must be generated only based on the reference.';
						|it = 'Transfer of title to goods must be generated only based on the reference.';
						|pl = 'Transfer of title to goods must be generated only based on the reference.';
						|tr = 'Mülkiyet hakkının devri yalnızca tasarruf ile gerçekleşecektir.'");

		Common.MessageToUser(
			ErrorText,,
			"Object.OrderSales",,
			Cancel);

	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
	
		QueryText = "
		|SELECT
		|	GoodsTable.Products AS Products
		|INTO Goods
		|FROM
		|	&GoodsTable AS GoodsTable
		|;
		|
		|////////////////////////////////////////////////
		|SELECT DISTINCT
		|	Goods.Products AS Products,
		|	Goods.Products.ItemsType AS ItemsType,
		|	PRESENTATION(Goods.Products.ItemsType) AS PresentationOfItemType
		|FROM
		|	Goods AS Goods
		|WHERE
		|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.OwnGoods)
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("GoodsTable", Goods.Unload(, "Products"));
		ErroneousItemTypes = Query.Execute().Unload();
		
	EndIf;
	
	For CurIndex__ = 0 To Goods.Count()-1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		If OrderSales
			And Not ValueIsFilled(SalesOrder)
			And Not ValueIsFilled(LineProducts_.SalesOrder) Then
			
			If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
				ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
								|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
								|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
								|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
			Else
				ErrorText = NStr("vi = 'Chưa điền trường ""Đơn hàng của khách"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
								|ru = 'Не заполнено поле ""Заказ клиента"" в строке %LineNumber% списка ""Товары""';
								|en = 'Sales order in line %LineNumber% of the Item list is not filled in'; fa = 'Sales order in line %LineNumber% of the Item list is not filled in';
								|it = 'Il campo ""Ordine del cliente"" nella riga %LineNumber% dell''elenco ""Merci"" non è compilato';
								|pl = 'Nie jest wypełnione pole ""Заказ клиента"" w wierszu %LineNumber% listy ""Товары""';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Müşteri siparişi"" alanı doldurulmamış'");
			EndIf;
			
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "SalesOrder"),
				,
				Cancel);
			
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			
			FoundRow = ErroneousItemTypes.Find(LineProducts_.Products);
			
			If FoundRow <> Undefined Then
				
				ErrorText = NStr("vi = 'Trong dòng %LineNumber% danh sách ""Hàng hóa"" đã chỉ định mặt hàng có kiểu ""%PresentationOfItemType%"", chỉ có thể thực hiện chuyển giao quyền sở hữu theo mặt hàng. ';
								|ru = 'В строке %LineNumber% списка ""Товары"" указана номенклатура с типом ""%PresentationOfItemType%"", Переход права собственности может делаться только по товарам.';
								|en = 'In line %LineNumber% of the ""Goods"" list, the item with the ""%PresentationOfItemType%"" type is specified. You can make transfer of title to goods only for goods.'; fa = 'In line %LineNumber% of the ""Goods"" list, the item with the ""%PresentationOfItemType%"" type is specified. You can make transfer of title to goods only for goods.';
								|it = 'In line %LineNumber% of the ""Goods"" list, the item with the ""%PresentationOfItemType%"" type is specified. You can make transfer of title to goods only for goods.';
								|pl = 'In line %LineNumber% of the ""Goods"" list, the item with the ""%PresentationOfItemType%"" type is specified. You can make transfer of title to goods only for goods.';
								|tr = '""Ürünler"" listesinin %LineNumber% satırında, ""%PresentationOfItemType%"" türünde bir öğe belirtilmiş. Mülkiyet hakkı devri, sadece ürünler için yapılabilir.'");
				ErrorText = StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
				ErrorText = StrReplace(ErrorText,
					"%PresentationOfItemType%",
					FoundRow.PresentationOfItemType);
				
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					CommonClientServer.PathToTabularSection("Goods", LineProducts_.LineNumber, "Products"),
					,
					Cancel);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ThereAreLinesBeyondOrder = UserRightsCached.SalesInExcessOfOrder()
							And (Goods.FindRows(New Structure("RowCode", 0)).Count() > 0);
	
	// The line code must be filled in if the implementation is on order
	If Not OrderSales
		Or (OrderSales
			And ThereAreLinesBeyondOrder) Then
		
		NotCheckedAttributeArray.Add("Goods.RowCode");
		
	EndIf;
	
	SetPrivilegedMode(True);
	If (Not ValueIsFilled(Terms)
		Or Not TMCommonUse.ValueOfBooleanObjectSProps(Terms, "ContractsAreUsed") 
		And ARAPObjectSettings <> Enums.ARAPObjectSettings.ByCounterpartyContracts) 
		And BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		NotCheckedAttributeArray.Add("Contract");
		
	EndIf;
	SetPrivilegedMode(False);
	
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
	
	If Not ToReturnReusablePackage Then
		NotCheckedAttributeArray.Add("ReusablePackagesReturnDate");
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	If Not BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		And Not BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
		NotCheckedAttributeArray.Add("DateOfTransferOfTitleToGoods");
	Else
		If Status <> Enums.StatusesOfCustomerInvoices.Shipped Then
			NotCheckedAttributeArray.Add("DateOfTransferOfTitleToGoods");
		EndIf;
	EndIf;
	
	CheckSalesOption(NotCheckedAttributeArray);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	CheckChangesInBusinessOperations(Cancel);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject,Cancel);
	TMCommonUse.CheckCorrectnessOfIndicationOfBusinessOperation(ThisObject, Cancel);
	
	If Not OrderSales
		And Not UserRightsCached.CreateCustomerInvoicesWithoutReferenceToOrder() Then
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			ErrorText = NStr("vi = 'Không đủ quyền tạo chứng từ bán hàng và cung cấp dịch vụ mà không có lệnh';
							|ru = 'Нет прав на создание реализации товаров и услуг без распоряжения';
							|en = 'Insufficient rights to create a customer invoice without a reference'; fa = 'Insufficient rights to create a customer invoice without a reference';
							|it = 'Insufficient rights to create a customer invoice without a reference';
							|pl = 'Insufficient rights to create a customer invoice without a reference';
							|tr = 'Ürünlerin ve hizmetlerin sipariş olmadan gerçekleştirilmeleri için izniniz yok'");
		Else
			ErrorText = NStr("vi = 'Không đủ quyền tạo chứng từ bán hàng và cung cấp dịch vụ mà không có đơn hàng';
							|ru = 'Нет прав на создание реализации товаров и услуг без заказа';
							|en = 'No rights to create customer invoice without order'; fa = 'No rights to create customer invoice without order';
							|it = 'Diritti insufficienti per la creazione della vendita delle merci e servizi senza ordine';
							|pl = 'Brak uprawnień do tworzenia sprzedaży towarów i usług bez zamówienia';
							|tr = 'Sipariş olmadan mal ve hizmet satışı oluşturma hakkı yok'");
		EndIf;
		
		Common.MessageToUser(
			ErrorText,
			Ref,
			,
			,
			Cancel);
		
	EndIf;
	
	If ValueIsFilled("ReusablePackagesReturnDate")
		And ToReturnReusablePackage
		And ReusablePackagesReturnDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày trả lại bao bì luân chuyển không thể nhỏ hơn ngày chứng từ.';
						|ru = 'Дата возврата многооборотной тары не должна быть меньше даты документа.';
						|en = 'Reusable packaging units return date must be later than the document date.'; fa = 'Reusable packaging units return date must be later than the document date.';
						|it = 'La data di reso dell''imballaggio riutilizzabile non deve essere precedente alla data del documento.';
						|pl = 'Data zwrotu tary wielokrotnego użytku nie może być mniejsza, niż data dokumentu.';
						|tr = 'Yeniden kullanılabilir ambalajların iade tarihi, belgenin tarihinden daha önce olmamalıdır.'");
		
		Common.MessageToUser(
			ErrorText,
			,
			"Object.ReusablePackagesReturnDate",
			,
			Cancel);
		
	EndIf;
	
	If Not (BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And DateOfTransferOfTitleToGoods <> Date('00010101')
		And DateOfTransferOfTitleToGoods < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày chuyển giao quyền sở hữu phải lớn hơn ngày chứng từ.';
						|ru = 'Дата перехода права собственности должна быть больше даты документа.';
						|en = 'Date of transfer of title to goods must be greater than the document date.'; fa = 'Date of transfer of title to goods must be greater than the document date.';
						|it = 'Data di passaggio di proprietà deve essere successiva alla data del documento.';
						|pl = 'Data przeniesienia własności musi być większa niż data dokumentu.';
						|tr = 'Mülkiyetin devredildiği tarih, belgenin tarihinden sonra olmalıdır.'");
		
		Common.MessageToUser(
			ErrorText,
			,
			"Object.DateOfTransferOfTitleToGoods",
			,
			Cancel);
		
	EndIf;
	
	If Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		SalesServer.CheckShipmentBan(Partner, Cancel);
	EndIf;
	
	VATAccountingLocalization.CheckServicesAtCommitteeSVATRate(ThisObject, Cancel);
	
	CustomerInvoiceLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	// In case the implementation used to make movements on the goods of organizations, but now it does not.
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	If AdditionalProperties.Property("OnlyStateOfTransferOfOwnershipHasChanged")
		And AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		SkipCheckingProhibitionOfChangingRegisters(RegisterRecords);
	EndIf;
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	If Not AdditionalProperties.OnlyStateOfTransferOfOwnershipHasChanged Then
		RegistrationParameters = Documents.CustomerInvoice.ParametersForRegisteringInvoicesIssued(ThisObject);
		VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	EndIf;
	
	CustomerInvoiceLocalization.Posting(ThisObject, Cancel, PostingMode);
	If Not Cancel Then
		ExcisableGoodsAccounting.CreateTaskToRecordAmountOfExciseTax(ThisObject);
	EndIf;
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	RegistrationParameters = Documents.CustomerInvoice.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	CustomerInvoiceLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Approved          = False;
	SalesOrder        = Undefined;
	Status              = Metadata.Documents.CustomerInvoice.Attributes.Status.FillValue;
	DiscountsAreCalculated    = False;
	OrderSales = False;
	InventoryOwnerAttributesAreSpecifiedManually = False;
	MaximumDeliveryLineCode  = 0;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	DateOfTransferOfTitleToGoods = Date(1,1,1);
	SupportingDocuments = "";
	InformationOnTransportationAndCargo = "";
	
	AgreementIsFilled = GetFunctionalOption("ToUseTermsOfSales") And ValueIsFilled(Terms);
	If AgreementIsFilled Then
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
		If SalesTermsAndConditions.AgreementStatus <> Enums.StatusesOfTermsOfSales.Closed Then
			ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
				ThisObject,
				SalesTermsAndConditions.ReusablePackageReturnCycleLength,
				SalesTermsAndConditions.CalculatePackageReturnDateAccordingToCalendar,
				SalesTermsAndConditions.ScheduleOfPackageReturn); 
		Else
			Terms = Undefined;
			ReusablePackagesReturnDate = Date(1,1,1);
		EndIf;
	Else
		ReusablePackagesReturnDate = Date(1,1,1);
	EndIf;
	
	For Each CurRow In Goods Do
		
		CurRow.SalesOrder = Undefined;
		CurRow.RowCode = 0;
		CurRow.RowID = "";
		CurRow.DeliveryLineCode = 0;
		
	EndDo;
	DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	InvoicesServer.FillInAssignmentsInTablePart(Goods, DefaultAssignment);
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	DiscountsMarkupsFillingServer.CancelDiscounts(ThisObject, "Goods", True, True);

	For Each TSRow In Goods Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;
	
	InitializeDocument();
	
	ARAPAccountingServer.OnCopy(ThisObject);
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	StructureBase = Documents.CustomerInvoice.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
	CustomerInvoiceLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	CustomerInvoiceLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnSetNewNumber(StandardProcessing, Prefix)
	
	Prefix = TMCommonUseCached.AdditionalPrefixOfNumeratorDocumentsOfSaleOfGoods();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnCustomerSOrder(Val DocumentBasis,
	Val OriginWarehouse,
	RegistrationOption,
	OrderDetails = Undefined,
	DesignParameters = Undefined,
	EconomicOperationOfRealization = Undefined)
	
	BasisType = TypeOf(DocumentBasis);
	FillInByLeftovers = False;
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	EnterOnBasisOfUnverified = False;
	If Not DesignParameters = Undefined And TypeOf(DesignParameters) = Type("Structure") Then
		DesignParameters.Property("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
		EnterOnBasisOfUnverified = ?(EnterOnBasisOfUnverified = Undefined, False, EnterOnBasisOfUnverified)
	EndIf;
	
	If BasisType = Type("DocumentRef.SalesOrder") Then
		
		Query = New Query;
		Query.Text = Documents.CustomerInvoice.QueryTextForFillingInBasedOnOrder();
		
		Query.SetParameter("SalesOrder", DocumentBasis);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
		
		Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
		Query.SetParameter("UsedDelivery", GoodsDeliveryClientServer.UsedDelivery());
		Query.SetParameter("UsedDelivery20", GoodsDeliveryClientServer.UsedDelivery20());
		Query.SetParameter("UsedDelivery25", GoodsDeliveryClientServer.UsedDelivery25());
		Query.SetParameter("EnterOnBasisOfUnverified", EnterOnBasisOfUnverified);
		
		QueryResult = Query.ExecuteBatch();
		
		OrderDetails = QueryResult[0].Select();
		OrderDetails.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(DocumentBasis,
			"CustomerInvoice",
			OrderDetails.BusinessOperation,
			RegistrationOption);
		
		Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted);
		
		// Filling in the header
		FillPropertyValues(ThisObject, OrderDetails);
		
		If ValueIsFilled(EconomicOperationOfRealization) Then
			BusinessOperation = EconomicOperationOfRealization;
		EndIf;
		
		If OrderDetails.ThisIsOrderAsInvoice Then
			
			If Not ValueIsFilled(Date) Then
				Date = CurrentSessionDate();
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
		
	ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	ReturnRequest.Ref                AS SalesOrder,
		|	ReturnRequest.Partner               AS Partner,
		|	ReturnRequest.Counterparty            AS Counterparty,
		|	ReturnRequest.ContactPerson        AS ContactPerson,
		|	ReturnRequest.Contract               AS Contract,
		|	ReturnRequest.Organization           AS Organization,
		|	ReturnRequest.PaymentMethod           AS PaymentMethod,
		|	ReturnRequest.Terms            AS Terms,
		|	ReturnRequest.SalesOpportunity                AS SalesOpportunity,
		|	ReturnRequest.Currency                AS Currency,
		|	ReturnRequest.Currency                AS ARAPCurrency,
		|	ReturnRequest.PaymentSchedule          AS PaymentSchedule,
		|	ReturnRequest.DateOfShipment          AS DateOfShipment,
		|	ReturnRequest.ThisIsOrderAsInvoice       AS ThisIsOrderAsInvoice,
		|	CASE
		|		WHEN ReturnRequest.Warehouse.IsFolder
		|			AND ReturnRequest.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE ReturnRequest.Warehouse
		|	END AS Warehouse,
		|	CASE WHEN ReturnRequest.Warehouse.IsFolder
		|		AND ReturnRequest.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|		THEN TRUE
		|		ELSE FALSE
		|	END AS ItIsForbiddenToSelectWarehouseGroup,
		|	ReturnRequest.PriceIncludesVAT       AS PriceIncludesVAT,
		|	ReturnRequest.VATTaxation    AS VATTaxation,
		|	CASE
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
		|				OR ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
		|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|		WHEN ReturnRequest.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
		|			THEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|		ELSE
		|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|	END AS BusinessOperation,
		|	ReturnRequest.NotShipInInstallments    AS NotShipInInstallments,
		|	ReturnRequest.DeliveryAddress         AS DeliveryAddress,
		|	ReturnRequest.Warehouse.UseWarehouseManagemantSystemForGoodsIssue AS AdvancedWarehousingOnShipment,
		|	ReturnRequest.ToReturnReusablePackage      AS ToReturnReusablePackage,
		|	ReturnRequest.ReusablePackageReturnCycleLength AS ReusablePackageReturnCycleLength,
		|	ReturnRequest.PackageDepositIsRequired           AS PackageDepositIsRequired,
		|	CASE
		|		WHEN &ToUseTermsOfSales 
		|			THEN ReturnRequest.Terms.ScheduleOfPackageReturn
		|		ELSE VALUE(Catalog.BusinessCalendars.EmptyRef)
		|	END AS ScheduleOfPackageReturn,
		|	CASE
		|		WHEN &ToUseTermsOfSales 
		|			THEN ReturnRequest.Terms.CalculatePackageReturnDateAccordingToCalendar
		|		ELSE FALSE
		|	END AS CalculatePackageReturnDateAccordingToCalendar,
		|	ReturnRequest.Status               AS DocumentStatus,
		|	NOT ReturnRequest.Posted          AS ThereAreErrorsPosted,
		|
		|	ReturnRequest.BankAccount                 AS CompanyBankAccount,
		|	ReturnRequest.CounterpartyBankAccount      AS CounterpartyBankAccount,
		|	ReturnRequest.Shipper               AS Shipper,
		|	ReturnRequest.GoodsRecipient                AS GoodsRecipient,
		|	ReturnRequest.ShipperBankAccount AS ShipperBankAccount,
		|	ReturnRequest.GoodsRecipientBankAccount  AS GoodsRecipientBankAccount,
		|
		|	ReturnRequest.DiscountsMarkups.(
		|		ConnectionKey,
		|		DiscountMarkup,
		|		Sum
		|	) AS DiscountsMarkups,
		|	ReturnRequest.DeliveryAddressFieldValues     AS DeliveryAddressFieldValues,
		|	CASE WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
		|		AND ReturnRequest.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) THEN
		|		ReturnRequest.DeliveryMethod
		|	END                                          AS DeliveryMethod,
		|
		|	CASE WHEN ReturnRequest.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) THEN
		|		ReturnRequest.CarrierPartner
		|	END                                          AS CarrierPartner,
		|
		|	CASE WHEN NOT &UseTransportationJobsForDeliveryAccountingByCarriers
		|		AND ReturnRequest.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) THEN
		|		ReturnRequest.AdditionalDeliveryInformation
		|	END                                          AS AdditionalDeliveryInformation,
		|
		|	ReturnRequest.ARAPObjectSettings                AS ARAPObjectSettings,
		|	ReturnRequest.LineOfBusiness        AS LineOfBusiness
		|
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS ReturnRequest
		|WHERE
		|	ReturnRequest.Ref = &DocumentBasis
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	ShippingOrdersShipped.Warehouse AS Warehouse
		|FROM
		|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersShipped
		|	LEFT JOIN Catalog.Warehouses AS Warehouses
		|		ON ShippingOrdersShipped.Warehouse = Warehouses.Ref
		|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
		|		ON TRUE
		|WHERE
		|	ShippingOrdersShipped.QuantityToBeShippedTurnover
		|		- ShippingOrdersShipped.ShippedQuantityTurnover > 0
		|	AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsIssue
		|		OR Warehouses.UseWarehouseManagemantSystemForGoodsIssue
		|			AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CheckDate
		|		OR TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst))
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsForIssueBalanceAndTurnovers.Warehouse AS Warehouse
		|FROM
		|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
		|			,
		|			,
		|			,
		|			,
		|			DocumentShipments = &DocumentBasis
		|				AND CAST(Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
		|				AND CAST(Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue < &CheckDate
		|		) AS GoodsForIssueBalanceAndTurnovers
		|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
		|		ON TRUE
		|WHERE
		|	GoodsForIssueBalanceAndTurnovers.ToShipExpense - GoodsForIssueBalanceAndTurnovers.ToRegisterExpense > 0
		|	AND TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst)
		|";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText = "
			|	ReferenceOrder = &DocumentBasis
			|";
		TableFormationParameters.Group = "Warehouse";
		TableFormationParameters.Indicators = "ToShip, Shipped";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		Query.Text = StrReplace(Query.Text,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
		Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
			
		QueryResult = Query.ExecuteBatch();
		
		OrderDetails = QueryResult[0].Select();
		OrderDetails.Next();
		
		TMCommonUse.CheckPossibilityOfEnteringBasedOnOperation(DocumentBasis,
										"CustomerInvoice",
										OrderDetails.BusinessOperation,
										RegistrationOption);
		
		Documents.RequestForReturnOfGoodsFromCustomer.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted);
		
		// Filling in the header.
		FillPropertyValues(ThisObject, OrderDetails);
		If OrderDetails.ThisIsOrderAsInvoice Then
			If Not ValueIsFilled(Date) Then
				Date = CurrentSessionDate();
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
		
		If ValueIsFilled(EconomicOperationOfRealization) Then
			BusinessOperation = EconomicOperationOfRealization;
		EndIf;
		
		Currency = ARAPCurrency;
		CompanyBankAccount = OrderDetails.BankAccount;
		ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
			ThisObject,
			OrderDetails.ReusablePackageReturnCycleLength,
			OrderDetails.CalculatePackageReturnDateAccordingToCalendar,
			OrderDetails.ScheduleOfPackageReturn);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			Query = New Query;
			Query.SetParameter("DocumentsArray", DocumentBasis);
			Query.SetParameter("CheckDate", CurrentSessionDate());
			Query.Text =
			"SELECT DISTINCT
			|	ShippingOrdersShipped.Warehouse AS Warehouse
			|FROM
			|	#ShipmentOrdersTurnoverExpanded AS ShippingOrdersShipped
			|	LEFT JOIN Catalog.Warehouses AS Warehouses
			|		ON ShippingOrdersShipped.Warehouse = Warehouses.Ref
			|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
			|		ON TRUE
			|WHERE
			|	ShippingOrdersShipped.QuantityToBeShippedTurnover
			|		- ShippingOrdersShipped.ShippedQuantityTurnover > 0
			|	AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsIssue
			|		OR Warehouses.UseWarehouseManagemantSystemForGoodsIssue
			|			AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue > &CheckDate
			|		OR TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst))
			|
			|UNION ALL
			|
			|SELECT
			|	GoodsForIssueBalanceAndTurnovers.Warehouse AS Warehouse
			|FROM
			|	AccumulationRegister.GoodsForIssue.BalanceAndTurnovers(
			|			,
			|			,
			|			,
			|			,
			|			DocumentShipments IN (&DocumentsArray)
			|				AND CAST(Warehouse AS Catalog.Warehouses).UseWarehouseManagemantSystemForGoodsIssue
			|				AND CAST(Warehouse AS Catalog.Warehouses).StartDateOfWarehouseManagemantSystemForGoodsIssue < &CheckDate
			|		) AS GoodsForIssueBalanceAndTurnovers
			|	LEFT JOIN Constant.ProcedureOfInvoiceAndGoodsIssueNoteRegistration AS TableOfConstants
			|		ON TRUE
			|WHERE
			|	GoodsForIssueBalanceAndTurnovers.ToShipExpense - GoodsForIssueBalanceAndTurnovers.ToRegisterExpense > 0
			|	AND TableOfConstants.Value = VALUE(Enum.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.OrdersFirst)
			|";
			
			TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
			TableFormationParameters.ConditionText = "
				|	ReferenceOrder IN (&DocumentsArray)
				|";
			TableFormationParameters.Group = "Warehouse";
			TableFormationParameters.Indicators = "ToShip, Shipped";
			TableFormationParameters.Resources = "Count";
			
			ShipmentOrdersTurnoverExpanded =
				AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
					TableFormationParameters);
			
			Query.Text = StrReplace(Query.Text,
				"#ShipmentOrdersTurnoverExpanded",
				ShipmentOrdersTurnoverExpanded);
			
			RequestResultForWarehouses = Query.Execute();
			WarehouseArray = RequestResultForWarehouses.Unload().UnloadColumn("Warehouse");
			Warehouse = OrderDetails.OriginWarehouse;
			
		EndIf;
		
	EndIf;
	
	If EconomicOperationOfRealization = Enums.BusinessTransactions.TransferOfTitleToGoods
		And ToUseTermsOfSales
		And ValueIsFilled(Terms) Then
		
		DetailsOfAgreement = Common.ObjectAttributesValues(Terms,
			"SaleWithDeferredTransferOfTitleIsAllowed, ContractsAreUsed, Presentation");
		
		If Not DetailsOfAgreement.SaleWithDeferredTransferOfTitleIsAllowed Then
			
			ExceptionText = NStr("vi = 'Theo thỏa thuận ""%1"" không thể giao hàng mà chưa chuyển giao quyền sở hữu.';
								|ru = 'По соглашению ""%1"" невозможна отгрузка товаров без перехода права собственности.';
								|en = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.'; fa = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
								|it = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
								|pl = 'Cannot ship goods without transfer of title to goods under the ""%1"" agreement.';
								|tr = '""%1"" anlaşmasına göre ürünler, mülkiyet hakkı devri olmaksızın sevkiyata alınamaz.'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				ExceptionText,
				DetailsOfAgreement.Presentation);
			
			Raise ExceptionText;
			
		EndIf;

		If Not DetailsOfAgreement.ContractsAreUsed Then
			
			ExceptionText = NStr("vi = 'Trong thỏa thuận ""%1"" không sử dụng hợp đồng với đối tác. Việc sử dụng hợp đồng là bắt buộc để giao hàng có chuyển giao quyền sở hữu hoãn lại.';
								|ru = 'В соглашении ""%1"" не используются договоры с контрагентами. Использование договоров является обязательным для реализации товаров с отложенным переходом права собственности.';
								|en = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for selling goods with deferred transfer of title to goods.'; fa = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for selling goods with deferred transfer of title to goods.';
								|it = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for selling goods with deferred transfer of title to goods.';
								|pl = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for selling goods with deferred transfer of title to goods.';
								|tr = '""%1"" anlaşması, cari hesaplarla yapılan sözleşmeleri kullanmamaktadır. Mülkiyet hakkı devri olmadan yapılan ürün satışlarında sözleşme kullanımı zorunludur.'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				ExceptionText,
				DetailsOfAgreement.Presentation);
			
			Raise ExceptionText;
			
		EndIf;
		
	EndIf;
	
	OrderSales = True;
	
	If ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		If ToUseTermsOfSales And ValueIsFilled(Terms) Then
			SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms);
			PaymentMethod   = SalesTermsAndConditions.PaymentMethod;
			
			ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
			ParametersStructure.Organization    			= Organization;
			ParametersStructure.LineOfBusiness	= LineOfBusiness;
			ParametersStructure.PaymentMethod				= PaymentMethod;
			ParametersStructure.Individual			= Courier;

			CashAccount = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
		EndIf;
	EndIf;
	
	// Filling in incl. goods.
	If EconomicOperationOfRealization = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		
		FillInByLeftovers = True;
		Warehouse = Catalogs.Warehouses.EmptyRef();
		OriginWarehouse = Catalogs.Warehouses.EmptyRef();
		
	ElsIf Not ValueIsFilled(OriginWarehouse) Then
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			// Only service
			If WarehouseArray.Count() = 0 Then
				FillInByLeftovers = True;
			// Services or goods
			ElsIf WarehouseArray.Count() >= 1 Then
				OriginWarehouse = WarehouseArray[0];
				Warehouse = OriginWarehouse;
				FillInByLeftovers = True;
			EndIf;
		Else
			FillInByLeftovers = True;
			OriginWarehouse = Warehouse;
		EndIf;
	Else
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			Warehouse = OriginWarehouse;
		EndIf;
		FillInByLeftovers = True;
	EndIf;
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
	If EnterOnBasisOfUnverified Then
		FillInByLeftovers = False;
	EndIf;
	
	If FillInByLeftovers Then
		
		If BasisType = Type("Array") Then
			AnArrayOfOrders = DocumentBasis;
		Else
			AnArrayOfOrders = New Array();
			AnArrayOfOrders.Add(SalesOrder);
		EndIf;
		
		SaleRegistrationOption = ?(ValueIsFilled(RegistrationOption), 
			RegistrationOption,
			Enums.SalesRegistrationOptions.CustomerInvoice);
			
		FillParameters = New Structure;
		FillParameters.Insert("RegistrationOption", SaleRegistrationOption);
		FillParameters.Insert("DesignParameters", DesignParameters);
		FillParameters.Insert("UseAdvancedFeaturesOfSalesOrder", Not OrderDetails.ThisIsOrderAsInvoice);
		
		If DesignParameters <> Undefined 
			 And DesignParameters.Property("CheckWarehouses") Then
			FillParameters.Insert("CheckWarehouses", DesignParameters.CheckWarehouses);
		EndIf;
		
		Documents.CustomerInvoice.FillByOrderBalances(
			ThisObject,
			Goods,
			DiscountsMarkups,
			BonusPointAccrual,
			?(OriginWarehouse=Undefined, Catalogs.Warehouses.EmptyRef(), OriginWarehouse),
			AnArrayOfOrders,
			FillParameters,
			PackageBarcodes);
		Barcodes = PackageBarcodes.Unload();
		Barcodes.GroupBy("PackageBarcode");
		PackageBarcodes.Load(Barcodes);
			
		OrdersServer.FillInOrderInOrderHeaderInTableSection(SalesOrder, Goods, "SalesOrder");
		
		If Not ValueIsFilled(SalesOrder)
			And AnArrayOfOrders.Count() = 1
			And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.SalesOrder") Then
			SalesOrder = AnArrayOfOrders[0];
		EndIf;
		
		DiscountsAreCalculated = True;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice);
		ProductsServer.FillInSeriesByFEFO(ThisObject,SeriesSpecificationParameters, False);
		
	EndIf;
	
	StructureBase = Documents.CustomerInvoice.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
	CustomerInvoiceLocalization.CheckCorrectAvailabilityOfDiscountsPaymentsWithBonusPointsForTobaccoProducts(ThisObject);
	
EndProcedure

Procedure FillInDocumentOnBasisOfSaleTransaction(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	SalesOpportunitiesToCustomer.Ref AS SalesOpportunity,
		|	SalesOpportunitiesToCustomer.Partner AS Partner,
		|	SalesOpportunitiesToCustomer.CustomerTermsOfSales AS Terms,
		|	ISNULL(TermsOfSale.BusinessOperation,
		|		VALUE(Enum.BusinessTransactions.EmptyRef)) AS AgreementOperation,
		|	SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson AS ContactPerson
		|FROM
		|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
		|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS SalesOpportunitiesToCustomerPartnersAndContactPersons
		|		ON (SalesOpportunitiesToCustomerPartnersAndContactPersons.Ref = SalesOpportunitiesToCustomer.Ref)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.Partner = SalesOpportunitiesToCustomer.Partner)
		|			AND (SalesOpportunitiesToCustomerPartnersAndContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef))
		|		
		|		LEFT JOIN Catalog.TermsOfSale AS TermsOfSale
		|		ON SalesOpportunitiesToCustomer.CustomerTermsOfSales = TermsOfSale.Ref
		|WHERE
		|	SalesOpportunitiesToCustomer.Ref = &DocumentBasis");
		
	Query.SetParameter("DocumentBasis",DocumentBasis);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Partner);
	FillPropertyValues(ThisObject, Selection);
	
	If GetFunctionalOption("ToUseTermsOfSales") Then
		
		If ValueIsFilled(Terms) Then
			DocumentOperations = TMCommonUse.PermissibleBusinessOperationsOfDocument("CustomerInvoice");
			
			If DocumentOperations.Find(Selection.AgreementOperation) <> Undefined Then
				FillInTermsOfSalesUnderAgreement();
			EndIf;
		Else
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query(
		"SELECT
		|	CustomerTermsOfSales.Ref                AS Terms,
		|	CustomerTermsOfSales.Partner               AS Partner,
		|	CustomerTermsOfSales.BusinessOperation AS BusinessOperation,
		|	CustomerTermsOfSales.ContactPerson        AS ContactPerson,
		|
		|	CustomerTermsOfSales.Status                AS DocumentStatus,
		|	CASE
		|		WHEN
		|			CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
		|		THEN
		|			FALSE
		|		ELSE
		|			TRUE
		|	END AS ThereAreErrorsStatus,
		|	CustomerTermsOfSales.Standard_ AS ThereAreErrorsTypical
		|
		|FROM
		|	Catalog.TermsOfSale  AS CustomerTermsOfSales
		|WHERE
		|	CustomerTermsOfSales.Ref = &DocumentBasis
		|");
		
	Query.SetParameter("DocumentBasis", DocumentBasis);
		
	QueryResult = Query.ExecuteBatch();
	
	QueryResultsArray = Query.ExecuteBatch();
	QueryResult = QueryResultsArray[0]; // QueryResult
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("CustomerInvoice", Selection.BusinessOperation);
	
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

Procedure FillInDocumentBasedOnReturnOfGoodsFromClient(Val DocumentBasis)

	Query = New Query;
	Query.SetParameter("DocumentBasis",DocumentBasis);
	Query.Text =
	"SELECT
	|	ReturnOfGoodsFromCustomer.Ref               AS Ref,
	|	ReturnOfGoodsFromCustomer.Organization          AS Organization,
	|	ReturnOfGoodsFromCustomer.Partner              AS Partner,
	|	ReturnOfGoodsFromCustomer.Counterparty           AS Counterparty,
	|	ReturnOfGoodsFromCustomer.SalesOpportunity               AS SalesOpportunity,
	|	ReturnOfGoodsFromCustomer.Terms           AS Terms,
	|	ReturnOfGoodsFromCustomer.Currency               AS Currency,
	|	ReturnOfGoodsFromCustomer.Currency               AS ARAPCurrency,
	|	ReturnOfGoodsFromCustomer.DocumentAmount       AS DocumentAmount,
	|	ReturnOfGoodsFromCustomer.DocumentAmount       AS AmountARAP,
	|	ReturnOfGoodsFromCustomer.Warehouse                AS Warehouse,
	|	ReturnOfGoodsFromCustomer.PriceIncludesVAT      AS PriceIncludesVAT,
	|	ReturnOfGoodsFromCustomer.VATTaxation   AS VATTaxation,
	|	ReturnOfGoodsFromCustomer.Contract              AS Contract,
	|	ReturnOfGoodsFromCustomer.ReusablePackageReturn AS ToReturnReusablePackage,
	|	ReturnOfGoodsFromCustomer.DepositForPackageIsRequired AS PackageDepositIsRequired,
	|	ReturnOfGoodsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	ReturnOfGoodsFromCustomer.ForeignCurrencyTransaction        AS ForeignCurrencyTransaction,
	|
	|	CASE WHEN ReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent) THEN
	|		VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	END AS BusinessOperation,
	|
	|	NOT ReturnOfGoodsFromCustomer.Posted AS ThereAreErrorsPosted,
	|
	|	ReturnOfGoodsFromCustomer.Goods.(
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		Package                 AS Package,
	|		Purpose               AS Purpose,
	|		NumberOfPackages       AS NumberOfPackages,
	|		Count               AS Count,
	|		Price                     AS Price,
	|		Sum                    AS Sum,
	|		VATRate                AS VATRate,
	|		VATAmount                 AS VATAmount,
	|		AmountIncludingVAT                AS AmountIncludingVAT,
	|		Warehouse                    AS Warehouse
	|	) AS Goods,
	|
	|	ReturnOfGoodsFromCustomer.SetOfSeries.(
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		Purpose               AS Purpose,
	|		Series                    AS Series,
	|		Count               AS Count,
	|		Warehouse                    AS Warehouse
	|	) AS SetOfSeries
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref = &DocumentBasis";
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
	
	AssignmentToFillIn = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	For Each String In Goods Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	For Each String In SetOfSeries Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);

EndProcedure

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		Partner = FillingData.Partner;
		
		If GetFunctionalOption("ToUseTermsOfSales") Then
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
	If FillingData.Property("SaleRegistrationOption") Then
		SaleRegistrationOption = FillingData.SaleRegistrationOption;
	EndIf;
	
	If FillingData.Property("Goods") Then
		For Each CurRow In FillingData.Goods Do
			FillPropertyValues(Goods.Add(), CurRow);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(VendorInvoice)
	
	Query = New Query;
	Query.SetParameter("DocumentBasis",VendorInvoice);
	Query.Text =
	"SELECT
	|	VendorInvoice.Ref AS Ref,
	|	VendorInvoice.Organization AS Organization,
	|	VendorInvoice.SalesOpportunity AS SalesOpportunity,
	|	VendorInvoice.Warehouse AS Warehouse,
	|	VendorInvoice.Department AS Department,
	|	CASE 
	|		WHEN VendorInvoice.LineOfBusiness.IncomeAccounting 
	|			THEN VendorInvoice.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END  AS LineOfBusiness,
	|
	|	NOT VendorInvoice.Posted AS ThereAreErrorsPosted
	|
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &DocumentBasis
	|
	|////////////////////////////////////////////////
	|;
	|SELECT
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count,
	|	Goods.NumberOfPackages  AS NumberOfPackages,
	|	Goods.Package            AS Package,
	|	Goods.Department       AS Department,
	|	Goods.VATRate           AS VATRate
	|
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products          AS Products,
	|	SetOfSeries.Characteristic        AS Characteristic,
	|	SetOfSeries.Purpose            AS Purpose,
	|	SetOfSeries.Warehouse                 AS Warehouse,
	|	SetOfSeries.Series                 AS Series,
	|	SetOfSeries.Count            AS Count
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SetOfSeries
	|WHERE
	|	SetOfSeries.Ref = &DocumentBasis";
	
	ResultsPackage = Query.ExecuteBatch();
	Header = ResultsPackage[0].Select();
	
	If Not Header.Next() Then

		ErrorText = NStr("vi = 'Chứng từ %Document% không có hàng hóa. Cấm nhập trên cơ sở chứng từ này.';
						|ru = 'Документ %Document% не содержит товаров. Ввод на основании документа запрещен.';
						|en = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.'; fa = 'Document %Document% does not have any goods. Generation from such base documents is not allowed.';
						|it = 'Il documento %Document% non contiene merci. L''immissione in base al documento non è consentita.';
						|pl = 'Dokument %Document% nie zawiera towarów. Wprowadzenie na podstawie dokumentu jest zakazane.';
						|tr = '%Document% belgesi hiçbir mal içermemektedir. Belgeye dayalı giriş yapılmasına izin verilmez.'");
		ErrorText = StrReplace(ErrorText, "%Document%", VendorInvoice);
	
		Raise ErrorText;
		
	EndIf;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		Header.Ref,
		,
		Header.ThereAreErrorsPosted,);
	
	// Filling in the header.
	FillPropertyValues(ThisObject, Header);
	DocumentBasis = VendorInvoice;
	
	// Splitting lines, filling in series with status 10.
	BaseGoods = ResultsPackage[1].Unload(); // ValueTable
	RowIndexes = New Array();
	For Each LineProducts_ In BaseGoods Do
		
		If LineProducts_.BatchesIndicationStatus = 10 Then
			RowIndexes.Insert(0, BaseGoods.IndexOf(LineProducts_));
		EndIf;
		
	EndDo;
	
	BaseSeries = ResultsPackage[2].Unload();
	
	If RowIndexes.Count() > 0 Then
		
		SeriesKey = "Products, Characteristic, Warehouse, Purpose";
		InvoicesServer.MoveSeriesFromTableToRows(BaseGoods, RowIndexes, BaseSeries, SeriesKey);
		
	EndIf;
	
	// Filling in the tabular part of the goods.
	Goods.Load(BaseGoods);
	
	For Each RowSeries In BaseSeries Do
		If RowSeries.Count > 0 Then
			NewRow = SetOfSeries.Add();
			FillPropertyValues(NewRow, RowSeries);
		EndIf;
	EndDo;
	
	UseOfWarehouses = New Structure("PurchasesWarehousesAreUsed, SalesWarehousesAreUsed",
						GetFunctionalOption("UseWarehousesInTabularSectionsOfPurchaseDocuments"),
						GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"));

	If UseOfWarehouses.PurchasesWarehousesAreUsed And Not UseOfWarehouses.SalesWarehousesAreUsed Then

		WarehouseArray = TMCommonUse.DeleteDuplicateElementsFromArray(Goods.UnloadColumn("Warehouse"));
		
		If WarehouseArray.Count() = 1 Then
			Warehouse = WarehouseArray[0];
		Else
			Warehouse = Catalogs.Warehouses.EmptyRef();
		EndIf;

	EndIf;
	
	AssignmentToFillIn = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	For Each String In Goods Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	For Each String In SetOfSeries Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;

	// Filling in the series indication statuses
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.CustomerInvoice);
	ProductsServer.FillInStatusesForSpecifyingSeries(ThisObject, SeriesSpecificationParameters);

EndProcedure

Procedure FillInDocumentOnBasisOfActOfDiscrepanciesAfterShipment(Val FillingData)
	
	SetPrivilegedMode(True);
	
	QueryText = 
	"SELECT
	|	SaleOfGoodsAndServices.DeliveryAddress,
	|	SaleOfGoodsAndServices.CompanyBankAccount,
	|	SaleOfGoodsAndServices.CounterpartyBankAccount,
	|	SaleOfGoodsAndServices.ShipperBankAccount,
	|	SaleOfGoodsAndServices.GoodsRecipientBankAccount,
	|	SaleOfGoodsAndServices.Currency,
	|	SaleOfGoodsAndServices.ARAPCurrency,
	|	SaleOfGoodsAndServices.Shipper,
	|	SaleOfGoodsAndServices.GoodsRecipient,
	|	SaleOfGoodsAndServices.Date AS ReferenceDate,
	|	SaleOfGoodsAndServices.LetterOfAuthorityIssuedBy,
	|	SaleOfGoodsAndServices.PowerOfAttorneyDate,
	|	SaleOfGoodsAndServices.PowerOfAttorneyPerson,
	|	SaleOfGoodsAndServices.PowerOfAttorneyNumber,
	|	SaleOfGoodsAndServices.SalesOrder,
	|	SaleOfGoodsAndServices.Organization,
	|	SaleOfGoodsAndServices.Counterparty,
	|	SaleOfGoodsAndServices.VATTaxation,
	|	SaleOfGoodsAndServices.Partner,
	|	SaleOfGoodsAndServices.Department,
	|	SaleOfGoodsAndServices.SalesOpportunity,
	|	SaleOfGoodsAndServices.DiscountsAreCalculated,
	|	SaleOfGoodsAndServices.Warehouse,
	|	SaleOfGoodsAndServices.Terms,
	|	SaleOfGoodsAndServices.AmountARAP,
	|	SaleOfGoodsAndServices.PaymentMethod,
	|	SaleOfGoodsAndServices.BusinessOperation,
	|	SaleOfGoodsAndServices.PriceIncludesVAT,
	|	SaleOfGoodsAndServices.CashAccount,
	|	SaleOfGoodsAndServices.IssuiedBy,
	|	SaleOfGoodsAndServices.IssuiedByJobTitle,
	|	SaleOfGoodsAndServices.OrderSales,
	|	SaleOfGoodsAndServices.FinancialAccountingGroup,
	|	SaleOfGoodsAndServices.LoyaltyCard,
	|	SaleOfGoodsAndServices.Contract,
	|	SaleOfGoodsAndServices.Basis,
	|	SaleOfGoodsAndServices.DeliveryMethod,
	|	SaleOfGoodsAndServices.DeliveryZone,
	|	SaleOfGoodsAndServices.DeliveryAddressFieldValues,
	|	SaleOfGoodsAndServices.CarrierPartner,
	|	SaleOfGoodsAndServices.DeliveryTimeFrom,
	|	SaleOfGoodsAndServices.DeliveryTimeTo,
	|	SaleOfGoodsAndServices.DeliveryAddressOfCarrier,
	|	SaleOfGoodsAndServices.DeliveryAddressOfCarrierFieldValues,
	|	SaleOfGoodsAndServices.AdditionalDeliveryInformation,
	|	SaleOfGoodsAndServices.ContactPerson,
	|	SaleOfGoodsAndServices.Director,
	|	SaleOfGoodsAndServices.ChiefAccountant,
	|	SaleOfGoodsAndServices.ARAPObjectSettings,
	|	SaleOfGoodsAndServices.ToReturnReusablePackage,
	|	SaleOfGoodsAndServices.ReusablePackagesReturnDate,
	|	SaleOfGoodsAndServices.ReusablePackageFillingStatus,
	|	SaleOfGoodsAndServices.PackageDepositIsRequired,
	|	SaleOfGoodsAndServices.ReferenceDocumentDateForPrintForms,
	|	SaleOfGoodsAndServices.BaseDocumentNumber,
	|	SaleOfGoodsAndServices.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.CustomerInvoice AS SaleOfGoodsAndServices
	|WHERE
	|	SaleOfGoodsAndServices.Ref = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Products AS Products,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Characteristic AS Characteristic,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Purpose AS Purpose,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Series AS Series,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Package AS Package,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Price AS Price,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATRate AS VATRate,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Warehouse AS Warehouse,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.CountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Count AS Count,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackagesByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.NumberOfPackages AS NumberOfPackages,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SumByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.Sum AS Sum,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmountByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.VATAmount AS VATAmount,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVATByDocument - CertificateOfDiscrepanciesAfterShipmentOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.SalesOrder,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Action,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref.DiscrepanciesPostingMethod AS DiscrepanciesPostingMethod,
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.RowCode
	|INTO GoodsSales_
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS CertificateOfDiscrepanciesAfterShipmentOfGoods
	|WHERE
	|	CertificateOfDiscrepanciesAfterShipmentOfGoods.Ref = &DiscrepancyCertificate
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND CertificateOfDiscrepanciesAfterShipmentOfGoods.SaleOfGoodsAndServices = &DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsSales_.Products,
	|	GoodsSales_.Characteristic,
	|	GoodsSales_.Purpose,
	|	GoodsSales_.Series,
	|	GoodsSales_.Package,
	|	GoodsSales_.Price,
	|	GoodsSales_.VATRate,
	|	GoodsSales_.Warehouse,
	|	GoodsSales_.Count,
	|	GoodsSales_.NumberOfPackages,
	|	GoodsSales_.Sum,
	|	GoodsSales_.VATAmount,
	|	GoodsSales_.AmountIncludingVAT,
	|	GoodsSales_.SalesOrder,
	|	GoodsSales_.Action AS GoodsAction,
	|	GoodsSales_.DiscrepanciesPostingMethod,
	|	GoodsSales_.RowCode
	|FROM
	|	GoodsSales_ AS GoodsSales_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsSales_.SalesOrder
	|FROM
	|	GoodsSales_ AS GoodsSales_
	|WHERE
	|	GoodsSales_.SalesOrder <> UNDEFINED";
	Query = New Query(QueryText);
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate", FillingData.DiscrepancyCertificate);
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	FillPropertyValues(ThisObject, HeaderSelection);
	SubsequentDeliveryBySale = FillingData.BasisOfAct;
	
	TableOfGoods = QueryBatch[2].Unload();
	For Each CurRow In TableOfGoods Do
		// Delivery in excess of the order
		If (CurRow.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection
			Or CurRow.DiscrepanciesPostingMethod = Enums.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentsAsSeparateBaseDocuments)
			And CurRow.GoodsAction = Enums.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired Then
			CurRow.RowCode = 0;
		EndIf;	
	EndDo;
	Goods.Load(TableOfGoods);
	
	SampleOrders = QueryBatch[3].Select();
	ItemsInSelectionOrders = SampleOrders.Count();
	If ItemsInSelectionOrders > 0 Then
		OrderSales = True;
		If ItemsInSelectionOrders = 1 Then
			SampleOrders.Next();
			SalesOrder = SampleOrders.SalesOrder;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Status) Then
		Status = Enums.StatusesOfCustomerInvoices.Shipped;
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(Val FillingData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Ref        AS DiscrepancyCertificate,
	|	ReturnOfGoodsFromCustomer.Ref             AS SubsequentDeliveryBySale,
	|	ReturnOfGoodsFromCustomer.Currency             AS Currency,
	|	ReturnOfGoodsFromCustomer.Organization        AS Organization,
	|	ReturnOfGoodsFromCustomer.Counterparty         AS Counterparty,
	|	ReturnOfGoodsFromCustomer.VATTaxation AS VATTaxation,
	|	ReturnOfGoodsFromCustomer.Department      AS Department,
	|	ReturnOfGoodsFromCustomer.Warehouse              AS Warehouse,
	|	ReturnOfGoodsFromCustomer.Partner            AS Partner,
	|	ReturnOfGoodsFromCustomer.Terms         AS Terms,
	|
	|	CASE
	|		WHEN
	|			ReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer)
	|			OR ReturnOfGoodsFromCustomer.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromRetailCustomer)
	|		THEN
	|			VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		ELSE
	|			VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|	END AS BusinessOperation,
	|
	|	ReturnOfGoodsFromCustomer.PriceIncludesVAT                     AS PriceIncludesVAT,
	|	ReturnOfGoodsFromCustomer.Contract                             AS Contract,
	|	ReturnOfGoodsFromCustomer.ContactPerson                      AS ContactPerson,
	|	ReturnOfGoodsFromCustomer.ReusablePackageReturn AS ToReturnReusablePackage,
	|	ReturnOfGoodsFromCustomer.DepositForPackageIsRequired             AS PackageDepositIsRequired,
	|	NOT DiscrepancyReportFollowingReceipt.Posted                    AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	DiscrepancyReportFollowingReceipt.Status                         AS StatusOfDivergenceReport,
	|	NOT DiscrepancyReportFollowingReceipt.Status IN (VALUE(Enum.StatusesOfDiscrepancyReport.ForCompletion), VALUE(Enum.StatusesOfDiscrepancyReport.Processed_)) AS ThereAreErrorsStatusReport,
	|	NOT ReturnOfGoodsFromCustomer.Posted                         AS ThereAreErrorsInReturnDocument
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS DiscrepancyReportFollowingReceipt
	|		INNER JOIN Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|		ON (TRUE)
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	DiscrepancyReportFollowingReceipt.Products           AS Products,
	|	DiscrepancyReportFollowingReceipt.Characteristic         AS Characteristic,
	|	DiscrepancyReportFollowingReceipt.Series                  AS Series,
	|	DiscrepancyReportFollowingReceipt.BatchesIndicationStatus    AS BatchesIndicationStatus,
	|	DiscrepancyReportFollowingReceipt.Package               AS Package,
	|	DiscrepancyReportFollowingReceipt.Price                   AS Price,
	|	DiscrepancyReportFollowingReceipt.VATRate              AS VATRate,
	|	DiscrepancyReportFollowingReceipt.RowCode              AS RowCode,
	|
	|	SUM(DiscrepancyReportFollowingReceipt.Count - DiscrepancyReportFollowingReceipt.CountByDocument)                 AS Count,
	|	SUM(DiscrepancyReportFollowingReceipt.NumberOfPackages - DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument) AS NumberOfPackages,
	|	SUM(DiscrepancyReportFollowingReceipt.Sum - DiscrepancyReportFollowingReceipt.SumByDocument)                           AS Sum,
	|	SUM(DiscrepancyReportFollowingReceipt.VATAmount - DiscrepancyReportFollowingReceipt.VATAmountByDocument)                     AS VATAmount,
	|	SUM(DiscrepancyReportFollowingReceipt.AmountIncludingVAT - DiscrepancyReportFollowingReceipt.AmountIncludingVATByDocument)                   AS AmountIncludingVAT
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS DiscrepancyReportFollowingReceipt
	|WHERE
	|	DiscrepancyReportFollowingReceipt.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceipt.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND DiscrepancyReportFollowingReceipt.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceipt.NumberOfPackages - DiscrepancyReportFollowingReceipt.NumberOfPackagesByDocument > 0
	|
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	BatchesIndicationStatus,
	|	Package,
	|	Price,
	|	VATRate,
	|	RowCode
	|	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////2
	|SELECT
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products                                                                 AS Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic                                                               AS Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series                                                                        AS Series,
	|	SUM(DiscrepancyReportFollowingReceiptSetOfSeries.Count - DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument)  AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS DiscrepancyReportFollowingReceiptSetOfSeries
	|WHERE
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Ref = &DiscrepancyCertificate
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.DocumentBasis = &DocumentBasis
	|	AND DiscrepancyReportFollowingReceiptSetOfSeries.Count - DiscrepancyReportFollowingReceiptSetOfSeries.CountByDocument > 0
	|
	|GROUP BY
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Products,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Characteristic,
	|	DiscrepancyReportFollowingReceiptSetOfSeries.Series
	|
	|";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	SetPrivilegedMode(True);
	
	QueryBatch = Query.ExecuteBatch();
	HeaderSelection = QueryBatch[0].Select();
	
	HeaderSelection.Next();
	
	// According to the return document
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.SubsequentDeliveryBySale,
		,
		HeaderSelection.ThereAreErrorsInReturnDocument,
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
	
	If Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
		If Not ValueIsFilled(Date) Then
			Date = CurrentSessionDate();
		EndIf;
	EndIf;
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	
EndProcedure

Procedure FillInDataOnGoodsTransferredToCommission(Val FillingData)
	
	BusinessOperation = FillingData.BusinessOperation;
	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	If ValueIsFilled(Terms) Then
		FillInTermsOfSalesUnderAgreement();
	EndIf;
	If ValueIsFilled(Contract) Then
		ContractARAPCurrency = Common.ObjectAttributeValue(Contract, "ARAPCurrency");
		ARAPCurrency = ContractARAPCurrency;
		Currency = ContractARAPCurrency;
	EndIf;
	If ValueIsFilled(Partner) And Not ValueIsFilled(Contract) Then
		FillInDefaultSalesConditions();
	EndIf;

	FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	ConsignmentSalesServer.FillInGoodsOnBalancesTransferredToCommissionUnderNewScheme(ThisObject, False);
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined, ReFillVATRate = False)
	
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
	If ValueIsFilled(Contract) Then
		MarkedProductOutflowOption = Common.ObjectAttributeValue(Contract, "MarkedProductOutflowOption");
	EndIf;
	
	Department             = SettingsValueCached.UserDivision(Manager, Department);
	
	ParametersOfAccount = OrganizationSDefaultAccountParameters();
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	ParametersStructure = CashServer.DefaultParametersForFillingInCheckout();
	ParametersStructure.Organization 	= Organization;
	ParametersStructure.CashAccount			= CashAccount;
	ParametersStructure.Individual	= Courier;

	CashAccount                     = SettingsValueCached.GetOrganizationSDefaultSalesRegister(ParametersStructure);
	
	Warehouse                     = SettingsValueCached.GetDefaultWarehouse(Warehouse, GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments"), True);
	If Not GetFunctionalOption("UseDeedsOfTransfer") Then
		SaleRegistrationOption = Enums.SalesRegistrationOptions.CustomerInvoice;
	EndIf;
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Warehouse);
	If StructureOfResponsible <> Undefined Then
		IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;

	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting
		Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
		Or BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods
		Or Not GetFunctionalOption("UseStatusesOfGoodsServicesSales") Then
		
		Status = Enums.StatusesOfCustomerInvoices.Shipped;
	ElsIf BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit
		And GetFunctionalOption("UseStatusesOfGoodsServicesSales") Then
		
		Status = Enums.StatusesOfCustomerInvoices.InTransit;
	EndIf;
	
	If Not OrderSales
		Or BusinessOperation <> Enums.BusinessTransactions.TransferOfTitleToGoods Then

		FillParameters = Documents.CustomerInvoice.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	// Fill in the bid taking into account the current date of the document. We recalculate the related details of the tabular part.
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(ThisObject);
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfFillingInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(ThisObject);
	StructureOfFillingInVATRate.FillingOnBasisOfCopying = ValueIsFilled(FillingData);
	
	If ReFillVATRate Then
		StructureOfActions.Insert("FillInVATRate", StructureOfFillingInVATRate);
	Else
		StructureOfActions.Insert("AdjustVATRate", StructureOfFillingInVATRate);
	EndIf;
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions, CachedValues);

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("ClearAmountOfSettlements", Undefined);
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValues.ProcessedRows,
		StructureOfActions,
		Goods,
		CachedValues);
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
	If GoodsDeliveryClientServer.UsedDelivery20()
		And DeliveryMethod.IsEmpty() Then
		
		DeliveryMethod = Enums.TransportMethods.SelfPickup;
		
	EndIf;
	
EndProcedure

Procedure InitializeSalesConditions()
	
	If Not GetFunctionalOption("ToUseTermsOfSales") And Not OrderSales Then
		FillInDefaultSalesConditions();
	EndIf;
	
EndProcedure

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

Procedure CheckChangesInBusinessOperations(Cancel)
	
	ImplementationIsNotPaid = (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	
	If Not IsNew()
		And ImplementationIsNotPaid Then
	
		Query = New Query;
		Query.Text = 
		"SELECT
		|	CustomersARAPAccounting.SumExpense AS PayAmount
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting.Turnovers(,,Period,
		|		ARAPObject.Object = &SalesOrder
		|	) AS CustomersARAPAccounting
		|
		|	INNER JOIN
		|		Document.CustomerInvoice AS DocumentData
		|	ON
		|		DocumentData.Ref = &Ref
		|		AND DocumentData.BusinessOperation <> &BusinessOperation
		|WHERE
		|	CustomersARAPAccounting.SumExpense > 0";
		
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("SalesOrder", ?(ValueIsFilled(SalesOrder), SalesOrder, Ref));
		Query.SetParameter("BusinessOperation", BusinessOperation);
		
		Selection = Query.Execute().Select();
		
		If Selection.Next() Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Giao hàng đã thanh toán. Không thể thiết lập giao dịch %1';
							|ru = 'Реализация оплачена. Нельзя устанавливать операцию %1';
							|en = 'Sale is paid. Cannot set transaction %1'; fa = 'Sale is paid. Cannot set transaction %1';
							|it = 'Vendita pagata. Impossibile impostare operazione %1';
							|pl = 'Realizacja jest oplacona. Nie można ustawić operacji %1';
							|tr = 'Satış ödendi. %1böyle bir işlem gerçekleştirilemez'"),
						BusinessOperation);
			Common.MessageToUser(Text, ThisObject, "BusinessOperation", , Cancel);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks)
	
	InventoryTypeDetails = New Structure;
	InventoryTypeDetails.Insert("Organization",				Catalogs.Companies.ManagementCompany);
	InventoryTypeDetails.Insert("TaxationOfOrganization",	Undefined);
	InventoryTypeDetails.Insert("FinancialAccountingGroup",		Undefined);
	InventoryTypeDetails.Insert("BusinessOperation",		BusinessOperation);
	
	For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
		
		If InventoryLine.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityPerRow = Min(Parameters.Count, InventoryLine.Count);
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, InventoryLine);
		
		FillableProperties = "Package, Price, VATRate, SetAccountingDimension, FEACNCode, ARAPObject";
		FillPropertyValues(NewRow, RowOfGoods, FillableProperties);
		
		NewRow.Count			= QuantityPerRow;
		NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
		NewRow.SalesOrder		= ?(ValueIsFilled(RowOfGoods.SalesOrder),
											RowOfGoods.SalesOrder,
											Undefined);
		
		If Parameters.Count <> 0 Then
			NewRow.NumberOfPackages			= QuantityPerRow * Parameters.NumberOfPackages
														/ Parameters.Count;
			NewRow.AmountARAP			= QuantityPerRow * Parameters.AmountARAP
														/ Parameters.Count;
			NewRow.ManualDiscount			= QuantityPerRow * Parameters.ManualDiscount
														/ Parameters.Count;
			NewRow.DiscountMarkupAmount	= QuantityPerRow * Parameters.DiscountMarkupAmount
														/ Parameters.Count;
		EndIf;
		
		If InventoryLine.Count <> 0 Then
			NewRow.AmountIncludingVAT	= QuantityPerRow * Parameters.AmountIncludingVAT / Parameters.Count;
			NewRow.VATAmount	= QuantityPerRow * Parameters.VATAmount / Parameters.Count;
			NewRow.ExciseTaxAmount	= QuantityPerRow * InventoryLine.ExciseTaxAmount / InventoryLine.Count;
			NewRow.VATAmountCompl = QuantityPerRow * Parameters.VATAmountCompl / Parameters.Count;
			NewRow.VATAmountMan = QuantityPerRow * Parameters.VATAmountMan / Parameters.Count;
		EndIf;
		
		InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
		InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
		InventoryLine.AmountIncludingVAT			= InventoryLine.AmountIncludingVAT - NewRow.AmountIncludingVAT;
		InventoryLine.VATAmount			= InventoryLine.VATAmount - NewRow.VATAmount;
		InventoryLine.ExciseTaxAmount		= InventoryLine.ExciseTaxAmount - NewRow.ExciseTaxAmount;
		InventoryLine.VATAmountCompl = InventoryLine.VATAmountCompl - NewRow.VATAmountCompl;
		InventoryLine.VATAmountMan = InventoryLine.VATAmountMan - NewRow.VATAmountMan;
		
		For Each KeyAndValue In Parameters Do
			Parameters[KeyAndValue.Key] = Parameters[KeyAndValue.Key] - NewRow[KeyAndValue.Key];
		EndDo;
		
		If BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
			
			RecipientInventoryOwnerAttribute = ComplianceOfTypesOfStocks.Get(InventoryLine.InventoryOwnerAttribute);
			
			If RecipientInventoryOwnerAttribute = Undefined Then
				InventoryTypeDetails.FinancialAccountingGroup = Common.ObjectAttributeValue(
																InventoryLine.InventoryOwnerAttribute,
																"FinancialAccountingGroup");
				
				RecipientInventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Catalogs.Companies.ManagementCompany,
																					BusinessOperation,
																					InventoryTypeDetails);
				
				ComplianceOfTypesOfStocks.Insert(InventoryLine.InventoryOwnerAttribute, RecipientInventoryOwnerAttribute);
			EndIf;
			
			NewRow.RecipientInventoryOwnerAttribute = RecipientInventoryOwnerAttribute;
			
		Else
			NewRow.RecipientInventoryOwnerAttribute = Undefined;
		EndIf;
		
		If Parameters.Count = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillInAdditionalStockTypes() Export
	
	NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, ProductsInSet, 
									|ItemVariantOfSet, Package, SalesOrder, FEACNCode, VATRate, Price, 
									|ARAPObject";
	NamesOfSummationColumns	= "Count, NumberOfPackages, AmountARAP, ManualDiscount,
									|DiscountMarkupAmount, AmountIncludingVAT, VATAmount,
									|VATAmountCompl, VATAmountMan";
	UnloadedColumns			= NamesOfGroupingColumns + ", " + NamesOfSummationColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
	
	Parameters = New Structure(NamesOfSummationColumns);
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, SalesOrder, NumberOfPackages");
	ComplianceOfTypesOfStocks = New Map;
	
	For Each RowOfGoods In GoodsTable Do
		
		FillPropertyValues(Parameters, RowOfGoods);
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		TheStructureOfTheSearch.NumberOfPackages = 0;
		
		FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks);
		
		If ValueIsFilled(RowOfGoods.SalesOrder)
			And Parameters.Count <> 0 Then
			
			TheStructureOfTheSearch.SalesOrder = Undefined;
			
			FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks);
			
		EndIf;
		
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
	
	If (Status <> Enums.StatusesOfCustomerInvoices.ForPrepayment
			Or BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent)
		And (Not Posted
			Or RefillInventoryKinds
			Or CheckChangesToDocumentDetails(TempTablesManager)
			Or CheckProductChanges_(TempTablesManager))Then
		
		FillParameters = ParametersForFillingInventoryTypes(False);
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		NamesOfGroupingColumns		= "ItemsLocationAttributes, SetAccountingDimension, InventoryOwnerAttribute, CCDNumber, 
										|VATRate, SalesOrder, FEACNCode, PartnerProducts";
		NamesOfSummationColumns	= "Count, QuantityByGBRN, NumberOfPackages, AmountIncludingVAT, VATAmount";
		NamesOfSummationColumns	= NamesOfSummationColumns + ", ExciseTaxAmount";
		ExcisableGoodsAccounting.CalculateAmountOfExciseTax(ThisObject, FillParameters, , Cancel);
		AdditionalProperties.Insert("WriteDownAmountOfExciseTax", FillParameters.CalculateAmountOfExciseTax);
		InventoryKinds.GroupBy(NamesOfGroupingColumns, NamesOfSummationColumns);
		
		FillInAdditionalStockTypes();
	ElsIf Status = Enums.StatusesOfCustomerInvoices.ForPrepayment Then
		InventoryKinds.Clear();
		
	EndIf;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.CustomerInvoice.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.CustomerInvoice.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	
	If Not BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
		FieldsNames.Insert("Work_5", "Department");
		
		// If the Warehouse is a group, then for the analysis of the inventory item, we take the warehouse from PM
		WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
		
		If ValueIsFilled(Warehouse)
			And WarehouseDetails.IsFolder
			And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
			
			FieldsNames.Insert("Arbitrary", "Warehouse");
			
		EndIf;
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
EndProcedure

#EndRegion

#Region Delivery

Function WarehousesUsedForDelivery()
	
	Result = New Array; // Array of CatalogRef.Warehouses
	
	If Not DeliveryIsRequired Then
		Return Result;
	EndIf;
	
	TableOfGoods = Goods.Unload(, "Products, Warehouse");
	
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
	DeliveryVerificationSettings.DeliveryWarehouses = WarehousesUsedForDelivery();
	DeliveryVerificationSettings.InvoiceForOrders = OrderSales;
	DeliveryVerificationSettings.DeliveryIndicationMethodFieldName = "";
	DeliveryVerificationSettings.MethodOfSpecifyingDeliveryIsUnconditional = Enums.DeliverySpecificationMethods.ForWholeDocument;
	DeliveryVerificationSettings.GoodsForDeliveryTableName = "";
	
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
	ThereAreGoodsNotOnOrders = Not OrderSales;
	
	If DeliveryIsApplicable
		And OrderSales Then
		
		ColumnsNames = "RowCode, SalesOrder";
		TableOfGoods = Goods.Unload(, ColumnsNames);
		Query = New Query;
		QueryText =
		"SELECT
		|	TableOfGoods.RowCode AS RowCode,
		|	TableOfGoods.SalesOrder AS SalesOrder
		|INTO TTTableOfGoods
		|FROM
		|	&TableOfGoods AS TableOfGoods
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE AS Flag
		|FROM
		|	TTTableOfGoods AS TTTableOfGoods
		|WHERE
		|	(CAST(TTTableOfGoods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice = TRUE
		|			OR CAST(TTTableOfGoods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice = TRUE
		|			OR TTTableOfGoods.RowCode = 0)";
		Query.Text = QueryText;
		Query.SetParameter("TableOfGoods", TableOfGoods);
		
		Selection = Query.Execute().Select();
		ThereAreGoodsNotOnOrders = Selection.Next();
		
	EndIf;
	
	If Not DeliveryIsApplicable
		Or (Not ThereAreGoodsNotOnOrders
				And Goods.Count() > 0) Then
		
		DeliveryIsRequired = False;
		DeliveryVerificationSettings.DeliveryIsRequired = DeliveryIsRequired;
		GoodsDelivery.ClearUnusedDeliveryFields(DeliveryVerificationSettings, Cancel);
		GoodsDelivery.ClearFillDeliveryLineCodes(ThisObject, DeliveryIsRequired);
		
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
		GoodsDelivery.ClearFillDeliveryLineCodes(ThisObject, DeliveryIsRequired);
		
		FieldNamesOfDeliveryPointAddresses = "Address, AddressValue, FieldValueAddress";
		DeliveryPointAddressFields = Common.ObjectAttributesValues(DeliveryPoint, FieldNamesOfDeliveryPointAddresses);
		
		DeliveryAddress = DeliveryPointAddressFields.Address;
		DeliveryAddressValue = DeliveryPointAddressFields.AddressValue;
		DeliveryAddressFieldValues = DeliveryPointAddressFields.FieldValueAddress;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// The procedure creates a temporary table of products with separate accounting Analytics.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table Manager
//								that will contain the created table.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfGoods.Warehouse,
	|
	|	DocumentDataTable.Department,
	|	DocumentDataTable.Manager,
	|	DocumentDataTable.SalesOpportunity AS SalesOpportunity,
	|	TableOfGoods.Purpose AS Purpose,
	|
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&VATTaxation AS VATTaxation,
	|
	|	TableOfGoods.Count AS Count
	|	
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|
	|	LEFT JOIN
	|		DocumentDataTable AS DocumentDataTable
	|	ON
	|		TRUE
	|WHERE
	|	TableOfGoods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|");
	Query.SetParameter("VATTaxation", VATTaxation);
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
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

Function GetDocumentAmountByContainer() Export
	
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
	|	Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND &PackageDepositIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountIncludingVAT"));
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountIncludingVAT;
	Return TotalAmount__;
	
EndFunction

Function GetAmountOfSettlementsForTS() Export
	
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
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage
	|	OR &PackageDepositIsRequired
	|");
	
	Query.SetParameter("Goods", Goods.Unload(,"Products,AmountARAP"));
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired", PackageDepositIsRequired);
	
	Upload0 = Query.Execute().Unload();
	TotalAmount__ = Upload0[0].AmountARAP;
	Return TotalAmount__;
	
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

Procedure CheckSalesOption(NotCheckedAttributeArray)
	
	If Not ValueIsFilled(SaleRegistrationOption) Then
		FilledInVersionOfSale = Enums.SalesRegistrationOptions.CustomerInvoice;
		
		If GetFunctionalOption("UseDeedsOfTransfer") Then
			Query = New Query(
			"SELECT
			|	Goods.Products AS Products
			|INTO
			|	TTProducts_1
			|FROM
			|	&Goods AS Goods
			|;
			|SELECT
			|	Goods.Products.Ref
			|FROM
			|	TTProducts_1 AS Goods
			|WHERE
			|	Goods.Products.SaleRegistrationOption = VALUE(Enum.SalesRegistrationOptions.DeedOfTransfer)");
			
			Query.SetParameter("Goods", Goods.Unload(,"Products"));
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() Then
				FilledInVersionOfSale = Enums.SalesRegistrationOptions.CustomerInvoice;
			ElsIf QueryResult.Unload().Count() = Goods.Count() Then
				FilledInVersionOfSale = Enums.SalesRegistrationOptions.DeedOfTransfer;
			EndIf;
		EndIf;
		
		If ValueIsFilled(FilledInVersionOfSale) Then
			ThisObject.AdditionalProperties.Insert("FilledInVersionOfSale", FilledInVersionOfSale);
			NotCheckedAttributeArray.Add("SaleRegistrationOption");
		EndIf;
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Organization, Date, VATTaxation, BusinessOperation";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM (
	|	SELECT
	|		TableOfGoods.SalesOrder AS SalesOrder,
	|		TableOfGoods.ARAPObject AS ARAPObject,
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.VATRate AS VATRate,
	|		TableOfGoods.FEACNCode AS FEACNCode,
	|		TableOfGoods.Package AS Package,
	|		TableOfGoods.Price AS Price,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.NumberOfPackages AS NumberOfPackages,
	|		TableOfGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|		TableOfGoods.VATAmount AS VATAmount,
	|		TableOfGoods.VATAmountCompl AS VATAmountCompl,
	|		TableOfGoods.VATAmountMan AS VATAmountMan,
	|		TableOfGoods.AmountARAP AS AmountARAP,
	|		TableOfGoods.ManualDiscount AS ManualDiscount,
	|		TableOfGoods.DiscountMarkupAmount AS DiscountMarkupAmount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|		TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.VATRate AS VATRate,
	|		TableTypesOfStocks_.FEACNCode AS FEACNCode,
	|		TableTypesOfStocks_.Package AS Package,
	|		TableTypesOfStocks_.Price AS Price,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.NumberOfPackages AS NumberOfPackages,
	|		-TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|		-TableTypesOfStocks_.VATAmount AS VATAmount,
	|		-TableTypesOfStocks_.VATAmountCompl AS VATAmountCompl,
	|		-TableTypesOfStocks_.VATAmountMan AS VATAmountMan,
	|		-TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|		-TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|		-TableTypesOfStocks_.DiscountMarkupAmount AS DiscountMarkupAmount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.SalesOrder,
	|	TableOfGoods.ARAPObject,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.VATRate,
	|	TableOfGoods.FEACNCode,
	|	TableOfGoods.Package,
	|	TableOfGoods.Price
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.NumberOfPackages) <> 0
	|	OR SUM(TableOfGoods.AmountIncludingVAT) <> 0
	|	OR SUM(TableOfGoods.VATAmount) <> 0
	|	OR SUM(TableOfGoods.VATAmountCompl) <> 0
	|	OR SUM(TableOfGoods.VATAmountMan) <> 0
	|	OR SUM(TableOfGoods.AmountARAP) <> 0
	|	OR SUM(TableOfGoods.ManualDiscount) <> 0
	|	OR SUM(TableOfGoods.DiscountMarkupAmount) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function ParametersForFillingInventoryTypes(ThisIsHolding)
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Never");
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		AvailableStockTypes = New Array;
		AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
		AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
		
		SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
		
	Else
		
		TaxationOfVATSales = VATTaxation;
		
		If BusinessOperation = Enums.BusinessTransactions.TransferOfTitleToGoods Then
			TaxationOfVATSales =
				VATAccountingERP.AccountingParametersForOrganization(Organization, Date).BasicTaxationVATSales;
		Else
			SelectionOfStockTypes_.VATTaxation = VATTaxation;
		EndIf;
		
		VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(SelectionOfStockTypes_,
																	Organization,
																	Date,
																	TaxationOfVATSales);
		VATAccountingERP.SetParametersForFillingInventoryTypesForCommissionSales(FillParameters);
		
		If BusinessOperation = Enums.BusinessTransactions.SaleToCustomerLocalAccounting Then
			If Not ThisIsHolding Then
				FillParameters.DocumentMakesBothArrivalAndExpenditure = True;
				FillParameters.WhenThereIsShortageOfGoodsOrganizationsShouldBeFilledWithStockTypesByDefault = False;
			EndIf;
		ElsIf BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgent
			Or BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit Then
			
			AvailableStockTypes = New Array;
			AvailableStockTypes.Add(Enums.InventoryTypes.OwnGoods);
			AvailableStockTypes.Add(Enums.InventoryTypes.ConsignedGoods);
			
			SelectionOfStockTypes_.InventoryType = AvailableStockTypes;
			
		EndIf;
		
		InventoriesServer.ToSupplementSelectionOfInventoryOwnerAttributesByTypeOfInventory(FillParameters.SelectionOfStockTypes_,
															Enums.InventoryTypes.Work_5);
		
	EndIf;
	If Documents.CustomerInvoice.ExcisableGoodsAreUsed(ThisObject) Then
		FillParameters.CalculateAmountOfExciseTax = True;
		SelectionOfStockTypes_.SubjectToExcise.Clear();
	EndIf;
	Return FillParameters;
	
EndFunction

Procedure SetPropertiesForChangingBankingDetails(Object, Var_AdditionalProperties)
	
	OnlyStateOfTransferOfOwnershipHasChanged = False;
	
	If (Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Object.BusinessOperation = Enums.BusinessTransactions.SalesViaCommissionAgentGoodsInTransit)
		And Object.Posted Then
		
		AttributesNotToCheck = New Structure;
		AttributesNotToCheck.Insert("Comment");
		AttributesNotToCheck.Insert("ReusablePackagesReturnDate");
		AttributesNotToCheck.Insert("PaymentDate");
		AttributesNotToCheck.Insert("DateOfTransferOfTitleToGoods");
		AttributesNotToCheck.Insert("Approved");
		
		UnverifiableTableParts = New Structure;
		UnverifiableTableParts.Insert("PackageBarcodes");
		
		AttributesNotToCheck.Insert("AdditionalAttributes");
		
		DocumentChanges = TMCommonUse.DocumentChanges(Object, AttributesNotToCheck, UnverifiableTableParts);
		
		OnlyStateOfTransferOfOwnershipHasChanged = DocumentChanges.Property("Attributes")
			Or DocumentChanges.Property("TabularSections");
		
		If DocumentChanges.Property("TabularSections") Then
			For Each TabularSection In DocumentChanges.TabularSections Do
				If TabularSection.Key <> "ARAPDetails" 
					And TabularSection.Key <> "PaymentScheduleSteps" Then
					OnlyStateOfTransferOfOwnershipHasChanged = False;
				EndIf;
			EndDo;
		EndIf;
		
		If DocumentChanges.Property("Attributes") Then
			For Each Attribute In DocumentChanges.Attributes Do
				If Attribute.Name <> "Status" Then
					OnlyStateOfTransferOfOwnershipHasChanged = False;
					Break;
				ElsIf Attribute.Name = "Status" 
					And (Attribute.NewValue = Enums.StatusesOfCustomerInvoices.ForPrepayment
					 	Or Attribute.PreviousValue2 = Enums.StatusesOfCustomerInvoices.ForPrepayment) Then
					OnlyStateOfTransferOfOwnershipHasChanged = False;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Var_AdditionalProperties.Insert("OnlyStateOfTransferOfOwnershipHasChanged", 
		OnlyStateOfTransferOfOwnershipHasChanged);
	
EndProcedure

Procedure SkipCheckingProhibitionOfChangingRegisters(Var_RegisterRecords)
	
	For Each CurRecordSet In Var_RegisterRecords Do
		
		MetadataObject = CurRecordSet.ThisObject.Metadata(); // MetadataObject
		
		CurRecordSet.AdditionalProperties.Insert("OnlyStateOfTransferOfOwnershipHasChanged", True);
		
		If Not GetFunctionalOption("NewOnlineARAPAccounting") 
			And (MetadataObject.Name = "CustomersARAPAccounting"
			Or MetadataObject.Name = "VendorsARAPAccounting") Then
			Continue;
		EndIf;
		
		CurRecordSet.AdditionalProperties.Insert("SkipPeriodClosingCheck", True);
		
	EndDo;
	
EndProcedure

// Fills in the VAT Amount (Local) and VAT Amount (upr.) columns in the Goods tabular part of the document.
//
Procedure FillInVATAmountsLocalMans() Export
	
	Query = New Query;
	Query.SetParameter("Recorder", Ref);
	Query.SetParameter("GoodsTable", Goods.Unload(, "SalesOrder, RowCode, VATAmountCompl, VATAmountMan"));
	Query.Text =
	"SELECT
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmountMan AS VATAmountMan
	|INTO GoodsTable
	|FROM
	|	&GoodsTable AS GoodsTable
	|WHERE
	|	GoodsTable.VATAmountCompl = 0
	|	OR GoodsTable.VATAmountMan = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.ReferenceOrder AS ReferenceOrder,
	|	NestedQuery.RowCode AS RowCode,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.VATAmountCompl) AS VATAmountCompl,
	|	SUM(NestedQuery.VATAmountMan) AS VATAmountMan
	|INTO BalanceTable
	|FROM
	|	(SELECT
	|		ShippingOrdersTurnover.ReferenceOrder AS ReferenceOrder,
	|		ShippingOrdersTurnover.RowCode AS RowCode,
	|		ShippingOrdersTurnover.IssuedInvoicesQuantityTurnover -
	|			ShippingOrdersTurnover.IssuedQuantityTurnover AS Count,
	|		ShippingOrdersTurnover.IssuedInvoicesVATAmountLocalTurnover -
	|			ShippingOrdersTurnover.IssuedVATAmountLocalTurnover AS VATAmountCompl,
	|		ShippingOrdersTurnover.IssuedInvoicesVATAmountManTurnover -
	|			ShippingOrdersTurnover.IssuedVATAmountManTurnover AS VATAmountMan
	|	FROM
	|		#ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
	|
	|	UNION ALL
	|
	|	SELECT
	|		OrdersForShipmentOfRegisteredRecords.ReferenceOrder AS ReferenceOrder,
	|		OrdersForShipmentOfRegisteredRecords.RowCode AS RowCode,
	|		OrdersForShipmentOfRegisteredRecords.IssuedQuantity AS Count,
	|		OrdersForShipmentOfRegisteredRecords.IssuedVATAmountLocal AS VATAmountCompl,
	|		OrdersForShipmentOfRegisteredRecords.IssuedVATAmountMan AS VATAmountMan
	|	FROM
	|		#OrdersForShipmentRegisteredRecordsExpanded AS OrdersForShipmentOfRegisteredRecords) AS NestedQuery
	|GROUP BY
	|	NestedQuery.ReferenceOrder,
	|	NestedQuery.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.SalesOrder AS SalesOrder,
	|	GoodsTable.RowCode AS RowCode,
	|	ISNULL(CASE
	|		WHEN BalanceTable.Count = 0
	|			THEN 1
	|		ELSE BalanceTable.Count
	|	END, 1) AS Count,
	|	ISNULL(CASE
	|		WHEN GoodsTable.VATAmountCompl = 0
	|			THEN ISNULL(BalanceTable.VATAmountCompl, 0)
	|		ELSE GoodsTable.VATAmountCompl
	|	END, 0) AS VATAmountCompl,
	|	ISNULL(CASE
	|		WHEN GoodsTable.VATAmountMan = 0
	|			THEN ISNULL(BalanceTable.VATAmountMan, 0)
	|		ELSE GoodsTable.VATAmountMan
	|	END, 0) AS VATAmountMan
	|FROM
	|	GoodsTable AS GoodsTable
	|		LEFT JOIN BalanceTable AS BalanceTable
	|		ON GoodsTable.SalesOrder = BalanceTable.ReferenceOrder
	|		AND GoodsTable.RowCode = BalanceTable.RowCode";
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(ReferenceOrder, RowCode) IN
		|	(SELECT
		|		SalesOrder,
		|		RowCode
		|	FROM
		|		GoodsTable)";
	TableFormationParameters.Group = "ReferenceOrder, RowCode";
	TableFormationParameters.Indicators = "Issued_1, TaxInvoicesRegistered";
	TableFormationParameters.Resources = "Count, VATAmountCompl, VATAmountMan";
	
	ShipmentOrdersTurnoverExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#ShipmentOrdersTurnoverExpanded",
		ShipmentOrdersTurnoverExpanded);
	
	TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
	TableFormationParameters.ConditionText =
		"(Recorder, ReferenceOrder, RowCode) IN
		|	(SELECT
		|		&Recorder,
		|		SalesOrder,
		|		RowCode
		|	FROM
		|		GoodsTable)";
	TableFormationParameters.Group = "ReferenceOrder, RowCode";
	TableFormationParameters.Indicators = "Issued_1";
	TableFormationParameters.Resources = "Count, VATAmountCompl, VATAmountMan";
	TableFormationParameters.PhysicalTable = True;
	
	OrdersForShipmentRegisteredRecordsExpanded =
		AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
			TableFormationParameters);
	
	Query.Text = StrReplace(Query.Text,
		"#OrdersForShipmentRegisteredRecordsExpanded",
		OrdersForShipmentRegisteredRecordsExpanded);
	
	TheStructureOfTheSearch = New Structure("SalesOrder, RowCode");
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		FillPropertyValues(TheStructureOfTheSearch, Selection);
		SearchForStrings = Goods.FindRows(TheStructureOfTheSearch);
		
		If SearchForStrings.Count() Then
			
			LineProducts_ = SearchForStrings.Get(0);
			
			If Not ValueIsFilled(LineProducts_.VATAmountCompl) Then
				LineProducts_.VATAmountCompl = Selection.VATAmountCompl / Selection.Count * LineProducts_.Count;
			EndIf;
			
			If Not ValueIsFilled(LineProducts_.VATAmountMan) Then
				LineProducts_.VATAmountMan = Selection.VATAmountMan / Selection.Count * LineProducts_.Count;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
