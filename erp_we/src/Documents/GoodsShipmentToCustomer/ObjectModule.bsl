#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the sales conditions in the document.
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
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SalesTermsAndConditions.Organization);
	LineOfBusiness = SalesTermsAndConditions.LineOfBusiness;
	
	OrganizationChanged = ValueIsFilled(SalesTermsAndConditions.Organization)
		And SalesTermsAndConditions.Organization <> Organization;
	
	If OrganizationChanged Then
		
		Organization = SalesTermsAndConditions.Organization;
		
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
		
	EndIf;
	
	TheCounterpartyPriorToTheChange = Counterparty;
	
	If Not SalesTermsAndConditions.Standard_
		And ValueIsFilled(SalesTermsAndConditions.Counterparty)
		And SalesTermsAndConditions.Counterparty <> Counterparty Then
			
		Counterparty = SalesTermsAndConditions.Counterparty;
		
	EndIf;
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Partner, Counterparty);
	
	If TheCounterpartyPriorToTheChange <> Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	Contract = Documents.GoodsShipmentToCustomer.GetDefaultContract(ThisObject);
	
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
			IssuiedBy = StructureOfResponsible.EmployeeResponsible;
			IssuiedByJobTitle = StructureOfResponsible.ResponsiblePosition;
		EndIf;
		
	EndIf;
	
	If Not SalesTermsAndConditions.Standard_
		And ValueIsFilled(SalesTermsAndConditions.ContactPerson)
		And Not ValueIsFilled(ContactPerson) Then
		
		ContactPerson = SalesTermsAndConditions.ContactPerson;
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
	LocalConversionRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		Currency,
		ComplCurrency,
		CurrentSessionDate());
	
EndProcedure

// Fills in the sales conditions by default.
//
Procedure FillInDefaultSalesConditions() Export
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	If ValueIsFilled(Partner)
		Or Not ToUseTermsOfSales Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("SelectedAgreement",   Terms);
		FilterParameters.Insert("EmptyDocumentLink", Documents.GoodsShipmentToCustomer.EmptyRef());
		FilterParameters.Insert("ConsiderWarehouseGroups", True);
		FilterParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
		FilterParameters.Insert("ShipmentWithDeferredTransferOfTitle25", True);
		FilterParameters.Insert("BusinessTransactions",
			PredefinedValue("Enum.BusinessTransactions.SaleToCustomer"));
		
		DefaultSalesTerms =
			SalesServer.GetDefaultSalesTerms(
				Partner,
				FilterParameters,
				True);
		
		TheCounterpartyPriorToTheChange = Counterparty;
		
		If DefaultSalesTerms <> Undefined Then
			
			If Not ToUseTermsOfSales
				Or (Terms <> DefaultSalesTerms.Terms
					And ValueIsFilled(DefaultSalesTerms.Terms)) Then
				
				Terms = DefaultSalesTerms.Terms;
				FillIn_TermsOfSales(DefaultSalesTerms);
				TheCounterpartyPriorToTheChange = Counterparty;
				
				If Not Patch Then
					FillParameters = Documents.GoodsShipmentToCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
					VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
				EndIf;
				
				If ToUseTermsOfSales Then
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
		
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount,
			?(TheCounterpartyPriorToTheChange = Counterparty, CounterpartyBankAccount, Undefined));
		
	EndIf;
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25()  Then
		
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
		
	EndIf;
	
	PartnersAndCounterparties.FillInDefaultPartnerContactPerson(Partner, ContactPerson);
	
EndProcedure

// Fills in the terms of sales by agreement in the shipment of goods to the customer.
//
Procedure FillInTermsOfSalesUnderAgreement() Export
	
	SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
	FillIn_TermsOfSales(SalesTermsAndConditions);
	
	If Not Patch Then
		FillParameters = Documents.GoodsShipmentToCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	FillInPricesBySalesConditions();
	
	If Not GetFunctionalOption("UseDeliveryManagement")
		And Not GoodsDeliveryClientServer.UsedDelivery25() Then
		
		DeliveryAddress = PrintFormGeneration.GetAddressFromContactInformation(Partner);
		
	EndIf;
	
EndProcedure

// Generates temporary tables with document data.
//
// Returns:
//	TempTablesManager - temporary table manager.
//
Function TemporaryDocumentDataTables() Export
	
	Query = New Query;
	QueryText = 
	"SELECT
	|	&Date        AS Date,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	VALUE(Catalog.TermsOfPurchaseFromVendors.EmptyRef) AS Terms,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|	VALUE(Catalog.SalesOpportunitiesToCustomer.EmptyRef) AS SalesOpportunity,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType
	|INTO DocumentDataTable
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	TableOfGoods.LineNumber    AS LineNumber,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.SalesOrder   AS OrderDocument,
	|	TableOfGoods.Products   AS Products,
	|	TableOfGoods.Characteristic AS Characteristic,
	|	TableOfGoods.Purpose     AS Purpose,
	|	TableOfGoods.Package       AS Package,
	|	TableOfGoods.Series          AS Series,
	|	TableOfGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
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
	|	TableTypesOfStocks_.SalesOrder     AS SalesOrder,
	|	TableTypesOfStocks_.InventoryOwnerAttribute       AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Count       AS Count,
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
	|	TableTypesOfStocks_.SalesOrder     AS SalesOrder,
	|	TableTypesOfStocks_.Count       AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.CCDNumber         AS CCDNumber,
	|	TableTypesOfStocks_.Price             AS Price,
	|	TableTypesOfStocks_.SalesOrder     AS OrderDocument,
	|	TableTypesOfStocks_.Sum            AS CommissionAmount,
	|	&InventoryOwnerAttributesAreSpecifiedManually          AS InventoryOwnerAttributesAreSpecifiedManually
	|INTO TableTypesOfStocks_
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|INDEX BY
	|	ItemsLocationAttributes
	|";
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager;
	
	TableOfGoods = ?(AdditionalProperties.Property("TablesOfFillingOfTypesOfStocksAtExchange")
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange <> Undefined
							And AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Property("Goods"),
						AdditionalProperties.TablesOfFillingOfTypesOfStocksAtExchange.Goods,
						Goods);
	
	Query.SetParameter("TableOfGoods",        TableOfGoods);
	Query.SetParameter("TableTypesOfStocks_",    InventoryKinds);
	Query.SetParameter("Date",                  Date);
	Query.SetParameter("Organization",           Organization);
	Query.SetParameter("Department", Department);
	Query.SetParameter("BusinessOperation", BusinessOperation);
	Query.SetParameter("InventoryOwnerAttributesAreSpecifiedManually", InventoryOwnerAttributesAreSpecifiedManually);
	Query.SetParameter("Manager", Manager);
	
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
//	DocumentObject - DocumentObject.GoodsShipmentToCustomer - the document for which parameters are initialized.
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
//	DocumentTables - See Documents.GoodsShipmentToCustomer.CollectionOfTabularPartsOfGoods.
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
	
	QuantityVerificationParameters = New Structure("Goods");
	
	ProductsServer.CheckQuantityFilling(
		ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters["Goods"]);
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentToCustomer);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	ProductsServer.CheckSeriesCompletion(ThisObject, SeriesSpecificationParameters, Cancel, NotCheckedAttributeArray);
	
	For CurIndex__ = 0 To Goods.Count() - 1 Do
		
		LineProducts_ = Goods[CurIndex__]; // LineOfATabularSection
		
		If ShipmentByOrders
			And Not ValueIsFilled(SalesOrder)
			And Not ValueIsFilled(LineProducts_.SalesOrder) Then
			
			ErrorText = NStr("vi = 'Chưa điền trường ""Lệnh"" tại dòng %LineNumber% của danh sách ""Hàng hóa""';
							|ru = 'Не заполнено поле ""Распоряжение"" в строке %LineNumber% списка ""Товары""';
							|en = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list'; fa = 'The ""Reference"" field is not filled in the %LineNumber% line of the ""Goods"" list';
							|it = 'Campo ""Disposizione"" non compilato nella riga %LineNumber% dell''elenco ""Articoli""';
							|pl = 'Pole ""Zamówienie"" w wierszu %LineNumber% listy ""Towary""';
							|tr = '""Ürünler"" listesinin %LineNumber% satırında ""Emir"" alanı doldurulmamış'");
			ErrorText =  StrReplace(ErrorText, "%LineNumber%", LineProducts_.LineNumber);
			ErrorField  = CommonClientServer.PathToTabularSection("Goods",
																			LineProducts_.LineNumber,
																			"SalesOrder");
			
			Common.MessageToUser(ErrorText, ThisObject, ErrorField, Undefined, Cancel);
			
		EndIf;
		
	EndDo;
	
	If Not Partner.IsEmpty()
		And Organization <> Catalogs.Companies.ManagementCompany
		And GoodsDeliveryClientServer.UsedDelivery() Then
		
		DeliveryVerificationSettings = DocumentDeliveryVerificationSettings();
		GoodsDelivery.CheckCompletionOfDeliveryDetails(DeliveryVerificationSettings, NotCheckedAttributeArray, Cancel);
		
	Else
		
		NotCheckedAttributeArray.Add("DeliveryAddress");
		NotCheckedAttributeArray.Add("DeliveryAddressOfCarrier");
		NotCheckedAttributeArray.Add("DeliveryMethod");
		NotCheckedAttributeArray.Add("CarrierPartner");
		NotCheckedAttributeArray.Add("SpecialTransportationConditionsDescription");
		
	EndIf;
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		CheckedAttributes.Add("Department");
	EndIf;
	
	DocumentCorrection.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If Not Cancel
		And TMCommonUse.CheckObjectDetails(ThisObject, CheckedAttributes) Then
		
		Cancel = True;
		
	EndIf;
	
	If Not ShipmentByOrders
		And Not UserRightsCached.CreateCustomerInvoicesWithoutReferenceToOrder() Then
		ErrorText = NStr("vi = 'Không có quyền tạo chứng từ giao hàng cho khách mà không có lệnh';
						|ru = 'Нет прав на создание отгрузки товаров клиенту без распоряжения';
						|en = 'Insufficient rights to create goods shipment to customer without a reference'; fa = 'Insufficient rights to create goods shipment to customer without a reference';
						|it = 'Insufficient rights to create goods shipment to customer without a reference';
						|pl = 'Insufficient rights to create goods shipment to customer without a reference';
						|tr = 'Müşteriye sipariş olmaksızın ürün sevkiyatı yapma izniniz yoktur'");
		Common.MessageToUser(ErrorText, Ref, , , Cancel);
	EndIf;
	
	SalesServer.CheckCorrectnessOfSalesDocument(ThisObject, Cancel);
	SalesServer.CheckShipmentBan(Partner, Cancel);
	
	CostsServer.CheckUseOfBatchAccounting22(ThisObject, Date, Cancel);
	
	GoodsShipmentToCustomerLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeDocumentBeforeFillingItOut();
	
	ParametersStructure = New Structure("HeaderAttributes, OriginWarehouse, FillByWarehouseDocument, DesignParameters, ArrayOfBases");
	ParametersStructure.HeaderAttributes = New Structure();
	
	FilledInBasedOnDocument = False;
	FillInDataType          = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") And FillingData.Property("DiscrepancyCertificate") Then
		
		FillInDocumentBasedOnDiscrepancyReport(FillingData);
		FilledInBasedOnDocument = True;
	
	ElsIf FillInDataType = Type("Structure") Then
		
		// Filling out the list of orders from the form.
		If FillingData.Property("DocumentBasis") Then
			
			// If a warehouse has been transferred, it is necessary to fill in the goods only for the specified warehouse.
			FillingData.Property("OriginWarehouse", ParametersStructure.OriginWarehouse);
			FillingData.Property("HeaderAttributes", ParametersStructure.HeaderAttributes);
			FillingData.Property("FillByWarehouseDocument", ParametersStructure.FillByWarehouseDocument);
			FillingData.Property("DesignParameters", ParametersStructure.DesignParameters);
			
			DocBasis = FillingData.DocumentBasis;
			If TypeOf(DocBasis) = Type("Array") And ValueIsFilled(DocBasis) Then
				ParametersStructure.ArrayOfBases = DocBasis;
				DocBasis = FillingData.DocumentBasis[0];
			EndIf;
				
			BasisType = TypeOf(DocBasis);
			If BasisType = Type("DocumentRef.GoodsShipmentToCustomer") Then
				DocumentCorrection.FillInCorrection(ThisObject, DocBasis);
			ElsIf BasisType = Type("DocumentRef.SalesOrder") Then
				FillInDocumentOnOrders(DocBasis, ParametersStructure);
			Else
				FillInDocumentOnOrders(FillingData.DocumentBasis, ParametersStructure);
				FilledInBasedOnDocument = True;
			EndIf;
			
		Else
			FillInSelectionDocument(FillingData);
		EndIf;

	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then

		FillInDocumentOnOrders(FillingData, ParametersStructure);
		FilledInBasedOnDocument = True;
		
	ElsIf FillInDataType = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		FillInDocumentOnBasisOfSaleTransaction(FillingData);
		
	ElsIf FillInDataType = Type("CatalogRef.TermsOfSale") Then
		
		FillInDocumentOnBasisOfIndividualAgreementWithClient(FillingData);
	
	ElsIf TypeOf(FillingData) = Type("DocumentRef." + Metadata().Name) Then
		
		DocumentCorrection.FillInCorrection(ThisObject, FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.VendorInvoice") Then
		
		FillInDocumentBasedOnPurchaseOfGoodsServices(FillingData);
		FilledInBasedOnDocument = True;

	ElsIf FillInDataType = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		
		FillInDocumentBasedOnReturnOfGoodsFromClient(FillingData);
		FilledInBasedOnDocument = True;

	EndIf;
	
	If Not FilledInBasedOnDocument Then
		
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		If Not ValueIsFilled(SalesOrder) And Not ToUseTermsOfSales Then
			
			FillInDefaultSalesConditions();
			
		EndIf;
		
	EndIf;
	
	FillOutBankAccounts();
	
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	ResponsiblePersonsServer.FillInManager_(ThisObject, False);
	If Not ValueIsFilled(Manager) Then
		Manager = Users.CurrentUser();
	EndIf;
	
	GoodsShipmentToCustomerLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentCorrection.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	DocumentAmount = GetDocumentAmount();
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentToCustomer);
	
	RoundingParameters = New Structure("Goods");
	ProductsServer.RoundUpNumberOfUnitItems(ThisObject, WriteMode, RoundingParameters["Goods"]);
	
	ProductsServer.ClearUnusedSeries(ThisObject, SeriesSpecificationParameters);
	
	RegistrationParameters = Documents.GoodsShipmentToCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedBeforeRecording(RegistrationParameters, WriteMode, DeletionMark, Posted);
	
	If ShipmentByOrders
		And ValueIsFilled(SalesOrder) Then
		For Each CurRow In Goods Do
			If Not ValueIsFilled(CurRow.SalesOrder) Then
				CurRow.SalesOrder = SalesOrder;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ShipmentByOrders Then
		OrdersServer.SetKeyInRowsOfTablePart(ThisObject, "Goods");
	EndIf;
	
	DeliveryBeforeWrite(Cancel, WriteMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		
		FillInProductTrackingDataInTabularPartsOfProducts();
		InformationRegisters.SetAccountingDimension.FillInCollection(Goods);
		FillStockTypes(Cancel);
		
	ElsIf WriteMode = DocumentWriteMode.UndoPosting Then
		
		If Not InventoryOwnerAttributesAreSpecifiedManually Then
			InventoryKinds.Clear();
		EndIf;
		
	EndIf;
	
	TMCommonUse.FillInDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	If IsNew()
		And Not ValueIsFilled(Number) Then
		
		SetNewNumber();
		
	EndIf;
	
	GoodsShipmentToCustomerLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
	If ShipmentByOrders Then
		
		If ValueIsFilled(ARAPObject) Then
			ARAPObjectsServer.CheckDeleteCalculationObject(ARAPObject, Cancel, False);
		EndIf;
		
		If ValueIsFilled(ARAPObjectSettings) Then
			ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		EndIf;
		
	Else
		ARAPAccountingServer.BeforeWrite(ThisObject, Cancel, WriteMode);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
	GoodsShipmentToCustomerLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel);
	
	RegistrationParameters = Documents.GoodsShipmentToCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedDuringTransaction(RegistrationParameters);
	
	GoodsShipmentToCustomerLocalization.Posting(ThisObject, Cancel, PostingMode);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	InitializeParametersForFillingInventoryTypesForConducting(ThisObject);
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
	GoodsDelivery.ReflectDeliveryState(Ref, Cancel, True);
	
	RegistrationParameters = Documents.GoodsShipmentToCustomer.ParametersForRegisteringInvoicesIssued(ThisObject);
	VATAccountingERP.UpdateInvoicesIssuedWhenDeletingTransaction(RegistrationParameters);
	
	GoodsShipmentToCustomerLocalization.UndoPosting(ThisObject, Cancel);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	DocumentCorrection.OnCopy(ThisObject, CopiedObject);
	
	ShipmentByOrders                     = False;
	SalesOrder                          = Undefined;
	InventoryOwnerAttributesAreSpecifiedManually             = False;
	ToUseTermsOfSales      = GetFunctionalOption("ToUseTermsOfSales");
	MaximumDeliveryLineCode  = 0;
	
	If ValueIsFilled(Terms) And ToUseTermsOfSales Then
		
		SalesTermsAndConditions = SalesServer.GetTermsAndConditionsOfSale(Terms, True, True);
		
		If SalesTermsAndConditions.AgreementStatus = Enums.StatusesOfTermsOfSales.Closed Then
			Terms = Undefined;
		EndIf;
		
	EndIf;
	
	For Each CurRow In Goods Do
		
		CurRow.SalesOrder          = Undefined;
		CurRow.RowCode             = 0;
		CurRow.RowID   = "";
		CurRow.Purpose            = Undefined;
		CurRow.DeliveryLineCode = 0;
		
	EndDo;
	
	DefaultAssignment = LinesOfBusinessServer.PushingAssignment(LineOfBusiness);
	InvoicesServer.FillInAssignmentsInTablePart(Goods, DefaultAssignment);
	
	SetOfSeries.Clear();
	InventoryKinds.Clear();
	
	InitializeDocument();
	
	TMCommonUse.ClearDocumentIDs(ThisObject, "Goods,InventoryKinds");
	
	GoodsShipmentToCustomerLocalization.OnCopy(ThisObject, CopiedObject);
	
	Author = Users.CurrentUser();
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInSelectionDocument(Val FillingData)

	If FillingData.Property("HeaderAttributes") Then
		FillPropertyValues(ThisObject, FillingData.HeaderAttributes);
	EndIf;
	
	If FillingData.Property("Partner") Then
		Partner = FillingData.Partner;
		
		ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
		If ToUseTermsOfSales Then
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

Procedure FillInDocumentOnOrders(DocumentBasis, Parameters);
	
	OrderDetails = Parameters.HeaderAttributes;
	
	If Parameters.ArrayOfBases = Undefined Then
		Parameters.ArrayOfBases = CommonClientServer.ValueInArray(DocumentBasis);
	EndIf;
	
	BasisType = TypeOf(DocumentBasis);
	If BasisType = Type("DocumentRef.SalesOrder") Then
		
		QueryText = 
		"SELECT
		|	Table.Ref                                AS SalesOrder,
		|	Table.Partner                               AS Partner,
		|	Table.Counterparty                            AS Counterparty,
		|	Table.Contract                               AS Contract,
		|	Table.Organization                           AS Organization,
		|	Table.Terms                            AS Terms,
		|	Table.SalesOpportunity                                AS SalesOpportunity,
		|	Table.Warehouse                                 AS Warehouse,
		|	Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND Table.Warehouse.IsFolder
		|		AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders) AS ItIsForbiddenToSelectWarehouseGroup,
		|	Table.Status                                AS DocumentStatus,
		|	NOT Table.Posted                           AS ThereAreErrorsPosted,
		|	Table.Department                         AS Department,
		|	Table.Currency                                AS Currency,
		|	Table.VATTaxation                    AS VATTaxation,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	Table.PaymentSchedule                          AS PaymentSchedule,
		|	Table.BankAccount                        AS BankAccount,
		|	Table.CashAccount                                 AS CashAccount,
		|	Table.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	Table.Shipper                      AS Shipper,
		|	Table.GoodsRecipient                       AS GoodsRecipient,
		|	Table.ShipperBankAccount        AS ShipperBankAccount,
		|	Table.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN
		|			Table.Warehouse.IsFolder AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|		THEN
		|			VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE
		|			Table.Warehouse
		|	END                                         AS OriginWarehouse,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|			THEN VALUE(Enum.TransportMethods.EmptyRef)
		|		ELSE Table.DeliveryMethod
		|	END AS DeliveryMethod,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|			THEN FALSE
		|		ELSE Table.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
		|	END AS MethodOfDeliveryByCarrier,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN VALUE(Enum.TransportMethods25.EmptyRef)
		|		ELSE Table.DeliveryMethod25
		|	END AS DeliveryMethod25,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN VALUE(Catalog.Partners.EmptyRef)
		|		ELSE Table.CarrierPartner
		|	END AS CarrierPartner,
		|	Table.DeliveryAddress                         AS DeliveryAddress,
		|	Table.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	Table.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
		|	Table.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	CASE
		|		WHEN &UsedDelivery25
		|				AND NOT Table.ThisIsOrderAsInvoice
		|			THEN Table.DeliveryPoint
		|		ELSE VALUE(Catalog.DeliveryPoints.EmptyRef)
		|	END AS DeliveryPoint,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN VALUE(Catalog.DeliveryZones.EmptyRef)
		|		ELSE Table.DeliveryZone
		|	END AS DeliveryZone,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN DATETIME(1, 1, 1)
		|		ELSE Table.DeliveryTimeFrom
		|	END AS DeliveryTimeFrom,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN DATETIME(1, 1, 1)
		|		ELSE Table.DeliveryTimeFrom
		|	END AS DeliveryTimeTo,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN FALSE
		|		ELSE Table.SpecialTransportationConditions
		|	END AS SpecialTransportationConditions,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN """"
		|		ELSE Table.SpecialTransportationConditionsDescription
		|	END AS SpecialTransportationConditionsDescription,
		|	CASE
		|		WHEN NOT &UsedDelivery
		|				OR &UsedDelivery25
		|					AND Table.ThisIsOrderAsInvoice
		|			THEN """"
		|		ELSE Table.AdditionalDeliveryInformation
		|	END AS AdditionalDeliveryInformation,
		|	Table.LineOfBusiness               AS LineOfBusiness,
		|	Table.ContactPerson                        AS ContactPerson,
		|	Table.LoyaltyCard                       AS LoyaltyCard,
		|	Table.FinancialAccountingGroup                AS FinancialAccountingGroup,
		|	TRUE                                        AS ShipmentByOrders,
		|	VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer) AS BusinessOperation,
		|	Table.Director                          AS Director,
		|	Table.ChiefAccountant                      AS ChiefAccountant,
		|	CASE
		|		WHEN Table.Warehouse.IsFolder
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS WarehouseGroupSelected
		|FROM
		|	Document.SalesOrder AS Table
		|WHERE
		|	Table.Ref = &DocumentBasis
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
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query = New Query(QueryText);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		Query.SetParameter("UsedDelivery", GoodsDeliveryClientServer.UsedDelivery());
		Query.SetParameter("UsedDelivery25", GoodsDeliveryClientServer.UsedDelivery25());
		
		QueryResult = Query.ExecuteBatch();
		OrderDetails = QueryResult[QueryResult.UBound()-1].Select();
		OrderDetails.Next();
		
		Documents.SalesOrder.CheckPossibilityOfEnteringBasedOn(
			OrderDetails.SalesOrder,
			OrderDetails.DocumentStatus,
			OrderDetails.ThereAreErrorsPosted);
		
		FillPropertyValues(ThisObject, OrderDetails);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = QueryResult[QueryResult.UBound()].Unload().UnloadColumn("Warehouse");
		EndIf;
		
	ElsIf BasisType = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		QueryText =
		"SELECT
		|	Table.Ref AS SalesOrder,
		|	Table.Partner AS Partner,
		|	Table.Counterparty AS Counterparty,
		|	Table.Contract AS Contract,
		|	Table.Organization AS Organization,
		|	Table.Terms AS Terms,
		|	Table.SalesOpportunity AS SalesOpportunity,
		|	Table.Warehouse AS Warehouse,
		|	Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND Table.Warehouse.IsFolder
		|		AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders) AS ItIsForbiddenToSelectWarehouseGroup,
		|	Table.Department AS Department,
		|	Table.Currency AS Currency,
		|	Table.VATTaxation AS VATTaxation,
		|	UNDEFINED AS PaymentMethod,
		|	UNDEFINED AS PaymentSchedule,
		|	UNDEFINED AS BankAccount,
		|	UNDEFINED AS CashAccount,
		|	Table.CounterpartyBankAccount AS CounterpartyBankAccount,
		|	Table.Shipper AS Shipper,
		|	Table.GoodsRecipient AS GoodsRecipient,
		|	Table.ShipperBankAccount AS ShipperBankAccount,
		|	Table.GoodsRecipientBankAccount AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN Table.Warehouse.IsFolder
		|		AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|			THEN VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE Table.Warehouse
		|	END AS OriginWarehouse,
		|	Table.DeliveryMethod AS DeliveryMethod,
		|	Table.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS
		|		MethodOfDeliveryByCarrier,
		|	Table.CarrierPartner AS CarrierPartner,
		|	Table.DeliveryAddress AS DeliveryAddress,
		|	Table.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
		|	Table.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
		|	Table.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	Table.DeliveryZone AS DeliveryZone,
		|	Table.DeliveryTimeFrom AS DeliveryTimeFrom,
		|	Table.DeliveryTimeTo AS DeliveryTimeTo,
		|	Table.SpecialTransportationConditions AS SpecialTransportationConditions,
		|	Table.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
		|	Table.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
		|	Table.LineOfBusiness AS LineOfBusiness,
		|	Table.ContactPerson AS ContactPerson,
		|	UNDEFINED AS LoyaltyCard,
		|	UNDEFINED AS FinancialAccountingGroup,
		|	TRUE AS ShipmentByOrders,
		|	VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer) AS BusinessOperation,
		|	Table.Director AS Director,
		|	Table.ChiefAccountant AS ChiefAccountant,
		|	CASE
		|		WHEN Table.Warehouse.IsFolder
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS WarehouseGroupSelected
		|FROM
		|	Document.GoodsShipmentToCustomer AS Table
		|WHERE
		|	Table.Ref = &DocumentBasis
		|";
		
		Query = New Query(QueryText);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		
		OrderDetails = Query.Execute().Select();
		OrderDetails.Next();
		
		FillPropertyValues(ThisObject, OrderDetails);
		
	ElsIf BasisType = Type("DocumentRef.RequestForReturnOfGoodsFromCustomer") Then
	
		QueryText = 
		"SELECT
		|	Table.Ref                                AS SalesOrder,
		|	Table.Partner                               AS Partner,
		|	Table.Counterparty                            AS Counterparty,
		|	Table.Contract                               AS Contract,
		|	Table.Organization                           AS Organization,
		|	Table.Terms                            AS Terms,
		|	Table.SalesOpportunity                                AS SalesOpportunity,
		|	Table.Warehouse                                 AS Warehouse,
		|	Table.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
		|		AND Table.Warehouse.IsFolder
		|		AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders) AS ItIsForbiddenToSelectWarehouseGroup,
		|	Table.Department                         AS Department,
		|	Table.Currency                                AS Currency,
		|	Table.VATTaxation                    AS VATTaxation,
		|	Table.PaymentMethod                           AS PaymentMethod,
		|	Table.PaymentSchedule                          AS PaymentSchedule,
		|	Table.BankAccount                        AS BankAccount,
		|	Table.CashAccount                                 AS CashAccount,
		|	Table.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	Table.Shipper                      AS Shipper,
		|	Table.GoodsRecipient                       AS GoodsRecipient,
		|	Table.ShipperBankAccount        AS ShipperBankAccount,
		|	Table.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	CASE
		|		WHEN
		|			Table.Warehouse.IsFolder AND Table.Warehouse.SelectGroup = VALUE(Enum.SelectWarehouseGroup.AllowInOrders)
		|		THEN
		|			VALUE(Catalog.Warehouses.EmptyRef)
		|		ELSE
		|			Table.Warehouse
		|	END                                         AS OriginWarehouse,
		|	Table.DeliveryMethod                        AS DeliveryMethod,
		|	Table.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier) AS MethodOfDeliveryByCarrier,
		|	Table.CarrierPartner                     AS CarrierPartner,
		|	Table.DeliveryAddress                         AS DeliveryAddress,
		|	Table.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	Table.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
		|	Table.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	Table.DeliveryZone                          AS DeliveryZone,
		|	Table.DeliveryTimeFrom                        AS DeliveryTimeFrom,
		|	Table.DeliveryTimeTo                       AS DeliveryTimeTo,
		|	Table.SpecialTransportationConditions                AS SpecialTransportationConditions,
		|	Table.SpecialTransportationConditionsDescription        AS SpecialTransportationConditionsDescription,
		|	Table.AdditionalDeliveryInformation    AS AdditionalDeliveryInformation,
		|	Table.LineOfBusiness               AS LineOfBusiness,
		|	Table.ContactPerson                        AS ContactPerson,
		|	Table.LoyaltyCard                       AS LoyaltyCard,
		|	Table.FinancialAccountingGroup                AS FinancialAccountingGroup,
		|	TRUE                                        AS ShipmentByOrders,
		|	VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer) AS BusinessOperation,
		|	Table.Director                          AS Director,
		|	Table.ChiefAccountant                      AS ChiefAccountant
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS Table
		|WHERE
		|	Table.Ref = &DocumentBasis
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
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query = New Query(QueryText);
		Query.SetParameter("DocumentBasis", DocumentBasis);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		
		QueryAttributes = Query.ExecuteBatch();
		OrderDetails = QueryAttributes[QueryAttributes.UBound()-1].Select();
		OrderDetails.Next();
		
		FillPropertyValues(ThisObject, OrderDetails);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = QueryResult[QueryAttributes.UBound()].Unload().UnloadColumn("Warehouse");
		EndIf;
		
	ElsIf BasisType = Type("Array") Then
	
		OrderDetails.Insert("ShipmentByOrders", True);
		FillPropertyValues(ThisObject, OrderDetails);

		Currency = OrderDetails.ARAPCurrency;
		BusinessOperation = Enums.BusinessTransactions.GoodsShipmentToCustomer;
		
		QueryText =
		"SELECT
		|	GoodsTable.ReferenceOrder AS ReferenceOrder
		|FROM
		|	Document.GoodsReceiptFromCustomer.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref IN (&ArrayOfBases)
		|	AND GoodsTable.Ref.ReduceShipmentByReference
		|	AND GoodsTable.RowCode <> 0
		|	AND NOT (GoodsTable.ReferenceOrder REFS Document.SaleAdjustment
		|		AND GoodsTable.ReferenceOrder <> VALUE(Document.SaleAdjustment.EmptyRef))
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
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		Query = New Query(QueryText);
		Query.SetParameter("ArrayOfBases", Parameters.ArrayOfBases);
		Query.SetParameter("DocumentsArray", DocumentBasis);
		Query.SetParameter("CheckDate", CurrentSessionDate());
		
		QueryResult = Query.ExecuteBatch();
		OrdersReceipts = QueryResult[QueryResult.UBound() - 1].Unload().UnloadColumn("ReferenceOrder");
		
		CommonClientServer.SupplementArray(Parameters.ArrayOfBases, OrdersReceipts);
		
		If OrderDetails.ItIsForbiddenToSelectWarehouseGroup Then
			WarehouseArray = QueryResult[QueryResult.UBound()].Unload().UnloadColumn("Warehouse");
		EndIf;
		
	EndIf;
	
	If GetFunctionalOption("ToUseTermsOfSales")
		And ValueIsFilled(OrderDetails.Terms) Then
	
		DetailsOfAgreement = Common.ObjectAttributesValues(OrderDetails.Terms,
			"SaleWithDeferredTransferOfTitleIsAllowed, ContractsAreUsed, Presentation");
		
		If Not DetailsOfAgreement.SaleWithDeferredTransferOfTitleIsAllowed Then
			
			ExceptionText = NStr("vi = 'Theo thỏa thuận ""%1"" không thể giao hàng mà không chuyển giao quyền sở hữu.';
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
			
			ExceptionText = NStr("vi = 'Trong thỏa thuận ""%1"" không sử dụng hợp đồng với đối tác. Việc sử dụng hợp đồng là bắt buộc để giao hàng mà chưa chuyển giao quyền sở hữu.';
								|ru = 'В соглашении ""%1"" не используются договоры с контрагентами. Использование договоров является обязательным для отгрузки товаров без перехода права собственности.';
								|en = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.'; fa = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
								|it = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
								|pl = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
								|tr = '""%1"" anlaşması, karşı taraflarla yapılan sözleşmeleri kullanmamaktadır. Mülkiyet hakkı devri olmadan yapılan ürün sevkiyatlarında sözleşme kullanımı zorunludur.'");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				ExceptionText,
				DetailsOfAgreement.Presentation);
			
			Raise ExceptionText;
			
		EndIf;
		
	EndIf;
	
	DocumentFillingParameters = Documents.GoodsShipmentToCustomer.DocumentFillingParameters();
	If Parameters.FillByWarehouseDocument <> Undefined Then
		DocumentFillingParameters.FillByWarehouseDocument = Parameters.FillByWarehouseDocument;
	EndIf;
	
	Documents.GoodsShipmentToCustomer.InitializeFillingParameters(DocumentFillingParameters,
		OrderDetails, Parameters.ArrayOfBases);
	
	If ValueIsFilled(Parameters.OriginWarehouse) Then
		Warehouse = Parameters.OriginWarehouse;
		DocumentFillingParameters.Warehouse = Warehouse;
	ElsIf OrderDetails.ItIsForbiddenToSelectWarehouseGroup And WarehouseArray.Count() > 0 Then 
		Warehouse = WarehouseArray[0];
		DocumentFillingParameters.Warehouse = Warehouse;
	EndIf;
	
	DesignParameters = Parameters.DesignParameters;
	If DesignParameters <> Undefined 
		 And DesignParameters.Property("CheckWarehouses") Then
		DocumentFillingParameters.Insert("CheckWarehouses", DesignParameters.CheckWarehouses);
	EndIf;
	
	DocumentFillingParameters.DisplayMessage_1 = True;
	
	InvoiceTable = Documents.GoodsShipmentToCustomer.TableDataAndDocument(Ref);
	
	Documents.GoodsShipmentToCustomer.FillInByOrdersOrders(
		InvoiceTable,
		Undefined,
		DocumentFillingParameters,
		PackageBarcodes);
	
	Goods.Load(InvoiceTable);

	InvoicesServer.DeleteEmptyLines(Goods, "Count");

	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(
		ThisObject,
		Documents.GoodsShipmentToCustomer);
		
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
	StructureBase = Documents.GoodsShipmentToCustomer.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
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
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	If ToUseTermsOfSales Then
		
		If ValueIsFilled(Terms) Then
			FillInTermsOfSalesUnderAgreement();
		Else
			FillInDefaultSalesConditions();
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure FillInDocumentOnBasisOfIndividualAgreementWithClient(Val DocumentBasis)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	CustomerTermsOfSales.Ref          AS Terms,
	|	VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer) AS BusinessOperation,
	|	CustomerTermsOfSales.Partner         AS Partner,
	|	CustomerTermsOfSales.ContactPerson  AS ContactPerson,
	|	CustomerTermsOfSales.Status          AS DocumentStatus,
	|	CustomerTermsOfSales.SaleWithDeferredTransferOfTitleIsAllowed AS SaleWithDeferredTransferOfTitleIsAllowed,
	|	CASE
	|		WHEN CustomerTermsOfSales.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|			THEN FALSE
	|		ELSE TRUE
	|	END                               AS ThereAreErrorsStatus,
	|	CustomerTermsOfSales.Standard_         AS ThereAreErrorsTypical,
	|	CustomerTermsOfSales.ContractsAreUsed AS ContractsAreUsed,
	|	PRESENTATION(CustomerTermsOfSales.Ref) AS PresentationOfAgreement
	|FROM
	|	Catalog.TermsOfSale  AS CustomerTermsOfSales
	|WHERE
	|	CustomerTermsOfSales.Ref = &DocumentBasis";
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	Selection.Next();
	
	If Not Selection.SaleWithDeferredTransferOfTitleIsAllowed Then

		ErrorText = NStr("vi = 'Không thể lập chứng từ ""%1"" mà chưa chuyển giao quyền sở hữu trên cơ sở %2. Để lập chứng từ giao hàng, hãy sử dụng ""%3""';
						|ru = 'Невозможно оформить документ ""%1"" без перехода права собственности на основании %2. Для оформления реализации товаров воспользуйтесь документом ""%3""';
						|en = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document'; fa = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|it = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|pl = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|tr = '%2 dahilinde mülkiyet hakkı devri olmadan ""%1"" belgesi düzenlenemez. Ürünlerin satışını düzenlemek için ""%3"" belgesini kullanın.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
											Metadata.Documents.GoodsShipmentToCustomer.Synonym,
											DocumentBasis,
											Metadata.Documents.CustomerInvoice.Synonym);
		
		Raise ErrorText;

	EndIf;
	
	If Not Selection.ContractsAreUsed Then
		
		ExceptionText = NStr("vi = 'Trong thỏa thuận ""%1"" không sử dụng hợp đồng với đối tác. Việc sử dụng hợp đồng là bắt buộc để giao hàng mà chuyển chuyển giao quyền sở hữu.';
							|ru = 'В соглашении ""%1"" не используются договоры с контрагентами. Использование договоров является обязательным для отгрузки товаров без перехода права собственности.';
							|en = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.'; fa = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|it = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|pl = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|tr = '""%1"" anlaşması, karşı taraflarla yapılan sözleşmeleri kullanmamaktadır. Mülkiyet hakkı devri olmadan yapılan ürün sevkiyatlarında sözleşme kullanımı zorunludur.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionText,
			Selection.PresentationOfAgreement);
		
		Raise ExceptionText;
		
	EndIf;
	
	SalesServer.CheckPossibilityOfEnteringOnBasisOfAgreement("GoodsShipmentToCustomer",
		Selection.BusinessOperation);
	
	ArrayOfValidStatuses = New Array();
	ArrayOfValidStatuses.Add(Enums.StatusesOfTermsOfSales.Valid);
	
	TMCommonUse.CheckPossibilityOfEnteringOnBasisOfAgreement(Selection.ThereAreErrorsTypical);
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsStatus = Selection.ThereAreErrorsStatus;
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(Selection.Terms, CheckParameters);

	FillPropertyValues(ThisObject, Selection);
	
	FillInTermsOfSalesUnderAgreement();
	
EndProcedure

Procedure FillInDocumentBasedOnPurchaseOfGoodsServices(Val DocumentBasis)
	
	Query = New Query;
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.Text =
	"SELECT
	|	VendorInvoice.Ref                  AS DocumentBasis,
	|	VendorInvoice.Ref                  AS Ref,
	|	VendorInvoice.Organization             AS Organization,
	|	VendorInvoice.Warehouse                   AS Warehouse,
	|	VendorInvoice.Currency                  AS Currency,
	|	VendorInvoice.SalesOpportunity                  AS SalesOpportunity,
	|	VendorInvoice.LineOfBusiness AS LineOfBusiness,
	|	NOT VendorInvoice.Posted             AS ThereAreErrorsPosted
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
	|	GoodsReceipts.Package            AS Package,
	|	GoodsReceipts.Series               AS Series,
	|	GoodsReceipts.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsReceipts.Count          AS Count,
	|	GoodsReceipts.NumberOfPackages  AS NumberOfPackages
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsReceipts
	|WHERE
	|	GoodsReceipts.Ref = &DocumentBasis
	|	AND GoodsReceipts.Products.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	SeriesReceipts.Warehouse          AS Warehouse,
	|	SeriesReceipts.Products   AS Products,
	|	SeriesReceipts.Characteristic AS Characteristic,
	|	SeriesReceipts.Purpose     AS Purpose,
	|	SeriesReceipts.Series          AS Series,
	|	SeriesReceipts.Count     AS Count
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SeriesReceipts
	|WHERE
	|	SeriesReceipts.Ref = &DocumentBasis
	|	AND SeriesReceipts.Products.ItemsType IN
	|	(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	SetPrivilegedMode(True);
	QueryBatch = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	HeaderSelection = QueryBatch[0].Select();
	HeaderSelection.Next();
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = HeaderSelection.ThereAreErrorsPosted;
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(HeaderSelection.Ref, CheckParameters);
	
	FillPropertyValues(ThisObject, HeaderSelection);
	
	Goods.Load(QueryBatch[1].Unload());
	SetOfSeries.Load(QueryBatch[2].Unload());
	
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
	
	SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject, Documents.GoodsShipmentToCustomer);
	ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
	
EndProcedure

Procedure FillInDocumentBasedOnReturnOfGoodsFromClient(Val DocumentBasis)

	Query = New Query;
	Query.Text =
	"SELECT
	|	ReturnOfGoodsFromCustomer.Ref               AS Ref,
	|	ReturnOfGoodsFromCustomer.Organization          AS Organization,
	|	ReturnOfGoodsFromCustomer.Partner              AS Partner,
	|	ReturnOfGoodsFromCustomer.Counterparty           AS Counterparty,
	|	ReturnOfGoodsFromCustomer.SalesOpportunity               AS SalesOpportunity,
	|	ReturnOfGoodsFromCustomer.Terms           AS Terms,
	|	ReturnOfGoodsFromCustomer.Currency               AS Currency,
	|	ReturnOfGoodsFromCustomer.DocumentAmount       AS DocumentAmount,
	|	ReturnOfGoodsFromCustomer.DocumentAmount       AS AmountARAP,
	|	ReturnOfGoodsFromCustomer.Warehouse                AS Warehouse,
	|	ReturnOfGoodsFromCustomer.Contract              AS Contract,
	|	ReturnOfGoodsFromCustomer.ReusablePackageReturn AS ToReturnReusablePackage,
	|	ReturnOfGoodsFromCustomer.DepositForPackageIsRequired AS PackageDepositIsRequired,
	|	ReturnOfGoodsFromCustomer.LineOfBusiness AS LineOfBusiness,
	|	VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer) AS BusinessOperation,
	|	NOT ReturnOfGoodsFromCustomer.Posted          AS ThereAreErrorsPosted,
	|	CASE
	|		WHEN &ToUseTermsOfSales
	|			THEN ReturnOfGoodsFromCustomer.Terms.SaleWithDeferredTransferOfTitleIsAllowed
	|		ELSE TRUE
	|	END AS SaleWithDeferredTransferOfTitleIsAllowed,
	|	CASE
	|		WHEN &ToUseTermsOfSales
	|			THEN ReturnOfGoodsFromCustomer.Terms.ContractsAreUsed
	|		ELSE TRUE
	|	END AS ContractsAreUsedInAgreement,
	|	PRESENTATION(ReturnOfGoodsFromCustomer.Terms) AS PresentationOfAgreement,
	|
	|	ReturnOfGoodsFromCustomer.Goods.(
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		Package                 AS Package,
	|		Purpose               AS Purpose,
	|		NumberOfPackages       AS NumberOfPackages,
	|		Count               AS Count,
	|		CASE
	|			WHEN Count <> 0
	|				THEN AmountIncludingVAT / Count
	|				ELSE 0
	|		END AS Price,
	|		AmountIncludingVAT                AS Sum,
	|		Ref.Warehouse             AS Warehouse
	|	) AS Goods,
	|
	|	ReturnOfGoodsFromCustomer.SetOfSeries.(
	|		Products             AS Products,
	|		Characteristic           AS Characteristic,
	|		Purpose               AS Purpose,
	|		Series                    AS Series,
	|		Count               AS Count
	|	) AS SetOfSeries
	|
	|FROM
	|	Document.ReturnOfGoodsFromCustomer AS ReturnOfGoodsFromCustomer
	|WHERE
	|	ReturnOfGoodsFromCustomer.Ref = &DocumentBasis";
	
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("ToUseTermsOfSales", ToUseTermsOfSales);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	If Not Selection.SaleWithDeferredTransferOfTitleIsAllowed Then
		
		ErrorText = NStr("vi = 'Không thể lập chứng từ ""%1"" mà chưa chuyển giao quyền sở hữu trên cơ sở %2. Để lập chứng từ giao hàng, hãy sử dụng ""%3""';
						|ru = 'Невозможно оформить документ ""%1"" без перехода права собственности на основании %2. Для оформления реализации товаров воспользуйтесь документом ""%3""';
						|en = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document'; fa = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|it = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|pl = 'Cannot issue the ""%1"" document without transfer of title to goods based on %2. To register the sale, use the ""%3"" document';
						|tr = '%2 dahilinde mülkiyet hakkı devri olmadan ""%1"" belgesi düzenlenemez. Ürünlerin satışını düzenlemek için ""%3"" belgesini kullanın.'");
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorText,
											Metadata.Documents.GoodsShipmentToCustomer.Synonym,
											DocumentBasis,
											Metadata.Documents.CustomerInvoice.Synonym);
		
		Raise ErrorText;
		
	EndIf;
	
	If Not Selection.ContractsAreUsedInAgreement Then
		
		ExceptionText = NStr("vi = 'Trong thỏa thuận ""%1"" không sử dụng hợp đồng với đối tác. Việc sử dụng hợp đồng là bắt buộc để giao hàng mà chưa chuyển giao quyền sở hữu.';
							|ru = 'В соглашении ""%1"" не используются договоры с контрагентами. Использование договоров является обязательным для отгрузки товаров без перехода права собственности.';
							|en = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.'; fa = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|it = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|pl = 'Contracts with counterparties are not used in the ""%1"" agreement. Using contracts is required for goods shipment without transfer of title to goods.';
							|tr = '""%1"" anlaşması, karşı taraflarla yapılan sözleşmeleri kullanmamaktadır. Mülkiyet hakkı devri olmadan yapılan ürün sevkiyatlarında sözleşme kullanımı zorunludur.'");
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			ExceptionText,
			Selection.PresentationOfAgreement);
		
		Raise ExceptionText;
		
	EndIf;
	
	CheckParameters = TMCommonUse.ParametersForCheckingPossibilityOfEnteringBasedOn();
	CheckParameters.ThereAreErrorsPosted = Selection.ThereAreErrorsPosted;
	TMCommonUse.CheckPossibilityOfInputBasedOnParameters(Selection.Ref, CheckParameters);

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

Procedure FillInDocumentBasedOnDiscrepancyReport(FillingData)

	DiscrepancyCertificate = FillingData.DiscrepancyCertificate;
	BasisOfAct = FillingData.BasisOfAct;
	EnterCorrection = FillingData.Patch;
	AdditionalDelivery = FillingData.AdditionalDelivery;
	
	QueryText = "";
	
	// The correction can only be entered in the certificate of discrepancies with the Shipment of goods to the customer basis
	If EnterCorrection Then

		DocumentCorrection.FillInCorrection(ThisObject, BasisOfAct);
	
	ElsIf AdditionalDelivery Then
		
		QueryText =
		"SELECT ALLOWED
		|	ShippingGoods.Ref.Partner                               AS Partner,
		|	ShippingGoods.Ref.Counterparty                            AS Counterparty,
		|	ShippingGoods.Ref.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	ShippingGoods.Ref.Terms                            AS Terms,
		|	ShippingGoods.Ref.BusinessOperation                 AS BusinessOperation,
		|	ShippingGoods.Ref.Organization                           AS Organization,
		|	ShippingGoods.Ref.CompanyBankAccount             AS CompanyBankAccount,
		|	ShippingGoods.Ref.Contract                               AS Contract,
		|	ShippingGoods.Ref.Warehouse                                 AS Warehouse,
		|	ShippingGoods.Ref.Currency                                AS Currency,
		|	ShippingGoods.Ref.DeliveryMethod                        AS DeliveryMethod,
		|	ShippingGoods.Ref.CarrierPartner                     AS CarrierPartner,
		|	ShippingGoods.Ref.DeliveryAddress                         AS DeliveryAddress,
		|	ShippingGoods.Ref.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	ShippingGoods.Ref.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
		|	ShippingGoods.Ref.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	ShippingGoods.Ref.DeliveryZone                          AS DeliveryZone,
		|	ShippingGoods.Ref.DeliveryTimeFrom                        AS DeliveryTimeFrom,
		|	ShippingGoods.Ref.DeliveryTimeTo                       AS DeliveryTimeTo,
		|	ShippingGoods.Ref.SpecialTransportationConditions                AS SpecialTransportationConditions,
		|	ShippingGoods.Ref.SpecialTransportationConditionsDescription        AS SpecialTransportationConditionsDescription,
		|	ShippingGoods.Ref.SalesOpportunity                                AS SalesOpportunity,
		|	ShippingGoods.Ref.ContactPerson                        AS ContactPerson,
		|	ShippingGoods.Ref.Department                         AS Department,
		|	ShippingGoods.Ref.LineOfBusiness               AS LineOfBusiness,
		|	ShippingGoods.Ref.SubsequentDeliveryByTransfer                  AS SubsequentDeliveryByTransfer,
		|	ShippingGoods.Ref.DocumentAmount                        AS DocumentAmount,
		|	ShippingGoods.Ref.Shipper                      AS Shipper,
		|	ShippingGoods.Ref.ShipperBankAccount        AS ShipperBankAccount,
		|	ShippingGoods.Ref.GoodsRecipient                       AS GoodsRecipient,
		|	ShippingGoods.Ref.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	ShippingGoods.Ref.Director                          AS Director,
		|	ShippingGoods.Ref.ChiefAccountant                      AS ChiefAccountant,
		|	ShippingGoods.Ref.IssuiedBy                              AS IssuiedBy,
		|	ShippingGoods.Ref.IssuiedByJobTitle                     AS IssuiedByJobTitle,
		|	ShippingGoods.Ref.LocalConversionRatio              AS LocalConversionRatio,
		|	ShippingGoods.Ref.LetterOfAuthorityIssuedBy                    AS LetterOfAuthorityIssuedBy,
		|	ShippingGoods.Ref.PowerOfAttorneyDate                      AS PowerOfAttorneyDate,
		|	ShippingGoods.Ref.PowerOfAttorneyPerson                      AS PowerOfAttorneyPerson,
		|	ShippingGoods.Ref.PowerOfAttorneyNumber                     AS PowerOfAttorneyNumber,
		|	ShippingGoods.Ref.DeliveryAddressValue                 AS DeliveryAddressValue,
		|	ShippingGoods.Ref.DeliveryAddressOfCarrierValue      AS DeliveryAddressOfCarrierValue,
		|	ShippingGoods.Ref.VATTaxation                    AS VATTaxation
		|FROM
		|	Document.GoodsShipmentToCustomer.Goods AS ShippingGoods
		|	INNER JOIN  Document.DiscrepancyReportFollowingShipment.Goods AS ActOfItems
		|		ON ShippingGoods.Products = ActOfItems.Products
		|			AND ShippingGoods.Characteristic = ActOfItems.Characteristic
		|			AND ShippingGoods.RowCode = ActOfItems.RowCode
		|			AND (ShippingGoods.SalesOrder = ActOfItems.SalesOrder
		|				OR ShippingGoods.Ref = ActOfItems.SalesOrder
		|				OR ShippingGoods.Ref.CorrectedDocument = ActOfItems.SalesOrder)
		|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
		|		ON ShippingGoods.Ref = DocumentsRegistry.ReversedDocument
		|			AND DocumentsRegistry.Posted
		|			AND NOT DocumentsRegistry.AdditionalRecord
		|WHERE
		|	ActOfItems.Ref = &DiscrepancyCertificate
		|	AND ActOfItems.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice)
		|	AND ActOfItems.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
		|	AND DocumentsRegistry.Ref IS NULL
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsShipmentToCustomer.Partner                               AS Partner,
		|	GoodsShipmentToCustomer.Counterparty                            AS Counterparty,
		|	GoodsShipmentToCustomer.CounterpartyBankAccount             AS CounterpartyBankAccount,
		|	GoodsShipmentToCustomer.Terms                            AS Terms,
		|	GoodsShipmentToCustomer.BusinessOperation                 AS BusinessOperation,
		|	GoodsShipmentToCustomer.Organization                           AS Organization,
		|	GoodsShipmentToCustomer.CompanyBankAccount             AS CompanyBankAccount,
		|	GoodsShipmentToCustomer.Contract                               AS Contract,
		|	GoodsShipmentToCustomer.Warehouse                                 AS Warehouse,
		|	GoodsShipmentToCustomer.Currency                                AS Currency,
		|	GoodsShipmentToCustomer.DeliveryMethod                        AS DeliveryMethod,
		|	GoodsShipmentToCustomer.CarrierPartner                     AS CarrierPartner,
		|	GoodsShipmentToCustomer.DeliveryAddress                         AS DeliveryAddress,
		|	GoodsShipmentToCustomer.DeliveryAddressFieldValues            AS DeliveryAddressFieldValues,
		|	GoodsShipmentToCustomer.DeliveryAddressOfCarrier              AS DeliveryAddressOfCarrier,
		|	GoodsShipmentToCustomer.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
		|	GoodsShipmentToCustomer.DeliveryZone                          AS DeliveryZone,
		|	GoodsShipmentToCustomer.DeliveryTimeFrom                        AS DeliveryTimeFrom,
		|	GoodsShipmentToCustomer.DeliveryTimeTo                       AS DeliveryTimeTo,
		|	GoodsShipmentToCustomer.SpecialTransportationConditions                AS SpecialTransportationConditions,
		|	GoodsShipmentToCustomer.SpecialTransportationConditionsDescription        AS SpecialTransportationConditionsDescription,
		|	GoodsShipmentToCustomer.SalesOpportunity                                AS SalesOpportunity,
		|	GoodsShipmentToCustomer.ContactPerson                        AS ContactPerson,
		|	GoodsShipmentToCustomer.Department                         AS Department,
		|	GoodsShipmentToCustomer.LineOfBusiness               AS LineOfBusiness,
		|	GoodsShipmentToCustomer.SubsequentDeliveryByTransfer                  AS SubsequentDeliveryByTransfer,
		|	GoodsShipmentToCustomer.DocumentAmount                        AS DocumentAmount,
		|	GoodsShipmentToCustomer.Shipper                      AS Shipper,
		|	GoodsShipmentToCustomer.ShipperBankAccount        AS ShipperBankAccount,
		|	GoodsShipmentToCustomer.GoodsRecipient                       AS GoodsRecipient,
		|	GoodsShipmentToCustomer.GoodsRecipientBankAccount         AS GoodsRecipientBankAccount,
		|	GoodsShipmentToCustomer.Director                          AS Director,
		|	GoodsShipmentToCustomer.ChiefAccountant                      AS ChiefAccountant,
		|	GoodsShipmentToCustomer.IssuiedBy                              AS IssuiedBy,
		|	GoodsShipmentToCustomer.IssuiedByJobTitle                     AS IssuiedByJobTitle,
		|	GoodsShipmentToCustomer.LocalConversionRatio              AS LocalConversionRatio,
		|	GoodsShipmentToCustomer.LetterOfAuthorityIssuedBy                    AS LetterOfAuthorityIssuedBy,
		|	GoodsShipmentToCustomer.PowerOfAttorneyDate                      AS PowerOfAttorneyDate,
		|	GoodsShipmentToCustomer.PowerOfAttorneyPerson                      AS PowerOfAttorneyPerson,
		|	GoodsShipmentToCustomer.PowerOfAttorneyNumber                     AS PowerOfAttorneyNumber,
		|	GoodsShipmentToCustomer.DeliveryAddressValue                 AS DeliveryAddressValue,
		|	GoodsShipmentToCustomer.DeliveryAddressOfCarrierValue      AS DeliveryAddressOfCarrierValue,
		|	GoodsShipmentToCustomer.VATTaxation                    AS VATTaxation
		|FROM
		|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
		|WHERE
		|	GoodsShipmentToCustomer.Ref = &BaseDocumentForDiscrepancyReport
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
	EndIf;
	
	QueryText = QueryText +
	"SELECT
	|	ActOfDiscrepancies.Products   AS Products,
	|	ActOfDiscrepancies.Characteristic AS Characteristic,
	|	CASE
	|		WHEN &AdditionalDelivery
	|			AND ActOfDiscrepancies.Ref.TypeOfBaseDocumentForNonConformanceCertificate = VALUE(Enum.TypesOfBaseDocumentsForDiscrepancyReport.CustomerInvoice)
	|			AND ActOfDiscrepancies.Ref.DiscrepanciesPostingMethod IN (
	|					VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegisterAdjustmentErrorCorrection),
	|					VALUE(Enum.MethodsOfRecordingDiscrepanciesCustomerReceivingNote.RegistrationOfAdjustmentAsAgreedByParties)
	|					)
	|			THEN 0
	|		ELSE
	|			ActOfDiscrepancies.RowCode
	|	END                                 AS RowCode,
	|	ActOfDiscrepancies.Warehouse          AS Warehouse,
	|	ActOfDiscrepancies.Purpose     AS Purpose,
	|	CASE
	|		WHEN &AdditionalDelivery
	|			THEN ActOfDiscrepancies.CountByDocument - ActOfDiscrepancies.Count
	|		ELSE
	|			ActOfDiscrepancies.Count
	|	END                                 AS Count,
	|	CASE
	|		WHEN ActOfDiscrepancies.Ref.PriceIncludesVAT
	|			THEN ActOfDiscrepancies.Price
	|		WHEN ActOfDiscrepancies.NumberOfPackages <> 0
	|			AND ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN ActOfDiscrepancies.Sum / ActOfDiscrepancies.NumberOfPackages
	|		WHEN ActOfDiscrepancies.NumberOfPackages <> 0
	|			THEN ActOfDiscrepancies.AmountIncludingVAT / ActOfDiscrepancies.NumberOfPackages
	|		WHEN ActOfDiscrepancies.NumberOfPackagesByDocument <> 0
	|			AND ActOfDiscrepancies.SaleOfGoodsAndServices REFS Document.GoodsShipmentToCustomer
	|			THEN ActOfDiscrepancies.SumByDocument / ActOfDiscrepancies.NumberOfPackagesByDocument
	|		WHEN ActOfDiscrepancies.NumberOfPackagesByDocument <> 0
	|			THEN ActOfDiscrepancies.AmountIncludingVATByDocument / ActOfDiscrepancies.NumberOfPackagesByDocument
	|		ELSE
	|			0
	|	END                                 AS Price,
	|	ActOfDiscrepancies.Series          AS Series,
	|	CASE
	|		WHEN ActOfDiscrepancies.SalesOrder REFS Document.GoodsShipmentToCustomer
	|			THEN UNDEFINED
	|		ELSE
	|			ActOfDiscrepancies.SalesOrder
	|	END                                 AS SalesOrder,
	|	ActOfDiscrepancies.Package       AS Package,
	|	ActOfDiscrepancies.PriceKind        AS PriceKind
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.Goods AS ActOfDiscrepancies
	|WHERE
	|	ActOfDiscrepancies.Ref = &DiscrepancyCertificate
	|	AND ActOfDiscrepancies.SaleOfGoodsAndServices = &BaseDocumentForDiscrepancyReport
	|	AND CASE
	|		WHEN &AdditionalDelivery
	|			THEN ActOfDiscrepancies.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|		ELSE
	|			ActOfDiscrepancies.Action IN (
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|				)
	|	END
	|
	|ORDER BY
	|	ActOfDiscrepancies.LineNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ActOfDivergenceSeries.Products       AS Products,
	|	ActOfDivergenceSeries.Characteristic     AS Characteristic,
	|	ActOfDivergenceSeries.Warehouse              AS Warehouse,
	|	ActOfDivergenceSeries.Purpose         AS Purpose,
	|	CASE
	|		WHEN &AdditionalDelivery
	|			THEN ActOfDivergenceSeries.CountByDocument - ActOfDivergenceSeries.Count
	|		ELSE
	|			ActOfDivergenceSeries.Count
	|	END                                    AS Count,
	|	ActOfDivergenceSeries.Series              AS Series
	|FROM
	|	Document.DiscrepancyReportFollowingShipment.SetOfSeries AS ActOfDivergenceSeries
	|WHERE
	|	ActOfDivergenceSeries.Ref = &DiscrepancyCertificate
	|	AND ActOfDivergenceSeries.SaleOfGoodsAndServices = &BaseDocumentForDiscrepancyReport
	|	AND CASE
	|		WHEN &AdditionalDelivery
	|			THEN ActOfDivergenceSeries.Action = VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired)
	|		ELSE
	|			ActOfDivergenceSeries.Action IN (
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.CreatingGoodsReceiptsByOrderAreNotMoreRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.AdditionalSupplyRequired),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.PurchasingOverdelivery),
	|				VALUE(Enum.ActionOptionsOnDiscrepanciesInCustomerInvoiceAfterGoodsIssue.ReturnOverdelivered)
	|				)
	|	END
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("AdditionalDelivery", AdditionalDelivery);
	Query.SetParameter("DiscrepancyCertificate", DiscrepancyCertificate);
	Query.SetParameter("BaseDocumentForDiscrepancyReport", BasisOfAct);
	
	QueryResults = Query.ExecuteBatch();
	
	If EnterCorrection Then
		
		TableOfItemsOfReport = QueryResults[QueryResults.UBound()-1].Unload();
		ActSeriesTable = QueryResults[QueryResults.UBound()].Unload();
		
		ShippingGoods = Goods.Unload();
		BatchShipment = SetOfSeries.Unload();
		
		SearchFields = "RowCode, " + Documents.GoodsShipmentToCustomer.KeyFieldsOfGoodsTable();
		
		For Each TableRow In TableOfItemsOfReport Do 
			
			SearchParameters = New Structure(SearchFields);
			FillPropertyValues(SearchParameters, TableRow);
			
			FoundRows = ShippingGoods.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then 
				
				For Each FoundRow In FoundRows Do
					FoundRow.Count = TableRow.Count;
				EndDo;
				
			Else // to add lines from the act in addition to the order
				
				NewRow = ShippingGoods.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.Count = TableRow.Count;
				
			EndIf;
		
		EndDo;
		
		SearchFields = "Products, Characteristic, Purpose, Series, Warehouse";
		
		For Each TableRow In ActSeriesTable Do 
			
			SearchParameters = New Structure(SearchFields);
			FillPropertyValues(SearchParameters, TableRow);
			
			FoundRows = BatchShipment.FindRows(SearchParameters);
			
			If FoundRows.Count() > 0 Then 
				
				For Each FoundRow In FoundRows Do 
					
					If FoundRow.Count > TableRow.Count Then
						
						FoundRow.Count = TableRow.Count;
						
					Else
						
						NewRow = BatchShipment.Add();
						FillPropertyValues(NewRow, FoundRow);
						NewRow.Count = TableRow.Count - FoundRow.Count;
						
					EndIf;
					
				EndDo;
				
			Else // to add lines from the act in addition to the order
				
				NewRow = BatchShipment.Add();
				FillPropertyValues(NewRow, TableRow);
				NewRow.Count = TableRow.Count;
				
			EndIf;
			
		EndDo;
		
		Goods.Load(ShippingGoods);
		SetOfSeries.Load(BatchShipment);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateAmount");
		
		BatchProcessingOfTablePartServer.TreatTS(
			Goods,
			StructureOfActions);
		
		InvoicesServer.DeleteEmptyLines(Goods, "Count");
		
		BaseDocumentOfDiscrepancyReportForCorrection = BasisOfAct;
		
	ElsIf AdditionalDelivery Then
	
		HeaderSelection = QueryResults[QueryResults.UBound()-2].Select();
		TableOfItemsOfReport = QueryResults[QueryResults.UBound()-1].Unload();
		
		HeaderSelection.Next();
		FillPropertyValues(ThisObject, HeaderSelection);
		
		For Each LineProducts_ In TableOfItemsOfReport Do
			
			If ValueIsFilled(LineProducts_.SalesOrder) Then
				ShipmentByOrders = True;
				Break;
			EndIf;
			
		EndDo;
		
		Goods.Load(TableOfItemsOfReport);
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");
		StructureOfActions.Insert("RecalculateAmount");
		
		BatchProcessingOfTablePartServer.TreatTS(
			Goods,
			StructureOfActions);
		
		InvoicesServer.DeleteEmptyLines(Goods, "Count");
		
		BaseDocumentForDiscrepancyReport = BasisOfAct;
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(ThisObject,
			Documents.GoodsShipmentToCustomer);
		
		ProductsServer.FillInSeriesByFEFO(ThisObject, SeriesSpecificationParameters, False);
		
	EndIf;
	
	StructureBase = Documents.GoodsShipmentToCustomer.StructureOfBaseForPrinting(ThisObject);
	FillPropertyValues(ThisObject, StructureBase);
	
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
	Author         = Users.CurrentUser();
	Department = SettingsValueCached.UserDivision(Manager, Department);
	
	If Not Patch Then
		FillParameters = Documents.GoodsShipmentToCustomer.ParametersForFillingInSalesVATTaxation(ThisObject);
		VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	EndIf;
	
	UseWarehousesInTheTablePart = GetFunctionalOption("UseWarehousesInTabularSectionsOfSalesDocuments");
	
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
	
	WarehouseGroup_ = Catalogs.Warehouses.ThisGroupAndWarehousesAreUsedByWHForSales(Warehouse);
	WarehousesServer.FillInWarehousesInTablePart(Warehouse, WarehouseGroup_, Goods, False);
	
EndProcedure

Procedure FillOutBankAccounts()
	
	If ValueIsFilled(CompanyBankAccount) And ValueIsFilled(CounterpartyBankAccount) Then
		Return;
	EndIf;
	
	SalesServer.FillInBankAccountsUnderAgreement(Contract,
		?(ValueIsFilled(CompanyBankAccount), Undefined, CompanyBankAccount),
		?(ValueIsFilled(CounterpartyBankAccount), Undefined, CounterpartyBankAccount));
	
	If ValueIsFilled(Organization) And Not ValueIsFilled(CompanyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.LineOfBusiness = LineOfBusiness;
		CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount);
	EndIf;
	
	If ValueIsFilled(Counterparty) And Not ValueIsFilled(CounterpartyBankAccount) Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Counterparty);
		CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
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
		Or CheckProductChanges_(TempTablesManager) Then
		
		FillParameters = ParametersForFillingInventoryTypes();
		
		InventoriesServer.FillInInventoryTypesForOrganizationsProducts(ThisObject,
																TempTablesManager,
																Cancel,
																FillParameters);
		
		InventoryKinds.GroupBy("ItemsLocationAttributes, InventoryOwnerAttribute, SalesOrder, CCDNumber, FEACNCode",
							"Count, NumberOfPackages, QuantityByGBRN, Sum");
		
		If Not Cancel Then
			FillInAdditionalStockTypes();
		EndIf;
		
	EndIf;
	
EndProcedure

Function CheckChangesToDocumentDetails(TempTablesManager)
	
	AttributesNames = "Date, Organization, VATTaxation, Partner, Contract";
	
	Return InventoriesServer.CheckChangesToDocumentDetails(TempTablesManager,
																Ref,
																AttributesNames);
	
EndFunction

Function CheckProductChanges_(TempTablesManager)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes
	|FROM
	|	(SELECT
	|		TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		TableOfGoods.Count AS Count,
	|		TableOfGoods.CommissionAmount AS CommissionAmount
	|	FROM
	|		TableOfGoods AS TableOfGoods
	|
	|	UNION ALL
	|
	|	SELECT
	|		TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		-TableTypesOfStocks_.Count AS Count,
	|		-TableTypesOfStocks_.CommissionAmount AS CommissionAmount
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|	
	|	) AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.ItemsLocationAttributes
	|
	|HAVING
	|	SUM(TableOfGoods.Count) <> 0
	|	OR SUM(TableOfGoods.CommissionAmount) <> 0";

	Result_Query = Query.Execute();
	
	Return Not Result_Query.IsEmpty();
	
EndFunction

Function ParametersForFillingInventoryTypes()
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.ReversedDocument = ReversedDocument;
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(
		Enums.InventoryTypes.GoodsInStorageWithRightToSell,
		"Never");
	
	SelectionOfStockTypes_ = FillParameters.SelectionOfStockTypes_;
	SelectionOfStockTypes_.VATTaxation = VATTaxation;
	
	VATAccountingERP.ParametersForFillingTypesOfStocksForTaxation(SelectionOfStockTypes_,
																Organization,
																Date,
																VATTaxation);
	
	Return FillParameters;
	
EndFunction

Procedure FillInAdditionalStockTypes()
	
	GroupColumns =
		"ItemsLocationAttributes,
		|ItemsLocationAttributesShipment,
		|SetAccountingDimension,
		|ProductsInSet,
		|ItemVariantOfSet,
		|Package,
		|Price,
		|SalesOrder,
		|RowCode,
		|FEACNCode";
	
	TotalingColumns = "Count, NumberOfPackages, Sum";
	
	UnloadedColumns = GroupColumns + ", " + TotalingColumns;
	
	GoodsTable = Goods.Unload(, UnloadedColumns);
	GoodsTable.GroupBy(GroupColumns, TotalingColumns);
	
	Parameters       = New Structure("Count, NumberOfPackages, Sum");
	TheStructureOfTheSearch = New Structure("ItemsLocationAttributes, SalesOrder, NumberOfPackages");
	
	For Each RowOfGoods In GoodsTable Do
		FillPropertyValues(Parameters, RowOfGoods);
		FillPropertyValues(TheStructureOfTheSearch, RowOfGoods);
		
		TheStructureOfTheSearch.NumberOfPackages = 0;
		
		FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters);
		
		If Parameters.Count <> 0
			And ValueIsFilled(RowOfGoods.SalesOrder) Then
			
			TheStructureOfTheSearch.SalesOrder = Undefined;
			
			FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters);
			
		EndIf;
	EndDo;
	
	FilterParameters = New Structure("Count", 0);
	LinesToDelete = InventoryKinds.FindRows(FilterParameters);
	
	For Each TableRow In LinesToDelete Do
		InventoryKinds.Delete(TableRow);
	EndDo;
	
EndProcedure

Procedure FillInInventoryTypesLine(RowOfGoods, TheStructureOfTheSearch, Parameters)
	
	For Each InventoryLine In InventoryKinds.FindRows(TheStructureOfTheSearch) Do
		
		If InventoryLine.Count = 0 Then
			Continue;
		EndIf;
		
		QuantityPerRow = Min(Parameters.Count, InventoryLine.Count);
		
		NewRow = InventoryKinds.Add();
		FillPropertyValues(NewRow, InventoryLine);
		
		NewRow.FEACNCode = RowOfGoods.FEACNCode;
		NewRow.RowCode = RowOfGoods.RowCode;
		NewRow.ItemsLocationAttributesShipment = RowOfGoods.ItemsLocationAttributesShipment;
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
//	DocumentTables - See Documents.GoodsShipmentToCustomer.CollectionOfTabularPartsOfGoods.
//
Procedure FillInProductTrackingDataInTabularPartsOfProducts(DocumentTables = Undefined)
	
	If DocumentTables = Undefined Then
		DocumentTables = Documents.GoodsShipmentToCustomer.CollectionOfTabularPartsOfGoods();
		
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
	
	// If the Warehouse is a group, then we take the warehouse from the PM for inventory accounting analytics.
	WarehouseDetails = Common.ObjectAttributesValues(Warehouse, "IsFolder, SelectGroup");
	
	If ValueIsFilled(Warehouse)
		And WarehouseDetails.IsFolder
		And WarehouseDetails.SelectGroup = Enums.SelectWarehouseGroup.AllowInOrdersAndInvoices Then
		
		FieldsNames.Insert("Arbitrary", "Warehouse");
		
	EndIf;
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable,
																	PlacesOfAccounting,
																	FieldsNames);
	
	PlacesOfRegistrationWithPartners = InformationRegisters.ItemsLocationAttributes.PlacesOfAccounting(BusinessOperation,
																					Contract,
																					Department,
																					Partner,
																					Contract);
	
	FieldsNames.BatchesIndicationStatus        = "BatchIndicationStatusOfGoodsShipped";
	FieldsNames.ItemsLocationAttributes = "ItemsLocationAttributesShipment";
	
	FieldsNames.Insert("Arbitrary", "");
	
	InformationRegisters.ItemsLocationAttributes.FillInCollection(GoodsTable,
																	PlacesOfRegistrationWithPartners,
																	FieldsNames);
	
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
	DeliveryVerificationSettings.InvoiceForOrders = ShipmentByOrders;
	DeliveryVerificationSettings.DeliveryIndicationMethodFieldName = "";
	DeliveryVerificationSettings.MethodOfSpecifyingDeliveryIsUnconditional = Enums.DeliverySpecificationMethods.ForWholeDocument;
	DeliveryVerificationSettings.GoodsForDeliveryTableName = "";
	
	Return DeliveryVerificationSettings;
	
EndFunction

Procedure DeliveryBeforeWrite(Cancel, Val WriteMode)
	
	GoodsDelivery.BeforeWrite(ThisObject, Cancel, WriteMode);
	
	DeliveryVerificationSettings = DocumentDeliveryVerificationSettings();
	DeliveryIsApplicable =
		(DeliveryIsRequired
			And Organization <> Catalogs.Companies.ManagementCompany)
		And GoodsDeliveryClientServer.UsedDelivery();
	ThereAreGoodsNotOnOrders = Not ShipmentByOrders;
	
	If DeliveryIsApplicable
		And ShipmentByOrders Then
		
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

Procedure FillInPricesBySalesConditions()
	
	FieldsNames = "PriceKind, Price, DeliveryPeriodDays";
	
	FillParameters = New Structure();
	FillParameters.Insert("PopulationFields",     FieldsNames);
	FillParameters.Insert("Date",               Date);
	FillParameters.Insert("Organization",        Organization);
	FillParameters.Insert("Currency",             Currency);
	FillParameters.Insert("Terms",         Terms);
	FillParameters.Insert("CalculateSets", True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",     "NumberOfPackages");
	
	EnterprisePricesFillingServer.FillInPrices(Goods, Undefined, FillParameters, StructureOfActions);
	
EndProcedure

// Returns the amount of the document for the Products tabular part.
//
// Returns:
// 	Number
//
Function GetDocumentAmount() Export
	
	DocumentGoods = Goods.Unload(, "Products, Sum");
	
	Query = New Query;
	Query.SetParameter("Goods", DocumentGoods);
	Query.Text = 
	"SELECT
	|	TT.Products AS Products,
	|	TT.Sum AS Sum
	|INTO Goods
	|FROM
	|	&Goods AS TT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(SUM(Goods.Sum), 0) AS Sum
	|FROM
	|	Goods AS Goods
	|		INNER JOIN Catalog.Products AS ProductsTable
	|		ON Goods.Products = ProductsTable.Ref
	|		AND ProductsTable.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.Sum;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
