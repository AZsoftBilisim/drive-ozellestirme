#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	List.LoadValues(Parameters.DocumentsArray);
	
	If Parameters.Property("FormCaption") Then 
		Title = Parameters.FormCaption;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(, List[RowSelected].Value);
	
EndProcedure

#EndRegion
