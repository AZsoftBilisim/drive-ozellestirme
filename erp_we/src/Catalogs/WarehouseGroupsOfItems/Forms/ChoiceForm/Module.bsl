#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	AssignedPurchaseSale = Undefined;
	
	If Parameters.Property("AssignedPurchaseSale", AssignedPurchaseSale) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List, 
			"PhysicallyDifferentFromAssignment", 
			AssignedPurchaseSale, 
			DataCompositionComparisonType.Equal,, 
			Not AssignedPurchaseSale);	
			
	EndIf;
	
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

