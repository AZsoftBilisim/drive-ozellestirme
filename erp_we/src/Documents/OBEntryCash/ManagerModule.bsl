#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	
	If TypeOf(Document) = Type("DocumentObject.OBEntryCash") Then
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
	QueryTextTableCashAccountBalance(Query, QueryTexts, Registers);
	QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers);
	QueryTextTableBankAccountCash(Query, QueryTexts, Registers);
	QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
	
	OBEntryLocalization.EnteringCashBalancesAddRequestTexts(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(Query, QueryTexts, Registers, EmptyRef().Metadata());
	
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
	
	DocumentMechanisms.Add("CashManagement");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentCorrection");
	DocumentMechanisms.Add("FinancialAccounting");
	OBEntryLocalization.EnteringCashBalancesAndAccountingMechanisms(DocumentMechanisms);
	
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
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
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
	OBEntryLocalization.EnteringCashBalancesAddReportCommands(ReportsCommands, Parameters);
EndProcedure

#EndRegion
#Region ConductingRegulatedAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	Return OBEntryLocalization.EnteringCashBalancesForReflectionInLocalAccounting();
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//  String - Containing the text of the request for temporary tables to be reflected in the regl. accounting.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	Return OBEntryLocalization.CashRequestTextTTReflectedInLocalAccounting();
EndFunction

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
	
	DateOfRemainingGoods = New Boundary(Date, BoundaryType.Including);
	
	If BusinessOperation = Enums.BusinessTransactions.OBEntryCashInHand Then
		Return CashBalances_1(DateOfRemainingGoods, Companies);
	ElsIf BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts Then
		Return BankAccountBalances(DateOfRemainingGoods, Companies);
	Else
		Return Undefined;
	EndIf;
	
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
	KeyFieldsArray.Add("Organization");	
	
	Return KeyFieldsArray;
	
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
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Documents.OBEntryCash);
	
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
	|	";

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

#Region InitializationAndFilling

// To initialize the document
//
// Parameters:
//  Object           - DocumentObject - the document being processed.
//  FillingData - Structure - fill-in data.
//  StandardProcessing - Boolean - platoon the flag of refusal from standard processing of filling in the document.
Procedure InitializeDocument(Object, FillingData = Undefined, StandardProcessing = True) Export
	
	Organization               = Catalogs.Companies.EmptyRef();
	Currency                    = Catalogs.Currencies.EmptyRef();
	BusinessOperation     = Enums.BusinessTransactions.EmptyRef();
	Comment               = "";
	PostInFinancialAndTaxAccounting            = False;
	RecordInOperationalAccounting = False;
	RecordInMA               = False;
	
	If FillingData <> Undefined Then
		
		If FillingData.Property("Organization") Then
			Organization = FillingData.Organization;
		EndIf;
		
		If FillingData.Property("Currency") Then
			Currency = FillingData.Currency;
		EndIf;
		
		If FillingData.Property("BusinessOperation") Then
			BusinessOperation = FillingData.BusinessOperation;
		EndIf;
		
		If FillingData.Property("Comment") Then
			Comment = FillingData.Comment;
		EndIf;
		
		If FillingData.Property("PostInFinancialAndTaxAccounting") Then
			PostInFinancialAndTaxAccounting = FillingData.PostInFinancialAndTaxAccounting;
		EndIf;
		
		If FillingData.Property("RecordInOperationalAccounting") Then
			RecordInOperationalAccounting = FillingData.RecordInOperationalAccounting;
		EndIf;
		
		If FillingData.Property("RecordInMA") Then
			RecordInMA = FillingData.RecordInMA;
		EndIf;
		
		If FillingData.Property("CopyingValue") Then
			OBEntryServer.FillInValuesForOldInputBalances(Object, FillingData.CopyingValue);
		EndIf;
		
	EndIf;
	
	//Organization
	If Not ValueIsFilled(Object.Organization) Then
		If Not ValueIsFilled(Organization)
			And Not GetFunctionalOption("UseMultipleCompanies") Then
			Object.Organization = SettingsValueCached.GetDefaultOrganization();
		Else
			Object.Organization = Organization;
		EndIf;
	EndIf;
	
	//Currency
	If Not ValueIsFilled(Object.Currency) Then
		If Not ValueIsFilled(Currency) Then
			Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		Else
			Object.Currency = Currency;
		EndIf;
	EndIf;
	
	//BusinessOperation
	If Not ValueIsFilled(Object.BusinessOperation) Then
		If Not ValueIsFilled(BusinessOperation) Then
			Object.BusinessOperation = Enums.BusinessTransactions.OBEntryCashInBankAccounts;
		Else
			Object.BusinessOperation = BusinessOperation;
		EndIf;
	EndIf;
	
	//Ways of reflection in accounting
	If PostInFinancialAndTaxAccounting Then
		Object.PostInFinancialAndTaxAccounting = PostInFinancialAndTaxAccounting;
	EndIf;
	
	If RecordInOperationalAccounting Then
		Object.RecordInOperationalAccounting = RecordInOperationalAccounting;
	EndIf;
	
	If RecordInMA Then
		Object.RecordInMA = RecordInMA;
	EndIf;
	
	//Comment
	If Not ValueIsFilled(Object.Comment) Then
		Object.Comment = Comment;
	EndIf;
	
	OBEntryLocalization.EnteringCashBalancesProcessingFilling(Object, FillingData, StandardProcessing);
	
EndProcedure

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

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	
	Fields.Add("Ref");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("BusinessOperation");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If Data.Ref <> Undefined Then
		Presentation = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Data,
			Data.Number,
			Data.Date,
			Data.BusinessOperation);
	EndIf;
	
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
	Query.Text ="SELECT
		|	DocumentData.Date AS Period,
		|	DocumentData.Number AS Number,
		|	DocumentData.Ref AS Ref,
		|	DocumentData.Organization AS Organization,
		|	DocumentData.Currency AS Currency,
		|	DocumentData.BusinessOperation AS BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting AS RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting AS PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA AS RecordInMA,
		|	CAST(DocumentData.Comment AS STRING(100)) AS Comment,
		|	DocumentData.Posted AS Posted,
		|	DocumentData.DeletionMark AS DeletionMark,
		|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
		|	DocumentData.Author AS Author,
		|	DocumentData.Patch AS Patch,
		|	DocumentData.ReversedDocument AS ReversedDocument,
		|	DocumentData.CorrectedDocument AS CorrectedDocument,
		|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting,
		|	SUM(ISNULL(CheckoutTabularData.Sum, 0) + ISNULL(TabularDataBankAccounts.Sum, 0) + ISNULL(CashRegisterTabularData.Sum, 0)) AS Sum
		|FROM
		|	Document.OBEntryCash AS DocumentData
		|		LEFT JOIN Document.OBEntryCash.CashAccounts AS CheckoutTabularData
		|		ON DocumentData.Ref = CheckoutTabularData.Ref
		|		LEFT JOIN Document.OBEntryCash.BankAccounts AS TabularDataBankAccounts
		|		ON DocumentData.Ref = TabularDataBankAccounts.Ref
		|		LEFT JOIN Document.OBEntryCash.CashRegisters AS CashRegisterTabularData
		|		ON DocumentData.Ref = CashRegisterTabularData.Ref
		|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
		|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
		|WHERE
		|	DocumentData.Ref = &Ref
		|
		|GROUP BY
		|	DocumentData.Date,
		|	DocumentData.Number,
		|	DocumentData.Ref,
		|	DocumentData.Organization,
		|	DocumentData.Currency,
		|	DocumentData.BusinessOperation,
		|	DocumentData.RecordInOperationalAccounting,
		|	DocumentData.PostInFinancialAndTaxAccounting,
		|	DocumentData.RecordInMA,
		|	DocumentData.Posted,
		|	DocumentData.DeletionMark,
		|	DocumentData.EmployeeResponsible,
		|	DocumentData.Patch,
		|	DocumentData.ReversedDocument,
		|	DocumentData.CorrectedDocument,
		|	CAST(DocumentData.Comment AS STRING(100)),
		|	BusinessTransactionsSettings.Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	Query.SetParameter("Period",                         Attributes.Period);
	Query.SetParameter("Number",                          Attributes.Number);
	Query.SetParameter("Organization",                    Attributes.Organization);
	Query.SetParameter("BusinessOperation",          Attributes.BusinessOperation);
	Query.SetParameter("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Query.SetParameter("ManagementAccountingCurrency",     Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("RecordInOperationalAccounting",      Attributes.RecordInOperationalAccounting);
	Query.SetParameter("PostInFinancialAndTaxAccounting",                 Attributes.PostInFinancialAndTaxAccounting);
	Query.SetParameter("RecordInMA",                    Attributes.RecordInMA);
	Query.SetParameter("Comment",                    Attributes.Comment);
	Query.SetParameter("Posted",                       Attributes.Posted);
	Query.SetParameter("DeletionMark",                Attributes.DeletionMark);
	Query.SetParameter("EmployeeResponsible",                  Attributes.EmployeeResponsible);
	Query.SetParameter("Author",                          Attributes.Author);
	Query.SetParameter("DocumentAmount",                 Attributes.Sum);
	Query.SetParameter("Currency",                         Attributes.Currency);
	Query.SetParameter("Patch",                    Attributes.Patch);
	Query.SetParameter("ReversedDocument",           Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument",           Attributes.CorrectedDocument);
	Query.SetParameter("BusinessTransactionSetting", Attributes.BusinessTransactionSetting);
	Query.SetParameter("MetadataIdentifier", 
		Common.MetadataObjectID("Document."+Metadata.Documents.OBEntryCash.Name));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function QueryTextTTExchangeRates(Query, QueryTexts)
	
	RegisterName = "TTExchangeRates";
	
	QueryText =
	"SELECT
	|	CurrencyRatesCut.Currency,
	|	CurrencyRatesCut.CourseNumerator / CurrencyRatesCut.CourseDenominator AS ConversionFactor_
	|	
	|INTO TTExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(
	|			&Period,
	|			Currency IN
	|				(SELECT
	|					&ManagementAccountingCurrency
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					CashAccounts.CashCurrency
	|				FROM
	|					Document.OBEntryCash.CashAccounts AS EnteringCheckoutBalances
	|						INNER JOIN Catalog.CashAccounts AS CashAccounts
	|						ON EnteringCheckoutBalances.CashAccount = CashAccounts.Ref
	|				WHERE
	|					EnteringCheckoutBalances.Ref = &Ref
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					CashRegisters.CashCurrency
	|				FROM
	|					Document.OBEntryCash.CashRegisters AS EnteringCashRegisterBalances
	|						INNER JOIN Catalog.CashRegisters AS CashRegisters
	|						ON EnteringCashRegisterBalances.CashRegister = CashRegisters.Ref
	|				WHERE
	|					EnteringCashRegisterBalances.Ref = &Ref
	|				
	|				UNION ALL
	|				
	|				SELECT DISTINCT
	|					CompaniesBankAccounts.CashCurrency
	|				FROM
	|					Document.OBEntryCash.BankAccounts AS EnteringBankAccountBalances
	|						INNER JOIN Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
	|						ON EnteringBankAccountBalances.BankAccount = CompaniesBankAccounts.Ref
	|				WHERE
	|					EnteringBankAccountBalances.Ref = &Ref
	|				)
	|				AND BaseCurrency = &LocalAccountingCurrency
	|	) AS CurrencyRatesCut";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashAccountBalance(Query, QueryTexts, Registers)
	
	RegisterName = "CashAccountBalance";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	CashAccountsTable.CashAccount                     AS CashAccount,
	|	CashAccountsTable.Sum                     AS Sum,
	|	CashAccountsTable.SumCompl                 AS SumCompl,
	|	CASE
	|		WHEN CashAccounts.CashCurrency = &ManagementAccountingCurrency
	|			THEN CashAccountsTable.Sum
	|		ELSE
	|			CashAccountsTable.Sum * ISNULL(CheckoutExchangeRates.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                  AS SumMan,
	|	CashAccountsTable.RowID       AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryCash.CashAccounts AS CashAccountsTable
	|		INNER JOIN Catalog.CashAccounts AS CashAccounts
	|			LEFT JOIN TTExchangeRates AS CheckoutExchangeRates
	|			ON CheckoutExchangeRates.Currency = CashAccounts.CashCurrency
	|			LEFT JOIN TTExchangeRates AS ManExchangeRates
	|			ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|		ON CashAccountsTable.CashAccount = CashAccounts.Ref
	|WHERE
	|	CashAccountsTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCashInHand)
	|
	|ORDER BY
	|	CashAccountsTable.LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableCashInCashRegistersCR(Query, QueryTexts, Registers)
	
	RegisterName = "CashInCashRegistersCR";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	CashAccountsTable.CashRegister                  AS CashRegister,
	|	CashAccountsTable.Sum                     AS Sum,
	|	CashAccountsTable.SumCompl                 AS SumCompl,
	|	CASE
	|		WHEN CashRegisters.CashCurrency = &ManagementAccountingCurrency
	|			THEN CashAccountsTable.Sum
	|		ELSE
	|			CashAccountsTable.Sum * ISNULL(CheckoutExchangeRates.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                  AS SumMan,
	|	CashAccountsTable.LineNumber               AS LineNumber,
	|	CashAccountsTable.RowID       AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryCash.CashRegisters AS CashAccountsTable
	|		INNER JOIN Catalog.CashRegisters AS CashRegisters
	|			LEFT JOIN TTExchangeRates AS CheckoutExchangeRates
	|			ON CheckoutExchangeRates.Currency = CashRegisters.CashCurrency
	|			LEFT JOIN TTExchangeRates AS ManExchangeRates
	|			ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|		ON CashAccountsTable.CashRegister = CashRegisters.Ref
	|WHERE
	|	CashAccountsTable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCashInRetailCashRegister)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	VALUE(AccumulationRecordType.Expense),
	|	&Organization,
	|	CashAccountsTable.CashRegister,
	|	CashAccountsTable.Sum,
	|	CashAccountsTable.SumCompl AS SumCompl,
	|	CASE
	|		WHEN CashRegisters.CashCurrency = &ManagementAccountingCurrency
	|			THEN CashAccountsTable.Sum
	|		ELSE
	|			CashAccountsTable.Sum * ISNULL(CheckoutExchangeRates.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END AS SumMan,
	|	CashAccountsTable.LineNumber AS LineNumber,
	|	CashAccountsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting  AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryCash.CashRegisters AS CashAccountsTable
	|		INNER JOIN Catalog.CashRegisters AS CashRegisters
	|			LEFT JOIN TTExchangeRates AS CheckoutExchangeRates
	|			ON CheckoutExchangeRates.Currency = CashRegisters.CashCurrency
	|			LEFT JOIN TTExchangeRates AS ManExchangeRates
	|			ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|		ON CashAccountsTable.CashRegister = CashRegisters.Ref
	|WHERE
	|	CashAccountsTable.Ref = &Ref
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryOpenSalesInvoicesFromRetailCashRegisters)
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableBankAccountCash(Query, QueryTexts, Registers)
	
	RegisterName = "BankAccountCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTExchangeRates", QueryTexts) Then
		QueryTextTTExchangeRates(Query, QueryTexts);
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization                           AS Organization,
	|	TableBankAccounts.BankAccount  AS BankAccount,
	|	TableBankAccounts.Sum           AS Sum,
	|	TableBankAccounts.SumCompl       AS SumCompl,
	|	CASE
	|		WHEN BankAccounts.CashCurrency = &ManagementAccountingCurrency
	|			THEN TableBankAccounts.Sum
	|		ELSE
	|			TableBankAccounts.Sum * ISNULL(AccountCurrencyRates.ConversionFactor_, 0) / ISNULL(ManExchangeRates.ConversionFactor_, 1)
	|	END                                  AS SumMan,
	|	TableBankAccounts.RowID AS FinRecordID,
	|	&BusinessTransactionSetting        AS BusinessTransactionSetting
	|FROM
	|	Document.OBEntryCash.BankAccounts AS TableBankAccounts
	|		INNER JOIN Catalog.CompaniesBankAccounts AS BankAccounts
	|			LEFT JOIN TTExchangeRates AS AccountCurrencyRates
	|			ON AccountCurrencyRates.Currency = BankAccounts.CashCurrency
	|			LEFT JOIN TTExchangeRates AS ManExchangeRates
	|			ON ManExchangeRates.Currency = &ManagementAccountingCurrency
	|		ON TableBankAccounts.BankAccount = BankAccounts.Ref
	|WHERE
	|	TableBankAccounts.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND &BusinessOperation = VALUE(Enum.BusinessTransactions.OBEntryCashInBankAccounts)
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
	
	QueryText = "SELECT
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
	|		WHEN COUNT(DISTINCT TabularDataBankAccounts.BankAccount.CashCurrency) > 1
	|				OR COUNT(DISTINCT CashRegisterTabularData.CashRegister.CashCurrency) > 1
	|				OR COUNT(DISTINCT CheckoutTabularData.CashAccount.CashCurrency) > 1 THEN UNDEFINED
	|		ELSE &Currency
	|	END AS Currency,
	|	UNDEFINED AS Contract,
	|	UNDEFINED AS LineOfBusiness,
	|	&Period AS RecordingInAccountingDate,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	CASE 
	|		WHEN COUNT(DISTINCT TabularDataBankAccounts.BankAccount.CashCurrency) > 1
	|				OR COUNT(DISTINCT CashRegisterTabularData.CashRegister.CashCurrency) > 1
	|				OR COUNT(DISTINCT CheckoutTabularData.CashAccount.CashCurrency) > 1 THEN 0
	|		ELSE SUM(ISNULL(CheckoutTabularData.Sum, 0) + ISNULL(TabularDataBankAccounts.Sum, 0) + ISNULL(CashRegisterTabularData.Sum, 0))
	|	END AS Sum,
	|	UNDEFINED AS Priority
	|FROM
	|	Document.OBEntryCash AS DocumentData
	|		LEFT JOIN Document.OBEntryCash.CashAccounts AS CheckoutTabularData
	|		ON DocumentData.Ref = CheckoutTabularData.Ref
	|		LEFT JOIN Document.OBEntryCash.BankAccounts AS TabularDataBankAccounts
	|		ON DocumentData.Ref = TabularDataBankAccounts.Ref
	|		LEFT JOIN Document.OBEntryCash.CashRegisters AS CashRegisterTabularData
	|		ON DocumentData.Ref = CashRegisterTabularData.Ref
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
	
	FullDocumentName = "Document.OBEntryCash";
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier", Common.MetadataObjectID(Metadata.Documents.OBEntryCash));
	
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
	
	OBEntryLocalization.EnteringCashBalancesAddPrintCommands(PrintCommands);
	
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

#Region ServiceProceduresForFillingInAccordingToOperationalAccountingData

Function CashBalances_1(DateOfRemainingGoods, Companies)
	
	Query = New Query;
	Query.Text = "SELECT
		|	""CashAccounts"" AS TablePartToFillIn,
		|	CashAccountBalanceBalance.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.OBEntryCashInHand) AS BusinessOperation,
		|	CashAccountBalanceBalance.CashAccount,
		|	SUM(CashAccountBalanceBalance.SumBalance) AS Sum,
		|	SUM(CashAccountBalanceBalance.SumComplBalance) AS SumCompl,
		|	SUM(CashAccountBalanceBalance.SumManBalance) AS SumMan
		|FROM
		|	AccumulationRegister.CashAccountBalance.Balance(&Date, Organization IN (&Companies)) AS CashAccountBalanceBalance
		|
		|GROUP BY
		|	CashAccountBalanceBalance.Organization,
		|	CashAccountBalanceBalance.CashAccount
		|
		|ORDER BY
		|	Organization";
	
	Query.Parameters.Insert("Companies", Companies);
	Query.Parameters.Insert("Date",                 DateOfRemainingGoods);
	
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
	
EndFunction

Function BankAccountBalances(DateOfRemainingGoods, Companies)
	
	Query = New Query;
	Query.Text = "SELECT
		|	""BankAccounts"" AS TablePartToFillIn,
		|	BankAccountCashBalance.Organization AS Organization,
		|	VALUE(Enum.BusinessTransactions.OBEntryCashInBankAccounts) AS BusinessOperation,
		|	BankAccountCashBalance.BankAccount,
		|	SUM(BankAccountCashBalance.SumBalance) AS Sum,
		|	SUM(BankAccountCashBalance.SumComplBalance) AS SumCompl,
		|	SUM(BankAccountCashBalance.SumManBalance) AS SumMan
		|FROM
		|	AccumulationRegister.BankAccountCash.Balance(&Date, Organization IN (&Companies)) AS BankAccountCashBalance
		|
		|GROUP BY
		|	BankAccountCashBalance.Organization,
		|	BankAccountCashBalance.BankAccount
		|
		|ORDER BY
		|	Organization";
	
	Query.Parameters.Insert("Companies", Companies);
	Query.Parameters.Insert("Date",                 DateOfRemainingGoods);
	
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
