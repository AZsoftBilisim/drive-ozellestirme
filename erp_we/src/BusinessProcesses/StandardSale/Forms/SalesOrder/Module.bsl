
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
		|	SalesOrder.Ref
		|FROM
		|	Document.SalesOrder AS SalesOrder
		|WHERE
		|	(NOT SalesOrder.DeletionMark)
		|	AND SalesOrder.SalesOpportunity = &SalesOpportunity");
	Query.SetParameter("SalesOpportunity", Job.SubjectOf);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		OrderDocument = Selection.Ref;
		Items.DecorationCustomerSOrder.Title = OrderDocument;
	Else
		Items.DecorationCustomerSOrder.Title = NStr("vi = 'Tạo đơn hàng';
													|ru = 'Создать заказ';
													|en = 'Create order'; fa = 'Create order';
													|it = 'Creare un ordine';
													|pl = 'Utwórz zamówienie';
													|tr = 'Sipariş oluştur'");
	EndIf;

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	Var TransactionParameter;
	
	If EventName = "Write_SalesOrder"
		And Parameter.Property("SalesOpportunity", TransactionParameter) Then
		
		If TransactionParameter = Job.SubjectOf Then
			OrderDocument = Source;
			Items.DecorationCustomerSOrder.Title = Source;
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
Procedure Completed2Execute()

	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisForm,True,New Structure("SalesOpportunity",Object.SubjectOf));

EndProcedure

&AtClient
Procedure DecorationCustomerSOrderClick(Item)
	
	If ValueIsFilled(OrderDocument) Then
		ShowValue(Undefined, OrderDocument);
	Else
		OpeningParameters = New Structure;
		FillingData = New Structure;
		FillingData.Insert("SalesOpportunity", Object.SubjectOf);
		OpeningParameters.Insert("FillingValues", FillingData);
		OpenForm(
			"Document.SalesOrder.ObjectForm", OpeningParameters,,,,, Undefined, FormWindowOpeningMode.Independent);
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndCloseExecute()
	
	BusinessProcessesAndTasksClient.WriteAndCloseExecute(ThisForm);
	
EndProcedure

#EndRegion
