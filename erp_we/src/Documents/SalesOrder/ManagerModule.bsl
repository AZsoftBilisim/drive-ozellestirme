#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Creates a representation of the metadata object in the main language.
// Returns:
// String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	ObjectPresentation = NStr(
		"vi = 'Đơn hàng của khách';
		|ru = 'Заказ клиента';
		|en = 'Sales order'; fa = 'سفارش فروش';
		|it = 'Ordine del cliente';
		|pl = 'Zamówienie klienta';
		|tr = 'Satış siparişi'",
		DefaultLanguageCode);
		
	Return ObjectPresentation;
	
EndFunction

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
	Parameters.StatisticsCollectionSections.UseAlways = "Author, DocumentBasis, Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
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
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BusinessOperation", Parameters);
	
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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("GoodsDelivery");
	
	SalesOrderLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.SalesOrder, DocumentRef.SalesOrder - link to the document or object for which you want to get data
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
	
	If TypeOf(Document) = Type("DocumentObject.SalesOrder") Then
		DocumentObject = Document;
		DocumentRef = Document.Ref;
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
		
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers, DocumentObject);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentObject);
		QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters);
		
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	ReflectReserve(Query, QueryTexts, Registers, DocumentObject);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject);
	
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

// The function returns the text of the query to determine the details of the delivery.
//
// Returns:
//	String - Query text
//
Function QueryTextDeliveryDetails_() Export
	
	QueryText =
	"SELECT
	|	Header.Number             AS Number,
	|	Header.Posted          AS Posted,
	|	Header.Ref            AS Ref,
	|	Header.Date              AS Date,
	|	Header.Partner           AS RecipientSender,
	|	Header.CarrierPartner AS Carrier,
	|	CASE WHEN (Header.DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrier)
	|			AND NOT &UseTransportationJobsForDeliveryAccountingByCarriers)
	|			OR Header.DeliveryMethod = VALUE(Enum.TransportMethods.ToCustomerByCourier)
	|		THEN VALUE(Enum.TransportMethods.SelfPickup)
	|		ELSE Header.DeliveryMethod
	|	END                   AS DeliveryMethod,
	|	Header.DeliveryZone      AS Zone,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrier
	|		ELSE Header.DeliveryAddress
	|		END               AS Address,
	|
	|	CASE WHEN DeliveryMethod = VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|		THEN Header.DeliveryAddressOfCarrierFieldValues
	|		ELSE Header.DeliveryAddressFieldValues
	|		END               AS FieldValueAddress,
	|
	|	Header.DeliveryTimeFrom    AS TimeFrom,
	|	Header.DeliveryTimeTo   AS TimeTo,
	|	Header.AdditionalDeliveryInformation
	|		                    AS AdditionalInformation,
	|	T.Warehouse                 AS Warehouse,
	|	T.DeliverFully    AS DeliverFully,
	|	Header.SpecialTransportationConditions  AS SpecialTransportationConditions,
	|	Header.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	Header.Terms.SplitGoodsIssueNotesByReferences AS SplitGoodsIssueNotesByReferences
	|
	|FROM
	|	(SELECT
	|		T.Ref AS Ref,
	|		T.Warehouse AS Warehouse,
	|		MIN(T.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
	|				AS DeliverFully
	|	FROM
	|		Document.SalesOrder.Goods AS T
	|	WHERE
	|		T.Ref IN (&References)
	|		AND T.Products.ItemsType IN (
	|			VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage))
	|	
	|	GROUP BY
	|		T.Ref,
	|		T.Warehouse
	|	
	|	HAVING
	|		MAX(T.SupplyOption = VALUE(Enum.SupplyOptions.Ship)) = TRUE
	|	) AS T
	|		INNER JOIN Document.SalesOrder AS Header
	|		ON (Header.Ref = T.Ref)";
	
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
	
	DataProcessors.LogOfSalesDocuments.AddGenerateCommand(GenerationCommands);
	
	Documents.CustomerInvoiceServices.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	Documents.IssuedLetterOfAuthority.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.TransferOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.MovementOfProductsAndMaterials.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.BackflushProduction.AddGenerateCommand(GenerationCommands);
	Documents.ByAssemblyDisassemblyOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.PurchaseOrder.AddCreateSecuringOrderCommand(GenerationCommands);
	Documents.ProductionOrder2_2.AddCreateSecuringOrderCommand(GenerationCommands);
	
	Documents.SubcontractOrder2_5.AddCreateSecuringOrderCommand(GenerationCommands);
	DataProcessors.GenerationOfTransferToProductionOrdersByReference.AddGenerateCommand(GenerationCommands);
	Documents.PurchaseOrder.AddCreateBasedOnOrdersToSuppliersCommand(GenerationCommands);
	
	Documents.InventoryAssignmentAdjustment.AddCreateCommandBasedOnCustomerOrder(GenerationCommands);
	
	If GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals") Then
		Documents.GoodsShipmentFromStorage.AddCreateCommandBasedOnCustomerOrder(GenerationCommands);
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		CreateCommandBasedOnApplication = Documents.TransferOfGoodsToBailee.AddCreateBasedOnOrderCommand_(GenerationCommands);
		If CreateCommandBasedOnApplication <> Undefined Then
			AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.Equal);
		
			CreateCommandBasedOnApplication.Presentation = NStr("vi = 'Chuyển giao hàng hóa cho người nhận ký gửi';
																|ru = 'Передача товаров комиссионеру';
																|en = 'Customer stock fill-up documents'; fa = 'Customer stock fill-up documents';
																|it = 'Trasferimento articoli al commissionario';
																|pl = 'Wydanie towarów komisantowi';
																|tr = 'Müşteri stoku doldurma'");
		EndIf;
	EndIf;
	
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		CreateCommandBasedOnApplication = Documents.TransferOfGoodsToBailee.AddCreateBasedOnOrderCommand_(GenerationCommands);
		If CreateCommandBasedOnApplication <> Undefined Then
			AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToStorageWithRightOfSale,
															DataCompositionComparisonType.Equal);
		
			CreateCommandBasedOnApplication.Presentation = NStr("vi = 'Chuyển giao hàng hóa cho người cất giữ';
																|ru = 'Передача товаров хранителю';
																|en = 'VMI fill-up'; fa = 'تکمیل موجودی VMI';
																|it = 'Consegna di merci al depositario';
																|pl = 'Przekazanie towaru do magazyniera';
																|tr = 'Malların emanetçiye transferi'");
		EndIf;
	EndIf;
	
	Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Catalogs.Complaints.AddGenerateCommand(GenerationCommands);
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	Documents.EngineeringChangeOrder.AddGenerateCommand(GenerationCommands);
	CreateCommandBasedOnApplication = Documents.CustomerInvoice.AddCreateBasedOnOrderCommand_(GenerationCommands);
	If CreateCommandBasedOnApplication <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.Equal);
		CreateCommandBasedOnApplication.FunctionalOptions =
			"ConsignmentSaleIsUsed20";
	EndIf;
	
	CreateCommandBasedOnApplication = Documents.CustomerInvoice.AddCreateBasedOnOrderCommand_(GenerationCommands);
	If CreateCommandBasedOnApplication <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	CreationCommandBasedOnTransferOfOwnership =
		Documents.CustomerInvoice.AddCommandToCreateTransferOfOwnershipBasedOnOrder(
			GenerationCommands);
	
	If CreationCommandBasedOnTransferOfOwnership <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationCommandBasedOnTransferOfOwnership,
			"ThisIsOrderAsInvoice", 
			False,
			DataCompositionComparisonType.Equal);
	EndIf;
		
	Documents.CustomerInvoice.AddCreateBasedOnRightsTransferReportCommand(GenerationCommands);
	
	Documents.CustomerCommercialInvoice.AddCreateBasedOnInvoiceCommand(GenerationCommands);
	
	Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands);
	
	If GetFunctionalOption("UseInternalSalesOrderApproval") Then
		CreateBasedOnCommand = BusinessProcesses.SaleApproval.AddGenerateCommand(GenerationCommands);
		If CreateBasedOnCommand <> Undefined Then
			CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateNewSalesOrderApprovalProcess";
			CreateBasedOnCommand.Id = "CreateNewSalesOrderApprovalProcess";
			CreateBasedOnCommand.Presentation = NStr("vi = 'Thống nhất đơn hàng của khách';
													|ru = 'Согласование заказа клиента';
													|en = 'Sales order approval'; fa = 'تأیید سفارش فروش';
													|it = 'Definizione dell''ordine del cliente';
													|pl = 'Uzgodnienie zamówienia sprzedaży';
													|tr = 'Müşteri siparişi onayı'");
			CreateBasedOnCommand.WriteMode = "Post";
			CreateBasedOnCommand.FunctionalOptions = "UseInternalSalesOrderApproval";
		EndIf;
	EndIf;
	
	Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	
	Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	
	
	
	CreateCommandBasedOnApplication = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	If CreateCommandBasedOnApplication <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnApplication, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	CreationTeamBasedOnACW = Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	If CreationTeamBasedOnACW <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationTeamBasedOnACW, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	CreateCommandBasedOnDatabaseWriteOff = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	If CreateCommandBasedOnDatabaseWriteOff <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreateCommandBasedOnDatabaseWriteOff, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	CreationCommandBasedOnAcquiringOperation = Documents.PaymentCardTransaction.AddGenerateCommand(GenerationCommands, Enums.BusinessTransactions.RefundToCustomer);
	
	If CreationCommandBasedOnAcquiringOperation <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(CreationCommandBasedOnAcquiringOperation, 
															"BusinessOperation", 
															Enums.BusinessTransactions.TransferToCommissionAgent,
															DataCompositionComparisonType.NotEqual);
	EndIf;
	
	Documents.GoodsShipmentToCustomer.AddCreateBasedOnOrderCommand_(GenerationCommands);
	
	CreationCommand = Documents.DeliveryOrder.AddGenerateCommand(GenerationCommands);
	If CreationCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryIsRequired",
			True,
			DataCompositionComparisonType.Equal);
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"ThisIsOrderAsInvoice",
			False,
			DataCompositionComparisonType.Equal);
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliverySpecificationMethod",
			Enums.DeliverySpecificationMethods.ByRows,
			DataCompositionComparisonType.NotEqual);
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreationCommand,
			"DeliveryPlanning",
			Enums.DeliveryPlanningKinds.SeparateDocument,
			DataCompositionComparisonType.Equal);
		
	EndIf;
	
	SalesOrderLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the "customer Order" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.SalesOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SalesOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SalesOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseSalesOrders";
		
		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

#EndRegion

// Fills in the table of details that depend on the business transaction
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the agreement
//	ArrayOfAllProps - Array - Bank details that do not depend on the business transaction
//	ArrayOfOperationDetails - Array - banking details that depend on the business transaction
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	
	ArrayOfAllProps.Add("PackageDepositIsRequired");
	
	ArrayOfAllProps.Add("Goods.PercentRateOfManualDiscount");
	ArrayOfAllProps.Add("Goods.ManualDiscount");
	ArrayOfAllProps.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
	ArrayOfAllProps.Add("Goods.DiscountMarkupAmount");
	
	ArrayOfOperationDetails = New Array;
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Not ValueIsFilled(BusinessOperation) Then
		
		ArrayOfOperationDetails.Add("PackageDepositIsRequired");
		
		ArrayOfOperationDetails.Add("Goods.PercentRateOfManualDiscount");
		ArrayOfOperationDetails.Add("Goods.ManualDiscount");
		ArrayOfOperationDetails.Add("Goods.PercentRateOfAutomaticDiscountMarkup");
		ArrayOfOperationDetails.Add("Goods.DiscountMarkupAmount");
		
	EndIf;
	
EndProcedure

// Defines the details of the selected document
//
// Parameters:
//	DocumentRef - DocumentRef - .
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
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.DocumentAmount AS AmountARAP,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.SalesOrder AS DocumentData
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
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = ?(ValueIsFilled(Selection.BusinessOperation), Selection.BusinessOperation, Enums.BusinessTransactions.SaleToCustomer);
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
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
		DocumentAmount = 0;
		AmountARAP = 0;
	EndIf;
	
	AttributesStructure1 = New Structure;
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

#Region CalculationOfStates

// Calculates the current status of the customer's order
//
// Parameters:
//	SalesOrder            - DocumentRef.SalesOrder - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//  CheckTasksToReflectStateOfOrders - Boolean - indicates whether the task has been checked
//                                                        in the taskreference register for the status of orders.
//
Procedure CalculateStatus(
			Val SalesOrder,
			Val Contract,
			StateOfCalculations,
			CheckTasksToReflectStateOfOrders = False) Export
	
	FillPropertyValues(StateOfCalculations, ARAPAccountingClientServer.StructureOfStateOfCalculations(True));
	
	If Not ValueIsFilled(SalesOrder) Or Not GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then
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
	|	Document.SalesOrder AS TT
	|WHERE
	|	TT.Ref = &SalesOrder
	|	AND NOT TT.ThisIsOrderAsInvoice
	|;
	|/////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN NOT DocumentOrderDocument.Posted 
	|			THEN VALUE(Enum.SalesOrderStates.EmptyRef)
	|		ELSE
	|			ISNULL(SalesOrderStates.State, VALUE(Enum.SalesOrderStates.Closed))
	|	END AS State,
	|	CASE
	|		WHEN (NOT DocumentOrderDocument.Posted)
	|			THEN FALSE
	|		WHEN DocumentOrderDocument.Status = VALUE(Enum.SalesOrderStatuses.Closed)
	|			THEN FALSE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &CurrentDate > SalesOrderStates.EventDate 
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StateOverdue,
	|	ISNULL(SalesOrderStates.PayAmount,0) AS PayAmount,
	|	ISNULL(SalesOrderStates.PayPercentage,0) AS PayPercentage,
	|	ISNULL(SalesOrderStates.AmountByShipment,0) AS AmountByShipment,
	|	ISNULL(SalesOrderStates.OrderShipmentPercentage,0) AS OrderShipmentPercentage,
	|	ISNULL(SalesOrderStates.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE) AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
	|	ISNULL(SalesOrderStates.DebtPercentage,0) AS DebtPercentage
	|	,&FieldHasTasksToReflectStateOfOrders
	|FROM
	|	TT_DocumentOrderDocument AS DocumentOrderDocument
	|LEFT JOIN
	|	InformationRegister.SalesOrderStates AS SalesOrderStates
	|ON
	|	SalesOrderStates.OrderDocument = DocumentOrderDocument.Ref
	|WHERE
	|	&CheckTasksToReflectStateOfOrders
	|
	|";

	QueryTextHasJobs = "SELECT FALSE AS ThereAreTasksToReflectStateOfOrders";
	If CheckTasksToReflectStateOfOrders Then
		
		QueryText = StrReplace(QueryText,
									",&FieldHasTasksToReflectStateOfOrders",
									",	FALSE AS ThereAreTasksToReflectStateOfOrders");
		
		QueryTextHasJobs = DocumentsStates.QueryTextThereAreTasksToReflectStateOfOrders("&SalesOrder");
		
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
		|			((DocumentOrderDocument.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved) AND DocumentOrderDocument.DocumentAmount > 0)
		|			OR NOT (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|					OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		THEN
		|			CAST (ISNULL(CustomersARAPAccountingBalance.SumBalance, 0) AS NUMBER(31,2))
		|		ELSE
		|			0
		|	END AS AmountOfDebt,
		|	CASE
		|		WHEN
		|			DocumentOrderDocument.Posted
		|			AND (DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|				OR DocumentOrderDocument.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice))
		|		THEN
		|			ISNULL(CustomersARAPAccountingBalance.AmountDueBalance,0)
		|		ELSE
		|			0
		|	END AS AmountToPay
		|FROM
		|	TT_DocumentOrderDocument AS DocumentOrderDocument
		|LEFT JOIN
		|	AccumulationRegister.CustomersARAPAccounting.Balance(,
		|			ARAPObject IN (SELECT TT.ARAPObject FROM TT_DocumentOrderDocument AS TT)
		|	) AS CustomersARAPAccountingBalance
		|ON
		|	DocumentOrderDocument.ARAPObject = CustomersARAPAccountingBalance.ARAPObject
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
	
	Query.SetParameter("SalesOrder", SalesOrder);
	Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
	
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
	
	QueryText ="
		|SELECT 
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentSalesOrder.Posted
		|	THEN
		|		VALUE(Enum.SalesOrderStates.EmptyRef)
		|// APPROVAL IS EXPECTED //////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingApproval)
		|// AN ADVANCE PAYMENT IS EXPECTED BEFORE SECURING //////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|		AND DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingAdvanceBeforeSupply)
		|// READY TO PROVIDE ///////////////////////////////////////////////////
		|	WHEN
		|		TTOrderAssurance.ThereIsToProvision
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyForSupply)
		|// PREPAYMENT IS EXPECTED BEFORE SHIPMENT ////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply) OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip))
		|		AND DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingPrepaymentBeforeShipment)
		|// PROVISION IS EXPECTED ////////////////////////////////////////////////////
		|	WHEN
		|		NOT TTPartiallyInStock.Ref IS NULL
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingSupply)
		|// READY FOR SHIPMENT //////////////////////////////////////////////////////////
		|	WHEN
		|		NOT TTOrderAssurance.ShipEverything
		|			AND (DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|					AND NOT DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.Closed)
		|				OR NOT DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
		|			OR TTDiscrepanciesOrderInvoice.WarrantRequired
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyToShip)
		|// THE TRANSFER OF OWNERSHIP IS EXPECTED ////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		OR NOT DocumentSalesOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND ISNULL(SalesOrdersBalance.ToShipClosingBalance, 0) = 0
		|		AND ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) > 0
		|		AND ISNULL(GoodsForIssueBalance.ToShipBalance, 0) = 0
		|	THEN
		|		VALUE(Enum.SalesOrderStates.TransferOfTitleToGoodsIsExpected)
		|// IN THE PROCESS OF SHIPMENT //////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR NOT DocumentSalesOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND (ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) <> 0 
		|			OR ISNULL(SalesOrdersBalance.OrderedClosingBalance, 0) <> 0
		|			OR ISNULL(GoodsForIssueBalance.ToShipBalance, 0) <> 0)
		|	THEN
		|		VALUE(Enum.SalesOrderStates.DuringShipment)
		|// PAYMENT IS EXPECTED AFTER SHIPMENT /////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|		AND DocumentSalesOrder.DocumentAmount - DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue - DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0 
		|		AND ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) = 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		VALUE(Enum.SalesOrderStates.PendingPaymentAfterShipment)
		|// READY TO CLOSE ////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status <> VALUE(Enum.SalesOrderStatuses.Closed) AND &MonitorOrderClosing
		|	THEN
		|		VALUE(Enum.SalesOrderStates.ReadyForClosure)
		|// unopened //////////////////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status IN
		|				(VALUE(Enum.SalesOrderStatuses.ToSupply), 
		|				VALUE(Enum.SalesOrderStatuses.ToShip),
		|				VALUE(Enum.SalesOrderStatuses.Closed))
		|	THEN
		|		VALUE(Enum.SalesOrderStates.Closed)
		|END AS State,
		|CASE
		|// NOT CARRIED OUT /////////////////////////////////////////////////////////////
		|	WHEN
		|		NOT DocumentSalesOrder.Posted
		|	THEN
		|		DATETIME(1,1,1)
		|// DATE OF APPROVAL ///////////////////////////////////////////////////////
		|	WHEN
		|		DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	THEN
		|		DocumentSalesOrder.ApprovalDate
		|// ADVANCE PAYMENT DATE /////////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|		AND DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// PREPAYMENT DATE /////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|		AND DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(MutualSettlementsStatus.PaidByOrder, 0) < DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|		AND (ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0 OR MutualSettlementsStatus.OrderDocument IS NULL)
		|	THEN
		|		SettlementDates.UpdateDate
		|// DATE OF SHIPMENT ///////////////////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip))
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|		AND (ISNULL(MutualSettlementsStatus.PaidByOrder, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR ISNULL(MutualSettlementsStatus.OrderAmount, 0) - ISNULL(MutualSettlementsStatus.RemainsToPay, 0) >= DocumentSalesOrder.AmountOfPrepaymentBeforeShipment + DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue
		|			OR NOT DocumentSalesOrder.ARAPObjectSettings IN (VALUE(Enum.ARAPObjectSettings.ByOrders), VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice)))
		|		AND (ISNULL(SalesOrdersBalance.SumClosingBalance, 0) > 0 OR ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) > 0)
		|	THEN
		|		ISNULL(ShippingDatesOfCustomerOrders.MinimumShipmentDate, DocumentSalesOrder.DateOfShipment)
		|// PAYMENT DATE AFTER SHIPMENT //////////////////////////////////////////////
		|	WHEN
		|		(DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|			OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip))
		|		AND DocumentSalesOrder.DocumentAmount - DocumentSalesOrder.AmountPrepaymentBeforeGoodsIssue - DocumentSalesOrder.AmountOfPrepaymentBeforeShipment > 0
		|		AND ISNULL(SalesOrdersBalance.ToRegisterClosingBalance, 0) = 0
		|		AND ISNULL(MutualSettlementsStatus.RemainsToPay, 0) > 0
		|	THEN
		|		SettlementDates.UpdateDate
		|	ELSE
		|		DATETIME(1,1,1)
		|END AS EventDate,
		|// PAYMENT AMOUNT /////////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|			OR DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|		THEN ISNULL(MutualSettlementsStatus.PayAmount, 0)
		|	ELSE 0
		|END AS PayAmount,
		|// PERCENTAGE OF PAYMENT ///////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|			OR DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|		THEN ISNULL(MutualSettlementsStatus.PayPercentage, 0)
		|	ELSE 0
		|END AS PayPercentage,
		|// SHIPMENT AMOUNT ///////////////////////////////////////////////////////////
		|CASE
		|	WHEN DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|			OR DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|		THEN ISNULL(SalesOrdersBalance.AmountOfExpenditureIncludingMeasuredGoods, 0) - DocumentSalesOrder.ReturnablePackagingAmount
		|	ELSE ISNULL(MutualSettlementsStatus.AmountByShipment, 0)
		|END AS AmountByShipment,
		|// PERCENTAGE OF SHIPMENT /////////////////////////////////////////////////////////
		|&OrderShipmentPercentage,
		|// DEBT (+ WE ARE OWED, - WE MUST)//////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.AmountOfDebt, 0) AS AmountOfDebt,
		|// percentage of debt ////////////////////////////////////////////////////////////
		|ISNULL(MutualSettlementsStatus.DebtPercentage, 0) AS DebtPercentage,
		|// DISCREPANCIES OF THE ORDER INVOICE//////////////////////////////////////////
		|CASE
		|	WHEN
		|		DocumentSalesOrder.Posted
		|		AND DocumentSalesOrder.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved)
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|	THEN
		|		ISNULL(TTDiscrepanciesOrderInvoice.ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice, FALSE)
		|	ELSE
		|		FALSE
		|	END AS ThereAreDiscrepanciesOfGoodsReceiptNoteAndInvoice,
		|//LINK TO THE ORDER///////////////////////////////////////////////////////
		|	DocumentSalesOrder.Ref AS OrderDocument
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|LEFT JOIN
		|	TTStateOfSETTLEMENTS AS MutualSettlementsStatus
		|ON
		|	DocumentSalesOrder.Ref = MutualSettlementsStatus.OrderDocument 
		|LEFT JOIN
		|	TTCustomerOrdersBalance AS SalesOrdersBalance
		|ON
		|	DocumentSalesOrder.Ref = SalesOrdersBalance.SalesOrder
		|LEFT JOIN
		|	TTGoodsForShipmentBalance AS GoodsForIssueBalance
		|ON
		|	DocumentSalesOrder.Ref = GoodsForIssueBalance.SalesOrder
		|LEFT JOIN
		|	CustomerOrderValidityDates AS SettlementDates
		|ON
		|	DocumentSalesOrder.ARAPObject = SettlementDates.ARAPObject
		|LEFT JOIN
		|	ShippingDatesOfCustomerOrders AS ShippingDatesOfCustomerOrders
		|ON
		|	DocumentSalesOrder.Ref = ShippingDatesOfCustomerOrders.SalesOrder
		|LEFT JOIN
		|	TTOrderAssurance AS TTOrderAssurance
		|ON
		|	TTOrderAssurance.Ref = DocumentSalesOrder.Ref
		|LEFT JOIN
		|	TTPartiallyInStock AS TTPartiallyInStock
		|ON
		|	TTPartiallyInStock.Ref = DocumentSalesOrder.Ref
		|LEFT JOIN
		|	TTDiscrepanciesOrderInvoice AS TTDiscrepanciesOrderInvoice
		|ON
		|	DocumentSalesOrder.Ref = TTDiscrepanciesOrderInvoice.SalesOrder
		|WHERE
		|	DocumentSalesOrder.Ref IN (&AnArrayOfOrders)
		|	AND NOT DocumentSalesOrder.ThisIsOrderAsInvoice
		|
		|";
	
	TextOfPercentageOfShipmentField = ?(
		GetFunctionalOption("NewOnlineARAPAccounting"),
		"CASE
		|	WHEN (DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|			OR DocumentSalesOrder.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|		THEN CAST((ISNULL(SalesOrdersBalance.AmountOfExpenditureIncludingMeasuredGoods, 0) - DocumentSalesOrder.ReturnablePackagingAmount) * 100 / DocumentSalesOrder.DocumentAmount AS NUMBER(20, 10))
		|	ELSE ISNULL(MutualSettlementsStatus.OrderShipmentPercentage, 0)
		|END AS OrderShipmentPercentage",
		"CASE
		|	WHEN
		|		DocumentSalesOrder.Posted
		|		AND (DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|			OR DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.OrderForPrepaymentInvoiceForInvoice))
		|		AND ISNULL(SalesOrdersBalance.SumExpense, 0) > 0
		|		AND DocumentSalesOrder.DocumentAmount > 0
		|	THEN
		|		CAST((ISNULL(SalesOrdersBalance.AmountOfExpenditureIncludingMeasuredGoods, 0) - DocumentSalesOrder.ReturnablePackagingAmount) * 100 / DocumentSalesOrder.DocumentAmount AS NUMBER(20, 10))
		|	ELSE 0
		|END AS OrderShipmentPercentage");
	QueryText = StrReplace(QueryText, "&OrderShipmentPercentage", TextOfPercentageOfShipmentField);
	
	Return QueryText;
	
EndFunction

#EndRegion

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse, Date, Status, ThisIsOrderAsInvoice";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.SalesOrder";
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, True);
	
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseItemsBatch 
				And Not Object.ThisIsOrderAsInvoice;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches
				And Not Object.ThisIsOrderAsInvoice;
				
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShipmentToCustomer);
		
	SeriesSpecificationParameters.ThisIsOrder = True;
	SeriesSpecificationParameters.ShipmentPlanning = True;
	SeriesSpecificationParameters.RegisterSeries = False;
	
	SeriesSpecificationParameters.Date = Object.Date;
	
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
	|	Goods.Series,
	|	Goods.Canceled,
	|	Goods.SupplyOption,
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
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN Goods.Canceled
	|				OR BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|				OR NOT Goods.SupplyOption IN (
	|						VALUE(Enum.SupplyOptions.FromWarehouse),
	|						VALUE(Enum.SupplyOptions.Ship))
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 15
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					WHEN Goods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|						THEN 11
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
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
	
	MeaningOfNewStatus = Enums.SalesOrderStatuses[NewStatus];
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("OrderFulfillmentControl") Then
		QueryText = SalesServer.RequestTextOrderControlAfterExecution();
		
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
		|	DocumentsTable.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
		|	CASE
		|		WHEN TTOrderBalances_.SalesOrder IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereAreLeftoversOnOrder
		|FROM
		|	Document.SalesOrder AS DocumentsTable
		|LEFT JOIN
		|	TTOrderBalances_
		|ON
		|	TTOrderBalances_.SalesOrder = DocumentsTable.Ref
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)
		|";
		
	Else
		
		QueryText =
		"SELECT
		|	DocumentsTable.Ref                                                                            AS Ref,
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
		|	DocumentsTable.ThisIsOrderAsInvoice                                                                    AS ThisIsOrderAsInvoice,
		|	TRUE                                                                                               AS Recording
		|FROM
		|	Document.SalesOrder AS DocumentsTable
		|WHERE
		|	DocumentsTable.Ref IN(&DocumentsArray)";
		
	EndIf;
		
	MonitorShipment = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment");
	MonitorCalculations  = GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment");
		
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	Query.SetParameter("MonitorShipment", MonitorShipment);
	Query.SetParameter("MonitorCalculations", MonitorCalculations);
	
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
	
	MeaningOfNewStatus = Enums.SalesOrderStatuses[NewStatus];
	
	If ValidationSample.ThisIsOrderAsInvoice Then
	
		ErrorText = NStr("vi = 'Trong chứng từ %Document% chưa thiết lập trạng thái ""%Status%"", bởi vì đối với đơn hàng của khách mà tạo trong chế độ ""Đơn hàng như hóa đơn"" chưa áp dụng trạng thái';
						|ru = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для заказов клиентов, созданных в режиме ""Заказ как счет"" статусы не применимы';
						|en = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales orders created in the ""Order as a commercial invoice"" mode'; fa = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales orders created in the ""Order as a commercial invoice"" mode';
						|it = 'У документа %Document% статус ""%Status%"" не установлен, т.к. для заказов клиентов, созданных в режиме ""Заказ как счет"" статусы не применимы';
						|pl = 'The %Document% document is not set to ""%Status%"" as you cannot set statuses for sales orders created in the ""Order as a commercial invoice"" mode';
						|tr = 'Durumlar ""Fatura olarak sipariş"" modunda oluşturulan müşteri siparişleri için geçerli olmadığından ""%Document%"" belgesi ""%Status%"" durumuna sahip değildir'");
		ErrorText = StrReplace(ErrorText, "%Document%", ValidationSample.Ref);
		ErrorText = StrReplace(ErrorText, "%Status%", ValidationSample.PresentationOfNewStatus);
		CommonClientServer.MessageToUser(ErrorText, ValidationSample.Ref, , , Cancel);
		
	EndIf;
	
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

// Checks the completeness of the verified details.
//
// Parameters:
//	 SalesOrder       - DocumentRef.SalesOrder - The document on the basis of which the input is made
//	 Status             - EnumRef - Status of the document that is used for entering data
//	 ThereAreErrorsPosted - Boolean - If True-the document on the basis of which the input is made is not held
//	 ForCompletion        - Boolean - Allows you to enter documents in the status of Vypolneniyu.
//
Procedure CheckPossibilityOfEnteringBasedOn(SalesOrder, Status = Undefined, ThereAreErrorsPosted = False,
		ForCompletion = False) Export
	
	ThisIsOrderAsInvoice = Common.ObjectAttributeValue(SalesOrder, "ThisIsOrderAsInvoice");
	ArrayOfValidStatuses = ValidInputStatusesBasedOn(ForCompletion, Not ThisIsOrderAsInvoice);
	ThereAreErrorsStatus = ArrayOfValidStatuses.Find(Status) = Undefined;
	
	TMCommonUse.CheckPossibilityOfEnteringBasedOn(
		SalesOrder,
		Status,
		ThereAreErrorsPosted,
		ThereAreErrorsStatus,
		ArrayOfValidStatuses);
	
EndProcedure

// Generates an array of acceptable statuses based on the program settings
//
// Parameters:
//  ForCompletion - Boolean - True, if you take into account the status of self-Sufficiency.
//  UseAdvancedFeaturesOfSalesOrder - Boolean, Undefined - 
//										false - returns Statuses only for the "order as invoice" mode of operation,
//										true - returns Statuses for the extended mode of operation,
//										undefined returns Statuses depending on the functional option installed in the system.
//
// Returns:
//  Array of EnumRef.SalesOrderStatuses - array of valid statuses.
//
Function ValidInputStatusesBasedOn(ForCompletion = False, UseAdvancedFeaturesOfSalesOrder = Undefined) Export
	
	ArrayOfValidStatuses = New Array;
	If UseAdvancedFeaturesOfSalesOrder = Undefined Then
		UseAdvancedFeaturesOfSalesOrder = GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	EndIf;
	
	If UseAdvancedFeaturesOfSalesOrder Then
		If GetFunctionalOption("UseShipmentByRowsInSalesOrder") Then
			ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToSupply);
		Else
			If ForCompletion Then
				ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToSupply);
			EndIf;
			ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.ToShip);
		EndIf;
		If GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment")
			Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment") Then
			ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.Closed);
		EndIf;
	Else
		ArrayOfValidStatuses.Add(Enums.SalesOrderStatuses.NotApproved);
	EndIf;
	
	Return ArrayOfValidStatuses;
	
EndFunction

// This function checks the order document when creating an expense order
//
// Parameters:
//	ReferenceOrder - DocumentRef - Document-order
//	Warehouse - CatalogRef.Warehouses - element of the Warehouses reference list.
//
// Returns:
//	Structure 						- verification results:
//	* Operation 						- String - Type of operation. "Failure" if the checks passed with errors
//	* ErrorText 					- String - Must be filled in when Failure = True
//	* GroupOfWarehousesAtYourDisposal 	- Boolean - A group of warehouses is selected at the disposal
//	* DateOfShipment 					- Date
//	* UseAdvancedWarehousing 	- Boolean - The warehouse uses an order scheme.
//
Function PerformOrderChecks(ReferenceOrder, Warehouse) Export
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("Operation", "");
	ReturnStructure.Insert("ErrorText", "");
	ReturnStructure.Insert("GroupOfWarehousesAtYourDisposal", False);
	ReturnStructure.Insert("DateOfShipment");
	ReturnStructure.Insert("UseAdvancedWarehousing", False);
	
	If Not ValueIsFilled(Common.ObjectAttributeValue(ReferenceOrder, "Warehouse")) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Kho bãi"" trong chứng từ ""%ReferenceOrder%"". Không thể tạo phiếu.';
						|ru = 'Не заполнено поле ""Склад"" в документе ""%ReferenceOrder%"". Невозможно создать ордер.';
						|en = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.'; fa = '""Warehouse"" in the ""%ReferenceOrder%"" document is not filled in. Cannot create a note.';
						|it = 'Il campo ""Magazzino"" nel documento ""%ReferenceOrder%"" non è stato compilato. Impossibile creare un mandato.';
						|pl = 'Nie jest wypełnione pole ""Magazyn"" w dokumencie ""%ReferenceOrder%"". Nie można utworzyć zlecenia.';
						|tr = '""%ReferenceOrder%"" belgesindeki ""Ambar"" alanı doldurulmamış. Giriş fişi oluşturulamaz.'");
		ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
		ReturnStructure.ErrorText = ErrorText;
		ReturnStructure.Operation = "Cancel";
		
		Return ReturnStructure
		
	EndIf;
	
	WarehouseGroupStructure     = New Structure("IsFolder", "Warehouse.IsFolder");
	WarehouseGroupValue      = Common.ObjectAttributesValues(ReferenceOrder, WarehouseGroupStructure);
	GroupOfWarehousesAtYourDisposal = WarehouseGroupValue.IsFolder;
	
	ReturnStructure.GroupOfWarehousesAtYourDisposal = GroupOfWarehousesAtYourDisposal; 
	
	Attributes = New Structure("DateOfShipment, Warehouse, UseAdvancedWarehousing", "Date");
		 	
	If Not GroupOfWarehousesAtYourDisposal Then
		
		Attributes.Warehouse = "Warehouse";
		Attributes.UseAdvancedWarehousing ="
		|CASE
		|	WHEN ISNULL(Warehouse.UseWarehouseManagemantSystemForGoodsIssue, FALSE)
		|			AND DATE >= ISNULL(Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
		|		THEN TRUE
		|	ELSE FALSE
		|END";
		
		AttributesValues = Common.ObjectAttributesValues(ReferenceOrder, Attributes);
		UseAdvancedWarehousing = AttributesValues.UseAdvancedWarehousing;
		
		ReturnStructure.UseAdvancedWarehousing = UseAdvancedWarehousing;
		
		If UseAdvancedWarehousing Then
			
			Warehouse = AttributesValues.Warehouse;
			FillPropertyValues(ReturnStructure, AttributesValues, "DateOfShipment");
			
		Else
			
			ErrorText = NStr("vi = 'Đối với kho bãi ""%Warehouse%"" không cần lập phiếu xuất kho.
				|Chưa điền chứng từ.';
				|ru = 'Для склада ""%Warehouse%"" оформление расходных ордеров не требуется.
				|Заполнение документа не выполнено.';
				|en = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.'; fa = 'For warehouse ""%Warehouse%"" it is not required to create goods issues.
				|The document is not completed.';
				|it = 'Per il magazzino, ""%Warehouse%"" non è richiesta la formalizzazione dei mandati di pagamento.
				|La compilazione del documento non è eseguita.';
				|pl = 'W przypadku magazynu ""%Warehouse%"" sporządzenie zleceń wydania nie jest wymagane.
				|Dokument nie został wypełniony.';
				|tr = '""%Warehouse%"" ambarı için herhangi bir ambar çıkış fişlerini düzenleme gerekmemektedir.
				| Belge tamamlanmamıştır.'");
			ReturnStructure.ErrorText = StrReplace(ErrorText, "%Warehouse%", String(AttributesValues.Warehouse));
			ReturnStructure.Operation = "Cancel";
			Return ReturnStructure;
			
		EndIf;	
	EndIf;
	
	Status = Common.ObjectAttributeValue(ReferenceOrder, "Status");
	
	CheckPossibilityOfEnteringBasedOn(ReferenceOrder, Status);
	
	If GroupOfWarehousesAtYourDisposal Then
		If Not ValueIsFilled(Warehouse) Then
			WarehouseArray = Documents.GoodsIssueNote.OrderWarehousesDuringShipment(ReferenceOrder, Undefined);
			If WarehouseArray.Count() = 0 Then
				ErrorText = NStr("vi = 'Đối với các kho bãi của chứng từ ""%ReferenceOrder%"" không cần lập phiếu nhập kho.
										|Chưa điền chứng từ.';
										|ru = 'Для складов документа ""%ReferenceOrder%"" оформление приходных ордеров не требуется.
										|Заполнение документа не выполнено.';
										|en = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.'; fa = 'It is not required to register goods receipts for warehouses of the ""%ReferenceOrder%"" document.
										|The document is not populated.';
										|it = 'Per i magazzini del documento ""%ReferenceOrder%"" non è richiesta la formalizzazione dei reversali d’incasso.
										|La compilazione del documento non è eseguita.';
										|pl = 'W przypadku magazynów dokumentu ""%ReferenceOrder%"" sporządzenie zleceń wydania nie jest wymagane.
										|Dokument nie został wypełniony.';
										|tr = '""%ReferenceOrder%"" belgesindeki depolar için ambar giriş fişlerinin düzenlemesi gerekmemektedir.
										| Belge tamamlanmamıştır.'");
				ErrorText = StrReplace(ErrorText, "%ReferenceOrder%", String(ReferenceOrder));
				ReturnStructure.ErrorText = ErrorText;
				ReturnStructure.Operation = "Cancel";
				Return ReturnStructure;
			ElsIf WarehouseArray.Count() = 1 Then
				Warehouse = WarehouseArray[0];
			Else
				ReturnStructure.Operation = "Return";
				Return ReturnStructure;
			EndIf;
		Else
			ReturnStructure.Operation = "Return";
			Return ReturnStructure;
		EndIf;
	EndIf;
	
	Return ReturnStructure
	
EndFunction

// Initializes the status structure of the document
//
// Returns:
//  Structure - a structure with the necessary fields.
//
Function StructureStateOfDocumentExecution() Export
	
	StructureState = Reports.DocumentFulfillmentStatus.InitializeDocumentExecutionStructureState();
	
	StructureState.Insert("DisplayCalculationsWithCustomersTable", 1);
	StructureState.Insert("OutputTablesSupply", 2);
	StructureState.Insert("DisplayShipmentTables", 3);
	StructureState.Insert("DisplayTablesCanceledShipment", 4);
	StructureState.Insert("ThisIsOrder", True);
	StructureState.Insert("ThereAreSummaryShipmentIndicators", True);
	StructureState.Insert("ThereAreReasonsToCancelShipment", GetFunctionalOption("UseReasonsForSalesOrderCancellations"));
	StructureState.Insert("NameTSGoodsShipment", "Goods");
	StructureState.Insert("DisplayDeliveryTables", 5);
	StructureState.Insert("RegisterNameShipmentOfServices", "ShipmentAndReturnReferences");
	StructureState.Insert("ToDisplayPPPTable", 6);
	
	Return StructureState
	
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.SalesOrder - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInSalesVATTaxation(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Object.Organization;	
	FillParameters.Date = OrdersServer.GetMinimumDateOfShipmentOfObject(Object);
	FillParameters.Warehouse = Object.Warehouse;
	FillParameters.Contract = Object.Contract;
	FillParameters.LineOfBusiness = Object.LineOfBusiness;
	FillParameters.ThisIsOrder = True;
	FillParameters.Department = Object.Department;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
		Or Object.BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
		Or Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	ElsIf Object.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale Then
		
		FillParameters.TransferToStorage = True;
		
	EndIf;
	
	Return FillParameters;
	
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
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then 
		Return ParametersMutualSettlementsSelfService(FillingData);
	EndIf;
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation, ThisIsOrderAsInvoice");
		BusinessOperation = StructureFillingData.BusinessOperation;
		ThisIsOrderAsInvoice = StructureFillingData.ThisIsOrderAsInvoice;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		ThisIsOrderAsInvoice = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		ThisIsOrderAsInvoice = FillingData.ThisIsOrderAsInvoice;
	EndIf;
	
	UseAdvancedFeaturesOfSalesOrder = ?(ThisIsOrderAsInvoice = Undefined,
														GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"),
														Not ThisIsOrderAsInvoice);
														
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsOrder                         = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = (BusinessOperation = Enums.BusinessTransactions.SaleToCustomer
															Or BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle
															Or BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal)
															And UseAdvancedFeaturesOfSalesOrder;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = True;
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.DocumentAmountForm              = "Form.AmountOrderedWithADepositContainer";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	ParametersStructure.FormItems.PaymentSettlement        = "CreditPaymentForm";
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	ParametersStructure.IncomingDocumentNumber          = "Object.NumberAccordingToCustomerData";
	ParametersStructure.IncomingDocumentDate           = "Object.DateAccordingToInformationFromCustomer";
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.ApprovalDate                 = "Object.ApprovalDate";
	ParametersStructure.DateOfShipment                     = "Object.Goods.DateOfShipment";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.OrderAsAProformaInvoice                     = Not UseAdvancedFeaturesOfSalesOrder;
	ParametersStructure.ThereIsDateOfTransferOfOwnership =
		GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
	ParametersStructure.SourceOfAmountsTabularPart       = True;
	ParametersStructure.ShipInOneDay              = "Object.NotShipInInstallments";
	
	#EndRegion
	
	#Region MutualSettlementsStatus
	
	ParametersStructure.FormItems.InscriptionCalculations                   = "DecorationSettlementState";
	
	#EndRegion
	
	#Region LimitsOnDebtUnderAgreement
	
	ParametersStructure.FormItems.DebtLimitationText    = "DecorationDebtLimitation";
	ParametersStructure.FormItems.DebtLimitation = "ImageShipmentProhibited";
	
	#EndRegion
	
	ParametersStructure.ToReturnReusablePackage            = "Object.ToReturnReusablePackage";
	ParametersStructure.PackageDepositIsRequired                 = "Object.PackageDepositIsRequired";
	
	ParametersStructure.PaymentPurposes                    = "Object.PaymentPurposes";
	ParametersStructure.TSP                                  = "Object.Warehouse";
	ParametersStructure.AdditionalInformation             = "Object.AdditionalInformation";
	
	Return ParametersStructure;
	
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
	
	Restriction.TextForExternalUsers1 =
	"AttachAdditionalTables
	|ThisList AS ThisList
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersPartners
	|	ON ExternalUsersPartners.AuthorizationObject = ThisList.Partner
	|
	|LEFT JOIN Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|	ON ContactPersonsForPartners.Owner = ThisList.Partner
	|
	|LEFT JOIN Catalog.ExternalUsers AS ExternalUsersContactPersons
	|	ON ExternalUsersContactPersons.AuthorizationObject = ContactPersonsForPartners.Ref
	|;
	|AllowReadUpdate
	|WHERE
	|	ValueAllowed(ExternalUsersPartners.Ref)
	|	OR ValueAllowed(ExternalUsersContactPersons.Ref)";

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

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// See ARAPAccountingServer.MechanismParameters
//
Function ParametersMutualSettlementsSelfService(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"BusinessOperation,
			|NotShipInInstallments");
		BusinessOperation = StructureFillingData.BusinessOperation;
		NotShipInInstallments    = StructureFillingData.NotShipInInstallments;
	ElsIf FillingData = Undefined Then
		BusinessOperation = Undefined;
		NotShipInInstallments = Undefined;
	Else
		BusinessOperation = FillingData.BusinessOperation;
		NotShipInInstallments    = FillingData.NotShipInInstallments;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsOrder                         = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = BusinessOperation <> Enums.BusinessTransactions.TransferToCommissionAgent
															And BusinessOperation <> Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = True;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentSteps         = "Object.PaymentScheduleSteps";
	ParametersStructure.ApprovalDate                 = "Object.ApprovalDate";
	
	If NotShipInInstallments Then
		ParametersStructure.DateOfShipment                     = "Object.DateOfShipment";
	Else
		ParametersStructure.DateOfShipment                     = "Object.Goods.DateOfShipment";
	EndIf; 
	
	ParametersStructure.DoNotSpecifyPaymentSources       = True;
	
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.CompanyBankAccount        = "Object.BankAccount";
	ParametersStructure.DocumentAmountForm              = "Form.AmountOrdered";
	ParametersStructure.AmountOfDepositForContainerForm           = "Form.PackageDepositValue";
	
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentSteps";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStepsText";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.ShipInOneDay              = "Object.NotShipInInstallments";
	
	Return ParametersStructure;
	
EndFunction

// Designed to override the order list to set the collateral actions.
// Parameters:
//  Orders - Array of AnyRef -
//  ActionCode - String -
//  UserMessages - Array of Structure
Procedure BeforePerformingActionsInOrderList(Orders, ActionCode, UserMessages) Export
	
	Query = New Query();
	Query.SetParameter("Orders", Orders);
	Query.Text =
		"SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.SalesOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|		AND NOT Table.ThisIsOrderAsInvoice
		|;
		|SELECT
		|	Table.Ref AS Ref
		|FROM
		|	Document.SalesOrder AS Table
		|WHERE
		|	Table.Ref IN (&Orders)
		|	AND Table.ThisIsOrderAsInvoice";
	QueryBatch = Query.ExecuteBatch();
	OrdersAsInvoice = QueryBatch[1].Unload().UnloadColumn("Ref");
	Text = NStr("vi = 'Đối với %1 chưa thể thực hiện lệnh, bởi vì đã tạo chứng từ trong chế độ ""Đơn hàng như hóa đơn""';
				|ru = 'Для %1 команда не может быть выполнена, так как документ был создан в режиме ""Заказ как счет""';
				|en = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode'; fa = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode';
				|it = 'Для %1 команда не может быть выполнена, так как документ был создан в режиме ""Заказ как счет""';
				|pl = 'The command cannot be performed for %1 as the document was created in the ""Order as a commercial invoice"" mode';
				|tr = '%1 için komut çalıştırılamaz çünkü belge ""Fatura olarak sipariş"" modunda oluşturulmuştur'");
	For Each Ref In OrdersAsInvoice Do 
		UserMessages.Add(New Structure("Text,Ref", StrTemplate(Text, Ref), Ref));
	EndDo;
	If OrdersAsInvoice.Count() > 0 Then
		Orders = QueryBatch[0].Unload().UnloadColumn("Ref");
	EndIf;
	
EndProcedure

// Forms the structure of the document parameters for embedding the document in the software algorithms.
// Parameters:
//  DocumentObject - DocumentObject.SalesOrder - Document
// Returns:
//  See ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions
//
Function AvailableRemainingEmbeddingOptions(DocumentObject = Undefined) Export
	
	EmbeddingParameters = ProvisionInDocumentsServer.AvailableRemainingEmbeddingOptions();
	EmbeddingParameters.UseEventSubscriptions.BeforePerformingActionsInOrderList = True;
	EmbeddingParameters.AttributesToBeCleared = "RowCode";
	
	// Updating the "Available" column.
	EmbeddingParameters.FormTableName = "Goods";
	
	// Conditional registration.
	FormItems = EmbeddingParameters.ConditionalAppearance.FormItems;
	FormItems.SupplyOption = "GoodsSupplyOption";
	FormItems.Available           = "GoodsAvailable";
	FormItems.Series              = "GoodsSeries";
	FormItems.WithAssignment        = "GoodsWithAssignment";
	FormItems.Warehouse              = "GoodsWarehouse";
	
	DataPaths = EmbeddingParameters.ConditionalAppearance.DataPaths;
	DataPaths.ReallocateInventory = "Object.Goods.ReallocateInventory";
	DataPaths.NoEditingAllowed = "Object.Goods.Canceled";
	DataPaths.ItemsType = "Object.Goods.ItemsType";
	
	// The choice of the security option.
	Links = EmbeddingParameters.ConnectionsOfSoftwareOptionSelectionParameters;
	Links.Available              = "Items.Goods.CurrentData.Available";
	Links.NumberOfPackages    = "Items.Goods.CurrentData.NumberOfPackages";
	Links.Count            = "Items.Goods.CurrentData.Count";
	Links.ShipIfAvailable = "Items.Goods.CurrentData.ShipIfAvailable";
	Links.WithAssignment           = "Items.Goods.CurrentData.WithAssignment";
	Links.ItemsType       = "Items.Goods.CurrentData.ItemsType";
	Links.Package              = "Items.Goods.CurrentData.Package";
	Links.Products          = "Items.Goods.CurrentData.Products";
	Links.SupplyOption    = "Items.Goods.CurrentData.SupplyOption";
	Links.Warehouse                 = "Items.Goods.CurrentData.Warehouse";
	Links.MultipleWarehouses      = "WarehouseGroup_";
	
	// The name of the shipment registration register.
	EmbeddingParameters.NameOfShipmentRegistrationRegister = "ShipmentAndReturnReferences";
	
	// Temporary document data table.
	EmbeddingParameters.ObjectName = "Document.SalesOrder";
	EmbeddingParameters.TableName = "Document.SalesOrder.Goods";
	
	EmbeddingParameters.DescriptionOfGettingDocumentData =
		"SELECT
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Department,
		|	TabPart.Warehouse AS Warehouse,
		|	Attributes.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	Attributes.Ref AS ShipmentOrder,
		|	TabPart.SupplyOption AS SupplyOption,
		|	TabPart.WithAssignment AS WithAssignment,
		|	TabPart.Count AS Count,
		|	TabPart.NumberOfPackages AS NumberOfPackages,
		|	TabPart.Package AS Package,
		|	Attributes.Status IN(
		|			VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip),
		|			VALUE(Enum.SalesOrderStatuses.Closed)
		|		) AS ReadyForSupply,
		|	Attributes.Status IN(
		|			VALUE(Enum.SalesOrderStatuses.ToSupply),
		|			VALUE(Enum.SalesOrderStatuses.ToShip),
		|			VALUE(Enum.SalesOrderStatuses.Closed)
		|		) AS ReadyToShip,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
		|	TabPart.Series AS Series,
		|	TabPart.RowCode AS RowCode,
		|	TabPart.Canceled AS Canceled,
		|	TabPart.LineNumber AS LineNumber,
		|	Attributes.Ref AS Recorder,
		|	Attributes.Date AS DocumentDate,
		|	Attributes.Warehouse AS GroupOfWarehouses,
		|	Attributes.Priority AS Priority,
		|	CASE WHEN Attributes.NotShipInInstallments THEN
		|				Attributes.DateOfShipment
		|			ELSE
		|				UNDEFINED
		|		END AS TheShipmentDateOfAllLinesIsASingleDate
		|INTO TemporaryDocumentDataTable
		|FROM
		|	Document.SalesOrder.Goods AS TabPart
		|		
		|		LEFT JOIN Document.SalesOrder AS Attributes
		|		ON TRUE";
	
	// Template for serialization of form data.
	Goods = New Structure();
	Goods.Insert("LineNumber",        New TypeDescription("Number"));
	Goods.Insert("Products",       New TypeDescription("CatalogRef.Products"));
	Goods.Insert("Characteristic",     New TypeDescription("CatalogRef.ItemsCharacteristics"));
	Goods.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Goods.Insert("SupplyOption", New TypeDescription("EnumRef.SupplyOptions"));
	Goods.Insert("WithAssignment",        New TypeDescription("Boolean"));
	Goods.Insert("NumberOfPackages", New TypeDescription("Number"));
	Goods.Insert("Count",         New TypeDescription("Number"));
	Goods.Insert("Package",           New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	Goods.Insert("DateOfShipment",       New TypeDescription("Date"));
	Goods.Insert("Series",              New TypeDescription("CatalogRef.ItemsBatches"));
	Goods.Insert("Canceled",           New TypeDescription("Boolean"));
	Goods.Insert("RowCode",          New TypeDescription("Number"));
	Goods.Insert("Department",      New TypeDescription("CatalogRef.BusinessStructure"));
	
	Object = New Structure();
	Object.Insert("Purpose",         New TypeDescription("CatalogRef.Assignments"));
	Object.Insert("Ref",             New TypeDescription("DocumentRef.SalesOrder"));
	Object.Insert("Status",             New TypeDescription("EnumRef.SalesOrderStatuses"));
	Object.Insert("NotShipInInstallments", New TypeDescription("Boolean"));
	Object.Insert("DateOfShipment",       New TypeDescription("Date"));
	Object.Insert("Date",               New TypeDescription("Date"));
	Object.Insert("Priority",          New TypeDescription("CatalogRef.Priorities"));
	Object.Insert("Warehouse",              New TypeDescription("CatalogRef.Warehouses"));
	Object.Insert("Goods",             Goods);
	
	EmbeddingParameters.FormDataSerializationPattern.Insert("Object", Object);
	
	Return EmbeddingParameters;
	
EndFunction

// Defines a list of business transactions that can be specified in documents such as "Customer's order".
//
//  Parameters:
//   CheckFunctionalOptions - Boolean - True if you want to get only operations
//                                           that can be specified in the document with the current values
//                                           of functional options. False if you need to get all document operations
//                                           of this type.
//  Returns:
//   Array of EnumRef.BusinessTransactions
Function BusinessOperationsOfDocument(CheckFunctionalOptions) Export
	
	UseSalesCommission = True;
	UseShipmentWithDeferredTransferOfTitle2_0 = True;
	ToUseTheTransferOfGoodsToStorage = True;
	ProvideAgentServicesOnPurchaseToPrincipals = True;
	UseShipmentByRowsInSalesOrder = True;
	OptionOfGoodsAssignmentInSales = Enums.OptionsOfGoodsAssignmentInSales.EmptyRef();
	
	If CheckFunctionalOptions Then
		
		UseSalesCommission =
			GetFunctionalOption("UseSalesCommission");
		UseShipmentWithDeferredTransferOfTitle2_0 =
			GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0");
		ToUseTheTransferOfGoodsToStorage =
			GetFunctionalOption("UseTransferToCustodyWithRightOfSale");
		ProvideAgentServicesOnPurchaseToPrincipals =
			GetFunctionalOption("ProvideAgentServicesOnPurchaseToPrincipals");
		UseShipmentByRowsInSalesOrder =
			GetFunctionalOption("UseShipmentByRowsInSalesOrder");
		OptionOfGoodsAssignmentInSales = Constants.OptionOfGoodsAssignmentInSales.Get();
		
	EndIf;
	
	Operations = New Array();
	
	Operations.Add(Enums.BusinessTransactions.SaleToCustomer);
	If UseShipmentWithDeferredTransferOfTitle2_0 Then
		Operations.Add(Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle);
	EndIf;
	If UseSalesCommission Then
		Operations.Add(Enums.BusinessTransactions.TransferToCommissionAgent);
	EndIf;
	If ToUseTheTransferOfGoodsToStorage Then
		Operations.Add(Enums.BusinessTransactions.TransferToStorageWithRightOfSale);
	EndIf;
	If ProvideAgentServicesOnPurchaseToPrincipals
		And UseShipmentByRowsInSalesOrder
		And OptionOfGoodsAssignmentInSales <> Enums.OptionsOfGoodsAssignmentInSales.Contract Then
		Operations.Add(Enums.BusinessTransactions.DeliveryForPrincipal);
	EndIf;
	
	Return Operations;
	
EndFunction

#Region TextsOfRequestOrderOfInvoices

// Adds the key details of the order to the selection collection
// 
// Parameters:
// 	Filter - Map
//
Procedure AddSelectionBasedOnKeyOrderDetails(Filter) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("Partner");
	KeyAttributes.Add("Counterparty");
	KeyAttributes.Add("Contract");
	KeyAttributes.Add("Warehouse");
	KeyAttributes.Add("SalesOpportunity");
	KeyAttributes.Add("Terms");
	KeyAttributes.Add("Currency");
	KeyAttributes.Add("LineOfBusiness");
	KeyAttributes.Add("ToReturnReusablePackage");
	
	TMCommonUse.AddSelectionBasedOnKeyOrderDetails(KeyAttributes, Filter);
	
EndProcedure

// Returns the text of the request for orders to processors according to key and additional selections.
// 
// Parameters:
// 	Parameters - See TMCommonUse.ParametersOfRequestTextForOrdersInvoices
// Returns:
//  String - Query text
//
Function RequestTextForOrdersInvoices(Parameters) Export
	
	AddSelectionBasedOnKeyOrderDetails(Parameters.Filter);
	
	QueryText =
	"SELECT
	|	TableOfOrders.Ref AS ReferenceOrder
	|FROM
	|	Document.SalesOrder AS TableOfOrders
	|WHERE
	|	TableOfOrders.Posted
	|	AND &FilterText1
	|";
	
	If Parameters.GenerateTT Then
		QueryText = RequestSchemes.SetSelectionOfAllowedRecords(QueryText, True);
		QueryText = RequestSchemes.SetRoomToTemporaryTable(QueryText, Parameters.TTName);
		QueryText = RequestSchemes.SetIndexingOfQueryFields(QueryText, "ReferenceOrder");
	EndIf;
	
	QueryText =
		StrReplace(QueryText, "&FilterText1", TMCommonUse.SelectionTextBySelectionCollection(Parameters.Filter));
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Structure - See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement.
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.VHFWarehouses = True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ObjectForm" Then
		If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
			StandardProcessing = False;
			SelectedForm = "SelfServiceWorkplaceDocumentForm";
		EndIf;
	ElsIf FormType = "ListForm" Then
		If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
			StandardProcessing = False;
			SelectedForm = "SelfServiceWorkplaceListForm";
		ElsIf Not AccessRight("Read", Metadata.InformationRegisters.SalesOrderStates)
			Or Not AccessRight("Read", Metadata.InformationRegisters.StatesByEDIAccountingObjects) Then
			StandardProcessing = False;
			SelectedForm = "ListForm";
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Internal

#Region Supply

// Returns a table for the goods of the document for the creation mechanism based on the securing order.
//
// Parameters:
//  Ref - DocumentRef.SalesOrder - the document for which you need to get the goods
//  CreationParameters - See ProvisionInDocumentsServer.ProductSelectionParametersForCreatingSecuringOrder
//  TempTablesManager - TempTablesManager - temporary table manager where a table with columns will be created:
//   * LineNumber - Number - Line number
//   * Products - CatalogRef.Products - Products
//   * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//   * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
//   * Warehouse - CatalogRef.Warehouses - Warehouse
//   * Department - CatalogRef.BusinessStructure - Department
//   * Purpose - CatalogRef.Assignments - Purpose
//   * SupplyOption - EnumRef.SupplyOptions - security option
//   * WithAssignment - Boolean - WithAssignment
//   * QuantityOfUnits - Number - number of units
//   * CountByDocument - Number - Number of packages
Procedure GoodsOfDocumentForCreatingSecuringOrder(Ref, CreationParameters, TempTablesManager) Export
	
	Attributes = Common.ObjectAttributesValues(Ref, "Status,Posted");
	CheckPossibilityOfEnteringBasedOn(Ref, Attributes.Status, Not Attributes.Posted, True);
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ItemsTypes", CreationParameters.ItemsTypes);
	Query.SetParameter("Ref", Ref);
	Query.Text =
		"SELECT
		|	Goods.LineNumber AS LineNumber,
		|	Goods.Products AS Products,
		|	Goods.Characteristic AS Characteristic,
		|	Goods.Package AS Package,
		|	Goods.Warehouse AS Warehouse,
		|	Goods.Department AS Department,
		|	CASE
		|		WHEN Goods.WithAssignment
		|			THEN Goods.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	Goods.SupplyOption AS SupplyOption,
		|	Goods.WithAssignment AS WithAssignment,
		|	Goods.DateOfShipment AS DateOfShipment,
		|	Goods.Count AS NumberOfUnitsPerDocument,
		|	Goods.NumberOfPackages AS CountByDocument
		|INTO DocumentGoods
		|FROM
		|	Document.SalesOrder.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|		AND NOT Goods.Canceled
		|		AND Goods.Products.ItemsType IN(&ItemsTypes)";
	
	Query.Execute();
	
EndProcedure

Function DocumentParametersForSoftwareActions(Object) Export
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		SecurityOptionAndFlagSeparately = ProvisionInDocumentsClientServer.ProvisionOptionAndFlagAreSeparateByDefault(True);
	Else
		SecurityOptionAndFlagSeparately = SalesServer.ProvisionOptionAndFlagAreSeparateByDefault(Object.Terms, Object.Status, , Not Object.ThisIsOrderAsInvoice);
	EndIf;
	
	DocumentParameters = New Structure();
	DocumentParameters.Insert("EmbeddingParameters",                  AvailableRemainingEmbeddingOptions());
	DocumentParameters.Insert("Object",                                Object);
	DocumentParameters.Insert("SecurityOptionAndFlagSeparately",    SecurityOptionAndFlagSeparately);
	
	ProvisionInDocumentsServer.FillInEmbeddingServiceParameters(DocumentParameters);
	Return DocumentParameters;
	
EndFunction

// Performs additional actions related to filling in the security in the document.
// Parameters:
//  Object - FormDataStructure, DocumentObject.SalesOrder - The document in which the security was filled in.
//  Changes - ValueTable - Table of changes to the document after filling in the security.
//  Mode - String - The mode that defines the software filling contest.
//  FillParameters - Structure - Fill-in parameters.
//  ThereAreChangesInDateOfShipment - Boolean - it will be set to True if the shipment dates have changed
Procedure AfterFillingOutCollateral(Object, Changes, Mode, FillParameters, ThereAreChangesInDateOfShipment = False) Export
	
	ThereAreChangesInDateOfShipment = ProvisionInDocumentsServer.UpdateShipmentDate(
		FillParameters,
		Object.NotShipInInstallments,
		Object.DateOfShipment,
		Object.Goods,
		"DateOfShipment");
		
	If ProvisionInDocumentsClientServer.YouNeedToCheckFillInShipmentDateForShipLines(Mode) Then
		
		ThereAreChangesInDateOfShipment = ThereAreChangesInDateOfShipment Or ProvisionInDocumentsServer.CheckFillInShipmentDateForShipLines(
			Changes.UnloadColumn("String"),
			"DateOfShipment",
			Object.NotShipInInstallments,
			Object.DateOfShipment);
			
	EndIf;
	
	If TypeOf(Object) <> Type("FormDataStructure") And ThereAreChangesInDateOfShipment Then
		PaymentStepsServer.AfterFillingOutCollateral(Object);
	EndIf;
	
	ProvisionInDocumentsServer.RecalculateNumberOfUnits(Changes, Object.Goods);
	Attributes = "Sum, VATAmount, AmountIncludingVAT, ManualDiscount, DiscountMarkupAmount";
	OrdersServer.RecalculateDependentPropsAfterSplittingRows(Changes, Attributes);
	SeriesSpecificationParameters = SeriesSpecificationParameters(Object);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
EndProcedure

#EndRegion

#Region LinesOfBusiness

// Returns the structure of document processing order parameters
// 
// Parameters:
// 	Form - ClientApplicationForm
// 	
// Returns:
// Structure - See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.FillInAssignmentInHeader = True;
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#EndRegion

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	HeaderData_.Date                      AS Period,
	|	HeaderData_.Partner                   AS Partner,
	|	HeaderData_.Counterparty                AS Counterparty,
	|	HeaderData_.Organization               AS Organization,
	|	HeaderData_.Currency                    AS Currency,
	|	HeaderData_.Warehouse                     AS Warehouse,
	|	HeaderData_.Status                    AS Status,
	|	HeaderData_.Ref                    AS SalesOrder,
	|	HeaderData_.Priority                 AS Priority,
	|	HeaderData_.PriceIncludesVAT           AS PriceIncludesVAT,
	|	HeaderData_.BusinessOperation     AS BusinessOperation,
	|	HeaderData_.Contract                   AS Contract,
	|	HeaderData_.Purpose                AS Purpose,
	|	HeaderData_.Department             AS Department,
	|	
	|	HeaderData_.AllowableAmountPayable AS AllowableAmountPayable,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.DocumentAmount AS DocumentAmount,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
	|	HeaderData_.DateAccordingToInformationFromCustomer AS DateAccordingToInformationFromCustomer,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.Manager AS Manager,
	|	HeaderData_.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
	|	HeaderData_.LoyaltyCardOwnerLoyaltyProgram AS LoyaltyProgram,
	|	HeaderData_.DeliveryIsRequired AS DeliveryIsRequired,
	|	HeaderData_.DeliveryPlanning AS DeliveryPlanning,
	|	HeaderData_.DeliverySpecificationMethod AS DeliverySpecificationMethod,
	|	HeaderData_.DeliveryMethod25 AS DeliveryMethod25,
	|	HeaderData_.ConsignmentSales25 AS ConsignmentSales25
	|
	|FROM
	|	DocumentDataHeader AS HeaderData_";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",          	 Attributes.Period);
	Query.SetParameter("SalesOrder",    	 Attributes.SalesOrder);
	Query.SetParameter("Period",          	 Attributes.Period);
	Query.SetParameter("Warehouse",           	 Attributes.Warehouse);
	Query.SetParameter("Partner",           	 Attributes.Partner);
	Query.SetParameter("Currency",          	 Attributes.Currency);
	Query.SetParameter("Status",          	 Attributes.Status);
	Query.SetParameter("Priority",           Attributes.Priority);
	Query.SetParameter("Organization",     	 Attributes.Organization);
	Query.SetParameter("PriceIncludesVAT", 	 Attributes.PriceIncludesVAT);
	Query.SetParameter("Purpose", 		 Attributes.Purpose);
	Query.SetParameter("Department", 		 Attributes.Department);
	Query.SetParameter("BusinessOperation", Attributes.BusinessOperation);
	Query.SetParameter("Contract",			 Attributes.Contract);
	Query.SetParameter("UseShipmentByRowsInSalesOrder", 
		GetFunctionalOption("UseShipmentByRowsInSalesOrder"));
	Query.SetParameter("UseAdvancedFeaturesOfSalesOrder", Not Attributes.ThisIsOrderAsInvoice);
	Query.SetParameter("AllowableAmountPayable", Attributes.AllowableAmountPayable);
	Query.SetParameter("Counterparty",           Attributes.Counterparty);
	Query.SetParameter("LineOfBusiness", Attributes.LineOfBusiness);
	Query.SetParameter("Number",                Attributes.Number);
	Query.SetParameter("Manager",             Attributes.Manager);
	Query.SetParameter("Author",                Attributes.Author);
	Query.SetParameter("Comment",          Attributes.Comment);
	Query.SetParameter("Posted",             Attributes.Posted);
	Query.SetParameter("DeletionMark",      Attributes.DeletionMark);
	Query.SetParameter("DateAccordingToInformationFromCustomer",  Attributes.DateAccordingToInformationFromCustomer);
	Query.SetParameter("NumberAccordingToCustomerData", Attributes.NumberAccordingToCustomerData);
	Query.SetParameter("DocumentAmount",       Attributes.DocumentAmount);
	Query.SetParameter("MetadataIdentifier",     Common.MetadataObjectID(TypeOf(DocumentRef)));
	Query.SetParameter("BusinessTransactionsGoodsTransfer",  SalesServer.GoodsTransferOperations());
	Query.SetParameter("LoyaltyProgram", Attributes.LoyaltyProgram);
	Query.SetParameter("CurrentDate",  CurrentUniversalDate());
	Query.SetParameter("ConsignmentSales25",Attributes.ConsignmentSales25);
	
	ContractInformation = Undefined;
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
	
	Query.SetParameter("DeliveryIsRequired", Attributes.DeliveryIsRequired);
	Query.SetParameter("DeliverySpecificationMethod", Attributes.DeliverySpecificationMethod);
	Query.SetParameter("DeliveryMethod25", Attributes.DeliveryMethod25);
	
	If Attributes.DeliveryIsRequired Then
		
		OperationLevel = GoodsDelivery.LevelOfOperationOfDocument(DocumentRef, Attributes.DeliveryPlanning);
		Query.SetParameter("OperationLevel", OperationLevel);
		
	EndIf;
	
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
	
	QueryTextHeader = "SELECT
	|	HeaderData_.Date AS Date,
	|	HeaderData_.Partner AS Partner,
	|	HeaderData_.Counterparty AS Counterparty,
	|	HeaderData_.Organization AS Organization,
	|	HeaderData_.Currency AS Currency,
	|	HeaderData_.Warehouse AS Warehouse,
	|	HeaderData_.Status AS Status,
	|	HeaderData_.Ref AS Ref,
	|	HeaderData_.Priority AS Priority,
	|	HeaderData_.PriceIncludesVAT AS PriceIncludesVAT,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.Contract AS Contract,
	|	HeaderData_.Purpose AS Purpose,
	|	HeaderData_.Department AS Department,
	|	ISNULL(HeaderData_.Contract.AllowableAmountPayable, 0) AS AllowableAmountPayable,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	HeaderData_.Number AS Number,
	|	HeaderData_.Comment AS Comment,
	|	HeaderData_.DocumentAmount AS DocumentAmount,
	|	HeaderData_.Posted AS Posted,
	|	HeaderData_.DeletionMark AS DeletionMark,
	|	HeaderData_.NumberAccordingToCustomerData AS NumberAccordingToCustomerData,
	|	HeaderData_.DateAccordingToInformationFromCustomer AS DateAccordingToInformationFromCustomer,
	|	HeaderData_.Author AS Author,
	|	HeaderData_.Manager AS Manager,
	|	HeaderData_.ThisIsOrderAsInvoice AS ThisIsOrderAsInvoice,
	|	HeaderData_.ToReturnReusablePackage AS ToReturnReusablePackage,
	|	HeaderData_.PackageDepositIsRequired AS PackageDepositIsRequired,
	|	HeaderData_.ARAPObject AS ARAPObject,
	|	HeaderData_.ARAPObjectSettings AS ARAPObjectSettings,
	|	HeaderData_.PaymentMethod AS PaymentMethod,
	|	HeaderData_.LoyaltyCard.Owner.LoyaltyProgram AS
	|		LoyaltyCardOwnerLoyaltyProgram,
	|	ISNULL(HeaderData_.Contract.ConsignmentSales25, FALSE) AS ConsignmentSales25,
	|	HeaderData_.NotShipInInstallments AS NotShipInInstallments,
	|	HeaderData_.DeliveryIsRequired AS DeliveryIsRequired,
	|	HeaderData_.DeliveryPlanning AS DeliveryPlanning,
	|	HeaderData_.DeliverySpecificationMethod AS DeliverySpecificationMethod,
	|	HeaderData_.DeliveryMethod25 AS DeliveryMethod25,
	|	HeaderData_.DeliveryPoint AS DeliveryPoint,
	|	HeaderData_.DeliveryZone AS DeliveryZone,
	|	HeaderData_.DeliveryToCarrier AS DeliveryToCarrier,
	|	HeaderData_.CarrierPartner AS CarrierPartner,
	|	HeaderData_.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	HeaderData_.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	HeaderData_.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	HeaderData_.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	HeaderData_.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription,
	|	HeaderData_.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	HeaderData_.DeliveryTimeTo AS DeliveryTimeTo,
	|	HeaderData_.DateOfShipment AS DateOfShipment
	|INTO DocumentDataHeader
	|FROM
	|	Document.SalesOrder AS HeaderData_
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
	|	GoodsTable.DateOfShipment AS DateOfShipment,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Package AS Package,
	|	GoodsTable.NumberOfPackages AS NumberOfPackages,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.PriceKind AS PriceKind,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountIncludingVAT AS AmountIncludingVAT,
	|	GoodsTable.PercentRateOfManualDiscount AS PercentRateOfManualDiscount,
	|	GoodsTable.ManualDiscount AS ManualDiscount,
	|	GoodsTable.PercentRateOfAutomaticDiscountMarkup AS PercentRateOfAutomaticDiscountMarkup,
	|	GoodsTable.DiscountMarkupAmount AS DiscountMarkupAmount,
	|	GoodsTable.CancellationReason AS CancellationReason,
	|	GoodsTable.RowCode AS RowCode,
	|	GoodsTable.Canceled AS Canceled,
	|	GoodsTable.ConnectionKey AS ConnectionKey,
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.DeliveryPeriodDays AS DeliveryPeriodDays,
	|	GoodsTable.Content AS Content,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	GoodsTable.SupplyOption AS SupplyOption,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductsInSet AS ProductsInSet,
	|	GoodsTable.WithAssignment AS WithAssignment,
	|	GoodsTable.ItemVariantOfSet AS ItemVariantOfSet,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.PartnerProducts AS PartnerProducts,
	|	GoodsTable.AmountOfBonusPointsToDeduction AS AmountOfBonusPointsToDeduction,
	|	GoodsTable.AmountOfBonusPointsToDeductionInCurrency AS AmountOfBonusPointsToDeductionInCurrency,
	|	GoodsTable.AmountOfEarnedBonusPointsInCurrency AS AmountOfEarnedBonusPointsInCurrency,
	|	GoodsTable.Products.ItemsType AS ProductsTypeOfProducts
	|INTO DocumentDataTableItems
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|INDEX BY
	|	Ref";
	
	ListOfRequests.Add(QueryTextTableGoods);
	
EndProcedure

Procedure QueryTextDocumentDataTableStagesOfPaymentSchedule(ListOfRequests)

	QueryTextTablePaymentScheduleSteps = "SELECT
	|	TableStagesOfPaymentSchedule.LineNumber                  AS LineNumber,
	|	TableStagesOfPaymentSchedule.Ref                       AS Ref,
	|	TableStagesOfPaymentSchedule.PaymentOption                AS PaymentOption,
	|	TableStagesOfPaymentSchedule.PaymentDate                  AS PaymentDate,
	|	TableStagesOfPaymentSchedule.PaymentPercentage               AS PaymentPercentage,
	|	TableStagesOfPaymentSchedule.PaymentAmount                 AS PaymentAmount,
	|	TableStagesOfPaymentSchedule.PackageDepositPercentage          AS PackageDepositPercentage,
	|	TableStagesOfPaymentSchedule.PackageDepositValue            AS PackageDepositValue,
	|	TableStagesOfPaymentSchedule.MeasuringGoodsVarianceAmount AS MeasuringGoodsVarianceAmount,
	|	TableStagesOfPaymentSchedule.Move                        AS Move,
	|	TableStagesOfPaymentSchedule.CalculateFrom               AS CalculateFrom
	|INTO DocumentDataTableStagesOfPaymentSchedule
	|FROM
	|	Document.SalesOrder.PaymentScheduleSteps AS TableStagesOfPaymentSchedule
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
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Date AS Date,
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
	|					VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
	|					VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))
	|			THEN FALSE
	|		WHEN DocumentTable.ProductsTypeOfProducts = VALUE(Enum.ItemsTypes.ReusablePackage)
	|			AND DocumentData.ToReturnReusablePackage
	|			AND NOT DocumentData.PackageDepositIsRequired
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	DocumentDataTableItems AS DocumentTable
	|		INNER JOIN DocumentDataHeader AS DocumentData
	|			ON DocumentTable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.Canceled
	|"; 
		
	If DocumentObject = Undefined Then
		
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataTableItems", "Document.SalesOrder.Goods");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentDataHeader", "Document.SalesOrder");
		QueryTextdata_ = StrReplace(QueryTextdata_, "DocumentTable.ProductsTypeOfProducts", "DocumentTable.Products.ItemsType");
		
	EndIf;
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers, DocumentObject = Undefined)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject = Undefined
		Or (DocumentObject <> Undefined
			And DocumentObject.Status <> Enums.SalesOrderStatuses.NotApproved) Then
		
		QueryText =
		"SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	BEGINOFPERIOD(&Period, DAY) AS Period,
		|	&Ref AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN &BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
		|			VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
		|			OR GoodsTable.BatchesIndicationStatus IN(10, 14)
		|			THEN GoodsTable.Series
		|		ELSE
		|			VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|			THEN 0
		|		ELSE GoodsTable.RowCode
		|	END AS RowCode,
		|	GoodsTable.Warehouse AS Warehouse,
		|	CASE
		|		WHEN GoodsTable.Canceled
		|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Canceled)
		|		ELSE VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Ordered)
		|	END AS Factor,
		|	GoodsTable.Count AS Count,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|			THEN GoodsTable.Sum
		|		ELSE
		|			GoodsTable.AmountIncludingVAT
		|	END AS Sum,
		|	CASE
		|		WHEN GoodsTable.Canceled
		|			THEN GoodsTable.CancellationReason
		|		ELSE UNDEFINED
		|	END AS CancellationReason
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND NOT &Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsTable.LineNumber AS LineNumber,
		|	GoodsTable.DateOfShipment AS Period,
		|	&Ref AS ReferenceOrder,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	CASE
		|		WHEN &BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
		|			VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
		|			OR TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|				AND GoodsTable.BatchesIndicationStatus IN(10, 14)
		|			THEN GoodsTable.Series
		|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
		|	END AS Series,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.DeliveryForPrincipal)
		|			THEN 0
		|		ELSE GoodsTable.RowCode
		|	END AS RowCode,
		|	CASE
		|		WHEN &BusinessOperation IN
		|			(VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|			VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale),
		|			VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
		|			OR TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
		|			THEN CASE
		|				WHEN GoodsTable.ProductsTypeOfProducts IN (VALUE(Enum.ItemsTypes.OwnGoods),
		|					VALUE(Enum.ItemsTypes.ReusablePackage))
		|					THEN GoodsTable.Warehouse
		|				ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|			END
		|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
		|	END AS Warehouse,
		|	TableOfIndicators.Ref AS Factor,
		|	GoodsTable.Count AS Count,
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|			THEN GoodsTable.Sum
		|		ELSE
		|			GoodsTable.AmountIncludingVAT
		|	END AS Sum,
		|	VALUE(Catalog.ReasonsForSaleOrderCancellation.EmptyRef) AS CancellationReason
		|FROM
		|	DocumentDataTableItems AS GoodsTable
		|		INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
		|		ON TableOfIndicators.Ref IN (VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
		|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip))
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND NOT &Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	AND NOT GoodsTable.Canceled
		|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|
		|ORDER BY
		|	LineNumber,
		|	Factor";
		
	Else
		Return "";
	EndIf;
	
	If DocumentObject = Undefined Then
		
		QueryText = StrReplace(QueryText, "DocumentDataTableItems", "Document.SalesOrder.Goods");
		QueryText = StrReplace(QueryText, "GoodsTable.ProductsTypeOfProducts", "GoodsTable.Products.ItemsType");
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If DocumentObject.Status = Enums.SalesOrderStatuses.NotApproved
	 Or Not DocumentObject.DeliveryIsRequired
	 Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.SelfPickup
	 Or DocumentObject.DeliveryMethod25 = Enums.TransportMethods25.OurCourier Then
		Return "";
	EndIf;
	
	If DocumentObject.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then
		
		QueryText =
		"SELECT
		|	DocumentHeader.DeliveryPlanning AS DeliveryPlanning,
		|	TableForDelivery.LineNumber AS LineNumber,
		|	BEGINOFPERIOD(&Period, DAY) AS Period,
		|	DocumentHeader.Organization AS Organization,
		|	VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
		|	GoodsTable.DateOfShipment AS DateOfShipment,
		|	TableForDelivery.DeliveryMethod AS DeliveryMethod,
		|	CASE
		|		WHEN TableForDelivery.DeliveryMethod = VALUE(Enum.TransportMethods25.ByCarrier)
		|			THEN TableForDelivery.Carrier
		|		ELSE VALUE(Catalog.Partners.EmptyRef)
		|	END AS Carrier,
		|	GoodsTable.Warehouse AS Sender,
		|	ISNULL(TableWarehousesDeliveryDetails.WarehousePoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS SenderPoint,
		|	ISNULL(TableWarehousesDeliveryDetails.AreaOfWarehouse, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Sender_Area,
		|	CASE
		|		WHEN TableForDelivery.DeliveryToCarrier
		|			THEN TableForDelivery.Carrier
		|		ELSE DocumentHeader.Partner
		|	END AS Recipient,
		|	CASE
		|		WHEN TableForDelivery.DeliveryToCarrier
		|			THEN TableForDelivery.CarrierDeliveryPoint
		|		ELSE TableForDelivery.DeliveryPoint
		|	END AS RecipientPoint,
		|	CASE
		|		WHEN TableForDelivery.DeliveryToCarrier
		|			THEN TableForDelivery.CarrierSDeliveryArea
		|		ELSE TableForDelivery.DeliveryZone
		|	END AS Recipient_Area,
		|	&Ref AS ReferenceOrder,
		|	UNDEFINED AS Trip,
		|	GoodsTable.Products AS Products,
		|	GoodsTable.Characteristic AS Characteristic,
		|	GoodsTable.Series AS Series,
		|	TableForDelivery.RowCode AS RowCode,
		|	CASE
		|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|			THEN &Ref
		|		ELSE UNDEFINED
		|	END AS PlanningDocument,
		|	1 AS Arm,
		|	GoodsTable.Package AS Package,
		|	GoodsTable.Count AS ToDeliver,
		|	CASE
		|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|			THEN GoodsTable.Count
		|		ELSE 0
		|	END AS ToTrip,
		|	0 AS InTrip,
		|	0 AS InTransit,
		|	0 AS Delivered,
		|	0 AS Canceled,
		|	0 AS ForAssembly,
		|	0 AS AssemblyInProgress,
		|	0 AS Assembled,
		|	&OperationLevel AS OperationLevel,
		|	NOT TableForDelivery.DeliveryToCarrier AS ThisIsFinalArm,
		|	1 AS MinimumArmNumber,
		|	TRUE AS PrimaryRegisterRecord,
		|	GoodsTable.DateOfShipment AS SourceShipmentDate,
		|	CASE
		|		WHEN GoodsTable.WithAssignment
		|			THEN DocumentHeader.Purpose
		|		ELSE &DefaultAssignment
		|	END AS Purpose
		|FROM
		|	Document.SalesOrder.GoodsToDeliver AS TableForDelivery
		|		INNER JOIN Document.SalesOrder.Goods AS GoodsTable
		|		ON TableForDelivery.Ref = GoodsTable.Ref
		|			AND TableForDelivery.RowCode = GoodsTable.RowCode
		|			AND (GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
		|		LEFT JOIN Document.SalesOrder AS DocumentHeader
		|		ON TableForDelivery.Ref = DocumentHeader.Ref
		|		LEFT JOIN Document.SalesOrder.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
		|		ON (GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref)
		|			AND (GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse)
		|WHERE
		|	TableForDelivery.Ref = &Ref
		|	AND &DeliveryIsRequired
		|	AND &DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ByRows)
		|	AND TableForDelivery.DeliveryMethod <> VALUE(Enum.TransportMethods25.SelfPickup)
		|	AND TableForDelivery.DeliveryMethod <> VALUE(Enum.TransportMethods25.OurCourier)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentHeader.DeliveryPlanning,
		|	TableForDelivery.LineNumber,
		|	BEGINOFPERIOD(&Period, DAY),
		|	DocumentHeader.Organization,
		|	VALUE(Enum.DeliveryTypes.OutgoingInfo),
		|	GoodsTable.DateOfShipment,
		|	VALUE(Enum.TransportMethods25.ByCarrier),
		|	TableForDelivery.Carrier,
		|	TableForDelivery.Carrier,
		|	TableForDelivery.CarrierDeliveryPoint,
		|	TableForDelivery.CarrierSDeliveryArea,
		|	DocumentHeader.Partner,
		|	TableForDelivery.DeliveryPoint,
		|	TableForDelivery.DeliveryZone,
		|	&Ref,
		|	UNDEFINED,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Series,
		|	TableForDelivery.RowCode,
		|	CASE
		|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|			THEN &Ref
		|		ELSE UNDEFINED
		|	END,
		|	2,
		|	GoodsTable.Package,
		|	GoodsTable.Count,
		|	CASE
		|		WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|			THEN GoodsTable.Count
		|		ELSE 0
		|	END,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	0,
		|	&OperationLevel,
		|	TRUE,
		|	0,
		|	FALSE,
		|	DATETIME(1, 1, 1),
		|	VALUE(Catalog.Assignments.EmptyRef)
		|FROM
		|	Document.SalesOrder.GoodsToDeliver AS TableForDelivery
		|		INNER JOIN Document.SalesOrder.Goods AS GoodsTable
		|		ON TableForDelivery.Ref = GoodsTable.Ref
		|			AND TableForDelivery.RowCode = GoodsTable.RowCode
		|			AND (GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship))
		|		LEFT JOIN Document.SalesOrder AS DocumentHeader
		|		ON TableForDelivery.Ref = DocumentHeader.Ref
		|		LEFT JOIN Document.SalesOrder.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
		|		ON (GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref)
		|			AND (GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse)
		|WHERE
		|	TableForDelivery.Ref = &Ref
		|	AND TableForDelivery.DeliveryToCarrier
		|	AND &DeliveryIsRequired
		|	AND &DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ByRows)
		|	AND TableForDelivery.DeliveryMethod <> VALUE(Enum.TransportMethods25.SelfPickup)
		|	AND TableForDelivery.DeliveryMethod <> VALUE(Enum.TransportMethods25.OurCourier)";
		
	EndIf;
	
	If DocumentObject.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ForWholeDocument Then
		
		QueryText =
		"SELECT
		|	DataTable.LineNumber AS LineNumber,
		|	DataTable.Period AS Period,
		|	DataTable.Organization AS Organization,
		|	DataTable.DeliveryType AS DeliveryType,
		|	DataTable.DateOfShipment AS DateOfShipment,
		|	DataTable.DeliveryMethod AS DeliveryMethod,
		|	DataTable.Carrier AS Carrier,
		|	DataTable.Sender AS Sender,
		|	DataTable.SenderPoint AS SenderPoint,
		|	DataTable.Sender_Area AS Sender_Area,
		|	DataTable.Recipient AS Recipient,
		|	DataTable.RecipientPoint AS RecipientPoint,
		|	DataTable.Recipient_Area AS Recipient_Area,
		|	DataTable.ReferenceOrder AS ReferenceOrder,
		|	DataTable.Trip AS Trip,
		|	DataTable.Products AS Products,
		|	DataTable.Characteristic AS Characteristic,
		|	DataTable.Series AS Series,
		|	DataTable.RowCode AS RowCode,
		|	DataTable.PlanningDocument AS PlanningDocument,
		|	DataTable.Arm AS Arm,
		|	DataTable.Package AS Package,
		|	DataTable.ToDeliver AS ToDeliver,
		|	DataTable.ToTrip AS ToTrip,
		|	DataTable.InTrip AS InTrip,
		|	DataTable.InTransit AS InTransit,
		|	DataTable.Delivered AS Delivered,
		|	DataTable.Canceled AS Canceled,
		|	DataTable.ForAssembly AS ForAssembly,
		|	DataTable.AssemblyInProgress AS AssemblyInProgress,
		|	DataTable.Assembled AS Assembled,
		|	&OperationLevel AS OperationLevel,
		|	DataTable.ThisIsFinalArm AS ThisIsFinalArm,
		|	DataTable.MinimumArmNumber AS MinimumArmNumber,
		|	DataTable.Arm = 1 AS PrimaryRegisterRecord,
		|	CASE
		|		WHEN DataTable.Arm = 1
		|			THEN DataTable.DateOfShipment
		|		ELSE DATETIME(1, 1, 1)
		|	END AS SourceShipmentDate,
		|	DataTable.Purpose AS Purpose
		|FROM
		|	(SELECT
		|		DocumentHeader.DeliveryPlanning AS DeliveryPlanning,
		|		GoodsTable.LineNumber AS LineNumber,
		|		BEGINOFPERIOD(&Period, DAY) AS Period,
		|		DocumentHeader.Organization AS Organization,
		|		VALUE(Enum.DeliveryTypes.OutgoingInfo) AS DeliveryType,
		|		GoodsTable.DateOfShipment AS DateOfShipment,
		|		DocumentHeader.DeliveryMethod25 AS DeliveryMethod,
		|		CASE
		|			WHEN DocumentHeader.DeliveryMethod25 = VALUE(Enum.TransportMethods25.ByCarrier)
		|				THEN DocumentHeader.CarrierPartner
		|			ELSE VALUE(Catalog.Partners.EmptyRef)
		|		END AS Carrier,
		|		GoodsTable.Warehouse AS Sender,
		|		ISNULL(TableWarehousesDeliveryDetails.WarehousePoint, VALUE(Catalog.DeliveryPoints.EmptyRef)) AS SenderPoint,
		|		ISNULL(TableWarehousesDeliveryDetails.AreaOfWarehouse, VALUE(Catalog.DeliveryZones.EmptyRef)) AS Sender_Area,
		|		CASE
		|			WHEN DocumentHeader.DeliveryToCarrier
		|				THEN DocumentHeader.CarrierPartner
		|			ELSE DocumentHeader.Partner
		|		END AS Recipient,
		|		CASE
		|			WHEN DocumentHeader.DeliveryToCarrier
		|				THEN DocumentHeader.CarrierDeliveryPoint
		|			ELSE DocumentHeader.DeliveryPoint
		|		END AS RecipientPoint,
		|		CASE
		|			WHEN DocumentHeader.DeliveryToCarrier
		|				THEN DocumentHeader.CarrierSDeliveryArea
		|			ELSE DocumentHeader.DeliveryZone
		|		END AS Recipient_Area,
		|		&Ref AS ReferenceOrder,
		|		UNDEFINED AS Trip,
		|		GoodsTable.Products AS Products,
		|		GoodsTable.Characteristic AS Characteristic,
		|		GoodsTable.Series AS Series,
		|		GoodsTable.RowCode AS RowCode,
		|		CASE
		|			WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END AS PlanningDocument,
		|		1 AS Arm,
		|		GoodsTable.Package AS Package,
		|		CASE
		|			WHEN GoodsTable.WithAssignment
		|				THEN DocumentHeader.Purpose
		|			ELSE &DefaultAssignment
		|		END AS Purpose,
		|		GoodsTable.Count AS ToDeliver,
		|		CASE
		|			WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|				THEN GoodsTable.Count
		|			ELSE 0
		|		END AS ToTrip,
		|		0 AS InTrip,
		|		0 AS InTransit,
		|		0 AS Delivered,
		|		0 AS Canceled,
		|		0 AS ForAssembly,
		|		0 AS AssemblyInProgress,
		|		0 AS Assembled,
		|		NOT DocumentHeader.DeliveryToCarrier AS ThisIsFinalArm,
		|		1 AS MinimumArmNumber
		|	FROM
		|		Document.SalesOrder.Goods AS GoodsTable
		|			LEFT JOIN Document.SalesOrder AS DocumentHeader
		|			ON GoodsTable.Ref = DocumentHeader.Ref
		|			LEFT JOIN Document.SalesOrder.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
		|			ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
		|				AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
		|	WHERE
		|		GoodsTable.Ref = &Ref
		|		AND &DeliveryIsRequired
		|		AND &DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ForWholeDocument)
		|		AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
		|		AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
		|		AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND NOT GoodsTable.Canceled
		|		AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		DocumentHeader.DeliveryPlanning,
		|		GoodsTable.LineNumber,
		|		BEGINOFPERIOD(&Period, DAY),
		|		DocumentHeader.Organization,
		|		VALUE(Enum.DeliveryTypes.OutgoingInfo),
		|		GoodsTable.DateOfShipment,
		|		VALUE(Enum.TransportMethods25.ByCarrier),
		|		DocumentHeader.CarrierPartner,
		|		DocumentHeader.CarrierPartner,
		|		DocumentHeader.CarrierDeliveryPoint,
		|		DocumentHeader.CarrierSDeliveryArea,
		|		DocumentHeader.Partner,
		|		DocumentHeader.DeliveryPoint,
		|		DocumentHeader.DeliveryZone,
		|		&Ref,
		|		UNDEFINED,
		|		GoodsTable.Products,
		|		GoodsTable.Characteristic,
		|		GoodsTable.Series,
		|		GoodsTable.RowCode,
		|		CASE
		|			WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|				THEN &Ref
		|			ELSE UNDEFINED
		|		END,
		|		2,
		|		GoodsTable.Package,
		|		VALUE(Catalog.Assignments.EmptyRef),
		|		GoodsTable.Count,
		|		CASE
		|			WHEN DocumentHeader.DeliveryPlanning = VALUE(Enum.DeliveryPlanningKinds.ByCurrentDocument)
		|				THEN GoodsTable.Count
		|			ELSE 0
		|		END,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		0,
		|		TRUE,
		|		0
		|	FROM
		|		Document.SalesOrder.Goods AS GoodsTable
		|			LEFT JOIN Document.SalesOrder AS DocumentHeader
		|			ON GoodsTable.Ref = DocumentHeader.Ref
		|			LEFT JOIN Document.SalesOrder.WarehousesDeliveryInformation AS TableWarehousesDeliveryDetails
		|			ON GoodsTable.Ref = TableWarehousesDeliveryDetails.Ref
		|				AND GoodsTable.Warehouse = TableWarehousesDeliveryDetails.Warehouse
		|	WHERE
		|		GoodsTable.Ref = &Ref
		|		AND &DeliveryIsRequired
		|		AND &DeliverySpecificationMethod = VALUE(Enum.DeliverySpecificationMethods.ForWholeDocument)
		|		AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.SelfPickup)
		|		AND &DeliveryMethod25 <> VALUE(Enum.TransportMethods25.OurCourier)
		|		AND GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
		|		AND NOT GoodsTable.Canceled
		|		AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|		AND DocumentHeader.DeliveryToCarrier) AS DataTable";
		
	EndIf;
	
	QueryText = StrReplace(QueryText, "Document.SalesOrder.Goods AS", "DocumentDataTableItems AS");
	QueryText = StrReplace(QueryText, "Document.SalesOrder AS DocumentHeader", "DocumentDataHeader AS DocumentHeader");
	QueryText = StrReplace(QueryText, "GoodsTable.Products.ItemsType", "GoodsTable.ProductsTypeOfProducts");
	QueryText = StrReplace(QueryText, "&DefaultAssignment", "VALUE(Catalog.Assignments.EmptyRef)");
	
	SynonymForDocumentTable = "DeliveryTable";
	GoodsDelivery.SetParametersOfEventRequest(Query, AddlParameters);
	GoodsDelivery.AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryText, SynonymForDocumentTable);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPaymentControl(Query, QueryTexts)
	
	RegisterName = "TTPaymentControl";
	QueryText =
		"SELECT
		|    MIN(
		|        CASE
		|            WHEN HeaderData_.Status  IN(
		|                VALUE(Enum.SalesOrderStatuses.ToSupply),
		|                VALUE(Enum.SalesOrderStatuses.ToShip)) THEN
		|                   
		|                    NOT GoodsTable.SupplyOption IN(
		|                        VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|                        VALUE(Enum.SupplyOptions.ToSupply),
		|                        VALUE(Enum.SupplyOptions.Ship))
		|                ELSE
		|                    TRUE
		|            END) AS ExcludeAdvancePaymentDuringControl,
		|    MIN(
		|        CASE
		|            WHEN HeaderData_.Status  IN(
		|                VALUE(Enum.SalesOrderStatuses.ToSupply),
		|                VALUE(Enum.SalesOrderStatuses.ToShip)) THEN
		|                   
		|                    GoodsTable.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|                ELSE
		|                    TRUE
		|            END) AS ExcludePrepaymentDuringControl
		|INTO TTPaymentControl
		|FROM
		|	Document.SalesOrder.Goods AS GoodsTable
		|		LEFT JOIN Document.SalesOrder AS HeaderData_
		|		ON GoodsTable.Ref = HeaderData_.Ref
		|WHERE
		|	GoodsTable.Ref IN(&Ref)";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectReserve(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (Not DocumentObject.ThisIsOrderAsInvoice 
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting) Then
		Return;
	EndIf;
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	CASE 
	|		WHEN DocumentGoods.DateOfShipment <> DATETIME(1, 1, 1) 
	|			THEN DocumentGoods.DateOfShipment
	|		ELSE HeaderData_.Date
	|	END								AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	DocumentDataTableItems AS DocumentGoods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	(DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.FromWarehouse)
	|		OR DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			AND HeaderData_.Status = VALUE(Enum.SalesOrderStatuses.NotApproved))
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ReflectReserve(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers, DocumentObject)
	
	If Not (Not DocumentObject.ThisIsOrderAsInvoice 
			And DocumentObject.BusinessOperation <> Enums.BusinessTransactions.SaleToCustomerLocalAccounting
			And DocumentObject.Status <> Enums.SalesOrderStatuses.NotApproved) Then
		Return;
	EndIf;
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref				AS Ref,
	|	DocumentGoods.DateOfShipment		AS Period,
	|	DocumentGoods.Ref				AS OrderDocument,
	|	UNDEFINED						AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	HeaderData_.Partner					AS Recipient,
	|	DocumentGoods.Warehouse				AS Warehouse,
	|	DocumentGoods.Products		AS Products,
	|	DocumentGoods.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN DocumentGoods.WithAssignment
	|			THEN HeaderData_.Purpose
	|		ELSE &DefaultAssignment
	|	END								AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series				AS Series,
	|	DocumentGoods.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	DocumentGoods.Count			AS Count,
	|	FALSE								AS ExceedingOrder,
	|	DocumentGoods.Canceled			AS Canceled,
	|	FALSE								AS ThisIsAnInvoice,
	|	TRUE								AS ShipmentByOrder
	|FROM
	|	DocumentDataTableItems AS DocumentGoods
	|		LEFT JOIN DocumentDataHeader AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|	AND DocumentGoods.Count <> 0";
	
	TextOfDocumentDataRequest = StrReplace(TextOfDocumentDataRequest,
												"&DefaultAssignment",
												"VALUE(Catalog.Assignments.EmptyRef)");
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS PlannedConsumptionOfDistributedStock,
		|	TRUE AS ControlOfFreeResidue
		|FROM
		|	Document.SalesOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|	AND TabPart.Ref.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	AND TabPart.SupplyOption = VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref                                     AS Ref,
		|	TabPart.Ref.Date                                AS Period,
		|	TabPart.Products                               AS Products,
		|	TabPart.Characteristic                             AS Characteristic,
		|	
		|	CASE WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) THEN
		|			TabPart.Department
		|		ELSE
		|			TabPart.Warehouse
		|		END AS Warehouse,
		|	
		|	CASE WHEN TabPart.WithAssignment THEN
		|				
		|				TabPart.Ref.Purpose
		|				
		|			ELSE VALUE(Catalog.Assignments.EmptyRef)
		|		END AS Purpose,
		|	
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count                                 AS Count,
		|	TabPart.SupplyOption                         AS SupplyOption,
		|	TabPart.Ref                                     AS OrderDocument,
		|	
		|	CASE WHEN TabPart.Ref.NotShipInInstallments THEN
		|				TabPart.Ref.DateOfShipment
		|			ELSE
		|				TabPart.DateOfShipment
		|		END AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.SalesOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved)
		|		AND TabPart.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN TabPart.Department
		|		ELSE TabPart.Warehouse
		|	END AS Warehouse,
		|	CASE
		|		WHEN TabPart.WithAssignment
		|			THEN TabPart.Ref.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	CASE
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND TabPart.WithAssignment
		|			THEN VALUE(Enum.SupplyOptions.ToSupply)
		|		WHEN TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|		AND NOT TabPart.WithAssignment
		|			THEN VALUE(Enum.SupplyOptions.NotRequired)
		|		ELSE VALUE(Enum.SupplyOptions.FromWarehouse)
		|	END AS SupplyOption,
		|	TabPart.Ref AS OrderDocument,
		|	CASE
		|		WHEN TabPart.Ref.NotShipInInstallments
		|			THEN TabPart.Ref.DateOfShipment
		|		ELSE TabPart.DateOfShipment
		|	END AS RequestShipmentOn,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.SalesOrder.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Canceled
		|		AND TabPart.Ref.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|		AND TabPart.SupplyOption IN(
		|			VALUE(Enum.SupplyOptions.Ship),
		|			VALUE(Enum.SupplyOptions.FromWarehouse))";
	
	StockAllocationRecords.PlanStockConsumption(
		Query,
		QueryTexts,
		Registers,
		QueryTextTabPart,
		False);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.SalesOrder";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("NumberAccordingToCustomerData", """""");
	
	If RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTPaymentControl", QueryTexts) Then
		QueryTextTTPaymentControl(Query, QueryTexts);
	EndIf;
	
	If Not (DocumentObject.Status <> Enums.SalesOrderStatuses.NotApproved
			And Not (DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent
			Or DocumentObject.BusinessOperation = Enums.BusinessTransactions.TransferToStorageWithRightOfSale)) Then
		
		TextPaymentPlans = "";
		
	Else
		
	TextPaymentPlans =
		"SELECT
		|	Table.Ref                                                                 AS Ref,
		|	DocumentDataHeader.Organization                                               AS Organization,
		|	DocumentDataHeader.Partner                                                   AS Partner,
		|	
		|	DocumentDataHeader.ARAPObject                                            AS ARAPObject,
		|	DocumentDataHeader.Date                                                      AS RecorderDate,
		|	DocumentDataHeader.Number                                                     AS RecorderNumber,
		|	DocumentDataHeader.ARAPObjectSettings                                           AS ARAPObjectSettings,
		|	DocumentDataHeader.Currency                                                    AS ARAPCurrency,
		|	DocumentDataHeader.Currency                                                    AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder)       AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod                                               AS PaymentMethod,
		|	
		|	Table.PaymentDate                                                      AS PaymentDate,
		|	Table.PaymentOption                                                    AS PaymentOption,
		|	Table.PaymentAmount + Table.PackageDepositValue                         AS AmountDue,
		|	Table.MeasuringGoodsVarianceAmount                                     AS MeasuringGoodsVarianceAmount,
		|		
		|	CASE
		|		WHEN DocumentDataHeader.Status = VALUE(Enum.SalesOrderStatuses.Closed)
		|			AND Table.PaymentOption IN (
		|				VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision),
		|				VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment))
		|			THEN FALSE
		|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|			THEN PaymentControl.ExcludeAdvancePaymentDuringControl
		|		WHEN Table.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|			THEN PaymentControl.ExcludePrepaymentDuringControl
		|		ELSE TRUE
		|	END                                                                    AS ExcludeDuringControl
		|	
		|FROM
		|	DocumentDataTableStagesOfPaymentSchedule AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|		LEFT JOIN TTPaymentControl AS PaymentControl
		|			ON (TRUE)
		|WHERE
		|	DocumentDataHeader.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	AND NOT DocumentDataHeader.BusinessOperation IN(VALUE(Enum.BusinessTransactions.TransferToCommissionAgent),
		|												VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale))";
	
	EndIf;
	
	If Not ((DocumentObject.Status = Enums.SalesOrderStatuses.ToSupply 
			Or DocumentObject.Status = Enums.SalesOrderStatuses.ToShip
			Or DocumentObject.Status = Enums.SalesOrderStatuses.Closed)) Then
		
		TextShipmentPlans = "";
		
	Else
		
	TextShipmentPlans =
		"SELECT
		|	Table.Ref                                    AS Ref,
		|	DocumentDataHeader.Organization                  AS Organization,
		|	DocumentDataHeader.Partner                      AS Partner,
		|	
		|	DocumentDataHeader.ARAPObject               AS ARAPObject,
		|	ENDOFPERIOD(Table.DateOfShipment, DAY)          AS DateOfShipment,
		|	Table.AmountIncludingVAT                                 AS IncreaseToBeSHIPPED,
		|	CASE
		|		WHEN DocumentDataHeader.BusinessOperation IN (
		|			VALUE(Enum.BusinessTransactions.SaleToCustomer),
		|			VALUE(Enum.BusinessTransactions.SaleWithDeferredTransferOfTitle),
		|			VALUE(Enum.BusinessTransactions.DeliveryForPrincipal))
		|		AND Table.SupplyOption =
		|				VALUE(Enum.SupplyOptions.Ship)
		|			THEN Table.AmountIncludingVAT
		|		ELSE 0
		|	END                                             AS IncreaseShipping,
		|	DocumentDataHeader.Date                         AS RecorderDate,
		|	DocumentDataHeader.Number                        AS RecorderNumber,
		|	DocumentDataHeader.ARAPObjectSettings              AS ARAPObjectSettings,
		|	DocumentDataHeader.Currency                       AS ARAPCurrency,
		|	DocumentDataHeader.Currency                       AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
		|	DocumentDataHeader.PaymentMethod                  AS PaymentMethod
		|	
		|FROM
		|	DocumentDataTableItems AS Table
		|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
		|			ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	NOT Table.Canceled
		|	AND Table.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
		|	AND (Table.ProductsTypeOfProducts <> VALUE(Enum.ItemsTypes.ReusablePackage)
		|		OR DocumentDataHeader.PackageDepositIsRequired
		|		OR NOT DocumentDataHeader.ToReturnReusablePackage)
		|	AND NOT &BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale)
		|	AND NOT (&BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent) 
		|		AND &ConsignmentSales25)";

	EndIf;
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans);
	
EndProcedure

// Returns a table of settlement amounts broken down by container/non-container and broken down by order.
// 
// Parameters:
//  ObjectReference_ - DocumentRef.SalesOrder - The document for which you want to get the data.
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
	|	Goods.Canceled            AS Canceled,
	|	&ToReturnReusablePackage AS ToReturnReusablePackage,
	|	&PackageDepositIsRequired      AS PackageDepositIsRequired
	|INTO TTProducts_1
	|FROM &ValueTable AS Goods
	|WHERE &LinkCondition_
	|	
	|;
	|SELECT 
	|	Goods.Ref                                    AS OrderDocument,
	|	Goods.Date                                      AS Date,
	|	Goods.ApprovalDate                          AS ApprovalDate,
	|	Goods.DateOfShipment                              AS DateOfShipment,
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
	|		END )         AS PackageDepositValue,
	|	0                                                AS AmountARAPByPackage
	|FROM
	|	TTProducts_1 AS Goods
	|WHERE
	|	NOT Goods.Canceled
	|GROUP BY
	|	Goods.DateOfShipment,
	|	Goods.Ref,
	|	Goods.Date,
	|	Goods.ApprovalDate
	|;";
	
	If AttributesValues = Undefined Then
		Query.Text = StrReplace(Query.Text, "&ValueTable", "Document.SalesOrder.Goods");
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

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReportCommand = Reports.PriceAnalysis.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm";
	EndIf;
	
	Reports.RevenueAndCOGS.AddOrderSalesTeam(ReportsCommands);
	
	If PriceManagementSystemServerCall.UsePriceManagementSystem25() Then
		Reports.SalesProfitabilityAssessment2_5.AddReportCommand(ReportsCommands);
	Else
		Reports.SalesProfitabilityAssessment.AddReportCommand(ReportsCommands);
	EndIf;
	
	Reports.DiscountsAppliedInDocument.AddReportCommand(ReportsCommands);
	
	ReportCommand = Reports.SaleApprovalResults.AddCustomerOrderApprovalResultsCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "ListForm";
	EndIf;
	
	ReportCommand = Reports.DocumentFulfillmentStatus.AddOrderFulfillmentStateCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm, SelfServiceWorkplaceDocumentForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentForm,ListForm";
	EndIf;
	
	// DocumentsListForm
	ReportCommand = Reports.DocumentFulfillmentStatus.AddOrderFulfillmentStateCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm,SelfServiceWorkplaceListForm";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = DataProcessors.OrderSupplyForecast.AddCommandStateOfCustomerOrderListProvision(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "SelfServiceWorkplaceListForm";
		ReportCommand.FormParameters.Insert("ReadOnly", True);
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.CustomerDebt_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = ARAPAccountingServer.PaymentCardWithClient_AddDocumentReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "Ordinary";
		ReportCommand.Order = 2;
	EndIf;
	
	ReportCommand = Reports.VariancesFromSalesTermsAndConditions.AddReportCommand(ReportsCommands);
	If ReportCommand <> Undefined Then
		ReportCommand.VisibilityInForms = "DocumentsListForm";
		ReportCommand.Importance = "SeeAlso";
		ReportCommand.Order = 1;
	EndIf;
	
	ReportCommand = Reports.SaleApprovalResults.AddCustomerOrderApprovalResultsCommand(ReportsCommands);
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
	
	SalesOrderLocalization.AddReportCommands(ReportsCommands, Parameters);

	ReportCommand = Reports.StateOfDelivery.AddReportCommand(
		ReportsCommands,
		Parameters,
		"DeliveryStateContext");
	
	If ReportCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			Metadata.Documents.SalesOrder.Attributes.DeliveryIsRequired.Name,
			True);
		
		AttachableCommands.AddCommandVisibilityCondition(
			ReportCommand,
			Metadata.Documents.SalesOrder.Attributes.Organization.Name,
			Catalogs.Companies.ManagementCompany,
			DataCompositionComparisonType.NotEqual);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If UserRightsCached.ThisIsPartner() Then
		
		// Sales order
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "SalesOrder";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Satış siparişi'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
										|ru = 'Счет на оплату с факсимиле';
										|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
										|it = 'Fattura di pagamento in facsimile';
										|pl = 'Rachunek do płatności z faksymile';
										|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
		
		Return;
		
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Sales order
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "SalesOrder";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказ клиента';
										|en = 'Sales order'; fa = 'سفارش فروش';
										|it = 'Ordine del cliente';
										|pl = 'Zamówienie klienta';
										|tr = 'Satış siparişi'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Customer's order (do not display discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "CustomerOrderWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng của khách (không hiển thị chiết khấu)';
										|ru = 'Заказ клиента (не выводить скидки)';
										|en = 'Sales order (do not display discounts)'; fa = 'Sales order (do not display discounts)';
										|it = 'Ordine del cliente (non visualizzare gli sconti)';
										|pl = 'Zamówienie sprzedaży (nie wyprowadzaj rabaty)';
										|tr = 'Satış siparişi (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Customer's order (display discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintOrderForGoodsServices";
		PrintCommand.Id = "SalesOrder";
		PrintCommand.Presentation = NStr("vi = 'Đơn hàng của khách (hiển thị chiết khấu)';
										|ru = 'Заказ клиента (выводить скидки)';
										|en = 'Sales order (display discounts)'; fa = 'Sales order (display discounts)';
										|it = 'Ordine del cliente (visualizzare gli sconti)';
										|pl = 'Zamówienie sprzedaży (wyprowadzaj rabaty)';
										|tr = 'Satış siparişi (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán';
										|ru = 'Счет на оплату';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Fattura di pagamento';
										|pl = 'Rachunek do zapłaty';
										|tr = 'Ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceForPaymentWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
										|ru = 'Счет на оплату (не выводить скидки)';
										|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
										|it = 'Fattura di pagamento (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoice";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
										|ru = 'Счет на оплату (выводить скидки)';
										|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
										|it = 'Fattura di pagamento (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności (wyświetlać zniżki)';
										|tr = 'Ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax';
										|ru = 'Счет на оплату с факсимиле';
										|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
										|it = 'Fattura di pagamento in facsimile';
										|pl = 'Rachunek do płatności z faksymile';
										|tr = 'Kaşeli ticari fatura'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (do not withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "InvoiceWithFacsimileWithoutDiscounts";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
										|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
										|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", False);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		// Invoice for payment (withdraw discounts)
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceWithFacsimile";
		PrintCommand.Presentation = NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
										|ru = 'Счет на оплату с факсимиле (выводить скидки)';
										|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
										|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
										|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
										|tr = 'Kaşeli ticari fatura (indirimleri göster)'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.AdditionalParameters.Insert("DisplayDiscounts_", True);
		PrintCommand.AdditionalParameters.Insert("DisplayFacsimiles", True);
		PrintCommand.AdditionalParameters.Insert("UseSynonymForKit", False);
		PrintCommand.AdditionalParameters.Insert("SynonymForTemplateForKit", PrintCommand.Presentation);
	EndIf;

	If Constants.UseInternationalPrintingForms.Get() Then
		
		// Proforma invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Id = "ProformaInvoiceEn";
		PrintCommand.Presentation = NStr("vi = 'Proforma invoice (en)';
										|ru = 'Proforma invoice (en)';
										|en = 'Proforma invoice (en)'; fa = 'Proforma invoice (en)';
										|it = 'Proforma invoice (en)';
										|pl = 'Proforma invoice (en)';
										|tr = 'Proforma invoice (en)'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	
	// Task for the selection of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "SelectionTask");
	PrintCommand.AdditionalParameters.Insert("PrintingFromDocumentData");
	
	AttachableCommands.AddCommandVisibilityCondition(PrintCommand,
														"Status",
														Enums.SalesOrderStatuses.NotApproved,
														DataCompositionComparisonType.NotEqual);
	
	
	SalesOrderLocalization.AddPrintCommands(PrintCommands);
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "SetOfDocuments") Then
		PrintFormsCollection.Clear();
		CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects);
	EndIf;
	
	SalesOrderLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

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
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Documents.Ref										AS Ref,
	|	Documents.Number											AS Number,
	|	Documents.Date											AS Date,
	|	Documents.DeliveryAddress									AS DeliveryAddress,
	|	Documents.Organization									AS Organization,
	|	Documents.Organization									AS Performer,
	|	CASE WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SalesByPatent)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef) 
	|			THEN FALSE
	|		ELSE TRUE
	|	END													AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	TRUE													AS ShowVAT,
	|	TRUE													AS UseAutoDiscounts,
	|	&DisplayAdditionalVATColumns									AS ShowNDSInRows,
	|	""""													AS Type,
	|	&PresentationOfDocument									AS PresentationOfDocument,
	|	&PresentationInError									AS PresentationInError,
	|	Documents.Organization.Prefix							AS Prefix,
	|	Documents.Counterparty									AS Counterparty,
	|	Documents.Counterparty									AS Customer_,
	|	Documents.BankAccount								AS BankAccount,
	|	Documents.BankAccount.CorrespondentText			AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT								AS PriceIncludesVAT,
	|	Documents.Currency										AS Currency,
	|	Documents.Manager.Individual						AS Manager,
	|	Documents.AdditionalInformation						AS AdditionalInformation,
	|	Documents.Shipper								AS Shipper,
	|	Documents.GoodsRecipient								AS GoodsRecipient
	|FROM
	|	Document.SalesOrder AS Documents
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1														AS Order,
	|	PaymentScheduleSteps.Ref								AS Ref,
	|	PaymentScheduleSteps.LineNumber							AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate							AS PaymentDate,
	|	PaymentScheduleSteps.PaymentOption						AS PaymentOption,
	|	PaymentScheduleSteps.PaymentPercentage						AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount							AS PaymentAmount,
	|	FALSE													AS ThisIsDepositForPackage
	|FROM
	|	Document.SalesOrder.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.PaymentAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	2														AS Order,
	|	PaymentScheduleSteps.Ref								AS Ref,
	|	PaymentScheduleSteps.LineNumber							AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate							AS PaymentDate,
	|	PaymentScheduleSteps.PaymentOption						AS PaymentOption,
	|	PaymentScheduleSteps.PackageDepositPercentage					AS PaymentPercentage,
	|	PaymentScheduleSteps.PackageDepositValue					AS PaymentAmount,
	|	TRUE													AS ThisIsDepositForPackage
	|FROM
	|	Document.SalesOrder.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.Ref.PackageDepositIsRequired
	|	AND PaymentScheduleSteps.PackageDepositValue <> 0
	|
	|ORDER BY
	|	LineNumber,
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.LineNumber                                     AS LineNumber,
	|	Table.Products                                    AS Products,
	|	Table.Package                                        AS Package,
	|
	|	Table.Count                                      AS Count,
	|	Table.NumberOfPackages                              AS NumberOfPackages,
	|
	|	CASE WHEN &DisplayDiscounts_ THEN
	|		Table.Price
	|	ELSE
	|		Table.Sum/Table.NumberOfPackages 
	|	END                                                   AS Price,
	|
	|	Table.Sum                                           AS Sum,
	|	Table.VATRate                                       AS VATRate,
	|	Table.VATAmount                                        AS VATAmount,
	|	Table.DateOfShipment                                    AS DateOfShipment,
	|	Table.Characteristic                                  AS Characteristic,
	|
	|	CASE WHEN &DisplayDiscounts_ THEN
	|		Table.ManualDiscount + Table.DiscountMarkupAmount
	|	ELSE
	|		0 
	|	END AS DiscountAmount,
	|
	|	Table.Sum + Table.ManualDiscount + Table.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	Table.Content AS Content,
	|
	|	CASE WHEN Table.Ref.ToReturnReusablePackage
	|			  AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ThisIsReusablePackage
	|
	|INTO Goods
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND Table.Canceled = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	MAX(Table.DateOfShipment) AS DateOfShipment,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE null
	|		END) AS VATRate,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                             AS Sum,
	|	Table.VATAmount                          AS VATAmount,
	|	Table.DateOfShipment                          AS DateOfShipment,
	|	Table.DiscountAmount                           AS DiscountAmount,
	|	Table.AmountWithoutADiscount                        AS AmountWithoutADiscount,
	|	TemporaryTableSetsOptional.VATRate AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	
	|	Goods.Ref											AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
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
	|	Goods.NumberOfPackages                                AS Count,
	|
	|	Goods.Price AS Price,
	|
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	Goods.DateOfShipment                                      AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	Goods.Content                                        AS Content,
	|
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|
	|FROM (
	|
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.DateOfShipment,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.Content,
	|		Table.ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.DateOfShipment,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		"""",
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Goods.Package",
		"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("PresentationOfDocument",	NStr("vi = 'đơn hàng của khách';
														|ru = 'заказа клиента';
														|en = 'Sales order'; fa = 'سفارش فروش';
														|it = 'ordine del cliente';
														|pl = 'zamówienia klienta';
														|tr = 'Satış siparişleri'", Common.DefaultLanguageCode()));
	Query.SetParameter("PresentationInError",	NStr("vi = 'đơn hàng của khách';
														|ru = 'заказа клиента';
														|en = 'sales order'; fa = 'sales order';
														|it = 'ordine del cliente';
														|pl = 'zamówienia klienta';
														|tr = 'Satış siparişleri'"));
	Query.SetParameter("DisplayAdditionalVATColumns", Constants.DisplayAdditionalVATColumns.Get());
	Query.SetParameter("LanguageCode", LanguageCode);
	Query.SetParameter("ThisIsMainLanguageOfSystem", LanguageCode = Common.DefaultLanguageCode() Or LanguageCode = Undefined);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

// The function receives data for generating a printed form " Notification"
//
// Parameters:
//	PrintParameters - Structure
//	ObjectsArray - Array - An array of references to documents, which is necessary to obtain the data.
//
// Returns:
// 	Structure:
// 		* HeaderResults - QueryResult
// 		* ResultsByPaymentStages - QueryResult
// 		* ResultForTabularPart - QueryResult
//
Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	If PrintParameters <> Undefined And PrintParameters.Property("DisplayDiscounts_") Then
		DisplayDiscounts_ = PrintParameters.DisplayDiscounts_;
	Else
		DisplayDiscounts_ = (Constants.DisplayDiscountsInPrintFormsOfSalesDocuments.Get()
			<> Enums.OptionsOfDiscountsDisplayingInPrintForms.NotDisplayDiscounts);
	EndIf; 
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.BankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SalesByPatent)
	|			OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.EmptyRef) 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd, 
	|	Documents.BankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.BankAccount.ForeignBank
	|		OR Documents.BankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.BankAccount.CashCurrency AS CashCurrency,
	|	
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankNameInt
	|		ELSE Documents.BankAccount.Bank.InternationalDescription END AS BankNameInt,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankNameForPaymentsInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalDescription END AS BankNameForPaymentsInt,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankSWIFTCode
	|		ELSE Documents.BankAccount.Bank.SWIFTBIC END AS BankSWIFTCode,
	|	CASE WHEN Documents.BankAccount.TransferBankDetailsManualEdit THEN Documents.BankAccount.BankSWIFTCodeForPayments
	|		ELSE Documents.BankAccount.TransferBank.SWIFTBIC END AS BankSWIFTCodeForPayments,
	|	CASE WHEN Documents.BankAccount.ManualBankDetailsChange THEN Documents.BankAccount.BankAddressInt
	|		ELSE Documents.BankAccount.Bank.InternationalAddress END AS BankAddress,
	|	CASE WHEN Documents.BankAccount.TransferBankDetailsManualEdit THEN Documents.BankAccount.BankAddressForPaymentInt
	|		ELSE Documents.BankAccount.TransferBank.InternationalAddress END AS TransferBankAddress,
	|	
	|	Documents.BankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.BankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.BankAccount.DigitalRoubleAccountID
	|		ELSE Documents.BankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN Documents.BankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.BankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.BankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.BankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.BankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.AdditionalInformation AS AdditionalInformation,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	Documents.PaymentPurposes AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.Shipper AS Shipper,
	|	Documents.GoodsRecipient AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.SalesOrder AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.BankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.BankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Documents.PointInTime
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	1														AS Order,
	|	PaymentScheduleSteps.Ref								AS Ref,
	|	PaymentScheduleSteps.LineNumber							AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate							AS PaymentDate,
	|	PaymentScheduleSteps.PaymentPercentage						AS PaymentPercentage,
	|	PaymentScheduleSteps.PaymentAmount							AS PaymentAmount,
	|	FALSE													AS ThisIsDepositForPackage
	|FROM
	|	Document.SalesOrder.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.PaymentAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	2														AS Order,
	|	PaymentScheduleSteps.Ref								AS Ref,
	|	PaymentScheduleSteps.LineNumber							AS LineNumber,
	|	PaymentScheduleSteps.PaymentDate							AS PaymentDate,
	|	PaymentScheduleSteps.PackageDepositPercentage					AS PaymentPercentage,
	|	PaymentScheduleSteps.PackageDepositValue					AS PaymentAmount,
	|	TRUE													AS ThisIsDepositForPackage
	|FROM
	|	Document.SalesOrder.PaymentScheduleSteps AS PaymentScheduleSteps
	|WHERE
	|	PaymentScheduleSteps.Ref IN(&ObjectsArray)
	|	AND PaymentScheduleSteps.Ref.PackageDepositIsRequired
	|	AND PaymentScheduleSteps.PackageDepositValue <> 0
	|
	|ORDER BY
	|	LineNumber,
	|	Order
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref AS Ref,
	|
	|	ProductKitConfigurations.Ref AS ItemKitConfiguration,
	|	ProductKitConfigurations.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ProductKitConfigurations.SetPricingOption AS SetPricingOption,
	|	Table.ProductsInSet                              AS ProductsInSet,
	|	Table.ItemVariantOfSet                            AS ItemVariantOfSet,
	|
	|	Table.LineNumber AS LineNumber,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Package AS Package,
	|	Table.Count AS Count,
	|	Table.NumberOfPackages AS NumberOfPackages,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.Price
	|		ELSE Table.Sum/Table.NumberOfPackages 
	|	END AS Price,
	|	Table.Sum AS Sum,
	|	Table.VATRate AS VATRate,
	|	Table.VATAmount AS VATAmount,
	|	Table.DateOfShipment AS DateOfShipment,
	|	CASE
	|		WHEN
	|			Table.Ref.ToReturnReusablePackage
	|			AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|	END AS ThisIsReusablePackage,
	|	CASE
	|		WHEN &DisplayDiscounts_ THEN
	|			Table.ManualDiscount + Table.DiscountMarkupAmount
	|		ELSE 0 
	|	END AS DiscountAmount,
	|	Table.Sum + Table.ManualDiscount + Table.DiscountMarkupAmount AS AmountWithoutADiscount,
	|	Table.Content AS Content
	|INTO Goods
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|
	|	LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ProductKitConfigurations.Owner = Table.ProductsInSet
	|		AND ProductKitConfigurations.Characteristic = Table.ItemVariantOfSet
	|		AND ProductKitConfigurations.Main
	|
	|WHERE
	|	Table.Ref IN(&ObjectsArray)
	|	AND Table.Canceled = FALSE
	|	AND (Table.Products.ItemsType <> VALUE(Enum.ItemsTypes.ReusablePackage)
	|		OR Table.Products.ItemsType = VALUE(Enum.ItemsTypes.ReusablePackage)
	|		AND (NOT Table.Ref.ToReturnReusablePackage OR Table.Ref.PackageDepositIsRequired))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS Ref,
	|	Table.ProductsInSet     AS ProductsInSet,
	|	Table.ItemVariantOfSet   AS ItemVariantOfSet,
	|	MIN(Table.LineNumber)   AS LineNumber,
	|	SUM(Table.Sum)           AS Sum,
	|	SUM(Table.VATAmount)        AS VATAmount,
	|	MAX(Table.DateOfShipment) AS DateOfShipment,
	|	SUM(Table.DiscountAmount)     AS DiscountAmount,
	|	SUM(Table.AmountWithoutADiscount)  AS AmountWithoutADiscount
	|INTO TemporaryTableSetsPreparation
	|FROM
	|	Goods AS Table
	|
	|WHERE
	|	Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfGoods.Ref AS Ref
	|INTO VariousGoods_
	|FROM
	|	Goods AS TableOfGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref                                    AS Ref,
	|	Goods.ItemKitConfiguration           AS ItemKitConfiguration,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet,
	|	Goods.ItemVariantOfSet,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CASE WHEN Goods.ItemKitConfiguration.ProductsOfMainComponent = Goods.Products
	|		AND Goods.ItemKitConfiguration.MainComponentCharacteristic = Goods.Characteristic THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS MainComponent,
	|	Goods.VATRate AS VATRate,
	|	0 AS DefaultQuantity,
	|	Goods.Count AS Count
	|INTO TemporaryTableSetsOptionalPartOne
	|FROM
	|	Goods AS Goods
	|
	|WHERE
	|	Goods.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VariousGoods_.Ref                                                                  AS Ref,
	|	ConfigurationOptionsForProductRange.Ref                                           AS ItemKitConfiguration,
	|	ConfigurationOptionsForProductRange.Ref.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	ConfigurationOptionsForProductRange.Ref.SetPricingOption                  AS SetPricingOption,
	|	ConfigurationOptionsForProductRange.Ref.Owner                                  AS ProductsInSet,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic                            AS ItemVariantOfSet,
	|	ConfigurationOptionsForProductRange.Products   AS Products,
	|	ConfigurationOptionsForProductRange.Characteristic AS Characteristic,
	|	FALSE AS MainComponent,
	|	NULL AS VATRate,
	|	SUM(ConfigurationOptionsForProductRange.Count) AS DefaultQuantity,
	|	0 AS Count
	|FROM
	|	Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		LEFT JOIN VariousGoods_ AS VariousGoods_
	|		ON TRUE
	|WHERE
	|	ConfigurationOptionsForProductRange.Ref IN (SELECT DISTINCT T.ItemKitConfiguration FROM Goods AS T)
	|
	|GROUP BY
	|	VariousGoods_.Ref,
	|	ConfigurationOptionsForProductRange.Ref,
	|	ConfigurationOptionsForProductRange.Ref.Owner,
	|	ConfigurationOptionsForProductRange.Ref.Characteristic,
	|	ConfigurationOptionsForProductRange.Products,
	|	ConfigurationOptionsForProductRange.Characteristic,
	|	ConfigurationOptionsForProductRange.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic,
	|	MAX(Table.VATRate) AS VATRate,
	|	MAX(Table.MainComponent) AS MainComponent,
	|	SUM(Table.DefaultQuantity) AS DefaultQuantity,
	|	SUM(Table.Count) AS Count
	|INTO TemporaryTableSetsOptionalPartTwo
	|FROM
	|	TemporaryTableSetsOptionalPartOne AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.ItemKitConfiguration,
	|	Table.SetPricingOption,
	|	Table.PresentationOptionInPrintForms,
	|	Table.ProductsInSet,
	|	Table.ItemVariantOfSet,
	|	Table.Products,
	|	Table.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet,
	|	MAX(CASE
	|			WHEN Result.MainComponent
	|				THEN Result.VATRate
	|			ELSE null
	|		END) AS VATRate,
	|	CAST(MIN(CASE
	|			WHEN Result.DefaultQuantity <> 0 AND Result.MainComponent
	|				THEN Result.Count / Result.DefaultQuantity
	|			ELSE null
	|		END) + 0.5 AS NUMBER(10,0)) - 1 AS Count
	|INTO TemporaryTableSetsOptional
	|FROM
	|	TemporaryTableSetsOptionalPartTwo AS Result
	|GROUP BY
	|	Result.Ref,
	|	Result.ItemKitConfiguration,
	|	Result.SetPricingOption,
	|	Result.PresentationOptionInPrintForms,
	|	Result.ProductsInSet,
	|	Result.ItemVariantOfSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableSetsOptional.ItemKitConfiguration,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale) THEN
	|		CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|		ELSE
	|			TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|	END AS PresentationOptionInPrintForms,
	|	CASE WHEN Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
	|			OR Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferToStorageWithRightOfSale) THEN
	|		CASE WHEN
	|			CASE WHEN TemporaryTableSetsOptional.PresentationOptionInPrintForms = VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet) THEN
	|				VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			ELSE
	|				TemporaryTableSetsOptional.PresentationOptionInPrintForms
	|			END = VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)
	|			AND TemporaryTableSetsOptional.SetPricingOption IN (VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToPrices),VALUE(Enum.SetPriceCalculationOptions.PriceAssignedForKitThenAllocatedToComponentsProportionallyToShares)) THEN
	|				VALUE(Enum.SetPriceCalculationOptions.CaclulatesFromComponentPrices)
	|		ELSE
	|			TemporaryTableSetsOptional.SetPricingOption
	|		END
	|	ELSE
	|		TemporaryTableSetsOptional.SetPricingOption
	|	END AS SetPricingOption,
	|	Table.Ref                            AS Ref,
	|	Table.ProductsInSet                AS ProductsInSet,
	|	Table.ItemVariantOfSet              AS ItemVariantOfSet,
	|	Table.LineNumber                       AS LineNumber,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS NumberOfPackages,
	|	ISNULL(TemporaryTableSetsOptional.Count, 1) AS Count,
	|	Table.Sum                                 AS Sum,
	|	Table.VATAmount                              AS VATAmount,
	|	Table.DateOfShipment                          AS DateOfShipment,
	|	Table.DiscountAmount                           AS DiscountAmount,
	|	Table.AmountWithoutADiscount                        AS AmountWithoutADiscount,
	|	TemporaryTableSetsOptional.VATRate AS VATRate
	|INTO TemporaryTableSets
	|FROM
	|	TemporaryTableSetsPreparation AS Table
	|		LEFT JOIN TemporaryTableSetsOptional AS TemporaryTableSetsOptional
	|		ON Table.ProductsInSet = TemporaryTableSetsOptional.ProductsInSet
	|		AND Table.ItemVariantOfSet = TemporaryTableSetsOptional.ItemVariantOfSet
	|		AND Table.Ref = TemporaryTableSetsOptional.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref											AS Ref,
	|	Goods.PresentationOptionInPrintForms AS PresentationOptionInPrintForms,
	|	Goods.SetPricingOption                  AS SetPricingOption,
	|	Goods.ProductsInSet								AS ProductsInSet,
	|	ISNULL(ProductsOfPresentationSet.DescriptionFull, Goods.ProductsInSet.DescriptionFull) AS ProductOfSetIsFullName,
	|	Goods.ItemVariantOfSet								AS ItemVariantOfSet,
	|	ISNULL(CharacteristicsOfProductOfPresentationSet.DescriptionFull, ISNULL(Goods.ItemVariantOfSet.DescriptionFull, """")) AS CharacteristicsOfSetFullName,
	|	Goods.IsRecordsSet AS IsRecordsSet,
	|	Goods.TheseAreComponents AS TheseAreComponents,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	ISNULL(ProductsPresentations.DescriptionFull, Goods.Products.DescriptionFull) AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	Goods.DateOfShipment                                      AS DateOfShipment,
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END                                                    AS Package,
	|
	|	Goods.DiscountAmount                                       AS DiscountAmount,
	|	Goods.AmountWithoutADiscount                                    AS AmountWithoutADiscount,
	|	Goods.Content                                        AS Content,
	|	Goods.ThisIsReusablePackage                                 AS ThisIsReusablePackage	
	|
	|FROM (
	|
	|	SELECT
	|		Table.Ref,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.PresentationOptionInPrintForms
	|		ELSE
	|			VALUE(Enum.OptionsOfSetPresentationInPrintForms.EmptyRef)
	|		END AS PresentationOptionInPrintForms,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.SetPricingOption
	|		ELSE
	|			VALUE(Enum.SetPriceCalculationOptions.EmptyRef)
	|		END AS SetPricingOption,
	|		Table.ProductsInSet,
	|		Table.ItemVariantOfSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TRUE
	|		ELSE
	|			FALSE
	|		END AS TheseAreComponents,
	|		FALSE AS IsRecordsSet,
	|		CASE WHEN ISNULL(TemporaryTableSets.LineNumber, 0) <> 0 THEN
	|			TemporaryTableSets.LineNumber
	|		ELSE
	|			Table.LineNumber
	|		END AS LineNumber,
	|		Table.Products,
	|		Table.Count,
	|		Table.NumberOfPackages,
	|		Table.Price,
	|		Table.Sum,
	|		Table.VATRate,
	|		Table.VATAmount,
	|		Table.DateOfShipment,
	|		Table.Characteristic,
	|		Table.Package,
	|		Table.DiscountAmount,
	|		Table.AmountWithoutADiscount,
	|		Table.Content,
	|		Table.ThisIsReusablePackage
	|	FROM
	|		Goods AS Table
	|			LEFT JOIN TemporaryTableSets AS TemporaryTableSets
	|			ON TemporaryTableSets.ProductsInSet = Table.ProductsInSet
	|			 AND TemporaryTableSets.ItemVariantOfSet = Table.ItemVariantOfSet
	|			 AND TemporaryTableSets.Ref = Table.Ref
	|
	|	WHERE
	|		Table.ProductsInSet = VALUE(Catalog.Products.EmptyRef)
	|		OR (Table.ProductsInSet <> VALUE(Catalog.Products.EmptyRef)
	|	        AND TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlyComponents),
	|	                                                                              VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents)))
	|
	|	UNION ALL
	|
	|	SELECT
	|		TemporaryTableSets.Ref,
	|		TemporaryTableSets.PresentationOptionInPrintForms,
	|		TemporaryTableSets.SetPricingOption AS SetPricingOption,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		FALSE AS TheseAreComponents,
	|		TRUE AS IsRecordsSet,
	|		TemporaryTableSets.LineNumber,
	|		TemporaryTableSets.ProductsInSet,
	|		TemporaryTableSets.Count,
	|		TemporaryTableSets.NumberOfPackages,
	|		CASE
	|			WHEN &DisplayDiscounts_ THEN
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.AmountWithoutADiscount) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|			ELSE
	|				CASE WHEN ISNULL(TemporaryTableSets.NumberOfPackages, 1) <> 0 THEN
	|					(TemporaryTableSets.Sum) / ISNULL(TemporaryTableSets.NumberOfPackages, 1)
	|				ELSE
	|					0
	|				END
	|		END AS Price,
	|		TemporaryTableSets.Sum AS Sum,
	|		TemporaryTableSets.VATRate,
	|		TemporaryTableSets.VATAmount,
	|		TemporaryTableSets.DateOfShipment,
	|		TemporaryTableSets.ItemVariantOfSet,
	|		VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|		TemporaryTableSets.DiscountAmount,
	|		TemporaryTableSets.AmountWithoutADiscount,
	|		"""",
	|		FALSE
	|	FROM
	|		TemporaryTableSets AS TemporaryTableSets
	|	WHERE
	|		TemporaryTableSets.PresentationOptionInPrintForms IN (VALUE(Enum.OptionsOfSetPresentationInPrintForms.OnlySet),
	|	                                                                        VALUE(Enum.OptionsOfSetPresentationInPrintForms.KitAndComponents))
	|) AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsOfPresentationSet
	|	ON (Goods.ProductsInSet = ProductsOfPresentationSet.Ref
	|			AND ProductsOfPresentationSet.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS CharacteristicsOfProductOfPresentationSet
	|	ON (Goods.ItemVariantOfSet = CharacteristicsOfProductOfPresentationSet.Ref
	|			AND CharacteristicsOfProductOfPresentationSet.LanguageCode = &LanguageCode)
	|
	|ORDER BY
	|	Goods.LineNumber,
	|	IsRecordsSet DESC
	|";
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("DisplayDiscounts_", DisplayDiscounts_);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

// Returns the document data structure used for printing the printed form of the product selection (placement) Task.
//
// Parameters:
//	PrintParameters	- Structure	- additional print options.
//	ObjectsArray	- Array	- links to objects that need to be printed.
//	
// Returns:
//	Structure - a structure with the following keys:
//		*ErrorResults			- QueryResult	- errors in document data that make it impossible
//															to print the document.
//		*ResultOnOrders	- Undefined		- information about orders for document shipment.
//		*HeaderResults			- QueryResult	- the data of the header of the document used for the print Job
//															in the selection of goods.
//		*ResultForTabularPart	- QueryResult	- data of the product part of the document used for printing
//															Job in the selection of goods.
//		*ResultForPackages		- QueryResult		- data about product packages in the tabular part of the document
//															used for printing the product selection Task.
//		*ResultBySeries			- Undefined		- data about product series in the table part of the document
//															that is used for printing the product selection Task.
//
Function GetDataForPrintedFormForProductPlacement(PrintParameters, ObjectsArray) Export
	
	QueryText =
	"SELECT DISTINCT
	|	TaskData_.Ref					AS Ref,
	|	PRESENTATION(TaskData_.Ref)		AS RefPresentation,
	|	TaskData_.Number						AS Number,
	|	TaskData_.Date						AS Date,
	|	UNDEFINED							AS NumberOfDocumentBeingCorrected,
	|	UNDEFINED							AS DateOfDocumentBeingCorrected,
	|	DocumentGoods.Warehouse					AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)		AS WarehousePresentation,
	|	&DefaultRoom					AS Premise,
	|	PRESENTATION(&DefaultRoom)	AS PremisePresentation,
	|	TRUE									AS ThisIsAnInvoice,
	|	FALSE									AS BinLocationWarehousingIsUsed,
	|	CASE
	|		WHEN DocumentGoods.Warehouse.UseBinLocationWarehousingForInformation
	|				AND (NOT DocumentGoods.Warehouse.UseBinLocationWarehousing
	|					OR TaskData_.Date < DocumentGoods.Warehouse.StartDateOfUsingWarehouseBinSystem)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS ReferenceStorageIsUsed,
	|	ISNULL(DocumentGoods.Warehouse.WarehouseZoneUsage, FALSE) AS WarehouseZoneUsage,
	|	CASE
	|		WHEN DocumentGoods.Warehouse.UseWarehouseManagemantSystemForGoodsIssue
	|				AND TaskData_.Date >= DocumentGoods.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS AdvancedWarehousingIsUsed
	|INTO TaskData_
	|FROM
	|	Document.SalesOrder AS TaskData_
	|		INNER JOIN Document.SalesOrder.Goods AS DocumentGoods
	|		ON TaskData_.Ref = DocumentGoods.Ref
	|
	|WHERE
	|	TaskData_.Ref IN(&ObjectsArray)
	|	AND DocumentGoods.Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND TaskData_.Status <> VALUE(Enum.SalesOrderStatuses.NotApproved)
	|
	|INDEX BY
	|	Ref,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	GoodsTable.DocumentShipments	AS Ref,
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.Warehouse				AS Warehouse,
	|	GoodsTable.ToShipBalance	AS Count
	|INTO GoodsForIssue
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|			,
	|			(Warehouse, DocumentShipments) IN
	|				(SELECT
	|					TaskData_.Warehouse		AS Warehouse,
	|					TaskData_.Ref	AS DocumentShipments
	|				FROM
	|					TaskData_ AS TaskData_
	|				WHERE
	|					NOT TaskData_.AdvancedWarehousingIsUsed)) AS GoodsTable
	|
	|INDEX BY
	|	Ref,
	|	Products
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Series					AS Series,
	|	GoodsTable.Warehouse					AS Warehouse
	|INTO GoodsFromOrder
	|FROM
	|	Document.SalesOrder.Goods AS GoodsTable
	|		INNER JOIN TaskData_ AS TaskData_
	|		ON GoodsTable.Ref = TaskData_.Ref
	|			AND GoodsTable.Warehouse = TaskData_.Warehouse
	|WHERE
	|	NOT GoodsTable.Canceled
	|	AND NOT TaskData_.AdvancedWarehousingIsUsed
	|	AND GoodsTable.Products.ItemsType IN(VALUE(Enum.ItemsTypes.OwnGoods),
	|													VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND GoodsTable.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Warehouse
	|
	|INDEX BY
	|	Ref,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsFromOrder.LineNumber			AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	GoodsTable.Series					AS Series,
	|	CAST(GoodsTable.Products AS Catalog.Products).PackagingGroup AS PackagingGroup,
	|	GoodsTable.Warehouse					AS Warehouse,
	|	GoodsTable.Count			AS Count
	|INTO TaskItems_
	|FROM
	|	GoodsForIssue AS GoodsTable
	|		INNER JOIN GoodsFromOrder AS GoodsFromOrder
	|		ON GoodsTable.Ref = GoodsFromOrder.Ref
	|			AND GoodsTable.Products = GoodsFromOrder.Products
	|			AND GoodsTable.Characteristic = GoodsFromOrder.Characteristic
	|			AND GoodsTable.Series = GoodsFromOrder.Series
	|			AND GoodsTable.Warehouse = GoodsFromOrder.Warehouse
	|
	|INDEX BY
	|	Products,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 4
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsTable.Warehouse					AS Warehouse,
	|	TaskData_.Premise				AS Premise,
	|	MIN(GoodsTable.LineNumber)	AS LineNumber,
	|	GoodsTable.Products			AS Products,
	|	GoodsTable.Characteristic		AS Characteristic,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END								AS Series,
	|	Goods.PackagingGroup				AS PackagingGroup,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN Goods.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END								AS Package,
	|	MIN(GoodsTable.Count)	AS Count
	|INTO TableOfGoodsSummarized
	|FROM
	|	TaskItems_ AS GoodsTable
	|		LEFT JOIN TaskData_ AS TaskData_
	|		ON GoodsTable.Ref = TaskData_.Ref
	|		
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON GoodsTable.Products = Goods.Ref
	|
	|GROUP BY
	|	GoodsTable.Ref,
	|	GoodsTable.Warehouse,
	|	TaskData_.Premise,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN VALUE(Catalog.ItemsBatches.EmptyRef)
	|		ELSE GoodsTable.Series
	|	END,
	|	Goods.PackagingGroup,
	|	CASE
	|		WHEN Goods.ProductKind.BatchUsageSettings = &BatchUsageSettings
	|			THEN Goods.UnitOfMeasure
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END
	|
	|INDEX BY
	|	Products,
	|	Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 5
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref
	|FROM
	|	Document.SalesOrder AS DocumentData
	|		LEFT JOIN TaskData_ AS TaskData_
	|		ON DocumentData.Ref = TaskData_.Ref
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND TaskData_.Ref IS NULL
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 6
	|SELECT
	|	TaskData_.Ref							AS Ref,
	|	PRESENTATION(TaskData_.Ref)				AS RefPresentation,
	|	TaskData_.Number								AS Number,
	|	TaskData_.Date								AS Date,
	|	TaskData_.NumberOfDocumentBeingCorrected		AS NumberOfDocumentBeingCorrected,
	|	TaskData_.DateOfDocumentBeingCorrected		AS DateOfDocumentBeingCorrected,
	|	TaskData_.Warehouse								AS Warehouse,
	|	PRESENTATION(TaskData_.Warehouse)				AS WarehousePresentation,
	|	TaskData_.Premise							AS Premise,
	|	PRESENTATION(TaskData_.Premise)			AS PremisePresentation,
	|	TaskData_.ThisIsAnInvoice						AS ThisIsAnInvoice,
	|	TaskData_.BinLocationWarehousingIsUsed		AS BinLocationWarehousingIsUsed,
	|	TaskData_.ReferenceStorageIsUsed	AS ReferenceStorageIsUsed,
	|	TaskData_.WarehouseZoneUsage		AS WarehouseZoneUsage,
	|	TaskData_.AdvancedWarehousingIsUsed			AS AdvancedWarehousingIsUsed
	|FROM
	|	TaskData_ AS TaskData_
	|
	|ORDER BY
	|	TaskData_.Ref,
	|	TaskData_.Warehouse
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 7
	|SELECT
	|	TableOfGoods.Ref								AS Ref,
	|	TableOfGoods.Warehouse								AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	PRESENTATION(MainStorageBins.Cell.WarehouseZone)	AS PresentationOfWorkArea,
	|	ISNULL(MainStorageBins.Cell.TabIndex, 0)	AS TabIndex,
	|	ISNULL(MainStorageBins.Cell, &DefaultCell)	AS MainStorageBin,
	|	ISNULL(MainStorageBins.Cell.Code, """")			AS MainStorageBinPresentation,
	|	ISNULL(OtherCells.Cell.TabIndex, 0)	AS TraversalOrderAdditionalCell,
	|	ISNULL(OtherCells.Cell.Code, """")			AS CellPresentation,
	|	TableOfGoods.LineNumber							AS LineNumber,
	|	Goods.Code											AS Code,
	|	Goods.SKU										AS SKU,
	|	TableOfGoods.Products							AS Products,
	|	Goods.DescriptionFull							AS ProductPresentation,
	|	TableOfGoods.Characteristic						AS Characteristic,
	|	TableOfGoods.Characteristic.DescriptionFull	AS CharacteristicPresentation,
	|	Goods.ProductKind.BatchUsageSettings	AS BatchUsageSettings,
	|	TableOfGoods.Series								AS Series,
	|	TableOfGoods.Series.Description					AS BatchPresentation,
	|	TableOfGoods.Package								AS Package,
	|	PRESENTATION(TableOfGoods.Package)				AS PresentationOfPackingUnit,
	|	PRESENTATION(Goods.UnitOfMeasure)				AS PresentationOfBasicUnitOfMeasure,
	|	TableOfGoods.Count							AS Count,
	|	TableOfGoods.Count							AS NumberOfPackages
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.Products AS Goods
	|		ON TableOfGoods.Products = Goods.Ref
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS OtherCells
	|		ON TableOfGoods.Products = OtherCells.Products
	|			AND NOT OtherCells.MainStorageBin
	|			AND TableOfGoods.Warehouse = OtherCells.Warehouse
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series
	|
	|TOTALS BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 8
	|SELECT DISTINCT
	|	TableOfGoods.Ref					AS Ref,
	|	TableOfGoods.Warehouse					AS Warehouse,
	|	ISNULL(MainStorageBins.Cell.WarehouseZone, &DefaultWorkArea)	AS WarehouseZone,
	|	TableOfGoods.LineNumber				AS LineNumber,
	|	TableOfGoods.Products				AS Products,
	|	TableOfGoods.Characteristic			AS Characteristic,
	|	TableOfGoods.Series					AS Series,
	|	ISNULL(ProductPackages.Ref, &DefaultPackaging)	AS Package,
	|	ISNULL(PRESENTATION(ProductPackages.Ref), PRESENTATION(TableOfGoods.Products.UnitOfMeasure))	AS PresentationOfPackingUnit,
	|	ISNULL(&PackingCoefficientText, 1)	AS QuantityPerPackage
	|FROM
	|	TableOfGoodsSummarized AS TableOfGoods
	|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|		ON (TableOfGoods.Products = ProductPackages.Owner
	|				OR TableOfGoods.PackagingGroup = ProductPackages.Owner)
	|			AND NOT ProductPackages.DeletionMark
	|			AND TableOfGoods.Count >= &PackingCoefficientText
	|		
	|		LEFT JOIN InformationRegister.PlaceProductsInStorageBins AS MainStorageBins
	|		ON TableOfGoods.Products = MainStorageBins.Products
	|			AND MainStorageBins.MainStorageBin
	|			AND TableOfGoods.Warehouse = MainStorageBins.Warehouse
	|
	|ORDER BY
	|	Ref,
	|	Warehouse,
	|	WarehouseZone,
	|	LineNumber,
	|	Products,
	|	Characteristic,
	|	Series,
	|	QuantityPerPackage DESC";
	
	PackingCoefficientText = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"ProductPackages",
									"TableOfGoods.Products");
	
	QueryText = StrReplace(QueryText,
								"&DefaultRoom",
								"VALUE(Catalog.Warerooms.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&BatchUsageSettings",
								"VALUE(Enum.ItemsBatchUsageSettings.InventoryItem)");
	QueryText = StrReplace(QueryText,
								"&DefaultWorkArea",
								"VALUE(Catalog.WarehouseZones.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultCell",
								"VALUE(Catalog.StorageBins.EmptyRef)");
	QueryText = StrReplace(QueryText,
								"&DefaultPackaging",
								"VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)");
	QueryText = StrReplace(QueryText, "&PackingCoefficientText", PackingCoefficientText);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	MaxIndex = Result.UBound();
	
	TaskData_ = New Structure;
	TaskData_.Insert("ErrorResults",		Result[MaxIndex - 3]);
	TaskData_.Insert("ResultOnOrders",	Undefined);
	TaskData_.Insert("HeaderResults",			Result[MaxIndex - 2]);
	TaskData_.Insert("ResultForTabularPart",	Result[MaxIndex - 1]);
	TaskData_.Insert("ResultForPackages",		Result[MaxIndex]);
	TaskData_.Insert("ResultBySeries",			Undefined);
	
	Return TaskData_;
	
EndFunction

Function CreateSetOfPrintedForms(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects) Export
	
	Var AddressOfSetOfPrintedForms;
	
	If TypeOf(PrintParameters) = Type("Structure") And PrintParameters.Property("AddressOfSetOfPrintedForms", AddressOfSetOfPrintedForms) Then
		
		PrintFormsSet = GetFromTempStorage(AddressOfSetOfPrintedForms);
		
	Else
		
		PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrintFormsSet(
			Metadata.Documents.SalesOrder.FullName(),
			ObjectsArray, Undefined);
		
	EndIf;
		
	If PrintFormsSet = Undefined Then
		Return Undefined;
	EndIf;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"SalesOrder");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintOrderForGoodsServices.GeneratePrintedCustomerOrderForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"CustomerOrderWithoutDiscounts");
		PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintOrderForGoodsServices.GeneratePrintedCustomerOrderForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoice");
	PrintParameters.Delete("DisplayDiscounts_");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceForPaymentWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceWithFacsimile");
	PrintParameters.Delete("DisplayDiscounts_");
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"InvoiceWithFacsimileWithoutDiscounts");
	PrintParameters.Insert("DisplayDiscounts_", False);
	PrintParameters.Insert("DisplayFacsimiles", True);
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.GeneratePrintedInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
		
	SetsOfPrintingOnObjects = InformationRegisters.ObjectPrintSettings.SetsOfPrintingOnObjects(PrintFormsCollection,
		PrintFormsSet,
		ObjectsArray,
		"ProformaInvoiceEn");
	For Each PrintKit In SetsOfPrintingOnObjects Do
		StructureOfTypes = New Map;
		StructureOfTypes.Insert("Document.SalesOrder", PrintKit.Objects);
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			PrintKit.Name,
			PrintKit.Presentation,
			DataProcessors.PrintCommercialInvoices.CreatePrintedProformaInvoiceForm(StructureOfTypes, PrintObjects, PrintParameters));
	EndDo;
	
	InformationRegisters.ObjectPrintSettings.FormSetOfExternalPrintingPlates(
		"Document.SalesOrder",
		ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects);
		
	SalesOrderLocalization.CreateSetOfPrintedForms(ObjectsArray,
		PrintParameters,
		PrintFormsCollection,
		PrintObjects,
		PrintFormsSet);

EndFunction

Function PrintFormsSet() Export
	
	PrintFormsSet = InformationRegisters.ObjectPrintSettings.PrepareSetOfPrintedForms();
	
	If GetFunctionalOption("SelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "SalesOrder", NStr("vi = 'Đơn hàng của khách (hiển thị chiết khấu)';
																										|ru = 'Заказ клиента (выводить скидки)';
																										|en = 'Sales order (display discounts)'; fa = 'Sales order (display discounts)';
																										|it = 'Ordine del cliente (visualizzare gli sconti)';
																										|pl = 'Zamówienie sprzedaży (wyprowadzaj rabaty)';
																										|tr = 'Satış siparişi (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "CustomerOrderWithoutDiscounts", NStr("vi = 'Đơn hàng của khách (không hiển thị chiết khấu)';
																															|ru = 'Заказ клиента (не выводить скидки)';
																															|en = 'Sales order (do not display discounts)'; fa = 'Sales order (do not display discounts)';
																															|it = 'Ordine del cliente (non visualizzare gli sconti)';
																															|pl = 'Zamówienie sprzedaży (nie wyprowadzaj rabaty)';
																															|tr = 'Satış siparişi (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán (hiển thị chiết khấu)';
																											|ru = 'Счет на оплату (выводить скидки)';
																											|en = 'Commercial invoice (display discounts)'; fa = 'Commercial invoice (display discounts)';
																											|it = 'Fattura di pagamento (visualizzare gli sconti)';
																											|pl = 'Rachunek do płatności (wyświetlać zniżki)';
																											|tr = 'Ticari fatura (indirimleri göster)'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceForPaymentWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán (không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату (не выводить скидки)';
																																|en = 'Commercial invoice (do not display discounts)'; fa = 'Commercial invoice (do not display discounts)';
																																|it = 'Fattura di pagamento (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności (nie wyświetlać zniżki)';
																																|tr = 'Ticari fatura (indirimleri gösterme)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax (hiển thị chiết khấu)';
																														|ru = 'Счет на оплату с факсимиле (выводить скидки)';
																														|en = 'Commercial invoice with facsimile (display discounts)'; fa = 'Commercial invoice with facsimile (display discounts)';
																														|it = 'Fattura di pagamento in facsimile (visualizzare gli sconti)';
																														|pl = 'Rachunek do płatności z faksymile (wyświetlać zniżki)';
																														|tr = 'Kaşeli ticari fatura (indirimleri göster)'"), 0);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "InvoiceWithFacsimileWithoutDiscounts", NStr("vi = 'Yêu cầu thanh toán ký qua fax(không hiển thị chiết khấu)';
																																|ru = 'Счет на оплату с факсимиле (не выводить скидки)';
																																|en = 'Commercial invoice with facsimile (do not display discounts)'; fa = 'Commercial invoice with facsimile (do not display discounts)';
																																|it = 'Fattura di pagamento in facsimile (non visualizzare gli sconti)';
																																|pl = 'Rachunek do płatności z faksymile (nie wyświetlać zniżki)';
																																|tr = 'Kaşeli ticari fatura (indirimleri gösterme)'"), 0);
	EndIf;
	
	If GetFunctionalOption("NotSelectAnOptionOfDiscountDisplayWhilePrintingSalesDocuments") Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "SalesOrder", NStr("vi = 'Đơn hàng của khách';
																										|ru = 'Заказ клиента';
																										|en = 'Sales order'; fa = 'سفارش فروش';
																										|it = 'Ordine del cliente';
																										|pl = 'Zamówienie klienta';
																										|tr = 'Satış siparişi'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoice", NStr("vi = 'Yêu cầu thanh toán';
																											|ru = 'Счет на оплату';
																											|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
																											|it = 'Fattura di pagamento';
																											|pl = 'Rachunek do zapłaty';
																											|tr = 'Ticari fatura'"), 1);
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceWithFacsimile", NStr("vi = 'Yêu cầu thanh toán ký qua fax';
																														|ru = 'Счет на оплату с факсимиле';
																														|en = 'Commercial invoice with facsimile'; fa = 'Commercial invoice with facsimile';
																														|it = 'Fattura di pagamento in facsimile';
																														|pl = 'Rachunek do płatności z faksymile';
																														|tr = 'Kaşeli ticari fatura'"), 0);
	EndIf;
	If Constants.UseInternationalPrintingForms.Get() Then
		InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet, "ProformaInvoiceEn", NStr("vi = 'Proforma invoice';
																												|ru = 'Proforma invoice';
																												|en = 'Proforma invoice'; fa = 'پیش‌فاکتور';
																												|it = 'Proforma invoice';
																												|pl = 'Proforma invoice';
																												|tr = 'Proforma invoice'"), 1);
	EndIf;
	InformationRegisters.ObjectPrintSettings.AddPrintedFormToKit(PrintFormsSet,
		"GoodsPickingPlacementJob", 
		NStr("vi = 'Nhiệm vụ lấy ra hàng hóa';
			|ru = 'Задание на отбор товаров';
			|en = 'Picking job'; fa = 'کار برداشت';
			|it = 'Task per selezione prodotti';
			|pl = 'Zadanie na selekcję towarów';
			|tr = 'Mal seçimi görevi'"),0);

	SalesOrderLocalization.PrintFormsSet(PrintFormsSet);
		
	Return PrintFormsSet;
	
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
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

Function AddCommandsToPrintSetOfDocuments() Export
	Return Not UserRightsCached.ThisIsPartner();
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

#Region Other

Function SeparateProvision(SalesOrder) Export

	SetPrivilegedMode(True);

	Query = New Query(
	"
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.SalesOrder.Goods AS T
	|WHERE
	|	T.Ref = &SalesOrder
	|	AND T.WithAssignment
	|");
	Query.SetParameter("SalesOrder", SalesOrder);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

Function ThereAreSeparateOrdersForTransaction(SalesOpportunity) Export

	SetPrivilegedMode(True);

	Query = New Query(
		"SELECT ALLOWED TOP 1
		|	TRUE AS EatSeparately
		|FROM
		|	Document.SalesOrder.Goods AS Goods
		|WHERE
		|	Goods.Ref.SalesOpportunity = &SalesOpportunity
		|	AND Goods.WithAssignment");
	Query.SetParameter("SalesOpportunity", SalesOpportunity);
	Return Not Query.Execute().IsEmpty();

EndFunction

#EndRegion

#Region ToDoList

// Fills in the user's to-do list.
// Parameters: 
//     ToDoList - See ToDoListServer.ToDoList
//
Procedure OnFillToDoList(ToDoList) Export
	
	FormName = "Document.SalesOrder.Form.DocumentsListForm";
	
	CommonQueryParameters = ToDoListInternal.CommonQueryParameters();
	
	// Let's determine whether the group's indicators are available to the current user
	Enabled =
		(CommonQueryParameters.IsFullUser
			Or AccessRight("View", Metadata.Documents.SalesOrder))
		And AccessRight("Insert", Metadata.Documents.SalesOrder)
		And AccessRight("Read",     Metadata.AccumulationRegisters.CustomersARAPAccounting)
		And AccessRight("Read",     Metadata.AccumulationRegisters.ShipmentAndReturnReferences)
		And GetFunctionalOption("UseSalesOrders")
		And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder");
	
	If Not Enabled Then
		Return;
	EndIf;
	
	// The calculation of the indicators
	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT DocumentSalesOrder.Ref) AS CustomerOrdersTotalInProgress,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate >= SalesOrderStates.EventDate THEN
	|			SalesOrderStates.OrderDocument
	|	END) AS CustomerOrdersForToday,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > SalesOrderStates.EventDate 
	|				AND SalesOrderStates.State IN (
	|					VALUE(Enum.SalesOrderStates.PendingAdvanceBeforeSupply),
	|					VALUE(Enum.SalesOrderStates.PendingPrepaymentBeforeShipment),
	|					VALUE(Enum.SalesOrderStates.PendingPaymentAfterShipment)) THEN
	|			SalesOrderStates.OrderDocument
	|		END) AS CustomerOrdersOverduePayment,
	|	COUNT(DISTINCT CASE
	|		WHEN SalesOrderStates.EventDate <> DATETIME(1, 1, 1)
	|				AND &UpdateDate > SalesOrderStates.EventDate 
	|				AND SalesOrderStates.State IN (
	|					VALUE(Enum.SalesOrderStates.PendingApproval),
	|					VALUE(Enum.SalesOrderStates.ReadyForSupply),
	|					VALUE(Enum.SalesOrderStates.ReadyToShip),
	|					VALUE(Enum.SalesOrderStates.DuringShipment),
	|					VALUE(Enum.SalesOrderStates.TransferOfTitleToGoodsIsExpected)) THEN
	|			SalesOrderStates.OrderDocument
	|	END) AS CustomerOrdersOverdueExecution
	|FROM
	|	Document.SalesOrder AS DocumentSalesOrder
	|		{LEFT JOIN InformationRegister.SalesOrderStates AS SalesOrderStates
	|		ON (SalesOrderStates.OrderDocument = DocumentSalesOrder.Ref)}
	|WHERE
	|	((NOT (SalesOrderStates.OrderDocument IS NULL) 
	|	AND SalesOrderStates.State <> VALUE(Enum.SalesOrderStates.Closed))
	|	OR NOT DocumentSalesOrder.Posted)
	|	AND DocumentSalesOrder.Manager = &User
	|	AND NOT DocumentSalesOrder.DeletionMark
	|	AND NOT DocumentSalesOrder.ThisIsOrderAsInvoice";
	
	Result = ToDoListInternal.NumericUserTasksIndicators(Query, CommonQueryParameters);
	
	// Filling out cases.
	// Customers' order
	UserTaskParent = ToDoList.Add();
	UserTaskParent.Id  = "SalesOrders";
	UserTaskParent.Presentation  = NStr("vi = 'Đơn hàng của khách';
										|ru = 'Заказы клиентов';
										|en = 'Sales orders'; fa = 'سفارش‌های فروش';
										|it = 'Ordini dei clienti';
										|pl = 'Zamówienia od klientów';
										|tr = 'Satış siparişi'");
	UserTaskParent.Owner       = Metadata.Subsystems.Sales;
	
	// CustomerOrdersTotalInProgress
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "CustomerOrdersTotalInProgress";
	ToDoItem.HasToDoItems       = Result.CustomerOrdersTotalInProgress > 0;
	ToDoItem.Presentation  = NStr("vi = 'Tất cả đơn hàng hiện tại';
									|ru = 'Всего заказов в работе';
									|en = 'Total active orders'; fa = 'Total active orders';
									|it = 'Totale ordini in esecuzione';
									|pl = 'Łącznie zamówień w pracy';
									|tr = 'Devam eden tüm siparişler'");
	ToDoItem.Count     = Result.CustomerOrdersTotalInProgress;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "SalesOrders";
	
	// CustomerOrdersForToday
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllOpened");
	FilterParameters.Insert("Relevance", "Today");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "CustomerOrdersForToday";
	ToDoItem.HasToDoItems       = Result.CustomerOrdersForToday > 0;
	ToDoItem.Presentation  = NStr("vi = 'Hôm nay';
									|ru = 'На сегодня';
									|en = 'As of today'; fa = 'As of today';
									|it = 'Ad oggi';
									|pl = 'Na dzisiaj';
									|tr = 'Bugün itibarıyla'");
	ToDoItem.Count     = Result.CustomerOrdersForToday;
	ToDoItem.Important         = False;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "SalesOrders";
	
	// CustomerOrdersOverduePayment
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllPaymentPending");
	FilterParameters.Insert("Relevance", "Overdue");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "CustomerOrdersOverduePayment";
	ToDoItem.HasToDoItems       = Result.CustomerOrdersOverduePayment > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đã quá hạn thanh toán theo giấy đề nghị';
									|ru = 'Просрочена оплата по заказам';
									|en = 'Overdue payables'; fa = 'حساب‌های پرداختنی سررسیدگذشته';
									|it = 'Pagamento per ordini scaduto';
									|pl = 'Zalełgła płatność według zamówień';
									|tr = 'Siparişlere ilişkin gecikmiş ödemeleri'");
	ToDoItem.Count     = Result.CustomerOrdersOverduePayment;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "SalesOrders";
	
	// CustomerOrdersOverdueExecution
	FilterParameters = New Structure;
	FilterParameters.Insert("State", "AllExecutionPending");
	FilterParameters.Insert("Relevance", "Overdue");
	FilterParameters.Insert("EventDate", CommonQueryParameters.DateEmpty);
	FilterParameters.Insert("Manager", CommonQueryParameters.User);
	FilterParameters.Insert("Priority", "");
	
	ToDoItem = ToDoList.Add();
	ToDoItem.Id  = "CustomerOrdersOverdueExecution";
	ToDoItem.HasToDoItems       = Result.CustomerOrdersOverdueExecution > 0;
	ToDoItem.Presentation  = NStr("vi = 'Đã quá hạn thực hiện đơn hàng';
									|ru = 'Просрочено исполнение заказов';
									|en = 'Overdue order execution'; fa = 'Overdue order execution';
									|it = 'Esecuzione di ordini scaduta';
									|pl = 'Zaległe wykonanie zamówień';
									|tr = 'Vadesi geçmiş siparişler'");
	ToDoItem.Count     = Result.CustomerOrdersOverdueExecution;
	ToDoItem.Important         = True;
	ToDoItem.Form          = FormName;
	ToDoItem.FormParameters = New Structure("QuickFilterStructure", FilterParameters);
	ToDoItem.Owner       = "SalesOrders";
	
	If Result.CustomerOrdersTotalInProgress > 0 Then
		UserTaskParent.HasToDoItems = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region CreatingHyperlinkInSalesDocumentsJournal

Function TextOfOrdersInProgressRequest()

	QueryText = 
	"SELECT ALLOWED TOP 1
	|	OrderStates.OrderDocument,
	|	OrderStates.State
	|FROM
	|	InformationRegister.SalesOrderStates AS OrderStates
	|WHERE
	|	OrderStates.State <> VALUE(Enum.SalesOrderStates.Closed)";
	
	Return QueryText
	
EndFunction

Function CreateHyperlinkSeeAlsoIn(Parameters) Export
	
	If Not (AccessRight("Read", Metadata.InformationRegisters.SalesOrderStates)
			And AccessRight("Update", Metadata.Documents.SalesOrder)
			And GetFunctionalOption("UseSalesOrders")
			And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder")) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Đơn hàng của khách';
						|ru = 'Заказы клиентов';
						|en = 'Sales orders'; fa = 'سفارش‌های فروش';
						|it = 'Ordini dei clienti';
						|pl = 'Zamówienia od klientów';
						|tr = 'Satış siparişi'");
	Query = New Query(TextOfOrdersInProgressRequest());
	
	If Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameWorkplace());
	Else
		Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplace());
	EndIf;
	
EndFunction

Function FormNameWorkplace() Export
	
	Return "Document.SalesOrder.Form.DocumentsListForm";
	
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
	|	&DateAccordingToInformationFromCustomer                    AS SourceDocumentDate,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&NumberAccordingToCustomerData                   AS SourceDocumentNumber,
	|	&Priority                              AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextBonusPoints(Query, QueryTexts, Registers, DocumentObject)
	
	RegisterName = "BonusPoints";
	
	If Not BonusPointsServer.ItIsRequiredToAddRegisterRegisteredRecordsBonusPoints(DocumentObject.Ref) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If DocumentObject.ThisIsOrderAsInvoice Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBonusPoints", QueryTexts) Then
		QueryTextTTBonusPoints(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	BonusPoints.Period                      AS Period,
	|	BonusPoints.DateToProcess              AS DateToProcess,
	|	BonusPoints.RecordType                 AS RecordType,
	|	BonusPoints.LoyaltyProgram AS LoyaltyProgram,
	|	BonusPoints.Partner                     AS Partner,
	|	SUM(BonusPoints.Accrued)            AS Accrued,
	|	SUM(BonusPoints.ToWriteOff)            AS ToWriteOff,
	|	SUM(BonusPoints.Reserved)      AS Reserved
	|FROM
	|	TTBonusPoints AS BonusPoints
	|
	|GROUP BY
	|	BonusPoints.LoyaltyProgram,
	|	BonusPoints.Partner,
	|	BonusPoints.Period,
	|	BonusPoints.DateToProcess,
	|	BonusPoints.RecordType
	|HAVING
	|	SUM(BonusPoints.Accrued) <> 0 OR 
	|	SUM(BonusPoints.ToWriteOff) <> 0 OR 
	|	SUM(BonusPoints.Reserved) <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBonusPoints(Query, QueryTexts)
	
	RegisterName = "TTBonusPoints";
	QueryText = 
	"SELECT
	|	BEGINOFPERIOD(&Period, DAY)                AS Period,
	|	CASE
	|		WHEN TabularSection.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			THEN &CurrentDate
	|		ELSE DATETIME(1, 1, 1)
	|	END AS DateToProcess,
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&LoyaltyProgram                AS LoyaltyProgram,
	|	&Partner                                    AS Partner,
	|	TabularSection.AmountOfBonusPointsToDeduction AS Accrued,
	|	0                                           AS ToWriteOff,
	|	CASE
	|		WHEN TabularSection.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			THEN 0
	|		ELSE TabularSection.AmountOfBonusPointsToDeduction
	|	END AS Reserved
	|INTO TTBonusPoints
	|FROM
	|	DocumentDataTableItems AS TabularSection
	|		LEFT JOIN DocumentDataHeader AS DocumentDataHeader
	|			ON TabularSection.Ref = DocumentDataHeader.Ref
	|WHERE
	|	TabularSection.AmountOfBonusPointsToDeduction <> 0
	|	AND NOT TabularSection.Canceled
	|	AND NOT DocumentDataHeader.ThisIsOrderAsInvoice
	|";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Assignments

// Returns a template for generating product assignments in the document.
//
// Parameters:
// 		Object - DocumentObject.SalesOrder, FormDataStructure - the customer order for which you need to get the destination template.
//
// Returns:
// 		See Catalogs.Assignments.NewSubmenuTemplate
//
Function DestinationPattern(Object) Export
	
	DestinationPattern = Catalogs.Assignments.NewSubmenuTemplate();
	
	If LinesOfBusinessServer.ThisIsLineOfActivityWithSeparationOfGoodsAndWorks(Object.LineOfBusiness) Then
		DestinationPattern.LineOfBusiness = Object.LineOfBusiness;
	EndIf;
	
	If Object.BusinessOperation = Enums.BusinessTransactions.DeliveryForPrincipal Then
		
		DestinationPattern.AssignmentType = Enums.AssignmentTypes.DeliveryForPrincipal;
		DestinationPattern.Contract = Object.Contract;
		DestinationPattern.Partner = Object.Partner;
		
	EndIf;
	
	OptionOfAssignment = Constants.OptionOfGoodsAssignmentInSales.Get();
	
	If OptionOfAssignment <> Enums.OptionsOfGoodsAssignmentInSales.LineOfBusiness
		Or Not ValueIsFilled(DestinationPattern.LineOfBusiness) Then
		
		DestinationPattern.OrderDocument = Object.Ref;
		
	EndIf;
	
	Return DestinationPattern;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
