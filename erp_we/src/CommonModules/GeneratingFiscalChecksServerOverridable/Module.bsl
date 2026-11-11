#Region Public

// Defines the structure of parameters for printing receipts, fills in the parameters with default values
//
// Returns:
// 	Structure - parameter structure:
//	* DocumentRef - DocumentRef, Undefined - 
//	* Organization - CatalogRef.Companies, Undefined - 
//	* Counterparty - CatalogRef.Counterparties, Undefined - 
//	* Partner - CatalogRef.Partners, Undefined - 
//	* RetailFacility - CatalogRef.Warehouses, Undefined - 
//	* Currency - CatalogRef.Currencies, Undefined - 
//	* ARAPCurrency - CatalogRef.Currencies, Undefined - 
//	* DocumentAmount - Number, Undefined -
//	* ReceiptPrintingCommandName - String, Undefined - 
//	* NameOfHyperlinkDetailsOnForm - String, Undefined - 
//	* PaymentCompleted - Boolean, Undefined - 
//	* AcquiringTransactionParameters - See PeripheralsReceiptPrintersClientServer.BatchOperationParametersInReceiptQueue
Function StructureOfBasicOperationParameters() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DocumentRef", Undefined);
	ParametersStructure.Insert("Organization", Undefined);
	ParametersStructure.Insert("Counterparty", Undefined);
	ParametersStructure.Insert("Partner", Undefined);
	ParametersStructure.Insert("RetailFacility", Undefined);
	ParametersStructure.Insert("Currency", Undefined);
	ParametersStructure.Insert("ARAPCurrency", Undefined);
	ParametersStructure.Insert("DocumentAmount", Undefined);
	ParametersStructure.Insert("ReceiptPrintingCommandName", Undefined);
	ParametersStructure.Insert("NameOfHyperlinkDetailsOnForm", Undefined);
	ParametersStructure.Insert("PaymentCompleted", Undefined);
	ParametersStructure.Insert("AcquiringTransactionParameters", New Structure());
	
	Return ParametersStructure;
	
EndFunction

// Returns parameters for the document to generate the receipt preview form
// 
// Parameters:
// 	OperationParametersList - Structure - The main parameters of the document
// Returns:
// 	Structure - document parameters for forming a form for previewing the receipt
Function ReceiptPreviewParameters(OperationParametersList) Export
	
	ReceiptPreviewParameters = New Structure;
	
	// UpdateSettlements
	UpdateSettlements(
		OperationParametersList);
	
	// UnifiedReceiptParameters
	ReceiptPreviewParameters.Insert(
		"SingleReceiptDocuments",
		UnifiedReceiptParameters(OperationParametersList));
	
	// AmountOfPrepaymentWithinOneDay
	ReceiptPreviewParameters.Insert(
		"AmountOfPrepaymentWithinOneDay",
		 PrepaymentAccordingToDeliveryDocumentWithinOneDay(OperationParametersList.DocumentRef));
	
	// PrepaymentAmountOutsideOfOneDay
	ReceiptPreviewParameters.Insert(
		"PrepaymentAmountOutsideOfOneDay",
		 PrepaymentForDeliveryDocumentOutsideOfOneDayLocalization(OperationParametersList.DocumentRef));
	
	// ObjectsOfCalculationsForDocument
	ObjectsOfCalculationsForDocument = ObjectsOfCalculationsForDocument(OperationParametersList);
	ReceiptPreviewParameters.Insert(
		"ObjectsOfCalculationsForDocument",
		ObjectsOfCalculationsForDocument);
	
	// AutoCalculationMethodFlags
	AutoCalculationMethodFlags = AutoCalculationMethodFlags(
		OperationParametersList,
		ObjectsOfCalculationsForDocument);
	ReceiptPreviewParameters.Insert(
		"AutoCalculationMethodFlags",
		AutoCalculationMethodFlags);
	
	// FiscalOperationData
	FiscalOperationData = FiscalOperationData();
	ReceiptPreviewParameters.Insert(
		"FiscalOperationData",
		FiscalOperationData);

	// FiscalReceiptParameters
	ReceiptPreviewParameters.Insert(
		"ParametersOfReceiptFiscalizationOperation",
		ParametersOfReceiptFiscalizationOperation(OperationParametersList));
		
	// Parameters of the personal data of the buyer
	ParametersForCheckingPermissionToEnterPersonalData = New Structure;
	ParametersForCheckingPermissionToEnterPersonalData.Insert(
		"SingleReceipt",
		ReceiptPreviewParameters.ParametersOfReceiptFiscalizationOperation.SingleReceipt);
	ParametersForCheckingPermissionToEnterPersonalData.Insert(
		"DocumentRef",
		ReceiptPreviewParameters.ParametersOfReceiptFiscalizationOperation.DocumentBasis);
	ParametersForCheckingPermissionToEnterPersonalData.Insert(
		"Counterparty",
		OperationParametersList.Counterparty);	
	ReceiptPreviewParameters.Insert(
		"PersonalDataInputIsAllowed",
		PersonalDataInputIsAllowed(ParametersForCheckingPermissionToEnterPersonalData));
	
	// AccessRights
	ReceiptPreviewParameters.Insert(
		"AccessRights",
		AccessRights());
	
	Return ReceiptPreviewParameters;
	
EndFunction

// Returns the status of the document working with acquiring equipment
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document to be checked for the ability to work with acquiring equipment
// Returns:
// 	Boolean - The status of the document with acquiring equipment
Function ItIsSupposedToConnectAcquiringTerminalAccordingToDocument(DocumentRef) Export
	
	ItIsSupposedToConnectAcquiringTerminalAccordingToDocument = False;
	
	
	Return ItIsSupposedToConnectAcquiringTerminalAccordingToDocument;
	
EndFunction

// Specifies the date of operation for the correction receipt.
// The date is determined on the basis of the document being corrected or its foundation document.
// For implementation documents, the date of transfer of ownership is taken into account.
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document to be corrected
// Returns:
// 	Date - Date of operation of the correction receipt for the document
Function DateOfAdjustedCalculation(DocumentRef) Export
	
	CorrectionDate_ = CurrentSessionDate();
	
	
	Return CorrectionDate_;
	
EndFunction

// Defines the types of types of fiscal receipts by documents
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Array of EnumRef.TypesOfCREFiscalDocuments - Types of fiscal receipts
Function TypesOfFiscalDocument(DocumentRef, ReceiptPrintingCommandName) Export
	
	TypesOfFiscalDocument = New Array;
	
	
	Return TypesOfFiscalDocument;
	
EndFunction

// Defines the types of cash payments for a document
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// 	FiscalDocumentType - EnumRef.TypesOfCREFiscalDocuments - Type of fiscal document
// Returns:
// 	Array of EnumRef.CashSettlementTypes - Types of cash settlement
Function CashSettlementTypes(DocumentRef, ReceiptPrintingCommandName, FiscalDocumentType) Export
	
	CashSettlementTypes = New Array;
	
	
	Return CashSettlementTypes;
	
EndFunction

// Defines the types of correction receipt for the document
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Array of EnumRef.KindsOfAdjustmentReceipts - Types of correction receipt
Function TypesOfCorrectionReceipt(DocumentRef, ReceiptPrintingCommandName) Export
	
	TypesOfCorrectionReceipt = New Array;
	
	
	Return TypesOfCorrectionReceipt;
	
EndFunction

// Generates a table of payment objects with the characteristics of the payment method for each object to form the receipt position
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	PossibleSignsOfCalculationMethodForDocument - ValueTable - Possible attributes of the document calculation method
// 	AutoCalculationMethodFlags - ValueTable - Signs of the settlement method for settlements with the counterparty
// 	ShowsCalculationMethod - EnumRef.CalculationMethodFlags - Selected attribute of the calculation method
// 	ARAPObjects - ValueTable - Objects of calculations based on the document
// 	DocumentAmount - Number - The amount of the document
// Returns:
// 	ValueTable - Table of settlement objects with signs of the method of settlement for each object:
//	* ARAPObject - DocumentRef, CatalogRef - 
//	* ShowsCalculationMethod - EnumRef.CalculationMethodFlags - 
//	* Sum - Number - 
Function CalculationObjectsWithCalculationMethodAttributes(DocumentRef, PossibleSignsOfCalculationMethodForDocument, AutoCalculationMethodFlags, ShowsCalculationMethod, ARAPObjects, DocumentAmount, AmountOfPrepaymentWithinOneDay) Export
	
	ARAPObjectTypes = Documents.AllRefsType().Types();
	ARAPObjectTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	ARAPObjectTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	ARAPObjectTypes.Add(Type("CatalogRef.GiftCertificates"));
	
	CalculationObjectsWithCalculationMethodAttributes = New ValueTable;
	CalculationObjectsWithCalculationMethodAttributes.Columns.Add("ARAPObject", New TypeDescription(New TypeDescription, ARAPObjectTypes));
	CalculationObjectsWithCalculationMethodAttributes.Columns.Add("ShowsCalculationMethod", TMCommonUse.DescriptionOfTypesByType(Type("EnumRef.CalculationMethodFlags")));
	CalculationObjectsWithCalculationMethodAttributes.Columns.Add("Sum", TMCommonUse.DescriptionOfTypesByType(Type("Number")));
	
	
	Return CalculationObjectsWithCalculationMethodAttributes;
	
EndFunction

// Determines whether the document is a payment document with the ability to break through the receipt
// 
// Parameters:
// 	DocumentRef - DocumentRef - document being checked
// Returns:
// 	Boolean - flag whether the document is a payment document with the ability to break through the receipt, yes = true, no = false
Function PaymentDocumentWithAbilityToBreakChecks(DocumentRef) Export
	
	PaymentDocumentWithAbilityToBreakChecks = False;
	
	
	Return PaymentDocumentWithAbilityToBreakChecks;
	
EndFunction

// Determines whether the document is a delivery document with the ability to break through the receipt
// 
// Parameters:
// 	DocumentRef - DocumentRef - document being checked
// Returns:
// 	Boolean - flag whether the document is a delivery document with the ability to break through the receipt, yes = true, no = false
Function DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Export
	
	DeliveryDocumentWithPossibilityOfPunchingChecks = False;
	
	
	Return DeliveryDocumentWithPossibilityOfPunchingChecks;
	
EndFunction

// Determines whether the payment item is an advance payment item
// 
// Parameters:
// 	ARAPObject - CatalogRef, DocumentRef - the object of the calculation of the payment document
// Returns:
// 	Boolean - flag whether the calculation object is an advance payment, yes = true, no = false
Function ObjectOfSettlementsAdvance(ARAPObject) Export
	
	ObjectOfSettlementsAdvance = False;
	
	
	Return ObjectOfSettlementsAdvance;
	
EndFunction

// Determines whether the settlement object is prepaid
// 
// Parameters:
// 	ARAPObject - DocumentRef - the object of the calculation of the payment document
// Returns:
// 	Boolean - flag whether the payment object is prepaid, yes = true, no = false
Function SettlementObjectIsPrepaid(ARAPObject) Export
	
	SettlementObjectIsPrepaid = False;
	
	
	Return SettlementObjectIsPrepaid;
	
EndFunction

// Defines the payment document for the document of delivery of goods/services. If there are more than one payment documents or
// there were no payments under the document, it is returned Indefinitely.
// 
// Parameters:
// 	DocumentRef - DocumentRef - Delivery document
// Returns:
// 	Undefined - LongDesc
Function PaymentDocumentForDeliveryDocumentWithinSingleReceipt(DocumentRef) Export
	
	SetPrivilegedMode(True);
	
	PaymentDocumentForDeliveryDocument = New Array;
	
	
	Return PaymentDocumentForDeliveryDocument;
	
EndFunction

// Defines the document of delivery of goods/services according to the payment document. If there are more than one delivery documents or
// there was no delivery according to the document, it is returned Indefinitely.
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document Of Payment
// Returns:
// 	Undefined - LongDesc
Function DeliveryDocumentAccordingToPaymentDocumentWithinFrameworkOfSingleCheck(DocumentRef) Export
	
	SetPrivilegedMode(True);
	
	PaymentDocumentForDeliveryDocument = New Array;
	
	
	Return PaymentDocumentForDeliveryDocument;
	
EndFunction

// Defines the payment document for the document of delivery of goods/services. If there are more than one payment documents or
// there were no payments under the document, it is returned Indefinitely.
// 
// Parameters:
// 	DocumentRef - DocumentRef - Delivery document
// Returns:
// 	Undefined - LongDesc
Function OneDayDeliveryDocumentARAPTransaction(DocumentRef) Export
	
	SetPrivilegedMode(True);
	
	PaymentDocumentForDeliveryDocument = New Array;
	
	
	Return PaymentDocumentForDeliveryDocument;
	
EndFunction

// Updates the parameters of the receipt fiscalization operation
// 
// Parameters:
// 	ReceiptOperationParameters - Structure - Data for generating parameters of the receipt fiscalization operation
// 	FDFVersion - String - FFD Version
// Returns:
// 	Structure - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
Function UpdateFiscalReceiptParameters(ReceiptOperationParameters, FDFVersion) Export
	
	ParametersOfReceiptFiscalizationOperation = GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation(
		ReceiptOperationParameters.DocumentRef,
		ReceiptOperationParameters.Organization);
	
	
	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

// Generates the text of a non-fiscal receipt based on a template.
// 
// Parameters:
// 	ParametersOfReceiptFiscalizationOperation - Structure - Parameters of the receipt fiscalization operation
// 	FDFVersion - String - Version of the FFD used for generating the receipt text
// Returns:
// 	String - The text of a non-fiscal receipt according to a template
Function UpdateReceiptTemplate(ParametersOfReceiptFiscalizationOperation, FDFVersion) Export
	
	TextOfNonFiscalReceipt = "";
	
	
	Return TextOfNonFiscalReceipt;
	
EndFunction

// Returns an array of possible attributes of the document calculation method
// 
// Parameters:
//  CalculationMethodFlags - Array of EnumRef.CalculationMethodFlags - Indicates the calculation method for the document, return value
// 	DocumentRef - DocumentRef - Document
// 	ARAPObjects - CatalogRef, DocumentRef - Document calculation objects 
// 	CashSettlementType - EnumRef.CashSettlementTypes - type of cash settlement
// 	DocumentAmount - Number - The amount of the document
Procedure TypesOfPossibleAttributesOfCalculationMethodForDocument(CalculationMethodFlags, DocumentRef, ARAPObjects, CashSettlementType, DocumentAmount) Export
	
	
EndProcedure

// Returns an array of possible attributes of the document calculation method
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document
// 	ARAPObjects - CatalogRef, DocumentRef - Document calculation objects 
// 	CashSettlementType - EnumRef.CashSettlementTypes - type of cash settlement
// 	DocumentAmount - Number - The amount of the document
// Returns:
// 	EnumRef.CalculationMethodFlags - Array of possible attributes of the document calculation method
Function FlagForDefaultPaymentMethod(DocumentRef, ARAPObjects, CashSettlementType, DocumentAmount) Export
	
	FlagForDefaultPaymentMethod = Enums.CalculationMethodFlags.EmptyRef();
	
	
	Return FlagForDefaultPaymentMethod;
	
EndFunction

// Returns the supported maximum version of the FFD
// 
// Returns:
// 	String - Description - FFD Version
Function MaximumFFDVersion() Export

	MaximumFFDVersion = "";
	
	
	Return MaximumFFDVersion;

EndFunction

// Returns the hardware-supported version of the FFD
// 
// Parameters:
// 	Peripherals - CatalogRef.Peripherals - CREWithDataTransfer
// Returns:
// 	String - The FFD version supported by the hardware
Function FFDHardwareVersion(Peripherals) Export

	FFDVersionValue = "";
	
	
	Return FFDVersionValue;

EndFunction

// Checks whether the entered TIN meets the legal requirements
// 
// Parameters:
// 	DocumentRef - DocumentRef - Receipt printing document
// 	TIN - String - Entered TIN
// 	MessageText - String - Error message
// Returns:
// 	Boolean - The status of the correctness of entering the TIN
Function TinMeetsRequirementsOnServer(DocumentRef, TIN, MessageText) Export
	
	TinFilledInCorrectly = True;
	
	
	Return TinFilledInCorrectly;
	
EndFunction

// Returns the connected equipment for the organization and the trading object
// 
// Parameters:
// 	OperationParametersList - Structure - The structure of the operation parameters
// Returns:
// 	Array of Structure - list of connected equipment:
// 	* Equipment - CatalogRef.Peripherals - Equipment
// 	* Attached - Boolean - The Status of the connection, where True = connected
// 	* FDFVersion - String - Hardware-supported version of the FFD
Function ConnectedReceiptPrintingEquipment(OperationParametersList) Export
	
	ConnectedReceiptPrintingEquipment = New Array;
	
	
	Return ConnectedReceiptPrintingEquipment;
	
EndFunction

// Returns objects of calculation of the payment document
// 
// Parameters:
//  PaymentDocuments - DocumentRef - Payment documents
//  ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
//  Undefined,ValueTable:
//   *OrderDocument - DocumentRef,CatalogRef
//   *Sum - Number
//
Function SettlementObjectsOfPaymentDocument(PaymentDocuments, ReceiptPrintingCommandName) Export
	
	SettlementObjectsOfPaymentDocument = Undefined;
	
	
	Return SettlementObjectsOfPaymentDocument;
	
EndFunction

// Updates the hyperlink view with the fiscal receipt data in the passed parameter " requisites hyperlink Form"
// 
// Parameters:
// 	DocumentRef - DocumentRef - Link to the document that is expected to be able
// 	 to enter/display the fiscal receipt from the document form.
// 	Form - ClientApplicationForm - The document form where you need to update the hyperlink for entering / displaying
// 	 the fiscal receipt.
// 	HyperlinkDetailsOnForm - FormAttribute - Form details that display a hyperlink for entering / displaying the fiscal
// 	 receipt.
Procedure UpdateFiscalCheckBreakdownHyperlink(DocumentRef, Form, HyperlinkDetailsOnForm) Export
	
	
EndProcedure

// Creating a cache of data is the main operation parameters when creating a form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form.
Procedure FormWhenCreatedOnServer(Form) Export
	
	
EndProcedure

// Creating a cache of data is the main parameters of the operation when reading the form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form.
Procedure FormWhenReadingOnServer(Form) Export
	
	
EndProcedure

// Creating a cache of data is the main parameters of the operation when changing the form details
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form consists of
Procedure FormWhenChangingBankingDetails(Form) Export
	
	
EndProcedure

// Extension for the Receipt processing methodform of the Processing manager module.Check preview.
// 	
// Parameters:
// 	FormType - String - name of the standard form.
// 	Parameters - Structure - Shape parameter
// 	SelectedForm - String, MetadataObject - Contains the name of the form to open or the form metadata object
// 	AdditionalInformation - Structure - additional information for opening the form.
// 	StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure ProcessingReceiptOfFormPreviewingReceipt(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export

	
EndProcedure

// Determines whether the document is used to pay with a gift certificate.
// 
// Parameters:
//  DocumentRef - DocumentRef.ARAPSettlement - Debt offset
// 
// Returns:
//  Boolean - Truth, payment by gift certificate
Function PaymentByGiftCard(DocumentRef) Export
	
	PaymentByGiftCard = False;
	
	If TypeOf(DocumentRef) = Type("DocumentRef.ARAPSettlement")
		And Common.ObjectAttributeValue(DocumentRef, "OperationKind")
			= Enums.KindsOfARAPSettlements.PaymentByGiftCard Then
			
		PaymentByGiftCard = True;
	EndIf;
	
	Return PaymentByGiftCard;
	
EndFunction


// Checks the permission to enter personal data 
//
// Parameters:
// 	ReceiptOperationParameters - Structure - Parameters required to check the permission:
// 	* DocumentRef - DocumentRef - Link to the delivery/payment document
// 	* Counterparty - CatalogRef.Counterparties - Customer
// 	* SingleReceipt - Boolean - The sign of a single receipt
// Returns:
//  Boolean - 
Function PersonalDataInputIsAllowed(ReceiptOperationParameters) Export
	
	PersonalDataInputIsAllowed = False;
	
	
	Return PersonalDataInputIsAllowed;
	
EndFunction

// calls the method of the AR/AP accounting mechanism for distributing settlements with clients
// 
// Parameters:
// 	OperationParametersList - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation
//
Procedure DistributeSettlementsWithClients(OperationParametersList) Export
	
	
EndProcedure

// performs a check that the distribution of AR/AP accounts is up-to-date.
// 
// Parameters:
// 	OperationParametersList - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation
//
// Returns:
//  Boolean
Function ARAPAccountsHaveBeenCalculated(OperationParametersList) Export
	
	ARAPAccountsHaveBeenCalculated = True;
	
	
	Return ARAPAccountsHaveBeenCalculated;
	
EndFunction

// Checks that the type of cash payments is included in the list of corrections allowed for using the cash receipt.
//
// Parameters:
//  TypeOfCashSettlements - EnumRef.CashSettlementTypes -
//
// Returns:
//  Boolean -
//
Function SalesSlipCorrectionIsAllowedForTypeOfCalculations(TypeOfCashSettlements) Export

	Result = False;
	
	If TypeOfCashSettlements = Enums.CashSettlementTypes.CashReceipt 
		Or TypeOfCashSettlements = Enums.CashSettlementTypes.CashOutflow
		Or TypeOfCashSettlements = Enums.CashSettlementTypes.Refund Then
		Result = True;
	EndIf;

	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region MethodsForFillingInReceiptPreviewParameters

Procedure UpdateSettlements(OperationParametersList)
	
	
EndProcedure

Function UnifiedReceiptParameters(OperationParametersList)
	
	SingleReceiptDocuments = New ValueTable();
	SingleReceiptDocuments.Columns.Add("Document");
	SingleReceiptDocuments.Columns.Add("Sum");
	
	
	Return SingleReceiptDocuments;
	
EndFunction

Function PrepaymentAccordingToDeliveryDocumentWithinOneDay(DocumentRef)
	
	PrepaymentAmountMan = 0;
	
	
	Return PrepaymentAmountMan;
	
EndFunction

Function PrepaymentForDeliveryDocumentOutsideOfOneDayLocalization(DocumentRef)
	
	PrepaymentAmountMan = 0;
	
	
	Return PrepaymentAmountMan;
	
EndFunction

Function ObjectsOfCalculationsForDocument(OperationParametersList)
	
	ObjectsOfCalculationsForDocument = New ValueTable();
	ObjectsOfCalculationsForDocument.Columns.Add("ARAPObject");
	ObjectsOfCalculationsForDocument.Columns.Add("OrderDocument");
	ObjectsOfCalculationsForDocument.Columns.Add("Sum");
	
	
	Return ObjectsOfCalculationsForDocument;
	
EndFunction

Function AutoCalculationMethodFlags(OperationParametersList, ObjectsOfCalculationsForDocument)
	
	AutoCalculationMethodFlags = New Array;
	
	
	Return AutoCalculationMethodFlags;
	
EndFunction

Function FiscalOperationData()
	
	Return RetailSales.StructureOfFiscalTransactionData();
	
EndFunction

Function ParametersOfReceiptFiscalizationOperation(OperationParametersList)
	
	Return GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation(
		OperationParametersList.DocumentRef,
		OperationParametersList.Organization);
	
EndFunction

Function AccessRights()
	
	Return SalesSettingsForUsersServer.CWPAccessRights(Users.CurrentUser());
	
EndFunction

// Checks the filling of excise stamps for one document (checking by object)
// 
// Parameters:
//  DocumentObject - DocumentObject - DocumentObject
// 
// Returns:
//  Boolean - Test result
Function BarcodesOfPackagesAreFilled(DocumentObject) Export
	
	Result = False;
	
	
	Return Not Result;
	
EndFunction

// Checks the filling of excise stamps for one document or a list of documents (checking by links)
// 
// Parameters:
//  SaleDocuments - DocumentRef, Array of DocumentRef - objects to check (link or links of the same type).
// 
// Returns:
//  Boolean - Test result
Function BarcodesOfPackagesAccordingToDocumentsAreFilledIn(SaleDocuments) Export
	
	Result = False;
	
	
	Return Not Result;
	
EndFunction

#EndRegion


#EndRegion

