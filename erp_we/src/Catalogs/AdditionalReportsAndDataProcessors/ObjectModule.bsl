///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#If Not MobileStandaloneServer Then

#Region Variables

Var IsGlobalDataProcessor;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If IsFolder Then
		Return;
	EndIf;
	
	ItemCheck = True;
	If AdditionalProperties.Property("ListCheck") Then
		ItemCheck = False;
	EndIf;
	
	If Not AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind) Then
		If Not UseForObjectForm And Not UseForListForm 
			And Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff Then
			Common.MessageToUser(
				NStr("vi = 'Hãy vô hiệu hóa đăng tải hoặc chọn ít nhất một biểu mẫu để sử dụng.';
					|ru = 'Отключите публикацию или выберите для использования как минимум одну из форм.';
					|en = 'Disable publication or select at least one of the forms to use.'; fa = 'Disable publication or select at least one of the forms to use.';
					|it = 'Отключите публикацию или выберите для использования как минимум одну из форм.';
					|pl = 'Disable publication or select at least one of the forms to use.';
					|tr = 'Göndermeyi devre dışı bırakın veya kullanılacak formlardan en az birini seçin'"),,, 
				"Object.UseForObjectForm", Cancel);
		EndIf;
	EndIf;
	
	// If the report is published, the name used to register the additional report 
	//     must be checked for uniqueness.
	If Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used Then
		
		// Check name.
		QueryText =
		"SELECT TOP 1
		|	1
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReports
		|WHERE
		|	AdditionalReports.ObjectName = &ObjectName
		|	AND &AdditReportCondition
		|	AND AdditionalReports.Publication = VALUE(Enum.AdditionalReportsAndDataProcessorsPublicationOptions.Used)
		|	AND AdditionalReports.DeletionMark = FALSE
		|	AND AdditionalReports.Ref <> &Ref";
		
		AddlReportsKinds = New Array;
		AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
		AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
		
		If AddlReportsKinds.Find(Kind) <> Undefined Then
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "AdditionalReports.Kind IN (&AddlReportsKinds)");
		Else
			QueryText = StrReplace(QueryText, "&AdditReportCondition", "NOT AdditionalReports.Kind IN (&AddlReportsKinds)");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("ObjectName",     ObjectName);
		Query.SetParameter("AddlReportsKinds", AddlReportsKinds);
		Query.SetParameter("Ref",         Ref);
		Query.Text = QueryText;
		
		SetPrivilegedMode(True);
		Conflicting = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		If Conflicting.Count() > 0 Then
			Cancel = True;
			If ItemCheck Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tên ""%1"" được dùng cho báo cáo (bộ xử lý) này đã bị chiếm bởi báo cáo (bộ xử lý) bổ sung đã đăng tải khác. 
					|
					|Để tiếp tục, hãy thay đổi dạng Đăng tải từ ""%2"" sang ""%3"" hoặc ""%4"".';
					|ru = 'Имя ""%1"", используемое данным отчетом (обработкой), уже занято другим опубликованным дополнительным отчетом (обработкой). 
					|
					|Для продолжения измените вид Публикации с ""%2"" на ""%3"" или ""%4"".';
					|en = 'The %1 report or data processor name is not unique.
					|
					|To continue, change the Publication type from ""%2"" to ""%3"" or ""%4"".'; fa = 'The %1 report or data processor name is not unique.
					|
					|To continue, change the Publication type from ""%2"" to ""%3"" or ""%4"".';
					|it = 'Il nome ""%1"", utilizzabile da questo report (elaborazione), è già utilizzato da un altro report pubblicabile aggiuntivo (elaborazione).
					|
					|Per continuare, modificare il tipo Pubblicazione da ""%2"" in ""%3"" o ""%4"".';
					|pl = 'Nazwa ""%1"", wykorzystywana przez dany raport (przetwarzanie) jest już zajęta przez inny opublikowany raport (przetwarzanie). 
					|
					|Aby kontynuować, zmień rodzaj Publikacji z ""%2"" na ""%3"" lub ""%4"".';
					|tr = 'Bu rapor (işleme) tarafından kullanılan ""%1"" adı, yayınlanmış başka bir ek rapor (işleme) tarafından zaten alınmıştır.
					|
					|Devam etmek için Gönderi türünü ""%2"" yerine ""%3"" veya ""%4"" olarak değiştirin.'"),
					ObjectName,
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode),
					String(Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff));
			Else
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Tên ""%1"" được dùng cho báo cáo (bộ xử lý) ""%2"" đã bị chiếm bởi báo cáo (bộ xử lý) bổ sung đã đăng tải khác.';
						|ru = 'Имя ""%1"", используемое отчетом (обработкой) ""%2"", уже занято другим опубликованным дополнительным отчетом (обработкой).';
						|en = 'The name %1 of the %2 report or data processor is not unique. The same name is assigned to another report or data processor.'; fa = 'The name %1 of the %2 report or data processor is not unique. The same name is assigned to another report or data processor.';
						|it = 'Il nome ""%1"", utilizzato dal report (elaborazione) ""%2"", è già utilizzato da un altro report aggiuntivo (elaborazione) pubblicato.';
						|pl = 'Nazwa ""%1"", wykorzystywana przez raport (przetwarzanie) ""%2"" jest już zajęta przez inne opublikowane raport dodatkowy (przetwarzanie).';
						|tr = '""%2"" raporda kullanılan ""%1"" adı (veri işlemcisi) yayınlanan başka bir ek rapor (veri işlemcisi) tarafından zaten kullanılıyor.'"),
					ObjectName,
					String(Ref));
			EndIf;
			Common.MessageToUser(ErrorText, , "Object.Publication");
		EndIf;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SSLSubsystemsIntegration.BeforeWriteAdditionalDataProcessor(ThisObject, Cancel);
	
	If IsNew() And Not AdditionalReportsAndDataProcessors.InsertRight1(ThisObject) Then
		Raise(NStr("vi = 'Không đủ quyền để thêm báo cáo hoặc bộ xử lý bổ sung.';
					|ru = 'Недостаточно прав для добавления дополнительных отчетов или обработок.';
					|en = 'Insufficient rights to add additional reports or data processors.'; fa = 'Insufficient rights to add additional reports or data processors.';
					|it = 'Permessi insufficienti per l''aggiunta di report o elaborazioni aggiuntive.';
					|pl = 'Niewystarczające uprawnienia do dodawania raportów dodatkowych lub przetwarzania.';
					|tr = 'Ek raporlar veya veri işlemcileri eklemek için yetersiz haklar.'"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	// Preliminary checks.
	If Not IsNew() And Kind <> Common.ObjectAttributeValue(Ref, "Kind") Then
		Common.MessageToUser(
			NStr("vi = 'Không thể thay đổi dạng báo cáo hoặc bộ xử lý bổ sung hiện tại.';
				|ru = 'Невозможно сменить вид существующего дополнительного отчета или обработки.';
				|en = 'Cannot change the kind of additional report or data processor.'; fa = 'Cannot change the kind of additional report or data processor.';
				|it = 'Impossibile modificare il tipo di un report aggiuntivo esistente oppure di un''elaborazione.';
				|pl = 'Zmiana rodzaju istniejącego raportu dodatkowego lub przetwarzania nie jest możliwa.';
				|tr = 'Mevcut ek raporun veya veri işlemcisinin türü değiştirilemez.'"),,,,
			Cancel);
		Return;
	EndIf;
	
	// Attribute connection with deletion mark.
	If DeletionMark Then
		Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff;
	EndIf;
	
	// Cache of standard checks.
	AdditionalProperties.Insert("PublicationAvailable", Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used);
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			BeforeWriteGlobalDataProcessors(Cancel);
		EndIf;
		Purpose.Clear();
	Else
		BeforeWriteAssignableDataProcessor(Cancel);
		Sections.Clear();
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	QuickAccess = CommonClientServer.StructureProperty(AdditionalProperties, "QuickAccess");
	If TypeOf(QuickAccess) = Type("ValueTable") Then
		DimensionValues = New Structure("AdditionalReportOrDataProcessor", Ref);
		ResourcesValues = New Structure("Available", True);
		InformationRegisters.DataProcessorAccessUserSettings.WriteSettingsPackage(QuickAccess, DimensionValues, ResourcesValues, True);
	EndIf;
	
	If IsGlobalDataProcessor() Then
		If ScheduleSetupRight() Then
			OnWriteGlobalDataProcessor(Cancel);
		EndIf;
	Else
		OnWriteAssignableDataProcessors(Cancel);
	EndIf;
	
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport
		Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Then
		OnWriteReport(Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	If IsFolder Then
		Return;
	EndIf;
	
	SSLSubsystemsIntegration.BeforeDeleteAdditionalDataProcessor(ThisObject, Cancel);
	
	If AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind) Then
		
		SetPrivilegedMode(True);
		// Deleting all jobs.
		For Each Command In Commands Do
			If ValueIsFilled(Command.GUIDScheduledJob) Then
				ScheduledJobsServer.DeleteJob(Command.GUIDScheduledJob);
			EndIf;
		EndDo;
		SetPrivilegedMode(False);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function IsGlobalDataProcessor()
	
	If IsGlobalDataProcessor = Undefined Then
		IsGlobalDataProcessor = AdditionalReportsAndDataProcessors.CheckGlobalDataProcessor(Kind);
	EndIf;
	
	Return IsGlobalDataProcessor;
	
EndFunction

#Region GlobalDataProcessors

Procedure BeforeWriteGlobalDataProcessors(Cancel)
	If Cancel Or Not AdditionalProperties.Property("RelevantCommands") Then
		Return;
	EndIf;
	
	CommandsTable = AdditionalProperties.RelevantCommands; // CatalogTabularSection.AdditionalReportsAndDataProcessors.Commands
	JobsToUpdate = New Map;
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	// Clearing jobs whose commands are deleted from the table.
	If Not IsNew() Then
		For Each ObsoleteCommand In Common.ObjectAttributeValue(Ref, "Commands").Unload() Do
			If ValueIsFilled(ObsoleteCommand.GUIDScheduledJob)
				And CommandsTable.Find(ObsoleteCommand.GUIDScheduledJob, "GUIDScheduledJob") = Undefined Then
				ScheduledJobsServer.DeleteJob(ObsoleteCommand.GUIDScheduledJob);
			EndIf;
		EndDo;
	EndIf;
	
	// Updating the set of scheduled jobs before writing their IDs to the tabular section.
	For Each RelevantCommand In CommandsTable Do
		Command = Commands.Find(RelevantCommand.Id, "Id");
		
		If PublicationEnabled And RelevantCommand.ScheduledJobSchedule.Count() > 0 Then
			Schedule    = RelevantCommand.ScheduledJobSchedule[0].Value;
			Use = RelevantCommand.ScheduledJobUsage
				And AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Schedule);
		Else
			Schedule = Undefined;
			Use = False;
		EndIf;
		
		Job = ScheduledJobsServer.Job(RelevantCommand.GUIDScheduledJob);
		If Job = Undefined Then // Not found.
			If Use Then
				// Create and register a scheduled job.
				JobParameters = New Structure;
				JobParameters.Insert("Metadata", Metadata.ScheduledJobs.StartingAdditionalDataProcessors);
				JobParameters.Insert("Use", False);
				Job = ScheduledJobsServer.AddJob(JobParameters);
				JobsToUpdate.Insert(RelevantCommand, Job);
				Command.GUIDScheduledJob = ScheduledJobsServer.UUID(Job);
			Else
				// No action required.
			EndIf;
		Else // Found.
			If Use Then
				// Register.
				JobsToUpdate.Insert(RelevantCommand, Job);
			Else
				// Delete.
				ScheduledJobsServer.DeleteJob(RelevantCommand.GUIDScheduledJob);
				Command.GUIDScheduledJob = CommonClientServer.BlankUUID();
			EndIf;
		EndIf;
	EndDo;
	
	AdditionalProperties.Insert("JobsToUpdate", JobsToUpdate);
	
EndProcedure

Procedure OnWriteGlobalDataProcessor(Cancel)
	If Cancel Or Not AdditionalProperties.Property("RelevantCommands") Then
		Return;
	EndIf;
	
	PublicationEnabled = (Publication <> Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff);
	
	// Scheduled jobs must be changed in the privileged mode.
	SetPrivilegedMode(True);
	
	For Each KeyAndValue In AdditionalProperties.JobsToUpdate Do
		Command = KeyAndValue.Key;// CatalogTabularSectionRow.AdditionalReportsAndDataProcessors.Commands
		Job = KeyAndValue.Value;
		
		Changes = New Structure;
		Changes.Insert("Use", False);
		Changes.Insert("Schedule", Undefined);
		Changes.Insert("Description", Left(JobPresentation(Command), 120));
		
		If PublicationEnabled And Command.ScheduledJobSchedule.Count() > 0 Then
			Changes.Schedule    = Command.ScheduledJobSchedule[0].Value;
			Changes.Use = Command.ScheduledJobUsage
				And AdditionalReportsAndDataProcessorsClientServer.ScheduleSpecified(Changes.Schedule);
		EndIf;
		
		ProcedureParameters = New Array;
		ProcedureParameters.Add(Ref);
		ProcedureParameters.Add(Command.Id);
		
		Changes.Insert("Parameters", ProcedureParameters);
		
		SSLSubsystemsIntegration.BeforeUpdateJob(ThisObject, Command, Job, Changes);
		If Changes <> Undefined Then
			ScheduledJobsServer.ChangeJob(Job, Changes);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region WorkWithScheduledJobs

Function ScheduleSetupRight()
	// Checks whether a user has rights to schedule the execution of additional reports and data processors.
	Return AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors);
EndFunction

Function JobPresentation(Command)
	// '[ObjectKind]: [ObjectDescription] / Command: [CommandPresentation]'
	Return (
		TrimAll(Kind)
		+ ": "
		+ TrimAll(Description)
		+ " / "
		+ NStr("vi = 'Lệnh';
				|ru = 'Команда';
				|en = 'Command'; fa = 'فرمان';
				|it = 'Comando';
				|pl = 'Command';
				|tr = 'Komut'")
		+ ": "
		+ TrimAll(Command.Presentation));
EndFunction

#EndRegion

#Region AssignableDataProcessors

Procedure BeforeWriteAssignableDataProcessor(Cancel)
	AssignmentTable = Purpose.Unload();
	AssignmentTable.GroupBy("RelatedObject");
	Purpose.Load(AssignmentTable);
	
	MetadataObjectsRefs = AssignmentTable.UnloadColumn("RelatedObject");
	
	If Not IsNew() Then
		For Each TableRow In Common.ObjectAttributeValue(Ref, "Purpose").Unload() Do
			If MetadataObjectsRefs.Find(TableRow.RelatedObject) = Undefined Then
				MetadataObjectsRefs.Add(TableRow.RelatedObject);
			EndIf;
		EndDo;
	EndIf;
	
	AdditionalProperties.Insert("MetadataObjectsRefs", MetadataObjectsRefs);
EndProcedure

Procedure OnWriteAssignableDataProcessors(Cancel)
	If Cancel Or Not AdditionalProperties.Property("MetadataObjectsRefs") Then
		Return;
	EndIf;
	
	InformationRegisters.AdditionalDataProcessorsPurposes.UpdateDataByMetadataObjectsRefs(AdditionalProperties.MetadataObjectsRefs);
EndProcedure

#EndRegion

#Region GlobalReports

Procedure OnWriteReport(Cancel)
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions") Then
		
		Try
			If IsNew() Then
				ExternalObject = ExternalReports.Create(ObjectName);
			Else
				ExternalObject = AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
			EndIf;
		Except
			ErrorText = NStr("vi = 'Chưa kết nối báo cáo:';
							|ru = 'Отчет не подключен:';
							|en = 'The report is not attached:'; fa = 'The report is not attached:';
							|it = 'The report is not attached:';
							|pl = 'The report is not attached:';
							|tr = 'Rapor bağlanmadı:'") + Chars.LF + ErrorProcessing.DetailErrorDescription(ErrorInfo());
			AdditionalReportsAndDataProcessors.WriteError(Ref, ErrorText);
			AdditionalProperties.Insert("AttachmentError", ErrorText);
			ExternalObject = Undefined;
		EndTry;
		
		AdditionalProperties.Insert("Global", IsGlobalDataProcessor());
		
		ModuleReportsOptions = Common.CommonModule("ReportsOptions");
		ModuleReportsOptions.OnWriteAdditionalReport(ThisObject, Cancel, ExternalObject);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf