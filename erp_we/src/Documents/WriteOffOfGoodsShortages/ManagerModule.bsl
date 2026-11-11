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
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ExpenseItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ExpenseItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfExpenses,AssetsLiabilitiesDimension", Parameters);
	
	WriteOffOfGoodsShortagesLocalization.EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1);
		
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
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	WriteOffOfGoodsShortagesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.WriteOffOfGoodsShortages") Then
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
		QueryTextRegisterRecordsProductsIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		WriteOffOfGoodsShortagesLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	ReflectStockDistribution(Query, QueryTexts, Registers);
	IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.WriteOffOfGoodsShortages);
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
	
	WriteOffOfGoodsShortagesLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Write off product shortages".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.WriteOffOfGoodsShortages) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.WriteOffOfGoodsShortages.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.WriteOffOfGoodsShortages);
		CreateBasedOnCommand.WriteMode = "Post";

		Return CreateBasedOnCommand;
	EndIf;

	Return Undefined;
EndFunction

// Adds the command to create the document "Write off product shortages".
//
// Parameters:
//  GenerationCommands - ValueTable - command table.
// Returns:
//  ValueTableRow, Undefined - description of the added command.
Function AddCreateBasedOnWarehouseGroupCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.WriteOffOfGoodsShortages) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.WriteOffOfGoodsShortages.FullName();
		CreateBasedOnCommand.Handler = "GenerationByReferenceTMClient.CreateStockShortagesRecognitionBasedOnGroupOfWarehouses";
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.WriteOffOfGoodsShortages);
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
	
	WriteOffOfGoodsShortagesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate
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
	
	DescriptionOfColumns.DataPaths.Products = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse = "Object.Warehouse";
	DescriptionOfColumns.DataPaths.ControlledLotReference = "Object.Goods.ControlledLotReference";
	
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
//	Document - FormDataStructure, DocumentRef.WriteOffOfGoodsShortages, DocumentObject.WriteOffOfGoodsShortages - document write-off of product shortages.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForFillingInVATActivityType.
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Warehouse");
	
	If TypeOf(Document) = Type("DocumentRef.WriteOffOfGoodsShortages") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	FillParameters.OtherDisposalOfGoods = True;
	
	Return FillParameters;
	
EndFunction

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

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.WriteOffOfGoodsShortages - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
	
	QueryTexts = New ValueList;
	Query        = FillInInitialParameters(DocumentRef, QueryTexts);
	
	QueryTextTTBases(Query, QueryTexts);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	CASE
	|		WHEN TTBases.NumberOfActivities = 1
	|			THEN TTBases.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.InventoryConsumption) AS KindOfTransactionWithExcisableGoods,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	&DocumentID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN TTBases AS TTBases
	|		ON (TTBases.Ref = &Ref)
	|WHERE
	|	(TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|			OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|			OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0)";
	
	QueryTexts.Add(QueryText);

	Results = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	Return Results[Results.UBound()];
	
EndFunction

// We are forming a request to receive data to fill in the register of "Movement on other assets and liabilities".
//
// Parameters:
//	DocumentRef - DocumentRef.InventoryConsumption - link to the document.
//
// Returns:
//	QueryResult - data on other assets and liabilities.
//
Function GetDataOnOtherAssetsLiabilities(DocumentRef) Export
	
	QueryTexts = New ValueList;
	Query        = FillInInitialParameters(DocumentRef, QueryTexts);
	
	Registers = New Structure;
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	Registers.Insert(RegisterName, Undefined);
	
	QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
	Results = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	Return Results[Results.UBound()];
	
EndFunction

#EndRegion
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
		|	AND Goods.Action = VALUE(Enum.ActionsOnGoodsInQualityControlCertificate.MakeDebit)";
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

// This function determines the details of the selected document.
//
// Parameters:
//  DocumentRef - DocumentRef.WriteOffOfGoodsShortages - link to the document.
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
	|	Document.WriteOffOfGoodsShortages AS DocumentData
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

// Parameters for specifying series.
//
// Parameters:
//	Object - Structure - a Collection Of Object Attribute Values required to fill in the parameters for specifying series.
//
// Returns:
//	See ProductsClientServer.SeriesSpecificationParameters.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.WriteOffOfGoodsShortages";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("ControlledLotReference");
	
	SeriesSpecificationParameters.FieldNameControlledLotReference = ".ControlledLotReference";
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
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

	Return WriteOffOfGoodsShortagesLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - The text of the request for the temporary reflection table in the regl accounting
Function RequestTextTTReflectedInLocalAccounting() Export

	Return WriteOffOfGoodsShortagesLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

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
	|	DocumentData.Organization       AS Organization,
	|	DocumentData.Warehouse             AS Warehouse,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems THEN
	|		DocumentData.ExpenseItem                
	|	ELSE UNDEFINED
	|	END    						  AS ExpenseItem,
	|	CASE WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems THEN
	|		DocumentData.ExpenseItem                
	|	ELSE UNDEFINED
	|	END    						  AS AssetAndLiabilityItem,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.Department     AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	CASE
	|		WHEN DocumentData.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
	|				AND DocumentData.Date >= DocumentData.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages
	|			THEN TRUE
	|		ELSE FALSE
	|	END                            AS UseWarehouseManagemantSystemForGoodsSurplusesShortages,
	|	DocumentData.VATActivityType AS VATActivityType,
	|	DocumentData.EmployeeResponsible    AS EmployeeResponsible,
	|	DocumentData.Author            AS Author,
	|	DocumentData.Comment      AS Comment,
	|	DocumentData.DeletionMark  AS DeletionMark,
	|	DocumentData.Patch      AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	DocumentData.Posted         AS Posted,
	|	DocumentData.DocumentID AS DocumentID
	|FROM
	|	Document.WriteOffOfGoodsShortages AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();	
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("UseWarehouseManagemantSystemForGoodsSurplusesShortages", 
		Attributes.UseWarehouseManagemantSystemForGoodsSurplusesShortages);
	
	Query.SetParameter("NumberForPrinting",              ObjectsPrefixesClientServer.NumberForPrinting(
	                                                        Attributes.Number));
	Query.SetParameter("MetadataIdentifier",    Common.MetadataObjectID(
	                                                        "Document.WriteOffOfGoodsShortages"));
	Query.SetParameter("Ref",                         DocumentRef);
	Query.SetParameter("BusinessOperation",          Enums.BusinessTransactions.GoodsConsumption);
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.GoodsConsumption);
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Warehouse",  Query.Parameters.Warehouse);
	QueryAnalyst.SetParameter("Series",  Catalogs.ItemsBatches.EmptyRef());
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	Goods.InventoryOwnerAttribute.GoodsOwner AS Warehouse,
	|	Keys.Products           AS Products,
	|	Keys.Characteristic         AS Characteristic,
	|	&EmptyAssignment            AS Purpose,
	|	&Series                       AS Series
	|FROM
	|	Document.WriteOffOfGoodsShortages.InventoryKinds AS Goods
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON
	|		Goods.ItemsLocationAttributes = Keys.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		Keys.Products           = Dimension.Products
	|		AND Keys.Characteristic       = Dimension.Characteristic
	|		AND &EmptyAssignment          = Dimension.Purpose
	|		AND Goods.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|		AND &Series                     = Dimension.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND Goods.Ref = &Ref
	|	AND Goods.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Keys.StorageLocation			 AS Warehouse,
	|	Keys.Products           AS Products,
	|	Keys.Characteristic         AS Characteristic,
	|	&EmptyAssignment            AS Purpose,
	|	Keys.Series                  AS Series
	|FROM
	|	Document.WriteOffOfGoodsShortages.InventoryKinds AS Goods
	|
	|	LEFT JOIN
	|		Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON
	|		Goods.ItemsLocationAttributes = Keys.Ref
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON
	|		Keys.Products           = Dimension.Products
	|		AND Keys.Characteristic       = Dimension.Characteristic
	|		AND &EmptyAssignment          = Dimension.Purpose
	|		AND Keys.StorageLocation		 = Dimension.StorageLocation
	|		AND Keys.Series                = Dimension.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND Goods.Ref = &Ref
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|";
	
	Selection = QueryAnalyst.Execute().Select();
	
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure
Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRatioFromLocalToMan") Then
		Return;
	EndIf;
	
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	RatePeriod = Query.Parameters.Period;

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	
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
	|	GoodsTable.ControlledLotReference AS ControlledLotReference,
	|	GoodsTable.Series               AS Series,
	|	-GoodsTable.Count         AS Count,
	|	GoodsTable.BatchesIndicationStatus AS BatchesIndicationStatus
	|FROM
	|	Document.WriteOffOfGoodsShortages.Goods AS GoodsTable
	|WHERE
	|	GoodsTable.Ref IN(&Ref)";
	
	WarehousesServer.IssueSurplusShortagesInWarehouse(Query, QueryTexts, Registers, QueryTextDocument_);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	SeriesTable.Products   AS Products,
	|	SeriesTable.Characteristic AS Characteristic,
	|	CASE WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|		  THEN SeriesTable.Purpose
	|		  ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                       AS Purpose,
	|	SeriesTable.Series          AS Series,
	|	SeriesTable.Count     AS Count,
	|	&Warehouse                      AS Sender,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord) AS WarehouseOperation,
	|	&Ref                     AS Document,
	|	&Period                     AS Period,
	|	&Ref                     AS Recorder,
	|	NOT &UseWarehouseManagemantSystemForGoodsSurplusesShortages AS ThisIsWarehouseRecord
	|FROM
	|	Document.WriteOffOfGoodsShortages.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	InitializeProductAnalysisKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	QueryText = 
	"SELECT
	|	Rows.LineNumber                             AS LineNumber,
	|	InventoryKinds.GoodsOwner                     AS GoodsOwner,
	|	Rows.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey           AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	CommitteeAnalytics.DimensionKey               AS CommitteeAccountingAnalytics,
	|	CASE
	|		WHEN InventoryKinds.GoodsOwner REFS Catalog.Companies
	|			THEN AnalysisOfIntercampaniCalculations.DimensionKey
	|		ELSE
	|			AnalysisOfCalculations.DimensionKey
	|	END                                          AS AnalysisOfSettlementsWithCommittee,
	|	Dimension.Products                         AS Products,
	|	Dimension.Characteristic                       AS Characteristic,
	|	Dimension.Purpose                           AS Purpose,
	|	Dimension.Series                                AS Series,
	|	ISNULL(Assignments.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef))
	|	                                               AS LineOfBusiness,
	|	InventoryKinds.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	InventoryKinds.InventoryOwnerAttributeOfCompanyGoodsOwner                AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	Rows.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	InventoryKinds.Currency                             AS Currency,
	|	InventoryKinds.Contract                            AS Contract,
	|	InventoryKinds.InventoryType                         AS InventoryType,
	|	Rows.CCDNumber                                AS CCDNumber,
	|	Rows.Count                              AS Count,
	|	Rows.QuantityByGBRN                        AS QuantityByGBRN,
	|	Rows.ExciseTaxAmount                             AS ExciseAmountInCurrencyLocal,
	|	CAST(Rows.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	Dimension.WarehouseArea.ShopFloorStockroom  AS ShopFloorStockroom,
	|	Rows.RowID                     AS RowID
	|INTO TTTypesOfStocks
	|FROM
	|	Document.WriteOffOfGoodsShortages.InventoryKinds AS Rows
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|		ON Rows.InventoryOwnerAttribute = InventoryKinds.Ref
	|	
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON Rows.ItemsLocationAttributes = Dimension.Ref
	|	
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON Dimension.Products = AnalyticsWithoutAssignment.Products
	|			AND Dimension.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose
	|			AND Dimension.Series = AnalyticsWithoutAssignment.Series
	|			AND Dimension.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement
	|	
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|		ON Dimension.Products = CommitteeAnalytics.Products
	|			AND Dimension.Characteristic = CommitteeAnalytics.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalytics.Purpose
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalytics.Series
	|			AND Rows.InventoryOwnerAttribute.GoodsOwner = CommitteeAnalytics.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalytics.ProductCostElement
	|	
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfCalculations
	|		ON AnalysisOfCalculations.Organization = &Organization
	|			AND AnalysisOfCalculations.Partner = InventoryKinds.GoodsOwner
	|			AND AnalysisOfCalculations.Counterparty = InventoryKinds.Counterparty
	|			AND AnalysisOfCalculations.Contract = InventoryKinds.Contract
	|			AND AnalysisOfCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS AnalysisOfIntercampaniCalculations
	|		ON AnalysisOfIntercampaniCalculations.Organization = &Organization
	|			AND AnalysisOfIntercampaniCalculations.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|			AND AnalysisOfIntercampaniCalculations.Counterparty = InventoryKinds.Counterparty
	|			AND AnalysisOfIntercampaniCalculations.Contract = InventoryKinds.Contract
	|			AND AnalysisOfIntercampaniCalculations.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	
	|		LEFT JOIN Catalog.Assignments AS Assignments
	|		ON Dimension.Purpose = Assignments.Ref
	|WHERE
	|	Rows.Ref = &Ref";
	
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
	|	Rows.LineNumber                      AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	&Period                                 AS Period,
	|	Rows.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory
	|			THEN Rows.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE
	|			&Organization
	|	END                                   AS Organization,
	|	CASE 
	|		WHEN Rows.SaleOfAnotherCompanyInventory
	|			THEN Rows.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE
	|			Rows.InventoryOwnerAttribute
	|	END                                   AS InventoryOwnerAttribute,
	|	Rows.CCDNumber                         AS CCDNumber,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS ShipmentCompany,
	|	Rows.Products                     AS Products,
	|	Rows.Characteristic                   AS Characteristic,
	|	&VATActivityType                     AS VATTaxation,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN UNDEFINED
	|		ELSE
	|			&DimensionOfExpenses
	|	END                                   AS DimensionOfExpenses,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN UNDEFINED
	|		ELSE
	|			&AssetsLiabilitiesDimension
	|	END                                   AS AssetsLiabilitiesDimension,
	|	CASE
	|		WHEN Rows.InventoryType = VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
	|			THEN UNDEFINED
	|		WHEN &ExpenseItem = UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE
	|			&ExpenseItem
	|	END                                   AS ExpenseItem,
	|	Rows.Count                       AS Count,
	|	0                                       AS ToRegisterGoodsIssue,
	|	Rows.QuantityByGBRN                 AS QuantityByGBRN,
	|	0                                       AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS Rows
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.LineNumber                      AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	&Period                                 AS Period,
	|	Rows.ItemsLocationAttributes       AS ItemsLocationAttributes,
	|	CASE
	|		WHEN Rows.SaleOfAnotherCompanyInventory
	|			THEN Rows.InventoryOwnerAttributeOfCompanyGoodsOwner.Organization
	|		ELSE
	|			&Organization
	|	END                                   AS Organization,
	|	CASE 
	|		WHEN Rows.SaleOfAnotherCompanyInventory
	|			THEN Rows.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE
	|			Rows.InventoryOwnerAttribute
	|	END                                   AS InventoryOwnerAttribute,
	|	Rows.CCDNumber                         AS CCDNumber,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS ShipmentCompany,
	|	Rows.Products                     AS Products,
	|	Rows.Characteristic                   AS Characteristic,
	|	&VATActivityType                     AS VATTaxation,
	|	UNDEFINED                            AS DimensionOfExpenses,
	|	UNDEFINED                            AS AssetsLiabilitiesDimension,
	|	UNDEFINED                            AS ExpenseItem,
	|	0                                       AS Count,
	|	Rows.Count                       AS ToRegisterGoodsIssue,
	|	0                                       AS QuantityByGBRN,
	|	Rows.QuantityByGBRN                 AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS Rows
	|WHERE
	|	Rows.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.MaterialOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.SemiFinishedProductOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.ProductsOfMaterialProvider),
	|		VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell))
	|
	|ORDER BY
	|	LineNumber";
	
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
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText =
	"SELECT
	|	Rows.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	Rows.Currency                          AS Currency,
	|	Rows.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	Rows.Products                    AS Products,
	|	Rows.Characteristic                  AS Characteristic,
	|	Rows.CCDNumber                        AS CCDNumber,
	|	&BusinessOperation                 AS BusinessOperation,
	|	Rows.Count                      AS Count,
	|	0                                      AS QuantityConsumed,
	|	0                                      AS RevenueAmount,
	|	0                                      AS RevenueAmountExclVATLocal,
	|	0                                      AS RevenueAmountMan,
	|	Rows.Count                      AS QuantityToRegister,
	|	Rows.QuantityByGBRN                AS QuantityForRegistrationByProductBatchID,
	|	0                                      AS QuantityConsumedForIncoiceRegistration,
	|	0                                      AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	0                                      AS RevenueAmountToRegister,
	|	Rows.CommitteeAccountingAnalytics         AS ItemsLocationAttributes,
	|	Rows.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
	|	Rows.RowID             AS RowID
	|FROM
	|	TTTypesOfStocks AS Rows
	|
	|WHERE
	|	Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND Rows.SaleOfAnotherCompanyInventory
	|	AND Rows.InventoryOwnerAttribute.GoodsTransferMethod <> VALUE(Enum.GoodsTransferMethods.TransferToCommissionAgent)
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	Rows.Currency                          AS Currency,
	|	Rows.InventoryOwnerAttribute                      AS InventoryOwnerAttribute,
	|	Rows.Products                    AS Products,
	|	Rows.Characteristic                  AS Characteristic,
	|	Rows.CCDNumber                        AS CCDNumber,
	|	&BusinessOperation                 AS BusinessOperation,
	|	0                                      AS Count,
	|	Rows.Count                      AS QuantityConsumed,
	|	0                                      AS RevenueAmount,
	|	0                                      AS RevenueAmountExclVATLocal,
	|	0                                      AS RevenueAmountMan,
	|	0                                      AS QuantityToRegister,
	|	0                                      AS QuantityForRegistrationByProductBatchID,
	|	Rows.Count                      AS QuantityConsumedForIncoiceRegistration,
	|	Rows.QuantityByGBRN                AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	0                                      AS RevenueAmountToRegister,
	|	Rows.CommitteeAccountingAnalytics         AS ItemsLocationAttributes,
	|	Rows.RowID             AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ConsignedGoodsWriteOff) AS BusinessTransactionSetting,
	|	Rows.RowID             AS RowID
	|FROM
	|	TTTypesOfStocks AS Rows
	|
	|WHERE
	|	Rows.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE GoodsTable.AnalysisOfAccountingForProductsWithoutAssignment
	|	END AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.InventoryType AS InventoryType,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &ExpenseItem = UNDEFINED THEN
	|		&AssetAndLiabilityItem
	|	ELSE
	|		&ExpenseItem
	|	END AS IncomeAndExpenseItem,
	|	GoodsTable.LineOfBusiness AS LineOfBusinessItems,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	GoodsTable.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	GoodsTable.InventoryOwnerAttribute AS SourceOfProductFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|
	|	GoodsTable.CommitteeAccountingAnalytics AS ItemsLocationAttributes,
	|	GoodsTable.LineOfBusiness AS ProductLineOfBusiness,
	|	InventoryLocationAttributeKeys.StorageLocation AS Warehouse,
	|	VALUE(Enum.InventoryTypes.OwnGoods) AS InventoryType,
	|	UNDEFINED AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &ExpenseItem = UNDEFINED THEN
	|		&AssetAndLiabilityItem
	|	ELSE
	|		&ExpenseItem
	|	END AS IncomeAndExpenseItem,
	|	GoodsTable.LineOfBusiness AS LineOfBusinessItems,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|
	|	GoodsTable.Count AS Count,
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|
	|	GoodsTable.InventoryOwnerAttribute AS SourceOfProductFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS InventoryLocationAttributeKeys
	|	ON GoodsTable.CommitteeAccountingAnalytics = InventoryLocationAttributeKeys.Ref
	|WHERE
	|	GoodsTable.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
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
Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocks", QueryTexts) Then
		QueryTextTTTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	&AssetAndLiabilityItem AS AssetRef,
	|	&AssetsLiabilitiesDimension AS Dimension,
	|	&GLAccountSettings AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	SUM(GoodsTable.ExciseAmountInCurrencyLocal) AS SumCompl,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS SumMan,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS AmountIncludingVAT,
	|	SUM(GoodsTable.ExciseAmountInCurrencyMgmt) AS AmountExcludingVAT,
	|
	|	&DocumentID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|WHERE
	|	&UseExcisableGoods
	|	AND &AssetAndLiabilityItem <> UNDEFINED
	|
	|HAVING
	|	SUM(GoodsTable.ExciseAmountInCurrencyLocal) <> 0
	|		OR SUM(GoodsTable.ExciseAmountInCurrencyMgmt) <> 0
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses();
	
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
	|	UNDEFINED                            AS Currency,
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
	|	Document.WriteOffOfGoodsShortages AS DocumentData
	|		LEFT JOIN Document.WriteOffOfGoodsShortages.Goods AS GoodsTable
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
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|
	|UNION ALL
	|
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
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountIncludingVAT,
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountExcludingVAT,
	|	SUM(TableExpenses.ExciseAmountInCurrencyMgmt) AS AmountExcludingVATMan,
	|	SUM(TableExpenses.ExciseAmountInCurrencyLocal) AS AmountIncludingVATCompl,
	|	SUM(TableExpenses.ExciseAmountInCurrencyLocal) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation AS BusinessOperation,
	|	TableExpenses.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	&DocumentID         AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	TTTypesOfStocks AS TableExpenses
	|GROUP BY
	|	VALUE(AccumulationRecordType.Receipt),
	|	TableExpenses.ItemsLocationAttributes
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

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.WriteOffOfGoodsShortages";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.GoodsConsumption);
	
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
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
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
		|	TabPart.Count AS Count,
		|	UNDEFINED AS PlannedConsumptionOfDistributedStock,
		|	FALSE AS ControlOfFreeResidue
		|FROM
		|	Document.WriteOffOfGoodsShortages.Goods AS TabPart
		|WHERE
		|	NOT TabPart.Ref.Warehouse.UseWarehouseManagemantSystemForGoodsSurplusesShortages
		|	OR TabPart.Ref.Warehouse.StartDateOfWarehouseManagemantSystemForGoodsSurplusesShortages > TabPart.Ref.Date";
	
	StockAllocationRecords.StockConsumption(Query, QueryTexts, Registers, QueryTextTabPart, True);
	
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
	
	#Region Moving_GoodsInStorageWithRightToSell
	
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
	|	TableTypesOfStocks_.ItemsLocationAttributes      	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	DocumentTable.VATActivityType 			 	AS VATActivityType,
	|	DocumentTable.VATActivityType			 		AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsConsumption) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 						 AS FinRecordID,
	|	&BusinessTransactionSetting								 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffOfGoodsShortages AS DocumentTable
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
		
	#EndRegion
	
	#Region WriteOffForExpensesAssets_Product
	
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
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	DocumentTable.VATActivityType				AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	ISNULL(OtherExpenses.CompanyRecipient, UNDEFINED) AS CorCompany,
	|	UNDEFINED 								    			AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute  				    			AS CorInventoryOwnerAttribute,
	|	DocumentTable.ExpenseItem 			    			AS ExpenseItemAssets,
	|	CASE WHEN DocumentTable.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems
	|		THEN DocumentTable.DimensionOfExpenses                
	|		ELSE DocumentTable.AssetsLiabilitiesDimension
	|	END    						  			    			AS AssetExpenseAnalytics,
	|	TableTypesOfStocks_.LineOfBusiness			    	AS CorLineOfBusiness,
	|	TableTypesOfStocks_.AnalysisOfSettlementsWithCommittee 			AS AccountingDimensionByPartners,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.EmployeeResponsible		AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 		AS Count,
	|
	// Other fields
	|	DocumentTable.GLAccountSettings 					 	 AS GLAccountSettings,
	|	VALUE(Enum.BusinessTransactions.GoodsConsumption) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID						 AS RowID,
	|	TableTypesOfStocks_.RowID 						 AS FinRecordID,
	|	&BusinessTransactionSetting								 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WriteOffOfGoodsShortages AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN TTOtherExpenses_ AS OtherExpenses
	|		ON OtherExpenses.ExpenseItem = &ExpenseItem
	|		AND OtherExpenses.DimensionOfExpenses = &DimensionOfExpenses
	|		AND OtherExpenses.ItemsLocationAttributes = TableTypesOfStocks_.ItemsLocationAttributes
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType <> VALUE(Enum.InventoryTypes.GoodsInStorageWithRightToSell)
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
	
	// The act of writing off goods
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ActOfDebitingGoods";
	PrintCommand.Presentation = NStr("vi = 'Biên bản ghi giảm hàng hóa';
									|ru = 'Акт о списании товаров';
									|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
									|it = 'Atto di storno delle merci';
									|pl = 'Protokół o wybrakowaniu towarów';
									|tr = 'Stok eksiği tahakkuku'");
	PrintCommand.CheckPostingBeforePrint = True;
	
	WriteOffOfGoodsShortagesLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfDebitingGoods") Then
		
	PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection, 
			"ActOfDebitingGoods",
			NStr("vi = 'Biên bản ghi giảm hàng hóa';
				|ru = 'Акт о списании товаров';
				|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
				|it = 'Atto di storno delle merci';
				|pl = 'Protokół o wybrakowaniu towarów';
				|tr = 'Stok eksiği tahakkuku'"),
			GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects));
		
	EndIf;
	
	WriteOffOfGoodsShortagesLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
EndProcedure

Function GeneratePrintedFormForDebitingGoods(ObjectsArray, PrintObjects)

	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	AdditionalColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputAdditionalColumn = ValueIsFilled(AdditionalColumn);
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
	|	Document.Warehouse.CurrentPositionOfTheResponsiblePerson AS StorekeeperPosition_,
	|	Document.EmployeeResponsible.Individual AS EmployeeResponsible
	|FROM
	|	Document.WriteOffOfGoodsShortages AS Document
	|WHERE
	|	Document.Ref IN(&ObjectsArray)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WriteOffOfShortagesOfGoods.Ref AS Ref,
	|	WriteOffOfShortagesOfGoods.LineNumber AS LineNumber,
	|	WriteOffOfShortagesOfGoods.Products AS Products,
	|	WriteOffOfShortagesOfGoods.Characteristic AS Characteristic,
	|	WriteOffOfShortagesOfGoods.Count AS Count,
	|	&AdditionalColumn,
	|	WriteOffOfShortagesOfGoods.Products.DescriptionFull AS ProductsPresentation,
	|	WriteOffOfShortagesOfGoods.Characteristic.DescriptionFull AS CharacteristicPresentation,
	|	PRESENTATION(WriteOffOfShortagesOfGoods.Series) AS SeriesPresentation,
	|	PRESENTATION(WriteOffOfShortagesOfGoods.Products.UnitOfMeasure) AS UnitOfMeasurePresentation
	|FROM
	|	Document.WriteOffOfGoodsShortages.Goods AS WriteOffOfShortagesOfGoods
	|WHERE
	|	WriteOffOfShortagesOfGoods.Ref IN(&ObjectsArray)
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref";
	
	If OutputAdditionalColumn Then
		Query.Text = StrReplace(Query.Text, "&AdditionalColumn", "WriteOffOfShortagesOfGoods.Products." + AdditionalColumn + " AS AdditionalColumn");
	Else
		Query.Text = StrReplace(Query.Text, "&AdditionalColumn,", "");
	EndIf;
	
	ResultsArray = Query.ExecuteBatch();
	
	QueryResult = ResultsArray[0]; // QueryResult
	SelectionByDocuments = QueryResult.Select();
	
	QueryResult = ResultsArray[1]; // QueryResult
	ProductSelection_1 	= QueryResult.Select(QueryResultIteration.ByGroups);
	
	DocumentAttributes 	= New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym 	= NStr("vi = 'Biên bản ghi giảm hàng hóa';
								|ru = 'Акт о списании товаров';
								|en = 'Stock shortage recognition'; fa = 'شناسایی کسری موجودی';
								|it = 'Atto di storno delle merci';
								|pl = 'Protokół o wybrakowaniu towarów';
								|tr = 'Stok eksiği tahakkuku'");
	
	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PARAMETERS_PRESS_WriteOffOfShortageOfGoods_ReportOnWriteOffOfGoods";
	
	Template = PrintManagement.PrintFormTemplate("Document.WriteOffOfGoodsShortages.PF_MXL_GoodsWriteOffNote");
	
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
	
	LabelArea       	= Template.GetArea("Signatures");
	AreaTotalQuantity 	= Template.GetArea("TotalCount1");
	
	FirstDocument = True;
	While SelectionByDocuments.Next() Do
		
		If Not FirstDocument Then
			TabDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument = False;
		
		RowNumberStart = TabDocument.TableHeight + 1;
		
		FillPropertyValues(DocumentAttributes, SelectionByDocuments);
		HeaderArea_.Parameters.Fill(SelectionByDocuments); 
		DataOfArea = New Structure;
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(SelectionByDocuments.Organization, SelectionByDocuments.Date);
		DataOfArea.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		DataOfArea.Insert("TitleText",
						TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		DataOfArea.Insert("WarehousePresentation", WarehousesServer.GetWarehousePresentation(SelectionByDocuments.WarehousePresentation));
		HeaderArea_.Parameters.Fill(DataOfArea);
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, SelectionByDocuments.Ref);
		TabDocument.Put(HeaderArea_);
		
		// Output of strings.
		If Not ProductSelection_1.FindNext(New Structure("Ref",SelectionByDocuments.Ref)) Then
			Continue;
		EndIf;
		
		// Output of the header.
		TabDocument.Put(AreaOfHeaderNumber);
		
		If OutputAdditionalColumn Then
			AreaCodesHeader.Parameters.AdditionalColumn = PresentationOfCodesColumn;
			TabDocument.Join(AreaCodesHeader);
		EndIf;
		
		TabDocument.Join(ProductAreaHeader);
		TabDocument.Join(AreaDataHeader);
		
		TotalItems_1 = 0;
		
		SelectionByLines = ProductSelection_1.Select(QueryResultIteration.ByGroups);
		While SelectionByLines.Next() Do
			NumberAreaLine.Parameters.Fill(SelectionByLines);
			TabDocument.Put(NumberAreaLine);
			If OutputAdditionalColumn Then
				AreaCodesString.Parameters.Fill(SelectionByLines);
				TabDocument.Join(AreaCodesString);
			EndIf;
			
			// Nomenclature.
			AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			ProductLineArea_.Parameters.Products = SelectionByLines.Products;
			ProductLineArea_.Parameters.ProductsPresentation = ProductsClientServer.PresentationOfProductsForPrinting(
				SelectionByLines.ProductsPresentation,
				SelectionByLines.CharacteristicPresentation,
				,
				SelectionByLines.SeriesPresentation,
				AdditionalParametersProductPresentation);
			TabDocument.Join(ProductLineArea_);
			// Quantity data.
			DataAreaRow.Parameters.Fill(SelectionByLines);
			TabDocument.Join(DataAreaRow);
			TotalItems_1 = TotalItems_1 + 1;
		EndDo;
		
		// Output of results.
		TabDocument.Put(RoomAreaBasementTable);
		If OutputAdditionalColumn Then
			TabDocument.Join(AreaCodesBasementTables);
		EndIf;
		TabDocument.Join(ProductAreaTableBasement);
		TabDocument.Join(DataAreaTableBasement);
		TextOfResultingLine = NStr("vi = 'Tổng số mặt hàng: %TotalItems_1%';
									|ru = 'Всего наименований %TotalItems_1%';
									|en = 'Total items %TotalItems_1%'; fa = 'Total items %TotalItems_1%';
									|it = 'Totale articoli %TotalItems_1%';
									|pl = 'Razem pozycji %TotalItems_1%';
									|tr = 'Toplam tanım %TotalItems_1%'");
		TextOfResultingLine = StrReplace(TextOfResultingLine,"%TotalItems_1%", TotalItems_1);
		AreaTotalQuantity.Parameters.TotalString = TextOfResultingLine;
		TabDocument.Put(AreaTotalQuantity);
		
		// Output of signatures.
		LabelArea.Parameters.EmployeeResponsible = PersonsTM.IndividualShortName(
			SelectionByDocuments.EmployeeResponsible,
			?(SelectionByDocuments.Patch, SelectionByDocuments.DateOfDocumentBeingCorrected, SelectionByDocuments.Date));
		LabelArea.Parameters.Warehouseman = PersonsTM.IndividualShortName(
			SelectionByDocuments.Warehouseman,
			?(SelectionByDocuments.Patch, SelectionByDocuments.DateOfDocumentBeingCorrected, SelectionByDocuments.Date));
		LabelArea.Parameters.StorekeeperPosition_ = WarehousesServer.PositionOfResponsiblePersonOfWarehouse(SelectionByDocuments.StorekeeperPosition_);
		TabDocument.Put(LabelArea);
		
		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, SelectionByDocuments.Ref);
		
	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

Function FillInInitialParameters(DocumentRef, QueryTexts)
	
	Query         = New Query;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DocumentID AS DocumentID,
	|	DocumentData.Department AS Department,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	CASE WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems THEN
	|		DocumentData.ExpenseItem
	|	ELSE UNDEFINED
	|	END    							AS ExpenseItem,
	|	CASE WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems THEN
	|		DocumentData.ExpenseItem
	|	ELSE UNDEFINED
	|	END    							AS AssetAndLiabilityItem	
	|FROM
	|	Document.WriteOffOfGoodsShortages AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Period,
	|			(Products, Country) IN
	|				(SELECT
	|					T.Products AS Products,
	|					&RegistrationCountry AS Country
	|				FROM
	|					Document.WriteOffOfGoodsShortages.Goods AS T
	|				WHERE
	|					T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products";
	
	QueryTexts.Add(QueryText, "TTCategoriesOfExcisableItems");

	QueryText = 
	"SELECT
	|	Dimension.Products AS Products,
	|	Rows.Count AS Count,
	|	Rows.ExciseTaxAmount AS ExciseAmountInCurrencyLocal,
	|	CAST(Rows.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(TableExciseCategories.ExcisableGoodsCategory, VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) AS ExcisableGoodsCategory,
	|	CASE
	|		WHEN Rows.InventoryOwnerAttribute.SubjectToExcise
	|			THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * Rows.Count
	|		ELSE 0
	|	END AS QuantityInExcisableCategoryUOM,
	|	Rows.InventoryOwnerAttribute.BusinessUnitProduction AS BusinessUnitProduction,
	|	Rows.RowID AS RowID,
	|	Rows.ItemsLocationAttributes AS ItemsLocationAttributes
	|INTO TTTypesOfStocks
	|FROM
	|	Document.WriteOffOfGoodsShortages.InventoryKinds AS Rows
	|
	|		INNER JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|			ON Rows.ItemsLocationAttributes = Dimension.Ref
	|
	|		INNER JOIN Catalog.InventoryKinds AS InventoryKinds
	|			ON Rows.InventoryOwnerAttribute = InventoryKinds.Ref
	|
	|		INNER JOIN TTCategoriesOfExcisableItems AS TableExciseCategories
	|			ON Dimension.Products = TableExciseCategories.Products
	|WHERE
	|	Rows.Ref = &Ref
	|	AND TableExciseCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)";

	QueryTexts.Add(QueryText, "TTTypesOfStocks");

	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.GoodsConsumption);
	Query.SetParameter("BusinessOperation",          Enums.BusinessTransactions.GoodsConsumption);
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	SetRequestParametersCurrencyCoefficients(Query);
	
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	
	Return Query;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
