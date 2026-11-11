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
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), QueryText, QuestionDialogMode.YesNoCancel);
		
		RepeatCallBeforeRecording = True;
		Cancel = True;
		
	EndIf;
	
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

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SettingsComposer = Parameters.SettingsComposer;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
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

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsComposerUserSettings

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Function WriteData()

	ThisForm.FormOwner.SettingsComposer = SettingsComposer;

	Modified = False;
	
	Notify("EstablishedSelection_FormationOfOrdersForProductionAccordingToPlan");
	
	Return True;
	
EndFunction

#EndRegion