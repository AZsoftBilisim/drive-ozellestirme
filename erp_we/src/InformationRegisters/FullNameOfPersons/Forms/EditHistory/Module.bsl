
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("Individual", Individual);
	
	If Not ValueIsFilled(Individual) Then
		Cancel = True;
		Return;
	EndIf;
	
	RecordSet.Load(Parameters.RecordSet.Unload());
	
	If Not AccessRight("Update", Metadata.InformationRegisters.FullNameOfPersons) Then
		ReadOnly = True;
	EndIf; 
	
	If ReadOnly Then
		
		Items.RecordSet.ReadOnly = True;
		
		CommonClientServer.SetFormItemProperty(
			Items, 
			"FormOkCommand",
			"Enabled",
			False);
			
		Items.FormCancelCommand.DefaultButton = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Modified Then
		
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("QuestionOfClosureCompletion", ThisForm),
			NStr("vi = 'Đã thay đổi dữ liệu. Lưu lại thay đổi?';
				|ru = 'Данные были изменены. Сохранить изменения?';
				|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
				|it = 'I dati sono stati modificati. Salvare le modifiche?';
				|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure


#EndRegion

#Region EventHandlersFormTablesRecordset

&AtClient
Procedure RecordSetOnStartEdit(Item, NewRow, Copy)
	
	If Not NewRow Or Item.CurrentData = Undefined Then
		Return;
	EndIf;

	If RecordSet.Count() > 1 Then
		
		RecordFullNameOfIndividuals = RecordSet.Get(RecordSet.Count() - 2);
		LastPeriod = RecordFullNameOfIndividuals.Period;
		
		If Not Copy Then
			Item.CurrentData.LastName 	= RecordFullNameOfIndividuals.LastName;
			Item.CurrentData.Name 		= RecordFullNameOfIndividuals.Name;
			Item.CurrentData.MiddleName 	= RecordFullNameOfIndividuals.MiddleName;
		EndIf;
		
	Else
		LastPeriod = '00010101000000';
	EndIf; 
	
	Item.CurrentData.Period = Max(BegOfDay(CurrentDate()), EndOfDay(LastPeriod) + 1);
	Item.CurrentData.Individual = Individual;
	
EndProcedure

&AtClient
Procedure RecordSetBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Or Item.CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Item.CurrentData.Period) Then
		
		ErrorMessage = NStr("vi = 'Cần chỉ ra ngày thông tin';
							|ru = 'Необходимо указать дату сведений';
							|en = 'Enter information date'; fa = 'Enter information date';
							|it = 'È necessario indicare la data delle informazioni';
							|pl = 'Należy podać datę informacji';
							|tr = 'Bilgi tarihi belirtilmelidir'");
		CommonClientServer.MessageToUser(ErrorMessage,,"RecordSet.Period", , Cancel);
		
	ElsIf Not ValueIsFilled(Item.CurrentData.LastName)
	 And Not ValueIsFilled(Item.CurrentData.Name) 
	 And Not ValueIsFilled(Item.CurrentData.MiddleName) Then
		
		ErrorMessage = NStr("vi = 'Cần chỉ định ít nhất một phần của họ tên';
							|ru = 'Необходимо указать хотя бы одну часть ФИО';
							|en = 'Specify at least one part of the full name'; fa = 'Specify at least one part of the full name';
							|it = 'È necessario indicare almeno una parte delle credenziali';
							|pl = 'Należy podać chociażby jedną część nazwiska i imienia';
							|tr = 'Tam adın en az bir bölümü belirtilmelidir'");
		CommonClientServer.MessageToUser(ErrorMessage,,"RecordSet", , Cancel);
		
	Else
		
		FoundRows = RecordSet.FindRows(New Structure("Period", Item.CurrentData.Period));
		For Each FoundRow In FoundRows Do
			If FoundRow <> Item.CurrentData Then
				ErrorMessage = NStr("vi = 'Đã có bản ghi với ngày thông tin đã chỉ ra';
									|ru = 'Уже есть запись с указанной датой сведений';
									|en = 'The record with the specified information date already exists'; fa = 'The record with the specified information date already exists';
									|it = 'Esiste già una registrazione con la data delle informazioni indicata';
									|pl = 'Wpis ze wskazaną datą informacji już istnieje';
									|tr = 'Belirtilen bilgi kaydı tarihi ile artık kayıt mevcut'");
				CommonClientServer.MessageToUser(ErrorMessage,,"RecordSet.Period", , Cancel);
				Break;
			EndIf; 
		EndDo;
		
	EndIf; 
	
EndProcedure

&AtClient
Procedure RecordSetOnEditEnd(Item, NewRow, CancelEdit)
	
	If Not CancelEdit Then
		Modified = True;
	EndIf;
	
	CurrentRowID = Items.RecordSet.CurrentRow;
	If CurrentRowID = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = RecordSet.FindByID(CurrentRowID);
	If CurrentRow = Undefined Then
		Return;
	EndIf; 
	
	CurrentRowIndex = RecordSet.IndexOf(CurrentRow);
	RecordsCount = RecordSet.Count();
	ShiftingRecord = RecordSet[CurrentRowIndex];
	
	Offset = 0;
	
	If CurrentRowIndex > 0 Then
		For ShiftingRecordIndex = RecordsCount - CurrentRowIndex To RecordsCount - 1 Do
			Record = RecordSet[RecordsCount - 1 - ShiftingRecordIndex];
			If ShiftingRecord.Period > Record.Period Then
				Break;
			EndIf; 
			Offset = Offset - 1;
		EndDo;
	EndIf;
	
	If Offset = 0 And CurrentRowIndex < RecordsCount - 1 Then
		For IndexOfRecord = CurrentRowIndex + 1 To RecordsCount - 1 Do
			Record = RecordSet[IndexOfRecord];
			If ShiftingRecord.Period < Record.Period Then
				Break;
			EndIf; 
			Offset = Offset + 1;
		EndDo;
	EndIf;
	
	If Offset <> 0 Then
		RecordSet.Move(CurrentRowIndex, Offset);
	EndIf; 
	
EndProcedure

&AtClient
Procedure RecordSetAfterDeleteRow(Item)
	
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	NotificationParameter1 = New Structure("RegisterName, RecordSet", "FullNameOfPersons", RecordSet);
	Notify("EditedHistory", NotificationParameter1, Individual);
	
	Modified = False;
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure QuestionOfClosureCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		OkCommand(Undefined);
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		CancelCommand(Undefined);
	EndIf;
	
EndProcedure

#EndRegion
