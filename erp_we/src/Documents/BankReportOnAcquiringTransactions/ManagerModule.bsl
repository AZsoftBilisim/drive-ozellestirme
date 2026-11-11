#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization, Department");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "AcquiringContract", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "AcquiringContract";
	Parameters.FillInIf.ObjectFieldsFilledIn = "AcquiringContract";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "ExpenseItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "ExpenseItem";
	Parameters.FillInIf.ObjectFieldsFilledIn = "ExpenseItem";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "DimensionOfExpenses", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization, Department";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(
		AttributesDetails1, "EmployeeResponsible", Parameters);
	
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
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	BankReportOnAcquiringTransactionsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.BankReportOnAcquiringTransactions") Then
		DocumentRef = Document.Ref;
		DocumentObject = Document
	Else
		DocumentRef = Document;
		DocumentObject = Document.GetObject();
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
		
		QueryTextAcquiringContractARAP(Query, QueryTexts, Registers);
		QueryTextCashInTransit(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextRecordsCashCounterparty(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		// Execution of the request and unloading of the received tables for the formation of movements
		BankReportOnAcquiringTransactionsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
	AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject);
	
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
	
	BankReportOnAcquiringTransactionsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Bank report on acquiring".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow - a data string defining the parameters of the input command based on.
//  - Undefined - if there is no right to create a document "The bank's Acquiring Report".
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.BankReportOnAcquiringTransactions) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.BankReportOnAcquiringTransactions.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BankReportOnAcquiringTransactions);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePaymentByCards";
	

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
	
	BankReportOnAcquiringTransactionsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	BankReportOnAcquiringTransactionsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	Operations = Enums.BusinessTransactions;
	
	// 
	Item = Settings.Add();
	Item.Fields.Add("PurchasePage");
	Item.Fields.Add("RefundsPage");
	Item.Fields.Add("AmountOfPurchases");
	Item.Fields.Add("AmountOfReturns");
	Finances.NewFilter(Item.Condition, "DetailedTransactionReconciliation", True);
	Item.Properties.Insert("Visible");
	
	// 
	Item = Settings.Add();
	Item.Fields.Add("CommissionPage");
	Item.Fields.Add("FeeAmount");
	Finances.NewFilter(Item.Condition, "RecordCommission", True);
	Item.Properties.Insert("Visible");
	
	// LabelCurrency
	Item = Settings.Add();
	Item.Fields.Add("LabelCurrencyCommission");
	Finances.NewFilter(Item.Condition, "More.UseMultipleCurrencies", False);
	Item.Properties.Insert("Visible");
	
	// POSTerminal
	Item = Settings.Add();
	Item.Fields.Add("PurchasesPOSTerminal");
	Item.Fields.Add("ReturnsPOSTerminal");
	Finances.NewFilter(Item.Condition, "More.POSTerminalsAreUsed", True);
	Item.Properties.Insert("Visible");
	
	// AuthorizationCode
	Item = Settings.Add();
	Item.Fields.Add("PurchasesAuthorizationCode");
	Item.Fields.Add("ReturnsAuthorizationCode");
	Finances.NewFilter(Item.Condition,
		"More.MakingPaymentMethod",
		Enums.MakingPaymentMethods.InstantPayments,,
		DataCompositionComparisonType.NotEqual);
	Item.Properties.Insert("Visible");
	
	// FPSPaymentID
	Item = Settings.Add();
	Item.Fields.Add("SetUpFPSConnection");
	Item.Fields.Add("PurchasesFPSPaymentID");
	Item.Fields.Add("ReturnsFPSPaymentID");
	Finances.NewFilter(Item.Condition,
		"More.MakingPaymentMethod",
		Enums.MakingPaymentMethods.InstantPayments,,
		DataCompositionComparisonType.Equal);
	Item.Properties.Insert("Visible");
	
	// Department
	Item = Settings.Add();
	Item.Fields.Add("Department");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", False);
	Item.Properties.Insert("Visible");
	
	// CommissionAgreement
	Item = Settings.Add();
	Item.Fields.Add("CommissionAgreement");
	Finances.NewFilter(Item.Condition, "KeepRecordsOfCommissionInARAPAccounting", True);
	Item.Properties.Insert("Visible");
	
EndProcedure

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	AvailabilityByOperation - Boolean - Indicates whether a selection of articles and analytics is available
// 
// Returns:
// 	- Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions
//
Function ItemsAndDimensionsSelectionParameters(AvailabilityByOperation) Export
	
	ArrayOfSelectionParameters = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItem");
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("DimensionOfExpenses");
	#EndRegion
	
	ChoiceParameters.AvailabilityByOperation = AvailabilityByOperation;
	ArrayOfSelectionParameters.Add(ChoiceParameters);
	#EndRegion
		
	Return ArrayOfSelectionParameters;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return BankReportOnAcquiringTransactionsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return BankReportOnAcquiringTransactionsLocalization.RequestTextTTReflectedInLocalAccounting();

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
	RedefiningParameterCalculation = New Structure;
	SynonymForDocumentTable = "";
	
	FullDocumentName = "Document.BankReportOnAcquiringTransactions";
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
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
			QueryText, FullDocumentName, SynonymForDocumentTable, True, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ValuesOfHoldingParameters();
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref                           AS Ref,
	|	DocumentData.Date                             AS Period,
	|	DocumentData.Number                            AS Number,
	|	DocumentData.CorrectedDocument.Date        AS AdjustmentPeriod_,
	|	DocumentData.Currency                           AS Currency,
	|	DocumentData.Organization                      AS Organization,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Author                            AS Author,
	|	DocumentData.AcquiringContract                AS AcquiringContract,
	|	DocumentData.AcquiringContract.BankAccount AS BankAccount,
	|	DocumentData.AcquiringContract.Counterparty     AS Acquirer,
	|	DocumentData.AcquiringContract.DetailedTransactionReconciliation     AS DetailedTransactionReconciliation,	
	|	DocumentData.AcquiringContract.CashFlowItemCashReceipt AS CashFlowItemCashReceipt,
	|	DocumentData.AcquiringContract.CashFlowItemReturn AS CashFlowItemReturn,
	|	DocumentData.Department                    AS Department,
	|	DocumentData.FeeAmount                    AS FeeAmount,
	|	DocumentData.DocumentAmount                   AS DocumentAmount,
	|	DocumentData.Patch                      AS Patch,
	|	DocumentData.ReversedDocument             AS ReversedDocument,
	|	DocumentData.CorrectedDocument             AS CorrectedDocument,
	|	DocumentData.DeletionMark                  AS DeletionMark,
	|	DocumentData.Posted                         AS Posted
	|FROM
	|	Document.BankReportOnAcquiringTransactions AS DocumentData
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
	
	Query.SetParameter("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.BankReportOnAcquiringTransactions);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.BankReportOnAcquiringTransactions"));
	Values.Insert("BusinessOperation",                           Enums.BusinessTransactions.BankReportOnAcquiringTransactions);
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextAcquiringContractARAP(Query, QueryTexts, Registers)
	
	RegisterName = "AcquiringContractARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	Payments_2.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	
	|	Payments_2.PaymentDate AS PaymentDate,
	|	Payments_2.POSTerminal AS POSTerminal,
	|	&AcquiringContract AS Contract,
	|	&Organization AS Organization,
	|	VALUE(Enum.AcquiringCashTypes.CashRecieptByAcquiringTransactions) AS CashType,
	|	&Currency AS Currency,
	|	
	|	VALUE(Enum.BusinessTransactions.BankReportOnAcquiringTransactions) AS BusinessOperation,
	|	&CashFlowItemCashReceipt AS CashFlowItem,
	|	Payments_2.AuthorizationCode AS AuthorizationCode,
	|	Payments_2.PaymentCardNumber AS PaymentCardNumber,
	|	
	|	Payments_2.Sum AS Sum
	|	
	|FROM
	|	Document.BankReportOnAcquiringTransactions.Purchases AS Payments_2
	|	
	|WHERE
	|	Payments_2.Ref = &Ref
	|	AND &DetailedTransactionReconciliation = TRUE	
	|
	|UNION ALL
	|
	|SELECT
	|	Payments_2.LineNumber AS LineNumber,
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	Payments_2.PaymentDate AS PaymentDate,
	|	Payments_2.POSTerminal AS POSTerminal,
	|	&AcquiringContract AS Contract,
	|	&Organization AS Organization,
	|	VALUE(Enum.AcquiringCashTypes.CashIssueByPaymentCard) AS CashType,
	|	&Currency AS Currency,
	|	
	|	VALUE(Enum.BusinessTransactions.BankReportOnAcquiringTransactions) AS BusinessOperation,
	|	&CashFlowItemReturn AS CashFlowItem,
	|	Payments_2.AuthorizationCode AS AuthorizationCode,
	|	Payments_2.PaymentCardNumber AS PaymentCardNumber,
	|	
	|	Payments_2.Sum AS Sum
	|	
	|FROM
	|	Document.BankReportOnAcquiringTransactions.Returns AS Payments_2
	|	
	|WHERE
	|	Payments_2.Ref = &Ref
	|	AND &DetailedTransactionReconciliation = TRUE
	|	
	|ORDER BY
	|	LineNumber
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)                                               AS RecordType,
	|	DocumentData.Date                                                                 AS Period,
	|	
	|	DocumentData.Organization                                                          AS Organization,
	|	DocumentData.AcquiringContract.BankAccount                                     AS Recipient,
	|	UNDEFINED                                                                         AS Sender,
	|	VALUE(Enum.CashTransferKinds.CashReceiptFromBankByAcquiring)   AS CashTransferKind,
	|	DocumentData.AcquiringContract.Counterparty                                         AS Counterparty,
	|	DocumentData.AcquiringContract                                                    AS Contract,
	|	DocumentData.Currency                                                               AS Currency,
	|	
	|	DocumentData.FeeAmount                                                               AS Sum,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2))   AS SumMan,
	|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS SumCompl,
	|	
	|	VALUE(Enum.BusinessTransactions.AcquiringFee)                    AS BusinessOperation,
	|	DocumentData.AcquiringContract.CashFlowItemCommission              AS CashFlowItem,
	|	
	|	DocumentData.DocumentID                                               AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.BankReportOnAcquiringTransactions)             AS BusinessTransactionSetting 
	|	
	|FROM
	|	Document.BankReportOnAcquiringTransactions AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTInitialOtherExpenses";
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AcquiringContract.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.ExpenseItem AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS VATActivityType,
	|	
		// Calculate the amount in the currency of management accounting.
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVATMan,
	|
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountIncludingVATCompl,
	|	ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, DocumentData.FeeAmount) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting 
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.BankReportOnAcquiringTransactions AS DocumentData
	|	LEFT JOIN
	|		TTAmountsOfDocumentsInAccountingCurrencies AS DocumentAmountsInAccountingCurrency
	|	ON
	|		DocumentAmountsInAccountingCurrency.Ref = DocumentData.Ref
	|		AND DocumentAmountsInAccountingCurrency.RowID = ""1""
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|	AND NOT DocumentData.KeepRecordsOfCommissionInARAPAccounting
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

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers)

	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.AcquiringContract.BankAccount.Department AS Department,
	|	DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|	DocumentData.Department AS IncomeExpenseBusinessUnit,
	|
	|	DocumentData.AcquiringContract AS Cash,
	|	VALUE(Enum.CashTypes.BankAcquirerCash) AS CashType,
	|	CASE
	|		WHEN ISNULL(DocumentData.AcquiringContract.CashFlowItemCommission, VALUE(Catalog.CashFlowReportItems.EmptyRef)) = VALUE(Catalog.CashFlowReportItems.EmptyRef) THEN
	|			VALUE(Catalog.CashFlowReportItems.PaymentToVendor)
	|		ELSE
	|			DocumentData.AcquiringContract.CashFlowItemCommission
	|	END AS CashFlowItem,
	|	DocumentData.Currency AS Currency,
	|
	|	DocumentData.AcquiringContract.LineOfBusiness AS LineOfBusinessItems,
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfRevenue,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	DocumentData.FeeAmount AS AmountInCurrency,
	|
	|	UNDEFINED AS SourceOfCashFinancialAccountingGroup,
	|	DocumentData.ExpenseItem AS SourceOfIncomeExpensesFinancialAccountingGroup
	|
	|FROM
	|	Document.BankReportOnAcquiringTransactions AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FeeAmount <> 0
	|	AND DocumentData.RecordCommission
	|";
	
	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;

EndFunction

Function QueryTextRecordsCashCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"	SELECT
	|		DocumentData.Date AS Period,
	|		VALUE(Enum.BusinessTransactions.AcquiringFee) AS BusinessOperation,
	|		DocumentData.Organization AS Organization,
	|		DocumentData.Department AS Department,
	|		DocumentData.AcquiringContract.BankAccount.LineOfBusiness AS LineOfBusinessCash,
	|
	|		DocumentData.AcquiringContract.BankAccount AS Cash,
	|		DocumentData.AcquiringContract.CashFlowItemCommission AS CashFlowItem,
	|		DocumentData.Currency AS PaymentCurrency,
	|
	|		DocumentData.CommissionARAPObject.LineOfBusiness AS LineOfBusiness,
	|		DocumentData.AcquiringContract.Partner AS Partner,
	|		DocumentData.CommissionARAPObject.Counterparty AS Counterparty,
	|		DocumentData.CommissionARAPObject.Contract AS Contract,
	|		DocumentData.CommissionARAPObject AS ARAPObject,
	|	
	|		CAST(DocumentData.FeeAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS PayAmount,
	|		CAST(DocumentData.FeeAmount * &FactorOfConversionToCurrencyOfRegul  AS NUMBER(31,2)) AS PaymentAmountLocal,
	|		DocumentData.FeeAmount AS PaymentAmountPaymentCurrency,
	|
	|		0 AS PostpaymentAmount,
	|		0 AS PostpaymentAmountLocal,
	|		0 AS PaymentAmountInPaymentCurrency,
	|		
	|		0 AS PrepaymentAmountMan,
	|		0 AS PrepaymentAmountLocal,
	|		0 AS PrepaymentAmount,
	|	
	|		0 AS VATAmount,
	|		0 AS VATAmountCompl,
	|		0 AS AmountVATCurrencyPayment,
	|
	|		DocumentData.Currency AS ARAPCurrency,
	|
	|		DocumentData.FeeAmount AS PaymentAmountInTheSettlementCurrency,
	|		0 AS PostPaymentAmountInARAPCurrency,
	|		0 AS PrepaymentAmountInARAPCurrency,
	|
	|		DocumentData.AcquiringContract.BankAccount AS SourceOfCashFinancialAccountingGroup,
	|		DocumentData.CommissionARAPObject AS SourceOfARAPFinancialAccountingGroup,
	|		UNDEFINED AS VATRate,
	|		UNDEFINED AS PaymentRequest
	|	FROM
	|		Document.BankReportOnAcquiringTransactions AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|		AND DocumentData.KeepRecordsOfCommissionInARAPAccounting
	|		AND DocumentData.RecordCommission
	|		AND DocumentData.FeeAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""BankReportOnAcquiringTransactions"" AS DataSource,
	|	FALSE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Date AS Date,
	|	DocumentTable.Organization AS Organization,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	UNDEFINED AS ARAPCurrency,
	|	UNDEFINED AS VATBasePeriod,
	|	DocumentTable.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	""1"" AS RowID,
	|	DocumentTable.FeeAmount AS AmountExcludingVAT,
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
	|	Document.BankReportOnAcquiringTransactions AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False);
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&MetadataIdentifier                AS RefType,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS Partner,
	|	DocumentData.AcquiringContract.BankAccount AS StorageLocation,
	|	DocumentData.AcquiringContract.Counterparty     AS Counterparty,
	|	&Department                          AS Department,
	|	&Period                                 AS IBDocumentDate,
	|	&Ref                                 AS Ref,
	
	|	&Number                                  AS IBDocumentNumber,
	|	UNDEFINED                            AS Status,
	|	UNDEFINED                            AS EmployeeResponsible,
	|	&Author                                  AS Author,
	|	FALSE                                    AS AdditionalRecord,
	|	UNDEFINED                            AS More,
	|	UNDEFINED                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	&DocumentAmount                         AS Sum,
	|	&Currency                                 AS Currency,
	|	&AcquiringContract                      AS Contract,
	|	UNDEFINED                            AS LineOfBusiness,
	|	&Patch                            AS ReverseTransactionCorrection,
	|	&ReversedDocument                   AS ReversedDocument,
	|	&CorrectedDocument                   AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.BankReportOnAcquiringTransactions AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers, DocumentObject)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.CommissionARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.BankReportOnAcquiringTransactions AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref = &Ref
		|";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates, True);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	TextPayment = "
		|SELECT
		|	DocumentData.Ref                                           AS Ref,
		|	DocumentData.Organization                                      AS Organization,
		|	CatalogAcquiringContracts.Partner                             AS Partner,
		|	DocumentData.Date                                             AS RecorderDate,
		|	DocumentData.Number                                            AS RecorderNumber,
		|	
		|	DocumentData.CommissionARAPObject                           AS ARAPObject,
		|	DocumentData.Currency                                           AS ARAPCurrency,
		|
		|	DocumentData.FeeAmount                                    AS Sum,
		|	DocumentData.FeeAmount                                    AS AmountARAP,
		|	0                                                                AS ReductionIsPaid,
		|	0                                                                AS IncreaseIsPaid,
		|	0                                                                AS SumMan,
		|	0                                                                AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.AcquiringFee)  AS BusinessOperation,
		|	CatalogAcquiringContracts.CashFlowItemCommission AS CashFlowItem,
		|	UNDEFINED                                                       AS PaymentRequest,
		|	VALUE(Enum.PaymentForms.BankAccountPayment)                     AS PaymentMethod,
		|	DocumentData.Currency                                             AS DocumentCurrency,
		|	DocumentData.Date                                               AS DateOfCourse,
		|	DocumentData.Date                                               AS MaturityDate,
		|	UNDEFINED                                                       AS LinkedDocument,
		|	DocumentData.DocumentID                             AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.BankReportOnAcquiringTransactions) AS BusinessTransactionSetting
		|FROM
		|	Document.BankReportOnAcquiringTransactions AS DocumentData
		|		LEFT JOIN Catalog.AcquiringContracts AS CatalogAcquiringContracts
		|			ON DocumentData.AcquiringContract = CatalogAcquiringContracts.Ref
		|WHERE
		|	DocumentData.Ref = &Ref
		|	AND DocumentData.KeepRecordsOfCommissionInARAPAccounting
		|	AND DocumentData.FeeAmount <> 0
		|	AND DocumentData.RecordCommission
		|";
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment);
	
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
	
	FullDocumentName = Metadata.Documents.BankReportOnAcquiringTransactions.FullName();
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation = Enums.BusinessTransactions.EmptyRef();
	String.MetadataObjectID = Common.MetadataObjectID(FullDocumentName);
	String.FullDocumentName = FullDocumentName;
	String.PurposeUseKey = "Report ofbank on operations_ ofacquiring";
	String.WorkplaceTitle = NStr("vi = 'Báo cáo của ngân hàng theo giao dịch thẻ';
								|ru = 'Отчет банка по операциям эквайринга';
								|en = 'Merchant statement'; fa = 'صورتحساب پذیرنده';
								|it = 'Report della banca relativo alle operazioni del terminale di acquisizione';
								|pl = 'Raport banku według operacji przez centrum autoryzacyjne';
								|tr = 'İşyeri ekstresi: PoS işlemleri'");
	String.Order = 1;
	String.AddButtonCreate = True;
	String.AccessRightInsert = AccessRight("Insert", Metadata.Documents.BankReportOnAcquiringTransactions);;
	String.AccessRightUpdate = AccessRight("Update", Metadata.Documents.BankReportOnAcquiringTransactions);;
	String.Filter = True;
	
	Return BusinessTransactionsAndDocuments;
	
EndFunction

#EndRegion

#EndIf
