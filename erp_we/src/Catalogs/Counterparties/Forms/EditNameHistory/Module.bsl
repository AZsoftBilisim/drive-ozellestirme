
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();

	If Not Parameters.Property("NameHistory")
		Or Not Parameters.Property("CurFullName") Then 
		Cancel = True;
		Return;
	EndIf;
	
	LegalEntityIndividual = Parameters.LegalEntityIndividual;
	
	NameHistory.Load(Parameters.NameHistory.Unload());
	If NameHistory.Count() = 0 Then
		NameHistory.Add().NameAbbreviated = Parameters.CurFullName;
	EndIf;

	GenerateHeadings();
	
	If Not AccessRight("Edit", Metadata.Catalogs.Counterparties) Then
		
		ReadOnly = True;
		
	EndIf;
	
	If ReadOnly Then
		
		Items.FormCancel.DefaultButton = True;
		
	EndIf;
	
	SetInitialValueAttribute(NameHistory);
	
	If NameHistory.Count() > 0 Then
		Items.NameHistory.CurrentRow = NameHistory[NameHistory.Count()-1].GetID();
	EndIf;
	
	HistoryLineQuantity = NameHistory.Count();
	
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

#Region EventHandlersFormTablesNameHistory

&AtClient
Procedure NameHistoryOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Item.CurrentData;
		
		If CurrentData <> Undefined Then
			
			NewPeriod = BegOfDay(CommonClient.SessionDate());
			CurrentData.InitialValue = False;
			
			// We get the maximum period in the table
			LastPeriod = '00010101000000';
			For Each RecordingHistory In NameHistory Do
				If RecordingHistory.Period > LastPeriod Then
					LastPeriod = RecordingHistory.Period;
				EndIf;
			EndDo;
			
			If NewPeriod <= LastPeriod Then
				NewPeriod = BegOfDay(LastPeriod + 60*60*24);
			EndIf;
			
			CurrentData.Period = NewPeriod;
			
			ThisObject.CurrentItem = Items.NameHistoryDescriptionFull;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NameHistoryOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	SetInitialValueAttribute(NameHistory);
	
EndProcedure

&AtClient
Procedure NameHistoryBeforeDeleteRow(Item, Cancel)
	
	If NameHistory.IndexOf(Item.CurrentData) = 0 Then
		Cancel = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure NameHistoryOnChange(Item)
	HistoryLineQuantity = NameHistory.Count();
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
	SelectionResult.Insert("NameHistory", NameHistory);
	
	Close(SelectionResult);

EndProcedure

&AtClient
Procedure CheckHistoryCompletion(Cancel)
	
	ClearMessages();
	
	LinePeriods = New Array;
	
	If NameHistory.Count() = 1
		And IsBlankString(NameHistory[0].NameAbbreviated) Then
		
		Return;
		
	EndIf;
	
	For Each Record In NameHistory Do
		
		RowIndex = NameHistory.IndexOf(Record);
		StringMessagePrefix = "NameHistory["+Format(RowIndex, "ND=; NFD=; NG=")+"].";
		
		If Not ValueIsFilled(Record.Period) And RowIndex > 0 Then
			ErrorMessage = NStr("vi = 'Bạn cần xác định ngày bắt đầu của hành động';
								|ru = 'Нужно указать дату начала действия';
								|en = 'Specify effective date'; fa = 'Specify effective date';
								|it = 'È necessario specificare la data di inizio';
								|pl = 'Należy wskazać datę rozpoczęcia działania';
								|tr = 'İşlem başlangıç ​​tarihi belirtilmeli'");
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"Period", , Cancel);
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
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"Period", , Cancel);
		EndIf;
		
		If Not ValueIsFilled(Record.NameAbbreviated) Then
			If LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.Person")
				Or LegalEntityIndividual = PredefinedValue("Enum.LegalEntityIndividual.IndividualEntrepreneur") Then
				ErrorMessage = NStr("vi = 'Chưa điền trường ""Họ, tên""';
									|ru = 'Поле ""Фамилия, имя, отчество"" не заполнено';
									|en = '""Full name"" is required'; fa = '""Full name"" is required';
									|it = 'Il campo ""Cognome, nome, patronimico"" non è compilato';
									|pl = 'Nie wypełniono pola ""Nazwisko, imię, imię odojcowskie""';
									|tr = '""Soyadı, adı, baba adı"" alanı doldurulmadı'");
			Else
				ErrorMessage = NStr("vi = 'Chưa điền trường ""Tên pháp lý viết tắt""';
									|ru = 'Поле ""Сокр. юр наименование"" не заполнено';
									|en = '""Abbr. legal name"" is required'; fa = '""Abbr. legal name"" is required';
									|it = 'Il campo ""Nome giuridico abbreviato"" non è compilato';
									|pl = 'Nie wypełniono pola ""Skrócona nazwa prawna""';
									|tr = '""Kısaltılmış yasal tanım"" alanı doldurulmadı'");
			EndIf;
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"NameAbbreviated",  , Cancel);
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
Procedure GenerateHeadings()

	If LegalEntityIndividual = Enums.LegalEntityIndividual.Person
		Or LegalEntityIndividual = Enums.LegalEntityIndividual.IndividualEntrepreneur Then
		
		Title = NStr("vi = 'Lịch sử thay đổi họ tên';
					|ru = 'История изменения ФИО';
					|en = 'History of full name change'; fa = 'History of full name change';
					|it = 'Cronologia delle modifiche di Cognome Nome Patronimico';
					|pl = 'Historia zmian Imię i nazwisko';
					|tr = 'Tam adı değişiklik geçmişi'");
		Items.NameHistoryDescriptionFull.Title = NStr("vi = 'Họ tên';
														|ru = 'Фамилия, имя, отчество';
														|en = 'Full name'; fa = 'نام کامل';
														|it = 'Cognome, nome, patronimico';
														|pl = 'Nazwisko, imię, imię odojcowskie';
														|tr = 'Soyadı, adı, baba adı'");
		
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NameHistoryDescriptionFull.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("HistoryLineQuantity");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 1;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NameHistory.NameAbbreviated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.NameHistoryPeriod.Name);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("NameHistory.InitialValue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Enabled", False);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OutdatedListTextColor);

EndProcedure

#EndRegion