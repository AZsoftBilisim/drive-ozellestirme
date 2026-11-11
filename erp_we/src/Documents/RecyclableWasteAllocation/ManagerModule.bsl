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
	
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	RecyclableWasteAllocationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization");

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
EndProcedure

#Region StandardCommandSubsystems

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
	
	ProductionServer.AddCommandCreateProductReleaseWithoutOrderBasedOn(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	RecyclableWasteAllocationLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds a command to create the document "returnable waste Distribution".
//
// Parameters:
//  GenerationCommands - ValueTable - The description in the creation of the base is undefined.Before adding a command to create a base
// Returns:
// 	ValueTableRow - The description in the creation of the base is undefined.Before adding a command to create a base.Teamsreferences 
//
Function AddGenerateCommand(GenerationCommands) Export
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.MaterialAndLaborAllocationBase.AddWasteReturnDistributionCommand(ReportsCommands);
	RecyclableWasteAllocationLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// StandardSubsystems.Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
#Region PrintOutput

	If AccessRight("Read", Metadata.Documents.RecyclableWasteAllocation) Then
		
		// Production output
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "Invoice";
		PrintCommand.Presentation = NStr("vi = 'Xuất xưởng thành phẩm';
										|ru = 'Выпуск продукции';
										|en = 'Product release'; fa = 'تولید محصول';
										|it = 'Emissione di prodotti';
										|pl = 'Wyprodukowanie';
										|tr = 'Ürün sürümü'");
		PrintCommand.CheckPostingBeforePrint = True;
		
	EndIf;
	
#EndRegion

	DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands, "PlacementJob");
	
	RecyclableWasteAllocationLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	Return "Recipient, Date";
	
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
//	Parameters:
//			Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//	Returns:
//			Structure - The structure of the parameters for specifying the series for the object.
//
Function SeriesSpecificationParameters(Object) Export
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Recipient, False);
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.RecyclableWasteAllocation";
	
	SeriesSpecificationParameters.UseItemsBatch = WarehouseSeriesParameters.UseItemsBatch;
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ProductReceivingFromManufacturing);
	
	SeriesSpecificationParameters.SeriesWhenPlanningShipmentVHFSeriesAreIndicated = True;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.ShipmentPlanning = False;
	SeriesSpecificationParameters.SelectionPlanning   = False;
	SeriesSpecificationParameters.FactOfSelection           = True;
	
	SeriesSpecificationParameters.RegisterSeries = True;
	
	SeriesSpecificationParameters.ProductInHeader = True;
	SeriesSpecificationParameters.WarehouseFieldName = "Recipient";
	SeriesSpecificationParameters.Date = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//	Parameters:
//		SeriesSpecificationParameters - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
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
	|	Goods.Series,
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
	|	Goods.Series,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
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
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose,
	|	SUM(TableOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS TableOfSeries
	|
	|GROUP BY
	|	TableOfSeries.Products,
	|	TableOfSeries.Characteristic,
	|	TableOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningShipment
	|			THEN CASE
	|					WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|							AND ProductsToRequest.Count > 0
	|						THEN 10
	|					ELSE 9
	|				END
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND &Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN 0
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenPlanningPicking
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.BatchesAccountingByFEFO
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 6
	|								ELSE 5
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 8
	|							ELSE 7
	|						END
	|				END
	|		WHEN BatchAccountingPolicies.BatchAccountingPolicy.SpecifyByPickingResult
	|				AND &FactOfSelection
	|				AND BatchAccountingPolicies.BatchAccountingPolicy.SpecifyWhenShippingKitsForDisassembly
	|			THEN CASE
	|					WHEN BatchAccountingPolicies.BatchAccountingPolicy.AccountForRemainingSeries
	|						THEN CASE
	|								WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|										AND ProductsToRequest.Count > 0
	|									THEN 4
	|								ELSE 3
	|							END
	|					ELSE CASE
	|							WHEN ProductsToRequest.Count = ISNULL(SeriesToRequest.Count, 0)
	|									AND ProductsToRequest.Count > 0
	|								THEN 2
	|							ELSE 1
	|						END
	|				END
	|		ELSE 0
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN ProductsToRequest AS ProductsToRequest
	|			LEFT JOIN SeriesToRequest AS SeriesToRequest
	|			ON ProductsToRequest.Products = SeriesToRequest.Products
	|				AND ProductsToRequest.Characteristic = SeriesToRequest.Characteristic
	|				AND ProductsToRequest.Purpose = SeriesToRequest.Purpose
	|			LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|				INNER JOIN Catalog.Warehouses AS Warehouses
	|				ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|			ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|				AND ProductsToRequest.ProductKind = BatchAccountingPolicies.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
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

#Region FillType

// Generates a list of documents based on the passed parameters.
//	Parameters:
//		Parameters - Structure - the parameters for the generation of documents.
//			It has the structure {Productpravilu, data Folders, cost Grouping}, all keys are required.
//			Produktiyapravilu - a table of values containing a list of manufactured products distributed according to the rules.
//			Data folders-Structure - data for filling in the document header.
//		ListOfObjects - ValueList - list of generated documents.
//
Procedure DocumentsOnParameters(Parameters, ListOfObjects) Export
	
	ProductTable = GetFromTempStorage(Parameters.ProductsByRule);

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25(Parameters.HeaderData_.Date);
	
	QueriesTexts = New Array();
	
	QueryText =
		"SELECT
		|	ProductTable.Organization,
		|	ProductTable.AllocatedAccordingToRule,
		|	ProductTable.Department,
		|	ProductTable.Recipient,
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Series,
		|	ProductTable.Purpose,
		|	ProductTable.Count
		|INTO #ProductTable
		|FROM
		|	&ProductTable AS ProductTable
		|WHERE
		|	NOT ProductTable.Count = 0
		|	AND NOT ProductTable.ErrorInModelSettings
		|;
		|";
	QueriesTexts.Add(QueryText);
	
	ProductTableName_ = "ProductTable";
	
	If UsePriceManagementSystem25 Then

		ProductTableName_ = "ProductTablePreliminary";
		
		Settings = PriceManagementSystemClientServer.SettingsForTemporaryTableWithAdditionForPricing();
		
		Settings.SourceOfGoods = ProductTableName_;
		Settings.ReceiverOfGoods = "ProductTable";
		Settings.ListOfOtherFields = "Organization, AllocatedAccordingToRule, Department, Recipient, Purpose, Count";
		Settings.PackagingField = "";
		
		QueryText = PriceManagementSystemClientServer.TextOfTemporaryTableRequestWithAddendumForPricing(
												Settings,
												UsePriceManagementSystem25);
		QueriesTexts.Add(QueryText);
		QueriesTexts.Add(";");
	EndIf;
	
	QueryText = "
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductTable.Organization,
		|	CASE
		|		WHEN &AutoFill
		|			THEN ProductTable.AllocatedAccordingToRule
		|		ELSE UNDEFINED
		|	END AS AllocatedAccordingToRule,
		|	AllocationRules.AllocationBase AS AllocationBase,
		|	AllocationRules.ProductCostElement AS ProductCostElement,
		|	PlannedPriceView.Value AS PriceKind,
		|	ProductTable.Department,
		|	ProductTable.Recipient,
		|	ProductTable.Products,
		|	ProductTable.Characteristic,
		|	ProductTable.Series,
		|	ProductTable.Purpose,
		|	SUM(ProductTable.Count) AS Count,
		|	SUM(ProductTable.Count) AS QuantityAccordingToRule,
		|	ItemsPrices.Price AS Price,
		|	SUM(ProductTable.Count * ItemsPrices.Price) AS Sum
		|FROM
		|	ProductTable AS ProductTable
		|		LEFT JOIN Catalog.CostAllocationRules AS AllocationRules
		|		ON ProductTable.AllocatedAccordingToRule = AllocationRules.Ref
		|			AND (&AutoFill)
		|		LEFT JOIN Constant.PriceKindOfPlannedCostOfMaterialsAndWorks AS PlannedPriceView
		|		ON (TRUE)
		|		LEFT JOIN
		|			&ItemsPrices AS ItemsPrices
		|		ON 
		|			&ItemPriceConnectionCondition
		|
		|GROUP BY
		|	PlannedPriceView.Value,
		|	ProductTable.Organization,
		|	AllocationRules.ProductCostElement,
		|	ProductTable.Series,
		|	ProductTable.Purpose,
		|	ProductTable.Department,
		|	ProductTable.Characteristic,
		|	ProductTable.Products,
		|	ProductTable.Recipient,
		|	ProductTable.AllocatedAccordingToRule,
		|	AllocationRules.AllocationBase,
		|	ItemsPrices.Price";
	
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts);
	QueryText = StrReplace(QueryText, "#ProductTable", ProductTableName_);
		
	QueryText = StrReplace(QueryText,
		"&ItemsPrices",
		PriceManagementSystemClientServer.QueryTextInformationRegisterItemsPrices("ProductTable",
																				,
																				,
																				UsePriceManagementSystem25));
	QueryText = StrReplace(QueryText,
		"&ItemPriceConnectionCondition",
		PriceManagementSystemClientServer.RequestTextInformationRegisterItemPricesConnectionCondition(
		"ProductTable",
		"ItemsPrices",
		"PlannedPriceView.Value",
		UsePriceManagementSystem25));
		
	Query = New Query(QueryText);
		
	Query.SetParameter("ProductTable",		ProductTable);
	Query.SetParameter("AutoFill",	Parameters.AutoFill);
	Query.SetParameter("Date",					Parameters.HeaderData_.Date);
	
	ProductTable = Query.Execute().Unload();
	
	NumberOfNewDocuments	= 0;
	
	For Each CurProducts_ In ProductTable Do
		
		CurDocument = Documents.RecyclableWasteAllocation.CreateDocument();
		CurDocument.GetNewObjectRef();
		
		ListOfObjects.Add(CurDocument);
		NumberOfNewDocuments = NumberOfNewDocuments + 1;
		
		CurDocument.Fill(New Structure("Organization", CurProducts_.Organization));
		
		FillPropertyValues(CurDocument, Parameters.HeaderData_);
		FillPropertyValues(CurDocument, CurProducts_);
		
		SeriesSpecificationParameters = ProductsServer.SeriesSpecificationParameters(CurDocument, Documents.RecyclableWasteAllocation);
		ProductsServer.FillInStatusesForSpecifyingSeries(CurDocument, SeriesSpecificationParameters);
		
		If (CurDocument.BatchesIndicationStatus = 3
				Or CurDocument.BatchesIndicationStatus = 5
				Or CurDocument.BatchesIndicationStatus = 7
				Or CurDocument.BatchesIndicationStatus = 9)
			And ValueIsFilled(CurDocument.Series) Then
			FillPropertyValues(CurDocument.SetOfSeries.Add(), CurProducts_);
			CurDocument.BatchesIndicationStatus = CurDocument.BatchesIndicationStatus + 1;
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region VATAccounting

// Initializes the parameters for filling in the VAT activity type
//
// Parameters:
//  Object		- DocumentObject.RecyclableWasteAllocation, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
//
Function ParametersForFillingInVATActivityType(Object) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization							= Object.Organization;
	FillParameters.Date								= Object.Date;
	FillParameters.LineOfBusiness				= Object.LineOfBusiness;
	FillParameters.OutputOfProductsAndWorks				= True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

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

// Returns parameters for setting up accounting accounts in the document.
//  
// Returns:
//	See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation 	= True;
	SetupParameters.DataPath   			= "Object.OtherExpenses";
	SetupParameters.ArticleType     			= "ArticleType";
	SetupParameters.Organization 				= "Object.Organization";
	
	SetupParameters.FormItems.Add("OtherExpensesTransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters() Export 
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.OtherExpenses";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.DimensionOfExpenses 		 = "DimensionOfExpenses";
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.ChoosingExpenseItem = True;
	
	OptionsArray = New Array;
	OptionsArray.Add(Enums.CostAllocationOptions.ToLinesOfBusiness);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCurrentPeriodExpensesDirectly);
	OptionsArray.Add(Enums.CostAllocationOptions.ToDeferredExpenses);
	OptionsArray.Add(Enums.CostAllocationOptions.ToProductionCosts);
	OptionsArray.Add(Enums.CostAllocationOptions.ToNonCurrentAssetCost);
	OptionsArray.Add(Enums.CostAllocationOptions.DoNotAllocate);
	OptionsArray.Add(Enums.CostAllocationOptions.ToCostCenters);
	
	ChoiceParameters.SelectionOfExpenditureItems.BusinessOperation = Enums.BusinessTransactions.GoodsConsumptionOnDemand;
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = OptionsArray;
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	
	ChoiceParameters.FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("OtherExpensesAssetsLiabilitiesDimension");
	
	Return ChoiceParameters;
	
EndFunction

// Returns the rules for printing the printed form of the Task for selecting (placing) products.
//
// Returns:
//	Array - the elements of which is the structure (See DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand)
//
Function RulesForPrintingTasksForSelectionPlacement() Export
	
	JobPrintingRules = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.RulesForPrintingTasksForSelectionPlacement();
	JobPrintingRules.ReceiptOperation	= True;
	JobPrintingRules.WarehouseFieldName			= "Recipient";
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection of elements:
//     * RegisterNameTable - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RecyclableWasteAllocation") Then
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
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		RecyclableWasteAllocationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	ScheduleGoodsReceipt(Query, QueryTexts, Registers);
	CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
		"SELECT
		|	Attributes.Date,
		|	Attributes.Date AS Period,
		|	Attributes.Ref,
		|	Attributes.Number,
		|	Attributes.Posted,
		|	Attributes.DeletionMark,
		|	Attributes.Organization,
		|	Attributes.ProductionIssueForActivity,
		|	Attributes.LineOfBusiness,
		|	Attributes.AllocatedAccordingToRule,
		|	Attributes.QuantityAccordingToRule,
		|	Attributes.ProductCostElement,
		|	Attributes.PriceKind,
		|	Attributes.Department,
		|	Attributes.Recipient,
		|	Attributes.Products,
		|	CatProducts.ItemsType AS ItemsType,
		|	CatProducts.FinancialAccountingGroup AS FinancialAccountingGroup,
		|	CatProducts.AnalyticalGroup AS AnalyticalGroup,
		|	Attributes.Characteristic,
		|	Attributes.Series,
		|	Attributes.BatchesIndicationStatus,
		|	Attributes.Count,
		|	Attributes.Purpose,
		|	CatAssignments.RecordsInWarehouseRegisters AS RecordsInWarehouseRegisters,
		|	Attributes.Price,
		|	Attributes.Sum,
		|	Attributes.ItemsLocationAttributes,
		|	Attributes.Currency,
		|	Attributes.EmployeeResponsible,
		|	Attributes.Author,
		|	Attributes.Comment,
		|	Attributes.DocumentID,
		|	UNDEFINED AS AdjustmentPeriod_
		|FROM
		|	Document.RecyclableWasteAllocation AS Attributes
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON (CatProducts.Ref = Attributes.Products)
		|		LEFT JOIN Catalog.Assignments AS CatAssignments
		|		ON (CatAssignments.Ref = Attributes.Purpose)
		|WHERE
		|	Attributes.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups",
								GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	Query.SetParameter("MetadataIdentifier",
								Common.MetadataObjectID(Type("DocumentRef.RecyclableWasteAllocation")));
								
	Query.SetParameter("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Date);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency,
		                                                                         Query.Parameters.Currency,
		                                                                         Query.Parameters.Date,
		                                                                         Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)

	If Query = Undefined Or Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	AnalyticsRequest = New Query(
	"SELECT DISTINCT
	|	GoodsTable.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.ProductCostElement
	|FROM
	|	(
	// analytics of the recipient of returnable waste with an empty destination
	|	SELECT
	|		&Recipient											AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		CASE
	|			WHEN &BatchesIndicationStatus = 14
	|				THEN &Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END												AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	// analytics of the division when it is released to the warehouse
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		&Purpose											AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	// unit analytics when released to the warehouse without assignment
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	// production batch analytics
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	| 		ISNULL(CatProductionLots.Purpose, 
	| 			VALUE(Catalog.Assignments.EmptyRef))	AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.RecyclableWasteAllocation.ProductionLots AS GoodsTable
	|
	|		LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Ref = GoodsTable.ProductionLot
	|
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|		AND GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// production batch analytics with an empty assignment
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		GoodsTable.ProductCostElement						AS ProductCostElement
	|	FROM
	|		Document.RecyclableWasteAllocation.ProductionLots AS GoodsTable
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND GoodsTable.Ref = &Ref
	|	
	|	UNION ALL
	|	
	// analytics by rules
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		&Purpose											AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	WHERE
	|		&KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	// analytics by rules with an empty assignment
	|	SELECT
	|		&Department										AS Warehouse,
	|		&Products										AS Products,
	|		&Characteristic										AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)		AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef)	AS Series,
	|		VALUE(Catalog.ProductCostElements.EmptyRef)	AS ProductCostElement
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments) AS GoodsTable
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.Products = Dimension.Products
	|			AND GoodsTable.Characteristic = Dimension.Characteristic
	|			AND GoodsTable.Series = Dimension.Series
	|			AND GoodsTable.Warehouse = Dimension.StorageLocation
	|			AND GoodsTable.Purpose = Dimension.Purpose
	|			AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series,
	|	GoodsTable.ProductCostElement");
	
	AnalyticsRequest.SetParameter("Ref",					Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Recipient",				Query.Parameters.Recipient);
	AnalyticsRequest.SetParameter("Products",				Query.Parameters.Products);
	AnalyticsRequest.SetParameter("Characteristic",			Query.Parameters.Characteristic);
	AnalyticsRequest.SetParameter("Purpose",				Query.Parameters.Purpose);
	AnalyticsRequest.SetParameter("BatchesIndicationStatus",		Query.Parameters.BatchesIndicationStatus);
	AnalyticsRequest.SetParameter("Series",						Query.Parameters.Series);
	AnalyticsRequest.SetParameter("Department",				Query.Parameters.Department);
	AnalyticsRequest.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;

	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return RecyclableWasteAllocationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in the regulated accounting.
// Returns:
//	See RecyclableWasteAllocationLocalization.RequestTextTTReflectedInLocalAccounting
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return RecyclableWasteAllocationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region QueryTextsTemporaryTables

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryTextAITExpenseRecognitionSettings = CalculationOfCostLocalization.AITSettingsQueryText("", "DistributionOfReturnableWaste_QueryTextTTTableInitialOtherExpenses");
	QueryTexts.Add(QueryTextAITExpenseRecognitionSettings, RegisterName);
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Date									AS Period,
	|	&Organization							AS Organization,
	|	&AdjustmentPeriod_					AS VariancePeriod,
	|	InventoryKinds.Department				AS Department,
	|	&LineOfBusiness				AS LineOfBusiness,
	|	CatAssignments.LineOfBusiness	AS CorLineOfBusiness,
	|	InventoryKinds.ExpenseItem				AS ExpenseItem,
	|	InventoryKinds.DimensionOfExpenses			AS DimensionOfExpenses,
	|	UNDEFINED							AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	InventoryKinds.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|
	|	-CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountIncludingVAT,
	|	-CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountExcludingVAT,
	|	-CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountExcludingVATMan,
	|	-CASE
	|		WHEN NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN 0
	|		ELSE CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END									AS AmountIncludingVATCompl,
	|	-CASE
	|		WHEN ExpenseItems.EnteredInTaxAccounting
	|			THEN CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END									AS AmountExcludingVATCompl,
	|	-CASE
	|		WHEN ExpenseItems.EnteredInTaxAccounting
	|			THEN 0
	|		ELSE CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END									AS PermanentDifference,
	|	0										AS CostTD,
	|	-CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT IS NULL
	|			 AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN NOT ExpenseItems.EnteredInTaxAccounting
	|					THEN 0
	|				ELSE CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|			END
	|	END AS AITAmount,
	|
	|	InventoryKinds.FinRecordID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.RecyclableWasteAllocation.InventoryKinds AS InventoryKinds
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = InventoryKinds.ExpenseItem
	|		LEFT JOIN Catalog.Assignments AS CatAssignments
	|		ON CatAssignments.Ref = &Purpose
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|		ON SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT = InventoryKinds.Department
	|			AND (SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization = &Organization)
	|			AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|		ON (SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT = &LineOfBusiness)
	|			AND (SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization = &Organization)
	|			AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND VALUETYPE(InventoryKinds.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|	AND NOT InventoryKinds.ExpenseItem = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Date									AS Period,
	|	&Organization							AS Organization,
	|	&AdjustmentPeriod_					AS VariancePeriod,
	|	TableExpenses.Department			AS Department,
	|	&LineOfBusiness				AS LineOfBusiness,
	|	CatAssignments.LineOfBusiness	AS CorLineOfBusiness,
	|	TableExpenses.ExpenseItem			AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses		AS DimensionOfExpenses,
	|	UNDEFINED							AS VATActivityType,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	&ItemsLocationAttributes				AS ItemsLocationAttributes,
	|
	|	-CAST(&Price * TableExpenses.Count * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountIncludingVAT,
	|	-CAST(&Price * TableExpenses.Count * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountExcludingVAT,
	|	-CAST(&Price * TableExpenses.Count * &ConversionRateToManCurrency AS NUMBER(31,2))	AS AmountExcludingVATMan,
	|	-CASE
	|		WHEN NOT ExpenseItems.EnteredInTaxAccounting
	|			THEN 0
	|		ELSE CAST(&Price * TableExpenses.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END									AS AmountIncludingVATCompl,
	|	-CASE
	|		WHEN ExpenseItems.EnteredInTaxAccounting
	|			THEN CAST(&Price * TableExpenses.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END									AS AmountExcludingVATCompl,
	|	-CASE
	|		WHEN ExpenseItems.EnteredInTaxAccounting
	|			THEN 0
	|		ELSE CAST(&Price * TableExpenses.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END									AS PermanentDifference,
	|	0										AS CostTD,
	|	-CASE
	|		WHEN SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT IS NULL
	|			 AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN NOT ExpenseItems.EnteredInTaxAccounting
	|					THEN 0
	|				ELSE CAST(&Price * TableExpenses.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|			END
	|	END AS AITAmount,
	|
	|	TableExpenses.RowID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation.OtherExpenses AS TableExpenses
	|		LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Ref = TableExpenses.ExpenseItem
	|		LEFT JOIN Catalog.Assignments AS CatAssignments
	|		ON CatAssignments.Ref = &Purpose
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfLBExpensesByBusinessUnit
	|		ON SettingsForRecognitionOfLBExpensesByBusinessUnit.ObjectOfSeparateAccountingAIT = TableExpenses.Department
	|			AND (SettingsForRecognitionOfLBExpensesByBusinessUnit.Organization = &Organization)
	|			AND SettingsForRecognitionOfLBExpensesByBusinessUnit.ExpensesAreIncludedInCost
	|		LEFT JOIN AITExpenseRecognitionSettings AS SettingsForRecognitionOfExpensesLBDpoLineOfBusiness
	|		ON (SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ObjectOfSeparateAccountingAIT = &LineOfBusiness)
	|			AND (SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.Organization = &Organization)
	|			AND SettingsForRecognitionOfExpensesLBDpoLineOfBusiness.ExpensesAreIncludedInCost
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND &ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|;
	|DROP AITExpenseRecognitionSettings
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(AdditionalFields+",VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	OtherExpenses.Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	UNDEFINED AS LotVendorAttributes,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	OtherExpenses.VATActivityType AS VATActivityType,
	|
	|	OtherExpenses.AmountIncludingVAT AS Cost,
	|	OtherExpenses.AmountExcludingVAT AS CostExcludingVAT,
	|	OtherExpenses.AmountIncludingVATCompl AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	0 AS VATManag,
	|
	|	OtherExpenses.BusinessOperation,
	|	OtherExpenses.FinRecordID AS RowID,
	|	OtherExpenses.FinRecordID,
	|	OtherExpenses.BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTInitialOtherExpenses AS OtherExpenses
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

#EndRegion

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	// the arrival of returnable waste in the pantry
	"SELECT
	|	&Date																				AS Period,
	|	VALUE(AccumulationRecordType.Receipt)												AS RecordType,
	|	GoodsTable.ItemsLocationAttributes											AS ItemsLocationAttributes,
	|	&Organization																		AS Organization,
	|	GoodsTable.InventoryOwnerAttribute															AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)											AS CCDNumber,
	|	GoodsTable.Count															AS Count,
	|	0																					AS QuantityByGBRN,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)	AS BusinessOperation,
	|	&ProductionIssueForActivity																AS VATTaxation,
	|	&Products																		AS Products,
	|	&Characteristic																		AS Characteristic,
	|	TRUE																				AS Primary
	|FROM
	|	Document.RecyclableWasteAllocation.InventoryKinds AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure CreateReceiptOfGoodsOnOneWayBasis(Query, QueryTexts, Registers)

	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref				AS Ref,
	|	DataSource.Ref				AS Invoice,
	|	FALSE								AS Patch,
	|	UNDEFINED						AS CorrectedDocument,
	|	UNDEFINED						AS OrderDocument,
	|	UNDEFINED						AS Contract,
	|	UNDEFINED						AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	DataSource.Date					AS Date,
	|	DataSource.Products			AS Products,
	|	DataSource.Characteristic		AS Characteristic,
	|	DataSource.Purpose			AS Purpose,
	|	FALSE                                AS ToControlQuality,
	|	FALSE                                AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                        AS ControlledLotReference,
	|	DataSource.Series				AS Series,
	|	DataSource.BatchesIndicationStatus	AS BatchesIndicationStatus,
	|	FALSE								AS ExceedingOrder,
	|	DataSource.Recipient			AS Warehouse,
	|	DataSource.Department		AS Sender,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) AS BusinessOperation,
	|	DataSource.Count           AS Count,
	|	TRUE                              AS ThisIsAnInvoice,
	|	FALSE								AS ReceiptUnderOrders,
	|	FALSE								AS ThisIsAdjustmentInsideInvoice
	|FROM
	|	Document.RecyclableWasteAllocation AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	WarehousesServer.CreateReceiptOfGoodsOnOneWayBasis(Query, 
														QueryTexts, 
														Registers, 
														QueryTextDocument_, 
														Metadata.Documents.RecyclableWasteAllocation, 
														"SetOfSeries");

EndProcedure

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	// arrival of works at a fixed cost by the recipient
	"SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Recipient								AS Department,
	|	&Products							AS Products,
	|	&Characteristic							AS Characteristic,
	|	&Purpose								AS Purpose,
	|	&Count								AS Count
	|WHERE
	|	&ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
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
		|	&Date																	AS Period,
		|	&Products															AS Products,
		|	&Characteristic															AS Characteristic,
		|	CASE
		|		WHEN &RecordsInWarehouseRegisters
		|			THEN &Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END																	AS Purpose,
		|	&Series																	AS Series,
		|	&Count																AS Count,
		|	&Recipient																AS Sender,
		|	&Recipient																AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ProductReceivingFromManufacturing)	AS WarehouseOperation,
		|	&Ref																	AS Document,
		|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt			AS ThisIsWarehouseRecord
		|FROM
		|	Catalog.Warehouses AS CatWarehouses
		|WHERE
		|	NOT &Series = VALUE(Catalog.ItemsBatches.EmptyRef)
		|	AND CatWarehouses.Ref = &Recipient
		|
		|UNION ALL
		|
		|SELECT
		|	&Date																	AS Period,
		|	&Products															AS Products,
		|	&Characteristic															AS Characteristic,
		|	CASE
		|		WHEN &RecordsInWarehouseRegisters
		|			THEN &Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END																	AS Purpose,
		|	GoodsTable.Series														AS Series,
		|	GoodsTable.Count												AS Count,
		|	&Recipient																AS Sender,
		|	&Recipient																AS Recipient,
		|	VALUE(Enum.WarehouseTransactions.ProductReceivingFromManufacturing)	AS WarehouseOperation,
		|	&Ref																	AS Document,
		|	NOT CatWarehouses.UseWarehouseManagemantSystemForGoodsReceipt
		|		OR &Date < CatWarehouses.StartDateOfWarehouseManagemantSystemForGoodsReceipt			AS ThisIsWarehouseRecord
		|FROM
		|	Document.RecyclableWasteAllocation.SetOfSeries AS GoodsTable
		|		INNER JOIN Document.RecyclableWasteAllocation AS Header
		|		ON GoodsTable.Ref = Header.Ref
		|			AND GoodsTable.Products = Header.Products
		|		INNER JOIN Catalog.Warehouses AS CatWarehouses
		|		ON (CatWarehouses.Ref = &Recipient)
		|WHERE
		|	GoodsTable.Ref = &Ref
		|	AND NOT GoodsTable.Series = VALUE(Catalog.ItemsBatches.EmptyRef)";

	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	// the arrival of returnable waste in the pantry
	"SELECT DISTINCT
	|	&Date										AS DateOfReceipt,
	|	&Products								AS Products,
	|	&Characteristic								AS Characteristic,
	|	&Series										AS Series,
	|	&Purpose									AS Purpose,
	|	InventoryKinds.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef)	AS CCDNumber
	|FROM
	|	Document.RecyclableWasteAllocation.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON InventoryKinds.InventoryOwnerAttribute = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND &Products = UninvoicedReceipts.Products
	|			AND &Characteristic = UninvoicedReceipts.Characteristic
	|			AND &Series = UninvoicedReceipts.Series
	|			AND &Purpose = UninvoicedReceipts.Purpose
	|			AND (UninvoicedReceipts.CCDNumber = VALUE(Catalog.CCDNumbers.EmptyRef))
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND (UninvoicedReceipts.InventoryOwnerAttribute IS NULL 
	|			OR UninvoicedReceipts.DateOfReceipt < &Date)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref						AS Ref,
	|	UNDEFINED				AS RecordSeparator,
	|	&Date						AS IBDocumentDate,
	|	&Number						AS IBDocumentNumber,
	|	&MetadataIdentifier	AS RefType,
	|	&Organization				AS Organization,
	|	VALUE(Enum.BusinessTransactions.ProductsRelease) AS BusinessOperation,
	|	&LineOfBusiness	AS LineOfBusiness,
	|	&Department				AS Department,
	|	&EmployeeResponsible				AS EmployeeResponsible,
	|	&Author						AS Author,
	|	&Comment				AS Comment,
	|	0							AS Sum,
	|	&Posted					AS Posted,
	|	&DeletionMark			AS DeletionMark,
	|	FALSE						AS AdditionalRecord,
	|	""""						AS More,
	|	&Date						AS SourceDocumentDate,
	|	&NumberForPrinting				AS SourceDocumentNumber,
	|	&Department				AS StorageLocation,
	|	&Date						AS RecordingInAccountingDate,
	|	UNDEFINED                AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = 
	"SELECT
	|	""OtherExpenses"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	CAST(DocumentTable.Ref.Price * DocumentTable.Count AS NUMBER(31, 2)) AS AmountExcludingVAT,
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
	|	Document.RecyclableWasteAllocation.OtherExpenses AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	AdditionalFields = "";
	CalculationOfCostLocalization.AddAdditionalFieldsByAIT(AdditionalFields);
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(AdditionalFields+",VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
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
	
	QueryText =
	"SELECT
	|	&Date																			AS Period,
	|	VALUE(AccumulationRecordType.Receipt)											AS RecordType,
	|	&Organization																	AS Organization,
	|	InventoryKinds.Department														AS Department,
	|	&LineOfBusiness 														AS LineOfBusiness,
	|	InventoryKinds.ExpenseItem														AS AssetRef,
	|	CASE
	|		WHEN InventoryKinds.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.AssetsLiabilitiesDimension
	|	END 																			AS Dimension,
	|	CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))	AS Sum
	|FROM
	|	Document.RecyclableWasteAllocation.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND VALUETYPE(InventoryKinds.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND NOT InventoryKinds.ExpenseItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|";
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date AS Period,
	|	&Organization AS Organization,
	|	InventoryKinds.Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	InventoryKinds.ExpenseItem AS AssetRef,
	|	InventoryKinds.AssetsLiabilitiesDimension AS Dimension,
	|	InventoryKinds.GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SumMan,
	|	CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|
	|	InventoryKinds.FinRecordID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|FROM
	|	Document.RecyclableWasteAllocation.InventoryKinds AS InventoryKinds
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|	AND VALUETYPE(InventoryKinds.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|	AND NOT InventoryKinds.ExpenseItem = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ScheduleGoodsReceipt(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref 				AS Ref,
	|	DataSource.Ref               AS Invoice,
	|	FALSE                                AS Patch,
	|	UNDEFINED                        AS CorrectedDocument,
	|	UNDEFINED	      				AS OrderDocument,
	|	UNDEFINED               			AS Contract,
	|	UNDEFINED             			AS Terms,
	|	VALUE(Enum.GoodsReceiptOptions.SplitByInvoicesOnly) AS GoodsReceiptOption,
	|	
	|	CASE WHEN DataSource.DateOfReceipt <> DATETIME(1, 1, 1) THEN
	|				DataSource.DateOfReceipt
	|			ELSE
	|				DataSource.Date
	|		END AS Date,
	|	
	|	DataSource.Products         AS Products,
	|	DataSource.Characteristic       AS Characteristic,
	|	DataSource.Purpose           AS Purpose,
	|	FALSE                                AS ToControlQuality,
	|	FALSE                                AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED                        AS ControlledLotReference,
	|	DataSource.Series                AS Series,
	|	DataSource.BatchesIndicationStatus  AS BatchesIndicationStatus,
	|	FALSE   								AS ExceedingOrder,
	|	DataSource.Recipient           AS Warehouse,
	|	DataSource.Department        AS Sender,
	|	DataSource.Count           AS Count,
	|	TRUE                              AS ThisIsAnInvoice,
	|	FALSE   								AS ReceiptUnderOrders,
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost)  AS BusinessOperation
	|FROM
	|	Document.RecyclableWasteAllocation AS DataSource
	|WHERE
	|	DataSource.Ref IN (&Ref)";
	
	WarehousesServer.ScheduleGoodsReceipt(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		// Arrival at an irregular warehouse or for old purposes.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.RecyclableWasteAllocation AS TabPart
		|WHERE
		|	NOT TabPart.Recipient REFS Catalog.Warehouses
		|	OR NOT TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	OR TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt > TabPart.Ref.Date
		|	OR TabPart.Purpose.RecordsInWarehouseRegisters = FALSE";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		// The reverse of the receipt order for the old appointments.
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	-TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.RecyclableWasteAllocation AS TabPart
		|WHERE
		|	TabPart.Purpose.RecordsInWarehouseRegisters = FALSE
		|	AND TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Recipient AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TabPart.Ref AS OrderDocument,
		|	TabPart.Date AS DateOfReceipt,
		|	TRUE AS AvailableForConsumption,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule,
		|	0 AS QuantityInGraph
		|FROM
		|	Document.RecyclableWasteAllocation AS TabPart
		|WHERE
		|	TabPart.Recipient.UseWarehouseManagemantSystemForGoodsReceipt
		|	AND TabPart.Recipient.StartDateOfWarehouseManagemantSystemForGoodsReceipt <= TabPart.Ref.Date";
	
	StockAllocationRecords.ScheduleStockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("ConversionRateToManCurrency");
	AdditionalParameters.Add("FactorOfConversionToCurrencyOfRegul");
	
	If Query <> Undefined Then
		SetRequestParametersCurrencyCoefficients(Query);
		InitializeProductAnalysisKeys(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	
	If Query <> Undefined Then
		// There are no additional tables.
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	// There are Registered Recorded movements to reflect the return waste in the warehouse.
	#Region InternalReceipt_ItemReceiptAtWarehouse
	
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
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(AnalyticsByRecipient.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN AnalyticsByRecipient.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 								  AS Count,
	|	UNDEFINED 																		  AS RowID,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS Cost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostExcludingVAT,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS LocalCost,
	|	0                                   				 								  AS VATLocal,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostMan,
	|	0 													 								  AS VATManag,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|		 AND CatWarehouses.ShopFloorStockroom
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCostLocal,
	|	0													 								  AS AddExpensesForGoods,
	|	0													 								  AS AdditionalExpensesExcludingVAT,
	|	0																					  AS AddExpensesLocal,
	|	0																					  AS AddExpensesMan,
	|	CASE
	|		WHEN ISNULL(TableTypesOfStocks_.ExpenseItem.EnteredInTaxAccounting, TRUE)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN 0
	|		ELSE CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END																				  AS PermanentDifference,
	|
	|	0 													 								  AS CostTD,
	|	0													 								  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	(CASE
	|		WHEN NOT CatWarehouses.ShopFloorStockroom
	|			THEN VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)
	|		ELSE VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) END) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID  	 					  						  AS FinRecordID,
	|	(CASE
	|		WHEN NOT CatWarehouses.ShopFloorStockroom
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) END) AS BusinessTransactionSetting
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.InventoryKinds AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = TableTypesOfStocks_.ItemsLocationAttributes
	|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = AnalyticsByRecipient.StorageLocation
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	// There are Registered Records for the reflection of return waste in the division (when released to the wholesale warehouse).
	#Region InternalReceipt_ItemReceiptToDivision
	
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
	|	DimensionByBusinessUnit.DimensionKey			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(AnalyticsByRecipient.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN AnalyticsByRecipient.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 								  AS Count,
	|	UNDEFINED 																		  AS RowID,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS Cost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostExcludingVAT,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS LocalCost,
	|	0                                   				 								  AS VATLocal,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostMan,
	|	0 													 								  AS VATManag,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCost,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCostLocal,
	|	0													 								  AS AddExpensesForGoods,
	|	0													 								  AS AdditionalExpensesExcludingVAT,
	|	0																					  AS AddExpensesLocal,
	|	0																					  AS AddExpensesMan,
	|	CASE
	|		WHEN ISNULL(TableTypesOfStocks_.ExpenseItem.EnteredInTaxAccounting, TRUE)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN 0
	|		ELSE CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END																				  AS PermanentDifference,
	|
	|	0 													 								  AS CostTD,
	|	0													 								  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID  	 					  						  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.Supplement)										  AS EntryType
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.InventoryKinds AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = TableTypesOfStocks_.ItemsLocationAttributes
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|			ON CatWarehouses.Ref = AnalyticsByRecipient.StorageLocation
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnit
	|			ON AnalyticsByRecipient.Products = DimensionByBusinessUnit.Products
	|			AND AnalyticsByRecipient.Characteristic = DimensionByBusinessUnit.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionByBusinessUnit.Series
	|			AND &Department = DimensionByBusinessUnit.StorageLocation
	|			AND AnalyticsByRecipient.Purpose = DimensionByBusinessUnit.Purpose
	|			AND AnalyticsByRecipient.ProductCostElement = DimensionByBusinessUnit.ProductCostElement
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT CatWarehouses.ShopFloorStockroom
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	// There are Registered Records for write-offs from the division (when released to a wholesale warehouse).
	#Region WriteOffToOtherBatches_ItemTransferToWarehouse
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	DimensionByBusinessUnit.DimensionKey			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(AnalyticsByRecipient.Purpose.VATActivityType,VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN AnalyticsByRecipient.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 									AS LotVendorAttributes,
	|
	// Corresponding fields
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS CorInventoryOwnerAttribute,
	|	UNDEFINED									AS CorCompany,
	|	DocumentTable.Ref							AS CorLot,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count AS Count,
	|
	// Other fields
	|	UNDEFINED 																		AS RowID,
	|	TableTypesOfStocks_.FinRecordID  	 					  					AS FinRecordID,
	|	VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction)		AS BusinessOperation,
	|	VALUE(Catalog.BusinessTransactionsSettings.TransferOfProductsFromProduction)	AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.Supplement)									AS EntryType,
	|	DocumentTable.Ref	AS DocumentRegisterRecords
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.InventoryKinds AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = TableTypesOfStocks_.ItemsLocationAttributes
	|	LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON CatWarehouses.Ref = AnalyticsByRecipient.StorageLocation
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByBusinessUnit
	|		ON AnalyticsByRecipient.Products = DimensionByBusinessUnit.Products
	|		AND AnalyticsByRecipient.Characteristic = DimensionByBusinessUnit.Characteristic
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = DimensionByBusinessUnit.Series
	|		AND &Department = DimensionByBusinessUnit.StorageLocation
	|		AND AnalyticsByRecipient.Purpose = DimensionByBusinessUnit.Purpose
	|		AND AnalyticsByRecipient.ProductCostElement = DimensionByBusinessUnit.ProductCostElement
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT CatWarehouses.ShopFloorStockroom
	|";

	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExpensesToOtherProductionLots,
		QueryText);

	#EndRegion

	#Region InternalReceipt_Goods_ByBatchOfProduction
	
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
	|	AnalysisOfProductsByParty.DimensionKey		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ProductionLot			AS Lot,
	|	CatProductionLots.VATActivityType		AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.ItemsLocationAttributes			AS CorItemsLocationAttributes,
	|	UNDEFINED											AS CorInventoryOwnerAttribute,
	|	DocumentTable.Products.AnalyticalGroup	AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	CatProductionLots.ProductsGroup					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 						 								   AS Count,
	|	UNDEFINED 																		   AS RowID,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS Cost,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostExcludingVAT,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS LocalCost,
	|	0                                   				 								  AS VATLocal,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS CostMan,
	|	0 													 								  AS VATManag,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCost,
	|	-(CASE
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider)
	|			THEN CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|		ELSE 0 END)																	  AS OffBalanceCostLocal,
	|	0													 								   AS AddExpensesForGoods,
	|	0													 								   AS AdditionalExpensesExcludingVAT,
	|	0																					   AS AddExpensesLocal,
	|	0																					   AS AddExpensesMan,
	|	0 												 								  	   AS PermanentDifference,
	|	0 													 								   AS CostTD,
	|	0													 								   AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID  	 					  						  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.InventoryKinds AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|		ON CatProductionLots.Ref = TableTypesOfStocks_.ProductionLot
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS AnalyticsByRecipient
	|		ON AnalyticsByRecipient.Ref = TableTypesOfStocks_.ItemsLocationAttributes
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfProductsByParty
	|		ON AnalysisOfProductsByParty.Products = &Products
	|			AND AnalysisOfProductsByParty.Characteristic = &Characteristic
	|			AND AnalysisOfProductsByParty.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND AnalysisOfProductsByParty.StorageLocation = &Department
	|			AND AnalysisOfProductsByParty.Purpose = CatProductionLots.Purpose
	|			AND AnalysisOfProductsByParty.ProductCostElement = TableTypesOfStocks_.ProductCostElement
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_Work
	
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
	|	DocumentTable.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	&QuantityAccordingToRule 						 								  		  	  AS Count,
	|	UNDEFINED 																			  AS RowID,
	|	CAST(&Price * &QuantityAccordingToRule * &ConversionRateToManCurrency AS NUMBER(31,2))  AS Cost,
	|	CAST(&Price * &QuantityAccordingToRule * &ConversionRateToManCurrency AS NUMBER(31,2))  AS CostExcludingVAT,
	|	CAST(&Price * &QuantityAccordingToRule * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|	0                                   				 								  	  AS VATLocal,
	|	CAST(&Price * &QuantityAccordingToRule * &ConversionRateToManCurrency AS NUMBER(31,2))  AS CostMan,
	|	0 													 								  	  AS VATManag,
	|	0 													 								  	  AS OffBalanceCost,
	|	0 													 								  	  AS OffBalanceCostLocal,
	|	0 													 								  	  AS AddExpensesForGoods,
	|	0 													 								  	  AS AdditionalExpensesExcludingVAT,
	|	0 													 								  	  AS AddExpensesLocal,
	|	0 													 								  	  AS AddExpensesMan,
	|	0 													 								  	  AS PermanentDifference,
	|	0 													 								  	  AS CostTD,
	|	0 													 								  	  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  	AS BusinessOperation,
	|	&DocumentID																		AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) 	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND &QuantityAccordingToRule <> 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_Work_ByExpenses
	
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
	|	DocumentTable.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 								  	  			AS Count,
	|	UNDEFINED 																						AS RowID,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))  	AS Cost,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))  	AS CostExcludingVAT,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.ExpenseItem.EnteredInTaxAccounting, TRUE)
	|		THEN CAST(&Price * TableTypesOfStocks_.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END																					  			AS LocalCost,
	|	0                                   				 								  	  			AS VATLocal,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))  	AS CostMan,
	|	0 													 								  	  AS VATManag,
	|	0 													 								  	  AS OffBalanceCost,
	|	0 													 								  	  AS OffBalanceCostLocal,
	|	0 													 								  	  AS AddExpensesForGoods,
	|	0 													 								  	  AS AdditionalExpensesExcludingVAT,
	|	0 													 								  	  AS AddExpensesLocal,
	|	0 													 								  	  AS AddExpensesMan,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.ExpenseItem.EnteredInTaxAccounting, TRUE)
	|		THEN 0
	|		ELSE CAST(&Price * TableTypesOfStocks_.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END																					  AS PermanentDifference,
	|	0 													 								  	  AS CostTD,
	|	0 													 								  	  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   												  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.OtherExpenses AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_Work_ByParty
	
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
	|	DocumentTable.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	DocumentTable.Ref							AS Lot,
	|	CASE
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <>
	|				VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN DocumentTable.ItemsLocationAttributes.Purpose.VATActivityType
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity
	|	END											AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	DocumentTable.Products.AnalyticalGroup	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 								  	  			AS Count,
	|	UNDEFINED 																						AS RowID,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS Cost,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS CostExcludingVAT,
	|	CAST(&Price * TableTypesOfStocks_.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) 	AS LocalCost,
	|	0                                   				 								  	  			AS VATLocal,
	|	CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS CostMan,
	|	0 													 								  	  AS VATManag,
	|	0 													 								  	  AS OffBalanceCost,
	|	0 													 								  	  AS OffBalanceCostLocal,
	|	0 													 								  	  AS AddExpensesForGoods,
	|	0 													 								  	  AS AdditionalExpensesExcludingVAT,
	|	0 													 								  	  AS AddExpensesLocal,
	|	0 													 								  	  AS AddExpensesMan,
	|	0																					  	  AS PermanentDifference,
	|	0 													 								  	  AS CostTD,
	|	0 													 								  	  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   												  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.ProductionLots AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_Work_ByProductionBatch
	
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
	|	AnalysisOfProductsByParty.DimensionKey		AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ProductionLot			AS Lot,
	|	CatProductionLots.VATActivityType		AS VATActivityType,
	|	(CASE
	|		WHEN DocumentTable.ProductionIssueForActivity = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentTable.ProductionIssueForActivity END) AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 	AS LotVendorAttributes,
	|	UNDEFINED	AS LotVendorAttributesCorr,
	|	0				AS RowCode,
	|
	// Corresponding fields
	|	DocumentTable.ItemsLocationAttributes				AS CorItemsLocationAttributes,
	|	UNDEFINED											AS CorInventoryOwnerAttribute,
	|	DocumentTable.Products.AnalyticalGroup	AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED											AS SalesOpportunity,
	|	DocumentTable.Department							AS Department,
	|	UNDEFINED											AS Manager,
	|	CatProductionLots.ProductsGroup					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 						 								  	  			 AS Count,
	|	UNDEFINED 																						 AS RowID,
	|	-CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS Cost,
	|	-CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS CostExcludingVAT,
	|	-CAST(&Price * TableTypesOfStocks_.Count * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))  AS LocalCost,
	|	0                                   				 								  	  			 AS VATLocal,
	|	-CAST(&Price * TableTypesOfStocks_.Count * &ConversionRateToManCurrency AS NUMBER(31,2))   AS CostMan,
	|	0 													 								  	  AS VATManag,
	|	0 													 								  	  AS OffBalanceCost,
	|	0 													 								  	  AS OffBalanceCostLocal,
	|	0 													 								  	  AS AddExpensesForGoods,
	|	0 													 								  	  AS AdditionalExpensesExcludingVAT,
	|	0 													 								  	  AS AddExpensesLocal,
	|	0 													 								  	  AS AddExpensesMan,
	|	0																					  	  AS PermanentDifference,
	|	0 													 								  	  AS CostTD,
	|	0 													 								  	  AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ProductsReleaseFixCost) 		  AS BusinessOperation,
	|	TableTypesOfStocks_.RowID   												  AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ProductsReleaseFixCost) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentTable
	|	INNER JOIN Document.RecyclableWasteAllocation.ProductionLots AS TableTypesOfStocks_
	|		ON DocumentTable.Ref = TableTypesOfStocks_.Ref
	|		INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|			ON CatProductionLots.Ref = TableTypesOfStocks_.ProductionLot
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfProductsByParty
	|			ON &Products = AnalysisOfProductsByParty.Products
	|			AND &Characteristic = AnalysisOfProductsByParty.Characteristic
	|			AND AnalysisOfProductsByParty.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND &Department = AnalysisOfProductsByParty.StorageLocation
	|			AND AnalysisOfProductsByParty.Purpose = CatProductionLots.Purpose
	|			AND TableTypesOfStocks_.ProductCostElement = AnalysisOfProductsByParty.ProductCostElement
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ItemsLocationAttributes.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.RecyclableWasteAllocation";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		RequestHasSource = False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Print

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
		
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"Invoice",
			NStr("vi = 'Xuất xưởng thành phẩm';
				|ru = 'Выпуск продукции';
				|en = 'Product release'; fa = 'تولید محصول';
				|it = 'Emissione di prodotti';
				|pl = 'Wyprodukowanie';
				|tr = 'Ürün sürümü'"),
			FormPrintedFormOfInvoice(ObjectsArray, PrintObjects));
		
	EndIf;
	
EndProcedure

Function FormPrintedFormOfInvoice(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	
	Template = PrintManagement.PrintFormTemplate("Document.MovementOfProductsAndMaterials.PF_MXL_Invoice");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.Number						AS Number,
	|	DocumentData.Date						AS Date,
	|	DocumentData.Organization					AS Organization,
	|	DocumentData.Organization.Prefix			AS Prefix,
	|	1											AS LineNumber,
	|	DocumentData.Products				AS Products,
	|	DocumentData.Characteristic				AS Characteristic,
	|	CASE
	|		WHEN ISNULL(DocumentData.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN DocumentData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END										AS Purpose,
	|	DocumentData.Recipient					AS Warehouse,
	|	DocumentData.Department				AS Department,
	|	DocumentData.Count					AS Count,
	|	DocumentData.Series						AS Series
	|INTO TTProducts_1
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND NOT DocumentData.BatchesIndicationStatus IN (4, 6, 8, 10)
	|	AND DocumentData.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(DocumentData.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT DocumentData.Recipient.ShopFloorStockroom
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref						AS Ref,
	|	DocumentData.Number						AS Number,
	|	DocumentData.Date						AS Date,
	|	DocumentData.Organization					AS Organization,
	|	DocumentData.Organization.Prefix			AS Prefix,
	|	1											AS LineNumber,
	|	DocumentData.Products				AS Products,
	|	DocumentData.Characteristic				AS Characteristic,
	|	CASE
	|		WHEN ISNULL(DocumentData.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN DocumentData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END										AS Purpose,
	|	DocumentData.Recipient					AS Warehouse,
	|	DocumentData.Department				AS Department,
	|	DocumentData.Count					AS Count,
	|	SeriesTable.Series							AS Series
	|FROM
	|	Document.RecyclableWasteAllocation.SetOfSeries AS SeriesTable
	|		INNER JOIN Document.RecyclableWasteAllocation AS DocumentData
	|		ON SeriesTable.Ref = DocumentData.Ref
	|WHERE
	|	SeriesTable.Ref IN(&DocumentsArray)
	|	AND DocumentData.BatchesIndicationStatus IN (4, 6, 8, 10)
	|	AND SeriesTable.Count <> 0
	|	AND DocumentData.Products.ItemsType IN (
	|					VALUE(Enum.ItemsTypes.OwnGoods),
	|					VALUE(Enum.ItemsTypes.ReusablePackage))
	|	AND VALUETYPE(DocumentData.Recipient) = TYPE(Catalog.Warehouses)
	|	AND NOT DocumentData.Recipient.ShopFloorStockroom
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.Ref				AS Ref,
	|	GoodsTable.Number					AS Number,
	|	GoodsTable.Date					AS Date,
	|	GoodsTable.Organization			AS Organization,
	|	GoodsTable.Organization.Prefix	AS Prefix,
	|	GoodsTable.Products,
	//|TT Table Items.Products." + ?(Code column = "", "Code", Code column) + " AS A CodArticle,
	|	GoodsTable.Products.DescriptionFull AS Products,
	|	GoodsTable.Products.DescriptionFull AS ProductItemName,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Characteristic.Description AS CharacteristicName,
	|	GoodsTable.Series.Description AS SeriesName_,
	|	GoodsTable.Products.UnitOfMeasure.Description AS UnitOfMeasure,
	|	GoodsTable.Count AS Count,
	|	VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction) AS DirectionOfProductionIssue,
	|	GoodsTable.Warehouse.Description AS RecipientPresentation1,
	|	GoodsTable.Department.Description AS DivisionRepresentation
	|FROM
	|	TTProducts_1 AS GoodsTable
	|
	|ORDER BY
	|	GoodsTable.Ref,
	|	GoodsTable.LineNumber
	|TOTALS
	|	MAX(Number),
	|	MAX(Date),
	|	MAX(Organization),
	|	MAX(RecipientPresentation1),
	|	MAX(DivisionRepresentation),
	|	MAX(Prefix)
	|BY
	|	Ref";

	Query.SetParameter("DocumentsArray",           ObjectsArray);
	Query.SetParameter("RecipientTypeWarehouse",         NStr("vi = 'Kho bãi';
																|ru = 'Склад';
																|en = 'Warehouse'; fa = 'Warehouse';
																|it = 'Magazzino';
																|pl = 'Magazyn';
																|tr = 'Ambar'"));
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.LeftMargin = 5;
	SpreadsheetDocument.RightMargin = 5;
	SpreadsheetDocument.HeaderSize = 0;
	SpreadsheetDocument.FooterSize = 0;
	SpreadsheetDocument.FitToPage = True;
	SpreadsheetDocument.PageOrientation = PageOrientation.Landscape;
	
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_ProductsRelease_Invoice";
	
	ResultsArray		= Query.ExecuteBatch();
	SelectionByDocuments 	= ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While SelectionByDocuments.Next() Do
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		PageNumber = 1;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We output the general details of the header
		TemplateArea = Template.GetArea("Header");
		TemplateArea.Parameters.Fill(SelectionByDocuments);
		TemplateArea.Parameters.TypeRecipient = NStr("vi = 'Kho bãi';
													|ru = 'Склад';
													|en = 'Warehouse'; fa = 'Warehouse';
													|it = 'Magazzino';
													|pl = 'Magazyn';
													|tr = 'Ambar'", Common.DefaultLanguageCode());
		
		TitleText = TMCommonUseClientServer.GenerateDocumentTitle(SelectionByDocuments, NStr("vi = 'Xuất xưởng thành phẩm';
																							|ru = 'Выпуск продукции';
																							|en = 'Product release'; fa = 'تولید محصول';
																							|it = 'Emissione di prodotti';
																							|pl = 'Wyprodukowanie';
																							|tr = 'Ürün sürümü'", Common.DefaultLanguageCode()));
		TemplateArea.Parameters.TitleText = TitleText;
		
		CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(SelectionByDocuments.Organization, SelectionByDocuments.Date);
		TemplateArea.Parameters.RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation);
		
		SpreadsheetDocument.Put(TemplateArea);
		
		// Creating an array to check the output
		ArrayOfOutputAreas = New Array;
		
		// We output the multiline part of the document
		TableHeaderArea = Template.GetArea(?(ColumnOfCodes = "", "TabHeader", "TabHeaderWithCode"));
		TemplateArea           = Template.GetArea(?(ColumnOfCodes = "", "String",       "StringWithCode"));
		BasementArea_          = Template.GetArea("Footer");
		
		LineProducts_ = SelectionByDocuments.Select();
		RowsCount = LineProducts_.Count();
		LineNumber = 0;
		ProductLineParameters = New Structure("LineNumber,ProductItemName");
		While LineProducts_.Next() Do
			
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			LineNumber = LineNumber + 1;
			
			ProductLineParameters.LineNumber = LineNumber;
			ProductLineParameters.ProductItemName = ProductsClientServer.PresentationOfProductsForPrinting(
															LineProducts_.ProductItemName, 
															LineProducts_.CharacteristicName,,
															LineProducts_.SeriesName_,
															AdditionalParametersProductPresentation);
															
			TemplateArea.Parameters.Fill(LineProducts_);
			TemplateArea.Parameters.Fill(ProductLineParameters);
			
			If LineNumber = 1 Then
				
				TableHeaderArea.Parameters.PageNumber = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Trang %1';
						|ru = 'Страница %1';
						|en = 'Page %1'; fa = 'Page %1';
						|it = 'Pagina %1';
						|pl = 'Strona %1';
						|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber); 
				SpreadsheetDocument.Put(TableHeaderArea);
				
			Else
				
				ArrayOfOutputAreas.Clear();
				ArrayOfOutputAreas.Add(TemplateArea);
				
				If LineNumber = RowsCount Then
					
					ArrayOfOutputAreas.Add(BasementArea_);
					
				EndIf;
				
				If LineNumber <> 1 And Not SpreadsheetDocument.CheckPut(ArrayOfOutputAreas) Then
					
					PageNumber = PageNumber + 1;
					SpreadsheetDocument.PutHorizontalPageBreak();
					TableHeaderArea.Parameters.PageNumber = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = 'Trang %1';
							|ru = 'Страница %1';
							|en = 'Page %1'; fa = 'Page %1';
							|it = 'Pagina %1';
							|pl = 'Strona %1';
							|tr = 'Sayfa %1'", Common.DefaultLanguageCode()), PageNumber);
					SpreadsheetDocument.Put(TableHeaderArea);
					
				EndIf;
				
			EndIf;
			
			SpreadsheetDocument.Put(TemplateArea);
			
		EndDo;
		
		// Output the document's basement
		BasementArea_.Parameters.TotalString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Tổng số mục %1';
				|ru = 'Всего наименований %1';
				|en = 'Total items %1'; fa = 'Total items %1';
				|it = 'Totale articoli %1';
				|pl = 'Razem pozycji %1';
				|tr = 'Toplam tanım %1'", Common.DefaultLanguageCode()), LineProducts_.Count());
		
		SpreadsheetDocument.Put(BasementArea_);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	Return SpreadsheetDocument;
	
EndFunction

// Returns the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting
// (placing) products.
//
// Returns:
//	String - the text of the request for information about the contents of the tabular parts of the document for printing the Task for selecting (placing) goods.
//
Function TextOfGoodsRequestDocumentForPrintingTaskForSelectingPlacingGoods() Export
	
	RequestText_1 =
	"SELECT
	|	DocumentData.Ref			AS Ref,
	|	1								AS LineNumber,
	|	DocumentData.Recipient		AS Warehouse,
	|	&Premise						AS Premise,
	|	DocumentData.Products	AS Products,
	|	DocumentData.Characteristic	AS Characteristic,
	|	DocumentData.Series			AS Series
	|INTO DocumentGoods
	|FROM
	|	Document.RecyclableWasteAllocation AS DocumentData
	|		INNER JOIN Catalog.Products AS Goods
	|		ON DocumentData.Products = Goods.Ref
	|
	|WHERE
	|	DocumentData.Ref IN(&ObjectsArray)
	|	AND NOT Goods.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	RequestText_1 = StrReplace(RequestText_1, "&Premise", "VALUE(Catalog.Warerooms.EmptyRef)");
	
	Return RequestText_1;
	
EndFunction

#EndRegion

#Region Assignments

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Purpose");
	Return FormTemplate;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
