#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the terms of sale in the transfer of goods to the custodian.
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
	ComplCurrency                     = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SalesTermsAndConditions.Organization);
	LineOfBusiness        = SalesTermsAndConditions.LineOfBusiness;
	ReusablePackagesReturnDate = Date(1, 1, 1);
	ToReturnReusablePackage      = False;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization)
							And SalesTermsAndConditions.Organization <> Organization;
	
	If OrganizationChanged Then
		Organization = SalesTermsAndConditions.Organization;
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
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
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	Contract = Handler.GetDefaultContract(ThisObject);
	ContractDetails_ = New Structure("Currency, LineOfBusiness, Department", "ARAPCurrency");
	Catalogs.CounterpartyContracts.FillInDocumentDetails(ThisObject, Contract, ContractDetails_);
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract, CompanyBankAccount, CounterpartyBankAccount);
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(LineOfBusiness, Terms, Contract);
	EndIf;
	
	If ValueIsFilled(SalesTermsAndConditions.Warehouse) Then
		Warehouse = SalesTermsAndConditions.Warehouse;
		
		StructureOfResponsible = SalesServer.GetWarehouseManager(Warehouse);
		
		If StructureOfResponsible <> Undefined Then
			IssuiedBy          = StructureOfResponsible.EmployeeResponsible;
			IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_ Then
		
		If ValueIsFilled(SalesTermsAndConditions.ContactPerson)
			And Not ValueIsFilled(ContactPerson) Then
			
			ContactPerson = SalesTermsAndConditions.ContactPerson;
			
		EndIf;
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency,
																								ComplCurrency,
																								CurrentSessionDate());
	
EndProcedure

// Fills in the default sales terms in the transfer of goods to the custodian.
//
Procedure FillInDefaultSalesConditions() Export
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	ToUseTermsOfSales = Handler.ToUseTermsOfSales();
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("BusinessTransactions", Handler.ContractBusinessTransaction());
		FilterParameters.Insert("EmptyDocumentLink", Documents.TransferOfGoodsToBailee.EmptyRef());
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ConsignmentSales25", BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
		
		DefaultSalesTerms =
			SalesServer.GetDefaultSalesTerms(
				Partner,
				FilterParameters,
				Handler.CustomerAgreementsAreApplicable());
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				If ToUseTermsOfSales 
					And BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent Then
					FillInPricesBySalesConditions();
				EndIf;
				
			Else
				Terms = DefaultSalesTerms.Terms;
				
				PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
			EndIf;
			
		Else
			Terms = Undefined;
			
			PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
		EndIf;
		
		If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And ValueIsFilled(Contract) Then
			FillInPricesUnderAgreement();
		EndIf;
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sale under the agreement in the transfer of goods to the custodian.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	
	FillIn_TermsOfSales(SalesTermsAndConditions);
	FillInPricesBySalesConditions();
	
	If Not GetFunctionalOption("UseDeliveryManagement") Then
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
	EndIf;
	
EndProcedure

// This function generates temporary document data.
//
// Parameters:
//	TransferredGoods - Boolean - Indicates the formation of temporary document data tables for goods
//										transferred for safekeeping.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables(TransferredGoods = False) Export
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	&Date        AS Date,
	|	&Partner     AS Partner,
	|	&Counterparty  AS Counterparty,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			THEN VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef)
	|		ELSE &Terms
	|	END AS Terms,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Contract     AS Contract,
	|	&Currency      AS Currency,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnitManagers)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Manager
	|		ELSE VALUE(Catalog.Users.EmptyRef)
	|	END        AS Manager,
	|	CASE
	|		WHEN SalesOpportunitiesToCustomer.EnabledGoodsAssignmentInSalesOpportunity
	|				AND &GenerateInventoryOwnerAttributesBySalesOpportunities
	|			THEN &SalesOpportunity
	|		ELSE VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef)
	|	END        AS SalesOpportunity,
	|	CASE
	|		WHEN BusinessStructure.OptionOfAssignedAccountingOfGoods = VALUE(Enum.OptionsOfAssignedAccountingOfGoods.ByBusinessUnit)
	|				AND &GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers
	|			THEN &Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END        AS Department,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	&InventoryType  AS InventoryType
	|INTO DocumentDataTable
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON BusinessStructure.Ref = &Department
	|		
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		ON SalesOpportunitiesToCustomer.Ref = &SalesOpportunity
	|WHERE
	|	Companies.Ref = &Organization
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber    AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	TableOfGoods.SalesOrder   AS OrderDocument,
	|	TableOfGoods.Products   AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose     AS AssignmentRecipient,
	|	TableOfGoods.AssignmentSender AS Purpose,
	|	TableOfGoods.Package       AS Package,
	|	TableOfGoods.Series          AS Series,
	|	TableOfGoods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus,
	|	TableOfGoods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusRecipient,
	|	TableOfGoods.Count     AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE &FieldTextTableOfGoodsQuantityByGBRN_
	|	END                         AS QuantityByGBRN,
	|	&FieldTextTableOfGoodsCCDNumber_ AS CCDNumber,
	|	TableOfGoods.Warehouse          AS Warehouse,
	|	TableOfGoods.Price           AS Price,
	|	TableOfGoods.Sum          AS CommissionAmount,
	|	0                             AS AmountVATRemuneration,
	|	TRUE                        AS SelectTypesOfStocks
	|INTO TableOfGoods
	|FROM
	|	&TableOfGoods AS TableOfGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TableTypesOfStocks_.LineNumber      AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	TableTypesOfStocks_.SalesOrder     AS SalesOrder,
	|	TableTypesOfStocks_.InventoryOwnerAttribute       AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count       AS Count,
	|	TableTypesOfStocks_.Package         AS Package,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Date, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TableTypesOfStocks_.QuantityByGBRN
	|	END                               AS QuantityByGBRN,
	|	TableTypesOfStocks_.Price             AS Price,
	|	TableTypesOfStocks_.Sum            AS Sum,
	|	TableTypesOfStocks_.SalesOrder     AS OrderDocument,
	|	TableTypesOfStocks_.CCDNumber         AS CCDNumber
	|INTO TTTypesOfStocks
	|FROM
	|	&TableTypesOfStocks_ AS TableTypesOfStocks_
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	TableTypesOfStocks_.LineNumber      AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute       AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|	TableTypesOfStocks_.SalesOrder AS SalesOrder,
	|	Dimension.Products              AS Products,
	|	Dimension.Characteristic            AS Characteristic,
	|	Dimension.Series                     AS Series,
	|	TableTypesOfStocks_.Count       AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber         AS CCDNumber,
	|	TableTypesOfStocks_.Package         AS Package,
	|	TableTypesOfStocks_.Price             AS Price,
	|	TableTypesOfStocks_.SalesOrder     AS OrderDocument,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS OriginWarehouse,
	|	Dimension.StorageLocation             AS Warehouse,
	|	TableTypesOfStocks_.Sum            AS CommissionAmount,
	|	0                                   AS AmountVATRemuneration,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	&InventoryOwnerAttributesAreSpecifiedManually          AS InventoryOwnerAttributesAreSpecifiedManually
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
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	TableOfGoods.LineNumber AS LineNumber,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&BusinessOperation      AS BusinessOperation,
	|	&Organization                AS Organization,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Catalog.VendorPriceTypes.EmptyRef) AS PriceKind,
	|	TableOfGoods.Products AS Products,
	|	TableOfGoods.OrderDocument        AS SalesOrder,
	|	UNDEFINED                AS GoodsOwner,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	FALSE                        AS ThisIsReusablePackage
	|INTO OriginalProductTable
	|FROM
	|	TableOfGoods AS TableOfGoods
	|WHERE
	|	CAST(TableOfGoods.Products AS Catalog.Products).ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers = GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers");
	GenerateInventoryOwnerAttributesBySalesOpportunities                  = GetFunctionalOption("GenerateInventoryOwnerAttributesBySalesOpportunities");
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("TableOfGoods",        TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",    InventoryKinds);
	Query.SetParameter("Ref",                Ref);
	Query.SetParameter("Date",                  Date);
	Query.SetParameter("Partner",               Partner);
	Query.SetParameter("Counterparty",            Counterparty);
	Query.SetParameter("Terms",            Terms);
	Query.SetParameter("Contract",               Contract);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("Manager",              Manager);
	Query.SetParameter("SalesOpportunity",                SalesOpportunity);
	Query.SetParameter("Department",         Department);
	Query.SetParameter("Currency",                Currency);
	Query.SetParameter("InventoryType",            Enums.InventoryTypes.OwnGoods);
	Query.SetParameter("Posted",              Posted);
	Query.SetParameter("GenerateInventoryOwnerAttributesBySalesOpportunities", GenerateInventoryOwnerAttributesBySalesOpportunities);
	Query.SetParameter("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers",
								GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	InventoriesServer.AddMandatoryColumnsToTemporaryTables(Query);
	InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject, Query);
	
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
//	TempTablesManager - TempTablesManager - temporary table Manager
//								that will contain the created table.
//
Procedure CreateTemporaryTableOfProductsAndAnalytics(TempTablesManager) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	TableOfGoods.Products               AS Products,
	|	TableOfGoods.Characteristic             AS Characteristic,
	|	TableOfGoods.Purpose                 AS Purpose,
	|	CASE
	|		WHEN TableOfGoods.BatchesIndicationStatus = 14
	|			THEN TableOfGoods.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END                                     AS Series,
	|	TableOfGoods.Count                 AS Count,
	|	TableOfGoods.Warehouse                      AS Warehouse,
	|	DocumentDataTable.Manager           AS Manager,
	|	DocumentDataTable.SalesOpportunity             AS SalesOpportunity,
	|	DocumentDataTable.Department      AS Department,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation
	|INTO TableOfProductsAndAnalytics
	|FROM
	|	TableOfGoods AS TableOfGoods
	|		LEFT JOIN DocumentDataTable AS DocumentDataTable
	|		ON TRUE
	|WHERE
	|	TableOfGoods.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|";
	
	Query.TempTablesManager = TempTablesManager;
	
	Query.Execute();
	
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
//	DocumentObject - DocumentObject.TransferOfGoodsToBailee - the document for which parameters are initialized.
//	WriteMode - DocumentWriteMode - the recording mode of the document.
//
Procedure InitializeParametersForFillingInventoryTypesForConducting(DocumentObject, WriteMode = Undefined) Export
	
	DocumentObject.AdditionalProperties.Insert("ParametersForFillingInventoryTypes", ParametersForFillingInventoryTypes());
	
EndProcedure

// Fills in the details that store information about inventory types and inventory accounting analysts in the tabular part of the "Goods"
// document, and also fills in the tabular part of the "Inventory types".
//
// Parameters:
//	Cancel - Boolean - indicates that the data could not be filled in.
//	DocumentTables - See Documents.TransferOfGoodsToBailee.CollectionOfTabularPartsOfGoods.
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

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	QuantityVerificationParameters = Handler.TSParametersForRounding();
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["Goods"]);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	SynonymForOrder = Handler.SynonymForOrder();
	
	For CurIndex__ = 0 To Goods.Count() - 1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		If TransferByOrders
			And Not ValueIsFilled(SalesOrder)
			And Not ValueIsFilled(LineProducts_.SalesOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""%SynonymForOrder%"" trong dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""%SynonymForOrder%"" в строке %LineNumber% списка ""Товары""';
							|en = '""%SynonymForOrder%"" field in line %LineNumber% of the Item list is not filled in'; fa = '""%SynonymForOrder%"" field in line %LineNumber% of the Item list is not filled in';
							|it = 'Non è stato compilato il campo ""%SynonymForOrder%"" nella riga %LineNumber% dell''elenco ""Merci""';
							|pl = 'Pole ""%SynonymForOrder%"" nie jest wypełnione w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""%SynonymForOrder%"" alanı doldurulmamış'");
			ErrorText = StrReplace(ErrorText, "%SynonymForOrder%", SynonymForOrder);
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
			ErrorField  = CommonClientServer.PathToTabularSection("Goods",
																			LineProducts_.LineNumber,
																			"SalesOrder");
			
			Common.MessageToUser(ErrorText, ThisObject, ErrorField, Undefined, Cancel);
			
		EndIf;
		
	EndDo;
	
	FilterParameters       = New Structure("RowCode", 0);
	ThereAreLinesBeyondOrder = UserRightsCached.SalesInExcessOfOrder()
							And (Goods.FindRows(FilterParameters).Count() > 0);
	
	// The line code must be filled in if the transfer is on order.
	If Not TransferByOrders
		Or (TransferByOrders
			And ThereAreLinesBeyondOrder) Then
		
		NotCheckedAttributeArray.Add("Goods.RowCode");
		
	EndIf;
	
	GoodsDelivery.CheckDeliveryDetails(ThisObject, NotCheckedAttributeArray, Cancel,
		TransferByOrders);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	If Not Handler.CustomerAgreementsAreApplicable() Then
		NotCheckedAttributeArray.Add("Terms");
	EndIf;
	
	If Not ToReturnReusablePackage Then
		NotCheckedAttributeArray.Add("ReusablePackagesReturnDate");
	EndIf;
	
	PartnersAndCounterparties.CheckPartnerContent(ThisObject, NotCheckedAttributeArray, Cancel, True);

	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	If Not TransferByOrders
		And Not BusinessOperation = Enums.BusinessTransactions.TransferToToller2_5
		And Not UserRightsCached.CreateCustomerInvoicesWithoutReferenceToOrder() Then
		ErrorText = NStr("vi = 'Không có quyền tạo chuyển giao hàng hóa cho người giám sát mà không có lệnh';
						|ru = 'Нет прав на создание передачи товаров хранителю без заказа';
						|en = 'No rights to create VMI fill-up without order'; fa = 'No rights to create VMI fill-up without order';
						|it = 'Diritti insufficienti per la creazione del trasferimento merci al depositario senza ordine';
						|pl = 'Brak praw do tworzenia transferu towarów do depozytariusza bez zamówienia';
						|tr = 'Sipariş olmaksızın malların emanetçiye transferini sağlama hakkı yoktur'");
		Common.MessageToUser(ErrorText, Ref, , , Cancel);
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
		
		Common.MessageToUser(ErrorText, , "Object.ReusablePackagesReturnDate", , Cancel);
		
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	SalesServer.CheckShipmentBan(Partner, Cancel);
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	TransferOfGoodsToBaileeLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Var OriginWarehouse;
	Var HeaderAttributes;
	Var DesignParameters;
	Var Handler;
	
	InitializeDocumentBeforeFillingItOut();
	
	FilledInBasedOnDocument = False;
	FillInDataType          = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		DocumentValueBasis = Undefined;
		FillingData.Property("DocumentBasis", DocumentValueBasis);
		DocumentTypeBase = TypeOf(DocumentValueBasis);
		
		Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsByOrderType(DocumentTypeBase);
		
		// Filling out the list of orders from the form.
		If DocumentTypeBase = Handler.OrderType_5()
			Or DocumentTypeBase = Type("Array") Then
			
			FilledInBasedOnDocument = False;
			
			// If a warehouse has been transferred, it is necessary to fill in the goods only for the specified warehouse.
			FillingData.Property("OriginWarehouse",       OriginWarehouse);
			FillingData.Property("HeaderAttributes",      HeaderAttributes);
			FillingData.Property("DesignParameters", DesignParameters);
			
			FillInDocumentBasedOnCustomerSOrder(FillingData.DocumentBasis, OriginWarehouse, HeaderAttributes,
				DesignParameters);
			
		ElsIf FillingData.Property("DiscrepancyCertificate")
			And FillingData.Property("BasisOfAct") Then
			
			If TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.TransferOfGoodsToBailee") Then
				
				If FillingData.Property("Patch") Then
					DocumentCorrection.FillInCorrection(ThisObject, FillingData.BasisOfAct);
					CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterShipment(FillingData);
				Else
					FilledInBasedOnDocument = True;
					FillInDocumentOnBasisOfActOfDiscrepanciesAfterShipment(FillingData);
				EndIf;
				
			ElsIf TypeOf(FillingData.BasisOfAct) = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
				
				FilledInBasedOnDocument = True;
				
				FillInDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(FillingData);
				
			EndIf;
			
		Else
			FillInSelectionDocument(FillingData);
		EndIf;
		
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		FillInDocumentOnBasisOfSaleTransaction(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		
		FilledInBasedOnDocument = True;
		
		Date = OrdersServer.GetMinimumOrderShipmentDate(FillingData);
		
		FillInDocumentBasedOnCustomerSOrder(FillingData, OriginWarehouse);
	ElsIf FillInDataType = Type("DocumentRef.SubcontractOrder2_5") Then
		
		FilledInBasedOnDocument = True;
		
		FillInDocumentBasedOnCustomerSOrder(FillingData, OriginWarehouse);
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.ReceiptOfGoodsFromCustodian") Then
		
		FilledInBasedOnDocument = True;
		
		FillInDocumentOnBasisOfReceiptOfGoodsFromCustodian(FillingData);
		
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then
		
		FilledInBasedOnDocument = True;
		
		FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData);
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ToReturnReusablePackage = False;
	EndIf;

	If Not FilledInBasedOnDocument Then
		
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
		
		If Not ValueIsFilled(SalesOrder)
			And Not Handler.ToUseTermsOfSales() Then
			
			FillInDefaultSalesConditions();
			
		EndIf;
		
	EndIf;
	
	InitializeDocument();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	If Handler = Undefined Then
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	EndIf;
	
	WarehouseGroup_ = Handler.ItIsGroupOfWarehousesAndWarehousesUsedByWHForSale(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
	TransferOfGoodsToBaileeLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentAmount         = GetDocumentAmount();
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	RoundingParameters = Handler.TSParametersForRounding();
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["Goods"]);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	If TransferByOrders
		And ValueIsFilled(SalesOrder) Then
		For Each CurRow In Goods Do
			If Not ValueIsFilled(CurRow.SalesOrder) Then
				CurRow.SalesOrder = SalesOrder;
			EndIf;
		EndDo;
	EndIf;
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
		
	EndIf;
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		ToReturnReusablePackage = False;
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	TransferOfGoodsToBaileeLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	TransferOfGoodsToBaileeLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	TransferOfGoodsToBaileeLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	TransferOfGoodsToBaileeLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	TransferByOrders                     = False;
	SalesOrder                          = Undefined;
	InventoryOwnerAttributesAreSpecifiedManually             = False;
	ReusablePackageFillingStatus = Enums.ReusablePackageFillingStates.EmptyRef();
	ToReturnReusablePackage             = False;
	
	If ValueIsFilled(Terms)
		And Handler.ToUseTermsOfSales() Then
		
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
		
		If SalesTermsAndConditions.AgreementStatus <> Enums.StatusesOfTermsOfSales.Closed Then
			ReusablePackagesReturnDate = Date(1,1,1);
			
		Else
			Terms = Undefined;
			ReusablePackagesReturnDate = Date(1,1,1);
		EndIf;
	Else
		ReusablePackagesReturnDate = Date(1,1,1);
	EndIf;
	
	For Each CurRow In Goods Do
		
		CurRow.SalesOrder          = Undefined;
		CurRow.RowCode             = 0;
		CurRow.RowID   = "";
		CurRow.Purpose            = Undefined;
		CurRow.AssignmentSender = Undefined;
		
	EndDo;
	
	DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	InvoicesServer.FillInAssignmentsInTablePart(Goods, DefaultAssignment);
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	TransferOfGoodsToBaileeLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInDocumentBasedOnCustomerSOrder(Val DocumentBasis,
													Val OriginWarehouse,
													OrderDetails = Undefined,
													DesignParameters = Undefined)
	
	BasisType = TypeOf(DocumentBasis);
	FillInByLeftovers = True;
	
	If Not DesignParameters = Undefined And TypeOf(DesignParameters) = Type("Structure") Then
		FillInByLeftovers =
			CommonClientServer.StructureProperty(DesignParameters, "FillInByLeftovers", FillInByLeftovers);
	EndIf;
	
	Handler = Documents.TransferOfGoodsToBailee.HandlerForActionsByOrderType(BasisType);
	
	If BasisType = Handler.OrderType_5() Then
		
		Query = New Query;
		Query.Text = Handler.TextOfRequestToFillInOrderForm();
		
		UseAdvancedFeaturesOfSalesOrder = Handler.UseAdvancedFeaturesOfSalesOrder();
		UseTransportationJobsForDeliveryAccountingByCarriers =
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers");
		
		Query.SetParameter("DocumentBasis",                DocumentBasis);
		Query.SetParameter("CheckDate",                     CurrentSessionDate());
		Query.SetParameter("ToUseTermsOfSales", Handler.ToUseTermsOfSales());
		Query.SetParameter("UseAdvancedFeaturesOfSalesOrder",
									UseAdvancedFeaturesOfSalesOrder);
		Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
									UseTransportationJobsForDeliveryAccountingByCarriers);
		
		SetPrivilegedMode(True);
		QueryResult = Query.ExecuteBatch();
		SetPrivilegedMode(False);
		
		OrderDetails = QueryResult[0].Select();
		OrderDetails.Next();
		
		Handler.OrderManager().CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder, OrderDetails.DocumentStatus, OrderDetails.ThereAreErrorsPosted);
		
		// Filling in the header
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
		
		Currency = OrderDetails.ARAPCurrency;
		CompanyBankAccount = OrderDetails.BankAccount;
		
		ReusablePackagesReturnDate = ReusablePackageServer.CalculateReturnDateOfMultiTurnContainer(
											ThisObject,
											OrderDetails.ReusablePackageReturnCycleLength,
											OrderDetails.CalculatePackageReturnDateAccordingToCalendar,
											OrderDetails.ScheduleOfPackageReturn);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			
			Query = New Query;
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
			
			Query.SetParameter("DocumentsArray", DocumentBasis);
			Query.SetParameter("CheckDate", CurrentSessionDate());
			
			SetPrivilegedMode(True);
			QueryResult = Query.Execute();
			SetPrivilegedMode(False);
			
			Warehouse         = OrderDetails.OriginWarehouse;
			WarehouseArray = QueryResult.Unload().UnloadColumn("Warehouse");
			
		EndIf;
		
	EndIf;
	
	TransferByOrders = True;
	
	// Filling in incl. goods.
	
	If ValueIsFilled(Warehouse)
		And Not Catalogs.Warehouses.IsFolder(Warehouse) Then
		OriginWarehouse = Warehouse;
	ElsIf Not ValueIsFilled(OriginWarehouse) Then
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			If WarehouseArray.Count() > 0 Then
				OriginWarehouse = WarehouseArray[0];
				Warehouse         = OriginWarehouse;
			EndIf;
		EndIf;
	Else
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			If TypeOf(OriginWarehouse) = Type("Array")
				And Not OriginWarehouse.Count() = 0 Then
				Warehouse = OriginWarehouse[0];
			Else
				Warehouse = OriginWarehouse;
			EndIf;
		EndIf;
	EndIf;
	
	TransferWarehouse = ?(OriginWarehouse = Undefined, Catalogs.Warehouses.EmptyRef(), OriginWarehouse);
	If ValueIsFilled(TransferWarehouse)
		And Not ValueIsFilled(Warehouse) Then
		Warehouse = TransferWarehouse;
	EndIf;
	
	If BasisType = Type("Array") Then
		AnArrayOfOrders = DocumentBasis;
	Else
		AnArrayOfOrders = New Array();
		AnArrayOfOrders.Add(SalesOrder);
	EndIf;
	
	If FillInByLeftovers Then
		FillParameters = New Structure("DesignParameters", DesignParameters);
	
		Documents.TransferOfGoodsToBailee.FillByOrderBalances(
			ThisObject, Goods, TransferWarehouse, AnArrayOfOrders, FillParameters, PackageBarcodes);
		Barcodes = PackageBarcodes.Unload();
		Barcodes.GroupBy("PackageBarcode");
		PackageBarcodes.Load(Barcodes);
	EndIf;
	
	OrdersServer.FillInOrderInOrderHeaderInTableSection(SalesOrder, Goods, "SalesOrder");
	
	If Not ValueIsFilled(SalesOrder)
		And AnArrayOfOrders.Count() = 1
		And TypeOf(AnArrayOfOrders[0]) = Type("DocumentRef.SalesOrder") Then
		SalesOrder = AnArrayOfOrders[0];
	EndIf;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	StructureBase = Handler.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
EndProcedure

Procedure FillInDocumentOnBasisOfActOfDiscrepanciesAfterShipment(Val FillingData)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ActAfterShipment.Ref           AS DiscrepancyCertificate,
	|	ActAfterShipment.Status           AS StatusOfDivergenceReport,
	|	GoodsHandover.Ref            AS Ref,
	|	GoodsHandover.Date              AS ReferenceDate,
	|	GoodsHandover.SalesOrder      AS SalesOrder,
	|	GoodsHandover.Partner           AS Partner,
	|	GoodsHandover.Counterparty        AS Counterparty,
	|	GoodsHandover.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	GoodsHandover.Terms        AS Terms,
	|	GoodsHandover.Organization       AS Organization,
	|	GoodsHandover.CompanyBankAccount AS CompanyBankAccount,
	|	GoodsHandover.Contract           AS Contract,
	|	GoodsHandover.Warehouse             AS Warehouse,
	|	GoodsHandover.Currency            AS Currency,
	|	GoodsHandover.BusinessOperation AS BusinessOperation,
	|
	|	GoodsHandover.Shipper AS Shipper,
	|	GoodsHandover.ShipperBankAccount AS ShipperBankAccount,
	|	GoodsHandover.GoodsRecipient  AS GoodsRecipient,
	|	GoodsHandover.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
	|
	|	GoodsHandover.DeliveryMethod                        AS DeliveryMethod,
	|	GoodsHandover.CarrierPartner                     AS CarrierPartner,
	|	GoodsHandover.DeliveryAddress                         AS DeliveryAddress,
	|	GoodsHandover.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
	|	GoodsHandover.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
	|	GoodsHandover.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
	|	GoodsHandover.DeliveryZone                          AS DeliveryZone,
	|	GoodsHandover.DeliveryTimeFrom                        AS DeliveryTimeFrom,
	|	GoodsHandover.DeliveryTimeTo                       AS DeliveryTimeTo,
	|	GoodsHandover.AdditionalDeliveryInformation    AS AdditionalDeliveryInformation,
	|
	|	GoodsHandover.SalesOpportunity                  AS SalesOpportunity,
	|	GoodsHandover.Department           AS Department,
	|	GoodsHandover.ContactPerson          AS ContactPerson,
	|	GoodsHandover.LineOfBusiness AS LineOfBusiness,
	|
	|	GoodsHandover.ToReturnReusablePackage             AS ToReturnReusablePackage,
	|	GoodsHandover.ReusablePackagesReturnDate        AS ReusablePackagesReturnDate,
	|	GoodsHandover.ReusablePackageFillingStatus AS ReusablePackageFillingStatus,
	|
	|	GoodsHandover.Director     AS Director,
	|	GoodsHandover.ChiefAccountant AS ChiefAccountant,
	|
	|	GoodsHandover.IssuiedBy          AS IssuiedBy,
	|	GoodsHandover.IssuiedByJobTitle AS IssuiedByJobTitle,
	|	GoodsHandover.Basis         AS Basis,
	|	GoodsHandover.ReferenceDocumentDateForPrintForms     AS ReferenceDocumentDateForPrintForms,
	|	GoodsHandover.BaseDocumentNumber    AS BaseDocumentNumber,
	|	NOT GoodsHandover.Posted       AS ThereAreErrorsPosted,
	|	NOT ActAfterShipment.Posted      AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	NOT ActAfterShipment.Status IN(&AcceptableActStatuses) AS ThereAreErrorsStatusReport
	|FROM
	|	Document.TransferOfGoodsToBailee AS GoodsHandover
	|		INNER JOIN Document.DiscrepancyReportFollowingShipment AS ActAfterShipment
	|		ON TRUE
	|WHERE
	|	GoodsHandover.Ref = &DocumentBasisCorrectionOfBasis
	|	AND ActAfterShipment.Ref = &DiscrepancyCertificate
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ProductsOfAct.SalesOrder   AS SalesOrder,
	|	ProductsOfAct.RowCode      AS RowCode,
	|	ProductsOfAct.Warehouse          AS Warehouse,
	|	ProductsOfAct.Products   AS Products,
	|	ProductsOfAct.Characteristic AS Characteristic,
	|	ProductsOfAct.Purpose     AS Purpose,
	|	ProductsOfAct.AssignmentSender AS AssignmentSender,
	|	ProductsOfAct.Package       AS Package,
	|	ProductsOfAct.Series          AS Series,
	|
	|	SUM(ProductsOfAct.CountByDocument - ProductsOfAct.Count)                 AS Count,
	|	SUM(ProductsOfAct.NumberOfPackagesByDocument - ProductsOfAct.NumberOfPackages) AS NumberOfPackages,
	|
	|	ProductsOfAct.PriceKind        AS PriceKind,
	|	ProductsOfAct.Price           AS Price,
	|
	|	SUM(ProductsOfAct.SumByDocument - ProductsOfAct.Sum) AS Sum
	|INTO TransferGoods
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ProductsOfAct
	|
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND ProductsOfAct.CountByDocument - ProductsOfAct.Count > 0
	|	AND ProductsOfAct.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	ProductsOfAct.SalesOrder,
	|	ProductsOfAct.RowCode,
	|	ProductsOfAct.Products,
	|	ProductsOfAct.Characteristic,
	|	ProductsOfAct.Purpose,
	|	ProductsOfAct.AssignmentSender,
	|	ProductsOfAct.Package,
	|	ProductsOfAct.Series,
	|	ProductsOfAct.Price,
	|	ProductsOfAct.Warehouse,
	|	ProductsOfAct.PriceKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	TransferGoods.SalesOrder   AS SalesOrder,
	|	TransferGoods.RowCode      AS RowCode,
	|	TransferGoods.Warehouse          AS Warehouse,
	|	TransferGoods.Products   AS Products,
	|	TransferGoods.Characteristic AS Characteristic,
	|	TransferGoods.Purpose     AS Purpose,
	|	TransferGoods.AssignmentSender AS AssignmentSender,
	|	TransferGoods.Package       AS Package,
	|	TransferGoods.Series          AS Series,
	|	TransferGoods.Count     AS Count,
	|	TransferGoods.NumberOfPackages AS NumberOfPackages,
	|	TransferGoods.PriceKind        AS PriceKind,
	|	TransferGoods.Price           AS Price,
	|	TransferGoods.Sum          AS Sum
	|FROM
	|	TransferGoods AS TransferGoods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	ActSeries.Warehouse          AS Warehouse,
	|	ActSeries.Products   AS Products,
	|	ActSeries.Characteristic AS Characteristic,
	|	ActSeries.Purpose     AS Purpose,
	|	ActSeries.AssignmentSender AS AssignmentSender,
	|	ActSeries.Series          AS Series,
	|	SUM(ActSeries.CountByDocument - ActSeries.Count) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|	AND ActSeries.CountByDocument - ActSeries.Count > 0
	|	AND ActSeries.SaleOfGoodsAndServices = &DocumentBasis
	|
	|GROUP BY
	|	ActSeries.Warehouse,
	|	ActSeries.Products,
	|	ActSeries.Characteristic,
	|	ActSeries.Purpose,
	|	ActSeries.AssignmentSender,
	|	ActSeries.Series
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT DISTINCT
	|	TransferGoods.SalesOrder AS SalesOrder
	|FROM
	|	TransferGoods AS TransferGoods
	|WHERE
	|	TransferGoods.SalesOrder <> VALUE(Document.SalesOrder.EmptyRef)
	|	AND TransferGoods.SalesOrder <> UNDEFINED";
	
	// According to the act of discrepancies after shipment.
	AcceptableActStatuses = DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn();
	
	Query.SetParameter("DiscrepancyCertificate",      FillingData.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis",     FillingData.BasisOfAct);
	Query.SetParameter("AcceptableActStatuses", AcceptableActStatuses);
	
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
	
	// According to the document of transfer of goods to the custodian.
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.Ref, Undefined,
		HeaderSelection.ThereAreErrorsPosted);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DiscrepancyCertificate,
															HeaderSelection.StatusOfDivergenceReport,
															HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
															HeaderSelection.ThereAreErrorsStatusReport,
															AcceptableActStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	SubsequentDeliveryByTransfer = FillingData.BasisOfAct;
	
	TableOfGoods = QueryBatch[2].Unload();
	
	For Each CurRow In TableOfGoods Do
		NewRow = Goods.Add();
		FillPropertyValues(NewRow,CurRow);
		
		NewRow.Sum = NewRow.Price * NewRow.NumberOfPackages;
	EndDo;
	
	SetOfSeries.Load(QueryBatch[3].Unload());
	
	SampleOrders           = QueryBatch[4].Select();
	ItemsInSelectionOrders = SampleOrders.Count();
	
	If ItemsInSelectionOrders > 0 Then
		TransferByOrders = True;
		
		If ItemsInSelectionOrders = 1 Then
			SampleOrders.Next();
			
			SalesOrder = SampleOrders.SalesOrder;
		EndIf;
	EndIf;
	
EndProcedure

Procedure CorrectionOfCorrectionOfDocumentOnBasisOfActOfDiscrepanciesAfterShipment(Val FillingData)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductsOfAct.RowCode             AS RowCode,
	|	ProductsOfAct.FilledInBySale AS FilledInBySale,
	|	ProductsOfAct.SalesOrder          AS SalesOrder,
	|	ProductsOfAct.Warehouse                 AS Warehouse,
	|	ProductsOfAct.Products          AS Products,
	|	ProductsOfAct.Characteristic        AS Characteristic,
	|	ProductsOfAct.Purpose            AS Purpose,
	|	ProductsOfAct.AssignmentSender AS AssignmentSender,
	|	ProductsOfAct.Package              AS Package,
	|	ProductsOfAct.Series                 AS Series,
	|	ProductsOfAct.PriceKind               AS PriceKind,
	|	ProductsOfAct.Price                  AS Price,
	|	ProductsOfAct.Count            AS Count,
	|	ProductsOfAct.Sum                 AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ProductsOfAct
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.SaleOfGoodsAndServices = &DocumentBasis
	|	AND ProductsOfAct.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|	AND ProductsOfAct.Count > 0
	|
	|ORDER BY
	|	LineNumber
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ActSeries.LineNumber           AS LineNumber,
	|	ActSeries.Warehouse                 AS Warehouse,
	|	ActSeries.Products          AS Products,
	|	ActSeries.Characteristic        AS Characteristic,
	|	ActSeries.Purpose            AS Purpose,
	|	ActSeries.AssignmentSender AS AssignmentSender,
	|	ActSeries.Series                 AS Series,
	|	ActSeries.Count            AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.SaleOfGoodsAndServices = &DocumentBasis
	|	AND ActSeries.Action IN (VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|							VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired))
	|	AND ActSeries.Count > 0
	|	AND NOT (NOT ActSeries.FilledInBySale
	|		AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.EmptyRef))";
	
	Query.SetParameter("DocumentBasis", FillingData.BasisOfAct);
	Query.SetParameter("DiscrepancyCertificate",  FillingData.DiscrepancyCertificate);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	TableOfItemsOfReport = QueryBatch[0].Unload();
	ActSeriesTable  = QueryBatch[1].Unload();
	
	GoodsTable = Goods.Unload();
	SeriesTable  = SetOfSeries.Unload();
	
	// Re-filling of products and series according to the act
	SelectionColumns =
		"Warehouse,
		|Products,
		|Characteristic,
		|Purpose,
		|AssignmentSender,
		|Series";
	If TransferByOrders Then
		SelectionColumns = "RowCode, SalesOrder, " + SelectionColumns;
	EndIf;
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In TableOfItemsOfReport Do
		
		If CurRow.FilledInBySale Then
			FillPropertyValues(FilterParameters, CurRow);
			FoundRows = GoodsTable.FindRows(FilterParameters);
			If FoundRows.Count() > 0 Then
				FoundRow = FoundRows[0];
				FoundRow.Count = CurRow.Count;
				FoundRow.Sum      = CurRow.Sum;
			Else
				NewRow = GoodsTable.Add();
				FillPropertyValues(NewRow, CurRow);
			EndIf;
		Else // to add lines from the over-order report
			NewRow = GoodsTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	SelectionColumns =
		"LineNumber,
		|Products,
		|Characteristic,
		|Purpose,
		|AssignmentSender,
		|Series,
		|Warehouse";
	FilterParameters = New Structure(SelectionColumns);
	
	For Each CurRow In ActSeriesTable Do
		
		FillPropertyValues(FilterParameters, CurRow);
		
		FoundRows = SeriesTable.FindRows(FilterParameters);
		If FoundRows.Count() > 0 Then
			
			For Each FoundRow In FoundRows Do
				
				If FoundRow.Count = CurRow.Count Then
					Continue;
				EndIf;
				
				If FoundRow.Count > CurRow.Count Then
					FoundRow.Count = CurRow.Count;
				Else
					NewRow = SeriesTable.Add();
					FillPropertyValues(NewRow, FoundRow);
					NewRow.Count = CurRow.Count - FoundRow.Count;
				EndIf;
				
			EndDo;
			
		Else // to add lines from the act in addition to the order
			NewRow = SeriesTable.Add();
			FillPropertyValues(NewRow, CurRow);
		EndIf;
		
	EndDo;
	
	Goods.Load(GoodsTable);
	SetOfSeries.Load(SeriesTable);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Procedure FillInDocumentOnBasisOfActOfDiscrepanciesAfterAcceptance(Val FillingData)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ReportAfterAcceptance.Ref             AS DiscrepancyCertificate,
	|	ReportAfterAcceptance.Status             AS StatusOfDivergenceReport,
	|	ReceiptFromTheCustodian.Ref      AS SubsequentDeliveryByTransfer,
	|	ReceiptFromTheCustodian.Partner     AS Partner,
	|	ReceiptFromTheCustodian.Counterparty  AS Counterparty,
	|	ReceiptFromTheCustodian.Terms  AS Terms,
	|	ReceiptFromTheCustodian.Organization AS Organization,
	|	ReceiptFromTheCustodian.Contract     AS Contract,
	|	ReceiptFromTheCustodian.Warehouse       AS Warehouse,
	|	ReceiptFromTheCustodian.Currency      AS Currency,
	|
	|	ReceiptFromTheCustodian.SalesOpportunity          AS SalesOpportunity,
	|	ReceiptFromTheCustodian.Department   AS Department,
	|	ReportAfterAcceptance.ContactPerson         AS ContactPerson,
	|	ReceiptFromTheCustodian.LineOfBusiness AS LineOfBusiness,
	|
	|	ReceiptFromTheCustodian.ReusablePackageReturn   AS ToReturnReusablePackage,
	|	ReceiptFromTheCustodian.ReusablePackageFillingStatus AS ReusablePackageFillingStatus,
	|
	|	CASE
	|		WHEN ReceiptFromTheCustodian.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCustodian)
	|			THEN VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
	|		WHEN ReceiptFromTheCustodian.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromCommissionAgent)
	|			THEN VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|		WHEN ReceiptFromTheCustodian.BusinessOperation = VALUE(Enum.BusinessTransactions.ReturnFromProcessingCompany2_5)
	|			THEN VALUE(Enum.BusinessTransactions.TransferToToller2_5)
	|	END AS BusinessOperation,
	|	
	|	ReportAfterAcceptance.Director     AS Director,
	|	ReportAfterAcceptance.ChiefAccountant AS ChiefAccountant,
	|
	|	NOT ReportAfterAcceptance.Posted        AS ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
	|	NOT ReportAfterAcceptance.Status IN(&AcceptableActStatuses) AS ThereAreErrorsStatusReport,
	|	NOT ReceiptFromTheCustodian.Posted AS ThereAreErrorsInReceiptDocument
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt AS ReportAfterAcceptance
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|		ON TRUE
	|WHERE
	|	ReportAfterAcceptance.Ref = &DiscrepancyCertificate
	|	AND ReceiptFromTheCustodian.Ref = &DocumentBasisCorrectionOfBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ProductsOfAct.RowCode      AS RowCode,
	|	ProductsOfAct.Warehouse          AS Warehouse,
	|	ProductsOfAct.Products   AS Products,
	|	ProductsOfAct.Characteristic AS Characteristic,
	|	ProductsOfAct.Purpose     AS Purpose,
	|	ProductsOfAct.Purpose     AS AssignmentSender,
	|	ProductsOfAct.Package       AS Package,
	|	ProductsOfAct.Series          AS Series,
	|	ProductsOfAct.BatchesIndicationStatus AS BatchesIndicationStatus,
	|
	|	SUM(ProductsOfAct.Count - ProductsOfAct.CountByDocument)                 AS Count,
	|	SUM(ProductsOfAct.NumberOfPackages - ProductsOfAct.NumberOfPackagesByDocument) AS NumberOfPackages,
	|
	|	ProductsOfAct.Price      AS Price,
	|
	|	SUM(ProductsOfAct.Sum - ProductsOfAct.SumByDocument)         AS Sum
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.Goods AS ProductsOfAct
	|WHERE
	|	ProductsOfAct.Ref = &DiscrepancyCertificate
	|	AND ProductsOfAct.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND ProductsOfAct.NumberOfPackages - ProductsOfAct.NumberOfPackagesByDocument > 0
	|	AND ProductsOfAct.DocumentBasis = &DocumentBasis
	|
	|GROUP BY
	|	ProductsOfAct.RowCode,
	|	ProductsOfAct.Products,
	|	ProductsOfAct.Characteristic,
	|	ProductsOfAct.Purpose,
	|	ProductsOfAct.Package,
	|	ProductsOfAct.Series,
	|	ProductsOfAct.BatchesIndicationStatus,
	|	ProductsOfAct.Price,
	|	ProductsOfAct.Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	ActSeries.Warehouse          AS Warehouse,
	|	ActSeries.Products   AS Products,
	|	ActSeries.Characteristic AS Characteristic,
	|	ActSeries.Purpose     AS Purpose,
	|	ActSeries.Purpose     AS AssignmentSender,
	|	ActSeries.Series          AS Series,
	|	SUM(ActSeries.Count - ActSeries.CountByDocument) AS Count
	|FROM
	|	Document.DiscrepancyReportFollowingReceipt.SetOfSeries AS ActSeries
	|WHERE
	|	ActSeries.Ref = &DiscrepancyCertificate
	|	AND ActSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInVendorInvoiceAfterGoodsReceipt.RegisterAndReturnOverdelivered)
	|	AND ActSeries.Count - ActSeries.CountByDocument > 0
	|	AND ActSeries.DocumentBasis = &DocumentBasis
	|
	|GROUP BY
	|	ActSeries.Warehouse,
	|	ActSeries.Products,
	|	ActSeries.Characteristic,
	|	ActSeries.Purpose,
	|	ActSeries.Series";
	
	// According to the act of discrepancies
	AcceptableActStatuses = DiscrepanciesServer.ArrayOfAcceptableStatusesOfReportsOfDiscrepanciesWhenCreatedBasedOn();
	
	Query.SetParameter("DiscrepancyCertificate",      FillingData.DiscrepancyCertificate);
	Query.SetParameter("DocumentBasis",     FillingData.BasisOfAct);
	Query.SetParameter("AcceptableActStatuses", AcceptableActStatuses);
	
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
	
	// According to the receipt document
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.SubsequentDeliveryByTransfer,
															Undefined,
															HeaderSelection.ThereAreErrorsInReceiptDocument);
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.DiscrepancyCertificate,
															HeaderSelection.StatusOfDivergenceReport,
															HeaderSelection.ThereAreMistakesActOfDiscrepanciesWasCarriedOut,
															HeaderSelection.ThereAreErrorsStatusReport,
															AcceptableActStatuses);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	SubsequentDeliveryByTransfer = FillingData.BasisOfAct;
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	If Not Handler.UseAdvancedFeaturesOfSalesOrder() Then
		If Not ValueIsFilled(Date) Then
			Date = CurrentSessionDate();
		EndIf;
	EndIf;
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	If FillingData.Property("Partner") Then
		Partner = FillingData.Partner;
		
		Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
		
		If Handler.ToUseTermsOfSales() Then
			FillInDefaultSalesConditions();
		EndIf;
	EndIf;
	
	If FillingData.Property("Goods") Then
		For Each CurRow In FillingData.Goods Do
			NewRow = Goods.Add();
			
			FillPropertyValues(NewRow, CurRow);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfSaleTransaction(Val DocumentBasis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	SalesOpportunitiesToCustomer.Ref              AS SalesOpportunity,
	|	SalesOpportunitiesToCustomer.Partner             AS Partner,
	|	SalesOpportunitiesToCustomer.CustomerTermsOfSales AS Terms,
	|	ContactPersons.ContactPerson        AS ContactPerson
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		LEFT JOIN Catalog.SalesOpportunitiesToCustomer.PartnersAndContactPersons AS ContactPersons
	|		ON ContactPersons.Ref = SalesOpportunitiesToCustomer.Ref
	|			AND ContactPersons.Partner = SalesOpportunitiesToCustomer.Partner
	|			AND ContactPersons.ContactPerson <> VALUE(Catalog.ContactPersonsForPartners.EmptyRef)
	|WHERE
	|	SalesOpportunitiesToCustomer.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfSaleTransaction(Selection.Partner);
	
	FillPropertyValues(ThisObject, Selection);
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	If Handler.ToUseTermsOfSales() Then
		
		If ValueIsFilled(Terms) Then
			
			AgreementOperation = Common.ObjectAttributeValue(Terms, "BusinessOperation");
			DocumentOperations  = TMCommonUse.PermissibleBusinessOperationsOfDocument("TransferOfGoodsToBailee");
			
			If DocumentOperations.Find(AgreementOperation) <> Undefined Then
				FillInTermsOfSalesUnderAgreement();
			EndIf;
			
		Else
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CustomerTermsOfSales.Ref         AS Terms,
	|	CustomerTermsOfSales.BusinessOperation AS BusinessOperation,
	|	CustomerTermsOfSales.Partner        AS Partner,
	|	CustomerTermsOfSales.ContactPerson AS ContactPerson,
	|	CustomerTermsOfSales.Status         AS DocumentStatus,
	|	CASE
	|		WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                              AS ThereAreErrorsStatus,
	|	CustomerTermsOfSales.Standard_        AS ThereAreErrorsTypical,
	|	CustomerTermsOfSales.ConsignmentSales25 AS ConsignmentSales25
	|FROM
	|	Catalog.TermsOfSale  AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	
	SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("TransferOfGoodsToBailee",
		Selection.BusinessOperation);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfSales.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(Selection.ThereAreErrorsTypical);
	
	ParametersForCheckingPossibilityOfEnteringBasedOn = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	ParametersForCheckingPossibilityOfEnteringBasedOn.Status = Selection.DocumentStatus;
	ParametersForCheckingPossibilityOfEnteringBasedOn.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	ParametersForCheckingPossibilityOfEnteringBasedOn.ArrayOfValidStatuses = ArrayOfValidStatuses;
	
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(Selection.Terms, ParametersForCheckingPossibilityOfEnteringBasedOn);
	
	If Selection.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			And Not Selection.ConsignmentSales25 Then
		
		ErrorText = StrTemplate(NStr("vi = 'Không thể nhập chứng từ ""Chuyển đi ký gửi"" dựa trên thỏa thuận với giao dịch ""%1"" theo sơ đồ ký gửi %2.
											|Cần sử dụng chứng từ ""%3"".';
											|ru = 'Нельзя выполнить ввод документа ""Передача на комиссию"" на основании соглашения с операцией ""%1"" по комиссионной схеме %2.
											|Необходимо использовать документ ""%3"".';
											|en = 'Cannot create the ""Consignment sales"" document based on the terms of sales with the ""%1"" transaction under the %2 commission scheme.
											|Use the ""%3"" document.'; fa = 'Cannot create the ""Consignment sales"" document based on the terms of sales with the ""%1"" transaction under the %2 commission scheme.
											|Use the ""%3"" document.';
											|it = 'Cannot create the ""Consignment sales"" document based on the terms of sales with the ""%1"" transaction under the %2 commission scheme.
											|Use the ""%3"" document.';
											|pl = 'Cannot create the ""Consignment sales"" document based on the terms of sales with the ""%1"" transaction under the %2 commission scheme.
											|Use the ""%3"" document.';
											|tr = '%2 komisyon şeması kapsamında ""%1"" işlemiyle yapılan sözleşmeye dayalı ""Konsinye satış"" belgesinin girilmesi mümkün değildir.
											|""%3"" belgesinin kullanılması gerekmektedir.'"),
			Selection.BusinessOperation,
			ConsignmentSalesServer.PostfixCommissionSchemes20(),
			Metadata.Documents.CustomerInvoice.Presentation());
		
		Raise ErrorText;
		
	EndIf;
	
	FillPropertyValues(ThisObject, Selection);
	
	FillInTermsOfSalesUnderAgreement();
	
EndProcedure

Procedure FillInDocumentOnBasisOfReceiptOfGoodsFromCustodian(Val DocumentBasis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ReceiptFromTheCustodian.Ref      AS DocumentBasis,
	|	ReceiptFromTheCustodian.Ref      AS Ref,
	|	ReceiptFromTheCustodian.Partner     AS Partner,
	|	ReceiptFromTheCustodian.Counterparty  AS Counterparty,
	|	ReceiptFromTheCustodian.Terms  AS Terms,
	|	ReceiptFromTheCustodian.Organization AS Organization,
	|	ReceiptFromTheCustodian.Contract     AS Contract,
	|	ReceiptFromTheCustodian.Warehouse       AS Warehouse,
	|	ReceiptFromTheCustodian.Currency      AS Currency,
	|	ReceiptFromTheCustodian.DocumentAmount AS DocumentAmount,
	|	ReceiptFromTheCustodian.SalesOpportunity      AS SalesOpportunity,
	|	ReceiptFromTheCustodian.LineOfBusiness AS LineOfBusiness,
	|	ReceiptFromTheCustodian.ReusablePackageReturn AS ToReturnReusablePackage,
	|	NOT ReceiptFromTheCustodian.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|WHERE
	|	ReceiptFromTheCustodian.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	ReceiptFromTheCustodian.Warehouse          AS Warehouse,
	|	GoodsReceipts.Products        AS Products,
	|	GoodsReceipts.Characteristic      AS Characteristic,
	|	GoodsReceipts.Purpose          AS Purpose,
	|	GoodsReceipts.Purpose          AS AssignmentSender,
	|	GoodsReceipts.Package            AS Package,
	|	GoodsReceipts.Series               AS Series,
	|	GoodsReceipts.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsReceipts.Count          AS Count,
	|	GoodsReceipts.NumberOfPackages  AS NumberOfPackages,
	|	GoodsReceipts.Price                AS Price,
	|	GoodsReceipts.Sum               AS Sum
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.Goods AS GoodsReceipts
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|		ON GoodsReceipts.Ref = ReceiptFromTheCustodian.Ref
	|WHERE
	|	GoodsReceipts.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	ReceiptFromTheCustodian.Warehouse    AS Warehouse,
	|	SeriesReceipts.Products   AS Products,
	|	SeriesReceipts.Characteristic AS Characteristic,
	|	SeriesReceipts.Purpose     AS Purpose,
	|	SeriesReceipts.Purpose     AS AssignmentSender,
	|	SeriesReceipts.Series          AS Series,
	|	SeriesReceipts.Count     AS Count
	|FROM
	|	Document.ReceiptOfGoodsFromCustodian.SetOfSeries AS SeriesReceipts
	|		INNER JOIN Document.ReceiptOfGoodsFromCustodian AS ReceiptFromTheCustodian
	|		ON SeriesReceipts.Ref = ReceiptFromTheCustodian.Ref
	|WHERE
	|	SeriesReceipts.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(HeaderSelection.Ref,
															Undefined,
															HeaderSelection.ThereAreErrorsPosted);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	AssignmentToFillIn = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	For Each String In Goods Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		If String.AssignmentSender <> AssignmentToFillIn Then
			String.AssignmentSender = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	For Each String In SetOfSeries Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		If String.AssignmentSender <> AssignmentToFillIn Then
			String.AssignmentSender = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(Val DocumentBasis)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	VendorInvoice.Ref      AS DocumentBasis,
	|	VendorInvoice.Ref      AS Ref,
	|	VendorInvoice.Organization AS Organization,
	|	VendorInvoice.Warehouse       AS Warehouse,
	|	VendorInvoice.Currency      AS Currency,
	|	VendorInvoice.SalesOpportunity      AS SalesOpportunity,
	|	VendorInvoice.LineOfBusiness AS LineOfBusiness,
	|	NOT VendorInvoice.Posted AS ThereAreErrorsPosted
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref = &DocumentBasis
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsReceipts.Warehouse               AS Warehouse,
	|	GoodsReceipts.Products        AS Products,
	|	GoodsReceipts.Characteristic      AS Characteristic,
	|	GoodsReceipts.Purpose          AS Purpose,
	|	GoodsReceipts.Purpose          AS AssignmentSender,
	|	GoodsReceipts.Package            AS Package,
	|	GoodsReceipts.Series               AS Series,
	|	GoodsReceipts.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsReceipts.Count          AS Count,
	|	GoodsReceipts.NumberOfPackages  AS NumberOfPackages,
	|	GoodsReceipts.Price                AS Price,
	|	GoodsReceipts.Sum               AS Sum
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsReceipts
	|
	|WHERE
	|	GoodsReceipts.Ref = &DocumentBasis
	|	AND GoodsReceipts.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SeriesReceipts.Warehouse          AS Warehouse,
	|	SeriesReceipts.Products   AS Products,
	|	SeriesReceipts.Characteristic AS Characteristic,
	|	SeriesReceipts.Purpose     AS Purpose,
	|	SeriesReceipts.Purpose     AS AssignmentSender,
	|	SeriesReceipts.Series          AS Series,
	|	SeriesReceipts.Count     AS Count
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SeriesReceipts
	|	
	|WHERE
	|	SeriesReceipts.Ref = &DocumentBasis
	|	AND SeriesReceipts.Products.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		HeaderSelection.Ref,
		Undefined,
		HeaderSelection.ThereAreErrorsPosted);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	
	AssignmentToFillIn = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	
	For Each String In Goods Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		If String.AssignmentSender <> AssignmentToFillIn Then
			String.AssignmentSender = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	For Each String In SetOfSeries Do
		If String.Purpose <> AssignmentToFillIn Then
			String.Purpose = Catalogs.Assignments.EmptyRef();
		EndIf;
		If String.AssignmentSender <> AssignmentToFillIn Then
			String.AssignmentSender = Catalogs.Assignments.EmptyRef();
		EndIf;
	EndDo;
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.TransferOfGoodsToBailee);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure InitializeDocumentBeforeFillingItOut()
	
	If Not ValueIsFilled(Date) Then
		Date = CurrentSessionDate();
	EndIf;
	
EndProcedure

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	ComplCurrency  = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Currency") Then
		If Not ValueIsFilled(Currency) Then
			Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	Author       = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	UseWarehousesInTheTablePart = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
	CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
		CompanyBankAccount);
	
	ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
	CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
		CounterpartyBankAccount);
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Warehouse") Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse, UseWarehousesInTheTablePart, True);
	EndIf;
	
	StructureOfResponsible = SalesServer.GetWarehouseManager(Warehouse);
	
	If StructureOfResponsible <> Undefined Then
		IssuiedBy = StructureOfResponsible.EmployeeResponsible;
		IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
	EndIf;
	
	LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(Currency,
																								ComplCurrency,
																								CurrentSessionDate());
	
EndProcedure

#EndRegion

#Region InventoryKinds

Procedure FillStockTypes(Cancel)
	
	SetPrivilegedMode(True);
	
	TempTablesManager  = TemporaryDocumentDataTables();
	RefillInventoryKinds = InventoriesServer.CheckWhetherDocumentInventoryTypesNeedToBeRefilled(ThisObject);
	
	If Not Posted
		Or RefillInventoryKinds
		Or CheckChangesToDocumentDetails(TempTablesManager)
		Or CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
															TempTablesManager,
															Cancel,
															FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, SalesOrder, CCDNumber",
							"Count, QuantityByGBRN, Sum");
		
		If Not Cancel Then
			SynchronizeProductAccountingAnalyticsBetweenTableParts();
			FillInAdditionalStockTypes();
		EndIf;
		
	EndIf;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, BusinessOperation, Partner, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager, Ref, AttributesNames);
	
EndFunction

Function CheckChangesInGoodsByQuantityAndAmount(TempTablesManager) Export
	
	Query = New Query("
	|SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners
	|FROM (
	|	SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|		TableOfGoods.Package AS Package,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.CommissionAmount AS CommissionAmount,
	|		TableOfGoods.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|	WHERE
	|		TableOfGoods.Products.ItemsType  IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|	UNION ALL
	|	
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableTypesOfStocks_.ItemsLocationAttributesGoodsAtPartners AS ItemsLocationAttributesGoodsAtPartners,
	|		TableTypesOfStocks_.Package AS Package,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|		-TableTypesOfStocks_.AmountVATRemuneration AS AmountVATRemuneration
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.ItemsLocationAttributesGoodsAtPartners,
	|	TableOfGoods.Package
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0
	|	OR SUM(TableOfGoods.AmountVATRemuneration) <> 0
	|");
	Query.TempTablesManager = TempTablesManager;

	Result_Query = Query.Execute();
	
	Return (Not Result_Query.IsEmpty());
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	Handler = Documents.TransferOfGoodsToBailee.ActionHandler(BusinessOperation);
	
	Return Handler.ParametersForFillingInventoryTypes(ThisObject);
	
EndFunction

Procedure SynchronizeProductAccountingAnalyticsBetweenTableParts()
	
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes");
	
	For Each RowOfGoods In Goods Do
		
		GoodsQuantity = RowOfGoods.Count;
		Sum             = RowOfGoods.Sum;
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		FoundRows = InventoryKinds.FindRows(TheStructureOfTheSearch);
		
		For Each InventoryLine In FoundRows Do
			
			If InventoryLine.Count = 0 Then
				Continue;
			EndIf;
			
			Count = Min(GoodsQuantity, InventoryLine.Count);
			
			NewRow = InventoryKinds.Add();
			FillPropertyValues(NewRow, InventoryLine);
			NewRow.ItemsLocationAttributesGoodsAtPartners = RowOfGoods.ItemsLocationAttributesGoodsAtPartners;
			
			NewRow.Count			= Count;
			NewRow.QuantityByGBRN	= Count * InventoryLine.QuantityByGBRN / InventoryLine.Count;
			
			If GoodsQuantity <> 0 Then
				NewRow.Sum = Count * Sum / GoodsQuantity;
			EndIf;
			
			InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
			InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
			InventoryLine.Sum				= InventoryLine.Sum - NewRow.Sum;
			
			GoodsQuantity = GoodsQuantity - NewRow.Count;
			Sum             = Sum - NewRow.Sum;
			
			If GoodsQuantity = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
	RowFilter = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(RowFilter);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInAdditionalStockTypes()
	
	GroupColumns = "ItemsLocationAttributes,
						|ItemsLocationAttributesGoodsAtPartners,
						|SetAccountingDimension,
						|ProductsInSet,
						|ItemVariantOfSet,
						|Package,
						|Price,
						|SalesOrder";
	
	TotalingColumns = "Count,
						|NumberOfPackages,
						|Sum";
	
	UnloadedColumns = GroupColumns + ", " + TotalingColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(GroupColumns, TotalingColumns);
	
	Parameters                = New Structure;
	ComplianceOfTypesOfStocks = New Map();
	TheStructureOfTheSearch          = New Structure("ItemsLocationAttributes, SalesOrder, NumberOfPackages");
	
	For Each RowOfGoods In GoodsTable Do
		
		Parameters.Insert("Count",         RowOfGoods.Count);
		Parameters.Insert("NumberOfPackages", RowOfGoods.NumberOfPackages);
		
		Parameters.Insert("Sum",  RowOfGoods.Sum);
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		TheStructureOfTheSearch.NumberOfPackages = 0;
		
		FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks);
		
		If Parameters.Count <> 0
			And ValueIsFilled(RowOfGoods.SalesOrder) Then
			
			TheStructureOfTheSearch.SalesOrder = Undefined;
			
			FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks);
			
		EndIf;
		
	EndDo;
	
	FilterParameters = New Structure("Count", 0);
	ArrayOfRowsToDelete_1 = InventoryKinds.FindRows(FilterParameters);
	
	For Each TableRow In ArrayOfRowsToDelete_1 Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters, ComplianceOfTypesOfStocks)
	
	For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
		
		If InventoryLine.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityPerRow = Min(Parameters.Count, InventoryLine.Count);
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, InventoryLine);
		
		NewRow.ItemsLocationAttributesGoodsAtPartners = RowOfGoods.ItemsLocationAttributesGoodsAtPartners;
		NewRow.SetAccountingDimension = RowOfGoods.SetAccountingDimension;
		NewRow.Package			= RowOfGoods.Package;
		NewRow.Count			= QuantityPerRow;
		NewRow.QuantityByGBRN	= QuantityPerRow * InventoryLine.QuantityByGBRN / InventoryLine.Count;
		NewRow.Price				= RowOfGoods.Price;
		NewRow.SalesOrder		= ?(ValueIsFilled(RowOfGoods.SalesOrder),
											RowOfGoods.SalesOrder,
											Undefined);
		
		If Parameters.Count <> 0 Then
			NewRow.NumberOfPackages = QuantityPerRow * Parameters.NumberOfPackages / Parameters.Count;
		EndIf;
		
		If InventoryLine.Count <> 0 Then
			NewRow.Sum = QuantityPerRow * Parameters.Sum / Parameters.Count;
		EndIf;
		
		InventoryLine.Count		= InventoryLine.Count - NewRow.Count;
		InventoryLine.QuantityByGBRN	= InventoryLine.QuantityByGBRN - NewRow.QuantityByGBRN;
		
		InventoryLine.Sum = InventoryLine.Sum - NewRow.Sum;
		
		Parameters.Count			= Parameters.Count - NewRow.Count;
		Parameters.NumberOfPackages	= Parameters.NumberOfPackages - NewRow.NumberOfPackages;
		
		Parameters.Sum = Parameters.Sum - NewRow.Sum;
		
		If Parameters.Count = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills in the inventory accounting analytics in the tabular parts of the document that store information about the goods.
// If the parameter is not passed, then the data in the tabular parts of the document will be filled in.
//
// Parameters:
//	DocumentTables - See Documents.TransferOfGoodsToBailee.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.TransferOfGoodsToBailee.CollectionOfTabularPartsOfGoods();
		
		FillPropertyValues(DocumentTables, ThisObject);
	EndIf;
	
	GoodsTable = DocumentTables.Goods;
	
	PlacesOfAccounting = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(Undefined,
																		Warehouse,
																		Department,
																		Partner,
																		Contract);
	
	FieldsNames = InformationRegisters.ItemsLocationAttributes.DefaultCollectionFieldNames();
	FieldsNames.BatchesIndicationStatus = "BatchesIndicationStatusInWarehouses";
	FieldsNames.Purpose          = "AssignmentSender";
	
	// If the Warehouse is a group, then we take the warehouse from the PM for inventory accounting analytics.
	WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder,SelectGroup");
	
	If ValueIsFilled(Warehouse)
		And WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
		
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfAccounting, FieldsNames);
	
	PlacesOfRegistrationWithPartners = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																					Contract,
																					Department,
																					Partner,
																					Contract);
	
	FieldsNames.BatchesIndicationStatus        = "BatchesIndicationStatusOfGoodsTransferred";
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesGoodsAtPartners";
	
	If BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		FieldsNames.Purpose = "";
	Else
		FieldsNames.Purpose = "Purpose";
	EndIf;
	
	FieldsNames.Insert("Arbitrary", "");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable, PlacesOfRegistrationWithPartners, FieldsNames);
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInPricesBySalesConditions()
	
	FieldsNames = "PriceKind, Price, DeliveryPeriodDays";
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields",     FieldsNames);
	FillParameters.Insert("Date",               Date);
	FillParameters.Insert("Organization",        Organization);
	FillParameters.Insert("Currency",             Currency);
	FillParameters.Insert("Terms",         Terms);
	FillParameters.Insert("CalculateSets", True);
	If SalesServer.ThisIsAgreementOnNewCommission(Terms) Then
		FillParameters.Insert("PriceKind", Common.ObjectAttributeValue(Contract, "PriceTypeAccountingPriceType"));
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	
	EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
	
EndProcedure

Procedure FillInPricesUnderAgreement()
	
	PriceTypeAccountingPriceType = Common.ObjectAttributeValue(Contract, "PriceTypeAccountingPriceType");
	
	If ValueIsFilled(PriceTypeAccountingPriceType) Then
		
		FieldsNames = "PriceKind, Price, DeliveryPeriodDays";
		
		FillParameters = New Structure();
		FillParameters.Insert("PopulationFields",     FieldsNames);
		FillParameters.Insert("Date",               Date);
		FillParameters.Insert("Organization",        Organization);
		FillParameters.Insert("Currency",             Currency);
		FillParameters.Insert("PriceKind",            PriceTypeAccountingPriceType);
		FillParameters.Insert("CalculateSets", True);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
		
		EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
		
	EndIf;
	
EndProcedure

Function GetDocumentAmount() Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Goods.Products AS Products,
	|	Goods.Sum        AS Sum
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|	OR NOT &ToReturnReusablePackage";
	
	DocumentGoods = Goods.Unload(,"Products, Sum");
	
	Query.SetParameter("Goods",                    DocumentGoods);
	Query.SetParameter("ToReturnReusablePackage", ToReturnReusablePackage);
	
	QueryResult = Query.Execute().Unload();
	TotalAmount__       = QueryResult[0].Sum;
	
	Return TotalAmount__;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
