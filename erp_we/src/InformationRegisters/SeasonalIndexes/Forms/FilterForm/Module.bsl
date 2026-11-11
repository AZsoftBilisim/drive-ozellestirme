#Region Variables

&AtClient
Var RepeatCallBeforeRecording; // Used for non-modal questions before recording

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If RepeatCallBeforeRecording = True Then
		RepeatCallBeforeRecording = False;
		Return;
	EndIf;
	
	If Modified Then
		
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Lưu lại';
												|ru = 'Сохранить';
												|en = 'Save'; fa = 'ذخیره';
												|it = 'Salvare';
												|pl = 'Save';
												|tr = 'Sakla'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Không lưu lại';
												|ru = 'Не сохранять';
												|en = 'Do not save'; fa = 'Do not save';
												|it = 'Non salvare';
												|pl = 'Nie zapisuj';
												|tr = 'Kaydetme'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Anuluj';
													|tr = 'İptal'"));
		
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(Notification,
			QueryText,
			Buttons);
		
		Cancel = True;
		RepeatCallBeforeRecording = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SettingsComposer = Parameters.SettingsComposer;
	
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure OkCommand(Command)
	
	WriteData();
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Modified = False;
	Close();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsComposerUserSettings

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	Modified = True;
	
EndProcedure


&AtClient
Procedure BeforeCloseCompletion(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
	
		WriteData();
		Close();
		
	ElsIf Result = DialogReturnCode.No Then
	
		Close();
		
	Else
		
		RepeatCallBeforeRecording = False;
	
	EndIf; 
	
EndProcedure

&AtClient
Function WriteData()

	ThisForm.FormOwner.SettingsComposer = SettingsComposer;

	Modified = False;
	
	Return True;
	
EndFunction

#EndRegion
