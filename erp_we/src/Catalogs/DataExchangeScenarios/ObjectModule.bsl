///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If DeletionMark Then
		
		UseScheduledJob = False;
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
	
		ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
		
		DataSeparationEnabled = Common.DataSeparationEnabled();
		
		If DataSeparationEnabled 
			And UseScheduledJob 
			And IsAutoDisabled Then
			
			IsAutoDisabled = False;
			
			ModuleDataExchangeInternalPublication.DeleteTasksAccordingToScriptWithError(Ref);
			
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// Deleting a scheduled job if necessary.
	If DeletionMark
		Or (Not UseScheduledJob
			And IsAutoDisabled) Then
		
		DeleteScheduledJob(Cancel);
		
	EndIf;
	
	// Update 1C:Enterprise cache so that the "DataExchangeCached.DataExchangeSettings"
	// procedure could read up-to-date data exchange settings.
	RefreshReusableValues();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	GUIDScheduledJob = "";
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DeleteScheduledJob(Cancel);
	
EndProcedure

#EndRegion

#Region Private

// Deletes a scheduled job.
//
// Parameters:
//  Cancel                     - Boolean - a cancellation flag. It is set to True if errors
//                                       occur upon the procedure execution.
//  ScheduledJobObject - a scheduled job object to be deleted.
// 
Procedure DeleteScheduledJob(Cancel)
	
	SetPrivilegedMode(True);
			
	// Define a scheduled job.
	ScheduledJobObject = Catalogs.DataExchangeScenarios.ScheduledJobByID(GUIDScheduledJob);
	
	If ScheduledJobObject <> Undefined Then
		
		Try
			If Common.DataSeparationEnabled() Then
				ScheduledJobsServer.DeleteJob(ScheduledJobObject);
			Else
				ScheduledJobObject.Delete();
			EndIf;	
		Except
			MessageString = NStr("vi = 'Lỗi khi xóa nhiệm vụ thường kỳ: %1';
								|ru = 'Ошибка при удалении регламентного задания: %1';
								|en = 'Cannot delete the scheduled job: %1'; fa = 'Cannot delete the scheduled job: %1';
								|it = 'Errore durante l''eliminazione del compito di routine: %1';
								|pl = 'Błędy podczas usuwania zadania reglamentowanego: %1';
								|tr = 'Zamanlanmış görev kaldırırken bir hata oluştu: %1'");
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			DataExchangeServer.ReportError(MessageString, Cancel);
		EndTry;
	
	EndIf;
		
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf