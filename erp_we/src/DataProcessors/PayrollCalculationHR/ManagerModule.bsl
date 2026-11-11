#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// This function loads the status table for calculating the PO
// 
// Parameters:
//  FillParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// *  FillingStatus - Boolean - Filling Status
// *  FillParameters - Structure - The fill parameters
// *  ErrorsArray - Array of String - List of errors
// *  TableOfPOCalculationStatus - ValueTable
//
Function FillInPOCalculationStatusTable(FillParameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.FillInPayrollStatus");
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	QueryExecutionResult.FillParameters = FillParameters;
	
	Try 
	   	TableOfPOCalculationStatus = 
   			FillInTableOfStatusesForCalculatingPO(QueryExecutionResult);
	Except
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult,
								PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
								PayrollCalculationHRServer.NewErrorParameters(NStr("ru = 'Заполнение данными не выполнено';
																					|vi = 'The data is not filled in';
																					|en = 'The data is not filled in'; fa = 'The data is not filled in';
																					|it = 'The data is not filled in';
																					|pl = 'The data is not filled in';
																					|tr = 'Verilerle doldurma gerçekleştirilemedi'")));	
	EndTry;		
	
	CheckCompletionOfPOCalculationStatuses(TableOfPOCalculationStatus, QueryExecutionResult);
	
	AddressOfPOCalculationStatusTable = PutToTempStorage(TableOfPOCalculationStatus, 
													FillParameters.AddressOfPOCalculationStatusTable);

	QueryExecutionResult.AddressOfPOCalculationStatusTable = AddressOfPOCalculationStatusTable;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;

EndFunction	

// The function loads the information register Payroll statuses
// 
// Parameters:
//  FillParameters - Structure - Boot parameter
// 
// Returns:
// Structure - The result of the query:
// * ResponseStatus - String
// * FillParameters - String - Boot parameter:
// * AddressOfPOCalculationStatusTable - String
// * DataTableAddress - String - Address of the data table
// * AddressOfErrorTable - String - Address of the Error Table
// * ErrorsArray - Array of String - Array of errors
// * Number_Transactions - Number
//
Function FillInInformationRegisterOfPOCalculationStatuses(FillParameters) Export

	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	QueryExecutionResult.FillParameters = FillParameters;
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.EntryInInformationRegisterStatusOfCalculationOfPO");
	
	NewTableOfPOCalculationStatus = FillInPOCalculationStatusTableWithData(FillParameters);
	
	BeginTransaction();
	Try
	
		WriteNewDataToInformationRegisterCalculationStatusesOfPO(FillParameters, NewTableOfPOCalculationStatus);

		CommitTransaction();

	Except
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
							PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
							PayrollCalculationHRServer.NewErrorParameters(
														NStr("ru = 'Заполнение данными не выполнено';
															|vi = 'The data is not filled in';
															|en = 'The data is not filled in'; fa = 'The data is not filled in';
															|it = 'The data is not filled in';
															|pl = 'The data is not filled in';
															|tr = 'Verilerle doldurma gerçekleştirilemedi'")));	
																	
		Raise;
		
	EndTry;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction	

// The function performs the calculation of charges
// 
// Parameters:
//  CalculationParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// * FillingStatus - Boolean - Filling Status
// * FillParameters - String - The fill parameters
// * ErrorsArray - Array of String - List of errors
// * TableOfPOCalculationStatus - ValueTable - Table of payroll statuses
//
Function CalculationOfAccruals(CalculationParameters) Export
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.CalculateAccruals");
	
	BeginTransaction();
	Try 
		
		StructureOfPreparedData = CalculateAccruals(CalculationParameters, QueryExecutionResult);
		
		StatusTablePreparedData = StructureOfPreparedData.StatusTable;
		AccrualTablePreparedData = StructureOfPreparedData.AccrualTable; 
		
		//Writing down the Status table
		POStatusTable = PayrollCalculationHRServer.CreatePayrollStatusTable(); 
		POAccrualTable = RegisterPayrollCalculationServer.CreateAccrualTable(); 
		
		ArrayOfErrorTexts = New Array();
		For Each CurrentRowAccrualTablePreparedData In AccrualTablePreparedData Do
			
			AccrualAmount = CalculateAccrualAmount(CurrentRowAccrualTablePreparedData, ArrayOfErrorTexts);  
			
			If AccrualAmount = 0 						
				And AccrualsAreOptional(CurrentRowAccrualTablePreparedData) Then
				
				ArrayOfErrorTexts.Clear();
				Continue;
			EndIf;	
			
			NewLineOfCharges = POAccrualTable.Add();
			FillPropertyValues(NewLineOfCharges, CurrentRowAccrualTablePreparedData); 
			NewLineOfCharges.Sum = AccrualAmount;
			NewLineOfCharges.Base = CurrentRowAccrualTablePreparedData.Value; 
			
			AccrualMethod = CurrentRowAccrualTablePreparedData.AccrualMethod;
			
			If NewLineOfCharges.Base = 0 
				And Not CurrentRowAccrualTablePreparedData.BasicEarnings
				And (AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked
				Or AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked) Then
				NewLineOfCharges.Base = CurrentRowAccrualTablePreparedData.AmountOfBasicEarnings;
			EndIf;	

			If AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked 
				And AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked Then
				
				NewLineOfCharges.NormalWorkdays = 0;
				NewLineOfCharges.NormOfHours = 0;
				
			EndIf;	

			NewLineOfCharges.Period = CurrentRowAccrualTablePreparedData.ValidityStartDate; 
			NewLineOfCharges.RowID = String(New UUID);
			
			If ArrayOfErrorTexts.Count() > 0 Then
				For Each CurrentErrorText In ArrayOfErrorTexts Do
					ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(CurrentErrorText);	
					ErrorParameters.Employee = NewLineOfCharges.Employee; 
					ErrorParameters.Individual = NewLineOfCharges.Individual;
					ErrorParameters.Department = NewLineOfCharges.Department;
					ErrorParameters.ErrorInAccruals = True; 
					PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);
				EndDo; 
				
				ArrayOfErrorTexts.Clear();
			EndIf;	
			
		EndDo;
		
		ArrayOfEmployeesWithAccrualErrors = CheckCalculationOfAccruals(POAccrualTable, QueryExecutionResult);
		
		For Each CurrentRowStatusTablePreparedData In StatusTablePreparedData Do
			
			NewStatusLine = POStatusTable.Add();
			FillPropertyValues(NewStatusLine, CurrentRowStatusTablePreparedData);
			NewStatusLine.AutoAccrualCalculationIsPerformed = 
			ArrayOfEmployeesWithAccrualErrors.Find(NewStatusLine.Employee) = Undefined;
		EndDo;
		
		PayrollCalculationHRServer.RecordPayrollStatusesForEmployees(POStatusTable);
		
		StructureOfDataRecords = RegisterPayrollCalculationServer.StructureOfAccrualDataRecords();
		StructureOfDataRecords.RegistrationMonth = CalculationParameters.CalculationPeriod;
		StructureOfDataRecords.Organization = CalculationParameters.Organization;
		StructureOfDataRecords.AccrualTable = POAccrualTable;
		
		RegisterPayrollCalculationServer.WriteDownAccrualTable(StructureOfDataRecords);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
							PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
							PayrollCalculationHRServer.NewErrorParameters(
													NStr("ru = 'Расчет начислений не выполнен';
														|vi = 'Accruals are not calculated';
														|en = 'Accruals are not calculated'; fa = 'Accruals are not calculated';
														|it = 'Accruals are not calculated';
														|pl = 'Accruals are not calculated';
														|tr = 'Tahakkuk hesaplaması gerçekleştirilemedi'")));	
		
	EndTry;		
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction	

// The function performs the calculation of deductions
// 
// Parameters:
//  CalculationParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// * FillingStatus - Boolean - Filling Status
// * FillParameters - Structure - The fill parameters
// * ErrorsArray - Array of String - List of errors
// * TableOfPOCalculationStatus - ValueTable - Table of PO Calculation Status
//
Function CalculationOfDeductions(CalculationParameters) Export
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.CalculateDeductions");
	
	BeginTransaction();
	Try 
		
		StructureOfPreparedData = CalculateDeductions(CalculationParameters, QueryExecutionResult);
		
		StatusTablePreparedData = StructureOfPreparedData.StatusTable;
		RetentionTablePreparedData = StructureOfPreparedData.RetentionTable; 
		
		//Writing down the Status table
		POStatusTable = PayrollCalculationHRServer.CreatePayrollStatusTable(); 
		TableOfPODeductions = RegisterPayrollCalculationServer.CreateRetentionTable(); 
		
		ArrayOfErrorTexts = New Array();
		For Each CurrentRowRetentionTablePreparedData In RetentionTablePreparedData Do
			
			AmountOfDeductions = CalculateRetentionAmount(CurrentRowRetentionTablePreparedData, ArrayOfErrorTexts);
			
			If AmountOfDeductions = 0 						
				And RetentionIsOptional(CurrentRowRetentionTablePreparedData) Then

				ArrayOfErrorTexts.Clear();
					
				Continue;
			EndIf;	
			
			NewLineOfDeductions = TableOfPODeductions.Add();
			FillPropertyValues(NewLineOfDeductions, CurrentRowRetentionTablePreparedData);
			NewLineOfDeductions.Sum = AmountOfDeductions;
			NewLineOfDeductions.RowID = String(New UUID);
			
			If ArrayOfErrorTexts.Count() > 0 Then
				For Each CurrentErrorText In ArrayOfErrorTexts Do
					ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(CurrentErrorText);	
					ErrorParameters.Employee = NewLineOfDeductions.Employee; 
					ErrorParameters.Individual = NewLineOfDeductions.Individual;
					ErrorParameters.Department = NewLineOfDeductions.Department;
					ErrorParameters.ErrorInDeductions = True; 
					PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);
				EndDo; 
				
				ArrayOfErrorTexts.Clear();
			EndIf;	
			
		EndDo;
		
		ArrayOfEmployeesWithRetentionErrors = CheckDeductionCalculation(TableOfPODeductions, QueryExecutionResult);
		
		For Each CurrentRowStatusTablePreparedData In StatusTablePreparedData Do
			
			NewStatusLine = POStatusTable.Add();
			FillPropertyValues(NewStatusLine, CurrentRowStatusTablePreparedData);
			NewStatusLine.AutoDeductionCalculationIsPerformed = 
			ArrayOfEmployeesWithRetentionErrors.Find(NewStatusLine.Employee) = Undefined;
			
		EndDo;
		
		PayrollCalculationHRServer.RecordPayrollStatusesForEmployees(POStatusTable);
		
		StructureOfDataRecords = RegisterPayrollCalculationServer.StructureOfRetentionDataRecords();
		StructureOfDataRecords.RegistrationMonth = CalculationParameters.CalculationPeriod;
		StructureOfDataRecords.Organization = CalculationParameters.Organization;
		StructureOfDataRecords.RetentionTable = TableOfPODeductions;
		StructureOfDataRecords.StatusTable = POStatusTable;
		
		RegisterPayrollCalculationServer.WriteRetentionTable(StructureOfDataRecords);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
		PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
		PayrollCalculationHRServer.NewErrorParameters(
		NStr("ru = 'Расчет удержаний не выполнен';
			|vi = 'Deductions are not calculated';
			|en = 'Deductions are not calculated'; fa = 'Deductions are not calculated';
			|it = 'Deductions are not calculated';
			|pl = 'Deductions are not calculated';
			|tr = 'Kesinti hesaplaması gerçekleştirilemedi'")));	
		
	EndTry;		
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction	

// The function performs the calculation of Taxes
// 
// Parameters:
//  CalculationParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// * FillingStatus - Boolean - Filling Status
// * FillParameters - Structure - The fill parameters
// * ErrorsArray - Array of String - List of errors
// * TableOfPOCalculationStatus - ValueTable - Table of PO Calculation Status
//
Function CalculationOfTaxes(CalculationParameters) Export
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.CalculationOfTaxes");
	
	BeginTransaction();
	
	Try
		StructureOfPreparedData = CalculateTaxes(CalculationParameters, QueryExecutionResult);
		
		StatusTablePreparedData = StructureOfPreparedData.StatusTable;
		TaxTablePreparedData = StructureOfPreparedData.TaxTable;
		
		//Writing down the Status table
		POStatusTable = PayrollCalculationHRServer.CreatePayrollStatusTable(); 
		POTaxTable = RegisterPayrollCalculationServer.CreateTaxTable(); 
		
		For Each CurrentRowTaxTablePreparedData In TaxTablePreparedData Do
			
			NewLineOfTaxes = POTaxTable.Add();
			FillPropertyValues(NewLineOfTaxes, CurrentRowTaxTablePreparedData);
			NewLineOfTaxes.RowID = String(New UUID);
			
		EndDo;
		
		ArrayOfPersonsWithTaxErrors = CheckTaxCalculation(POTaxTable, QueryExecutionResult);
		
		For Each CurrentRowStatusTablePreparedData In StatusTablePreparedData Do
			
			NewStatusLine = POStatusTable.Add();
			FillPropertyValues(NewStatusLine, CurrentRowStatusTablePreparedData);
			NewStatusLine.AutoTaxCalculationIsPerformed = 
			ArrayOfPersonsWithTaxErrors.Find(NewStatusLine.Individual) = Undefined;
			If NewStatusLine.AutoAccrualCalculationIsPerformed
				And NewStatusLine.AutoDeductionCalculationIsPerformed
				And NewStatusLine.AutoTaxCalculationIsPerformed Then
				NewStatusLine.CalculationStatusHR = Enums.PayrollStatus.Preliminary;
			EndIf;	
			
		EndDo;
		
		PayrollCalculationHRServer.RecordPayrollStatusesForEmployees(POStatusTable);
		
		StructureOfDataRecords = RegisterPayrollCalculationServer.StructureOfTaxDataRecords();
		StructureOfDataRecords.RegistrationMonth = CalculationParameters.CalculationPeriod;
		StructureOfDataRecords.Organization = CalculationParameters.Organization;
		StructureOfDataRecords.TaxTable = POTaxTable;
		
		RegisterPayrollCalculationServer.WriteDownTaxTable(StructureOfDataRecords);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
						PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
											PayrollCalculationHRServer.NewErrorParameters(
																NStr("ru = 'Расчет удержаний не выполнен';
																	|vi = 'Deductions are not calculated';
																	|en = 'Deductions are not calculated'; fa = 'Deductions are not calculated';
																	|it = 'Deductions are not calculated';
																	|pl = 'Deductions are not calculated';
																	|tr = 'Kesinti hesaplaması gerçekleştirilemedi'")));	
	EndTry;		
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction

// The function calculates the amount to be paid
// 
// Parameters:
//  CalculationParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// * FillingStatus - Boolean - Filling Status
// * FillParameters - Structure - The fill parameters
// * ErrorsArray - Array of String - List of errors
// * TableOfPOCalculationStatus - ValueTable - Table of PO Calculation Status
//
Function CalculationOfAmountToBePaid(CalculationParameters) Export
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.CalculationOfAmountToBePaid");
	
	BeginTransaction();
	
	Try
		StructureOfPreparedData = CalculateAmountToBePaid(CalculationParameters, QueryExecutionResult);
		
		//Writing down the Status table
		POStatusTable = PayrollCalculationHRServer.CreatePayrollStatusTable(); 
		
		TableOfPreparedDataStatuses = StructureOfPreparedData.StatusTable;
		
		POReflectionDocument = WriteDataToPayrollReflectionDocument(
								CalculationParameters, StructureOfPreparedData, QueryExecutionResult);
								
		ErrorsCount = QueryExecutionResult.ErrorsArray.Count();
		
		For Each CurrentRowPreparedDataStatusTable In TableOfPreparedDataStatuses Do
			
			NewStatusLine = POStatusTable.Add();
			FillPropertyValues(NewStatusLine, CurrentRowPreparedDataStatusTable);
			If CurrentRowPreparedDataStatusTable.AllAutoCalculationsAreCompleted
				And ErrorsCount = 0 Then
				NewStatusLine.DocumentOfPostingInAccounting = POReflectionDocument;                               
				NewStatusLine.CalculationStatusHR = Enums.PayrollStatus.IsFinal;
			Else     
				NewStatusLine.DocumentOfPostingInAccounting = Documents.PostingPayrollExpensesInFinancialAccounting2_5.EmptyRef();	
				NewStatusLine.CalculationStatusHR = Enums.PayrollStatus.Errors;
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По сотруднику %1, не рассчитана сумма к выплате';
																							|vi = 'For employee %1, the amount to be paid is not calculated';
																							|en = 'For employee %1, the amount to be paid is not calculated'; fa = 'For employee %1, the amount to be paid is not calculated';
																							|it = 'For employee %1, the amount to be paid is not calculated';
																							|pl = 'For employee %1, the amount to be paid is not calculated';
																							|tr = 'Çalışan %1 için ödenecek tutar hesaplanmamıştır.'"),
				CurrentRowPreparedDataStatusTable.Employee,);
				
				AddErrorOnAmountToBePaid(QueryExecutionResult, CurrentRowPreparedDataStatusTable, MessageText);
				
			EndIf;	
			
		EndDo;
		
		PayrollCalculationHRServer.RecordPayrollStatusesForEmployees(POStatusTable);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
							PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
											PayrollCalculationHRServer.NewErrorParameters(
															NStr("ru = 'Расчет суммы к выплате не выполнен';
																|vi = 'Amount to be paid is not calculated';
																|en = 'Amount to be paid is not calculated'; fa = 'Amount to be paid is not calculated';
																|it = 'Amount to be paid is not calculated';
																|pl = 'Amount to be paid is not calculated';
																|tr = 'Ödenecek tutar hesaplaması gerçekleştirilemedi'")));	
		
	EndTry;		
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction

//Performs unblocking of payroll.
// 
// Parameters:
//  CalculationParameters - Structure - The fill parameters
// 
// Returns:
// Structure - The result of the query:
// * FillingStatus - Boolean - Filling Status
// * FillParameters - Structure - The fill parameters
// * ErrorsArray - Array of String - List of errors
// * TableOfPOCalculationStatus - ValueTable - Table of PO Calculation Status
//
Function UnblockingPayroll(CalculationParameters) Export
	
	QueryExecutionResult = PayrollCalculationHRServer.StructureOfQueryResult();
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"DataProcessor.HRPayrollCenter.Form.UnblockingOfPayroll");
	
	BeginTransaction();
	
	Try
		TableOfPreparedData = GetDataForUnblockingPOCalculation(CalculationParameters, QueryExecutionResult);
		
		POStatusTable = PayrollCalculationHRServer.CreatePayrollStatusTable(); 
		
		For Each CurrentRowIsTableOfPreparedData In TableOfPreparedData Do
			
			NewStatusLine = POStatusTable.Add();
			FillPropertyValues(NewStatusLine, CurrentRowIsTableOfPreparedData);
			
		EndDo;
		
		PayrollCalculationHRServer.RecordPayrollStatusesForEmployees(POStatusTable);
		
		DeleteDataFromPayrollReflectionDocument(CalculationParameters, POStatusTable);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
		PayrollCalculationHRServer.NewErrorParameters(ErrorDescription()));	
		PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
		PayrollCalculationHRServer.NewErrorParameters(
		NStr("ru = 'Разблокировка расчетов не выполнена';
			|vi = 'Calculations are not unlocked';
			|en = 'Calculations are not unlocked'; fa = 'Calculations are not unlocked';
			|it = 'Calculations are not unlocked';
			|pl = 'Calculations are not unlocked';
			|tr = 'Hesaplamaların kilidi açılamadı'")));	
		
	EndTry;		
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, 1);
	
	Return QueryExecutionResult;
	
EndFunction	

#EndRegion

#Region Private  

Procedure DeleteDataFromPayrollReflectionDocument(CalculationParameters, POStatusTable)
	
	If POStatusTable.Count() = 0 Then
		Return;
	EndIf;	
	
	DocumentReference = FindLinkToDocumentPayrollReflectionInInternationalAccounting(CalculationParameters);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Document.PostingPayrollExpensesInFinancialAccounting2_5");
		LockItem.SetValue("Ref", DocumentReference);
		Block.Lock();
		
		DocumentObject = DocumentReference.GetObject();
		
		ArrayOfEmployees = POStatusTable.UnloadColumn("Employee");
		
		DeleteDataFromTableByDocument(DocumentObject, "Accruals", ArrayOfEmployees, "Employee");
		DeleteDataFromTableByDocument(DocumentObject, "Deductions",  ArrayOfEmployees, "Employee");
		DeleteDataFromTableByDocument(DocumentObject, "PayrollTaxes", ArrayOfEmployees, "Employee");
		DeleteDataFromTableByDocument(DocumentObject, "DutiesOfTaxAgent", ArrayOfEmployees, "Employee");
		
		DocumentObject.Write(DocumentWriteMode.Posting);
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure	

Function WriteDataToPayrollReflectionDocument(CalculationParameters, StructureOfPreparedData, QueryExecutionResult)
	
	DocumentReference = FindLinkToDocumentPayrollReflectionInInternationalAccounting(CalculationParameters);
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("Document.PostingPayrollExpensesInFinancialAccounting2_5");
		LockItem.SetValue("Ref", DocumentReference);
		Block.Lock();
		
		DocumentObject = DocumentReference.GetObject();
		
		UpdateTableInDocument(DocumentObject, "Accruals", StructureOfPreparedData.Accruals, 
																		"Employee", QueryExecutionResult);
		UpdateTableInDocument(DocumentObject, "PayrollTaxes", 
												StructureOfPreparedData.PayrollTaxes, 
																			"Employee", QueryExecutionResult);
		UpdateTableInDocument(DocumentObject, "DutiesOfTaxAgent", 
												StructureOfPreparedData.DutiesOfTaxAgent, 
																		"Employee", QueryExecutionResult);
		UpdateTableInDocument(DocumentObject, "Deductions", StructureOfPreparedData.Deductions, 
																"Employee", QueryExecutionResult);
		
		HasErrors = False;
		If DocumentObject.CheckFilling() Then
		
			DocumentObject.Write(DocumentWriteMode.Posting);   
		
		ElsIf DocumentObject.Posted Then
			
			If Not DocumentsPayrollAndHumanResourcesServer.DocumentIsUsedInCalculatingPOData(DocumentObject.Ref) Then
				DocumentObject.Write(DocumentWriteMode.UndoPosting);
			Else
				DocumentObject.Write(DocumentWriteMode.Write);
			EndIf;	
			
			HasErrors = True;
		
		Else	

			DocumentObject.Write(DocumentWriteMode.Write);
		
		EndIf;	
		
		If Not DocumentObject.Posted
			Or HasErrors Then
			
			PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, 
											PayrollCalculationHRServer.NewErrorParameters(
															NStr("ru = 'Расчет суммы к выплате не выполнен';
																|vi = 'Amount to be paid is not calculated';
																|en = 'Amount to be paid is not calculated'; fa = 'Amount to be paid is not calculated';
																|it = 'Amount to be paid is not calculated';
																|pl = 'Amount to be paid is not calculated';
																|tr = 'Ödenecek tutar hesaplaması gerçekleştirilemedi'")));	
			
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return DocumentReference;
	
EndFunction	

Function RetentionIsOptional(CurrentRetentionRow)
	
	If CurrentRetentionRow.InputFrequency <> 2 Then
		CurrentRetentionRow.MandatoryRetention = False;
	EndIf;

	Return Not CurrentRetentionRow.MandatoryRetention;
	
EndFunction	

Function AccrualsAreOptional(CurrentAccrualLine)
	
	If CurrentAccrualLine.DaysWorked = 0 And CurrentAccrualLine.HoursWorked = 0 
		And CurrentAccrualLine.InputFrequency <> 2
		And CurrentAccrualLine.AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.Development_1
		And Not CurrentAccrualLine.BasicEarnings Then
		CurrentAccrualLine.MandatoryAccrual = False;
	EndIf;

	Return Not CurrentAccrualLine.MandatoryAccrual;
	
EndFunction	

Procedure CheckCompletionOfPOCalculationStatuses(TableOfPOCalculationStatus, QueryExecutionResult)
	If TableOfPOCalculationStatus.Count() = 0 Then
		Return;
	EndIf;	
	
	For Each CurrentPOStatusBar In TableOfPOCalculationStatus Do
		
		If CurrentPOStatusBar.TimeCard = 0
			And CurrentPOStatusBar.MethodOfAccrualOfBasicEarnings <> Enums.AccrualMethodsPayrollAndHumanResources.Development_1  
			And CurrentPOStatusBar.MethodOfAccrualOfBasicEarnings <> Enums.AccrualMethodsPayrollAndHumanResources.BaseSalary Then
			
			CurrentPOStatusBar.ThereAreErrorsInTimesheets = True;	
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
																		NStr("ru = 'Не введен табель, по сотруднику: %1';
																			|vi = 'For employee %1, the timesheet is not created';
																			|en = 'For employee %1, the timesheet is not created'; fa = 'For employee %1, the timesheet is not created';
																			|it = 'For employee %1, the timesheet is not created';
																			|pl = 'For employee %1, the timesheet is not created';
																			|tr = 'Çalışan %1 için puantaj girilmemiştir.'"), 
																		CurrentPOStatusBar.Employee);
			
			AddErrorToPOStatuses(QueryExecutionResult, CurrentPOStatusBar, MessageText);
			
		EndIf;	
		
	EndDo;	
	
EndProcedure	

Procedure DeleteDataFromTableByDocument(DocumentObject, ColumnDescription, ArrayOfEmployees, NameOfFilterField)

	If ArrayOfEmployees.Count() = 0 Then
		Return;
	EndIf;
	
	Filter_By_Field = New Structure(NameOfFilterField);
	
	DocumentTable = DocumentObject[ColumnDescription];
	
	//Clearing the data that needs to be overwritten
	For Each CurrentValueArrayOfEmployees In ArrayOfEmployees Do
		
		Filter_By_Field[NameOfFilterField] = CurrentValueArrayOfEmployees;
		
		FoundRowsInDocumentTable = DocumentTable.FindRows(Filter_By_Field);
	
		If FoundRowsInDocumentTable.Count() > 0 Then
		
			For Each CurrentRow In FoundRowsInDocumentTable Do
				
				DocumentTable.Delete(CurrentRow);	
			
			EndDo;	
		
		EndIf;	
		
	EndDo;
	
EndProcedure	
	
Procedure UpdateTableInDocument(DocumentObject, ColumnDescription, DataTable, NameOfFilterField, QueryExecutionResult)
	
	If DataTable.Count() = 0 Then
		Return;
	EndIf;
	
	Filter_By_Field = New Structure(NameOfFilterField);
	
	DocumentTable = DocumentObject[ColumnDescription];
	
	TableByFilter = DataTable.Copy(, NameOfFilterField);
	TableByFilter.GroupBy(NameOfFilterField);
	
	//Clearing the data that needs to be overwritten
	For Each CurrentRowOfSelectionTable In TableByFilter Do
		
		Filter_By_Field[NameOfFilterField] = CurrentRowOfSelectionTable[NameOfFilterField];
		
		FoundRowsInDocumentTable = DocumentTable.FindRows(Filter_By_Field);
	
		If FoundRowsInDocumentTable.Count() > 0 Then
		
			For Each CurrentRow In FoundRowsInDocumentTable Do
				
				DocumentTable.Delete(CurrentRow);	
			
			EndDo;	
		
		EndIf;	
		
	EndDo;
	
	//Adding new data
	For Each CurrentDataDataTable In DataTable Do
		If CurrentDataDataTable.AllAutoCalculationsAreCompleted = NULL Then   
			
			If ColumnDescription = "Accruals" Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По сотруднику %1, некорректно введено начисление %2 Сумма %3';
																							|vi = 'For employee %1, the %2 accrual (amount %3)  is incorrect';
																							|en = 'For employee %1, the %2 accrual (amount %3)  is incorrect'; fa = 'For employee %1, the %2 accrual (amount %3)  is incorrect';
																							|it = 'For employee %1, the %2 accrual (amount %3)  is incorrect';
																							|pl = 'For employee %1, the %2 accrual (amount %3)  is incorrect';
																							|tr = 'Çalışan %1 için %2 tahakkuku hatalı girilmiştir. Tutar %3'"),
					CurrentDataDataTable.Employee, CurrentDataDataTable.AccrualKind, CurrentDataDataTable.Sum);   
					
				AddErrorOnAccruals(QueryExecutionResult, CurrentDataDataTable, MessageText);					
			ElsIf ColumnDescription = "Retention" Then
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'По сотруднику %1, некорректно введено удержание %2 Сумма %3';
																							|vi = 'For employee %1, the %2 deduction (amount %3)  is incorrect';
																							|en = 'For employee %1, the %2 deduction (amount %3)  is incorrect'; fa = 'For employee %1, the %2 deduction (amount %3)  is incorrect';
																							|it = 'For employee %1, the %2 deduction (amount %3)  is incorrect';
																							|pl = 'For employee %1, the %2 deduction (amount %3)  is incorrect';
																							|tr = 'Çalışan %1 için %2 kesintisi hatalı girilmiştir. Tutar %3'"),
					CurrentDataDataTable.Employee, CurrentDataDataTable.DeductionKind, CurrentDataDataTable.Sum);

					AddRetentionError(QueryExecutionResult, CurrentDataDataTable, MessageText);					
					
			EndIf;			
		
			Continue;
		EndIf;	
		
		If Not CurrentDataDataTable.AllAutoCalculationsAreCompleted Then
			Continue;
		EndIf;	
		
		NewRow = DocumentTable.Add();
		FillPropertyValues(NewRow , CurrentDataDataTable);		
		
		If ColumnDescription = "Accruals"
			Or ColumnDescription = "PayrollTaxes" Then
			
			If Not ValueIsFilled(NewRow.PostingOption) Then
				NewRow.PostingOption = 
					Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses;
			ElsIf NewRow.PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities Then
			
				NewRow.ExpenseItem = CurrentDataDataTable.ExpenseAssetLiabilityItem;
				NewRow.AssetsLiabilitiesDimension = CurrentDataDataTable.DimensionOfExpensesAssetsLiabilities;
				
            EndIf;

			NewRow.GLAccountSettings = CurrentDataDataTable.ExpenseLedgerAccountsSettings;
			
		ElsIf ColumnDescription = "Deductions" Then
			
			If Not ValueIsFilled(NewRow.PostingOption) Then
				NewRow.PostingOption = 
					Enums.AccrualsDeductionsRecordOptions.RecogniseAsOtherIncome;
			ElsIf NewRow.PostingOption = Enums.AccrualsDeductionsRecordOptions.RecognizeAsOtherAssetsLiabilities Then
				
				NewRow.IncomeItem = CurrentDataDataTable.IncomeAssetLiabilityItem;
				NewRow.AssetsLiabilitiesDimension = CurrentDataDataTable.DimensionOfIncomeAssetsLiabilities;
				
            EndIf;

			NewRow.GLAccountSettings = CurrentDataDataTable.IncomeLedgerAccountsSettings;
			
		EndIf;
			
	EndDo;	
	
EndProcedure

Function CheckCalculationOfAccruals(POAccrualTable, QueryExecutionResult)
	ArrayOfEmployeesWithAccrualErrors = New Array();
	
	If POAccrualTable.Count() = 0 Then
		Return ArrayOfEmployeesWithAccrualErrors;
	EndIf;	
	
	For Each CurrentRowTableOfPOAccruals In	POAccrualTable Do
		
		If CurrentRowTableOfPOAccruals.Sum = 0
			And (CurrentRowTableOfPOAccruals.MandatoryAccrual)  Then
			
			If CurrentRowTableOfPOAccruals.InputFrequency = 2 Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По сотруднику %1, не введена сумма начисления %2, в месяце: %3, документом: Разовые начисления';
						|vi = 'For employee %1, the accrual amount (%2) is not entered in %3 by the ""One-time accruals"" document';
						|en = 'For employee %1, the accrual amount (%2) is not entered in %3 by the ""One-time accruals"" document'; fa = 'For employee %1, the accrual amount (%2) is not entered in %3 by the ""One-time accruals"" document';
						|it = 'For employee %1, the accrual amount (%2) is not entered in %3 by the ""One-time accruals"" document';
						|pl = 'For employee %1, the accrual amount (%2) is not entered in %3 by the ""One-time accruals"" document';
						|tr = 'Çalışan %1 için %3 ayında Tek seferlik tahakkuklar belgesiyle %2 tahakkuk tutarı girilmemiştir.'"), 
					CurrentRowTableOfPOAccruals.Employee, 
					CurrentRowTableOfPOAccruals.Accrual, 
					CurrentRowTableOfPOAccruals.Period);
			Else
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("ru = 'По сотруднику %1, не указана сумма начисления: %2';
															|vi = 'For employee %1, the accrual amount is not specified: %2';
															|en = 'For employee %1, the accrual amount is not specified: %2'; fa = 'For employee %1, the accrual amount is not specified: %2';
															|it = 'For employee %1, the accrual amount is not specified: %2';
															|pl = 'For employee %1, the accrual amount is not specified: %2';
															|tr = 'Çalışan %1 için tahakkuk tutarı belirtilmemiştir: %2'"), 
														CurrentRowTableOfPOAccruals.Employee, 
														CurrentRowTableOfPOAccruals.Accrual);
			EndIf;																		
			
			AddErrorOnAccruals(QueryExecutionResult, CurrentRowTableOfPOAccruals, MessageText);
			
			ArrayOfEmployeesWithAccrualErrors.Add(CurrentRowTableOfPOAccruals.Employee);
			
		EndIf;	
		
	EndDo;	
	
	Return ArrayOfEmployeesWithAccrualErrors;
	
EndFunction

Function CheckDeductionCalculation(TableOfPODeductions, QueryExecutionResult)
	ArrayOfEmployeesWithRetentionErrors = New Array();
	
	If TableOfPODeductions.Count() = 0 Then
		Return ArrayOfEmployeesWithRetentionErrors;
	EndIf;	
	
	For Each CurrentRowTableOfPODeductions In	TableOfPODeductions Do
		
		If CurrentRowTableOfPODeductions.Sum = 0
			And (CurrentRowTableOfPODeductions.MandatoryRetention)  Then
			
			If CurrentRowTableOfPODeductions.InputFrequency = 2 Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По сотруднику %1, не введена сумма удержания %2, в месяце: %3, документом: Разовые удержания';
						|vi = 'For employee %1, the deduction amount (%2) is not entered in %3 by the ""One-time deductions"" document';
						|en = 'For employee %1, the deduction amount (%2) is not entered in %3 by the ""One-time deductions"" document'; fa = 'For employee %1, the deduction amount (%2) is not entered in %3 by the ""One-time deductions"" document';
						|it = 'For employee %1, the deduction amount (%2) is not entered in %3 by the ""One-time deductions"" document';
						|pl = 'For employee %1, the deduction amount (%2) is not entered in %3 by the ""One-time deductions"" document';
						|tr = 'Çalışan %1 için %3 ayında Tek seferlik kesintiler belgesiyle %2 kesintisi girilmemiştir.'"), 
					CurrentRowTableOfPODeductions.Employee,
					CurrentRowTableOfPODeductions.Retention,
					CurrentRowTableOfPODeductions.Period);
			Else
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
														NStr("ru = 'По сотруднику %1, не указана сумма удержания: %2';
															|vi = 'For employee %1, the deduction amount is not specified: %2';
															|en = 'For employee %1, the deduction amount is not specified: %2'; fa = 'For employee %1, the deduction amount is not specified: %2';
															|it = 'For employee %1, the deduction amount is not specified: %2';
															|pl = 'For employee %1, the deduction amount is not specified: %2';
															|tr = 'Çalışan %1 için kesinti tutarı belirtilmemiştir: %2'"), 
														CurrentRowTableOfPODeductions.Employee,
														CurrentRowTableOfPODeductions.Retention);

			EndIf;
																	
			AddRetentionError(QueryExecutionResult, CurrentRowTableOfPODeductions, MessageText);
			
			ArrayOfEmployeesWithRetentionErrors.Add(CurrentRowTableOfPODeductions.Employee);
			
		EndIf;	
		
	EndDo;	
	
	Return ArrayOfEmployeesWithRetentionErrors;
	
EndFunction

Function CheckTaxCalculation(POTaxTable, QueryExecutionResult) 
	
	ArrayOfPersonsWithTaxErrors = New Array();
	
	If POTaxTable.Count() = 0 Then
		Return ArrayOfPersonsWithTaxErrors;
	EndIf;	
	
	For Each CurrentRowTableOfTaxesPO In POTaxTable Do
		If CurrentRowTableOfTaxesPO.ThisIsNonTaxableAccrualOfThisTax Then
			Continue;
		EndIf;	
		
		If CurrentRowTableOfTaxesPO.Sum = 0 Then
			
			If CurrentRowTableOfTaxesPO.EnteringTaxManually Then
				
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'По физическому лицу %1, не введена сумма налога %2, в месяце: %3, документом Ручной расчет налогов';
						|vi = 'For %1, the ""%2"" tax amount is not specified in %3 by the ""Manual tax calculation"" document';
						|en = 'For %1, the ""%2"" tax amount is not specified in %3 by the ""Manual tax calculation"" document'; fa = 'For %1, the ""%2"" tax amount is not specified in %3 by the ""Manual tax calculation"" document';
						|it = 'For %1, the ""%2"" tax amount is not specified in %3 by the ""Manual tax calculation"" document';
						|pl = 'For %1, the ""%2"" tax amount is not specified in %3 by the ""Manual tax calculation"" document';
						|tr = 'Gerçek kişi %1 için %3 ayında Manuel vergi hesaplama belgesiyle %2 vergisi girilmemiştir.'"), 
					CurrentRowTableOfTaxesPO.Individual, 
					CurrentRowTableOfTaxesPO.TaxKind, 
					CurrentRowTableOfTaxesPO.Period);
			Else
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											NStr("ru = 'По физическому лицу %1, по налогу %2  не указана сумма: %3';
												|vi = 'For %1, the amount (%3) is not specified for the ""%2"" tax';
												|en = 'For %1, the amount (%3) is not specified for the ""%2"" tax'; fa = 'For %1, the amount (%3) is not specified for the ""%2"" tax';
												|it = 'For %1, the amount (%3) is not specified for the ""%2"" tax';
												|pl = 'For %1, the amount (%3) is not specified for the ""%2"" tax';
												|tr = 'Gerçek kişi %1 için %2 vergisinde tutar belirtilmemiştir: %3'"),
											CurrentRowTableOfTaxesPO.Individual,
											CurrentRowTableOfTaxesPO.TaxKind,
											CurrentRowTableOfTaxesPO.Sum);   
			EndIf;
			
			AddErrorOnTaxes(QueryExecutionResult, CurrentRowTableOfTaxesPO, MessageText);
			
			ArrayOfPersonsWithTaxErrors.Add(CurrentRowTableOfTaxesPO.Individual);
			
		EndIf;	
		
	EndDo;	
	
	Return ArrayOfPersonsWithTaxErrors;
	
EndFunction

Procedure AddErrorToPOStatuses(QueryExecutionResult, CurrentRowInPOStatusTable, MessageText)
	
	ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(MessageText);
	ErrorParameters.Employee = CurrentRowInPOStatusTable.Employee;  
    ErrorParameters.Department = CurrentRowInPOStatusTable.Department;
	ErrorParameters.ErrorInTimesheets = True;
	
	PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);	
	
EndProcedure	

Procedure AddErrorOnAccruals(QueryExecutionResult, CurrentRowTableOfPOAccruals, MessageText)
	
	ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(MessageText);
	ErrorParameters.Employee = CurrentRowTableOfPOAccruals.Employee;
	ErrorParameters.Individual = CurrentRowTableOfPOAccruals.Individual;
    ErrorParameters.Department = CurrentRowTableOfPOAccruals.Department;
	ErrorParameters.ErrorInAccruals = True;
	
	PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);	
	
EndProcedure	

Procedure AddRetentionError(QueryExecutionResult, CurrentRowTableOfPODeductions, MessageText)
	
	ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(MessageText);
	ErrorParameters.Employee = CurrentRowTableOfPODeductions.Employee;
	ErrorParameters.Individual = CurrentRowTableOfPODeductions.Individual;
    ErrorParameters.Department = CurrentRowTableOfPODeductions.Department;
	ErrorParameters.ErrorInDeductions = True;
	
	PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);	
	
EndProcedure

Procedure AddErrorOnTaxes(QueryExecutionResult, CurrentRowTableOfTaxesPO, MessageText)
	
	ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(MessageText);
	ErrorParameters.Individual = CurrentRowTableOfTaxesPO.Individual;
    ErrorParameters.Department =  CurrentRowTableOfTaxesPO.Department;
	ErrorParameters.EmployeeTaxError =     CurrentRowTableOfTaxesPO.DeductedFromEmployeeWages;
	ErrorParameters.ErrorInCompanyTaxes = Not CurrentRowTableOfTaxesPO.DeductedFromEmployeeWages;
	
	PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);	
	
EndProcedure

Procedure AddErrorOnAmountToBePaid(QueryExecutionResult, CurrentRowPreparedDataStatusTable, MessageText)
	
	ErrorParameters = PayrollCalculationHRServer.NewErrorParameters(MessageText);
	ErrorParameters.Employee = CurrentRowPreparedDataStatusTable.Employee;
	ErrorParameters.Individual = CurrentRowPreparedDataStatusTable.Individual;
    ErrorParameters.Department =  CurrentRowPreparedDataStatusTable.Department;
	
	PayrollCalculationHRServer.AddErrorToErrorArray(QueryExecutionResult, ErrorParameters);	
	
EndProcedure

Function FindLinkToDocumentPayrollReflectionInInternationalAccounting(CalculationParameters)
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	PostingPayrollExpensesInFinancialAccounting2_5.Ref AS Ref
	|FROM
	|	Document.PostingPayrollExpensesInFinancialAccounting2_5 AS PostingPayrollExpensesInFinancialAccounting2_5
	|WHERE
	|	NOT PostingPayrollExpensesInFinancialAccounting2_5.DeletionMark
	|	AND PostingPayrollExpensesInFinancialAccounting2_5.Organization = &Organization
	|	AND PostingPayrollExpensesInFinancialAccounting2_5.CalculationsPeriod = &CalculationPeriod";
	
	Query.SetParameter("Organization", CalculationParameters.Organization);
	Query.SetParameter("CalculationPeriod", CalculationParameters.CalculationPeriod); 
	Result = Query.Execute();	
	
	If Result.IsEmpty() Then
		DocumentObject = Documents.PostingPayrollExpensesInFinancialAccounting2_5.CreateDocument();
		DocumentObject.Organization = CalculationParameters.Organization;
		DocumentObject.CalculationsPeriod = CalculationParameters.CalculationPeriod;  
		DocumentObject.Date = EndOfMonth(CalculationParameters.CalculationPeriod);
		DocumentObject.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(CalculationParameters.Organization);
		DocumentObject.EmployeeResponsible = Users.CurrentUser();
		DocumentObject.ARAPType = Catalogs.TypesOfEmployeeCompensations.Payroll;
		DocumentObject.AccrualsAndTaxesDetailedByPersons = True;
		DocumentObject.Write();
		DocumentRef = DocumentObject.Ref;
	Else
		
		Selection = Result.Select();
		Selection.Next();
		DocumentRef = Selection.Ref;
	EndIf;	

	Return DocumentRef;
EndFunction	

// Calculates the retention amount based on the prepared calculation data.
//
// Parameters:
//   LineFromPreparedCalculationData - Structure - a string of prepared data for calculation
//   ArrayOfErrorText - Array of Structure - array for accumulating error messages
//
// Returns:
//   Number - Retention Amount
Function CalculateRetentionAmount(LineFromPreparedCalculationData, ArrayOfErrorText)
	
	RetentionAmount = LineFromPreparedCalculationData.Sum;
	
	Return RetentionAmount;
	
EndFunction	

Function CalculateAccrualAmount(LineFromPreparedCalculationData, ArrayOfErrorText)
	
	ArrayOfTextIndicators = SetUpCalculationFormula.OperandsOfTextFormula(
						LineFromPreparedCalculationData.CalculationFormula); 
	OperandValues = New Map();					

	For Each CurrentTextIndicator In ArrayOfTextIndicators Do
		FoundIndicator = Catalogs.CalculationIndicatorsHR[CurrentTextIndicator];
		
		If FoundIndicator = Catalogs.CalculationIndicatorsHR.BaseSalary Then
			
			If LineFromPreparedCalculationData.BasicEarnings Then
				CertainValue = LineFromPreparedCalculationData.Value;
			Else     
				CertainValue = LineFromPreparedCalculationData.AmountOfBasicEarnings;
			EndIf;	
			
		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.TimeInDays Then
			
			CertainValue = LineFromPreparedCalculationData.DaysWorked; 
			
		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.TimeInHours Then
			
			CertainValue = LineFromPreparedCalculationData.HoursWorked; 
			
		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.NormOfHours Then
			
			// If a norm is introduced for the main earnings, then we take this norm.
			If Not LineFromPreparedCalculationData.BasicEarnings 
				And LineFromPreparedCalculationData.AccrualOfBasicEarningsRequiresInWatersOfNorm Then
				CertainValue = LineFromPreparedCalculationData.NormIsHoursForBasicEarnings; 
				LineFromPreparedCalculationData.NormOfHours = CertainValue;

			Else	
				CertainValue = LineFromPreparedCalculationData.NormOfHours; 
			EndIf;	
			
		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.NormalWorkdays Then

			// If a norm is introduced for the main earnings, then we take this norm.
			If Not LineFromPreparedCalculationData.BasicEarnings 
				And LineFromPreparedCalculationData.AccrualOfBasicEarningsRequiresInWatersOfNorm Then 
				CertainValue = LineFromPreparedCalculationData.NormIsDaysForBasicEarnings; 
				LineFromPreparedCalculationData.NormalWorkdays = CertainValue;
			Else	
				CertainValue = LineFromPreparedCalculationData.NormalWorkdays; 
			EndIf;	
			
		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.Development_1 Then
			
			CertainValue = LineFromPreparedCalculationData.Value; 

		ElsIf FoundIndicator = Catalogs.CalculationIndicatorsHR.AmountByAccrual Then
			
			CertainValue = LineFromPreparedCalculationData.Value; 
						
		Else                             
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Не найден показатель %1';
																						|vi = 'The ""%1"" indicator is not found';
																						|en = 'The ""%1"" indicator is not found'; fa = 'The ""%1"" indicator is not found';
																						|it = 'The ""%1"" indicator is not found';
																						|pl = 'The ""%1"" indicator is not found';
																						|tr = '%1 göstergesi bulunamadı'"),
																		CurrentTextIndicator,);
			
			ArrayOfErrorText.Add(MessageText);	
			
			Continue;
		EndIf;	
			
		OperandValues.Insert(CurrentTextIndicator, CertainValue); 

	EndDo;
	
	If Not CalculationByFormulaIsSafe(LineFromPreparedCalculationData, ArrayOfErrorText, OperandValues) Then
		
		Return 0;
		
	EndIf;

	CalculationFormula = CheckCalculationFormula(LineFromPreparedCalculationData.CalculationFormula);

	ResultOfCalculationAccordingToFormula = SetUpCalculationFormula.PerformCalculationsUsingFormula(
															CalculationFormula,
															ArrayOfTextIndicators,
															OperandValues, ArrayOfErrorText);
															
	Return Number(ResultOfCalculationAccordingToFormula);														
	
EndFunction

Function CheckCalculationFormula(CalculationFormula)

	CalculationFormula = StrReplace(CalculationFormula, ",", ".");
	
	Return CalculationFormula;
EndFunction	

Function CalculationByFormulaIsSafe(LineFromPreparedCalculationData, ArrayOfErrorText, OperandValues)
	
	If Not ValueIsFilled(LineFromPreparedCalculationData.AccrualMethod) Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("ru = 'У сотрудника %1, не указан способ начисления у начисления: %2';
													|vi = 'For employee %1, the accrual method is not specified for the ""%2"" accrual';
													|en = 'For employee %1, the accrual method is not specified for the ""%2"" accrual'; fa = 'For employee %1, the accrual method is not specified for the ""%2"" accrual';
													|it = 'For employee %1, the accrual method is not specified for the ""%2"" accrual';
													|pl = 'For employee %1, the accrual method is not specified for the ""%2"" accrual';
													|tr = 'Çalışan %1 için %2 tahakkukunda tahakkuk yöntemi belirtilmemiştir.'"),
												LineFromPreparedCalculationData.Employee, LineFromPreparedCalculationData.Accrual);
			
			ArrayOfErrorText.Add(MessageText);	
		Return False;
	EndIf;
	
	If LineFromPreparedCalculationData.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked Then
		
		 Value = OperandValues.Get("NormalWorkdays");
		 If Value = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("ru = 'У сотрудника %1, не указана норма дней, для вида времени: %2 начисления: %3. Проверьте документ: Нормы рабочего времени';
													|vi = 'Employee %1 has no specified normal working days for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours"" document';
													|en = 'Employee %1 has no specified normal working days for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours"" document'; fa = 'Employee %1 has no specified normal working days for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours"" document';
													|it = 'Employee %1 has no specified normal working days for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours"" document';
													|pl = 'Employee %1 has no specified normal working days for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours"" document';
													|tr = 'Çalışan %1 için %3 tahakkukunda, %2 zaman türü için gün normu belirtilmemiştir. Belgeyi kontrol edin: Çalışma zamanı normları'"),
												LineFromPreparedCalculationData.Employee,
												LineFromPreparedCalculationData.PayCode, 
												LineFromPreparedCalculationData.Accrual);
			
			ArrayOfErrorText.Add(MessageText);
		 EndIf;	
		 
	ElsIf  LineFromPreparedCalculationData.AccrualMethod = Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked Then
		
		 Value = OperandValues.Get("NormOfHours");  
		 
		 If Value = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("ru = 'У сотрудника %1, не указана норма часов, для вида времени: %2 начисления: %3. Проверьте документ: Нормы рабочего времени';
													|vi = 'Employee %1 has no specified normal working hours for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours""  document';
													|en = 'Employee %1 has no specified normal working hours for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours""  document'; fa = 'Employee %1 has no specified normal working hours for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours""  document';
													|it = 'Employee %1 has no specified normal working hours for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours""  document';
													|pl = 'Employee %1 has no specified normal working hours for the ""%2"" work time type, the ""%3"" accrual. Check the ""Normal working hours""  document';
													|tr = 'Çalışan %1 için %3 tahakkukunda, %2 zaman türü için saat normu belirtilmemiştir. Belgeyi kontrol edin: Çalışma zamanı normları'"),
												LineFromPreparedCalculationData.Employee,
												LineFromPreparedCalculationData.PayCode, 
												LineFromPreparedCalculationData.Accrual);
			
			ArrayOfErrorText.Add(MessageText);
		 EndIf;	
		 
	EndIf;	
	
	Return ArrayOfErrorText.Count() = 0;
	
EndFunction	

Function CalculateAccruals(CalculationParameters, QueryExecutionResult)
	
	Organization = CalculationParameters.Organization;
	CalculationPeriod = CalculationParameters.CalculationPeriod;
	CalculationStatusTable = CalculationParameters.CalculationStatuses;
	ArrayOfEmployees = CalculationStatusTable.UnloadColumn("Employee");
	
	Query = New Query();   
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("SettlementStartDate", CalculationPeriod);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("Department", CalculationParameters.Department);
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);
	
	Query.Text = 
	"SELECT
	|	&SettlementStartDate AS Period,
	|	EmploymentRecordSliceLast.Organization AS Organization,
	|	EmploymentRecordSliceLast.Department AS Department,
	|	EmploymentRecordSliceLast.Employee AS Employee,
	|	EmploymentRecordSliceLast.WorkScheduleCalendar AS WorkScheduleCalendar
	|INTO PersonnelHistoryIsDetailed
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&SettlementStartDate, Employee IN (&ArrayOfEmployees)) AS EmploymentRecordSliceLast
	|WHERE
	|	EmploymentRecordSliceLast.WorksInBusinessUnit = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	EmploymentRecord.Period,
	|	EmploymentRecord.Organization,
	|	EmploymentRecord.Department,
	|	EmploymentRecord.Employee,
	|	EmploymentRecord.WorkScheduleCalendar
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.WorksInBusinessUnit = TRUE
	|	AND EmploymentRecord.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND EmploymentRecord.Employee IN(&ArrayOfEmployees)
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHR.Period,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee,
	|	CASE
	|		WHEN ISNULL(EmploymentRecord.WorkScheduleCalendar, 0) = 0
	|			THEN EmploymentRecordSliceLast.WorkScheduleCalendar
	|		ELSE EmploymentRecord.WorkScheduleCalendar
	|	END
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|		LEFT JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON RegularAccrualsAndDeductionsHR.Organization = EmploymentRecord.Organization
	|			AND RegularAccrualsAndDeductionsHR.Department = EmploymentRecord.Department
	|			AND RegularAccrualsAndDeductionsHR.Employee = EmploymentRecord.Employee
	|			AND RegularAccrualsAndDeductionsHR.Period >= EmploymentRecord.Period
	|			AND (EmploymentRecord.WorksInBusinessUnit = TRUE)
	|			AND (EmploymentRecord.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH))
	|			AND (EmploymentRecord.Employee IN (&ArrayOfEmployees))
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&SettlementStartDate, Employee IN (&ArrayOfEmployees)) AS EmploymentRecordSliceLast
	|		ON RegularAccrualsAndDeductionsHR.Organization = EmploymentRecordSliceLast.Organization
	|			AND RegularAccrualsAndDeductionsHR.Department = EmploymentRecordSliceLast.Department
	|			AND RegularAccrualsAndDeductionsHR.Employee = EmploymentRecordSliceLast.Employee
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND RegularAccrualsAndDeductionsHR.Employee IN(&ArrayOfEmployees)
	|	AND RegularAccrualsAndDeductionsHR.Valid
	|	AND RegularAccrualsAndDeductionsHR.BasicEarnings
	|
	|GROUP BY
	|	RegularAccrualsAndDeductionsHR.Period,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee,
	|	CASE
	|		WHEN ISNULL(EmploymentRecord.WorkScheduleCalendar, 0) = 0
	|			THEN EmploymentRecordSliceLast.WorkScheduleCalendar
	|		ELSE EmploymentRecord.WorkScheduleCalendar
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EmploymentRecord.Period AS Period,
	|	EmploymentRecord.Organization AS Organization,
	|	EmploymentRecord.Department AS Department,
	|	EmploymentRecord.Employee AS Employee
	|INTO PersonnelHistoryDetailedDisabled
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.WorksInBusinessUnit = FALSE
	|	AND EmploymentRecord.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND EmploymentRecord.Employee IN(&ArrayOfEmployees)
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHR.Period,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|		LEFT JOIN InformationRegister.EmploymentRecord AS EmploymentRecord
	|		ON RegularAccrualsAndDeductionsHR.Organization = EmploymentRecord.Organization
	|			AND RegularAccrualsAndDeductionsHR.Department = EmploymentRecord.Department
	|			AND RegularAccrualsAndDeductionsHR.Employee = EmploymentRecord.Employee
	|			AND RegularAccrualsAndDeductionsHR.Period >= EmploymentRecord.Period
	|			AND (EmploymentRecord.WorksInBusinessUnit = FALSE)
	|			AND (EmploymentRecord.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH))
	|			AND (EmploymentRecord.Employee IN (&ArrayOfEmployees))
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND RegularAccrualsAndDeductionsHR.Employee IN(&ArrayOfEmployees)
	|	AND NOT RegularAccrualsAndDeductionsHR.Valid
	|	AND RegularAccrualsAndDeductionsHR.BasicEarnings
	|
	|GROUP BY
	|	RegularAccrualsAndDeductionsHR.Period,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PersonnelHistoryDetailedDisabled.Period AS Period,
	|	PersonnelHistoryDetailedDisabled.Organization AS Organization,
	|	PersonnelHistoryDetailedDisabled.Department AS Department,
	|	PersonnelHistoryDetailedDisabled.Employee AS Employee
	|INTO PersonnelHistoryDisabled
	|FROM
	|	PersonnelHistoryDetailedDisabled AS PersonnelHistoryDetailedDisabled
	|
	|GROUP BY
	|	PersonnelHistoryDetailedDisabled.Period,
	|	PersonnelHistoryDetailedDisabled.Department,
	|	PersonnelHistoryDetailedDisabled.Employee,
	|	PersonnelHistoryDetailedDisabled.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PersonnelHistoryIsDetailed.Period AS PeriodBeginning,
	|	PersonnelHistoryIsDetailed.Organization AS Organization,
	|	PersonnelHistoryIsDetailed.Department AS Department,
	|	PersonnelHistoryIsDetailed.Employee AS Employee,
	|	ISNULL(PersonnelHistoryDisabled.Period, DATETIME(1, 1, 1)) AS PeriodEnd_,
	|	PersonnelHistoryIsDetailed.WorkScheduleCalendar AS WorkScheduleCalendar
	|INTO PersonnelHistorySelected
	|FROM
	|	PersonnelHistoryIsDetailed AS PersonnelHistoryIsDetailed
	|		LEFT JOIN PersonnelHistoryDisabled AS PersonnelHistoryDisabled
	|		ON PersonnelHistoryIsDetailed.Organization = PersonnelHistoryDisabled.Organization
	|			AND PersonnelHistoryIsDetailed.Department = PersonnelHistoryDisabled.Department
	|			AND PersonnelHistoryIsDetailed.Employee = PersonnelHistoryDisabled.Employee
	|			AND (PersonnelHistoryIsDetailed.Period < PersonnelHistoryDisabled.Period)
	|			AND (PersonnelHistoryDisabled.Employee IN (&ArrayOfEmployees))
	|			AND (PersonnelHistoryDisabled.Organization = &Organization)
	|			
	|
	|GROUP BY
	|	PersonnelHistoryIsDetailed.Employee,
	|	PersonnelHistoryIsDetailed.Organization,
	|	PersonnelHistoryIsDetailed.Period,
	|	PersonnelHistoryIsDetailed.Department,
	|	ISNULL(PersonnelHistoryDisabled.Period, DATETIME(1, 1, 1)),
	|	PersonnelHistoryIsDetailed.WorkScheduleCalendar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnEmployeeTimesheetTurnovers.Organization AS Organization,
	|	DataOnEmployeeTimesheetTurnovers.Employee AS Employee,
	|	DataOnEmployeeTimesheetTurnovers.TimeKind AS TimeKind,
	|	DataOnEmployeeTimesheetTurnovers.DaysTurnover AS DaysWorked,
	|	DataOnEmployeeTimesheetTurnovers.Hours1Turnover AS HoursWorked,
	|	DataOnEmployeeTimesheetTurnovers.Period AS DateDay
	|INTO Timekeeping
	|FROM
	|	AccumulationRegister.DataOnEmployeeTimesheet.Turnovers(&SettlementStartDate, ENDOFPERIOD(&SettlementStartDate, MONTH), Day, Employee IN (&ArrayOfEmployees)) AS DataOnEmployeeTimesheetTurnovers
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StandardWorkingHoursStandardsByPayCodes.PayCode AS PayCode,
	|	StandardWorkingHoursStandardsByPayCodes.StandardDays AS StandardDays,
	|	StandardWorkingHoursStandardsByPayCodes.StandardHours AS StandardHours,
	|	StandardWorkingHours.ScheduleOfWork AS ScheduleOfWork,
	|	CASE
	|		WHEN StandardWorkingHours.ScheduleOfWork = VALUE(Catalog.Calendars.EmptyRef)
	|			THEN 1
	|		ELSE 2
	|	END AS OrderOfUse
	|INTO WorkingTimeStandards
	|FROM
	|	Document.StandardWorkingHours.StandardsByPayCodes AS StandardWorkingHoursStandardsByPayCodes
	|		LEFT JOIN Document.StandardWorkingHours AS StandardWorkingHours
	|		ON StandardWorkingHoursStandardsByPayCodes.Ref = StandardWorkingHours.Ref
	|WHERE
	|	StandardWorkingHours.Posted
	|	AND StandardWorkingHours.RegistrationMonth = &SettlementStartDate
	|
	|INDEX BY
	|	PayCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkingTimeStandards.PayCode AS PayCode,
	|	WorkingTimeStandards.StandardDays AS StandardDays,
	|	WorkingTimeStandards.StandardHours AS StandardHours,
	|	WorkingTimeStandards.ScheduleOfWork AS ScheduleOfWork
	|INTO WorkingTimeStandardsForEveryoneByDefault
	|FROM
	|	WorkingTimeStandards AS WorkingTimeStandards
	|WHERE
	|	WorkingTimeStandards.OrderOfUse = 1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	WorkingTimeStandards.PayCode AS PayCode,
	|	WorkingTimeStandards.StandardDays AS StandardDays,
	|	WorkingTimeStandards.StandardHours AS StandardHours,
	|	WorkingTimeStandards.ScheduleOfWork AS ScheduleOfWork
	|INTO WorkingTimeStandardsAccordingToWorkSchedule
	|FROM
	|	WorkingTimeStandards AS WorkingTimeStandards
	|WHERE
	|	WorkingTimeStandards.OrderOfUse = 2
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&SettlementStartDate AS ValidityStartDate,
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization AS Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department AS Department,
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction AS Accrual,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value,
	|	RegularAccrualsAndDeductionsHRSliceLast.Valid AS Valid,
	|	RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings AS BasicEarnings,
	|	CASE
	|		WHEN ISNULL(RegularAccrualsAndDeductionsOfHRAreNotValid.Period, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|			THEN RegularAccrualsAndDeductionsOfHRAreNotValid.Period
	|		WHEN ISNULL(RegularAccrualsAndHRDeductionsAreValid.Period, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|			THEN RegularAccrualsAndHRDeductionsAreValid.Period
	|		ELSE DATETIME(1, 1, 1)
	|	END AS EndOfPeriod,
	|	RegularAccrualsAndDeductionsHRSliceLast.TimeKindForNorms AS TimeKindForNorms
	|INTO DetailedTableOfAccrualsOfDeductions
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&SettlementStartDate,
	|			Employee IN (&ArrayOfEmployees)
	|				) AS RegularAccrualsAndDeductionsHRSliceLast
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsOfHRAreNotValid
	|		ON RegularAccrualsAndDeductionsHRSliceLast.Organization = RegularAccrualsAndDeductionsOfHRAreNotValid.Organization
	|			AND RegularAccrualsAndDeductionsHRSliceLast.Department = RegularAccrualsAndDeductionsOfHRAreNotValid.Department
	|			AND RegularAccrualsAndDeductionsHRSliceLast.Employee = RegularAccrualsAndDeductionsOfHRAreNotValid.Employee
	|			AND RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction = RegularAccrualsAndDeductionsOfHRAreNotValid.AccrualDeduction
	|			AND (RegularAccrualsAndDeductionsOfHRAreNotValid.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH))
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Recorder REFS Document.HiringHR)
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Recorder REFS Document.ChangeInBasicEarnings)
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Valid)
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndHRDeductionsAreValid
	|		ON RegularAccrualsAndDeductionsHRSliceLast.Organization = RegularAccrualsAndHRDeductionsAreValid.Organization
	|			AND RegularAccrualsAndDeductionsHRSliceLast.Department = RegularAccrualsAndHRDeductionsAreValid.Department
	|			AND RegularAccrualsAndDeductionsHRSliceLast.Employee = RegularAccrualsAndHRDeductionsAreValid.Employee
	|			AND RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction = RegularAccrualsAndHRDeductionsAreValid.AccrualDeduction
	|			AND (RegularAccrualsAndHRDeductionsAreValid.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH))
	|			AND (NOT RegularAccrualsAndHRDeductionsAreValid.Recorder REFS Document.HiringHR)
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Recorder REFS Document.ChangeInBasicEarnings)
	|			AND (RegularAccrualsAndHRDeductionsAreValid.Valid)
	|
	|
	|	WHERE RegularAccrualsAndDeductionsHRSliceLast.Valid = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	RegularAccrualsAndDeductionsHR.Period,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee,
	|	RegularAccrualsAndDeductionsHR.AccrualDeduction,
	|	RegularAccrualsAndDeductionsHR.Value,
	|	RegularAccrualsAndDeductionsHR.Valid,
	|	RegularAccrualsAndDeductionsHR.BasicEarnings,
	|	CASE
	|		WHEN ISNULL(RegularAccrualsAndDeductionsOfHRAreNotValid.Period, DATETIME(1, 1, 1)) <> DATETIME(1, 1, 1)
	|			THEN RegularAccrualsAndDeductionsOfHRAreNotValid.Period
	|		ELSE DATETIME(1, 1, 1)
	|	END AS EndOfPeriod,
	|	RegularAccrualsAndDeductionsHR.TimeKindForNorms
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|		LEFT JOIN InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsOfHRAreNotValid
	|		ON RegularAccrualsAndDeductionsHR.Organization = RegularAccrualsAndDeductionsOfHRAreNotValid.Organization
	|			AND RegularAccrualsAndDeductionsHR.Department = RegularAccrualsAndDeductionsOfHRAreNotValid.Department
	|			AND RegularAccrualsAndDeductionsHR.Employee = RegularAccrualsAndDeductionsOfHRAreNotValid.Employee
	|			AND RegularAccrualsAndDeductionsHR.Period < RegularAccrualsAndDeductionsOfHRAreNotValid.Period
	|			AND RegularAccrualsAndDeductionsHR.AccrualDeduction = RegularAccrualsAndDeductionsOfHRAreNotValid.AccrualDeduction
	|			AND (RegularAccrualsAndDeductionsOfHRAreNotValid.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH))
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Recorder REFS Document.HiringHR)
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Recorder REFS Document.ChangeInBasicEarnings)
	|			AND (NOT RegularAccrualsAndDeductionsOfHRAreNotValid.Valid)
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND RegularAccrualsAndDeductionsHR.Employee IN(&ArrayOfEmployees)
	|	AND RegularAccrualsAndDeductionsHR.Valid
	|	AND CASE
	|			WHEN RegularAccrualsAndDeductionsHR.Period BETWEEN BEGINOFPERIOD(&SettlementStartDate, DAY) AND &SettlementStartDate
	|				THEN NOT RegularAccrualsAndDeductionsHR.Recorder REFS Document.HiringHR
	|			ELSE TRUE
	|		END
	|
	|INDEX BY
	|	Organization,
	|	Department,
	|	Employee,
	|	Accrual
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailedTableOfAccrualsOfDeductions.ValidityStartDate AS ValidityStartDate,
	|	DetailedTableOfAccrualsOfDeductions.Organization AS Organization,
	|	DetailedTableOfAccrualsOfDeductions.Department AS Department,
	|	DetailedTableOfAccrualsOfDeductions.Employee AS Employee,
	|	CASE
	|		WHEN AccrualAndDeductionKinds.InputFrequency = 2
	|			THEN 0
	|		ELSE DetailedTableOfAccrualsOfDeductions.Value
	|	END AS Value,
	|	DetailedTableOfAccrualsOfDeductions.Valid AS Valid,
	|	DetailedTableOfAccrualsOfDeductions.BasicEarnings AS BasicEarnings,
	|	AccrualAndDeductionKinds.AccrualMethod AS AccrualMethod,
	|	AccrualAndDeductionKinds.CalculationFormula AS CalculationFormula,
	|	AccrualAndDeductionKinds.PayCode AS PayCode,
	|	AccrualAndDeductionKinds.InputFrequency AS InputFrequency,
	|	AccrualAndDeductionKinds.ItIsADeduction AS ItIsADeduction,
	|	DetailedTableOfAccrualsOfDeductions.Accrual AS Accrual,
	|	DetailedTableOfAccrualsOfDeductions.EndOfPeriod AS EndOfPeriod,
	|	AccrualAndDeductionKinds.AccrualMethod = VALUE(Enum.AccrualMethodsPayrollAndHumanResources.Development_1) AS This_Is_Output,
	|	PersonnelHistorySelected.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	DetailedTableOfAccrualsOfDeductions.TimeKindForNorms AS TimeKindForNorms
	|INTO SummaryTableOfAccrualsAndDeductions
	|FROM
	|	DetailedTableOfAccrualsOfDeductions AS DetailedTableOfAccrualsOfDeductions
	|		LEFT JOIN Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|		ON DetailedTableOfAccrualsOfDeductions.Accrual = AccrualAndDeductionKinds.Ref
	|		LEFT JOIN PersonnelHistorySelected AS PersonnelHistorySelected
	|		ON DetailedTableOfAccrualsOfDeductions.Organization = PersonnelHistorySelected.Organization
	|			AND DetailedTableOfAccrualsOfDeductions.Department = PersonnelHistorySelected.Department
	|			AND DetailedTableOfAccrualsOfDeductions.Employee = PersonnelHistorySelected.Employee
	|			AND DetailedTableOfAccrualsOfDeductions.ValidityStartDate = PersonnelHistorySelected.PeriodBeginning
	|WHERE
	|	NOT AccrualAndDeductionKinds.ItIsADeduction
	|
	|GROUP BY
	|	DetailedTableOfAccrualsOfDeductions.Department,
	|	DetailedTableOfAccrualsOfDeductions.Employee,
	|	DetailedTableOfAccrualsOfDeductions.ValidityStartDate,
	|	DetailedTableOfAccrualsOfDeductions.Organization,
	|	DetailedTableOfAccrualsOfDeductions.BasicEarnings,
	|	DetailedTableOfAccrualsOfDeductions.Valid,
	|	AccrualAndDeductionKinds.ItIsADeduction,
	|	AccrualAndDeductionKinds.PayCode,
	|	AccrualAndDeductionKinds.AccrualMethod,
	|	AccrualAndDeductionKinds.CalculationFormula,
	|	AccrualAndDeductionKinds.InputFrequency,
	|	DetailedTableOfAccrualsOfDeductions.Accrual,
	|	DetailedTableOfAccrualsOfDeductions.EndOfPeriod,
	|	PersonnelHistorySelected.WorkScheduleCalendar,
	|	AccrualAndDeductionKinds.AccrualMethod = VALUE(Enum.AccrualMethodsPayrollAndHumanResources.Development_1),
	|	CASE
	|		WHEN AccrualAndDeductionKinds.InputFrequency = 2
	|			THEN 0
	|		ELSE DetailedTableOfAccrualsOfDeductions.Value
	|	END,
	|	DetailedTableOfAccrualsOfDeductions.TimeKindForNorms
	|
	|INDEX BY
	|	ValidityStartDate,
	|	Organization,
	|	Department,
	|	Employee,
	|	PayCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate AS ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee,
	|	SummaryTableOfAccrualsAndDeductions.Value AS Value,
	|	SummaryTableOfAccrualsAndDeductions.Accrual AS Accrual,
	|	SummaryTableOfAccrualsAndDeductions.AccrualMethod AS AccrualMethod,
	|	SummaryTableOfAccrualsAndDeductions.PayCode AS PayCode,
	|	ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.StandardDays, WorkingTimeStandardsForEveryoneByDefault.StandardDays) AS StandardDays,
	|	ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.StandardHours, WorkingTimeStandardsForEveryoneByDefault.StandardHours) AS StandardHours,
	|	CASE
	|		WHEN SummaryTableOfAccrualsAndDeductions.AccrualMethod = VALUE(Enum.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked)
	|				OR SummaryTableOfAccrualsAndDeductions.AccrualMethod = VALUE(Enum.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AccrualOfBasicEarningsRequiresInWatersOfNorm,
	|	SummaryTableOfAccrualsAndDeductions.TimeKindForNorms AS TimeKindForNorms
	|INTO AccrualsBasicEarnings
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN WorkingTimeStandardsForEveryoneByDefault AS WorkingTimeStandardsForEveryoneByDefault
	|		ON SummaryTableOfAccrualsAndDeductions.TimeKindForNorms = WorkingTimeStandardsForEveryoneByDefault.PayCode
	|		LEFT JOIN WorkingTimeStandardsAccordingToWorkSchedule AS WorkingTimeStandardsAccordingToWorkSchedule
	|		ON SummaryTableOfAccrualsAndDeductions.TimeKindForNorms = WorkingTimeStandardsAccordingToWorkSchedule.PayCode
	|			AND SummaryTableOfAccrualsAndDeductions.WorkScheduleCalendar = WorkingTimeStandardsAccordingToWorkSchedule.ScheduleOfWork
	|WHERE
	|	SummaryTableOfAccrualsAndDeductions.BasicEarnings
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department,
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate AS ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee,
	|	SummaryTableOfAccrualsAndDeductions.Accrual AS Accrual,
	|	SUM(ISNULL(AccrualsHRTurnovers.SumTurnover, 0)) AS AmountAccruedInCurrentPeriod
	|INTO TableOfAmountsEnteredThisMonth
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN AccumulationRegister.AccrualsHR.Turnovers(
	|				&SettlementStartDate,
	|				ENDOFPERIOD(&SettlementStartDate, MONTH),
	|				Month,
	|				Organization = &Organization
	|					AND Employee IN (&ArrayOfEmployees)) AS AccrualsHRTurnovers
	|		ON SummaryTableOfAccrualsAndDeductions.Organization = AccrualsHRTurnovers.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Department = AccrualsHRTurnovers.Department
	|			AND SummaryTableOfAccrualsAndDeductions.Employee = AccrualsHRTurnovers.Employee
	|			AND SummaryTableOfAccrualsAndDeductions.Accrual = AccrualsHRTurnovers.Accrual
	|WHERE
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency = 2
	|
	|GROUP BY
	|	SummaryTableOfAccrualsAndDeductions.Organization,
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Employee,
	|	SummaryTableOfAccrualsAndDeductions.Accrual,
	|	SummaryTableOfAccrualsAndDeductions.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NULL AS Date,
	|	NULL AS Ref,
	|	WorkOutput.Department AS Department,
	|	WorkOutput.Organization AS Organization,
	|	WorkOutputEmployees.Employee AS Employee,
	|	WorkOutputEmployees.Employee_ AS Employee_,
	|	SUM(WorkOutputEmployees.Sum) AS Sum,
	|	SUM(WorkOutputEmployees.HoursWorked) AS HoursWorked
	|INTO OutputForEmployees
	|FROM
	|	Document.WorkOutput.Employees AS WorkOutputEmployees
	|		LEFT JOIN Document.WorkOutput AS WorkOutput
	|		ON WorkOutputEmployees.Ref = WorkOutput.Ref
	|WHERE
	|	WorkOutput.Date BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, Month)
	|	AND WorkOutput.Posted
	|	AND WorkOutput.Organization = &Organization
	|	AND WorkOutputEmployees.Employee IN(&ArrayOfEmployees)
	|	AND WorkOutput.WorkOrderKind = VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|
	|GROUP BY
	|	WorkOutputEmployees.Employee_,
	|	WorkOutputEmployees.Employee,
	|	WorkOutput.Department,
	|	WorkOutput.Organization
	|
	|UNION ALL
	|
	|SELECT
	|	WorkOutput.Date,
	|	WorkOutput.Ref,
	|	WorkOutput.Department,
	|	WorkOutput.Organization,
	|	WorkOutputActivityKinds.Employee,
	|	WorkOutputActivityKinds.Employee_,
	|	WorkOutputActivityKinds.Sum,
	|	0
	|FROM
	|	Document.WorkOutput.ActivityKinds AS WorkOutputActivityKinds
	|		LEFT JOIN Document.WorkOutput AS WorkOutput
	|		ON WorkOutputActivityKinds.Ref = WorkOutput.Ref
	|WHERE
	|	WorkOutput.Date BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, Month)
	|	AND WorkOutput.Posted
	|	AND WorkOutput.Organization = &Organization
	|	AND WorkOutputActivityKinds.Employee IN(&ArrayOfEmployees)
	|	AND WorkOutput.WorkOrderKind <> VALUE(Enum.TeamWorkOrderKinds.TeamKind)
	|
	|INDEX BY
	|	Employee,
	|	Organization,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(ISNULL(OutputForEmployees.Sum, 0)) AS Sum,
	|	SUM(ISNULL(OutputForEmployees.HoursWorked, 0)) AS HoursWorked,
	|	SummaryTableOfAccrualsAndDeductions.Accrual AS Accrual,
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee
	|INTO AccrualOutput
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN OutputForEmployees AS OutputForEmployees
	|		ON SummaryTableOfAccrualsAndDeductions.Organization = OutputForEmployees.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Department = OutputForEmployees.Department
	|			AND SummaryTableOfAccrualsAndDeductions.Employee = OutputForEmployees.Employee
	|WHERE
	|	SummaryTableOfAccrualsAndDeductions.AccrualMethod = VALUE(Enum.AccrualMethodsPayrollAndHumanResources.Development_1)
	|
	|GROUP BY
	|	SummaryTableOfAccrualsAndDeductions.Department,
	|	SummaryTableOfAccrualsAndDeductions.Organization,
	|	SummaryTableOfAccrualsAndDeductions.Employee,
	|	SummaryTableOfAccrualsAndDeductions.Accrual
	|
	|INDEX BY
	|	Employee,
	|	Department,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate AS ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee,
	|	SummaryTableOfAccrualsAndDeductions.Accrual AS Accrual,
	|	SummaryTableOfAccrualsAndDeductions.Valid AS Valid,
	|	SummaryTableOfAccrualsAndDeductions.BasicEarnings AS BasicEarnings,
	|	SummaryTableOfAccrualsAndDeductions.AccrualMethod AS AccrualMethod,
	|	SummaryTableOfAccrualsAndDeductions.CalculationFormula AS CalculationFormula,
	|	SummaryTableOfAccrualsAndDeductions.PayCode AS PayCode,
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency AS InputFrequency,
	|	SummaryTableOfAccrualsAndDeductions.ItIsADeduction AS ItIsADeduction,
	|	SUM(ISNULL(Timekeeping.DaysWorked, 0)) AS DaysWorked,
	|	SUM(CASE
	|			WHEN ISNULL(AccrualOutput.HoursWorked, 0) <> 0
	|				THEN AccrualOutput.HoursWorked
	|			ELSE ISNULL(Timekeeping.HoursWorked, 0)
	|		END) AS HoursWorked,
	|	SummaryTableOfAccrualsAndDeductions.Employee.Individual AS Individual,
	|	VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses) AS PostingOption,
	|	TRUE AS MandatoryAccrual,
	|	SummaryTableOfAccrualsAndDeductions.Value AS Value,
	|	SummaryTableOfAccrualsAndDeductions.This_Is_Output AS This_Is_Output,
	|	SummaryTableOfAccrualsAndDeductions.EndOfPeriod AS EndOfPeriod,
	|	SummaryTableOfAccrualsAndDeductions.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	SummaryTableOfAccrualsAndDeductions.TimeKindForNorms AS TimeKindForNorms
	|INTO AccrualTableDistributedACCORDINGToDetailedReportCard
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN Timekeeping AS Timekeeping
	|		ON SummaryTableOfAccrualsAndDeductions.Organization = Timekeeping.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Employee = Timekeeping.Employee
	|			AND SummaryTableOfAccrualsAndDeductions.PayCode = Timekeeping.TimeKind
	|			AND SummaryTableOfAccrualsAndDeductions.ValidityStartDate <= Timekeeping.DateDay
	|			AND (CASE
	|				WHEN SummaryTableOfAccrualsAndDeductions.EndOfPeriod = DATETIME(1, 1, 1)
	|					THEN TRUE
	|				ELSE Timekeeping.DateDay <= SummaryTableOfAccrualsAndDeductions.EndOfPeriod
	|			END)
	|		LEFT JOIN AccrualOutput AS AccrualOutput
	|		ON SummaryTableOfAccrualsAndDeductions.Organization = AccrualOutput.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Department = AccrualOutput.Department
	|			AND SummaryTableOfAccrualsAndDeductions.Employee = AccrualOutput.Employee
	|			AND SummaryTableOfAccrualsAndDeductions.Accrual = AccrualOutput.Accrual
	|
	|GROUP BY
	|	SummaryTableOfAccrualsAndDeductions.ItIsADeduction,
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Organization,
	|	SummaryTableOfAccrualsAndDeductions.CalculationFormula,
	|	SummaryTableOfAccrualsAndDeductions.Employee,
	|	SummaryTableOfAccrualsAndDeductions.Department,
	|	SummaryTableOfAccrualsAndDeductions.AccrualMethod,
	|	SummaryTableOfAccrualsAndDeductions.BasicEarnings,
	|	SummaryTableOfAccrualsAndDeductions.PayCode,
	|	SummaryTableOfAccrualsAndDeductions.Valid,
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency,
	|	SummaryTableOfAccrualsAndDeductions.Accrual,
	|	SummaryTableOfAccrualsAndDeductions.Employee.Individual,
	|	SummaryTableOfAccrualsAndDeductions.This_Is_Output,
	|	SummaryTableOfAccrualsAndDeductions.Value,
	|	SummaryTableOfAccrualsAndDeductions.EndOfPeriod,
	|	SummaryTableOfAccrualsAndDeductions.WorkScheduleCalendar,
	|	SummaryTableOfAccrualsAndDeductions.TimeKindForNorms
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.ValidityStartDate AS ValidityStartDate,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Organization AS Organization,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Department AS Department,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Employee AS Employee,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Accrual AS Accrual,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Valid AS Valid,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.BasicEarnings AS BasicEarnings,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.AccrualMethod AS AccrualMethod,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.CalculationFormula AS CalculationFormula,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.PayCode AS PayCode,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.InputFrequency AS InputFrequency,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.ItIsADeduction AS ItIsADeduction,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.DaysWorked AS DaysWorked,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.HoursWorked AS HoursWorked,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Individual AS Individual,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.PostingOption AS PostingOption,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.MandatoryAccrual AS MandatoryAccrual,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.Value AS Value,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.This_Is_Output AS This_Is_Output,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.EndOfPeriod AS EndOfPeriod,
	|	AccrualTableDistributedACCORDINGToDetailedReportCard.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	AccrualsBasicEarnings.Value AS AmountOfBasicEarnings,
	|	ISNULL(AccrualsBasicEarnings.StandardDays, 0) AS NormIsDaysForBasicEarnings,
	|	ISNULL(AccrualsBasicEarnings.StandardHours, 0) AS NormIsHoursForBasicEarnings,
	|	AccrualsBasicEarnings.AccrualOfBasicEarningsRequiresInWatersOfNorm AS AccrualOfBasicEarningsRequiresInWatersOfNorm,
	|	AccrualsBasicEarnings.TimeKindForNorms AS TimeKindForNorms
	|INTO AccrualTableDistributedByReportCard
	|FROM
	|	AccrualTableDistributedACCORDINGToDetailedReportCard AS AccrualTableDistributedACCORDINGToDetailedReportCard
	|		LEFT JOIN AccrualsBasicEarnings AS AccrualsBasicEarnings
	|		ON AccrualTableDistributedACCORDINGToDetailedReportCard.ValidityStartDate = AccrualsBasicEarnings.ValidityStartDate
	|			AND AccrualTableDistributedACCORDINGToDetailedReportCard.Organization = AccrualsBasicEarnings.Organization
	|			AND AccrualTableDistributedACCORDINGToDetailedReportCard.Department = AccrualsBasicEarnings.Department
	|			AND AccrualTableDistributedACCORDINGToDetailedReportCard.Employee = AccrualsBasicEarnings.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualTableDistributedByReportCard.ValidityStartDate AS ValidityStartDate,
	|	AccrualTableDistributedByReportCard.ItIsADeduction AS ItIsADeduction,
	|	AccrualTableDistributedByReportCard.Organization AS Organization,
	|	AccrualTableDistributedByReportCard.Department AS Department,
	|	AccrualTableDistributedByReportCard.Employee AS Employee,
	|	AccrualTableDistributedByReportCard.Accrual AS Accrual,
	|	CASE
	|		WHEN ISNULL(TableOfAmountsEnteredThisMonth.AmountAccruedInCurrentPeriod, 0) <> 0
	|			THEN TableOfAmountsEnteredThisMonth.AmountAccruedInCurrentPeriod
	|		WHEN ISNULL(AccrualOutput.Sum, 0) <> 0
	|			THEN AccrualOutput.Sum
	|		WHEN AccrualTableDistributedByReportCard.This_Is_Output
	|			THEN 0
	|		ELSE AccrualTableDistributedByReportCard.Value
	|	END AS Value,
	|	AccrualTableDistributedByReportCard.Valid AS Valid,
	|	AccrualTableDistributedByReportCard.BasicEarnings AS BasicEarnings,
	|	AccrualTableDistributedByReportCard.AccrualMethod AS AccrualMethod,
	|	AccrualTableDistributedByReportCard.CalculationFormula AS CalculationFormula,
	|	AccrualTableDistributedByReportCard.PayCode AS PayCode,
	|	AccrualTableDistributedByReportCard.InputFrequency AS InputFrequency,
	|	CASE
	|		WHEN ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.PayCode, 0) = 0
	|			THEN ISNULL(WorkingTimeStandardsForEveryoneByDefault.StandardDays, 0)
	|		ELSE WorkingTimeStandardsAccordingToWorkSchedule.StandardDays
	|	END AS NormalWorkdays,
	|	CASE
	|		WHEN ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.PayCode, 0) = 0
	|			THEN ISNULL(WorkingTimeStandardsForEveryoneByDefault.StandardHours, 0)
	|		ELSE WorkingTimeStandardsAccordingToWorkSchedule.StandardHours
	|	END AS NormOfHours,
	|	AccrualTableDistributedByReportCard.Employee.Individual AS Individual,
	|	VALUE(Enum.AccrualsDeductionsRecordOptions.RecogniseAsOtherExpenses) AS PostingOption,
	|	SUM(AccrualTableDistributedByReportCard.AmountOfBasicEarnings) AS AmountOfBasicEarnings,
	|	TRUE AS MandatoryAccrual,
	|	AccrualTableDistributedByReportCard.DaysWorked AS DaysWorked,
	|	AccrualTableDistributedByReportCard.HoursWorked AS HoursWorked,
	|	CASE
	|		WHEN AccrualTableDistributedByReportCard.EndOfPeriod = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(AccrualTableDistributedByReportCard.ValidityStartDate, MONTH)
	|		ELSE AccrualTableDistributedByReportCard.EndOfPeriod
	|	END AS PeriodEnding,
	|	AccrualTableDistributedByReportCard.NormIsDaysForBasicEarnings AS NormIsDaysForBasicEarnings,
	|	AccrualTableDistributedByReportCard.NormIsHoursForBasicEarnings AS NormIsHoursForBasicEarnings,
	|	AccrualTableDistributedByReportCard.AccrualOfBasicEarningsRequiresInWatersOfNorm AS AccrualOfBasicEarningsRequiresInWatersOfNorm
	|FROM
	|	AccrualTableDistributedByReportCard AS AccrualTableDistributedByReportCard
	|		LEFT JOIN WorkingTimeStandardsForEveryoneByDefault AS WorkingTimeStandardsForEveryoneByDefault
	|		ON AccrualTableDistributedByReportCard.TimeKindForNorms = WorkingTimeStandardsForEveryoneByDefault.PayCode
	|		LEFT JOIN TableOfAmountsEnteredThisMonth AS TableOfAmountsEnteredThisMonth
	|		ON AccrualTableDistributedByReportCard.Employee = TableOfAmountsEnteredThisMonth.Employee
	|			AND AccrualTableDistributedByReportCard.Accrual = TableOfAmountsEnteredThisMonth.Accrual
	|			AND AccrualTableDistributedByReportCard.Organization = TableOfAmountsEnteredThisMonth.Organization
	|			AND AccrualTableDistributedByReportCard.Department = TableOfAmountsEnteredThisMonth.Department
	|			AND AccrualTableDistributedByReportCard.ValidityStartDate = TableOfAmountsEnteredThisMonth.ValidityStartDate
	|		LEFT JOIN AccrualOutput AS AccrualOutput
	|		ON AccrualTableDistributedByReportCard.Organization = AccrualOutput.Organization
	|			AND AccrualTableDistributedByReportCard.Department = AccrualOutput.Department
	|			AND AccrualTableDistributedByReportCard.Employee = AccrualOutput.Employee
	|			AND AccrualTableDistributedByReportCard.Accrual = AccrualOutput.Accrual
	|		LEFT JOIN WorkingTimeStandardsAccordingToWorkSchedule AS WorkingTimeStandardsAccordingToWorkSchedule
	|		ON AccrualTableDistributedByReportCard.TimeKindForNorms = WorkingTimeStandardsAccordingToWorkSchedule.PayCode
	|			AND AccrualTableDistributedByReportCard.WorkScheduleCalendar = WorkingTimeStandardsAccordingToWorkSchedule.ScheduleOfWork
	|WHERE
	|	ISNULL(TableOfAmountsEnteredThisMonth.AmountAccruedInCurrentPeriod, 0) = 0
	|
	|GROUP BY
	|	AccrualTableDistributedByReportCard.ItIsADeduction,
	|	AccrualTableDistributedByReportCard.ValidityStartDate,
	|	AccrualTableDistributedByReportCard.Organization,
	|	AccrualTableDistributedByReportCard.CalculationFormula,
	|	AccrualTableDistributedByReportCard.Employee,
	|	AccrualTableDistributedByReportCard.Department,
	|	AccrualTableDistributedByReportCard.AccrualMethod,
	|	AccrualTableDistributedByReportCard.BasicEarnings,
	|	AccrualTableDistributedByReportCard.PayCode,
	|	AccrualTableDistributedByReportCard.Valid,
	|	AccrualTableDistributedByReportCard.InputFrequency,
	|	CASE
	|		WHEN ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.PayCode, 0) = 0
	|			THEN ISNULL(WorkingTimeStandardsForEveryoneByDefault.StandardDays, 0)
	|		ELSE WorkingTimeStandardsAccordingToWorkSchedule.StandardDays
	|	END,
	|	CASE
	|		WHEN ISNULL(WorkingTimeStandardsAccordingToWorkSchedule.PayCode, 0) = 0
	|			THEN ISNULL(WorkingTimeStandardsForEveryoneByDefault.StandardHours, 0)
	|		ELSE WorkingTimeStandardsAccordingToWorkSchedule.StandardHours
	|	END,
	|	AccrualTableDistributedByReportCard.Accrual,
	|	AccrualTableDistributedByReportCard.Individual,
	|	CASE
	|		WHEN ISNULL(TableOfAmountsEnteredThisMonth.AmountAccruedInCurrentPeriod, 0) <> 0
	|			THEN TableOfAmountsEnteredThisMonth.AmountAccruedInCurrentPeriod
	|		WHEN ISNULL(AccrualOutput.Sum, 0) <> 0
	|			THEN AccrualOutput.Sum
	|		WHEN AccrualTableDistributedByReportCard.This_Is_Output
	|			THEN 0
	|		ELSE AccrualTableDistributedByReportCard.Value
	|	END,
	|	AccrualTableDistributedByReportCard.Employee.Individual,
	|	AccrualTableDistributedByReportCard.DaysWorked,
	|	AccrualTableDistributedByReportCard.HoursWorked,
	|	CASE
	|		WHEN AccrualTableDistributedByReportCard.EndOfPeriod = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(AccrualTableDistributedByReportCard.ValidityStartDate, MONTH)
	|		ELSE AccrualTableDistributedByReportCard.EndOfPeriod
	|	END,
	|	AccrualTableDistributedByReportCard.NormIsDaysForBasicEarnings,
	|	AccrualTableDistributedByReportCard.NormIsHoursForBasicEarnings,
	|	AccrualTableDistributedByReportCard.AccrualOfBasicEarningsRequiresInWatersOfNorm
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR AS CalculationStatusHR
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &SettlementStartDate
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ArrayOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization";
	
	RequestResultsPackage	= Query.ExecuteBatch();
	
	StructureOfPreparedData = New Structure();
	StructureOfPreparedData.Insert("StatusTable",  RequestResultsPackage[17].Unload());
	StructureOfPreparedData.Insert("AccrualTable",RequestResultsPackage[16].Unload());
	
	Return StructureOfPreparedData;
EndFunction	

Function CalculateDeductions(CalculationParameters, QueryExecutionResult)
	
	Organization = CalculationParameters.Organization;
	CalculationPeriod = CalculationParameters.CalculationPeriod;
	CalculationStatusTable = CalculationParameters.CalculationStatuses;
	ArrayOfEmployees = CalculationStatusTable.UnloadColumn("Employee");
	
	Query = New Query();   
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("SettlementStartDate", CalculationPeriod);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);
	
	Query.Text = 
	"SELECT
	|	EmploymentRecordSliceLast.Period AS Period,
	|	EmploymentRecordSliceLast.Organization AS Organization,
	|	EmploymentRecordSliceLast.Department AS Department,
	|	EmploymentRecordSliceLast.Employee AS Employee
	|INTO PersonnelHistoryIsDetailed
	|FROM
	|	InformationRegister.EmploymentRecord.SliceLast(&SettlementStartDate, Employee IN (&ArrayOfEmployees)) AS EmploymentRecordSliceLast
	|WHERE
	|	EmploymentRecordSliceLast.WorksInBusinessUnit = TRUE
	|
	|UNION ALL
	|
	|SELECT
	|	EmploymentRecord.Period,
	|	EmploymentRecord.Organization,
	|	EmploymentRecord.Department,
	|	EmploymentRecord.Employee
	|FROM
	|	InformationRegister.EmploymentRecord AS EmploymentRecord
	|WHERE
	|	EmploymentRecord.WorksInBusinessUnit = TRUE
	|	AND EmploymentRecord.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PersonnelHistoryIsDetailed.Period AS Period,
	|	PersonnelHistoryIsDetailed.Organization AS Organization,
	|	PersonnelHistoryIsDetailed.Department AS Department,
	|	PersonnelHistoryIsDetailed.Employee AS Employee
	|INTO PersonnelHistorySelected
	|FROM
	|	PersonnelHistoryIsDetailed AS PersonnelHistoryIsDetailed
	|
	|GROUP BY
	|	PersonnelHistoryIsDetailed.Employee,
	|	PersonnelHistoryIsDetailed.Organization,
	|	PersonnelHistoryIsDetailed.Period,
	|	PersonnelHistoryIsDetailed.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&SettlementStartDate AS ValidityStartDate,
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization AS Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department AS Department,
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee,
	|	RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction AS Retention,
	|	RegularAccrualsAndDeductionsHRSliceLast.Value AS Value
	|INTO DetailedTableOfAccrualsOfDeductions
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(
	|			&SettlementStartDate,
	|			Employee IN (&ArrayOfEmployees)
	|				AND Valid = TRUE) AS RegularAccrualsAndDeductionsHRSliceLast
	|
	|UNION ALL
	|
	|SELECT
	|	&SettlementStartDate,
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee,
	|	RegularAccrualsAndDeductionsHR.AccrualDeduction,
	|	RegularAccrualsAndDeductionsHR.Value
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND RegularAccrualsAndDeductionsHR.Employee IN(&ArrayOfEmployees)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DetailedTableOfAccrualsOfDeductions.ValidityStartDate AS ValidityStartDate,
	|	DetailedTableOfAccrualsOfDeductions.Organization AS Organization,
	|	DetailedTableOfAccrualsOfDeductions.Department AS Department,
	|	DetailedTableOfAccrualsOfDeductions.Employee AS Employee,
	|	DetailedTableOfAccrualsOfDeductions.Value AS Sum,
	|	DetailedTableOfAccrualsOfDeductions.Retention AS Retention,
	|	AccrualAndDeductionKinds.InputFrequency AS InputFrequency
	|INTO SummaryTableOfAccrualsAndDeductions
	|FROM
	|	DetailedTableOfAccrualsOfDeductions AS DetailedTableOfAccrualsOfDeductions
	|		LEFT JOIN Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|		ON DetailedTableOfAccrualsOfDeductions.Retention = AccrualAndDeductionKinds.Ref
	|WHERE
	|	AccrualAndDeductionKinds.ItIsADeduction
	|
	|GROUP BY
	|	DetailedTableOfAccrualsOfDeductions.Department,
	|	DetailedTableOfAccrualsOfDeductions.Employee,
	|	DetailedTableOfAccrualsOfDeductions.ValidityStartDate,
	|	DetailedTableOfAccrualsOfDeductions.Organization,
	|	DetailedTableOfAccrualsOfDeductions.Value,
	|	AccrualAndDeductionKinds.ItIsADeduction,
	|	DetailedTableOfAccrualsOfDeductions.Retention,
	|	AccrualAndDeductionKinds.InputFrequency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee,
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate AS ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Retention AS Retention,
	|	SUM(ISNULL(DeductionsHRTurnovers.SumTurnover, 0)) AS AmountWithheldInCurrentPeriod,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department
	|INTO TableOfAmountsEnteredThisMonth
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN AccumulationRegister.DeductionsHR.Turnovers(
	|				&SettlementStartDate,
	|				ENDOFPERIOD(&SettlementStartDate, MONTH),
	|				Recorder,
	|				Organization = &Organization
	|					AND Employee IN (&ArrayOfEmployees)) AS DeductionsHRTurnovers
	|		ON SummaryTableOfAccrualsAndDeductions.Organization = DeductionsHRTurnovers.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Department = DeductionsHRTurnovers.Department
	|			AND SummaryTableOfAccrualsAndDeductions.Employee = DeductionsHRTurnovers.Employee
	|			AND SummaryTableOfAccrualsAndDeductions.Retention = DeductionsHRTurnovers.Retention
	|WHERE
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency = 2
	|	AND DeductionsHRTurnovers.Recorder REFS Document.OneTimeDeductions
	|
	|GROUP BY
	|	SummaryTableOfAccrualsAndDeductions.Organization,
	|	SummaryTableOfAccrualsAndDeductions.Employee,
	|	SummaryTableOfAccrualsAndDeductions.Retention,
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate AS Period,
	|	SummaryTableOfAccrualsAndDeductions.Organization AS Organization,
	|	SummaryTableOfAccrualsAndDeductions.Department AS Department,
	|	SummaryTableOfAccrualsAndDeductions.Employee AS Employee,
	|	SummaryTableOfAccrualsAndDeductions.Retention AS Retention,
	|	SUM(CASE
	|			WHEN ISNULL(TableOfAmountsEnteredThisMonth.AmountWithheldInCurrentPeriod, 0) <> 0
	|				THEN TableOfAmountsEnteredThisMonth.AmountWithheldInCurrentPeriod  
	|			WHEN SummaryTableOfAccrualsAndDeductions.InputFrequency = 2 
	|				THEN 0
	|			ELSE SummaryTableOfAccrualsAndDeductions.Sum
	|		END) AS Sum,
	|	SummaryTableOfAccrualsAndDeductions.Employee.Individual AS Individual,
	|	TRUE AS MandatoryRetention,
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency AS InputFrequency,
	|	ENDOFPERIOD(SummaryTableOfAccrualsAndDeductions.ValidityStartDate, MONTH) AS PeriodEnding
	|FROM
	|	SummaryTableOfAccrualsAndDeductions AS SummaryTableOfAccrualsAndDeductions
	|		LEFT JOIN TableOfAmountsEnteredThisMonth AS TableOfAmountsEnteredThisMonth
	|		ON SummaryTableOfAccrualsAndDeductions.ValidityStartDate = TableOfAmountsEnteredThisMonth.ValidityStartDate
	|			AND SummaryTableOfAccrualsAndDeductions.Organization = TableOfAmountsEnteredThisMonth.Organization
	|			AND SummaryTableOfAccrualsAndDeductions.Department = TableOfAmountsEnteredThisMonth.Department
	|			AND SummaryTableOfAccrualsAndDeductions.Retention = TableOfAmountsEnteredThisMonth.Retention
	|WHERE
	|	ISNULL(TableOfAmountsEnteredThisMonth.AmountWithheldInCurrentPeriod, 0) = 0
	|
	|GROUP BY
	|	SummaryTableOfAccrualsAndDeductions.ValidityStartDate,
	|	SummaryTableOfAccrualsAndDeductions.Organization,
	|	SummaryTableOfAccrualsAndDeductions.Employee,
	|	SummaryTableOfAccrualsAndDeductions.Retention,
	|	SummaryTableOfAccrualsAndDeductions.Department,
	|	SummaryTableOfAccrualsAndDeductions.Employee.Individual,
	|	SummaryTableOfAccrualsAndDeductions.InputFrequency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR AS CalculationStatusHR
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &SettlementStartDate
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ArrayOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization";
	
	RequestResultsPackage	= Query.ExecuteBatch();
	
	StructureOfPreparedData = New Structure();
	StructureOfPreparedData.Insert("StatusTable",  RequestResultsPackage[6].Unload());
	StructureOfPreparedData.Insert("RetentionTable",RequestResultsPackage[5].Unload());
	
	Return StructureOfPreparedData; 
	
EndFunction	

Function CalculateTaxes(CalculationParameters, QueryExecutionResult)
	
	Organization = CalculationParameters.Organization;
	CalculationPeriod = CalculationParameters.CalculationPeriod;
	CalculationStatusTable = CalculationParameters.CalculationStatuses;
	ArrayOfEmployees = CalculationStatusTable.UnloadColumn("Employee");
	
	Query = New Query();   
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("SettlementStartDate", CalculationPeriod);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);
	
	Query.Text = 
	"SELECT
	|	TaxSettingsNonTaxableAccruals.TaxKind AS TaxKind,
	|	TaxSettingsNonTaxableAccruals.Accrual AS Accrual
	|INTO NonTaxableAccruals
	|FROM
	|	InformationRegister.NonTaxableAccrualsHR.SliceLast(&SettlementStartDate, Organization = &Organization) AS NonTaxableAccrualsHRSliceLast
	|		LEFT JOIN Document.TaxSettings.NonTaxableAccruals AS TaxSettingsNonTaxableAccruals
	|		ON NonTaxableAccrualsHRSliceLast.Recorder = TaxSettingsNonTaxableAccruals.Ref
	|
	|INDEX BY
	|	TaxKind,
	|	Accrual
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ApplyDeductionsEmployeeDeductions.TaxKind AS TaxKind,
	|	ApplyDeductionsEmployeeDeductions.DeductionKindHR AS DeductionKindHR,
	|	ApplyDeductionsEmployeeDeductions.DeductionEndMonth AS DeductionEndMonth,
	|	ApplyDeductions.Employee AS Employee,
	|	ApplyDeductions.Organization AS Organization,
	|	ApplyDeductions.RegistrationMonth AS RegistrationMonth
	|INTO DeductionsApplied
	|FROM
	|	Document.ApplyDeductions AS ApplyDeductions
	|		LEFT JOIN Document.ApplyDeductions.EmployeeDeductions AS ApplyDeductionsEmployeeDeductions
	|		ON ApplyDeductions.Ref = ApplyDeductionsEmployeeDeductions.Ref
	|WHERE
	|	ApplyDeductions.Organization = &Organization
	|	AND ApplyDeductions.Posted
	|	AND ApplyDeductions.RegistrationMonth <= &SettlementStartDate
	|
	|INDEX BY
	|	TaxKind,
	|	DeductionKindHR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxSettingsStandardDeductions.TaxKind AS TaxKind,
	|	TaxSettingsStandardDeductions.DeductionKindHR AS DeductionKindHR,
	|	TaxSettingsStandardDeductions.DeductionAmount AS DeductionAmount
	|INTO StandardDeductions
	|FROM
	|	InformationRegister.Deductions_HR.SliceLast(&SettlementStartDate, Organization = &Organization) AS Deductions_HRSliceLast
	|		LEFT JOIN Document.TaxSettings.StandardDeductions AS TaxSettingsStandardDeductions
	|		ON Deductions_HRSliceLast.DocumentRecorder = TaxSettingsStandardDeductions.Ref
	|
	|INDEX BY
	|	TaxKind,
	|	DeductionKindHR
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxSettingsTaxRates.TaxKind AS TaxKind,
	|	TaxSettingsTaxRates.Tariff AS Tariff,
	|	TaxContributionKinds.DeductedFromEmployeeWages AS DeductedFromEmployeeWages
	|INTO TaxRatesAreAutomatic
	|FROM
	|	InformationRegister.TaxRatesHR.SliceLast(&SettlementStartDate, Organization = &Organization) AS TaxRatesHRSliceLast
	|		LEFT JOIN Document.TaxSettings.TaxRates AS TaxSettingsTaxRates
	|			LEFT JOIN Catalog.TaxContributionKinds AS TaxContributionKinds
	|			ON TaxSettingsTaxRates.TaxKind = TaxContributionKinds.Ref
	|		ON TaxRatesHRSliceLast.DocumentRecorder = TaxSettingsTaxRates.Ref
	|WHERE
	|	TaxSettingsTaxRates.AccrueAutomatically
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxSettingsTaxRates.TaxKind AS TaxKind,
	|	TaxSettingsTaxRates.Tariff AS Tariff,
	|	TaxContributionKinds.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	TaxRatesHRSliceLast.Organization AS Organization
	|INTO TaxRatesAreManual
	|FROM
	|	InformationRegister.TaxRatesHR.SliceLast(&SettlementStartDate, Organization = &Organization) AS TaxRatesHRSliceLast
	|		LEFT JOIN Document.TaxSettings.TaxRates AS TaxSettingsTaxRates
	|			LEFT JOIN Catalog.TaxContributionKinds AS TaxContributionKinds
	|			ON TaxSettingsTaxRates.TaxKind = TaxContributionKinds.Ref
	|		ON TaxRatesHRSliceLast.DocumentRecorder = TaxSettingsTaxRates.Ref
	|WHERE
	|	NOT TaxSettingsTaxRates.AccrueAutomatically
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualsHR.Organization AS Organization,
	|	AccrualsHR.Individual AS Individual,
	|	AccrualsHR.Employee AS Employee,
	|	AccrualsHR.Accrual AS Accrual,
	|	AccrualsHR.Recorder AS AccrualRegistrar,
	|	AccrualsHR.Department AS Department,
	|	SUM(AccrualsHR.Sum) AS Sum
	|INTO Accruals
	|FROM
	|	AccumulationRegister.AccrualsHR AS AccrualsHR
	|WHERE
	|	AccrualsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND AccrualsHR.Organization = &Organization
	|	AND AccrualsHR.Employee IN(&ArrayOfEmployees)
	|
	|GROUP BY
	|	AccrualsHR.Employee,
	|	AccrualsHR.Individual,
	|	AccrualsHR.Organization,
	|	AccrualsHR.Department,
	|	AccrualsHR.Accrual,
	|	AccrualsHR.Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxRatesAreAutomatic.TaxKind AS TaxKind,
	|	TaxRatesAreAutomatic.Tariff AS Rate_OfTax,
	|	Accruals.Organization AS Organization,
	|	Accruals.Individual AS Individual,
	|	Accruals.Employee AS Employee,
	|	Accruals.Accrual AS Accrual,
	|	Accruals.AccrualRegistrar AS AccrualRegistrar,
	|	Accruals.Department AS Department,
	|	Accruals.Sum AS AccrualAmount,
	|	TaxRatesAreAutomatic.DeductedFromEmployeeWages AS DeductedFromEmployeeWages
	|INTO AllTaxesOnAllAccruals
	|FROM
	|	TaxRatesAreAutomatic AS TaxRatesAreAutomatic,
	|	Accruals AS Accruals
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxRatesAreManual.TaxKind AS TaxKind,
	|	TaxRatesAreManual.Tariff AS Rate_OfTax,
	|	TaxRatesAreManual.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	ISNULL(TaxesContributionsHRTurnovers.Organization, EmploymentRecordSliceLast.Organization) AS Organization,
	|	ISNULL(TaxesContributionsHRTurnovers.Individual, EmploymentRecordSliceLast.Employee.Individual) AS Individual,
	|	ISNULL(TaxesContributionsHRTurnovers.Department, EmploymentRecordSliceLast.Department) AS Department,
	|	ISNULL(TaxesContributionsHRTurnovers.SumTurnover, 0) AS AmountOfTax
	|INTO AllManualTaxes
	|FROM
	|	TaxRatesAreManual AS TaxRatesAreManual
	|		LEFT JOIN AccumulationRegister.TaxesContributionsHR.Turnovers(
	|				&SettlementStartDate,
	|				ENDOFPERIOD(&SettlementStartDate, MONTH),
	|				Month,
	|				Organization = &Organization
	|					AND Individual IN
	|						(SELECT
	|							EmployeesHR.Individual AS Individual
	|						FROM
	|							Catalog.EmployeesHR AS EmployeesHR
	|						WHERE
	|							EmployeesHR.Ref IN (&ArrayOfEmployees))) AS TaxesContributionsHRTurnovers
	|		ON TaxRatesAreManual.TaxKind = TaxesContributionsHRTurnovers.TaxKind
	|		LEFT JOIN InformationRegister.EmploymentRecord.SliceLast(&SettlementStartDate, Employee IN (&ArrayOfEmployees)) AS EmploymentRecordSliceLast
	|		ON TaxRatesAreManual.Organization = EmploymentRecordSliceLast.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeductionsApplied.Organization AS Organization,
	|	DeductionsApplied.Employee AS Employee,
	|	DeductionsApplied.TaxKind AS TaxKind,
	|	SUM(CASE
	|			WHEN ISNULL(StandardDeductions.DeductionAmount, 0) = 0
	|				THEN 0
	|			ELSE StandardDeductions.DeductionAmount
	|		END) AS DeductionAmount
	|INTO Deductions_
	|FROM
	|	DeductionsApplied AS DeductionsApplied
	|		LEFT JOIN StandardDeductions AS StandardDeductions
	|		ON DeductionsApplied.TaxKind = StandardDeductions.TaxKind
	|			AND DeductionsApplied.DeductionKindHR = StandardDeductions.DeductionKindHR
	|
	|GROUP BY
	|	DeductionsApplied.TaxKind,
	|	DeductionsApplied.Organization,
	|	DeductionsApplied.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllTaxesOnAllAccruals.TaxKind AS TaxKind,
	|	AllTaxesOnAllAccruals.Rate_OfTax AS Rate_OfTax,
	|	AllTaxesOnAllAccruals.Organization AS Organization,
	|	AllTaxesOnAllAccruals.Individual AS Individual,
	|	AllTaxesOnAllAccruals.Employee AS Employee,
	|	AllTaxesOnAllAccruals.Accrual AS Accrual,
	|	AllTaxesOnAllAccruals.AccrualRegistrar AS AccrualRegistrar,
	|	AllTaxesOnAllAccruals.Department AS Department,
	|	AllTaxesOnAllAccruals.AccrualAmount AS AccrualAmount,
	|	CASE
	|		WHEN ISNULL(NonTaxableAccruals.Accrual, 0) = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS ThisIsNonTaxableAccrualOfThisTax,
	|	AllTaxesOnAllAccruals.DeductedFromEmployeeWages AS DeductedFromEmployeeWages
	|INTO TableOfAccrualsOfTaxesWithDeductions
	|FROM
	|	AllTaxesOnAllAccruals AS AllTaxesOnAllAccruals
	|		LEFT JOIN NonTaxableAccruals AS NonTaxableAccruals
	|		ON AllTaxesOnAllAccruals.TaxKind = NonTaxableAccruals.TaxKind
	|			AND AllTaxesOnAllAccruals.Accrual = NonTaxableAccruals.Accrual
	|
	|GROUP BY
	|	AllTaxesOnAllAccruals.TaxKind,
	|	AllTaxesOnAllAccruals.Accrual,
	|	AllTaxesOnAllAccruals.AccrualRegistrar,
	|	AllTaxesOnAllAccruals.Employee,
	|	AllTaxesOnAllAccruals.Organization,
	|	AllTaxesOnAllAccruals.Department,
	|	AllTaxesOnAllAccruals.Individual,
	|	CASE
	|		WHEN ISNULL(NonTaxableAccruals.Accrual, 0) = 0
	|			THEN FALSE
	|		ELSE TRUE
	|	END,
	|	AllTaxesOnAllAccruals.Rate_OfTax,
	|	AllTaxesOnAllAccruals.AccrualAmount,
	|	AllTaxesOnAllAccruals.DeductedFromEmployeeWages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAccrualsOfTaxesWithDeductions.TaxKind AS TaxKind,
	|	TableOfAccrualsOfTaxesWithDeductions.Rate_OfTax AS Rate_OfTax,
	|	TableOfAccrualsOfTaxesWithDeductions.Organization AS Organization,
	|	TableOfAccrualsOfTaxesWithDeductions.Individual AS Individual,
	|	TableOfAccrualsOfTaxesWithDeductions.Employee AS Employee,
	|	TableOfAccrualsOfTaxesWithDeductions.Accrual AS Accrual,
	|	TableOfAccrualsOfTaxesWithDeductions.AccrualRegistrar AS AccrualRegistrar,
	|	TableOfAccrualsOfTaxesWithDeductions.Department AS Department,
	|	CASE
	|		WHEN TableOfAccrualsOfTaxesWithDeductions.ThisIsNonTaxableAccrualOfThisTax
	|			THEN 0
	|		ELSE TableOfAccrualsOfTaxesWithDeductions.AccrualAmount
	|	END AS AccrualAmount,
	|	TableOfAccrualsOfTaxesWithDeductions.ThisIsNonTaxableAccrualOfThisTax AS ThisIsNonTaxableAccrualOfThisTax,
	|	TableOfAccrualsOfTaxesWithDeductions.DeductedFromEmployeeWages AS DeductedFromEmployeeWages
	|INTO TableOfAccruedTaxesByAccruals
	|FROM
	|	TableOfAccrualsOfTaxesWithDeductions AS TableOfAccrualsOfTaxesWithDeductions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAccrualsOfTaxesWithDeductions.TaxKind AS TaxKind,
	|	TableOfAccrualsOfTaxesWithDeductions.Rate_OfTax AS Rate_OfTax,
	|	TableOfAccrualsOfTaxesWithDeductions.Organization AS Organization,
	|	TableOfAccrualsOfTaxesWithDeductions.Individual AS Individual,
	|	TableOfAccrualsOfTaxesWithDeductions.Employee AS Employee,
	|	TableOfAccrualsOfTaxesWithDeductions.Accrual AS Accrual,
	|	TableOfAccrualsOfTaxesWithDeductions.AccrualRegistrar AS AccrualRegistrar,
	|	TableOfAccrualsOfTaxesWithDeductions.Department AS Department,
	|	SUM(TableOfAccrualsOfTaxesWithDeductions.AccrualAmount) AS AccrualAmount,
	|	TableOfAccrualsOfTaxesWithDeductions.ThisIsNonTaxableAccrualOfThisTax AS ThisIsNonTaxableAccrualOfThisTax,
	|	TableOfAccrualsOfTaxesWithDeductions.DeductedFromEmployeeWages AS DeductedFromEmployeeWages
	|INTO TableOfNonTaxableAccrualsByTaxType
	|FROM
	|	TableOfAccrualsOfTaxesWithDeductions AS TableOfAccrualsOfTaxesWithDeductions
	|WHERE
	|	TableOfAccrualsOfTaxesWithDeductions.ThisIsNonTaxableAccrualOfThisTax
	|
	|GROUP BY
	|	TableOfAccrualsOfTaxesWithDeductions.Employee,
	|	TableOfAccrualsOfTaxesWithDeductions.ThisIsNonTaxableAccrualOfThisTax,
	|	TableOfAccrualsOfTaxesWithDeductions.DeductedFromEmployeeWages,
	|	TableOfAccrualsOfTaxesWithDeductions.Department,
	|	TableOfAccrualsOfTaxesWithDeductions.Accrual,
	|	TableOfAccrualsOfTaxesWithDeductions.AccrualRegistrar,
	|	TableOfAccrualsOfTaxesWithDeductions.Individual,
	|	TableOfAccrualsOfTaxesWithDeductions.TaxKind,
	|	TableOfAccrualsOfTaxesWithDeductions.Organization,
	|	TableOfAccrualsOfTaxesWithDeductions.Rate_OfTax
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAccruedTaxesByAccruals.Organization AS Organization,
	|	TableOfAccruedTaxesByAccruals.TaxKind AS TaxKind,
	|	TableOfAccruedTaxesByAccruals.Individual AS Individual,
	|	TableOfAccruedTaxesByAccruals.Employee AS Employee,
	|	TableOfAccruedTaxesByAccruals.Department AS Department,
	|	SUM(TableOfAccruedTaxesByAccruals.AccrualAmount) AS Base,
	|	&SettlementStartDate AS Period,
	|	TableOfAccruedTaxesByAccruals.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	TableOfAccruedTaxesByAccruals.Rate_OfTax AS Rate_OfTax,
	|	TableOfAccruedTaxesByAccruals.Accrual AS Accrual,
	|	TableOfAccruedTaxesByAccruals.AccrualRegistrar AS AccrualRegistrar,
	|	TableOfAccruedTaxesByAccruals.ThisIsNonTaxableAccrualOfThisTax AS ThisIsNonTaxableAccrualOfThisTax
	|INTO TableOfAccrualAmountsByTaxType
	|FROM
	|	TableOfAccruedTaxesByAccruals AS TableOfAccruedTaxesByAccruals
	|
	|GROUP BY
	|	TableOfAccruedTaxesByAccruals.Organization,
	|	TableOfAccruedTaxesByAccruals.TaxKind,
	|	TableOfAccruedTaxesByAccruals.Employee,
	|	TableOfAccruedTaxesByAccruals.DeductedFromEmployeeWages,
	|	TableOfAccruedTaxesByAccruals.Individual,
	|	TableOfAccruedTaxesByAccruals.Department,
	|	TableOfAccruedTaxesByAccruals.Rate_OfTax,
	|	TableOfAccruedTaxesByAccruals.Accrual,
	|	TableOfAccruedTaxesByAccruals.AccrualRegistrar,
	|	TableOfAccruedTaxesByAccruals.ThisIsNonTaxableAccrualOfThisTax
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR AS CalculationStatusHR
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &SettlementStartDate
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ArrayOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAccrualAmountsByTaxType.Organization AS Organization,
	|	TableOfAccrualAmountsByTaxType.TaxKind AS TaxKind,
	|	TableOfAccrualAmountsByTaxType.Individual AS Individual,
	|	TableOfAccrualAmountsByTaxType.Employee AS Employee,
	|	TableOfAccrualAmountsByTaxType.Department AS Department,
	|	TableOfAccrualAmountsByTaxType.Base * TableOfAccrualAmountsByTaxType.Rate_OfTax / 100 AS Sum,
	|	TableOfAccrualAmountsByTaxType.Base AS Base,
	|	TableOfAccrualAmountsByTaxType.Period AS Period,
	|	TableOfAccrualAmountsByTaxType.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	TableOfAccrualAmountsByTaxType.Rate_OfTax AS Rate_OfTax,
	|	0 AS Deduction,
	|	FALSE AS EnteringTaxManually,
	|	TableOfNonTaxableAccrualsByTaxType.AccrualAmount AS NonTaxableAmount,
	|	TableOfAccrualAmountsByTaxType.Accrual AS Accrual,
	|	TableOfAccrualAmountsByTaxType.AccrualRegistrar AS AccrualRegistrar,
	|	TableOfAccrualAmountsByTaxType.ThisIsNonTaxableAccrualOfThisTax AS ThisIsNonTaxableAccrualOfThisTax
	|FROM
	|	TableOfAccrualAmountsByTaxType AS TableOfAccrualAmountsByTaxType
	|		LEFT JOIN TableOfNonTaxableAccrualsByTaxType AS TableOfNonTaxableAccrualsByTaxType
	|		ON TableOfAccrualAmountsByTaxType.Organization = TableOfNonTaxableAccrualsByTaxType.Organization
	|			AND TableOfAccrualAmountsByTaxType.TaxKind = TableOfNonTaxableAccrualsByTaxType.TaxKind
	|			AND TableOfAccrualAmountsByTaxType.Employee = TableOfNonTaxableAccrualsByTaxType.Employee
	|			AND TableOfAccrualAmountsByTaxType.Accrual = TableOfNonTaxableAccrualsByTaxType.Accrual
	|			AND TableOfAccrualAmountsByTaxType.AccrualRegistrar = TableOfNonTaxableAccrualsByTaxType.AccrualRegistrar
	|
	|UNION ALL
	|
	|SELECT
	|	AllManualTaxes.Organization,
	|	AllManualTaxes.TaxKind,
	|	AllManualTaxes.Individual,
	|	NULL,
	|	AllManualTaxes.Department,
	|	AllManualTaxes.AmountOfTax,
	|	0,
	|	&SettlementStartDate,
	|	AllManualTaxes.DeductedFromEmployeeWages,
	|	AllManualTaxes.Rate_OfTax,
	|	0,
	|	TRUE,
	|	NULL,
	|	NULL,
	|	AllManualTaxes.TaxKind,
	|	FALSE
	|FROM
	|	AllManualTaxes AS AllManualTaxes
	|WHERE
	|	AllManualTaxes.AmountOfTax = 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Deductions_.Organization AS Organization,
	|	Deductions_.Employee AS Employee,
	|	Deductions_.TaxKind AS TaxKind,
	|	Deductions_.DeductionAmount AS DeductionAmount
	|FROM
	|	Deductions_ AS Deductions_";
	
	RequestResultsPackage	= Query.ExecuteBatch();
	
	TaxTable = RequestResultsPackage[14].Unload();
	DeductionTable = RequestResultsPackage[15].Unload();
	
	TheStructureOfTheSearch = New Structure();
	TheStructureOfTheSearch.Insert("Organization", Catalogs.Companies.EmptyRef()); 
	TheStructureOfTheSearch.Insert("Employee", Catalogs.EmployeesHR.EmptyRef()); 
	TheStructureOfTheSearch.Insert("TaxKind", Catalogs.TaxContributionKinds.EmptyRef()); 
	TheStructureOfTheSearch.Insert("EnteringTaxManually", False); 
	TheStructureOfTheSearch.Insert("ThisIsNonTaxableAccrualOfThisTax", False); 
	
	For Each DeductionTableRow In DeductionTable Do
		
		DeductionAmount = DeductionTableRow.DeductionAmount;
		FillPropertyValues(TheStructureOfTheSearch, DeductionTableRow);
		
		FoundRows = TaxTable.FindRows(TheStructureOfTheSearch);
		
		For Each CurrentRowOfFoundRows In FoundRows Do  
			If CurrentRowOfFoundRows.Base = 0 Then
				Continue;
			EndIf;	
			
			WriteOFFDeductionAmount = Min(CurrentRowOfFoundRows.Base, DeductionAmount);	
			CurrentRowOfFoundRows.Deduction = WriteOFFDeductionAmount;
			CurrentRowOfFoundRows.Base = CurrentRowOfFoundRows.Base - CurrentRowOfFoundRows.Deduction;
			CurrentRowOfFoundRows.Sum = CurrentRowOfFoundRows.Base * CurrentRowOfFoundRows.Rate_OfTax/100;
			DeductionAmount = DeductionAmount -	WriteOFFDeductionAmount; 
			
			CurrentRowOfFoundRows.ThisIsNonTaxableAccrualOfThisTax = CurrentRowOfFoundRows.Base = 0;
			
			If DeductionAmount = 0 Then
				Break;
			EndIf;	
			
		EndDo;
		
	EndDo;
	
	StructureOfPreparedData = New Structure();
	StructureOfPreparedData.Insert("StatusTable",  RequestResultsPackage[13].Unload());
	StructureOfPreparedData.Insert("TaxTable",   TaxTable);
	
	Return StructureOfPreparedData; 
	
EndFunction	

Function CalculateAmountToBePaid(CalculationParameters, QueryExecutionResult)

	Organization = CalculationParameters.Organization;
	CalculationPeriod = CalculationParameters.CalculationPeriod;
	CalculationStatusTable = CalculationParameters.CalculationStatuses;
	ArrayOfEmployees = CalculationStatusTable.UnloadColumn("Employee");
	
	Query = New Query();   
	
	Query.SetParameter("SettlementStartDate", CalculationPeriod);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);

	QueryText = InformationRegisters.SettingOfPostingInAccountingHR.GetTextOfSettingsForFillingInReflectionInAccounting();

	QueryText = QueryText + 
	";
	|
	|////////////////////////////////////////////////////////////////////////////////
    |";

	Query.Text = QueryText + 
	"SELECT
	|	RulesForFillingInReflectionInAccounting.TypeOfAccrualDeduction AS TypeOfAccrualDeduction,
	|	RulesForFillingInReflectionInAccounting.Department AS Department,
	|	RulesForFillingInReflectionInAccounting.Employee AS Employee,
	|	RulesForFillingInReflectionInAccounting.DocumentCalculation AS DocumentCalculation,
	|	RulesForFillingInReflectionInAccounting.PostingOption AS PostingOption,
	|	RulesForFillingInReflectionInAccounting.AllocationBaseType AS AllocationBaseType,
	|	RulesForFillingInReflectionInAccounting.ProductCostElement AS ProductCostElement,
	|	RulesForFillingInReflectionInAccounting.LineOfBusiness AS LineOfBusiness,
	|	RulesForFillingInReflectionInAccounting.ExpenseItem AS ExpenseItem,
	|	RulesForFillingInReflectionInAccounting.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccounting.IncomeItem AS IncomeItem,
	|	RulesForFillingInReflectionInAccounting.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccounting.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	RulesForFillingInReflectionInAccounting.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	RulesForFillingInReflectionInAccounting.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccounting.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccounting.Counterparty AS Counterparty,
	|	RulesForFillingInReflectionInAccounting.IssuancePurpose AS IssuancePurpose,
	|	RulesForFillingInReflectionInAccounting.DimensionOfExpenses AS DimensionOfExpenses,
	|	RulesForFillingInReflectionInAccounting.DimensionOfRevenue AS DimensionOfRevenue,
	|	RulesForFillingInReflectionInAccounting.ARAPObject AS ARAPObject
	|INTO RulesForFillingInReflectionInAccountingCollected
	|FROM
	|	RulesForFillingInReflectionInAccounting AS RulesForFillingInReflectionInAccounting
	|
	|INDEX BY
	|	TypeOfAccrualDeduction,
	|	Department,
	|	Employee,
	|	DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed
	|		AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed
	|		AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AllAutoCalculationsAreCompleted
	|INTO PayrollStatusesForEmployees
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &SettlementStartDate
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ArrayOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
	|
	|INDEX BY
	|	Organization,
	|	Employee,
	|	Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualsHR.Organization AS Organization,
	|	AccrualsHR.Employee AS Employee,
	|	AccrualsHR.Accrual AS AccrualKind,
	|	AccrualsHR.Department AS Department,
	|	AccrualsHR.Sum AS Sum,
	|	AccrualsHR.Individual AS Individual,
	|	AccrualsHR.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|		ELSE VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|	END AS TypesOfAccrualsOfDeductionsToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DivisionToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Employee
	|		ELSE VALUE(Catalog.EmployeesHR.EmptyRef)
	|	END AS EmployeeToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation
	|		ELSE UNDEFINED
	|	END AS DocumentToBeReflectedInAccounting
	|INTO Accruals
	|FROM
	|	AccumulationRegister.AccrualsHR AS AccrualsHR
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel1
	|		ON AccrualsHR.Recorder = RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|			AND AccrualsHR.Employee = RulesForFillingInReflectionInAccountingLevel1.Employee
	|			AND AccrualsHR.Department = RulesForFillingInReflectionInAccountingLevel1.Department
	|			AND AccrualsHR.Accrual = RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel2
	|		ON AccrualsHR.Accrual = RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|			AND AccrualsHR.Employee = RulesForFillingInReflectionInAccountingLevel2.Employee
	|			AND RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation = UNDEFINED
	|			AND AccrualsHR.Department = RulesForFillingInReflectionInAccountingLevel2.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel3
	|		ON RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation = UNDEFINED
	|			AND RulesForFillingInReflectionInAccountingLevel3.Employee = VALUE(Catalog.EmployeesHR.EmptyRef)
	|			AND AccrualsHR.Accrual = RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|			AND AccrualsHR.Department = RulesForFillingInReflectionInAccountingLevel3.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel4
	|		ON RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation = UNDEFINED
	|			AND RulesForFillingInReflectionInAccountingLevel4.Employee = VALUE(Catalog.EmployeesHR.EmptyRef)
	|			AND RulesForFillingInReflectionInAccountingLevel4.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			AND AccrualsHR.Accrual = RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|WHERE
	|	AccrualsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND AccrualsHR.Employee IN(&ArrayOfEmployees)
	|	AND AccrualsHR.Organization = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeductionsHR.Organization AS Organization,
	|	DeductionsHR.Individual AS Individual,
	|	DeductionsHR.Employee AS Employee,
	|	DeductionsHR.Retention AS DeductionKind,
	|	DeductionsHR.Department AS Department,
	|	DeductionsHR.Sum AS Sum,
	|	DeductionsHR.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|		ELSE VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|	END AS TypesOfAccrualsOfDeductionsToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DivisionToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Employee
	|		ELSE VALUE(Catalog.EmployeesHR.EmptyRef)
	|	END AS EmployeeToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation
	|		ELSE UNDEFINED
	|	END AS DocumentToBeReflectedInAccounting
	|INTO Deductions
	|FROM
	|	AccumulationRegister.DeductionsHR AS DeductionsHR
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel1
	|		ON DeductionsHR.Recorder = RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|			AND DeductionsHR.Employee = RulesForFillingInReflectionInAccountingLevel1.Employee
	|			AND DeductionsHR.Department = RulesForFillingInReflectionInAccountingLevel1.Department
	|			AND DeductionsHR.Retention = RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel2
	|		ON DeductionsHR.Retention = RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|			AND DeductionsHR.Employee = RulesForFillingInReflectionInAccountingLevel2.Employee
	|			AND (RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation = UNDEFINED)
	|			AND DeductionsHR.Department = RulesForFillingInReflectionInAccountingLevel2.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel3
	|		ON (RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation = UNDEFINED)
	|			AND (RulesForFillingInReflectionInAccountingLevel3.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND DeductionsHR.Retention = RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|			AND DeductionsHR.Department = RulesForFillingInReflectionInAccountingLevel3.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel4
	|		ON (RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation = UNDEFINED)
	|			AND (RulesForFillingInReflectionInAccountingLevel4.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND (RulesForFillingInReflectionInAccountingLevel4.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|			AND DeductionsHR.Retention = RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|WHERE
	|	DeductionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND DeductionsHR.Employee IN(&ArrayOfEmployees)
	|	AND DeductionsHR.Organization = &Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesContributionsHR.Organization AS Organization,
	|	TaxesContributionsHR.Individual AS Individual,
	|	TaxesContributionsHR.TaxKind AS TaxKind,
	|	TaxesContributionsHR.Department AS Department,
	|	TaxesContributionsHR.DeductedFromEmployeeWages AS DeductedFromEmployeeWages,
	|	SUM(TaxesContributionsHR.Sum) AS Sum,
	|	SUM(TaxesContributionsHR.Base) AS Base,
	|	TaxesContributionsHR.RowID AS RowID,
	|	TaxesContributionsHR.Employee AS Employee,
	|	TaxesContributionsHR.Recorder AS Recorder,
	|	TaxesContributionsHR.Accrual AS Accrual,
	|	TaxesContributionsHR.AccrualRegistrar AS AccrualRegistrar
	|INTO TaxesContributions
	|FROM
	|	AccumulationRegister.TaxesContributionsHR AS TaxesContributionsHR
	|WHERE
	|	TaxesContributionsHR.Organization = &Organization
	|	AND TaxesContributionsHR.Period BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND TaxesContributionsHR.Employee IN(&ArrayOfEmployees)
	|	AND TaxesContributionsHR.Sum <> 0
	|
	|GROUP BY
	|	TaxesContributionsHR.Organization,
	|	TaxesContributionsHR.TaxKind,
	|	TaxesContributionsHR.Department,
	|	TaxesContributionsHR.Individual,
	|	TaxesContributionsHR.DeductedFromEmployeeWages,
	|	TaxesContributionsHR.RowID,
	|	TaxesContributionsHR.Employee,
	|	TaxesContributionsHR.Recorder,
	|	TaxesContributionsHR.Accrual,
	|	TaxesContributionsHR.AccrualRegistrar
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesContributions.Organization AS Organization,
	|	TaxesContributions.Individual AS Individual,
	|	TaxesContributions.TaxKind AS TaxKind,
	|	TaxesContributions.Department AS Department,
	|	TaxesContributions.Sum AS Sum,
	|	TaxesContributions.Base AS Base,
	|	TaxesContributions.RowID AS RowID,
	|	TaxesContributions.Employee AS Employee
	|INTO DutiesOfTaxAgent
	|FROM
	|	TaxesContributions AS TaxesContributions
	|WHERE
	|	TaxesContributions.DeductedFromEmployeeWages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesContributions.Organization AS Organization,
	|	TaxesContributions.Individual AS Individual,
	|	TaxesContributions.TaxKind AS TaxKind,
	|	TaxesContributions.Department AS Department,
	|	TaxesContributions.Sum AS Sum,
	|	TaxesContributions.Base AS Base,
	|	TaxesContributions.RowID AS RowID,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccounting1_1Level.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccounting1_1Level.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|		ELSE VALUE(Catalog.AccrualAndDeductionKinds.EmptyRef)
	|	END AS TypesOfAccrualsOfDeductionsToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccounting1_1Level.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccounting1_1Level.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Department
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DivisionToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccounting1_1Level.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccounting1_1Level.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.Employee
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.Employee
	|		ELSE VALUE(Catalog.EmployeesHR.EmptyRef)
	|	END AS EmployeeToBeReflectedInAccounting,
	|	CASE
	|		WHEN ISNULL(RulesForFillingInReflectionInAccounting1_1Level.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccounting1_1Level.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel1.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel2.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel3.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation
	|		WHEN ISNULL(RulesForFillingInReflectionInAccountingLevel4.PostingOption, VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)) <> VALUE(Enum.AccrualsDeductionsRecordOptions.EmptyRef)
	|			THEN RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation
	|		ELSE UNDEFINED
	|	END AS DocumentToBeReflectedInAccounting,
	|	TaxesContributions.Employee AS Employee
	|INTO PayrollTaxes
	|FROM
	|	TaxesContributions AS TaxesContributions
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel1
	|		ON TaxesContributions.Recorder = RulesForFillingInReflectionInAccountingLevel1.DocumentCalculation
	|			AND TaxesContributions.Employee = RulesForFillingInReflectionInAccountingLevel1.Employee
	|			AND TaxesContributions.Department = RulesForFillingInReflectionInAccountingLevel1.Department
	|			AND TaxesContributions.TaxKind = RulesForFillingInReflectionInAccountingLevel1.TypeOfAccrualDeduction
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccounting1_1Level
	|		ON TaxesContributions.AccrualRegistrar = RulesForFillingInReflectionInAccounting1_1Level.DocumentCalculation
	|			AND TaxesContributions.Employee = RulesForFillingInReflectionInAccounting1_1Level.Employee
	|			AND TaxesContributions.Department = RulesForFillingInReflectionInAccounting1_1Level.Department
	|			AND TaxesContributions.Accrual = RulesForFillingInReflectionInAccounting1_1Level.TypeOfAccrualDeduction
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel2
	|		ON TaxesContributions.Accrual = RulesForFillingInReflectionInAccountingLevel2.TypeOfAccrualDeduction
	|			AND TaxesContributions.Employee = RulesForFillingInReflectionInAccountingLevel2.Employee
	|			AND (RulesForFillingInReflectionInAccountingLevel2.DocumentCalculation = UNDEFINED)
	|			AND TaxesContributions.Department = RulesForFillingInReflectionInAccountingLevel2.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel3
	|		ON (RulesForFillingInReflectionInAccountingLevel3.DocumentCalculation = UNDEFINED)
	|			AND (RulesForFillingInReflectionInAccountingLevel3.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND TaxesContributions.Accrual = RulesForFillingInReflectionInAccountingLevel3.TypeOfAccrualDeduction
	|			AND TaxesContributions.Department = RulesForFillingInReflectionInAccountingLevel3.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingLevel4
	|		ON (RulesForFillingInReflectionInAccountingLevel4.DocumentCalculation = UNDEFINED)
	|			AND (RulesForFillingInReflectionInAccountingLevel4.Employee = VALUE(Catalog.EmployeesHR.EmptyRef))
	|			AND (RulesForFillingInReflectionInAccountingLevel4.Department = VALUE(Catalog.BusinessStructure.EmptyRef))
	|			AND TaxesContributions.Accrual = RulesForFillingInReflectionInAccountingLevel4.TypeOfAccrualDeduction
	|WHERE
	|	NOT TaxesContributions.DeductedFromEmployeeWages
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollStatusesForEmployees.CalculationPeriod AS CalculationPeriod,
	|	PayrollStatusesForEmployees.Organization AS Organization,
	|	PayrollStatusesForEmployees.Individual AS Individual,
	|	PayrollStatusesForEmployees.Employee AS Employee,
	|	PayrollStatusesForEmployees.Department AS Department,
	|	PayrollStatusesForEmployees.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	PayrollStatusesForEmployees.AllAutoCalculationsAreCompleted AS AllAutoCalculationsAreCompleted,
	|	PayrollStatusesForEmployees.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	PayrollStatusesForEmployees.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	PayrollStatusesForEmployees.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed
	|FROM
	|	PayrollStatusesForEmployees AS PayrollStatusesForEmployees
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accruals.Organization AS Organization,
	|	Accruals.Employee AS Employee,
	|	Accruals.AccrualKind AS AccrualKind,
	|	Accruals.Department AS Department,
	|	Accruals.Sum AS Sum,
	|	Accruals.Individual AS Individual,
	|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
	|	Accruals.RowID AS RowID,
	|	PayrollStatusesForEmployees.AllAutoCalculationsAreCompleted AS AllAutoCalculationsAreCompleted,
	|	RulesForFillingInReflectionInAccountingCollected.PostingOption AS PostingOption,
	|	RulesForFillingInReflectionInAccountingCollected.AllocationBaseType AS AllocationBaseType,
	|	RulesForFillingInReflectionInAccountingCollected.ProductCostElement AS ProductCostElement,
	|	RulesForFillingInReflectionInAccountingCollected.LineOfBusiness AS LineOfBusiness,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseItem AS ExpenseItem,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeItem AS IncomeItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.Counterparty AS Counterparty,
	|	RulesForFillingInReflectionInAccountingCollected.IssuancePurpose AS IssuancePurpose,
	|	RulesForFillingInReflectionInAccountingCollected.ARAPObject AS ARAPObject,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpenses AS DimensionOfExpenses,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	Accruals AS Accruals
	|		LEFT JOIN PayrollStatusesForEmployees AS PayrollStatusesForEmployees
	|		ON Accruals.Organization = PayrollStatusesForEmployees.Organization
	|			AND Accruals.Employee = PayrollStatusesForEmployees.Employee
	|			AND Accruals.Department = PayrollStatusesForEmployees.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingCollected
	|		ON Accruals.TypesOfAccrualsOfDeductionsToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.TypeOfAccrualDeduction
	|			AND Accruals.DivisionToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Department
	|			AND Accruals.EmployeeToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Employee
	|			AND Accruals.DocumentToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Deductions.Organization AS Organization,
	|	Deductions.Individual AS Individual,
	|	Deductions.Employee AS Employee,
	|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
	|	Deductions.DeductionKind AS DeductionKind,
	|	Deductions.Department AS Department,
	|	Deductions.Sum AS Sum,
	|	Deductions.RowID AS RowID,
	|	PayrollStatusesForEmployees.AllAutoCalculationsAreCompleted AS AllAutoCalculationsAreCompleted,
	|	RulesForFillingInReflectionInAccountingCollected.PostingOption AS PostingOption,
	|	RulesForFillingInReflectionInAccountingCollected.AllocationBaseType AS AllocationBaseType,
	|	RulesForFillingInReflectionInAccountingCollected.ProductCostElement AS ProductCostElement,
	|	RulesForFillingInReflectionInAccountingCollected.LineOfBusiness AS LineOfBusiness,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseItem AS ExpenseItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeItem AS IncomeItem,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.Counterparty AS Counterparty,
	|	RulesForFillingInReflectionInAccountingCollected.IssuancePurpose AS IssuancePurpose,
	|	RulesForFillingInReflectionInAccountingCollected.ARAPObject AS ARAPObject,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpenses AS DimensionOfExpenses,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfRevenue AS DimensionOfRevenue
	|FROM
	|	Deductions AS Deductions
	|		LEFT JOIN PayrollStatusesForEmployees AS PayrollStatusesForEmployees
	|		ON Deductions.Organization = PayrollStatusesForEmployees.Organization
	|			AND Deductions.Employee = PayrollStatusesForEmployees.Employee
	|			AND Deductions.Department = PayrollStatusesForEmployees.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingCollected
	|		ON Deductions.TypesOfAccrualsOfDeductionsToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.TypeOfAccrualDeduction
	|			AND Deductions.DivisionToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Department
	|			AND Deductions.EmployeeToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Employee
	|			AND Deductions.DocumentToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.DocumentCalculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DutiesOfTaxAgent.Organization AS Organization,
	|	DutiesOfTaxAgent.Individual AS Individual,
	|	DutiesOfTaxAgent.TaxKind AS TaxKind,
	|	DutiesOfTaxAgent.Department AS Department,
	|	VALUE(Catalog.TypesOfEmployeeCompensations.Payroll) AS ARAPType,
	|	DutiesOfTaxAgent.Sum AS Sum,
	|	DutiesOfTaxAgent.Base AS TaxBase,
	|	DutiesOfTaxAgent.RowID AS RowID,
	|	PayrollStatusesForEmployees.AllAutoCalculationsAreCompleted AS AllAutoCalculationsAreCompleted,
	|	DutiesOfTaxAgent.Employee AS Employee
	|FROM
	|	DutiesOfTaxAgent AS DutiesOfTaxAgent
	|		LEFT JOIN PayrollStatusesForEmployees AS PayrollStatusesForEmployees
	|		ON DutiesOfTaxAgent.Organization = PayrollStatusesForEmployees.Organization
	|			AND DutiesOfTaxAgent.Department = PayrollStatusesForEmployees.Department
	|			AND DutiesOfTaxAgent.Individual = PayrollStatusesForEmployees.Individual
	|			AND DutiesOfTaxAgent.Employee = PayrollStatusesForEmployees.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollTaxes.Organization AS Organization,
	|	PayrollTaxes.Individual AS Individual,
	|	PayrollTaxes.TaxKind AS TaxKind,
	|	PayrollTaxes.Department AS Department,
	|	PayrollTaxes.Sum AS Sum,
	|	PayrollTaxes.Base AS TaxBase,
	|	PayrollTaxes.RowID AS RowID,
	|	PayrollStatusesForEmployees.AllAutoCalculationsAreCompleted AS AllAutoCalculationsAreCompleted,
	|	RulesForFillingInReflectionInAccountingCollected.PostingOption AS PostingOption,
	|	RulesForFillingInReflectionInAccountingCollected.AllocationBaseType AS AllocationBaseType,
	|	RulesForFillingInReflectionInAccountingCollected.ProductCostElement AS ProductCostElement,
	|	RulesForFillingInReflectionInAccountingCollected.LineOfBusiness AS LineOfBusiness,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseItem AS ExpenseItem,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseAssetLiabilityItem AS ExpenseAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeItem AS IncomeItem,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeAssetLiabilityItem AS IncomeAssetLiabilityItem,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpensesAssetsLiabilities AS DimensionOfExpensesAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfIncomeAssetsLiabilities AS DimensionOfIncomeAssetsLiabilities,
	|	RulesForFillingInReflectionInAccountingCollected.IncomeLedgerAccountsSettings AS IncomeLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.ExpenseLedgerAccountsSettings AS ExpenseLedgerAccountsSettings,
	|	RulesForFillingInReflectionInAccountingCollected.Counterparty AS Counterparty,
	|	RulesForFillingInReflectionInAccountingCollected.IssuancePurpose AS IssuancePurpose,
	|	RulesForFillingInReflectionInAccountingCollected.ARAPObject AS ARAPObject,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfExpenses AS DimensionOfExpenses,
	|	RulesForFillingInReflectionInAccountingCollected.DimensionOfRevenue AS DimensionOfRevenue,
	|	PayrollTaxes.Employee AS Employee
	|FROM
	|	PayrollTaxes AS PayrollTaxes
	|		LEFT JOIN PayrollStatusesForEmployees AS PayrollStatusesForEmployees
	|		ON PayrollTaxes.Organization = PayrollStatusesForEmployees.Organization
	|			AND PayrollTaxes.Individual = PayrollStatusesForEmployees.Individual
	|			AND PayrollTaxes.Employee = PayrollStatusesForEmployees.Employee
	|			AND PayrollTaxes.Department = PayrollStatusesForEmployees.Department
	|		LEFT JOIN RulesForFillingInReflectionInAccountingCollected AS RulesForFillingInReflectionInAccountingCollected
	|		ON PayrollTaxes.TypesOfAccrualsOfDeductionsToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.TypeOfAccrualDeduction
	|			AND PayrollTaxes.DivisionToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Department
	|			AND PayrollTaxes.EmployeeToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.Employee
	|			AND PayrollTaxes.DocumentToBeReflectedInAccounting = RulesForFillingInReflectionInAccountingCollected.DocumentCalculation";
	
	RequestResultsPackage	= Query.ExecuteBatch();
	
	StructureOfPreparedData = New Structure();
	StructureOfPreparedData.Insert("StatusTable", RequestResultsPackage[14].Unload());
	StructureOfPreparedData.Insert("Accruals", 				  RequestResultsPackage[15].Unload());
	StructureOfPreparedData.Insert("Deductions", 				  RequestResultsPackage[16].Unload());
	StructureOfPreparedData.Insert("DutiesOfTaxAgent", 	  RequestResultsPackage[17].Unload());
	StructureOfPreparedData.Insert("PayrollTaxes",	  RequestResultsPackage[18].Unload());
	
	Return StructureOfPreparedData;
	
EndFunction	

Function GetDataForUnblockingPOCalculation(CalculationParameters, QueryExecutionResult)
	
	Organization = CalculationParameters.Organization;
	CalculationPeriod = CalculationParameters.CalculationPeriod;
	CalculationStatusTable = CalculationParameters.CalculationStatuses;
	ArrayOfEmployees = CalculationStatusTable.UnloadColumn("Employee");
	
	Query = New Query();   
	Query.TempTablesManager = New TempTablesManager;
	
	Query.SetParameter("SettlementStartDate", CalculationPeriod);
	Query.SetParameter("Organization", Organization);
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);
	
	Query.Text = 
	"SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoAccrualCalculationIsPerformed AS AutoAccrualCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoDeductionCalculationIsPerformed AS AutoDeductionCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.AutoTaxCalculationIsPerformed AS AutoTaxCalculationIsPerformed,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	VALUE(Enum.PayrollStatus.Preliminary) AS CalculationStatusHR
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod BETWEEN &SettlementStartDate AND ENDOFPERIOD(&SettlementStartDate, MONTH)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN(&ArrayOfEmployees)
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)";
	
	Return Query.Execute().Unload();
	
EndFunction	

Function FillInPOCalculationStatusTableWithData(FillParameters)
	
	Query = New Query;
	
	If FillParameters.ArrayOfEmployees.Count() = 0 Then	
	
		Query.Text = 
		"SELECT
		|	EmploymentRecordSliceLast.Department AS Department,
		|	EmploymentRecordSliceLast.Employee AS Employee,
		|	EmploymentRecordSliceLast.Organization AS Organization,
		|	EmployeesHR.Individual AS Individual
		|INTO ListOfEmployees
		|FROM
		|	InformationRegister.EmploymentRecord.SliceLast(
		|			&CalculationPeriod,
		|			Organization = &Organization
		|				AND WorksInBusinessUnit = TRUE
		|				AND CASE
		|					WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|						THEN TRUE
		|					ELSE Department = &Department
		|				END) AS EmploymentRecordSliceLast
		|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
		|		ON EmploymentRecordSliceLast.Employee = EmployeesHR.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	EmploymentRecord.Department,
		|	EmploymentRecord.Employee,
		|	EmploymentRecord.Organization,
		|	EmployeesHR.Individual
		|FROM
		|	InformationRegister.EmploymentRecord AS EmploymentRecord
		|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
		|		ON EmploymentRecord.Employee = EmployeesHR.Ref
		|WHERE
		|	EmploymentRecord.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
		|	AND EmploymentRecord.Organization = &Organization
		|	AND CASE
		|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|				THEN TRUE
		|			ELSE EmploymentRecord.Department = &Department
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfEmployees.Department AS Department,
		|	ListOfEmployees.Employee AS Employee,
		|	ListOfEmployees.Organization AS Organization,
		|	ListOfEmployees.Individual AS Individual,
		|	&CalculationPeriod AS CalculationPeriod,
		|	VALUE(Enum.PayrollStatus.NotCalculated) AS CalculationStatusHR
		|INTO EmployeeTableIsNotCalculated
		|FROM
		|	ListOfEmployees AS ListOfEmployees
		|
		|GROUP BY
		|	ListOfEmployees.Department,
		|	ListOfEmployees.Employee,
		|	ListOfEmployees.Organization,
		|	ListOfEmployees.Individual
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod AS CalculationPeriod,
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR AS CalculationStatusHR
		|INTO TableOfPOCalculationStatus
		|FROM
		|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
		|WHERE
		|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
		|	AND CASE
		|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|				THEN TRUE
		|			ELSE StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department = &Department
		|		END
		|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &CalculationPeriod
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(TableOfPOCalculationStatus.CalculationPeriod, EmployeeTableIsNotCalculated.CalculationPeriod) AS CalculationPeriod,
		|	ISNULL(TableOfPOCalculationStatus.Organization, EmployeeTableIsNotCalculated.Organization) AS Organization,
		|	ISNULL(TableOfPOCalculationStatus.Individual, EmployeeTableIsNotCalculated.Individual) AS Individual,
		|	ISNULL(TableOfPOCalculationStatus.Employee, EmployeeTableIsNotCalculated.Employee) AS Employee,
		|	ISNULL(TableOfPOCalculationStatus.Department, EmployeeTableIsNotCalculated.Department) AS Department,
		|	ISNULL(TableOfPOCalculationStatus.CalculationStatusHR, EmployeeTableIsNotCalculated.CalculationStatusHR) AS CalculationStatusHR,
		|	CASE
		|		WHEN ISNULL(TableOfPOCalculationStatus.Employee, 0) = 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS ThereIsEntryInPOCalculationStatuses
		|FROM
		|	EmployeeTableIsNotCalculated AS EmployeeTableIsNotCalculated
		|		FULL JOIN TableOfPOCalculationStatus AS TableOfPOCalculationStatus
		|		ON EmployeeTableIsNotCalculated.Department = TableOfPOCalculationStatus.Department
		|			AND EmployeeTableIsNotCalculated.CalculationPeriod = TableOfPOCalculationStatus.CalculationPeriod
		|			AND EmployeeTableIsNotCalculated.Employee = TableOfPOCalculationStatus.Employee
		|			AND EmployeeTableIsNotCalculated.Organization = TableOfPOCalculationStatus.Organization";
		
		Query.SetParameter("Organization", FillParameters.Organization);
		Query.SetParameter("CalculationPeriod", FillParameters.CalculationPeriod);
		Query.SetParameter("Department", FillParameters.Department);
		
	Else

		Query.Text = 
		"SELECT
		|	EmploymentRecordSliceLast.Department AS Department,
		|	EmploymentRecordSliceLast.Employee AS Employee,
		|	EmploymentRecordSliceLast.Organization AS Organization,
		|	EmployeesHR.Individual AS Individual
		|INTO ListOfEmployees
		|FROM
		|	InformationRegister.EmploymentRecord.SliceLast(
		|			&CalculationPeriod,
		|			Organization = &Organization
		|				AND Employee IN (&ListOfEmployees)
		|				AND CASE
		|					WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|						THEN TRUE
		|					ELSE Department = &Department
		|				END) AS EmploymentRecordSliceLast
		|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
		|		ON EmploymentRecordSliceLast.Employee = EmployeesHR.Ref
		|
		|UNION ALL
		|
		|SELECT
		|	EmploymentRecord.Department,
		|	EmploymentRecord.Employee,
		|	EmploymentRecord.Organization,
		|	EmployeesHR.Individual
		|FROM
		|	InformationRegister.EmploymentRecord AS EmploymentRecord
		|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
		|		ON EmploymentRecord.Employee = EmployeesHR.Ref
		|WHERE
		|	EmploymentRecord.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
		|	AND EmploymentRecord.Employee IN(&ListOfEmployees)
		|	AND CASE
		|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|				THEN TRUE
		|			ELSE EmploymentRecord.Department = &Department
		|		END
		|	AND EmploymentRecord.Organization = &Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ListOfEmployees.Department AS Department,
		|	ListOfEmployees.Employee AS Employee,
		|	ListOfEmployees.Organization AS Organization,
		|	ListOfEmployees.Individual AS Individual,
		|	&CalculationPeriod AS CalculationPeriod,
		|	VALUE(Enum.PayrollStatus.NotCalculated) AS CalculationStatusHR
		|FROM
		|	ListOfEmployees AS ListOfEmployees
		|
		|GROUP BY
		|	ListOfEmployees.Department,
		|	ListOfEmployees.Employee,
		|	ListOfEmployees.Organization,
		|	ListOfEmployees.Individual";
		
		Query.SetParameter("Organization",       FillParameters.Organization);
		Query.SetParameter("CalculationPeriod",     FillParameters.CalculationPeriod);
		Query.SetParameter("Department",     FillParameters.Department);
		Query.SetParameter("ListOfEmployees", FillParameters.ArrayOfEmployees);
		
	EndIf;
	
	Return Query.Execute().Unload();
	
EndFunction	

Procedure WriteNewDataToInformationRegisterCalculationStatusesOfPO(FillParameters, NewTableOfPOCalculationStatus)
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources");
		LockItem.DataSource = NewTableOfPOCalculationStatus;
		LockItem.UseFromDataSource("Employee" ,"Employee");
		LockItem.UseFromDataSource("Organization" ,"Organization");
		LockItem.UseFromDataSource("CalculationPeriod" ,"CalculationPeriod");
		Block.Lock();
		
		For Each CurrentRow In NewTableOfPOCalculationStatus Do
			
			Set = InformationRegisters.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CreateRecordSet();	
			Set.Filter.Organization.Set(FillParameters.Organization);    
			Set.Filter.Department.Set(CurrentRow.Department);
			Set.Filter.Employee.Set(CurrentRow.Employee);
			Set.Filter.CalculationPeriod.Set(FillParameters.CalculationPeriod);
			Set.Read();
			
			If Set.Count() <> 0 Then
				Continue;
			EndIf;
			
			NewRecord = Set.Add();
			FillPropertyValues(NewRecord, CurrentRow);
			Set.Write(True);
			
		EndDo;
		
		CommitTransaction();
	Except 
		RollbackTransaction();				
		Raise;
	EndTry;				
	
EndProcedure	

Function FillInTableOfStatusesForCalculatingPO(QueryExecutionResult)
	
	FillParameters = QueryExecutionResult.FillParameters;
	
	Query = New Query();
	Query.TempTablesManager = New TempTablesManager();
	
	Query.Text = 
	"SELECT
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization AS Organization,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Individual AS Individual,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee AS Employee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR AS CalculationStatusHR,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department AS Department,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal)
	|		OR StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.Preliminary) AS CalculatedEmployee,
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationStatusHR = VALUE(Enum.PayrollStatus.IsFinal) AS SignLock
	|INTO PayrollStatuses
	|FROM
	|	InformationRegister.StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources AS StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources
	|WHERE
	|	StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Organization = &Organization
	|	AND StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.CalculationPeriod = &CalculationPeriod
	|	AND CASE
	|			WHEN &Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN TRUE
	|			ELSE StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Department = &Department
	|		END
	|	AND CASE
	|			WHEN &SelectByEmployee
	|				THEN StatusesOfPayrollCalculationByEmployeePayrollAndHumanResources.Employee IN (&ArrayOfEmployees)
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AccrualsHR.Organization AS Organization,
	|	AccrualsHR.Individual AS Individual,
	|	AccrualsHR.Employee AS Employee,
	|	SUM(AccrualsHR.Sum) AS Sum,
	|	AccrualsHR.Department AS Department,
	|	AccrualsHR.RowID AS RowID
	|INTO Accruals
	|FROM
	|	AccumulationRegister.AccrualsHR AS AccrualsHR
	|WHERE
	|	AccrualsHR.Organization = &Organization
	|	AND AccrualsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|
	|GROUP BY
	|	AccrualsHR.Organization,
	|	AccrualsHR.Individual,
	|	AccrualsHR.Employee,
	|	AccrualsHR.Department,
	|	AccrualsHR.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeductionsHR.Organization AS Organization,
	|	DeductionsHR.Individual AS Individual,
	|	DeductionsHR.Employee AS Employee,
	|	DeductionsHR.Department AS Department,
	|	SUM(DeductionsHR.Sum) AS Sum,
	|	DeductionsHR.RowID AS RowID
	|INTO Deductions
	|FROM
	|	AccumulationRegister.DeductionsHR AS DeductionsHR
	|WHERE
	|	DeductionsHR.Organization = &Organization
	|	AND DeductionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|
	|GROUP BY
	|	DeductionsHR.Organization,
	|	DeductionsHR.Individual,
	|	DeductionsHR.Employee,
	|	DeductionsHR.Department,
	|	DeductionsHR.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesContributionsHR.Organization AS Organization,
	|	TaxesContributionsHR.Individual AS Individual,
	|	TaxesContributionsHR.Employee AS Employee,
	|	TaxesContributionsHR.Department AS Department,
	|	SUM(TaxesContributionsHR.Sum) AS Sum,
	|	TaxesContributionsHR.RowID AS RowID
	|INTO TaxesEmployee
	|FROM
	|	AccumulationRegister.TaxesContributionsHR AS TaxesContributionsHR
	|		LEFT JOIN Catalog.TaxContributionKinds AS TaxContributionKinds
	|		ON TaxesContributionsHR.TaxKind = TaxContributionKinds.Ref
	|WHERE
	|	TaxContributionKinds.DeductedFromEmployeeWages
	|	AND TaxesContributionsHR.Organization = &Organization
	|	AND TaxesContributionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|
	|GROUP BY
	|	TaxesContributionsHR.Organization,
	|	TaxesContributionsHR.Individual,
	|	TaxesContributionsHR.Employee,
	|	TaxesContributionsHR.Department,
	|	TaxesContributionsHR.RowID
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesContributionsHRTurnovers.Organization AS Organization,
	|	TaxesContributionsHRTurnovers.Individual AS Individual,
	|	TaxesContributionsHRTurnovers.Employee AS Employee,
	|	TaxesContributionsHRTurnovers.Department AS Department,
	|	SUM(TaxesContributionsHRTurnovers.SumTurnover) AS Sum
	|INTO CompanyTaxes
	|FROM
	|	AccumulationRegister.TaxesContributionsHR.Turnovers(&CalculationPeriod, ENDOFPERIOD(&CalculationPeriod, MONTH), Month, Organization = &Organization) AS TaxesContributionsHRTurnovers
	|		LEFT JOIN Catalog.TaxContributionKinds AS TaxContributionKinds
	|		ON TaxesContributionsHRTurnovers.TaxKind = TaxContributionKinds.Ref
	|WHERE
	|	NOT TaxContributionKinds.DeductedFromEmployeeWages
	|
	|GROUP BY
	|	TaxesContributionsHRTurnovers.Organization,
	|	TaxesContributionsHRTurnovers.Individual,
	|	TaxesContributionsHRTurnovers.Employee,
	|	TaxesContributionsHRTurnovers.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Accruals.Organization AS Organization,
	|	Accruals.Individual AS Individual,
	|	Accruals.Employee AS Employee,
	|	SUM(Accruals.Sum) AS Sum,
	|	Accruals.Department AS Department
	|INTO SummaryCharges
	|FROM
	|	Accruals AS Accruals
	|
	|GROUP BY
	|	Accruals.Department,
	|	Accruals.Employee,
	|	Accruals.Individual,
	|	Accruals.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Deductions.Organization AS Organization,
	|	Deductions.Individual AS Individual,
	|	Deductions.Employee AS Employee,
	|	Deductions.Department AS Department,
	|	SUM(Deductions.Sum) AS Sum
	|INTO DeductionsAreSummary
	|FROM
	|	Deductions AS Deductions
	|
	|GROUP BY
	|	Deductions.Individual,
	|	Deductions.Employee,
	|	Deductions.Department,
	|	Deductions.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TaxesEmployee.Organization AS Organization,
	|	TaxesEmployee.Individual AS Individual,
	|	TaxesEmployee.Employee AS Employee,
	|	TaxesEmployee.Department AS Department,
	|	SUM(TaxesEmployee.Sum) AS Sum
	|INTO EmployeeTaxesSummary
	|FROM
	|	TaxesEmployee AS TaxesEmployee
	|
	|GROUP BY
	|	TaxesEmployee.Individual,
	|	TaxesEmployee.Employee,
	|	TaxesEmployee.Department,
	|	TaxesEmployee.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AccrualsHR.Organization AS Organization,
	|	AccrualsHR.Individual AS Individual,
	|	AccrualsHR.Employee AS Employee,
	|	AccrualsHR.Department AS Department,
	|	TRUE AS ThereAreManualAccruals
	|INTO TableOfManualAccruals
	|FROM
	|	AccumulationRegister.AccrualsHR AS AccrualsHR
	|WHERE
	|	AccrualsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|	AND AccrualsHR.ManualAccrual
	|
	|GROUP BY
	|	AccrualsHR.Organization,
	|	AccrualsHR.Individual,
	|	AccrualsHR.Employee,
	|	AccrualsHR.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CASE
	|			WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Expense)
	|				THEN -PayrollCalculationsHR.Sum
	|			ELSE PayrollCalculationsHR.Sum
	|		END) AS AmountToBePaid,
	|	PayrollCalculationsHR.Individual AS Individual,
	|	PayrollCalculationsHR.Organization AS Organization,
	|	PayrollCalculationsHR.Department AS Department,
	|	CASE
	|		WHEN ISNULL(Accruals.Employee, 0) <> 0
	|			THEN Accruals.Employee
	|		WHEN ISNULL(Deductions.Employee, 0) <> 0
	|			THEN Deductions.Employee
	|		WHEN ISNULL(TaxesEmployee.Employee, 0) <> 0
	|			THEN TaxesEmployee.Employee
	|	END AS Employee
	|INTO TableOfAmountsToBePaidDetailed
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR AS PayrollCalculationsHR
	|		LEFT JOIN Accruals AS Accruals
	|		ON PayrollCalculationsHR.FinRecordID = Accruals.RowID
	|		LEFT JOIN Deductions AS Deductions
	|		ON PayrollCalculationsHR.FinRecordID = Deductions.RowID
	|		LEFT JOIN TaxesEmployee AS TaxesEmployee
	|		ON PayrollCalculationsHR.FinRecordID = TaxesEmployee.RowID
	|WHERE
	|	PayrollCalculationsHR.Organization = &Organization
	|	AND PayrollCalculationsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|
	|GROUP BY
	|	PayrollCalculationsHR.Organization,
	|	PayrollCalculationsHR.Department,
	|	PayrollCalculationsHR.Individual,
	|	CASE
	|		WHEN ISNULL(Accruals.Employee, 0) <> 0
	|			THEN Accruals.Employee
	|		WHEN ISNULL(Deductions.Employee, 0) <> 0
	|			THEN Deductions.Employee
	|		WHEN ISNULL(TaxesEmployee.Employee, 0) <> 0
	|			THEN TaxesEmployee.Employee
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(TableOfAmountsToBePaidDetailed.AmountToBePaid) AS AmountToBePaid,
	|	TableOfAmountsToBePaidDetailed.Individual AS Individual,
	|	PayrollStatuses.Organization AS Organization,
	|	PayrollStatuses.Department AS Department,
	|	TableOfAmountsToBePaidDetailed.Employee AS Employee
	|INTO TableOfAmountsToBePaid
	|FROM
	|	PayrollStatuses AS PayrollStatuses
	|		LEFT JOIN TableOfAmountsToBePaidDetailed AS TableOfAmountsToBePaidDetailed
	|		ON PayrollStatuses.Organization = TableOfAmountsToBePaidDetailed.Organization
	|			AND PayrollStatuses.Individual = TableOfAmountsToBePaidDetailed.Individual
	|			AND PayrollStatuses.Employee = TableOfAmountsToBePaidDetailed.Employee
	|			AND PayrollStatuses.Department = TableOfAmountsToBePaidDetailed.Department
	|
	|GROUP BY
	|	PayrollStatuses.Organization,
	|	PayrollStatuses.Department,
	|	TableOfAmountsToBePaidDetailed.Individual,
	|	TableOfAmountsToBePaidDetailed.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TaxesContributionsHR.Organization AS Organization,
	|	TaxesContributionsHR.Individual AS Individual,
	|	TaxesContributionsHR.Employee AS Employee,
	|	TaxesContributionsHR.Department AS Department,
	|	TRUE AS ThereAreManualTaxesFromEmployee
	|INTO TableOfManualTaxesFromEmployee
	|FROM
	|	AccumulationRegister.TaxesContributionsHR AS TaxesContributionsHR
	|WHERE
	|	TaxesContributionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|	AND TaxesContributionsHR.DeductedFromEmployeeWages
	|	AND TaxesContributionsHR.ManualTax
	|
	|GROUP BY
	|	TaxesContributionsHR.Organization,
	|	TaxesContributionsHR.Individual,
	|	TaxesContributionsHR.Employee,
	|	TaxesContributionsHR.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegularAccrualsAndDeductionsHR.Organization AS Organization,
	|	RegularAccrualsAndDeductionsHR.Department AS Department,
	|	RegularAccrualsAndDeductionsHR.Employee AS Employee,
	|	1 AS SalaryChange
	|INTO PersonnelDocuments
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR AS RegularAccrualsAndDeductionsHR
	|WHERE
	|	RegularAccrualsAndDeductionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|	AND RegularAccrualsAndDeductionsHR.Organization = &Organization
	|	AND NOT RegularAccrualsAndDeductionsHR.Recorder REFS Document.HiringHR
	|	AND RegularAccrualsAndDeductionsHR.Valid
	|
	|GROUP BY
	|	RegularAccrualsAndDeductionsHR.Organization,
	|	RegularAccrualsAndDeductionsHR.Department,
	|	RegularAccrualsAndDeductionsHR.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataOnEmployeeTimesheetTurnovers.Recorder AS Recorder,
	|	DataOnEmployeeTimesheetTurnovers.Organization AS Organization,
	|	DataOnEmployeeTimesheetTurnovers.Employee AS Employee
	|INTO TimesheetsForDocuments
	|FROM
	|	AccumulationRegister.DataOnEmployeeTimesheet.Turnovers(&CalculationPeriod, ENDOFPERIOD(&CalculationPeriod, MONTH), Recorder, Organization = &Organization) AS DataOnEmployeeTimesheetTurnovers
	|WHERE
	|	DataOnEmployeeTimesheetTurnovers.Organization = &Organization
	|
	|GROUP BY
	|	DataOnEmployeeTimesheetTurnovers.Recorder,
	|	DataOnEmployeeTimesheetTurnovers.Organization,
	|	DataOnEmployeeTimesheetTurnovers.Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	TaxesContributionsHR.Organization AS Organization,
	|	TaxesContributionsHR.Individual AS Individual,
	|	TaxesContributionsHR.Employee AS Employee,
	|	TaxesContributionsHR.Department AS Department,
	|	TRUE AS ThereAreManualTaxesFromCompany
	|INTO TableOfManualTaxesFromCompany
	|FROM
	|	AccumulationRegister.TaxesContributionsHR AS TaxesContributionsHR
	|WHERE
	|	TaxesContributionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|	AND NOT TaxesContributionsHR.DeductedFromEmployeeWages
	|	AND TaxesContributionsHR.ManualTax
	|
	|GROUP BY
	|	TaxesContributionsHR.Organization,
	|	TaxesContributionsHR.Individual,
	|	TaxesContributionsHR.Employee,
	|	TaxesContributionsHR.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DeductionsHR.Organization AS Organization,
	|	DeductionsHR.Individual AS Individual,
	|	DeductionsHR.Employee AS Employee,
	|	DeductionsHR.Department AS Department,
	|	TRUE AS ThereAreManualDeductions
	|INTO TableOfManualDeductions
	|FROM
	|	AccumulationRegister.DeductionsHR AS DeductionsHR
	|WHERE
	|	DeductionsHR.Period BETWEEN &CalculationPeriod AND ENDOFPERIOD(&CalculationPeriod, MONTH)
	|	AND DeductionsHR.ManualDeduction
	|
	|GROUP BY
	|	DeductionsHR.Organization,
	|	DeductionsHR.Individual,
	|	DeductionsHR.Employee,
	|	DeductionsHR.Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TimesheetsForDocuments.Employee AS Employee,
	|	SUM(1) AS DocumentsCount,
	|	TimesheetsForDocuments.Organization AS Organization
	|INTO NumberOfTimeSheets
	|FROM
	|	TimesheetsForDocuments AS TimesheetsForDocuments
	|
	|GROUP BY
	|	TimesheetsForDocuments.Employee,
	|	TimesheetsForDocuments.Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegularAccrualsAndDeductionsHRSliceLast.Employee AS Employee,
	|	AccrualAndDeductionKinds.AccrualMethod AS MethodOfAccrualOfBasicEarnings,
	|	RegularAccrualsAndDeductionsHRSliceLast.Organization AS Organization,
	|	RegularAccrualsAndDeductionsHRSliceLast.Department AS Department
	|INTO MethodsOfAccrualOfBasicEarnings
	|FROM
	|	InformationRegister.RegularAccrualsAndDeductionsHR.SliceLast(ENDOFPERIOD(&CalculationPeriod, MONTH), Organization = &Organization) AS RegularAccrualsAndDeductionsHRSliceLast
	|		LEFT JOIN Catalog.AccrualAndDeductionKinds AS AccrualAndDeductionKinds
	|		ON RegularAccrualsAndDeductionsHRSliceLast.AccrualDeduction = AccrualAndDeductionKinds.Ref
	|WHERE
	|	RegularAccrualsAndDeductionsHRSliceLast.BasicEarnings
	|	AND RegularAccrualsAndDeductionsHRSliceLast.Valid
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PayrollStatuses.Organization AS Organization,
	|	PayrollStatuses.Individual AS Individual,
	|	PayrollStatuses.Employee AS Employee,
	|	PayrollStatuses.CalculationStatusHR AS CalculationStatusHR,
	|	PayrollStatuses.DocumentOfPostingInAccounting AS DocumentOfPostingInAccounting,
	|	SUM(Accruals.Sum) AS AmountIsAccrued,
	|	PayrollStatuses.Department AS Department,
	|	SUM(Deductions.Sum) AS AmountDeductions,
	|	TableOfManualAccruals.ThereAreManualAccruals AS ThereAreManualAccruals,
	|	TableOfManualDeductions.ThereAreManualDeductions AS ThereAreManualDeductions,
	|	SUM(CompanyTaxes.Sum) AS TaxesFromCompany,
	|	SUM(TaxesEmployee.Sum) AS TaxesFromEmployee,
	|	TableOfManualTaxesFromCompany.ThereAreManualTaxesFromCompany AS ThereAreManualTaxesFromCompany,
	|	TableOfManualTaxesFromEmployee.ThereAreManualTaxesFromEmployee AS ThereAreManualTaxesFromEmployee,
	|	PayrollStatuses.CalculatedEmployee AS CalculatedEmployee,
	|	PayrollStatuses.SignLock AS SignLock,
	|	SUM(-TableOfAmountsToBePaid.AmountToBePaid) AS AmountToBePaid,
	|	SUM(ISNULL(NumberOfTimeSheets.DocumentsCount, 0)) AS TimeCard,
	|	FALSE AS ThereAreErrorsInTimesheets,
	|	FALSE AS ThereAreErrorsInAccruals,
	|	FALSE AS ThereAreErrorsInDeductions,
	|	FALSE AS ThereAreErrorsInTaxesFromEmployee,
	|	FALSE AS ThereAreErrorsInTaxesFromCompany,
	|	MethodsOfAccrualOfBasicEarnings.MethodOfAccrualOfBasicEarnings AS MethodOfAccrualOfBasicEarnings,
	|	SUM(PersonnelDocuments.SalaryChange) AS SalaryChange,
	|	ISNULL(EmployeesHR.Description, """") AS NameOfEmployee
	|FROM
	|	PayrollStatuses AS PayrollStatuses
	|		LEFT JOIN SummaryCharges AS Accruals
	|		ON PayrollStatuses.Organization = Accruals.Organization
	|			AND PayrollStatuses.Employee = Accruals.Employee
	|			AND PayrollStatuses.Department = Accruals.Department
	|		LEFT JOIN DeductionsAreSummary AS Deductions
	|		ON PayrollStatuses.Organization = Deductions.Organization
	|			AND PayrollStatuses.Department = Deductions.Department
	|			AND PayrollStatuses.Employee = Deductions.Employee
	|		LEFT JOIN TableOfManualAccruals AS TableOfManualAccruals
	|		ON PayrollStatuses.Organization = TableOfManualAccruals.Organization
	|			AND PayrollStatuses.Employee = TableOfManualAccruals.Employee
	|			AND PayrollStatuses.Department = TableOfManualAccruals.Department
	|		LEFT JOIN TableOfManualDeductions AS TableOfManualDeductions
	|		ON PayrollStatuses.Organization = TableOfManualDeductions.Organization
	|			AND PayrollStatuses.Employee = TableOfManualDeductions.Employee
	|			AND PayrollStatuses.Department = TableOfManualDeductions.Department
	|		LEFT JOIN EmployeeTaxesSummary AS TaxesEmployee
	|		ON PayrollStatuses.Organization = TaxesEmployee.Organization
	|			AND PayrollStatuses.Individual = TaxesEmployee.Individual
	|			AND PayrollStatuses.Employee = TaxesEmployee.Employee
	|			AND PayrollStatuses.Department = TaxesEmployee.Department
	|		LEFT JOIN CompanyTaxes AS CompanyTaxes
	|		ON PayrollStatuses.Organization = CompanyTaxes.Organization
	|			AND PayrollStatuses.Individual = CompanyTaxes.Individual
	|			AND PayrollStatuses.Employee = CompanyTaxes.Employee
	|			AND PayrollStatuses.Department = CompanyTaxes.Department
	|		LEFT JOIN TableOfManualTaxesFromEmployee AS TableOfManualTaxesFromEmployee
	|		ON PayrollStatuses.Organization = TableOfManualTaxesFromEmployee.Organization
	|			AND PayrollStatuses.Individual = TableOfManualTaxesFromEmployee.Individual
	|			AND PayrollStatuses.Employee = TableOfManualTaxesFromEmployee.Employee
	|			AND PayrollStatuses.Department = TableOfManualTaxesFromEmployee.Department
	|		LEFT JOIN TableOfManualTaxesFromCompany AS TableOfManualTaxesFromCompany
	|		ON PayrollStatuses.Organization = TableOfManualTaxesFromCompany.Organization
	|			AND PayrollStatuses.Individual = TableOfManualTaxesFromCompany.Individual
	|			AND PayrollStatuses.Employee = TableOfManualTaxesFromCompany.Employee
	|			AND PayrollStatuses.Department = TableOfManualTaxesFromCompany.Department
	|		LEFT JOIN PersonnelDocuments AS PersonnelDocuments
	|		ON PayrollStatuses.Organization = PersonnelDocuments.Organization
	|			AND PayrollStatuses.Employee = PersonnelDocuments.Employee
	|			AND PayrollStatuses.Department = PersonnelDocuments.Department
	|		LEFT JOIN TableOfAmountsToBePaid AS TableOfAmountsToBePaid
	|		ON PayrollStatuses.Organization = TableOfAmountsToBePaid.Organization
	|			AND PayrollStatuses.Department = TableOfAmountsToBePaid.Department
	|			AND PayrollStatuses.Individual = TableOfAmountsToBePaid.Individual
	|			AND PayrollStatuses.Employee = TableOfAmountsToBePaid.Employee
	|		LEFT JOIN NumberOfTimeSheets AS NumberOfTimeSheets
	|		ON PayrollStatuses.Employee = NumberOfTimeSheets.Employee
	|		LEFT JOIN MethodsOfAccrualOfBasicEarnings AS MethodsOfAccrualOfBasicEarnings
	|		ON PayrollStatuses.Employee = MethodsOfAccrualOfBasicEarnings.Employee
	|			AND PayrollStatuses.Organization = MethodsOfAccrualOfBasicEarnings.Organization
	|			AND PayrollStatuses.Department = MethodsOfAccrualOfBasicEarnings.Department
	|		LEFT JOIN Catalog.EmployeesHR AS EmployeesHR
	|		ON PayrollStatuses.Employee = EmployeesHR.Ref
	|
	|GROUP BY
	|	TableOfManualTaxesFromEmployee.ThereAreManualTaxesFromEmployee,
	|	PayrollStatuses.SignLock,
	|	PayrollStatuses.CalculatedEmployee,
	|	PayrollStatuses.Individual,
	|	PayrollStatuses.Organization,
	|	MethodsOfAccrualOfBasicEarnings.MethodOfAccrualOfBasicEarnings,
	|	PayrollStatuses.Department,
	|	PayrollStatuses.Employee,
	|	TableOfManualTaxesFromCompany.ThereAreManualTaxesFromCompany,
	|	TableOfManualAccruals.ThereAreManualAccruals,
	|	PayrollStatuses.DocumentOfPostingInAccounting,
	|	PayrollStatuses.CalculationStatusHR,
	|	TableOfManualDeductions.ThereAreManualDeductions,
	|	ISNULL(EmployeesHR.Description, """")
	|
	|ORDER BY
	|	NameOfEmployee";
	
	Query.SetParameter("Organization",   FillParameters.Organization);
	Query.SetParameter("Department", FillParameters.Department);
	Query.SetParameter("CalculationPeriod", FillParameters.CalculationPeriod);  
	
	ArrayOfEmployees =	?(FillParameters.Property("ArrayOfEmployees"), 
												FillParameters.ArrayOfEmployees, New Array());	
	Query.SetParameter("ArrayOfEmployees", ArrayOfEmployees);  
	Query.SetParameter("SelectByEmployee", ArrayOfEmployees.Count() > 0);  
	Query.SetParameter("ARAPType",    Catalogs.TypesOfEmployeeCompensations.Payroll);
	
	StatusTable = Query.Execute().Unload();
	
	Return StatusTable;
	
EndFunction	

#EndRegion

#EndIf
