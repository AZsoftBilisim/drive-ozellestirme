
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Object = CommandExecuteParameters.Source.Object;
	
	Filter = New Structure("Organization", Object.Organization);
	Filter.Insert("Individual", GetListOfIndividuals(Object.Content));
	
	ReportPeriod = New StandardPeriod(Date(1,1,1), EndOfDay(Date(3999, 12, 31)));
	Filter.Insert("ReportPeriod", ReportPeriod);
	
	FormParameters = New Structure("Filter", Filter);
	FormParameters.Insert("GenerateOnOpen", True);
	OpenForm("Report.PaysheetPaymentControl.Form", FormParameters, CommandExecuteParameters.Source, 
	CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	
EndProcedure

&AtServer
Function GetListOfIndividuals(Val Content)
	
	Array = Content.Unload(,"Individual").UnloadColumn("Individual");
	Return Array;
	
EndFunction