#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	IsFullUser = Users.IsFullUser(Undefined, True);
	Items.MaximumBatch.ReadOnly = Not IsFullUser;
	ReadOnly = Not IsFullUser;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.BeforeWriteAtServer(CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Core
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtClient
Procedure Attachable_Opening(Item, StandardProcessing)
	
	// StandardSubsystems.Core
	NationalLanguageSupportClient.OnOpen(ThisObject, Object, Item, StandardProcessing);
	// End StandardSubsystems.Core
	
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion
