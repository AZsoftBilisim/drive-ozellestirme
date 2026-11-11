
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FillingStructure = New Structure;
	FillingStructure.Insert("ArrayOfStatements", CommandParameter);
	
	FormParameters = New Structure("Basis", FillingStructure);
	
	OpenForm("Document.PaymentRequest.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion
