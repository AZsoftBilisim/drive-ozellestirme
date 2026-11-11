
#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Item.CurrentData.Property(Field.Name) Then
		Value = Item.CurrentData[Field.Name];
		ShowValue(Undefined, Value);
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion
