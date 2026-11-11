#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupCreate",
		"Visible",
		AccessRight("InteractiveInsert", Metadata.Catalogs.DiscountMarkupTerms));
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	DiscountsMarkupsServer.AddCommandsToCreateNewConditionsForDiscountsMarkups(ThisObject, Items.GroupCreate);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteCommandToCreateConditionsForProvisionOfDiscountsMargins(Command)
	
	DiscountsMarkupsClient.ProcessCommandToAddConditionsForGrantingDiscountsMarkups(
		ThisObject,
		Command,
		Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
