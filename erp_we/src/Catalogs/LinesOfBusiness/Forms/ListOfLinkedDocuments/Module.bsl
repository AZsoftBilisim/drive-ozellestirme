
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Ref") Then
		CommonClientServer.SetDynamicListParameter(DocumentsList, "RefFilter", Parameters.Ref);
	EndIf;
	
	Settings = DocumentsList.SettingsComposer.Settings;
	LinkField = Settings.SelectionAvailableFields.FindField(New DataCompositionField("Ref"));
	
	// StandardSubsystems.AttachableCommands
	PlacementParameter = AttachableCommands.PlacementParameters();
	PlacementParameter.Sources = LinkField.Type;
	PlacementParameter.CommandBar = Items.DocumentsListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameter);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StartDateOnChange(Item)

	CommonClientServer.SetDynamicListParameter(
			DocumentsList,
			"StartDate",
			Period.StartDate,
			Period.StartDate <> '00010101');

EndProcedure

&AtClient
Procedure EndDateOnChange(Item)

	CommonClientServer.SetDynamicListParameter(
			DocumentsList,
			"EndDate",
			Period.EndDate,
			Period.EndDate <> '00010101');

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure DocumentsListSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	If Item.CurrentData <> Undefined Then
		ShowValue(, Item.CurrentData.Ref);
	EndIf;

EndProcedure

&AtClient
Procedure DocumentsListOnActivateField(Item)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
    AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.DocumentsList);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
    AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.DocumentsList);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SelectPeriod(Command)

	NotificationAfterSelectingPeriod = New CallbackDescription("AfterSelectingPeriod", ThisObject);
	TMCommonUseClient.EditPeriod(ThisObject.Period, , NotificationAfterSelectingPeriod);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterSelectingPeriod(Result, AdditionalParameters) Export

	If Result <> Undefined Then
		
		CommonClientServer.SetDynamicListParameter(
			DocumentsList,
			"StartDate",
			Period.StartDate,
			Period.StartDate <> '00010101');
		
		CommonClientServer.SetDynamicListParameter(
			DocumentsList,
			"EndDate",
			Period.EndDate,
			Period.EndDate <> '00010101');
			
		AttachableCommandsClient.StartCommandUpdate(ThisObject); 
		
	EndIf;

EndProcedure

#EndRegion