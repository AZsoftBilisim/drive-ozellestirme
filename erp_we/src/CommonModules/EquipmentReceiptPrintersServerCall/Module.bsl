
#Region Public

#Region RegistrationParameters

// The function returns whether the fiscal device supports.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID
// 
// Returns:
//  Boolean - The fiscal device supports checking the marking codes
Function FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID) Export
	
	Return PeripheralsReceiptPrinters.FiscalDeviceSupportsVerificationOfMarkingCodes(DeviceID);
	
EndFunction

// The function returns the FFD version for the fiscal device.
// 
// Parameters:
//  DeviceID - CatalogRef.Peripherals - Device ID.
// 
// Returns:
//  Undefined - The fiscal device supports the FFD version
Function FiscalDeviceSupportsFFDVersion(DeviceID) Export
	
	Return PeripheralsReceiptPrinters.FiscalDeviceSupportsFFDVersion(DeviceID);
	
EndFunction    


#EndRegion

#Region GeneratingCCTData

// Get a table of shift parameters from the KKT.
//
// Parameters:
//  XMLData1 - String - xml string
//  InterfaceRevision - Number - Interface revision
//  CREShiftNumber - Number - shift number
//  KKTReceiptNumber - Number - receipt number
//
// Returns:
//  Structure
//
Function GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision = 0, CREShiftNumber = 0, KKTReceiptNumber = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetShiftParametersFromXMLPackage(XMLData1, InterfaceRevision, CREShiftNumber, KKTReceiptNumber);
	
EndFunction

// Returns the XML text of the info receipt
// Parameters:
//  Data - Structure
//  LineWidth_ - Number
//  Revision - String
//
// Returns:
//  String - xml string
//
Function XMLInfoReceiptPackage(Data,  LineWidth_, Revision) Export
	
	Template = FiscalDocumentTemplates.InfoReceiptTemplate(LineWidth_, Data);
	NonFiscalDocument = FiscalDocumentTemplates.OutputAsText(Template);
	Return PeripheralsReceiptPrinters.GetXMLPackageForText(NonFiscalDocument, Revision);
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

#Region FiscalTransactions

// Outdated: Printing equipment should be used.Record a fiscal operation.
// Record of operation in the Log of fiscal of operations.
//
// Parameters:
//   FiscalizationParameters - Structure - 
Procedure RecordFiscalTransaction(FiscalizationParameters) Export
	
	PeripheralsReceiptPrinters.RecordFiscalTransaction(FiscalizationParameters);
	
EndProcedure

// APK: 142-off backward compatibility

// Outdated: Printing equipment should be used.Fiscal operation data.
// Get Log data of operations.
//
// Parameters:
//  DocumentRef - DocumentRef - The Foundation document.
//  RecordID - InformationRegisterRecord.FiscalTransactions - record of a fiscal transaction.
//  DocumentTypes - EnumRef.TypesOfCREFiscalDocuments - types of documents.
//  CalculationType - EnumRef.CashSettlementTypes - Type of calculation.
//  FiscalFlag - String - The fiscal feature of the document
// 
// Returns:
//  Structure - Structure by properties:
//   * CashRegisterShiftNumber - Number - The check of KKM.
//   * Sum - Number - The amount.
//   * DocumentBasis - DocumentRef - The Foundation document.
//   * XMLData1 - ValueStorage - Check the data transferred to the CCP (XML).
//
Function FiscalOperationData(DocumentRef, RecordID = Undefined, DocumentTypes = Undefined, CalculationType = Undefined, FiscalFlag = Undefined) Export
	
	Return PeripheralsReceiptPrinters.FiscalOperationData(DocumentRef, RecordID, DocumentTypes, CalculationType, FiscalFlag);
	
EndFunction

// APK: 142-on

// Outdated: Printing equipment should be used.Fiscal operationidentifier.
// Get Log data of operations.
//
// Parameters:
//  RecordID - InformationRegisterRecord.FiscalTransactions - The ID of the record.
// 
// Returns:
// InformationRegisterRecord.FiscalTransactions
Function FiscalOperationsByID(RecordID) Export
	
	Return PeripheralsReceiptPrinters.FiscalOperationsByID(RecordID);
	
EndFunction

// Outdated: Printing equipment should be used.List of fiscal operations.
// Get a list of the Log of fiscal of operations.
//
// Parameters:
//  DocumentRef - DocumentRef - The Foundation document.
//  DocumentTypes - EnumRef.TypesOfCREFiscalDocuments - types of fiscal documents.
//  CalculationType - EnumRef.CashSettlementTypes - types of calculation.
// 
// Returns:
//  See PeripheralsReceiptPrinters.ListOfFiscalTransactions
//
Function ListOfFiscalTransactions(DocumentRef, DocumentTypes = Undefined, CalculationType = Undefined) Export
	
	Return PeripheralsReceiptPrinters.ListOfFiscalTransactions(DocumentRef, DocumentTypes, CalculationType);
	
EndFunction

#EndRegion

#Region CREReceiptsOrder 

// Deprecated: Distributed virtualization should be used.addcheckcheckcheckckt.
// Add the receipt to the receipt queue of the KKT.
//
// Parameters:
//  KKTReceiptParameters - Structure - KKT receipt parameters:
//  * ReceiptPositions - Array of See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptSFiscalLine - .
//  BatchOperationParameters - See PeripheralsReceiptPrintersClientServer.BatchOperationParametersInReceiptQueue
// Returns:
//  InformationRegisterRecord
Function AddReceiptToKKTReceiptQueue(KKTReceiptParameters, BatchOperationParameters = Undefined) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.AddReceiptToKKTReceiptQueue(KKTReceiptParameters, BatchOperationParameters);
	EndIf;
	
EndFunction

// Deprecated: Distributed virtualization should be used.Given turn.
// Receipt data from the queue.
//
// Parameters:
//  RecordID - InformationRegisterRecord.FiscalTransactions - The ID of the record.
// 
// Returns:
//  Structure
Function ReceiptDetailsInQueue(RecordID) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.ReceiptDetailsInQueue(RecordID);
	EndIf;
	
EndFunction

// Deprecated: Distributed virtualization should be used.Checkinafiscalization.
// Receipts are in the queue for fiscalization.
//
// Parameters:
//  CashRegister - DefinedType.CashAccountCEL - the cash account for which to carry out fiscalization, if not specified then for all.
//
// Returns:
//  Array
Function ReceiptsInLineForFiscalization(CashRegister = Undefined) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.ReceiptsInLineForFiscalization(CashRegister);
	EndIf;
	
EndFunction

// Deprecated: Distributed virtualization should be used.Delete the queue.
// Delete the receipt from the queue.
//
// Parameters:
//  DocumentRef - DocumentRef - The Foundation document.
// 
Procedure DeleteReceiptFromQueue(DocumentRef) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.DeleteReceiptFromQueue(DocumentRef);
	EndIf;
	
EndProcedure

// Deprecated: Distributed virtualization should be used.Clear the queue of checks.
// Clear the receipt queue.
//
Procedure ClearReceiptQueue() Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.ClearReceiptQueue();
	EndIf;
	
EndProcedure

// Deprecated: Distributed virtualization should be used.Write down the Check Queue status.
// Record the Status of the receipt in the queue.
//
// Parameters:
//  FiscalizationParameters - Structure:
//   * IDOfFiscalRecord - String
//   * DocumentBasis - DocumentRef
//   * ResultOfBatchOperation - Structure
//  ReceiptStatus - EnumRef.CREReceiptStatusInQueue
//  CREEquipment - CatalogRef.Peripherals -
//  ErrorText - String
Procedure RecordReceiptStatusInQueue(FiscalizationParameters, ReceiptStatus, CREEquipment = Undefined, ErrorText = Undefined) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		ModuleDistributedFiscalization.RecordReceiptStatusInQueue(FiscalizationParameters, ReceiptStatus, CREEquipment, ErrorText);
	EndIf;
	
EndProcedure

// Deprecated: Distributed virtualization should be used.Get the status of the check queue.
// Receipt data from the queue.
//
// Parameters:
//  RecordID - InformationRegisterRecord.FiscalTransactions - The ID of the record.
// 
// Returns:
//  Structure
Function GetReceiptStatusInQueue(RecordID) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.GetReceiptStatusInQueue(RecordID);
	EndIf;
	
EndFunction

// Deprecated: Distributed virtualization should be used.Get a fiscal operation.
// Receipt data from the queue by fiscal attribute and Cash register receipt number.
// 
// Parameters:
//  FiscalFlag - String - Fiscal feature
//  CashRegisterReceiptNumber - String - KKM receipt number
// 
// Returns:
//  Undefined, Structure - Get A Fiscal Transaction:
//  * DocumentBasis - DefinedType.BaseDocumentForFiscalPLTransaction
//  * RecordID - UUID
//  * FiscalFlag - String - 
//  * CashRegisterShiftNumber - Number
//  * CashRegisterReceiptNumber - Number 
Function GetFiscalTransaction(FiscalFlag, CashRegisterReceiptNumber = Undefined) Export
	
	If CommonCEL.DistributedFiscalizationIsUsed() Then
		ModuleDistributedFiscalization = CommonCEL.CommonModule("Distributed_Fiscalization");
		Return ModuleDistributedFiscalization.GetFiscalTransaction(FiscalFlag, CashRegisterReceiptNumber);
	EndIf;
	
EndFunction

#EndRegion

// Outdated: You should use the Formatnological control.Performed a check of the obligation and the correctness of the filling of tags.
// Performs a must-fill check for tags.
//
// Parameters:
//  Parameters - Structure 
//  DeviceID - CatalogRef.Peripherals
//  ErrorDescription - String
// 
// Returns:
//  Boolean
Function MandatoryAndCorrectFillingOfTagsWasChecked(Parameters, DeviceID, ErrorDescription) Export
	
	If CommonCEL.FormatLogicalControlIsUsed() Then
		FormatAndLogicControlModule = CommonCEL.CommonModule("FormatLogicalControl");
		Return FormatAndLogicControlModule.MandatoryAndCorrectFillingOfTagsWasChecked(Parameters, DeviceID, ErrorDescription);
	Else
		Return True;
	EndIf;
	
EndFunction

// Outdated: You should use the Formatnological control.The required format is provided.
// The procedure leads to a format agreed with the Federal Tax Service.
//
// Parameters:
//  MainParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  Cancel - Boolean
//  ErrorDescription - String
//  FixedBasicParameters - Boolean
Procedure BringDataToRequiredFormat(MainParameters, Cancel, ErrorDescription, FixedBasicParameters) Export
	
	If CommonCEL.FormatLogicalControlIsUsed() Then
		FormatAndLogicControlModule = CommonCEL.CommonModule("FormatLogicalControl");
		FormatAndLogicControlModule.BringDataToRequiredFormat(MainParameters, FixedBasicParameters);
	EndIf;
	
EndProcedure

// Outdated: Printing equipment should be used.Template check.
// The function generates a receipt template.
//
// Parameters:
//  CommonParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  EquipmentType - String - types of equipment by line.
//  AdditionalText - String - additional text of the receipt template.
//  DeviceID - CatalogRef.Peripherals
//
// Returns:
//  Structure
Function ReceiptTemplate(CommonParameters, EquipmentType, AdditionalText = Undefined, DeviceID = Undefined) Export
	
	Return PeripheralsReceiptPrinters.ReceiptTemplate(CommonParameters, EquipmentType, AdditionalText, DeviceID);
	
EndFunction

// Outdated: Printing equipment should be used.Generate a fiscal document.
// The function generates a tabular document based on the fiscal receipt data.
//
// Parameters:
//  DocumentType - Number
//   CommonParameters - Structure - fiscal document parameters loaded from XML data
//                    See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   ReceiptDetails_ - Structure - parameters of a fiscal document from the information register fiscal documents
//                    See FiscalOperationData()
//   FFDFormat - String - the format of fiscal data affects the output of the payment table at "1.0" 
//                        only the types of payments "CASH", "ELECTRONIC" are used
//
// Returns:
//  SpreadsheetDocument - a tabular document with a generated fiscal document can be saved in any format.
//
Function GenerateFiscalDocument(DocumentType, CommonParameters, ReceiptDetails_, FFDFormat = "1.1") Export
	
	Return PeripheralsReceiptPrinters.GenerateFiscalDocument(DocumentType, CommonParameters, ReceiptDetails_, FFDFormat);
	
EndFunction

// Outdated: Printing equipment should be used.Generate a fiscal document.
// The function generates a tabular document based on the fiscal receipt data.
//
// Parameters:
//  DocumentType - Number
//   CommonParameters - Structure - fiscal document parameters loaded from XML data
//                    See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//   ReceiptDetails_ - Structure - parameters of the fiscal document from the register of information fiscal documents
//                    See FiscalOperationData().
//   FFDFormat - String - the format of fiscal data affects the output of the payment table with "1.0" 
//                        only the types of payments "CASH", "ELECTRONIC" are used.
//
// Returns:
//  String - Text.
//
Function GenerateFiscalDocumentText(DocumentType, CommonParameters, ReceiptDetails_ = Undefined, FFDFormat = "1.1", ReceiptWidth = 36) Export
	
	Return PeripheralsReceiptPrinters.GenerateFiscalDocumentText(DocumentType, CommonParameters, ReceiptDetails_, FFDFormat, ReceiptWidth);
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function BeforeOpeningCashShift(ConnectionParameters, OperationData) Export
	
	Return PeripheralsReceiptPrinters.BeforeOpeningCashShift(ConnectionParameters, OperationData);
	
EndFunction

Function BeforeClosingCashShift(ConnectionParameters, OperationData) Export
	
	Return PeripheralsReceiptPrinters.BeforeClosingCashShift(ConnectionParameters, OperationData);
	
EndFunction

Function AfterOpeningCashShift(ConnectionParameters, ExecutionResult) Export
	
	Return PeripheralsReceiptPrinters.AfterOpeningCashShift(ConnectionParameters, ExecutionResult);
	
EndFunction

Function AfterCashShiftCloses(ConnectionParameters, ExecutionResult) Export
	
	Return PeripheralsReceiptPrinters.AfterCashShiftCloses(ConnectionParameters, ExecutionResult);
	
EndFunction


#Region GeneratingCCTData

// Get the xmlpackage for the operation.
// 
// Parameters:
//  CommonParameters - Structure, Boolean - General settings
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  String - Get the Xmlpackage for the operation
Function GetXMLPacketForOperation(CommonParameters, InterfaceRevision = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetXMLPacketForOperation(CommonParameters, InterfaceRevision);
	
EndFunction

// Get an xmlpackage for text.
// 
// Parameters:
//  TextString - String, Structure - Line of text
//  InterfaceRevision - Number - Interface revision
// 
// Returns:
//  Array of XMLWriter - Get an xmlpackage for text.  
//
Function GetXMLPackageForText(TextString, InterfaceRevision = 0) Export
	
	Return PeripheralsReceiptPrintersClientServer.
		GetXMLPackageForText(TextString, InterfaceRevision);
	
EndFunction  

Procedure FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_ = 32) Export
	
	PeripheralsReceiptPrintersClientServer.
		FillInXMLPackagesForTextDocument(TestReceipts, NonFiscalDocuments, ConnectionParameters, LineWidth_);

EndProcedure

// Get state parameters from an XML package.
//
// Parameters:
//  DATAXML string, XML text
// 
// Returns:
//  Structure
//
Function GetStateParametersFromXMLPackage(Data, ShiftNumber = Undefined) Export
	
	Return PeripheralsReceiptPrintersClientServer.GetStateParametersFromXMLPackage(Data, ShiftNumber);
	
EndFunction         



#EndRegion

///////////////////////////////////////////////////////////////////////////////
// Marking Codes

// Outdated: You should use Management equipmentmark.The code of the planned statusmarkable preparation.
// Get the code of the planned Status of the marked product
// 
// Parameters:
//  PlannedStatusOfTheMarkedProduct - EnumRef - The planned status of the marked product.  
// 
// Returns:
//  Number - The code of the planned status of the marked goods according to the OFD
//
Function CodePlannedStatusOfMarkedProduct(PlannedStatusOfTheMarkedProduct) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.CodePlannedStatusOfMarkedProduct(PlannedStatusOfTheMarkedProduct);
	EndIf;
	
EndFunction

// Outdated: You should use Management equipmentmark.The answering codeoismostatusetovar.
// Get an OISM response code about the Status of the product
// 
// Parameters:
//  TheAnswerAboutTheProductStatus - EnumRef - Response from ISMO.  
// 
// Returns:
//  Number - The response of the OISM about the status of the goods according to the OFD
//
Function ProductStatusResponseCode(TheAnswerAboutTheProductStatus) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.ProductStatusResponseCode(TheAnswerAboutTheProductStatus);
	EndIf;
	
EndFunction

// Outdated: You should use Management equipmentmark.The answer is an ismostatusetovarapocode.
// Get a response from the OISM about the Status of the product by code.
// 
// Parameters:
//  TheAnswerAboutTheProductStatus - Number - Response from ISMO.  
// 
// Returns:
//  EnumRef - SEE OI's answer.
//
Function ResponseAboutProductStatusByCode(TheAnswerAboutTheProductStatus) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.ResponseAboutProductStatusByCode(TheAnswerAboutTheProductStatus);
	EndIf;
	
EndFunction

// Outdated: You should use Management equipmentmark.The code type of labeling of the CCT.
// Get the type code of the CCT marking by code.
// 
// Parameters:
//  CCTMarkingType - EnumRef.CREMarkingTypes - The type of marking of the CCT.
// 
// Returns:
//  String, Arbitrary - KKT marking type code
Function CktMarkingTypeCode(CCTMarkingType) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.CktMarkingTypeCode(CCTMarkingType);
	EndIf;
	
EndFunction

// Outdated: You should use Management equipmentmark.Type of markingctpocode.
// Get the KKT marking type code.
// 
// Parameters:
//  CodeMarkingTypeCKT - Number - Code type of marking KKT
// 
// Returns:
//  Arbitrary, EnumRef.CREMarkingTypes - Type marking code Ktpo
Function KktMarkingTypeByCode(CodeMarkingTypeCKT) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.KktMarkingTypeByCode(CodeMarkingTypeCKT);
	EndIf;
	
EndFunction

// Outdated: You should use Management equipmentmark.statusresultatasaprosacmpocode.
// Get the Status of the KM request result by code.
// 
// Parameters:
//  StatusCode_ - Number - Status code.
// 
// Returns:
//  Arbitrary, EnumRef - Status of the result of the CMPo code request  
Function StatusOfKMRequestResultByCode(StatusCode_) Export
	
	If CommonCEL.MarkingIsUsed() Then
		ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
		Return ModuleEquipmentManagerMarking.StatusOfKMRequestResultByCode(StatusCode_);
	EndIf;
	
EndFunction

#EndRegion