#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each State In Parameters.States1 Do
		If TypeOf(State.Value) <> Type("String") Then
			NwRw = StateTable.Add();
			NwRw.State = State.Presentation;
			NwRw.StateID = State.Value.ID;
			NwRw.StateType = State.Value.Type;
		EndIf;
	EndDo;
	
	For Each Page1 In StateTable Do
		If TypeOf(Parameters.CurrentDataValue) = Type("ValueList") Then
			For Each Item In Parameters.CurrentDataValue Do
				If Item.Value.ID = Page1.StateID
						And Item.Value.Type = Page1.StateType Then
					Page1.Check = True;
					Break;
				EndIf;
			EndDo;
		ElsIf Parameters.CurrentDataValueID = Page1.StateID
				And Parameters.CurrentDataValueType = Page1.StateType Then
			Page1.Check = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersStateTable

&AtClient
Procedure StateTableBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure StateTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	// We will return the list of values.
	StateSelectionList = New ValueList;
	
	For Each Page1 In StateTable Do
		If Page1.Check Then
			Value = IntegrationWith1CDocumentManagementCoreClientServer.ReferenceObjectDataDM(
				Page1.StateID,
				Page1.StateType,
				Page1.State);
			StateSelectionList.Add(Value, Value.Description);
		EndIf;
	EndDo;
	
	If StateSelectionList.Count() = 1 Then
		NotifyChoice(StateSelectionList[0].Value);
	Else
		NotifyChoice(StateSelectionList); // if 0 is also here.
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	
	For Each Page1 In StateTable Do
		Page1.Check = True;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	
	For Each Page1 In StateTable Do
		Page1.Check = False;
	EndDo;
	
EndProcedure

#EndRegion