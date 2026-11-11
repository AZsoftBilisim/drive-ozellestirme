#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("UpdatingObjects", UpdatingObjects) Then
		UpdatingObjects = ProductDataManagementClientServer.DescriptionOfObjectUpdateSettingsConstructor();
	EndIf;
	
	UpdateOption = UpdatingObjects.UpdateOption;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UpdateOptionWhenChanging(Item)
	
	UpdatingObjects.UpdateOption = UpdateOption;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	Modified = False;
	
	Close(UpdatingObjects);
	
EndProcedure

#EndRegion