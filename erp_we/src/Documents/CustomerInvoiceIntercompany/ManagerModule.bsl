#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyRecipient", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,CompanyRecipient";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization,CompanyRecipient";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Contract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RecipientCompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
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
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CustomerInvoiceIntercompanyLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.CustomerInvoiceIntercompany") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableBatchesOfProductionCosts(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		AddTextsToReflectSettlements(Query, QueryTexts, Registers);
		
		CustomerInvoiceIntercompanyLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
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

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.IntercompanyGoodsReturn.AddGenerateCommand(GenerationCommands);
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CustomerInvoiceIntercompanyLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Transfer of goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CustomerInvoiceIntercompany) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CustomerInvoiceIntercompany.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CustomerInvoiceIntercompany);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerInvoiceIntercompany";
	

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
	
	Reports.ControlOfCustomerInvoicesIntercompany.AddProductTransferControlCommand(ReportsCommands);
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	CustomerInvoiceIntercompanyLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//	UseTransferForBusiness - Boolean
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation,
															ArrayOfAllProps,
															ArrayOfOperationDetails,
															UseTransferForBusiness = True) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("PaymentDate");
	ArrayOfAllProps.Add("PaymentMethod");
	ArrayOfAllProps.Add("SpecifyCCDNumbers");
	ArrayOfAllProps.Add("Goods.Department");
	ArrayOfAllProps.Add("Goods.ToExpenseAs");
	
	If UseTransferForBusiness Then
		ArrayOfAllProps.Add("TransferForActivity_");
	EndIf;
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany Then
		ArrayOfOperationDetails.Add("PaymentDate");
		ArrayOfOperationDetails.Add("PaymentMethod");
		ArrayOfOperationDetails.Add("SpecifyCCDNumbers");
		ArrayOfOperationDetails.Add("Goods.Department");
		ArrayOfOperationDetails.Add("Goods.ToExpenseAs");
		
		If UseTransferForBusiness Then
			ArrayOfOperationDetails.Add("TransferForActivity_");
		EndIf;
	EndIf;
	
EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.CustomerInvoiceIntercompany - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.AmountARAP AS AmountARAP,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.CourseNumerator AS Rate,
	|	DocumentData.CourseDenominator AS Repetition,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.SalesContract AS SalesContract,
	|	DocumentData.PurchasingContract AS PurchasingContract
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.CompanyRecipient;
		SenderOrganization = Selection.Organization;
		CompanyRecipient = Selection.CompanyRecipient;
		ARAPCurrency = Selection.ARAPCurrency;
		BusinessOperation = Selection.BusinessOperation;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		ARAPAccountingViaSeparateCounterparty = Selection.ARAPAccountingViaSeparateCounterparty;
		Partner = ?(ARAPAccountingViaSeparateCounterparty, Selection.Partner, Catalogs.Partners.OurEnterprise);
		Counterparty = ?(ARAPAccountingViaSeparateCounterparty, Selection.Counterparty, Selection.Organization);
		Contract = Selection.Contract;
		LineOfBusiness = Selection.LineOfBusiness;
		Rate = Selection.Rate;
		Repetition = Selection.Repetition;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		SalesContract = Selection.SalesContract;
		PurchasingContract = Selection.PurchasingContract;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		SenderOrganization = Catalogs.Companies.EmptyRef();
		CompanyRecipient = Catalogs.Companies.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		BusinessOperation = Enums.BusinessTransactions.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		ARAPAccountingViaSeparateCounterparty = False;
		Partner = Catalogs.Partners.EmptyRef();
		Contract = Catalogs.IntercompanyContracts.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Rate = 1;
		Repetition = 1;
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		SalesContract = Catalogs.CounterpartyContracts.EmptyRef();
		PurchasingContract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", BusinessOperation);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("SenderOrganization", SenderOrganization);
	AttributesStructure1.Insert("CompanyRecipient", CompanyRecipient);
	AttributesStructure1.Insert("ARAPAccountingViaSeparateCounterparty", ARAPAccountingViaSeparateCounterparty);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("Rate", Rate);
	AttributesStructure1.Insert("Repetition", Repetition);
	AttributesStructure1.Insert("SalesContract", SalesContract);
	AttributesStructure1.Insert("PurchasingContract", PurchasingContract);
	If Not ARAPAccountingViaSeparateCounterparty Then
		AttributesStructure1.Insert("Contract", Contract);
	EndIf;
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	
	Return AttributesStructure1;
EndFunction

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date";
	
	Return AttributesNames;
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.CustomerInvoiceIntercompany";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - the composition of fields is set in the function
//		Nomenclaturales.Parametrizatsii.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Series               AS Series,
	|	Goods.Count          AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
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
	|				ELSE 0
	|			END
	|	END                      AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON BatchAccountingPolicies.Warehouse = &Warehouse
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber         AS LineNumber,
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

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CustomerInvoiceIntercompanyLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CustomerInvoiceIntercompanyLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Goods.Purpose");
	
	Return FormTemplate;
	
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
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(CompanyRecipient)
	|	) AND ValueAllowed(Partner)
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CustomerInvoiceIntercompany, DocumentObject.CustomerInvoiceIntercompany - document for transferring goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the taxable sales().
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Contract, SalesContract, Warehouse,
										|BusinessOperation, ARAPAccountingViaSeparateCounterparty, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FieldsToFillIn = "Date, Organization, Warehouse, LineOfBusiness";
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes, FieldsToFillIn);
	
	FillParameters.Contract    = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.SalesContract,
										DocumentAttributes.Contract);
	
	GoodsSales = DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	FillParameters.GoodsSales    = GoodsSales;
	FillParameters.ImplementationOfWorksServices = GoodsSales;
	FillParameters.TransferToCommissionAgent   = Not GoodsSales;
	
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CustomerInvoiceIntercompany, DocumentObject.CustomerInvoiceIntercompany - document for transferring goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, CompanyRecipient, Contract, PurchasingContract, Warehouse, 
										|BusinessOperation, ARAPAccountingViaSeparateCounterparty, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes, "Date, Warehouse, LineOfBusiness");
	
	FillParameters.Organization = DocumentAttributes.CompanyRecipient;
	FillParameters.Contract     = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.PurchasingContract,
										DocumentAttributes.Contract);
	
	PurchaseOfGoods = DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	FillParameters.PurchaseOfGoods = PurchaseOfGoods;
	FillParameters.AcquisitionOfWorks   = PurchaseOfGoods;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters to register the issued invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CustomerInvoiceIntercompany, DocumentObject.CustomerInvoiceIntercompany - document for transferring goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of the Invoice data().
//
Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, CompanyRecipient, Counterparty, VATTaxation, 
										|BusinessOperation, ARAPAccountingViaSeparateCounterparty");
	
	If TypeOf(Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, Organization, VATTaxation");
	
	RegistrationParameters.Counterparty = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.CompanyRecipient);
	
	GoodsSales = DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	RegistrationParameters.GoodsSales    = GoodsSales;
	RegistrationParameters.ImplementationOfWorksServices = GoodsSales;
	RegistrationParameters.TransferToCommissionAgent   = Not GoodsSales;
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters for registering received invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CustomerInvoiceIntercompany, DocumentObject.CustomerInvoiceIntercompany - document for transferring goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of invoices received().
//
Function ParametersForRegisteringInvoicesReceived(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, CompanyRecipient, Counterparty, VATTaxation, 
										|BusinessOperation, ARAPAccountingViaSeparateCounterparty");
	
	If TypeOf(Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, VATTaxation");
	
	RegistrationParameters.Organization = DocumentAttributes.CompanyRecipient;
	RegistrationParameters.Counterparty  = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.Organization);
	
	PurchaseOfGoods = DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	RegistrationParameters.PurchaseOfGoodsWorksServices = PurchaseOfGoods;
	RegistrationParameters.ConsignmentProcurement               = Not PurchaseOfGoods;
	
	Return RegistrationParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The operation of the document.
//
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	AvailabilityByOperation = BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.Goods";
	ChoiceParameters.AssetRef                = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = AvailabilityByOperation;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("GoodsExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("GoodsDimensionOfExpenses");
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	Return ChoiceParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ARAPAccountingViaSeparateCounterparty,
			|BusinessOperation,
			|SalesContract,
			|PurchasingContract");
		ARAPAccountingViaSeparateCounterparty = StructureFillingData.ARAPAccountingViaSeparateCounterparty;
		BusinessOperation             = StructureFillingData.BusinessOperation;
		SalesContract                    = StructureFillingData.SalesContract;
		PurchasingContract                    = StructureFillingData.PurchasingContract;
	ElsIf FillingData = Undefined Then
		ARAPAccountingViaSeparateCounterparty = False;
		BusinessOperation             = Undefined;
		SalesContract                    = Undefined;
		PurchasingContract                    = Undefined;
	Else
		ARAPAccountingViaSeparateCounterparty = FillingData.ARAPAccountingViaSeparateCounterparty;
		BusinessOperation             = FillingData.BusinessOperation;
		SalesContract                    = FillingData.SalesContract;
		PurchasingContract                    = FillingData.PurchasingContract;
	EndIf;
	
	// Array of parameters - separately for shipment and acceptance
	// Shipment (Seller Organization):
	
	SettlementParameters = New Array();
	
	#Region Shipment
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase                = True;
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	//With certain values of the document details, he may not change the mutual settlements. 
	//An example is the transfer of goods to the commission.StructureParameters
	//If the value is negative, the settlement objects will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan               =
		BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	ParametersStructure.ModifiesDeliveryShipmentPlan     =
		BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)";
	
	//They are used to generate calculation and analytics objects.
	ParametersStructure.Organization = "Object.Organization";
	ParametersStructure.Partner    = ?(ARAPAccountingViaSeparateCounterparty, "Object.Partner", Catalogs.Partners.OurEnterprise);
	ParametersStructure.Counterparty = ?(ARAPAccountingViaSeparateCounterparty, "Object.Counterparty", "Object.CompanyRecipient");
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract = ?(ARAPAccountingViaSeparateCounterparty, "Object.SalesContract", "Object.Contract");
	ContractSettlementProcedure = ?(ValueIsFilled(SalesContract),"Object.SalesContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	//Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	ParametersStructure.CounterpartyBankAccount        = "Object.RecipientCompanyBankAccount";
	
	//They are used to determine the value of payments in the currency and in the form of editing payment rules.
	//The details for the object of calculations are used in conducting.
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroup";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	//The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement                      = "PaymentOffsetSenderForm";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "ExpensesAmountARAP";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	ParametersStructure.CourseNumerator                    = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                  = "Object.CourseDenominator";
	
	//The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies      = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesSender";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesSender";
	ParametersStructure.FormItems.InscriptionCalculations     = "DecorationPaymentStatusSender";
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	//Function Payment stages and payment date
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	#EndRegion
	
	ParametersStructure.TSP                              = "Object.Warehouse";
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Receiving
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	ParametersStructure.ThisIsSalePurchase                = True;
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	//With certain values of the document details, he may not change the mutual settlements. 
	//An example is the transfer of goods to the commission.StructureParameters
	//If the value is negative, the settlement objects will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan               = 
		BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)";
	ParametersStructure.ModifiesDeliveryShipmentPlan     = 
		BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
		
	//They are used to generate calculation and analytics objects.
	ParametersStructure.Organization = "Object.CompanyRecipient";
	ParametersStructure.Partner    = ?(ARAPAccountingViaSeparateCounterparty, "Object.Partner", Catalogs.Partners.OurEnterprise);
	ParametersStructure.Counterparty = ?(ARAPAccountingViaSeparateCounterparty, "Object.Counterparty", "Object.Organization");
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract = ?(ARAPAccountingViaSeparateCounterparty, "Object.PurchasingContract", "Object.Contract");
	ContractSettlementProcedure = ?(ValueIsFilled(PurchasingContract),"Object.PurchasingContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	//Details other than the currency and amount of the document. If it is not filled in, then the currency of the document will be taken for reading.
	ParametersStructure.ARAPCurrency             = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP              = "Object.AmountARAP";
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	ParametersStructure.CashAccount                            = "Object.CashAccountRecipient";
	ParametersStructure.CompanyBankAccount        = "Object.RecipientCompanyBankAccount";
	ParametersStructure.CounterpartyBankAccount        = "Object.CompanyBankAccount";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectOfRecipient";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroupOfRecipient";
	
	//The name of the button that opens the Payment offset assistant for the current set of parameters.
	ParametersStructure.FormItems.PaymentSettlement                      = "PaymentOffsetRecipientForm";
	ParametersStructure.FormItems.AmountOfTSSettlements            = "ExpensesAmountARAP";
	
	#EndRegion
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument

	ParametersStructure.CourseNumerator                          = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                        = "Object.CourseDenominator";
	
	//The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies      = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesRecipient";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesRecipient";
	ParametersStructure.FormItems.InscriptionCalculations     = "DecorationPaymentStatusRecipient";
	
	#EndRegion
	
	#Region ScheduledPaymentScheduleAndPaymentDate
	//Function Payment stages and payment date
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	#EndRegion
	
	ParametersStructure.TSP                              = "Object.Warehouse";
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	Return SettlementParameters;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	CustomerInvoiceIntercompanyLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
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
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.CustomerInvoiceIntercompany, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.BusinessOperation = Enums.BusinessTransactions.GoodsSaleToAnotherCompany;
	
EndFunction

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.CustomerInvoiceIntercompany - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Organization             AS Organization,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting,
	|	DocumentData.VATTaxation      AS VATTaxation,
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                   AS ThisIsTransferToCommission,
	|	DocumentData.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	QueryText =
	"SELECT	
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(&Period, (Products, Country) IN
	|		(SELECT
	|			T.Products AS Products,
	|			&RegistrationCountry AS Country
	|		FROM
	|			Document.CustomerInvoiceIntercompany.Goods AS T
	|		WHERE
	|			T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|;
	|SELECT
	|	TableTypesOfStocks_.RowID             AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	TableTypesOfStocks_.ExciseTaxAmount                     AS ExciseAmountInCurrencyLocal,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(TableExciseCategories.ExcisableGoodsCategory,
	|		VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) AS ExcisableGoodsCategory,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SubjectToExcise
	|		THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * TableTypesOfStocks_.Count
	|		ELSE 0
	|	END                                              AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	CASE
	|		WHEN &ThisIsTransferToCommission
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT TableTypesOfStocks_.ToExpenseAs
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END                                              AS VATTaxation, // Sender's VAT Taxation type of activity
	|	TableTypesOfStocks_.RowID             AS FinRecordID,
	|	TableTypesOfStocks_.Ref.ARAPObjectOfRecipient.UUID AS IDOfRecipientSFinRecord
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS TableTypesOfStocks_
	|
	|	INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = TableExciseCategories.Products
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|;
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.SaleOfGoodsAndServices) AS KindOfTransactionWithExcisableGoods,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|	OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|	OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0
	|";
	
	Query.Text = QueryText;
	
	RatePeriod = Attributes.Period;
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization);

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
	Return Query.Execute();
	
EndFunction

#EndRegion

#EndRegion
// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Chuyển giao hàng hóa giữa các doanh nghiệp';
		|ru = 'Передача товаров между организациями';
		|en = 'Customer invoice — Intercompany'; fa = 'فاکتور مشتری — بین‌شرکتی';
		|it = 'Trasferimento delle merci tra le organizzazioni';
		|pl = 'Przekazanie towarów pomiędzy firmami';
		|tr = 'İş yerleri arası müşteri faturası'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("SaleRegistrationOption");
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("ARAPAccountingViaSeparateCounterparty");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.SaleRegistrationOption = PredefinedValue("Enum.SalesRegistrationOptions.DeedOfTransfer") Then
		StandardProcessing = False;
		Presentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Biên bản chuyển giao quyền giữa các doanh nghiệp %1 ngày %2';
				|ru = 'Акт на передачу прав между организациями %1 от %2';
				|en = 'Deed of transfer between companies %1 dated %2'; fa = 'Deed of transfer between companies %1 dated %2';
				|it = 'Atto di trasferimento dei diritti tra società %1 del %2';
				|pl = 'Protokół o przeniesieniu praw między firmami %1 z %2';
				|tr = 'İş yerleri arasında devir senedi %2 itibaren %1'"),
			Data.Number,
			Data.Date);
	EndIf;
	
	If Data.ARAPAccountingViaSeparateCounterparty Then
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
			Data, Presentation, StandardProcessing, "CustomerInvoiceIntercompany");
	EndIf;
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Number                             AS Number,
	|	DocumentData.Date                              AS Period,
	|	DocumentData.Ref                            AS Ref,
	|	DocumentData.Organization                       AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.CompanyRecipient             AS CompanyRecipient,
	|	DocumentData.Warehouse                             AS Warehouse,
	|	DocumentData.Currency                            AS Currency,
	|	DocumentData.ARAPCurrency              AS ARAPCurrency,
	|	DocumentData.PaymentDate                       AS PaymentDate,
	|	DocumentData.Department                     AS Department,
	|	DocumentData.PriceIncludesVAT                   AS PriceIncludesVAT,
	|	DocumentData.VATTaxation                AS VATTaxation,
	|	DocumentData.BusinessOperation             AS BusinessOperation,
	|	DocumentData.SpecifyCCDNumbers                AS SpecifyCCDNumbers,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Counterparty                        AS Counterparty,
	|	DocumentData.TransferForActivity_           AS TransferForActivity_,
	|	DocumentData.Author                             AS Author,
	|	DocumentData.Organization                       AS Vendor,
	|	DocumentData.Manager                          AS Manager,
	|	UNDEFINED                                      AS SalesOpportunity,
	|	UNDEFINED                                      AS OptionOfAssignedAccountingOfGoods,
	|	VALUE(Catalog.InventoryAccountingGroups.EmptyRef) AS FinancialAccountingGroup,
	|	FALSE                                              AS EnabledGoodsAssignmentInSalesOpportunity,
	|	UNDEFINED                                      AS Terms,
	|	DocumentData.Contract                           AS Contract,
	|	DocumentData.SalesContract                    AS SalesContract,
	|	DocumentData.PurchasingContract                    AS PurchasingContract,
	|	
	|	DocumentData.Partner  AS Partner,
	|
	|	CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END                                             AS ThisIsTransferToCommission,
	|
	|	CASE WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|		OR DocumentData.EndOfPeriod > DocumentData.Date
	|	THEN
	|		DocumentData.Date
	|	ELSE
	|		DocumentData.EndOfPeriod
	|	END                                             AS EndOfPeriod,
	|	DocumentData.LineOfBusiness 		  AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.IncomingDocumentNumber           AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate            AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName    AS ExternalDocumentName,
	|	DocumentData.Comment                       AS Comment,
	|	DocumentData.DocumentAmount                    AS DocumentAmount,
	|	DocumentData.Posted                          AS Posted,
	|	DocumentData.DeletionMark                   AS DeletionMark,
	|	DocumentData.ARAPObject                    AS ARAPObject,
	|	DocumentData.ARAPObject.UUID AS IDARAPObject,
	|	DocumentData.ARAPObjectOfRecipient          AS ARAPObjectOfRecipient,
	|	BusinessTransactionsSettings.Ref             AS BusinessTransactionSetting,
	|	UNDEFINED                                      AS AdjustmentPeriod_
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentData
	|	
	|	
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	MetadataIdentifier = Common.MetadataObjectID("Document.CustomerInvoiceIntercompany");
	
	StringPattern = "vi = 'Chuyển giao từ ""%1""';
					|ru = 'Передача из ""%1""';
					|en = 'Transfer from ""%1""';
					|it = 'Trasferimento da ""%1""';
					|pl = 'Przeniesienie z ""%1""';
					|tr = '""%1""''den transfer'"; // @NStr
	OrganizationInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Organization);
	
	StringPattern = "vi = 'Chuyển giao vào ""%1""';
					|ru = 'Передача в ""%1""';
					|en = 'Transfer to ""%1""';
					|it = 'Trasferimento a ""%1""';
					|pl = 'Przeniesienie do ""%1""';
					|tr = '""%1"" içine transfer'"; // @NStr
	InformationAboutRecipientOrganization = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.CompanyRecipient);
	
	DocumentNumber          = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);
	
	Query.SetParameter("Ref",                            DocumentRef);
	Query.SetParameter("EndOfPeriod",                      EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("PriceIncludesVAT",                   ?(Attributes.PriceIncludesVAT, 0, 1));
	Query.SetParameter("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Query.SetParameter("LocalAccountingCurrency",    Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",        Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale", GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("MetadataIdentifier",           MetadataIdentifier);
	Query.SetParameter("OrganizationInformation",           OrganizationInformation);
	Query.SetParameter("InformationAboutRecipientOrganization", InformationAboutRecipientOrganization);
	Query.SetParameter("DocumentNumber",                    DocumentNumber);
	Query.SetParameter("IncomingDocumentNumber",           IncomingDocumentNumber);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms",   Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes, Attributes.CompanyRecipient);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref"                , Query.Parameters.Ref);
	QueryAnalyst.SetParameter("CompanyRecipient" , Query.Parameters.CompanyRecipient);
	QueryAnalyst.SetParameter("EmptyBatch_"           , Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("EmptyAssignment"      , Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("Organization"           , Query.Parameters.Organization);
	QueryAnalyst.SetParameter("ThisIsTransferToCommission" , Query.Parameters.ThisIsTransferToCommission);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);

	QueryAnalyst.Text = 
	"SELECT
	|	NestedQuery.Warehouse AS Warehouse,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.Purpose AS Purpose,
	|	VALUE(Catalog.ProductCostElements.EmptyRef) AS ProductCostElement,
	|	NestedQuery.Series AS Series
	|FROM
	|	(SELECT
	|		Goods.ItemsLocationAttributes.Products     AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic   AS Characteristic,
	|		&EmptyAssignment      AS Purpose,
	|		&EmptyBatch_           AS Series,
	|		&CompanyRecipient AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.InventoryKinds AS Goods
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND &ThisIsTransferToCommission
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.ItemsLocationAttributes.Products         AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment          AS Purpose,
	|		&EmptyBatch_               AS Series,
	|		Goods.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.InventoryKinds AS Goods
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Goods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Goods.ItemsLocationAttributes.Products         AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic       AS Characteristic,
	|		&EmptyAssignment          AS Purpose,
	|		Goods.ItemsLocationAttributes.Series                AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation        AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.InventoryKinds AS Goods
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT
	|		Services.Products   AS Products,
	|		Services.Characteristic AS Characteristic,
	|		&EmptyAssignment     AS Purpose,
	|		&EmptyBatch_          AS Series,
	|		ISNULL(Services.Characteristic.Principal, Services.Products.Principal) AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.Goods AS Services
	|WHERE
	|	Services.Ref = &Ref
	|	AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> UNDEFINED
	|	AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> &Organization
	|	AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Works.Products AS Products,
	|		Works.Characteristic AS Characteristic,
	|		Works.Purpose AS Purpose,
	|		CASE
	|			WHEN Works.BatchesIndicationStatus = 14
	|			THEN Works.Series
	|			ELSE &EmptyBatch_
	|		END AS Series,
	|		Works.Department AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.Goods AS Works
	|	WHERE
	|		Works.Ref = &Ref
	|		AND Works.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Works.Products AS Products,
	|		Works.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		CASE
	|			WHEN Works.BatchesIndicationStatus = 14
	|			THEN Works.Series
	|			ELSE &EmptyBatch_
	|		END AS Series,
	|		Works.Department AS Warehouse
	|	FROM
	|		Document.CustomerInvoiceIntercompany.Goods AS Works
	|	WHERE
	|		Works.Ref = &Ref
	|		AND Works.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments) AS NestedQuery
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON NestedQuery.Products = Dimension.Products
	|		AND NestedQuery.Characteristic = Dimension.Characteristic
	|		AND NestedQuery.Series = Dimension.Series
	|		AND NestedQuery.Warehouse = Dimension.StorageLocation
	|		AND NestedQuery.Purpose = Dimension.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	NestedQuery.Warehouse,
	|	NestedQuery.Products,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Purpose,
	|	NestedQuery.Series
	|";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.CustomerInvoiceIntercompany.Name,
		"Goods, InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 												AS TabularSectionName,
	|	DocumentTable.LineNumber 									AS LineNumber,
	|	CASE WHEN DocumentTable.Ref.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentTable.Ref.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END															AS Vendor,
	|	CASE WHEN DocumentTable.Ref.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentTable.Ref.Counterparty
	|		ELSE DocumentTable.Ref.Organization
	|	END															AS Counterparty,
	|	DocumentTable.VATRate 										AS VATRate,
	|	CASE
	|		WHEN DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		ELSE DocumentTable.Ref.TransferForActivity_
	|	END															AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentTable.ItemsLocationAttributes.Products.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(DocumentTable.ItemsLocationAttributes.Products.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               							AS AssetTaxClass,
	|	LineCodes.RowCode												AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS DocumentTable
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""Goods"" 														AS TabularSectionName,
	|	DocumentTable.LineNumber									AS LineNumber,
	|	CASE WHEN DocumentTable.Ref.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentTable.Ref.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END															AS Vendor,
	|	CASE WHEN DocumentTable.Ref.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentTable.Ref.Counterparty
	|		ELSE DocumentTable.Ref.Organization
	|	END															AS Counterparty,
	|	DocumentTable.VATRate 										AS VATRate,
	|	CASE
	|		WHEN DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		ELSE DocumentTable.Ref.TransferForActivity_
	|	END															AS VATTaxation,
	|	CASE
	|		WHEN DocumentTable.Ref.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer)
	|			THEN VALUE(Enum.AssetKinds.GoodsTaxAgent)
	|		WHEN DocumentTable.Products.ItemsType IN
	|		  (VALUE(Enum.ItemsTypes.OwnGoods), VALUE(Enum.ItemsTypes.ReusablePackage))
	|			THEN ISNULL(DocumentTable.Products.FinancialAccountingGroup.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods))
	|		WHEN DocumentTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		  AND NOT DocumentTable.ToExpenseAs
	|			THEN VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|		WHEN ISNULL(DocumentTable.ExpenseItem.VATAssetTaxClass, VALUE(Enum.AssetKinds.EmptyRef)) <>
	|		  VALUE(Enum.AssetKinds.EmptyRef)
	|			THEN DocumentTable.ExpenseItem.VATAssetTaxClass
	|		ELSE VALUE(Enum.AssetKinds.OtherWorksAndServices)
	|	END                               							AS AssetTaxClass,
	|	LineCodes.RowCode												AS RowCode
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS DocumentTable
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfReceiptOfGoods(Query, QueryTexts) Export
	
	RegisterName = "TTTableOfReceiptOfGoods";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	GoodsTable.ItemsLocationAttributes.Products                       AS Products,
	|	GoodsTable.ItemsLocationAttributes.Products.ItemsType       AS ItemsType,
	|	GoodsTable.ItemsLocationAttributes.Products.TracedGoods	AS TracedGoods,
	|	GoodsTable.ItemsLocationAttributes.Characteristic                     AS Characteristic,
	|	GoodsTable.ItemsLocationAttributes.Series                              AS Series,
	|	GoodsTable.ItemsLocationAttributes.Purpose                         AS Purpose,
	|	GoodsTable.RecipientInventoryOwnerAttribute       AS InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute.InventoryType       AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType      AS CCDNumberCCDNumberType,
	|	GoodsTable.Count                 AS Count,
	|	GoodsTable.QuantityByGBRN           AS QuantityByGBRN,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN GoodsTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN AnalyticsVendorForWork.DimensionKey
	|		ELSE GoodsTable.ItemsLocationAttributes
	|	END                                           AS ItemsLocationAttributes,
	|	GoodsTable.ByUninvoicedGoods AS ByUninvoicedGoods,
	|
	|	CASE WHEN &ThisIsTransferToCommission THEN
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)
	|	WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	ELSE
	|		&VATTaxation
	|	END                                    AS VATTaxation
	|INTO TTTableOfReceiptOfGoods
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS GoodsTable
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsVendorForWork
	|	ON
	|		GoodsTable.ItemsLocationAttributes.Products = AnalyticsVendorForWork.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = AnalyticsVendorForWork.Characteristic
	|		AND GoodsTable.Department = AnalyticsVendorForWork.StorageLocation
	|		AND GoodsTable.ItemsLocationAttributes.Purpose = AnalyticsVendorForWork.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsVendorForWork.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsVendorForWork.ProductCostElement
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &SpecifyCCDNumbers
	|	
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Products                  AS Products,
	|	GoodsTable.Products.ItemsType  AS ItemsType,
	|	GoodsTable.Products.TracedGoods AS TracedGoods,
	|	GoodsTable.Characteristic                AS Characteristic,
	|	GoodsTable.Series                         AS Series,
	|	GoodsTable.Purpose                    AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute                    AS InventoryOwnerAttribute,
	|	GoodsTable.InventoryOwnerAttribute.InventoryType         AS InventoryOwnerAttributeIsTypeOfInventory,
	|	GoodsTable.CCDNumber                      AS CCDNumber,
	|	GoodsTable.CCDNumber.CCDNumberType         AS CCDNumberCCDNumberType,
	|	GoodsTable.Count                    AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END                                       AS QuantityByGBRN,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.ItemsLocationAttributes    AS ItemsLocationAttributes,
	|	GoodsTable.ByUninvoicedGoods AS ByUninvoicedGoods,
	|
	|	CASE WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	ELSE
	|		&VATTaxation
	|	END                                       AS VATTaxation
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS GoodsTable
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &SpecifyCCDNumbers
	|	AND (GoodsTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|		OR (GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting))
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
	                                                                         Query.Parameters.Currency,
	                                                                         Query.Parameters.Period,
	                                                                         Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",            Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",           Coefficients.FactorOfConversionToCurrencyOfRegul);
	RatePeriod = Query.Parameters.Period;
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	SetRequestParametersCurrencyCoefficients(Query);
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType    AS ItemsType,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                    AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                  AS Characteristic,
	|	CASE
	|		WHEN TableTypesOfStocks_.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                              AS ThisIsTraceableWork,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS SupplierProductAnalysis,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	AnalyticsProviderWithoutAssignment.DimensionKey      AS AnalysisOfProductsSupplierWithoutAssignment,
	|	CommitteeKeys.DimensionKey                       AS CommitteeProductAnalysis,
	|	DimensionConsignee.DimensionKey                 AS AnalysisOfCommissionAgentProducts,
	|	TableTypesOfStocks_.ItemsLocationAttributes      AS DimensionOfProductItemClient,
	|	AnalyticsProviderWithoutAssignment.DimensionKey      AS ProductAnalysisClientWithoutAssignment,
	|
	|	TableTypesOfStocks_.VATRate                       AS VATRate,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType           AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency               AS StockTypeCurrency,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute            AS RecipientInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ByUninvoicedGoods AS ByUninvoicedGoods,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType           AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT                       AS AmountIncludingVAT,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                    AS AmountIncludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                     AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                  AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                   AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                 AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                    AS VATAmountCompl,
	|
	|	TableTypesOfStocks_.AmountARAP             AS AmountARAP,
	|	TableTypesOfStocks_.AmountVATARAP          AS AmountVATARAP,
	|
	|	TableTypesOfStocks_.RowID             AS RowID,
	|	TableTypesOfStocks_.VATAmount                        AS VATAmount,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			   AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	   AS VATActivityType, // Recipient's VAT taxation type of activity
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes    AS LotVendorAttributes,
	|	TableTypesOfStocks_.ExciseTaxAmount                     AS ExciseAmountInCurrencyLocal,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS SupplierSWarehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType AS RecipientInventoryType,
	|
	|	CASE
	|		WHEN &ThisIsTransferToCommission
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(TableTypesOfStocks_.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT TableTypesOfStocks_.ToExpenseAs
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN TableTypesOfStocks_.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END                                              AS VATTaxation, // Sender's VAT Taxation type of activity
	|	TableTypesOfStocks_.RowID             AS FinRecordID,
	|	TableTypesOfStocks_.Ref.ARAPObjectOfRecipient.UUID AS IDOfRecipientSFinRecord,
	|	TableTypesOfStocks_.Department AS Department,
	|	TableTypesOfStocks_.ExpenseItem AS ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableTypesOfStocks_.ToExpenseAs AS ToExpenseAs
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsProviderWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsProviderWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsProviderWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsProviderWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsProviderWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsProviderWithoutAssignment.ProductCostElement
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsProviderWithoutAssignment.Purpose
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS DimensionConsignee
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = DimensionConsignee.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = DimensionConsignee.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = DimensionConsignee.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionConsignee.Series
	|		AND &CompanyRecipient = DimensionConsignee.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionConsignee.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommitteeKeys.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommitteeKeys.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeKeys.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(Query, QueryTexts)
	
	RegisterName = "TTAgencyServices";
	
	QueryText =
	"SELECT DISTINCT
	|	CASE WHEN NOT Services.Ref IS NULL
	|			THEN Services.Ref
	|		WHEN NOT Terms.Ref IS NULL
	|			THEN Terms.Ref
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|			THEN ServicesAgreementClosed.Ref
	|		ELSE ISNULL(AgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE WHEN NOT Services.Ref IS NULL
	|				THEN Services.Ref.Currency
	|		WHEN NOT Terms.Ref IS NULL
	|				THEN Terms.Currency
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|				THEN ServicesAgreementClosed.Ref.Currency
	|		ELSE ISNULL(AgreementClosed.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products     AS Products,
	|	ToRegister.Characteristic   AS Characteristic,
	|	ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms
	|	ON Terms.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND Terms.Organization = &Organization
	|		AND Terms.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND Terms.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND (&Period >= Terms.ValidityStartDate
	|			AND (&Period <= Terms.ValidityEndDate
	|			OR Terms.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS Services
	|	ON Terms.Ref = Services.Ref
	|		AND ToRegister.Products = Services.Products
	|		AND ToRegister.Characteristic = Services.Characteristic
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementClosed
	|	ON AgreementClosed.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND AgreementClosed.Organization = &Organization
	|		AND AgreementClosed.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (&Period >= AgreementClosed.ValidityStartDate
	|			AND (&Period <= AgreementClosed.ValidityEndDate
	|			OR AgreementClosed.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS ServicesAgreementClosed
	|	ON AgreementClosed.Ref = ServicesAgreementClosed.Ref
	|		AND ToRegister.Products = ServicesAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServicesAgreementClosed.Characteristic
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Organization
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|	/ (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		Currency IN (
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.StockTypeCurrency AS Currency
	|			FROM
	|				TTTypesOfStocks AS TableTypesOfStocks_
	|			WHERE
	|				TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			
	|			UNION ALL
	|			
	|			SELECT DISTINCT
	|				AgentServices.Currency AS Currency
	|			FROM
	|				TTAgencyServices AS AgentServices
	|			) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTOperationServices(Query, QueryTexts)
	
	RegisterName = "TTOperationServices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf; 
	
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.Products.ItemsType                AS ItemsType,
	|	GoodsTable.Products                                AS Products,
	|	GoodsTable.Characteristic                              AS Characteristic,
	|	GoodsTable.Purpose                                  AS Purpose,
	|
	|	(CASE GoodsTable.Products.ItemsType
	|		WHEN VALUE(Enum.ItemsTypes.OperationService) THEN GoodsTable.ItemsLocationAttributes
	|		ELSE DimensionWorks.DimensionKey END)              AS RecipientProductAnalysis,
	|	(CASE GoodsTable.Products.ItemsType
	|		WHEN VALUE(Enum.ItemsTypes.OperationService) THEN AnalyticsWithoutAssignment.DimensionKey
	|		ELSE AnalyticsOfWorkWithoutAssignment.DimensionKey END) AS ProductAnalysisRecipientWithoutAssignment,
	|
	|	GoodsTable.ItemsLocationAttributes                  AS DimensionOfProductItem,
	|	AnalyticsWithoutAssignment.DimensionKey                      AS AnalysisOfProductsWithoutAssignment,
	|
	|	GoodsTable.VATRate                                   AS VATRate,
	|	GoodsTable.ExpenseItem                              AS ExpenseItem,
	|	GoodsTable.ExpenseItem.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	GoodsTable.DimensionOfExpenses                           AS DimensionOfExpenses,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			   		  AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation			  AS VATActivityType, // Recipient's VAT taxation type of activity
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes    		  AS LotVendorAttributes,
	|	GoodsTable.InventoryOwnerAttribute                                  AS InventoryOwnerAttribute,
	|	UNDEFINED                                              AS RecipientInventoryOwnerAttribute,
	|	(CASE GoodsTable.Products.ItemsType
	|		WHEN VALUE(Enum.ItemsTypes.OperationService) THEN &LineOfBusiness
	|		ELSE GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness END) AS LineOfBusiness,
	|
	|	GoodsTable.Count                                  AS Count,
	|	GoodsTable.AmountIncludingVAT                                   AS AmountIncludingVAT,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                           AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                         AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                            AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                        AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                           AS VATAmountCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                          AS AmountIncludingVATCompl,
	|
	|	GoodsTable.RowID                         AS RowID,
	|	GoodsTable.VATAmount                                    AS VATAmount,
	|	GoodsTable.ExpenseItem.SeparateVATAccountingOption   AS SeparateVATAccountingOption,
	|	GoodsTable.AmountARAP                         AS AmountARAP,
	|	GoodsTable.AmountVATARAP                      AS AmountVATARAP,
	|
	|	GoodsTable.ItemsLocationAttributes.StorageLocation    AS Warehouse,
	|
	|	CASE
	|		WHEN &ThisIsTransferToCommission
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT GoodsTable.ToExpenseAs
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END                                                     AS VATTaxation, // Sender's VAT Taxation type of activity
	|
	|	AgentServices.Terms                                AS Terms,
	|	AgentServices.Currency                                    AS Currency,
	|	ISNULL(PrincipalKeys.DimensionKey, UNDEFINED)     AS PrincipalProductAnalysis,
	|	ISNULL(AgentServices.Principal, UNDEFINED)         AS Principal,
	|	GoodsTable.Department                               AS Department,
	|	GoodsTable.ToExpenseAs                            AS ToExpenseAs,
	|	GoodsTable.RowID                         AS FinRecordID,
	|	GoodsTable.Ref.ARAPObjectOfRecipient.UUID AS IDOfRecipientSFinRecord,
	|	FALSE                                                      AS ThisIsTraceableWork
	|
	|INTO TTOperationServices
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS GoodsTable
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|	GoodsTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		GoodsTable.Ref = Amounts.Ref
	|		AND GoodsTable.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS DimensionWorks
	|	ON
	|		  DimensionWorks.Products   = GoodsTable.Products
	|		AND DimensionWorks.Characteristic = GoodsTable.Characteristic
	|		AND DimensionWorks.Purpose     = GoodsTable.Purpose
	|		AND DimensionWorks.StorageLocation  = GoodsTable.Department
	|		AND DimensionWorks.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionWorks.ProductCostElement
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsOfWorkWithoutAssignment
	|	ON
	|		  DimensionWorks.Products = AnalyticsOfWorkWithoutAssignment.Products
	|		AND DimensionWorks.Characteristic = AnalyticsOfWorkWithoutAssignment.Characteristic
	|		AND DimensionWorks.Series = AnalyticsOfWorkWithoutAssignment.Series
	|		AND DimensionWorks.StorageLocation = AnalyticsOfWorkWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsOfWorkWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsOfWorkWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON GoodsTable.Products = AgentServices.Products
	|		AND GoodsTable.Characteristic = AgentServices.Characteristic
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS PrincipalKeys
	|	ON PrincipalKeys.Products = AgentServices.Products
	|		AND PrincipalKeys.Characteristic = AgentServices.Characteristic
	|		AND PrincipalKeys.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND PrincipalKeys.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND PrincipalKeys.StorageLocation = AgentServices.Principal
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = PrincipalKeys.ProductCostElement
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Products.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|													VALUE(Enum.ItemsTypes.Work_5))
	|	AND GoodsTable.ItemsLocationAttributes NOT IN
	|		(SELECT DISTINCT
	|			InventoryKinds.ItemsLocationAttributes
	|		FROM
	|			Document.CustomerInvoiceIntercompany.InventoryKinds AS InventoryKinds
	|		WHERE
	|			InventoryKinds.Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	CatalogProducts.ItemsType                    AS ItemsType,
	|	Dimension.Products                                    AS Products,
	|	Dimension.Characteristic                                  AS Characteristic,
	|	Dimension.Purpose                                      AS Purpose,
	|
	|	DimensionWorks.DimensionKey                             AS RecipientProductAnalysis,
	|	AnalyticsOfWorkWithoutAssignment.DimensionKey                AS ProductAnalysisRecipientWithoutAssignment,
	|
	|	GoodsTable.ItemsLocationAttributes                  AS DimensionOfProductItem,
	|	AnalyticsWithoutAssignment.DimensionKey                      AS AnalysisOfProductsWithoutAssignment,
	|
	|	GoodsTable.VATRate                                   AS VATRate,
	|	GoodsTable.ExpenseItem                              AS ExpenseItem,
	|	GoodsTable.ExpenseItem.CostAllocationOptionLocal AS CostAllocationOptionLocal,
	|	GoodsTable.DimensionOfExpenses                           AS DimensionOfExpenses,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			   		  AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation			  AS VATActivityType, // Recipient's VAT taxation type of activity
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes    		  AS LotVendorAttributes,
	|	GoodsTable.InventoryOwnerAttribute                                  AS InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute                        AS RecipientInventoryOwnerAttribute,
	|	Dimension.Purpose.LineOfBusiness              AS LineOfBusiness,
	|
	|	GoodsTable.Count                                  AS Count,
	|	GoodsTable.AmountIncludingVAT                                   AS AmountIncludingVAT,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                           AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                         AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                            AS VATAmountMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                        AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                           AS VATAmountCompl,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                          AS AmountIncludingVATCompl,
	|
	|	GoodsTable.RowID                         AS RowID,
	|	GoodsTable.VATAmount                                    AS VATAmount,
	|	GoodsTable.ExpenseItem.SeparateVATAccountingOption   AS SeparateVATAccountingOption,
	|	GoodsTable.AmountARAP                         AS AmountARAP,
	|	GoodsTable.AmountVATARAP                      AS AmountVATARAP,
	|
	|	GoodsTable.ItemsLocationAttributes.StorageLocation    AS Warehouse,
	|
	|	CASE
	|		WHEN &ThisIsTransferToCommission
	|			THEN VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		WHEN ISNULL(GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT GoodsTable.ToExpenseAs
	|			THEN GoodsTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN GoodsTable.VATRate = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		 AND &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE &VATTaxation
	|	END                                                     AS VATTaxation, // Sender's VAT Taxation type of activity
	|
	|	UNDEFINED                                              AS Terms,
	|	UNDEFINED                                              AS Currency,
	|	UNDEFINED                                              AS PrincipalProductAnalysis,
	|	UNDEFINED                                              AS Principal,
	|	GoodsTable.Department                               AS Department,
	|	GoodsTable.ToExpenseAs                            AS ToExpenseAs,
	|	GoodsTable.RowID                         AS FinRecordID,
	|	GoodsTable.Ref.ARAPObjectOfRecipient.UUID AS IDOfRecipientSFinRecord,
	|	TRUE                                                    AS ThisIsTraceableWork
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS GoodsTable
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON GoodsTable.ItemsLocationAttributes = Dimension.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON GoodsTable.Ref = Amounts.Ref
	|			AND GoodsTable.RowID = Amounts.RowID
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionWorks
	|		ON DimensionWorks.Products   = Dimension.Products
	|			AND DimensionWorks.Characteristic = Dimension.Characteristic
	|			AND DimensionWorks.Purpose     = Dimension.Purpose
	|			AND DimensionWorks.StorageLocation  = GoodsTable.Department
	|			AND DimensionWorks.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionWorks.ProductCostElement
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfWorkWithoutAssignment
	|		ON DimensionWorks.Products = AnalyticsOfWorkWithoutAssignment.Products
	|			AND DimensionWorks.Characteristic = AnalyticsOfWorkWithoutAssignment.Characteristic
	|			AND DimensionWorks.Series = AnalyticsOfWorkWithoutAssignment.Series
	|			AND DimensionWorks.StorageLocation = AnalyticsOfWorkWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsOfWorkWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsOfWorkWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN Catalog.Products AS CatalogProducts
	|		ON Dimension.Products = CatalogProducts.Ref
	|		
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND CatalogProducts.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.CustomerInvoiceIntercompany.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.CustomerInvoiceIntercompany.Goods AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

Function QueryTextTTProductLines(Query, QueryTexts)
	
	RegisterName = "TTProductLines"; 
	
	QueryText = "
	|SELECT
	|	TableOfGoods.Ref                     AS Ref,
	|	TableOfGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableOfGoods.Package                   AS Package,
	|	MAX(TableOfGoods.LineNumber)      AS LineNumber
	|
	|INTO TTProductLines
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS TableOfGoods
	|WHERE
	|	TableOfGoods.Ref IN(&Ref)
	|
	|GROUP BY
	|	TableOfGoods.Ref,
	|	TableOfGoods.ItemsLocationAttributes,
	|	TableOfGoods.Package
	|
	|INDEX BY
	|	Ref,
	|	ItemsLocationAttributes,
	|	Package
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ =
	"SELECT
	|	HeaderData_.Date                    AS Period,
	|	InventoryTable.Ref               AS Ref,
	|	HeaderData_.BusinessOperation   AS BusinessOperation,
	|	HeaderData_.CompanyRecipient   AS Organization,
	|	HeaderData_.Department           AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                               AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                               AS Contract,
	|	HeaderData_.Shipper        AS Shipper,
	|	InventoryTable.Ref               AS DocumentAcquisitions,
	|	InventoryTable.Ref               AS OriginalTradeDocument,
	|	FALSE                                AS ErrorCorrection,
	|	FALSE                                AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                AS ReduceAmountVATDeduction,
	|	UNDEFINED                        AS PurchaseAdjustmentDocument,
	|	HeaderData_.VATTaxation      AS VATTaxation,
	|	HeaderData_.TransferForActivity_ AS VATActivityType,
	|	Dimension.Products              AS Products,
	|	Dimension.Characteristic            AS Characteristic,
	|	InventoryTable.VATRate            AS VATRate,
	|	InventoryTable.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	InventoryTable.CCDNumber             AS CCDNumber,
	|	InventoryTable.RowID  AS RowID,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                AS PurchasePerBatchOfProduction,
	|	UNDEFINED                        AS LineOfBusinessOfProductionParty,
	|	InventoryTable.ToExpenseAs		AS ToExpenseAs,
	|	UNDEFINED                        AS ExpenseItem,
	|	UNDEFINED                        AS DimensionOfExpenses,
	|	UNDEFINED                        AS ItemOfOtherAssets,
	|	UNDEFINED                        AS AnalyticsOfOtherAssets,
	|	Dimension.Purpose                AS Purpose,
	|	VALUE(Catalog.BusinessStructure.EmptyRef) AS AccountingDivision,
	|	HeaderData_.ARAPObjectOfRecipient.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	HeaderData_.Date                    AS Period,
	|	TableOfGoods.Ref               AS Ref,
	|	HeaderData_.BusinessOperation   AS BusinessOperation,
	|	HeaderData_.CompanyRecipient   AS Organization,
	|	HeaderData_.Department           AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                               AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                               AS Contract,
	|	HeaderData_.Shipper        AS Shipper,
	|	TableOfGoods.Ref               AS DocumentAcquisitions,
	|	TableOfGoods.Ref               AS OriginalTradeDocument,
	|	FALSE                                AS ErrorCorrection,
	|	FALSE                                AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                AS ReduceAmountVATDeduction,
	|	UNDEFINED                        AS PurchaseAdjustmentDocument,
	|	HeaderData_.VATTaxation      AS VATTaxation,
	|	HeaderData_.TransferForActivity_ AS VATActivityType,
	|	TableOfGoods.Products         AS Products,
	|	TableOfGoods.Characteristic       AS Characteristic,
	|	TableOfGoods.VATRate            AS VATRate,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableOfGoods.RowID  AS RowID,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                AS PurchasePerBatchOfProduction,
	|	UNDEFINED                        AS LineOfBusinessOfProductionParty,
	|	TableOfGoods.ToExpenseAs		AS ToExpenseAs,
	|	TableOfGoods.ExpenseItem       AS ExpenseItem,
	|	TableOfGoods.DimensionOfExpenses    AS DimensionOfExpenses,
	|	UNDEFINED                        AS ItemOfOtherAssets,
	|	UNDEFINED                        AS AnalyticsOfOtherAssets,
	|	TableOfGoods.Purpose           AS Purpose,
	|	TableOfGoods.Department        AS AccountingDivision,
	|	TableOfGoods.Ref.ARAPObjectOfRecipient.UUID  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS TableOfGoods
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND ProductsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND NOT (ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND ProductsTable.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting)
	|";
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductLines", QueryTexts) Then
		QueryTextTTProductLines(Query, QueryTexts);
	EndIf; 
	
	ValueText_ = "
	|SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.CompanyRecipient
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	HeaderData_.Shipper       AS Shipper,
	|	HeaderData_.GoodsRecipient        AS GoodsRecipient,
	|	FALSE                               AS RetailSaleOfGoods,
	|	InventoryTable.Ref              AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                       AS ImplementationAdjustmentDocument,
	|	UNDEFINED                       AS ConsignedGoodsCustomer,
	|	FALSE                               AS SalesViaCommissionAgent,
	|	FALSE                               AS ErrorCorrection,
	|	FALSE                               AS AdjustmentUnderApprovalOfParties,
	|	FALSE                               AS ReduceAmountVATDeduction,
	|	HeaderData_.ARAPObject         AS ARAPObject,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	Dimension.Series                    AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	""""                               AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Count
	|		ELSE InventoryTable.NumberOfPackages
	|	END                              AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN Dimension.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasurementInventory
	|	END                              AS UnitOfMeasure,
	|	InventoryTable.QuantityByGBRN    AS QuantityByGBRN,
	|	InventoryTable.ExciseTaxAmount         AS ExciseTaxAmount,
	|	InventoryTable.CCDNumber            AS CCDNumber,
	|	InventoryTable.VATRate           AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	InventoryTable.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	ProductLines_2.LineNumber          AS LineNumber,
	|	InventoryTable.RowID AS RowID,
	|	InventoryTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|	
	|		LEFT JOIN TTProductLines AS ProductLines_2
	|		ON InventoryTable.Ref = ProductLines_2.Ref
	|			AND InventoryTable.ItemsLocationAttributes = ProductLines_2.ItemsLocationAttributes
	|			AND InventoryTable.Package = ProductLines_2.Package
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	HeaderData_.Date                  AS Period,
	|	TableOfGoods.Ref             AS Ref,
	|	HeaderData_.BusinessOperation AS BusinessOperation,
	|	HeaderData_.Organization           AS Organization,
	|	HeaderData_.Department         AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.CompanyRecipient
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                             AS Contract,
	|	HeaderData_.Shipper      AS Shipper,
	|	HeaderData_.GoodsRecipient       AS GoodsRecipient,
	|	FALSE                              AS RetailSaleOfGoods,
	|	TableOfGoods.Ref             AS DocumentSalesOfGoodsAndServices,
	|	UNDEFINED                      AS ImplementationAdjustmentDocument,
	|	UNDEFINED                      AS ConsignedGoodsCustomer,
	|	FALSE                              AS SalesViaCommissionAgent,
	|	FALSE                              AS ErrorCorrection,
	|	FALSE                              AS AdjustmentUnderApprovalOfParties,
	|	FALSE                              AS ReduceAmountVATDeduction,
	|	HeaderData_.ARAPObject        AS ARAPObject,
	|	HeaderData_.VATTaxation    AS VATTaxation,
	|	TableOfGoods.Products       AS Products,
	|	TableOfGoods.Characteristic     AS Characteristic,
	|	TableOfGoods.Series              AS Series,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	""""                              AS Content,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN TableOfGoods.Count
	|		ELSE TableOfGoods.NumberOfPackages
	|	END                             AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN TableOfGoods.Products.UnitOfMeasure
	|		ELSE &RequestTextUnitOfMeasurementProducts
	|	END                             AS UnitOfMeasure,
	|	0                                 AS QuantityByGBRN,
	|	0                                 AS ExciseTaxAmount,
	|	TableOfGoods.CCDNumber           AS CCDNumber,
	|	TableOfGoods.VATRate          AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	TableOfGoods.LineNumber        AS LineNumber,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS TableOfGoods
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|WHERE
	|	TableOfGoods.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsSaleToAnotherCompany)
	|	AND ProductsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|	AND NOT (ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND ProductsTable.TracedGoods
	|			AND &UseTraceableImportedGoodsAccounting)
	|";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasurementInventory",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryTable.Package",
			"Dimension.Products"));
	ValueText_ = StrReplace(
		ValueText_,
		"&RequestTextUnitOfMeasurementProducts",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"TableOfGoods.Package",
			"TableOfGoods.Products"));
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.CompanyRecipient AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectOfRecipient AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.CustomerInvoiceIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.CompanyRecipient AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CustomerInvoiceIntercompany.ARAPDetailsWithVendor AS Table
		|		LEFT JOIN Document.CustomerInvoiceIntercompany AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.CustomerInvoiceIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CustomerInvoiceIntercompany.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.CustomerInvoiceIntercompany AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region AddTextsToReflectMutualSettlements
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                               AS Ref,
		|	Table.CompanyRecipient                AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                        AS Partner,
		|	Table.Date                                 AS RecorderDate,
		|	Table.Number                                AS RecorderNumber,
		|
		|	Table.ARAPObjectOfRecipient             AS ARAPObject,
		|	Table.PaymentDate                          AS PaymentDate,
		|	UNDEFINED                                 AS PaymentOption,
		|	UNDEFINED                                 AS PurchaseOrder_,
		|	Table.DocumentAmount                       AS Sum,
		|	Table.AmountARAP                  AS AmountARAP,
		|	0                                            AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings                      AS ARAPObjectSettings,
		|	FALSE                                         AS InvoiceForOrders,
		|	Table.ARAPCurrency                 AS ARAPCurrency,
		|	Table.BusinessOperation                AS BusinessOperation,
		|	Table.PaymentMethod                          AS PaymentMethod,
		|	Table.Currency                               AS DocumentCurrency,
		|	Table.Date                                 AS DateOfCourse,
		|	UNDEFINED                                 AS LinkedDocument
		|FROM
		|	Document.CustomerInvoiceIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                               AS Ref,
		|	Table.CompanyRecipient                AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                        AS Partner,
		|	Table.Date                                 AS RecorderDate,
		|	Table.Number                                AS RecorderNumber,
		|	Table.PaymentDate                          AS PaymentDate,
		|	
		|	Table.ARAPObjectOfRecipient             AS ARAPObject,
		|	Table.ARAPObjectSettings                      AS ARAPObjectSettings,
		|	FALSE                                         AS InvoiceForOrders,
		|	FALSE                                         AS ExceedingOrder,
		|	UNDEFINED                                 AS PurchaseOrder_,
		|	Table.AmountARAP                  AS AmountDue,
		|	Table.ARAPCurrency                 AS ARAPCurrency,
		|	Table.BusinessOperation                AS BusinessOperation,
		|	Table.PaymentMethod                          AS PaymentMethod,
		|	Table.Currency                               AS DocumentCurrency,
		|	UNDEFINED                                 AS PaymentOption,
		|	UNDEFINED                                 AS LinkedDocument
		|FROM
		|	Document.CustomerInvoiceIntercompany AS Table
		|WHERE
		|	NOT Table.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
		|	AND Table.Ref IN (&Ref)";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                          AS Ref,
		|	Table.Ref.CompanyRecipient    AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                   AS Partner,
		|	
		|	Table.ARAPObject                  AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectOfRecipient AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency     AS ARAPCurrency,
		|	Table.AmountARAP             AS AmountARAP,
		|	Table.Ref.Currency                   AS DocumentCurrency,
		|	Table.Sum                           AS Sum,
		|
		|	Table.Ref.Date                     AS DateOfCourse,
		|	Table.Ref.Date                     AS RecorderDate,
		|	Table.Ref.Number                    AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|	
		|FROM
		|	Document.CustomerInvoiceIntercompany.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	#EndRegion
	
	#Region AddTextsToReflectSalesSettlements
	
	#Region Sale
	
	TextSale =
		"SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	
		|	Table.ARAPObject          AS ARAPObject,
		|	Table.PaymentDate             AS PaymentDate,
		|	UNDEFINED                    AS SalesOrder_,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.AmountARAP     AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|	Table.DocumentAmount          AS Sum,
		|	
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.ARAPCurrency    AS ARAPCurrency,
		|	Table.BusinessOperation   AS BusinessOperation,
		|	Table.Date                    AS DateOfCourse,
		|	Table.Currency                  AS DocumentCurrency,
		|	UNDEFINED                    AS PaymentOption,
		|	FALSE                            AS ExceedingOrder,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CustomerInvoiceIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Organization                    AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                  AS Partner,
		|	
		|	Table.ARAPObject                 AS ARAPObject,
		|	Table.Date                           AS RecorderDate,
		|	Table.Number                          AS RecorderNumber,
		|	Table.ARAPObjectSettings                AS ARAPObjectSettings,
		|	Table.ARAPCurrency           AS ARAPCurrency,
		|	Table.Currency                         AS DocumentCurrency,
		|	Table.BusinessOperation          AS BusinessOperation,
		|	Table.PaymentMethod                    AS PaymentMethod,
		|	
		|	Table.PaymentDate                    AS PaymentDate,
		|	UNDEFINED                           AS PaymentOption,
		|	Table.AmountARAP            AS AmountDue,
		|	
		|	TRUE                                 AS ExcludeDuringControl,
		|	FALSE                                   AS InvoiceForOrders,
		|	UNDEFINED                           AS SalesOrder_,
		|	FALSE                                   AS ExceedingOrder,
		|	UNDEFINED                           AS LinkedDocument
		|	
		|FROM
		|	Document.CustomerInvoiceIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)";
	
	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                 AS Ref,
		|	Table.Ref.Organization                     AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                          AS Partner,
		|
		|	Table.ARAPObject                         AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                  AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency            AS ARAPCurrency,
		|	Table.AmountARAP                    AS AmountARAP,
		|	Table.Ref.Currency                          AS DocumentCurrency,
		|	Table.Sum                                  AS Sum,
		|
		|	Table.Ref.Date                            AS DateOfCourse,
		|	Table.Ref.Date                            AS RecorderDate,
		|	Table.Ref.Number                           AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|	
		|FROM
		|	Document.CustomerInvoiceIntercompany.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
	#EndRegion
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                                           AS Document,
	|	&Period                                                           AS Period,
	|	&Ref                                                           AS Recorder,
	|	SeriesTable.Products                                         AS Products,
	|	SeriesTable.Characteristic                                       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                             AS Purpose,
	|	SeriesTable.Series                                                AS Series,
	|	SeriesTable.Count                                           AS Count,
	|	&Warehouse                                                            AS Sender,
	|	&Warehouse                                                            AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)              AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	TRUE                                                            AS ThisIsWarehouseRecord
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfReceiptOfGoods", QueryTexts) Then
		QueryTextTTTableOfReceiptOfGoods(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period                                      AS Period,
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	&Organization                                 AS Organization,
	|	&Organization                                 AS ShipmentCompany,
	|	GoodsTable.Products                   AS Products,
	|	GoodsTable.Characteristic                 AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute           AS CorInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                       AS CCDNumber,
	|	SUM(GoodsTable.Count)              AS Count,
	|	SUM(GoodsTable.QuantityByGBRN)        AS QuantityByGBRN,
	|	GoodsTable.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	&BusinessOperation                       AS BusinessOperation,
	|	GoodsTable.VATTaxation             AS VATTaxation,
	|	GoodsTable.DimensionOfProductItemClient    AS CorItemsLocationAttributes,
	|	FALSE                                         AS Primary
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	NOT GoodsTable.ByUninvoicedGoods
	|	AND GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.Work_5),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.RecipientInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.SupplierProductAnalysis,
	|	GoodsTable.DimensionOfProductItemClient,
	|	GoodsTable.VATTaxation
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                  AS Period,
	|	VALUE(AccumulationRecordType.Receipt)   AS RecordType,
	|	&CompanyRecipient                   AS Organization,
	|	&Organization                             AS ShipmentCompany,
	|	GoodsTable.Products               AS Products,
	|	GoodsTable.Characteristic             AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	UNDEFINED                             AS CorInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                   AS CCDNumber,
	|	SUM(GoodsTable.Count)          AS Count,
	|	SUM(GoodsTable.QuantityByGBRN)        AS QuantityByGBRN,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&BusinessOperation                   AS BusinessOperation,
	|	GoodsTable.VATTaxation         AS VATTaxation,
	|	UNDEFINED                             AS CorItemsLocationAttributes,
	|	TRUE                                   AS Primary
	|FROM
	|	TTTableOfReceiptOfGoods AS GoodsTable
	|WHERE
	|	NOT GoodsTable.ByUninvoicedGoods
	|	AND GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.Work_5),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.VATTaxation";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfReceiptOfGoods", QueryTexts) Then
		QueryTextTTTableOfReceiptOfGoods(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT DISTINCT
	|	&Period                      AS DateOfReceipt,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	GoodsTable.Purpose     AS Purpose,
	|	GoodsTable.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber       AS CCDNumber
	|FROM
	|	TTTableOfReceiptOfGoods AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON
	|		  GoodsTable.InventoryOwnerAttribute     = UninvoicedReceipts.InventoryOwnerAttribute
	|		AND GoodsTable.Products   = UninvoicedReceipts.Products
	|		AND GoodsTable.Characteristic = UninvoicedReceipts.Characteristic 
	|		AND GoodsTable.Series          = UninvoicedReceipts.Series 
	|		AND GoodsTable.Purpose     = UninvoicedReceipts.Purpose 
	|		AND GoodsTable.CCDNumber       = UninvoicedReceipts.CCDNumber 
	|
	|WHERE
	|	NOT GoodsTable.ByUninvoicedGoods
	|	AND GoodsTable.ItemsType IN
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.Work_5),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND (UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period)
	|
	|ORDER BY
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.Purpose,
	|	GoodsTable.CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetParameterForPartnerAccountingAnalystRequestProvider(Query)
	
	If Query.Parameters.Property("AccountingAnalyticsByPartnersSupplier") Then
		Return;
	EndIf;
	
	StructureSupplier = New Structure;
	StructureSupplier.Insert("Organization", Query.Parameters.CompanyRecipient);
	StructureSupplier.Insert("Partner",     Catalogs.Partners.OurEnterprise);
	StructureSupplier.Insert("Counterparty",  Query.Parameters.Organization);
	StructureSupplier.Insert("Contract",     Query.Parameters.Contract);
	StructureSupplier.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AccountingAnalyticsByPartnersSupplier = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureSupplier);
	
	Query.SetParameter("AccountingAnalyticsByPartnersSupplier", AccountingAnalyticsByPartnersSupplier);
	
EndProcedure

Procedure SetParameterForPartnerAccountingAnalyticsRequestClient(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartnersClient") Then
		Return;
	EndIf;
	
	StructureClient = New Structure;
	StructureClient.Insert("Organization", Query.Parameters.Organization);
	StructureClient.Insert("Partner",     Catalogs.Partners.OurEnterprise);
	StructureClient.Insert("Counterparty",  Query.Parameters.CompanyRecipient);
	StructureClient.Insert("Contract",     Query.Parameters.Contract);
	StructureClient.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AccountingDimensionByPartnersClient = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureClient);
	
	Query.SetParameter("AccountingDimensionByPartnersClient", AccountingDimensionByPartnersClient);
	
EndProcedure

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&EndOfPeriod                                     AS Period,
	|	VALUE(AccumulationRecordType.Expense)            AS RecordType,
	|	&Organization                                      AS CompanyOwner,
	|	&CompanyRecipient                            AS ShipmentCompany,
	|	&Warehouse                                            AS Warehouse,
	|	TableTypesOfStocks_.Products                   AS Products,
	|	TableTypesOfStocks_.Characteristic                 AS Characteristic,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute           AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber                       AS CCDNumber,
	|	TableTypesOfStocks_.Count                     AS Count,
	|	TableTypesOfStocks_.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	&BusinessOperation                            AS BusinessOperation,
	|	TableTypesOfStocks_.VATTaxation             AS VATTaxation,
	|	TRUE                                            AS Primary
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ByUninvoicedGoods
	|	AND TableTypesOfStocks_.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)            AS RecordType,
	|	&Period                                           AS Period,
	|	&Organization                                      AS Organization,
	|	TableTypesOfStocks_.StockTypeCurrency               AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products                   AS Products,
	|	TableTypesOfStocks_.Characteristic                 AS Characteristic,
	|	TableTypesOfStocks_.CommitteeProductAnalysis AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber                       AS CCDNumber,
	|	&Ref                                           AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation                            AS BusinessOperation,
	|	TableTypesOfStocks_.Count                     AS Count,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END                                             AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END                                             AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END                                             AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count                     AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN               AS QuantityForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.Currency = &Currency
	|			THEN TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END                                             AS RevenueAmountToRegister,
	|	&IDARAPObject                     AS FinRecordID,
	|	&BusinessTransactionSetting                   AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID            AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.StockTypeCurrency = ExchangeRates.Currency
	|
	|WHERE
	|	NOT &ThisIsTransferToCommission
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	SetParameterForPartnerAccountingAnalyticsRequestClient(Query);
	
	QueryText =
	"SELECT
	|	&Period                                 AS Period,
	|	&Department                          AS Department,
	|	&AdjustmentPeriod_                    AS AdjustmentPeriod_,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.SupplierProductAnalysis
	|		ELSE TableTypesOfStocks_.AnalysisOfProductsSupplierWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	&AccountingDimensionByPartnersClient        AS AccountingDimensionByPartners,
	|	CASE WHEN &AccountingForIncomeUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED                            AS SalesOrder,
	|	TableTypesOfStocks_.InventoryType           AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute           AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END)                                  AS AccountingSection,
	|	UNDEFINED 							AS FinancialAccountingDimension,
	|	TableTypesOfStocks_.VATTaxation	AS VATActivityType,
	|
	|	&Manager                               AS Manager,
	|
	|	SUM(TableTypesOfStocks_.Count)    AS Count,
	|
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan)  AS RevenueAmount,
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan) AS RevenueAmountExcludingVAT,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl) AS RevenueAmountExclVATLocal,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl) AS RevenueAmountIncludingVATLocal,
	|
	|	SUM(CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountIncludingVATMan
	|	ELSE
	|		0
	|	END)                                  AS Cost,
	|
	|	SUM(CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan
	|	ELSE
	|		0
	|	END)                                  AS CostExcludingVAT,
	|
	|	SUM(CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	 AND &CompanyManagementAccounting THEN
	|		TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan
	|	ELSE
	|		0
	|	END)                                  AS CostMan,
	|
	|	SUM(CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.AmountExcludingVATCompl
	|	ELSE
	|		0
	|	END)                                  AS LocalCost,
	|
	|	0                                       AS ManualDiscount,
	|	0                                       AS DiscountMarkupAmount,
	|
	|	&Warehouse                                  AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END                                   AS Contract,
	|	UNDEFINED                            AS Terms,
	|
	|	&ARAPCurrency                   AS ARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency                                 AS DocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|	SUM(TableTypesOfStocks_.ExciseAmountInCurrencyLocal) AS ExciseAmountInCurrencyLocal,
	|	SUM(TableTypesOfStocks_.ExciseAmountInCurrencyMgmt)  AS ExciseAmountInCurrencyMgmt,
	|
	|	TableTypesOfStocks_.VATTaxation  AS VATTaxation,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		VALUE(Enum.BusinessTransactions.ConsignmentSale)
	|	ELSE
	|		&BusinessOperation
	|	END                                   AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END                                   AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject                         AS SourceOfARAPFinancialAccountingGroup,
	|
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate    AS VATRate
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	NOT &ThisIsTransferToCommission
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|
	|GROUP BY
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.SupplierProductAnalysis
	|		ELSE TableTypesOfStocks_.AnalysisOfProductsSupplierWithoutAssignment
	|	END,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	TableTypesOfStocks_.InventoryType,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE CASE WHEN TableTypesOfStocks_.ShopFloorStockroom
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|		END
	|	END),

	|	TableTypesOfStocks_.InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation,
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END, 
	|	TableTypesOfStocks_.RowID,
	|	TableTypesOfStocks_.FinRecordID,
	|	TableTypesOfStocks_.VATRate
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                             AS Period,
	|	&Department                      AS Department,
	|	&AdjustmentPeriod_                AS AdjustmentPeriod_,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.DimensionOfProductItem
	|		ELSE GoodsTable.AnalysisOfProductsWithoutAssignment
	|	END,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	&AccountingDimensionByPartnersClient    AS AccountingDimensionByPartners,
	|	CASE WHEN &AccountingForIncomeUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED                        AS SalesOrder,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END                               AS InventoryType,
	|	
	|	CASE 
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND GoodsTable.ThisIsTraceableWork
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END                        AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END) AS AccountingSection,
	|	UNDEFINED 						AS FinancialAccountingDimension,
	|	GoodsTable.VATTaxation 	AS VATActivityType,
	|
	|	&Manager                           AS Manager,
	|
	|	SUM(GoodsTable.Count)     AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan)   AS RevenueAmount,
	|	SUM(GoodsTable.AmountIncludingVATMan - GoodsTable.VATAmountMan) AS RevenueAmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS RevenueAmountExclVATLocal,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS RevenueAmountIncludingVATLocal,
	|
	|	SUM(CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN GoodsTable.AmountIncludingVATMan
	|		ELSE 0
	|		END)                            AS Cost,
	|	SUM(CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN GoodsTable.AmountIncludingVATMan - GoodsTable.VATAmountMan
	|		ELSE 0
	|		END)                            AS CostExcludingVAT,
	|	SUM(CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|	 	 AND &CompanyManagementAccounting
	|		THEN GoodsTable.AmountIncludingVATMan - GoodsTable.VATAmountMan
	|		ELSE 0
	|		END)                            AS CostMan,
	|	SUM(CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN GoodsTable.AmountExcludingVATCompl
	|		ELSE 0
	|		END)                            AS LocalCost,
	|
	|	0                                   AS ManualDiscount,
	|	0                                   AS DiscountMarkupAmount,
	|
	|	GoodsTable.Warehouse                 AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END                               AS Contract,
	|	UNDEFINED                        AS Terms,
	|
	|	&ARAPCurrency               AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency                             AS DocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT)      AS AmountInDocumentCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|	0                                   AS ExciseAmountInCurrencyLocal,
	|	0                                   AS ExciseAmountInCurrencyMgmt,
	|
	|	GoodsTable.VATTaxation    AS VATTaxation,
	|	&BusinessOperation              AS BusinessOperation,
	|
	|	GoodsTable.Products          AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject                     AS SourceOfARAPFinancialAccountingGroup,
	|
	|	GoodsTable.FinRecordID AS FinRecordID,
	|	&BusinessTransactionSetting      AS BusinessTransactionSetting,
	|	GoodsTable.VATRate              AS VATRate
	|	
	|FROM
	|	TTOperationServices AS GoodsTable
	|
	|WHERE
	|	NOT &ThisIsTransferToCommission
	|
	|GROUP BY
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.DimensionOfProductItem
	|		ELSE GoodsTable.AnalysisOfProductsWithoutAssignment
	|	END,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Principal,
	|	CASE
	|		WHEN GoodsTable.Principal <> UNDEFINED
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END,
	|	CASE 
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		 AND GoodsTable.ThisIsTraceableWork
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END,
	|	(CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) END),
	|	GoodsTable.VATTaxation,
	|	GoodsTable.RowID,
	|	GoodsTable.FinRecordID,
	|	GoodsTable.VATRate
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period                                AS Period,
	|	&Period                                AS RecorderDate,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	GoodsTable.Products             AS Products,
	|	GoodsTable.Characteristic           AS Characteristic,
	|	GoodsTable.Purpose               AS Purpose,
	|	GoodsTable.DimensionOfProductItem    AS ItemsLocationAttributes,
	|	GoodsTable.Count               AS Count,
	|	GoodsTable.VATTaxation       AS VATTaxation,
	|	FALSE                                   AS Primary
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ThisIsTraceableWork
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&Period                                       AS Period,
	|	&Period                                       AS RecorderDate,
	|	&CompanyRecipient                        AS Organization,
	|	GoodsTable.Department                   AS Department,
	|	GoodsTable.Products                    AS Products,
	|	GoodsTable.Characteristic                  AS Characteristic,
	|	GoodsTable.Purpose                      AS Purpose,
	|	GoodsTable.RecipientProductAnalysis AS ItemsLocationAttributes,
	|	GoodsTable.Count                      AS Count,
	|	GoodsTable.VATTaxation              AS VATTaxation,
	|	TRUE                                        AS Primary
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT GoodsTable.ThisIsTraceableWork
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableBatchesOfProductionCosts(Query, QueryTexts, Registers)
	
	RegisterName = "BatchesOfProductionCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&Period                                       AS Period,
	|	&CompanyRecipient                        AS Organization,
	|	GoodsTable.RecipientProductAnalysis AS ItemsLocationAttributes,
	|	GoodsTable.LotVendorAttributes            AS LotVendorAttributes,
	|	&Ref                                       AS DocumentInflow,
	|	GoodsTable.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	GoodsTable.Count                      AS Count,
	|	0                                             AS Cost,
	|	0                                             AS CostExcludingVAT,
	|	GoodsTable.AmountExcludingVATCompl                 AS LocalCost,
	|	CASE
	|		WHEN GoodsTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0
	|		ELSE GoodsTable.VATAmountCompl                   
	|	END                                         AS VATLocal,
	|	0                                             AS PermanentDifference,
	|	0                                             AS CostTD
	|
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &BatchAccountingVersion22
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Ref.Date AS Date,
	|	GoodsTable.Ref.Organization AS Organization,
	|	GoodsTable.Ref.Currency AS DocumentCurrency,
	|	GoodsTable.Ref.ARAPCurrency AS ARAPCurrency,
	|	GoodsTable.Ref.Date AS VATBasePeriod,
	|	GoodsTable.Ref.Date AS DateOfCourse,
	|
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.RowID AS RowID,
	|
	|	GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount AS AmountExcludingVAT,
	|	GoodsTable.VATRate AS VATRate,
	|	GoodsTable.VATAmount AS VATAmount,
	|	GoodsTable.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	CASE
	|		WHEN GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	GoodsTable.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS GoodsTable
	|
	|	INNER JOIN Catalog.Products AS ProductData_1
	|		ON GoodsTable.Products = ProductData_1.Ref
	|
	|WHERE
	|	GoodsTable.Ref IN (&Ref)
	|	AND (ProductData_1.ItemsType IN (VALUE(Enum.ItemsTypes.OperationService),
	|											VALUE(Enum.ItemsTypes.Work_5))
	|	AND NOT (ProductData_1.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|		AND ProductData_1.TracedGoods
	|		AND &UseTraceableImportedGoodsAccounting))
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	
	|	InventoryKinds.Ref AS Ref,
	|	InventoryKinds.Ref.Date AS Date,
	|	InventoryKinds.Ref.Organization AS Organization,
	|	InventoryKinds.Ref.Currency AS DocumentCurrency,
	|	InventoryKinds.Ref.ARAPCurrency AS ARAPCurrency,
	|	InventoryKinds.Ref.Date AS VATBasePeriod,
	|	InventoryKinds.Ref.Date AS DateOfCourse,
	|
	|	InventoryKinds.LineNumber AS LineNumber,
	|	InventoryKinds.RowID AS RowID,
	|
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVAT,
	|	InventoryKinds.VATRate AS VATRate,
	|	InventoryKinds.VATAmount AS VATAmount,
	|	InventoryKinds.AmountARAP AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	CASE
	|		WHEN InventoryKinds.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	InventoryKinds.Ref.ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany.InventoryKinds AS InventoryKinds
	|
	|WHERE
	|	InventoryKinds.Ref IN (&Ref)
	|";
	
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);

	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots("RowID");
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	&Period                                      AS Period,
	|	&CompanyRecipient                       AS Organization,
	|	GoodsTable.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	&Ref                                      AS DocumentInflow,
	|	GoodsTable.RecipientInventoryOwnerAttribute           AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes           AS LotVendorAttributes,
	|	SUM(GoodsTable.Count)              AS Count,
	|	0                                            AS Cost,
	|	0                                            AS CostExcludingVAT,
	|
	|	SUM(
	|		CASE
	|			WHEN GoodsTable.RecipientInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl
	|			ELSE GoodsTable.AmountExcludingVATCompl END
	|		) AS LocalCost,
	|	SUM(
	|		CASE 
	|			WHEN GoodsTable.RecipientInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|				THEN 0
	|			WHEN GoodsTable.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|				THEN 0
	|			ELSE GoodsTable.VATAmountCompl 
	|		END) AS VATLocal,
	|
	|	GoodsTable.Products                   AS Products,
	|	GoodsTable.Characteristic                 AS Characteristic,
	|	GoodsTable.VATTaxation             AS VATTaxation,
	|	&BusinessOperation                       AS BusinessOperation,
	|	TRUE                                       AS Primary,
	|	&Ref                                      AS DocumentSource
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	(GoodsTable.ItemsType IN (VALUE(Enum.ItemsTypes.OwnGoods),
	|									  VALUE(Enum.ItemsTypes.ReusablePackage))
	|		OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			AND GoodsTable.Products.TracedGoods)
	|	AND &BatchAccountingVersion21
	|
	|GROUP BY
	|	GoodsTable.SupplierProductAnalysis,
	|	GoodsTable.RecipientInventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.VATTaxation";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
#Region UninvoicedReceipt
	UninvoicedReceipt =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromAnotherCompany) AS BusinessOperation,	
	|	&CompanyRecipient AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	TableTypesOfStocks_.SupplierSWarehouse AS Warehouse,
	|	TableTypesOfStocks_.RecipientInventoryType AS InventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Organization
	|	END AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|	
	|	SUM(TableTypesOfStocks_.Count) AS Count,
	|
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan) AS Sum,
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan) AS AmountExcludingVAT,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl) AS SumCompl,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	SUM (
	|		CASE
	|			WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|				THEN TableTypesOfStocks_.AmountIncludingVATMan
	|			ELSE 0
	|		END) AS Cost,
	|	SUM (
	|		CASE 
	|			WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|				THEN TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan
	|			ELSE 0
	|		END) AS CostExcludingVAT,
	|	SUM (
	|		CASE
	|			WHEN TableTypesOfStocks_.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|			ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|		END) AS LocalCost,
	|	
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	NOT &ThisIsTransferToCommission
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork
	|GROUP BY
	|	TableTypesOfStocks_.VATActivityType,
	|	TableTypesOfStocks_.SupplierProductAnalysis,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	TableTypesOfStocks_.SupplierSWarehouse,
	|	TableTypesOfStocks_.RecipientInventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END
	|";
#EndRegion

#Region ReceiptOfWorks
	ReceiptOfWorks =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.PurchaseFromAnotherCompany) AS BusinessOperation,
	|	&CompanyRecipient AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Manager AS Manager,
	|
	|	GoodsTable.RecipientProductAnalysis AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	GoodsTable.Warehouse AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OperationService) AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Organization
	|	END AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	SUM(GoodsTable.Count) AS Count,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl)
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
	|	GoodsTable.Products AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectOfRecipient AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|GROUP BY
	|	GoodsTable.VATActivityType,
	|	GoodsTable.DimensionOfProductItem,
	|	GoodsTable.RecipientProductAnalysis,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Department
	|";
#EndRegion

#Region ConsignmentProcurement
	ConsignmentProcurement =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ConsignmentProcurement) AS BusinessOperation,	
	|	&CompanyRecipient AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	TableTypesOfStocks_.SupplierSWarehouse AS Warehouse,
	|	TableTypesOfStocks_.RecipientInventoryType AS InventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Organization
	|	END AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|	
	|	SUM(TableTypesOfStocks_.Count) AS Count,
	|
	|	0 AS Sum,
	|	0 AS AmountExcludingVAT,
	|	0 AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan) AS Cost,
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan) AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.VATActivityType IN (
	|				VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|				VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN
	|				SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl)
	|		ELSE SUM(TableTypesOfStocks_.AmountExcludingVATCompl)
	|	END AS LocalCost,
	|	
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT) AS AmountInDocumentCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInDocumentCurrency,
	|
	|	&ARAPCurrency AS ARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|	AND &ThisIsTransferToCommission
	|GROUP BY
	|	TableTypesOfStocks_.VATActivityType,
	|	TableTypesOfStocks_.SupplierProductAnalysis,
	|	TableTypesOfStocks_.LineOfBusiness,
	|	TableTypesOfStocks_.SupplierSWarehouse,
	|	TableTypesOfStocks_.RecipientInventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END";
#EndRegion

	QueryText = UninvoicedReceipt
		+ " UNION ALL " + ReceiptOfWorks
		+ " UNION ALL " + ConsignmentProcurement;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                                              AS Period,
	|	&BusinessOperation                               AS BusinessOperation,
	|	&Organization                                         AS Organization,
	|	&Department                                       AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN TableTypesOfStocks_.SupplierProductAnalysis
	|		ELSE TableTypesOfStocks_.AnalysisOfProductsSupplierWithoutAssignment
	|	END                                                AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness           AS LineOfBusiness,
	|	TableTypesOfStocks_.SupplierSWarehouse                   AS Warehouse,
	|	TableTypesOfStocks_.InventoryType                        AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                        AS InventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.AnalysisOfCommissionAgentProducts AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness           AS CorLineOfBusiness,
	|	UNDEFINED                                         AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	TableTypesOfStocks_.InventoryType                        AS CorInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                        AS CorInventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.Count                        AS Count,
	|	TableTypesOfStocks_.Count                        AS CorQuantity,
	|
	|	0                                                    AS Cost,
	|	0                                                    AS CostExcludingVAT,
	|	0                                                    AS LocalCost,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|			ELSE TableTypesOfStocks_.Products
	|	END                                                AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|			ELSE TableTypesOfStocks_.Products
	|	END                                                AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&ThisIsTransferToCommission
	|	AND NOT TableTypesOfStocks_.ThisIsTraceableWork";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Period                                  AS Period,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfServices) AS BusinessOperation,
	|	&CompanyRecipient                   AS Organization,
	|	GoodsTable.Department              AS Department,
	|
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|				THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END                                    AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Organization
	|	END                                    AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END                                    AS Contract,
	|	UNDEFINED                             AS ARAPObject,
	|
	|	GoodsTable.ExpenseItem             AS IncomeAndExpenseItem,
	|	GoodsTable.LineOfBusiness    AS LineOfBusinessItems,
	|	UNDEFINED                             AS DimensionOfRevenue,
	|	GoodsTable.DimensionOfExpenses          AS DimensionOfExpenses,
	|	
	|	SUM(GoodsTable.AmountIncludingVATMan)        AS Sum,
	|	SUM(GoodsTable.AmountExcludingVATMan)      AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS SumCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl)     AS LocalAmountExcludingVAT,
	|
	|	&Currency                                  AS Currency,
	|	SUM(GoodsTable.AmountIncludingVAT)           AS AmountInCurrency,
	|	SUM(GoodsTable.AmountIncludingVAT - GoodsTable.VATAmount) AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency                    AS ARAPCurrency,
	|	SUM(GoodsTable.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(GoodsTable.AmountARAP - GoodsTable.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	&ARAPObjectOfRecipient AS SourceOfARAPFinancialAccountingGroup,
	|	GoodsTable.IDOfRecipientSFinRecord AS FinRecordID
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND NOT GoodsTable.ThisIsTraceableWork
	|
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.Department,
	|	GoodsTable.IDOfRecipientSFinRecord
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                  AS Period,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfServices) AS BusinessOperation,
	|	&CompanyRecipient                   AS Organization,
	|	TableTypesOfStocks_.Department         AS Department,
	|
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|				THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END                                    AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Organization
	|	END                                    AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END                                    AS Contract,
	|	UNDEFINED                             AS ARAPObject,
	|
	|	TableTypesOfStocks_.ExpenseItem        AS IncomeAndExpenseItem,
	|	&LineOfBusiness			     AS LineOfBusinessItems,
	|	UNDEFINED                             AS DimensionOfRevenue,
	|	TableTypesOfStocks_.DimensionOfExpenses     AS DimensionOfExpenses,
	|	
	|	SUM(TableTypesOfStocks_.AmountIncludingVATMan)   AS Sum,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl) AS SumCompl,
	|	SUM(TableTypesOfStocks_.AmountExcludingVATCompl) AS LocalAmountExcludingVAT,
	|
	|	&Currency                                  AS Currency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT)      AS AmountInCurrency,
	|	SUM(TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInCurrency,
	|		
	|	&ARAPCurrency                    AS ARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP) AS AmountInARAPCurrency,
	|	SUM(TableTypesOfStocks_.AmountARAP - TableTypesOfStocks_.AmountVATARAP) AS AmountExcludingVATInARAPCurrency,
	|
	|	&ARAPObjectOfRecipient AS SourceOfARAPFinancialAccountingGroup,
	|	TableTypesOfStocks_.IDOfRecipientSFinRecord AS FinRecordID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|
	|GROUP BY
	|	TableTypesOfStocks_.ExpenseItem,
	|	TableTypesOfStocks_.DimensionOfExpenses,
	|	TableTypesOfStocks_.Department,
	|	TableTypesOfStocks_.IDOfRecipientSFinRecord";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                         AS Period,
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	GoodsTable.AnalysisOfCommissionAgentProducts AS ItemsLocationAttributes,
	|	UNDEFINED                                    AS Terms,
	|	&Organization                                    AS Organization,
	|	GoodsTable.InventoryOwnerAttribute                        AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber                          AS CCDNumber,
	|	SUM(GoodsTable.Count)                 AS Count,
	|	SUM(GoodsTable.QuantityByGBRN)           AS QuantityByGBRN,
	|	&BusinessOperation                          AS BusinessOperation,
	|	GoodsTable.VATTaxation                AS VATTaxation,
	|	GoodsTable.Products                      AS Products,
	|	GoodsTable.Characteristic                    AS Characteristic,
	|	GoodsTable.SupplierProductAnalysis    AS CorItemsLocationAttributes
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	&BusinessOperation 
	|			= VALUE(Enum.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany)
	|	AND GoodsTable.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OwnGoods),
	|		VALUE(Enum.ItemsTypes.ReusablePackage))
	|
	|GROUP BY
	|	GoodsTable.SupplierProductAnalysis,
	|	GoodsTable.AnalysisOfCommissionAgentProducts,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.VATTaxation,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Organization                                AS Organization,
	|	&CompanyRecipient                      AS Customer,
	|	ToRegister.PrincipalProductAnalysis AS ItemsLocationAttributes,
	|	ToRegister.Terms                      AS Terms,
	|	ToRegister.Currency                          AS Currency,
	|	ToRegister.Count                      AS Count,
	|	ToRegister.AmountIncludingVAT
	|		* ExchangeRates.ConversionFactor_       AS RevenueAmount,
	|	ToRegister.VATAmount 
	|		* ExchangeRates.ConversionFactor_       AS VATAmount,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATCompl
	|		ELSE 0
	|	END                                       AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(ToRegister.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ToRegister.AmountIncludingVATMan
	|		ELSE 0
	|	END                                       AS RevenueAmountMan,
	|	&Ref                                     AS DocumentSalesOfGoodsAndServices,
	|
	|	&IDARAPObject               AS FinRecordID,
	|	&BusinessTransactionSetting             AS BusinessTransactionSetting,
	|	ToRegister.RowID             AS RowID
	|FROM
	|	TTOperationServices AS ToRegister
	|
	|	LEFT JOIN TTExchangeRates AS ExchangeRates
	|	ON ToRegister.Currency = ExchangeRates.Currency
	|WHERE
	|	ToRegister.PrincipalProductAnalysis <> UNDEFINED";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	Query.SetParameter("GenerateVATChargedWhenIncludingInCost",
		AccountingPoliciesTaxSettingsCached.GenerateVATChargedWhenIncludingInCost(Query.Parameters.CompanyRecipient, Query.Parameters.Period));
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_                   AS VariancePeriod,
	|	&CompanyRecipient                 AS Organization,
	|	GoodsTable.Department            AS Department,
	|	GoodsTable.LineOfBusiness  AS LineOfBusiness,
	|	GoodsTable.ExpenseItem           AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses        AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType       AS VATActivityType,
	|
	// For goods and works, the amounts for the company are calculated at the end of the month.
	|	SUM(CASE
	|		WHEN GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN GoodsTable.AmountIncludingVATMan
	|		ELSE 0 END)                     AS AmountIncludingVAT,
	|	SUM(CASE
	|		WHEN GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN GoodsTable.AmountExcludingVATMan
	|		ELSE 0 END)                     AS AmountExcludingVAT,
	// For goods and works, the SUMASNDS and SUMABESNDS fields are equal to 0. In this case
	// , it is not possible to include/exclude VAT in the function textquestionatablycautprocedure(). Therefore, for goods and services, the inclusion/exclusion of VAT for the amount (Man) is performed
	// in this function.
	|	SUM(CASE
	|		WHEN GoodsTable.ItemsType <> VALUE(Enum.ItemsTypes.OperationService)
	|		 AND GoodsTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND GoodsTable.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|		 AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN GoodsTable.AmountIncludingVATMan
	|		ELSE GoodsTable.AmountExcludingVATMan END) AS AmountExcludingVATMan,
	|	
	|	SUM(GoodsTable.AmountExcludingVATCompl
	|		+ GoodsTable.VATAmountCompl)      AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl)   AS AmountExcludingVATCompl,
	|	0	                                   AS PermanentDifference,
	|	0                                      AS CostTD,
	|	&BusinessOperation                 AS BusinessOperation,
	|	GoodsTable.DimensionOfProductItem    AS ItemsLocationAttributes,
	|
	|	GoodsTable.RowID      AS RowID,
	|	GoodsTable.IDOfRecipientSFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND NOT GoodsTable.ThisIsTraceableWork
	|
	|GROUP BY
	|	GoodsTable.VATActivityType,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.DimensionOfProductItem,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.RowID,
	|	GoodsTable.IDOfRecipientSFinRecord
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_                   AS VariancePeriod,
	|	&CompanyRecipient                 AS Organization,
	|	GoodsTable.Department            AS Department,
	|	GoodsTable.LineOfBusiness  AS LineOfBusiness,
	|	GoodsTable.ExpenseItem           AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses        AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType       AS VATActivityType,
	|
	|	0								       AS AmountIncludingVAT,
	|	0									   AS AmountExcludingVAT,
	|	SUM(CASE
	|		WHEN GoodsTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND GoodsTable.ExpenseItem.SeparateVATAccountingOption = VALUE(Enum.SeparateVATAccountingOptions.FromDocument)
	|		 AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN GoodsTable.AmountIncludingVATMan
	|		ELSE GoodsTable.AmountExcludingVATMan END) AS AmountExcludingVATMan,
	|	
	|	SUM(GoodsTable.AmountExcludingVATCompl
	|		+ GoodsTable.VATAmountCompl)      AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl)   AS AmountExcludingVATCompl,
	|	0	                                   AS PermanentDifference,
	|	0                                      AS CostTD,
	|	VALUE(Enum.BusinessTransactions.ReceiptOfServices) AS BusinessOperation,
	|	GoodsTable.DimensionOfProductItemClient AS ItemsLocationAttributes,
	|
	|	GoodsTable.RowID      AS RowID,
	|	GoodsTable.IDOfRecipientSFinRecord AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier) AS BusinessTransactionSetting
	|
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|
	|GROUP BY
	|	GoodsTable.VATActivityType,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.DimensionOfProductItemClient,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.RowID,
	|	GoodsTable.IDOfRecipientSFinRecord
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOperationServices", QueryTexts) Then
		QueryTextTTOperationServices(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&CompanyRecipient                 AS Organization,
	|	GoodsTable.Department            AS Department,
	|	GoodsTable.LineOfBusiness  AS LineOfBusiness,
	|	GoodsTable.ExpenseItem           AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses        AS DimensionOfExpenses,
	|	UNDEFINED                           AS AssetsLiabilitiesDimension,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan)      AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan)    AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl)   AS LocalCost,
	|	SUM(GoodsTable.VATAmountCompl)      AS VATLocal,
	|	SUM(GoodsTable.VATAmountMan)       AS VATManag,
	|	0	                                   AS PermanentDifference,
	|	0                                      AS CostTD,
	|	&Ref                                AS ExpenseReceiptDocument,
	|	GoodsTable.LotVendorAttributes     AS LotVendorAttributes,
	|	UNDEFINED                           AS ItemsLocationAttributes,
	|	GoodsTable.VATActivityType       AS VATActivityType,
	|	&BusinessOperation                 AS BusinessOperation,
	|
	|	GoodsTable.RowID      AS RowID,
	|	GoodsTable.IDOfRecipientSFinRecord AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTOperationServices AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|
	|GROUP BY
	|	GoodsTable.VATActivityType,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.RowID,
	|	GoodsTable.IDOfRecipientSFinRecord
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&CompanyRecipient                 AS Organization,
	|	GoodsTable.Department            AS Department,
	|	GoodsTable.LineOfBusiness  AS LineOfBusiness,
	|	GoodsTable.ExpenseItem           AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses        AS DimensionOfExpenses,
	|	UNDEFINED                           AS AssetsLiabilitiesDimension,
	|
	|	0                                      AS Cost,
	|	0                                      AS CostExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATCompl)   AS LocalCost,
	|	SUM(GoodsTable.VATAmountCompl)      AS VATLocal,
	|	SUM(GoodsTable.VATAmountMan)       AS VATManag,
	|	0	                                   AS PermanentDifference,
	|	0                                      AS CostTD,
	|	&Ref                                AS ExpenseReceiptDocument,
	|	GoodsTable.LotVendorAttributes     AS LotVendorAttributes,
	|	UNDEFINED                           AS ItemsLocationAttributes,
	|	GoodsTable.VATActivityType       AS VATActivityType,
	|	&BusinessOperation                 AS BusinessOperation,
	|
	|	GoodsTable.RowID      AS RowID,
	|	GoodsTable.IDOfRecipientSFinRecord AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	GoodsTable.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|
	|GROUP BY
	|	GoodsTable.VATActivityType,
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.RowID,
	|	GoodsTable.IDOfRecipientSFinRecord
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      		= "Document.CustomerInvoiceIntercompany";
	SynonymForDocumentTable 		= "";
	RequestHasSource    		= True;
	TemporaryTableQueryTexts 	= New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("DocumentNumber",                    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber",           """""");
	RedefiningParameterCalculation.Insert("OrganizationInformation",           """""");
	RedefiningParameterCalculation.Insert("InformationAboutRecipientOrganization", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Undefined, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation,
		TemporaryTableQueryTexts);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingAnalyticsByPartnersSupplier");
	AdditionalParameters.Add("AccountingDimensionByPartnersClient");
	
	If Query <> Undefined Then
		SetParameterForPartnerAccountingAnalystRequestProvider(Query);
		SetParameterForPartnerAccountingAnalyticsRequestClient(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTOperationServices");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTOperationServices(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[2], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.SupplierProductAnalysis 	AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END                                           	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	DocumentTable.CompanyRecipient          	AS CorCompany,
	|	TableTypesOfStocks_.SupplierProductAnalysis 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	DocumentTable.Ref								AS CorLot,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartnersClient					AS AccountingDimensionByPartners,
	|	UNDEFINED 										AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

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
	|	DocumentTable.CompanyRecipient				AS Organization,
	|	TableTypesOfStocks_.SupplierProductAnalysis	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
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
	|	DocumentTable.Organization	AS CorCompany,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan                 AS Cost,
	|	TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan AS CostExcludingVAT,
	|	TableTypesOfStocks_.AmountExcludingVATCompl              AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.VATAmountCompl
	|	END 											AS VATLocal,
	|	TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType <> VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		THEN TableTypesOfStocks_.VATAmountMan
	|		ELSE 0
	|	END 										    AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 											AS BusinessOperation,
	|	TableTypesOfStocks_.IDOfRecipientSFinRecord			 					AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromAnotherCompany)	AS BusinessTransactionSetting
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region WriteOffForExpensesAssets_Product
	
	// You do not need to fill out inventory analytics to write off expenses, because in the recipient organization, the receipt will be in other expenses
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					  AS Organization,
	|	TableTypesOfStocks_.SupplierProductAnalysis AS ItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END		 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, DocumentTable.CompanyRecipient) AS CorCompany,
	// The coralalitika field of the accountanomenclature is used in the request for accounting transactions.
	|	TableTypesOfStocks_.DimensionOfProductItemClient  AS CorItemsLocationAttributes, 
	|	UNDEFINED                                    AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem               AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses            AS AssetExpenseAnalytics,
	|	TableTypesOfStocks_.LineOfBusiness      AS CorLineOfBusiness,
	|	UNDEFINED                                    AS CorLot,
	|	UNDEFINED                                    AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartnersClient                AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	TableTypesOfStocks_.Department	AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	DocumentTable.BusinessOperation		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	 	AS RowID,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = TableTypesOfStocks_.ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = TableTypesOfStocks_.DimensionOfExpenses
	|		AND OtherExpenses.RowID = TableTypesOfStocks_.RowID
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion

	#Region Moving_Goods_Commission
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.SupplierProductAnalysis  	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        	AS CorCompany,
	|	UNDEFINED 									   		AS CorLot,
	|	TableTypesOfStocks_.AnalysisOfCommissionAgentProducts	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute							AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	DocumentTable.Manager				AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND &ThisIsTransferToCommission
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion

	#Region ExternalReceipt_Product_Commission
	
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
	|	DocumentTable.CompanyRecipient				AS Organization,
	|	TableTypesOfStocks_.DimensionOfProductItemClient		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute				AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
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
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID			AS RowID,
	|	0												AS Cost,
	|	0 												AS CostExcludingVAT,
	|	0												AS LocalCost,
	|	0 												AS VATLocal,
	|	0												AS CostMan,
	|	0 												AS VATManag,
	|	TableTypesOfStocks_.AmountExcludingVATMan
	|		+ TableTypesOfStocks_.VATAmountMan			AS OffBalanceCost,
	|	TableTypesOfStocks_.AmountExcludingVATCompl
	|		+ TableTypesOfStocks_.VATAmountCompl			AS OffBalanceCostLocal,
	|	0												AS AddExpensesForGoods,
	|	0												AS AdditionalExpensesExcludingVAT,
	|	0												AS AddExpensesLocal,
	|	0												AS AddExpensesMan,
	|	0												AS PermanentDifference,
	|	0												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsignmentProcurement)		AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID			 				AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignmentProcurement)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND &ThisIsTransferToCommission";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ImplementationOfThisWork
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 						AS Organization,
	|	TableTypesOfStocks_.DimensionOfProductItem 			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	DocumentTable.CompanyRecipient          	AS CorCompany,
	|	TableTypesOfStocks_.RecipientProductAnalysis 	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute				AS CorInventoryOwnerAttribute,
	|	DocumentTable.Ref								AS CorLot,
	|	TableTypesOfStocks_.LotVendorAttributes				AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartnersClient					AS AccountingDimensionByPartners,
	|	UNDEFINED 										AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  	AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND TableTypesOfStocks_.Principal = UNDEFINED";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	#Region ExternalEntry_Work
	
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
	|	DocumentTable.CompanyRecipient				AS Organization,
	|	TableTypesOfStocks_.RecipientProductAnalysis	AS ItemsLocationAttributes,
	|	CASE
	|   	WHEN TableTypesOfStocks_.ThisIsTraceableWork
	|   		THEN TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|   	ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|   END												AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
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
	|	DocumentTable.Organization	AS CorCompany,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	TableTypesOfStocks_.AmountIncludingVATMan               	AS Cost,
	|	TableTypesOfStocks_.AmountExcludingVATMan				AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|		THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|		ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	TableTypesOfStocks_.VATAmountCompl					AS VATLocal,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan - TableTypesOfStocks_.VATAmountMan
	|	END                                           AS CostMan,
	|	TableTypesOfStocks_.VATAmountMan				    AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 									AS BusinessOperation,
	|	TableTypesOfStocks_.IDOfRecipientSFinRecord			 			AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromSupplier)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND TableTypesOfStocks_.Principal = UNDEFINED";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region ExternalReceipt_Work_IncludeVATInCostExpenses
	
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
	|	DocumentTable.CompanyRecipient				AS Organization,
	|	TableTypesOfStocks_.RecipientProductAnalysis	AS ItemsLocationAttributes,
	|	CASE
	|   	WHEN TableTypesOfStocks_.ThisIsTraceableWork
	|   		THEN TableTypesOfStocks_.RecipientInventoryOwnerAttribute
	|   	ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|   END												AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
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
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0												AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	0                                           	AS Cost,
	|	0                                           	AS CostExcludingVAT,
	|	TableTypesOfStocks_.VATAmountCompl 				AS LocalCost,
	|	0												AS VATLocal,
	|	TableTypesOfStocks_.VATAmountMan 					AS CostMan,
	|	0												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	0 												AS PermanentDifference,
	|	0 												AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation 										AS BusinessOperation,
	|	TableTypesOfStocks_.RowID						 				AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND TableTypesOfStocks_.Principal = UNDEFINED
	|	AND &GenerateVATChargedWhenIncludingInCost
	|	AND TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	#Region WriteOffForExpensesAssets_Work
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.DimensionOfProductItem 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, DocumentTable.CompanyRecipient) AS CorCompany,
	// The coralalitika field of the accountanomenclature is used in the request for accounting transactions.
	|	TableTypesOfStocks_.RecipientProductAnalysis 			AS CorItemsLocationAttributes,
	|	UNDEFINED				  				    			AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.ExpenseItem 			    			AS ExpenseItemAssets,
	|	TableTypesOfStocks_.DimensionOfExpenses    					AS AssetExpenseAnalytics,
	|	TableTypesOfStocks_.LineOfBusiness					AS CorLineOfBusiness,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN DocumentTable.Ref
	|		ELSE UNDEFINED
	|	END 											  	 		AS CorLot,
	|	CASE WHEN &BatchAccountingVersion22 AND &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											  	 		AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartnersClient 							AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	TableTypesOfStocks_.Department	AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	DocumentTable.BusinessOperation		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	 	AS RowID,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	&BusinessTransactionSetting				AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = TableTypesOfStocks_.ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = TableTypesOfStocks_.DimensionOfExpenses
	|		AND OtherExpenses.RowID = TableTypesOfStocks_.RowID
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND TableTypesOfStocks_.ToExpenseAs
	|	AND NOT &ThisIsTransferToCommission
	|	AND TableTypesOfStocks_.Principal = UNDEFINED";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CustomerInvoiceIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
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

#Region Print

// Returns the data required for the printed form "Act of rendering services".
// 
// Parameters:
// 	PrintParameters - Structure - advanced print settings
// 	ObjectsArray  - Array    - references to objects that should be printed
// 	
// Returns:
// 	Structure - Contains data on the header of the document, the tabular part:
// 	* HeaderResults          - QueryResult - 
// 	* ResultForTabularPart - QueryResult - 
//
Function GetDataForPrintedServiceDeliveryReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query("
	|////////////////////////////////////////////////////////////////////////////
	|// REQUEST BY HEADER
	|
	|SELECT // documents without an intermediary
	|	SaleOfGoodsAndServices.Ref AS Ref,
	|	SaleOfGoodsAndServices.Number AS Number,
	|	SaleOfGoodsAndServices.Date AS Date,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	SaleOfGoodsAndServices.CompanyRecipient AS Counterparty,
	|	SaleOfGoodsAndServices.Organization AS Organization,
	|	SaleOfGoodsAndServices.Organization.Prefix AS Prefix,
	|	SaleOfGoodsAndServices.Currency AS Currency,
	|	SaleOfGoodsAndServices.PriceIncludesVAT AS PriceIncludesVAT,
	|	(CASE WHEN SaleOfGoodsAndServices.VATTaxation IN (&TaxationWithoutVAT) THEN FALSE ELSE TRUE END) AS ConsiderVAT,
	|	SaleOfGoodsAndServices.Warehouse.CurrentEmployeeInChargeTypes.Description AS VacationProduced
	|FROM
	|	Document.CustomerInvoiceIntercompany AS SaleOfGoodsAndServices
	|WHERE
	|	SaleOfGoodsAndServices.Ref IN (&DocumentsArray) AND SaleOfGoodsAndServices.Posted AND NOT SaleOfGoodsAndServices.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|SELECT // documents from the sender to the intermediary
	|	SaleOfGoodsAndServices.Ref AS Ref,
	|	SaleOfGoodsAndServices.Number AS Number,
	|	SaleOfGoodsAndServices.Date AS Date,
	|	SaleOfGoodsAndServices.Partner AS Partner,
	|	SaleOfGoodsAndServices.Counterparty AS Counterparty,
	|	SaleOfGoodsAndServices.Organization AS Organization,
	|	SaleOfGoodsAndServices.Organization.Prefix AS Prefix,
	|	SaleOfGoodsAndServices.Currency AS Currency,
	|	SaleOfGoodsAndServices.PriceIncludesVAT AS PriceIncludesVAT,
	|	(CASE WHEN SaleOfGoodsAndServices.VATTaxation IN (&TaxationWithoutVAT) THEN FALSE ELSE TRUE END) AS ConsiderVAT,
	|	SaleOfGoodsAndServices.Warehouse.CurrentEmployeeInChargeTypes.Description AS VacationProduced
	|FROM
	|	Document.CustomerInvoiceIntercompany AS SaleOfGoodsAndServices
	|WHERE
	|	SaleOfGoodsAndServices.Ref IN (&DocumentsArray) AND SaleOfGoodsAndServices.Posted AND SaleOfGoodsAndServices.ARAPAccountingViaSeparateCounterparty
	|	AND SaleOfGoodsAndServices.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|UNION ALL
	|SELECT // documents from the intermediary to the recipient
	|	SaleOfGoodsAndServices.Ref AS Ref,
	|	SaleOfGoodsAndServices.IncomingDocumentNumber AS Number,
	|	SaleOfGoodsAndServices.IncomingDocumentDate AS Date,
	|	SaleOfGoodsAndServices.Partner AS Partner,
	|	SaleOfGoodsAndServices.CompanyRecipient AS Counterparty,
	|	SaleOfGoodsAndServices.Counterparty AS Organization,
	|	SaleOfGoodsAndServices.Organization.Prefix AS Prefix,
	|	SaleOfGoodsAndServices.Currency AS Currency,
	|	SaleOfGoodsAndServices.PriceIncludesVAT AS PriceIncludesVAT,
	|	(CASE WHEN SaleOfGoodsAndServices.VATTaxation IN (&TaxationWithoutVAT) THEN FALSE ELSE TRUE END) AS ConsiderVAT,
	|	"""" AS VacationProduced
	|FROM
	|	Document.CustomerInvoiceIntercompany AS SaleOfGoodsAndServices
	|WHERE
	|	SaleOfGoodsAndServices.Ref IN (&DocumentsArray) AND SaleOfGoodsAndServices.Posted AND SaleOfGoodsAndServices.ARAPAccountingViaSeparateCounterparty
	|	AND SaleOfGoodsAndServices.CompanyRecipient <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Ref;
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
	|	NestedQuery.Characteristic                                             AS Characteristic,
	|	NestedQuery.Characteristic.DescriptionFull                          AS CharacteristicFullName,
	|	NestedQuery.Package.Description                                      AS PackagingName_,
	|	NestedQuery.VATRate                                                  AS VATRate,
	|	NestedQuery.Price													   AS Price,
	|	NestedQuery.Count                                                 AS Count,
	|	NestedQuery.Sum													   AS Sum,
	|	NestedQuery.VATAmount												   AS VATAmount,
	|	NestedQuery.DiscountAmount                                                AS DiscountAmount,
	|	NestedQuery.AmountWithoutADiscount                                             AS AmountWithoutADiscount,
	|	NestedQuery.LineNumber                                                AS LineNumber,
	|	FALSE                                                                       AS ThisIsReusablePackage
	|FROM (
	|	SELECT
	|		SaleOfGoodsAndServices.Ref AS Ref,
	|		SaleOfGoodsAndServices.Products AS Products,
	|
	|		CASE WHEN SaleOfGoodsAndServices.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) THEN
	|			1
	|		ELSE
	|			&QueryTextPackagingFactor
	|		END AS ZoomRatio,
	|
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|
	|		0 AS DiscountPercentage,
	|		SaleOfGoodsAndServices.Characteristic              AS Characteristic,
	|		SaleOfGoodsAndServices.Package                    AS Package,
	|		SaleOfGoodsAndServices.VATRate                   AS VATRate,
	|		SaleOfGoodsAndServices.Price                        AS Price,
	|		SaleOfGoodsAndServices.NumberOfPackages          AS Count,
	|		SaleOfGoodsAndServices.Sum                       AS Sum,
	|		0                                      AS DiscountAmount,
	|		SaleOfGoodsAndServices.Sum                       AS AmountWithoutADiscount,
	|		SaleOfGoodsAndServices.VATAmount                    AS VATAmount,
	|		SaleOfGoodsAndServices.LineNumber                 AS LineNumber
	|	FROM
	|		Document.CustomerInvoiceIntercompany.Goods AS SaleOfGoodsAndServices
	|	WHERE
	|		SaleOfGoodsAndServices.Ref IN (&DocumentsArray)
	|		AND SaleOfGoodsAndServices.Products.ItemsType IN (
	|			VALUE(Enum.ItemsTypes.OperationService),
	|			VALUE(Enum.ItemsTypes.Work_5)
	|		)
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
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"SaleOfGoodsAndServices.Package",
			"SaleOfGoodsAndServices.Products"));
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"SaleOfGoodsAndServices.Package",
			"SaleOfGoodsAndServices.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
	TaxationWithoutVAT = New Array();
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsNotSubjectToVAT);
	TaxationWithoutVAT.Add(Enums.VATTaxationTypes.SaleIsSubjectToUTII);
	Query.SetParameter("TaxationWithoutVAT", TaxationWithoutVAT);
	
	ResultsArray 			= Query.ExecuteBatch();
	HeaderResults			= ResultsArray[0];
	ResultForTabularPart 	= ResultsArray[1];
	
	DataStructureForPrinting 	= New Structure("HeaderResults, ResultForTabularPart",
												   HeaderResults, ResultForTabularPart);
	
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
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	If Not UserRightsCached.ThisIsPartner() Then
		// The act on the provision of services
		PrintCommand = PrintCommands.Add();
		PrintCommand.PrintManager = "DataProcessor.PrintCertificateOfRenderedServices";
		PrintCommand.Id = "Act";
		PrintCommand.Presentation = NStr("vi = 'Biên bản cung cấp dịch vụ';
										|ru = 'Акт об оказании услуг';
										|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
										|it = 'Atto di prestazione dei servizi';
										|pl = 'Protokół świadczenia usług';
										|tr = 'Hizmet tutanağı'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.DefaultPrintForm = True;
		PrintCommand.PrintFormDescription = NStr("vi = 'Biên bản cung cấp dịch vụ';
												|ru = 'Акт об оказании услуг';
												|en = 'Certificate of rendered services'; fa = 'Certificate of rendered services';
												|it = 'Atto di prestazione dei servizi';
												|pl = 'Protokół świadczenia usług';
												|tr = 'Hizmet tutanağı'");
	EndIf;
	
	If Not UserRightsCached.ThisIsPartner() And Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
										|ru = 'Commercial invoice';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Commercial invoice';
										|pl = 'Commercial invoice';
										|tr = 'Commercial invoice'");
		PrintCommand.CheckPostingBeforePrint = True;
	EndIf;
	
	CustomerInvoiceIntercompanyLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	CustomerInvoiceIntercompanyLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
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
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.CompanyRecipient AS Counterparty,
	|	Documents.CompanyRecipient.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.RecipientCompanyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Organization
	|		ELSE Documents.Shipper
	|	END AS Shipper,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoiceIntercompany AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND NOT Documents.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CounterpartyBankAccount.Owner, Documents.CompanyRecipient) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	"""" AS Director,
	|	"""" AS JobTitleExecutive,
	|	"""" AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.CompanyRecipient AS Counterparty,
	|	Documents.CompanyRecipient.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CounterpartyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CounterpartyBankAccount.ForeignBank
	|		OR Documents.CounterpartyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.RecipientCompanyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CounterpartyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CounterpartyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CounterpartyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CounterpartyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CounterpartyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CounterpartyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN ISNULL(Documents.CounterpartyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(Documents.CounterpartyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN ISNULL(Documents.CounterpartyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CounterpartyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Counterparty
	|		ELSE Documents.Shipper
	|	END,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoiceIntercompany AS Documents
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND Documents.ARAPAccountingViaSeparateCounterparty
	|	AND Documents.CompanyRecipient <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCode
	|		ELSE BankClassifier.SWIFTBIC
	|	END AS BankSWIFTCode,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddress
	|		ELSE BankClassifier.Address
	|	END AS BankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressInt
	|		ELSE BankClassifier.InternationalAddress
	|	END AS BankAddressInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBank
	|		ELSE BankCountries.Ref
	|	END AS CountryOfBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankNameForPaymentsInt
	|		ELSE CorrespondentBankClassifier.InternationalDescription
	|	END AS BankNameForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankSWIFTCodeForPayments
	|		ELSE CorrespondentBankClassifier.SWIFTBIC
	|	END AS BankSWIFTCodeForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE CorrespondentBankClassifier.CityInternationalFormat
	|	END AS BankCityForPaymentsInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.BankAddressForPaymentInt
	|		ELSE CorrespondentBankClassifier.InternationalAddress
	|	END AS BankAddressForPaymentInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankAddress
	|		ELSE CorrespondentBankClassifier.Address
	|	END AS TransferBankAddress,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.CountryOfBankForPayments
	|		ELSE CountriesOfCorrespondentBanksOfRussianFederation.Ref
	|	END AS CountryOfBankForPayments,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Organization
	|		ELSE Documents.Shipper
	|	END AS Shipper,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.CustomerInvoiceIntercompany AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS BankCountries
	|		ON BankClassifier.CountryCode = BankCountries.Code
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Catalog.WorldCountries AS CountriesOfCorrespondentBanksOfRussianFederation
	|		ON CorrespondentBankClassifier.CountryCode = CountriesOfCorrespondentBanksOfRussianFederation.Code
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND Documents.ARAPAccountingViaSeparateCounterparty
	|	AND Documents.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0 AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	0 AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
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
	|	ISNULL(ItemsCharacteristicsPresentations.DescriptionFull, ISNULL(Goods.Characteristic.DescriptionFull, """")) AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END AS Package,
	|	0 AS DiscountAmount,
	|	Goods.Sum AS AmountWithoutADiscount,
	|	FALSE AS ThisIsReusablePackage
	|FROM
	|	Document.CustomerInvoiceIntercompany.Goods AS Goods
	|	LEFT JOIN Catalog.Products.Presentations AS ProductsPresentations
	|	ON (Goods.Products = ProductsPresentations.Ref
	|			AND ProductsPresentations.LanguageCode = &LanguageCode)
	|	LEFT JOIN Catalog.ItemsCharacteristics.Presentations AS ItemsCharacteristicsPresentations
	|	ON (Goods.Characteristic = ItemsCharacteristicsPresentations.Ref
	|			AND ItemsCharacteristicsPresentations.LanguageCode = &LanguageCode)
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|ORDER BY
	|	Goods.LineNumber
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
		
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
		
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Query.SetParameter("LanguageCode", LanguageCode);
	
	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#Region State

// Calculates the current state of the transfer of goods on the recipient's side.
//
// Parameters:
//	GoodsHandover         - DocumentRef.CustomerInvoiceIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateRecipientState(Val GoodsHandover, Val Contract, StateOfCalculations) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusRecipient());
	
	If ValueIsFilled(GoodsHandover) And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS PaymentAmountRecipient,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.BusinessOperation <> VALUE(Enum.BusinessTransactions.ConsignmentProcurement)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) * 100 / VendorsARAPAccountingBalance.AmountDueExpense AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PaymentPercentageRecipient,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |				AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) < 0
		                      |			THEN CAST(-ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfOverduePaymentRecipient,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0)
		                      |		ELSE 0
		                      |	END AS OrderReceiptAmount,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PercentageOfOrderReceipt,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.Posted
		                      |				AND (ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |					OR DocumentGoodsHandover.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfDebtRecipient,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CASE
		                      |					WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0
		                      |						THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |					ELSE CAST(ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |				END
		                      |		ELSE 0
		                      |	END AS PercentageOfDebtRecipient,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |			THEN -VendorsARAPAccountingBalance.AmountDueClosingBalance
		                      |		ELSE 0
		                      |	END AS AmountPayableRecipient
		                      |FROM
		                      |	Document.CustomerInvoiceIntercompany AS DocumentGoodsHandover
		                      |		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject = &ARAPObject) AS VendorsARAPAccountingBalance
		                      |		ON (TRUE)
		                      |		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(ENDOFPERIOD(&CurrentDate, DAY), ARAPObject = &ARAPObject) AS SettlementsWithSuppliersBalancesAsOfDate
		                      |		ON (TRUE)
		                      |WHERE
		                      |	DocumentGoodsHandover.Ref = &GoodsHandover");
		
		ARAPObject = Common.ObjectAttributeValue(GoodsHandover, "ARAPObjectOfRecipient");
		
		Query.SetParameter("GoodsHandover", GoodsHandover);
		Query.SetParameter("ARAPObject", ARAPObject);
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Calculates the current state of the transfer of goods on the sender's side.
//
// Parameters:
//	GoodsHandover  - DocumentRef.CustomerInvoiceIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//
Procedure CalculateSenderState(Val GoodsHandover, Val Contract, StateOfCalculations) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusSender());
	
	If ValueIsFilled(GoodsHandover) And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0)
		                      |		ELSE 0
		                      |	END AS PaymentAmountSender,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN CAST(ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0) * 100 / DocumentGoodsHandover.AmountARAP AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PaymentPercentageSender,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN CAST(ISNULL(SettlementsWithCustomersBalancesAsOfDateOfRelevance.AmountDueBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfOverduePaymentSender,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0)
		                      |		ELSE 0
		                      |	END AS AmountByShipment,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0) * 100 / DocumentGoodsHandover.AmountARAP AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS OrderShipmentPercentage,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.Posted
		                      |				AND (DocumentGoodsHandover.AmountARAP > 0
		                      |					OR DocumentGoodsHandover.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		                      |			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOwedSender,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.AmountARAP > 0
		                      |			THEN CASE
		                      |					WHEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) > 0
		                      |						THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentGoodsHandover.AmountARAP AS NUMBER(15, 0))
		                      |					ELSE CAST(ISNULL(-CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / DocumentGoodsHandover.AmountARAP AS NUMBER(15, 0))
		                      |				END
		                      |		ELSE 0
		                      |	END AS PercentageOfDebtSender,
		                      |	CASE
		                      |		WHEN DocumentGoodsHandover.Posted
		                      |				AND DocumentGoodsHandover.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |			THEN CustomersARAPAccountingBalance.AmountDueClosingBalance
		                      |		ELSE 0
		                      |	END AS AmountPayableSender
		                      |FROM
		                      |	Document.CustomerInvoiceIntercompany AS DocumentGoodsHandover
		                      |		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(, , , , ARAPObject = &ARAPObject) AS CustomersARAPAccountingBalance
		                      |		ON (TRUE)
		                      |		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(ENDOFPERIOD(&CurrentDate, DAY), ARAPObject = &ARAPObject) AS SettlementsWithCustomersBalancesAsOfDateOfRelevance
		                      |		ON (TRUE)
		                      |WHERE
		                      |	DocumentGoodsHandover.Ref = &GoodsHandover");
		
		ARAPObject = Common.ObjectAttributeValue(GoodsHandover, "ARAPObject");
		
		Query.SetParameter("GoodsHandover", GoodsHandover);
		Query.SetParameter("ARAPObject", ARAPObject); 
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusRecipient()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountRecipient", 0);
	StructureOfStateOfCalculations.Insert("OrderReceiptAmount", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableRecipient", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusSender()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountSender", 0);
	StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageSender", 0);
	StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentSender", 0);
	StructureOfStateOfCalculations.Insert("AmountOwedSender", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtSender", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableSender", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

#EndRegion

#EndRegion

#Region CreatingHyperlinkInIntercampanyDocumentLog

// Returns the text of the hyperlink for the transition from the document log to the transfer processing workplace.
//
// Parameters:
//	Parameters - Structure - parameters for forming the hyperlink text.
//
// Returns:
//  Undefined, FormattedString - the text of the hyperlink of the transition to the workplace of the registration of transfers.
Function CreateHyperlinkToDesign(Parameters) Export
	
	If Not AccessRight("Read", Metadata.AccumulationRegisters.CompanySafeStock) Then
		Return Undefined;
	EndIf;
	
	HyperlinkText = NStr("vi = 'Chuyển';
						|ru = 'Передачи';
						|en = 'Transfers'; fa = 'انتقال‌ها';
						|it = 'Consegne';
						|pl = 'Przeniesienia';
						|tr = 'Transferler'");
	Query = New Query;
	Query.SetParameter("MakeTransfers", True); 
	Query.SetParameter("IssueRansoms", False); 
	
	Query.SetParameter("Sender", Parameters.Organization);
	Query.SetParameter("Warehouse", Parameters.Warehouse);
	
	Query.Text = InventoriesServer.TextOfRequestForRegistrationOfReservesOfGoodsOrganizations(Query, "SamplingPresenceOfRecords");
		
	If Not Query.Execute().IsEmpty() Then
		Return New FormattedString(HyperlinkText, , , ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions");
	Else
		Return New FormattedString(HyperlinkText, , StyleColors.EmptyTableField, ,
			"DataProcessor.LogOfIntercompanyDocuments.Form.RegisterTransfersAndRedemptions");
	EndIf;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.Department            AS Department,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	MAX(TableDocumentRegistry.Contract)                  AS Contract,
	|	TableDocumentRegistry.LineOfBusiness            AS LineOfBusiness,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.Department                      AS Department,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.ExternalDocumentName) AS ExternalDocumentName,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber
	|INTO TTBases
	|FROM
	|	(SELECT
	|		DocumentData.Ref                                       AS Ref,
	|		&Period                                                      AS IBDocumentDate,
	|		&Number                                                       AS IBDocumentNumber,
	|		&MetadataIdentifier                                     AS RefType,
	|		&Organization                                                 AS Organization,
	|		&BusinessOperation                                       AS BusinessOperation,
	|		&Partner                                                     AS Partner,
	|		&Counterparty                                                  AS Counterparty,
	|		&Contract                                                     AS Contract,
	|		UNDEFINED                                                 AS LineOfBusiness,
	|		&Warehouse                                                       AS StorageLocation,
	|		&Department                                               AS Department,
	|		&Manager                                                    AS EmployeeResponsible,
	|		&Author                                                       AS Author,
	|		CAST(&Comment AS STRING(100))                       AS Comment,
	|		&Currency                                                      AS Currency,
	|		&DocumentAmount                                              AS Sum,
	|		UNDEFINED                                                 AS Status,
	|		&Posted                                                    AS Posted,
	|		&DeletionMark                                             AS DeletionMark,
	|		FALSE                                                         AS AdditionalRecord,
	|		CAST(&InformationAboutRecipientOrganization AS STRING(100)) AS More,
	|		&Period                                                      AS SourceDocumentDate,
	|		&ExternalDocumentName                              AS ExternalDocumentName,
	|		&DocumentNumber                                              AS SourceDocumentNumber
	|	FROM
	|		Document.CustomerInvoiceIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref                             AS Ref,
	|		&Period                                            AS IBDocumentDate,
	|		&Number                                             AS IBDocumentNumber,
	|		&MetadataIdentifier                           AS RefType,
	|		&CompanyRecipient                             AS Organization,
	|		&BusinessOperation                             AS BusinessOperation,
	|		&Partner                                           AS Partner,
	|		&Counterparty                                        AS Counterparty,
	|		&Contract                                           AS Contract,
	|		UNDEFINED                                       AS LineOfBusiness,
	|		&Warehouse                                             AS StorageLocation,
	|		&Department                                     AS Department,
	|		&Manager                                          AS EmployeeResponsible,
	|		&Author                                             AS Author,
	|		CAST(&Comment AS STRING(100))             AS Comment,
	|		&Currency                                            AS Currency,
	|		&DocumentAmount                                    AS Sum,
	|		UNDEFINED                                       AS Status,
	|		&Posted                                          AS Posted,
	|		&DeletionMark                                   AS DeletionMark,
	|		TRUE                                             AS AdditionalRecord,
	|		CAST(&OrganizationInformation AS STRING(100)) AS More,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &Period
	|			ELSE &IncomingDocumentDate
	|		END                                              AS SourceDocumentDate,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN UNDEFINED
	|			ELSE &ExternalDocumentName
	|		END                    AS ExternalDocumentName,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &DocumentNumber
	|			ELSE &IncomingDocumentNumber
	|		END                                              AS SourceDocumentNumber
	|	FROM
	|		Document.CustomerInvoiceIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	TableDocumentRegistry.LineOfBusiness,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
