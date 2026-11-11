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
	
	SetFormItemsVisibility();
	
	If ValueIsFilled(Record.DefaultExchangeMessagesTransportKind) Then
		
		PageName = "TransportSettings[TransportKind]";
		PageName = StrReplace(PageName, "[TransportKind]"
		, Common.EnumerationValueName(Record.DefaultExchangeMessagesTransportKind));
		
		If Items[PageName].Visible Then
			
			Items.TransportKindsPages.CurrentPage = Items[PageName];
			
		EndIf;
	
	EndIf;
	
	If ValueIsFilled(Record.CorrespondentEndpoint) Then
		SetPrivilegedMode(True);
		Passwords = Common.ReadDataFromSecureStorage(Record.CorrespondentEndpoint, "FTPConnectionDataAreasPassword, ArchivePasswordDataAreaExchangeMessages");
		FTPConnectionPassword = ?(ValueIsFilled(Passwords.FTPConnectionDataAreasPassword), UUID, "");
		ArchivePasswordExchangeMessages = ?(ValueIsFilled(Passwords.ArchivePasswordDataAreaExchangeMessages), UUID, "");
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	SetPrivilegedMode(True);
	If FTPConnectionPasswordChanged Then
		Common.WriteDataToSecureStorage(Record.CorrespondentEndpoint, FTPConnectionPassword, "FTPConnectionDataAreasPassword");
	EndIf;
	If ExchangeMessageArchivePasswordChanged Then
		Common.WriteDataToSecureStorage(Record.CorrespondentEndpoint, ArchivePasswordExchangeMessages, "ArchivePasswordDataAreaExchangeMessages");
	EndIf;
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FILEDataExchangeDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	DataExchangeClient.FileDirectoryChoiceHandler(Record, "FILEDataExchangeDirectory", StandardProcessing);
	
EndProcedure

&AtClient
Procedure FILEDataExchangeDirectoryOpening(Item, StandardProcessing)
	
	DataExchangeClient.FileOrDirectoryOpenHandler(Record, "FILEDataExchangeDirectory", StandardProcessing)
	
EndProcedure

&AtClient
Procedure ArchivePasswordExchangeMessagesOnChange(Item)
	ExchangeMessageArchivePasswordChanged = True;
EndProcedure

&AtClient
Procedure FTPConnectionPasswordOnChange(Item)
	FTPConnectionPasswordChanged = True;
EndProcedure

&AtClient
Procedure ArchivePasswordExchangeMessages1OnChange(Item)
	ExchangeMessageArchivePasswordChanged = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TestFILEConnection(Command)
	
	TestConnection("FILE");
	
EndProcedure

&AtClient
Procedure TestFTPConnection(Command)
	
	TestConnection("FTP");
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure TestConnection(TransportKindAsString)
	
	Cancel = False;
	
	ClearMessages();
	
	TestConnectionAtServer(Cancel, TransportKindAsString);
	
	WarningText = ?(Cancel, NStr("vi = 'Không thể thiết lập kết nối.';
								|ru = 'Не удалось установить подключение.';
								|en = 'Cannot establish connection.'; fa = 'Cannot establish connection.';
								|it = 'Connessione fallita.';
								|pl = 'Połączenie nieudane.';
								|tr = 'Bağlantı yapılamadı.'"), NStr("vi = 'Đã kết nối thành công.';
																				|ru = 'Подключение успешно установлено.';
																				|en = 'Connection established.'; fa = 'Connection established.';
																				|it = 'Connessione stabilita con successo.';
																				|pl = 'Połączenie zostało pomyślnie nawiązane.';
																				|tr = 'Bağlantı başarıyla kuruldu.'"));
	ShowMessageBox(, WarningText);
	
EndProcedure

&AtServer
Procedure TestConnectionAtServer(Cancel, TransportKindAsString)
	
	PasswordsToCheck = Undefined;
	
	If FTPConnectionPasswordChanged Then
		PasswordsToCheck = New Structure("FTPConnectionPassword", FTPConnectionPassword);
	EndIf;
	
	ExchangeMessagesTransport.CheckExchangeMessageTransportDataProcessorAttachment(
		Cancel, Record, Enums.ExchangeMessagesTransportTypes[TransportKindAsString], , PasswordsToCheck);
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	UsedTransports = New Array;
	UsedTransports.Add(Enums.ExchangeMessagesTransportTypes.FILE);
	UsedTransports.Add(Enums.ExchangeMessagesTransportTypes.FTP);
	
	Items.DefaultExchangeMessagesTransportKind.ChoiceList.Clear();
	
	For Each Item In UsedTransports Do
		
		Items.DefaultExchangeMessagesTransportKind.ChoiceList.Add(Item, String(Item));
		
	EndDo;
	
	Items.TestFTPConnection.Visible = False;
	
EndProcedure

#EndRegion
