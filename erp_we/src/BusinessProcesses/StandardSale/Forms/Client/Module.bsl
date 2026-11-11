
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InitialExecutionFlag = Object.Executed;
	TaskObject = FormAttributeToValue("Object");
	JobObject = TaskObject.BusinessProcess.GetObject();
	ValueToFormAttribute(JobObject, "Job");

	ToUseTermsOfSales   = GetFunctionalOption("ToUseTermsOfSales");

	UseDateAndTimeInTaskDeadlines = GetFunctionalOption("UseDateAndTimeInTaskDeadlines");
	Items.DueDateTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.ExecutionStartDateScheduledTime.Visible = UseDateAndTimeInTaskDeadlines;
	Items.CompletionDate.Format = ?(UseDateAndTimeInTaskDeadlines, "DLF=DT", "DLF=D");

	BusinessProcessesAndTasksServer.TaskFormOnCreateAtServer(
		ThisForm, Object, Items.StateGroup, Items.CompletionDate);
	
	TransactionDetails_ = Common.ObjectAttributesValues(Job.SubjectOf,New Structure("Partner,CustomerTermsOfSales"));
	
	Client = TransactionDetails_.Partner;
	Terms = TransactionDetails_.CustomerTermsOfSales;
	
	SetClientCommandHeader();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SalesOpportunitiesToCustomer" Then
		
		If Parameter.Property("Partner") Then
			Client = Parameter.Partner;
		EndIf;
		
		If Parameter.Property("CustomerTermsOfSales") Then
			Terms = Parameter.CustomerTermsOfSales;
		EndIf;
		
	EndIf;
	
	SetClientCommandHeader();
	
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
Procedure Client(Command)

	If ValueIsFilled(Client) 
		And (Not ToUseTermsOfSales Or ValueIsFilled(Terms)) Then
	
		ShowValue(Undefined, Client);
	
	Else
	
		OpenForm("Catalog.SalesOpportunitiesToCustomer.Form.ItemForm",
		             New Structure("Key,NotificationRequired",Job.SubjectOf,True));
	
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetClientCommandHeader()

	If Not ValueIsFilled(Client) Then
		
		Items.CommandClient.Title = NStr("vi = 'Chỉ ra khách hàng và thỏa thuận';
										|ru = 'Указать клиента и соглашение';
										|en = 'Specify customer and agreement'; fa = 'Specify customer and agreement';
										|it = 'Specificare cliente e accordo';
										|pl = 'Wskaż klienta i uzgadnianie';
										|tr = 'Müşteriyi ve anlaşmayı belirt'");
		
	ElsIf ToUseTermsOfSales And Not ValueIsFilled(Terms) Then
		
		Items.CommandClient.Title = NStr("vi = 'Chỉ ra thỏa thuận';
										|ru = 'Указать соглашение';
										|en = 'Specify agreement'; fa = 'Specify agreement';
										|it = 'Specificare accordo';
										|pl = 'Wskaż umowę';
										|tr = 'Anlaşmayı belirt'");
		
	Else
		
		Items.CommandClient.Title = Client;
		
	EndIf;
	
EndProcedure

#EndRegion
