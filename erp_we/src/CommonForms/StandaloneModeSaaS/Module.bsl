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
	
	// Only users with full access rights can create and disable standalone workstations.
	If Not Users.IsFullUser() Then
		
		Raise NStr("vi = 'Không đủ quyền để tùy chỉnh làm việc độc lập.';
					|ru = 'Недостаточно прав для настройки автономной работы.';
					|en = 'Insufficient rights for standalone mode setup.'; fa = 'Insufficient rights for standalone mode setup.';
					|it = 'Diritti insufficienti per l''impostazione di lavoro autonomo.';
					|pl = 'Niewystarczające uprawnienia do konfiguracji pracy offline.';
					|tr = 'Tek başına modu yapılandırmak için yetkiler yetersiz.'");
		
	ElsIf Not StandaloneModeInternal.StandaloneModeSupported() Then
		
		Raise NStr("vi = 'Không cho phép tính năng làm việc độc lập trong ứng dụng.';
					|ru = 'Возможность автономной работы в приложении не предусмотрена.';
					|en = 'The application doesn''t support standalone mode.'; fa = 'The application doesn''t support standalone mode.';
					|it = 'Возможность автономной работы в приложении не предусмотрена.';
					|pl = 'The application doesn''t support standalone mode.';
					|tr = 'Uygulamada çevrimdışı çalışma imkanı yoktur.'");
		
	EndIf;
	
	UpdateStandaloneModeMonitorAtServer();
	
	BigFilesTransferSupported = StandaloneModeInternal.BigFilesTransferSupported();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("UpdateStandaloneModeMonitor", 60);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If    EventName = "CreateStandaloneWorkstation"
		Or EventName = "Write_StandaloneWorkstation"
		Or EventName = "DeleteStandaloneWorkstation" Then
		
		UpdateStandaloneModeMonitor();
		
	ElsIf EventName = "DataExchangeResultFormClosed" Then
		
		UpdateSwitchToConflictsTitle();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateStandaloneWorkstation(Command)
	
	Notification = New CallbackDescription("CreateStandaloneWorkstationCompletion", ThisObject);
	
	If BigFilesTransferSupported Then
		FileSystemClient.AttachFileOperationsExtension(Notification, "", False);
	Else
		RunCallback(Notification, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure StopSynchronizationWithStandaloneWorkstation(Command)
	
	DisconnectStandaloneWorkstation(StandaloneWorkstation);
	
EndProcedure

&AtClient
Procedure StopSynchronizationWithStandaloneWorkstationInList(Command)
	
	CurrentData = Items.StandaloneWorkstationsList.CurrentData;
	
	If CurrentData <> Undefined Then
		
		DisconnectStandaloneWorkstation(CurrentData.StandaloneWorkstation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeStandaloneWorkstation(Command)
	
	If StandaloneWorkstation <> Undefined Then
		
		ShowValue(, StandaloneWorkstation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeStandaloneWorkstationInList(Command)
	
	CurrentData = Items.StandaloneWorkstationsList.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ShowValue(, CurrentData.StandaloneWorkstation);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateStandaloneModeMonitor();
	
EndProcedure

&AtClient
Procedure StandaloneWorkstationsListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, Items.StandaloneWorkstationsList.CurrentData.StandaloneWorkstation);
	
EndProcedure

&AtClient
Procedure HowToInstallOrUpdate1CEnterprisePlatfomVersion(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TemplateName", "HowToInstallOrUpdate1CEnterprisePlatfomVersion");
	FormParameters.Insert("Title", NStr("vi = 'Làm thế nào để cài đặt hoặc cập nhật phiên bản nền tảng 1C:Enterprise';
										|ru = 'Как установить или обновить версию платформы 1С:Предприятие';
										|en = 'How to install or update 1C:Enterprise platform'; fa = 'نحوه نصب یا به‌روزرسانی پلتفرم 1C:Enterprise';
										|it = 'Come impostare o aggiornare la versione della piattaforma 1C:Enterprise';
										|pl = 'Jak zainstalować lub zaktualizować wersję platformy 1C:Enterprise';
										|tr = '1C:Enterprise platformunun sürümü nasıl yüklenir veya güncellenir'"));
	
	OpenForm("DataProcessor.StandaloneWorkstationCreationWizard.Form.AdditionalDetails", FormParameters, ThisObject, "HowToInstallOrUpdate1CEnterprisePlatfomVersion");
	
EndProcedure

&AtClient
Procedure HowToConfigureStandaloneWorkstation(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TemplateName", "SWSetupInstruction");
	FormParameters.Insert("Title", NStr("vi = 'Làm thế nào để tùy chỉnh chỗ làm việc độc lập';
										|ru = 'Как настроить автономное рабочее место';
										|en = 'How to set up a standalone workstation'; fa = 'How to set up a standalone workstation';
										|it = 'Come impostare la postazione di lavoro autonoma';
										|pl = 'Jak ustawić miejsce pracy offline';
										|tr = 'Çevrimdışı çalışma alanı nasıl ayarlanır'"));
	
	OpenForm("DataProcessor.StandaloneWorkstationCreationWizard.Form.AdditionalDetails", FormParameters, ThisObject, "SWSetupInstruction");
	
EndProcedure

&AtClient
Procedure GoToConflicts(Command)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("ExchangeNodes", UsedNodesArray(StandaloneWorkstation, StandaloneWorkstationsList));
	
	OpenForm("InformationRegister.DataExchangeResults.Form.Form", OpeningParameters);
	
EndProcedure

&AtClient
Procedure DataToSendComposition(Command)
	
	CurrentPage = Items.StandaloneMode.CurrentPage;
	StandaloneNode  = Undefined;
	
	If CurrentPage = Items.SingleStandaloneWorkstation Then
		StandaloneNode = StandaloneWorkstation;
		
	ElsIf CurrentPage = Items.MultipleStandaloneWorkstations Then
		CurrentData = Items.StandaloneWorkstationsList.CurrentData;
		If CurrentData <> Undefined Then
			StandaloneNode = CurrentData.StandaloneWorkstation;
		EndIf;
		
	EndIf;
		
	If ValueIsFilled(StandaloneNode) Then
		DataExchangeClient.OpenCompositionOfDataToSend(StandaloneNode);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CreateStandaloneWorkstationCompletion(ExtensionAttached, AdditionalParameters) Export
	
	If ExtensionAttached Then
		OpenForm("DataProcessor.StandaloneWorkstationCreationWizard.Form.SetupSaaS", , ThisObject, "1");
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateStandaloneModeMonitorAtServer()
	
	SetPrivilegedMode(True);
	
	StandaloneWorkstationsCount = StandaloneModeInternal.StandaloneWorkstationsCount();
	UpdateSwitchToConflictsTitle();
	
	If StandaloneWorkstationsCount = 0 Then
		
		Items.StandaloneModeNotConfigured.Visible = True;
		
		Items.StandaloneMode.CurrentPage = Items.StandaloneModeNotConfigured;
		Items.SingleStandaloneWorkstation.Visible = False;
		Items.MultipleStandaloneWorkstations.Visible = False;
		
	ElsIf StandaloneWorkstationsCount = 1 Then
		
		Items.SingleStandaloneWorkstation.Visible = True;
		
		Items.StandaloneMode.CurrentPage = Items.SingleStandaloneWorkstation;
		Items.StandaloneModeNotConfigured.Visible = False;
		Items.MultipleStandaloneWorkstations.Visible = False;
		
		StandaloneWorkstation = StandaloneModeInternal.StandaloneWorkstation();
		StandaloneWorkstationsList.Clear();
		
		Items.LastSynchronizationInfo.Title = DataExchangeServer.SynchronizationDatePresentation(
			StandaloneModeInternal.LastSuccessfulSynchronizationDate(StandaloneWorkstation)) + ".";
		
		Items.DataTransferRestrictionsDetails.Title = StandaloneModeInternal.DataTransferRestrictionsDetails(StandaloneWorkstation);
		
	ElsIf StandaloneWorkstationsCount > 1 Then
		
		Items.MultipleStandaloneWorkstations.Visible = True;
		
		Items.StandaloneMode.CurrentPage = Items.MultipleStandaloneWorkstations;
		Items.StandaloneModeNotConfigured.Visible = False;
		Items.SingleStandaloneWorkstation.Visible = False;
		
		StandaloneWorkstation = Undefined;
		StandaloneWorkstationsList.Load(StandaloneModeInternal.StandaloneWorkstationsMonitor());
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateSwitchToConflictsTitle()
	
	If DataExchangeCached.VersioningUsed() Then
		
		UsedNodesArray = UsedNodesArray(StandaloneWorkstation, StandaloneWorkstationsList);
		TitleStructure = InformationRegisters.DataExchangeResults.TheNumberOfWarningsForTheFormElement(UsedNodesArray);
		
		FillPropertyValues (Items.GoToConflicts, TitleStructure);
		FillPropertyValues (Items.GoToConflicts1, TitleStructure);
		
	Else
		
		Items.GoToConflicts.Visible = False;
		Items.GoToConflicts1.Visible = False;
		
	EndIf;
	
EndProcedure

&AtClient
Function GetCurrentRowIndex()
	
	// Function return value.
	RowIndex = Undefined;
	
	// Positioning the mouse pointer upon the monitor update
	CurrentData = Items.StandaloneWorkstationsList.CurrentData;
	
	If CurrentData <> Undefined Then
		
		RowIndex = StandaloneWorkstationsList.IndexOf(CurrentData);
		
	EndIf;
	
	Return RowIndex;
EndFunction

&AtClient
Procedure ExecuteCursorPositioning(RowIndex)
	
	If RowIndex <> Undefined Then
		
		// Checking the mouse pointer position once new data is received
		If StandaloneWorkstationsList.Count() <> 0 Then
			
			If RowIndex > StandaloneWorkstationsList.Count() - 1 Then
				
				RowIndex = StandaloneWorkstationsList.Count() - 1;
				
			EndIf;
			
			// Place the mouse pointer.
			Items.StandaloneWorkstationsList.CurrentRow = StandaloneWorkstationsList[RowIndex].GetID();
			
		EndIf;
		
	EndIf;
	
	// If setting the current row by TableName value failed, the first row is set as the current one
	If Items.StandaloneWorkstationsList.CurrentRow = Undefined
		And StandaloneWorkstationsList.Count() <> 0 Then
		
		Items.StandaloneWorkstationsList.CurrentRow = StandaloneWorkstationsList[0].GetID();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateStandaloneModeMonitor()
	
	RowIndex = GetCurrentRowIndex();
	
	UpdateStandaloneModeMonitorAtServer();
	
	// Positioning the mouse pointer.
	ExecuteCursorPositioning(RowIndex);
	
EndProcedure

&AtClientAtServerNoContext
Function UsedNodesArray(StandaloneWorkstation, StandaloneWorkstationsList)
	
	ExchangeNodes = New Array;
	
	If ValueIsFilled(StandaloneWorkstation) Then
		ExchangeNodes.Add(StandaloneWorkstation);
	Else
		For Each NodeRow In StandaloneWorkstationsList Do
			ExchangeNodes.Add(NodeRow.StandaloneWorkstation);
		EndDo;
	EndIf;
	
	Return ExchangeNodes;
	
EndFunction

&AtClient
Procedure DisconnectStandaloneWorkstation(StandaloneWorkstationToDisconnect)
	
	FormParameters = New Structure("StandaloneWorkstation", StandaloneWorkstationToDisconnect);
	
	OpenForm("CommonForm.StandaloneWorkstationDisconnection", FormParameters, ThisObject, StandaloneWorkstationToDisconnect);
	
EndProcedure

#EndRegion
