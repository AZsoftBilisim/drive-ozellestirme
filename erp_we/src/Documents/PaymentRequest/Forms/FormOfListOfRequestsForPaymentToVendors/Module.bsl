
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	

	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);

	ObjectsVersioning.OnCreateAtServer(ThisObject);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Electronic documents"
	If EventName = "UpdateEdState" Then
		Items.List.Refresh();	
	EndIf;

EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	DisplayRequests = Settings.Get("DisplayRequests");
	DisplayRequestsOnChangeServer();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DisplayRequestsOnChange(Item)
	
	DisplayRequestsOnChangeServer();
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
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

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure DisplayRequestsOnChangeServer()

	If DisplayRequests = 0 Then // All
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			False,
			DataCompositionComparisonType.Equal,
			,
			False);
		
	ElsIf DisplayRequests = 1 Then // Unpaid
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			False,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	ElsIf DisplayRequests = 2 Then // Paid_
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RequestIsPaid",
			True,
			DataCompositionComparisonType.Equal,
			,
			True);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
