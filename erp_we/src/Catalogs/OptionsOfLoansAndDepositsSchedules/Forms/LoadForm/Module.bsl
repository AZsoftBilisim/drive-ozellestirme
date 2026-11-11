
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("ScheduleType") Then
		ScheduleType = Parameters.ScheduleType;
		InitializeLoadingParameters();
	EndIf;
	
	Parameters.Property("ScheduleOption", ScheduleOption);
	Parameters.Property("OwnerID", OwnerID);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteSchedule(Command)
	
	LoadGraph();
	
EndProcedure

&AtClient
Procedure CloseForm(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure LoadGraph()
	
	If ImportChartServer() Then
		Close(ScheduleAddress);
	EndIf;
	
	Text = NStr("vi = 'Kết nhập đã kết thúc';
				|ru = 'Загрузка окончена';
				|en = 'Import completed'; fa = 'ورود اطلاعات تکمیل شد';
				|it = 'Download completato';
				|pl = 'Pobieranie zakończono';
				|tr = 'Yüklenme bitti'");
	ShowUserNotification(Text,,, PictureLib.Information32);
	
EndProcedure

&AtServer
Procedure ReportConversionError(LineNumber, ColumnName, StringValue)
	
	TextTemplate1 = NStr("vi = 'Dòng số%1 cột ""%2"" - lỗi chuyển đổi giá trị ""%3""
		|Dòng chưa được kết nhập!';
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
Function TextToDate(Val StringValue, LineNumber, ColumnName, Separator = ".")
	
	Digits = StringFunctionsClientServer.SplitStringIntoSubstringsArray(StringValue,Separator);
	
	Try
		Result = ?(StrLen(Digits[2]) = 2, "20" + Digits[2], Digits[2])
			+ Format(Digits[1], "ND=2; NLZ=;") 
			+ Format(Digits[0], "ND=2; NLZ=;");
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
	
	Try
		Result = Number(StrReplace(StringValue," ",""));
	Except
		ReportConversionError(LineNumber, ColumnName, StringValue);
	EndTry;
	Return Result;
	
EndFunction

&AtServer
Function ImportChartServer()
	
	LineNumber = 2;
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	LoadingFields = ImportParameters.Fields;
	DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Period).Text);
	UploadedWithoutErrors = True;
	
	// Prepare a set of records
	GraphEntries = InformationRegisters[ImportParameters.RegisterName].CreateRecordSet(); // InformationRegisterRecordSet
	GraphEntries.Filter.ScheduleOption.Set(ScheduleOption);
	
	While DateFilledIn Do
		
		RowData = Undefined;
		Try
			// Let's read the data lines of the graph
			RowData = New Structure("ScheduleOption",ScheduleOption);
			For Each Field In LoadingFields Do
				
				ValueText = SpreadsheetDocument.Area("R" + StringNumber + Field.Value).Text;
				If Field.Key = "Period" Then
					Simple = TextToDate(ValueText, StringNumber, Field.Key);
				Else
					Simple = TextToNumber(ValueText, StringNumber, Field.Key);
				EndIf;
				RowData.Insert(Field.Key,Simple);
				
			EndDo;// by columns of the loading table
			
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		If ValueIsFilled(RowData) Then
			// let's check everything we've read
			AllFieldsFilled = ValueIsFilled(RowData.Period);
			If AllFieldsFilled Then
				SumOfFields = 0;
				For Each Field In ImportParameters.ControlFields Do
					SumOfFields = SumOfFields + RowData[Field];
				EndDo;// by control fields
				If SumOfFields = 0 Then
					AllFieldsFilled = False;
					UploadedWithoutErrors = False;
					TextTemplate1 = NStr("vi = 'Dòng số%1 không điền cột tổng. 
						|Chưa kết nhập dòng này.';
						|ru = 'В строке №%1 нет заполненных колонок сумм.
						|Строка не загружена!';
						|en = 'No amount are filled in line %1.
						|The line is not imported.'; fa = 'No amount are filled in line %1.
						|The line is not imported.';
						|it = 'Nella riga №%1 non ci sono colonne di importo compilate.
						| Riga non caricata!';
						|pl = 'W wierszu nr%1 brak wypełnionych kolumn kwot.
						|Wiersz nie został pobrany!';
						|tr = 'Satır №%1 tamamlanmış tutar sütunlarına sahip değil.
						|Satır yüklenmedi!'");
					Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, StringNumber);
					CommonClientServer.MessageToUser(Text);
				EndIf;
			EndIf;
			
			// Let's write down what we read
			If AllFieldsFilled Then
				NewRecord = GraphEntries.Add();
				FillPropertyValues(NewRecord, RowData);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Period).Text);
		Except
			CommonClientServer.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;// by rows of the loading table
	
	ScheduleAddress = PutToTempStorage(Common.ValueToXMLString(GraphEntries), OwnerID);
	
	Return UploadedWithoutErrors;
	
EndFunction

&AtServer
Procedure InitializeLoadingParameters()
	
	ImportParameters = New Structure;
	LoadingFields = New Structure("Period","C1");
	If ScheduleType = "ScheduleOfAccruals" Then
		
		ThisForm.Title = NStr("vi = 'Kết nhập lịch biểu tính toán';
								|ru = 'Загрузка графика начислений';
								|en = 'Import accrual schedule'; fa = 'Import accrual schedule';
								|it = 'Download del grafico delle maturazioni';
								|pl = 'Pobieranie harmonogramu naliczeń';
								|tr = 'Tahakkuk programının yüklenmesi'");
		
		LoadingFields.Insert("Interests","C2");
		LoadingFields.Insert("Fee","C3");
		
		FieldArray = New Array;
		FieldArray.Add("Interests");
		FieldArray.Add("Fee");
		
		ImportParameters.Insert("ControlFields", FieldArray);
		ImportParameters.Insert("RegisterName", "ScheduleOfAccrualsForLoansAndDeposits");
		
	ElsIf ScheduleType = "PaymentSchedule" Then
		
		ThisForm.Title = NStr("vi = 'Kết nhập lịch biểu thanh toán';
								|ru = 'Загрузка графика оплат';
								|en = 'Import payment schedule'; fa = 'Import payment schedule';
								|it = 'Download grafico di pagamento';
								|pl = 'Pobieranie harmonogramu płatności';
								|tr = 'Ödeme programının yüklenmesi'");
		LoadingFields.Insert("Sum","C2");
		LoadingFields.Insert("Interests","C3");
		LoadingFields.Insert("Fee","C4");
		
		FieldArray = New Array;
		FieldArray.Add("Sum");
		FieldArray.Add("Interests");
		FieldArray.Add("Fee");
		
		ImportParameters.Insert("ControlFields", FieldArray);
		ImportParameters.Insert("RegisterName", "ScheduleOfPaymentForLoansAndDeposits");
		
	ElsIf ScheduleType = "TrancheSchedule" Then
		
		ThisForm.Title = NStr("vi = 'Kết nhập lịch biểu giai đoạn thanh toán';
								|ru = 'Загрузка графика траншей';
								|en = 'Import tranche schedule'; fa = 'Import tranche schedule';
								|it = 'Download grafico tranche';
								|pl = 'Pobieranie harmonogramu transz';
								|tr = 'Dilim programının yüklenmesi'");
		LoadingFields.Insert("Sum","C2");
		
		FieldArray = New Array;
		FieldArray.Add("Sum");
		
		ImportParameters.Insert("ControlFields", FieldArray);
		ImportParameters.Insert("RegisterName", "ScheduleOfTrancheForLoansAndDeposits");
		
	EndIf;
	
	ImportParameters.Insert("Fields", LoadingFields);
	
	// Initializing a tabular document
	TemplateTemplate = Catalogs.OptionsOfLoansAndDepositsSchedules.GetTemplate("ChartImportTemplate");
	SpreadsheetDocument.Clear();
	ColumnArea = TemplateTemplate.GetArea(ScheduleType);
	SpreadsheetDocument.Join(ColumnArea);
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

#EndRegion

#EndRegion
