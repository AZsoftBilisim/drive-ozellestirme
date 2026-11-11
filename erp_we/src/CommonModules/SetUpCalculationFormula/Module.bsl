#Region Internal

// Returns a structure with the parameters of the HR calculation formula.
//
// Returns:
//   Structure - the parameters of the ZIK calculation formula, including the accrual method, the use of the coefficient, the coefficient and the type of working time:
//     * AccrualMethod - EnumRef.AccrualMethodsPayrollAndHumanResources - HR accrual method.
//     * UseCoefficient - Boolean - indicates whether the coefficient is being used.
//     * ZoomRatio - Number - the value of the coefficient.
//     * PayCode - CatalogRef.PayCodesHR - type of working time.
Function ParametersOfCalculationFormulaFromForm() Export
	
	FormulaCompositionParameters = New Structure;
	FormulaCompositionParameters.Insert("AccrualMethod", Enums.AccrualMethodsPayrollAndHumanResources.EmptyRef());
	FormulaCompositionParameters.Insert("UseCoefficient", False);
	FormulaCompositionParameters.Insert("ZoomRatio", 0);
	FormulaCompositionParameters.Insert("PayCode", Catalogs.PayCodesHR.EmptyRef());
	
	Return FormulaCompositionParameters;
	
EndFunction	

// Generates a salary calculation formula based on the specified parameters.
//
// Parameters:
//   CalculationFormulaParameters - Structure - Contains parameters for the calculation formula.
//
// Returns:
//   String - The generated salary calculation formula.
Function MakeCalculationFormula(CalculationFormulaParameters) Export
	
	StructureOfIndicators = InitiateMetrics();
	
	IndicatorsOfBaseRates = StructureOfIndicators.IndicatorsOfBaseRates;
	DivisorIndicators      = StructureOfIndicators.DivisorIndicators;              
	TimeTrackingIndicators  = StructureOfIndicators.TimeTrackingIndicators;
	
	BaseRateIndicator	= IndicatorsOfBaseRates.Get(CalculationFormulaParameters.AccrualMethod);
	DivisorExponent		= DivisorIndicators.Get(CalculationFormulaParameters.AccrualMethod);
	TimeTrackingIndicator	= TimeTrackingIndicators.Get(CalculationFormulaParameters.AccrualMethod);
	
	CalculationFormula = BaseRateIndicator.PredefinedDataName;
	
	If DivisorExponent <> Undefined Then
		
		CalculationFormula = CalculationFormula + "/" + DivisorExponent.PredefinedDataName;	
		
	EndIf;	
	
	If TimeTrackingIndicator <> Undefined Then
		
		CalculationFormula = CalculationFormula + "*" + TimeTrackingIndicator.PredefinedDataName;	
		
	EndIf;	
	
	If CalculationFormulaParameters.UseCoefficient Then
		
		CalculationFormula = CalculationFormula + " " + "*" + " " + CalculationFormulaParameters.ZoomRatio;
		
	EndIf;	
	
	Return CalculationFormula;
	
EndFunction	

// Restores Form settings based on the calculation formula.
//
// Parameters:
//   CalculationFormula - String - Calculation formula based on which the Form settings are restored
//
// Returns:
//   Structure - See ParametersOfCalculationFormulaFromForm()
Function RestoreFormSettingsUsingCalculationFormula(CalculationFormula) Export
	
	StructureOfFormIndicators = DecomposeCalculationFormula(CalculationFormula);
	
	Return  StructureOfFormIndicators;
	
EndFunction

#EndRegion

#Region Private

Function InitiateMetrics()
	
	ComplianceOfAccrualMethodWithBasicIndicator = New Map();

	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.Development_1, 
															Catalogs.CalculationIndicatorsHR.Development_1);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalary, 
															Catalogs.CalculationIndicatorsHR.BaseSalary);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked, 
															Catalogs.CalculationIndicatorsHR.BaseSalary);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked, 
															Catalogs.CalculationIndicatorsHR.BaseSalary);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerDay, 
															Catalogs.CalculationIndicatorsHR.AmountByAccrual);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerMonth, 
															Catalogs.CalculationIndicatorsHR.AmountByAccrual);
	ComplianceOfAccrualMethodWithBasicIndicator.Insert(Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerHour, 
															Catalogs.CalculationIndicatorsHR.AmountByAccrual);
	
	DivisorMatching = New Map();
	DivisorMatching.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked, 
															Catalogs.CalculationIndicatorsHR.NormalWorkdays);
	DivisorMatching.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked, 
															Catalogs.CalculationIndicatorsHR.NormOfHours);
	
	ComplianceWithTimeTracking = New Map();
	ComplianceWithTimeTracking.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked, 
															Catalogs.CalculationIndicatorsHR.TimeInDays);
	ComplianceWithTimeTracking.Insert(Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked, 
															Catalogs.CalculationIndicatorsHR.TimeInHours);
	ComplianceWithTimeTracking.Insert(Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerDay, 
															Catalogs.CalculationIndicatorsHR.TimeInDays);
	ComplianceWithTimeTracking.Insert(Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerHour, 
															Catalogs.CalculationIndicatorsHR.TimeInHours);

	Return New Structure("IndicatorsOfBaseRates,DivisorIndicators,TimeTrackingIndicators",
							ComplianceOfAccrualMethodWithBasicIndicator, DivisorMatching, ComplianceWithTimeTracking)
	
EndFunction	

// Parses the calculation formula into its component parts.
//
// Parameters:
//   CalculationFormula - String - The formula for decomposition
//
// Returns:
//   Structure - Formula Composition Parameters
Function DecomposeCalculationFormula(CalculationFormula)
	
	FormulaCompositionParameters = ParametersOfCalculationFormulaFromForm();

	If Not ValueIsFilled(CalculationFormula) Then
		Return FormulaCompositionParameters;
	EndIf;	
	
	FirstOccurrenceOfMultiply = StrFind(CalculationFormula, "*", SearchDirection.FromEnd);	
	If FirstOccurrenceOfMultiply > 0 Then
		
		PossibleNumber = Right(CalculationFormula, StrLen(CalculationFormula) - FirstOccurrenceOfMultiply);
		
		If CommonClientServer.IsNumber(PossibleNumber) Then
			FormulaCompositionParameters.ZoomRatio = Number(PossibleNumber);
			FormulaCompositionParameters.UseCoefficient = True;
		EndIf;	
		
	EndIf;

	Return FormulaCompositionParameters;

EndFunction	

// Returns a string containing mathematical symbols used in formulas.
//
// Returns:
//   String - list of mathematical symbols
Function MathematicalSymbols() Export
	SpecialChars = "+,-,/,*";
	Return SpecialChars;
EndFunction

// Extracts operands from the HR calculation text formula.
//
// Parameters:
//   Calculation_Formula - String - text formula for extracting operands
//
// Returns:
//   Array of String - list of operands extracted from the formula
Function OperandsOfTextFormula(Calculation_Formula) Export
	
	ArrayOfOperands = New Array();
	
	MathematicalSigns = MathematicalSymbols();
	
	LengthOfCalculationFormula = StrLen(TrimAll(Calculation_Formula)); 

	If LengthOfCalculationFormula = 0 Then
		Return ArrayOfOperands;
	EndIf;	
	
	WordSeparationArray = New Array();
	WordSeparationArray.Add(0);

	For Counter = 1 To LengthOfCalculationFormula Do
	Char = Mid(Calculation_Formula, Counter, 1);

		If StrFind(MathematicalSigns, Char) > 0 Then
			WordSeparationArray.Add(Counter);
		EndIf;	
	EndDo;

	WordSeparationArray.Add(LengthOfCalculationFormula+1);
	
	If WordSeparationArray.Count() > 0 Then
		
		For Counter = 1 To (WordSeparationArray.Count()-1) Do
		
			NameOfOperand = Mid(Calculation_Formula, WordSeparationArray[Counter-1]+1,
									(WordSeparationArray[Counter]- WordSeparationArray[Counter-1])-1);
			
			If Not CommonClientServer.IsNumber(NameOfOperand) Then
				ArrayOfOperands.Add(TrimAll(NameOfOperand)); 
			EndIf;	
		
		EndDo;
		
	EndIf;	
	
	Return ArrayOfOperands;
	
EndFunction	

// Performs the calculation according to the specified formula, substituting the values of the operands into it.
//
// Parameters:
//   Calculation_Formula - String - the formula for calculating
//   ArrayOfOperands - Array of String - list of operands used in the formula
//   OperandValues - Map - correspondence between operands and their values
//   ArrayOfErrorText - Array of String - errors that occurred during the calculation
//
// Returns:
//   String - Result Of Formula Calculation
Function PerformCalculationsUsingFormula(Val Calculation_Formula, ArrayOfOperands, OperandValues, ArrayOfErrorText) Export
	
	If Not ValueIsFilled(Calculation_Formula) Then
		Return 0;
	EndIf;
		
	For Each Operand In ArrayOfOperands Do
		OperandValue = OperandValues.Get(Operand);
		If Not OperandValue = Undefined Then
			Calculation_Formula = StrReplace(Calculation_Formula, Operand, Format(OperandValue, "NDS=.; NZ=0; NG=0"));
		EndIf;
	EndDo;
	
	Try
		#If Client Then
			CalculationResult = Format(Eval(Calculation_Formula),"ND=15; NFD=3; NZ=0");
		#Else
			CalculationResult = Format(Common.CalculateInSafeMode(Calculation_Formula),"ND=15; NFD=3; NZ=0");
		#EndIf
	Except
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
												NStr("ru = 'Расчетная формула %1 вызывает ошибку';
													|vi = 'The ""%1"" calculation formula causes an error';
													|en = 'The ""%1"" calculation formula causes an error'; fa = 'The ""%1"" calculation formula causes an error';
													|it = 'The ""%1"" calculation formula causes an error';
													|pl = 'The ""%1"" calculation formula causes an error';
													|tr = 'Hesaplama formülü %1 hata veriyor'"),
												Calculation_Formula);
			
		ArrayOfErrorText.Add(MessageText);
		
		Return 0;
	EndTry;
	
	Calculation = CalculationResult;
	
	Return Calculation;
	
EndFunction
#EndRegion
