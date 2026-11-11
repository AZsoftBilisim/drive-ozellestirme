#Region Private

&AtServer
Procedure GenerateReportParameters(CommandParameter, ReportName, FormParameters)

	DocumentAttributes = Documents.CustomerInvoiceIntercompany.DocumentAttributes(CommandParameter);
	If DocumentAttributes.ARAPAccountingViaSeparateCounterparty Then
		ReportName = "PartnersARAPAccounting";
		FormParameters.VariantKey = "PartnersARAPAccounting";
		If DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
			FormParameters.Filter = New Structure("Partner, Counterparty",
				DocumentAttributes.Partner,
				DocumentAttributes.Counterparty);
			FormParameters.PurposeUseKey = "PartnerCounterparty";
		Else
			FormParameters.Filter = New Structure("OrderDocument", CommandParameter);
			FormParameters.PurposeUseKey = "SalesOrder";
		EndIf;
	Else
		ReportName = "IntercompanyARAP";
		FormParameters.VariantKey = "SalesPayments";
		If DocumentAttributes.BusinessOperation = Enums.BusinessTransactions.TransferOfGoodsToCommissionAgentInAnotherCompany Then
			FormParameters.Filter = New Structure("Seller, Customer",
				DocumentAttributes.SenderOrganization,
				DocumentAttributes.CompanyRecipient,);
			FormParameters.PurposeUseKey = "SellerBuyer";
		Else
			FormParameters.Filter = New Structure("DocumentOfARAPAccounting", CommandParameter);
			FormParameters.PurposeUseKey = "Document";
		EndIf;
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