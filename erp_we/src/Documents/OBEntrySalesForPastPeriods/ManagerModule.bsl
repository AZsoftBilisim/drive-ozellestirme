#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the parameters of the selection of articles and analyst.
// 
// Returns:
//  Structure - Article and analyst selection options (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//              .
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	#Region FinancialResultExpenses
	
	// ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.FinancialResultExpenses";
	ChoiceParameters.AssetRef                = "ExpenseItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	ChoiceParameters.ChoosingExpenseItem   = False;
	
	ChoiceParameters.FormItems.AssetRef.Add("FinancialResultExpensesExpenseItem");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	#Region FinancialResultIncome
	
	// IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath           = "Object.FinancialResultIncome";
	ChoiceParameters.AssetRef                = "IncomeItem";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	ChoiceParameters.ChoosingExpenseItem   = False;
	
	ChoiceParameters.FormItems.AssetRef.Add("FinancialResultIncomeIncomeItem");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	#EndRegion
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

Function ObtainingFormForEnteringBalancesOnSalesForPastPeriods(BusinessOperation) Export
	
	MatchingOperationTypesToForms = New Map;
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryOpenGiftCards"),
		"FormGiftCards");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfOtherPLItemsInPastPeriods"),
		"FormFinancialResult");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods"),
		"FormWholesale");
		
	MatchingOperationTypesToForms.Insert(
		PredefinedValue("Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods"),
		"FormRetailSales");
	
	Return MatchingOperationTypesToForms[BusinessOperation];
	
EndFunction

#Region Posting

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - collection:
//     of Table elements<Register Name> - Assignment tables - a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If TypeOf(Document) = Type("DocumentObject.OBEntrySalesForPastPeriods") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// Create a motion initialization request
	
	Query = New Query;
	FillInInitializationParameters(Query, DocumentRef);
	
	////////////////////////////////////////////////////////////////////////////
	// Let's form the request text
	
	QueryTexts = New ValueList;
	QueryTextTableFinancialResults(Query, QueryTexts, Registers);
	QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.EnteringBalancesOnSalesForPastPeriodsSupplementTextsOfRequests(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("FinancialResult");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("GiftCertificates");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringBalancesOfSalesForPastPeriodsRegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	DataProcessors.ReferenceAddressWarehousingOfProducts.AddGenerateCommand(GenerationCommands);
	
	OBEntryLocalization.AddGenerationCommands(GenerationCommands, Parameters);

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
	
	OBEntryLocalization.EnterBalancesOnSalesForPastPeriodsAddReportCommands(ReportsCommands, Parameters);

EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return OBEntryLocalization.EnteringSalesBalancesForPastPeriodsToBeReflectedInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return OBEntryLocalization.EnteringBalancesOnSalesForPastPeriodsQueryTextTTReflectionInLocalAccounting();

EndFunction

#EndRegion
#Region InterfaceImplementation

// Adds a command to create a document based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
// Returns:
//	FormCommand - the command being added.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntrySalesForPastPeriods);
	
EndFunction

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND( ValueAllowed(Warehouse)
	|	OR Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	)";

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

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	Return Undefined;	
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation) Export
	
	KeyFieldsArray = New Array;
	Return KeyFieldsArray;
	
EndFunction

#EndRegion

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	SelectedOperation = Undefined;
	
	If Parameters.Property("Key") And ValueIsFilled(Parameters.Key) Then
		
		SelectedOperation = Parameters.Key.BusinessOperation;
		
	ElsIf Parameters.Property("FillingValues") Then
		
		Parameters.FillingValues.Property("BusinessOperation", SelectedOperation);
		
	ElsIf Parameters.Property("CopyingValue") Then
		
		SelectedOperation = GeneralPurposeTMServerCall.ObjectAttributeValue(Parameters.CopyingValue,"BusinessOperation");
		
	ElsIf Parameters.Property("FilterByTransactionTypes") And Parameters.FilterByTransactionTypes.Count() = 1 Then
		
		SelectedOperation = Parameters.FilterByTransactionTypes[0].Value;
		
		FillingValues = New Structure;
		FillingValues.Insert("BusinessOperation", SelectedOperation);
		
		Parameters.Insert("FillingValues", FillingValues);
		
		If Parameters.Property("Organization") Then
			FillingValues.Insert("Organization", Parameters.Organization);
		EndIf;
		
		If Parameters.Property("RecordInOperationalAccounting") Then
			FillingValues.Insert("RecordInOperationalAccounting", Parameters.RecordInOperationalAccounting);
		EndIf;
		
		If Parameters.Property("PostInFinancialAndTaxAccounting") Then
			FillingValues.Insert("PostInFinancialAndTaxAccounting", Parameters.PostInFinancialAndTaxAccounting);
		EndIf;
		
		If Parameters.Property("RecordInMA") Then
			FillingValues.Insert("RecordInMA", Parameters.RecordInMA);
		EndIf;
		
	EndIf;

	If ValueIsFilled(SelectedOperation) Then
		
		StandardProcessing = False;
		
		SelectedForm = OBEntryServerCall.ObtainingFormForEnteringBalancesOnSalesForPastPeriods(SelectedOperation);
		
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	
	Presentation = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data,
		Data.Number,
		Data.Date,
		Data.BusinessOperation);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Department AS Department,
		|	DocumentData.Department.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	DocumentData.Warehouse AS Warehouse,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.VATTaxation AS VATTaxation,
		|	DocumentData.Partner AS Partner,
		|	DocumentData.Counterparty AS Counterparty,
		|	DocumentData.Contract AS Contract,
		|	DocumentData.CustomerTermsOfSales AS CustomerTermsOfSales,
		|	DocumentData.Partner AS Vendor,
		|	DocumentData.Manager AS Manager,
		|	DocumentData.Author AS Author,
		|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
		|	DocumentData.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.Posted AS Posted,
		|	SUM(ISNULL(DataOfTabularPartFinancialResultExpenses.ExpenseAmount, 0)
		|		+ ISNULL(DataOfTabularPartFinancialResultIncome.IncomeAmount, 0) 
		|		+ ISNULL(TableDataGiftCertificates.AmountInCertificateCurrency, 0)
		|		+ ISNULL(DataOfTablePartWholesaleSales.Sum, 0) 
		|		+ ISNULL(DataOfTabularPartRetailSales.Sum, 0)) AS DocumentAmount
		|FROM
		|	Document.OBEntrySalesForPastPeriods AS DocumentData
		|		LEFT JOIN Document.OBEntrySalesForPastPeriods.WholesaleSalesInPastPeriods AS DataOfTablePartWholesaleSales
		|		ON DocumentData.Ref = DataOfTablePartWholesaleSales.Ref
		|		LEFT JOIN Document.OBEntrySalesForPastPeriods.RetailSales AS DataOfTabularPartRetailSales
		|		ON DocumentData.Ref = DataOfTabularPartRetailSales.Ref
		|		LEFT JOIN Document.OBEntrySalesForPastPeriods.GiftCertificates AS TableDataGiftCertificates
		|		ON DocumentData.Ref = TableDataGiftCertificates.Ref
		|		LEFT JOIN Document.OBEntrySalesForPastPeriods.FinancialResultExpenses AS DataOfTabularPartFinancialResultExpenses
		|		ON DocumentData.Ref = DataOfTabularPartFinancialResultExpenses.Ref
		|		LEFT JOIN Document.OBEntrySalesForPastPeriods.FinancialResultIncome AS DataOfTabularPartFinancialResultIncome
		|		ON DocumentData.Ref = DataOfTabularPartFinancialResultIncome.Ref
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.Department,
		|	DocumentData.Warehouse,
		|	DocumentData.Currency,
		|	DocumentData.BusinessOperation,
		|	DocumentData.VATTaxation,
		|	DocumentData.Counterparty,
		|	DocumentData.Contract,
		|	DocumentData.CustomerTermsOfSales,
		|	DocumentData.Partner,
		|	DocumentData.Manager,
		|	DocumentData.Author,
		|	DocumentData.PriceIncludesVAT,
		|	DocumentData.LineOfBusiness,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	DocumentData.EmployeeResponsible,
		|	DocumentData.DeletionMark,
		|	DocumentData.Posted";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                         Attributes.Period);
	Query.SetParameter("Number",                          Attributes.Number);
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("Department",                  Attributes.Department);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("Partner",                        Attributes.Partner);
	Query.SetParameter("Counterparty",                     Attributes.Counterparty);
	Query.SetParameter("Contract",                        Attributes.Contract);
	Query.SetParameter("CustomerTermsOfSales",            Attributes.CustomerTermsOfSales);
	Query.SetParameter("VATTaxation",             Attributes.VATTaxation);
	Query.SetParameter("Manager",                       Attributes.Manager);
	Query.SetParameter("Author",                          Attributes.Author);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("PriceIncludesVAT",                Attributes.PriceIncludesVAT);
	Query.SetParameter("LineOfBusiness",        Attributes.LineOfBusiness);
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("EmptyAssignment",               Catalogs.Assignments.EmptyRef());
	Query.SetParameter("Warehouse" ,                         Attributes.Warehouse);
	Query.SetParameter("Comment" ,                   Attributes.Comment);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("DocumentAmount",                 Attributes.DocumentAmount);
	Query.SetParameter("Currency",                         Attributes.Currency);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document." + Metadata.Documents.OBEntrySalesForPastPeriods.Name));

	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query("
	|SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	&EmptyAssignment          AS Purpose,
	|	Keys.Series                AS Series,
	|	Keys.Warehouse                AS Warehouse
	|FROM
	|	(SELECT DISTINCT
	|		Sales.ItemsLocationAttributes.Products   AS Products,
	|		Sales.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment                                 AS Purpose,
	|		Sales.ItemsLocationAttributes.Series          AS Series,
	|		Sales.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|	FROM
	|		Document.OBEntrySalesForPastPeriods.WholesaleSalesInPastPeriods AS Sales
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Sales.Ref = &Ref
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		Sales.ItemsLocationAttributes.Products   AS Products,
	|		Sales.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		&EmptyAssignment                                 AS Purpose,
	|		Sales.ItemsLocationAttributes.Series          AS Series,
	|		Sales.ItemsLocationAttributes.StorageLocation  AS Warehouse
	|	FROM
	|		Document.OBEntrySalesForPastPeriods.RetailSales AS Sales
	|	WHERE
	|		NOT &KeepRecordsOfInventoryCostByAssignments
	|		AND Sales.Ref = &Ref
	|	) AS Keys
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products = Dimension.Products
	|		AND Keys.Characteristic = Dimension.Characteristic
	|		AND Keys.Series = Dimension.Series
	|		AND Keys.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|		AND &EmptyAssignment = Dimension.Purpose
	|WHERE
	|	Dimension.DimensionKey IS NULL
	|	AND &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfWholesaleTransactionsInPastPeriods),
	|		VALUE(Enum.BusinessTransactions.OBEntryStatisticsOfRetailSaleTransactionsInPastPeriods)
	|		)	
	|");
	
	QueryAnalyst.SetParameter("Ref",                                     Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment",                           Query.Parameters.EmptyAssignment);
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("BusinessOperation",                      Query.Parameters.BusinessOperation);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Function QueryTextTableFinancialResults(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialResults";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	TableRevenue.DateRecord           AS Period,
	|	&Organization                          AS Organization,
	|	&Department                        AS Department,
	|	TableRevenue.IncomeItem           AS IncomeItem,
	|	UNDEFINED                          AS ExpenseItem,
	|	TableRevenue.LineOfBusiness AS LineOfBusiness,
	|	TableRevenue.IncomeAmount            AS Income,
	|	0                                     AS Expenses
	|	
	|FROM
	|	Document.OBEntrySalesForPastPeriods.FinancialResultIncome AS TableRevenue
	|
	|WHERE
	|	TableRevenue.Ref = &Ref
	|
 	|UNION ALL
 	|
	|SELECT
	|	TableExpenses.DateRecord           AS Period,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	UNDEFINED                           AS IncomeItem,
	|	TableExpenses.ExpenseItem          AS ExpenseItem,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	0                                      AS Income,
	|	TableExpenses.ExpenseAmount           AS Expenses
	|	
	|FROM
	|	Document.OBEntrySalesForPastPeriods.FinancialResultExpenses AS TableExpenses
	|
	|WHERE
	|	TableExpenses.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|
	|ORDER BY
	|	Organization,
	|	Department,
	|	LineOfBusiness,
	|	IncomeItem,
	|	ExpenseItem";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Procedure SetPartnerAccountingAnalyticsParameter(Query)
	
	If Query.Parameters.Property("AccountingDimensionByPartners") Then
		Return;
	EndIf;
	
	AccountingDimensionByPartners = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Query.Parameters);
	
	Query.SetParameter("AccountingDimensionByPartners", AccountingDimensionByPartners);

EndProcedure

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetPartnerAccountingAnalyticsParameter(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber                                      AS LineNumber,
	|	GoodsTable.DateRecord                                    AS Period,
	|	&Department                                                 AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE DimensionCostOfProduction.DimensionKey
	|	END                                                          AS ItemsLocationAttributes,
	|	UNDEFINED                                                   AS SetAccountingDimension,
	|	&AccountingDimensionByPartners                                     AS AccountingDimensionByPartners,
	|	UNDEFINED                                                   AS SalesOrder,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|		THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END                                                          AS InventoryType,
	|	&Manager                                                      AS Manager,
	|	CASE
	|		WHEN NOT (GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|					OR GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|			THEN GoodsTable.InventoryOwnerAttribute
	|		ELSE UNDEFINED
	|	END                                                          AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		WHEN ISNULL(GoodsTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END) AS AccountingSection,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 AND &FIFORollingValuation 
	|		THEN &VATTaxation
	|		ELSE UNDEFINED END)								   AS VATActivityType,
	|	&Warehouse                                                         AS Warehouse,
	|	&Contract                                                       AS Contract,
	|	&CustomerTermsOfSales                                           AS Terms,
	|	&ManagementAccountingCurrency                                    AS ARAPCurrency,
	|	&ManagementAccountingCurrency                                    AS DocumentCurrency,
	|	&VATTaxation                                            AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer) AS BusinessOperation,
	|
	|	&LineOfBusiness                                       AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                          AS ProductLineOfBusiness,
	|
	|	UNDEFINED                                                   AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED                                                   AS SourceOfARAPFinancialAccountingGroup,
	|
	|	0                                                              AS Cost,
	|	0                                                              AS CostExcludingVAT,
	|	0                                                              AS LocalCost,
	|	0                                                              AS ManualDiscount,
	|	0                                                              AS DiscountMarkupAmount,
	|	0                                                              AS AmountInARAPCurrency,
	|	0                                                              AS AmountExcludingVATInARAPCurrency,
	|	0                                                              AS AmountInDocumentCurrency,
	|	0                                                              AS AmountExcludingVATInDocumentCurrency,
	|	GoodsTable.Count                                       AS Count,
	|	GoodsTable.Sum                                            AS RevenueAmount,
	|	GoodsTable.AmountExcludingVAT                                      AS RevenueAmountExcludingVAT,
	|	GoodsTable.SumCompl                                        AS RevenueAmountExclVATLocal,
	|	GoodsTable.SumCompl + GoodsTable.VATLocal                AS RevenueAmountIncludingVATLocal,
	|
	|	GoodsTable.RowID                              AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SaleToCustomer) AS BusinessTransactionSetting,
	|	GoodsTable.VATRate                                        AS VATRate
	|
	|FROM
	|	Document.OBEntrySalesForPastPeriods.WholesaleSalesInPastPeriods AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
	|	ON GoodsTable.ItemsLocationAttributes.Products = DimensionCostOfProduction.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = DimensionCostOfProduction.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = DimensionCostOfProduction.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = DimensionCostOfProduction.StorageLocation
	|		AND &EmptyAssignment = DimensionCostOfProduction.Purpose
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber                                       AS LineNumber,
	|	GoodsTable.DateRecord                                     AS Period,
	|	&Department                                                  AS Department,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes
	|		ELSE DimensionCostOfProduction.DimensionKey
	|	END                                                           AS ItemsLocationAttributes,
	|	UNDEFINED                                                    AS SetAccountingDimension,
	|	GoodsTable.AccountingDimensionByPartners                         AS AccountingDimensionByPartners,
	|	UNDEFINED                                                    AS SalesOrder,
	|	CASE
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			OR GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|		THEN VALUE(Enum.InventoryTypes.OperationService)
	|		ELSE VALUE(Enum.InventoryTypes.OwnGoods)
	|	END                                                           AS InventoryType,
	|	&Manager                                                       AS Manager,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|			AND  NOT (GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|					OR GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)) THEN
	|		GoodsTable.InventoryOwnerAttribute
	|	ELSE
	|		UNDEFINED
	|	END                                                           AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN GoodsTable.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		WHEN GoodsTable.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef)
	|		WHEN ISNULL(GoodsTable.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom, FALSE)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END) AS AccountingSection,
	|	(CASE
	|		WHEN &BatchAccountingVersion22 AND &FIFORollingValuation THEN &VATTaxation
	|		ELSE UNDEFINED END)								    AS VATActivityType,
	|	&Warehouse                                                          AS Warehouse,
	|	&Contract                                                        AS Contract,
	|	&CustomerTermsOfSales                                            AS Terms,
	|	&ManagementAccountingCurrency                                     AS ARAPCurrency,
	|	&ManagementAccountingCurrency                                     AS DocumentCurrency,
	|	&VATTaxation                                             AS VATTaxation,
	|	VALUE(Enum.BusinessTransactions.RetailSaleOfGoods) AS BusinessOperation,
	|
	|	&LineOfBusiness                                       AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN GoodsTable.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                          AS ProductLineOfBusiness,
	|
	|	UNDEFINED                                                    AS SourceOfProductFinancialAccountingGroup,
	|	UNDEFINED                                                    AS SourceOfARAPFinancialAccountingGroup,
	|
	|	0                                                               AS Cost,
	|	0                                                               AS CostExcludingVAT,
	|	0                                                               AS LocalCost,
	|	0                                                               AS ManualDiscount,
	|	0                                                               AS DiscountMarkupAmount,
	|	0                                                               AS AmountInARAPCurrency,
	|	0                                                               AS AmountExcludingVATInARAPCurrency,
	|	0                                                               AS AmountInDocumentCurrency,
	|	0                                                               AS AmountExcludingVATInDocumentCurrency,
	|	GoodsTable.Count                                        AS Count,
	|	GoodsTable.Sum                                             AS RevenueAmount,
	|	GoodsTable.AmountExcludingVAT                                       AS RevenueAmountExcludingVAT,
	|	GoodsTable.SumCompl                                         AS RevenueAmountExclVATLocal,
	|	GoodsTable.SumCompl + GoodsTable.VATLocal                 AS RevenueAmountIncludingVATLocal,
	|
	|	GoodsTable.RowID                              AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RetailSaleOfGoods) AS BusinessTransactionSetting,
	|	GoodsTable.VATRate                                        AS VATRate
	|
	|FROM
	|	Document.OBEntrySalesForPastPeriods.RetailSales AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionCostOfProduction
	|	ON GoodsTable.ItemsLocationAttributes.Products = DimensionCostOfProduction.Products
	|		AND GoodsTable.ItemsLocationAttributes.Characteristic = DimensionCostOfProduction.Characteristic
	|		AND GoodsTable.ItemsLocationAttributes.Series = DimensionCostOfProduction.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = DimensionCostOfProduction.ProductCostElement
	|		AND GoodsTable.ItemsLocationAttributes.StorageLocation = DimensionCostOfProduction.StorageLocation
	|		AND &EmptyAssignment = DimensionCostOfProduction.Purpose
	|WHERE
	|	GoodsTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|
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
	
	QueryText =
	"SELECT
	|	&MetadataIdentifier AS RefType,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS StorageLocation,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Department,
	|	&Period AS IBDocumentDate,
	|	&Ref AS Ref,
	|	&Number AS IBDocumentNumber,
	|	UNDEFINED AS Status,
	|	&EmployeeResponsible AS EmployeeResponsible,
	|	&Author AS Author,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	&Comment AS Comment,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	CASE
	|		WHEN &Currency = DocumentData.Organization.LocalAccountingCurrency
	|			THEN SUM(ISNULL(DataOfTabularPartFinancialResultExpenses.ExpenseAmount, 0) +
	|				ISNULL(DataOfTabularPartFinancialResultIncome.IncomeAmount, 0) +
	|				ISNULL(TableDataGiftCertificates.SumCompl, 0) +
	|				ISNULL(DataOfTablePartWholesaleSales.SumCompl, 0) +
	|				ISNULL(DataOfTabularPartRetailSales.SumCompl, 0))
	|		ELSE SUM(ISNULL(DataOfTabularPartFinancialResultExpenses.ExpenseAmount, 0) +
	|			ISNULL(DataOfTabularPartFinancialResultIncome.IncomeAmount, 0) +
	|			ISNULL(TableDataGiftCertificates.AmountInCertificateCurrency, 0) +
	|			ISNULL(DataOfTablePartWholesaleSales.Sum, 0) + ISNULL(DataOfTabularPartRetailSales.Sum, 0))
	|	END AS Sum,
	|	&Currency AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	FALSE AS ReverseTransactionCorrection,
	|	UNDEFINED AS ReversedDocument,
	|	UNDEFINED AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntrySalesForPastPeriods AS DocumentData
	|		LEFT JOIN Document.OBEntrySalesForPastPeriods.WholesaleSalesInPastPeriods AS
	|			DataOfTablePartWholesaleSales
	|		ON DocumentData.Ref = DataOfTablePartWholesaleSales.Ref
	|		LEFT JOIN Document.OBEntrySalesForPastPeriods.RetailSales AS
	|			DataOfTabularPartRetailSales
	|		ON DocumentData.Ref = DataOfTabularPartRetailSales.Ref
	|		LEFT JOIN Document.OBEntrySalesForPastPeriods.GiftCertificates AS
	|			TableDataGiftCertificates
	|		ON DocumentData.Ref = TableDataGiftCertificates.Ref
	|		LEFT JOIN Document.OBEntrySalesForPastPeriods.FinancialResultExpenses AS
	|			DataOfTabularPartFinancialResultExpenses
	|		ON DocumentData.Ref = DataOfTabularPartFinancialResultExpenses.Ref
	|		LEFT JOIN Document.OBEntrySalesForPastPeriods.FinancialResultIncome AS
	|			DataOfTabularPartFinancialResultIncome
	|		ON DocumentData.Ref = DataOfTabularPartFinancialResultIncome.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|GROUP BY
	|	DocumentData.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.OBEntrySalesForPastPeriods";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntrySalesForPastPeriods));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = QueryText;
	Result.ParameterValues = ParameterValues;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	OBEntryLocalization.EnterBalancesAboutPastSalesAddPrintCommands(PrintCommands);
	
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
	
EndProcedure

#EndRegion


#EndRegion

#EndIf
