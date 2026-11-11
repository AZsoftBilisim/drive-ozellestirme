#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not ValueIsFilled(Parameters.TimeConsumingOperationKind) Then
		Cancel = True;
		Return;
	EndIf;
	
	OperationParametersList = Parameters.OperationParametersList;
	FormParameters = FillInParametersForOpeningGeneralFormOfLongTermOperation(ThisObject);
	TimeConsumingOperationKind = Parameters.TimeConsumingOperationKind;
	
	// design of form elements
	NoteTemplate = NStr("vi = 'Biểu mẫu được gọi ra từ phương thức ""%1"" của mô-đun quản lý ""%2"" để hiển thị biểu mẫu chung ""%3"".';
						|ru = 'Форма вызывается из метода ""%1"" модуля менеджера ""%2"" для показа общей формы ""%3"".';
						|en = 'The form is called from the ""%1"" method of the ""%2"" manager module to display the ""%3"" common form.'; fa = 'The form is called from the ""%1"" method of the ""%2"" manager module to display the ""%3"" common form.';
						|it = 'Форма вызывается из метода ""%1"" модуля менеджера ""%2"" для показа общей формы ""%3"".';
						|pl = 'The form is called from the ""%1"" method of the ""%2"" manager module to display the ""%3"" common form.';
						|tr = 'Form, ""%3"" genel formunun gösterilmesi için ""%2"" yönetici modülünün ""%1"" yöntemi üzerinden çağrılır.'");
	NameOfMethodCall = "FormGetProcessing";
	ExplanationText = StringFunctionsClientServer.SubstituteParametersToString(
		NoteTemplate,
		NameOfMethodCall,
		FormAttributeToValue("Object").Metadata().FullName(),
		Metadata.CommonForms.TimeConsumingOperation.Name);
	Items.DecorationNote.Title = ExplanationText;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If TimeConsumingOperationKind = "DistributeSettlementsWithClients" Then
		Cancel = True;
		CallbackOnCompletion = New CallbackDescription("OpenGeneralFormOfLongTermOperationDistributeSettlementsWithClientsEnd", ThisObject);
		TimeConsumingOperationForm = OpenForm("CommonForm.TimeConsumingOperation", FormParameters, FormOwner,,,, CallbackOnCompletion);
		If Not ValueIsFilled(FormParameters.JobID) Then
			GeneratingFiscalChecksServerCall.DistributeSettlementsWithClients(OperationParametersList);
			If TimeConsumingOperationForm.IsOpen() Then
				TimeConsumingOperationForm.Close();
			EndIf;
		EndIf;
	Else
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure OpenReceiptPreviewProcessingForm()
	
	CallbackOnCompletion = Undefined;
	If Not CallbackDescriptionOnClose = Undefined Then
		CallbackOnCompletion = New CallbackDescription(CallbackDescriptionOnClose.ProcedureName,
														CallbackDescriptionOnClose.Module,
														CallbackDescriptionOnClose.AdditionalParameters);
	EndIf;
	FormOpenParameters = New Structure("OperationParametersList", OperationParametersList);
	OpenForm("DataProcessor.PreviewReceipt.Form", FormOpenParameters, FormOwner, , , , CallbackOnCompletion, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtServerNoContext
Function FillInParametersForOpeningGeneralFormOfLongTermOperation(Form)
	
	FormParameters = New Structure;
	FormParameters.Insert("MessageText", 				Form.Parameters.MessageText);
	FormParameters.Insert("JobID", 		Form.Parameters.JobID);
	FormParameters.Insert("OutputIdleWindow",       	Form.Parameters.OutputIdleWindow);
	FormParameters.Insert("OutputProgressBar", 	Form.Parameters.OutputProgressBar);
	FormParameters.Insert("OutputMessages",          	Form.Parameters.OutputMessages);
	
	Return FormParameters;
EndFunction

&AtClient
Procedure OpenGeneralFormOfLongTermOperationDistributeSettlementsWithClientsEnd(Result, AdditionalParameters) Export
	
	If ARAPAccountsHaveBeenCalculated(OperationParametersList) Then
		OpenReceiptPreviewProcessingForm();
		CallbackDescriptionOnClose = Undefined;
	Else
		CommonClient.MessageToUser(NStr("vi = 'Không thể in phiếu. Không thể thực hiện giao dịch cập nhật phân bổ hạch toán với khách hàng.
														|Thông tin chi tiết trong nhật ký sự kiện.';
														|ru = 'Печать чека невозможна. Не выполнена операция актуализации распределения расчетов с клиентами.
														|Подробная информация в журнале регистрации.';
														|en = 'Cannot print the receipt. The allocation of customer AR/AP is not updated.
														|For more information, see the event log.'; fa = 'Cannot print the receipt. The allocation of customer AR/AP is not updated.
														|For more information, see the event log.';
														|it = 'Печать чека невозможна. Не выполнена операция актуализации распределения расчетов с клиентами.
														|Подробная информация в журнале регистрации.';
														|pl = 'Cannot print the receipt. The allocation of customer AR/AP is not updated.
														|For more information, see the event log.';
														|tr = 'Fiş yazdırma mümkün değildir. İstemcilerle mutabakat dağılımının güncellenmesi işlemi gerçekleştirilmemiştir.
														|Detaylı bilgi kayıt defterinde.'"));
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ARAPAccountsHaveBeenCalculated(OperationParametersList)
	Return GeneratingFiscalChecksServerOverridable.ARAPAccountsHaveBeenCalculated(OperationParametersList);
EndFunction

#EndRegion
