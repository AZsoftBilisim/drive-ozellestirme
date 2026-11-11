
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Scenario = Parameters.Scenario;
	Currency = Parameters.Currency;
	
	InitializeLoadingParameters();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportCurrencyRates(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Currency) Then
		CommonClientServer.MessageToUser(
			NStr("vi = 'Hãy chỉ ra loại tiền tệ để kết nhập tỷ giá';
				|ru = 'Укажите валюту для загрузки курсов';
				|en = 'Specify a currency for importing exchange rates'; fa = 'Specify a currency for importing exchange rates';
				|it = 'Indicate la valuta per il download dei tassi di cambio';
				|pl = 'Określ walutę do pobrania kursów';
				|tr = 'Kurların indirilmeleri için para birimini belirtiniz'"), , "Currency");
		Return;
	EndIf;
	
	If ImportCurrencyRatesServer() Then
		Close();
	EndIf;
	
	Notify("DownloadedScriptCourses");
	
	Text = NStr("vi = 'Đã kết nhập tỷ giá';
				|ru = 'Загрузка курсов выполнена';
				|en = 'Rates are imported'; fa = 'Rates are imported';
				|it = 'Download dei tassi di cambio terminato';
				|pl = 'Pobranie kursów wykonano';
				|tr = 'Döviz kurlarının indirilmesi gerçekleştirildi'");
	ShowUserNotification(Text, , , PictureLib.Information32);
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure ReportConversionError(LineNumber, ColumnName, StringValue)	
	
	TextTemplate1 = NStr("vi = 'Dòng số %1 cột ""%2"" - lỗi chuyển đổi giá trị ""%3""
						|Chưa kết nhập dòng!';
						|ru = 'Строка №%1 колонка ""%2"" - ошибка преобразования значения ""%3""
						|Строка не загружена!';
						|en = 'Conversion error for value ""%3""
						| in column ""%2"" of line %1. The line is not imported.'; fa = 'Conversion error for value ""%3""
						| in column ""%2"" of line %1. The line is not imported.';
						|it = 'Riga №%1, colonna ""%2"" - errore nella trasformazione del valore ""%3""
						|Riga non caricata!';
						|pl = 'Wiersz Nr%1 kolumna ""%2"" - błąd konwersji wartości ""%3""
						| Wiersz nie jest wczytany!';
						|tr = 'Satır №%1 sütun ""%2"" - değer dönüştürme hatası ""%3""
						|Satır yüklenmedi!'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, LineNumber, ColumnName, StringValue);
	CommonClientServer.MessageToUser(Text);
	
EndProcedure

&AtServer
Function TextToDate(Val StringValue, LineNumber, ColumnName)
	
	Result = Undefined;
	
	LocalDate = Format(Date('29991211'), "DLF=D");
	StringLength = StrLen(LocalDate);
	
	Cnt = 1;
	While Cnt <= StringLength Do
		CurChar = Mid(LocalDate, Cnt, 1);
		If StringFunctionsClientServer.OnlyNumbersInString(CurChar) Then
			Cnt = Cnt + 1;
		Else
			FractionalPartSeparator = CurChar;
			Break;
		EndIf;
	EndDo;
	
	Try
		Digits = StringFunctionsClientServer.SplitStringIntoSubstringsArray(LocalDate, FractionalPartSeparator);
		IndexNumber_ = Digits.Find("11");
		IndexMonth = Digits.Find("12");
		IndexYear = Digits.Find("2999");
		
		Digits = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StringValue, FractionalPartSeparator);
		Result = ?(StrLen(Digits[IndexYear]) = 2, "20" + Digits[2], Digits[2]) 
					+ Format(Number(Digits[IndexMonth]), "ND=2; NLZ=;") 
					+ Format(Number(Digits[IndexNumber_]), "ND=2; NLZ=;");
		Result = Date(Result);
	Except
		ReportConversionError(LineNumber, ColumnName, StringValue);
	EndTry;
	
	Return Result;
	
EndFunction

&AtServer
Function TextToNumber(StringValue, LineNumber, ColumnName)
	
	If IsBlankString(StringValue) Or StringValue = Undefined Then
		Return 0;
	EndIf;
	
	Result = 0;
	
	Try
		Result = Number(StrReplace(StringValue," ",""));
	Except
		ReportConversionError(LineNumber, ColumnName, StringValue);
	EndTry;
	
	Return Result;
	
EndFunction

&AtServer
Function ImportCurrencyRatesServer()
	
	LineNumber = 2;
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	LoadingFields = ImportParameters.Fields;
	FieldNamesInLanguages = ImportParameters.FieldNamesInLanguages;
	DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Period).Text);
	UploadedWithoutErrors = True;
	
	While DateFilledIn Do
		
		RowData = Undefined;
		
		Try
			
			RowData = New Structure("Scenario, Currency", Scenario, Currency);
			
			For Each Field In LoadingFields Do
				
				ValueText = SpreadsheetDocument.Area("R" + StringNumber + Field.Value).Text;
				If Field.Key = "Period" Then
					Simple = TextToDate(ValueText, StringNumber, FieldNamesInLanguages[Field.Key]);
				Else
					Simple = TextToNumber(ValueText, StringNumber, FieldNamesInLanguages[Field.Key]);
				EndIf;
				RowData.Insert(Field.Key,Simple);
				
			EndDo;
			
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
			UploadedWithoutErrors = False;
		EndTry;
		
		If ValueIsFilled(RowData) Then
			
			// let's check everything we've read
			AllFieldsAreFilledInCorrectly = True;
			
			If Not ValueIsFilled(RowData.Period) Then
				AllFieldsAreFilledInCorrectly = False;
				ErrorMessage = NStr("vi = 'Chưa điền kỳ trong dòng %1. Chưa kết nhập dòng.';
									|ru = 'В строке %1 не заполнен период. Строка не загружена.';
									|en = 'Period in line %1 is not filled in. The line is not imported.'; fa = 'Period in line %1 is not filled in. The line is not imported.';
									|it = 'Nella riga %1 non è compilato il periodo. Riga non caricata.';
									|pl = 'W wierszu %1 nie jest wypełnionym okres. Wiersz nie jest wczytany.';
									|tr = '%1 satırında doldurulan herhangi bir dönem mevcut değil. Satır indirilmedi.'");
				CommonClientServer.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber));
			EndIf;
			
			For Each Field In ImportParameters.ControlFields Do
				
				ErrorMessage = "";
				
				If RowData[Field] < 0 Then
					ErrorMessage = NStr("vi = 'Dòng %1 trong cột %2 là âm. Chưa kết nhập dòng.';
										|ru = 'В строке %1 в колонке %2 отрицательное значение. Строка не загружена.';
										|en = 'There is a negative value in line %1 of column %2. The line is not imported.'; fa = 'There is a negative value in line %1 of column %2. The line is not imported.';
										|it = 'Nella riga %1, colonna %2 vi è un valore negativo. Riga non caricata.';
										|pl = 'W wierszu %1 kolumnie %2 jest wartość ujemną. Wiersz nie jest wczytany.';
										|tr = '%2 sütunundaki %1 satırında negatif değer mevcut. Satır indirilmedi.'");
				ElsIf RowData[Field] = 0 Then
					ErrorMessage = NStr("vi = 'Chưa điền giá trị trong dòng %1 trong cột %2. Chưa kết nhập dòng.';
										|ru = 'В строке %1 в колонке %2 значение не заполнено. Строка не загружена.';
										|en = 'Column %2 in line %1 is not filled in. The line is not imported.'; fa = 'Column %2 in line %1 is not filled in. The line is not imported.';
										|it = 'Nella riga %1, colonna %2 il valore non è compilato. Riga non caricata.';
										|pl = 'W wierszu %1 kolumnie %2 wartość nie jest wypełniona. Wiersz nie jest wczytany.';
										|tr = '%2 sütunundaki %1 satırında değer doldurulmamış. Satır indirilmedi.'");
				EndIf;
				
				If ValueIsFilled(ErrorMessage) Then
					AllFieldsAreFilledInCorrectly = False;
					CommonClientServer.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber, FieldNamesInLanguages[Field]));
					UploadedWithoutErrors = False;
				EndIf;
				
			EndDo;
			
			If AllFieldsAreFilledInCorrectly Then
				Record = InformationRegisters.ForecastedExchangeRatesOfScenarios.CreateRecordManager();
				FillPropertyValues(Record, RowData);
				Record.Write(True);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Period).Text);
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
			UploadedWithoutErrors = False;
		EndTry;
		
	EndDo;
	
	Return UploadedWithoutErrors;
	
EndFunction

&AtServer
Procedure InitializeLoadingParameters()
	
	ImportParameters = New Structure;
	
	LoadingFields = New Structure();
	LoadingFields.Insert("Period", "C1");
	LoadingFields.Insert("CourseNumerator", "C2");
	LoadingFields.Insert("CourseDenominator","C3");
	
	ImportParameters.Insert("Fields", LoadingFields);
	
	FieldArray = New Array;
	FieldArray.Add("CourseNumerator");
	FieldArray.Add("CourseDenominator");
	
	ImportParameters.Insert("ControlFields", FieldArray);
	
	FieldNamesInLanguages = New Structure();
	FieldNamesInLanguages.Insert("Period", NStr("vi = 'Kỳ';
												|ru = 'Период';
												|en = 'Period'; fa = 'دوره';
												|it = 'Periodo';
												|pl = 'Period';
												|tr = 'Dönem'"));
	FieldNamesInLanguages.Insert("CourseNumerator", NStr("vi = 'Tỷ giá tử số';
														|ru = 'Курс числитель';
														|en = 'Rate numerator'; fa = 'صورت نرخ';
														|it = 'Tasso di cambio del nominatore';
														|pl = 'Kurs licznik';
														|tr = 'Kur payı'"));
	FieldNamesInLanguages.Insert("CourseDenominator", NStr("vi = 'Tỷ giá mẫu số';
															|ru = 'Курс знаменатель';
															|en = 'Rate denominator'; fa = 'مخرج نرخ';
															|it = 'Tasso di cambio del denominatore';
															|pl = 'Kurs mianownik';
															|tr = 'Kur paydası'"));
	
	ImportParameters.Insert("FieldNamesInLanguages", FieldNamesInLanguages);
	
	TemplateTemplate = InformationRegisters.ForecastedExchangeRatesOfScenarios.GetTemplate("RateImportTemplate");
	SpreadsheetDocument.Clear();
	ColumnArea = TemplateTemplate.GetArea("Currency_Rates");
	SpreadsheetDocument.Join(ColumnArea);
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

#EndRegion

#EndRegion
