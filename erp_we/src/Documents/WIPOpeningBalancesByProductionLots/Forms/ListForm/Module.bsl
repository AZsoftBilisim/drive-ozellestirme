
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	URL = "e1cib/list/Document.WIPOpeningBalancesByProductionLots";
	
	CommandsAdd = New Array;
	CommandsAdd.Add("FormCreate");
	CommandsAdd.Add("FormCopy");
	CommandsAdd.Add("FormDelete");
	CommandsAdd.Add("ListContextMenuCreate");
	CommandsAdd.Add("ListContextMenuCopy");
	CommandsAdd.Add("ListContextMenuSetDeletionMark");
	CommandsAdd.Add("ListContextMenuPost");
	CommandsAdd.Add("ListContextMenuUndoPosting");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		CommandsAdd,
		"Enabled",
		AccessRight("Update", Metadata.Documents.WIPOpeningBalancesByProductionLots));
	
	DocumentTypesUsed = New Array();
	DocumentTypesUsed.Add(Type("DocumentRef.WIPOpeningBalancesByProductionLots"));
	DocumentTypesUsed.Add(Type("DocumentRef.ReversingEntry"));
	
	List.Parameters.SetParameterValue("RefType",
		Common.MetadataObjectID("Document.WIPOpeningBalancesByProductionLots"));
		
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.List,
		Metadata.Documents.WIPOpeningBalancesByProductionLots.FullName());
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Conducting_Storno"
			Or EventName = "Write_ReversingEntry"
			Or EventName = "Write_WIPOpeningBalancesByProductionLots" Then
		Items.List.Refresh();
	EndIf;
	
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
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	If Copy Then
		TMCommonUseClient.CopyItem(Item);
	Else
		OpenForm("Document.WIPOpeningBalancesByProductionLots.ObjectForm", , Items.List);
	EndIf;
	Cancel = True;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;	
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure


&AtClient
Procedure ListPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListUndoPosting(Command)
	
	TMCommonUseClient.UndoPosting(Items.List, Title);
	
EndProcedure

&AtClient
Procedure ListCopy(Command)
	
	TMCommonUseClient.CopyItem(Items.List);
	
EndProcedure

&AtClient
Procedure ListSetClearADeletionMark(Command)
	
	TMCommonUseClient.SetDeletionMark(Items.List, Title);
EndProcedure

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	
	TMCommonUseClient.EditPeriod(Period, , Notification);
	
EndProcedure

&AtClient
Procedure SetDateIntervalCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	Period = ValueSelected;
	SetSelectionByPeriod();
	
EndProcedure

&AtServer
Procedure SetSelectionByPeriod()
	
	List.Parameters.SetParameterValue("BeginOfPeriod",
		Period.StartDate);
	List.Parameters.SetParameterValue("EndOfPeriod", 
		Period.EndDate);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", "Date");

EndProcedure

#EndRegion
