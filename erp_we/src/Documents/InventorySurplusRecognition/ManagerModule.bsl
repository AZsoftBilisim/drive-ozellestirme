#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization, Department, Warehouse");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IncomeItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "IncomeItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "IncomeItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfRevenue", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	InventorySurplusRecognitionLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
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
	
	If TypeOf(Document) = Type("DocumentObject.InventorySurplusRecognition") Then
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
		
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		// Execution of the request and unloading of the received tables for movements.
		InventorySurplusRecognitionLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.InventorySurplusRecognition);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
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

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	InventorySurplusRecognitionLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "posting surplus goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.InventorySurplusRecognition) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.InventorySurplusRecognition.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.InventorySurplusRecognition);
		CreateBasedOnCommand.WriteMode = "Post";
		
	

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
	
	InventorySurplusRecognitionLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.InventorySurplusRecognition - link to the document.
//
// Returns:
//	Structure - details of domestic consumption of goods.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization
	|FROM
	|	Document.InventorySurplusRecognition AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
	Else
		Date = Date(1,1,1);
		Organization = Undefined;
	EndIf;
	
	AttributesStructure1 = New Structure("Date, Organization",
		Date,
		Organization,);
	
	Return AttributesStructure1;

EndFunction

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Warehouse,Date";
	
	Return AttributesNames;
EndFunction

// Returns parameters for specifying series for the products specified in the document.
//
// Parameters:
//  Object	 - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.InventorySurplusRecognition";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;            
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = True;
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
	|	Goods.Products,
	|	Goods.Characteristic,
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
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
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

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return InventorySurplusRecognitionLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - the text of the request for additional temporary tables required for reflection in the regulated accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return InventorySurplusRecognitionLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// Needs for goods in stock.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	Return FormTemplate;
	
EndFunction

// Document parameters for the Attribute filling mechanism are subject to unblocking and data confirmation of the quality
// in the document.
// 
// Parameters:
//  Object - DocumentObject.PurchaseOrder - Object.
// 
// Returns:
//  Structure - structure with fields:
//   * FillInUnblockableDateOfQualityConfirmation - See QualityControl.New_ActionParameters
//   * Key - String - An identifier used when there are two or more data sources to fill in in the same object. 
Function QualityControlActionParameters(Object) Export
	
	Action_Parameters = New Structure();
	Action_Parameters.Insert("Key", "");
	
	ActionName = "FillInUnblockableDateOfQualityConfirmation";
	
	UseAdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	
	ActionParameters = QualityControl.New_ActionParameters(ActionName);
	ActionParameters.QueryOptions.QualityControlDateOfUnblockingIfThereIsNoDateOfReceiptOfLotReference = DateOfReceipt;
	ActionParameters.QueryOptions.QualityControlReset = UseAdvancedWarehousing;
	
	Action_Parameters.Insert(ActionName, ActionParameters);
	
	Return Action_Parameters;
	
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
	JobPrintingRules.SurplusesRecord		= True;
	JobPrintingRules.DocumentCorrectionsAreUsed = True;
	
	Return JobPrintingRules;
	
EndFunction

#EndRegion

// Returns the parameters of the selection of articles and analyst.
//
// Returns:
//	Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//             .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date                     AS Period,
	|	DocumentData.Number                    AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.Currency AS Currency,
	|	ISNULL(DocumentData.Warehouse.ShopFloorStockroom, FALSE) AS ShopFloorStockroom,
	|	DocumentData.Department AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	DocumentData.IncomeItem AS IncomeItem,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.Patch              AS Patch,
	|	DocumentData.ReversedDocument     AS ReversedDocument,
	|	DocumentData.CorrectedDocument     AS CorrectedDocument,
	|	DocumentData.Posted                 AS Posted
	|FROM
	|	Document.InventorySurplusRecognition AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	Attributes = Query.Execute().Select();
	Attributes.Next();
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	Query.SetParameter("Period",                                  Attributes.Period);
	Query.SetParameter("Number",                                   Attributes.Number);
	Query.SetParameter("AdjustmentPeriod_",                     Attributes.AdjustmentPeriod_);
	Query.SetParameter("Warehouse",                                   Attributes.Warehouse);
	Query.SetParameter("ShopFloorStockroom",                         Attributes.ShopFloorStockroom);
	Query.SetParameter("InventoryType",                              Attributes.InventoryType);
	Query.SetParameter("Organization",                             Attributes.Organization);
	Query.SetParameter("IncomeItem",                           Attributes.IncomeItem);
	Query.SetParameter("DimensionOfRevenue",                        Attributes.DimensionOfRevenue);
	Query.SetParameter("Department",                           Attributes.Department);
	Query.SetParameter("BusinessOperation",                   Enums.BusinessTransactions.GoodsRecordingAsReceived);
	Query.SetParameter("BusinessTransactionSetting",          Catalogs.BusinessTransactionsSettings.GoodsRecordingAsReceived);
	Query.SetParameter("Currency",                                  Attributes.Currency);
	Query.SetParameter("LocalAccountingCurrency",          Attributes.LocalAccountingCurrency);
	Query.SetParameter("UseWarehouseManagemantSystemForGoodsSurplusesShortages", Attributes.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	
	Query.SetParameter("EmployeeResponsible",                           Attributes.EmployeeResponsible);
	Query.SetParameter("Author",                                   Attributes.Author);
	Query.SetParameter("Comment",                             Attributes.Comment);
	Query.SetParameter("DeletionMark",                         Attributes.DeletionMark);
	Query.SetParameter("Posted",                                Attributes.Posted);
	Query.SetParameter("OptionOfAssignedAccountingOfGoods",        Attributes.OptionOfAssignedAccountingOfGoods);
	Query.SetParameter("NumberForPrinting", 							 ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("TaxationOfOrganization",				 AccountingParametersForOrganization.BasicTaxationVATSales);
	
	Query.SetParameter("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
		Attributes.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(
		"Document.InventorySurplusRecognition"));
	Query.SetParameter("Patch",                             Attributes.Patch);
	Query.SetParameter("ReversedDocument",                    Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",                    Attributes.CorrectedDocument);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
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
	|	Document.InventorySurplusRecognition.Goods AS GoodsTable
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = Dimension.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|		AND &EmptyAssignment = Dimension.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
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

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.InventorySurplusRecognition.Name,
		"Goods");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Goods"" 									AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	UNDEFINED								AS Vendor,
	|	UNDEFINED								AS Counterparty,
	|	UNDEFINED 								AS VATRate,
	|	UNDEFINED								AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods)	AS AssetTaxClass,
	|	LineCodes.RowCode							AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS DocumentTable
	|	INNER JOIN Document.InventorySurplusRecognition AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

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
	|	&Warehouse AS Warehouse,
	|	&ShopFloorStockroom AS ShopFloorStockroom,
	|	GoodsTable.Ref.IncomeItem AS IncomeItem,
	|	GoodsTable.RowID AS RowID
	|INTO TTTableProducts
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS GoodsTable
	|	LEFT JOIN  InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON GoodsTable.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= GoodsTable.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText = " 
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	GoodsTable.Purpose.LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	CAST(GoodsTable.Sum * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	(CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.Sum * &ConversionRateToManCurrency
	|		ELSE 0 END) AS SumMan,
	|	(CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN GoodsTable.Sum * &FactorOfConversionToCurrencyOfRegul
	|		ELSE 0 END) AS SumCompl,
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|";
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = " 
	|SELECT
	|	SeriesTable.Products AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	SeriesTable.Series AS Series,
	|	SeriesTable.Count AS Count,
	|	&Warehouse AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	&Ref AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS SeriesTable
	|
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
		QueryTextTableTTTableProducts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period AS DateOfReceipt,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series          AS Series,
	|	GoodsTable.Purpose     AS Purpose,
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
	|		AND GoodsTable.Purpose = UninvoicedReceipts.Purpose 
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
	|	GoodsTable.Purpose,
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

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Goods"" AS DataSource,
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
	|	Document.InventorySurplusRecognition.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
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
	|	&Warehouse AS Warehouse,
	|	&InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusinessItems,
	|	&IncomeItem AS IncomeAndExpenseItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|
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
	|	UNDEFINED             AS Partner,
	|	UNDEFINED             AS Counterparty,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                    AS LineOfBusiness,
	|	&Warehouse                   AS StorageLocation,
	|	&Department           AS Department,
	|	&EmployeeResponsible           AS EmployeeResponsible,
	|	&Author                   AS Author,
	|	CAST(&Comment AS STRING(100))
	|	                         AS Comment,
	|	&Currency                  AS Currency,
	|	0                        AS Sum,
	|	UNDEFINED             AS Status,
	|	&Posted                AS Posted,
	|	&DeletionMark         AS DeletionMark,
	|	FALSE                     AS AdditionalRecord,
	|	UNDEFINED             AS More,
	|	&Period                  AS SourceDocumentDate,
	|	&NumberForPrinting           AS SourceDocumentNumber,
	|	&Patch             AS ReverseTransactionCorrection,
	|	&ReversedDocument    AS ReversedDocument,
	|	&CorrectedDocument    AS CorrectedDocument,
	|	&Period                  AS RecordingInAccountingDate,
	|	UNDEFINED             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	|	Document.InventorySurplusRecognition AS DocumentData
	|		LEFT JOIN Document.InventorySurplusRecognition.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.InventorySurplusRecognition";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.GoodsRecordingAsReceived);
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName%kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
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

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.InventorySurplusRecognition.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
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
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	CASE WHEN NOT &Patch
	|		THEN DocumentTable.Ref
	|		ELSE DocumentTable.CorrectedDocument
	|	END 											AS Lot,
	|	&TaxationOfOrganization						AS VATActivityType,
	|	UNDEFINED									AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 									AS LotVendorAttributesCorr,
	|	0 										AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 						AS SalesOpportunity,
	|	DocumentTable.Department 		AS Department,
	|	UNDEFINED 						AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 		AS Count,
	|	UNDEFINED 				 								AS RowID,
	|	TableTypesOfStocks_.SumMan 						 		AS Cost,
	|	TableTypesOfStocks_.SumMan 						 		AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl 								AS LocalCost,
	|	0                                   				 		AS VATLocal,
	|	TableTypesOfStocks_.SumMan 						 		AS CostMan,
	|	0 													 		AS VATManag,
	|	0 													 		AS OffBalanceCost,
	|	0 													 		AS OffBalanceCostLocal,
	|	0													 		AS AddExpensesForGoods,
	|	0													 		AS AdditionalExpensesExcludingVAT,
	|	0															AS AddExpensesLocal,
	|	0															AS AddExpensesMan,
	|	CASE WHEN TableTypesOfStocks_.IncomeItem.EnteredInTaxAccounting = FALSE
	|		THEN TableTypesOfStocks_.SumCompl
	|		ELSE 0
	|	END 												 		AS PermanentDifference,
	|	0 													 		AS CostTD,
	|	0													 		AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID    	 					  AS FinRecordID,
	|	&BusinessTransactionSetting          						  AS BusinessTransactionSetting
	|
	|FROM
	|	Document.InventorySurplusRecognition AS DocumentTable
	|	INNER JOIN TTTableProducts AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)";
	
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

	// The act of receiving goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "CertificateOfGoodsRecordingAsReceived";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi tăng hàng hóa';
									|ru = 'Акт об оприходовании товаров';
									|en = 'Stock surplus recognition'; fa = 'شناسایی مازاد موجودی';
									|it = 'Atto di registrazione contabile delle merci';
									|pl = 'Protokół o rejestrowaniu towarów';
									|tr = 'Ürünlerin envanter girişi için tutanak'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	// Assignment for the placement of goods
	PrintCommand = DataProcessors.PrintJobsForInventoryPickingPlacementAndRecount.AddPrintCommand(PrintCommands,
																							"PlacementJob");
	PrintCommand.AdditionalParameters.Insert("NoExtraCharge");
	
	InventorySurplusRecognitionLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "CertificateOfGoodsRecordingAsReceived") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "CertificateOfGoodsRecordingAsReceived",
				NStr("vi = 'Biên bản ghi tăng hàng hóa';
					|ru = 'Акт об оприходовании товаров';
					|en = 'Stock surplus recognition'; fa = 'شناسایی مازاد موجودی';
					|it = 'Atto di registrazione contabile delle merci';
					|pl = 'Protokół o rejestrowaniu towarów';
					|tr = 'Ürünlerin envanter girişi için tutanak'"),
				PrintingOfActOnRegistrationOfGoods(ObjectsArray, PrintObjects));

	EndIf;
	InventorySurplusRecognitionLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function PrintingOfActOnRegistrationOfGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(NameOfCodeColumn);

	Query = New Query;
	Query.Text =
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.Number AS Number,
	|	Document.Date AS Date,
	|	Document.CorrectedDocument.Number AS NumberOfDocumentBeingCorrected,
	|	Document.CorrectedDocument.Date AS DateOfDocumentBeingCorrected,
	|	Document.Patch AS Patch,
	|	Document.Warehouse AS Warehouse,
	|	Document.Currency AS Currency,
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	PRESENTATION(Document.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(Document.Department) AS DepartmentPresentation,
	|	Document.Organization.Prefix AS Prefix,
	|	Document.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
	|	Document.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition_,
	|	Document.EmployeeResponsible.Individual AS EmployeeResponsible
	|FROM
	|	Document.InventorySurplusRecognition AS Document
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|   Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS Products,
	|	&NameOfCodeColumn AS AdditionalColumn,
	|	GoodsTable.Products.DescriptionFull AS ProductsPresentation,
	|	GoodsTable.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	PRESENTATION(GoodsTable.Series) AS SeriesPresentation,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure) AS UnitOfMeasurePresentation,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Price AS Price,
	|	GoodsTable.Sum AS Sum,
	|	GoodsTable.Ref AS Ref
	|FROM
	|	Document.InventorySurplusRecognition.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";

	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&NameOfCodeColumn", "GoodsTable.Products." +NameOfCodeColumn);
	Else
		Query.Text = StrReplace(Query.Text, "&NameOfCodeColumn AS AdditionalColumn,", "");
	EndIf;

	DocumentAttributes = New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Biên bản ghi tăng hàng hóa';
							|ru = 'Акт об оприходовании товаров';
							|en = 'Stock surplus recognition'; fa = 'شناسایی مازاد موجودی';
							|it = 'Atto di registrazione contabile delle merci';
							|pl = 'Protokół o rejestrowaniu towarów';
							|tr = 'Ürünlerin envanter girişi için tutanak'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PARAMETERS_PRESS_THERegistrationOfSurplusGoods_TheActOfRegisteringSurplusGoods";
	
	Template = PrintManagement.PrintFormTemplate("Document.InventorySurplusRecognition.PF_MXL_CertificateOfGoodsRecordingAsReceived");
	
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	
	ScopeOfApplication_2  = Template.GetArea("Basis");

	AreaOfHeaderNumber = Template.GetArea("TableHeader|LineNumber");
	AreaCodesHeader  = Template.GetArea("TableHeader|ColumnOfCodes");
	ProductAreaHeader  = Template.GetArea("TableHeader|OwnGoods");
	AreaDataHeader = Template.GetArea("TableHeader|Data");

	If Not OutputAdditionalColumn Then

		Template.Area("OwnGoods").ColumnWidth = Template.Area("OwnGoods").ColumnWidth
				+ Template.Area("ColumnOfCodes").ColumnWidth;

	EndIf;

	NumberAreaLine = Template.GetArea("String|LineNumber");
	AreaCodesString  = Template.GetArea("String|ColumnOfCodes");
	ProductLineArea_  = Template.GetArea("String|OwnGoods");
	DataAreaRow = Template.GetArea("String|Data");

	RoomAreaBasementTable = Template.GetArea("TableFooter|LineNumber");
	AreaCodesBasementTables  = Template.GetArea("TableFooter|ColumnOfCodes");
	ProductAreaTableBasement  = Template.GetArea("TableFooter|OwnGoods");
	DataAreaTableBasement = Template.GetArea("TableFooter|Data");

	LabelArea       = Template.GetArea("Signatures");
	RegionAmountInWords = Template.GetArea("AmountInWords");
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResults = Query.ExecuteBatch(); 
	
	DocumentsSelection = QueryResults[0].Select();
	SelectionByTableParts = QueryResults[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	While DocumentsSelection.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;

		// We display the header of the invoice.
		FillPropertyValues(DocumentAttributes, DocumentsSelection);
		HeaderArea_.Parameters.Fill(DocumentsSelection);
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		HeaderDataStructure_1.Insert("WarehousePresentation", WarehousesServer.GetWarehousePresentation(DocumentsSelection.WarehousePresentation));
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		HeaderDataStructure_1.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		HeaderArea_.Parameters.Fill(HeaderDataStructure_1);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);

		// Output of the header.
		TabDocument.Put(AreaOfHeaderNumber);

		If OutputAdditionalColumn Then

			AreaCodesHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
			TabDocument.Join(AreaCodesHeader);

		EndIf;
		TabDocument.Join(ProductAreaHeader);

		TabDocument.Join(AreaDataHeader);

		AmountTotal = 0;
		TotalItems_1 = 0;

		// Output of strings.
		SelectionByTableParts.FindNext(New Structure("Ref",DocumentsSelection.Ref));
		
		SelectionByLines = SelectionByTableParts.Select();
		
		While SelectionByLines.Next() Do

			NumberAreaLine.Parameters.Fill(SelectionByLines);
			TabDocument.Put(NumberAreaLine);

			If OutputAdditionalColumn Then

				AreaCodesString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(AreaCodesString);

			EndIf;

			// Nomenclature.
			ProductLineArea_.Parameters.Products = SelectionByLines.Products;
			ProductLineArea_.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				, // Package
				SelectionByLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			
			TabDocument.Join(ProductLineArea_);
			
			// Data on prices, quantity.
			DataAreaRow.Parameters.Fill(SelectionByLines);
			
			TabDocument.Join(DataAreaRow);

			AmountTotal = AmountTotal + SelectionByLines.Sum;
			TotalItems_1 = TotalItems_1 + 1;

		EndDo;

		// Output of the basement.
		TabDocument.Put(RoomAreaBasementTable);
		If OutputAdditionalColumn Then
			TabDocument.Join(AreaCodesBasementTables);
		EndIf;
		TabDocument.Join(ProductAreaTableBasement);
		TabDocument.Join(DataAreaTableBasement);

		// Withdrawal of the Amount in words.
		RegionAmountInWords.Parameters.AmountInWords = ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountTotal, DocumentsSelection.Currency);
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng %TotalItems_1%, tổng số tiền %AmountTotal% %Currency%';
									|ru = 'Всего наименований %TotalItems_1%, на сумму %AmountTotal% %Currency%';
									|en = 'Total names %TotalItems_1%, in the amount of %AmountTotal% %Currency%'; fa = 'Total names %TotalItems_1%, in the amount of %AmountTotal% %Currency%';
									|it = 'Totale articoli %TotalItems_1%, per un totale di %AmountTotal% %Currency%';
									|pl = 'Razem pozycji %TotalItems_1%, na kwotę %AmountTotal% %Currency%';
									|tr = '%AmountTotal% tutar için, toplam tanım %TotalItems_1% %Currency%'", Common.DefaultLanguageCode());
		
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%AmountTotal%", Format(AmountTotal, "NFD=2"));
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%Currency%", String(DocumentsSelection.Currency));
		
		RegionAmountInWords.Parameters.TotalString = TextOfResultingLine;

		TabDocument.Put(RegionAmountInWords);

		// Output of signatures.
		LabelArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(DocumentsSelection.EmployeeResponsible, ?(DocumentsSelection.Patch, DocumentsSelection.DateOfDocumentBeingCorrected, DocumentsSelection.Date));
		LabelArea.Parameters.Warehouseman = PersonsTM.IndividualShortName(DocumentsSelection.Warehouseman, ?(DocumentsSelection.Patch, DocumentsSelection.DateOfDocumentBeingCorrected, DocumentsSelection.Date));
		LabelArea.Parameters.StorekeeperPosition_ = WarehousesServer.PositionOfResponsiblePersonOfWarehouse(DocumentsSelection.StorekeeperPosition_);
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;

EndFunction

#EndRegion

#Region InfobaseUpdate

#Region Handlers_11_4_1

#EndRegion

#EndRegion

#EndRegion

#EndIf
