#Region Public

// Open the preview of the cheque
// 
// Parameters:
// 	Form - ClientApplicationForm - the form of the document
// 	FiscalTransactionCompletion - CallbackDescription - Form closing handler
Procedure DisplayReceipt(Form, FiscalTransactionCompletion) Export
	
	ClearMessages();
	
	ProcessRecordingMode(CreateStructureForProcessingReceiptDisplayParameters(Form, FiscalTransactionCompletion));
	
EndProcedure

// Executes the fiscalization command
//
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form
// 	URL - String - Name of the fiscalization command
// 	StandardProcessing - Boolean - Flag for standard processing
//
Procedure FiscalOperationNavigationLinkProcessing(Form, URL, StandardProcessing) Export
	
	StandardProcessing = False;
	
	FiscalizationParameters = TMCommonUseClientServer.GetEngineDataFromFormCache(Form, "RetailSales");
	
	If "IssueCashReceipt" = URL Then
		
		GeneratingFiscalChecksClient.DisplayReceipt(
			Form,
			New CallbackDescription("FiscalTransactionCompletion", Form));
			
	ElsIf "PunchReceiptCollectionWithdrawal" = URL Then
		
		EquipmentConnectedToTradingFacility = TMPeripheralsServerCall.EquipmentConnectedOnTradeObjectInteractingOnlineWith1C(FiscalizationParameters.RetailFacility);
		If EquipmentConnectedToTradingFacility.CREWITHDATATRANSFER.Count() = 1 Then
			FiscalizationParameters.Insert("Peripherals_", EquipmentConnectedToTradingFacility.CREWITHDATATRANSFER[0]);
		EndIf;
		
		AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
		
		TMPeripheralsClient.PunchCheckWithdrawalOfFunds(
			Form,
			FiscalizationParameters,
			DocumentWriteMode.Posting,
			New CallbackDescription("FiscalTransactionCompletion", Form, AdditionalNotificationParameters));
		
	ElsIf "PunchReceiptCollectionDeposit" = URL Then
		
		EquipmentConnectedToTradingFacility = TMPeripheralsServerCall.EquipmentConnectedOnTradeObjectInteractingOnlineWith1C(FiscalizationParameters.RetailFacility);
		If EquipmentConnectedToTradingFacility.CREWITHDATATRANSFER.Count() = 1 Then
			FiscalizationParameters.Insert("Peripherals_", EquipmentConnectedToTradingFacility.CREWITHDATATRANSFER[0]);
		EndIf;
		
		AdditionalNotificationParameters = New Structure("ResultOfFiscalOperation,DocumentReference", Undefined, Undefined);
		
		TMPeripheralsClient.PunchReceiptDepositFunds(
			Form,
			FiscalizationParameters,
			DocumentWriteMode.Posting,
			New CallbackDescription("FiscalTransactionCompletion", Form, AdditionalNotificationParameters));
		
	ElsIf "OpenRecordOfFiscalTransaction" = URL Then
		
		TMPeripheralsClient.OpenRecordOfFiscalTransaction(Form, Form.Object.Ref);
		
	ElsIf "ConfigureHardware_" = URL Then
		
		OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection");
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function CreateStructureForProcessingReceiptDisplayParameters(Form, FiscalTransactionCompletion)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                   Form);
	AdditionalParameters.Insert("OperationParametersList",       New Structure);
	AdditionalParameters.Insert("NotificationOnCompletion", FiscalTransactionCompletion);
	
	Return AdditionalParameters;
	
EndFunction

Function DocumentPosted(AdditionalParameters)
	
	DocumentPosted = True;
	
	If Not AdditionalParameters.Form.Object.Posted Or AdditionalParameters.Form.Modified Then
		DocumentPosted = False;
	EndIf;
	
	Return DocumentPosted;
	
EndFunction

Procedure UpdateOperationParameters(AdditionalParameters)
	
	OperationParametersList = TMCommonUseClientServer.GetEngineDataFromFormCache(
		AdditionalParameters.Form,
		"RetailSales");
	
	AdditionalParameters.OperationParametersList.Insert("OperationParametersList", OperationParametersList);
	
EndProcedure

#Region ProcessingDocumentRecordingMode

Procedure AfterAnsweringQuestionAboutHoldingDocument(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		TMPeripheralsClient.WriteObject(
			AdditionalParameters.Form,
			DocumentWriteMode.Posting,
			New CallbackDescription("DisplayReceiptAfterWritingDocument", ThisObject, AdditionalParameters));
		
	EndIf;
	
EndProcedure

// Notification handler after document recording
// 
// Parameters:
// 	Result - Boolean - The result records of a document (TRUE if recorded)
// 	AdditionalParameters - Structure - Additional operation parameters, consists of:
// 	* Form - ClientApplicationForm - The Form of the document consists of:
// 	** Object - DocumentObject - The main props of the form
// 	* OperationParametersList - Structure - The main parameters of the operation on the document
// 	* NotificationOnCompletion - CallbackDescription -
Procedure DisplayReceiptAfterWritingDocument(Result, AdditionalParameters) Export
	
	If Not DocumentPosted(AdditionalParameters) Then
		
		ErrorText = NStr("vi = 'Không thể kết chuyển chứng từ';
						|ru = 'Не удалось провести документ';
						|en = 'Cannot post the document'; fa = 'Cannot post the document';
						|it = 'Non è possibile registrare il documento';
						|pl = 'Nie udało się zaksięgować dokument';
						|tr = 'Belge kaydedilemedi'");
		HandleError(ErrorText, AdditionalParameters.NotificationOnCompletion);
		
	Else

		Form = AdditionalParameters.Form;
		
		// See GeneratingFiscalChecksServer.DataVerificationBeforeFiscalTransaction
		CheckParameters = New Structure;
		CheckParameters.Insert("FormName", Form.FormName);
		CheckParameters.Insert("ReceiptPrintingCommandName", "");
		If TMCommonUseClientServer.HasObjectAttribute(Form, "ReceiptPrintingCommandName") Then
			CheckParameters.Insert("ReceiptPrintingCommandName", Form.ReceiptPrintingCommandName);
		EndIf;
		CheckParameters.Insert("CalculationType", Undefined);
		If TMCommonUseClientServer.HasObjectAttribute(Form, "CalculationType") Then
			CheckParameters.Insert("CalculationType", Form.CalculationType);
		EndIf;

		If DataVerificationBeforeFiscalTransaction(Form.Object, CheckParameters) Then
			UpdateOperationParameters(AdditionalParameters);
			OpenReceiptPreviewForm(AdditionalParameters);
		Else
			HandleError(Undefined, AdditionalParameters.NotificationOnCompletion);	
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ProcessRecordingMode(AdditionalParameters)
	
	If Not DocumentPosted(AdditionalParameters) Then
		DisplayQuestionOfNeedForDocument(AdditionalParameters);
	Else
		DisplayReceiptAfterWritingDocument(True, AdditionalParameters);
	EndIf;
	
EndProcedure

Procedure DisplayQuestionOfNeedForDocument(AdditionalParameters)
	
	ShowQueryBox(
		New CallbackDescription("AfterAnsweringQuestionAboutHoldingDocument", ThisObject, AdditionalParameters),
		NStr("vi = 'Giao dịch chỉ có thể sau khi kết chuyển chứng từ, kết chuyển chứng từ?';
			|ru = 'Операция возможна только после проведения документа, провести документ?';
			|en = 'The operation is possible only after posting the document. Post the document?'; fa = 'The operation is possible only after posting the document. Post the document?';
			|it = 'L''operazione è possibile solo dopo la registrazione del documento in contabilità, registrare il documento?';
			|pl = 'Operacja jest możliwa tylko po zaksięgowaniu dokumentu, zaksięgować dokument?';
			|tr = 'İşlem yalnızca bir belge kaydedildikten sonra mümkündür, belgeyi kaydedilsin mi?'"),
		QuestionDialogMode.YesNo);
	
EndProcedure

Procedure HandleError(ErrorText, NotificationOnCompletion)
	
	If ValueIsFilled(ErrorText) Then
		CommonClient.MessageToUser(ErrorText);
	EndIf;
	If NotificationOnCompletion <> Undefined Then
		RunCallback(NotificationOnCompletion, False);
	EndIf;
	
EndProcedure

// See GeneratingFiscalChecksServer.DataVerificationBeforeFiscalTransaction
Function DataVerificationBeforeFiscalTransaction(Object, CheckParameters) Export
	Return GeneratingFiscalChecksServerCall.DataVerificationBeforeFiscalTransaction(Object, CheckParameters);	
EndFunction

#EndRegion

Procedure OpenReceiptPreviewForm(AdditionalParameters)
	
	OperationParametersList       = AdditionalParameters.OperationParametersList;
	FormOwner           = AdditionalParameters.Form;
	NotificationOnCompletion = AdditionalParameters.NotificationOnCompletion;
	
	OpenForm("DataProcessor.PreviewReceipt.Form", OperationParametersList, FormOwner,,,, NotificationOnCompletion);
	
EndProcedure

#EndRegion
