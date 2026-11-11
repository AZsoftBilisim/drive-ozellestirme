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
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("OperationalAccountingOfGoodsOfOrganizations");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("ImportAccounting");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CCDImportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
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
	
	If TypeOf(Document) = Type("DocumentObject.CCDImport") Then
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
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers);
		QueryTextTableCompanyGoods(Query, QueryTexts, Registers);
		QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers);
		QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableVATInvoiced(Query, QueryTexts, Registers);
		QueryTextTableLotsVATForAllocation(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		CCDImportLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region NonOperationalInterrogation

// We form a request to receive excise tax amounts for the document.
//
// Parameters:
//	DocumentRef - DocumentRef.CCDImport - link to the document.
//
// Returns:
//	QueryResult - data on excise tax amounts.
//
Function GetExciseTaxData(DocumentRef) Export
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.ARAPCurrency    AS ARAPCurrency,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	BusinessTransactionsSettings.Ref   AS BusinessTransactionSetting
	|FROM
	|	Document.CCDImport AS DocumentData
	|
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.RegistrationOption = BusinessTransactionsSettings.BusinessOperation
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
	
	QueryText =
	"SELECT
	|	CategoryTable.Products AS Products,
	|	CategoryTable.ConversionFactor_ AS ConversionFactor_,
	|	CategoryTable.ExcisableGoodsCategory AS ExcisableGoodsCategory
	|INTO TTCategoriesOfExcisableItems
	|FROM
	|	InformationRegister.ExcisableGoodsCategories.SliceLast(
	|			&Period,
	|			Country = &RegistrationCountry
	|				AND Products IN
	|					(SELECT DISTINCT
	|						T.Products AS Products
	|					FROM
	|						Document.CCDImport.Goods AS T
	|					WHERE
	|						T.Ref = &Ref)) AS CategoryTable
	|WHERE
	|	CategoryTable.ExcisableGoods
	|
	|INDEX BY
	|	Products
	|;
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS ExcisePaymentBusinessUnit,
	|	DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	DocumentGoods.Products AS Products,
	|	ExcisableGoodsCategories.ExcisableGoodsCategory AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.Import) AS KindOfTransactionWithExcisableGoods,
	|	DocumentGoods.Count AS Count,
	|	CAST(DocumentGoods.Count * ExcisableGoodsCategories.ConversionFactor_ AS NUMBER(15, 3)) AS QuantityInExcisableCategoryUOM,
	|	CAST(&FactorOfConversionToCurrencyOfRegul * DocumentGoods.ExciseTaxAmount AS NUMBER(31, 2)) AS ExciseAmountInCurrencyLocal,
	|	CAST(&ConversionRateToManCurrency * DocumentGoods.ExciseTaxAmount AS NUMBER(31, 2)) AS ExciseAmountInCurrencyMgmt,
	|	DocumentGoods.RowID AS FinRecordID,
	|	&SettingUpBusinessOfOperation_AccrualOfExciseTaxes AS BusinessTransactionSetting
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|		INNER JOIN TTCategoriesOfExcisableItems AS ExcisableGoodsCategories
	|		ON DocumentGoods.Products = ExcisableGoodsCategories.Products
	|WHERE
	|	DocumentGoods.Ref = &Ref
	|	AND ExcisableGoodsCategories.ExcisableGoodsCategory <> VALUE(Catalog.ExcisableGoodsCategories.EmptyRef)
	|	AND (DocumentGoods.ExciseTaxAmount <> 0
	|		OR CAST(DocumentGoods.Count * ExcisableGoodsCategories.ConversionFactor_ AS NUMBER(15, 3)) <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS ExcisePaymentBusinessUnit,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ExcisableGoodsCategories.EmptyRef) AS ExcisableGoodsCategory,
	|	VALUE(Enum.KindsOfTransactionsWithExcisableGoods.EmptyRef) AS KindOfTransactionWithExcisableGoods,
	|	0 AS Count,
	|	0 AS QuantityInExcisableCategoryUOM,
	|	SUM(-DocumentGoods.ExciseTaxAmount) AS ExciseAmountInCurrencyLocal,
	|	SUM(-(CAST(&ConversionRateToManCurrency * DocumentGoods.ExciseTaxAmount AS NUMBER(31, 2)))) AS ExciseAmountInCurrencyMgmt,
	|	DocumentData.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|		INNER JOIN Document.CCDImport AS DocumentData
	|		ON DocumentGoods.Ref = DocumentData.Ref
	|WHERE
	|	DocumentGoods.Ref = &Ref
	|	AND DocumentGoods.ExciseTaxAmount <> 0
	|
	|GROUP BY
	|	DocumentData.ARAPObject.UUID
	|";
	
	Query.Text = QueryText;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
				Query.Parameters.Currency,
				Query.Parameters.ARAPCurrency,
				Query.Parameters.Period,
				Query.Parameters.Organization);
	
	RegistrationCountry = SettingsValueClientServerCached.CountryOfOrganizationRegistration(Attributes.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",                   Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",                  Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("RegistrationCountry",                                RegistrationCountry);
	Query.SetParameter("SettingUpBusinessOfOperation_AccrualOfExciseTaxes", Catalogs.BusinessTransactionsSettings.ExciseAccrual);
	
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
	
	CCDImportLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "Customs Declaration for import".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CCDImport) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CCDImport.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CCDImport);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseImports";
	

		Return CreateBasedOnCommand;
	EndIf;
	
	CCDImportLocalization.AddGenerateCommand(GenerationCommands);
	
	Return Undefined;
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	CCDImportLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	CCDImportLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	AllAttributes - Array - Array of all names of banking details that depend on the business operation
//	TransactionDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, AllAttributes, TransactionDetails) Export
	AllAttributes = New Array;
	TransactionDetails = New Array;
	
	AllAttributes.Add("Terms");
	AllAttributes.Add("Contract");
	If BusinessOperation = Enums.BusinessTransactions.RegisterCCDThroughBroker Then
		TransactionDetails.Add("Terms");
		TransactionDetails.Add("Contract");
	EndIf;
EndProcedure

// Gets the details of the document
//
// Parameters:
//  DocumentRef	 - DocumentRef.CCDImport - link to the document.
//
// Returns:
//  Structure - The structure of the details.
//
Function DocumentAttributes(DocumentRef) Export
	
	Attributes = New Structure;
	Attributes.Insert("Date", '00010101');
	Attributes.Insert("BusinessOperation", Enums.BusinessTransactions.RegisterCCDThroughBroker);
	Attributes.Insert("Organization", Catalogs.Companies.EmptyRef());
	Attributes.Insert("Partner", Catalogs.Partners.EmptyRef());
	Attributes.Insert("Counterparty", Catalogs.Counterparties.EmptyRef());
	Attributes.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	Attributes.Insert("ARAPObjectSettings", Enums.ARAPObjectSettings.EmptyRef());
	Attributes.Insert("ByOrder", False);
	Attributes.Insert("ARAPCurrency", Catalogs.Currencies.EmptyRef());
	Attributes.Insert("DocumentAmount", 0);
	Attributes.Insert("AmountARAP", 0);
	Attributes.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	
	Query = New Query("
	|SELECT
	|	Data.Date AS Date,
	|	Data.RegistrationOption AS BusinessOperation,
	|	Data.Organization AS Organization,
	|	Data.Partner AS Partner,
	|	Data.Counterparty AS Counterparty,
	|	Data.Contract AS Contract,
	|	Data.ARAPObjectSettings AS ARAPObjectSettings,
	|	FALSE AS ByOrder,
	|	Data.ARAPCurrency AS ARAPCurrency,
	|	Data.DocumentAmount AS DocumentAmount,
	|	CASE WHEN Data.Posted THEN
	|		Data.AmountARAP
	|	ELSE
	|		0
	|	END AS AmountARAP,
	|	Data.LineOfBusiness AS LineOfBusiness
	|FROM
	|	Document.CCDImport AS Data
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

// Returns parameters for specifying series for products specified in the document
//
// Parameters:
//  Object - Structure - the structure of the values of the details object required to populate the parameters specify the series.
//
// Returns:
//  Structure - See ProductsClientServer.SeriesSpecificationParameters
//
Function SeriesSpecificationParameters(Object) Export
	
	SeriesSpecificationParameters = ProductsClientServer.SeriesSpecificationParameters();
	
	SeriesSpecificationParameters.FullObjectName = "Document.CCDImport";
	
	SeriesSpecificationParameters.TSSeriesName = "Goods";
	SeriesSpecificationParameters.UseCostAccountingByBatches = GetFunctionalOption("UseCostAccountingByBatchesWarehouse", New Structure());
	SeriesSpecificationParameters.UseItemsBatch  = GetFunctionalOption("UseItemsBatchWarehouse", New Structure());
	
	SeriesSpecificationParameters.WarehouseTransactions.Add(Enums.WarehouseTransactions.EmptyRef());
	SeriesSpecificationParameters.LinkFields.Add("Warehouse");
	
	SeriesSpecificationParameters.ThisIsAnInvoice = True;
	
	SeriesSpecificationParameters.SeriesOnlyForCostPrice = True;
	SeriesSpecificationParameters.Date = Object.Date;
	
	OperationsGoodsInTransit = New Array();
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.PurchaseFromVendorGoodsInTransit);
	OperationsGoodsInTransit.Add(Enums.BusinessTransactions.ImportGoodsInTransit);
	
	SeriesSpecificationParameters.QueryOptions.Insert("BusinessTransactionsGoodsInTransit", OperationsGoodsInTransit);
	
	SeriesSpecificationParameters.AdditionalFieldNames.Add("BusinessOperation");
	
	Return SeriesSpecificationParameters;
	
EndFunction

// Names of the details that the parameters for specifying the series depend on
//
//	Returns:
//		String - the names of the details, separated by commas.
//
Function NamesOfDetailsForFillingInParametersForSpecifyingSeries() Export
	AttributesNames = "Date";
	
	Return AttributesNames;
EndFunction

// Returns the request text for calculating the statuses for specifying series
//	Parameters:
//		SeriesSpecificationParameters - See ProductsClientServer.SeriesSpecificationParameters
//	Returns:
//		String - query text.
//
Function TextOfRequestToFillInStatusesForSpecifyingSeries(SeriesSpecificationParameters) Export
	
	QueryText = 
	"SELECT
	|	Goods.Products,
	|	Goods.Characteristic,
	|	Goods.Warehouse,
	|	Goods.Series,
	|	Goods.Count,
	|	Goods.BatchesIndicationStatus,
	|	Goods.BusinessOperation,
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
	|		ON (BatchAccountingPolicies.Warehouse = Goods.Warehouse)
	|			AND (CAST(Goods.Products AS Catalog.Products).ProductKind = BatchAccountingPolicies.Ref)
	|WHERE
	|	NOT Goods.BusinessOperation IN (&BusinessTransactionsGoodsInTransit)
	|
	|UNION ALL
	|
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.BatchesIndicationStatus AS OldStatusOfSpecifyingSeries,
	|	CASE
	|		WHEN ProductKind.BatchAccountingPolicy IS NULL
	|			THEN 0
	|		ELSE CASE
	|				WHEN ProductKind.BatchAccountingPolicy.UseCostAccountingByBatches
	|					THEN
	|						CASE
	|							WHEN ProductKind.BatchAccountingPolicy.BatchesAccountingOfGoodsInTransitFromVendor
	|								THEN
	|									CASE
	|										WHEN Goods.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|											THEN 18
	|										ELSE 17
	|									END
	|								ELSE 0
	|						END
	|					ELSE 0
	|			END
	|	END AS BatchesIndicationStatus
	|FROM
	|	Goods AS Goods
	|	INNER JOIN Catalog.ItemKinds AS ProductKind
	|	ON ProductKind.Ref = CAST(Goods.Products AS Catalog.Products).ProductKind
	|WHERE
	|	Goods.BusinessOperation IN (&BusinessTransactionsGoodsInTransit)
	|
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

// Returns a table of used document statuses depending on functional options and other parameters.
//
// Returns:
//  ValueTable - See TMCommonUse.TableOfStatusesToChangeFromList
//
Function DocumentStatusesThatCanBeChangedFromList() Export
	
	Table = TMCommonUse.TableOfStatusesToChangeFromList();
		
	Return Table;
	
EndFunction

//Returns the number of invoices to be processed.
//
// Parameters:
//	Parameters - Structure - Properties:
//	* CompanyArray - Array - Array of organizations.
//	* EndOfPeriod - Date - upper limit on the date of the purchase document.
//	* NoPeriodLimit - Boolean - do not limit the date of the purchase document
//
// Returns:
//	Number - the number of invoices to be processed.
//
Function ThereAreInvoicesForRegistration(Parameters) Export
		
	Query = New Query;
	QueryText = 
	"SELECT ALLOWED
	|	COUNT(DISTINCT OnDate.DocumentInflow) AS NumberOfDocumentsForRegistration
	|FROM
	|	AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(&EndDate, ImportDocumentType = &ImportDocumentType) AS OnDate
	|		LEFT JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments.Balance(, ) AS ForNow
	|		ON OnDate.ItemsLocationAttributes = ForNow.ItemsLocationAttributes
	|			AND OnDate.Vendor = ForNow.Vendor
	|			AND OnDate.Organization = ForNow.Organization
	|			AND OnDate.InventoryOwnerAttribute = ForNow.InventoryOwnerAttribute
	|			AND OnDate.DocumentInflow = ForNow.DocumentInflow
	|			AND OnDate.ImportDocumentType = ForNow.ImportDocumentType
	|WHERE
	|	ForNow.CountBalance > 0
	|	AND &FilterCriterion";
	
	If ValueIsFilled(Parameters.CompanyArray) Then
		FilterCriterion = "OnDate.Organization IN (&CompanyArray)";
		QueryText = StrReplace(QueryText,"&FilterCriterion", FilterCriterion);
		Query.SetParameter("CompanyArray", Parameters.CompanyArray);
	Else
		QueryText = StrReplace(QueryText,"AND &FilterCriterion", "");
	EndIf;
	
	If Parameters.Property("NoPeriodLimit") Then
		Query.SetParameter("EndDate", CurrentSessionDate());
	Else
		Query.SetParameter("EndDate", Parameters.EndOfPeriod);
	EndIf;

	Query.SetParameter("ImportDocumentType", Common.MetadataObjectID("Document.CCDImport"));
	
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Not Selection.NumberOfDocumentsForRegistration = NULL Then
		Return Selection.NumberOfDocumentsForRegistration;
	Else
		Return 0;
	EndIf;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CCDImportLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return CCDImportLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	Parameters - Structure - A structure whose properties contain values 
//            that affect the availability of the Operation: customs Collection, customs Penalty, and processing of a Checkfill.
// 
// Returns:
// 	Array - See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(Parameters) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItemFee
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItemFee";
	
	If Parameters.Property("CustomsFee") And 
		 Parameters.CustomsFee = 0 And 
		 Parameters.Property("FillCheckProcessing") And 
		 Parameters.FillCheckProcessing Then
		
		ChoiceParameters.AvailabilityByOperation = False;
		
	EndIf;
	
	ChoiceParameters.ChoosingExpenseItem = True;	
	
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionFees";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemFee");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionFees");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	#Region ExpenseItemPenalty
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenseItemPenalty";
	
	If Parameters.Property("CustomsPenalty") And 
		 Parameters.CustomsPenalty = 0 And 
		 Parameters.Property("FillCheckProcessing") And 
		 Parameters.FillCheckProcessing Then
		 
		ChoiceParameters.AvailabilityByOperation = False;
		 
	EndIf;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionPenalties";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemPenalty");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionPenalties");
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	Return ArrayOfSelectionParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	
	ParametersStructure.ThisIsSalePurchase                    = True;
	ParametersStructure.PaymentType_                          = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	ParametersStructure.DocumentAmountForm                  = "Form.DocumentAmount";
	
	ParametersStructure.CourseNumerator                       = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                     = "Object.CourseDenominator";
	ParametersStructure.PaymentDate                         = "Object.PaymentDate";
	ParametersStructure.PaymentStepsText                  = "Form.PaymentStepsText";
	
	ParametersStructure.PathToTSDataPaymentDecryption     = "Object.ARAPDetails";
	ParametersStructure.CashAccount                               = "";
	ParametersStructure.Manager                            = "Object.Manager";
	ParametersStructure.VATTaxation                  = Enums.VATTaxationTypes.EmptyRef();
	
	ParametersStructure.FormItems.LabelCurrencies         = "CurrencyDecoration";
	ParametersStructure.FormItems.InscriptionStages          = "DecorationPaymentSteps";
	ParametersStructure.FormItems.PaymentSettlement           = "CreditPaymentForm";
	ParametersStructure.FormItems.AmountOfTSSettlements = "";
	ParametersStructure.FormItems.FinancialAccountingGroup   = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness  = "LineOfBusiness";
	ParametersStructure.CurrencyAndExchangeRateDocumentViewOnly  = True;
	
	ParametersStructure.ARAPObject                      = "Object.ARAPObject";
	
	Return ParametersStructure;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
// 
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CounterpartyBankAccount", Parameters);
	
EndProcedure

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
	|	AND ValueAllowed(Department)
	|	AND ( ValueAllowed(Partner)
	|	OR ValueAllowed(Vendor)
	|	) ";

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

#EndRegion

#Region Private

Function DocumentAmount(Object) Export
	
	DocumentAmount = Object.CustomsFee + Object.CustomsPenalty + Object.Goods.Total("DutyAmount")
		+ Object.Goods.Total("VATAmount") + Object.Goods.Total("ExciseTaxAmount");
	
	Return DocumentAmount;
	
EndFunction

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;
	
	Return DataSources; 

EndFunction

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul")
		And Query.Parameters.Property("ConversionRateToSettlementCurrency") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
				Query.Parameters.Currency,
				Query.Parameters.ARAPCurrency,
				Query.Parameters.Period,
				Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",            Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",           Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("ConversionRateToSettlementCurrency", Coefficients.ConversionRateToSettlementCurrency);
	
	LocalAccountingCurrency =
		SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Query.Parameters.Organization);
	
	If Query.Parameters.Currency = LocalAccountingCurrency Then
		Query.SetParameter("ConversionRatioFromLocalToMan", Coefficients.ConversionRateToManCurrency);
	Else
		ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
		RatePeriod = Query.Parameters.Period;
		
		ConversionRatioFromLocalToMan = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			LocalAccountingCurrency, ManagementAccountingCurrency, RatePeriod, LocalAccountingCurrency);
		
		Query.SetParameter("ConversionRatioFromLocalToMan", ConversionRatioFromLocalToMan);
	EndIf;
	
EndProcedure

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT 
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeclarationNo AS DeclarationNo,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.ARAPCurrency AS ARAPCurrency,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.ARAPObject AS ARAPObject,
	|	CASE WHEN DocumentData.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms) THEN
	|		TRUE
	|	ELSE
	|		FALSE
	|	END AS ReleasedFromCustoms,
	|	DocumentData.Department AS Department,
	|	ISNULL(DocumentData.Department.OptionOfAssignedAccountingOfGoods, VALUE(Enum.OptionsOfAssignedAccountingOfGoods.EmptyRef)) AS OptionOfAssignedAccountingOfGoods,
	|	DocumentData.RegistrationOption AS BusinessOperation,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Terms AS Terms,
	|	DocumentData.VendorSCounterparty AS VendorSCounterparty,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	UNDEFINED AS SalesOpportunity,
	|	DocumentData.Status                 AS Status,
	|	DocumentData.Comment            AS Comment,
	|	DocumentData.DocumentAmount         AS DocumentAmount,
	|	DocumentData.DeletionMark        AS DeletionMark,
	|	DocumentData.Posted               AS Posted,
	|	DocumentData.PaymentMethod            AS PaymentMethod,
	|	DocumentData.PaymentDate            AS PaymentDate,
	|	DocumentData.ManualAdjustmentOfTaxInvoiceRegister AS ManualAdjustmentOfTaxInvoiceRegister,
	|	DocumentData.Author AS Author,
	|	BusinessTransactionsSettings.Ref  AS BusinessTransactionSetting,
	|	UNDEFINED AS AdjustmentPeriod_
	|	
	|FROM
	|	Document.CCDImport AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.RegistrationOption = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("MetadataIdentifier",        Common.MetadataObjectID("Document.CCDImport"));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.SetParameter("ManualAdjustmentOfTaxInvoiceRegister",   Attributes.ManualAdjustmentOfTaxInvoiceRegister);
	Query.SetParameter("SettingUpBusinessOfOperation_AccrualOfExciseTaxes", Catalogs.BusinessTransactionsSettings.ExciseAccrual);
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	Query.SetParameter("TaxationOfOrganization",     AccountingParametersForOrganization.BasicTaxationVATSales);
	
	DateOfDeclaration = Catalogs.CCDNumbers.DateOfAcceptanceOfGoodsDeclaration(Attributes.DeclarationNo);
	Query.SetParameter("DateOfDeclaration", ?(ValueIsFilled(DateOfDeclaration), DateOfDeclaration, Attributes.Period));
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
		Enums.BusinessTransactions.PurchaseByImport);
	Query.SetParameter("BusinessTransactionsImportPurchase", BusinessTransactionsImportPurchase);
	
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" Sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	AccountingForTraceableGoodsLocalization.SetParametersForUsingTrackingOfTraceableGoods(Query);
	
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
	|	Keys.StorageLocation		   AS Warehouse,
	|	Keys.ProductCostElement    AS ProductCostElement
	|FROM
	|	Document.CCDImport.Goods AS Goods
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Keys.Products                  = Dimension.Products
	|		AND Keys.Characteristic             = Dimension.Characteristic
	|		AND Keys.Series                      = Dimension.Series
	|		AND Keys.StorageLocation			   = Dimension.StorageLocation
	|		AND &EmptyAssignment                = Dimension.Purpose
	|		AND Keys.ProductCostElement          = Dimension.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Dimension.Products IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|	AND &Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Keys.Products         AS Products,
	|	Keys.Characteristic       AS Characteristic,
	|	Keys.Purpose           AS Purpose,
	|	Keys.Series                AS Series,
	|	Goods.Warehouse               AS Warehouse,
	|	Keys.ProductCostElement    AS ProductCostElement
	|FROM
	|	Document.CCDImport.Goods AS Goods
	|
	|	LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Keys
	|	ON Goods.ItemsLocationAttributes = Keys.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS DimensionByWarehouses
	|	ON DimensionByWarehouses.Products = Keys.Products
	|		AND DimensionByWarehouses.Characteristic = Keys.Characteristic
	|		AND DimensionByWarehouses.Series = Keys.Series
	|		AND DimensionByWarehouses.Purpose = Keys.Purpose
	|		AND DimensionByWarehouses.ProductCostElement = Keys.ProductCostElement
	|		AND DimensionByWarehouses.StorageLocation = Goods.Warehouse
	|WHERE
	|	Goods.Ref = &Ref
	|	AND DimensionByWarehouses.Products IS NULL
	|	AND &Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
	|");
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	QueryAnalyst.SetParameter("Status", Query.Parameters.Status);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "TTInitialOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ExpenseItemFee AS ExpenseItem,
	|	DocumentData.ExpensesDimensionFees AS DimensionOfExpenses,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	DocumentData.RegistrationOption AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	DocumentData.RowIDFee AS RowID,
	|	DocumentData.ARAPObject.UUID AS FinRecordID,
	|
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.CCDImport AS DocumentData
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentData.Ref = Amounts.Ref
	|		AND DocumentData.RowIDFee = Amounts.RowID
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsFee <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.ExpenseItemPenalty AS ExpenseItem,
	|	DocumentData.ExpensesDimensionPenalties AS DimensionOfExpenses,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS AmountIncludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	DocumentData.RegistrationOption AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|
	|	DocumentData.RowIDFine AS RowID,
	|	DocumentData.ARAPObject.UUID AS FinRecordID,
	|
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CCDImport AS DocumentData
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentData.Ref = Amounts.Ref
	|		AND DocumentData.RowIDFine = Amounts.RowID
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsPenalty <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Registers);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Registers);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	TextSelectionOfAnalystField =
	"SELECT
	|	""Goods"" 												AS TabularSectionName,
	|	DocumentTable.LineNumber 							AS LineNumber,
	|	DocumentData.Partner									AS Vendor,
	|	DocumentData.Counterparty								AS Counterparty,
	|	DocumentTable.VATRate 								AS VATRate,
	|	DocumentTable.PurchaseForActivity					AS VATTaxation,
	|	VALUE(Enum.AssetKinds.CustomsPayments)	AS AssetTaxClass,
	|	0														AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.CCDImport.Goods AS DocumentTable
	|	INNER JOIN Document.CCDImport AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	""Document"" 												AS TabularSectionName,
	|	0 															AS LineNumber,
	|	DocumentData.Partner										AS Vendor,
	|	DocumentData.Counterparty									AS Counterparty,
	|	VALUE(Catalog.VATRates.EXCLUDINGVAT)						AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef)	AS VATTaxation,
	|	VALUE(Enum.AssetKinds.CustomsPayments)		AS AssetTaxClass,
	|	0															AS RowCode
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function QueryTextVtProductsForAnalystConnection(Query, QueryTexts)
	
	RegisterName = "VtProductsForAnalystConnection";
	
	QueryText = 
	"SELECT
	|	TSGoods.Ref AS Ref,
	|	TSGoods.SectionNumber AS SectionNumber,
	|	TSGoods.Products AS Products,
	|	TSGoods.Characteristic AS Characteristic,
	|	TSGoods.Package AS Package,
	|	TSGoods.NumberOfPackages AS NumberOfPackages,
	|	TSGoods.Count AS Count,
	|	TSGoods.QuantityByGBRN AS QuantityByGBRN,
	|	TSGoods.CustomsValue AS CustomsValue,
	|	TSGoods.DutyAmount AS DutyAmount,
	|	TSGoods.VATAmount AS VATAmount,
	|	TSGoods.Warehouse AS Warehouse,
	|	TSGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TSGoods.InventoryOwnerAttribute.Organization AS TypeOfInventoryOwnerAttributeCompany,
	|	TSGoods.InventoryOwnerAttribute.GoodsOwner AS TypeOfInventoryOwnerAttributeOwnerOfItem,
	|	TSGoods.InventoryOwnerAttribute.VATTaxation AS TypeOfInventoryOwnerAttributeTaxationOfVAT,
	|	TSGoods.InventoryOwnerAttribute.FinancialAccountingGroup AS InventoryOwnerAttributeFinancialAccountingGroup,
	|	TSGoods.InventoryOwnerAttribute.ProductsGroup AS InventoryOwnerAttributeIsProductGroup,
	|	TSGoods.InventoryOwnerAttribute.PriceKind AS InventoryOwnerAttributePriceType,
	|	TSGoods.InventoryOwnerAttribute.SubjectToExcise AS InventoryOwnerAttributeIsSubjectToExciseDuty,
	|	TSGoods.OriginCountry ASCountryOfOrigin,
	|	TSGoods.DeclarationNoForInvoice AS DeclarationNoForInvoice,
	|	TSGoods.CCDNumber AS CCDNumber,
	|	TSGoods.Series AS Series,
	|	TSGoods.BatchesIndicationStatus AS BatchesIndicationStatus,
	|	TSGoods.ItemsLocationAttributes AS DimensionKey,
	|	TSGoods.ItemsLocationAttributes.ProductCostElement AS ProductCostElement,
	|	TSGoods.ItemsLocationAttributes.StorageLocation AS StorageLocation,
	|	TSGoods.DocumentInflow AS DocumentInflow,
	|	TSGoods.PurchaseForActivity AS PurchaseForActivity,
	|	TSGoods.Purpose AS Purpose,
	|	TSGoods.VATRate AS VATRate,
	|	TSGoods.DutyRate AS DutyRate,
	|	TSGoods.BusinessOperation AS BusinessOperation
	|INTO VtProductsForAnalystConnection
	|FROM
	|	Document.CCDImport.Goods AS TSGoods
	|WHERE
	|	TSGoods.Ref = &Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Series,
	|	Purpose,
	|	ProductCostElement,
	|	StorageLocation";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableCompanyGoods(Query, QueryTexts, Registers)
	
	RegisterName = "CompanyGoods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTypesOfStocksForConnectingAnalytics", QueryTexts) Then
		QueryTextVtProductsForAnalystConnection(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentData.Organization AS Organization,
	|	DocumentGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	DocumentGoods.CCDNumber AS CCDNumber,
	|	DocumentGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE DocumentGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DocumentData.RegistrationOption AS BusinessOperation
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|
	|	INNER JOIN
	|		Document.CCDImport AS DocumentData
	|	ON
	|		DocumentGoods.Ref = DocumentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentGoods.BusinessOperation <>
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|
	|UNION ALL
	|
	// Arrival of goods in transit, on contract, without GTD.
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentData.Organization AS Organization,
	|	DocumentGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	DocumentGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	DocumentData.RegistrationOption AS BusinessOperation
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|
	|	INNER JOIN
	|		Document.CCDImport AS DocumentData
	|	ON
	|		DocumentGoods.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentGoods.BusinessOperation = 
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|	
	|
	|UNION ALL
	|
	// Arrival of own goods, to the warehouse, from the GTD.
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	ISNULL(Dimension.DimensionKey, DocumentGoods.DimensionKey) AS ItemsLocationAttributes,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentData.Organization AS Organization,
	|	ISNULL(TypesOfStocksWarehouse.Ref, DocumentGoods.InventoryOwnerAttribute),
	|	DocumentGoods.CCDNumber AS CCDNumber,
	|	DocumentGoods.Count AS Count,
	|	CASE
	|		WHEN NOT &UseTraceableImportedGoodsAccounting
	|				OR BEGINOFPERIOD(&Period, MONTH) < &DateOfTraceableImportedGoodsAccountingStart
	|			THEN 0
	|		ELSE DocumentGoods.QuantityByGBRN
	|	END AS QuantityByGBRN,
	|	DocumentData.RegistrationOption AS BusinessOperation
	|FROM
	|	VtProductsForAnalystConnection AS DocumentGoods
	|
	|	INNER JOIN
	|		Document.CCDImport AS DocumentData
	|	ON
	|		DocumentGoods.Ref = DocumentData.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON DocumentGoods.Products = Dimension.Products
	|		AND DocumentGoods.Characteristic = Dimension.Characteristic
	|		AND DocumentGoods.Series = Dimension.Series
	|		AND DocumentGoods.Purpose = Dimension.Purpose
	|		AND DocumentGoods.ProductCostElement = Dimension.ProductCostElement
	|		AND DocumentGoods.Warehouse = Dimension.StorageLocation
	|
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|	ON TypesOfStocksWarehouse.Organization = DocumentGoods.TypeOfInventoryOwnerAttributeCompany
	|		AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		AND TypesOfStocksWarehouse.GoodsOwner = DocumentGoods.TypeOfInventoryOwnerAttributeOwnerOfItem
	|		AND TypesOfStocksWarehouse.VATTaxation = DocumentGoods.TypeOfInventoryOwnerAttributeTaxationOfVAT
	|		AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentGoods.InventoryOwnerAttributeFinancialAccountingGroup
	|		AND TypesOfStocksWarehouse.ProductsGroup = DocumentGoods.InventoryOwnerAttributeIsProductGroup
	|		AND TypesOfStocksWarehouse.PriceKind = DocumentGoods.InventoryOwnerAttributePriceType
	|		AND TypesOfStocksWarehouse.SubjectToExcise = DocumentGoods.InventoryOwnerAttributeIsSubjectToExciseDuty
	|		AND NOT TypesOfStocksWarehouse.IsDuplicate
	|		AND NOT TypesOfStocksWarehouse.Obsolete1
	|		AND NOT TypesOfStocksWarehouse.DeletionMark
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentGoods.BusinessOperation = 
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|	
	|
	|UNION ALL
	|
	// Consumption of own goods, to the warehouse, without GTE.
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	ISNULL(Dimension.DimensionKey, DocumentGoods.DimensionKey) AS ItemsLocationAttributes,
	|	DocumentGoods.Products AS Products,
	|	DocumentGoods.Characteristic AS Characteristic,
	|	DocumentData.Organization AS Organization,
	|	ISNULL(TypesOfStocksWarehouse.Ref, DocumentGoods.InventoryOwnerAttribute),
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	DocumentGoods.Count AS Count,
	|	0 AS QuantityByGBRN,
	|	DocumentData.RegistrationOption AS BusinessOperation
	|FROM
	|	VtProductsForAnalystConnection AS DocumentGoods
	|
	|	INNER JOIN
	|		Document.CCDImport AS DocumentData
	|	ON
	|		DocumentGoods.Ref = DocumentData.Ref
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON DocumentGoods.Products = Dimension.Products
	|		AND DocumentGoods.Characteristic = Dimension.Characteristic
	|		AND DocumentGoods.Series = Dimension.Series
	|		AND DocumentGoods.Purpose = Dimension.Purpose
	|		AND DocumentGoods.ProductCostElement = Dimension.ProductCostElement
	|		AND DocumentGoods.Warehouse = Dimension.StorageLocation
	|
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfStocksWarehouse
	|	ON TypesOfStocksWarehouse.Organization = DocumentGoods.TypeOfInventoryOwnerAttributeCompany
	|		AND TypesOfStocksWarehouse.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		AND TypesOfStocksWarehouse.GoodsOwner = DocumentGoods.TypeOfInventoryOwnerAttributeOwnerOfItem
	|		AND TypesOfStocksWarehouse.VATTaxation = DocumentGoods.TypeOfInventoryOwnerAttributeTaxationOfVAT
	|		AND TypesOfStocksWarehouse.FinancialAccountingGroup = DocumentGoods.InventoryOwnerAttributeFinancialAccountingGroup
	|		AND TypesOfStocksWarehouse.ProductsGroup = DocumentGoods.InventoryOwnerAttributeIsProductGroup
	|		AND TypesOfStocksWarehouse.PriceKind = DocumentGoods.InventoryOwnerAttributePriceType
	|		AND TypesOfStocksWarehouse.SubjectToExcise = DocumentGoods.InventoryOwnerAttributeIsSubjectToExciseDuty
	|		AND NOT TypesOfStocksWarehouse.IsDuplicate
	|		AND NOT TypesOfStocksWarehouse.Obsolete1
	|		AND NOT TypesOfStocksWarehouse.DeletionMark
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentGoods.BusinessOperation = 
	|		VALUE(Enum.BusinessTransactions.ImportGoodsInTransit)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDatesOfCompanyGoodsReceipt(Query, QueryTexts, Registers)
	
	RegisterName = "DatesOfCompanyGoodsReceipt";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	&Period AS DateOfReceipt,
	|	Rows.Products   AS Products,
	|	Rows.Characteristic AS Characteristic,
	|	Rows.Series          AS Series,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	Rows.InventoryOwnerAttribute     AS InventoryOwnerAttribute,
	|	Rows.CCDNumber       AS CCDNumber
	|FROM
	|	Document.CCDImport.Goods AS Rows
	|
	|	LEFT JOIN
	|		InformationRegister.DatesOfCompanyGoodsReceipt AS Dates
	|	ON
	|		Rows.InventoryOwnerAttribute = Dates.InventoryOwnerAttribute 
	|		AND Rows.Products = Dates.Products
	|		AND Rows.Characteristic = Dates.Characteristic 
	|		AND Rows.Series = Dates.Series
	|		AND VALUE(Catalog.Assignments.EmptyRef) = Dates.Purpose
	|		AND Rows.CCDNumber = Dates.CCDNumber 
	|WHERE
	|	Rows.Ref = &Ref AND &ReleasedFromCustoms
	|	AND (Dates.DateOfReceipt IS NULL OR Dates.DateOfReceipt < &Period)
	|	AND Rows.BusinessOperation IN (VALUE(Enum.BusinessTransactions.EmptyRef),
	|		&BusinessTransactionsImportPurchase)
	|
	|GROUP BY
	|	Rows.Products,
	|	Rows.Characteristic,
	|	Rows.Series,
	|	Rows.InventoryOwnerAttribute,
	|	Rows.CCDNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts)
	
	TempTableName = "TTGoodsForRegistrationOfImportDocuments";
	
	QueryText = 
	"SELECT DISTINCT
	|	CASE
	|		WHEN ISNULL(GoodsForRegistrationOfImportDocuments.DocumentInflow, UNDEFINED) <> VALUE(Document.VendorInvoice.EmptyRef)
	|			AND ISNULL(GoodsForRegistrationOfImportDocuments.DocumentInflow, UNDEFINED) <> UNDEFINED
	|			THEN TRUE
	|		ELSE
	|			FALSE
	|	END AS ReceiptDocumentCompleted,
	|	TTReceipts.DocumentInflow AS DocumentInflow
	|INTO TTGoodsForRegistrationOfImportDocuments
	|FROM
	|	Document.CCDImport.Goods AS TTReceipts
	|		LEFT JOIN AccumulationRegister.GoodsForRegistrationOfImportDocuments AS GoodsForRegistrationOfImportDocuments
	|		ON TTReceipts.DocumentInflow = GoodsForRegistrationOfImportDocuments.Recorder
	|WHERE
	|	TTReceipts.Ref = &Ref";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsForRegistrationOfImportDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTGoodsForRegistrationOfImportDocuments", QueryTexts) Then
		QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	CASE
	|		WHEN DocumentGoods.BusinessOperation IN (VALUE(Enum.BusinessTransactions.EmptyRef),
	|			VALUE(Enum.BusinessTransactions.PurchaseByImport)) THEN
	|			DocumentGoods.ItemsLocationAttributes
	|		ELSE
	|			ISNULL(AnalysisOfProductAccountingByPartners.DimensionKey, VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef))
	|	END AS ItemsLocationAttributes,
	|	DocumentData.Vendor AS Vendor,
	|	DocumentData.Organization AS Organization,
	|	DocumentGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	CASE 
	|		WHEN 
	|			ISNULL(TTProductsForRegistration_.ReceiptDocumentCompleted,FALSE) THEN
	|				DocumentGoods.DocumentInflow
	|		ELSE
	|			UNDEFINED
	|	END AS DocumentInflow,
	|
	|   &MetadataIdentifier AS ImportDocumentType,
	|	0 AS QuantityByGBRN,	
	|
	|	DocumentGoods.Count AS Count,
	|	CASE 
	|		WHEN 
	|			ISNULL(TTProductsForRegistration_.ReceiptDocumentCompleted,FALSE) THEN
	|				DocumentGoods.CustomsValue
	|		ELSE
	|			0
	|	END AS Sum,
	|
	|	DocumentGoods.CCDNumber AS CCDNumber
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|
	|	INNER JOIN Document.CCDImport AS DocumentData
	|	ON DocumentGoods.Ref = DocumentData.Ref
	|	LEFT JOIN TTGoodsForRegistrationOfImportDocuments AS TTProductsForRegistration_
	|	ON TTProductsForRegistration_.DocumentInflow = DocumentGoods.DocumentInflow
	|	LEFT JOIN Document.VendorInvoice AS ReceiptData
	|	ON DocumentGoods.DocumentInflow = ReceiptData.Ref
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalysisOfProductAccountingByPartners
	|		ON DocumentGoods.Products = AnalysisOfProductAccountingByPartners.Products
	|		AND DocumentGoods.Characteristic = AnalysisOfProductAccountingByPartners.Characteristic
	|		AND DocumentGoods.Purpose = AnalysisOfProductAccountingByPartners.Purpose
	|		AND DocumentGoods.Series = AnalysisOfProductAccountingByPartners.Series
	|		AND ReceiptData.Contract = AnalysisOfProductAccountingByPartners.StorageLocation
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentGoods.BusinessOperation IN (VALUE(Enum.BusinessTransactions.EmptyRef),
	|		&BusinessTransactionsImportPurchase)
	|	AND &ReleasedFromCustoms
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableExpenseBatchesToGoodsCost(Query, QueryTexts, Registers)
	
	RegisterName = "ExpenseBatchesToGoodsCost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) 			AS RecordType,
	|	DocumentData.Organization 					AS Organization,
	|	DocumentGoods.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	&Ref											AS DocumentInflow,
	|	DocumentGoods.InventoryOwnerAttribute 						AS InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	&Ref 										AS ExpenseReceiptDocument,
	|	UNDEFINED 									AS ExpenseItem,
	|
	|	SUM(DocumentGoods.Count)				AS Count,
	|	SUM(&ConversionRateToManCurrency 
	|			* (DocumentGoods.DutyAmount + DocumentGoods.VATAmount)) AS Cost,
	|	SUM(&ConversionRateToManCurrency
	|			* DocumentGoods.DutyAmount) 						AS CostExcludingVAT,
	|	SUM(DocumentGoods.DutyAmount) 							AS LocalCost,
	|	SUM(
	|		CASE 
	|			WHEN TableOfBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|				THEN 0 
	|				ELSE DocumentGoods.VATAmount
	|		END) 														AS VATLocal,
	|	&Department													AS ExpensesBusinessUnit,
	|	0																AS PermanentDifference,
	|	0																AS CostTD
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|	INNER JOIN 
	|		Document.CCDImport AS DocumentData
	|	ON 
	|		DocumentGoods.Ref = DocumentData.Ref
	|
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 	    = DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND &BatchAccountingVersion21
	|
	|GROUP BY
	|	DocumentData.Organization,
	|	DocumentGoods.ItemsLocationAttributes,
	|	DocumentGoods.InventoryOwnerAttribute,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Goods"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	&Period AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Period AS VATBasePeriod,
	|	&Period AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.DutyAmount AS AmountExcludingVAT,
	|	ISNULL(TableSections.VATRate, VALUE(Catalog.VATRates.EmptyRef)) AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,	
	|	DocumentTable.DutyAmount + DocumentTable.VATAmount AS AmountARAP,
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	&ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CCDImport.Goods AS DocumentTable
	|	LEFT JOIN 
	|		Document.CCDImport.Sections AS TableSections
	|	ON
	|		TableSections.Ref = DocumentTable.Ref
	|		AND TableSections.SectionNumber = DocumentTable.SectionNumber
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|
	|UNION ALL
	|
	|SELECT
	|	""CustomsFee"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentData.Ref AS Ref,
	|	&Period AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Period AS VATBasePeriod,
	|	&Period AS DateOfCourse,
	|
	|	UNDEFINED AS LineNumber,
	|	DocumentData.RowIDFee AS RowID,
	|	DocumentData.CustomsFee AS AmountExcludingVAT,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS VATAmount,	
	|	DocumentData.CustomsFee AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	&ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsFee <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	""CustomsPenalty"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentData.Ref AS Ref,
	|	&Period AS Date,
	|	&Organization AS Organization,
	|	&Currency AS DocumentCurrency,
	|	&ARAPCurrency AS ARAPCurrency,
	|	&Period AS VATBasePeriod,
	|	&Period AS DateOfCourse,
	|
	|	UNDEFINED AS LineNumber,
	|	DocumentData.RowIDFine AS RowID,
	|	DocumentData.CustomsPenalty AS AmountExcludingVAT,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	0 AS VATAmount,	
	|	DocumentData.CustomsPenalty AS AmountARAP,
	|	0 AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	&ARAPObject AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsPenalty <> 0
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	QueryText =  "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	DocumentData.ExpenseItemFee AS ExpenseItem,
	|	DocumentData.ExpensesDimensionFees AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&TaxationOfOrganization AS VATActivityType,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS Cost,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS CostExcludingVAT,
	|	0 AS VATManag,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	DocumentData.RegistrationOption AS BusinessOperation,
	|	
	|	DocumentData.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	Document.CCDImport AS DocumentData
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.TabularSectionName = ""Document""
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentData.Ref = Amounts.Ref
	|		AND DocumentData.RowIDFee = Amounts.RowID
	|WHERE
	|	DocumentData.Ref = &Ref 
	|	AND &ReleasedFromCustoms 
	|	AND DocumentData.CustomsFee <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	DocumentData.ExpenseItemPenalty AS ExpenseItem,
	|	DocumentData.ExpensesDimensionPenalties AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|	CASE
	|		WHEN ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) THEN
	|			DocumentData.LineOfBusiness
	|	END AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	&TaxationOfOrganization AS VATActivityType,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan, 0) AS Cost,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS CostExcludingVAT,
	|	0 AS VATManag,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0) AS LocalCost,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	0 AS VATLocal,
	|	DocumentData.RegistrationOption AS BusinessOperation,
	|	
	|	DocumentData.ARAPObject.UUID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CCDImport AS DocumentData
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.TabularSectionName = ""Document""
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentData.Ref = Amounts.Ref
	|		AND DocumentData.RowIDFine = Amounts.RowID
	|WHERE
	|	DocumentData.Ref = &Ref 
	|	AND &ReleasedFromCustoms 
	|	AND DocumentData.CustomsPenalty <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts, Registers);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, Registers);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableLotsVATForAllocation(Query, QueryTexts, Registers)
	
	RegisterName = "LotsVATForAllocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	DocumentData.Counterparty AS Vendor,
	|	&Ref AS ExpenseReceiptDocument,
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	VALUE(Enum.AssetKinds.CustomsPayments) AS AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes.VATRate AS VATRate,
	|
	|	DocumentGoods.DutyAmount AS LocalCost,
	|	DocumentGoods.VATAmount     AS VATLocal,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN &ConversionRateToManCurrency * DocumentGoods.VATAmount
	|		ELSE 0 END            AS VATManag
	|
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|	INNER JOIN 
	|		Document.CCDImport AS DocumentData
	|	ON 
	|		DocumentGoods.Ref = DocumentData.Ref
	|
	|	INNER JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 	    = DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	DocumentData.Ref = &Ref 
	|	AND &ReleasedFromCustoms 
	|	AND DocumentGoods.VATAmount <> 0
	|	AND TableOfBatchAccountingAnalysts.VATTaxation = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
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
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText =
	"// Fee reflection.
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	DocumentGoods.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	DocumentGoods.Warehouse AS Warehouse,
	|	DocumentGoods.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|   DocumentGoods.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	ISNULL(DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS ProductLineOfBusiness,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Terms AS Terms,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	0 AS Count,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan,
	|		CAST(&ConversionRateToManCurrency * (DocumentGoods.DutyAmount + DocumentGoods.VATAmount) AS NUMBER(31,2))) AS Sum,
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CAST(&ConversionRateToManCurrency * DocumentGoods.DutyAmount AS NUMBER(31,2))) AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 
	|		CAST(&FactorOfConversionToCurrencyOfRegul * (DocumentGoods.DutyAmount + DocumentGoods.VATAmount) AS NUMBER(31,2))) AS SumCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 
	|		CAST(&FactorOfConversionToCurrencyOfRegul * (DocumentGoods.DutyAmount) AS NUMBER(31,2))) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	CASE
	|		WHEN DocumentGoods.PurchaseForActivity IN (
	|			  VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT),
	|			  VALUE(Enum.VATTaxationTypes.PreferentialVATTaxationOnSTS),
	|			  VALUE(Enum.VATTaxationTypes.SaleIsSubjectToUTII))
	|			THEN 
	|				ISNULL(Amounts.AmountIncludingVATCompl, 
	|					CAST(&FactorOfConversionToCurrencyOfRegul * (DocumentGoods.DutyAmount + DocumentGoods.VATAmount) AS NUMBER(31,2))) 
	|		ELSE
	|			ISNULL(Amounts.AmountExcludingVATCompl, 
	|				CAST(&FactorOfConversionToCurrencyOfRegul * (DocumentGoods.DutyAmount) AS NUMBER(31,2)))
	|	END AS LocalCost,
	|
	|	ISNULL(Amounts.AmountIncludingVATMan,
	|		CAST(&ConversionRateToManCurrency * (DocumentGoods.DutyAmount + DocumentGoods.VATAmount) AS NUMBER(31,2))) AS AddExpensesForGoods,
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CAST(&ConversionRateToManCurrency * DocumentGoods.DutyAmount AS NUMBER(31,2))) AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS Currency,
	|	DocumentGoods.DutyAmount + DocumentGoods.VATAmount AS AmountInDocumentCurrency,
	|	DocumentGoods.DutyAmount AS AmountExcludingVATInDocumentCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	CAST((DocumentGoods.DutyAmount + DocumentGoods.VATAmount)
	|			* &ConversionRateToSettlementCurrency AS NUMBER(31,2)) AS AmountInARAPCurrency,
	|	CAST(DocumentGoods.DutyAmount
	|			* &ConversionRateToSettlementCurrency AS NUMBER(31,2)) AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN DocumentGoods.InventoryOwnerAttribute
	|		ELSE DocumentGoods.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObject AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	Document.CCDImport.Goods AS DocumentGoods
	|
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON DocumentGoods.Ref = Amounts.Ref
	|		AND DocumentGoods.RowID = Amounts.RowID
	|WHERE
	|	DocumentGoods.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND (DocumentGoods.DutyAmount <> 0
	|		OR DocumentGoods.VATAmount<>0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);

#Region CostsOfCustomsDuties
	CostsOfCustomsDuties = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ExpensesForCustomsFeesFines) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	
	|	DocumentData.ExpenseItemFee AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.ExpensesDimensionFees AS DimensionOfExpenses,
	|	CASE WHEN &AccountingForLBCosts THEN
	|		&LineOfBusiness
	|	END AS LineOfBusinessItems,
	|	
	|	CAST(DocumentData.CustomsFee * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	CAST(DocumentData.CustomsFee * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CustomsFee AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	CAST(DocumentData.CustomsFee * &ConversionRateToSettlementCurrency AS NUMBER(31,2)) AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObject.UUID AS FinRecordID
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsFee <> 0
	|"; 
#EndRegion

#Region CostsOfCustomsFines
	CostsOfCustomsFines = 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ExpensesForCustomsFeesFines) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	CASE WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|		&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	UNDEFINED AS ARAPObject,
	|	
	|	DocumentData.ExpenseItemPenalty AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.ExpensesDimensionPenalties AS DimensionOfExpenses,
	|	CASE WHEN &AccountingForLBCosts THEN
	|		&LineOfBusiness
	|	END AS LineOfBusinessItems,
	|	
	|	CAST(DocumentData.CustomsPenalty * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	CAST(DocumentData.CustomsPenalty * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CustomsPenalty AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	CAST(DocumentData.CustomsPenalty * &ConversionRateToSettlementCurrency AS NUMBER(31,2)) AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObject.UUID AS FinRecordID
	|FROM
	|	Document.CCDImport AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &ReleasedFromCustoms
	|	AND DocumentData.CustomsPenalty <> 0
	|"; 
#EndRegion

	QueryText = CostsOfCustomsDuties
		+ " UNION ALL " + CostsOfCustomsFines;
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;


EndFunction

Function QueryTextTableVATInvoiced(Query, QueryTexts, Registers)
	
	RegisterName = "VATInvoiced";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf; 
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	VATAccountingERPInternal.SetParameterTypesOfTaxationVATReceipts(Query);
	Query.SetParameter("StartDateOfVATAccountingByLineOfBusiness", VATAccountingERP.AccountingSettings().StartDateOfVATAccountingByLineOfBusiness);
	
	QueryText = "
	|
	|SELECT
	|	&Ref                                                AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt)                 AS RecordType,
	|	&Period                                                AS Period,
	|	Operation.Organization                                   AS Organization,
	|	&Ref                                                AS TaxInvoice,
	|	Operation.Counterparty                                    AS Vendor,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass                 AS AssetTaxClass,
	|	DocumentGoods.VATRate                              AS VATRate,
	|	TableOfBatchAccountingAnalysts.VATTaxation          AS VATActivityType,
	|	UNDEFINED                                           AS CorrectedTaxInvoice,
	|	UNDEFINED                                           AS SaleExport,
	|	CASE WHEN &Period >= &StartDateOfVATAccountingByLineOfBusiness THEN
	|		DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness
	|	ELSE
	|		UNDEFINED
	|	END                                                  AS LineOfBusiness,
	|	SUM(Amounts.AmountExcludingVATCompl)                           AS AmountExcludingVAT,
	|	SUM(Amounts.VATAmountCompl)                              AS VAT,
	|	SUM(CASE 
	|			WHEN &CompanyManagementAccounting
	|				THEN Amounts.VATAmountMan
	|		ELSE 0
	|	END)                                                 AS VATManag,
	|	UNDEFINED                                           AS Event,
	|	FALSE                                                   AS PeriodEndTransaction,
	|	
	|	Operation.ARAPObject.UUID        AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.CCDImport AS Operation
	|	
	|	INNER JOIN
	|		Document.CCDImport.Goods AS DocumentGoods
	|	ON
	|		Operation.Ref = DocumentGoods.Ref
	|  	
	|   LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON DocumentGoods.Ref = Amounts.Ref
	|		AND DocumentGoods.RowID = Amounts.RowID
	|		
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 	    = DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	
	|WHERE
	|	Operation.Ref = &Ref
	|	AND Operation.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Operation.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
	|	AND (TableOfBatchAccountingAnalysts.VATTaxation IN (&TypesOfTaxationVATReceipts)
	|		OR (TableOfBatchAccountingAnalysts.VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND &GenerateVATChargedWhenIncludingInCost))
	|
	|GROUP BY
	|	Operation.Organization,
	|	Operation.Counterparty,
	|	DocumentGoods.VATRate,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation,
	|	CASE WHEN &Period >= &StartDateOfVATAccountingByLineOfBusiness THEN
	|		DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness
	|	ELSE
	|		UNDEFINED
	|	END,
	|	Operation.ARAPObject
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref                                                AS Recorder,
	|	VALUE(AccumulationRecordType.Expense)                 AS RecordType,
	|	&Period                                                AS Period,
	|	Operation.Organization                                   AS Organization,
	|	&Ref                                                AS TaxInvoice,
	|	Operation.Counterparty                                    AS Vendor,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass                 AS AssetTaxClass,
	|	DocumentGoods.VATRate                              AS VATRate,
	|	TableOfBatchAccountingAnalysts.VATTaxation          AS VATActivityType,
	|	UNDEFINED                                           AS CorrectedTaxInvoice,
	|	UNDEFINED                                           AS SaleExport,
	|	CASE WHEN &Period >= &StartDateOfVATAccountingByLineOfBusiness THEN
	|		DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness
	|	ELSE
	|		UNDEFINED
	|	END                                                  AS LineOfBusiness,
	|	SUM(Amounts.AmountExcludingVATCompl)                           AS AmountExcludingVAT,
	|	SUM(Amounts.VATAmountCompl)                              AS VAT,
	|	SUM(CASE 
	|			WHEN &CompanyManagementAccounting
	|				THEN Amounts.VATAmountMan
	|		ELSE 0
	|	END)                                                 AS VATManag,
	|	UNDEFINED                                           AS Event,
	|	FALSE                                                   AS PeriodEndTransaction,
	|	
	|	DocumentGoods.RowID                    AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.CCDImport AS Operation
	|	
	|	INNER JOIN
	|		Document.CCDImport.Goods AS DocumentGoods
	|	ON
	|		Operation.Ref = DocumentGoods.Ref
	|  	
	|   LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON DocumentGoods.Ref = Amounts.Ref
	|		AND DocumentGoods.RowID = Amounts.RowID
	|		
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|	ON TableOfBatchAccountingAnalysts.LineNumber 	    = DocumentGoods.LineNumber
	|	 AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|
	|WHERE
	|	Operation.Ref = &Ref
	|	AND Operation.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|	AND Operation.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms)
	|	AND TableOfBatchAccountingAnalysts.VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND &GenerateVATChargedWhenIncludingInCost
	|
	|GROUP BY
	|	Operation.Organization,
	|	Operation.Counterparty,
	|	DocumentGoods.VATRate,
	|	TableOfBatchAccountingAnalysts.AssetTaxClass,
	|	TableOfBatchAccountingAnalysts.VATTaxation,
	|	CASE WHEN &Period >= &StartDateOfVATAccountingByLineOfBusiness THEN
	|		DocumentGoods.ItemsLocationAttributes.Purpose.LineOfBusiness
	|	ELSE
	|		UNDEFINED
	|	END,
	|	Operation.ARAPObject,
	|	DocumentGoods.RowID
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
	|	DocumentData.Ref                  AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&Partner                                AS Partner,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	CASE
	|		WHEN DocumentData.NumberOfStorageLocations = 1
	|			THEN DocumentData.StorageLocation
	|		ELSE UNDEFINED
	|	END                                   AS StorageLocation,
	|	&Department                          AS Department,
	|	&Manager                               AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Currency                                 AS Currency,
	|	&DocumentAmount                         AS Sum,
	|	&Status                                 AS Status,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	DocumentData.AdditionalRecord    AS AdditionalRecord,
	|	&ContractInformation                   AS More,
	|	&Period                                 AS SourceDocumentDate,
	|	&DeclarationNo                        AS SourceDocumentNumber,
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
	|	DocumentData.Ref AS Ref,
	|	ISNULL(DocumentGoods.BusinessOperation,
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport)) AS BusinessOperation,
	|	MAX(
	|		ISNULL(DocumentGoods.DocumentInflow.Warehouse,
	|			VALUE(Catalog.Warehouses.EmptyRef))) AS StorageLocation,
	|	COUNT(
	|		DISTINCT ISNULL(DocumentGoods.DocumentInflow.Warehouse,
	|			VALUE(Catalog.Warehouses.EmptyRef))) AS NumberOfStorageLocations,
	|	(DocumentGoods.BusinessOperation <> TableOfBasicOperations.BasicOperation) AS AdditionalRecord
	|INTO TTBases
	|FROM
	|	Document.CCDImport AS DocumentData
	|		LEFT JOIN Document.CCDImport.Goods AS DocumentGoods
	|		ON DocumentData.Ref = DocumentGoods.Ref
	|		
	|		LEFT JOIN
	|			(SELECT
	|				MAX(DocumentData.BusinessOperation) AS BasicOperation
	|			FROM
	|				Document.CCDImport.Goods AS DocumentData
	|			WHERE
	|				DocumentData.Ref = &Ref) AS TableOfBasicOperations
	|		ON TRUE
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	ISNULL(DocumentGoods.BusinessOperation,
	|		VALUE(Enum.BusinessTransactions.PurchaseByImport)),
	|	(DocumentGoods.BusinessOperation <> TableOfBasicOperations.BasicOperation)";


	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Registers);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts, Registers);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.CCDImport";
	SynonymForDocumentTable      = "";
	RequestHasSource         = True;
	TemporaryTableQueryTexts = New Map();
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("DeclarationNo",      """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	RedefiningParameterCalculation.Insert("ReleasedFromCustoms",
		"	CASE WHEN DocumentData.Ref.Status = VALUE(Enum.CustomsDeclarationStatus.ReleasedFromCustoms) THEN
		|		TRUE
		|	ELSE
		|		FALSE
		|	END");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	ParameterValues.Insert("BusinessTransactionsImportPurchase",
		PurchasesServer.BusinessOperationsOnMain(Enums.BusinessTransactions.PurchaseByImport));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "CompanyGoods" Then
		
		TemporaryTableQueryTexts.Insert("VtProductsForAnalystConnection",
			QueryTextVtProductsForAnalystConnection(Query, QueryTexts));
		QueryText = QueryTextTableCompanyGoods(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "GoodsForRegistrationOfImportDocuments" Then
		
		QueryText = QueryTextTableGoodsForRegistrationOfImportDocuments(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTGoodsForRegistrationOfImportDocuments",
			QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts));
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
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
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
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.CCDImport AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Document.CCDImport.ARAPDetails AS Table
		|		LEFT JOIN Document.CCDImport AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	HeaderData_.Ref                                                 AS Ref,
		|	HeaderData_.Organization                                            AS Organization,
		|	HeaderData_.Partner                                                AS Partner,
		|	HeaderData_.Date                                                   AS RecorderDate,
		|	HeaderData_.Number                                                  AS RecorderNumber,
		|	
		|	HeaderData_.ARAPObject                                         AS ARAPObject,
		|	HeaderData_.PaymentDate                                            AS PaymentDate,
		|	UNDEFINED                                                       AS PaymentOption,
		|	UNDEFINED                                                       AS PurchaseOrder_,
		|	
		|	HeaderData_.DocumentAmount                                         AS Sum,
		|	HeaderData_.AmountARAP                                    AS AmountARAP,
		|	0                                                                  AS AmountARAPByPackage,
		|
		|	HeaderData_.ARAPObjectSettings                                        AS ARAPObjectSettings,
		|	FALSE                                                               AS InvoiceForOrders,
		|	HeaderData_.ARAPCurrency                                   AS ARAPCurrency,
		|	HeaderData_.RegistrationOption                                      AS BusinessOperation,
		|	HeaderData_.PaymentMethod                                            AS PaymentMethod,
		|	HeaderData_.Currency                                                 AS DocumentCurrency,
		|	HeaderData_.Date                                                   AS DateOfCourse,
		|	UNDEFINED                                                       AS LinkedDocument
		|FROM
		|	Document.CCDImport AS HeaderData_
		|WHERE
		|	HeaderData_.Ref IN (&Ref)
		|	AND &ReleasedFromCustoms

		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|	SELECT
		|	HeaderData_.Ref                                                 AS Ref,
		|	HeaderData_.Organization                                            AS Organization,
		|	HeaderData_.Partner                                                AS Partner,
		|	HeaderData_.Date                                                   AS RecorderDate,
		|	HeaderData_.Number                                                  AS RecorderNumber,
		|	HeaderData_.PaymentDate                                            AS PaymentDate,
		|	
		|	HeaderData_.ARAPObject                                         AS ARAPObject,
		|	HeaderData_.ARAPObjectSettings                                        AS ARAPObjectSettings,
		|	FALSE                                                               AS InvoiceForOrders,
		|	FALSE                                                               AS ExceedingOrder,
		|	UNDEFINED                                                       AS PurchaseOrder_,
		|	HeaderData_.DocumentAmount                                         AS AmountDue,
		|	HeaderData_.ARAPCurrency                                   AS ARAPCurrency,
		|	HeaderData_.RegistrationOption                                      AS BusinessOperation,
		|	HeaderData_.PaymentMethod                                            AS PaymentMethod,
		|	HeaderData_.Currency                                                 AS DocumentCurrency,
		|	UNDEFINED                                                       AS PaymentOption,
		|	UNDEFINED                                                       AS LinkedDocument
		|FROM
		|	Document.CCDImport AS HeaderData_
		|WHERE
		|	HeaderData_.Ref IN (&Ref)
		|";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                    AS Ref,
		|	Table.Ref.Organization                                        AS Organization,
		|	Table.Ref.Partner                                            AS Partner,
		|	
		|	Table.ARAPObject                                            AS CalculationObjectSource,
		|	Table.Ref.ARAPObject                                     AS CalculationObjectReceiver,
		|
		|	Table.Ref.ARAPCurrency                               AS ARAPCurrency,
		|	Table.AmountARAP                                       AS AmountARAP,
		|	Table.Ref.Currency                                             AS DocumentCurrency,
		|	Table.Sum                                                     AS Sum,
		|
		|	Table.Ref.Date                                               AS RecorderDate,
		|	Table.Ref.Date                                               AS DateOfCourse,
		|	Table.Ref.Number                                              AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)        AS BusinessOperation
		|	
		|FROM
		|	Document.CCDImport.ARAPDetails AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
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
	AdditionalParameters.Add("TypesOfTaxationVATIsIncludedInCost");
	
	If Query <> Undefined Then
		SetRequestParametersCurrencyCoefficients(Query);
		InitializeProductAccountingAnalyticsKeys(Query);
		Query.SetParameter("TypesOfTaxationVATIsIncludedInCost",
			VATAccountingERP.ActivitiesVATIsIncludedInCost());
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTAmountsOfDocumentsInAccountingCurrencies");
	AdditionalTables.Add("TTGoodsForRegistrationOfImportDocuments");
	AdditionalTables.Add("TTTableOfPartyAccountingAnalysts");
	AdditionalTables.Add("TTAmountsOfDocumentsInAccountingCurrencies");
	
	If Query <> Undefined Then
	
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[1], QueryTexts) Then
			QueryTextTTGoodsForRegistrationOfImportDocuments(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[2], QueryTexts) Then
			QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
		EndIf;
		
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[2], QueryTexts) Then
			GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region ExternalReceipt_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentInflow	AS DocumentSource,
	|	CASE
	|		WHEN ISNULL(TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted, FALSE)
	|			THEN TableTypesOfStocks_.DocumentInflow
	|			ELSE UNDEFINED
	|	END									AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_					AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 										  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 						  AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 										  AS InventoryOwnerAttribute,
	|	UNDEFINED 								  						  AS Lot,
	|	ISNULL(TableOfBatchAccountingAnalysts.VATTaxation, TableTypesOfStocks_.PurchaseForActivity) AS VATActivityType,
	|	UNDEFINED									  					  AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 									AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableOfBatchAccountingAnalysts.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	UNDEFINED 					AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	TableTypesOfStocks_.DocumentInflow.SalesOpportunity			AS SalesOpportunity,
	|	TableTypesOfStocks_.DocumentInflow.Department 	AS Department,
	|	TableTypesOfStocks_.DocumentInflow.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0 										AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN 0
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl,
	|			CAST(&FactorOfConversionToCurrencyOfRegul * TableTypesOfStocks_.DutyAmount AS NUMBER(31,2)))
	|	END 									AS LocalCost,
	|	ISNULL(Amounts.VATAmountCompl,
	|		CASE WHEN ISNULL(TableOfBatchAccountingAnalysts.VATTaxation, TableTypesOfStocks_.PurchaseForActivity)
	|		  = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0 
	|			ELSE CAST(&FactorOfConversionToCurrencyOfRegul * TableTypesOfStocks_.VATAmount AS NUMBER(31,2))
	|		END)                              AS VATLocal,
	|	0 										AS CostMan,
	|	ISNULL(Amounts.VATAmountMan,
	|		CASE WHEN ISNULL(TableOfBatchAccountingAnalysts.VATTaxation, TableTypesOfStocks_.PurchaseForActivity)
	|		  = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|			THEN 0 
	|			ELSE CAST(&ConversionRateToManCurrency * TableTypesOfStocks_.VATAmount AS NUMBER(31,2))
	|		END) 								AS VATManag,
	|	0 										AS OffBalanceCost,
	|	0 										AS OffBalanceCostLocal,
	|	ISNULL(Amounts.AmountIncludingVATMan,
	|		CAST(&ConversionRateToManCurrency * (TableTypesOfStocks_.DutyAmount + TableTypesOfStocks_.VATAmount) AS NUMBER(31,2))) AS AddExpensesForGoods,
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CAST(&ConversionRateToManCurrency * TableTypesOfStocks_.DutyAmount AS NUMBER(31,2))) AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN NOT &BatchAccountingVersion22
	|		THEN 0
	|		ELSE ISNULL(Amounts.AmountExcludingVATCompl,
	|			CAST(&FactorOfConversionToCurrencyOfRegul * TableTypesOfStocks_.DutyAmount AS NUMBER(31,2)))
	|	END 									AS AddExpensesLocal,
	|	ISNULL(Amounts.AmountExcludingVATMan,
	|		CAST(&ConversionRateToManCurrency * TableTypesOfStocks_.DutyAmount AS NUMBER(31,2))) AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	CASE
	|		WHEN ISNULL(TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted, FALSE)
	|			THEN VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification)
	|			ELSE VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification)
	|	END 															 AS BusinessOperation,
	|	DocumentTable.ARAPObject.UUID			 AS FinRecordID,
	|	&BusinessTransactionSetting                             	 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CCDImport.Goods AS TableTypesOfStocks_
	|	INNER JOIN Document.CCDImport AS DocumentTable
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|	LEFT JOIN TTGoodsForRegistrationOfImportDocuments AS TTGoodsForRegistrationOfImportDocuments
	|		ON TTGoodsForRegistrationOfImportDocuments.DocumentInflow = TableTypesOfStocks_.DocumentInflow
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	   = TableTypesOfStocks_.LineNumber
	|	 	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &ReleasedFromCustoms
	|	AND (TableTypesOfStocks_.DutyAmount <> 0
	|		OR TableTypesOfStocks_.VATAmount<>0)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	#Region ExternalReceipt_Item_InclusionOfExciseTaxInCost
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 					AS Period,
	|	DocumentTable.Ref 				AS Ref,
	|	TableTypesOfStocks_.DocumentInflow	AS DocumentSource,
	|	CASE
	|		WHEN ISNULL(TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted, FALSE)
	|			THEN TableTypesOfStocks_.DocumentInflow
	|			ELSE UNDEFINED
	|	END									AS SourceDocumentPeriod,
	|	UNDEFINED 							AS DocumentToBeCorrected,
	|	UNDEFINED			AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 										  AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 						  AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryOwnerAttribute 										  AS InventoryOwnerAttribute,
	|	UNDEFINED 								  						  AS Lot,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN ISNULL(TableOfBatchAccountingAnalysts.VATTaxation, TableTypesOfStocks_.PurchaseForActivity)
	|		ELSE UNDEFINED
	|	END 																  AS VATActivityType,
	|	UNDEFINED									  					  AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	UNDEFINED 									AS LotVendorAttributes,
	|	CASE WHEN &BatchAccountingVersion22
	|		THEN TableOfBatchAccountingAnalysts.LotVendorAttributes
	|		ELSE UNDEFINED
	|	END 											AS LotVendorAttributesCorr,
	|	UNDEFINED 					AS Vendor,
	|	DocumentTable.Counterparty 	AS Counterparty,
	|	TableTypesOfStocks_.VATRate 	AS VATRate,
	|
	// Corresponding fields
	|	UNDEFINED					AS CorItemsLocationAttributes,
	|	UNDEFINED					AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	TableTypesOfStocks_.DocumentInflow.SalesOpportunity			AS SalesOpportunity,
	|	TableTypesOfStocks_.DocumentInflow.Department 	AS Department,
	|	TableTypesOfStocks_.DocumentInflow.Manager 		AS Manager,
	|
	// Quantitative and summary indicators
	|	0 										AS Count,
	|	TableTypesOfStocks_.RowID 	AS RowID,
	|	0 										AS Cost,
	|	0 										AS CostExcludingVAT,
	|	CASE
	|		WHEN &BatchAccountingVersion22
	|			THEN 0
	|		ELSE TableTypesOfStocks_.ExciseTaxAmount
	|	END 									AS LocalCost,
	|	0										AS VATLocal,
	|	0 										AS CostMan,
	|	0 										AS VATManag,
	|	0 										AS OffBalanceCost,
	|	0 										AS OffBalanceCostLocal,
	|	CAST(&ConversionRatioFromLocalToMan * TableTypesOfStocks_.ExciseTaxAmount AS NUMBER(31,2)) AS AddExpensesForGoods,
	|	CAST(&ConversionRatioFromLocalToMan * TableTypesOfStocks_.ExciseTaxAmount AS NUMBER(31,2)) AS AdditionalExpensesExcludingVAT,
	|	CASE WHEN NOT &BatchAccountingVersion22
	|			THEN 0
	|		ELSE TableTypesOfStocks_.ExciseTaxAmount
	|	END 									AS AddExpensesLocal,
	|	CAST(&ConversionRatioFromLocalToMan * TableTypesOfStocks_.ExciseTaxAmount AS NUMBER(31,2)) AS AddExpensesMan,
	|	0 										AS PermanentDifference,
	|	0 										AS CostTD,
	|	0										AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.LotRecordTypes.IncludeExciseInCost) AS EntryType,
	|	CASE
	|		WHEN ISNULL(TTGoodsForRegistrationOfImportDocuments.ReceiptDocumentCompleted, FALSE)
	|			THEN VALUE(Enum.BusinessTransactions.AdditionalExpensesWithLotDocumentSpecification)
	|			ELSE VALUE(Enum.BusinessTransactions.AdditionalExpensesWithoutLotDocumentSpecification)
	|	END 															 AS BusinessOperation,
	|	TableTypesOfStocks_.RowID							 AS FinRecordID,
	|	&SettingUpBusinessOfOperation_AccrualOfExciseTaxes	 AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CCDImport.Goods AS TableTypesOfStocks_
	|	INNER JOIN Document.CCDImport AS DocumentTable
	|		ON TableTypesOfStocks_.Ref = DocumentTable.Ref
	|	LEFT JOIN TTGoodsForRegistrationOfImportDocuments AS TTGoodsForRegistrationOfImportDocuments
	|		ON TTGoodsForRegistrationOfImportDocuments.DocumentInflow = TableTypesOfStocks_.DocumentInflow
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber 	   = TableTypesOfStocks_.LineNumber
	|	 	AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Goods""
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND &ReleasedFromCustoms
	|	AND TableTypesOfStocks_.ExciseTaxAmount <> 0";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region InitializationAndFilling

Procedure FillByDefault(Object) Export
	
	Organization = Object.Organization;
	
	Object.Manager = Users.CurrentUser();
	Object.Department = SettingsValueCached.UserDivision(Object.Manager, Object.Department);
	Object.Organization = SettingsValueCached.GetDefaultOrganization(Object.Organization);
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	Object.ARAPCurrency = Object.Currency;
	
	CompanyBankAccount = ?(Organization = Object.Organization, Object.CompanyBankAccount, Undefined);
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, CompanyBankAccount);
	
	CurrencyOfPayment  = CashServer.GetPaymentCurrency(Object.PaymentMethod, Object.CompanyBankAccount);
	Object.ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency(CurrencyOfPayment, Object.Organization);
	
EndProcedure

Procedure FillInAccordingToTermsOfPurchase(Object, PurchaseConditions) Export
	
	Counterparty = Object.Counterparty;
	
	FillPropertyValues(Object, PurchaseConditions, "PaymentMethod, FinancialAccountingGroup, LineOfBusiness, ForeignCurrencyTransaction");
	If Not ValueIsFilled(Object.RegistrationOption) Then
		Object.RegistrationOption = Enums.BusinessTransactions.RegisterCCDThroughBroker;
	EndIf;
	If Not ValueIsFilled(Object.Partner) Then
		Object.Partner = PurchaseConditions.Partner;
	EndIf;
	If ValueIsFilled(PurchaseConditions.Organization) And PurchaseConditions.Organization<>Object.Organization Then
		Object.Organization = PurchaseConditions.Organization;
		Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
	EndIf;
	If ValueIsFilled(PurchaseConditions.Counterparty) And PurchaseConditions.Counterparty<>Object.Counterparty Then
		Object.Counterparty = PurchaseConditions.Counterparty;
	EndIf;
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
	
	If Counterparty <> Object.Counterparty Then
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
		Object.CounterpartyBankAccount =
			CashServer.GetDefaultCounterpartyBankAccount(ParametersOfAccount);
	EndIf;
	
	If PurchaseConditions.ContractsAreUsed <> Undefined And PurchaseConditions.ContractsAreUsed Then
		
		AddlParameters = PurchasesServer.AdditionalContractSelectionParameters();
		AddlParameters.ARAPCurrency = Object.ARAPCurrency;
		Object.Contract = PurchasesServer.GetDefaultContract(
			Object, OperationsOfSelectionOfAgreementsContracts(), AddlParameters);
		PurchasesServerCall.FillInBankAccountsUnderAgreement(Object.Contract, Object.CompanyBankAccount, Object.CounterpartyBankAccount);
		
		If ValueIsFilled(Object.Contract) Then
			ForeignCurrencyTransaction = Common.ObjectAttributeValue(Object.Contract, "ForeignCurrencyTransaction");
			If ForeignCurrencyTransaction <> Object.ForeignCurrencyTransaction Then
				Object.ForeignCurrencyTransaction = ForeignCurrencyTransaction;
				Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
			EndIf;
		EndIf;
		
		If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") 
			Or GetFunctionalOption("UseVendorARAPInLineOfBusiness") Then
			LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
		EndIf;
		
	Else
		
		If Object.ForeignCurrencyTransaction <> PurchaseConditions.ForeignCurrencyTransaction Then
			Object.ForeignCurrencyTransaction = PurchaseConditions.ForeignCurrencyTransaction;
			Object.CompanyBankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		EndIf;
		
	EndIf;
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Object.Organization);
	ParametersOfAccount.LineOfBusiness = Object.LineOfBusiness;
	ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ParametersOfAccount.ExcludeCurrencyAccounts = Object.ForeignCurrencyTransaction;
	Object.CompanyBankAccount = CashServer.GetOrganizationSDefaultBankAccount(
		ParametersOfAccount, Object.CompanyBankAccount);
	
	PaymentDateValue = PurchasesServer.GetLatestDateOnSchedule(Object.Date, PurchaseConditions.Terms);
	If ValueIsFilled(PaymentDateValue) Then
		Object.PaymentDate = PaymentDateValue;
	EndIf;
	
EndProcedure

Procedure FillInByPartner(Object, Partner) Export
	
	PurchaseConditions = Undefined;
	
	If Not ValueIsFilled(Object.Partner) Or (Object.Partner <> Partner) Then
		Object.Partner = Partner;
	EndIf;
	If (Object.RegistrationOption <> Enums.BusinessTransactions.RegisterCCDUnassisted) Then
		
		FilterParameters = New Structure;
		FilterParameters.Insert("ForPurchaseOnly",      False);
		FilterParameters.Insert("BusinessTransactions", OperationsOfSelectionOfAgreementsContracts());
		FilterParameters.Insert("SelectedAgreement",   Object.Terms);
		
		PurchaseConditions =
			PurchasesServer.GetDefaultPurchaseTerms(
				Object.Partner,
				FilterParameters);
	EndIf;
	
	If ValueIsFilled(PurchaseConditions) Then
		If Object.Terms <> PurchaseConditions.Terms
			And ValueIsFilled(PurchaseConditions.Terms) Then
			
			Object.Terms = PurchaseConditions.Terms;
			FillInAccordingToTermsOfPurchase(Object, PurchaseConditions);
		Else
			Object.Terms = PurchaseConditions.Terms;
		EndIf;
	Else
		Counterparty = Object.Counterparty;
		PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(Object.Partner, Object.Counterparty);
		BankAccount = ?(Counterparty = Object.Counterparty, Object.CounterpartyBankAccount, Undefined);
		ParametersOfAccount = CashServer.ParametersForFillingInCounterpartySBankAccount(Object.Counterparty);
		Object.CounterpartyBankAccount = CashServer.GetDefaultCounterpartyBankAccount(
			ParametersOfAccount, BankAccount);
		Object.Terms = Undefined;
	EndIf;
	
	If GetFunctionalOption("UseCostAccountingByLinesOfBusiness") Then
		LinesOfBusinessServer.FillInDefaultDirection(Object.LineOfBusiness, Object.Terms, Object.Contract);
	EndIf;
	
EndProcedure

// Returns:
// 	Structure - Contains:
// * LineOfBusiness - CatalogRef.LinesOfBusiness -
// * Goods - TabularSection, Undefined -
// * PriceIncludesVAT - Boolean -
// * CurrencyOfReceipt - CatalogRef.Currencies -
// * DateOfReceipt - Undefined -
// * VendorSCounterparty - CatalogRef.Counterparties -
// * Vendor - CatalogRef.Partners -
// * Organization - CatalogRef.Companies -
// * CompanyBankAccount - CatalogRef.CompaniesBankAccounts -
Function FillingStructure() Export
	
	Result = New Structure;
	Result.Insert("Organization", Catalogs.Companies.EmptyRef());
	Result.Insert("CompanyBankAccount", Catalogs.CompaniesBankAccounts.EmptyRef());
	Result.Insert("Vendor", Catalogs.Partners.EmptyRef());
	Result.Insert("VendorSCounterparty", Catalogs.Counterparties.EmptyRef());
	Result.Insert("DateOfReceipt", Undefined);
	Result.Insert("CurrencyOfReceipt", Catalogs.Currencies.EmptyRef());
	Result.Insert("PriceIncludesVAT", False);
	Result.Insert("Goods", Undefined);
	Result.Insert("LineOfBusiness", Catalogs.LinesOfBusiness.EmptyRef());
	
	Return Result;
EndFunction

// Parameters:
// 	Object - DocumentObject.CCDImport - 
// 	Data - See FillingStructure
Procedure FillInAccordingToData(Object, Data) Export
	FillPropertyValues(Object, Data);
	FillByDefault(Object);
	If Data.Goods<>Undefined Then
		If False <> Data.PriceIncludesVAT Then
			For Each OwnGoods In Data.Goods Do // in the Amount field we will get the amount without VAT
				PriceManagementSystem.RecalculateAmountsInRowWithVAT(OwnGoods, False, False, False);
			EndDo;
		EndIf;
		If Object.Currency <> Data.CurrencyOfReceipt And ValueIsFilled(Data.CurrencyOfReceipt) Then
			DocumentDate = ?(ValueIsFilled(Object.Date),Object.Date,CurrentSessionDate());
			LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
			CoursesAreOld = ProcessingOfExchangeRatesTM.GetCurrencyRate(Data.CurrencyOfReceipt, DocumentDate, LocalAccountingCurrency);
			CoursesAreNew  = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, DocumentDate, LocalAccountingCurrency);
			PriceManagementSystem.ConvertTabularAmountsToCurrency(
				Data.Goods, False, Data.CurrencyOfReceipt, Object.Currency, CoursesAreOld, CoursesAreNew);
		ElsIf Data.Goods.Columns.Find("CurrencyOfReceipt") <> Undefined
			And Data.Goods.Columns.Find("DateOfReceipt") <> Undefined Then
			
			BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
			For Each OwnGoods In Data.Goods Do
				If ValueIsFilled(OwnGoods.DateOfReceipt)
					And ValueIsFilled(OwnGoods.CurrencyOfReceipt) Then
					NewCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(Object.Currency, OwnGoods.DateOfReceipt, BaseCurrency);
					OldCurrencyRate = ProcessingOfExchangeRatesTM.GetCurrencyRate(OwnGoods.CurrencyOfReceipt, OwnGoods.DateOfReceipt, BaseCurrency);
					
					OwnGoods.AmountIncludingVAT = ProcessingOfExchangeRatesTMClientServer.ConvertAtRate(
						OwnGoods.AmountIncludingVAT,
						OldCurrencyRate,
						NewCurrencyRate);
						
					PriceManagementSystem.RecalculateAmountsInRowWithVAT(
						OwnGoods,
						False,
						False,
						False);
				EndIf;
			EndDo;
		EndIf;
		
		For Each BufferElement In Data.Goods Do
			OwnGoods = Object.Goods.Add();
			FillPropertyValues(OwnGoods, BufferElement,
				"Products, Characteristic, Series, Warehouse, Purpose, InventoryOwnerAttribute, Package, Count, NumberOfPackages, DocumentInflow, PurchaseForActivity");
			OwnGoods.BusinessOperation = BufferElement.BusinessOperation;
			OwnGoods.CustomsValue = BufferElement.Sum;
		EndDo;
		
		StructureOfActions = New Structure;
		If ExcisableGoodsAccounting.ImportOfExcisableItemsIsUsed(Object.Organization, Object.Date) Then
			ParametersForRecalculationOfExciseTaxAmount =
				BatchProcessingOfTablePartClientServer.ParametersForRecalculationOfExciseTaxAmount(Object, True);
			StructureOfActions.Insert("RecalculateExciseTaxAmount", ParametersForRecalculationOfExciseTaxAmount);
		EndIf;
		
		If GetFunctionalOption("UseSectionsOfCustomsDeclarationImport") Then
			If ValueIsFilled(StructureOfActions) Then
				BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
			EndIf;
			Section = Object.Sections.Add();
			Section.SectionNumber = 1;
			For Each LineProducts_ In Object.Goods Do
				LineProducts_.SectionNumber = Section.SectionNumber;
				Section.CustomsValue = Section.CustomsValue + LineProducts_.CustomsValue;
				Section.ExciseTaxAmount = Section.ExciseTaxAmount + LineProducts_.ExciseTaxAmount;
			EndDo;
		Else
			// We will get the VAT rate from the nomenclature and calculate the VAT amount.
			VATAccountingSettings = VATAccountingERP.AccountingSettings();
			ParametersFillInVATRate = BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object);
			ParametersFillInVATRate.VATTaxation = VATAccountingSettings.MainActivityVATProcurement;
			StructureOfActions.Insert("FillInVATRate", ParametersFillInVATRate);
			CachedValues = New Structure;
			BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValues);
			
			For Each String In Object.Goods Do
				String.VATAmount =
					PriceManagementSystemClientServer.CalculateVATAmount(
						String.CustomsValue + String.DutyAmount + String.ExciseTaxAmount,
						String.VATRate,
						False);
			EndDo;
			
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Other

// Returns:
// 	Array - an array of operations, agreements and contracts for which are available for use.
Function OperationsOfSelectionOfAgreementsContracts() Export
	Operations = New Array;
	Operations.Add(Enums.BusinessTransactions.PurchaseFromSupplier);
	Return Operations;
EndFunction

#EndRegion

#Region CreatingHyperlinkInPurchaseLog

Function CreateHyperlinkToDesign(Parameters) Export
	
	ThereIsRightToReadReceiptsOfGoodsServices = AccessRight("Read", Metadata.Documents.VendorInvoice);
	If Not (AccessRight("Read", Metadata.AccumulationRegisters.GoodsForRegistrationOfImportDocuments)
		And ThereIsRightToReadReceiptsOfGoodsServices) Then
		Return Undefined;
	EndIf;
	
	Parameters.Insert("CompanyArray",?(ValueIsFilled(Parameters.Organization), 
											TMCommonUseClientServer.Array(Parameters.Organization),
											Undefined));
	Parameters.Insert("NoPeriodLimit");
	
	HyperlinkText = NStr("vi = 'TKHQ nhập khẩu';
						|ru = 'ТД импорт';
						|en = 'Customs declaration import'; fa = 'Customs declaration import';
						|it = 'TD Import';
						|pl = 'Deklaracja celna import';
						|tr = 'Gümrük İthalat Beyannamesi'");
	
	If ThereAreInvoicesForRegistration(Parameters) Then
		Return New FormattedString(HyperlinkText,,,,
			FormNameWorkplaceCustomsDeclarationImport());
	Else
		Return New FormattedString(HyperlinkText,,StyleColors.EmptyTableField,,
			FormNameWorkplaceCustomsDeclarationImport());
	EndIf;
	
EndFunction

#EndRegion

Function FormNameWorkplaceCustomsDeclarationImport() Export
	
	Return "Document.CCDImport.Form.Workplace";
	
EndFunction

#EndRegion

#EndIf
