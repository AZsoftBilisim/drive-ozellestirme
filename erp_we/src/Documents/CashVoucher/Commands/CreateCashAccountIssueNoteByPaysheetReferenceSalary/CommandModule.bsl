
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("Basis", CommandParameter);
	
	OpenForm("Document.CashVoucher.ObjectForm", FormParameters);
	
EndProcedure

#EndRegion
