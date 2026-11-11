
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
Procedure DecorationTransactionDocumentsClick(Item)
	
	StructureFilter = New Structure("SalesOpportunity", Object.SubjectOf);
	
	FormParameters = New Structure(
			"Filter, SettingsKey, GenerateOnOpen",
			StructureFilter,
			"SalesOpportunity",
			True);

	OpenForm("DataProcessor.PartnerAndSalesOpportunityDocuments.Form.SalesOpportunityDocuments",
			FormParameters,
			ThisObject);
	
EndProcedure

#EndRegion
