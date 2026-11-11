
#Region EventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ListOfPriceTypes = New ValueList;
	ListOfPriceTypes.LoadValues(Catalogs.TypesOfPrices.AvailableTypesOfPrices());
	CommonClientServer.SetDynamicListFilterItem(List, "PriceKind", ListOfPriceTypes, DataCompositionComparisonType.InList,, True);
	
EndProcedure

#EndRegion
