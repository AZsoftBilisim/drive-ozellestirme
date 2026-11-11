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
	
	If Common.FileInfobase() And Parameters.PromptForClusterAdministrationParameters Then
		Raise NStr("vi = 'Có thể tùy chỉnh tham số cụm Server ở chế độ làm việc Client-server.';
					|ru = 'Настройка параметров кластера серверов доступна только в клиент-серверном режиме работы.';
					|en = 'Specifying cluster server parameters is only available in client/server mode.'; fa = 'Specifying cluster server parameters is only available in client/server mode.';
					|it = 'L''impostazione dei parametri del cluster di server è disponibile solo in modalità client-server.';
					|pl = 'Ustawianie parametrów klastra serwerów jest dostępne tylko w trybie pracy klient-serwer.';
					|tr = 'Sunucu kümesi parametrelerinin ayarlanması sadece istemci / sunucu modunda kullanılabilir.'");
	EndIf;
	
	If Parameters.PromptForClusterAdministrationParameters
		And Common.IsMacOSClient() Then
		Return; // Cancel is set in OnOpen.
	EndIf;
	
	SeparatedDataUsageAvailable = Common.SeparatedDataUsageAvailable();
	
	If Parameters.AdministrationParameters = Undefined Then
		AdministrationParameters = StandardSubsystemsServer.AdministrationParameters();
	Else
		AdministrationParameters = Parameters.AdministrationParameters;
	EndIf;
	
	IsNecessaryToInputAdministrationParameters();
	
	If SeparatedDataUsageAvailable Then
		
		IBUser = InfoBaseUsers.FindByName(
		AdministrationParameters.InfobaseAdministratorName);
		If IBUser <> Undefined Then
			IBAdministratorID = IBUser.UUID;
		EndIf;
		Users.FindAmbiguousIBUsers(Undefined, IBAdministratorID);
		IBAdministrator = Catalogs.Users.FindByAttribute("IBUserID", IBAdministratorID);
		
	EndIf;
	
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	If IsBlankString(Parameters.NoteLabel) Then
		Items.NoteLabel.Visible = False;
	Else
		Items.NoteLabel.Title = Parameters.NoteLabel;
	EndIf;
	
	FillPropertyValues(ThisObject, AdministrationParameters);
	
	Items.WorkMode.CurrentPage = ?(SeparatedDataUsageAvailable, Items.SeparatedMode, Items.SharedMode);
	Items.IBAdministrationGroup.Visible = Parameters.PromptForIBAdministrationParameters;
	Items.ClusterAdministrationGroup.Visible = Parameters.PromptForClusterAdministrationParameters;
	
	If Common.IsLinuxClient() Then
		
		AttachmentType = "RAS";
		Items.AttachmentType.Visible = False;
		Items.ManagementParametersGroup.ShowTitle = True;
		Items.ManagementParametersGroup.Representation = UsualGroupRepresentation.WeakSeparation;
		
	EndIf;
	
	Items.ConnectionTypeGroup.CurrentPage = ?(AttachmentType = "COM", Items.COMGroup, Items.RASGroup);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Parameters.PromptForClusterAdministrationParameters
		And CommonClient.IsMacOSClient() Then
		Cancel = True;
		MessageText = NStr("vi = 'Không thể kết nối đến cụm Server trong Client dưới hệ điều hành OS X.';
							|ru = 'Подключение к кластеру серверов недоступно в клиенте под управлением ОС X.';
							|en = 'Cannot connect to the server cluster on the client running on OS X.'; fa = 'Cannot connect to the server cluster on the client running on OS X.';
							|it = 'La connessione a un cluster di server non è disponibile da client che girano su OS X.';
							|pl = 'Podłączenie do klastra serwerów nie jest dostępne w kliencie zarządzanym przez OS X.';
							|tr = 'Bir sunucu kümesine bağlantı, X tabanlı bir istemcide kullanılamaz.'");
		ShowMessageBox(,MessageText);
		Return;
	EndIf;
	
	If Not AdministrationParametersInputRequired Then
		Try
			CheckAdministrationParameters(AdministrationParameters);
		Except
			Return; // Don't process. The form opens in the regular mode.
		EndTry;
		Cancel = True;
		RunCallback(CallbackDescriptionOnClose, AdministrationParameters);
	EndIf;
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Parameters.PromptForIBAdministrationParameters Then
		Return;
	EndIf;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		If Not ValueIsFilled(IBAdministrator) Then
			Return;
		EndIf;
		
		FieldName = "IBAdministrator";
		
		IBUser = Undefined;
		GetIBAdministrator(IBUser);
		If IBUser = Undefined Then
			Common.MessageToUser(NStr("vi = 'Người sử dụng đã chỉ ra không có quyền truy cập đến cơ sở thông tin.';
										|ru = 'Указанный пользователь не имеет доступа к информационной базе.';
										|en = 'This user is not allowed to access the infobase.'; fa = 'This user is not allowed to access the infobase.';
										|it = 'L''utente indicato non ha accesso al database informatico.';
										|pl = 'Wskazany użytkownik nie ma dostępu do bazy informacyjnej.';
										|tr = 'Bu kullanıcının Infobase erişimi yok.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
		If Not Users.IsFullUser(IBUser, True) Then
			Common.MessageToUser(NStr("vi = 'Người sử dụng không có quyền quản trị.';
										|ru = 'У пользователя нет административных прав.';
										|en = 'This user has no administrative rights.'; fa = 'This user has no administrative rights.';
										|it = 'L''utente non ha permessi di amministratore.';
										|pl = 'Użytkownik nie ma uprawnień administracyjnych.';
										|tr = 'Kullanıcının yönetici yetkileri yok.'"),,
				FieldName,,Cancel);
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AttachmentTypeOnChange(Item)
	
	Items.ConnectionTypeGroup.CurrentPage = ?(AttachmentType = "COM", Items.COMGroup, Items.RASGroup);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	
	ClearMessages();
	
	If Not CheckFillingAtServer() Then
		Return;
	EndIf;
	
	// Populate the settings structure.
	FillPropertyValues(AdministrationParameters, ThisObject);
	
	CheckAdministrationParameters(AdministrationParameters);
	
	SaveConnectionParameters();
	
	// Restore password values.
	FillPropertyValues(AdministrationParameters, ThisObject);
	
	Close(AdministrationParameters);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function CheckFillingAtServer()
	
	Return CheckFilling();
	
EndFunction

&AtServer
Procedure SaveConnectionParameters()
	
	// Saving the parameters to a constant, clearing the passwords.
	StandardSubsystemsServer.SetAdministrationParameters(AdministrationParameters);
	
EndProcedure

&AtServer
Procedure GetIBAdministrator(IBUser = Undefined)
	
	If Common.SeparatedDataUsageAvailable() Then
		If ValueIsFilled(IBAdministrator) Then
			IBUser = InfoBaseUsers.FindByUUID(
				Common.ObjectAttributeValue(IBAdministrator, "IBUserID"));
		Else
			IBUser = Undefined;
		EndIf;
		InfobaseAdministratorName = ?(IBUser = Undefined, "", IBUser.Name);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAdministrationParameters(AdministrationParameters)
	
	If CommonClient.FileInfobase()
		And AttachmentType = "COM" Then
		
		Notification = New CallbackDescription("CheckAdministrationParametersAfterCheckCOMConnector", ThisObject);
		CommonClient.RegisterCOMConnector(False, Notification);
	Else 
		CheckAdministrationParametersAfterCheckCOMConnector(True, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckAdministrationParametersAfterCheckCOMConnector(IsRegistered, Context) Export
	
	If IsRegistered Then 
		ValidateAdministrationParametersAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure ValidateAdministrationParametersAtServer()
	
	If Common.FileInfobase() Then
		ValidateFileInfobaseAdministrationParameters();
	Else 
		ClusterAdministration.CheckAdministrationParameters(AdministrationParameters,,
			Parameters.PromptForClusterAdministrationParameters, Parameters.PromptForIBAdministrationParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure IsNecessaryToInputAdministrationParameters()
	
	AdministrationParametersInputRequired = True;
	
	If Parameters.PromptForIBAdministrationParameters And Not Parameters.PromptForClusterAdministrationParameters Then
		
		UsersCount = InfoBaseUsers.GetUsers().Count();
		
		If UsersCount > 0 Then
			
			// Calculate the up-to-date username even if it was changed in the current session.
			// (For example, when the infobase is accessed via an external session.)
			// In other cases, get "InfobaseUsers.CurrentUser".
			CurrentUser = InfoBaseUsers.FindByUUID(
				InfoBaseUsers.CurrentUser().UUID);
			
			If CurrentUser = Undefined Then
				CurrentUser = InfoBaseUsers.CurrentUser();
			EndIf;
			
			If CurrentUser.StandardAuthentication And Not CurrentUser.PasswordIsSet 
				And Users.IsFullUser(CurrentUser, True) Then
				
				AdministrationParameters.InfobaseAdministratorName = CurrentUser.Name;
				AdministrationParameters.InfobaseAdministratorPassword = "";
				
				AdministrationParametersInputRequired = False;
				
			EndIf;
			
		ElsIf UsersCount = 0 Then
			
			AdministrationParameters.InfobaseAdministratorName = "";
			AdministrationParameters.InfobaseAdministratorPassword = "";
			
			AdministrationParametersInputRequired = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ValidateFileInfobaseAdministrationParameters()
	
	If Parameters.PromptForIBAdministrationParameters Then
		
		// Connection check is not performed for the base versions.
		If StandardSubsystemsServer.IsBaseConfigurationVersion() 
			Or StandardSubsystemsServer.IsTrainingPlatform() Then
			Return;
		EndIf;
		
		ConnectionParameters = CommonClientServer.ParametersStructureForExternalConnection();
		ConnectionParameters.InfobaseDirectory = StrSplit(InfoBaseConnectionString(), """")[1];
		ConnectionParameters.UserName = InfobaseAdministratorName;
		ConnectionParameters.UserPassword = InfobaseAdministratorPassword;
		
		Result = Common.EstablishExternalConnectionWithInfobase(ConnectionParameters);
		
		If Result.Join = Undefined Then
			Raise Result.BriefErrorDetails;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion