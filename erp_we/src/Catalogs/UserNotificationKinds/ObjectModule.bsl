#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	Supplied = False;
	Running = False;
	Changed = False;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	NotCheckedAttributeArray = New Array;
	If NotificationType = Enums.UserNotificationTypes.NonOperational Then
		NotCheckedAttributeArray.Add("DataSources");
	ElsIf NotificationType = Enums.UserNotificationTypes.Nonexclusive Then
		NotCheckedAttributeArray.Add("GroupedNotificationText");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	If Not IsFolder And Running And Not Conversations.CollaborationSystemConnected() Then
		ErrorText = NStr("vi = 'Không thể truy cập vào các cuộc thảo luận của hệ thống tương tác. Dạng thông báo này không thể hoạt động.';
						|ru = 'Обсуждения системы взаимодействия недоступны. Вид оповещения не может быть активным.';
						|en = 'Collaboration system notifications are not available. The notification kind cannot be active.'; fa = 'Collaboration system notifications are not available. The notification kind cannot be active.';
						|it = 'Collaboration system notifications are not available. The notification kind cannot be active.';
						|pl = 'Collaboration system notifications are not available. The notification kind cannot be active.';
						|tr = 'Ortak çalışma sistemi sohbeti mevcut değil. Bildirim türü aktif olamaz.'");
		
		Common.MessageToUser(
			ErrorText,
			ThisObject,
			"Running",
			,
			Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder And NotificationType = Enums.UserNotificationTypes.NonOperational Then
		DataSources.Clear();
	EndIf;
	
	If Not IsFolder And Running Then
		
		If DCSTemplateName = UserNotificationsOfEvents.NameOfPredefinedTemplate() Then
			DCS = DataCompositionSchema.Get();
			If DCS = Undefined 
				Or Not UserNotificationsOfEvents.HasChanges(DCS, UserNotificationsOfEvents.TemplateByFullName(DCSTemplateName)) Then
				ErrorText = NStr("vi = 'Chưa tùy chỉnh truy vấn nhận dữ liệu thông báo. Dạng thông báo này không thể hoạt động.';
								|ru = 'Не настроен запрос получения данных оповещения. Вид оповещения не может быть активным.';
								|en = 'The request for notification data is not configured. The notification kind cannot be active.'; fa = 'The request for notification data is not configured. The notification kind cannot be active.';
								|it = 'The request for notification data is not configured. The notification kind cannot be active.';
								|pl = 'The request for notification data is not configured. The notification kind cannot be active.';
								|tr = 'Bildirim verilerini alma talebi yapılandırılmadı. Bildirim türü aktif olamaz.'");
				
				Common.MessageToUser(
					ErrorText,
					ThisObject,
					"Running",
					,
					Cancel);
			EndIf;
		EndIf;
		
		UserNotificationsOfEvents.CheckingCorrectnessOfDataAcquisitionSchemeBeforeRecording(ThisObject, Cancel);
	EndIf;
	
	If Not IsFolder And Supplied And Not Changed Then
		DescriptionOfTypeOfAlerts = UserNotificationsOfEvents.DescriptionOfTypeOfUserAlertsById(Ref.UUID());
		If DescriptionOfTypeOfAlerts <> Undefined Then
			If DataCompositionSchema.Get() <> Undefined
				Or StorageOfDataCompositionSettings.Get() <> Undefined Then
				
				Changed = True;
				
			EndIf;
			
			If Not Changed Then
				MainAttributesOfTypeOfAlerts = UserNotificationsOfEvents.MainAttributesOfTypeOfAlerts();
				For Each AttributeName In MainAttributesOfTypeOfAlerts Do
					If DescriptionOfTypeOfAlerts[AttributeName] <> ThisObject[AttributeName] Then
						Changed = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If Not Changed Then
				For Each SourceRow In DescriptionOfTypeOfAlerts.DataSources Do
					If TypeOf(SourceRow.SourceType) = Type("String") Then
						StringSourceSourceType = Common.MetadataObjectID(SourceRow.SourceType);
					Else
						StringSourceSourceType = SourceRow.SourceType;
					EndIf;
					TheStructureOfTheSearch = New Structure("SourceType, SourceDetails_",
						StringSourceSourceType,
						SourceRow.SourceDetails_);
						
					If DataSources.FindRows(TheStructureOfTheSearch).Count() = 0 Then
						Changed = True;
						Break;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	RefreshReusableValues();
	
	If Not IsFolder And Running And Conversations.CollaborationSystemConnected() Then
		SetPrivilegedMode(True);
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.UserNotificationsOfEvents);
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() = 1 Then
			If Not Jobs[0].Use Then
				Parameters = New Structure();
				Parameters.Insert("Use", True);
				ScheduledJobsServer.ChangeJob(Jobs[0].UUID, Parameters);
			EndIf;
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf