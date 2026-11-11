#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormNameWorkplaceCustomsDeclarationImport = "Document.CCDImport.Form.Workplace";
	OpenForm(
		FormNameWorkplaceCustomsDeclarationImport, ,
		CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
		
EndProcedure

#EndRegion