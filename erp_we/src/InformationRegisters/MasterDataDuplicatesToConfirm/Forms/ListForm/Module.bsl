#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Source <> Undefined Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText = StrReplace(List.QueryText, "TRUE", "RegisterTableOverridable.Source = &Source");
		Common.SetDynamicListProperties(Items.List, ListProperties);
		List.Parameters.SetParameterValue("Source", Parameters.Source);
	EndIf;
EndProcedure

#EndRegion
