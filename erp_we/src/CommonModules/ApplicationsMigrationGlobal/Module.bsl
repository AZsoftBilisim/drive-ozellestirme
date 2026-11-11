#Region Internal

// It is necessary due to the fact that the waiting handler is not executed in the web client in an unopened form
Procedure UpdateStatusOfTransitionToService() Export
	
	Form = ApplicationsMigrationClient.GoToServiceForm();
	If Form = Undefined Then
		DetachIdleHandler("UpdateStatusOfTransitionToService");
	Else
		Form.UpdatingTransitionStatus();
	EndIf;
	
EndProcedure

Procedure EnableServiceStatusUpdateHandler() Export
	
	AttachIdleHandler("UpdateStatusOfTransitionToService", 5, False);
	
EndProcedure

Procedure DisableServiceStatusUpdateHandler() Export
	
	DetachIdleHandler("UpdateStatusOfTransitionToService");
	
EndProcedure

#EndRegion
