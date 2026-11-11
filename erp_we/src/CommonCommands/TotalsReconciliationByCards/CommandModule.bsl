#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	UUID = New UUID();
	CallbackDescription = New CallbackDescription("ExecuteOperationCompletion", ThisObject);
	PeripheralsPaymentSystemsServerClient.StartReconciliationOfTotalsAtAcquiringTerminal(CallbackDescription, UUID)
	
EndProcedure

&AtClient
Procedure ExecuteOperationCompletion(ExecutionResult, Parameters) Export
	
	If ExecutionResult.Result Then
		MessageText = NStr("vi = 'Đã thực hiện thành công thao tác.';
							|ru = 'Операция выполнена успешно.';
							|en = 'Operation has been successfully installed.'; fa = 'Operation has been successfully installed.';
							|it = 'Operazione completata con successo.';
							|pl = 'Operacja została wykonana pomyślnie.';
							|tr = 'İşlem başarıyla tamamlandı.'");
	Else
		MessageText = ExecutionResult.ErrorDescription;
	EndIf;
	
	CommonCELClient.MessageToUser(MessageText);
	
EndProcedure

#EndRegion