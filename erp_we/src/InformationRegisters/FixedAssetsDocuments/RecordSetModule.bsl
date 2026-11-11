#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	FillInZeroEntryNumber(ThisObject);
		
EndProcedure

#EndRegion

#Region Private

Procedure UploadWithProcessing(DataTable) Export
	
	Load(DataTable);
	
	FillInZeroEntryNumber(ThisObject);
	
EndProcedure

Procedure FillInZeroEntryNumber(RecordSet)
	
	If RecordSet.Count() = 0 Then
		Return;
	EndIf;
	
	ThereIsZeroRecordNumber = False;
	For Each RegisterRecord In RecordSet Do
		If RegisterRecord.RecNo = 0 Then
			ThereIsZeroRecordNumber = True;
			Break
		EndIf;
	EndDo;
	
	If Not ThereIsZeroRecordNumber Then
		RecordSet[0].RecNo = 0;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
