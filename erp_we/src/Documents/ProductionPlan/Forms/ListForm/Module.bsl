
#Region Variables

&AtClient
Var IdleHandlerParameters;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	List.Parameters.SetParameterValue("CurrentDate", CurrentSessionDate());
	CurrentOnly = True;
	RelevanceOfThePlan = New ValueList;
	RelevanceOfThePlan.Add(1);
	RelevanceOfThePlan.Add(2);
	CommonClientServer.SetDynamicListFilterItem(List, "RelevanceOfThePlan",  RelevanceOfThePlan, DataCompositionComparisonType.InList,, CurrentOnly);
	
	SetAvailabilityOfStatusSettingCommands();
	
	Fields = CommonClientServer.ValueInArray("StateOfProductionPlanCalculation");
	List.SetRestrictionsForUseInGroup(Fields);
	List.SetRestrictionsForUseInOrder(Fields);
	List.SetRestrictionsForUseInFilter(Fields);
	
	ToDoListOverridable.OnCreateAtServer(ThisForm, List);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);


	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	PlanReplacementControl_();
	AttachIdleHandler("PlanReplacementControl_", 3600);
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit = True Then
		OnCloseAtServer(JobID);
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Scenario  = Settings.Get("Scenario");
	Status = Settings.Get("Status");
	EmployeeResponsible = Settings.Get("EmployeeResponsible");
	CurrentOnly = Settings.Get("CurrentOnly");
	
	CommonClientServer.SetDynamicListFilterItem(List, "Scenario",  Scenario, DataCompositionComparisonType.Equal,, ValueIsFilled(Scenario));
	CommonClientServer.SetDynamicListFilterItem(List, "Status",  Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
	RelevanceOfThePlan = New ValueList;
	RelevanceOfThePlan.Add(1);
	RelevanceOfThePlan.Add(2);
	CommonClientServer.SetDynamicListFilterItem(List, "RelevanceOfThePlan",  RelevanceOfThePlan, DataCompositionComparisonType.InList,, CurrentOnly);
	
	ToDoListOverridable.BeforeLoadDataFromSettingsAtServer(ThisForm, Settings);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterScenarioOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Scenario",  Scenario, DataCompositionComparisonType.Equal,, ValueIsFilled(Scenario));
	
EndProcedure

&AtClient
Procedure FilterStatusOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Status",  Status, DataCompositionComparisonType.Equal,, ValueIsFilled(Status));
	
EndProcedure

&AtClient
Procedure FilterEmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible",  EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure FilterCurrentOnlyOnChange(Item)
	
	RelevanceOfThePlan = New ValueList;
	RelevanceOfThePlan.Add(1);
	RelevanceOfThePlan.Add(2);
	
	CommonClientServer.SetDynamicListFilterItem(List, "RelevanceOfThePlan",  RelevanceOfThePlan, DataCompositionComparisonType.InList,, CurrentOnly);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	StateCodes = Documents.ProductionPlan.ProductionPlanCalculationStatusCodes();
	
	Indicator = New Map;
	Indicator.Insert(StateCodes.NotCalculated,           0);
	Indicator.Insert(StateCodes.Calculated,             1);
	Indicator.Insert(StateCodes.AwaitingCalculation,        2);
	Indicator.Insert(StateCodes.Calculating,        2);
	Indicator.Insert(StateCodes.IsCancelled,            2);
	Indicator.Insert(StateCodes.NotCalculatedHasErrors, 3);

	ReferenceList = Rows.GetKeys();
	CalculationStates = Documents.ProductionPlan.StatesOfProductionPlanCalculation(ReferenceList);
	
	For Each Ref In ReferenceList Do
		
		CalculationState = CalculationStates[Ref];
		
		If  ( CalculationState.Code = StateCodes.NotCalculated
			Or CalculationState.Code = StateCodes.Calculated ) Then // the indicator is not displayed so as not to "clog" the list.
			IndexOf = 0;
		Else
			IndexOf = CalculationState.Code;
		EndIf;
		
		Rows[Ref].Data.StateOfProductionPlanCalculation = Indicator[IndexOf];
		
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure SetTheStatusInPreparation(Command)
	
	SetStatus("UnderPreparation", NStr("vi = 'Đang chuẩn bị';
										|ru = 'В подготовке';
										|en = 'Created'; fa = 'ایجادشده';
										|it = 'In preparazione';
										|pl = 'W przygotowaniu';
										|tr = 'Hazırlanma işleminde'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusOnApproval(Command)
	
	SetStatus("AwaitingConfirmation", NStr("vi = 'Đang làm việc';
											|ru = 'В работе';
											|en = 'In progress'; fa = 'در حال انجام';
											|it = 'In esecuzione';
											|pl = 'Wykonuje się';
											|tr = 'İşleniyor'"));
	
EndProcedure

&AtClient
Procedure SetTheConfirmedStatus(Command)
	
	SetStatus("Upholded", NStr("vi = 'Đã duyệt';
								|ru = 'Утвержден';
								|en = 'Confirmed'; fa = 'تأییدشده';
								|it = 'Confermato';
								|pl = 'Zatwierdzony';
								|tr = 'Onaylandı'"));
	
EndProcedure

&AtClient
Procedure SetTheStatusToCanceled(Command)
	
	SetStatus("RolledBack_", NStr("vi = 'Hủy bỏ';
									|ru = 'Отменен';
									|en = 'Canceled'; fa = 'لغوشده';
									|it = 'Annullato';
									|pl = 'Canceled';
									|tr = 'İptal edildi'"));
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure RecalculateProductionPlans(Command)
	
	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	If HighlightedLinks.Count() = 0 Then
		Return;
	EndIf;
	
	Result = RecalculateProductionPlansOnServer(HighlightedLinks);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription("RecalculateProductionPlansAlert", ThisObject);
	
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
	Items.List.Refresh();
	
EndProcedure

&AtClient
Procedure CancelPosting(Command)
	ReferencesArrray = Items.List.SelectedRows;
	CancelPlansOnServer(ReferencesArrray);
	Items.List.Refresh()
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAvailabilityOfStatusSettingCommands()
	
	AccessRightChangeProductionPlan = AccessRight("Update", Metadata.Documents.ProductionPlan);
	RightOfAccessApprovalOfProductionPlans = Users.RolesAvailable("ApprovalOfProductionPlans");
	
	Items.GroupSetStatus.Visible = AccessRightChangeProductionPlan;
	Items.ListSetTheConfirmedStatus.Visible = RightOfAccessApprovalOfProductionPlans;
	
EndProcedure

&AtClient
Procedure SetStatus(Status, TexStatus)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Trong các đơn hàng đã chọn từ danh sách sẽ đặt trạng thái ""%Status%"". Theo kế hoạch tiếp nhận vào thực hiện, có thể lập chứng từ. Tiếp tục?';
					|ru = 'У выделенных в списке планов будет установлен статус ""%Status%"". По принятым в работу планам могут быть оформлены документы. Продолжить?';
					|en = 'Plans selected in the list will have status ""%Status%"". Documents can be registered according to the plans accepted into operation. Continue?'; fa = 'Plans selected in the list will have status ""%Status%"". Documents can be registered according to the plans accepted into operation. Continue?';
					|it = 'Per i piani selezionati nell''elenco verrà impostato lo stato ""%Status%"". Per i piani accettati per l''esecuzione possono essere formalizzati i documenti. Continuare?';
					|pl = 'U zaznaczonych na liście planów zostanie zainstalowana status ""%Status%"". W przyjętych do pracy planach mogą być wystawione dokumenty. Kontynuować?';
					|tr = 'Listedeki seçili planlar ""%Status%"" durumuna ayarlanacak. Kabul edilen planlara göre belgeler düzenlenebilir olacak. Devam edilsin mi?'");
	QueryText = StrReplace(QueryText, "%Status%", TexStatus);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Status", Status);
	AdditionalParameters.Insert("TexStatus", TexStatus);
	AdditionalParameters.Insert("SelectedRows", SelectedRows);
	
	Notification = New CallbackDescription("SetStatusCompletion", ThisObject, AdditionalParameters);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure SetStatusCompletion(Result, AdditionalParameters) Export 
	
	If Result <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(
		AdditionalParameters.SelectedRows, 
		AdditionalParameters.Status);
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.List, 
		ProcessedItemsCount, 
		AdditionalParameters.SelectedRows.Count(), 
		AdditionalParameters.TexStatus);
	
EndProcedure

&AtServer
Function RecalculateProductionPlansOnServer(HighlightedLinks)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("References", HighlightedLinks);
	ParametersStructure.Insert("RunJob", True);
	
	JobDescription = NStr("vi = 'Đăng ký nhiệm vụ kể lại kế hoạch sản xuất';
							|ru = 'Регистрация заданий к пересчету планов производства';
							|en = 'Registration of jobs to recalculate production plans'; fa = 'Registration of jobs to recalculate production plans';
							|it = 'La registrazione dei task di ricalcolo dei piani di produzione';
							|pl = 'Rejestracja zadań do przeliczeń planów produkcji';
							|tr = 'Görev üretim planı yeniden sayımına kaydediliyor'");
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription = JobDescription;
		
	Result = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ProductionPlan.RecalculateProductionPlans",
		ParametersStructure,
		ExecutionParameters);
		
		JobID = Result.JobID;
		StorageAddress       = Result.ResultAddress;
	
	Return Result;
	
EndFunction

&AtClient
Procedure RecalculateProductionPlansAlert(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		
		UserMessages = BackgroundJobMessages(JobID);
		If UserMessages <> Undefined Then
			For Each BackgroundJobMessage In UserMessages Do
				BackgroundJobMessage.Message();
			EndDo;
		EndIf;
		Return;
		
	EndIf;
	
	If Result.Status = "Completed2" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function BackgroundJobMessages(JobID)
	
	UserMessages = New Array;
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob <> Undefined Then
		UserMessages = BackgroundJob.GetUserMessages();
	EndIf;
	
	Return UserMessages;
	
EndFunction

&AtServerNoContext
Procedure OnCloseAtServer(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtClient
Procedure PlanReplacementControl_()
	
	ControlReplacementOfPlansOnServer();
	
EndProcedure

&AtServerNoContext
Procedure ControlReplacementOfPlansOnServer()
	
	Planning.PlanReplacementControl_();
	
EndProcedure

&AtServerNoContext
Procedure CancelPlansOnServer(ReferencesArrray)
	
	Planning.CancelPlans(ReferencesArrray, "ProductionPlan");
	
EndProcedure

#EndRegion
