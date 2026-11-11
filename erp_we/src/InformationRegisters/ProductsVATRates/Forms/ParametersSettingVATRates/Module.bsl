#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Period = BegOfMonth(Parameters.Period);
	Country = Parameters.Country;
	BySelectedLines = Parameters.BySelectedLines;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToBegin(Command)
	
	If CheckFilling() Then
		
		Result = New Structure;
		Result.Insert("Period", Period);
		Result.Insert("Country", Country);
		Result.Insert("VATRate", VATRate);
		Result.Insert("BySelectedLines", BySelectedLines);
		
		Close(Result);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PeriodOnChange(Item)
	Period = BegOfMonth(Period);
EndProcedure

#EndRegion