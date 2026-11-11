
#Region FormEventHandlers

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetSelectionByDivision();
	SetCurrentViewOfWorkCenterSource();
	SetSelectedViewOfWorkCenterReceiver();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterDepartmentOnChange(Item)
	
	SetSelectionByDivision();
	
EndProcedure

&AtClient
Procedure FilterWorkCenterTypeSourceOnChange(Item)
	
	SetCurrentViewOfWorkCenterSource();
	
EndProcedure

&AtClient
Procedure FilterWorkCenterTypeDestinationOnChange(Item)
	
	SetSelectedViewOfWorkCenterReceiver();
	
EndProcedure

#EndRegion

#Region Private

#Region Filters

&AtServer
Procedure SetSelectionByDivision()

	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"Department", 
		FilterDepartment, 
		DataCompositionComparisonType.InHierarchy,
		, // Presentation - automatically
		ValueIsFilled(FilterDepartment));

EndProcedure

&AtServer
Procedure SetCurrentViewOfWorkCenterSource()

	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"WorkCenterTypeSource", 
		FilterWorkCenterTypeSource, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(FilterWorkCenterTypeSource));

EndProcedure

&AtServer
Procedure SetSelectedViewOfWorkCenterReceiver()

	CommonClientServer.SetDynamicListFilterItem(
		List, 
		"WorkCenterTypeDestination", 
		FilterWorkCenterTypeDestination, 
		DataCompositionComparisonType.Equal,
		, // Presentation - automatically
		ValueIsFilled(FilterWorkCenterTypeDestination));

EndProcedure

#EndRegion

#EndRegion
