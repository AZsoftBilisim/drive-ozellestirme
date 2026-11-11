///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then 
		Return;
	ElsIf IsFolder Then 
		Personal = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
		Return;
	EndIf;
	
	// Create a scheduled dummy job (to store its ID in the data).
	SetPrivilegedMode(True);
	
	ScheduledJobsServer.BlockARoutineTask(ScheduledJob);

	Job = ScheduledJobsServer.Job(ScheduledJob);
	If Job = Undefined Then
		
		JobParameters = New Structure();
		JobParameters.Insert("Metadata", Metadata.ScheduledJobs.ReportMailing);
		JobParameters.Insert("MethodName", Metadata.ScheduledJobs.ReportMailing.MethodName);
		JobParameters.Insert("UserName", ReportMailing.IBUserName(Author));
		JobParameters.Insert("Use", False);
		JobParameters.Insert("Description", JobByMailingPresentation(Description));
 		Job = ScheduledJobsServer.AddJob(JobParameters);
		
		ScheduledJob = ScheduledJobsServer.UUID(Job);
		ScheduledJobsServer.BlockARoutineTask(ScheduledJob);
	EndIf;

	SetPrivilegedMode(False);
	
	// Mapping of the mailing and job readiness flag to the mailing deletion mark.
	If DeletionMark And IsPrepared Then
		IsPrepared = False;
	EndIf;
	
	// A map between groups and personal email distribution flag.
	// User checks, which provide hard links, are placed on the item form.
	// 
	GroupIncludedIntoPersonalDistributionHierarchy = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
	If Personal <> GroupIncludedIntoPersonalDistributionHierarchy Then
		Parent = ?(Personal, Catalogs.ReportMailings.PersonalMailings, Catalogs.ReportMailings.EmptyRef());
	EndIf;
EndProcedure

Procedure BeforeDelete(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	If ValueIsFilled(ScheduledJob) Then
		SetPrivilegedMode(True);
		ScheduledJobsServer.DeleteJob(ScheduledJob);
		SetPrivilegedMode(False);
	EndIf;
	
	Common.DeleteDataFromSecureStorage(Ref);
EndProcedure

Procedure OnCopy(CopiedObject)
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	ScheduledJob = Undefined;
EndProcedure

Procedure OnWrite(Cancel)
	// Called right after writing the object to the database.
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	Job = ScheduledJobsServer.Job(ScheduledJob);	
	If Job <> Undefined Then
		Changes = New Structure;
		
		EnableJob = ExecuteOnSchedule And IsPrepared;
		If Job.Use <> EnableJob Then
			Changes.Insert("Use", EnableJob);
		EndIf;
		
		// Schedule is set in the item form.
		If AdditionalProperties.Property("Schedule") 
			And TypeOf(AdditionalProperties.Schedule) = Type("JobSchedule")
			And String(AdditionalProperties.Schedule) <> String(Job.Schedule) Then
			Changes.Insert("Schedule", AdditionalProperties.Schedule);
		EndIf;
		
		UserName = ReportMailing.IBUserName(Author);
		If Job.UserName <> UserName Then
			Changes.Insert("UserName", UserName);
		EndIf;
		
		If TypeOf(Job) = Type("ScheduledJob") Then
			JobDescription = JobByMailingPresentation(Description);
			If Job.Description <> JobDescription Then
				Changes.Insert("Description", JobDescription);
			EndIf;
		EndIf;
		
		If Job.Parameters.Count() <> 1 Or Job.Parameters[0] <> Ref Then
			JobParameters = New Array;
			JobParameters.Add(Ref);
			Changes.Insert("Parameters", JobParameters);
		EndIf;
			
		If Changes.Count() > 0 Then
			ScheduledJobsServer.ChangeJob(ScheduledJob, Changes);
		EndIf;
	EndIf;
	SetPrivilegedMode(False);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes) 
	
	If IsFolder Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Author) Then 
		Cancel = True;
		Common.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Người chịu trách nhiệm"".';
				|ru = 'Поле ""Ответственный"" не заполнено.';
				|en = 'The ""Person responsible"" field is required.'; fa = 'The ""Person responsible"" field is required.';
				|it = 'Поле ""Ответственный"" не заполнено.';
				|pl = 'The ""Person responsible"" field is required.';
				|tr = '""Sorumlu"" alanı doldurulmadı.'"), ThisObject, "Author",, Cancel);
	EndIf;
		
	GroupIncludedIntoPersonalDistributionHierarchy = ReportMailing.IsMemberOfPersonalReportGroup(Parent);
		
	If Not Personal And Not Personalized And GroupIncludedIntoPersonalDistributionHierarchy Then
		Cancel = True;
		Common.MessageToUser(
			NStr("vi = 'Để gửi hàng loạt báo cáo ""Báo cáo cho người nhận chỉ định"" không thể chỉ định nhóm trong ""Gửi riêng"".';
				|ru = 'Для рассылок отчетов ""Отчеты указанным получателям"" нельзя указывать группу, входящую в ""Личные рассылки"".';
				|en = 'You cannot specify a group included in ""Personal distributions"" for the ""Reports to specified recipients"" distributions.'; fa = 'You cannot specify a group included in ""Personal distributions"" for the ""Reports to specified recipients"" distributions.';
				|it = 'Для рассылок отчетов ""Отчеты указанным получателям"" нельзя указывать группу, входящую в ""Личные рассылки"".';
				|pl = 'You cannot specify a group included in ""Personal distributions"" for the ""Reports to specified recipients"" distributions.';
				|tr = '""Belirtilen alıcılara raporlar"" bülten raporları için ""Kişisel bültenlere"" dahil edilen grubu belirtemezsiniz.'"), ThisObject, "Parent",, Cancel);
	ElsIf Not Personal And Personalized And GroupIncludedIntoPersonalDistributionHierarchy Then
		Cancel = True;
		Common.MessageToUser(
			NStr("vi = 'Để gửi hàng loạt báo cáo ""Báo cáo riêng cho mỗi người nhận"" không thể chỉ định nhóm trong ""Gửi riêng"".';
				|ru = 'Для рассылок отчетов ""Свой отчет для каждого получателя"" нельзя указывать группу, входящую в ""Личные рассылки"".';
				|en = 'You cannot specify a group included in ""Personal distributions"" for the ""Individual report for each recipient"" distributions.'; fa = 'You cannot specify a group included in ""Personal distributions"" for the ""Individual report for each recipient"" distributions.';
				|it = 'Для рассылок отчетов ""Свой отчет для каждого получателя"" нельзя указывать группу, входящую в ""Личные рассылки"".';
				|pl = 'You cannot specify a group included in ""Personal distributions"" for the ""Individual report for each recipient"" distributions.';
				|tr = '""Her alıcıya özel rapor"" rapor bültenleri için ""Kişisel bültenlerin"" parçası olan bir grup belirtemezsiniz.'"), ThisObject, "Parent",, Cancel);
	ElsIf Personal And Not GroupIncludedIntoPersonalDistributionHierarchy  Then
		Cancel = True;
		Common.MessageToUser(
			NStr("vi = 'Để gửi riêng báo cáo, hãy chỉ định nhóm ""Gửi riêng"" hoặc phân nhóm.';
				|ru = 'Для личных рассылок отчетов укажите группу ""Личные рассылки"" или ее подгруппу.';
				|en = 'Specify a ""Personal distributions"" group or its subgroup for personal report distributions.'; fa = 'Specify a ""Personal distributions"" group or its subgroup for personal report distributions.';
				|it = 'Для личных рассылок отчетов укажите группу ""Личные рассылки"" или ее подгруппу.';
				|pl = 'Specify a ""Personal distributions"" group or its subgroup for personal report distributions.';
				|tr = 'Kişisel rapor bültenleri için ""Kişisel bültenler"" grubunu veya alt grubunu belirtin.'"), ThisObject, "Parent",, Cancel);
	EndIf;

EndProcedure

#EndRegion

#Region Private

Function JobByMailingPresentation(MailingDescription)
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Gửi báo cáo hàng loạt: %1';
																		|ru = 'Рассылка отчетов: %1';
																		|en = 'Report distribution: %1'; fa = 'Report distribution: %1';
																		|it = 'Invio di report: %1';
																		|pl = 'Wysyłanie raportów: %1';
																		|tr = 'Rapor bülteni:%1'"), TrimAll(MailingDescription));
EndFunction

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf