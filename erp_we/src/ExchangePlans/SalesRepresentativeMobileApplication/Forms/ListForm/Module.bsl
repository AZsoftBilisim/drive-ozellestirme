
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.DoNotDisplayThisNode Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			ExchangePlans.SalesRepresentativeMobileApplication.ThisNode(),
			DataCompositionComparisonType.NotEqual,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
EndProcedure

#EndRegion
