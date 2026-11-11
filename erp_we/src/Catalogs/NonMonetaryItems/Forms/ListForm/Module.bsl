
#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)

	Items.List.Representation = TableRepresentation.List;
	HierarchyOfMetricsWhenActivatingWaitHandlerLine();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIndicatorHierarchy

&AtClient
Procedure IndicatorHierarchyOnActivateRow(Item)

	AttachIdleHandler("HierarchyOfMetricsWhenActivatingWaitHandlerLine", 0.1, True);

EndProcedure

&AtClient
Procedure HierarchyOfMetricsWhenActivatingWaitHandlerLine()

	SelectionByHierarchyOfIndicators = Items.IndicatorHierarchy.CurrentRow;
	CommonClientServer.SetDynamicListFilterItem(
		List, "Parent", SelectionByHierarchyOfIndicators, 
		DataCompositionComparisonType.Equal, "Parent", True);

EndProcedure

#EndRegion
