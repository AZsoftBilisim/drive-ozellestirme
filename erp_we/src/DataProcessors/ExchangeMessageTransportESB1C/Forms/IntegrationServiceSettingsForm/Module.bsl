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
	
	If Not ValueIsFilled(Parameters.IntegrationServiceName) Then
		
		Raise NStr("vi = 'Biểu mẫu này không được dùng để mở trực tiếp.';
					|ru = 'Эта форма не предназначена для непосредственного открытия.';
					|en = 'This is a dependent form and opens from a different form.'; fa = 'This is a dependent form and opens from a different form.';
					|it = 'Эта форма не предназначена для непосредственного открытия.';
					|pl = 'This is a dependent form and opens from a different form.';
					|tr = 'Bu form doğrudan açılmak üzere tasarlanmamıştır.'",
			Common.DefaultLanguageCode());
		
	EndIf;
	
	MetadataIntegrationServices = Metadata.IntegrationServices[Parameters.IntegrationServiceName];
	IntegrationServiceSettings  = IntegrationServices[Parameters.IntegrationServiceName].GetSettings();
	DescriptionService 		= MetadataIntegrationServices.Presentation();   
	
	If IntegrationServiceSettings.ExternalIntegrationServiceAddress = "" Then
		ExternalIntegrationServiceAddress = MetadataIntegrationServices.ExternalIntegrationServiceAddress;
	Else
		ExternalIntegrationServiceAddress = IntegrationServiceSettings.ExternalIntegrationServiceAddress;
	EndIf;
	
	ExternalIntegrationServiceUserName    = IntegrationServiceSettings.ExternalIntegrationServiceUserName;
	ExternalIntegrationServiceUserPassword = IntegrationServiceSettings.ExternalIntegrationServiceUserPassword;
	UserName 							= IntegrationServiceSettings.UserName;
	
	For Each User In InfoBaseUsers.GetUsers() Do
		Items.UserName.ChoiceList.Add(User.Name);
	EndDo;	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldSaveSettings(Command)
	
	SaveSettingsAtServer();
	
	Close(DialogReturnCode.OK);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(DialogReturnCode.Cancel);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveSettingsAtServer() 
	
	IntegrationServiceSettings = New IntegrationServiceSettings;
	IntegrationServiceSettings.ExternalIntegrationServiceAddress              = ExternalIntegrationServiceAddress;
	IntegrationServiceSettings.ExternalIntegrationServiceUserName    = ExternalIntegrationServiceUserName;
	IntegrationServiceSettings.ExternalIntegrationServiceUserPassword = ExternalIntegrationServiceUserPassword;
	IntegrationServiceSettings.UserName                             = UserName;
	
	IntegrationServices[Parameters.IntegrationServiceName].SetSettings(IntegrationServiceSettings);
	
EndProcedure

#EndRegion