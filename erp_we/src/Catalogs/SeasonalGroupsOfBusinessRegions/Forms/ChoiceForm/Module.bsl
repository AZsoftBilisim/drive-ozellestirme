
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("DonTDisplaySharedGroup") Then
	
		CommonClientServer.SetDynamicListFilterItem(List, "Ref", 
			Catalogs.SeasonalGroupsOfBusinessRegions.OtherItems,
			DataCompositionComparisonType.NotEqual);
	
	EndIf; 
	
EndProcedure

#EndRegion
