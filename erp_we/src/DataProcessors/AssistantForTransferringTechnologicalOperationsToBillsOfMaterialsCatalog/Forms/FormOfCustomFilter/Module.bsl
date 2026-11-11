
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseRouteSheets") Then
		Cancel = True;
		Return;
	EndIf;
	
	InitializeSettingsComposer(Parameters);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject),
			NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
				|ru = 'Данные были изменены. Сохранить изменения?';
				|en = 'The data has changed. Do you want to save the changes?'; fa = 'The data has changed. Do you want to save the changes?';
				|it = 'I dati sono stati modificati. Salvare le modifiche?';
				|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
				|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"),
			QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveAndLoad(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeSettingsComposer(Var_Parameters)
	
	Schema      = DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.GetTemplate("CustomFiltersLayoutTemplate");
	SchemaURL = PutToTempStorage(Schema, UUID);
	
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	If ValueIsFilled(Var_Parameters.CompositionSettings) Then
		SettingsComposer.LoadSettings(Var_Parameters.CompositionSettings);
	Else
		SettingsComposer.LoadSettings(Schema.DefaultSettings);
	EndIf;
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	Result = FinishEditingOnServer();
	
	If Result <> Undefined Then
		
		Modified = False;
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Function FinishEditingOnServer()
	
	Return SettingsComposer.GetSettings();
	
EndFunction

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion