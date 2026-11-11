
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Title") Then
		ThisForm.Title = Parameters.Title;
	EndIf;
	
	TransactionList = Parameters.TransactionList;
	Items.TransactionList.HeightInTableRows = TransactionList.Count();
	
	Items.Warning.Visible = (Parameters.Property("DisplayWarning_") And Parameters.DisplayWarning_);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TransactionListSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentOperation = TransactionList.FindByValue(Item.CurrentData.Value);
	CurrentOperation.Check = Not CurrentOperation.Check;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	NotifyChoice(TransactionList);
	
EndProcedure

#EndRegion