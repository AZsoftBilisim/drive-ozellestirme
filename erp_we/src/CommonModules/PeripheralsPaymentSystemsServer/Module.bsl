
#Region Internal

// Adds the supplied drivers to the list as part of the configuration.
// 
// Parameters:
//  DriversOfHardware - See EquipmentManager.NewTableOfSuppliedHardwareDrivers
//
Procedure UpdateSuppliedDrivers(DriversOfHardware) Export
	
	
EndProcedure

// Prepare the operation data.
// 
// Parameters:
//  ConnectionParameters - Structure -Connection setting
//  Command - String - Command
//  OperationParametersList - Structure -Operation parameters
// 
// Returns:
//  Undefined
Function PrepareOperationData(ConnectionParameters, Command, OperationParametersList) Export
	
	OperationParametersList.Insert("Result", False); 
	OperationParametersList.Insert("ErrorText");  
	
	Return OperationParametersList;
	
EndFunction

Procedure ProcessOperationData(ConnectionParameters, Command, ExecutionResult, OperationData) Export
	
	If Command = "GetOperationByCards" Then
		If ExecutionResult.Property("ResultOfXMLOperation") Then
			Operations = TransactionsByCards(ExecutionResult.ResultOfXMLOperation);     
			ExecutionResult.Insert("Operations", Operations);
		EndIf;
	Else                        
		
		If ExecutionResult.Property("OutgoingXMLParameters") And Not IsBlankString(ExecutionResult.OutgoingXMLParameters) Then
			OperationParametersList = CommonCEL.ReadRootXMLElement(ExecutionResult.OutgoingXMLParameters);   
			If OperationParametersList.Property("AuthorizationCode") Then
				ExecutionResult.AuthorizationCode = OperationParametersList.AuthorizationCode;
			EndIf;
			If OperationParametersList.Property("CardNumber") Then
				ExecutionResult.CardNumber = OperationParametersList.CardNumber;
			EndIf;                              
			If OperationParametersList.Property("CardNumberHash") Then
				ExecutionResult.HashCardNumber = OperationParametersList.CardNumberHash;
			EndIf;                              
			If OperationParametersList.Property("RRNCode") Then
				ExecutionResult.ReferenceNumber = OperationParametersList.RRNCode;
			EndIf;  
			If OperationParametersList.Property("ReceiptNumber") Then
				ExecutionResult.POSTerminalReceiptNumber = OperationParametersList.ReceiptNumber;
			EndIf;  
			If OperationParametersList.Property("AuthorizationType") Then
				ExecutionResult.TypeOfPaymentAtTerminalCode = OperationParametersList.AuthorizationType;  
			EndIf;  
			If OperationParametersList.Property("OperationStatus") Then
				OperationStatus = OperationParametersList.OperationStatus;
				ExecutionResult.OperationStatus = ?(ValueIsFilled(OperationStatus), Number(OperationStatus), 0);
			EndIf;  
			If OperationParametersList.Property("ResultCode") Then
				EndCode = OperationParametersList.ResultCode;
				ExecutionResult.EndCode = ?(ValueIsFilled(EndCode), Number(EndCode), 0);       
			EndIf;  
			If OperationParametersList.Property("PaymentSystemIdentifier") Then
				ExecutionResult.PaymentSystemId = OperationParametersList.PaymentSystemIdentifier;
			EndIf;  
			If OperationParametersList.Property("UUID") Then
				ExecutionResult.BankTransactionID = OperationParametersList.UUID;
			EndIf;  
			If OperationParametersList.Property("Date") Then
				ExecutionResult.DateTime = OperationParametersList.Date;       
			EndIf;  
			
		EndIf;
		
		If ExecutionResult.Property("SlipReceiptText")
			And Not IsBlankString(ExecutionResult.SlipReceiptText) Then 
			
			If CommonCEL.CheckPrintingDevicesAreUsed() Then
				ModuleEquipmentReceiptPrintingDevices = CommonCEL.CommonModule("PeripheralsReceiptPrinters");
				If OperationData.Property("FullSlipReceipt") And Not OperationData.FullSlipReceipt Then
					SlipReceiptText = PeripheralsPaymentSystemsServerClientServer.TextOfSlipReceiptByDefault(ExecutionResult);         
				Else
					SlipReceiptText = ExecutionResult.SlipReceiptText;
				EndIf;
				TestReceipts = ModuleEquipmentReceiptPrintingDevices.GetXMLPackageForText(SlipReceiptText, ConnectionParameters.InterfaceRevision);
				ExecutionResult.Insert("TestReceipts", TestReceipts);
			EndIf;
			
		EndIf;
		
		If ExecutionResult.Property("TypeOfPaymentAtTerminalCode") Then
			ExecutionResult.PaymentKindOnTerminal = TypeOfPaymentAtTerminalByCode(Number(ExecutionResult.TypeOfPaymentAtTerminalCode));
		EndIf;  
		
	EndIf;         
	
	OperationType = TypeOfPaymentTransactionByCommand(Command);
	RecordPaymentOfOperation(OperationType, OperationData, ExecutionResult);
	
EndProcedure

// Record the payment of operation.
//
Procedure RecordPaymentOfOperation(OperationType, OperationData, ExecutionResult) Export
	
	If OperationType = Undefined Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	QueryID = ?(OperationData.Property("QueryID"), OperationData.QueryID, Undefined);
	If IsBlankString(QueryID) Or QueryID = "0" Then
		QueryID = New UUID();    
		OperationData.QueryID = String(QueryID);;
	EndIf;
	
	DocumentBasis    = ?(OperationData.Property("DocumentBasis"), OperationData.DocumentBasis, Undefined);
	TransactionAmount        = ?(OperationData.Property("TransactionAmount"), OperationData.TransactionAmount, Undefined);
	FiscalTransactionID = ?(OperationData.Property("FiscalTransactionID"), OperationData.FiscalTransactionID, Undefined);
	RecordDate = CommonCEL.SessionDate();
	
	RecordSet = InformationRegisters.PaymentTransactions.CreateRecordSet();
	
	Record = RecordSet.Add();
	Record.QueryID            = String(QueryID);
	Record.DocumentBasis               = DocumentBasis;
	Record.RequestDate_                     = RecordDate;
	Record.YearMonth                        = Year(RecordDate)*100+Month(RecordDate);
	Record.OperationType                     = OperationType;
	Record.FiscalTransactionID = FiscalTransactionID;
	Record.TransactionAmount                   = TransactionAmount;
	Record.ActionCompleted               = ExecutionResult.Result;    
	If IsBlankString(OperationData.CartID) Then  
		If ExecutionResult.Property("OperationID") Then
			Record.OperationID = ExecutionResult.OperationID; 
		EndIf;                 
	Else
		Record.OperationID = OperationData.CartID;
	EndIf;                 
	
	If ExecutionResult.Result Then         
		If ExecutionResult.Property("PaymentKindOnTerminal") Then
			Record.PaymentKindOnTerminal = ExecutionResult.PaymentKindOnTerminal; 
		EndIf;                 
		Record.ReferenceNumber = ?(ExecutionResult.Property("ReferenceNumber"), ExecutionResult.ReferenceNumber, Undefined);
		Record.AuthorizationCode = ?(ExecutionResult.Property("AuthorizationCode"), ExecutionResult.AuthorizationCode, Undefined); 
		Record.TerminalId = ?(ExecutionResult.Property("TerminalId"), ExecutionResult.TerminalId, Undefined);
		Record.AcquirerBankID = ?(ExecutionResult.Property("AcquirerBankID"), ExecutionResult.AcquirerBankID, Undefined);
		Record.PaymentSystemId = ?(ExecutionResult.Property("PaymentSystemId"),ExecutionResult.PaymentSystemId, Undefined);   
		Record.BankTransactionID = ?(ExecutionResult.Property("BankTransactionID"), ExecutionResult.BankTransactionID, Undefined); 
		Record.TransactionDateTime = ?(ExecutionResult.Property("DateTime"), ExecutionResult.DateTime, Undefined);
	EndIf;                 
	
	Deflate = New Deflation(6);    
	
	If OperationData.Property("QueryText") Then
		QueryText = OperationData.QueryText;
	Else
		JSONWriter = New JSONWriter();
		JSONWriter.SetString();
		WriteJSON(JSONWriter, OperationData, , "WriteOfOperation_JSONConversion", PeripheralsPaymentSystemsServer);
		QueryText = JSONWriter.Close();
	EndIf;
	Record.QueryData = New ValueStorage(QueryText, Deflate);
	
	If OperationData.Property("ResponseText") Then   
		ResponseText = OperationData.ResponseText;
	Else
		JSONWriter = New JSONWriter();
		JSONWriter.SetString();
		WriteJSON(JSONWriter, ExecutionResult, , "WriteOfOperation_JSONConversion", PeripheralsPaymentSystemsServer);
		ResponseText = JSONWriter.Close();
	EndIf;
	Record.ResponseData  = New ValueStorage(ResponseText,  Deflate);
	
	RecordSet.Write(False); 
	
EndProcedure

// Retrieves payment Operation data.
//
// Parameters:             
//  QueryID - String - Request ID
//  DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction - The document Foundation
// 
// Returns:
//  Boolean
//
Function PaymentOfOperationsData(QueryID = Undefined, DocumentBasis = Undefined, QueryData = False) Export
	
	SetPrivilegedMode(True);   
	
	PaymentTransactions = New Array();
	
	Query = New Query;
	QueryText = 
		"SELECT ALLOWED
		|	PaymentTransactions.DocumentBasis AS DocumentBasis,
		|	PaymentTransactions.OperationID AS OperationID,
		|	PaymentTransactions.QueryID AS QueryID,
		|	PaymentTransactions.FiscalTransactionID AS FiscalTransactionID,
		|	PaymentTransactions.RequestDate_ AS RequestDate_,
		|	PaymentTransactions.OperationType AS OperationType,
		|	PaymentTransactions.TransactionAmount AS TransactionAmount,
		|	PaymentTransactions.ActionCompleted AS ActionCompleted,    
		|	PaymentTransactions.ReferenceNumber AS ReferenceNumber,  
		|	PaymentTransactions.AuthorizationCode AS AuthorizationCode,    
		|	PaymentTransactions.PaymentKindOnTerminal AS PaymentKindOnTerminal,    
		|	PaymentTransactions.TerminalId AS TerminalId, 
		|	PaymentTransactions.AcquirerBankID AS AcquirerBankID, 
		|	PaymentTransactions.PaymentSystemId AS PaymentSystemId,  
		|	PaymentTransactions.BankTransactionID AS BankTransactionID,     
		|	PaymentTransactions.TransactionDateTime AS TransactionDateTime,
		|	PaymentTransactions.QueryData AS QueryData,
		|	PaymentTransactions.ResponseData AS ResponseData      
		|FROM
		|	InformationRegister.PaymentTransactions AS PaymentTransactions
		|WHERE
		|	&Condition";
	
	If QueryID <> Undefined Then
		ConditionText = "PaymentTransactions.QueryID = &QueryID";
		Query.SetParameter("QueryID", QueryID);  
	ElsIf DocumentBasis <> Undefined Then
		ConditionText = "PaymentTransactions.DocumentBasis = &DocumentBasis";
		Query.SetParameter("DocumentBasis", DocumentBasis);  
	Else
		ConditionText = "";         
	EndIf;
	
	Query.Text = StrReplace(QueryText, "&Condition", ConditionText);
	Selection = Query.Execute().Select();
	While Selection.Next() Do   
		
		PaymentOperation = New Structure();
		PaymentOperation.Insert("DocumentBasis");
		PaymentOperation.Insert("OperationID");
		PaymentOperation.Insert("QueryID");
		PaymentOperation.Insert("FiscalTransactionID");
		PaymentOperation.Insert("RequestDate_");
		PaymentOperation.Insert("OperationType");
		PaymentOperation.Insert("TransactionAmount");
		PaymentOperation.Insert("ActionCompleted");  
		PaymentOperation.Insert("ReferenceNumber");  
		PaymentOperation.Insert("AuthorizationCode");    
		PaymentOperation.Insert("PaymentKindOnTerminal");    
		PaymentOperation.Insert("TerminalId"); 
		PaymentOperation.Insert("AcquirerBankID"); 
		PaymentOperation.Insert("PaymentSystemId");  
		PaymentOperation.Insert("BankTransactionID");     
		PaymentOperation.Insert("TransactionDateTime");
		PaymentOperation.Insert("QueryData");
		PaymentOperation.Insert("ResponseData");
		FillPropertyValues(PaymentOperation, Selection);
		
		If QueryData Then
			RequestDataStorage = Selection.QueryData; // ValueStorage
			If TypeOf(RequestDataStorage) = Type("ValueStorage") Then
				PaymentOperation.Insert("QueryData", RequestDataStorage.Get());
			EndIf;
			ResponseDataStorage = Selection.ResponseData; // ValueStorage
			If TypeOf(ResponseDataStorage) = Type("ValueStorage") Then
				PaymentOperation.Insert("ResponseData", ResponseDataStorage.Get());
			EndIf;
		EndIf;
		
		PaymentTransactions.Add(PaymentOperation);
	EndDo;
	
	Return PaymentTransactions;
	
EndFunction

Function WriteOfOperation_JSONConversion(Property, Value, AdditionalParameters, Cancel) Export  
	
	Return String(Value);   
	
EndFunction

// Checks the possibility of canceling the payment based on the basis document.
//
// Parameters:
//  DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction - The document Foundation
// 
// Returns:
//  Boolean
//
Function CancellationOfPaymentByCheckIsPossible(DocumentBasis) Export
	
	If Not ValueIsFilled(DocumentBasis) Then
		Return False
	EndIf;
	
	SetPrivilegedMode(True);
	Query = New Query;
	
	Query.Text = "SELECT
	|	PaymentTransactions.OperationID AS OperationID
	|FROM
	|	InformationRegister.PaymentTransactions AS PaymentTransactions
	|WHERE
	|	PaymentTransactions.DocumentBasis = &DocumentBasis
	|	AND PaymentTransactions.OperationType = &OperationType
	|	AND PaymentTransactions.ActionCompleted = &ActionCompleted"; 
	
	Query.SetParameter("DocumentBasis", DocumentBasis);
	Query.SetParameter("OperationType", Enums.PaymentTransactionTypes.CancelingPaymentByPaymentCard);
	Query.SetParameter("ActionCompleted", True);
	
	QueryResult = Query.Execute();
	SelectionBasedOnQueryResult = QueryResult.Select();
	If Not SelectionBasedOnQueryResult.Next() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

Function TypeOfPaymentTransactionByCommand(Command)
	
	TransactionTypes = New Map();
	
	TransactionTypes.Insert("AuthorizeSales", Enums.PaymentTransactionTypes.PaymentByPaymentCard);
	TransactionTypes.Insert("AuthorizeRefund", Enums.PaymentTransactionTypes.ReturnByPaymentCard);
	TransactionTypes.Insert("AuthorizeVoid", Enums.PaymentTransactionTypes.CancelingPaymentByPaymentCard);
	TransactionTypes.Insert("PayByPaymentCardWithCashWithdrawal", Enums.PaymentTransactionTypes.PaymentByPaymentCardWithCashIssue);
	TransactionTypes.Insert("PurchaseWithEnrollment", Enums.PaymentTransactionTypes.PurchaseWithEnrollment);
	TransactionTypes.Insert("PayElectronicCertificate", Enums.PaymentTransactionTypes.PaymentWithDigitalCertificate);
	TransactionTypes.Insert("ReturnElectronicCertificate", Enums.PaymentTransactionTypes.DigitalCertificateReturn);
	TransactionTypes.Insert("EmergencyVoid", Enums.PaymentTransactionTypes.AbnormalCancellation);
	
	Return TransactionTypes.Get(Command);
	
EndFunction

// ++ Non-mobile application

// Returns the period for storing payment transactions in the information register
//
// Returns:
//   EnumRef.RetentionPeriodOfTransactionHistory
//
Function RetentionPeriodOfPaymentTransactionHistory() Export
	
	StoragePeriod = Constants.RetentionPeriodOfPaymentTransactions.Get();
	Return StoragePeriod;
	
EndFunction

// Set the value of constants for the retention periods of operations in the information registers
//
Procedure SetRetentionPeriodOfOperations() Export 
	
	If Not ValueIsFilled(Constants.RetentionPeriodOfPaymentTransactions.Get()) Then
		Constants.RetentionPeriodOfPaymentTransactions.Set(Enums.RetentionPeriodOfTransactionHistory.AllTime);
	EndIf;
	
EndProcedure

#Region ScheduledJobs

// It is called from the routine taskdetermined procedure.When
// defining the settings of the scheduled tasks to set the availability of the scheduled task, determines the dependence on the functional options.
// 
// Parameters:
//  Settings - ValueTable
//  FunctionalOption - MetadataObjectFunctionalOption
Procedure OnDefineScheduledJobSettings(Settings, FunctionalOption = Undefined) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearHistoryOfPaymentTransactions;
	Setting.FunctionalOption = FunctionalOption;
	
EndProcedure

#EndRegion

// -- Non-mobile application

// Sets the ID of the fiscal transaction in the log of logging payment transactions by request ID
//
// Parameters:
//   QueryID - String - Unique Request ID
//   FiscalTransactionID - String - Id Of The Fiscal Transaction
Procedure SetIdOfFiscalRecord(QueryID, FiscalTransactionID) Export
	
	InformationRegisters.PaymentTransactions.SetAttributeOfPaymentTransaction(QueryID, 
		"FiscalTransactionID", FiscalTransactionID);
	
EndProcedure

// Will clear the history of payment transactions
//
Procedure ClearHistoryOfPaymentTransactions(ClearDate) Export
	
	If ClearDate = Undefined Then
		Return;
	EndIf;
	
	InformationRegisters.PaymentTransactions.ClearRegisterForPastMonths(ClearDate);
	InformationRegisters.PaymentTransactions.ClearCurMONTHREGISTER (ClearDate);
	
EndProcedure

#EndRegion

#Region Private

// Get card transactions.
//
// Parameters:
//  XMLData1 - String
//
// Returns:
//  Array of See PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquisitionOperationPerformed
// 
Function TransactionsByCards(XMLData1) 
	
	Result = New Array();
	
	If Not IsBlankString(XMLData1) Then
		
		XMLReader = New XMLReader; 
		XMLReader.SetString(XMLData1);
		XMLReader.MoveToContent(); 
		
		If XMLReader.Name = "Table" And XMLReader.NodeType = XMLNodeType.StartElement Then  
			While XMLReader.Read() Do  
				If XMLReader.Name = "Record" And XMLReader.NodeType = XMLNodeType.StartElement Then  
					Operation = PeripheralsPaymentSystemsServerClientServer.ParametersOfAcquisitionOperationPerformed();    
					Operation.TransactionType = XMLReader.AttributeValue("TypeOperation");
					Operation.MerchantSNumber = XMLReader.AttributeValue("MerchantNumber");
					Operation.CardNumber = XMLReader.AttributeValue("CardNumber");
					If XMLReader.AttributeValue("CardNumberHash") <> Undefined Then
						Operation.HashCardNumber = XMLReader.AttributeValue("CardNumberHash");      
					EndIf;                            
					If XMLReader.AttributeValue("Amount") <> Undefined Then
						Operation.TransactionAmount = Number(XMLReader.AttributeValue("Amount"));        
					EndIf; 
					If XMLReader.AttributeValue("AmountCash") <> Undefined Then
						Operation.AmountOfCash = Number(XMLReader.AttributeValue("AmountCash"));
					EndIf; 
					If XMLReader.AttributeValue("ElectronicCertificateAmount") <> Undefined Then
						Operation.AmountOfElectronicCertificate = Number(XMLReader.AttributeValue("ElectronicCertificateAmount"));
					EndIf; 
					If XMLReader.AttributeValue("ReturnElectronicCertificate") <> Undefined Then
						Operation.AmountOfOwnFunds = Number(XMLReader.AttributeValue("ReturnElectronicCertificate"));
					EndIf;
					Operation.ReferenceNumber = XMLReader.AttributeValue("RRNCode");
					Operation.AuthorizationCode= XMLReader.AttributeValue("AuthorizationCode");
					Result.Add(Operation);
				EndIf;
			EndDo;
		EndIf; 
		
	EndIf;
	
	Return Result;
	
EndFunction

// Type of payment at the terminal by code.
// 
// Parameters:    
//   TypeOfPaymentCode - Number - Payment type code.
// Returns:
//   EnumRef.PaymentKindOnTerminal - Type Of Payment At The Terminal
//
Function TypeOfPaymentAtTerminalByCode(TypeOfPaymentCode) Export  
	
	Result = Enums.PaymentKindOnTerminal.TypeOfPaymentAtTerminalByCode();
	Return Result.Get(TypeOfPaymentCode);
	
EndFunction      

// Payment type code on the terminal.
// 
// Parameters:    
//   PaymentKind_ -  EnumRef.PaymentKindOnTerminal - Type Of Payment At The Terminal
// Returns:
//   Number - Payment Type Code   
//
Function PaymentTypeCodeAtTerminal(PaymentKind_) Export
	
	Result = Enums.PaymentKindOnTerminal.PaymentTypeCodeAtTerminal();
	Return Result.Get(PaymentKind_);
	
EndFunction

 #EndRegion