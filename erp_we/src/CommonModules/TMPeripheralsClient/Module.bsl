
#Region Public

// Enables or disables hardware depending on the transmitted connection status
// 
// Parameters:
// 	ConnectionStatus - Boolean - The connection status of the equipment: True - connected, False - disable
// 	Form - ClientApplicationForm - the form of the document
// 	UsedEquipment - Array of CatalogRef.Peripherals - Equipment available to the current user
// 	 , including acquiring terminals.
// 	EquipmentTable - ValueTable - List of available receipt printing equipment
// 	CompletionNotification - CallbackDescription - Notification of completion of the action
Procedure SetHardwareConnectionStatus(ConnectionStatus, Form, UsedEquipment, EquipmentTable, CompletionNotification = Undefined) Export
	
	For Each Equipment In UsedEquipment Do
		Context = New Structure;
		Context.Insert("Equipment", Equipment);
		Context.Insert("EquipmentTable", EquipmentTable);
		Context.Insert("UUID", Form.UUID);
		Context.Insert("CompletionNotification", CompletionNotification);
		
		If ConnectionStatus Then
			CallbackDescription = New CallbackDescription("StartConnectingEquipmentByIdCompletion", ThisObject, Context);
			EquipmentManagerClient.StartConnectingEquipmentById(CallbackDescription, Form.UUID, Equipment);
		Else
			CallbackDescription = New CallbackDescription("Start_DisablingEquipmentByIdCompletion", ThisObject, Context);
			EquipmentManagerClient.Start_DisablingEquipmentById(CallbackDescription, Form.UUID, Equipment);
		EndIf;
		
	EndDo;
	
EndProcedure

// To open the preview of the check registers.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  OperationParametersList - Structure - structure with properties:
//   * DocumentRef - DocumentRef -;
//   * Organization - CatalogRef.Companies -;
//   * RetailFacility - CatalogRef -;
//   * Peripherals_ - CatalogRef.Peripherals - ;
//   * Sum - Number -;
//   * CashWithdrawalFromCashRegister - DocumentRef.CashWithdrawalFromCashRegister - ;
//   * DepositCashIntoCashRegister - DocumentRef.DepositCashIntoCashRegister - ;
//  WriteMode - DocumentWriteMode - Recording mode.
//  NotificationOnCompletion - CallbackDescription - description of the alert.
//
Procedure IssueCashReceipt(Form, OperationParametersList, WriteMode, NotificationOnCompletion = Undefined) Export
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                   Form);
	AdditionalParameters.Insert("OperationParametersList",       OperationParametersList);
	AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
	AdditionalParameters.Insert("DocumentWriteMode",    WriteMode);
	AdditionalParameters.Insert("ProcedureName",            "BreakingThroughReceiptAfterWritingDocument");
	
	ProcessRecordingMode(True, AdditionalParameters);
	
EndProcedure

// Punch the cash withdrawal receipt.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  OperationParametersList - Structure - structure with properties:
//   * DocumentRef - DocumentRef -;
//   * Organization - CatalogRef.Companies -;
//   * RetailFacility - CatalogRef -;
//   * Peripherals_ - CatalogRef.Peripherals - ;
//   * Sum - Number -;
//   * CashWithdrawalFromCashRegister - DocumentRef.CashWithdrawalFromCashRegister - ;
//   * DepositCashIntoCashRegister - DocumentRef.DepositCashIntoCashRegister - ;
//  WriteMode - DocumentWriteMode - Recording mode.
//  NotificationOnCompletion - CallbackDescription - description of the alert.
//
Procedure PunchCheckWithdrawalOfFunds(Form, OperationParametersList, WriteMode, NotificationOnCompletion) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                   Form);
	AdditionalParameters.Insert("OperationParametersList",       OperationParametersList);
	AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
	AdditionalParameters.Insert("DocumentWriteMode",    WriteMode);
	AdditionalParameters.Insert("ProcedureName",            "PenetrationOfCheckWithdrawalOfFundsAfterRecordingDocument");
	
	RetailSalesClient.ProcessShiftState(
		Form,
		New CallbackDescription("ProcessRecordingMode", ThisObject, AdditionalParameters));
	
EndProcedure

// Punch the receipt for depositing funds.
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  OperationParametersList - Structure - structure with properties:
//   * DocumentRef - DocumentRef -;
//   * Organization - CatalogRef.Companies -;
//   * RetailFacility - CatalogRef -;
//   * Peripherals_ - CatalogRef.Peripherals - ;
//   * Sum - Number -;
//   * CashWithdrawalFromCashRegister - DocumentRef.CashWithdrawalFromCashRegister - ;
//   * DepositCashIntoCashRegister - DocumentRef.DepositCashIntoCashRegister - ;
//  WriteMode - DocumentWriteMode - Recording mode.
//  NotificationOnCompletion - CallbackDescription - description of the alert.
//
Procedure PunchReceiptDepositFunds(Form, OperationParametersList, WriteMode, NotificationOnCompletion) Export
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                   Form);
	AdditionalParameters.Insert("OperationParametersList",       OperationParametersList);
	AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
	AdditionalParameters.Insert("DocumentWriteMode",    WriteMode);
	AdditionalParameters.Insert("ProcedureName",            "BreakingThroughCheckDepositingFundsAfterRecordingDocument");
	
	RetailSalesClient.ProcessShiftState(
		Form,
		New CallbackDescription("ProcessRecordingMode", ThisObject, AdditionalParameters));
	
EndProcedure

// The procedure creates a queue of receipts for subsequent fiscal processing
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  OperationParametersList - Structure - structure with properties:
//   * DocumentRef - DocumentRef -;
//   * Organization - CatalogRef.Companies -;
//   * RetailFacility - CatalogRef -;
//   * Peripherals_ - CatalogRef.Peripherals - ;
//   * Sum - Number -;
//   * CashWithdrawalFromCashRegister - DocumentRef.CashWithdrawalFromCashRegister - ;
//   * DepositCashIntoCashRegister - DocumentRef.DepositCashIntoCashRegister - ;
//  WriteMode - DocumentWriteMode - Recording mode.
//  NotificationOnCompletion - CallbackDescription - description of the alert.
//
Procedure CreateReceiptQueue(Form, OperationParametersList, WriteMode, NotificationOnCompletion = Undefined) Export
	
	ClearMessages();
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Form",                   Form);
	AdditionalParameters.Insert("OperationParametersList",       OperationParametersList);
	AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
	AdditionalParameters.Insert("DocumentWriteMode",    WriteMode);
	AdditionalParameters.Insert("ProcedureName",            "CreateReceiptQueueAfterWritingDocument");
	
	ProcessRecordingMode(True, AdditionalParameters);
	
EndProcedure

// To access the form for recording fiscal transactions. Integration with the PCM
//
// Parameters:
//  Form - ClientApplicationForm - shape.
//  DocumentBasis - DocumentRef - Link to the Foundation document
//  RecordID - String, Undefined - The record ID;
//  CalculationType - EnumRef.CashSettlementTypes - Calculation type
//
Procedure OpenRecordOfFiscalTransaction(Form, Val DocumentBasis, RecordID = Undefined, CalculationType = Undefined) Export
	
	If RecordID = Undefined Then
		FiscalOperationData = GeneratingFiscalChecksServerCall.DataOfPunchedFiscalCheckForDocument(DocumentBasis, CalculationType);
		If FiscalOperationData = Undefined Then
			Return;
		EndIf;
		
		DocumentBasis = FiscalOperationData.DocumentBasis;
		RecordID = FiscalOperationData.RecordID;
	EndIf;
	
	WriteParameters = New Structure();
	WriteParameters.Insert("DocumentBasis",   DocumentBasis);
	WriteParameters.Insert("RecordID", RecordID);
	
	KeyValue = New Array;
	KeyValue.Add(WriteParameters);
	
	RecordKey = New("InformationRegisterRecordKey.FiscalTransactions", KeyValue);
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RecordKey);
	
	OpenForm("InformationRegister.FiscalTransactions.Form.RecordForm", FormParameters, Form);
	
EndProcedure

// Checks whether the cash register equipment is connected to a document or a form for previewing a receipt.
// 
// Parameters:
//  DocumentRef - DocumentRef - The document to check the Status of
// 
// Returns:
//  Boolean - True if the cash register equipment is connected to the document
Function CashRegisterEquipmentIsConnectedToDocument(DocumentRef) Export
	
	CashRegisterEquipmentIsConnectedToDocument = False;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoice")
		Or TypeOf(DocumentRef) = Type("DocumentRef.ReturnOfGoodsFromCustomer") Then
		CashRegisterEquipmentIsConnectedToDocument = True;
	EndIf;
	
	Return CashRegisterEquipmentIsConnectedToDocument;
	
EndFunction

// Get the structure of the details of the cash collection operation of the cash node.
// 
// Returns:
//  Structure - structure with properties:
//   * Date - Date - Transaction date.
//   * DocumentBasis - DocumentRef - Link to the Foundation document.
//   * Organization - DefinedType.CompanyCEL - Organization.
//   * RetailFacility - DefinedType.RetailFacilityCEL - Trade object.
//   * Device - CatalogRef.Peripherals - Device.
//   * OperationType - EnumRef.TypesOfCashOperatingUnitOperation - Type of operation.
//   * Sum - Number - The amount.
//   * AdditionalParameters - Structure - advanced setting.
//
Function StructureDetailsOfCashNodeCollectionOperation() Export
	
	AdditionalParameters = New Structure;
	
	Attributes = New Structure;
	
	Attributes.Insert("Date");
	Attributes.Insert("DocumentBasis");
	Attributes.Insert("Organization");
	Attributes.Insert("RetailFacility");
	Attributes.Insert("Device");
	
	Attributes.Insert("OperationType");
	Attributes.Insert("Sum");
	
	Attributes.Insert("AdditionalParameters", AdditionalParameters);
	
	Return Attributes;
	
EndFunction

// Write an object.
//
// Parameters:
//  Form - ManagedFormExtensionForCatalogs - shape.
//  Var_DocumentWriteMode - DocumentWriteMode - Recording mode.
//  CallbackDescription - CallbackDescription - description of the alert.
//
Procedure WriteObject(Form, Var_DocumentWriteMode, CallbackDescription) Export
	
	ResponseViaNotificationDescription = TMCommonUseClientServer.HasObjectAttribute(Form, "NotExecuteCheck1BeforeWrite");
	
	Posted = False;
	Try
		
		If ResponseViaNotificationDescription Then
			
			Form.Write(
				New Structure(
					"WriteMode, ActionAfterRecording",
					Var_DocumentWriteMode,
					CallbackDescription));
			
		Else
			
			Posted = Form.Write(
				New Structure(
					"WriteMode",
					Var_DocumentWriteMode));
			
		EndIf;
		
	Except
		
		Posted = False;
		
	EndTry;
	
	If Not ResponseViaNotificationDescription Then
		RunCallback(CallbackDescription, Posted);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure AfterAnsweringQuestionAboutDocumentEntry(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		
		If AdditionalParameters.NotificationOnCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		EndIf;
		
	Else
		
		WriteObject(
			AdditionalParameters.Form,
			AdditionalParameters.DocumentWriteMode,
			New CallbackDescription(AdditionalParameters.ProcedureName, ThisObject, AdditionalParameters));
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - Boolean, Undefined -;
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
//
Procedure BreakingThroughReceiptAfterWritingDocument(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Not Result Then
		
		If AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Write Then
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể ghi chứng từ';
					|ru = 'Не удалось записать документ';
					|en = 'Cannot save the document'; fa = 'Cannot save the document';
					|it = 'Non è stato possibile registrare documento';
					|pl = 'Nie udało się zapisać dokument';
					|tr = 'Belge kaydedilemedi'"));
		Else
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể kết chuyển chứng từ';
					|ru = 'Не удалось провести документ';
					|en = 'Cannot post the document'; fa = 'Cannot post the document';
					|it = 'Non è possibile registrare il documento';
					|pl = 'Nie udało się zaksięgować dokument';
					|tr = 'Belge kaydedilemedi'"));
		EndIf;
		
		If AdditionalParameters.NotificationOnCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		EndIf;
		
	Else
		
		If AdditionalParameters.OperationParametersList.DocumentRef <> Undefined
			And Not ValueIsFilled(AdditionalParameters.OperationParametersList.DocumentRef) Then
			AdditionalParameters.OperationParametersList.DocumentRef = AdditionalParameters.Form.Object.Ref;
		EndIf;
		
		OpenForm(
			"DataProcessor.PreviewReceipt.Form",
			AdditionalParameters.OperationParametersList,
			AdditionalParameters.Form,,,,
			AdditionalParameters.NotificationOnCompletion);
		
	EndIf;
	
EndProcedure

// Parameters:
// Result - Boolean, Undefined - ;
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
//
Procedure PenetrationOfCheckWithdrawalOfFundsAfterRecordingDocument(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Not Result Then
		
		If AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Write Then
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể ghi chứng từ';
					|ru = 'Не удалось записать документ';
					|en = 'Cannot save the document'; fa = 'Cannot save the document';
					|it = 'Non è stato possibile registrare documento';
					|pl = 'Nie udało się zapisać dokument';
					|tr = 'Belge kaydedilemedi'"));
		Else
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể kết chuyển chứng từ';
					|ru = 'Не удалось провести документ';
					|en = 'Cannot post the document'; fa = 'Cannot post the document';
					|it = 'Non è possibile registrare il documento';
					|pl = 'Nie udało się zaksięgować dokument';
					|tr = 'Belge kaydedilemedi'"));
		EndIf;
		
		If AdditionalParameters.NotificationOnCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		EndIf;
		
	Else
		
		If AdditionalParameters.OperationParametersList.DocumentRef <> Undefined
			And Not ValueIsFilled(AdditionalParameters.OperationParametersList.DocumentRef) Then
			AdditionalParameters.OperationParametersList.DocumentRef = AdditionalParameters.Form.Object.Ref;
		EndIf;
		
		NotificationOnCompletion = New CallbackDescription("LogWithdrawalOfFundsToCashDeskOfCashRegister", ThisObject, AdditionalParameters);
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("TypeOfCollection", 0);
		OperationParametersList.Insert("Sum",         AdditionalParameters.OperationParametersList.DocumentAmount);
		OperationParametersList.Insert("DocumentBasis", AdditionalParameters.OperationParametersList.DocumentRef);
		
		OperationParametersNew = PeripheralsReceiptPrintersClientServer.CollectionParameters();
		FillPropertyValues(OperationParametersNew, OperationParametersList);
		
		PeripheralsReceiptPrintersClient.StartCollectionOnFiscalDevice(
			NotificationOnCompletion,
			AdditionalParameters.Form.UUID,
			AdditionalParameters.OperationParametersList.Peripherals_,
			OperationParametersNew);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - Boolean, String - ;
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
//
Procedure BreakingThroughCheckDepositingFundsAfterRecordingDocument(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Not Result Then
		
		If AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Write Then
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể ghi chứng từ';
					|ru = 'Не удалось записать документ';
					|en = 'Cannot save the document'; fa = 'Cannot save the document';
					|it = 'Non è stato possibile registrare documento';
					|pl = 'Nie udało się zapisać dokument';
					|tr = 'Belge kaydedilemedi'"));
		Else
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể kết chuyển chứng từ';
					|ru = 'Не удалось провести документ';
					|en = 'Cannot post the document'; fa = 'Cannot post the document';
					|it = 'Non è possibile registrare il documento';
					|pl = 'Nie udało się zaksięgować dokument';
					|tr = 'Belge kaydedilemedi'"));
		EndIf;
		
		If AdditionalParameters.NotificationOnCompletion <> Undefined Then
			RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		EndIf;
		
	Else
		
		If AdditionalParameters.OperationParametersList.DocumentRef <> Undefined
			And Not ValueIsFilled(AdditionalParameters.OperationParametersList.DocumentRef) Then
			AdditionalParameters.OperationParametersList.DocumentRef = AdditionalParameters.Form.Object.Ref;
		EndIf;
		
		NotificationOnCompletion = New CallbackDescription("RecordInJournalDepositOfFundsToCashRegisterOfCashRegister", ThisObject, AdditionalParameters);
		
		OperationParametersList = New Structure;
		OperationParametersList.Insert("TypeOfCollection", 1);
		OperationParametersList.Insert("Sum",         AdditionalParameters.OperationParametersList.DocumentAmount);
		OperationParametersList.Insert("DocumentBasis", AdditionalParameters.OperationParametersList.DocumentRef);
		
		OperationParametersNew = PeripheralsReceiptPrintersClientServer.CollectionParameters();
		FillPropertyValues(OperationParametersNew, OperationParametersList);
		
		PeripheralsReceiptPrintersClient.StartCollectionOnFiscalDevice(
			NotificationOnCompletion,
			AdditionalParameters.Form.UUID,
			AdditionalParameters.OperationParametersList.Peripherals_,
			OperationParametersNew);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	Result - Boolean, Undefined - The result of executing
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
//
Procedure CreateReceiptQueueAfterWritingDocument(Result, AdditionalParameters) Export
	
	CreateReceiptQueueAfterWritingDocumentLocalization(Result, AdditionalParameters);
	
EndProcedure

// Parameters:
// 	ExecutionResult - Structure
// 	AdditionalParameters - Structure:
//		* NotificationOnCompletion - CallbackDescription
//
Procedure RecordInJournalDepositOfFundsToCashRegisterOfCashRegister(ExecutionResult, AdditionalParameters) Export
	If AdditionalParameters.NotificationOnCompletion <> Undefined Then
		AdditionalParameters.NotificationOnCompletion.AdditionalParameters.Insert("ResultOfFiscalOperation", ExecutionResult);
	EndIf;
	
	If ExecutionResult.Result Then
		
		Form = AdditionalParameters.Form;
		
		FiscalizationParameters = Undefined;
		// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
		If ExecutionResult.Property("OutputParametersSet") 
			 And ExecutionResult.OutputParametersSet.Count() > 8 Then
			FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
		EndIf;
		
		CompletionParameters = New Structure;
		CompletionParameters.Insert("CloseForm",                False);
		CompletionParameters.Insert("Form",                       Form);
		CompletionParameters.Insert("NotificationOnCompletion",     AdditionalParameters.NotificationOnCompletion);
		CompletionParameters.Insert("FiscalOperationDetails", FiscalizationParameters);
		
		PerformActionAfterRecordingFiscalTransactionInLog(
			Form,
			New CallbackDescription("FiscalTransactionIsRecordedInLog", ThisObject, CompletionParameters),
			NStr("vi = 'Không thể ghi dữ liệu vào nhật ký máy tính tiền.';
				|ru = 'Не удалось записать данные в журнал фискальных операций.';
				|en = 'Cannot save data to the fiscal transactions log.'; fa = 'Cannot save data to the fiscal transactions log.';
				|it = 'Non è stato possibile salvare i dati nel registro delle operazioni fiscali.';
				|pl = 'Nie udało się zapisać dane do dziennika operacji fiskalnych.';
				|tr = 'Mali işlem günlüğüne veri yazılamadı.'"));
		
	Else
		
		CommonClientServer.MessageToUser(ExecutionResult.ErrorDescription);
		
		RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		
	EndIf;
	
EndProcedure

// Parameters:
// 	ExecutionResult - Structure
// 	AdditionalParameters - Structure:
//		* NotificationOnCompletion - CallbackDescription
//
Procedure LogWithdrawalOfFundsToCashDeskOfCashRegister(ExecutionResult, AdditionalParameters) Export

	If AdditionalParameters.NotificationOnCompletion <> Undefined Then
		AdditionalParameters.NotificationOnCompletion.AdditionalParameters.Insert("ResultOfFiscalOperation", ExecutionResult);
	EndIf;
	
	If ExecutionResult.Result Then
		
		Form = AdditionalParameters.Form;
		
		FiscalizationParameters = Undefined;
		// If the data was not recorded in the Fiscal Operation register, an error occurred during recording.
		If ExecutionResult.Property("OutputParametersSet") 
			 And ExecutionResult.OutputParametersSet.Count() > 8 Then
			
			FiscalizationParameters = ExecutionResult.OutputParametersSet[8];
		EndIf;
		
		CompletionParameters = New Structure;
		CompletionParameters.Insert("CloseForm",                False);
		CompletionParameters.Insert("Form",                       Form);
		CompletionParameters.Insert("NotificationOnCompletion",     AdditionalParameters.NotificationOnCompletion);
		CompletionParameters.Insert("FiscalOperationDetails", FiscalizationParameters);
		
		PerformActionAfterRecordingFiscalTransactionInLog(
			Form,
			New CallbackDescription("FiscalTransactionIsRecordedInLog", ThisObject, CompletionParameters),
			NStr("vi = 'Không thể ghi dữ liệu vào nhật ký máy tính tiền.';
				|ru = 'Не удалось записать данные в журнал фискальных операций.';
				|en = 'Cannot save data to the fiscal transactions log.'; fa = 'Cannot save data to the fiscal transactions log.';
				|it = 'Non è stato possibile salvare i dati nel registro delle operazioni fiscali.';
				|pl = 'Nie udało się zapisać dane do dziennika operacji fiskalnych.';
				|tr = 'Mali işlem günlüğüne veri yazılamadı.'"));
		
	Else
		
		CommonClientServer.MessageToUser(ExecutionResult.ErrorDescription);
		
		RunCallback(AdditionalParameters.NotificationOnCompletion, False);
		
	EndIf;
	
EndProcedure

Procedure FiscalTransactionIsRecordedInLog(Result, AdditionalParameters) Export
	
	FiscalOperationDetails = AdditionalParameters.FiscalOperationDetails;
	
	If Result.OperationPerformedOnDevice
		And Result.ModifiedDataIsRecorded Then
		
		If AdditionalParameters.CloseForm Then
			AdditionalParameters.Form.Close(FiscalOperationDetails);
		Else
			RunCallback(AdditionalParameters.NotificationOnCompletion, True);
		EndIf;
		
	Else
		
		If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then
			
			FormParameters = New Structure;
			FormParameters.Insert("Data", FiscalOperationDetails.DocumentBasis);
			FormParameters.Insert("DataForEventLog", FiscalOperationDetails);
			FormParameters.Insert("MessageText",
				NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
				           |Đã đánh phiếu tính tiền, nhưng chưa được ghi nhận trong hệ thống.';
				           |ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
				           |Чек ККМ пробит, но не зафиксирован в системе.';
				           |en = 'WARNING! An exception is thrown.
				           |Receipt was issued but it was not recorded in the application.'; fa = 'WARNING! An exception is thrown.
				           |Receipt was issued but it was not recorded in the application.';
				           |it = 'ATTENZIONE! si è verificata una situazione eccezionale: 
				           |lo scontrino del registratore di cassa è stato emesso, ma non è stato registrato nel sistema.';
				           |pl = 'UWAGA! wystąpiła sytuacja wyjątkowa:
				           |Paragon kasy fiskalnej został wybity, ale nie został zarejestrowany w systemie.';
				           |tr = 'DİKKAT! İstisnai bir durum meydana geldi:
				           | Bir Yazar Kasa Cihazı fişi basıldı, ancak sisteme kaydedilmedi.'"));
			
			OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, ThisObject);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ProcessRecordingMode(Result, AdditionalParameters) Export
	
	If Result = Undefined
		Or Not Result Then
		RunCallback(AdditionalParameters.NotificationOnCompletion, False);
	EndIf;
	
	If AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Write
		And (Not ValueIsFilled(AdditionalParameters.Form.Object.Ref) Or AdditionalParameters.Form.Modified) Then
		
		ShowQueryBox(
			New CallbackDescription("AfterAnsweringQuestionAboutDocumentEntry", ThisObject, AdditionalParameters),
			NStr("vi = 'Giao dịch chỉ có thể sau khi ghi chứng từ, ghi lại chứng từ?';
				|ru = 'Операция возможна только после записи документа, записать документ?';
				|en = 'You can perform the operation only after saving the document. Do you want to save?'; fa = 'You can perform the operation only after saving the document. Do you want to save?';
				|it = 'L''operazione è possibile solo dopo la registrazione del documento, registrare il documento?';
				|pl = 'Operacja jest możliwa tylko po wykonaniu zapisu dokumentu, zapisać dokument?';
				|tr = 'İşlem yalnızca belge kaydedildikten sonra mümkündür, belgeyi kaydet?'"),
			QuestionDialogMode.YesNo);
		
	ElsIf AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Posting
		And (Not AdditionalParameters.Form.Object.Posted Or AdditionalParameters.Form.Modified) Then
		
		ShowQueryBox(
			New CallbackDescription("AfterAnsweringQuestionAboutDocumentEntry", ThisObject, AdditionalParameters),
			NStr("vi = 'Giao dịch chỉ có thể sau khi kết chuyển chứng từ, kết chuyển chứng từ?';
				|ru = 'Операция возможна только после проведения документа, провести документ?';
				|en = 'The operation is possible only after posting the document. Post the document?'; fa = 'The operation is possible only after posting the document. Post the document?';
				|it = 'L''operazione è possibile solo dopo la registrazione del documento in contabilità, registrare il documento?';
				|pl = 'Operacja jest możliwa tylko po zaksięgowaniu dokumentu, zaksięgować dokument?';
				|tr = 'İşlem yalnızca bir belge kaydedildikten sonra mümkündür, belgeyi kaydedilsin mi?'"),
			QuestionDialogMode.YesNo);
		
	Else
		CallbackDescription = New CallbackDescription(AdditionalParameters.ProcedureName, ThisObject, AdditionalParameters);
		RunCallback(CallbackDescription, True);
	EndIf;
	
EndProcedure

Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetryRecordingIsRequired = False;
		If AdditionalParameters.ProcedureName = "RecordFiscalTransactionInTransaction" Then
			OperationResult = TMPeripheralsServerCall.RecordFiscalTransactionInTransaction(
				RetryRecordingIsRequired,
				AdditionalParameters.CallbackDescription.AdditionalParameters.FiscalOperationDetails);
		EndIf;
		
		If (TypeOf(OperationResult) = Type("Boolean") And OperationResult) Then
			
			RunCallback(
				AdditionalParameters.CallbackDescription,
				?(AdditionalParameters.ReturnFunctionResult, OperationResult, AdditionalParameters.ResultOfSuccessfulImplementation));
			
		Else
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
				AdditionalParameters.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			
		EndIf;
		
	Else
		
		RunCallback(
			AdditionalParameters.CallbackDescription,
			?(AdditionalParameters.ReturnFunctionResult, AdditionalParameters.OperationResult, AdditionalParameters.CancellationResult_));
		
	EndIf;
	
EndProcedure

Procedure PerformActionAfterRecordingFiscalTransactionInLog(Form, NotificationOnCompletion, MessageText) Export
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = TMPeripheralsServerCall.RecordFiscalTransactionInTransaction(
		RetryRecordingIsRequired,
		NotificationOnCompletion.AdditionalParameters.FiscalOperationDetails);
	
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Form", Form);
		AdditionalParameters.Insert("CallbackDescription", NotificationOnCompletion);
		AdditionalParameters.Insert("MessageText", MessageText);
		AdditionalParameters.Insert("ReturnFunctionResult", False);
		AdditionalParameters.Insert("ResultOfSuccessfulImplementation", New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True));
		AdditionalParameters.Insert("CancellationResult_", New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False));
		AdditionalParameters.Insert("ProcedureName", "RecordFiscalTransactionInTransaction");
		AdditionalParameters.Insert("OperationResult", ModifiedDataIsRecorded);
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParameters);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
			AdditionalParameters.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(
			NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded",
				True, True));
		
	EndIf;
	
EndProcedure

#Region WorkingWithConnectedEquipment

Procedure StartConnectingEquipmentByIdCompletion(Data, AdditionalParameters) Export
	
	Equipment            = AdditionalParameters.Equipment;
	EquipmentTable     = AdditionalParameters.EquipmentTable;
	UUID = AdditionalParameters.UUID;
	
	If Data.Result Then
		
		FoundRows = EquipmentTable.FindRows(New Structure("Equipment", Equipment));
		
		For Each TSRow In FoundRows Do
			
			If Not TSRow.Attached Then
				
				TSRow.Attached = True;
				
				Context = New Structure;
				Context.Insert("Equipment",         TSRow.Equipment);
				Context.Insert("FDFVersion",            TSRow.FDFVersion);
				Context.Insert("CompletionNotification", AdditionalParameters.CompletionNotification);
				
				PeripheralsReceiptPrintersClient.StartGettingFiscalDeviceParameters(
					New CallbackDescription("AfterReceivingDeviceParameters", ThisObject, Context),
					UUID,
					Equipment);
				
			EndIf;
			
		EndDo;
		
	Else
		
		MessageText = NStr("vi = 'Khi kết nối thiết bị %1 đã xảy ra lỗi:
									|""%2"".';
									|ru = 'При подключении устройства %1 произошла ошибка:
									|""%2"".';
									|en = 'An error occurred when connecting the %1 device:
									|""%2"".'; fa = 'An error occurred when connecting the %1 device:
									|""%2"".';
									|it = 'Durante il collegamento dell''apparecchiatura %1 si è verificato un errore:
									|""%2"".';
									|pl = 'Podczas podłączenia urządzenia %1 wystąpił błąd:
									|""%2"".';
									|tr = '%1:
									|""%2"" cihazı bağlanırken hata oluştu.'");
		CommonClient.MessageToUser(StrTemplate(MessageText, Equipment, Data.ErrorDescription));
		
	EndIf;
	
EndProcedure

Procedure AfterReceivingDeviceParameters(ExecutionResult, AdditionalParameters) Export
	
	If ExecutionResult.Result Then
		
		Peripherals = New Structure;
		Peripherals.Insert("Equipment", AdditionalParameters.Equipment);
		Peripherals.Insert("FDFVersion",    AdditionalParameters.FDFVersion);
		
		If Not ValueIsFilled(AdditionalParameters.FDFVersion)
			And ValueIsFilled(ExecutionResult.CREParameters.VersionFDFCRE) Then
			
			Peripherals.FDFVersion = ExecutionResult.CREParameters.VersionFDFCRE;
			
		ElsIf Not ValueIsFilled(AdditionalParameters.FDFVersion) Then
			
			Peripherals.FDFVersion = GeneratingFiscalChecksServerCall.MaximumFFDVersion();
			
		EndIf;
		
		RunCallback(AdditionalParameters.CompletionNotification, Peripherals);
		
	EndIf;
	
EndProcedure

Procedure Start_DisablingEquipmentByIdCompletion(Data, Equipment) Export
	
	If Not Data.Result Then
		
		MessageText = NStr("vi = 'Khi tắt thiết bị %1 đã xảy ra lỗi:
									|""%2"".';
									|ru = 'При отключении устройства %1 произошла ошибка:
									|""%2"".';
									|en = 'An error occurred when disconnecting the %1 device:
									|""%2"".'; fa = 'An error occurred when disconnecting the %1 device:
									|""%2"".';
									|it = 'Durante la disattivazione dell''apparecchiatura %1 si è verificato un errore:
									|""%2"".';
									|pl = 'Podczas wyłączenia urządzenia %1 wystąpił błąd:
									|""%2"".';
									|tr = '%1 cihazı devre dışı bırakılırken hata oluştu:
									|""%2"".'");
		CommonClient.MessageToUser(StrTemplate(MessageText, Equipment, Data.ErrorDescription));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region WorkingWithBarcodeScanner

Function ConvertDataFromScannerToArray(Parameter) Export
	
	EquipmentManagerTMClient.ProcessEvent();
	
	Data = New Array;
	Data.Add(ConvertDataFromScannerToStructure(Parameter));
	
	Return Data;
	
EndFunction

Function ConvertDataFromScannerToStructure(Parameter) Export
	
	EquipmentManagerTMClient.ProcessEvent();
	
	If Parameter[1] = Undefined Then
		Data = New Structure("Barcode, Count", Parameter[0], 1); 	 // We get the barcode from the main data
	Else
		Data = New Structure("Barcode, Count", Parameter[1][1], 1); // We get the barcode from the additional data
	EndIf;
	
	Return Data;
	
EndFunction

#EndRegion

#Region Localization

Procedure CreateReceiptQueueAfterWritingDocumentLocalization(Result, AdditionalParameters)
	
	ResultOfDocumentRecording = False;
	If Result = Undefined
		Or Not Result Then
		
		If AdditionalParameters.DocumentWriteMode = DocumentWriteMode.Write Then
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể ghi chứng từ';
					|ru = 'Не удалось записать документ';
					|en = 'Cannot save the document'; fa = 'Cannot save the document';
					|it = 'Non è stato possibile registrare documento';
					|pl = 'Nie udało się zapisać dokument';
					|tr = 'Belge kaydedilemedi'"));
		Else
			ShowMessageBox(
				Undefined,
				NStr("vi = 'Không thể kết chuyển chứng từ';
					|ru = 'Не удалось провести документ';
					|en = 'Cannot post the document'; fa = 'Cannot post the document';
					|it = 'Non è possibile registrare il documento';
					|pl = 'Nie udało się zaksięgować dokument';
					|tr = 'Belge kaydedilemedi'"));
		EndIf;
		
	Else
		
		ResultOfDocumentRecording = True;
		If Not AdditionalParameters.OperationParametersList.Property("DocumentBasis")
			Or Not ValueIsFilled(AdditionalParameters.OperationParametersList.DocumentBasis) Then
			AdditionalParameters.OperationParametersList.Insert("DocumentBasis", AdditionalParameters.Form.Object.Ref);
		EndIf;
		
		
	EndIf;
	
	If AdditionalParameters.NotificationOnCompletion <> Undefined Then
		RunCallback(AdditionalParameters.NotificationOnCompletion, ResultOfDocumentRecording);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
