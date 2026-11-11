
#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
	
	RegisterRecords = Object.RegisterRecords;
	AdditionalProperties = Object.AdditionalProperties;
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject - processed object
//  CopiedObject - DocumentObject.AccrualAndWriteOffOfBadDebtAlowances - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
	
	
EndProcedure

#EndRegion

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

// Adds a command of creation of the document "expense report".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Procedure AddGenerateCommand(GenerationCommands) Export


EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region Print

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
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	QueryTexts = New Array;
	
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	Return QueryText;
	
EndFunction

#EndRegion
#Region MonthEndTransactions

// A Routine operation with the "formation of reserves for doubtful debts" type
// for transferred organizations for the specified period cancels the execution of documents.
//
// Parameters:
// 	Companies - Array - array of organizations for generating documents
// 	Period - Date - the period of formation documents
//
Procedure DeleteOldReservesAtCloseOfMonth(Companies, Period) Export
	
	
EndProcedure

// Supplements the request texts with a request to receive routine operations for forming reserves for doubtful debts
// (the old approach to forming reserves).
//
// Parameters:
// 	QueryTexts - Array - request texts to add a new request to
//
Procedure RequestTextReservesOld(QueryTexts) Export
	
	
EndProcedure

#EndRegion
#Region LegislativeSupport

// From 01.01.2017 according to paragraph 1 of article 266 of the tax code of the Russian Federation (as amended). Federal law No. 401-FZ of 30.11.2016)
// amended the definition of doubtful debts.
// If the taxpayer has a counter-obligation (payables)
// to the counterparty, the corresponding debt to the taxpayer is considered doubtful in the part
// that exceeds the specified payables of the taxpayer to this counterparty.
//
// Returns:
// 	Boolean
//
Function TakeIntoAccountTheCounterDebt(Period) Export

	Return False;
	
EndFunction

// Item 70 of the Regulations on accounting (Order of the Ministry of Finance of the Russian Federation of 29.07.1998 N 34n)
// If by the end of the reporting year following the year of creation of the doubtful debt reserve,
// this reserve is not used in any part,
// the unspent amounts are added to the financial results when preparing the balance sheet at the end of the reporting year
// .
//
// Returns:
// 	Boolean
//
Function ApplyParagraph70OfOrder34N(Period, Organization) Export
	
	Return False;
	
EndFunction

// Determines the share of reserves for doubtful debts based on restrictions in accordance with clause 4 of article 266 of the tax code
// The limit is defined as the" permitted " share of the amount of reserves determined based on the amounts of doubtful
// debts and the timing of their occurrence.
//
// Returns:
// 	Number - the share of reserves for doubtful debts WELL
//
Function GetShareOfProvisionsForDoubtfulDebtsTa(Period, Organization) Export
	
	Return 0;
	
EndFunction

// item 4, article 266 of the tax code of the Russian Federation
// Since 2017, when calculating reserves for doubtful debts for reporting periods, the limit in N is equal to the greater of the amounts:
// - 10% of revenue for the current reporting period
// - 10% of the previous year's revenue
// When calculating for the year, the limit is still 10% of the revenue of the reporting year(405-FZ of 30.11.16).
//
// Returns:
// 	Number - spending limit WELL
//
Function GetTaSpendingLimit(Period, Organization) Export
	
	Return 0;
	
EndFunction

// Determines whether PBU 18/02 is applied and whether provisions for doubtful debts are reflected on Permanent differences (PR).
//
// Parameters:
// 	AccountingPolicyParameters - Structure, Undefined - register resource values
//
// Returns:
// 	Number - 1, if PBU 18/02 is applied and reserves are reflected on the PR, otherwise 0
//
Function ReflectionCoefficientOfConstantDifference(AccountingPolicyParameters) Export
	
	Return 0;
	
EndFunction

// Determines whether PBU 18/02 is applied and whether provisions for doubtful debts are reflected in Temporary differences (BP).
//
// Parameters:
// 	AccountingPolicyParameters - Structure, Undefined - register resource values
//
// Returns:
// 	Number - 1, if PBU 18/02 is applied and reserves are reflected in BP, otherwise 0
//
Function CoefficientOfReflectionOfTimeDifference(AccountingPolicyParameters) Export
	
	Return 0;
	
EndFunction

// Determines whether the accounting policy has changed the type of accounting for differences for allowances for doubtful debts
// 
// Parameters:
// 	Period - Date -
// 	Organization - CatalogRef.Companies - 
// 	AccountingPolicyParameters - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// 	AccountingPolicySettingsTa - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// Returns:
// 	Boolean
Function ChangedTypeOfDifferencesInAccountingPolicies(Period, Organization, AccountingPolicyParameters, AccountingPolicySettingsTa)Export

	
	Return False;
	
EndFunction

#EndRegion

#Region SparkRisks

// Checks whether the use of the SPARK risks service is allowed.
//
// Returns:
// 	Boolean - if True, then allowed
//
Function SparkRisksUseIsPermitted() Export
	
	Return False;
	
EndFunction

// Data gets a SPARK of indices passed to the contractors.
//
// Parameters:
// 	ArrayOfCounterparties - Array - counterparties for which you need to get SPARK indexes
// 	UsageIsAllowed - Boolean - if False, an empty table is returned
//
// Returns:
// 	ValueTable - SPARK index table
//
Function SparkRisksGettingData(ArrayOfCounterparties, UsageIsAllowed) Export
	
	If Not UsageIsAllowed Then
		Return SPARKRisksEmptyTable();
	EndIf;
	
	Return SPARKRisksEmptyTable();
	
EndFunction

// Sets the conditional design of the elements of the transmitted form
// for the document Accrual and write-off of reserves for doubtful debts.
//
Procedure SparkRisksConditionalAppearance(Form) Export
	
	
EndProcedure

#EndRegion

#Region ConfiguringForms

// Adds the value "write-off of accounts receivable from the reserve" to the business operation selection list.
//
// Parameters:
// 	Item - FormField - field for entering the form that specifies the business transaction
//
Procedure AddWriteOffAtReserveExpense(Item) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Returns the period for calculating reserves, or Undefined
// if no reserves are accrued starting from this period.
//
// Parameters:
// 	Organization - CatalogRef.Companies - the organization for which you want to obtain the period of calculation of reserves
// 	Period - Date - the date on which you want to retrieve information
//
// Returns:
// 	Date, Undefined - the date of the beginning of accrual of reserves or Uncertain, if reserves are not accrued
//
Function PeriodOfCalculationOfProvisionsForDoubtfulDebts(Organization, Period) Export
	
	Result = Undefined;
	
	Return Result
	
EndFunction

// Returns a table of debt estimates in accordance with the organization's accounting policy.
//
// Returns:
// 		ValueTable - empty evaluation table (See empty evaluation table)
//
Function ACRatingTable(Organization, Period) Export
	
	EvaluationTable = Documents.AccrualAndWriteOffOfBadDebtAlowances.EmptyRatingTable();
	Return EvaluationTable;
	
EndFunction

Function RequestTextAccountingPoliciesAC() Export 

	Result =
	"SELECT
	|	FALSE AS ToGenerateLossAllowance,
	|	VALUE(Enum.Periodicity.EmptyRef) AS FrequencyOfLossAllowance,
	|	UNDEFINED AS TypeOfDifferencesInPBU18ProvisionsForDoubtfulDebts,
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization
	|INTO TT_ACAccountingPolicies
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges";
	
	Return Result;
	
EndFunction

Function RequestTextAccountingPolicyTa() Export
	
	Result =
	"SELECT
	|	ParentOrganizations.Organization AS Organization,
	|	FALSE AS GenerateTA,
	|	VALUE(Enum.Periodicity.EmptyRef) AS PeriodicityTa
	|INTO TTAccountingPolicyTa
	|FROM
	|	OnlyParentOrganizations AS ParentOrganizations";
	
	Return Result;
	
EndFunction

Function RequestTextAccountingPoliciesTa() Export
	
	Result =
	"SELECT
	|	FALSE AS ToFormReservesForDoubtfulDebtsTa,
	|	VALUE(Enum.Periodicity.EmptyRef) AS PeriodicityOfProvisionsForDoubtfulDebtsTa,
	|	TT_TableOfChanges.Period AS Period,
	|	TT_TableOfChanges.Organization AS Organization
	|INTO TT_AccountingPoliciesTa
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges";
	
	Return Result;
	
EndFunction

// Values of tax accounting flags.
// 
// Parameters:
//  Organization - CatalogRef.Companies
//  Date  - Date
//  TA - Boolean
//  GenerateTA  - Boolean
// 
// Returns:
//  Undefined - Values Of Tax Accounting Flags
Function ValuesOfTaxAccountingFlags(Organization, Date, TA, GenerateTA) Export
	
	StructureOfFlagsTA = Undefined;
	
	
	Return StructureOfFlagsTA;

EndFunction

#EndRegion

#Region Private

#Region Posting

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of request texts for the event.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure

// The procedure complements the text of the request to fill in the initialization parameters of the document.
//
// Parameters:
//  Query - Query - A general request to fill in the initialization parameters of the document.
//  Attributes - QueryResultSelection - Selection of document details.
//
Procedure AddInitializationParameters(Query, Attributes) Export

	MAAccountingPolicyParameters	= Undefined;
	ACAccountingPolicyParameters	= Undefined;
	AccountingPolicySettingsTa	= Undefined;
	
	
	Query.SetParameter("PD", ReflectionCoefficientOfConstantDifference(ACAccountingPolicyParameters));
	Query.SetParameter("TD", CoefficientOfReflectionOfTimeDifference(ACAccountingPolicyParameters));
	Query.SetParameter("ApplyParagraph70OfOrder34N", ApplyParagraph70OfOrder34N(Attributes.Period, Attributes.Organization));
	Query.SetParameter("ChangedTypeOfDifferences", ChangedTypeOfDifferencesInAccountingPolicies(
		Attributes.Period, Attributes.Organization, MAAccountingPolicyParameters, AccountingPolicySettingsTa));

EndProcedure

// The function gets the parameters of the accounting and tax accounting policies in effect on the date.
// Parameters:
//  AccountingPolicySettings_ - Structure - Cur current accounting parameters linked to the register of accounting policies:
// * FinancialAccountingPolicy - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// * AccountingPolicyBuhAccounting - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings
// * ProfitTaxAccountingSettings - Undefined, Structure - See AccountingPoliciesTaxSettings.CurrentTaxAccountingPolicySettings.
//  Organization - CatalogRef.Companies
//  Period - Date
// 
Procedure SupplementCurrentParametersOfAccountingPolicies(AccountingPolicySettings_, Organization, Period) Export
	
	
EndProcedure


#EndRegion

#Region Other

Function SPARKRisksEmptyTable()
	
	Result = New ValueTable();
	Result.Columns.Add("Counterparty", New TypeDescription("CatalogRef.Counterparties"));
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
