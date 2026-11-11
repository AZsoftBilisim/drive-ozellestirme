
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.ChoiceMode Then
		Items.List.ChoiceMode = True;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarForm;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// Document processing processsreferences
	If Common.SubsystemExists("SalaryCadresApplications.DocumentProcessingProcessesSalary") Then
		ModuleDocumentProcessingProcessesSalary = Common.CommonModule("DocumentProcessingProcessesSalary");
		ModuleDocumentProcessingProcessesSalary.OnCreateListFormAtServer(ThisObject, "List");
	EndIf;	
	// End Document processing processsreferences
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	// ERP-BZKR Project 3063
	Return;
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListOnChange(Item)
	
	
	Return;
	
EndProcedure

&AtServer
Procedure ListBeforeLoadUserSettingsAtServer(Item, Settings)
	
	Return;
	
EndProcedure

&AtServer
Procedure ListOnUpdateUserSettingSetAtServer(StandardProcessing)
	
	Return;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)

	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands


#EndRegion
