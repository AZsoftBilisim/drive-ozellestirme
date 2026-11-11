#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.CommandListForms);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.ListDate.Name);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If Parameters.Property("DonTDownloadSelections") Then
		Settings.Delete("FilterWorkOrderKind");
		Settings.Delete("Department");
		Settings.Delete("Team");
	EndIf; 
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	WhenChangingSelections();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DepartmentOnChange(Item)
	
	DivisionWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure FilterWorkOrderKindOnChange(Item)
	
	TypeOfOutfitWhenChangingServerCall();
	
EndProcedure

&AtClient
Procedure TeamOnChange(Item)
	
	BrigadeWhenChangingServerCall();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	FillingValues = New Structure;
	
	If ValueIsFilled(Team) Then
		FillingValues.Insert("Team", Team);
	EndIf;
	
	If ValueIsFilled(Department) Then
		FillingValues.Insert("Department", Department);
	EndIf;
	
	If ReferenceArray.Count() > 0 Then
		FillingValues.Insert("References", ReferenceArray);
	EndIf;
	
	FormParameters = New Structure("FillingValues", FillingValues);
	
	OpenForm("Document.WorkOutput.ObjectForm", FormParameters, ThisForm);
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.StatusPresentation Then
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

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


&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	WhenChangingSelections();
	
	ChangeSelectedAvailable = ProductionServer.CommandChangeSelectedIsAvailable(Metadata.Documents.WorkOutput);
	Items.ListChangeSelectedItems.Visible          = ChangeSelectedAvailable;
	Items.ContextMenuChangeSelected.Visible = ChangeSelectedAvailable;
	
EndProcedure

&AtServer
Procedure WhenChangingSelections()

	SetSelectionByDivision();
	SetSelectionByTypeOfOutfit();
	EstablishSelectionByBrigade();
	
EndProcedure

&AtServer
Procedure DivisionWhenChangingServerCall()

	SetSelectionByDivision();
	
EndProcedure

&AtServer
Procedure TypeOfOutfitWhenChangingServerCall()

	SetSelectionByTypeOfOutfit();
	
EndProcedure

&AtServer
Procedure BrigadeWhenChangingServerCall()

	EstablishSelectionByBrigade();
	
EndProcedure

&AtServer
Procedure SetSelectionByDivision()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Department", 
		Department, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Department));
		
EndProcedure

&AtServer
Procedure EstablishSelectionByBrigade()
	
	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Team", 
		Team, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(Team));
		
EndProcedure

&AtServer
Procedure SetSelectionByTypeOfOutfit()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"WorkOrderKind",
		FilterWorkOrderKind,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterWorkOrderKind));
	
EndProcedure


#EndRegion
