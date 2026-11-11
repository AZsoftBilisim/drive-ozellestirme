
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ManagerEvaluation    = Parameters.Key.ProbabilityOfSuccessfulCompletion;
	Probabilities        = SalesOpportunitiesServer.CalculateProbability(Parameters.Key);
	StepTotal        = Probabilities.StepTotal;
	ByManager        = Probabilities.ByManager;
	ByPartner         = Probabilities.ByPartner;
	ByTransactionKind	   = Probabilities.ByTransactionKind;
	Medium            = Probabilities.Medium;
	Calculated          = Probabilities.Calculated;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set(Command)
	
	Close(Calculated);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
