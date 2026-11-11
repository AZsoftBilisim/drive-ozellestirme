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
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, PurchaseOrder, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Partner";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Partner";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "HandedOverBy", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "HandedOverBy";
	Parameters.FillInIf.ObjectFieldsFilledIn = "HandedOverBy";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "HandedOverJobTitle", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
	
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
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentCorrection");
	
	GoodsReceiptForStorageLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.GoodsReceiptForStorage") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTablePurchaseOrders(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		
		GoodsReceiptForStorageLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
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
	|	Goods.Warehouse AS Warehouse,
	|	Goods.Ref.Contract AS Contract
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&References)
	|
	|GROUP BY
	|	Goods.Ref,
	|	Goods.Warehouse";
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.Partner           AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	Header.DeliveryMethod    AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|
	|	CASE WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|		THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|		THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	References.Warehouse      AS Warehouse,
	|	TRUE                  AS DeliverFully,
	|	Header.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	&TT_Orders AS References
	|		INNER JOIN Document.GoodsReceiptForStorage AS Header
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


// Returns:
// 	String - The text of the request to receive goods for delivery by order
Function QueryTextGoodsToDeliver() Export
	
	QueryText =
	"SELECT
	|	Goods.Ref,
	|	Goods.Warehouse,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	Goods.Purpose,
	|	SUM(Goods.Count) AS Count
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
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

// Adds the command to create the document "acceptance of goods for storage".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTableRow, Undefined - created team
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsReceiptForStorage.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsReceiptForStorage);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustodyDuringPurchase";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	If GetFunctionalOption("UseNonConformanceCertificatesFollowingAcceptance") Then
		CreationCommand = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(
							GenerationCommands);
		
		If CreationCommand <> Undefined Then
			CreationCommand.Presentation = NStr("vi = 'Biên bản chênh lệch sau khi nhận';
												|ru = 'Акт о расхождениях после приемки';
												|en = 'Receipt discrepancy report'; fa = 'گزارش مغایرت دریافت';
												|it = 'Atto di discrepanze dopo l''accettazione';
												|pl = 'Protokół o odchyleniu po przyjęciu';
												|tr = 'Stok farkları raporu'");
			AttachableCommands.AddCommandVisibilityCondition(
				CreationCommand,
				"BusinessOperation",
				Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
				DataCompositionComparisonType.NotEqual);
		EndIf;
	EndIf;
	Command = Documents.DiscrepancyReportFollowingReceipt.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
			DataCompositionComparisonType.Equal);
		
		Command.FunctionalOptions = "UseCertificatesOfDiscrepanciesAfterAcceptanceForAcceptanceOfGiverSGoods2_5";
		Command.Presentation       = NStr("vi = 'Biên bản chênh lệch sau khi nhận';
											|ru = 'Акт о расхождениях после поступления';
											|en = 'Consignment pick-up discrepancy report'; fa = 'Consignment pick-up discrepancy report';
											|it = 'Atti sulle discrepanze dopo l''arrivo';
											|pl = 'Protokół o odchyleniu po wpływie';
											|tr = 'Teslim alım sonrası tutarsızlık raporu'");
		
	EndIf;
	Documents.TransferOrder.AddCreateCommandBasedOnAcceptanceOfGoodsForStorageByWarehouseGroup(GenerationCommands);
	
	Command = Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
			DataCompositionComparisonType.NotEqual);
	EndIf;
	Command = Documents.GoodsShipmentFromStorage.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	Command = Documents.GoodsShipmentFromStorage.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			Command,
			"BusinessOperation",
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
			DataCompositionComparisonType.Equal);
		
		Command.Presentation = NStr("vi = 'Trả lại cho người đặt gia công';
									|ru = 'Возврат давальцу';
									|en = 'Goods return — Subcontracting services delivered'; fa = 'برگشت کالا — خدمات پیمانکاری فرعی ارائه‌شده';
									|it = 'Restituzione del fornitore di materiali';
									|pl = 'Zwrot właścicielowi surowców';
									|tr = 'Tedarikçiye iade'");
		
	EndIf;
	Documents.GoodsQualityControlCertificate.AddGenerateCommand(GenerationCommands);
	
	Documents.RequestForGoodsQualityControl.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.InventoryTransfer.AddCreateBasedOnWarehouseGroupCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	GoodsReceiptForStorageLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "acceptance of goods for storage".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   
// Returns:
//   ValueTableRow, Undefined - created team
//
Function AddCreateBasedOnOrderCommand_(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.AcceptanceOfGoodsForStorageIsCarriedOutOnBasisOfOrder";
		CreateBasedOnCommand.Id = "CreateByOrderReference";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Nhập kho hàng hóa để cất giữ';
												|ru = 'Приемка товаров на хранение';
												|en = 'VMI procurement'; fa = 'تدارکات VMI';
												|it = 'Accettazione delle merci per il deposito';
												|pl = 'Przyjęcie towarów do przechowania';
												|tr = 'Malların depoya girişi'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = True;
		CreateBasedOnCommand.FunctionalOptions =
			"UseCustodyDuringPurchase";
		CreateBasedOnCommand.FunctionalOptions =
			"UseCustodyDuringPurchase, UseTollManufacturing2_5";
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create a document "Receipts from the giver" based on the "Transfer to the processor".
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   
// Returns:
//   ValueTableRow, Undefined - created team
//
Function AddCreateCommandBasedOnTransferToProcessor(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.GoodsReceiptForStorage.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Tiếp nhận từ người đặt gia công';
														|ru = 'Поступление от давальца';
														|en = 'Receipt from material provider'; fa = 'دریافت از تأمین‌کننده مواد';
														|it = 'Ricezione dall''addetto alla lavorazione';
														|pl = 'Wpływ od właściciela surowców';
														|tr = 'Mal girişi — Verilen fason hizmetleri'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndSubcontracting25";
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreateBasedOnCommand,
			"BusinessOperation",
			Enums.BusinessTransactions.TransferToToller2_5);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a command to create a document "Receipts from the giver" for acceptance of the repaired FINISHED product.
//
// Parameters:
//   GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//   
// Returns:
//   ValueTableRow, Undefined - created team
//
Function AddCommandToCreateReceiptOfRepairedFINISHEDProduct(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.AcceptanceOfRepairedFinishedProductToCreateOnBasisOfOrder";
		CreateBasedOnCommand.Id = "AcceptanceOfRepairedFinishedProductToCreateOnBasisOfOrder";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Tiếp nhận sản phẩm vào sửa chữa';
												|ru = 'Поступление изделия в ремонт';
												|en = 'Receipt of product for repair'; fa = 'Receipt of product for repair';
												|it = 'Receipt of product for repair';
												|pl = 'Receipt of product for repair';
												|tr = 'Ürünün bakım onarım için teslim alınması'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.MultipleChoice = False;
		CreateBasedOnCommand.FunctionalOptions = "UseTollManufacturing2_5";
		
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
		ReportCommand.VisibilityInForms = "DocumentForm";
		
	EndIf;
	
	GoodsReceiptForStorageLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region FillType

// Fills in a table of products based on selection data or an array of orders.
//
// Parameters:
//	SelectionData_ 		- Structure - fields that will be used to select order balances for filling in the document.
//	Goods 				- FormDataCollection - the product table where the remaining orders will be placed.
//	WarehouseForReceipt	- CatalogRef.Warehouses - 
//	AnArrayOfOrders 		- Array - orders for which balances will be selected.
//	CheckOrderOfCalculations - Boolean - Required for compatibility of the selection form from Orders, 
//	                                    used in the document Purchase of goods and services.
Procedure FillByOrderBalances(SelectionData_, Goods, WarehouseForReceipt, AnArrayOfOrders = Undefined, CheckOrderOfCalculations = False) Export
	
	ArrayOfOrdersToSupplier = New Array();
	
	// Data on the remaining items of the order.
	SampleProducts_ = GetQueryResultsForOrderBalances(SelectionData_, WarehouseForReceipt, AnArrayOfOrders).Select();
	
	While SampleProducts_.Next() Do
		If ArrayOfOrdersToSupplier.Find(SampleProducts_.PurchaseOrder) = Undefined Then
			ArrayOfOrdersToSupplier.Add(SampleProducts_.PurchaseOrder);
		EndIf;
	EndDo;
	
	If ArrayOfOrdersToSupplier.Count() > 0 Then
		AnArrayOfOrders = ArrayOfOrdersToSupplier;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("DocumentCurrency",         SelectionData_.Currency);
	Query.SetParameter("ArrayOfOrdersToSupplier", ArrayOfOrdersToSupplier);
	
	Query.Text =
	"SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Ref                    AS PurchaseOrder,
	|	TheOrdersTable.Currency                    AS Currency,
	|	CASE
	|		WHEN TheOrdersTable.Currency <> &DocumentCurrency
	|			THEN TRUE
	|		ELSE
	|			FALSE
	|	END                                    AS ConvertToDocumentCurrency
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|
	|UNION ALL
	|
	|SELECT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY)  AS Date,
	|	TheOrdersTable.Ref                     AS PurchaseOrder,
	|	TheOrdersTable.Currency                     AS Currency,
	|	TheOrdersTable.Currency <> &DocumentCurrency AS ConvertToDocumentCurrency
	|FROM
	|	Document.MaterialProviderOrder2_5 AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY) AS Date,
	|	TheOrdersTable.Currency                    AS Currency,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.PurchaseOrder AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	BEGINOFPERIOD(TheOrdersTable.Date, DAY)                  AS Date,
	|	TheOrdersTable.Currency                                     AS Currency,
	|	TheOrdersTable.Organization.LocalAccountingCurrency AS LocalAccountingCurrency
	|FROM
	|	Document.MaterialProviderOrder2_5 AS TheOrdersTable
	|WHERE
	|	TheOrdersTable.Ref IN (&ArrayOfOrdersToSupplier)
	|	AND TheOrdersTable.Currency <> &DocumentCurrency
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
		
		Currency_Rates = ProcessingOfExchangeRatesTM.GetCurrencyRate(Selection.Currency, Selection.Date, Selection.LocalAccountingCurrency);
		
		NewRow.CourseNumerator = Currency_Rates.CourseNumerator;
		NewRow.CourseDenominator = Currency_Rates.CourseDenominator;
	EndDo;
	
	If TableOfExchangeRates.Count() > 0 Then
		StructureOfNewCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(SelectionData_.Currency, CurrentSessionDate(),
					SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(SelectionData_.Organization));
	EndIf;
	
	SampleProducts_.Reset();
	
	While SampleProducts_.Next() Do
		
		AmountsMustBeRecalculated = (SampleProducts_.Count <> SampleProducts_.QuantityByOrder);
		
		TabRow = Goods.Add();
		FillPropertyValues(TabRow, SampleProducts_);
		
		TabRow.Count = SampleProducts_.Count;
		TabRow.NumberOfPackages = SampleProducts_.Count / SampleProducts_.ZoomRatio;
		
		OrderDetails_.Reset();
		OrderFound = OrderDetails_.FindNext(TabRow.PurchaseOrder, "PurchaseOrder");
		
		If OrderFound Then
			
			If OrderDetails_.ConvertToDocumentCurrency Then
				
				FilterParameters = New Structure("Currency, Date", OrderDetails_.Currency, OrderDetails_.Date);
				CurrencyExchangeRate = TableOfExchangeRates.FindRows(FilterParameters);
				
				If CurrencyExchangeRate.Count() = 1 Then
					
					AmountsMustBeRecalculated = True;
					
					TabRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(TabRow.Price,
						CurrencyExchangeRate[0],
						StructureOfNewCurrencyRates);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If OrderFound
			And AmountsMustBeRecalculated Then
			
			TabRow.Sum = TabRow.Price * TabRow.NumberOfPackages;
			
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
//	Parameters:
//		Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
//	Returns:
//		See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsReceiptForStorage";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = 
					WarehouseSeriesParameters.UseItemsBatch
					And Not WarehousesServer.UseWarehouseManagemantSystemForGoodsReceipt(Object.Warehouse, Object.Date, True)
						Or WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice    = False;
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
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
	|	END AS BatchesIndicationStatus
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
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  	See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.TermsOfUse_ =
		"Object.BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)";
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.Partner                  = "Object.Partner";
	DestinationPattern.Contract                  = "Object.Contract";
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True,
		"Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	DescriptionOfColumns.DataPaths.ToControlQuality = "Object.Goods.ToControlQuality";
	
	Return FormTemplate;
	
EndFunction

// Returns the destination template
// 
// Parameters:
//  Object - DocumentObject.GoodsReceiptForStorage, FormDataStructure - 
// 
// Returns:
//  See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	If Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		
		If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
			DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
		EndIf;
		
		DestinationPattern.Partner = Object.Partner;
		DestinationPattern.Contract = Object.Contract;
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.Giveaway2_5;
		
		If ValueIsFilled(Object.PurchaseOrder)
			And Constants.OptionOfMaterialAssignmentUponSubcontractingServicesDelivered.Get() = Enums.AssignmentAtSubcontractingServicesDelivered.MaterialProviderOrder Then
			DestinationPattern.OrderDocument = Object.PurchaseOrder;
		ElsIf Not ValueIsFilled(Object.LineOfBusiness) Then
			ContractLB = Common.ObjectAttributeValue(Object.Contract, "LineOfBusiness");
			If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(ContractLB) Then
				DestinationPattern.LineOfBusiness = ContractLB;
			EndIf;
		EndIf;
	
	EndIf;
	Return DestinationPattern;
	
EndFunction

#EndRegion

#Region Other

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.GoodsReceiptForStorage, DocumentRef.GoodsReceiptForStorage - Document.
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
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department,
		|Patch,
		|CorrectedDocument");
	
	If ObjectAttributes.Ref <> Undefined And ObjectAttributes.Patch Then
		Attributes = AttributesOfControlledLotReference(ObjectAttributes.CorrectedDocument, FieldNameControlledLotReference);
		Return Attributes;
	EndIf;
		
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
	Attributes.Sender = ObjectAttributes.Partner;
	Attributes.BusinessOperation = ObjectAttributes.BusinessOperation;
	Return Attributes;
	
EndFunction

// Document parameters for the Attribute filling mechanism to check the quality and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.GoodsReceiptForStorage - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Object.DateOfReceipt, Object.Date, True);
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	
	ActionParameters.ReadableFields = "Products,Warehouse";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = DateOfReceipt;
	
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	&QualityControlDateOfReceipt AS DateOfReceipt,
		|	FALSE AS Set,
		|	FALSE AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

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

// Initializes the status structure of the document
// 
// Returns:
// See Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.DisplayReceiptTables        = 1;
	StructureState.ThisIsAnInvoice                      = True;
	StructureState.ThereAreSummaryIndicatorsOfReceipt = True;
	StructureState.NameOfInvoiceForOrdersField         = "ReceiptUnderOrders";
	StructureState.NameOfAmountField                      = "Sum";
	
	Return StructureState
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm -
// Returns:
//  See AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument
Function ProcedureForFillingOutAssignmentsInDocument(Form) Export
	
	DocumentProcessingProcedure = AssignmentsServer.ProcedureForFillingOutAssignmentsInDocument();
	DocumentProcessingProcedure.OrderDetailsName = "ReceiptUnderOrders";
	DocumentProcessingProcedure.DocumentDefinesFunctionAssignmentTemplate = True;
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	If Form.Object.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	EndIf;
	TableOfConditions = AssignmentsServer.ConditionsForProcessingAssignmentsInRows("ItemsType,RowCode");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Nhập hàng';
							|ru = 'Приемка товаров';
							|en = 'Goods receipt'; fa = 'رسید انبار';
							|it = 'Accettazione merci';
							|pl = 'Przyjęcie zewnętrzne';
							|tr = 'Mal girişi'"));
	GoodsReceiptForStorageLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return GoodsReceiptForStorageLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return GoodsReceiptForStorageLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// Fills in an array of acceptable names for incoming documents.
//
// Parameters:
//  ArrayOfNames	 - Array - an array of the names of incoming documents.
//
Procedure AddNamesOfIncomingDocuments(ArrayOfNames) Export
	
EndProcedure

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
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(BusinessOperation)";

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

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		DocumentSynonym = NStr("vi = 'Nhập kho hàng hóa để cất giữ';
								|ru = 'Приемка товаров на хранение';
								|en = 'VMI procurement'; fa = 'تدارکات VMI';
								|it = 'Accettazione delle merci per il deposito';
								|pl = 'Przyjęcie towarów do przechowania';
								|tr = 'Malların depoya girişi'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
		DocumentSynonym = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
	EndIf;
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), DocumentSynonym, Data.Number, Data.Date);
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "GoodsReceiptForStorage");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("BusinessOperation");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date                             AS Period,
	|	DocumentData.Ref                           AS Ref,
	|	DocumentData.Organization                      AS Organization,
	|	DocumentData.Partner                          AS Partner,
	|	DocumentData.Partner                          AS Sender,
	|	DocumentData.Counterparty                       AS Counterparty,
	|	DocumentData.Counterparty.RegistrationCountry     AS RegistrationCountry,
	|	DocumentData.Terms                       AS Terms,
	|	DocumentData.Currency                           AS Currency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Terms.Currency                AS AgreementCurrency,
	|	DocumentData.PurchaseOrder                  AS PurchaseOrder,
	|	DocumentData.Warehouse                            AS Warehouse,
	|	DocumentData.ControlledLotReference             AS ControlledLotReference,
	|	DocumentData.BusinessOperation            AS BusinessOperation,
	|	DocumentData.Department                    AS Department,
	|	DocumentData.ReceiptUnderOrders             AS ReceiptUnderOrders,
	|	DocumentData.GoodsReceiptOption            AS GoodsReceiptOption,
	|	DocumentData.Contract                          AS Contract,
	|	DocumentData.Manager                         AS Manager,
	|	DocumentData.Author                            AS Author,
	|	DocumentData.VendorPriceKind                AS VendorPriceKind,
	|	DocumentData.VendorPriceKind.Currency         AS CurrencyOfSupplierSPriceType,
	|	DocumentData.DocumentAmount                   AS DocumentAmount,
	|	DocumentData.IncomingDocumentDate           AS IncomingDocumentDate,
	|	DocumentData.IncomingDocumentNumber          AS IncomingDocumentNumber,
	|	DocumentData.ExternalDocumentName   AS ExternalDocumentName,
	|	DocumentData.Number                            AS Number,
	|	DocumentData.Comment                      AS Comment,
	|	DocumentData.DeletionMark                  AS DeletionMark,
	|	DocumentData.Posted                         AS Posted,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	DocumentData.RegisterVendorPrices     AS RegisterVendorPrices,
	|	DocumentData.DocumentID           AS DocumentID,
	|	DocumentData.Patch                      AS Patch,
	|	DocumentData.ReversedDocument             AS ReversedDocument,
	|	DocumentData.CorrectedDocument             AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date        AS AdjustmentPeriod_,
	|	BusinessTransactionsSettings.Ref            AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsReceiptForStorage AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);

	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("ManagementAccountingCurrency",                                     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses",                          GetFunctionalOption("UseAccountingOfOtherIncomeExpenses")); 
	Query.SetParameter("ReceiptUnderSeveralOrders",                                 ?(Not ValueIsFilled(Attributes.PurchaseOrder), True, False));
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",                GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("ControlCompanyStockBalanceForRegistrationByReceipts",GetFunctionalOption("ControlCompanyStockBalanceForRegistrationByReceipts"));
	Query.SetParameter("ControlIssueOfCashByPurposes",                      GetFunctionalOption("ControlIssueOfCashByPurposes"));
	
	Query.SetParameter("IncomingDocumentNumber",                                        IncomingDocumentNumber);
	Query.SetParameter("MetadataIdentifier",                                        Common.MetadataObjectID(FullObjectName()));
	
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
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	GoodsTable.ItemsLocationAttributes.Products         AS Products,
	|	GoodsTable.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|	&EmptyAssignment          AS Purpose,
	|	GoodsTable.ItemsLocationAttributes.Series                AS Series,
	|	GoodsTable.ItemsLocationAttributes.StorageLocation        AS Warehouse
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|		AND &EmptyAssignment = Dimension.Purpose
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Procedure SetPartnerAccountingAnalyticsParameter(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters);
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);
	
EndProcedure

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers)
	
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = "
	|
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	GoodsTable.Count               AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &ReceiptUnderOrders
	|	AND GoodsTable.RowCode <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	0                                      AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.RowCode = 0
	|	AND &ReceiptUnderOrders
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber              AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	GoodsTable.PurchaseOrder          AS PurchaseOrder,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.RowCode                AS RowCode,
	|	GoodsTable.Warehouse                    AS Warehouse,
	|	0                                      AS Ordered,
	|	GoodsTable.Count               AS ToRegister
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.RowCode = 0
	|	AND &ReceiptUnderOrders
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	DataSource.Ref.Patch            AS Patch,
	|	DataSource.Ref.CorrectedDocument   AS CorrectedDocument,
	|	DataSource.PurchaseOrder               AS OrderDocument,
	|	DataSource.Ref.Contract                AS Contract,
	|	DataSource.Ref.Terms             AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.Ref.DateOfReceipt
	|			ELSE
	|				DataSource.Ref.Date
	|		END AS Date,
	|	
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DataSource.Ref.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	DataSource.Ref.Partner                AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DataSource.Ref.ReceiptUnderOrders   AS ReceiptUnderOrders
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	DataSource.Ref                        AS Invoice,
	|	DataSource.Ref.Patch            AS Patch,
	|	DataSource.Ref.CorrectedDocument   AS CorrectedDocument,
	|	DataSource.PurchaseOrder		         AS OrderDocument,
	|	DataSource.Ref.Contract                AS Contract,
	|	DataSource.Ref.Terms             AS Terms,
	|	DataSource.Ref.GoodsReceiptOption  AS GoodsReceiptOption,
	|	DataSource.Ref.Date                   AS Date,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	DataSource.Ref.ControlledLotReference   AS ControlledLotReference,
	|	DataSource.Series                         AS Series,
	|	DataSource.BatchesIndicationStatus           AS BatchesIndicationStatus,
	|	DataSource.Ref.ReceiptUnderOrders
	|		AND DataSource.RowCode = 0           AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	DataSource.Ref.Partner                AS Sender,
	|	DataSource.Ref.BusinessOperation  AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	TRUE                                       AS ThisIsAnInvoice,
	|	DataSource.Ref.ReceiptUnderOrders   AS ReceiptUnderOrders,
	|	FALSE AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	CurrentMetadataObject1 = Metadata.Documents.GoodsReceiptForStorage;
		
	WarehousesServer.CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers, QueryTextDocument_, CurrentMetadataObject1, "SetOfSeries");

EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
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
	|		WHEN (NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsReceiptForStorage.SetOfSeries AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	SeriesTable.Products,
	|	SeriesTable.Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
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
	|		WHEN (NOT SeriesTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|				OR &Period < SeriesTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period                      AS DateOfReceipt,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	GoodsTable.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber       AS CCDNumber
	|FROM
	|	TTTableProducts AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON
	|		GoodsTable.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute 
	|		AND GoodsTable.Products = UninvoicedReceipts.Products
	|		AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic 
	|		AND GoodsTable.Series = UninvoicedReceipts.Series
	|		AND GoodsTable.CCDNumber = UninvoicedReceipts.CCDNumber 
	|
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.CCDNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ShipmentCompany,
	|	TRUE AS Primary
	|FROM
	|	TTTableProducts AS GoodsTable
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	MIN(GoodsTable.LineNumber)        AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	&Period                                   AS Period,
	|	&Organization                              AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                  AS InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes  AS ItemsLocationAttributes,
	|	&Ref                                   AS DocumentInflow,
	|
	|	SUM(GoodsTable.Count)           AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan)         AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan)       AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl 
	|		+ GoodsTable.VATAmountCompl)         AS LocalCost,
	|	0                                         AS VATLocal,
	|
	|	GoodsTable.LotVendorAttributes        AS LotVendorAttributes,
	|	GoodsTable.Products                AS Products,
	|	GoodsTable.Characteristic              AS Characteristic,
	|
	|	&BusinessOperation                    AS BusinessOperation,
	|	TRUE                                    AS Primary,
	|	UNDEFINED                              AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BatchAccountingVersion21
	|
	|GROUP BY
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic
	|
	|ORDER BY
	|	LineNumber
	|";  
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Goods"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	UNDEFINED AS VATRate,
	|	0 AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Goods"" 								AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	UNDEFINED			 				AS VATRate,
	|	UNDEFINED							AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) AS AssetTaxClass,
	|	0										AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS DocumentTable
	|	INNER JOIN Document.GoodsReceiptForStorage AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableProducts(Query, QueryTexts)
	
	RegisterName = "TTTableProducts";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber                  AS LineNumber,
	|	GoodsTable.Ref                       AS Ref,
	|	GoodsTable.RowCode                    AS RowCode,
	|	GoodsTable.PurchaseOrder              AS PurchaseOrder,
	|	GoodsTable.Products                 AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.Characteristic               AS Characteristic,
	|	GoodsTable.Series                        AS Series,
	|
	|	GoodsTable.CCDNumber                     AS CCDNumber,
	|	GoodsTable.InventoryOwnerAttribute                   AS InventoryOwnerAttribute,
	|
	|	GoodsTable.Count                   AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END                                      AS QuantityByGBRN,
	|	GoodsTable.Price                         AS Price,
	|	GoodsTable.Warehouse                        AS Warehouse,
	|	CASE WHEN GoodsTable.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
	|			AND &Period >= GoodsTable.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
	|		THEN TRUE
	|		ELSE FALSE
	|	END                                      AS UseWarehouseManagemantSystemForGoodsReceipt,
	|	GoodsTable.Sum                        AS Sum,
	|	0                                          AS VATAmount,
	|	GoodsTable.Sum                        AS AmountIncludingVAT,
	|	GoodsTable.RowID          AS RowID,
	|	GoodsTable.Purpose                   AS Purpose,
	|	GoodsTable.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey       AS AnalysisOfAccountingForProductsWithoutAssignment,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)            AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)          AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)         AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)            AS VATAmountCompl,
	|
	|	GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND GoodsTable.InventoryOwnerAttribute.InventoryType IN (&InventoryTypesOwn) AS ThisIsTara,
	|
	|	VALUE(Catalog.VATRates.EmptyRef)     AS VATRate,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes
	|
	|INTO TTTableProducts
	|
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON GoodsTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		GoodsTable.Ref = Amounts.Ref
	|		AND GoodsTable.RowID = Amounts.RowID
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber = GoodsTable.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	CurrencyRatesCut.Currency    AS Currency,
	|	CurrencyRatesCut.CourseNumerator AS CourseNumerator,
	|	CurrencyRatesCut.CourseDenominator AS CourseDenominator
	|INTO
	|	TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyRatesCut
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableOfGoods_(Query, QueryTexts)
	
	RegisterName = "TemporaryTableOfGoods_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Goods.PartnerProducts AS PartnerProducts,
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	Goods.Package               AS Package,
	|	CAST(Goods.Price
	|				* CASE
	|					WHEN
	|						&Currency <> &AgreementCurrency
	|					THEN
	|						CASE
	|							WHEN ISNULL(ExchangeRatesOfAgreement_.CourseDenominator, 0) > 0
	|								AND ISNULL(ExchangeRatesOfAgreement_.CourseNumerator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|							THEN 
	|								(Currency_Rates.CourseNumerator * ExchangeRatesOfAgreement_.CourseDenominator)
	|								/ (ExchangeRatesOfAgreement_.CourseNumerator * Currency_Rates.CourseDenominator)
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
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS ExchangeRatesOfAgreement_
	|ON
	|	ExchangeRatesOfAgreement_.Currency = &AgreementCurrency
	|WHERE
	|	Goods.Ref = &Ref
	|	AND &RegisterVendorPrices
	|	AND (Goods.RowCode = 0 OR NOT Goods.PurchaseOrder.RegisterVendorPrices)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts)
	
	RegisterName = "ProductsWithDifferentPackagingPrices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	Goods.Products                    AS Products,
	|	Goods.Characteristic                  AS Characteristic,
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
	|	Characteristic
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ProductsWithDifferentPackagingPrices", QueryTexts) Then
		QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	MAX(Goods.PartnerProducts) AS PartnerProducts,
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	&VendorPriceKind                      AS VendorPriceKind,
	|	&CurrencyOfSupplierSPriceType               AS Currency,
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
	|				END
	|			* CASE
	|				WHEN
	|					&Currency <> &CurrencyOfSupplierSPriceType
	|				THEN
	|					CASE
	|						WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|							AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|							AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|						THEN 
	|							(Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator)
	|							/ (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|						ELSE
	|							0
	|					END
	|				ELSE 
	|					1
	|			END) AS NUMBER(31,2)) AS Price
	|FROM
	|	TemporaryTableOfGoods_ AS Goods
	|LEFT JOIN
	|	ProductsWithDifferentPackagingPrices AS ProductsWithDifferentPackagingPrices
	|ON
	|	Goods.Products = ProductsWithDifferentPackagingPrices.Products
	|	AND Goods.Characteristic = ProductsWithDifferentPackagingPrices.Characteristic
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|ON
	|	CurrencyRatesPrices.Currency = &CurrencyOfSupplierSPriceType
	|WHERE
	|	&VendorPriceKind <> VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.GoodsReceiptForStorage";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber", """""");
	RedefiningParameterCalculation.Insert("Sender",  "GoodsTable.Ref.Partner");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "PurchaseOrders" Then
		
		QueryText = QueryTextTablePurchaseOrders(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
		
	ElsIf RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
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
	
	If RegisterName = "DocumentsRegistry" Then
		
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
			RedefiningParameterCalculation);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&IncomingDocumentDate                 AS SourceDocumentDate,
	|	&IncomingDocumentNumber                AS SourceDocumentNumber,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&ExternalDocumentName         AS SourceDocumentName,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	&Partner AS Warehouse,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	GoodsTable.ItemsLocationAttributes AS CorItemsLocationAttributes,
	|	&Warehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType AS CorInventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Count AS CorQuantity,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	UNDEFINED AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN GoodsTable.InventoryOwnerAttribute
	|			ELSE GoodsTable.Products
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTableProducts AS GoodsTable
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	&ControlledLotReference AS ControlledLotReference,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref.ReceiptUnderOrders
		|	AND TabPart.RowCode <> 0 AS OnSchedule,
		|	CASE
		|		WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.GoodsReceiptOption IN
		|			(VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|			VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|			THEN TabPart.Ref.Terms
		|		WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.GoodsReceiptOption IN
		|			(VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		OR NOT TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		OR TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date";
	
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
		|	Document.GoodsReceiptForStorage.Goods AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|		AND TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref                                                AS Ref,
		|	TabPart.Ref.Date                                           AS Period,
		|	TabPart.Products                                          AS Products,
		|	TabPart.Characteristic                                        AS Characteristic,
		|	TabPart.Warehouse                                                 AS Warehouse,
		|	CASE
		|		WHEN TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|			THEN VALUE(Catalog.Assignments.EmptyRef)
		|		ELSE TabPart.Purpose
		|	END AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	CASE WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|					VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices)) THEN
		|					
		|				TabPart.Ref.Terms
		|					
		|			WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices)) THEN
		|					
		|					TabPart.Ref.Contract
		|					
		|			WHEN TabPart.Ref.ReceiptUnderOrders
		|					AND TabPart.Ref.GoodsReceiptOption
		|						<> VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) THEN
		|					TabPart.PurchaseOrder
		|			ELSE
		|				CASE
		|					WHEN TabPart.Ref.CorrectedDocument = VALUE(Document.GoodsReceiptForStorage.EmptyRef)
		|						THEN TabPart.Ref
		|					ELSE TabPart.Ref.CorrectedDocument
		|				END
		|		END AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.DateOfReceipt <> DATETIME(1, 1, 1) THEN
		|				TabPart.Ref.DateOfReceipt
		|			ELSE
		|				TabPart.Ref.Date
		|		END AS DateOfReceipt,
		|	
		|	TRUE                                                         AS AvailableForConsumption,
		|	TabPart.Ref.ReceiptUnderOrders AND TabPart.RowCode <> 0 AS OnSchedule,
		|	
		|	CASE WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|				AND TabPart.Ref.GoodsReceiptOption IN(
		|					VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed),
		|					VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|					VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices)) THEN
		|					
		|				TabPart.Ref.Terms
		|					
		|		WHEN TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.Date >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Ref.GoodsReceiptOption IN
		|			(VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices),
		|			VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|			THEN TabPart.Ref.Contract
		|		ELSE TabPart.PurchaseOrder
		|	END AS OrderInSchedule,
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	Document.GoodsReceiptForStorage.Goods AS TabPart
		|WHERE
		|	TabPart.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt
		|		AND TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date
		|		AND (TabPart.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)
		|			OR NOT TabPart.Ref.ReceiptUnderOrders
		|			OR TabPart.RowCode = 0)";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
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
		SetPartnerAccountingAnalyticsParameter(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableProducts");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableProducts(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization						AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	UNDEFINED 										AS VATActivityType,
	|	UNDEFINED										AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	UNDEFINED 					AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity			AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	UNDEFINED 					AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	UNDEFINED 									AS RowID,
	|	CASE WHEN TableTypesOfStocks_.ThisIsTara
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END 											AS Cost,
	|	CASE WHEN TableTypesOfStocks_.ThisIsTara
	|		THEN TableTypesOfStocks_.AmountExcludingVATMan
	|		ELSE 0
	|	END 											AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.ThisIsTara
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0
	|	END 											AS LocalCost,
	|	0                                   			AS VATLocal,
	|	0 												AS CostMan,
	|	0 												AS VATManag,
	|	CASE WHEN NOT TableTypesOfStocks_.ThisIsTara
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END											AS OffBalanceCost,
	|	CASE WHEN NOT TableTypesOfStocks_.ThisIsTara
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE 0
	|	END											AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0	 											AS CostOfPersonalIncomeTax,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	&DocumentID			 				AS FinRecordID,
	|	&BusinessTransactionSetting                 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsReceiptForStorage AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

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
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
		
	Return JobPrintingRules;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Receipt of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "Invoice";
	PrintCommand.Presentation = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
									|ru = 'Приемка товаров на хранение';
									|en = 'VMI procurement'; fa = 'تدارکات VMI';
									|it = 'Accettazione delle merci per il deposito';
									|pl = 'Przyjęcie towarów do przechowania';
									|tr = 'Malların depoya girişi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale,
		ComparisonType.Equal);
		
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "InvoiceReceiptOfRawMaterialsFromGiver";
	PrintCommand.Presentation = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand,
		"BusinessOperation",
		Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5,
		ComparisonType.Equal);
	// Receipt invoice
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "PurchaseInvoice";
	PrintCommand.Presentation = NStr("vi = 'Hóa đơn nhập hàng';
									|ru = 'Приходная накладная';
									|en = 'Delivery note'; fa = 'Delivery note';
									|it = 'Bolla di acquisto';
									|pl = 'Faktura przyjęcie z zewnątrz';
									|tr = 'Sevk irsaliyesi'");
	PrintCommand.CheckPostingBeforePrint = True;

	// Assignment for the placement of goods
	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");

	If UserRightsCached.PrintPriceTagsAndLabels() Then
		// PriceTags
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "PrintManagementTMClient.PrintPriceTagsAndLabels";
		PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels";
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
		PrintCommand.PrintManager = "DataProcessor.PrintPriceTagsAndLabels";
		PrintCommand.Id = "Labels";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	GoodsReceiptForStorageLocalization.AddPrintCommands(PrintCommands);

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
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "InvoiceReceiptOfRawMaterialsFromGiver") Then
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"InvoiceReceiptOfRawMaterialsFromGiver",
			NStr("vi = 'Phiếu nhập kho';
				|ru = 'Накладная';
				|en = 'Invoice'; fa = 'فاکتور';
				|it = 'Lettera di vettura';
				|pl = 'Invoice';
				|tr = 'İrsaliye'"),
			FormPrintedFormInvoice(ObjectsArray, PrintObjects));
		
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PurchaseInvoice") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "PurchaseInvoice", NStr("vi = 'Hóa đơn nhập hàng';
																											|ru = 'Приходная накладная';
																											|en = 'Purchase invoice'; fa = 'فاکتور خرید';
																											|it = 'Bolla di acquisto';
																											|pl = 'Faktura przyjęcie z zewnątrz';
																											|tr = 'Sevk irsaliyesi'"), FormPrintedFormReceiptInvoice(ObjectsArray, PrintObjects));
	EndIf;
	
	GoodsReceiptForStorageLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function FormPrintedFormInvoice(ObjectsArray, PrintObjects)
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////
	|// REQUEST BY HEADER
	|
	|SELECT
	|	GoodsReceiptForStorage.Ref              AS Ref,
	|	GoodsReceiptForStorage.Number               AS Number,
	|	GoodsReceiptForStorage.Date                AS Date,
	|	GoodsReceiptForStorage.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	GoodsReceiptForStorage.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	GoodsReceiptForStorage.Patch         AS Patch,
	|	GoodsReceiptForStorage.Partner             AS Partner,
	|	GoodsReceiptForStorage.Counterparty          AS Vendor,
	|	GoodsReceiptForStorage.Organization         AS Organization,
	|	GoodsReceiptForStorage.Organization.Prefix AS Prefix,
	|	GoodsReceiptForStorage.Currency              AS Currency,
	|	GoodsReceiptForStorage.ReceivedBy              AS ReceivedBy,
	|	GoodsReceiptForStorage.AcceptedPosition     AS AcceptedPosition,
	|	GoodsReceiptForStorage.HandedOverBy                AS HandedOverBy,
	|	GoodsReceiptForStorage.HandedOverJobTitle       AS HandedOverJobTitle,
	|	GoodsReceiptForStorage.BusinessOperation AS BusinessOperation
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|
	|WHERE
	|	GoodsReceiptForStorage.Ref IN (&DocumentsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////
	|// QUERY BY TABLE PARTS
	|
	|SELECT
	|	NestedQuery.Ref								AS Ref,
	|	NestedQuery.Products						AS Products,
	|	NestedQuery.Products.DescriptionFull		AS ProductNameFull_,
	|	NestedQuery.Products.Code					AS Code,
	|	NestedQuery.Products.SKU				AS SKU,
	|	NestedQuery.UnitOfMeasure.Description		AS UnitPrice,
	|	NestedQuery.UnitOfMeasure					AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull	AS Characteristic,
	|	NestedQuery.Series.Description					AS Series,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|		THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END												AS Package,
	|	
	|	VALUE(Catalog.VATRates.EmptyRef)         AS VATRate,
	|	NestedQuery.Price								AS Price,
	|	NestedQuery.Count							AS Count,
	|	NestedQuery.Sum								AS Sum,
	|	0                                                   AS VATAmount,
	|	NestedQuery.LineNumber							AS LineNumber
	|FROM (
	|	SELECT
	|		GoodsReceiptForStorage.Ref				AS Ref,
	|		GoodsReceiptForStorage.Products		AS Products,
	|
	|		CASE WHEN GoodsReceiptForStorage.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			1
	|		ELSE
	|			&QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|
	|		CASE WHEN GoodsReceiptForStorage.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			GoodsReceiptForStorage.Products.UnitOfMeasure
	|		ELSE
	|			GoodsReceiptForStorage.Package
	|		END										AS UnitOfMeasure,
	|
	|		GoodsReceiptForStorage.Characteristic		AS Characteristic,
	|		GoodsReceiptForStorage.Series				AS Series,
	|		GoodsReceiptForStorage.Package			AS Package,
	|		GoodsReceiptForStorage.Price				AS Price,
	|		GoodsReceiptForStorage.NumberOfPackages	AS Count,
	|		GoodsReceiptForStorage.Sum				AS Sum,
	|		GoodsReceiptForStorage.LineNumber		AS LineNumber
	|	FROM
	|		Document.GoodsReceiptForStorage.Goods AS GoodsReceiptForStorage
	|	WHERE
	|		GoodsReceiptForStorage.Ref IN(&DocumentsArray)
	|) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|
	|TOTALS
	|	SUM(Sum)
	|
	|BY
	|	Ref
	|");
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"GoodsReceiptForStorage.Package",
			"GoodsReceiptForStorage.Products"));
	
	Query.SetParameter("DocumentsArray", 				ObjectsArray);

	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsReceiptForStorage_Invoice";
	
	ResultsArray 		= Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		ProductSelection_1 = SelectionByDocuments.Select();
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.GoodsReceiptForStorage.PF_MXL_GoodsReceiptForStorage");
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		TemplateArea = Template.GetArea("Title");
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		
		TitleText = NStr("vi = 'Nhập kho hàng hóa để lưu trữ';
						|ru = 'Приемка товаров на хранение';
						|en = 'VMI procurement'; fa = 'تدارکات VMI';
						|it = 'Accettazione delle merci per il deposito';
						|pl = 'Przyjęcie towarów do przechowania';
						|tr = 'Malların depoya girişi'");
		If PrintData.BusinessOperation = Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5 Then
			TitleText = TollingSchemeClientServer.SynonymForDocumentAcceptanceOfGoodsForStorage();
		EndIf;
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, 
			TitleText));
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
		
		ProductColumnArea = Template.Area("OwnGoods");
			
		If Not OutputCodes Then
			
			ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
			
		EndIf;
		
			
		RoomArea  = Template.GetArea("TableHeader|LineNumber");
		AreaCodes   = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductArea   = Template.GetArea("TableHeader|OwnGoods");
		DataArea  = Template.GetArea("TableHeader|Data");
			
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
			
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		RoomArea  = Template.GetArea("TableRow|LineNumber");
		AreaCodes   = Template.GetArea("TableRow|ColumnOfCodes");
		ProductArea   = Template.GetArea("TableRow|OwnGoods");
		DataArea  = Template.GetArea("TableRow|Data");
			
		Sum		= 0;
		LineNumber	= 0;
		
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

			SpreadsheetDocument.Join(DataArea);
			
			Sum = Sum + ProductSelection_1.Sum;
			
		EndDo;
		
		// We output the basement
		
		RoomArea  = Template.GetArea("TableFooter|LineNumber");
		AreaCodes   = Template.GetArea("TableFooter|ColumnOfCodes");
		ProductArea   = Template.GetArea("TableFooter|OwnGoods");
		DataArea  = Template.GetArea("TableFooter|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		
		StructureOfData = New Structure;
		StructureOfData.Insert("Total",  PrintFormGeneration.SumFormat(Sum));
		DataArea.Parameters.Fill(StructureOfData);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the total of the ADS
		RoomArea	= Template.GetArea("VATTableBasement|LineNumber");
		AreaCodes	= Template.GetArea("VATTableBasement|ColumnOfCodes");
		ProductArea	= Template.GetArea("VATTableBasement|OwnGoods");
		DataArea	= Template.GetArea("VATTableBasement|Data");
		
		SpreadsheetDocument.Put(RoomArea);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
		
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
		
		// We output the Amount in words
		
		TemplateArea = Template.GetArea("AmountInWords");
		AmountToBeRegistered = Sum;
		
		TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số là %1, thành tiền %2';
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
		TemplateArea.Parameters.Fill(PrintData);
		DataStructureAccepted = New Structure;
		DataStructureAccepted.Insert("ReceivedBy", PersonsTM.IndividualShortName(PrintData.ReceivedBy, PrintData.Date));
		TemplateArea.Parameters.Fill(DataStructureAccepted);
		
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
//	DocumentsArray - Array of DocumentRef.GoodsReceiptForStorage - a collection of document references used
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
	|	Document.GoodsReceiptForStorage.Goods AS TableOfGoods
	|		LEFT JOIN Document.GoodsReceiptForStorage AS HeaderData_
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
	|	Document.GoodsReceiptForStorage.SetOfSeries AS TableOfSeries
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
	|	Document.GoodsReceiptForStorage AS HeaderData_
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
	|	AcceptanceOfGoodsForStorageGoods.Products   AS Products,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic AS Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.Series          AS Series,
	|	CASE WHEN AcceptanceOfGoodsForStorageGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.Package
	|	ELSE
	|		AcceptanceOfGoodsForStorageGoods.Package
	|	END AS Package,
	|
	|	MIN(AcceptanceOfGoodsForStorageGoods.LineNumber) AS Order,
	|	SUM(
	|		CASE WHEN AcceptanceOfGoodsForStorageGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|			AcceptanceOfGoodsForStorageGoods.NumberOfPackages * (ISNULL(&QueryTextPackagingFactor1, 1) / ISNULL(&QueryTextPackagingFactor2, 1))
	|		ELSE
	|			AcceptanceOfGoodsForStorageGoods.NumberOfPackages
	|		END) AS Count
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS AcceptanceOfGoodsForStorageGoods
	|		LEFT JOIN InformationRegister.ItemsPrices25.SliceLast AS ItemsPrices
	|		ON ItemsPrices.Products     = AcceptanceOfGoodsForStorageGoods.Products
	|		 AND ItemsPrices.PricingVariant = AcceptanceOfGoodsForStorageGoods.Characteristic.ItemsCharacteristicForPricing
	|		 AND ItemsPrices.PricingBatch          = AcceptanceOfGoodsForStorageGoods.Series.ItemsBatchForPricing
	|		 AND ItemsPrices.PriceKind          = AcceptanceOfGoodsForStorageGoods.Ref.Warehouse.RetailPriceType
	|	
	|WHERE
	|	AcceptanceOfGoodsForStorageGoods.Ref IN(&DocumentsArray)
	|
	|GROUP BY
	|	AcceptanceOfGoodsForStorageGoods.Products,
	|	AcceptanceOfGoodsForStorageGoods.Characteristic,
	|	AcceptanceOfGoodsForStorageGoods.Series,
	|	CASE WHEN AcceptanceOfGoodsForStorageGoods.Ref.Warehouse.WarehouseStore = VALUE(Enum.TypesOfWarehouses.RetailStore) THEN
	|		ItemsPrices.Package
	|	ELSE
	|		AcceptanceOfGoodsForStorageGoods.Package
	|	END
	|
	|ORDER BY
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsReceiptForStorage.Organization            AS Organization,
	|	GoodsReceiptForStorage.Warehouse                  AS Warehouse,
	|	GoodsReceiptForStorage.Warehouse.RetailPriceType AS PriceKind
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceiptForStorage
	|WHERE
	|	GoodsReceiptForStorage.Ref IN(&DocumentsArray)";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"AcceptanceOfGoodsForStorageGoods.Package",
			"AcceptanceOfGoodsForStorageGoods.Products"));
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
	
	// Preparation of data for filling in the tabular part of the processing of printing price tags and labels.
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
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_GoodsReceiptForStorage_PurchaseInvoice";
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	PackagingUsage = GetFunctionalOption("UseItemPackages");
	
	Query = New Query(
	"SELECT DISTINCT
	|	GoodsReceipt.Ref AS Ref,
	|	GoodsReceipt.Organization AS Organization,
	|	GoodsReceipt.Counterparty AS Counterparty,
	|	GoodsReceipt.Number AS Number,
	|	GoodsReceipt.Date AS Date,
	|	GoodsReceipt.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	GoodsReceipt.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	GoodsReceipt.Patch AS Patch,
	|	GoodsReceipt.Organization.Prefix AS Prefix,
	|	GoodsReceipt.ReceivedBy,
	|	GoodsReceipt.AcceptedPosition,
	|	GoodsReceipt.HandedOverBy,
	|	GoodsReceipt.HandedOverJobTitle
	|FROM
	|	Document.GoodsReceiptForStorage AS GoodsReceipt
	|WHERE
	|	GoodsReceipt.Ref IN(&ObjectsArray)
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
	|	END AS Package
	|FROM
	|	Document.GoodsReceiptForStorage.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
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
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsReceiptForStorage.PF_MXL_PurchaseInvoice");
	
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
	
	DocumentAttributes = New Structure("Number, Date, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected,
		|Prefix, Presentation, PresentationOfOrder, RepresentationOfTheOrganization, 
		|PartnerPresentation_, HandedOverBy, HandedOverJobTitle, ReceivedBy, AcceptedPosition");
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
			DocumentAttributes, 
			NStr("vi = 'Tiếp nhận hàng hóa';
				|ru = 'Поступление товаров';
				|en = 'Goods pick-up from customer'; fa = 'Goods pick-up from customer';
				|it = 'Arrivo delle merci';
				|pl = 'Wpływ towarów';
				|tr = 'İrsaliye'", Common.DefaultLanguageCode()));
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
				
				AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
				AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
				
				OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
					ProductSelection_1.Products,
					ProductSelection_1.Characteristic,
					,
					,
					AdditionalParametersProductPresentation);
					
				ProductDataStructure = New Structure("OwnGoods", OwnGoods);
				Area.Parameters.Fill(ProductDataStructure);
				Area.Parameters.Fill(ProductSelection_1);
				SpreadsheetDocument.Put(Area);
				
			EndDo;
			
			Area = Template.GetArea("TableFooter");
			SpreadsheetDocument.Put(Area);
			
			Area = Template.GetArea("Signatures");
			TextOfResultingLine = NStr("vi = 'Tổng số là %TotalItems_1%';
										|ru = 'Всего наименований %TotalItems_1%';
										|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
										|it = 'Totale articoli %TotalItems_1%';
										|pl = 'Razem pozycji %TotalItems_1%';
										|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
			TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", LineCount-1);
			DocumentAttributes.Insert("TotalString", TextOfResultingLine);
			Area.Parameters.Fill(DocumentAttributes);
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
	
EndProcedure

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//  ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	CommonQueryParameters = ToDoListServer.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.GoodsReceiptForStorage))
		And AccessRight("View", Metadata.Documents.MaterialProviderOrder2_5)
		And (AccessRight("Insert", Metadata.Documents.GoodsReceiptForStorage)
			Or AccessRight("Update", Metadata.Documents.GoodsReceiptForStorage))
		And GetFunctionalOption("UseTollManufacturing2_5");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	ReceiptOfRawMaterialsFromGiverToRegistration2_5 =
		DataProcessors.DocumentsOfReceiptForTollingAll2_5.NumberOfLinesForLayout(
			Enums.BusinessTransactions.ReceiptFromMaterialProvider2_5);
	
	UserTaskParent = ToDoList.Find("ProcessingOfProvidedMaterials2_5", "Id");
	If UserTaskParent = Undefined Then
		UserTaskParent = ToDoList.Add();
		UserTaskParent.Id = "ProcessingOfProvidedMaterials2_5";
		UserTaskParent.Presentation = NStr("vi = 'Gia công sản xuất';
											|ru = 'Переработка давальческого сырья';
											|en = 'Subcontracting services'; fa = 'خدمات پیمانکاری فرعی';
											|it = 'Trasformazione di materie prime del committente';
											|pl = 'Przetwarzanie surowców dostarczonych przez klienta';
											|tr = 'Sağlayıcı hammaddelerinin yeniden işlenmesi'");
		UserTaskParent.Owner      = Metadata.Subsystems.Sales;
	EndIf;
	
	UserTaskParent.HasToDoItems = UserTaskParent.HasToDoItems Or ReceiptOfRawMaterialsFromGiverToRegistration2_5 > 0;
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentPageName",      "RawMaterialReceiptPage");
	FormParameters.Insert("FormAssignmentKey",     "ToDoList");
	FormParameters.Insert("QuickFilterStructure", New Structure);
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "ReceiptOfRawMaterialsFromGiverToRegistration2_5";
	ToDoItem.HasToDoItems       = ReceiptOfRawMaterialsFromGiverToRegistration2_5 > 0;
	ToDoItem.Presentation  = NStr("vi = 'Chuẩn bị lập tiếp nhận nguyên vật liệu từ bên đặt gia công';
									|ru = 'Поступления сырья от давальцев к оформлению';
									|en = 'Receive raw materials from the material providers for registration'; fa = 'Receive raw materials from the material providers for registration';
									|it = 'Arrivi delle materie prime dai prestatori da formalizzare';
									|pl = 'Napływ surowców dostarczonych przez klienta do rejestracji';
									|tr = 'Hammaddelerin işlenmek üzere sağlayıcılardan teslim alınması'");
	ToDoItem.Count     = ReceiptOfRawMaterialsFromGiverToRegistration2_5;
	ToDoItem.Important         = False;
	ToDoItem.Form          = "DataProcessor.DocumentsOfReceiptForTollingAll2_5.Form.ToRegisterInvoices";
	ToDoItem.FormParameters = FormParameters;
	ToDoItem.Owner       = "ProcessingOfProvidedMaterials2_5";
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.GoodsReceiptForStorage";
EndFunction

// Generates the query result for the undelivered part of orders.
//
// Parameters:
//	SelectionData_ 		- Structure - the fields that will be selected remnants of the orders.
//	WarehouseForReceipt 	- CatalogRef.Warehouses - the warehouse where the remaining orders will be selected.
//	AnArrayOfOrders 		- Array - orders for which balances will be selected.
//
// Returns:
//	QueryResult - the result of the request for the undelivered part of the orders /.
//
Function GetQueryResultsForOrderBalances(SelectionData_, WarehouseForReceipt = Undefined,
		AnArrayOfOrders = Undefined)
	
	Query = New Query;
	Query.SetParameter("Recorder",             SelectionData_.Ref);
	Query.SetParameter("CurrentDate",             BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Partner",                 SelectionData_.Partner);
	Query.SetParameter("Counterparty",              SelectionData_.Counterparty);
	Query.SetParameter("Terms",              SelectionData_.Terms);
	Query.SetParameter("Organization",             SelectionData_.Organization);
	Query.SetParameter("WarehouseForReceipt",        WarehouseForReceipt);
	Query.SetParameter("Contract",                 SelectionData_.Contract);
	Query.SetParameter("BusinessOperation",   SelectionData_.BusinessOperation);
	Query.SetParameter("LineOfBusiness", SelectionData_.LineOfBusiness);
	Query.SetParameter("GoodsReceiptOption",   SelectionData_.GoodsReceiptOption);
	Query.SetParameter("AnArrayOfOrders",           AnArrayOfOrders);
	Query.SetParameter("SelectByOrder_",        AnArrayOfOrders <> Undefined);
	
	If TypeOf(SelectionData_) = Type("Structure")
		And SelectionData_.Property("InvoiceGoods") Then
		
		Query.SetParameter("InvoiceGoods", SelectionData_.InvoiceGoods);
		
	Else
		
		OrderTypes = New Array;
		OrderTypes.Add(Type("DocumentRef.PurchaseOrder"));
		OrderTypes.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
		InvoiceGoods = New ValueTable;
		InvoiceGoods.Columns.Add("LineNumber", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		InvoiceGoods.Columns.Add("RowCode", New TypeDescription("Number", New NumberQualifiers(10, 0)));
		InvoiceGoods.Columns.Add("PartnerProducts", New TypeDescription("CatalogRef.ProductCrossReferences"));
		InvoiceGoods.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		InvoiceGoods.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		InvoiceGoods.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		InvoiceGoods.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
		InvoiceGoods.Columns.Add("Series", New TypeDescription("CatalogRef.ItemsBatches"));
		InvoiceGoods.Columns.Add("Count", TMCommonUse.DescriptionOfQuantitativeFieldType());
		InvoiceGoods.Columns.Add("Price", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("Sum", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("AmountARAP", TMCommonUse.MoneyFieldTypeDescription());
		InvoiceGoods.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		InvoiceGoods.Columns.Add("PurchaseOrder", New TypeDescription(OrderTypes));
		InvoiceGoods.Columns.Add("QuantityInOrder", TMCommonUse.DescriptionOfQuantitativeFieldType());
		InvoiceGoods.Columns.Add("SalesOpportunity", New TypeDescription("CatalogRef.SalesOpportunitiesToCustomer"));
		
		Query.SetParameter("InvoiceGoods", InvoiceGoods);
		
	EndIf;
	
	Query.Text =
	"SELECT
	|	OrdersTable.PurchaseOrder    AS PurchaseOrder,
	|	OrdersTable.RowCode          AS RowCode,
	|	OrdersTable.Products       AS Products,
	|	OrdersTable.Characteristic     AS Characteristic,
	|	OrdersTable.Warehouse              AS Warehouse,
	|	SUM(OrdersTable.ToRegister) AS Count
	|INTO TableBalance
	|FROM
	|	(SELECT
	|		OrdersBalance.PurchaseOrder    AS PurchaseOrder,
	|		OrdersBalance.Products       AS Products,
	|		OrdersBalance.Characteristic     AS Characteristic,
	|		OrdersBalance.RowCode          AS RowCode,
	|		OrdersBalance.Warehouse              AS Warehouse,
	|		OrdersBalance.ToRegisterBalance AS ToRegister
	|	FROM
	|		AccumulationRegister.PurchaseOrders.Balance(,
	|			CASE
	|				WHEN &SelectByOrder_
	|					THEN PurchaseOrder IN (&AnArrayOfOrders)
	|				ELSE PurchaseOrder.Partner = &Partner
	|					AND PurchaseOrder.Counterparty = &Counterparty
	|					AND PurchaseOrder.Contract = &Contract
	|					AND PurchaseOrder.Organization = &Organization
	|					AND PurchaseOrder.GoodsReceiptOption = &GoodsReceiptOption
	|					AND
	|					(&BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|					AND PurchaseOrder.BusinessOperation IN(
	|						VALUE(Enum.BusinessTransactions.TollManufacturing2_5),
	|						VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|						VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|						VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|						VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|					OR
	|					PurchaseOrder.BusinessOperation = &BusinessOperation
	|					AND PurchaseOrder.Terms = &Terms
	|					)
	|			END
	|			AND CASE
	|				WHEN CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|					THEN Warehouse IN HIERARCHY (&WarehouseForReceipt)
	|							OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|					ELSE Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|			END) AS OrdersBalance
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		TrafficOrders.PurchaseOrder,
	|		TrafficOrders.Products,
	|		TrafficOrders.Characteristic,
	|		TrafficOrders.RowCode,
	|		TrafficOrders.Warehouse,
	|		CASE
	|			WHEN TrafficOrders.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				THEN -TrafficOrders.ToRegister
	|			ELSE TrafficOrders.ToRegister
	|		END
	|	FROM
	|		AccumulationRegister.PurchaseOrders AS TrafficOrders
	|	WHERE
	|		TrafficOrders.Recorder = &Recorder
	|		AND CASE
	|			WHEN &SelectByOrder_
	|				THEN TrafficOrders.PurchaseOrder IN (&AnArrayOfOrders)
	|			ELSE TrafficOrders.PurchaseOrder.Partner = &Partner
	|				AND TrafficOrders.PurchaseOrder.Counterparty = &Counterparty
	|				AND TrafficOrders.PurchaseOrder.Contract = &Contract
	|				AND TrafficOrders.PurchaseOrder.Organization = &Organization
	|				AND TrafficOrders.PurchaseOrder.GoodsReceiptOption = &GoodsReceiptOption
	|				AND
	|				(&BusinessOperation = VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|				AND TrafficOrders.PurchaseOrder.BusinessOperation IN(
	|					VALUE(Enum.BusinessTransactions.TollManufacturing2_5),
	|					VALUE(Enum.BusinessTransactions.Subcontracting2_5),
	|					VALUE(Enum.BusinessTransactions.RepairProductsFromProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformWorksUsingProvidedMaterials2_5),
	|					VALUE(Enum.BusinessTransactions.PerformRMUsingProvidedMaterials2_5))
	|				OR
	|				TrafficOrders.PurchaseOrder.BusinessOperation = &BusinessOperation
	|				AND TrafficOrders.PurchaseOrder.Terms = &Terms
	|				)
	|		END
	|		AND TrafficOrders.Active
	|		AND CASE
	|			WHEN CAST(&WarehouseForReceipt AS Catalog.Warehouses).IsFolder
	|				THEN TrafficOrders.Warehouse IN HIERARCHY (&WarehouseForReceipt)
	|					OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			ELSE TrafficOrders.Warehouse IN (VALUE(Catalog.Warehouses.EmptyRef), &WarehouseForReceipt)
	|		END) AS OrdersTable
	|
	|GROUP BY
	|	OrdersTable.PurchaseOrder,
	|	OrdersTable.Products,
	|	OrdersTable.Characteristic,
	|	OrdersTable.RowCode,
	|	OrdersTable.Warehouse
		
	|HAVING
	|	SUM(OrdersTable.ToRegister) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Recorder AS PurchaseOrder,
	|	InvoiceGoods.LineNumber AS LineNumber,
	|	InvoiceGoods.RowCode AS RowCode,
	|	InvoiceGoods.PartnerProducts AS PartnerProducts,
	|	CAST(InvoiceGoods.Products AS Catalog.Products) AS Products,
	|	InvoiceGoods.Characteristic AS Characteristic,
	|	InvoiceGoods.Purpose AS Purpose,
	|	CAST(InvoiceGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package,
	|	InvoiceGoods.Series AS Series,
	|	InvoiceGoods.Count AS Count,
	|	InvoiceGoods.Price AS Price,
	|	InvoiceGoods.Sum AS Sum,
	|	InvoiceGoods.Sum AS AmountARAP,
	|	CAST(InvoiceGoods.Warehouse AS Catalog.Warehouses) AS Warehouse,
	|	InvoiceGoods.Count AS QuantityInOrder,
	|	InvoiceGoods.SalesOpportunity AS SalesOpportunity
	|INTO
	|	TTGoodsWaybill
	|FROM
	|	&InvoiceGoods AS InvoiceGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBalance.PurchaseOrder           AS PurchaseOrder,
	|	TableBalance.Products              AS Products,
	|	TableBalance.Characteristic            AS Characteristic,
	|	TableBalance.RowCode                 AS RowCode,
	|	TableBalance.Count                AS Count,
	|	TableBalance.Warehouse                     AS Warehouse,
	|	ISNULL(WaybillGoods.Count,0)   AS QuantityInInvoice,
	|	OrderingProducts.Count                   AS QuantityInOrder,
	|	OrderingProducts.LineNumber                  AS LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity                AS SalesOpportunity,
	|	OrderingProducts.DateOfReceipt              AS DateOfReceipt,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
	|	OrderingProducts.Count                   AS QuantityByOrder,
	|	OrderingProducts.Price                         AS Price,
	|	OrderingProducts.Sum                        AS Sum,
	|	OrderingProducts.Products.ItemsType AS ItemsType,
	|	OrderingProducts.PartnerProducts         AS PartnerProducts,
	|	OrderingProducts.Purpose                   AS Purpose,
	|	CASE
	|		WHEN TableBalance.PurchaseOrder REFS Document.MaterialProviderOrder2_5
	|			THEN CAST(TableBalance.PurchaseOrder AS Document.MaterialProviderOrder2_5).VATTaxation
	|		WHEN TableBalance.PurchaseOrder REFS Document.SubcontractOrder2_5
	|			THEN CAST(TableBalance.PurchaseOrder AS Document.SubcontractOrder2_5).VATTaxation
	|		WHEN TableBalance.PurchaseOrder REFS Document.PurchaseOrder
	|			THEN CAST(TableBalance.PurchaseOrder AS Document.PurchaseOrder).VATTaxation
	|		ELSE VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	END AS VATTaxation,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2)
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	CASE
	|		WHEN TableBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|				AND TableBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.PurchaseOrder.Goods AS OrderingProducts
	|		ON TableBalance.Products = OrderingProducts.Products
	|			AND TableBalance.Characteristic = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode = OrderingProducts.RowCode
	|			AND TableBalance.PurchaseOrder = OrderingProducts.Ref
	|
	|		LEFT JOIN TTGoodsWaybill AS WaybillGoods
	|		ON TableBalance.Products = WaybillGoods.Products
	|			AND TableBalance.Characteristic = WaybillGoods.Characteristic
	|			AND TableBalance.RowCode = WaybillGoods.RowCode
	|			AND TableBalance.PurchaseOrder = WaybillGoods.PurchaseOrder
	|
	|UNION ALL
	|
	|SELECT
	|	TableBalance.PurchaseOrder                           AS PurchaseOrder,
	|	TableBalance.Products                              AS Products,
	|	TableBalance.Characteristic                            AS Characteristic,
	|	TableBalance.RowCode                                 AS RowCode,
	|	TableBalance.Count                                AS Count,
	|	TableBalance.Warehouse                                     AS Warehouse,
	|	ISNULL(WaybillGoods.Count,0)                   AS QuantityInInvoice,
	|	OrderingProducts.Count                                   AS QuantityInOrder,
	|	OrderingProducts.LineNumber                                  AS LineNumber,
	|	OrderingProducts.Ref.SalesOpportunity                                AS SalesOpportunity,
	|	OrderingProducts.DateOfReceipt                              AS DateOfReceipt,
	|	ISNULL(WaybillGoods.Package, OrderingProducts.Package) AS Package,
	|	OrderingProducts.Count                                   AS QuantityByOrder,
	|	OrderingProducts.Price                                         AS Price,
	|	OrderingProducts.Sum                                        AS Sum,
	|	OrderingProducts.Products.ItemsType                 AS ItemsType,
	|	OrderingProducts.PartnerProducts                         AS PartnerProducts,
	|	OrderingProducts.Purpose                                   AS Purpose,
	|	OrderingProducts.Ref.VATTaxation                    AS VATTaxation,
	|	CASE
	|		WHEN ISNULL(WaybillGoods.Package, OrderingProducts.Package) = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2)
	|	END AS ZoomRatio,
	|	TableBalance.Count / ISNULL(ISNULL(&QueryTextPackagingFactor1, &QueryTextPackagingFactor2), 1) AS NumberOfPackages,
	|	CASE
	|		WHEN TableBalance.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|				AND TableBalance.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment
	|FROM
	|	TableBalance AS TableBalance
	|		INNER JOIN Document.MaterialProviderOrder2_5.UsedMaterials AS OrderingProducts
	|		ON TableBalance.Products       = OrderingProducts.Products
	|			AND TableBalance.Characteristic  = OrderingProducts.Characteristic
	|			AND TableBalance.RowCode       = OrderingProducts.RowCode
	|			AND TableBalance.PurchaseOrder = OrderingProducts.Ref
	|
	|		LEFT JOIN TTGoodsWaybill AS WaybillGoods
	|		ON TableBalance.Products       = WaybillGoods.Products
	|			AND TableBalance.Characteristic  = WaybillGoods.Characteristic
	|			AND TableBalance.RowCode       = WaybillGoods.RowCode
	|			AND TableBalance.PurchaseOrder = WaybillGoods.PurchaseOrder
	|
	|UNION ALL
	|
	|SELECT
	|	InvoiceGoods.PurchaseOrder              AS PurchaseOrder,
	|	InvoiceGoods.Products                 AS Products,
	|	InvoiceGoods.Characteristic               AS Characteristic,
	|	InvoiceGoods.RowCode                    AS RowCode,
	|	InvoiceGoods.Count                   AS Count,
	|	InvoiceGoods.Warehouse                        AS Warehouse,
	|	ISNULL(InvoiceGoods.Count,0)       AS QuantityInInvoice,
	|	0                                            AS QuantityInOrder,
	|	InvoiceGoods.LineNumber                  AS LineNumber,
	|	InvoiceGoods.SalesOpportunity                       AS SalesOpportunity,
	|	UNDEFINED                                 AS DateOfReceipt,
	|	InvoiceGoods.Package                     AS Package,
	|	0                                            AS QuantityByOrder,
	|	InvoiceGoods.Price                         AS Price,
	|	InvoiceGoods.Sum                        AS Sum,
	|	InvoiceGoods.Products.ItemsType AS ItemsType,
	|	InvoiceGoods.PartnerProducts       AS PartnerProducts,
	|	InvoiceGoods.Purpose                   AS Purpose,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation,
	|	CASE
	|		WHEN InvoiceGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 1
	|		ELSE &QueryTextPackagingFactor3
	|	END AS ZoomRatio,
	|	InvoiceGoods.Count / ISNULL(&QueryTextPackagingFactor3, 1) AS NumberOfPackages,
	|	CASE
	|		WHEN InvoiceGoods.Warehouse.UseWarehouseManagemantSystemForGoodsReceipt = TRUE
	|				AND InvoiceGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= &CurrentDate
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AdvancedWarehousingOnShipment
	|FROM
	|	TTGoodsWaybill AS InvoiceGoods
	|WHERE
	|	InvoiceGoods.RowCode = 0
	|
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
	
	SetPrivilegedMode(True);
	
	Return Query.Execute();
	
EndFunction

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

#EndRegion

#EndIf
#EndIf
