
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	QueryText =
		"SELECT
		|	Rules.Ref AS Ref,
		|	Rules.Description AS Description
		|FROM
		|	Catalog.CostAllocationRules AS Rules
		|WHERE
		|	NOT Rules.Obsolete_
		|	AND (&OnlyWithTheSpecifiedSelection AND Rules.SettingsOfBaseOfAllocationByLotsChanged
		|			OR NOT &OnlyWithTheSpecifiedSelection)";
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "Catalog.CostAllocationRules";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.List,
		ListProperties);
				
	CommonClientServer.SetDynamicListParameter(
			List,
			"OnlyWithTheSpecifiedSelection",
			Parameters.OnlyWithTheSpecifiedSelection);
			
EndProcedure
