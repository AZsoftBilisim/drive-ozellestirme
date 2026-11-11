#Region Variables

&AtClient
Var IdleHandlerParameters; // Structure of waiting time intervals for a long operation

&AtClient
Var PreviousVersionOfTaskData; // The data version of the task, when the form is blocked, the tree
                                    // is updated when the data version changes.

&AtClient
Var TimeConsumingOperationForm; // The form of blocking this form when performing a long operation

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
		
	EditingBudgetTasksOutsideProcesses = Users.RolesAvailable("EditingBudgetTasksOutsideProcesses")
		Or Users.IsFullUser(, , True);
		
	If Object.Ref.IsEmpty() Then
		
		DataFromBudgetPreparationStage = Common.ObjectAttributesValues(Object.BudgetingStep,
			"SettingOfAction, MonitoringReportSettings");
		If DataFromBudgetPreparationStage.SettingOfAction = Undefined Then
			ActionSettingsTable = Undefined;
		Else
			ActionSettingsTable = DataFromBudgetPreparationStage.SettingOfAction.Get();
		EndIf;
		If ActionSettingsTable <> Undefined Then
			MultipleInstances(ActionSettingsTable);
			PlaceActionSettingsInTemporaryStorage(ActionSettingsTable);
			If Object.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
				Or Object.Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
				Or Object.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
				Or Object.Action
				= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				UpdateDocumentTree(ActionSettingsTable,True);
			EndIf;
		EndIf;
		
		If DataFromBudgetPreparationStage.MonitoringReportSettings = Undefined Then
			ControlReportSettingsTable = Undefined;
		Else
			ControlReportSettingsTable = DataFromBudgetPreparationStage.MonitoringReportSettings.Get();
		EndIf;
		If ControlReportSettingsTable <> Undefined Then
			MonitoringReportSettings.Load(ControlReportSettingsTable);
		EndIf;
		
		If Not EditingBudgetTasksOutsideProcesses And Not ValueIsFilled(Object.MainTask_) Then
			Raise NStr("vi = 'Là một phần của quy trình ngân sách, chỉ các nhiệm vụ liên quan mới được phép tạo.';
						|ru = 'В рамках бюджетного процесса разрешено создавать только связанные задачи.';
						|en = 'You can create only linked tasks within the budget process.'; fa = 'You can create only linked tasks within the budget process.';
						|it = 'Nel processo di budget è consentito creare solo gli obiettivi correlati.';
						|pl = 'W ramach procesu budżetowego dozwolono utworzenie tylko zadania związana.';
						|tr = 'Bütçe süreci sınırları içinde sadece ilgili görevler oluşturmaya izin veriliyor.'");
		EndIf;
		
		OnReadCreateAtServer();
		
	EndIf;
	
	If Not Users.IsFullUser(, , False)
	   And Not AccessRight("Update", Metadata.Catalogs.BudgetingSteps) Then
		Items.ActionGroup.Enabled = False;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	UpdateInformationOnRelatedTasks();
	
	ActionSettingsTable = CurrentObject.SettingOfAction.Get();
	If ActionSettingsTable <> Undefined Then
		MultipleInstances(ActionSettingsTable);
		PlaceActionSettingsInTemporaryStorage(ActionSettingsTable);
	EndIf;
	
	If Object.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
		Or Object.Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
		Or Object.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		Or Object.Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		UpdateDocumentTree(ActionSettingsTable);
	EndIf;
	
	ControlReportSettingsTable = CurrentObject.MonitoringReportSettings.Get();
	If ControlReportSettingsTable <> Undefined Then
		MonitoringReportSettings.Load(ControlReportSettingsTable);
	EndIf;
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ActionSettingsTable = GetActionSettingsFromTemporaryStorage();
	CurrentObject.SettingOfAction = New ValueStorage(ActionSettingsTable);
	CurrentObject.MonitoringReportSettings = New ValueStorage(MonitoringReportSettings.Unload());
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	UpdateStatusOfApprovedDocuments();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_PurchasePlan"
		Or EventName = "Write_SalesPlan"
		Or EventName = "Write_ProductionPlan"
		Or EventName = "Write_AssemblyDisassemblyPlan"
		Or EventName = "Write_InventoryConsumptionPlan"
		Or EventName = "Write_PlanOfGoodsStock"
		Or EventName = "Write_BudgetEntryForm" Then
		
		SearchResult = Object.ApprovedDocuments.FindRows(New Structure("Document", Source));
		If SearchResult.Count() Or ListVisibility Then
			FormControl();
		EndIf;
		
		DocumentListSearch = Object.DocumentsList.FindRows(New Structure("Document", Source));
		If DocumentListSearch.Count() And MonitoringReportSettings.Count() Then
			GenerateControlReport();
		EndIf;
		
	EndIf;
	 
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_BudgetTask",,Object.Ref);
	If Not WriteParameters.Property("DoNotRunDocumentCreationCheck") Then
		If Object.ForDocumentCreation Then
			AttachIdleHandler("CheckExecutionOfDocumentCreationClient", 0.2, True);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If MonitoringReportSettings.Count() > 0 Then
		Items.MonitoringReportKind.ChoiceList.Clear();
		For Each Page1 In MonitoringReportSettings Do
			Items.MonitoringReportKind.ChoiceList.Add(String(Page1.BudgetProfile),String(Page1.BudgetProfile));
		EndDo;
		MonitoringReportKind = MonitoringReportSettings[0].BudgetProfile;
		MonitoringReportIndex = 0;
		GenerateControlReport();
	EndIf;
	
	If MonitoringReportSettings.Count() <= 1 Then
		Items.MonitoringReportKind.Visible = False;
	EndIf;
	If Object.ForDocumentCreation Then
		AttachIdleHandler("CheckExecutionOfDocumentCreationClient", 0.2, True);
	EndIf;
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	ThereIsAuthor = ValueIsFilled(Object.Author);
	Items.Author.Visible = ThereIsAuthor;
	Items.TheLabelIsFormedAutomatically.Visible = Not ThereIsAuthor;
	
	Attributes = New Structure("Periodicity", "Parent.Periodicity");
	Periodicity = Common.ObjectAttributesValues(Object.BudgetingStep, Attributes).Periodicity;
	LabelPeriod = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(Object.Period, Periodicity);
	
	If Object.Executed Then
		Title = NStr("vi = 'Đã thực hiện';
					|ru = 'Выполнено';
					|en = 'Completed'; fa = 'تکمیل‌شده';
					|it = 'Completato';
					|pl = 'Wykonano';
					|tr = 'Tamamlandı'");
	EndIf;
	
	ConfigureListOfTaskActions();
	SetAvailabilityOfBudgetingModel();
	
	CurrentAction1 = Object.Action;
	
	If CurrentAction1 = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		Items.DocumentTreeTypeOfBudgetAnalytics.Title = NStr("vi = 'Quy tắc tính toán';
															|ru = 'Правило расчета';
															|en = 'Calculation rule'; fa = 'قاعده محاسبه';
															|it = 'Calculation rule';
															|pl = 'Calculation rule';
															|tr = 'Hesaplama kuralı'");
	ElsIf CurrentAction1
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		Items.DocumentTreeTypeOfBudgetAnalytics.Title = NStr("vi = 'Chỉ tiêu ngân sách';
															|ru = 'Показатель бюджетов';
															|en = 'Budget balance item'; fa = 'قلم مانده بودجه';
															|it = 'Indice dei bilanci';
															|pl = 'Wskaźnik budżetowy';
															|tr = 'Bütçe kalemi'");
	EndIf;
	
	FormControl();
	
	OpenSettings = ValueIsFilled(Object.BudgetingStep);
	Items.BudgetingModel.ReadOnly = OpenSettings;
	Items.BudgetingStep.ReadOnly = OpenSettings;
	Items.Action.ReadOnly = OpenSettings;
	
	WindowOptionsKey = ?(ListVisibility, "DocumentsList", "Document");
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActionOnChange(Item)
	
	ActionOnChangeServer();
	
EndProcedure

&AtClient
Procedure ThePeriodOfTheTaskWhenItIsChanged(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetPeriodOfTaskWhenItChangesOnServer();
	
EndProcedure

&AtClient
Procedure BudgetingStepOnChange(Item)
	
	Object.DocumentsList.Clear();
	
	SetPeriodOfTaskWhenItChangesOnServer();
	
EndProcedure

&AtClient
Procedure ApprovedDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Document = Object.ApprovedDocuments.FindByID(RowSelected).Document;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", Document);
	OpenForm(NameOfDocumentForm(Document), FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure DocumentTreeSelection(Item)
	
	If Item.CurrentItem.Name = "DocumentTreeDocumentPresentation" Then
		
		CurrentData = Items.DocumentTree.CurrentData;
		If ValueIsFilled(CurrentData.Document) Then
			ShowValue(, CurrentData.Document);
		Else
			If CurrentData.DocumentPresentation = NStr("vi = 'Tạo mới';
														|ru = 'Создать';
														|en = 'Create'; fa = 'ایجاد';
														|it = 'Creare';
														|pl = 'Create';
														|tr = 'Oluştur'") Then
				If ReadOnly Then
					ShowMessageBox(, NStr("vi = 'Người sử dụng không có quyền soạn nhiệm vụ ngân sách.';
											|ru = 'У пользователя нет прав на редактирование бюджетной задачи.';
											|en = 'The user does not have the rights to edit the budget task.'; fa = 'The user does not have the rights to edit the budget task.';
											|it = 'The user does not have the rights to edit the budget task.';
											|pl = 'The user does not have the rights to edit the budget task.';
											|tr = 'Kullanıcının bütçe görevini düzenleme yetkisi bulunmamaktadır.'"));
					Return;
				EndIf;
				ArrayDocuments = CreateBudgetByActionLine(CurrentData.GetID(), True);
				If ArrayDocuments <> Undefined And ArrayDocuments.Count() > 0 Then
					ButtonsList = New ValueList;
					ButtonsList.Add(DialogReturnCode.Yes, ?(ArrayDocuments.Count() = 1,
						NStr("vi = 'Chọn đối tượng tìm thấy';
							|ru = 'Выбрать найденный';
							|en = 'Select found'; fa = 'Select found';
							|it = 'Selezionare trovato';
							|pl = 'Wybierz znaleziony';
							|tr = 'Bulunanları seç'"), NStr("vi = 'Chọn từ đối tượng được tìm thấy';
															|ru = 'Выбрать из найденных';
															|en = 'Select from found'; fa = 'Select from found';
															|it = 'Selezionare tra trovati';
															|pl = 'Wybierz spośród znalezionych';
															|tr = 'Bulunanlardan seç'")));
					ButtonsList.Add(DialogReturnCode.No, NStr("vi = 'Tạo mới';
																|ru = 'Создать новый';
																|en = 'Create new'; fa = 'ایجاد جدید';
																|it = 'Crea nuovo';
																|pl = 'Utwórz nowy';
																|tr = 'Yenisini oluştur'"));
					If ArrayDocuments.Count() = 1 Then
						QueryText = NStr("vi = 'Đã tìm thấy chứng từ phù hợp.';
										|ru = 'Найден подходящий документ.';
										|en = 'A suitable document is found.'; fa = 'A suitable document is found.';
										|it = 'A suitable document is found.';
										|pl = 'A suitable document is found.';
										|tr = 'Uygun belge bulundu.'");
					Else
						QueryText = StringFunctionsClientServer.SubstituteParametersToString(
							NStr("vi = 'Đã tìm thấy chứng từ phù hợp (%1).';
								|ru = 'Найдено подходящих документов (%1).';
								|en = 'Suitable documents found (%1).'; fa = 'Suitable documents found (%1).';
								|it = 'Suitable documents found (%1).';
								|pl = 'Suitable documents found (%1).';
								|tr = 'Bulunan uygun belgelerin sayısı (%1).'"), ArrayDocuments.Count());
					EndIf;
					ShowQueryBox(New CallbackDescription("DocumentTreeSelectionCompletion", ThisObject, ArrayDocuments), 
						QueryText, ButtonsList);
				Else
					DocumentTreeSelectionCompletion(DialogReturnCode.No, ArrayDocuments)	
				EndIf;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DocumentTreeSelectionCompletion(QuestionResult, ArrayDocuments) Export
	
	CurrentData = Items.DocumentTree.CurrentData;
	
	ResponseCode = QuestionResult;
	If ResponseCode = DialogReturnCode.Yes Then
		If ArrayDocuments.Count() > 1 Then
			ReplaceBudget(Undefined);
		Else
			CurrentData.Document = ArrayDocuments[0];
			CurrentData.DocumentPresentation = PresentationOfDocument(CurrentData.Document);
			Nw = Object.DocumentsList.Add();
			Nw.Document = CurrentData.Document;
			
			Try
				Write();
			Except
				Modified = True;
				Raise NStr("vi = 'Không thể ghi lại nhiệm vụ.
					|Chứng từ theo nhiệm vụ có thể không hợp lệ để thay đổi';
					|ru = 'Не удалось записать задачу. 
					|Документы по задаче могут быть не доступны для изменения';
					|en = 'Cannot save the task. 
					|The task documents might be read-only'; fa = 'Cannot save the task. 
					|The task documents might be read-only';
					|it = 'Impossibile registrare l''obiettivo. 
					|I documenti relativi all''obiettivo potrebbero essere non disponibili alla modifica';
					|pl = 'Brak możliwości zapisu zadania. 
					|Dokumenty dla zadania mogą być nie dostępne dla zmiany';
					|tr = 'Görev kaydedilemiyor.
					| Göreve göre belgeler değişikler için kullanılamayabilir'");
			EndTry;
			
		EndIf;
	Else
		ArrayDocuments = CreateBudgetByActionLine(CurrentData.GetID());
		If ArrayDocuments <> Undefined And ArrayDocuments.Count() > 0 Then
			CurrentData.Document = ArrayDocuments[0];
			CurrentData.DocumentPresentation = PresentationOfDocument(CurrentData.Document);
			
			NewRow = Object.DocumentsList.Add();
			NewRow.Document = CurrentData.Document;
				
			Try
				Write();
			Except
				Modified = True;
				Raise NStr("vi = 'Không thể ghi lại nhiệm vụ.
					|Chứng từ theo nhiệm vụ có thể không hợp lệ để thay đổi';
					|ru = 'Не удалось записать задачу. 
					|Документы по задаче могут быть не доступны для изменения';
					|en = 'Cannot save the task. 
					|The task documents might be read-only'; fa = 'Cannot save the task. 
					|The task documents might be read-only';
					|it = 'Impossibile registrare l''obiettivo. 
					|I documenti relativi all''obiettivo potrebbero essere non disponibili alla modifica';
					|pl = 'Brak możliwości zapisu zadania. 
					|Dokumenty dla zadania mogą być nie dostępne dla zmiany';
					|tr = 'Görev kaydedilemiyor.
					| Göreve göre belgeler değişikler için kullanılamayabilir'");
			EndTry;
			
			ShowValue(,CurrentData.Document);
			
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure MonitoringReportKindStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceList = New ValueList;
	For Each Page1 In MonitoringReportSettings Do
		ChoiceList.Add(MonitoringReportSettings.IndexOf(Page1),String(Page1.BudgetProfile));
	EndDo;
	
	Notification = New CallbackDescription("TypeOfControlReportSelectionCompletion", ThisObject);
	ShowChooseFromList(Notification,
		ChoiceList,
		Items.MonitoringReportKind,
		ChoiceList.FindByValue(MonitoringReportIndex));
	
EndProcedure

&AtClient
Procedure DecorationPerformAClickAction(Item)
	ExecuteAction(Undefined);
EndProcedure

&AtClient
Procedure DocumentTreeBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	ClearBudget(Undefined);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureAction(Command)
	
	Cancel = False;
	If Not ValueIsFilled(Object.Ref) Then
		QueryText = NStr("vi = 'Để cấu hình một hành động, bạn phải ghi lại một đối tượng. Để ghi lại?';
						|ru = 'Для настройки действия необходимо записать объект. Записать?';
						|en = 'To configure the action, save the object. Do you want to save it?'; fa = 'To configure the action, save the object. Do you want to save it?';
						|it = 'Per impostare l''azione è necessario registrare l''oggetto. Registrarlo?';
						|pl = 'Aby skonfigurować akcję, musisz zapisać obiekt. Chcesz zapisać?';
						|tr = 'Eylem ayarlamak için nesneyi kaydetmek gerekiyor. Kaydedilsin mi?'");
		
		Notification = New CallbackDescription("ConfigureActionCompletion", ThisObject);
		ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
		Return;
	EndIf;
	
	ConfigureFragmentAction(Cancel);
	
EndProcedure

&AtClient
Procedure ConfigureActionCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ClearMessages();
		Cancel = Not Write();
	Else 
		Cancel = True;
	EndIf;
	
	ConfigureFragmentAction(Cancel);

EndProcedure

&AtClient
Procedure ConfigureFragmentAction(Val Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	Address = ?(ValueIsFilled(AddressActionSetting), AddressActionSetting,
		PlaceActionSettingsInTemporaryStorage());
	FormParameters = New Structure;
	FormParameters.Insert("Address",                  Address);
	FormParameters.Insert("BudgetingStep", Object.BudgetingStep);
	FormParameters.Insert("BudgetingModel",   Object.BudgetingModel);
	FormParameters.Insert("ActionType", Object.Action);
	
	Notification = New CallbackDescription("WhenClosingActionSettingsForm", ThisObject);
	
	NameOfConfigurationForm = NameOfConfigurationFormOnServer(Object.Action);
	OpenForm(NameOfConfigurationForm, FormParameters, ThisObject, , , , Notification);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	If CheckFilling() Then
		Write();
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteAndClose(Command)
	
	If ReadOnly Then
		ClearMessages();
		MarkTaskCompletionATServer();
		Close();
		Return;
	EndIf;
	
	Object.Executed = True;
	
	CompletionDate = Object.CompletionDate;
	If Not ValueIsFilled(CompletionDate) Then
		Object.CompletionDate = GetCurSessionDate();
	EndIf;
	
	ClearMessages();
	
	If CheckFilling() Then
		Write();
		Close();
	Else
		Object.Executed = False;
		Object.CompletionDate = CompletionDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteAction(Command)
	
	Document = CurrentDocument(Object.DocumentsList);
	If CheckNeedToCreateNewDocumentServer(Document, Object.Action, ListVisibility) Then
		Notification = New CallbackDescription("CreateNewDocument", ThisObject);
		ShowQueryBox(
			Notification, 
			NStr("vi = 'Chứng từ mới sẽ được tạo và ghi lại. Tiếp tục?';
				|ru = 'Будет создан и записан новый документ. Продолжить?';
				|en = 'A new document will be created and saved. Continue?'; fa = 'A new document will be created and saved. Continue?';
				|it = 'Verrà creato e salvato un nuovo documento. Continuare?';
				|pl = 'Nowy dokument zostanie utworzony i zapisany. Kontynuować?';
				|tr = 'Yeni belge oluşturulacak ve kaydedilecek. Devam edilsin mi?'"),
			QuestionDialogMode.YesNo,
			60);
	Else
		ExecuteActionClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateAutomatically(Command)
	
	DocumentsList = New Array();
	For Each Page1 In Object.DocumentsList Do
		DocumentsList.Add(Page1.Document);
	EndDo;
	DocumentsList = CommonClientServer.CollapseArray(DocumentsList);
	StructureSuitableDocuments = FindSuitableBudgetsForDocumentTree(Object.BudgetingModel,
		DocumentTree, Object.Action);
	If StructureSuitableDocuments = Undefined Then
		Return;
	EndIf;
	ArrayDocuments = StructureSuitableDocuments.DocumentsArray;
	
	If ArrayDocuments <> Undefined And ArrayDocuments.Count() > 0 Then
		ButtonsList = New ValueList;
		ButtonTitle = NStr("vi = 'Sử dụng đối tượng tìm thấy';
							|ru = 'Использовать найденные';
							|en = 'Use found'; fa = 'Use found';
							|it = 'Utilizzare trovati';
							|pl = 'Użyj znalezionych';
							|tr = 'Bulunanları kullan'");
		ButtonsList.Add(DialogReturnCode.No, ButtonTitle);
		ButtonTitle = NStr("vi = 'Tạo mới';
							|ru = 'Создавать новые';
							|en = 'Create new ones'; fa = 'Create new ones';
							|it = 'Creare nuovi';
							|pl = 'Tworzyć nowe';
							|tr = 'Yenileri oluştur'");
		ButtonsList.Add(DialogReturnCode.Yes, ButtonTitle);
		
		StringPattern = NStr("vi = 'Đã tìm thấy chứng từ phù hợp (%1).';
							|ru = 'Найдено подходящих документов (%1).';
							|en = 'Suitable documents found (%1).'; fa = 'Suitable documents found (%1).';
							|it = 'Suitable documents found (%1).';
							|pl = 'Suitable documents found (%1).';
							|tr = 'Bulunan uygun belgelerin sayısı (%1).'");
		QueryText = StringFunctionsClientServer.SubstituteParametersToString(
				StringPattern, ArrayDocuments.Count());
				
		ShowQueryBox(New CallbackDescription("GenerateAutomaticallyCompletion", ThisObject), 
			QueryText, ButtonsList);
	Else
		If StructureSuitableDocuments.NumberOfDocumentsToCreate Then	
			GenerateAutomaticallyCompletion(DialogReturnCode.No);
		Else
			ClearMessages();
			ErrorText = NStr("vi = 'Không cần tạo chứng từ mới, đã tạo tất cả chứng từ.';
							|ru = 'Создание новых документов не требуется, все документы уже созданы.';
							|en = 'No need to create new documents. All the documents are already created.'; fa = 'No need to create new documents. All the documents are already created.';
							|it = 'No need to create new documents. All the documents are already created.';
							|pl = 'No need to create new documents. All the documents are already created.';
							|tr = 'Yeni belgelerin oluşturulması gerekmiyor, tüm belgeler zaten oluşturulmuş.'");
			CommonClient.MessageToUser(ErrorText);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnToPreparation(Command)
	
	SetStatus("UnderPreparation", NStr("vi = 'Đang chuẩn bị';
										|ru = 'В подготовке';
										|en = 'Under development'; fa = 'در حال توسعه';
										|it = 'In preparazione';
										|pl = 'W przygotowaniu';
										|tr = 'Hazırlanma işleminde'"));
	
	SelectedRows = Items.ApprovedDocuments.SelectedRows; 
	
	AdditionalParameters1 = New Structure("LinesToReturnToTraining", SelectedRows);
	Notification = New CallbackDescription("WhenEnteringTaskParametersReturnToPreparation", 
		ThisObject, AdditionalParameters1);
	
	FormParameters = New Structure;
	If SelectedRows.Count() > 1 Then
		FormParameters.Insert("FormCaption",
			NStr("vi = 'Hình thành các nhiệm vụ chịu trách nhiệm chuẩn bị chứng từ';
				|ru = 'Формирование задач ответственным за подготовку документов';
				|en = 'Generate tasks to the persons responsible for document preparation'; fa = 'Generate tasks to the persons responsible for document preparation';
				|it = 'Creazione degli obiettivi da parte della persona responsabile della preparazione dei documenti';
				|pl = 'Tworzenie zadań odpowiedzialnych za przygotowanie dokumentów';
				|tr = 'Belgelerin hazırlanmasından sorumlu görevin oluşturulması'"));
	Else
		FormParameters.Insert("FormCaption",
			NStr("vi = 'Hình thành nhiệm vụ cho người chịu trách nhiệm chuẩn bị chứng từ';
				|ru = 'Формирование задачи ответственному за подготовку документа';
				|en = 'Generate a task to the person responsible for the document preparation'; fa = 'Generate a task to the person responsible for the document preparation';
				|it = 'Creazione dell''obiettivo per la persona responsabile della preparazione del documento';
				|pl = 'Utworzenie zadania odpowiedzialnego za przygotowanie dokumentu';
				|tr = 'Belgelerin hazırlanmasından sorumlu görevlerin oluşturulması'"));
	EndIf;
	FormParameters.Insert("CreatingMultipleTasks", SelectedRows.Count() > 1);
	FormParameters.Insert("SelectABudgetPreparationStep", False);
	FormParameters.Insert("ChooseAnArtist", False);
	FormParameters.Insert("BudgetingModel", Object.BudgetingModel);
	
	OpenForm("Task.BudgetTask.Form.GenerationOfLinkedTask", 
		FormParameters, ThisObject, , , , Notification);
	
EndProcedure

&AtClient
Procedure Approve(Command)
	
	SetStatus("Upholded", NStr("vi = 'Đã duyệt';
								|ru = 'Утвержден';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Confermato';
								|pl = 'Zatwierdzony';
								|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	SetStatus("RolledBack_", NStr("vi = 'Hủy bỏ';
									|ru = 'Отменен';
									|en = 'Canceled'; fa = 'لغوشده';
									|it = 'Annullato';
									|pl = 'Canceled';
									|tr = 'İptal edildi'"));
	
EndProcedure

&AtClient
Procedure OpenDocument(Command)
	
	CurrentRow = Items.ApprovedDocuments.CurrentData;
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure("Key", CurrentRow.Document);
	OpenForm(NameOfDocumentForm(CurrentRow.Document), FormParameters, ThisObject);

EndProcedure

&AtClient
Procedure CreateLinkedTask(Command)
	
	ClearMessages();
	If Not ValueIsFilled(Object.Ref) Then
		CommonClient.MessageToUser(NStr("vi = 'Trước khi tạo nhiệm vụ liên quan, cần ghi lại đối tượng';
										|ru = 'Перед созданием связанной задачи необходимо записать объект';
										|en = 'Before creating a linked task, save the object'; fa = 'Before creating a linked task, save the object';
										|it = 'Перед созданием связанной задачи необходимо записать объект';
										|pl = 'Before creating a linked task, save the object';
										|tr = 'Bağlantılı görev oluşturmadan önce, nesnenin kaydedilmesi gerekmektedir'"));
		Return;
	EndIf;
	
	Notification = New CallbackDescription("WhenEnteringParametersForRelatedTask", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("CreatingMultipleTasks", False);
	FormParameters.Insert("SelectABudgetPreparationStep", True);
	FormParameters.Insert("ChooseAnArtist", True);
	FormParameters.Insert("BudgetingModel", Object.BudgetingModel);
	
	OpenForm("Task.BudgetTask.Form.GenerationOfLinkedTask", 
		FormParameters, ThisObject, , , , Notification);
	
EndProcedure

&AtClient
Procedure ClearBudget(Command)
	
	CurrentData = Undefined;
	RowsSelected = New Array();
	For Each RowIndex In Items.DocumentTree.SelectedRows Do
		RowsSelected.Add(DocumentTree.FindByID(RowIndex));	
	EndDo;
	If RowsSelected.Count() = 0
	   And DocumentTree.GetItems().Count() > 0
	   And Not ListVisibility Then
		RowsSelected.Add(DocumentTree.FindByID(0));
	EndIf;
	
	For Each Page1 In RowsSelected Do
		CurrentData = Page1;
		If ValueIsFilled(CurrentData.Document) Then
			FilterParameters = New Structure;
			FilterParameters.Insert("Document",CurrentData.Document);
			
			Rows = Object.DocumentsList.FindRows(FilterParameters);
			If Rows.Count() > 0 Then
				For Each Page1 In Rows Do
					Object.DocumentsList.Delete(Object.DocumentsList.IndexOf(Page1));
				EndDo;
			EndIf;
			
			Modified = True;
			
			CurrentData.Document = Undefined;
			CurrentData.DocumentPresentation = NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Creare';
													|pl = 'Create';
													|tr = 'Oluştur'");
		EndIf;
	EndDo;
	
	If Not ListVisibility Then
		Items.ToPerformTheInputActionBudgets.Title = NStr("vi = '<Nhập ngân sách>';
															|ru = '<Ввести бюджет>';
															|en = '<Enter budget>'; fa = '<Enter budget>';
															|it = '<Inserire il budget>';
															|pl = '<Wprowadź budżet>';
															|tr = '<Bütçeyi gir>'");
		If DocumentTree.GetItems().Count() = 0 Then
			Object.DocumentsList.Clear();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure ReplaceBudget(Command)
	
	CurrentData = Items.DocumentTree.CurrentData;
	If CurrentData = Undefined Then
		TreeItems = DocumentTree.GetItems();
		If TreeItems.Count() > 0 And Not ListVisibility Then
			CurrentData = TreeItems[0];
			If CurrentData.GetItems().Count() > 0 Then
				CurrentData = CurrentData.GetItems()[0];
				If CurrentData.GetItems().Count() > 0 Then
					CurrentData = CurrentData.GetItems()[0];
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	If Object.Action = PredefinedValue(
		"Enum.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules") Then
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"CalculationRule,Scenario,Organization,Department,BeginOfPeriod,Periodicity");
		NameOfStartOfPeriodParameter = "PlanningPeriod";
	ElsIf Object.Action = PredefinedValue(
		"Enum.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance") Then
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"BudgetBalanceItem,Scenario,BeginOfPeriod");
		NameOfStartOfPeriodParameter = "DateOfRemainingGoods";
	Else
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"BudgetProfile,Scenario,Organization,Department,BeginOfPeriod,EndOfPeriod");
		MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
		For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
			ArrayOfParametersNames.Add("Dimension"+DimensionNumber);
		EndDo;
		NameOfStartOfPeriodParameter = "BeginOfPeriod";
	EndIf;
	FormParameters = New Structure;
	If Not CurrentData = Undefined Then
		FormParameters.Insert("Key", CurrentData.Document);
		
		FilterStructure1 = New Structure;
		For Each ParameterName In ArrayOfParametersNames Do
			If ValueIsFilled(CurrentData[ParameterName]) Then
				If ParameterName = "BeginOfPeriod" Then
					FilterStructure1.Insert(NameOfStartOfPeriodParameter, CurrentData[ParameterName]);
				ElsIf ParameterName = "EndOfPeriod" Then
					FilterStructure1.Insert("PeriodEnding", CurrentData[ParameterName]);
				Else
					FilterStructure1.Insert(ParameterName, CurrentData[ParameterName]);
				EndIf;
			EndIf;
		EndDo;
		
		If FilterStructure1.Count() > 0 Then
			FormParameters.Insert("Filter", FilterStructure1);
		EndIf;
	EndIf;
	
	Notification = New CallbackDescription("ReplaceBudgetCompletion", 
		ThisObject,?(CurrentData = Undefined, 0, CurrentData.GetID()));
	
	If ListVisibility Then
		OwnerElement = Items.DocumentTree;
	Else
		OwnerElement = Items.ToPerformTheInputActionBudgets;
	EndIf;
	ChoiceFormName = StringFunctionsClientServer.SubstituteParametersToString("Document.%1.ChoiceForm",
		NameOfBudgetDocumentForIssue(Object.Action));
	OpenForm(ChoiceFormName,FormParameters,OwnerElement,,,,Notification);
	
EndProcedure

&AtClient
Procedure AddBudget(Command)
	
	CurrentData = Items.DocumentTree.CurrentData;
	If CurrentData = Undefined Then
		TreeItems = DocumentTree.GetItems();
		If TreeItems.Count() > 0 And Not ListVisibility Then
			CurrentData = TreeItems[0];
			If CurrentData.GetItems().Count() > 0 Then
				CurrentData = CurrentData.GetItems()[0];
				If CurrentData.GetItems().Count() > 0 Then
					CurrentData = CurrentData.GetItems()[0];
				EndIf;
			EndIf;
		ElsIf Not ListVisibility And TreeItems.Count() = 0 Then
			ExecuteAction(Undefined);
			Return;
		EndIf;
	EndIf;
	
	ArrayDocuments = CreateBudgetByActionLine(CurrentData.GetID(),False,True);
	If ArrayDocuments <> Undefined And ArrayDocuments.Count() > 0 Then
		
		Nw = Object.DocumentsList.Add();
		Nw.Document = ArrayDocuments[0];
		
		Try
			Write();
		Except
			Modified = True;
			Raise NStr("vi = 'Không thể ghi lại nhiệm vụ.
				|Chứng từ theo nhiệm vụ có thể không hợp lệ để thay đổi';
				|ru = 'Не удалось записать задачу. 
				|Документы по задаче могут быть не доступны для изменения';
				|en = 'Cannot save the task. 
				|The task documents might be read-only'; fa = 'Cannot save the task. 
				|The task documents might be read-only';
				|it = 'Impossibile registrare l''obiettivo. 
				|I documenti relativi all''obiettivo potrebbero essere non disponibili alla modifica';
				|pl = 'Brak możliwości zapisu zadania. 
				|Dokumenty dla zadania mogą być nie dostępne dla zmiany';
				|tr = 'Görev kaydedilemiyor.
				| Göreve göre belgeler değişikler için kullanılamayabilir'");
		EndTry;
		
		If Object.DocumentsList.Count() > 1 And Not ListVisibility Then
			ListVisibility = True;
			FormControl();
		ElsIf Object.DocumentsList.Count() = 1 Then
			TextEnterBudget = NStr("vi = '<Nhập ngân sách>';
									|ru = '<Ввести бюджет>';
									|en = '<Enter budget>'; fa = '<Enter budget>';
									|it = '<Inserire il budget>';
									|pl = '<Wprowadź budżet>';
									|tr = '<Bütçeyi gir>'");
			Items.ToPerformTheInputActionBudgets.Title = 
			?(ValueIsFilled(Nw.Document), String(Nw.Document), TextEnterBudget);
		EndIf;
		
		FormParameters = New Structure("Key", ArrayDocuments[0]);
		
		Notification = New CallbackDescription("AddBudgetCompletion", ThisObject, ArrayDocuments[0]);
		
		NameOfDocumentForm = StringFunctionsClientServer.SubstituteParametersToString("Document.%1.ObjectForm",
			NameOfBudgetDocumentForIssue(Object.Action));
		OpenForm(NameOfDocumentForm, FormParameters, Items.DocumentTree,,,, Notification);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshReport(Command)
	GenerateControlReport();
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Function GetCurSessionDate()
	Return CurrentSessionDate();
EndFunction

&AtServer
Procedure MarkTaskCompletionATServer()
	
	SetPrivilegedMode(True);
	
	Object.Executed = True;
	
	CompletionDate = Object.CompletionDate;
	If Not ValueIsFilled(CompletionDate) Then
		Object.CompletionDate = GetCurSessionDate();
	EndIf;
	
	Write();
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure CheckExecutionOfDocumentCreationClient()
	CheckResult = CheckingCompletionOfDocumentCreationTask(Object.Ref);
	If Not CheckResult.Completed2 Then
		TimeConsumingOperationsClient.InitIdleHandlerParameters(IdleHandlerParameters);
		IdleHandlerParameters.IntervalIncreaseCoefficient = 1.2;
		AttachIdleHandler("Attachable_CheckCompletionOfDocumentCreationTask", 1, True);
		
		MessageText = NStr("vi = 'Chứng từ đang được tạo';
							|ru = 'Идет формирование документов';
							|en = 'Documents are being generated'; fa = 'Documents are being generated';
							|it = 'Generazione dei documenti in corso';
							|pl = 'Trwa generowanie dokumentów';
							|tr = 'Belgeler oluşturuluyor'");
		ParametersOfFormToOpen = New Structure("MessageText", MessageText);
		Notification = New CallbackDescription("ProcessingFormClosureAndDocumentCreation", ThisObject);
		TimeConsumingOperationForm = OpenForm("Task.BudgetTask.Form.TaskLockDocumentsGeneration",
			ParametersOfFormToOpen, 
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
EndProcedure

&AtServerNoContext
Function CheckingCompletionOfDocumentCreationTask(Task)
	
	CheckResult = New Structure;
	
	CurVersionOfData = Common.ObjectAttributeValue(Task, "DataVersion");
	CheckResult.Insert("CurVersionOfData", CurVersionOfData);
	
	If Common.FileInfobase() Then
		Completed2 = Not Common.ObjectAttributeValue(Task, "ForDocumentCreation");
	Else
		BudgetingProcess = Common.ObjectAttributeValue(Task, "BudgetingProcess");
		Completed2 = Not Tasks.BudgetTask.BackgroundJobForCreatingDocumentsIsRunning(BudgetingProcess)
		        Or Not Common.ObjectAttributeValue(Task, "ForDocumentCreation");
	EndIf;
	CheckResult.Insert("Completed2", Completed2);
		
	Return CheckResult;
EndFunction

&AtClient
Procedure ProcessingFormClosureAndDocumentCreation(ClosingResult, AdditionalParameters) Export
	If Not ClosingResult = Undefined Then 
		If ClosingResult.CloseTheTask Then
			Close();
		Else
			ReadAndLockTasks();
			ExpandDocumentTree();
		EndIf;
	EndIf;
	DetachIdleHandler("Attachable_CheckCompletionOfDocumentCreationTask");
EndProcedure

&AtServer
Function ReadAndLockTasks()
	
	Result = False;
	
	BeginTransaction();
	Try
		
		BudgetingSteps = New Array;
		BudgetingSteps.Add(Object.BudgetingStep);
		If ValueIsFilled(Object.BudgetingStepBasis) Then
			BudgetingSteps.Add(Object.BudgetingStepBasis);
		EndIf;
		
		TasksToBlock = Tasks.BudgetTask.TasksToBlockWhenEnteringDocuments(Object.BudgetingModel,
		                                                                                   Object.Period,
		                                                                                   BudgetingSteps);
		
		Block = New DataLock;
		LockItem = Block.Add("Task.BudgetTask");
		LockItem.DataSource = TasksToBlock;
		LockItem.UseFromDataSource("Ref", "Ref");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Read();
		
		TaskObject = FormAttributeToValue("Object");
		TaskObject.Lock();
		
		If TaskObject.ForDocumentCreation Then
			TaskObject.ForDocumentCreation = False;
			TaskObject.Write();
		EndIf;
		
		Result = True;
		
		ValueToFormAttribute(TaskObject, "Object");
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		DefaultLanguageCode = Common.DefaultLanguageCode();
		ErrorTextDetailed = NStr("vi = 'Không thể ghi tác vụ do: %1';
								|ru = 'Не удалось записать задачу по причине: %1';
								|en = 'Cannot save the task. Reason: %1'; fa = 'Cannot save the task. Reason: %1';
								|it = 'Non è possibile registrare l''obiettivo a causa di: %1';
								|pl = 'Nie udało się zapisać zadanie z powodu: %1';
								|tr = 'Görev şu sebeple kaydedilemiyor: %1'", DefaultLanguageCode);
		ErrorTextDetailed = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTextDetailed, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(NStr("vi = 'Quy trình ngân sách';
							|ru = 'Бюджетный процесс';
							|en = 'Budget process'; fa = 'فرایند بودجه';
							|it = 'Processo di budget';
							|pl = 'Proces budżetowy';
							|tr = 'Bütçe süreci'", Common.DefaultLanguageCode())
			+ "." + NStr("vi = 'Tạo chứng từ cho nhiệm vụ';
						|ru = 'Создание документов для задачи';
						|en = 'Creating documents for the task'; fa = 'Creating documents for the task';
						|it = 'Creazione dei documenti per il compito';
						|pl = 'Tworzenie dokumentów dla zadania';
						|tr = 'Görevler için belge oluşturma'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorTextDetailed);
		
		ErrorTextIsShort = NStr("vi = 'Không thể ghi tác vụ do: %1';
								|ru = 'Не удалось записать задачу по причине: %1';
								|en = 'Cannot save the task. Reason: %1'; fa = 'Cannot save the task. Reason: %1';
								|it = 'Non è possibile registrare l''obiettivo a causa di: %1';
								|pl = 'Nie udało się zapisać zadanie z powodu: %1';
								|tr = 'Görev şu sebeple kaydedilemiyor: %1'");
		ErrorTextIsShort = StringFunctionsClientServer.SubstituteParametersToString(
			ErrorTextIsShort, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
		Common.MessageToUser(ErrorTextIsShort);
		
	EndTry;
	
	Return Result;
	
EndFunction
&AtServerNoContext
Function NameOfDocumentForm(Document)
	
	MetadataObject = Metadata.FindByType(TypeOf(Document));
	Return MetadataObject.FullName() + ".ObjectForm";
	
EndFunction

&AtServer
Procedure ReturnDocumentsToProductionServer(TaskParameters_, LinesToReturnToTraining)
	
	CacheOfNewTasks = New Map;
	
	For Each Id In LinesToReturnToTraining Do
		
		LineDocument = Object.ApprovedDocuments.FindByID(Id);
		
		BudgetingStep = LineDocument.BudgetingStep;
		EmployeeResponsible          = LineDocument.EmployeeResponsible;
		
		If TypeOf(LineDocument.Document) = Type("DocumentRef.BudgetEntryForm") Then
			
			ActionType = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm;
			
		ElsIf TypeOf(LineDocument.Document) = Type("DocumentRef.RegistrarOfBudgetTurnover") Then
			
			ActionType = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules;
		
		ElsIf TypeOf(LineDocument.Document) = Type(
			"DocumentRef.SettingOfEstimatesOpeningBalance") Then
			
			ActionType = Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance;
			
		ElsIf TypeOf(LineDocument.Document) = Type("DocumentRef.PurchasePlan")
			Or TypeOf(LineDocument.Document) = Type("DocumentRef.SalesPlan")
			Or TypeOf(LineDocument.Document) = Type("DocumentRef.PlanOfGoodsStock")
			Or TypeOf(LineDocument.Document) = Type("DocumentRef.ProductionPlan")
			Or TypeOf(LineDocument.Document) = Type("DocumentRef.AssemblyDisassemblyPlan")
			Or TypeOf(LineDocument.Document) = Type("DocumentRef.InventoryConsumptionPlan") Then
			
			ActionType = Enums.TypesOfBudgetingStepActions.PlanEntry;
			
		Else
			
			Raise NStr("vi = 'Chưa xác định kiểu hành động đối với nhiệm vụ.';
						|ru = 'Тип действия для задачи не определен.';
						|en = 'Action type for the task is not determined.'; fa = 'Action type for the task is not determined.';
						|it = 'Il tipo di azione per l''obiettivo non è stato definito.';
						|pl = 'Typ działania do zadania nie jest zdefiniowany.';
						|tr = 'Görevler için eylem türü belirtilmemiş.'");
			
		EndIf;
		
		If ActionType = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm Then
			
			CacheIssues = CacheOfNewTasks.Get(BudgetingStep);
			If CacheIssues = Undefined Then
				CacheIssues = New Map;
				CacheOfNewTasks.Insert(BudgetingStep, CacheIssues);
			EndIf;
			
			TaskObject = CacheIssues.Get(EmployeeResponsible);
			If TaskObject = Undefined Then
				TaskObject = Tasks.BudgetTask.CreateTask();
				CacheIssues.Insert(EmployeeResponsible, TaskObject);
			EndIf;
			
		Else
			
			TaskObject = Tasks.BudgetTask.CreateTask();
			
		EndIf;
		
		FillPropertyValues(TaskObject, TaskParameters_);
		
		TaskObject.Date					= CurrentSessionDate();
		TaskObject.BudgetingModel 	= Object.BudgetingModel;
		TaskObject.BudgetingStep	= Object.BudgetingStep;
		TaskObject.Period					= Object.Period;
		TaskObject.MainTask_			= Object.Ref;
		
		TaskObject.BudgetingStepBasis		= BudgetingStep;
		TaskObject.Performer							= EmployeeResponsible;
		TaskObject.Action								= ActionType;
		TaskObject.DocumentsList.Add().Document 	= LineDocument.Document;
		
		TaskObject.SettingOfAction = Common.ObjectAttributeValue(BudgetingStep, "SettingOfAction");
		
		TaskObject.Author = Users.AuthorizedUser();
		
		TaskObject.Write();
		
	EndDo;
	
EndProcedure

&AtServer
Function PlaceActionSettingsInTemporaryStorage(Val SettingsTable = Undefined)
		
	If SettingsTable = Undefined Then
		SettingsTable = New ValueTable;
		SettingsTable.Columns.Add("Name");
		SettingsTable.Columns.Add("Value");
		SettingsTable.Columns.Add("Presentation");
	EndIf;
	
	If ValueIsFilled(AddressActionSetting) Then
		AddressActionSetting = PutToTempStorage(SettingsTable, AddressActionSetting);
	Else
		AddressActionSetting = PutToTempStorage(SettingsTable, UUID);
	EndIf;
	
	Return AddressActionSetting;
	
EndFunction

&AtServer
Function GetActionSettingsFromTemporaryStorage()
	
	SettingsTable = New ValueTable;
	SettingsTable.Columns.Add("Name");
	SettingsTable.Columns.Add("Value");
	SettingsTable.Columns.Add("Presentation");

	If ValueIsFilled(AddressActionSetting) Then
		SettingsTable = GetFromTempStorage(AddressActionSetting);
	EndIf;
	
	Return SettingsTable;
	
EndFunction

&AtClient
Procedure WhenEnteringTaskParametersReturnToPreparation(TaskParameters_, AdditionalParameters) Export
	
	If TaskParameters_ <> Undefined Then
		ReturnDocumentsToProductionServer(TaskParameters_, AdditionalParameters.LinesToReturnToTraining);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenEnteringParametersForRelatedTask(TaskParameters_, AdditionalParameters) Export
	
	If TaskParameters_ <> Undefined Then
		CreateLinkedTaskServer(TaskParameters_);
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenClosingActionSettingsForm(Address, AdditionalParameters) Export
	
	If Address = Undefined Then
		Return;
	EndIf;
	
	FormControl();
	
EndProcedure

&AtServerNoContext
Function CheckNeedToCreateNewDocumentServer(Document, Action, ListVisibility)
	
	Return	Tasks.BudgetTask.YouNeedToCreateNewDocument(Document, Action, ListVisibility);
	
EndFunction

&AtClient
Procedure ExecuteWriteObject(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Write();
		If TypeOf(AdditionalParameters) = Type("CallbackDescription") Then
			RunCallback(AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureListOfTaskActions()
	
	If Not (GetFunctionalOption("UsePurchasePlanning")
		Or GetFunctionalOption("UseSalesPlans")
		Or GetFunctionalOption("UseProductionPlanning")
		Or GetFunctionalOption("UseAssemblyDisassemblyPlanning")
		Or GetFunctionalOption("UsePlanningOfInventoryConsumption")) Then
		RemoveActionFromList(Enums.TypesOfBudgetingStepActions.PlanEntry);
	EndIf;
	
	If Not Object.BudgetingModel.IsEmpty() Then
	
		ModelDetails = Common.ObjectAttributesValues(
			Object.BudgetingModel, "UseBudgetConfirmation");
			
		If Not ModelDetails.UseBudgetConfirmation Then
			RemoveActionFromList(Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure RemoveActionFromList(ActionType)
	
	ListItem = Items.Action.ChoiceList.FindByValue(ActionType);
	If ListItem <> Undefined Then
		Items.Action.ChoiceList.Delete(ListItem);
	EndIf;
	
EndProcedure

&AtServer
Procedure ActionOnChangeServer()
	
	If Object.Action = CurrentAction1 Then
		Return;
	EndIf;
	
	AddressActionSetting = "";
	
	Object.DocumentsList.Clear();
	
	CurrentAction1 = Object.Action;
	
	FormControl();
	
EndProcedure

&AtServer
Procedure FillInListOfRelatedTasks(Tree, TotalTaskCount, Completed2, TopLevelTask)
	
	If Tree = Undefined Then
		Return;
	EndIf;
	
	For Each TreeRow In Tree.Rows Do
		If TreeRow.Task = TopLevelTask Then
			Continue;
		EndIf;
		TotalTaskCount = TotalTaskCount + 1;
		If TreeRow.TaskExecuted Then
			Completed2 = Completed2 + 1;
		EndIf;
		FillInListOfRelatedTasks(TreeRow, TotalTaskCount, Completed2, TreeRow.Task);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function NameOfConfigurationFormOnServer(Val Action)
	
	If Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
		Or Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm;
	ElsIf Action = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets;
	EndIf;

	Return Enums.TypesOfBudgetingStepActions.FormName(Action)
	
EndFunction

&AtServer
Procedure FormControl()
	
	UpdateStatusOfApprovedDocuments();
	
	SetActionPresentation();
	
	ThisActionIsOther = (Object.Action = Enums.TypesOfBudgetingStepActions.Other);
	ThisIsAssertionAction = (Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		Or Object.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover);
	Items.ApprovedDocumentsPage.Visible = ThisIsAssertionAction;
	Items.ConfirmationGroup.Visible = ThisIsAssertionAction;
	
	VisibilityOfSettings = ValueIsFilled(Object.Action) And Not ThisActionIsOther;
	Items.ActionSettings.Visible = VisibilityOfSettings;
	
	SettingOfAction = GetActionSettingsFromTemporaryStorage();
	SettingPresentation =
		Enums.TypesOfBudgetingStepActions.GetActionPresentation(SettingOfAction, Object.Action);
	Items.DecorationSettings.Title = SettingPresentation;
	
	ReportCount = MonitoringReportSettings.Count();
	ThereAreControlReports = (ReportCount > 0);
	
	Items.ControlReportPage.Visible = ThereAreControlReports;
	
	Items.GroupToPerformTheActionHyperlink.Visible = Not ListVisibility;
	Items.GroupToPerformTheActionList.Visible = ListVisibility;
	
	If ListVisibility Then
		Items.TaskInformation.Title = NStr("vi = 'Chứng từ nhiệm vụ';
											|ru = 'Документы по задаче';
											|en = 'Documents by task'; fa = 'Documents by task';
											|it = 'Documenti relativi all''obiettivo';
											|pl = 'Dokumenty dot. zadania';
											|tr = 'Göreve göre belgeler'");
	Else
		Items.TaskInformation.Title = NStr("vi = 'Nhiệm vụ hành động';
											|ru = 'Действие задачи';
											|en = 'Task action'; fa = 'اقدام وظیفه';
											|it = 'Azione dell''obiettivo';
											|pl = 'Czynność zadania';
											|tr = 'Görev eylemi'");
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPeriodOfTaskWhenItChangesOnServer()
	
	If Not ValueIsFilled(Object.Period) Then
		Object.Period = CurrentSessionDate();
	EndIf;
	
	Attributes = New Structure();
	Attributes.Insert("Action", "Action");
	Attributes.Insert("SettingOfAction", "SettingOfAction");
	Attributes.Insert("MonitoringReportSettings", "MonitoringReportSettings");
	Attributes.Insert("Periodicity", "Parent.Periodicity");
	Attributes.Insert("DurationType", "DurationType");
	Attributes.Insert("Duration", "Duration");
	ValueOfBankingDetails = Common.ObjectAttributesValues(Object.BudgetingStep, Attributes);
	
	Object.Action = ValueOfBankingDetails.Action;
	Periodicity = ValueOfBankingDetails.Periodicity;
	Tasks.BudgetTask.SetTaskDuration(Object, ValueOfBankingDetails);
	Object.Period = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Object.Period, Periodicity);
	
	ActionSettingsTable = New ValueTable();
	If ValueOfBankingDetails.SettingOfAction <> Undefined Then
		ActionSettingsTable = ValueOfBankingDetails.SettingOfAction.Get();
		If ActionSettingsTable <> Undefined Then
			PlaceActionSettingsInTemporaryStorage(ActionSettingsTable);
			MultipleInstances(ActionSettingsTable);
			If Object.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
				Or Object.Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets
				Or Object.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
				Or Object.Action
				= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
				UpdateDocumentTree(ActionSettingsTable);
			EndIf;
		EndIf;
	EndIf;

	If ValueOfBankingDetails.MonitoringReportSettings <> Undefined Then
		ControlReportSettingsTable = ValueOfBankingDetails.MonitoringReportSettings.Get();
		If ControlReportSettingsTable <> Undefined Then
			MonitoringReportSettings.Load(ControlReportSettingsTable);
		EndIf;
	EndIf;
	
	TableOfApprovedDocuments = Tasks.BudgetTask.ApprovedDocumentsForProcessStep(
		Object.Action,
		ActionSettingsTable,
		Object.Period);
	Object.ApprovedDocuments.Load(TableOfApprovedDocuments);
	
	LabelPeriod = WorkingWithClientServerPeriods.PresentationOfPeriodByDate(Object.Period, Periodicity);
	
	FormControl();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfBudgetingModel()
	
	NumberOfActiveModels
		= Catalogs.BudgetingModels.NumberOfExistingBudgetingModels();
		
	TMCommonUseClientServer.SetFormItemProperty(
		Items, 
		"BudgetingModel", 
		"Visible", 
		NumberOfActiveModels <> 1 Or Not ValueIsFilled(Object.BudgetingModel));
	
EndProcedure

&AtServer
Procedure SetActionPresentation()
	
	Action = Object.Action;
	
	ActionFilled = ValueIsFilled(Action);
	ThisActionIsOther = (Action = Enums.TypesOfBudgetingStepActions.Other);
	
	PresentationAction = NStr("vi = 'Thực hiện thao tác';
								|ru = 'Выполнить действие';
								|en = 'Execute action'; fa = 'اجرای اقدام';
								|it = 'Eseguire l''azione';
								|pl = 'Wykonaj akcję';
								|tr = 'Eylemi gerçekleştir'");
	If Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Nhập ngân sách>';
							|ru = '<Ввести бюджет>';
							|en = '<Enter budget>'; fa = '<Enter budget>';
							|it = '<Inserire il budget>';
							|pl = '<Wprowadź budżet>';
							|tr = '<Bütçeyi gir>'");
		PresentationAction = 
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.AdjustCorrectBudgets Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Điều chỉnh ngân sách>';
							|ru = '<Скорректировать бюджет>';
							|en = '<Adjust budget>'; fa = '<Adjust budget>';
							|it = '<Скорректировать бюджет>';
							|pl = '<Adjust budget>';
							|tr = '<Bütçeyi düzelt>'");
		PresentationAction = 
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Tạo phát sinh của ngân sách>';
							|ru = '<Сформировать обороты бюджетов>';
							|en = '<Generate budget turnovers>'; fa = '<Generate budget turnovers>';
							|it = '<Generate budget turnovers>';
							|pl = '<Generate budget turnovers>';
							|tr = '<Bütçe cirolarını oluştur>'");
		PresentationAction = 
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.SetCashFlowLimits Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Đặt hạn mức dòng tiền>';
							|ru = '<Установить лимиты расхода денежных средств>';
							|en = '<Set cash flow limits>'; fa = '<Set cash flow limits>';
							|it = '<Impostare i limiti di spesa in contanti>';
							|pl = '<Ustaw limity wydatków środków pieniężnych>';
							|tr = '<Nakit akışı limitlerini ayarla>'");
		PresentationAction =
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.PlanEntry Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Nhập kế hoạch>';
							|ru = '<Ввести план>';
							|en = '<Enter plan>'; fa = '<Enter plan>';
							|it = '<Inserire il piano>';
							|pl = '<Wprowadź plan>';
							|tr = '<Planı gir>'");
		PresentationAction = 
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.SetValuesForNonFinancialItems Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Nhập giá trị của các chỉ số phi tài chính>';
							|ru = '<Ввести значения нефинансовых показателей>';
							|en = '<Enter non-financial item values>'; fa = '<Enter non-financial item values>';
							|it = '<Inserire i valori degli indici non finanziari>';
							|pl = '<Wprowadź wartość wskaźników niefinansowych>';
							|tr = '<Finansal olmayan öğelerin değerlerini girin>'");
		PresentationAction =
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		Document = CurrentDocument(Object.DocumentsList);
		ActionText = NStr("vi = '<Nhập số dư của chỉ tiêu tính toán>';
							|ru = '<Ввести остатки расчетных показателей>';
							|en = '<Enter the balance of estimates>'; fa = '<Enter the balance of estimates>';
							|it = '<Enter the balance of estimates>';
							|pl = '<Enter the balance of estimates>';
							|tr = '<Hesaplanan gösterge bakiyelerini gir>'");
		PresentationAction = 
			?(ValueIsFilled(Document), String(Document), ActionText);
			
	ElsIf Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets Then
		TotalDocuments = Object.ApprovedDocuments.Count();
		
		FilterParameters = New Structure("Status", Enums.PlanStatuses.Upholded);
		Confirmed = Object.ApprovedDocuments.FindRows(FilterParameters).Count();
		
		FilterParameters = New Structure("Status", Enums.PlanStatuses.RolledBack_);
		Canceled = Object.ApprovedDocuments.FindRows(FilterParameters).Count();
		
		FilterParameters = New Structure("Status", Enums.PlanStatuses.AwaitingConfirmation);
		ForConfirmation = Object.ApprovedDocuments.FindRows(FilterParameters).Count();
		
		FilterParameters = New Structure("Status", Enums.PlanStatuses.UnderPreparation);
		UnderPreparation = Object.ApprovedDocuments.FindRows(FilterParameters).Count();
		
		If TotalDocuments = 0 Then
			PresentationAction = NStr("vi = 'Không có chứng từ cần phê duyệt';
										|ru = 'Нет документов к утверждению';
										|en = 'No documents for confirmation'; fa = 'No documents for confirmation';
										|it = 'Nessun documento do approvare';
										|pl = 'Brak dokumentów do zatwierdzenia';
										|tr = 'Onaylanacak belge mevcut değil'");
		ElsIf Confirmed = TotalDocuments Then
			PresentationAction = NStr("vi = 'Tất cả các chứng từ đã được duyệt';
										|ru = 'Все документы утверждены';
										|en = 'All documents are confirmed'; fa = 'All documents are confirmed';
										|it = 'Tutti i documenti sono stati approvati';
										|pl = 'Wszystkie dokumenty zatwierdzone';
										|tr = 'Tüm belgeler onaylandı'");
		ElsIf Canceled = TotalDocuments Then
			PresentationAction = NStr("vi = 'Tất cả các chứng từ bị hủy bỏ.';
										|ru = 'Все документы отменены';
										|en = 'All documents are canceled'; fa = 'All documents are canceled';
										|it = 'Tutti i documenti sono stati annullati';
										|pl = 'Wszystkie dokumenty anulowano';
										|tr = 'Tüm belgeler iptal edildi'");
		ElsIf TotalDocuments = Confirmed + Canceled Then
			PresentationAction = NStr("vi = 'Đã duyệt: %1 %3, Đã hủy: %2 %4';
										|ru = 'Утверждены: %1 %3, отменены: %2 %4';
										|en = 'Approved: %1 %3, canceled: %2 %4'; fa = 'Approved: %1 %3, canceled: %2 %4';
										|it = 'Approvati: %1 %3, annullati: %2 %4';
										|pl = 'Zatwierdzono: %1 %3, anulowano: %2 %4';
										|tr = 'Onaylananlar: %1 %3, iptal edilenler: %2 %4'");
			PresentationAction = 
				StringFunctionsClientServer.SubstituteParametersToString(PresentationAction, 
					Confirmed, 
					Canceled,
					DeclinationOfDocuments(Confirmed),
					DeclinationOfDocuments(Canceled));
		ElsIf ForConfirmation <> 0 And UnderPreparation <> 0 Then
			PresentationAction = NStr("vi = 'Cần phê duyệt: %1 %3, chưa sẵn sàng phê duyệt: %2 %4';
										|ru = 'К утверждению: %1 %3, не готовы к утверждению: %2 %4';
										|en = 'For confirmation: %1 %3, not ready for confirmation: %2 %4'; fa = 'For confirmation: %1 %3, not ready for confirmation: %2 %4';
										|it = 'Da approvare: %1 %3, non pronti per l''approvazione: %2 %4';
										|pl = 'Do zatwierdzenia: %1 %3, nie jest gotowy do zatwierdzenia: %2 %4';
										|tr = 'Onaylamaya:%1 %3,onaylamaya hazır değil: %2 %4'");
			PresentationAction = 
				StringFunctionsClientServer.SubstituteParametersToString(PresentationAction, 
					ForConfirmation, 
					UnderPreparation,
					DeclinationOfDocuments(ForConfirmation),
					DeclinationOfDocuments(UnderPreparation));
		ElsIf UnderPreparation <> 0 Then
			PresentationAction = NStr("vi = 'Chưa sẵn sàng để phê duyệt: %1 %2';
										|ru = 'Не готовы к утверждению: %1 %2';
										|en = 'Not ready for confirmation: %1 %2'; fa = 'Not ready for confirmation: %1 %2';
										|it = 'Non pronti per l''approvazione: %1%2';
										|pl = 'Nie jest gotowy do zatwierdzenia: %1 %2';
										|tr = 'Onaylanma işlemine hazır değiller: %1%2'");
			PresentationAction = StringFunctionsClientServer.SubstituteParametersToString(PresentationAction, 
				UnderPreparation,
				DeclinationOfDocuments(UnderPreparation));
		Else 
			PresentationAction = NStr("vi = 'Cần phê duyệt: %1 %2';
										|ru = 'К утверждению: %1 %2';
										|en = 'For confirmation: %1 %2'; fa = 'For confirmation: %1 %2';
										|it = 'Da approvare: %1 %2';
										|pl = 'Do zatwierdzenia: %1 %2';
										|tr = 'Onaylanma işlemine: %1%2'");
			PresentationAction = StringFunctionsClientServer.SubstituteParametersToString(PresentationAction, 
				ForConfirmation,
				DeclinationOfDocuments(ForConfirmation));
		EndIf;
		
	EndIf;
	
	Items.ExecuteAction.Visible = ActionFilled And Not ThisActionIsOther 
		And Not Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm;	
	Items.ExecuteAction.Title = PresentationAction;
	
	Items.ToPerformTheInputActionBudgets.Visible =
		(Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm);
	Items.ToPerformTheInputActionBudgets.Title = PresentationAction;
	
EndProcedure

&AtServer
Function DeclinationOfDocuments(NumberOfDocuments_)
	
	Return TMCommonUseClientServer.DeclensionOfWord(
		NumberOfDocuments_, 
		NStr("vi = 'chứng từ, chứng từ, chứng từ, m';
			|ru = 'документ, документа, документов, м';
			|en = 'document, documents'; fa = 'document, documents';
			|it = 'документ, документа, документов, м';
			|pl = 'document, documents';
			|tr = 'belge, belgeler, belgeler, m'"));
	
EndFunction

&AtClient
Procedure ExecuteActionClient()
	
	If Object.Action = PredefinedValue("Enum.TypesOfBudgetingStepActions.ApprovalOfBudgets") Then
		Items.MainPanel.CurrentPage = Items.ApprovedDocumentsPage;
	Else
		Result = ExecuteActionServer();
		If Result <> Undefined Then
			OpenForm(Result.FormName, Result.FormParameters, ThisObject, Result.Uniqueness);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CreateNewDocument(QuestionResult, AddlParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		ExecuteActionClient();
	EndIf;
	
EndProcedure

&AtServer
Function ExecuteActionServer()
	
	If Not CheckFilling() Then
		Return Undefined;
	EndIf;
	
	Write = False;
	
	ErrorText = "";
	ActionSettings = GetActionSettingsFromTemporaryStorage();
	Result = Tasks.BudgetTask.ExecuteAction(Object,
	                                                     ActionSettings,
	                                                     Write,
	                                                     True,
	                                                     ErrorText);
	
	If ValueIsFilled(ErrorText) Then
		Common.MessageToUser(ErrorText);
	EndIf;
	
	If Write Then
		Write();
	EndIf;
	
	SetActionPresentation();
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function CurrentDocument(DocumentsList)
	
	Return ?(DocumentsList.Count(), DocumentsList[DocumentsList.Count()-1].Document, Undefined);
	
EndFunction

&AtServer
Procedure UpdateStatusOfApprovedDocuments()
	
	If Object.Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		And Object.Action <> Enums.TypesOfBudgetingStepActions.ApprovalOfGeneratedBudgetTurnover Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ApprovedDocuments.LineNumber,
	|	ApprovedDocuments.Document,
	|	ApprovedDocuments.BudgetingStep
	|INTO ApprovedDocuments
	|FROM
	|	&ApprovedDocuments AS ApprovedDocuments
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ApprovedDocuments.LineNumber AS LineNumber,
	|	ApprovedDocuments.Document,
	|	BudgetingSteps.EmployeeResponsible,
	|	CASE
	|		WHEN NOT BudgetEntryForm.Ref IS NULL 
	|			THEN BudgetEntryForm.Status
	|		WHEN NOT RegistrarOfBudgetTurnover.Ref IS NULL 
	|			THEN RegistrarOfBudgetTurnover.Status
	|		WHEN NOT PurchasePlan.Ref IS NULL 
	|			THEN PurchasePlan.Status
	|		WHEN NOT SalesPlan.Ref IS NULL 
	|			THEN SalesPlan.Status
	|		WHEN NOT ProductionPlan.Ref IS NULL 
	|			THEN ProductionPlan.Status
	|		WHEN NOT AssemblyDisassemblyPlan.Ref IS NULL 
	|			THEN AssemblyDisassemblyPlan.Status
	|		WHEN NOT InventoryConsumptionPlan.Ref IS NULL 
	|			THEN InventoryConsumptionPlan.Status
	|		WHEN NOT PlanOfGoodsStock.Ref IS NULL 
	|			THEN PlanOfGoodsStock.Status
	|	END AS Status
	|FROM
	|	ApprovedDocuments AS ApprovedDocuments
	|		LEFT JOIN Catalog.BudgetingSteps AS BudgetingSteps
	|		ON ApprovedDocuments.BudgetingStep = BudgetingSteps.Ref
	|		LEFT JOIN Document.BudgetEntryForm AS BudgetEntryForm
	|		ON ApprovedDocuments.Document = BudgetEntryForm.Ref
	|		LEFT JOIN Document.RegistrarOfBudgetTurnover AS RegistrarOfBudgetTurnover
	|		ON ApprovedDocuments.Document = RegistrarOfBudgetTurnover.Ref
	|		LEFT JOIN Document.PurchasePlan AS PurchasePlan
	|		ON ApprovedDocuments.Document = PurchasePlan.Ref
	|		LEFT JOIN Document.SalesPlan AS SalesPlan
	|		ON ApprovedDocuments.Document = SalesPlan.Ref
	|		LEFT JOIN Document.ProductionPlan AS ProductionPlan
	|		ON ApprovedDocuments.Document = ProductionPlan.Ref
	|		LEFT JOIN Document.AssemblyDisassemblyPlan AS AssemblyDisassemblyPlan
	|		ON ApprovedDocuments.Document = AssemblyDisassemblyPlan.Ref
	|		LEFT JOIN Document.InventoryConsumptionPlan AS InventoryConsumptionPlan
	|		ON ApprovedDocuments.Document = InventoryConsumptionPlan.Ref
	|		LEFT JOIN Document.PlanOfGoodsStock AS PlanOfGoodsStock
	|		ON ApprovedDocuments.Document = PlanOfGoodsStock.Ref
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("ApprovedDocuments", Object.ApprovedDocuments.Unload());
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	Selection.Next();
	
	For Each String In Object.ApprovedDocuments Do
		If String.LineNumber <> Selection.LineNumber Then
			Selection.Next();
		EndIf;
		String.Status = Selection.Status;
		String.EmployeeResponsible = Selection.EmployeeResponsible;
	EndDo;
	
EndProcedure

&AtClient
Procedure SetStatus(Status, TexStatus)
	
	DocumentsForSettingStatus = New Array;
	For Each Id In Items.ApprovedDocuments.SelectedRows Do
		Document = Object.ApprovedDocuments.FindByID(Id).Document;
		DocumentsForSettingStatus.Add(Document);
	EndDo;
	
	If DocumentsForSettingStatus.Count() = 0 Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = 
		GeneralPurposeTMServerCall.SetStatusOfDocuments(DocumentsForSettingStatus, Status);
	
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ApprovedDocuments,
		ProcessedItemsCount, DocumentsForSettingStatus.Count(), TexStatus);
	
	FormControl();
	
EndProcedure

&AtServer
Procedure CreateLinkedTaskServer(TaskParameters_)
	
	AsPartOfAnotherStep = 
		TaskParameters_.Property("BudgetingStep")
		And TaskParameters_.BudgetingStep <> Object.BudgetingStep;
	
	If AsPartOfAnotherStep Then
		FillingData = TaskParameters_.BudgetingStep;
	Else
		FillingData = New Structure("BudgetingModel, BudgetingStep, Action, Period, Document");
		FillPropertyValues(FillingData, Object);
		FillingData.Insert("SettingOfAction",
			New ValueStorage(GetActionSettingsFromTemporaryStorage()));
		FillingData.Insert("MonitoringReportSettings",
			New ValueStorage(MonitoringReportSettings.Unload()));
	EndIf;
	
	NewTask = Tasks.BudgetTask.CreateTask();
	NewTask.Fill(FillingData);
	FillPropertyValues(NewTask, TaskParameters_, "Description, TaskDueDate, TaskDetails1, Performer");
	
	NewTask.MainTask_ = Object.Ref;
	NewTask.Period = Object.Period;
	NewTask.BudgetingStepBasis = Object.BudgetingStep;
	
	If NewTask.Action = Enums.TypesOfBudgetingStepActions.ApprovalOfBudgets
		And Not AsPartOfAnotherStep Then
		NewTask.ApprovedDocuments.Load(Object.ApprovedDocuments.Unload());
	EndIf;
	
	NewTask.Write();
	
	UpdateInformationOnRelatedTasks();
	
EndProcedure

&AtServer
Procedure UpdateInformationOnRelatedTasks()
	
	SubordinateTaskTree = Tasks.BudgetTask.SubordinateTasks(Object.Ref);
	FoundRow = SubordinateTaskTree.Rows.Find(Object.Ref, , True);
	TotalTaskCount = 0;
	Completed2 = 0;
	FillInListOfRelatedTasks(FoundRow, TotalTaskCount, Completed2, Object.Ref);
	If TotalTaskCount Then
		Items.TheInscriptionIsCompleted.Title = NStr("vi = 'Hoàn thành %1 từ %2';
													|ru = 'Выполнено %1 из %2';
													|en = 'Completed %1 out of %2'; fa = 'Completed %1 out of %2';
													|it = 'Completati %1 da %2';
													|pl = 'Wykonano %1 z %2';
													|tr = '%2''den %1 tamamlandı'");
		Items.TheInscriptionIsCompleted.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.TheInscriptionIsCompleted.Title,
			Completed2,
			TotalTaskCount);
	Else
		Items.TheInscriptionIsCompleted.Title = NStr("vi = 'Không có nhiệm vụ liên quan';
													|ru = 'Связанные задачи не назначены';
													|en = 'Linked tasks are not assigned'; fa = 'وظایف مرتبط تخصیص نیافته‌اند';
													|it = 'Obiettivi correlati non assegnati';
													|pl = 'Związane zadania nie są przypisane';
													|tr = 'İlgili görevler atanmadı'");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDocumentTree(Val ActionSettingsTable, AllDocuments = False)
	
	If TypeOf(ActionSettingsTable) = Type("String") Then
		ActionSettingsTable = GetFromTempStorage(ActionSettingsTable);
	EndIf;
	
	DocumentTree.GetItems().Clear();
	
	DocumentPeriod_ = Object.Period;
	If Not ValueIsFilled(DocumentPeriod_) Then
		DocumentPeriod_ = CurrentSessionDate();
	EndIf;

	Attributes = New Structure("Periodicity, Action", "Parent.Periodicity");
	Attributes = Common.ObjectAttributesValues(Object.BudgetingStep, Attributes);
	Periodicity = Attributes.Periodicity;

	BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(DocumentPeriod_, Periodicity);
	EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(DocumentPeriod_, Periodicity);
	
	VTDocuments = Object.DocumentsList.Unload();
	DocumentsArray = VTDocuments.UnloadColumn("Document");
		
	BudgetEntryTree = Tasks.BudgetTask.ParametersForEnteringBudgetsByActionSettings(
		ActionSettingsTable, Attributes.Action,
		BeginOfPeriod,
		EndOfPeriod,
		Periodicity,
		?(AllDocuments,Undefined,DocumentsArray));
		
	If Not BudgetEntryTree = Undefined Then
		ValueToFormAttribute(BudgetEntryTree,"DocumentTree");
	EndIf;
	
	If AllDocuments And Not BudgetEntryTree = Undefined Then
		Object.DocumentsList.Clear();
		For Each BudgetViewLine In BudgetEntryTree.Rows Do
			If ValueIsFilled(BudgetViewLine.Document) Then
				Nw = Object.DocumentsList.Add();
				Nw.Document = BudgetViewLine.Document;
			EndIf;
			For Each StringPeriod In BudgetViewLine.Rows Do
				If ValueIsFilled(StringPeriod.Document) Then
					Nw = Object.DocumentsList.Add();
					Nw.Document = StringPeriod.Document;
				EndIf;
				For Each AnalyticsLine In StringPeriod.Rows Do
					If ValueIsFilled(AnalyticsLine.Document) Then
						Nw = Object.DocumentsList.Add();
						Nw.Document = AnalyticsLine.Document;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function GenerateAllBudgetsByActionSettings(DonTCheckExistingDocuments = False)
	
	If Not Object.Action = Enums.TypesOfBudgetingStepActions.FillingBudgetEntryForm
		And Not Object.Action = Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules
		And Not Object.Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance Then
		Return Undefined;
	EndIf;
	
	BudgetEntryTree = FormAttributeToValue("DocumentTree");
	
	NewDocumentParameters = New Structure("Period, BudgetingModel, BudgetingStep");
	FillPropertyValues(NewDocumentParameters, Object);
	NewDocumentParameters.Insert("BudgetTask", Object.Ref);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("NewDocumentParameters",NewDocumentParameters);
	ReportParameters.Insert("BudgetEntryTree",BudgetEntryTree);
	ReportParameters.Insert("DonTCheckExistingDocuments",DonTCheckExistingDocuments);
	
	TimeConsumingOperations.CancelJobExecution(BudgetGenerationJobID);
	
	BudgetGenerationJobID = Undefined;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion =0;
	
	ExecutionParameters.BackgroundJobDescription =
		TMReportFunctionsClientServer.GetNameOfReportExecutionTask(ThisObject);
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Tasks.BudgetTask.GenerateBudgetsBasedOnBackgroundActionSettings",
		ReportParameters,
		ExecutionParameters);
	
	BudgetGenerationJobID = ExecutionResult.JobID;
	
	Return ExecutionResult;

EndFunction

&AtServer
Function CreateBudgetByActionLine(RowID, OnlyFindExistingOnes = False, CopyRow = False)
	
	ActionString = DocumentTree.FindByID(RowID);
	
	If ActionString = Undefined Then
		Return New Array();
	EndIf;
	
	If ValueIsFilled(ActionString.Document) And Not CopyRow Then
		ArrayDocuments = New Array();
		ArrayDocuments.Add(ActionString.Document);
		Return ArrayDocuments;
	EndIf;
	
	BudgetEntryTree = FormAttributeToValue("DocumentTree");
	ActionStructure = Tasks.BudgetTask.ActionStringParameters(ActionString, BudgetEntryTree.Columns);
	
	NewDocumentParameters = New Structure("Period, BudgetingModel, BudgetingStep");
	FillPropertyValues(NewDocumentParameters, Object);
	NewDocumentParameters.Insert("BudgetTask", Object.Ref);
	
	If OnlyFindExistingOnes Then
		ArrayDocuments = Tasks.BudgetTask.FindDocumentByPaddingValues(NameOfBudgetDocumentForIssue(
			Object.Action), ActionStructure);
	ElsIf ValueIsFilled(ActionString.CalculationRule) Then
		ArrayDocuments = Tasks.BudgetTask.CreateBudgetTurnoverLogger(NewDocumentParameters,
			ActionStructure, True);
	ElsIf ValueIsFilled(ActionString.BudgetBalanceItem) Then
		ArrayDocuments = Tasks.BudgetTask.CreateInstallationOfOpeningBalancesOfCalculatedIndicators(
			NewDocumentParameters, ActionStructure, False);
	Else
		ArrayDocuments = Tasks.BudgetTask.CreateBudgetEntryDocument(NewDocumentParameters,
			ActionStructure, True, True);
	EndIf;
	
	Return ArrayDocuments;
	
EndFunction

&AtClient
Procedure TypeOfControlReportSelectionCompletion(SelectionResult, AdditionalParameters) Export
	
	If SelectionResult <> Undefined Then
		MonitoringReportIndex = SelectionResult.Value;
		MonitoringReportKind = SelectionResult.Presentation;
		GenerateControlReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateControlReport()
	
	ReportParameters = PrepareReportParameters();
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Budget, "ReportGeneration");
	
	ExecutionResult = GenerateControlReportServer(ReportParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	CallbackOnCompletion = New CallbackDescription("GenerateControlReportNotification", ThisObject);

	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure GenerateControlReportNotification(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	LoadPreparedData(Result.ResultAddress);
	
EndProcedure

&AtServer
Function PrepareReportParameters()
	
	CurrentRow = MonitoringReportSettings.FindByID(MonitoringReportIndex);
	
	If CurrentRow = Undefined Then
		Return Undefined;
	EndIf;
	
	If Not ValueIsFilled(CurrentRow.BudgetProfile) Then
		Raise NStr("vi = 'Không xác định dạng ngân sách để xây dựng báo cáo.';
					|ru = 'Не определен Вид бюджета для построения отчета.';
					|en = 'Budget profile to use for report generation is not determined.'; fa = 'Budget profile to use for report generation is not determined.';
					|it = 'Non è stata definita la Tipologia di budget per generare il report.';
					|pl = 'Nieokreślony Typ budżetu do budowania raportu.';
					|tr = 'Raporun inşası için Bütçe profili belirtilmemiş.'")
	EndIf;
	
	ReportParameters = New Structure();
	ReportParameters.Insert("BudgetingModel", Object.BudgetingModel);
	ReportParameters.Insert("BudgetProfile", CurrentRow.BudgetProfile);
	ReportParameters.Insert("Scenario", CurrentRow.Scenario);
	If CurrentRow.Departments.Count() > 0 Then
		ReportParameters.Insert("Department", CurrentRow.Departments);
	EndIf;
	If CurrentRow.Companies.Count() > 0 Then
		ReportParameters.Insert("Organization", CurrentRow.Companies);
	EndIf;
	
	ReportPeriod = ?(ValueIsFilled(Object.Period), Object.Period, CurrentSessionDate());
	BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(ReportPeriod, Periodicity);
	EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(ReportPeriod, Periodicity);

	ReportParameters.Insert("BeginOfPeriod", BeginOfPeriod);
	ReportParameters.Insert("EndOfPeriod", EndOfPeriod);
	
	If ValueIsFilled(ReportParameters.Scenario) Then
		ReportParameters.Insert("ReportCurrency", Common.ObjectAttributeValue(ReportParameters.Scenario,
			"Currency"));
	Else
		ReportParameters.Insert("ReportCurrency", Constants.ManagementAccountingCurrency.Get());
	EndIf;
	
	ReportParameters.Insert("UpdateDate", EndOfDay(CurrentSessionDate()));

	If TypeOf(CurrentRow.BudgetProfile) <> Type("CatalogRef.BudgetProfiles") Then
		Return ReportParameters;
	EndIf;
	
	ActualDataLimit = Catalogs.BudgetProfiles.BorderOfActualDataByBudgetType(ReportParameters.BudgetProfile,
		ReportParameters.BeginOfPeriod);
	ReportParameters.Insert("ActualDataLimit", ActualDataLimit);
	
	DataStatuses = New ValueList;
	DataStatuses.Add(Enums.PlanStatuses.Upholded);
	If GetFunctionalOption("UseBudgetConfirmation", 
			New Structure("BudgetingModel", ReportParameters.BudgetingModel)) Then
		If CurrentRow.DataUnderDevelopment Then 
			DataStatuses.Add(Enums.PlanStatuses.UnderPreparation);
		EndIf;
		If CurrentRow.DataForConfirmation Then 
			DataStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
		EndIf;
	Else
		DataStatuses.Add(Enums.PlanStatuses.AwaitingConfirmation);
		DataStatuses.Add(Enums.PlanStatuses.UnderPreparation);
	EndIf;
	ReportParameters.Insert("Status", DataStatuses);
	ReportParameters.Insert("GenerationMode", Enums.ModesOfBudgetReportGeneration.Report);
	
	AdditionalFiltersForAnalytics = New Structure;
	HeaderAnalystTable = Common.ObjectAttributeValue(ReportParameters.BudgetProfile,
		"HeaderDimensions.DimensionKind");
	For Each DimensionKind In HeaderAnalystTable.Unload().UnloadColumn("DimensionKind") Do
		FieldName = FinancialReportingCached.NameOfBudgetReportField(DimensionKind);
		AdditionalFiltersForAnalytics.Insert(FieldName);
	EndDo;
	
	ReportParameters.Insert("AdditionalFiltersForAnalytics", AdditionalFiltersForAnalytics);
	ReportParameters.Insert("ShowItemHierarchy", True);
	ReportParameters.Insert("ConsiderAdditionalSelectionByHierarchy", False);
	ReportParameters.Insert("QueryTextDocumentTables", "");
	
	Return ReportParameters;
	
EndFunction

&AtServer
Function GenerateControlReportServer(ReportParameters)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	JobID = Undefined;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription =
		TMReportFunctionsClientServer.GetNameOfReportExecutionTask(ThisObject);
	
	If TypeOf(ReportParameters.BudgetProfile) = Type("CatalogRef.BudgetProfiles") Then
		ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
			"BudgetReportingDisplayServer.PutDataForBudgetReportInStorage", ReportParameters, ExecutionParameters);
	Else
		ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
			"BudgetReportingDisplayServer.PutBudgetTurnoverDataInVault", ReportParameters, ExecutionParameters);
	EndIf;
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure Attachable_CheckCompletionOfDocumentCreationTask()
	
	Try
		CheckResult = CheckingCompletionOfDocumentCreationTask(Object.Ref);
		If CheckResult.Completed2 Then
			ProcessingFormClosureAndDocumentCreation(New Structure("CloseTheTask", False), Undefined);
			TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
			
		Else
			If PreviousVersionOfTaskData <> Undefined
			   And PreviousVersionOfTaskData <> CheckResult.CurVersionOfData Then
				Read();
				ExpandDocumentTree();
			EndIf;
			PreviousVersionOfTaskData = CheckResult.CurVersionOfData;
			
			TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
			AttachIdleHandler(
				"Attachable_CheckCompletionOfDocumentCreationTask",
				IdleHandlerParameters.CurrentInterval,
			True);
		EndIf;
	Except
		CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Budget , "DontUse");
		Raise ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;

EndProcedure
&AtServer
Procedure ActionsAfterBudgeting(StorageAddressBudgetGeneration)
	
	ExecutionResult = GetFromTempStorage(StorageAddressBudgetGeneration);
	If ExecutionResult.HasErrors Then
		Common.MessageToUser(ExecutionResult.ErrorText);
	Else
		Object.DocumentsList.Clear();
		CommonClientServer.SupplementTableFromArray(Object.DocumentsList,
			ExecutionResult.Documents, "Document");
		
		Write();
	EndIf;
	UpdateDocumentTree(GetActionSettingsFromTemporaryStorage());
	Items.Pages.CurrentPage = Items.ResultPage;
		
EndProcedure

&AtClient
Procedure ExpandDocumentTree()
	
	TreeItems = DocumentTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.DocumentTree.Expand(TreeItem.GetID());
		SubordinateElements_ = TreeItem.GetItems();
		For Each SubordinateElement In SubordinateElements_ Do
			Items.DocumentTree.Expand(SubordinateElement.GetID());
		EndDo;
	EndDo;

EndProcedure

&AtServer
Procedure LoadPreparedData(Val StorageAddress)
	
	ExecutionResult = GetFromTempStorage(StorageAddress);
	
	If TypeOf(ExecutionResult) = Type("Structure") Then
		
		MonitoringReport    = ExecutionResult.Result;
		CellData_         = ExecutionResult.CellData_;
		DetailsData   = ExecutionResult.DetailsData;
		
	Else
		
		MonitoringReport = ExecutionResult;
		
	EndIf;
	
	AddressOfCellData = PutToTempStorage(CellData_, UUID);
	DetailsDataAddress = PutToTempStorage(DetailsData, UUID);
	
	JobID = Undefined;
	
	CommonClientServer.SetSpreadsheetDocumentFieldState(Items.Budget, "DontUse");
	
EndProcedure

&AtServer
Procedure MultipleInstances(Val ActionSettingsTable)
	
	ListVisibility = Tasks.BudgetTask.BudgetTaskList(Object, ActionSettingsTable);
	
EndProcedure

#Region ProcessingDecryptionOfControlReport

&AtClient
Procedure BudgetDetailProcessing(Item, IndexDecryption, StandardProcessing)
	
	StandardProcessing = False;
	
	Details = BudgetReportingServerCall.DetailsValue(IndexDecryption, DetailsDataAddress);
	
	If TypeOf(Details) = Type("Structure") Then
		If Details.Property("DataLineIndex")
		   And Details.DataLineIndex <> Undefined Then
			
			OpeningParameters = ParametersForOpeningDecryptionReport(Details);
			
			If OpeningParameters.ReportParameters.Property("FixedSettings") Then
				Recorder = GetUnambiguousLoggerBySettings(
					OpeningParameters.ReportParameters.FixedSettings,
					Details);
			EndIf;
			
			If Recorder = Undefined Then
				BudgetReportingClient.OpenReportForm(OpeningParameters, ThisObject);
			Else
				ShowValue(,Recorder);
			EndIf;
			
		ElsIf Details.Property("Value")
		        And Details.Value <> Undefined Then
			
			ShowValue(Undefined, Details.Value);
			
		Else
			
			ShowMessageBox(, NStr("vi = 'Không có dữ liệu để giải mã';
									|ru = 'Нет данных для расшифровки';
									|en = 'No data to drill down'; fa = 'No data to drill down';
									|it = 'Non ci sono dati per la decodifica';
									|pl = 'Brak danych do odszyfrowania';
									|tr = 'Çözümleme için veri yok'"));
			
		EndIf;
	Else
		ShowMessageBox(, NStr("vi = 'Không có dữ liệu để giải mã';
								|ru = 'Нет данных для расшифровки';
								|en = 'No data to drill down'; fa = 'No data to drill down';
								|it = 'Non ci sono dati per la decodifica';
								|pl = 'Brak danych do odszyfrowania';
								|tr = 'Çözümleme için veri yok'"));
	EndIf;

EndProcedure

&AtServer
Function GetUnambiguousLoggerBySettings(Val FixedSettings,Details)
	
	Recorder = Undefined;
	
	CellData_ = GetFromTempStorage(AddressOfCellData);
	RelatedDataString = CellData_[Details.DataLineIndex];
	If RelatedDataString.MainItem Then
		TypeOfElementToDecrypt = RelatedDataString.ItemKind;
	Else
		TypeOfElementToDecrypt = RelatedDataString.OperandType;
	EndIf;
	
	If Not TypeOfElementToDecrypt = Enums.FinancialReportItemKinds.BudgetFlowItem Then
		 Return Undefined;
	EndIf;
	
	FixedSettings.Structure.Clear();
	FinancialReportingServer.NewGrouping(FixedSettings.Structure, "Recorder");
	
	DataCompositionSchema = Reports.BudgetingTurnoverBalanceReport.GetTemplate("TurnoversPlan");
	BudgetingServer.AddDCSAnalyticsByType(DataCompositionSchema, "BudgetFlowItem");

	TemplateComposer = New DataCompositionTemplateComposer();
	
	Template = TemplateComposer.Execute(DataCompositionSchema,
	                                    FixedSettings,,,
	                                    Type("DataCompositionValueCollectionTemplateGenerator"));
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(Template);
	
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Result = New ValueTable;
	OutputProcessor.SetObject(Result);
	OutputProcessor.Output(CompositionProcessor);
	
	If Result.Count() = 1 Then
		Recorder = Result[0].Recorder;
	EndIf;
	
	Return Recorder;
	
EndFunction

&AtServer
Function ParametersForOpeningDecryptionReport(Details)
	
	ReportParameters = PrepareReportParameters();
	Return BudgetReportingServerCall.ParametersForOpeningDecryptionReport(ReportParameters,
		Details,
		AddressOfCellData);
	
EndFunction

#EndRegion

&AtClient
Procedure ReplaceBudgetCompletion(Result, ElementIndex) Export
	
	If ValueIsFilled(Result) Then
		CurrentData = Items.DocumentTree.CurrentData;
		If CurrentData = Undefined Then
			CurrentData = DocumentTree.FindByID(ElementIndex);
		EndIf;
		
		If Not CurrentData = Undefined Then
			If ValueIsFilled(CurrentData.Document) Then
				FilterParameters = New Structure;
				FilterParameters.Insert("Document",CurrentData.Document);
				
				Rows = Object.DocumentsList.FindRows(FilterParameters);
				If Rows.Count() > 0 Then
					Object.DocumentsList.Delete(Object.DocumentsList.IndexOf(Rows[0]));
				EndIf;
			EndIf;
			CurrentData.Document = Result;
			CurrentData.DocumentPresentation = PresentationOfDocument(Result);
		EndIf;
				
		NewRow = Object.DocumentsList.Add();
		NewRow.Document = Result;
		
		Try
			Write();
		Except
			Modified = True;
			Raise NStr("vi = 'Không thể ghi lại nhiệm vụ.
				|Chứng từ theo nhiệm vụ có thể không hợp lệ để thay đổi';
				|ru = 'Не удалось записать задачу. 
				|Документы по задаче могут быть не доступны для изменения';
				|en = 'Cannot save the task. 
				|The task documents might be read-only'; fa = 'Cannot save the task. 
				|The task documents might be read-only';
				|it = 'Impossibile registrare l''obiettivo. 
				|I documenti relativi all''obiettivo potrebbero essere non disponibili alla modifica';
				|pl = 'Brak możliwości zapisu zadania. 
				|Dokumenty dla zadania mogą być nie dostępne dla zmiany';
				|tr = 'Görev kaydedilemiyor.
				| Göreve göre belgeler değişikler için kullanılamayabilir'");
		EndTry;
		
		If Not ListVisibility Then
			Items.ToPerformTheInputActionBudgets.Title = 
				?(ValueIsFilled(Result), String(Result), NStr("vi = '<Nhập ngân sách>';
																|ru = '<Ввести бюджет>';
																|en = '<Enter budget>'; fa = '<Enter budget>';
																|it = '<Inserire il budget>';
																|pl = '<Wprowadź budżet>';
																|tr = '<Bütçeyi gir>'"));
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PresentationOfDocument(DocumentRef)
	
	DocumentAttributes = Common.ObjectAttributesValues(DocumentRef, "Number, Date");
	Return DocumentAttributes.Number + " " + DocumentAttributes.Date;
	
EndFunction

&AtClient
Procedure GenerateAutomaticallyCompletion(QuestionResult, Var_Parameters=Undefined) Export
	
	DonTCheckExistingDocuments = False;
	If QuestionResult = DialogReturnCode.Yes Then
		DonTCheckExistingDocuments = True;
	EndIf;
	
	Items.Pages.CurrentPage = Items.PageLongActions;
	
	ExecutionResult = GenerateAllBudgetsByActionSettings(DonTCheckExistingDocuments);

	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputProgressBar = True;
	IdleParameters.ExecutionProgressNotification =
		New CallbackDescription("GenerateAutomaticallyOutputProgress", ThisObject);
	
	CallbackOnCompletion = New CallbackDescription("GenerateAutomaticNotification", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(
		ExecutionResult, CallbackOnCompletion, IdleParameters);
	
	Try
		Write();
	Except
		Modified = True;
		Raise NStr("vi = 'Không thể ghi lại nhiệm vụ.
			|Chứng từ theo nhiệm vụ có thể không hợp lệ để thay đổi';
			|ru = 'Не удалось записать задачу. 
			|Документы по задаче могут быть не доступны для изменения';
			|en = 'Cannot save the task. 
			|The task documents might be read-only'; fa = 'Cannot save the task. 
			|The task documents might be read-only';
			|it = 'Impossibile registrare l''obiettivo. 
			|I documenti relativi all''obiettivo potrebbero essere non disponibili alla modifica';
			|pl = 'Brak możliwości zapisu zadania. 
			|Dokumenty dla zadania mogą być nie dostępne dla zmiany';
			|tr = 'Görev kaydedilemiyor.
			| Göreve göre belgeler değişikler için kullanılamayabilir'");
	EndTry;
	
EndProcedure

&AtClient
Procedure GenerateAutomaticNotification(Result, AditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	Try
		ActionsAfterBudgeting(Result.ResultAddress);
		ExpandDocumentTree();
	Except
		Items.Pages.CurrentPage = Items.ResultPage;
		Raise ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
EndProcedure

&AtClient
Procedure GenerateAutomaticallyOutputProgress(Result, AditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	BackgroundJobPercentage = Result.Progress;
	
EndProcedure

&AtServerNoContext
Function FindSuitableBudgetsForDocumentTree(BudgetingModel, Val DocumentTree, Action)
	
	ThisIsInputOfBudgetTurnoverAccordingToCalculationRules = (Action
		= Enums.TypesOfBudgetingStepActions.FormationOfBudgetTurnoverAccordingToCalculationRules);
	ThisIsInputOfBalancesOfCalculatedIndicators = (Action
		= Enums.TypesOfBudgetingStepActions.SettingOfEstimatesOpeningBalance);
	
	BudgetPopulationDimension = New ValueTable;
	BudgetPopulationDimension.Columns.Add("TreeID",New TypeDescription("Number"));
	BudgetPopulationDimension.Columns.Add("BeginOfPeriod",New TypeDescription("Date"));
	BudgetPopulationDimension.Columns.Add("EndOfPeriod",New TypeDescription("Date"));
	BudgetPopulationDimension.Columns.Add("CalculationRule",New TypeDescription(
		"CatalogRef.RuleForCalculatingRelatedBudgetBalancesAndTurnovers"));
	BudgetPopulationDimension.Columns.Add("Periodicity",New TypeDescription(
		"EnumRef.Periodicity"));
	BudgetPopulationDimension.Columns.Add("BudgetProfile",New TypeDescription("CatalogRef.BudgetProfiles"));
	BudgetPopulationDimension.Columns.Add("BudgetBalanceItem",
		New TypeDescription("CatalogRef.BudgetBalanceItems"));
	BudgetPopulationDimension.Columns.Add("Scenario",New TypeDescription("CatalogRef.BudgetingScenarios"));
	BudgetPopulationDimension.Columns.Add("Organization",New TypeDescription("CatalogRef.Companies"));
	BudgetPopulationDimension.Columns.Add("Department",New TypeDescription("CatalogRef.BusinessStructure"));
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	For Cnt = 1 To MaximumNumberOfAnalysts Do
		AnalystType = Metadata.Documents.BudgetEntryForm.Attributes.Dimension1.Type;
		BudgetPopulationDimension.Columns.Add("Dimension"+Cnt, AnalystType);
	EndDo;
	
	CreateCommand = NStr("vi = 'Tạo mới';
						|ru = 'Создать';
						|en = 'Create'; fa = 'ایجاد';
						|it = 'Creare';
						|pl = 'Utwórz';
						|tr = 'Oluştur'");
	
	For Each BudgetLine In DocumentTree.GetItems() Do
		If BudgetLine.DocumentPresentation = CreateCommand Then
			Nw = BudgetPopulationDimension.Add();
			FillPropertyValues(Nw,BudgetLine);
			Nw.TreeID = BudgetLine.GetID();
		EndIf;
		For Each StringPeriod In BudgetLine.GetItems() Do
			If StringPeriod.DocumentPresentation = CreateCommand Then
				Nw = BudgetPopulationDimension.Add();
				FillPropertyValues(Nw,StringPeriod);
				Nw.TreeID = StringPeriod.GetID();
			EndIf;
			For Each AnalyticsLine In StringPeriod.GetItems() Do
				If AnalyticsLine.DocumentPresentation = CreateCommand Then
					Nw = BudgetPopulationDimension.Add();
					FillPropertyValues(Nw,AnalyticsLine);
					Nw.TreeID = AnalyticsLine.GetID();
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Query = New Query;
	Text = 
	"SELECT
	|	BudgetPopulationDimension.Organization AS Organization,
	|	BudgetPopulationDimension.Department AS Department,
	|	BudgetPopulationDimension.Scenario AS Scenario,
	|	BudgetPopulationDimension.BeginOfPeriod AS BeginOfPeriod,
	|	BudgetPopulationDimension.EndOfPeriod AS EndOfPeriod,
	|	BudgetPopulationDimension.BudgetProfile AS BudgetProfile,
	|	BudgetPopulationDimension.CalculationRule AS CalculationRule,
	|	BudgetPopulationDimension.Periodicity AS Periodicity,
	|	BudgetPopulationDimension.BudgetBalanceItem AS BudgetBalanceItem,
	|	&TextOfBudgetAnalyticsampleOfAnalysts
	|INTO DimensionOfBudgets
	|FROM
	|	&AnalysisOfFillingBudgets AS BudgetPopulationDimension
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DimensionOfBudgets.Organization AS Organization,
	|	DimensionOfBudgets.Department AS Department,
	|	DimensionOfBudgets.Scenario AS Scenario,
	|	DimensionOfBudgets.BeginOfPeriod AS BeginOfPeriod,
	|	DimensionOfBudgets.EndOfPeriod AS EndOfPeriod,
	|	DimensionOfBudgets.BudgetBalanceItem AS BudgetBalanceItem,
	|	DimensionOfBudgets.BudgetProfile AS BudgetProfile,
	|	DimensionOfBudgets.CalculationRule AS CalculationRule,
	|	DimensionOfBudgets.Periodicity AS Periodicity,
	|	&TextSampleAnalytics,
	|	MAX(BudgetEntryForm.Ref) AS Document
	|FROM
	|	DimensionOfBudgets AS DimensionOfBudgets
	|		LEFT JOIN Document.BudgetEntryForm AS BudgetEntryForm
	|		ON &TextConnectingParameters
	|		AND &TextAnalyst_4
	|		AND &ConditionBasedOnBudgetingModel
	|		AND (NOT BudgetEntryForm.DeletionMark)
	|GROUP BY
	|	DimensionOfBudgets.Organization,
	|	DimensionOfBudgets.BeginOfPeriod,
	|	DimensionOfBudgets.Department,
	|	DimensionOfBudgets.BudgetProfile,
	|	DimensionOfBudgets.EndOfPeriod,
	|	DimensionOfBudgets.Scenario,
	|	DimensionOfBudgets.CalculationRule,
	|	DimensionOfBudgets.Periodicity,
	|	DimensionOfBudgets.BudgetBalanceItem,
	|	&TextGroupingAnalytics";
	
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Then
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"Organization,Department,Scenario,BeginOfPeriod,Periodicity,CalculationRule");
		NameOfStartOfPeriodParameter = "PlanningPeriod";
		Text = StrReplace(Text, "Document.BudgetEntryForm", "Document.RegistrarOfBudgetTurnover");
		Text = StrReplace(Text, "&ConditionBasedOnBudgetingModel", "TRUE");
	ElsIf ThisIsInputOfBalancesOfCalculatedIndicators Then
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"BudgetBalanceItem,Scenario,BeginOfPeriod");
		NameOfStartOfPeriodParameter = "DateOfRemainingGoods";
		Text = StrReplace(Text, "Document.BudgetEntryForm", "Document.SettingOfEstimatesOpeningBalance");
		Text = StrReplace(Text, "&ConditionBasedOnBudgetingModel", "TRUE");
	Else
		ArrayOfParametersNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			"Organization,Department,Scenario,BeginOfPeriod,EndOfPeriod,BudgetProfile");
		NameOfStartOfPeriodParameter = "BeginOfPeriod";
		Text = StrReplace(Text, "&ConditionBasedOnBudgetingModel",
			"(BudgetEntryForm.BudgetingModel = &BudgetingModel)");
	EndIf;
	
	ConnectionConditionTemplate = "DimensionOfBudgets.%1 = BudgetEntryForm.%2";
	ArrayOfConnectionConditions = New Array;
	For Each ParameterName In ArrayOfParametersNames Do
		If ParameterName = "BeginOfPeriod" Then
			ConnectionConditionText = StringFunctionsClientServer.SubstituteParametersToString(ConnectionConditionTemplate,
				ParameterName, NameOfStartOfPeriodParameter);
		ElsIf ParameterName = "EndOfPeriod" Then
			ConnectionConditionText = StringFunctionsClientServer.SubstituteParametersToString(ConnectionConditionTemplate,
				ParameterName, "PeriodEnding");
		Else
			ConnectionConditionText = StringFunctionsClientServer.SubstituteParametersToString(ConnectionConditionTemplate,
				ParameterName, ParameterName);
		EndIf;
		ArrayOfConnectionConditions.Add(ConnectionConditionText);
	EndDo;
	Text = StrReplace(Text, "&TextConnectingParameters", StrConcat(ArrayOfConnectionConditions, Chars.LF + Chars.Tab
		+ Chars.Tab + "And "));
	
	TextOfBudgetAnalyticsampleOfAnalysts = "";
	TextSampleAnalytics = "";
	TextAnalyst_4 = "";
	TextGroupingAnalytics = "";
	For DimensionNumber = 1 To MaximumNumberOfAnalysts Do
		TextOfBudgetAnalyticsampleOfAnalysts = TextOfBudgetAnalyticsampleOfAnalysts
			+ ?(TextOfBudgetAnalyticsampleOfAnalysts = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"BudgetPopulationDimension.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextSampleAnalytics = TextSampleAnalytics
			+ ?(TextSampleAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionOfBudgets.Dimension%1 AS Dimension%1",
				DimensionNumber);
		
		TextAnalyst_4 = TextAnalyst_4
			+ ?(TextAnalyst_4 = "", "", Chars.LF + Chars.Tab + Chars.Tab + "And ")
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionOfBudgets.Dimension%1 = BudgetEntryForm.Dimension%1",
				DimensionNumber);
		
		TextGroupingAnalytics = TextGroupingAnalytics
			+ ?(TextGroupingAnalytics = "", "", "," + Chars.LF + Chars.Tab)
			+ StringFunctionsClientServer.SubstituteParametersToString(
				"DimensionOfBudgets.Dimension%1",
				DimensionNumber);
	EndDo;
	Text = StrReplace(Text, "&TextOfBudgetAnalyticsampleOfAnalysts", TextOfBudgetAnalyticsampleOfAnalysts);
	Text = StrReplace(Text, "&TextSampleAnalytics", TextSampleAnalytics);
	If ThisIsInputOfBudgetTurnoverAccordingToCalculationRules Or ThisIsInputOfBalancesOfCalculatedIndicators Then
		Text = StrReplace(Text, "&TextAnalyst_4", "TRUE");
	Else
		Text = StrReplace(Text, "&TextAnalyst_4", TextAnalyst_4);
	EndIf;
	Text = StrReplace(Text, "&TextGroupingAnalytics", TextGroupingAnalytics);
	
	Query.Text = Text;
	
	Query.SetParameter("BudgetingModel", BudgetingModel);
	Query.SetParameter("AnalysisOfFillingBudgets",BudgetPopulationDimension);
	
	Result = Query.Execute().Unload();
	
	DocumentsArray = New Array();
	For Each Page1 In Result Do
		If ValueIsFilled(Page1.Document) Then
			DocumentsArray.Add(Page1.Document);
		EndIf;
	EndDo;
	
	StructureSuitableDocuments = New Structure();
	StructureSuitableDocuments.Insert("DocumentsArray",DocumentsArray);
	StructureSuitableDocuments.Insert("NumberOfDocumentsToCreate",BudgetPopulationDimension.Count());
	
	Return StructureSuitableDocuments;
	
EndFunction

&AtServerNoContext
Function NameOfBudgetDocumentForIssue(Action)
	
	Return Tasks.BudgetTask.NameOfBudgetDocumentForIssue(Action);
	
EndFunction

&AtClient
Procedure AddBudgetCompletion(Result, DocumentRef) Export
	
	UpdateDocumentTree(AddressActionSetting,False);
	
	TreeItems = DocumentTree.GetItems();
	For Each TreeItem In TreeItems Do
		Items.DocumentTree.Expand(TreeItem.GetID(),True);
	EndDo;
	
	FoundRow = FindRowInDocumentTree(DocumentRef);
	If FoundRow <> Undefined Then
		Items.DocumentTree.CurrentRow = FoundRow.GetID();
	EndIf;
	
EndProcedure

&AtClient
Function FindRowInDocumentTree(DocumentRef)
	
	SearchString = Undefined;
	
	For Each BudgetViewLine_ In DocumentTree.GetItems() Do
		If BudgetViewLine_.Document = DocumentRef Then
			SearchString = BudgetViewLine_;
			Break;
		EndIf;
		For Each StringPeriod In BudgetViewLine_.GetItems() Do
			If StringPeriod.Document = DocumentRef Then
				SearchString = StringPeriod;
				Break;
			EndIf;
			For Each AnalyticsLine In StringPeriod.GetItems() Do
				If AnalyticsLine.Document = DocumentRef Then
					SearchString = AnalyticsLine;
					Break;
				EndIf;
			EndDo;
		EndDo;
	EndDo;
	
	Return SearchString;

EndFunction

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Period" Then
		ThePeriodOfTheTaskWhenItIsChanged(Items.Period1);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
