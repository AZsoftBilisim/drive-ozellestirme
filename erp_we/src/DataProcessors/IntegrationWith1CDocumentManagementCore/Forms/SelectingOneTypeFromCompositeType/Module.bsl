#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.FormCaption) Then
		AutoTitle = False;
		Title = Parameters.FormCaption;
	EndIf;
	
	If Parameters.AvailableTypeList.Count() = 0 Then
		Cancel = True;
		Return;
	EndIf;
	
	For Each Item In Parameters.AvailableTypeList Do
		NewRow = AvailableTypes.Add();
		NewRow.Presentation = Item.Value.Presentation;
		NewRow.Name = Item.Value.XDTOClassName;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AvailableTypesSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.AvailableTypes.CurrentData.Name);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	Close(Items.AvailableTypes.CurrentData.Name);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion