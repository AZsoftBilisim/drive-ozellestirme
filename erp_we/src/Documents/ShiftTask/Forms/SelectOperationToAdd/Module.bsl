
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = StrReplace(
		List.QueryText,
		"&RunTime",
		InformationRegisters.OperationsToCreateShiftTasks.QueryTextOperationTime_("RegisterOverridable"));
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

#EndRegion
