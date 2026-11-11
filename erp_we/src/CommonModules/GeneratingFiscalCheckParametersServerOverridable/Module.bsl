
#Region Public

#Region CreatingGeneralReceiptParameters

// Initializes fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentRef - DocumentRef - The document that you want to print the check 
// 	Organization - CatalogRef.Companies - The organization for the document
Procedure ParametersOfReceiptFiscalizationOperation(FiscalReceiptParameters, DocumentRef, Organization) Export
	
	
EndProcedure

// The main parameters of the fiscal receipt are filled in
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentRef - DocumentRef - The document which formed the parameters of a fiscal receipt
// 	Organization - CatalogRef.Companies - Organization of the document used for generating fiscal receipt parameters
// 	Cashier - CatalogRef.Users, Undefined - The user who fiscalizes the document
Procedure ParametersOfReceiptFiscalizationOperationForDocument(FiscalReceiptParameters, DocumentRef, Organization, Cashier = Undefined) Export
	
	
EndProcedure

// Updates the "document Management" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentBasis - DocumentRef - new value for the "document Management" parameter"
Procedure UpdateParametersOfFiscalReceiptDocument(FiscalReceiptParameters, DocumentBasis) Export
EndProcedure

// Updates the "single Check" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	FlagSingleReceipt - Boolean - new value for the "single Check" parameter"
Procedure UpdateFiscalReceiptParametersSingleReceipt(FiscalReceiptParameters, FlagSingleReceipt) Export
EndProcedure

// Updates the "calculation Type" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationType - EnumRef.CashSettlementTypes - new value for the "calculation Type" parameter"
Procedure FiscalReceiptParametersAndPaymentType(FiscalReceiptParameters, CalculationType) Export
EndProcedure

// Updates the "serial Number" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	EquipmentSerialNumber - String - new value for the "serial Number" parameter"
Procedure FiscalReceiptParametersAndEquipmentSerialNumber(FiscalReceiptParameters, EquipmentSerialNumber) Export
EndProcedure

// Updates the recipient's parameters in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	InformationAboutLegalEntity - Structure - Information about the buyer legal entity/sole proprietor
Procedure FiscalReceiptParametersFillInBuyerParameters(FiscalReceiptParameters, InformationAboutLegalEntity) Export
EndProcedure

// Updates the parameter "PaymenTInternetMagazine" in the parameters of the fiscal receipt 
// 
// Parameters:
//  FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
//  OnlineStoreAddress - String - The address of the calculation website
Procedure FiscalReceiptParametersFillInOnlineCalculations(FiscalReceiptParameters, OnlineStoreAddress) Export
	

EndProcedure

// Updates the "trade Object" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PlaceOfSettlement - Structure - contains the structure of values for a trade item
Procedure ParametersOfFiscalCheckFillInPlaceOfCalculations(FiscalReceiptParameters, PlaceOfSettlement) Export
EndProcedure

// Updates the parameters for sending an electronic receipt in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SendingOption - EnumRef.OptionsOfSendingElectronicReceiptToCustomer - option for sending an electronic receipt (email, sms)
// 	RecipientSContact - String - email or phone number
Procedure FiscalReceiptParametersFillInParametersForSendingElectronicReceipt(FiscalReceiptParameters, SendingOption, RecipientSContact) Export
EndProcedure

// Updates personal data in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	ThereIsPersonalData - Boolean - Fiscal receipt parameters contain / do not contain personal data
// 	Recipient - String - Recipient's full name and passport data in the absence of TIN
// 	BeneficiaryTIN - String - The INN of the recipient
Procedure FiscalReceiptParametersFillInPersonalData(FiscalReceiptParameters, ThereIsPersonalData, Recipient, BeneficiaryTIN) Export
	
	FiscalReceiptParameters.Insert("ThereIsPersonalData", ThereIsPersonalData);
	FiscalReceiptParameters.Insert("Recipient"   , TrimAll(Recipient));
	FiscalReceiptParameters.Insert("BeneficiaryTIN", TrimAll(BeneficiaryTIN));
	
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
	
	FiscalReceiptParameters.Insert("ThereIsPersonalData", ThereIsPersonalData);
	FiscalReceiptParameters.Insert("BuyerInformation", BuyerInformation);
	FiscalReceiptParameters.Insert("PersonalDataType", PersonalDataType);
	FiscalReceiptParameters.Insert("PersonalDataSubject", PersonalDataSubject);
	
EndProcedure

// Updates the correction receipt parameters in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentToBeCorrected - DocumentRef - The basis for entering the receipt printing document
// 	TypeOfCorrection - EnumRef.KindsOfAdjustmentReceipts - the form of a check correction
// 	CorrectionData - Array - Additional correction data
Procedure FiscalReceiptParametersFillInCorrectionParameters(FiscalReceiptParameters, DocumentToBeCorrected, TypeOfCorrection, CorrectionData) Export
EndProcedure

// Clears the correction receipt parameters in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
Procedure FiscalReceiptParametersDeleteCorrectionParameters(FiscalReceiptParameters) Export
EndProcedure

// Updates the "Positioncheck" parameter in the fiscal receipt parameters
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	ReceiptPositions - Array - the new value of the parameter to "Posizione"
Procedure FiscalReceiptParametersFillInReceiptItems(FiscalReceiptParameters, ReceiptPositions) Export
EndProcedure

// Updates the "payment Table" parameter in the fiscal receipt parameters 
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	TableOfPayment - Array - new value for the "payment Table" parameter"
Procedure FiscalReceiptParametersFillInPaymentTable(FiscalReceiptParameters, TableOfPayment) Export
EndProcedure

// Adds additional data to the parameters of the fiscal receipt when paying with a gift certificate
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - Parameters of the fiscal receipt, consists of:
// 	* ReceiptPositions - Array - An array of structures the position of the check
// 	* TableOfPayment - Array - An array of structures of wage types with amounts
// 	GiftCertificates - ValueTable - List of gift certificates with total data
Procedure AddDataForGiftCertificates(FiscalReceiptParameters, GiftCertificates) Export
EndProcedure

// Returns a table of products to fill in line items in the receipt parameters
// 
// Parameters:
// 	DocumentRef - DocumentRef - Document for receiving product items
// Returns:
//  Undefined, ValueTable - A table with commodity items with quantitative and summary indicators:
//  * NomenclatureName - String -
//  * CharacteristicName - String -
//  * Package - CatalogRef.PackagesAndUnitsOfMeasure - 
//  * PackagingName_ - String -
//  * Count - Number - 
//  * Price - Number -
//  * Sum - Number - 
//  * VATRate - CatalogRef.VATRates -
//  * VATAmount - Number -
// 
Function ProductItemsByDocument(DocumentRef) Export
	
	Return Undefined;
	
EndFunction

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
		
	PlaceOfSettlement = New Structure("RetailFacility, PlaceOfSettlement, SettlementAddress", "", "", "");
	
	If ValueIsFilled(RetailFacility) Then
		PlaceOfSettlement.RetailFacility = RetailFacility;
	Else
		PlaceOfSettlement.RetailFacility = TMPeripheralsServerCall.CashRegisterRelatedToEquipment(CREEquipment);
	EndIf;
	
	DescriptionOfCashShift = RetailSales.GetCashShiftState(CREEquipment);
	
	If DescriptionOfCashShift.ShiftIsOpened
		And DescriptionOfCashShift.ItinerantTrade
		And ValueIsFilled(DescriptionOfCashShift.PlaceOfSettlement) Then
		PlaceOfSettlement.PlaceOfSettlement = DescriptionOfCashShift.PlaceOfSettlement;
	Else
		TradeObjectPlaceOfSettlement = RetailSales.PlaceOfKKTCalculations(CREEquipment);
		If ValueIsFilled(TradeObjectPlaceOfSettlement) Then
			PlaceOfSettlement.PlaceOfSettlement = TradeObjectPlaceOfSettlement;
		Else
			PlaceOfSettlement.PlaceOfSettlement = RetailSales.KktShoppingFacility(Organization, RetailFacility);
		EndIf;
	EndIf;

	If DescriptionOfCashShift.ShiftIsOpened
		And DescriptionOfCashShift.ItinerantTrade 
		And ValueIsFilled(DescriptionOfCashShift.SettlementAddress) Then
		PlaceOfSettlement.SettlementAddress = DescriptionOfCashShift.SettlementAddress;
	Else
		PlaceOfSettlement.SettlementAddress = RetailSales.AddressOfKKTCalculations(CREEquipment, Organization);
	EndIf;

	ParametersOfFiscalCheckFillInPlaceOfCalculations(ParametersOfReceiptFiscalizationOperation, PlaceOfSettlement);
	
EndProcedure

#EndRegion

#Region FormationOfCashRegisterReceiptPositions

// Calculates and updates the setting position of the check of KKM (Checkm, Checkclosed, Checkmarks)
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentRef - DocumentRef - Link to the KKM receipt
Procedure UpdateParametersOfFiscalReceiptAndCashRegisterReceipt(FiscalReceiptParameters, DocumentRef) Export
EndProcedure

// Calculates and updates the parameter table check payments KKM (Checkm, Checkclosed, Checkmarks)
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PaymentInformation - Structure - Payment amounts by type of payment
Procedure UpdateFiscalReceiptParametersCashRegisterReceiptPaymentTable(FiscalReceiptParameters, PaymentInformation) Export
EndProcedure

// Update the parameters of the fiscal receipt for FSS certificates.
// 
// Parameters:
//  FiscalReceiptParameters - See PeripheralsReceiptPrintersClientServer.ParametersOfReceiptFiscalizationOperation
//  PaymentCards_ - ValueTable -  Payment Cards
//
Procedure UpdateFiscalReceiptParametersFSSCertificates(FiscalReceiptParameters, PaymentCards_) Export
EndProcedure

// Update the parameters of the fiscal receipt for the SBP.
// 
// Parameters:
//  FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
//  SBPPayments - ValueTable -  SBP payments
Procedure UpdateParametersOfSBPFiscalReceipt(FiscalReceiptParameters, SBPPayments) Export
EndProcedure

#EndRegion

#Region FormationOfSingleCheckPositions

// Calculates and updates the single receipt item parameter
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SingleReceiptDocuments - Array of Structure - Documents included in a single receipt
// 	PrepaymentAmountMan - Number - Prepayment amount
//
Procedure UpdateParametersOfFiscalReceiptOfUnifiedReceiptItems(FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan = 0) Export
EndProcedure

// Calculates and updates the parameter of the table of payments one check
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	SingleReceiptDocuments - Array of Structure - Documents included in a single receipt
// 	PrepaymentAmountMan - Number - Prepayment amount
//
Procedure UpdateFiscalReceiptParametersPaymentTableSingleReceipt(FiscalReceiptParameters, SingleReceiptDocuments, PrepaymentAmountMan = 0) Export
EndProcedure

#EndRegion

#Region FormationOfPositionsOfDeliveryDocument

// Calculates and updates the receipt item parameter for the delivery document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationObjectsWithCalculationMethodAttributes - ValueTable - table of delivery amounts for settlement objects
// 		of the receipt printing document with details based on the calculation method.
Procedure UpdateParametersOfFiscalReceiptAndReceiptForDeliveryDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes) Export
EndProcedure

// Calculates and updates the check payment table parameter for the delivery document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	PaymentStructureOfDeliveryDocument - Structure - Payment amounts by type of payment
Procedure UpdateParametersOfFiscalReceiptPaymentTableForDeliveryDocument(FiscalReceiptParameters, PaymentStructureOfDeliveryDocument) Export
EndProcedure

#EndRegion

#Region FormationOfPositionsOfPaymentDocument

// Calculates and updates the receipt item parameter for the payment document
// Advances on gift certificates are detailed in the receipt before the settlement object.
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	CalculationObjectsWithCalculationMethodAttributes - ValueTable - table of delivery amounts for settlement objects
// 		of the receipt printing document with details based on the calculation method.
// 	ReceiptPrintingCommandName - String - Name of the check breakout command
Procedure UpdateParametersOfFiscalReceiptAndReceiptForPaymentDocument(FiscalReceiptParameters, CalculationObjectsWithCalculationMethodAttributes, ReceiptPrintingCommandName) Export
EndProcedure

// Calculates and updates the check payment table parameter for the payment document
// 
// Parameters:
// 	FiscalReceiptParameters - Structure - The parameters of the fiscal receipt
// 	DocumentAmount - Structure - Payment amounts by type of payment
Procedure UpdateParametersOfFiscalReceiptPaymentTableForPaymentDocument(FiscalReceiptParameters, DocumentAmount) Export
EndProcedure

#EndRegion

#EndRegion

#Region Private


#EndRegion
