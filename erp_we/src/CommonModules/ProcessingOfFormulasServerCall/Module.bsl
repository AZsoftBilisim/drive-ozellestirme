#Region Public

// Function parameter value by name.
//
// Parameters:
// 	CalculationText - String - calculated formula
// 	ReplacementValue - Arbitrary - the parameter for which the formula will be calculated
//
// Returns:
// 	Arbitrary
//
Function CheckQueryFormula(CalculationText, ReplacementValue) Export
	
	Query = New Query();
	Query.SetParameter("Parameter", ReplacementValue);
	
	//@skip-check bsl-ql-hub
	Query.Text = StrReplace(
		"SELECT TField_emplate FROM TemplateTable_",
		"TField_emplate FROM TemplateTable_",
		StrReplace(CalculationText, String(ReplacementValue), "&Parameter"));
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.Get(0);
	
EndFunction

// Gets the calculation text.
//
// Parameters:
// 	CalculationText - String - calculated formula
// 	Operands - Array of String - an array of operands
// 	ReplacementValue - Arbitrary - the parameter for which the formula will be calculated
// 	TypesOfOperands - Map of String - types of operands
//
Procedure GetCalculationText(CalculationText, Operands, ReplacementValue, TypesOfOperands = Undefined) Export
	
	TypesOfOperands = ?(TypesOfOperands = Undefined, New Map, TypesOfOperands);
	
	For Each Operand In Operands Do
		
		ValueForSubstitution = Undefined;
		
		OperandType_ = TypesOfOperands.Get(Operand);
		If ValueIsFilled(OperandType_) Then
			
			If OperandType_.ContainsType(Type("Date")) Then
				
				ValueForSubstitution = "Date(1, 1, 1)";
				
			ElsIf OperandType_.ContainsType(Type("Number")) Then
				
				RandomNumberGenerator = New RandomNumberGenerator();
				ValueForSubstitution = Format(RandomNumberGenerator.RandomNumber(1, 1000), "NG=")
				
			ElsIf OperandType_.ContainsType(Type("Boolean")) Then
				
				ValueForSubstitution = "False";
				
			ElsIf OperandType_.ContainsType(Type("String")) Then
				
				ValueForSubstitution = """1""";
				
			Else
				
				TypeDescription = New TypeDescription(OperandType_);
				ValueForSubstitution = String(TypeDescription.AdjustValue(1));
				
			EndIf;
			
		EndIf;
		
		If Not ValueIsFilled(ValueForSubstitution) Then
			ValueForSubstitution = ReplacementValue;
		EndIf;
		
		CalculationText = StrReplace(
			CalculationText,
			ProcessingOfFormulasClientServer.GetOperandTextToInsert(Operand),
			ValueForSubstitution);
		
	EndDo;
	
EndProcedure

#EndRegion