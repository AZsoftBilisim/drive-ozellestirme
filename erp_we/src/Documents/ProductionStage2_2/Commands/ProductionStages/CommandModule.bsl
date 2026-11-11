
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	FormParameters = New Structure("QuickFilterStructure", New Structure("ReferenceOrder", CommandParameter));
	
	OpenForm("Document.ProductionStage2_2.ListForm",
		FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion
