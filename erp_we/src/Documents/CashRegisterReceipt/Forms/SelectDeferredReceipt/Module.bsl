
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	KKMOtborTicketOffice        = Parameters.CashRegister;
	LoyaltyCardSelection = Parameters.LoyaltyCard;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "CashRegister", KKMOtborTicketOffice, DataCompositionComparisonType.Equal,,ValueIsFilled(KKMOtborTicketOffice));
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "LoyaltyCard", LoyaltyCardSelection, DataCompositionComparisonType.Equal,,ValueIsFilled(LoyaltyCardSelection));
		
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KKMOtborTicketOfficeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "CashRegister", KKMOtborTicketOffice, DataCompositionComparisonType.Equal,,ValueIsFilled(KKMOtborTicketOffice));
	
EndProcedure

&AtClient
Procedure LoyaltyCardSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "LoyaltyCard", LoyaltyCardSelection, DataCompositionComparisonType.Equal,,ValueIsFilled(LoyaltyCardSelection));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion
