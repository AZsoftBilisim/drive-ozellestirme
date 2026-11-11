
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("NotificationFunction") Then 
		NotificationFunction = Parameters.NotificationFunction;
	Else
		NotificationFunction = "SelectionOfDetailsInSelectionTable";
	EndIf;
	
	ArrayOfSelectionDetails = GetFromTempStorage(Parameters.AddressInStorage);
	FillInTableOfValuesFromArray(ArrayOfSelectionDetails);
	
	AttributesTable.Sort("AttributeName");

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure AddToPanel(Command)
	
	SelectBankingDetails(0);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAttributesTable

&AtClient
Procedure AttributesTableBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttributesTableBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure AttributesTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectBankingDetails(2);
	
EndProcedure

&AtClient
Procedure AttributesTableValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	SelectBankingDetails(2);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInTableOfValuesFromArray(RowsArray)
	
	AttributesTable.Clear();
	
	For Each ArrayRow In RowsArray Do
		
		RowOfDetailsTable = AttributesTable.Add();
		FillPropertyValues(RowOfDetailsTable, ArrayRow);
		
	EndDo;
	
EndProcedure


// Performing operations to select and deselect items
// 
// Parameters:
// 	SelectionOption - Number - Option for selecting elements. 0 - make a selection; 1 - cancel the selection; 2-invert the selection
&AtClient
Procedure SelectBankingDetails(SelectionOption = 0)
	
	If Items.AttributesTable.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ArrayOfItemsToAdd = New Array;
	
	For Each SelectedRow In Items.AttributesTable.SelectedRows Do
		
		RowParameters = New Structure("AttributeName, IsAddlAttribute, Property, Used, AttributeRepresentation, Used");
		
		RowData = Items.AttributesTable.RowData(SelectedRow);
		If SelectionOption = 0 Then			
			RowData.Used = True;
		ElsIf SelectionOption = 1 Then 
			RowData.Used = False;
		Else
			RowData.Used = Not RowData.Used;						
		EndIf;
		
		FillPropertyValues(RowParameters, RowData);
		ArrayOfItemsToAdd.Add(RowParameters);
		
	EndDo;
	
	//Notify("Correction of the Selection table", New Structure("Array of add-ons", Array of add-ons));
	Notify(NotificationFunction, New Structure("ArrayOfItemsToAdd", ArrayOfItemsToAdd));
	
EndProcedure

#EndRegion
