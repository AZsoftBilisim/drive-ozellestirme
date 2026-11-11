#Region Public

// Returns the supported maximum version of the FFD
// 
// Returns:
// 	String - Description - FFD Version
Function MaximumFFDVersion() Export
	
	Return GeneratingFiscalChecksServer.MaximumFFDVersion();
	
EndFunction

// Initializes fiscal receipt parameters
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that you want to print the check 
// 	Organization - CatalogRef.Companies - The organization for the document
// Returns:
// 	Structure - Description: Fiscal Receipt Parameters
//
Function ParametersOfReceiptFiscalizationOperation(DocumentRef, Organization) Export
	
	Return GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation(DocumentRef, Organization);
	
EndFunction

// Returns operation parameters for fiscalizing a receipt for a document
// 
// Parameters:
// 	DocumentRef - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperationBatchMode.DocumentRef
// 	CREEquipment - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperationBatchMode.CREEquipment
// 	
// Returns:
// 	See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperationBatchMode 
//
Function ParametersOfReceiptFiscalizationOperationBatchMode(DocumentRef, CREEquipment) Export
	
	Return GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperationBatchMode(DocumentRef, CREEquipment);
	
EndFunction

// Checks whether fiscalization is possible for a specific document
// 
// Parameters:
// 	DocumentRef - DocumentRef - document being checked
// 	
// Returns:
// 	Boolean
//
Function AllowedPenetrationOfFiscalChecksOnDocument(DocumentRef) Export

	ShapeStructure = New Structure;
	ShapeStructure.Insert("Object", DocumentRef);
	
	LocalizationModule = TMCommonUse.GetLocalizationModule(DocumentRef.Metadata().Name);

	If Not LocalizationModule.AllowedPenetrationOfFiscalChecksOnDocument(ShapeStructure) Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns parameters of the broken fiscal receipt for the document, otherwise, if it is not broken, it is undefined
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that the receipt may have been broken through
// 	CalculationType - EnumRef.CashSettlementTypes - Calculation type
// Returns:
// 	Structure, Undefined - Description: Parameters of a punctured fiscal receipt according to the document, otherwise, if not punctured, it is uncertain
Function DataOfPunchedFiscalCheckForDocument(DocumentRef, CalculationType = Undefined) Export
	
	Return GeneratingFiscalChecksServer.DataOfPunchedFiscalCheckForDocument(DocumentRef, CalculationType);
	
EndFunction

// Check penetration flag - broken = True, not broken = False
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that the receipt may have been broken through
//  CalculationType - EnumRef.CashSettlementTypes - Calculation type
// Returns:
// 	Boolean - Check penetration flag - broken = True, not broken = False
Function FiscalCheckOnDocumentIsBroken(DocumentRef, CalculationType = Undefined) Export
	
	Return GeneratingFiscalChecksServer.FiscalCheckOnDocumentIsBroken(DocumentRef, CalculationType);	
	
EndFunction

// Returns a flag for the correctness of entering settlement objects in the document: 
//  - if the document contains advance and prepaid settlement objects, the flag = A lie
//  - otherwise, flag = True.
// 
// Parameters:
// 	DocumentRef - DocumentRef - link to the payment document
// 	MessageText - String - Informational message to the user about an error, otherwise an empty string
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Boolean - Description - returns the status of correctness of filling in the calculation objects
Function PaymentObjectsEnteredCorrectlyInPaymentDocument(DocumentRef, MessageText, ReceiptPrintingCommandName) Export
	
	Return GeneratingFiscalChecksServer.PaymentObjectsEnteredCorrectlyInPaymentDocument(DocumentRef, MessageText, ReceiptPrintingCommandName);
	
EndFunction

// calls the method of the AR/AP accounting mechanism for distributing settlements with clients
// 
// Parameters:
// 	OperationParametersList - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation
//
Procedure DistributeSettlementsWithClients(OperationParametersList) Export
	
	GeneratingFiscalChecksServer.DistributeSettlementsWithClients(OperationParametersList);
	
EndProcedure

// Checks whether the barcodes of packages for marked goods are filled in in the documents
// 
// Parameters:
//  SaleDocuments - Array of DocumentRef.CustomerInvoice, DocumentRef.ReturnOfGoodsFromCustomer - Verifiable Documents
// 
// Returns:
//  Boolean - TRUE if the barcodes of packages for marked goods are filled in the documents
Function BarcodesOfPackagesAccordingToDocumentsAreFilledIn(SaleDocuments) Export
	
	Return GeneratingFiscalChecksServerOverridable.BarcodesOfPackagesAccordingToDocumentsAreFilledIn(SaleDocuments);
	
EndFunction

// Checks the data for correctness before the fiscal of operation
// 
// Parameters:
//  Object - DocumentObject - document form object
//  CheckParameters - Structure of KeyAndValue - Mandatory composition of properties for Transferring data from the client context:
//   *FormName - String
//   *CalculationType - EnumRef.CashSettlementTypes, Undefined - Used for the Debt Offset document, Undefined by default.
//   *ReceiptPrintingCommandName - String - By default, an empty string.
// 
// Returns:
// See GeneratingFiscalChecksServer.DataVerificationBeforeFiscalTransaction
Function DataVerificationBeforeFiscalTransaction(Val Object, CheckParameters) Export
	Return GeneratingFiscalChecksServer.DataVerificationBeforeFiscalTransaction(Object, CheckParameters);
EndFunction

#EndRegion