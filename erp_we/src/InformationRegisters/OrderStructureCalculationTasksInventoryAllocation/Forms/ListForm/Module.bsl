
#Region FormCommandsEventHandlers

&AtClient
Procedure StartCalculation(Command)
	
	RunCalculationOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServerNoContext
Procedure RunCalculationOnServer()
	
	OrderStructure.StartCalculation();
	
EndProcedure

#EndRegion

