
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	String = TransactionTable.Add();
	String.Operation = "WriteOff";
	String = TransactionTable.Add();
	String.Operation = "RecordingAsReceived";
	String = TransactionTable.Add();
	String.Operation = "Damage";
	String = TransactionTable.Add();
	String.Operation = "Misgrading";
	
	If Parameters.Property("SelectedOperations") Then
		ItemCount = Parameters.SelectedOperations.Count();
		If ItemCount = 0 Or ItemCount = TransactionTable.Count() Then
			For Each String In TransactionTable Do
				String.Selected_5 = True;
			EndDo;
		Else
			For Each Item In Parameters.SelectedOperations Do
				RowsArray = TransactionTable.FindRows(New Structure("Operation",Item));
				RowsArray[0].Selected_5 = True;
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Filter(Command)
	Result = New Array;
	For Each String In TransactionTable Do
		If String.Selected_5 Then
			Result.Add(String.Operation);
		EndIf;
	EndDo;
	If Result.Count() = TransactionTable.Count() Then
		Result.Clear();
	EndIf;
		
	Close(Result);
EndProcedure

&AtClient
Procedure ClearRows(Command)
	For Each String In TransactionTable Do
		String.Selected_5 = False;
	EndDo;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Setting the conditional design for the 'Operation' field of the table part.
	DataProcessors.WarehouseGoodsIssueReceiptWizard.SetConditionalFormattingOperationText(ThisForm,
																						"TransactionTableOperation",
																						"TransactionTable.Operation");
	
EndProcedure

#EndRegion