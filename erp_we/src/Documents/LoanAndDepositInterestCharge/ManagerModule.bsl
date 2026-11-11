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
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("FinancialInstruments");
	DocumentMechanisms.Add("DocumentCorrection");
	
	LoanAndDepositInterestChargeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.LoanAndDepositInterestCharge") Then
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
		
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers);
		QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers);
		QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		ReflectOtherRevenue(Query, QueryTexts, Registers);
		
		LoanAndDepositInterestChargeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
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
	
	LoanAndDepositInterestChargeLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create the document "Accruals on loans and deposits".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow - a data string defining the parameters of the input command based on.
//  - Undefined - if there is no right to create a document "Accruals on loans and deposits".
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.LoanAndDepositInterestCharge) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.LoanAndDepositInterestCharge.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.LoanAndDepositInterestCharge);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseLoanAndDepositContracts";
	

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
	
	LoanAndDepositInterestChargeLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return LoanAndDepositInterestChargeLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return LoanAndDepositInterestChargeLocalization.RequestTextTTReflectedInLocalAccounting();

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
	
	#Region SettingUpReflectionAccountInLocalAccounting
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	SetupParameters.DataPath = "Object.Accruals";
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.ArticleType = "ArticleType";
	SetupParameters.AssetAndLiabilityItem = "IncomeAndExpenseItem";
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("AccrualsPresentationOfRecordingInComplAccounting");
	
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction
// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - The operation of the document.
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	ChoiceParametersArray = New Array;
	
	#Region ExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Accruals";
	ChoiceParameters.AssetRef = "IncomeAndExpenseItem";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.FormItems.AssetRef.Add("IncomeAndExpenseItem");
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("AccrualsAssetsLiabilitiesDimension");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = (BusinessOperation = Enums.BusinessTransactions.LoansInterestCharge);
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("AccrualsDimensionOfExpenses");
	#EndRegion
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = (BusinessOperation <> Enums.BusinessTransactions.LoansInterestCharge);
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("AccrualsDimensionOfRevenue");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

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
	
	FullDocumentName = "Document.LoanAndDepositInterestCharge";
	
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
	Query.Text = "
	|SELECT
	|	DocumentData.Ref                AS Ref,
	|	DocumentData.Date                  AS Period,
	|	DocumentData.Number                 AS Number,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization           AS Organization,
	|	DocumentData.StartDate            AS StartDate,
	|	DocumentData.EndDate         AS EndDate,
	|	DocumentData.EmployeeResponsible         AS EmployeeResponsible,
	|	DocumentData.Author                 AS Author,
	|	DocumentData.Comment           AS Comment,
	|	DocumentData.DeletionMark       AS DeletionMark,
	|	DocumentData.Patch           AS Patch,
	|	DocumentData.ReversedDocument  AS ReversedDocument,
	|	DocumentData.CorrectedDocument  AS CorrectedDocument,
	|	DocumentData.Posted              AS Posted,
	|	DocumentData.Organization.LocalAccountingCurrency AS ComplCurrency,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_
	|FROM
	|	Document.LoanAndDepositInterestCharge AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
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
	Values.Insert("MetadataIdentifier",               Common.MetadataObjectID("Document.LoanAndDepositInterestCharge"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses", GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("CurrencyOfMan",                             Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Values.Insert("NumberForPrinting",                     ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Procedure InitializeTrackingAnalyticsKeysForPartners(Query)
	
	If Query.Parameters.Property("PartnerAccountingAnalyticsKeysInitialized_") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = 
	"SELECT DISTINCT
	|	&Organization                                           AS Organization,
	|	AccrualTable.Partner                              AS Partner,
	|	AccrualTable.Counterparty                           AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.LoanAndDepositInterestCharge.Accruals AS AccrualTable
	|	INNER JOIN Catalog.LoanAndDepositContracts AS ContractData
	|		ON AccrualTable.Contract = ContractData.Ref
	|
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|		ON (&Organization = Dimension.Organization)
	|			AND AccrualTable.Counterparty = Dimension.Counterparty
	|			AND AccrualTable.Partner = Dimension.Partner
	|			AND Dimension.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND VALUE(Catalog.LinesOfBusiness.EmptyRef) = Dimension.LineOfBusiness
	|WHERE
	|	AccrualTable.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL ";
	
	QueryAnalyst.SetParameter("Ref",      Query.Parameters.Ref);
	QueryAnalyst.SetParameter("Organization", Query.Parameters.Organization);

	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.AccountingDimensionByPartners.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("PartnerAccountingAnalyticsKeysInitialized_", True);
	
EndProcedure

Function QueryTextTTCurrencyConversionFactors(Query, QueryTexts)
	
	TableName = "TTCurrencyConversionFactors";
	
	QueryText = "
	|SELECT
	|	AccrualTable_.ARAPCurrency,
	|	AccrualTable_.Date
	|INTO PeriodsTable
	|FROM
	|	Document.LoanAndDepositInterestCharge.Accruals AS AccrualTable_
	|WHERE
	|	AccrualTable_.Ref = &Ref
	|GROUP BY
	|	AccrualTable_.ARAPCurrency,
	|	AccrualTable_.Date
	|INDEX BY
	|	AccrualTable_.ARAPCurrency,
	|	AccrualTable_.Date
	|";
	QueryTexts.Add(QueryText, "PeriodsTable");
	
	FinancialInstruments.QueryTextTTCurrencyConversionFactors(QueryTexts, TableName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAccrualTable(Query, QueryTexts) Export
	
	RegisterName = "TTAccrualTable";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTCurrencyConversionFactors", QueryTexts) Then
		QueryTextTTCurrencyConversionFactors(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	AccrualTable_.LineNumber              AS LineNumber,
	|	CASE 
	|		WHEN AccrualTable_.Ref.Patch
	|			THEN AccrualTable_.Ref.Date
	|			ELSE AccrualTable_.Date
	|	END                                      AS Date,
	|	AccrualTable_.Partner                  AS Partner,
	|	AccrualTable_.Counterparty               AS Counterparty,
	|	AccrualTable_.Contract                  AS Contract,
	|	AccrualTable_.Department            AS Department,
	|	AccrualTable_.LineOfBusiness  AS LineOfBusiness,
	|	AccrualTable_.IncomeAndExpenseItem    AS IncomeAndExpenseItem,
	|	AccrualTable_.DimensionOfRevenue         AS DimensionOfRevenue,
	|	AccrualTable_.DimensionOfExpenses        AS DimensionOfExpenses,
	|	AccrualTable_.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	AccrualTable_.ScheduleAmountType          AS ScheduleAmountType,
	|	AccrualTable_.ARAPCurrency     AS ARAPCurrency,
	|	AccrualTable_.AmountARAP      AS AmountARAP,
	|	CAST(AccrualTable_.AmountARAP * Coefficients.ManConversionFactor AS NUMBER(31,2)) AS SumMan,
	|	CAST(AccrualTable_.AmountARAP * Coefficients.LocalConversionRatio AS NUMBER(31,2)) AS SumCompl,
	|	AccrualTable_.GLAccountSettings     AS GLAccountSettings,
	|	AccrualTable_.RowID      AS RowID
	|INTO TTAccrualTable
	|FROM
	|	Document.LoanAndDepositInterestCharge.Accruals AS AccrualTable_
	|		
	|		LEFT JOIN
	|			TTCurrencyConversionFactors AS Coefficients
	|		ON
	|			Coefficients.ARAPCurrency = AccrualTable_.ARAPCurrency
	|			AND Coefficients.Date = AccrualTable_.Date
	|WHERE
	|	AccrualTable_.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure ReflectOtherRevenue(Query, QueryTexts, Registers)
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	TextOtherRevenue =
	"SELECT
	|	TableRevenue.Date AS Period,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	TableRevenue.Partner AS Partner,
	|	TableRevenue.Counterparty AS Counterparty,
	|	TableRevenue.Contract AS Contract,
	|	TableRevenue.Department AS Department,
	|	UNDEFINED AS Individual,
	|	TableRevenue.LineOfBusiness AS LineOfBusiness,
	|	&BusinessOperation AS BusinessOperation,
	|	TableRevenue.IncomeAndExpenseItem AS IncomeItem,
	|	TableRevenue.DimensionOfRevenue AS DimensionOfRevenue,
	|	0 AS Count,
	|	TableRevenue.SumMan AS RevenueExcludingVATManag,
	|	TableRevenue.SumCompl AS RevenueExcludingVATLocal,
	|	0 AS VATManag,
	|	0 AS VATLocal,
	|	0 AS RevenueAmountPD,
	|	UNDEFINED AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT) AS VATTaxation,
	|	TableRevenue.ARAPCurrency AS ARAPCurrency,
	|	TableRevenue.AmountARAP AS AmountARAP,
	|	UNDEFINED AS ARAPObject,
	|	TableRevenue.RowID      AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	TTAccrualTable AS TableRevenue
	|WHERE
	|	&BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.DepositInterestCharge),
	|		VALUE(Enum.BusinessTransactions.IssuedBorrowingsInterestCharge)
	|	)
	|	AND TableRevenue.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.IncomeItems
	|";
	
	IncomeAndExpensesServer.ReflectOtherRevenue(Query, QueryTexts, Registers, TextOtherRevenue);
	
EndProcedure

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses("VariancePeriod");
	QueryText = QueryText + "UNION ALL" + "
	|SELECT
	|	TableExpenses.Date                     AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	&Organization                            AS Organization,
	|	TableExpenses.Department            AS Department,
	|	TableExpenses.IncomeAndExpenseItem    AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableExpenses.LineOfBusiness  AS LineOfBusiness,
	|	UNDEFINED                            AS VATActivityType,
	|
	|	TableExpenses.SumMan                 AS AmountIncludingVAT,
	|	TableExpenses.SumMan                 AS AmountExcludingVAT,
	|	(CASE
	|		WHEN TableExpenses.Date < &StartDateOfManagementAccountingOfOrganizations
	|			THEN 0
	|		ELSE TableExpenses.SumMan END) AS AmountExcludingVATMan,
	|	TableExpenses.SumCompl                AS AmountIncludingVATCompl,
	|	TableExpenses.SumCompl                AS AmountExcludingVATCompl,
	|	0                                       AS PermanentDifference,
	|	0                                       AS CostTD,
	|	&BusinessOperation                  AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|	
	|	TableExpenses.RowID      AS FinRecordID,
	|	&BusinessTransactionSetting         AS BusinessTransactionSetting,
	|	&AdjustmentPeriod_					AS VariancePeriod
	|	
	|FROM
	|	TTAccrualTable AS TableExpenses
	|	INNER JOIN
	|		ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON
	|		TableExpenses.IncomeAndExpenseItem = ExpenseItems.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.LoansInterestCharge)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts)
	
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	TableExpenses.Date                    AS Period,
	|	&Organization                           AS Organization,
	|	TableExpenses.Department           AS Department,
	|	&Ref                                AS ExpenseReceiptDocument,
	|	TableExpenses.IncomeAndExpenseItem   AS ExpenseItem,
	|	TableExpenses.DimensionOfExpenses       AS DimensionOfExpenses,
	|	UNDEFINED                           AS AssetsLiabilitiesDimension,
	|	UNDEFINED                           AS LotVendorAttributes,
	|	TableExpenses.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED                           AS ItemsLocationAttributes,
	|	UNDEFINED                           AS VATActivityType,
	|
	|	TableExpenses.SumMan                AS Cost,
	|	TableExpenses.SumMan                AS CostExcludingVAT,
	|	0                                      AS VATManag,
	|	TableExpenses.SumCompl               AS LocalCost,
	|	0                                      AS PermanentDifference,
	|	0                                      AS CostTD,
	|	0                                      AS VATLocal,
	|	&BusinessOperation                 AS BusinessOperation,
	|
	|	TableExpenses.RowID     AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTAccrualTable AS TableExpenses
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|		ON TableExpenses.IncomeAndExpenseItem = ExpenseItems.Ref
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.LoansInterestCharge)
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

Function QueryTextTableFinancialInstrumentsARAP(Query, QueryTexts, Registers)
	
	RegisterName = "FinancialInstrumentsARAP";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	InitializeTrackingAnalyticsKeysForPartners(Query);
	
	QueryText = "
	|SELECT
	|	AccrualTable.Date                                               AS Period,
	|	CASE
	|		WHEN AccrualTable.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END                                                                AS RecordType,
	
	|	ISNULL(DimensionByPartners.DimensionKey, UNDEFINED)           AS AccountingDimensionByPartners,
	|	AccrualTable.Contract                                            AS Contract,
	|	AccrualTable.ScheduleAmountType                                    AS AmountType,
	|	AccrualTable.ARAPCurrency                               AS Currency,
	
	|	AccrualTable.AmountARAP                                AS Sum,
	|	AccrualTable.SumMan                                           AS SumMan,
	|	AccrualTable.SumCompl                                          AS SumCompl,
	
	|	&BusinessOperation                                               AS BusinessOperation,
	|	VALUE(Enum.FinancialInstrumentScheduleTypes.Accruals) AS ScheduleType,
	|	AccrualTable.IncomeAndExpenseItem                              AS DimensionItem,
	|	AccrualTable.RowID                                AS RowID,
	|	
	|	AccrualTable.RowID                                AS FinRecordID,
	|	&BusinessTransactionSetting                                      AS BusinessTransactionSetting
	|		
	|FROM
	|	TTAccrualTable AS AccrualTable
	|		LEFT JOIN InformationRegister.AccountingDimensionByPartners AS DimensionByPartners
	|		ON DimensionByPartners.Organization = &Organization
	|			AND DimensionByPartners.Partner = AccrualTable.Partner
	|			AND DimensionByPartners.Counterparty = AccrualTable.Counterparty
	|			AND DimensionByPartners.Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef)
	|			AND DimensionByPartners.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCashIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	AccrualTable_.Date                              AS Period,
	|	&BusinessOperation                              AS BusinessOperation,
	|	&Organization                                        AS Organization,
	|	AccrualTable_.Contract.Department             AS Department,
	|	AccrualTable_.Department                     AS IncomeExpenseBusinessUnit,
	|
	|	AccrualTable_.Contract.LineOfBusiness   AS LineOfBusinessCash,
	|	AccrualTable_.Contract                           AS Cash,
	|	VALUE(Enum.CashTypes.Deposits) AS CashType,
	|	UNDEFINED                                        AS CashFlowItem,
	|	AccrualTable_.ARAPCurrency              AS Currency,
	|
	|	AccrualTable_.LineOfBusiness           AS LineOfBusinessItems,
	|	AccrualTable_.IncomeAndExpenseItem             AS IncomeAndExpenseItem,
	|	AccrualTable_.DimensionOfRevenue                  AS DimensionOfRevenue,
	|	UNDEFINED                                        AS DimensionOfExpenses,
	|	AccrualTable_.AssetsLiabilitiesDimension          AS AssetsLiabilitiesDimension,
	|
	|	AccrualTable_.SumMan                          AS Sum,
	|	AccrualTable_.SumCompl                         AS SumCompl,
	|	AccrualTable_.AmountARAP               AS AmountInCurrency,
	|
	|	AccrualTable_.Contract                           AS SourceOfCashFinancialAccountingGroup,
	|	AccrualTable_.IncomeAndExpenseItem             AS SourceOfIncomeExpensesFinancialAccountingGroup
	|FROM
	|	TTAccrualTable AS AccrualTable_
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.DepositInterestCharge)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
#Region IssuedBorrowingsInterestCharge
	IssuedBorrowingsInterestCharge = 
	"SELECT
	|	TableRevenue.Date                     AS Period,
	|	&BusinessOperation                 AS BusinessOperation,
	|	&Organization                           AS Organization,
	|	TableRevenue.Contract.Department    AS Department,
	|	TableRevenue.Department            AS IncomeExpenseBusinessUnit,
	|
	|	TableRevenue.Contract.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	TableRevenue.Partner                  AS Partner,
	|	TableRevenue.Counterparty               AS Counterparty,
	|	TableRevenue.Contract                  AS Contract,
	|	UNDEFINED                           AS ARAPObject,
	|
	|	TableRevenue.LineOfBusiness  AS LineOfBusinessItems,
	|	TableRevenue.IncomeAndExpenseItem    AS IncomeAndExpenseItem,
	|	TableRevenue.DimensionOfRevenue         AS DimensionOfRevenue,
	|	UNDEFINED                           AS DimensionOfExpenses,
	|	TableRevenue.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	TableRevenue.SumMan                 AS Sum,
	|	0                                      AS AmountExcludingVAT,
	|	TableRevenue.SumCompl                AS SumCompl,
	|	0                                      AS LocalAmountExcludingVAT,
	|
	|	TableRevenue.ARAPCurrency     AS Currency,
	|	TableRevenue.AmountARAP      AS AmountInCurrency,
	|	0                                      AS AmountExcludingVATInCurrency,
	|		
	|	TableRevenue.ARAPCurrency     AS ARAPCurrency,
	|	TableRevenue.AmountARAP      AS AmountInARAPCurrency,
	|	0                                      AS AmountExcludingVATInARAPCurrency,
	|
	|	TableRevenue.Contract                  AS SourceOfARAPFinancialAccountingGroup,
	|	TableRevenue.RowID      AS FinRecordID
	|FROM
	|	TTAccrualTable AS TableRevenue
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.IssuedBorrowingsInterestCharge)
	|";
#EndRegion

#Region LoansInterestCharge
	LoansInterestCharge = 
	"SELECT
	|	TableExpenses.Date                     AS Period,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	TableExpenses.Contract.Department    AS Department,
	|	TableExpenses.Department            AS IncomeExpenseBusinessUnit,
	|
	|	TableExpenses.Contract.LineOfBusiness AS CounterpartyLineOfBusiness,
	|	TableExpenses.Partner                  AS Partner,
	|	TableExpenses.Counterparty               AS Counterparty,
	|	TableExpenses.Contract                  AS Contract,
	|	UNDEFINED                            AS ARAPObject,
	|
	|	TableExpenses.LineOfBusiness  AS LineOfBusinessItems,
	|	TableExpenses.IncomeAndExpenseItem    AS IncomeAndExpenseItem,
	|	UNDEFINED                            AS DimensionOfRevenue,
	|	TableExpenses.DimensionOfExpenses        AS DimensionOfExpenses,
	|	TableExpenses.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	
	|	TableExpenses.SumMan                 AS Sum,
	|	0                                       AS AmountExcludingVAT,
	|	TableExpenses.SumCompl                AS SumCompl,
	|	0                                       AS LocalAmountExcludingVAT,
	|
	|	TableExpenses.ARAPCurrency     AS Currency,
	|	TableExpenses.AmountARAP      AS AmountInCurrency,
	|	0                                       AS AmountExcludingVATInCurrency,
	|		
	|	TableExpenses.ARAPCurrency     AS ARAPCurrency,
	|	TableExpenses.AmountARAP      AS AmountInARAPCurrency,
	|	0                                       AS AmountExcludingVATInARAPCurrency,
	|
	|	TableExpenses.Contract                  AS SourceOfARAPFinancialAccountingGroup,
	|	TableExpenses.RowID      AS FinRecordID
	|FROM
	|	TTAccrualTable AS TableExpenses
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.LoansInterestCharge)";
#EndRegion

	QueryText = IssuedBorrowingsInterestCharge
		+ " UNION ALL " + LoansInterestCharge;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.LoansInterestCharge) THEN
	|			VALUE(AccumulationRecordType.Receipt)
	|		ELSE
	|			VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusiness AS LineOfBusiness,
	|	AccrualTable.IncomeAndExpenseItem AS AssetRef,
	|	CASE
	|		WHEN AccrualTable.AssetsLiabilitiesDimension = VALUE(Enum.AssetAndLiabilityItemsWithoutDimension.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE AccrualTable.AssetsLiabilitiesDimension
	|	END AS Dimension,
	|	SUM(AccrualTable.SumMan) AS Sum
	|FROM
	|	TTAccrualTable AS AccrualTable
	|WHERE
	|	AccrualTable.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	
	|GROUP BY
	|	AccrualTable.IncomeAndExpenseItem,
	|	AccrualTable.AssetsLiabilitiesDimension,
	|	AccrualTable.LineOfBusiness,
	|	AccrualTable.Department
	|";
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
	
	If Not DocumentsPosting.ThereIsQueryTable("TTAccrualTable", QueryTexts) Then
		QueryTextTTAccrualTable(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	AccrualTable.Date AS Period,
	|	&Organization AS Organization,
	|	AccrualTable.Department AS Department,
	|	AccrualTable.LineOfBusiness AS LineOfBusiness,
	|	AccrualTable.IncomeAndExpenseItem AS AssetRef,
	|	AccrualTable.AssetsLiabilitiesDimension AS Dimension,
	|	AccrualTable.GLAccountSettings AS GLAccountSettings,
	|	CASE
	|		WHEN AccrualTable.Contract.ContractKind = VALUE(Enum.ContractKindsOfFinancialInstruments.LoanOrBorrowing)
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		ELSE
	|			VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|	END AS DebitCredit,
	|
	|	AccrualTable.SumCompl AS SumCompl,
	|	AccrualTable.SumMan AS SumMan,
	|	AccrualTable.SumMan AS AmountIncludingVAT,
	|	AccrualTable.SumMan AS AmountExcludingVAT,
	|
	|	AccrualTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	TTAccrualTable AS AccrualTable
	|WHERE
	|	AccrualTable.IncomeAndExpenseItem REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|";
	
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
	|	UNDEFINED                            AS StorageLocation,
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
	|	0                                       AS Sum,
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

#Region DocumentJournal

Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments) Export
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.LoansInterestCharge;
	String.FullDocumentName			= Metadata.Documents.LoanAndDepositInterestCharge.FullName();
	String.PurposeUseKey 	= "LoanAndDepositInterestCharge";
	String.WorkplaceTitle	 	= NStr("vi = 'Tính lãi đi vay và tiết kiệm';
										|ru = 'Начисления по кредитам и депозитам';
										|en = 'Credit and deposit interest charge'; fa = 'محاسبه سود اعتبار و سپرده';
										|it = 'Maturazioni per crediti e depositi';
										|pl = 'Naliczenia wg pożyczek i depozytów';
										|tr = 'Kredi ve mevduat faiz gideri'");
	String.Order                      = 1;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.DepositInterestCharge;
	String.FullDocumentName			= Metadata.Documents.LoanAndDepositInterestCharge.FullName();
	String.PurposeUseKey 	= "LoanAndDepositInterestCharge";
	String.WorkplaceTitle	 	= NStr("vi = 'Tính lãi đi vay và tiết kiệm';
										|ru = 'Начисления по кредитам и депозитам';
										|en = 'Credit and deposit interest charge'; fa = 'محاسبه سود اعتبار و سپرده';
										|it = 'Maturazioni per crediti e depositi';
										|pl = 'Naliczenia wg pożyczek i depozytów';
										|tr = 'Kredi ve mevduat faiz gideri'");
	String.Order                      = 2;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.IssuedBorrowingsInterestCharge;
	String.FullDocumentName			= Metadata.Documents.LoanAndDepositInterestCharge.FullName();
	String.PurposeUseKey 	= "LoanAndDepositInterestCharge";
	String.WorkplaceTitle	 	= NStr("vi = 'Tính lãi đi vay và tiết kiệm';
										|ru = 'Начисления по кредитам и депозитам';
										|en = 'Credit and deposit interest charge'; fa = 'محاسبه سود اعتبار و سپرده';
										|it = 'Maturazioni per crediti e depositi';
										|pl = 'Naliczenia wg pożyczek i depozytów';
										|tr = 'Kredi ve mevduat faiz gideri'");
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

#EndRegion

#EndIf
