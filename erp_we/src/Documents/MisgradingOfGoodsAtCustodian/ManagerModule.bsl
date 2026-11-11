#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
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
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsAreEmpty = "ReceiveGoodsAtCostTheyWereIssuedFromWarehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "IncomeItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "IncomeItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "IncomeItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfRevenue", Parameters);
	
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
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses"); // for the formation of Registered Records for deviations in the cost of goods
	DocumentMechanisms.Add("DocumentCorrection");
	
	MisgradingOfGoodsAtCustodianLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.MisgradingOfGoodsAtCustodian") Then
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
		
		QueryTextRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		
		MisgradingOfGoodsAtCustodianLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.MisgradingOfGoodsAtCustodian);
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
//	Settings - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

#Region GenerateFrom

// Adds the command to create the document "Write-off of shipped goods".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//  ValueTableRow
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MisgradingOfGoodsAtCustodian) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager           = Metadata.Documents.MisgradingOfGoodsAtCustodian.FullName();
		CreateBasedOnCommand.Presentation      =
			TMCommonUse.ObjectPresentation(Metadata.Documents.MisgradingOfGoodsAtCustodian);
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions =
			"UseTransferToCustodyWithRightOfSale, UseProductionByThirdParty2_5";
		
		Return CreateBasedOnCommand;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Adds a Command to create a document "Re-sorting goods from the custodian" with the operation "Re-sorting goods from the processor".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow
//
Function AddCreateCommandBasedOnReSortingOfGiverSGoods(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MisgradingOfGoodsAtCustodian) Then
		
		CreateBasedOnCommand                     = GenerationCommands.Add();
		CreateBasedOnCommand.Manager            = Metadata.Documents.MisgradingOfGoodsAtCustodian.FullName();
		CreateBasedOnCommand.Presentation       = NStr("vi = 'Chuyển tồn hàng hóa của bên nhận gia công';
														|ru = 'Пересортица товаров у переработчика';
														|en = 'Stock reclass at subcontractor'; fa = 'طبقه‌بندی مجدد موجودی نزد پیمانکار فرعی';
														|it = 'Riclassificazione dei prodotti presso l''elaboratore';
														|pl = 'Przeklasyfikowanie towarów u przetwórcy';
														|tr = 'Fason üretici stoku yeniden sınıflandırma'");
		CreateBasedOnCommand.WriteMode         = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseMultipleCompaniesAndProductionByThirdParty25";
		
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
	
	MisgradingOfGoodsAtCustodianLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.CompanyStockBalance.AddReportCommand(ReportsCommands);
	
	MisgradingOfGoodsAtCustodianLocalization.AddReportCommands(ReportsCommands, Parameters);
	
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
//	Structure - The composition of the fields is set in the Nomenclature Clientserver function.The parameters of the series are specified.
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	SeriesSpecificationParameters.FullObjectName = "Document.MisgradingOfGoodsAtCustodian";
	
	UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse",
																New Structure());
	UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse",
																New Structure());
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = UseItemsBatch;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	SeriesSpecificationParameters.WarehouseFieldName = "Contract";
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	
	SeriesSpecificationParameters.LinkFields.Add("Purpose");
	SeriesSpecificationParameters.LinkFields.Add("ProductsRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.LinkFields.Add("AssignmentGoodsReceipt");
	
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Products",	"ProductsRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Characteristic",	"CharacteristicRecordingAsReceived");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Purpose",		"AssignmentGoodsReceipt");
	SeriesSpecificationParameters.FieldNamesWithSuffix.Insert("Series",			"BatchReceipt");
	
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatus");
	SeriesSpecificationParameters.FieldNamesStatusOfSeriesIndication.Add("BatchesIndicationStatusReceipt");
	
	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert("BatchesIndicationStatus", "Series");
	SeriesSpecificationParameters.MatchesSeriesFieldNameToStatusOfSeriesIndication.Insert(
		"BatchesIndicationStatusReceipt",
		"BatchReceipt");
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessOperation", Object.BusinessOperation);
	
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
	|	Goods.LineNumber                      AS LineNumber,
	|	Goods.Products                     AS Products,
	|	Goods.Characteristic                   AS Characteristic,
	|	Goods.Purpose                       AS Purpose,
	|	Goods.Series                            AS Series,
	|	Goods.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	Goods.ProductsRecordingAsReceived        AS ProductsRecordingAsReceived,
	|	Goods.CharacteristicRecordingAsReceived      AS CharacteristicRecordingAsReceived,
	|	Goods.AssignmentGoodsReceipt          AS AssignmentGoodsReceipt,
	|	Goods.BatchReceipt               AS BatchReceipt,
	|	Goods.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt,
	|	Goods.Count                       AS Count
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 1
	|SELECT
	|	Goods.LineNumber                      AS LineNumber,
	|	Goods.BatchesIndicationStatus              AS OldStatusOfSpecifyingSeries,
	|	Goods.BatchesIndicationStatusReceipt AS OldStatusOfSeriesReference,
	|	CASE
	|		WHEN CAST(Goods.Products AS Catalog.Products).ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN CAST(Goods.Products AS Catalog.Products).ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				AND (CAST(Goods.Products AS Catalog.Products).ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian)
	|					OR CAST(Goods.Products AS Catalog.Products).ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller))
	|			THEN
	|				CASE
	|					WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 18
	|					ELSE 17
	|				END
	|		ELSE 0
	|	END                                   AS BatchesIndicationStatus,
	|	CASE
	|		WHEN CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		WHEN CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|				AND (CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind.BatchAccountingPolicy.BatchesAccountingInDepositedGoods
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtCustodian)
	|					OR CAST(Goods.ProductsRecordingAsReceived AS Catalog.Products).ProductKind.BatchAccountingPolicy.SeriesAccountingOfGoodsTransferredToSubcontractor
	|						AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MisgradingOfGoodsAtToller))
	|			THEN
	|				CASE
	|					WHEN Goods.BatchReceipt <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|						THEN 18
	|					ELSE 17
	|				END
	|		ELSE 0
	|	END                                   AS BatchesIndicationStatusReceipt
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////// 2
	|SELECT
	|	Statuses.LineNumber                      AS LineNumber,
	|	Statuses.BatchesIndicationStatus              AS BatchesIndicationStatus,
	|	Statuses.BatchesIndicationStatusReceipt AS BatchesIndicationStatusReceipt
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
//	Returns:
//		See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness = "Object.LineOfBusiness";
	
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	// The remnants of the transferred goods
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"GoodsTransferredToCustodians",
			True,
			"Object.Goods.Purpose");
	
	DescriptionOfColumns.Columns.FindByValue("Passed").Check = True;
	
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Contract        = "Object.Contract";
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	
	// The remnants of the transferred goods
	DescriptionOfColumns =
		Catalogs.Assignments.AddColumnDescription_(
			FormTemplate,
			"GoodsTransferredToCustodians",
			True,
			"Object.Goods.AssignmentGoodsReceipt");
	
	DescriptionOfColumns.Columns.FindByValue("Passed").Check = True;
	
	DescriptionOfColumns.DataPaths.Organization    = "Object.Organization";
	DescriptionOfColumns.DataPaths.Contract        = "Object.Contract";
	DescriptionOfColumns.DataPaths.Products   = "Object.Goods.Products";
	DescriptionOfColumns.DataPaths.Characteristic = "Object.Goods.Characteristic";
	
	Return FormTemplate;
	
EndFunction

// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
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
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return MisgradingOfGoodsAtCustodianLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	See MisgradingOfGoodsAtCustodianLocalization.RequestTextTTReflectedInLocalAccounting
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return MisgradingOfGoodsAtCustodianLocalization.RequestTextTTReflectedInLocalAccounting();
	
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
// Parameters:
//	TradeGoodsAtCost - Boolean - indicates whether the goods need to be named at cost.
//	Var_FillChecking - Boolean - a sign that the filling of articles is carried out when checking the filling of the document.
//
// Returns:
//	See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(TradeGoodsAtCost, Var_FillChecking = False) Export
	
	ChoiceParametersArray = New Array;
	
	AvailabilityByOperation = True;
	
	If Var_FillChecking Then
		AvailabilityByOperation = Not TradeGoodsAtCost;
	ElsIf TradeGoodsAtCost Then
		AvailabilityByOperation = Undefined;
	EndIf;
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "ExpenseItem";
	ChoiceParameters.ArticleType   = "ArticleType";
	
	ChoiceParameters.AvailabilityByOperation               = AvailabilityByOperation;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses   = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension   = "AssetsLiabilitiesDimension";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AssetsLiabilitiesDimension");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	// IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef      = "IncomeItem";
	ChoiceParameters.ArticleType   = "TypeOfIncomeItem";
	
	ChoiceParameters.AvailabilityByOperation               = AvailabilityByOperation;
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue   = "DimensionOfRevenue";
	
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	
	ChoiceParametersArray.Add(ChoiceParameters);
	
	Return ChoiceParametersArray;
	
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
	If Data.BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller Then
		ObjectPresentation = NStr("vi = 'Chuyển tồn hàng hóa tại bên nhận gia công';
									|ru = 'Пересортица товаров у переработчика';
									|en = 'Stock reclass at subcontractor'; fa = 'طبقه‌بندی مجدد موجودی نزد پیمانکار فرعی';
									|it = 'Riclassificazione dei prodotti presso l''elaboratore';
									|pl = 'Przeklasyfikowanie towarów u przetwórcy';
									|tr = 'Fason üretici stoku yeniden sınıflandırma'");
	Else
		ObjectPresentation = NStr("vi = 'Chuyển tồn hàng hóa tại bên cho thuê kho';
									|ru = 'Пересортица товаров у хранителя';
									|en = 'Stock reclass at custodian'; fa = 'تغییر طبقه موجودی نزد امانت‌دار';
									|it = 'Riclassificazione dei prodotti presso il custode';
									|pl = 'Przeklasyfikowanie towarów u opiekuna';
									|tr = 'VMI stoku yeniden sınıflandırılma'");
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

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources; 
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                                                     AS Ref,
	|	DocumentData.Number                                                      AS Number,
	|	DocumentData.Date                                                       AS Period,
	|	DocumentData.Partner                                                    AS Partner,
	|	DocumentData.Counterparty                                                 AS Counterparty,
	|	DocumentData.Terms                                                 AS Terms,
	|	DocumentData.DocumentAmount                                             AS DocumentAmount,
	|	DocumentData.Currency                                                     AS Currency,
	|	DocumentData.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse                   AS ArrivalAtCost,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.ExpenseItems)
	|			THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                                                      AS ExpenseItem,
	|	CASE
	|		WHEN VALUETYPE(DocumentData.ExpenseItem) = TYPE(ChartOfCharacteristicTypes.AssetLiabilityItems)
	|			THEN DocumentData.ExpenseItem
	|		ELSE UNDEFINED
	|	END                                                                      AS AssetAndLiabilityItem,
	|	DocumentData.AssetsLiabilitiesDimension                                   AS AssetsLiabilitiesDimension,
	|	DocumentData.DimensionOfExpenses                                          AS DimensionOfExpenses,
	|	DocumentData.IncomeItem                                              AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                                           AS DimensionOfRevenue,
	|	DocumentData.BusinessOperation                                      AS BusinessOperation,
	|	DocumentData.Organization                                                AS Organization,
	|	DocumentData.Contract                                                    AS Contract,
	|	DocumentData.PriceKind                                                    AS PriceKind,
	|	DocumentData.Comment                                                AS Comment,
	|	DocumentData.InventoryOwnerAttributesAreSpecifiedManually                                  AS InventoryOwnerAttributesAreSpecifiedManually,
	|	DocumentData.EmployeeResponsible                                              AS EmployeeResponsible,
	|	DocumentData.Author                                                      AS Author,
	|	DocumentData.LineOfBusiness                                    AS LineOfBusiness,
	|	DocumentData.Department                                              AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods,
	|		VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.SalesOpportunity                                                     AS SalesOpportunity,
	|	ISNULL(DocumentData.SalesOpportunity.EnabledGoodsAssignmentInSalesOpportunity, FALSE)     AS EnabledGoodsAssignmentInSalesOpportunity,
	|	DocumentData.Patch                                                AS Patch,
	|	DocumentData.ReversedDocument                                       AS ReversedDocument,
	|	DocumentData.CorrectedDocument                                       AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date                                  AS AdjustmentPeriod_,
	|	DocumentData.DeletionMark                                            AS DeletionMark,
	|	DocumentData.Posted                                                   AS Posted,
	|	BusinessTransactionsSettings.Ref                                      AS BusinessTransactionSetting
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentData
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
	MetadataIdentifier = Common.MetadataObjectID("Document.MisgradingOfGoodsAtCustodian");
	
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
	Query.SetParameter(
		"GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Attributes.Organization, Attributes.Period);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
EndProcedure

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
	|	&Period                                          AS Period,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN VALUE(Enum.BusinessTransactions.GoodsMisgrading)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END                                            AS BusinessOperation,
	|	&Organization                                     AS Organization,
	|	&Department                                   AS Department,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignment
	|	END                                            AS ItemsLocationAttributes,
	|	InventoryKinds.LineOfBusiness              AS LineOfBusiness,
	|	&Contract                                         AS Warehouse,
	|	InventoryKinds.InventoryType                           AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute                           AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ItemsLocationAttributesReceipt
	|		ELSE InventoryKinds.AnalysisOfAccountingForProductsWithoutAssignmentRegistration
	|	END                                            AS CorItemsLocationAttributes,
	|	InventoryKinds.DirectionOfActivityRegistration AS CorLineOfBusiness,
	|	&Contract                                         AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt.InventoryType   AS CorInventoryType,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt              AS CorInventoryOwnerAttribute,
	|	InventoryKinds.Count                           AS Count,
	|	InventoryKinds.Count                           AS CorQuantity,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN 0
	|		ELSE InventoryKinds.SumMan
	|	END                                            AS Cost,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN 0
	|		ELSE InventoryKinds.SumMan
	|	END                                            AS CostExcludingVAT,
	|	CASE
	|		WHEN &ArrivalAtCost
	|			THEN 0
	|		ELSE InventoryKinds.SumCompl
	|	END                                            AS LocalCost,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END                                            AS SourceOfProductFinancialAccountingGroup,
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttributeGoodsReceipt
	|		ELSE InventoryKinds.ProductsRecordingAsReceived
	|	END                                            AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	TTTypesOfStocks AS InventoryKinds";
	
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
	|	&Period                                                           AS Period,
	|	SeriesTable.Series                                                AS Series,
	|	SeriesTable.Products                                         AS Products,
	|	SeriesTable.Characteristic                                       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                             AS Purpose,
	|	&Ref                                                           AS Document,
	|	&Partner                                                          AS Sender,
	|	UNDEFINED                                                      AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)              AS Premise,
	|	VALUE(Enum.WarehouseTransactions.ShortageRecord)        AS WarehouseOperation,
	|	FALSE                                                              AS ThisIsWarehouseRecord,
	|	SeriesTable.Count                                           AS Count
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period                                                           AS Period,
	|	SeriesTable.BatchReceipt                                   AS Series,
	|	SeriesTable.ProductsRecordingAsReceived                            AS Products,
	|	SeriesTable.CharacteristicRecordingAsReceived                          AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.AssignmentGoodsReceipt.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.AssignmentGoodsReceipt
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                             AS Purpose,
	|	&Ref                                                           AS Document,
	|	UNDEFINED                                                      AS Sender,
	|	&Partner                                                          AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)              AS Premise,
	|	VALUE(Enum.WarehouseTransactions.SurplusesRecord)        AS WarehouseOperation,
	|	FALSE                                                              AS ThisIsWarehouseRecord,
	|	SeriesTable.Count                                           AS Count
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.Goods AS SeriesTable
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Count <> 0
	|	AND SeriesTable.BatchReceipt <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|";
	
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
	|	&Ref                                AS Ref,
	|	&Period                                AS IBDocumentDate,
	|	&Number                                 AS IBDocumentNumber,
	|	&MetadataIdentifier               AS RefType,
	|	&Organization                           AS Organization,
	|	&BusinessOperation                 AS BusinessOperation,
	|	&Partner                               AS Partner,
	|	&Counterparty                            AS Counterparty,
	|	&Contract                               AS Contract,
	|	CASE
	|		WHEN DocumentData.NumberOfActivities = 1
	|			THEN DocumentData.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                  AS LineOfBusiness,
	|	&Partner                               AS StorageLocation,
	|	&Department                         AS Department,
	|	&EmployeeResponsible                         AS EmployeeResponsible,
	|	&Author                                 AS Author,
	|	CAST(&Comment AS STRING(100)) AS Comment,
	|	&Currency                                AS Currency,
	|	&DocumentAmount                        AS Sum,
	|	UNDEFINED                           AS Status,
	|	&Posted                              AS Posted,
	|	&DeletionMark                       AS DeletionMark,
	|	FALSE                                   AS AdditionalRecord,
	|	&ContractInformation                  AS More,
	|	&Period                                AS SourceDocumentDate,
	|	&Patch                           AS ReverseTransactionCorrection,
	|	&ReversedDocument                  AS ReversedDocument,
	|	&CorrectedDocument                  AS CorrectedDocument,
	|	&NumberForPrinting                         AS SourceDocumentNumber,
	|	&Period                                AS RecordingInAccountingDate
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
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	&Period                                             AS Period,
	|	InventoryKinds.ItemsLocationAttributes              AS ItemsLocationAttributes,
	|	&Organization                                        AS Organization,
	|	InventoryKinds.InventoryOwnerAttribute                              AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumber                                AS CCDNumber,
	|	&BusinessOperation                              AS BusinessOperation,
	|	&Organization                                        AS ShipmentCompany,
	|	CASE
	|		WHEN &ExpenseItem = UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE &ExpenseItem
	|	END                                               AS ExpenseItem,
	|	&DimensionOfExpenses                                  AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension                           AS AssetsLiabilitiesDimension,
	|	InventoryKinds.Products                            AS Products,
	|	InventoryKinds.Characteristic                          AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributesReceipt AS CorItemsLocationAttributes,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt                 AS CorInventoryOwnerAttribute,
	|	FALSE                                                AS Primary,
	|	InventoryKinds.Count                              AS Count,
	|	0                                                   AS ToRegisterGoodsIssue,
	|	InventoryKinds.QuantityByGBRN                        AS QuantityByGBRN,
	|	0                                                   AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                             AS RecordType,
	|	&Period                                                            AS Period,
	|	InventoryKinds.ItemsLocationAttributesReceipt                AS ItemsLocationAttributes,
	|	&Organization                                                       AS Organization,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt                                AS InventoryOwnerAttribute,
	|	InventoryKinds.CCDNumberRegistration                                  AS CCDNumber,
	|	&BusinessOperation                                             AS BusinessOperation,
	|	UNDEFINED                                                       AS ShipmentCompany,
	|	UNDEFINED                                                       AS ExpenseItem,
	|	UNDEFINED                                                       AS DimensionOfExpenses,
	|	UNDEFINED                                                       AS AssetsLiabilitiesDimension,
	|	InventoryKinds.ItemsLocationAttributesReceipt.Products   AS Products,
	|	InventoryKinds.ItemsLocationAttributesReceipt.Characteristic AS Characteristic,
	|	UNDEFINED                                                       AS CorItemsLocationAttributes,
	|	UNDEFINED                                                       AS CorInventoryOwnerAttribute,
	|	NOT &ArrivalAtCost                                          AS Primary,
	|	InventoryKinds.Count                                             AS Count,
	|	0                                                                  AS ToRegisterGoodsIssue,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE InventoryKinds.QuantityByRNPTReceipt
	|	END                                                              AS QuantityByGBRN,
	|	0                                                                  AS ToRegisterGoodsIssueByProductBatchID
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""InventoryKinds"" 										 AS TabularSectionName,
	|	DocumentTable.LineNumber 							 AS LineNumber,
	|	UNDEFINED											 AS Vendor,
	|	UNDEFINED											 AS Counterparty,
	|	UNDEFINED 											 AS VATRate,
	|	CASE
	|		WHEN ISNULL(DocumentTable.ItemsLocationAttributesReceipt.Purpose.VATActivityType,
	|			VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		THEN DocumentTable.ItemsLocationAttributesReceipt.Purpose.VATActivityType
	|		ELSE &TaxationOfOrganization
	|	END AS VATTaxation,
	|	VALUE(Enum.AssetKinds.Goods) 			 AS AssetTaxClass,
	|	0														 AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.MisgradingOfGoodsAtCustodian AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	InventoryKinds.LineNumber                                            AS LineNumber,
	|	InventoryKinds.Ref                                                 AS Ref,
	|	InventoryKinds.RowID                                    AS RowID,
	|	InventoryKinds.CCDNumber                                               AS CCDNumber,
	|
	|	InventoryKinds.InventoryOwnerAttribute.GoodsOwner                              AS GoodsOwner,
	|	InventoryKinds.InventoryOwnerAttribute.Contract                                     AS Contract,
	|	InventoryKinds.InventoryOwnerAttribute                                             AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                                  AS InventoryType,
	|	InventoryKinds.ItemsLocationAttributes                             AS ItemsLocationAttributes,
	|	AnalyticsWithoutAssignment.DimensionKey                               AS AnalysisOfAccountingForProductsWithoutAssignment,
	|	InventoryKinds.ItemsLocationAttributes.Products                AS Products,
	|	InventoryKinds.ItemsLocationAttributes.Characteristic              AS Characteristic,
	|	InventoryKinds.ItemsLocationAttributes.Purpose                  AS Purpose,
	|	InventoryKinds.ItemsLocationAttributes.Series                       AS Series,
	|	ISNULL(InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef))     AS LineOfBusiness,
	|
	|	&Organization                                                       AS Organization,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt.Currency                         AS Currency,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt                                AS InventoryOwnerAttributeGoodsReceipt,
	|	InventoryKinds.InventoryOwnerAttributeGoodsReceipt.InventoryType                     AS InventoryTypeRegistration,
	|	InventoryKinds.ItemsLocationAttributesReceipt                AS ItemsLocationAttributesReceipt,
	|	AnalyticsWithoutAssignmentRegistration.DimensionKey                  AS AnalysisOfAccountingForProductsWithoutAssignmentRegistration,
	|	InventoryKinds.ItemsLocationAttributesReceipt.Products   AS ProductsRecordingAsReceived,
	|	InventoryKinds.ItemsLocationAttributesReceipt.Characteristic AS CharacteristicRecordingAsReceived,
	|	ISNULL(InventoryKinds.ItemsLocationAttributesReceipt.Purpose.LineOfBusiness,
	|		VALUE(Catalog.LinesOfBusiness.EmptyRef))     AS DirectionOfActivityRegistration,
	|	InventoryKinds.CCDNumberRegistration                                  AS CCDNumberRegistration,
	|
	|	TableOfBatchAccountingAnalysts.AssetTaxClass							   AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation					   AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes 				   AS LotVendorAttributes,
	|
	|	InventoryKinds.Count                                                         AS Count,
	|	InventoryKinds.QuantityByGBRN                                                   AS QuantityByGBRN,
	|	InventoryKinds.QuantityByRNPTReceipt                                      AS QuantityByRNPTReceipt,
	|	InventoryKinds.Sum                                                              AS Sum,
	|	CAST(InventoryKinds.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(InventoryKinds.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(InventoryKinds.AmountOffBalance * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountOffBalanceMan,
	|	CAST(InventoryKinds.AmountOffBalance * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalOffBalanceAmount
	|
	|INTO TTTypesOfStocks
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.InventoryKinds AS InventoryKinds
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON InventoryKinds.ItemsLocationAttributes.Products   = AnalyticsWithoutAssignment.Products
	|		 AND InventoryKinds.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|		 AND InventoryKinds.ItemsLocationAttributes.Series          = AnalyticsWithoutAssignment.Series
	|		 AND InventoryKinds.ItemsLocationAttributes.StorageLocation  = AnalyticsWithoutAssignment.StorageLocation
	|		 AND VALUE(Catalog.Assignments.EmptyRef)          = AnalyticsWithoutAssignment.Purpose
	|		 AND VALUE(Catalog.ProductCostElements.EmptyRef)   = AnalyticsWithoutAssignment.ProductCostElement
	|
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignmentRegistration
	|		ON InventoryKinds.ItemsLocationAttributesReceipt.Products   = AnalyticsWithoutAssignmentRegistration.Products
	|		 AND InventoryKinds.ItemsLocationAttributesReceipt.Characteristic = AnalyticsWithoutAssignmentRegistration.Characteristic
	|		 AND InventoryKinds.ItemsLocationAttributesReceipt.Series          = AnalyticsWithoutAssignmentRegistration.Series
	|		 AND InventoryKinds.ItemsLocationAttributesReceipt.StorageLocation  = AnalyticsWithoutAssignmentRegistration.StorageLocation
	|		 AND VALUE(Catalog.Assignments.EmptyRef)                       = AnalyticsWithoutAssignmentRegistration.Purpose
	|		 AND VALUE(Catalog.ProductCostElements.EmptyRef)                = AnalyticsWithoutAssignmentRegistration.ProductCostElement
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= InventoryKinds.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|	
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
	|	AnalystTable.Products   AS Products,
	|	AnalystTable.Characteristic AS Characteristic,
	|	AnalystTable.Purpose     AS Purpose,
	|	AnalystTable.Series          AS Series,
	|	AnalystTable.StorageLocation  AS Warehouse
	|FROM
	|	(SELECT
	|		Goods.ItemsLocationAttributes.Products   AS Products,
	|		Goods.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)     AS Purpose,
	|		Goods.ItemsLocationAttributes.Series          AS Series,
	|		Goods.ItemsLocationAttributes.StorageLocation  AS StorageLocation
	|	FROM
	|		Document.MisgradingOfGoodsAtCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributes.Products      = Dimension.Products
	|			 AND Goods.ItemsLocationAttributes.Characteristic    = Dimension.Characteristic
	|			 AND Goods.ItemsLocationAttributes.Series             = Dimension.Series
	|			 AND Goods.ItemsLocationAttributes.StorageLocation     = Dimension.StorageLocation
	|			 AND VALUE(Catalog.Assignments.EmptyRef)        = Dimension.Purpose
	|			 AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Goods.ItemsLocationAttributesReceipt.Products   AS Products,
	|		Goods.ItemsLocationAttributesReceipt.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef)                  AS Purpose,
	|		Goods.ItemsLocationAttributesReceipt.Series          AS Series,
	|		Goods.ItemsLocationAttributesReceipt.StorageLocation  AS StorageLocation
	|	FROM
	|		Document.MisgradingOfGoodsAtCustodian.Goods AS Goods
	|			LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Goods.ItemsLocationAttributesReceipt.Products   = Dimension.Products
	|			 AND Goods.ItemsLocationAttributesReceipt.Characteristic = Dimension.Characteristic
	|			 AND Goods.ItemsLocationAttributesReceipt.Series          = Dimension.Series
	|			 AND Goods.ItemsLocationAttributesReceipt.StorageLocation  = Dimension.StorageLocation
	|			 AND VALUE(Catalog.Assignments.EmptyRef)                  = Dimension.Purpose
	|			 AND VALUE(Catalog.ProductCostElements.EmptyRef)           = Dimension.ProductCostElement
	|	WHERE
	|		Goods.Ref = &Ref
	|		AND Dimension.Products IS NULL
	|		AND NOT &KeepRecordsOfInventoryCostByAssignments) AS AnalystTable
	|";
	
	QueryAnalyst.SetParameter("Ref",                                     Query.Parameters.Ref);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
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
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentData
	|		LEFT JOIN Document.MisgradingOfGoodsAtCustodian.Goods AS GoodsTable
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
	
	FullDocumentName           = "Document.MisgradingOfGoodsAtCustodian";
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

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
	   And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients =
		ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Query.Parameters.Currency,
			Undefined,
			Query.Parameters.Period,
			Query.Parameters.Organization);
	
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	
EndProcedure

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ =
	"SELECT
	|	""InventoryKinds""                             AS DataSource,
	|	TRUE                                      AS DistributeTotalAmount,
	|	DocumentTable.Ref                     AS Ref,
	|	DocumentTable.Ref.Date                AS Date,
	|	DocumentTable.Ref.Organization         AS Organization,
	|	DocumentTable.Ref.Currency              AS DocumentCurrency,
	|	UNDEFINED                                AS ARAPCurrency,
	|	DocumentTable.Ref.Date                AS VATBasePeriod,
	|	DocumentTable.Ref.Date                AS DateOfCourse,
	|	DocumentTable.LineNumber                AS LineNumber,
	|	DocumentTable.RowID        AS RowID,
	|	DocumentTable.Sum                      AS AmountExcludingVAT,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0                                           AS VATAmount,
	|	0                                           AS AmountARAP,
	|	0                                           AS AmountVATARAP,
	|	0                                           AS AmountExcludingVATCompl,
	|	0                                           AS AmountExcludingVATMan,
	|	FALSE                                        AS NonPledgeReturnableContainers,
	|	FALSE                                        AS RecordedInARAPAccounting,
	|	FALSE                                        AS RecalculateBasedOnARAPData,
	|	UNDEFINED                                AS ARAPObject
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

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
	|	&Period                                                              AS DateOfReceipt,
	|	GoodsTable.ItemsLocationAttributesReceipt.Products   AS Products,
	|	GoodsTable.ItemsLocationAttributesReceipt.Characteristic AS Characteristic,
	|	GoodsTable.ItemsLocationAttributesReceipt.Series          AS Series,
	|	GoodsTable.ItemsLocationAttributesReceipt.Purpose     AS Purpose,
	|	GoodsTable.InventoryOwnerAttributeGoodsReceipt                                AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumberRegistration                                  AS CCDNumber
	|FROM
	|	TTTypesOfStocks AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.DatesOfCompanyGoodsReceipt AS UninvoicedReceipts
	|	ON GoodsTable.InventoryOwnerAttributeGoodsReceipt                               = UninvoicedReceipts.InventoryOwnerAttribute
	|	AND GoodsTable.ItemsLocationAttributesReceipt.Products   = UninvoicedReceipts.Products
	|	AND GoodsTable.ItemsLocationAttributesReceipt.CHARACTERISTIC = UninvoicedReceipts.Characteristic
	|	AND GoodsTable.ItemsLocationAttributesReceipt.Series          = UninvoicedReceipts.Series
	|	AND GoodsTable.ItemsLocationAttributesReceipt.Purpose     = UninvoicedReceipts.Purpose
	|	AND GoodsTable.CCDNumberRegistration                                  = UninvoicedReceipts.CCDNumber
	|
	|WHERE
	|	(UninvoicedReceipts.DateOfReceipt IS NULL
	|		OR UninvoicedReceipts.DateOfReceipt < BEGINOFPERIOD(&Period, DAY))
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
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt	  				AS CorInventoryOwnerAttribute,
	|	&ExpenseItem 											AS ExpenseItemAssets,
	|	&DimensionOfExpenses 											AS AssetExpenseAnalytics,
	|	&IncomeItem  											AS IncomeItem,
	|	&DimensionOfRevenue											AS DimensionOfRevenue,
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
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentTable
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
	|	DocumentTable.Organization 								AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt					AS InventoryOwnerAttribute,
	|	CASE WHEN NOT &Patch
	|		THEN DocumentTable.Ref
	|		ELSE DocumentTable.CorrectedDocument
	|	END 														AS Lot,
	|	TableTypesOfStocks_.VATActivityType						AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED												AS CorItemsLocationAttributes,
	|	UNDEFINED												AS CorInventoryOwnerAttribute,
	|	UNDEFINED												AS CorGroupOfManufacturedProducts,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes AS LotVendorAttributes,
	|	CASE WHEN NOT &FIFORollingValuation
	|		THEN TableTypesOfStocks_.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 									AS LotVendorAttributesCorr,
	|	0 										AS RowCode,
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
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentTable
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
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			 		 	AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType				AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        		AS CorCompany,
	|	UNDEFINED 									   			AS CorLot,
	|	TableTypesOfStocks_.ItemsLocationAttributesReceipt	AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt					AS CorInventoryOwnerAttribute,
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
	|	VALUE(Enum.BusinessTransactions.GoodsMisgrading)				AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 										AS FinRecordID,
	|	&BusinessTransactionSetting 											AS BusinessTransactionSetting
	|
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentTable
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
	|	DocumentTable.Date	AS Period,
	|	DocumentTable.Ref	AS Ref,
	|	UNDEFINED			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute					AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED										AS CorCompany,
	|	UNDEFINED										AS CorLot,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryTypeRegistration = VALUE(Enum.InventoryTypes.OwnGoods)
	|			THEN TableTypesOfStocks_.ItemsLocationAttributes
	|		ELSE TableTypesOfStocks_.ItemsLocationAttributesReceipt END) AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttributeGoodsReceipt					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED							AS SalesOpportunity,
	|	DocumentTable.Department			AS Department,
	|	UNDEFINED							AS Manager,
	|	UNDEFINED 							AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Other fields
	|	CASE WHEN DocumentTable.ReceiveGoodsAtCostTheyWereIssuedFromWarehouse
	|		THEN VALUE(Enum.BusinessTransactions.GoodsMisgrading)
	|		ELSE VALUE(Enum.BusinessTransactions.GoodsMisgradingWithRevaluation)
	|	END									AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	&BusinessTransactionSetting			AS BusinessTransactionSetting
	|
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian AS DocumentTable
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
	
	// Act on the re-sorting of goods from the keeper
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "ActOfReSortingGoodsFromKeeper";
	PrintCommand.Presentation                  = NStr("vi = 'Biên bản chuyển tồn hàng hóa tại nơi cất giữ';
														|ru = 'Акт о пересортице товаров у хранителя';
														|en = 'Stock reclass certificate at custodian'; fa = 'Stock reclass certificate at custodian';
														|it = 'Atto di riclassificazione degli articoli presso il deposito';
														|pl = 'Protokół o przeklasyfikowaniu towarów u opiekuna';
														|tr = 'VMI stoku yeniden sınıflandırmasına ilişkin tutanak'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand, "BusinessOperation", Enums.BusinessTransactions.MisgradingOfGoodsAtCustodian);
	
	// Act on the re-sorting of goods from the processor
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id                  = "ActOfReSortingGoodsFromProcessor";
	PrintCommand.Presentation                  = NStr("vi = 'Biên bản chuyển tồn hàng hóa của người nhận gia công';
														|ru = 'Акт о пересортице товаров у переработчика';
														|en = 'Stock reclass certificate at subcontractor'; fa = 'Stock reclass certificate at subcontractor';
														|it = 'Atto di riclassificazione degli articoli presso l''elaboratore';
														|pl = 'Protokół o przeklasyfikowaniu towarów u przetwórcy';
														|tr = 'Fason üretici stoku yeniden sınıflandımasına ilişkin tutanak'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintManagement.AddCommandVisibilityCondition(
		PrintCommand, "BusinessOperation", Enums.BusinessTransactions.MisgradingOfGoodsAtToller);
	MisgradingOfGoodsAtCustodianLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// Forms printed forms of the object.
//
// Parameters:
//	ObjectsArray        - Array           - an array of references to objects which need to print,
//	PrintParameters       - Structure        - structure of additional print parameters,
//	PrintFormsCollection - ValueTable  - generated table documents,
//	PrintObjects         - ValueList   - list of print objects,
//	OutputParameters       - Structure        - parameters of generated table documents.
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfReSortingGoodsFromKeeper") Then
	
		PrintManagement.OutputSpreadsheetDocumentToCollection(
										PrintFormsCollection,
										"ActOfReSortingGoodsFromKeeper",
										NStr("vi = 'Biên bản chuyển tồn hàng hóa tại nơi cất giữ';
											|ru = 'Акт о пересортице товаров у хранителя';
											|en = 'Stock reclass certificate at custodian'; fa = 'Stock reclass certificate at custodian';
											|it = 'Atto di riclassificazione degli articoli presso il deposito';
											|pl = 'Protokół o przeklasyfikowaniu towarów u opiekuna';
											|tr = 'VMI stoku yeniden sınıflandırmasına ilişkin tutanak'"),
										FormPrintedFormOfActOfReSortingGoods(ObjectsArray, PrintObjects));
	
	EndIf;
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ActOfReSortingGoodsFromProcessor") Then
	
		PrintManagement.OutputSpreadsheetDocumentToCollection(
										PrintFormsCollection,
										"ActOfReSortingGoodsFromProcessor",
										NStr("vi = 'Biên bản chuyển tồn hàng hóa của người nhận gia công';
											|ru = 'Акт о пересортице товаров у переработчика';
											|en = 'Stock reclass certificate at subcontractor'; fa = 'Stock reclass certificate at subcontractor';
											|it = 'Atto di riclassificazione degli articoli presso l''elaboratore';
											|pl = 'Protokół o przeklasyfikowaniu towarów u przetwórcy';
											|tr = 'Fason üretici stoku yeniden sınıflandımasına ilişkin tutanak'"),
										FormPrintedFormOfActOfReSortingGoods(ObjectsArray, PrintObjects));
	
	EndIf;
	PrintFormGeneration.FillInSendingParameters(
		OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

// The function generates a printed form of documents for the re-sorting of goods from the keepers.
//
// Parameters:
//	ObjectsArray  - Array         - an array of references to objects which need to print,
//	PrintObjects   - ValueList - list of print objects.
//
// Returns:
//	SpreadsheetDocument - the printed form of documents is the re-sorting of goods from the keepers.
//
Function FormPrintedFormOfActOfReSortingGoods(ObjectsArray, PrintObjects)
	
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
	|	Document.Contract AS Contract,
	|	Document.Department AS Department,
	|	Document.Organization AS Organization,
	|	PRESENTATION(Document.Contract) AS ContractPresentation,
	|	PRESENTATION(Document.Department) AS DepartmentPresentation,
	|	Document.Organization.AbbreviatedDescription AS OrganizationPresentation,
	|	Document.Organization.Prefix AS Prefix,
	|	Document.EmployeeResponsible.Individual AS EmployeeResponsible
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian AS Document
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
	|	PRESENTATION(GoodsTable.Products.UnitOfMeasure) AS UnitOfMeasurementWriteOffPresentation,
	|	&AdditionalColumnWriteOff,
	|	GoodsTable.ProductsRecordingAsReceived AS ProductsRecordingAsReceived,
	|	GoodsTable.ProductsRecordingAsReceived.DescriptionFull AS ProductsRecordingAsReceivedPresentation,
	|	GoodsTable.CharacteristicRecordingAsReceived.DescriptionFull AS CharacteristicRecordingAsReceivedPresentation,
	|	PRESENTATION(GoodsTable.BatchReceipt) AS BatchReceiptPresentation,
	|	PRESENTATION(GoodsTable.ProductsRecordingAsReceived.UnitOfMeasure) AS UnitOfMeasurementRegistrationPresentation,
	|	&AdditionalColumnRegistration,
	|	GoodsTable.Count AS Count,
	|	GoodsTable.Ref AS Ref
	|FROM
	|	Document.MisgradingOfGoodsAtCustodian.Goods AS GoodsTable
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
		AdditionalColumnWriteOff = "GoodsTable.Products." + AdditionalColumn +" AS AdditionalColumnWriteOff,";
		AdditionalColumnRegistration = "GoodsTable.ProductsRecordingAsReceived." + AdditionalColumn +" AS AdditionalColumnRegistration,";
	Else
		AdditionalColumnWriteOff = "";
		AdditionalColumnRegistration = "";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&AdditionalColumnWriteOff,",      AdditionalColumnWriteOff);
	Query.Text = StrReplace(Query.Text, "&AdditionalColumnRegistration,", AdditionalColumnRegistration);
	
	DocumentAttributes = New Structure("Number, Date, Prefix, NumberOfDocumentBeingCorrected, DateOfDocumentBeingCorrected");
	DocumentSynonym = NStr("vi = 'Biên bản chuyển tồn hàng hóa';
							|ru = 'Акт о пересортице товаров';
							|en = 'Stock reclass certificate'; fa = 'گواهی تغییر طبقه موجودی';
							|it = 'Atto di riclassificazione delle merci';
							|pl = 'Protokół o przeklasyfikowaniu (niedobory/nadwyżki pozorne) towarów';
							|tr = 'Stok yeniden sınıflandırmasına ilişkin rapor'", Common.DefaultLanguageCode());

	TabDocument = New SpreadsheetDocument;
	TabDocument.PrintParametersName = "PARAMETERS_PRINTER_ResortmentOfGoodsAtCustodian_ActOfResortmentOfGoodsAtCustodian";
	
	Template = PrintManagement.PrintFormTemplate("Document.MisgradingOfGoodsAtCustodian.PF_MXL_CustodianMisgradingCertificate");
	If GetFunctionalOption("UseBusinessUnits") Then
		HeaderArea_ = Template.GetArea("Title");
	Else
		HeaderArea_ = Template.GetArea("TitleWithoutDivision");
	EndIf;
	
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
		DataOfArea = New Structure;
		NamesAsOfDate = CompaniesCached.NamesAsOfDate(DocumentsSelection.Organization, DocumentsSelection.Date);
		DataOfArea.Insert("OrganizationPresentation", NamesAsOfDate.AbbreviatedDescription);
		DataOfArea.Insert("TitleText", 
							TMCommonUseClientServer.GenerateDocumentTitle(DocumentAttributes, DocumentSynonym));
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(TabDocument, Template, HeaderArea_, DocumentsSelection.Ref);
		HeaderArea_.Parameters.Fill(DataOfArea);
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
		TabDocument.Put(LabelArea);

		PrintManagement.SetDocumentPrintArea(TabDocument, RowNumberStart, PrintObjects, DocumentsSelection.Ref);

	EndDo;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return TabDocument;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
//
// Parameters:
//  PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
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

#Region UnifiedMethodsForBusinessOperations

#Region Posting

// Returns parameters for filling in inventory types for the document "Re-sorting of goods from the custodian".
// 
// Parameters:
//  ReversedDocument - DocumentRef.MisgradingOfGoodsAtCustodian - 
//
// Returns:
//  See InventoriesServer.ParametersForFillingInventoryTypes
//
Function ParametersForFillingInventoryTypes(ReversedDocument) Export
	
	FillParameters = InventoriesServer.ParametersForFillingInventoryTypes();
	FillParameters.PickUpVTCHGoodsAcceptedForResponsibleStorage.Insert(Enums.InventoryTypes.GoodsInStorageWithRightToSell, "Always");
	FillParameters.ReversedDocument                              = ReversedDocument;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#Region BusinessTransactions

// Returns the business transaction of the contract.
//
// Returns:
//  EnumRef.BusinessTransactions - 
// 
Function ContractBusinessTransaction() Export
	
	Return Enums.BusinessTransactions.TransferToStorageWithRightOfSale;
	
EndFunction

#EndRegion

#Region FunctionalOptions

// Returns a sign of the applicability of agreements with clients
//
// Returns:
//  Boolean - 
//
Function CustomerAgreementsAreApplicable() Export
	
	Return True;
	
EndFunction

// Returns the use of agreements with clients attribute
//
// Returns:
//  Boolean -
//
Function ToUseTermsOfSales() Export
	
	Return GetFunctionalOption("ToUseTermsOfSales");

EndFunction

#EndRegion

#Region Form

//Gets the default contract.
//
// Parameters:
//  Object - FormDataStructure - 
//
// Returns:
//  CatalogRef.CounterpartyContracts - 
//
Function GetDefaultContract(Object) Export
	
	If GetFunctionalOption("UseIncomeAccountingByLinesOfBusiness") Then
		Contract = SalesServer.GetDefaultContract(
					Object, ContractBusinessTransaction(), Undefined, Object.LineOfBusiness);
	Else
		Contract = SalesServer.GetDefaultContract(
					Object, ContractBusinessTransaction());
	EndIf;
	
	Return Contract;
	
EndFunction

// Sets the availability of the contract element.
//
// Parameters:
//  Form - ClientApplicationForm -
//  Object - FormDataStructure -
//  Contract - CatalogRef.CounterpartyContracts, Undefined -
//
Procedure SetContractAvailability(Form, Object, Contract = Undefined) Export
	
	Items = Form.Items;

	SalesServer.SetContractAvailability(
		Object, Items.Contract.Enabled, Items.Contract.Visible, Contract);
	
EndProcedure

// Adjusts the form.
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Number - Number - 
//  Date  - Date - 
//
Procedure CustomizeForm(Form, Number, Date) Export
	
	Items  = Form.Items;
	Parameters = Form.Parameters;
	
	Form.AutoTitle = True;
	Form.Title     = DocumentFormHeader(Not ValueIsFilled(Parameters.Key), Number, Date);

	Items.Partner.Title = NStr("vi = 'Khách hàng';
								|ru = 'Клиент';
								|en = 'Customer'; fa = 'مشتری';
								|it = 'Cliente';
								|pl = 'Customer';
								|tr = 'Müşteri'");
	
	Items.Terms.Visible = ToUseTermsOfSales();
	
EndProcedure

// Configures the parameters of the selection and the relationship of the parameters of the selection of the details of the form.
//
// Parameters:
//  Form  - ClientApplicationForm -
//  Object - FormDataStructure -
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
	
	// Direction of activity
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.IncomeAccounting", True));
	
	Items.LineOfBusiness.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	
EndProcedure

// Returns the title of the document form transfer of goods to the custodian.
//
// Parameters:
//  NewDocument - Boolean - 
//  Number - Number - 
//  Date - Date - 
//
// Returns:
//  String - 
//
Function DocumentFormHeader(NewDocument, Number, Date) Export
	
	Return "";
	
EndFunction

// Returns the presentation of the document transfer of goods to the custodian.
//
// Returns:
//  String - 
//
Function ObjectPresentation() Export
	
	Return NStr("vi = 'Chuyển tồn hàng hóa tại nơi cất giữ';
				|ru = 'Пересортица товаров у хранителя';
				|en = 'Stock reclass at custodian'; fa = 'تغییر طبقه موجودی نزد امانت‌دار';
				|it = 'Riclassificazione dei prodotti presso il custode';
				|pl = 'Przeklasyfikowanie towarów u opiekuna';
				|tr = 'Emanetçi stoku yeniden sınıflandırma'");
	
EndFunction

#EndRegion

#EndRegion

#Region GeneralMethodsForBusinessOperations

#Region ActionHandlers

// Gets a server action handler depending on the business operation
//
// Parameters:
//  BusinessOperation - EnumRef.BusinessTransactions, Undefined - 
//
// Returns:
//  CommonModule, DocumentManager - handler manager
//
Function ActionHandler(BusinessOperation = Undefined) Export
	If BusinessOperation = Enums.BusinessTransactions.MisgradingOfGoodsAtToller Then
		ActionHandler = MisgradingOfGoodsAtToller;
	Else
		ActionHandler = Documents.MisgradingOfGoodsAtCustodian;
	EndIf;
	Return ActionHandler;
	
EndFunction

#EndRegion

#Region Form

// Sets up the business operation props
//
// Parameters:
//  Form - ClientApplicationForm - 
//  Object - FormDataStructure - 
//
Procedure ConfigureBusinessTransactionDetails(Form, Object) Export
	
	Items = Form.Items;
	
	Items.BusinessOperation.ChoiceList.Clear();
		
	If GetFunctionalOption("UseTransferToCustodyWithRightOfSale") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.MisgradingOfGoodsAtCustodian);
	EndIf;
	If GetFunctionalOption("UseProductionByThirdParty2_5") Then
		Items.BusinessOperation.ChoiceList.Add(
			Enums.BusinessTransactions.MisgradingOfGoodsAtToller);
	EndIf;
	Items.BusinessOperation.Visible = Items.BusinessOperation.ChoiceList.Count() > 1;
	
	If Not ValueIsFilled(Object.BusinessOperation)
	   And Items.BusinessOperation.ChoiceList.Count() = 1 Then
		Object.BusinessOperation = Items.BusinessOperation.ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#EndIf