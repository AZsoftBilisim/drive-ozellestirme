#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("NotThisScenario") Then
		
		If TypeOf(Parameters.NotThisScenario) = Type("FixedArray") Then
			LinkToThisScript = New ValueList;
			LinkToThisScript.LoadValues(New Array(Parameters.NotThisScenario));
			ListComparisonView = DataCompositionComparisonType.NotInList;
		Else
			LinkToThisScript = Parameters.NotThisScenario;
			ListComparisonView = DataCompositionComparisonType.NotEqual;
		EndIf;
		
		ListSelectionsClientServer.SetListSelectionElement(
			List, "Ref", LinkToThisScript, ListComparisonView);
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

