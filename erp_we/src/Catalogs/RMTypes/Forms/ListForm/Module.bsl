
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		// Hide the elements if the form is opened from the owner's form.
		Items.Owner.Visible = False;
		Items.FilterOwner.Visible = False;
		Items.FilterGeneralRMType.Visible = False;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.ListAndFormCommands;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetFilters(ThisObject);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterOwnerOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

&AtClient
Procedure FilterGeneralRMTypeOnChange(Item)
	
	SetFilters(ThisObject);

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetFilters(Form)
	
	List = Form.List;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner",
		Form.FilterOwner,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterOwner));
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"GeneralRMType",
		Form.FilterGeneralRMType,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(Form.FilterGeneralRMType));
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#EndRegion