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
	
	// Verify that the form is opened with the required parameters
	If Not Parameters.Property("ExchangeNode") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'", Common.DefaultLanguageCode());
		
	EndIf;
	
	ExchangeNode = Parameters.ExchangeNode;
	
	PeerInfobaseName = String(ExchangeNode);
	
	Items.LabelWaitDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.LabelWaitDecoration.Title, PeerInfobaseName);
	
	Items.ErrorLabelDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.ErrorLabelDecoration.Title, PeerInfobaseName);
	
	Title = NStr("vi = 'Kết nhập tham số trao đổi dữ liệu';
				|ru = 'Загрузка параметров обмена данными';
				|en = 'Import data exchange parameters'; fa = 'Import data exchange parameters';
				|it = 'Il download dei parametri di scambio dati';
				|pl = 'Pobieranie parametrów wymiany danych';
				|tr = 'Veri alışverişi parametrelerin içe aktarılması'");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Items.PanelMain.CurrentPage = Items.TimeConsumingOperationPage;
	Items.FormDoneCommand.DefaultButton = False;
	Items.FormDoneCommand.Enabled = False;
	
	AttachIdleHandler("OnStartImportXDTOSettings", 1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DoneCommand(Command)
	
	Result = New Structure;
	Result.Insert("ContinueSetup",            False);
	Result.Insert("DataReceivedForMapping", False);
	
	Close(Result);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OnStartImportXDTOSettings()
	
	ContinueWait = True;
	OnStartImportXDTOSettingsAtServer(ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			IdleHandlerParameters);
			
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		OnCompleteImportXDTOSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForImportXDTOSettings()
	
	ContinueWait = False;
	OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
		
		AttachIdleHandler("OnWaitForImportXDTOSettings",
			IdleHandlerParameters.CurrentInterval, True);
	Else
		IdleHandlerParameters = Undefined;
		OnCompleteImportXDTOSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteImportXDTOSettings()
	
	ErrorMessage = "";
	SettingsImported = False;
	DataReceivedForMapping = False;
	OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage);
	
	If SettingsImported Then
		
		Result = New Structure;
		Result.Insert("ContinueSetup",            True);
		Result.Insert("DataReceivedForMapping", DataReceivedForMapping);
		
		Close(Result);
	Else
		Items.PanelMain.CurrentPage = Items.ErrorPage;
		Items.FormDoneCommand.DefaultButton = True;
		Items.FormDoneCommand.Enabled = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartImportXDTOSettingsAtServer(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ImportSettings = New Structure;
	ImportSettings.Insert("ExchangeNode", ExchangeNode);
		
	ModuleSetupWizard.OnStartImportXDTOSettings(ImportSettings, HandlerParameters, ContinueWait);
	
EndProcedure
	
&AtServerNoContext
Procedure OnWaitImportXDTOSettingsAtServer(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	ContinueWait = False;
	ModuleSetupWizard.OnWaitForImportXDTOSettings(HandlerParameters, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnCompleteImportXDTOSettingsAtServer(HandlerParameters, SettingsImported, DataReceivedForMapping, ErrorMessage)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteImportXDTOSettings(HandlerParameters, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		SettingsImported = False;
		DataReceivedForMapping = False;
		ErrorMessage = CompletionStatus.ErrorMessage;
	Else
		SettingsImported = CompletionStatus.Result.SettingsImported;
			
		If Not SettingsImported Then
			DataReceivedForMapping = False;
			ErrorMessage = CompletionStatus.Result.ErrorMessage;
		Else
			DataReceivedForMapping = CompletionStatus.Result.DataReceivedForMapping;
		EndIf;
	EndIf;
	
EndProcedure 

#EndRegion
