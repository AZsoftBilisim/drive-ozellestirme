
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CompanyIndividual = Parameters.CompanyIndividual;
	NameHistory.Load(Parameters.NameHistory.Unload());
	
	SetInitialValueAttribute(NameHistory);
	
	If NameHistory.Count() > 0 Then
		Items.NameHistory.CurrentRow = NameHistory[NameHistory.Count()-1].GetID();
	EndIf;
	
	If Not AccessRight("Edit", Metadata.Catalogs.Companies) Then
		ReadOnly = True;
	EndIf;
	
	If ReadOnly Then
		
		Items.CancelCommand.DefaultButton = True;
		
	EndIf;
	
	SetConditionalAppearance();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersNameHistory

&AtClient
Procedure NameHistoryOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		If Item.CurrentData <> Undefined Then
			
			NewPeriod = BegOfDay(CommonClient.SessionDate());
			
			// We get the maximum period in the table
			LastPeriod = '00010101000000';
			LatestRecord = Undefined;
			For Each RecordingHistory In NameHistory Do
				If RecordingHistory.Period >= LastPeriod
					And RecordingHistory <> Item.CurrentData Then
					LastPeriod = RecordingHistory.Period;
					LatestRecord = RecordingHistory;
				EndIf;
			EndDo;
			
			If NewPeriod <= LastPeriod Then
				NewPeriod = BegOfDay(LastPeriod + 60*60*24);
			EndIf;
			
			Item.CurrentData.Period = NewPeriod;
			If LatestRecord <> Undefined Then
				FillPropertyValues(Item.CurrentData, LatestRecord, , "Period, Initial_Value");
			EndIf;
			
			CurrentItem = Items.NameHistoryAbbreviatedDescription;
			
		EndIf;
		
	EndIf;
	
	If Item.CurrentData <> Undefined Then
		NameAbbreviatedBeforeChange = Item.CurrentData.AbbreviatedDescription;
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
Procedure NameHistoryAbbreviatedDescriptionOnChange(Item)
	
	CurrentData = Items.NameHistory.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CompaniesClientLocalization.NameHistoryAbbreviatedDescriptionOnChange(CurrentData, ThisObject);
	
	NameAbbreviatedBeforeChange = CurrentData.AbbreviatedDescription;
	
EndProcedure

&AtClient
Procedure NameHistoryBeforeDeleteRow(Item, Cancel)
	
	If NameHistory.IndexOf(Item.CurrentData) = 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Đã cấm xóa bản ghi ban đầu của lịch sử';
										|ru = 'Удаление начальной записи истории запрещено';
										|en = 'You cannot delete the initial history record'; fa = 'You cannot delete the initial history record';
										|it = 'Удаление начальной записи истории запрещено';
										|pl = 'You cannot delete the initial history record';
										|tr = 'İlk geçmiş kaydının silinmesi yasaktır'"),,,, Cancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	Cancel = False;
	
	CheckHistoryCompletion(Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	SelectionResult = New Structure;
	SelectionResult.Insert("NameHistory", NameHistory);
	NotifyChoice(SelectionResult);
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	#Region Period
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.NameHistoryPeriod.Name);
	
	CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter,
		"NameHistory.Initial_Value", DataCompositionComparisonType.Equal, True);
	
	CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter,
		"NameHistory.Period", DataCompositionComparisonType.Equal, Date(1,1,1));
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Giá trị ban đầu';
																		|ru = 'Начальное значение';
																		|en = 'Initial value'; fa = 'مقدار اولیه';
																		|it = 'Valore iniziale';
																		|pl = 'Wartość początkowa';
																		|tr = 'İlk değer'"));
	ConditionalAppearanceItem.Appearance.SetParameterValue("ReadOnly", True);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, "NameHistoryPeriod");
	
	CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter,
		"NameHistory.Initial_Value", DataCompositionComparisonType.Equal, False);
	CommonClientServer.AddCompositionItem(ConditionalAppearanceItem.Filter,
		"NameHistory.Period", DataCompositionComparisonType.NotFilled);
	#EndRegion
	
	#Region AbbreviatedDescription
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.TitleAbbreviatedName.Name);
	ElementSelection = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ElementSelection.LeftValue = True;
	ElementSelection.RightValue = True;
	ElementSelection.ComparisonType = DataCompositionComparisonType.Equal;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Tên ngắn gọn';
																		|ru = 'Сокращенное';
																		|en = 'Abbreviated'; fa = 'Abbreviated';
																		|it = 'Сокращенное';
																		|pl = 'Abbreviated';
																		|tr = 'Kısaltılmış'"));
	#EndRegion
	
	#Region DescriptionFull
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.TitleFullName.Name);
	ElementSelection = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ElementSelection.LeftValue = True;
	ElementSelection.RightValue = True;
	ElementSelection.ComparisonType = DataCompositionComparisonType.Equal;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Tên đầy đủ';
																		|ru = 'Полное';
																		|en = 'Full'; fa = 'کامل';
																		|it = 'Полное';
																		|pl = 'Full';
																		|tr = 'Tam'"));
	#EndRegion
	
	#Region DescriptionInternational
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(ConditionalAppearanceItem.Fields, Items.TitleNameInternational.Name);
	ElementSelection = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ElementSelection.LeftValue = True;
	ElementSelection.RightValue = True;
	ElementSelection.ComparisonType = DataCompositionComparisonType.Equal;
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = 'Tên quốc tế';
																		|ru = 'Международное';
																		|en = 'International'; fa = 'بین‌المللی';
																		|it = 'Международное';
																		|pl = 'International';
																		|tr = 'Uluslararası'"));
	#EndRegion
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetInitialValueAttribute(HistoryTable)
	
	HistoryTable.Sort("Period");
	// The first line should be the original value
	If HistoryTable.Count() > 0 Then
		FirstRow = HistoryTable[0];
		FirstRow.Initial_Value = True;
		FirstRow.Period = '00010101';
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckHistoryCompletion(Cancel)
	
	LinePeriods = New Array;
	
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
			// There was a line with this date before, this is an error.
			// There cannot be 2 rows with the same date.
			ErrorMessage = NStr("vi = 'Đã có bản ghi với ngày thông tin đã chỉ ra';
								|ru = 'Уже есть запись с указанной датой сведений';
								|en = 'The record with the specified information date already exists'; fa = 'The record with the specified information date already exists';
								|it = 'Esiste già una registrazione con la data delle informazioni indicata';
								|pl = 'Wpis ze wskazaną datą informacji już istnieje';
								|tr = 'Belirtilen bilgi kaydı tarihi ile artık kayıt mevcut'");
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"Period", , Cancel);
		EndIf;
		
		If Not ValueIsFilled(Record.AbbreviatedDescription) Then
			ErrorMessage = NStr("vi = 'Chưa điền trường ""Tên ngắn gọn""';
								|ru = 'Поле ""Сокращенное наименование"" не заполнено';
								|en = 'The ""Abbreviated name"" field is required'; fa = 'The ""Abbreviated name"" field is required';
								|it = 'Поле ""Сокращенное наименование"" не заполнено';
								|pl = 'The ""Abbreviated name"" field is required';
								|tr = '""Kısaltılmış tanım"" alanı doldurulmadı'");
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"AbbreviatedDescription",  , Cancel);
		EndIf;
		
		If Not ValueIsFilled(Record.DescriptionFull) Then
			ErrorMessage = NStr("vi = 'Chưa điền trường ""Tên đầy đủ""';
								|ru = 'Поле ""Полное наименование"" не заполнено';
								|en = 'The ""Full name"" field is required'; fa = 'The ""Full name"" field is required';
								|it = 'Поле ""Полное наименование"" не заполнено';
								|pl = 'The ""Full name"" field is required';
								|tr = '""Tam tanım"" alanı doldurulmadı'");
			CommonClient.MessageToUser(ErrorMessage, , StringMessagePrefix+"DescriptionFull",  , Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion