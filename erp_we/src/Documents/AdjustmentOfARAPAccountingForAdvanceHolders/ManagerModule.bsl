
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
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"Department", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("AdvanceHoldersARAPAccounting_");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ExpenseReportLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure, ValueList of String - a collection of data tables to be reflected in the register.
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.AdjustmentOfARAPAccountingForAdvanceHolders") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query        = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		
		QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherIncome(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		AdjustmentOfARAPAccountingForAdvanceHoldersLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
// 
// Returns:
// 	Array 
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation) Export
	
	WriteOffToRevenue =
		BusinessOperation = Enums.BusinessTransactions.RecognitionOfDebtToAdvanceHolderAsIncome;
	ChoiceParametersArray = New Array;
	
	#Region AssetRef
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.ARAPAdjustment";
	ChoiceParameters.AssetRef = "AssetRef";
	ChoiceParameters.ArticleType = "ArticleType";
	ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
	If WriteOffToRevenue Then
		ChoiceParameters.DefaultValue = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
	EndIf;
	ChoiceParameters.FormItems.AssetRef.Add("ARAPAdjustmentAssetRef");
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = WriteOffToRevenue;
	ChoiceParameters.DimensionOfRevenue = "DimensionOfRevenue";
	ChoiceParameters.FormItems.DimensionOfRevenue.Add("ARAPAdjustmentDimensionOfRevenue");
	#EndRegion
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = Not WriteOffToRevenue;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ARAPAdjustmentDimensionOfExpenses");
	#EndRegion
	
	#Region AssetsLiabilitiesDimension
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add(
		        "ARAPAdjustmentAssetsLiabilitiesDimension");
	#EndRegion
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
		
	Return ChoiceParametersArray;
	
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
	SetupParameters.DataPath = "Object.ARAPAdjustment";
	
	SetupParameters.ArticleType = "ArticleType";
	SetupParameters.AssetAndLiabilityItem = "AssetRef";
	
	SetupParameters.Presentation = "PresentationOfRecordingInComplAccounting";
	
	SetupParameters.Organization = "Object.Organization";

	SetupParameters.FormItems.Add("ARAPAdjustmentPresentationOfRecordingInComplAccounting");
	ParametersArray.Add(SetupParameters);
	#EndRegion
	
	Return ParametersArray;
	
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return AdjustmentOfARAPAccountingForAdvanceHoldersLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

// Returns Balances of funds from accountable persons
//
// Parameters:
//  ParametersForObtainingBalances - Structure:
//   *Date                  - Date - the date on which the Balances will be received.
//   *Organization           - CatalogRef.Companies
//   *Department         - CatalogRef.BusinessStructure
//   *BusinessOperation - EnumRef.BusinessTransactions - determines the nature of the resulting Balance.
//                                                     if a household is specified. The write-off Operation
//                                                     is due to the reporting face, then positive Balances will be received.
//                                                     Otherwise, negative Balances will be obtained.
//   *AdvanceHolder       - CatalogRef.Persons - optional parameter
//                                                   . If omitted, Balances for all reporting entities will be received.
//   *Currency                - CatalogRef.Currencies         - optional parameter
//                                                             . If not specified, Balances for all currencies will be received.
//   *IssuancePurpose            - CatalogRef.CashFlowReportItems - optional parameter
//                                                               . If not specified, Balances for all targets will be received.
//
// Returns:
//  QueryResultSelection:
//   *Organization                    - CatalogRef.Companies,
//   *Department                  - CatalogRef.BusinessStructure,
//   *AdvanceHolder                - CatalogRef.Persons,
//   *IssuancePurpose                     - CatalogRef.CashFlowReportItems,
//   *Currency                         - CatalogRef.Currencies,
//   *Sum                          - Number,
//   *SumCompl                      - Number,
//   *SumMan                       - Number,
//   *DateOfLastAdvanceReport - Date
//
Function SamplingBalances(ParametersForObtainingBalances) Export
	
	Query = New Query;
	Query.SetParameter("BoundaryOfResidues", New Boundary(ParametersForObtainingBalances.Date, BoundaryType.Excluding));
	Query.SetParameter("Organization",   ParametersForObtainingBalances.Organization);
	Query.SetParameter("Department", ParametersForObtainingBalances.Department);
	Query.SetParameter("ThisIsDebtToBeARAPWriteOff",
		ParametersForObtainingBalances.BusinessOperation =
			Enums.BusinessTransactions.AdvanceHolderARAPWriteOff);
		
	OptionalParameters = New Array;
	OptionalParameters.Add("AdvanceHolder");
	OptionalParameters.Add("IssuancePurpose");
	OptionalParameters.Add("Currency");
	
	ArrayOfParameterTexts = New Array;
	ArrayOfParameterTexts.Add("TRUE");
	For Each ParameterName In OptionalParameters Do
		ParameterValue = ParametersForObtainingBalances[ParameterName];
		If ValueIsFilled(ParameterValue) Then
			ArrayOfParameterTexts.Add(StrReplace("ParameterName = &ParameterName", "ParameterName", ParameterName));
			Query.SetParameter(ParameterName, ParameterValue);
		EndIf;
	EndDo;
		
	Query.Text =
	"SELECT
	|	AdvanceHolderCashBalance.Organization AS Organization,
	|	AdvanceHolderCashBalance.Department AS Department,
	|	AdvanceHolderCashBalance.AdvanceHolder AS AdvanceHolder,
	|	AdvanceHolderCashBalance.IssuancePurpose AS IssuancePurpose,
	|	AdvanceHolderCashBalance.Currency AS Currency,
	|	CASE
	|		WHEN NOT &ThisIsDebtToBeARAPWriteOff
	|			THEN -1
	|		ELSE 1
	|	END * AdvanceHolderCashBalance.SumBalance AS SumBalance,
	|	CASE
	|		WHEN NOT &ThisIsDebtToBeARAPWriteOff
	|			THEN -1
	|		ELSE 1
	|	END * AdvanceHolderCashBalance.SumManBalance AS SumManBalance,
	|	CASE
	|		WHEN NOT &ThisIsDebtToBeARAPWriteOff
	|			THEN -1
	|		ELSE 1
	|	END * AdvanceHolderCashBalance.SumComplBalance AS SumComplBalance
	|INTO TTBalanceOfFunds
	|FROM
	|	AccumulationRegister.AdvanceHolderCash.Balance(
	|			&BoundaryOfResidues,
	|			Organization = &Organization
	|				AND Department = &Department
	|				AND &AdditionalSelection) AS AdvanceHolderCashBalance
	|WHERE
	|	CASE
	|			WHEN &ThisIsDebtToBeARAPWriteOff
	|				THEN AdvanceHolderCashBalance.SumBalance > 0
	|			ELSE AdvanceHolderCashBalance.SumBalance < 0
	|		END
	|INDEX BY
	|	Organization,
	|	AdvanceHolder,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalancesOfCash.Organization AS Organization,
	|	BalancesOfCash.Department AS Department,
	|	BalancesOfCash.AdvanceHolder AS AdvanceHolder,
	|	BalancesOfCash.IssuancePurpose AS IssuancePurpose,
	|	BalancesOfCash.Currency AS Currency,
	|	BalancesOfCash.SumBalance AS Sum,
	|	BalancesOfCash.SumManBalance AS SumMan,
	|	BalancesOfCash.SumComplBalance AS SumCompl,
	|	MAX(ISNULL(Document.Date,DATETIME(1,1,1))) AS DateOfLastAdvanceReport
	|FROM
	|	TTBalanceOfFunds AS BalancesOfCash
	|		LEFT JOIN Document.ExpenseReport AS Document
	|		ON (Document.Organization = BalancesOfCash.Organization)
	|			AND (Document.AdvanceHolder = BalancesOfCash.AdvanceHolder)
	|			AND (Document.Department = BalancesOfCash.Department)
	|			AND Document.Posted
	|GROUP BY
	|	BalancesOfCash.Organization,
	|	BalancesOfCash.Department,
	|	BalancesOfCash.AdvanceHolder,
	|	BalancesOfCash.IssuancePurpose,
	|	BalancesOfCash.Currency,
	|	BalancesOfCash.SumBalance,
	|	BalancesOfCash.SumManBalance,
	|	BalancesOfCash.SumComplBalance
	|";
	
	Query.Text = StrReplace(Query.Text, "&AdditionalSelection", StrConcat(ArrayOfParameterTexts, " And "));
	Return Query.Execute().Select();
	
EndFunction

// Recalculates the Local and Man amounts of the line being edited
//
// Parameters:
//  LineToEdit - FormDataStructure - the row of the form table in which the recalculation should take place
//  ParametersForObtainingBalances - Structure:
//   *Date                  - Date - the date on which the Balances will be received.
//   *Organization           - CatalogRef.Companies
//   *Department         - CatalogRef.BusinessStructure
//   *BusinessOperation - EnumRef.BusinessTransactions - determines the nature of the resulting Balance.
//                                                     if a household is specified. The write-off Operation
//                                                     is due to the reporting face, then positive Balances will be received.
//                                                     Otherwise, negative Balances will be obtained.
//   *AdvanceHolder       - CatalogRef.Persons - optional parameter
//                                                   . If omitted, Balances for all reporting entities will be received.
//   *Currency                - CatalogRef.Currencies         - optional parameter
//                                                             . If not specified, Balances for all currencies will be received.
//   *IssuancePurpose            - CatalogRef.CashFlowReportItems - optional parameter
//                                                               . If not specified, Balances for all targets will be received.
//
Procedure RecalculateLocalAndManAmounts(LineToEdit, ParametersForObtainingBalances) Export
	
	SamplingBalances = SamplingBalances(ParametersForObtainingBalances);
	If SamplingBalances.Next() Then
		
		If Not SamplingBalances.Sum = 0 Then
			
			LineToEdit.SumCompl = SamplingBalances.SumCompl * LineToEdit.Sum / SamplingBalances.Sum;
			LineToEdit.SumMan  = SamplingBalances.SumMan * LineToEdit.Sum / SamplingBalances.Sum;
			
		EndIf;
		
	Else
			
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(LineToEdit.Currency,
			                                                                     LineToEdit.Currency,
			                                                                     ParametersForObtainingBalances.Date,
			                                                                     ParametersForObtainingBalances.Organization);
			
		LineToEdit.SumCompl = LineToEdit.Sum * Coefficients.FactorOfConversionToCurrencyOfRegul;
		LineToEdit.SumMan  = LineToEdit.Sum * Coefficients.FactorOfConversionToCurrencyOfRegul;
		
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	
EndProcedure

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Parameters:
//  Query - Query
//  QueryTexts - ValueList of String
//
// Returns:
//	String - Query text
//
Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

// The procedure generates the text for the request for the register of information summationdocumentsaccount
//
// Parameters:
//  Query - Query
//  QueryTexts - ValueList of String
//  Registers - Structure, String, Undefined - list of names of registers for which the formation of tables is required.
//
Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Registers <> Undefined And Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	If DocumentsPosting.ThereIsQueryTable("DocumentAmountsInAccountingCurrency", QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts);
	
	Text = "
	|////////////////////////////////////////////////////////////////////////////////
	|// Table DocumentAmountsInAccountingCurrency
	|"+
	"SELECT
	|	*
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

// The function returns the adapted Query Text
//
// Parameters:
//  RegisterName - String - the name of the register for which the adapted Query Text is generated
//
// Returns:
//  String
Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.AdjustmentOfARAPAccountingForAdvanceHolders";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
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

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Fills in the access restriction text
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Department)
	|	AND ValueAllowed(ARAPAdjustment.AdvanceHolder, NULL AS TRUE)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	Presentation = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = '%1 %2 ngày %3';
			|ru = '%1 %2 от %3';
			|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
			|it = '%1 %2 del %3';
			|pl = '%1 %2 z dnia %3';
			|tr = '%3 tarihli %1 %2'"),
		Data.BusinessOperation,
		Data.Number,
		Data.Date);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Posting

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.Department AS Department,
	|	DocumentData.Author AS Author,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",
	              Common.MetadataObjectID("Document.AdjustmentOfARAPAccountingForAdvanceHolders"));
	Values.Insert("ControlIssueOfCashByPurposes",
	                  GetFunctionalOption("ControlIssueOfCashByPurposes"));
	Values.Insert("UseAccountingOfOtherIncomeExpenses",
	                  GetFunctionalOption("UseAccountingOfOtherIncomeExpenses"));
	Values.Insert("UseAccountingOfOtherAssetsAndLiabilities",
	                  GetFunctionalOption("UseAccountingOfOtherAssetsAndLiabilities"));
	
	If Not Attributes = Undefined Then
		Values.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextTableTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts)
	
	RegisterName = "DocumentAmountsInLocalCurrency";
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS Period,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.Currency AS Currency,
	|	DocumentTable.Currency AS DocumentCurrency,
	|	DocumentTable.Currency AS ARAPCurrency,
	|	UNDEFINED AS VATRate,
	|	UNDEFINED AS VATBasePeriod,
	|	UNDEFINED AS ARAPObject,
	|	FALSE AS RecordedInARAPAccounting,
	|	0 AS AmountVATARAP,
	|	0 AS VATAmount,
	|	0 AS VATAmountCompl,
	|	0 AS VATAmountMan,
	|	DocumentTable.Sum AS AmountARAP,
	|	DocumentTable.Sum AS AmountIncludingVAT,
	|	DocumentTable.Sum AS AmountExcludingVAT,
	|	DocumentTable.SumCompl AS AmountExcludingVATCompl,
	|	DocumentTable.SumMan AS AmountExcludingVATMan
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentTable
	|WHERE
	|	DocumentTable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction // The text of the tablequestionsummydocumentsvaluteregl()

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Department AS StorageLocation,
	|	&Department AS Department,
	|	&Author AS EmployeeResponsible,
	|	&Author AS Author,
	|	DocumentData.Comment AS Comment,
	|	UNDEFINED AS Currency,
	|	UNDEFINED AS Sum,
	|	&Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS RecordSeparator,
	|	"""" AS More,
	|	&Period AS SourceDocumentDate,
	|	&NumberForPrinting AS SourceDocumentNumber,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableAdvanceHolderCash(Query, QueryTexts, Registers)
	
	RegisterName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN &BusinessOperation =
	|				  VALUE(Enum.BusinessTransactions.RecognitionOfDebtToAdvanceHolderAsIncome)
	|			THEN VALUE(AccumulationRecordType.Receipt)
	|		ELSE VALUE(AccumulationRecordType.Expense)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	DocumentTable.AdvanceHolder AS AdvanceHolder,
	|	&Department AS Department,
	|	DocumentTable.Currency AS Currency,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		DocumentTable.IssuancePurpose
	|	END AS IssuancePurpose,
	|	DocumentTable.Sum AS Sum,
	|	DocumentTable.SumMan AS SumMan,
	|	DocumentTable.SumCompl AS SumCompl,
	|	DocumentTable.Sum AS ToReport,
	|	&BusinessOperation AS BusinessOperation,
	|	CASE WHEN &ControlIssueOfCashByPurposes THEN
	|		DocumentTable.IssuancePurpose
	|	END AS CashFlowItem,
	|	DocumentTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
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
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	DocumentData.AssetRef AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses AS DimensionOfExpenses,
	|	&Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS VATActivityType,
	|	DocumentData.SumMan AS AmountIncludingVAT,
	|	DocumentData.SumMan AS AmountExcludingVAT,
	|	DocumentData.SumMan AS AmountExcludingVATMan,
	|	DocumentData.SumCompl AS AmountIncludingVATCompl,
	|	DocumentData.SumCompl AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	0 AS CostTD,
	|	&BusinessOperation BusinessOperation,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	DocumentData.RowID AS FinRecordID,
	|	""""  AS RowID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentData
	|	INNER JOIN ChartOfCharacteristicTypes.ExpenseItems AS ExpenseItems
	|	ON DocumentData.AssetRef = ExpenseItems.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AdvanceHolderARAPWriteOff)
	|";
	
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
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	CASE
	|		WHEN &BusinessOperation =
	|				  VALUE(Enum.BusinessTransactions.RecognitionOfDebtToAdvanceHolderAsIncome)
	|			THEN VALUE(AccumulationRecordType.Expense)
	|		ELSE VALUE(AccumulationRecordType.Receipt)
	|	END AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.AssetRef AS AssetRef,
	|	DocumentData.AssetsLiabilitiesDimension AS Dimension,
	|	DocumentData.SumMan AS Sum
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.AssetRef REFS ChartOfCharacteristicTypes.AssetLiabilityItems";
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(QueryText);
	ArrayOfTexts.Add(AccumulationRegisters.OtherAssetsLiabilities.QueryTextTableOtherAssetsLiabilities(False));
	
	QueryTexts.Add(StrConcat(ArrayOfTexts, TMCommonUse.QuerySeparatorInJoin()), RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.AssetRef AS IncomeItem,
	|	DocumentData.DimensionOfRevenue AS DimensionOfRevenue,
	|	&BusinessOperation AS BusinessOperation,
	|	DocumentData.SumMan AS Sum,
	|	DocumentData.SumMan AS SumMan,
	|	DocumentData.SumCompl AS SumCompl,
	|	DocumentData.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentData
	|	INNER JOIN ChartOfCharacteristicTypes.IncomeItems AS IncomeItems
	|	ON DocumentData.AssetRef = IncomeItems.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UseAccountingOfOtherIncomeExpenses
	|	AND DocumentData.AssetRef <> UNDEFINED
	|	AND &BusinessOperation =
	|				VALUE(Enum.BusinessTransactions.RecognitionOfDebtToAdvanceHolderAsIncome)
	|
	|ORDER BY
	|	DocumentData.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	&Organization AS Organization,
	|	&Department AS Department,
	|	UNDEFINED AS LineOfBusiness,
	|	DocumentData.AssetRef AS AssetRef,
	|	DocumentData.AssetsLiabilitiesDimension AS Dimension,
	|	DocumentData.GLAccountSettings AS GLAccountSettings,
	|	CASE
	|		WHEN &BusinessOperation =
	|				  VALUE(Enum.BusinessTransactions.AdvanceHolderARAPWriteOff)
	|			THEN VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)
	|		ELSE VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit)
	|	END AS DebitCredit,
	|
	|	DocumentData.SumCompl AS SumCompl,
	|	DocumentData.SumMan AS SumMan,
	|	DocumentData.SumMan AS AmountIncludingVAT,
	|	DocumentData.SumMan AS AmountExcludingVAT,
	|	
	|	DocumentData.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	Document.AdjustmentOfARAPAccountingForAdvanceHolders.ARAPAdjustment AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.AssetRef REFS ChartOfCharacteristicTypes.AssetLiabilityItems
	|	AND DocumentData.AssetRef <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndIf