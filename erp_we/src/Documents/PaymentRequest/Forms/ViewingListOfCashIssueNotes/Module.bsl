
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Var ValueOfHeaderParameter;
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	PaymentDocumentList.LoadValues(Parameters.PaymentDocumentList.UnloadValues());
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chứng từ thanh toán (%1)';
			|ru = 'Документы оплаты (%1)';
			|en = 'AR/AP transactions (%1)'; fa = 'AR/AP transactions (%1)';
			|it = 'Documenti di pagamento (%1)';
			|pl = 'Dokumenty płatności (%1)';
			|tr = 'Ödeme belgeleri (%1)'"),
		PaymentDocumentList.Count());
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PaymentDocumentListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ShowValue(Undefined, Items.PaymentDocumentList.CurrentData.Value);
	
EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

