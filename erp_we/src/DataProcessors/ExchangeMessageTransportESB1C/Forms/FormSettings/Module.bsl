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
	
	FillInIntegrationService();
	FillInListOfChannels();
	
	ThereIsSubsystemRoutineTasks = 
		Common.SubsystemExists("StandardSubsystems.ScheduledJobs");
		
	ScheduledJobID = ScheduledJobsServer.UUID(
		Metadata.ScheduledJobs.IntegrationServicesProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure IntegrationServiceOnChange(Item)
	
	FillInListOfChannels();
	
EndProcedure

&AtClient
Procedure DecorationPreSettingsURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "IntegrationServices" Then
	
		OpenForm("DataProcessor.ExchangeMessageTransportESB1C.Form.IntegrationServiceManagementForm");
	
	ElsIf FormattedStringURL = "ScheduledJob" Then
		
		If ThereIsSubsystemRoutineTasks Then
			
			FormParameters = New Structure;
			FormParameters.Insert("Action", "Change");
			FormParameters.Insert("Id", ScheduledJobID);
		
			NameOfRoutineTaskForm = "DataProcessor.ScheduledAndBackgroundJobs.Form.ScheduledJob";
			OpenForm(NameOfRoutineTaskForm, FormParameters, ThisObject);
		
		Else
			
			FormParameters = New Structure;
			FormParameters.Insert("Id", ScheduledJobID);
			
			NameOfRoutineTaskForm = "DataProcessor.ExchangeMessageTransportESB1C.Form.ScheduledJobSetupForm";
			OpenForm(NameOfRoutineTaskForm, FormParameters, ThisObject);
		
		EndIf;
		
	ElsIf FormattedStringURL = "Help" Then
		
		OpenHelp("DataProcessor.ExchangeMessageTransportESB1C");
		
	EndIf;
	
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
	
	ConnectionIsSet = False;
	TestConnectionAtServer(ConnectionIsSet);
	
	If ConnectionIsSet Then
		
		WarningText = NStr("vi = 'Đã kết nối thành công.';
							|ru = 'Подключение успешно установлено.';
							|en = 'Connection established.'; fa = 'Connection established.';
							|it = 'Connessione stabilita con successo.';
							|pl = 'Połączenie zostało pomyślnie nawiązane.';
							|tr = 'Bağlantı başarıyla kuruldu.'", 
			CommonClient.DefaultLanguageCode());
			
		ShowMessageBox(, WarningText);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ResultOfClosureOnServer()
	
	Return ExchangeMessagesTransport.ResultOfClosingTransportForm(ThisObject);
	
EndFunction

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
Procedure FillInIntegrationService()
	
	For Each IntegrationService In Metadata.IntegrationServices Do
		
		Items.IntegrationService.ChoiceList.Add(IntegrationService.Name);
		
	EndDo;
	
	List = Items.IntegrationService.ChoiceList;
	If Not ValueIsFilled(Object.IntegrationService)
		And List.Count() = 1 Then
		
		Object.IntegrationService = List[0].Value;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfChannels()
	
	List = Items.SendingChannel.ChoiceList;
	List.Clear();
	
	If ValueIsFilled(Object.IntegrationService) Then
		
		For Each Canal In Metadata.IntegrationServices[Object.IntegrationService].IntegrationServiceChannels Do
			If Canal.MessageDirection = Metadata.ObjectProperties.IntegrationServiceChannelMessageDirection.Send Then
				List.Add(Canal.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	If List.Count() = 1 Then
		Object.SendingChannel = List[0].Value;
	EndIf;
	
	List = Items.ReceiptChannel.ChoiceList;
	List.Clear();
	
	If ValueIsFilled(Object.IntegrationService) Then
		
		For Each Canal In Metadata.IntegrationServices[Object.IntegrationService].IntegrationServiceChannels Do
			If Canal.MessageDirection = Metadata.ObjectProperties.IntegrationServiceChannelMessageDirection.Receive Then
				List.Add(Canal.Name);
			EndIf;
		EndDo;
		
	EndIf;
	
	If List.Count() = 1 Then
		Object.ReceiptChannel = List[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

