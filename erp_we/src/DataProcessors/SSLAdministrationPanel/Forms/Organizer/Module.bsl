///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		If Users.IsFullUser() Then
			HasMail = Common.SubsystemExists("StandardSubsystems.EmailOperations");
			ScheduledJob = FindScheduledJob("TaskMonitoring");
			If HasMail And ScheduledJob <> Undefined Then
				TasksMonitoringUsage = ScheduledJob.Use;
				TaskMonitoringSchedule    = ScheduledJob.Schedule;
			Else
				Items.TasksMonitoringGroup.Visible = False;
			EndIf;
			ScheduledJob = FindScheduledJob("NewPerformerTaskNotifications");
			If HasMail And ScheduledJob <> Undefined Then
				NotifyPerformersAboutNewTasksUsage = ScheduledJob.Use;
				NewPerformerTaskNotificationsSchedule    = ScheduledJob.Schedule;
			Else
				Items.NotifyPerformersAboutNewTasksGroup.Visible = False;
			EndIf;
		Else
			Items.TasksMonitoringGroup.Visible = False;
			Items.NotifyPerformersAboutNewTasksGroup.Visible = False;
		EndIf;
		
		If Common.DataSeparationEnabled() Then
			Items.TasksMonitoringConfigureSchedule.Visible = False;
			Items.NotifyPerformersAboutNewTasksConfigureSchedule.Visible = False;
		EndIf;
	Else
		Items.BusinessProcessesAndTasksGroup.Visible = False;
	EndIf;
	
	// Update items states.
	SetAvailability();
	
	ApplicationSettingsOverridable.OrganizerOnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName <> "Write_ConstantsSet" 
		And EventName <> "ConversationsEnabled" Then
		Return;
	EndIf;
	
	If Source = "UseExternalUsers"
		Or EventName = "ConversationsEnabled"
		Or Source = "UseUserNotificationsOfSystemEvents" Then
		
		Read();
		SetAvailability();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseEmailClientOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseOtherInteractionsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure SendEmailsInHTMLFormatOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseReviewedFlagOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure DenyDisplayingUnsafeContentInEmailsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseNotesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseUserRemindersOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseSurveyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseMessageTemplatesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseBusinessProcessesAndTasksOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseSubordinateBusinessProcessesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure ChangeJobsBackdatedOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseTaskStartDateOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseDateAndTimeInTaskDeadlinesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseIncidentsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseUserNotificationsOfSystemEventsOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseUserNotificationsViaTelegramOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure UseUserNotificationsByEmailOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RolesAndTaskPerformers(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		ModuleBusinessProcessesAndTasksClient = CommonClient.CommonModule("BusinessProcessesAndTasksClient");
		ModuleBusinessProcessesAndTasksClient.OpenRolesAndTaskPerformersList();
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksMonitoringConfigureSchedule(Command)
	Dialog = New ScheduledJobDialog(TaskMonitoringSchedule);
	Dialog.Show(New CallbackDescription("TaskMonitoringAfterScheduleChanged", ThisObject));
EndProcedure

&AtClient
Procedure NotifyPerformersAboutNewTasksConfigureSchedule(Command)
	Dialog = New ScheduledJobDialog(NewPerformerTaskNotificationsSchedule);
	Dialog.Show(New CallbackDescription("NewPerformerTaskNotificationsAfterChangeSchedule", ThisObject));
EndProcedure

&AtClient
Procedure OpenUserNotificationKinds(Command)
	OpenForm("Catalog.UserNotificationKinds.Form.ListForm",, ThisObject);
EndProcedure

&AtClient
Procedure SetUpIntegrationWithTelegram(Command)
	OpenForm("DataProcessor.ConnectingToUserNotificationsBot.Form.TelegramBotCreation",,ThisObject);
EndProcedure

#EndRegion

#Region Private

#Region Client

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

&AtClient
Procedure TaskMonitoringAfterScheduleChanged(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	TaskMonitoringSchedule = Schedule;
	TasksMonitoringUsage = True;
	WriteScheduledJob("TaskMonitoring", TasksMonitoringUsage, 
		TaskMonitoringSchedule, "TaskMonitoringSchedule");
EndProcedure

&AtClient
Procedure TasksMonitoringUsageOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") And TasksMonitoringUsage Then
		CallbackDescription = New CallbackDescription("TasksMonitoringUsageMailAvailabilityCheckCompleted", ThisObject);
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	Else
		TasksMonitoringUsageMailAvailabilityCheckCompleted(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure TasksMonitoringUsageMailAvailabilityCheckCompleted(CheckCompleted, AdditionalParameters = Undefined) Export
	
	If CheckCompleted = True Then
		WriteScheduledJob("TaskMonitoring", TasksMonitoringUsage, 
			TaskMonitoringSchedule, "TaskMonitoringSchedule");
	Else
		TasksMonitoringUsage = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NewPerformerTaskNotificationsAfterChangeSchedule(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	NewPerformerTaskNotificationsSchedule = Schedule;
	NotifyPerformersAboutNewTasksUsage = True;
	WriteScheduledJob("NewPerformerTaskNotifications", NotifyPerformersAboutNewTasksUsage, 
		NewPerformerTaskNotificationsSchedule, "NewPerformerTaskNotificationsSchedule");
EndProcedure

&AtClient
Procedure NotifyPerformersAboutNewTasksUsageOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.EmailOperations") And NotifyPerformersAboutNewTasksUsage Then
		CallbackDescription = New CallbackDescription(
			"NotifyPerformersAboutNewTasksUsageEmailAvailabilityCheckCompleted", ThisObject);
		ModuleEmailOperationsClient = CommonClient.CommonModule("EmailOperationsClient");
		ModuleEmailOperationsClient.CheckAccountForSendingEmailExists(CallbackDescription);
	Else
		NotifyPerformersAboutNewTasksUsageEmailAvailabilityCheckCompleted(True);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyPerformersAboutNewTasksUsageEmailAvailabilityCheckCompleted(CheckCompleted, AdditionalParameters = Undefined) Export
	
	If CheckCompleted = True Then
		WriteScheduledJob("NewPerformerTaskNotifications", NotifyPerformersAboutNewTasksUsage, 
			NewPerformerTaskNotificationsSchedule, "NewPerformerTaskNotificationsSchedule");
	Else
		NotifyPerformersAboutNewTasksUsage = False;
	EndIf;
		
EndProcedure

#EndRegion

#Region Server

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	If (ConstantName = "UseEmailClient" Or ConstantName = "UseBusinessProcessesAndTasks") 
		And Not ConstantsSet[ConstantName] Then
		Read();
	EndIf;
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantName;
	
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	If (DataPathAttribute = "ConstantsSet.UseEmailClient" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.Interactions") Then
		
		Items.UseOtherInteractions.Enabled             = ConstantsSet.UseEmailClient;
		Items.UseReviewedFlag.Enabled               = ConstantsSet.UseEmailClient;
		Items.SendEmailsInHTMLFormat.Enabled                 = ConstantsSet.UseEmailClient;
		Items.DenyDisplayingUnsafeContentInEmails.Enabled = ConstantsSet.UseEmailClient;
		
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseMessageTemplates" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.MessageTemplates") Then
		
		Items.MessageTemplatesSettingsGroup.Enabled = ConstantsSet.UseMessageTemplates;
	EndIf;
	
	If (DataPathAttribute = "ConstantsSet.UseBusinessProcessesAndTasks" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		AvailabilityOfBusinessProcessesAndTasks =
			Not ConstantsSet.UseBusinessProcessesAndTasks
			Or (Not Constants.UseSalesOrderApproval.Get()
				And Not Constants.UseApprovalOfTermsOfSales.Get()
				And Not Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Get()
				And Not Constants.UseApprovalOfItemPrices.Get()
				// IntegrationWith1CDocumentManagementSubsystem
				And Not Constants.UseIntegrationWith1CDocumentManagement.Get()
				// End IntegrationWith1CDocumentManagementSubsystem
				And Not Constants.UsePurchaseOrderApproval.Get()
				And Not Constants.UseApprovalOfEngineeringChangeOrders.Get()
				And Not Constants.UseApprovalOfInventoryConsumptionOrders.Get());
		Items.UseBusinessProcessesAndTasks.Enabled 		   = AvailabilityOfBusinessProcessesAndTasks;
		Items.GroupCommentUseBusinessProcesses.Visible = Not AvailabilityOfBusinessProcessesAndTasks;
		
		If Not AvailabilityOfBusinessProcessesAndTasks Then
			Items.CommentUseBusinessProcesses.Title = CommentTextUseBusinessProcesses();
		EndIf;
		Items.OpenRolesAndPerformersForBusinessProcesses.Enabled = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseSubordinateBusinessProcesses.Enabled  = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.ChangeJobsBackdated.Enabled            = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseTaskStartDate.Enabled            = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.UseDateAndTimeInTaskDeadlines.Enabled     = ConstantsSet.UseBusinessProcessesAndTasks;
		Items.TasksMonitoringGroup.Enabled					= ConstantsSet.UseBusinessProcessesAndTasks;
		Items.NotifyPerformersAboutNewTasksGroup.Enabled = ConstantsSet.UseBusinessProcessesAndTasks;
		
	EndIf;
	
	If Items.TasksMonitoringGroup.Visible
		And (DataPathAttribute = "TaskMonitoringSchedule" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		Items.TasksMonitoringConfigureSchedule.Enabled	= TasksMonitoringUsage;
		If TasksMonitoringUsage Then
			SchedulePresentation = String(TaskMonitoringSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = "";
		EndIf;
		Items.TasksMonitoringNote.Title = Presentation;
	EndIf;
	
	If Items.NotifyPerformersAboutNewTasksGroup.Visible
		And (DataPathAttribute = "NewPerformerTaskNotificationsSchedule" Or DataPathAttribute = "")
		And Common.SubsystemExists("StandardSubsystems.BusinessProcessesAndTasks") Then
		Items.NotifyPerformersAboutNewTasksConfigureSchedule.Enabled	= NotifyPerformersAboutNewTasksUsage;
		If NotifyPerformersAboutNewTasksUsage Then
			SchedulePresentation = String(NewPerformerTaskNotificationsSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = "";
		EndIf;
		Items.NotifyPerformersAboutNewTasksNote.Title = Presentation;
	EndIf;
	
	If DataPathAttribute = "" 
		Or DataPathAttribute = "ConstantsSet.UseUserNotificationsOfSystemEvents" Then
		
		CollaborationSystemConnected = False;
		DiscussionSubsystemExists = False;
		If Common.SubsystemExists("StandardSubsystems.Conversations") Then
			ModuleConversations = Common.CommonModule("Conversations");
			CollaborationSystemConnected = ModuleConversations.CollaborationSystemConnected();
			DiscussionSubsystemExists = True;
		EndIf;
		
		Items.UseUserNotificationsOfSystemEvents.Enabled = CollaborationSystemConnected;
		Items.SettingUpUserNotificationKinds.Enabled = CollaborationSystemConnected
			And ConstantsSet.UseUserNotificationsOfSystemEvents;
		Items.CommentUseUserAlerts.Visible = Not CollaborationSystemConnected;
		Items.DecorationUseUserAlerts.Visible = Not CollaborationSystemConnected;
		
		Items.UseUserNotificationsViaTelegram.Enabled = ConstantsSet.UseUserNotificationsOfSystemEvents And CollaborationSystemConnected;
		Items.UseUserNotificationsByEmail.Enabled = ConstantsSet.UseUserNotificationsOfSystemEvents And CollaborationSystemConnected;
		
		If Not CollaborationSystemConnected Then
			ConnectText = NStr("vi = 'Để sử dụng thông báo cho người sử dụng về các sự kiện của hệ thống, cần kết nối đến dịch vụ thảo luận.';
								|ru = 'Для использования оповещений пользователей о событиях системы необходимо подключение к сервису обсуждений.';
								|en = 'To use user notifications about system events, connect to the conversation service.'; fa = 'To use user notifications about system events, connect to the conversation service.';
								|it = 'To use user notifications about system events, connect to the conversation service.';
								|pl = 'To use user notifications about system events, connect to the conversation service.';
								|tr = 'Sistem olayları hakkında kullanıcı bildirimleri için sohbet hizmetine bağlanmanız gerekmektedir.'");
			
			RowsArray = New Array;
			RowsArray.Add(ConnectText);
			If DiscussionSubsystemExists Then
				RowsArray.Add(Chars.LF);
				RowsArray.Add(New FormattedString(
					NStr("vi = 'Kết nối';
						|ru = 'Подключиться';
						|en = 'Connect'; fa = 'اتصال';
						|it = 'Connect';
						|pl = 'Connect';
						|tr = 'Bağlan'"), ,
					StyleColors.HyperlinkColor,
					Undefined,
					"e1cib/app/" + Metadata.DataProcessors.EnableDiscussions.FullName()));
			EndIf;
				
			Items.CommentUseUserAlerts.Title = New FormattedString(RowsArray);
		EndIf;
	EndIf;
	If DataPathAttribute = "" 
		Or DataPathAttribute = "ConstantsSet.UseUserNotificationsViaTelegram" Then
			Items.SetUpIntegrationWithTelegram.Enabled = ConstantsSet.UseUserNotificationsOfSystemEvents
				And ConstantsSet.UseUserNotificationsViaTelegram;
	EndIf;
EndProcedure

&AtServer
Procedure WriteScheduledJob(PredefinedItemName, Use, Schedule, DataPathAttribute)
	ScheduledJob = FindScheduledJob(PredefinedItemName);
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", Use);
	JobParameters.Insert("Schedule", Schedule);
	
	ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
	
	If DataPathAttribute <> Undefined Then
		SetAvailability(DataPathAttribute);
	EndIf;
EndProcedure

&AtServer
Function FindScheduledJob(PredefinedItemName)
	Filter = New Structure;
	Filter.Insert("Metadata", PredefinedItemName);
	
	SearchResult = ScheduledJobsServer.FindJobs(Filter);
	Return ?(SearchResult.Count() = 0, Undefined, SearchResult[0]);
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
// OtherItems

&AtServer
Function CommentTextUseBusinessProcesses()
	
	CommentTextUseBusinessProcesses = NStr("vi = 'Không thể ngắt bỏ quy trình nghiệp vụ và nhiệm vụ, bởi vì đã bật:';
											|ru = 'Невозможно отключение бизнес-процессов и задач, потому что включено:';
											|en = 'Cannot terminate business processes and tasks as the following is enabled:'; fa = 'Cannot terminate business processes and tasks as the following is enabled:';
											|it = 'Non è possibile disabilitare i processi e le attività aziendali perché è abilitato:';
											|pl = 'Nie można wyłączyć procesów biznesowych i zadań, ponieważ jest włączone:';
											|tr = 'İş Süreçleri ve Görevler devre dışı bırakılamaz çünkü aşağıdakiler etkin:'");
	
	AdditionToComment = "";
	
	If Constants.UseApprovalOfItemPrices.Get() Then
		
		AdditionToComment =
			Chars.LF + Chars.Tab + "- "
			+ NStr("vi = 'Thống nhất đơn giá trong phân hệ ""Marketing""';
					|ru = 'Согласование цен в разделе ""Маркетинг""';
					|en = 'Price approval in the Marketing section'; fa = 'Price approval in the Marketing section';
					|it = 'Coordinamento dei prezzi nella sezione ""Marketing""';
					|pl = 'Uzgodnienie cen w rozdziale ""Marketing""';
					|tr = '""Pazarlama"" bölümünde fiyat onayı'");
		
	EndIf;
	
	If Constants.UseSalesOrderApproval.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Thống nhất đơn hàng của khách trong phân hệ ""Bán hàng""';
					|ru = 'Согласование заказов клиентов в разделе ""Продажи""';
					|en = 'Sales order approval in the Sales section'; fa = 'Sales order approval in the Sales section';
					|it = 'Coordinamento degli ordini dei clienti nella sezione ""Vendite""';
					|pl = 'Uzgodnienie zamówień klientów w rozdziale ""Sprzedaże""';
					|tr = '""Satışlar"" bölümünde satış siparişi onayı'");
		
	EndIf;
	
	If Constants.UseApprovalOfRequestsForReturnOfGoodsFromCustomers.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Thống nhất giấy đề nghị trả hàng trong phân hệ ""Bán hàng""';
					|ru = 'Согласование заявок на возврат в разделе ""Продажи""';
					|en = 'Return request approval in the Sales section'; fa = 'Return request approval in the Sales section';
					|it = 'Coordinamento delle domande di rimborso nella sezione ""Vendite""';
					|pl = 'Uzgodnienie wniosków o zwrot w rozdziale ""Sprzedaże""';
					|tr = '""Satışlar"" bölümünde iade başvuruları onayı'");
		
	EndIf;
	
	If Constants.UseApprovalOfTermsOfSales.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Thống nhất thỏa thuận với khách hàng trong phân hệ ""Bán hàng""';
					|ru = 'Согласование соглашений с клиентами в разделе ""Продажи""';
					|en = 'Customer agreement approval in the Sales section'; fa = 'Customer agreement approval in the Sales section';
					|it = 'Coordinamento degli accordi con i clienti nella sezione ""Vendite""';
					|pl = 'Uzgodnienie umów z klientami w rozdziale ""Sprzedaże""';
					|tr = '""Satışlar"" bölümünde müşterilerle anlaşma onayı'");
		
	EndIf;
	
	If Constants.UsePurchaseOrderApproval.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Thống nhất chứng từ mua hàng trong phân hệ ""Mua hàng""';
					|ru = 'Согласование документов закупок в разделе ""Закупки""';
					|en = 'Purchase document approval in the Purchases section'; fa = 'Purchase document approval in the Purchases section';
					|it = 'Coordinamento dei documenti di appalto nella sezione ""Acquisti""';
					|pl = 'Uzgodnienie dokumentów zakupów w rozdziale ""Zakupy""';
					|tr = '""Satın almalar"" bölümünde satın alma belgeleri onayı'");
		
	EndIf;
	
	If Constants.UseApprovalOfInventoryConsumptionOrders.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Thống nhất đơn hàng tiêu dùng nội bộ trong phân hệ ""Kho bãi và vận chuyển""';
					|ru = 'Согласование заказов на внутреннее потребление в разделе ""Склад и доставка""';
					|en = 'Approve inventory consumption orders in the Warehouse and delivery section'; fa = 'Approve inventory consumption orders in the Warehouse and delivery section';
					|it = 'Согласование заказов на внутреннее потребление в разделе ""Склад и доставка""';
					|pl = 'Approve inventory consumption orders in the Warehouse and delivery section';
					|tr = '""Ambar ve teslimat"" maddesindeki dış tüketimde siparişlerin onayı'");
		
	EndIf;
	If Constants.UseApprovalOfEngineeringChangeOrders.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("ru = 'Согласование разрешений на замену материалов в разделе ""Производство""';
					|vi = 'Approve engineering change orders in the ""Production"" section';
					|en = 'Approve engineering change orders in the ""Production"" section'; fa = 'Approve engineering change orders in the ""Production"" section';
					|it = 'Approve engineering change orders in the ""Production"" section';
					|pl = 'Approve engineering change orders in the ""Production"" section';
					|tr = '""Üretim"" bölümünde mühendislik değişiklik emirlerin onaylanması'");
		
	EndIf;
	// IntegrationWith1CDocumentManagementSubsystem
	If Constants.UseIntegrationWith1CDocumentManagement.Get() Then
		
		AdditionToComment =
			AdditionToComment + ?(Not IsBlankString(AdditionToComment), ";", "") + Chars.LF + Chars.Tab + "- " 
			+ NStr("vi = 'Tích hợp với 1C:Document Management trong phân hệ ""Quản lý văn bản""';
					|ru = 'Интеграция с 1С:Документооборотом в разделе ""Документооборот""';
					|en = 'Integration with 1C:Document Management in section Document Management'; fa = 'Integration with 1C:Document Management in section Document Management';
					|it = 'Integrazione con 1C:Document Management nella sezione ""Gestione documenti""';
					|pl = 'Integracja z 1С:Document Management w rozdziale ""Document Management""';
					|tr = '""İş akışı"" bölümünde 1C:İş akışı ile entegrasyon'");
		
	EndIf;
	// End IntegrationWith1CDocumentManagementSubsystem
	
	If Not IsBlankString(AdditionToComment) Then
		CommentTextUseBusinessProcesses = CommentTextUseBusinessProcesses + " " + AdditionToComment + ".";
	Else 
		CommentTextUseBusinessProcesses = "";
	EndIf;
	
	Return CommentTextUseBusinessProcesses;
	
EndFunction

#EndRegion