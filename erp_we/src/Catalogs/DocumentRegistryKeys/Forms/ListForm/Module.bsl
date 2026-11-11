
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	KeyTypes = Metadata.Catalogs.DocumentRegistryKeys.Attributes.Key.Type.Types();
	
	Items.ValueType.ChoiceList.Add("", NStr("vi = '<Tất cả các loại>';
											|ru = '<Все типы>';
											|en = '<All types>'; fa = '<همه انواع>';
											|it = '<Tutti i tipi>';
											|pl = '<Wszystkie typy>';
											|tr = '<Tüm tipler>'"));
	
	For Each KeyType In KeyTypes Do
		
		TypeMetadata = Metadata.FindByType(KeyType);
		
		If TypeMetadata <> Undefined Then
			FullName = TypeMetadata.FullName();
			Items.ValueType.ChoiceList.Add(FullName, TypeMetadata.Presentation());
			EmptyValue = PredefinedValue(FullName + ".EmptyRef");
			EmptyKeyValues.Add(EmptyValue);
		EndIf;
		
	EndDo;
	
	SetConditionalAppearance();
		
	CommonClientServer.SetDynamicListParameter(List, "KeyValueType", TypeOf(Undefined));
	
	ThereAreDuplicates = Catalogs.DocumentRegistryKeys.ThereAreDuplicates();
	ThereAreItemsOfDirectoriesWithoutKeys = Catalogs.DocumentRegistryKeys.ThereAreKeysToGenerate();
	
	Items.List.ChangeRowSet = CommonClientServer.DebugMode();
	
	CustomizeForm();
	
	ScheduledJobData = GetScheduledJobData(ScheduledJobID);
	SetSchedulePresentation(ScheduledJobData);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationStartTheProcedureForCreatingDocumentRegistryKeysURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	CreateKeys();
	
EndProcedure

&AtClient
Procedure DecorationDuplicateDeletionErrorURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ShouldNotRunInBackground", True);
	FilterParameters.Insert("StartDate", CorrectionStartTime);
	FilterParameters.Insert("EventLogEvent", NameOfDuplicateDeletionLogEvent());
	EventLogClient.OpenEventLog(FilterParameters);
	
EndProcedure

&AtClient
Procedure SceneryThereAreDuplicatesInTheMainNodeRIBURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	DeleteDuplicates();
EndProcedure

&AtClient
Procedure DecorationCheckTheNeedToReDisplayDocumentsInTheRegistryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	CheckNeedToReReflectDocumentsInRegistry();
EndProcedure

&AtClient
Procedure DecorationErrorReflectingDocumentsInTheRegistryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ShouldNotRunInBackground", True);
	FilterParameters.Insert("StartDate", CorrectionStartTime);
	FilterParameters.Insert("Level", "Error");
	EventLogClient.OpenEventLog(FilterParameters);
EndProcedure

&AtClient
Procedure DecorationErrorCreatingDocumentRegistryKeysURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ShouldNotRunInBackground", True);
	FilterParameters.Insert("StartDate", CorrectionStartTime);
	FilterParameters.Insert("Level", "Error");
	EventLogClient.OpenEventLog(FilterParameters);
	
EndProcedure

&AtClient
Procedure DecorationThereAreDocumentsForReReflectionInTheRegistryURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	FixErrorsInReflectingDocumentsInRegistry();
EndProcedure

&AtClient
Procedure ValueTypeOnChange(Item)
	TypeOfValueWhenChangedOnServer();
EndProcedure

&AtClient
Procedure DecorationSchedulePresentationClick(Item)
	
	OpeningParameters = New Structure("ScheduledJobID", ScheduledJobID);
	
	HandlerNotifications = New CallbackDescription("AfterEditingRoutineTask", ThisObject);
	
	OpenForm("Catalog.DocumentRegistryKeys.Form.FormOfScheduledJobToDeleteDuplicates",
		OpeningParameters,
		ThisObject,,,,
		HandlerNotifications,
		FormWindowOpeningMode.LockOwnerWindow
	);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterEditingRoutineTask(Value, AdditionalParameters) Export
	
	ScheduledJobData = GetScheduledJobData(Value);
	SetSchedulePresentation(ScheduledJobData);
	
EndProcedure

&AtServerNoContext
Function GetScheduledJobData(ScheduledJobID)
	
	Result = New Structure("Use, Schedule", False, Undefined);
	
	SearchParameters = New Structure;
	
	If ValueIsFilled(ScheduledJobID) Then
		
		SearchParameters.Insert("UUID",
			New UUID(ScheduledJobID));
		
	Else
		
		SearchParameters.Insert("Metadata",
			Metadata.ScheduledJobs.DeleteDuplicatesOfDocumentRegistryKeys);
		
	EndIf;
	
	SetPrivilegedMode(True);
	JobsSearch = ScheduledJobsServer.FindJobs(SearchParameters);
	SetPrivilegedMode(False);
	
	If JobsSearch.Count() > 0 Then
		
		ScheduledJobID = String(ScheduledJobsServer.UUID(JobsSearch.Get(0)));
		
		SetPrivilegedMode(True);
		Job = ScheduledJobsServer.Job(ScheduledJobID);
		SetPrivilegedMode(False);
		
		FillPropertyValues(Result, Job);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SetSchedulePresentation(ScheduledJobData)
	
	If ScheduledJobData.Use Then
		SchedulePresentation = New FormattedString(
			String(ScheduledJobData.Schedule),,
			WebColors.Green
		);
	Else
		SchedulePresentation = NStr("vi = 'Không sử dụng ';
									|ru = 'Не используется';
									|en = 'Not used'; fa = 'استفاده نمی‌شود';
									|it = 'Non viene utilizzato';
									|pl = 'Nie używane';
									|tr = 'Kullanılmıyor'");
	EndIf;
	
	Items.DecorationSchedulePresentation.Title = SchedulePresentation;
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	Items.DecorationDuplicateDeletionError.Visible         = (ThereAreDuplicates = "Error");
	Items.TheSceneryHasDuplicatesInTheSubordinateNodeOfTheRIB.Visible = (ThereAreDuplicates = "ThereAreDuplicatesInSubordinateNodeRib");
	Items.SceneryThereAreDuplicatesInTheMainNodeRIB.Visible     = (ThereAreDuplicates = "ThereAreDuplicatesInMainRibNode");
	Items.DecorationNoDuplicates.Visible                    = (ThereAreDuplicates = "None");
	
	Items.DecorationErrorCreatingDocumentRegistryKeys.Visible             = (ThereAreItemsOfDirectoriesWithoutKeys = "Error");
	Items.DecorationThereAreNotEnoughKeysInTheSlaveNodeOfTheRIB.Visible                = (ThereAreItemsOfDirectoriesWithoutKeys = "ThereAreElementsWithoutKeysInSubordinateNodeRib");
	Items.DecorationStartTheProcedureForCreatingDocumentRegistryKeys.Visible = (ThereAreItemsOfDirectoriesWithoutKeys = "ThereAreElementsWithoutKeysInMainRibNode");
	Items.DecorationForAllElementsOfTheDirectoriesKeysAreCreated.Visible          = (ThereAreItemsOfDirectoriesWithoutKeys = "None");
	
	Items.DecorationErrorReflectingDocumentsInTheRegistry.Visible                      = (ThereAreDuplicates = "None")
																						And (ThereAreItemsOfDirectoriesWithoutKeys = "None") 
																						And (ThereAreDocumentsForRemirrorInTheRegistry = "Error"); 
																						
	Items.DecorationThereAreDocumentsForReReflectionInTheRegistry.Visible                    = (ThereAreDuplicates = "None")
																						And (ThereAreItemsOfDirectoriesWithoutKeys = "None") 
																						And (ThereAreDocumentsForRemirrorInTheRegistry = "Is");
																						
	Items.DecorationAllDocumentsInTheRegistryAreReflectedCorrectly.Visible                  =  (ThereAreDuplicates = "None")
																						And (ThereAreItemsOfDirectoriesWithoutKeys = "None") 
																						And (ThereAreDocumentsForRemirrorInTheRegistry = "None");
																						
	Items.DecorationCheckTheNeedToReDisplayDocumentsInTheRegistry.Visible  =  (ThereAreDuplicates = "None")
																						And (ThereAreItemsOfDirectoriesWithoutKeys = "None") 
																						And (ThereAreDocumentsForRemirrorInTheRegistry <> "Error")
																						And (ThereAreDocumentsForRemirrorInTheRegistry <> "Is")
																						And (ThereAreDocumentsForRemirrorInTheRegistry <> "None");
	
EndProcedure

&AtServer
Procedure TypeOfValueWhenChangedOnServer()
	
	If IsBlankString(ValueType) Then
		CommonClientServer.SetDynamicListParameter(List, "KeyValueType", TypeOf(Undefined));
	Else	
		
		KeyMetadata = Metadata.FindByFullName(ValueType);
		
		CommonClientServer.SetDynamicListParameter(List,
			"KeyValueType",
			TypeOf(KeyMetadata.StandardAttributes.Ref.Type.AdjustValue()));
	EndIf;
		
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Description.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.Key");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = EmptyKeyValues;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giá trị trống>';
													|ru = '<пустое значение>';
													|en = '<empty value>'; fa = '<empty value>';
													|it = '<valore vuoto>';
													|pl = '<pusta wartość>';
													|tr = '<boş değer>'"));
	
EndProcedure

&AtServerNoContext
Function NameOfDuplicateDeletionLogEvent()
	Return Catalogs.DocumentRegistryKeys.NameOfDuplicateDeletionLogEvent();
EndFunction

&AtClient
Procedure DeleteDuplicates()
	
	BackgroundJob = DeleteDuplicatesServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterRemovingDuplicates", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function DeleteDuplicatesServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Loại bỏ sự trùng lặp của các khóa sổ đăng ký chứng từ';
																	|ru = 'Удаление дублей ключей реестра документов';
																	|en = 'Delete duplicates of document registry keys'; fa = 'حذف موارد تکراری کلیدهای دفتر ثبت اسناد';
																	|it = 'Eliminazione dei doppioni del registro di documenti';
																	|pl = 'Usunięcie powtórzenia kluczy rejestru dokumentów';
																	|tr = 'Belge kayıt anahtar kopyalarının silinmesi'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("Catalogs.DocumentRegistryKeys.FindAndDeleteDuplicatesInListForm",
		New Structure, BackgroundExecutionParameters);
		
	CorrectionStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterRemovingDuplicates(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			AfterRemovingDuplicatesServer(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = '%Cause% nedeniyle görev tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterRemovingDuplicatesServer(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	ThereAreDuplicates = Result.ThereAreDuplicates;
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure CreateKeys()
	
	BackgroundJob = CreateKeysServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterCreatingKeys", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function CreateKeysServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo khóa đăng ký chứng từ';
																	|ru = 'Создание ключей рееста документов';
																	|en = 'Generating document registry keys'; fa = 'Generating document registry keys';
																	|it = 'Creazione delle chiavi del registro dei documenti';
																	|pl = 'Utworzenie kluczy rejestru dokumentów';
																	|tr = 'Belge kayıt anahtarlarının oluşturulması'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("Catalogs.DocumentRegistryKeys.CreateKeysInListForm",
		New Structure, BackgroundExecutionParameters);
		
	CorrectionStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterCreatingKeys(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			AfterAfterCreatingServerKeys(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = '%Cause% nedeniyle görev tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterAfterCreatingServerKeys(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	ThereAreItemsOfDirectoriesWithoutKeys = Result.ThereAreItemsOfDirectoriesWithoutKeys;
	CustomizeForm();
	
EndProcedure


&AtClient
Procedure CheckNeedToReReflectDocumentsInRegistry()
	
	BackgroundJob = CheckNeedToReReflectDocumentsInRegistryServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterCheckingNeedToReReflectDocumentsInRegistry", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function CheckNeedToReReflectDocumentsInRegistryServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kiểm tra sự phản ánh chính xác của các chứng từ trong sổ đăng ký';
																	|ru = 'Проверка корректности отражения документов в реестре';
																	|en = 'Checking the correct reflection of documents in the registry'; fa = 'Checking the correct reflection of documents in the registry';
																	|it = 'Verifica della correttezza del rilevamento dei documenti nel registro';
																	|pl = 'Sprawdzenie poprawności odbicia dokumentów w rejestrze';
																	|tr = 'Kayıttaki belgelerin yansımasının doğruluğunun kontrol edilmesi'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("Catalogs.DocumentRegistryKeys.CheckNeedToReReflectDocumentsInRegistry",
		New Structure, BackgroundExecutionParameters);
		
	CorrectionStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterCheckingNeedToReReflectDocumentsInRegistry(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			AfterCheckingNeedToReReflectDocumentsInRegistryServer(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = '%Cause% nedeniyle görev tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterCheckingNeedToReReflectDocumentsInRegistryServer(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	ThereAreDocumentsForRemirrorInTheRegistry = Result.ThereAreDocumentsForRemirrorInTheRegistry;
	CustomizeForm();
	
EndProcedure

&AtClient
Procedure FixErrorsInReflectingDocumentsInRegistry()
	
	BackgroundJob = FixErrorsInReflectingDocumentsInRegistryServer();
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = True;
	Handler = New CallbackDescription("AfterFixingErrorcockReflectionOfDocumentsInRegistry", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(BackgroundJob, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function FixErrorsInReflectingDocumentsInRegistryServer()
	
	BackgroundExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(ThisObject.UUID);
	BackgroundExecutionParameters.BackgroundJobDescription = NStr("vi = 'Sửa lỗi phản ánh chứng từ trong sổ đăng ký chứng từ';
																	|ru = 'Исправление отражения документов в реестре документов';
																	|en = 'Correction of documents records in documents registry'; fa = 'Correction of documents records in documents registry';
																	|it = 'Correzione del rilevamento dei documenti nel registro dei documenti';
																	|pl = 'Poprawienie odzwierciedlenia dokumentów w rejestrze dokumentów';
																	|tr = 'Belgelerin kayıttaki yansımalarının düzeltilmesi'");
	BackgroundExecutionParameters.RunInBackground = True;
	
	BackgroundJob = TimeConsumingOperations.ExecuteInBackground("Catalogs.DocumentRegistryKeys.FixErrorsInReflectingDocumentsInRegistry",
		New Structure, BackgroundExecutionParameters);
		
	CorrectionStartTime = CurrentSessionDate();
		
	Return BackgroundJob;
	
EndFunction

&AtClient
Procedure AfterFixingErrorcockReflectionOfDocumentsInRegistry(BackgroundJob, AdditionalParameters) Export
	
	If BackgroundJob <> Undefined 
		And BackgroundJob.Status = "Completed2" Then
	
		If IsTempStorageURL(BackgroundJob.ResultAddress) Then
			AfterFixingErrorcockReflectionOfDocumentsInRegistryServer(BackgroundJob.ResultAddress);
		EndIf;
		
	Else
		If BackgroundJob <> Undefined Then
			ErrorDescription = NStr("vi = 'Không thể hoàn thành nhiệm vụ do: %Cause%';
									|ru = 'Не удалось закончить выполнения задания по причине: %Cause%';
									|en = 'Cannot complete job. Reason: %Cause%'; fa = 'Cannot complete job. Reason: %Cause%';
									|it = 'Non è stato possibile completare il task a causa di: %Cause%';
									|pl = 'Nie udało się ukończyć zadanie z powodu: %Cause%';
									|tr = '%Cause% nedeniyle görev tamamlanamadı'");
			ErrorDescription = StrReplace(ErrorDescription, "%Cause%",  BackgroundJob.DetailErrorDescription);
			ShowMessageBox(, ErrorDescription);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterFixingErrorcockReflectionOfDocumentsInRegistryServer(ResultAddress)
	
	Result = GetFromTempStorage(ResultAddress);
	ThereAreDocumentsForRemirrorInTheRegistry = Result.ThereAreDocumentsForRemirrorInTheRegistry;
	CustomizeForm();
	
EndProcedure

#EndRegion
