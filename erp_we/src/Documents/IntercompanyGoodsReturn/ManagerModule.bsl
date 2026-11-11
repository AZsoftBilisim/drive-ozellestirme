#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyRecipient");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization,CompanyRecipient";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization,CompanyRecipient";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Contract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "CompanyRecipient";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "CompanyRecipient";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "RecipientCompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization, CompanyRecipient";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Warehouse";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);		
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("SerialAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	IntercompanyGoodsReturnLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.IntercompanyGoodsReturn") Then
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
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers);
		QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AddTextsToReflectSettlements(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		IntercompanyGoodsReturnLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.IntercompanyGoodsReturn - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	PartsOfQueryText = New Array;
	TextOfRequestPart =
	"SELECT
	|	TableTypesOfStocks_.RowID AS RowID,
	|	DimensionKeys.Products AS Products,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.ExciseTaxAmount AS ExciseTaxAmount,
	|	ISNULL(TypesOfStocksOfRecipient.SubjectToExcise, FALSE) AS SubjectToExcise,
	|	TypesOfStocksOfRecipient.BusinessUnitProduction AS BusinessUnitProduction,
	|	TableTypesOfStocks_.CostDefiningMethod AS CostDefiningMethod,
	|	TheseGrounds.Date AS DateOfTransferDocument,
	|	ISNULL(TheseGrounds.Date, &Period) AS Date
	|INTO TableTypesOfStocks_
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN Document.CustomerInvoiceIntercompany AS TheseGrounds
	|		ON TableTypesOfStocks_.DocumentTransfers_ = TheseGrounds.Ref
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS DimensionKeys
	|		ON TableTypesOfStocks_.ItemsLocationAttributes = DimensionKeys.Ref
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksOfRecipient
	|		ON TableTypesOfStocks_.RecipientInventoryOwnerAttribute = TypesOfStocksOfRecipient.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	Products,
	|	Date";
	PartsOfQueryText.Add(TextOfRequestPart);
	
	RequestTextParameters = ExcisableGoodsAccounting.ParametersOfQueryTextTTExciseCategoriesOfItems();
	RequestTextParameters.SelectingCategoriesByDate = False;
	RequestTextParameters.ProductTableName_ = "TableTypesOfStocks_";
	RequestTextParameters.FieldNamePeriod = "Date";
	
	TextOfRequestPart = ExcisableGoodsAccounting.QueryTextTTExciseCategoriesOfItems(, RequestTextParameters);
	PartsOfQueryText.Add(TextOfRequestPart);
	
	TextOfRequestPart =
	"SELECT
	|	TableTypesOfStocks_.RowID             AS RowID,
	|	TableTypesOfStocks_.Products                    AS Products,
	|	TableTypesOfStocks_.Count                      AS Count,
	|	TableTypesOfStocks_.ExciseTaxAmount                     AS ExciseAmountInCurrencyLocal,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(TableExciseCategories.ItemCategory,
	|		VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)) AS ExcisableGoodsCategory,
	|	CASE WHEN TableTypesOfStocks_.SubjectToExcise
	|		THEN ISNULL(TableExciseCategories.ConversionFactor_, 0) * TableTypesOfStocks_.Count
	|		ELSE 0
	|	END                                              AS QuantityInExcisableCategoryUOM,
	|	TableTypesOfStocks_.BusinessUnitProduction       AS BusinessUnitProduction,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = &CostFromTransferDocument
	|		AND TableTypesOfStocks_.DateOfTransferDocument < &BeginningOfMonthOfPeriod
	|	THEN
	|		VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	WHEN TableTypesOfStocks_.CostDefiningMethod <> &CostFromTransferDocument
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END                                              AS BusinessTransactionSetting
	|
	|INTO TTRecipientSInventory
	|FROM
	|	TableTypesOfStocks_ AS TableTypesOfStocks_
	|
	|	INNER JOIN TTExciseCategoriesOfItems AS TableExciseCategories
	|		ON TableTypesOfStocks_.Products = TableExciseCategories.Products
	|		AND TableTypesOfStocks_.Date = TableExciseCategories.Period
	|
	|WHERE
	|	TableExciseCategories.ExcisableGoods
	|	AND TableExciseCategories.ItemCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableTypesOfStocks_
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTExciseCategoriesOfItems
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Period AS Period,
	|	&CompanyRecipient AS Organization,
	|	TableTypesOfStocks_.BusinessUnitProduction AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.Return) AS KindOfTransactionWithExcisableGoods,
	|	-TableTypesOfStocks_.Count AS Count,
	|	-TableTypesOfStocks_.QuantityInExcisableCategoryUOM AS QuantityInExcisableCategoryUOM,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	-TableTypesOfStocks_.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTRecipientSInventory AS TableTypesOfStocks_
	|WHERE
	|	TableTypesOfStocks_.ExciseAmountInCurrencyLocal <> 0
	|	OR TableTypesOfStocks_.ExciseAmountInCurrencyMgmt <> 0
	|	OR TableTypesOfStocks_.QuantityInExcisableCategoryUOM <> 0
	|";
	PartsOfQueryText.Add(TextOfRequestPart);
	
	Query.Text = StrConcat(PartsOfQueryText, Common.QueryBatchSeparator());
	
	RatePeriod = Attributes.Period;
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.CompanyRecipient);

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.CompanyRecipient);
	
	Query.SetParameter("Period", Attributes.Period);
	Query.SetParameter("BeginningOfMonthOfPeriod", BegOfMonth(Attributes.Period));
	Query.SetParameter("CostFromTransferDocument", Enums.WaysToCalculateReturnCost.FromTransferDocument);
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	Query.SetParameter("Country", RegistrationCountry);
	Query.SetParameter("UseExcisableGoods", ExcisableGoodsAreUsed(Attributes));

	Return Query.Execute();

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
	
	Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	IntercompanyGoodsReturnLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the "Return between organizations" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
// Returns:
//	 ValueTableRow, Undefined - the command to output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.IntercompanyGoodsReturn) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.IntercompanyGoodsReturn.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.IntercompanyGoodsReturn);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerInvoiceIntercompany";

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
	
	IntercompanyGoodsReturnLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// The sample values of requisites of the document on the link.
//
// Parameters:
//  DocumentRef - DocumentRef.IntercompanyGoodsReturn - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Attributes = New Structure();
	
	Attributes.Insert("Date", '00010101');
	Attributes.Insert("BusinessOperation", Enums.BusinessTransactions.EmptyRef());
	Attributes.Insert("Organization", Catalogs.Companies.EmptyRef());
	Attributes.Insert("Partner", Catalogs.Partners.EmptyRef());
	Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Attributes.Insert("SenderOrganization", Catalogs.Companies.EmptyRef());
	Attributes.Insert("CompanyRecipient", Catalogs.Companies.EmptyRef());
	Attributes.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	Attributes.Insert("DocumentAmount", 0);
	Attributes.Insert("AmountARAP", 0);
	Attributes.Insert("ARAPAccountingViaSeparateCounterparty", False);
	Attributes.Insert("SalesContract", Catalogs.CounterpartyContracts.EmptyRef());
	Attributes.Insert("PurchasingContract", Catalogs.CounterpartyContracts.EmptyRef());
	
	Query = New Query("
	|SELECT
	|	Data.Date                              AS Date,
	|	Data.BusinessOperation             AS BusinessOperation,
	|	Data.Organization                       AS Organization,
	|	(CASE WHEN Data.ARAPAccountingViaSeparateCounterparty 
	|		THEN Data.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END)                                   AS Partner,
	|	(CASE WHEN Data.ARAPAccountingViaSeparateCounterparty
	|		THEN Data.Counterparty
	|		ELSE Data.Organization
	|	END)                                   AS Counterparty,
	|	Data.Organization                       AS SenderOrganization,
	|	Data.CompanyRecipient             AS CompanyRecipient,
	|	Data.Currency                            AS ARAPCurrency,
	|	Data.DocumentAmount                    AS DocumentAmount,
	|	(CASE WHEN Data.Posted
	|		THEN Data.DocumentAmount
	|		ELSE 0
	|	END)                                   AS AmountARAP,
	|	Data.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	Data.SalesContract                    AS SalesContract,
	|	Data.PurchasingContract                    AS PurchasingContract
	|FROM
	|	Document.IntercompanyGoodsReturn AS Data
	|WHERE
	|	Data.Ref = &DocumentRef
	|");
	Query.SetParameter("DocumentRef", DocumentRef);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(Attributes, Selection);
	EndIf;
	Return Attributes;
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return IntercompanyGoodsReturnLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - the text of the request to create temporary tables
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return IntercompanyGoodsReturnLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#Region SetOfSeries

// Names of the details that the parameters for specifying the series depend on.
//
// Returns:
//	String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	
	AttributesNames = "Warehouse,Date";
	
	Return AttributesNames;
	
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
	
	SeriesSpecificationParameters.FullObjectName = "Document.IntercompanyGoodsReturn";
	
	WarehouseSeriesParameters = WarehousesServer.UseOfSeriesInStock(Object.Warehouse, False);
	
	SeriesSpecificationParameters.UseCostAccountingByBatches = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.UseItemsBatch  = WarehouseSeriesParameters.UseCostAccountingByBatches;
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = True;
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.MovementInFinancialAccounting);
	
	SeriesSpecificationParameters.TSSeriesName   = "Goods";
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	SeriesSpecificationParameters.Date         = Object.Date;
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Returns the request text for calculating the statuses of specifying series.
//
// Parameters:
//	SeriesSpecificationParameters - Structure - the composition of fields is set in the function
//		Nomenclaturales.Parametrizatsii.
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
	|	Goods.Series               AS Series,
	|	Goods.Count          AS Count,
	|	Goods.BatchesIndicationStatus AS BatchesIndicationStatus
	|INTO Goods
	|FROM
	|	&Goods AS Goods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber         AS LineNumber,
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
	|	END                      AS BatchesIndicationStatus
	|INTO Statuses
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|			INNER JOIN Catalog.Warehouses AS Warehouses
	|			ON BatchAccountingPolicies.Warehouse = Warehouses.Ref
	|		ON BatchAccountingPolicies.Warehouse = &Warehouse
	|			AND CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
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

// Initializes parameters that serve the selection of assignments in document forms.
//
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "AllAssignments", False, "Object.Goods.Purpose");
	
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
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(CompanyRecipient)
	|	) AND ValueAllowed(Partner)
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.IntercompanyGoodsReturn, DocumentObject.IntercompanyGoodsReturn - document for the return of goods between organizations.
//
// Returns:
//	See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation.
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	AttributesNames =
		"Date,
		|CompanyRecipient,
		|Contract,
		|SalesContract,
		|Warehouse,
		|Department,
		|BusinessOperation,
		|ARAPAccountingViaSeparateCounterparty,
		|LineOfBusiness";
	
	DocumentAttributes = New Structure(AttributesNames);
	
	If TypeOf(Document) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FieldsToFillIn = "Date, Warehouse, LineOfBusiness, Department";
	
	ReturnOfGoods =
		DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes, FieldsToFillIn);
	
	FillParameters.Organization	= DocumentAttributes.CompanyRecipient;
	FillParameters.Contract		= ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.SalesContract,
										DocumentAttributes.Contract);
	
	FillParameters.ReturnOfGoodsFromCustomer = ReturnOfGoods;
	FillParameters.ReturnOfGoodsFromCommissionAgent = Not ReturnOfGoods;
	
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters to register the issued invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.IntercompanyGoodsReturn, DocumentObject.IntercompanyGoodsReturn - document for the return of goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of the Invoice data().
//
Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	DocumentAttributes = New Structure("Ref, Organization, CompanyRecipient, Counterparty, VATTaxation, 
										|Date, BusinessOperation, ARAPAccountingViaSeparateCounterparty, CustomerVATExempt");
	
	If TypeOf(Document) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, Organization, VATTaxation");
	
	If Not ValueIsFilled(RegistrationParameters.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	EndIf;
	
	RegistrationParameters.Counterparty = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.CompanyRecipient);
	
	RegistrationParameters.ReturnOfGoodsToVendor =
		Not DocumentAttributes.CustomerVATExempt
		And DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	
	If
		RegistrationParameters.ReturnOfGoodsToVendor
		And RegistrationParameters.Date >= VATAccountingERP.AccountingSettings().DateWhenRefundsAreReflectedInCorrectiveSF
		And Not DocumentAttributes.ARAPAccountingViaSeparateCounterparty
	Then
		RegistrationParameters.AdjustmentUnderApprovalOfParties = True;
		RegistrationParameters.Organization = DocumentAttributes.CompanyRecipient;
	EndIf;
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters for registering received invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.IntercompanyGoodsReturn, DocumentObject.IntercompanyGoodsReturn - document for the return of goods between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of invoices received().
//
Function ParametersForRegisteringInvoicesReceived(Document) Export
	
	DocumentAttributes = New Structure("Ref, Organization, CompanyRecipient, Counterparty, VATTaxation, 
										|Date, BusinessOperation, ARAPAccountingViaSeparateCounterparty, CustomerVATExempt");
	
	If TypeOf(Document) = Type("DocumentRef.IntercompanyGoodsReturn") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, VATTaxation");
	
	If Not ValueIsFilled(RegistrationParameters.Date) Then
		RegistrationParameters.Date = CurrentSessionDate();
	EndIf;
	
	RegistrationParameters.Organization = DocumentAttributes.CompanyRecipient;
	RegistrationParameters.Counterparty  = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.Organization);
	
	RegistrationParameters.ReturnOfGoodsFromVATPayer =
		Not DocumentAttributes.CustomerVATExempt
		And DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn
		And DocumentAttributes.ARAPAccountingViaSeparateCounterparty;
	RegistrationParameters.ReturnOfGoodsFromVATDefaulter =
		DocumentAttributes.CustomerVATExempt
		Or DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn;
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ARAPAccountingViaSeparateCounterparty,
			|BusinessOperation,
			|SalesContract,
			|PurchasingContract");
		ARAPAccountingViaSeparateCounterparty = StructureFillingData.ARAPAccountingViaSeparateCounterparty;
		BusinessOperation             = StructureFillingData.BusinessOperation;
		SalesContract                    = StructureFillingData.SalesContract;
		PurchasingContract                    = StructureFillingData.PurchasingContract;
	ElsIf FillingData = Undefined Then
		ARAPAccountingViaSeparateCounterparty = False;
		BusinessOperation             = Undefined;
		SalesContract                    = Undefined;
		PurchasingContract                    = Undefined;
	Else
		ARAPAccountingViaSeparateCounterparty = FillingData.ARAPAccountingViaSeparateCounterparty;
		BusinessOperation             = FillingData.BusinessOperation;
		SalesContract                    = FillingData.SalesContract;
		PurchasingContract                    = FillingData.PurchasingContract;
	EndIf;
	
	// Array of parameters - separately for shipment and acceptance
	
	// Shipment (Seller Organization):
	
	SettlementParameters = New Array();
	
	#Region Shipment
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	//With certain values of the document details, he may not change the mutual settlements. 
	//An example is the transfer of goods to the commission.StructureParameters
	//If the value is negative, the settlement objects will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan                  = 
		BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	ParametersStructure.ModifiesDeliveryShipmentPlan        = False;
		
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)";
	
	//They are used to generate calculation and analytics objects.
	ParametersStructure.Organization = "Object.Organization";
	ParametersStructure.Partner    = ?(ARAPAccountingViaSeparateCounterparty, "Object.Partner", Catalogs.Partners.OurEnterprise);
	ParametersStructure.Counterparty = ?(ARAPAccountingViaSeparateCounterparty, "Object.Counterparty", "Object.CompanyRecipient");
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract    = ?(ARAPAccountingViaSeparateCounterparty, "Object.SalesContract", "Object.Contract");
	
	ContractSettlementProcedure = ?(ValueIsFilled(SalesContract),"Object.SalesContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.Contract.ARAPObjectSettings");
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.PathToTSDataPaymentDecryption  = "";
	Else
		ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetails";
		ParametersStructure.FormItems.AddToPaymentDecryption = "ARAPDetailsSelectionByStock";
		ParametersStructure.FormItems.ARAPDetails = "ARAPDetails";
	EndIf;;
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.PaymentMethod                      = "";
	
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	//They are used to determine the value of payments in the currency and in the form of editing payment rules.
	//The details for the object of calculations are used in conducting.
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	ParametersStructure.ARAPObject                   = "Object.ARAPObject";
	
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroup";
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	#EndRegion
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Receiving
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	#Region RequiredParameters2
	
	//Determines which register the parameters move, which common forms, enumerations and directories to use.
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting; 
	
	//With certain values of the document details, he may not change the mutual settlements. 
	//An example is the transfer of goods to the commission.StructureParameters
	//If the value is negative, the settlement objects will be hidden, but it will be possible to change currencies and the exchange rate.
	ParametersStructure.ChangesPaymentPlan               = 
		BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = False;
		
	ParametersStructure.ChangesCalculationsByString           = 
		"DataSource.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)";
	
	//They are used to generate calculation and analytics objects.
	ParametersStructure.Organization                      = "Object.CompanyRecipient";
	ParametersStructure.Partner    = ?(ARAPAccountingViaSeparateCounterparty, "Object.Partner", Catalogs.Partners.OurEnterprise);
	ParametersStructure.Counterparty = ?(ARAPAccountingViaSeparateCounterparty, "Object.Counterparty", "Object.Organization");
	
	#EndRegion
	
	#Region OptionalParameters
	
	ParametersStructure.Contract    = ?(ARAPAccountingViaSeparateCounterparty, "Object.PurchasingContract", "Object.Contract");
	
	ContractSettlementProcedure = ?(ValueIsFilled(PurchasingContract),"Object.PurchasingContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.Contract.ARAPObjectSettings");
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	
	//It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	ParametersStructure.CashAccount                            = "";
	ParametersStructure.PaymentMethod                      = "";
	ParametersStructure.CompanyBankAccount        = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	
	ParametersStructure.ForeignCurrencyTransaction                    = "";
	
	//The details for the object of calculations are used in conducting.
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectOfRecipient";
	
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroupOfRecipient";
	
	#EndRegion
	
	SettlementParameters.Add(ParametersStructure);
	
	#EndRegion
	
	Return SettlementParameters;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Trả hàng';
							|ru = 'Возврат товаров';
							|en = 'Return of goods'; fa = 'برگشت کالا';
							|it = 'Restituzione della merce';
							|pl = 'Zwrot towarów';
							|tr = 'Ürün iadesi'"));
	IntercompanyGoodsReturnLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
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
#Region Excisable_Items

// Returns an indication of the use of excisable items of own production in the document.
//
// Parameters:
//	DocumentObject - DocumentObject.IntercompanyGoodsReturn, FormDataStructure - Document data.
//
// Returns:
//	Boolean - excisable items of own production are used.
//
Function ExcisableGoodsAreUsed(DocumentObject) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return False;
	EndIf;
	
	Return DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntercompanyGoodsReturn;
	
EndFunction

#EndRegion
#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.ARAPAccountingViaSeparateCounterparty Then
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
			Data, Presentation, StandardProcessing, "IntercompanyGoodsReturn");
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("ARAPAccountingViaSeparateCounterparty");
	
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
	Query.Text = "
	|SELECT
	|	DocumentData.Number AS Number,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Warehouse AS Warehouse,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.DocumentTransfers_ AS DocumentTransfers_,
	|	DocumentData.Department AS Department,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Author AS Author,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.SalesContract AS SalesContract,
	|	DocumentData.PurchasingContract AS PurchasingContract,
	|
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	(CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|		THEN TRUE ELSE FALSE END) AS ThisIsReturnOfGoods,
	|	(CASE WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|		THEN TRUE ELSE FALSE END) AS ThisIsCommissionRefund,
	|
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.CompanyRecipient AS CompanyRecipient,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Partner AS Partner,
	|
	|	DocumentData.CustomerVATExempt AS CustomerVATExempt,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	DocumentData.ARAPObjectOfRecipient AS ARAPObjectOfRecipient,
	|	UNDEFINED AS AdjustmentPeriod_
	|	
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentData
	|	
	|	LEFT JOIN Catalog.IntercompanyContracts AS Contracts
	|	ON DocumentData.Contract = Contracts.Ref
	|		AND Contracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|
	|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
	|	ON DocumentData.SalesContract = CounterpartyContractsClient.Ref
	|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|	
	|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
	|	ON DocumentData.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
	|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	MetadataIdentifier = Common.MetadataObjectID("Document.IntercompanyGoodsReturn");
	
	StringPattern = "vi = 'Trả lại từ ""%1""';
					|ru = 'Возврат из ""%1""';
					|en = 'Return from ""%1""';
					|it = 'Reso da ""%1""';
					|pl = 'Zwrot z ""%1""';
					|tr = '""%1""''den iade'"; // @NStr
	OrganizationInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Organization);
	
	StringPattern = "vi = 'Trả lại vào ""%1""';
					|ru = 'Возврат в ""%1""';
					|en = 'Return to ""%1""';
					|it = 'Reso a ""%1""';
					|pl = 'Zwrot do ""%1""';
					|tr = '""%1""''ye iade'"; // @NStr
	InformationAboutRecipientOrganization = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.CompanyRecipient);
	
	DocumentNumber          = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);
	
	// filling the data request with the following parameters
	Query.SetParameter("Ref",								Attributes.Ref);
	Query.SetParameter("Number",								Attributes.Number);
	Query.SetParameter("Period",								Attributes.Period);
	Query.SetParameter("BeginningOfMonthOfPeriod",                BegOfMonth(Attributes.Period));
	Query.SetParameter("BusinessOperation",				Attributes.BusinessOperation);
	Query.SetParameter("ThisIsReturnOfGoods",					Attributes.ThisIsReturnOfGoods);
	Query.SetParameter("ThisIsCommissionRefund",				Attributes.ThisIsCommissionRefund);
	Query.SetParameter("Organization",						Attributes.Organization);
	Query.SetParameter("CompanyRecipient",				Attributes.CompanyRecipient);
	Query.SetParameter("Warehouse",								Attributes.Warehouse);
	Query.SetParameter("Department",						Attributes.Department);
	Query.SetParameter("Currency",								Attributes.Currency);
	Query.SetParameter("LocalAccountingCurrency",		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",			Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ARAPAccountingViaSeparateCounterparty",	Attributes.ARAPAccountingViaSeparateCounterparty);
	Query.SetParameter("Counterparty",							Attributes.Counterparty);
	Query.SetParameter("VATTaxation",					Attributes.VATTaxation);
	Query.SetParameter("DocumentTransfers_",					Attributes.DocumentTransfers_);
	Query.SetParameter("Manager",							Attributes.Manager);
	Query.SetParameter("Author",								Attributes.Author);
	Query.SetParameter("Partner",							Attributes.Partner);
	Query.SetParameter("Contract",							Attributes.Contract);
	Query.SetParameter("SalesContract",						Attributes.SalesContract);
	Query.SetParameter("PurchasingContract",						Attributes.PurchasingContract);
	Query.SetParameter("LineOfBusiness",			Attributes.LineOfBusiness);
	Query.SetParameter("AccountingForLBCosts",						Attributes.AccountingForLBCosts);
	Query.SetParameter("AccountingForIncomeUnderLB",					Attributes.AccountingForIncomeUnderLB);
	Query.SetParameter("AccountingForSettlementsWithSuppliersUnderLB",		Attributes.AccountingForSettlementsWithSuppliersUnderLB);
	Query.SetParameter("IncomingDocumentDate",				Attributes.IncomingDocumentDate);
	Query.SetParameter("Comment",						Attributes.Comment);
	Query.SetParameter("DocumentAmount",						Attributes.DocumentAmount);
	Query.SetParameter("Posted",							Attributes.Posted);
	Query.SetParameter("DeletionMark",					Attributes.DeletionMark);
	Query.SetParameter("MetadataIdentifier",			MetadataIdentifier);
	Query.SetParameter("OrganizationInformation",			OrganizationInformation);
	Query.SetParameter("InformationAboutRecipientOrganization",	InformationAboutRecipientOrganization);
	Query.SetParameter("DocumentNumber",						DocumentNumber);
	Query.SetParameter("IncomingDocumentNumber",			IncomingDocumentNumber);
	Query.SetParameter("CustomerVATExempt",			Attributes.CustomerVATExempt);
	Query.SetParameter("ARAPObject",						Attributes.ARAPObject);
	Query.SetParameter("ARAPObjectOfRecipient",			Attributes.ARAPObjectOfRecipient);
	Query.SetParameter("ExternalDocumentName",		Attributes.ExternalDocumentName);
	Query.SetParameter("CostFromTransferDocument",   Enums.WaysToCalculateReturnCost.FromTransferDocument);
	Query.SetParameter("AdjustmentPeriod_",				Attributes.AdjustmentPeriod_);
	
	AccountingParametersForOrganization 			= VATAccountingERP.AccountingParametersForOrganization(Attributes.CompanyRecipient, Attributes.Period);
	AccountingParametersForSenderSOrganization 	= VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	Query.SetParameter("TaxationOfOrganization", AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("SenderTaxation", AccountingParametersForSenderSOrganization.BasicTaxationVATSales);
	
	Query.SetParameter("DateWhenRefundsAreReflectedInCorrectiveSF", VATAccountingERP.AccountingSettings().DateWhenRefundsAreReflectedInCorrectiveSF);
	Query.SetParameter("DisplayBasicUnitsOfMeasureInPrintForms", Constants.DisplayBasicUnitsOfMeasureInPrintForms.Get());
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups",
		GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	UseExcisableGoods = False;
	RegistrationCountry = Catalogs.WorldCountries.EmptyRef();
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	RegistrationCountry =
		SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.CompanyRecipient);
	Query.SetParameter("UseExcisableGoods", UseExcisableGoods);
	Query.SetParameter("RegistrationCountry", RegistrationCountry);
	
EndProcedure

Procedure InitializeProductAnalysisKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestPreliminary = New Query("
		|SELECT DISTINCT
		|	Table.Warehouse           AS Warehouse,
		|	Table.Products    AS Products,
		|	Table.Characteristic  AS Characteristic,
		|	Table.Purpose      AS Purpose,
		|	Table.Series           AS Series
		|FROM 
		|	(SELECT DISTINCT
		|		&CompanyRecipient AS Warehouse,
		|		Goods.Products    AS Products,
		|		Goods.Characteristic  AS Characteristic,
		|		&Purpose            AS Purpose,
		|		&Series                 AS Series
		|	FROM
		|		Document.IntercompanyGoodsReturn.Goods AS Goods
		|	WHERE
		|		Goods.Ref = &Ref 
		|		AND NOT &ThisIsReturnOfGoods
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		&Organization           AS Warehouse,
		|		Goods.Products    AS Products,
		|		Goods.Characteristic  AS Characteristic,
		|		&Purpose            AS Purpose,
		|		&Series                 AS Series
		|	FROM
		|		Document.IntercompanyGoodsReturn.Goods AS Goods
		|	WHERE
		|		Goods.Ref = &Ref 
		|		AND NOT &ThisIsReturnOfGoods
		|
		|	UNION ALL
		|
		|	SELECT DISTINCT
		|		Goods.ItemsLocationAttributes.StorageLocation            AS Warehouse,
		|		Goods.ItemsLocationAttributes.Products     AS Products,
		|		Goods.ItemsLocationAttributes.Characteristic   AS Characteristic,
		|		&Purpose            AS Purpose,
		|		Goods.ItemsLocationAttributes.Series            AS Series
		|	FROM
		|		Document.IntercompanyGoodsReturn.Goods AS Goods
		|	WHERE
		|		Goods.Ref = &Ref 
		|		AND NOT &KeepRecordsOfInventoryCostByAssignments
		|
		|	) AS Table
		|
		|	LEFT JOIN 
		|		InformationRegister.ItemsLocationAttributes AS Dimension
		|	ON 
		|		Table.Products = Dimension.Products 
		|		AND Table.Characteristic = Dimension.Characteristic
		|		AND Table.Purpose = Dimension.Purpose
		|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
		|		AND Table.Series = Dimension.Series
		|		AND Table.Warehouse = Dimension.StorageLocation
		|WHERE
		|	Dimension.DimensionKey IS NULL
		|");
	RequestPreliminary.SetParameter("Ref", Query.Parameters.Ref);
	RequestPreliminary.SetParameter("CompanyRecipient", Query.Parameters.CompanyRecipient);
	RequestPreliminary.SetParameter("Organization", Query.Parameters.Organization);
	RequestPreliminary.SetParameter("Series", Catalogs.ItemsBatches.EmptyRef());
	RequestPreliminary.SetParameter("Purpose", Catalogs.Assignments.EmptyRef());
	RequestPreliminary.SetParameter("ThisIsReturnOfGoods", Query.Parameters.ThisIsReturnOfGoods);
	RequestPreliminary.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	Selection = RequestPreliminary.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.Currency, Undefined,
		Query.Parameters.Period, Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	RatePeriod = Query.Parameters.Period;

	ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
	
	Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
EndProcedure

Procedure SetParameterOfAccountingAnalyticsRequestRecipient(Query)
	
	If Query.Parameters.Property("AccountingAnalyticsRecipient") Then
		Return;
	EndIf;
	
	KeyClient = New Structure();
	KeyClient.Insert("Organization",             Query.Parameters.CompanyRecipient);
	KeyClient.Insert("Partner",                 Catalogs.Partners.OurEnterprise);
	KeyClient.Insert("Counterparty",              Query.Parameters.Organization);
	KeyClient.Insert("Contract",                 Query.Parameters.Contract);
	KeyClient.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	Query.SetParameter("AccountingAnalyticsRecipient",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(KeyClient));
	
EndProcedure

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf;
	
	ValueText_ =
	"SELECT
	|	HeaderData_.Date                    AS Period,
	|	InventoryTable.Ref               AS Ref,
	|	HeaderData_.BusinessOperation   AS BusinessOperation,
	|	HeaderData_.CompanyRecipient   AS Organization,
	|	HeaderData_.Department           AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                               AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                               AS Contract,
	|	HeaderData_.Shipper        AS Shipper,
	|	HeaderData_.CustomerVATExempt AS CustomerVATExempt,
	|	FALSE                                AS RetailCustomer,
	|	FALSE                                AS FundsReturnedToRetailBuyer,
	|	""""                                AS CashReturnDocumentNumberToRetailBuyer,
	|	DATETIME(1, 1, 1)                  AS DateOfDocumentOfReturnOfCashToRetailBuyer,
	|	InventoryTable.Ref               AS DocumentReturnPolicy,
	|	InventoryTable.DocumentSalesOfGoodsAndServices   AS DocumentSalesOfGoodsAndServices,
	|	HeaderData_.ARAPObjectOfRecipient AS ARAPObject,
	|	HeaderData_.VATTaxation      AS VATTaxation,
	|	HeaderData_.VATTaxation      AS VATActivityType,
	|	InventoryTable.Products         AS Products,
	|	InventoryTable.Characteristic       AS Characteristic,
	|	InventoryTable.Series                AS Series,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Count
	|		ELSE InventoryTable.NumberOfPackages
	|	END                               AS Count,
	|	CASE
	|		WHEN &DisplayBasicUnitsOfMeasureInPrintForms
	|			THEN InventoryTable.Products.UnitOfMeasure
	|		ELSE &QueryTextUnitOfMeasure
	|	END                               AS UnitOfMeasure,
	|	InventoryTable.QuantityByGBRN     AS QuantityByGBRN,
	|	InventoryTable.ExciseTaxAmount          AS ExciseTaxAmount,
	|	InventoryTable.VATRate            AS VATRate,
	|	VALUE(Catalog.FEACN.EmptyRef) AS FEACNCode,
	|	InventoryTable.InventoryOwnerAttribute           AS InventoryOwnerAttribute,
	|	InventoryTable.CCDNumber             AS CCDNumber,
	|	0                                   AS LineNumber,
	|	InventoryTable.RowID  AS RowID,
	|	HeaderData_.LineOfBusiness AS LineOfBusiness,
	|	InventoryTable.Purpose           AS Purpose,
	|	UNDEFINED                        AS ConsignedGoodsCustomer,
	|	InventoryTable.FinRecordID  AS FinRecordID,
	|	InventoryTable.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	FALSE                                AS ReturnOfGoodsViaCommissionAgent
	|FROM
	|	TTRecipientSInventory AS InventoryTable
	|		LEFT JOIN Document.IntercompanyGoodsReturn AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|WHERE
	|	HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|	AND (HeaderData_.Date < &DateWhenRefundsAreReflectedInCorrectiveSF OR NOT HeaderData_.ARAPAccountingViaSeparateCounterparty)
	|";
	
	ValueText_ = StrReplace(
		ValueText_,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"InventoryTable.Package",
			"InventoryTable.Products"));
	VATAccountingERP.ReflectReturnOfGoodsFromBuyer(Query, QueryTexts, Registers, ValueText_);
	
	TextProducts_1 =
	"SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	HeaderData_.BusinessOperation  AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.CompanyRecipient
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	HeaderData_.Shipper       AS Shipper,
	|	HeaderData_.GoodsRecipient        AS GoodsRecipient,
	|	HeaderData_.CustomerVATExempt AS CustomerVATExempt,
	|	InventoryTable.Ref              AS DocumentReturnPolicy,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	Dimension.Purpose               AS Purpose,
	|	InventoryTable.VATRate           AS VATRate,
	|	InventoryTable.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN InventoryTable.DocumentTransfers_ = VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|			THEN NULL
	|		ELSE InventoryTable.DocumentTransfers_
	|	END AS DocumentInflow,
	|	InventoryTable.DocumentTransfers_.TransferForActivity_ AS VATActivityType,
	|	InventoryTable.RowID AS RowID,
	|	InventoryTable.Ref.ARAPObject.UUID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.IntercompanyGoodsReturn AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|	AND HeaderData_.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|	AND (HeaderData_.Date < &DateWhenRefundsAreReflectedInCorrectiveSF OR NOT HeaderData_.ARAPAccountingViaSeparateCounterparty)
	|";
	
	VATAccountingERP.ReflectReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextProducts_1);
	
EndProcedure

Function QueryTextTableGoodsBatchMovement(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsBatchMovement";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                                           AS Document,
	|	&Period                                                           AS Period,
	|	&Ref                                                           AS Recorder,
	|	SeriesTable.Products                                         AS Products,
	|	SeriesTable.Characteristic                                       AS Characteristic,
	|	CASE
	|		WHEN ISNULL(SeriesTable.Purpose.RecordsInWarehouseRegisters, FALSE)
	|			THEN SeriesTable.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef)
	|	END                                                             AS Purpose,
	|	SeriesTable.Series                                                AS Series,
	|	SeriesTable.Count                                           AS Count,
	|	&Warehouse                                                            AS Sender,
	|	&Warehouse                                                            AS Recipient,
	|	VALUE(Catalog.Warerooms.EmptyRef)              AS WareroomOfRecipient,
	|	VALUE(Enum.WarehouseTransactions.MovementInFinancialAccounting) AS WarehouseOperation,
	|	TRUE                                                            AS ThisIsWarehouseRecord
	|FROM
	|	Document.IntercompanyGoodsReturn.Goods AS SeriesTable
	|
	|WHERE
	|	SeriesTable.Ref = &Ref
	|	AND SeriesTable.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates

	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates =
	"SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|WHERE
	|	DocumentDataHeader.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	Table.ARAPObject AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	SettlementObjectReturn.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
	|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
	|		ON SettlementObjectReturn.Ref = DocumentDataHeader.ARAPObject
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND DocumentDataHeader.ARAPObject <> Table.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	DocumentDataHeader.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	SettlementObjectReturn.Ref AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	SettlementObjectReturn.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
	|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|		ON Table.Ref = DocumentDataHeader.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
	|		ON SettlementObjectReturn.Ref = DocumentDataHeader.ARAPObject
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND DocumentDataHeader.ARAPObject <> Table.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentDataHeader.Ref AS Ref,
	|	DocumentDataHeader.CompanyRecipient AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObjectOfRecipient AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	DocumentDataHeader.Currency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|WHERE
	|	DocumentDataHeader.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	SettlementObjectReturn.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	ARAPObjects.Ref AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	Table.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
	|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|		ON DocumentDataHeader.Ref = Table.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
	|		ON DocumentDataHeader.ARAPObjectOfRecipient = SettlementObjectReturn.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SenderSPaymentObjects
	|		ON Table.ARAPObject = SenderSPaymentObjects.Ref
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON SenderSPaymentObjects.Object = ARAPObjects.Object
	|			AND NOT ARAPObjects.DeletionMark
	|		AND ARAPObjects.PaymentType_ = CASE
	|			WHEN SenderSPaymentObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		END
	|		AND ARAPObjects.Organization = DocumentDataHeader.CompanyRecipient
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND DocumentDataHeader.ARAPObjectOfRecipient <> ARAPObjects.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	SettlementObjectReturn.Organization AS Organization,
	|	DocumentDataHeader.Date AS DateOfCourse,
	|	DocumentDataHeader.ARAPObjectOfRecipient AS ARAPObject,
	|	DocumentDataHeader.Currency AS DocumentCurrency,
	|	Table.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
	|		INNER JOIN Document.IntercompanyGoodsReturn AS DocumentDataHeader
	|		ON DocumentDataHeader.Ref = Table.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
	|		ON DocumentDataHeader.ARAPObjectOfRecipient = SettlementObjectReturn.Ref
	|		INNER JOIN Catalog.ARAPObjects AS SenderSPaymentObjects
	|		ON Table.ARAPObject = SenderSPaymentObjects.Ref
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON SenderSPaymentObjects.Object = ARAPObjects.Object
	|		AND NOT ARAPObjects.DeletionMark
	|		AND ARAPObjects.PaymentType_ = CASE
	|			WHEN SenderSPaymentObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|				THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|			ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		END
	|		AND ARAPObjects.Organization = DocumentDataHeader.CompanyRecipient
	|WHERE
	|	Table.Ref IN (&Ref)
	|	AND DocumentDataHeader.ARAPObjectOfRecipient <> ARAPObjects.Ref";
	
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);

	#EndRegion
	
	#Region AddTextsToReflectMutualSettlements
	
	TextReturn = "
		|SELECT
		|	Table.Ref                          AS Ref,
		|	Table.Organization                     AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                   AS Partner,
		|	Table.Date                            AS RecorderDate,
		|	Table.Number                           AS RecorderNumber,
		|	
		|	Table.Date                            AS PaymentDate,
		|	Table.ARAPObject                  AS ARAPObject,
		|	Table.DocumentAmount                  AS Sum,
		|	Table.DocumentAmount                  AS AmountARAP,
		|	0                                       AS AmountARAPByPackage,
		|	0                                       AS ToReceive,
		|
		|	FALSE                                    AS InvoiceForOrders,
		|	Table.Currency                          AS ARAPCurrency,
		|	Table.BusinessOperation           AS BusinessOperation,
		|	UNDEFINED                            AS CashFlowItem,
		|	Table.Currency                          AS DocumentCurrency,
		|	Table.Date                            AS DateOfCourse,
		|
		|	Table.ARAPObject.UUID AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting
		|FROM
		|	Document.IntercompanyGoodsReturn AS Table
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ARAPObjects.Ref = Table.ARAPObject
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)";
		
	TextTranscriptOfPayment = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	Document.Organization                          AS Organization,
		|	CASE WHEN Document.ARAPAccountingViaSeparateCounterparty
		|		THEN Document.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                              AS Partner,
		|	SettlementObjectReturn.ARAPCurrency    AS ARAPCurrency,
		|
		|	SettlementObjectReturn.Ref                  AS CalculationObjectSource,
		|	ARAPObjects.Ref                        AS CalculationObjectReceiver,
		|
		|	Document.Date                                 AS RecorderDate,
		|	Document.Number                                AS RecorderNumber,
		|	Document.Currency                               AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	
		|	Document.Date                                 AS DateOfCourse,
		|	Table.Sum                                 AS Sum,
		|	Table.AmountARAP                   AS AmountARAP
		|	
		|FROM
		|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
		|		INNER JOIN Document.IntercompanyGoodsReturn AS Document
		|			ON Table.Ref = Document.Ref
		|		INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
		|			ON SettlementObjectReturn.Ref = Document.ARAPObject
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|			ON ARAPObjects.Ref = Table.ARAPObject
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Document.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
		|	AND SettlementObjectReturn.Ref <> ARAPObjects.Ref
		|";
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.CarryingOutReturnOfGoodsToSupplier(Query, QueryTexts, Registers, TextReturn, TextTranscriptOfPayment);
	
	#EndRegion
	
	#Region AddTextsToReflectSalesSettlements
	TextReturn =
		"SELECT
		|	Table.Ref                                           AS Ref,
		|	Table.CompanyRecipient                            AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                    AS Partner,
		|	
		|	Table.ARAPObjectOfRecipient                         AS ARAPObject,
		|	Table.DocumentAmount                                   AS AmountARAP,
		|	Table.DocumentAmount                                   AS Sum,
		|	Table.DocumentAmount                                   AS AmountDue,
		|	
		|	Table.Date                                             AS RecorderDate,
		|	Table.Number                                            AS RecorderNumber,
		|	Table.Currency                                           AS ARAPCurrency,
		|	Table.BusinessOperation                            AS BusinessOperation,
		|	UNDEFINED                                             AS CashFlowItem,
		|	Table.Date                                             AS DateOfCourse,
		|	Table.Currency                                           AS DocumentCurrency
		|FROM
		|	Document.IntercompanyGoodsReturn AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)";
	
	TextTranscriptOfPayment = "
		|SELECT
		|	Table.Ref                                AS Ref,
		|	SettlementObjectReturn.Organization             AS Organization,
		|	SettlementObjectReturn.Partner                 AS Partner,
		|
		|	Document.ARAPObjectOfRecipient             AS CalculationObjectSource,
		|	ARAPObjects.Ref                        AS CalculationObjectReceiver,
		|
		|	Document.Date                                 AS RecorderDate,
		|	Document.Number                                AS RecorderNumber,
		|	Table.ARAPCurrency                  AS ARAPCurrency,
		|	Document.Currency                               AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.ARAPSettlement) AS BusinessOperation,
		|	
		|	Document.Date                                 AS DateOfCourse,
		|	Table.Sum                                 AS Sum,
		|	Table.AmountARAP                   AS AmountARAP
		|	
		|FROM
		|	Document.IntercompanyGoodsReturn.ARAPDetails AS Table
		|
		|	INNER JOIN Document.IntercompanyGoodsReturn AS Document
		|		ON Document.Ref = Table.Ref
		|
		|	INNER JOIN Catalog.ARAPObjects AS SettlementObjectReturn
		|		ON Document.ARAPObjectOfRecipient = SettlementObjectReturn.Ref
		|
		|	INNER JOIN Catalog.ARAPObjects AS SenderSPaymentObjects
		|		ON Table.ARAPObject = SenderSPaymentObjects.Ref
		|
		|	INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON SenderSPaymentObjects.Object = ARAPObjects.Object
		|			AND ARAPObjects.PaymentType_ = 
		|				CASE WHEN SenderSPaymentObjects.PaymentType_ = VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|					THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
		|					ELSE VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
		|				END
		|			AND ARAPObjects.Organization = Document.CompanyRecipient
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Document.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
		|	AND Document.ARAPObjectOfRecipient <> ARAPObjects.Ref";

	ARAPAccountingPostingCustomers.CarryingOutReturnOfGoodsFromCustomer(Query, QueryTexts, Registers, TextReturn, TextTranscriptOfPayment);
	
	#EndRegion
	
EndProcedure

Function QueryTextTTSenderSInventory(Query, QueryTexts) Export
	
	RegisterName = "TTSenderSInventory";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	InitializeProductAnalysisKeys(Query);
	
	QueryText =  "
	|SELECT
	|	InventoryKinds.ItemsLocationAttributes                              AS DimensionReturnPolicy,
	|	AnalysisOfProductsWithoutAssignment.DimensionKey                    AS ReturnAnalyticsWithoutAssignment,
	|	UNDEFINED                                                        AS CommissionAnalytics,
	|	InventoryKinds.LineNumber                                             AS LineNumber,
	|	Dimension.Products                                              AS Products,
	|	Dimension.Characteristic                                            AS Characteristic,
	|	InventoryKinds.InventoryOwnerAttribute                                              AS InventoryOwnerAttribute,
	|	InventoryKinds.InventoryOwnerAttribute                                              AS InventoryTypeAccounting,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                                   AS InventoryType,
	|	InventoryKinds.CCDNumber                                                AS CCDNumber,
	|	InventoryKinds.CCDNumber.CCDNumberType                                   AS CCDNumberCCDNumberType,
	|	InventoryKinds.Count                                              AS Count,
	|	InventoryKinds.QuantityByGBRN                                        AS QuantityByGBRN,
	|	InventoryKinds.AmountIncludingVAT                                               AS AmountIncludingVAT,
	|	InventoryKinds.VATRate                                               AS VATRate,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	InventoryKinds.VATAmount                                                AS VATAmount,
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount                        AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                     AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                   AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                                      AS VATAmountMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                    AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                                  AS AmountExcludingVATCompl,	
	|	ISNULL(Amounts.VATAmountCompl, 0)                                     AS VATAmountCompl,	
	|	ISNULL(Amounts.VATBaseLocal, 0)                                      AS VATBaseLocal,
	|	InventoryKinds.RecipientInventoryOwnerAttribute                                    AS RecipientInventoryOwnerAttribute,
	|	InventoryKinds.RowID                                     AS RowID,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|			THEN UNDEFINED
	|		ELSE InventoryKinds.DocumentTransfers_ END)                       AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|			THEN DATETIME(1,1,1)
	|		ELSE InventoryKinds.DocumentTransfers_.Date END)                	AS SalePeriod,
	|	InventoryKinds.CostDefiningMethod							AS CostDefiningMethod,
	|	InventoryKinds.ByUninvoicedGoods                                    AS ByUninvoicedGoods,
	|	Dimension.WarehouseArea                                       AS Warehouse,
	|	Dimension.WarehouseArea.ShopFloorStockroom                       AS ShopFloorStockroom,
	|	(CASE
	|		WHEN InventoryKinds.DocumentTransfers_ <> VALUE(Document.CustomerInvoiceIntercompany.EmptyRef)
	|			THEN InventoryKinds.DocumentTransfers_.TransferForActivity_
	|		ELSE &SenderTaxation END)                        AS VATActivityType,
	|	CASE
	|		WHEN InventoryKinds.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|			THEN InventoryKinds.RowID
	|		ELSE InventoryKinds.Ref.ARAPObject.UUID
	|	END                                                               AS FinRecordID
	|
	|INTO TTSenderSInventory
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS InventoryKinds
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Dimension.Ref 
	|
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfProductsWithoutAssignment
	|	ON
	|		Dimension.Products = AnalysisOfProductsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalysisOfProductsWithoutAssignment.Characteristic
	|		AND Dimension.Series = AnalysisOfProductsWithoutAssignment.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfProductsWithoutAssignment.ProductCostElement
	|		AND Dimension.StorageLocation = AnalysisOfProductsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfProductsWithoutAssignment.Purpose
	|
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON InventoryKinds.InventoryOwnerAttribute.FinancialAccountingGroup = FAG.Ref
	|
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		InventoryKinds.Ref = Amounts.Ref
	|		AND InventoryKinds.RowID = Amounts.RowID
	|WHERE
	|	InventoryKinds.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = CostCalculationDocumentsPosting.RequestTextStringCodesForBatchAccountingAnalytics(
		Metadata.Documents.IntercompanyGoodsReturn.Name,
		"InventoryKinds");
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""InventoryKinds"" 							AS TabularSectionName,
	|	DocumentTable.LineNumber 				AS LineNumber,
	|	CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentData.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END										AS Vendor,
	|	CASE WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
	|		THEN DocumentData.Counterparty
	|		ELSE DocumentData.Organization
	|	END										AS Counterparty,
	|	DocumentTable.VATRate 					AS VATRate,
	|	DocumentData.VATTaxation			AS VATTaxation,
	|	ISNULL(FAG.VATAssetTaxClass, VALUE(Enum.AssetKinds.Goods)) AS AssetTaxClass,
	|	LineCodes.RowCode							AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS DocumentTable
	|	INNER JOIN Document.IntercompanyGoodsReturn AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|		AND LineCodes.TabularSectionName = ""InventoryKinds""
	|	LEFT JOIN Catalog.InventoryAccountingGroups AS FAG
	|		ON DocumentTable.InventoryOwnerAttribute.FinancialAccountingGroup = FAG.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTRecipientSInventory(Query, QueryTexts) Export
	
	RegisterName = "TTRecipientSInventory";
	
	InitializeProductAnalysisKeys(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAmountsOfDocumentsInAccountingCurrencies", QueryTexts) Then 
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	EndIf;
	
	QueryText =  "
	|SELECT
	|	TableTypesOfStocks_.Ref                                                                   AS Ref,
	|	TableTypesOfStocks_.ItemsLocationAttributes                                               AS DimensionReturnPolicy,
	|	AnalysisOfProductsWithoutAssignment.DimensionKey                                            AS ReturnAnalyticsWithoutAssignment,
	|	CommissionAnalytics.DimensionKey                                                             AS CommissionAnalytics,
	|	ISNULL(TableTypesOfStocks_.ItemsLocationAttributesShipment.Ref, TableTypesOfStocks_.ItemsLocationAttributes) AS DimensionShipments,
	|	ISNULL(AnalyticsForShipmentsWithoutDestination.DimensionKey, AnalysisOfProductsWithoutAssignment.DimensionKey) AS AnalyticsForShipmentsWithoutDestination,
	|	TableTypesOfStocks_.LineNumber                                                              AS LineNumber,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products                                  AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic                                AS Characteristic,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Series                                         AS Series,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute                                                     AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute                                                               AS SenderSInventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType                                          			AS SenderInventoryType,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute                                                     AS InventoryTypeAccounting,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType                                          AS InventoryType,
	|	TableTypesOfStocks_.CCDNumber                                                                 AS CCDNumber,
	|	TableTypesOfStocks_.CCDNumber.CCDNumberType                                                    AS CCDNumberCCDNumberType,
	|	TableTypesOfStocks_.Count                                                               AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN                                                         AS QuantityByGBRN,
	|	TableTypesOfStocks_.NumberOfPackages                                                       AS NumberOfPackages,
	|	TableTypesOfStocks_.Package                                                                 AS Package,
	|	TableTypesOfStocks_.AmountIncludingVAT                                                                AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATRate                                                                AS VATRate,
	|	TableTypesOfStocks_.VATAmount                                                                 AS VATAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount                                                              AS ExciseTaxAmount,
	|	TableTypesOfStocks_.ExciseTaxAmount                                                              AS ExciseAmountInCurrencyLocal,
	|	CAST(TableTypesOfStocks_.ExciseTaxAmount * &ConversionRatioFromLocalToMan AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)                                                             AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)                                                           AS AmountExcludingVATMan,
	|	ISNULL(Amounts.VATAmountMan, 0)                                                              AS VATAmountMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)                                                            AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)                                                          AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)                                                             AS VATAmountCompl,
	|	TableTypesOfStocks_.RecipientInventoryOwnerAttribute.Currency                                              AS Currency,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass                                                      AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation                                               AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes                                             AS LotVendorAttributes,
	|	TableTypesOfStocks_.RowID                                                      AS RowID,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod <> &CostFromTransferDocument
	|			THEN UNDEFINED
	|		ELSE TableTypesOfStocks_.DocumentTransfers_ END)                     					AS DocumentSalesOfGoodsAndServices,
	|	(CASE
	|		WHEN TableTypesOfStocks_.CostDefiningMethod <> &CostFromTransferDocument
	|			THEN DATETIME(1,1,1)
	|		ELSE TableTypesOfStocks_.DocumentTransfers_.Date END)                					AS SalePeriod,
	|	TableTypesOfStocks_.CostDefiningMethod											AS CostDefiningMethod,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea                           AS Warehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom           AS ShopFloorStockroom,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose                                    AS Purpose,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.Purpose                            AS PurposeOfShipment,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.StorageLocation                         AS OriginWarehouse,
	|	TableTypesOfStocks_.ItemsLocationAttributesShipment.StorageLocation.ShopFloorStockroom         AS ShopPantryShipment,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment                                                       AS TypeOfShipmentInventoryAccounting,
	|	TableTypesOfStocks_.InventoryOwnerAttributeShipment                                                       AS InventoryOwnerAttributeShipment,
	|	ISNULL(TableTypesOfStocks_.DocumentTransfers_.Department, &Department) 				AS ImplementationDivision,
	|	TableTypesOfStocks_.ByUninvoicedGoods                                                     AS ByUninvoicedGoods,
	|	TableTypesOfStocks_.Cost_                                           					AS Cost_,
	|	(CASE
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN TableTypesOfStocks_.Cost_
	|		ELSE TableTypesOfStocks_.CostExcludingVAT_ END)                    					AS CostExcludingVAT_,
	|	TableTypesOfStocks_.CostLocal                                       					AS CostLocal,
	|	TableTypesOfStocks_.CDCost                                         					AS CDCost,
	|	TableTypesOfStocks_.TDCost                                         					AS TDCost,
	|	TableTypesOfStocks_.RowID                                                      AS FinRecordID,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = &CostFromTransferDocument
	|		AND TableTypesOfStocks_.DocumentTransfers_.Date < &BeginningOfMonthOfPeriod
	|	THEN
	|		VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	WHEN TableTypesOfStocks_.CostDefiningMethod <> &CostFromTransferDocument
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn)
	|	ELSE
	|		VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSale)
	|	END                                                                                       AS BusinessTransactionSetting
	|INTO TTRecipientSInventory
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS TableTypesOfStocks_
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfProductsWithoutAssignment
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalysisOfProductsWithoutAssignment.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalysisOfProductsWithoutAssignment.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalysisOfProductsWithoutAssignment.Series
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfProductsWithoutAssignment.ProductCostElement
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation = AnalysisOfProductsWithoutAssignment.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfProductsWithoutAssignment.Purpose
	|
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS CommissionAnalytics
	|	ON 
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = CommissionAnalytics.Products 
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = CommissionAnalytics.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommissionAnalytics.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommissionAnalytics.ProductCostElement
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommissionAnalytics.Series
	|		AND &Organization = CommissionAnalytics.StorageLocation
	|
	|	LEFT JOIN
	|		InformationRegister.ItemsLocationAttributes AS AnalyticsForShipmentsWithoutDestination
	|	ON
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsForShipmentsWithoutDestination.Products
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsForShipmentsWithoutDestination.Characteristic
	|		AND TableTypesOfStocks_.ItemsLocationAttributes.Series = AnalyticsForShipmentsWithoutDestination.Series
	|		AND ISNULL(TableTypesOfStocks_.ItemsLocationAttributesShipment.StorageLocation,
	|			ISNULL(TableTypesOfStocks_.DocumentTransfers_.Warehouse, TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation)) = AnalyticsForShipmentsWithoutDestination.StorageLocation
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForShipmentsWithoutDestination.Purpose
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsForShipmentsWithoutDestination.ProductCostElement
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 		= TableTypesOfStocks_.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""InventoryKinds""
	|
	|	LEFT JOIN 
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|
	|INDEX BY
	|	CCDNumberCCDNumberType";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSenderSInventory", QueryTexts) Then
		QueryTextTTSenderSInventory(Query, QueryTexts);
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	&Warehouse AS Warehouse,
	|	&Organization AS Organization,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|
	|	GoodsTable.Count AS Count,
	|	GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|
	|	&Organization AS ShipmentCompany,
	|	GoodsTable.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	GoodsTable.DimensionReturnPolicy AS CorItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	UNDEFINED AS DocumentSalesOfGoodsAndServices,
	|	GoodsTable.RecipientInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	FALSE AS Primary
	|FROM
	|	TTSenderSInventory AS GoodsTable
	|WHERE
	|	NOT GoodsTable.ByUninvoicedGoods
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	&Warehouse AS Warehouse,
	|	&CompanyRecipient AS Organization,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|
	|	-GoodsTable.Count AS Count,
	|	-GoodsTable.QuantityByGBRN AS QuantityByGBRN,
	|
	|	&Organization AS ShipmentCompany,
	|	GoodsTable.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	GoodsTable.DimensionShipments AS CorItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	GoodsTable.DocumentSalesOfGoodsAndServices  AS DocumentSalesOfGoodsAndServices,
	|	GoodsTable.InventoryOwnerAttributeShipment AS CorInventoryOwnerAttribute,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = &CostFromTransferDocument
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Primary
	|FROM
	|	TTRecipientSInventory AS GoodsTable
	|WHERE
	|	NOT GoodsTable.ByUninvoicedGoods
	|
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure SetFIFORequestParameterRollingScoreOfRecipient(Query)
	
	If Query.Parameters.Property("FIFORollingEstimateOfRecipient") Then
		Return;
	EndIf;
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate("FinancialAccountingPolicy",
		Query.Parameters.CompanyRecipient,
		BegOfMonth(Query.Parameters.Period));
		
	Query.SetParameter("FIFORollingEstimateOfRecipient",
		(AccountingPolicyParameters <> Undefined
			And AccountingPolicyParameters.InventoryValuationMethod = Enums.InventoryValuationMethods.FIFORollingValuation));
	
EndProcedure

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetParameterOfAccountingAnalyticsRequestRecipient(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	InventoryKinds.LineNumber       AS LineNumber,
	|	&Period                       AS Period,
	|	&AdjustmentPeriod_          AS AdjustmentPeriod_,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|		 AND &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.DimensionReturnPolicy
	|		WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|		 AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ReturnAnalyticsWithoutAssignment
	|		WHEN InventoryKinds.SalePeriod < &BeginningOfMonthOfPeriod
	|		 AND &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.DimensionReturnPolicy
	|		WHEN InventoryKinds.SalePeriod < &BeginningOfMonthOfPeriod
	|		 AND NOT &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.ReturnAnalyticsWithoutAssignment
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN InventoryKinds.DimensionShipments
	|		ELSE InventoryKinds.AnalyticsForShipmentsWithoutDestination
	|	END AS ItemsLocationAttributes,
	|	UNDEFINED                  AS SalesOrder,
	|	&AccountingAnalyticsRecipient     AS AccountingDimensionByPartners,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|			THEN &Department
	|		ELSE InventoryKinds.ImplementationDivision
	|	END 						  AS Department,
	|	InventoryKinds.InventoryType        AS InventoryType,
	|	InventoryKinds.InventoryTypeAccounting AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN InventoryKinds.ShopFloorStockroom 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock) END) AS AccountingSection,
	|	InventoryKinds.VATActivityType AS VATActivityType,
	|	&Manager                     AS Manager,
	|	-InventoryKinds.Count       AS Count,
	|	-InventoryKinds.AmountIncludingVATMan     AS RevenueAmount,
	|	-InventoryKinds.AmountExcludingVATMan   AS RevenueAmountExcludingVAT,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountIncludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.Cost_
	|		ELSE 0
	|	END AS Cost,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostExcludingVAT_
	|		ELSE 0
	|	END AS CostExcludingVAT,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting THEN 0
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATMan
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostExcludingVAT_
	|		ELSE 0 END AS CostMan,
	|	CASE
	|		WHEN InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		 OR InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromCurrentDocument)
	|			THEN - InventoryKinds.AmountExcludingVATCompl
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN - InventoryKinds.CostLocal
	|		ELSE 0 END AS LocalCost,
	|
	|	InventoryKinds.VATActivityType AS VATTaxation,
	|	CASE WHEN InventoryKinds.CostDefiningMethod = &CostFromTransferDocument
	|		AND InventoryKinds.SalePeriod < &BeginningOfMonthOfPeriod
	|	THEN
	|		VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|	WHEN InventoryKinds.CostDefiningMethod <> &CostFromTransferDocument
	|		THEN VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn)
	|	ELSE
	|		VALUE(Enum.BusinessTransactions.ReverseOfSale)
	|	END AS BusinessOperation,
	|	-InventoryKinds.AmountExcludingVATCompl AS RevenueAmountExclVATLocal,
	|	-(InventoryKinds.AmountExcludingVATCompl + InventoryKinds.VATAmountCompl) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	InventoryKinds.OriginWarehouse AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	CASE
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.DimensionReturnPolicy.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END AS ProductLineOfBusiness,
	|
	|	&Currency AS ARAPCurrency,
	|	InventoryKinds.AmountIncludingVAT AS AmountInARAPCurrency,
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	InventoryKinds.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|	-InventoryKinds.ExciseAmountInCurrencyLocal AS ExciseAmountInCurrencyLocal,
	|	-InventoryKinds.ExciseAmountInCurrencyMgmt AS ExciseAmountInCurrencyMgmt,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		InventoryKinds.InventoryOwnerAttribute
	|	ELSE
	|		InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectOfRecipient AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	InventoryKinds.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN InventoryKinds.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|			AND InventoryKinds.SalePeriod >= &BeginningOfMonthOfPeriod
	|			AND InventoryKinds.InventoryType IN (VALUE(Enum.InventoryTypes.OwnGoods),
	|				VALUE(Enum.InventoryTypes.ConsignedGoods))
	|			AND (InventoryKinds.OriginWarehouse <> InventoryKinds.Warehouse
	|			OR InventoryKinds.TypeOfShipmentInventoryAccounting <> InventoryKinds.InventoryTypeAccounting
	|			AND InventoryKinds.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			OR InventoryKinds.Purpose <> InventoryKinds.PurposeOfShipment)
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|		ELSE InventoryKinds.BusinessTransactionSetting
	|	END AS BusinessTransactionSetting,
	|	InventoryKinds.VATRate AS VATRate
	|	
	|FROM
	|	TTRecipientSInventory AS InventoryKinds
	|WHERE
	|	&ThisIsReturnOfGoods
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoodsForTransfer(Query, QueryTexts, Registers)
	RegisterName = "CompanyGoodsForTransfer";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSenderSInventory", QueryTexts) Then
		QueryTextTTSenderSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&CompanyRecipient AS CompanyOwner,
	|	&Warehouse AS Warehouse,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.InventoryOwnerAttribute AS SellerInventoryOwnerAttribute,
	|	GoodsTable.CCDNumber AS CCDNumber,
	|	GoodsTable.Count AS Returned,
	|	GoodsTable.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	GoodsTable.RecipientInventoryOwnerAttribute AS CorInventoryOwnerAttribute,
	|	GoodsTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	TRUE AS Primary
	|FROM
	|	TTSenderSInventory AS GoodsTable
	|	
	|WHERE
	|	GoodsTable.ByUninvoicedGoods
	|	
	|ORDER BY
	|	GoodsTable.LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates"; 
	
	QueryText = "
	|SELECT
	|	ExchangeRates.Currency AS Currency,
	|
	|	(DocumentExchangeRate.CourseNumerator * ExchangeRates.CourseDenominator)
	|  / (DocumentExchangeRate.CourseDenominator * ExchangeRates.CourseNumerator) AS ConversionFactor_
	|
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period,
	|		Currency IN (
	|			SELECT DISTINCT
	|				TableTypesOfStocks_.RecipientInventoryOwnerAttribute.Currency AS Currency
	|			FROM
	|				Document.IntercompanyGoodsReturn.InventoryKinds AS TableTypesOfStocks_
	|
	|			WHERE
	|				TableTypesOfStocks_.Ref = &Ref
	|				AND TableTypesOfStocks_.RecipientInventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			) AND BaseCurrency = &LocalAccountingCurrency
	|	) AS ExchangeRates
	|
	|	INNER JOIN
	|		InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &Currency AND BaseCurrency = &LocalAccountingCurrency) AS DocumentExchangeRate
	|	ON
	|		TRUE
	|
	|WHERE
	|	DocumentExchangeRate.CourseDenominator <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf;
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber			AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt)	AS RecordType,
	|	&Period									AS Period,
	|	&CompanyRecipient					AS Organization,
	|	TableTypesOfStocks_.Currency				AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute			AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products			AS Products,
	|	TableTypesOfStocks_.Characteristic		AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber				AS CCDNumber,
	|	TableTypesOfStocks_.Ref.DocumentTransfers_ AS DocumentSalesOfGoodsAndServices,
	|	&BusinessOperation					AS BusinessOperation,
	|	(-TableTypesOfStocks_.Count)		AS Count,
	|	0										AS QuantityConsumed,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END									AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN -TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END									AS RevenueAmountMan,
	|	(-TableTypesOfStocks_.Count)		AS QuantityToRegister,
	|	(-TableTypesOfStocks_.QuantityByGBRN)	AS QuantityForRegistrationByProductBatchID,
	|	0										AS QuantityConsumedForIncoiceRegistration,
	|	0										AS QuantityIsWrittenOffForRegistrationByProductBatchID,
	|	CASE
	|		WHEN TableTypesOfStocks_.Currency = &Currency
	|			THEN -TableTypesOfStocks_.AmountIncludingVAT
	|		ELSE -TableTypesOfStocks_.AmountIncludingVAT * ExchangeRates.ConversionFactor_
	|	END									AS RevenueAmountToRegister,
	|	Dimension.DimensionKey					AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.RowID	AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntercompanyCommissionReturn) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID	AS RowID
	|FROM
	|	TTRecipientSInventory AS TableTypesOfStocks_
	|		LEFT JOIN TTExchangeRates AS ExchangeRates
	|		ON TableTypesOfStocks_.Currency = ExchangeRates.Currency
	|		
	|		INNER JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON TableTypesOfStocks_.Products = Dimension.Products
	|			AND TableTypesOfStocks_.Characteristic = Dimension.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|			AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|			AND TableTypesOfStocks_.InventoryOwnerAttribute.GoodsOwner = Dimension.StorageLocation
	|WHERE
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND &ThisIsReturnOfGoods
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""InventoryKinds"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	0 AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	CASE
	|		WHEN DocumentTable.Ref.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn) 
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObject AS ARAPObject,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure 

Function QueryTextTableLotsOfGoodsOfOrganizations(Query, QueryTexts, Registers)
	RegisterName = "LotsOfGoodsOfOrganizations";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&CompanyRecipient AS Organization,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	&Ref AS DocumentInflow, 
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	-GoodsTable.Count AS Count,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -GoodsTable.Cost_
	|		ELSE -GoodsTable.AmountIncludingVATMan
	|	END                                                AS Cost,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -GoodsTable.CostExcludingVAT_
	|		ELSE -GoodsTable.AmountExcludingVATMan
	|	END                                                AS CostExcludingVAT,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -GoodsTable.CostLocal
	|		ELSE -GoodsTable.AmountExcludingVATCompl

	|	END AS LocalCost,
	|	0                                                    AS VATLocal,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -GoodsTable.CDCost
	|		ELSE 0
	|	END                                                AS PermanentDifference,
	|	CASE
	|		WHEN GoodsTable.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|			THEN -GoodsTable.TDCost
	|		ELSE 0
	|	END                                                AS CostTD,
	|
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	UNDEFINED AS CorItemsLocationAttributes,
	|	UNDEFINED AS CorInventoryOwnerAttribute,
	|	VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomer) AS BusinessOperation,
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	TRUE AS Primary,
	|	UNDEFINED AS DocumentSource
	|FROM
	|	TTRecipientSInventory AS GoodsTable
	|
	|WHERE
	|	&BatchAccountingVersion21
	|	AND GoodsTable.CostDefiningMethod <> &CostFromTransferDocument
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTSenderSInventory", QueryTexts) Then
		QueryTextTTSenderSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	InventoryKinds.DimensionReturnPolicy AS ItemsLocationAttributes,
	|	InventoryKinds.Warehouse AS Warehouse,
	|	InventoryKinds.InventoryType AS InventoryType,
	|	InventoryKinds.InventoryTypeAccounting AS InventoryOwnerAttribute,
	|
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &CompanyRecipient
	|	END AS Counterparty,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	InventoryKinds.Count AS Count,
	|
	|	InventoryKinds.AmountIncludingVATMan AS Sum,
	|	CAST((InventoryKinds.AmountExcludingVAT * &ConversionRateToManCurrency) AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	InventoryKinds.AmountIncludingVATCompl AS SumCompl,
	|	CAST((InventoryKinds.AmountExcludingVAT * &FactorOfConversionToCurrencyOfRegul) AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	InventoryKinds.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&Currency AS ARAPCurrency,
	|	InventoryKinds.AmountIncludingVAT AS AmountInARAPCurrency,
	|	InventoryKinds.AmountIncludingVAT - InventoryKinds.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN InventoryKinds.InventoryOwnerAttribute
	|		ELSE InventoryKinds.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTSenderSInventory AS InventoryKinds
	|WHERE
	|	&ThisIsReturnOfGoods AND InventoryKinds.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|"; 
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsProductsProducts(Query, QueryTexts, Registers)
	RegisterName = "RecordsProductsProducts";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	InitializeProductAnalysisKeys(Query);
	
	QueryText = 
	"SELECT
	|	&Period                                                             AS Period,
	|	&BusinessOperation                                              AS BusinessOperation,
	|	&CompanyRecipient                                              AS Organization,
	|	&Department                                                      AS Department,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE AnalysisOfProductsWithoutAssignment.DimensionKey
	|	END                                                               AS ItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                               AS LineOfBusiness,
	|	Dimension.StorageLocation                                                     AS Warehouse,
	|	InventoryKinds.InventoryOwnerAttribute.InventoryType                                   AS InventoryType,
	|	InventoryKinds.InventoryOwnerAttribute												AS InventoryOwnerAttribute,
	|
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments 
	|		THEN InventoryKinds.ItemsLocationAttributes
	|		ELSE AnalysisOfProductsWithoutAssignment.DimensionKey
	|	END                                                               AS CorItemsLocationAttributes,
	|	CASE WHEN &KeepRecordsOfInventoryCostByAssignments
	|		THEN InventoryKinds.ItemsLocationAttributes.Purpose.LineOfBusiness
	|		ELSE UNDEFINED
	|	END                                                               AS CorLineOfBusiness,
	|	Dimension.StorageLocation                                                     AS CorWarehouseCorCommissionAgentCorBusinessUnit,
	|	InventoryKinds.RecipientInventoryOwnerAttribute.InventoryType                         AS CorInventoryType,
	|	InventoryKinds.RecipientInventoryOwnerAttribute									AS CorInventoryOwnerAttribute,
	|
	|	InventoryKinds.Count                                              AS Count,
	|	InventoryKinds.Count                                              AS CorQuantity,
	|
	|	CAST((InventoryKinds.AmountIncludingVAT * &ConversionRateToManCurrency)  AS NUMBER(31,2)) AS Cost,
	|	CAST((InventoryKinds.AmountIncludingVAT * &ConversionRateToManCurrency)  AS NUMBER(31,2)) AS CostExcludingVAT,
	|	CAST((InventoryKinds.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul) AS NUMBER(31,2)) AS LocalCost,
	|
	|	InventoryKinds.InventoryOwnerAttribute												AS SourceOfProductFinancialAccountingGroup,
	|	InventoryKinds.RecipientInventoryOwnerAttribute									AS CorSourceOfItemsFinancialAccountingGroup
	|
	|FROM
	|	Document.IntercompanyGoodsReturn.InventoryKinds AS InventoryKinds
	|	LEFT JOIN 
	|		Catalog.InventoryLocationAttributeKeys AS Dimension
	|	ON
	|		InventoryKinds.ItemsLocationAttributes = Dimension.Ref 
	|
	|	LEFT JOIN 
	|		InformationRegister.ItemsLocationAttributes AS AnalysisOfProductsWithoutAssignment
	|	ON
	|		Dimension.Products = AnalysisOfProductsWithoutAssignment.Products
	|		AND Dimension.Characteristic = AnalysisOfProductsWithoutAssignment.Characteristic 
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalysisOfProductsWithoutAssignment.ProductCostElement
	|		AND Dimension.Series = AnalysisOfProductsWithoutAssignment.Series 
	|		AND Dimension.StorageLocation = AnalysisOfProductsWithoutAssignment.StorageLocation 
	|		AND VALUE(Catalog.Assignments.EmptyRef) = AnalysisOfProductsWithoutAssignment.Purpose 
	|WHERE
	|	&ThisIsCommissionRefund
	|	AND InventoryKinds.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTRecipientSInventory", QueryTexts) Then
		QueryTextTTRecipientSInventory(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	MIN(GoodsTable.LineNumber) AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|
	|	GoodsTable.CommissionAnalytics AS ItemsLocationAttributes,
	|	UNDEFINED AS Terms,
	|	&CompanyRecipient AS Organization,
	|	GoodsTable.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	SUM(GoodsTable.Count) AS Count,
	|	SUM(GoodsTable.QuantityByGBRN) AS QuantityByGBRN,
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.VATActivityType AS VATTaxation,
	|	GoodsTable.DimensionReturnPolicy AS CorItemsLocationAttributes,
	|	GoodsTable.DocumentSalesOfGoodsAndServices AS DocumentSalesOfGoodsAndServices,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic
	|FROM
	|	TTRecipientSInventory AS GoodsTable
	|WHERE
	|	&BusinessOperation 
	|			= VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|
	|GROUP BY
	|	GoodsTable.CommissionAnalytics,
	|	GoodsTable.InventoryOwnerAttribute,
	|	GoodsTable.CCDNumber,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.DimensionReturnPolicy,
	|	GoodsTable.DocumentSalesOfGoodsAndServices,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic
	|ORDER BY
	|	LineNumber
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
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	MAX(TableDocumentRegistry.Contract)                  AS Contract,
	|	TableDocumentRegistry.LineOfBusiness            AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.ExternalDocumentName) AS ExternalDocumentName,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref             AS Ref,
	|		&Period                            AS IBDocumentDate,
	|		&Number                             AS IBDocumentNumber,
	|		&MetadataIdentifier           AS RefType,
	|		&Organization                       AS Organization,
	|		&BusinessOperation             AS BusinessOperation,
	|		&Partner                           AS Partner,
	|		&Counterparty                        AS Counterparty,
	|		&Contract                           AS Contract,
	|		UNDEFINED                       AS LineOfBusiness,
	|		&Warehouse                             AS StorageLocation,
	|		&Department                     AS Department,
	|		&Manager                          AS EmployeeResponsible,
	|		&Author                             AS Author,
	|		CAST(&Comment AS STRING(100)) AS Comment,
	|		&Currency                            AS Currency,
	|		&DocumentAmount                    AS Sum,
	|		UNDEFINED                       AS Status,
	|		&Posted                          AS Posted,
	|		&DeletionMark                   AS DeletionMark,
	|		FALSE                               AS AdditionalRecord,
	|		CAST(&InformationAboutRecipientOrganization AS STRING(100)) AS More,
	|		&Period                            AS SourceDocumentDate,
	|		&ExternalDocumentName    AS ExternalDocumentName,
	|		&DocumentNumber                    AS SourceDocumentNumber
	|	FROM
	|		Document.IntercompanyGoodsReturn AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref   AS Ref,
	|		&Period                  AS IBDocumentDate,
	|		&Number                   AS IBDocumentNumber,
	|		&MetadataIdentifier AS RefType,
	|		&CompanyRecipient   AS Organization,
	|		&BusinessOperation   AS BusinessOperation,
	|		&Partner                 AS Partner,
	|		&Counterparty              AS Counterparty,
	|		&Contract                 AS Contract,
	|		UNDEFINED             AS LineOfBusiness,
	|		&Warehouse                   AS StorageLocation,
	|		&Department           AS Department,
	|		&Manager                AS EmployeeResponsible,
	|		&Author                   AS Author,
	|		CAST(&Comment AS STRING(100)) AS Comment,
	|		&Currency                  AS Currency,
	|		&DocumentAmount          AS Sum,
	|		UNDEFINED             AS Status,
	|		&Posted                AS Posted,
	|		&DeletionMark         AS DeletionMark,
	|		TRUE                   AS AdditionalRecord,
	|		CAST(&OrganizationInformation AS STRING(100)) AS More,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &Period
	|			ELSE &IncomingDocumentDate
	|		END                    AS SourceDocumentDate,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN UNDEFINED
	|			ELSE &ExternalDocumentName
	|		END                    AS ExternalDocumentName,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &DocumentNumber
	|			ELSE &IncomingDocumentNumber
	|		END                    AS SourceDocumentNumber
	|	FROM
	|		Document.IntercompanyGoodsReturn AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	TableDocumentRegistry.LineOfBusiness,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.IntercompanyGoodsReturn";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("DocumentNumber",                    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber",           """""");
	RedefiningParameterCalculation.Insert("OrganizationInformation",           """""");
	RedefiningParameterCalculation.Insert("InformationAboutRecipientOrganization", """""");
	
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
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
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

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AccountingAnalyticsRecipient");
	AdditionalParameters.Add("ConversionRateToManCurrency");
	AdditionalParameters.Add("FactorOfConversionToCurrencyOfRegul");
	AdditionalParameters.Add("FIFORollingEstimateOfRecipient");
	
	If Query <> Undefined Then
		SetParameterOfAccountingAnalyticsRequestRecipient(Query);
		SetRequestParametersCurrencyCoefficients(Query);
		SetFIFORequestParameterRollingScoreOfRecipient(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTSenderSInventory");
	AdditionalTables.Add("TTRecipientSInventory");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTSenderSInventory(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTRecipientSInventory(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(DocumentObject) Export
	
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
	|	TableTypesOfStocks_.DimensionReturnPolicy 			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryTypeAccounting			AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED 								  	AS CorItemsLocationAttributes,
	|	UNDEFINED 								  	AS CorInventoryOwnerAttribute,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.DifferencesInCostOfReturnAndActualCostOfGoods) AS ExpenseItemAssets,
	|	VALUE(Catalog.Partners.OurEnterprise)	AS AssetExpenseAnalytics,
	|	VALUE(ChartOfCharacteristicTypes.IncomeItems.DifferencesInCostOfReturnAndActualCostOfGoods)  AS IncomeItem,
	|	VALUE(Catalog.Partners.OurEnterprise)	AS DimensionOfRevenue,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED 					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager 		AS Manager,
	|	UNDEFINED 					AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 				AS Count,
	|	TableTypesOfStocks_.RowID 		AS RowID,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 																AS Cost,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN 0
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 																AS CostExcludingVAT,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND NOT &MovingAverage
	|			THEN TableTypesOfStocks_.AmountExcludingVATCompl + TableTypesOfStocks_.VATAmountCompl
	|			ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|	END 																AS LocalCost,
	|	CASE
	|		WHEN NOT &CompanyManagementAccounting
	|			THEN 0
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN 0
	|		WHEN TableTypesOfStocks_.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|		 AND NOT &MovingAverage
	|			THEN TableTypesOfStocks_.AmountExcludingVATMan + TableTypesOfStocks_.VATAmountMan
	|			ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END	 															AS CostMan,
	|	0													 				AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	&AccountingAnalyticsRecipient AS AccountingDimensionByPartners,
	|
	// Other fields
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|		THEN VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn) 
	|		ELSE VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn) 
	|	END 										AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID 	AS FinRecordID,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.IntercompanyCommissionReturn) 
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.IntercompanyGoodsReturn) 
	|	END 										AS BusinessTransactionSetting
	|
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentTable
	|	INNER JOIN TTSenderSInventory AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.DisposalAtFixedCost,
		QueryText);
	
	#EndRegion
	
	#Region ExternalReceipt_Product
	
	If Not DocumentObject = Undefined 
		And Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.CompanyRecipient				AS Organization,
	|	TableTypesOfStocks_.DimensionReturnPolicy				AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryTypeAccounting				AS InventoryOwnerAttribute,
	|	DocumentTable.Ref								AS Lot,
	|	&TaxationOfOrganization							AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributes,
	|	TableTypesOfStocks_.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner		AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED					AS SalesOpportunity,
	|	DocumentTable.Department 	AS Department,
	|	DocumentTable.Manager		AS Manager,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count					AS Count,
	|	TableTypesOfStocks_.RowID 			AS RowID,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.Cost_
	|		ELSE TableTypesOfStocks_.AmountIncludingVATMan
	|	END 											AS Cost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|	END 											AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostLocal
	|		ELSE CASE
	|			WHEN &TaxationOfOrganization IN (
	|			  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|				THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|				ELSE TableTypesOfStocks_.AmountExcludingVATCompl
	|			END
	|	END 											AS LocalCost,
	|	TableTypesOfStocks_.VATAmountCompl 				AS VATLocal,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE CASE
	|			WHEN &TaxationOfOrganization IN (
	|			  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|				THEN TableTypesOfStocks_.AmountIncludingVATMan
	|				ELSE TableTypesOfStocks_.AmountExcludingVATMan
	|			END
	|	END 											AS CostMan,
	|	TableTypesOfStocks_.VATAmountMan					AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CDCost
	|		ELSE 0
	|	END 											AS PermanentDifference,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.TDCost
	|		ELSE 0
	|	END 											AS CostTD,
	|	0 												AS CorGrossInitialCostENT,
	|
	// Optional fields
	|	&AccountingAnalyticsRecipient													AS AccountingDimensionByPartners,
	|	
	// Other fields
	|	VALUE(Enum.BusinessTransactions.GoodsReceiptByGoodsReturn) 		AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID		 							AS FinRecordID,
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) 
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.IntercompanyCommissionReturn) 
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.GoodsReceiptByGoodsReturn) 
	|	END 																		AS BusinessTransactionSetting
	|
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentTable
	|	INNER JOIN TTRecipientSInventory AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|	AND TableTypesOfStocks_.CostDefiningMethod <> VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|	AND TableTypesOfStocks_.SenderInventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	EndIf;
	
	#EndRegion

	#Region Sales_Product
	
	If Not DocumentObject = Undefined 
		And Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
	
	QueryText = 
	"SELECT
	// Document description
	|	&Period							 				AS Period,
	|	&Ref											AS Ref,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices			AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod 				AS SourceDocumentPeriod,
	|	UNDEFINED 					 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_							AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.CompanyRecipient			AS Organization,
	|	TableTypesOfStocks_.DimensionReturnPolicy			AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryTypeAccounting			AS InventoryOwnerAttribute,
	|	UNDEFINED									AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.DimensionShipments			AS CorItemsLocationAttributes,
	|	CASE
	|		WHEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting
	|		ELSE TableTypesOfStocks_.InventoryTypeAccounting
	|	END											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingAnalyticsRecipient						AS AccountingDimensionByPartners,
	|	UNDEFINED           							AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED								AS SalesOpportunity,
	|	TableTypesOfStocks_.ImplementationDivision	AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count				AS Count,
	|
	// Optional fields
	|	TableTypesOfStocks_.VATActivityType		AS CorVATActivityTypes,
	|
	// Other fields
	|	TableTypesOfStocks_.RowID		AS RowID,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.BusinessTransactions.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Enum.BusinessTransactions.ReverseOfSaleReturnToAnotherWarehouse)
	|	END										AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID	AS FinRecordID,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Catalog.BusinessTransactionsSettings.ReturnOfGoodsFromCustomerOfPreviousPeriods)
	|		ELSE VALUE(Catalog.BusinessTransactionsSettings.ReverseOfSaleReturnToAnotherWarehouse)
	|	END										AS BusinessTransactionSetting,
	|	CASE
	|		WHEN TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	|		THEN VALUE(Enum.LotRecordTypes.PreviousPeriodReturn)
	|		ELSE VALUE(Enum.LotRecordTypes.ReturnToAnotherWarehouse)
	|	END AS EntryType
	|
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentTable
	|	INNER JOIN TTRecipientSInventory AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|	AND (TableTypesOfStocks_.SalePeriod < &BeginningOfMonthOfPeriod
	//Conditions for returning to another warehouse (BT cancellation and refund of another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|		OR ISNULL(TableTypesOfStocks_.OriginWarehouse, DocumentTable.Warehouse) <> ISNULL(TableTypesOfStocks_.Warehouse, DocumentTable.Warehouse)
	|		OR TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> TableTypesOfStocks_.InventoryTypeAccounting
	|		AND TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR TableTypesOfStocks_.Purpose <> ISNULL(TableTypesOfStocks_.PurposeOfShipment, TableTypesOfStocks_.Purpose))
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
#Region Sales_Goods_Storno
	
	If Not DocumentObject = Undefined 
		And Not DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 			 AS Period,
	|	DocumentTable.Ref 		 AS Ref,
	|	TableTypesOfStocks_.DocumentSalesOfGoodsAndServices AS DocumentSource,
	|	TableTypesOfStocks_.SalePeriod 	  AS SourceDocumentPeriod,
	|	UNDEFINED 					 AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_             AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.CompanyRecipient			AS Organization,
	|	TableTypesOfStocks_.DimensionShipments			AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting
	|		ELSE TableTypesOfStocks_.InventoryTypeAccounting
	|	END 											AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	TableTypesOfStocks_.DimensionShipments   			AS CorItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting
	|		ELSE TableTypesOfStocks_.InventoryTypeAccounting
	|	END 											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingAnalyticsRecipient						AS AccountingDimensionByPartners,
	|	UNDEFINED 									AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED								AS SalesOpportunity,
	|	TableTypesOfStocks_.ImplementationDivision	AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	-TableTypesOfStocks_.Count 			AS Count,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|
	// Optional fields
	|	TableTypesOfStocks_.VATActivityType	AS CorVATActivityTypes,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ReverseOfSale) AS BusinessOperation,
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	TableTypesOfStocks_.BusinessTransactionSetting AS BusinessTransactionSetting,
	|	VALUE(Enum.LotRecordTypes.ReversingEntry) AS EntryType
	|
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentTable
	|	INNER JOIN TTRecipientSInventory AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND NOT DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|	AND TableTypesOfStocks_.SalePeriod >= &BeginningOfMonthOfPeriod
	|	AND TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.FromTransferDocument)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	//Conditions for no return to another warehouse (BT cancellation of a refund to another warehouse). For this BT, a Registered Record will be used that is similar to the return in the previous period
	|	AND ISNULL(TableTypesOfStocks_.OriginWarehouse, DocumentTable.Warehouse) = ISNULL(TableTypesOfStocks_.Warehouse, DocumentTable.Warehouse)
	|	AND (TableTypesOfStocks_.TypeOfShipmentInventoryAccounting = TableTypesOfStocks_.InventoryTypeAccounting
	|	OR TableTypesOfStocks_.TypeOfShipmentInventoryAccounting = VALUE(Catalog.InventoryKinds.EmptyRef))
	|	AND ISNULL(TableTypesOfStocks_.PurposeOfShipment, TableTypesOfStocks_.Purpose) = TableTypesOfStocks_.Purpose
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	EndIf;
	
	#EndRegion
	
#Region Moving_Goods_Commission
	
	If Not DocumentObject = Undefined 
		And DocumentObject.BusinessOperation = Enums.BusinessTransactions.IntercompanyCommissionReturn Then
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.CompanyRecipient			 	AS Organization,
	|	TableTypesOfStocks_.CommissionAnalytics				AS ItemsLocationAttributes,
	|	CASE WHEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|		THEN TableTypesOfStocks_.TypeOfShipmentInventoryAccounting
	|		ELSE TableTypesOfStocks_.InventoryTypeAccounting
	|	END												AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATActivityType 			 	AS VATActivityType,
	|	TableTypesOfStocks_.VATActivityType				AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                        AS CorCompany,
	|	UNDEFINED 									   	AS CorLot,
	|	TableTypesOfStocks_.DimensionReturnPolicy				AS CorItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryTypeAccounting				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED								AS SalesOpportunity,
	|	TableTypesOfStocks_.ImplementationDivision	AS Department,
	|	DocumentTable.Manager					AS Manager,
	|	UNDEFINED 								AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.Cost_
	|		ELSE 0
	|	END	AS Cost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostExcludingVAT_
	|		ELSE 0
	|	END	AS CostExcludingVAT,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CostLocal
	|		ELSE 0
	|	END	AS LocalCost,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.Cost_
	|		ELSE 0
	|	END	AS CostMan,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.CDCost
	|		ELSE 0
	|	END	AS PermanentDifference,
	|	CASE WHEN TableTypesOfStocks_.CostDefiningMethod = VALUE(Enum.WaysToCalculateReturnCost.Manually)
	|		THEN TableTypesOfStocks_.TDCost
	|		ELSE 0
	|	END	AS CostTD,
	|
	// Optional fields
	|	CASE WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END AS AccountingSection,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		WHEN TableTypesOfStocks_.ShopFloorStockroom 
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|			ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.ProductStock)
	|	END AS CorAccountingSection,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn) AS BusinessOperation,
	|	TableTypesOfStocks_.RowID	AS RowID,
	|	TableTypesOfStocks_.FinRecordID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IntercompanyCommissionReturn) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.IntercompanyGoodsReturn AS DocumentTable
	|	INNER JOIN TTRecipientSInventory AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.BusinessOperation = VALUE(Enum.BusinessTransactions.IntercompanyCommissionReturn)
	|	AND TableTypesOfStocks_.InventoryType IN (
	|		VALUE(Enum.InventoryTypes.OwnGoods),
	|		VALUE(Enum.InventoryTypes.ConsignedGoods))
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.Move,
		QueryText);
	
	EndIf;
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
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

	// Refund to the supplier
	PrintCommand = PrintCommands.Add();
	PrintCommand.Id = "ReturnToVendor";
	PrintCommand.Presentation = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
									|ru = 'Возврат поставщику';
									|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
									|it = 'Reso al fornitore';
									|pl = 'Zwrot do dostawcy ';
									|tr = 'Tedarikçiye iade'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Trả lại hàng cho nhà cung cấp';
											|ru = 'Возврат поставщику';
											|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
											|it = 'Reso al fornitore';
											|pl = 'Zwrot do dostawcy ';
											|tr = 'Tedarikçiye iade'");
	
	If Constants.UseInternationalPrintingForms.Get() Then
		// Invoice
		PrintCommand = PrintCommands.Add();
		PrintCommand.Id = "InvoiceInt";
		PrintCommand.PrintManager = "DataProcessor.PrintCommercialInvoices";
		PrintCommand.Presentation = NStr("vi = 'Commercial invoice';
										|ru = 'Commercial invoice';
										|en = 'Commercial invoice'; fa = 'فاکتور تجاری';
										|it = 'Commercial invoice';
										|pl = 'Commercial invoice';
										|tr = 'Commercial invoice'");
		PrintCommand.CheckPostingBeforePrint = True;
		PrintCommand.Order = 39;
	EndIf;
	
	IntercompanyGoodsReturnLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "ReturnToVendor") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(PrintFormsCollection, "ReturnToVendor", NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																											|ru = 'Возврат поставщику';
																											|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
																											|it = 'Reso al fornitore';
																											|pl = 'Zwrot do dostawcy ';
																											|tr = 'Tedarikçiye iade'"), GeneratePrintedFormReturnToSupplier(ObjectsArray, PrintObjects));
	EndIf;
	
	IntercompanyGoodsReturnLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
	PrintFormGeneration.FillInSendingParameters(OutputParameters.SendOptions, ObjectsArray, PrintFormsCollection);
	
EndProcedure

Function GeneratePrintedFormReturnToSupplier(ObjectsArray, PrintObjects)
	
	SetPrivilegedMode(True);
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms();
	NameOfCodeColumn = ColumnOfCodes.ColumnName;
	PresentationOfCodesColumn = ColumnOfCodes.ColumnPresentation;
	OutputCodes = ValueIsFilled(NameOfCodeColumn);
	
	Query = New Query(
	"SELECT
	|	ReturnOfGoods.Ref AS Ref,
	|	ReturnOfGoods.Organization.Prefix AS Prefix,
	|	ReturnOfGoods.Number AS Number,
	|	ReturnOfGoods.Date AS Date,
	|	ReturnOfGoods.Organization AS Organization,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Partner,
	|	ReturnOfGoods.CompanyRecipient AS Recipient,
	|	ReturnOfGoods.Currency AS Currency,
	|	ReturnOfGoods.PriceIncludesVAT AS PriceIncludesVAT,
	|	ReturnOfGoods.BusinessOperation AS BusinessOperation,
	|	CASE
	|		WHEN ReturnOfGoods.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ConsiderVAT,
	|	ReturnOfGoods.Warehouse.CurrentEmployeeInChargeTypes AS VacationProduced,
	|	CASE
	|		WHEN ReturnOfGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTransferToCommission
	|FROM
	|	Document.IntercompanyGoodsReturn AS ReturnOfGoods
	|WHERE
	|	ReturnOfGoods.Ref IN(&DocumentsArray)
	|	AND ReturnOfGoods.Posted
	|	AND (NOT ReturnOfGoods.ARAPAccountingViaSeparateCounterparty)
	|
	|UNION ALL
	|
	|SELECT
	|	ReturnOfGoods.Ref,
	|	ReturnOfGoods.Organization.Prefix,
	|	ReturnOfGoods.Number,
	|	ReturnOfGoods.Date,
	|	ReturnOfGoods.Organization,
	|	ReturnOfGoods.Partner,
	|	ReturnOfGoods.Counterparty,
	|	ReturnOfGoods.Currency,
	|	ReturnOfGoods.PriceIncludesVAT,
	|	ReturnOfGoods.BusinessOperation,
	|	CASE
	|		WHEN ReturnOfGoods.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ReturnOfGoods.Warehouse.CurrentEmployeeInChargeTypes.Description,
	|	CASE
	|		WHEN ReturnOfGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.IntercompanyGoodsReturn AS ReturnOfGoods
	|WHERE
	|	ReturnOfGoods.Ref IN(&DocumentsArray)
	|	AND ReturnOfGoods.Posted
	|	AND ReturnOfGoods.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	ReturnOfGoods.Ref,
	|	ReturnOfGoods.Organization.Prefix,
	|	ReturnOfGoods.Number,
	|	ReturnOfGoods.Date,
	|	ReturnOfGoods.Counterparty,
	|	ReturnOfGoods.Partner,
	|	ReturnOfGoods.CompanyRecipient,
	|	ReturnOfGoods.Currency,
	|	ReturnOfGoods.PriceIncludesVAT,
	|	ReturnOfGoods.BusinessOperation,
	|	CASE
	|		WHEN ReturnOfGoods.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|			THEN TRUE
	|		ELSE FALSE
	|	END,
	|	ReturnOfGoods.Warehouse.CurrentEmployeeInChargeTypes.Description,
	|	CASE
	|		WHEN ReturnOfGoods.BusinessOperation <> VALUE(Enum.BusinessTransactions.IntercompanyGoodsReturn)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|FROM
	|	Document.IntercompanyGoodsReturn AS ReturnOfGoods
	|WHERE
	|	ReturnOfGoods.Ref IN(&DocumentsArray)
	|	AND ReturnOfGoods.Posted
	|	AND ReturnOfGoods.ARAPAccountingViaSeparateCounterparty
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductNameFull_,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Description AS UnitPrice,
	|	NestedQuery.UnitOfMeasure AS UnitOfMeasure,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(&QueryTextPackagingFactor1, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.VATRate AS VATRate,
	|	NestedQuery.Price AS Price,
	|	NestedQuery.Count AS Count,
	|	NestedQuery.Sum AS Sum,
	|	NestedQuery.VATAmount AS VATAmount,
	|	NestedQuery.LineNumber AS LineNumber,
	|	FALSE AS ThisIsReusablePackage
	|FROM
	|	(SELECT
	|		ReturnOfGoods.Ref AS Ref,
	|		ReturnOfGoods.Products AS Products,
	|		CASE
	|			WHEN ReturnOfGoods.Package = VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|				THEN 1
	|			ELSE &QueryTextPackagingFactor2
	|		END AS ZoomRatio,
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|		ReturnOfGoods.Characteristic AS Characteristic,
	|		ReturnOfGoods.Package AS Package,
	|		ReturnOfGoods.VATRate AS VATRate,
	|		ReturnOfGoods.Price AS Price,
	|		ReturnOfGoods.NumberOfPackages AS Count,
	|		ReturnOfGoods.Sum AS Sum,
	|		ReturnOfGoods.VATAmount AS VATAmount,
	|		ReturnOfGoods.LineNumber AS LineNumber
	|	FROM
	|		Document.IntercompanyGoodsReturn.Goods AS ReturnOfGoods
	|	WHERE
	|		ReturnOfGoods.Ref IN(&DocumentsArray)
	|		AND ReturnOfGoods.Ref.Posted) AS NestedQuery
	|
	|ORDER BY
	|	NestedQuery.Ref,
	|	LineNumber
	|TOTALS BY
	|	Ref");
	
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor1",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"NestedQuery.Package",
			"NestedQuery.Products"));
		
	Query.Text = StrReplace(Query.Text,
		"&QueryTextPackagingFactor2",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ReturnOfGoods.Package",
			"ReturnOfGoods.Products"));
			
	Query.Text = StrReplace(Query.Text,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"ReturnOfGoods.Package",
			"ReturnOfGoods.Products"));
	
	Query.SetParameter("DocumentsArray", ObjectsArray);
		
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_IntercompanyGoodsReturn_Invoice";
	
	ResultsArray   = Query.ExecuteBatch(); 
	PrintData        = ResultsArray[0].Select();
	SelectionByDocuments = ResultsArray[1].Select(QueryResultIteration.ByGroups);
	
	FirstDocument = True;
	
	While PrintData.Next() Do
		
		// We will find the products in the selection for the current document
		TheStructureOfTheSearch = New Structure("Ref", PrintData.Ref);
		FollowingIsFound = SelectionByDocuments.FindNext(TheStructureOfTheSearch);
		
		// The layout must be obtained for each document, because the column sizes change dynamically.
		Template = PrintManagement.PrintFormTemplate("Document.IntercompanyGoodsReturn.PF_MXL_ReturnToVendor");
		
		ProductSelection_1 = SelectionByDocuments.Select();
		
		If Not FirstDocument Then
			SpreadsheetDocument.PutHorizontalPageBreak();
		EndIf;
		
		FirstDocument    = False;
		RowNumberStart = SpreadsheetDocument.TableHeight + 1;
		
		// We display the header of the invoice
		
		If Not PrintData.ThisIsTransferToCommission Then
			
			ProductColumnArea = Template.Area("OwnGoods");
			If Not OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.2;
			EndIf;
			
		Else
			
			ProductColumnArea = Template.Area("ProductWithoutAmounts");
			If Not OutputCodes Then
				ProductColumnArea.ColumnWidth = ProductColumnArea.ColumnWidth * 1.125;
			EndIf;
			
		EndIf;
		
		TemplateArea = Template.GetArea("Title");
		
		HeaderDataStructure_1 = New Structure;
		HeaderDataStructure_1.Insert("TitleText", TMCommonUseClientServer.GenerateDocumentTitle(PrintData, NStr("vi = 'Trả lại hàng cho nhà cung cấp';
																												|ru = 'Возврат поставщику';
																												|en = 'Return to vendor'; fa = 'مرجوعی به تأمین‌کننده';
																												|it = 'Reso al fornitore';
																												|pl = 'Zwrot do dostawcy ';
																												|tr = 'Tedarikçiye iade'", Common.DefaultLanguageCode())));
		TemplateArea.Parameters.Fill(HeaderDataStructure_1);
		
		BarcodingOfPrintForms.OutputBarcodeToTabularDocument(SpreadsheetDocument, Template, TemplateArea, PrintData.Ref);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Vendor");
		DataStructureProvider = New Structure;
		SupplierPresentation                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Organization, PrintData.Date), "FullDescr");
		DataStructureProvider.Insert("SupplierPresentation", SupplierPresentation);
		DataStructureProvider.Insert("Vendor", PrintData.Organization);
		TemplateArea.Parameters.Fill(DataStructureProvider);
		SpreadsheetDocument.Put(TemplateArea);
		
		TemplateArea                                   = Template.GetArea("Customer");
		CustomerDataStructure = New Structure;
		RecipientPresentation1                         = PrintFormGeneration.OrganizationDescription(PrintFormGeneration.InformationAboutLegalEntity(PrintData.Recipient, PrintData.Date), "FullDescr");
		CustomerDataStructure.Insert("RecipientPresentation1", RecipientPresentation1);
		CustomerDataStructure.Insert("Recipient", PrintData.Recipient);
		TemplateArea.Parameters.Fill(CustomerDataStructure);
		SpreadsheetDocument.Put(TemplateArea);
		
		// Output the title of the Products table
		
		If Not PrintData.ThisIsTransferToCommission Then
			
			RoomArea     = Template.GetArea("TableHeader|LineNumber");
			AreaCodes      = Template.GetArea("TableHeader|ColumnOfCodes");
			ProductArea      = Template.GetArea("TableHeader|OwnGoods");
			DataArea     = Template.GetArea("TableHeader|Data");
			
		Else
			
			RoomArea     = Template.GetArea("HeaderOfTableWithoutAmounts|LineNumberWithoutSums");
			AreaCodes      = Template.GetArea("HeaderOfTableWithoutAmounts|ColumnOfCodesWithoutSums");
			ProductArea      = Template.GetArea("HeaderOfTableWithoutAmounts|ProductWithoutAmounts");
			DataArea     = Template.GetArea("HeaderOfTableWithoutAmounts|DataWithoutAmounts");
			
		EndIf;
			
		SpreadsheetDocument.Put(RoomArea);
			
		If OutputCodes Then
			DataStructureCodes = New Structure("NameOfCodeColumn", PresentationOfCodesColumn);
			AreaCodes.Parameters.Fill(DataStructureCodes);
			SpreadsheetDocument.Join(AreaCodes);
		EndIf;
			
		SpreadsheetDocument.Join(ProductArea);
		SpreadsheetDocument.Join(DataArea);
			
		If Not PrintData.ThisIsTransferToCommission Then
			
			RoomArea  = Template.GetArea("TableRow|LineNumber");
			AreaCodes   = Template.GetArea("TableRow|ColumnOfCodes");
			ProductArea   = Template.GetArea("TableRow|OwnGoods");
			DataArea  = Template.GetArea("TableRow|Data");
			
		Else
			
			RoomArea  = Template.GetArea("TableRowWithoutSums|LineNumberWithoutSums");
			AreaCodes   = Template.GetArea("TableRowWithoutSums|ColumnOfCodesWithoutSums");
			ProductArea   = Template.GetArea("TableRowWithoutSums|ProductWithoutAmounts");
			DataArea  = Template.GetArea("TableRowWithoutSums|DataWithoutAmounts");
			
		EndIf;
			
		Sum          = 0;
		VATAmount       = 0;
		LineNumber    = 0;
		
		// Output the rows of the Goods table

		While ProductSelection_1.Next() Do
			
			LineNumber = LineNumber + 1;
			
			RoomArea.Parameters.Fill(New Structure("LineNumber", LineNumber));
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				DataStructureCodes = New Structure("SKU", ProductSelection_1[NameOfCodeColumn]);
				AreaCodes.Parameters.Fill(DataStructureCodes);
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			ProductArea.Parameters.Fill(ProductSelection_1);
			AdditionalParametersForGettingNameToPrint = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
			AdditionalParametersForGettingNameToPrint.ReturnContainers = ProductSelection_1.ThisIsReusablePackage;
			AdditionalParametersForGettingNameToPrint.DefaultLanguageCode = Common.DefaultLanguageCode();
			
			OwnGoods = ProductsClientServer.PresentationOfProductsForPrinting(
				ProductSelection_1.ProductNameFull_,
				ProductSelection_1.Characteristic,
				,
				,
				AdditionalParametersForGettingNameToPrint);

			ProductDataStructure = New Structure("OwnGoods", OwnGoods);
			ProductArea.Parameters.Fill(ProductDataStructure);
			SpreadsheetDocument.Join(ProductArea);
			
			DataArea.Parameters.Fill(ProductSelection_1);
			SpreadsheetDocument.Join(DataArea);
			
			If PrintData.BusinessOperation <> Enums.BusinessTransactions.ReturnOfGoodsToConsignor Then
				
				Sum    = Sum    + ProductSelection_1.Sum;
				VATAmount = VATAmount + ProductSelection_1.VATAmount;
				
			EndIf;
				
		EndDo;
		
		// We output the basement
		
		If Not PrintData.ThisIsTransferToCommission Then
			
			RoomArea = Template.GetArea("TableFooter|LineNumber");
			AreaCodes  = Template.GetArea("TableFooter|ColumnOfCodes");
			ProductArea  = Template.GetArea("TableFooter|OwnGoods");
			DataArea = Template.GetArea("TableFooter|Data");
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
				
			TotalDataStructure = New Structure;
			TotalDataStructure.Insert("Total", PrintFormGeneration.SumFormat(Sum));
			DataArea.Parameters.Fill(TotalDataStructure);
			SpreadsheetDocument.Join(DataArea);
			
		EndIf;
			
		// We output the total of the ADS
		
		If PrintData.ConsiderVAT And Not PrintData.ThisIsTransferToCommission Then
			
			RoomArea = Template.GetArea("VATTableBasement|LineNumber");
			AreaCodes  = Template.GetArea("VATTableBasement|ColumnOfCodes");
			ProductArea  = Template.GetArea("VATTableBasement|OwnGoods");
			DataArea = Template.GetArea("VATTableBasement|Data");
			
			SpreadsheetDocument.Put(RoomArea);
			
			If OutputCodes Then
				SpreadsheetDocument.Join(AreaCodes);
			EndIf;
			
			SpreadsheetDocument.Join(ProductArea);
			
			VATDataStructure = New Structure;
			VATDataStructure.Insert("VAT", ?(PrintData.PriceIncludesVAT, 
				NStr("vi = 'Trong đó thuế GTGT:';
					|ru = 'В том числе НДС:';
					|en = 'Including VAT:'; fa = 'Including VAT:';
					|it = 'IVA compresa:';
					|pl = 'W tym VAT';
					|tr = 'KDV dahil:'",Common.DefaultLanguageCode()), 
				NStr("vi = 'Thuế GTGT:';
					|ru = 'Сумма НДС:';
					|en = 'VAT amount:'; fa = 'مبلغ مالیات بر ارزش افزوده:';
					|it = 'Importo IVA:';
					|pl = 'Wartość VAT';
					|tr = 'KDV tutarı:'", Common.DefaultLanguageCode())));
			VATDataStructure.Insert("TotalVAT", PrintFormGeneration.SumFormat(VATAmount));
			DataArea.Parameters.Fill(VATDataStructure);
			SpreadsheetDocument.Join(DataArea);
			
		EndIf;
		
		If Not PrintData.ThisIsTransferToCommission Then
			
			// We output the Amount in words
			
			TemplateArea = Template.GetArea("AmountInWords");
			AmountToBeRegistered = Sum + ?(PrintData.PriceIncludesVAT, 0, VATAmount);
			
			TotalString = NStr("vi = 'Toàn bộ tên gọi %NumberOfTitles%, số tiền %DocumentAmount%';
								|ru = 'Всего наименований %NumberOfTitles%, на сумму %DocumentAmount%';
								|en = 'Total items %NumberOfTitles% in the amount of %DocumentAmount%'; fa = 'Total items %NumberOfTitles% in the amount of %DocumentAmount%';
								|it = 'Totale articoli %NumberOfTitles%, per l''importo di %DocumentAmount%';
								|pl = 'Razem przedmiotów %NumberOfTitles%, w kwocie %DocumentAmount%';
								|tr = 'Toplam tanım %NumberOfTitles%, tutar %DocumentAmount%'", Common.DefaultLanguageCode()) + " ";
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", ProductSelection_1.Count());
			TotalString = StrReplace(TotalString, "%DocumentAmount%", PrintFormGeneration.SumFormat(AmountToBeRegistered, PrintData.Currency));

			DataStructureSummaryRow = New Structure;
			DataStructureSummaryRow.Insert("TotalString", TotalString);
			DataStructureSummaryRow.Insert("AmountInWords", ProcessingOfExchangeRatesTM.GenerateAmountInWords(AmountToBeRegistered, PrintData.Currency));
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		Else
			
			TemplateArea = Template.GetArea("BasementTablesWithoutSums");
			TotalString = NStr("vi = 'Số lượng các dòng là: %NumberOfTitles%';
								|ru = 'Всего наименований %NumberOfTitles%';
								|en = 'Total items %NumberOfTitles%'; fa = 'Total items %NumberOfTitles%';
								|it = 'Totale articoli %NumberOfTitles%';
								|pl = 'Łącznie nazw %NumberOfTitles%';
								|tr = 'Toplam tanım %NumberOfTitles%'", Common.DefaultLanguageCode());
			TotalString = StrReplace(TotalString, "%NumberOfTitles%", ProductSelection_1.Count());
			DataStructureSummaryRow = New Structure("TotalString", TotalString);
			TemplateArea.Parameters.Fill(DataStructureSummaryRow);
			SpreadsheetDocument.Put(TemplateArea);
			
		EndIf;
		
		// Output signatures
		TemplateArea = Template.GetArea("Signatures");
		
		If ValueIsFilled(PrintData.VacationProduced) Then
			DataStructureVacationProduced =
				New Structure("VacationProduced", PersonsTM.IndividualShortName(PrintData.VacationProduced, PrintData.Date));
			TemplateArea.Parameters.Fill(DataStructureVacationProduced);
		EndIf;
		
		SpreadsheetDocument.Put(TemplateArea);
		
		PrintManagement.SetDocumentPrintArea(SpreadsheetDocument, RowNumberStart, PrintObjects, PrintData.Ref);
		
	EndDo;
	
	SpreadsheetDocument.FitToPage = True;

	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;

EndFunction // Form a printable form to return to the supplier()

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
	
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
	If GetFunctionalOption("UsePartnersAndCounterparties") Then 
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
	EndIf;
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Shipper");
	PrintObjectDataStructure.ArrayOfRecipientDetails.Add("GoodsRecipient");
	
EndProcedure

Function GetDataForPrintedInvoiceForm(PrintParameters, ObjectsArray, LanguageCode = Undefined) Export
	
	Return DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode);
	
EndFunction

Function DataForPrintedFormsOfInvoiceForPaymentOfNotification(PrintParameters, ObjectsArray, LanguageCode) Export
	
	TempTablesManager = New TempTablesManager;
	ResponsiblePersonsServer.CreateTemporaryTableOfResponsiblePersonsOfDocuments(ObjectsArray, TempTablesManager);	
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.Text =
	"SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.CompanyRecipient AS Counterparty,
	|	Documents.CompanyRecipient.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.RecipientCompanyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankSWIFTCode AS BankSWIFTCode,
	|	Documents.CompanyBankAccount.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	Documents.CompanyBankAccount.BankAddress AS BankAddress,
	|	Documents.CompanyBankAccount.TransferBankAddress AS TransferBankAddress,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Organization
	|		ELSE Documents.Shipper
	|	END AS Shipper,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.IntercompanyGoodsReturn AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND NOT Documents.ARAPAccountingViaSeparateCounterparty
	|
	|UNION ALL
	|
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CounterpartyBankAccount.Owner, Documents.CompanyRecipient) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	"""" AS Director,
	|	"""" AS JobTitleExecutive,
	|	"""" AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.CompanyRecipient AS Counterparty,
	|	Documents.CompanyRecipient.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CounterpartyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CounterpartyBankAccount.ForeignBank
	|		OR Documents.CounterpartyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.RecipientCompanyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CounterpartyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CounterpartyBankAccount.BankSWIFTCode AS BankSWIFTCode,
	|	Documents.CounterpartyBankAccount.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	Documents.CounterpartyBankAccount.BankAddress AS BankAddress,
	|	Documents.CounterpartyBankAccount.TransferBankAddress AS TransferBankAddress,
	|	Documents.CounterpartyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS ThisIsDigitalRubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CounterpartyBankAccount.AccountNumber
	|	END AS BankAccountNumber,	
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CounterpartyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CounterpartyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CounterpartyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CounterpartyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Counterparty
	|		ELSE Documents.Shipper
	|	END,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.IntercompanyGoodsReturn AS Documents
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND Documents.ARAPAccountingViaSeparateCounterparty
	|	AND Documents.CompanyRecipient <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	Documents.Ref AS Ref,
	|	Documents.Number AS Number,
	|	Documents.Date AS Date,
	|	UNDEFINED AS DocumentBasis,
	|	ISNULL(Documents.CompanyBankAccount.Owner, Documents.Organization) AS Organization,
	|	Documents.Organization AS CompanyVendor,
	|	TableResponsiblePersons.DirectorDescription AS Director,
	|	TableResponsiblePersons.DirectorJobTitle AS JobTitleExecutive,
	|	TableResponsiblePersons.ChiefAccountantDescription AS ChiefAccountant,
	|	CASE
	|		WHEN Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|				OR Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII)
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ConsiderVAT,
	|	Documents.VATTaxation = VALUE(Enum.VATTaxationTypes.SubjectToVATAtCustomer) AS OperationIsSubjectToBuyerSPersonalIncomeTax,
	|	Documents.Counterparty AS Counterparty,
	|	Documents.Counterparty.LegalEntityIndividual AS CounterpartyLegEntInd,
	|	Documents.CompanyBankAccount AS BankAccount,
	|	
	|	CASE WHEN Documents.CompanyBankAccount.ForeignBank
	|		OR Documents.CompanyBankAccount.CashCurrency <> Documents.Organization.LocalAccountingCurrency
	|		OR Documents.CounterpartyBankAccount.ForeignBank THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS PaymentAbroad,
	|	Documents.CompanyBankAccount.CashCurrency AS CashCurrency,
	|	Documents.CompanyBankAccount.BankSWIFTCode AS BankSWIFTCode,
	|	Documents.CompanyBankAccount.BankSWIFTCodeForPayments AS BankSWIFTCodeForPayments,
	|	Documents.CompanyBankAccount.BankAddress AS BankAddress,
	|	Documents.CompanyBankAccount.TransferBankAddress AS TransferBankAddress,
	|	Documents.CompanyBankAccount.BankAccountForPayments AS BankAccountForPayments,
	|	ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE) AS DigitalRoubleAccount,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN Documents.CompanyBankAccount.DigitalRoubleAccountID
	|		ELSE Documents.CompanyBankAccount.AccountNumber
	|	END AS BankAccountNumber,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankBIC
	|		ELSE BankClassifier.Code
	|	END AS BICBank,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankDescription
	|		ELSE BankClassifier.Description
	|	END AS BankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankNameInt
	|		ELSE BankClassifier.InternationalDescription
	|	END AS BankNameInt,
	|	CASE
	|		WHEN ISNULL(Documents.CompanyBankAccount.DigitalRoubleAccount, FALSE)
	|			THEN """"
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCorrAccount
	|		ELSE BankClassifier.CorrAccount
	|	END AS BankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCity
	|		ELSE BankClassifier.City
	|	END AS BankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN Documents.CompanyBankAccount.BankCityForPaymentsInt
	|		ELSE BankClassifier.CityInternationalFormat
	|	END AS BankCityInt,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankBIC
	|		ELSE CorrespondentBankClassifier.Code
	|	END AS TransferBankBIC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankDescription
	|		ELSE CorrespondentBankClassifier.Description
	|	END AS TransferBankDescription,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCorrAccount
	|		ELSE CorrespondentBankClassifier.CorrAccount
	|	END AS TransferBankCorrAccount,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN Documents.CompanyBankAccount.TransferBankCity
	|		ELSE CorrespondentBankClassifier.City
	|	END AS TransferBankCity,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.ManualBankDetailsChange
	|			THEN """"
	|		ELSE ISNULL(BankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCC,
	|	CASE
	|		WHEN Documents.CompanyBankAccount.TransferBankDetailsManualEdit
	|			THEN """"
	|		ELSE ISNULL(CorrespondentBankClassifier.CashSettlementCenterBIC.Description, """")
	|	END AS NameOfBankSRCCForSettlements,
	|	Documents.CompanyBankAccount.CorrespondentText AS CorrespondentTextBankAccount,
	|	Documents.PriceIncludesVAT AS PriceIncludesVAT,
	|	Documents.Currency AS Currency,
	|	Documents.Manager.Individual AS Manager,
	|	Documents.DocumentAmount AS AmountToReturn,
	|	FALSE AS PartialPayment,
	|	"""" AS PaymentPurposes,
	|	100 AS PayPercentage,
	|	"""" AS AdditionalInformation,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	CASE
	|		WHEN Documents.Shipper = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.Organization
	|		ELSE Documents.Shipper
	|	END AS Shipper,
	|	CASE
	|		WHEN Documents.GoodsRecipient = VALUE(Catalog.Counterparties.EmptyRef)
	|			THEN Documents.CompanyRecipient
	|		ELSE Documents.GoodsRecipient
	|	END AS GoodsRecipient,
	|	Documents.PaymentID AS PaymentID,
	|	FALSE AS InvoiceToBeRefunded
	|FROM
	|	Document.IntercompanyGoodsReturn AS Documents
	|		LEFT JOIN TableResponsiblePersons AS TableResponsiblePersons
	|		ON Documents.Ref = TableResponsiblePersons.Ref
	|		LEFT JOIN Catalog.BankClassifier AS BankClassifier
	|		ON Documents.CompanyBankAccount.Bank = BankClassifier.Ref
	|		LEFT JOIN Catalog.BankClassifier AS CorrespondentBankClassifier
	|		ON Documents.CompanyBankAccount.TransferBank = CorrespondentBankClassifier.Ref
	|		LEFT JOIN Constants
	|		ON TRUE
	|WHERE
	|	Documents.Ref IN(&ObjectsArray)
	|	AND Documents.ARAPAccountingViaSeparateCounterparty
	|	AND Documents.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UNDEFINED AS Ref,
	|	0 AS LineNumber,
	|	UNDEFINED AS PaymentDate,
	|	0 AS PaymentPercentage,
	|	0 AS PaymentAmount,
	|	FALSE AS ThisIsDepositForPackage
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Ref AS Ref,
	|	Goods.LineNumber										AS LineNumber,
	|	Goods.Products										AS Products,
	|	Goods.Products.Code									AS Code,
	|	Goods.Products.SKU								AS SKU,
	|	Goods.Products.DescriptionFull					AS DescriptionFull,
	|	&QueryTextUnitOfMeasureDescription				AS UnitOfMeasure,
	|	Goods.NumberOfPackages                                AS Count,
	|	Goods.Price AS Price,
	|	Goods.Sum                                             AS Sum,
	|	Goods.VATRate                                         AS VATRate,
	|	Goods.VATAmount                                          AS VATAmount,
	|	UNDEFINED                                             AS TypeOfContractorSPrice,
	|	ISNULL(Goods.Characteristic.DescriptionFull, """") AS Characteristic,
	|	CASE WHEN ISNULL(&QueryTextPackagingFactor, 1) = 1 THEN
	|		UNDEFINED
	|	ELSE
	|		Goods.Package.Description
	|	END AS Package,
	|	0 AS DiscountAmount,
	|	Goods.Sum AS AmountWithoutADiscount,
	|	FALSE AS ThisIsReusablePackage
	|FROM
	|	Document.IntercompanyGoodsReturn.Goods AS Goods
	|WHERE
	|	Goods.Ref IN(&ObjectsArray)
	|ORDER BY
	|	Goods.LineNumber
	|";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	
	If ValueIsFilled(LanguageCode)
		And Not LanguageCode = Common.DefaultLanguageCode() Then
		
		PackageNameUnitsOfMeasurement = "InternationalAbbreviation";
		
	Else
		
		PackageNameUnitsOfMeasurement = "Description";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextUnitOfMeasureDescription",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			PackageNameUnitsOfMeasurement,
			"Goods.Package",
			"Goods.Products"));
		
	Query.SetParameter("ObjectsArray", ObjectsArray);

	RequestResultsPackage = Query.ExecuteBatch();
	
	DataStructureForPrinting = New Structure;
	DataStructureForPrinting.Insert("HeaderResults", RequestResultsPackage[0]);
	DataStructureForPrinting.Insert("ResultsByPaymentStages", RequestResultsPackage[1]);
	DataStructureForPrinting.Insert("ResultForTabularPart", RequestResultsPackage[RequestResultsPackage.Count() - 1]);
	
	Return DataStructureForPrinting;
	
EndFunction

#EndRegion

#Region InitializationAndFilling

// Filling in the structure for the transfer of goods, the" quality " of the link to the transfer IS not controlled.
//
// Parameters:
//	Object - Structure - what to fill in, the composition is expected to be equivalent to the structure of the document returningtowards between Organizations
//	SourceRef - DocumentRef.CustomerInvoiceIntercompany
//
Procedure InstructionsForTransferOfGoods(Object, SourceRef) Export
	
	Query = New Query(
		"SELECT
		|	PTO.Organization AS Organization,
		|	PTO.CompanyRecipient AS CompanyRecipient,
		|	PTO.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
		|	PTO.Partner AS Partner,
		|	PTO.Counterparty AS Counterparty
		|FROM
		|	Document.CustomerInvoiceIntercompany AS PTO
		|WHERE
		|	PTO.Ref = &Ref");
	Query.SetParameter("Ref",SourceRef);
	Attributes = Query.Execute().Unload()[0];
	
	If Not ValueIsFilled(Object.Organization) Then
		Object.Organization = Attributes.CompanyRecipient;
	EndIf;
	If Not ValueIsFilled(Object.CompanyRecipient) Then
		Object.CompanyRecipient = Attributes.Organization;
	EndIf;
	FillPropertyValues(Object,Attributes,"ARAPAccountingViaSeparateCounterparty,Partner,Counterparty");
	
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

#EndRegion

#EndIf
