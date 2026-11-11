
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

// The procedure complements the texts of requests for the document.
//
// Parameters:
//  Query - Query - General request for document execution.
//  QueryTexts - ValueList - List of texts of the request for holding.
//  Registers - String, Structure - A comma-separated list of document execution registers or in structure keys.
//
Procedure AddRequestTexts(Query, QueryTexts, Registers) Export
	
	
EndProcedure
//
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return "";
	
EndFunction

#EndRegion
#EndRegion

#Region MonthEndTransactions

// The procedure applies an increment factor to the amount of expense recognition in the NUS.
// The coefficient is applied only to research and development expenses included in the list of the government of the Russian Federation,
// for items with a preferential type of NU expenses. The calculation of the application of the increasing coefficient is recorded in the register 
// of information for calculating the recognition of R & d Expenditures.
//
// Parameters:
//  RegisterRecordTable - ValueTable - Document Movement Table:
//   * ExpenseItem - ChartOfCharacteristicTypesRef.ExpenseItems
//   * DimensionOfExpenses - Characteristic.ExpenseItems
//   * RecordType - AccumulationRecordType
//   * FinRecordID - String
//   * SumCompl - Number
//   * PermanentDifference - Number
//   * CostTD - Number
//   * ApplyCoefficient - Boolean
//  RecognitionDocument - DocumentRef.RDExpenseRecognition -
//  Organization - CatalogRef.Companies - The organization that the calculation is performed for.
//  CalculationPeriod - Date - Date when the calculation was completed.
//
Procedure ApplyBoostingFactor(RegisterRecordTable, RecognitionDocument, Organization, CalculationPeriod) Export

	
EndProcedure

// Returns documents to be reflected in regl. accounting
//
// Parameters:
// 	Documentreflection - Assignment TablereFerences, 
// 							Manager of temporary tables - A table of documents that need to be returned to reflection, 
// 													  or a manager of temporary tables that has a table of documents to be reflected
// 													  The table should have columns Document, Organization, and Data reflections. 
//
Procedure ReturnDocumentsToReflection(TempTableManager) Export
	
	
EndProcedure

// Sets a lock and clears the movement of localize registers
// 
// Parameters:
// 	TempTableManager - TempTablesManager - contains a display document table with columns:
// 	* Document - DocumentRef.RDExpenseRecognition - 
Procedure ClearingMovementOfExpenseRecognitionDocuments(TempTableManager) Export

	
EndProcedure

// Determines the size of the increasing coefficient to the amounts of recognition of expenses in the WELL
//
// Parameters:
// 	Period - Date - The period of validity.
//
// Returns:
// 	Number - The coefficient to the amounts of recognition of expenses in NU.
//
Function IncreasingCoefficientToAmountsOfRecognitionOfExpensesInNationalBudget(Val Period) Export

	ZoomRatio = 1;
	
	If BegOfYear(Period) >= '2025-01-01' Then
		ZoomRatio = 2;
	Else
		ZoomRatio = 1.5;
	EndIf;
	
	Return ZoomRatio;
	
EndFunction

#EndRegion

#Region ReportsCommands

Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Function QueryTextAccountingPolicyOfBU() Export
	
	Result =
	"SELECT
	|	ParentOrganizations.Organization 								AS Organization,
	|	FALSE 															AS AccountingForRAndDAccordingToFsb26,
	|	VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)	AS ExpenseItemForRD,
	|	UNDEFINED													AS ExpensesDimensionResearchExpenses
	|INTO TTAccountingPolicyBuhAccounting
	|FROM
	|	TTParentOrganizations AS ParentOrganizations";
	
	Return Result;
	
EndFunction

Function RequestTextAccountingPoliciesAC() Export
	
	Result =
	"SELECT
	|	TT_TableOfChanges.Period		AS Period,
	|	TT_TableOfChanges.Organization AS Organization,
	|	FALSE 							AS InternationalRecognitionForResearch
	|INTO TT_ACAccountingPolicies
	|FROM
	|	Tt_OrganizationOfAccountingPolicy AS TT_TableOfChanges";
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region Posting


#EndRegion


#EndRegion