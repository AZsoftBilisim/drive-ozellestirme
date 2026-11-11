
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	For Each Date In Parameters.ListOfDates_ Do
		RowData = FinancialDetailsForThePeriod.Add();
		RowData.Date = Date;
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompleteSelection(Command)
	
	Result = New Array;
	
	For Each RowData In FinancialDetailsForThePeriod Do
		If RowData.Check Then
			Result.Add(RowData.Date);
		EndIf;
	EndDo;

	Close(Result);
	
EndProcedure

&AtClient
Procedure SelectAll_2(Command)
	
	SetSelection_(True);
	
EndProcedure

&AtClient
Procedure RemoveTheSelection(Command)
	
	SetSelection_(False);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetSelection_(Check)
	
	For Each RowData In FinancialDetailsForThePeriod Do
		RowData.Check = Check;
	EndDo;
	
EndProcedure

#EndRegion

