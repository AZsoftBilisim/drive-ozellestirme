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
	
	FullMetadataName = FormAttributeToValue("Object").Metadata().FullName();
	
	For Each IntegrationServiceMetadata In Metadata.IntegrationServices Do
		IntegrationService = IntegrationServicesList.Add();
		IntegrationService.Name = IntegrationServiceMetadata.Name;
		IntegrationService.Presentation = IntegrationServiceMetadata.Presentation();
		IntegrationService.ExternalIntegrationServiceAddress = IntegrationServiceMetadata.ExternalIntegrationServiceAddress;
	EndDo;
	
	RefreshStatus();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIntegrationServices

&AtClient
Procedure IntegrationServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenIntegrationServiceSettings();
	
EndProcedure

&AtClient
Procedure IntegrationServicesBeforeRowChange(Item, Cancel)
	
	If Item.CurrentItem.Name = "IntegrationServicesIsActive" Then
		Item.CurrentData.Running = Not Item.CurrentData.Running;
	Else
		Cancel = True;
		OpenIntegrationServiceSettings();
	EndIf;
	
EndProcedure

&AtClient
Procedure IntegrationServicesIsActiveOnChange(Item)
	
	CurrentData = Items.IntegrationServices.CurrentData;

	SetActiveInIntegrationService(CurrentData.Name, CurrentData.Running);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetActive(Command)
	
	SetActiveAtServer(True);
	
EndProcedure

&AtClient
Procedure RemoveActivity(Command)
	
	SetActiveAtServer(False);
	
EndProcedure

&AtClient
Procedure ChangeSettings(Command)
	
	If Items.IntegrationServices.CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenIntegrationServiceSettings();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure RefreshStatus()
	
	For Each IntegrationService In IntegrationServicesList Do
        IntegrationServiceManager = IntegrationServices[IntegrationService.Name];
		MetadataIntegrationService = Metadata.IntegrationServices[IntegrationService.Name];
		IntegrationService.Running = IntegrationServiceManager.GetActive();
		IntegrationServiceSettings = IntegrationServiceManager.GetSettings();
		
		If IntegrationServiceSettings.ExternalIntegrationServiceAddress = "" Then
			IntegrationService.ExternalIntegrationServiceAddress = MetadataIntegrationService.ExternalIntegrationServiceAddress; 
		Else
			IntegrationService.ExternalIntegrationServiceAddress = IntegrationServiceSettings.ExternalIntegrationServiceAddress;
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure SetActiveInIntegrationService(Val Name, Val Active)
	
	IntegrationServiceManager = IntegrationServices[Name];
	IntegrationServiceManager.SetActive(Active);

EndProcedure

&AtServer
Procedure SetActiveAtServer(Val Active)

	For Each TableRow In IntegrationServicesList Do
		SetActiveInIntegrationService(TableRow.Name, Active);
	EndDo;
	
	RefreshStatus();
	
EndProcedure

&AtClient
Procedure OpenIntegrationServiceSettings()
	
	FormParameters = New Structure;
	FormParameters.Insert("IntegrationServiceName", Items.IntegrationServices.CurrentData.Name);
	
	CallbackDescription = New CallbackDescription("FormClosingCompletion", ThisObject);
	OpenForm(FullMetadataName + ".Form.IntegrationServiceSettingsForm", 
		FormParameters,
		ThisObject,,,,
		CallbackDescription);
	
EndProcedure

&AtClient
Procedure FormClosingCompletion(Result, AdditionalParameters = Undefined) Export
	
	If Result = DialogReturnCode.OK Then
		RefreshStatus();
	EndIf;
	
EndProcedure

#EndRegion


