#Region Variables

&AtClient
Var CloseFlag;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Object.Ref.IsEmpty() Then
		Object.Status = Enums.StatusesOfBudgetingProcess.NotStarted;
		Object.EmployeeResponsible = Users.AuthorizedUser();
		If Parameters.Property("Basis") And ValueIsFilled(Parameters.Basis) Then
			Object.StepGroup = Parameters.Basis;
			Object.BudgetingModel = Common.ObjectAttributeValue(Parameters.Basis, "Owner");
			Error = ErrorInSelectedBudgetingModel(Object.BudgetingModel, Object.EndOfPeriod);
			If Not IsBlankString(Error) Then
				Raise(Error);
			EndIf;
			GroupOfStepsWhenChangingOnServer();
		EndIf;
	EndIf;
	
	SetFormHeader();
	FillInStepTree();
	DisplayPeriod_();
	UpdateServerStatuses();
	FormControl();
	
	AddressOfSettingTransfer = PutToTempStorage(Undefined, UUID);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If Not CloseFlag = True
		And Object.Status <> PredefinedValue("Enum.StatusesOfBudgetingProcess.Completed")
		And Object.Status <> PredefinedValue("Enum.StatusesOfBudgetingProcess.RolledBack_") Then
		If AllTasksCompleted_() Then
			ShowQueryBox(New CallbackDescription("BeforeWriteCompletion", ThisForm, New Structure("CloseForm", WriteParameters.ForceCloseTheForm)), NStr(
				"vi = 'Tất cả nhiệm vụ đã thực hiện. Kết thúc quy trình?';
				|ru = 'Все задачи выполнены. Завершить процесс?';
				|en = 'All tasks are completed. End the process?'; fa = 'All tasks are completed. End the process?';
				|it = 'Tutti i task sono eseguiti. Completare il processo?';
				|pl = 'Wszystkie zadania są zakończone. Zakończyć proces?';
				|tr = 'Tüm görevler tamamlandı. Süreç sonlandırılsın mı?'"), QuestionDialogMode.YesNo);
			Cancel = True;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	UpdateServerStatuses();
	FormControl();
	
	Id = FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 1));
	If Id <> Undefined Then
		Items.BudgetProcessStepTree.CurrentRow = Id;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	Var Errors;
	
	If Object.Status = Enums.StatusesOfBudgetingProcess.NotStarted Then
		Error = ErrorInSelectedBudgetingModel(Object.BudgetingModel, Object.EndOfPeriod);
		If Not IsBlankString(Error) Then
			Common.MessageToUser(Error, , , , Cancel);
		EndIf;
		Return;
	EndIf;
	
	ValidationTree = FormAttributeToValue("BudgetProcessStepTree");
	TheStructureOfTheSearch = New Structure("IsFolder, ExecuteAutomatically", False, False);
	
	StructureOfBlankSearch = CommonClientServer.CopyStructure(TheStructureOfTheSearch);
	StructureOfBlankSearch.Insert("EmployeeResponsible", Catalogs.Users.EmptyRef());
	FoundRows = ValidationTree.Rows.FindRows(StructureOfBlankSearch, True);
	For Each FoundRow In FoundRows Do
		MessageText_1 = NStr("vi = 'Không điền vào người chịu trách nhiệm cho giai đoạn %1 từ %2';
							|ru = 'Не заполнен ответственный для этапа %1 от %2';
							|en = 'Person responsible for step %1 from %2 is not filled in'; fa = 'Person responsible for step %1 from %2 is not filled in';
							|it = 'Non è compilata la persona responsabile per la fase %1 del %2';
							|pl = 'Nie wprowadzono odpowiedzialnego dla etapu %1 z dnia %2';
							|tr = 'Sorumlu doldurulmadı etap %1 için %2 itibarıyla'");
		MessageText_1 = StringFunctionsClientServer.SubstituteParametersToString(MessageText_1, 
								FoundRow.Description, Format(FoundRow.Period, "DLF=D"));
		CommonClientServer.AddUserError(Errors, "BudgetProcessStepTree", MessageText_1, "");
	EndDo;
	
	StructureOfBlankSearch = CommonClientServer.CopyStructure(TheStructureOfTheSearch);
	StructureOfBlankSearch.Insert("Duration", 0);
	FoundRows = ValidationTree.Rows.FindRows(StructureOfBlankSearch, True);
	For Each FoundRow In FoundRows Do
		MessageText_1 = NStr("vi = 'Thời lượng không được điền cho kỳ %1 từ %2';
							|ru = 'Не заполнена длительность для этапа %1 от %2';
							|en = 'Duration is required for step %1 dated %2'; fa = 'Duration is required for step %1 dated %2';
							|it = 'Non è compilata la durata della fase %1 del %2';
							|pl = 'Nie wprowadzono сzasu trwania dla etapu %1 z dnia %2';
							|tr = 'Süre doldurulmadı etap %1 için %2 itibarıyla'");
		MessageText_1 = StringFunctionsClientServer.SubstituteParametersToString(MessageText_1, 
								FoundRow.Description, Format(FoundRow.Period, "DLF=D"));
		CommonClientServer.AddUserError(Errors, "BudgetProcessStepTree", MessageText_1, "");
	EndDo;
	
	StructureOfBlankSearch = CommonClientServer.CopyStructure(TheStructureOfTheSearch);
	StructureOfBlankSearch.Insert("DurationType", Enums.TypesOfBudgetingStepDurations.EmptyRef());
	FoundRows = ValidationTree.Rows.FindRows(StructureOfBlankSearch, True);
	For Each FoundRow In FoundRows Do
		MessageText_1 = NStr("vi = 'Chưa điền kiểu thời lượng cho kỳ %1 từ %2';
							|ru = 'Не заполнен тип длительности для этапа %1 от %2';
							|en = 'Duration type is required for step %1 dated %2'; fa = 'Duration type is required for step %1 dated %2';
							|it = 'Non è compilato il tipo della durata per la fase %1 del %2';
							|pl = 'Nie wprowadzono typu czasu trwania dla etapu %1 z dnia %2';
							|tr = 'Süre tipi doldurulmadı etap %1 için %2 itibarıyla'");
		MessageText_1 = StringFunctionsClientServer.SubstituteParametersToString(MessageText_1, 
								FoundRow.Description, Format(FoundRow.Period, "DLF=D"));
		CommonClientServer.AddUserError(Errors, "BudgetProcessStepTree", MessageText_1, "");
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("UpdateTaskStatuses", 15);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.Status = Enums.StatusesOfBudgetingProcess.RolledBack_ Then
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	BudgetTask.Ref
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingProcess = &BudgetingProcess
		|	AND NOT BudgetTask.Executed";
		
		Query.SetParameter("BudgetingProcess", CurrentObject.Ref);
		
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			TaskObject_ = SelectionDetailRecords.Ref.GetObject();
			TaskObject_.Executed = True;
			TaskObject_.AdditionalProperties.Insert("TaskGenerationMode", True);
			TaskObject_.Write();
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(NameOfAlertEvent, Parameter, Source)
		
	If NameOfAlertEvent = "Write_BudgetTask" Then
		
		IDOfNextLine = ProcessingTaskNotificationOnServer();
		If IDOfNextLine <> Undefined Then
			Items.BudgetProcessStepTree.CurrentRow = IDOfNextLine;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeWriteCompletion(Result, AdditionalParameters) Export
	
	CloseFlag = True;
	
	If Result = DialogReturnCode.Yes Then
		Object.Status = PredefinedValue("Enum.StatusesOfBudgetingProcess.Completed");
	EndIf;
	
	Write();
	If AdditionalParameters.Property("CloseForm")
		And AdditionalParameters.CloseForm = True Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetingModelChoiceProcessing(Item, ValueSelected, StandardProcessing)
	Error = ErrorInSelectedBudgetingModel(ValueSelected, Object.EndOfPeriod);
	If Not IsBlankString(Error) Then
		StandardProcessing = False;
		ShowMessageBox(, Error);
	EndIf;
EndProcedure

&AtClient
Procedure StepGroupOnChange(Item)
	
	If ValueIsFilled(Object.StepGroup) Then
		GroupOfStepsWhenChangingOnServer();
		ExpandStepTree();
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("PeriodStartChoiceCompletion", ThisObject);
	
	PeriodType = DefineTypeOfPeriod(Object.Periodicity);
	TMCommonUseClient.SelectPeriodFromList(
				ThisForm,
				Item,
				PeriodType,
				Object.BeginOfPeriod,
				CallbackDescription);

EndProcedure

&AtClient
Procedure PeriodicityOnChange(Item)
	
	EnterPeriodValue();
	ExpandStepTree();
	
EndProcedure

&AtClient
Procedure AdditionToDescriptionStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.AdditionToDescription");
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region TableEventHandlersForms

&AtClient
Procedure BudgetProcessStepTreeNotRunningOnChange(Item)
	
	CurrentRow = Items.BudgetProcessStepTree.CurrentData;
	CurrentRow.StatusIndex_3 = ?(CurrentRow.NotRunning, -1, 0);
	
	SetValueOfTablePart("NotRunning");
	
EndProcedure

&AtClient
Procedure BudgetProcessStepTreeEmployeeResponsibleOnChange(Item)
	
	SetValueOfTablePart("EmployeeResponsible");
	
EndProcedure

&AtClient
Procedure BudgetProcessStepTreeDurationOnChange(Item)
	
	SetValueOfTablePart("Duration");
	
EndProcedure

&AtClient
Procedure BudgetProcessStepTreeDurationTypeOnChange(Item)
	
	SetValueOfTablePart("DurationType");
	
EndProcedure

&AtClient
Procedure BudgetProcessStepTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurFieldElement = Items.BudgetProcessStepTree.CurrentItem;
	If CurFieldElement.ReadOnly Then
		OpenTask();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers
// End MenuReports


&AtClient
Procedure UpdateStatuses(Command)
	
	UpdateServerStatuses();
	
EndProcedure

&AtClient
Procedure ExecuteTask(Command)
	
	UpdateServerStatuses();
	CurrentData = Items.BudgetProcessStepTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	If CurrentData.IsFolder Then
		ShowMessageBox(, NStr("vi = 'Đặt con trỏ trên bước chuẩn bị ngân sách để tạo một nhiệm vụ';
								|ru = 'Установите курсор на этап подготовки бюджетов для создания задачи';
								|en = 'Select a budgeting step to create the task'; fa = 'Select a budgeting step to create the task';
								|it = 'Posizionarsi col cursore sulla fase di preparazione dei budget per creare il task';
								|pl = 'Ustaw kursor na etapie przygotowania budżetu, aby utworzyć zadanie.';
								|tr = 'İmleci görev oluşturma işlemi için bütçe hazırlama aşamalarına ayarlayınız'"));
	ElsIf CurrentData.StatusIndex_3 = 0 Then
		ShowMessageBox(, NStr("vi = 'Nhiệm vụ chưa bắt đầu';
								|ru = 'Задача еще не началась';
								|en = 'Task is not started yet'; fa = 'Task is not started yet';
								|it = 'Il task non è ancora cominciato';
								|pl = 'Zadanie jeszcze nie rozpoczęte';
								|tr = 'Görev daha başlamadı'"));
	ElsIf CurrentData.StatusIndex_3 = 2 Then
		ShowMessageBox(, NStr("vi = 'Nhiệm vụ đã hoàn thành';
								|ru = 'Задача уже выполнена';
								|en = 'Task is already completed'; fa = 'Task is already completed';
								|it = 'Il task è già completato';
								|pl = 'Zadanie już zostało wykonane';
								|tr = 'Görev artık tamamlandı'"));
	Else
		CurTaskParameters = CurTaskParameters(
										Object.Ref, CurrentData.BudgetingStep, 
										CurrentData.BudgetingStepBasis, CurrentData.Period,
										AddressOfSettingTransfer);
		If CurTaskParameters = Undefined Then
			ShowMessageBox(, NStr("vi = 'Nhiệm vụ chưa được lập';
									|ru = 'Задача еще не сформирована';
									|en = 'Task is not generated yet'; fa = 'Task is not generated yet';
									|it = 'Il task non è ancora generato';
									|pl = 'Zadanie jeszcze nie wygenerowane';
									|tr = 'Görev daha oluşturulmadı'"));
			Return;
		EndIf;
		ExecuteActionClient(CurTaskParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisForm);
	
EndProcedure

&AtClient
Procedure Run(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	ProcessParameters = New Structure;
	ProcessParameters.Insert("BudgetingModel", Object.BudgetingModel);
	ProcessParameters.Insert("StepGroup", Object.StepGroup);
	ProcessParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	ProcessParameters.Insert("EndOfPeriod", Object.EndOfPeriod);
	ProcessParameters.Insert("Ref", Object.Ref);
	
	InformationAboutDoubles = PresenceOfRunningDuplicatesOfProcesses(ProcessParameters);
	If Not InformationAboutDoubles = Undefined Then
		CallbackDescription = New CallbackDescription("RunDuplicateProcess", ThisForm);
		
		WarningTexts = New Array;
		WarningTexts.Add(
			NStr("vi = 'Đối với mô hình hiện tại, nhóm các kỳ trong kỳ của quy trình ngân sách, đã có các đối tượng trùng lặp:';
				|ru = 'Для текущей модели, группы этапов в периоде действия бюджетного процесса уже есть дублирующиеся объекты:';
				|en = 'Duplicate objects already exist for the current model of stage group in budget process validity period:'; fa = 'Duplicate objects already exist for the current model of stage group in budget process validity period:';
				|it = 'Per il modello attuale, i gruppi delle fasi nel periodo di validità del processo di budget esistono già gli oggetti duplicati:';
				|pl = 'W bieżącego modelu, grupy etapów w okresie ważności procesu budżetowego, istnieją już zduplikowane obiekty:';
				|tr = 'Mevcut modeller için bütçe süreci eylem dönemindeki aşamalar grubunda halihazırda tekrarlanan iki nesne mevcut:'"));
		If InformationAboutDoubles.ThereAreDuplicates_ Then
			WarningTexts.Add(
				NStr("vi = 'Quy trình chuẩn bị ngân sách không đầy đủ';
					|ru = 'не завершенные документы ""Процесс подготовки бюджетов"".';
					|en = 'unfinished ""Budgeting process"" documents.'; fa = 'unfinished ""Budgeting process"" documents.';
					|it = 'i documenti ""Processo di preparazione dei budget"" non completati.';
					|pl = 'nie zakończone dokumenty ""Proces przygotowania budżetu""';
					|tr = '""Bütçeleme süreci"" bekleyen belgeleri.'"));
		EndIf;
		If InformationAboutDoubles.ThereAreDuplicatesOfTasks Then
			If WarningTexts.Count() > 1 Then
				WarningTexts[WarningTexts.Count()-1] =
					StrReplace(WarningTexts[WarningTexts.Count()-1], ".", "");
				WarningTexts.Add(NStr("vi = 'và';
										|ru = 'и';
										|en = 'and'; fa = 'و';
										|it = 'e';
										|pl = 'and';
										|tr = 've'"));
			EndIf;
			WarningTexts.Add(NStr("vi = 'chưa hoàn thành nhiệm vụ.';
									|ru = 'не выполненные задачи.';
									|en = 'not performed tasks.'; fa = 'not performed tasks.';
									|it = 'i task non completati.';
									|pl = 'nie wykonane zadania';
									|tr = 'tamamlanmayan görevler.'"));
		EndIf;
		WarningTexts.Add(NStr("vi = 'Chạy một quá trình trùng lặp?';
								|ru = 'Запустить дублирующий процесс?';
								|en = 'Run duplicating process?'; fa = 'Run duplicating process?';
								|it = 'Avviare il processo di duplicazione?';
								|pl = 'Uruchomić zduplikowany proces?';
								|tr = 'Tekrarlanan süreç başlatılsın mı?'"));
		QueryText = StrConcat(WarningTexts, " ");
		
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	Else
		StartingCompletionProcess();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function PresenceOfRunningDuplicatesOfProcesses(ProcessParameters)
	
	Response = Undefined;
	
	PeriodDates = New ValueTable;
	PeriodDates.Columns.Add("StartDate", New TypeDescription("Date",,,,,New DateQualifiers(DateFractions.DateTime)));
	
	Period = ProcessParameters.BeginOfPeriod;
	While Period <= ProcessParameters.EndOfPeriod Do
		DateString = PeriodDates.Add();
		DateString.StartDate = Period;
		
		Period = Period + 86400;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("StepGroup", ProcessParameters.StepGroup);
	Query.Text = "SELECT
	|	BudgetingSteps.Ref AS Ref,
	|	BudgetingSteps.Parent AS Parent1,
	|	BudgetingSteps.Parent.Parent AS Parent2,
	|	BudgetingSteps.Parent.Parent.Parent AS Parent3,
	|	BudgetingSteps.Parent.Parent.Parent.Parent AS Parent4,
	|	BudgetingSteps.Parent.Parent.Parent.Parent.Parent AS Parent5,
	|	BudgetingSteps.Parent.Parent.Parent.Parent.Parent.Parent AS Parent6,
	|	BudgetingSteps.Parent.Parent.Parent.Parent.Parent.Parent.Parent AS Parent7
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Ref = &StepGroup";
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	HigherLevelStageGroups = New Array;
	
	For NumberOfParentGroupInRequest = 1 To 7 Do
		ParentStageGroup = Selection["Parent" + Format(7-NumberOfParentGroupInRequest+1, "NZ=0; NG=0")];
		If ValueIsFilled(ParentStageGroup) Then
			HigherLevelStageGroups.Add(ParentStageGroup);
		EndIf;
	EndDo;
	
	ParentStageGroup = Selection.Parent7;
	While ValueIsFilled(ParentStageGroup) Do
		ParentStageGroup = Common.ObjectAttributeValue(ParentStageGroup, "Parent");
		
		If ValueIsFilled(ParentStageGroup) Then
			HigherLevelStageGroups.Add(ParentStageGroup);
		EndIf;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("StepGroup",            ProcessParameters.StepGroup);
	Query.SetParameter("HigherLevelStageGroups", HigherLevelStageGroups);
	Query.SetParameter("PeriodDates",             PeriodDates);
	Query.SetParameter("BudgetingModel",    ProcessParameters.BudgetingModel);
	Query.SetParameter("CurProcess",          ProcessParameters.Ref);
	Query.Text = "SELECT
	|	PeriodDates.StartDate AS StartDate
	|INTO PeriodDates
	|FROM
	|	&PeriodDates AS PeriodDates
	|
	|INDEX BY
	|	StartDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BudgetingSteps.Ref AS Ref
	|INTO IntersectingStages
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Ref IN HIERARCHY(&StepGroup)
	|
	|UNION ALL
	|
	|SELECT
	|	BudgetingSteps.Ref
	|FROM
	|	Catalog.BudgetingSteps AS BudgetingSteps
	|WHERE
	|	BudgetingSteps.Ref IN(&HigherLevelStageGroups)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	""Process_"" AS ObjectKind,
	|	TRUE AS ThereAreDuplicates
	|FROM
	|	PeriodDates AS PeriodDates
	|		INNER JOIN Document.BudgetingProcess AS BudgetingProcess
	|		ON (PeriodDates.StartDate BETWEEN BudgetingProcess.BeginOfPeriod AND BudgetingProcess.EndOfPeriod)
	|			AND (BudgetingProcess.BudgetingModel = &BudgetingModel)
	|			AND (NOT BudgetingProcess.DeletionMark)
	|			AND (BudgetingProcess.Status = VALUE(Enum.StatusesOfBudgetingProcess.Running))
	|			AND (NOT BudgetingProcess.Ref = &CurProcess)
	|		INNER JOIN IntersectingStages AS IntersectingStages
	|		ON (BudgetingProcess.StepGroup = IntersectingStages.Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Task"",
	|	TRUE
	|FROM
	|	PeriodDates AS PeriodDates
	|		INNER JOIN Task.BudgetTask AS BudgetTask
	|		ON PeriodDates.StartDate = BudgetTask.Period
	|			AND (NOT BudgetTask.DeletionMark)
	|			AND (NOT BudgetTask.Executed)
	|			AND (NOT BudgetTask.Inactive_)
	|			AND (NOT BudgetTask.BudgetingProcess = &CurProcess)
	|			AND (BudgetTask.BudgetingModel = &BudgetingModel)
	|		INNER JOIN IntersectingStages AS IntersectingStages
	|		ON (BudgetTask.BudgetingStep = IntersectingStages.Ref)";
	
	Result = Query.Execute();
	
	Response = Undefined;
	If Not Result.IsEmpty() Then
		Response = New Structure("ThereAreDuplicates_, ThereAreDuplicatesOfTasks", False, False);
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			If Selection.ObjectKind = "Process_" Then
				Response.Insert("ThereAreDuplicates_", Selection.ThereAreDuplicates);
			ElsIf Selection.ObjectKind = "Task" Then
				Response.Insert("ThereAreDuplicatesOfTasks", Selection.ThereAreDuplicates);
			EndIf;
		EndDo;
	EndIf;
	
	Return Response;
	
EndFunction

&AtClient
Procedure StartingCompletionProcess()
	Object.Status = PredefinedValue("Enum.StatusesOfBudgetingProcess.Running");
	Write();
EndProcedure

&AtClient
Procedure RunDuplicateProcess(Result, AdditionalParameters) Export
	If Result = DialogReturnCode.Yes Then
		StartingCompletionProcess();
	EndIf;
EndProcedure

&AtClient
Procedure Dismiss(Command)
	
	CallbackDescription = New CallbackDescription("DismissCompletion", ThisForm);
	ShowQueryBox(CallbackDescription, NStr("vi = 'Quá trình sẽ được chấm dứt. Tiếp tục?';
											|ru = 'Процесс будет прекращен. Продолжить?';
											|en = 'The process will be aborted. Continue?'; fa = 'The process will be aborted. Continue?';
											|it = 'Il processo verrà terminato. Continuare?';
											|pl = 'Proces zostanie zakończony. Kontynuować?';
											|tr = 'Süreç sonlandırılacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure DismissCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Object.Status = PredefinedValue("Enum.StatusesOfBudgetingProcess.RolledBack_");
	Write();
	
EndProcedure

&AtClient
Procedure OpenBudget(Command)
	
	CurrentData = Items.BudgetProcessStepTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurTaskParameters = CurTaskParameters(
										Object.Ref, CurrentData.BudgetingStep, 
										CurrentData.BudgetingStepBasis, CurrentData.Period,
										AddressOfSettingTransfer);
	
	If Not ValueIsFilled(CurTaskParameters) Then
		ShowMessageBox(,NStr("vi = 'Còn chưa tạo nhiệm vụ';
							|ru = 'Задача еще не создана';
							|en = 'Task is not created yet'; fa = 'Task is not created yet';
							|it = 'Il task non è ancora creato';
							|pl = 'Zadanie jeszcze nie zostało utworzone';
							|tr = 'Görev daha oluşturulmadı'"));
	ElsIf Not ValueIsFilled(CurTaskParameters.CurrentDocument) Then
		ShowMessageBox(,NStr("vi = 'Chưa tạo ngân sách trong phạm vi nhiệm vụ';
							|ru = 'Бюджет в рамках задачи не создавался';
							|en = 'Budget within the task was not created'; fa = 'Budget within the task was not created';
							|it = 'Nell''ambito del task il budget non veniva creato';
							|pl = 'Budżet nie został utworzony w ramach zadania';
							|tr = 'Bütçe görev dahilinde oluşturulmadı'"));
	Else
		ShowValue(,CurTaskParameters.CurrentDocument);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTask()
	
	CurrentData = Items.BudgetProcessStepTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurTaskParameters = CurTaskParameters(
										Object.Ref, CurrentData.BudgetingStep, 
										CurrentData.BudgetingStepBasis, CurrentData.Period,
										AddressOfSettingTransfer);
	
	If Not ValueIsFilled(CurTaskParameters) Then
		ShowMessageBox(,NStr("vi = 'Nhiệm vụ chưa được tạo';
							|ru = 'Задача еще не создана';
							|en = 'Task is not created yet'; fa = 'Task is not created yet';
							|it = 'Il task non è ancora creato';
							|pl = 'Zadanie jeszcze nie zostało utworzone';
							|tr = 'Görev daha oluşturulmadı'"));
	Else
		ShowValue(,CurTaskParameters.Task);
	EndIf;
	
EndProcedure

&AtClient
Procedure BackToTask(Command)
	
	If Object.Status <> PredefinedValue("Enum.StatusesOfBudgetingProcess.Running") Then
		ShowMessageBox(, StrTemplate(NStr("vi = 'Quy trình ngân sách đang ở trạng thái %1';
											|ru = 'Бюджетный процесс находится в статусе %1';
											|en = 'The budget process is in the %1 status'; fa = 'The budget process is in the %1 status';
											|it = 'Бюджетный процесс находится в статусе %1';
											|pl = 'The budget process is in the %1 status';
											|tr = 'Bütçe süreci %1 durumundadır'"), Object.Status));
		Return;
	EndIf;
	
	UpdateServerStatuses();
	CurrentData = Items.BudgetProcessStepTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	If CurrentData.IsFolder Then
		ShowMessageBox(, NStr("vi = 'Đặt con trỏ trên bước chuẩn bị ngân sách để quay lại thực hiện nhiệm vụ';
								|ru = 'Установите курсор на этап подготовки бюджетов для возврата к выполнению задачи';
								|en = 'Select a budgeting step to go back to the task'; fa = 'Select a budgeting step to go back to the task';
								|it = 'Установите курсор на этап подготовки бюджетов для возврата к выполнению задачи';
								|pl = 'Select a budgeting step to go back to the task';
								|tr = 'İmleci görev oluşturma işlemi için bütçe hazırlama aşamalarına ayarlayın'"));
	ElsIf CurrentData.StatusIndex_3 = 0 Then
		ShowMessageBox(, NStr("vi = 'Nhiệm vụ chưa bắt đầu';
								|ru = 'Задача еще не началась';
								|en = 'Task is not started yet'; fa = 'Task is not started yet';
								|it = 'Задача еще не началась';
								|pl = 'Zadanie jeszcze nie rozpoczęte';
								|tr = 'Görev daha başlamadı'"));
	Else
		Notification = New CallbackDescription("BackToTaskCompletion", ThisObject, New Structure("BudgetingStep", CurrentData.BudgetingStep));
		ShowQueryBox(Notification, NStr("vi = 'Nhiệm vụ hiện tại và tất cả các nhiệm vụ tiếp theo sẽ được đánh dấu là không hoạt động. Tiếp tục?';
										|ru = 'Текущая и все последующие задачи будут отмечены как неактивные. Продолжить?';
										|en = 'The current task and the following ones will be marked as inactive. Continue?'; fa = 'The current task and the following ones will be marked as inactive. Continue?';
										|it = 'Текущая и все последующие задачи будут отмечены как неактивные. Продолжить?';
										|pl = 'The current task and the following ones will be marked as inactive. Continue?';
										|tr = 'Mevcut ve sonraki bütün görevler devre dışı olarak işaretlenecektir. Devam edilsin mi?'"), QuestionDialogMode.YesNo);
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplacePerformer(Command)
	
	If Not ValueIsFilled(Object.Ref) Or Modified Then
		ShowMessageBox(, NStr("vi = 'Trước khi thực hiện giao dịch, cần ghi lại chứng từ';
								|ru = 'Перед выполнением операции необходимо записать документ';
								|en = 'Before performing the operation, save the document'; fa = 'Before performing the operation, save the document';
								|it = 'Перед выполнением операции необходимо записать документ';
								|pl = 'Before performing the operation, save the document';
								|tr = 'İşlem gerçekleştirilmeden önce belge kaydedilmelidir'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("ReplacePerformerCompletion", ThisObject);
	OpenForm("Document.BudgetingProcess.Form.ReplaceTaskAssignee", , ThisObject,
		UUID, , , CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ReplacePerformerCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	ReplaceTaskExecutor(Result.CurrentPerformer, Result.NewArtist);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtClient
Procedure ExecuteActionClient(CurTaskParameters)
	
	If Modified Then
		If Not CheckFilling() Then
			Return;
		EndIf;
		Write();
	EndIf;
	
	If CurTaskParameters.Action = 
			PredefinedValue("Enum.TypesOfBudgetingStepActions.ApprovalOfBudgets")
		Or CurTaskParameters.Action = 
			PredefinedValue("Enum.TypesOfBudgetingStepActions.Other") Then
			
		OpenForm("Task.BudgetTask.ObjectForm", New Structure("Key", CurTaskParameters.Task));
		
	Else
		If Not BudgetTaskList(CurTaskParameters.Task) Then
			Result = ExecuteActionServer(CurTaskParameters);
			If Result <> Undefined Then
				AdditionalParameters = New Structure("Document_",Result.FormParameters.Key);
				CallbackDescription = New CallbackDescription("CompleteEventTask", ThisObject, AdditionalParameters);
				OpenForm(Result.FormName, Result.FormParameters, ThisForm, Result.Uniqueness,,,CallbackDescription);
			EndIf;
		Else
			ShowValue(,CurTaskParameters.Task);
		EndIf;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function CurrentDocument(DocumentsList)
	
	Return ?(DocumentsList.Count(), DocumentsList[DocumentsList.Count()-1].Document, Undefined);
	
EndFunction

&AtServer
Function ExecuteActionServer(CurTaskParameters)
	
	TaskObject = CurTaskParameters.Task.GetObject();
	
	Action = TaskObject.Action;
	Document = CurrentDocument(TaskObject.DocumentsList);
	
	Write = False;
	Result = Tasks.BudgetTask.ExecuteAction(TaskObject, 
								GetFromTempStorage(CurTaskParameters.LinkToSettings), Write);
	
	If Write Then
		TaskObject.Write();
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function CurTaskParameters(Process_, ProcessStep, RepeatableStage, Period, AddressOfSettingTransfer)
	
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	BudgetTask.Ref,
		|	BudgetTask.Action,
		|	BudgetTask.SettingOfAction,
		|	BudgetTask.DocumentsList.(
		|		LineNumber AS LineNumber,
		|		Document
		|	)
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingProcess = &BudgetingProcess
		|	AND BudgetTask.BudgetingStep = &BudgetingStep
		|	AND BudgetTask.BudgetingStepBasis = &BudgetingStepBasis
		|	AND BudgetTask.Period = &Period
		|	AND NOT BudgetTask.DeletionMark
		|	AND NOT BudgetTask.Inactive_
		|
		|ORDER BY
		|	LineNumber";
	
	Query.SetParameter("Period", Period);
	Query.SetParameter("BudgetingStepBasis", RepeatableStage);
	Query.SetParameter("BudgetingProcess", Process_);
	Query.SetParameter("BudgetingStep", ProcessStep);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		SettingOfAction = SelectionDetailRecords.SettingOfAction; // ValueStorage
		
		Result = New Structure();
		Result.Insert("Task", SelectionDetailRecords.Ref); 
		Result.Insert("Action", SelectionDetailRecords.Action);
		Result.Insert("LinkToSettings", PutToTempStorage(SettingOfAction.Get(), AddressOfSettingTransfer)); 
		Result.Insert("CurrentDocument", CurrentDocument(SelectionDetailRecords.DocumentsList.Unload()) );
		
		Return Result;
		
	EndDo;
	
EndFunction

&AtClient
Procedure BackToTaskCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.No Then
		Return;
	EndIf;
	
	BackToTaskServer(AdditionalParameters.BudgetingStep);
	
EndProcedure

&AtServer
Procedure BackToTaskServer(BudgetingStep)
	
	Documents.BudgetingProcess.DisableActivityOfBudgetProcessTasks(Object.Ref, BudgetingStep);
	
	UpdateServerStatuses();
	
EndProcedure

&AtServer
Procedure FillInStepTree()
	
	StageTree = Documents.BudgetingProcess.TreeOfProcessStepsByDocument(Object);
	ValueToFormAttribute(StageTree, "BudgetProcessStepTree");
	
EndProcedure

&AtServer
Procedure FormControl()
	
	Items.FormRun.Visible = False;
	Items.FormDismiss.Visible = False;
	Items.FormExitApp.Visible = False;
	
	AllowedToChangeSettings = False;
	If Object.Status = Enums.StatusesOfBudgetingProcess.Running Then
		If FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 2)) <> Undefined
			And FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 1)) = Undefined
			And FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 0)) = Undefined Then
			Items.FormExitApp.Visible = True;
		Else
			Items.FormDismiss.Visible = True;
		EndIf;
	ElsIf Object.Status = Enums.StatusesOfBudgetingProcess.NotStarted Then
		Items.FormRun.Visible = True;
		AllowedToChangeSettings = True;
	EndIf;
	
	Items.BudgetingModel.ReadOnly = Not AllowedToChangeSettings;
	Items.StepGroup.ReadOnly = Not AllowedToChangeSettings;
	Items.Periodicity.ReadOnly = Not AllowedToChangeSettings;
	Items.Period.ReadOnly = Not AllowedToChangeSettings;
	
	AllTasksCompleted_ = False;
	If Object.Status <> Enums.StatusesOfBudgetingProcess.Completed
		And Object.Status <> Enums.StatusesOfBudgetingProcess.RolledBack_ Then
		If AllTasksCompleted_() Then
			AllTasksCompleted_ = True;
		EndIf;
	EndIf;
	Items.GroupAllTasksCompleted.Visible = AllTasksCompleted_;
	
EndProcedure

&AtServer
Procedure GroupOfStepsWhenChangingOnServer()
	
	OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
	DocumentIndex = OrderedPeriodicities.Find(Object.Periodicity);
	AttributesStructure1 = Common.ObjectAttributesValues(Object.StepGroup, "Periodicity, IsFolder, Parent.Periodicity");
	If AttributesStructure1.IsFolder Then
		StepFrequency = AttributesStructure1.Periodicity;
	Else
		StepFrequency = AttributesStructure1.ParentPeriodicity;
	EndIf;
	StepIndex = OrderedPeriodicities.Find(StepFrequency);
	If StepIndex > DocumentIndex Then
		Object.Periodicity = StepFrequency;
		If Not ValueIsFilled(Object.BeginOfPeriod) Then
			Object.BeginOfPeriod = CurrentSessionDate(); 
		EndIf;
		If Not ValueIsFilled(Object.EndOfPeriod) Then
			Object.EndOfPeriod = CurrentSessionDate(); 
		EndIf;
		EnterPeriodValue();
	Else
		FillInCalculationStepsOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCalculationStepsOnServer(RepeatableProcessStep = Undefined, RepeatableStepGroup = Undefined)
	
	If Not ValueIsFilled(RepeatableProcessStep) Then
		Object.CalculationSettings.Clear();
		Object.HierarchySettings.Clear();
	EndIf;
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetingSteps.Ref AS BudgetingStep,
		|	CASE
		|		WHEN BudgetingSteps.Ref = &Parent
		|			THEN UNDEFINED
		|		ELSE BudgetingSteps.Parent
		|	END AS StepGroup,
		|	BudgetingSteps.Duration,
		|	BudgetingSteps.DurationType,
		|	BudgetingSteps.EmployeeResponsible,
		|	BudgetingSteps.NotRunning,
		|	BudgetingSteps.Code,
		|	BudgetingSteps.IsFolder,
		|	BudgetingSteps.Periodicity,
		|	BudgetingSteps.Parent.Periodicity AS PeriodicityOfGroup,
		|	BudgetingSteps.Action,
		|	BudgetingSteps.ExecuteAutomatically
		|FROM
		|	Catalog.BudgetingSteps AS BudgetingSteps
		|WHERE
		|	BudgetingSteps.Ref IN HIERARCHY(&Parent)";
		
	If Not ValueIsFilled(RepeatableProcessStep) Then
		Query.SetParameter("Parent", Object.StepGroup);
	Else
		Query.SetParameter("Parent", RepeatableStepGroup);
	EndIf;
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	OrderedPeriodicities = Enums.Periodicity.OrderedPeriodicities();
	DocumentIndex = OrderedPeriodicities.Find(Object.Periodicity);
	
	SelectionDetailRecords.Reset();
	While SelectionDetailRecords.Next() Do
		
		If SelectionDetailRecords.BudgetingStep = RepeatableStepGroup Then
			Continue;
		EndIf;
		
		If SelectionDetailRecords.IsFolder Then
			FillInIndex = OrderedPeriodicities.Find(SelectionDetailRecords.Periodicity);
		Else
			FillInIndex = OrderedPeriodicities.Find(SelectionDetailRecords.PeriodicityOfGroup);
		EndIf;
		
		If FillInIndex > DocumentIndex Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch = New Structure("StepGroup, BudgetingStep, BudgetingStepBasis");
		FillPropertyValues(TheStructureOfTheSearch, SelectionDetailRecords);
		If ValueIsFilled(RepeatableProcessStep) Then
			TheStructureOfTheSearch.BudgetingStepBasis = TheStructureOfTheSearch.BudgetingStep;
			TheStructureOfTheSearch.BudgetingStep = RepeatableProcessStep;
		EndIf;
		
		If Not Object.HierarchySettings.FindRows(TheStructureOfTheSearch).Count() Then
			NewRow = Object.HierarchySettings.Add();
			FillPropertyValues(NewRow, SelectionDetailRecords);
			FillPropertyValues(NewRow, TheStructureOfTheSearch);
		EndIf;
	
		If SelectionDetailRecords.IsFolder Then
			Continue;
		EndIf;
		
		NewRow.Periodicity = SelectionDetailRecords.PeriodicityOfGroup;
		
		NewRow = Object.CalculationSettings.Add();
		FillPropertyValues(NewRow, SelectionDetailRecords);
		NewRow.Period = Object.BeginOfPeriod;
		If ValueIsFilled(RepeatableProcessStep) Then
			NewRow.BudgetingStepBasis = NewRow.BudgetingStep;
			NewRow.BudgetingStep = RepeatableProcessStep;
		EndIf;
		
		NextPeriod = WorkingWithClientServerPeriods.AddInterval(NewRow.Period, SelectionDetailRecords.PeriodicityOfGroup, 1);
		While NextPeriod <= Object.EndOfPeriod Do
			NewPeriodLine = Object.CalculationSettings.Add();
			FillPropertyValues(NewPeriodLine, NewRow);
			NewPeriodLine.Period = NextPeriod;
			NextPeriod = WorkingWithClientServerPeriods.AddInterval(NextPeriod, SelectionDetailRecords.PeriodicityOfGroup, 1);
		EndDo;
		
		If SelectionDetailRecords.Action = Enums.TypesOfBudgetingStepActions.StepGroupRepetition Then
			If Not ValueIsFilled(RepeatableProcessStep) Then
				SettingOfAction = Common.ObjectAttributeValue(SelectionDetailRecords.BudgetingStep, "SettingOfAction"); // ValueStorage
				FoundRow = SettingOfAction.Get().Find("StepGroup", "Name");
				If FoundRow <> Undefined Then
					RepeatableGroup = FoundRow.Value;
					FillInCalculationStepsOnServer(SelectionDetailRecords.BudgetingStep, RepeatableGroup);
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	If Not ValueIsFilled(RepeatableProcessStep) Then
		FillInStepTree();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function DefineTypeOfPeriod(Periodicity)
	
	Return Enums.AvailableReportPeriods[Common.EnumerationValueName(Periodicity)];
	
EndFunction

&AtClient
Procedure PeriodStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export

	If SelectedPeriod <> Undefined Then
		
		Period = SelectedPeriod.Presentation;
		
		Object.BeginOfPeriod = SelectedPeriod.Value;
		Object.EndOfPeriod = WorkingWithClientServerPeriods.PeriodEndDate_(SelectedPeriod.Value, Object.Periodicity);
		
		FillInCalculationStepsOnServer();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure DisplayPeriod_()
	
	If Not ValueIsFilled(Object.Periodicity) Then
		Period = "";
		Items.Period.Enabled = False;
		Return;
	Else
		Items.Period.Enabled = True;
	EndIf;
	
	PeriodType = DefineTypeOfPeriod(Object.Periodicity);
	PeriodsList = TMCommonUseClientServer.AvailablePeriodValuesByPeriodType(Object.BeginOfPeriod, PeriodType);
	ListItem = PeriodsList.FindByValue(Object.BeginOfPeriod);
	
	If ListItem = Undefined Then
		Period = "";
	Else
		Period = ListItem.Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure EnterPeriodValue()
	
	Object.BeginOfPeriod = WorkingWithClientServerPeriods.BeginningDateOfPeriod(Object.BeginOfPeriod, Object.Periodicity);
	Object.EndOfPeriod =  WorkingWithClientServerPeriods.PeriodEndDate_(Object.BeginOfPeriod, Object.Periodicity);
	
	DisplayPeriod_();
	FillInCalculationStepsOnServer();
	
EndProcedure

&AtClient
Procedure ExpandStepTree()
	
	For Each TreeRow In BudgetProcessStepTree.GetItems() Do
		Items.BudgetProcessStepTree.Expand(TreeRow.GetID(), True);
	EndDo;
	
EndProcedure

&AtClient
Procedure SetValueOfTablePart(FieldName)
	
	CurrentData = Items.BudgetProcessStepTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = New Structure("Period, BudgetingStep, BudgetingStepBasis");
	FillPropertyValues(TheStructureOfTheSearch, CurrentData);
	FoundRow = Object.CalculationSettings.FindRows(TheStructureOfTheSearch)[0];
	FoundRow[FieldName] = CurrentData[FieldName];
	
EndProcedure

&AtServer
Function FindRows(TreeRows, TheStructureOfTheSearch)
	
	Return Documents.BudgetingProcess.FindRows(TreeRows, TheStructureOfTheSearch);
	
EndFunction

&AtServer
Procedure UpdateServerStatuses()
	
	If Object.Ref.IsEmpty() Then
		Return;
	EndIf;
	
	Documents.BudgetingProcess.FillInTaskStatusesInTree(Object, BudgetProcessStepTree);
	
	SetFormHeader();
	
EndProcedure

&AtServerNoContext
Function ObjectTask(Document, BudgetingProcess)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	BudgetTask.Ref,
		|	BudgetTask.DeletionMark,
		|	BudgetTask.Executed,
		|	BudgetTask.Inactive_
		|INTO BudgetTasks
		|FROM
		|	Task.BudgetTask AS BudgetTask
		|WHERE
		|	BudgetTask.BudgetingProcess = &BudgetingProcess
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BudgetTaskDocumentsList.Ref
		|FROM
		|	BudgetTasks AS BudgetTasks
		|		LEFT JOIN Task.BudgetTask.DocumentsList AS BudgetTaskDocumentsList
		|		ON BudgetTasks.Ref = BudgetTaskDocumentsList.Ref
		|WHERE
		|	NOT BudgetTasks.DeletionMark
		|	AND NOT BudgetTasks.Inactive_
		|	AND BudgetTaskDocumentsList.Document = &Document
		|	AND NOT BudgetTasks.Executed";
	
	Query.SetParameter("Document", Document);
	Query.SetParameter("BudgetingProcess", BudgetingProcess);
	
	QueryResult = Query.Execute();
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		
		Return SelectionDetailRecords.Ref;
		
	EndDo;
	
EndFunction

&AtServerNoContext
Function StatusOfCurDocumentIsApproved(Source)
	
	DocumentAttributes = Common.ObjectAttributesValues(Source, "Status, Posted");
	If DocumentAttributes.Status = Enums.PlanStatuses.UnderPreparation Or Not DocumentAttributes.Posted Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure CompleteEventTask(Result, AdditionalParameters) Export
	
	Document = AdditionalParameters.Document_;
	Task = ObjectTask(Document, Object.Ref);
	If ValueIsFilled(Task) Then
		If  TypeOf(Result) = Type("DocumentRef.BudgetEntryForm")  
			And Not StatusOfCurDocumentIsApproved(Document) Then
			
			CommonClientServer.MessageToUser(
				NStr("vi = 'Để thực hiện nhiệm vụ, chứng từ cần có trạng thái ""Đang làm việc""';
					|ru = 'Для выполнения задачи документ должен быть в статусе ""В работе""';
					|en = 'To complete the task, the document should be in the ""In progress"" status'; fa = 'To complete the task, the document should be in the ""In progress"" status';
					|it = 'Per eseguire il compito il documento deve avere lo stato ""In lavorazione""';
					|pl = 'Aby zakończyć zadanie, dokument powinien mieć status ""W toku""';
					|tr = 'Görevi gerçekleştirmek için belge ""İşleniyor"" durumunda olması gerek'"));
			
		Else
			
			IDOfNextLine = PerformTaskOnServer(Task);
			If IDOfNextLine <> Undefined Then
				Items.BudgetProcessStepTree.CurrentRow = IDOfNextLine;
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServerNoContext
Function BudgetTaskList(Task)
	
	Return Tasks.BudgetTask.BudgetTaskList(Task);
	
EndFunction

&AtServer
Function ProcessingTaskNotificationOnServer()
	
	UpdateServerStatuses();
	
	FormControl();
	
	Return FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 1));
	
EndFunction

&AtServer
Function PerformTaskOnServer(Task)
	
	Try
		TaskObject = Task.GetObject();
		TaskObject.Lock();
	Except
		Return Undefined;
	EndTry;
	
	TaskObject.Executed = True;
	TaskObject.Write();
	
	UpdateServerStatuses();
	
	FormControl();
	
	Return FindRows(BudgetProcessStepTree.GetItems(), New Structure("StatusIndex_3", 1));
	
EndFunction

&AtClient
Procedure UpdateTaskStatuses()
	
	UpdateServerStatuses();
	
EndProcedure

&AtClient
Procedure ExitApp(Command)
	
	Object.Status = PredefinedValue("Enum.StatusesOfBudgetingProcess.Completed");
	Write();
	Close();
	
EndProcedure

&AtServerNoContext
Function ErrorInSelectedBudgetingModel(Model, EndDate)
	
	ModelData = Common.ObjectAttributesValues(Model, "Status, ValidToDate");
	If ModelData.Status <> Enums.BudgetingModelStatuses.Valid Then
		Return NStr("vi = 'Mô hình lập ngân sách không có hiệu lực.
									|Hãy thay đổi trạng thái mô hình để chọn trong chứng từ';
									|ru = 'Модель бюджетирования не действует.
									|Измените статус у модели для выбора в документе';
									|en = 'Budgeting model is invalid.
									|Change the model status for selection in the document'; fa = 'Budgeting model is invalid.
									|Change the model status for selection in the document';
									|it = 'Il modello del budgeting non funziona. 
									|Modificare lo status del modello per la selezione nel documento';
									|pl = 'Model budżetowania nie działa.
									|Zmień status modelu dla wyboru w dokumencie';
									|tr = 'Bütçeleme modeli etki etmiyor.
									|Belgede seçim yapabilmek için durum modelini değiştirin'");
	ElsIf ValueIsFilled(EndDate) And ValueIsFilled(ModelData.ValidToDate)
		And ModelData.ValidToDate < EndDate Then
		Return NStr("vi = 'Kỳ hiệu lực của mô hình lập ngân sách không tương ứng với kỳ chuẩn bị ngân sách';
					|ru = 'Период действия модели бюджетирования не соответствует периоду подготовки бюджетов';
					|en = 'The validity period of the budgeting model does not correspond to the budget preparation period'; fa = 'The validity period of the budgeting model does not correspond to the budget preparation period';
					|it = 'Период действия модели бюджетирования не соответствует периоду подготовки бюджетов';
					|pl = 'The validity period of the budgeting model does not correspond to the budget preparation period';
					|tr = 'Bütçeleme modeli geçerlilik dönemi bütçelerin hazırlanma dönemine karşılık gelmemektedir'");
	Else
		Return "";
	EndIf;
	
EndFunction

&AtServer
Function AllTasksCompleted_()
	
	Return Documents.BudgetingProcess.InStageTreeAllTasksAreCompleted(BudgetProcessStepTree);
	
EndFunction

&AtServer
Procedure SetFormHeader()
	
	If ValueIsFilled(Object.Ref) Then	
		Title = String(Object.Ref) + " (" + String(Object.Status) + ")";
	Else
		Title = Metadata.Documents.BudgetingProcess.Synonym + " (" + String(Object.Status) + ")";
	EndIf;
	
EndProcedure

&AtServer
Procedure ReplaceTaskExecutor(CurrentPerformer, NewArtist)
	
	Query = New Query;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Performer", CurrentPerformer);
	Query.Text = 
	"SELECT
	|	BudgetingProcessCalculationSettings.LineNumber AS LineNumber,
	|	ISNULL(BudgetTaskTasksByExecutive.Ref, UNDEFINED) AS BudgetTask,
	|	ISNULL(BudgetTaskTasksByExecutive.Executed, FALSE) AS Executed
	|FROM
	|	Document.BudgetingProcess.CalculationSettings AS BudgetingProcessCalculationSettings
	|		LEFT JOIN Task.BudgetTask.TasksByExecutive(&Performer, BudgetingProcess = &Ref) AS BudgetTaskTasksByExecutive
	|		ON BudgetingProcessCalculationSettings.Ref = BudgetTaskTasksByExecutive.BudgetingProcess
	|			AND BudgetingProcessCalculationSettings.BudgetingStep = BudgetTaskTasksByExecutive.BudgetingStep
	|			AND BudgetingProcessCalculationSettings.BudgetingStepBasis = BudgetTaskTasksByExecutive.BudgetingStepBasis
	|WHERE
	|	BudgetingProcessCalculationSettings.Ref = &Ref
	|	AND BudgetingProcessCalculationSettings.EmployeeResponsible = &Performer";
	
	BeginTransaction();
	
	Try
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			If Selection.Executed Then
				// There is no need to change the executor for completed tasks
				Continue;
			EndIf;
			
			TSRow = Object.CalculationSettings.Get(Selection.LineNumber-1);
			TSRow.EmployeeResponsible = NewArtist;
			
			If ValueIsFilled(Selection.BudgetTask) Then
				
				Block = New DataLock;
				LockItem = Block.Add("Task.BudgetTask");
				LockItem.SetValue("Ref", Selection.BudgetTask);
				Block.Lock();
				
				TaskObject = Selection.BudgetTask.GetObject();
				TaskObject.Performer = NewArtist;
				TaskObject.Write();
				
			EndIf;
			
		EndDo;
		
		Write();
		
		FillInStepTree();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể đổi người thực hiện nhiệm vụ do nguyên nhân:
			|%1';
			|ru = 'Не удалось выполнить замену исполнителя задач по причине:
			|%1';
			|en = 'Cannot replace the task assignee. Reason:
			|%1'; fa = 'Cannot replace the task assignee. Reason:
			|%1';
			|it = 'Не удалось выполнить замену исполнителя задач по причине:
			|%1';
			|pl = 'Cannot replace the task assignee. Reason:
			|%1';
			|tr = 'Görev atananı değişiminin gerçekleştirilememe nedeni:
			|%1'");
		
		Common.MessageToUser(StrTemplate(MessageText, ErrorProcessing.DetailErrorDescription(
			ErrorInfo())));
		
	EndTry;
	
EndProcedure

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
