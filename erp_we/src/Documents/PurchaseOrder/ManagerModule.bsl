#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	
EndProcedure

#EndRegion

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
		"Organization", Parameters);

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, DocumentBasis, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Warehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BusinessOperation", Parameters);
	
EndProcedure

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryTextReferences =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Ref.Contract AS Contract,
	|	DocumentData.Warehouse AS Warehouse
	|FROM
	|	Document.PurchaseOrder.Goods AS DocumentData
	|WHERE
	|	DocumentData.Ref IN (&References)
	|	AND DocumentData.Ref.Status IN (
	|		VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
	|		VALUE(Enum.PurchaseOrderStatuses.Closed))
	|	AND NOT DocumentData.Canceled
	|	AND DocumentData.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND &ThisIsOrder_
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Ref.Contract,
	|	DocumentData.Warehouse";
	
	QueryText =
	"SELECT
	|	DeliveryDataSource.Number             AS Number,
	|	DeliveryDataSource.Posted          AS Posted,
	|	DeliveryDataSource.Ref            AS Ref,
	|	DeliveryDataSource.Date              AS Date,
	|	DeliveryDataSource.Partner           AS RecipientSender,
	|	DeliveryDataSource.CarrierPartner AS Carrier,
	|	DeliveryDataSource.DeliveryMethod    AS DeliveryMethod,
	|	DeliveryDataSource.DeliveryZone      AS Zone,
	|
	|	CASE WHEN DeliveryDataSource.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|		THEN DeliveryDataSource.DeliveryAddressOfCarrier
	|		ELSE DeliveryDataSource.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN DeliveryDataSource.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToTransferPoint)
	|		THEN DeliveryDataSource.DeliveryAddressOfCarrierFieldValues
	|		ELSE DeliveryDataSource.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	DeliveryDataSource.DeliveryTimeFrom    AS TimeFrom,
	|	DeliveryDataSource.DeliveryTimeTo   AS TimeTo,
	|	DeliveryDataSource.AdditionalDeliveryInformation
	|	                        AS AdditionalInformation,
	|	References.Warehouse                       AS Warehouse,
	|	TRUE AS DeliverFully,
	|	DeliveryDataSource.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	DeliveryDataSource.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	FALSE AS SplitGoodsIssueNotesByReferences
	|FROM
	|	&TT_Orders AS References
	|		INNER JOIN Document.PurchaseOrder AS DeliveryDataSource
	|		ON DeliveryDataSource.Ref = References.Ref
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

// The function returns the text of the request to receive goods for delivery by order
//
// Returns:
//  String - Query text
//
Function QueryTextGoodsToDeliver() Export
	
	QueryText =
	"SELECT
	|	T.Ref,
	|	T.Warehouse,
	|	T.Products,
	|	T.Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	T.Purpose,
	|	SUM(T.Count) AS Count
	|FROM
	|	Document.PurchaseOrder.Goods AS T
	|WHERE
	|	T.Ref IN(&References)
	|
	|GROUP BY
	|	T.Ref,
	|	T.Warehouse,
	|	T.Products,
	|	T.Characteristic,
	|	T.Purpose";
	
	Return QueryText;
	
EndFunction

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	Documents.VendorInvoice.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
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
	
	If AccessRight("Insert", Metadata.BusinessProcesses.PurchaseApproval) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.BusinessProcesses.PurchaseApproval.FullName();
		CreateBasedOnCommand.Presentation = NStr("vi = 'Thống nhất đơn hàng đặt nhà cung cấp';
												|ru = 'Согласование заказа поставщику';
												|en = 'PO approval'; fa = 'PO approval';
												|it = 'Definizione dell''ordine al fornitore';
												|pl = 'Uzgodnienie zamówień zakupu';
												|tr = 'Satın alma siparişi onayı'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseOrderApproval";
	   
	EndIf;
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	Documents.GoodsReceiptForStorage.AddCreateBasedOnOrderCommand_(GenerationCommands);
	Documents.PackingList.AddGenerateCommand(GenerationCommands);
	Documents.ReceiptOfServicesToBusinessUnit.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	
	
EndProcedure

// Adds a command of creation of the document "Order to supplier".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PurchaseOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PurchaseOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PurchaseOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseOrders";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Adds a command of creation of the document "Order to supplier".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddCreateBasedOnOrdersToSuppliersCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PurchaseOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.GenerationOfPurchaseOrdersByReference";
		CreateBasedOnCommand.Id = "GenerationOfPurchaseOrdersByReference";
		CreateBasedOnCommand.Presentation = NStr("vi = 'Nhiều đơn hàng đặt nhà cung cấp';
												|ru = 'Заказы поставщикам';
												|en = 'Purchase orders'; fa = 'سفارش‌های خرید';
												|it = 'Ordini ai fornitori';
												|pl = 'Zamówienia do dostawcy';
												|tr = 'Satın alma siparişleri'");
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseOrders";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Adds a command of creation of the document "Order to supplier".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateSecuringOrderCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.PurchaseOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PurchaseOrder.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateSecuringOrder";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
			Metadata.Documents.PurchaseOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePurchaseOrders";
		CreationParameters = ProvisionInDocumentsServer.ParametersForCreatingSecuringOrder(
			CreateBasedOnCommand.AdditionalParameters);
		CreationParameters.NameOfDocumentManager = "PurchaseOrder";
		CreationParameters.FormName = "Document.PurchaseOrder.ObjectForm";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
EndFunction

// Creation parameters based on the providing order.
// Returns:
// See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
Function CreationParametersBasedOnProvidingOrder() Export
	
	ProductTableParameters = ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder();
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OwnGoods);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.ReusablePackage);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.Work_5);
	ProductTableParameters.ItemsTypes.Add(Enums.ItemsTypes.OperationService);
	ProductTableParameters.OneWarehouse = True;
	Return ProductTableParameters;
	
EndFunction

#EndRegion

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = Reports.VariancesFromPurchaseConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	Reports.PurchaseApprovalResults.AddDocumentReportCommand(ReportsCommands);
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.Order = 1;
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,DocumentsList";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = Reports.DocumentFulfillmentStatus.AddStateOfExecutionDocumentCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.IndebtednessToSuppliers_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithSupplier_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.VariancesFromPurchaseConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = Reports.AnalysisOfReasonsForPurchaseOrderCancellationAccordingToDocument.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 3;
	EndIf;
	
EndProcedure

// Defines a list of fill commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters
//
Procedure AddFillCommands(FillingCommands, Parameters) Export
	
EndProcedure

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("PurchaseForActivity");
	ArrayOfAllProps.Add("VATTaxation");
	ArrayOfAllProps.Add("ToReturnReusablePackage");
	ArrayOfAllProps.Add("ReusablePackageReturnCycleLength");
	ArrayOfAllProps.Add("PackageDepositIsRequired");
	
	ArrayOfAllProps.Add("Goods.ToExpenseAs");
	ArrayOfAllProps.Add("Goods.ExpenseItem");
	ArrayOfAllProps.Add("Goods.DimensionOfExpenses");
	
	ArrayOfAllProps.Add("Goods.PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("Goods.ManualDiscount");
	ArrayOfAllProps.Add("Goods.Price");
	ArrayOfAllProps.Add("Goods.Sum");
	ArrayOfAllProps.Add("Goods.AmountIncludingVAT");
	ArrayOfAllProps.Add("Goods.VendorPriceKind");
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
	
	ArrayOfOperationDetails = New Array;
	If BusinessTransactionsPurchasingFromSupplier.Find(BusinessOperation) <> Undefined
		Or Not ValueIsFilled(BusinessOperation) Then
		
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("VATTaxation");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackageReturnCycleLength");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.AmountIncludingVAT");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then	
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.AmountIncludingVAT");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then	
		ArrayOfOperationDetails.Add("VATTaxation");
		
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.AmountIncludingVAT");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	ElsIf BusinessTransactionsImportPurchase.Find(BusinessOperation) <> Undefined Then
		
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.AmountIncludingVAT");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(BusinessOperation) <> Undefined Then
		
		ArrayOfOperationDetails.Add("PurchaseForActivity");
		ArrayOfOperationDetails.Add("ToReturnReusablePackage");
		ArrayOfOperationDetails.Add("ReusablePackageReturnCycleLength");
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		ArrayOfOperationDetails.Add("Goods.ExpenseItem");
		ArrayOfOperationDetails.Add("Goods.DimensionOfExpenses");
		
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		
		ArrayOfOperationDetails.Add("Goods.Price");
		ArrayOfOperationDetails.Add("Goods.Sum");
		ArrayOfOperationDetails.Add("Goods.AmountIncludingVAT");
		ArrayOfOperationDetails.Add("Goods.VendorPriceKind");
		
	EndIf;
	
EndProcedure

// This function determines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	SUM(GoodsTable.AmountARAP) AS AmountARAP
	|INTO TableOfOverOrderAmounts
	|FROM
	|	Document.VendorInvoice.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref.Posted
	|	AND GoodsTable.PurchaseOrder = &DocumentRef
	|	AND GoodsTable.RowCode = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DocumentAmount 
	|	+ ISNULL(TableOfOverOrderAmounts.AmountARAP, 0)
	|		AS AmountARAP,
	|	DocumentData.Posted AS Posted
	|FROM
	|	Document.PurchaseOrder AS DocumentData
	|		LEFT JOIN TableOfOverOrderAmounts AS TableOfOverOrderAmounts
	|		ON (TRUE)
	|WHERE
	|	DocumentData.Ref = &DocumentRef");	
	
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
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.PurchaseFromSupplier);
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		Contract = Catalogs.CounterpartyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier;
		DocumentAmount = 0;
		AmountARAP = 0;
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Contract", Contract);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	
	Return AttributesStructure1;

EndFunction

// Generates a verification request when changing the status of the list of documents
//
// Parameters:
//	DocumentsArray - Array - An array of references to documents that should be reviewed
//	NewStatus - String - Name of the new status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Query - Request for verification before changing the status.
//
Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.PurchaseOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl") Then
		
		QueryText = PurchasesServer.RequestTextOrderControlAfterExecution();
		
		QueryText = QueryText + 
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
		|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
		|	PRESENTATION(&Status) AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS StatusMatches,
		|	DocumentsTable.Posted AS Posted,
		|	DocumentsTable.DeletionMark AS DeletionMark,
		|	TRUE AS Recording,
		|	CASE WHEN TTOrderBalances_.PurchaseOrder IS NULL
		|		THEN FALSE
		|			ELSE TRUE
		|	END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.PurchaseOrder AS DocumentsTable
		|LEFT JOIN
		|	TTOrderBalances_
		|ON
		|	DocumentsTable.Ref = TTOrderBalances_.PurchaseOrder
		|WHERE
		|	DocumentsTable.Ref IN (&DocumentsArray)
		|";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref AS Ref,
		|	PRESENTATION(DocumentsTable.Ref)                                                             AS Presentation,
		|	PRESENTATION(DocumentsTable.Status)                                                             AS PresentationOfCurStatus,
		|	PRESENTATION(&Status)                                                                              AS PresentationOfNewStatus,
		|	CASE
		|		WHEN DocumentsTable.Status = &Status
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                                                                AS StatusMatches,
		|	DocumentsTable.Posted                                                                           AS Posted,
		|	DocumentsTable.DeletionMark                                                                    AS DeletionMark,
		|	TRUE                                                                                               AS Recording
		|FROM
		|	Document.PurchaseOrder AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	EndIf;
	MonitorReceipt = GetFunctionalOption("DoNotClosePurchaseOrdersBeforeAllGoodsAreReceived");
	MonitorCalculations     = GetFunctionalOption("DoNotClosePurchaseOrdersWithoutCompletePayment");
	UseStatuses       = GetFunctionalOption("UsePurchaseOrderStatuses");
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("MonitorReceipt", MonitorReceipt);
	Query.SetParameter("MonitorCalculations",     MonitorCalculations);
	Query.SetParameter("UseStatuses",       UseStatuses);
	
	Return Query;
	
EndFunction

// Returns the result of checking when the document status changes
//
// Parameters:
//	ValidationSample - QueryResultSelection - Current selection string
//	NewStatus - EnumRef - New status
//	AdditionalParameters - Structure - Structure of additional parameters.
//
// Returns:
//	Boolean - True, if the verification is completed successfully.
//
Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Cancel = False;
	
	If AdditionalParameters = Undefined Then
		Return Not Cancel;
	EndIf;
	
	If AdditionalParameters.Property("OrderFulfillmentControl")
		And ValidationSample.ThereAreLeftoversOnOrder Then
		
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa đặt trạng thái ""%Status%"" bởi vì đơn hàng cung ứng không đầy đủ';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. заказ поставлен не полностью';
						|en = 'Cannot change the status of %Document% to %Status%. Some items have not been delivered'; fa = 'Cannot change the status of %Document% to %Status%. Some items have not been delivered';
						|it = 'Lo stato ""%Status%"" del documento%Document% non è impostato, poiché l''ordine non è fornito completamente';
						|pl = 'W dokumencie %Document% nie ustawiono statusu ""%Status%"", ponieważ zamówienie wysłano nie w całości';
						|tr = 'Sipariş tam olarak teslim edilmediği için ""%Document%"" belgesinin ""%Status%"" durumu yoktur'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref);
		Cancel = True;
		
	EndIf;
	
	Return Not Cancel;
	
EndFunction

// Defines the access right to add documents of the Order to supplier type
//
// Returns:
// Boolean - The truth if there is a right.
Function AccessRightInsert() Export
	
	Return AccessRight("Insert", Metadata.Documents.PurchaseOrder);
	
EndFunction

#Region CalculationOfStates

// Calculates the current status of the order to the supplier
//
// Parameters:
//	PurchaseOrder         - DocumentRef.PurchaseOrder - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//  CheckTasksToReflectStateOfOrders - Boolean - indicates whether the task has been checked
//	                                                      in the taskreference register for the status of orders.
//
Procedure CalculateStatus(
			Val PurchaseOrder,
			Val Contract,
			StateOfCalculations,
			CheckTasksToReflectStateOfOrders = False) Export
	
	FillPropertyValues(StateOfCalculations, ARAPAccountingClientServer.StructureOfStateOfCalculations(False));
	
	If Not ValueIsFilled(PurchaseOrder) Then
		Return;
	EndIf;

	QueryText =
	"SELECT
	|	TT.Ref AS Ref,
	|	TT.Posted AS Posted,
	|	TT.Status AS Status,
	|	TT.DocumentAmount AS DocumentAmount,
	|	TT.ARAPObjectSettings AS ARAPObjectSettings,
	|	TT.ARAPObject AS ARAPObject
	|INTO TT_DocumentOrderDocument
	|FROM
	|	Document.PurchaseOrder AS TT
	|WHERE
	|	TT.Ref = &PurchaseOrder
	|;
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN (NOT DocumentOrderDocument.Posted)
	|			THEN VALUE(Enum.PurchaseOrderStates.EmptyRef)
	|		ELSE
	|			ISNULL(PurchaseOrderStates.State, VALUE(Enum.PurchaseOrderStates.Closed))
	|	END AS State,
	|	CASE
	|		WHEN (NOT DocumentOrderDocument.Posted)
	|			THEN FALSE
	|		WHEN (DocumentOrderDocument.Status = VALUE(Enum.PurchaseOrderStatuses.Closed) AND &UseStatuses)
	|			THEN FALSE
	|		WHEN PurchaseOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &CurrentDate > PurchaseOrderStates.EventDate 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StateOverdue,
	|	ISNULL(PurchaseOrderStates.PayAmount,0) AS PayAmount,
	|	ISNULL(PurchaseOrderStates.PayPercentage,0) AS PayPercentage,
	|	ISNULL(PurchaseOrderStates.OrderReceiptAmount,0) AS OrderReceiptAmount,
	|	ISNULL(PurchaseOrderStates.PercentageOfOrderReceipt,0) AS PercentageOfOrderReceipt,
	|	ISNULL(PurchaseOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
	|	ISNULL(PurchaseOrderStates.DebtPercentage,0) AS DebtPercentage
	|	,&FieldHasTasksToReflectStateOfOrders
	|FROM
	|	TT_DocumentOrderDocument AS DocumentOrderDocument
	|LEFT JOIN
	|	InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
	|ON
	|	PurchaseOrderStates.OrderDocument = DocumentOrderDocument.Ref
	|WHERE
	|	&CheckTasksToReflectStateOfOrders
	|";
		
	QueryTextHasJobs = "SELECT FALSE AS ThereAreTasksToReflectStateOfOrders";
	If CheckTasksToReflectStateOfOrders Then
		
		QueryText = StrReplace(QueryText,
									",&FieldHasTasksToReflectStateOfOrders",
									",	FALSE AS ThereAreTasksToReflectStateOfOrders");
		
		QueryTextHasJobs = DocumentsStates.QueryTextThereAreTasksToReflectStateOfOrders("&PurchaseOrder");
		
		QueryText = StrReplace(QueryText,
									"&CheckTasksToReflectStateOfOrders",
									StrTemplate("NOT TRUE IN 
											  |		(%1)", QueryTextHasJobs));
	
	Else
		
		QueryText = StrReplace(QueryText, ",&FieldHasTasksToReflectStateOfOrders", "");
		QueryText = StrReplace(QueryText, "&CheckTasksToReflectStateOfOrders", "TRUE");
		
	EndIf;
	
	QueryTextCalculations = "SELECT 0 AS AmountOfDebt, 0 AS AmountToPay";
	If AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		
		QueryTextCalculations = "
		|SELECT // DEBT (+ WE OWE, - WE OWE)
		|	CASE
		|		WHEN
		|			DocumentOrderDocument.Posted AND
		|			((DocumentOrderDocument.Status <> VALUE(Enum.PurchaseOrderStatuses.NotApproved) AND DocumentOrderDocument.DocumentAmount > 0)
		|			OR NOT (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		THEN
		|			CAST (ISNULL(VendorsARAPAccountingBalance.SumBalance, 0) AS NUMBER(31,2))
		|		ELSE
		|			0
		|	END AS AmountOfDebt,
		|	CASE
		|		WHEN
		|			DocumentOrderDocument.Posted
		|			AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		THEN
		|			ISNULL(-VendorsARAPAccountingBalance.AmountDueBalance,0)
		|		ELSE
		|			0
		|	END AS AmountToPay
		|FROM
		|	TT_DocumentOrderDocument AS DocumentOrderDocument
		|LEFT JOIN
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,
		|			ARAPObject IN (SELECT TT.ARAPObject FROM TT_DocumentOrderDocument AS TT)
		|	) AS VendorsARAPAccountingBalance
		|ON
		|	DocumentOrderDocument.ARAPObject = VendorsARAPAccountingBalance.ARAPObject
		|";
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryTexts = New Array;
	QueryTexts.Add(QueryText);
	QueryTexts.Add(QueryTextCalculations);
	QueryTexts.Add(QueryTextHasJobs);
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());

	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("PurchaseOrder", PurchaseOrder);
	Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
	Query.SetParameter("UseStatuses", GetFunctionalOption("UsePurchaseOrderStatuses"));
	
	QueryResults = Query.ExecuteBatch();
	StatesResult = QueryResults[1];
	If Not StatesResult.IsEmpty() Then
		
		StatesSelection = StatesResult.Select();
		If StatesSelection.Next() Then
			FillPropertyValues(StateOfCalculations, StatesSelection);
		EndIf;
	
		SampleCalculations = QueryResults[2].Select();
		If SampleCalculations.Next() Then
			FillPropertyValues(StateOfCalculations, SampleCalculations);
		EndIf;
		
	ElsIf CheckTasksToReflectStateOfOrders Then
	
		SelectionThereAreTasks = QueryResults[3].Select();	
		If SelectionThereAreTasks.Next() Then
			FillPropertyValues(StateOfCalculations, SelectionThereAreTasks);
		EndIf;
		
	EndIf;
	
EndProcedure

// The function returns the text of the query to calculate the order status.
//
// Returns:
//	String - Query text
//
Function RequestTextForCalculatingOrderStates() Export
	
	QueryText = "
		|SELECT
		|	OrdersBalance.PurchaseOrder                        AS PurchaseOrder,
		|	SUM(OrdersBalance.ToRegisterClosingBalance)      AS ToRegisterBalance,
		|	SUM(OrdersBalance.OrderedClosingBalance)         AS OrderedBalance,
		|	SUM(OrdersBalance.OrderedExpense)         AS OrderedExpense
		|	
		|INTO TTOrdersToSuppliersBalance
		|
		|FROM (SELECT
		|		PurchaseOrdersBalance.PurchaseOrder AS PurchaseOrder,
		|		PurchaseOrdersBalance.Products    AS Products,
		|		PurchaseOrdersBalance.Characteristic  AS Characteristic,
		|		PurchaseOrdersBalance.Warehouse           AS Warehouse,
		|		CASE
		|			WHEN PurchaseOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|						WHEN PurchaseOrdersBalance.ToRegisterClosingBalance <= PurchaseOrdersBalance.ToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|							AND PurchaseOrdersBalance.ToRegisterClosingBalance >= -(PurchaseOrdersBalance.ToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|							THEN 0 
		|						ELSE ISNULL(PurchaseOrdersBalance.ToRegisterClosingBalance, 0)
		|					END
		|			ELSE ISNULL(PurchaseOrdersBalance.ToRegisterClosingBalance, 0)
		|		END                                                   AS ToRegisterClosingBalance,
		|	
		|		CASE
		|			WHEN PurchaseOrdersBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|						WHEN PurchaseOrdersBalance.OrderedClosingBalance <= PurchaseOrdersBalance.ToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|							AND PurchaseOrdersBalance.OrderedClosingBalance >= -(PurchaseOrdersBalance.ToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|							THEN 0 
		|						ELSE ISNULL(PurchaseOrdersBalance.OrderedClosingBalance, 0)
		|					END
		|			ELSE ISNULL(PurchaseOrdersBalance.OrderedClosingBalance, 0)
		|		END                                                   AS OrderedClosingBalance,
		|		PurchaseOrdersBalance.OrderedExpense AS OrderedExpense
		|		
		|	FROM AccumulationRegister.PurchaseOrders.BalanceAndTurnovers(,,,,
		|		PurchaseOrder IN (&AnArrayOfOrders)) AS PurchaseOrdersBalance) AS OrdersBalance
		|GROUP BY
		|	OrdersBalance.PurchaseOrder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsBalance.DocumentInflow        AS DocumentInflow,
		|	SUM(GoodsBalance.ToReceiveBalance) AS ToReceiveClosingBalance,
		|	SUM(GoodsBalance.ToReceiveExpense)  AS ToReceiveExpense,
		|	SUM(CASE WHEN GoodsBalance.ToReceiveBalance > 0
		|		OR GoodsBalance.ToRegisterReceiptsByInvoicesClosingBalance > 0 THEN 1 ELSE 0 END) AS ProductNameDiscrepancies,
		|	SUM(GoodsBalance.ToIssueReceiptsForOrdersFinalBalances) <> 0  AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice
		|
		|INTO TTGoodsForReceiptBalances
		|
		|FROM (SELECT
		|		GoodsToReceiveBalance.DocumentInflow AS DocumentInflow,
		|		GoodsToReceiveBalance.Products        AS Products,
		|		GoodsToReceiveBalance.Characteristic      AS Characteristic,
		|		GoodsToReceiveBalance.Warehouse               AS Warehouse,
		|		GoodsToReceiveBalance.Series               AS Series,
		|		CASE
		|			WHEN GoodsToReceiveBalance.Products.UnitOfMeasure.MeasuredValueType IN (&DimensionalTypesOfQuantities)
		|				THEN CASE
		|						WHEN GoodsToReceiveBalance.GoodsReceiptNotesToRegisterClosingBalance <= GoodsToReceiveBalance.GoodsReceiptNotesToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100)
		|							AND GoodsToReceiveBalance.GoodsReceiptNotesToRegisterClosingBalance >= -(GoodsToReceiveBalance.GoodsReceiptNotesToRegisterReceipt
		|								* (&AllowableDeviationOfMeasuringGoodsShipmentAndReceiving / 100))
		|							THEN 0 
		|						ELSE ISNULL(GoodsToReceiveBalance.GoodsReceiptNotesToRegisterClosingBalance, 0)
		|					END
		|			ELSE ISNULL(GoodsToReceiveBalance.GoodsReceiptNotesToRegisterClosingBalance, 0)
		|		END                                         AS ToReceiveBalance,
		|		GoodsToReceiveBalance.GoodsReceiptNotesToRegisterExpense  AS ToReceiveExpense,
		|		GoodsToReceiveBalance.ToRegisterGoodsReceiptsClosingBalance  AS ToIssueReceiptsForOrdersFinalBalances,
		|		GoodsToReceiveBalance.ToRegisterReceiptsByInvoicesClosingBalance AS ToRegisterReceiptsByInvoicesClosingBalance
		|
		|FROM AccumulationRegister.GoodsToReceive.BalanceAndTurnovers(,,,,
		|		DocumentInflow IN (&AnArrayOfOrders)) AS GoodsToReceiveBalance) AS GoodsBalance
		|GROUP BY
		|	GoodsBalance.DocumentInflow
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT 
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentPurchaseOrder.Posted
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.EmptyRef)
		|// APPROVAL IS EXPECTED //////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingApproval)
		|// AN ADVANCE PAYMENT IS EXPECTED BEFORE CONFIRMATION /////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingAdvanceBeforeConfirmation)
		|// CONFIRMATION IS EXPECTED //////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved)
		|		AND ((DocumentPurchaseOrder.DocumentAmount > 0
		|			AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|				OR NOT DocumentPurchaseOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))))
		|			OR DocumentPurchaseOrder.DocumentAmount = 0)
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingConfirmation)
		|// PREPAYMENT IS EXPECTED BEFORE RECEIPT //////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved) OR &NotUsePurchaseOrderStatuses
		|		OR DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_))
		|		AND DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingPrepaymentBeforePurchase)
		|// READY FOR ADMISSION //////////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|		AND DocumentPurchaseOrder.DocumentAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) + ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR NOT DocumentPurchaseOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND ISNULL(PurchaseOrdersBalance.OrderedExpense, 0) = 0
		|		AND ISNULL(GoodsToReceiveBalance.ToReceiveExpense,0) = 0
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.ReadyForReceipt)
		|// EXPECTED RECEIPT //////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses)
		|		AND DocumentPurchaseOrder.DocumentAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) + ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR NOT DocumentPurchaseOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND (ISNULL(PurchaseOrdersBalance.ToRegisterBalance, 0) <> 0
		|		OR ISNULL(GoodsToReceiveBalance.ToReceiveClosingBalance,0) <> 0
		|		OR ISNULL(GoodsToReceiveBalance.ProductNameDiscrepancies,0) <> 0)
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingReceipt)
		|// PAYMENT IS EXPECTED ////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses)
		|		AND DocumentPurchaseOrder.DocumentAmount - DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation - DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt > 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0
		|		AND ISNULL(PurchaseOrdersBalance.ToRegisterBalance, 0) = 0
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.PendingPaymentAfterReceipt)
		|// READY TO CLOSE ////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status <> VALUE(Enum.PurchaseOrderStatuses.Closed) AND &MonitorOrderClosing
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.ReadyForClosure)
		|// unopened //////////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status IN (VALUE(Enum.PurchaseOrderStatuses.Closed),VALUE(Enum.PurchaseOrderStatuses.Confirmed_))
		|	THEN
		|		VALUE(Enum.PurchaseOrderStates.Closed)
		|END AS State,
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentPurchaseOrder.Posted
		|	THEN
		|		DATETIME(1,1,1)
		|// DATE OF APPROVAL ///////////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
		|	THEN
		|		DocumentPurchaseOrder.ApprovalDate
		|// ADVANCE PAYMENT DATE /////////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved) OR &NotUsePurchaseOrderStatuses)
		|		AND DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// DATE OF FIRST RECEIPT ////////////////////////////////////////////////
		|	WHEN
		|		DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved)
		|		AND DocumentPurchaseOrder.DocumentAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR NOT DocumentPurchaseOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|	THEN
		|		DocumentPurchaseOrder.DateOfFirstReceipt
		|// PREPAYMENT DATE /////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses)
		|		AND DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// DATE OF RECEIPT ////////////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|			OR &NotUsePurchaseOrderStatuses)
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) + ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt + DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|			OR NOT DocumentPurchaseOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND ISNULL(PurchaseOrdersBalance.OrderedBalance, 0) <> 0 OR ISNULL(PurchaseOrdersBalance.ToRegisterBalance, 0) <> 0
		|	THEN
		|		
		|		ISNULL(DatesOfReceiptOfOrdersToSuppliers.MinimumReceiptDate, DocumentPurchaseOrder.DateOfFirstReceipt)
		|// PAYMENT DATE AFTER RECEIPT ///////////////////////////////////////////
		|	WHEN
		|		(DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses)
		|		AND DocumentPurchaseOrder.DocumentAmount - DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation - DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt > 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) < 0
		|	THEN
		|		SettlementDates.UpdateDate
		|	ELSE
		|		DATETIME(1,1,1)
		|END AS EventDate,
		|// PAYMENT AMOUNT /////////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentPurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|		THEN ISNULL(MutualSettlementsStatus.PayAmount, 0)
		|	ELSE 0
		|END AS PayAmount,
		|// PERCENTAGE OF PAYMENT ///////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentPurchaseOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|		THEN ISNULL(MutualSettlementsStatus.PayPercentage, 0)
		|	ELSE 0
		|END AS PayPercentage,
		|// RECEIPT AMOUNT ////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentPurchaseOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|		THEN ISNULL(PaidForOrders.ToReceiveExpense, 0)
		|	ELSE ISNULL(MutualSettlementsStatus.OrderReceiptAmount, 0)
		|END AS OrderReceiptAmount,
		|// PERCENTAGE OF RECEIPT //////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentPurchaseOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		|			AND DocumentPurchaseOrder.DocumentAmount > 0
		|		THEN CAST(ISNULL(PaidForOrders.ToReceiveExpense, 0) * 100 / DocumentPurchaseOrder.DocumentAmount AS NUMBER(20, 10))
		|	ELSE ISNULL(MutualSettlementsStatus.PercentageOfOrderReceipt, 0)
		|END AS PercentageOfOrderReceipt,
		|// DEBT (+ WE ARE OWED, - WE MUST)//////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.AmountOfDebt, 0) AS AmountOfDebt,
		|// percentage of debt ////////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.DebtPercentage, 0) AS DebtPercentage,
		|	ISNULL(GoodsToReceiveBalance.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
		|	DocumentPurchaseOrder.Ref AS OrderDocument
		|FROM
		|	Document.PurchaseOrder AS DocumentPurchaseOrder
		|LEFT JOIN
		|	TTStateOfSETTLEMENTS AS MutualSettlementsStatus
		|ON
		|	DocumentPurchaseOrder.Ref = MutualSettlementsStatus.OrderDocument
		|LEFT JOIN
		|	PaidForOrders AS PaidForOrders
		|ON
		|	DocumentPurchaseOrder.Ref = PaidForOrders.PurchaseOrder
		|LEFT JOIN
		|	TTOrdersToSuppliersBalance AS PurchaseOrdersBalance
		|ON
		|	DocumentPurchaseOrder.Ref = PurchaseOrdersBalance.PurchaseOrder
		|LEFT JOIN
		|	TTGoodsForReceiptBalances AS GoodsToReceiveBalance
		|ON
		|	DocumentPurchaseOrder.Ref = GoodsToReceiveBalance.DocumentInflow
		|LEFT JOIN
		|	DatesWhenOrdersToSuppliersAreUpToDate AS SettlementDates
		|ON
		|	DocumentPurchaseOrder.ARAPObject = SettlementDates.ARAPObject
		|LEFT JOIN
		|	DatesOfReceiptOfOrdersToSuppliers AS DatesOfReceiptOfOrdersToSuppliers
		|ON
		|	DocumentPurchaseOrder.Ref = DatesOfReceiptOfOrdersToSuppliers.PurchaseOrder
		|WHERE
		|	DocumentPurchaseOrder.Ref IN (&AnArrayOfOrders)
		|
		|";
	Return QueryText;
	
EndFunction

#EndRegion

// Initializes the status structure of the document
//
// Returns:
//  Structure - a structure with the necessary fields.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithSuppliersTable", 1);
	StructureState.Insert("DisplayOrderedTable_", 2);
	StructureState.Insert("DisplayReceiptTables", 3);
	StructureState.Insert("DisplayTablesCanceledReceipt", 4);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("ThereAreSummaryIndicatorsOfReceipt", True);
	StructureState.Insert("ThereAreReasonsForCancelingAdmission", GetFunctionalOption("UseReasonsForPurchaseOrderCancellations"));
	
	Return StructureState
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
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
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Delete(AppointmentTemplateWithoutAgencyPurchase.AssignmentTypes.Find(Enums.AssignmentTypes.DeliveryForPrincipal));
	
	AppointmentTemplateWithoutAgencyPurchase.TermsOfUse_ = "Object.BusinessOperation <> VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)";
	
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Goods.Warehouse";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "ReferenceOrder";
	
	// The needs for work in the recipient department.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Goods.Department";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	DescriptionOfColumns.DataPaths.ReferenceOrder     = "ReferenceOrder";
	
	Return FormTemplate;
	
EndFunction

// Defines a list of business operations that can be specified in documents of the "order to supplier" type.
//
//  Parameters:
//   CheckFunctionalOptions - Boolean - True if you want to get only operations
//                                           that can be specified in the document with the current values
//                                           of functional options. False if you need to get all document operations
//                                           of this type.
//  Returns:
//   Array - Array - An array of values of the enumeration type of the link.Economic operations.
Function BusinessOperationsOfDocument(CheckFunctionalOptions) Export
	
	UsePurchaseCommission       = True;
	UseGoodsInTransitFromVendors  = True;
	UseImports          = True;
	UseImportOfGoodsFromCustomsUnion = True;
	UseUninvoicedDeliveries = True;
	UseCustodyDuringPurchase = False;
	UseCustodyDuringPurchase = True;
	
	If CheckFunctionalOptions Then
		
		UsePurchaseCommission       = GetFunctionalOption("UsePurchaseCommission");
		UseGoodsInTransitFromVendors  = GetFunctionalOption("UseGoodsInTransitFromVendors");
		UseImports          = GetFunctionalOption("UseImports");
		UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
		UseUninvoicedDeliveries     = GetFunctionalOption("UseUninvoicedDeliveries");
		UseCustodyDuringPurchase = False;
		UseCustodyDuringPurchase = GetFunctionalOption(
			"UseCustodyDuringPurchase");
		
	EndIf;
	
	Operations = New Array();
	
	Operations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	If UseGoodsInTransitFromVendors Then
		Operations.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	EndIf;
	If UseUninvoicedDeliveries Then
		Operations.Add(Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt);
	EndIf;
	
	If UseImports Then
		Operations.Add(Enums.BusinessTransactions.PurchaseByImport);
	EndIf;
	If UseImports
		And UseGoodsInTransitFromVendors Then
		Operations.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	EndIf;
	
	If UseImportOfGoodsFromCustomsUnion Then
		Operations.Add(Enums.BusinessTransactions.ImportFromEAEU);
	EndIf;
	If UseImportOfGoodsFromCustomsUnion
		And UseGoodsInTransitFromVendors Then
		Operations.Add(Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit);
	EndIf;
	If UseImportOfGoodsFromCustomsUnion
		And UseUninvoicedDeliveries Then
		Operations.Add(Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery);
	EndIf;
	
	If UsePurchaseCommission Then
		Operations.Add(Enums.BusinessTransactions.ConsignmentProcurement);
	EndIf;
	
	If UseCustodyDuringPurchase Then
		Operations.Add(Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale);
	EndIf;
	
	Return Operations;
	
EndFunction

// Returns the structure of parameters for filling in the purchase VAT tax.
//
// Parameters:
//  Object - DocumentObject.PurchaseOrder - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases
//
Function ParametersForFillingInVATTaxationPurchases(Object) Export

	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	
	FillParameters.Counterparty = Object.Counterparty;
	FillParameters.Contract = Object.Contract;
	FillParameters.Period =  Object.Date; 
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
		
	If BusinessTransactionsPurchasingFromSupplier.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
		
	ElsIf BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.ImportOfGoods = True;
		
	ElsIf  Object.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale Then
		
		FillParameters.VMIProcurement = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement Then
		
		FillParameters.ConsignmentProcurement = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns the structure of parameters for filling in the VAT date type.
//
// Parameters:
//  Object - DocumentObject.PurchaseOrder - 
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
		
	If BusinessTransactionsPurchasingFromSupplier.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		FillParameters.AcquisitionOfWorks = True;
		FillParameters.PurchaseOnArticles = True;
		
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(Object.BusinessOperation) <> Undefined
		Or BusinessTransactionsImportPurchase.Find(Object.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		
	EndIf;
	
	Return FillParameters;

EndFunction

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
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation");
		BusinessOperation = StructureFillingData.BusinessOperation;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsOrder                         = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;

	ParametersStructure.ChangesPaymentPlan               = BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
															Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromSupplier
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt
															Or BusinessOperation = Enums.BusinessTransactions.PurchaseByImport
															Or BusinessOperation = Enums.BusinessTransactions.ImportGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEU
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUGoodsInTransit
															Or BusinessOperation = Enums.BusinessTransactions.ImportFromEAEUInvoicedDelivery;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.ApprovalDate                 = "Object.ApprovalDate";
	
	ParametersStructure.DateOfShipment                     = "Object.Goods.DateOfShipment";
	ParametersStructure.DateOfReceipt                  = "Object.Goods.DateOfReceipt";
	ParametersStructure.ShipInOneDay              = "Object.OneDateReceipt";
	
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	
	ParametersStructure.DocumentAmountForm              = "Form.AmountOrderedWithADepositContainer";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.FormItems.InscriptionCalculations     = "DecorationSettlementState";
	ParametersStructure.FormItems.PaymentSettlement        = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	ParametersStructure.IncomingDocumentNumber          = "Object.VendorReferenceNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.VendorReferenceDate";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.ToReturnReusablePackage        = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired             = "Object.PackageDepositIsRequired";
	
	ParametersStructure.OperationWithSelfEmployedPerson             = "Object.OperationWithSelfEmployedPerson";
	ParametersStructure.TSP                              = "Object.Warehouse";
	
	Return ParametersStructure;
	
EndFunction

// Document parameters for the mechanism of filling in the Attributes of the controlled party in the document.
// 
// Parameters:
//  ObjectOrRef - DocumentObject.PurchaseOrder, DocumentRef.PurchaseOrder - Document.
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
		|Number,
		|BusinessOperation,
		|LineOfBusiness,
		|Counterparty,
		|Organization,
		|Department");
		
	Attributes.Lot = ObjectAttributes.Ref;
	Attributes.Contract = ObjectAttributes.Contract;
	Attributes.Partner = ObjectAttributes.Partner;
	Attributes.LineOfBusiness = ObjectAttributes.LineOfBusiness;
	Attributes.Counterparty = ObjectAttributes.Counterparty;
	Attributes.ReasonForGoodsLock = Catalogs.GoodsLockReasons.InputQualityControlOfGoods;
	Attributes.ReceiptDocumentNumber = ObjectAttributes.Number;
	Attributes.DateOfReceiptDocument = ObjectAttributes.Date;
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
//  Object - DocumentObject.PurchaseOrder - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInCheckQualityDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ContractRequired = QualityControl.ControlMayBeDeterminedByContract(Object.BusinessOperation);
	
	ActionName = "FillInCheckQualityDateOfQualityConfirmation";
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.ReadableFields = "Products,Warehouse,DateOfReceipt,Canceled,ToExpenseAs";
	ActionParameters.EditableFields = "ToControlQuality,QualityConfirmationDate";
	ActionParameters.KeyDetailsOfHeader.Insert("Warehouse", Object.Warehouse);
	ActionParameters.QueryOptions.QualityControlContract = ?(ContractRequired, Object.Contract, Undefined);
	ActionParameters.QueryOptions.QualityControlDateOfReceipt = Object.DateOfReceipt;
	ActionParameters.QueryOptions.Insert("QualityControlAdmissionByOneDate", Object.OneDateReceipt);
	ActionParameters.KeyDetailsOfHeader.Insert("DeliveryDuration", Object.DeliveryDuration);
	ActionParameters.QueryTextDocumentData =
		"SELECT
		|	Table.IdOfTTRow AS IdOfTTRow,
		|	Table.Products AS Products,
		|	Table.Warehouse AS Warehouse,
		|	&QualityControlContract AS Contract,
		|	CASE
		|		WHEN &QualityControlAdmissionByOneDate
		|			THEN &QualityControlDateOfReceipt
		|		ELSE Table.DateOfReceipt
		|	END AS DateOfReceipt,
		|	FALSE AS Set,
		|	Table.Canceled OR Table.ToExpenseAs AS Reset
		|INTO DataOfDocumentToBeFilledInCheckQualityDateOfQualityConfirmation
		|FROM
		|	#DataSource AS Table
		|INDEX BY
		|	Products,Warehouse,Contract";
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
EndFunction

// Fills in the delivery address of the warehouse.
//
// Parameters:
// 	DeliveryAddressForVendor - String - delivery address;
// 	AvailableWarehouses - Array of CatalogRef.Warehouses - Document Warehouses;
// 	DateOfTransferFrom - Date - the start date of the address.
//
Procedure FillInDeliveryAddressForSupplier(DeliveryAddressForVendor, AvailableWarehouses, Val DateOfTransferFrom = Undefined) Export
	
	AddressSelectionList = WarehouseAddresses(AvailableWarehouses, DateOfTransferFrom);
	
	If AddressSelectionList.Count() = 1 Then
		DeliveryAddressForVendor = AddressSelectionList[0].Value;
	EndIf;
	
EndProcedure

// Gets a list of warehouse addresses for the document.
//
// Parameters:
// 	AvailableWarehouses - Array of CatalogRef.Warehouses - Document Warehouses;
// 	DateOfTransferFrom - Date - the start date of the address.
//
// Returns:
//	ValueList of String - Delivery address data.
//
Function WarehouseAddresses(AvailableWarehouses, Val DateOfTransferFrom = Undefined) Export
	
	AddressSelectionList = New ValueList;
	DateOfTransferFrom = ?(ValueIsFilled(DateOfTransferFrom), DateOfTransferFrom, CurrentSessionDate());
	
	ContactInformationTypes= New Array;
	ContactInformationTypes.Add(Enums.ContactInformationTypes.Address);
	
	If AvailableWarehouses.Count() > 0 Then
		WarehouseAddresses = ContactsManager.ObjectsContactInformation(AvailableWarehouses,
																					ContactInformationTypes,
																					Undefined,
																					DateOfTransferFrom);
		For Each Address In WarehouseAddresses Do
			
			If ValueIsFilled(Address.Presentation)
				And AddressSelectionList.FindByValue(Address.Presentation) = Undefined Then
				
				AddressSelectionList.Add(Address.Presentation, String(Address.Kind) + ": " + Address.Presentation);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return AddressSelectionList;
	
EndFunction

#Region WorkingWithDates

// Returns a date that differs from the specified start date by the number of business days
// included in the main calendar of the enterprise.
//
// Parameters:
// StartDate - Date - the date from which to calculate the number of days.
// DaysCount - Number - the number of days to increase the start date by.
//
// Returns:
//   Date - the date increased by the number of working days according to the main calendar of the enterprise.
//          If the calendar is not full, the date is increased by the number of calendar days.
//
Function DateAccordingToCompanyCalendar(StartDate, DaysCount) Export
	
	Texts = New Array();
	
	Text = ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule();
	Texts.Add(Text);
	
	Text =
	"SELECT
	|	&StartDate AS StartDate,
	|	&DaysCount AS DaysCount
	|INTO TTFillData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalculationOfDeliveryDateOverridable.DateFound AS DateByCalendar
	|FROM
	|	TTFillData AS Table
	|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE";
	
	Substitutions = ProvisionInDocumentsServer.AddToDateAccordingToEnterpriseCalendar(
		"Table.StartDate", "Table.DaysCount");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.DateFound", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Query = New Query;
	Query.SetParameter("StartDate", BegOfDay(StartDate));
	Query.SetParameter("DaysCount", DaysCount);
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	Selection = Query.Execute().Select();
	Selection.Next();
	
	DateByCalendar = Selection.DateByCalendar;
	If Not ValueIsFilled(DateByCalendar) Then
		DateByCalendar = TMCommonUseClientServer.CalculatePeriodEndDate(
			StartDate, Enums.Periodicity.Day, DaysCount) + 1;
	EndIf;
	
	Return DateByCalendar;
	
EndFunction

// Determines the date of the next day included in the schedule.
//
// Parameters:
//  StartDate - Date - the date for which you need to find the nearest one.
//  Calendar  - CatalogRef.Calendars
//             - CatalogRef.BusinessCalendars - the schedule or 
//               production calendar to be used for the calculation.
// 
// Returns:
//  Date - the nearest date included in the schedule.
//
Function NearestWorkingDate(StartDate, Calendar = Undefined) Export
	
	If Calendar = Undefined Then
		Calendar = Constants.MainEnterpriseCalendar.Get();
	EndIf;
	
	If Not ValueIsFilled(Calendar) Then
		Return StartDate;
	EndIf;
	
	InitialDates = CommonClientServer.ValueInArray(StartDate);
	DatesByCalendar = Undefined;
	
	If TypeOf(Calendar) <> Type("CatalogRef.BusinessCalendars") Then
		
		If Common.SubsystemExists("StandardSubsystems.WorkSchedules") Then
			ModuleWorkSchedules = Common.CommonModule("WorkSchedules");
			ReceivingParameters = ModuleWorkSchedules.NearestDatesByScheduleReceivingParameters();
			ReceivingParameters.RaiseException1 = False;
			DatesByCalendar = ModuleWorkSchedules.NearestDatesIncludedInSchedule(
				Calendar, InitialDates, ReceivingParameters);
		EndIf;
		
	Else
	
		ReceivingParameters = CalendarSchedules.NearestWorkDatesReceivingParameters();
		ReceivingParameters.ConsiderNonWorkPeriods = False;
		ReceivingParameters.RaiseException1 = False;
		DatesByCalendar = CalendarSchedules.NearestWorkDates(Calendar, InitialDates, ReceivingParameters);
		
	EndIf;
	
	If DatesByCalendar = Undefined Then
		Return StartDate;
	EndIf;
	
	DateByCalendar = DatesByCalendar.Get(StartDate);
	If DateByCalendar = Undefined Then
		DateByCalendar = StartDate;
	EndIf;
	
	Return DateByCalendar;
	
EndFunction

// Determines the date of shipment by the date of receipt and the duration of delivery by the number of days included in the calendar.
//
// Parameters:
//  OrderDate - Date - the minimum date allowed for shipment.
//  DateOfReceipt - Date - the date from which you need to calculate the date of shipment.
//  DeliveryDuration - Number - the number of days to reduce the date of receipt.
//  Calendar - CatalogRef.Calendars
//            - CatalogRef.BusinessCalendars - the schedule or 
//              production calendar to be used for the calculation.
//
// Returns:
//   Date
//
Function DateOfShipmentByCalendar(OrderDate, DateOfReceipt, DeliveryDuration, Calendar = Undefined) Export
	
	If Calendar = Undefined Then
		Calendar = Constants.MainEnterpriseCalendar.Get();
	EndIf;
	
	MinimumShipmentDate = NearestWorkingDate(OrderDate, Calendar);
	If ValueIsFilled(DateOfReceipt) Then
		DateOfShipment = DateAccordingToCompanyCalendar(DateOfReceipt, -DeliveryDuration);
	Else
		DateOfShipment = NearestWorkingDate(CurrentSessionDate(), Calendar);
	EndIf;
	
	Return Max(MinimumShipmentDate, DateOfShipment);
	
EndFunction

// Determines the duration of delivery in days according to the calendar.
//
// Parameters:
//  StartDate - Date - start date of the delivery period.
//  EndDate - Date - the end date of the delivery period.
//  Calendar - CatalogRef.Calendars
//            - CatalogRef.BusinessCalendars - the schedule or 
//              production calendar to be used for the calculation.
//
// Returns:
//   Number
//
Function DeliveryTimeByCalendar(StartDate, EndDate, Calendar = Undefined) Export
	
	If EndDate <= StartDate Then
		Return 0;
	EndIf;
	
	If Calendar = Undefined Then
		Calendar = Constants.MainEnterpriseCalendar.Get();
	EndIf;
	
	DeliveryDuration = CalendarSchedules.DateDiffByCalendar(Calendar, StartDate, EndDate, False);
	If ValueIsFilled(DeliveryDuration) Then
		DeliveryDuration = Max(DeliveryDuration - 1, 1);
	Else
		DayDuration = 86400;
		DeliveryDuration = (EndDate - StartDate) / DayDuration;
	EndIf;
	
	Return DeliveryDuration;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Allows you to specify metadata objects for which the logic of restricting access to data is set.
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Warehouse)
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

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ListForm" Then
		If Not AccessRight("Read", Metadata.InformationRegisters.PurchaseOrderStates)
			Or Not AccessRight("Read", Metadata.InformationRegisters.StatesByEDIAccountingObjects) Then
			StandardProcessing = False;
			SelectedForm = "ListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.PurchaseOrder, DocumentRef.PurchaseOrder - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;

	If TypeOf(Document) = Type("DocumentObject.PurchaseOrder") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
	ElsIf Document = Undefined Then
		DocumentObject = Undefined;
		DocumentRef = EmptyRef();
	Else
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
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	PurchaseOrder.Date                         AS Period,
	|	PurchaseOrder.DocumentBasis            AS DocumentBasis,
	|	PurchaseOrder.Currency                       AS Currency,
	|	PurchaseOrder.AgreementCurrency             AS AgreementCurrency,
	|	PurchaseOrder.PriceIncludesVAT              AS PriceIncludesVAT,
	|	PurchaseOrder.PriceIncludesVATTerms    AS PriceIncludesVATTerms,
	|	PurchaseOrder.Status                       AS Status,
	|	PurchaseOrder.Partner                      AS Partner,
	|	PurchaseOrder.Counterparty                   AS Counterparty,
	|	PurchaseOrder.Organization                  AS Organization,
	|	PurchaseOrder.BusinessOperation        AS BusinessOperation,
	|	PurchaseOrder.Terms                   AS Terms,
	|	PurchaseOrder.RegisterVendorPrices AS RegisterVendorPrices,
	|	PurchaseOrder.GoodsReceiptOption        AS GoodsReceiptOption,
	|	PurchaseOrder.Contract                      AS Contract,
	|	PurchaseOrder.ContractPresentation         AS ContractPresentation,
	|	PurchaseOrder.ToReturnReusablePackage    AS ToReturnReusablePackage,
	|	PurchaseOrder.PackageDepositIsRequired         AS PackageDepositIsRequired,
	|	PurchaseOrder.LineOfBusiness      AS LineOfBusiness,
	|	PurchaseOrder.Warehouse                        AS Warehouse,
	|	PurchaseOrder.Number                        AS Number,
	|	PurchaseOrder.Manager                     AS Manager,
	|	PurchaseOrder.Author                        AS Author,
	|	PurchaseOrder.Comment                  AS Comment,
	|	PurchaseOrder.DocumentAmount               AS DocumentAmount,
	|	PurchaseOrder.Posted                     AS Posted,
	|	PurchaseOrder.DeletionMark              AS DeletionMark,
	|	PurchaseOrder.VendorReferenceDate       AS VendorReferenceDate,
	|	PurchaseOrder.VendorReferenceNumber      AS VendorReferenceNumber,
	|	PurchaseOrder.Department                AS Department,
	|	PurchaseOrder.Priority                    AS Priority
	|
	|FROM	DocumentDataHeader AS PurchaseOrder";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	DocumentsPosting.SetQueryParametersBySelection(Query, Attributes, "ContractPresentation");
	
	Query.SetParameter("PurchaseRequest", Documents.PurchaseRequest.ApplicationForBasisOfPurchaseOrderToSupplier(DocumentRef));
	Query.SetParameter("PurchaseOrder", DocumentRef);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(TypeOf(DocumentRef)));
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.ContractPresentation);
	EndIf;
	Query.SetParameter("ContractInformation",  ContractInformation);
	
EndProcedure

Procedure GetDocumentData(Query, DocumentRef)

	ListOfRequests = New Array;

	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDocumentDataTableItems(ListOfRequests);
	QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryTextHeader = 
	"SELECT
	|	HeaderData_.Ref                       AS Ref,
	|	HeaderData_.DocumentBasis            AS DocumentBasis,
	|	HeaderData_.Date                         AS Date,
	|	HeaderData_.Currency                       AS Currency,
	|	HeaderData_.Terms.Currency            AS AgreementCurrency,
	|	HeaderData_.PriceIncludesVAT              AS PriceIncludesVAT,
	|	ISNULL(HeaderData_.Terms.PriceIncludesVAT, FALSE) AS PriceIncludesVATTerms,
	|	HeaderData_.Status                       AS Status,
	|	HeaderData_.Partner                      AS Partner,
	|	HeaderData_.Counterparty                   AS Counterparty,
	|	HeaderData_.Organization                  AS Organization,
	|	HeaderData_.BusinessOperation        AS BusinessOperation,
	|	HeaderData_.Terms                   AS Terms,
	|	HeaderData_.RegisterVendorPrices AS RegisterVendorPrices,
	|	HeaderData_.GoodsReceiptOption        AS GoodsReceiptOption,
	|	HeaderData_.ServiceReceiptOption          AS ServiceReceiptOption,
	|	HeaderData_.Contract                      AS Contract,
	|	PRESENTATION(HeaderData_.Contract)       AS ContractPresentation,
	|	HeaderData_.ToReturnReusablePackage    AS ToReturnReusablePackage,
	|	HeaderData_.PackageDepositIsRequired         AS PackageDepositIsRequired,
	|	HeaderData_.LineOfBusiness      AS LineOfBusiness,
	|	HeaderData_.Warehouse                        AS Warehouse,
	|	HeaderData_.Number                        AS Number,
	|	HeaderData_.Manager                     AS Manager,
	|	HeaderData_.Author                        AS Author,
	|	HeaderData_.Comment                  AS Comment,
	|	HeaderData_.DocumentAmount               AS DocumentAmount,
	|	HeaderData_.Posted                     AS Posted,
	|	HeaderData_.DeletionMark              AS DeletionMark,
	|	HeaderData_.VendorReferenceDate       AS VendorReferenceDate,
	|	HeaderData_.VendorReferenceNumber      AS VendorReferenceNumber,
	|	HeaderData_.Department                AS Department,
	|	HeaderData_.Priority                    AS Priority,
	|	HeaderData_.ARAPObject               AS ARAPObject,
	|	HeaderData_.Contract.PurchaseRegistrationOption AS ContractPurchasingOption,
	|	HeaderData_.Contract.OptionForRegisteringServiceReceiptDocuments AS ContractIsVariantOfRegistrationOfDocumentsForAdmissionToServices,
	|	HeaderData_.ARAPObjectSettings              AS ARAPObjectSettings,
	|	HeaderData_.PaymentMethod                  AS PaymentMethod
	|INTO DocumentDataHeader
	|FROM
	|	Document.PurchaseOrder AS HeaderData_
	|WHERE
	|	HeaderData_.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextHeader);
	
EndProcedure

Procedure QueryTextDocumentDataTableItems(ListOfRequests)
	
	QueryTextTableGoods = "SELECT
	|	GoodsTable.LineNumber               AS LineNumber,
	|	GoodsTable.Ref                    AS Ref,
	|	GoodsTable.PartnerProducts      AS PartnerProducts,
	|	GoodsTable.Products              AS Products,
	|	GoodsTable.Characteristic            AS Characteristic,
	|	GoodsTable.Package                  AS Package,
	|	GoodsTable.NumberOfPackages        AS NumberOfPackages,
	|	GoodsTable.Count                AS Count,
	|	GoodsTable.DateOfReceipt           AS DateOfReceipt,
	|	GoodsTable.VendorPriceKind         AS VendorPriceKind,
	|	GoodsTable.Price                      AS Price,
	|	GoodsTable.Sum                     AS Sum,
	|	GoodsTable.PercentRateOfManualDiscount       AS PercentRateOfManualDiscount,
	|	GoodsTable.ManualDiscount         AS ManualDiscount,
	|	GoodsTable.VATRate                 AS VATRate,
	|	GoodsTable.VATAmount                  AS VATAmount,
	|	GoodsTable.AmountIncludingVAT                 AS AmountIncludingVAT,
	|	GoodsTable.RowCode                 AS RowCode,
	|	GoodsTable.Canceled                  AS Canceled,
	|	GoodsTable.ExpenseItem            AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses         AS DimensionOfExpenses,
	|	GoodsTable.CancellationReason             AS CancellationReason,
	|	GoodsTable.Warehouse                     AS Warehouse,
	|	GoodsTable.Purpose                AS Purpose,
	|	GoodsTable.Department             AS Department,
	|	GoodsTable.ToExpenseAs          AS ToExpenseAs,
	|	GoodsTable.RowID       AS RowID,
	|	GoodsTable.ToControlQuality AS ToControlQuality,
	|	GoodsTable.DateOfShipment              AS DateOfShipment,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts
	|
	|INTO DocumentDataTableItems
	|FROM
	|	Document.PurchaseOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests)

	QueryTextTablePaymentScheduleSteps = "SELECT
	|	TableStagesOfPaymentSchedule.LineNumber         AS LineNumber,
	|	TableStagesOfPaymentSchedule.Ref              AS Ref,
	|	TableStagesOfPaymentSchedule.PaymentOption       AS PaymentOption,
	|	TableStagesOfPaymentSchedule.PaymentDate         AS PaymentDate,
	|	TableStagesOfPaymentSchedule.DateOfShipment        AS DateOfShipment,
	|	TableStagesOfPaymentSchedule.PaymentPercentage      AS PaymentPercentage,
	|	TableStagesOfPaymentSchedule.PaymentAmount        AS PaymentAmount,
	|	TableStagesOfPaymentSchedule.PackageDepositPercentage AS PackageDepositPercentage,
	|	TableStagesOfPaymentSchedule.PackageDepositValue   AS PackageDepositValue,
	|	TableStagesOfPaymentSchedule.Move               AS Move,
	|	TableStagesOfPaymentSchedule.CalculateFrom      AS CalculateFrom
	|INTO DocumentDataTableStagesOfPaymentSchedule
	|FROM
	|	Document.PurchaseOrder.PaymentScheduleSteps AS TableStagesOfPaymentSchedule
	|WHERE
	|	TableStagesOfPaymentSchedule.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTablePaymentScheduleSteps);

EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined, DocumentObject = Undefined) Export
	

	QueryTextdata_ = 
	"SELECT
	|	""Goods"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DATETIME(1,1,1) AS VATBasePeriod,
	|	DocumentData.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation IN (
	|					VALUE(Enum.BusinessTransactions.ConsignmentProcurement),
	|					VALUE(Enum.BusinessTransactions.ReceivingForStorageWithRightOfSale))
	|			THEN FALSE
	|		WHEN DocumentTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentData.ToReturnReusablePackage
	|			AND NOT DocumentData.PackageDepositIsRequired
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	DocumentDataTableItems  AS DocumentTable
	|		LEFT JOIN DocumentDataHeader AS DocumentData
	|			ON DocumentTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Canceled
	|"; 
		
	If DocumentObject = Undefined Then
		
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableItems", "Document.PurchaseOrder.Goods");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.PurchaseOrder");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentTable.ProductsTypeOfProducts", "DocumentTable.Products.ItemsType");
		
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTablePurchaseOrders(Query, QueryTexts, Registers, DocumentObject = Undefined)
	RegisterName = "PurchaseOrders";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber                                         AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	&Period                                                           AS Period,
	|	GoodsTable.Ref                                              AS PurchaseOrder,
	|	GoodsTable.Products                                        AS Products,
	|	GoodsTable.Characteristic                                      AS Characteristic,
	|	GoodsTable.RowCode                                           AS RowCode,
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE UNDEFINED
	|	END                                                             AS Warehouse,
	|	CASE WHEN  (NOT GoodsTable.Canceled)
	|			AND &Status IN (VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
	|						VALUE(Enum.PurchaseOrderStatuses.Closed)) THEN
	|			GoodsTable.Count
	|		ELSE 0
	|	END                                                             AS ToRegister,
	|	GoodsTable.Count                                          AS Ordered,
	|	UNDEFINED                                                      AS CancellationReason
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber                                         AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	&Period                                                           AS Period,
	|	GoodsTable.Ref                                              AS PurchaseOrder,
	|	GoodsTable.Products                                        AS Products,
	|	GoodsTable.Characteristic                                      AS Characteristic,
	|	GoodsTable.RowCode                                           AS RowCode,
	|	CASE WHEN GoodsTable.ProductsTypeOfProducts IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage)) THEN
	|			GoodsTable.Warehouse
	|		ELSE UNDEFINED
	|	END                                                             AS Warehouse,
	|	0                                                                 AS ToRegister,
	|	-GoodsTable.Count                                         AS Ordered,
	|	GoodsTable.CancellationReason                                       AS CancellationReason
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Canceled
	|";
	
	If DocumentObject = Undefined Then
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.PurchaseOrder.Goods");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers, DocumentObject)
	
	If DocumentObject <> Undefined
		And Not (DocumentObject.Status = Enums.PurchaseOrderStatuses.Confirmed_
			Or DocumentObject.Status = Enums.PurchaseOrderStatuses.Closed) Then
		Return;
	EndIf;
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref                        AS Ref,
	|	UNDEFINED                                 AS Invoice,
	|	FALSE                                         AS Patch,
	|	UNDEFINED                                 AS CorrectedDocument,
	|	DataSource.Ref                        AS OrderDocument,
	|	DocumentHeader.Contract                       AS Contract,
	|	DocumentHeader.Terms                    AS Terms,
	|	DocumentHeader.GoodsReceiptOption         AS GoodsReceiptOption,
	|	DocumentHeader.ServiceReceiptOption           AS ServiceReceiptOption,
	|	DataSource.DateOfReceipt               AS Date,
	|	DataSource.Products                  AS Products,
	|	DataSource.Characteristic                AS Characteristic,
	|	DataSource.Purpose                    AS Purpose,
	|	DataSource.ToControlQuality     AS ToControlQuality,
	|	FALSE                                         AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                                 AS ControlledLotReference,
	|	0                                            AS BatchesIndicationStatus,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	FALSE                                         AS ExceedingOrder,
	|	DataSource.Warehouse                         AS Warehouse,
	|	DocumentHeader.Partner                       AS Sender,
	|	DocumentHeader.BusinessOperation         AS BusinessOperation,
	|	DataSource.Count                    AS Count,
	|	FALSE                                         AS ThisIsAnInvoice,
	|	FALSE                                         AS ReceiptUnderOrders
	|FROM
	|	DocumentDataTableItems AS DataSource
	|		LEFT JOIN DocumentDataHeader AS DocumentHeader
	|		ON DataSource.Ref = DocumentHeader.Ref
	|WHERE
	|	((NOT DataSource.ToExpenseAs
	|   	AND NOT (DataSource.Products.ItemsType IN
	|			(VALUE(Enum.ItemsTypes.OperationService),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|			AND DocumentHeader.ContractIsVariantOfRegistrationOfDocumentsForAdmissionToServices = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed)))
	|		OR (CAST(DataSource.Products AS Catalog.Products).ItemsType IN(
	|				VALUE(Enum.ItemsTypes.OperationService),
	|				VALUE(Enum.ItemsTypes.Work_5))
	|			AND DocumentHeader.ContractIsVariantOfRegistrationOfDocumentsForAdmissionToServices = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsInvoiced)
	|			AND DocumentHeader.BusinessOperation IN(
	|				VALUE(Enum.BusinessTransactions.PurchaseFromVendorCreatingInvoicesOnGoodsReceipt),
	|				VALUE(Enum.BusinessTransactions.ImportFromEAEUInvoicedDelivery))))
	|	AND NOT DataSource.Canceled";
	
	If DocumentObject = Undefined Then
		QueryTextDocument_ = StrReplace(QueryTextDocument_, "DocumentDataTableItems", "Document.PurchaseOrder.Goods");
		QueryTextDocument_ = StrReplace(QueryTextDocument_, "DocumentDataHeader", "Document.PurchaseOrder");
		QueryTextDocument_ = StrReplace(QueryTextDocument_, "DocumentHeader.ContractPurchasingOption", "DocumentHeader.Contract.PurchaseRegistrationOption");
		QueryTextDocument_ = StrReplace(QueryTextDocument_, "DocumentHeader.ContractIsVariantOfRegistrationOfDocumentsForAdmissionToServices", "DocumentHeader.Contract.OptionForRegisteringServiceReceiptDocuments");
	EndIf;
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_,, True);
	
EndProcedure

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency IN (SELECT
	|				DefaultBaseCurrency.Value AS Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS
	|		RelativeExchangeRatesSliceLast
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableOfGoods_(Query, QueryTexts)
	
	RegisterName = "TemporaryTableOfGoods_";
	
	QueryText = "
	|SELECT
	|	Goods.PartnerProducts AS PartnerProducts,
	|	Goods.Products           AS Products,
	|	Goods.Characteristic         AS Characteristic,
	|	Goods.VendorPriceKind      AS VendorPriceKind,
	|	Goods.Package               AS Package,
	|	Goods.VATRate              AS VATRate,
	|	Goods.Price                   AS Price
	|INTO
	|	TemporaryTableOfGoods_
	|FROM
	|	DocumentDataTableItems AS Goods
	|WHERE
	|	&RegisterVendorPrices
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
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.VendorPriceKind                AS VendorPriceKind,
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
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not (DocumentObject.RegisterVendorPrices) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableOfGoods_", QueryTexts) Then
		QueryTextTemporaryTableOfGoods_(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("ProductsWithDifferentPackagingPrices", QueryTexts) Then
		QueryTextProductsWithDifferentPackagingPrices(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	MAX(Goods.PartnerProducts) AS PartnerProducts,
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.VendorPriceKind                AS VendorPriceKind,
	|	Goods.VendorPriceKind.Currency         AS Currency,
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
	|				* CASE
	|					WHEN
	|						&PriceIncludesVAT AND NOT Goods.VendorPriceKind.PriceIncludesVAT
	|					THEN CASE
	|							WHEN Goods.VATRate = VALUE(Catalog.VATRates.EmptyRef)
	|								THEN 1
	|							ELSE 100 / (100 + Goods.VATRate.Rate1)
	|						END
	|				WHEN NOT &PriceIncludesVAT
	|						AND Goods.VendorPriceKind.PriceIncludesVAT
	|					THEN (Goods.VATRate.Rate1 + 100) / 100
	|				ELSE 1
	|			END
	|			* CASE
	|				WHEN
	|					&Currency <> Goods.VendorPriceKind.Currency
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
	|	AND Goods.VendorPriceKind = ProductsWithDifferentPackagingPrices.VendorPriceKind
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|ON
	|	Currency_Rates.Currency = &Currency
	|LEFT JOIN
	|	TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|ON
	|	CurrencyRatesPrices.Currency = Goods.VendorPriceKind.Currency
	|WHERE
	|	NOT Goods.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.VendorPriceKind,
	|	Goods.VendorPriceKind.Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.PurchaseOrder";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure();
	ParameterValues.Insert("ConstantProductAcceptanceOption", Constants.GoodsReceiptOption.Get());
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("VendorReferenceNumber", """""");
	RedefiningParameterCalculation.Insert("DocumentInflow",
		"CASE
		|WHEN ISNULL(GoodsTable.Ref.Contract.GoodsReceiptOption, VALUE(Enum.GoodsReceiptOptions.EmptyRef)) = VALUE(Enum.GoodsReceiptOptions.EmptyRef)
		|				AND &ConstantProductAcceptanceOption IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
		|			OR GoodsTable.Ref.Contract.GoodsReceiptOption  IN (VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices))
		|THEN
		|	GoodsTable.Ref.Contract
		|WHEN ISNULL(GoodsTable.Ref.Contract.GoodsReceiptOption, VALUE(Enum.GoodsReceiptOptions.EmptyRef)) = VALUE(Enum.GoodsReceiptOptions.EmptyRef)
		|				AND &ConstantProductAcceptanceOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			OR GoodsTable.Ref.Contract.GoodsReceiptOption  = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|THEN
		|	GoodsTable.Ref
		|
		|WHEN ISNULL(GoodsTable.Ref.Terms.GoodsReceiptOption, VALUE(Enum.GoodsReceiptOptions.EmptyRef)) = VALUE(Enum.GoodsReceiptOptions.EmptyRef)
		|				AND &ConstantProductAcceptanceOption IN (VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|			OR GoodsTable.Ref.Terms.GoodsReceiptOption  IN (VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices),
		|													VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed))
		|THEN
		|	GoodsTable.Ref.Terms
		|WHEN ISNULL(GoodsTable.Ref.Terms.GoodsReceiptOption, VALUE(Enum.GoodsReceiptOptions.EmptyRef)) = VALUE(Enum.GoodsReceiptOptions.EmptyRef)
		|				AND &ConstantProductAcceptanceOption = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|			OR GoodsTable.Ref.Terms.GoodsReceiptOption  = VALUE(Enum.GoodsReceiptOptions.DividedByOrdersAndInvoices)
		|THEN
		|	GoodsTable.Ref
		|
		|ELSE
		|	UNDEFINED
		|END");
	RedefiningParameterCalculation.Insert("InvoiceIsOrder",
		"GoodsTable.Ref.GoodsReceiptOption = VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly)");
	RedefiningParameterCalculation.Insert("GoodsReceiptOption",
		"GoodsTable.Ref.GoodsReceiptOption");
	
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
	|	&Status                                 AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&VendorReferenceDate                 AS SourceDocumentDate,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&VendorReferenceNumber                AS SourceDocumentNumber,
	|	&Period                                 	AS RecordingInAccountingDate,
	|	&Priority                              AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)

	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness = 
		"SELECT
		|	DocumentDataHeader.ARAPObject AS ARAPObject
		|FROM
		|	DocumentDataHeader AS DocumentDataHeader";
		
	QueryTextLinesOfBusiness = ARAPAccountingPosting.GetTableOfLinesOfBusiness(QueryTextLinesOfBusiness);

	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	If DocumentObject = Undefined
		Or Not (DocumentObject.Status <> Enums.PurchaseOrderStatuses.NotApproved
		And Not(DocumentObject.BusinessOperation = Enums.BusinessTransactions.ConsignmentProcurement
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale)) Then

		TextPaymentPlans = "";

	Else

	TextPaymentPlans =
		"SELECT
		|	Table.Ref                                                                    AS Ref,
		|	DocumentDataHeader.Organization                                                  AS Organization,
		|	DocumentDataHeader.Partner                                                      AS Partner,
		|
		|	DocumentDataHeader.ARAPObject                                               AS ARAPObject,
		|	DocumentDataHeader.Date                                                         AS RecorderDate,
		|	DocumentDataHeader.Number                                                        AS RecorderNumber,
		|	DocumentDataHeader.ARAPObjectSettings                                              AS ARAPObjectSettings,
		|	DocumentDataHeader.Currency                                                       AS ARAPCurrency,
		|	DocumentDataHeader.Currency                                                       AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod                                                  AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                         AS PaymentDate,
		|	Table.DateOfShipment                                                        AS DateOfShipment,
		|	Table.PaymentOption                                                       AS PaymentOption,
		|	CASE WHEN DocumentDataHeader.PackageDepositIsRequired THEN
		|		Table.PaymentAmount + Table.PackageDepositValue
		|	ELSE
		|		Table.PaymentAmount
		|	END                                                                       AS AmountDue
		|	
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref";

	EndIf;
	
	If DocumentObject = Undefined
		Or Not (DocumentObject.BusinessOperation <> Enums.BusinessTransactions.ReceivingForStorageWithRightOfSale
			And (DocumentObject.Status = Enums.PurchaseOrderStatuses.Approved
				Or DocumentObject.Status = Enums.PurchaseOrderStatuses.Confirmed_
				Or DocumentObject.Status = Enums.PurchaseOrderStatuses.Closed)) Then
		
		TextDeliveryPlans = "";
		
	Else

	TextDeliveryPlans = 
		"SELECT
		|	Table.Ref                                                              AS Ref,
		|	DocumentDataHeader.Organization                                                  AS Organization,
		|	DocumentDataHeader.Partner                                                      AS Partner,
		|	
		|	DocumentDataHeader.ARAPObject                                               AS ARAPObject,
		|	DocumentDataHeader.Date                                                         AS RecorderDate,
		|	DocumentDataHeader.Number                                                        AS RecorderNumber,
		|	DocumentDataHeader.ARAPObjectSettings                                              AS ARAPObjectSettings,
		|	DocumentDataHeader.Currency                                                       AS ARAPCurrency,
		|	DocumentDataHeader.Currency                                                       AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfPurchaseOrder) AS BusinessOperation,
		|	
		|	Table.DateOfReceipt                                                     AS DateOfReceipt,
		|	Table.AmountIncludingVAT                                                           AS IncreaseToAdmission
		|FROM
		|	DocumentDataTableItems AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	NOT Table.Canceled
		|	AND (Table.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR DocumentDataHeader.PackageDepositIsRequired
		|		OR NOT DocumentDataHeader.ToReturnReusablePackage)";
		
	EndIf;
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ExecutionOfOrderToSupplier(Query, QueryTexts, Registers, TextPaymentPlans, TextDeliveryPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.ConductingSettlementsWithSuppliersDeliveryPlan(Query, QueryTexts, Registers, TextDeliveryPlans);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref          AS Ref,
		|	TabPart.Ref.Date     AS Period,
		|	TabPart.Products    AS Products,
		|	TabPart.Characteristic  AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ToControlQuality AS ToControlQuality,
		|	TabPart.ToControlQuality AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
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
		|					AND TabPart.DateOfReceipt >= TabPart.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsReceipt
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
		|							WHEN TabPart.Products.ItemsType IN (
		|									VALUE(Enum.ItemsTypes.Work_5),
		|									VALUE(Enum.ItemsTypes.OperationService))
		|								THEN TabPart.Ref.ServiceReceiptOption
		|							ELSE TabPart.Ref.GoodsReceiptOption
		|						END IN (
		|							VALUE(Enum.GoodsReceiptOptions.NotDividedByOrdersAndInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.GoodsReceiptWithoutReferenceToOrdersAndInvoicesAllowed), 
		|							VALUE(Enum.GoodsReceiptOptions.NotSeparatedByInvoices))
		|						THEN TabPart.Ref.Terms
		|					WHEN CASE
		|							WHEN TabPart.Products.ItemsType IN (
		|									VALUE(Enum.ItemsTypes.Work_5),
		|									VALUE(Enum.ItemsTypes.OperationService))
		|								THEN TabPart.Ref.ServiceReceiptOption
		|							ELSE TabPart.Ref.GoodsReceiptOption
		|						END IN (
		|							VALUE(Enum.GoodsReceiptOptions.UnderContractsWithoutOrdersAndInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.ByContractsAfterOrdersOrInvoices), 
		|							VALUE(Enum.GoodsReceiptOptions.ByContractsAfterInvoices))
		|						THEN TabPart.Ref.Contract
		|					ELSE TabPart.Ref
		|				END
		|		ELSE TabPart.Ref
		|	END AS OrderDocument,
		|	
		|	TabPart.DateOfReceipt AS DateOfReceipt,
		|	
		|	TabPart.Ref.Status IN(
		|			VALUE(Enum.PurchaseOrderStatuses.Confirmed_),
		|			VALUE(Enum.PurchaseOrderStatuses.Closed)
		|		) AS AvailableForConsumption,
		|	
		|	&PurchaseRequest <> VALUE(Document.PurchaseRequest.EmptyRef) AS OnSchedule,
		|	&PurchaseRequest AS OrderInSchedule,
		|	TabPart.Count AS QuantityInGraph
		|FROM
		|	Document.PurchaseOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.ToExpenseAs
		|	AND NOT TabPart.Canceled";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, True);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Order to supplier
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
	PrintCommand.Id = "PurchaseOrder";
	PrintCommand.Presentation = NStr("vi = 'Đơn hàng đặt nhà cung cấp';
									|ru = 'Заказ поставщику';
									|en = 'Purchase order'; fa = 'سفارش خرید';
									|it = 'Ordine al fornitore';
									|pl = 'Zamówienie do dostawcy';
									|tr = 'Satın alma siparişi'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.AdditionalParameters.Insert("Type", "PurchaseOrder");

	If GetFunctionalOption("UsePartnersProducts") Then
		 
		 // Order to the supplier according to the supplier's data
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "PurchaseOrder";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng đặt nhà cung cấp theo dữ liệu của nhà cung cấp';
										|ru = 'Заказ поставщику по данным поставщика';
										|en = 'Vendor reference'; fa = 'مرجع تأمین‌کننده';
										|it = 'Ordine al fornitore in base ai dati del fornitore';
										|pl = 'Zamówienie zakupu według danych dostawcy';
										|tr = 'Tedarikçi bilgilerine göre satın alma siparişi'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("Type", "PurchaseOrderBySupplierData");
		
	EndIf;

EndProcedure

// Returns the data required for the printed form "Order for goods and services".
// 
// Parameters:
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	PrintParameters - Structure - advanced print settings
//  LanguageCode - String - the language in which the printed form will be displayed.
//                         It consists of the language code according to ISO 639-1 and, optionally, the country code according to ISO 3166-1, separated
//                         by an underscore. Examples: "en", "en_US", "en_GB", "ru", "ru_EN".
// 	
// Returns:
// 	Structure - It contains data on the document header, tabular part, and payment stages:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
// 	* ResultsByPaymentStages   - QueryResult - 
//
Function GetDataForPrintedOrderFormForGoodsServices(ObjectsArray, PrintParameters, LanguageCode = Undefined) Export
	
	Query = New Query();
	QueryText =  
	"SELECT
	|	Documents.Ref										AS Ref,
	|	Documents.Number											AS Number,
	|	Documents.Date											AS Date,
	|	Documents.Organization									AS Organization,
	|	Documents.Organization									AS Customer_,
	|
	|	CASE WHEN
	|		Documents.VATTaxation IN (VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|										VALUE(Enum.VATTaxationTypes.DigitalServices))
	|	THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END													AS ConsiderVAT,
	|	Documents.PriceIncludesVAT								AS PriceIncludesVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|
	|	Documents.Organization.Prefix							AS Prefix,
	|	Documents.Counterparty									AS Counterparty,
	|	Documents.Counterparty									AS Performer,
	|	Documents.BankAccount								AS BankAccount,
	|	Documents.BankAccount.CorrespondentText			AS CorrespondentTextBankAccount,
	|	Documents.Currency										AS Currency,
	|	Documents.Manager.Individual						AS Manager,
	|	Documents.AdditionalInformation						AS AdditionalInformation,
	|
	|	CASE Documents.DeliveryMethod
	|		WHEN VALUE(Enum.TransportMethods.ByVendorToOurWarehouse) THEN
	|			Documents.DeliveryAddressForVendor
	|		WHEN VALUE(Enum.TransportMethods.ByCarrierToOurWarehouse) THEN
	|			Documents.DeliveryAddressForVendor
	|		WHEN VALUE(Enum.TransportMethods.ByCarrierToTransferPoint) THEN
	|			Documents.DeliveryAddressOfCarrier
	|		ELSE
	|			""""
	|	END													AS DeliveryAddress,
	|
	|	UNDEFINED											AS Shipper,
	|	UNDEFINED											AS GoodsRecipient,
	// Parameters for selecting report layout areas
	|	FALSE													AS ShowNDSInRows,
	|	TRUE													AS UseAutoDiscounts,
	|	&Type													AS Type,
	|	&PresentationOfDocument									AS PresentationOfDocument,
	|	&PresentationInError									AS PresentationInError
	|
	|FROM
	|	Document.PurchaseOrder AS Documents
	|
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	UNDEFINED AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	UNDEFINED AS PaymentOption,
	|	UNDEFINED AS PaymentPercentage,
	|	UNDEFINED AS PaymentAmount
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref											AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.PartnerProducts.Description				AS NameOfContractorSProductList,
	|	Goods.PartnerProducts.Code						AS ArtistCode,
	|	Goods.PartnerProducts.SKU					AS ArtistSArticle,
	|	Goods.VendorPriceKind								AS TypeOfContractorSPrice,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	Goods.DateOfReceipt									AS DateOfReceipt,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	""""													AS Content,
	|
	|	Goods.NumberOfPackages								AS Count,
	|
	|	Goods.Price												AS Price,
	|	Goods.ManualDiscount								AS DiscountAmount,
	|	Goods.Sum + Goods.ManualDiscount					AS AmountWithoutADiscount,
	|	Goods.Sum											AS Sum,
	|	Goods.VATRate										AS VATRate,
	|	Goods.VATAmount											AS VATAmount,
	|
	|	CASE
	|		WHEN Goods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Products.UnitOfMeasure)
	|					ELSE Goods.Products.UnitOfMeasure.InternationalAbbreviation
	|				END
	|		ELSE 
	|				CASE 
	|					WHEN &ThisIsMainLanguageOfSystem THEN
	|						PRESENTATION(Goods.Package)
	|					ELSE Goods.Package.InternationalAbbreviation
	|				END
	|	END AS UnitOfMeasure,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END													AS Package,
	|
	|	CASE WHEN Goods.Ref.ToReturnReusablePackage
	|			  AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END													AS ThisIsReusablePackage
	|
	|FROM
	|	Document.PurchaseOrder.Goods AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|	AND Goods.Canceled = FALSE
	|
	|ORDER BY
	|	LineNumber";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
		
	Query.Text = QueryText;
		
	Query.SetParameter("ObjectsArray",			ObjectsArray);
	Query.SetParameter("Type",					PrintParameters["Type"]);
	Query.SetParameter("PresentationOfDocument",	NStr("vi = 'Đơn hàng đặt nhà cung cấp';
														|ru = 'Заказ поставщику';
														|en = 'Purchase order'; fa = 'سفارش خرید';
														|it = 'Ordine al fornitore';
														|pl = 'Zamówienie do dostawcy';
														|tr = 'Satın alma siparişi'", Common.DefaultLanguageCode()));
	Query.SetParameter("PresentationInError",	Metadata.Documents.PurchaseOrder.Presentation());
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults",			RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages",	RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart",	RequestResultsPackage[2]);
	
	Return DataStructureForPrinting;
	
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
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("ContactPerson");
	
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

Function QueryTextDocumentGoods(Filter) Export

	QueryText = 
	"SELECT
	|	Table.Ref                       AS PurchaseOrder,
	|	Table.Products                 AS Products,
	|	Table.Characteristic               AS Characteristic,
	|	Table.Purpose                   AS Purpose,
	|	Table.RowCode                    AS RowCode,
	|	Table.Count                   AS Count,
	|	Table.Price                         AS Price,
	|	Table.Sum                        AS Sum,
	|	Table.Package                     AS Package,
	|	Table.Warehouse                        AS Warehouse,
	|	ISNULL(DataOfAccounting.ToRegister, 0) AS ToRegister,
	|	ISNULL(DataOfAccounting.Ordered, 0)    AS Ordered
	|FROM
	|	Document.PurchaseOrder.Goods AS Table
	|	LEFT JOIN TTAccountingData AS DataOfAccounting
	|	ON Table.Ref = DataOfAccounting.PurchaseOrder
	|	AND Table.RowCode = DataOfAccounting.RowCode
	|WHERE
	|	NOT DataOfAccounting.PurchaseOrder IS NULL
	|	AND &Filter";
	
	If ValueIsFilled(Filter) Then
		
		FilterText1 = "";
		
		For Each KeyValue In Filter Do
			
			FilterText1 = 
				FilterText1
				+ " And "
				+ KeyValue.Key
				+ " IN(&"
				+ KeyValue.Value
				+ ")";
			
		EndDo;
		
		QueryText = StrReplace(QueryText, "AND &Filter", FilterText1);
	Else
		QueryText = StrReplace(QueryText, "AND &Filter", "");
	EndIf;
	
	Return QueryText;

EndFunction

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.PurchaseOrder - The document for which you want to get the data.
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
	|	&Ref                    AS Ref,
	|	&Date                      AS Date,
	|	&ApprovalDate          AS ApprovalDate,
	|	Goods.AmountIncludingVAT           AS Sum,
	|	CAST(Goods.Products AS Catalog.Products) AS Products,
	|	Goods.DateOfShipment        AS DateOfShipment,
	|	Goods.DateOfReceipt     AS DateOfReceipt,
	|	Goods.Canceled            AS Canceled,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|;
	|SELECT 
	|	Goods.Ref                                    AS OrderDocument,
	|	Goods.Date                                      AS Date,
	|	Goods.ApprovalDate                          AS ApprovalDate,
	|	Goods.DateOfShipment                              AS DateOfShipment,
	|	Goods.DateOfReceipt                           AS DateOfReceipt,
	|	SUM(CASE
	|			WHEN Goods.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|					OR NOT Goods.ToReturnReusablePackage
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END)              AS PaymentAmount,
	|	0                                                AS AmountARAP,
	|	SUM(CASE 
	|			WHEN Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|				AND Goods.PackageDepositIsRequired
	|				THEN Goods.Sum
	|			ELSE 0 
	|		END)         AS PackageDepositValue,
	|	0                                                AS AmountARAPByPackage
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.Canceled
	|GROUP BY
	|	Goods.DateOfShipment,
	|	Goods.DateOfReceipt,
	|	Goods.Ref,
	|	Goods.Date,
	|	Goods.ApprovalDate
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.PurchaseOrder.Goods");
		Query.Text = StrReplace(Query.Text, "&ToReturnReusablePackage", "Goods.Ref.ToReturnReusablePackage");
		Query.Text = StrReplace(Query.Text, "&PackageDepositIsRequired", "Goods.Ref.PackageDepositIsRequired");
		Query.Text = StrReplace(Query.Text, "&Date", "Goods.Ref.Date");
		Query.Text = StrReplace(Query.Text, "&ApprovalDate", "Goods.Ref.ApprovalDate");
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

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.PurchaseOrder.Form.DocumentsListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.PurchaseOrder))
		And AccessRight("Insert", Metadata.Documents.PurchaseOrder)
		And AccessRight("Read",     Metadata.AccumulationRegisters.VendorsARAPAccounting)
		And GetFunctionalOption("UsePurchaseOrders");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT DocumentPurchaseOrder.Ref) AS OrdersToSuppliersAreStillInProgress,
	|	COUNT(DISTINCT CASE
	|		WHEN PurchaseOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate >= PurchaseOrderStates.EventDate THEN
	|			PurchaseOrderStates.OrderDocument
	|		END) AS OrdersToSuppliersForToday,
	|	COUNT(DISTINCT CASE
	|		WHEN PurchaseOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > PurchaseOrderStates.EventDate 
	|				AND PurchaseOrderStates.State IN (
	|					VALUE(Enum.PurchaseOrderStates.PendingAdvanceBeforeConfirmation),
	|					VALUE(Enum.PurchaseOrderStates.PendingPrepaymentBeforePurchase),
	|					VALUE(Enum.PurchaseOrderStates.PendingPaymentAfterReceipt)) THEN
	|			PurchaseOrderStates.OrderDocument
	|		END) AS OrdersToSuppliersOverduePayment,
	|	COUNT(DISTINCT CASE
	|		WHEN PurchaseOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > PurchaseOrderStates.EventDate 
	|				AND PurchaseOrderStates.State IN (
	|					VALUE(Enum.PurchaseOrderStates.PendingApproval),
	|					VALUE(Enum.PurchaseOrderStates.PendingConfirmation),
	|					VALUE(Enum.PurchaseOrderStates.ReadyForReceipt),
	|					VALUE(Enum.PurchaseOrderStates.PendingReceipt)) THEN
	|			PurchaseOrderStates.OrderDocument
	|		END) AS OrdersToSuppliersOverdue
	|FROM
	|	Document.PurchaseOrder AS DocumentPurchaseOrder
	|		{LEFT JOIN InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
	|		ON (PurchaseOrderStates.OrderDocument = DocumentPurchaseOrder.Ref)}
	|WHERE
	|	(NOT (PurchaseOrderStates.OrderDocument IS NULL) OR NOT DocumentPurchaseOrder.Posted)
	|	AND DocumentPurchaseOrder.Manager = &User
	|	AND PurchaseOrderStates.State <> VALUE(Enum.PurchaseOrderStates.Closed)
	|	AND (NOT DocumentPurchaseOrder.DeletionMark)";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Ordering to suppliers
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "PurchaseOrders";
	UserTaskParent.Presentation  = NStr("vi = 'Nhiều đơn hàng đặt nhà cung cấp';
										|ru = 'Заказы поставщикам';
										|en = 'Purchase orders'; fa = 'سفارش‌های خرید';
										|it = 'Ordini ai fornitori';
										|pl = 'Zamówienia do dostawcy';
										|tr = 'Satın alma siparişleri'");
	UserTaskParent.Owner       = Metadata.Subsystems.Purchases;
	
	// OrdersToSuppliersAreStillInProgress
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersToSuppliersAreStillInProgress";
	ToDoItem.HasToDoItems       = Result.OrdersToSuppliersAreStillInProgress > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tất cả đơn hàng hiện tại';
									|ru = 'Всего заказов в работе';
									|en = 'Total active orders'; fa = 'Total active orders';
									|it = 'Totale ordini in esecuzione';
									|pl = 'Łącznie zamówień w pracy';
									|tr = 'Devam eden tüm siparişler'");
	ToDoItem.Count     = Result.OrdersToSuppliersAreStillInProgress;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchaseOrders";
	
	// OrdersToSuppliersForToday
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "Today");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersToSuppliersForToday";
	ToDoItem.HasToDoItems       = Result.OrdersToSuppliersForToday > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hôm nay';
									|ru = 'На сегодня';
									|en = 'For now'; fa = 'For now';
									|it = 'Ad oggi';
									|pl = 'Na dzisiaj';
									|tr = 'Bugün itibarıyla'");
	ToDoItem.Count     = Result.OrdersToSuppliersForToday;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchaseOrders";
	
	// OrdersToSuppliersOverduePayment
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllPaymentPending");
	FilterParameters.Insert("Relevance", "Overdue");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersToSuppliersOverduePayment";
	ToDoItem.HasToDoItems       = Result.OrdersToSuppliersOverduePayment > 0;
	ToDoItem.Presentation  = NStr("vi = 'Quá hạn thanh toán đơn hàng';
									|ru = 'Просрочена оплата по заказам';
									|en = 'Overdue payables'; fa = 'حساب‌های پرداختنی سررسیدگذشته';
									|it = 'Pagamento per ordini scaduto';
									|pl = 'Zalełgła płatność według zamówień';
									|tr = 'Gecikmiş sipariş ödemeleri'");
	ToDoItem.Count     = Result.OrdersToSuppliersOverduePayment;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchaseOrders";
	
	// OrdersToSuppliersOverdue
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllExecutionPending");
	FilterParameters.Insert("Relevance", "Overdue");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "OrdersToSuppliersOverdue";
	ToDoItem.HasToDoItems       = Result.OrdersToSuppliersOverdue > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đã quá hạn thực hiện đơn hàng';
									|ru = 'Просрочено исполнение заказов';
									|en = 'Overdue order execution'; fa = 'Overdue order execution';
									|it = 'Esecuzione di ordini scaduta';
									|pl = 'Zaległe wykonanie zamówień';
									|tr = 'Vadesi geçmiş siparişler'");
	ToDoItem.Count     = Result.OrdersToSuppliersOverdue;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "PurchaseOrders";
	
	If Result.OrdersToSuppliersAreStillInProgress > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

// Verifies that the order is an order for acceptance of goods
//
// Parameters:
//  PurchaseOrder	 - DocumentRef.PurchaseOrder - The order being checked.
//
// Returns:
//  Boolean - Test result
//
Function OrderIsOrderForAcceptanceOfGoods(PurchaseOrder) Export
	
	SetPrivilegedMode(True);
	
	OptionForAcceptingOrderGoods = Common.ObjectAttributeValue(PurchaseOrder, "GoodsReceiptOption");
	
	Result = False;
	If Not ValueIsFilled(OptionForAcceptingOrderGoods) Then
		Result = Constants.GoodsReceiptOption.Get() = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices;
	ElsIf OptionForAcceptingOrderGoods = Enums.GoodsReceiptOptions.DividedByOrdersAndInvoices Then
		Result = True;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region CreatingHyperlinkInPurchaseLog

Function TextOfOrdersToSupplierInProgressRequest()

	QueryText = 
	"SELECT ALLOWED TOP 1
	|	PurchaseOrderStates.OrderDocument,
	|	PurchaseOrderStates.State
	|FROM
	|	InformationRegister.PurchaseOrderStates AS PurchaseOrderStates
	|WHERE
	|	PurchaseOrderStates.State <> VALUE(Enum.PurchaseOrderStates.Closed)";
	
	Return QueryText
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.PurchaseOrderStates)
			And AccessRight("Update", Metadata.Documents.PurchaseOrder)
			And GetFunctionalOption("UsePurchaseOrders")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Nhiều đơn hàng đặt nhà cung cấp';
						|ru = 'Заказы поставщикам';
						|en = 'Purchase orders'; fa = 'سفارش‌های خرید';
						|it = 'Ordini ai fornitori';
						|pl = 'Zamówienia do dostawcy';
						|tr = 'Satın alma siparişleri'");
	Query = New Query(TextOfOrdersToSupplierInProgressRequest());
	
	FormNameWorkplaceOrderToSupplier = "Document.PurchaseOrder.Form.DocumentsListForm";
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameWorkplaceOrderToSupplier);
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplaceOrderToSupplier);
	EndIf;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.PurchaseOrder.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.62";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("3344821c-a845-4238-a1d6-52a2ec46bcee");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.PurchaseOrder.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Đơn hàng đặt nhà cung cấp"":';
								|ru = 'Обновление документов ""Заказ поставщику"":';
								|en = 'Update the ""Purchase order"" documents:'; fa = 'Update the ""Purchase order"" documents:';
								|it = 'Update the ""Purchase order"" documents:';
								|pl = 'Update the ""Purchase order"" documents:';
								|tr = '""Tedarikçi Siparişi"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Phương án tiếp nhận dịch vụ"" bằng giá trị của mục tin ""Phương án tiếp nhận hàng hóa"".';
								|ru = '- заполняет реквизит ""Вариант приемки услуг"" значением реквизита ""Вариант приемки товаров"".';
								|en = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.'; fa = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|it = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|pl = '- Fills the ""Service receipt option"" attribute with the ""Goods receipt option"" attribute value.';
								|tr = '“Hizmet kabulü seçeneği” özniteliğini “Mal kabulü seçeneği” özniteliğinin değeriyle doldurur.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.PurchaseOrder.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.PurchaseOrder.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.PurchaseOrder";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	DocumentAttributes.Ref AS Ref
	|FROM
	|	Document.PurchaseOrder AS DocumentAttributes
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
	
	FullObjectName = "Document.PurchaseOrder";
	
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
	|		LEFT JOIN Document.PurchaseOrder AS DocumentAttributes
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
				Raise NStr("vi = 'Không thể xử lý cập nhật chứng từ ""Đơn hàng đặt nhà cung cấp"".';
							|ru = 'Не удалось обработать обновление документов ""Заказ поставщику"".';
							|en = 'Cannot process the update of the ""Purchase order"" documents.'; fa = 'Cannot process the update of the ""Purchase order"" documents.';
							|it = 'Cannot process the update of the ""Purchase order"" documents.';
							|pl = 'Cannot process the update of the ""Purchase order"" documents.';
							|tr = '""Tedarikçi Siparişi"" belgelerinin güncellenmesi işlenemedi.'");
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
