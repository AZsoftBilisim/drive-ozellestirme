

#Region Public

#Region Cash

// Generates and returns the data of the statement for payment, including the Attributes of the header and the tabular part with the possibility of selection.
//
// Parameters:
//   Statement - DocumentRef.PayrollStatementHR - The statement whose data you need to get.
//   FilterParameters - Structure - Optional parameters for the selection of individuals and bank accounts.
//
// Returns:
//   Structure:
//     * HeaderAttributes - Structure:
//         ** Statement - DocumentRef.PayrollStatementHR
//         ** Organization - CatalogRef.Companies
//         ** Department - CatalogRef.BusinessStructure
//         ** DateOfPayment - Date
//         ** Director - CatalogRef.Persons
//         ** JobTitleExecutive - String
//         ** Presentation - String
//         ** BusinessOperation - CatalogRef.BusinessTransactionsSettings
//         ** PaymentMethodHR - EnumRef.PaymentMethodsHR
//         ** KindOfPayment - EnumRef.SalaryPaymentKinds
//     * Table - ValueTable:
//         ** Individual - CatalogRef.Persons
//         ** Sum - Number
//         ** BankAccount - CatalogRef.CounterpartyBankAccounts
//         ** Statement - DocumentRef.PayrollStatementHR
Function DataOfStatement(Statement, FilterParameters = Undefined) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	PayrollStatementHR.Ref AS Statement,
	|	PayrollStatementHR.Organization AS Organization,
	|	PayrollStatementHR.Department AS Department,
	|	PayrollStatementHR.DateOfPayment AS DateOfPayment,
	|	PayrollStatementHR.Director AS Director,
	|	PayrollStatementHR.JobTitleExecutive AS JobTitleExecutive,
	|	PayrollStatementHR.Presentation AS Presentation,
	|	CASE
	|		WHEN
	|			PayrollStatementHR.PaymentMethodHR = VALUE(Enum.PaymentMethodsHR.EmployeeSBankAccount)
	|			THEN VALUE(Enum.BusinessTransactions.SalaryPaymentToBankAccounts)
	|		ELSE VALUE(Enum.BusinessTransactions.SalaryPaymentViaCashAccount)
	|	END AS BusinessOperation,
	|	PayrollStatementHR.PaymentMethodHR AS PaymentMethodHR,
	|	PayrollStatementHR.KindOfPayment AS KindOfPayment,
	|	PayrollStatementHR.Posted AS Posted
	|FROM
	|	Document.PayrollStatementHR AS PayrollStatementHR
	|WHERE
	|	PayrollStatementHR.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollStatementHRContent.Individual AS Individual,
	|	SUM(PayrollStatementHRContent.ToBePaid) AS Sum,
	|	PayrollStatementHRContent.BankAccount AS BankAccount,
	|	PayrollStatementHRContent.Ref AS Statement
	|FROM
	|	Document.PayrollStatementHR.Content AS PayrollStatementHRContent
	|WHERE
	|	PayrollStatementHRContent.Ref = &Ref
	|	AND CASE
	|		WHEN &Individual = VALUE(Catalog.Persons.EmptyRef)
	|			THEN TRUE
	|		ELSE PayrollStatementHRContent.Individual = &Individual
	|	END
	|	AND CASE
	|		WHEN &BankAccount = VALUE(Catalog.CounterpartyBankAccounts.EmptyRef)
	|			THEN TRUE
	|		ELSE PayrollStatementHRContent.BankAccount = &BankAccount
	|	END
	|GROUP BY
	|	PayrollStatementHRContent.Individual,
	|	PayrollStatementHRContent.BankAccount,
	|	PayrollStatementHRContent.Ref";
	
	Query.SetParameter("Ref", Statement);
	Query.SetParameter("Individual", Catalogs.Persons.EmptyRef());
	Query.SetParameter("BankAccount", Catalogs.CounterpartyBankAccounts.EmptyRef());
	
	If TypeOf(FilterParameters) = Type("Structure") Then
		If FilterParameters.Property("Individual") Then
			Query.SetParameter("Individual", FilterParameters.Individual);
		EndIf;
		If FilterParameters.Property("BankAccount") Then
			Query.SetParameter("BankAccount", FilterParameters.BankAccount);
		EndIf;
	EndIf;
	
	QueryResult = Query.ExecuteBatch();
	
	DataOfStatement = New Structure();
	DataOfStatement.Insert("HeaderAttributes", 	QueryResultToStructure(QueryResult[0]));
	DataOfStatement.Insert("Table",			QueryResult[1].Unload());
	
	Return DataOfStatement;
	
EndFunction

// The procedure establishes the visibility of the selection of payroll operations for employees in the form for the WE version.
//
// Parameters:
//	Field - FormField - Field of the form for selecting a business transaction.
//
Procedure EstablishVisibilityOfOperationsOfPayrollIssuanceToEmployees(Field) Export
	
	LimitListOfOperations = Not GetFunctionalOption("RFPaymentsSupport");
	
	If LimitListOfOperations Then
		OperationArray = New Array;
		OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentByDistributor);
		OperationArray.Add(Enums.BusinessTransactions.SalaryPaymentToEmployee);
		
		For Each BusinessOperation In OperationArray Do
			ListItem = Field.ChoiceList.FindByValue(BusinessOperation);
			If ListItem <> Undefined Then
				Field.ChoiceList.Delete(ListItem);
			EndIf;
		EndDo;
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#Region Private

//Returns data from the first record of the query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult - the result of the request containing the data to be processed.
// 
// Returns:
//  Structure - the structure with the result.
//
Function QueryResultToStructure(Val QueryResult)
	
	Return DataExchangeInternal.QueryResultToStructure(QueryResult);
	
EndFunction

#EndRegion