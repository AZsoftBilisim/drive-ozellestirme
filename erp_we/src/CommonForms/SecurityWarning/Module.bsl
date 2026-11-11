///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.Key) Then
		ErrorText =
			NStr("vi = 'Biểu mẫu chung ""Cảnh báo bảo mật"" là biểu mẫu phụ trợ và được mở ra từ cơ chế dịch vụ của ứng dụng.';
				|ru = 'Общая форма ""Предупреждение безопасности"" является вспомогательной и открывается из служебных механизмов приложения.';
				|en = 'The common form ""Security warning"" is auxiliary; it is meant to be opened by the internal application algorithms.'; fa = 'The common form ""Security warning"" is auxiliary; it is meant to be opened by the internal application algorithms.';
				|it = 'Общая форма ""Предупреждение безопасности"" является вспомогательной и открывается из служебных механизмов приложения.';
				|pl = 'The common form ""Security warning"" is auxiliary; it is meant to be opened by the internal application algorithms.';
				|tr = '""Güvenlik Uyarısı"" genel formu yardımcı olup uygulamanın hizmet mekanizmalarından açılır.'");
		Raise ErrorText;
	EndIf;
	
	If Not UsersInternalClientServer.SecurityWarningKinds().Property(Parameters.Key) Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chỉ ra sai dạng cảnh báo bảo mật ""%1"".';
				|ru = 'Указан некорректный вид предупреждения безопасности ""%1"".';
				|en = 'Invalid security warning specified: %1.'; fa = 'Invalid security warning specified: %1.';
				|it = 'Указан некорректный вид предупреждения безопасности ""%1"".';
				|pl = 'Invalid security warning specified: %1.';
				|tr = 'Geçersiz güvenlik uyarı türü ""%1"" belirtildi.'"),
			Parameters.Key);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	PurposeUseKey = Parameters.Key;
	WindowOptionsKey = Parameters.Key;
	
	CurrentPage = Items.Find(Parameters.Key);
	For Each Page In Items.Pages.ChildItems Do
		Page.Visible = (Page = CurrentPage);
	EndDo;
	Items.Pages.CurrentPage = CurrentPage;
	
	If CurrentPage = Items.AfterUpdate Then
		Items.DenyOpeningExternalReportsAndDataProcessors.DefaultButton = True;
		
	ElsIf CurrentPage = Items.AfterObtainRight Then
		Items.IAgree.DefaultButton = True;
		
	ElsIf CurrentPage = Items.BeforeOpenFile Then
		If ValueIsFilled(Parameters.AdditionalParameter) Then
			Items.WarningOnOpenFile.Title =
				StringFunctionsClientServer.SubstituteParametersToString(
					Items.WarningOnOpenFile.Title,
					Parameters.AdditionalParameter);
		EndIf;
	
	ElsIf CurrentPage = Items.BeforeDeleteExtensionWithData
	      Or CurrentPage = Items.BeforeDeleteExtensionWithoutData
	      Or CurrentPage = Items.BeforeDisableExtensionWithData Then
		
		If Common.DataSeparationEnabled() Then 
			Items.WarningBeforeDeleteExtensionWithDataBackup.Visible = False;
			Items.WarningBeforeDeleteExtensionWithoutDataBackup.Visible = False;
			
		ElsIf Common.SubsystemExists("StandardSubsystems.IBBackup") Then
			ModuleIBBackupServer = Common.CommonModule("IBBackupServer");
			Items.WarningBeforeDeleteExtensionWithDataBackup.Title = 
				StringFunctions.FormattedString(NStr("vi = 'Trước khi gỡ cài đặt phần mở rộng, cần
					|<a href=""%1"">sao lưu dự phòng cơ sở thông tin</a>.';
					|ru = 'Перед удалением расширения рекомендуется
					|<a href=""%1"">выполнить резервное копирование информационной базы</a>.';
					|en = 'It is recommended that you 
					|<a href=""%1"">back up the infobase</a> before deleting the extension.'; fa = 'It is recommended that you 
					|<a href=""%1"">back up the infobase</a> before deleting the extension.';
					|it = 'Перед удалением расширения рекомендуется
					|<a href=""%1"">выполнить резервное копирование информационной базы</a>.';
					|pl = 'It is recommended that you 
					|<a href=""%1"">back up the infobase</a> before deleting the extension.';
					|tr = 'Uzantı silinmeden önce </a> infobase''nin yedeklenmesi tavsiye edilir
					|<a href=""%1"">.'"),
				ModuleIBBackupServer.BackupDataProcessorURL());
			Items.WarningBeforeDeleteExtensionWithoutDataBackup.Title =
				Items.WarningBeforeDeleteExtensionWithDataBackup.Title;
		EndIf;
		
		If Parameters.AdditionalParameter = True Then
			Items.WarningBeforeDeleteExtensionWithDataTextDelete.Title =
				NStr("vi = 'Xóa phần mở rộng đã chọn?';
					|ru = 'Удалить выделенные расширения?';
					|en = 'Do you want to delete the selected extensions?'; fa = 'Do you want to delete the selected extensions?';
					|it = 'Eliminare le estensioni selezionate?';
					|pl = 'Usunąć zaznaczone rozszerzenia?';
					|tr = 'Seçilen uzantılar silinsin mi?'");
		Else
			Items.WarningBeforeDeleteExtensionWithDataTextDelete.Title =
				NStr("vi = 'Xóa phần mở rộng';
					|ru = 'Удалить расширение?';
					|en = 'Do you want to delete the extension?'; fa = 'Do you want to delete the extension?';
					|it = 'Eliminare l''estensione?';
					|pl = 'Usunąć rozszerzenie?';
					|tr = 'Uzantı silinsin mi?'");
		EndIf;
		Items.WarningBeforeDeleteExtensionWithoutDataTextDelete.Title = 
			Items.WarningBeforeDeleteExtensionWithDataTextDelete.Title;
		
		Title = NStr("vi = 'Cảnh báo';
					|ru = 'Предупреждение';
					|en = 'Warning'; fa = 'هشدار';
					|it = 'Avviso';
					|pl = 'Ostrzeżenie';
					|tr = 'Uyarı'");
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarningBeforeDeleteExtensionBackupURLProcessing(Item, 
	FormattedStringURL, StandardProcessing)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CommandContinue(Command)
	SelectedButtonName = Command.Name;
	CloseFormAndReturnResult();
EndProcedure

&AtClient
Procedure DenyOpeningExternalReportsAndDataProcessors(Command)
	AllowInteractiveOpening = False;
	ManageRoleAtClient(Command);
EndProcedure

&AtClient
Procedure AllowOpeningExternalReportsAndDataProcessors(Command)
	AllowInteractiveOpening = True;
	ManageRoleAtClient(Command);
EndProcedure

&AtClient
Procedure IAgree(Command)
	SelectedButtonName = Command.Name;
	IAgreeAtServer();
	CloseFormAndReturnResult();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ManageRoleAtClient(Command)
	SelectedButtonName = Command.Name;
	ManageRoleAtServer();
	RefreshReusableValues();
	ProposeRestart();
EndProcedure

&AtServer
Procedure ManageRoleAtServer()
	If Not AccessRight("Administration", Metadata) Then
		Return;
	EndIf;
	RoleOpening = Metadata.Roles.InteractiveOpenExtReportsAndDataProcessors;
	AdministratorRole = Metadata.Roles.SystemAdministrator;
	
	AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	AdministrationParameters.Insert("OpenExternalReportsAndDataProcessorsDecisionMade", True);
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
	
	RefreshReusableValues();
	
	IBUsers = InfoBaseUsers.GetUsers();
	For Each IBUser In IBUsers Do
		If AllowInteractiveOpening Then
			If IBUser.Roles.Contains(AdministratorRole)
				And Not IBUser.Roles.Contains(RoleOpening) Then
				IBUser.Roles.Add(RoleOpening);
				IBUser.Write();
			EndIf;
		Else
			If IBUser.Roles.Contains(RoleOpening) Then
				IBUser.Roles.Delete(RoleOpening);
				IBUser.Write();
			EndIf;
		EndIf;
	EndDo;
	
	If AllowInteractiveOpening Then
		RestartRequired = Not AccessRight("InteractiveOpenExtDataProcessors", Metadata);
	Else
		RestartRequired = AccessRight("InteractiveOpenExtDataProcessors", Metadata);
	EndIf;
	
	IAgreeAtServer();
	
	// In SaaS mode, the right to open external reports and date processors
	// is not supported for data area users.
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.SetExternalReportsAndDataProcessorsOpenRight(AllowInteractiveOpening);
	EndIf;
	
EndProcedure

&AtServer
Procedure IAgreeAtServer()
	Common.CommonSettingsStorageSave("SecurityWarning", "UserAccepts", True);
EndProcedure

&AtClient
Procedure CloseFormAndReturnResult()
	If IsOpen() Then
		NotifyChoice(SelectedButtonName);
	EndIf;
EndProcedure

&AtClient
Procedure ProposeRestart()
	If Not RestartRequired Then
		CloseFormAndReturnResult();
		Return;
	EndIf;
	
	Handler = New CallbackDescription("RestartApplication", ThisObject);
	Buttons = New ValueList;
	Buttons.Add("Restart", NStr("vi = 'Khởi động lại';
								|ru = 'Перезапустить';
								|en = 'Restart'; fa = 'راه‌اندازی مجدد';
								|it = 'Riavviare';
								|pl = 'Restart';
								|tr = 'Yeniden başlat'"));
	Buttons.Add("DoNotRestart", NStr("vi = 'Không khởi động lại';
									|ru = 'Не перезапускать';
									|en = 'Do not restart'; fa = 'Do not restart';
									|it = 'Non riavviare';
									|pl = 'Nie uruchamiaj ponownie';
									|tr = 'Yeniden başlatma'"));
	QueryText = NStr("vi = 'Để áp dụng thay đổi, nên khởi động lại ứng dụng.';
					|ru = 'Для применения изменений требуется перезапустить приложение.';
					|en = 'To apply the changes, restart the application.'; fa = 'To apply the changes, restart the application.';
					|it = 'Для применения изменений требуется перезапустить приложение.';
					|pl = 'To apply the changes, restart the application.';
					|tr = 'Değişikliklerin uygulanması için uygulama yeniden başlatılmalıdır.'");
	ShowQueryBox(Handler, QueryText, Buttons);
EndProcedure

&AtClient
Procedure RestartApplication(Response, ExecutionParameters) Export
	CloseFormAndReturnResult();
	If Response = "Restart" Then
		Exit(False, True);
	EndIf;
EndProcedure

#EndRegion
