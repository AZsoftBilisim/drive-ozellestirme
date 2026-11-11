#Region Public

// Constructor function for the parameter of the Information centerclient procedure.Open the form of the Online message of the support servicesupport
// 
// Returns: 
//  Structure - With Fields:
//   * Subject - String - Subject of the Appeal
//   * Text - String - Request Text
//   * Use_StandardTemplate - Boolean - If True, the text of the request will be filled in using the template 
//                                              from the Information Centerserver method.Template Textstavteh Support
//   * Attachments - Array of Structure - array of addition of structures with fields:
//    ** FileName - String - the file name is an attachment with an extension, for example "file.txt "
//    ** AddressInTempStorage - String - the address of the attachment file in the temporary storage
//   * CompletionHandler - CallbackDescription - description of the notification about closing the new request Form
//   * AdditionalData - Structure - any data structure that can be sent to the support service.
//                                        This structure should be serializable in JSON.
//   * UseSupportRequestCreationWizard - Boolean - If True, and if available in the Support Service Management 
//   												  , the Wizard for creating a request will be used
//   * WizardData - Structure - data to be Transferred to the Request Creation Wizard (structure values - primitive types - String, Number, Boolean, Date)
//
//@skip-check doc-comment-field-type-strict
Function NewParametersForContactingSupportService() Export
	
	Result = New Structure;
	Result.Insert("Subject");
	Result.Insert("Text");
	Result.Insert("Use_StandardTemplate", True);
	Result.Insert("Attachments");
	Result.Insert("CompletionHandler");
	Result.Insert("AdditionalData");
	Result.Insert("UseSupportRequestCreationWizard", False);
	Result.Insert("WizardKeyFields", New Structure);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

#Region UserCodeEncryption_ServiceProgrammingInterface
// The methods of the encryption area of the user_service_program interface are borrowed 
// from the integration subsystem with the document flow from the enterprise management configuration (1C:ERP)

// Divides the user's code into two independent parts for subsequent recovery by the function of a fellow user.
//
// Parameters:
//   UserCode - String - shared user code.
//
// Returns:
//   Array of String - an array of two strings containing a hexadecimal Presentation of the user's code.
//
Function SplitUserCode(UserCode) Export
	
	Result = New Array;
	Result.Add("");
	Result.Add("");
	Generator = Undefined;
	
	// Decompose the code into an array of numbers in pairs.
	ArrayOfNumbers = New Array;
	IndexOf = 1;
	While IndexOf <= StrLen(UserCode) Do
		Number = CharCode(UserCode, IndexOf);
		IndexOf = IndexOf + 1;
		If IndexOf <= StrLen(UserCode) Then
			Number = Number * 65536 + CharCode(UserCode, IndexOf);
			IndexOf = IndexOf + 1;
		EndIf;
		ArrayOfNumbers.Add(Number);
	EndDo;
	
	// Divide each of the resulting numbers.
	For Each Number In ArrayOfNumbers Do
		SplitNumber = DivideNumber(Number, Generator); // ((1, NNN), (2, MMM))
		Result[0] = Result[0] + NumberHexadecimalPresentation(SplitNumber[0][1], 8);
		Result[1] = Result[1] + NumberHexadecimalPresentation(SplitNumber[1][1], 8);
	EndDo;
	
	Return Result;
	
EndFunction

// Collects the user code from two parts previously separated by the Split User Code function.
// In case of string corruption, returns Undefined.
//
// Parameters:
//   SplitCode - Array - two lines containing the separated user code.
//
// Returns:
//   String - the collected user code or
//   Undefined - if the lines are corrupted.
//
Function CollectUserCode(Val SplitCode) Export
	
	If SplitCode.Count() <> 2 Then
		Return Undefined;
	EndIf;
	SplitCode[0] = TrimAll(SplitCode[0]);
	SplitCode[1] = TrimAll(SplitCode[1]);
	If StrLen(SplitCode[0]) <> StrLen(SplitCode[1]) Then
		Return Undefined;
	EndIf;
	If StrLen(SplitCode[0]) % 8 <> 0 Then
		Return Undefined;
	EndIf;
	Result = "";
	Numbers_ = Int(StrLen(SplitCode[0])) / 8;
	For NNumbers = 1 To Numbers_ Do
		SplitNumber = New Array;
		For NParts = 0 To 1 Do
			Pair = New Array;
			Pair.Add(NParts + 1);
			Presentation = Mid(SplitCode[NParts], 1 + (NNumbers - 1) * 8, 8);
			Pair.Add(NumberFromHexadecimalPresentation(Presentation));
			SplitNumber.Add(Pair);
		EndDo;
		CollectedNumber = CollectNumber(SplitNumber);
		If CollectedNumber >= 65536 Then
			Result = Result + Char(Int(CollectedNumber / 65536));
		EndIf;
		Result = Result + Char(CollectedNumber % 65536);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region UserCodeEncryption_ServiceProceduresAndFunctions
// The methods of the encryption area of the user_service_procedurefunctions are borrowed 
// from the integration subsystem with the document flow from the enterprise management configuration (1C:ERP)

// Returns the hexadecimal Presentation of a number.
//
// Parameters:
//   Number - Number - integer.
//   Discharges - Number - the minimum width of the result.
//            - Undefined - do not add zeros.
//
// Returns:
//   String - Hexadecimal Presentation of a number, possibly
//   padded with zeros up to the specified number of digits.
//
Function NumberHexadecimalPresentation(Val Number, Discharges = Undefined)
	
	If Number = 0 And Discharges = Undefined Then
		Return "0";
	EndIf;
	
	Result = "";
	NDischarge = 0;
	While True Do
		NDischarge = NDischarge + 1;
		If Number = 0 Then // it may be necessary to add up to the specified number of digits
			If Discharges = Undefined Then
				Break;
			ElsIf NDischarge > Discharges Then
				Break;
			EndIf;
		EndIf;
		RightDischarge = Number % 16;
		Number = Int(Number / 16);
		If RightDischarge > 9 Then
			Result = Char(CharCode("A") + RightDischarge - 10) + Result;
		Else
			Result = Char(CharCode("0") + RightDischarge) + Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Collects a number divided by Shamir's algorithm into parts by the Divide Number function.
//
// Parameters:
//   SplitNumber - Array - array of pairs of numbers of the form (1, 123), (2, 234), ...
//
// Returns:
//   Number - original number.
//
Function CollectNumber(SplitNumber)
	
	Result = 0;
	Module = ModulusOfResidueRing();
	For String = 0 To SplitNumber.Count() - 1 Do
		Numerator = 1; 
		Divisor = 1;
		For Column = 0 To SplitNumber.Count() - 1 Do
			If String = Column Then
				Continue;
			EndIf;
			dated = SplitNumber[String][0];
			Before  = SplitNumber[Column][0];
			Numerator = (Numerator * -Before) % Module;
			Divisor = (Divisor * (dated - Before)) % Module;
		EndDo;
		Value = SplitNumber[String][1];
		Result = (Module + Result + (Value * Numerator * ReverseModule(Divisor))) % Module;
	EndDo;
	
	Return Result;
	
EndFunction

// Calculates the inverse module.
//
// Parameters:
//   NumberK - Number
//
// Returns:
//   Number - such that (Numerok * Inverse module(numerok)) % Modulus = 1 for all 
//   positive numbers < The module.
//
Function ReverseModule(Val NumberK)
	
	Module = ModulusOfResidueRing();
	NumberK = NumberK % Module;
	
	If NumberK < 0 Then
		Decomposition = DecomposeNode(Module, -NumberK);
		Factorization = -Decomposition[2];
	Else
		Decomposition = DecomposeNode(Module, NumberK);
		Factorization = Decomposition[2];
	EndIf;
	
	Return (Module + Factorization) % Module;
	
EndFunction

// Performs the decomposition of the largest common divisor of a pair of numbers A and B.
//
// Parameters:
//   NumberA - Number
//   NumberB - Number
//
// Returns:
//   Array - (X, Y, Z), such that:
//     X is the greatest common divisor of NumerA and NumerA;
//     X = Numeral A * Y + Numeral * Z.
//
Function DecomposeNode(Val NumberA, Val NumberB)
	
	Result = New Array;
	
	If NumberB = 0 Then
		Result.Add(NumberA);
		Result.Add(1);
		Result.Add(0);
	Else
		Quotient = Int(NumberA / NumberB);
		Module = NumberA % NumberB;
		Decomposition = DecomposeNode(NumberB, Module);
		Result.Add(Decomposition[0]);
		Result.Add(Decomposition[2]);
		Result.Add(Decomposition[1] - Decomposition[2] * Quotient);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a large prime number used as a module of the residue class ring.
// Must be greater than any of the encoded numbers.
//
Function ModulusOfResidueRing()
	Return 4294967291; // more than any of the possible combinations of two password characters.
EndFunction

// Gets a number from its hexadecimal representation. May cause an exception.
//
// Parameters:
//   Presentation - String - hexadecimal number.
//
// Returns:
//   Number - the converted number.
//
Function NumberFromHexadecimalPresentation(Val Presentation)
	
	If Presentation = "" Then
		Return 0;
	EndIf;
	Presentation = Upper(Presentation);
	
	Result = 0;
	While Presentation <> "" Do
		Digit = Left(Presentation, 1);
		Presentation = Mid(Presentation, 2);
		If Digit >= "0" And Digit <= "9" Then
			Result = Result * 16 + CharCode(Digit, 1) - CharCode("0");
		ElsIf Digit >= "A" And Digit <= "F" Then
			Result = Result * 16 + 10 + CharCode(Digit, 1) - CharCode("A");
		Else
			Raise NStr("vi = 'Ký tự lỗi trong chuỗi thập lục phân.';
						|ru = 'Ошибочный символ в шестнадцатеричной строке.';
						|en = 'Invalid character in a hexadecimal string.'; fa = 'Invalid character in a hexadecimal string.';
						|it = 'Ошибочный символ в шестнадцатеричной строке.';
						|pl = 'Błędny symbol w wierszu szesnastkowym.';
						|tr = 'Onaltılı satırda geçersiz karakter.'");
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Divides the secret number into the specified number of parts according to Shamir's algorithm.
//
// Parameters:
//   Number - Number - a separable number, from 0 to 2^32 - 1.
//   Generator - RandomNumberGenerator - a random number generator, it is advisable to save it between calls.
//   Parts_ - Number - the number of parts into which the number is divided.
//   Mandatory - Number - the number of parts required for restoration.
//
// Returns:
//   Array - array of pairs of numbers of the form (1, 123), (2, 234), (3, 345), necessary for recovery.
//
Function DivideNumber(Number, Generator = Undefined, Parts_ = 2, Mandatory = 2)
	
	#If Not WebClient Then
		
	If Generator = Undefined Then
		Generator = New RandomNumberGenerator(CurrentDate() - Date(1, 1, 1)); // The use is justified: RNG.
	EndIf;
	Module = ModulusOfResidueRing();
	
	While True Do
		Result = New Array;
		Coefficients = New Array;
		Coefficients.Add(Number);
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		For Term = 1 To Parts_ Do
			Value = Number;
			For Power = 1 To Mandatory - 1 Do
				Value = (
					Value + (Coefficients[Power] * (Pow(Term, Power) % Module)) % Module
				) % Module;
			EndDo;
			Pair = New Array;
			Pair.Add(Term);
			Pair.Add(Value);
			Result.Add(Pair);
		EndDo;
		If CollectNumber(Result) = Number Then
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
	#Else
		
	Raise NStr("vi = 'Chức năng không được hỗ trợ trong web-client.';
				|ru = 'Функция не поддерживается в веб-клиенте.';
				|en = 'Function is not supported in web client.'; fa = 'Function is not supported in web client.';
				|it = 'La funzione non è supportata nel client web.';
				|pl = 'Funkcja nie jest obsługiwana w kliencie webowym.';
				|tr = 'Bu fonksiyon, web istemcisinde desteklenmiyor.'")
	
	#EndIf
	
EndFunction

#EndRegion

#EndRegion
