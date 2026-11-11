
#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Item.CurrentData[Field.Name];
	ShowValue(Undefined, Value);
	StandardProcessing = False;
	
EndProcedure

#EndRegion
