
#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConfiguringDataSourcesClick(Item)
	
	OpenForm(
		"Catalog.SourcesToImportProductionMasterData.ListForm");
	
EndProcedure

&AtClient
Procedure ImportStateMonitoringClick(Item)
	
	OpenForm(
		"DataProcessor.ImportProductionMasterData.Form.ImportStateMonitoring");
	
EndProcedure

&AtClient
Procedure MatchingObjectsClick(Item)
	
	OpenForm(
		"DataProcessor.ImportProductionMasterData.Form.MatchingObjects");
	
EndProcedure

#EndRegion