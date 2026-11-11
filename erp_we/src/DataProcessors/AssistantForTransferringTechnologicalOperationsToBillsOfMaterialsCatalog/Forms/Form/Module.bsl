
#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseAdditionalAttributesAndInfo") Then
		Raise(
			NStr("vi = 'Để làm việc với trợ giúp chuyển đổi giao dịch, cần bật sử dụng mục tin và thông tin bổ sung.';
				|ru = 'Для работы помощника переноса операций необходимо включить использование дополнительных реквизитов и сведений.';
				|en = 'Enable additional attributes and information records to use operations transfer assistant.'; fa = 'Enable additional attributes and information records to use operations transfer assistant.';
				|it = 'Affinché l''assistente per il trasferimento delle operazioni funzioni, è necessario abilitare l''uso di requisiti e informazioni aggiuntivi.';
				|pl = 'Do pracy asystenta przeniesienia operacji należy włączyć używanie dodatkowych atrybutów i danych.';
				|tr = 'İşlem aktarma sihirbazının çalışması için ek özniteliklerin ve bilgilerin kullanımını etkinleştirmeniz gerekmektedir.'"));
	EndIf;
	
	If Not GetFunctionalOption("UseRouteSheets") Then
		Raise(
			NStr("vi = 'Đã vô hiệu hóa sử dụng thẻ lộ trình, có thể là đã kết thúc chuyển đổi sang lưu trữ các giao dịch trong bảng kê chi tiết.';
				|ru = 'Использование маршрутных карт отключено, возможно переход на хранение операций в спецификациях уже завершен.';
				|en = 'Using route sheets is disabled, the transition to storing operations in the bills of materials has already been completed.'; fa = 'Using route sheets is disabled, the transition to storing operations in the bills of materials has already been completed.';
				|it = 'Uso di schede di lavorazione è disattivato, è possibile che il passaggio alla memorizzazione delle operazioni nelle specifiche sia stato già completato.';
				|pl = 'Używanie kart technologicznych jest odłączone, być może przejście do przechowywania operacji w specyfikacjach jest już zakończone.';
				|tr = 'Rotalarının kullanımı devre dışı bırakıldı, ürün reçetelerinde işlemlerin depolanmasına geçiş zaten tamamlanmış olabilir.'"));
	EndIf;
	
	FillInServiceDetails();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Not ThereAreRouteMaps Then
		Settings.Insert("MarkStep_1", True);
		Settings.Insert("MarkStep_2", True);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not MarkStep_1 Then
		StartUpdatingInformationOnSelectedRouteMaps();
	ElsIf Not MarkStep_2 And MarkStep_1 Then
		StartUpdatingInformationOnConflicts();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region Marks

&AtClient
Procedure CheckDoneStep1Click(Item)
	
	ResetMark(ThisObject, 1);
	
	StartUpdatingInformationOnSelectedRouteMaps();
	
EndProcedure

&AtClient
Procedure CheckNotDoneStep1Click(Item)
	
	SetCheck(ThisObject, 1);
	
	StartUpdatingInformationOnConflicts();
	
EndProcedure

&AtClient
Procedure CheckDoneStep2Click(Item)
	
	ResetMark(ThisObject, 2);
	
	StartUpdatingInformationOnConflicts();
	
EndProcedure

&AtClient
Procedure CheckNotDoneStep2Click(Item)
	
	SetCheck(ThisObject, 2);
	
EndProcedure

&AtClient
Procedure CheckDoneStep3Click(Item)
	
	ResetMark(ThisObject, 3);
	
EndProcedure

&AtClient
Procedure CheckNotDoneStep3Click(Item)
	
	SetCheck(ThisObject, 3);
	
EndProcedure

#EndRegion

&AtClient
Procedure OptionForSelectingRouteMapsWhenChanging(Item)
	
	SelectedRouteMapsQuantity = 0;
	
	StartUpdatingInformationOnSelectedRouteMaps();
	
	ConfigureDependentFormElements(ThisObject, "CreationOfStandardTechnologicalProcesses");
	
EndProcedure

&AtClient
Procedure ArbitraryFilterClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("CompositionSettings", CompositionSettings);
	
	CallbackDescription = New CallbackDescription("ArbitraryFilterCompletion", ThisObject);
		
	OpenForm("DataProcessor.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.Form.FormOfCustomFilter",
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure LabelSelectedRouteMapsClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	If Not RouteMapSelectionOption = RouteMapSelectionOptionAll() Then
		FormParameters.Insert("SelectedRouteMapsAddress", SelectedRouteMapsAddress);
	EndIf;
	
	OpenForm("DataProcessor.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.Form.SelectedRouteSheetsForm",
		FormParameters,
		ThisObject);
	
EndProcedure

&AtClient
Procedure ConflictInformationNavigationLinkHandling(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	StartUpdatingInformationOnConflicts(True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateProductionProcesses(Command)
	
	StartCreatingTypicalTechnologicalProcesses();
	
EndProcedure

&AtClient
Procedure PerformATransferOfOperations(Command)
	
	StartMergingCatalogs();
	
EndProcedure

&AtClient
Procedure DisableTheUseOfRouteMaps(Command)
	
	StartDisablingUseOfRouteMaps();
	
EndProcedure

#EndRegion

#Region Private

#Region Marks

&AtClientAtServerNoContext
Function SequenceOfSteps()
	
	Result = New Array;
	
	Result.Add(1);
	Result.Add(2);
	Result.Add(3);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function PreviousStep(Form, CurrentStep)
	
	Return CurrentStep-1;
	
EndFunction

&AtClientAtServerNoContext
Function StepAvailable(Form, CurrentStep)
	
	If Form.ALongRunningOperationDataProcessing <> Undefined Then
		
		Return False;
	
	Else
	
		Return (CurrentStep = 1 Or Form["MarkStep_"+PreviousStep(Form, CurrentStep)]);
		
	EndIf;
	
EndFunction

&AtClientAtServerNoContext
Function StepElementsAreAvailable(Form, CurrentStep)
	
	Return StepAvailable(Form, CurrentStep) And Not Form["MarkStep_"+CurrentStep];
	
EndFunction

&AtClientAtServerNoContext
Procedure SetCheck(Form, CurrentStep)
	
	Form["MarkStep_"+CurrentStep] = True;
	
	ConfigureDependentFormElements(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ResetMark(Form, CurrentStep)
	
	For Each Step In SequenceOfSteps() Do
		
		If Step < CurrentStep Then
			Continue;
		EndIf;
		
		Form["MarkStep_"+Step] = False;
		
	EndDo;
	
	ConfigureDependentFormElements(Form);
	
EndProcedure

#EndRegion

#Region CreationOfStandardTechnologicalProcesses

&AtClientAtServerNoContext
Function OptionForSelectingRouteMapsReusable()
	Return 1;
EndFunction

&AtClientAtServerNoContext
Function OptionForSelectingRouteMapsBySelection()
	Return 2;
EndFunction

&AtClientAtServerNoContext
Function RouteMapSelectionOptionAll()
	Return 0;
EndFunction

&AtClient
Procedure ArbitraryFilterCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		CompositionSettings = Result;
		
		StartUpdatingInformationOnSelectedRouteMaps();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartUpdatingInformationOnSelectedRouteMaps()
	
	Items.GroupPages1_4.CurrentPage = Items.GroupPage14Waiting;
	
	StartUpdatingInformationOnSelectedRouteMapsOnServer();
	
	If ALongRunningOperationInterface <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"UpdateInformationOnSelectedRouteMaps",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ALongRunningOperationInterface,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUpdatingInformationOnSelectedRouteMapsOnServer()
	
	If ALongRunningOperationInterface <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(ALongRunningOperationInterface.JobID);
		ALongRunningOperationInterface = Undefined;
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận danh sách thẻ lộ trình đã chọn.';
														|ru = 'Получение списка отобранных маршрутных карт.';
														|en = 'Getting a list of selected route sheets.'; fa = 'Getting a list of selected route sheets.';
														|it = 'Ottenere l''elenco di schede di lavorazione selezionate.';
														|pl = 'Otrzymanie listy wybranych kart technologicznych.';
														|tr = 'Seçilen Rotalarının listesinin alınması.'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("RouteMapSelectionOption", RouteMapSelectionOption);
	ProcedureParameters.Insert("CompositionSettings", CompositionSettings);
	
	ALongRunningOperationInterface = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.ListOfSelectedRouteMapsInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
	If ALongRunningOperationInterface.Status <> "Running" Then
		
		ProcessResultOfUpdatingListOfSelectedRouteMaps(ALongRunningOperationInterface);
		
		ALongRunningOperationInterface = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateInformationOnSelectedRouteMaps(Result, AdditionalParameters) Export
	
	ALongRunningOperationInterface = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		ProcessResultOfUpdatingListOfSelectedRouteMaps(Result);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfUpdatingListOfSelectedRouteMaps(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	SelectedRouteMapsQuantity = Result.RouteMapsQuantity;
	If RouteMapSelectionOptionAll() Then
		SelectedRouteMapsAddress = Undefined;
	Else
		SelectedRouteMapsAddress = PutToTempStorage(Result.RouteSheets, UUID);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "CreationOfStandardTechnologicalProcesses");
	
	Items.GroupPages1_4.CurrentPage = Items.GroupPage14Label; 
	
EndProcedure

&AtClient
Procedure StartCreatingTypicalTechnologicalProcesses()
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		Return;
	EndIf;
	
	Items.GroupStep1Processing.CurrentPage = Items.GroupStep1ProcessingWaiting;
	
	StartCreatingTypicalTechnologicalProcessesOnServer();
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"CreationOfStandardTechnologicalProcessesCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ALongRunningOperationDataProcessing,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
	RefreshInterface = True;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure StartCreatingTypicalTechnologicalProcessesOnServer()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo quy trình kỹ thuật mẫu.';
														|ru = 'Создание типовых технологических процессов.';
														|en = 'Generating standard technological processes.'; fa = 'Generating standard technological processes.';
														|it = 'Creazione di processi tecnologici standard.';
														|pl = 'Utworzenie typowych procesów technologicznych.';
														|tr = 'Standart teknolojik süreçlerin oluşturulması.'");
	
	ProcedureParameters = New Structure("RouteMapSelectionOption,RouteSheets");
	ProcedureParameters.RouteMapSelectionOption = RouteMapSelectionOption;
	If Not RouteMapSelectionOption = RouteMapSelectionOptionAll()
			And IsTempStorageURL(SelectedRouteMapsAddress) Then
		ProcedureParameters.RouteSheets = GetFromTempStorage(SelectedRouteMapsAddress);
	EndIf;
	
	ALongRunningOperationDataProcessing = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.CreateTypicalTechnologicalProcessesInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure CreationOfStandardTechnologicalProcessesCompletion(Result, AdditionalParameters) Export
	
	ALongRunningOperationDataProcessing = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		JobResult = ProcessResultOfCreatingTechnologicalProcesses(Result);
		
		If JobResult.HasErrors Then
			
			Message = NStr("vi = 'Đã kết thúc bị lỗi.
			|	Chi tiết xem trong nhật ký sự kiện';
			|ru = 'Завершено с ошибками.
			|	Подробности см. в журнале регистрации';
			|en = 'Completed with errors.
			|	See event log for details.'; fa = 'Completed with errors.
			|	See event log for details.';
			|it = 'Completato con errori.
			|	Vedere dettagli nel registro';
			|pl = 'Zakończono z błędami.
			|	Szczegóły zobacz w dzienniku rejestracji';
			|tr = 'Hatalarla tamamlandı.
			|	Ayrıntılar için olay günlüğüne bakın'");
			Picture  = PictureLib.Error32;
			
		Else
			
			Message = StrTemplate(NStr("vi = 'Đã kết thúc thành công.
			|	Đã tạo %1 quy trình kỹ thuật';
			|ru = 'Завершено успешно.
			|	Создано технологических процессов: %1';
			|en = 'Completed successfully.
			|	Technological processes generated: %1'; fa = 'Completed successfully.
			|	Technological processes generated: %1';
			|it = 'Completato con successo.
			|	Processi tecnologici creati: %1';
			|pl = 'Zakończono pomyślnie.
			|	Utworzono procesów technologicznych: %1';
			|tr = 'Başarıyla tamamlandı.
			|	Oluşturulan teknolojik süreçler: %1'"), JobResult.QuantityCreated);
			Picture  = PictureLib.Information32;
			
			StartUpdatingInformationOnConflicts();
			
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Tạo quy trình kỹ thuật';
									|ru = 'Создание технологических процессов';
									|en = 'Creating technological processes'; fa = 'Creating technological processes';
									|it = 'Creazione di processi tecnologici';
									|pl = 'Utworzenie procesów technologicznych';
									|tr = 'Teknolojik süreçlerin oluşturulması'"),,
			Message,
			Picture);
			
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessResultOfCreatingTechnologicalProcesses(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	If Not Result.HasErrors Then
	
		MarkStep_1 = True;
		Constants.UseTechnologicalProcesses.Set(True);
		
	EndIf;
		
	Items.GroupStep1Processing.CurrentPage = Items.GroupStep1ProcessingEmpty;
	
	ConfigureDependentFormElements(ThisObject);
	
	Return Result;
	
EndFunction

#EndRegion

#Region MergingCatalogs

&AtClient
Procedure StartUpdatingInformationOnConflicts(GenerateReport = False)
	
	If GenerateReport Then
		Items.Group22Conflicts.CurrentPage = Items.Group22WaitingForAReport;
	Else
		Items.Group22Conflicts.CurrentPage = Items.Group22Waiting;
	EndIf;
	
	StartUpdatingInformationOnPresenceOfConflictsOnServer(GenerateReport);
	
	If ALongRunningOperationInterface <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"UpdateInformationOnConflicts",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ALongRunningOperationInterface,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUpdatingInformationOnPresenceOfConflictsOnServer(GenerateReport = False)
	
	If ALongRunningOperationInterface <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(ALongRunningOperationInterface.JobID);
		ALongRunningOperationInterface = Undefined;
	EndIf;
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("GenerateReport", GenerateReport);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật thông tin về xung đột.';
														|ru = 'Обновление информации о наличии конфликтов.';
														|en = 'Updating conflict information.'; fa = 'Updating conflict information.';
														|it = 'Aggiornamento di informazioni sulla presenza di conflitti.';
														|pl = 'Aktualizacja informacji o istnieniu konfliktów.';
														|tr = 'Çakışma varlığına ilişkin bilgilerin güncellenmesi.'");
	
	ALongRunningOperationInterface = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.DeterminePresenceOfConflictsInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure UpdateInformationOnConflicts(Result, AdditionalParameters) Export
	
	ALongRunningOperationInterface = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		ConflictData = Undefined; // SpreadsheetDocument
		
		ProcessResultOfUpdatingInformationOnPresenceOfConflicts(Result, ConflictData);
		
		If ConflictData <> Undefined Then
			
			OpenForm("DataProcessor.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.Form.FormOfConflictsInformation",
				ConflictData, ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfUpdatingInformationOnPresenceOfConflicts(TimeConsumingOperation, ConflictData = Undefined)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	If Result.ThereAreConflicts = True Then
		Items.Group22Conflicts.CurrentPage = Items.Group22ThereAreConflicts;
		If Result.GenerateReport Then
			AddressConflictData = PutToTempStorage(Result.ConflictData, UUID);
			ConflictData = New Structure("AddressConflictData", AddressConflictData);
		EndIf;
	Else
		LabelNoConflicts = NStr("vi = 'Không tìm thấy xung đột hoặc đã xử lý tất cả bảng kê chi tiết';
								|ru = 'Конфликтов не обнаружено либо все спецификации уже обработаны';
								|en = 'No conflicts found or all the bills of materials have already been processed'; fa = 'No conflicts found or all the bills of materials have already been processed';
								|it = 'Conflitti non rilevati oppure tutte le specifiche sono state elaborate';
								|pl = 'Nie wykryto konfliktów lub wszystkie specyfikacje są już przetworzone';
								|tr = 'Herhangi bir çakışma bulunamadı veya tüm ürü reçeteleri zaten işlenmiş'");
		Items.Group22Conflicts.CurrentPage = Items.Group22NoConflicts;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "MergingCatalogs");
	
EndProcedure

&AtClient
Procedure StartMergingCatalogs()
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		Return;
	EndIf;
	
	Items.GroupStep2Processing.CurrentPage = Items.GroupStep2ProcessingWaiting;
	
	StartMergingCatalogsOnServer();
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"MergingCatalogsCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ALongRunningOperationDataProcessing,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
	RefreshInterface = True;
	
	ConfigureDependentFormElements(ThisObject);

EndProcedure

&AtServer
Procedure StartMergingCatalogsOnServer()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Chuyển đổi giao dịch sang bảng kê chi tiết nguồn lực.';
														|ru = 'Перенос операций в ресурсные спецификации.';
														|en = 'Transferring operations to bills of materials.'; fa = 'Transferring operations to bills of materials.';
														|it = 'Trasferimento di operazioni nelle specifiche delle risorse.';
														|pl = 'Przeniesienie operacji do specyfikacji zasobów.';
														|tr = 'İşlemlerin ürün reçetelerine aktarılması.'");
	
	ProcedureParameters = New Structure;
	
	ALongRunningOperationDataProcessing = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.CombiningCatalogsInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure MergingCatalogsCompletion(Result, AdditionalParameters) Export
	
	ALongRunningOperationDataProcessing = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		JobResult = ProcessResultOfMergingCatalogs(Result);
		
		If JobResult.HasErrors Then
					
			Message = NStr("vi = 'Đã kết thúc bị lỗi.
			|	Chi tiết xem trong nhật ký sự kiện';
			|ru = 'Завершен с ошибками.
			|	Подробности см. в журнале регистрации';
			|en = 'Completed with errors.
			|	See event log for details.'; fa = 'Completed with errors.
			|	See event log for details.';
			|it = 'Completato con errori.
			|	Vedere dettagli nel registro';
			|pl = 'Zakończony z błędami.
			|	Szczegóły zobacz w dzienniku rejestracji';
			|tr = 'Hatalarla tamamlandı.
			|	Ayrıntılar için olay günlüğüne bakın'");
			Picture  = PictureLib.Error32;
			
		Else
			
			ArrayOfTexts = New Array;
			ArrayOfTexts.Add(NStr("vi = 'Đã hoàn tất thành công.';
									|ru = 'Завершен успешно.';
									|en = 'Completed successfully.'; fa = 'Completed successfully.';
									|it = 'Completato con successo.';
									|pl = 'Zakończony pomyślnie.';
									|tr = 'Başarıyla tamamlandı.'"));
			ArrayOfTexts.Add(StrTemplate(NStr("vi = 'Đã xử lý %1 bảng kê chi tiết';
												|ru = 'Обработано спецификаций: %1';
												|en = 'Bills of materials processed: %1'; fa = 'Bills of materials processed: %1';
												|it = 'Specifiche elaborate: %1';
												|pl = 'Przetworzono specyfikacji: %1';
												|tr = 'İşlenen ürün reçeteleri: %1'"), JobResult.ProcessedSpecifications));
			If JobResult.RescheduledOperations > 0 Then
				ArrayOfTexts.Add(StrTemplate(NStr("vi = 'Đã chuyển %1 giao dịch';
													|ru = 'Перенесено операций: %1';
													|en = 'Operations transferred: %1'; fa = 'Operations transferred: %1';
													|it = 'Operazioni trasferite: %1';
													|pl = 'Przeniesiono operacji: %1';
													|tr = 'Aktarılan işlemler: %1'"), JobResult.RescheduledOperations));
			EndIf;
			If JobResult.ConnectedTechnicalProcesses > 0 Then
				ArrayOfTexts.Add(StrTemplate(NStr("vi = 'Đã kết nối quy trình kỹ thuật: %1';
													|ru = 'Подключено технологических процессов: %1';
													|en = 'Technological processes attached: %1'; fa = 'Technological processes attached: %1';
													|it = 'Processi tecnologici collegati: %1';
													|pl = 'Podłączono procesów technologicznych: %1';
													|tr = 'Bağlanan teknolojik süreçler: %1'"), JobResult.ConnectedTechnicalProcesses));
			EndIf;
			
			Message = StrConcat(ArrayOfTexts, Chars.LF);
			Picture  = PictureLib.Information32;
			
			AttachIdleHandler("RefreshApplicationInterface", 2, True);
			
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Chuyển giao dịch';
									|ru = 'Перенос операций';
									|en = 'Transferring operations'; fa = 'انتقال عملیات';
									|it = 'Trasferimento di operazioni';
									|pl = 'Przeniesienie operacji';
									|tr = 'İşlemlerin aktarılması'"),,
			Message,
			Picture);
		
	EndIf;
	
EndProcedure

&AtServer
Function ProcessResultOfMergingCatalogs(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	If Not Result.HasErrors Then
		
		MarkStep_2 = True;
		
	EndIf;
	
	Items.GroupStep2Processing.CurrentPage = Items.GroupStep2ProcessingEmpty;
	
	ConfigureDependentFormElements(ThisObject);
	
	Return Result;
	
EndFunction

#EndRegion

#Region DisablingRouteMaps

&AtClient
Procedure StartDisablingUseOfRouteMaps()
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		Return;
	EndIf;
	
	Items.GroupStep3_processing.CurrentPage = Items.GroupStep3_Processing_Waiting;
	
	StartDisablingUseOfRouteMapsAtServer();
	
	If ALongRunningOperationDataProcessing <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"DisablingRouteMapsCompletion",
			ThisObject);
			
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
			
		TimeConsumingOperationsClient.WaitCompletion(
			ALongRunningOperationDataProcessing,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
	RefreshInterface = True;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure StartDisablingUseOfRouteMapsAtServer()
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Ngắt sử dụng thẻ quy trình.';
														|ru = 'Отключение использования маршрутных карт.';
														|en = 'Disable using route sheets.'; fa = 'Disable using route sheets.';
														|it = 'Disable using route sheets.';
														|pl = 'Disable using route sheets.';
														|tr = 'Rotalarının kullanımının devre dışı bırakılması.'");
	
	ProcedureParameters = New Structure;
	
	ALongRunningOperationDataProcessing = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.DisablingUseOfRouteSheetsInBackground",
		ProcedureParameters,
		ExecutionParameters);
	
EndProcedure

&AtClient
Procedure DisablingRouteMapsCompletion(Result, AdditionalParameters) Export
	
	ALongRunningOperationDataProcessing = Undefined;
	
	If Result <> Undefined And Result.Status = "Completed2" Then
		
		JobResult = ToProcessResultOfDisablingUseOfRouteSheets(Result);
	
		If JobResult.HasErrors Then
					
			Message = NStr("vi = 'Chưa thực hiện.
			|	Xem chi tiết trong nhật ký sự kiện';
			|ru = 'Не выполнено.
			|	Подробности см. в журнале регистрации';
			|en = 'Not completed.
			|	For more information, see the Event log'; fa = 'Not completed.
			|	For more information, see the Event log';
			|it = 'Not completed.
			|	For more information, see the Event log';
			|pl = 'Not completed.
			|	For more information, see the Event log';
			|tr = 'Tamamlanmadı.
			|	Ayrıntılar için olay günlüğüne bakın'");
			Picture  = PictureLib.Error32;
			
		Else
			
			Message = NStr("vi = 'Đã thực hiện thành công.';
							|ru = 'Выполнено успешно.';
							|en = 'Completed successfully.'; fa = 'Completed successfully.';
							|it = 'Completed successfully.';
							|pl = 'Completed successfully.';
							|tr = 'Başarıyla tamamlandı.'");
			Picture  = PictureLib.Information32;
			
			Notify("Write_ConstantsSet", New Structure, "UseRouteSheets");
			
			AttachIdleHandler("RefreshApplicationInterface", 2, True);
			
		EndIf;
		
		ShowUserNotification(NStr("vi = 'Ngắt sử dụng thẻ quy trình';
									|ru = 'Отключение использования маршрутных карт';
									|en = 'Disable using route sheets'; fa = 'غیرفعال کردن استفاده از برگه‌های مسیر';
									|it = 'Disable using route sheets';
									|pl = 'Disable using route sheets';
									|tr = 'Rotalarının kullanımının devre dışı bırakılması'"),,
			Message,
			Picture);
	
	EndIf;
	
EndProcedure

&AtServer
Function ToProcessResultOfDisablingUseOfRouteSheets(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	If Not Result.HasErrors Then
		
		MarkStep_3 = True;
		
	EndIf;
	
	Items.GroupStep3_processing.CurrentPage = Items.GroupStep3_Processing_Empty;
	
	FillInServiceDetails();
	
	ConfigureDependentFormElements(ThisObject);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure CustomizeFormElements()
	
	RouteMapSelectionOption    = OptionForSelectingRouteMapsReusable();
	
	LabelNoConflicts           = NStr("vi = 'Không tiến hành tìm kiếm xung đột';
										|ru = 'Поиск конфликтов не производился';
										|en = 'Conflict search was not performed'; fa = 'Conflict search was not performed';
										|it = 'La ricerca di conflitti non è stata effettuata';
										|pl = 'Wyszukiwanie konfliktów nie wykonywało się';
										|tr = 'Çakışma araması gerçekleştirilmedi'");
	
	If GetFunctionalOption("UseTechnologicalProcesses")
		Or Not ThereAreRouteMaps Then
		MarkStep_1 = True;
	EndIf;
	
	If GetFunctionalOption("StoreOperationsInBillsOfMaterials")
		Or Not ThereAreRouteMaps Then
		MarkStep_1 = True;
		MarkStep_2 = True;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Marks")
		Or Initialize Then
			
		Steps = SequenceOfSteps();
		For Each Step In Steps Do
			GroupStep = Items["GroupMarkStep"+Step];
			If StepAvailable(Form, Step) Then
				If Form["MarkStep_"+Step] = True Then
					GroupStep.CurrentPage = Items["DonePageStep"+Step];
				Else
					GroupStep.CurrentPage = Items["PageNotReadyStep"+Step];
				EndIf;
			Else
				GroupStep.CurrentPage = Items["PageUnavailableStep"+Step];
			EndIf;
		EndDo;
			
	EndIf;
	
	If AttributesStructure1.Property("CreationOfStandardTechnologicalProcesses")
		Or Initialize Then
		
		ItemsAvailable = StepElementsAreAvailable(Form, 1);
		
		Items.Group1_2.Enabled = ItemsAvailable;
		Items.ArbitraryFilter.Visible = (Form.RouteMapSelectionOption = OptionForSelectingRouteMapsBySelection());
		Items.GroupPages1_4.Enabled = ItemsAvailable;
		
		If Form.SelectedRouteMapsQuantity > 0 Then
			RouteMapsSelected = StrTemplate(NStr("vi = 'Đã chọn thẻ lộ trình (%1)';
												|ru = 'Выбрано маршрутных карт (%1)';
												|en = 'Route sheets selected (%1)'; fa = 'Route sheets selected (%1)';
												|it = 'Schede di lavorazioni selezionate (%1)';
												|pl = 'Wybrano kart technologicznych (%1)';
												|tr = 'Seçilen rotalar (%1)'"), Form.SelectedRouteMapsQuantity);
			Items.LabelSelectedRouteMaps.Hyperlink = True;
			Items.CreateProductionProcesses.Enabled = ItemsAvailable;
		Else
			RouteMapsSelected = NStr("vi = 'Không có thẻ lộ trình để xử lý';
									|ru = 'Нет маршрутных карт для обработки';
									|en = 'No route sheets for processing'; fa = 'No route sheets for processing';
									|it = 'Non ci sono schede di lavorazione da elaborare';
									|pl = 'Brak kart technologicznych do przetwarzania';
									|tr = 'İşlenecek rotalar yok'");
			Items.LabelSelectedRouteMaps.Hyperlink = False;
			Items.CreateProductionProcesses.Enabled = False;
		EndIf;
		Form.LabelSelectedRouteMaps = RouteMapsSelected;
			
	EndIf;
	
	If AttributesStructure1.Property("MergingCatalogs")
		Or Initialize Then
		
		ItemsAvailable = StepElementsAreAvailable(Form, 2);
		
		Items.Group22Conflicts.Enabled = ItemsAvailable;
		Items.PerformATransferOfOperations.Enabled = ItemsAvailable;
		
	EndIf;
	
	If AttributesStructure1.Property("DisablingRouteMaps")
		Or Initialize Then
		
		ItemsAvailable = StepElementsAreAvailable(Form, 3);
		
		Items.DisableTheUseOfRouteMaps.Enabled = ItemsAvailable;
		Items.GroupMarkStep3.Enabled = Form.MarkStep_3 Or Form.StoreOperationsInBillsOfMaterials;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	Query = New Query("SELECT TOP 1
	|	TRUE AS Field1
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|WHERE
	|	NOT RouteSheets.DeletionMark");
	ThereAreRouteMaps = Not Query.Execute().IsEmpty();
	
	StoreOperationsInBillsOfMaterials = GetFunctionalOption("StoreOperationsInBillsOfMaterials");
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion