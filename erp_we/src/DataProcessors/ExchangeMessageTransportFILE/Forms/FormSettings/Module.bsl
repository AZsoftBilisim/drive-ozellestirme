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
	
	ExchangeMessagesTransport.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	SetVisibilityAvailability();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataExchangeDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	DataExchangeClient.FileDirectoryChoiceHandler(Object, "DataExchangeDirectory", StandardProcessing);
EndProcedure

&AtClient
Procedure DataExchangeDirectoryOpening(Item, StandardProcessing)
	DataExchangeClient.FileOrDirectoryOpenHandler(Object, "DataExchangeDirectory", StandardProcessing)
EndProcedure

&AtClient
Procedure CompressOutgoingMessageFileOnChange(Item)
	SetVisibilityAvailability();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If CheckFilling() Then
		
		ClosingResult = ResultOfClosureOnServer();
		Close(ClosingResult);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TestConnection(Command)
	
	ClosingNotification1 = New CallbackDescription("TestConnectionCompletion", ThisObject);
	If CommonClient.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Queries = CreateRequestToUseExternalResources(Object);
		
		ModuleSafeModeManagerClient = CommonClient.CommonModule("SafeModeManagerClient");
		ModuleSafeModeManagerClient.ApplyExternalResourceRequests(Queries, ThisObject, ClosingNotification1);
	Else
		RunCallback(ClosingNotification1, DialogReturnCode.OK);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ResultOfClosureOnServer()
	
	Return ExchangeMessagesTransport.ResultOfClosingTransportForm(ThisForm);
	
EndFunction

&AtServerNoContext
Function CreateRequestToUseExternalResources(Val Object)
	
	PermissionsRequests = New Array;
	Permissions = New Array;
	
	If Not IsBlankString(Object.DataExchangeDirectory) Then
		
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		
		Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
			Object.DataExchangeDirectory, True, True));
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
		
	EndIf;
	
	Return PermissionsRequests;
	
EndFunction

&AtClient
Procedure TestConnectionCompletion(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.OK Then
		
		ConnectionIsSet = False;
		TestConnectionAtServer(ConnectionIsSet);
		
		WarningText = ?(ConnectionIsSet, NStr("vi = 'Đã kết nối thành công.';
												|ru = 'Подключение успешно установлено.';
												|en = 'Connection established.'; fa = 'Connection established.';
												|it = 'Connessione stabilita con successo.';
												|pl = 'Połączenie zostało pomyślnie nawiązane.';
												|tr = 'Bağlantı başarıyla kuruldu.'"),
								NStr("vi = 'Không thể thiết lập kết nối.';
									|ru = 'Не удалось установить подключение.';
									|en = 'Cannot establish connection.'; fa = 'Cannot establish connection.';
									|it = 'Connessione fallita.';
									|pl = 'Połączenie nieudane.';
									|tr = 'Bağlantı yapılamadı.'"));
		ShowMessageBox(, WarningText);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(ConnectionIsSet)
	
	SetPrivilegedMode(True);
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	// Fill password.
	ExchangeMessagesTransport.FillInSettingsFromSecureStorageForForm(ThisForm, DataProcessorObject);
	
	// Check the connection.
	ConnectionIsSet = DataProcessorObject.ConnectionIsSet();
	If Not ConnectionIsSet Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessage
			+ Chars.LF + NStr("vi = 'Xem thông tin về lỗi kỹ thuật trong nhật ký sự kiện.';
								|ru = 'Техническую информацию об ошибке см. в журнале регистрации.';
								|en = 'See the event log for details.'; fa = 'See the event log for details.';
								|it = 'Per i dettagli tecnici sull''errore consultare il registro di log.';
								|pl = 'See the event log for details.';
								|tr = 'Olay günlüğündeki hata hakkındaki teknik bilgilere bakın.'");
		
		Common.MessageToUser(ErrorMessage, , , , Cancel);
		
	EndIf;
		
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure SetVisibilityAvailability()
	Items.ArchivePasswordExchangeMessages.Enabled = Object.CompressOutgoingMessageFile;
EndProcedure

#EndRegion

