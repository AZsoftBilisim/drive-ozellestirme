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
	
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("WIPAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	WIPOpeningBalancesByProductionLotsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.WIPOpeningBalancesByProductionLots") Then
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
		
		QueryTextTableOtherWorkInProgressExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableWIPLaborCosts(Query, QueryTexts, Registers);
		
		WIPOpeningBalancesByProductionLotsLocalization.AddRequestTexts(
			Query,
			QueryTexts,
			Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region SetOfSeries

//Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Department,Date";
	
	Return AttributesNames;
	
EndFunction

//Returns parameters for specifying series for products specified in the document
//
//	Parameters:
//	 Object - Structure - structure of object details values required for filling in parameters for specifying series
//	Returns:
//	 Structure - See ProductsServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName	= "Document.WIPOpeningBalancesByProductionLots";
	SeriesSpecificationParameters.NameTSGoods		= "MaterialsAndWorks";
	SeriesSpecificationParameters.TSSeriesName		= "MaterialsAndWorks";
	
	SeriesSpecificationParameters.ThisIsAnInvoice										= True;
	SeriesSpecificationParameters.Date												= Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName										= "Department";
	
	SeriesSpecificationParameters.UseItemsBatch	= GetFunctionalOption("UseItemsBatchProduction22");
	SeriesSpecificationParameters.UseCostAccountingByBatches	= GetFunctionalOption("UseCostAccountingByBatchesProduction22");
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.OBEntry);
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("Package");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// The procedure fills in the statuses for specifying series in the PM goods lines
//
// Parameters:
//  SeriesSpecificationParameters - Structure - structure of parameters for specifying series returned by the corresponding procedure of the document Manager module (processing)
//
// Returns:
//	String - The text of the request to fill in statuses.
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.LineNumber,
	|	Goods.BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Package,
	|	SetOfSeries.Count
	|INTO SetOfSeries
	|FROM
	|	&SetOfSeries AS SetOfSeries
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Purpose,
	|	Goods.Package,
	|	SUM(Goods.Count) AS Count,
	|	CAST(Goods.Products AS Catalog.Products).ProductKind AS ProductKind
	|INTO ProductsToRequest
	|FROM
	|	Goods AS Goods
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Package,
	|	Goods.Characteristic,
	|	Goods.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SetOfSeries.Products,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose,
	|	SetOfSeries.Package,
	|	SUM(SetOfSeries.Count) AS Count
	|INTO SeriesToRequest
	|FROM
	|	SetOfSeries AS SetOfSeries
	|
	|GROUP BY
	|	SetOfSeries.Products,
	|	SetOfSeries.Package,
	|	SetOfSeries.Characteristic,
	|	SetOfSeries.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS StatusOfSpecifyingSeriesIsOld,
	|	CASE
	|		WHEN CatItemKinds.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN CatItemKinds.BatchAccountingPolicy.UseCostAccountingByBatches
	|			THEN CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 14
	|					ELSE 13
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
	|				AND ProductsToRequest.Package = SeriesToRequest.Package
	|			LEFT JOIN Catalog.ItemKinds AS CatItemKinds
	|			ON ProductsToRequest.ProductKind = CatItemKinds.Ref
	|		ON Goods.Products = ProductsToRequest.Products
	|			AND Goods.Characteristic = ProductsToRequest.Characteristic
	|			AND Goods.Purpose = ProductsToRequest.Purpose
	|			AND Goods.Package = ProductsToRequest.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusTable.LineNumber AS LineNumber,
	|	StatusTable.BatchesIndicationStatus
	|FROM
	|	Statuses AS StatusTable
	|WHERE
	|	StatusTable.StatusOfSpecifyingSeriesIsOld <> StatusTable.BatchesIndicationStatus
	|
	|ORDER BY
	|	LineNumber";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region StandardCommandSubsystems

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	WIPOpeningBalancesByProductionLotsLocalization.AddGenerationCommands(
		GenerationCommands,
		Parameters);
	
EndProcedure

// Adds a command to create the document "Initial WIP balances by production batches".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.WIPOpeningBalancesByProductionLots) Then
		
		CreationBasedOnCommand = GenerationCommands.Add();
		
		CreationBasedOnCommand.Handler			= "GenerationByReferenceTMClient.ToCreateInitialRemnantsOfUnfinishedProductionByBatchesOfProduction";
		CreationBasedOnCommand.Id		= "ToCreateInitialRemnantsOfUnfinishedProductionByBatchesOfProduction";
		CreationBasedOnCommand.Presentation		= TMCommonUse.ObjectPresentation(Metadata.Documents.WIPOpeningBalancesByProductionLots);
		CreationBasedOnCommand.WriteMode			= "Post";
		CreationBasedOnCommand.MultipleChoice	= False;
		
		Return CreationBasedOnCommand;
		
	EndIf;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	WIPOpeningBalancesByProductionLotsLocalization.AddReportCommands(
		ReportsCommands,
		Parameters);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	WIPOpeningBalancesByProductionLotsLocalization.AddPrintCommands(
		PrintCommands);
	
EndProcedure

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

#Region DownloadingFromVHFFile

// Sets the download parameters.
//
// Parameters:
//   Parameters - Structure - download parameters from a file.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	ColumnDataType	= Parameters.ColumnDataType;
	TSName				= Parameters.AdditionalParameters.TSName;
	
	ColumnDataType.Insert("DocumentType",					New TypeDescription("String",,	New StringQualifiers(23)));
	ColumnDataType.Insert("DocumentDate",					New TypeDescription("Date",,	New DateQualifiers(DateFractions.DateTime)));
	ColumnDataType.Insert("DocumentNumber",					New TypeDescription("String",,	New StringQualifiers(11)));
	ColumnDataType.Insert("CostGroupNumber",				New TypeDescription("Number",,	New NumberQualifiers(15,0)));
	ColumnDataType.Insert("NameOfCalculationArticle",	New TypeDescription("String",,	New StringQualifiers(100)));
	ColumnDataType.Insert("Sum",							New TypeDescription("Number",,	New NumberQualifiers(15, 2)));
	
	If TSName = "MaterialsAndWorks" Then
		
		ColumnDataType.Insert("Barcode",					New TypeDescription("String",,	New StringQualifiers(200)));
		ColumnDataType.Insert("SKU",					New TypeDescription("String",,	New StringQualifiers(50)));
		ColumnDataType.Insert("ProductsAndServicesCode",			New TypeDescription("String",,	New StringQualifiers(11)));
		ColumnDataType.Insert("ItemName",	New TypeDescription("String",,	New StringQualifiers(100)));
		
		ColumnDataType.Insert("ItemVariantName",	New TypeDescription("String",,	New StringQualifiers(150)));
		ColumnDataType.Insert("PurposeDescription",		New TypeDescription("String",,	New StringQualifiers(150)));
		ColumnDataType.Insert("BatchName",			New TypeDescription("String",,	New StringQualifiers(150)));
		
		ColumnDataType.Insert("PackageCode",				New TypeDescription("String",,	New StringQualifiers(4)));
		ColumnDataType.Insert("PackageName",		New TypeDescription("String",,	New StringQualifiers(50)));
		
		ColumnDataType.Insert("NumberOfPackages",			New TypeDescription("Number",,	New NumberQualifiers(15, 3)));
		
	ElsIf TSName = "LaborCosts" Then
		
		ColumnDataType.Insert("WorkKindCode",				New TypeDescription("String",,	New StringQualifiers(9)));
		ColumnDataType.Insert("NameOfTypeOfWork",		New TypeDescription("String",,	New StringQualifiers(150)));
		
		ColumnDataType.Insert("Count",					New TypeDescription("Number",,	New NumberQualifiers(15, 3)));
		ColumnDataType.Insert("StandardAmount",			New TypeDescription("Number",,	New NumberQualifiers(15,2)));
		
	Else
		ColumnDataType.Insert("ExpenseItemCode",			New TypeDescription("String",,	New StringQualifiers(9)));
		ColumnDataType.Insert("NameOfExpenditureItem",	New TypeDescription("String",,	New StringQualifiers(100)));
	EndIf;
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	If AdditionalParameters.TSName = "MaterialsAndWorks" Then
		CompareUploadedDataMaterialsAndWorks(AddressOfUploadedData, AddressOfMappingTable, ConflictsList);
	ElsIf AdditionalParameters.TSName = "LaborCosts" Then
		CompareUploadedDataLaborCosts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList);
	ElsIf AdditionalParameters.TSName = "OtherExpenses" Then
		CompareDownloadableDataOtherExpenses(AddressOfUploadedData, AddressOfMappingTable, ConflictsList);
	EndIf;
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	TSName = AdditionalParameters.TSName;
	
	If TSName = "MaterialsAndWorks" Then
		FillInListOfAmbiguitiesMaterialsAndWorks(ConflictsList, ColumnName, LoadedValuesString);
	ElsIf TSName = "LaborCosts" Then
		FillInListOfAmbiguitiesLaborCosts(ConflictsList, ColumnName, LoadedValuesString);
	ElsIf TSName = "OtherExpenses" Then
		FillInListOfAmbiguitiesOtherExpenses(ConflictsList, ColumnName, LoadedValuesString);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region VATAccounting

// Initializing parameters for registering invoices received
//  Parameters:
//    ObjectData - DocumentObject.WIPOpeningBalancesByProductionLots - Object of the balance entry document
//
//  Returns:
//    See VATAccountingERPClientServer.ParametersForFillingInVATActivityType
Function ParametersForFillingInVATActivities(ObjectData) Export
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillParameters.Organization							= ObjectData.Organization;
	FillParameters.Date								= ObjectData.Date;
	FillParameters.LineOfBusiness				= ObjectData.LineOfBusiness;
	FillParameters.MovementOfGoodsAndWorksInProduction	= True;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region PurposesAndDirectionsOfActivity

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	// Template for materials.
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "Object.MaterialsAndWorks.Purpose");
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.Giveaway21));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterials22));
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.ProvidedMaterialsForStage22));
	// All appointments.
	Catalogs.Assignments.AddColumnDescription_(
		FormTemplate,
		"AllAssignments",
		True,
		"Object.MaterialsAndWorks.Purpose");
	
	Return FormTemplate;
	
EndFunction

// The procedure for processing changes in the direction of activity.
// 
// Parameters:
// 	Form - ClientApplicationForm
// Returns:
// 	See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "MaterialsAndWorks";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("MaterialsAndWorks", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

#EndRegion

#Region ArticleSelectionAndAnalytics

Function ItemsAndDimensionsSelectionParameters() Export
	
	// Output items
	ArticleSelectionOptions = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	
	ArticleSelectionOptions.DataPath					= "Object.OtherExpenses";
	ArticleSelectionOptions.AssetRef						= "ExpenseItem";
	ArticleSelectionOptions.ArticleType					= "ArticleType";
	
	ArticleSelectionOptions.ChoosingExpenseItem			= True;
	ArticleSelectionOptions.DimensionOfExpenses			= "DimensionOfExpenses";
	
	FormItems = ArticleSelectionOptions.FormItems;
	FormItems.AssetRef.Add("OtherExpensesExpenseItem");
	FormItems.DimensionOfExpenses.Add("OtherExpensesDimensionOfExpenses");
	
	Return ArticleSelectionOptions;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

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

#Region Private

#Region Posting

#Region Initialize

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)

	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);

	Query.Text =
	"SELECT
	|	Attributes.Date						AS Date,
	|	Attributes.Date						AS Period,
	|	Attributes.Number						AS Number,
	|	Attributes.Ref					AS Ref,
	|	Attributes.Posted					AS Posted,
	|	Attributes.DeletionMark			AS DeletionMark,
	|	Attributes.Organization				AS Organization,
	|	Attributes.Department				AS Department,
	|	Attributes.LineOfBusiness	AS LineOfBusiness,
	|	Attributes.VATActivityType		AS VATActivityType,
	|	Attributes.DocumentBasis			AS DocumentBasis,
	|	Attributes.DocumentAmount			AS DocumentAmount,
	|	Attributes.EmployeeResponsible				AS EmployeeResponsible,
	|	Attributes.Patch				AS Patch,
	|	Attributes.ReversedDocument		AS ReversedDocument,
	|	Attributes.CorrectedDocument		AS CorrectedDocument,
	|	Attributes.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	Attributes.Comment				AS Comment
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots AS Attributes
	|WHERE
	|	Attributes.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
								GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	Query.SetParameter("AnalyticalAccountingByProductsGroups",
								GetFunctionalOption("AnalyticalAccountingByProductsGroups"));
	
	Query.SetParameter("MetadataIdentifier",
							Common.MetadataObjectID(Type("DocumentRef.WIPOpeningBalancesByProductionLots")));
	
	Query.SetParameter("BusinessOperation",
							Enums.BusinessTransactions.OBEntryProductionLotCosts);
	
	Query.SetParameter("BusinessTransactionSetting",
							Catalogs.BusinessTransactionsSettings.OBEntryProductionLotCosts);
	
	Query.SetParameter("NumberForPrinting",	ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	Query.SetParameter("CurrencyOfMan",		Constants.ManagementAccountingCurrency.Get());
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Date);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
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
	// batch analysis of production without assignment
	|	SELECT DISTINCT
	|		GoodsTable.Ref.Department				AS Warehouse,
	|		GoodsTable.Products						AS Products,
	|		GoodsTable.Characteristic					AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)	AS Purpose,
	|		CASE
	|			WHEN GoodsTable.BatchesIndicationStatus = 14
	|				THEN GoodsTable.Series
	|			ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|		END											AS Series,
	|		GoodsTable.ProductCostElement					AS ProductCostElement
	|	FROM
	|		Document.WIPOpeningBalancesByProductionLots.MaterialsAndWorks AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref = &Ref
	|	) AS GoodsTable
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON GoodsTable.Products = Dimension.Products
	|	AND GoodsTable.Characteristic = Dimension.Characteristic
	|	AND GoodsTable.Series = Dimension.Series
	|	AND GoodsTable.Warehouse = Dimension.StorageLocation
	|	AND GoodsTable.Purpose = Dimension.Purpose
	|	AND GoodsTable.ProductCostElement = Dimension.ProductCostElement
	|
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
	
	AnalyticsRequest.SetParameter("Ref", Query.Parameters.Ref);
	AnalyticsRequest.SetParameter("Department", Query.Parameters.Department);
	
	Selection = AnalyticsRequest.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;

	Query.SetParameter("ProductAnalysisKeysInitialized", True);
	
EndProcedure

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.WIPOpeningBalancesByProductionLots";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("CurrencyOfMan", Constants.ManagementAccountingCurrency.Get());
	ParameterValues.Insert("BusinessOperation", Enums.BusinessTransactions.OBEntryProductionLotCosts);
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Undefined, QueryTexts, Undefined);
		RequestHasSource	= False;
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName%, chưa thực hiện điều chỉnh nội dung truy vấn 
								|tạo các bản ghi kết chuyển theo biểu ghi %RegisterName%.';
								|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса 
								|формирования движений по регистру %RegisterName%.';
								|en = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.'; fa = 'In the %FullDocumentName% document, adaptation of request for generating records 
								|of the %RegisterName% register is not implemented.';
								|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento del testo di richiesta 
								|della generazione dei movimenti sul registro%RegisterName%.';
								|pl = 'W dokumencie %FullDocumentName%nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów 
								| w rejestrze %RegisterName%.';
								|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi 
								|talebinin metin uyarlaması uygulanmadı.'");
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ConductingLocalAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - query text.
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return WIPOpeningBalancesByProductionLotsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
// 
// Returns:
// 	See WIPOpeningBalancesByProductionLotsLocalization.RequestTextTTReflectedInLocalAccounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return WIPOpeningBalancesByProductionLotsLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region TextsOfRequestsForHolding

#Region QueryTextsTemporaryTables

Function QueryTextTTProducts_1(Query, QueryTexts)
	
	RegisterName = "TTProducts_1";
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText =
	"SELECT
	|	GoodsTable.ItemsLocationAttributes					AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey						AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	GoodsTable.InventoryOwnerAttribute									AS InventoryOwnerAttribute,
	|	GoodsTable.ProductionLot							AS ProductionLot,
	|	CASE
	|		WHEN NOT CatProductionLots.ProductsGroup = VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)
	|			THEN CatProductionLots.ProductsGroup
	|		ELSE UNDEFINED
	|	END														AS FinancialAccountingDimension,
	|	(CASE
	|		WHEN CatProductionLots.VATActivityType = VALUE(Enum.VATTaxationTypes.EmptyRef)
	|			THEN &TaxationOfOrganization
	|		ELSE CatProductionLots.VATActivityType END) 	AS VATActivityType,
	|	GoodsTable.ProductCostElement								AS ProductCostElement,
	|	GoodsTable.Count									AS Count,
	|	GoodsTable.Sum											AS Cost,
	|	GoodsTable.Sum											AS CostExcludingVAT,
	|	GoodsTable.SumCompl										AS LocalCost,
	|	GoodsTable.AmountPermanentDifferences										AS PermanentDifference,
	|	GoodsTable.AmountTemporaryDifferences										AS CostTD,
	|	0															AS VATLocal,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN GoodsTable.Sum
	|		ELSE 0
	|	END														AS CostMan,
	|	0															AS VATManag,
	|	GoodsTable.RowID						AS RowID
	|INTO TTProducts_1
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.MaterialsAndWorks AS GoodsTable
	|
	|	INNER JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Ref = GoodsTable.ProductionLot
	|	
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON Dimension.Ref = GoodsTable.ItemsLocationAttributes
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|	ON AnalyticsWithoutAssignment.Products = Dimension.Products
	|	AND AnalyticsWithoutAssignment.Characteristic = Dimension.Characteristic
	|	AND AnalyticsWithoutAssignment.Series = Dimension.Series
	|	AND AnalyticsWithoutAssignment.StorageLocation = Dimension.StorageLocation
	|	AND AnalyticsWithoutAssignment.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|	AND AnalyticsWithoutAssignment.ProductCostElement = Dimension.ProductCostElement
	|
	|WHERE
	|	GoodsTable.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

Function QueryTextTableOtherWorkInProgressExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherWorkInProgressExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	OtherExpenses.Period AS Period,
	|	OtherExpenses.RecordType AS RecordType,
	|	OtherExpenses.Organization AS Organization,
	|	OtherExpenses.Department AS Department,
	|	OtherExpenses.ExpenseItem AS ExpenseItem,
	|	OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness AS LineOfBusiness,
	|	OtherExpenses.ProductionLot AS ProductionLot,
	|	OtherExpenses.ProductCostElement AS ProductCostElement,
	|	OtherExpenses.ProductsGroup AS ProductsGroup,
	|	OtherExpenses.RuleOfCostAllocatingToProductionLots AS RuleOfCostAllocatingToProductionLots,
	|	SUM(OtherExpenses.Cost) AS Cost,
	|	SUM(OtherExpenses.CostExcludingVAT) AS CostExcludingVAT,
	|	SUM(OtherExpenses.LocalCost) AS LocalCost,
	|	SUM(OtherExpenses.PermanentDifference) AS PermanentDifference,
	|	SUM(OtherExpenses.CostTD) AS CostTD,
	|	SUM(OtherExpenses.CostMan) AS CostMan,
	|	OtherExpenses.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	(SELECT
	|		&Date AS Period,
	|		VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|		&Organization AS Organization,
	|		&Department AS Department,
	|		OtherExpenses.ExpenseItem AS ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses AS DimensionOfExpenses,
	|		OtherExpenses.ProductionLot.LineOfBusiness AS LineOfBusiness,
	|		OtherExpenses.ProductionLot AS ProductionLot,
	|		OtherExpenses.ProductCostElement AS ProductCostElement,
	|		OtherExpenses.ProductionLot.ProductsGroup AS ProductsGroup,
	|		OtherExpenses.RuleOfCostAllocatingToProductionLotsMan AS RuleOfCostAllocatingToProductionLots,
	|		OtherExpenses.Sum AS Cost,
	|		OtherExpenses.Sum AS CostExcludingVAT,
	|		0 AS LocalCost,
	|		0 AS PermanentDifference,
	|		0 AS CostTD,
	|		CASE
	|			WHEN &CompanyManagementAccounting
	|				THEN OtherExpenses.Sum
	|			ELSE 0
	|		END AS CostMan,
	|		OtherExpenses.RowID AS RowID
	|	FROM
	|		Document.WIPOpeningBalancesByProductionLots.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		&Date,
	|		VALUE(AccumulationRecordType.Receipt),
	|		&Organization,
	|		&Department,
	|		OtherExpenses.ExpenseItem,
	|		OtherExpenses.DimensionOfExpenses,
	|		OtherExpenses.ProductionLot.LineOfBusiness,
	|		OtherExpenses.ProductionLot,
	|		OtherExpenses.ProductCostElement,
	|		OtherExpenses.ProductionLot.ProductsGroup,
	|		OtherExpenses.RuleOfCostAllocatingToProductionLotsLocal,
	|		0,
	|		0,
	|		OtherExpenses.SumCompl,
	|		OtherExpenses.AmountPermanentDifferences,
	|		OtherExpenses.AmountTemporaryDifferences,
	|		0,
	|		OtherExpenses.RowID
	|	FROM
	|		Document.WIPOpeningBalancesByProductionLots.OtherExpenses AS OtherExpenses
	|	WHERE
	|		OtherExpenses.Ref = &Ref) AS OtherExpenses
	|
	|GROUP BY
	|	OtherExpenses.DimensionOfExpenses,
	|	OtherExpenses.LineOfBusiness,
	|	OtherExpenses.ProductionLot,
	|	OtherExpenses.RecordType,
	|	OtherExpenses.Organization,
	|	OtherExpenses.ProductCostElement,
	|	OtherExpenses.ProductsGroup,
	|	OtherExpenses.RuleOfCostAllocatingToProductionLots,
	|	OtherExpenses.Period,
	|	OtherExpenses.Department,
	|	OtherExpenses.ExpenseItem,
	|	OtherExpenses.RowID";
	
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
	|	&Ref									AS Ref,
	|	UNDEFINED							AS RecordSeparator,
	|	&Date									AS IBDocumentDate,
	|	&Number									AS IBDocumentNumber,
	|	&MetadataIdentifier				AS RefType,
	|	&Organization							AS Organization,
	|	&BusinessOperation				AS BusinessOperation,
	|	&LineOfBusiness				AS LineOfBusiness,
	|	&Department							AS Department,
	|	&EmployeeResponsible							AS EmployeeResponsible,
	|	CAST(&Comment AS STRING(100))	AS Comment,
	|	&CurrencyOfMan								AS Currency,
	|	&DocumentAmount							AS Sum,
	|	&Posted								AS Posted,
	|	&DeletionMark						AS DeletionMark,
	|	FALSE									AS AdditionalRecord,
	|	""""									AS More,
	|	&Date									AS SourceDocumentDate,
	|	&NumberForPrinting							AS SourceDocumentNumber,
	|	&Department							AS StorageLocation,
	|	&Patch							AS ReverseTransactionCorrection,
	|	&ReversedDocument					AS ReversedDocument,
	|	&CorrectedDocument					AS CorrectedDocument,
	|	&Date									AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableWIPLaborCosts(Query, QueryTexts, Registers)
	
	RegisterName = "WIPLaborCosts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Date									AS Period,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Organization							AS Organization,
	|	&Department							AS Department,
	|	LaborCosts.WorkKind					AS WorkKind,
	|	LaborCosts.ProductionLot			AS ProductionLot,
	|	LaborCosts.ProductCostElement			AS ProductCostElement,
	|	LaborCosts.ProductionLot.ProductsGroup AS ProductsGroup,
	|	LaborCosts.Count					AS Count,
	|	LaborCosts.StandardAmount			AS StandardCost,
	|	LaborCosts.Sum						AS Cost,
	|	LaborCosts.SumCompl					AS LocalCost,
	|	LaborCosts.AmountPermanentDifferences						AS PermanentDifference,
	|	LaborCosts.AmountTemporaryDifferences						AS CostTD,
	|	LaborCosts.RowID		AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots.LaborCosts AS LaborCosts
	|
	|WHERE
	|	LaborCosts.Ref = &Ref
	|";
	
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
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTProducts_1");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTProducts_1(Query, QueryTexts);
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
	|	TableTypesOfStocks_.ProductionLot			AS Lot,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	DocumentTable.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 							AS LotVendorAttributes,
	|	UNDEFINED 							AS LotVendorAttributesCorr,
	|	0 										AS RowCode,
	|
	// Corresponding fields
	|	UNDEFINED						AS CorItemsLocationAttributes,
	|	UNDEFINED						AS CorInventoryOwnerAttribute,
	|	UNDEFINED						AS CorGroupOfManufacturedProducts,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 											AS SalesOpportunity,
	|	UNDEFINED 											AS Department,
	|	UNDEFINED 											AS Manager,
	|	TableTypesOfStocks_.ProductionLot.ProductsGroup 	AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 						 		AS Count,
	|	UNDEFINED 				 								AS RowID,
	|	TableTypesOfStocks_.Cost 						 		AS Cost,
	|	TableTypesOfStocks_.CostExcludingVAT 						 	AS CostExcludingVAT,
	|	TableTypesOfStocks_.LocalCost 							AS LocalCost,
	|	TableTypesOfStocks_.VATLocal                                  AS VATLocal,
	|	TableTypesOfStocks_.CostMan 						 	AS CostMan,
	|	TableTypesOfStocks_.VATManag 									AS VATManag,
	|	0 													 		AS OffBalanceCost,
	|	0 													 		AS OffBalanceCostLocal,
	|	0													 		AS AddExpensesForGoods,
	|	0													 		AS AdditionalExpensesExcludingVAT,
	|	0															AS AddExpensesLocal,
	|	0															AS AddExpensesMan,
	|	TableTypesOfStocks_.PermanentDifference 						AS PermanentDifference,
	|	TableTypesOfStocks_.CostTD 						AS CostTD,
	|	0													 		AS CorGrossInitialCostENT,
	|
	// Other fields
	|	&BusinessOperation									AS BusinessOperation,
	|	TableTypesOfStocks_.RowID					AS FinRecordID,
	|	&BusinessTransactionSetting							AS BusinessTransactionSetting
	|
	|FROM
	|	Document.WIPOpeningBalancesByProductionLots AS DocumentTable
	|	INNER JOIN TTProducts_1 AS TableTypesOfStocks_
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

#EndRegion

#Region StandardCommandSubsystems

#Region DownloadingFromVHFFile

Procedure CompareUploadedDataMaterialsAndWorks(AddressOfUploadedData, AddressOfMappingTable, ConflictsList)
	
	MaterialsAndWorks	= GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport	= GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTUploadedDataMaterialsAndWorks());
	QueryTexts.Add(QueryTextTTBatchDocumentData());
	QueryTexts.Add(QueryTextTTBarcodeData());
	QueryTexts.Add(QueryTextTTProductData());
	QueryTexts.Add(QueryTextTTCharacteristicsData());
	QueryTexts.Add(QueryTextTTDestinationData());
	QueryTexts.Add(QueryTextTTSeriesData());
	QueryTexts.Add(QueryTextTTPackingData());
	QueryTexts.Add(QueryTextTTDataProductCostElements());
	QueryTexts.Add(RequestTextUploadedMaterialsAndWorkData());
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",				DataToImport);
	Query.SetParameter("TextProductionOrder",		NStr("vi = 'Đơn hàng sản xuất';
															|ru = 'Заказ на производство';
															|en = 'Production order'; fa = 'سفارش تولید';
															|it = 'Ordine di produzione';
															|pl = 'Zlecenie produkcyjne';
															|tr = 'Üretim emri'"));
	
	
	Query.SetParameter("TextProcessorReport2_5",		NStr("vi = 'Bảng kê hàng hóa của người nhận gia công';
															|ru = 'Отчет переработчика';
															|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
															|it = 'Report subfornitore';
															|pl = 'Raport przetwórcy';
															|tr = 'Alınan fason hizmetleri bildirimi'"));
	Query.SetParameter("TextProductionWithoutOrder",		NStr("vi = 'Sản xuất không có đơn hàng';
																|ru = 'Производство без заказа';
																|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																|it = 'Produzione senza ordine';
																|pl = 'Produkcja bez zamówień';
																|tr = 'Geriye dönük üretim'"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = MaterialsAndWorks.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.QuantityOfProducts > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Products";
		EndIf;
		
		If Selection.NumberOfCharacteristics > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Characteristic";
		EndIf;
		
		If Selection.NumberOfAppointments > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Purpose";
		EndIf;
		
		If Selection.SeriesCount > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Series";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ProductCostElement";
		EndIf;
		
		If Selection.PackingQuantity > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "Package";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(MaterialsAndWorks, AddressOfMappingTable);
	
EndProcedure

Procedure CompareUploadedDataLaborCosts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList)
	
	LaborCosts		= GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport	= GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTUploadedDataLaborCosts());
	QueryTexts.Add(QueryTextTTBatchDocumentData());
	QueryTexts.Add(QueryTextTTDataTypesOfWork());
	QueryTexts.Add(QueryTextTTDataProductCostElements());
	QueryTexts.Add(RequestTextUploadedDataLaborCosts());
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",				DataToImport);
	Query.SetParameter("TextProductionOrder",		NStr("vi = 'Đơn hàng sản xuất';
															|ru = 'Заказ на производство';
															|en = 'Production order'; fa = 'سفارش تولید';
															|it = 'Ordine di produzione';
															|pl = 'Zlecenie produkcyjne';
															|tr = 'Üretim emri'"));
	
	
	Query.SetParameter("TextProcessorReport2_5",		NStr("vi = 'Bảng kê hàng hóa của người nhận gia công';
															|ru = 'Отчет переработчика';
															|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
															|it = 'Report subfornitore';
															|pl = 'Raport przetwórcy';
															|tr = 'Alınan fason hizmetleri bildirimi'"));
	Query.SetParameter("TextProductionWithoutOrder",		NStr("vi = 'Sản xuất không có đơn hàng';
																|ru = 'Производство без заказа';
																|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																|it = 'Produzione senza ordine';
																|pl = 'Produkcja bez zamówień';
																|tr = 'Geriye dönük üretim'"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = LaborCosts.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.NumberOfWorkKinds > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "WorkKind";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ProductCostElement";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(LaborCosts, AddressOfMappingTable);
	
EndProcedure

Procedure CompareDownloadableDataOtherExpenses(AddressOfUploadedData, AddressOfMappingTable, ConflictsList)
	
	OtherExpenses		= GetFromTempStorage(AddressOfMappingTable); // ValueTable
	DataToImport	= GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTUploadedDataOtherExpenses());
	QueryTexts.Add(QueryTextTTBatchDocumentData());
	QueryTexts.Add(QueryTextTTDataOfExpenditureItems());
	QueryTexts.Add(QueryTextTTDataProductCostElements());
	QueryTexts.Add(RequestTextUploadedDataOtherExpenses());
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",				DataToImport);
	Query.SetParameter("TextProductionOrder",		NStr("vi = 'Đơn hàng sản xuất';
															|ru = 'Заказ на производство';
															|en = 'Production order'; fa = 'سفارش تولید';
															|it = 'Ordine di produzione';
															|pl = 'Zlecenie produkcyjne';
															|tr = 'Üretim emri'"));
	
	
	Query.SetParameter("TextProcessorReport2_5",		NStr("vi = 'Bảng kê hàng hóa của người nhận gia công';
															|ru = 'Отчет переработчика';
															|en = 'Subcontracting services notification received'; fa = 'اعلامیه خدمات پیمانکاری فرعی دریافت‌شده';
															|it = 'Report subfornitore';
															|pl = 'Raport przetwórcy';
															|tr = 'Alınan fason hizmetleri bildirimi'"));
	Query.SetParameter("TextProductionWithoutOrder",		NStr("vi = 'Sản xuất không có đơn hàng';
																|ru = 'Производство без заказа';
																|en = 'Backflush production'; fa = 'تولید با کسر خودکار مواد';
																|it = 'Produzione senza ordine';
																|pl = 'Produkcja bez zamówień';
																|tr = 'Geriye dönük üretim'"));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = OtherExpenses.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.NumberOfExpenditureItems > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ExpenseItem";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity					= ConflictsList.Add();
			WritingAboutAmbiguity.Id	= Selection.Id;
			WritingAboutAmbiguity.Column			= "ProductCostElement";
		EndIf;
		
	EndDo;
	
	PutToTempStorage(OtherExpenses, AddressOfMappingTable);
	
EndProcedure

Procedure FillInListOfAmbiguitiesMaterialsAndWorks(ConflictsList, ColumnName, LoadedValuesString)
	
	Query = New Query;
	
	If ColumnName = "Products" Then
		
		Query.Text =
		"SELECT
		|	Barcodes.Products			AS Products,
		|	Barcodes.Characteristic		AS Characteristic,
		|	Barcodes.Package				AS Package,
		|	Barcodes.Series					AS Series
		|INTO TTBarcodeData
		|FROM
		|	InformationRegister.ItemsBarcodes AS Barcodes
		|
		|WHERE
		|	NOT &Barcode = """"
		|	AND Barcodes.Barcode = &Barcode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref AS Ref
		|FROM
		|	(SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &SKU = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.SKU = &SKU
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &ProductsAndServicesCode = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Code = &ProductsAndServicesCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &ItemName = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Description = &ItemName
		|
		|	UNION ALL
		|
		|	SELECT
		|		BarcodeData_5.Products AS Ref
		|	FROM
		|		TTBarcodeData AS BarcodeData_5
		|	) AS CatProducts
		|
		|GROUP BY
		|	CatProducts.Ref
		|";
		
		Query.SetParameter("Barcode",					LoadedValuesString.Barcode);
		Query.SetParameter("SKU",					LoadedValuesString.SKU);
		Query.SetParameter("ProductsAndServicesCode",			LoadedValuesString.ProductsAndServicesCode);
		Query.SetParameter("ItemName",	LoadedValuesString.ItemName);
		
	EndIf;
	
	If ColumnName = "Characteristic" Then
		
		Query.Text =
		"SELECT
		|	Characteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|WHERE
		|	NOT &ItemVariantName = """"
		|	AND Characteristics.Description = &ItemVariantName
		|";
		
		Query.SetParameter("ItemVariantName",	LoadedValuesString.ItemVariantName);
		
	EndIf;
	
	If ColumnName = "Purpose" Then
		
		Query.Text =
		"SELECT
		|	CatAssignments.Ref AS Ref
		|FROM
		|	Catalog.Assignments AS CatAssignments
		|
		|WHERE
		|	NOT &PurposeDescription = """"
		|	AND CatAssignments.Description = &PurposeDescription
		|";
		
		Query.SetParameter("PurposeDescription",	LoadedValuesString.PurposeDescription);
		
	EndIf;
	
	If ColumnName = "Series" Then
		
		Query.Text =
		"SELECT
		|	CatSetOfSeries.Ref AS Ref
		|FROM
		|	Catalog.ItemsBatches AS CatSetOfSeries
		|
		|WHERE
		|	NOT &BatchName = """"
		|	AND CatSetOfSeries.Description = &BatchName
		|";
		
		Query.SetParameter("BatchName",	LoadedValuesString.BatchName);
		
	EndIf;
	
	If ColumnName = "ProductCostElement" Then
		
		Query.Text =
		"SELECT
		|	CatProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS CatProductCostElements
		|
		|WHERE
		|	NOT &NameOfCalculationArticle = """"
		|	AND CatProductCostElements.Description = &NameOfCalculationArticle
		|";
		
		Query.SetParameter("NameOfCalculationArticle",	LoadedValuesString.NameOfCalculationArticle);
		
	EndIf;
	
	If ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	(SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageCode = """"
		|		AND Packages.Code = &PackageCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageName = """"
		|		AND Packages.Description = &PackageName
		|	) AS Packages
		|
		|GROUP BY
		|	Packages.Ref
		|";
		
		Query.SetParameter("PackageCode",			LoadedValuesString.PackageCode);
		Query.SetParameter("PackageName",	LoadedValuesString.PackageName);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInListOfAmbiguitiesLaborCosts(ConflictsList, ColumnName, LoadedValuesString)
	
	Query = New Query;
	
	If ColumnName = "ProductCostElement" Then
		
		Query.Text =
		"SELECT
		|	CatProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS CatProductCostElements
		|
		|WHERE
		|	NOT &NameOfCalculationArticle = """"
		|	AND CatProductCostElements.Description = &NameOfCalculationArticle
		|";
		
		Query.SetParameter("NameOfCalculationArticle",	LoadedValuesString.NameOfCalculationArticle);
		
	EndIf;
	
	If ColumnName = "WorkKind" Then
		
		Query.Text =
		"SELECT
		|	ActivityKinds.Ref AS Ref
		|FROM
		|	(SELECT
		|		ActivityKinds.Ref AS Ref
		|	FROM
		|		Catalog.EmployeeWorkKinds AS ActivityKinds
		|
		|	WHERE
		|		NOT &WorkKindCode = """"
		|		AND ActivityKinds.Code = &WorkKindCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		ActivityKinds.Ref AS Ref
		|	FROM
		|		Catalog.EmployeeWorkKinds AS ActivityKinds
		|
		|	WHERE
		|		NOT &NameOfTypeOfWork = """"
		|		AND ActivityKinds.Description = &NameOfTypeOfWork
		|	) AS ActivityKinds
		|
		|GROUP BY
		|	ActivityKinds.Ref
		|";
		
		Query.SetParameter("WorkKindCode",			LoadedValuesString.WorkKindCode);
		Query.SetParameter("NameOfTypeOfWork",	LoadedValuesString.NameOfTypeOfWork);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInListOfAmbiguitiesOtherExpenses(ConflictsList, ColumnName, LoadedValuesString)
	
	Query = New Query;
	
	If ColumnName = "ProductCostElement" Then
		
		Query.Text =
		"SELECT
		|	CatProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS CatProductCostElements
		|
		|WHERE
		|	NOT &NameOfCalculationArticle = """"
		|	AND CatProductCostElements.Description = &NameOfCalculationArticle
		|";
		
		Query.SetParameter("NameOfCalculationArticle",	LoadedValuesString.NameOfCalculationArticle);
		
	EndIf;
	
	If ColumnName = "ExpenseItem" Then
		
		Query.Text =
		"SELECT
		|	ExpenseItems.Ref AS Ref
		|FROM
		|	(SELECT
		|		ExpenseItems.Ref AS Ref
		|	FROM
		|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|
		|	WHERE
		|		NOT &ExpenseItemCode = """"
		|		AND ExpenseItems.Code = &ExpenseItemCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		ExpenseItems.Ref AS Ref
		|	FROM
		|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
		|
		|	WHERE
		|		NOT &NameOfExpenditureItem = """"
		|		AND ExpenseItems.Description = &NameOfExpenditureItem
		|	) AS ExpenseItems
		|
		|GROUP BY
		|	ExpenseItems.Ref
		|";
		
		Query.SetParameter("ExpenseItemCode",			LoadedValuesString.ExpenseItemCode);
		Query.SetParameter("NameOfExpenditureItem",	LoadedValuesString.NameOfExpenditureItem);
		
	EndIf;
	
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#Region DownloadRequestTextsFromVHFFile

#Region TextsOfDownloadRequestsFromVHFFileAreGeneral

Function QueryTextTTBatchDocumentData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id					AS Id,
	|	CASE
	|		WHEN OrderDetails.Ref IS NOT NULL
	|			THEN OrderDetails.Ref
	|		WHEN ProcessorSReportDetails2_5.Ref IS NOT NULL
	|			THEN ProcessorSReportDetails2_5.Ref
	|		WHEN ProductionDetailsWithoutOrder.Ref IS NOT NULL
	|			THEN ProductionDetailsWithoutOrder.Ref
	|		ELSE UNDEFINED
	|	END											AS DocumentLots
	|INTO TTBatchDocumentData
	|FROM
	|	TTDownloadableData AS DataToImport
	|
	|	LEFT JOIN Document.ProductionOrder2_2 AS OrderDetails
	|	ON DataToImport.DocumentType = &TextProductionOrder
	|	AND OrderDetails.Date = DataToImport.DocumentDate
	|	AND OrderDetails.Number = DataToImport.DocumentNumber
	|
	|
	|	LEFT JOIN Document.SubcontractorReport2_5 AS ProcessorSReportDetails2_5
	|	ON DataToImport.DocumentType = &TextProcessorReport2_5
	|	AND ProcessorSReportDetails2_5.Date = DataToImport.DocumentDate
	|	AND ProcessorSReportDetails2_5.Number = DataToImport.DocumentNumber
	|
	|	LEFT JOIN Document.BackflushProduction AS ProductionDetailsWithoutOrder
	|	ON DataToImport.DocumentType = &TextProductionWithoutOrder
	|	AND ProductionDetailsWithoutOrder.Date = DataToImport.DocumentDate
	|	AND ProductionDetailsWithoutOrder.Number = DataToImport.DocumentNumber
	|
	|INDEX BY
	|	Id,
	|	DocumentLots
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataProductCostElements()
	
	QueryText =
	"SELECT
	|	DataToImport.Id						AS Id,
	|	MAX(CatProductCostElements.Ref)				AS ProductCostElement,
	|	COUNT(DISTINCT CatProductCostElements.Ref)	AS NumberOfCalculationArticles
	|INTO TTDataProductCostElements
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN Catalog.ProductCostElements AS CatProductCostElements
	|	ON CatProductCostElements.Description = DataToImport.NameOfCalculationArticle
	|
	|WHERE
	|	NOT DataToImport.NameOfCalculationArticle = """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TextsOfRequestsToDownloadFromVHFFileMaterialsAndWorks

Function RequestTextTTUploadedDataMaterialsAndWorks()
	
	QueryText =
	"SELECT
	|	DataToImport.Id					AS Id,
	|	DataToImport.DocumentType					AS DocumentType,
	|	DataToImport.DocumentDate					AS DocumentDate,
	|	DataToImport.DocumentNumber				AS DocumentNumber,
	|	DataToImport.CostGroupNumber				AS CostGroupNumber,
	|	DataToImport.NameOfCalculationArticle	AS NameOfCalculationArticle,
	|	DataToImport.Sum							AS Sum,
	|	DataToImport.Barcode						AS Barcode,
	|	DataToImport.SKU						AS SKU,
	|	DataToImport.ProductsAndServicesCode				AS ProductsAndServicesCode,
	|	DataToImport.ItemName		AS ItemName,
	|	DataToImport.ItemVariantName	AS ItemVariantName,
	|	DataToImport.PurposeDescription		AS PurposeDescription,
	|	DataToImport.BatchName				AS BatchName,
	|	DataToImport.PackageCode					AS PackageCode,
	|	DataToImport.PackageName			AS PackageName,
	|	DataToImport.NumberOfPackages			AS NumberOfPackages
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBarcodeData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id	AS Id,
	|	Barcodes.Products			AS Products,
	|	Barcodes.Characteristic		AS Characteristic,
	|	Barcodes.Series					AS Series,
	|	Barcodes.Package				AS Package
	|INTO TTBarcodeData
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|	ON Barcodes.Barcode = DataToImport.Barcode
	|
	|WHERE
	|	NOT DataToImport.Barcode = """"
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductData()
	
	QueryText =
	"SELECT
	|	CatProducts.Id						AS Id,
	|	MAX(CatProducts.Products)				AS Products,
	|	COUNT(DISTINCT CatProducts.Products)	AS QuantityOfProducts
	|INTO TTProductData
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		CatProducts.Ref			AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.SKU
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.SKU = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		CatProducts.Ref			AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ProductsAndServicesCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		CatProducts.Ref			AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.ItemName
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ItemName = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id	AS Id,
	|		BarcodeData_5.Products	AS Products
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS CatProducts
	|
	|GROUP BY
	|	CatProducts.Id
	|
	|INDEX BY
	|	Id,
	|	Products
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCharacteristicsData()
	
	QueryText =
	"SELECT
	|	Characteristics.Id						AS Id,
	|	MAX(Characteristics.Characteristic)				AS Characteristic,
	|	COUNT(DISTINCT Characteristics.Characteristic)	AS NumberOfCharacteristics
	|INTO TTCharacteristicsData
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		Characteristics.Ref			AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = ProductData_1.Products
	|		AND Characteristics.Description = DataToImport.ItemVariantName
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ItemVariantName = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		Characteristics.Ref			AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = ProductData_1.Products.ProductKind
	|		AND Characteristics.Description = DataToImport.ItemVariantName
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ItemVariantName = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id	AS Id,
	|		BarcodeData_5.Characteristic	AS Characteristic
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Characteristics
	|
	|GROUP BY
	|	Characteristics.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDestinationData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id				AS Id,
	|	MAX(CatAssignments.Ref)				AS Purpose,
	|	COUNT(DISTINCT CatAssignments.Ref)	AS NumberOfAppointments
	|INTO TTDestinationData
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN Catalog.Assignments AS CatAssignments
	|	ON CatAssignments.Description = DataToImport.PurposeDescription
	|
	|WHERE
	|	NOT DataToImport.PurposeDescription = """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTSeriesData()
	
	QueryText =
	"SELECT
	|	ItemsBatches.Id					AS Id,
	|	MAX(ItemsBatches.Series)				AS Series,
	|	COUNT(DISTINCT ItemsBatches.Series)	AS SeriesCount
	|INTO TTSeriesData
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		ItemsBatches.Ref		AS Series
	|	FROM
	|		TTDownloadableData AS DataToImport
	|			INNER JOIN TTProductData AS ProductData_1
	|			ON DataToImport.Id = ProductData_1.Id
	|			
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON ProductData_1.Products = CatalogProducts.Ref
	|			
	|			LEFT JOIN TTBarcodeData AS BarcodeData_5
	|			ON DataToImport.Id = BarcodeData_5.Id
	|			
	|			INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|			ON CatalogProducts.ProductKind = ItemsBatches.ProductKind
	|				AND DataToImport.BatchName = ItemsBatches.Description
	|	
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.BatchName = """"
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		ItemsBatches.Ref		AS Series
	|	FROM
	|		TTDownloadableData AS DataToImport
	|			INNER JOIN TTProductData AS ProductData_1
	|			ON DataToImport.Id = ProductData_1.Id
	|			
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON ProductData_1.Products = CatalogProducts.Ref
	|			
	|			LEFT JOIN TTBarcodeData AS BarcodeData_5
	|			ON DataToImport.Id = BarcodeData_5.Id
	|			
	|			INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|			ON CatalogProducts.BatchOwner = ItemsBatches.ProductKind
	|				AND DataToImport.BatchName = ItemsBatches.Description
	|	
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.BatchName = """"
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		ItemsBatches.Ref		AS Series
	|	FROM
	|		TTDownloadableData AS DataToImport
	|			INNER JOIN TTProductData AS ProductData_1
	|			ON DataToImport.Id = ProductData_1.Id
	|			
	|			INNER JOIN Catalog.Products AS CatalogProducts
	|			ON ProductData_1.Products = CatalogProducts.Ref
	|			
	|			INNER JOIN Catalog.ItemKinds AS TypesOfGoodsItems
	|			ON CatalogProducts.ProductKind = TypesOfGoodsItems.Ref
	|			
	|			LEFT JOIN TTBarcodeData AS BarcodeData_5
	|			ON DataToImport.Id = BarcodeData_5.Id
	|			
	|			INNER JOIN Catalog.ItemsBatches AS ItemsBatches
	|			ON DataToImport.BatchName = ItemsBatches.Description
	|			
	|			INNER JOIN Catalog.ItemKinds AS TypesOfBatchItem
	|			ON ItemsBatches.ProductKind = TypesOfBatchItem.Ref
	|				AND TypesOfGoodsItems.BatchOwner = TypesOfBatchItem.BatchOwner
	|				AND TypesOfGoodsItems.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|				AND TypesOfBatchItem.BatchOwner <> VALUE(Catalog.ItemKinds.EmptyRef)
	|	
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.BatchName = """"
	|	
	|	UNION ALL
	|	
	|	SELECT DISTINCT
	|		BarcodeData_5.Id	AS Id,
	|		BarcodeData_5.Series			AS Series
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	
	|	) AS ItemsBatches
	|
	|GROUP BY
	|	ItemsBatches.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPackingData()
	
	QueryText =
	"SELECT
	|	Packages.Id					AS Id,
	|	MAX(Packages.Package)				AS Package,
	|	COUNT(DISTINCT Packages.Package)	AS PackingQuantity
	|INTO TTPackingData
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Description = DataToImport.PackageName
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageName = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Description = DataToImport.PackageName
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageName = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		Packages.Ref					AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id	AS Id,
	|		BarcodeData_5.Package		AS Package
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextUploadedMaterialsAndWorkData()
	
	QueryText =
	"SELECT
	|	DataToImport.Id								AS Id,
	|	CatProductionLots.Ref								AS ProductionLot,
	|	CASE
	|		WHEN ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) = 1
	|			THEN DataForCalculation_.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END														AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(ProductData_1.QuantityOfProducts, 0) = 1
	|			THEN ProductData_1.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END														AS Products,
	|	CASE
	|		WHEN ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) = 1
	|			THEN CharacteristicsData.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END														AS Characteristic,
	|	CASE
	|		WHEN ISNULL(DestinationData.NumberOfAppointments, 0) = 1
	|			THEN DestinationData.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END														AS Purpose,
	|	CASE
	|		WHEN ISNULL(SeriesData_.SeriesCount, 0) = 1
	|			THEN SeriesData_.Series
	|		ELSE VALUE(Catalog.ItemsBatches.EmptyRef)
	|	END														AS Series,
	|	CASE
	|		WHEN ISNULL(PackageData_.PackingQuantity, 0) = 1
	|			THEN PackageData_.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END														AS Package,
	|	ISNULL(ProductData_1.QuantityOfProducts, 0)		AS QuantityOfProducts,
	|	ISNULL(CharacteristicsData.NumberOfCharacteristics, 0)	AS NumberOfCharacteristics,
	|	ISNULL(DestinationData.NumberOfAppointments, 0)			AS NumberOfAppointments,
	|	ISNULL(SeriesData_.SeriesCount, 0)					AS SeriesCount,
	|	ISNULL(PackageData_.PackingQuantity, 0)				AS PackingQuantity,
	|	ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) AS NumberOfCalculationArticles,
	|	DataToImport.NumberOfPackages						AS NumberOfPackages,
	|	DataToImport.Sum										AS Sum
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTBatchDocumentData AS BatchDocumentData
	|	ON BatchDocumentData.Id = DataToImport.Id
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = BatchDocumentData.DocumentLots
	|	AND CatProductionLots.Code = DataToImport.CostGroupNumber
	|	
	|	LEFT JOIN TTDataProductCostElements AS DataForCalculation_
	|	ON DataForCalculation_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTProductData AS ProductData_1
	|	ON ProductData_1.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTCharacteristicsData AS CharacteristicsData
	|	ON CharacteristicsData.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTDestinationData AS DestinationData
	|	ON DestinationData.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTSeriesData AS SeriesData_
	|	ON SeriesData_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTPackingData AS PackageData_
	|	ON PackageData_.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DownloadRequestTextsFromVHFFileLaborCosts

Function RequestTextTTUploadedDataLaborCosts()
	
	QueryText =
	"SELECT
	|	DataToImport.Id					AS Id,
	|	DataToImport.DocumentType					AS DocumentType,
	|	DataToImport.DocumentDate					AS DocumentDate,
	|	DataToImport.DocumentNumber				AS DocumentNumber,
	|	DataToImport.CostGroupNumber				AS CostGroupNumber,
	|	DataToImport.NameOfCalculationArticle	AS NameOfCalculationArticle,
	|	DataToImport.Sum							AS Sum,
	|	DataToImport.WorkKindCode					AS WorkKindCode,
	|	DataToImport.NameOfTypeOfWork			AS NameOfTypeOfWork,
	|	DataToImport.Count					AS Count,
	|	DataToImport.StandardAmount				AS StandardAmount
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataTypesOfWork()
	
	QueryText =
	"SELECT
	|	ActivityKinds.Id						AS Id,
	|	MAX(ActivityKinds.WorkKind)				AS WorkKind,
	|	COUNT(DISTINCT ActivityKinds.WorkKind)	AS NumberOfWorkKinds
	|INTO TTDataTypesOfWork
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		ActivityKinds.Ref				AS WorkKind
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON ActivityKinds.Code = DataToImport.WorkKindCode
	|
	|	WHERE
	|		NOT DataToImport.WorkKindCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		ActivityKinds.Ref				AS WorkKind
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON ActivityKinds.Description = DataToImport.NameOfTypeOfWork
	|
	|	WHERE
	|		NOT DataToImport.NameOfTypeOfWork = """"
	|	) AS ActivityKinds
	|
	|GROUP BY
	|	ActivityKinds.Id
	|
	|INDEX BY
	|	Id,
	|	WorkKind
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextUploadedDataLaborCosts()
	
	QueryText =
	"SELECT
	|	DataToImport.Id								AS Id,
	|	CatProductionLots.Ref								AS ProductionLot,
	|	CASE
	|		WHEN ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) = 1
	|			THEN DataForCalculation_.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END														AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(DataTypesOfWork.NumberOfWorkKinds, 0) = 1
	|			THEN DataTypesOfWork.WorkKind
	|		ELSE VALUE(Catalog.EmployeeWorkKinds.EmptyRef)
	|	END														AS WorkKind,
	|	ISNULL(DataTypesOfWork.NumberOfWorkKinds, 0)			AS NumberOfWorkKinds,
	|	ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) AS NumberOfCalculationArticles,
	|	DataToImport.Count								AS Count,
	|	CASE
	|		WHEN NOT DataToImport.Count = 0
	|			THEN CAST(DataToImport.StandardAmount / DataToImport.Count AS NUMBER(31,2))
	|		ELSE 0
	|	END														AS StandardRate,
	|	DataToImport.StandardAmount							AS StandardAmount,
	|	DataToImport.Sum										AS Sum
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTBatchDocumentData AS BatchDocumentData
	|	ON BatchDocumentData.Id = DataToImport.Id
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = BatchDocumentData.DocumentLots
	|	AND CatProductionLots.Code = DataToImport.CostGroupNumber
	|	
	|	LEFT JOIN TTDataProductCostElements AS DataForCalculation_
	|	ON DataForCalculation_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTDataTypesOfWork AS DataTypesOfWork
	|	ON DataTypesOfWork.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region TextsOfDownloadRequestsFromVHFFileOtherExpenses

Function RequestTextTTUploadedDataOtherExpenses()
	
	QueryText =
	"SELECT
	|	DataToImport.Id					AS Id,
	|	DataToImport.DocumentType					AS DocumentType,
	|	DataToImport.DocumentDate					AS DocumentDate,
	|	DataToImport.DocumentNumber				AS DocumentNumber,
	|	DataToImport.CostGroupNumber				AS CostGroupNumber,
	|	DataToImport.NameOfCalculationArticle	AS NameOfCalculationArticle,
	|	DataToImport.Sum							AS Sum,
	|	DataToImport.ExpenseItemCode				AS ExpenseItemCode,
	|	DataToImport.NameOfExpenditureItem	AS NameOfExpenditureItem
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataOfExpenditureItems()
	
	QueryText =
	"SELECT
	|	ExpenseItems.Id						AS Id,
	|	MAX(ExpenseItems.ExpenseItem)				AS ExpenseItem,
	|	COUNT(DISTINCT ExpenseItems.ExpenseItem)	AS NumberOfExpenditureItems
	|INTO TTDataOfExpenditureItems
	|FROM
	|	(SELECT
	|		DataToImport.Id	AS Id,
	|		ExpenseItems.Ref			AS ExpenseItem
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Code = DataToImport.ExpenseItemCode
	|
	|	WHERE
	|		NOT DataToImport.ExpenseItemCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id	AS Id,
	|		ExpenseItems.Ref			AS ExpenseItem
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON ExpenseItems.Description = DataToImport.NameOfExpenditureItem
	|
	|	WHERE
	|		NOT DataToImport.NameOfExpenditureItem = """"
	|	) AS ExpenseItems
	|
	|GROUP BY
	|	ExpenseItems.Id
	|
	|INDEX BY
	|	Id,
	|	ExpenseItem
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextUploadedDataOtherExpenses()
	
	QueryText =
	"SELECT
	|	DataToImport.Id								AS Id,
	|	CatProductionLots.Ref								AS ProductionLot,
	|	CASE
	|		WHEN ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) = 1
	|			THEN DataForCalculation_.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END														AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			THEN DataOfExpenditureItems.ExpenseItem
	|		ELSE VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|	END														AS ExpenseItem,
	|	CASE
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			AND DataOfExpenditureItems.ExpenseItem.CostSharingRule.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.MaterialCostsAmount),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardMaterialConsumption),
	|				VALUE(Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialCosts)
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			AND DataOfExpenditureItems.ExpenseItem.CostSharingRule.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses),
	|				VALUE(Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds),
	|				VALUE(Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel),
	|				VALUE(Enum.TypesOfCostAllocatingBase.WorkPerformanceDuration))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByLaborCosts)
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			AND DataOfExpenditureItems.ExpenseItem.CostSharingRule.BaseOfAllocationByLots =
	|				VALUE(Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts)
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByMaterialAndLaborCosts)
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			AND DataOfExpenditureItems.ExpenseItem.CostSharingRule.BaseOfAllocationByLots IN
	|				(VALUE(Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases),
	|				VALUE(Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases))
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProductsIncludingFutureReleases)
	|		WHEN ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0) = 1
	|			THEN VALUE(Enum.RulesOfCostAllocationToProductCost.ByProducts)
	|		ELSE VALUE(Enum.RulesOfCostAllocationToProductCost.EmptyRef)
	|	END														AS RuleOfCostAllocatingToProductionLots,
	|	ISNULL(DataOfExpenditureItems.NumberOfExpenditureItems, 0)	AS NumberOfExpenditureItems,
	|	ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) AS NumberOfCalculationArticles,
	|	DataToImport.Sum										AS Sum
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTBatchDocumentData AS BatchDocumentData
	|	ON BatchDocumentData.Id = DataToImport.Id
	|	
	|	LEFT JOIN Catalog.ProductionLots AS CatProductionLots
	|	ON CatProductionLots.Document = BatchDocumentData.DocumentLots
	|	AND CatProductionLots.Code = DataToImport.CostGroupNumber
	|	
	|	LEFT JOIN TTDataProductCostElements AS DataForCalculation_
	|	ON DataForCalculation_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTDataOfExpenditureItems AS DataOfExpenditureItems
	|	ON DataOfExpenditureItems.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#EndRegion

#EndIf