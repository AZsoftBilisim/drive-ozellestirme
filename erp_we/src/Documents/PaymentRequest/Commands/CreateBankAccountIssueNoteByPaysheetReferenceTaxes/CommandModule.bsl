
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FillingStructure = New Structure;
	FillingStructure.Insert("ArrayOfStatements", CommandParameter);
	FillingStructure.Insert("BusinessOperation",
			PredefinedValue("Enum.BusinessTransactions.TransferOfTaxesAndContributions"));
	
	FormParameters = New Structure("Basis", FillingStructure);
	
	OpenForm("Document.PaymentRequest.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion
