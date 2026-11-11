#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	PossibleOwners = GetFromTempStorage(Parameters.AddressInTempStorage);
	For Each Owner In PossibleOwners Do
		NewRow = OwnersTable.Add();
		NewRow.Owner = Owner;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOwnersTable

&AtClient
Procedure OwnersTableSelection(Item, RowSelected, Field, StandardProcessing)
	ValueSelected = Items.OwnersTable.CurrentData.Owner;
	Close(ValueSelected);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	ValueSelected = Items.OwnersTable.CurrentData.Owner;
	Close(ValueSelected);
EndProcedure

#EndRegion