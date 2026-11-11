#Region Private

&AtServer
Procedure GenerateReportParameters(CommandParameter, ReportName, FormParameters)
	
	DocumentAttributes = Documents.CommissionReportIntercompany.DocumentAttributes(CommandParameter);
	If DocumentAttributes.ARAPAccountingViaSeparateCounterparty Then
		ReportName = "PartnersARAPAccounting";
		FormParameters.Filter = New Structure("OrderDocument", CommandParameter);
		FormParameters.PurposeUseKey = "SalesOrder";
		FormParameters.VariantKey = "PartnersARAPAccounting";
	Else
		ReportName = "IntercompanyARAP";
		FormParameters.Filter = New Structure("DocumentOfARAPAccounting", CommandParameter);
		FormParameters.PurposeUseKey = "Document";
		FormParameters.VariantKey = "SalesPayments";
	EndIf;
	
EndProcedure // Generate Report parameters()

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Var ReportName;
	
	FormParameters = New Structure("Filter, FixedSettings, PurposeUseKey, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	
	GenerateReportParameters(CommandParameter, ReportName, FormParameters);
		
	OpenForm("Report." + ReportName + ".Form",
		FormParameters,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure // Processing of the command()

#EndRegion