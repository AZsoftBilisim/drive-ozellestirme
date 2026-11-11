///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	InformParameters = UsersInternalClient.RestartNotificationParameters();
	If Not ValueIsFilled(InformParameters.RestartDate) Then
		Return;
	EndIf;
	
	Items.FormRemindMeTomorrow.Visible = False;
	Items.Picture.Picture = PictureLib.DialogExclamation;
	
	MinutesLeftPresentation = UsersInternalClient.MinutesBeforeRestartPresentation(
		UsersInternalClient.MinutesBeforeRestart(InformParameters.RestartDate));
		
	Items.Label.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Người quản trị đã thay đổi các quyền truy cập.
		           |Sẽ khởi động lại ứng dụng sau %1 để chúng có hiệu lực.';
		           |ru = 'Администратор изменил права доступа.
		           |Приложение будет перезапущено через %1, чтобы они вступили в силу.';
		           |en = 'The administrator changed access rights.
		           |To apply the changes, the app will restart in %1.'; fa = 'The administrator changed access rights.
		           |To apply the changes, the app will restart in %1.';
		           |it = 'Администратор изменил права доступа.
		           |Приложение будет перезапущено через %1, чтобы они вступили в силу.';
		           |pl = 'The administrator changed access rights.
		           |To apply the changes, the app will restart in %1.';
		           |tr = 'Yönetici erişim yetkilerini değiştirdi.%1Değişikliklerin devreye girmesi için uygulama yeniden başlatılacak.
		           |'"),
		MinutesLeftPresentation);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Restart(Command)
	
	StandardSubsystemsClient.SkipExitConfirmation();
	Exit(True, True);
	
EndProcedure

&AtClient
Procedure RemindMeTomorrow(Command)
	
	RemindTomorrowOnServer();
	Close();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RemindTomorrowOnServer()
	
	Common.SystemSettingsStorageSave("InfobaseUserRoleChangeControl",
		"DateRemindTomorrow", BegOfDay(CurrentSessionDate()) + 60*60*24);
	
EndProcedure

#EndRegion
