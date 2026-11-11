#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RationingAndPricingOfWorksOnTariffGrids = False;
	Items.JobTitle.Visible = RationingAndPricingOfWorksOnTariffGrids;
	Items.JobTitleSelection.Visible = RationingAndPricingOfWorksOnTariffGrids;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure JobTitleSelectionOnChange(Item)
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"JobTitle",
		JobTitleSelection,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(JobTitleSelection));
EndProcedure

#EndRegion