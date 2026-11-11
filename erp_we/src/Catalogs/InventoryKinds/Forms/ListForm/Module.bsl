#Region Variables

&AtClient
Var TimeConsumingOperationForm;

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BackgroundJob = New Structure("
		|JobName,
		|JobID,
		|StorageAddress");
	
	If Not AccessRight("Update", Metadata.AccumulationRegisters.CompanyGoods) Then
		Items.FormReplaceInventoryKindDuplicates.Enabled = False;
		Items.FormUpdateInformationOnObsoleteInventoryKinds.Enabled = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReplaceInventoryKindDuplicates(Command)
	
	JobParameters = New Structure;
	
	RunBackgroundJob1("ReplaceInventoryKindDuplicates", JobParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure UpdateInformationOnObsoleteInventoryKinds(Command)
	
	JobParameters = New Structure;
	
	RunBackgroundJob1("UpdateInformationOnObsoleteInventoryKinds", JobParameters);
	
EndProcedure

#EndRegion

#Region Private

#Region Other

#Region BackgroundJobs

&AtClient
Procedure RunBackgroundJob1(JobName, JobParameters)
	
	JobCompleted = RunBackgroundJobOnServer(JobName, JobParameters);
	
	If JobCompleted Then
		ProcessJobCompletionOnClient();
	Else
		OpenTimeConsumingOperationForm();
	EndIf;

EndProcedure

&AtServer
Function RunBackgroundJobOnServer(Val JobName, Val JobParameters)
	
	If JobName = "ReplaceInventoryKindDuplicates" Then
		
		TaskStartResult = RunTaskReplaceDuplicatesOfViewsOnServer(JobParameters);
		
	ElsIf JobName = "UpdateInformationOnObsoleteInventoryKinds" Then	
		
		TaskStartResult = StartTaskUpdateInformationAboutObsoleteInventoryTypes(JobParameters);
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Nhiệm vụ không xác định ""%1""';
								|ru = 'Неизвестное задание ""%1""';
								|en = 'Unknown job ""%1""'; fa = 'Unknown job ""%1""';
								|it = 'Task sconosciuto ""%1""';
								|pl = 'Nieznane zadanie ""%1""';
								|tr = '""%1"" bilinmeyen görevi'"),
							JobName);
	EndIf;
	
	BackgroundJob.JobName           = JobName;
	BackgroundJob.JobID = TaskStartResult.JobID;
	BackgroundJob.StorageAddress       = TaskStartResult.StorageAddress;
	
	Return TaskStartResult.JobCompleted;

EndFunction

&AtClient
Procedure ProcessJobCompletionOnClient()

	If BackgroundJob.JobName = "ReplaceInventoryKindDuplicates" Then
		TaskCompletionReplaceDuplicatesOfInventoryTypesServer(BackgroundJob.StorageAddress);
	ElsIf BackgroundJob.JobName = "UpdateInformationOnObsoleteInventoryKinds" Then
		TaskCompletionUpdateInformationAboutObsoleteInventoryTypes(BackgroundJob.StorageAddress);
	EndIf;

EndProcedure

&AtClient
Procedure OpenTimeConsumingOperationForm()
	
	TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleHandlerParameters);
	
	IdleHandlerParameters.IntervalIncreaseCoefficient = 1.2;
	AttachIdleHandler("Attachable_CheckTaskCompletion", 1, True);
	
	TimeConsumingOperationForm = TimeConsumingOperationsClient.OpenTimeConsumingOperationForm(
		ThisObject, BackgroundJob.JobID);
	
EndProcedure

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	Try
		
		If TimeConsumingOperationForm.IsOpen() Then
			
			If JobCompleted(BackgroundJob.JobID) Then
				ProcessJobCompletionOnClient();
				TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
			Else
				TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
				AttachIdleHandler("Attachable_CheckTaskCompletion",
					IdleHandlerParameters.CurrentInterval, True);
			EndIf;
				
		EndIf;
		
	Except
		
		TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
		Raise;
		
	EndTry;
	
EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

#Region CompletingTasks

&AtServer
Function RunTaskReplaceDuplicatesOfViewsOnServer(JobParameters)
	
	JobDescription = NStr("vi = 'Thay thế các phần tử trùng lặp của dạng vật tư';
							|ru = 'Замена дублей видов запасов';
							|en = 'Replace duplicate inventory owner attributes'; fa = 'Replace duplicate inventory owner attributes';
							|it = 'Sostituzione dei duplicati dei tipi delle scorte';
							|pl = 'Zamiana duplikatów rodzajów zapasów';
							|tr = 'Çifte stok türlerinin değişimi'");
	
	TaskStartResult = TimeConsumingOperations.StartBackgroundExecution(
									UUID,
									"Catalogs.InventoryKinds.ReplaceInventoryKindDuplicates",
									JobParameters,
									JobDescription);
			
	Return TaskStartResult;
		
EndFunction

&AtClient
Procedure TaskCompletionReplaceDuplicatesOfInventoryTypesServer(StorageAddress)
	
	Result = CompletingJobOnServer(StorageAddress);
	
	Picture = PictureLib.Information32;
	TitleText = NStr("vi = 'Đã thay thế các phần tử trùng lặp của dạng vật tư';
					|ru = 'Дубли видов запасов заменены';
					|en = 'Duplicate inventory owner attributes are replaced'; fa = 'Duplicate inventory owner attributes are replaced';
					|it = 'Duplicati dei tipi delle scorte sono sostituiti';
					|pl = 'Duplikaty rodzajów zapasów zostały zamienione';
					|tr = 'Çifte stok türleri değiştirildi'");
	MessageText = NStr("vi = 'Đã kết thúc thao tác thay thế các phần tử trùng lặp của danh mục ""Dạng vật tư"".';
						|ru = 'Операция по замене дублирующихся элементов справочника ""Виды запасов"" завершена.';
						|en = 'Duplicate items found in catalog ""Inventory owner attributes"" are replaced.'; fa = 'Duplicate items found in catalog ""Inventory owner attributes"" are replaced.';
						|it = 'L''operazione sulla sostituzione di elementi duplicati della directory ""Tipi delle scorte"" è stata completata.';
						|pl = 'Operacja zamiany zduplikowanych elementów katalogu ""Виды запасов"" została zakończona.';
						|tr = '""Stok türleri"" kataloğunun tekrarlanan öğelerini değiştirme işlemi tamamlandı.'");
	
	ShowUserNotification(TitleText, Undefined, MessageText, Picture);
	
EndProcedure

&AtServer
Function StartTaskUpdateInformationAboutObsoleteInventoryTypes(JobParameters)
	
	JobDescription = NStr("vi = 'Cập nhật thông tin về các dạng hàng tồn kho lỗi thời với số dư';
							|ru = 'Обновление информации об устаревших видах запасов с остатками';
							|en = 'Update information on obsolete inventory owner attributes with balance'; fa = 'Update information on obsolete inventory owner attributes with balance';
							|it = 'Aggiornamento delle informazioni sui tipi delle scorte obsoleti con rimanenze';
							|pl = 'Aktualizacja informacji o przestarzałych rodzajach zapasów z ostatkami';
							|tr = 'Bakiyelerle eski stok türlerine ilişkin bilgilerin güncellenmesi'");
	
	TaskStartResult = TimeConsumingOperations.StartBackgroundExecution(
									UUID,
									"InformationRegisters.ObsoleteInventoryOwnerAttributesWithBalance.UpdateRecords",
									JobParameters,
									JobDescription);
			
	Return TaskStartResult;
		
EndFunction

&AtClient
Procedure TaskCompletionUpdateInformationAboutObsoleteInventoryTypes(StorageAddress)
	
	Result = CompletingJobOnServer(StorageAddress);
	
	Picture = PictureLib.Information32;
	TitleText = NStr("vi = 'Thông tin đã cập nhật';
					|ru = 'Информация обновлена';
					|en = 'Information is updated'; fa = 'Information is updated';
					|it = 'Informazioni aggiornate';
					|pl = 'Informacja została zaktualizowana';
					|tr = 'Bilgi güncellendi'");
	MessageText = NStr("vi = 'Cập nhật các dạng hàng tồn kho lỗi thời với số dư đã hoàn thành';
						|ru = 'Обновление информации об устаревших видах запасов с остатками завершено';
						|en = 'Information on obsolete inventory owner attributes with balance is updated'; fa = 'Information on obsolete inventory owner attributes with balance is updated';
						|it = 'Aggiornamento delle informazioni sui tipi delle scorte obsoleti con rimanenze è completato';
						|pl = 'Aktualizacja informacji o przestarzałych rodzajach zapasów z ostatkami zostało zakończone';
						|tr = 'Bakiyeleri tamamlanmış eski stok türlerinin güncellenmesi'");
	
	ShowUserNotification(TitleText, Undefined, MessageText, Picture);
	
EndProcedure

&AtServer
Function CompletingJobOnServer(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	
	Items.List.Refresh();
	Items.IntercompanyList.Refresh();
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#EndRegion
