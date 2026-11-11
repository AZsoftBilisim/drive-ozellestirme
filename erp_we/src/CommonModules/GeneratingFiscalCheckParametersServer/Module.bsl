#Region Public

#Region CreatingGeneralReceiptParameters

// Initializes fiscal receipt parameters
// 
// Parameters:
// 	DocumentRef - DocumentRef - The document that you want to print the check 
// 	Organization - CatalogRef.Companies - The organization for the document
// Returns:
// 	Structure - Description: Fiscal Receipt Parameters
Function ParametersOfReceiptFiscalizationOperation(DocumentRef, Organization, Cashier = Undefined) Export
	
	ParametersOfReceiptFiscalizationOperation = Undefined;
	
	GeneratingFiscalCheckParametersServerOverridable.ParametersOfReceiptFiscalizationOperation(ParametersOfReceiptFiscalizationOperation, DocumentRef, Organization);
	GeneratingFiscalCheckParametersServerOverridable.ParametersOfReceiptFiscalizationOperationForDocument(ParametersOfReceiptFiscalizationOperation, DocumentRef, Organization, Cashier);
	
	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

// Updates the "document Management" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentBasis - DocumentRef - new value for the "document Management" parameter"
Procedure UpdateParametersOfFiscalReceiptDocument(FiscalReceiptParameters, DocumentBasis) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptDocument(FiscalReceiptParameters, DocumentBasis);
	
EndProcedure

// Updates the "single Check" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	FlagSingleReceipt - Boolean - new value for the "single Check" parameter"
Procedure UpdateFiscalReceiptParametersSingleReceipt(FiscalReceiptParameters, FlagSingleReceipt) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateFiscalReceiptParametersSingleReceipt(FiscalReceiptParameters, FlagSingleReceipt);
	
EndProcedure

// Updates the "calculation Type" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationType - EnumRef.CashSettlementTypes - new value for the "calculation Type" parameter"
Procedure FiscalReceiptParametersAndPaymentType(FiscalReceiptParameters, CalculationType) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersAndPaymentType(FiscalReceiptParameters, CalculationType);
	
EndProcedure

// Updates the "serial Number" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	EquipmentSerialNumber - String - new value for the "serial Number" parameter"
Procedure FiscalReceiptParametersAndEquipmentSerialNumber(FiscalReceiptParameters, EquipmentSerialNumber) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersAndEquipmentSerialNumber(FiscalReceiptParameters, EquipmentSerialNumber);
	
EndProcedure

// Updates the recipient's parameters in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	InformationAboutLegalEntity - Structure - Information about the buyer legal entity/sole proprietor
Procedure FiscalReceiptParametersFillInBuyerParameters(FiscalReceiptParameters, InformationAboutLegalEntity) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInBuyerParameters(FiscalReceiptParameters, InformationAboutLegalEntity);
	
EndProcedure

// Updates the "trade Object" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PlaceOfSettlement - Structure - contains the structure of values for a trade item
Procedure ParametersOfFiscalCheckFillInPlaceOfCalculations(FiscalReceiptParameters, PlaceOfSettlement) Export
	
	GeneratingFiscalCheckParametersServerOverridable.ParametersOfFiscalCheckFillInPlaceOfCalculations(FiscalReceiptParameters, PlaceOfSettlement);
	
EndProcedure

// Updates the parameters for sending an electronic receipt in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SendingOption - EnumRef.OptionsOfSendingElectronicReceiptToCustomer - option for sending an electronic receipt (email, sms)
// 	RecipientSContact - String - email or phone number
Procedure FiscalReceiptParametersFillInParametersForSendingElectronicReceipt(FiscalReceiptParameters, SendingOption, RecipientSContact) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInParametersForSendingElectronicReceipt(FiscalReceiptParameters, SendingOption, RecipientSContact);
	
EndProcedure

// Updates personal data in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	ThereIsPersonalData - Boolean - Fiscal receipt parameters contain / do not contain personal data
// 	Recipient - String - Recipient's full name and passport data in the absence of TIN
// 	BeneficiaryTIN - String - The INN of the recipient
Procedure FiscalReceiptParametersFillInPersonalData(FiscalReceiptParameters, ThereIsPersonalData, Recipient, BeneficiaryTIN) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInPersonalData(
		FiscalReceiptParameters,
		ThereIsPersonalData,
		Recipient,
		BeneficiaryTIN);
	
EndProcedure
	
// Updates personal data in the parameters of the fiscal receipt version FFD 1.2
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	ThereIsPersonalData - Boolean - Fiscal receipt parameters contain / do not contain personal data
// 	PersonalDataType - EnumRef.TypesOfPersonalDataOfTheCCT - The type of personal data specified when the check is punched
//	PersonalDataSubject - CatalogRef.Persons - Retail buyer
// 	BuyerInformation - Structure - Information about the buyer
Procedure FiscalReceiptParametersFillInPersonalDataFFD_1_2(FiscalReceiptParameters, ThereIsPersonalData, PersonalDataType, PersonalDataSubject, BuyerInformation) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInPersonalDataFFD_1_2(
		FiscalReceiptParameters,
		ThereIsPersonalData,
		PersonalDataType,
		PersonalDataSubject,
		BuyerInformation);
	
EndProcedure
	

// Updates the "Positioncheck" parameter in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	ReceiptPositions - Array of Structure - the new value of the parameter to "Posizione"
Procedure FiscalReceiptParametersFillInReceiptItems(FiscalReceiptParameters, ReceiptPositions) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInReceiptItems(FiscalReceiptParameters, ReceiptPositions);
	
EndProcedure

// Updates the "payment Table" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	TableOfPayment - Array of Structure - new value for the "payment Table" parameter"
Procedure FiscalReceiptParametersFillInPaymentTable(FiscalReceiptParameters, TableOfPayment) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInPaymentTable(FiscalReceiptParameters, TableOfPayment);
	
EndProcedure

// Updates the correction receipt parameters in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentToBeCorrected - DocumentRef - The basis for entering the receipt printing document
// 	TypeOfCorrection - EnumRef.KindsOfAdjustmentReceipts - the form of a check correction
// 	CorrectionData - Array - Additional correction data
Procedure FiscalReceiptParametersFillInCorrectionParameters(FiscalReceiptParameters, DocumentToBeCorrected, TypeOfCorrection, CorrectionData) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersFillInCorrectionParameters(FiscalReceiptParameters, DocumentToBeCorrected, TypeOfCorrection, CorrectionData);
	
EndProcedure

// Clears the correction receipt parameters in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
Procedure FiscalReceiptParametersDeleteCorrectionParameters(FiscalReceiptParameters) Export
	
	GeneratingFiscalCheckParametersServerOverridable.FiscalReceiptParametersDeleteCorrectionParameters(FiscalReceiptParameters);
	
EndProcedure

// Adds additional data to the parameters of the fiscal receipt when paying with a gift certificate
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	GiftCertificates - ValueTable - List of gift certificates with total data
Procedure AddDataForGiftCertificates(FiscalReceiptParameters, GiftCertificates) Export
	
	GeneratingFiscalCheckParametersServerOverridable.AddDataForGiftCertificates(FiscalReceiptParameters, GiftCertificates);
	
EndProcedure

#EndRegion

#Region FormationOfCashRegisterReceiptParameters

// Updates the sales item data in the receipt parameters
//
// Parameters:
// 	ParametersOfReceiptFiscalizationOperation - Structure - The parameters of the fiscal receipt
//  Organization - CatalogRef.Companies - Link to the organization
// 	RetailFacility - CatalogRef.Warehouses - Link to the warehouse that the CCT is linked to
//  CREEquipment - CatalogRef.Peripherals - Link to KKT
Procedure UpdateFiscalReceiptParametersSettlementLocation(ParametersOfReceiptFiscalizationOperation, Organization, RetailFacility, CREEquipment) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateFiscalReceiptParametersSettlementLocation(
		ParametersOfReceiptFiscalizationOperation, Organization, RetailFacility, CREEquipment);
	
EndProcedure

#EndRegion

#Region FormationOfCashRegisterReceiptPositions

// Calculates and updates the setting position of the check of KKM (Checkm, Checkclosed, Checkmarks)
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentRef - DocumentRef - Link to the KKM receipt
Procedure UpdateParametersOfFiscalReceiptAndCashRegisterReceipt(FiscalReceiptParameters, DocumentRef) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptAndCashRegisterReceipt(FiscalReceiptParameters, DocumentRef);
	
EndProcedure

// Calculates and updates the parameter table check payments KKM (Checkm, Checkclosed, Checkmarks)
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PaymentInformation - Structure - Payment amounts by type of payment
Procedure UpdateFiscalReceiptParametersCashRegisterReceiptPaymentTable(FiscalReceiptParameters, PaymentInformation) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateFiscalReceiptParametersCashRegisterReceiptPaymentTable(FiscalReceiptParameters, PaymentInformation);
	
EndProcedure

// Update the parameters of the fiscal receipt for FSS certificates.
// 
// Parameters:
//  FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
//  PaymentCards_ - ValueTable -  Payment Cards
Procedure UpdateFiscalReceiptParametersFSSCertificates(FiscalReceiptParameters, PaymentCards_) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateFiscalReceiptParametersFSSCertificates(
		FiscalReceiptParameters,
		PaymentCards_);
	
EndProcedure

// Update the parameters of the fiscal receipt for the SBP.
// 
// Parameters:
//  FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
//  SBPPayments - ValueTable -  SBP payments
Procedure UpdateParametersOfSBPFiscalReceipt(FiscalReceiptParameters, SBPPayments) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfSBPFiscalReceipt(
		FiscalReceiptParameters,
		SBPPayments);
	
EndProcedure

#EndRegion

#Region FormationOfSingleCheckPositions

// Calculates and updates the single receipt item parameter
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SingleReceiptDocuments - Array of Structure - Documents included in a single receipt
// 	PrepaymentAmountMan - Number - Prepayment amount
Procedure UpdateParametersOfFiscalReceiptOfUnifiedReceiptItems(FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan = 0) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptOfUnifiedReceiptItems(
		FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan);
	
EndProcedure

// Calculates and updates the parameter of the table of payments one check
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SingleReceiptDocuments - Array of Structure - Documents included in a single receipt
// 	PrepaymentAmountMan - Number - Prepayment amount
Procedure UpdateFiscalReceiptParametersPaymentTableSingleReceipt(FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan = 0) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateFiscalReceiptParametersPaymentTableSingleReceipt(
		FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan);
	
EndProcedure

#EndRegion

#Region FormationOfPositionsOfDeliveryDocument

// Calculates and updates the receipt item parameter for the delivery document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationObjectsWithCalculationMethodAttributes - ValueTable - table of delivery amounts for settlement objects of the document printing receipt with details on the basis of the calculation method
Procedure UpdateParametersOfFiscalReceiptAndReceiptForDeliveryDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptAndReceiptForDeliveryDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes);
	
EndProcedure

// Calculates and updates the check payment table parameter for the delivery document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PaymentStructureOfDeliveryDocument - Structure - Payment amounts by type of payment
Procedure UpdateParametersOfFiscalReceiptPaymentTableForDeliveryDocument(FiscalReceiptParameters, PaymentStructureOfDeliveryDocument) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptPaymentTableForDeliveryDocument(FiscalReceiptParameters, PaymentStructureOfDeliveryDocument);
	
EndProcedure

#EndRegion

#Region FormationOfPositionsOfPaymentDocument

// Calculates and updates the check item parameter for the payment document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationObjectsWithCalculationMethodAttributes - ValueTable - table of delivery amounts for settlement objects of the document printing receipt with details on the basis of the calculation method
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
Procedure UpdateParametersOfFiscalReceiptAndReceiptForPaymentDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes, ReceiptPrintingCommandName) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptAndReceiptForPaymentDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes, ReceiptPrintingCommandName);
	
EndProcedure

// Calculates and updates the check payment table parameter for the payment document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentAmount - Structure - Payment amounts by type of payment
Procedure UpdateParametersOfFiscalReceiptPaymentTableForPaymentDocument(FiscalReceiptParameters, DocumentAmount) Export
	
	GeneratingFiscalCheckParametersServerOverridable.UpdateParametersOfFiscalReceiptPaymentTableForPaymentDocument(FiscalReceiptParameters, DocumentAmount);
	
EndProcedure

#EndRegion

#Region BatchGeneration

// Returns operation parameters for fiscalizing a receipt for a document
//
// Parameters:
// 	DocumentRef - DocumentRef - link to a document that supports fiscalization
// 	CREEquipment - CatalogRef.Peripherals
// 
// Returns:
// 	Structure, Undefined - 
//
Function ParametersOfReceiptFiscalizationOperationBatchMode(DocumentRef, CREEquipment = Undefined) Export
	
	If Not GeneratingFiscalChecksServerCall.AllowedPenetrationOfFiscalChecksOnDocument(DocumentRef) Then
		Return Undefined;
	EndIf;
	
	If GeneratingFiscalChecksServerCall.FiscalCheckOnDocumentIsBroken(DocumentRef) Then
		Return Undefined;
	EndIf; 

	FDFVersion = "";
	If CREEquipment = Undefined Then
		CREEquipment = Catalogs.Peripherals.EmptyRef();
		RetailFacility = Undefined;
	Else 
		RetailFacility = Common.ObjectAttributeValue(DocumentRef, "CashAccount");
		FDFVersion = GeneratingFiscalChecksServerOverridable.FFDHardwareVersion(CREEquipment);
	EndIf;
	
	OperationParametersList = New Structure();
	
	OperationParametersList.Insert("DocumentRef", DocumentRef);
	OperationParametersList.Insert("Currency");
	OperationParametersList.Insert("ARAPCurrency");
	OperationParametersList.Insert("Counterparty");
	OperationParametersList.Insert("Organization");
	OperationParametersList.Insert("Partner");
	OperationParametersList.Insert("DocumentAmount");
	
	FillPropertyValues(OperationParametersList, DocumentRef);
	
	OperationParametersList.Insert("ReceiptPrintingCommandName",			"IssueCashReceipt");
	OperationParametersList.Insert("NameOfHyperlinkDetailsOnForm",	Undefined);
	OperationParametersList.Insert("PaymentCompleted",					Undefined);
	OperationParametersList.Insert("AcquiringTransactionParameters",	Undefined);
	OperationParametersList.Insert("RetailFacility",					RetailFacility);
	
	ReceiptPreviewParameters = GeneratingFiscalChecksServer.ReceiptPreviewParameters(OperationParametersList);
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(CREEquipment);
	
	CashSettlementType = PredefinedValue("Enum.CashSettlementTypes.CashReceipt");
	AutoCalculationMethodFlags = TMCommonUse.ArrayToValueTable(ReceiptPreviewParameters.AutoCalculationMethodFlags);
	
	PossibleSignsOfCalculationMethodForDocument = GeneratingFiscalChecksServer.TypesOfPossibleAttributesOfCalculationMethodForDocument(
		DocumentRef,
		ReceiptPreviewParameters.ObjectsOfCalculationsForDocument,
		CashSettlementType,
		OperationParametersList.DocumentAmount);
	
	CalculationObjectsWithCalculationMethodAttributes = GeneratingFiscalChecksServerOverridable.CalculationObjectsWithCalculationMethodAttributes(
		DocumentRef,
		PossibleSignsOfCalculationMethodForDocument,
		AutoCalculationMethodFlags,
		"<Auto>",
		ReceiptPreviewParameters.ObjectsOfCalculationsForDocument,
		OperationParametersList.DocumentAmount,
		0);
	
	ParametersOfReceiptFiscalizationOperation = ReceiptPreviewParameters.ParametersOfReceiptFiscalizationOperation;
	
	ParametersOfReceiptFiscalizationOperation.Insert("DocumentRef", 			DocumentRef);
	ParametersOfReceiptFiscalizationOperation.Insert("Organization", 				OperationParametersList.Organization);
	ParametersOfReceiptFiscalizationOperation.Insert("Counterparty", 				OperationParametersList.Counterparty);
	ParametersOfReceiptFiscalizationOperation.Insert("DocumentAmount", 			OperationParametersList.DocumentAmount);
	
	If ReceiptPreviewParameters.SingleReceiptDocuments.Count() > 0 Then
		ParametersOfReceiptFiscalizationOperation.Insert("SingleReceipt", 			True);
		ParametersOfReceiptFiscalizationOperation.Insert("SingleReceiptDocuments", 	ReceiptPreviewParameters.SingleReceiptDocuments);
	EndIf; 
	
	If Not GeneratingFiscalChecksServerOverridable.PaymentDocumentWithAbilityToBreakChecks(DocumentRef)
		And ValueIsFilled(StructureRegisterShiftState)
		And StructureRegisterShiftState.Property("Warehouse") Then
		ParametersOfReceiptFiscalizationOperation.Insert("Warehouse", StructureRegisterShiftState.Warehouse);
	Else
		ParametersOfReceiptFiscalizationOperation.Insert("Warehouse", Undefined);
	EndIf;
	
	ParametersOfReceiptFiscalizationOperation.Insert("FiscalDocumentType", PredefinedValue("Enum.TypesOfCREFiscalDocuments.SALESSLIP"));
	ParametersOfReceiptFiscalizationOperation.Insert("CashSettlementType", CashSettlementType);
	ParametersOfReceiptFiscalizationOperation.Insert("TypeOfAdjustmentReceipt", Undefined);
	ParametersOfReceiptFiscalizationOperation.Insert("CREEquipment", CREEquipment);
	ParametersOfReceiptFiscalizationOperation.Insert("EquipmentSerialNumber", CREEquipment.SerialNumber);
	
	ParametersForSendingElectronicReceipt = RetailSales.GetParametersForSendingElectronicReceiptToPartner(OperationParametersList.Partner); 
	ParametersOfReceiptFiscalizationOperation.Insert("OptionOfSendingElectronicReceipt", ParametersForSendingElectronicReceipt.OptionOfSendingElectronicReceipt);
	ParametersOfReceiptFiscalizationOperation.Insert("ContactOfRecipientOfElectronicCheck", ParametersForSendingElectronicReceipt.ContactOfRecipientOfElectronicCheck);
	
	ParametersOfReceiptFiscalizationOperation.Insert("CalculationObjectsWithCalculationMethodAttributes", CalculationObjectsWithCalculationMethodAttributes);
	ParametersOfReceiptFiscalizationOperation.Insert("AutoCalculationMethodFlags", AutoCalculationMethodFlags);
	
	ParametersOfReceiptFiscalizationOperation.Insert("TheOperationInvolvesEnteringTheBuyerSPersonalData", False);
	
	ParametersOfReceiptFiscalizationOperation.Insert("ReceiptPrintingCommandName", OperationParametersList.ReceiptPrintingCommandName);
	
	ParametersOfReceiptFiscalizationOperation = GeneratingFiscalChecksServer.UpdateFiscalReceiptParameters(ParametersOfReceiptFiscalizationOperation, FDFVersion);

	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

#EndRegion 

// Returns a table of products to fill in line items in the receipt parameters
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for receiving product items
// Returns:
// 	ValueTable - A table with commodity items with quantitative and summary indicators
Function ProductItemsByDocument(DocumentRef) Export
	
	Return GeneratingFiscalCheckParametersServerOverridable.ProductItemsByDocument(DocumentRef);
	
EndFunction

#EndRegion

