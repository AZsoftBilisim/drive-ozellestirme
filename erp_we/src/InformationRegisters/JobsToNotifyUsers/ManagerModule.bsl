#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Adds tasks to the information register "Tasks to notify users".
// 
// Parameters:
//  NotificationSource - AnyRef, Array of AnyRef - link-the source of the task or an array of links to be reflected.
//  NotificationKinds - Array of CatalogRef.UserNotificationKinds - array of reflected types of alerts by source.
//  NotificationInitiator - CatalogRef.Users, Undefined - the user is the initiator of the notification.
//  TaskTable - See DeferredJobs.AddTasksToQueue.TaskTable
//
Procedure AddTasksToReflection(NotificationSource, NotificationKinds, NotificationInitiator = Undefined, TaskTable = Undefined) Export
	
	SetPrivilegedMode(True);
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("NotificationSource", Common.AllRefsTypeDetails());
	DataTable.Columns.Add("NotificationKind", New TypeDescription("CatalogRef.UserNotificationKinds"));
	DataTable.Columns.Add("NotificationInitiator", New TypeDescription("CatalogRef.Users"));
	
	If TypeOf(NotificationSource) = Type("Array") Then
		ArrayOfSources = NotificationSource;
	Else
		ArrayOfSources = New Array;
		ArrayOfSources.Add(NotificationSource);
	EndIf;
	
	For Each Source In ArrayOfSources Do
		For Each NotificationKind In NotificationKinds Do
			NewRow = DataTable.Add();
			NewRow.NotificationSource = Source;
			NewRow.NotificationKind = NotificationKind;
			NewRow.NotificationInitiator = NotificationInitiator;
		EndDo;
	EndDo;
	
	Query = New Query;
	Query.Text = "SELECT
	|	DataTable.NotificationSource AS NotificationSource,
	|	DataTable.NotificationKind AS NotificationKind,
	|	DataTable.NotificationInitiator AS NotificationInitiator
	|INTO DataTable
	|FROM
	|	&DataTable AS DataTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataTable.NotificationSource AS NotificationSource,
	|	DataTable.NotificationKind AS NotificationKind,
	|	DataTable.NotificationInitiator AS NotificationInitiator
	|FROM
	|	DataTable AS DataTable
	|		LEFT JOIN InformationRegister.JobsToNotifyUsers AS JobsToNotifyUsers
	|		ON DataTable.NotificationSource = JobsToNotifyUsers.NotificationSource
	|			AND DataTable.NotificationKind = JobsToNotifyUsers.NotificationKind
	|			AND DataTable.NotificationInitiator = JobsToNotifyUsers.NotificationInitiator
	|WHERE
	|	JobsToNotifyUsers.NotificationSource IS NULL";
	
	Query.SetParameter("DataTable", DataTable);
	DataTable = Query.Execute().Unload();
	
	DeferredJobs.AddTasksToQueue(NameOfTaskQueue(), DataTable,,TaskTable);
	
EndProcedure

// Name of the task queue for notifying users.
//
// Returns:
//  String - Name of the task queue.
Function NameOfTaskQueue() Export
	
	Return "JobsToNotifyUsers";
	
EndFunction

#EndRegion

#EndIf