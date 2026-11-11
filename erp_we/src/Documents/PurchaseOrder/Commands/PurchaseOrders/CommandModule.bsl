#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormNameWorkplaceOrderToSupplier = "Document.PurchaseOrder.Form.DocumentsListForm";
	OpenForm(FormNameWorkplaceOrderToSupplier,
		, // Form parametersreferences,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion