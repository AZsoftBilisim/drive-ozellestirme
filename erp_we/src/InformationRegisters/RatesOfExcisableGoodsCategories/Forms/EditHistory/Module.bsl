
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ExcisableGoodsCategory = Parameters.ExcisableGoodsCategory;
	ReadOnly = Parameters.ReadOnly;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"ExcisableGoodsCategory",
		ExcisableGoodsCategory,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(ExcisableGoodsCategory),,);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	NotifyChoice(GetPeriod(RowSelected));
	
EndProcedure

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	Notify("Delete_RateOfExciseCategory",, ExcisableGoodsCategory);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	ExcisableGoodsCategory = Item.CurrentData.ExcisableGoodsCategory;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetPeriod(RecordKey)
	
	If ValueIsFilled(RecordKey) Then
		Period = RecordKey.Period;
	Else
		Period = Undefined;
	EndIf;
	
	Return Period;
	
EndFunction

#EndRegion
