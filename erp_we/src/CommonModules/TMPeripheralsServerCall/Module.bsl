
#Region Public

// Get the equipment connected to the terminal.
//
// Parameters:
//  POSTerminal - CatalogRef.POSTerminals - An acquiring terminal.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Terminal.
//   * CREWITHDATATRANSFER - Undefined, CatalogRef.Peripherals - KKT.
//
Function EquipmentConnectedToTerminal(POSTerminal) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref
	|INTO SettingUpTheRMK
	|FROM
	|	Catalog.CWPSettings AS T
	|WHERE
	|	T.Workplace = &Workplace
	|
	|;
	|SELECT TOP 1
	|	POSTerminals.Peripherals               AS Terminal,
	|	POSTerminals.UseWithoutConnectingPeripherals AS UseWithoutConnectingPeripherals,
	|	POSTerminals.CREPeripherals            AS CREWithDataTransfer
	|FROM
	|	Catalog.CWPSettings.POSTerminals AS POSTerminals
	|		INNER JOIN SettingUpTheRMK AS SettingUpTheRMK
	|		ON SettingUpTheRMK.Ref = POSTerminals.Ref
	|WHERE
	|	POSTerminals.POSTerminal = &POSTerminal");
	
	Query.SetParameter("Workplace",          EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("POSTerminal", POSTerminal);
	
	ReturnValue = StructureConnectedEquipment();
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		
		FillPropertyValues(ReturnValue, Selection);
		If Selection.UseWithoutConnectingPeripherals Then
			ReturnValue.Terminal = Undefined;
		EndIf;
		
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Get equipment connected to the checkout.
//
// Parameters:
//  CashAccount - CatalogRef.CashAccounts - Cash.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * CREWITHDATATRANSFER - Undefined, CatalogRef.Peripherals - KKT.
//
Function EquipmentConnectedToCheckout(CashAccount) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref
	|INTO SettingUpTheRMK
	|FROM
	|	Catalog.CWPSettings AS T
	|WHERE
	|	T.Workplace = &Workplace
	|
	|;
	|SELECT TOP 1
	|	CashAccounts.Peripherals AS CREWithDataTransfer
	|FROM
	|	Catalog.CWPSettings.CashAccounts AS CashAccounts
	|		INNER JOIN SettingUpTheRMK AS SettingUpTheRMK
	|		ON SettingUpTheRMK.Ref = CashAccounts.Ref
	|WHERE
	|	CashAccounts.CashAccount = &CashAccount");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("CashAccount",        CashAccount);
	
	ReturnValue = StructureConnectedEquipment();
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ReturnValue, Selection);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Get the cash register associated with the equipment.
//
// Parameters:
//  CREEquipment - CatalogRef.Peripherals -
// 
// Returns:
//  CatalogRef.CashAccounts, Undefined - 
//
Function CashRegisterRelatedToEquipment(CREEquipment) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref
	|INTO SettingUpTheRMK
	|FROM
	|	Catalog.CWPSettings AS T
	|WHERE
	|	T.Workplace = &Workplace
	|
	|;
	|SELECT TOP 1
	|   CashAccounts.CashAccount AS CashAccount
	|FROM
	|	Catalog.CWPSettings.CashAccounts AS CashAccounts
	|		INNER JOIN SettingUpTheRMK AS SettingUpTheRMK
	|		ON SettingUpTheRMK.Ref = CashAccounts.Ref
	|WHERE
	|	CashAccounts.Peripherals = &CREEquipment");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("CREEquipment", CREEquipment);
	
	ReturnValue = Undefined;
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ReturnValue = Selection.CashAccount;
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Get equipment connected to the KKM checkout.
//
// Parameters:
//  CashRegister - CatalogRef.CashRegisters - Cash registers.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * CREWITHDATATRANSFER - Array of CatalogRef.Peripherals - CREWithDataTransfer
//
Function EquipmentConnectedToCashRegister(CashRegister) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref
	|INTO SettingUpTheRMK
	|FROM
	|	Catalog.CWPSettings AS T
	|WHERE
	|	T.Workplace = &Workplace
	|
	|;
	|SELECT TOP 1
	|	CashRegisters.Peripherals AS CREWithDataTransfer
	|FROM
	|	Catalog.CWPSettings.CashRegisters AS CashRegisters
	|		INNER JOIN SettingUpTheRMK AS SettingUpTheRMK
	|		ON SettingUpTheRMK.Ref = CashRegisters.Ref
	|WHERE
	|	NOT CashRegisters.UseWithoutConnectingPeripherals
	|	AND CashRegisters.CashRegister = &CashRegister");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("CashRegister",     CashRegister);
	
	ReturnValue = StructureConnectedEquipment();
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(ReturnValue, Selection);
	EndIf;
	
	Return ReturnValue;
	
EndFunction

// Get the hardware connected by organization.
//
// Parameters:
//  Organization - DefinedType.CompanyCEL - Organization.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * CREWITHDATATRANSFER - Array of CatalogRef.Peripherals - CREWithDataTransfer
//
Function EquipmentConnectedByOrganization(Organization) Export
	
	Query = New Query;
	QueryText =
	"SELECT
	|	EquipmentList.Ref AS CREWithDataTransfer
	|INTO UsedPeripherals
	|FROM
	|	Catalog.Peripherals AS EquipmentList
  	|		INNER JOIN Catalog.CWPSettings.CashRegisters AS CashRegisterCWPSettings
  	|		ON (CashRegisterCWPSettings.Ref.Workplace = &Workplace)
  	|			AND (CashRegisterCWPSettings.Peripherals = EquipmentList.Ref)
	|WHERE
	|	EquipmentList.Organization = &Organization
	|	AND NOT EquipmentList.DeletionMark
	|	AND EquipmentList.DeviceIsInUse
	|	AND EquipmentList.Workplace = &Workplace
	|
	|UNION ALL
	|
	|SELECT
	|	EquipmentList.Ref AS CREWithDataTransfer	
	|FROM
	|	Catalog.Peripherals AS EquipmentList
  	|		INNER JOIN Catalog.CWPSettings.CashAccounts AS CashRegisterCWPSettings
  	|		ON (CashRegisterCWPSettings.Ref.Workplace = &Workplace)
  	|			AND (CashRegisterCWPSettings.Peripherals = EquipmentList.Ref)
	|WHERE
	|	EquipmentList.Organization = &Organization
	|	AND NOT EquipmentList.DeletionMark
	|	AND EquipmentList.DeviceIsInUse
	|	AND EquipmentList.Workplace = &Workplace
	|
	|";
	
	QueriesTexts = New Array;
	QueriesTexts.Add(QueryText);
	
	QueryTextFinalSelection = "
	|SELECT DISTINCT
	|	UsedPeripherals.CREWithDataTransfer AS CREWithDataTransfer
	|FROM
	|	UsedPeripherals AS UsedPeripherals
	|";
	QueriesTexts.Add(QueryTextFinalSelection);
	
	Query.Text = StrConcat(QueriesTexts, ";");
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("Organization",  Organization);
	
	ListOfCCTS = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ListOfCCTS.Add(Selection.CREWithDataTransfer);
	EndDo;
	
	ReturnValue = StructureConnectedEquipment();
	ReturnValue.CREWITHDATATRANSFER = ListOfCCTS;
	
	Return ReturnValue;
	
EndFunction

// Get the equipment connected to the organization's cash registers for the current workplace.
//
// Parameters:
//  Organization - CatalogRef.Companies - Organization.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined
//   * CREWITHDATATRANSFER - Undefined, CatalogRef.Peripherals - KKT.
//
Function EquipmentConnectedToCheckoutByOrganization(Organization) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref AS Ref
	|INTO SettingUpTheRMK
	|FROM
	|	Catalog.CWPSettings AS T
	|WHERE
	|	T.Workplace = &Workplace
	|
	|;
	|SELECT
	|	CashAccounts.Peripherals AS CREWithDataTransfer,
	|   CashAccounts.CashAccount AS CashAccount
	|FROM
	|	Catalog.CWPSettings.CashAccounts AS CashAccounts
	|		INNER JOIN SettingUpTheRMK AS SettingUpTheRMK
	|		ON SettingUpTheRMK.Ref = CashAccounts.Ref
	|WHERE
	|	CashAccounts.Peripherals.Organization = &Organization
	|	AND NOT CashAccounts.Peripherals.DeletionMark
	|	AND CashAccounts.Peripherals.DeviceIsInUse
	|");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.GetClientSWorkplace());
	Query.SetParameter("Organization",  Organization);
	
	ReturnValue = StructureConnectedEquipment();
	ReturnValue.CREWITHDATATRANSFER = New Array;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ReturnValue.CREWITHDATATRANSFER.Add(Selection.CREWithDataTransfer);
	EndDo;
	
	Return ReturnValue;
	
EndFunction

// Get equipment connected to the organization and interacting online with 1C.
//
// Parameters:
//  Organization - DefinedType.CompanyCEL - Organization.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * CREWITHDATATRANSFER - Array of CatalogRef.Peripherals - CREWithDataTransfer
//
Function EquipmentConnectedByOrganizationInteractingOnlineWith1C(Organization) Export
	
	EquipmentConnectedByOrganization = EquipmentConnectedByOrganization(Organization);
	
	EquipmentInteractingOnlineS1s = New Array();
	FillInArrayOfConnectedEquipmentByOrganization(EquipmentInteractingOnlineS1s, EquipmentConnectedByOrganization);
	
	EquipmentConnectedByOrganization.CREWITHDATATRANSFER = EquipmentInteractingOnlineS1s;
	
	Return EquipmentConnectedByOrganization;
	
EndFunction

// Get equipment connected to a trading account and interacting online with 1C.
//
// Parameters:
//  RetailFacility - CatalogRef.CashRegisters, CatalogRef.CashAccounts - A commercial object for identifying
//  	specific connected equipment.
// 
// Returns:
//  Structure - Structure by properties:
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * CREWITHDATATRANSFER - Array of CatalogRef.Peripherals - CREWithDataTransfer
//
Function EquipmentConnectedOnTradeObjectInteractingOnlineWith1C(RetailFacility) Export
	
	EquipmentForCommercialObject = Undefined;
	If TypeOf(RetailFacility) = Type("CatalogRef.CashRegisters") Then
		EquipmentForCommercialObject = EquipmentConnectedToCashRegister(RetailFacility);
	Else // Shopping Center Type(Commercial object) = Type("Reference link.Ticket offices") Then
		EquipmentForCommercialObject = EquipmentConnectedToCheckout(RetailFacility);
	EndIf;
	
	EquipmentInteractingOnlineS1s = New Array();
	
	FillInArrayOfConnectedEquipmentForRetailItem(EquipmentInteractingOnlineS1s, EquipmentForCommercialObject);
	
	EquipmentConnectedByOrganization = StructureConnectedEquipment();
	EquipmentConnectedByOrganization.CREWITHDATATRANSFER = EquipmentInteractingOnlineS1s;
	
	Return EquipmentConnectedByOrganization;
	
EndFunction

Function DataOfFiscalOfOperationTakingIntoAccountCashREGISTERCorrectionReceipt(DocumentBasis) Export
	
	FiscalOperationData = Undefined;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	ReceiptOfCashRegisterAdjustment.Ref AS Ref
	|FROM
	|	Document.ReceiptOfCashRegisterAdjustment AS ReceiptOfCashRegisterAdjustment
	|WHERE
	|	ReceiptOfCashRegisterAdjustment.CashRegisterReceipt = &CashRegisterReceipt
	|	AND ReceiptOfCashRegisterAdjustment.Posted = TRUE
	|	AND ReceiptOfCashRegisterAdjustment.Status = &Status
	|	AND ReceiptOfCashRegisterAdjustment.TypeOfCorrection = &TypeOfCorrection";
	Query.SetParameter("CashRegisterReceipt", DocumentBasis);
	Query.SetParameter("Status", Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	Query.SetParameter("TypeOfCorrection", Enums.KindsOfAdjustmentReceipts.CRENonApplication);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FiscalOperationData = PeripheralsReceiptPrinters.FiscalOperationData(Selection.Ref);
	EndIf;
	
	Return FiscalOperationData;
	
EndFunction

Function FiscalTransactionDataWithImplementationAdjustment(DocumentBasis) Export
	
	FiscalOperationData = Undefined;
	
	Query = New Query;
	Query.Text =
	"SELECT TOP 1
	|	SaleAdjustment.Ref AS Ref
	|FROM
	|	Document.SaleAdjustment AS SaleAdjustment
	|		INNER JOIN InformationRegister.FiscalTransactions AS FiscalTransactions
	|		ON SaleAdjustment.Ref = FiscalTransactions.DocumentBasis
	|WHERE
	|	SaleAdjustment.DocumentBasis = &DocumentBasis
	|
	|ORDER BY
	|	SaleAdjustment.Date DESC";
	Query.SetParameter("DocumentBasis", DocumentBasis);
	
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FiscalOperationData = PeripheralsReceiptPrinters.FiscalOperationData(Selection.Ref);
	EndIf;
	
	Return FiscalOperationData;
	
EndFunction

// Write the operation to the Fiscal operations data register. Left for compatibility with the Operationpoyandexcasse.Reflect documentfiscal operation log()
// is called ONLY from there
// previously an entry was made in the register of information
// for fiscal operation Logsn't created in this method now : 
//		Retail displays.Create a documentnotesreferencesexternal links(Vneshenergoservis);
//      Retail displays.Create documentsreferencesexternal links(Dredging of monetary funds from kassykkm).
//
// Parameters:
//  RetryRecordingIsRequired - Boolean - Required to re-attempt recording.
//  DetailsOfCashNodeSFiscalOperation - Structure - Details Of The Cash Node's Fiscal Operation:
//    	* Date - Date - Date of receipt formation
//    	* DocumentBasis - DocumentRef - 
//    	* Organization - CatalogRef - Organization that belongs to Yandex. Checkout
//    	* RetailFacility - CatalogRef - 
//    	* Device - CatalogRef - KKM cash register or fiscal device
//    	* OperationType - EnumRef - Type of operation of the cash register node
//    	* CalculationType - EnumRef - type of cash settlement
//    	* CashRegisterReceiptNumber - String - Fiscal document number
//    	* ShiftNumber - String - Cash shift number
//    	* OptionOfSendingElectronicReceipt - EnumRef - Options for sending an electronic receipt to the buyer
//    	* ContactDetailsOfElectronicReceipt - String - Contact details of the electronic receipt
//    	* Sum - Number - Check amount
//    	* PaymentAmountInCash - Number - Check amount
//    	* PaymentAmountPaymentCard - Number - Check amount
//    	* LoanAmount_ - Number - Check amount
//    	* PrepaymentAmountMan - Number - Check amount
//    	* NettingAmount - Number - Check amount
//    	* Data - Structure -
//    			- Array - Fiscal transaction data
//    	* AdditionalParameters - Structure - Describes additional parameters.
//  
// Returns:
//  Boolean - The result of recording the fiscal operation.
Function WriteInJournalOfFiscalOperations(RetryRecordingIsRequired, Val DetailsOfCashNodeSFiscalOperation) Export
	
	FiscalizationParameters = PeripheralsReceiptPrinters.ReceiptFiscalizationParameters();
	
	FiscalizationParameters.DocumentBasis = DetailsOfCashNodeSFiscalOperation.DocumentBasis;
	FiscalizationParameters.Organization = DetailsOfCashNodeSFiscalOperation.Organization;
	FiscalizationParameters.RetailFacility = DetailsOfCashNodeSFiscalOperation.RetailFacility;
	FiscalizationParameters.CalculationType = DetailsOfCashNodeSFiscalOperation.CalculationType;
	FiscalizationParameters.KKTReceiptNumber = DetailsOfCashNodeSFiscalOperation.CashRegisterReceiptNumber; //in BPO Nomerchekakkt, in YAK Nomerchekakkm
	FiscalizationParameters.ReceiptDateAndTime = DetailsOfCashNodeSFiscalOperation.Date;
	
	If DetailsOfCashNodeSFiscalOperation.OperationType = Enums.TypesOfCashOperatingUnitOperation.FiscalTransaction Then
		FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.SALESSLIP;
	ElsIf DetailsOfCashNodeSFiscalOperation.OperationType = Enums.TypesOfCashOperatingUnitOperation.DepositCash Then	
		FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.CashDeposit;
	ElsIf DetailsOfCashNodeSFiscalOperation.OperationType = Enums.TypesOfCashOperatingUnitOperation.CashWithdrawal Then	
		FiscalizationParameters.DocumentType = Enums.TypesOfCREFiscalDocuments.Withdrawal;
	EndIf;	
	
	FiscalizationParameters.ReceiptAmount = DetailsOfCashNodeSFiscalOperation.Sum;
	FiscalizationParameters.ElectronicalyPayment = DetailsOfCashNodeSFiscalOperation.PaymentAmountPaymentCard;
	
	Result = RecordFiscalTransactionInTransaction(RetryRecordingIsRequired, FiscalizationParameters);
	
	Return Result;
	
EndFunction

// Write the operation to the fiscal operations information register in the transaction. 
// This method is added for calling from the client context (in particular, pluggable Equipmentoutclient) with the possibility of trying to write again
// In the future, it is planned to transfer this method to the BPO server management system.
//
// Parameters:
//  RetryRecordingIsRequired - Boolean - Required to re-attempt recording.
//  FiscalizationParameters - Structure - For a description of the parameters fiscalization of the receipt, see the function of the Client Server management equipment.Parametersfiscalization of the check().
// 
// Returns:
// 	Boolean - The result of recording a fiscal transaction.
Function RecordFiscalTransactionInTransaction(RetryRecordingIsRequired, Val FiscalizationParameters) Export
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		If FiscalizationParameters <> Undefined Then
			
			NeedToRecordFiscalOperation = Not FiscalizationParameters.OperationRecorded;
			ItIsNecessaryToRecordFiscalOperationStorno = Not ( IsBlankString(FiscalizationParameters.ReverseCorrectionCheck)
					 									 Or FiscalizationParameters.ReverseCorrectionCheck.OperationRecorded );
														 
			If NeedToRecordFiscalOperation Or ItIsNecessaryToRecordFiscalOperationStorno Then
															 
				Block = New DataLock;
				
				If NeedToRecordFiscalOperation And ValueIsFilled(FiscalizationParameters.DocumentBasis) Then
					LockItem = Block.Add();
					LockItem.Region = "InformationRegister.FiscalTransactions";
					LockItem.Mode = DataLockMode.Shared;
					LockItem.SetValue("DocumentBasis", FiscalizationParameters.DocumentBasis);
				EndIf;	
				
				If ItIsNecessaryToRecordFiscalOperationStorno And ValueIsFilled(FiscalizationParameters.ReverseCorrectionCheck.DocumentBasis) Then
					LockItem = Block.Add();
					LockItem.Region = "InformationRegister.FiscalTransactions";
					LockItem.Mode = DataLockMode.Shared;
					LockItem.SetValue("DocumentBasis", FiscalizationParameters.ReverseCorrectionCheck.DocumentBasis);
				EndIf;
				
				If Block.Count() Then
					Block.Lock();
				EndIf;	

				If NeedToRecordFiscalOperation Then
					EquipmentReceiptPrintersServerCall.RecordFiscalTransaction(FiscalizationParameters);
				EndIf;
				If ItIsNecessaryToRecordFiscalOperationStorno Then
					EquipmentReceiptPrintersServerCall.RecordFiscalTransaction(FiscalizationParameters.ReverseCorrectionCheck);
				EndIf;
				
			EndIf;
		EndIf;
		
		Result = True;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		RetryRecordingIsRequired = True;
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Generates a list of fiscal operations for the document and puts them in the queue
//
// Parameters:
//  DocumentRef - DocumentRef - link to the document to create a receipt queue for
//
Procedure CreateReceiptQueue(DocumentRef) Export
	
	
EndProcedure

#EndRegion

#Region Private

// Official structure "of the connected equipment"
// 
// Returns:
//  Structure - With Fields:
//   * CREWITHDATATRANSFER - Array of CatalogRef.Peripherals - CREWithDataTransfer
//   * Terminal - Undefined, CatalogRef.Peripherals - Data to the connected terminal
//   * UseWithoutConnectingPeripherals - Boolean, Undefined - 
//
Function StructureConnectedEquipment()
	
	Result = New Structure;
	Result.Insert("Terminal");
	Result.Insert("CREWITHDATATRANSFER");
	Result.Insert("UseWithoutConnectingPeripherals");
	Return Result;
	
EndFunction

Procedure FillInArrayOfConnectedEquipmentByOrganization(EquipmentInteractingOnlineS1s, EquipmentConnectedByOrganization)
	
	For Each FiscalEquipment In EquipmentConnectedByOrganization.CREWITHDATATRANSFER Do
		AddFiscalEquipmentInteractingOnlineWith1CToArray(EquipmentInteractingOnlineS1s, FiscalEquipment);
	EndDo;
	
EndProcedure

Procedure FillInArrayOfConnectedEquipmentForRetailItem(EquipmentInteractingOnlineS1s, EquipmentForCommercialObject)
	
	If TypeOf(EquipmentForCommercialObject) = Type("Structure")
		And EquipmentForCommercialObject.Property("CREWITHDATATRANSFER")
		And EquipmentForCommercialObject.CREWITHDATATRANSFER <> Undefined Then
		
		AddFiscalEquipmentInteractingOnlineWith1CToArray(EquipmentInteractingOnlineS1s, EquipmentForCommercialObject.CREWITHDATATRANSFER);
	EndIf;
	
EndProcedure

Procedure AddFiscalEquipmentInteractingOnlineWith1CToArray(EquipmentInteractingOnlineS1s, FiscalEquipment)
	
	AttributeNameEquipmentType = "EquipmentType";
	
	
	EquipmentType = Common.ObjectAttributeValue(FiscalEquipment, AttributeNameEquipmentType);
		
	If EquipmentType = Enums.PeripheralTypes.ReceiptPrinter
		Or EquipmentType = Enums.PeripheralTypes.FiscalCashRegisters
		Or EquipmentType = Enums.PeripheralTypes.CREWithDataTransfer Then
		
		EquipmentInteractingOnlineS1s.Add(FiscalEquipment);
	EndIf;
	
EndProcedure

#EndRegion
