
#Region FormCommandsEventHandlers

&AtClient
Procedure MinimizeRegisteredRecords(Command)
	
	TimeConsumingOperation = StartRegisteringRecordedConvolutionATServer();
	CallbackOnCompletion = New CallbackDescription("AfterEndOfConvolutionOfRegisteredRecorded", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterEndOfConvolutionOfRegisteredRecorded(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

&AtServer
Function StartRegisteringRecordedConvolutionATServer()
	
	Return TimeConsumingOperations.ExecuteProcedure(,
		"AccumulationRegisters.AvailabilityOfWorkCenterTypes.CollapseRecordsByBusyResource");
	
EndFunction

#EndRegion