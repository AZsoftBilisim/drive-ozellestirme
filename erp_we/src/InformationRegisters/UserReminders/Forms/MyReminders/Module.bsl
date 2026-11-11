///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	List.Parameters.SetParameterValue("User", Users.CurrentUser());
	Items.AllReminders.Visible = Users.IsFullUser();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	Cancel = True;
	OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("Key", Items.List.CurrentRow));
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	RowIsSelected = Not Item.CurrentRow = Undefined;
	Items.DeleteButton.Enabled = RowIsSelected;
	Items.ChangeButton.Enabled = RowIsSelected;
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	DeleteReminder();
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	If Field.Name = "Source" Then
		StandardProcessing = False;
		If ValueIsFilled(Items.List.CurrentData.Source) Then
			ShowValue(, Items.List.CurrentData.Source);
		Else
			ShowMessageBox(, NStr("vi = 'Chưa xác định nguồn nhắc nhở.';
									|ru = 'Источник напоминания не задан.';
									|en = 'Please specify the reminder source.'; fa = 'Please specify the reminder source.';
									|it = 'Nessuna fonte di promemoria specificata.';
									|pl = 'Źródło przypomnienia nie jest ustawione.';
									|tr = 'Hatırlatıcı kaynağı belirlenmemiş.'"));
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)
	OpenForm("InformationRegister.UserReminders.Form.Reminder", New Structure("Key", Items.List.CurrentRow));
EndProcedure

&AtClient
Procedure Delete(Command)
	DeleteReminder();
EndProcedure

&AtClient
Procedure Create(Command)
	OpenForm("InformationRegister.UserReminders.Form.Reminder");
EndProcedure

&AtClient
Procedure AllReminders(Command)
	
	OpenForm("InformationRegister.UserReminders.Form.AllReminders");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisableReminder(ReminderParameters)
	UserRemindersInternal.DisableReminder(ReminderParameters, False, True);
EndProcedure

&AtClient
Procedure DeleteReminder()
	
	DialogButtons = New ValueList;
	DialogButtons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa bỏ';
												|ru = 'Удалить';
												|en = 'Delete'; fa = 'حذف';
												|it = 'Eliminare';
												|pl = 'Delete';
												|tr = 'Sil'"));
	DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Không xóa';
													|ru = 'Не удалять';
													|en = 'Do not delete'; fa = 'حذف نشود';
													|it = 'Non eliminare';
													|pl = 'Nie usuwaj';
													|tr = 'Silme'"));
	CallbackDescription = New CallbackDescription("DeleteReminderCompletion", ThisObject);
	
	ShowQueryBox(CallbackDescription, NStr("vi = 'Xóa bỏ nhắc việc?';
											|ru = 'Удалить напоминание?';
											|en = 'Delete the reminder?'; fa = 'Delete the reminder?';
											|it = 'Rimuovere promemoria?';
											|pl = 'Usunąć przypomnienie?';
											|tr = 'Hatırlatıcı silinsin mi?'"), DialogButtons);
	
EndProcedure

&AtClient
Procedure DeleteReminderCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	RecordKey = Items.List.CurrentRow;
	ReminderParameters = New Structure("User,EventTime,Source");
	FillPropertyValues(ReminderParameters, Items.List.CurrentData);
	
	DisableReminder(ReminderParameters);
	UserRemindersClient.DeleteRecordFromNotificationsCache(ReminderParameters);
	Notify("Write_UserReminders", New Structure, RecordKey);
	NotifyChanged(Type("InformationRegisterRecordKey.UserReminders"));
	
EndProcedure

#EndRegion
