#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "Organization, Department, Warehouse, EmployeeResponsible");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.FillInIf.ObjectFieldsAreEmpty = "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "IncomeItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "IncomeItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "IncomeItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "DimensionOfRevenue", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.FillInIf.ObjectFieldsAreEmpty = "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "ExpenseItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ExpenseItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ExpenseItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "DimensionOfExpenses", Parameters);
	
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
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // for the formation of Registered Records for deviations in the cost of goods
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	GoodsMisgradingLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsMisgrading") Then
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
		
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTableDocumentAmountsInLocalCurrency(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		// Execution of the request and unloading of the received tables for movements.
		GoodsMisgradingLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.GoodsMisgrading);
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
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	GoodsMisgradingLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.MisgradingOfGoodsAtCustodian.AddCreateCommandBasedOnReSortingOfGiverSGoods(GenerationCommands);
EndProcedure

// Adds a command to create the "re-Sorting of products" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsMisgrading) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsMisgrading.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsMisgrading);
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
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	GoodsMisgradingLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

#Region SetOfSeries

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
	
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsMisgrading";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.SurplusesRecord);
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.ShortageRecord);
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentGoodsReceipt");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Series",			"BatchReceipt");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusReceipt");
	
	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatus", "Series");
	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatusReceipt",
																					"BatchReceipt");
	
	SeriesSpecificationParameters.SpecialCheckingOfSeriesIndicationStatuses = True;
	
	Return SeriesSpecificationParameters;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//
// Parameters:
//  SeriesSpecificationParameters	 - Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
// Returns:
//  String - Query text
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Series,
	|	Goods.ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived,
	|	Goods.BatchReceipt,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.BatchesIndicationStatusReceipt,
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
	|	Goods.BatchesIndicationStatusReceipt AS OldStatusOfSeriesReference,
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
	|	END AS BatchesIndicationStatus,
	|	CASE
	|		WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy IS NULL 
	|			THEN 0
	|		ELSE CASE
	|				WHEN AccountingPoliciesAndLogging.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN CASE
	|							WHEN Goods.BatchReceipt <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|								THEN 14
	|							ELSE 13
	|						END
	|				ELSE 0
	|			END
	|	END AS BatchesIndicationStatusReceipt
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON (BatchAccountingPolicies.Warehouse = &Warehouse)
	|			AND (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS AccountingPoliciesAndLogging
	|			INNER JOIN Catalog.Warehouses AS WarehousesRegistration
	|			ON AccountingPoliciesAndLogging.Warehouse = WarehousesRegistration.Ref
	|		ON (AccountingPoliciesAndLogging.Warehouse = &Warehouse)
	|			AND (CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind = AccountingPoliciesAndLogging.Ref)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Statuses.LineNumber AS LineNumber,
	|	Statuses.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	Statuses.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt
	|FROM
	|	Statuses AS Statuses
	|WHERE
	|	(Statuses.BatchesIndicationStatus <> Statuses.OldStatusOfSpecifyingSeries
	|			OR Statuses.BatchesIndicationStatusReceipt <> Statuses.OldStatusOfSeriesReference)
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;

EndFunction

// Returns the request text to check whether the series is filled in
//	Parameters:
//		SeriesSpecificationParameters - Structure - the structure of fields is specified in the function Nomenclaturales.Parametrizatsii
//	Returns:
//		String - query text.
//
Function TextOfRequestToCheckSeriesFilling(SeriesSpecificationParameters) Export
	
	QueryText =
	"SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	TableOfSeries.CharacteristicRecordingAsReceived AS CharacteristicRecordingAsReceived,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Series AS Series,
	|	TableOfSeries.Count AS Count,
	|	TableOfSeries.BatchReceipt AS BatchReceipt,
	|	TableOfSeries.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt,
	|	TableOfSeries.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO SeriesPreparatoryTable
	|FROM
	|	&TableOfSeries_QueryNumber AS TableOfSeries
	|WHERE
	|	(TableOfSeries.BatchesIndicationStatus > 0
	|				AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|			OR TableOfSeries.BatchesIndicationStatusReceipt > 0
	|				AND NOT TableOfSeries.BatchesIndicationStatusReceipt IN (&SeriesStatusesYouCanSpecifySeries))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfSeries.LineNumber AS LineNumber,
	|	TableOfSeries.Products AS Products,
	|	TableOfSeries.Characteristic AS Characteristic,
	|	TableOfSeries.Series AS Series,
	|	""Series"" AS FieldNameSeries,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	TableOfSeries.Count AS NumberOfPackages
	|INTO SeriesTableForQuery
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.BatchesIndicationStatus > 0
	|	AND NOT TableOfSeries.BatchesIndicationStatus IN (&SeriesStatusesYouCanSpecifySeries)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfSeries.LineNumber,
	|	TableOfSeries.ProductsRecordingAsReceived,
	|	TableOfSeries.CharacteristicRecordingAsReceived,
	|	TableOfSeries.BatchReceipt,
	|	""BatchReceipt"",
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	TableOfSeries.Count
	|FROM
	|	SeriesPreparatoryTable AS TableOfSeries
	|WHERE
	|	TableOfSeries.BatchesIndicationStatusReceipt > 0
	|	AND NOT TableOfSeries.BatchesIndicationStatusReceipt IN (&SeriesStatusesYouCanSpecifySeries)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SeriesPreparatoryTable";
	
	Return QueryText;
	
EndFunction

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String -query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return GoodsMisgradingLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - the text of the request for additional temporary tables required for reflection in the regulated accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return GoodsMisgradingLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.RecordsInWarehouseRegisters = "TRUE";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
	// The remnants of the goods being written off in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
	// The needs for registered goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.AssignmentGoodsReceipt");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.ProductsRecordingAsReceived";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.CharacteristicRecordingAsReceived";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
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
	
	DateOfReceipt = InvoicesServer.DateOfReceipt(Undefined, Object.Date, True);
	UseAdvancedWarehousing = WarehousesServer.UseWarehouseManagemantSystemForGoodsSurplusesShortages(Object.Warehouse, Object.Date);
	
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
	|	ValueAllowed(Warehouse)
	|	AND ValueAllowed(Organization)
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

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.GoodsMisgrading, DocumentObject.GoodsMisgrading - document re-sorting of goods.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Warehouse, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.GoodsMisgrading") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	FillParameters.MovementOfGoodsInWarehouses = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters of the selection of articles and analyst.
//
// Parameters:
//	TradeGoodsAtCost - Boolean - indicates whether the goods need to be named at cost.
//	Var_FillChecking - Boolean - a sign that the filling of articles is carried out when checking the filling of the document.
//
// Returns:
//	Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//             .
//
Function ItemsAndDimensionsSelectionParameters(TradeGoodsAtCost, Var_FillChecking = False) Export
	
	ArrayOfSelectionParameters = New Array;
	
	AvailabilityByOperation = True;
	
	If Var_FillChecking Then
		AvailabilityByOperation = Not TradeGoodsAtCost;
	ElsIf TradeGoodsAtCost Then
		AvailabilityByOperation = Undefined;
	EndIf;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	
	ChoiceParameters.AvailabilityByOperation               = AvailabilityByOperation;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	
	ChoiceParameters.AvailabilityByOperation               = AvailabilityByOperation;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
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

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Warehouse",  Query.Parameters.Warehouse);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",  Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	GoodsTable.Warehouse          AS Warehouse,
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose     AS Purpose,
	|	GoodsTable.Series          AS Series 
	|FROM (
	|	SELECT
	|		TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|	FROM
	|		Document.GoodsMisgrading.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|	UNION ALL
	|
	|	SELECT
	|		&Warehouse                                     AS Warehouse,
	|		GoodsTable.ProductsRecordingAsReceived    AS Products,
	|		GoodsTable.CharacteristicRecordingAsReceived  AS Characteristic,
	|		GoodsTable.AssignmentGoodsReceipt      AS Purpose,
	|		GoodsTable.BatchReceipt           AS Series
	|	FROM
	|		Document.GoodsMisgrading.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT
	|		&Warehouse                                     AS Warehouse,
	|		GoodsTable.ProductsRecordingAsReceived    AS Products,
	|		GoodsTable.CharacteristicRecordingAsReceived  AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		GoodsTable.BatchReceipt           AS Series
	|	FROM
	|		Document.GoodsMisgrading.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|	UNION ALL
	|
	|	SELECT
	|		GoodsTable.ItemsLocationAttributes.StorageLocation                              AS Warehouse,
	|		GoodsTable.ItemsLocationAttributes.Products                       AS Products,
	|		GoodsTable.ItemsLocationAttributes.Characteristic                     AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		GoodsTable.ItemsLocationAttributes.Series                              AS Series
	|	FROM
	|		Document.GoodsMisgrading.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	) AS GoodsTable
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.Series = Dimension.Series
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("CalculationAnalysisKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS Ref
	|INTO TableTypesOfStocks_
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS TableTypesOfStocks_
	|		INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|		ON CatalogInventoryKinds.Ref = TableTypesOfStocks_.InventoryOwnerAttribute
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND CatalogInventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|INDEX BY
	|	Ref
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT DISTINCT
	|	AnalyticsData.Organization				AS Organization,
	|	AnalyticsData.Partner					AS Partner,
	|	AnalyticsData.Counterparty				AS Counterparty,
	|	AnalyticsData.Contract					AS Contract,
	|	AnalyticsData.LineOfBusiness	AS LineOfBusiness
	|FROM
	|	(SELECT
	|		CatalogInventoryKinds.Organization							AS Organization,
	|		VALUE(Catalog.Partners.OurEnterprise)				AS Partner,
	|		CatalogInventoryKinds.Counterparty							AS Counterparty,
	|		CASE
	|			WHEN CatalogInventoryKinds.Contract = UNDEFINED
	|				THEN VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|			ELSE CatalogInventoryKinds.Contract
	|		END														AS Contract,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)	AS LineOfBusiness
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|			INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|			ON CatalogInventoryKinds.Ref = TableTypesOfStocks_.Ref
	|	WHERE
	|		CatalogInventoryKinds.Counterparty REFS Catalog.Companies
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		CatalogInventoryKinds.Organization							AS Organization,
	|		CatalogInventoryKinds.GoodsOwner						AS Partner,
	|		CatalogInventoryKinds.Counterparty							AS Counterparty,
	|		CASE
	|			WHEN CatalogInventoryKinds.Contract = UNDEFINED
	|				THEN VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			ELSE CatalogInventoryKinds.Contract
	|		END														AS Contract,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef)	AS LineOfBusiness
	|	FROM
	|		TableTypesOfStocks_ AS TableTypesOfStocks_
	|			INNER JOIN Catalog.InventoryKinds AS CatalogInventoryKinds
	|			ON CatalogInventoryKinds.Ref = TableTypesOfStocks_.Ref
	|	WHERE
	|		NOT CatalogInventoryKinds.Counterparty REFS Catalog.Companies
	|	
	|	) AS AnalyticsData
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|			ON AnalysisOfCalculations.Organization = AnalyticsData.Organization
	|			AND AnalysisOfCalculations.Partner = AnalyticsData.Partner
	|			AND AnalysisOfCalculations.Counterparty = AnalyticsData.Counterparty
	|			AND AnalysisOfCalculations.Contract = AnalyticsData.Contract
	|			AND AnalysisOfCalculations.LineOfBusiness = AnalyticsData.LineOfBusiness
	|WHERE
	|	AnalysisOfCalculations.DimensionKey IS NULL";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("CalculationAnalysisKeysInitialized", True);
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Ref            AS Ref,
	|	DocumentData.Date              AS Period,
	|	DocumentData.Number             AS Number,
	|	DocumentData.Warehouse             AS Warehouse,
	|	DocumentData.Currency            AS Currency,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse AS ArrivalAtCost,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.ExpenseItem    AS ExpenseItem,
	|	DocumentData.DimensionOfRevenue  AS DimensionOfRevenue,
	|	DocumentData.IncomeItem     AS IncomeItem,
	|	DocumentData.IncomeItem.EnteredInTaxAccounting AS IncomeItemIsAcceptedForTaxAccounting,
	|	DocumentData.Department     AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef))AS OptionOfAssignedAccountingOfGoods,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DocumentData.VATActivityType AS VATActivityType,
	|	DocumentData.EmployeeResponsible      AS EmployeeResponsible,
	|	DocumentData.Author              AS Author,
	|	DocumentData.Comment        AS Comment,
	|	DocumentData.DeletionMark    AS DeletionMark,
	|	DocumentData.Patch        AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted           AS Posted,
	|	DocumentData.DocumentID AS DocumentID
	|FROM
	|	Document.GoodsMisgrading AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	NameOfBusinessOperationSetting = Common.EnumerationValueName(Attributes.BusinessOperation);
	Query.SetParameter(
		"BusinessTransactionSetting",
		Catalogs.BusinessTransactionsSettings[NameOfBusinessOperationSetting]);
	
	
	Query.SetParameter("UseWarehouseManagemantSystemForGoodsSurplusesShortages", 
		Attributes.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("NumberForPrinting",         ObjectsPrefixesClientServer.NumberForPrinting(
		Attributes.Number));
	Query.SetParameter("MetadataIdentifier", Common.MetadataObjectID(
		"Document.GoodsMisgrading"));
	Query.SetParameter("InventoryTypesOwn", Enums.InventoryTypes.InventoryTypesOwn());
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
		
EndProcedure

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
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.GoodsMisgrading.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.ProductsRecordingAsReceived AS Products,
		|	TabPart.CharacteristicRecordingAsReceived AS Characteristic,
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.AssignmentGoodsReceipt AS Purpose,
		|	TabPart.ControlledLotReference AS ControlledLotReference,
		|	TabPart.ControlledLotReference <> VALUE(Catalog.ControlledLots.EmptyRef) AS ToControlQuality,
		|	TabPart.SubjectToUnlocking AS SubjectToUnlocking,
		|	TabPart.QualityConfirmationDate AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.GoodsMisgrading.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, True);
	
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Ref.Date AS Date,
	|	GoodsTable.Ref.Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose AS Purpose,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Series AS Series,
	|	-GoodsTable.Count AS Count,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref AS Ref,
	|	GoodsTable.Ref.Date AS Date,
	|	GoodsTable.Ref.Warehouse AS Warehouse,
	|	GoodsTable.ProductsRecordingAsReceived AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	GoodsTable.AssignmentGoodsReceipt AS Purpose,
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.BatchReceipt AS Series,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.BatchesIndicationStatusReceipt AS BatchesIndicationStatus
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsTable
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
	
	QueryText =
	"SELECT
	|	GoodsTable.Products   AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                    AS Purpose,
	|	GoodsTable.Series      AS Series,
	|	GoodsTable.Count AS Count,
	|	&Warehouse                   AS Sender,
	|	UNDEFINED             AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)       AS Premise,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	&Ref                  AS Document,
	|	&Period                  AS Period,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages  AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.ProductsRecordingAsReceived AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.AssignmentGoodsReceipt.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.AssignmentGoodsReceipt
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END AS Purpose,
	|	GoodsTable.BatchReceipt AS Series,
	|	GoodsTable.Count AS Count,
	|	UNDEFINED AS Sender,
	|	&Warehouse AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef) AS Premise,
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord) AS WarehouseOperation,
	|	&Ref AS Document,
	|	&Period AS Period,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.BatchReceipt <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
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
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.GoodsMisgrading.Name,
		"InventoryKinds",
		"ItemsLocationAttributesReceipt");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 										 AS TabularSectionName,
	|	DocumentTable.LineNumber 							 AS LineNumber,
	|	UNDEFINED											 AS Vendor,
	|	UNDEFINED											 AS Counterparty,
	|	UNDEFINED 											 AS VATRate,
	|	DocumentData.VATActivityType						 AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) 			 AS AssetTaxClass,
	|	LineCodes.RowCode										 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.GoodsMisgrading AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAnalysisKeys(Query);
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS DimensionWriteOffs,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusinessExpenses,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalyticsForWriteOffsWithoutAssignment,
	|	CommitteeKeys.DimensionKey AS CommitteeProductAnalysis,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS ItemsLocationAttributesReceipt,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS AssignmentGoodsReceipt,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS BatchReceipt,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS LogInAnalytics,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Purpose.LineOfBusiness  AS DirectionOfActivityOfRegistration,
	|	KeysOfRegistrationWithoutAssignment.DimensionKey  AS AnalyticsOfRegistrationWithoutAssignment,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Contract AS Contract,
	|
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt.InventoryType AS InventoryTypeRegistration,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumberRegistration AS CCDNumberRegistration,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableTypesOfStocks_.QuantityByRNPTReceipt AS QuantityByRNPTReceipt,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOffBalanceMan,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalOffBalanceAmount,
	|	
	|	TableTypesOfStocks_.RowID AS RowID
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
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
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS KeysOfRegistrationWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products = KeysOfRegistrationWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic = KeysOfRegistrationWithoutAssignment.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysOfRegistrationWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Series = KeysOfRegistrationWithoutAssignment.Series
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.StorageLocation = KeysOfRegistrationWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysOfRegistrationWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Partner = TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND (AnalysisOfCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|			OR (AnalysisOfCalculations.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.Contract = UNDEFINED))
	|		AND AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND (AnalysisOfIntercampaniCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|			OR (AnalysisOfIntercampaniCalculations.Contract = VALUE(Catalog.IntercompanyContracts.EmptyRef)
	|				AND TableTypesOfStocks_.InventoryOwnerAttribute.Contract = UNDEFINED))
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT DISTINCT
	|	&Period									AS DateOfReceipt,
	|	InventoryKinds.ProductsRecordingAsReceived	AS Products,
	|	InventoryKinds.CharacteristicRecordingAsReceived	AS Characteristic,
	|	InventoryKinds.BatchReceipt			AS Series,
	|	InventoryKinds.AssignmentGoodsReceipt		AS Purpose,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt		AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumberRegistration		AS CCDNumber
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|		LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|		ON InventoryKinds.InventoryOwnerAttributeGoodsReceipt = UninvoicedReceipts.InventoryOwnerAttribute
	|			AND InventoryKinds.ProductsRecordingAsReceived = UninvoicedReceipts.Products
	|			AND InventoryKinds.CharacteristicRecordingAsReceived = UninvoicedReceipts.Characteristic
	|			AND InventoryKinds.BatchReceipt = UninvoicedReceipts.Series
	|			AND InventoryKinds.AssignmentGoodsReceipt = UninvoicedReceipts.Purpose
	|			AND InventoryKinds.CCDNumberRegistration = UninvoicedReceipts.CCDNumber
	|
	|WHERE
	|	UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < &Period
	|
	|ORDER BY
	|	InventoryOwnerAttribute,
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	CCDNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductsOfOrganizations(Query, QueryTexts) Export
		
	TableName = "TTProductsOfOrganizations";
		
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText =
	"SELECT
	|	NestedQuery.Period AS Period,
	|	NestedQuery.RecordType AS RecordType,
	|	NestedQuery.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	NestedQuery.Organization AS Organization,
	|	NestedQuery.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	NestedQuery.CCDNumber AS CCDNumber,
	|	NestedQuery.CCDNumberCCDNumberType AS CCDNumberCCDNumberType,
	|	NestedQuery.BusinessOperation AS BusinessOperation,
	|	NestedQuery.VATTaxation AS VATTaxation,
	|	NestedQuery.ShipmentCompany AS ShipmentCompany,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Characteristic AS Characteristic,
	|	NestedQuery.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	NestedQuery.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	NestedQuery.Primary AS Primary,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.ToRegisterGoodsIssue AS ToRegisterGoodsIssue,
	|	NestedQuery.QuantityByGBRN AS QuantityByGBRN,
	|	NestedQuery.ToRegisterGoodsIssueByProductBatchID AS ToRegisterGoodsIssueByProductBatchID,
	|	RECORDAUTONUMBER() AS RowID
	|INTO TTProductsOfOrganizations
	|FROM
	|	(SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	InventoryKinds.DimensionWriteOffs AS ItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE &Organization
	|	END AS Organization,
	|	CASE
	|		WHEN InventoryKinds.SaleOfAnotherCompanyInventory
	|			THEN InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE InventoryKinds.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber AS CCDNumber,
	|	InventoryKinds.CCDNumber.CCDNumberType AS CCDNumberCCDNumberType,
	|	&BusinessOperation AS BusinessOperation,
	|	&VATActivityType AS VATTaxation,
	|	&Organization AS ShipmentCompany,
	|	InventoryKinds.Products AS Products,
	|	InventoryKinds.Characteristic AS Characteristic,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN InventoryKinds.CommitteeProductAnalysis
	|		ELSE InventoryKinds.LogInAnalytics
	|	END AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.InventoryOwnerAttributeGoodsReceipt
	|	END AS CorInventoryOwnerAttribute,
	|	FALSE AS Primary,
	|	InventoryKinds.Count			AS Count,
	|	0								AS ToRegisterGoodsIssue,
	|	InventoryKinds.QuantityByGBRN	AS QuantityByGBRN,
	|	0								AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                             AS Period,
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	InventoryKinds.ItemsLocationAttributesReceipt AS ItemsLocationAttributes,
	|	&Organization                                        AS Organization,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt                 AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumberRegistration                   AS CCDNumber,
	|	InventoryKinds.CCDNumberRegistration.CCDNumberType      AS CCDNumberCCDNumberType,
	|	&BusinessOperation                              AS BusinessOperation,
	|	UNDEFINED                                        AS VATTaxation,
	|	UNDEFINED                                        AS ShipmentCompany,
	|	LogInAnalytics.Products                 AS Products,
	|	LogInAnalytics.Characteristic               AS Characteristic,
	|	UNDEFINED                                        AS CorItemsLocationAttributes,
	|	UNDEFINED                                        AS CorInventoryOwnerAttribute,
	|	NOT &ArrivalAtCost                           AS Primary,
	|	InventoryKinds.Count                              AS Count,
	|	0                                                   AS ToRegisterGoodsIssue,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE InventoryKinds.QuantityByRNPTReceipt
	|	END                                               AS QuantityByGBRN,
	|	0                                                   AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS InventoryKinds
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS LogInAnalytics
	|		ON InventoryKinds.ItemsLocationAttributesReceipt = LogInAnalytics.DimensionKey
	|
	|WHERE
	|	InventoryKinds.Ref = &Ref) AS NestedQuery
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, TableName);
	
	Return QueryText;
		
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers) Export
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTProductsOfOrganizations", QueryTexts) Then
		QueryTextTTProductsOfOrganizations(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	TTProductsOfOrganizations.Period AS Period,
	|	TTProductsOfOrganizations.RecordType AS RecordType,
	|	TTProductsOfOrganizations.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TTProductsOfOrganizations.Organization AS Organization,
	|	TTProductsOfOrganizations.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TTProductsOfOrganizations.CCDNumber AS CCDNumber,
	|	TTProductsOfOrganizations.BusinessOperation AS BusinessOperation,
	|	TTProductsOfOrganizations.VATTaxation AS VATTaxation,
	|	TTProductsOfOrganizations.ShipmentCompany AS ShipmentCompany,
	|	TTProductsOfOrganizations.Products AS Products,
	|	TTProductsOfOrganizations.Characteristic AS Characteristic,
	|	TTProductsOfOrganizations.CorItemsLocationAttributes AS CorItemsLocationAttributes,
	|	TTProductsOfOrganizations.CorInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	TTProductsOfOrganizations.Primary AS Primary,
	|	TTProductsOfOrganizations.Count AS Count,
	|	TTProductsOfOrganizations.ToRegisterGoodsIssue AS ToRegisterGoodsIssue,
	|	TTProductsOfOrganizations.QuantityByGBRN AS QuantityByGBRN,
	|	TTProductsOfOrganizations.ToRegisterGoodsIssueByProductBatchID AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTProductsOfOrganizations AS TTProductsOfOrganizations";
	
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
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	&Period                                            AS Period,
	|	&Organization                                       AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.CommitteeProductAnalysis  AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Currency                          AS Currency,
	|	TableTypesOfStocks_.CCDNumber                        AS CCDNumber,
	|	0                                                  AS Count,
	|	0                                                  AS RevenueAmount,
	|	0                                                  AS RevenueAmountExclVATLocal,
	|	0                                                  AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count                      AS QuantityConsumed,
	|	0                                                  AS QuantityToRegister,
	|	0                                                  AS QuantityForRegistrationByProductBatchID,
	|	0                                                  AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.Count                      AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN                AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	&BusinessOperation                             AS BusinessOperation,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt         AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.LogInAnalytics          AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.Products                    AS Products,
	|	TableTypesOfStocks_.Characteristic                  AS Characteristic,
	|	TableTypesOfStocks_.RowID             AS FinRecordID,
	|	&BusinessTransactionSetting                    AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID             AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
EndProcedure

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
	|	VALUE(AccumulationRecordType.Receipt)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Organization                                AS Organization,
	|	TableTypesOfStocks_.LogInAnalytics   AS ItemsLocationAttributes,
	|	&Ref                                     AS DocumentInflow,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt  AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.LotVendorAttributes     AS LotVendorAttributes,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumMan  END) AS Cost,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumMan  END) AS CostExcludingVAT,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumCompl END) AS LocalCost,
	|	0. AS VATLocal,
	|
	|	TableTypesOfStocks_.ProductsRecordingAsReceived AS Products,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived AS Characteristic,
	|	&BusinessOperation                      AS BusinessOperation,
	|	TRUE AS Primary,
	|	(CASE WHEN &ArrivalAtCost THEN &Ref ELSE UNDEFINED END) AS DocumentSource
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|WHERE
	|	&BatchAccountingVersion21";
	
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
	|	&Period        AS Period,
	|	CASE WHEN &ArrivalAtCost
	|		THEN &BusinessOperation
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END          AS BusinessOperation,
	|	&Organization   AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionWriteOffs
	|		ELSE InventoryKinds.AnalyticsForWriteOffsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	InventoryKinds.LineOfBusinessExpenses AS LineOfBusiness,
	|	&Warehouse                        AS Warehouse,
	|	InventoryKinds.InventoryType        AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute        AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.LogInAnalytics
	|		ELSE InventoryKinds.AnalyticsOfRegistrationWithoutAssignment
	|	END AS CorItemsLocationAttributes,
	|	InventoryKinds.DirectionOfActivityOfRegistration AS CorLineOfBusiness,
	|	&Warehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.InventoryTypeRegistration AS CorInventoryType,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt AS CorInventoryOwnerAttribute,
	|
	|	InventoryKinds.Count AS Count,
	|	InventoryKinds.Count AS CorQuantity,
	|
	|	CASE WHEN &ArrivalAtCost
	|		THEN 0
	|		ELSE InventoryKinds.SumMan
	|	END AS Cost,
	|	CASE WHEN &ArrivalAtCost
	|		THEN 0
	|		ELSE InventoryKinds.SumMan
	|	END AS CostExcludingVAT,
	|	CASE WHEN &ArrivalAtCost
	|		THEN 0
	|		ELSE InventoryKinds.SumCompl
	|	END AS LocalCost,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		InventoryKinds.InventoryOwnerAttribute
	|	ELSE 
	|		InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		InventoryKinds.InventoryOwnerAttributeGoodsReceipt
	|	ELSE 
	|		InventoryKinds.ProductsRecordingAsReceived
	|	END AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS InventoryKinds";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Warehouse                                 AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.DimensionWriteOffs   AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute          AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber            AS CCDNumber,
	|	TableTypesOfStocks_.Products        AS Products,
	|	TableTypesOfStocks_.Characteristic      AS Characteristic,
	|	TableTypesOfStocks_.Count          AS Count,
	|	&BusinessOperation                 AS BusinessOperation,
	|	&VATActivityType                    AS VATTaxation
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.SaleOfAnotherCompanyInventory
	|ORDER BY
	|	LineNumber";
	
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                            AS Counterparty,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                   AS LineOfBusiness,
	|	&Warehouse                                  AS StorageLocation,
	|	&Department                          AS Department,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	CAST(&Comment AS STRING(100))  AS Comment,
	|	&Currency                                 AS Currency,
	|	0                                       AS Sum,
	|	UNDEFINED                            AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
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
	|	Document.GoodsMisgrading AS DocumentData
	|		LEFT JOIN Document.GoodsMisgrading.Goods AS GoodsTable
	|		ON DocumentData.Ref = GoodsTable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	&Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&ExpenseItem AS ExpenseItem,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	0 AS AmountIncludingVAT,
	|	0 AS AmountExcludingVAT,
	|	0 AS AmountExcludingVATMan,
	|	0 AS AmountIncludingVATCompl,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	&DocumentID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_ AS VariancePeriod
	|	
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Receipt),
	|	&Organization,
	|	&Department,
	|	&ExpenseItem,
	|	&DimensionOfExpenses,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef),
	|	UNDEFINED,
	|
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	0,
	|	-GoodsTable.SumCompl,
	|	&BusinessOperation,
	|	GoodsTable.DimensionWriteOffs,
	|	
	|	GoodsTable.RowID,
	|	&BusinessTransactionSetting,
	|	&AdjustmentPeriod_
	|
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	NOT &ArrivalAtCost
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.SumCompl <> 0
	|	AND GoodsTable.InventoryType  IN (&InventoryTypesOwn)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("VariancePeriod");
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "";

	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	&Department AS Department,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	0 AS Sum,
	|	0 AS SumMan,
	|	0 AS SumCompl,
	|	-GoodsTable.SumCompl AS CostTD,
	|	CASE
	|		WHEN &IncomeItemIsAcceptedForTaxAccounting
	|			THEN 0
	|		ELSE GoodsTable.SumCompl
	|	END AS PermanentDifference,
	|	&BusinessOperation AS BusinessOperation,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	NOT &ArrivalAtCost
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.SumCompl <> 0
	|	AND GoodsTable.InventoryTypeRegistration IN (&InventoryTypesOwn)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.GoodsMisgrading";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert(
		"BusinessOperation", "	DocumentData.Ref.BusinessOperation");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
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
	
	If SynonymForDocumentTable <> "DocumentData" Then
		
		For Each CalculationParameter In RedefiningParameterCalculation Do
			
			RedefiningParameterCalculation[CalculationParameter.Key] =
				StrReplace(CalculationParameter.Value, "DocumentData", SynonymForDocumentTable);
			
		EndDo;
		
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

Function QueryTextTableDocumentAmountsInLocalCurrency(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentAmountsInLocalCurrency";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber         AS LineNumber,
	|	&Period                                AS Period,
	|	&Currency                                AS Currency,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.Sum               AS AmountExcludingVAT,
	|	UNDEFINED                           AS VATRate,
	|	0                                      AS VATAmount,
	|	TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS AmountExcludingVATCompl,
	|	0                                      AS VATAmountCompl,
	|	TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS AmountExcludingVATMan,
	|	0                                      AS VATAmountMan,
	|	UNDEFINED                           AS PaymentType_
	|
	|FROM
	|	Document.GoodsMisgrading.InventoryKinds AS TableTypesOfStocks_
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND NOT &ArrivalAtCost
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("TaxationOfOrganization");
	
	If Query <> Undefined Then
		SetRequestParameterTaxationOfOrganization(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTypesOfStocks");
	AdditionalTables.Add("TTOtherExpenses_");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTypesOfStocks(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTableTTOtherExpenses_(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region DisposalAtFixedCost_Item
	
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
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN TableTypesOfStocks_.CommitteeProductAnalysis
	|		ELSE TableTypesOfStocks_.DimensionWriteOffs
	|	END 											AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END 											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.LogInAnalytics 		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt	  	AS CorInventoryOwnerAttribute,
	|	&ExpenseItem 								AS ExpenseItemAssets,
	|	&DimensionOfExpenses 								AS AssetExpenseAnalytics,
	|	&IncomeItem  								AS IncomeItem,
	|	&DimensionOfRevenue								AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	UNDEFINED 					AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	TableTypesOfStocks_.SumMan 			AS Cost,
	|	TableTypesOfStocks_.SumMan 			AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl 			AS LocalCost,
	|	TableTypesOfStocks_.SumMan 			AS CostMan,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Enum.BusinessTransactions.GoodsMisgrading)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END 																		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	&BusinessTransactionSetting 											AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsMisgrading AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	// If, during the re-sorting of goods in storage, own goods are accounted for, then the transfer 
	// to the Accounting section "Goods in storage with the right of sale (to be debited)" is reflected # The Transfer area_Commodity storage.
	|	AND NOT (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		AND TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion

	#Region DisposalAtFixedCost_CommissionItem
	
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
	|	TableTypesOfStocks_.DimensionWriteOffs			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 									AS CorItemsLocationAttributes,
	|	UNDEFINED	  								AS CorInventoryOwnerAttribute,
	|	&ExpenseItem 								AS ExpenseItemAssets,
	|	&DimensionOfExpenses 								AS AssetExpenseAnalytics,
	|	&IncomeItem  								AS IncomeItem,
	|	&DimensionOfRevenue								AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	UNDEFINED 					AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	0 										AS LocalCost,
	|	0 										AS CostMan,
	|	0										AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.MaterialsReceivedForProcessing)
	|	END 									AS AccountingSection,
	|	TableTypesOfStocks_.AnalysisOfSettlementsWithCommittee AS AccountingDimensionByPartners,
	|
	// Other fields
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Enum.BusinessTransactions.GoodsMisgrading)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END 																		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	&BusinessTransactionSetting 											AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsMisgrading AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|	AND NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion
	
	#Region InternalReceipt_Product
	
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
	|	TableTypesOfStocks_.LogInAnalytics 		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt		AS InventoryOwnerAttribute,
	|	CASE WHEN NOT &Patch
	|		THEN DocumentTable.Ref
	|		ELSE DocumentTable.CorrectedDocument
	|	END 											AS Lot,
	|	CASE WHEN TableTypesOfStocks_.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		THEN &TaxationOfOrganization
	|		ELSE TableTypesOfStocks_.VATActivityType
	|	END 											AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
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
	|	TableTypesOfStocks_.RowID 				 		AS RowID,
	|	TableTypesOfStocks_.SumMan 						 		AS Cost,
	|	TableTypesOfStocks_.SumMan 						 		AS CostExcludingVAT,
	|	TableTypesOfStocks_.SumCompl 								AS LocalCost,
	|	0                                   				 		AS VATLocal,
	|	TableTypesOfStocks_.SumMan 						 		AS CostMan,
	|	0 													 		AS VATManag,
	|	TableTypesOfStocks_.AmountOffBalanceMan					 		AS OffBalanceCost,
	|	TableTypesOfStocks_.LocalOffBalanceAmount				 		AS OffBalanceCostLocal,
	|	0													 		AS AddExpensesForGoods,
	|	0													 		AS AdditionalExpensesExcludingVAT,
	|	0															AS AddExpensesLocal,
	|	0															AS AddExpensesMan,
	|	0 												 			AS PermanentDifference,
	|	0 													 		AS CostTD,
	|	0													 		AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Enum.BusinessTransactions.GoodsMisgrading)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END 																		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	&BusinessTransactionSetting 											AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsMisgrading AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.InternalReceipt,
		QueryText);
	
	#EndRegion

	#Region Moving_Product
	
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
	|	TableTypesOfStocks_.DimensionWriteOffs      			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	DocumentTable.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.LogInAnalytics			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt			AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	UNDEFINED							AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	TableTypesOfStocks_.AnalysisOfSettlementsWithCommittee								AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|			THEN VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|		ELSE &BusinessOperation
	|	END 																		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	&BusinessTransactionSetting 											AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsMisgrading AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|	AND DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
		
	#EndRegion

	#Region Moving_GoodsInStorage
	
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
	|	TableTypesOfStocks_.DimensionWriteOffs      			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	DocumentTable.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN TableTypesOfStocks_.DimensionWriteOffs
	|		ELSE TableTypesOfStocks_.LogInAnalytics END) AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt			AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	UNDEFINED							AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	&BusinessOperation					AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsMisgrading AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|	AND (DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		OR TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
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

	// Act on the re-sorting of goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfReSortingGoods";
	PrintCommand.Presentation = NStr("vi = 'Biên bản chuyển tồn hàng hóa';
									|ru = 'Акт о пересортице товаров';
									|en = 'Stock reclass certificate'; fa = 'گواهی تغییر طبقه موجودی';
									|it = 'Atto di riclassificazione delle merci';
									|pl = 'Protokół o przeklasyfikowaniu (niedobory/nadwyżki pozorne) towarów';
									|tr = 'Stok yeniden sınıflandırmasına ilişkin tutanak'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	GoodsMisgradingLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export

	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfReSortingGoods") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ActOfReSortingGoods",
				NStr("vi = 'Biên bản chuyển tồn hàng hóa';
					|ru = 'Акт о пересортице товаров';
					|en = 'Stock reclass certificate'; fa = 'گواهی تغییر طبقه موجودی';
					|it = 'Atto di riclassificazione delle merci';
					|pl = 'Protokół o przeklasyfikowaniu (niedobory/nadwyżki pozorne) towarów';
					|tr = 'Stok yeniden sınıflandırmasına ilişkin tutanak'"),
				PrintingOfActOfReSortingGoods(ObjectsArray, PrintObjects));

	EndIf;
	GoodsMisgradingLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function PrintingOfActOfReSortingGoods(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	AdditionalColumn = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	OutputAdditionalColumn = ValueIsFilled(AdditionalColumn);

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
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	PRESENTATION(Document.Warehouse) AS WarehousePresentation,
	|	PRESENTATION(Document.Department) AS DepartmentPresentation,
	|	Document.Organization.Prefix AS Prefix,
	|	Document.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
	|	Document.EmployeeResponsible.Individual AS EmployeeResponsible
	|FROM
	|	Document.GoodsMisgrading AS Document
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	GoodsTable.Products AS WriteOffProducts,
	|	GoodsTable.Products.DescriptionFull AS WriteOffProductsPresentation,
	|	GoodsTable.Characteristic.DescriptionFull AS WriteOffFeaturePresentation,
	|	PRESENTATION(GoodsTable.Series) AS SeriesWriteOffPresentation,
	|	&AdditionalColumnWriteOff,
	|	GoodsTable.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	&AdditionalColumnRegistration,
	|	GoodsTable.ProductsRecordingAsReceived.DescriptionFull AS ProductsRecordingAsReceivedPresentation,
	|	GoodsTable.CharacteristicRecordingAsReceived.DescriptionFull AS CharacteristicRecordingAsReceivedPresentation,
	|	PRESENTATION(GoodsTable.BatchReceipt) AS BatchReceiptPresentation,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure) AS UnitOfMeasurementWriteOffPresentation,
	|	PRESENTATION(GoodsTable.ProductsRecordingAsReceived.UnitOfMeasure) AS UnitOfMeasurementRegistrationPresentation,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Ref AS Ref
	|FROM
	|	Document.GoodsMisgrading.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|	AND GoodsTable.Ref.Posted
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";

	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnWriteOff", "GoodsTable.Products." + AdditionalColumn + " AS AdditionalColumnWriteOff");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnRegistration", "GoodsTable.ProductsRecordingAsReceived." + AdditionalColumn + " AS AdditionalColumnRegistration");
	Else
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnWriteOff,", "");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnRegistration,", "");
	EndIf;

	DocumentAttributes = New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Biên bản chuyển tồn hàng hóa';
							|ru = 'Акт о пересортице товаров';
							|en = 'Stock reclass certificate'; fa = 'گواهی تغییر طبقه موجودی';
							|it = 'Atto di riclassificazione delle merci';
							|pl = 'Protokół o przeklasyfikowaniu (niedobory/nadwyżki pozorne) towarów';
							|tr = 'Stok yeniden sınıflandırmasına ilişkin tutanak'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PrintPARAMETERS_ProductResortment_ProductResortmentReport";
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsMisgrading.PF_MXL_MisgradingCertificate");
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	ScopeOfApplication_2  = Template.GetArea("Basis");

	AreaOfHeaderNumber              = Template.GetArea("TableHeader|LineNumber");
	CodeAreaWriteOffHeader       = Template.GetArea("TableHeader|CodeColumnWriteOff");
	AreaOfCodesRegistrationHeader  = Template.GetArea("TableHeader|ColumnOfEntryCodes");
	ProductAreaWriteOffHeader       = Template.GetArea("TableHeader|ProductWriteOff");
	ProductAreaRegistrationHeader  = Template.GetArea("TableHeader|ProductRegistration");
	AreaEdISMWriteOffHeader       = Template.GetArea("TableHeader|UnitOfMeasurementWriteOff");
	AreaEdISMRegistrationHeader  = Template.GetArea("TableHeader|UnitOfMeasurementRegistration");
	AreaDataHeader              = Template.GetArea("TableHeader|Data");

	If Not OutputAdditionalColumn Then

		Template.Area("ProductWriteOff").ColumnWidth = Template.Area("ProductWriteOff").ColumnWidth
				+ Template.Area("CodeColumnWriteOff").ColumnWidth;
		Template.Area("ProductRegistration").ColumnWidth = Template.Area("ProductRegistration").ColumnWidth
				+ Template.Area("ColumnOfEntryCodes").ColumnWidth;

	EndIf;

	NumberAreaLine              = Template.GetArea("String|LineNumber");
	CodeAreaWriteOffLine       = Template.GetArea("String|CodeColumnWriteOff");
	AreaCodesEntryString  = Template.GetArea("String|ColumnOfEntryCodes");
	ProductAreaWriteOffLine       = Template.GetArea("String|ProductWriteOff");
	ProductAreaEntryLine  = Template.GetArea("String|ProductRegistration");
	AreaEdISMWriteOffLine       = Template.GetArea("String|UnitOfMeasurementWriteOff");
	AreaEdISMEntryString  = Template.GetArea("String|UnitOfMeasurementRegistration");
	DataAreaRow              = Template.GetArea("String|Data");

	TableBasementArea  = Template.GetArea("TableFooter");
	LabelArea        = Template.GetArea("Signatures");
	RegionAmountInWords  = Template.GetArea("AmountInWords");
	
	Query.SetParameter("ObjectsArray", ObjectsArray);
	QueryResults = Query.ExecuteBatch();
	
	DocumentsSelection = QueryResults[0].Select();
	SelectionByTableParts = QueryResults[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
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
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		HeaderDataStructure_1.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		HeaderDataStructure_1.Insert("TitleText", 
							TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		HeaderDataStructure_1.Insert("WarehousePresentation", 
							WarehousesServer.GetWarehousePresentation(DocumentsSelection.WarehousePresentation));
		HeaderArea_.Parameters.Fill(HeaderDataStructure_1);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);

		// Output of the header.
		TabDocument.Put(AreaOfHeaderNumber);

		If OutputAdditionalColumn Then

			TabDocument.Join(CodeAreaWriteOffHeader);

		EndIf;
		TabDocument.Join(ProductAreaWriteOffHeader);
		TabDocument.Join(AreaEdISMWriteOffHeader);
		
		If OutputAdditionalColumn Then

			TabDocument.Join(AreaOfCodesRegistrationHeader);

		EndIf;
		TabDocument.Join(ProductAreaRegistrationHeader);
  		TabDocument.Join(AreaEdISMRegistrationHeader);

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

				CodeAreaWriteOffLine.Parameters.Fill(SelectionByLines);
				TabDocument.Join(CodeAreaWriteOffLine);

			EndIf;

			// Nomenclature.
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductAreaWriteOffLine.Parameters.WriteOffProducts = SelectionByLines.WriteOffProducts;
			ProductAreaWriteOffLine.Parameters.WriteOffProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
					SelectionByLines.WriteOffProductsPresentation,
					SelectionByLines.WriteOffFeaturePresentation,
					SelectionByLines.SeriesWriteOffPresentation,
					,
					AdditionalParametersProductPresentation);
					
			TabDocument.Join(ProductAreaWriteOffLine);
			
			AreaEdISMWriteOffLine.Parameters.Fill(SelectionByLines);
			TabDocument.Join(AreaEdISMWriteOffLine);
			
			If OutputAdditionalColumn Then

				AreaCodesEntryString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(AreaCodesEntryString);

			EndIf;

			// Nomenclature.
			ProductAreaEntryLine.Parameters.ProductsRecordingAsReceived = SelectionByLines.ProductsRecordingAsReceived;
			ProductAreaEntryLine.Parameters.ProductsRecordingAsReceivedPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
					SelectionByLines.ProductsRecordingAsReceivedPresentation,
					SelectionByLines.CharacteristicRecordingAsReceivedPresentation,
					SelectionByLines.BatchReceiptPresentation,
					,
					AdditionalParametersProductPresentation);
					
			TabDocument.Join(ProductAreaEntryLine);
			
			AreaEdISMEntryString.Parameters.Fill(SelectionByLines);
			TabDocument.Join(AreaEdISMEntryString);

			// Quantity data.
			DataAreaRow.Parameters.Fill(SelectionByLines);
			
			TabDocument.Join(DataAreaRow);

			TotalItems_1 = TotalItems_1 + 1;

		EndDo;

		// Output of the basement.
		TabDocument.Put(TableBasementArea);
		// Withdrawal of the Amount in words.
		
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'", Common.DefaultLanguageCode());
		
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		
		RegionAmountInWords.Parameters.TotalString = TextOfResultingLine;

		TabDocument.Put(RegionAmountInWords);

		// Output of signatures.
		LabelArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(DocumentsSelection.EmployeeResponsible, 
			?(DocumentsSelection.Patch, DocumentsSelection.DateOfDocumentBeingCorrected, DocumentsSelection.Date));
		LabelArea.Parameters.Warehouseman = PersonsTM.IndividualShortName(DocumentsSelection.Warehouseman,
			?(DocumentsSelection.Patch, DocumentsSelection.DateOfDocumentBeingCorrected, DocumentsSelection.Date));
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.GoodsMisgrading - link to the document.
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
	|	Document.GoodsMisgrading AS DocumentData
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

#EndRegion

#EndRegion

#EndIf
