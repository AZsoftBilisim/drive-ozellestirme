&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	NameOfSchedulingSubsystem = PlanningClientServer.NameOfSchedulingSubsystem();
	
	AdditionalReportsAndDataProcessorsClient.OpenAdditionalReportAndDataProcessorCommandsForm(
			CommandParameter,
			CommandExecuteParameters,
			AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor(),
			NameOfSchedulingSubsystem);
			
EndProcedure