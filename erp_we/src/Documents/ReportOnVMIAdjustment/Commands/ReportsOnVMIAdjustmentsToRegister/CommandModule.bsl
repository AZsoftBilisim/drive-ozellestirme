#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormNameWorkplace = "Document.ReportOnVMIAdjustment.Form.ToRegisterWriteOffsOfGoodsReceivedForStorage";
	OpenForm(FormNameWorkplace,
		,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness,
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion