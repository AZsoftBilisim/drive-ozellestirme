
 #Region FormCommandsEventHandlers	

&AtClient
Procedure RecalculationOfPaymentSchedule(Command)
	CallbackDescription = New CallbackDescription("AfterEndOfRecalculation",ThisObject);
	OpenForm("InformationRegister.ScheduleOfPayments.Form.ScheduleRecalculationForm",,,,,,CallbackDescription);
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterEndOfRecalculation(Result, AdditionalParameters) Export
	Items.List.Refresh();
EndProcedure

#EndRegion