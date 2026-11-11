
&AtClient
Procedure Apply(Command)
	
	Close(NumberOfMonths);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NumberOfMonths = 3;
	
EndProcedure
