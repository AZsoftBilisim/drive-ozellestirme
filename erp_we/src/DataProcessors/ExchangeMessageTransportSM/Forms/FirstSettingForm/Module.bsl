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
	
	If Not Parameters.Property("ConnectionSettings") Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters.ConnectionSettings);
	
	Parameters.Property("SettingID", SettingID);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartGetConnectionsListForConnection();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ApplicationsSaaSOnActivateRow(Item)

	CurrentData = Items.ApplicationsSaaS.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Object.InternalPublication = CurrentData.HasExchangeAdministrationManage_3_0_1_1;
	Object.Endpoint = CurrentData.Endpoint;
	Object.CorrespondentEndpoint = CurrentData.CorrespondentEndpoint;
	Object.PeerInfobaseName = CurrentData.ApplicationDescription;
	Object.CorrespondentDataArea = CurrentData.DataArea;
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	ClosingResult = ResultOfClosureOnServer();
	Close(ClosingResult);
		
EndProcedure

&AtClient
Procedure RefreshAvailableApplicationsList(Command)
	
	StartGetConnectionsListForConnection();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function ResultOfClosureOnServer()
	
	Return ExchangeMessagesTransport.ResultOfClosingTransportForm(ThisForm);
	
EndFunction

#Region GetConnectionsListForConnection

&AtClient
Procedure StartGetConnectionsListForConnection()
	
	Items.SaaSApplicationsPanel.Visible = True;
	Items.ApplicationsSaaS.Enabled = False;
	Items.SaaSApplicationsRefreshAvailableApplicationsList.Enabled = False;
	Items.InternalPublication.Enabled = False;
	Items.FormDone.Enabled = False;
	
	Items.SaaSApplicationsPanel.CurrentPage = Items.SaaSApplicationsPanelWaitPage;
	AttachIdleHandler("GetApplicationListForConnectionOnStart", 0.1, True);
	
EndProcedure

&AtClient
Procedure GetApplicationListForConnectionOnStart()
	
	ParametersOfGetApplicationsListHandler = Undefined;
	ContinueWait = False;
	
	OnStartGetConnectionsListForConnection(ContinueWait);
		
	If ContinueWait Then
		DataExchangeClient.InitIdleHandlerParameters(
			ParametersOfGetApplicationsListIdleHandler);
			
		AttachIdleHandler("OnWaitForGetApplicationListForConnection",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		OnCompleteGettingApplicationsListForConnection();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnWaitForGetApplicationListForConnection()
	
	ContinueWait = False;
	OnWaitGetConnectionsListForConnection(ParametersOfGetApplicationsListHandler, ContinueWait);
	
	If ContinueWait Then
		DataExchangeClient.UpdateIdleHandlerParameters(ParametersOfGetApplicationsListIdleHandler);
		
		AttachIdleHandler("OnWaitForGetApplicationListForConnection",
			ParametersOfGetApplicationsListIdleHandler.CurrentInterval, True);
	Else
		ParametersOfGetApplicationsListIdleHandler = Undefined;
		OnCompleteGettingApplicationsListForConnection();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnCompleteGettingApplicationsListForConnection()
	
	Cancel = False;
	OnCompleteGettingApplicationsListForConnectionAtServer(Cancel);
	
	Items.SaaSApplicationsRefreshAvailableApplicationsList.Enabled = True;
	Items.ApplicationsSaaS.Enabled = True;
	Items.InternalPublication.Enabled = True;
	Items.FormDone.Enabled = True;
	
	If Cancel Then
		Items.SaaSApplicationsPanel.CurrentPage = Items.SaaSApplicationsErrorPage;
	Else
		Items.SaaSApplicationsPanel.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnStartGetConnectionsListForConnection(ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	WizardParameters = New Structure;
	WizardParameters.Insert("Mode", "NotConfiguredExchanges");
	WizardParameters.Insert("ExchangePlanName", ExchangePlanName);
	
	If ValueIsFilled(ExchangeFormat) Then
		WizardParameters.Insert("ExchangeFormat", ExchangeFormat);
	Else
		WizardParameters.Insert("ExchangeFormat", ExchangePlanName);
	EndIf;
	WizardParameters.Insert("SettingID", SettingID);
	
	ModuleSetupWizard.OnStartGetApplicationList(WizardParameters,
		ParametersOfGetApplicationsListHandler, ContinueWait);
	
EndProcedure

&AtServerNoContext
Procedure OnWaitGetConnectionsListForConnection(HandlerParameters, ContinueWait)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		ContinueWait = False;
		Return;
	EndIf;
	
	ModuleSetupWizard.OnWaitForGetApplicationList(
		HandlerParameters, ContinueWait);
	
EndProcedure

&AtServer
Procedure OnCompleteGettingApplicationsListForConnectionAtServer(Cancel = False)
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataSynchronizationBetweenWebApplicationsSetupWizard();
	
	If ModuleSetupWizard = Undefined Then
		Cancel = True;
		Return;
	EndIf;
	
	CompletionStatus = Undefined;
	ModuleSetupWizard.OnCompleteGettingApplicationsList(
		ParametersOfGetApplicationsListHandler, CompletionStatus);
		
	If CompletionStatus.Cancel Then
		Cancel = True;
		Return;
	EndIf;
	
	ApplicationsTable = CompletionStatus.Result; // ValueTable
	
	ApplicationsTable.Columns.Add("PictureUseMode", New TypeDescription("Number"));
	ApplicationsTable.FillValues(1, "PictureUseMode"); // Web application
	ApplicationsSaaS.Load(ApplicationsTable);
	
EndProcedure

#EndRegion

#EndRegion
