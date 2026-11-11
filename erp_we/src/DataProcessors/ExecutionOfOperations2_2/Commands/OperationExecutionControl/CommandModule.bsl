
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure;
	
	OpenForm("DataProcessor.ExecutionOfOperations2_2.Form.OperationExecutionControl", FormParameters, ThisObject);
	
EndProcedure

#EndRegion