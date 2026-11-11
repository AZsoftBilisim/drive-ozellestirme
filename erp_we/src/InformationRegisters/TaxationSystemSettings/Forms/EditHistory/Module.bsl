#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Organization = Parameters.Organization;
	ReadOnly = Parameters.ReadOnly;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal, , 
		ValueIsFilled(Organization),,);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure Add(Command)
	NotifyChoice(New Structure("Organization, Period", 
		Organization,
		CommonClient.SessionDate()));
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	NotifyChoice(RowSelected);
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure Select(Command)
	NotifyChoice(Items.List.CurrentRow);
EndProcedure

#EndRegion