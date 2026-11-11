
#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Value = Item.CurrentData[Field.Name];
	StandardProcessing = False;
	ShowValue(Undefined, Value);
	
EndProcedure

#EndRegion
