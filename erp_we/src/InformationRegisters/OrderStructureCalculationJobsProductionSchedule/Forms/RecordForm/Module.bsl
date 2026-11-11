
#Region FormEventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Not ValueIsFilled(Record.Separator) Then
		Record.Separator = New UUID();
	EndIf;
	
EndProcedure

#EndRegion