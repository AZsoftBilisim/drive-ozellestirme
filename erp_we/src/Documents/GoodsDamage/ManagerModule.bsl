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
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsAreEmpty = "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ExpenseItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ExpenseItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfExpenses", Parameters);
	
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
	
	GoodsDamageLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.GoodsDamage") Then
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
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		// Execution of the request and unloading of the received tables for movements.
		GoodsDamageLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.GoodsDamage);
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
	
	Documents.PriceSetup.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	GoodsDamageLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	Documents.DamageAtCustodian.AddCreateCommandBasedOnDamageToGiverSGoods(GenerationCommands);
EndProcedure

// Adds the command to create the "product Damage" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsDamage) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsDamage.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsDamage);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsQuality";
	

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Adds the command to create the "product Damage" document.
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnWarehouseGroupCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.GoodsDamage) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.GoodsDamage.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateDamageToGoodsBasedOnGroupOfWarehouses";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.GoodsDamage);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseGoodsQuality";
		
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
	
	GoodsDamageLocalization.AddReportCommands(ReportsCommands, Parameters);

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
	
	SeriesSpecificationParameters.FullObjectName = "Document.GoodsDamage";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.FieldNameControlledLotReference = "ControlledLotReference";
	
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	
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

#EndRegion
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return GoodsDamageLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - the text of the request for additional temporary tables required for reflection in the regulated accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return GoodsDamageLocalization.RequestTextTTReflectedInLocalAccounting();

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
	// Remnants of goods in the warehouse.
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", True, "Object.Goods.Purpose");
	DescriptionOfColumns.Columns.FindByValue("InStock").Check = True;
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.ControlledLotReference";
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Warehouse)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.GoodsDamage, DocumentObject.GoodsDamage - document the damage to the goods.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Warehouse");
	
	If TypeOf(Document) = Type("DocumentRef.GoodsDamage") Then
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
//	BusinessOperation            - EnumRef.BusinessTransactions - The operation of the document.
//	TradeGoodsAtCost - Boolean - indicates whether the goods need to be named at cost.
//
// Returns:
//	Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//             .
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, TradeGoodsAtCost) Export
	
	AvailabilityByOperation = Not TradeGoodsAtCost;
	
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	
	ChoiceParameters.AvailabilityByOperation = AvailabilityByOperation;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	
	Return ChoiceParameters;
	
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

#Region Private

#Region FillingInDocument_

Function ParametersForCreatingWarehousesByGroup(CommandParameter) Export
	
	Query = New Query();
	
	If TypeOf(CommandParameter) = Type("DocumentRef.GoodsQualityControlCertificate") Then
		
		Query.Text =
		"SELECT ALLOWED DISTINCT
		|	Goods.Warehouse.Ref AS Warehouse
		|FROM
		|	Document.GoodsQualityControlCertificate.Goods AS Goods
		|WHERE
		|	Goods.Ref = &Ref
		|	AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.RegisterStockQualityChange)";
		Query.SetParameter("Ref", CommandParameter);
		
	EndIf;
	
	Warehouses = Query.Execute().Unload().UnloadColumn("Warehouse");
	
	MultipleWarehouses = False;
	If Warehouses.Count() > 1 Then
		MultipleWarehouses = True;
	ElsIf Warehouses.Count() = 0 Then
		Warehouses.Add(Catalogs.Warehouses.EmptyRef()); // goods will not be filled in during the processing of filling in the document, a message will be issued about the absence of lines with the necessary action
	EndIf;
	
	ParametersForCreatingWarehousesByGroup = New Structure();
	ParametersForCreatingWarehousesByGroup.Insert("WarehousesList", Warehouses);
	ParametersForCreatingWarehousesByGroup.Insert("MultipleWarehouses", MultipleWarehouses);
	
	Return ParametersForCreatingWarehousesByGroup;
	
EndFunction

#EndRegion

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
	|	DocumentData.Ref            AS Ref,
	|	DocumentData.Date              AS Period,
	|	DocumentData.Number             AS Number,
	|	DocumentData.Warehouse             AS Warehouse,
	|	DocumentData.Currency            AS Currency,
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Department     AS Department,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef))AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.ExpenseItem    AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|			THEN TRUE
	|		ELSE FALSE
	|	END                             AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DocumentData.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse AS ArrivalAtCost,
	|	DocumentData.VATActivityType AS VATActivityType,
	|	DocumentData.EmployeeResponsible     AS EmployeeResponsible,
	|	DocumentData.Author             AS Author,
	|	DocumentData.Comment       AS Comment,
	|	DocumentData.DeletionMark   AS DeletionMark,
	|	DocumentData.Patch       AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted          AS Posted,
	|	DocumentData.DocumentID AS DocumentID,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.GoodsDamage AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Patch",                      Attributes.Patch);
	Query.SetParameter("ReversedDocument",             Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",             Attributes.CorrectedDocument);
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", 
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	Query.SetParameter("NumberForPrinting",              ObjectsPrefixesClientServer.NumberForPrinting(
	                                                        Attributes.Number));
	Query.SetParameter("MetadataIdentifier",    Common.MetadataObjectID(
	                                                        "Document.GoodsDamage"));
EndProcedure

Procedure IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers)
	
	QueryTextDocument_ =
	"SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.Products        AS Products,
	|	GoodsTable.Characteristic      AS Characteristic,
	|	GoodsTable.Purpose          AS Purpose,
	|	GoodsTable.Ref.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Series               AS Series,
	|	-GoodsTable.Count         AS Count,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.Ref              AS Ref,
	|	GoodsTable.Ref.Date         AS Date,
	|	GoodsTable.Ref.Warehouse        AS Warehouse,
	|	GoodsTable.ProductsRecordingAsReceived   AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.ForAssignment
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                             AS Purpose,
	|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
	|	GoodsTable.Series               AS Series,
	|	GoodsTable.Count          AS Count,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsTable
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
	|	GoodsTable.Products		AS Products,
	|	GoodsTable.Characteristic	AS Characteristic,
	|	CASE
	|		WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN GoodsTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END							AS Purpose,
	|	GoodsTable.Series				AS Series,
	|	GoodsTable.Count		AS Count,
	|	&Warehouse							AS Sender,
	|	UNDEFINED					AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.DamageRecord) AS WarehouseOperation,
	|	&Ref							AS Document,
	|	&Period							AS Period,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.ProductsRecordingAsReceived		AS Products,
	|	GoodsTable.CharacteristicRecordingAsReceived	AS Characteristic,
	|	CASE
	|		WHEN GoodsTable.ForAssignment
	|			THEN CASE
	|					WHEN ISNULL(GoodsTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|						THEN GoodsTable.Purpose
	|					ELSE VALUE(Catalog.Assignments.EmptyRef)
	|				END
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END										AS Purpose,
	|	GoodsTable.Series							AS Series,
	|	GoodsTable.Count					AS Count,
	|	UNDEFINED								AS Sender,
	|	&Warehouse										AS Recipient,
	|	VALUE(Enum.WarehouseTransactions.DamageRecord) AS WarehouseOperation,
	|	&Ref										AS Document,
	|	&Period										AS Period,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND GoodsTable.Count <> 0
	|	AND GoodsTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Warehouse",  Query.Parameters.Warehouse);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments",  Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.Text =
	"SELECT DISTINCT
	|	Goods.Warehouse          AS Warehouse,
	|	Goods.Products   AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Purpose     AS Purpose,
	|	Goods.Series          AS Series
	|FROM
	|	(
	|		SELECT
	|			&Warehouse                                       AS Warehouse,
	|			GoodsTable.ItemsLocationAttributesReceipt.Products      AS Products,
	|			GoodsTable.ItemsLocationAttributesReceipt.Characteristic    AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			GoodsTable.ItemsLocationAttributesReceipt.Series                          AS Series
	|		FROM
	|			Document.GoodsDamage.InventoryKinds AS GoodsTable
	|			LEFT JOIN
	|				InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON
	|				GoodsTable.ItemsLocationAttributesReceipt.Products = Dimension.Products
	|				AND GoodsTable.ItemsLocationAttributesReceipt.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND GoodsTable.ItemsLocationAttributesReceipt.Series = Dimension.Series
	|				AND GoodsTable.ItemsLocationAttributesReceipt.StorageLocation = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			GoodsTable.Ref = &Ref
	|			AND Dimension.Products IS NULL
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|		UNION ALL
	|
	|		SELECT
	|			GoodsTable.ItemsLocationAttributesReceipt.StorageLocation AS Warehouse,
	|			GoodsTable.ItemsLocationAttributesReceipt.Products AS Products,
	|			GoodsTable.ItemsLocationAttributesReceipt.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|			GoodsTable.ItemsLocationAttributesReceipt.Series AS Series
	|		FROM
	|			Document.GoodsDamage.InventoryKinds AS GoodsTable
	|			LEFT JOIN
	|				InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON
	|				GoodsTable.ItemsLocationAttributesReceipt.Products = Dimension.Products
	|				AND GoodsTable.ItemsLocationAttributesReceipt.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND GoodsTable.ItemsLocationAttributesReceipt.Series = Dimension.Series
	|				AND GoodsTable.ItemsLocationAttributesReceipt.StorageLocation = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			GoodsTable.Ref = &Ref
	|			AND Dimension.Products IS NULL
	|			AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|		UNION ALL
	|
	|		SELECT 
	|			GoodsTable.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|			GoodsTable.ItemsLocationAttributesReceipt.Products AS Products,
	|			GoodsTable.ItemsLocationAttributesReceipt.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|		FROM
	|			Document.GoodsDamage.InventoryKinds AS GoodsTable
	|			LEFT JOIN
	|				InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON
	|				GoodsTable.ItemsLocationAttributesReceipt.Products = Dimension.Products
	|				AND GoodsTable.ItemsLocationAttributesReceipt.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND GoodsTable.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			GoodsTable.Ref = &Ref 
	|			AND GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			AND Dimension.Products IS NULL
	|
	|		UNION ALL
	|
	|		SELECT 
	|			GoodsTable.InventoryOwnerAttribute.GoodsOwner             AS Warehouse,
	|			GoodsTable.ItemsLocationAttributes.Products AS Products,
	|			GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|		FROM
	|			Document.GoodsDamage.InventoryKinds AS GoodsTable
	|			LEFT JOIN
	|				InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON
	|				GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|				AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|				AND GoodsTable.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			GoodsTable.Ref = &Ref 
	|			AND GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			AND Dimension.Products IS NULL
	|
	|		UNION ALL
	|
	|		SELECT 
	|			GoodsTable.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.GoodsOwner                 AS Warehouse,
	|			GoodsTable.ItemsLocationAttributes.Products AS Products,
	|			GoodsTable.ItemsLocationAttributes.Characteristic AS Characteristic,
	|			VALUE(Catalog.Assignments.EmptyRef)        AS Purpose,
	|			VALUE(Catalog.ItemsBatches.EmptyRef) AS Series
	|		FROM
	|			Document.GoodsDamage.InventoryKinds AS GoodsTable
	|			LEFT JOIN
	|				InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON
	|				GoodsTable.ItemsLocationAttributes.Products = Dimension.Products
	|				AND GoodsTable.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|				AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|				AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|				AND GoodsTable.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.GoodsOwner = Dimension.StorageLocation
	|				AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		WHERE
	|			GoodsTable.Ref = &Ref 
	|			AND GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND GoodsTable.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			AND Dimension.Products IS NULL
	|	) AS Goods";
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAnalysisKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS DimensionRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Purpose.LineOfBusiness AS DirectionOfActivityRegistration,
	|	KeysWithoutAssignment.DimensionKey AS AnalyticsRegistrationWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS DimensionWriteOff,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalyticsWriteOffWithoutAssignment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Contract AS Contract,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt.InventoryType AS InventoryTypeRegistration,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOffBalanceMan,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalOffBalanceAmount,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee
	|	
	|INTO TTTypesOfStocks
	|FROM
	|	Document.GoodsDamage.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS KeysWithoutAssignment
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products = KeysWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic = KeysWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Series = KeysWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.StorageLocation = KeysWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysWithoutAssignment.ProductCostElement
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Partner = TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND AnalysisOfCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|		AND AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType <> VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products AS ProductsRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic AS CharacteristicRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt AS DimensionRecordingAsReceived,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt.Purpose.LineOfBusiness AS DirectionOfActivityRegistration,
	|	KeysRegistrationWithoutAssignment.DimensionKey AS AnalyticsRegistrationWithoutAssignment,
	|	Dimension.DimensionKey AS DimensionWriteOff,
	|	Dimension.DimensionKey AS AnalyticsWriteOffWithoutAssignment,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner AS GoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Contract AS Contract,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt AS InventoryOwnerAttributeGoodsReceipt,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt.InventoryType AS InventoryTypeRegistration,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityByGBRN,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass			AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation	AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	TableTypesOfStocks_.Sum AS Sum,
	|	CAST(TableTypesOfStocks_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(TableTypesOfStocks_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOffBalanceMan,
	|	CAST(TableTypesOfStocks_.AmountOffBalance * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalOffBalanceAmount,
	|	TableTypesOfStocks_.RowID AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series AS Series,
	|	CASE WHEN TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner REFS Catalog.Companies
	|		THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE AnalysisOfCalculations.DimensionKey
	|	END AS AnalysisOfSettlementsWithCommittee
	|
	|FROM
	|	Document.GoodsDamage.InventoryKinds AS TableTypesOfStocks_
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS KeysRegistrationWithoutAssignment
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributesReceipt.Products = KeysRegistrationWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Characteristic = KeysRegistrationWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.Series = KeysRegistrationWithoutAssignment.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = KeysRegistrationWithoutAssignment.Purpose
	|		AND TableTypesOfStocks_.ItemsLocationAttributesReceipt.StorageLocation = KeysRegistrationWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = KeysRegistrationWithoutAssignment.ProductCostElement
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = Dimension.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|		AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = &Organization
	|		AND AnalysisOfCalculations.Partner = TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner
	|		AND AnalysisOfCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND AnalysisOfCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|		AND AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|		AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND AnalysisOfIntercampaniCalculations.Counterparty = TableTypesOfStocks_.InventoryOwnerAttribute.Counterparty
	|		AND AnalysisOfIntercampaniCalculations.Contract = TableTypesOfStocks_.InventoryOwnerAttribute.Contract
	|		AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.GoodsDamage.Name,
		"InventoryKinds",
		"ItemsLocationAttributesReceipt");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 													 AS TabularSectionName,
	|	DocumentTable.LineNumber 										 AS LineNumber,
	|	UNDEFINED														 AS Vendor,
	|	UNDEFINED														 AS Counterparty,
	|	UNDEFINED 														 AS VATRate,
	|	DocumentData.VATActivityType									 AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) 						 AS AssetTaxClass,
	|	LineCodes.RowCode													 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.GoodsDamage.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.GoodsDamage AS DocumentData
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
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	&Period                                         AS Period,
	|	&Warehouse                                          AS Warehouse,
	|	&Organization                                    AS ShipmentCompany,
	|
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|	ELSE
	|		&Organization
	|	END AS Organization,
	|
	|	CASE WHEN TableTypesOfStocks_.SaleOfAnotherCompanyInventory THEN
	|		TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner
	|	ELSE
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	END AS InventoryOwnerAttribute,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes   AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.Products                 AS Products,
	|	TableTypesOfStocks_.Characteristic               AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                     AS CCDNumber,
	|	TableTypesOfStocks_.VATActivityType           AS VATTaxation,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt      AS CorInventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.DimensionWriteOff
	|	ELSE
	|		TableTypesOfStocks_.DimensionRecordingAsReceived
	|	END AS CorItemsLocationAttributes,
	|	&BusinessOperation                          AS BusinessOperation,
	|	&ExpenseItem                                 AS ExpenseItem,
	|	&DimensionOfExpenses                              AS DimensionOfExpenses,
	|	FALSE                                            AS Primary,
	|	TableTypesOfStocks_.Count                   AS Count,
	|	0                                               AS ToRegisterGoodsIssue,
	|	TableTypesOfStocks_.QuantityByGBRN             AS QuantityByGBRN,
	|	0                                               AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	&Period                                         AS Period,
	|	&Warehouse                                          AS Warehouse,
	|	&Organization                                    AS ShipmentCompany,
	|	&Organization                                    AS Organization,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt      AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.DimensionRecordingAsReceived       AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ProductsRecordingAsReceived    AS Products,
	|	TableTypesOfStocks_.CharacteristicRecordingAsReceived  AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber                     AS CCDNumber,
	|	UNDEFINED                                    AS VATTaxation,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                   AS CorInventoryOwnerAttribute,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		TableTypesOfStocks_.DimensionWriteOff
	|	ELSE
	|		TableTypesOfStocks_.ItemsLocationAttributes
	|	END                                           AS CorItemsLocationAttributes,
	|	&BusinessOperation                          AS BusinessOperation,
	|	UNDEFINED                                    AS ExpenseItem,
	|	UNDEFINED                                    AS DimensionOfExpenses,
	|	NOT &ArrivalAtCost                       AS Primary,
	|	TableTypesOfStocks_.Count                   AS Count,
	|	0                                               AS ToRegisterGoodsIssue,
	|	TableTypesOfStocks_.QuantityByGBRN             AS QuantityByGBRN,
	|	0                                               AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|";
	
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
	
	QueryText = 
	"SELECT
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&Period                                       AS Period,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.Currency                     AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                 AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	TableTypesOfStocks_.DimensionWriteOff          AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt    AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.DimensionRecordingAsReceived     AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber                   AS CCDNumber,
	|	&BusinessOperation                        AS BusinessOperation,
	|	0                                             AS Count,
	|	TableTypesOfStocks_.Count                 AS QuantityConsumed,
	|	0                                             AS RevenueAmount,
	|	0                                             AS RevenueAmountExclVATLocal,
	|	0                                             AS RevenueAmountMan,
	|	0                                             AS QuantityToRegister,
	|	0                                             AS QuantityForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.Count                 AS QuantityConsumedForIncoiceRegistration,
	|	TableTypesOfStocks_.QuantityByGBRN           AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	0                                             AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.RowID        AS FinRecordID,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsDamage)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.GoodsDamageRevaluation)
	|	END                                         AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID        AS RowID
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

Procedure SetRequestParameterTaxationOfOrganization(Query)
	
	If Query.Parameters.Property("TaxationOfOrganization") Then
		Return;
	EndIf;
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Query.Parameters.Organization, Query.Parameters.Period).BasicTaxationVATSales;
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization);
	
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
	|	(CASE WHEN &ArrivalAtCost THEN UNDEFINED ELSE &Ref END) AS DocumentInflow,
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	&Period                                       AS Period,
	|	&Organization                                  AS Organization,
	|	TableTypesOfStocks_.DimensionRecordingAsReceived     AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt    AS InventoryOwnerAttribute,
	|	(CASE WHEN &ArrivalAtCost THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.LotVendorAttributes END) AS LotVendorAttributes,
	|	TableTypesOfStocks_.Count                 AS Count,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumMan  END) AS Cost,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumMan  END) AS CostExcludingVAT,
	|	(CASE WHEN &ArrivalAtCost THEN 0. ELSE TableTypesOfStocks_.SumCompl END) AS LocalCost,
	|	0. AS VATLocal,
	|	TableTypesOfStocks_.Products               AS Products,
	|	TableTypesOfStocks_.Characteristic             AS Characteristic,
	|	&BusinessOperation                        AS BusinessOperation,
	|	(NOT &ArrivalAtCost) AS Primary,
	|	(CASE WHEN &ArrivalAtCost THEN &Ref ELSE UNDEFINED END) AS DocumentSource
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion21";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsProductsProducts(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	InventoryKinds.LineOfBusiness AS LineOfBusiness,
	|	&Warehouse AS Warehouse,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionRecordingAsReceived
	|		ELSE InventoryKinds.AnalyticsRegistrationWithoutAssignment
	|	END AS CorItemsLocationAttributes,
	|	InventoryKinds.DirectionOfActivityRegistration AS CorLineOfBusiness,
	|	&Warehouse AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt.InventoryType AS CorInventoryType,
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
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization AS CompanyOwner,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.Count AS Count,
	|	&BusinessOperation AS BusinessOperation,
	|	&VATActivityType AS VATTaxation
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
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
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
	|	Document.GoodsDamage AS DocumentData
	|		LEFT JOIN Document.GoodsDamage.Goods AS GoodsTable
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
	
	FullDocumentName           = "Document.GoodsDamage";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("UseWarehouseManagemantSystemForGoodsSurplusesShortages",
		"CASE
		|		WHEN GoodsTable.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|				AND GoodsTable.Ref.Date >= GoodsTable.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
		|			THEN TRUE
		|		ELSE FALSE
		|	END");
	
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
	
	If SynonymForDocumentTable <> "GoodsTable" Then
		For Each CalculationParameter In RedefiningParameterCalculation Do
			RedefiningParameterCalculation[CalculationParameter.Key] = StrReplace(
				CalculationParameter.Value, "GoodsTable", SynonymForDocumentTable);
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

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses();
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
	|	&DocumentID         AS FinRecordID,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsDamage)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.GoodsDamageRevaluation)
	|	END                           AS BusinessTransactionSetting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_();
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
		|	TabPart.Ref.Warehouse AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	TabPart.Ref.ControlledLotReference AS ControlledLotReference,
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.GoodsDamage.Goods AS TabPart
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
		|	CASE
		|		WHEN TabPart.ForAssignment
		|			THEN TabPart.Purpose
		|		ELSE VALUE(Catalog.Assignments.EmptyRef)
		|	END AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	FALSE AS OnSchedule,
		|	UNDEFINED AS OrderInSchedule
		|FROM
		|	Document.GoodsDamage.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, False, False);
	
EndProcedure

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
	|	TableTypesOfStocks_.DimensionWriteOff 			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.DimensionRecordingAsReceived 									AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt	  								AS CorInventoryOwnerAttribute,
	|	&ExpenseItem 															AS ExpenseItemAssets,
	|	&DimensionOfExpenses 															AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.GoodsValueVariance)  AS IncomeItem,
	|	TableTypesOfStocks_.DimensionWriteOff.Products							AS DimensionOfRevenue,
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
	|	VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation)			AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 											AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsDamageRevaluation)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsDamage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	// If, when the goods are damaged in storage, their own goods are accounted for, then the transfer 
	// to the Accounting section "Goods in storage with the right of sale (to be debited)" is reflected # The Transfer area_Commodity storage.
	|	AND NOT (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|		AND TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods))
	|";
	
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
	|	TableTypesOfStocks_.DimensionRecordingAsReceived 		AS ItemsLocationAttributes,
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
	|	VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation)			AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 											AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsDamageRevaluation)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsDamage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|";
	
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
	|	TableTypesOfStocks_.DimensionWriteOff      			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	DocumentTable.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.DimensionRecordingAsReceived			AS CorItemsLocationAttributes,
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
	|	VALUE(Enum.BusinessTransactions.GoodsDamage)			AS BusinessOperation,
	|	TableTypesOfStocks_.RowID								AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.GoodsDamage)	AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsDamage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|	AND TableTypesOfStocks_.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
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
	|	TableTypesOfStocks_.DimensionWriteOff      			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	DocumentTable.VATActivityType					AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN TableTypesOfStocks_.DimensionWriteOff
	|		ELSE TableTypesOfStocks_.DimensionRecordingAsReceived END) AS CorItemsLocationAttributes,
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
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Enum.BusinessTransactions.GoodsDamage)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsDamageRevaluation)
	|	END 																		AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsDamage)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.GoodsDamage)
	|	END 																		AS BusinessTransactionSetting
	|
	|FROM
	|	Document.GoodsDamage AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
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

	// The act of damage to goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfSpoilageOfGoods";
	PrintCommand.Presentation = NStr("vi = 'Biên bản về hàng hỏng';
									|ru = 'Акт о порче товаров';
									|en = 'Stock quality change certificate'; fa = 'گواهی تغییر کیفیت موجودی';
									|it = 'Atto di danneggiamento delle merci';
									|pl = 'Protokół o uszkodzeniu towarów';
									|tr = 'Stok kalite değişikliğine ilişkin tutanak'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.FunctionalOptions = "UseGoodsQuality";
	
	GoodsDamageLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfSpoilageOfGoods") Then

		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"ActOfSpoilageOfGoods",
			NStr("vi = 'Biên bản về hàng hỏng';
				|ru = 'Акт о порче товаров';
				|en = 'Stock quality change certificate'; fa = 'گواهی تغییر کیفیت موجودی';
				|it = 'Atto di danneggiamento delle merci';
				|pl = 'Protokół o uszkodzeniu towarów';
				|tr = 'Stok kalite değişikliğine ilişkin tutanak'"),
			PrintingOfActOfDamageToGoods(ObjectsArray, PrintObjects));
		
	EndIf;
	GoodsDamageLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	
EndProcedure

Function PrintingOfActOfDamageToGoods(ObjectsArray, PrintObjects)
	
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
	|	Document.Organization.AbbreviatedDescription AS OrganizationPresentation,
	|	Document.Organization.Prefix AS Prefix,
	|	Document.Warehouse.CurrentEmployeeInChargeTypes AS Warehouseman,
	|	Document.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition_,
	|	Document.EmployeeResponsible.Individual AS EmployeeResponsible,
	|	Document.CauseForDamage AS CauseForDamage 
	|FROM
	|	Document.GoodsDamage AS Document
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
	|	GoodsTable.Products AS SourceProducts_,
	|	GoodsTable.Products.DescriptionFull AS SourceProducts_Presentation,
	|	GoodsTable.Characteristic.DescriptionFull AS InitialCharacteristicPresentation,
	|	&AdditionalColumnWriteOff,
	|	GoodsTable.ProductsRecordingAsReceived AS ProductIsFlawed,
	|	&AdditionalColumnRegistration,
	|	GoodsTable.ProductsRecordingAsReceived.DescriptionFull AS ProductIsFlawedPresentation,
	|	GoodsTable.CharacteristicRecordingAsReceived.DescriptionFull AS CharacteristicSpoiledPresentation,
	|	PRESENTATION(GoodsTable.Series) AS SeriesPresentation,
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure) AS UnitOfMeasurementInitialPresentation,
	|	PRESENTATION(GoodsTable.ProductsRecordingAsReceived.UnitOfMeasure) AS UnitOfMeasurementCorruptedPresentation,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Ref AS Ref
	|FROM
	|	Document.GoodsDamage.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";	

	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnWriteOff", "GoodsTable.Products." + AdditionalColumn + " AS AdditionalColumnWriteOff");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnRegistration", "ProductsRecordingAsReceived." + AdditionalColumn + " AS AdditionalColumnRegistration");
	Else	
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnWriteOff,", "");
		Query.Text = StrReplace(Query.Text, "&AdditionalColumnRegistration,", "");
	EndIf;
	
	DocumentAttributes = New Structure("Number, Date, Prefix, Presentation, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Biên bản về hàng hỏng';
							|ru = 'Акт о порче товаров';
							|en = 'Stock quality change certificate'; fa = 'گواهی تغییر کیفیت موجودی';
							|it = 'Atto di danneggiamento delle merci';
							|pl = 'Protokół o uszkodzeniu towarów';
							|tr = 'Stok kalite değişikliğine ilişkin tutanak'", Common.DefaultLanguageCode());
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PARAMETERS_PRESS_DamageToGoods_ActOfDamageToGoods";         
	
	Template = PrintManagement.PrintFormTemplate("Document.GoodsDamage.PF_MXL_GoodsDeteriorationCertificate");
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	ScopeOfApplication_2  = Template.GetArea("Basis");

	AreaOfHeaderNumber              = Template.GetArea("TableHeader|LineNumber");
	CodeAreaSourceHeader       = Template.GetArea("TableHeader|SourceCodeColumn");
	AreaCodesCorruptedHeader  = Template.GetArea("TableHeader|CodesColumnIsMessedUp");
	ProductHeaderArea       = Template.GetArea("TableHeader|OriginalProduct");              
	ProductAreaDamagedCap    = Template.GetArea("TableHeader|DamagedGoods_");
	AreaEdISMSourceHeader       = Template.GetArea("TableHeader|UnitOfMeasurementInitial");
	AreaEdISMCorruptedHeader  = Template.GetArea("TableHeader|UnitOfMeasurementCorrupted");
	AreaDataHeader              = Template.GetArea("TableHeader|Data");

	If Not OutputAdditionalColumn Then

		Template.Area("OriginalProduct").ColumnWidth = Template.Area("OriginalProduct").ColumnWidth
				+ Template.Area("SourceCodeColumn").ColumnWidth;
		Template.Area("DamagedGoods_").ColumnWidth = Template.Area("DamagedGoods_").ColumnWidth
				+ Template.Area("CodesColumnIsMessedUp").ColumnWidth;

	EndIf;

	NumberAreaLine              = Template.GetArea("String|LineNumber");
	CodeAreaSourceString       = Template.GetArea("String|SourceCodeColumn");
	AreaCodesCorruptedString  = Template.GetArea("String|CodesColumnIsMessedUp");
	ProductLineArea       = Template.GetArea("String|OriginalProduct");
	ProductAreaIsDamaged    = Template.GetArea("String|DamagedGoods_");
	AreaEdISMSourceString       = Template.GetArea("String|UnitOfMeasurementInitial");
	AreaEdISMCorruptedString  = Template.GetArea("String|UnitOfMeasurementCorrupted");
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
		DataOfArea = New Structure;
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		DataOfArea.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		DataOfArea.Insert("TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		DataOfArea.Insert("WarehousePresentation", WarehousesServer.GetWarehousePresentation(DocumentsSelection.WarehousePresentation));
		HeaderArea_.Parameters.Fill(DataOfArea);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		TabDocument.Put(HeaderArea_);

		// Output of the header.
		TabDocument.Put(AreaOfHeaderNumber);

		If OutputAdditionalColumn Then

			TabDocument.Join(CodeAreaSourceHeader);

		EndIf;
		TabDocument.Join(ProductHeaderArea);
		TabDocument.Join(AreaEdISMSourceHeader);
		
		If OutputAdditionalColumn Then

			TabDocument.Join(AreaCodesCorruptedHeader);

		EndIf;
		TabDocument.Join(ProductAreaDamagedCap);
  		TabDocument.Join(AreaEdISMCorruptedHeader);

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

				CodeAreaSourceString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(CodeAreaSourceString);

			EndIf;

			// Nomenclature.
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductLineArea.Parameters.SourceProducts_ = SelectionByLines.SourceProducts_;
			ProductLineArea.Parameters.SourceProducts_Presentation = ProductsClientServer.PresentationOfProductsForPrinting(
					SelectionByLines.SourceProducts_Presentation,
					SelectionByLines.InitialCharacteristicPresentation,
					,
					SelectionByLines.SeriesPresentation,
					AdditionalParametersProductPresentation);
					
			TabDocument.Join(ProductLineArea);
			
			AreaEdISMSourceString.Parameters.Fill(SelectionByLines);
			TabDocument.Join(AreaEdISMSourceString);
			
			If OutputAdditionalColumn Then

				AreaCodesCorruptedString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(AreaCodesCorruptedString);

			EndIf;

			// Nomenclature.
			ProductAreaIsDamaged.Parameters.ProductIsFlawed = SelectionByLines.ProductIsFlawed;
			ProductAreaIsDamaged.Parameters.ProductIsFlawedPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
					SelectionByLines.ProductIsFlawedPresentation,
					SelectionByLines.CharacteristicSpoiledPresentation,
					SelectionByLines.SeriesPresentation,
					,
					AdditionalParametersProductPresentation);
					
			TabDocument.Join(ProductAreaIsDamaged);
			
			AreaEdISMCorruptedString.Parameters.Fill(SelectionByLines);
			TabDocument.Join(AreaEdISMCorruptedString);

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
		LabelArea.Parameters.StorekeeperPosition_ = WarehousesServer.PositionOfResponsiblePersonOfWarehouse(DocumentsSelection.StorekeeperPosition_);
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	TabDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
