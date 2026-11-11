#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Form = CommandExecuteParameters.Source;
	ClearMessages();
	ResultOfActions = SupplyInDocumentsServerCall.PerformActionInOrderList(
		CommandParameter,
		"ACTION_LOAD",
		Form.UUID);
		
	If ProvisionInDocumentsClient.ResultOfPerformingActionsNeedQuestion(ResultOfActions) Then
		ProvisionInDocumentsClient.ShowQuestionUncheckShipByOneDateForListOfOrders(
			CommandParameter,
			"ACTION_LOAD",
			ResultOfActions,
			Form);
	Else
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		AdditionalParameters = New Structure("Form,Orders",
			Form, CommandParameter);
		TimeConsumingOperationsClient.WaitCompletion(ResultOfActions,
			New CallbackDescription("CommandProcessingCompletion", ThisObject, AdditionalParameters),
			IdleParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Internal

&AtClient
Procedure CommandProcessingCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		
		Return;
		
	ElsIf Result.Status = "Error" Then
		
		ShowMessageBox(, Result.BriefErrorDescription);
		
	Else
		
		Form = AdditionalParameters.Form;
		ResultOfActions = GetFromTempStorage(Result.ResultAddress);
		Form.OrdersToCheckTheInventoryAllocationTask.LoadValues(AdditionalParameters.Orders);
		Form.AttachIdleHandler("Attachable_CheckWhetherInventoryAllocationTaskIsCompletedForOrders", 1, True);
		ProvisionInDocumentsClient.ReportResultsOfActionsInOrderList(ResultOfActions);
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
