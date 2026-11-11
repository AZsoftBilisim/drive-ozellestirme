
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Items.List.ChoiceMode Then
	
		StandardProcessing = False;
		ProcessSelectionAndClose(RowSelected);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Items.List.ChoiceMode Then
	
		StandardProcessing = False;
		ProcessSelectionAndClose(Value);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PickUpFromWHO(Command)
	
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	Items.FormPickUpFromWHO.Visible = False;
	
	If Parameters.Property("ChoiceMode") And Parameters.ChoiceMode Then
		
		Items.List.ChoiceMode = True;
		
		QueryText = "
		|SELECT TOP 1
		|	Classifier.Ref AS Ref
		|FROM
		|	Catalog.ManufacturingOperationClassifier AS Classifier
		|WHERE
		|	Classifier.Ref = &Ref
		|	OR (Classifier.Description = &Description AND &Description <> """")
		|";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Ref",       Parameters.CurrentRef);
		Query.SetParameter("Description", Parameters.CurrentDescription);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Items.List.CurrentRow = Selection.Ref;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSelectionAndClose(ValueSelected)
	
	If Not ValueIsFilled(ValueSelected) Then
		Return;
	EndIf;
	
	RowData = Items.List.RowData(ValueSelected);
	
	If RowData.IsFolder Then
		Return;
	EndIf;
	
	NotifyChoice(RowData.Ref);
	
EndProcedure

#EndRegion