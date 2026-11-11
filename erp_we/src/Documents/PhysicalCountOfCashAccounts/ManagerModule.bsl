#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "EmployeeResponsible");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CashBook", Parameters);
	
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	PhysicalCountOfCashAccountsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.PhysicalCountOfCashAccounts") Then
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
		QueryTextOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextCashAccountBalance(Query, QueryTexts, Registers);
		QueryTextRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		PhysicalCountOfCashAccountsLocalization.AddRequestTexts(Query,
																							QueryTexts,
																							Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	PhysicalCountOfCashAccountsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the "cash Inventory" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.PhysicalCountOfCashAccounts) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.PhysicalCountOfCashAccounts.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.PhysicalCountOfCashAccounts);
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
	
	
	
	PhysicalCountOfCashAccountsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return PhysicalCountOfCashAccountsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return PhysicalCountOfCashAccountsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for selecting articles in the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters() Export
	
	ChoiceParametersArray = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.CashAccounts";
	ChoiceParameters.AssetRef = "IncomeAndExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("CashAccountsIncomeAndExpenseItem");
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("CashAccountsDimensionOfExpenses");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("CashAccountsDimensionOfRevenue");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
		
	Return ChoiceParametersArray;
	
EndFunction

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("IncomeItem");
	ArrayOfAllProps.Add("DimensionOfRevenue");
	ArrayOfAllProps.Add("ExpenseItem");
	ArrayOfAllProps.Add("DimensionOfExpenses");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.RecordSurplusDuringCashCollection Then
		
		ArrayOfOperationDetails.Add("IncomeItem");
		ArrayOfOperationDetails.Add("DimensionOfRevenue");
	
	ElsIf BusinessOperation = Enums.BusinessTransactions.RecordShortageOnCashCollection Then
		
		ArrayOfOperationDetails.Add("ExpenseItem");
		ArrayOfOperationDetails.Add("DimensionOfExpenses");
		
	EndIf;
	
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
	|	ValueAllowed(Organization)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.PhysicalCountOfCashAccounts";
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
			QueryText, FullDocumentName, "", False);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, "");
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                          AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.CashBook                 AS CashBook,
	|	
	|	DocumentData.ActualTotalAmount             AS DocumentAmount,
	|	DocumentData.ActualTotalAmount             AS ActualTotalAmount,
	|	DocumentData.EmployeeResponsible                 AS EmployeeResponsible,
	|	DocumentData.Author                         AS Author,
	|	DocumentData.Number                         AS Number,
	|	DocumentData.Comment                   AS Comment,
	|	DocumentData.DeletionMark               AS DeletionMark,
	|	DocumentData.Patch                   AS Patch,
	|	DocumentData.ReversedDocument          AS ReversedDocument,
	|	DocumentData.CorrectedDocument          AS CorrectedDocument,
	|	DocumentData.Posted                      AS Posted,
	|	DocumentData.CorrectedDocument.Date     AS AdjustmentPeriod_
	|FROM
	|	Document.PhysicalCountOfCashAccounts AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	Query.SetParameter("SettingUpSurplusBusinessOperation", 		Catalogs.BusinessTransactionsSettings.RecordSurplusDuringCashAccountAudit);
	Query.SetParameter("SettingUpShortageBusinessOperation", 	Catalogs.BusinessTransactionsSettings.RecordShortageDuringCashAccountAudit);
	
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",           Common.MetadataObjectID("Document.PhysicalCountOfCashAccounts"));
	Values.Insert("ManagementAccountingCurrency",        Constants.ManagementAccountingCurrency.Get());
	Values.Insert("BusinessOperationSurplus",      Enums.BusinessTransactions.RecordSurplusDuringCashAccountAudit);
	Values.Insert("EconomicOperationShortage",    Enums.BusinessTransactions.RecordShortageDuringCashAccountAudit);
	
	If Attributes <> Undefined Then
		Values.Insert("NumberForPrinting",                         ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTTManExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesMan"; 
	
	QueryText =
	"SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * ManSExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * ManSExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TTExchangeRatesMan
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &ManagementAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS ManSExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND ManSExchangeRate.CourseNumerator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTLocalExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRatesLocal"; 
	
	QueryText =
	"SELECT
	|	CurrencyExchangeRate.Currency AS Currency,
	|	CurrencyExchangeRate.CourseNumerator * LocalCurrencyExchangeRate.CourseDenominator / (CurrencyExchangeRate.CourseDenominator * LocalCurrencyExchangeRate.CourseNumerator) AS ConversionFactor_
	|INTO TTExchangeRatesLocal
	|FROM InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency = &LocalAccountingCurrency) AS CurrencyExchangeRate
	|	INNER JOIN InformationRegister.RelativeExchangeRates.SliceLast(&Period, Currency = &LocalAccountingCurrency AND BaseCurrency = &LocalAccountingCurrency) AS LocalCurrencyExchangeRate
	|	ON (TRUE)
	|WHERE
	|	CurrencyExchangeRate.CourseDenominator <> 0
	|	AND LocalCurrencyExchangeRate.CourseNumerator <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTCashAccounts(Query, QueryTexts)
	
	RegisterName = "CheckoutTT";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesMan", QueryTexts) Then
		QueryTextTTManExchangeRates(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRatesLocal", QueryTexts) Then
		QueryTextTTLocalExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	CashAccountsTable.Ref AS Ref,
	|	CashAccountsTable.LineNumber AS LineNumber,
	|	CashAccountsTable.RowID AS RowID,
	|	CashAccountsTable.CashAccount AS CashAccount,
	|	CashAccountsTable.CashAccount.CashCurrency AS Currency,
	|	CashAccountsTable.DiscrepancyAmount AS DiscrepancyAmount,
	|	CashAccountsTable.DiscrepancyAmount * ISNULL(TableManExchangeRates.ConversionFactor_, 0) AS AmountOfManDiscrepancy,
	|	CashAccountsTable.DiscrepancyAmount * ISNULL(TableLocalExchangeRates.ConversionFactor_, 0) AS SumOfLocalDivergence,
	|	CashAccountsTable.CashFlowItem AS CashFlowItem,
	|	CashAccountsTable.CashAccount.Department AS Department,
	|	CashAccountsTable.Department AS IncomeExpenseBusinessUnit,
	|	CashAccountsTable.CashAccount.LineOfBusiness AS LineOfBusiness,
	|	CashAccountsTable.IncomeAndExpenseItem AS IncomeAndExpenseItem,
	|	CashAccountsTable.DimensionOfRevenue AS DimensionOfRevenue,
	|	CashAccountsTable.DimensionOfExpenses AS DimensionOfExpenses
	|INTO CheckoutTT
	|FROM
	|	Document.PhysicalCountOfCashAccounts.CashAccounts AS CashAccountsTable
	|		LEFT JOIN TTExchangeRatesMan AS TableManExchangeRates
	|		ON (TableManExchangeRates.Currency = CashAccountsTable.CashAccount.CashCurrency)
	|		LEFT JOIN TTExchangeRatesLocal AS TableLocalExchangeRates
	|		ON (TableLocalExchangeRates.Currency = CashAccountsTable.CashAccount.CashCurrency)
	|WHERE
	|	CashAccountsTable.Ref = &Ref
	|	AND CashAccountsTable.DiscrepancyAmount <> 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("CheckoutTT", QueryTexts) Then
		QueryTextTTCashAccounts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                      AS Period,
	|	
	|	&Organization                                 AS Organization,
	|	
	|	CheckoutTT.IncomeExpenseBusinessUnit         AS Department,
	|	CheckoutTT.LineOfBusiness              AS LineOfBusiness,
	|	CheckoutTT.IncomeAndExpenseItem                AS IncomeItem,
	|	CheckoutTT.DimensionOfRevenue                     AS DimensionOfRevenue,
	|	
	|	CheckoutTT.AmountOfManDiscrepancy                  AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN CheckoutTT.AmountOfManDiscrepancy
	|		ELSE 0
	|	END                                        AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN CheckoutTT.SumOfLocalDivergence
	|		ELSE 0
	|	END                                        AS SumCompl,
	|	
	|	&BusinessOperationSurplus                AS BusinessOperation,
	|	
	|	CheckoutTT.RowID                  AS FinRecordID,
	|	&SettingUpSurplusBusinessOperation       AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_                         AS AdjustmentPeriod_
	|	
	|FROM
	|	CheckoutTT AS CheckoutTT
	|	
	|WHERE
	|	CheckoutTT.DiscrepancyAmount > 0";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("CheckoutTT", QueryTexts) Then
		QueryTextTTCashAccounts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	&Period                                      AS Period,
	|	&Organization                                 AS Organization,
	|	&AdjustmentPeriod_                         AS VariancePeriod,
	|	CheckoutTT.IncomeExpenseBusinessUnit         AS Department,
	|	CheckoutTT.LineOfBusiness              AS LineOfBusiness,
	|	CheckoutTT.IncomeAndExpenseItem                AS ExpenseItem,
	|	CheckoutTT.DimensionOfExpenses                    AS DimensionOfExpenses,
	|	UNDEFINED                                 AS VATActivityType,
	|	
	|	-CheckoutTT.AmountOfManDiscrepancy                 AS AmountIncludingVAT,
	|	-CheckoutTT.AmountOfManDiscrepancy                 AS AmountExcludingVAT,
	|	-CheckoutTT.AmountOfManDiscrepancy                 AS AmountExcludingVATMan,
	|
	|	-CheckoutTT.SumOfLocalDivergence                AS AmountIncludingVATCompl,
	|	-CheckoutTT.SumOfLocalDivergence                AS AmountExcludingVATCompl,
	|	0                                            AS PermanentDifference,
	|	0                                            AS CostTD,
	|	&EconomicOperationShortage              AS BusinessOperation,
	|	UNDEFINED                                 AS ItemsLocationAttributes,
	|	
	|	CheckoutTT.RowID                  AS FinRecordID,
	|	&SettingUpShortageBusinessOperation     AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	CheckoutTT AS CheckoutTT
	|WHERE
	|	CheckoutTT.DiscrepancyAmount < 0";
	
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

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("CheckoutTT", QueryTexts) Then
		QueryTextTTCashAccounts(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	&Period                                                           AS Period,
	|	&Organization                                                      AS Organization,
	|	CheckoutTT.IncomeExpenseBusinessUnit                              AS Department,
	|	&Ref                                                           AS ExpenseReceiptDocument,
	|	CheckoutTT.IncomeAndExpenseItem                                     AS ExpenseItem,
	|	CheckoutTT.DimensionOfExpenses                                         AS DimensionOfExpenses,
	|	UNDEFINED                                                      AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)       AS LotVendorAttributes,
	|	CheckoutTT.LineOfBusiness                                   AS LineOfBusiness,
	|	UNDEFINED                                                      AS ItemsLocationAttributes,
	|	UNDEFINED                                                      AS VATActivityType,
	|	
	|	-CheckoutTT.SumOfLocalDivergence                                     AS Cost,
	|	-CheckoutTT.SumOfLocalDivergence                                     AS CostExcludingVAT,
	|	0                                                                 AS VATManag,
	|	-CheckoutTT.SumOfLocalDivergence                                     AS LocalCost,
	|	0                                                                 AS PermanentDifference,
	|	0                                                                 AS CostTD,
	|	0                                                                 AS VATLocal,
	|	&EconomicOperationShortage                                   AS BusinessOperation,
	|	
	|	CheckoutTT.RowID                                       AS FinRecordID,
	|	&SettingUpShortageBusinessOperation                          AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	CheckoutTT AS CheckoutTT
	|WHERE
	|	CheckoutTT.DiscrepancyAmount < 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
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
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextCashAccountBalance(Query, QueryTexts, Registers)
	
	RegisterName = "CashAccountBalance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("CheckoutTT", QueryTexts) Then
		QueryTextTTCashAccounts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		VALUE(AccumulationRecordType.Receipt)
	|	ELSE
	|		VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Period                                           AS Period,
	|	
	|	&Organization                                      AS Organization,
	|	CheckoutTT.CashAccount                                     AS CashAccount,
	|	
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.DiscrepancyAmount
	|	ELSE
	|		-CheckoutTT.DiscrepancyAmount
	|	END AS Sum,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.AmountOfManDiscrepancy
	|	ELSE
	|		-CheckoutTT.AmountOfManDiscrepancy
	|	END AS SumMan,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.SumOfLocalDivergence
	|	ELSE
	|		-CheckoutTT.SumOfLocalDivergence
	|	END AS SumCompl,
	|	
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		&BusinessOperationSurplus
	|	ELSE
	|		&EconomicOperationShortage
	|	END AS BusinessOperation,
	|	CheckoutTT.CashFlowItem             AS CashFlowItem,
	|	
	|	CheckoutTT.RowID AS FinRecordID,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		&SettingUpSurplusBusinessOperation
	|	ELSE
	|		&SettingUpShortageBusinessOperation
	|	END AS BusinessTransactionSetting
	|	
	|FROM
	|	CheckoutTT AS CheckoutTT";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCashIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("CheckoutTT", QueryTexts) Then
		QueryTextTTCashAccounts(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period                                             AS Period,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		&BusinessOperationSurplus
	|	ELSE
	|		&EconomicOperationShortage
	|	END AS BusinessOperation,
	|	&Organization AS Organization,
	|	CheckoutTT.Department                               AS Department,
	|	CheckoutTT.LineOfBusiness                     AS LineOfBusinessCash,
	|	CheckoutTT.IncomeExpenseBusinessUnit                AS IncomeExpenseBusinessUnit,
	|
	|	CheckoutTT.CashAccount                                       AS Cash,
	|	VALUE(Enum.CashTypes.CashPayment) AS CashType,
	|	CheckoutTT.CashFlowItem               AS CashFlowItem,
	|	CheckoutTT.Currency                                      AS Currency,
	|
	|	CheckoutTT.LineOfBusiness                     AS LineOfBusinessItems,
	|	CheckoutTT.IncomeAndExpenseItem                       AS IncomeAndExpenseItem,
	|	CheckoutTT.DimensionOfRevenue                            AS DimensionOfRevenue,
	|	CheckoutTT.DimensionOfExpenses                           AS DimensionOfExpenses,
	|
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.AmountOfManDiscrepancy
	|	ELSE
	|		-CheckoutTT.AmountOfManDiscrepancy
	|	END AS Sum,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.SumOfLocalDivergence
	|	ELSE
	|		-CheckoutTT.SumOfLocalDivergence
	|	END AS SumCompl,
	|	CASE WHEN CheckoutTT.DiscrepancyAmount > 0 THEN
	|		CheckoutTT.DiscrepancyAmount
	|	ELSE
	|		-CheckoutTT.DiscrepancyAmount
	|	END AS AmountInCurrency,
	|
	|	CheckoutTT.CashAccount                                       AS SourceOfCashFinancialAccountingGroup,
	|	CheckoutTT.IncomeAndExpenseItem                       AS SourceOfIncomeExpensesFinancialAccountingGroup
	|	
	|FROM
	|	CheckoutTT AS CheckoutTT";
	
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities();
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""CashAccounts"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.CashAccount.CashCurrency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	CASE
	|		WHEN DocumentTable.DiscrepancyAmount > 0
	|			THEN DocumentTable.DiscrepancyAmount
	|		ELSE - DocumentTable.DiscrepancyAmount
	|	END AS AmountExcludingVAT,
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
	|	Document.PhysicalCountOfCashAccounts.CashAccounts AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure
Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&EconomicOperationShortage         AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS Partner,
	|	UNDEFINED                          AS StorageLocation,
	|	UNDEFINED                            AS Counterparty,
	|	UNDEFINED                            AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	
	|	&Number                                  AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&ActualTotalAmount                      AS Sum,
	|	UNDEFINED                            AS Currency,
	|	UNDEFINED                            AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	PhysicalCountOfCashAccountsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	PhysicalCountOfCashAccountsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters)
	
EndProcedure

#EndRegion

// Defines the composition of documents and business operations that are available for display in the workplace.
//
// Parameters:
//  BusinessTransactionsAndDocuments	 - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
// 
// Returns:
//   - ValueTable - Table of values with columns:
//     * BusinessOperation					 - EnumRef.BusinessTransactions
//     * MetadataObjectID			 - CatalogRef.MetadataObjectIDs
//     * Filter									 - Boolean
//     * DocumentPresentation					 - String
//     * FullDocumentName						 - String
//     * Invoice								 - Boolean
//     * ReferenceIsUsed				 - Boolean
//     * StatusesAreUsed					 - Boolean
//     * BySeveralOrders					 - Boolean
//     * GoodsReceiptNoteIsImpossible				 - Boolean
//     * DivideDocumentsByDepartment		 - Boolean
//     * InvoiceFullName						 - String
//     * PurposeUseKey			 - String
//     * AccessRightInsert					 - Boolean
//     * AccessRightUpdate					 - Boolean
//     * WorkplaceTitle					 - String
//     * NamesOfElementsWithManagedVisibility	 - String
//     * WorkplaceItemNames			 - String
//     * NamesOfDisplayedElements				 - String
//     * HyperlinkCalculationManagerForRegistration	 - String
//
//
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments) Export
	
	FullDocumentName = Metadata.Documents.PhysicalCountOfCashAccounts.FullName();
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	String.MetadataObjectID = Common.MetadataObjectID(FullDocumentName);
	String.FullDocumentName = FullDocumentName;
	String.PurposeUseKey = "Inventory_ cash ofmoney facilities";
	String.WorkplaceTitle = NStr("vi = 'Kiểm kê tiền mặt';
								|ru = 'Инвентаризация наличных денежных средств';
								|en = 'Petty cash audit'; fa = 'حسابرسی صندوق تنخواه';
								|it = 'Inventario del contante disponibile';
								|pl = 'Inwentaryzacja gotówki';
								|tr = 'Nakit varlıkların fiziksel stok sayımı'");
	String.Order = 1;
	String.AddButtonCreate = True;
	String.AccessRightInsert = AccessRight("Insert", Metadata.Documents.PhysicalCountOfCashAccounts);;
	String.AccessRightUpdate = AccessRight("Update", Metadata.Documents.PhysicalCountOfCashAccounts);;
	String.Filter = True;
	
	Return BusinessTransactionsAndDocuments;
	
EndFunction

#EndRegion

#EndIf
