
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChartName = Parameters.ChartName;
	UniqueOwnerID = Parameters.UniqueOwnerID;
	HasSecurityDeposit = Parameters.HasSecurityDeposit And ChartName <> "InterestAccrualSchedule";
	ThereIsBuyoutOfLeasedAssets = Parameters.ThereIsBuyoutOfLeasedAssets And ChartName <> "InterestAccrualSchedule";
	
	InitializeTheForm();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("ShowFormClosingConfirmationCompletion", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit,, WarningText);

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
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure LoadGraph()
	
	ScheduleAddress = ImportChartServer();
	
	If ScheduleAddress = Undefined Then
		Return;
	EndIf;
	
	Modified = False;
	
	ShowUserNotification(NStr("vi = 'Đã hoàn thành kết nhập lịch biểu';
								|ru = 'Загрузка графика завершена';
								|en = 'Schedule import complete'; fa = 'Schedule import complete';
								|it = 'Importazione del grafico completata';
								|pl = 'Pobieranie harmonogramu zostało zakończone';
								|tr = 'Çizelgenin yüklenmesi tamamlandı'"),,, PictureLib.Information32);

	Close(ScheduleAddress);
	
EndProcedure

&AtServer
Function ImportChartServer()
	
	ImportParameters = ImportParameters();
	
	LineNumber = 2;
	StringNumber = Format(LineNumber, "NZ=0; NG=0");
	LoadingFields = ImportParameters.Fields;
	DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Date).Text);
	
	UploadedWithoutErrors = True;
	
	If ChartName = "ServicePaymentSchedule" Then
		GraphEntries = InformationRegisters.LeaseServicesPaymentSchedule.CreateRecordSet();
	ElsIf ChartName = "ServiceAccrualSchedule" Then
		GraphEntries = InformationRegisters.LeaseServicesAccrualSchedule.CreateRecordSet();
	ElsIf ChartName = "InterestAccrualSchedule" Then
		GraphEntries = InformationRegisters.LeaseInterestAccrualSchedule.CreateRecordSet();
	Else
		Raise StrTemplate(NStr("vi = 'Lịch không xác định %1';
								|ru = 'Неизвестный график %1';
								|en = 'Unknown schedule %1'; fa = 'Unknown schedule %1';
								|it = 'Grafico sconosciuto %1';
								|pl = 'Niewiadomy harmonogram %1';
								|tr = 'Bilinmeyen çizelge %1'"), ChartName);
	EndIf;
	
	While DateFilledIn Do
		
		RowData = Undefined;
		Try

			RowData = New Structure;
			For Each Field In LoadingFields Do
				
				ValueText = SpreadsheetDocument.Area("R" + StringNumber + Field.Value).Text;
				If Field.Key = "Date" Then
					Simple = TextToDate(ValueText, StringNumber, Field.Key);
				Else
					Simple = TextToNumber(ValueText, StringNumber, Field.Key);
				EndIf;
				RowData.Insert(Field.Key, Simple);
				
			EndDo;
			
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
		If ValueIsFilled(RowData) Then

			AllFieldsFilled = ValueIsFilled(RowData.Date);
			If AllFieldsFilled Then
				SumOfFields = 0;
				For Each Field In ImportParameters.ControlFields Do
					SumOfFields = SumOfFields + RowData[Field];
				EndDo;
				If SumOfFields = 0 Then
					AllFieldsFilled = False;
					UploadedWithoutErrors = False;
					MessageText = StrTemplate(NStr("vi = 'Không thể kết nhập dòng %1, vì chưa điền số tiền';
													|ru = 'Не удалось загрузить строку %1, т.к. не заполнены суммы';
													|en = 'Cannot import line %1 because amounts are not filled in'; fa = 'Cannot import line %1 because amounts are not filled in';
													|it = 'Non è stato possibile importare la riga %1, poiché gli importi non sono compilati';
													|pl = 'Nie udało się pobrać wiersza %1, ponieważ wartości nie są wypełnione';
													|tr = 'Toplamlar doldurulmadığı için %1 satırı yüklenemedi'"), StringNumber);
					Common.MessageToUser(MessageText);
				EndIf;
			EndIf;
			
			If AllFieldsFilled Then
				NewRecord = GraphEntries.Add();
				FillPropertyValues(NewRecord, RowData);
			EndIf;
			
		EndIf;
		
		LineNumber = LineNumber + 1;
		StringNumber = Format(LineNumber, "NZ=0; NG=0");
		
		Try
			DateFilledIn = ValueIsFilled(SpreadsheetDocument.Area("R" + StringNumber + LoadingFields.Date).Text);
		Except
			Common.MessageToUser(BriefErrorDescription(ErrorInfo()));
		EndTry;
		
	EndDo;
	
	If UploadedWithoutErrors Then
		ScheduleAddress = PutToTempStorage(GraphEntries.Unload(), UniqueOwnerID);
	Else
		ScheduleAddress = Undefined;
	EndIf;
	
	Return ScheduleAddress;
	
EndFunction

&AtServer
Function ImportParameters()
	
	ImportParameters = New Structure;
	LoadingFields = New Structure("Date", "C1");
	 
	If ChartName = "InterestAccrualSchedule" Then
		LoadingFields.Insert("Interests", "C2");
	Else
		LoadingFields.Insert("RentalService", "C2");
	EndIf;
	
	If HasSecurityDeposit Then
		LoadingFields.Insert("DepositPayment", "C3");
	EndIf;
	
	If ThereIsBuyoutOfLeasedAssets Then
		LoadingFields.Insert("BuyoutValue", "C4");
	EndIf;
	
	ImportParameters.Insert("Fields", LoadingFields);
	
	//
	FieldArray = New Array;
	
	If ChartName = "InterestAccrualSchedule" Then
		FieldArray.Add("Interests");
	Else
		FieldArray.Add("RentalService");
	EndIf;
	
	If HasSecurityDeposit Then
		FieldArray.Add("DepositPayment");
	EndIf;
	
	If ThereIsBuyoutOfLeasedAssets Then
		FieldArray.Add("BuyoutValue");
	EndIf;
	
	ImportParameters.Insert("ControlFields", FieldArray);
	
	Return ImportParameters;
	
EndFunction

&AtServer
Procedure InitializeTheForm()
	
	ImportParameters = New Structure;
	If ChartName = "ServiceAccrualSchedule" Then
		Title = NStr("vi = 'Kết nhập lịch biểu tính toán';
					|ru = 'Загрузка графика начислений';
					|en = 'Import accrual schedule'; fa = 'Import accrual schedule';
					|it = 'Download del grafico delle maturazioni';
					|pl = 'Pobieranie harmonogramu naliczeń';
					|tr = 'Tahakkuk çizelgesinin yüklenmesi'");
	ElsIf ChartName = "ServicePaymentSchedule" Then
		Title = NStr("vi = 'Kết nhập lịch biểu thanh toán';
					|ru = 'Загрузка графика оплат';
					|en = 'Import payment schedule'; fa = 'Import payment schedule';
					|it = 'Download grafico di pagamento';
					|pl = 'Pobieranie harmonogramu płatności';
					|tr = 'Ödeme çizelgesinin yüklenmesi'");
	ElsIf ChartName = "InterestAccrualSchedule" Then
		Title = NStr("vi = 'Kết nhập lịch biểu tính lãi';
					|ru = 'Загрузка графика процентов';
					|en = 'Importing interest schedule'; fa = 'Importing interest schedule';
					|it = 'Importazione del grafico degli interessi';
					|pl = 'Pobieranie harmonogramu procentów';
					|tr = 'Faiz çizelgesinin yüklenmesi'");
	EndIf;
	
	TemplateTemplate = Catalogs.LeaseContract.GetTemplate("ChartImportTemplate");
	
	SpreadsheetDocument.Clear();
	
	ColumnArea = TemplateTemplate.GetArea("RentalService");
	
	If ChartName = "ServiceAccrualSchedule" Then
		ColumnArea.Parameters.Title = NStr("vi = 'Dịch vụ thuê';
											|ru = 'Услуга по аренде';
											|en = 'Rental service'; fa = 'خدمات اجاره';
											|it = 'Servizio relativo all''affitto';
											|pl = 'Usługa dotycząca dzierżawy';
											|tr = 'Kiralama hizmeti'");
	ElsIf ChartName = "ServicePaymentSchedule" Then
		ColumnArea.Parameters.Title = NStr("vi = 'Số tiền thanh toán dịch vụ thuê';
											|ru = 'Сумма оплаты услуг по аренде';
											|en = 'Amount of payment for rental services'; fa = 'مبلغ پرداخت خدمات اجاره';
											|it = 'Importo del pagamento dei servizi relativi all''affitto';
											|pl = 'Wartość opłaty usług dotyczących dzierżawy';
											|tr = 'Kiralama hizmeti ödeme tutarı'");
	ElsIf ChartName = "InterestAccrualSchedule" Then
		ColumnArea.Parameters.Title = NStr("vi = 'Số tiền phần trăm';
											|ru = 'Сумма процентов';
											|en = 'Interest amount'; fa = 'مبلغ بهره';
											|it = 'Importo degli interessi';
											|pl = 'Wartość odsetek';
											|tr = 'Faiz tutarı'")
	EndIf;
	
	SpreadsheetDocument.Join(ColumnArea);
	
	If HasSecurityDeposit Then
		
		ColumnArea = TemplateTemplate.GetArea("DepositPayment");
		
		ColumnArea.Parameters.Title =
			?(ChartName = "ServiceAccrualSchedule",
				NStr("vi = 'Số tiền đối trừ tiền ký quỹ';
					|ru = 'Сумма зачета обеспечительного платежа';
					|en = 'Security deposit offset amount'; fa = 'مبلغ تهاتر ودیعه تضمین';
					|it = 'Ammontare del pagamento di saldo sicuro';
					|pl = 'Wartość zaliczenia płatności zabezpieczającej';
					|tr = 'Mahsup edilen teminat tutarı'"),
				NStr("vi = 'Số tiền thanh toán đảm bảo';
					|ru = 'Сумма обеспечительного платежа';
					|en = 'Security deposit amount'; fa = 'مبلغ سپرده تضمین';
					|it = 'Importo del deposito cauzionale';
					|pl = 'Wartość płatności zabezpieczającej';
					|tr = 'Teminat miktarı'"));
				 
		SpreadsheetDocument.Join(ColumnArea);
	
	EndIf;
	
	If ThereIsBuyoutOfLeasedAssets Then
		
		ColumnArea = TemplateTemplate.GetArea("BuyoutValue");
		ColumnArea.Parameters.Title =
			?(ChartName = "ServiceAccrualSchedule",
				NStr("vi = 'Số tiền mua lại đối tượng thuê';
					|ru = 'Сумма выкупа предметов аренды';
					|en = 'Amount of rental objects redemption'; fa = 'مبلغ بازخرید اقلام اجاره‌ای';
					|it = 'Importo del rimborso degli elementi di affitto';
					|pl = 'Wartość wykupu przedmiotów dzierżawy';
					|tr = 'Kiralama kalemlerinin itfa tutarı'"),
				NStr("vi = 'Giá trị mua lại';
					|ru = 'Выкупная стоимость';
					|en = 'Buyout value'; fa = 'ارزش بازخرید';
					|it = 'Valore di Rimborso';
					|pl = 'Wartość wykupu';
					|tr = 'İtfa değeri'"));	
	
		SpreadsheetDocument.Join(ColumnArea);
	
	EndIf;
	
	SpreadsheetDocument.FixedTop = 1;
	
EndProcedure

&AtServer
Procedure ReportConversionError(LineNumber, ColumnName, StringValue)
	
	TextTemplate1 = NStr("vi = 'Dòng số %1 cột ""%2"" - lỗi chuyển đổi giá trị ""%3""
		|Dòng chưa được kết nhập.';
		|ru = 'Строка №%1 колонка ""%2"" - ошибка преобразования значения ""%3""
		|Строка не загружена.';
		|en = 'Conversion error for value ""%3""
		| in column ""%2"" of line %1. The line is not imported.'; fa = 'Conversion error for value ""%3""
		| in column ""%2"" of line %1. The line is not imported.';
		|it = 'Riga №%1, colonna ""%2"" - errore nella trasformazione del valore ""%3""
		|Riga non caricata.';
		|pl = 'Wiersz Nr%1 kolumna ""%2"" - błąd konwersji wartości ""%3""
		| Wiersz nie jest wczytany.';
		|tr = 'Satır no%1 sütun ""%2"" - değer dönüştürme hatası ""%3""
		|Satır yüklenmedi.'");
	Text = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, LineNumber, ColumnName, StringValue);
	Common.MessageToUser(Text);
	
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

&AtClient
Procedure ShowFormClosingConfirmationCompletion(Result, AdditionalParameters) Export
	
	LoadGraph();
	
EndProcedure

#EndRegion
