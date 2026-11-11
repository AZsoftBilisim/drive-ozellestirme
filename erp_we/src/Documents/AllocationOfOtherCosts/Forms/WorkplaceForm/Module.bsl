#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseAccountingByExpenseObjects = False;
	Items.HyperlinkProductionDocuments.Visible = True;
	UseAccountingByExpenseObjects = GetFunctionalOption("UseAccountingByExpenseObjects");
	Items.CostSharingMode.Visible = UseAccountingByExpenseObjects;
	
	AdditionAvailable = AccessRight("Insert", Metadata.Documents.AllocationOfOtherCosts);

	IncomingData = New Map; 
	// In the Cur version, there is no metadata that has not been updated, which blocks the creation of new distribution documents.
	
	DeferredUpdateCompleted = Not CostCalculationAppliedAlgorithms.ThereIsDataLockWhenUpdatingInformationSecurity(IncomingData);
	Items.ExpenseItemsGenerateDocuments.Enabled = AdditionAvailable And DeferredUpdateCompleted;
	Items.IndicatorOfIncompleteDeferredUpdate.Visible = Not DeferredUpdateCompleted;
	Commands.GenerateDocuments.ToolTip = ?(DeferredUpdateCompleted,
		NStr("vi = 'Tạo chứng từ phân bổ theo các tùy chỉnh hiện tại';
			|ru = 'Сформировать документы распределения по текущим настройкам';
			|en = 'Create allocation documents by current settings'; fa = 'Create allocation documents by current settings';
			|it = 'Creare documenti di distribuzione in base alle impostazioni correnti';
			|pl = 'Wygeneruj dokumenty podziału zgodnie z bieżącymi ustawieniami';
			|tr = 'Mevcut ayarlara göre dağıtım belgeleri oluştur'"),
		NStr("vi = 'Không được phép tạo chứng từ phân bổ trước khi hoàn thành cập nhật hoãn lại';
			|ru = 'Формирование документов распределения недоступно до завершения отложенного обновления';
			|en = 'Cannot create allocation documents until the deferred update is completed'; fa = 'Cannot create allocation documents until the deferred update is completed';
			|it = 'Creazione dei documenti di distribuzione non disponibile fino al completamento dell''aggiornamento postposto';
			|pl = 'Wygenerowanie dokumentów podziału jest niedostępne do zakończenia odroczonej aktualizacji';
			|tr = 'Ertelenmiş güncelleme tamamlanana kadar dağıtım belgelerinin oluşturulması kullanılamaz'"));
	
	VTBusinessTransactionsAndDocumentTypes = TMCommonUse.AvailableBusinessTransactionsAndDocuments(DescriptionOfOperationsAndDocumentTypes(),
		FilterBusinessTransactions, FilterDocumentTypes, "");
	VTBusinessTransactionsAndDocumentTypes.Sort("Order");
	BusinessTransactionsAndDocuments.Load(VTBusinessTransactionsAndDocumentTypes);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	CostSharingMode = "ByArticles";
	
	FormItemsManagement();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	WhenOpenedOnServer();
	
	MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);
	
	CheckActivityOfBackgroundFormUpdateJob();
	
	SetVisibility1(ThisForm);
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AllocationOfOtherCosts"
		And TypeOf(Parameter) = Type("Structure")
		And Not Parameter.Count() = 0
		And Not Parameter.Property("DeleteMarkedObjects") Then
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("Organization", Parameter.Organization);
		FilterStructure1.Insert("Department", Parameter.Department);
		FilterStructure1.Insert("ExpenseItem", Parameter.ExpenseItem);
		FilterStructure1.Insert("DimensionOfExpenses", Parameter.DimensionOfExpenses);
		FilterStructure1.Insert("LineOfBusiness", Parameter.LineOfBusiness);
		
		Rows = ExpenseItems.FindRows(FilterStructure1);
		If Rows.Count() > 0 Then
			
			FillPropertyValues(Rows[0], Parameter);
			
			If ValueIsFilled(State)
				And State <> Rows[0].UPRStatus
				And State <> Rows[0].ReglStatus 
				Then
				UpdateFormData();
			EndIf;
			
		Else
			
			UPRStatus = Undefined;
			If Parameter.Property("UPRStatus") Then
				UPRStatus = Parameter.UPRStatus;
			EndIf;
			
			ReglStatus = Undefined;
			If Parameter.Property("ReglStatus") Then
				ReglStatus = Parameter.ReglStatus;
			EndIf;
			

			If ValueIsFilled(State) 
				And State <> UPRStatus
				And State <> ReglStatus
				Then
				UpdateFormData();
			EndIf;
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure CostSharingModeOnChange(Item)
	SetVisibility1(ThisForm);
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		Settings.Delete("Organization");
		Settings.Delete("Department");
	Else
		If Parameters.Property("Organization") Then
			Settings["Organization"] = Parameters.Organization;
		EndIf;
		Settings["Organization"] = SettingsValueCached.GetDefaultOrganization(Settings["Organization"]);
		
		If Parameters.Property("Department") Then
			Settings["Department"] = Parameters.Department;
		EndIf;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Settings["Period"] = Parameters.RegistrationPeriod;
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenOpenedOnServer()
	
	If Parameters.Property("State") Then
		State = Parameters.State;
	EndIf;
	
	SetDefaultValues();
	
	If Parameters.Property("Organization") Then
		Period = Parameters.Organization;
	EndIf;
	
	If Parameters.Property("Department") Then
		Period = Parameters.Department;
	EndIf;
	
	If Parameters.Property("RegistrationPeriod") Then
		Period = Parameters.RegistrationPeriod;
	EndIf;
	
	FiltersStructure = Undefined;
	If Parameters.Property("FiltersStructure", FiltersStructure) Then
		QuickFilterStructure = New Structure;
		
		If FiltersStructure.Property("Organization", Organization) Then
			QuickFilterStructure.Insert("Organization", Organization);
		EndIf;
		
		If FiltersStructure.Property("Department", Department) Then
			QuickFilterStructure.Insert("Department", Department);
		EndIf;
	Else
		Parameters.Property("QuickFilterStructure", QuickFilterStructure);
		If QuickFilterStructure <> Undefined Then
			QuickFilterStructure.Property("Organization", Organization);
			QuickFilterStructure.Property("Department", Department);
		EndIf;
	EndIf;
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	
	AddBackgroundTask("UpdateHyperlinkToLayout", CurrentBackgroundJobs);
	AddBackgroundTask("FillInExpenseItems", CurrentBackgroundJobs);
	
	TaskParameters = Undefined;
	PrepareServerTaskParameters(TaskParameters);
	RunBackgroundJobsOnServer(TaskParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MonthLineStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("MonthLineStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", Period, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MonthLineStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		Period = SelectedPeriod;
		MonthLine = TMCommonUseClient.GetPresentationOfRegistrationPeriod(Period);

		UpdateFormData();
	EndIf;
	
EndProcedure

&AtClient
Procedure MonthLineTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(Direction,
																		  StandardProcessing,
																		  Period,
																		  MonthLine);
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure MonthLineClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	UpdateFormData();
	SetVisibility1(ThisForm);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	UpdateFormData();
	SetVisibility1(ThisForm);
	
EndProcedure

&AtClient
Procedure StateOnChange(Item)
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure ToRegisterURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",		Organization);
	QuickFilterStructure.Insert("Department",	Department);
	QuickFilterStructure.Insert("FilterDocumentTypes",			FilterDocumentTypes);
	QuickFilterStructure.Insert("FilterBusinessTransactions",	FilterBusinessTransactions);
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	FormParameters.Insert("Organization",		Organization);
	FormParameters.Insert("RegistrationPeriod",			Period);
	
	OpenForm(FormattedStringURL,FormParameters);
	
EndProcedure

&AtClient
Procedure HyperlinkProductionDocumentsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	TMCommonUseClient.OpenLog(LogParameters());
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExpenseItems

&AtClient
Procedure ExpenseItemsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenDocumentForm();
	
EndProcedure

&AtClient
Procedure ExpenseItemsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenDocumentForm();	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure ExpenseItemsOpen(Command)
	
	OpenDocumentForm();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure ExpenseItemsGenerateDocuments(Command)
	
	If Items.ExpenseItems.SelectedRows.Count() = 0 Then
		
		CommonClientServer.MessageToUser(NStr("vi = 'Chưa chọn dòng nào.';
												|ru = 'Не выделено ни одной строки.';
												|en = 'No lines selected.'; fa = 'No lines selected.';
												|it = 'Nessuna riga selezionata.';
												|pl = 'Nie osunięto ani jednego wiersza';
												|tr = 'Herhangi bir satır belirtilmedi.'"));
		Return;
		
	EndIf;
	
	RunBackgroundJob1("GenerateDocuments");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemsUPRStatus.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ExpenseItemsReglStatus.Name);

	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExpenseItems.UPRStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CostAllocationStates.AllocationError;

	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ExpenseItems.ReglStatus");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.CostAllocationStates.AllocationError;
	

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

EndProcedure

#Region FillingForm

&AtClient
Procedure UpdateFormData()

	PerformanceMonitorClient.TimeMeasurement(
		"Document.AllocationOfOtherCosts.Form.WorkplaceForm.UpdateFormData");

	DetachIdleHandler("CheckActivityOfBackgroundFormUpdateJob");
	
	BatchAccounting22 = BatchAccountingIsUsed(Period);
	
	ExpenseItems.Clear();
	AddBackgroundTask("UpdateHyperlinkToLayout", CurrentBackgroundJobs);
	AddBackgroundTask("FillInExpenseItems", CurrentBackgroundJobs);
	
	StartBackgroundJobs();

EndProcedure

#EndRegion

#Region BackgroundJobs

#Region CommonMechanisms

&AtClientAtServerNoContext
Procedure AddBackgroundTask(JobName, CurrentBackgroundJobs, ClearQueue = False)

	If ClearQueue Then
		
		CancelCurTasks(CurrentBackgroundJobs);
		CurrentBackgroundJobs.Clear();
		
	EndIf;
	
	TaskData_ = CurrentBackgroundJobs.Add();
	TaskData_.Name = JobName;
	
EndProcedure

&AtClient
Procedure RunBackgroundJob1(JobName)
	
	AddBackgroundTask(JobName, CurrentBackgroundJobs, True);
	
	StartBackgroundJobs();

EndProcedure

&AtClient
Procedure StartBackgroundJobs()

	AllTasksCompleted = RunBackgroundJobsOnServer(PrepareClientTaskParameters());
	
	If AllTasksCompleted Then
		ProcessTaskCompletionOnClient();
	Else
		CheckActivityOfBackgroundFormUpdateJob();
	EndIf;

EndProcedure

// Run background jobs on the server.
// 
// Parameters:
//  TaskParameters - Map - task parameters
// 
// Returns:
//  Boolean - Start background tasks on the server
&AtServer
Function RunBackgroundJobsOnServer(Val TaskParameters)
	
	AllTasksCompleted = True;
	
	TaskDescriptions = BackgroundJobDescriptions();
	
	For Each TasksInQueue In CurrentBackgroundJobs Do
		
		If TasksInQueue.Running
			Or TasksInQueue.Completed2 Then
			Continue;
		EndIf;
		
		JobDetails = TaskDescriptions.Get(TasksInQueue.Name);
		If JobDetails = Undefined Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
								NStr("vi = 'Nhiệm vụ không xác định ""%1""';
									|ru = 'Неизвестное задание ""%1""';
									|en = 'Unknown job ""%1""'; fa = 'Unknown job ""%1""';
									|it = 'Task sconosciuto ""%1""';
									|pl = 'Nieznane zadanie ""%1""';
									|tr = '""%1"" bilinmeyen görevi'"),
								TasksInQueue.Name);
		EndIf;
							
		JobParameters = TaskParameters.Get(TasksInQueue.Name);
		If JobParameters = Undefined Then
			
			PrepareServerTaskParameters(TaskParameters);
			JobParameters = TaskParameters.Get(TasksInQueue.Name);
			
		EndIf;
		
		RunResult = ExecuteInBackground(JobDetails, JobParameters);
		
		TasksInQueue.Id  = RunResult.JobID;
		TasksInQueue.StorageAddress = RunResult.ResultAddress;
		TasksInQueue.RunResult = RunResult;
		
		If RunResult.Status = "Running" Then
			TasksInQueue.Running = True;
		ElsIf RunResult.Status = "Completed2" Then
			TasksInQueue.Completed2 = True;
		EndIf;
		
		If Not TasksInQueue.Completed2 Then
			AllTasksCompleted = False;
		EndIf;
		
	EndDo;
	
	CustomizeItemsBasedOnBackgroundJobs(ThisForm);
	
	Return AllTasksCompleted;

EndFunction

&AtServer
Function ExecuteInBackground(JobDetails, JobParameters)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDetails.Presentation;
	
	CurrentOperation = JobDetails.Presentation;
	
	TaskStartResult = TimeConsumingOperations.ExecuteInBackground(
									JobDetails.Method,
									JobParameters,
									ExecutionParameters);
			
	Return TaskStartResult;
	
EndFunction

// Cancel the current service background tasks of the Form.
// 
// Parameters:
//  CurrentBackgroundJobs See Document.AllocationOfOtherCosts.Form.WorkplaceForm.CurrentBackgroundJobs
&AtServerNoContext
Procedure CancelCurTasks(Val CurrentBackgroundJobs)
	
	For Each Job In CurrentBackgroundJobs Do
		TimeConsumingOperations.CancelJobExecution(Job.Id);
	EndDo;
	
EndProcedure

#EndRegion

#Region TaskCompletionControl

&AtClient
Procedure CheckActivityOfBackgroundFormUpdateJob()
	
	For Each Job In CurrentBackgroundJobs Do
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("ProcessJobExecutionResult", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			Job.RunResult, CallbackOnCompletion, IdleParameters);
			
	EndDo;
	
EndProcedure

#EndRegion

#Region TaskDescriptions

&AtClientAtServerNoContext
Function BackgroundJobDescriptions()
	
	TaskDescription_ = New Map;
	
	TaskDescription_.Insert("GenerateDocuments",
		BackgroundJobCharacteristics(NStr("vi = 'Lập các chứng từ để phân bổ chi phí.';
											|ru = 'Формирование документов распределения расходов.';
											|en = 'Generate expense allocation documents.'; fa = 'Generate expense allocation documents.';
											|it = 'Formazione dei documenti di ripartizione delle spese.';
											|pl = 'Tworzenie dokumentów podziału kosztów.';
											|tr = 'Giderlerin dağıtımı için belgelerin oluşturulması.'"),
			"Documents.AllocationOfOtherCosts.GenerateDocuments",
			,
			True));
		
	TaskDescription_.Insert("FillInExpenseItems",
		BackgroundJobCharacteristics(NStr("vi = 'Điền dạng chi phí.';
											|ru = 'Заполнение статей расходов.';
											|en = 'Fill in expense items.'; fa = 'Fill in expense items.';
											|it = 'Compilazione delle voci di spesa.';
											|pl = 'Wypełnienie wydatków';
											|tr = 'Gider kalemleri dolduruluyor.'"),
			"Documents.AllocationOfOtherCosts.ArticlesToBeDistributedInBackground"));
			
	TaskDescription_.Insert("UpdateHyperlinkToLayout",
		BackgroundJobCharacteristics(NStr("vi = 'Nhận dữ liệu để lập.';
											|ru = 'Получение данных к оформлению.';
											|en = 'Obtain the data to register.'; fa = 'Obtain the data to register.';
											|it = 'Ricezione dei dati da registrare.';
											|pl = 'Odbieranie danych do rejestracji.';
											|tr = 'Düzenlenecek verilerin alınması.'"),
			"Documents.AllocationOfOtherCosts.CreateHyperlinkToBackgroundTaskLayout",
			False));

	Return TaskDescription_;
	
EndFunction

&AtClientAtServerNoContext
Function BackgroundJobCharacteristics(Presentation = "", Method = "", OutputBagel = True, BlockForm = False)
	
	Characteristics = New Structure;
	Characteristics.Insert("Presentation", Presentation);
	Characteristics.Insert("Method", Method);
	Characteristics.Insert("OutputBagel", OutputBagel);
	Characteristics.Insert("BlockForm", BlockForm);
	
	Return Characteristics;
	
EndFunction

&AtClient
Function PrepareClientTaskParameters()
	
	TaskParameters = New Map;
	
	For Each TasksInQueue In CurrentBackgroundJobs Do
		
		If TasksInQueue.Running Or TasksInQueue.Completed2 Then
			Continue;
		EndIf;
		
		JobParameters = Undefined;
		If TasksInQueue.Name = "GenerateDocuments" Then
			
			JobParameters = New Structure;
			JobParameters.Insert("ExpenseParameters", 	GetExpenseParameters());
			JobParameters.Insert("CompanyArray", 	Organization);
			JobParameters.Insert("RegistrationPeriod", 	Period);
			
		EndIf;
		
		If TasksInQueue.Name = "FillInExpenseItems" Then
			
			JobParameters = New Structure;
			JobParameters.Insert("Period", 		Period);
			JobParameters.Insert("Organization", 	Organization);
			JobParameters.Insert("Department", 	Department);
			JobParameters.Insert("State", 		State);
			JobParameters.Insert("OnlyConstantDifferences", False);
			
		EndIf;
		
		If JobParameters = Undefined Then
			Continue;
		EndIf;
		
		TaskParameters.Insert(TasksInQueue.Name, JobParameters);
		
	EndDo;
	
	Return TaskParameters;
	
EndFunction

&AtServer
Procedure PrepareServerTaskParameters(TaskParameters)
	
	If TaskParameters = Undefined Then
		TaskParameters = New Map;
	EndIf;
	
	For Each TasksInQueue In CurrentBackgroundJobs Do
		
		If TasksInQueue.Completed2
			Or TasksInQueue.Running
			Or Not TaskParameters.Get(TasksInQueue.Name) = Undefined Then
			Continue;
		EndIf;
		
		JobParameters = New Array;
		If TasksInQueue.Name = "UpdateHyperlinkToLayout" Then
			
			Filter = New Structure;
			Filter.Insert("Period", Period);
			Filter.Insert("Organization", Organization);
			Filter.Insert("Department", Department);
			
			JobParameters.Add(BusinessTransactionsAndDocuments.Unload());
			JobParameters.Add(Filter);
			
		EndIf;
		
		If TasksInQueue.Name = "FillInExpenseItems" Then
			
			JobParameters = New Structure;
			JobParameters.Insert("Period", 		Period);
			JobParameters.Insert("Organization", 	Organization);
			JobParameters.Insert("Department", 	Department);
			JobParameters.Insert("State", 		State);
			JobParameters.Insert("OnlyConstantDifferences", False);
			
		EndIf;
		
		TaskParameters.Insert(TasksInQueue.Name, JobParameters);
		
	EndDo;
	
EndProcedure

#Region ProcessingResultsOfBackgroundTasks

&AtClient
Procedure ProcessTaskCompletionOnClient()
	
	For Each TaskData_ In CurrentBackgroundJobs Do
		
		If TaskData_.Name = "GenerateDocuments" Then
			ProcessResultOfDocumentGeneration(TaskData_.StorageAddress);
		ElsIf TaskData_.Name = "FillInExpenseItems" Then
			
			PerformanceMonitorClient.TimeMeasurement(
				"Document.AllocationOfOtherCosts.Form.WorkplaceForm.GettingResultOfArticleToDistributionInBackground");
			
			ProcessResultOfReceivingExpenseItems(TaskData_.StorageAddress);
			
		ElsIf TaskData_.Name = "UpdateHyperlinkToLayout" Then
			ProcessResultOfFormationForRegistration(TaskData_.StorageAddress);	
		EndIf;
		
	EndDo;
	
	CurrentBackgroundJobs.Clear();
	CustomizeItemsBasedOnBackgroundJobs(ThisForm);
	
EndProcedure

&AtClient
Procedure ProcessJobExecutionResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		AllTasksAreCompleted = True;
		
		For Each BackgroundJob In CurrentBackgroundJobs Do
			If BackgroundJob.Id = Result.JobID Then
				BackgroundJob.Completed2 = True;
			EndIf;
			AllTasksAreCompleted = Min(AllTasksAreCompleted, BackgroundJob.Completed2);
		EndDo;
		
		If AllTasksAreCompleted Then
			ProcessTaskCompletionOnClient();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessResultOfDocumentGeneration(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	
	For Each OrganizationResults In Result Do
		
		DetailingResult = OrganizationResults.Value;
		
		If DetailingResult.ErrorsDescription.Count() > 0 Then
			For Each ErrorDescription In DetailingResult.ErrorsDescription Do
				CommonClientServer.MessageToUser(ErrorDescription.ErrorText);
			EndDo;
		EndIf;
		
		If DetailingResult.GeneratedDocuments_  = 0 Then
			Continue;
		EndIf;
		
		TemplateGeneratedDocuments = NStr("vi = 'Theo doanh nghiệp %1, đã được tạo %2 chứng từ phân bổ.';
											|ru = 'По организации %1 сформировано %2 документов распределения.';
											|en = '%2 allocation documents are generated by the company %1.'; fa = '%2 allocation documents are generated by the company %1.';
											|it = 'Per azienda %1 sono stati generati %2 documenti di ripartizione.';
											|pl = 'Według firmy %1 powstały %2 dokumenty dystrybucyjne.';
											|tr = '%1 iş yerine göre %2 dağıtım belgesi oluşturuldu.'");
		ShowUserNotification(,
			,
			StrTemplate(TemplateGeneratedDocuments,
				OrganizationResults.Key,
				Format(DetailingResult.GeneratedDocuments_, "NG=0")),
			PictureLib.Information32);
		
		For Each NewData In DetailingResult.UpdatedData_ Do
			
			LineToUpdate_ = ExpenseItems.FindByID(NewData.LineID);
			If LineToUpdate_ = Undefined 
				Or Not LineToUpdate_.ExpenseItem = NewData.ExpenseItem
				Or Not LineToUpdate_.DimensionOfExpenses = NewData.DimensionOfExpenses
				Or Not LineToUpdate_.Organization = NewData.Organization
				Or Not LineToUpdate_.Department = NewData.Department
				Or Not LineToUpdate_.LineOfBusiness = NewData.LineOfBusiness Then
				Continue;
			EndIf;
			
			FillPropertyValues(LineToUpdate_, NewData, , 
				"ExpenseItem, DimensionOfExpenses, Organization, Department, LineOfBusiness");
			
		EndDo;
		
	EndDo;
	
EndProcedure	

&AtServer
Procedure ProcessResultOfReceivingExpenseItems(StorageAddress)
	
	Result = GetFromTempStorage(StorageAddress);
	
	If Not Result = Undefined Then
		ExpenseItems.Load(Result);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfFormationForRegistration(StorageAddress)
	
	ToRegister = GetFromTempStorage(StorageAddress);
	
	If Not ValueIsFilled(ToRegister) Then
		TextIsUpdatingData = NStr("vi = 'Cần lập: không';
									|ru = 'К оформлению: нет';
									|en = 'To register: no'; fa = 'To register: no';
									|it = 'Da formalizzare: no';
									|pl = 'Do rejestracji: brak';
									|tr = 'Düzenlenecek: yok'");
		ToRegister = New FormattedString(TextIsUpdatingData);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Other

&AtServer
Function DescriptionOfOperationsAndDocumentTypes()
	
	VTBusinessTransactionsAndDocumentTypes = BusinessTransactionsAndDocuments.Unload();
	VTBusinessTransactionsAndDocumentTypes.Clear();

	#Region DeferredExpensesAllocation
	
	RBPLine							= VTBusinessTransactionsAndDocumentTypes.Add();
	String								= RBPLine;
	String.BusinessOperation		= Enums.BusinessTransactions.DeferredExpenseAllocation;
	String.PurposeUseKey	= "";
	String.WorkplaceTitle		= NStr("vi = 'Phân bổ chi phí trả trước';
										|ru = 'Распределение расходов будущих периодов';
										|en = 'Deferred expense allocation'; fa = 'تسهیم هزینه‌های معوق';
										|it = 'Ripartizione spese dei riscontri attivi';
										|pl = 'Podział wydatków przyszłych okresów';
										|tr = 'Ertelenmiş giderler tahsisi'");
	String.DocumentType					= Type("DocumentRef.DeferredExpensesAllocation");
	String.FullDocumentName			= Metadata.Documents.DeferredExpensesAllocation.FullName();
	String.StatusesAreUsed			= False;
	String.AddButtonCreate		= False;
	String.Order						= 10;
	String.Filter 						= True;
	String.HyperlinkCalculationManagerForRegistration = "Document.DeferredExpensesAllocation";
		
	#EndRegion
	
	Return VTBusinessTransactionsAndDocumentTypes;
	
EndFunction

&AtClient
Procedure ProcessUserResponse(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters.AccountingDimension = Result;
	OpenDocumentForm(AdditionalParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CustomizeItemsBasedOnBackgroundJobs(Form)
	
	Items = Form.Items;
	
	TaskDescription_ = BackgroundJobDescriptions();
	
	OutputBagel = False;
	BlockForm = False;
	NoInformationForRegistration = False;
	
	For Each TasksInQueue In Form.CurrentBackgroundJobs Do
		
		JobDetails = TaskDescription_.Get(TasksInQueue.Name);
		
		OutputBagel = Max(OutputBagel, JobDetails.OutputBagel And TasksInQueue.Running);
		BlockForm = Max(BlockForm, JobDetails.BlockForm And TasksInQueue.Running);
		NoInformationForRegistration = Max(NoInformationForRegistration, 
									TasksInQueue.Name = "UpdateHyperlinkToLayout" And TasksInQueue.Running);
	EndDo;
	
	Items.GroupFilter.Enabled = Not BlockForm;
	Items.ExpenseItems.Enabled = Not BlockForm;
	Items.GroupPerformingCalculationInTheBackground.Visible = OutputBagel;
	
	If NoInformationForRegistration Then
		
		TextIsUpdatingData = NStr("vi = 'Cần lập: <đang cập nhật dữ liệu>';
									|ru = 'К оформлению: <идет обновление данных>';
									|en = 'To register: <updating data>'; fa = 'To register: <updating data>';
									|it = 'Da formalizzare: <dati in fase di aggiornamento>';
									|pl = 'Do rejestracji: <odbywa się aktualizacja danych>';
									|tr = 'Düzenlenecek: <veri güncellemesi devam ediyor>'");
		Form.ToRegister = New FormattedString(TextIsUpdatingData);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibility1(Form)
	
	Items = Form.Items;
	
	Items.ExpenseItemsDepartment.Visible = Not ValueIsFilled(Form.Department);
	Items.ExpenseItemsOrganization.Visible = Not ValueIsFilled(Form.Organization);

	// Displaying elements for working with cost objects
	FromHIA = Form.CostSharingMode = "FromHIA";
	Items.ExpenseItems.RowFilter = New FixedStructure("ThisIsOVZ", FromHIA);
	Items.ExpenseItem.Visible = Not FromHIA;
	Items.LineOfBusiness.Visible = Not FromHIA;
	Items.GroupItem.Visible = Not FromHIA;
	Items.DimensionOfExpenses.Title = 
		?(FromHIA, NStr("vi = 'Đối tượng phát sinh chi phí';
						|ru = 'Объект возникновения затрат';
						|en = 'Cost center'; fa = 'مرکز هزینه';
						|it = 'Centro di costo';
						|pl = 'Obiekt tworzenia się rozchodów';
						|tr = 'Gider oluşum nesnesi'"), NStr("vi = 'Đối tượng phân tích chi phí';
													|ru = 'Аналитика расхода';
													|en = 'Expense dimension'; fa = 'بُعد هزینه';
													|it = 'Analisi dei dati di uscita';
													|pl = 'Analityka rozchodu';
													|tr = 'Gider boyutu'"));
	
EndProcedure

&AtServer
Procedure SetDefaultValues()
	
	If Not ValueIsFilled(Period) Then
		Period = BegOfMonth(CurrentSessionDate());
	EndIf; 
	
EndProcedure

&AtClient
Function DefineParametersForOpeningDocumentForm(CurrentData, OpeningParameters)
	
	If Not OpeningParameters = Undefined Then
		Return OpeningParameters;
	EndIf;
	

	UseAIT = DefineAITUsage();
	
	FormParameters = New Structure;
	FormParameters.Insert("AccountingDimension", Undefined);
	FormParameters.Insert("SettingUpDistribution", Undefined);
	
	If CurrentData.DocumentMan = CurrentData.DocumentCompl
		And (CurrentData.DocumentMan = CurrentData.DocumentAIT
			Or Not UseAIT)
		And ValueIsFilled(CurrentData.DocumentMan) Then
		Return FormParameters;
	EndIf;
	
	CurrentField = Items.ExpenseItems.CurrentItem;
	
	If CurrentField.Name = "ExpenseItemsUPRStatus"
		Or (CurrentData.ReglStatus = PredefinedValue("Enum.CostAllocationStates.NotRequired") 
			And (CurrentData.NDDState = PredefinedValue("Enum.CostAllocationStates.NotRequired")
				Or Not UseAIT)
			)
		Then
		
		FormParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.Management");
		Return FormParameters;
		
	ElsIf CurrentField.Name = "ExpenseItemsReglStatus"
		Or (CurrentData.UPRStatus = PredefinedValue("Enum.CostAllocationStates.NotRequired") 
			And (CurrentData.NDDState = PredefinedValue("Enum.CostAllocationStates.NotRequired")
				Or Not UseAIT)
			)
		Then
		
		FormParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.Local");
		Return FormParameters;

	ElsIf UseAIT And (CurrentField.Name = "ExpenseItemsNDDState"
		Or (CurrentData.UPRStatus = PredefinedValue("Enum.CostAllocationStates.NotRequired") 
			And CurrentData.ReglStatus = PredefinedValue("Enum.CostAllocationStates.NotRequired") 
			And CurrentData.StateOfNal = PredefinedValue("Enum.CostAllocationStates.NotRequired")
			))
		Then
		
		FormParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.AIT");
		Return FormParameters;
	
	EndIf;
	
	If Not ValueIsFilled(CurrentData.DocumentMan)
		And Not ValueIsFilled(CurrentData.DocumentCompl)
		And (Not ValueIsFilled(CurrentData.DocumentAIT)
			Or Not UseAIT)
		Then
		
		If Not (AdditionAvailable And DeferredUpdateCompleted) Then
			Return Undefined;
		EndIf;
		
		FormParameters.SettingUpDistribution = GetCostItemAllocationSettings(
			GetExpenseParameters(CurrentData.GetID()), 
			CurrentData.Organization,
			EndOfMonth(Period))[0];
		
		If FormParameters.SettingUpDistribution.LocalDistributionOption = FormParameters.SettingUpDistribution.ManDistributionOption
			And FormParameters.SettingUpDistribution.LocalDistributionRule = FormParameters.SettingUpDistribution.ManDistributionRule
			And Not UseAIT 
				Or (FormParameters.SettingUpDistribution.NDTDistributionOption = FormParameters.SettingUpDistribution.ManDistributionOption
					And FormParameters.SettingUpDistribution.RuleOfDistributionOfPersonalIncomeTax = FormParameters.SettingUpDistribution.ManDistributionRule)
			Or FormParameters.SettingUpDistribution.LocalDistributionOption = FormParameters.SettingUpDistribution.ManDistributionOption
				And FormParameters.SettingUpDistribution.LocalDistributionOption = PredefinedValue("Enum.CostAllocationOptions.ToProductionCosts")
				And Not BatchAccounting22 Then
			Return FormParameters;
		EndIf;
		
	EndIf;
		
	ResponseOptions = New ValueList;
	
	If Not CurrentData.UPRStatus = 
		PredefinedValue("Enum.CostAllocationStates.NotRequired")
		Then
		ResponseOptions.Add(PredefinedValue("Enum.AccountingDimensions.Management"), 
			NStr("vi = 'Đối với kế toán quản trị';
				|ru = 'Для управленческого учета';
				|en = 'For management accounting'; fa = 'For management accounting';
				|it = 'Per contabilità gestionale';
				|pl = 'Dla ewidencji zarządczej';
				|tr = 'Yönetim muhasebesi için'"));
	EndIf;
	
	If Not CurrentData.ReglStatus = 
		PredefinedValue("Enum.CostAllocationStates.NotRequired")
		Then
		ResponseOptions.Add(PredefinedValue("Enum.AccountingDimensions.Local"), 
			NStr("vi = 'Đối với kế toán doanh nghiệp';
				|ru = 'Для бухгалтерского учета';
				|en = 'For accounting'; fa = 'For accounting';
				|it = 'Per la contabilità';
				|pl = 'Dla ewidencji księgowej';
				|tr = 'Genel muhasebe için'"));
	EndIf;
	

	If UseAIT And Not CurrentData.NDDState = 
		PredefinedValue("Enum.CostAllocationStates.NotRequired")
		Then
		ResponseOptions.Add(PredefinedValue("Enum.AccountingDimensions.AIT"), 
			NStr("vi = 'Đối với thuế thu nhập bổ sung';
				|ru = 'Для НДД';
				|en = 'For AIT'; fa = 'For AIT';
				|it = 'Для НДД';
				|pl = 'For AIT';
				|tr = 'EGV için'"));
	EndIf;
	
	ResponseOptions.Add(Undefined, NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'"));
	
	ShowQueryBox(New CallbackDescription("ProcessUserResponse", ThisObject, FormParameters), 
		NStr("vi = 'Quy tắc phân bổ trong các dạng kế toán khác nhau là khác nhau. 
		|Đối với dạng kế toán nào cần mở tùy chỉnh quy tắc phân bổ?';
		|ru = 'Правила распределения для различных видов учета отличаются. 
		|Для какого вида учета открыть настройку правила распределения?';
		|en = 'Allocation rules for different accounting kinds are different. 
		|For which accounting kind should the allocation rule setting be opened?'; fa = 'Allocation rules for different accounting kinds are different. 
		|For which accounting kind should the allocation rule setting be opened?';
		|it = 'Le regole di distribuzione differiscono tra tipi diversi di contabilità. 
		|Per quale tipo di contabilità aprire l''impostazione della regola di distribuzione?';
		|pl = 'Zasady dystrybucji dla różnych rodzajów ewidencji różnią się. 
		|Dla jakiego rodzaju ewidencji otworzyć ustawienie zasady dystrybucji?';
		|tr = 'Farklı muhasebe türleri için dağıtım kuralları farklıdır. 
		|Dağıtım kuralı ayarı hangi muhasebe için açılsın?'"), 
		ResponseOptions);
		
	Return Undefined;
	
EndFunction


&AtClient
Procedure OpenDocumentForm(OpeningParameters = Undefined)
	
	CurrentData = Items.ExpenseItems.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpeningParameters = DefineParametersForOpeningDocumentForm(CurrentData, OpeningParameters);
	If OpeningParameters = Undefined Then
		Return;
	EndIf;
	
	UseAIT = DefineAITUsage();
	
	Document = CurrentData.DocumentMan;
		
	If OpeningParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.Local") Then
		Document = CurrentData.DocumentCompl;
	ElsIf OpeningParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.AIT") And UseAIT Then
		Document = CurrentData.DocumentAIT;
	EndIf;
	
	If Document.IsEmpty() Then
		
		If Not (AdditionAvailable And DeferredUpdateCompleted) Then
			Return;
		EndIf;
		
		If OpeningParameters.SettingUpDistribution = Undefined Then
			OpeningParameters.SettingUpDistribution = GetCostItemAllocationSettings(
				GetExpenseParameters(CurrentData.GetID()),
				CurrentData.Organization,
				EndOfMonth(Period))[0];
		EndIf;
		
		OpeningParameters.SettingUpDistribution.Insert("ManagementAccounting", OpeningParameters.AccountingDimension = Undefined
			Or OpeningParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.Management"));
		OpeningParameters.SettingUpDistribution.Insert("LocalAccounting", OpeningParameters.AccountingDimension = Undefined
			Or OpeningParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.Local"));
		OpeningParameters.SettingUpDistribution.Insert("AIT", UseAIT 
			And (OpeningParameters.AccountingDimension = Undefined
				Or OpeningParameters.AccountingDimension = PredefinedValue("Enum.AccountingDimensions.AIT")));
		
		FormParameters = New Structure;
		FormParameters.Insert("Basis", OpeningParameters.SettingUpDistribution);
		
	Else
		FormParameters = New Structure("Key", Document);
	EndIf;
	
	OpenForm("Document.AllocationOfOtherCosts.ObjectForm", FormParameters, Items.ExpenseItems);
	
EndProcedure

&AtServer
Function LogParameters()
	
	LogParameters = New Structure;
	LogParameters.Insert("FormAssignmentKey", "AllocationOfOtherCosts");
	LogParameters.Insert("WorkplaceName", "LogOfProductionDocuments");
	LogParameters.Insert("JournalSynonym",NStr("vi = 'Chứng từ sản xuất';
												|ru = 'Документы производства';
												|en = 'Production documents'; fa = 'اسناد تولید';
												|it = 'Documenti di produzione';
												|pl = 'Dokumenty produkcji';
												|tr = 'Üretim belgeleri'"));
	ListFormSelections = New Structure;
	ListFormSelections.Insert("Period", New StandardPeriod(BegOfMonth(Period), EndOfMonth(Period)));
	ListFormSelections.Insert("Organization", Organization);
	ListFormSelections.Insert("Department", Department);
	
	FilterDocumentTypes = New ValueList;
	FilterDocumentTypes.Add(Common.MetadataObjectID("Document.AllocationOfOtherCosts"));
	ListFormSelections.Insert("FilterDocumentTypes", FilterDocumentTypes);
	
	FilterBusinessTransactions = New ValueList;
	FilterBusinessTransactions.Add(Enums.BusinessTransactions.ExpensingToProductionLots);
	ListFormSelections.Insert("FilterBusinessTransactions", FilterBusinessTransactions);
	
	LogParameters.Insert("ListFormSelections", ListFormSelections);
	
	Return LogParameters;
	
EndFunction
// Generates an array with data by string
//	Parameters:
//		LineID - Number - ID of the line that triggered the Select event
//	Returns:
//		Array - contains a structure with string data.
//
&AtClient
Function GetExpenseParameters(LineID = Undefined)
	
	ExpenseParameters = New Array;
	For Each CurRow In Items.ExpenseItems.SelectedRows Do
		
		If Not LineID = Undefined And Not CurRow = LineID Then
			Continue;
		EndIf;
		
		FillingData = New Structure;
		RowData = Items.ExpenseItems.RowData(CurRow);
		FillingData.Insert("Date",                    EndOfMonth(Period));
		FillingData.Insert("DocumentMan",			 RowData.DocumentMan);
		FillingData.Insert("DocumentCompl",			 RowData.DocumentCompl);
		FillingData.Insert("DocumentAIT",			 RowData.DocumentAIT);
		
		FillingData.Insert("UPRStatus",			 RowData.UPRStatus);
		FillingData.Insert("ReglStatus",			 RowData.ReglStatus);
		FillingData.Insert("NDDState",			 RowData.NDDState);
		
		FillingData.Insert("LineID",                CurRow);
		FillingData.Insert("ExpenseItem",          RowData.ExpenseItem);
		FillingData.Insert("DimensionOfExpenses",       RowData.DimensionOfExpenses);
		FillingData.Insert("Organization",             RowData.Organization);
		FillingData.Insert("Department",           RowData.Department);
		FillingData.Insert("LineOfBusiness", RowData.LineOfBusiness);
		
		ExpenseParameters.Add(FillingData);
				
	EndDo;
	
	Return ExpenseParameters;
	
EndFunction

&AtServerNoContext
Function GetCostItemAllocationSettings(ExpenseParameters, Organization, RegistrationPeriod)
	Return Documents.AllocationOfOtherCosts.GetCostItemAllocationSettings(ExpenseParameters, Organization, RegistrationPeriod);
EndFunction

&AtServerNoContext
Function BatchAccountingIsUsed(Period)
	Return CalculationOfCostCached.BatchAccountingVersion22(Period);
EndFunction
	

// Determine AIT usage.
// 
// Returns:
//  Boolean - True if FO Accounting is enabled.
&AtServerNoContext
Function DefineAITUsage()
	Return CalculationOfCostLocalization.GetFunctionalOptionAITAccounting();
EndFunction

&AtServer
Procedure FormItemsManagement()
	

	If DefineAITUsage() Then
		Items.ExpenseItemsNDDState.Visible = True;
	EndIf;
	
EndProcedure
	
#EndRegion

#EndRegion
