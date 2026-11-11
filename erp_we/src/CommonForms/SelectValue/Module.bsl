
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If TypeOf(Parameters.ValuesForSelection) = Type("ValueList") Then
		List.ValueType = Parameters.ValuesForSelection.ValueType;
		TMCommonUse.AddRowsToTable(List, Parameters.ValuesForSelection);
	ElsIf TypeOf(Parameters.ValuesForSelection) = Type("Array") Then
		List.LoadValues(Parameters.ValuesForSelection);
	EndIf;
	
	If Parameters.Property("Title") Then
		ThisForm.Title = Parameters.Title;
		ThisForm.AutoTitle = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure Select(Command)
	
	Close(Items.List.CurrentData.Value);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	Close(Items.List.CurrentData.Value);
	
EndProcedure

#EndRegion
