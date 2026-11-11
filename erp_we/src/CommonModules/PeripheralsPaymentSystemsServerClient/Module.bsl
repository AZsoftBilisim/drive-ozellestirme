
#Region Public

// APK: 142-off backward compatibility

// Perform operations on the acquiring terminal.
// If the acquiring terminal does not support printing receipts on the terminal, a printer is connected for printing.
// 
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification on completion.
//  ClientID - ClientApplicationForm -the ID of the form.
//  DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//  OperationParametersList - Structure - parameters for performing the operation.
//  AdditionalParameters - Structure - additional commands.
//  PrintingDevice - Undefined - The printing device.    
//
Procedure StartOperationOnAcquiringTerminal(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined, PrintingDevice = Undefined) Export
	
	DataToSupplement = EquipmentManagerClient.PrintingSlipReceiptOfAcquiringOperation();
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		For Each Item In AdditionalParameters Do
			DataToSupplement.Insert(Item.Key, Item.Value);
		EndDo;
	EndIf;
	
	OperationContext = ContextOfOperationOnAcquiringTerminal();
	OperationContext.NotificationOnCompletion = NotificationOnCompletion;
	OperationContext.ClientID    = ClientID;   
	OperationContext.DeviceID = DeviceID;
	OperationContext.PrintingDevice    = PrintingDevice;
	OperationContext.OperationParametersList       = OperationParametersList;
	OperationContext.AdditionalParameters = AdditionalParameters; 
	OperationContext.TransactionType           = OperationParametersList.TransactionType; 
	OperationContext.PrepareData       = False; 
	OperationContext.ProcessData__        = True;        
	OperationContext.PrepareDataClient = True;
	OperationContext.ProcessData__Client  = False;
	OperationContext.ProcessDataInCaseOfError = True;
	OperationContext.UsePrintingDevice = OperationParametersList.UsePrintingDevice;
	OperationContext.AdditionalParameters = DataToSupplement;
	OperationParametersList.Insert("FullSlipReceipt", OperationContext.AdditionalParameters.FullSlipReceipt);
	
	PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext);
	
EndProcedure

// Perform reconciliation of totals on the acquiring terminal.
// If the acquiring terminal does not support printing receipts on the terminal, a printer is connected for printing.
// 
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification on completion.
//  ClientID - ClientApplicationForm -the ID of the form.
//  DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//  OperationParametersList - Structure - parameters for performing the operation.
//  AdditionalParameters - Structure - additional commands.
//  PrintingDevice - Undefined - The printing device.      
//
Procedure StartReconciliationOfTotalsAtAcquiringTerminal(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined, PrintingDevice = Undefined) Export
	
	OperationContext = ContextOfOperationOnAcquiringTerminal();
	OperationContext.NotificationOnCompletion = NotificationOnCompletion;
	OperationContext.ClientID    = ClientID;   
	OperationContext.DeviceID = DeviceID;
	OperationContext.PrintingDevice    = PrintingDevice;
	OperationContext.OperationParametersList       = OperationParametersList;
	OperationContext.AdditionalParameters = AdditionalParameters; 
	OperationContext.TransactionType           = "Settlement"; 
	OperationContext.PrepareData       = False; 
	OperationContext.ProcessData__        = True;
	OperationContext.UsePrintingDevice = True;
	
	PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext);
	
EndProcedure

// Start receiving card transactions.
// 
// Parameters:
//  NotificationOnCompletion - CallbackDescription - notification on completion.
//  ClientID - ClientApplicationForm -the ID of the form.
//  DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//  OperationParametersList - Structure - parameters for performing the operation.
//  AdditionalParameters - Structure - additional commands.
//
Procedure BeginGettingTransactionsByCards(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = ContextOfOperationOnAcquiringTerminal();
	OperationContext.NotificationOnCompletion = NotificationOnCompletion;
	OperationContext.ClientID    = ClientID;   
	OperationContext.DeviceID = DeviceID;
	OperationContext.OperationParametersList       = OperationParametersList;
	OperationContext.AdditionalParameters = AdditionalParameters; 
	OperationContext.TransactionType           = "GetOperationByCards"; 
	OperationContext.PrepareData       = False; 
	OperationContext.ProcessData__        = True;
	
	PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext);
	
EndProcedure

// APK: 142-on

// Start getting map parameters.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartGettingMapParameters(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = ContextOfOperationOnAcquiringTerminal();
	OperationContext.NotificationOnCompletion = NotificationOnCompletion;
	OperationContext.ClientID    = ClientID;   
	OperationContext.DeviceID = DeviceID;
	OperationContext.PrintingDevice    = Undefined;
	OperationContext.OperationParametersList       = OperationParametersList;
	OperationContext.AdditionalParameters = AdditionalParameters; 
	OperationContext.TransactionType           = "GetCardParametrs"; 
	OperationContext.PrepareData       = False; 
	OperationContext.ProcessData__        = False;
	OperationContext.UsePrintingDevice = False;
	
	PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext);
	
EndProcedure

// Start performing an emergency cancel operation.
//
// Parameters:
//   NotificationOnCompletion - CallbackDescription - notification on completion.
//   ClientID    - ClientApplicationForm -the ID of the form.
//   DeviceID - CatalogRef.Peripherals - device ID, if undefined, a choice will be offered.
//   OperationParametersList       - Structure - parameters for performing the operation.
//   AdditionalParameters - Structure - additional commands.
//
Procedure StartPerformingEmergencyOperationCancellation(NotificationOnCompletion, ClientID, DeviceID = Undefined, OperationParametersList = Undefined, AdditionalParameters = Undefined) Export
	
	OperationContext = ContextOfOperationOnAcquiringTerminal();
	OperationContext.NotificationOnCompletion = NotificationOnCompletion;
	OperationContext.ClientID    = ClientID;   
	OperationContext.DeviceID = DeviceID;
	OperationContext.PrintingDevice    = Undefined;
	OperationContext.OperationParametersList       = OperationParametersList;
	OperationContext.AdditionalParameters = AdditionalParameters; 
	OperationContext.TransactionType           = "EmergencyVoid"; 
	OperationContext.PrepareData       = False; 
	OperationContext.ProcessData__        = False;
	OperationContext.ProcessDataInCaseOfError = False;
	OperationContext.UsePrintingDevice = False;
	
	PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext);
	
EndProcedure

// Returns the string of the last slip receipt
//
// Returns:
//  String
Function LastSlipCheck() Export
	
	Peripherals = EquipmentManagerClient.Peripherals();
	Return Peripherals.LastSlipCheck;    
	
EndFunction

// Returns possible types of batch operation of operation
// 
// Returns:
//  Map
Function BatchOperationTypesInReceiptQueue() Export
	
	Result = New Map();
	Result.Insert("NotBatchOperation", PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.NotBatchOperation"));
	Result.Insert("FiscalizeReceiptWithCardPayment", PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.FiscalizeReceiptWithCardPayment"));
	Result.Insert("SaleWithCashIssue", PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.SaleWithCashIssue"));
	Result.Insert("PurchaseWithEnrollment", PredefinedValue("Enum.BatchOperationTypesInReceiptQueue.PurchaseWithEnrollment"));
	Return Result;
	
EndFunction

#EndRegion

#Region Internal

// Sets the line of the last slip receipt
//
// Parameters:
//  SlipReceiptText - String
Procedure SetLastSlipReceipt(SlipReceiptText) Export
	Peripherals = EquipmentManagerClient.Peripherals();
	Peripherals.LastSlipCheck = SlipReceiptText;
EndProcedure

 // Prepare the operation data before executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  OperationParametersList - Structure - 
// 
// Returns:
//  Structure - Prepare Operation Data:
//
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList, OperationData) Export
	
	OperationParametersList.Insert("Result", True);
	OperationParametersList.Insert("ErrorText");
	
	If Command = "PayElectronicCertificate" Or Command = "ReturnElectronicCertificate" Then
		If IsBlankString(OperationParametersList.CartID) Or OperationParametersList.AmountOfElectronicCertificate = 0 Then  
			OperationParametersList.ErrorText = NStr("vi = 'Sai tham số trong giao dịch.';
													|ru = 'Неверные параметры в операции.';
													|en = 'Incorrect parameters in the transaction.'; fa = 'Incorrect parameters in the transaction.';
													|it = 'Неверные параметры в операции.';
													|pl = 'Incorrect parameters in the transaction.';
													|tr = 'İşlemde yanlış parametreler var.'");
			OperationParametersList.Result = False; 
			Return OperationParametersList;
		EndIf;
	Else
		If Command <> "Settlement" Then
			If Not (OperationParametersList.TransactionAmount > 0) Then   
				OperationParametersList.ErrorText =  NStr("vi = 'Sai số tiền giao dịch.';
															|ru = 'Не корректная сумма операции.';
															|en = 'Incorrect operation amount.'; fa = 'Incorrect operation amount.';
															|it = 'Не корректная сумма операции.';
															|pl = 'Nie poprawna kwota operacji.';
															|tr = 'Yanlış işlem tutarı.'");
				OperationParametersList.Result = False; 
				Return OperationParametersList;
			EndIf;
		EndIf;
	EndIf;
	
	If Not IsBlankString(OperationParametersList.QrCardAttributes) And Not ConnectionParameters.ConsumerPresentedQR Then
		OperationParametersList.ErrorText = NStr("vi = 'Driver không hỗ trợ Consumer-Presented QR.';
												|ru = 'Consumer-Presented QR не поддерживается драйвером.';
												|en = 'The driver does not support Consumer-Presented QR.'; fa = 'The driver does not support Consumer-Presented QR.';
												|it = 'Consumer-Presented QR не поддерживается драйвером.';
												|pl = 'The driver does not support Consumer-Presented QR.';
												|tr = 'Consumer-Presented QR sürücü tarafından desteklenmiyor.'");
		OperationParametersList.Result = False; 
		Return OperationParametersList;
	EndIf;
	
	If Command = "AuthorizeSales" Or Command = "AuthorizeRefund" Or Command = "AuthorizeVoid" 
		Or Command = "PayByPaymentCardWithCashWithdrawal" Or Command = "PurchaseWithEnrollment"       
		Or Command = "PayElectronicCertificate" Or Command = "ReturnElectronicCertificate"
		Or Command = "AuthorizePreSales" Or Command = "AuthorizeCompletion" Or Command = "AuthorizeVoidPreSales"  Then      
		OperationParametersList.Insert("IncomingParametersXML", GetXMLPacketForOperation(OperationParametersList)); 
	EndIf;
	
	Return OperationParametersList;  

EndFunction

// Process the operation data after executing the command.
// 
// Parameters:
//  ConnectionParameters - Structure - See EquipmentManagerClientServer.ConnectionParameters()
//  Command - String - command to execute
//  ExecutionResult - Structure - 
//  OperationData - Structure - 
Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export

EndProcedure

#Region Classifiers

// Payment type code on the terminal.
// 
// Parameters:    
//   PaymentKind_ -  EnumRef.PaymentKindOnTerminal - Type Of Payment At The Terminal
// Returns:
//   Number - Payment Type Code   
//                                
Function PaymentTypeCodeAtTerminal(PaymentKind_) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	Result = LibraryClassifiers.PaymentTypeCodeAtTerminal;
	Return Result.Get(PaymentKind_);
	
EndFunction

// Type of payment at the terminal by code.
// 
// Parameters:    
//   TypeOfPaymentCode - Number - Payment type code.
// Returns:
//   EnumRef.PaymentKindOnTerminal - Type Of Payment At The Terminal
//
Function TypeOfPaymentAtTerminalByCode(TypeOfPaymentCode) Export
	
	LibraryClassifiers = EquipmentManagerClient.LibraryClassifiers();
	Result = LibraryClassifiers.TypeOfPaymentAtTerminalByCode;
	Return Result.Get(TypeOfPaymentCode);
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Get the xmlpackage for the operation.
// 
// Parameters:
//  OperationParametersList - Structure - Parameters
// 
// Returns:
//  String - Get the Xmlpackage for the operation
//
Function GetXMLPacketForOperation(OperationParametersList) Export
	
#If WebClient Then
	Return EquipmentPaymentSystemsServerCall.GetXMLPacketForOperation(OperationParametersList);
#Else
	Return PeripheralsPaymentSystemsServerClientServer.GetXMLPacketForOperation(OperationParametersList);
#EndIf

EndFunction

Function ContextOfOperationOnAcquiringTerminal()
	
	OperationContext = New Structure();
	OperationContext.Insert("NotificationOnCompletion", Undefined);
	OperationContext.Insert("ClientID"   , Undefined);   
	OperationContext.Insert("DeviceID", Undefined);
	OperationContext.Insert("PrintingDevice"   , Undefined);
	OperationContext.Insert("OperationParametersList"      , Undefined);
	OperationContext.Insert("AdditionalParameters", Undefined); 
	OperationContext.Insert("TransactionType"          , Undefined); 
	OperationContext.Insert("PrepareData"        , False); 
	OperationContext.Insert("ProcessData__"         , False);
	OperationContext.Insert("ProcessDataInCaseOfError", False);   
	OperationContext.Insert("PrepareDataClient"  , False);
	OperationContext.Insert("ProcessData__Client"   , False);
	OperationContext.Insert("UsePrintingDevice", False);  
	OperationContext.Insert("Result"     , True);
	Return OperationContext;
	
EndFunction

Procedure PerformingOperationOnAcquiringTerminal(DeviceID, OperationContext)
	
	If DeviceID = Undefined Or IsBlankString(DeviceID) Then       
		
		SupportedTypes = EquipmentManagerClientServer.ParametersTypesOfEquipment();
		SupportedTypes.POSTerminal = True;
		
		Notification = New CallbackDescription("PerformingOperationOnAcquiringTerminalCompletion", ThisObject, OperationContext);
		EquipmentManagerClient.SelectDevice(Notification, SupportedTypes,
			NStr("vi = 'Hãy chọn thiết bị thanh toán thẻ';
				|ru = 'Выберите эквайринговый терминал';
				|en = 'Select a POS terminal'; fa = 'Select a POS terminal';
				|it = 'Scegliere il terminale di acquisizione';
				|pl = 'Wybierz terminal acquiringowy';
				|tr = 'PoS terminali seçin'"), 
			NStr("vi = 'Chưa kết nối thiết bị thanh toán thẻ.';
				|ru = 'Эквайринговый терминал не подключен.';
				|en = 'POS terminal is not connected.'; fa = 'POS terminal is not connected.';
				|it = 'Il terminale di acquisizione non è collegato.';
				|pl = 'Terminal płatniczy nie jest podłączony.';
				|tr = 'PoS terminali bağlı değil.'"),
			NStr("vi = 'Chưa chọn thiết bị thanh toán thẻ.';
				|ru = 'Эквайринговый терминал не выбран.';
				|en = 'POS terminal is not selected.'; fa = 'POS terminal is not selected.';
				|it = 'Il terminale di acquisizione non è scelto.';
				|pl = 'Terminal płatniczy nie jest wybrany.';
				|tr = 'PoS terminali seçili değil.'"));
	Else
		PerformingOperationOnAcquiringTerminalCompletion(OperationContext, OperationContext);
	EndIf
	
EndProcedure

Procedure PerformingOperationOnAcquiringTerminalCompletion(SelectionResult, OperationContext) Export
	
	If SelectionResult.Result Then                                                   
		OperationContext.DeviceID = SelectionResult.DeviceID;
		OperationParametersList = OperationContext.OperationParametersList;
		If OperationContext.TransactionType = "ReturnElectronicCertificate" And IsBlankString(OperationParametersList.ReferenceNumber) Then
			Notification = New CallbackDescription("PerformingOfOperationOnAcquiringTerminalAfterEnteringRRN", ThisObject, OperationContext);
			ToolTip = NStr("vi = 'Hãy nhập RRN của giao dịch từ phiếu cuối mua hàng trên máy POS';
							|ru = 'Введите RRN операции cо слип-чека покупки ЭС';
							|en = 'Enter the operation RRN from the digital sales slip'; fa = 'Enter the operation RRN from the digital sales slip';
							|it = 'Enter the operation RRN from the digital sales slip';
							|pl = 'Enter the operation RRN from the digital sales slip';
							|tr = 'DS satın alma slip fişinden işlemin RRN''sini girin'"); 
			ShowInputString(Notification, "", ToolTip, 12); 
		Else                            
			ExecutionOfOperationOnAcquiringTerminalCommand(OperationContext);
		EndIf;
	Else
		RunCallback(OperationContext.NotificationOnCompletion, SelectionResult);
	EndIf;
	
EndProcedure           

Procedure PerformingOfOperationOnAcquiringTerminalAfterEnteringRRN(RRNString, OperationContext) Export
	
	OperationContext.OperationParametersList.ReferenceNumber = RRNString;
	ExecutionOfOperationOnAcquiringTerminalCommand(OperationContext);
	
EndProcedure

Procedure ExecutionOfOperationOnAcquiringTerminalCommand(OperationContext) Export
	
	If OperationContext.OperationParametersList <> Undefined Then
		If OperationContext.OperationParametersList.Property("QrCardAttributes") Then
			QrCardAttributes = OperationContext.OperationParametersList.QrCardAttributes;
			If Not IsBlankString(QrCardAttributes) Then
				If Not PeripheralsPaymentSystemsServerClientServer.TheseAreQrCardAttributes(QrCardAttributes) Then     
					MessageText = NStr("vi = 'Không thể thực hiện giao dịch với mã QR đã chỉ định.';
										|ru = 'Операция по указанному QR-коду невозможна.';
										|en = 'Cannot carry out a transaction by the specified QR code.'; fa = 'Cannot carry out a transaction by the specified QR code.';
										|it = 'Операция по указанному QR-коду невозможна.';
										|pl = 'Cannot carry out a transaction by the specified QR code.';
										|tr = 'Belirtilen QR kod ile işlem yapılamıyor.'");
					ExecutionResult = EquipmentManagerClientServer.ParametersForPerformingOperationOnHardware(False, MessageText);
					RunCallback(OperationContext.NotificationOnCompletion, ExecutionResult);
					Return;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
		
	ParametersCommandExecution = EquipmentManagerClientServer.ParametersCommandExecution(OperationContext.TransactionType,
		"PeripheralsPaymentSystemsServer", OperationContext.AdditionalParameters, OperationContext.PrepareData, OperationContext.ProcessData__, 
		OperationContext.UsePrintingDevice, OperationContext.ProcessDataInCaseOfError);   
	ParametersCommandExecution.PrepareDataClient = OperationContext.PrepareDataClient;
		
	EquipmentManagerClient.StartCommandExecution(OperationContext.NotificationOnCompletion, OperationContext.ClientID, 
		OperationContext.DeviceID, OperationContext.OperationParametersList, ParametersCommandExecution, OperationContext.PrintingDevice);
	
EndProcedure

#EndRegion  