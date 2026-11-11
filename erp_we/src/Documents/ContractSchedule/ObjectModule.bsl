#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	ErrorTemplate = NStr("vi = 'Chưa điền cột ""Số tiền"" tại dòng %1 trong danh sách ""Lịch biểu thanh toán""';
						|ru = 'Не заполнена колонка ""Сумма"" в строке %1 списка ""График оплаты""';
						|en = 'The ""Amount"" column in the %1 line of the ""Payment schedule"" list is not filled in'; fa = 'The ""Amount"" column in the %1 line of the ""Payment schedule"" list is not filled in';
						|it = 'Non è compilata la colonna ""Importo"" nella riga %1 dell''elenco ""Grafico di pagamento""';
						|pl = 'Nie wypełniono kolumny ""Wartość"" w wierszu %1 lista ""Harmonogram płatności""';
						|tr = '""Ödeme planı"" listesinin %1 satırındaki ""Tutar"" sütunu doldurulmadı'");
	For Each Stage In PaymentScheduleSteps Do
		If Not ValueIsFilled(Stage.PaymentAmount) Then
			ErrorText = StrTemplate(ErrorTemplate, Stage.LineNumber);
			Common.MessageToUser(
				ErrorText,
				,
				"Object."+CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Stage.LineNumber, "PaymentAmount"),
				,
				Cancel);
		EndIf;
	EndDo;
	
	ScheduleOption = Common.ObjectAttributeValue(Contract, "OptionOfDeterminingExecutionScheduleInContract");
	TheseAreRegularPayments = (ScheduleOption = Enums.OptionsForDeterminingExecutionScheduleInContract.RegularPayments);
	
	If Not TheseAreRegularPayments And PaymentScheduleSteps.Total("PaymentPercentage") <> 100 Then
		ErrorText = NStr("vi = 'Phần trăm thanh toán hợp đồng theo tất cả giai đoạn phải bằng ""100%""';
						|ru = 'Процент оплаты договора по всем этапам должен быть равен ""100%""';
						|en = 'The percentage of contract payment in all stages must be ""100%""'; fa = 'The percentage of contract payment in all stages must be ""100%""';
						|it = 'La percentuale di pagamento del contratto deve essere pari a ""100%"" in tutte le fasi';
						|pl = 'Procent opłaty kontraktu wg wszystkich etapów powinien równać się ""100%""';
						|tr = 'Tüm aşamalar için sözleşme ödeme yüzdesi ""100%"" olmalıdır'");
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			,
			,
			Cancel);
	EndIf;
		
	If Not TheseAreRegularPayments And ContractScheduleSteps.Total("FulfillmentPercentage") <> 100 Then
		ErrorText = NStr("vi = 'Tỷ lệ phần trăm giao hàng trong hợp đồng theo tất cả giai đoạn phải bằng ""100%""';
						|ru = 'Процент отгрузки договора по всем этапам должен быть равен ""100%""';
						|en = 'The percentage of contract shipment in all stages must be ""100%""'; fa = 'The percentage of contract shipment in all stages must be ""100%""';
						|it = 'Процент отгрузки договора по всем этапам должен быть равен ""100%""';
						|pl = 'The percentage of contract shipment in all stages must be ""100%""';
						|tr = 'Tüm aşamalar için sözleşmenin sevkiyat yüzdesi ""100%""e eşit olmalıdır'");
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			,
			,
			Cancel);
	EndIf;
	
	For Each Data_Stage In PaymentScheduleSteps Do
		
		If TheseAreRegularPayments Then
			Continue;
		EndIf;
	
		If PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(Data_Stage.CalculateFrom, Data_Stage.Formula)
			And Not ValueIsFilled(Data_Stage.DateOfShipment) Then
			ErrorText = NStr("ru = 'Для варианта отсчета, зависящего от даты отгрузки не указана дата отгрузки';
							|vi = 'The shipment date is not specified for the calculation option that depends on the shipment date';
							|en = 'The shipment date is not specified for the calculation option that depends on the shipment date'; fa = 'The shipment date is not specified for the calculation option that depends on the shipment date';
							|it = 'The shipment date is not specified for the calculation option that depends on the shipment date';
							|pl = 'The shipment date is not specified for the calculation option that depends on the shipment date';
							|tr = 'Sevkiyat tarihine bağlı olan referans seçeneği için sevkiyat tarihi belirtilmedi'");
			ErrorField  = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "CalculateFrom");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				,
				,
				Cancel);
		EndIf;
		
		If Not PaymentStepsCached.StringOfStagesDependsOnDateOfShipment(Data_Stage.CalculateFrom, Data_Stage.Formula)
			And ValueIsFilled(Data_Stage.DateOfShipment) Then
			ErrorText = NStr("ru = 'Для варианта отсчета, независящего от даты отгрузки указана дата отгрузки';
							|vi = 'The shipment date is specified for the calculation option that does not depend on the shipment date';
							|en = 'The shipment date is specified for the calculation option that does not depend on the shipment date'; fa = 'The shipment date is specified for the calculation option that does not depend on the shipment date';
							|it = 'The shipment date is specified for the calculation option that does not depend on the shipment date';
							|pl = 'The shipment date is specified for the calculation option that does not depend on the shipment date';
							|tr = 'Sevkiyat tarihinden bağımsız olan referans seçeneği için sevkiyat tarihi belirtildi'");
			ErrorField  = CommonClientServer.PathToTabularSection("PaymentScheduleSteps", Data_Stage.LineNumber, "CalculateFrom");
			
			Common.MessageToUser(
				ErrorText,
				ThisObject,
				,
				,
				Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If IsNew() And Not ValueIsFilled(Number) Then
		SetNewNumber();
	EndIf;
	
	DefaultDate = ?(ContractScheduleSteps.Count() > 0,
			ContractScheduleSteps[0].DateAccordingToSchedule,
			?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	
	ContractDate_ = Common.ObjectAttributeValue(Contract,"Date");
	If ValueIsFilled(ContractDate_) Then
		DefaultDate = Min(ContractDate_,DefaultDate);
	EndIf;
	
	If Date > DefaultDate Then
		Date = DefaultDate;
	EndIf;
	
	If WriteMode = DocumentWriteMode.UndoPosting Then
		ARAPObject = Catalogs.ARAPObjects.EmptyRef();
	ElsIf WriteMode = DocumentWriteMode.Posting Then
		ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Contract);
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#EndIf