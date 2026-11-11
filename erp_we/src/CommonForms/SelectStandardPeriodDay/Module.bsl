#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BeginOfPeriod = Parameters.BeginOfPeriod;
	EndOfPeriod  = Parameters.EndOfPeriod;
	
	If BegOfDay(BeginOfPeriod) = BegOfDay(EndOfPeriod) Then
		Day = BeginOfPeriod;
	Else
		Day = CurrentSessionDate();
	EndIf;
	
	If Day < Parameters.LowLimit Then
		Day = Parameters.LowLimit;
	EndIf;
	
	Items.Day.BeginOfRepresentationPeriod = Parameters.LowLimit;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure DayOnChange(Item)
	
	SelectionResult = New Structure("BeginOfPeriod, EndOfPeriod", BegOfDay(Day), EndOfDay(Day));
	Close(SelectionResult);
	
EndProcedure

#EndRegion