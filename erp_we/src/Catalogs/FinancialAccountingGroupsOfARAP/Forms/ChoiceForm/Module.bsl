
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") Then
		
		Catalogs.FinancialAccountingGroupsOfARAP.ConvertSelectionParametersSelection(Parameters.Filter);
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

