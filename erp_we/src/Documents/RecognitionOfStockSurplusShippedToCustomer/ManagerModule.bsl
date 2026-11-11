#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//	AttributesDetails1 - Structure - description of the Attributes for which you need to get the statistics values.
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//	DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//											registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//	Document - DocumentRef, DocumentObject - a link to the document or object for which you want to get data.
//	Registers - Structure - list of register names for which tables should be retrieved.
//	AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//	See DocumentsPosting.InitializeDocumentDataForPosting.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RecognitionOfStockSurplusShippedToCustomer") Then
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
		
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		RecognitionOfStockSurplusShippedToCustomerLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region GenerateFrom

// Adds the command to create the document "Registration of surplus shipped goods".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
//
// Returns:
//	ValueTableRow, Undefined - the command to output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
													Metadata.Documents.RecognitionOfStockSurplusShippedToCustomer);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions =
		    "UseTransferToCustodyWithRightOfSale,
		    |UseShipmentWithDeferredTransferOfTitle2_5";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands.
//	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters.
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "BusinessOperation,Date";
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//	Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RecognitionOfStockSurplusShippedToCustomer";
	
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters.
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
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Products      AS Products,
	|	Goods.Characteristic    AS Characteristic,
	|	Goods.Purpose        AS Purpose,
	|	Goods.Series             AS Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind,
	|	SUM(Goods.Count) AS Count
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Series,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE
	|			CASE
	|				WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN &DocumentOperation_ = VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|									OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|									OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer)
	|										AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer
	|								THEN
	|									CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
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
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
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

#Region PurposeAndDirectionOfActivity

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate.
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	Return FormTemplate;
	
EndFunction

// The procedure for processing changes in the direction of activity.
//
// Parameters:
//	Form - ClientApplicationForm
//
// Returns:
//	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity.
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToFillInAssignment = "Goods";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Goods", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return RecognitionOfStockSurplusShippedToCustomerLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//	String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return RecognitionOfStockSurplusShippedToCustomerLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion
#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//	Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
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

#Region ArticleSelectionAndAnalytics

// Returns the parameters of the selection of articles and analyst.
//
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";
	ChoiceParameters.SelectingItemOfAssetsLiabilities	= True;
	ChoiceParameters.AssetsLiabilitiesDimension	= "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

// Returns parameters for setting up accounting accounts in the document.
//
// Returns:
//	See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.ArticleType   = "ArticleType";
	SetupParameters.Presentation = "TransactionRecordingPresentation";
	SetupParameters.AssetAndLiabilityItem = "IncomeItem";
	
	SetupParameters.FormItems.Add("TransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction
#Region Filling_By_Order

// Returns a collection of Attributes of the default document header.
//
// Returns:
//	Structure - collection containing a description of the Attributes of the document header:
//		* Ref - DocumentRef.RecognitionOfStockSurplusShippedToCustomer
//		* Partner - CatalogRef.Partners
//		* Counterparty - CatalogRef.Counterparties
//		* Terms - CatalogRef.TermsOfSale
//		* BusinessOperation - EnumRef.BusinessTransactions
//		* Organization - CatalogRef.Companies
//		* Contract - CatalogRef.CounterpartyContracts
//		* SalesOpportunity - CatalogRef.SalesOpportunitiesToCustomer
//		* LineOfBusiness - CatalogRef.LinesOfBusiness
//		* Department - CatalogRef.BusinessStructure
//		* Currency - CatalogRef.Currencies
//
Function HeaderAttributes() Export

	HeaderAttributes = New Structure;
	
	HeaderAttributes.Insert("Partner",                 Catalogs.Partners.EmptyRef());
	HeaderAttributes.Insert("Counterparty",              Catalogs.Counterparties.EmptyRef());
	HeaderAttributes.Insert("Terms",              Catalogs.TermsOfSale.EmptyRef());
	HeaderAttributes.Insert("BusinessOperation",   Enums.BusinessTransactions.EmptyRef());
	HeaderAttributes.Insert("Organization",             Catalogs.Companies.EmptyRef());
	HeaderAttributes.Insert("Contract",                 Catalogs.CounterpartyContracts.EmptyRef());
	HeaderAttributes.Insert("SalesOpportunity",                  Catalogs.SalesOpportunitiesToCustomer.EmptyRef());
	HeaderAttributes.Insert("Department",           Catalogs.BusinessStructure.EmptyRef());
	HeaderAttributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	HeaderAttributes.Insert("Currency",                  Catalogs.Currencies.EmptyRef());
	HeaderAttributes.Insert("Ref",
		Documents.RecognitionOfStockSurplusShippedToCustomer.EmptyRef());
	
	Return HeaderAttributes;
	
EndFunction

// Returns a collection of orders for the specified invoice, based on the transmitted selections.
//
// Parameters:
//	Invoice - DocumentRef.RecognitionOfStockSurplusShippedToCustomer - the invoice for which
//																		the selection of orders is carried out.
//	HeaderAttributes - See HeaderAttributes.
//
// Returns:
//	Array of DocumentRef - orders of the invoice.
//
Function WaybillOrders(Invoice, HeaderAttributes) Export
	
	QueryText =
	"SELECT ALLOWED
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.SalesOrder AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.LineOfBusiness = &LineOfBusiness)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref AS ReferenceOrder
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentData
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.LineOfBusiness = &LineOfBusiness)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	CASE
	|		WHEN DocumentData.Ref.Patch
	|			THEN DocumentData.Ref.CorrectedDocument
	|		ELSE
	|			DocumentData.Ref
	|	END AS ReferenceOrder
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS DocumentData
	|WHERE
	|	DocumentData.Ref.Posted
	|	AND DocumentData.Ref.Organization = &Organization
	|	AND DocumentData.Ref.Partner = &Partner
	|	AND DocumentData.Ref.Counterparty = &Counterparty
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Ref.Terms = &Terms)
	|	AND DocumentData.Ref.Contract = &Contract
	|	AND DocumentData.Ref.Currency = &Currency
	|	AND DocumentData.Ref.SalesOpportunity = &SalesOpportunity
	|	AND (NOT &UseLinesOfBusiness
	|		OR DocumentData.Ref.LineOfBusiness = &LineOfBusiness)
	|	AND (NOT DocumentData.Ref.ShipmentByOrders
	|		AND DocumentData.SalesOrder IN (
	|	                      VALUE(Document.SalesOrder.EmptyRef),
	|	                      VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                      VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                      UNDEFINED
	|	                      )
	|		OR
	|		DocumentData.Ref.ShipmentByOrders
	|		AND CASE
	|			WHEN DocumentData.SalesOrder REFS Document.SalesOrder
	|				THEN CAST(DocumentData.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			WHEN DocumentData.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				THEN CAST(DocumentData.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			ELSE
	|				FALSE
	|		END)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	DocumentData.Lot AS ReferenceOrder
	|FROM
	|	Document.OBEntryGoods AS DocumentData
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON DocumentData.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentData.Posted
	|	AND DocumentData.Organization = &Organization
	|	AND DocumentData.Partner = &Partner
	|	AND DocumentData.Counterparty = &Counterparty
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|	AND DocumentsRegistry.Ref IS NULL
	|";
	
	Query = New Query(QueryText);
	
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Partner",                 HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",              HeaderAttributes.Counterparty);
	Query.SetParameter("Terms",              HeaderAttributes.Terms);
	Query.SetParameter("Contract",                 HeaderAttributes.Contract);
	Query.SetParameter("Currency",                  HeaderAttributes.Currency);
	Query.SetParameter("SalesOpportunity",                  HeaderAttributes.SalesOpportunity);
	Query.SetParameter("LineOfBusiness", HeaderAttributes.LineOfBusiness);
	Query.SetParameter("ToUseTermsOfSales",
	                          GetFunctionalOption("ToUseTermsOfSales"));
	Query.SetParameter("UseLinesOfBusiness",
	                          GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness"));
	
	References = Query.Execute().Unload().UnloadColumn("ReferenceOrder");
	Return CommonClientServer.CollapseArray(References);
	
EndFunction

// Returns parameters for filling in the document by order.
//
// Returns:
//	Structure - a collection of parameters for filling out a document by order, containing the following properties:
//		* AnArrayOfOrders - Undefined, Array of DocumentRef - collection of links to the orders of the invoice.
//		* FieldNameOrder - String - the name of the Attribute used as the source of order information.
//		* KeyFields - See KeyFieldsOfGoodsTable.
//
Function DocumentFillingParameters() Export
	
	FillParameters = New Structure;
	FillParameters.Insert("AnArrayOfOrders",	Undefined);
	FillParameters.Insert("FieldNameOrder",	"ReferenceOrder");
	FillParameters.Insert("KeyFields",	"");
	
	Return FillParameters;
	
EndFunction

// Initializes parameters populate the document according to the document.
//
// Parameters:
//	FillParameters - See DocumentFillingParameters.
//	HeaderAttributes - See HeaderAttributes.
//	AnArrayOfOrders - Array of DocumentRef - a collection of links to the orders of the invoice, which will be
//												filled in.
//
Procedure InitializeFillingParameters(FillParameters, HeaderAttributes, AnArrayOfOrders) Export
	
	FillParameters.AnArrayOfOrders	= AnArrayOfOrders;
	FillParameters.KeyFields	= KeyFieldsOfGoodsTable();
	
EndProcedure

// Returns the names of the Attributes used to match tables when filling in orders.
//
// Returns:
//	String - the names of the Attributes by which the tables are compared when filling in orders.
//
Function KeyFieldsOfGoodsTable() Export
	
	Return "ReferenceOrder, Products, Characteristic, Purpose, Series";
	
EndFunction

// Fills in the table of goods by orders.
//
// Parameters:
//	Goods - ValueTable - Table products to fill In
//	Recorder - DocumentRef.RecognitionOfStockSurplusShippedToCustomer - link to the invoice.
//	FillParameters - See DocumentFillingParameters.
//	PackageBarcodes - ValueTable, Undefined - A table of barcodes for returning data on stamps.
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	QueryTexts = New Array();
	
	// 1. We get the Query Text for the Balances for shipment: [shipped] + [logged to PPP] - [debited to PPP]
	// - [formalized] - [accepted]
	
	QueryTexts.Add(QueryTextBalancesToBeProcessedByOrders());
	
	// 2. We connect the Balances to be shipped from item 1. with the data from the tables of the order documents.
	// The Number, Date, Document summation, etc. fields are required to be displayed in the order selection form.
	
	QueryText = 
	"SELECT
	|	TTAccountingData.ReferenceOrder                  AS ReferenceOrder,
	|	MAX(DataOfCorrectedDocuments.Date) AS DateOfLastCorrection
	|INTO RecentFixes
	|FROM
	|	Document.GoodsShipmentToCustomer AS DataOfCorrectedDocuments
	|	INNER JOIN TTAccountingData AS TTAccountingData
	|		ON DataOfCorrectedDocuments.CorrectedDocument = TTAccountingData.ReferenceOrder
	|WHERE
	|	DataOfCorrectedDocuments.Posted
	|	AND DataOfCorrectedDocuments.Patch
	|
	|GROUP BY
	|	TTAccountingData.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TTAccountingData.ReferenceOrder AS ReferenceOrder,
	|	DocumentsData.Ref    AS CorrectedShipmentOfItems
	|INTO CorrectionsOfItemShipments
	|FROM
	|	TTAccountingData AS TTAccountingData
	|	LEFT JOIN RecentFixes AS RecentFixes
	|		ON TTAccountingData.ReferenceOrder = RecentFixes.ReferenceOrder
	|	LEFT JOIN Document.GoodsShipmentToCustomer AS DocumentsData
	|		ON TTAccountingData.ReferenceOrder = DocumentsData.CorrectedDocument
	|			AND RecentFixes.DateOfLastCorrection = DocumentsData.Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.LineNumber               AS LineNumber,
	|	DataOfAccounting.ReferenceOrder          AS ReferenceOrder,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Series                     AS Series,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum
	|INTO VTKRegistration
	|FROM
	|	Document.SalesOrder.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber               AS LineNumber,
	|	DataOfAccounting.ReferenceOrder          AS ReferenceOrder,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Series                     AS Series,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum
	|FROM
	|	Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	NOT Table.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber               AS LineNumber,
	|	DataOfAccounting.ReferenceOrder          AS ReferenceOrder,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Series                     AS Series,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN CorrectionsOfItemShipments AS CorrectionsOfItemShipments
	|		ON ISNULL(CorrectionsOfItemShipments.CorrectedShipmentOfItems, CorrectionsOfItemShipments.ReferenceOrder) = Table.Ref
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON CorrectionsOfItemShipments.ReferenceOrder = DataOfAccounting.ReferenceOrder
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|
	|UNION ALL
	|
	// For lines over the order
	|SELECT
	|	ISNULL(Table.LineNumber, 0)  AS LineNumber,
	|	DataOfAccounting.ReferenceOrder          AS ReferenceOrder,
	|	DataOfAccounting.Products          AS Products,
	|	DataOfAccounting.Characteristic        AS Characteristic,
	|	DataOfAccounting.Series                 AS Series,
	|	SUM(ISNULL(Table.Count, 0) + ISNULL(RegistrationOfItems.Count, 0)) AS Count,
	|	MAX(DataOfAccounting.ForRegistrationQuantity) AS ToRegister,
	|	MAX(DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity) AS Price,
	|	MAX(DataOfAccounting.AmountToBeProcessed) AS Sum
	|FROM
	|	TTAccountingData AS DataOfAccounting
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS Table
	|		ON DataOfAccounting.ReferenceOrder = Table.SalesOrder
	|			AND Table.RowCode = 0
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|	LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS RegistrationOfItems
	|		ON DataOfAccounting.ReferenceOrder = RegistrationOfItems.ReferenceOrder
	|			AND DataOfAccounting.Products = RegistrationOfItems.Products
	|			AND DataOfAccounting.Characteristic = RegistrationOfItems.Characteristic
	|WHERE
	|	DataOfAccounting.RowCode = 0
	|
	|GROUP BY
	|	ISNULL(Table.LineNumber, 0),
	|	DataOfAccounting.ReferenceOrder,
	|	DataOfAccounting.Products,
	|	DataOfAccounting.Characteristic,
	|	ISNULL(Table.Warehouse, VALUE(Catalog.Warehouses.EmptyRef)),
	|	DataOfAccounting.Series,
	|	DataOfAccounting.RowCode,
	|	DataOfAccounting.CCDNumber
	|
	|UNION ALL
	|
	|SELECT
	|	Table.LineNumber               AS LineNumber,
	|	DataOfAccounting.ReferenceOrder          AS ReferenceOrder,
	|	Table.Products              AS Products,
	|	Table.Characteristic            AS Characteristic,
	|	Table.Series                     AS Series,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                             AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum
	|FROM
	|	Document.OBEntryGoods.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref.Lot
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(VTKRegistration.LineNumber) AS LineNumber,
	|	VTKRegistration.ReferenceOrder         AS ReferenceOrder,
	|	VTKRegistration.Products         AS Products,
	|	VTKRegistration.Characteristic       AS Characteristic,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	VTKRegistration.Series                AS Series,
	|	SUM(VTKRegistration.Count)    AS Count,
	|	SUM(VTKRegistration.ToRegister)   AS ToRegister,
	|	MAX(VTKRegistration.Price)       AS Price,
	|	SUM(VTKRegistration.Sum)         AS Sum
	|FROM
	|	VTKRegistration AS VTKRegistration
	|
	|GROUP BY
	|	VTKRegistration.ReferenceOrder,
	|	VTKRegistration.Products,
	|	VTKRegistration.Characteristic,
	|	VTKRegistration.Series
	|
	|ORDER BY
	|	VTKRegistration.ReferenceOrder
	|";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Table.Package",
			"Table.Products"));
	
	QueryTexts.Add(QueryText);
	
	QueryText = StrConcat(QueryTexts, InvoicesServer.QuerySeparatorText());
	
	Query = New Query(QueryText);
	Query.SetParameter("References", FillParameters.AnArrayOfOrders);
	Query.SetParameter("Recorder", Recorder);
	OrdersTable = Query.Execute().Unload();
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";

	// Adding the number of orders
	Var_Key = FillParameters.KeyFields;
	
	Condition = "On [Count]"; // @query-part
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("BusinessOperation");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.BusinessOperation =  Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor Then
		DocumentNameTemplate = NStr("vi = 'Ghi tăng hàng thừa của người nhận ký gửi %1 từ %2';
									|ru = 'Оприходование излишков товаров у комиссионера %1 от %2';
									|en = 'Stock surplus recognition at consignee %1 dated %2'; fa = 'Stock surplus recognition at consignee %1 dated %2';
									|it = 'Accettazione articoli in eccedenza presso il commissionario %1 di %2';
									|pl = 'Rejestracja nadwyżek towarów u komisanta %1 z dnia %2';
									|tr = '%1komisyoncudan %2tarihli mal fazlalıklarının envantere alınması'");
	ElsIf Data.BusinessOperation =  Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor Then
		DocumentNameTemplate = NStr("vi = 'Ghi tăng hàng thừa đang cất giữ và có quyền bán %1 từ %2';
									|ru = 'Оприходование излишков товаров на хранении с правом продажи %1 от %2';
									|en = 'Stock surplus recognition with the right to sell %1 dated %2'; fa = 'Stock surplus recognition with the right to sell %1 dated %2';
									|it = 'Accettazione articoli in eccedenza presso il magazzino con diritto di vendita %1 di %2';
									|pl = 'Rejestracja nadwyżek towarów na przechowywaniu z prawem sprzedaży %1 z dnia %2';
									|tr = 'Depodaki ihtiyaç fazlası malların %1satış hakkı ile %2 tarihinde kabulü'");
	Else
		DocumentNameTemplate = NStr("vi = 'Ghi tăng hàng thừa đã giao cho khách %1 từ %2';
									|ru = 'Оприходование излишков товаров, отгруженных клиенту %1 от %2';
									|en = 'Recognition of stock surplus shipped to the ""%1"" customer dated %2'; fa = 'Recognition of stock surplus shipped to the ""%1"" customer dated %2';
									|it = 'Recognition of stock surplus shipped to the ""%1"" customer dated %2';
									|pl = 'Recognition of stock surplus shipped to the ""%1"" customer dated %2';
									|tr = 'Müşteriye %1/%2 fazlalık olarak sevk edilen ürünlerin tahakkuku'");
	EndIf;
	
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(DocumentNameTemplate,
																			Data.Number,
																			Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

// Returns a collection of additional data sources when the item information in the accounting is updated.
//
// Parameters:
//	RegisterName - String - register name.
//
// Returns:
//	Map - collection of additional data sources when the item's information is reflected in accounting.
//
Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref             AS Ref,
	|	DocumentData.Number              AS Number,
	|	DocumentData.Date               AS Period,
	|	DocumentData.Partner            AS Partner,
	|	DocumentData.Counterparty         AS Counterparty,
	|	DocumentData.Terms         AS Terms,
	|	CASE
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems
	|			THEN DocumentData.IncomeItem
	|		ELSE UNDEFINED
	|	END                              AS IncomeItem,
	|	CASE
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|			THEN DocumentData.IncomeItem
	|		ELSE UNDEFINED
	|	END                              AS AssetAndLiabilityItem,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.DimensionOfRevenue  AS DimensionOfRevenue,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Contract            AS Contract,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	DocumentData.PriceKind            AS PriceKind,
	|	DocumentData.Comment        AS Comment,
	|	DocumentData.EmployeeResponsible      AS EmployeeResponsible,
	|	DocumentData.Author              AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department      AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.SalesOpportunity             AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.DeletionMark    AS DeletionMark,
	|	DocumentData.Posted           AS Posted,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
	|	DocumentData.Currency             AS Currency,
	|	DocumentData.DocumentAmount     AS DocumentAmount
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|		LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
	|		ON DocumentData.Contract = CounterpartyContracts.Ref
	|	
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	For Each Column In QueryResult.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ContractInformation    = "";
	NumberForPrinting           = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	MetadataIdentifier = Common.MetadataObjectID("Document.RecognitionOfStockSurplusShippedToCustomer");
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	If ValueIsFilled(Attributes.Contract) Then
		ContractInformation = NStr("vi = 'Theo hợp đồng ""%Contract%""';
									|ru = 'По договору ""%Contract%""';
									|en = 'Under the ""%Contract%"" contract'; fa = 'Under the ""%Contract%"" contract';
									|it = 'In base al contratto ""%Contract%""';
									|pl = 'Według umowy ""%Contract%""';
									|tr = '""%Contract%"" Sözleşmesi kapsamında'", Common.DefaultLanguageCode());
		ContractInformation = StrReplace(ContractInformation, "%Contract%", Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier",    MetadataIdentifier);
	Query.SetParameter("NumberForPrinting",              NumberForPrinting);
	Query.SetParameter("ContractInformation",       ContractInformation);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);

EndProcedure

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS ProductLineOfBusiness,
	|	&Partner AS Warehouse,
	|	&InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN &IncomeItem = UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE &IncomeItem
	|	END                     AS IncomeAndExpenseItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan   AS Cost,
	|	GoodsTable.SumMan   AS CostExcludingVAT,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.SumMan
	|		ELSE 0
	|	END                    AS CostMan,
	|	GoodsTable.SumCompl  AS LocalCost,
	|
	|	GoodsTable.InventoryOwnerAttribute AS SourceOfProductFinancialAccountingGroup
	|
	|FROM
	|	TTTableProducts AS GoodsTable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = " 
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	GoodsTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	GoodsTable.SumMan AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.SumMan
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN GoodsTable.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&IncomeItem <> UNDEFINED
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	GoodsTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	&AssetAndLiabilityItem AS AssetRef,
	|	CASE
	|		WHEN &AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	GoodsTable.SumMan AS Sum
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&AssetAndLiabilityItem <> UNDEFINED
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	GoodsTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	&AssetAndLiabilityItem AS AssetRef,
	|	&AssetsLiabilitiesDimension AS Dimension,
	|	&GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN GoodsTable.SumCompl
	|		ELSE 0 END) AS SumCompl,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.SumMan
	|		ELSE 0 END) AS SumMan,
	|	GoodsTable.SumMan AS AmountIncludingVAT,
	|	GoodsTable.SumMan AS AmountExcludingVAT,
	|
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&AssetAndLiabilityItem <> UNDEFINED
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Returns the Query Text of a temporary table and supplements the collection of values of executable Query Texts.
//
// Parameters:
//	Query - Query - a query that stores the parameters used in the query list.
//	QueryTexts - ValueList of String - collection of Query Texts and their names.
//
// Returns:
//	String - The text of the temporary table query.
//
Function QueryTextTableTTTableProducts(Query, QueryTexts) Export
	
	TempTableName = "TTTableProducts";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Products.ItemsType AS ItemsType,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE GoodsTable.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	GoodsTable.Sum AS Sum,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	&Contract AS Warehouse,
	|	GoodsTable.Ref.IncomeItem AS IncomeItem,
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.RowID AS FinRecordID
	|INTO TTTableProducts
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS GoodsTable
	|		LEFT JOIN  InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON GoodsTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND GoodsTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND GoodsTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND GoodsTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|		LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = GoodsTable.LineNumber
	|			AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		
		Return;
		
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
					Query.Parameters.Currency,
					Undefined,
					Query.Parameters.Period,
					Query.Parameters.Organization);
	
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Goods"" 									AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED 								AS VATRate,
	|	UNDEFINED								AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	0											AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS DocumentTable
	|	INNER JOIN Document.RecognitionOfStockSurplusShippedToCustomer AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(
					TextSelectionOfAnalystField,
					Query,
					QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                     AS Period,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	&Ref                     AS Document,
	|	&Partner                    AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|ORDER BY
	|	SeriesTable.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
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
	|	&Ref                  AS Ref,
	|	&Period                  AS IBDocumentDate,
	|	&Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization             AS Organization,
	|	&BusinessOperation   AS BusinessOperation,
	|	&Partner                 AS Partner,
	|	&Counterparty              AS Counterparty,
	|	&Contract                 AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	&Partner                 AS StorageLocation,
	|	&Department           AS Department,
	|	&EmployeeResponsible           AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	CAST(&Comment AS STRING(100)) AS Comment,
	|	&Currency                  AS Currency,
	|	&DocumentAmount          AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	&ContractInformation    AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableProducts", QueryTexts) Then
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	&Ref AS DocumentInflow,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.SumMan AS Cost,
	|	GoodsTable.SumMan AS CostExcludingVAT,
	|	GoodsTable.SumCompl AS LocalCost,
	|	CASE WHEN GoodsTable.Ref.IncomeItem.EnteredInTaxAccounting = FALSE THEN
	|		GoodsTable.SumCompl
	|	ELSE
	|		0
	|	END AS PermanentDifference,
	|	0 CostTD,
	|	GoodsTable.Products AS Products, 
	|	GoodsTable.Characteristic AS Characteristic,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTTableProducts AS GoodsTable
	|WHERE
	|	&BatchAccountingVersion21
	|ORDER BY
	|	LineNumber
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
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	TRUE AS Primary
	|FROM
	|	TTTableProducts AS GoodsTable
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction 

Function QueryTextTableShipmentReferences(Query, QueryTexts, Registers)
	
	RegisterName = "ShipmentAndReturnReferences";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	0 AS RowCode,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			AND GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	TableOfIndicators.Ref AS Factor,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.Sum) AS Sum
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS GoodsTable
	|	INNER JOIN Enum.IndicatorsOfShipmentAndReturnReferences AS TableOfIndicators
	|		ON TableOfIndicators.Ref IN(
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister),
	|				VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|				)
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation =
	|		VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer)
	|	AND NOT GoodsTable.ReferenceOrder IN (
	|				VALUE(Document.SalesOrder.EmptyRef),
	|				VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|				VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|				VALUE(Document.SourceDocument.EmptyRef),
	|				UNDEFINED
	|				)
	|
	|GROUP BY
	|	GoodsTable.LineNumber,
	|	GoodsTable.Ref.Date,
	|	GoodsTable.ReferenceOrder,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	CASE
	|		WHEN TableOfIndicators.Ref = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			AND GoodsTable.BatchesIndicationStatus IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	TableOfIndicators.Ref
	|
	|ORDER BY
	|	LineNumber,
	|	Factor";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Goods.ItemsLocationAttributes.Products   AS Products,
	|	Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment                                AS Purpose,
	|	Goods.ItemsLocationAttributes.Series          AS Series,
	|	Goods.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS Goods
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Goods.ItemsLocationAttributes.Products      = Dimension.Products
	|			AND Goods.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND Goods.ItemsLocationAttributes.Series          = Dimension.Series
	|			AND Goods.ItemsLocationAttributes.StorageLocation  = Dimension.StorageLocation
	|			AND &EmptyAssignment                                = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.Products IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments";
	
	QueryAnalyst.SetParameter("Ref",           Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",
										Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	&Ref                                                             AS Ref,
	|	MAX(
	|		ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS LineOfBusiness,
	|	COUNT(
	|		DISTINCT ISNULL(GoodsTable.Purpose.LineOfBusiness,
	|			VALUE(Catalog.LinesOfBusiness.EmptyRef))) AS NumberOfActivities
	|INTO TTBases
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer AS DocumentData
	|		LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

// Returns the result of adapting the Query Text of the accounting reflection for the case specified in the parameter.
//
// Parameters:
//	RegisterName - String - register name.
//
// Returns:
//	See InfobaseUpdateTM.ResultOfRequestAdaptation.
//
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.RecognitionOfStockSurplusShippedToCustomer";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	ParameterValues = New Structure();
	ParameterValues.Insert("MetadataIdentifier",
								Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "ShipmentAndReturnReferences" Then
		
		QueryText = QueryTextTableShipmentReferences(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "GoodsTable";
	
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
						RedefiningParameterCalculation,
						TemporaryTableQueryTexts);
		
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""Goods"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Organization AS Organization,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
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
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Ref.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor),
	|			VALUE(Enum.BusinessTransactions.RecognitionOfStockSurplusShippedToCustomer)
	|			)";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(Query,
																				QueryTexts,
																				Registers,
																				QueryTextdata_);

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
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableProducts");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTableTTTableProducts(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region InternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period AS Period,
	|	&Ref AS Ref,
	|	UNDEFINED AS DocumentSource,
	|	UNDEFINED AS SourceDocumentPeriod,
	|	UNDEFINED AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	&Ref AS Lot,
	|	&TaxationOfOrganization AS VATActivityType,
	|	UNDEFINED AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END AS LotVendorAttributesCorr,
	|	0 AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|	UNDEFINED AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	&SalesOpportunity AS SalesOpportunity,
	|	&Department AS Department,
	|	&Author AS Manager,
	|	UNDEFINED AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.SumMan AS Cost,
	|	TableTypesOfStocks_.SumMan AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl AS LocalCost,
	|	0 AS VATLocal,
	|	TableTypesOfStocks_.SumMan AS CostMan,
	|	0 AS VATManag,
	|	0 AS OffBalanceCost,
	|	0 AS OffBalanceCostLocal,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|	0 AS AddExpensesLocal,
	|	0 AS AddExpensesMan,
	|	CASE
	|		WHEN TableTypesOfStocks_.IncomeItem.EnteredInTaxAccounting = FALSE
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS CorGrossInitialCostENT,
	|
	// Other fields
	|	&BusinessOperation AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	TTTableProducts AS TableTypesOfStocks_";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	// The act of writing off goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfRegistrationOfSurplusGoods";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi tăng hàng thừa';
									|ru = 'Акт оприходования излишков товаров';
									|en = 'Certificate of stock surplus recognition'; fa = 'Certificate of stock surplus recognition';
									|it = 'Atto di accettazione delle eccedenze degli articoli';
									|pl = 'Protokół przyjęcia na stan nadmiar towarów';
									|tr = 'Stok fazlası mallar raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	RecognitionOfStockSurplusShippedToCustomerLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray        - Array of AnyRef - Array of links to objects that need to be printed.
//	PrintParameters       - Structure        - Structure of additional print parameters.
//	PrintFormsCollection - ValueTable  - generated tabular documents.
//	PrintObjects         - See PrintManagementOverridable.OnPrint.PrintObjects.
//	OutputParameters       - Structure        - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfRegistrationOfSurplusGoods") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection,
															"ActOfRegistrationOfSurplusGoods",
															NStr("vi = 'Biên bản ghi tăng hàng thừa';
																|ru = 'Акт оприходования излишков товаров';
																|en = 'Certificate of stock surplus recognition'; fa = 'Certificate of stock surplus recognition';
																|it = 'Atto di accettazione delle eccedenze degli articoli';
																|pl = 'Protokół przyjęcia na stan nadmiar towarów';
																|tr = 'Stok fazlası mallar raporu'"),
															FormPrintedFormOfActOfSurplusGoods(ObjectsArray, PrintObjects));
	EndIf;
	
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions,
														ObjectsArray,
														PrintFormsCollection);
	
EndProcedure

// This function generates a printed form of documents for debiting goods from custodians.
//
// Parameters:
//	ObjectsArray - Array of AnyRef - Array of links to objects that need to be printed.
//	PrintObjects  - See PrintManagementOverridable.OnPrint.PrintObjects.
//
// Returns:
//	SpreadsheetDocument - the printed form of the documents for the write-off of goods from the keepers.
//
Function FormPrintedFormOfActOfSurplusGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InventorySurplusRecognition.Ref      AS Ref,
	|	InventorySurplusRecognition.Number       AS Number,
	|	InventorySurplusRecognition.Date        AS Date,
	|	InventorySurplusRecognition.Counterparty  AS Counterparty,
	|	InventorySurplusRecognition.Organization AS Organization,
	|	ISNULL(Companies.Prefix, """") AS Prefix,
	|	InventorySurplusRecognition.BusinessOperation AS BusinessOperation,
	|	InventorySurplusRecognition.Department AS Department,
	|	PRESENTATION(InventorySurplusRecognition.Department) AS DepartmentPresentation,
	|	ISNULL(Users.Individual, VALUE(Catalog.Persons.EmptyRef)) AS EmployeeResponsible
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer AS InventorySurplusRecognition
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON InventorySurplusRecognition.Organization = Companies.Ref
	|		
	|		LEFT JOIN Catalog.Users AS Users
	|		ON InventorySurplusRecognition.EmployeeResponsible = Users.Ref
	|WHERE
	|	InventorySurplusRecognition.Ref IN(&ObjectsArray)
	|	AND InventorySurplusRecognition.Posted
	|
	|ORDER BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	DocumentGoods.Ref         AS Ref,
	|	DocumentGoods.LineNumber    AS LineNumber,
	|	ISNULL(CatProducts.Code, """") AS Code,
	|	ISNULL(CatProducts.SKU, """") AS SKU,
	|	ISNULL(CatProducts.DescriptionFull, """") AS ProductsPresentation,
	|	DocumentGoods.Products   AS Products,
	|	ISNULL(Characteristics.DescriptionFull, """") AS CharacteristicPresentation,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	PRESENTATION(DocumentGoods.Series) AS SeriesPresentation,
	|	PRESENTATION(CatProducts.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|	DocumentGoods.Count     AS Count
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS DocumentGoods
	|		LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer AS GoodsConsumption
	|		ON DocumentGoods.Ref = GoodsConsumption.Ref
	|		
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON DocumentGoods.Products = CatProducts.Ref
	|		
	|		LEFT JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON DocumentGoods.Characteristic = Characteristics.Ref
	|WHERE
	|	DocumentGoods.Ref IN(&ObjectsArray)
	|	AND GoodsConsumption.Posted
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|
	|TOTALS BY
	|	Ref";
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	
	ResultsArray   = Query.ExecuteBatch();
	
	ResultPrintData			= ResultsArray[0]; // QueryResult
	ResultDocumentSelection	= ResultsArray[1]; // QueryResult
	
	PrintData					= ResultPrintData.Select();
	SelectionByDocuments 			= ResultDocumentSelection.Select(QueryResultIteration.ByGroups);
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_PARAMETERS_RecordingOfSurplusShippedItems_StockShortageRecognitionReport";
	
	FirstDocument = True;
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	While PrintData.Next() Do
		
		If PrintData.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfConsignor Then
			DocumentSynonym = NStr("vi = 'Biên bản ghi tăng hàng hóa của người nhận ký gửi';
									|ru = 'Акт оприходования товаров у комиссионера';
									|en = 'Certificate of goods recognition at consignee'; fa = 'Certificate of goods recognition at consignee';
									|it = 'Atto di accettazione degli articoli presso il commissionario';
									|pl = 'Protokół przyjęcia na stan towarów u komisanta';
									|tr = 'Konsinye stok fazlası malları raporu'", Common.DefaultLanguageCode());
		ElsIf PrintData.BusinessOperation = Enums.BusinessTransactions.RecognizeInventorySurplusForTheBenefitOfDepositor Then
			DocumentSynonym = NStr("vi = 'Biên bản ghi tăng hàng hóa từ bên cất giữ';
									|ru = 'Акт оприходования товаров у хранителя';
									|en = 'Certificate of goods recognition at custodian'; fa = 'Certificate of goods recognition at custodian';
									|it = 'Atto di accettazione degli articoli presso il magazzino';
									|pl = 'Protokół przyjęcia na stan towarów u opiekuna';
									|tr = 'Emanetçide bulunan ürün envanteri raporu'", Common.DefaultLanguageCode());
		Else
			DocumentSynonym = NStr("vi = 'Biên bản ghi tăng hàng hóa của khách hàng';
									|ru = 'Акт оприходования товаров у клиента';
									|en = 'Certificate of stock recognition at customer'; fa = 'Certificate of stock recognition at customer';
									|it = 'Certificate of stock recognition at customer';
									|pl = 'Certificate of stock recognition at customer';
									|tr = 'Ürünlerin müşterinin tesislerinde kabul edilmesine yönelik rapor'", Common.DefaultLanguageCode());
		EndIf;
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.RecognitionOfStockSurplusShippedToCustomer.PF_MXL_ReportOnGoodsSurpluses"); // SpreadsheetDocument -
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice.
		If UseBusinessUnits Then
			HeaderArea_ = Template.GetArea("Title");
		Else
			HeaderArea_ = Template.GetArea("TitleWithoutDivision");
		EndIf;
		
		RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization,
																				PrintData.Date),
									"FullDescr");
		BuyerPresentation  = PrintFormGeneration.OrganizationDescription(
									PrintFormGeneration.InformationAboutLegalEntity(PrintData.Counterparty,
																				PrintData.Date),
									"FullDescr");
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText",
									TMCommonUseClientServer.GenerateDocumentTitle(PrintData,
																								DocumentSynonym));
		HeaderDataStructure_1.Insert("Organization",              PrintData.Organization);
		HeaderDataStructure_1.Insert("OrganizationPresentation", RepresentationOfTheOrganization);
		HeaderDataStructure_1.Insert("Customer",               PrintData.Counterparty);
		HeaderDataStructure_1.Insert("CustomerPresentation",  BuyerPresentation);
		
		If UseBusinessUnits Then
			HeaderDataStructure_1.Insert("Department",              PrintData.Department);
			HeaderDataStructure_1.Insert("DepartmentPresentation", PrintData.DepartmentPresentation);
		EndIf;
		
		HeaderArea_.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument,
																		Template,
																		HeaderArea_,
																		PrintData.Ref);
		
		SpreadsheetDocument.Put(HeaderArea_);
		
		// Output the title of the Products table.
		AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
		AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
		ProductAreaHeader  = Template.GetArea("TableHeader|OwnGoods");
		AreaDataHeader = Template.GetArea("TableHeader|Data");
		
		SpreadsheetDocument.Put(AreaOfHeaderNumber);
		
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			
			AreaCodesHeader.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodesHeader);
		Else
			Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth
													+ Template.Area("ColumnOfCodes").ColumnWidth;
		EndIf;
		
		SpreadsheetDocument.Join(ProductAreaHeader);
		SpreadsheetDocument.Join(AreaDataHeader);
		
		NumberAreaLine = Template.GetArea("String|LineNumber");
		AreaCodesString  = Template.GetArea("String|ColumnOfCodes");
		ProductLineArea_  = Template.GetArea("String|OwnGoods");
		DataAreaRow = Template.GetArea("String|Data");
		
		// We will find the products in the selection for the current document.
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		ProductSelection_1 = SelectionByDocuments.Select();
		
		LineNumber = 0;
		
		// Output the rows of the Products table.
		While ProductSelection_1.Next() Do
			LineNumber = LineNumber + 1;
			
			DataStructureLineNumber = New Structure("LineNumber", LineNumber);
			
			NumberAreaLine.Parameters.Fill(DataStructureLineNumber);
			SpreadsheetDocument.Put(NumberAreaLine);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("AdditionalColumn", ProductSelection_1[NameOfCodeColumn]);
				
				AreaCodesString.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodesString);
			EndIf;
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(ProductSelection_1.ProductsPresentation,
																				ProductSelection_1.CharacteristicPresentation,
																				Undefined,
																				ProductSelection_1.SeriesPresentation,
																				AdditionalParametersProductPresentation);
			
			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			
			ProductLineArea_.Parameters.Fill(ProductDataStructure);
			ProductLineArea_.Parameters.Fill(ProductSelection_1);
			SpreadsheetDocument.Join(ProductLineArea_);
			
			DataAreaRow.Parameters.Fill(ProductSelection_1);
			SpreadsheetDocument.Join(DataAreaRow);
		EndDo;
		
		RoomAreaBasement = Template.GetArea("TableFooter|LineNumber");
		AreaCodesBasement  = Template.GetArea("TableFooter|ColumnOfCodes");
		ProductAreaBasement  = Template.GetArea("TableFooter|OwnGoods");
		DataAreaBasement = Template.GetArea("TableFooter|Data");
		
		SpreadsheetDocument.Put(RoomAreaBasement);
		
		If OutputCodes Then
			SpreadsheetDocument.Join(AreaCodesBasement);
		EndIf;
		
		SpreadsheetDocument.Join(ProductAreaBasement);
		SpreadsheetDocument.Join(DataAreaBasement);
		
		// Output of results.
		AreaTotalQuantity = Template.GetArea("TotalCount1");
		
		TextOfResultingLine = NStr("vi = 'Tổng số tên gọi: %TotalItems_1%';
									|ru = 'Всего наименований: %TotalItems_1%';
									|en = 'Total items: %TotalItems_1%'; fa = 'Total items: %TotalItems_1%';
									|it = 'Totale articoli: %TotalItems_1%';
									|pl = 'Razem pozycji: %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", ProductSelection_1.Count());
		
		DataStructureSummaryRow = New Structure("TotalString", TextOfResultingLine);
		
		AreaTotalQuantity.Parameters.Fill(DataStructureSummaryRow);
		SpreadsheetDocument.Put(AreaTotalQuantity);
		
		// Output of signatures.
		LabelArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.EmployeeResponsible) Then
			DataStructureVacationProduced = New Structure("EmployeeResponsible",
															PersonsTM.IndividualShortName(PrintData.EmployeeResponsible,
																									PrintData.Date));
			
			LabelArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects,
			PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
//
// Parameters:
//	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure.
//
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	
	If GetFunctionalOption("UsePartnersAndCounterparties") Then
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	
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
//      * Key     - String - name of the prop in the template.
//      * Value - String - the fill value in the template.
//    * CommonAttributesValues - Map of KeyAndValue - list of common Attributes used in the template:
//      * Key     - String - name of the prop in the template.
//      * Value - String - the fill value in the template.
//    * Attachments - Map of KeyAndValue - the values of the requisites:
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
//     * SendingOption - String - Options for sending emails: "To", "Copy", "Hidden Copy", "Reverse Address".
//  MessageSubject - AnyRef - a reference to the object that is the data source.
//
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, MessageSubject) Export
	
EndProcedure

#EndRegion

Function QueryTextBalancesToBeProcessedByOrders(TempTableName = "TTAccountingData")
	
	QueryText =
	"SELECT ALLOWED
	|	TableRevolutions.ReferenceOrder AS ReferenceOrder,
	|	TableRevolutions.Products AS Products,
	|	TableRevolutions.Characteristic AS Characteristic,
	|	TableRevolutions.RowCode AS RowCode,
	|	TableRevolutions.Series AS Series,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS ShippedQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS ShippedAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS RegisteredUpToPPPQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS RegisteredUpToPPPAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS DeductedToPPPQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS DebitedToPPPAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS QuantityReadyForAcceptance,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS AmountToBeAccepted,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS QuantityAccepted_,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS AcceptedAmount,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|			THEN TableRevolutions.CountTurnover
	|		ELSE
	|			0
	|	END AS IssuedQuantity,
	|	CASE
	|		WHEN TableRevolutions.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|			THEN TableRevolutions.SumTurnover
	|		ELSE
	|			0
	|	END AS IssuedAmount
	|INTO ShippingOrdersTurnover
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder IN (&References)
	|				AND Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|				AND Factor IN (
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Shipped),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ReceivedBeforeTransferOfTitleToGoods),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ForReceiving),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Accepted),
	|						VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.Issued_1)
	|						)
	|	) AS TableRevolutions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableRevolutions.ReferenceOrder AS ReferenceOrder,
	|	TableRevolutions.Products AS Products,
	|	TableRevolutions.Characteristic AS Characteristic,
	|	TableRevolutions.RowCode AS RowCode,
	|	MAX(TableRevolutions.Series) AS Series,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	SUM(CASE
	|		WHEN TableRevolutions.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN TableRevolutions.QuantityReadyForAcceptance - TableRevolutions.QuantityAccepted_
	|		ELSE 
	|			TableRevolutions.ShippedQuantity
	|				+ TableRevolutions.RegisteredUpToPPPQuantity
	|				- TableRevolutions.DeductedToPPPQuantity
	|				- TableRevolutions.QuantityAccepted_
	|				- TableRevolutions.IssuedQuantity
	|	END) AS ForRegistrationQuantity,
	|	SUM(CASE
	|		WHEN TableRevolutions.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN TableRevolutions.AmountToBeAccepted - TableRevolutions.AcceptedAmount
	|		ELSE 
	|			TableRevolutions.ShippedAmount
	|				+ TableRevolutions.RegisteredUpToPPPAmount
	|				- TableRevolutions.DebitedToPPPAmount
	|				- TableRevolutions.AcceptedAmount
	|				- TableRevolutions.IssuedAmount
	|	END) AS AmountToBeProcessed
	|INTO #TempTableName
	|FROM
	|	ShippingOrdersTurnover AS TableRevolutions
	|
	|GROUP BY
	|	TableRevolutions.ReferenceOrder,
	|	TableRevolutions.Products,
	|	TableRevolutions.Characteristic,
	|	TableRevolutions.RowCode
	|
	|HAVING
	|	SUM(CASE
	|		WHEN TableRevolutions.ReferenceOrder REFS Document.SaleAdjustment
	|			THEN TableRevolutions.QuantityReadyForAcceptance - TableRevolutions.QuantityAccepted_
	|		ELSE 
	|			TableRevolutions.ShippedQuantity
	|				+ TableRevolutions.RegisteredUpToPPPQuantity
	|				- TableRevolutions.DeductedToPPPQuantity
	|				- TableRevolutions.QuantityAccepted_
	|				- TableRevolutions.IssuedQuantity
	|	END) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ShippingOrdersTurnover
	|";
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
