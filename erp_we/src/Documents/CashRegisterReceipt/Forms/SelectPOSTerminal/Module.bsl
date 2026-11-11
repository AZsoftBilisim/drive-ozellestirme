
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	TerminalList = Parameters.ChoiceList;	// See Catalogs.POSTerminals.ParametersOfAcquiringTerminalsByOrganization
	
	For Each ListItem In TerminalList Do
		ValueListItem_ = ListItem.Value;	// Structure
		Items.POSTerminal.ChoiceList.Add(ValueListItem_.Ref, ListItem.Presentation);
	EndDo;
	
	If Items.POSTerminal.ChoiceList.Count() > 0 Then
		ElementsAcquiringTerminal = Items.POSTerminal.ChoiceList[0].Value; // CatalogRef.Peripherals
		POSTerminal = ElementsAcquiringTerminal.Ref;
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	For Each ListItem In TerminalList Do
		ValueListItem_ = ListItem.Value; // Structure
			If ValueListItem_.Ref = POSTerminal Then
			Close(ValueListItem_);
			Break;
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
