
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FilterParameters = New Structure;
	
	If TypeOf(CommandParameter) = Type("CatalogRef.Companies") Then
		FilterParameters.Insert("Owner", CommandParameter);
	Else
		FilterParameters = New Structure("LineOfBusiness", CommandParameter);
	EndIf;
	
	FormParameters = New Structure("Filter", FilterParameters);
	
	OpenForm(
		"Catalog.CompaniesBankAccounts.ListForm",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure
