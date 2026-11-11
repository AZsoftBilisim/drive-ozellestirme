#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ID") Then
		SubjectOfID = Parameters.ID;
		SubjectOfType = Parameters.type;
	EndIf;
	
	// issues of completing tasks
	If IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("1.2.7.3")
			And Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("3.0.1.1") Then
		ListQuestions();
	Else
		DataProcessors.IntegrationWith1CDocumentManagement.ProcessFormIfServiceVersionFunctionalityIsUnavailable(ThisObject);
		Items.Questions.Visible = False;
		Items.QuestionsDescription.Visible = False;
	EndIf;
	
	If Not IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1.CORP") Then
		Items.QuestionsTypeOfQuestion.Visible = False;
		Items.ListOfQuestionsGroupTiming.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If (EventName = "Recording_1CDocumentManagementTask"
			Or EventName = "Recording_1CDocumentManagementBusinessProcess") And Source = ThisObject Then
		ListQuestions();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQuestions

&AtClient
Procedure QuestionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	Process_ = Items.Questions.CurrentData;
	
	If Process_ <> Undefined Then
		IntegrationWith1CDocumentManagementCoreClient.OpenObject(Process_.DoQueryBoxType, Process_.DoQueryBoxID, ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Refresh(Command)
	
	Modified = False;
	ListQuestions();
	
EndProcedure

&AtClient
Procedure FindExecute(Command)
	
	Modified = False;
	FormParameters = New Structure("SearchString",SearchString);
	Notification = New CallbackDescription("FindExecuteCompletion", ThisObject);
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SearchInList", FormParameters, ThisObject,,,, Notification);
	
EndProcedure

&AtClient
Procedure FindExecuteCompletion(Result, NotificationParameters) Export
	
	If TypeOf(Result) = Type("String") Then
		SearchString = Result;
		ListQuestions();
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelSearch(Command)
	
	// canceling the search mode
	Modified = False;
	SearchString = "";
	ListQuestions();
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	Modified = False;
	FormParameters = New Structure;
	FormParameters.Insert("ID", SubjectOfID);
	FormParameters.Insert("type", SubjectOfType);
	FormParameters.Insert("TypeOfQuestion", NStr("vi = 'Khác';
												|ru = 'Иное';
												|en = 'Other'; fa = 'سایر';
												|it = 'Altro';
												|pl = 'Other';
												|tr = 'Diğer'"));
	FormParameters.Insert("TypeOfQuestionID", "Иное"); //@NON-NLS-2
	
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement.Form.BusinessProcessIssueSolvingNewQuestion",
		FormParameters, ThisObject, SubjectOfID);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ListQuestions()
	
	Proxy = IntegrationWith1CDocumentManagementCoreCached.GetProxy();
	
	Conditions = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListQuery");
	ListOfSelectionConditions = Conditions.conditions; // XDTOList
	
	Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
	Condition.property = "target";
	Condition.value = IntegrationWith1CDocumentManagementCore.CreateObjectID(Proxy, SubjectOfID, SubjectOfType);
	ListOfSelectionConditions.Add(Condition);
	
	If ValueIsFilled(SearchString) Then
		Condition = IntegrationWith1CDocumentManagementCore.CreateObject(Proxy, "DMObjectListCondition");
		Condition.property = "name";
		Condition.value = SearchString;
		ListOfSelectionConditions.Add(Condition);
	EndIf;
	
	Response = IntegrationWith1CDocumentManagementCore.FindListOfObjects(
		Proxy,
		"DMBusinessProcessIssuesSolution",
		Conditions);
	
	Questions.Clear();
	For Each DoQueryBox In Response.items Do
		
		BusinessProcess = DoQueryBox.object;
		QuestionRow = Questions.Add();
		IntegrationWith1CDocumentManagementCore.FillInObjectDetails(QuestionRow, BusinessProcess, "DoQueryBox");
		QuestionRow.DoQueryBox = BusinessProcess.description;
		If IntegrationWith1CDocumentManagementCore.PropertySet(BusinessProcess, "issueType") Then
			QuestionRow.TypeOfQuestion = BusinessProcess.issueType.name;
		ElsIf IntegrationWith1CDocumentManagementCoreCached.FunctionalityOfServiceVersionIsAvailable("2.1.18.1") Then
			QuestionRow.TypeOfQuestion = NStr("vi = 'Khác';
												|ru = 'Иное';
												|en = 'Other'; fa = 'سایر';
												|it = 'Altro';
												|pl = 'Other';
												|tr = 'Diğer'");
		EndIf;
		QuestionRow.Date = BusinessProcess.beginDate;
		QuestionRow.LongDesc = BusinessProcess.perfomanceHistory;
		QuestionRow.Author = BusinessProcess.author.name;
		If IntegrationWith1CDocumentManagementCore.PropertySet(BusinessProcess, "completionMark") Then
			QuestionRow.Picture = IntegrationWith1CDocumentManagement.IndexOfCompletionTagImage(
				BusinessProcess.completionMark);
		EndIf;
		If IntegrationWith1CDocumentManagementCore.PropertySet(BusinessProcess, "initiator") Then
			QuestionRow.Whom = BusinessProcess.initiator.name;
		EndIf;
		If QuestionRow.TypeOfQuestion = NStr("vi = 'Gia hạn';
											|ru = 'Перенос срока';
											|en = 'Postponement'; fa = 'Postponement';
											|it = 'Spostamento termine';
											|pl = 'Przeniesienie terminu';
											|tr = 'Tarihin ertelenmesi'") Then
			QuestionRow.TitleNewDate = NStr("vi = 'Thời hạn mới:';
											|ru = 'Новый срок:';
											|en = 'New due date:'; fa = 'New due date:';
											|it = 'Nuovo termine:';
											|pl = 'Nowy termin:';
											|tr = 'Yeni süre:'");
			QuestionRow.TitlePreviousDate = NStr("vi = 'Thời hạn cũ:';
												|ru = 'Старый срок:';
												|en = 'Old due date:'; fa = 'Old due date:';
												|it = 'Termine precedente:';
												|pl = 'Stary termin:';
												|tr = 'Eski süre:'");
			If IntegrationWith1CDocumentManagementCore.PropertySet(BusinessProcess, "newDueDate") Then
				QuestionRow.NewTerm = BusinessProcess.newDueDate;
			EndIf;
			If IntegrationWith1CDocumentManagementCore.PropertySet(BusinessProcess, "oldDueDate") Then
				QuestionRow.OldDeadline = BusinessProcess.oldDueDate;
			Else
				QuestionRow.OldDeadline = BusinessProcess.issueTask.dueDate;
			EndIf;
		EndIf;
		
	EndDo;
	
	Questions.Sort("Date DESC");
	
EndProcedure

#EndRegion
