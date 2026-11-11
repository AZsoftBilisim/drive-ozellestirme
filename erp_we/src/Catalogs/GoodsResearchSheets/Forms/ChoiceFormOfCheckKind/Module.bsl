#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessingSelectionOfListValue(RowSelected, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	ProcessingSelectionOfListValue(Value, StandardProcessing);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessingSelectionOfListValue(RowSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	NotifyChoice(Items.List.RowData(RowSelected).CheckKind);
	
EndProcedure

#EndRegion
