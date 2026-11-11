#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	 FormParameters = New Structure("SubjectOf", CommandParameter);
	 OpenForm("Catalog.Incidents.Form.IncidentsBySubject", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
EndProcedure

#EndRegion