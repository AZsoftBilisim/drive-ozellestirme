#Region Public


#Region Cash

// Fills in the total amount of outstanding payments upon Bank confirmation.
//
// Parameters:
//   Confirmation - DocumentRef - link to the Bank's confirmation.
//   Sum - Number - the amount of outstanding payments to be filled in.
//
Procedure FillInAmountOfOutstandingPaymentsBasedOnBankSConfirmation(Confirmation, Sum) Export
EndProcedure

// The procedure registers compensation from the FSS for expenses on benefits.
//
// Parameters:
//	TempTablesManager - TempTablesManager - Manager that contains the table to Dokumentierten.
//	Object - DocumentObject.BankAccountReceiptNote - Document, if registration is performed during the document execution.
//	Cancel - Boolean - Indicates that motion recording is not being recorded.
//
Procedure GenerateReimbursementOfSocialInsuranceExpenses(TempTablesManager = Undefined, Object = Undefined, Cancel = False) Export
EndProcedure

// Checks the completion of the receipt of the DS for the return of non-transferred salary.
// 
// Parameters:
// 	Object - DocumentObject.BankAccountReceiptNote - The document being checked.
// 	NotCheckedAttributeArray - Array - array of unverifiable details for processing the fill-in check.
// 	Cancel - Boolean - a sign of failure.
//
Procedure CheckFormForRefundOfNonTransferredSalary(Object, NotCheckedAttributeArray, Cancel) Export
EndProcedure

// Returns the date corresponding to the tax period for which the payment was made.
//
// Parameters:
//    MonthOfTaxPeriod - Date - date to fill in.
//    BasisIndicator - String - The symbol of the Foundation of the tax payment
//    PeriodIndicator - String - Symbol of the period for which the tax is transferred
Procedure FillInMonthOfTaxPeriod(MonthOfTaxPeriod, BasisIndicator, PeriodIndicator) Export
	MonthOfTaxPeriod = Date(1,1,1);
EndProcedure

// The data sheets function for filling out payment documents.
//
// Parameters:
//   FilterParameters - Structure - structure with parameters for selecting statements.
//   TempTablesManager - TempTablesManager - temporary table manager.
//
// Returns:
//   Structure   - a structure with the values of the folder details and an array of errors.
//
Function StatementData_(FilterParameters, TempTablesManager = Undefined) Export
	
	Result = New Structure("HeaderAttributes, ErrorsArray", Undefined, New Array);
	Return Result;
	
EndFunction

// The procedure generates a temporary table of individuals based on various types of statements in accordance with the parameters.
//
// Parameters:
//	TempTablesManager - TempTablesManager - temporary table Manager
//	Parameters - Structure - structure of parameters.
//
Procedure DataOnPaymentStatements(TempTablesManager, Parameters) Export
	
	
EndProcedure

#EndRegion

#Region AccountingOfLaborCosts

// Converts the passed array of individuals to a string.
// Used to present a summary of documents.
//
// Parameters:
//	Persons - Array - array of elements of the reference Link type.Physical particle,
//	UpdateDate - Date - date for getting the last name, first name, and patronymic.
//	Content - String - a string of the form <last name, First Name, last name...>.
//
Procedure FillInShortListOfPersons(Persons, UpdateDate, Content) Export
EndProcedure

// Fills in personnel data: the tariff rate, the time worked in the transferred collection.
//
// Parameters:
//  Object - DocumentObject.WorkOutput, FormDataStructure - The document to be filled in.
//  TSName - String - name of the table part to fill in the fields in.
//  FieldsToFillIn - Structure - a structure containing a list of fields to fill (See BSKIntegration.EmployeePersonnelDataFieldsToFillIn)
//                                in.
//  RowsArray - Array - rows to fill in (if Undefined, the fields are filled in in all
//                         rows of the table part).
//
Procedure FillInPersonnelDataOfEmployees(Object, TSName, FieldsToFillIn, RowsArray = Undefined) Export
EndProcedure

// Returns the part of the unit
// 
// Parameters:
// 	ArrayOfIndividuals - Array - array of individuals.
// 	Department - CatalogRef.BusinessStructure - unit.
// 	Organization - CatalogRef.Companies - organization of the desired division. 
//
Procedure FillInIndividualsDivisions(ArrayOfIndividuals, Department, Organization = Undefined) Export
EndProcedure

// Is determined by the setting of the reflection in Boo. default accounting for the specified type of work.
//
// Parameters:
// 	RegisterData - Structure - For a description of the fields, see the resources of the register of information of Accounting Workers.
//   WorkKind - CatalogRef.EmployeeWorkKinds - Type of work.
//
Procedure FillInAccountingOfTypeOfWorkAccordingToRegister(RegisterData, WorkKind) Export
EndProcedure

// Forms the structure of employee personnel data fields to be filled in
//
// Returns:
//  Structure - fields to fill in.
//
Function EmployeePersonnelDataFieldsToFillIn() Export
	
	Result = New Structure;
	Result.Insert("TariffRate",			False);
	Result.Insert("HoursWorked",			False);
	
	Return Result;
	
EndFunction

#EndRegion


#Region OtherProgrammingInterface


// See ToDoListOverridable.OnDetermineToDoListHandlers.
Procedure OnDetermineToDoListHandlers(Handlers) Export
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region HandlersForMonthClosingStages

Function OperationSalaryReflectionInFinancialAccounting() Export
	
	Operation = Undefined;
	Return Operation;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#EndRegion
