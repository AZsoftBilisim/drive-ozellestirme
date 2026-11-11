
#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListAfterDeleteRow(Item)
	
	Notify("Delete_RateOfExciseCategory",, ExcisableGoodsCategory);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	ExcisableGoodsCategory = Items.List.CurrentData.ExcisableGoodsCategory;
	
EndProcedure

#EndRegion
