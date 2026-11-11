
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"DiscountMarkup",
		Parameters.DiscountMarkup,
		DataCompositionComparisonType.Equal,, True);
	
	CurrentDate = CurrentSessionDate();

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	OpeningParameters = New Structure("Key", Items.List.CurrentData.Ref);
	StandardProcessing = False;
	OpenForm("Catalog.LoyaltyPrograms.Form.ItemForm", OpeningParameters);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

