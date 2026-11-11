
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("IsAccessValueSelection") Then
		
		CommonClientServer.SetDynamicListFilterItem(List,
			"UseForAccessRestrictions",
			True,
			DataCompositionComparisonType.Equal,,
			True);
		
		Items.List.Representation = TableRepresentation.List;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	If TypeOf(Value) = Type("Array") Then
		NotifyChoice(Item.RowData(Value[0]).BusinessOperation);
	Else
		NotifyChoice(Item.RowData(Value).BusinessOperation);
	EndIf;
	
EndProcedure

#EndRegion
