#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

#Region UniversalMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

#EndRegion
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning

	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
	List, "Organization", FilterOrganization, QuickFilterStructure);

	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(
	List, "Department", FilterDepartment, QuickFilterStructure);

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)

	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Organization", FilterOrganization,
		QuickFilterStructure, Settings);
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "Department", FilterDepartment,
		QuickFilterStructure, Settings);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOrganizationOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(List, "Organization", FilterOrganization,
		DataCompositionComparisonType.Equal, , ValueIsFilled(FilterOrganization));
EndProcedure

&AtClient
Procedure FilterOrganizationClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterOrganization) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure FilterDepartmentOnChange(Item)

	CommonClientServer.SetDynamicListFilterItem(List, "Department", FilterDepartment,
		DataCompositionComparisonType.Equal, , ValueIsFilled(FilterDepartment));

EndProcedure

&AtClient
Procedure FilterDepartmentClearing(Item, StandardProcessing)
	If Not ValueIsFilled(FilterDepartment) Then
		StandardProcessing = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region Universal_

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)

	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);

EndProcedure

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result)
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#EndRegion