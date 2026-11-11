#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not DesignedForEmails And Not DesignedForSMSMessage Then
		
		ErrorText = NStr("vi = 'Chưa chỉ ra dạng gửi thông báo nào.';
						|ru = 'Не указан ни один вид доставки сообщений.';
						|en = 'No message delivery kind is specified.'; fa = 'No message delivery kind is specified.';
						|it = 'Non è specificato alcun tipo di consegna del messaggio.';
						|pl = 'Nie określono żadnego rodzaju dostarczania wiadomości.';
						|tr = 'Mesaj teslim türü belirtilmedi.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"DesignedForEmails",
			,
			Cancel);
		
	EndIf;
	
	If Not DesignedForSMSMessage Then
		NotCheckedAttributeArray.Add("SMSMessageTemplate");
	EndIf;
	
	If Not DesignedForEmails Then
		NotCheckedAttributeArray.Add("EmailTemplate");
	EndIf;
	
	If Not SendingConditionsAreUsed Then
		NotCheckedAttributeArray.Add("SendingCondition");
	EndIf;
		

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	ScheduledJobsServer.DeleteJob(ScheduledJob);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// Creating a routine task (obtaining a unique identifier)
	SetPrivilegedMode(True);
	
	If SendingConditionsAreUsed Then
		
		FillInConditionParameters(ConditionParameters, SendingCondition);
		
	Else
		
		SendingCondition = "";
		ConditionParameters.Clear();
		
	EndIf;
	
	If AdditionalProperties.Property("Schedule") And AdditionalProperties.Property("Use") Then
		
		Job = ScheduledJobsServer.Job(ScheduledJob);
		If Job = Undefined  Then
			
			JobParameters = New Structure;
			JobParameters.Insert("Metadata", Metadata.ScheduledJobs.DataAnalysisForNotificationsToCustomers);
			JobParameters.Insert("Use", False);
			JobParameters.Insert("Description", ScheduledJobDescription());
			Job = ScheduledJobsServer.AddJob(JobParameters);
			
			ScheduledJob = ScheduledJobsServer.UUID(Job);
			
		EndIf;
		
		AdditionalProperties.Insert("Job",Job);
		
	ElsIf AdditionalProperties.Property("RemovalScheduledJob") Then
		
		ScheduledJobsServer.DeleteJob(ScheduledJob);
		ScheduledJob = Undefined;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RecordRoutineTask();
	
	RefreshReusableValues();
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	ScheduledJob = Undefined;
	
EndProcedure

#EndRegion

#Region Private

Procedure RecordRoutineTask()

	If Not AdditionalProperties.Property("Job") Then
		Return;
	EndIf;
	
	Job = AdditionalProperties.Job;
	If Job = Undefined Then
		Return;
	EndIf;
	
	JobParameters = New Structure;
	
	// The schedule is set in the form of an element
	If AdditionalProperties.Property("Schedule") 
			And TypeOf(AdditionalProperties.Schedule) = Type("JobSchedule")
			And String(AdditionalProperties.Schedule) <> String(Job.Schedule) Then
			
		JobParameters.Insert("Schedule", AdditionalProperties.Schedule);
		
	EndIf;
	
	// Usage is set in the form of an element
	If DeletionMark And Job.Use Then
		
		JobParameters.Insert("Use", False);
		
	ElsIf AdditionalProperties.Property("Use") 
		And AdditionalProperties.Use <> Job.Use Then
		
		JobParameters.Insert("Use", AdditionalProperties.Use);
		
	EndIf;

	JobDescription = ScheduledJobDescription();
	JobParameters.Insert("Description", JobDescription);
	
	Parameters = New Array;
	Parameters.Add(Ref);
	JobParameters.Insert("Parameters", Parameters);
	
	SetPrivilegedMode(True);
	ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
	
EndProcedure

Function ScheduledJobDescription()

	Return NStr("vi = 'Phân tích dữ liệu đối với dạng thông báo';
				|ru = 'Анализ данных для вида оповещений';
				|en = 'Analysis of data for notification kind'; fa = 'Analysis of data for notification kind';
				|it = 'Analisi dei dati per il tipo di avvisi';
				|pl = 'Analiza danych dla rodzaju powiadomień';
				|tr = 'Uyarı türü için verilerin analizi'") + ": " + TrimAll(Description);

EndFunction 

Procedure FillInConditionParameters(ConditionParameters, SendingCondition)
	
	ConditionParameters.Clear();
	
	ParametersOfSendingCondition = New Structure;
	ParametersOfSendingCondition.Insert("TemplateType", "SMS");
	ParametersOfSendingCondition.Insert("Text", SendingCondition);
	MatchingConditionParameters = MessageTemplatesInternal.ParametersFromMessageText(ParametersOfSendingCondition);
	
	ParametersOfPreviousMessage = MatchingConditionParameters.Get("PreviousMessage");
	If ParametersOfPreviousMessage <> Undefined Then
		For Each Parameter In ParametersOfPreviousMessage Do
			NewRow = ConditionParameters.Add();
			NewRow.ThisIsAPreviousMessageParameter = True;
			NewRow.ParameterName = Parameter.Key;
		EndDo;
	EndIf;
	ParametersOfPreviousMessage = MatchingConditionParameters.Get("CurMessage");
	If ParametersOfPreviousMessage <> Undefined Then
		For Each Parameter In ParametersOfPreviousMessage Do
			NewRow = ConditionParameters.Add();
			NewRow.ThisIsAPreviousMessageParameter = False;
			NewRow.ParameterName = Parameter.Key;
		EndDo;
	EndIf;
	
EndProcedure;

#EndRegion

#EndIf