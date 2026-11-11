#Region Public



#Region CheckingFormula

// Returns a template for formula validation parameters.
// 
// Returns:
// 	Structure - LongDesc:
// * CommonModuleFunctions - Array of See ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction -
// * FormulaForCalculationInQuery - Boolean - Indicates whether the function is executed as an expression of the request text.
// * Field - String - The path to the form details for which the message was output, or to the object data.
// * DataPath - String - Contains the path in the form that will display the message to the object associated with this message.
// * ErrorMessage - String - The default value is "". If the message is filled in, the specified message will be displayed if there is an error.
// * NotOutputMessages - Boolean - Flag that allows you to disable the output of error messages.
// * TypesOfOperands - Map - types of operands
//
Function FormulaValidationParameters() Export
	
	CheckParameters = New Structure;
	CheckParameters.Insert("CommonModuleFunctions", New Array);
	CheckParameters.Insert("FormulaForCalculationInQuery", False);
	CheckParameters.Insert("Field", "");
	CheckParameters.Insert("DataPath", "");
	CheckParameters.Insert("ErrorMessage", "");
	CheckParameters.Insert("NotOutputMessages", False);
	CheckParameters.Insert("TypesOfOperands", New Map);
	
	Return CheckParameters;
	
EndFunction

// Checks the formula for interactive user actions.
//
// Parameters:
//   Formula - String - text of the formula.
//   Operands - Array of String - operands of the formula.
//   ResultType - TypeDescription - the expected type of the result of the computation.
//   CheckParameters - See FormulaValidationParameters.
//
Procedure CheckFormulaInteractive(Formula, Operands, ResultType, CheckParameters = Undefined) Export
	
	If ValueIsFilled(Formula) Then
		If CheckFormula(Formula, Operands, ResultType, CheckParameters) Then
			
			ShowUserNotification(
				NStr("vi = 'Không tìm thấy lỗi trong công thức';
					|ru = 'В формуле ошибок не обнаружено';
					|en = 'No errors detected in the formula'; fa = 'No errors detected in the formula';
					|it = 'Nessun errore trovato nella formula';
					|pl = 'Nie znaleziono błędów w formule';
					|tr = 'Formülde hata bulunamadı'"),
				,
				,
				PictureLib.Information32);
			
		EndIf;
	EndIf;
	
EndProcedure

// Checks whether the formula is correct.
//
// Parameters:
//   Formula - String - text of the formula.
//   Operands - Array of String - operands of the formula.
//   ResultType - TypeDescription - the expected type of the result of the computation.
//   CheckParameters - See FormulaValidationParameters.
//
// Returns:
//  Boolean - False if there are errors, otherwise True.
//
Function CheckFormula(Formula, Operands, ResultType, Val CheckParameters = Undefined) Export
	
	Result = True;
	
	If CheckParameters = Undefined Then
		CheckParameters = FormulaValidationParameters();
	EndIf;
	
	If ValueIsFilled(Formula) Then
		
		ResultTypes = ResultType.Types();
		If ResultTypes.Count() = 1
			And ResultTypes[0] = Type("String") Then
			CalculationText = """String"" + " + Formula;
			ReplacementValue = """1""";
		ElsIf ResultTypes.Count() = 1
			And ResultTypes[0] = Type("Date") Then
			If CheckParameters.FormulaForCalculationInQuery Then
				ReplacementValue = CommonClient.SessionDate();
			Else
				ReplacementValue = "1 ";
			EndIf;
			CalculationText = Formula;
		Else
			ReplacementValue = "1 ";
			CalculationText = Formula;
		EndIf;
		
		ProcessingOfFormulasServerCall.GetCalculationText(CalculationText, Operands, ReplacementValue, CheckParameters.TypesOfOperands);
		Try
			If CheckParameters.FormulaForCalculationInQuery Then
				
				CalculationTextForRequest = StrReplace(CalculationText, "Date(1, 1, 1)", "DATETIME(1, 1, 1)");
				
				CalculationResult2 = ProcessingOfFormulasServerCall.CheckQueryFormula(
					CalculationTextForRequest,
					ReplacementValue);
				
			Else
				If CheckParameters.CommonModuleFunctions.Count() > 0 Then
					
					For Each FunctionProperties In CheckParameters.CommonModuleFunctions Do
						CalculationText = StrReplace(CalculationText, FunctionProperties.Id, FunctionProperties.FullPath);
					EndDo; 
					
				EndIf;
				
				CalculationResult2 = Eval(CalculationText);
			EndIf;
			VerificationText = StrReplace(Formula, Chars.LF, "");
			VerificationText = StrReplace(VerificationText, " ", "");
			NoSeparators = Find(VerificationText, "][")
				+ Find(VerificationText, """[")
				+ Find(VerificationText, "]""");
			If NoSeparators > 0 Then
				ReportErrorInFormula(Formula,
					CalculationText,
					NStr("vi = 'Giữa các toán hạng cần có toán tử hoặc dấu chia tách';
						|ru = 'Между операндами должен присутствовать оператор или разделитель';
						|en = 'An operator or a separator is to be between the operands'; fa = 'An operator or a separator is to be between the operands';
						|it = 'An operator or a separator is to be between the operands';
						|pl = 'An operator or a separator is to be between the operands';
						|tr = 'İşlenenlerin arasında bir operatör veya sınırlayıcı olmalıdır'"),
					CheckParameters,
					Result);
			EndIf;
			
			CalculationResultTypeIsCorrect = False;
			
			For Each ValidType_ In ResultType.Types() Do
				If TypeOf(CalculationResult2) = ValidType_ Then
					CalculationResultTypeIsCorrect = True;
					Break;
				EndIf;
			EndDo;
			
			If Not CalculationResultTypeIsCorrect Then
				ErrorReason = NStr("vi = 'Kết quả tính toán cần có kiểu %1';
									|ru = 'Результат расчета должен быть типа %1';
									|en = 'Calculation result must be of the %1 type'; fa = 'Calculation result must be of the %1 type';
									|it = 'Calculation result must be of the %1 type';
									|pl = 'Calculation result must be of the %1 type';
									|tr = 'Hesaplama sonucu %1 türünde olmalıdır'");
				ErrorReason = StrTemplate(ErrorReason, ResultType);
				
				ReportErrorInFormula(Formula,
					CalculationText,
					ErrorReason,
					CheckParameters,
					Result);
			EndIf;
		
		Except
			
			Result = False;
			
			If ValueIsFilled(CheckParameters.ErrorMessage) Then
				MessageText = CheckParameters.ErrorMessage;
			Else
				MessageText = NStr("vi = 'Đã phát hiện lỗi trong công thức. Hãy kiểm tra công thức. Cần lập công thức theo quy tắc ghi lại biểu thức bằng ngôn ngữ hệ thống 1C:Enterprise.';
									|ru = 'В формуле обнаружены ошибки. Проверьте формулу. Формулы должны составляться по правилам написания выражений на встроенном языке 1С:Предприятия.';
									|en = 'Errors are detected in the formula. Check the formula. Formulas should be created based on the expression rules of 1C:Enterprise script.'; fa = 'Errors are detected in the formula. Check the formula. Formulas should be created based on the expression rules of 1C:Enterprise script.';
									|it = 'Sono stati rilevati errori nella formula. Controllate la formula. Le formule devono essere composte secondo le regole di scrittura delle espressioni del linguaggio incorporato1C:Enterprise.';
									|pl = 'We wzorze zostały wykryte błędy. Sprawdź wzór. Wzory powinny być sporządzane zgodnie z zasadami pisowni wyrażeń na wbudowanym języku 1C:Enterprise.';
									|tr = 'Formülde hatalar bulundu. Formülü kontrol edin. Formüller, yerleşik 1C:Enterprise dilinde ifade yazma kurallarına göre hazırlanmalıdır.'");
			EndIf;
			
			ReportErrorInFormula(Formula,
				CalculationText,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()),
				CheckParameters,
				Result,
				MessageText);
		EndTry;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region ErrorOutput

Procedure ReportErrorInFormula(Formula, CalculationText, ErrorReason, CheckParameters, Result, Val MessageToUserText = "")
	
	Result = False;
	EventLogComment = StrTemplate(
		NStr("vi = 'Trong công thức: %1
			|Đã phát hiện ra lỗi:
			|%2
			|
			|Nội dung tính công thức nhận được: %3';
			|ru = 'В формуле: %1
			|Обнаружены ошибки:
			|%2
			|
			|Полученный текст расчета формулы: %3';
			|en = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3'; fa = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|it = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|pl = 'In the formula: %1
			|Errors found:
			|%2
			|
			|Received formula calculation text: %3';
			|tr = 'Formülde: %1
			| Hatalar tespit edildi:
			|%2
			|
			|Alınan formül hesabı metni: %3'"),
		Formula,
		ErrorReason,
		CalculationText);
		
	EventLogClient.AddMessageForEventLog(
		NStr("vi = 'Lỗi khi kiểm tra công thức (Khách hàng)';
			|ru = 'Ошибка при проверке формулы (Клиент)';
			|en = 'Formula check error (Client)'; fa = 'Formula check error (Client)';
			|it = 'Formula check error (Client)';
			|pl = 'Formula check error (Client)';
			|tr = 'Formül kontrolünde hata'"),
		"Warning",
		EventLogComment,
		,
		True);
		
	If CheckParameters.NotOutputMessages Then
		Return;
	EndIf;
	
	If IsBlankString(MessageToUserText) Then
		MessageToUserText = StrTemplate("In formula_1 detected_1 errors. %1", ErrorReason);
	EndIf;
	
	CommonClient.MessageToUser(
		MessageToUserText,,
		CheckParameters.Field,
		CheckParameters.DataPath);
	
EndProcedure

#EndRegion

#EndRegion
