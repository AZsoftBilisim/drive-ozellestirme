#Region Public

// Returns parameters for the document for forming the receipt preview form
// 
// Parameters:
// 	OperationParametersList - Structure - The main parameters of the document
// Returns:
// 	Structure - document parameters for forming a form for previewing a receipt
Function ReceiptPreviewParameters(OperationParametersList) Export
	
	Return GeneratingFiscalChecksServerOverridable.ReceiptPreviewParameters(OperationParametersList);
	
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
	
	GeneratingFiscalChecksServerOverridable.UpdateFiscalCheckBreakdownHyperlink(DocumentRef, Form, HyperlinkDetailsOnForm);
	
EndProcedure

// Manages the properties of the hyperlink form element of the fiscal receipt breakdown
// 
// Parameters:
// 	Form - ClientApplicationForm - The form of the document on which you need to configure the hyperlink field for entering/displaying
// 	 the fiscal receipt.
// 	HyperlinkElementOnForm - FormField - A form field displaying a hyperlink for entering/displaying a fiscal
// 	 receipt.
Procedure ConfigureFiscalReceiptPenetrationHyperlinkElement(Form, HyperlinkElementOnForm) Export
	
	If Form.ReadOnly Or Not AccessRight("Update", Form.Object.Ref.Metadata()) Then
		HyperlinkElementOnForm.Enabled = False;	
	EndIf;

EndProcedure

// Checks whether the current user has the right to hold the document
// 
// Parameters:
// 	DocumentRef - DocumentRef - Link to the document that is expected to be able
// 	 to enter/display the fiscal receipt from the document form.
// Returns:
// 	Boolean - Returns True if the user has the right to hold the document
Function ThereIsRightToBreakFiscalCheckOnDocument(DocumentRef) Export
	
	Return (UserHasRightToHoldDocumentInteractively(DocumentRef)
		Or DocumentPosted(DocumentRef));

EndFunction

// Checks whether the current user has configured the connected equipment for the organization's cash register
// 
// Parameters:
// 	Organization - CatalogRef.Companies - Link to the organization from the document form
//
// Returns:
// 	Boolean - Returns True if the connected equipment for the organization's cash register is configured
Function ThereIsConnectedEquipmentToOrganizationSCashRegisters(Organization) Export		
	ThereIsConnectedEquipment = False;
	ConnectedEquipmentByOrganization = TMPeripheralsServerCall.EquipmentConnectedToCheckoutByOrganization(Organization);
	If ConnectedEquipmentByOrganization.CREWITHDATATRANSFER.Count() Then
		ThereIsConnectedEquipment = True;
	EndIf;
	Return ThereIsConnectedEquipment; 
EndFunction

// Adds a hyperlink view of the command to open a broken receipt
// 
// Parameters:
// 	PresentationsArray - Array of FormattedString - An array of hyperlink representations
// 	CashRegisterReceiptNumber - String - Number of the CMC receipt that was punched through the document
// 	HyperlinkAnchorText - String - The text of the hyperlink for the treatment of depression
// 	PresentationText - String - Text of the hyperlink view that the user sees on the form
Procedure AddCheckProbitCommandToHyperlinkPresentation(PresentationsArray, CashRegisterReceiptNumber, HyperlinkAnchorText, PresentationText = Undefined) Export
	
	PresentationReceiptPunched = StrTemplate(NStr("vi = 'Đã đánh phiếu số%1';
													|ru = 'Пробит чек №%1';
													|en = 'Receipt No.%1 is issued'; fa = 'Receipt No.%1 is issued';
													|it = 'Scontrino №%1 emesso';
													|pl = 'Wydrukowano paragon nr%1';
													|tr = 'Fiş No%1 kesildi'"), CashRegisterReceiptNumber);
	If PresentationText <> Undefined Then
		PresentationReceiptPunched = PresentationText;
	EndIf;
	
	PresentationsArray.Add(New FormattedString(PresentationReceiptPunched, , StyleColors.HyperlinkColor, , HyperlinkAnchorText));

EndProcedure

// Adds a hyperlink view of the check breakout command
// 
// Parameters:
// 	PresentationsArray - Array of FormattedString - An array of hyperlink representations
// 	HyperlinkAnchorText - String - The text of the hyperlink for the treatment of depression
// 	PresentationText - String, Undefined - Text of the hyperlink view from the call
Procedure AddPunchReceiptCommandToHyperlinkPresentation(PresentationsArray, HyperlinkAnchorText, PresentationText = Undefined) Export
	
	PresentationPreviewOfReceipt = NStr("vi = 'Đánh phiếu tính tiền';
										|ru = 'Пробить чек';
										|en = 'Issue cash receipt'; fa = 'صدور رسید نقدی';
										|it = 'Emettere lo scontrino';
										|pl = 'Wydrukuj paragon';
										|tr = 'Fiş kes'");
	If PresentationText <> Undefined Then
		PresentationPreviewOfReceipt = PresentationText;
	EndIf;
	
	PresentationsArray.Add(New FormattedString(PresentationPreviewOfReceipt, , StyleColors.HyperlinkColor, , HyperlinkAnchorText));

EndProcedure

// Adds an unbroken receipt hyperlink view
// 
// Parameters:
// 	PresentationsArray - Array of FormattedString - An array of hyperlink representations
// 	HyperlinkAnchorText - String - The text of the hyperlink for the treatment of depression
Procedure AddHyperlinksToPresentationReceiptFailedStatus(PresentationsArray, HyperlinkAnchorText = "") Export

	PresentationReceiptFailed = NStr("vi = 'Phiếu chưa đánh';
									|ru = 'Чек не пробит';
									|en = 'Receipt is not issued'; fa = 'رسید صادر نشده است';
									|it = 'Lo scontrino non è stato emesso';
									|pl = 'Nie wydrukowano paragonu';
									|tr = 'Fiş kesilmedi'");
	PresentationsArray.Add(New FormattedString(PresentationReceiptFailed, , StyleColors.HyperlinkColor, , HyperlinkAnchorText));

EndProcedure

// Returns the supported maximum version of the FFD
// 
// Returns:
// 	String - Description - FFD Version
Function MaximumFFDVersion() Export
	
	Return GeneratingFiscalChecksServerOverridable.MaximumFFDVersion();

EndFunction

// Returns parameters of the broken fiscal receipt for the document, otherwise, if it is not broken, it is undefined
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that the receipt may have been broken through
// 	CalculationType - EnumRef.CashSettlementTypes - Calculation type
// Returns:
// 	Structure, Undefined - Description: Parameters of a punctured fiscal receipt according to the document, otherwise, if not punctured, it is uncertain
Function DataOfPunchedFiscalCheckForDocument(DocumentRef, CalculationType = Undefined) Export
	
	If Not ValueIsFilled(DocumentRef) Then
		Return Undefined;
	EndIf;

	// Get fiscal transaction data for a document from the fiscal transaction log
	DataOfPunchedFiscalCheckForDocument = EquipmentReceiptPrintersServerCall.FiscalOperationData(DocumentRef, , , CalculationType);
	
	// If the data of the fiscal operation on the document is not received, get the data of the fiscal operation on the document that
	// the document "Adjustment of implementation" could make in the "Non-Use of CCT" mode
	If DataOfPunchedFiscalCheckForDocument = Undefined Then
		If TypeOf(DocumentRef) = Type("DocumentRef.CashRegisterReceipt") Then
			DataOfPunchedFiscalCheckForDocument = TMPeripheralsServerCall.DataOfFiscalOfOperationTakingIntoAccountCashREGISTERCorrectionReceipt(DocumentRef);
		Else
			DataOfPunchedFiscalCheckForDocument = TMPeripheralsServerCall.FiscalTransactionDataWithImplementationAdjustment(DocumentRef);
		EndIf;
	EndIf;
	
	// If the fiscal transaction data for the document has not been received, check whether a single receipt for the commodity
	// document has not been punched
	If DataOfPunchedFiscalCheckForDocument = Undefined Then
		
		DocumentsWithinSingleReceipt = Undefined;
		
		If (TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoiceServices")
			Or TypeOf(DocumentRef) = Type("DocumentRef.ReturnOfGoodsFromCustomer")
			Or TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoice")
			Or TypeOf(DocumentRef) = Type("DocumentRef.CustomerInvoiceServicesAndAssets")) Then
		
			DocumentsWithinSingleReceipt = GeneratingFiscalChecksServerOverridable.PaymentDocumentForDeliveryDocumentWithinSingleReceipt(DocumentRef);
		
		ElsIf (TypeOf(DocumentRef) = Type("DocumentRef.CashAccountReceiptNote")
			Or TypeOf(DocumentRef) = Type("DocumentRef.CashVoucher")
			Or TypeOf(DocumentRef) = Type("DocumentRef.PaymentCardTransaction")) Then
			
			DocumentsWithinSingleReceipt = GeneratingFiscalChecksServerOverridable.DeliveryDocumentAccordingToPaymentDocumentWithinFrameworkOfSingleCheck(DocumentRef);
		
		EndIf;
		
		If DocumentsWithinSingleReceipt <> Undefined Then
			
			For Each SingleReceiptDocument In DocumentsWithinSingleReceipt Do
				DataOfPunchedFiscalCheckForDocument = EquipmentReceiptPrintersServerCall.FiscalOperationData(SingleReceiptDocument);
				
				If DataOfPunchedFiscalCheckForDocument <> Undefined
					And DataOfPunchedFiscalCheckForDocument.SingleReceipt Then
					
					Break;
				Else
					DataOfPunchedFiscalCheckForDocument = Undefined;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return DataOfPunchedFiscalCheckForDocument;

EndFunction

// Check penetration flag - broken = True, not broken = False
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that the receipt may have been broken through
// 	CalculationType - EnumRef.CashSettlementTypes - Calculation type
// Returns:
// 	Boolean - Check penetration flag - broken = True, not broken = False
Function FiscalCheckOnDocumentIsBroken(DocumentRef, CalculationType = Undefined) Export
	
	ReceiptIsIssued = False;
	
	FiscalOperationLogData = DataOfPunchedFiscalCheckForDocument(DocumentRef, CalculationType = Undefined);
	
	If FiscalOperationLogData <> Undefined Then
		ReceiptIsIssued = True;
	EndIf;
	
	Return ReceiptIsIssued;
	
EndFunction

// Returns an array of possible attributes of the document calculation method
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document
// 	ARAPObjects - CatalogRef, DocumentRef - Document calculation objects 
// 	CashSettlementType - EnumRef.CashSettlementTypes - type of cash settlement
// 	DocumentAmount - Number - The amount of the document
// Returns:
// 	Array - Array of possible attributes of the document calculation method
Function TypesOfPossibleAttributesOfCalculationMethodForDocument(DocumentRef, ARAPObjects, CashSettlementType, DocumentAmount) Export
	
	CalculationMethodFlags = New Array();
	
	GeneratingFiscalChecksServerOverridable.TypesOfPossibleAttributesOfCalculationMethodForDocument(
		CalculationMethodFlags,
		DocumentRef,
		ARAPObjects,
		CashSettlementType,
		DocumentAmount);
	
	Return CalculationMethodFlags;
	
EndFunction

// Returns the attribute of the default calculation method for the document
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document
// 	ARAPObjects - CatalogRef, DocumentRef - Document calculation objects 
// 	CashSettlementType - EnumRef.CashSettlementTypes - type of cash settlement
// 	DocumentAmount - Number - The amount of the document
// Returns:
// 	EnumRef.CashSettlementTypes - Indicates the default calculation method for the document
Function FlagForDefaultPaymentMethod(DocumentRef, ARAPObjects, CashSettlementType, DocumentAmount) Export
	
	Return GeneratingFiscalChecksServerOverridable.FlagForDefaultPaymentMethod(
				DocumentRef,
				ARAPObjects,
				CashSettlementType,
				DocumentAmount);
	
EndFunction

// Returns a flag for the correctness of entering settlement objects in the document: 
//  - if the document contains advance and prepaid settlement objects, the flag = False - otherwise, flag = True.
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document Of Payment
// 	MessageText - String - Informational message to the user about an error, otherwise an empty string
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Boolean - returns the status of correctness of filling in the calculation objects
Function PaymentObjectsEnteredCorrectlyInPaymentDocument(DocumentRef, MessageText, ReceiptPrintingCommandName) Export
	
	If Not GeneratingFiscalChecksServerOverridable.PaymentDocumentWithAbilityToBreakChecks(DocumentRef) Then
		Return True;
	EndIf;	
		
	ThereIsObjectOfCalculationsInAdvance = False;
	ThereIsCalculationObject = False;
	
	PaymentDocuments = New Array;
	PaymentDocuments.Add(DocumentRef);
	
	ARAPObjects = SettlementObjectsOfPaymentDocument(PaymentDocuments, ReceiptPrintingCommandName);
	For Each ARAPObject In ARAPObjects Do
		If GeneratingFiscalChecksServerOverridable.ObjectOfSettlementsAdvance(ARAPObject.OrderDocument) Then
			ThereIsObjectOfCalculationsInAdvance = True;
		Else
			ThereIsCalculationObject = True;
		EndIf;
	EndDo;
	
	If ThereIsObjectOfCalculationsInAdvance And ThereIsCalculationObject Then
		MessageText = NStr("vi = 'Không thể trả trước và thanh toán tạm ứng trong một đối tượng thanh toán. Phải chia thành các chứng từ thanh toán riêng.';
							|ru = 'Нельзя в одном объекте расчетов оплачивать аванс и предоплату. Необходимо разделить на отдельные документы оплаты.';
							|en = 'You cannot make both an advance payment and prepayment in a single AR/AP object. It should be divided into separate AR/AP transactions.'; fa = 'You cannot make both an advance payment and prepayment in a single AR/AP object. It should be divided into separate AR/AP transactions.';
							|it = 'È impossibile pagare un anticipo e un pagamento anticipato in un oggetto di pagamento. È necessario suddividerlo in documenti di pagamento separati.';
							|pl = 'Nie można w jednym obiekcie obliczeń opłacać zaliczkę i przedpłatę. Należy podzielić na poszczególne dokumenty płatności.';
							|tr = 'Aynı Alacak/Borç nesnesinde bir avans ödemesi ve bir ön ödeme yapılamaz. Bunları farklı ödeme belgelerine ayırmak gerekir.'");
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Determines whether the document is a delivery document with the ability to break through the receipt
// 
// Parameters:
// 	DocumentRef - DocumentRef - document being checked
// Returns:
// 	Boolean - flag whether the document is a delivery document with the ability to break through the receipt, yes = true, no = false
Function DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef) Export
	
	Return GeneratingFiscalChecksServerOverridable.DeliveryDocumentWithPossibilityOfPunchingChecks(DocumentRef);
	
EndFunction

// Returns an array of available cash registers for the current RMK setup
// 
// Parameters:
//  AvailableCashRegisters - Array - A parameter that can be re-filled by the available cash registers of the KKM
//  CashRegister - CatalogRef.CashRegisters - KKM sales register for getting the current RMK settings
//  ByCashRegisterCompany - Boolean - If True, then only the cashier of the same organization as the cashier is searched
//
Procedure FillInAvailableCashRegisterSalesRegisters(AvailableCashRegisters, CashRegister, ByCashRegisterCompany = False) Export
	
	AvailableCashRegisters.Clear();

	Workplace = EquipmentManagerServerCall.GetClientSWorkplace();

	Query = New Query(
	"SELECT ALLOWED TOP 1
	|	CWPSettings.CashRegisters.(
	|		CashRegister AS CashRegister,
	|		CashRegister.CashRegisterType AS CashRegisterType,
	|		CashRegister.Owner AS Organization
	|	) AS AvailableCashRegisters,
	|	CAST(&CashRegister AS Catalog.CashRegisters).Owner AS KKMCashRegisterIsRegisteredCompany
	|FROM
	|	Catalog.CWPSettings AS CWPSettings
	|WHERE
	|	CWPSettings.Workplace = &Workplace
	|	AND CWPSettings.Ref IN (SELECT DISTINCT T.Ref FROM Catalog.CWPSettings.CashRegisters AS T WHERE T.CashRegister = &CashRegister)
	|");

	Query.SetParameter("Workplace", Workplace);
	Query.SetParameter("CashRegister", CashRegister);

	Result = Query.Execute();
	Selection = Result.Select();

	If Selection.Next() Then

		AvailableCashRegisterCheckoutSelection = Selection.AvailableCashRegisters; // QueryResultSelection - sampling by Cash Registers of the KKM from the RMK Setup 
		SampleAvailableCashRegisters = AvailableCashRegisterCheckoutSelection.Select();
		While SampleAvailableCashRegisters.Next() Do
			If SampleAvailableCashRegisters.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters Then
				If ByCashRegisterCompany And Selection.KKMCashRegisterIsRegisteredCompany <> SampleAvailableCashRegisters.Organization Then
					Continue;
				EndIf;
				AvailableCashRegisters.Add(SampleAvailableCashRegisters.CashRegister);
			EndIf;
		EndDo;

	EndIf;
	
EndProcedure

// Creating a cache of data is the main operation parameters when creating a form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form.
Procedure FormWhenCreatedOnServer(Form) Export
	
	GeneratingFiscalChecksServerOverridable.FormWhenCreatedOnServer(Form);
	
EndProcedure

// Creating a cache of data is the main parameters of the operation when reading the form on the server
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form.
Procedure FormWhenReadingOnServer(Form) Export
	
	GeneratingFiscalChecksServerOverridable.FormWhenReadingOnServer(Form);
	
EndProcedure

// Creating a cache of data is the main parameters of the operation when changing the form details
// 
// Parameters:
// 	Form - ClientApplicationForm - The Form of the document consists of:
// 	* Object - DocumentObject - The main props of the form consists of
Procedure FormWhenChangingBankingDetails(Form) Export
	
	GeneratingFiscalChecksServerOverridable.FormWhenChangingBankingDetails(Form);
	
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
	
	GeneratingFiscalChecksServerOverridable.ProcessingReceiptOfFormPreviewingReceipt(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	
EndProcedure

// Returns the status of the document working with acquiring equipment
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document to be checked for the ability to work with acquiring equipment
// Returns:
// 	Boolean - The status of the document with acquiring equipment
Function ItIsSupposedToConnectAcquiringTerminalAccordingToDocument(DocumentRef) Export
	
	Return GeneratingFiscalChecksServerOverridable.ItIsSupposedToConnectAcquiringTerminalAccordingToDocument(DocumentRef);
	
EndFunction

// Defines the date of the document correction receipt operation
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document to be corrected
// Returns:
// 	Date - Date of operation of the correction receipt for the document
Function DateOfAdjustedCalculation(DocumentRef) Export
	
	Return GeneratingFiscalChecksServerOverridable.DateOfAdjustedCalculation(DocumentRef);
	
EndFunction

// Defines the types of fiscal receipts by documents
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Array of EnumRef.TypesOfCREFiscalDocuments - Types of fiscal receipts
Function TypesOfFiscalDocument(DocumentRef, ReceiptPrintingCommandName) Export
	
	Return GeneratingFiscalChecksServerOverridable.TypesOfFiscalDocument(DocumentRef, ReceiptPrintingCommandName);
	
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
	
	Return GeneratingFiscalChecksServerOverridable.CashSettlementTypes(
		DocumentRef,
		ReceiptPrintingCommandName,
		FiscalDocumentType);
	
EndFunction

// Defines the types of correction receipt for the document
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for breaking through the fiscal receipt
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
// Returns:
// 	Array of EnumRef.KindsOfAdjustmentReceipts - Types of correction receipt
Function TypesOfCorrectionReceipt(DocumentRef, ReceiptPrintingCommandName) Export
	
	Return GeneratingFiscalChecksServerOverridable.TypesOfCorrectionReceipt(DocumentRef, ReceiptPrintingCommandName);
	
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
// 	ValueTable - Table of settlement objects with signs of the method of settlement for each object
Function CalculationObjectsWithCalculationMethodAttributes(DocumentRef, PossibleSignsOfCalculationMethodForDocument, AutoCalculationMethodFlags, ShowsCalculationMethod, ARAPObjects, DocumentAmount) Export
	
	Return GeneratingFiscalChecksServerOverridable.CalculationObjectsWithCalculationMethodAttributes(
		DocumentRef,
		PossibleSignsOfCalculationMethodForDocument,
		AutoCalculationMethodFlags,
		ShowsCalculationMethod,
		ARAPObjects,
		DocumentAmount,
		0);
	
EndFunction

// Updates the parameters of the receipt fiscalization operation
// 
// Parameters:
// 	ReceiptOperationParameters - Structure - Data for generating parameters of the receipt fiscalization operation
// 	FDFVersion - String - FFD Version
// Returns:
// 	Structure - Updated parameters of the receipt fiscalization operation
Function UpdateFiscalReceiptParameters(ReceiptOperationParameters, FDFVersion) Export
	
	Return GeneratingFiscalChecksServerOverridable.UpdateFiscalReceiptParameters(ReceiptOperationParameters, FDFVersion);
	
EndFunction

// Generates the text of a non-fiscal receipt based on a template.
// 
// Parameters:
// 	ParametersOfReceiptFiscalizationOperation - Structure - Parameters of the receipt fiscalization operation
// 	FDFVersion - String - Version of the FFD used for generating the receipt text
// Returns:
// 	String - The text of a non-fiscal receipt according to a template
Function UpdateReceiptTemplate(ParametersOfReceiptFiscalizationOperation, FDFVersion) Export
	
	Return GeneratingFiscalChecksServerOverridable.UpdateReceiptTemplate(ParametersOfReceiptFiscalizationOperation, FDFVersion);
	
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
	
	Return GeneratingFiscalChecksServerOverridable.TinMeetsRequirementsOnServer(DocumentRef, TIN, MessageText);
	
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
	
	Return GeneratingFiscalChecksServerOverridable.ConnectedReceiptPrintingEquipment(OperationParametersList);
	
EndFunction

Function BarcodesOfPackagesAreFilled(Object) Export
	
	Return GeneratingFiscalChecksServerOverridable.BarcodesOfPackagesAreFilled(Object);
	
EndFunction

// Checks the data of the wholesale document before performing the fiscal of operation on the Preview check processing form.
// Before verification, the document must be carried out and the form modification flag must be removed.
//
// Parameters:
//  Object - DocumentObject - document form object
//  CheckParameters - Structure of KeyAndValue - Mandatory composition of properties for Transferring data from the client context:
//   *FormName - String
//   *CalculationType - EnumRef.CashSettlementTypes, Undefined - Used for the Debt Offset document, Undefined by default.
//   *ReceiptPrintingCommandName - String - By default, an empty string.
//
// Returns:
//  Boolean - 
//
Function DataVerificationBeforeFiscalTransaction(Object, CheckParameters) Export
	Result = True;
	
	FormName = CheckParameters.FormName;
	CalculationType = CheckParameters.CalculationType;
	ReceiptPrintingCommandName = CheckParameters.ReceiptPrintingCommandName;
	
	MessageText = "";
	If FiscalCheckOnDocumentIsBroken(Object.Ref, CalculationType) Then
		Result = False;
		ErrorText = NStr("ru = 'По документу уже был пробит чек';
						|vi = 'Receipt of the document was printed already';
						|en = 'Receipt of the document was printed already'; fa = 'Receipt of the document was printed already';
						|it = 'In base al documento è stato già registrato lo scontrino';
						|pl = 'W dokumencie został już skasowany paragon';
						|tr = 'Belgeye göre fiş kesildi'");
		Common.MessageToUser(ErrorText);
	ElsIf Not PaymentObjectsEnteredCorrectlyInPaymentDocument(Object.Ref, MessageText, ReceiptPrintingCommandName) Then
		Result = False;
		ErrorText = StrTemplate(NStr("vi = '%1';
									|ru = '%1';
									|en = '%1'; fa = '%1';
									|it = '%1';
									|pl = '%1';
									|tr = '%1'"), MessageText);
		Common.MessageToUser(ErrorText);
	Else
		// We show all the errors found during data verification
		Result = BarcodesOfPackagesAccordingToDocumentsAreFilledIn(Object, FormName) And Result;
		Result = RetailSalesLocalization.VerificationOfDataOfMarkedGoodsDocument(Object) And Result;
	EndIf;
	
	Return Result;
EndFunction

// calls the method of the AR/AP accounting mechanism for distributing settlements with clients
// 
// Parameters:
// 	OperationParametersList - See GeneratingFiscalCheckParametersServer.ParametersOfReceiptFiscalizationOperation
//
Procedure DistributeSettlementsWithClients(OperationParametersList) Export
	
	GeneratingFiscalChecksServerOverridable.DistributeSettlementsWithClients(OperationParametersList);
	
EndProcedure

// Determines whether the document is used to pay with a gift certificate.
// 
// Parameters:
//  DocumentRef - DocumentRef.ARAPSettlement - Debt offset
// 
// Returns:
//  Boolean - Truth, payment by gift certificate
Function PaymentByGiftCard(DocumentRef) Export
	
	Return GeneratingFiscalChecksServerOverridable.PaymentByGiftCard(DocumentRef);
	
EndFunction

#EndRegion

#Region Private

#Region RightsManagement

Function UserHasRightToHoldDocumentInteractively(Document)
	
	Return AccessRight("InteractivePosting", Document.Metadata());
	
EndFunction

Function DocumentPosted(Document)
	
	Return Common.ObjectAttributeValue(Document, "Posted");
	
EndFunction

#EndRegion

Function SettlementObjectsOfPaymentDocument(DocumentPayments, ReceiptPrintingCommandName)
	
	Return GeneratingFiscalChecksServerOverridable.SettlementObjectsOfPaymentDocument(DocumentPayments, ReceiptPrintingCommandName);
	
EndFunction

// Performs verification of the tabular part of the barcodes in the sales documents specified in the decryption of the payment of wholesale payment documents.
//
// Parameters:
//  Object - DocumentObject - document form object
//  FormName - String - The name of the form from whose context the current method was called.
//
// Returns:
//  Boolean - 
//
Function BarcodesOfPackagesAccordingToDocumentsAreFilledIn(Object, FormName)
	
	Result = True;
	
	
	Return Result;
	
EndFunction

#EndRegion

