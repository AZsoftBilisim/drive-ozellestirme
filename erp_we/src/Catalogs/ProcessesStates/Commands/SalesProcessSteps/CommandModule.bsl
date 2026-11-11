
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure("Parent",PredefinedValue("Catalog.ProcessesStates.SalesProcesses"));
	
	OpenForm("Catalog.ProcessesStates.ListForm",
				 New Structure("Filter",FilterParameters),
				  CommandExecuteParameters.Source,
				 CommandExecuteParameters.Uniqueness,
				 CommandExecuteParameters.Window);
				 
EndProcedure
