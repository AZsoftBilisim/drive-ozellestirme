#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
// 
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization, Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, PurchaseOrder, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
// 
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("PreparationOfReportsToPurchasingCommittee");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("IntangibleAssets");
	VendorInvoiceLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.VendorInvoice, DocumentRef.VendorInvoice - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.VendorInvoice") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf Document <> Undefined Then // the call is not from the update handler
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers, DocumentObject);
		
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers, DocumentObject);
		QueryTextBatchesOfProductionCosts(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTablePurchases(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject);
		QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject);
		VendorInvoiceLocalization.AddVATInclusiveQueryTexts(Query, QueryTexts, Registers, DocumentObject);

		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers, DocumentObject);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	If DocumentObject <> Undefined Then // the call is not from the update handler
		
		AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
		ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject);
		CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers, DocumentObject);
		ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject);
		
		VendorInvoiceLocalization.AddRequestTexts(Query, QueryTexts, Registers, DocumentObject);
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region Delivery

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryTextReferences =
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.Ref.Contract AS Contract,
	|	Goods.Warehouse AS Warehouse
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&References)
	|	AND Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &ThisIsOrder_
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Ref.Contract,
	|	Goods.Warehouse";
	
	QueryText =
	"SELECT
	|	Header.Number AS Number,
	|	Header.Posted AS Posted,
	|	Header.Ref AS Ref,
	|	Header.Date AS Date,
	|	CASE
	|		WHEN Header.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN Header.AdvanceHolder
	|		ELSE Header.Partner
	|	END AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	Header.DeliveryMethod AS DeliveryMethod,
	|	Header.DeliveryZone AS Zone,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|			THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|	END AS Address,
	|	CASE
	|		WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|			THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|	END AS FieldValueAddress,
	|	Header.DeliveryTimeFrom AS TimeFrom,
	|	Header.DeliveryTimeTo AS TimeTo,
	|	Header.AdditionalDeliveryInformation AS AdditionalInformation,
	|	References.Warehouse AS Warehouse,
	|	TRUE AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|FROM
	|	&TT_Orders AS References
	|		
	|		INNER JOIN Document.VendorInvoice AS Header
	|		ON (Header.Ref = References.Ref)
	|
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContract
	|		ON CounterpartyContract.Ref = References.Contract
	|
	|WHERE
	|	CounterpartyContract.Ref IS NULL
	|	OR NOT CounterpartyContract.DeliveryMethod IN (&ShippingMethodsUsed)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN DeliveryDataSource.Ref IN (&ReceiptOrderAgreement)
	|			THEN DeliveryDataSource.Number
	|		ELSE
	|			References.Ref.Number
	|	END                                       AS Number,
	|	CASE
	|		WHEN DeliveryDataSource.Ref IN (&ReceiptOrderAgreement)
	|			THEN TRUE
	|		ELSE
	|			References.Ref.Posted
	|	END                                       AS Posted,
	|	CASE
	|		WHEN DeliveryDataSource.Ref IN (&ReceiptOrderAgreement)
	|			THEN DeliveryDataSource.Ref
	|		ELSE
	|			References.Ref
	|	END                                       AS Ref,
	|	CASE
	|		WHEN DeliveryDataSource.Ref IN (&ReceiptOrderAgreement)
	|			THEN DeliveryDataSource.Date
	|		ELSE
	|			References.Ref.DATE
	|	END                                       AS Date,
	|	DeliveryDataSource.Partner				AS RecipientSender,
	|	DeliveryDataSource.CarrierPartner	AS Carrier,
	|	CASE
	|		WHEN DeliveryDataSource.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|				AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers
	|			THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE DeliveryDataSource.DeliveryMethod
	|	END										AS DeliveryMethod,
	|	DeliveryDataSource.DeliveryZone			AS Zone,
	|	CASE
	|		WHEN DeliveryDataSource.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN DeliveryDataSource.DeliveryAddressOfCarrier
	|		ELSE DeliveryDataSource.DeliveryAddress
	|	END										AS Address,
	|	CASE
	|		WHEN DeliveryDataSource.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|			THEN DeliveryDataSource.DeliveryAddressOfCarrierFieldValues
	|		ELSE DeliveryDataSource.DeliveryAddressFieldValues
	|	END										AS FieldValueAddress,
	|	DeliveryDataSource.DeliveryTimeFrom		AS TimeFrom,
	|	DeliveryDataSource.DeliveryTimeTo		AS TimeTo,
	|	DeliveryDataSource.AdditionalDeliveryInformation	AS AdditionalInformation,
	|	References.Warehouse							AS Warehouse,
	|	FALSE										AS DeliverFully,
	|	FALSE										AS SpecialTransportationConditions,
	|	""""										AS SpecialTransportationConditionsDescription,
	|	FALSE										AS SplitGoodsIssueNotesByReferences
	|FROM
	|	&TT_Orders AS References
	|		INNER JOIN Catalog.CounterpartyContracts AS DeliveryDataSource
	|		ON DeliveryDataSource.Ref = References.Contract
	|WHERE
	|	DeliveryDataSource.DeliveryMethod IN (&ShippingMethodsUsed)";
	
	QueryText = StrReplace(QueryText, "&TT_Orders", "(" + QueryTextReferences + ")");
	
	Return QueryText;
	
EndFunction

// The function returns the text of the request to receive goods for delivery by order.
//
// Returns:
//	String - the generated request text.
//
Function QueryTextGoodsToDeliver() Export
	
	QueryText =
	"SELECT
	|	Goods.Ref AS Ref,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	Goods.Purpose AS Purpose,
	|	SUM(Goods.Count) AS Count
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&References)
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose";
	
	Return QueryText;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		CreationCommand = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
		If CreationCommand <> Undefined Then
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi nhận';
												|ru = 'Акт о расхождениях после поступления';
												|en = 'Discrepancy report'; fa = 'گزارش مغایرت';
												|it = 'Atti sulle discrepanze dopo l''arrivo';
												|pl = 'Protokół o odchyleniu po wpływie';
												|tr = 'Teslim alım sonrası tutarsızlık raporu'");
			
			If GetFunctionalOption("UseGoodsInTransitFromVendors")
				Or GetFunctionalOption("UseUninvoicedDeliveries") Then
				
				CreationCommand.Handler =
					"GenerationByReferenceTMClient.CreateReportOnDiscrepanciesAfterAcceptanceBasedOnPurchaseOfGoodsServices";
				
			EndIf;
		EndIf;
	EndIf;
	
	Documents.ReturnOfGoodsToVendor.AddGenerateCommand(GenerationCommands);
	
	Documents.RedemptionOfReturnablePackagingFromVendor.AddGenerateCommand(GenerationCommands);
	
	Documents.TransferOrder.AddCreateCommandBasedOnPurchaseOfGoodsAndServicesForGroupOfWarehouses(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.PurchaseAdjustment.AddGenerateCommand(GenerationCommands);
	
	Documents.InventoryTransfer.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.GoodsShipmentToCustomer.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerInvoice.AddGenerateCommand(GenerationCommands);
	
	CreateBasedOnCommand = Documents.VendorPriceList.AddGenerateCommand(GenerationCommands);
	If CreateBasedOnCommand <> Undefined Then
		CreateBasedOnCommand.Presentation = NStr("vi = 'Ghi nhận đơn giá nhà cung cấp';
												|ru = 'Регистрация цен поставщика';
												|en = 'Vendor price registration'; fa = 'ثبت قیمت تأمین‌کننده';
												|it = 'Registrazione dei prezzi del fornitore';
												|pl = 'Rejestracja cen dostawcy';
												|tr = 'Tedarikçi fiyatlarının kaydedilmesi'");
	EndIf; 
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InventoryConsumption.AddCreateBasedOnExpenseWriteOffAssetsCommand(GenerationCommands);
	
	CreateBasedOnCommand = DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(
									GenerationCommands);
	
	If CreateBasedOnCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
															"BusinessOperation",
															Enums.BusinessTransactions.PurchaseFromVendorLocal,
															ComparisonType.NotEqual);
	EndIf;
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	Documents.OtherIncomeExpenses.AddGenerateCommand(GenerationCommands);
	ProductionServer.AddCreateContentTransferCommandBasedOn(GenerationCommands);
	Documents.TransferOfGoodsToBailee.AddGenerateCommand(GenerationCommands);
	
	Documents.PackingList.AddGenerateCommand(GenerationCommands);
	
	Documents.CCDImport.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAdjustment.AddGenerateCommand(GenerationCommands);
	
	
	Documents.InventoryConsumption.AddCreateCommandBasedOnCommissioning(GenerationCommands);
	
	Documents.ApplicationForImportationOfGoods.AddGenerateCommand(GenerationCommands);
	
	VendorInvoiceLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.ReverseVATAccrual.AddGenerateCommand(GenerationCommands);
	
	Documents.ReceiptOfServicesToBusinessUnit.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the "Purchase of goods and services" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.VendorInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.VendorInvoice.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.VendorInvoice);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction


// Adds the command to create the "Purchase of goods and services" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	FormCommand - the command being added.
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.VendorInvoice) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.PurchaseOfGoodsServicesCreateOnBasisOfOrder";
		CreateBasedOnCommand.Id = "CreateByOrderReference";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Mua hàng hóa và dịch vụ';
												|ru = 'Приобретение товаров и услуг';
												|en = 'Vendor invoice'; fa = 'فاکتور تأمین‌کننده';
												|it = 'Acquisti di beni e servizi';
												|pl = 'Nabycie towarów i usług';
												|tr = 'Satın alma faturası'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
		
	EndIf;
	
	ReportCommand = Reports.VariancesFromPurchaseConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
		
	EndIf;
	
	ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	
	ReportCommand = Reports.ARAPAccountingStatementByReturnablePackagingReceived.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		
		
	EndIf;
	
	ReportCommand = Reports.DetailedCalculationOfDiscountingInterestExpenseAccrual.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm,DocumentsList";
	EndIf;
	
	VendorInvoiceLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure


#Region FillType

// Fills in a table of products based on selection data or an array of orders
//
// Parameters:
//	SelectionData_             - Structure - fields that will be used to select order balances for filling in the document
//	Goods                   - FormDataCollection - item table in which are placed the remains of the orders
//	WarehouseForReceipt         - CatalogRef.Warehouses - Warehouse
//	AnArrayOfOrders            - Array of DocumentRef.PurchaseOrder - orders for which balances will be selected.
//	CheckOrderOfCalculations - Boolean - The default value is True, which means that no filling will be performed
//	                                    and a message will be issued if Orders with DIFFERENT payment orders are found.
//
Procedure FillByOrderBalances(SelectionData_, Goods, WarehouseForReceipt, AnArrayOfOrders = Undefined, CheckOrderOfCalculations = True) Export
	
	// Data on the remaining items of the order.
	SampleProducts_ = GetQueryResultsForOrderBalances(SelectionData_, WarehouseForReceipt, AnArrayOfOrders).Select();
	
	ArrayOfOrdersToSupplier = New Array();
	ArrayOfARAPObjectsSettings = New Array();
	
	While SampleProducts_.Next() Do
		If ArrayOfOrdersToSupplier.Find(SampleProducts_.PurchaseOrder) = Undefined Then
			ArrayOfOrdersToSupplier.Add(SampleProducts_.PurchaseOrder);
		EndIf;
		If CheckOrderOfCalculations
			And ValueIsFilled(SampleProducts_.ARAPObjectSettings)
			And ArrayOfARAPObjectsSettings.Find(SampleProducts_.ARAPObjectSettings) = Undefined Then
			ArrayOfARAPObjectsSettings.Add(SampleProducts_.ARAPObjectSettings);
		EndIf;
	EndDo;
	
	If AnArrayOfOrders = Undefined
		And CheckOrderOfCalculations 
		And ArrayOfARAPObjectsSettings.Count() > 1 Then
		Common.MessageToUser(NStr("vi = 'Trong các đơn hàng đã tìm thấy, khác trường ""Trình tự hạch toán""';
									|ru = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|en = 'The ""Payment terms"" field data is different for the found orders'; fa = 'The ""Payment terms"" field data is different for the found orders';
									|it = 'У найденных заказов отличается поле ""Порядок расчетов""';
									|pl = 'The ""Payment terms"" field data is different for the found orders';
									|tr = 'Bulunan siparişlerin farklı bir ""Alacak/Borç muhasebesi prosedürü"" alanı mevcut'"));
		Return;
	EndIf;
	
	If ArrayOfOrdersToSupplier.Count() > 0 Then
		AnArrayOfOrders = ArrayOfOrdersToSupplier;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ArrayOfOrdersToSupplier", ArrayOfOrdersToSupplier);
	Query.SetParameter("DocumentCurrency", SelectionData_.Currency);
	
	Query.Text =
	"
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref                    AS PurchaseOrder,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.PriceIncludesVAT           AS PriceIncludesVAT,
	|	CASE
	|		WHEN
	|			TheOrdersTable.Currency <> &DocumentCurrency
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ConvertToDocumentCurrency
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|;
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.Organization               AS Organization
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|";
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultOrderDetails = ResultsArray[0]; // QueryResult
	ResultSelection = ResultsArray[1]; // QueryResult
	
	OrderDetails_ = ResultOrderDetails.Select();
	
	TableOfExchangeRates = New ValueTable;
	TableOfExchangeRates.Columns.Add("Currency",    New TypeDescription("CatalogRef.Currencies"));
	TableOfExchangeRates.Columns.Add("Date",      New TypeDescription("Date"));
	TableOfExchangeRates.Columns.Add("CourseNumerator", New TypeDescription("Number"));
	TableOfExchangeRates.Columns.Add("CourseDenominator", New TypeDescription("Number"));
	
	Selection = ResultSelection.Select();
	
	While Selection.Next() Do
		
		NewRow = TableOfExchangeRates.Add();
		FillPropertyValues(NewRow, Selection);
		
		Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date,
							SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Selection.Organization));
		NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
		NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
		
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	EndIf;
	
	SampleProducts_.Reset();
	While SampleProducts_.Next() Do
		
		ProductVATRate = SampleProducts_.VATRate;
		
		AmountsMustBeRecalculated = (SampleProducts_.Count <> SampleProducts_.QuantityByOrder);
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_);
		TabRow.VATRate = ProductVATRate;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.PurchaseOrder, "PurchaseOrder");

		TakeAmountFromOrder = False;
		
		If OrderFound And SampleProducts_.QuantityByOrder >= SampleProducts_.Count Then
			
			TabRow.Count = SampleProducts_.QuantityByOrder - SampleProducts_.Count;
			TabRow.NumberOfPackages = ?(TabRow.Count = 0, 0, TabRow.Count/ SampleProducts_.ZoomRatio);
			TakeAmountFromOrder = True;
			
		Else		
			
			TabRow.Count = SampleProducts_.Count;
			TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
		
		EndIf;
		
		If OrderFound And (TakeAmountFromOrder Or AmountsMustBeRecalculated Or OrderDetails_.ConvertToDocumentCurrency) Then
			
			If Not TakeAmountFromOrder 
				And OrderDetails_.ConvertToDocumentCurrency Then
				
				FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
				CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
				
				If CurrencyExchangeRate.Count() = 1 Then
					
					TabRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
							TabRow.Price,
							CurrencyExchangeRate[0],
							StructureOfNewCurrencyRates);
					AmountsMustBeRecalculated = True;
					
				EndIf;
				
			EndIf;
			
			PriceManagementSystem.RecalculateAmountsInRow(TabRow, False, False, True, OrderDetails_.PriceIncludesVAT);
			
			If TakeAmountFromOrder Then
			
				TabRow.Count =  SampleProducts_.Count;
				TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
				TabRow.Sum = SampleProducts_.Sum - TabRow.Sum;
				TabRow.VATAmount = SampleProducts_.VATAmount - TabRow.VATAmount;
				TabRow.AmountIncludingVAT = SampleProducts_.AmountIncludingVAT - TabRow.AmountIncludingVAT;
				If TabRow.PercentRateOfManualDiscount <> 0 Then
					TabRow.ManualDiscount = SampleProducts_.ManualDiscount - TabRow.ManualDiscount;
				EndIf;
				
				If OrderDetails_.ConvertToDocumentCurrency Then
					
					FilterParameters = New Structure("Currency,Date", OrderDetails_.Currency, OrderDetails_.Date);
					CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
					
					If CurrencyExchangeRate.Count() = 1 Then
						
						TabRow.Price = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
								TabRow.Price,
								CurrencyExchangeRate[0],
								StructureOfNewCurrencyRates);
						AmountsMustBeRecalculated = True;
			
						TabRow.Sum = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
								TabRow.Sum,
								CurrencyExchangeRate[0],
								StructureOfNewCurrencyRates);
								
						TabRow.VATAmount = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
								TabRow.VATAmount,
								CurrencyExchangeRate[0],
								StructureOfNewCurrencyRates);
								
						TabRow.AmountIncludingVAT = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
								TabRow.AmountIncludingVAT,
								CurrencyExchangeRate[0],
								StructureOfNewCurrencyRates);
								
						TabRow.ManualDiscount = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
								TabRow.ManualDiscount,
								CurrencyExchangeRate[0],
								StructureOfNewCurrencyRates);
								
					EndIf;
					
				EndIf;
				
			EndIf;
			
			If SelectionData_.VATTaxation = Enums.VATTaxationTypes.SubjectToVATAtCustomer Then
				TabRow.VATAmount = 0;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,BusinessOperation,Date";
	
	Return AttributesNames;
EndFunction



// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.VendorInvoice";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	PurchasingFromSupplierUsingLocalAccounting = (Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal);
	
	If PurchasingFromSupplierUsingLocalAccounting Then
		SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
		SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		SeriesSpecificationParameters.SeriesOnlyForCostPrice    = True;
	Else
		SeriesSpecificationParameters.UseItemsBatch  = 
						(WarehouseSeriesParameters.UseItemsBatch And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date, True))
						Or WarehouseSeriesParameters.UseCostAccountingByBatches;
		SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
		SeriesSpecificationParameters.SeriesOnlyForCostPrice    = False;
		SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	EndIf;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ReceiptFromVendor);
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Ref");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Terms");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Contract");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("ReceiptUnderOrders");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("Goods_PurchaseOrder");
	SeriesSpecificationParameters.FieldNamesForOrderDefinition.Add("GoodsReceiptOption");
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	OperationsInTransit = New Array();
	OperationsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	OperationsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	
	NonInvoicingOperations = New Array();
	NonInvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	NonInvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	
	BusinessTransactionGoodsInTransitAndNonInvoicing = OperationsInTransit.Find(Object.BusinessOperation) <> Undefined
		Or NonInvoicingOperations.Find(Object.BusinessOperation) <> Undefined;
	TheseAreGoodsInTransit = OperationsInTransit.Find(Object.BusinessOperation) <> Undefined;
	
	SeriesSpecificationParameters.QueryOptions.Insert("TheseAreGoodsInTransit", TheseAreGoodsInTransit);
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessTransactionGoodsInTransitAndNonInvoicing", BusinessTransactionGoodsInTransitAndNonInvoicing);
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.LineNumber
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Warehouse,
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			OR &BusinessTransactionGoodsInTransitAndNonInvoicing
	|			THEN 0
	|		ELSE CASE
	|				WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				WHEN NOT &SeriesOnlyForCostPrice
	|					THEN CASE
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|								THEN CASE
	|										WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 10
	|													ELSE 9
	|												END
	|										ELSE 0
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|								THEN CASE
	|										WHEN NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|												OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 8
	|													ELSE 7
	|												END
	|										ELSE 0
	|									END
	|							WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceiving
	|									AND (NOT Warehouses.UseWarehouseManagemantSystemForGoodsReceipt
	|										OR &Date < Warehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|									AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyOnReceivingFromVendor
	|								THEN CASE
	|										WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|											THEN CASE
	|													WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|															AND ProductsToRequest.Count > 0
	|														THEN 4
	|													ELSE 3
	|												END
	|										ELSE CASE
	|												WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|														AND ProductsToRequest.Count > 0
	|													THEN 2
	|												ELSE 1
	|											END
	|									END
	|							ELSE 0
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					AND &BusinessTransactionGoodsInTransitAndNonInvoicing
	|					THEN
	|						CASE
	|							WHEN ((ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInUninvoicedGoodsDeliveries
	|										AND NOT &TheseAreGoodsInTransit)
	|									OR (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor)
	|										AND &TheseAreGoodsInTransit)
	|								THEN CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatusGoodsAtPartners
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|				AND ProductsToRequest.Warehouse = SeriesToRequest.Warehouse
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = ProductsToRequest.Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber                         AS LineNumber,
	|	CASE
	|		WHEN &BusinessTransactionGoodsInTransitAndNonInvoicing
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                       AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	CASE
	|		WHEN &BusinessTransactionGoodsInTransitAndNonInvoicing
	|			THEN Statuses.BatchesIndicationStatusGoodsAtPartners
	|		ELSE Statuses.BatchesIndicationStatus
	|	END <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return VendorInvoiceLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return VendorInvoiceLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.VendorInvoice, DocumentRef.VendorInvoice - Document.
//  FieldNameControlledLotReference - String - field name, controlled Lot reference.
// 
// Returns:
//  See QualityControl.NewAttributesOfControlledLotReference
Function AttributesOfControlledLotReference(ObjectOrRef, FieldNameControlledLotReference) Export
	
	Attributes = QualityControl.NewAttributesOfControlledLotReference();
	ObjectAttributes = QualityControl.AttributesOfItemOrLink(ObjectOrRef,
		"Contract,
		|Partner,
		|Ref,
		|Date,
		|DateOfReceipt,
		|Number,
		|BusinessOperation,
		|AdvanceHolder,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.DateOfReceipt = InvoicesServer.DateOfReceipt(ObjectAttributes.DateOfReceipt, ObjectAttributes.Date);
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.Organization = ObjectAttributes.Organization;
	Attributes.Department = ObjectAttributes.Department;
	
	// The Attributes for Registering Records according to the Accumulation register "Goods for receipt", when the Lot reference is known, for example, for return
	// without registration in the document "Quality control Act". The logic of filling in the fields is synchronized with the Registered Records of the current
	// document, as an order in "Goods for receipt".
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Attributes.Sender = ObjectAttributes.Partner;
	If ObjectAttributes.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		Attributes.Sender = ObjectAttributes.AdvanceHolder;
	EndIf;
	
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.VendorInvoice - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	Reset = Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal;
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products,Warehouse,ToExpenseAs";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlReset", Reset);
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	&QualityControlReset OR Table.ToExpenseAs AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Fills in the table of details that depend on the business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("AdvanceHolder");
	ArrayOfAllProps.Add("CashFlowItem");
	ArrayOfAllProps.Add("PaymentMethod");
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("PurchaseForActivity");
	ArrayOfAllProps.Add("VATTaxation");
	ArrayOfAllProps.Add("SalesOpportunity");
	ArrayOfAllProps.Add("ARAPObjectSettings");
	ArrayOfAllProps.Add("CompanyBankAccount");
	ArrayOfAllProps.Add("Director");
	ArrayOfAllProps.Add("CounterpartyBankAccount");
	ArrayOfAllProps.Add("Shipper");
	ArrayOfAllProps.Add("ShipperBankAccount");
	ArrayOfAllProps.Add("ReceivedBy");
	ArrayOfAllProps.Add("AcceptedPosition");
	
	ArrayOfAllProps.Add("Goods.PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("Goods.ManualDiscount");
	ArrayOfAllProps.Add("Goods.ToExpenseAs");
	ArrayOfAllProps.Add("Goods.ExpenseItem");
	ArrayOfAllProps.Add("Goods.DimensionOfExpenses");
	ArrayOfAllProps.Add("Goods.CCDNumber");
	ArrayOfAllProps.Add("Goods.PartnerProducts");
	ArrayOfAllProps.Add("Goods.VendorPriceKind");
	
	UseDiscountAdjustmentsInPurchases = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
	
	ArrayOfOperationDetails = New Array;
	If BusinessTransactionsPurchasingFromSupplier.Find(BusinessOperation) <> Undefined
	 Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("SalesOpportunity");
		ArrayOfOperationDetails.Add("ARAPObjectSettings");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("Director");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Shipper");
		ArrayOfOperationDetails.Add("ShipperBankAccount");
		ArrayOfOperationDetails.Add("ReceivedBy");
		ArrayOfOperationDetails.Add("AcceptedPosition");
		
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.PartnerProducts");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
		If UseDiscountAdjustmentsInPurchases Then
			ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
			ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("AdvanceHolder");
		ArrayOfOperationDetails.Add("CashFlowItem");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("Director");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		
		If UseDiscountAdjustmentsInPurchases Then
			ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
			ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		EndIf;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("SalesOpportunity");
		ArrayOfOperationDetails.Add("ARAPObjectSettings");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("Director");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Shipper");
		ArrayOfOperationDetails.Add("ShipperBankAccount");
		ArrayOfOperationDetails.Add("ReceivedBy");
		ArrayOfOperationDetails.Add("AcceptedPosition");
		
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.PartnerProducts");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	ElsIf BusinessTransactionsImportPurchase.Find(BusinessOperation) <> Undefined Then
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("SalesOpportunity");
		ArrayOfOperationDetails.Add("ARAPObjectSettings");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("Director");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Shipper");
		ArrayOfOperationDetails.Add("ShipperBankAccount");
		ArrayOfOperationDetails.Add("ReceivedBy");
		ArrayOfOperationDetails.Add("AcceptedPosition");
		
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.PartnerProducts");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
		If UseDiscountAdjustmentsInPurchases Then
			ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
			ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		EndIf;
	
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(BusinessOperation) <> Undefined Then
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("FinancialAccountingGroup");
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("SalesOpportunity");
		ArrayOfOperationDetails.Add("ARAPObjectSettings");
		ArrayOfOperationDetails.Add("CompanyBankAccount");
		ArrayOfOperationDetails.Add("Director");
		ArrayOfOperationDetails.Add("CounterpartyBankAccount");
		ArrayOfOperationDetails.Add("Shipper");
		ArrayOfOperationDetails.Add("ShipperBankAccount");
		ArrayOfOperationDetails.Add("ReceivedBy");
		ArrayOfOperationDetails.Add("AcceptedPosition");
		
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.CCDNumber");
		ArrayOfOperationDetails.Add("Goods.PartnerProducts");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
		If UseDiscountAdjustmentsInPurchases Then
			ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
			ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		EndIf;
	
	EndIf;
	
	VendorInvoiceLocalization.FillInNamesOfBusinessTransactionDetails(BusinessOperation,
																						ArrayOfAllProps,
																						ArrayOfOperationDetails);
	
EndProcedure

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	If Not ValueIsFilled(FieldValuesToIdentifyReferences.Terms)
		And Not ValueIsFilled(FieldValuesToIdentifyReferences.Contract) Then
		If FieldValuesToIdentifyReferences.ReceiptUnderOrders Then
			Return FieldValuesToIdentifyReferences.Goods_PurchaseOrder;
		Else
			Return FieldValuesToIdentifyReferences.Ref;
		EndIf;
	Else
		GoodsReceiptOption = FieldValuesToIdentifyReferences.GoodsReceiptOption;
		
		If GoodsReceiptOption = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then 
			If FieldValuesToIdentifyReferences.ReceiptUnderOrders Then
				Return FieldValuesToIdentifyReferences.Goods_PurchaseOrder;
			Else
				Return FieldValuesToIdentifyReferences.Ref;
			EndIf;
		ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(GoodsReceiptOption) Then
			Return FieldValuesToIdentifyReferences.Terms;
		ElsIf Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(GoodsReceiptOption) Then
			Return FieldValuesToIdentifyReferences.Contract;
		EndIf;
		
	EndIf;
EndFunction

// Initializes the status structure of the document.
//
// Returns:
//   Structure - initialized document execution structure.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithSuppliersTable", 1);
	StructureState.Insert("DisplayReceiptTables", 2);
	StructureState.Insert("ThisIsAnInvoice", True);
	StructureState.Insert("ThereAreSummaryIndicatorsOfReceipt", True);
	StructureState.Insert("NameOfInvoiceForOrdersField", "ReceiptUnderOrders");
	
	Return StructureState
	
EndFunction

// Returns the document processing order
// 
// Parameters:
// 	Form - ClientApplicationForm - Form
// Returns:
// 	Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.TermsOfUse_ = "Object.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	
	AppointmentTemplateWithoutAgencyPurchase = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	AppointmentTemplateWithoutAgencyPurchase.LineOfBusiness  = "Object.LineOfBusiness";
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.DeliveryForPrincipal));
	
	AppointmentTemplateWithoutAgencyPurchase.TermsOfUse_ = "Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	
	// The needs for work in the recipient department.

	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	
	Return FormTemplate;
	
EndFunction

// Fills in the parameters of a request that retrieves data about business operations used in the document.
//
// Parameters:
//	QueryOptions - Structure - request parameters to initialize:
//		* BusinessTransactionsPurchasingFromSupplier				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsImportPurchase				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsProcurementInEAEUCountries			 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsAdmissionToCommission				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsGoodsInTransit					 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsUnfacturedDeliveries		 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsDoNotShareProcurementProcessing	 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//
Procedure FillInParametersOfBusinessOperations(QueryOptions) Export
	
	UseImports = GetFunctionalOption("UseImports");
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UsePurchaseCommission = GetFunctionalOption("UsePurchaseCommission");
	UseGoodsInTransitFromVendors = GetFunctionalOption("UseGoodsInTransitFromVendors");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	UseManagementCompany = GetFunctionalOption("UseManagementCompany");
	
	BusinessTransactionsPurchasingFromSupplier = New Array;
	BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	If UseManagementCompany Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorLocal);
	EndIf;
	
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	EndIf;
	
	If UseUninvoicedDeliveries Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	EndIf;
	
	BusinessTransactionsImportPurchase = New Array;
	If UseImports Then
		BusinessTransactionsImportPurchase.Add(Enums.BusinessTransactions.PurchaseByImport);
		
		If UseGoodsInTransitFromVendors Then
			BusinessTransactionsImportPurchase.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		EndIf;
	EndIf;
	
	BusinessTransactionsProcurementInEAEUCountries = New Array;
	If UseImportOfGoodsFromCustomsUnion Then
		BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEU);
		
		If UseGoodsInTransitFromVendors Then
			BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		EndIf;
		
		If UseUninvoicedDeliveries Then
			BusinessTransactionsProcurementInEAEUCountries.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsAdmissionToCommission = New Array;
	If UsePurchaseCommission Then
		BusinessTransactionsAdmissionToCommission.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	BusinessTransactionsGoodsInTransit = New Array;
	If UseGoodsInTransitFromVendors Then
		BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
		
		If UseImports Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
		EndIf;
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsGoodsInTransit.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
		EndIf;
	EndIf;
	
	BusinessTransactionsUnfacturedDeliveries = New Array;
	If UseUninvoicedDeliveries Then
		BusinessTransactionsUnfacturedDeliveries.Add(
			Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
		
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsUnfacturedDeliveries.Add(
				Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsDoNotShareProcurementProcessing = New Array;
	BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseViaAdvanceHolder);
	
	If UseManagementCompany Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseFromVendorLocal);
	EndIf;
	
	If UsePurchaseCommission Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	If UseImports Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.PurchaseByImport);
	EndIf;
	If UseImportOfGoodsFromCustomsUnion Then
		BusinessTransactionsDoNotShareProcurementProcessing.Add(Enums.BusinessTransactions.ImportFromEAEU);
	EndIf;
	
	QueryOptions.BusinessTransactionsPurchasingFromSupplier           = BusinessTransactionsPurchasingFromSupplier;
	QueryOptions.BusinessTransactionsImportPurchase             = BusinessTransactionsImportPurchase;
	QueryOptions.BusinessTransactionsAdmissionToCommission              = BusinessTransactionsAdmissionToCommission;
	QueryOptions.BusinessTransactionsProcurementInEAEUCountries          = BusinessTransactionsProcurementInEAEUCountries;
	QueryOptions.BusinessTransactionsGoodsInTransit                  = BusinessTransactionsGoodsInTransit;
	QueryOptions.BusinessTransactionsUnfacturedDeliveries    = BusinessTransactionsUnfacturedDeliveries;
	QueryOptions.BusinessTransactionsDoNotShareProcurementProcessing = BusinessTransactionsDoNotShareProcurementProcessing;
	
EndProcedure

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	VendorInvoiceLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region VATAccounting

Function EconomicImportOperations() Export
	
	EconomicImportOperations = New Array;
	EconomicImportOperations.Add(
		PredefinedValue("Enum.BusinessTransactions.PurchaseByImport"));
	EconomicImportOperations.Add(
		PredefinedValue("Enum.BusinessTransactions.ImportGoodsInTransit"));
	
	Return EconomicImportOperations;
	
EndFunction

Function EconomicOperationsImportFromEAEU() Export
	
	EconomicOperationsImportFromEAEU = New Array;
	EconomicOperationsImportFromEAEU.Add(
		PredefinedValue("Enum.BusinessTransactions.ImportFromEAEU"));
	EconomicOperationsImportFromEAEU.Add(
		PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit"));
	EconomicOperationsImportFromEAEU.Add(
		PredefinedValue("Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery"));
	
	Return EconomicOperationsImportFromEAEU;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.VendorInvoice, DocumentRef.VendorInvoice, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	If TypeOf(Object) = Type("DocumentObject.VendorInvoice")
		Or TypeOf(Object) = Type("FormDataStructure") Then
		ObjectData = Object;
	ElsIf TypeOf(Object) = Type("DocumentRef.VendorInvoice") Then
		ObjectData = Common.ObjectAttributesValues(Object, "Counterparty,Contract,BusinessOperation,Date");
	EndIf;
	
	FillParameters.Counterparty = ObjectData.Counterparty;
	FillParameters.Contract = ObjectData.Contract;
	FillParameters.Period = ObjectData.Date;
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
		
	If ObjectData.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
		Or ObjectData.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf BusinessTransactionsPurchasingFromSupplier.Find(ObjectData.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = False;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(ObjectData.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
		
	ElsIf BusinessTransactionsImportPurchase.Find(ObjectData.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoods = True;
		
	ElsIf  ObjectData.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale  Then
		
		FillParameters.PurchaseOfGoods = True;
		
	ElsIf ObjectData.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		FillParameters.ConsignmentProcurement = True;
		
	ElsIf  ObjectData.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		FillParameters.PurchaseViaAdvanceHolder = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the VAT activity type.
//
// Parameters:
//  Object - DocumentObject.VendorInvoice
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization = Object.Organization;
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Contract = Object.Contract;
	FillParameters.Date = Object.Date;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.Department = Object.Department;
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
		
	If BusinessTransactionsPurchasingFromSupplier.Find(Object.BusinessOperation) <> Undefined
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal 
		Or Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(Object.BusinessOperation) <> Undefined
		Or BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		
	ElsIf  Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		FillParameters.PurchaseOfGoods = True;
		
	EndIf;
	
	Return FillParameters;

EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.VendorInvoice, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	
	RegistrationParameters.Ref				= Object.Ref;
	RegistrationParameters.Date				= Object.Date;
	RegistrationParameters.Organization		= Object.Organization;
	RegistrationParameters.Counterparty			= Object.Counterparty;
	RegistrationParameters.VATTaxation = Object.VATTaxation;
	
	ImportFromEAEU = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	PurchaseByImport = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	If Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		RegistrationParameters.ConsignmentProcurement = True;
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		RegistrationParameters.PurchaseViaAdvanceHolder = True;
	ElsIf ImportFromEAEU.Find(Object.BusinessOperation) <> Undefined Then
		RegistrationParameters.ImportOfGoodsFromCustomsUnion = True;
	ElsIf PurchaseByImport.Find(Object.BusinessOperation) <> Undefined Then
		RegistrationParameters.ImportOfGoods = True;
	Else
		RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	EndIf;
	
	Return RegistrationParameters;
	
EndFunction

#EndRegion

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region GoodsExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object.Goods";
	ChoiceParameters.AssetRef = "ExpenseItem";
	
	If ProductsServer.ListOfBusinessOperationsExcludingServicesAndWorks().FindByValue(BusinessOperation) <> Undefined Then
		ChoiceParameters.AvailabilityByOperation = False;
	EndIf;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation,
			|ReceiptUnderOrders,
			|Ref");
		BusinessOperation = StructureFillingData.BusinessOperation;
		ReceiptUnderOrders  = StructureFillingData.ReceiptUnderOrders;
		ThereAreAdjustingEntries     = False;
		PurchasesServer.CheckForAdjustmentsAndInvoices(StructureFillingData.Ref, StructureFillingData.Ref, ThereAreAdjustingEntries, False);
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		ReceiptUnderOrders  = False;
		ThereAreAdjustingEntries     = False;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		ReceiptUnderOrders  = FillingData.ReceiptUnderOrders;
		ThereAreAdjustingEntries     = False;
		PurchasesServer.CheckForAdjustmentsAndInvoices(FillingData.Ref, FillingData.Ref, ThereAreAdjustingEntries, False);
	EndIf;
	
	SettlementParameters = New Array;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                     = True;
	ParametersStructure.PaymentType_                           = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesPaymentPlan                    = BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
																
ParametersStructure.ChangesCalculationsByString                = 
	"DataSource.BusinessOperation IN (VALUE(Enum.BusinessTransactions.PurchaseFromSupplier),
	|											VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal),
	|											VALUE(Enum.BusinessTransactions.PurchaseByImport),
	|											VALUE(Enum.BusinessTransactions.ImportFromEAEU),
	|											VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|											VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|											VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|											VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|											VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
	|";
	ParametersStructure.ModifiesDeliveryShipmentPlan          = BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
																Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
																Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	ParametersStructure.ARAPCurrency                  = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                   = "Object.AmountARAP";
	ParametersStructure.AmountARAPByPackage             = "Object.AmountARAPByPackage"; 
	
	ParametersStructure.CourseNumerator                         = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                       = "Object.CourseDenominator";
	
	ParametersStructure.PathToTSData                         = "Object.Goods";
	ParametersStructure.PropsNameTSOrder                   = "PurchaseOrder";
	ParametersStructure.PathToTSDataPaymentDecryption       = "Object.ARAPDetails";
	
	ParametersStructure.CashAccount                                 = "";
	ParametersStructure.Manager                              = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber               = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate                = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName       = "Object.ExternalDocumentName";
	
	ParametersStructure.InvoiceForOrders                    = "Object.ReceiptUnderOrders";
	ParametersStructure.OrderBase                        = "Object.PurchaseOrder";
	
	ParametersStructure.FormItems.LabelCurrencies          = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages           = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations         = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement            = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements  = "GoodsAmountARAP";
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly   = ThereAreAdjustingEntries;
	ParametersStructure.DocumentCurrencyViewOnly        = ReceiptUnderOrders And Not UserRightsCached.VarianceFromPurchaseConditions();
	ParametersStructure.MutualSettlementsCurrencyViewOnly   = ReceiptUnderOrders And Not UserRightsCached.VarianceFromPurchaseConditions();
	ParametersStructure.DonTShowCalculations                  = BusinessOperation = PredefinedValue("Enum.BusinessTransactions.PurchaseViaAdvanceHolder");
	
	ParametersStructure.PathToTSDataPaymentSteps             = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText                   = "Form.PaymentStepsText";
	ParametersStructure.SourceOfAmountsTabularPart           = True;
	ParametersStructure.DocumentAmountForm                  = "Form.AmountTotal";
	ParametersStructure.AmountOfDepositForContainerForm               = "Form.PackageDepositValue";
	ParametersStructure.InvoiceForSeveralOrdersIsPossible = GetFunctionalOption("UseReceiptForMultipleOrders");
	
	ParametersStructure.ARAPObject                       = "Object.Goods.ARAPObject";
	
	ParametersStructure.DocumentExchangeRateDate             = "Object.DocumentExchangeRateDate";
	ParametersStructure.ToReturnReusablePackage            = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired                 = "Object.PackageDepositIsRequired";
	
	ParametersStructure.OperationWithSelfEmployedPerson                 = "Object.OperationWithSelfEmployedPerson";
	ParametersStructure.TSP                                  = "Object.Warehouse";
	
	SettlementParameters.Add(ParametersStructure);
	
	If BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		
		ParametersStructure = ARAPAccountingServer.MechanismParameters();
		ParametersStructure.PaymentType_                = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.Organization                = Catalogs.Companies.ManagementCompany;
		ParametersStructure.SourceOfAmountsTabularPart = True;
		ParametersStructure.ThisIsSalePurchase          = True;
		ParametersStructure.ARAPCurrency       = "Object.ARAPCurrency";
		ParametersStructure.AmountARAP        = "Object.AmountARAP";
		ParametersStructure.CashAccount                      = "";
		ParametersStructure.CourseNumerator              = "Object.CourseNumerator";
		ParametersStructure.CourseDenominator            = "Object.CourseDenominator";
		ParametersStructure.PathToTSData              = "Object.Goods";
		ParametersStructure.ARAPObject             = "Object.ObjectOfManCalculations";
		ParametersStructure.Contract                    = "";
		ParametersStructure.TSP                        = "Object.Warehouse";
		
		SettlementParameters.Add(ParametersStructure);
		
	EndIf;
	
	Return SettlementParameters;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - composition of properties See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.VHFWarehouses				= True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndRegion

 #Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.VendorInvoice.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("7344821c-a805-4238-a7d6-52a2ec45bcee");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.VendorInvoice.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Mua hàng hóa và dịch vụ"":';
								|ru = 'Обновление документов ""Приобретение товаров и услуг"":';
								|en = 'Update the ""Vendor invoice"" documents:'; fa = 'Update the ""Vendor invoice"" documents:';
								|it = 'Update the ""Vendor invoice"" documents:';
								|pl = 'Update the ""Vendor invoice"" documents:';
								|tr = '""Mal ve hizmet alımı"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Phương án tiếp nhận dịch vụ"" bằng giá trị của mục tin ""Phương án tiếp nhận hàng hóa"".';
								|ru = '- заполняет реквизит ""Вариант приемки услуг"" значением реквизита ""Вариант приемки товаров"".';
								|en = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.'; fa = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|it = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|pl = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|tr = '""Hizmet kabulü seçeneği"" özniteliğini ""Mal kabulü seçeneği"" özniteliğinin değeriyle doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.VendorInvoice.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.VendorInvoice.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.VendorInvoice";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.VendorInvoice AS DocumentAttributes
	|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentAttributes.Contract = CounterpartyContracts.Ref
	|WHERE
	|	DocumentAttributes.ServiceReceiptOption = VALUE(Enum.GoodsReceiptOptions.EmptyRef)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.VendorInvoice";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	UpdatedData.Ref AS Ref
	|INTO UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Ref AS Ref,
	|	DocumentAttributes.DataVersion AS DataVersion,
	|	DocumentAttributes.GoodsReceiptOption AS GoodsReceiptOption
	|FROM
	|	UpdatedData AS UpdatedData
	|		LEFT JOIN Document.VendorInvoice AS DocumentAttributes
	|		ON UpdatedData.Ref = DocumentAttributes.Ref";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ExceptionReason = 0;
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			ObjectModified = False;
			
			If DocumentObject <> Undefined Then
				If Not ValueIsFilled(DocumentObject.ServiceReceiptOption) Then
					DocumentObject.ServiceReceiptOption = Selection.GoodsReceiptOption;
					ObjectModified = True;
				EndIf;
			EndIf;
			
			ExceptionReason = 2; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
			If ExceptionReason = 2 Then
				Raise NStr("vi = 'Không thể xử lý chứng từ ""Mua hàng hóa và dịch vụ"".';
							|ru = 'Не удалось обработать обновление документов ""Приобретение товаров и услуг"".';
							|en = 'Cannot process the update of the ""Vendor invoice"" documents.'; fa = 'Cannot process the update of the ""Vendor invoice"" documents.';
							|it = 'Cannot process the update of the ""Vendor invoice"" documents.';
							|pl = 'Cannot process the update of the ""Vendor invoice"" documents.';
							|tr = '""Ürün ve hizmet alımı"" belgelerinin güncellenmesi işlenemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "VendorInvoice");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	If RegisterName = "ItemsPricesOfVendor" Then
		DataSources.Insert("Goods.VendorPriceKind");
	EndIf;
	
	Return DataSources;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.PaymentMethod AS PaymentMethod,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.AdvanceHolder AS AdvanceHolder,
	|	DocumentData.ExpenseReport AS ExpenseReport,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN DocumentData.AdvanceHolder
	|		ELSE DocumentData.Partner
	|	END AS Sender,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyLocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Partner AS Vendor,
	|	DocumentData.Counterparty AS Counterparty,
	|	ISNULL(DocumentData.CounterpartyCountryOfResidence, VALUE(Catalog.WorldCountries.EmptyRef)) AS RegistrationCountry,
	|	ISNULL(DocumentData.CounterpartyCountryOfResidence.EEUMember, FALSE) AS CounterpartyMemberOfEAEU,	
	|	DocumentData.Terms AS Terms,
	|	DocumentData.Currency AS Currency,
	|	ISNULL(DocumentData.AgreementCurrency_, VALUE(Catalog.Currencies.EmptyRef)) AS AgreementCurrency,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	ISNULL(DocumentData.AgreementPriceIncludesVAT, FALSE) AS PriceIncludesVATTerms,
	|	DocumentData.RegisterVendorPrices AS RegisterVendorPrices,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.PurchaseOrder AS PurchaseOrder,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|			THEN TRUE
	|			ELSE FALSE
	|	END AS OperationOfImportingGoodsInTransitAndNonInvoicingIsUsed,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
	|		) THEN TRUE
	|		ELSE FALSE
	|	END AS UnfactuationOperationIsUsed,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	DocumentData.Department AS Department,
	|	ISNULL(DocumentData.SubdivisionIsVariantOfSeparateAccountingOfItems, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.ReceiptUnderOrders AS ReceiptUnderOrders,
	|	DocumentData.GoodsReceiptOption AS GoodsReceiptOption,
	|	DocumentData.ServiceReceiptOption AS ServiceReceiptOption,
	|	DocumentData.Contract AS Contract,
	|	CASE
	|		WHEN DocumentData.BusinessOperation IN(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|														VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|														VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|														VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|														VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UninvoicedReceiptDocumentIsUsed,
	|	DocumentData.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	DocumentData.PackageDepositIsRequired AS PackageDepositIsRequired,
	|	DocumentData.PurchaseForActivity AS PurchaseForActivity,
	|	CASE
	|		WHEN DocumentData.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
	|				AND DocumentData.ReceiptUnderOrders
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS SettlementsAgainstOrders,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusinessCostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusinessSIsAccountingOfVendorsARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.SalesOpportunity AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunitySeparateAccountingOfItemsForSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.DocumentAmount                 AS DocumentAmount,
	|	DocumentData.IncomingDocumentDate         AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber        AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Number                          AS Number,
	|	DocumentData.Comment                    AS Comment,
	|	DocumentData.DeletionMark                AS DeletionMark,
	|	DocumentData.Posted                       AS Posted,
	|	DocumentData.Author                          AS Author,
	|	DocumentData.NewWayToCreateApplicationForGoodsImportFromEAEU AS NewWayToCreateApplicationForGoodsImportFromEAEU,
	|	BusinessTransactionsSettings.Ref          AS BusinessTransactionSetting,
	|	DocumentData.ActualTransactionDate        AS AdjustmentPeriod_
	|FROM
	|	DocumentDataHeader AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentData.Contract = CounterpartyContracts.Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
		
	Query.SetParameter("LocalAccountingCurrency",             Attributes.LocalAccountingCurrency);
	Query.SetParameter("RegulatedAccountingCurrency",             Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",                 Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("PriceIncludesVAT",                            ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses",      GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	Query.SetParameter("PriceIncludesVATOfDocument",                   Attributes.PriceIncludesVAT);
	Query.SetParameter("ReceiptUnderSeveralOrders",             ?(Not ValueIsFilled(Attributes.PurchaseOrder), True, False));
	Query.SetParameter("ControlIssueOfCashByPurposes",  GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Query.SetParameter("ReusablePackage",                         Enums.ItemsTypes.ReusablePackage);
	Query.SetParameter("BusinessTransactionsImportPurchase",				PurchasesServer.BusinessOperationsOnMain(
																				Enums.BusinessTransactions.PurchaseByImport));
	Query.SetParameter("BusinessTransactionsPurchasingFromSupplier",				PurchasesServer.BusinessOperationsOnMain(
																				Enums.BusinessTransactions.PurchaseFromSupplier));
	Query.SetParameter("BusinessTransactionsProcurementInEAEUCountries",				PurchasesServer.BusinessOperationsOnMain(
																				Enums.BusinessTransactions.ImportFromEAEU));
																				
	Query.SetParameter("BusinessTransactionsDeliveryUnderPrincipal",	PurchasesServer.BusinessOperationsForAgencyProcurementUnderPrincipal());
	Query.SetParameter("MetadataIdentifier",                    Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("StartDateOfPrintingSingleExpenseReport",    Constants.StartDateOfPrintingSingleExpenseReport.Get());
	Query.SetParameter("AccountingForLBCosts",                Attributes.AccountingForLBCosts);
	Query.SetParameter("AccountingForSettlementsWithSuppliersUnderLB", Attributes.AccountingForSettlementsWithSuppliersUnderLB);
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("IDCustomsDeclarationImport", Common.MetadataObjectID("Document.CCDImport"));
	Query.SetParameter("IdApplicationForImportOfGoods", Common.MetadataObjectID("Document.ApplicationForImportationOfGoods")); 
	
	InvoicingOperations = New Array;
	InvoicingOperations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	InvoicingOperations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	
	ObjectData = Common.ObjectAttributesValues(Attributes.Contract, 
		"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
	UnfacturedDeliveriesOfServicesWorks = InvoicingOperations.Find(Attributes.BusinessOperation) <> Undefined
		And (ObjectData.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
		Or ObjectData.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced);
	
	Query.SetParameter("UnfacturedDeliveriesOfServicesWorks", UnfacturedDeliveriesOfServicesWorks);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	Query.SetParameter("DateOfRemainingGoods", New Boundary(DocumentRef.PointInTime(), BoundaryType.Excluding));
	
	DimensionInventoryItemsWithoutManAssignment = False;
	If Attributes.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
		DimensionInventoryItemsWithoutManAssignment = DimensionInventoryItemsWithoutManAssignment(Query)
	EndIf;
	Query.SetParameter("DimensionInventoryItemsWithoutManAssignment", DimensionInventoryItemsWithoutManAssignment);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests);
	QueryTextDocumentDataBatchTable(ListOfRequests);
	QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests);
	QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = "SELECT
	|	HeaderData_.DataVersion AS DataVersion,
	|	HeaderData_.Date AS Date,
	|	HeaderData_.PointInTime AS PointInTime,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.Ref AS Ref,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.Partner AS Partner,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.Department AS Department,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.DocumentAmount AS DocumentAmount,
	|	HeaderData_.AmountARAPByOrder AS AmountARAPByOrder,
	|	HeaderData_.Manager AS Manager,
	|	HeaderData_.PurchaseOrder AS PurchaseOrder,
	|	HeaderData_.AdvanceHolder AS AdvanceHolder,
	|	HeaderData_.PriceIncludesVAT AS PriceIncludesVAT,
	|	HeaderData_.ARAPCurrency AS ARAPCurrency,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.PurchaseForActivity AS PurchaseForActivity,
	|	HeaderData_.PaymentMethod AS PaymentMethod,
	|	HeaderData_.Approved AS Approved,
	|	HeaderData_.VATTaxation AS VATTaxation,
	|	HeaderData_.AmountARAP AS AmountARAP,
	|	HeaderData_.CompanyBankAccount AS CompanyBankAccount,
	|	HeaderData_.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	HeaderData_.IncomingDocumentDate AS IncomingDocumentDate,
	|	HeaderData_.Shipper AS Shipper,
	|	HeaderData_.CounterpartyBankAccount AS CounterpartyBankAccount,
	|	HeaderData_.ShipperBankAccount AS ShipperBankAccount,
	|	HeaderData_.SalesOpportunity AS SalesOpportunity,
	|	HeaderData_.ReceivedBy AS ReceivedBy,
	|	HeaderData_.AcceptedPosition AS AcceptedPosition,
	|	HeaderData_.ReceiptUnderOrders AS ReceiptUnderOrders,
	|	HeaderData_.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	HeaderData_.RegisterVendorPrices AS RegisterVendorPrices,
	|	HeaderData_.Contract AS Contract,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.Director AS Director,
	|	HeaderData_.ARAPObjectSettings AS ARAPObjectSettings,
	|	HeaderData_.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	HeaderData_.ReusablePackagesReturnDate AS ReusablePackagesReturnDate,
	|	HeaderData_.ReusablePackageFillingStatus AS ReusablePackageFillingStatus,
	|	HeaderData_.PackageDepositIsRequired AS PackageDepositIsRequired,
	|	HeaderData_.SubsequentDeliveryByDocument AS SubsequentDeliveryByDocument,
	|	HeaderData_.AdvancePurpose AS AdvancePurpose,
	|	HeaderData_.DocumentsCount AS DocumentsCount,
	|	HeaderData_.SheetQuantity AS SheetQuantity,
	|	HeaderData_.ChiefAccountant AS ChiefAccountant,
	|	HeaderData_.CashFlowItem AS CashFlowItem,
	|	HeaderData_.DeliveryMethod AS DeliveryMethod,
	|	HeaderData_.CarrierPartner AS CarrierPartner,
	|	HeaderData_.DeliveryZone AS DeliveryZone,
	|	HeaderData_.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	HeaderData_.DeliveryTimeTo AS DeliveryTimeTo,
	|	HeaderData_.DeliveryAddress AS DeliveryAddress,
	|	HeaderData_.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	HeaderData_.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	HeaderData_.DeliveryAddressOfCarrier AS DeliveryAddressOfCarrier,
	|	HeaderData_.DeliveryAddressOfCarrierFieldValues AS DeliveryAddressOfCarrierFieldValues,
	|	HeaderData_.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	HeaderData_.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.ThereAreAlcoholicProducts AS ThereAreAlcoholicProducts,
	|	HeaderData_.Terms AS Terms,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.CourseNumerator AS CourseNumerator,
	|	HeaderData_.CourseDenominator AS CourseDenominator,
	|	HeaderData_.ThereAreProductsMarkedWithSPMS AS ThereAreProductsMarkedWithSPMS,
	|	HeaderData_.ThereAreSPMSControlIdentificationMarks AS ThereAreSPMSControlIdentificationMarks,
	|	HeaderData_.GoodsReceiptOption AS GoodsReceiptOption,
	|	HeaderData_.ServiceReceiptOption AS ServiceReceiptOption,
	|	HeaderData_.ControlledLotReference AS ControlledLotReference,
	|	HeaderData_.AmountARAPByPackage AS AmountARAPByPackage,
	|	HeaderData_.ExpenseReport AS ExpenseReport,
	|	HeaderData_.ExternalDocumentName AS ExternalDocumentName,
	|	HeaderData_.ForeignCurrencyTransaction AS ForeignCurrencyTransaction,
	|	HeaderData_.DeliveryAddressValue AS DeliveryAddressValue,
	|	HeaderData_.DeliveryAddressOfCarrierValue AS DeliveryAddressOfCarrierValue,
	|	HeaderData_.AdjustmentOfStockWithProductBatchID AS AdjustmentOfStockWithProductBatchID,
	|	HeaderData_.DateOfReceipt AS DateOfReceipt,
	|	CASE WHEN HeaderData_.DocumentExchangeRateDate = DATETIME(1,1,1)
	|			THEN HeaderData_.Date
	|			ELSE HeaderData_.DocumentExchangeRateDate
	|	END AS DocumentExchangeRateDate,
	|	HeaderData_.NewWayToCreateApplicationForGoodsImportFromEAEU AS NewWayToCreateApplicationForGoodsImportFromEAEU,
	|	HeaderData_.ObjectOfManCalculations AS ObjectOfManCalculations,
	|	HeaderData_.Organization.LocalAccountingCurrency AS CompanyLocalAccountingCurrency,
	|	HeaderData_.Counterparty.RegistrationCountry AS CounterpartyCountryOfResidence,
	|	HeaderData_.Terms.Currency AS AgreementCurrency_,
	|	HeaderData_.Terms.PriceIncludesVAT AS AgreementPriceIncludesVAT,
	|	HeaderData_.Department.OptionOfAssignedAccountingOfGoods AS SubdivisionIsVariantOfSeparateAccountingOfItems,
	|	HeaderData_.LineOfBusiness.CostAccounting AS LineOfBusinessCostAccounting,
	|	HeaderData_.LineOfBusiness.VendorARAP AS LineOfBusinessSIsAccountingOfVendorsARAP,
	|	HeaderData_.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity AS SalesOpportunitySeparateAccountingOfItemsForSalesOpportunity,
	|	HeaderData_.Contract.ExecutionScheduleIsSpecified AS ContractExecutionScheduleIsSet,
	|	HeaderData_.ObjectOfManCalculations.UUID AS ARAPObjectOfManIsUniqueIdentifier,
	|	HeaderData_.ActualTransactionDate AS ActualTransactionDate
	|INTO DocumentDataHeader
	|FROM
	|	Document.VendorInvoice AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods = "SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.VendorPriceKind AS VendorPriceKind,
	|	GoodsTable.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsTable.ManualDiscount AS ManualDiscount,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.PurchaseOrder AS PurchaseOrder,
	|	GoodsTable.Certificate AS Certificate,
	|	GoodsTable.PassportNumber AS PassportNumber,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.SalesOpportunity AS SalesOpportunity,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	GoodsTable.AmountVATARAP AS AmountVATARAP,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.ToControlQuality AS ToControlQuality,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.ToExpenseAs AS ToExpenseAs,
	|	GoodsTable.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	GoodsTable.IncomingDocumentDate AS IncomingDocumentDate,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|	GoodsTable.ExternalDocumentName AS ExternalDocumentName,
	|	GoodsTable.AmountTotal AS AmountTotal,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts,
	|	GoodsTable.Purpose.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
	|	GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt AS WarehouseUseOrderSchemeWhenReceiving,
	|	GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt,
	|	GoodsTable.ItemsLocationAttributes.Purpose AS ItemsLocationAttributesAssignment,
	|	GoodsTable.ItemsLocationAttributes.Products AS AnalysisOfAccountingForProductsProducts,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods AS
	|		InventoryLocationAttributeOfItemOfItemThatIsBeingTracked,
	|	GoodsTable.ItemsLocationAttributes.Characteristic AS AnalysisOfAccountingProductsCharacteristics,
	|	GoodsTable.ItemsLocationAttributes.Series AS InventoryLocationAttributeAnalysisBatch,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation AS ProductAccountingAnalyticsStorageLocation,
	|	GoodsTable.ItemsLocationAttributes.ProductCostElement AS InventoryLocationAttributeOfItemIsProductCostElementAnalysis,
	|	GoodsTable.Purpose.VATActivityType AS PurposeOfVATSTaxationOfTypeOfActivity,
	|	GoodsTable.Purpose.AssignmentType AS AssignmentTypeOfAssignment,
	|	GoodsTable.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier,
	|	GoodsTable.Products.TracedGoods AS ItemOfTraceableItem,
	|	GoodsTable.Warehouse.ShopFloorStockroom AS WarehouseShopFloorStockroom,
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS
	|		InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
	|	GoodsTable.ARAPObject.LineOfBusiness AS ARAPObjectLineOfBusiness,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.ItemsLocationAttributes.Products.ItemsType AS
	|		InventoriedLocationAttributesItemTypeOfItem,
	|	GoodsTable.PurchaseOrder.RegisterVendorPrices AS PurchaseOrderRegisterVendorPrices,
	|	GoodsTable.VendorPriceKind.Currency AS VendorPriceTypeCurrency
	|INTO DocumentDataTableItems
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataTableOfInventoryOwnerAttributes(ListOfRequests)
	
	QueryTextTableInventoryKinds = "SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.Ref AS Ref,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.PurchaseOrder AS PurchaseOrder,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Price AS Price,
	|	TableTypesOfStocks_.VATRate AS VATRate,
	|	TableTypesOfStocks_.VATAmount AS VATAmount,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountIncludingVAT,
	|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
	|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
	|	TableTypesOfStocks_.ManualDiscount AS ManualDiscount,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.Department AS Department,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType AS
	|		InventoriedLocationAttributesItemTypeOfItem,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS AnalysisOfAccountingForProductsProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.TracedGoods AS
	|		InventoryLocationAttributeOfItemOfItemThatIsBeingTracked,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS AnalysisOfAccountingProductsCharacteristics,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS InventoryLocationAttributeAnalysisBatch,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS ProductAccountingAnalyticsStorageLocation,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS ItemsLocationAttributesAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributes.ProductCostElement AS InventoryLocationAttributeOfItemIsProductCostElementAnalysis,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Organization AS TypeOfInventoryOwnerAttributeCompany,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS TypeOfInventoryOwnerAttributeOwnerOfItem,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.VATTaxation AS TypeOfInventoryOwnerAttributeTaxationOfVAT,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.FinancialAccountingGroup AS InventoryOwnerAttributeFinancialAccountingGroup,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.ProductsGroup AS InventoryOwnerAttributeIsProductGroup,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.PriceKind AS InventoryOwnerAttributePriceType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SubjectToExcise AS InventoryOwnerAttributeIsSubjectToExciseDuty,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.BusinessUnitProduction AS InventoryOwnerAttributeDivisionOfProduction,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.KeepRecordsByCCD AS
	|		InventoriedLocationAttributeItemAccountingForCCD,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS
	|		InventoryInventoryLocationAttributeAnalysisWarehouseTerritoryShopFloorStockroom,
	|	TableTypesOfStocks_.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS
	|		InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.AssignmentType AS
	|		InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment
	|
	|INTO DocumentDataTableOfInventoryOwnerAttributes
	|FROM
	|	Document.VendorInvoice.InventoryKinds AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableInventoryKinds);
	
EndProcedure

Procedure QueryTextDocumentDataBatchTable(ListOfRequests)
	
	QueryTextTableSetOfSeries = "SELECT
	|	SeriesTable.LineNumber AS LineNumber,
	|	SeriesTable.Ref AS Ref,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	SeriesTable.Purpose AS Purpose,
	|	SeriesTable.Warehouse AS Warehouse,
	|	SeriesTable.Purpose.RecordsInWarehouseRegisters AS AssigningTrafficToWarehouseRegisters,
	|	SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt AS WarehouseUseOrderSchemeWhenReceiving,
	|	SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt AS WarehouseStartDateOfOrderSchemeUponReceipt
	|INTO DocumentDataBatchTable
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	ListOfRequests.Add(QueryTextTableSetOfSeries);
	
EndProcedure

Procedure QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests)

	QueryTextTablePaymentScheduleSteps = "SELECT
	|	TableStagesOfPaymentSchedule.LineNumber AS LineNumber,
	|	TableStagesOfPaymentSchedule.Ref AS Ref,
	|	TableStagesOfPaymentSchedule.OrderDocument AS OrderDocument,
	|	TableStagesOfPaymentSchedule.ExceedingOrder AS ExceedingOrder,
	|	TableStagesOfPaymentSchedule.PaymentOption AS PaymentOption,
	|	TableStagesOfPaymentSchedule.PaymentDate AS PaymentDate,
	|	TableStagesOfPaymentSchedule.Move AS Move,
	|	TableStagesOfPaymentSchedule.PaymentAmount AS PaymentAmount,
	|	TableStagesOfPaymentSchedule.PaymentPercentage AS PaymentPercentage,
	|	TableStagesOfPaymentSchedule.PackageDepositValue AS PackageDepositValue,
	|	TableStagesOfPaymentSchedule.PackageDepositPercentage AS PackageDepositPercentage,
	|	TableStagesOfPaymentSchedule.AmountARAP AS AmountARAP,
	|	TableStagesOfPaymentSchedule.AmountARAPByPackage AS AmountARAPByPackage,
	|	TableStagesOfPaymentSchedule.ARAPObject AS ARAPObject,
	|	TableStagesOfPaymentSchedule.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier,
	|	TableStagesOfPaymentSchedule.CalculateFrom AS CalculateFrom
	|INTO DocumentDataTableStagesOfPaymentSchedule
	|FROM
	|	Document.VendorInvoice.PaymentScheduleSteps AS TableStagesOfPaymentSchedule
	|WHERE
	|	TableStagesOfPaymentSchedule.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTablePaymentScheduleSteps);

EndProcedure

Procedure QueryTextDocumentDataTableDecryptionOfPayment(ListOfRequests)

	QueryTextTableARAPDetails = "SELECT
	|	PaymentDecryptionTable.LineNumber AS LineNumber,
	|	PaymentDecryptionTable.Ref AS Ref,
	|	PaymentDecryptionTable.Sum AS Sum,
	|	PaymentDecryptionTable.ARAPCurrency AS ARAPCurrency,
	|	PaymentDecryptionTable.AmountARAP AS AmountARAP,
	|	PaymentDecryptionTable.ARAPObject AS ARAPObject,
	|	PaymentDecryptionTable.ARAPObject.Organization AS ARAPObjectOfCompany,
	|	PaymentDecryptionTable.ARAPObject.Object AS CalculationObjectObject,
	|	PaymentDecryptionTable.ARAPObject.UUID AS ARAPObjectIsUniqueIdentifier
	|INTO DocumentDataTableDecryptionOfPayment
	|FROM
	|	Document.VendorInvoice.ARAPDetails AS PaymentDecryptionTable
	|WHERE
	|	PaymentDecryptionTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableARAPDetails);
	
EndProcedure

Function DimensionInventoryItemsWithoutManAssignment(Query)
	
	AnalystRequest = New Query("
	|SELECT TOP 1
	|	TRUE AS DimensionWithAppointment
	|FROM
	|	Document.VendorInvoice AS Purchase
	|	INNER JOIN AccumulationRegister.CompanyGoods AS RegisterRecords
	|		ON RegisterRecords.Recorder = Purchase.Ref
	|		AND RegisterRecords.Period = Purchase.Date
	|		AND RegisterRecords.Organization = VALUE(Catalog.Companies.ManagementCompany)
	|		AND RegisterRecords.ItemsLocationAttributes.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
	|WHERE
	|	Purchase.Ref = &Ref
	|	AND Purchase.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|
	|UNION
	|
	// The document does not yet have Registered Records for the register of "Goods of organizations" (the document has not yet been carried out). 
	|SELECT TOP 1
	|	TRUE AS DimensionWithAppointment
	|FROM
	|	Document.VendorInvoice AS Purchase
	|	LEFT JOIN AccumulationRegister.CompanyGoods AS RegisterRecords
	|		ON RegisterRecords.Recorder = Purchase.Ref
	|		AND RegisterRecords.Period = Purchase.Date
	|WHERE
	|	Purchase.Ref = &Ref
	|	AND Purchase.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|	AND RegisterRecords.Recorder IS NULL
	|");
	AnalystRequest.SetParameter("Ref", Query.Parameters.Ref);
	QueryResult = AnalystRequest.Execute();
	Return QueryResult.IsEmpty();
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query, DocumentObject = Undefined)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	GoodsTable.AnalysisOfAccountingForProductsProducts AS Products,
	|	GoodsTable.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	GoodsTable.InventoryLocationAttributeAnalysisBatch AS Series,
	|	GoodsTable.ProductAccountingAnalyticsStorageLocation AS StorageLocation
	|INTO TTAnalyticsToCreation
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.AnalysisOfAccountingForProductsProducts = Dimension.Products
	|			AND GoodsTable.AnalysisOfAccountingProductsCharacteristics = Dimension.Characteristic
	|			AND GoodsTable.InventoryLocationAttributeAnalysisBatch = Dimension.Series
	|			AND GoodsTable.ProductAccountingAnalyticsStorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND (NOT &KeepRecordsOfInventoryCostByAssignments
	|		OR &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal))
	|	AND GoodsTable.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	GoodsTable.AnalysisOfAccountingForProductsProducts AS Products,
	|	GoodsTable.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	GoodsTable.ItemsLocationAttributesAssignment AS Purpose,
	|	GoodsTable.InventoryLocationAttributeAnalysisBatch AS Series,
	|	GoodsTable.Warehouse AS StorageLocation
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByWarehouses
	|	ON DimensionByWarehouses.Products = GoodsTable.AnalysisOfAccountingForProductsProducts
	|		AND DimensionByWarehouses.Characteristic = GoodsTable.AnalysisOfAccountingProductsCharacteristics
	|		AND DimensionByWarehouses.Series = GoodsTable.InventoryLocationAttributeAnalysisBatch
	|		AND DimensionByWarehouses.Purpose = GoodsTable.ItemsLocationAttributesAssignment
	|		AND DimensionByWarehouses.ProductCostElement = GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByWarehouses.StorageLocation = GoodsTable.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND DimensionByWarehouses.Products IS NULL
	|	AND GoodsTable.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|UNION ALL
	|
	// Analytics of traceable works
	|SELECT DISTINCT
	|	GoodsTable.AnalysisOfAccountingForProductsProducts AS Products,
	|	GoodsTable.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	GoodsTable.ItemsLocationAttributesAssignment AS Purpose,
	|	GoodsTable.InventoryLocationAttributeAnalysisBatch AS Series,
	|	CASE
	|		WHEN
	|			GoodsTable.Ref.BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|			THEN
	|				GoodsTable.Ref.Department
	|			ELSE
	|				GoodsTable.Department
	|	END AS StorageLocation
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = GoodsTable.AnalysisOfAccountingForProductsProducts
	|		AND DimensionByBusinessUnits.Characteristic = GoodsTable.AnalysisOfAccountingProductsCharacteristics
	|		AND DimensionByBusinessUnits.Series = GoodsTable.InventoryLocationAttributeAnalysisBatch
	|		AND DimensionByBusinessUnits.Purpose = GoodsTable.ItemsLocationAttributesAssignment
	|		AND DimensionByBusinessUnits.ProductCostElement = GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByBusinessUnits.StorageLocation = 
	|			CASE
	|				WHEN 
	|					GoodsTable.Ref.BusinessOperation IN (
	|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|					THEN
	|						GoodsTable.Ref.Department
	|					ELSE
	|						GoodsTable.Department
	|			END
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND GoodsTable.AnalysisOfAccountingForProductsProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.AnalysisOfAccountingForProductsProducts.TracedGoods
	|	AND DimensionByBusinessUnits.Products IS NULL
	|	AND GoodsTable.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|UNION ALL
	|
	// With a two-way analytics with a batch at cost may be in TS types of supplies, and may not be in TS Products.
	// At the same time, a Warehouse is required, which is available only in TS Goods.
	|SELECT DISTINCT
	|	GoodsTable.AnalysisOfAccountingForProductsProducts AS Products,
	|	GoodsTable.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	GoodsTable.ItemsLocationAttributesAssignment AS Purpose,
	|	GoodsTable.InventoryLocationAttributeAnalysisBatch AS Series,
	|	TableWarehouses_.Warehouse AS StorageLocation
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS GoodsTable
	|	INNER JOIN DocumentDataTableItems AS TableWarehouses_
	|	ON GoodsTable.Ref = TableWarehouses_.Ref
	|		AND GoodsTable.AnalysisOfAccountingForProductsProducts = TableWarehouses_.AnalysisOfAccountingForProductsProducts
	|		AND GoodsTable.AnalysisOfAccountingProductsCharacteristics = TableWarehouses_.AnalysisOfAccountingProductsCharacteristics
	|		AND GoodsTable.ItemsLocationAttributesAssignment = TableWarehouses_.ItemsLocationAttributesAssignment
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByWarehouses
	|	ON DimensionByWarehouses.Products = GoodsTable.AnalysisOfAccountingForProductsProducts
	|		AND DimensionByWarehouses.Characteristic = GoodsTable.AnalysisOfAccountingProductsCharacteristics
	|		AND DimensionByWarehouses.Series = GoodsTable.InventoryLocationAttributeAnalysisBatch
	|		AND DimensionByWarehouses.Purpose = GoodsTable.ItemsLocationAttributesAssignment
	|		AND DimensionByWarehouses.ProductCostElement = GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByWarehouses.StorageLocation = TableWarehouses_.Warehouse
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND DimensionByWarehouses.Products IS NULL
	|	AND GoodsTable.ItemsLocationAttributes <> VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef)
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.StorageLocation AS StorageLocation
	|FROM
	|	TTAnalyticsToCreation AS GoodsTable
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.StorageLocation
	|
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAnalyticsToCreation
	|";
	
	If DocumentObject = Undefined Then
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "GoodsTable.AnalysisOfAccountingForProductsProducts", "GoodsTable.ItemsLocationAttributes.Products");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "GoodsTable.AnalysisOfAccountingProductsCharacteristics", "GoodsTable.ItemsLocationAttributes.Characteristic");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "GoodsTable.InventoryLocationAttributeAnalysisBatch", "GoodsTable.ItemsLocationAttributes.Series");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "GoodsTable.ProductAccountingAnalyticsStorageLocation", "GoodsTable.ItemsLocationAttributes.StorageLocation");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "GoodsTable.ItemsLocationAttributesAssignment", "GoodsTable.ItemsLocationAttributes.Purpose");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "TableWarehouses_.AnalysisOfAccountingForProductsProducts", "TableWarehouses_.ItemsLocationAttributes.Products");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "TableWarehouses_.AnalysisOfAccountingProductsCharacteristics", "TableWarehouses_.ItemsLocationAttributes.Characteristic");
		QueryAnalyst.Text = StrReplace(QueryAnalyst.Text, "TableWarehouses_.ItemsLocationAttributesAssignment", "TableWarehouses_.ItemsLocationAttributes.Purpose");
	EndIf;
	
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("BusinessOperation", Query.Parameters.BusinessOperation);
	QueryAnalyst.SetParameter("UseTraceableImportedGoodsAccounting",
		Query.Parameters.UseTraceableImportedGoodsAccounting);
	QueryAnalyst.SetParameter("UninvoicedReceiptDocumentIsUsed", Query.Parameters.UninvoicedReceiptDocumentIsUsed);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestForAnalytics = New Query;
	RequestForAnalytics.TempTablesManager = Query.TempTablesManager;
	RequestForAnalytics.Text = "
	|SELECT DISTINCT
	|	ARAPDetails.ARAPObject AS ARAPObject,
	|	ISNULL(ARAPDetails.ARAPObject.Contract,VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS Contract,
	|	ISNULL(ARAPDetails.ARAPObject.LineOfBusiness,VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness
	|INTO TableOfCalculationObjects
	|FROM
	|	Document.VendorInvoice.ARAPDetails AS ARAPDetails
	|	
	|WHERE
	|	ARAPDetails.Ref = &Ref
	|	
	|INDEX BY
	|	ARAPObject
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	&Organization AS Organization,
	|	&Contract 	 AS Contract,
	|	&Counterparty  AS Counterparty,
	|	&Partner 	 AS Partner,
	|	Stages.ARAPObject.LineOfBusiness AS LineOfBusiness 
	|FROM
	|	Document.VendorInvoice.PaymentScheduleSteps AS Stages
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&Organization = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND &Partner = Dimension.Partner
	|		AND &Contract = Dimension.Contract
	|		AND Stages.ARAPObject.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Stages.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	&OrganizationOfMan                                 AS Organization,
	|	TableOfCalculationObjects.Contract                 AS Contract,
	|	&Counterparty                                     AS Counterparty,
	|	&Partner                                        AS Partner,
	|	TableOfCalculationObjects.LineOfBusiness AS LineOfBusiness 
	|FROM
	|	TableOfCalculationObjects AS TableOfCalculationObjects
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON
	|		&OrganizationOfMan = Dimension.Organization
	|		AND &Counterparty = Dimension.Counterparty
	|		AND &Partner = Dimension.Partner
	|		AND TableOfCalculationObjects.Contract = Dimension.Contract
	|		AND TableOfCalculationObjects.LineOfBusiness = Dimension.LineOfBusiness
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|";
	
	RequestForAnalytics.SetParameter("Ref",                	 Query.Parameters.Ref);
	RequestForAnalytics.SetParameter("Organization",           	 Query.Parameters.Organization); 
	RequestForAnalytics.SetParameter("OrganizationOfMan",          Catalogs.Companies.ManagementCompany);
	RequestForAnalytics.SetParameter("Counterparty",            	 Query.Parameters.Counterparty);
	RequestForAnalytics.SetParameter("Partner",       			 Query.Parameters.Partner);
	RequestForAnalytics.SetParameter("Contract",       			 Query.Parameters.Contract);
	RequestForAnalytics.SetParameter("LineOfBusiness", Query.Parameters.LineOfBusiness);
	RequestForAnalytics.SetParameter("SettlementsAgainstOrders", 		 Query.Parameters.SettlementsAgainstOrders);
	RequestForAnalytics.SetParameter("BusinessOperation",	 Query.Parameters.BusinessOperation);
	
	Selection = RequestForAnalytics.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If DocumentObject = Undefined Or DocumentObject.ReceiptUnderOrders Then
				
	QueryText = "
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Date                   AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE
	|			VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                  AS Warehouse,
	|	GoodsTable.Count               AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND DocumentData.ReceiptUnderOrders
	|	AND GoodsTable.RowCode <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Date                   AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                  AS Warehouse,
	|	0                                      AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.RowCode = 0
	|	AND DocumentData.ReceiptUnderOrders
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	DocumentData.Date                   AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END                                  AS Warehouse,
	|	0                                      AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.RowCode = 0
	|	AND DocumentData.ReceiptUnderOrders
	|
	|";
	
	Else
		Return "";
	EndIf;
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		Return;
	EndIf;
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DocumentDataHeader.Contract                AS Contract,
	|	DocumentDataHeader.Terms             AS Terms,
	|	DocumentDataHeader.GoodsReceiptOption  AS GoodsReceiptOption,
	|	DocumentDataHeader.ServiceReceiptOption    AS ServiceReceiptOption,
	|	
	|	CASE WHEN DocumentDataHeader.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DocumentDataHeader.DateOfReceipt
	|			ELSE
	|				DocumentDataHeader.Date
	|		END AS Date,
	|	
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DocumentDataHeader.ControlledLotReference    AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DocumentDataHeader.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN DocumentDataHeader.AdvanceHolder
	|		ELSE DocumentDataHeader.Partner
	|	END                                        AS Sender,
	|	DocumentDataHeader.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DocumentDataHeader.ReceiptUnderOrders   AS ReceiptUnderOrders
	|FROM
	|	DocumentDataTableItems AS DataSource
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON DataSource.Ref = DocumentDataHeader.Ref
	|WHERE
	|	NOT DataSource.ToExpenseAs
	|	AND DataSource.Count > 0";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_,, True);
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers, DocumentObject)

	// Checking for non-use of the two-way scheme.
	If Not ((DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.ImportGoodsInTransit)
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		Return;
	EndIf;
	
	RegisterOfGoodsInWarehouses = "ProductStock";
	RegisterOfGoodsToBeReceived = "GoodsToReceive";
	ThereIsRegisterOfGoodsInWarehouses = False;
	ThereIsRegisterOfGoodsForReceipt = False;
	
	If ValueIsFilled(Registers) Then
		If TypeOf(Registers) = Type("String")
			And Registers = RegisterOfGoodsInWarehouses Then
			ThereIsRegisterOfGoodsInWarehouses = True;
		EndIf;
		If TypeOf(Registers) = Type("String")
			And Registers = RegisterOfGoodsToBeReceived Then
			ThereIsRegisterOfGoodsForReceipt = True;
		EndIf;
		
		If TypeOf(Registers) = Type("Structure")
			And Registers.Property(RegisterOfGoodsInWarehouses) Then
			ThereIsRegisterOfGoodsInWarehouses = True;
		EndIf;
		If TypeOf(Registers) = Type("Structure")
			And Registers.Property(RegisterOfGoodsToBeReceived) Then
			ThereIsRegisterOfGoodsForReceipt = True;
		EndIf;
	EndIf;
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DocumentDataHeader.Contract                 AS Contract,
	|	DocumentDataHeader.Terms              AS Terms,
	|	DocumentDataHeader.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DocumentDataHeader.Date                    AS Date,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DocumentDataHeader.ControlledLotReference    AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DocumentDataHeader.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN DocumentDataHeader.AdvanceHolder
	|		ELSE DocumentDataHeader.Partner
	|	END                                        AS Sender,
	|	DocumentDataHeader.BusinessOperation   AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DocumentDataHeader.ReceiptUnderOrders    AS ReceiptUnderOrders,
	|	DataSource.Count < 0                AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	DocumentDataTableItems AS DataSource
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON DataSource.Ref = DocumentDataHeader.Ref
	|WHERE
	|	NOT DataSource.ToExpenseAs
	|	
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.VendorInvoice;
	
	If ThereIsRegisterOfGoodsInWarehouses Then
		WarehousesServer.CreateReceiptOfGoodsOnOneWayBasis(Query,
			QueryTexts,
			RegisterOfGoodsInWarehouses,
			QueryTextDocument_,
			CurrentMetadataObject1,
			"SetOfSeries");
	EndIf;
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DocumentDataHeader.Contract                 AS Contract,
	|	DocumentDataHeader.Terms              AS Terms,
	|	DocumentDataHeader.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DocumentDataHeader.Date                    AS Date,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DocumentDataHeader.ControlledLotReference    AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DocumentDataHeader.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN DocumentDataHeader.AdvanceHolder
	|		ELSE DocumentDataHeader.Partner
	|	END                                        AS Sender,
	|	DocumentDataHeader.BusinessOperation   AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DocumentDataHeader.ReceiptUnderOrders    AS ReceiptUnderOrders,
	|	FALSE                                         AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	DocumentDataTableItems AS DataSource
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON DataSource.Ref = DocumentDataHeader.Ref
	|WHERE
	|	NOT DataSource.ToExpenseAs
	// Clipping adjustments with a negative amount.
	|	AND DataSource.Count > 0
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.VendorInvoice;
	
	If ThereIsRegisterOfGoodsForReceipt Then
		WarehousesServer.CreateReceiptOfGoodsOnOneWayBasis(Query,
			QueryTexts,
			RegisterOfGoodsToBeReceived,
			QueryTextDocument_,
			CurrentMetadataObject1,
			"SetOfSeries");
	EndIf;

EndProcedure

Procedure ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, DocumentObject)

// Checking for non-use of the two-way scheme.
	If Not ((DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit)
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		Return;
	EndIf;
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DocumentDataHeader.Contract                 AS Contract,
	|	DocumentDataHeader.Terms              AS Terms,
	|	DocumentDataHeader.GoodsReceiptOption   AS GoodsReceiptOption,
	|	DocumentDataHeader.ServiceReceiptOption     AS ServiceReceiptOption,
	|	DocumentDataHeader.Date                    AS Date,
	|	
	|	CASE WHEN DocumentDataHeader.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DocumentDataHeader.DateOfReceipt
	|			ELSE
	|				DocumentDataHeader.Date
	|		END AS DateOfPlannedReceipt,
	|	
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DocumentDataHeader.ControlledLotReference    AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DocumentDataHeader.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	CASE
	|		WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN DocumentDataHeader.AdvanceHolder
	|		ELSE DocumentDataHeader.Partner
	|	END                                        AS Sender,
	|	DocumentDataHeader.BusinessOperation   AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DocumentDataHeader.ReceiptUnderOrders   AS ReceiptUnderOrders
	|FROM
	|	DocumentDataTableItems AS DataSource
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON DataSource.Ref = DocumentDataHeader.Ref
	|WHERE
	|	NOT DataSource.ToExpenseAs
	|
	|";
	
	WarehousesServer.ToIssuePurchaseOfGoodsOnDvukhodovka(Query, QueryTexts, Registers, QueryTextDocument_, ,True);

EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	
		|	CASE
		|		WHEN TabPart.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN TabPart.Warehouse
		|		ELSE TabPart.Department
		|	END AS Warehouse,
		|	
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Ref.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	
		|	TabPart.Ref.ReceiptUnderOrders AND TabPart.RowCode <> 0 AS OnSchedule,
		|	
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					AND TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|				OR TabPart.Products.ItemsType IN(
		|						VALUE(Enum.ItemsTypes.OwnGoods),
		|						VALUE(Enum.ItemsTypes.ReusablePackage))
		|					AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|					AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|				OR TabPart.Products.ItemsType IN(
		|						VALUE(Enum.ItemsTypes.OwnGoods),
		|						VALUE(Enum.ItemsTypes.ReusablePackage))
		|					AND TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|			THEN 
		|				CASE
		|					WHEN 
		|						CASE
		|							WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|								THEN TabPart.Ref.ServiceReceiptOption
		|							ELSE TabPart.Ref.GoodsReceiptOption
		|						END IN (
		|							VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), 
		|							VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|						THEN TabPart.Ref.Terms
		|					WHEN 
		|						CASE
		|							WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|								THEN TabPart.Ref.ServiceReceiptOption
		|							ELSE TabPart.Ref.GoodsReceiptOption
		|						END IN (
		|							VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|						THEN TabPart.Ref.Contract
		|					ELSE TabPart.PurchaseOrder
		|				END
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.VendorInvoice.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|		AND NOT TabPart.ToExpenseAs
		|		AND (TabPart.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|				AND (NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|					OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date)
		|				AND NOT TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|			OR TabPart.Products.ItemsType IN(
		|					VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|				AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|			OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|				AND NOT (TabPart.Ref.BusinessOperation IN(
		|							VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|							VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|				AND ISNULL(TabPart.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced),
		|							FALSE)))";
		
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
		
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.VendorInvoice.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|		AND NOT TabPart.ToExpenseAs
		|		AND TabPart.Products.ItemsType IN(
		|			VALUE(Enum.ItemsTypes.OwnGoods),
		|			VALUE(Enum.ItemsTypes.ReusablePackage))
		|		AND NOT TabPart.ToExpenseAs
		|		AND TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND (TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|			OR TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|					VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)))";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType IN(
		|				VALUE(Enum.ItemsTypes.OwnGoods),
		|				VALUE(Enum.ItemsTypes.ReusablePackage))
		|			THEN TabPart.Warehouse
		|		ELSE TabPart.Department
		|	END AS Warehouse,
		|	
		|	CASE WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE THEN
		|				VALUE(Catalog.Assignments.EmptyRef)
		|			ELSE
		|				TabPart.Purpose
		|		END AS Purpose,
		|	
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	
		|	CASE
		|		WHEN 
		|			CASE
		|				WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					THEN TabPart.Ref.ServiceReceiptOption
		|				ELSE TabPart.Ref.GoodsReceiptOption
		|			END IN (
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), 
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN 
		|			CASE
		|				WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					THEN TabPart.Ref.ServiceReceiptOption
		|				ELSE TabPart.Ref.GoodsReceiptOption
		|			END IN (
		|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		WHEN 
		|			CASE
		|				WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					THEN TabPart.Ref.ServiceReceiptOption
		|				ELSE TabPart.Ref.GoodsReceiptOption
		|			END = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|				OR NOT TabPart.Ref.ReceiptUnderOrders
		|			THEN TabPart.Ref
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
		|				TabPart.Ref.DateOfReceipt
		|			ELSE
		|				TabPart.Ref.Date
		|		END AS DateOfReceipt,
		|	
		|	TRUE AS AvailableForConsumption,
		|	TabPart.Ref.ReceiptUnderOrders AND TabPart.RowCode <> 0 AS OnSchedule,
		|	
		|	CASE
		|		WHEN 
		|			CASE
		|				WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					THEN TabPart.Ref.ServiceReceiptOption
		|				ELSE TabPart.Ref.GoodsReceiptOption
		|			END IN (
		|				VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), 
		|				VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN 
		|			CASE
		|				WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|					THEN TabPart.Ref.ServiceReceiptOption
		|				ELSE TabPart.Ref.GoodsReceiptOption
		|			END IN (
		|				VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), 
		|				VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule,
		|	
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	Document.VendorInvoice.Goods AS TabPart
		|WHERE
		|	TabPart.Ref.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
		|		AND NOT TabPart.ToExpenseAs
		|		AND (TabPart.Products.ItemsType IN (
		|					VALUE(Enum.ItemsTypes.OwnGoods), 
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|				AND (TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|					OR NOT TabPart.Ref.ReceiptUnderOrders
		|					OR TabPart.RowCode = 0)
		|				AND (TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|						AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|					OR TabPart.Ref.BusinessOperation IN(
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|						VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|						VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)))
		|			OR TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|				AND TabPart.Ref.ServiceReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|				AND TabPart.Ref.ReceiptUnderOrders
		|				AND TabPart.RowCode = 0
		|				AND TabPart.Ref.BusinessOperation IN(
		|					VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|					VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))
		|				AND ISNULL(TabPart.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced),
		|					FALSE))";	
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssigningTrafficToWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	SeriesTable.Warehouse AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS WareroomOfRecipient,
	|	&Partner AS Sender,
	|	VALUE(Enum.WarehouseTransactions.ReceiptFromVendor) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	CASE
	|		WHEN (NOT SeriesTable.WarehouseUseOrderSchemeWhenReceiving
	|				OR &Period < SeriesTable.WarehouseStartDateOfOrderSchemeUponReceipt)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	DocumentDataBatchTable AS SeriesTable
	|WHERE
	|	SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssigningTrafficToWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END,
	|	SeriesTable.Series,
	|	SeriesTable.Count,
	|	SeriesTable.Warehouse,
	|	VALUE(Catalog.Warerooms.EmptyRef),
	|	&Partner,
	|	VALUE(Enum.WarehouseTransactions.ReceiptFromVendor),
	|	&Ref,
	|	&Period,
	|	&Ref,
	|	CASE
	|		WHEN (NOT SeriesTable.WarehouseUseOrderSchemeWhenReceiving
	|				OR &Period < SeriesTable.WarehouseStartDateOfOrderSchemeUponReceipt)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	DocumentDataTableItems AS SeriesTable
	|WHERE
	|	SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableReceivedReturnablePackaging(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ReceivedReturnablePackaging";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.ToReturnReusablePackage) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Count               AS Count,
	|	GoodsTable.AmountIncludingVAT                AS Sum,
	|	&Partner                               AS Partner,
	|	&Ref                                AS DocumentInflow,
	|	&PackageDepositIsRequired                  AS DepositIsRequired,
	|	
	|	CASE
	|		WHEN &PackageDepositIsRequired
	|			THEN &IDOfUnusedFinRecord
	|		ELSE GoodsTable.FinRecordID
	|	END                                  AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|	AND GoodsTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	BusinessTransactionsImportPurchasing = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	If Not (BusinessTransactionsImportPurchasing.Find(DocumentObject.BusinessOperation) = Undefined) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period							AS DateOfReceipt,
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.Purpose		AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber			AS CCDNumber
	|FROM
	|	TTTableProducts AS GoodsTable
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON GoodsTable.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND GoodsTable.Products = UninvoicedReceipts.Products
	|			AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic
	|			AND GoodsTable.Series = UninvoicedReceipts.Series
	|			AND GoodsTable.Purpose = UninvoicedReceipts.Purpose
	|			AND GoodsTable.CCDNumber = UninvoicedReceipts.CCDNumber
	|
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	|	AND NOT GoodsTable.ToExpenseAs
	// This is a traceable work regardless of the acceptance scheme, or the item (container) according to the one-way scheme.
	|	AND (
	|		(NOT &UninvoicedReceiptDocumentIsUsed
	|		AND (NOT &BusinessOperation IN(&BusinessTransactionsProcurementInEAEUCountries)
	|			OR NOT ISNULL(GoodsTable.TracedGoods, FALSE))
	|		AND GoodsTable.ItemsType IN(
	|				VALUE(Enum.ItemsTypes.OwnGoods),
	|				VALUE(Enum.ItemsTypes.ReusablePackage)
	|				))
	|		OR (&UseTraceableImportedGoodsAccounting
	|			AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods))
	|
	|ORDER BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Purpose,
	|	GoodsTable.CCDNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentObject = Undefined)  Export
	
	TableName = "TTProductsOfOrganizations";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocksForConnectingAnalytics", QueryTexts) Then
		QueryTextTTTypesOfStocksForConnectingAnalytics(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("VtProductsForAnalystConnection", QueryTexts) Then
		QueryTextVtProductsForAnalystConnection(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	// Odnohodovka
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				OR &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|INTO TTProductsOfOrganizations
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|
	|UNION ALL
	|
	// Traceable Work
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|				OR &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DimensionByBusinessUnits.DimensionKey AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnits
	|	ON DimensionByBusinessUnits.Products = GoodsTable.Products
	|		AND DimensionByBusinessUnits.Characteristic = GoodsTable.Characteristic
	|		AND DimensionByBusinessUnits.Series = GoodsTable.Series
	|		AND DimensionByBusinessUnits.Purpose = GoodsTable.Purpose
	|		AND DimensionByBusinessUnits.ProductCostElement = GoodsTable.ItemsLocationAttributes.ProductCostElement
	|		AND DimensionByBusinessUnits.StorageLocation = 
	|			CASE
	|				WHEN &UnfactuationOperationIsUsed
	|					THEN
	|						GoodsTable.Ref.Department
	|					ELSE
	|						GoodsTable.Department
	|			END
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5)
	|	AND GoodsTable.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked
	|	AND &UseTraceableImportedGoodsAccounting
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &BusinessOperation IN (&BusinessTransactionsImportPurchase)
	// One-way or one-way processing.
	|	AND (NOT &UninvoicedReceiptDocumentIsUsed
	|		OR &UninvoicedReceiptDocumentIsUsed
	|			AND &UnfactuationOperationIsUsed)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	VALUE(Catalog.Companies.ManagementCompany),
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType,
	|	GoodsTable.VATRate,
	|	GoodsTable.Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	(CASE
	|		WHEN &DimensionInventoryItemsWithoutManAssignment
	|			THEN AnalyticsWithoutAssignment.DimensionKey
	|		ELSE GoodsTable.DimensionKey END) AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.Companies.ManagementCompany) AS ShipmentCompany,
	|	FALSE AS Primary
	|FROM
	|	TTTypesOfStocksForConnectingAnalytics AS GoodsTable
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON GoodsTable.Products = AnalyticsWithoutAssignment.Products
	|			AND GoodsTable.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND GoodsTable.Series = AnalyticsWithoutAssignment.Series
	|			AND GoodsTable.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.Work_5),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|UNION ALL
	|
	// Two - way
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	GoodsTable.AnalysisOfAccountingForProductsProducts,
	|	GoodsTable.AnalysisOfAccountingProductsCharacteristics,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef),
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.Count,
	|	0 AS QuantityByGBRN,
	// On the contract.
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS GoodsTable
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.InventoriedLocationAttributesItemTypeOfItem IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND NOT &OperationOfImportingGoodsInTransitAndNonInvoicingIsUsed
	|	AND NOT GoodsTable.ToExpenseAs
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	TypesOfStocksWarehouse.InventoryType,
	|	GoodsTable.CCDNumber, 
	|	GoodsTable.CCDNumber.CCDNumberType,
	|	GoodsTable.VATRate,
	|	SUM(CASE
	|			WHEN DocumentGoods.Count < GoodsTable.Count
	|				THEN DocumentGoods.Count
	|			ELSE GoodsTable.Count
	|		END),
	|	SUM(CASE
	|			WHEN DocumentGoods.QuantityByGBRN < GoodsTable.QuantityByGBRN
	|				THEN DocumentGoods.QuantityByGBRN
	|			ELSE GoodsTable.QuantityByGBRN
	|		END) AS QuantityByGBRN,
	// To the warehouse.
	|	Dimension.DimensionKey AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|FROM
	|	TTTypesOfStocksForConnectingAnalytics AS GoodsTable
	|		INNER JOIN VtProductsForAnalystConnection AS DocumentGoods
	|		ON GoodsTable.Ref = DocumentGoods.Ref
	|			AND GoodsTable.PurchaseOrder = DocumentGoods.PurchaseOrder
	|			AND GoodsTable.DimensionKey.Products = DocumentGoods.ItemsLocationAttributes.Products
	|			AND GoodsTable.DimensionKey.CHARACTERISTIC = DocumentGoods.ItemsLocationAttributes.CHARACTERISTIC
	|			AND GoodsTable.DimensionKey.Purpose = DocumentGoods.ItemsLocationAttributes.Purpose
	|			AND (GoodsTable.DimensionKey.StorageLocation = DocumentGoods.ItemsLocationAttributes.StorageLocation
	|				OR (&Contract = DocumentGoods.ItemsLocationAttributes.StorageLocation
	|				AND &UninvoicedReceiptDocumentIsUsed
	|				AND NOT &UnfactuationOperationIsUsed)
	|			)
	|			AND (GoodsTable.DimensionKey.Series = DocumentGoods.ItemsLocationAttributes.Series
	|				OR DocumentGoods.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND GoodsTable.CCDNumber = DocumentGoods.CCDNumber
	|			AND GoodsTable.VATRate = DocumentGoods.VATRate
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND GoodsTable.Series = Dimension.Series
	|			AND GoodsTable.Purpose = Dimension.Purpose
	|			AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|			AND DocumentGoods.Warehouse = Dimension.StorageLocation
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = GoodsTable.TypeOfInventoryOwnerAttributeCompany
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = GoodsTable.TypeOfInventoryOwnerAttributeOwnerOfItem
	|			AND TypesOfStocksWarehouse.VATTaxation = GoodsTable.TypeOfInventoryOwnerAttributeTaxationOfVAT
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = GoodsTable.InventoryOwnerAttributeFinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = GoodsTable.InventoryOwnerAttributeIsProductGroup
	|			AND TypesOfStocksWarehouse.PriceKind = GoodsTable.InventoryOwnerAttributePriceType
	|			AND TypesOfStocksWarehouse.SubjectToExcise = GoodsTable.InventoryOwnerAttributeIsSubjectToExciseDuty
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (NOT &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|		OR NOT ISNULL(GoodsTable.TracedGoods, FALSE))
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND GoodsTable.KeepRecordsByCCD
	|	AND NOT GoodsTable.ToExpenseAs
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType,
	|	GoodsTable.VATRate,
	|	Dimension.DimensionKey
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense),
	|	&Period,
	|	&Organization,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	TypesOfStocksWarehouse.InventoryType,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	VALUE(Enum.CCDNumberTypes.EmptyRef),
	|	GoodsTable.VATRate AS VATRate,
	|	SUM(CASE
	|			WHEN DocumentGoods.Count < GoodsTable.Count
	|				THEN DocumentGoods.Count
	|			ELSE GoodsTable.Count
	|		END),
	|	0 AS QuantityByGBRN,
	// To the warehouse.
	|	Dimension.DimensionKey AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|FROM
	|	TTTypesOfStocksForConnectingAnalytics AS GoodsTable
	|		INNER JOIN VtProductsForAnalystConnection AS DocumentGoods
	|		ON GoodsTable.Ref = DocumentGoods.Ref
	|			AND GoodsTable.PurchaseOrder = DocumentGoods.PurchaseOrder
	|			AND GoodsTable.DimensionKey.Products = DocumentGoods.ItemsLocationAttributes.Products
	|			AND GoodsTable.DimensionKey.CHARACTERISTIC = DocumentGoods.ItemsLocationAttributes.CHARACTERISTIC
	|			AND GoodsTable.DimensionKey.Purpose = DocumentGoods.ItemsLocationAttributes.Purpose
	|			AND (GoodsTable.DimensionKey.StorageLocation = DocumentGoods.ItemsLocationAttributes.StorageLocation
	|				OR (&Contract = DocumentGoods.ItemsLocationAttributes.StorageLocation
	|				AND &UninvoicedReceiptDocumentIsUsed
	|				AND NOT &UnfactuationOperationIsUsed)
	|			)
	|			AND (GoodsTable.DimensionKey.Series = DocumentGoods.ItemsLocationAttributes.Series
	|				OR DocumentGoods.ItemsLocationAttributes.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|			AND GoodsTable.CCDNumber = DocumentGoods.CCDNumber
	|			AND GoodsTable.VATRate = DocumentGoods.VATRate
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND GoodsTable.Series = Dimension.Series
	|			AND GoodsTable.Purpose = Dimension.Purpose
	|			AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|			AND DocumentGoods.Warehouse = Dimension.StorageLocation
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|		ON TypesOfStocksWarehouse.Organization = GoodsTable.TypeOfInventoryOwnerAttributeCompany
	|			AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|			AND TypesOfStocksWarehouse.GoodsOwner = GoodsTable.TypeOfInventoryOwnerAttributeOwnerOfItem
	|			AND TypesOfStocksWarehouse.VATTaxation = GoodsTable.TypeOfInventoryOwnerAttributeTaxationOfVAT
	|			AND TypesOfStocksWarehouse.FinancialAccountingGroup = GoodsTable.InventoryOwnerAttributeFinancialAccountingGroup
	|			AND TypesOfStocksWarehouse.ProductsGroup = GoodsTable.InventoryOwnerAttributeIsProductGroup
	|			AND TypesOfStocksWarehouse.PriceKind = GoodsTable.InventoryOwnerAttributePriceType
	|			AND TypesOfStocksWarehouse.SubjectToExcise = GoodsTable.InventoryOwnerAttributeIsSubjectToExciseDuty
	|			AND NOT TypesOfStocksWarehouse.IsDuplicate
	|			AND NOT TypesOfStocksWarehouse.Obsolete1
	|			AND NOT TypesOfStocksWarehouse.DeletionMark
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (NOT &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|		OR NOT ISNULL(GoodsTable.TracedGoods, FALSE))
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND GoodsTable.KeepRecordsByCCD
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	TypesOfStocksWarehouse.Ref,
	|	GoodsTable.VATRate,
	|	Dimension.DimensionKey
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";

	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "DocumentDataTableOfInventoryOwnerAttributes", "Document.VendorInvoice.InventoryKinds");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoriedLocationAttributesItemTypeOfItem", "GoodsTable.ItemsLocationAttributes.Products.ItemsType");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked", "GoodsTable.ItemsLocationAttributes.Products.TracedGoods");
		QueryText = StrReplace(QueryText, "GoodsTable.AnalysisOfAccountingForProductsProducts", "GoodsTable.ItemsLocationAttributes.Products");
		QueryText = StrReplace(QueryText, "GoodsTable.AnalysisOfAccountingProductsCharacteristics", "GoodsTable.ItemsLocationAttributes.Characteristic");
	EndIf;
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers, DocumentObject = Undefined) Export
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.Primary AS Primary
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations";
		
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	PurchaseByImportOperations 	= PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	ImportFromEAEUOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	If DocumentObject <> Undefined
		And PurchaseByImportOperations.Find(DocumentObject.BusinessOperation) = Undefined
		And ImportFromEAEUOperations.Find(DocumentObject.BusinessOperation) = Undefined Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsForRegistrationOfImportDocuments", QueryTexts) Then
		QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocksForConnectingAnalytics", QueryTexts) Then
		QueryTextTTTypesOfStocksForConnectingAnalytics(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueriesArray = New Array;
	
	If DocumentObject = Undefined 
		Or (DocumentObject <> Undefined And PurchaseByImportOperations.Find(DocumentObject.BusinessOperation) <> Undefined) Then
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalanceForRegistrationByReceipts
	|			THEN UNDEFINED
	|		WHEN TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted IS NULL
	|			THEN &Ref
	|		WHEN NOT TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted
	|			THEN UNDEFINED
	|		ELSE &Ref
	|	END AS DocumentInflow,
	|
	|   &IDCustomsDeclarationImport AS ImportDocumentType,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	0 AS QuantityByGBRN,	
	|
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalanceForRegistrationByReceipts
	|			THEN UNDEFINED
	|		WHEN TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted IS NULL
	|			THEN CASE
	|					WHEN &ARAPCurrency = DocumentData.CompanyLocalAccountingCurrency
	|							AND &Currency <> DocumentData.CompanyLocalAccountingCurrency
	|						THEN GoodsTable.AmountARAP
	|					ELSE CAST(GoodsTable.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|				END
	|		WHEN NOT TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted
	|			THEN UNDEFINED
	|		ELSE CASE
	|				WHEN &ARAPCurrency = DocumentData.CompanyLocalAccountingCurrency
	|						AND &Currency <> DocumentData.CompanyLocalAccountingCurrency
	|					THEN GoodsTable.AmountARAP
	|				ELSE CAST(GoodsTable.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|			END
	|	END AS Sum,
	|	TRUE AS Primary,
	|	"""" AS RowID
	|FROM
	|	TTTableProducts AS GoodsTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON GoodsTable.Ref = DocumentData.Ref
	|		LEFT JOIN TTGoodsForRegistrationOfImportDocuments AS TTGoodsForRegistrationOfImportDocuments
	|			ON (TRUE)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods), 
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	&Partner,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalanceForRegistrationByReceipts
	|			THEN UNDEFINED
	|		WHEN TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted IS NULL
	|			THEN &Ref
	|		WHEN NOT TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted
	|			THEN UNDEFINED
	|		ELSE &Ref
	|	END,
	|
	|	&IDCustomsDeclarationImport AS ImportDocumentType,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	0 AS QuantityByGBRN,	
	|
	|	TableTypesOfStocks_.Count,
	|	CASE
	|		WHEN NOT &ControlCompanyStockBalanceForRegistrationByReceipts
	|			THEN UNDEFINED
	|		WHEN TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted IS NULL
	|			THEN CASE
	|					WHEN &ARAPCurrency = DocumentData.CompanyLocalAccountingCurrency
	|							AND &Currency <> DocumentData.CompanyLocalAccountingCurrency
	|						THEN TableTypesOfStocks_.AmountARAP
	|					ELSE CAST(TableTypesOfStocks_.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|				END
	|		WHEN NOT TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted
	|			THEN UNDEFINED
	|		ELSE CASE
	|				WHEN &ARAPCurrency = DocumentData.CompanyLocalAccountingCurrency
	|						AND &Currency <> DocumentData.CompanyLocalAccountingCurrency
	|					THEN TableTypesOfStocks_.AmountARAP
	|				ELSE CAST(TableTypesOfStocks_.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|			END
	|	END,
	|	TRUE,
	|	"""" AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON TableTypesOfStocks_.Ref = DocumentData.Ref
	|		LEFT JOIN TTGoodsForRegistrationOfImportDocuments AS TTGoodsForRegistrationOfImportDocuments
	|			ON (TRUE)
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods), 
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &BusinessOperation IN (&BusinessTransactionsImportPurchase)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND &UninvoicedReceiptDocumentIsUsed";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If DocumentObject = Undefined 
		Or (DocumentObject <> Undefined And ImportFromEAEUOperations.Find(DocumentObject.BusinessOperation) <> Undefined) Then
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Partner AS Vendor,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&Ref AS DocumentInflow,
	|
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	0 AS QuantityByGBRN,
	|
	|	GoodsTable.Count AS Count,
	|	ISNULL(DocumentAmounts_.AmountExcludingVAT, 0) AS Sum,
	|	TRUE AS Primary,
	|	GoodsTable.RowID AS RowID
	|FROM
	|	TTTableProducts AS GoodsTable
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		GoodsTable.Ref = DocumentAmounts_.Ref
	|		AND GoodsTable.RowID = DocumentAmounts_.RowID
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND GoodsTable.Count > 0
	|	AND &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND &NewWayToCreateApplicationForGoodsImportFromEAEU
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Period,
	|	&Organization,
	|	&Partner,
	|	TableTypesOfStocks_.ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	&Ref,
	|
	|	&IdApplicationForImportOfGoods AS ImportDocumentType,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	0 AS QuantityByGBRN,
	|
	|	TableTypesOfStocks_.Count,
	|	ISNULL(DocumentAmounts_.AmountExcludingVAT, 0),
	|	TRUE,
	|	TableTypesOfStocks_.RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmounts_
	|	ON
	|		TableTypesOfStocks_.Ref = DocumentAmounts_.Ref
	|		AND TableTypesOfStocks_.RowID = DocumentAmounts_.RowID
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND TableTypesOfStocks_.Count > 0
	|	AND &BusinessOperation IN (&BusinessTransactionsProcurementInEAEUCountries)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND &NewWayToCreateApplicationForGoodsImportFromEAEU";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "DocumentData.CompanyLocalAccountingCurrency", "DocumentData.Organization.LocalAccountingCurrency");
	EndIf;
	
	VendorInvoiceLocalization.AddRequestTextTableProductsForImportDocuments(QueryText);

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	 
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS AmountIncludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(GoodsTable.CostTD) AS CostTD,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting 
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(GoodsTable.CostTD) AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting 
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.RowID
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS AmountIncludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(GoodsTable.CostTD) AS CostTD,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting 
	|
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.RowID
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);

	QueryText = "
	// Expenses
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	SUM(GoodsTable.VATAmountMan) AS VATManag,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalCost,
	|	0 AS PermanentDifference,
	|	SUM(GoodsTable.CostTD) AS CostTD,
	|	SUM(GoodsTable.VATAmountCompl) AS VATLocal,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.RowID
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, DocumentObject = Undefined) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);

	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&Department                         AS Department,
	|	&Currency                                AS Currency,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	&BusinessOperation                 AS BusinessOperation,
	|	&CashFlowItem         AS CashFlowItem,
	|	SUM(GoodsTable.AmountIncludingVAT)         AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATCompl) + SUM(GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountIncludingVATMan)      AS SumMan,
	|	SUM(GoodsTable.AmountIncludingVAT)         AS ToReport,
	|	0                                      AS PurchaseAmount,
	|	
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|	
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.FinRecordID
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	&AdvanceHolder                       AS AdvanceHolder,
	|	&Department                         AS Department,
	|	&Currency                                AS Currency,
	|	
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS IssuancePurpose,
	|	
	|	&BusinessOperation                 AS BusinessOperation,
	|	&CashFlowItem         AS CashFlowItem,
	|	0                                      AS Sum,
	|	0                                      AS SumCompl,
	|	0                                      AS SumMan,
	|	0                                      AS ToReport,
	|	SUM(GoodsTable.AmountIncludingVAT)         AS PurchaseAmount,
	|	
	|	&IDOfUnusedFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EmptyRef) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&ExpenseReport = VALUE(Document.ExpenseReport.EmptyRef)
	|	AND &Period >= &StartDateOfPrintingSingleExpenseReport
	|	
	|GROUP BY
	|	GoodsTable.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueriesArray = New Array;
	
	If (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.ConsignmentProcurement) Then
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Ref AS DocumentInflow,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalCost,
	|	SUM(
	|		CASE 
	|			WHEN GoodsTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|				THEN 0 
	|			ELSE GoodsTable.VATAmountCompl
	|		END) AS VATLocal,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), 
	|									  VALUE(Enum.ItemsTypes.ReusablePackage))
	|		OR (GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods))
	|	AND &BatchAccountingVersion21
	|	AND NOT GoodsTable.ToExpenseAs
	|GROUP BY
	|	GoodsTable.InventoryOwnerAttribute, GoodsTable.ItemsLocationAttributes, GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products, GoodsTable.Characteristic";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If (DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement) Then
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Ref AS DocumentInflow,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods), 
	|									  VALUE(Enum.ItemsTypes.ReusablePackage))
	|		OR (GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods))
	|	AND &BatchAccountingVersion21
	|	AND NOT GoodsTable.ToExpenseAs
	|GROUP BY
	|	GoodsTable.InventoryOwnerAttribute, GoodsTable.ItemsLocationAttributes, GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products, GoodsTable.Characteristic";
	
	QueriesArray.Add(QueryText);
	
	EndIf;
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;

	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	
	If Query.Parameters.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
		SetRequestParametersCurrencyCoefficients(Query);
		
		RegisterName = "DocumentAmountsInAccountingCurrency";
		
		If Registers <> Undefined And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
			Return;
		EndIf;
		
		If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
			Return;
		EndIf;
		
		QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts, DocumentObject);
		
		Text = "
		|////////////////////////////////////////////////////////////////////////////////
		|// Table DocumentAmountsInAccountingCurrency
		|"+
		"SELECT
		|	*
		|FROM
		|	TTAmountsOfDocumentsInAccountingCurrencies";
		
		QueryTexts.Add(Text, RegisterName);
		
	Else
		
		RequestTextForTheseDocuments = "
		|SELECT
		|	""Covariability"" AS DataSource,
		|	TRUE AS DistributeTotalAmount,
		|
		|	GoodsTable.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Currency AS DocumentCurrency,
		|	DocumentData.ARAPCurrency AS ARAPCurrency,
		|	DocumentData.DocumentExchangeRateDate AS VATBasePeriod,
		|	DocumentData.DocumentExchangeRateDate AS DateOfCourse,
		|
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.RowID AS RowID,
		|	
		|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVAT,
		|	GoodsTable.VATRate AS VATRate,
		|	GoodsTable.VATAmount AS VATAmount,
		|	GoodsTable.AmountARAP AS AmountARAP,
		|	GoodsTable.AmountVATARAP AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|	
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			THEN FALSE
		|		WHEN GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND DocumentData.ToReturnReusablePackage
		|				AND NOT DocumentData.PackageDepositIsRequired
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS RecordedInARAPAccounting,
		|	GoodsTable.ARAPObject AS ARAPObject,
		|	TRUE AS RecalculateBasedOnARAPData
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|			ON GoodsTable.Ref = DocumentData.Ref
		|
		|WHERE
		|	GoodsTable.Ref IN (&Ref)
		|	AND (NOT &UninvoicedReceiptDocumentIsUsed
		|			OR &UninvoicedReceiptDocumentIsUsed
		|				AND GoodsTable.ProductsTypeOfProducts IN (
		|						VALUE(Enum.ItemsTypes.OperationService), 
		|						VALUE(Enum.ItemsTypes.Work_5)))
		|
		|UNION ALL
		|
		|SELECT
		|	""Covariability"" AS DataSource,
		|	TRUE AS DistributeTotalAmount,
		|	
		|	TableTypesOfStocks_.Ref AS Ref,
		|	DocumentData.Date AS Date,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Currency AS DocumentCurrency,
		|	DocumentData.ARAPCurrency AS ARAPCurrency,
		|	DocumentData.DocumentExchangeRateDate AS VATBasePeriod,
		|	DocumentData.DocumentExchangeRateDate AS DateOfCourse,
		|
		|	TableTypesOfStocks_.LineNumber AS LineNumber,
		|	TableTypesOfStocks_.RowID AS RowID,
		|	
		|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVAT,
		|	TableTypesOfStocks_.VATRate AS VATRate,
		|	TableTypesOfStocks_.VATAmount AS VATAmount,
		|	TableTypesOfStocks_.AmountARAP AS AmountARAP,
		|	TableTypesOfStocks_.AmountVATARAP AS AmountVATARAP,
		|	0 AS AmountExcludingVATCompl,
		|	0 AS AmountExcludingVATMan,
		|
		|	CASE
		|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			THEN FALSE
		|		WHEN TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.ReusablePackage)
		|				AND DocumentData.ToReturnReusablePackage
		|				AND NOT DocumentData.PackageDepositIsRequired
		|		THEN FALSE
		|		ELSE TRUE
		|	END AS RecordedInARAPAccounting,
		|	TableTypesOfStocks_.ARAPObject AS ARAPObject,
		|	TRUE AS RecalculateBasedOnARAPData
		|FROM
		|	DocumentDataTableOfInventoryOwnerAttributes AS TableTypesOfStocks_
		|		INNER JOIN DocumentDataHeader AS DocumentData
		|			ON TableTypesOfStocks_.Ref = DocumentData.Ref
		|WHERE
		|	TableTypesOfStocks_.Ref IN (&Ref)
		|	AND &UninvoicedReceiptDocumentIsUsed
		|";

		If DocumentObject = Undefined Then
			 RequestTextForTheseDocuments = StrReplace(RequestTextForTheseDocuments, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
			 RequestTextForTheseDocuments = StrReplace(RequestTextForTheseDocuments, "DocumentDataTableOfInventoryOwnerAttributes", "Document.VendorInvoice.InventoryKinds");
			 RequestTextForTheseDocuments = StrReplace(RequestTextForTheseDocuments, "DocumentDataHeader", "Document.VendorInvoice");
			 RequestTextForTheseDocuments = StrReplace(RequestTextForTheseDocuments, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
			 RequestTextForTheseDocuments = StrReplace(RequestTextForTheseDocuments, "TableTypesOfStocks_.InventoriedLocationAttributesItemTypeOfItem", "TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType");
		EndIf;
		
		InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
			Query, QueryTexts, Registers, RequestTextForTheseDocuments);
	EndIf;
	
EndProcedure

Function QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "DocumentAmountsInLocalCurrency";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesOfReportLines", QueryTexts) Then
		QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts, DocumentObject);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Ref AS Ref,
	|	DocumentTable.LineNumber,
	|	&Period AS Period,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS DocumentCurrency,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	CAST((DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountExcludingVATCompl,
	|	CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS VATAmountCompl,
	|	CAST(DocumentTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	UNDEFINED AS PaymentType_,
	|	CAST((DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|	CAST(DocumentTable.VATAmount * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS VATAmountMan,
	|	CAST(DocumentTable.AmountIncludingVAT * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountIncludingVATMan,
	|	
	|	DocumentTable.AmountARAP - DocumentTable.AmountVATARAP AS AmountGiven,
	|	CAST((DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS AmountGivenCompl,
	|	CAST((DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) * TableExchangeRatesOfReportLines.ManConversionFactor AS NUMBER(31,2)) AS AmountGivenMan,
	|	
	|	FALSE AS RecordedInARAPAccounting,
	|	DocumentTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	&Period AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	CAST((DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount) * TableExchangeRatesOfReportLines.LocalConversionRatio AS NUMBER(31,2)) AS VATBaseLocal,
	|	UNDEFINED AS ARAPCurrency,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	DocumentDataTableItems AS DocumentTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON DocumentTable.Ref = DocumentData.Ref
	|		
	|		LEFT JOIN TTExchangeRatesOfReportLines AS TableExchangeRatesOfReportLines
	|		ON TableExchangeRatesOfReportLines.RowID = DocumentTable.RowID
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction // The text of the tablequestionsummydocumentsvaluteregl()

Function QueryTextTTExchangeRatesOfReportLines(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTExchangeRatesOfReportLines";
	
	QueryText = "
	|SELECT
	|	SUM(Cash.SumBalance) AS ReceivedEmails,
	|	CAST(SUM(Cash.SumManBalance) / SUM(Cash.SumBalance) AS NUMBER(31,18)) AS ManConversionFactor,
	|	CAST(SUM(Cash.SumComplBalance) / SUM(Cash.SumBalance) AS NUMBER(31,18)) AS LocalConversionRatio,
	|	CASE WHEN &ControlIssueOfCashByPurposes 
	|		THEN Cash.IssuancePurpose
	|		ELSE VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|	END AS IssuancePurpose,
	|	Cash.Currency AS Currency
	|INTO CurrencyRatesOfAdvances
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&DateOfRemainingGoods,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND AdvanceHolder = &AdvanceHolder
	|				) AS Cash
	|WHERE
	|	Cash.SumBalance > 0
	|GROUP BY
	|	CASE WHEN &ControlIssueOfCashByPurposes 
	|		THEN Cash.IssuancePurpose
	|		ELSE VALUE(Catalog.CashFlowReportItems.EmptyRef)
	|	END,
	|	Cash.Currency
	|;
	|
	|SELECT
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CashFlowItem AS CashFlowItem,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.AmountIncludingVAT AS Sum,
	|	GoodsTable.AmountTotal AS AmountTotal
	|INTO ReportLines
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON GoodsTable.Ref = DocumentData.Ref
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|;
	|SELECT
	|	SplitExpenseLine.RowID AS RowID,
	|	SUM(SplitExpenseLine.Sum) AS Sum,
	|	SUM(SplitExpenseLine.SumMan) AS SumMan,
	|	SUM(SplitExpenseLine.SumCompl) AS SumCompl,
	|	CASE WHEN SUM(SplitExpenseLine.Sum) = 0
	|		THEN &ConversionRateToManCurrency
	|		ELSE CAST(SUM(SplitExpenseLine.SumMan) / SUM(SplitExpenseLine.Sum) AS NUMBER(31,18))
	|	END AS ManConversionFactor,
	|	CASE WHEN SUM(SplitExpenseLine.Sum) = 0
	|		THEN &FactorOfConversionToCurrencyOfRegul
	|		ELSE CAST(SUM(SplitExpenseLine.SumCompl) / SUM(SplitExpenseLine.Sum) AS NUMBER(31,18))
	|	END AS LocalConversionRatio
	|INTO TTExchangeRatesOfReportLines
	|FROM
	|	//Advance part amount
	|	(SELECT
	|		ReportLines.RowID AS RowID,
	|		CASE
	|			//The Balance of the advance is greater than or equal to the sum of the line
	|			WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN ReportLines.Sum
	|			//Received minus the already distributed advance payment of more than zero
	|			WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) 
	|			ELSE 0
	|		END AS Sum,
	|		CASE WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN ReportLines.Sum
	|			WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) 
	|			ELSE 0
	|		END * CurrencyRatesOfAdvances.ManConversionFactor AS SumMan,
	|		CASE WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN ReportLines.Sum
	|			WHEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN CurrencyRatesOfAdvances.ReceivedEmails - (ReportLines.AmountTotal - ReportLines.Sum) 
	|			ELSE 0
	|		END * CurrencyRatesOfAdvances.LocalConversionRatio AS SumCompl
	|	FROM
	|		ReportLines AS ReportLines
	|			INNER JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|			ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|				AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|					OR NOT &ControlIssueOfCashByPurposes)
	|	
	|	UNION ALL
	|	
	|	//Debt part
	|	SELECT
	|		ReportLines.RowID AS RowID,
	|		CASE
	|			//In the opposite direction: The Balance of the advance is greater than or equal to the sum of the line, which means the debt is 0 
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN 0
	|			//The Balance of the advance is greater than zero and the sum of the line is greater than the Balance of the advance
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN ReportLines.Sum - (ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum))
	|			ELSE ReportLines.Sum
	|		END AS Sum,
	|		CASE
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN 0
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN ReportLines.Sum - (ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum))
	|			ELSE ReportLines.Sum
	|		END * &ConversionRateToManCurrency AS SumMan,
	|		CASE
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) >= ReportLines.Sum
	|				THEN 0
	|			WHEN ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum) > 0
	|				THEN ReportLines.Sum - (ISNULL(CurrencyRatesOfAdvances.ReceivedEmails,0) - (ReportLines.AmountTotal - ReportLines.Sum))
	|			ELSE ReportLines.Sum
	|		END * &FactorOfConversionToCurrencyOfRegul AS SumCompl
	|	FROM
	|		ReportLines AS ReportLines
	|			LEFT JOIN CurrencyRatesOfAdvances AS CurrencyRatesOfAdvances
	|			ON CurrencyRatesOfAdvances.Currency = ReportLines.Currency
	|				AND (CurrencyRatesOfAdvances.IssuancePurpose = ReportLines.CashFlowItem
	|					OR NOT &ControlIssueOfCashByPurposes)
	|	) AS SplitExpenseLine
	|GROUP BY
	|	SplitExpenseLine.RowID
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Query.Parameters.Property("UnfacturedDeliveriesOfServicesWorks") And Query.Parameters.UnfacturedDeliveriesOfServicesWorks Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	GoodsTable.Department,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Purpose AS Purpose,
	|	TRUE AS Primary
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND (GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR GoodsTable.AssignmentTypeOfAssignment <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND NOT GoodsTable.TracedGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextBatchesOfProductionCosts(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BatchesOfProductionCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&Ref AS DocumentInflow,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalCost,
	|	SUM(CASE 
	|			WHEN GoodsTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|				THEN 0
	|			ELSE GoodsTable.VATAmountCompl
	|		END ) AS VATLocal
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &BatchAccountingVersion22
	|	AND (GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR GoodsTable.AssignmentTypeOfAssignment <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes, 
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.InventoryOwnerAttribute
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueriesArray = New Array;
	
	BusinessTransactionsImportPurchase    = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	BusinessTransactionsPurchasingFromSupplier  = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	
#Region UninvoicedReceipt
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
		Or BusinessTransactionsImportPurchase.Find(DocumentObject.BusinessOperation) <> Undefined 
		Or BusinessTransactionsProcurementInEAEUCountries.Find(DocumentObject.BusinessOperation) <> Undefined
		Or BusinessTransactionsPurchasingFromSupplier.Find(DocumentObject.BusinessOperation) <> Undefined Then
		
	UninvoicedReceipt = 
	"SELECT
	|	&Period AS Period,
	|	CASE WHEN GoodsTable.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE
	|		WHEN &ReceiptUnderOrders
	|				AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders
	|				AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END AS OrderDocument,
	|	UNDEFINED AS AdvanceHolder,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	SUM(GoodsTable.DiscountAmount) AS DiscountAmount,
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|			VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT), 
	|			VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods), 
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &ReceiptUnderOrders
	|				AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders
	|				AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.ARAPObject,
	|	GoodsTable.VATActivityType,
	|	CASE WHEN GoodsTable.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|		ELSE &BusinessOperation
	|	END";
	
	QueriesArray.Add(UninvoicedReceipt);
	
	EndIf;
	
	If BusinessTransactionsImportPurchase.Find(DocumentObject.BusinessOperation) <> Undefined 
		Or BusinessTransactionsProcurementInEAEUCountries.Find(DocumentObject.BusinessOperation) <> Undefined
		Or BusinessTransactionsPurchasingFromSupplier.Find(DocumentObject.BusinessOperation) <> Undefined Then
		
	UninvoicedReceipt =
	"SELECT
	|	&Period,
	|	CASE WHEN TableTypesOfStocks_.InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|		ELSE &BusinessOperation
	|	END AS BusinessOperation,
	|	&Organization,
	|	&Department,
	|	&Manager,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|		OR &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE
	|			TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	TableTypesOfStocks_.Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	&Partner,
	|	&Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END,
	|	&Terms,
	|	&Contract,
	|	CASE
	|		WHEN &ReceiptUnderOrders
	|				AND &ReceiptUnderSeveralOrders
	|			THEN TableTypesOfStocks_.PurchaseOrder
	|		WHEN &ReceiptUnderOrders
	|				AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END,
	|	UNDEFINED,
	|	SUM(TableTypesOfStocks_.Count),
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan),
	|	SUM(TableTypesOfStocks_.AmountExcludingVATMan),
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl),
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl),
	|	SUM(TableTypesOfStocks_.DiscountAmount),
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan),
	|	SUM(TableTypesOfStocks_.AmountExcludingVATMan),
	|	CASE
	|		WHEN TableTypesOfStocks_.VATActivityType IN (VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT), VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl)
	|		ELSE SUM(TableTypesOfStocks_.AmountExcludingVATCompl)
	|	END,
	|	0,
	|	0,
	|	&Currency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT),
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount),
	|	&ARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP),
	|	SUM(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP),
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE InventoryLocationAttributeKeys.Products
	|	END,
	|	TableTypesOfStocks_.ARAPObject
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND &UninvoicedReceiptDocumentIsUsed
	|
	|GROUP BY
	|	CASE
	|		WHEN &BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
	|			VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
	|			VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt))
	|		OR &KeepRecordsOfInventoryCostByAssignments
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE
	|			TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|	END,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	TableTypesOfStocks_.Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &ReceiptUnderOrders
	|				AND &ReceiptUnderSeveralOrders
	|			THEN TableTypesOfStocks_.PurchaseOrder
	|		WHEN &ReceiptUnderOrders
	|				AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE InventoryLocationAttributeKeys.Products
	|	END,
	|	TableTypesOfStocks_.ARAPObject,
	|	CASE WHEN TableTypesOfStocks_.InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|		THEN VALUE(Enum.BusinessTransactions.ReceivingForPrincipal)
	|		ELSE &BusinessOperation
	|	END,
	|	TableTypesOfStocks_.VATActivityType";
	
	QueriesArray.Add(UninvoicedReceipt);
	
	EndIf;
		
#EndRegion


#Region ReceiptOfWorks

	If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
	ReceiptOfWorks =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	&Department AS Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE
	|		WHEN &ReceiptUnderOrders AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END AS OrderDocument,
	|	UNDEFINED AS AdvanceHolder,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	SUM(GoodsTable.DiscountAmount) AS DiscountAmount,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND (GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR NOT GoodsTable.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &ReceiptUnderOrders AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.ARAPObject,
	|	GoodsTable.Department,
	|	GoodsTable.VATActivityType
	|";
	
	QueriesArray.Add(ReceiptOfWorks);
	
	EndIf;
	
#EndRegion

#Region ConsignmentProcurement

	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
	ConsignmentProcurement = 
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	CASE
	|		WHEN &ReceiptUnderOrders AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END AS OrderDocument,
	|	UNDEFINED AS AdvanceHolder,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT GoodsTable.ToExpenseAs
	|	
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &ReceiptUnderOrders AND &ReceiptUnderSeveralOrders
	|			THEN GoodsTable.PurchaseOrder
	|		WHEN &ReceiptUnderOrders AND NOT &ReceiptUnderSeveralOrders
	|			THEN &PurchaseOrder
	|		ELSE &Ref
	|	END,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.ARAPObject,
	|	GoodsTable.VATActivityType
	|";
	
	QueriesArray.Add(ConsignmentProcurement);
	
	EndIf;
	
#EndRegion

#Region ReceiptOfGoodsThroughAccountablePerson
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
	ReceiptOfGoodsThroughAccountablePerson =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				OR &Counterparty = VALUE(Catalog.Companies.EmptyRef) THEN
	|			UNDEFINED
	|		ELSE
	|			&Counterparty
	|	END AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	CASE
	|		WHEN &Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				OR &Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef) THEN
	|			UNDEFINED
	|		ELSE
	|			&Contract
	|	END AS Contract,
	|	&Ref AS OrderDocument,
	|	&AdvanceHolder AS AdvanceHolder,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	SUM(GoodsTable.DiscountAmount) AS DiscountAmount,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT GoodsTable.ToExpenseAs
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.ARAPObject,
	|	GoodsTable.VATActivityType
	|";
	
	QueriesArray.Add(ReceiptOfGoodsThroughAccountablePerson);
	
	EndIf;
	
#EndRegion

#Region ReceiptOfWorksThroughAccountablePerson
	
	If DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		
	ReceiptOfWorksThroughAccountablePerson =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	&Department AS Warehouse,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Terms AS Terms,
	|	&Contract AS Contract,
	|	&Ref AS OrderDocument,
	|	&AdvanceHolder AS AdvanceHolder,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	SUM(GoodsTable.DiscountAmount) AS DiscountAmount,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
	|		ELSE SUM(GoodsTable.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|   AND (GoodsTable.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR NOT GoodsTable.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|
	|GROUP BY
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.InventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE GoodsTable.Products
	|	END,
	|	GoodsTable.Department,
	|	GoodsTable.ARAPObject,
	|	GoodsTable.VATActivityType
	|";
	
	QueriesArray.Add(ReceiptOfWorksThroughAccountablePerson);
	
	EndIf;
	
#EndRegion
	
	If QueriesArray.Count() = 0 Then
		Return "";
	EndIf;

	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
		
	QueryText = StrConcat(QueriesArray, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);

	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		THEN VALUE(Enum.BusinessTransactions.ReceiptOfServicesPurchaseAgainstLocal)
	|		ELSE VALUE(Enum.BusinessTransactions.ReceiptOfServices)
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	GoodsTable.ARAPObject AS ARAPObject,
	|
	|	GoodsTable.ExpenseItem AS IncomeAndExpenseItem,
	|	GoodsTable.LineOfBusiness AS LineOfBusinessItems,
	|	UNDEFINED AS DimensionOfRevenue,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	
	|	GoodsTable.AmountIncludingVATMan AS Sum,
	|	GoodsTable.AmountExcludingVATMan AS AmountExcludingVAT,
	|	GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl AS SumCompl,
	|	GoodsTable.AmountExcludingVATCompl AS LocalAmountExcludingVAT,
	|
	|	&Currency AS Currency,
	|	GoodsTable.AmountIncludingVAT AS AmountInCurrency,
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency AS ARAPCurrency,
	|	GoodsTable.AmountARAP AS AmountInARAPCurrency,
	|	GoodsTable.AmountARAP - GoodsTable.AmountVATARAP AS AmountExcludingVATInARAPCurrency,
	|
	|	GoodsTable.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	GoodsTable.FinRecordID AS FinRecordID
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.OtherExpensesOfAdvanceHolders) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	GoodsTable.Department AS IncomeExpenseBusinessUnit,
	|	&AdvanceHolder AS Cash,
	|	VALUE(Enum.CashTypes.AdvanceHolderSCash) AS CashType,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		&CashFlowItem
	|	END AS CashFlowItem,
	|	&Currency AS Currency,
	|	
	|	CASE
	|		WHEN &AccountingForLBCosts THEN
	|			&LineOfBusiness
	|	END AS LineOfBusinessItems,
	|	GoodsTable.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	
	|	CAST(GoodsTable.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST(GoodsTable.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	GoodsTable.AmountIncludingVAT AS AmountInCurrency,
	|	
	|	GoodsTable.VATAmountMan AS VATAmount,
	|	GoodsTable.VATAmountCompl AS VATAmountCompl,
	|	GoodsTable.VATAmount AS AmountVATCurrencyPayment,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	GoodsTable.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|	AND GoodsTable.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts, DocumentObject = Undefined)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	SetRequestParameterTaxationOfOrganization(Query);
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.VendorInvoice.Name,
		"Goods, InventoryKinds");
	
	If DocumentObject <> Undefined Then
		LineNumberText = StrReplace(LineNumberText, "Document.VendorInvoice.Goods",       "DocumentDataTableItems");
		LineNumberText = StrReplace(LineNumberText, "Document.VendorInvoice.InventoryKinds",  "DocumentDataTableOfInventoryOwnerAttributes");
	EndIf;
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Goods"" 								AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
	|				AND ISNULL(ARTICLES__.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|		 AND NOT &SimplifiedTaxationSystem
	|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		WHEN ISNULL(DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentData.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentData.PurchaseForActivity
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN CatProducts.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN CatProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		  AND NOT DocumentTable.ToExpenseAs
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		WHEN ISNULL(ARTICLES__.VATAssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef)) <>
	|		  VALUE(Enum.AssetKinds.EmptyRef)
	|			THEN ARTICLES__.VATAssetTaxClass
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|			THEN 0
	|		ELSE LineCodes.RowCode END)	AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	DocumentDataTableItems AS DocumentTable
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.Products
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|SELECT
	|	""InventoryKinds"" 						AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|			AND DocumentData.PurchaseForActivity = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		ELSE DocumentData.PurchaseForActivity
	|	END                               	AS VATTaxation,
	|	CASE
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.DigitalServices)
	|			THEN VALUE(Enum.AssetKinds.DigitalServices)
	|		WHEN CatProducts.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               	AS AssetTaxClass,
	|	(CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|			THEN 0
	|		ELSE LineCodes.RowCode END)	AS RowCode
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS DocumentTable
	|	INNER JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Dimension.Ref = DocumentTable.ItemsLocationAttributes
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = Dimension.Products
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON CatProducts.FinancialAccountingGroup = FAG.Ref
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	If DocumentObject = Undefined Then
		TextSelectionOfAnalystField = StrReplace(TextSelectionOfAnalystField, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		TextSelectionOfAnalystField = StrReplace(TextSelectionOfAnalystField, "DocumentDataTableOfInventoryOwnerAttributes", "Document.VendorInvoice.InventoryKinds");
		TextSelectionOfAnalystField = StrReplace(TextSelectionOfAnalystField, "DocumentDataHeader", "Document.VendorInvoice");
		TextSelectionOfAnalystField = StrReplace(TextSelectionOfAnalystField, "DocumentTable.PurposeOfVATSTaxationOfTypeOfActivity", "DocumentTable.Purpose.VATActivityType");
	EndIf;
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts, DocumentObject) Export
	
	RegisterName = "TTTableProducts";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query, DocumentObject);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	FALSE AS IncludeVATInCostExpenses,
	|	GoodsTable.Ref                       		AS Ref,
	|	GoodsTable.RowCode                    		AS RowCode,
	|	GoodsTable.ExpenseItem               		AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses            		AS DimensionOfExpenses,
	|	GoodsTable.PurchaseOrder              		AS PurchaseOrder,
	|	GoodsTable.ARAPObject              		AS ARAPObject,
	|	GoodsTable.Products                 		AS Products,
	|	GoodsTable.ProductsTypeOfProducts 		AS ItemsType,
	|	GoodsTable.Characteristic               		AS Characteristic,
	|	GoodsTable.Series                        		AS Series,
	|	GoodsTable.AssignmentTypeOfAssignment			AS AssignmentTypeOfAssignment,
	|	GoodsTable.InventoryOwnerAttributeIsTypeOfInventory         		AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.CCDNumber                     		AS CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType             AS CCDNumberCCDNumberType,
	|	GoodsTable.InventoryOwnerAttribute                   		AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage AND NOT &PackageDepositIsRequired
	|			THEN GoodsTable.RowID
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN GoodsTable.RowID
	|		ELSE GoodsTable.ARAPObjectIsUniqueIdentifier
	|	END AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|
	|	GoodsTable.Count                   		AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	ISNULL(GoodsTable.ItemOfTraceableItem, FALSE) AS TracedGoods,
	|	GoodsTable.Price                         		AS Price,
	|	GoodsTable.Warehouse                        		AS Warehouse,
	|	GoodsTable.WarehouseShopFloorStockroom        		AS ShopFloorStockroom,
	|	CASE WHEN GoodsTable.WarehouseUseOrderSchemeWhenReceiving
	|			AND &Period >= GoodsTable.WarehouseStartDateOfOrderSchemeUponReceipt
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                      		AS UseWarehouseManagemantSystemForGoodsReceipt,
	|	GoodsTable.Sum                        		AS Sum,
	|	GoodsTable.VATAmount                     		AS VATAmount,
	|	GoodsTable.AmountIncludingVAT                    		AS AmountIncludingVAT,
	|	GoodsTable.RowID          		AS RowID,
	|	GoodsTable.Purpose                   		AS Purpose,
	|	GoodsTable.ItemsLocationAttributes   		AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey       		AS AnalysisOfAccountingForProductsWithoutAssignment,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND &ToReturnReusablePackage THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThisIsTaraForReturn,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0)
	|	END AS AmountIncludingVATMan,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0)
	|	END AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)      AS VATAmountMan,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0)
	|	END AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)     AS VATAmountCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)      AS VATBaseLocal,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0
	|	END AS CostTD,
	|	
	|	CASE WHEN &CompanyManagementAccounting AND &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN
	|			CASE
	|				WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|					THEN Amounts.AmountGivenMan
	|				ELSE ISNULL(Amounts.AmountExcludingVATMan, 0)
	|			END
	|		ELSE 0
	|	END AS CostMan,
	|	CASE WHEN &BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN
	|			CASE
	|				WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|					THEN Amounts.AmountGivenCompl
	|				ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0)
	|			END 
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	GoodsTable.VATRate AS VATRate,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGiven, 0) <> 0
	|			THEN Amounts.AmountGiven + GoodsTable.AmountVATARAP
	|		ELSE 
	|			GoodsTable.AmountARAP
	|	END AS AmountARAP,
	|	GoodsTable.AmountVATARAP AS AmountVATARAP,
	|	CAST(GoodsTable.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(15,1)) AS DiscountAmount,
	|
	|	GoodsTable.Department                  AS Department,
	|	GoodsTable.ToExpenseAs               AS ToExpenseAs,
	|	CASE
	|		WHEN GoodsTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OperationService)
	|			OR (GoodsTable.ProductsTypeOfProducts IN (
	|					VALUE(Enum.ItemsTypes.Work_5), 
	|					VALUE(Enum.ItemsTypes.OwnGoods))
	|				AND ISNULL(GoodsTable.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
	|					VALUE(Catalog.LinesOfBusiness.EmptyRef)) = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|			THEN
	|				CASE WHEN &AccountingForLBCosts THEN
	|					&LineOfBusiness
	|				ELSE
	|					UNDEFINED
	|				END
	|		ELSE ISNULL(GoodsTable.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	END AS LineOfBusiness,
	|	ISNULL(AnalysisOfCalculations.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|	GoodsTable.InventoriedLocationAttributesItemTypeOfItem AS InventoriedLocationAttributesItemTypeOfItem,
	|	GoodsTable.AnalysisOfAccountingForProductsProducts AS AnalysisOfAccountingForProductsProducts,
	|	GoodsTable.ItemsLocationAttributesAssignment AS ItemsLocationAttributesAssignment
	|
	|INTO TTTableProducts
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|	LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON DocumentData.Ref = GoodsTable.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON GoodsTable.AnalysisOfAccountingForProductsProducts = AnalyticsWithoutAssignment.Products
	|		AND GoodsTable.AnalysisOfAccountingProductsCharacteristics = AnalyticsWithoutAssignment.Characteristic
	|		AND GoodsTable.InventoryLocationAttributeAnalysisBatch = AnalyticsWithoutAssignment.Series
	|		AND GoodsTable.ProductAccountingAnalyticsStorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		GoodsTable.Ref = Amounts.Ref
	|		AND GoodsTable.RowID = Amounts.RowID
	|		AND (Amounts.AmountExcludingVATCompl <> 0
	|			OR Amounts.AmountExcludingVATMan <> 0)
	|		AND (GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) = Amounts.AmountExcludingVAT
	|		AND GoodsTable.VATAmount = Amounts.VATAmount
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|	ON
	|		&Organization = AnalysisOfCalculations.Organization
	|		AND &Counterparty = AnalysisOfCalculations.Counterparty
	|		AND &Partner = AnalysisOfCalculations.Partner
	|		AND &Contract = AnalysisOfCalculations.Contract
	|		AND GoodsTable.ARAPObjectLineOfBusiness = AnalysisOfCalculations.LineOfBusiness
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		QueryText = StrReplace(QueryText, "GoodsTable.ARAPObjectIsUniqueIdentifier", "GoodsTable.ARAPObject.UUID");
		QueryText = StrReplace(QueryText, "GoodsTable.ItemOfTraceableItem", "GoodsTable.Products.TracedGoods");
		QueryText = StrReplace(QueryText, "GoodsTable.WarehouseUseOrderSchemeWhenReceiving", "GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt");
		QueryText = StrReplace(QueryText, "GoodsTable.WarehouseStartDateOfOrderSchemeUponReceipt", "GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness", "GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoriedLocationAttributesItemTypeOfItem", "GoodsTable.ItemsLocationAttributes.Products.ItemsType");
		QueryText = StrReplace(QueryText, "GoodsTable.AnalysisOfAccountingForProductsProducts", "GoodsTable.ItemsLocationAttributes.Products");
		QueryText = StrReplace(QueryText, "GoodsTable.AnalysisOfAccountingProductsCharacteristics", "GoodsTable.ItemsLocationAttributes.Characteristic");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoryLocationAttributeAnalysisBatch", "GoodsTable.ItemsLocationAttributes.Series");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductAccountingAnalyticsStorageLocation", "GoodsTable.ItemsLocationAttributes.StorageLocation");
		QueryText = StrReplace(QueryText, "GoodsTable.ARAPObjectLineOfBusiness", "GoodsTable.ARAPObject.LineOfBusiness");
		QueryText = StrReplace(QueryText, "GoodsTable.WarehouseShopFloorStockroom", "GoodsTable.Warehouse.ShopFloorStockroom");
		QueryText = StrReplace(QueryText, "GoodsTable.ItemsLocationAttributesAssignment", "GoodsTable.ItemsLocationAttributes.Purpose");
		QueryText = StrReplace(QueryText, "GoodsTable.AssignmentTypeOfAssignment", "GoodsTable.Purpose.AssignmentType");
		QueryText = StrReplace(QueryText, "GoodsTable.InventoryOwnerAttributeIsTypeOfInventory", "GoodsTable.InventoryOwnerAttribute.InventoryType");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTGoodsForRegistrationOfImportDocuments";
	
	QueryText = "
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	CASE
	|		WHEN GoodsForRegistrationOfImportDocuments.DocumentInflow <> VALUE(Document.VendorInvoice.EmptyRef)
	|			AND GoodsForRegistrationOfImportDocuments.DocumentInflow <> UNDEFINED
	|	THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ReceiptDocumentCompleted
	|INTO TTGoodsForRegistrationOfImportDocuments
	|FROM
	|	DocumentDataHeader AS DocumentData
	|	INNER JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistrationOfImportDocuments
	|	ON DocumentData.Ref = GoodsForRegistrationOfImportDocuments.Recorder
	|WHERE
	|	GoodsForRegistrationOfImportDocuments.Recorder = &Ref
	|GROUP BY
	|	DocumentData.Ref,
	|	GoodsForRegistrationOfImportDocuments.DocumentInflow";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsTypesOfInventory(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTGoodsTypesOfInventory";
	
	QueryText = "
	|SELECT
	|	Goods.ItemsLocationAttributes,
	|	MAX(Goods.InventoryOwnerAttribute) AS InventoryOwnerAttribute
	|INTO TTGoodsTypesOfInventory
	|FROM
	|	DocumentDataTableItems AS Goods
	|WHERE
	|	Goods.Ref = &Ref
	|GROUP BY
	|	Goods.ItemsLocationAttributes
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTTypesOfStocks";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Undefined, DocumentObject);
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query, DocumentObject);
	QueryTextTTGoodsTypesOfInventory(Query, QueryTexts, DocumentObject);
	
	QueryText = "
	|SELECT
	|	FALSE AS IncludeVATInCostExpenses,
	|	TSInventoryKinds.Ref AS Ref,
	|	TSInventoryKinds.RowID AS RowID,
	|	TSInventoryKinds.AnalysisOfAccountingForProductsProducts AS Products,
	|	TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem AS ItemsType,
	|	TSInventoryKinds.InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment AS InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment,
	|	TSInventoryKinds.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	TSInventoryKinds.InventoryLocationAttributeAnalysisBatch AS Series,
	|	TSInventoryKinds.CCDNumber AS CCDNumber,
	|	TSInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ISNULL(GoodsTypesOfStocks.InventoryOwnerAttribute, TSInventoryKinds.RecipientInventoryOwnerAttribute) AS RecipientInventoryOwnerAttribute,
	|	ISNULL(TSInventoryKinds.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked, FALSE) AS TracedGoods,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE TSInventoryKinds.QuantityByGBRN
	|	END AS QuantityByGBRN,	
	|	TSInventoryKinds.Count AS Count,
	|	TSInventoryKinds.Price AS Price,
	|	TSInventoryKinds.VATRate AS VATRate,
	|	TSInventoryKinds.VATAmount AS VATAmount,
	|	TSInventoryKinds.AmountIncludingVAT AS AmountIncludingVAT,
	|	TSInventoryKinds.AmountARAP AS AmountARAP,
	|	TSInventoryKinds.AmountVATARAP AS AmountVATARAP,
	|	TSInventoryKinds.ManualDiscount AS ManualDiscount,
	|	TSInventoryKinds.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	ISNULL(TSInventoryKinds.InventoryInventoryLocationAttributeAnalysisWarehouseTerritoryShopFloorStockroom, FALSE) AS ShopFloorStockroom,
	|	TSInventoryKinds.ItemsLocationAttributesAssignment AS Purpose,
	|	TSInventoryKinds.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TSInventoryKinds.PurchaseOrder AS PurchaseOrder,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|			THEN TSInventoryKinds.RowID
	|		ELSE TSInventoryKinds.ARAPObjectIsUniqueIdentifier
	|	END AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TSInventoryKinds.ARAPObject AS ARAPObject,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	ISNULL(TSInventoryKinds.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	TSInventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	TSInventoryKinds.ExpenseItem AS ExpenseItem,
	|	TSInventoryKinds.DimensionOfExpenses AS DimensionOfExpenses,
	|	TSInventoryKinds.Department AS Department,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	ISNULL(AnalysisOfCalculations.DimensionKey, UNDEFINED) AS AccountingDimensionByPartners,
	|
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan + Amounts.VATAmountMan
	|		ELSE ISNULL(Amounts.AmountIncludingVATMan, 0) END) AS AmountIncludingVATMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0) END) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)     AS VATAmountMan,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0) END) AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)    AS VATAmountCompl,
	|	ISNULL(Amounts.VATBaseLocal, 0)     AS VATBaseLocal,
	|	(CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl - Amounts.AmountExcludingVATCompl
	|		ELSE 0 END) AS CostTD,
	|
	|	CAST(TSInventoryKinds.ManualDiscount * &ConversionRateToManCurrency AS NUMBER(15,1)) AS DiscountAmount,
	|
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenCompl, 0) <> 0
	|			THEN Amounts.AmountGivenCompl
	|			ELSE ISNULL(Amounts.AmountExcludingVATCompl, 0)
	|	END AS LocalCost,
	|	CASE
	|		WHEN ISNULL(Amounts.AmountGivenMan, 0) <> 0
	|			THEN Amounts.AmountGivenMan
	|		ELSE ISNULL(Amounts.AmountExcludingVATMan, 0)
	|	END AS CostMan,
	|	TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem AS InventoriedLocationAttributesItemTypeOfItem,
	|	TSInventoryKinds.AnalysisOfAccountingForProductsProducts AS AnalysisOfAccountingForProductsProducts,
	|	TSInventoryKinds.ItemsLocationAttributesAssignment AS ItemsLocationAttributesAssignment
	|
	|INTO TTTypesOfStocks
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS TSInventoryKinds
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|			ON TSInventoryKinds.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TSInventoryKinds.Ref = Amounts.Ref
	|			AND TSInventoryKinds.RowID = Amounts.RowID
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON TSInventoryKinds.AnalysisOfAccountingForProductsProducts = AnalyticsWithoutAssignment.Products
	|			AND TSInventoryKinds.AnalysisOfAccountingProductsCharacteristics = AnalyticsWithoutAssignment.Characteristic
	|			AND TSInventoryKinds.InventoryLocationAttributeAnalysisBatch = AnalyticsWithoutAssignment.Series
	|			AND TSInventoryKinds.ProductAccountingAnalyticsStorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = TSInventoryKinds.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|	ON
	|		&Organization = AnalysisOfCalculations.Organization
	|		AND &Counterparty = AnalysisOfCalculations.Counterparty
	|		AND &Partner = AnalysisOfCalculations.Partner
	|		AND &Contract = AnalysisOfCalculations.Contract
	|		AND CASE 
	|			WHEN &SettlementsAgainstOrders 
	|				THEN TSInventoryKinds.PurchaseOrder.LineOfBusiness 	
	|			ELSE
	|				&LineOfBusiness
	|		  END = AnalysisOfCalculations.LineOfBusiness
	|	LEFT JOIN TTGoodsTypesOfInventory AS GoodsTypesOfStocks
	|		ON GoodsTypesOfStocks.ItemsLocationAttributes = TSInventoryKinds.ItemsLocationAttributes
	|		AND TSInventoryKinds.RecipientInventoryOwnerAttribute = VALUE(Catalog.InventoryKinds.EmptyRef)
	|WHERE
	|	TSInventoryKinds.Ref = &Ref";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableOfInventoryOwnerAttributes", "Document.VendorInvoice.InventoryKinds");
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem", "TSInventoryKinds.ItemsLocationAttributes.Products.ItemsType");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeOfItemSAccountingIsAssignmentTypeOfAssignment", "TSInventoryKinds.ItemsLocationAttributes.Purpose.AssignmentType");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.AnalysisOfAccountingProductsCharacteristics", "TSInventoryKinds.ItemsLocationAttributes.Characteristic");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeAnalysisBatch", "TSInventoryKinds.ItemsLocationAttributes.Series");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked", "TSInventoryKinds.ItemsLocationAttributes.Products.TracedGoods");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryInventoryLocationAttributeAnalysisWarehouseTerritoryShopFloorStockroom", "TSInventoryKinds.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.ARAPObjectIsUniqueIdentifier", "TSInventoryKinds.ARAPObject.UUID");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoriedLocationAttributeAnalysisPurposeLineOfBusiness", "TSInventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem", "TSInventoryKinds.ItemsLocationAttributes.Products.ItemsType");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.ProductAccountingAnalyticsStorageLocation", "TSInventoryKinds.ItemsLocationAttributes.StorageLocation");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.AnalysisOfAccountingForProductsProducts", "TSInventoryKinds.ItemsLocationAttributes.Products");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.ItemsLocationAttributesAssignment", "TSInventoryKinds.ItemsLocationAttributes.Purpose");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocksForConnectingAnalytics(Query, QueryTexts, DocumentObject = Undefined)
	
	RegisterName = "TTTypesOfStocksForConnectingAnalytics";
	
	QueryText = 
	"SELECT
	|	TSInventoryKinds.Ref AS Ref,
	|	TSInventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TSInventoryKinds.CCDNumber AS CCDNumber,
	|	TSInventoryKinds.Count AS Count,
	|	TSInventoryKinds.QuantityByGBRN AS QuantityByGBRN,
	|	TSInventoryKinds.PurchaseOrder AS PurchaseOrder,
	|	TSInventoryKinds.RecipientInventoryOwnerAttribute AS RecipientInventoryOwnerAttribute,
	|	TSInventoryKinds.Price AS Price,
	|	TSInventoryKinds.VATRate AS VATRate,
	|	TSInventoryKinds.VATAmount AS VATAmount,
	|	TSInventoryKinds.AmountIncludingVAT AS AmountIncludingVAT,
	|	TSInventoryKinds.AmountARAP AS AmountARAP,
	|	TSInventoryKinds.AmountVATARAP AS AmountVATARAP,
	|	TSInventoryKinds.ARAPObject AS ARAPObject,
	|	TSInventoryKinds.ManualDiscount AS ManualDiscount,
	|	TSInventoryKinds.ToExpenseAs AS ToExpenseAs,
	|	TSInventoryKinds.ItemsLocationAttributes AS DimensionKey,
	|	TSInventoryKinds.AnalysisOfAccountingForProductsProducts AS Products,
	|	TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem AS ItemsType,
	|	TSInventoryKinds.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked AS TracedGoods,
	|	TSInventoryKinds.AnalysisOfAccountingProductsCharacteristics AS Characteristic,
	|	TSInventoryKinds.InventoryLocationAttributeAnalysisBatch AS Series,
	|	TSInventoryKinds.ProductAccountingAnalyticsStorageLocation AS StorageLocation,
	|	TSInventoryKinds.ItemsLocationAttributesAssignment AS Purpose,
	|	TSInventoryKinds.InventoryLocationAttributeOfItemIsProductCostElementAnalysis AS ProductCostElement,
	|	TSInventoryKinds.InventoriedLocationAttributeItemAccountingForCCD AS KeepRecordsByCCD,
	|	TSInventoryKinds.TypeOfInventoryOwnerAttributeCompany AS TypeOfInventoryOwnerAttributeCompany,
	|	TSInventoryKinds.TypeOfInventoryOwnerAttributeOwnerOfItem AS TypeOfInventoryOwnerAttributeOwnerOfItem,
	|	TSInventoryKinds.TypeOfInventoryOwnerAttributeTaxationOfVAT AS TypeOfInventoryOwnerAttributeTaxationOfVAT,
	|	TSInventoryKinds.InventoryOwnerAttributeFinancialAccountingGroup AS InventoryOwnerAttributeFinancialAccountingGroup,
	|	TSInventoryKinds.InventoryOwnerAttributeIsProductGroup AS InventoryOwnerAttributeIsProductGroup,
	|	TSInventoryKinds.InventoryOwnerAttributeIsSubjectToExciseDuty AS InventoryOwnerAttributeIsSubjectToExciseDuty,
	|	TSInventoryKinds.InventoryOwnerAttributeDivisionOfProduction AS InventoryOwnerAttributeDivisionOfProduction,
	|	TSInventoryKinds.InventoryOwnerAttributePriceType AS InventoryOwnerAttributePriceType
	|INTO TTTypesOfStocksForConnectingAnalytics
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS TSInventoryKinds
	|WHERE
	|	TSInventoryKinds.Ref = &Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	StorageLocation,
	|	Purpose,
	|	ProductCostElement";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableOfInventoryOwnerAttributes", "Document.VendorInvoice.InventoryKinds");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.AnalysisOfAccountingForProductsProducts ", "TSInventoryKinds.ItemsLocationAttributes.Products ");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoriedLocationAttributesItemTypeOfItem", "TSInventoryKinds.ItemsLocationAttributes.Products.ItemsType");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeOfItemOfItemThatIsBeingTracked", "TSInventoryKinds.ItemsLocationAttributes.Products.TracedGoods");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.AnalysisOfAccountingProductsCharacteristics", "TSInventoryKinds.ItemsLocationAttributes.Characteristic");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeAnalysisBatch", "TSInventoryKinds.ItemsLocationAttributes.Series");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.ProductAccountingAnalyticsStorageLocation", "TSInventoryKinds.ItemsLocationAttributes.StorageLocation");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.ItemsLocationAttributesAssignment", "TSInventoryKinds.ItemsLocationAttributes.Purpose");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryLocationAttributeOfItemIsProductCostElementAnalysis", "TSInventoryKinds.ItemsLocationAttributes.ProductCostElement");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoriedLocationAttributeItemAccountingForCCD", "TSInventoryKinds.ItemsLocationAttributes.Products.KeepRecordsByCCD");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.TypeOfInventoryOwnerAttributeCompany", "TSInventoryKinds.InventoryOwnerAttribute.Organization");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.TypeOfInventoryOwnerAttributeOwnerOfItem", "TSInventoryKinds.InventoryOwnerAttribute.GoodsOwner");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.TypeOfInventoryOwnerAttributeTaxationOfVAT", "TSInventoryKinds.InventoryOwnerAttribute.VATTaxation");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryOwnerAttributeFinancialAccountingGroup", "TSInventoryKinds.InventoryOwnerAttribute.FinancialAccountingGroup");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryOwnerAttributeIsProductGroup", "TSInventoryKinds.InventoryOwnerAttribute.ProductsGroup");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryOwnerAttributeIsSubjectToExciseDuty", "TSInventoryKinds.InventoryOwnerAttribute.SubjectToExcise");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryOwnerAttributeDivisionOfProduction", "TSInventoryKinds.InventoryOwnerAttribute.BusinessUnitProduction");
		QueryText = StrReplace(QueryText, "TSInventoryKinds.InventoryOwnerAttributePriceType", "TSInventoryKinds.InventoryOwnerAttribute.PriceKind");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextVtProductsForAnalystConnection(Query, QueryTexts)
	
	RegisterName = "VtProductsForAnalystConnection";
	
	QueryText = 
	"SELECT
	|	TSGoods.Ref AS Ref,
	|	TSGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TSGoods.CCDNumber AS CCDNumber,
	|	SUM(TSGoods.Count) AS Count,
	|	SUM(TSGoods.QuantityByGBRN) AS QuantityByGBRN,
	|	SUM(TSGoods.AmountARAP) AS AmountARAP,
	|	SUM(TSGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	TSGoods.VATRate AS VATRate,
	|	TSGoods.Warehouse AS Warehouse,
	|	TSGoods.PurchaseOrder AS PurchaseOrder
	|INTO VtProductsForAnalystConnection
	|FROM
	|	Document.VendorInvoice.Goods AS TSGoods
	|WHERE
	|	TSGoods.Ref = &Ref
	|GROUP BY
	|	TSGoods.Ref,
	|	TSGoods.ItemsLocationAttributes,
	|	TSGoods.CCDNumber,
	|	TSGoods.VATRate,
	|	TSGoods.PurchaseOrder,
	|	TSGoods.Warehouse
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes,
	|	CCDNumber,
	|	PurchaseOrder,
	|	Warehouse";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			BaseCurrency IN (SELECT
	|				DefaultBaseCurrency.Value AS Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS RelativeExchangeRatesSliceLast
	|
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableOfGoods_(Query, QueryTexts, DocumentObject)
	
	RegisterName = "TemporaryTableOfGoods_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Goods.PartnerProducts AS PartnerProducts,
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	Goods.VendorPriceKind      AS VendorPriceKind,
	|	Goods.VendorPriceTypeCurrency AS VendorPriceTypeCurrency,
	|	Goods.Package               AS Package,
	|	CAST(Goods.Price
	|				* CASE
	|					WHEN
	|						&Currency <> VendorPriceTypes.Currency
	|					THEN
	|						CASE
	|							WHEN ISNULL(ExchangeRatesTypesOfSupplierPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(ExchangeRatesTypesOfSupplierPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(Currency_Rates.CourseNumerator * ExchangeRatesTypesOfSupplierPrices.CourseDenominator)
	|								/ (ExchangeRatesTypesOfSupplierPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|							ELSE
	|								0
	|						END
	|					ELSE 
	|						1
	|				END AS NUMBER(31,2))
	|	AS Price
	|INTO
	|	TemporaryTableOfGoods_
	|FROM
	|	DocumentDataTableItems AS Goods
	|LEFT JOIN
	|	Catalog.VendorPriceTypes AS VendorPriceTypes
	|ON
	|	VendorPriceTypes.Ref = Goods.VendorPriceKind
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS ExchangeRatesTypesOfSupplierPrices
	|ON
	|	ExchangeRatesTypesOfSupplierPrices.Currency = VendorPriceTypes.Currency
	|WHERE
	|	Goods.Ref = &Ref
	|	AND &RegisterVendorPrices
	|	AND (Goods.RowCode = 0 OR NOT Goods.PurchaseOrder.RegisterVendorPrices)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
		QueryText = StrReplace(QueryText, "Goods.PurchaseOrderRegisterVendorPrices", "Goods.PurchaseOrder.RegisterVendorPrices");
		QueryText = StrReplace(QueryText, "Goods.VendorPriceTypeCurrency", "Goods.VendorPriceKind.Currency");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts, DocumentObject)
	
	RegisterName = "ProductsWithDifferentPackagingPrices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
	|	Goods.VendorPriceKind               AS VendorPriceKind,
	|	AVG(
	|		Goods.Price / CASE
	|				WHEN
	|					Goods.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN
	|					&QueryTextPackagingFactor
	|				ELSE
	|					1
	|			END
	|	) AS PricePerBaseUnit,
	|	COUNT(DISTINCT Goods.Package)  AS NumberOfDifferentPackages
	|INTO
	|	ProductsWithDifferentPackagingPrices
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|GROUP BY
	|	Products,
	|	Characteristic,
	|	VendorPriceKind
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentObject = Undefined And Not DocumentObject.RegisterVendorPrices Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ProductsWithDifferentPackagingPrices", QueryTexts) Then
		QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	MAX(Goods.PartnerProducts) AS PartnerProducts,
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.VendorPriceKind                AS VendorPriceKind,
	|	Goods.VendorPriceTypeCurrency          AS Currency,
	|	&Period                                 AS Period,
	|	&Partner                                AS Partner,
	|	MIN(CASE
	|				WHEN
	|					ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|				THEN
	|					VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				ELSE
	|					Goods.Package
	|				END
	|			) AS Package,
	|	CAST(AVG(CASE
	|				WHEN
	|					ProductsWithDifferentPackagingPrices.NumberOfDifferentPackages > 1
	|				THEN
	|					ProductsWithDifferentPackagingPrices.PricePerBaseUnit
	|				ELSE
	|					Goods.Price
	|			END) AS NUMBER(31,2)) AS Price
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|LEFT JOIN
	|	ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	|ON
	|	Goods.Products = ProductsWithDifferentPackagingPrices.Products
	|	AND Goods.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	|	AND Goods.VendorPriceKind = ProductsWithDifferentPackagingPrices.VendorPriceKind
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|ON
	|	CurrencyRatesPrices.Currency = Goods.VendorPriceTypeCurrency
	|WHERE
	|	NOT Goods.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.VendorPriceKind,
	|	Goods.VendorPriceTypeCurrency
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "Goods.VendorPriceTypeCurrency", "Goods.VendorPriceKind.Currency");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;

	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency, Query.Parameters.ARAPCurrency, Query.Parameters.Period, Query.Parameters.Organization);
		
	Query.SetParameter("ConversionRateToManCurrency",            Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",           Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	TemporaryTableQueryTexts = New Map();
	
	FullDocumentName      = "Document.VendorInvoice";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessTransactionsImportPurchase",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport));
	// This name of the parameter is due to the presence of the "Currency" requisite, which makes
	// it impossible to use the name "Currency of the regulated account".
	ParameterValues.Insert("ControlCompanyStockBalanceForRegistrationByReceipts",
		GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	ParameterValues.Insert("UseTraceableImportedGoodsAccounting",
		AccountingForTraceableGoodsLocalization.UseTraceableImportedGoodsAccounting(Date(1,1,1)));
	ParameterValues.Insert("DateOfTraceableImportedGoodsAccountingStart",
		AccountingForTraceableGoodsLocalization.DateOfTraceableImportedGoodsAccountingStart());
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractIsOrder",
		"CASE WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|														  VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|														  VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|THEN
		|	TRUE
		|	   WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|THEN
		|	TRUE
		|ELSE
		|	FALSE
		|END");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"CASE WHEN GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|THEN
		|	TRUE
		|ELSE
		|	FALSE
		|END");
	RedefiningParameterCalculation.Insert("DocumentInflow",
		"CASE WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|														  VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|														  VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|THEN
		|	GoodsTable.Ref.Terms
		|WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|THEN
		|	GoodsTable.Ref.Contract
		|ELSE
		|	GoodsTable.Ref
		|END");
	RedefiningParameterCalculation.Insert("ByContractsAfterInvoices",
		"CASE WHEN GoodsTable.Ref.GoodsReceiptOption IN (VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices),
		|														  VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|THEN
		|	TRUE
		|ELSE
		|	FALSE
		|END");
	RedefiningParameterCalculation.Insert("BusinessTransactionForReceipt", 
		"CASE
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery)
		|		THEN VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportFromEAEUUninvoicedDelivery)
		|		THEN VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery)
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportReceiptFromGoodsInTransit)
		|		THEN VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|END");
	RedefiningParameterCalculation.Insert("UninvoicedReceiptDocumentIsUsed", 
		"CASE
		|	WHEN DocumentData.BusinessOperation IN(VALUE(Enum.BusinessTransactions.PurchaseFromVendorGoodsInTransit),
		|													VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
		|													VALUE(Enum.BusinessTransactions.ImportFromEAEUGoodsInTransit),
		|													VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|													VALUE(Enum.BusinessTransactions.ImportGoodsInTransit))
		|		THEN TRUE
		|	ELSE FALSE
		|END");
	RedefiningParameterCalculation.Insert("OperationOfImportingGoodsInTransitAndNonInvoicingIsUsed", 
		"CASE
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
		|		THEN TRUE
		|		ELSE FALSE
		|END");
	RedefiningParameterCalculation.Insert("UnfactuationOperationIsUsed", 
		"CASE
		|	WHEN DocumentData.BusinessOperation IN (
		|		VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery),
		|		VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt)
		|	) THEN TRUE
		|	ELSE FALSE
		|END");
	RedefiningParameterCalculation.Insert("Sender", 
		"CASE
		|	WHEN Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
		|		THEN Ref.AdvanceHolder
		|	ELSE Ref.Partner
		|END");
	
	If RegisterName = "PurchaseOrders" Then
		
		QueryText = QueryTextTablePurchaseOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "ItemsPricesOfVendor" Then
		
		QueryText = QueryTextTableItemsPricesOfVendor(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "CompanyGoods" Then
		TemporaryTableQueryTexts.Insert("TTTypesOfStocksForConnectingAnalytics",
			QueryTextTTTypesOfStocksForConnectingAnalytics(Query, QueryTexts));
		TemporaryTableQueryTexts.Insert("VtProductsForAnalystConnection",
			QueryTextVtProductsForAnalystConnection(Query, QueryTexts));
		QueryText = QueryTextTableCompanyGoods(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "GoodsForRegistrationOfImportDocuments" Then
		QueryText = QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTGoodsForRegistrationOfImportDocuments",
			QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts));
		TemporaryTableQueryTexts.Insert("TTTypesOfStocksForConnectingAnalytics",
			QueryTextTTTypesOfStocksForConnectingAnalytics(Query, QueryTexts));
		TemporaryTableQueryTexts.Insert("VtProductsForAnalystConnection",
			QueryTextVtProductsForAnalystConnection(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "FATable";
		
	ElsIf RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = QueryTextTableIntangibleAssetsDocuments(QueryTexts, RegisterName, Undefined);
		SynonymForDocumentTable = "TableOfIA";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments"
		Or RegisterName = "IntangibleAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
			
		If RegisterName = "PurchaseOrders" Then
			QueryText = StrReplace(QueryText, "DocumentTableUpdatingInformationSecurity.Ref.", "DocumentData.");
		EndIf;
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Warehouse                   AS StorageLocation,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Manager                AS EmployeeResponsible,
	|	DocumentData.Author                   AS Author,
	|	CAST(DocumentData.Comment AS STRING (100)) AS Comment,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.DocumentAmount          AS Sum,
	|	UNDEFINED                            AS Status,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	CASE
	|		WHEN DocumentData.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			THEN """"
	|		ELSE &ContractInformation
	|	END                                   AS More,
	|	DocumentData.IncomingDocumentDate  AS SourceDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	If Not DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "Document.VendorInvoice", "DocumentDataHeader");
	Else
		ContractInformationTemplate = "vi = 'Theo hợp đồng %1';
										|ru = 'По договору %1';
										|en = 'Under the %1 contract';
										|it = 'По договору %1';
										|pl = 'Under the %1 contract';
										|tr = '%1 sözleşmesi kapsamında'"; // @NStr
		QueryText = StrReplace(QueryText, "&ContractInformation", """" + ContractInformationTemplate + """");
		QueryText = StrReplace(QueryText, "%1", """" + " + CAST("""""""" AS STRING(1)) + 
			|CAST(DocumentData.Contract.Description AS STRING(150)) + CAST("""""""" AS STRING(1)) + "
			+ """");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0) AS RecNo,
	|	FATable.Ref                 AS Ref,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Department    AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Posted         AS Posted,
	|	FATable.DimensionOfExpenses      AS FixedAsset,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	TRUE AS RecordInTA
	|
	|FROM
	|	DocumentDataTableItems AS FATable
	|
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN DocumentDataTableItems AS DoublesTable
	|		ON DoublesTable.Ref = FATable.Ref
	|			AND DoublesTable.DimensionOfExpenses = FATable.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < FATable.LineNumber
	|			AND DoublesTable.ToExpenseAs
	|			AND (DoublesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND FATable.ToExpenseAs
	|	AND DoublesTable.Ref IS NULL
	|
	|	AND (FATable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR FATable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR FATable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND FATable.DimensionOfExpenses <> UNDEFINED
	|	AND (FATable.DimensionOfExpenses REFS Catalog.Assets
	|			AND FATable.DimensionOfExpenses <> VALUE(Catalog.Assets.EmptyRef)
	|		OR FATable.DimensionOfExpenses REFS Catalog.ConstructionObjects
	|			AND FATable.DimensionOfExpenses <> VALUE(Catalog.ConstructionObjects.EmptyRef))
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
	Else
		QueryText = StrReplace(QueryText, "FATable.Ref = &Ref", "TRUE");
	EndIf;

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableIntangibleAssetsDocuments(QueryTexts, Registers, DocumentObject)
	
	RegisterName = "IntangibleAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(TableOfIA.LineNumber-1, 0) AS RecNo,
	|	TableOfIA.Ref                AS Ref,
	|	DocumentData.Date             AS Date,
	|	DocumentData.Organization      AS Organization,
	|	DocumentData.Department    AS Department,
	|	&MetadataIdentifier         AS RefType,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Posted         AS Posted,
	|	TableOfIA.DimensionOfExpenses     AS IntangibleAsset,
	|	TRUE AS RecordInLocalAccounting,
	|	TRUE AS RecordInManAccounting,
	|	TRUE AS RecordInTA
	|
	|FROM
	|	DocumentDataTableItems AS TableOfIA
	|
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|		ON TableOfIA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN DocumentDataTableItems AS DoublesTable
	|		ON DoublesTable.Ref = TableOfIA.Ref
	|			AND DoublesTable.DimensionOfExpenses = TableOfIA.DimensionOfExpenses
	|			AND DoublesTable.LineNumber < TableOfIA.LineNumber
	|			AND DoublesTable.ToExpenseAs
	|			AND (DoublesTable.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				OR DoublesTable.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|WHERE
	|	TableOfIA.Ref = &Ref
	|	AND TableOfIA.ToExpenseAs
	|	AND DoublesTable.Ref IS NULL
	|
	|	AND (TableOfIA.ExpenseItem.CostAllocationOptionManag = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR TableOfIA.ExpenseItem.CostAllocationOptionLocal = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|		OR TableOfIA.ExpenseItem.CostAllocationOptionTax = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost))
	|
	|	AND TableOfIA.DimensionOfExpenses <> UNDEFINED
	|	AND TableOfIA.DimensionOfExpenses REFS Catalog.IntangibleAssets
	|	AND TableOfIA.DimensionOfExpenses <> VALUE(Catalog.IntangibleAssets.EmptyRef)
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataHeader", "Document.VendorInvoice");
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.VendorInvoice.Goods");
	Else
		QueryText = StrReplace(QueryText, "TableOfIA.Ref = &Ref", "TRUE");
	EndIf;

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers, DocumentObject)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	HouseholdValueOperations = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	HouseholdOperationsItems   = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	
	ArrayOfValueQueries = New Array;
	
	If HouseholdValueOperations.Find(DocumentObject.BusinessOperation) <> Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal 
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
	
	ValueText_ =
	"SELECT
	|	DocumentDataHeader.Date AS Period,
	|	Goods.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Department AS Department,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	DocumentDataHeader.Contract AS Contract,
	|	DocumentDataHeader.Shipper AS Shipper,
	|	Goods.Ref AS DocumentAcquisitions,
	|	Goods.Ref AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS ReduceAmountVATDeduction,
	|	UNDEFINED AS PurchaseAdjustmentDocument,
	|	DocumentDataHeader.VATTaxation AS VATTaxation,
	|	DocumentDataHeader.PurchaseForActivity AS VATActivityType,
	|	Goods.VATRate AS VATRate,
	|	CASE WHEN Goods.ToExpenseAs
	|		THEN UNDEFINED
	|		ELSE Goods.Products
	|	END AS Products,
	|	Goods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	Goods.CCDNumber AS CCDNumber,
	|	Goods.Department AS AccountingDivision,
	|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	Goods.ToExpenseAs	AS ToExpenseAs,
	|	Goods.ExpenseItem AS ExpenseItem,
	|	Goods.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS ItemOfOtherAssets,
	|	UNDEFINED AS AnalyticsOfOtherAssets,
	|	Goods.Purpose AS Purpose,
	|	Goods.RowID AS RowID,
	|	Goods.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS Goods
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON Goods.Ref = DocumentDataHeader.Ref
	|WHERE
	|	(NOT &UninvoicedReceiptDocumentIsUsed
	|		OR Goods.InventoriedLocationAttributesItemTypeOfItem IN (
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5)))
	|	AND (CASE
	|		WHEN DocumentDataHeader.ToReturnReusablePackage
	|			THEN Goods.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|	AND Goods.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)";
	
	ArrayOfValueQueries.Add(ValueText_);
	
	EndIf;
	
	If HouseholdValueOperations.Find(DocumentObject.BusinessOperation) <> Undefined
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Then
	
	ValueText_ =
	"SELECT
	|	DocumentDataHeader.Date AS Period,
	|	InventoryKinds.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Department AS Department,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	DocumentDataHeader.Contract AS Contract,
	|	DocumentDataHeader.Shipper AS Shipper,
	|	InventoryKinds.Ref AS DocumentAcquisitions,
	|	InventoryKinds.Ref AS OriginalTradeDocument,
	|	FALSE AS ErrorCorrection,
	|	FALSE AS AdjustmentUnderApprovalOfParties,
	|	FALSE AS ReduceAmountVATDeduction,
	|	UNDEFINED AS PurchaseAdjustmentDocument,
	|	DocumentDataHeader.VATTaxation AS VATTaxation,
	|	DocumentDataHeader.PurchaseForActivity AS VATActivityType,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.AnalysisOfAccountingForProductsProducts AS Products,
	|	InventoryKinds.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	UNDEFINED AS AccountingDivision,
	|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
	|	FALSE AS PurchasePerBatchOfProduction,
	|	UNDEFINED AS LineOfBusinessOfProductionParty,
	|	UNDEFINED AS ToExpenseAs,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	UNDEFINED AS ItemOfOtherAssets,
	|	UNDEFINED AS AnalyticsOfOtherAssets,
	|	InventoryKinds.ItemsLocationAttributes.Purpose AS Purpose,
	|	InventoryKinds.RowID AS RowID,
	|	InventoryKinds.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON InventoryKinds.Ref = DocumentDataHeader.Ref
	|WHERE
	|	&UninvoicedReceiptDocumentIsUsed
	|	AND (CASE
	|		WHEN DocumentDataHeader.ToReturnReusablePackage
	|			THEN InventoryKinds.InventoriedLocationAttributesItemTypeOfItem <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		ELSE
	|			TRUE
	|		END)
	|	AND InventoryKinds.BusinessTransactionSetting <> VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)
	|";
	
	ArrayOfValueQueries.Add(ValueText_);
	
	EndIf;
	
	ValueText_ = "";
	
	If ArrayOfValueQueries.Count() > 0 Then
		ValueText_ = StrConcat(ArrayOfValueQueries, TMCommonUse.QuerySeparatorInJoin());
	EndIf;
	
	TextProducts_1 = "";
	
	If HouseholdOperationsItems.Find(DocumentObject.BusinessOperation) <> Undefined Then
		
	TextProducts_1 = 
	"SELECT
	|	DocumentDataHeader.Date AS Period,
	|	Goods.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	Goods.Ref AS DocumentAcquisitions,
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Series AS Series,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.Count AS Count,
	|	Goods.RowID AS RowID
	|FROM
	|	DocumentDataTableItems AS Goods
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON Goods.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Goods.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|	AND NOT &NewWayToCreateApplicationForGoodsImportFromEAEU
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Date AS Period,
	|	Goods.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	Goods.Ref AS DocumentAcquisitions,
	|	Goods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	Goods.ItemsLocationAttributes.Products AS Products,
	|	Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	Goods.ItemsLocationAttributes.Series AS Series,
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.Count AS Count,
	|	Goods.RowID AS RowID
	|FROM
	|	DocumentDataTableOfInventoryOwnerAttributes AS Goods
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON Goods.Ref = DocumentDataHeader.Ref
	|WHERE
	|	Goods.InventoriedLocationAttributesItemTypeOfItem = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND &UninvoicedReceiptDocumentIsUsed
	|	AND NOT &NewWayToCreateApplicationForGoodsImportFromEAEU
	|";
	
	EndIf;
	
	If ValueText_ = "" And TextProducts_1 = "" Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts, DocumentObject);
	EndIf;
	
	If ValueIsFilled(ValueText_) Then
		VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	EndIf;
	
	If ValueIsFilled(TextProducts_1) Then
		ImportAccounting.ReflectImportOfGoodsFromCustomsUnion(Query, QueryTexts, Registers, TextProducts_1);
	EndIf;
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	BusinessTransactionsPurchasingFromSupplier  = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsImportPurchase    = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport);
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.ImportFromEAEU);
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";
	
	QueryTextExchangeRatesOfDocumentLinesOfBusiness = "
	|SELECT DISTINCT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.DocumentExchangeRateDate AS DateOfCourse,
	|	DocumentARAPObjects.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
	|FROM
	|	(SELECT
	|		PaymentScheduleSteps.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableStagesOfPaymentSchedule AS PaymentScheduleSteps
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		ARAPDetails.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableDecryptionOfPayment AS ARAPDetails
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentDataHeader.ObjectOfManCalculations AS ARAPObject
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableItems AS GoodsTable
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsTable.PurchaseOrder.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataTableItems AS GoodsTable
	|			INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|				ON DocumentDataHeader.Ref = GoodsTable.Ref
	|					AND DocumentDataHeader.ReceiptUnderOrders
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentDataHeader.Contract.ARAPObject AS ARAPObject
	|	FROM
	|		DocumentDataHeader AS DocumentDataHeader
	|	WHERE
	|		DocumentDataHeader.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice)
	|	) AS DocumentARAPObjects
	|		INNER JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON TRUE
	|WHERE
	|	DocumentARAPObjects.ARAPObject <> VALUE(Catalog.ARAPObjects.EmptyRef)
	|";

	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextExchangeRatesOfDocumentLinesOfBusiness);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion

	#Region Purchase

	If Not (BusinessTransactionsPurchasingFromSupplier.Find(DocumentObject.BusinessOperation) <> Undefined 
			Or BusinessTransactionsImportPurchase.Find(DocumentObject.BusinessOperation) <> Undefined
			Or BusinessTransactionsProcurementInEAEUCountries.Find(DocumentObject.BusinessOperation) <> Undefined
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		
		TextPurchase = "";
	
	Else
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                                 AS Ref,
		|	DocumentDataHeader.Organization               AS Organization,
		|	DocumentDataHeader.Partner                   AS Partner,
		|	DocumentDataHeader.Date                      AS RecorderDate,
		|	DocumentDataHeader.Number                     AS RecorderNumber,
		|
		|	Table.ARAPObject                         AS ARAPObject,
		|	Table.PaymentDate                            AS PaymentDate,
		|	Table.PaymentOption                          AS PaymentOption,
		|	CASE WHEN Table.ExceedingOrder
		|		THEN UNDEFINED
		|		ELSE Table.OrderDocument
		|	END                                          AS PurchaseOrder_,
		|	Table.PaymentAmount
		|		 + Table.PackageDepositValue               AS Sum,
		|	Table.AmountARAP
		|		 + Table.AmountARAPByPackage       AS AmountARAP,
		|	Table.AmountARAPByPackage              AS AmountARAPByPackage,
		|
		|	DocumentDataHeader.ARAPObjectSettings           AS ARAPObjectSettings,
		|	DocumentDataHeader.ReceiptUnderOrders      AS InvoiceForOrders,
		|	DocumentDataHeader.ARAPCurrency      AS ARAPCurrency,
		|	DocumentDataHeader.BusinessOperation     AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod               AS PaymentMethod,
		|	DocumentDataHeader.Currency                    AS DocumentCurrency,
		|	DocumentDataHeader.DocumentExchangeRateDate  AS DateOfCourse,
		|	UNDEFINED                                   AS LinkedDocument
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|";

	EndIf;
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	If Not (BusinessTransactionsPurchasingFromSupplier.Find(DocumentObject.BusinessOperation) <> Undefined 
			Or BusinessTransactionsImportPurchase.Find(DocumentObject.BusinessOperation) <> Undefined
			Or BusinessTransactionsProcurementInEAEUCountries.Find(DocumentObject.BusinessOperation) <> Undefined
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		
		TextPaymentPlan_ = "";
	
	Else
		
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                                                  AS Ref,
		|	DocumentDataHeader.Organization                                AS Organization,
		|	DocumentDataHeader.Partner                                    AS Partner,
		|	DocumentDataHeader.Date                                       AS RecorderDate,
		|	DocumentDataHeader.Number                                      AS RecorderNumber,
		|	Table.PaymentDate                                             AS PaymentDate,
		|	
		|	Table.ARAPObject                                          AS ARAPObject,
		|	DocumentDataHeader.ARAPObjectSettings                            AS ARAPObjectSettings,
		|	DocumentDataHeader.ReceiptUnderOrders                       AS InvoiceForOrders,
		|	Table.ExceedingOrder                                             AS ExceedingOrder,
		|	Table.OrderDocument                                                   AS PurchaseOrder_,
		|	Table.AmountARAP + Table.AmountARAPByPackage AS AmountDue,
		|	DocumentDataHeader.ARAPCurrency                       AS ARAPCurrency,
		|	DocumentDataHeader.BusinessOperation                      AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod                                AS PaymentMethod,
		|	DocumentDataHeader.Currency                                     AS DocumentCurrency,
		|	Table.PaymentOption                                           AS PaymentOption,
		|	UNDEFINED                                                    AS LinkedDocument
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|";

	EndIf;
	#EndRegion
	
	#Region TextProducts_1
	
	If Not (BusinessTransactionsPurchasingFromSupplier.Find(DocumentObject.BusinessOperation) <> Undefined 
			Or BusinessTransactionsImportPurchase.Find(DocumentObject.BusinessOperation) <> Undefined
			Or BusinessTransactionsProcurementInEAEUCountries.Find(DocumentObject.BusinessOperation) <> Undefined
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement) Then
		
		TextProducts_1 = "";
	
	Else
		
	TextProducts_1 = "
		|SELECT
		|	Table.Ref                                       AS Ref,
		|	DocumentDataHeader.Organization                     AS Organization,
		|	DocumentDataHeader.Partner                         AS Partner,
		|	DocumentDataHeader.Date                            AS RecorderDate,
		|	DocumentDataHeader.Number                           AS RecorderNumber,
		|	
		|	Table.ARAPObject                               AS ARAPObject,
		|	DocumentDataHeader.ARAPObjectSettings                 AS ARAPObjectSettings,
		|	DocumentDataHeader.ReceiptUnderOrders            AS InvoiceForOrders,
		|	Table.RowCode = 0                                AS ExceedingOrder,
		|	Table.PurchaseOrder                              AS PurchaseOrder_,
		|	Table.AmountARAP                          AS IncreaseToAdmission,
		|	Table.AmountARAP                          AS ReduceToAdmission,
		|	CASE WHEN DocumentDataHeader.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|		THEN 0
		|		ELSE Table.AmountARAP
		|	END                                                AS AmountARAP,
		|	DocumentDataHeader.ARAPCurrency            AS ARAPCurrency,
		|	DocumentDataHeader.BusinessOperation           AS BusinessOperation,
		|	DocumentDataHeader.Currency                          AS DocumentCurrency
		|FROM
		|	DocumentDataTableItems AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	(Table.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR DocumentDataHeader.PackageDepositIsRequired
		|		OR NOT DocumentDataHeader.ToReturnReusablePackage)
		|	AND NOT (Table.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.Work_5) 
		|		 AND NOT Table.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|		 AND Table.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
		|";

	EndIf;
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                                 AS Ref,
		|	DocumentDataHeader.Organization                                               AS Organization,
		|	DocumentDataHeader.Partner                                                   AS Partner,
		|
		|	ARAPObjects.Ref                                                         AS CalculationObjectReceiver,
		|	Table.ARAPObject                                                         AS CalculationObjectSource,
		|
		|	DocumentDataHeader.ARAPCurrency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                                    AS AmountARAP,
		|	DocumentDataHeader.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                                  AS Sum,
		|
		|	DocumentDataHeader.Date                                                      AS RecorderDate,
		|	DocumentDataHeader.DocumentExchangeRateDate                                  AS DateOfCourse,
		|	DocumentDataHeader.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)                     AS BusinessOperation
		|	
		|FROM
		|	DocumentDataTableDecryptionOfPayment AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ARAPObjects.Object = Table.Ref
		|				AND ARAPObjects.Organization = DocumentDataHeader.Organization
		|				AND NOT ARAPObjects.OnlyBalance
		|				AND NOT ARAPObjects.DeletionMark
		|";
		
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset, TextProducts_1);
	
	#Region PurchaseOnlyLocal
	If Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
		
		TextPayment = "";
	
	Else
		
	TextPayment = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	VALUE(Catalog.Companies.ManagementCompany)               AS Organization,
		|	Table.Partner                                                          AS Partner,
		|
		|	Table.ObjectOfManCalculations                                                AS ARAPObject,
		|	Table.Date                                                             AS RecorderDate,
		|	Table.Number                                                            AS RecorderNumber,
		|	Table.ARAPCurrency                                             AS ARAPCurrency,
		|	Table.Currency                                                           AS DocumentCurrency,
		|	Table.BusinessOperation                                            AS BusinessOperation,
		|
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.DocumentAmount                                                   AS Sum,
		|	0                                                                        AS SumCompl,
		|	0                                                                        AS SumMan,
		|	0                                                                        AS ReductionIsPaid,
		|	0                                                                        AS IncreaseIsPaid,
		|
		|	DATETIME(1,1,1)                                                         AS MaturityDate,
		|	Table.DocumentExchangeRateDate                                         AS DateOfCourse,
		|	UNDEFINED                                                             AS PaymentMethod,
		|	UNDEFINED                                                             AS CashFlowItem,
		|	UNDEFINED                                                             AS LinkedDocument,
		|	UNDEFINED                                                             AS PaymentRequest,
		|	&IDOfUnusedFinRecord                                    AS FinRecordID,
		|	UNDEFINED                                                             AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataHeader AS Table
		|WHERE
		|	Table.ObjectOfManCalculations <> VALUE(Catalog.ARAPObjects.EmptyRef)
		|";
		
	EndIf;
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		InitializeTrackingAnalyticsKeysForPartners(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableProducts");
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableProducts(Query, QueryTexts, Document);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts, Document);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(DocumentObject) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or	DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22 AND NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			THEN 0
	|	 	WHEN DocumentTable.BusinessOperation =  VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		  AND (&BatchAccountingVersion22 OR NOT &FIFORollingValuation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS Cost,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			THEN 0
	|	 	WHEN DocumentTable.BusinessOperation =  VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		  AND (&BatchAccountingVersion22 OR NOT &FIFORollingValuation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END											AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END											AS VATManag,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END											AS OffBalanceCost,
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0
	|	END											AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		  AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR NOT TableTypesOfStocks_.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND TableTypesOfStocks_.Count >= 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	EndIf;
	#EndRegion

	#Region ExternalInput_ReturnProduct

	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or	DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	DocumentTable.Ref		AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	-CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			THEN 0
	|	 	WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		 AND (&BatchAccountingVersion22 OR NOT &FIFORollingValuation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS Cost,
	|	-CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|			THEN 0
	|	 	WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.PurchaseFromVendorLocal)
	|		 AND (&BatchAccountingVersion22 OR NOT &FIFORollingValuation)
	|			THEN 0
	|			ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostExcludingVAT,
	|	-TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	-CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	-TableTypesOfStocks_.CostMan				AS CostMan,
	|	-CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	-CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS OffBalanceCost,
	|	-CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0
	|	END 											AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	CASE WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END 																  AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 							  AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting					  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR NOT TableTypesOfStocks_.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND TableTypesOfStocks_.Count < 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	#EndRegion
	
	#Region ExternalReceipt_GoodsUnderPrincipal
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
			Or	DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	0 												AS Cost,
	|	0 												AS CostExcludingVAT,
	|	0 												AS LocalCost,
	|	0												AS VATLocal,
	|	0												AS CostMan,
	|	0												AS VATManag,
	|	TableTypesOfStocks_.AmountIncludingVATMan					AS OffBalanceCost,
	|	TableTypesOfStocks_.AmountExcludingVATCompl
	|		+ TableTypesOfStocks_.VATAmountCompl 			AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ReceivingForPrincipal) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID						  AS FinRecordID,
	|	&BusinessTransactionSetting                 				  AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	 AND NOT TableTypesOfStocks_.ToExpenseAs
	|    AND TableTypesOfStocks_.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalReceipt_GoodsInTransit
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			Or	DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan					AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END											AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0 												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND TableTypesOfStocks_.Count >= 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalInput_ReturnGoodsInTransit
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
			Or	DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	DocumentTable.Ref		AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType 				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	-TableTypesOfStocks_.AmountIncludingVATMan				AS Cost,
	|	-TableTypesOfStocks_.AmountExcludingVATMan				AS CostExcludingVAT,
	|	-TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	-CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	-TableTypesOfStocks_.CostMan				AS CostMan,
	|	-CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0												AS OffBalanceCost,
	|	0 												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.OwnGoodsInTransitFromVendors)	AS AccountingSection,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ReturnOfGoodsToVendor)			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID										AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting  								AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND TableTypesOfStocks_.Count < 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalAdmission_Work_LocalAccounting
	
	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
				
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	VALUE(Catalog.Companies.ManagementCompany)	AS Organization,
	|	(CASE
	|		WHEN &DimensionInventoryItemsWithoutManAssignment
	|			THEN TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes END) AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute								AS InventoryOwnerAttribute,
	|	UNDEFINED												AS Lot,
	|	TableTypesOfStocks_.VATActivityType						AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType						AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED					AS LotVendorAttributes,
	|	UNDEFINED					AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	-TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	-TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	-TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	0												AS VATLocal,
	|	-TableTypesOfStocks_.CostMan				AS CostMan,
	|	0												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0 												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		  AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.Products.TracedGoods
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef) OR
	|		TableTypesOfStocks_.AssignmentTypeOfAssignment <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalEntry_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	TableTypesOfStocks_.VATActivityType 			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	CASE WHEN NOT (&BatchAccountingVersion22 AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE WHEN NOT (&BatchAccountingVersion22 AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	CASE WHEN &BatchAccountingVersion22 AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS OffBalanceCost,
	|	CASE WHEN &BatchAccountingVersion22 AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN
	|			CASE WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|				THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|				ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|			END
	|		ELSE 0
	|	END 											AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		  AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT &UnfacturedDeliveriesOfServicesWorks
	|	AND (TableTypesOfStocks_.Purpose = VALUE(Catalog.Assignments.EmptyRef) OR
	|		TableTypesOfStocks_.AssignmentTypeOfAssignment <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalReceipt_UnfactoredDeliveries

	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery
		Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt) Then

	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	TableTypesOfStocks_.CostMan					AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0 												AS OffBalanceCost,
	|	0 												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		  AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	#Region ExternalReceipt_UninvoicedDeliveries_WorksAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED				AS VariancePeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	TableTypesOfStocks_.VATRate					AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan 				AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan 				AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost 				AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	TableTypesOfStocks_.CostMan 				AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS VATManag,
	|	0 												AS OffBalanceCost,
	|	0 												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	CASE WHEN DocumentTable.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
	|		THEN TableTypesOfStocks_.CostTD
	|		ELSE 0
	|	END											AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.Work_5),
	|		VALUE(Enum.ItemsTypes.OperationService))
	|	AND &UnfacturedDeliveriesOfServicesWorks
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region Sales_Product_LocalAccounting

	If Not DocumentObject = Undefined 
		And (DocumentObject.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal) Then
			
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED			AS VariancePeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|
	// Item accounting fields
	|	VALUE(Catalog.Companies.ManagementCompany) 					AS Organization,
	|	(CASE
	|		WHEN &DimensionInventoryItemsWithoutManAssignment
	|			THEN TableTypesOfStocks_.AnalysisOfAccountingForProductsWithoutAssignment
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributes END) AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END 											AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	DocumentTable.Organization 					AS CorCompany,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute 		AS CorInventoryOwnerAttribute,
	|	DocumentTable.Ref							AS CorLot,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	UNDEFINED 									AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity 		AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 		AS BusinessOperation,
	|	&IDOfUnusedFinRecord		AS FinRecordID,
	|	&BusinessTransactionSetting	 			AS BusinessTransactionSetting 
	|
	|FROM
	|	DocumentDataHeader AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	OR (TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND TableTypesOfStocks_.Products.TracedGoods)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Receipt of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Mua hàng hóa';
									|ru = 'Приобретение товаров';
									|en = 'Purchase of goods'; fa = 'Purchase of goods';
									|it = 'Acquisto merci';
									|pl = 'Nabycie towarów';
									|tr = 'Mal alımları'");
	PrintCommand.CheckPostingBeforePrint = True;

	// Receipt invoice
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PurchaseInvoice";
	PrintCommand.Presentation = NStr("vi = 'Hóa đơn nhập hàng';
									|ru = 'Приходная накладная';
									|en = 'Purchase invoice'; fa = 'فاکتور خرید';
									|it = 'Bolla di acquisto';
									|pl = 'Faktura przyjęcie z zewnątrz';
									|tr = 'Sevk irsaliyesi'");
	PrintCommand.CheckPostingBeforePrint = True;

	// The act on the provision of services
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Act";
	PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
									|ru = 'Акт об оказании услуг';
									|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
									|it = 'Atto di prestazione dei servizi';
									|pl = 'Protokół świadczenia usług';
									|tr = 'Hizmet tutanağı'");
	PrintCommand.CheckPostingBeforePrint = True;

	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														Enums.BusinessTransactions.PurchaseFromVendorLocal,
														ComparisonType.NotEqual);

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.VendorInvoice";
		PrintCommand.Id = "PriceTags";
		PrintCommand.Presentation = NStr("vi = 'Nhãn giá';
										|ru = 'Ценники';
										|en = 'Price tags'; fa = 'برچسب‌های قیمت';
										|it = 'Cartellini del prezzo';
										|pl = 'Price tags';
										|tr = 'Fiyat etiketleri'");
		PrintCommand.CheckPostingBeforePrint = True;

		// Labels
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "Document.VendorInvoice";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	VendorInvoiceLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray - See PrintManagementOverridable.OnPrint.ObjectsArray
//  PrintParameters - See PrintManagementOverridable.OnPrint.PrintParameters
//  PrintFormsCollection - See PrintManagementOverridable.OnPrint.PrintFormsCollection
//  PrintObjects - See PrintManagementOverridable.OnPrint.PrintObjects
//  OutputParameters - See PrintManagementOverridable.OnPrint.OutputParameters
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Invoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Invoice", NStr("vi = 'Phiếu nhập kho';
																									|ru = 'Накладная';
																									|en = 'Invoice'; fa = 'فاکتور';
																									|it = 'Lettera di vettura';
																									|pl = 'Invoice';
																									|tr = 'İrsaliye'"), FormPrintedFormInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchaseInvoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PurchaseInvoice", NStr("vi = 'Hóa đơn nhập hàng';
																											|ru = 'Приходная накладная';
																											|en = 'Purchase invoice'; fa = 'فاکتور خرید';
																											|it = 'Bolla di acquisto';
																											|pl = 'Faktura przyjęcie z zewnątrz';
																											|tr = 'Sevk irsaliyesi'"), FormPrintedFormReceiptInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "Act") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "Act", NStr("vi = 'Biên bản cung cấp dịch vụ';
																								|ru = 'Акт об оказании услуг';
																								|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
																								|it = 'Atto di prestazione dei servizi';
																								|pl = 'Protokół świadczenia usług';
																								|tr = 'Hizmet tutanağı'"), FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	VendorInvoiceLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////
	|// REQUEST BY HEADER
	|
	|SELECT
	|	VendorInvoice.Ref                                   AS Ref,
	|	VendorInvoice.Number                                    AS Number,
	|	VendorInvoice.Date                                     AS Date,
	|	VendorInvoice.Partner                                  AS Partner,
	|	VendorInvoice.Counterparty                               AS Vendor,
	|	VendorInvoice.Organization                              AS Organization,
	|	VendorInvoice.Organization.Prefix                      AS Prefix,
	|	VendorInvoice.Currency                                   AS Currency,
	|	VendorInvoice.PriceIncludesVAT                          AS PriceIncludesVAT,
	|	VendorInvoice.ReceivedBy                                   AS GettingProduced,
	|	CASE
	|		WHEN
	|			VendorInvoice.VATTaxation IN (VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|															VALUE(Enum.VATTaxationTypes.DigitalServices))
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ConsiderVAT
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|
	|WHERE
	|	VendorInvoice.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|// QUERY BY TABLE PARTS
	|
	|SELECT
	|	NestedQuery.Ref                                                     AS Ref,
	|	NestedQuery.Products                                               AS Products,
	|	NestedQuery.Products.DescriptionFull                            AS ProductNameFull_,
	|	NestedQuery.Products.Code                                           AS Code,
	|	NestedQuery.Products.SKU                                       AS SKU,
	|	NestedQuery.UnitOfMeasure.Description                              AS UnitPrice,
	|	NestedQuery.UnitOfMeasure                                           AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull                          AS Characteristic,
	|	NestedQuery.Series.Description							               AS Series,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|		THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                                                      AS Package,
	|	NestedQuery.VATRate                                                  AS VATRate,
	|	NestedQuery.Price                                                       AS Price,
	|	NestedQuery.Count                                                 AS Count,
	|	NestedQuery.Sum                                                      AS Sum,
	|	NestedQuery.VATAmount                                                   AS VATAmount,
	|	NestedQuery.DiscountAmount                                                AS DiscountAmount,
	|	NestedQuery.AmountWithoutADiscount                                             AS AmountWithoutADiscount,
	|	NestedQuery.LineNumber                                                AS LineNumber,
	|	CASE
	|		WHEN
	|			NestedQuery.Ref.ToReturnReusablePackage
	|			AND NestedQuery.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|FROM (
	|	SELECT
	|		VendorInvoice.Ref AS Ref,
	|		VendorInvoice.Products AS Products,
	|
	|		CASE WHEN VendorInvoice.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			1
	|		ELSE
	|			&QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|
	|		CASE WHEN VendorInvoice.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			VendorInvoice.Products.UnitOfMeasure
	|		ELSE
	|			VendorInvoice.Package
	|		END AS UnitOfMeasure,
	|
	|		VendorInvoice.PercentRateOfManualDiscount         AS DiscountPercentage,
	|		VendorInvoice.Characteristic              AS Characteristic,
	|		VendorInvoice.Series              			AS Series,
	|		VendorInvoice.Package                    AS Package,
	|		VendorInvoice.VATRate                   AS VATRate,
	|		VendorInvoice.Price                        AS Price,
	|		VendorInvoice.NumberOfPackages          AS Count,
	|		VendorInvoice.Sum                       AS Sum,
	|		VendorInvoice.ManualDiscount           AS DiscountAmount,
	|		VendorInvoice.Sum +
	|		VendorInvoice.ManualDiscount           AS AmountWithoutADiscount,
	|		VendorInvoice.VATAmount                    AS VATAmount,
	|		VendorInvoice.LineNumber                 AS LineNumber
	|	FROM
	|		Document.VendorInvoice.Goods AS VendorInvoice
	|	WHERE
	|		VendorInvoice.Ref IN (&DocumentsArray)
	|		AND VendorInvoice.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref
	|");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"VendorInvoice.Package",
			"VendorInvoice.Products"));
	
	Query.SetParameter("DocumentsArray", 				ObjectsArray);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_VendorInvoice_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there are only services in the invoice, let's move on to the next document
		
		If FollowingIsFound Then
			ProductSelection_1 = SelectionByDocuments.Select();
			DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(ProductSelection_1, UseManualDiscounts);
			ThereAreDiscounts = DiscountHeader.ThereAreDiscounts;
			ProductSelection_1.Reset();
		Else
			Continue;
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.VendorInvoice.PF_MXL_UninvoicedReceipt");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(
			PrintData,
			NStr("vi = 'Mua hàng hóa';
				|ru = 'Приобретение товаров';
				|en = 'Purchase of goods'; fa = 'Purchase of goods';
				|it = 'Acquisto merci';
				|pl = 'Nabycie towarów';
				|tr = 'Mal alımları'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Vendor, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Vendor);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1 = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Organization);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		
		If ThereAreDiscounts Then
			ProductColumnArea = Template.Area("DiscountedProduct");
		Else
			ProductColumnArea = Template.Area("OwnGoods");
		EndIf;
			
		If Not OutputCodes Then
			
			If ThereAreDiscounts Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.35;
			Else
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
			EndIf;
			
		EndIf;
		
		If ThereAreDiscounts Then
			
			RoomArea  = Template.GetArea("TableHeaderWithDiscount|LineNumber");
			AreaCodes   = Template.GetArea("TableHeaderWithDiscount|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableHeaderWithDiscount|DiscountedProduct");
			DataArea  = Template.GetArea("TableHeaderWithDiscount|DiscountedData");
			
			StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount", 
				DiscountHeader.Discount,
				DiscountHeader.DiscountAmount);
			DataArea.Parameters.Fill(StructureOfDiscountHeader);
			
		Else
			
			RoomArea  = Template.GetArea("TableHeader|LineNumber");
			AreaCodes   = Template.GetArea("TableHeader|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableHeader|OwnGoods");
			DataArea  = Template.GetArea("TableHeader|Data");
			
		EndIf;
			
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
			
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		If ThereAreDiscounts Then
			
			RoomArea  = Template.GetArea("TableRowWithDiscount|LineNumber");
			AreaCodes   = Template.GetArea("TableRowWithDiscount|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableRowWithDiscount|DiscountedProduct");
			DataArea  = Template.GetArea("TableRowWithDiscount|DiscountedData");
			
		Else
			
			RoomArea  = Template.GetArea("TableRow|LineNumber");
			AreaCodes   = Template.GetArea("TableRow|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableRow|OwnGoods");
			DataArea  = Template.GetArea("TableRow|Data");
			
		EndIf;
			
		Sum          = 0;
		VATAmount       = 0;
		TotalOfDiscounts    = 0;
		LineNumber    = 0;
		TotalWithoutDiscounts = 0;
		
		// Output the rows of the Goods table
			
		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			DataStructureLineNumber = New Structure("LineNumber", LineNumber);
			RoomArea.Parameters.Fill(DataStructureLineNumber);
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();			
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				ProductSelection_1.Series,
				AdditionalParametersForGettingNameToPrint);
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			ProductArea.Parameters.Fill(ProductDataStructure);
			
			SpreadsheetDocument.Join(ProductArea);

			DataArea.Parameters.Fill(ProductSelection_1);
			If DiscountHeader.ThereAreDiscounts Then
				DataStructureDiscountAmount = New Structure("DiscountAmount", 
					?(DiscountHeader.OnlyMarkUp,- ProductSelection_1.DiscountAmount,ProductSelection_1.DiscountAmount));
				DataArea.Parameters.Fill(DataStructureDiscountAmount);
			EndIf;

			SpreadsheetDocument.Join(DataArea);
			
			Sum          = Sum          + ProductSelection_1.Sum;
			VATAmount       = VATAmount       + ProductSelection_1.VATAmount;
			
			If ThereAreDiscounts Then
				TotalOfDiscounts    = TotalOfDiscounts    + ProductSelection_1.DiscountAmount;
				TotalWithoutDiscounts = TotalWithoutDiscounts + ProductSelection_1.AmountWithoutADiscount;
			EndIf;
			
		EndDo;
		
		// We output the basement
		
		If ThereAreDiscounts Then
			
			RoomArea  = Template.GetArea("BasementTablesAtDiscount|LineNumber");
			AreaCodes   = Template.GetArea("BasementTablesAtDiscount|ColumnOfCodes");
			ProductArea   = Template.GetArea("BasementTablesAtDiscount|DiscountedProduct");
			DataArea  = Template.GetArea("BasementTablesAtDiscount|DiscountedData");
			
		Else
			
			RoomArea  = Template.GetArea("TableFooter|LineNumber");
			AreaCodes   = Template.GetArea("TableFooter|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableFooter|OwnGoods");
			DataArea  = Template.GetArea("TableFooter|Data");
			
		EndIf;
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		DataStructureOfWholeDiscount = New Structure;
		If ThereAreDiscounts Then
			DataStructureOfWholeDiscount.Insert("TotalOfDiscounts", ?(DiscountHeader.OnlyMarkUp,-TotalOfDiscounts, TotalOfDiscounts));
			DataStructureOfWholeDiscount.Insert("TotalWithoutDiscounts", TotalWithoutDiscounts);
		EndIf;
		DataStructureOfWholeDiscount.Insert("Total",  PrintFormGeneration.SumFormat(Sum));
		DataArea.Parameters.Fill(DataStructureOfWholeDiscount);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		
		If PrintData.ConsiderVAT Then
			
			If ThereAreDiscounts Then
				
				RoomArea  = Template.GetArea("BasementTableVATDiscount|LineNumber");
				AreaCodes   = Template.GetArea("BasementTableVATDiscount|ColumnOfCodes");
				ProductArea   = Template.GetArea("BasementTableVATDiscount|DiscountedProduct");
				DataArea  = Template.GetArea("BasementTableVATDiscount|DiscountedData");
				
			Else
				
				RoomArea  = Template.GetArea("VATTableBasement|LineNumber");
				AreaCodes   = Template.GetArea("VATTableBasement|ColumnOfCodes");
				ProductArea   = Template.GetArea("VATTableBasement|OwnGoods");
				DataArea  = Template.GetArea("VATTableBasement|Data");
				
			EndIf;
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			
			VATDataStructure = New Structure;
			VATDataStructure.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			VATDataStructure.Insert("VAT", ?(PrintData.PriceIncludesVAT,
				NStr("vi = 'Trong đó thuế GTGT:';
					|ru = 'В том числе НДС:';
					|en = 'Including VAT:'; fa = 'Including VAT:';
					|it = 'IVA compresa:';
					|pl = 'W tym VAT';
					|tr = 'KDV dahil:'", Common.DefaultLanguageCode()),
				NStr("vi = 'Thuế GTGT:';
					|ru = 'Сумма НДС:';
					|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
					|it = 'Importo IVA:';
					|pl = 'Wartość VAT';
					|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			DataArea.Parameters.Fill(VATDataStructure);
			SpreadsheetDocument.Join(DataArea);
			
		EndIf;
		
		// We output the Amount in words
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số %1, thành tiền %2';
				|ru = 'Всего наименований %1, на сумму %2';
				|en = 'Total items %1 in the amount of %2'; fa = 'Total items %1 in the amount of %2';
				|it = 'Totale articoli %1, per importo di %2';
				|pl = 'Razem pozycji %1, na kwotę %2';
				|tr = 'Toplam tanım %1, tutar %2'", Common.DefaultLanguageCode()),
			ProductSelection_1.Count(),
			PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
	
		DataStructureSummaryRow = New Structure;
		DataStructureSummaryRow.Insert("TotalString", TotalString);
		DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.GettingProduced) Then
			DataStructureGettingProduced = New Structure;
			DataStructureGettingProduced.Insert("GettingProduced", PersonsTM.IndividualShortName(PrintData.GettingProduced, PrintData.Date));
			TemplateArea.Parameters.Fill(DataStructureGettingProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction

// Returns the address in the temporary storage for the generated data collection used for printing labels.
//
// Parameters:
//	DocumentsArray - Array of DocumentRef.VendorInvoice - a collection of document references used
//																			to prepare label printing data.
//
// Returns:
//	String - the address in the temporary storage for the generated collection of data used for printing labels.
//
Function LabelPrintingData(DocumentsArray) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TableOfGoods.Ref						AS Ref,
	|	CASE
	|		WHEN ISNULL(WarehouseData_1.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|			THEN TRUE
	|		ELSE FALSE
	|	END										AS RetailStore,
	|	CASE
	|		WHEN WarehouseData_1.RetailPriceType IS NULL
	|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|		ELSE WarehouseData_1.RetailPriceType
	|	END										AS RetailPriceType,
	|	MIN(TableOfGoods.LineNumber)			AS Order,
	|	TableOfGoods.Products					AS Products,
	|	TableOfGoods.Characteristic				AS Characteristic,
	|	CASE
	|		WHEN TheseCharacteristics.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE TheseCharacteristics.ItemsCharacteristicForPricing
	|	END										AS PricingVariant,
	|	TableOfGoods.Series						AS Series,
	|	CASE
	|		WHEN SeriesData.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE SeriesData.ItemsBatchForPricing
	|	END										AS PricingBatch,
	|	TableOfGoods.Package						AS Package,
	|	SUM(TableOfGoods.NumberOfPackages)	AS Count
	|INTO TableOfProductsToRequest
	|FROM
	|	Document.VendorInvoice.Goods AS TableOfGoods
	|		LEFT JOIN Document.VendorInvoice AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.Warehouses AS WarehouseData_1
	|		ON HeaderData_.Warehouse = WarehouseData_1.Ref
	|		
	|		LEFT JOIN Catalog.ItemsCharacteristics AS TheseCharacteristics
	|		ON TableOfGoods.Characteristic = TheseCharacteristics.Ref
	|		
	|		LEFT JOIN Catalog.ItemsBatches AS SeriesData
	|		ON TableOfGoods.Series = SeriesData.Ref
	|
	|WHERE
	|	TableOfGoods.Ref IN (&DocumentsArray)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	CASE
	|		WHEN ISNULL(WarehouseData_1.WarehouseStore, UNDEFINED) = VALUE(Enum.TypesOfWarehouses.RetailStore)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	CASE
	|		WHEN WarehouseData_1.RetailPriceType IS NULL
	|			THEN VALUE(Catalog.TypesOfPrices.EmptyRef)
	|		ELSE WarehouseData_1.RetailPriceType
	|	END,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	CASE
	|		WHEN TheseCharacteristics.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|		ELSE TheseCharacteristics.ItemsCharacteristicForPricing
	|	END,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN SeriesData.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE SeriesData.ItemsBatchForPricing
	|	END,
	|	TableOfGoods.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfGoods.Ref				AS Ref,
	|	TableOfGoods.Products			AS Products,
	|	TableOfGoods.Characteristic		AS Characteristic,
	|	COUNT(TableOfGoods.Package)	AS NumberOfPackages
	|INTO TableOfProductsGrouped
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	TableOfSeries.Series				AS Series,
	|	CASE
	|		WHEN SeriesData.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE SeriesData.ItemsBatchForPricing
	|	END							AS PricingBatch,
	|	SUM(TableOfSeries.Count)	AS Count
	|INTO DocumentSeriesTable
	|FROM
	|	Document.VendorInvoice.SetOfSeries AS TableOfSeries
	|		LEFT JOIN Catalog.ItemsBatches AS SeriesData
	|		ON TableOfSeries.Series = SeriesData.Ref
	|
	|WHERE
	|	TableOfSeries.Ref IN (&DocumentsArray)
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Series,
	|	CASE
	|		WHEN SeriesData.Ref IS NULL
	|			THEN VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)
	|		ELSE SeriesData.ItemsBatchForPricing
	|	END
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	COUNT(TableOfSeries.Series)	AS SeriesCount
	|INTO SeriesTableGrouped
	|FROM
	|	DocumentSeriesTable AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfSeries.PricingBatch		AS PricingBatch,
	|	TableOfGoods.Package		AS Package,
	|	TableOfSeries.Count / ISNULL(&QueryTextPackagingFactor1, 1) AS Count
	|INTO SeriesTableForQuery
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN DocumentSeriesTable AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages = 1)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfSeries.PricingBatch		AS PricingBatch,
	|	TableOfGoods.Package		AS Package,
	|	TableOfGoods.Count	AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN DocumentSeriesTable AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages > 1)
	|	AND (TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			SeriesTableGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.SeriesCount = 1)
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic,
	|	TableOfSeries.Series			AS Series,
	|	TableOfSeries.PricingBatch		AS PricingBatch,
	|	TableOfSeries.Package		AS Package,
	|	TableOfSeries.Count		AS Count
	|INTO TableOfSeries
	|FROM
	|	InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		INNER JOIN SeriesTableForQuery AS TableOfSeries
	|		ON ItemsBarcodes.Products = TableOfSeries.Products
	|			AND ItemsBarcodes.Characteristic = TableOfSeries.Characteristic
	|			AND ItemsBarcodes.Series = TableOfSeries.Series
	|			AND ItemsBarcodes.Package = TableOfSeries.Package
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.Ref				AS Ref,
	|	TableOfSeries.Products		AS Products,
	|	TableOfSeries.Characteristic		AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.ItemsBatchesForPricing.EmptyRef) AS PricingBatch,
	|	TableOfSeries.Package			AS Package,
	|	SUM(TableOfSeries.Count)	AS Count
	|FROM
	|	SeriesTableForQuery AS TableOfSeries
	|		LEFT JOIN InformationRegister.ItemsBarcodes AS ItemsBarcodes
	|		ON TableOfSeries.Products = ItemsBarcodes.Products
	|			AND TableOfSeries.Characteristic = ItemsBarcodes.Characteristic
	|			AND TableOfSeries.Series = ItemsBarcodes.Series
	|			AND TableOfSeries.Package = ItemsBarcodes.Package
	|
	|WHERE
	|	ItemsBarcodes.Barcode IS NULL
	|
	|GROUP BY
	|	TableOfSeries.Ref,
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Package
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(TableOfGoods.Order)	AS Order,
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic,
	|	TableOfGoods.Series			AS Series,
	|	CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|		ELSE TableOfGoods.Package
	|	END							AS Package,
	|	SUM(CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN TableOfGoods.Count * (ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1))
	|		ELSE TableOfGoods.Count
	|	END)							AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON TableOfGoods.Products = ItemsPrices.Products
	|			AND TableOfGoods.PricingVariant = ItemsPrices.PricingVariant
	|			AND TableOfGoods.PricingBatch = ItemsPrices.PricingBatch
	|			AND TableOfGoods.RetailPriceType = ItemsPrices.PriceKind
	|
	|WHERE
	|	(TableOfGoods.Ref, TableOfGoods.Products, TableOfGoods.Characteristic, TableOfGoods.Package) NOT IN
	|		(SELECT
	|			TableOfSeries.Ref			AS Ref,
	|			TableOfSeries.Products	AS Products,
	|			TableOfSeries.Characteristic	AS Characteristic,
	|			TableOfSeries.Package		AS Package
	|		FROM
	|			TableOfSeries AS TableOfSeries)
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfGoods.Series,
	|	CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|		ELSE TableOfGoods.Package
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	MIN(TableOfGoods.Order)	AS Order,
	|	TableOfGoods.Products		AS Products,
	|	TableOfGoods.Characteristic	AS Characteristic,
	|	TableOfSeries.Series				AS Series,
	|	CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|		ELSE TableOfGoods.Package
	|	END							AS Package,
	|	SUM(CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN TableOfSeries.Count * (ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1))
	|		ELSE TableOfSeries.Count
	|	END)							AS Count
	|FROM
	|	TableOfProductsToRequest AS TableOfGoods
	|		INNER JOIN TableOfSeries AS TableOfSeries
	|		ON TableOfGoods.Ref = TableOfSeries.Ref
	|			AND TableOfGoods.Products = TableOfSeries.Products
	|			AND TableOfGoods.Characteristic = TableOfSeries.Characteristic
	|			AND TableOfGoods.Package = TableOfSeries.Package
	|		
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON TableOfGoods.Products = ItemsPrices.Products
	|			AND TableOfGoods.PricingVariant = ItemsPrices.PricingVariant
	|			AND TableOfSeries.PricingBatch = ItemsPrices.PricingBatch
	|			AND TableOfGoods.RetailPriceType = ItemsPrices.PriceKind
	|			AND TableOfGoods.RetailStore
	|
	|GROUP BY
	|	TableOfGoods.Products,
	|	TableOfGoods.Characteristic,
	|	TableOfSeries.Series,
	|	CASE
	|		WHEN TableOfGoods.RetailStore
	|			THEN ISNULL(ItemsPrices.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))
	|		ELSE TableOfGoods.Package
	|	END
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfSeries.Ref			AS Ref,
	|	TableOfSeries.Products	AS Products,
	|	TableOfSeries.Characteristic	AS Characteristic
	|FROM
	|	DocumentSeriesTable AS TableOfSeries
	|
	|WHERE
	|	(TableOfSeries.Ref, TableOfSeries.Products, TableOfSeries.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			TableOfProductsGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.NumberOfPackages > 1)
	|	AND (TableOfSeries.Ref, TableOfSeries.Products, TableOfSeries.Characteristic) IN
	|		(SELECT
	|			GroupingTable.Ref			AS Ref,
	|			GroupingTable.Products		AS Products,
	|			GroupingTable.Characteristic	AS Characteristic
	|		FROM
	|			SeriesTableGrouped AS GroupingTable
	|		WHERE
	|			GroupingTable.SeriesCount > 1)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	HeaderData_.Organization				AS Organization,
	|	HeaderData_.Warehouse					AS Warehouse,
	|	HeaderData_.Warehouse.RetailPriceType	AS PriceKind
	|FROM
	|	Document.VendorInvoice AS HeaderData_
	|WHERE
	|	HeaderData_.Ref IN (&DocumentsArray)";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	QueryResult = Query.ExecuteBatch();
	
	DetailsOfDocuments = QueryResult[QueryResult.UBound()].Unload();
	
	Companies	= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "Organization");
	Warehouses		= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "Warehouse");
	TypesOfPrices		= TMCommonUse.UniqueValuesFromTableColumn(DetailsOfDocuments, "PriceKind");
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(Companies.Count() = 1, Companies[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse", ?(Warehouses.Count() = 1, Warehouses[0], Warehouses));
	StructureOfActions.Insert("FillInPriceView", ?(TypesOfPrices.Count() = 1, TypesOfPrices[0], Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintLabels");
	StructureOfActions.Insert("FillInTheNumberOfLabelsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of processing the printing of price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Date",						TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray));
	ResultingStructure.Insert("Goods",					QueryResult[QueryResult.UBound() - 2].Unload());
	ResultingStructure.Insert("ErrorTableBySeries",	QueryResult[QueryResult.UBound() - 1].Unload());
	ResultingStructure.Insert("StructureOfActions",		StructureOfActions);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

// The function puts the necessary data in the structure. The structure is placed in temporary storage.
//
// Returns:
//	String - the address of the data structure in the temporary storage.
//
Function DataForPrintingPriceTags(DocumentsArray) Export
	
	PricingDate = TMCommonUse.GetMaximumDateOfDocuments(DocumentsArray);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PurchaseOfGoodsServicesGoods.Products   AS Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic AS Characteristic,
	|	PurchaseOfGoodsServicesGoods.Series          AS Series,
	|
	|	CASE WHEN PurchaseOfGoodsServicesGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.Package
	|	ELSE
	|		PurchaseOfGoodsServicesGoods.Package
	|	END AS Package,
	|
	|	MIN(PurchaseOfGoodsServicesGoods.LineNumber) AS Order,
	|	SUM(
	|		CASE WHEN PurchaseOfGoodsServicesGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|			PurchaseOfGoodsServicesGoods.NumberOfPackages * (ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1))
	|		ELSE
	|			PurchaseOfGoodsServicesGoods.NumberOfPackages
	|		END) AS Count
	|FROM
	|	Document.VendorInvoice.Goods AS PurchaseOfGoodsServicesGoods
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON ItemsPrices.Products     = PurchaseOfGoodsServicesGoods.Products
	|			AND ItemsPrices.PricingVariant = PurchaseOfGoodsServicesGoods.Characteristic.ItemsCharacteristicForPricing
	|			AND ItemsPrices.PricingBatch          = PurchaseOfGoodsServicesGoods.Series.ItemsBatchForPricing
	|			AND ItemsPrices.PriceKind          = PurchaseOfGoodsServicesGoods.Ref.Warehouse.RetailPriceType
	|	
	|WHERE
	|	PurchaseOfGoodsServicesGoods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	PurchaseOfGoodsServicesGoods.Products,
	|	PurchaseOfGoodsServicesGoods.Characteristic,
	|	PurchaseOfGoodsServicesGoods.Series,
	|	CASE WHEN PurchaseOfGoodsServicesGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.Package
	|	ELSE
	|		PurchaseOfGoodsServicesGoods.Package
	|	END
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	VendorInvoice.Organization            AS Organization,
	|	VendorInvoice.Warehouse                  AS Warehouse,
	|	VendorInvoice.Warehouse.RetailPriceType AS PriceKind
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|WHERE
	|	VendorInvoice.Ref IN(&DocumentsArray)";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"PurchaseOfGoodsServicesGoods.Package",
			"PurchaseOfGoodsServicesGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ItemsPrices.Package",
			"ItemsPrices.Products"));
	
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	ResultsArray = Query.ExecuteBatch();
	
	TableDocumentDetails = ResultsArray[1].Unload();
	CompanyArray = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Organization");
	WarehouseArray     = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "Warehouse");
	ArrayOfPriceTypes    = TMCommonUse.UniqueValuesFromTableColumn(TableDocumentDetails, "PriceKind");
	
	// Preparation of the action structure for processing the printing of price tags and labels
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInOrganization", ?(CompanyArray.Count() = 1, CompanyArray[0], Undefined));
	StructureOfActions.Insert("FillInTheWarehouse",       ?(WarehouseArray.Count() = 1,     WarehouseArray[0],     WarehouseArray));
	StructureOfActions.Insert("FillInPriceView",     ?(ArrayOfPriceTypes.Count() = 1,    ArrayOfPriceTypes[0],    Undefined));
	StructureOfActions.Insert("ShowQuantityColumnInDocument", True);
	StructureOfActions.Insert("SetPrintModeFromDocument");
	StructureOfActions.Insert("SetMode", "PrintingPriceTags");
	StructureOfActions.Insert("FillInTheNumberOfPriceTagsForTheDocument");
	StructureOfActions.Insert("FillInTheGoodsTable");
	
	// Preparation of data for filling in the tabular part of processing the printing of price tags and labels.
	ResultingStructure = New Structure;
	ResultingStructure.Insert("Goods", ResultsArray[0].Unload());
	ResultingStructure.Insert("StructureOfActions", StructureOfActions);
	ResultingStructure.Insert("Date",              PricingDate);
	
	Return PutToTempStorage(ResultingStructure);
	
EndFunction

Function FormPrintedFormReceiptInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_VendorInvoice_PurchaseInvoice";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	PackagingUsage = GetFunctionalOption("UseItemPackages");
	
	Query = New Query(
	"SELECT DISTINCT
	|	Documents.Ref AS Ref,
	|	Documents.Organization AS Organization,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	Documents.Organization.Prefix AS Prefix
	|FROM
	|	Document.VendorInvoice AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.Warehouse AS Warehouse,
	|	&QueryTextUnitOfMeasureDescription AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.Products.UnitOfMeasure) AS PresentationOfBasicUnitOfMeasure,
	|	Goods.NumberOfPackages AS NumberOfPackages,
	|	Goods.Count AS Count,
	|	Goods.Products.Code AS Code,
	|	Goods.Products.SKU AS SKU,
	|	Goods.Products.DescriptionFull AS Products,
	|	Goods.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1
	|			THEN UNDEFINED
	|		ELSE Goods.Package.Description
	|	END AS Package,
	|	CASE
	|		WHEN
	|			Goods.Ref.ToReturnReusablePackage
	|			AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage
	|FROM
	|	Document.VendorInvoice.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|	AND Goods.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	Goods.LineNumber
	|TOTALS BY
	|	Ref,
	|	Warehouse");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Description",
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	Template = PrintManagement.PrintFormTemplate("Document.VendorInvoice.PF_MXL_PurchaseInvoice");
	
	Offset_ = SpreadsheetDocumentShiftType.Vertical;
	WidthOfDeletedColumns = 0;
	If ColumnOfCodes <> "SKU" Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("SKU").ColumnWidth;
		Template.DeleteArea(Template.Area("SKU"), Offset_);
	EndIf;
	If ColumnOfCodes<>"Code" Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("Code").ColumnWidth;
		Template.DeleteArea(Template.Area("Code"), Offset_);
	EndIf;
	
	If Not PackagingUsage Then
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("PackingQuantity_").ColumnWidth;
		Template.DeleteArea(Template.Area("PackingQuantity_"), Offset_);
		WidthOfDeletedColumns = WidthOfDeletedColumns + Template.Area("PackagePresentation").ColumnWidth;
		Template.DeleteArea(Template.Area("PackagePresentation"), Offset_);
	EndIf;
	AreaOfFirstColumnOfGoods = Template.Area("FirstColumnOfGoods");
	AreaOfFirstColumnOfGoods.ColumnWidth = AreaOfFirstColumnOfGoods.ColumnWidth + WidthOfDeletedColumns;
	
	ResultsArray = Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	// Creating an array to check: which of the documents were not included in the selection
	ValidationArray = New Array;
	For Each Ref In ObjectsArray Do
		ValidationArray.Add(Ref);
	EndDo;
	
	DocumentAttributes = New Structure;
    DocumentAttributes.Insert("Number");
    DocumentAttributes.Insert("Date");
    DocumentAttributes.Insert("Prefix");
    DocumentAttributes.Insert("Presentation");
    DocumentAttributes.Insert("PresentationOfOrder");
    DocumentAttributes.Insert("RepresentationOfTheOrganization");
    DocumentAttributes.Insert("PartnerPresentation_");
	DocumentAttributes.Insert("TitleText", NStr("vi = 'Hóa đơn nhập hàng';
												|ru = 'Приходная накладная';
												|en = 'Purchase invoice'; fa = 'فاکتور خرید';
												|it = 'Bolla di acquisto';
												|pl = 'Faktura przyjęcie z zewnątrz';
												|tr = 'Sevk irsaliyesi'", Common.DefaultLanguageCode()));
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		If Not SelectionByDocuments.FindNext(New Structure("Ref", PrintData.Ref)) Then
			Continue;
		EndIf;
		
		ValidationArray.Delete(ValidationArray.Find(PrintData.Ref));
		
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes, PrintData);
		DocumentAttributes.PresentationOfOrder = TMCommonUseClientServer.GenerateDocumentTitle(
			DocumentAttributes, NStr("vi = 'Mua hàng hóa';
									|ru = 'Приобретение товаров';
									|en = 'Purchase of goods'; fa = 'Purchase of goods';
									|it = 'Acquisto merci';
									|pl = 'Nabycie towarów';
									|tr = 'Mal alımları'", Common.DefaultLanguageCode()));
		DocumentAttributes.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(
				PrintData.Organization,
				PrintData.Date
			),
			"FullDescr");
		DocumentAttributes.PartnerPresentation_ = PrintFormGeneration.OrganizationDescription(
			PrintFormGeneration.InformationAboutLegalEntity(
				PrintData.Counterparty,
				PrintData.Date
			),
			"FullDescr");
		
		SampleByWarehouse = SelectionByDocuments.Select(QueryResultIteration.ByGroups);
		While SampleByWarehouse.Next() Do
			
			If Not FirstDocument Then
				SpreadsheetDocument.PutHorizontalPageBreak();
			EndIf;
			
			FirstDocument = False;
			
			Area = Template.GetArea("Title");
			Area.Parameters.Fill(DocumentAttributes);
			BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, Area, PrintData.Ref);
			SpreadsheetDocument.Put(Area);
			
			Area = Template.GetArea("Header");
			Area.Parameters.Fill(DocumentAttributes);
			HeaderDataStructure_ = New Structure;
			HeaderDataStructure_.Insert("WarehousePresentation_", SampleByWarehouse.Warehouse);
			Area.Parameters.Fill(HeaderDataStructure_);
			SpreadsheetDocument.Put(Area);
			
			Area = Template.GetArea("Vendor");
			Area.Parameters.Fill(DocumentAttributes);
			SpreadsheetDocument.Put(Area);
			
			Area = Template.GetArea("Customer");
			Area.Parameters.Fill(DocumentAttributes);
			SpreadsheetDocument.Put(Area);
			
			SpreadsheetDocument.Put(Template.GetArea("TableHeader"));
			
			LineCount = 1;
			ProductSelection_1 = SampleByWarehouse.Select();
			While ProductSelection_1.Next() Do
				
				Area = Template.GetArea("TableRow");
				DataStructureLineNumber = New Structure("LineNumber", LineCount);
				Area.Parameters.Fill(DataStructureLineNumber);
				
				LineCount = LineCount + 1;
				AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
				AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					ProductSelection_1.Products,
					ProductSelection_1.Characteristic,
					,
					,
					AdditionalParametersForGettingNameToPrint);
					
				ProductDataStructure = New Structure("OwnGoods", OwnGoods);
				Area.Parameters.Fill(ProductDataStructure);
				Area.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Put(Area);
				
			EndDo;
			
			Area = Template.GetArea("TableFooter");
			SpreadsheetDocument.Put(Area);
			
			Area = Template.GetArea("Signatures");
			TextOfResultingLine = NStr("vi = 'Tổng số là: %TotalItems_1%';
										|ru = 'Всего наименований %TotalItems_1%';
										|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
										|it = 'Totale articoli %TotalItems_1%';
										|pl = 'Razem pozycji %TotalItems_1%';
										|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
			TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
			DataStructureSummaryRow = New Structure;
			DataStructureSummaryRow.Insert("TotalString", TextOfResultingLine);
			Area.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(Area);
			
		EndDo;
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	For Each Ref In ValidationArray Do
		CommonClientServer.MessageToUser(
			StrReplace(
				NStr("vi = 'Trong chứng từ %Ref% không có hàng hóa. Không cần in phiếu nhập kho.';
					|ru = 'В документе %Ref% отсутствуют товары. Печать приходной накладной не требуется.';
					|en = 'No goods in the %Ref% document. Stamp of the purchase invoice is not required.'; fa = 'No goods in the %Ref% document. Stamp of the purchase invoice is not required.';
					|it = 'Il documento %Ref% non contiene le merci. La stampa della bolla di acquisto non è richiesta.';
					|pl = 'Brak towarów w dokumencie %Ref%. Nie jest potrzebne drukowanie zlecenia przyjęcia towaru.';
					|tr = '%Ref%belgesinde herhangi bir mal bulunmamaktadır. İrsaliye yazdırmaya gerek yoktur.'"),
				"%Ref%",
				Ref
			),
			Ref);
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

Function FormPrintedFormOfActOnProvisionOfServices(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);

	SpreadsheetDocument = New SpreadsheetDocument;
	
	UseManualDiscounts = GetFunctionalOption("UseDiscountAdjustmentsInPurchases");
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////
	|// REQUEST BY HEADER
	|
	|SELECT
	|	VendorInvoice.Ref              AS Ref,
	|	VendorInvoice.Number               AS Number,
	|	VendorInvoice.Date                AS Date,
	|	VendorInvoice.Partner             AS Partner,
	|	VendorInvoice.Counterparty          AS Counterparty,
	|	VendorInvoice.Organization         AS Organization,
	|	VendorInvoice.Organization.Prefix AS Prefix,
	|	VendorInvoice.Currency              AS Currency,
	|	VendorInvoice.PriceIncludesVAT     AS PriceIncludesVAT,
	|	CASE
	|		WHEN
	|			VendorInvoice.VATTaxation IN (VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|															VALUE(Enum.VATTaxationTypes.DigitalServices))
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END                                                             AS ConsiderVAT,
	|	VendorInvoice.Warehouse.CurrentEmployeeInChargeTypes.Description   AS VacationProduced
	|FROM
	|	Document.VendorInvoice AS VendorInvoice
	|
	|WHERE
	|	VendorInvoice.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|// QUERY BY TABLE PARTS
	|
	|SELECT
	|	NestedQuery.Ref                                                     AS Ref,
	|	NestedQuery.Products                                               AS Products,
	|	NestedQuery.Products.DescriptionFull                            AS ServiceNameFull,
	|	NestedQuery.Products.Code                                           AS Code,
	|	NestedQuery.Products.SKU                                       AS SKU,
	|	NestedQuery.UnitOfMeasure.Description                              AS UnitPrice,
	|	NestedQuery.UnitOfMeasure                                           AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull                          AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1 
	|		THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END                                                                      AS Package,
	|	NestedQuery.VATRate                                                  AS VATRate,
	|	NestedQuery.Price                                                       AS Price,
	|	NestedQuery.Count                                                 AS Count,
	|	NestedQuery.Sum                                                      AS Sum,
	|	NestedQuery.VATAmount                                                   AS VATAmount,
	|	NestedQuery.DiscountAmount                                                AS DiscountAmount,
	|	NestedQuery.AmountWithoutADiscount                                             AS AmountWithoutADiscount,
	|	NestedQuery.LineNumber                                                AS LineNumber,
	|	FALSE                                                                       AS ThisIsReusablePackage
	|FROM (
	|	SELECT
	|		VendorInvoice.Ref AS Ref,
	|		VendorInvoice.Products AS Products,
	|
	|		CASE WHEN VendorInvoice.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			1
	|		ELSE
	|			&QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|		&QueryTextUnitOfMeasure 						AS UnitOfMeasure,
	|		VendorInvoice.PercentRateOfManualDiscount         AS DiscountPercentage,
	|		VendorInvoice.Characteristic              AS Characteristic,
	|		VendorInvoice.Package                    AS Package,
	|		VendorInvoice.VATRate                   AS VATRate,
	|		VendorInvoice.Price                        AS Price,
	|		VendorInvoice.NumberOfPackages          AS Count,
	|		VendorInvoice.Sum                       AS Sum,
	|		VendorInvoice.ManualDiscount           AS DiscountAmount,
	|		VendorInvoice.Sum +
	|		VendorInvoice.ManualDiscount           AS AmountWithoutADiscount,
	|		VendorInvoice.VATAmount                    AS VATAmount,
	|		VendorInvoice.LineNumber                 AS LineNumber
	|	FROM
	|		Document.VendorInvoice.Goods AS VendorInvoice
	|	WHERE
	|		VendorInvoice.Ref IN (&DocumentsArray)
	|		AND VendorInvoice.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OperationService),VALUE(Enum.ItemsTypes.Work_5))
	|	
	|	) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(DiscountAmount)
	|BY
	|	Ref
	|");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"VendorInvoice.Package",
			"VendorInvoice.Products"));
			
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"VendorInvoice.Package",
			"VendorInvoice.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_VendorInvoice_Act";
	
	ResultsArray   = Query.ExecuteBatch();

	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// If there are only services in the invoice, let's move on to the next document
		If FollowingIsFound Then
			SampleByService = SelectionByDocuments.Select();
			DiscountHeader = PrintFormGeneration.YouNeedToDisplayDiscounts(SampleByService, UseManualDiscounts);
			ThereAreDiscounts = DiscountHeader.ThereAreDiscounts;
			SampleByService.Reset();
		Else
			
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Trong chứng từ %1 không có dịch vụ. Không cần in biên bản cung cấp dịch vụ.';
					|ru = 'В документе %1 отсутствуют услуги. Печать акта об оказании услуг не требуется.';
					|en = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.'; fa = 'Services are missing in document %1. Printing of ""Customer invoice — Services"" is not required.';
					|it = 'Non ci sono servizi nel documento %1. La stampa dell''atto sulla prestazione dei servizi non è richiesta.';
					|pl = 'W dokumencie %1 brak usług. Drukowanie protokółu świadczenia usług nie jest potrzebne.';
					|tr = '%1 Belgesinde herhangi bir hizmet bulunmamaktadır. Hizmet tutanağı yazdırmaya gerek yoktur.'"),
				PrintData.Ref);
				
			CommonClientServer.MessageToUser(
				Text,
				PrintData.Ref);
			
			Continue;
		EndIf;
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		Template = PrintManagement.PrintFormTemplate("Document.VendorInvoice.PF_MXL_Act");
		
		// We display the header of the act
		
		TemplateArea                          = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Biên bản';
																					|ru = 'Акт';
																					|en = 'Customer invoice — Services'; fa = 'فاکتور مشتری — خدمات';
																					|it = 'Atto';
																					|pl = 'Protokół';
																					|tr = 'Tutanak'", Common.DefaultLanguageCode()));
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TitleText);
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Counterparty);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Organization);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Service table
		
		If ThereAreDiscounts Then
			
			TemplateArea = Template.GetArea("TableHeaderWithDiscount");
			RowArea = Template.GetArea("RowWithDiscount");
			
			StructureOfDiscountHeader = New Structure("Discount, AmountWithoutADiscount", 
				DiscountHeader.Discount,
				DiscountHeader.DiscountAmount);
			TemplateArea.Parameters.Fill(StructureOfDiscountHeader);
		Else
			
			TemplateArea = Template.GetArea("TableHeader");
			RowArea = Template.GetArea("String");
			
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		Sum       = 0;
		VATAmount    = 0;
		LineNumber = 0;
		
		// Output the rows of the Services table
		
		While SampleByService.Next() Do
		
			LineNumber = LineNumber + 1;
			
			RowArea.Parameters.Fill(SampleByService);
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			StringDataStructure = New Structure;
			StringDataStructure.Insert("LineNumber", LineNumber);
			StringDataStructure.Insert("OwnGoods", ProductsClientServer.PresentationOfProductsForPrinting(
				SampleByService.ServiceNameFull,
				SampleByService.Characteristic,
				,
				,
				AdditionalParametersProductPresentation));
			
			If ThereAreDiscounts Then
				StringDataStructure.Insert("Discount", ?(DiscountHeader.OnlyMarkUp,- SampleByService.DiscountAmount,SampleByService.DiscountAmount));
				StringDataStructure.Insert("AmountWithoutADiscount", PrintFormGeneration.SumFormat(SampleByService.Sum + SampleByService.DiscountAmount));
			EndIf;
			RowArea.Parameters.Fill(StringDataStructure);
			
			Sum    = Sum    + SampleByService.Sum;
			VATAmount = VATAmount + SampleByService.VATAmount;
			
			SpreadsheetDocument.Put(RowArea);
		
		EndDo;
		
		TemplateArea                 = Template.GetArea("InTotal");
		TotalDataStructure = New Structure;
		TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
		TemplateArea.Parameters.Fill(TotalDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		If PrintData.ConsiderVAT Then
			
			TemplateArea = Template.GetArea("TotalVAT_");
			DataStructureTotalVAT = New Structure;
			
			DataStructureTotalVAT.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			DataStructureTotalVAT.Insert("VAT", ?(PrintData.PriceIncludesVAT, 
				NStr("vi = 'Trong đó thuế GTGT';
					|ru = 'В том числе НДС';
					|en = 'including VAT'; fa = 'با احتساب مالیات بر ارزش افزوده';
					|it = 'di cui IVA';
					|pl = 'w tym VAT';
					|tr = 'KDV dahil'", Common.DefaultLanguageCode()), 
				NStr("vi = 'Thuế GTGT';
					|ru = 'Сумма НДС';
					|en = 'VAT amount'; fa = 'مبلغ مالیات بر ارزش افزوده';
					|it = 'Importo IVA';
					|pl = 'Wartość VAT';
					|tr = 'KDV tutarı'", Common.DefaultLanguageCode())));
			TemplateArea.Parameters.Fill(DataStructureTotalVAT);
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;

		AmountToBeRegistered                          = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
		TemplateArea                          = Template.GetArea("AmountInWords");
		
		TotalString = NStr("vi = 'Tổng số dịch vụ là %NumberOfTitles%, với số tiền là %DocumentAmount%';
							|ru = 'Всего оказано услуг %NumberOfTitles%, на сумму %DocumentAmount%';
							|en = 'Total amount due %DocumentAmount% for the services rendered %NumberOfTitles%'; fa = 'Total amount due %DocumentAmount% for the services rendered %NumberOfTitles%';
							|it = 'Servizi totali resi %NumberOfTitles%, per l''importo di %DocumentAmount%';
							|pl = 'Całkowita ilość świadczonych usług %NumberOfTitles%, o wartości %DocumentAmount%';
							|tr = 'Sağlanan tüm hizmetler %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode());
		TotalString = StrReplace(TotalString, "%NumberOfTitles%", LineNumber);
		TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));
		
		DataStructureSummaryRow = New Structure;
		DataStructureSummaryRow.Insert("TotalString", TotalString);
		DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
		TemplateArea.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(TemplateArea);

		TemplateArea = Template.GetArea("Signatures");
		
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	
EndProcedure

#EndRegion

#Region MessageTemplates

// Called when preparing message templates and allows you to redefine the list of details and attachments.
//
// Parameters:
//  Attributes               - ValueTree - list of template Attributes:
//         * Name            - String - the unique name of the shared prop.
//         * Presentation  - String - representation of general props.
//         * Type            - Type    - Type of props. By default, a string.
//         * Format         - String - Format for output values for numbers, dates, strings, and Boolean values.
//  Attachments                - ValueTable - Printed forms and attachments:
//         * Name            - String - the unique name of the attachment.
//         * Presentation  - String - representation of the option.
//         * FileType       - String - Attachment type that corresponds to the file extension: "pdf", "png", "jpg", mxl"
//                                      , etc.
//  AdditionalParameters - Structure - more information about the message template.
//
Procedure OnPrepareMessageTemplate(Attributes, Attachments, AdditionalParameters) Export
	
EndProcedure

// Called when creating messages based on a template to fill in the values of details and attachments.
//
// Parameters:
//  Message - Structure - structure with keys:
//    * AttributesValues - Map of KeyAndValue- list of Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template;
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites
//      * Key     - String - name of the attachment in the template;
//      * Value - BinaryData, String - binary data or an address in the attachment's temporary storage.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//  AdditionalParameters - Structure -  additional information about the message template.
//
Procedure OnCreateMessage(Message, MessageSubject, AdditionalParameters) Export
	
EndProcedure

// Fills in the list of SMS recipients when sending a message generated by a template.
//
// Parameters:
//   SMSMessageRecipients - ValueTable - the list is received by SMS:
//     * PhoneNumber - String - phone number where the SMS message will be sent.
//     * Presentation - String - representation of the recipient of the SMS message.
//     * Contact       - CatalogRef - the contact that the phone number belongs to.
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsPhonesInMessage(SMSMessageRecipients, MessageSubject) Export
	
EndProcedure

// Fills in the list of email recipients when sending a message generated by a template.
//
// Parameters:
//   EmailRecipients - ValueTable - list of received emails:
//     * Address           - String - recipient's email address.
//     * Presentation   - String - submission of the email message.
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", " Reverse Address";
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.VendorInvoice";
EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.VendorInvoice - The document for which you want to get the data.
//  AttributesValues - Structure
// 
// Returns:
//  ValueTable - ValueTable:
// 		* OrderDocument - DocumentRef - OrderDocument
// 		* Date - Date - Document date
// 		* ApprovalDate - Date - Approval date (for orders)
// 		* DateOfShipment - Date - Scheduled shipment date
// 		* AmountARAP - Number - Amount Of Settlements By Line
// 		* AmountARAPByPackage - Number - The amount of settlements by container by line
Function OrderAmounts(ObjectReference_, AttributesValues = Undefined) Export
	
	Query = New Query;
	
	Query.Text = "
	|SELECT
	|	Goods.PurchaseOrder     AS OrderDocument,
	|	Goods.AmountIncludingVAT           AS Sum,
	|	Goods.AmountARAP AS AmountARAP,
	|	Goods.Products        AS Products,
	|	Goods.RowCode           AS RowCode,
	|	&OrderingCaps                AS Order_Header,
	|	&ByOrders                 AS ByOrders,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|SELECT 
	|	NestedQuery.OrderDocument                            AS OrderDocument,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)) AS OrderDate,
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1)) AS ApprovalDate,
	|	NestedQuery.ExceedingOrder                      AS ExceedingOrder,
	|	SUM(NestedQuery.PaymentAmount)              AS PaymentAmount,
	|	SUM(NestedQuery.AmountARAP)       AS AmountARAP,
	|	SUM(NestedQuery.PackageDepositValue)         AS PackageDepositValue,
	|	SUM(NestedQuery.AmountARAPByPackage) AS AmountARAPByPackage
	|FROM (SELECT
	|		CASE WHEN ISNULL(Goods.OrderDocument.Number, """") = """"
	|				THEN Goods.Order_Header
	|			ELSE Goods.OrderDocument
	|		END                             AS OrderDocument,
	|		FALSE                              AS ExceedingOrder,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                        AS PaymentAmount,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.AmountARAP
	|			ELSE 0
	|		END                            AS AmountARAP,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.AmountARAP
	|			ELSE 0 
	|		END                            AS AmountARAPByPackage
	|	FROM TTProducts_1 AS Goods
	|	WHERE
	|		Goods.RowCode <> 0
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CASE WHEN ISNULL(Goods.OrderDocument.Number, """") = """"
	|				THEN Goods.Order_Header
	|			ELSE Goods.OrderDocument
	|		END                        AS OrderDocument,
	|		Goods.ByOrders AS ExceedingOrder,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                        AS PaymentAmount,
	|		CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.AmountARAP
	|			ELSE 0
	|		END                            AS AmountARAP,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END                            AS PackageDepositValue,
	|		CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.AmountARAP
	|			ELSE 0 
	|		END                            AS AmountARAPByPackage
	|	FROM TTProducts_1 AS Goods
	|	WHERE
	|		Goods.RowCode = 0) AS NestedQuery
	|GROUP BY
	|	NestedQuery.OrderDocument,
	|	NestedQuery.ExceedingOrder,
	|	ISNULL(NestedQuery.OrderDocument.DATE, DATETIME(1,1,1)),
	|	ISNULL(NestedQuery.OrderDocument.ApprovalDate, DATETIME(1,1,1))
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.VendorInvoice.Goods");
		Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "Goods.Ref.ToReturnReusablePackage");
		Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "Goods.Ref.PackageDepositIsRequired");
		Query.Text = StrReplace(Query.Text, "&OrderingCaps", "Goods.Ref.PurchaseOrder");
		Query.Text = StrReplace(Query.Text, "&ByOrders", "Goods.Ref.ReceiptUnderOrders");
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "Goods.Ref = &Ref");
		Query.SetParameter("Ref",ObjectReference_);
	Else
		Query.Text = StrReplace(Query.Text, "&LinkCondition_", "TRUE");
		For Each KeyValue In AttributesValues Do
			Query.SetParameter(KeyValue.Key, KeyValue.Value);
		EndDo;
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure CheckItemTypes(BusinessOperation, Organization, Contract, ItemList, Cancel) Export
	
	If ItemList.Count() = 0 Then
		Return;
	EndIf;
	
	If Not (BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt 
		Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery) Then
		Return;
	EndIf;
	
	ContractDetails_ = Common.ObjectAttributesValues(Contract, "PurchaseRegistrationOption, 
		|OptionForRegisteringServiceReceiptDocuments");
	
	If Not ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed
		Or Not ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(CASE
	|			WHEN Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				THEN 1
	|			ELSE 0
	|		END) AS Goods,
	|	MAX(CASE
	|			WHEN Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5))
	|				THEN 1
	|			ELSE 0
	|		END) AS WorksServices
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref IN(&ItemList)";
	
	Query.SetParameter("ItemList", ItemList);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		If Selection.WorksServices > 0 And Selection.Goods > 0 Then
			MessageTemplate = NStr("vi = 'Theo doanh nghiệp ""%1"" trong hợp đồng ""%2"" đã thiết lập cách tạo khác nhau mua hàng hóa, công việc và dịch vụ.
				|Không cho phép đồng thời xử lý hàng hóa theo sơ đồ ""Giao hàng mà không có hóa đơn"" và công việc, dịch vụ theo sơ đồ 
				|""Tiếp nhận dịch vụ được đảo ngược (""phương pháp dồn tích"")"".
				|Tạo chứng từ ""Mua hàng hóa và dịch vụ"" riêng biệt theo hàng hóa, riêng biệt theo công việc và dịch vụ.';
				|ru = 'По организации ""%1"" в договоре ""%2"" установлены разные методы оформления закупки товаров, работ и услуг.
				|Не допускается одновременное оформление товаров по схеме ""Неотфактурованные поставки товаров"" и работ и услуг по схеме 
				|""Поступление услуг сторнируется (""метод начисления"")"".
				|Оформите документы ""Приобретение товаров и услуг"" отдельно по товарам, отдельно по работам и услугам.';
				|en = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|Simultaneous registration of goods by the ""Goods received not invoiced"" scheme and registration of works and services by the 
				|""Receipt of services is reversed (accrual method)"" scheme is not allowed.
				|Register the ""Vendor invoice"" documents separately for goods and for works and services.'; fa = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|Simultaneous registration of goods by the ""Goods received not invoiced"" scheme and registration of works and services by the 
				|""Receipt of services is reversed (accrual method)"" scheme is not allowed.
				|Register the ""Vendor invoice"" documents separately for goods and for works and services.';
				|it = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|Simultaneous registration of goods by the ""Goods received not invoiced"" scheme and registration of works and services by the 
				|""Receipt of services is reversed (accrual method)"" scheme is not allowed.
				|Register the ""Vendor invoice"" documents separately for goods and for works and services.';
				|pl = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|Simultaneous registration of goods by the ""Goods received not invoiced"" scheme and registration of works and services by the 
				|""Receipt of services is reversed (accrual method)"" scheme is not allowed.
				|Register the ""Vendor invoice"" documents separately for goods and for works and services.';
				|tr = '""%1"" işyeri için ""%2"" sözleşmesinde ürün, iş ve hizmet alımı için farklı düzenleme yöntemleri belirlenmiştir. 
				| Ürünlerin ""Faturalanmamış ürün teslimatları"" şemasına göre ve iş ve hizmetlerin 
				| ""Hizmet girişi iptal edilir (""tahakkuk yöntemi"")"" şemasına göre aynı anda düzenlenmesine izin verilmez. 
				|""Ürün ve hizmet alımı"" belgelerini ürünler için ayrı, iş ve hizmetler için ayrı olarak düzenleyin.'");
			
			MessageText = StrTemplate(MessageTemplate, Organization, Contract);	
			
			Common.MessageToUser(MessageText);
		ElsIf Selection.WorksServices > 0 And Selection.Goods = 0 Then
			MessageTemplate = NStr("vi = 'Theo doanh nghiệp ""%1"" trong hợp đồng ""%2"" đã thiết lập các cách khác nhau tạo mua hàng, công việc và dịch vụ.
				|Để tạo mua công việc và dịch vụ theo sơ đồ ""Tiếp nhận dịch vụ được đảo ngược (""phương pháp dồn tích"")"" 
				|cần sử dụng chứng từ ""Mua hàng hóa và dịch vụ"" với giao dịch kinh tế ""Mua hàng từ nhà cung cấp"".';
				|ru = 'По организации ""%1"" в договоре ""%2"" установлены разные методы оформления закупки товаров, работ и услуг.
				|Для оформления приобретения работ и услуг по схеме ""Поступление услуг сторнируется (""метод начисления"")"" 
				|необходимо использовать документ ""Приобретение товаров и услуг"" с хозяйственной операцией ""Закупка у поставщика"".';
				|en = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|To register the purchase of works and services by the ""Receipt of services is reversed (accrual method)"" scheme, 
				|use the ""Vendor invoice"" document with the ""Purchase from vendor"" business transaction.'; fa = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|To register the purchase of works and services by the ""Receipt of services is reversed (accrual method)"" scheme, 
				|use the ""Vendor invoice"" document with the ""Purchase from vendor"" business transaction.';
				|it = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|To register the purchase of works and services by the ""Receipt of services is reversed (accrual method)"" scheme, 
				|use the ""Vendor invoice"" document with the ""Purchase from vendor"" business transaction.';
				|pl = 'For the ""%1"" company, the ""%2"" contract contains different methods for registering the purchase of goods, works, and services.
				|To register the purchase of works and services by the ""Receipt of services is reversed (accrual method)"" scheme, 
				|use the ""Vendor invoice"" document with the ""Purchase from vendor"" business transaction.';
				|tr = '""%1"" işyeri için ""%2"" sözleşmesinde ürün, iş ve hizmet alımı için farklı düzenleme yöntemleri belirlenmiştir.
				| İş ve hizmet alımını ""Hizmet girişi iptal edilir (""tahakkuk yöntemi"")"" şemasına göre düzenlemek için 
				| ""Tedarikçiden alım"" ticari işlem türüne sahip ""Ürün ve hizmet alımı"" belgesini kullanmak gerekir.'");
			
			MessageText = StrTemplate(MessageTemplate, Organization, Contract);	
			
			Common.MessageToUser(MessageText);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FillType

// Generates the query result for the undelivered part of orders
//
// Parameters:
//	SelectionData_     - Structure - the fields that will be selected remains orders
//	WarehouseForReceipt - CatalogRef.Warehouses - warehouse where order balances will be selected
//	AnArrayOfOrders    - Array - orders for which balances will be selected.
//
// Returns:
//	QueryResult - the result of a request for an undelivered part of orders.
//
Function GetQueryResultsForOrderBalances(SelectionData_, WarehouseForReceipt = Undefined,
		AnArrayOfOrders = Undefined)
		
	OnlyWorksServices = False;
	
	If TypeOf(SelectionData_) = Type("Structure") And SelectionData_.Property("OnlyWorksServices") Then
		OnlyWorksServices = SelectionData_.OnlyWorksServices;
	EndIf;
	
	Query = New Query;
	
	Query.SetParameter("AnArrayOfOrders",             AnArrayOfOrders);
	Query.SetParameter("Partner",                   SelectionData_.Partner);
	Query.SetParameter("Counterparty",                SelectionData_.Counterparty);
	Query.SetParameter("Contract",                   SelectionData_.Contract);
	Query.SetParameter("GoodsReceiptOption",     SelectionData_.GoodsReceiptOption);
	Query.SetParameter("Organization",               SelectionData_.Organization);
	Query.SetParameter("Terms",                SelectionData_.Terms);
	
	If SelectionData_.BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorLocal Or
		SelectionData_.BusinessOperation = Enums.BusinessTransactions.PurchaseViaAdvanceHolder Then
		Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.PurchaseFromSupplier);
	Else
		ContractDetails_ = Common.ObjectAttributesValues(SelectionData_.Contract, "PurchaseRegistrationOption, 
			|OptionForRegisteringServiceReceiptDocuments");
		
		If Not ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
			And ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
			If SelectionData_.BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU Then
				Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
			ElsIf SelectionData_.BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier Then
				Query.SetParameter("BusinessOperation", Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
			Else
				Query.SetParameter("BusinessOperation", SelectionData_.BusinessOperation);
			EndIf;
		Else
			Query.SetParameter("BusinessOperation", SelectionData_.BusinessOperation);
		EndIf;
	EndIf;
	
	Query.SetParameter("ARAPCurrency",      SelectionData_.ARAPCurrency);
	Query.SetParameter("VATTaxation",        SelectionData_.VATTaxation);
	Query.SetParameter("ToReturnReusablePackage", SelectionData_.ToReturnReusablePackage);
	Query.SetParameter("PackageDepositIsRequired",      SelectionData_.PackageDepositIsRequired);
	Query.SetParameter("PriceIncludesVAT",           SelectionData_.PriceIncludesVAT);
	Query.SetParameter("Recorder",               SelectionData_.Ref);
	Query.SetParameter("WarehouseForReceipt",          WarehouseForReceipt);
	Query.SetParameter("SelectByOrder_",          AnArrayOfOrders <> Undefined);
	Query.SetParameter("CurrentDate",               BegOfDay(CurrentSessionDate()));
	Query.SetParameter("FinancialAccountingGroup",    SelectionData_.FinancialAccountingGroup);
	Query.SetParameter("Department",             SelectionData_.Department);
	Query.SetParameter("CheckHFCUnit", SelectionData_.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders
		And GetFunctionalOption("UseLocal"));
	
	If SelectionData_.ARAPObjectSettings = Enums.ARAPObjectSettings.ByOrders 
		And SelectionData_.LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef() Then
		Query.SetParameter("WithoutSelectionByAreasOfActivity", True);
	Else
		Query.SetParameter("WithoutSelectionByAreasOfActivity", False);
	EndIf;
	
	Query.SetParameter("LineOfBusiness", SelectionData_.LineOfBusiness);
	Query.SetParameter("OnlyWorksServices", 	 OnlyWorksServices);
	
	ArrayOfHouseholdOperationsInvoice = New Array;
	ArrayOfHouseholdOperationsInvoice.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	ArrayOfHouseholdOperationsInvoice.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	
	OptionOfExecutionOfPurchasesOfContract = Common.ObjectAttributeValue(SelectionData_.Contract, "PurchaseRegistrationOption");
	ContractDetails_ = Common.ObjectAttributesValues(SelectionData_.Contract,
		"PurchaseRegistrationOption, OptionForRegisteringServiceReceiptDocuments");
		
	FillInExpenseAnalyticsColumns = Not (ArrayOfHouseholdOperationsInvoice.Find(SelectionData_.BusinessOperation) <> Undefined
		And (ContractDetails_.PurchaseRegistrationOption = Enums.PurchaseRegistrationOptions.UninvoicedDeliveriesOfGoodsAndServices
		Or Not ContractDetails_.OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesNotUsed));
	Query.SetParameter("FillInExpenseAnalyticsColumns", FillInExpenseAnalyticsColumns);
	
	If TypeOf(SelectionData_) = Type("Structure")
		And SelectionData_.Property("InvoiceGoods") Then
		
		Query.SetParameter("InvoiceGoods", SelectionData_.InvoiceGoods);
		
	Else
		InvoiceGoods = New ValueTable;
		InvoiceGoods.Columns.Add("PurchaseOrder", New TypeDescription("DocumentRef.PurchaseOrder"));
		InvoiceGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		InvoiceGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		InvoiceGoods.Columns.Add("RowCode", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		InvoiceGoods.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
		InvoiceGoods.Columns.Add("AmountARAP", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		InvoiceGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		InvoiceGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		InvoiceGoods.Columns.Add("QuantityInOrder", TMCommonUse.DescriptionOfQuantitativeFieldType());
		InvoiceGoods.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("VATRate", New TypeDescription("CatalogRef.VATRates"));
		InvoiceGoods.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("VATAmount", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("AmountIncludingVAT", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("PercentRateOfManualDiscount", New TypeDescription("Number", New NumberQualifiers(5, 2)));
		InvoiceGoods.Columns.Add("ManualDiscount", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("SalesOpportunity", New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
		InvoiceGoods.Columns.Add("ExpenseItem", New TypeDescription("ChartOfCharacteristicTypesRef.ExpenseItems"));
		InvoiceGoods.Columns.Add("DimensionOfExpenses", New TypeDescription("CatalogRef.OtherExpenses"));
		InvoiceGoods.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
		InvoiceGoods.Columns.Add("ToExpenseAs", New TypeDescription("Boolean"));
		InvoiceGoods.Columns.Add("VendorPriceKind", New TypeDescription("CatalogRef.VendorPriceTypes"));
		InvoiceGoods.Columns.Add("PartnerProducts", New TypeDescription("CatalogRef.ProductCrossReferences"));
		InvoiceGoods.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		
		Query.SetParameter("InvoiceGoods", InvoiceGoods);
	EndIf;
	
	Query.SetParameter("OperationWithSelfEmployedPerson", SelectionData_.OperationWithSelfEmployedPerson);
	
	Query.Text =
	"SELECT ALLOWED
	|	OrdersTable.PurchaseOrder        AS PurchaseOrder,
	|	OrdersTable.Products           AS Products,
	|	OrdersTable.Characteristic         AS Characteristic,
	|	OrdersTable.RowCode              AS RowCode,
	|	OrdersTable.Warehouse                  AS Warehouse,
	|	SUM(OrdersTable.ToRegister)     AS Count
	|
	|INTO TableBalance
	|
	|FROM
	|	(SELECT
	|		OrdersBalance.PurchaseOrder        AS PurchaseOrder,
	|		OrdersBalance.Products           AS Products,
	|		OrdersBalance.Characteristic         AS Characteristic,
	|		OrdersBalance.RowCode              AS RowCode,
	|		OrdersBalance.Warehouse                  AS Warehouse,
	|		OrdersBalance.ToRegisterBalance     AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(,
	|				CASE WHEN &SelectByOrder_ THEN
	|					PurchaseOrder IN (&AnArrayOfOrders)
	|				ELSE
	|					CAST(PurchaseOrder AS Document.PurchaseOrder).Partner = &Partner
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).Counterparty = &Counterparty
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).Contract = &Contract
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).GoodsReceiptOption = &GoodsReceiptOption
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).Organization = &Organization
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).BusinessOperation = &BusinessOperation
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).Terms = &Terms
	|					AND (CAST(PurchaseOrder AS Document.PurchaseOrder).Currency = &ARAPCurrency
	|						OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).VATTaxation = &VATTaxation
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).PriceIncludesVAT = &PriceIncludesVAT
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).ToReturnReusablePackage = &ToReturnReusablePackage
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).PackageDepositIsRequired = &PackageDepositIsRequired
	|					AND (&WithoutSelectionByAreasOfActivity 
	|						OR CAST(PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness = &LineOfBusiness 
	|						OR CAST(PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|					AND (NOT &CheckHFCUnit
	|						OR (CAST(PurchaseOrder AS Document.PurchaseOrder).FinancialAccountingGroup IN (&FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|						AND CAST(PurchaseOrder AS Document.PurchaseOrder).Department IN (&Department, VALUE(Catalog.BusinessStructure.EmptyRef))))
	|					AND CAST(PurchaseOrder AS Document.PurchaseOrder).OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
	|					
	|				END
	|				AND
	|				CASE
	|					WHEN
	|						CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|					THEN
	|						Warehouse IN HIERARCHY (&WarehouseForReceipt) OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|					ELSE
	|						Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|				END
	|				AND (NOT &OnlyWorksServices OR Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5)))
	|			) AS OrdersBalance
	|
	|	UNION ALL
	|
	|	SELECT
	|		TrafficOrders.PurchaseOrder,
	|		TrafficOrders.Products,
	|		TrafficOrders.Characteristic,
	|		TrafficOrders.RowCode,
	|		TrafficOrders.Warehouse,
	|		CASE WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt) THEN
	|				-TrafficOrders.ToRegister
	|			ELSE
	|				TrafficOrders.ToRegister
	|		END
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS TrafficOrders
	|	WHERE
	|		TrafficOrders.Recorder = &Recorder
	|		AND CASE WHEN &SelectByOrder_ THEN
	|			TrafficOrders.PurchaseOrder IN (&AnArrayOfOrders)
	|		ELSE
	|			CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Partner = &Partner
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Counterparty = &Counterparty
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Contract = &Contract
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Organization = &Organization
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).BusinessOperation = &BusinessOperation
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Terms = &Terms
	|					AND (CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Currency = &ARAPCurrency
	|						OR &BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement))
	|					AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).VATTaxation = &VATTaxation
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).PriceIncludesVAT = &PriceIncludesVAT
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).ToReturnReusablePackage = &ToReturnReusablePackage
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).PackageDepositIsRequired = &PackageDepositIsRequired
	|			AND (&WithoutSelectionByAreasOfActivity 
	|				OR (CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness = &LineOfBusiness 
	|						OR CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|			AND (NOT &CheckHFCUnit
	|				OR (CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).FinancialAccountingGroup IN (&FinancialAccountingGroup, VALUE(Catalog.FinancialAccountingGroupsOfARAP.EmptyRef))
	|				AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).Department IN (&Department, VALUE(Catalog.BusinessStructure.EmptyRef))))
	|			AND CAST(TrafficOrders.PurchaseOrder AS Document.PurchaseOrder).OperationWithSelfEmployedPerson = &OperationWithSelfEmployedPerson
	|			
	|		END
	|		AND TrafficOrders.Active
	|				AND CASE
	|					WHEN
	|						CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|					THEN
	|						TrafficOrders.Warehouse IN HIERARCHY (&WarehouseForReceipt) OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|					ELSE
	|						TrafficOrders.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|				END
	|		AND (NOT &OnlyWorksServices OR Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService), VALUE(Enum.ItemsTypes.Work_5)))
	|	) AS OrdersTable
	|	
	|	GROUP BY
	|		OrdersTable.PurchaseOrder,
	|		OrdersTable.Products,
	|		OrdersTable.Characteristic,
	|		OrdersTable.RowCode,
	|		OrdersTable.Warehouse
	|	
	|	HAVING
	|		SUM(OrdersTable.ToRegister) > 0
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceGoods.PurchaseOrder AS PurchaseOrder,
	|	CAST(InvoiceGoods.Products AS Catalog.Products) AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.RowCode AS RowCode,
	|	InvoiceGoods.Count AS Count,
	|	InvoiceGoods.Sum AS AmountARAP,
	|	CAST(InvoiceGoods.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	CAST(InvoiceGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.VendorPriceKind AS VendorPriceKind,
	|	InvoiceGoods.Count AS QuantityInOrder,
	|	InvoiceGoods.Price AS Price,
	|	InvoiceGoods.VATRate AS VATRate,
	|	InvoiceGoods.Sum AS Sum,
	|	InvoiceGoods.VATAmount AS VATAmount,
	|	InvoiceGoods.AmountIncludingVAT AS AmountIncludingVAT,
	|	InvoiceGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	InvoiceGoods.ManualDiscount AS ManualDiscount,
	|	InvoiceGoods.SalesOpportunity                   AS SalesOpportunity,
	|	InvoiceGoods.ExpenseItem           AS ExpenseItem,
	|	InvoiceGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	InvoiceGoods.Department            AS Department,
	|	InvoiceGoods.ToExpenseAs         AS ToExpenseAs,
	|	InvoiceGoods.PartnerProducts   AS PartnerProducts,
	|	InvoiceGoods.Purpose               AS Purpose
	|INTO
	|	TTGoodsInvoiceWithoutGrouping
	|FROM
	|	&InvoiceGoods AS InvoiceGoods
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceGoods.PurchaseOrder AS PurchaseOrder,
	|	InvoiceGoods.Products AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.RowCode AS RowCode,
	|	SUM(InvoiceGoods.Count) AS Count,
	|	SUM(InvoiceGoods.AmountARAP) AS AmountARAP,
	|	InvoiceGoods.Warehouse AS Warehouse,
	|	InvoiceGoods.Package AS Package,
	|	InvoiceGoods.VendorPriceKind AS VendorPriceKind,
	|	SUM(InvoiceGoods.QuantityInOrder) AS QuantityInOrder,
	|	InvoiceGoods.Price AS Price,
	|	InvoiceGoods.VATRate AS VATRate,
	|	SUM(InvoiceGoods.Sum) AS Sum,
	|	SUM(InvoiceGoods.VATAmount) AS VATAmount,
	|	SUM(InvoiceGoods.AmountIncludingVAT) AS AmountIncludingVAT,
	|	InvoiceGoods.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	SUM(InvoiceGoods.ManualDiscount) AS ManualDiscount,
	|	InvoiceGoods.SalesOpportunity                   AS SalesOpportunity,
	|	InvoiceGoods.ExpenseItem           AS ExpenseItem,
	|	InvoiceGoods.DimensionOfExpenses        AS DimensionOfExpenses,
	|	InvoiceGoods.Department            AS Department,
	|	InvoiceGoods.ToExpenseAs         AS ToExpenseAs,
	|	InvoiceGoods.PartnerProducts   AS PartnerProducts,
	|	InvoiceGoods.Purpose               AS Purpose
	|INTO
	|	TTGoodsWaybill
	|FROM
	|	TTGoodsInvoiceWithoutGrouping AS InvoiceGoods
	|GROUP BY
	|	InvoiceGoods.PurchaseOrder,
	|	InvoiceGoods.Products,
	|	InvoiceGoods.Characteristic,
	|	InvoiceGoods.RowCode,
	|	InvoiceGoods.Warehouse,
	|	InvoiceGoods.Package,
	|	InvoiceGoods.VendorPriceKind,
	|	InvoiceGoods.Price,
	|	InvoiceGoods.VATRate,
	|	InvoiceGoods.PercentRateOfManualDiscount,
	|	InvoiceGoods.SalesOpportunity,
	|	InvoiceGoods.ExpenseItem,
	|	InvoiceGoods.DimensionOfExpenses,
	|	InvoiceGoods.Department,
	|	InvoiceGoods.ToExpenseAs,
	|	InvoiceGoods.PartnerProducts,
	|	InvoiceGoods.Purpose
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.PurchaseOrder           AS PurchaseOrder,
	|	OrderingProducts.Ref.ARAPObjectSettings       AS ARAPObjectSettings,
	|	TableBalance.Products              AS Products,
	|	TableBalance.Characteristic            AS Characteristic,
	|	TableBalance.RowCode                 AS RowCode,
	|	TableBalance.Count                AS Count,
	|	TableBalance.Warehouse                     AS Warehouse,
	|	ISNULL(WaybillGoods.Count,0)   AS QuantityInInvoice,
	|	OrderingProducts.Count                   AS QuantityInOrder,
	|	OrderingProducts.LineNumber                  AS LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity                AS SalesOpportunity,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		OrderingProducts.ExpenseItem
	|	ELSE
	|		UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		OrderingProducts.DimensionOfExpenses
	|	ELSE
	|		UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		OrderingProducts.Department
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		OrderingProducts.ToExpenseAs
	|	ELSE
	|		FALSE
	|	END AS ToExpenseAs,
	|	OrderingProducts.DateOfReceipt              AS DateOfReceipt,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
	|	OrderingProducts.VendorPriceKind            AS VendorPriceKind,
	|	OrderingProducts.Count                   AS QuantityByOrder,
	|	OrderingProducts.Price                         AS Price,
	|	OrderingProducts.VATRate                    AS VATRate,
	|	OrderingProducts.Sum                        AS Sum,
	|	OrderingProducts.VATAmount                     AS VATAmount,
	|	OrderingProducts.AmountIncludingVAT                    AS AmountIncludingVAT,
	|	OrderingProducts.PercentRateOfManualDiscount          AS PercentRateOfManualDiscount,
	|	OrderingProducts.ManualDiscount            AS ManualDiscount,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.PartnerProducts       AS PartnerProducts,
	|	OrderingProducts.Purpose                   AS Purpose,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1)
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	CASE 
	|		WHEN TableBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|			AND TableBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|			AND NOT TableBalance.Products.ItemsType IN(
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS AdvancedWarehousingOnShipment
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.PurchaseOrder.Goods AS OrderingProducts
	|		ON  TableBalance.Products     = OrderingProducts.Products
	|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode      = OrderingProducts.RowCode
	|			AND TableBalance.PurchaseOrder = OrderingProducts.Ref
	|		LEFT JOIN TTGoodsWaybill AS WaybillGoods
	|		ON TableBalance.Products = WaybillGoods.Products
	|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
	|			AND TableBalance.RowCode = WaybillGoods.RowCode
	|			AND TableBalance.PurchaseOrder = WaybillGoods.PurchaseOrder
	|
	|UNION ALL
	|
	|SELECT
	|	InvoiceGoods.PurchaseOrder          AS PurchaseOrder,
	|	CAST(InvoiceGoods.PurchaseOrder AS Document.PurchaseOrder).ARAPObjectSettings AS ARAPObjectSettings,
	|	InvoiceGoods.Products             AS Products,
	|	InvoiceGoods.Characteristic           AS Characteristic,
	|	InvoiceGoods.RowCode                AS RowCode,
	|	InvoiceGoods.Count               AS Count,
	|	InvoiceGoods.Warehouse                    AS Warehouse,
	|	ISNULL(InvoiceGoods.Count,0)   AS QuantityInInvoice,
	|	0                                        AS QuantityInOrder,
	|	0                                        AS LineNumber,
	|	InvoiceGoods.SalesOpportunity                   AS SalesOpportunity,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		InvoiceGoods.ExpenseItem
	|	ELSE
	|		UNDEFINED
	|	END AS ExpenseItem,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		InvoiceGoods.DimensionOfExpenses
	|	ELSE
	|		UNDEFINED
	|	END AS DimensionOfExpenses,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		InvoiceGoods.Department
	|	ELSE
	|		VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS Department,
	|	CASE WHEN &FillInExpenseAnalyticsColumns THEN
	|		InvoiceGoods.ToExpenseAs
	|	ELSE
	|		FALSE
	|	END AS ToExpenseAs,
	|	UNDEFINED                             AS DateOfReceipt,
	|	InvoiceGoods.Package                 AS Package,
	|	InvoiceGoods.VendorPriceKind        AS VendorPriceKind,
	|	0                                        AS QuantityByOrder,
	|	InvoiceGoods.Price                     AS Price,
	|	InvoiceGoods.VATRate                AS VATRate,
	|	InvoiceGoods.Sum                    AS Sum,
	|	InvoiceGoods.VATAmount                 AS VATAmount,
	|	InvoiceGoods.AmountIncludingVAT                AS AmountIncludingVAT,
	|	InvoiceGoods.PercentRateOfManualDiscount          AS PercentRateOfManualDiscount,
	|	InvoiceGoods.ManualDiscount            AS ManualDiscount,
	|	InvoiceGoods.Products.ItemsType AS ItemsType,
	|	InvoiceGoods.PartnerProducts       AS PartnerProducts,
	|	InvoiceGoods.Purpose                   AS Purpose,
	|	CASE
	|		WHEN InvoiceGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor3, 1)
	|	END AS ZoomRatio,
	|	InvoiceGoods.Count / ISNULL(&QueryTextPackagingFactor3, 1) AS NumberOfPackages,
	|	CASE 
	|		WHEN InvoiceGoods.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|			AND InvoiceGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|			AND NOT InvoiceGoods.Products.ItemsType IN(
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS AdvancedWarehousingOnShipment
	|FROM
	|	TTGoodsWaybill AS InvoiceGoods
	|WHERE
	|	InvoiceGoods.RowCode = 0
	|ORDER BY
	|	TableBalance.PurchaseOrder,
	|	OrderingProducts.LineNumber";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"WaybillGoods.Package",
			"WaybillGoods.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"OrderingProducts.Package",
			"OrderingProducts.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor3",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"InvoiceGoods.Package",
			"InvoiceGoods.Products"));
		
	Return Query.Execute();
EndFunction
#EndRegion

#Region ToDoList

Function QueryTextOrdersToBeRegistered(Organization = Undefined, Warehouse = Undefined) Export

	QueryText = 
	"SELECT TOP 1 ALLOWED
	|	PurchaseOrders.Ref AS Ref,
	|	VALUETYPE(PurchaseOrders.Ref) AS TypeOfOrder_,
	|	PurchaseOrders.Date AS Date,
	|	PurchaseOrders.Number AS Number,
	|	PurchaseOrders.Partner AS Partner,
	|	PurchaseOrders.Counterparty AS Counterparty,
	|	PurchaseOrders.Organization AS Organization,
	|	PurchaseOrders.Warehouse AS Warehouse,
	|	PurchaseOrders.Terms AS Terms,
	|	PurchaseOrders.Contract AS Contract,
	|	PurchaseOrders.Currency AS Currency,
	|	PurchaseOrders.Manager AS Manager,
	|	PurchaseOrders.DocumentAmount AS DocumentAmount,
	|	PurchaseOrders.Priority AS Priority,
	|	PurchaseOrders.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN SUM(TableOfOrders.ToRegisterExpense) = 0
	|			THEN 1
	|		ELSE 2
	|	END AS ReceiptState
	|FROM
	|	AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(, , , , PurchaseOrder REFS Document.PurchaseOrder {(Warehouse) AS Warehouse}) AS TableOfOrders
	|		LEFT JOIN Document.PurchaseOrder AS PurchaseOrders
	|		ON (PurchaseOrders.Ref = TableOfOrders.PurchaseOrder)
	|WHERE
	|	TableOfOrders.ToRegisterClosingBalance > 0
	|	AND &SelectionConditionWarehouse
	|	AND &SelectionConditionOrganization
	|
	|GROUP BY
	|	PurchaseOrders.Ref,
	|	VALUETYPE(PurchaseOrders.Ref),
	|	PurchaseOrders.Date,
	|	PurchaseOrders.Number,
	|	PurchaseOrders.Partner,
	|	PurchaseOrders.Counterparty,
	|	PurchaseOrders.Organization,
	|	PurchaseOrders.Warehouse,
	|	PurchaseOrders.Terms,
	|	PurchaseOrders.Contract,
	|	PurchaseOrders.Currency,
	|	PurchaseOrders.Manager,
	|	PurchaseOrders.DocumentAmount,
	|	PurchaseOrders.Priority,
	|	PurchaseOrders.BusinessOperation";
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = "PurchaseOrders.Organization = &Organization";
		QueryText = StrReplace(QueryText,"&SelectionConditionOrganization", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganization", "");
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		FilterCriterion = "PurchaseOrders.Warehouse = &Warehouse";
		QueryText = StrReplace(QueryText,"&SelectionConditionWarehouse", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionWarehouse", "");
	EndIf;
	
	Return QueryText
	
EndFunction

Function QueryTextReceiptRefs(Organization = Undefined, Warehouse = Undefined) Export

	QueryText = 
	"SELECT DISTINCT TOP 1 ALLOWED
	|	TableOfOrders.Ref,
	|	VALUETYPE(TableOfOrders.Ref) AS TypeOfOrder_,
	|	TableOfOrders.Date,
	|	TableOfOrders.Number,
	|	TableOfOrders.DeletionMark,
	|	TableOfOrders.Partner,
	|	TableOfOrders.Counterparty,
	|	TableOfOrders.Organization,
	|	TableOfOrders.Warehouse,
	|	TableOfOrders.Terms,
	|	TableOfOrders.Contract,
	|	TableOfOrders.Currency,
	|	TableOfOrders.Manager,
	|	TableOfOrders.DocumentAmount,
	|	TableOfOrders.Priority,
	|	TableOfOrders.BusinessOperation,
	|	MAX(TableOfOrders.NoteState) AS NoteState
	|FROM
	|	(SELECT
	|		TableOfOrders.DocumentInflow.Ref AS Ref,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Date
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Date
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Date
	|		END AS Date,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Number
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Number
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Number
	|		END AS Number,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).DeletionMark
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).DeletionMark
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).DeletionMark
	|		END AS DeletionMark,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Partner
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Partner
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Partner
	|		END AS Partner,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Counterparty
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Counterparty
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Counterparty
	|		END AS Counterparty,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Organization
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Organization
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Organization
	|		END AS Organization,
	|		TableOfOrders.Warehouse AS Warehouse,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Terms
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Terms
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Ref
	|		END AS Terms,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Contract
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Contract
	|		END AS Contract,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Currency
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Currency
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Currency
	|		END AS Currency,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Manager
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).Manager
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).Manager
	|		END AS Manager,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).DocumentAmount
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).DocumentAmount
	|		END AS DocumentAmount,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).Priority
	|		END AS Priority,
	|		CASE
	|			WHEN TableOfOrders.DocumentInflow REFS Document.PurchaseOrder
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.PurchaseOrder).BusinessOperation
	|			WHEN TableOfOrders.DocumentInflow REFS Document.VendorInvoice
	|				THEN CAST(TableOfOrders.DocumentInflow AS Document.VendorInvoice).BusinessOperation
	|			WHEN TableOfOrders.DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors
	|				THEN CAST(TableOfOrders.DocumentInflow AS Catalog.TermsOfPurchaseFromVendors).BusinessOperation
	|		END AS BusinessOperation,
	|		TableOfOrders.Warehouse AS OriginWarehouse,
	|		TableOfOrders.Products AS Products,
	|		TableOfOrders.Characteristic AS ProductCharacteristic,
	|		TableOfOrders.Purpose AS Purpose,
	|		CASE
	|			WHEN TableOfOrders.ToRegisterGoodsReceiptsClosingBalance = 0
	|					AND TableOfOrders.ToRegisterGoodsReceiptsReceipt > 0
	|				THEN 0
	|			WHEN TableOfOrders.ToRegisterGoodsReceiptsReceipt > 0
	|				THEN 3
	|			ELSE 1
	|		END AS NoteState
	|	FROM
	|		AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(
	|				,
	|				,
	|				,
	|				,
	|				DocumentInflow REFS Document.PurchaseOrder
	|					OR DocumentInflow REFS Document.VendorInvoice
	|					OR DocumentInflow REFS Catalog.TermsOfPurchaseFromVendors {(Warehouse) AS Warehouse}) AS TableOfOrders
	|	WHERE
	|		TableOfOrders.ToRegisterGoodsReceiptsClosingBalance <> 0) AS TableOfOrders
	|WHERE
	|	NOT TableOfOrders.Number IS NULL
	|	AND &SelectionConditionWarehouse
	|	AND &SelectionConditionOrganization
	|
	|GROUP BY
	|	TableOfOrders.Ref,
	|	VALUETYPE(TableOfOrders.Ref),
	|	TableOfOrders.DeletionMark,
	|	TableOfOrders.Number,
	|	TableOfOrders.Date,
	|	TableOfOrders.Partner,
	|	TableOfOrders.Counterparty,
	|	TableOfOrders.Organization,
	|	TableOfOrders.Terms,
	|	TableOfOrders.Contract,
	|	TableOfOrders.Currency,
	|	TableOfOrders.Warehouse,
	|	TableOfOrders.Manager,
	|	TableOfOrders.Priority,
	|	TableOfOrders.BusinessOperation,
	|	TableOfOrders.DocumentAmount";
	
	If ValueIsFilled(Organization) Then
		FilterCriterion = "TableOfOrders.Organization = &Organization";
		QueryText = StrReplace(QueryText,"&SelectionConditionOrganization", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionOrganization", "");
	EndIf;
	
	If ValueIsFilled(Warehouse) Then
		FilterCriterion = "TableOfOrders.Warehouse = &Warehouse";
		QueryText = StrReplace(QueryText,"&SelectionConditionWarehouse", FilterCriterion);
	Else
		QueryText = StrReplace(QueryText,"AND &SelectionConditionWarehouse", "");
	EndIf;
	
	Return QueryText
	
EndFunction

Function ThereAreOrdersForRegistration(Organization = Undefined, Warehouse = Undefined) Export
		
	QueryText = QueryTextOrdersToBeRegistered(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ThereAreOrdersForAcceptance(Organization = Undefined, Warehouse = Undefined) Export
	
	QueryText = QueryTextReceiptRefs(Organization, Warehouse);

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Warehouse", Warehouse);
	
	Return Not Query.Execute().IsEmpty();
		
EndFunction

// Fills in the user's to-do list.
// Parameters: 
//    ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "DataProcessor.LogOfPurchaseDocuments.Form.InvoicesForRegistrationList";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.VendorInvoice))
		And AccessRight("Insert", Metadata.Documents.VendorInvoice)
		And AccessRight("View", Metadata.Documents.PurchaseOrder)
		And AccessRight("Read",   Metadata.AccumulationRegisters.PurchaseOrders)
		And GetFunctionalOption("UsePurchaseOrders");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT TableOfOrders.PurchaseOrder) AS OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress
	|FROM
	|	AccumulationRegister.PurchaseOrders.Balance(, PurchaseOrder IN (
	|		SELECT
	|			PurchaseOrder.Ref
	|		FROM
	|			Document.PurchaseOrder AS PurchaseOrder)) AS TableOfOrders
	|WHERE
	|	TableOfOrders.ToRegisterBalance > 0";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Documentsapplication of goods and services
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "DocumentsOfReceiptOfGoodsAndServices";
	UserTaskParent.Presentation  = NStr("vi = 'Chứng từ mua lại hàng hóa và dịch vụ';
										|ru = 'Документы приобретения товаров и услуг';
										|en = 'Vendor invoices'; fa = 'Vendor invoices';
										|it = 'Documenti di acquisizione di merci e servizi';
										|pl = 'Dokumenty nabycia towarów i usług';
										|tr = 'Satın alma faturasına ilişkin belgeler'");
	UserTaskParent.HasToDoItems       = Result.OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress > 0;
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress
	FilterParameters = New Structure;
	FilterParameters.Insert("Warehouse", Catalogs.Warehouses.EmptyRef());
	
	FormParameters = New Structure;
	FormParameters.Insert("QuickFilterStructure", FilterParameters);
	FormParameters.Insert("CurrentPageName", "PageOfTheOrderForRegistration");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress";
	ToDoItem.HasToDoItems       = Result.OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress > 0;
	ToDoItem.Presentation  = NStr("vi = 'Lệnh lập chứng từ đang làm việc';
									|ru = 'Распоряжения на оформление в работе';
									|en = 'References for registration in progress'; fa = 'References for registration in progress';
									|it = 'Le disposizioni per la formalizzazione sono in esecuzione';
									|pl = 'Zamówienia rejestracji są w toku wykonywania';
									|tr = 'İş yerinde işleme alınacak siparişler'");
	ToDoItem.Count     = Result.OrdersForRegistrationOfReceiptsOfGoodsAndServicesInProgress;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "DocumentsOfReceiptOfGoodsAndServices";
	
EndProcedure

Function CreateHyperlinkToDesign(Parameters) Export
	
	Organization = Parameters.Organization;
	Warehouse = Parameters.Warehouse;
	
	ShowOrders = GetFunctionalOption("UsePurchaseOrders")
		And AccessRight("Read", Metadata.Documents.PurchaseOrder)
		And AccessRight("Read", Metadata.AccumulationRegisters.PurchaseOrders)
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
	
	ShowAcceptanceOrders = WarehousesServer.ThereIsOrderForReceiptWarehouse(Warehouse,CurrentSessionDate())
		And AccessRight("Read", Metadata.AccumulationRegisters.GoodsToReceive);
		
	Hyperlink = Undefined;
	HyperlinkText = NStr("vi = 'Hóa đơn';
						|ru = 'Накладные';
						|en = 'Invoices'; fa = 'فاکتورها';
						|it = 'Lettere di vettura';
						|pl = 'Listy przewozowe';
						|tr = 'İrsaliye'");
	If ShowOrders
		Or ShowAcceptanceOrders Then
		
		Hyperlink = New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			NameOfPurchaseGoodsServicesListForm());
		
	EndIf;
	
	If ShowOrders
			And ThereAreOrdersForRegistration(Organization, Warehouse)
		Or ShowAcceptanceOrders
			And ThereAreOrdersForAcceptance(Organization, Warehouse) Then
			
		Hyperlink = New FormattedString(HyperlinkText,,,,
			NameOfPurchaseGoodsServicesListForm());
			
	EndIf;
	
	Return Hyperlink;
	
EndFunction

Function NameOfPurchaseGoodsServicesListForm() Export
	
	Return "Document.VendorInvoice.Form.DocumentsListForm";
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef.VendorInvoice - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.PurchaseOrder AS PurchaseOrder,
	|	DocumentData.ReceiptUnderOrders AS ReceiptUnderOrders,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition
	|
	|FROM
	|	Document.VendorInvoice AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		Partner = Selection.Partner;
		Counterparty = Selection.Counterparty;
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Currency = Selection.Currency;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.PurchaseFromSupplier);
		ByOrder = Selection.ReceiptUnderOrders;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		Rate = Selection.Rate;
		Repetition = Selection.Repetition;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		ByOrder = False;
		DocumentAmount = 0;
		AmountARAP = 0;
		Rate = 1;
		Repetition = 1;
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("Currency", Currency);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("ByOrder", ByOrder);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	
	Return AttributesStructure1;

EndFunction

#EndRegion

#Region Posting

#EndRegion

Function QueryTextTableGoodsAndServicesToRegisterPurchasingReportsToConsignor(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "GoodsAndServicesToRegisterPurchasingReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	BusinessTransactionsDeliveryUnderPrincipal = PurchasesServer.BusinessOperationsForAgencyProcurementUnderPrincipal();
	
	If Not (BusinessTransactionsDeliveryUnderPrincipal.Find(DocumentObject.BusinessOperation) <> Undefined) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts, DocumentObject);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	&Ref AS DocumentAcquisitions,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	&ARAPCurrency AS Currency,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.VATAmount AS VATAmount,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl
	|		ELSE 0
	|	END AS SumCompl,
	|	CASE
	|		WHEN ISNULL(Assignments.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|			THEN GoodsTable.AmountExcludingVATMan + GoodsTable.VATAmountMan
	|		ELSE 0
	|	END AS SumMan,
	|	TRUE AS Primary,
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	GoodsTable.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(Assignments.ConsiderVATRates, FALSE)
	|			THEN GoodsTable.VATRate
	|		ELSE VALUE(Catalog.VATRates.EmptyRef)
	|	END AS VATRate
	|FROM
	|	TTTableProducts AS GoodsTable
	|LEFT JOIN
	|	Catalog.Assignments AS Assignments
	|ON
	|	GoodsTable.Purpose = Assignments.Ref
	|WHERE
	|	GoodsTable.AssignmentTypeOfAssignment = VALUE(Enum.AssignmentTypes.DeliveryForPrincipal)
	|	AND CASE GoodsTable.ItemsType
	|			WHEN VALUE(Enum.ItemsTypes.OwnGoods)
	|				THEN TRUE
	|			WHEN VALUE(Enum.ItemsTypes.Work_5)
	|				THEN TRUE
	|			WHEN VALUE(Enum.ItemsTypes.ReusablePackage)
	|				THEN NOT &ToReturnReusablePackage
	|			ELSE FALSE
	|		END
	|	AND NOT &UninvoicedReceiptDocumentIsUsed
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
EndFunction

#EndRegion

#EndIf
#EndIf
