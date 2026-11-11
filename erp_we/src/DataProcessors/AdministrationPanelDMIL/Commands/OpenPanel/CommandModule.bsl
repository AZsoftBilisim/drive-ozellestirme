#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	StandardProcessing = True;
	IntegrationWith1CDocumentManagementCoreClientOverridable.OpenBidAdministrationPanel(
		CommandExecuteParameters,
		StandardProcessing);
	
	If Not StandardProcessing Then
		Return;
	EndIf;
	
	OpenForm(
		"DataProcessor.AdministrationPanelDMIL.Form.IntegrationWith1CDocumentManagementSetting",
		New Structure,
		CommandExecuteParameters.Source,
		"DataProcessor.AdministrationPanelDMIL.Form.IntegrationWith1CDocumentManagementSetting"
			+ ?(CommandExecuteParameters.Window = Undefined, ".SingleWindow", ""),
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion