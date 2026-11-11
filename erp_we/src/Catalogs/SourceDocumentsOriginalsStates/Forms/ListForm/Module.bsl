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

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListOnChange(Item)
	
	RefreshReusableValues();
	Notify("Write_SourceDocumentsOriginalsStates");
	
EndProcedure

#EndRegion


#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands

// Parameters:
//  Command - FormCommand
//
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export

    ExecuteCommandAtServer(ExecutionParameters);

EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)

    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);

EndProcedure
&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
//End StandardSubsystems.AttachableCommands

#EndRegion
