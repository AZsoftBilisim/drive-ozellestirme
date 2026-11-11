
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Filter.Property("Owner") Then
		Items.Owner.Visible = False;
	EndIf; 

	//Standard subsystems.Pluggable commands
	//Pluggable commands.Attached to the Server(this is an object);
	//The end of the standard subsystem.Pluggable commands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Exit Then
		Return;
	EndIf;
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TextOfPossibilityOfUsingServiceURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CloseBannerByClicking(Item)
	
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private


#EndRegion
