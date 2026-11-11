#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	Items.ReplaceDuplicates.Visible = Users.IsFullUser();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ReplaceDuplicates(Command)
	ReplaceDuplicatesOnServer();
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ReplaceDuplicatesOnServer()
	Catalogs.KeysForLotVendorAttributes.ReplaceDimensionKeyDuplicates();
	Items.List.Refresh();
EndProcedure

#EndRegion