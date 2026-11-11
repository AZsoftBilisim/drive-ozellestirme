
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Filter = New Structure("Cell",CommandParameter);
	FormParameters = New Structure("Filter", Filter);
	OpenForm("InformationRegister.StorageBinsLocks.ListForm",
	 				FormParameters, 
					CommandExecuteParameters.Source, 
					CommandExecuteParameters.Uniqueness, 
					CommandExecuteParameters.Window);
					
EndProcedure

#EndRegion
