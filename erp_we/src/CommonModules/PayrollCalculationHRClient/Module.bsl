#Region Internal

// Starts the procedure for filling in the PO calculation status table
// 
// Parameters:
//   FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure FillInTableOfStatusesForCalculatingPO(FillParameters, Form) Export

	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForFillingInCalculationStatusesOfPO(
		Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputProgressBar = False;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Заполнение таблицы статусов расчета ЗП';
										|vi = 'Fill in the payroll calculation status table';
										|en = 'Fill in the payroll calculation status table'; fa = 'Fill in the payroll calculation status table';
										|it = 'Fill in the payroll calculation status table';
										|pl = 'Fill in the payroll calculation status table';
										|tr = 'Bordro hesaplama durumları tablosunun doldurulması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Таблица заполнена';
														|vi = 'Table is filled';
														|en = 'Table is filled'; fa = 'Table is filled';
														|it = 'Table is filled';
														|pl = 'Table is filled';
														|tr = 'Tablo dolduruldu'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("ImportParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfFillingInPOCalculationStatusesTable", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Called at the End of filling in the Status table for calculating the PO
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfFillingInPOCalculationStatusesTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress);
	
	Notify("FillingInPOCalculationStatusTable", ResultsTable, 
																	AdditionalParameters.Form);
	
EndProcedure

// Starts the procedure for filling in po calculation Statuses
// 
// Parameters:
//   FillParameters - Structure - The fill parameters
//  Form - ClientApplicationForm - Form
//
Procedure FillInPOCalculationStatuses(FillParameters, Form) Export

	TimeConsumingOperation = 
		PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForFillingInInformationRegisterOfPOCalculationStatuses(
																			Form.UUID, FillParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Заполнение статусов расчета заработной платы';
										|vi = 'Fill in payroll calculation statuses';
										|en = 'Fill in payroll calculation statuses'; fa = 'Fill in payroll calculation statuses';
										|it = 'Fill in payroll calculation statuses';
										|pl = 'Fill in payroll calculation statuses';
										|tr = 'Bordro hesaplama durumlarının doldurulması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Статусы расчета заработной платы заполнены';
														|vi = 'Payroll calculation statuses are filled';
														|en = 'Payroll calculation statuses are filled'; fa = 'Payroll calculation statuses are filled';
														|it = 'Payroll calculation statuses are filled';
														|pl = 'Payroll calculation statuses are filled';
														|tr = 'Bordro hesaplama durumları dolduruldu'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("FillParameters", FillParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfFillingInPayrollStatuses", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

// Called at the End of filling in payroll Statuses
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//
Procedure EndOfFillingInPayrollStatuses(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Form = AdditionalParameters.Form;
	QueryExecutionResult = GetFromTempStorage(Result.ResultAddress);
	
	If Result.Status = "Error" Then
			
		Raise Result.BriefErrorDescription;
		
	EndIf;
	
	Notify("NotifyAboutEndOfFillingInPayrollStatusesATServer", 
											QueryExecutionResult, Form);
	
EndProcedure

// Starts unblocking calculation
// 
// Parameters:
//   CalculationParameters - Structure - Calculation parameters
//  Form - ClientApplicationForm - Form
//
Procedure UnblockCalculation(CalculationParameters, Form) Export
	
	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForUnblockingCalculation(
		Form.UUID, CalculationParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Разблокировка расчета';
										|vi = 'Unlock calculation';
										|en = 'Unlock calculation'; fa = 'Unlock calculation';
										|it = 'Unlock calculation';
										|pl = 'Unlock calculation';
										|tr = 'Hesaplamanın kilidini açma'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Расчет разблокирован';
														|vi = 'Calculation is unlocked';
														|en = 'Calculation is unlocked'; fa = 'Calculation is unlocked';
														|it = 'Calculation is unlocked';
														|pl = 'Calculation is unlocked';
														|tr = 'Hesaplamanın kilidi açıldı'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CalculationParameters", CalculationParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfUnblockingCalculation", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of Unblocking the calculation 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfUnblockingCalculation(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress); 
	ResultParameters = New Structure("ErrorsArray,CalculationParameters", ResultsTable.ErrorsArray, 
																	AdditionalParameters.CalculationParameters);
	
	Notify("CalculationHasBeenUnblocked", ResultParameters, AdditionalParameters.Form);
	
EndProcedure

// Starts the accrual calculation procedure
// 
// Parameters:
//   CalculationParameters - Structure - Calculation parameters
//  Form - ClientApplicationForm - Form
//
Procedure CalculateAccruals(CalculationParameters, Form) Export
	
	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForCalculatingAccruals(
		Form.UUID, CalculationParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Расчет начислений';
										|vi = 'Accrual calculation';
										|en = 'Accrual calculation'; fa = 'Accrual calculation';
										|it = 'Accrual calculation';
										|pl = 'Accrual calculation';
										|tr = 'Tahakkukların hesaplanması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Начисления рассчитаны';
														|vi = 'Accruals are calculated';
														|en = 'Accruals are calculated'; fa = 'Accruals are calculated';
														|it = 'Accruals are calculated';
														|pl = 'Accruals are calculated';
														|tr = 'Tahakkuklar hesaplandı'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CalculationParameters", CalculationParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfAccrualCalculation", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of the accrual calculation 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfAccrualCalculation(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress); 
	ResultParameters = New Structure("ErrorsArray,CalculationParameters", ResultsTable.ErrorsArray, 
																	AdditionalParameters.CalculationParameters);
	
	Notify("CalculationOfAccrualsCompleted", ResultParameters, AdditionalParameters.Form);
	
EndProcedure

// Starts the deduction calculation procedure
// 
// Parameters:
//   CalculationParameters - Structure - Calculation parameters
//  Form - ClientApplicationForm - Form
//
Procedure CalculateDeductions(CalculationParameters, Form) Export
	
	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForCalculatingDeductions(
		Form.UUID, CalculationParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Расчет удержаний';
										|vi = 'Deduction calculation';
										|en = 'Deduction calculation'; fa = 'Deduction calculation';
										|it = 'Deduction calculation';
										|pl = 'Deduction calculation';
										|tr = 'Kesintilerin hesaplanması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Удержания рассчитаны';
														|vi = 'Deductions are calculated';
														|en = 'Deductions are calculated'; fa = 'Deductions are calculated';
														|it = 'Deductions are calculated';
														|pl = 'Deductions are calculated';
														|tr = 'Kesintiler hesaplandı'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CalculationParameters", CalculationParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfDeductionCalculation", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of the deduction calculation
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfDeductionCalculation(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress); 
	ResultParameters = New Structure("ErrorsArray,CalculationParameters", ResultsTable.ErrorsArray, 
																		AdditionalParameters.CalculationParameters);
	
	Notify("DeductionsAreCalculated", ResultParameters, AdditionalParameters.Form);
	
EndProcedure

// Starts the tax calculation procedure
// 
// Parameters:
//   CalculationParameters - Structure - Calculation parameters
//  Form - ClientApplicationForm - Form
//
Procedure CalculateTaxes(CalculationParameters, Form) Export
	
	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaxCalculationTask(
		Form.UUID, CalculationParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Расчет налогов';
										|vi = 'Tax calculation';
										|en = 'Tax calculation'; fa = 'Tax calculation';
										|it = 'Tax calculation';
										|pl = 'Tax calculation';
										|tr = 'Vergilerin hesaplanması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Налоги рассчитаны';
														|vi = 'Taxes are calculated';
														|en = 'Taxes are calculated'; fa = 'Taxes are calculated';
														|it = 'Taxes are calculated';
														|pl = 'Taxes are calculated';
														|tr = 'Vergiler hesaplandı'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CalculationParameters", CalculationParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfTaxCalculation", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of the tax calculation
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfTaxCalculation(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress); 
	ResultParameters = New Structure("ErrorsArray,CalculationParameters", ResultsTable.ErrorsArray, 
																		AdditionalParameters.CalculationParameters);
	
	Notify("TaxCalculationHasBeenCompleted", ResultParameters, AdditionalParameters.Form);
	
EndProcedure

// Starts the procedure for calculating the Amount to be paid
// 
// Parameters:
//   CalculationParameters - Structure - Calculation parameters
//  Form - ClientApplicationForm - Form
//
Procedure CalculateAmountToBePaid(CalculationParameters, Form) Export
	
	TimeConsumingOperation = PayrollCalculationPayrollAndHumanResourcesServerCall.FillInParametersOfBackgroundTaskForCalculatingAmountToBePaid(
		Form.UUID, CalculationParameters);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
	IdleParameters.OwnerForm = Form;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.OutputMessages = True;
	IdleParameters.MessageText = NStr("ru = 'Расчет суммы к выплате';
										|vi = 'Calculate amount to be paid';
										|en = 'Calculate amount to be paid'; fa = 'محاسبه مبلغ قابل پرداخت';
										|it = 'Calculate amount to be paid';
										|pl = 'Calculate amount to be paid';
										|tr = 'Ödenecek tutarın hesaplanması'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.UserNotification.Explanation = NStr("ru = 'Сумма к выплате рассчитана';
														|vi = 'Amount to be paid is calculated';
														|en = 'Amount to be paid is calculated'; fa = 'Amount to be paid is calculated';
														|it = 'Amount to be paid is calculated';
														|pl = 'Amount to be paid is calculated';
														|tr = 'Ödenecek tutar hesaplandı'");
	IdleParameters.UserNotification.Text = NStr("ru = 'Расчет заработной платы';
												|vi = 'Payroll calculation';
												|en = 'Payroll calculation'; fa = 'محاسبه حقوق';
												|it = 'Payroll calculation';
												|pl = 'Payroll calculation';
												|tr = 'Bordro hesaplama'");
	
	AdditionalParameters = New Structure(); 
	AdditionalParameters.Insert("Form", Form);
	AdditionalParameters.Insert("CalculationParameters", CalculationParameters);
	
	CallbackOnCompletion = New CallbackDescription("EndOfCalculationOfAmountToBePaid", 
		ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure	

// Called at the End of the calculation of the amount to be paid
// 
// Parameters:
//   Result - Structure - result parameters
//   AdditionalParameters - Structure - advanced setting
//    
Procedure EndOfCalculationOfAmountToBePaid(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ResultsTable = GetFromTempStorage(Result.ResultAddress); 
	ResultParameters = New Structure("ErrorsArray", ResultsTable.ErrorsArray);
	
	Notify("AmountToBePaidHasBeenCalculated", ResultParameters, AdditionalParameters.Form);
	
EndProcedure

#EndRegion
