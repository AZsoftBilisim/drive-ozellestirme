
#Region FormEventHandlers

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	Record.Separator = New UUID();
	
EndProcedure

#EndRegion