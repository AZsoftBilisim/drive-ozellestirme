
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetUnavailableSelectionsFromParameters(Parameters.Filter);
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
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

#Region Private

#Region Other

// The procedure sets the selections passed in the structure. Selections cannot be changed.
//
// Parameters:
//	FilterStructure1 - Structure - Key: name of the data layout field, Value: selection value.
//
&AtServer
Procedure SetUnavailableSelectionsFromParameters(FilterStructure1)
	
	If FilterStructure1.Property("Owner") Then
		FilterStructure1.Delete("Owner");
	EndIf;
	
	If FilterStructure1.Property("ArticleOwner") Then
		FilterStructure1.Delete("ArticleOwner");
	EndIf;
	
	For Each FilterElement In FilterStructure1 Do

		If ValueIsFilled(FilterElement.Value) Then
			CommonClientServer.SetDynamicListFilterItem(
				List, FilterElement.Key, FilterElement.Value);
		Else
			FilterStructure1.Delete(FilterElement.Key);
		EndIf;
			
	EndDo; 
	
EndProcedure

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

#EndRegion
