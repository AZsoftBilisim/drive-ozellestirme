#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - ValueTable - for the composition of the fields, see the Print Management function.Create a collection of print commands.
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ForAllRows( ValueAllowed(EmployeesHR.Individual, NULL AS TRUE)
	|	) AND ValueAllowed(Organization)";
EndProcedure

// End StandardSubsystems.AccessManagement

// Returns information about the input command based on
//
// Parameters:
//  GenerationCommands - ValueTable - command table
// 
// Returns:
//  ValueTableRow - contains information about the properties of the command
//
Function AddGenerateCommand(GenerationCommands) Export

	If AccessRight("Insert", Metadata.Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount) Then
		
		Command = GenerationCommands.Add();
		Command.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount);
		Command.Manager = Metadata.Documents.BankConfirmationAboutCashReceiptOnEmployeeAccount.FullName();
		Command.WriteMode = "Post";
		
		Return Command;
		
	EndIf;
	
	Return Undefined;

EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	// PayrollCardProgram
	Item = Settings.Add();
	Item.Fields.Add("PayrollCardProgram");
	FinancialReportingServer.NewFilter(Item.Condition, "More.UsePayroll", True);
	OrGroup = FinancialReportingServer.NewFilter(Item.Condition, , , Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	FinancialReportingServer.NewFilter(OrGroup, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
	AndGroup = FinancialReportingServer.NewFilter(OrGroup, , , Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	FinancialReportingServer.NewFilter(AndGroup, "BusinessOperation", Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	FinancialReportingServer.NewFilter(AndGroup, "PayrollCardProgram", , , DataCompositionComparisonType.Filled);
	Item.Properties.Insert("Visible");
	
	Item = Settings.Add();
	Item.Fields.Add("PayrollCardProgram");
	FinancialReportingServer.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	Item.Properties.Insert("MarkIncomplete", False);
	
	// Department
	Item = Settings.Add();
	Item.Fields.Add("Department");
	FinancialReportingServer.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.IssueCashToAdvanceHolder);
	Item.Properties.Insert("Visible", False);
	
	// 
	
	Item = Settings.Add();
	Item.Fields.Add("EmployeesHRBICBankAccount");
	FinancialReportingServer.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
	FinancialReportingServer.NewFilter(Item.Condition, "More.CreditingByAccountNumberIsSupported", True);
	Item.Properties.Insert("Visible");
	
	// 
	
	Item = Settings.Add();
	Item.Fields.Add("RegistryFee");
	Item.Fields.Add("EmployeesHRFee");
	Item.Fields.Add("EmployeesHRPersonalAccountMeetsRequirements");
	Item.Fields.Add("EmployeesHRBICOfAccountThatMeetsRequirements");
	Item.Fields.Add("EmployeesHRNumberOfAccountThatMeetsRequirements");
	FinancialReportingServer.NewFilter(Item.Condition, "BusinessOperation", Enums.BusinessTransactions.SalaryPaymentByPayrollCardProgram);
	FinancialReportingServer.NewFilter(Item.Condition, "More.PayrollCardProgramSupportsWaysOfCreditingPayments", True);
	Item.Properties.Insert("Visible");
	
EndProcedure

#EndRegion

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  Mechanisms - Array - list of names of accounting mechanisms that will be
//                       registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(Mechanisms) Export

	Mechanisms = New Array;
	Mechanisms.Add("AdvanceHoldersARAPAccounting_");
	Mechanisms.Add("CashManagement");
	Mechanisms.Add("AccountingForOtherAssetsLiabilities");
	Mechanisms.Add("FinancialAccounting");
	BankConfirmationAboutCashReceiptOnEmployeeAccountLocalization.RegisterAccountingMechanisms(Mechanisms);

EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  RegistersList - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting.
//
Function DocumentDataForPosting(Document, RegistersList, AddlParameters) Export

	If TypeOf(Document) = Type("DocumentObject.BankConfirmationAboutCashReceiptOnEmployeeAccount") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	AddQueryTextTableCashOnWay(QueryTexts, RegistersList);
	AddTextOfRequestTableCashFromAccountablePersons(QueryTexts, RegistersList);
	
	AddQueryTextTableOtherAssetsLiabilities(QueryTexts, RegistersList);
	AddQueryTextTableOfRegisteredRecordsForOtherAssetsLiabilities(QueryTexts, RegistersList);
	
	BankConfirmationAboutCashReceiptOnEmployeeAccountLocalization.AddRequestTexts(Query, QueryTexts, RegistersList);
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(Document.Currency,
																				Document.Currency,
																				Document.Date,
																				Document.Organization);
			
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("Period", Document.Date);
	Query.SetParameter("Organization", Document.Organization);
	Query.SetParameter("DocumentID", DocumentRef.UUID());
	Query.SetParameter("ConversionRateToManCurrency", Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	Query.SetParameter("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	
	ControlOfIssuanceOfReportInContextOfGoals = GetFunctionalOption("ControlIssueOfCashByPurposes");
	Query.SetParameter("ControlIssueOfCashByPurposes", ControlOfIssuanceOfReportInContextOfGoals);
	Query.SetParameter("StartDateOfTransferViaIntermediateAccount",
		Constants.StartDateOfSalaryTransferViaTransfersOnWay.Get());
	Query.SetParameter("UsePayroll",
		GetFunctionalOption("UsePayroll"));
	TablesForRegisteredRecords = DocumentsPosting.InitializeDocumentDataForPosting(Query,
																		QueryTexts, AddlParameters);
	
	Return TablesForRegisteredRecords;

EndFunction
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return BankConfirmationAboutCashReceiptOnEmployeeAccountLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return BankConfirmationAboutCashReceiptOnEmployeeAccountLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	If FormType = "ChoiceForm" Then
		
		If Not CommonClientServer.HasAttributeOrObjectProperty(Parameters, "ChoiceMode") Then
			
			StandardProcessing = False;
			Parameters.Insert("ChoiceMode", True);
			SelectedForm = "ListForm";
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal


#EndRegion

#Region Private

#Region Posting

Procedure AddQueryTextTableCashOnWay(QueryTexts, Registers)
	
	TableName = "CashInTransit";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryText = "SELECT
	               |	VALUE(AccumulationRecordType.Expense) AS RecordType,
	               |	DocumentData.Date AS Period,
	               |	DocumentData.Organization AS Organization,
	               |	UNDEFINED AS Recipient,
	               |	BankAccountIssue.BankAccount AS Sender,
	               |	VALUE(Enum.CashTransferKinds.TransferToPersons) AS CashTransferKind,
	               |	BankAccountIssue.Counterparty AS Counterparty,
	               |	UNDEFINED AS Contract,
	               |	DocumentData.Currency AS Currency,
	               |	EnrollmentData.Sum AS Sum,
	               |	EnrollmentData.Sum * &ConversionRateToManCurrency AS SumMan,
	               |	EnrollmentData.Sum * &FactorOfConversionToCurrencyOfRegul AS SumCompl,
	               |	DocumentData.BusinessOperation AS BusinessOperation,
	               |	EnrollmentData.CashFlowItem AS CashFlowItem,
	               |	EnrollmentData.RowID AS FinRecordID,
	               |	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder)) AS BusinessTransactionSetting
	               |FROM
	               |	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS DocumentData
	               |		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	               |		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	               |		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
	               |		ON DocumentData.SourceDocument = BankAccountIssue.Ref
	               |		INNER JOIN Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS EnrollmentData
	               |		ON DocumentData.Ref = EnrollmentData.Ref
	               |WHERE
	               |	DocumentData.Ref = &Ref
	               |	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	               |	AND EnrollmentData.SalaryCreditingResult = VALUE(Enum.SalaryCreditingResults.Credited)
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	VALUE(AccumulationRecordType.Expense),
	               |	DocumentData.Date,
	               |	DocumentData.Organization,
	               |	UNDEFINED,
	               |	BankAccountIssue.BankAccount,
	               |	VALUE(Enum.CashTransferKinds.TransferToPersons),
	               |	BankAccountIssue.Counterparty,
	               |	UNDEFINED,
	               |	DocumentData.Currency,
	               |	EnrollmentData.Sum,
	               |	EnrollmentData.Sum * &ConversionRateToManCurrency,
	               |	EnrollmentData.Sum * &FactorOfConversionToCurrencyOfRegul,
	               |	DocumentData.BusinessOperation,
	               |	EnrollmentData.CashFlowItem,
	               |	EnrollmentData.RowID AS FinRecordID,
	               |	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.SalaryPaymentByPayrollCardProgram))
	               |FROM
	               |	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS DocumentData
	               |		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	               |		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	               |		INNER JOIN Document.BankAccountIssue AS BankAccountIssue
	               |		ON DocumentData.SourceDocument = BankAccountIssue.Ref
	               |		INNER JOIN Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS EnrollmentData
	               |		ON DocumentData.Ref = EnrollmentData.Ref
	               |WHERE
	               |	DocumentData.Ref = &Ref
	               |	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
	               |	AND EnrollmentData.SalaryCreditingResult = VALUE(Enum.SalaryCreditingResults.Credited)
	               |	AND DocumentData.Date >= &StartDateOfTransferViaIntermediateAccount
	               |	AND &StartDateOfTransferViaIntermediateAccount <> DATETIME(1, 1, 1)
	               |	AND &UsePayroll
	               |";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure AddTextOfRequestTableCashFromAccountablePersons(QueryTexts, Registers)
	
	TableName = "AdvanceHolderCash";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(TableName, Registers) Then
		Return;
	EndIf;
	
	QueryText = "SELECT
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref AS Ref,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Individual AS AdvanceHolder,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.PersonalAccountNumber AS PersonalAccountNumber,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.SalaryCreditingResult AS SalaryCreditingResult,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Sum AS Sum,
	               |	CAST(BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Sum * &ConversionRateToManCurrency AS NUMBER(31, 2)) AS SumMan,
	               |	CAST(BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2)) AS SumCompl,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.CommentToResult AS CommentToResult,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Date AS Date,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Organization AS Organization,
	               |	BankAccountIssue.Department AS Department,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Currency AS Currency,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.CashFlowItem AS CashFlowItem,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.RowID AS RowID,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.BusinessOperation AS BusinessOperation,
	               |	CAST(BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument AS Document.BankAccountIssue).ExpenseReportDate AS ExpenseReportDate
	               |INTO PersonalAccountsTable
	               |FROM
	               |	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR
	               |		INNER JOIN Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount
	               |			INNER JOIN Document.BankAccountIssue AS BankAccountIssue
	               |			ON BankConfirmationAboutCashReceiptOnEmployeeAccount.SourceDocument = BankAccountIssue.Ref
	               |		ON BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.Ref = BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref
	               |WHERE
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref = &Ref
	               |	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.BusinessOperation = VALUE(Enum.BusinessTransactions.IssueCashToAdvanceHolder)
	               |	AND BankConfirmationAboutCashReceiptOnEmployeeAccountEmployeesHR.SalaryCreditingResult = VALUE(Enum.SalaryCreditingResults.Credited)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	PersonalAccountsTable.Date AS Period,
	               |	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	               |	PersonalAccountsTable.Organization AS Organization,
	               |	PersonalAccountsTable.AdvanceHolder AS AdvanceHolder,
	               |	PersonalAccountsTable.Department AS Department,
	               |	PersonalAccountsTable.Currency AS Currency,
	               |	CASE
	               |		WHEN &ControlIssueOfCashByPurposes
	               |			THEN PersonalAccountsTable.CashFlowItem
	               |	END AS IssuancePurpose,
	               |	PersonalAccountsTable.BusinessOperation AS BusinessOperation,
	               |	PersonalAccountsTable.CashFlowItem AS CashFlowItem,
	               |	PersonalAccountsTable.Sum AS Sum,
	               |	PersonalAccountsTable.SumMan AS SumMan,
	               |	PersonalAccountsTable.SumCompl AS SumCompl,
	               |	0 AS ToReport,
	               |	PersonalAccountsTable.RowID AS FinRecordID,
	               |	VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder) AS BusinessTransactionSetting
	               |FROM
	               |	PersonalAccountsTable AS PersonalAccountsTable
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	ENDOFPERIOD(PersonalAccountsTable.ExpenseReportDate, DAY),
	               |	VALUE(AccumulationRecordType.Receipt),
	               |	PersonalAccountsTable.Organization,
	               |	PersonalAccountsTable.AdvanceHolder,
	               |	PersonalAccountsTable.Department,
	               |	PersonalAccountsTable.Currency,
	               |	CASE
	               |		WHEN &ControlIssueOfCashByPurposes
	               |			THEN PersonalAccountsTable.CashFlowItem
	               |	END,
	               |	PersonalAccountsTable.BusinessOperation,
	               |	PersonalAccountsTable.CashFlowItem,
	               |	0,
	               |	0,
	               |	0,
	               |	PersonalAccountsTable.Sum,
	               |	&IDOfUnusedFinRecord,
	               |	VALUE(Catalog.BusinessTransactionsSettings.IssueCashToAdvanceHolder)
	               |FROM
	               |	PersonalAccountsTable AS PersonalAccountsTable";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Function AddQueryTextTableOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "OtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "SELECT
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Date AS Period,
	               |	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Organization AS Organization,
	               |	UNDEFINED AS Department,
	               |	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	               |	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	               |	UNDEFINED AS Dimension,
	               |	CAST(BankConfirmationAboutCashReceiptOnEmployeeAccount.DocumentAmount * &ConversionRateToManCurrency AS NUMBER(31, 2)) AS Sum
	               |FROM
	               |	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS BankConfirmationAboutCashReceiptOnEmployeeAccount
	               |WHERE
	               |	BankConfirmationAboutCashReceiptOnEmployeeAccount.Ref = &Ref
	               |	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
	               |	AND BankConfirmationAboutCashReceiptOnEmployeeAccount.Date >= &StartDateOfTransferViaIntermediateAccount
	               |	AND &StartDateOfTransferViaIntermediateAccount <> DATETIME(1, 1, 1)
	               |	AND &UsePayroll
	               |";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AddQueryTextTableOfRegisteredRecordsForOtherAssetsLiabilities(QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Organization AS Organization,
	|	UNDEFINED AS Department,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.Payroll) AS AssetRef,
	|	UNDEFINED AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|	CAST(EnrollmentData.Sum * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(EnrollmentData.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS SumMan,
	|	CAST(EnrollmentData.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountIncludingVAT,
	|	CAST(EnrollmentData.Sum * &ConversionRateToManCurrency AS NUMBER(31,2))  AS AmountExcludingVAT,
	|	EnrollmentData.RowID AS FinRecordID,
	|	ISNULL(BusinessTransactionsSettings.Ref, VALUE(Catalog.BusinessTransactionsSettings.SalaryPaymentByPayrollCardProgram)) AS BusinessTransactionSetting
	|FROM
	|	Document.BankConfirmationAboutCashReceiptOnEmployeeAccount AS DocumentData
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|	INNER JOIN Document.BankConfirmationAboutCashReceiptOnEmployeeAccount.EmployeesHR AS EnrollmentData
	|		ON DocumentData.Ref = EnrollmentData.Ref
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SalaryPaymentByPayrollCardProgram)
	|	AND EnrollmentData.SalaryCreditingResult = VALUE(Enum.SalaryCreditingResults.Credited)
	|	AND DocumentData.Date >= &StartDateOfTransferViaIntermediateAccount
	|	AND &StartDateOfTransferViaIntermediateAccount <> DATETIME(1, 1, 1)
	|	AND &UsePayroll
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

Procedure EstablishReturnableTypesOfMutualSettlements(ParametersOfUpdate = Undefined) Export
	
	Return;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf