#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	If Modified And Not ClosingInProgress Then
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			QueryText, 
			QuestionDialogMode.YesNoCancel);
		Cancel = True;
		Return;
	EndIf; 
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		If Not WriteData() Then
			Return;
		EndIf; 
	EndIf;
	
	ClosingInProgress = True;
	Close();
	
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

#Region FormTableItemsEventHandlersSettingsComposerUserSettings

&AtClient
Procedure SettingsComposerUserSettingsOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Function WriteData()

	ThisForm.FormOwner.SettingsComposer = SettingsComposer;

	Modified = False;
	
	Return True;
	
EndFunction

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

#Region Initialize

ClosingInProgress = False;

#EndRegion