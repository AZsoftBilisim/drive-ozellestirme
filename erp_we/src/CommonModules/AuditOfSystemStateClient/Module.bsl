////////////////////////////////////////////////////////////////////////////////
// Subsystem "System state audit".
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function CheckTaskCompletion(Form, IdleHandlerParameters, TimeConsumingOperationForm) Export
	
	JobCompleted = False;
	
	Try
		If TimeConsumingOperationForm.IsOpen()
			And TimeConsumingOperationForm.JobID = Form.JobID Then
			If Form.JobCompleted(Form.JobID) Then
				TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
				JobCompleted = True;
			Else
				TimeConsumingOperationsClient.UpdateIdleHandlerParameters(IdleHandlerParameters);
				Form.AttachIdleHandler(
					"Attachable_CheckTaskCompletion",
					IdleHandlerParameters.CurrentInterval,
					True);
			EndIf;
		EndIf;
	Except
		TimeConsumingOperationsClient.CloseTimeConsumingOperationForm(TimeConsumingOperationForm);
		Raise;
	EndTry;
	
	Return JobCompleted;
	
EndFunction

#EndRegion
