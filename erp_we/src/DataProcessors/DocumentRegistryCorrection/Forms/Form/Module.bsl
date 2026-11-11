
#Region FormCommandsEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CleaningNonExistentLinks = True;
	ReDisplayingDocuments     = True;
	
EndProcedure

&AtClient
Procedure ExecuteOperation(Command)
	JobID = Undefined;
	
	If CleaningNonExistentLinks Then
		AttachIdleHandler("ClearNonExistentRefs", 0.1, True);
	ElsIf ReDisplayingDocuments Then
		AttachIdleHandler("RedefineDocumentsInRegistry", 0.1, True);
	EndIf;
EndProcedure

#EndRegion


#Region Private

&AtClient
Procedure ClearNonExistentRefs()
	
	TimeConsumingOperation = ClearNonExistentLinksOnServer();
	JobID = TimeConsumingOperation.JobID;
	
	IdleParameters  = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Đang thực hiện xóa việc đăng ký chứng từ khỏi các tham chiếu không tồn tại.';
										|ru = 'Выполняется очистка реестра документов от несуществующих ссылок.';
										|en = 'Deleting non-existing references from document registry.'; fa = 'Deleting non-existing references from document registry.';
										|it = 'Pulizia del registro documenti da collegamenti inesistenti in corso.';
										|pl = 'Odbywa się czyszczenie rejestru dokumentów od nieistniejących linków.';
										|tr = 'Belge kayıt defteri var olmayan bağlantılardan temizlenir.'");
	IdleParameters.OutputIdleWindow = True;
	
	CallbackOnCompletion = New CallbackDescription("CleaningNonExistentLinksCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function ClearNonExistentLinksOnServer()
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	ParametersStructure = New Structure;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DataProcessorName", StrSplit(FormName, ".")[1]);
	ProcedureParameters.Insert("MethodName", "ClearNonExistentLinksInDocumentRegistryInBackground");
	ProcedureParameters.Insert("ExecutionParameters", ParametersStructure);
	ProcedureParameters.Insert("IsExternalDataProcessor", False);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Xóa các liên kết không tồn tại trong sổ đăng ký chứng từ';
														|ru = 'Очистка несуществующих ссылок в реестре документов';
														|en = 'Deleting non-existing references from document registry'; fa = 'Deleting non-existing references from document registry';
														|it = 'Pulizia del registro documenti da collegamenti inesistenti';
														|pl = 'Czyszczenie nieistniejących linków w rejestrze dokumentów';
														|tr = 'Belge kaydında var olmayan bağlantıları temizleme'");
	
	Return TimeConsumingOperations.ExecuteInBackground("TimeConsumingOperations.RunDataProcessorObjectModuleProcedure", 
		ProcedureParameters, ExecutionParameters);
	
EndFunction
	
&AtClient
Procedure CleaningNonExistentLinksCompletion(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else
		ExecutionResult = GetFromTempStorage(Result.ResultAddress);
		
		MessageTemplate = NStr("vi = 'Xóa các liên kết không tồn tại. Đã xóa hồ sơ: %1.';
								|ru = 'Завершена очистка несуществующих ссылок. Удалено записей: %1.';
								|en = 'Deleting non-existing references complete. Total records deleted: %1.'; fa = 'Deleting non-existing references complete. Total records deleted: %1.';
								|it = 'Pulizia del registro documenti da collegamenti inesistenti effettuata. Voci eliminate: %1.';
								|pl = 'Zakończono czyszczenie nieistniejących linków. Usunięte wpisy: %1.';
								|tr = 'Mevcut olmayan bağlantıların temizlenmesi tamamlandı. Silinen kayıtlar: %1.'");
		
		Message = New UserMessage();
		Message.Text = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
			ExecutionResult.RefsCount);
		Message.Message();
		
		If ReDisplayingDocuments Then
			AttachIdleHandler("RedefineDocumentsInRegistry", 0.1, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure RedefineDocumentsInRegistry()
	
	TimeConsumingOperation = RedefineDocumentsInRegistryOnServer();
	JobID = TimeConsumingOperation.JobID;
	
	IdleParameters  = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Phản ánh của các chứng từ trong sổ đăng ký.';
										|ru = 'Выполняется отражение документов в реестре.';
										|en = 'Recording documents in registry.'; fa = 'Recording documents in registry.';
										|it = 'Riflessione dei documenti nel registro in corso.';
										|pl = 'Wykonuje się odzwierciedlenie dokumentów w rejestrze.';
										|tr = 'Belgeler kayıt defterine yansıtılır.'");
	IdleParameters.OutputIdleWindow = True;
	
	CallbackOnCompletion = New CallbackDescription("ReReflectionOfDocumentsInRegistryEnds", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function RedefineDocumentsInRegistryOnServer()
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	ParametersStructure = New Structure;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DataProcessorName", StrSplit(FormName, ".")[1]);
	ProcedureParameters.Insert("MethodName", "RedefineDocumentsInDocumentRegistry");
	ProcedureParameters.Insert("ExecutionParameters", ParametersStructure);
	ProcedureParameters.Insert("IsExternalDataProcessor", False);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Phản ánh lại chứng từ trong sổ đăng ký chứng từ';
														|ru = 'Переотражение документов в реестре документов';
														|en = 'Re-recording documents in documents registry'; fa = 'Re-recording documents in documents registry';
														|it = 'Nuovo rilevamento dei documenti nel registro dei documenti';
														|pl = 'Ponowne odzwierciedlenie dokumentów w rejestrze dokumentów';
														|tr = 'Belge kaydında belgelerin yeniden yansıtılması'");
	
	Return TimeConsumingOperations.ExecuteInBackground("TimeConsumingOperations.RunDataProcessorObjectModuleProcedure", 
		ProcedureParameters, ExecutionParameters);
	
EndFunction
	
&AtClient
Procedure ReReflectionOfDocumentsInRegistryEnds(Result, AdditionalParameters) Export
	If Result = Undefined Then
		Return;
	ElsIf Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	Else
		Message = New UserMessage();
		Message.Text = NStr("vi = 'Đã hoàn tất phản ánh các chứng từ trong sổ đăng ký.';
							|ru = 'Отражение документов в реестре завершено.';
							|en = 'Recording documents in registry complete.'; fa = 'Recording documents in registry complete.';
							|it = 'Riflessione dei documenti nel registro effettuata';
							|pl = 'Odzwierciedlenie dokumentów w rejestrze zostało zakończone.';
							|tr = 'Belgelerin kayda yansıtılması tamamlanmıştır.'");
		Message.Message();
	EndIf;
	
EndProcedure

#EndRegion