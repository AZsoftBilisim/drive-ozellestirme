

#Region FormTableItemsEventHandlersDocumentsByBasis

&AtClient
Procedure DepositorsValueChoice(Item, Value, StandardProcessing)
	ReturnStructure = New Structure("Partner, Contract, Organization");
	FillPropertyValues(ReturnStructure, Item.CurrentData);
	NotifyChoice(ReturnStructure);
EndProcedure

#EndRegion
