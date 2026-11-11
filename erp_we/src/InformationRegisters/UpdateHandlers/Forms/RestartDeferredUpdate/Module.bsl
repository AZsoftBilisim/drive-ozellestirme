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
	Title = NStr("vi = 'Khởi động lại bản cập nhật hoãn lại';
				|ru = 'Перезапуск отложенного обновления';
				|en = 'Restart deferred update'; fa = 'راه‌اندازی مجدد به‌روزرسانی معوق';
				|it = 'Riavvio aggiornamento posticipato';
				|pl = 'Ponowne uruchomienie odroczonej aktualizacji';
				|tr = 'Ertelenmiş güncellemeyi yeniden başlatma'");
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkSelectionHandlersURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure HyperlinkSelectionHandlersClick(Item)
	CompletionProcessing = New CallbackDescription("AfterSelectHandlers", ThisObject);
	
	ChoiceParameters = New Structure;
	ChoiceParameters.Insert("SelectedHandlers", SelectedHandlers);
	OpenForm("InformationRegister.UpdateHandlers.Form.ChoiceForm", ChoiceParameters,,,,, CompletionProcessing);
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure Restart(Command)
	Items.FormRestart.Enabled = False;
	
	TimeConsumingOperation = TimeConsumingOperation();
	
	CallbackOnCompletion = New CallbackDescription("ProcessResult", ThisObject);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterSelectHandlers(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedHandlers.LoadValues(Result);
	
	If SelectedHandlers.Count() = 0 Then
		Items.HyperlinkSelectionHandlers.Title = NStr("vi = 'Chọn hàm sự kiện';
														|ru = 'Выбрать обработчики';
														|en = 'Select handlers'; fa = 'انتخاب رویدادگردان‌ها';
														|it = 'Selezionare elaboratori';
														|pl = 'Wybierz procesory danych';
														|tr = 'İşleyicileri seç'");
	Else
		Items.HyperlinkSelectionHandlers.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chọn %1 hàm sự kiện';
				|ru = 'Выбрано обработчиков: %1';
				|en = 'Handlers selected: %1'; fa = 'Handlers selected: %1';
				|it = 'Elaboratori selezionati: %1';
				|pl = 'Wybrano procesorów danych: %1';
				|tr = 'İşleyiciler seçildi: %1'"),
			SelectedHandlers.Count());
	EndIf;
	
EndProcedure

&AtServer
Function TimeConsumingOperation()
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	
	Result = TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "InfobaseUpdate.RelaunchDeferredUpdate",
		SelectedHandlers.UnloadValues());
	
	Return Result;
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure ProcessResult(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
		Return;
	EndIf;
	
	Notify("DeferredUpdateRestarted");
	Close();
EndProcedure

#EndRegion