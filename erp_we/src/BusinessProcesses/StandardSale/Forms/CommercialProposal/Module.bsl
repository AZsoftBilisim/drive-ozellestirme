
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

	Query = New Query(
		"SELECT ALLOWED
		|	CommercialProposalForCustomer.Ref
		|FROM
		|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
		|WHERE
		|	(NOT CommercialProposalForCustomer.DeletionMark)
		|	AND CommercialProposalForCustomer.SalesOpportunity = &SalesOpportunity");
	Query.SetParameter("SalesOpportunity", Job.SubjectOf);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		CommercialProposal = Selection.Ref;
		Items.KP.Title   = CommercialProposal;
	Else
		Items.KP.Title = NStr("vi = 'Tạo báo giá';
								|ru = 'Создать коммерческое предложение';
								|en = 'Create sales quotation'; fa = 'ایجاد پیش‌فاکتور فروش';
								|it = 'Creare offerta commerciale';
								|pl = 'Utwórz ofertę handlową';
								|tr = 'Satış teklifini oluştur'");
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CommercialOfferToClient__"
		And TypeOf(Source) = Type("DocumentRef.CommercialProposalForCustomer") Then
		
		If Job.SubjectOf = CommercialOfferTransaction(Source) Then
			
			CommercialProposal = Source;
			Items.KP.Title   = Source;

		EndIf;
		
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

&AtClient
Procedure CommercialProposal(Command)

	If ValueIsFilled(CommercialProposal) Then
		ShowValue(Undefined, CommercialProposal);
	Else
		OpenForm(
			"Document.CommercialProposalForCustomer.ObjectForm",
			New Structure("Basis", Job.SubjectOf),,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Function CommercialOfferTransaction(CommercialProposal) 
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text = "SELECT
	|	CommercialProposalForCustomer.SalesOpportunity AS SalesOpportunity
	|FROM
	|	Document.CommercialProposalForCustomer AS CommercialProposalForCustomer
	|WHERE
	|	CommercialProposalForCustomer.Ref = &Ref";
	
	Query.SetParameter("Ref", CommercialProposal);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.SalesOpportunity;
	
EndFunction

#EndRegion
