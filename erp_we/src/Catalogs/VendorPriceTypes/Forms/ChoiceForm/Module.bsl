
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	If Not Parameters.ChoosingPartner Then
		Items.OwnerFilter.Visible = False;
		Items.Owner.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerFilterOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner",
		OwnerFilter,
		DataCompositionComparisonType.Equal,,
		ValueIsFilled(OwnerFilter));
		
	Items.Owner.Visible = Not ValueIsFilled(OwnerFilter);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

