
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	Filter = New Structure;
	Filter.Insert("Owner",PredefinedValue("Catalog.PackagingGroups.BasicUnitsOfMeasure"));
	FormParameters = New Structure("Filter", Filter);
	OpenForm("Catalog.PackagesAndUnitsOfMeasure.Form.FormOfUnitsOfMeasureList",
		FormParameters,
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure