#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.RowChoiceMode) Then
		RowChoiceMode = Parameters.RowChoiceMode;
	Else
		RowChoiceMode = "OpenEntryForm";
	EndIf;
	
	If RowChoiceMode = "OpenObjectForm" Then
		Items.AdditionalRecord.Visible = False;
		Items.RecordSeparator.Visible = False;
		Items.Ref.Visible = False;
		Items.DeletionMark.Visible = False;
		Items.Posted.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region TableEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	If RowChoiceMode = "OpenEntryForm" Then
		StandardProcessing = False;
		
		ShowValue(, RowSelected);
	ElsIf RowChoiceMode = "OpenObjectForm" Then
		StandardProcessing = False;
		
		ShowValue(, Item.CurrentData.Ref);
	EndIf;
	
EndProcedure

#EndRegion