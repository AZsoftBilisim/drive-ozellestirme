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
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("Sales");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("ARAPAccounting");
	
	WriteOffOfShippedGoodsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.WriteOffOfShippedGoods") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
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
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableShipmentReferences(Query, QueryTexts, Registers);
		
		WriteOffOfShippedGoodsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleShipmentOfGoods(Query, QueryTexts, Registers);
	
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
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export
	
EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region GenerateFrom

// Adds the command to create the document "Debiting goods from the custodian".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
//
// Returns:
//	ValueTableRow, Undefined - the command to output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.WriteOffOfShippedGoods) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.WriteOffOfShippedGoods.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(
													Metadata.Documents.WriteOffOfShippedGoods);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseTransferToCustodyWithRightOfSale, UseShipmentWithDeferredTransferOfTitle2_5";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//	Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	WriteOffOfShippedGoodsLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#Region CreationOfGiverBasedOnReportOnWriteOffOfGoods

// Adds the command to create the document "Debiting goods from the custodian".
//
// Parameters:
//	GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands.
//
// Returns:
//	ValueTableRow, Undefined - the command to output to the submenu.
//
Function AddCreateCommandBasedOnReportOnWriteOffOfGiverSGoods(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.WriteOffOfShippedGoods) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.WriteOffOfShippedGoods.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Bảng kê ghi giảm hàng hóa của người nhận gia công';
														|ru = 'Отчет о списании товаров у переработчика';
														|en = 'Subcontractor stock adjustment'; fa = 'تعدیل موجودی نزد پیمانکار فرعی';
														|it = 'Report sulla cancellazione degli articoli presso l''elaboratore';
														|pl = 'Raport o rozchodzie towarów u przetwórcy';
														|tr = 'Fason üreticide ürünlerin silinmesine ilişkin rapor'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndProductionByThirdParty25";
		
		BsnsTransactions = New ValueList;
		BsnsTransactions.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAtTheExpenseOfProvider);
		BsnsTransactions.Add(Enums.BusinessTransactions.ProviderGoodsWriteOffAsExpenses);
		
		AttachableCommands.AddCommandVisibilityCondition(
			CreateBasedOnCommand,
			"BusinessOperation",
			BsnsTransactions,
			DataCompositionComparisonType.InList);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//	ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands.
//	Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters.
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	WriteOffOfShippedGoodsLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

#EndRegion

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on.
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
	SeriesSpecificationParameters.FullObjectName = "Document.WriteOffOfShippedGoods";
	
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("Warehouse");
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = Undefined;
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusInWarehouses");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusOfGoodsTransferred");
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
	SeriesSpecificationParameters.DocumentOperation_ = Object.BusinessOperation;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//	String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.LineNumber         AS LineNumber,
	|	Goods.Warehouse               AS Warehouse,
	|	Goods.Products        AS Products,
	|	Goods.Characteristic      AS Characteristic,
	|	Goods.Purpose          AS Purpose,
	|	Goods.Series               AS Series,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS BatchesIndicationStatusOfGoodsTransferred,
	|	Goods.Count          AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.Warehouse             AS Warehouse,
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
	|	Goods.Warehouse,
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
	|	Goods.BatchesIndicationStatusInWarehouses AS OldStatusOfSpecifyingSeriesInWarehouses,
	|	Goods.BatchesIndicationStatusOfGoodsTransferred AS OldStatusOfSpecifyingSeriesOfTransferredGoods,
	|	CASE
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN ProductsToRequest.ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				AND (ProductsToRequest.ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffShortagesAtDepositorSExpense)
	|					OR ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingOfBatchesInGoodsTransferredToCommissionAgent
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense)
	|					OR ProductsToRequest.ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.GoodsWriteOffAtToller)
	|					OR &DocumentOperation_ = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|						AND ProductsToRequest.ProductKind.BatchAccountingPolicy.AccountingForGoodsBatchesShippedToCustomer)
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 18
	|					ELSE 17
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatus,
	|	CASE
	|		WHEN &DocumentOperation_ <> VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 10
	|					ELSE 9
	|				END
	|		ELSE 0
	|	END                      AS BatchesIndicationStatusInWarehouses
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Warehouse = ProductsToRequest.Warehouse
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|		ON ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|			AND ProductsToRequest.Warehouse = BatchAccountingPolicies.Warehouse
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON ProductsToRequest.Warehouse = Warehouses.Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 3
	|SELECT
	|	Statuses.LineNumber                  AS LineNumber,
	|	Statuses.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatusInWarehouses,
	|	Statuses.BatchesIndicationStatus          AS BatchesIndicationStatusOfGoodsTransferred,
	|	CASE
	|		WHEN Statuses.BatchesIndicationStatus = 0
	|			THEN Statuses.BatchesIndicationStatusInWarehouses
	|		ELSE Statuses.BatchesIndicationStatus
	|	END                                AS BatchesIndicationStatus
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeriesOfTransferredGoods
	|	OR CASE
	|			WHEN Statuses.BatchesIndicationStatus = 0
	|				THEN Statuses.BatchesIndicationStatusInWarehouses
	|			ELSE Statuses.BatchesIndicationStatus
	|		END <> Statuses.OldStatusOfSpecifyingSeries
	|	OR Statuses.BatchesIndicationStatusInWarehouses <> Statuses.OldStatusOfSpecifyingSeriesInWarehouses
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region PurposeAndDirectionOfActivity

// Initializes parameters that serve the selection of assignments in document forms.
//
//	Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate.
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// The remnants of the transferred goods
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(
						FormTemplate,
						"GoodsTransferredToCustodians",
						True,
						"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Passed").Check = True;
	
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Contract        = "Object.Contract";
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	
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
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Goods";
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
	
	Return WriteOffOfShippedGoodsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//	String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return WriteOffOfShippedGoodsLocalization.RequestTextTTReflectedInLocalAccounting();
	
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

// Returns the parameters of the selection of articles and analyst.
//
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions.
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
//
// Returns:
//	See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	SetupParameters.ArticleType   = "ArticleType";
	
	SetupParameters.FormItems.Add("TransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction
// Returns the Products table
//
// Parameters:
//  Invoice - DocumentRef.GoodsReceiptFromCustomer - link to the invoice for PM Products that need to be returned
//
// Returns:
//  ValueTable - The tabular part of the goods receipt document.
//
Function TableDataAndDocument(Invoice) Export
	
	QueryText = 
		"SELECT
		|	GoodsTable.LineNumber,
		|	GoodsTable.Products,
		|	GoodsTable.Characteristic,
		|	GoodsTable.Purpose,
		|	GoodsTable.Count,
		|	GoodsTable.Warehouse,
		|	GoodsTable.Series,
		|	GoodsTable.BatchesIndicationStatus,
		|	GoodsTable.BatchesIndicationStatusInWarehouses,
		|	GoodsTable.BatchesIndicationStatusOfGoodsTransferred,
		|	GoodsTable.ItemsLocationAttributes,
		|	GoodsTable.CCDNumber,
		|	GoodsTable.Price,
		|	GoodsTable.Sum,
		|	GoodsTable.ReferenceOrder,
		|	GoodsTable.RowCode
		|FROM
		|	Document.WriteOffOfShippedGoods.Goods AS GoodsTable
		|WHERE
		|	GoodsTable.Ref = &Invoice";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice", Invoice);
	
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#Region Filling_By_Order

// Returns a collection of Attributes of the default document header.
//
// Returns:
//	Structure - collection containing a description of the Attributes of the document header:
//		* Ref - DocumentRef.WriteOffOfShippedGoods
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
	
	HeaderAttributes.Insert("Ref",					Documents.WriteOffOfShippedGoods.EmptyRef());
	HeaderAttributes.Insert("Partner",					Catalogs.Partners.EmptyRef());
	HeaderAttributes.Insert("Warehouse",						Catalogs.Warehouses.EmptyRef());
	HeaderAttributes.Insert("Counterparty",				Catalogs.Counterparties.EmptyRef());
	HeaderAttributes.Insert("Terms",				Catalogs.TermsOfSale.EmptyRef());
	HeaderAttributes.Insert("BusinessOperation",	Enums.BusinessTransactions.EmptyRef());
	HeaderAttributes.Insert("Organization",				Catalogs.Companies.EmptyRef());
	HeaderAttributes.Insert("Contract",					Catalogs.CounterpartyContracts.EmptyRef());
	HeaderAttributes.Insert("SalesOpportunity",					Catalogs.SalesOpportunitiesToCustomer.EmptyRef());
	HeaderAttributes.Insert("Department",			Catalogs.BusinessStructure.EmptyRef());
	HeaderAttributes.Insert("LineOfBusiness",	Catalogs.LinesOfBusiness.EmptyRef());
	HeaderAttributes.Insert("Currency",					Catalogs.Currencies.EmptyRef());
	
	Return HeaderAttributes;
	
EndFunction

// Returns a collection of orders for the specified invoice, based on the transmitted selections.
//
// Parameters:
//	Invoice - DocumentRef.WriteOffOfShippedGoods - the invoice for which the selection of orders is carried out.
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
	|	AND DocumentData.Terms = &Terms
	|	AND (NOT &ToUseTermsOfSales
	|		OR DocumentData.Terms = &Terms)
	|	AND DocumentData.Contract = &Contract
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.SalesOpportunity = &SalesOpportunity
	|	AND CASE
	|		WHEN NOT &UseLinesOfBusiness
	|			THEN TRUE
	|		ELSE DocumentData.LineOfBusiness = &LineOfBusiness
	|	END
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
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
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
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
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
	|		OR DocumentData.Ref.ShipmentByOrders
	|			AND CASE
	|				WHEN DocumentData.SalesOrder REFS Document.SalesOrder
	|					THEN CAST(DocumentData.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				WHEN DocumentData.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|					THEN CAST(DocumentData.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				ELSE
	|					FALSE
	|			END)
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
	|	AND DocumentData.Warehouse IN HIERARCHY (&Warehouse)
	|	AND &Warehouse <> VALUE(Catalog.Warehouses.EmptyRef)
	|	AND DocumentData.Currency = &Currency
	|	AND DocumentData.Lot <> VALUE(Document.SourceDocument.EmptyRef)
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	&Invoice AS ReferenceOrder
	|";
	
	Query = New Query(QueryText);
	Query.SetParameter("Invoice",               Invoice);
	Query.SetParameter("Organization",             HeaderAttributes.Organization);
	Query.SetParameter("Partner",                 HeaderAttributes.Partner);
	Query.SetParameter("Counterparty",              HeaderAttributes.Counterparty);
	Query.SetParameter("Terms",              HeaderAttributes.Terms);
	Query.SetParameter("Contract",                 HeaderAttributes.Contract);
	Query.SetParameter("Warehouse",                   HeaderAttributes.Warehouse);
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
	FillParameters.Insert("AnArrayOfOrders", Undefined);
	FillParameters.Insert("FieldNameOrder",  "ReferenceOrder");
	FillParameters.Insert("KeyFields",  "");
	
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
	
	FillParameters.AnArrayOfOrders = AnArrayOfOrders;
	FillParameters.KeyFields  = KeyFieldsOfGoodsTable();
	
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
//	Recorder	 - DocumentRef.WriteOffOfShippedGoods - link to the invoice.
//	FillParameters - See DocumentFillingParameters.
//	PackageBarcodes - ValueTable, Undefined - A table of barcodes for returning data on stamps.
//
Procedure FillInByOrdersOrders(Goods, Recorder, FillParameters, PackageBarcodes = Undefined) Export
	
	ToFillInCCD = Goods.Columns.Find("CCDNumber") <> Undefined;

	QueryTexts = New Array();
	
	// 1. We get the Query Text for the Balances for shipment: [shipped] + [logged to PPP] - [debited to PPP]
	// - [formalized] - [accepted]

	If ToFillInCCD Then
		QueryTexts.Add(QueryTextBalancesToBeProcessedByOrders("TTForRegistrationByOrder"));
		QueryTexts.Add(QueryTextBalancesToBeProcessedUnderCCD("TTForRegistrationByOrder"));
	Else
		QueryTexts.Add(QueryTextBalancesToBeProcessedByOrders());
	EndIf;
	
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
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                             AS Purpose,
	|	Table.Warehouse                     AS Warehouse,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                             AS Series,
	|	Table.RowCode                 AS RowCode,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum,
	|	DataOfAccounting.CCDNumber              AS CCDNumber
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
	|	CASE
	|		WHEN Table.WithAssignment
	|			THEN Table.Ref.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                             AS Purpose,
	|	Table.Ref.Warehouse              AS Warehouse,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                             AS Series,
	|	Table.RowCode                 AS RowCode,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum,
	|	DataOfAccounting.CCDNumber              AS CCDNumber
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
	|	Table.Purpose                AS Purpose,
	|	Table.Warehouse                     AS Warehouse,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                             AS Series,
	|	Table.RowCode                 AS RowCode,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum,
	|	DataOfAccounting.CCDNumber              AS CCDNumber
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	INNER JOIN CorrectionsOfItemShipments AS CorrectionsOfItemShipments
	|		ON ISNULL(CorrectionsOfItemShipments.CorrectedShipmentOfItems, CorrectionsOfItemShipments.ReferenceOrder) = Table.Ref
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON CorrectionsOfItemShipments.ReferenceOrder = DataOfAccounting.ReferenceOrder
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|WHERE
	|	Table.Ref.Posted
	|
	|UNION ALL
	|
	// For lines over the order
	|SELECT
	|	MAX(ISNULL(Table.LineNumber, 0))  AS LineNumber,
	|	DataOfAccounting.ReferenceOrder                    AS ReferenceOrder,
	|	DataOfAccounting.Products                    AS Products,
	|	DataOfAccounting.Characteristic                  AS Characteristic,
	|	MAX(ISNULL(Table.Purpose, VALUE(Catalog.Assignments.EmptyRef))) AS Purpose,
	|	MAX(ISNULL(Table.Warehouse, VALUE(Catalog.Warehouses.EmptyRef))) AS Warehouse,
	|	MAX(CASE
	|		WHEN Table.Series IS NOT NULL AND Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		WHEN RegistrationOfItems.Series IS NOT NULL AND RegistrationOfItems.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN RegistrationOfItems.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END)                                      AS Series,
	|	DataOfAccounting.RowCode                       AS RowCode,
	|	SUM(ISNULL(Table.Count, 0) + ISNULL(RegistrationOfItems.Count, 0)) AS Count,
	|	MAX(DataOfAccounting.ForRegistrationQuantity) AS ToRegister,
	|	MAX(CASE
	|		WHEN DataOfAccounting.ForRegistrationQuantity = 0
	|			THEN 0
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|	END)                                      AS Price,
	|	MAX(DataOfAccounting.AmountToBeProcessed)      AS Sum,
	|	DataOfAccounting.CCDNumber                        AS CCDNumber
	|FROM
	|	TTAccountingData AS DataOfAccounting
	|	LEFT JOIN Document.GoodsShipmentToCustomer.Goods AS Table
	|		ON DataOfAccounting.ReferenceOrder = Table.SalesOrder
	|			AND Table.RowCode = 0
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND Table.Ref.Posted
	|	LEFT JOIN Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS RegistrationOfItems
	|		ON DataOfAccounting.ReferenceOrder = RegistrationOfItems.ReferenceOrder
	|			AND DataOfAccounting.Products = RegistrationOfItems.Products
	|			AND DataOfAccounting.Characteristic = RegistrationOfItems.Characteristic
	|			AND RegistrationOfItems.Ref.Posted
	|WHERE
	|	DataOfAccounting.RowCode = 0
	|
	|GROUP BY
	|	DataOfAccounting.ReferenceOrder,
	|	DataOfAccounting.Products,
	|	DataOfAccounting.Characteristic,
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
	|	Table.Purpose                AS Purpose,
	|	Table.Ref.Warehouse              AS Warehouse,
	|	CASE
	|		WHEN Table.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|			THEN Table.Series
	|		ELSE
	|			DataOfAccounting.Series
	|	END                             AS Series,
	|	Table.RowCode                 AS RowCode,
	|	Table.Count                AS Count,
	|	DataOfAccounting.ForRegistrationQuantity AS ToRegister,
	|	CASE
	|		WHEN Table.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|			THEN DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|		ELSE
	|			DataOfAccounting.AmountToBeProcessed / DataOfAccounting.ForRegistrationQuantity
	|				* &QueryTextPackagingFactor
	|	END                             AS Price,
	|	DataOfAccounting.AmountToBeProcessed      AS Sum,
	|	Table.CCDNumber                  AS CCDNumber
	|FROM
	|	Document.OBEntryGoods.Goods AS Table
	|	INNER JOIN TTAccountingData AS DataOfAccounting
	|		ON DataOfAccounting.ReferenceOrder = Table.Ref.Lot
	|			AND DataOfAccounting.Products = Table.Products
	|			AND DataOfAccounting.Characteristic = Table.Characteristic
	|			AND DataOfAccounting.RowCode = Table.RowCode
	|			AND Table.Ref.Posted
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	DocumentsRegistry.Ref IS NULL
	|	AND Table.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(VTKRegistration.LineNumber) AS LineNumber,
	|	VTKRegistration.ReferenceOrder         AS ReferenceOrder,
	|	VTKRegistration.Products         AS Products,
	|	VTKRegistration.Characteristic       AS Characteristic,
	|	VTKRegistration.Purpose           AS Purpose,
	|	VTKRegistration.Warehouse                AS Warehouse,
	|	VTKRegistration.Series                AS Series,
	|	VTKRegistration.RowCode            AS RowCode,
	|	SUM(VTKRegistration.Count)    AS Count,
	|	SUM(VTKRegistration.ToRegister)   AS ToRegister,
	|	MAX(VTKRegistration.Price)       AS Price,
	|	SUM(VTKRegistration.Sum)         AS Sum,
	|	VTKRegistration.CCDNumber             AS CCDNumber
	|FROM
	|	VTKRegistration AS VTKRegistration
	|
	|GROUP BY
	|	VTKRegistration.ReferenceOrder,
	|	VTKRegistration.Products,
	|	VTKRegistration.Characteristic,
	|	VTKRegistration.Purpose,
	|	VTKRegistration.Warehouse,
	|	VTKRegistration.Series,
	|	VTKRegistration.RowCode,
	|	VTKRegistration.CCDNumber
	|
	|ORDER BY
	|	VTKRegistration.ReferenceOrder,
	|	MIN(VTKRegistration.LineNumber)
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

	Var_Key = "RowCode, " + FillParameters.KeyFields;
	If ToFillInCCD Then
		Var_Key = Var_Key + ", CCDNumber";
	EndIf;
	
	OrdersTable.Columns.ToRegister.Name = "QuantityInOrder";
	
	Condition = "On [Count]"; // @query-part
	InvoicesServer.AllocateQuantity(OrdersTable, Goods, "QuantityInOrder", Var_Key, Condition, True);
	
	// Adding an undistributed number of orders in separate lines
	InvoicesServer.SupplementTable(OrdersTable, Goods, "QuantityInOrder");
	
EndProcedure

#EndRegion

#Region Other

// Fills in the table of details that depend on the business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//	ArrayOfAllProps - Array of String - Bank details that do not depend on the business transaction.
//	ArrayOfOperationDetails - Array of String - Bank details that depend on the business transaction.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("Currency");
	ArrayOfAllProps.Add("DocumentAmount");
	ArrayOfAllProps.Add("PriceKind");
	ArrayOfAllProps.Add("ReduceShipmentByReference");
	ArrayOfAllProps.Add("SourseOfInformationAboutPricesForPrinting");
	ArrayOfAllProps.Add("Warehouse");
	
	ArrayOfAllProps.Add("Goods.Price");
	ArrayOfAllProps.Add("Goods.Sum");
	ArrayOfAllProps.Add("Goods.Warehouse");
	
	Handler = ActionHandler(BusinessOperation);
	ArrayOfOperationDetails = Handler.TransactionDetails();
	
EndProcedure

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods", Undefined);
	
	Return DocumentTables;
	
EndFunction

// Returns the Query Text for getting the Balance of goods in transit by CCD numbers.
//
//Parameters:
//	NameOfTemporaryTableToBeProcessedByOrders - String - the name of the temporary table containing information about goods and the quantity to be processed.
//	TempTableName - String - the name of the temporary table where the result will be placed is the Balance of goods in transit by CCD numbers.
//
// Returns:
//	String - Query text
Function QueryTextBalancesToBeProcessedUnderCCD(NameOfTemporaryTableToBeProcessedByOrders,
	TempTableName = "TTAccountingData") Export

	QueryText =
	"SELECT ALLOWED DISTINCT
	|	Table.Ref AS Document
	|INTO SalesDocumentsAll
	|FROM
	|	Document.GoodsShipmentToCustomer.Goods AS Table
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON Table.Ref = DocumentsRegistry.ReversedDocument
	|			AND DocumentsRegistry.Posted
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	Table.SalesOrder IN(&References)
	|	AND Table.Ref.Posted
	|	AND DocumentsRegistry.Ref IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Document
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.Ref IN(&References)
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Document
	|FROM
	|	Document.GoodsShipmentToCustomer AS Table
	|WHERE
	|	Table.CorrectedDocument IN(&References)
	|	AND Table.Ref.Patch
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS Document
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS Table
	|WHERE
	|	Table.ReferenceOrder IN(&References)
	|	AND Table.Ref.Posted
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Ref AS Document
	|FROM
	|	Document.OBEntryGoods.Goods AS Table
	|WHERE
	|	Table.Ref.Lot IN(&References)
	|	AND Table.Ref.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryKinds.ItemsLocationAttributesShipment AS ItemsLocationAttributes,
	|	InventoryKinds.CCDNumber                           AS CCDNumber,
	|	InventoryKinds.Count                         AS QuantityFromDocument,
	|	CASE
	|		WHEN Goods.SalesOrder IN (
	|	                   VALUE(Document.SalesOrder.EmptyRef),
	|	                   VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                   VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                   UNDEFINED
	|	                   )
	|				AND Goods.Ref.Patch
	|			THEN Goods.Ref.CorrectedDocument
	|		WHEN Goods.SalesOrder IN (
	|	                   VALUE(Document.SalesOrder.EmptyRef),
	|	                   VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                   VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                   UNDEFINED
	|	                   )
	|			THEN Goods.Ref
	|		WHEN Goods.SalesOrder REFS Document.SalesOrder
	|				AND CAST(Goods.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|			THEN Goods.Ref
	|		WHEN Goods.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|				AND CAST(Goods.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|			THEN Goods.Ref
	|		ELSE
	|			Goods.SalesOrder
	|	END                                          AS ReferenceOrder,
	|	Goods.RowCode                               AS RowCode
	|INTO InventoryLocationAttributesWithCCDNumbersAndNoGrouping
	|FROM
	|	Document.GoodsShipmentToCustomer.InventoryKinds AS InventoryKinds
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON InventoryKinds.Ref = SalesDocumentsAll.Document
	|	INNER JOIN Document.GoodsShipmentToCustomer.Goods AS Goods
	|		ON InventoryKinds.Ref = Goods.Ref
	|		AND InventoryKinds.ItemsLocationAttributes = Goods.ItemsLocationAttributes
	|		AND InventoryKinds.SalesOrder = Goods.SalesOrder
	|		AND InventoryKinds.RowCode = Goods.RowCode
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	Goods.Count                 AS QuantityFromDocument,
	|	Goods.ReferenceOrder               AS ReferenceOrder,
	|	0                                 AS RowCode
	|FROM
	|	Document.RecognitionOfStockSurplusShippedToCustomer.Goods AS Goods
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON Goods.Ref = SalesDocumentsAll.Document
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Goods.CCDNumber                   AS CCDNumber,
	|	Goods.Count                 AS QuantityFromDocument,
	|	Goods.Ref.Lot              AS ReferenceOrder,
	|	Goods.RowCode                  AS RowCode
	|FROM
	|	Document.OBEntryGoods.Goods AS Goods
	|	INNER JOIN SalesDocumentsAll AS SalesDocumentsAll
	|		ON Goods.Ref = SalesDocumentsAll.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	Table.CCDNumber                     AS CCDNumber,
	|	SUM(Table.QuantityFromDocument) AS QuantityFromDocument,
	|	Table.ReferenceOrder                 AS ReferenceOrder,
	|	Table.RowCode                    AS RowCode
	|INTO InventoryLocationAttributesWithCCDNumbers
	|FROM
	|	InventoryLocationAttributesWithCCDNumbersAndNoGrouping AS Table
	|
	|GROUP BY
	|	Table.ItemsLocationAttributes,
	|	Table.CCDNumber,
	|	Table.ReferenceOrder,
	|	Table.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Set.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	Set.CCDNumber                   AS CCDNumber,
	|	SUM(Set.Count)          AS BalanceOfCCD
	|INTO TTBalancesOnCCD
	|FROM
	|	(SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		Table.CountBalance          AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods.Balance(, (ItemsLocationAttributes, CCDNumber) IN (
	|			                                           SELECT
	|			                                               ItemsLocationAttributes,
	|			                                               CCDNumber
	|			                                           FROM
	|			                                               InventoryLocationAttributesWithCCDNumbers
	|			                                           )
	|		) AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ItemsLocationAttributes AS ItemsLocationAttributes,
	|		Table.CCDNumber                   AS CCDNumber,
	|		Table.Count                 AS Count
	|	FROM
	|		AccumulationRegister.CompanyGoods AS Table
	|	WHERE
	|		Table.Active
	|		AND Table.Recorder IN(&Recorder)
	|		AND Table.RecordType = VALUE(AccumulationRecordType.Expense)
	|	) AS Set
	|
	|GROUP BY
	|	Set.ItemsLocationAttributes,
	|	Set.CCDNumber
	|
	|HAVING
	|	SUM(Set.Count) > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Products AS Products,
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryLocationAttributesWithCCDNumbers.CCDNumber                   AS CCDNumber,
	|	InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument      AS QuantityFromDocument,
	|	InventoryLocationAttributesWithCCDNumbers.ReferenceOrder               AS ReferenceOrder,
	|	InventoryLocationAttributesWithCCDNumbers.RowCode                  AS RowCode,
	|	SUM(CASE
	|		WHEN InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument < TTBalancesOnCCD.BalanceOfCCD
	|			THEN InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument
	|		ELSE
	|			TTBalancesOnCCD.BalanceOfCCD
	|	END) AS BalanceOfCCD
	|INTO TTBalancesOnGTDSByOrders
	|FROM
	|	InventoryLocationAttributesWithCCDNumbers AS InventoryLocationAttributesWithCCDNumbers
	|	INNER JOIN TTBalancesOnCCD AS TTBalancesOnCCD
	|		ON InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes = TTBalancesOnCCD.ItemsLocationAttributes
	|		AND InventoryLocationAttributesWithCCDNumbers.CCDNumber = TTBalancesOnCCD.CCDNumber
	|
	|GROUP BY
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Products,
	|	InventoryLocationAttributesWithCCDNumbers.ItemsLocationAttributes.Characteristic,
	|	InventoryLocationAttributesWithCCDNumbers.CCDNumber,
	|	InventoryLocationAttributesWithCCDNumbers.QuantityFromDocument,
	|	InventoryLocationAttributesWithCCDNumbers.ReferenceOrder,
	|	InventoryLocationAttributesWithCCDNumbers.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTForRegistrationByOrder.ReferenceOrder               AS ReferenceOrder,
	|	TTForRegistrationByOrder.Products               AS Products,
	|	TTForRegistrationByOrder.Characteristic             AS Characteristic,
	|	TTForRegistrationByOrder.RowCode                  AS RowCode,
	|	TTForRegistrationByOrder.Series                      AS Series,
	|	ISNULL(TTBalancesOnGTDSByOrders.CCDNumber, VALUE(Catalog.CCDNumbers.EmptyRef)) AS CCDNumber,
	|	ISNULL(TTBalancesOnGTDSByOrders.BalanceOfCCD, 0) AS BalanceOfCCD,
	|	TTForRegistrationByOrder.ForRegistrationQuantity      AS ForRegistrationQuantity,
	|	TTForRegistrationByOrder.AmountToBeProcessed           AS AmountToBeProcessed
	|INTO Result
	|FROM
	|	#NameOfTemporaryTableToBeProcessedByOrders AS TTForRegistrationByOrder
	|	LEFT JOIN TTBalancesOnGTDSByOrders AS TTBalancesOnGTDSByOrders
	|		ON TTForRegistrationByOrder.Products = TTBalancesOnGTDSByOrders.Products
	|		AND TTForRegistrationByOrder.Characteristic = TTBalancesOnGTDSByOrders.Characteristic
	|		AND TTForRegistrationByOrder.ReferenceOrder = TTBalancesOnGTDSByOrders.ReferenceOrder
	|		AND TTForRegistrationByOrder.RowCode = TTBalancesOnGTDSByOrders.RowCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RECORDAUTONUMBER()               AS LineNumber,
	|	Result.ReferenceOrder          AS ReferenceOrder,
	|	Result.Products          AS Products,
	|	Result.Characteristic        AS Characteristic,
	|	Result.RowCode             AS RowCode,
	|	Result.Series                 AS Series,
	|	Result.CCDNumber              AS CCDNumber,
	|	Result.BalanceOfCCD          AS BalanceOfCCD,
	|	Result.ForRegistrationQuantity AS ForRegistrationQuantity,
	|	Result.AmountToBeProcessed      AS AmountToBeProcessed
	|INTO ResultIsNumbered
	|FROM
	|	Result
	|
	|INDEX BY
	|	LineNumber,
	|	ReferenceOrder,
	|	Products,
	|	Characteristic,
	|	RowCode,
	|	Series,
	|	CCDNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableBase.ReferenceOrder     AS ReferenceOrder,
	|	TableBase.Products     AS Products,
	|	TableBase.Characteristic   AS Characteristic,
	|	TableBase.RowCode        AS RowCode,
	|	TableBase.Series            AS Series,
	|	TableBase.CCDNumber         AS CCDNumber,
	|	CASE
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END AS ForRegistrationQuantity,
	|	CASE
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END * TableBase.AmountToBeProcessed / TableBase.ForRegistrationQuantity AS AmountToBeProcessed
	|INTO #TempTableName
	|FROM
	|	ResultIsNumbered AS TableBase
	|		LEFT JOIN ResultIsNumbered AS Distribution_Table
	|		ON TableBase.LineNumber >= Distribution_Table.LineNumber
	|		AND TableBase.ReferenceOrder = Distribution_Table.ReferenceOrder
	|		AND TableBase.Products = Distribution_Table.Products
	|		AND TableBase.Characteristic = Distribution_Table.Characteristic
	|		AND TableBase.Series = Distribution_Table.Series
	|		AND TableBase.RowCode = Distribution_Table.RowCode
	|
	|GROUP BY
	|	TableBase.LineNumber,
	|	TableBase.ReferenceOrder,
	|	TableBase.Products,
	|	TableBase.Characteristic,
	|	TableBase.RowCode,
	|	TableBase.Series,
	|	TableBase.CCDNumber,
	|	TableBase.BalanceOfCCD,
	|	TableBase.ForRegistrationQuantity,
	|	TableBase.AmountToBeProcessed
	|
	|HAVING
	|	CASE
	|		WHEN TableBase.ForRegistrationQuantity >= SUM(Distribution_Table.BalanceOfCCD)
	|			THEN TableBase.BalanceOfCCD
	|		WHEN TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity) < 0
	|			THEN 0
	|		ELSE
	|			  TableBase.BalanceOfCCD - (SUM(Distribution_Table.BalanceOfCCD) - TableBase.ForRegistrationQuantity)
	|	END <> 0
	|";
	
	QueryText = StrReplace(
		QueryText,
		"#NameOfTemporaryTableToBeProcessedByOrders",
		NameOfTemporaryTableToBeProcessedByOrders);
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("BusinessOperation");
	Fields.Add("Number");
	Fields.Add("Date");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	If Data.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
		ObjectPresentation = NStr("vi = 'Ghi giảm hàng hóa đã giao cho người nhận ký gửi';
									|ru = 'Списание товаров, отгруженных комиссионеру';
									|en = 'Write-off of goods shipped to consignee'; fa = 'Write-off of goods shipped to consignee';
									|it = 'Write-off of goods shipped to consignee';
									|pl = 'Write-off of goods shipped to consignee';
									|tr = 'Konsinyeye sevk edilen ürünlerin gider yazılması'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller Then
		ObjectPresentation = NStr("vi = 'Bảng kê ghi giảm hàng hóa của người nhận gia công';
									|ru = 'Отчет о списании товаров у переработчика';
									|en = 'Subcontractor stock adjustment'; fa = 'تعدیل موجودی نزد پیمانکار فرعی';
									|it = 'Report sulla cancellazione degli articoli presso l''elaboratore';
									|pl = 'Raport o rozchodzie towarów u przetwórcy';
									|tr = 'Fason üreticide ürünlerin silinmesine ilişkin rapor'");
	ElsIf Data.BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense Then
		ObjectPresentation = NStr("vi = 'Ghi giảm hàng hóa đã giao cho bên cất giữ';
									|ru = 'Списание товаров, отгруженных хранителю';
									|en = 'VMI write-off'; fa = 'VMI write-off';
									|it = 'VMI write-off';
									|pl = 'VMI write-off';
									|tr = 'Emanetçiye gönderilen ürünlerin gider yazılması'");
	Else
		ObjectPresentation = NStr("vi = 'Ghi giảm hàng hóa đã giao cho khách';
									|ru = 'Списание товаров, отгруженных клиенту';
									|en = 'Write-off of goods shipped to customer'; fa = 'اسقاط کالاهای ارسال‌شده به مشتری';
									|it = 'Write-off of goods shipped to customer';
									|pl = 'Write-off of goods shipped to customer';
									|tr = 'Müşteriye sevk edilen ürünlerin gider yazılması'");
	EndIf;
	
	Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
									|ru = '%1 %2 от %3';
									|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
									|it = '%1 %2 del %3';
									|pl = '%1 %2 z dnia %3';
									|tr = '%3 tarihli %1 %2'"), ObjectPresentation, Data.Number, Data.Date);
	
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
	|	DocumentData.ExpenseItem     AS ExpenseItem,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.DimensionOfExpenses  AS DimensionOfExpenses,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization        AS Organization,
	|	DocumentData.Contract            AS Contract,
	|	DocumentData.Warehouse              AS Warehouse,
	|	DocumentData.SourseOfInformationAboutPricesForPrinting AS SourseOfInformationAboutPricesForPrinting,
	|	DocumentData.PriceKind            AS PriceKind,
	|	DocumentData.Comment        AS Comment,
	|	DocumentData.InventoryOwnerAttributesAreSpecifiedManually AS InventoryOwnerAttributesAreSpecifiedManually,
	|	DocumentData.EmployeeResponsible      AS EmployeeResponsible,
	|	DocumentData.Author              AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Department      AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.SalesOpportunity             AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE) AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.DeletionMark    AS DeletionMark,
	|	DocumentData.Patch        AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Posted           AS Posted,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
	|	DocumentData.Currency AS Currency,
	|	CASE
	|		WHEN
	|			DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                              AS WriteOffFromCommitee,
	|	DocumentData.DocumentAmount     AS DocumentAmount,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_
	|FROM
	|	Document.WriteOffOfShippedGoods AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	MetadataIdentifier = Common.MetadataObjectID("Document.WriteOffOfShippedGoods");
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	
	Query.SetParameter("MetadataIdentifier", MetadataIdentifier);
	Query.SetParameter("NumberForPrinting",           NumberForPrinting);
	Query.SetParameter("ContractInformation",    ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RegisterRecordsProductsIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                   AS Period,
	|	&BusinessOperation    AS BusinessOperation,
	|	&Organization              AS Organization,
	|	&Department            AS Department,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                     AS ItemsLocationAttributes,
	|	&Partner                  AS Warehouse,
	|	GoodsTable.InventoryType  AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute  AS InventoryOwnerAttribute,
	|	&ExpenseItem           AS IncomeAndExpenseItem,
	|	&LineOfBusiness  AS LineOfBusinessItems,
	|	&DimensionOfExpenses        AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	GoodsTable.Count  AS Count,
	|	0                         AS Cost,
	|	0                         AS CostExcludingVAT,
	|	0                         AS LocalCost,
	|	GoodsTable.InventoryOwnerAttribute  AS SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS GoodsTable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
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
	|	&Partner                    AS Sender,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	FALSE                        AS ThisIsWarehouseRecord,
	|	SeriesTable.Count     AS Count
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS SeriesTable
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
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|			THEN &Warehouse
	|		ELSE &Partner
	|	END                    AS StorageLocation,
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
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
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
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period								AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization						AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	&BusinessOperation				AS BusinessOperation,
	|	&ExpenseItem						AS ExpenseItem,
	|	&DimensionOfExpenses					AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension			AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic,
	|	TableTypesOfStocks_.Count		AS Count,
	|	0									AS ToRegisterGoodsIssue,
	|	TableTypesOfStocks_.QuantityByGBRN	AS QuantityByGBRN,
	|	0									AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period								AS Period,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	&Organization						AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute		AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber			AS CCDNumber,
	|	&BusinessOperation				AS BusinessOperation,
	|	UNDEFINED						AS ExpenseItem,
	|	UNDEFINED						AS DimensionOfExpenses,
	|	UNDEFINED						AS AssetsLiabilitiesDimension,
	|	TableTypesOfStocks_.Products		AS Products,
	|	TableTypesOfStocks_.Characteristic	AS Characteristic,
	|	0									AS Count,
	|	TableTypesOfStocks_.Count		AS ToRegisterGoodsIssue,
	|	0									AS QuantityByGBRN,
	|	TableTypesOfStocks_.QuantityByGBRN	AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|
	|ORDER BY
	|	TableTypesOfStocks_.LineNumber
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
	// 1. For all lines with a completed order, we fill in the Register Records according to the PH of the order for the return
	// with the indicator "Written off to PPP"
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods) AS Factor,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.Sum) AS Sum
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
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
	|	GoodsTable.RowCode,
	|	CASE
	|		WHEN GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END
	|
	|UNION ALL
	|
	// 2. For the case when the Written-off goods field = "Ship again" and in the line with the line code > 0 we write
	// the indicator "To be shipped", and the quantity and amount with a + sign.
	// For the case when the Written-off goods field = "Not to ship", we write the indicator "For registration",
	// and the quantity and amount with the sign -.
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Ref.Date AS Period,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.RowCode AS RowCode,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END AS Warehouse,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN 
	|				GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END AS Series,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|		ELSE
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|	END AS Factor,
	|	SUM(CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Count
	|		ELSE
	|			-GoodsTable.Count
	|	END) AS Count,
	|	SUM(CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Sum
	|		ELSE
	|			-GoodsTable.Sum
	|	END) AS Sum
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
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
	|	GoodsTable.RowCode,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			AND GoodsTable.BatchesIndicationStatusInWarehouses IN (10, 14)
	|			THEN 
	|				GoodsTable.Series
	|		ELSE
	|			VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN GoodsTable.Warehouse
	|		ELSE VALUE(Catalog.Warehouses.EmptyRef)
	|	END,
	|	CASE
	|		WHEN GoodsTable.Ref.ReduceShipmentByReference
	|			AND GoodsTable.RowCode <> 0
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.SourceDocument
	|			AND NOT GoodsTable.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|			THEN VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToShip)
	|		ELSE
	|			VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.ToRegister)
	|	END
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
	"SELECT
	|	TabPart.Ref         AS Ref,
	|	TabPart.Ref.Date    AS Period,
	|	TabPart.Products   AS Products,
	|	TabPart.Characteristic AS Characteristic,
	|	TabPart.Warehouse          AS Warehouse,
	|	TabPart.Purpose     AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	TabPart.Count     AS Count,
	|	TRUE                  AS ControlOfFreeResidue,
	|	UNDEFINED            AS PlannedConsumptionOfDistributedStock
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS TabPart
	|WHERE
	|	TabPart.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|	AND TabPart.Ref.ReduceShipmentByReference
	|	AND TabPart.RowCode <> 0
	|	AND NOT TabPart.ReferenceOrder REFS Document.SourceDocument
	|	AND NOT TabPart.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, False);
	
EndProcedure

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	&Organization							AS Organization,
	|	Rows.Currency							AS Currency,
	|	Rows.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	Rows.CommitteeProductAnalysis	AS ItemsLocationAttributes,
	|	Rows.Products						AS Products,
	|	Rows.Characteristic					AS Characteristic,
	|	Rows.CCDNumber							AS CCDNumber,
	|	&BusinessOperation					AS BusinessOperation,
	|	Rows.Count						AS QuantityConsumed,
	|	Rows.Count						AS QuantityConsumedForIncoiceRegistration,
	|	Rows.QuantityByGBRN					AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	Rows.RowID				AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleShipmentOfGoods(Query, QueryTexts, Registers)
	
	TextOfDocumentDataRequest = 
	"SELECT
	|	DocumentGoods.Ref              AS Ref,
	|	HeaderData_.Date                    AS Period,
	|	DocumentGoods.ReferenceOrder        AS OrderDocument,
	|	HeaderData_.Ref                  AS Invoice,
	|	FALSE                                AS Patch,
	|	UNDEFINED                        AS CorrectedDocument,
	|	HeaderData_.Partner                 AS Recipient,
	|	DocumentGoods.Warehouse               AS Warehouse,
	|	DocumentGoods.Products        AS Products,
	|	DocumentGoods.Characteristic      AS Characteristic,
	|	DocumentGoods.Purpose          AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	DocumentGoods.Series               AS Series,
	|	DocumentGoods.BatchesIndicationStatusInWarehouses AS BatchesIndicationStatus,
	|	DocumentGoods.Count          AS Count,
	|	FALSE                                AS ExceedingOrder,
	|	FALSE                                AS Canceled,
	|	TRUE                              AS ThisIsAnInvoice,
	|	FALSE                                AS ShipmentByOrder
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS DocumentGoods
	|		LEFT JOIN Document.WriteOffOfShippedGoods AS HeaderData_
	|		ON DocumentGoods.Ref = HeaderData_.Ref
	|
	|WHERE
	|	DocumentGoods.Ref IN(&Ref)
	|	AND DocumentGoods.RowCode <> 0
	|	AND DocumentGoods.Count <> 0
	|	AND HeaderData_.ReduceShipmentByReference
	|	AND NOT DocumentGoods.ReferenceOrder REFS Document.SourceDocument
	|	AND NOT DocumentGoods.ReferenceOrder REFS Document.GoodsShipmentToCustomer
	|	AND NOT DocumentGoods.ReferenceOrder IN (
	|	                     UNDEFINED,
	|	                     VALUE(Document.SalesOrder.EmptyRef),
	|	                     VALUE(Document.RequestForReturnOfGoodsFromCustomer.EmptyRef),
	|	                     VALUE(Document.GoodsShipmentToCustomer.EmptyRef),
	|	                     VALUE(Document.SourceDocument.EmptyRef)
	|	                     )
	|";
	
	WarehousesServer.ScheduleShipmentOfGoods(Query, QueryTexts, Registers, TextOfDocumentDataRequest);
	
EndProcedure

// Returns the Query Text of a temporary table and supplements the collection of values of executable Query Texts.
//
// Parameters:
//	Query - Query - a query that stores the parameters used in the query list.
//	QueryTexts - ValueList of String - collection of Query Texts and their names.
//
// Returns:
//	String - The text of the temporary table query.
//
Function QueryTextTTTypesOfStocks(Query, QueryTexts) Export
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                               AS LineNumber,
	|	InventoryKinds.Ref                                    AS Ref,
	|	CatInventoryKinds.GoodsOwner                         AS GoodsOwner,
	|	CatInventoryKinds.Contract                                AS Contract,
	|	InventoryKinds.InventoryOwnerAttribute                                AS InventoryOwnerAttribute,
	|	CatInventoryKinds.InventoryType                             AS InventoryType,
	|	InventoryKinds.ItemsLocationAttributes                AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                  AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Products   AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Purpose     AS Purpose,
	|	InventoryKinds.ItemsLocationAttributes.Series          AS Series,
	|	InventoryKinds.Count                                AS Count,
	|	InventoryKinds.QuantityByGBRN                          AS QuantityByGBRN,
	|	InventoryKinds.CCDNumber                                  AS CCDNumber,
	|	CASE 
	|		WHEN &WriteOffFromCommitee
	|			THEN InventoryKinds.Sum
	|		ELSE 0
	|	END                                                 AS Sum,
	|	CASE 
	|		WHEN &WriteOffFromCommitee
	|			THEN CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                 AS SumMan,
	|	CASE 
	|		WHEN &WriteOffFromCommitee
	|			THEN CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END                                                 AS SumCompl,
	|	ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS LineOfBusiness,
	|	InventoryKinds.RowID                       AS RowID,
	|	InventoryKinds.InventoryOwnerAttribute.Currency                         AS Currency,
	|	CommitteeKeys.DimensionKey                          AS CommitteeProductAnalysis,
	|	ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.VATActivityType,
	|		VALUE(Enum.VATTaxationTypes.EmptyRef)) AS VATActivityType
	|INTO TTTypesOfStocks
	|FROM
	|	Document.WriteOffOfShippedGoods.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON InventoryKinds.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND InventoryKinds.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|			AND InventoryKinds.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND InventoryKinds.ItemsLocationAttributes.ProductCostElement = AnalyticsWithoutAssignment.ProductCostElement
	|		
	|		LEFT JOIN Catalog.InventoryKinds AS CatInventoryKinds
	|		ON InventoryKinds.InventoryOwnerAttribute = CatInventoryKinds.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeKeys
	|		ON InventoryKinds.ItemsLocationAttributes.Products = CommitteeKeys.Products
	|			AND InventoryKinds.ItemsLocationAttributes.Characteristic = CommitteeKeys.Characteristic
	|			AND InventoryKinds.ItemsLocationAttributes.Purpose = CommitteeKeys.Purpose
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeKeys.Series
	|			AND InventoryKinds.InventoryOwnerAttribute.GoodsOwner = CommitteeKeys.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeKeys.ProductCostElement
	|WHERE
	|	InventoryKinds.Ref = &Ref";
	
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
	|	Keys.Products   AS Products,
	|	Keys.Characteristic AS Characteristic,
	|	&EmptyAssignment    AS Purpose,
	|	Keys.Series          AS Series,
	|	Keys.StorageLocation  AS Warehouse
	|FROM
	|	Document.WriteOffOfShippedGoods.InventoryKinds AS Goods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Goods.ItemsLocationAttributes = Keys.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Keys.Products = Dimension.Products
	|			AND Keys.Characteristic = Dimension.Characteristic
	|			AND Keys.Series = Dimension.Series
	|			AND Keys.StorageLocation = Dimension.StorageLocation
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Keys.Products               AS Products,
	|	Keys.Characteristic             AS Characteristic,
	|	&EmptyAssignment                AS Purpose,
	|	&Series                           AS Series,
	|	Goods.InventoryOwnerAttribute.GoodsOwner AS Warehouse
	|FROM
	|	Document.WriteOffOfShippedGoods.InventoryKinds AS Goods
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|		ON Goods.ItemsLocationAttributes = Keys.Ref
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Keys.Products = Dimension.Products
	|			AND Keys.Characteristic = Dimension.Characteristic
	|			AND &Series = Dimension.Series
	|			AND Goods.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|			AND &EmptyAssignment = Dimension.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND Goods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryAnalyst.SetParameter("Ref",           Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("Series",            Catalogs.ItemsBatches.EmptyRef());
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
	|	Document.WriteOffOfShippedGoods AS DocumentData
	|		LEFT JOIN Document.WriteOffOfShippedGoods.Goods AS GoodsTable
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
	
	FullDocumentName           = "Document.WriteOffOfShippedGoods";
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

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region LinesOfBusiness
	
	RegisterName = "TemporaryTableOfLinesOfBusiness";
	
	QueryTextLinesOfBusiness =
	"SELECT
	|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
	|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|		OR (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfAnalytics
	|INTO TTLinesOfBusiness
	|FROM
	|	Document.GoodsShipmentToCustomer AS DirectionsOfDocuments
	|WHERE
	|	DirectionsOfDocuments.Ref IN
	|		(SELECT
	|			ReferenceOrder
	|		FROM
	|			Document.WriteOffOfShippedGoods.Goods
	|		WHERE
	|			Ref = &Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	DirectionsOfDocuments.ARAPObject AS ARAPObject,
	|	DirectionsOfDocuments.ARAPObject.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.IncomeAccounting, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting))
	|		OR (ISNULL(DirectionsOfDocuments.ARAPObject.LineOfBusiness.VendorARAP, FALSE)
	|		AND
	|			DirectionsOfDocuments.ARAPObject.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting))
	|			THEN DirectionsOfDocuments.ARAPObject.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS DirectionOfAnalytics
	|FROM
	|	Document.SalesOrder AS DirectionsOfDocuments
	|WHERE
	|	DirectionsOfDocuments.Ref IN
	|		(SELECT
	|			ReferenceOrder
	|		FROM
	|			Document.WriteOffOfShippedGoods.Goods
	|		WHERE
	|			Ref = &Ref)";
	
	QueryTexts.Add(QueryTextLinesOfBusiness, RegisterName);
	
	#EndRegion
	
	#Region CancellationOfPlans
	
	TextPaymentPlans =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).Date AS OrderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).PaymentMethod AS PaymentMethod,
	|	DocumentDataHeader.Date AS PaymentDate,
	|	ScheduleStages.PaymentOption AS PaymentOption,
	|	-Table.Sum * ScheduleStages.PaymentPercentage / 100 AS AmountDue,
	|	0 AS MeasuringGoodsVarianceAmount,
	|	TRUE AS ExcludeDuringControl
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS Table
	|		INNER JOIN Document.WriteOffOfShippedGoods AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		INNER JOIN Document.SalesOrder.PaymentScheduleSteps AS ScheduleStages
	|		ON Table.ReferenceOrder = ScheduleStages.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND Table.RowCode <> 0
	|	AND NOT DocumentDataHeader.ReduceShipmentByReference
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND NOT CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
	
	TextShipmentPlans =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObject AS ARAPObject,
	|	ENDOFPERIOD(DocumentDataHeader.Date, DAY) AS DateOfShipment,
	|	-Table.Sum AS IncreaseToBeSHIPPED,
	|	-Table.Sum AS IncreaseShipping,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).Date AS OrderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	VALUE(Enum.BusinessTransactions.SchedulingOfSalesOrder) AS BusinessOperation,
	|	CAST(Table.ReferenceOrder AS Document.SalesOrder).PaymentMethod AS PaymentMethod
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS Table
	|		INNER JOIN Document.WriteOffOfShippedGoods AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		INNER JOIN Document.SalesOrder.Goods AS GoodsFromOrder
	|		ON Table.ReferenceOrder = GoodsFromOrder.Ref
	|			AND Table.RowCode = GoodsFromOrder.RowCode
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND Table.RowCode <> 0
	|	AND NOT DocumentDataHeader.ReduceShipmentByReference
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.SalesOrder)
	|	AND NOT CAST(Table.ReferenceOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|	AND CAST(Table.ReferenceOrder AS
	|		Document.SalesOrder).ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByARAPDocuments)";
	
	ARAPAccountingPostingCustomers.ExecutionOfCustomerOrder(Query, QueryTexts, Registers, TextPaymentPlans, TextShipmentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithClientsPaymentPlan(Query, QueryTexts, Registers, TextPaymentPlans);
	ARAPAccountingPostingCustomers.ConductingSettlementsWithCustomersShippingPlan(Query, QueryTexts, Registers, TextShipmentPlans);
	
	#EndRegion
	
	#Region ReduceShipping
	
	TextProducts_1 =
	"SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Partner AS Partner,
	|	DocumentDataHeader.Counterparty AS Counterparty,
	|	DocumentDataHeader.Contract AS Contract,
	|	DocumentDataHeader.LineOfBusiness AS LineOfBusiness,
	|	CAST(Table.ReferenceOrder AS Document.GoodsShipmentToCustomer).ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Date AS DateOfShipment,
	|	0 AS IncreaseShipping,
	|	Table.Sum AS ReduceShipping,
	|	0 AS IncreaseToBeSHIPPED,
	|	0 AS ReduceToBESHIPPED,
	|	Table.Sum AS AmountARAP,
	|	Table.ReferenceOrder AS SalesOrder_,
	|	0 AS DepositForPackage,
	|	FALSE AS ExceedingOrder,
	|	TRUE AS InvoiceForOrders,
	|	TRUE AS ThisIsTransferOfOwnershipBasedOnShipment,
	|	CAST(Table.ReferenceOrder AS Document.GoodsShipmentToCustomer).ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentDataHeader.Date AS RecorderDate,
	|	DocumentDataHeader.Number AS RecorderNumber,
	|	DocumentDataHeader.Currency AS ARAPCurrency,
	|	DocumentDataHeader.BusinessOperation AS BusinessOperation,
	|	DocumentDataHeader.Currency AS DocumentCurrency
	|FROM
	|	Document.WriteOffOfShippedGoods AS DocumentDataHeader
	|		INNER JOIN Document.WriteOffOfShippedGoods.Goods AS Table
	|		ON DocumentDataHeader.Ref = Table.Ref
	|WHERE
	|	DocumentDataHeader.Ref = &Ref
	|	AND VALUETYPE(Table.ReferenceOrder) = TYPE(Document.GoodsShipmentToCustomer)";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, "", "", "", TextProducts_1);
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""InventoryKinds"" AS DataSource,
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
	|	FALSE AS RecordedInARAPAccounting,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.WriteOffOfShippedGoods.InventoryKinds AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Ref.BusinessOperation IN (
	|			VALUE(Enum.BusinessTransactions.WriteOffShortagesAtConsignorSExpense),
	|			VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|			)";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

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
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	
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
	AdditionalTables.Add("TTTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Moving_GoodsInStorageWithRightToSell
	
	If Not Document = Undefined 
		And Document.BusinessOperation <> Enums.BusinessTransactions.WriteOffOfShippedGoods Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					 	AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes      	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	UNDEFINED 			 							AS VATActivityType,
	|	UNDEFINED			 							AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Author				AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|
	// Other fields
	|	DocumentTable.BusinessOperation  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|	TableTypesOfStocks_.RowID 	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffOfShippedGoods AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
	
	EndIf;
		
	#EndRegion
	
	#Region WriteOffForExpensesAssets_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED AS DocumentSource,
	|	UNDEFINED AS SourceDocumentPeriod,
	|	UNDEFINED AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END AS VATActivityType,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|		THEN TableTypesOfStocks_.VATActivityType
	|		ELSE UNDEFINED
	|	END AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED AS CorCompany,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|	DocumentTable.ExpenseItem AS ExpenseItemAssets,
	|	CASE
	|		WHEN VALUETYPE(DocumentTable.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|		THEN DocumentTable.DimensionOfExpenses
	|		ELSE DocumentTable.AssetsLiabilitiesDimension
	|	END AS AssetExpenseAnalytics,
	|	CASE
	|		WHEN DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)
	|		THEN TableTypesOfStocks_.LineOfBusiness
	|		ELSE DocumentTable.LineOfBusiness
	|	END AS CorLineOfBusiness,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity AS SalesOpportunity,
	|	DocumentTable.Department AS Department,
	|	DocumentTable.Author AS Manager,
	|	UNDEFINED AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count AS Count,
	|
	// Other fields
	|	DocumentTable.GLAccountSettings AS GLAccountSettings,
	|	DocumentTable.BusinessOperation 	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffOfShippedGoods AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (TableTypesOfStocks_.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|	OR &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.RecogniseAsExpensesAssets,
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
	
	// The act of writing off goods from the custodian
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfDebitingGoodsFromCustodian";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm hàng hóa từ nơi bảo quản';
									|ru = 'Акт о списании товаров у хранителя';
									|en = 'VMI adjustment'; fa = 'تعدیل VMI';
									|it = 'Atto di cancellazione contabile delle merci dal depositario';
									|pl = 'Akt o rozchodzie towarów u opiekuna';
									|tr = 'Emanetçi mallarının kayıttan düşmesine ilişkin rapor'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense,
														ComparisonType.Equal);
	// The act of writing off goods from the commission agent
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfWritingOffGoodsFromCommissionAgent";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm hàng hóa của người nhận ký gửi';
									|ru = 'Акт о списании товаров у комиссионера';
									|en = 'Stock shortage recognition at consignee'; fa = 'Stock shortage recognition at consignee';
									|it = 'Atto di storno articoli presso il commissionario';
									|pl = 'Protokół o rozchodzie towarów u komisanta';
									|tr = 'Konsinyeden malların silinmesine ilişkin rapor'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense,
														ComparisonType.Equal);
	
	// The Stock shortage recognition act from the customer
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfGoodsWriteOffFromCustomer";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm hàng hóa của khách hàng';
									|ru = 'Акт о списании товаров у клиента';
									|en = 'Stock shortage recognition at customer'; fa = 'Stock shortage recognition at customer';
									|it = 'Stock shortage recognition at customer';
									|pl = 'Stock shortage recognition at customer';
									|tr = 'Ürünlerin müşterinin tesisinden gider yazılmasına ilişkin rapor'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														Enums.BusinessTransactions.WriteOffOfShippedGoods,
														ComparisonType.Equal);
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfWritingOffGoodsFromProcessor";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm hàng hóa của người nhận gia công';
									|ru = 'Акт о списании товаров у переработчика';
									|en = 'Recognition of subcontractor stock adjustment'; fa = 'Recognition of subcontractor stock adjustment';
									|it = 'Atto di storno articoli presso l''elaboratore';
									|pl = 'Protokół o rozchodzie towarów u przetwórcy';
									|tr = 'Fason üreticiden malların silinmesine ilişkin rapor'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(PrintCommand,
														"BusinessOperation",
														Enums.BusinessTransactions.GoodsWriteOffAtToller,
														ComparisonType.Equal);
	WriteOffOfShippedGoodsLocalization.AddPrintCommands(PrintCommands);
	
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
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfDebitingGoodsFromCustodian") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ActOfDebitingGoodsFromCustodian",
			NStr("vi = 'Biên bản ghi giảm hàng hóa';
				|ru = 'Акт о списании товаров';
				|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
				|it = 'Atto di storno delle merci';
				|pl = 'Protokół o wybrakowaniu towarów';
				|tr = 'Malların silinmesi raporu'"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfWritingOffGoodsFromCommissionAgent") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ActOfWritingOffGoodsFromCommissionAgent",
			NStr("vi = 'Biên bản ghi giảm hàng hóa';
				|ru = 'Акт о списании товаров';
				|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
				|it = 'Atto di storno delle merci';
				|pl = 'Protokół o wybrakowaniu towarów';
				|tr = 'Malların silinmesi raporu'"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
	EndIf;
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfGoodsWriteOffFromCustomer") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ActOfGoodsWriteOffFromCustomer",
			NStr("vi = 'Biên bản ghi giảm hàng hóa';
				|ru = 'Акт о списании товаров';
				|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
				|it = 'Atto di storno delle merci';
				|pl = 'Protokół o wybrakowaniu towarów';
				|tr = 'Malların silinmesi raporu'"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfWritingOffGoodsFromProcessor") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"ActOfWritingOffGoodsFromProcessor",
			NStr("vi = 'Biên bản ghi giảm hàng hóa';
				|ru = 'Акт о списании товаров';
				|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
				|it = 'Atto di storno delle merci';
				|pl = 'Protokół o wybrakowaniu towarów';
				|tr = 'Malların silinmesi raporu'"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
	EndIf;
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions,
														ObjectsArray,
														PrintFormsCollection);
	
EndProcedure

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

// This function generates a printed form of documents for debiting goods from custodians.
//
// Parameters:
//	ObjectsArray - Array of AnyRef - Array of links to objects that need to be printed.
//	PrintObjects  - See PrintManagementOverridable.OnPrint.PrintObjects.
//
// Returns:
//	SpreadsheetDocument - the printed form of the documents for the write-off of goods from the keepers.
//
Function GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	GoodsConsumption.Ref      AS Ref,
	|	GoodsConsumption.Number       AS Number,
	|	GoodsConsumption.Date        AS Date,
	|	GoodsConsumption.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	GoodsConsumption.CorrectedDocument.Date  AS DateOfDocumentBeingCorrected,
	|	GoodsConsumption.Counterparty  AS Counterparty,
	|	GoodsConsumption.Organization AS Organization,
	|	ISNULL(Companies.Prefix, """") AS Prefix,
	|	GoodsConsumption.BusinessOperation AS BusinessOperation,
	|	GoodsConsumption.Department AS Department,
	|	PRESENTATION(GoodsConsumption.Department) AS DepartmentPresentation,
	|	ISNULL(Users.Individual, VALUE(Catalog.Persons.EmptyRef)) AS EmployeeResponsible
	|FROM
	|	Document.WriteOffOfShippedGoods AS GoodsConsumption
	|		LEFT JOIN Catalog.Companies AS Companies
	|		ON GoodsConsumption.Organization = Companies.Ref
	|		
	|		LEFT JOIN Catalog.Users AS Users
	|		ON GoodsConsumption.EmployeeResponsible = Users.Ref
	|WHERE
	|	GoodsConsumption.Ref IN(&ObjectsArray)
	|	AND GoodsConsumption.Posted
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
	|	Document.WriteOffOfShippedGoods.Goods AS DocumentGoods
	|		LEFT JOIN Document.WriteOffOfShippedGoods AS GoodsConsumption
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
	SpreadsheetDocument.PrintParametersName = "PRINTPARAMETERS_WriteOffOfShippedItems_StockShortageRecognitionReport";
	
	FirstDocument   = True;
	
	UseBusinessUnits = GetFunctionalOption("UseBusinessUnits");
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	While PrintData.Next() Do
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.WriteOffOfShippedGoods.PF_MXL_GoodsWriteOffNote");
		
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
		
		Handler = Documents.WriteOffOfShippedGoods.ActionHandler(PrintData.BusinessOperation);
		DocumentSynonym = Handler.SynonymOfDocumentForPrintedFormReportOnWriteOffOfGoods();
		
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
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
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

#Region UnifiedMethodsForBusinessOperations

#Region Posting

// Returns parameters for filling in inventory types for the document "Write-off of shipped goods".
//
// Parameters:
//	Object - DocumentObject.WriteOffOfShippedGoods - the document for which inventory filling is performed.
//
// Returns:
//	See InventoriesServer.ParametersForFillingInventoryTypes.
//
Function ParametersForFillingInventoryTypes(Object) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "ByAgreementSettings");
	FillParameters.ReversedDocument = Object.ReversedDocument;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Returns:
//	EnumRef.BusinessTransactions - business transaction of the Contract.
//
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

// Returns a collection of object Attribute names available of operation.
//
// Returns:
//	Array of String - collection of object Attribute names available of operation.
//
Function TransactionDetails() Export
	
	TransactionDetails = New Array;
	TransactionDetails.Add("PriceKind");
	TransactionDetails.Add("SourseOfInformationAboutPricesForPrinting");
	
	Return TransactionDetails;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns an indication of the applicability of agreements with clients.
//
// Returns:
//	Boolean - a sign of the applicability of agreements with clients.
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns a flag for using agreements with clients.
//
// Returns:
//	Boolean - indicates the use of agreements with clients.
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

#EndRegion

#Region Form

// Gets the default contract.
//
// Parameters:
//	Object - FormDataStructure - Document data.
//
// Returns:
//	CatalogRef.CounterpartyContracts - the default value of the document Contract.
//
Function GetDefaultContract(Object) Export
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Contract = SalesServer.GetDefaultContract(
					Object,
					ContractBusinessTransaction(),
					Undefined,
					Object.LineOfBusiness);
	Else
		Contract = SalesServer.GetDefaultContract(
					Object,
					ContractBusinessTransaction());
	EndIf;
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	Object - FormDataStructure - Document data.
//	Contract - CatalogRef.CounterpartyContracts, Undefined - the meaning of the Contract document.
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;
	
	SalesServer.SetContractAvailability(
		Object, Items.Contract.Enabled, Items.Contract.Visible, Contract);
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	Number - String - document number.
//	Date  - Date - document date.
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = False;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);
	
	Items.Partner.Title = NStr("vi = 'Khách hàng';
								|ru = 'Клиент';
								|en = 'Customer'; fa = 'مشتری';
								|it = 'Cliente';
								|pl = 'Customer';
								|tr = 'Müşteri'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	Items.SourseOfInformationAboutPricesForPrinting.Visible = True;
	Items.DocumentCurrency.Visible = False;
	Items.ReduceShipmentByReference.Visible = False;
	Items.Warehouse.Visible = False;
	Items.Warehouse.AutoMarkIncomplete = False;
	
	Items.GoodsFillInPricesUnderAgreement.Visible  = False;
	Items.Pages_Order.Visible           = False;
	Items.GoodsPickUpItemsByOrder.Visible = False;
	Items.GoodsUnlinkFromOrder.Visible         = False;
	
	TitleText = NStr("vi = 'Chọn hàng đã chuyển';
					|ru = 'Подобрать переданные товары';
					|en = 'Pick customer stock'; fa = 'انتخاب موجودی مشتری';
					|it = 'Selezionare le merci consegnate';
					|pl = 'Odbierz przeniesione wiersze pozycji';
					|tr = 'Transfer edilen malları seç'");
	
	FormCommand = Form.Commands.Find("SelectTransferredGoods");
	FormCommand.Title = TitleText;
	FormCommand.ToolTip = TitleText;
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//	Form  - ClientApplicationForm - client application.
//	Object - FormDataStructure - Document data.
//
Procedure AdjustItemSelectionSettings(Form, Object) Export
	
	Items = Form.Items;
	
	// Partner
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.Client", True));
	
	Items.Partner.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	// Counterparty
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("TitleByPartner", NStr("vi = 'Theo khách hàng';
																		|ru = 'По клиенту';
																		|en = 'By customer'; fa = 'بر اساس مشتری';
																		|it = 'Per cliente';
																		|pl = 'Przez klienta';
																		|tr = 'Müşteriye göre'")));
	
	Items.Counterparty.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
	//Contract
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.Status", Enums.CounterpartyContractStatuses.Valid));
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.BusinessOperation", ContractBusinessTransaction()));
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.DeletionMark", False));
	
	ArrayOfSelectParameterRelationships = New Array;
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Counterparty", "Object.Counterparty", LinkedValueChangeMode.Clear));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Organization", "Object.Organization", LinkedValueChangeMode.Clear));	
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Terms", "Object.Terms", LinkedValueChangeMode.DontChange));
	
	Items.Contract.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Contract.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	//Terms
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(
		New ChoiceParameter("Filter.ConsignmentSales25", False));
	
	ArrayOfSelectParameterRelationships = New Array;
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Date", "Object.Date", LinkedValueChangeMode.DontChange));
	ArrayOfSelectParameterRelationships.Add(
		New ChoiceParameterLink("Filter.Partner", "Object.Partner", LinkedValueChangeMode.Clear));
	
	Items.Terms.ChoiceParameters       = New FixedArray(ChoiceParametersArray);
	Items.Terms.ChoiceParameterLinks = New FixedArray(ArrayOfSelectParameterRelationships);
	
	// Direction of activity
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//	NewDocument - Boolean - indicates whether a new document has been created.
//	Number - String - document number.
//	Date - Date - Document date
//
// Returns:
//	String - title of the document form.
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	If NewDocument Then
		Title = StrTemplate(NStr("vi = '%1 (tạo mới)';
								|ru = '%1 (создание)';
								|en = '%1 (Create)'; fa = '%1 (Create)';
								|it = '%1 (creazione)';
								|pl = '%1 (utworzenie)';
								|tr = '%1 (oluştur)'"), ObjectPresentation());
	Else
		Title = StrTemplate(NStr("vi = '%1 %2 ngày %3';
								|ru = '%1 %2 от %3';
								|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
								|it = '%1 %2 del %3';
								|pl = '%1 %2 z dnia %3';
								|tr = '%3 tarihli %1 %2'"), ObjectPresentation(), Number, Date);
	EndIf;
	
	Return Title;
	
EndFunction

// Returns the Presentation of the document.
//
// Returns:
//	String - presentation of the document.
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Ghi giảm hàng hóa đã giao cho bên cất giữ';
				|ru = 'Списание товаров, отгруженных хранителю';
				|en = 'VMI write-off'; fa = 'VMI write-off';
				|it = 'VMI write-off';
				|pl = 'VMI write-off';
				|tr = 'Emanetçiye gönderilen ürünlerin gider yazılması'");
	
EndFunction

#EndRegion

#Region PrintForms

// Returns the synonym of the document used in the written form "The act of writing off goods from the custodian"
//
// Returns:
//	String - A synonym for a printed Form document.
//
Function SynonymOfDocumentForPrintedFormReportOnWriteOffOfGoods() Export
	
	DocumentSynonym = NStr("vi = 'Biên bản ghi giảm hàng hóa tại nơi cất giữ';
							|ru = 'Акт о списании товаров у хранителя';
							|en = 'VMI adjustment'; fa = 'تعدیل VMI';
							|it = 'Atto di cancellazione contabile delle merci dal depositario';
							|pl = 'Akt o rozchodzie towarów u opiekuna';
							|tr = 'Emanetçi mallarının kayıttan düşmesine ilişkin rapor'", Common.DefaultLanguageCode());
	
	Return DocumentSynonym;
	
EndFunction

#EndRegion

#EndRegion

#Region GeneralMethodsForBusinessOperations

#Region ActionHandlers

// Gets a server action handler depending on the business transaction.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions, Undefined - business operation of the document.
//
// Returns:
//	CommonModule, DocumentManager - handler manager.
//
Function ActionHandler(BusinessOperation = Undefined) Export
	
	If BusinessOperation = Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense Then
		ActionHandler = WriteOffGoodsOfCommissionAgent;
	ElsIf BusinessOperation = Enums.BusinessTransactions.GoodsWriteOffAtToller Then
		ActionHandler = GoodsWriteOffAtToller;
	ElsIf BusinessOperation = Enums.BusinessTransactions.WriteOffOfShippedGoods Then
		ActionHandler = WriteOffOfGoodsShippedToCustomer;
	Else
		ActionHandler = Documents.WriteOffOfShippedGoods;
	EndIf;
	
	Return ActionHandler;
	
EndFunction

#EndRegion

#Region Form

// Sets up the Business Operation Attribute.
//
// Parameters:
//	Form - ClientApplicationForm - the form of the client application.
//	Object - FormDataStructure - Document data.
//
Procedure ConfigureBusinessTransactionDetails(Form, Object) Export
	
	Items = Form.Items;
	ChoiceList = Items.BusinessOperation.ChoiceList;
	
	ChoiceList.Clear();
	
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		ChoiceList.Add(Enums.BusinessTransactions.WriteOffShortagesAtDepositorSExpense);
	EndIf;
	
	If GetFunctionalOption("UseSalesCommission") Then
		ChoiceList.Add(Enums.BusinessTransactions.WriteOffShortagesAtConsignorSExpense);
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		ChoiceList.Add(Enums.BusinessTransactions.GoodsWriteOffAtToller);
	EndIf;
	If GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_5") Then
		ChoiceList.Add(Enums.BusinessTransactions.WriteOffOfShippedGoods);
	EndIf;
	
	Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
		And ChoiceList.Count() = 1 Then
		
		Object.BusinessOperation = ChoiceList[0].Value;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	#Region Documents_WriteOffOfShippedItems_ProcessDataToUpgradeToNewVersion
	
	Handler = Handlers.Add();
	Handler.Procedure = "Documents.WriteOffOfShippedGoods.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("37bce852-8ca1-440b-b8db-eead2c670d92");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.WriteOffOfShippedGoods.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật chứng từ ""Ghi giảm hàng hóa đã giao"":';
								|ru = 'Обновление документов ""Списание отгруженных товаров"":';
								|en = 'Update the ""Shipped goods write-off"" documents:'; fa = 'Update the ""Shipped goods write-off"" documents:';
								|it = 'Update the ""Shipped goods write-off"" documents:';
								|pl = 'Update the ""Shipped goods write-off"" documents:';
								|tr = '""Sevk edilen ürünlerin gider yazılması"" belgelerinin güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Trạng thái chỉ định sê-ri hàng hóa đã chuyển giao"" trong phần bảng ""Hàng hóa"".';
								|ru = '- заполнение реквизита ""Статус указания серий, переданных товаров"" в табличной части ""Товары"".';
								|en = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.'; fa = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|it = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|pl = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|tr = '- ""Ürünler"" tablosundaki ""Seri numarası, teslim edilen ürünlerin durumu"" özniteliğinin doldurulması.'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.WriteOffOfShippedGoods.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	#EndRegion
	
EndProcedure

// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	HeaderAttributes.Ref AS Ref
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS ItemsDocuments
	|		INNER JOIN Document.WriteOffOfShippedGoods AS HeaderAttributes
	|		ON ItemsDocuments.Ref = HeaderAttributes.Ref
	|WHERE
	|	ItemsDocuments.BatchesIndicationStatus > 0
	|	AND ItemsDocuments.BatchesIndicationStatus <> ItemsDocuments.BatchesIndicationStatusOfGoodsTransferred
	|	AND NOT HeaderAttributes.BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfShippedGoods)";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName	= EmptyRef().Metadata().FullName();
	UpdatedData	=  InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý chứng từ ""Ghi giảm hàng hóa đã giao"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать документы ""Списание отгруженных товаров"" по обработчику:';
								|en = 'Cannot process the ""Shipped goods write-off"" documents by the handler:'; fa = 'Cannot process the ""Shipped goods write-off"" documents by the handler:';
								|it = 'Cannot process the ""Shipped goods write-off"" documents by the handler:';
								|pl = 'Cannot process the ""Shipped goods write-off"" documents by the handler:';
								|tr = 'İşleyici tarafından ""Sevk edilen ürünlerin gider yazılması"" belgeleri işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- điền mục tin ""Trạng thái chỉ định sê-ri hàng hóa chuyển"" trong phần bảng ""Hàng hóa"".';
								|ru = '- заполнение реквизита ""Статус указания серий, переданных товаров"" в табличной части ""Товары"".';
								|en = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.'; fa = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|it = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|pl = '- Fill the ""Batch indication status of goods transferred"" attribute in the ""Goods"" table.';
								|tr = '- ""Ürünler"" tablosundaki ""Seri numarası, teslim edilen ürünlerin durumu"" özniteliğinin doldurulması.'"));
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ItemsDocuments.LineNumber AS LineNumber
	|FROM
	|	Document.WriteOffOfShippedGoods.Goods AS ItemsDocuments
	|		INNER JOIN Document.WriteOffOfShippedGoods AS HeaderAttributes
	|		ON ItemsDocuments.Ref = HeaderAttributes.Ref
	|
	|WHERE
	|	ItemsDocuments.Ref = &Ref
	|	AND ItemsDocuments.BatchesIndicationStatus > 0
	|	AND ItemsDocuments.BatchesIndicationStatus <> ItemsDocuments.BatchesIndicationStatusOfGoodsTransferred";
	
	For Each Document In UpdatedData Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.WriteOffOfShippedGoods - 
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Kết chuyển lại chứng từ thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			If DocumentObject <> Undefined Then
				If DocumentObject.BusinessOperation <> Enums.BusinessTransactions.WriteOffOfShippedGoods Then
					Query.SetParameter("Ref", DocumentObject.Ref);
					
					QueryResult = Query.Execute();
					
					If Not QueryResult.IsEmpty() Then
						Selection = QueryResult.Select();
						
						While Selection.Next() Do
							LineProducts_ = DocumentObject.Goods[Selection.LineNumber - 1];
							LineProducts_.BatchesIndicationStatusOfGoodsTransferred = LineProducts_.BatchesIndicationStatus;
						EndDo;
					EndIf;
				EndIf;
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If DocumentObject <> Undefined
				And DocumentObject.Modified() Then
				
				InfobaseUpdate.WriteData(DocumentObject);
				
			Else
				InfobaseUpdate.MarkProcessingCompletion(Document.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Document.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
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
	|INTO OrdersForShipmentWithoutGrouping
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
	|
	|UNION ALL
	|
	|SELECT
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.RowCode AS RowCode,
	|	Table.Series AS Series,
	|	0 AS ShippedQuantity,
	|	0 AS ShippedAmount,
	|	0 AS RegisteredUpToPPPQuantity,
	|	0 AS RegisteredUpToPPPAmount,
	|	-Table.Count AS DeductedToPPPQuantity,
	|	-Table.Sum AS DebitedToPPPAmount,
	|	0 AS QuantityReadyForAcceptance,
	|	0 AS AmountToBeAccepted,
	|	0 AS QuantityAccepted_,
	|	0 AS AcceptedAmount,
	|	0 AS IssuedQuantity,
	|	0 AS IssuedAmount
	|FROM
	|	AccumulationRegister.ShipmentAndReturnReferences AS Table
	|WHERE
	|	Table.Active
	|	AND Table.Recorder = &Recorder
	|	AND Table.ReferenceOrder IN (&References)
	|	AND Table.Products.ItemsType = VALUE(Enum.ItemsTypes.OwnGoods)
	|	AND Table.Factor = VALUE(Enum.IndicatorsOfShipmentAndReturnReferences.WrittenOffBeforeTransferOfTitleToGoods)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	OrdersForShipmentWithoutGrouping.ReferenceOrder AS ReferenceOrder,
	|	OrdersForShipmentWithoutGrouping.Products AS Products,
	|	OrdersForShipmentWithoutGrouping.Characteristic AS Characteristic,
	|	OrdersForShipmentWithoutGrouping.RowCode AS RowCode,
	|	OrdersForShipmentWithoutGrouping.Series AS Series,
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedQuantity) AS ShippedQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedAmount) AS ShippedAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPQuantity) AS RegisteredUpToPPPQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPAmount) AS RegisteredUpToPPPAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.DeductedToPPPQuantity) AS DeductedToPPPQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.DebitedToPPPAmount) AS DebitedToPPPAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.QuantityReadyForAcceptance) AS QuantityReadyForAcceptance,
	|	SUM(OrdersForShipmentWithoutGrouping.AmountToBeAccepted) AS AmountToBeAccepted,
	|	SUM(OrdersForShipmentWithoutGrouping.QuantityAccepted_) AS QuantityAccepted_,
	|	SUM(OrdersForShipmentWithoutGrouping.AcceptedAmount) AS AcceptedAmount,
	|	SUM(OrdersForShipmentWithoutGrouping.IssuedQuantity) AS IssuedQuantity,
	|	SUM(OrdersForShipmentWithoutGrouping.IssuedAmount) AS IssuedAmount
	|INTO ShipmentOrdersAreGrouped
	|FROM
	|	OrdersForShipmentWithoutGrouping AS OrdersForShipmentWithoutGrouping
	|
	|GROUP BY
	|	OrdersForShipmentWithoutGrouping.ReferenceOrder,
	|	OrdersForShipmentWithoutGrouping.Products,
	|	OrdersForShipmentWithoutGrouping.Characteristic,
	|	OrdersForShipmentWithoutGrouping.RowCode,
	|	OrdersForShipmentWithoutGrouping.Series
	|
	|HAVING
	|	SUM(OrdersForShipmentWithoutGrouping.ShippedQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.ShippedAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.RegisteredUpToPPPAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.DeductedToPPPQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.DebitedToPPPAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.QuantityReadyForAcceptance) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.AmountToBeAccepted) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.QuantityAccepted_) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.AcceptedAmount) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.IssuedQuantity) <> 0
	|	OR SUM(OrdersForShipmentWithoutGrouping.IssuedAmount) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ShipmentOrdersAreGrouped.ReferenceOrder AS ReferenceOrder,
	|	ShipmentOrdersAreGrouped.Products AS Products,
	|	ShipmentOrdersAreGrouped.Characteristic AS Characteristic,
	|	ShipmentOrdersAreGrouped.RowCode AS RowCode,
	|	MAX(ShipmentOrdersAreGrouped.Series) AS Series,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	SUM(ShipmentOrdersAreGrouped.ShippedQuantity
	|			+ ShipmentOrdersAreGrouped.RegisteredUpToPPPQuantity
	|			- ShipmentOrdersAreGrouped.DeductedToPPPQuantity
	|			- ShipmentOrdersAreGrouped.QuantityAccepted_
	|			- ShipmentOrdersAreGrouped.IssuedQuantity) AS ForRegistrationQuantity,
	|	SUM(ShipmentOrdersAreGrouped.ShippedAmount
	|			+ ShipmentOrdersAreGrouped.RegisteredUpToPPPAmount
	|			- ShipmentOrdersAreGrouped.DebitedToPPPAmount
	|			- ShipmentOrdersAreGrouped.AcceptedAmount
	|			- ShipmentOrdersAreGrouped.IssuedAmount) AS AmountToBeProcessed
	|INTO TTForRegistrationByOrder
	|FROM
	|	ShipmentOrdersAreGrouped AS ShipmentOrdersAreGrouped
	|
	|GROUP BY
	|	ShipmentOrdersAreGrouped.ReferenceOrder,
	|	ShipmentOrdersAreGrouped.Products,
	|	ShipmentOrdersAreGrouped.Characteristic,
	|	ShipmentOrdersAreGrouped.RowCode
	|
	|HAVING
	|	SUM(ShipmentOrdersAreGrouped.ShippedQuantity
	|			+ ShipmentOrdersAreGrouped.RegisteredUpToPPPQuantity
	|			- ShipmentOrdersAreGrouped.DeductedToPPPQuantity
	|			- ShipmentOrdersAreGrouped.QuantityAccepted_
	|			- ShipmentOrdersAreGrouped.IssuedQuantity) <> 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OrdersForShipmentWithoutGrouping
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ShipmentOrdersAreGrouped
	|";
	
	QueryText = StrReplace(QueryText, "#TempTableName", TempTableName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf
