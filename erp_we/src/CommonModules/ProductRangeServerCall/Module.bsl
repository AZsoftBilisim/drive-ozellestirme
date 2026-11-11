
#Region Private

Procedure CopyAndAddSettings(SettingsComposer, NewSettings1, Details) Export
	
	NewSettings1 = SettingsComposer.GetSettings();
	NewSettings1.AdditionalProperties.Insert("Details", Details);
	CommonClientServer.SetFilterItem(
		NewSettings1.Filter,
		"Store",
		Details.Store,
		DataCompositionComparisonType.Equal,
		,
		True);
	
	If Details.GroupName = "ProductKind" Then
		CommonClientServer.SetFilterItem(
			NewSettings1.Filter,
			"ProductKind",
			Details.ProductKind,
			DataCompositionComparisonType.Equal,
			,
			True);
	Else
		CommonClientServer.SetFilterItem(
			NewSettings1.Filter,
			"ProductCategory",
			Details.ProductCategory,
			DataCompositionComparisonType.Equal,
			,
			True);
	EndIf;
	
EndProcedure

#EndRegion

