
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AppTypes = AppTypesServer.ConfigurationAppTypes();
	
	ChoiceList = Items.AppTypeName.ChoiceList;
	ChoiceList.LoadValues(AppTypes.UnloadColumn("Name"));
	
EndProcedure

#EndRegion
