
#Region Internal

// Starts a background task and fills in PO calculation statuses 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	FillParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForFillingInCalculationStatusesOfPO(UUID, FillParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Загрузка транзакций';
														|vi = 'Import transactions';
														|en = 'Import transactions'; fa = 'ورود تراکنش‌ها';
														|it = 'Загрузка транзакций';
														|pl = 'Import transactions';
														|tr = 'İşlemlerin dışa aktarılması'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.FillInPOCalculationStatusTable",
							FillParameters);
							
	Return ExecutionResult;
	
EndFunction

// Runs a background job to load transactions from the service 
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	ImportParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForFillingInInformationRegisterOfPOCalculationStatuses(UUID, ImportParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Заполнение регистра сведений Статусы расчета зп';
														|vi = 'Fill in the ""Payroll calculation statuses"" information register ';
														|en = 'Fill in the ""Payroll calculation statuses"" information register '; fa = 'Fill in the ""Payroll calculation statuses"" information register ';
														|it = 'Fill in the ""Payroll calculation statuses"" information register ';
														|pl = 'Fill in the ""Payroll calculation statuses"" information register ';
														|tr = 'Bilgi kaydının doldurulması Bordro hesaplama durumları'");
		
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.FillInInformationRegisterOfPOCalculationStatuses",
							ImportParameters);
	
	Return ExecutionResult;
	
EndFunction  

// Performs calculation of charges
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	CalculationParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCalculatingAccruals(UUID, CalculationParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Расчет начислений';
														|vi = 'Accrual calculation';
														|en = 'Accrual calculation'; fa = 'Accrual calculation';
														|it = 'Accrual calculation';
														|pl = 'Accrual calculation';
														|tr = 'Tahakkukların hesaplanması'");
	
	POCalculationParameters = Common.CopyRecursive(CalculationParameters);
	POCalculationParameters.Insert("CalculationStatuses", GetFromTempStorage(CalculationParameters.AddressOfCalculationStatusesTable));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.CalculationOfAccruals",
							POCalculationParameters);
							
	Return ExecutionResult;
	
EndFunction

// Performs Unblocking of the calculation
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	CalculationParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForUnblockingCalculation(UUID, CalculationParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Разблокировка расчета';
														|vi = 'Unlock calculation';
														|en = 'Unlock calculation'; fa = 'Unlock calculation';
														|it = 'Unlock calculation';
														|pl = 'Unlock calculation';
														|tr = 'Hesaplamanın kilidini açma'");
	
	POCalculationParameters = Common.CopyRecursive(CalculationParameters);
	POCalculationParameters.Insert("CalculationStatuses", GetFromTempStorage(CalculationParameters.AddressOfCalculationStatusesTable));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.UnblockingPayroll",
							POCalculationParameters);
							
	Return ExecutionResult;
	
EndFunction

// Performs the calculation of deductions
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	CalculationParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCalculatingDeductions(UUID, CalculationParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Расчет удержаний';
														|vi = 'Deduction calculation';
														|en = 'Deduction calculation'; fa = 'Deduction calculation';
														|it = 'Deduction calculation';
														|pl = 'Deduction calculation';
														|tr = 'Kesintilerin hesaplanması'");
	
	POCalculationParameters = Common.CopyRecursive(CalculationParameters);
	POCalculationParameters.Insert("CalculationStatuses", GetFromTempStorage(CalculationParameters.AddressOfCalculationStatusesTable));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.CalculationOfDeductions",
							POCalculationParameters);
							
	Return ExecutionResult;
	
EndFunction

// Performs tax calculation
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	CalculationParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaxCalculationTask(UUID, CalculationParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Расчет налогов';
														|vi = 'Tax calculation';
														|en = 'Tax calculation'; fa = 'Tax calculation';
														|it = 'Tax calculation';
														|pl = 'Tax calculation';
														|tr = 'Vergilerin hesaplanması'");
	
	POCalculationParameters = Common.CopyRecursive(CalculationParameters);
	POCalculationParameters.Insert("CalculationStatuses", GetFromTempStorage(CalculationParameters.AddressOfCalculationStatusesTable));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.CalculationOfTaxes",
							POCalculationParameters);
							
	Return ExecutionResult;
	
EndFunction


// Calculates the amount to be paid
//
// Parameters:
//	UUID - UUID - unique ID of the background job that is running.
//	CalculationParameters - Structure - a set of parameters for the function
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForCalculatingAmountToBePaid(UUID, CalculationParameters) Export
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("ru = 'Расчет Суммы к выплате';
														|vi = 'Calculate amount to be paid';
														|en = 'Calculate amount to be paid'; fa = 'محاسبه مبلغ قابل پرداخت';
														|it = 'Calculate amount to be paid';
														|pl = 'Calculate amount to be paid';
														|tr = 'Hesaplama Ödenecek tutar'");
	
	POCalculationParameters = Common.CopyRecursive(CalculationParameters);
	POCalculationParameters.Insert("CalculationStatuses", GetFromTempStorage(CalculationParameters.AddressOfCalculationStatusesTable));
	
	ExecutionResult = TimeConsumingOperations.ExecuteFunction(
							ExecutionParameters,
							"DataProcessors.PayrollCalculationHR.CalculationOfAmountToBePaid",
							POCalculationParameters);
							
	Return ExecutionResult;
	
EndFunction

#Region ActionsWithPayrollStatusRegisterForEmployees	

// Creates a table of payroll statuses.
//
// Returns:
//   ValueTable - table with payroll Status:
// 		* CalculationPeriod - Date - Payroll period
// 		* Organization - CatalogRef.Companies - Organization
// 		* Department - CatalogRef.BusinessStructure - Department
// 		* Individual - CatalogRef.Persons - A natural person
// 		* Employee - CatalogRef.EmployeesHR - Employee
// 		* CalculationStatusHR - EnumRef.PayrollStatus - Status of the calculation
// 		* AutoAccrualCalculationIsPerformed - Boolean - Indicates whether the automatic calculation of accruals has been performed
// 		* AutoDeductionCalculationIsPerformed - Boolean - Indicates that automatic deduction calculation has been performed
// 		* AutoTaxCalculationIsPerformed - Boolean - Indicates that automatic tax calculation has been performed.
//
Function CreatePayrollStatusTable() Export
	
	StatusTable = New ValueTable();
	StatusTable.Columns.Add("CalculationPeriod", Common.DateTypeDetails(DateFractions.Date));
	StatusTable.Columns.Add("Organization", New TypeDescription("CatalogRef.Companies"));
	StatusTable.Columns.Add("Department", New TypeDescription("CatalogRef.BusinessStructure"));
	StatusTable.Columns.Add("Individual", New TypeDescription("CatalogRef.Persons"));
	StatusTable.Columns.Add("Employee", New TypeDescription("CatalogRef.EmployeesHR")); 
	StatusTable.Columns.Add("CalculationStatusHR", New TypeDescription("EnumRef.PayrollStatus")); 
	StatusTable.Columns.Add("AutoAccrualCalculationIsPerformed", New TypeDescription("Boolean"));
	StatusTable.Columns.Add("AutoDeductionCalculationIsPerformed", New TypeDescription("Boolean"));
	StatusTable.Columns.Add("AutoTaxCalculationIsPerformed", New TypeDescription("Boolean"));
	StatusTable.Columns.Add("DocumentOfPostingInAccounting", New TypeDescription("DocumentRef.PostingPayrollExpensesInFinancialAccounting2_5"));
	
	Return StatusTable;
EndFunction	

// Records payroll statuses for employees.
//
// Parameters:
//   CalculationStatusTable - ValueTable - table with payroll Status
Procedure RecordPayrollStatusesForEmployees(CalculationStatusTable) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources");
		LockItem.DataSource = CalculationStatusTable;
		LockItem.UseFromDataSource("Employee" ,"Employee");
		LockItem.UseFromDataSource("Organization" ,"Organization");
		LockItem.UseFromDataSource("Department" ,"Department");
		LockItem.UseFromDataSource("CalculationPeriod" ,"CalculationPeriod");
		Block.Lock();
		
		For Each CurrentRow In CalculationStatusTable Do 
			
			RecordSet = InformationRegisters.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CreateRecordSet();
			
			RecordSet.Filter.Organization.Set(CurrentRow.Organization);
			RecordSet.Filter.Department.Set(CurrentRow.Department);
			RecordSet.Filter.CalculationPeriod.Set(CurrentRow.CalculationPeriod);
			RecordSet.Filter.Employee.Set(CurrentRow.Employee);
			
			Record = RecordSet.Add();
			FillPropertyValues(Record, CurrentRow);
			
			RecordSet.Write(True);
			
		EndDo;
		
		CommitTransaction();
	Except 
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region DealingWithErrors

Procedure AddErrorToErrorArray(QueryExecutionResult, ErrorParameters) Export
	
	 ErrorsArray = QueryExecutionResult.ErrorsArray; 
	 ErrorsArray.Add(ErrorParameters);
	
EndProcedure

// Creates a structure with error parameters for future reference.
//
// Parameters:
//   ErrorText - String - The text of the error that will be saved in the parameters.
//
// Returns:
//   Structure - A set of parameters characterizing the error. See NewErrorParameters
//               ()
Function NewErrorParameters(ErrorText = "") Export
	
    ErrorParameters = New Structure();
	ErrorParameters.Insert("ErrorText",ErrorText);
	ErrorParameters.Insert("Employee", Catalogs.EmployeesHR.EmptyRef());
	ErrorParameters.Insert("Department", Catalogs.BusinessStructure.EmptyRef());
	ErrorParameters.Insert("Individual", Catalogs.Persons.EmptyRef());
	ErrorParameters.Insert("ErrorInAccruals", False);
	ErrorParameters.Insert("ErrorInDeductions", False);
	ErrorParameters.Insert("EmployeeTaxError", False);
	ErrorParameters.Insert("ErrorInCompanyTaxes", False); 
	ErrorParameters.Insert("ErrorInTimesheets", False); 
	
	Return ErrorParameters;
EndFunction	

// Returns a structure with the results of the query.
// The structure contains the execution Status, filling parameters, error array, and address of the PO calculation Status table.
//
// Returns:
//   Structure - result of the query execution with the default values filled in
Function StructureOfQueryResult() Export
	
	QueryExecutionResult = New Structure();
	QueryExecutionResult.Insert("ExecutionStatus", False); 
	QueryExecutionResult.Insert("FillParameters", New Structure());
	QueryExecutionResult.Insert("ErrorsArray", New Array());
	QueryExecutionResult.Insert("AddressOfPOCalculationStatusTable", "");
	
	Return QueryExecutionResult;
	
EndFunction	

#EndRegion

#EndRegion  
