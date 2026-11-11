#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department");
	
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
	DocumentMechanisms.Add("LossAllowance");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ARAPAdjustmentFinancialInstrumentsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  - ValueList - contains the request texts and their names, returned if the property gets the request texts of the parameter
//  					Dopparameters have the value of True.
//  - Structure - contains data tables to load into registers.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ARAPAdjustmentFinancialInstruments") Then
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
		
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		QueryTextTableLossAllowance(Query, QueryTexts, Registers);
		
		ARAPAdjustmentFinancialInstrumentsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
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
	
	ARAPAdjustmentFinancialInstrumentsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "adjustment of debt on financial instruments".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow - a data string defining the parameters of the input command based on.
//  - Undefined - if there is no right to create a document "Adjustment of debt on financial instruments".
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ARAPAdjustmentFinancialInstruments) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName();
		CreateBasedOnCommand.Presentation =
			TMCommonUse.ObjectPresentation(Metadata.Documents.ARAPAdjustmentFinancialInstruments);
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
	
	ARAPAdjustmentFinancialInstrumentsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The function generates the request text to reflect the document in regl. accounting.
//
// Returns:
// 		String - query text.
//
Function TextOfReflectionInLocalAccounting() Export

	Return ARAPAdjustmentFinancialInstrumentsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
// 		String - query text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ARAPAdjustmentFinancialInstrumentsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

// Returns parameters for setting up accounting accounts in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 	
// Returns:
// 	Array of See GLAccountSettingsServer.SetupParameters
//
Function AccountingAccountSettings_(BusinessOperation) Export
	
	ParametersArray = New Array();
	
	#Region SettingUpAccountToReflectDebitingExpenses
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object";
	
	If BusinessOperation = Enums.BusinessTransactions.ARWriteOff 
		Or BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance Then
		SetupParameters.ArticleType = "ExpenseItemItemType";
		SetupParameters.AssetAndLiabilityItem = "ExpenseItem";
	Else
		SetupParameters.ArticleType = "IncomeItemItemType";
		SetupParameters.AssetAndLiabilityItem = "IncomeItem";
		
	EndIf;
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("PresentationOfTheCostReflectionInTheReglAccounting");
	SetupParameters.FormItems.Add("PresentationOfTheIncomeReflectionInTheReglAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ExpenseItemItemType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	WriteOffAtExpenseOfReserve = (BusinessOperation = Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance);
	ChoiceParameters.AvailabilityByOperation = 
			(BusinessOperation = Enums.BusinessTransactions.ARWriteOff 
					Or WriteOffAtExpenseOfReserve);
	
	#Region AssetsLiabilitiesDimension
	If ChoiceParameters.AvailabilityByOperation Then
		ChoiceParameters.SelectingItemOfAssetsLiabilities = Not WriteOffAtExpenseOfReserve;
		ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
		ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("ExpensesAssetsLiabilitiesDimension");
	EndIf;
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
	
	#Region IncomeItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "IncomeItem";
	ChoiceParameters.ArticleType = "IncomeItemItemType";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeItem");
	
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.APWriteOff);
	
	#Region AssetsLiabilitiesDimension
	If ChoiceParameters.AvailabilityByOperation Then
		ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
		ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
		ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("IncomeAssetLiabilityAnalysis");
	EndIf;
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = True;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("DimensionOfRevenue");
	#EndRegion
	
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
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
	|	AND ValueAllowed(Partner)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

// Defines the properties of form fields depending on the data
//
// Returns:
//    ValueTable - table with columns Fields, Condition, Properties.
//
Function FormFieldSettings() Export
	
	Finances = FinancialReportingServer;
	Settings = CashServer.InitializeFormFieldSettings();
	
	OtherAccountsReceivable = New Array;
	OtherAccountsReceivable.Add(Enums.BusinessTransactions.ARWriteOff);
	OtherAccountsReceivable.Add(Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance);
	
	Item = Settings.Add();
	Item.Fields.Add("ExpensesPage");
	Finances.NewFilter(Item.Condition, "BusinessOperation", OtherAccountsReceivable);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("RevenuePage");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.APWriteOff);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("Partner");
	Finances.NewFilter(Item.Condition, "BusinessOperation", OtherAccountsReceivable);
	Item.Properties.Insert("Title", NStr("vi = 'Người vay nợ';
										|ru = 'Дебитор';
										|en = 'Debtor'; fa = 'بدهکار';
										|it = 'Debitore';
										|pl = 'Dłużnik';
										|tr = 'Borçlu'"));
	
	Item = Settings.Add();
	Item.Fields.Add("Partner");
	Finances.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.APWriteOff);
	Item.Properties.Insert("Title", NStr("vi = 'Người cho vay';
										|ru = 'Кредитор';
										|en = 'Creditor'; fa = 'بستانکار';
										|it = 'Creditore';
										|pl = 'Wierzyciel';
										|tr = 'Alacaklı'"));
		
	Item = Settings.Add();
	Finances.NewFilter(Item.Condition, "More.ComplAccountingIsUsed", True);
	Item.Properties.Insert("Visible");
	
	// Settlement document
	Item = Settings.Add();
	Item.Fields.Add("Debt_ARAPDocument");
	Finances.NewFilter(Item.Condition, "ContractKind", Enums.ContractKindsOfFinancialInstruments.Lease, Type("DataCompositionFilterItem"), DataCompositionComparisonType.Equal);
	Item.Properties.Insert("Visible", True);
	Return Settings;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ARAPAdjustmentFinancialInstruments";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting",        """""");
	RedefiningParameterCalculation.Insert("ContractInformation", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
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
			QueryText, FullDocumentName, SynonymForDocumentTable, RequestHasSource, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable, RedefiningParameterCalculation);
	EndIf;

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date                                  AS Period,
	|	DocumentData.Number                                 AS Number,
	|	DocumentData.Organization                           AS Organization,
	|	DocumentData.Partner                               AS Partner,
	|	DocumentData.Counterparty                            AS Counterparty,
	|	DocumentData.Contract                               AS Contract,
	|	DocumentData.Contract.LineOfBusiness       AS LineOfBusiness,
	|	DocumentData.ARAPCurrency                  AS ARAPCurrency,
	|	DocumentData.DocumentAmount                        AS DocumentAmount,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	CASE WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.IncomeItems THEN
	|		DocumentData.IncomeItem                
	|	ELSE UNDEFINED
	|	END                                                 AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                      AS DimensionOfRevenue,
	|	CASE WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.ExpenseItems THEN
	|		DocumentData.ExpenseItem                
	|	ELSE UNDEFINED
	|	END                                                 AS ExpenseItem,
	|	ISNULL(ExpenseItems.CostAllocationOptionLocal, UNDEFINED) AS CostAllocationOptionLocal,
	|	ISNULL(ExpenseItems.VATAssetTaxClass, UNDEFINED) AS TypeOfValueOfVATExpenses,
	|	DocumentData.DimensionOfExpenses                     AS DimensionOfExpenses,
	|	CASE
	|		WHEN DocumentData.ExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems THEN
	|			DocumentData.ExpenseItem
	|		WHEN DocumentData.IncomeItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems THEN
	|			DocumentData.IncomeItem
	|		ELSE UNDEFINED
	|	END                                                 AS AssetAndLiabilityItem,
	|	DocumentData.AssetsLiabilitiesDimension              AS AssetsLiabilitiesDimension,
	|	DocumentData.Department                         AS Department,
	|	DocumentData.BusinessOperation                 AS BusinessOperation,
	|	DocumentData.EmployeeResponsible                         AS EmployeeResponsible,
	|	DocumentData.Comment                           AS Comment,
	|	DocumentData.GLAccountSettings                  AS GLAccountSettings,
	|	DocumentData.Posted                              AS Posted,
	|	DocumentData.DeletionMark                       AS DeletionMark,
	|	DocumentData.PointInTime                         AS PointInTime,
	|	DocumentData.Patch                           AS Patch,
	|	DocumentData.ReversedDocument                  AS ReversedDocument,
	|	DocumentData.CorrectedDocument                  AS CorrectedDocument,
	|	DocumentData.Ref                                AS Ref,
	|	DocumentData.Author                                 AS Author,
	|	BusinessTransactionsSettings.Ref                 AS BusinessTransactionSetting,
	|	DocumentData.CorrectedDocument.Date             AS AdjustmentPeriod_
	|FROM
	|	Document.ARAPAdjustmentFinancialInstruments AS DocumentData
	|	LEFT JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		DocumentData.ExpenseItem = ExpenseItems.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|	
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
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",
		Common.MetadataObjectID("Document.ARAPAdjustmentFinancialInstruments"));
	Values.Insert("ManagementAccountingCurrency",            Constants.ManagementAccountingCurrency.Get());
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities", GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	
	If Attributes <> Undefined Then
		
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.ARAPCurrency,
			Undefined,
			Attributes.Period,
			Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.TempTablesManager = Query.TempTablesManager;
	QueryAnalyst.SetParameter("Ref",                    Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization",               Query.Parameters.Organization);
	QueryAnalyst.SetParameter("Counterparty",                Query.Parameters.Counterparty);
	QueryAnalyst.SetParameter("Partner",                   Query.Parameters.Partner);
	
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	&Organization                    AS Organization,
	|	&Partner                        AS Partner,
	|	&Counterparty                     AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.ARAPAdjustmentFinancialInstruments AS DocumentData
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners  AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		&Organization = RegisterAccountingAnalyticsForPartners.Organization
	|		AND &Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND &Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND RegisterAccountingAnalyticsForPartners.DimensionKey IS NULL
	|";
	
	QueryResult = QueryAnalyst.Execute();
	Selection = QueryResult.Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query) Export
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Query.Parameters.ARAPCurrency,
	                                                                         Undefined,
	                                                                         Query.Parameters.Period,
	                                                                         Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Function QueryTextTemporaryDebtTable(Query, QueryTexts) Export
	
	TempTableName = "Table1_";
	
	QueryText = "
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	Debt_.AmountType AS AmountType,
	|	Debt_.Sum AS Sum,
	|	Debt_.RowID AS RowID,
	|	CASE
	|		WHEN &ARAPCurrency = &LocalAccountingCurrency THEN
	|			Debt_.Sum
	|		ELSE
	|			CAST(Debt_.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|	END AS SumCompl,
	|	CASE
	|		WHEN &ARAPCurrency = &ManagementAccountingCurrency THEN
	|			Debt_.Sum
	|		ELSE
	|			CAST(Debt_.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	END AS SumMan,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATTaxation
	|	, Debt_.ARAPDocument AS ARAPDocument
	|INTO Table1_
	|FROM
	|	Document.ARAPAdjustmentFinancialInstruments.Debt_ AS Debt_
	|WHERE
	|	Debt_.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, TempTableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)

	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("BalancesOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	QueryText = "
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	&Contract AS Contract,
	|	Debt_.AmountType AS AmountType,
	|	&ARAPCurrency AS Currency,
	|	
	|	Debt_.Sum - ISNULL(ReserveBalances.Sum, 0) AS Sum,
	|	Debt_.SumMan - ISNULL(ReserveBalances.SumMan, 0) AS SumMan,
	|	Debt_.SumCompl - ISNULL(ReserveBalances.SumCompl, 0) AS SumCompl,
	|	
	|	VALUE(Enum.BusinessTransactions.ARWriteOff) AS BusinessOperation,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	, Debt_.ARAPDocument AS ARAPDocument,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.EmptyRef)
	|	END AS ScheduleType,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment) THEN
	|			CASE
	|				WHEN &IncomeItem <> UNDEFINED
	|						AND &IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) THEN &IncomeItem
	|				WHEN &ExpenseItem <> UNDEFINED 
	|						AND &ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN &ExpenseItem
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END AS DimensionItem
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		&Organization = RegisterAccountingAnalyticsForPartners.Organization
	|		AND &Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND &Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|	
	|	LEFT JOIN
	|		BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON
	|		Debt_.RowID = ReserveBalances.RowID
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|	
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ARWriteOff),
	|		VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|
	|UNION ALL
	|
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	&Contract AS Contract,
	|	Debt_.AmountType AS AmountType,
	|	&ARAPCurrency AS Currency,
	|	
	|	ReserveBalances.Sum AS Sum,
	|	ReserveBalances.SumMan AS SumMan,
	|	ReserveBalances.SumCompl AS SumCompl,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	, Debt_.ARAPDocument AS ARAPDocument,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.EmptyRef)
	|	END,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment) THEN
	|			CASE
	|				WHEN &IncomeItem <> UNDEFINED
	|						AND &IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) THEN &IncomeItem
	|				WHEN &ExpenseItem <> UNDEFINED 
	|						AND &ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN &ExpenseItem
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END AS DimensionItem
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		&Organization = RegisterAccountingAnalyticsForPartners.Organization
	|		AND &Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND &Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|	
	|	INNER JOIN
	|		BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON
	|		Debt_.RowID = ReserveBalances.RowID
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|
	|UNION ALL
	|
	|SELECT
	|	Debt_.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	RegisterAccountingAnalyticsForPartners.DimensionKey AS AccountingDimensionByPartners,
	|	&Contract AS Contract,
	|	Debt_.AmountType AS AmountType,
	|	&ARAPCurrency AS Currency,
	|	
	|	Debt_.Sum AS Sum,
	|	Debt_.SumMan AS SumMan,
	|	Debt_.SumCompl AS SumCompl,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	, Debt_.ARAPDocument AS ARAPDocument,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|			THEN VALUE(Enum.FinancialInstrumentScheduleTypes.Payments)
	|		ELSE VALUE(Enum.FinancialInstrumentScheduleTypes.EmptyRef)
	|	END,
	|	CASE
	|		WHEN Debt_.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment) THEN
	|			CASE
	|				WHEN &IncomeItem <> UNDEFINED
	|						AND &IncomeItem <> VALUE(ChartOfCharacteristicTypes.IncomeItems.EmptyRef) THEN &IncomeItem
	|				WHEN &ExpenseItem <> UNDEFINED 
	|						AND &ExpenseItem <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef) THEN &ExpenseItem
	|				ELSE UNDEFINED
	|			END
	|		ELSE UNDEFINED
	|	END AS DimensionItem
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|	LEFT JOIN
	|		InformationRegister.AccountingDimensionByPartners AS RegisterAccountingAnalyticsForPartners
	|	ON
	|		&Organization = RegisterAccountingAnalyticsForPartners.Organization
	|		AND &Partner = RegisterAccountingAnalyticsForPartners.Partner
	|		AND &Counterparty = RegisterAccountingAnalyticsForPartners.Counterparty
	|		AND VALUE(Catalog.CounterpartyContracts.EmptyRef) = RegisterAccountingAnalyticsForPartners.Contract
	|		AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = RegisterAccountingAnalyticsForPartners.LineOfBusiness
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|	
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	&IncomeItem AS IncomeItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	Debt_.SumMan AS Sum,
	|	CASE WHEN NOT &CompanyManagementAccounting
	|		THEN 0
	|		ELSE Debt_.SumMan
	|	END AS SumMan,
	|	CASE WHEN NOT &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|		THEN 0
	|		ELSE Debt_.SumCompl
	|	END AS SumCompl,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|	
	|FROM
	|	Table1_ AS Debt_
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND &IncomeItem <> UNDEFINED
	|
	|ORDER BY
	|	Debt_.LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("BalancesOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
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
	|	&LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) - ISNULL(ReserveBalances.SumMan, 0) AS AmountIncludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) - ISNULL(ReserveBalances.SumMan, 0) AS AmountExcludingVAT,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) - ISNULL(ReserveBalances.SumMan, 0) AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) - ISNULL(ReserveBalances.SumCompl, 0) AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) - ISNULL(ReserveBalances.SumCompl, 0) AS AmountExcludingVATCompl,
	|	-ISNULL(ReserveBalances.PermanentDifference, 0) AS PermanentDifference,
	|	-ISNULL(ReserveBalances.CostTD, 0) AS CostTD,
	|	VALUE(Enum.BusinessTransactions.ARWriteOff) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_ AS VariancePeriod
	|	
	|FROM
	|	Table1_ AS Debt_
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS AssetRef
	|		ON AssetRef.Ref = &ExpenseItem
	|	
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Amounts.Ref = &Ref
	|		AND Debt_.RowID = Amounts.RowID
	|
	|	LEFT JOIN
	|		BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON
	|		Debt_.RowID = ReserveBalances.RowID
	|		AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ARWriteOff),
	|		VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))
	|	AND &ExpenseItem <> UNDEFINED
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

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	#Region ARWriteOff
	ARWriteOff =
	"SELECT
	|	&Period                                 AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&AssetAndLiabilityItem                  AS AssetRef,
	|	CASE
	|		WHEN &AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &AssetsLiabilitiesDimension
	|	END                                   AS Dimension,
	|	Debt_.SumMan                  AS Sum
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ARWriteOff)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetAndLiabilityItem <> UNDEFINED
	|";
	#EndRegion

	#Region APWriteOff
	APWriteOff =
	"SELECT
	|	&Period                                 AS Period,
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	&LineOfBusiness                AS LineOfBusiness,
	|	&AssetAndLiabilityItem                  AS AssetRef,
	|	CASE
	|		WHEN &AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE &AssetsLiabilitiesDimension
	|	END                                   AS Dimension,
	|	Debt_.SumMan                  AS Sum
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetAndLiabilityItem <> UNDEFINED";
	#EndRegion
	
	QueryText = APWriteOff
		+ " UNION ALL " + ARWriteOff;
	
	QueryText = QueryText + "UNION ALL"
		+ AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	#Region ARWriteOff
	ARWriteOff =
	"SELECT
	|	&Period                   AS Period,
	|	&Organization              AS Organization,
	|	&Department            AS Department,
	|	&LineOfBusiness  AS LineOfBusiness,
	|	&AssetAndLiabilityItem    AS AssetRef,
	|	&AssetsLiabilitiesDimension AS Dimension,
	|	&GLAccountSettings     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	Debt_.SumCompl AS SumCompl,
	|	Debt_.SumMan  AS SumMan,
	|	Debt_.SumMan  AS AmountIncludingVAT,
	|	Debt_.SumMan  AS AmountExcludingVAT,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.ARWriteOff)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetAndLiabilityItem <> UNDEFINED
	|";
	#EndRegion

	#Region APWriteOff
	APWriteOff =
	"SELECT
	|	&Period                   AS Period,
	|	&Organization              AS Organization,
	|	&Department            AS Department,
	|	&LineOfBusiness  AS LineOfBusiness,
	|	&AssetAndLiabilityItem    AS AssetRef,
	|	&AssetsLiabilitiesDimension AS Dimension,
	|	&GLAccountSettings     AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	Debt_.SumCompl AS SumCompl,
	|	Debt_.SumMan  AS SumMan,
	|	Debt_.SumMan  AS AmountIncludingVAT,
	|	Debt_.SumMan  AS AmountExcludingVAT,
	|	
	|	Debt_.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|	AND &UseAccountingOfOtherAssetsAndLiabilities
	|	AND &AssetAndLiabilityItem <> UNDEFINED";
	#EndRegion
	
	QueryText = APWriteOff
		+ " UNION ALL " + ARWriteOff;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Debt_"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.ARAPCurrency AS DocumentCurrency,
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
	|	Document.ARAPAdjustmentFinancialInstruments.Debt_ AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);
	
EndProcedure

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
#Region APWriteOff
	APWriteOff = "
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN &AssetAndLiabilityItem <> UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE &IncomeItem
	|	END AS IncomeAndExpenseItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	UNDEFINED AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	Debt_.SumMan AS Sum,
	|	0 AS AmountExcludingVAT,
	|	Debt_.SumCompl AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&ARAPCurrency AS Currency,
	|	Debt_.Sum AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	Debt_.Sum AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	&Contract AS SourceOfARAPFinancialAccountingGroup,
	|	Debt_.RowID AS FinRecordID
	|FROM
	|	Table1_ AS Debt_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.APWriteOff)
	|";
#EndRegion

#Region ARWriteOff
	ARWriteOff =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.ARWriteOff) AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS CounterpartyLineOfBusiness,
	|	
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	
	|	&LineOfBusiness AS LineOfBusinessItems,
	|	CASE
	|		WHEN &AssetAndLiabilityItem <> UNDEFINED
	|			THEN &AssetAndLiabilityItem
	|		ELSE &ExpenseItem
	|	END AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|	&AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	Debt_.SumMan - ISNULL(ReserveBalances.SumMan, 0) AS Sum,
	|	0 AS AmountExcludingVAT,
	|	Debt_.SumCompl - ISNULL(ReserveBalances.SumCompl, 0) AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&ARAPCurrency AS Currency,
	|	Debt_.Sum - ISNULL(ReserveBalances.Sum, 0) AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	Debt_.Sum- ISNULL(ReserveBalances.Sum, 0) AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|	
	|	&Contract AS SourceOfARAPFinancialAccountingGroup,
	|	Debt_.RowID AS FinRecordID
	|FROM
	|	Table1_ AS Debt_
	|	LEFT JOIN BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|	ON Debt_.RowID = ReserveBalances.RowID
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.ARWriteOff),
	|		VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance))";
#EndRegion
	
	QueryText = APWriteOff
		+ " UNION ALL " + ARWriteOff;
		
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	&LineOfBusiness AS LineOfBusiness,
	|	
	|	UNDEFINED AS Partner,
	|	&Organization AS Counterparty,
	|	&Contract AS Contract,
	|	
	|	&LineOfBusiness AS CorLineOfBusiness,
	|	&Partner AS CorPartner,
	|	&Counterparty AS CorCounterparty,
	|	&Contract AS CorContract,
	|	
	|	ReserveBalances.SumMan AS Sum,
	|	0 AS AmountExcludingVAT,
	|	ReserveBalances.SumCompl AS SumCompl,
	|	0 AS LocalAmountExcludingVAT,
	|	
	|	&ARAPCurrency AS Currency,
	|	ReserveBalances.Sum AS AmountInCurrency,
	|	0 AS AmountExcludingVATInCurrency,
	|	
	|	&ARAPCurrency AS ARAPCurrency,
	|	ReserveBalances.Sum AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&ARAPCurrency AS CorCurrencyOfARAPAccounting,
	|	ReserveBalances.Sum AS AdjAmountInARAPCurrency,
	|	0 AS AdjAmountExcludingVATInARAPCurrency,
	|	
	|	&Contract AS SourceOfARAPFinancialAccountingGroup,
	|	&Contract AS CorSourceOfARAPFinancialAccountingGroup
	|FROM
	|	BalancesOfProvisionsForDoubtfulDebts AS ReserveBalances
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Department                          AS Department,
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&ARAPCurrency                   AS Currency,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts)
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	// We get accounting analytics for partners to select the records of the register of reserves for doubtful debts.
	// We also use this analytics to block the accumulation register data.
	
	AnalyticsParameters = New Structure;
	AnalyticsParameters.Insert("Partner", Query.Parameters.Partner);
	AnalyticsParameters.Insert("Organization", Query.Parameters.Organization);
	AnalyticsParameters.Insert("Counterparty", Query.Parameters.Counterparty);
	AnalyticsParameters.Insert("Contract", Catalogs.CounterpartyContracts.EmptyRef());
	AnalyticsParameters.Insert("LineOfBusiness",
		Common.ObjectAttributeValue(Query.Parameters.Contract, "LineOfBusiness"));
	
	DimensionAccounting_1 = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(AnalyticsParameters);
	
	AuxiliaryQuery = New Query;
	AuxiliaryQuery.TempTablesManager = Query.TempTablesManager;
	For Each Parameter In Query.Parameters Do
		AuxiliaryQuery.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	AuxiliaryQuery.SetParameter("DimensionAccounting_1", DimensionAccounting_1);
	
	AuxiliaryQuery.Text =
	"SELECT
	|	Debt_.LineNumber,
	|	&DimensionAccounting_1 AS AccountingDimensionByPartners,
	|	&Contract AS ARAPObject,
	|	&ARAPCurrency AS Currency,
	|	Debt_.AmountType,
	|	Debt_.RowID,
	|	Debt_.Sum AS Sum,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0) AS SumCompl,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0) AS SumMan
	|FROM
	|	Document.ARAPAdjustmentFinancialInstruments.Debt_ AS Debt_
	|	
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON
	|		Debt_.Ref = Amounts.Ref
	|		AND Debt_.RowID = Amounts.RowID
	|WHERE
	|	Debt_.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)";
	
	Table1_ = AuxiliaryQuery.Execute().Unload();
	
	// Copy the structure of the table of reserve balances and add the row ID column.
	
	DistributionTable_1 = Table1_.CopyColumns();
	DistributionTable_1.Columns.Add("PermanentDifference", New TypeDescription("Number"));
	DistributionTable_1.Columns.Add("CostTD", New TypeDescription("Number"));
	AuxiliaryQuery.Text =
	"SELECT
	|	ReserveBalances.AccountingDimensionByPartners,
	|	ReserveBalances.ARAPObject,
	|	ReserveBalances.Currency,
	|	ReserveBalances.AmountType,
	|	
	|	-ReserveBalances.SumBalance AS Sum,
	|	-ReserveBalances.SumManBalance AS SumMan,
	|	-ReserveBalances.SumComplBalance AS SumCompl,
	|	-ReserveBalances.PermanentDifferenceBalance AS PermanentDifference,
	|	-ReserveBalances.CostTDBalance AS CostTD
	|FROM
	|	AccumulationRegister.LossAllowance.Balance(&PointInTime,
	|		&DimensionAccounting_1 = AccountingDimensionByPartners
	|		AND &Contract = ARAPObject
	|		AND &ARAPCurrency = Currency
	|		AND UNDEFINED = ARAPDocument
	|	) AS ReserveBalances
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance)";
	
	// We block the accumulation register "Reserves for doubtful debts" according to the Accounting Analytics for partners and the Object of settlements.
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("AccumulationRegister.LossAllowance");
	DataLockItem.Mode = DataLockMode.Shared;
	DataLockItem.SetValue("AccountingDimensionByPartners", DimensionAccounting_1);
	DataLockItem.SetValue("ARAPObject", Query.Parameters.Contract);
	DataLock.Lock();
	
	TableReserveBalances = AuxiliaryQuery.Execute().Unload();
	TableReserveBalances.Indexes.Add("AmountType");
	
	If Not TableReserveBalances.Count() = 0 Then
		
		// We distribute the debt table according to the table of reserve balances.
		
		For Each RowArrears In Table1_ Do
			TheStructureOfTheSearch = New Structure("AmountType", RowArrears.AmountType);
			FoundRows = TableReserveBalances.FindRows(TheStructureOfTheSearch);
			For Each LineReserveBalances In FoundRows Do
				If RowArrears.Sum = 0 And RowArrears.SumCompl = 0 And RowArrears.SumMan = 0 Then
					Break;
				EndIf;
				
				If LineReserveBalances.Sum = 0 And LineReserveBalances.SumCompl = 0 And LineReserveBalances.SumMan = 0 Then
					Continue;
				EndIf;
				
				Sum = Min(RowArrears.Sum, LineReserveBalances.Sum);
				SumMan = Min(RowArrears.SumMan, LineReserveBalances.SumMan);
				SumCompl = Min(RowArrears.SumCompl, LineReserveBalances.SumCompl);
				
				NewRow = DistributionTable_1.Add();
				FillPropertyValues(NewRow, LineReserveBalances,, "Sum,SumMan,SumCompl");
				NewRow.RowID = RowArrears.RowID;
				NewRow.Sum = Sum;
				NewRow.SumMan = SumMan;
				NewRow.SumCompl = SumCompl;
				NewRow.CostTD = Min(SumCompl, LineReserveBalances.CostTD);
				NewRow.PermanentDifference = Min(SumCompl, LineReserveBalances.PermanentDifference);
				
				RowArrears.Sum = RowArrears.Sum - Sum;
				RowArrears.SumMan = RowArrears.SumMan - SumMan;
				RowArrears.SumCompl = RowArrears.SumCompl - SumCompl;
				
				LineReserveBalances.Sum = LineReserveBalances.Sum - Sum;
				LineReserveBalances.SumMan = LineReserveBalances.SumMan - SumMan;
				LineReserveBalances.SumCompl = LineReserveBalances.SumCompl - SumCompl;
				LineReserveBalances.CostTD = LineReserveBalances.CostTD - NewRow.CostTD;
				LineReserveBalances.PermanentDifference = LineReserveBalances.PermanentDifference - NewRow.PermanentDifference;
			EndDo;
		EndDo;
		
	EndIf;
	Query.SetParameter("AllocationOfReserves", DistributionTable_1);
	
	QueryText =
	"SELECT
	|	T.AccountingDimensionByPartners,
	|	T.ARAPObject,
	|	T.Currency,
	|	T.AmountType,
	|	T.RowID,
	|	T.Sum,
	|	T.SumMan,
	|	T.SumCompl,
	|	T.CostTD,
	|	T.PermanentDifference
	|INTO AllocationOfProvisionsForDoubtfulDebts
	|FROM
	|	&AllocationOfReserves AS T";
	
	QueryTexts.Add(QueryText, "AllocationOfProvisionsForDoubtfulDebts");
	
	QueryText =
	"SELECT
	|	T.RowID,
	|	SUM(T.Sum) AS Sum,
	|	SUM(T.SumMan) AS SumMan,
	|	SUM(T.SumCompl) AS SumCompl,
	|	SUM(T.CostTD) AS CostTD,
	|	SUM(T.PermanentDifference) AS PermanentDifference
	|INTO BalancesOfProvisionsForDoubtfulDebts
	|FROM
	|	AllocationOfProvisionsForDoubtfulDebts AS T
	|GROUP BY
	|	T.RowID";
	
	QueryTexts.Add(QueryText, "BalancesOfProvisionsForDoubtfulDebts");
	
	Return QueryText;
	
EndFunction

Function QueryTextTableLossAllowance(Query, QueryTexts, Registers)

	RegisterName = "LossAllowance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("Table1_", QueryTexts) Then
		QueryTextTemporaryDebtTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("AllocationOfProvisionsForDoubtfulDebts", QueryTexts) Then
		TextOfRequestTTReservesForDoubtfulDebts(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	AllocationOfReserves.AccountingDimensionByPartners,
	|	AllocationOfReserves.ARAPObject,
	|	&ARAPCurrency AS Currency,
	|	UNDEFINED AS ARAPDocument,
	|	AllocationOfReserves.AmountType AS AmountType,
	|	
	|	AllocationOfReserves.Sum AS Sum,
	|	AllocationOfReserves.SumMan AS SumMan,
	|	AllocationOfReserves.SumCompl AS SumCompl,
	|	AllocationOfReserves.PermanentDifference AS PermanentDifference,
	|	AllocationOfReserves.CostTD AS CostTD,
	|	
	|	VALUE(Enum.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance) AS BusinessOperation,
	|	AllocationOfReserves.RowID AS RowID
	|FROM
	|	AllocationOfProvisionsForDoubtfulDebts AS AllocationOfReserves";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

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
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ARWriteOff;
	String.FullDocumentName			= Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName();
	String.PurposeUseKey 	= "Adjusting ofarrears on financial totools";
	String.WorkplaceTitle	 	= NStr("vi = 'Điều chỉnh công nợ theo các công cụ tài chính';
										|ru = 'Корректировка задолженности по финансовым инструментам';
										|en = 'AR/AP adjustment — Financial instruments'; fa = 'تعدیل دریافتنی/پرداختنی — ابزارهای مالی';
										|it = 'Adeguamento del debito su strumenti finanziari';
										|pl = 'Korekta zobowiązania w ramach instrumentów finansowych';
										|tr = 'Alacak/Borç düzeltmesi - Finansal araçlar'");
	String.Order                      = 1;
	String.AddButtonCreate        = True;
	
	If GetFunctionalOption("UseLocal") Then
		String = BusinessTransactionsAndDocuments.Add();
		String.BusinessOperation 		= Enums.BusinessTransactions.WriteOffOfValueImpairedDebtAtExpenseOfLossAllowance;
		String.FullDocumentName			= Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName();
		String.PurposeUseKey 	= "Adjusting ofarrears on financial totools";
		String.WorkplaceTitle	 	= NStr("vi = 'Điều chỉnh công nợ theo các công cụ tài chính';
											|ru = 'Корректировка задолженности по финансовым инструментам';
											|en = 'AR/AP adjustment — Financial instruments'; fa = 'تعدیل دریافتنی/پرداختنی — ابزارهای مالی';
											|it = 'Adeguamento del debito su strumenti finanziari';
											|pl = 'Korekta zobowiązania w ramach instrumentów finansowych';
											|tr = 'Alacak/Borç düzeltmesi - Finansal araçlar'");
		String.Order                      = 2;
		String.AddButtonCreate        = True;
	EndIf;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.APWriteOff;
	String.FullDocumentName			= Metadata.Documents.ARAPAdjustmentFinancialInstruments.FullName();
	String.PurposeUseKey 	= "Adjusting ofarrears on financial totools";
	String.WorkplaceTitle	 	= NStr("vi = 'Điều chỉnh công nợ theo các công cụ tài chính';
										|ru = 'Корректировка задолженности по финансовым инструментам';
										|en = 'AR/AP adjustment — Financial instruments'; fa = 'تعدیل دریافتنی/پرداختنی — ابزارهای مالی';
										|it = 'Adeguamento del debito su strumenti finanziari';
										|pl = 'Korekta zobowiązania w ramach instrumentów finansowych';
										|tr = 'Alacak/Borç düzeltmesi - Finansal araçlar'");
	String.Order                      = 3;
	String.AddButtonCreate        = True;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								New ValueList, 
								New ValueList, 
								"");
	
	Return TableOfValuesAvailable;
	
EndFunction

#EndRegion

#EndIf
