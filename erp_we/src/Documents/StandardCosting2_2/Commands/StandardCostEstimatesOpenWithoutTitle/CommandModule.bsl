
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm("Document.StandardCosting2_2.ListForm",
		FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
		
EndProcedure
