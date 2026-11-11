///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExchangeMessagesTransport.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	InitializeFormAttributes();
	
	SetVisibilityAvailability();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

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

&AtClient
Procedure GetToken(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ClientID", Object.ClientID);
	FormParameters.Insert("ClientSecret", Object.ClientSecret);
	
	Notification = New CallbackDescription("GetTokenCompletion", ThisObject);
	
	OpenForm("DataProcessor.ExchangeMessageTransportYandexDisk.Form.TokenReceiptForm",
		FormParameters,,,,, Notification, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure
	
&AtClient
Procedure GetTokenCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FillPropertyValues(Object, Result);
	
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
	
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	Permissions.Add(ModuleSafeModeManager.PermissionToUseInternetResource("HTTPS", "cloud-api.yandex.net"));
	
	PermissionsRequests.Add(
		ModuleSafeModeManager.RequestToUseExternalResources(Permissions));
	
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
	
	TransportSettings = Undefined;
	Parameters.Property("TransportSettings", TransportSettings);
	If ValueIsFilled(TransportSettings) Then
		Items.AccessSettings.Hide();
	EndIf;
		
EndProcedure

&AtServer
Procedure InitializeFormAttributes()
	
	If Not Parameters.Property("TransportSettings") Then
		Object.CompressOutgoingMessageFile = True;
	EndIf;
		
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
