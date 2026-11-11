

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeLoadingParameters();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportCurrencyRates(Command)
	
	If ImportCurrencyRatesServer() Then
		Close();
	EndIf;
	
	Notify("Record_LoadRelativeExchangeRates");
	
	Text = NStr("vi = 'Đã thực hiện kết nhập tỷ giá tương ứng';
				|ru = 'Загрузка относительных курсов выполнена';
				|en = 'Relative exchange rates are imported'; fa = 'Relative exchange rates are imported';
				|it = 'Download dei tassi di cambio relativi eseguito';
				|pl = 'Pobieranie względnych kursów zostało wykonane';
				|tr = 'Göreli döviz kurlarının yüklenmesi gerçekleştirildi'");
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
						|Chưa kết nhập dòng';
						|ru = 'Строка №%1 колонка ""%2"" - ошибка преобразования значения ""%3""
						|Строка не загружена';
						|en = 'Conversion error for value ""%3""
						| in column ""%2"" of line %1. The line is not imported'; fa = 'Conversion error for value ""%3""
						| in column ""%2"" of line %1. The line is not imported';
						|it = 'Riga №%1, colonna ""%2"" - errore nella trasformazione del valore ""%3""
						|Riga non caricata';
						|pl = 'Wiersz Nr%1 kolumna ""%2"" - błąd konwersji wartości ""%3""
						| Wiersz nie jest wczytany';
						|tr = '%1Satır numarası ""%2""sütunu değeri dönüştürülürken hata ""%3
						|"" Satır yüklenmedi'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, LineNumber, ColumnName, StringValue);
	Common.MessageToUser(Text);
	
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
Function TextToCurrency(Val StringValue, LineNumber, ColumnName)
	
	Result = Catalogs.Currencies.FindByDescription(TrimAll(StringValue), True);
	
	If Not ValueIsFilled(Result) Then 
	    ReportConversionError(LineNumber, ColumnName, StringValue);
	EndIf;
	
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
			
			RowData = New Structure;
			
			For Each Field In LoadingFields Do
				
				ValueText = SpreadsheetDocument.Area("R" + StringNumber + Field.Value).Text;
				If Field.Key = "Period" Then
					Simple = TextToDate(ValueText, StringNumber, FieldNamesInLanguages[Field.Key]);
				ElsIf Field.Key = "Currency" Or Field.Key = "BaseCurrency" Then
					Simple = TextToCurrency(ValueText, StringNumber, FieldNamesInLanguages[Field.Key]);
				Else
					Simple = TextToNumber(ValueText, StringNumber, FieldNamesInLanguages[Field.Key]);
				EndIf;
				RowData.Insert(Field.Key,Simple);
				
			EndDo;
			
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
			UploadedWithoutErrors = False;
		EndTry;
		
		If ValueIsFilled(RowData) Then
			
			// let's check everything we've read
			AllFieldsAreFilledInCorrectly = True;
			
			If Not ValueIsFilled(RowData.Period) Then
				AllFieldsAreFilledInCorrectly = False;
				ErrorMessage = NStr("vi = 'Trong dòng %1 chưa điền kỳ. Chưa kết nhập dòng.';
									|ru = 'В строке %1 не заполнен период. Строка не загружена.';
									|en = 'Period in line %1 is not filled in. The line is not imported.'; fa = 'Period in line %1 is not filled in. The line is not imported.';
									|it = 'Nella riga %1 non è compilato il periodo. Riga non caricata.';
									|pl = 'W wierszu %1 nie jest wypełnionym okres. Wiersz nie jest wczytany.';
									|tr = '%1 satırında doldurulan herhangi bir dönem mevcut değil. Satır indirilmedi.'");
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber));
			EndIf;
			
			If Not ValueIsFilled(RowData.Currency) Then
				AllFieldsAreFilledInCorrectly = False;
				ErrorMessage = NStr("vi = 'Trong dòng %1 chưa điền kỳ. Chưa kết nhập dòng.';
									|ru = 'В строке %1 не заполнена валюта. Строка не загружена.';
									|en = 'Currency in line %1 is not filled in. The line is not imported.'; fa = 'Currency in line %1 is not filled in. The line is not imported.';
									|it = 'Nella riga %1 non è compilata la valuta. La riga non è stata scaricata.';
									|pl = 'W wierszu %1 nie wypełniono waluty. Wiersz nie został pobrany.';
									|tr = '%1 satırında para birimi doldurulmadı. Satır yüklenmedi.'");
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber));
			EndIf;
			
			If Not ValueIsFilled(RowData.BaseCurrency) Then
				AllFieldsAreFilledInCorrectly = False;
				ErrorMessage = NStr("vi = 'Trong dòng %1 chưa điền tiền tệ cơ sở. Chưa kết nhập dòng.';
									|ru = 'В строке %1 не заполнена базовая валюта. Строка не загружена.';
									|en = 'Base currency in line %1 is not filled in. The line is not imported.'; fa = 'Base currency in line %1 is not filled in. The line is not imported.';
									|it = 'Nella riga %1 non è compilata la valuta di riferimento. La riga non è stata scaricata.';
									|pl = 'W wierszu %1 nie wypełniono podstawowej waluty. Wiersz nie został pobrany.';
									|tr = '%1 satırında temel para birimi doldurulmadı. Satır yüklenmedi.'");
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber));
			EndIf;
			
			For Each Field In ImportParameters.ControlFields Do
				
				ErrorMessage = "";
				
				If RowData[Field] < 0 Then
					ErrorMessage = NStr("vi = 'Trong dòng %1 cột %2 có giá trị âm. Chưa kết nhập dòng.';
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
					Common.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(ErrorMessage, StringNumber, FieldNamesInLanguages[Field]));
					UploadedWithoutErrors = False;
				EndIf;
				
			EndDo;
			
			If AllFieldsAreFilledInCorrectly Then
				Record = InformationRegisters.RelativeExchangeRates.CreateRecordManager();
				FillPropertyValues(Record, RowData);
				Record.CourseNumerator = RowData.BaseCurrencyUnits;
				Record.CourseDenominator = RowData.CurrencyUnits;
				Record.Write(True);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Period).Text);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
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
	LoadingFields.Insert("CurrencyUnits", "C2");
	LoadingFields.Insert("Currency", "C3");
	LoadingFields.Insert("BaseCurrencyUnits", "C4");
	LoadingFields.Insert("BaseCurrency", "C5");
	
	ImportParameters.Insert("Fields", LoadingFields);
	
	FieldArray = New Array;
	FieldArray.Add("CurrencyUnits");
	FieldArray.Add("BaseCurrencyUnits");
	
	ImportParameters.Insert("ControlFields", FieldArray);
	
	FieldNamesInLanguages = New Structure();
	FieldNamesInLanguages.Insert("Period", NStr("vi = 'Kỳ';
												|ru = 'Период';
												|en = 'Period'; fa = 'دوره';
												|it = 'Periodo';
												|pl = 'Period';
												|tr = 'Dönem'"));
	FieldNamesInLanguages.Insert("CurrencyUnits", NStr("vi = 'Đơn vị tiền tệ';
														|ru = 'Единиц валюты';
														|en = 'Currency units'; fa = 'Currency units';
														|it = 'Unità di valuta';
														|pl = 'Jednostki waluty';
														|tr = 'Para birimi birimleri'"));
	FieldNamesInLanguages.Insert("Currency", NStr("vi = 'Tiền tệ';
													|ru = 'Валюта';
													|en = 'Currency'; fa = 'ارز';
													|it = 'Valuta';
													|pl = 'Currency';
													|tr = 'Para birimi'"));
	FieldNamesInLanguages.Insert("BaseCurrencyUnits", NStr("vi = 'Đơn vị tiền tệ cơ sở';
															|ru = 'Единиц базовой валюты';
															|en = 'Base currency units'; fa = 'Base currency units';
															|it = 'Unità valuta di riferimento';
															|pl = 'Jednostka waluty podstawowej';
															|tr = 'Temel para birimi birimleri'"));
	FieldNamesInLanguages.Insert("BaseCurrency", NStr("vi = 'Tiền tệ cơ sở';
														|ru = 'Базовая валюта';
														|en = 'Base currency'; fa = 'ارز پایه';
														|it = 'Valuta di riferimento';
														|pl = 'Waluta podstawowa';
														|tr = 'Temel para birimi'"));
	
	ImportParameters.Insert("FieldNamesInLanguages", FieldNamesInLanguages);
	
	
	TemplateTemplate = InformationRegisters.RelativeExchangeRates.GetTemplate("RateImportTemplate");
	SpreadsheetDocument.Clear();
	ColumnArea = TemplateTemplate.GetArea("ExchangeRates");
	SpreadsheetDocument.Join(ColumnArea);
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

#EndRegion

#EndRegion

