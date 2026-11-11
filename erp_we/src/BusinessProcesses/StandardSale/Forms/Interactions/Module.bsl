
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InitialExecutionFlag = Object.Executed;
	TaskObject = FormAttributeToValue("Object");
	JobObject = TaskObject.BusinessProcess.GetObject();
	ValueToFormAttribute(JobObject, "Job");

	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.DueDateTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.ExecutionStartDateScheduledTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.CompletionDate.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");

	BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(
		ThisForm, Object, Items.StateGroup, Items.CompletionDate);
	
	RightToViewInteractions = AccessRight("View", Metadata.DocumentJournals.Interactions);
	SetDecorationTextNumberOfInteractions(ThisObject);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If InteractionsClientServer.IsInteraction(Source) And Parameter.SubjectOf = Job.SubjectOf Then
		
		SetDecorationTextNumberOfInteractions(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndCloseExecute()

	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisForm);

EndProcedure

&AtClient
Procedure Completed2Execute()

	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisForm,True,New Structure("SalesOpportunity",Object.SubjectOf));

EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetDecorationTextNumberOfInteractions(Form)
	
	If Form.RightToViewInteractions Then
		
		NumberOfInteractions = NumberOfInteractions(Form.Job.SubjectOf);
		InfoText = StrTemplate(NStr("vi = 'Giao tiếp ( %1)';
									|ru = 'Взаимодействия (%1)';
									|en = 'Interactions (%1)'; fa = 'Interactions (%1)';
									|it = 'Interazioni (%1)';
									|pl = 'Interakcje (%1)';
									|tr = 'İş etkileşimleri (%1)'"), String(NumberOfInteractions));
		
	Else
		
		InfoText = NStr("vi = 'Không có quyền xem các giao tiếp';
						|ru = 'Нет прав для просмотра взаимодействий';
						|en = 'No rights to view interactions'; fa = 'No rights to view interactions';
						|it = 'Nessun diritto di visualizzare le interazioni';
						|pl = 'Brak uprawnień do przeglądania interakcji';
						|tr = 'Etkileşim görüntüleme için yetki mevcut değil'");
		
	EndIf;
	
	Form.Items.InteractionDecoration.Title = InfoText;
	
EndProcedure

&AtServerNoContext
Function NumberOfInteractions(SalesOpportunity)

	If Not AccessRight("Read",Metadata.DocumentJournals.Interactions) Then
		Return 0;
	EndIf;
	
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(*) AS NumberOfInteractions
		|FROM
		|	DocumentJournal.Interactions AS Interactions
		|		INNER JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
		|		ON Interactions.Ref = InteractionsFolderSubjects.Interaction
		|WHERE
		|	(NOT Interactions.DeletionMark)
		|	AND VALUETYPE(Interactions.Ref) <> TYPE(Document.PlannedInteraction)
		|	AND InteractionsFolderSubjects.SubjectOf = &SubjectOf");
	Query.SetParameter("SubjectOf", SalesOpportunity);
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection.NumberOfInteractions;

EndFunction

&AtClient
Procedure InteractionDecorationClick(Item)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("SubjectOf", Object.SubjectOf);
		
	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterStructure1);
	FormParameters.Insert("InteractionType", "SubjectOf");
	
	OpenForm(
		"DocumentJournal.Interactions.Form.ParametricListForm",
		FormParameters,
		ThisObject,
		ThisObject.UniqueKey);
	
EndProcedure

#EndRegion
