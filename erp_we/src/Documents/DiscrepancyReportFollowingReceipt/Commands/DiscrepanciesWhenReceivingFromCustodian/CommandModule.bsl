

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("TypeOfBaseDocumentForNonConformanceCertificate",
									PredefinedValue("Enum.TypesOfBaseDocumentsForDiscrepancyReport.ReturnOfGoodsFromCustodian"));
	
	OpenForm("Document.DiscrepancyReportFollowingReceipt.ListForm",
				FormParameters,
				CommandExecuteParameters.Source,
				"ReceiptOfGoodsFromCustodian",
				CommandExecuteParameters.Window,
				CommandExecuteParameters.URL);

EndProcedure

#EndRegion

