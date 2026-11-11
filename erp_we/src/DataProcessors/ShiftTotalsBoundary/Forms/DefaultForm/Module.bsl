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
	If Not TotalsAndAggregatesManagementInternal.MustMoveTotalsBorder() Then
		Cancel = True; // The period is already set in the session of another user.
		Return;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	TimeConsumingOperation = LongRunningOperationStartServer(UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("TimeConsumingOperationCompletionClient", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Handler, WaitSettings);
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function LongRunningOperationStartServer(UUID)
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Tổng số và thống kê: đẩy nhanh kết chuyển chứng từ và lập báo cáo';
													|ru = 'Итоги и агрегаты: Ускорение проведения документов и формирования отчетов';
													|en = 'Totals and aggregates: Accelerated document posting and report generation'; fa = 'Totals and aggregates: Accelerated document posting and report generation';
													|it = 'Totali e aggregati: Accelerazione della registrazione dei documenti e della generazione dei report';
													|pl = 'Wyniki i agregaty: Przyspieszenie księgowania dokumentów i tworzenia raportów';
													|tr = 'Toplamlar ve agregalar: Belgelerin gönderilmesini hızlandırma ve raporlar oluşturma'");
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.ShiftTotalsBoundary.ExecuteCommand",
		Undefined, StartSettings1);
	
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure TimeConsumingOperationCompletionClient(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		TimeConsumingOperationAfterOutputResult(False);
		Return;
	EndIf;
	If Result.Status = "Completed2" Then
		ShowUserNotification(NStr("vi = 'Đã hoàn tất thành công việc tối ưu';
									|ru = 'Оптимизация успешно завершена';
									|en = 'Optimization completed successfully'; fa = 'Optimization completed successfully';
									|it = 'Ottimizzazione terminata con successo';
									|pl = 'Optymizacja została pomyślnie zakończona';
									|tr = 'Optimizasyon başarıyla tamamlandı'"),,, PictureLib.Success32);
		TimeConsumingOperationAfterOutputResult(True);
	Else
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	EndIf;
	
EndProcedure

&AtClient
Procedure TimeConsumingOperationAfterOutputResult(Result)
	If CallbackDescriptionOnClose <> Undefined Then
		RunCallback(CallbackDescriptionOnClose, Result); // Bypass specific call from OnOpen.
	EndIf;
	If IsOpen() Then
		Close(Result);
	EndIf;
EndProcedure

#EndRegion