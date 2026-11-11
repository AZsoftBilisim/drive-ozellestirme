#Region FormCommandsEventHandlers

&AtClient
Procedure StartVATCalculation(Command)
	StartVATCalculationOnServer();
EndProcedure

&AtServer
Procedure StartVATCalculationOnServer()
	
	VATAccountingERPInternal.CompleteTasksForGeneratingVATRegisteredRecords(
		EndOfMonth(Period.EndDate),
		CommonClientServer.ValueInArray(Organization));
	
EndProcedure

#EndRegion