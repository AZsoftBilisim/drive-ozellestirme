
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SplitOrdersByAssignments = Parameters.SplitOrdersByAssignments;
	SplitOrdersByWarehouses = Parameters.SplitOrdersByWarehouses;
	SplitOrdersByReleaseLaunchDates = Parameters.SplitOrdersByReleaseLaunchDates;
	
	Items.SplitOrdersByAssignments.Visible = Parameters.DestinationVisibility;
	Items.SplitOrdersByAssignments.Enabled = Parameters.AvailabilityOfDestinationSettings;
	Items.SplitOrdersByReleaseLaunchDates.Visible = Parameters.DynamicStructure;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	
	OrderCreationParameters = New Structure();
	OrderCreationParameters.Insert("SplitOrdersByAssignments", SplitOrdersByAssignments);
	OrderCreationParameters.Insert("SplitOrdersByWarehouses", SplitOrdersByWarehouses);
	OrderCreationParameters.Insert("SplitOrdersByReleaseLaunchDates", SplitOrdersByReleaseLaunchDates);
	
	NotifyChoice(OrderCreationParameters);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
