
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AllowCalendarEditing   = True;
	AllowEditingPaymentForm = True;
	AllowEditingSteps      = True;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEdit(Command)

	Result = New Array;
	
	If AllowCalendarEditing Then
		Result.Add("Calendar");
	EndIf;
	
	If AllowEditingPaymentForm Then
		Result.Add("PaymentMethod");
	EndIf;
	
	If AllowEditingSteps Then
		Result.Add("Stages");
	EndIf;
	
	Close(Result);

EndProcedure

&AtClient
Procedure SetAllMarks(Command)
	
	AllowCalendarEditing   = True;
	AllowEditingPaymentForm = True;
	AllowEditingSteps      = True;
	
EndProcedure

&AtClient
Procedure RemoveAllMarks(Command)
	
	AllowCalendarEditing   = False;
	AllowEditingPaymentForm = False;
	AllowEditingSteps      = False;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
