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
		"Organization, Department, CashFlowItem", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author, Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"BankAccount, CashAccount", Parameters);
		
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization, Department";
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
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CashDepositWithdrawalDiscrepanciesLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.CashDepositWithdrawalDiscrepancies") Then
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
		QueryTextCashInTransit(Query, QueryTexts, Registers);
		QueryTextRecordsCashIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableOtherAssetsLiabilities(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CashDepositWithdrawalDiscrepanciesLocalization.AddRequestTexts(Query,
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
	
	CashDepositWithdrawalDiscrepanciesLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "Reflection of discrepancies in cash collection".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  - ValueTableRow - a data string defining the parameters of the input command based on.
//  - Undefined - if there is no right to create a document "Reflection of discrepancies in cash collection".
//
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CashDepositWithdrawalDiscrepancies) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CashDepositWithdrawalDiscrepancies.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CashDepositWithdrawalDiscrepancies);
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
	
	CashDepositWithdrawalDiscrepanciesLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CashDepositWithdrawalDiscrepanciesLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CashDepositWithdrawalDiscrepanciesLocalization.RequestTextTTReflectedInLocalAccounting();

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
	
	ChoiceParameters.AvailabilityByOperation = 
			(BusinessOperation = Enums.BusinessTransactions.RecordShortageOnCashCollection);
	
	#Region DimensionOfExpenses
	ChoiceParameters.ChoosingExpenseItem = ChoiceParameters.AvailabilityByOperation;
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
	
	ChoiceParameters.AvailabilityByOperation = (BusinessOperation = Enums.BusinessTransactions.RecordSurplusDuringCashCollection);
	
	#Region DimensionOfRevenue
	ChoiceParameters.ChoosingIncomeItem = ChoiceParameters.AvailabilityByOperation;
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
	
	FullDocumentName = Metadata.Documents.CashDepositWithdrawalDiscrepancies.FullName();
	MetadataObjectID = Common.MetadataObjectID(FullDocumentName);
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 			= Enums.BusinessTransactions.RecordShortageOnCashCollection;
	String.MetadataObjectID 	= MetadataObjectID;
	String.FullDocumentName 				= FullDocumentName;
	String.PurposeUseKey 		= "CashDepositWithdrawalDiscrepancies";
	String.WorkplaceTitle 			= NStr("vi = 'Phản ánh chênh lệch khi chuyển tiền nội bộ';
											|ru = 'Отражение расхождений при инкассации денежных средств';
											|en = 'Cash deposit/withdrawal discrepancies'; fa = 'مغایرت‌های واریز/برداشت وجه نقد';
											|it = 'Rilevazione delle discrepanze all''incasso del denaro';
											|pl = 'Odzwierciedlenie odchylenia podczas inkasacji środków pieniężnych';
											|tr = 'Nakit yatırma sırasında tutarsızlıkların yansıtılması'");
	String.Order 							= 1;
	String.AddButtonCreate 			= True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 			= Enums.BusinessTransactions.RecordSurplusDuringCashCollection;
	String.MetadataObjectID 	= MetadataObjectID;
	String.FullDocumentName 				= FullDocumentName;
	String.PurposeUseKey 		= "CashDepositWithdrawalDiscrepancies";
	String.WorkplaceTitle 			= NStr("vi = 'Phản ánh chênh lệch khi chuyển tiền nội bộ';
											|ru = 'Отражение расхождений при инкассации денежных средств';
											|en = 'Cash deposit/withdrawal discrepancies'; fa = 'مغایرت‌های واریز/برداشت وجه نقد';
											|it = 'Rilevazione delle discrepanze all''incasso del denaro';
											|pl = 'Odzwierciedlenie odchylenia podczas inkasacji środków pieniężnych';
											|tr = 'Nakit yatırma sırasında tutarsızlıkların yansıtılması'");
	String.Order 							= 2;
	String.AddButtonCreate 			= True;
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								New ValueList, 
								New ValueList, 
								"");
	
	Return TableOfValuesAvailable;
	
EndFunction

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
	
	FullDocumentName = "Document.CashDepositWithdrawalDiscrepancies";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("AmountInCurrency", "Sum");
	
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
			QueryText, FullDocumentName, "", False, RedefiningParameterCalculation);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, "");
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = "
	|SELECT
	|	DocumentData.Date                                                        AS Period,
	|	DocumentData.Organization                                                 AS Organization,
	|	DocumentData.BusinessOperation                                       AS BusinessOperation,
	|	DocumentData.BankAccount                                              AS BankAccount,
	|	DocumentData.CashAccount                                                       AS CashAccount,
	|	DocumentData.Sum                                                       AS AmountInCurrency,
	|	DocumentData.Currency                                                      AS Currency,    
	|	DocumentData.CorrectedDocument.Date									AS AdjustmentPeriod_,
	|	
	|	DocumentData.Department                                               AS Department,
	|	DocumentData.BankAccount.Department                                AS BankAccountDivision,
	|	DocumentData.BankAccount.LineOfBusiness                      AS LineOfBusiness,
	|	DocumentData.IncomeItem                                               AS IncomeItem,
	|	DocumentData.DimensionOfRevenue                                            AS DimensionOfRevenue,
	|	DocumentData.ExpenseItem                                              AS ExpenseItem,
	|	DocumentData.ExpenseItem.EnteredInTaxAccounting                     AS EnteredInTaxAccounting,
	|	DocumentData.DimensionOfExpenses                                           AS DimensionOfExpenses,
	|	
	|	DocumentData.CashFlowItem                               AS CashFlowItem,
	|	
	|	DocumentData.EmployeeResponsible                                               AS EmployeeResponsible,
	|	DocumentData.Author                                                       AS Author,
	|	DocumentData.Number                                                       AS Number,
	|	DocumentData.Comment                                                 AS Comment,
	|	DocumentData.DeletionMark                                             AS DeletionMark,
	|	DocumentData.Patch                                                 AS Patch,
	|	DocumentData.ReversedDocument                                        AS ReversedDocument,
	|	DocumentData.CorrectedDocument                                        AS CorrectedDocument,
	|	DocumentData.Posted                                                    AS Posted,
	|	DocumentData.DocumentID                                      AS DocumentID,
	|	BusinessTransactionsSettings.Ref                                       AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.CashDepositWithdrawalDiscrepancies AS DocumentData
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
	
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                         Common.MetadataObjectID("Document.CashDepositWithdrawalDiscrepancies"));
	Values.Insert("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",              Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",             Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("NumberForPrinting",                               ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
		
	EndIf;
	
	Return Values;
	
EndFunction

Function QueryTextOtherIncome(Query, QueryTexts, Registers)
	
	RegisterName = "OtherIncome";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period                                      AS Period,
	|	
	|	&Organization                                 AS Organization,
	|	&AdjustmentPeriod_                         AS AdjustmentPeriod_,
	|	&Department                               AS Department,
	|	&LineOfBusiness                     AS LineOfBusiness,
	|	&IncomeItem                               AS IncomeItem,
	|	&DimensionOfRevenue                            AS DimensionOfRevenue,
	|	
	|	&AmountInCurrency * &ConversionRateToManCurrency AS Sum,
	|	CASE
	|		WHEN &CompanyManagementAccounting
	|			THEN &AmountInCurrency * &ConversionRateToManCurrency
	|		ELSE 0
	|	END                                        AS SumMan,
	|	CASE
	|		WHEN &UseAccountingOfOtherIncomeExpensesInLocalAccounting
	|			THEN &AmountInCurrency * &FactorOfConversionToCurrencyOfRegul
	|		ELSE 0
	|	END                                        AS SumCompl,
	|	
	|	&BusinessOperation                       AS BusinessOperation,
	|
	|	&DocumentID                      AS FinRecordID,
	|	&BusinessTransactionSetting              AS BusinessTransactionSetting
	|	
	|WHERE
	|	&BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	&Period                                      AS Period,
	|	&AdjustmentPeriod_                         AS VariancePeriod,
	|	&Organization                                 AS Organization,
	|	&Department                               AS Department,
	|	&LineOfBusiness                     AS LineOfBusiness,
	|	DocumentData.ExpenseItem               AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses            AS DimensionOfExpenses,
	|	UNDEFINED                                 AS VATActivityType,
	|	
	|	&AmountInCurrency * &ConversionRateToManCurrency AS AmountIncludingVAT,
	|	&AmountInCurrency * &ConversionRateToManCurrency AS AmountExcludingVAT,
	|	&AmountInCurrency * &ConversionRateToManCurrency AS AmountExcludingVATMan,
	|	&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul AS AmountIncludingVATCompl,
	|	&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul AS AmountExcludingVATCompl,
	|	0                                            AS PermanentDifference,
	|	0                                            AS CostTD,
	|	&BusinessOperation                       AS BusinessOperation,
	|	UNDEFINED                                 AS ItemsLocationAttributes,
	|	
	|	DocumentData.DocumentID       AS FinRecordID,
	|	&BusinessTransactionSetting              AS BusinessTransactionSetting
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	Document.CashDepositWithdrawalDiscrepancies AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection)";
	
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
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                            AS RecordType,
	|	&Period                                                           AS Period,
	|	
	|	&Organization                                                      AS Organization,
	|	&Department                                                    AS Department,
	|	&Ref                                                           AS ExpenseReceiptDocument,
	|	DocumentData.ExpenseItem                                    AS ExpenseItem,
	|	DocumentData.DimensionOfExpenses                                 AS DimensionOfExpenses,
	|	UNDEFINED                                                      AS AssetsLiabilitiesDimension,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef)       AS LotVendorAttributes,
	|	&LineOfBusiness                                          AS LineOfBusiness,
	|	UNDEFINED                                                      AS ItemsLocationAttributes,
	|	UNDEFINED                                                      AS VATActivityType,
	|	
	|	&AmountInCurrency * &ConversionRateToManCurrency                   AS Cost,
	|	&AmountInCurrency * &ConversionRateToManCurrency                   AS CostExcludingVAT,
	|	0                                                                 AS VATManag,
	|	&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul                  AS LocalCost,	
	|	0                                                                 AS PermanentDifference,
	|	0                                                                 AS CostTD,
	|	0                                                                 AS VATLocal,
	|	&BusinessOperation                                            AS BusinessOperation,
	|
	|	DocumentData.DocumentID                            AS FinRecordID,
	|	&BusinessTransactionSetting                                   AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	Document.CashDepositWithdrawalDiscrepancies AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection)";
	
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

Function QueryTextCashInTransit(Query, QueryTexts, Registers)
	
	RegisterName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)                                     AS RecordType,
	|	&Period                                                                    AS Period,
	|	
	|	&Organization                                                               AS Organization,
	|	&BankAccount                                                            AS Recipient,
	|	&CashAccount                                                                     AS Sender,
	|	VALUE(Enum.CashTransferKinds.CashDepositToBank)        AS CashTransferKind,
	|	UNDEFINED                                                               AS Counterparty,
	|	&Currency                                                                    AS Currency,
	|	
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection) THEN
	|		&AmountInCurrency
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection) THEN
	|		-&AmountInCurrency
	|	END AS Sum,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection) THEN
	|		&AmountInCurrency * &ConversionRateToManCurrency
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection) THEN
	|		-&AmountInCurrency * &ConversionRateToManCurrency
	|	END AS SumMan,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection) THEN
	|		&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection) THEN
	|		-&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul
	|	END AS SumCompl,
	|	
	|	&BusinessOperation                                                     AS BusinessOperation,
	|	&CashFlowItem                                             AS CashFlowItem,
	|
	|	&DocumentID                                                    AS FinRecordID,
	|	&BusinessTransactionSetting                                            AS BusinessTransactionSetting
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextRecordsCashIncomeExpenses(Query, QueryTexts, Registers)

	RegisterName = "RecordsCashIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	&BusinessOperation AS BusinessOperation,
	|	&Organization AS Organization,
	|	&BankAccountDivision AS Department,
	|	&LineOfBusiness     AS LineOfBusinessCash,
	|	&Department               AS IncomeExpenseBusinessUnit,
	|
	|	DocumentData.CashAccount AS Cash,
	|	VALUE(Enum.CashTypes.CashInTransit) AS CashType,
	|	&CashFlowItem AS CashFlowItem,
	|	&Currency AS Currency,
	|
	|	&LineOfBusiness     AS LineOfBusinessItems,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection) THEN
	|		&ExpenseItem
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection) THEN
	|		&IncomeItem
	|	END AS IncomeAndExpenseItem,
	|	&DimensionOfRevenue AS DimensionOfRevenue,
	|	&DimensionOfExpenses AS DimensionOfExpenses,
	|
	|	&AmountInCurrency * &ConversionRateToManCurrency AS Sum,
	|	&AmountInCurrency * &FactorOfConversionToCurrencyOfRegul AS SumCompl,
	|	&AmountInCurrency AS AmountInCurrency,
	|
	|	DocumentData.CashAccount AS SourceOfCashFinancialAccountingGroup,
	|	CASE WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordShortageOnCashCollection) THEN
	|		&ExpenseItem
	|	WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.RecordSurplusDuringCashCollection) THEN
	|		&IncomeItem
	|	END AS SourceOfIncomeExpensesFinancialAccountingGroup
	|FROM
	|	Document.CashDepositWithdrawalDiscrepancies AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	|	""CashDepositWithdrawalDiscrepancies"" AS DataSource,
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
	|	"""" AS RowID,
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
	|	Document.CashDepositWithdrawalDiscrepancies AS DocumentTable
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
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	UNDEFINED                            AS Partner,
	|	&BankAccount                         AS StorageLocation,
	|	UNDEFINED                            AS Counterparty,
	|	&Department                          AS Department,
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
	|	&AmountInCurrency                           AS Sum,
	|	&Currency                                 AS Currency,
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
	Return;
	CashDepositWithdrawalDiscrepanciesLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#EndRegion

#EndIf
