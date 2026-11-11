#Region Internal

// Fills in the parameters of the background task for filling in the table of Status calculation of the PO
// 
// Parameters:
// 	UUID - UUID - unique identifier
// 	FillParameters - Structure - The fill parameters
// 
// Returns:
// See TimeConsumingOperations.ExecuteFunction.
//
Function FillInParametersOfBackgroundTaskForFillingInCalculationStatusesOfPO(UUID, FillParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForFillingInCalculationStatusesOfPO(
			UUID, FillParameters);
	
EndFunction

// Fills in the parameters of the background task to fill in the payroll Status information register.
//
// Parameters:
//   UUID - UUID - unique task ID.
//   FillParameters - Structure - parameters required to fill in the register.
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction.
Function FillInParametersOfBackgroundTaskForFillingInInformationRegisterOfPOCalculationStatuses(UUID, FillParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForFillingInInformationRegisterOfPOCalculationStatuses(
			UUID, FillParameters);
	
EndFunction

// Generates the parameters of the background task for calculating accruals.
//
// Parameters:
//   UUID - UUID - unique calculation ID
//   CalculationParameters - Structure - structure with parameters for calculating accruals
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction
Function FillInParametersOfBackgroundTaskForCalculatingAccruals(UUID, CalculationParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForCalculatingAccruals(
			UUID, CalculationParameters);
	
EndFunction

// Generates the parameters of the background task for unblocking the calculation.
//
// Parameters:
//   UUID - UUID - unique calculation ID
//   CalculationParameters - Structure - structure with parameters for calculation
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction
Function FillInParametersOfBackgroundTaskForUnblockingCalculation(UUID, CalculationParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForUnblockingCalculation(
			UUID, CalculationParameters);
	
EndFunction


// Generates parameters for a background task for calculating deductions.
//
// Parameters:
//   UUID - UUID - Unique Task ID
//   CalculationParameters - Structure - structure with parameters for calculating deductions
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction
Function FillInParametersOfBackgroundTaskForCalculatingDeductions(UUID, CalculationParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForCalculatingDeductions(
			UUID, CalculationParameters);
	
EndFunction

// Generates the parameters of the background task for calculating taxes.
//
// Parameters:
//   UUID - UUID - unique identifier of the operation
//   CalculationParameters - Structure - structure with parameters for calculating taxes
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction
Function FillInParametersOfBackgroundTaxCalculationTask(UUID, CalculationParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaxCalculationTask(
			UUID, CalculationParameters);
	
EndFunction

// Generates the parameters of the background task for calculating the amount to be paid.
//
// Parameters:
//   UUID - UUID - unique calculation ID
//   CalculationParameters - Structure - structure with parameters for calculating the amount to be paid
//
// Returns:
//   See TimeConsumingOperations.ExecuteFunction
Function FillInParametersOfBackgroundTaskForCalculatingAmountToBePaid(UUID, CalculationParameters) Export
	
	Return PayrollCalculationHRServer.FillInParametersOfBackgroundTaskForCalculatingAmountToBePaid(
			UUID, CalculationParameters);
	
EndFunction

#EndRegion
