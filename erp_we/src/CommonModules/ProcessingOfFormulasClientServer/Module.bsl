
#Region Public

#Region FormulaAndOperandParsing

// Calculates the ID value from a string according to the variable naming rules.
// 
// Parameters:
//  RwName - String - name of the string to get the ID from. 
//
// Returns:
//  String - An identifier that conforms to the rules for naming identifiers.
//
Function IDForFormulas(RwName) Export
	
	Id = RwName;
	
	Digits = New Array();
	For Cnt = 0 To 9 Do
		Digits.Add(String(Cnt));
	EndDo;
	
	FirstCharacterIsNotDigit = False;
	
	Id = GetID(Id);
	
	If Not IsBlankString(Id) Then
		While Not FirstCharacterIsNotDigit Do
			If Digits.Find(Mid(Id, 1, 1)) = Undefined Then
				FirstCharacterIsNotDigit = True;
			EndIf;
			If FirstCharacterIsNotDigit Then
				Break;
			Else
				Id = Mid(Id, 2);
			EndIf;
		EndDo;
	EndIf;
	
	Return Id;
	
EndFunction

// Gets the text of the operand to insert into the formula.
//
// Parameters:
//  Operand - String - name of the operand.
//
// Returns:
//  String - The text of the operand to insert.
//
Function GetOperandTextToInsert(Operand) Export
	
	Return "[" + Operand + "]";
	
EndFunction // Get the text of the command to add()

// Retrieves the operands from the text of the formula
//
// Parameters:
//  Formula - String - text of the formula.
//  OnlyUniqueOnes - Boolean - If True, only unique operands are placed in the returned array.
//
// Returns:
//  Array - Operands from a text formula (without external brackets, for example, "Nomenclature.{DR.Forwarder}").
//
Function OperandsOfTextFormula(Formula, OnlyUniqueOnes = False) Export
	
	ArrayOfOperands = New Array;
	
	OperandStartTag = "[";
	OperandEndTag = "]";
	
	RestOfFormula = Formula;
	
	StartOfOperand = StrFind(RestOfFormula, OperandStartTag);
	While StartOfOperand > 0 Do
		EndOfOperand = PositionOfOperandEndClosingTag(RestOfFormula, OperandStartTag, OperandEndTag);
		Operand = Mid(RestOfFormula, StartOfOperand, (EndOfOperand - StartOfOperand + 1));
		OperandWithoutOuterBrackets = Mid(Operand, 2, StrLen(Operand) - 2);
		If OnlyUniqueOnes Then
			If ArrayOfOperands.Find(OperandWithoutOuterBrackets) = Undefined Then
				ArrayOfOperands.Add(OperandWithoutOuterBrackets);
			EndIf;
		Else
			ArrayOfOperands.Add(OperandWithoutOuterBrackets);
		EndIf;
		
		RestOfFormula = Mid(RestOfFormula, EndOfOperand + 1);
		StartOfOperand = StrFind(RestOfFormula, OperandStartTag);
	EndDo;
	
	
	Return ArrayOfOperands;
	
EndFunction

// Returns an array of operand parts. For example, the operand
// 			" stringable Part[0].Requisito.{Characteristic of the request}.Requestcachepolicy"
// should be divided into parts:
// 			"Stroitelnoye[0]", "Requisito", "{Of Characteristicsit}", "Requestparameters".
// 
// Parameters:
// 	Operand - String - The operand of the formula.
// 	PresentationsOfCharacteristics - Boolean - Flag indicating that expressions are parsed with representations of characteristics,
// 				not identifiers.
// 	RemoveOuterBrackets - Boolean - If True, then if the operand is enclosed in outer [] brackets, they will be removed.
// 				Basically, if the operand is enclosed in outer square brackets, this is a restriction of the operand itself,
// 				as, for example, in formulas of types of items. However, if a part of the operand is parsed, the
// 				outer square brackets are a characteristic feature and should not be removed.
// 				For example, in the method "performing checks and converting Expressions", a path
// 				of the type " Account.Subconto1.[Performance characteristics]". Then the "Invoice.Subconto1 " is
// 				the first part of the expression, and "[feature Representation]" is the second part.
// Returns:
// 	Array of String - Parts of the operand.
//
Function OperandParts(Operand, PresentationsOfCharacteristics = False, RemoveOuterBrackets = True) Export
	Result = New Array;
	
	ParsedText = Operand;
	
	OperandStartTag = "[";
	OperandEndTag = "]";
	
	FeatureStartTag = "{";
	EndTagCharacteristics = "}";
	If PresentationsOfCharacteristics Then
		FeatureStartTag = "[";
		EndTagCharacteristics = "]";
	EndIf;
	
	If RemoveOuterBrackets Then
		// If the operand is enclosed in outer brackets [], they must be removed.
		If Left(ParsedText, 1) = OperandStartTag
			And Right(ParsedText, 1) = OperandEndTag Then
			ParsedText = Mid(ParsedText, 2, StrLen(ParsedText) - 2);
		EndIf;
	EndIf;
	
	// Inside the characteristic, the prefix of the characteristic type is indicated through a dot.
	// Therefore, the tags of characteristics are first searched for, outside of these tags, the parts of the operand are separated by a dot.
	OperandPartSeparator = ".";
	
	StartOfFeaturePosition = StrFind(ParsedText, FeatureStartTag);
	While StartOfFeaturePosition > 0 Do
		EndOfFeaturePosition = PositionOfOperandEndClosingTag(ParsedText,
			FeatureStartTag, EndTagCharacteristics);
		
		If StartOfFeaturePosition = 1 Then
			TextBeforeCharacteristic = "";
		Else
			TextBeforeCharacteristic = Mid(ParsedText, 1, StartOfFeaturePosition - 1);
		EndIf;
		If Not IsBlankString(TextBeforeCharacteristic) Then
			Parts = StrSplit(TextBeforeCharacteristic, OperandPartSeparator, False);
			For Each Term In Parts Do
				Result.Add(Term);
			EndDo;
		EndIf;
		PartOfCharacteristic = Mid(ParsedText,
			StartOfFeaturePosition,
			EndOfFeaturePosition - StartOfFeaturePosition + 1);
		Result.Add(PartOfCharacteristic);
		
		ParsedText = Mid(ParsedText, EndOfFeaturePosition + 1);
		StartOfFeaturePosition = StrFind(ParsedText, FeatureStartTag);
	EndDo;
	If Not IsBlankString(ParsedText) Then
		Parts = StrSplit(ParsedText, OperandPartSeparator, False);
		For Each Term In Parts Do
			Result.Add(Term);
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

Function SpecialChars() Export
	SpecialChars = " .,+,-,/,*,?,=,<,>,(,)%!@#$%&*""№:;{}[]?()\|/`~'^_";
	Return SpecialChars;
EndFunction

#EndRegion

#Region CommonModuleFunctions

// Returns an empty array of function description structures that can be called when the formula is executed.
// 
// Returns:
// 	Array of See DescriptionOfCommonModuleFunction
//
Function CommonModuleFunctions() Export
	Result = New Array;
	
	Return Result;
EndFunction

// Returns the structure of the function description that can be called when executing the formula.
// 
// Returns:
// 	Structure - description of an additional function used in the formula constructor and when executing the formula, with properties:
// 	 *Id - String - Required field. ID of the function in the code language. For Example, "Calculating The Algorithm".
// 	 *FullPath - String - Required field. Includes the name of the shared module and the name of the function.
// 	 		For Example, " Complex Calculations.Calculating the algorithm".
// 	 *Presentation - String - Required field. Representation of the function display in the user's language.
// 	 		For example, "calculation by algorithm".
// 	 *StructureToInsert - String - Required field. Text to insert in the formula constructor.
// 	 		Contains the function ID in the code language.
// 			It can also contain commas, as well as hints for the user in the user's language.
// 			For example, " calculating the algorithm (<function Parameter 1>, <function Parameter 2>)".
// 			In the example given, the parameters are described "<The function parameter 1> " can be placed in the NSTR for display
// 			to the user.
// 	 *Explanation - String - Optional parameter. Explanation displayed in the formula constructor when positioning
// 	 		on the function line. In the user's language.
//
Function DescriptionOfCommonModuleFunction() Export
	FunctionDescription_ = New Structure;
	// Required parameters.
	FunctionDescription_.Insert("Id", "");
	FunctionDescription_.Insert("FullPath", "");
	FunctionDescription_.Insert("Presentation", "");
	FunctionDescription_.Insert("StructureToInsert", "");
	
	// Optional parameters.
	FunctionDescription_.Insert("Explanation", "");
	
	Return FunctionDescription_;
EndFunction

#EndRegion

#EndRegion

#Region Private

// Calculates the ID value from a string according to
// the ID naming rules.
// 
// Parameters:
// 	PresentationRow - String - View, the string to get the ID from.
//
// Returns:
// 	String - An identifier that conforms to the rules for naming identifiers.
//
Function GetID(PresentationRow)
	
	SpecialChars = SpecialChars();
	Digits = "0123456789";
	
	Id = "";
	HadSpecialChar = False;
	ThereWereSignificantCharactersNotNumbers = False;
	
	For CharNum = 1 To StrLen(PresentationRow) Do
		
		Char = Mid(PresentationRow, CharNum, 1);
		
		If StrFind(SpecialChars, Char) <> 0 Then
			HadSpecialChar = True;
			If Char = "_" Then
				Id = Id + Char;
				ThereWereSignificantCharactersNotNumbers = True;
			EndIf;
		ElsIf Not ThereWereSignificantCharactersNotNumbers
			And StrFind(Digits, Char) <> 0 Then
			HadSpecialChar = True;
			Id = Id + Char;
		ElsIf HadSpecialChar
			Or CharNum = 1 Then
			HadSpecialChar = False;
			Id = Id + Upper(Char);
			ThereWereSignificantCharactersNotNumbers = True;
		Else
			Id = Id + Char;
			ThereWereSignificantCharactersNotNumbers = True;
		EndIf;
		
	EndDo;
	
	Return Id;
	
EndFunction

Function PositionOfOperandEndClosingTag(RestOfFormula, OperandStartTag, OperandEndTag)
	
	TagWithNestedTags = 0;
	Position = StrFind(RestOfFormula, OperandStartTag,, 1);
	
	NextClosingPosition = 0;
	TagWithNestedTags = TagWithNestedTags + 1;
	While Not TagWithNestedTags = 0 Do
		// For example, an operand that includes the index of a table part row.
		NextOpeningPosition = StrFind(RestOfFormula, OperandStartTag,, Position + 1);
		NextClosingPosition = StrFind(RestOfFormula, OperandEndTag,, Position + 1);
		
		If NextOpeningPosition <> 0
			And (NextOpeningPosition < NextClosingPosition) Then
			Position = NextOpeningPosition;
			TagWithNestedTags = TagWithNestedTags + 1;
		Else
			Position = NextClosingPosition;
			TagWithNestedTags = TagWithNestedTags - 1;
		EndIf;
		If Position = 0 Then
			ErrorText = NStr("vi = 'Lỗi khi phân tích cú pháp nội dung công thức: không tìm thấy thẻ đóng toán hạng';
							|ru = 'Ошибка при разборе текста формулы: не найден тег закрытия операнда';
							|en = 'Error parsing formula text: operand close tag not found'; fa = 'Error parsing formula text: operand close tag not found';
							|it = 'Errore durante l''analisi del testo della formula: non è stato trovato il tag di chiusura dell''operando';
							|pl = 'Błąd podczas analizy tekstu formuły: nie znaleziono tagu zamknięcia operandu';
							|tr = 'Formül metni ayrıştırılırken hata oluştu: İşlenen kapanış etiketi bulunamadı'");
			Raise ErrorText;
		EndIf;
	EndDo;
	
	Return Position;
	
EndFunction

#EndRegion

