
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();

	If Not Parameters.Property("CRTRHistory")
		Or Not Parameters.Property("CurCheckpoint") Then 
		Cancel = True;
		Return;
	EndIf;
	
	CRTRHistory.Load(Parameters.CRTRHistory.Unload());
	If CRTRHistory.Count() = 0 Then
		CRTRHistory.Add().CRTR = Parameters.CurCheckpoint;
	EndIf;
	
	If Not AccessRight("Edit", Metadata.Catalogs.Counterparties) Then
		
		ReadOnly = True;
		
	EndIf;
	
	If ReadOnly Then
		
		Items.FormCancel.DefaultButton = True;
		
	EndIf;
	
	SetInitialValueAttribute(CRTRHistory);
	
	If CRTRHistory.Count() > 0 Then
		Items.CRTRHistory.CurrentRow = CRTRHistory[CRTRHistory.Count()-1].GetID();
	EndIf;
	
	HistoryLineQuantity = CRTRHistory.Count();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Not ClosingInProgress Then
		
		Cancel = True;
		StandardProcessing = False;
		
		QueryText = NStr("vi = 'Dữ liệu đã được thay đổi, chuyển thay đổi?';
						|ru = 'Данные были изменены, перенести изменения?';
						|en = 'Data has changed, transfer the changes?'; fa = 'Data has changed, transfer the changes?';
						|it = 'I dati sono stati modificati, trasferire le modifiche?';
						|pl = 'Dane zostały zmienione, przenieść zmiany?';
						|tr = 'Veriler değiştirildi, değişiklikleri taşı?'");
		ClosingNotification1 = New CallbackDescription("QuestionAboutMigratingChangesAfterAnswer", ThisObject);
		ShowQueryBox(ClosingNotification1, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesCheckpointHistory

&AtClient
Procedure CRTRHistoryOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Item.CurrentData;
		
		If CurrentData <> Undefined Then
			
			NewPeriod = BegOfDay(CommonClient.SessionDate());
			CurrentData.InitialValue = False;
			
			// We get the maximum period in the table
			LastPeriod = '00010101000000';
			For Each RecordingHistory In CRTRHistory Do
				If RecordingHistory.Period > LastPeriod Then
					LastPeriod = RecordingHistory.Period;
				EndIf;
			EndDo;
			
			If NewPeriod <= LastPeriod Then
				NewPeriod = BegOfDay(LastPeriod + 60*60*24);
			EndIf;
			
			CurrentData.Period = NewPeriod;
			
			ThisObject.CurrentItem = Items.CRTRHistoryCRTR;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CRTRHistoryOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	SetInitialValueAttribute(CRTRHistory);
	
EndProcedure

&AtClient
Procedure CRTRHistoryBeforeDeleteRow(Item, Cancel)
	
	If CRTRHistory.IndexOf(Item.CurrentData) = 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CRTRHistoryOnChange(Item)
	HistoryLineQuantity = CRTRHistory.Count();
	ClearMarkIncomplete();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	MigrateChanges();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetInitialValueAttribute(HistoryTable)
	
	HistoryTable.Sort("Period");
	If HistoryTable.Count() > 0 Then
		FirstRow = HistoryTable[0];
		FirstRow.InitialValue = True;
		FirstRow.Period = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure MigrateChanges()
	
	Cancel = False;
	
	CheckHistoryCompletion(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	ClosingInProgress = True;
	SelectionResult = New Structure;
	SelectionResult.Insert("CRTRHistory", CRTRHistory);
	
	Close(SelectionResult);

EndProcedure

&AtClient
Procedure CheckHistoryCompletion(Cancel)
	
	ClearMessages();
	
	LinePeriods = New Array;
	
	If CRTRHistory.Count() = 1
		And IsBlankString(CRTRHistory[0].CRTR) Then
		
		Return;
		
	EndIf;
	
	For Each Record In CRTRHistory Do
		
		RowIndex = CRTRHistory.IndexOf(Record);
		StringMessagePrefix = "CRTRHistory["+Format(RowIndex, "ND=; NFD=; NG=")+"].";
		
		If Not ValueIsFilled(Record.Period) And RowIndex > 0 Then
			ErrorMessage = NStr("vi = 'Bạn cần xác định ngày bắt đầu của hành động';
								|ru = 'Нужно указать дату начала действия';
								|en = 'Specify effective date'; fa = 'Specify effective date';
								|it = 'È necessario specificare la data di inizio';
								|pl = 'Należy wskazać datę rozpoczęcia działania';
								|tr = 'İşlem başlangıç ​​tarihi belirtilmeli'");
			CommonClientServer.MessageToUser(ErrorMessage, , StringMessagePrefix+"Period", , Cancel);
		EndIf;
		
		If LinePeriods.Find(Record.Period) = Undefined Then
			If ValueIsFilled(Record.Period) Then
				LinePeriods.Add(Record.Period);
			EndIf;
		Else
			ErrorMessage = NStr("vi = 'Đã có bản ghi với ngày thông tin đã chỉ ra';
								|ru = 'Уже есть запись с указанной датой сведений';
								|en = 'The record with the specified information date already exists'; fa = 'The record with the specified information date already exists';
								|it = 'Esiste già una registrazione con la data delle informazioni indicata';
								|pl = 'Wpis ze wskazaną datą informacji już istnieje';
								|tr = 'Belirtilen bilgi kaydı tarihi ile artık kayıt mevcut'");
			CommonClientServer.MessageToUser(ErrorMessage, , StringMessagePrefix+"Period", , Cancel);
		EndIf;
		
		If Not ValueIsFilled(Record.CRTR) Then
			ErrorMessage = NStr("vi = 'Trường ''''MSDN'''' chưa điền';
								|ru = 'Поле ""КПП"" не заполнено';
								|en = '""KPP"" is required'; fa = '""KPP"" is required';
								|it = 'Il campo ""Codice causale di registrazione fiscale"" non è compilato';
								|pl = 'Nie wypełniono pola ""KPP""';
								|tr = '""KPP"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(ErrorMessage, , StringMessagePrefix+"CRTR",  , Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure QuestionAboutMigratingChangesAfterAnswer(Response, AdditionalParameters) Export

	If Response = DialogReturnCode.Yes Then
		
		MigrateChanges();
		
	ElsIf Response = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close(Undefined);
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CRTRHistoryCRTR.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("HistoryLineQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CRTRHistory.CRTR");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CRTRHistoryPeriod.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CRTRHistory.InitialValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OutdatedListTextColor);

EndProcedure

#EndRegion