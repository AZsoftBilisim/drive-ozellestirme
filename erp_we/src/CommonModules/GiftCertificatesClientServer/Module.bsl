
#Region Public

// Calculates the type of operation for gift certificates, depending on the type of document.
// 
// Parameters:
//  Object - DocumentObject, FormDataStructure, Structure - The Cur document that has the link property..
// Returns:
//  Number - 1 - Sale
// 			2 - Refund
// 			3 - Payment
// 			4 - Cancellation.
//
Function TypeOfOperationForGiftCertificates(Object) Export
	TypeOfOperationForGiftCertificates = 0;
	ObjectReferenceType = TypeOf(Object.Ref);
	TypeOfOperationOfDebtOffsetting = Undefined;		
	If ObjectReferenceType = Type("DocumentRef.ARAPSettlement") Then
		// Checking for a call from Processing.Payment set-off helpers.The form.Form
		If CommonClientServer.HasAttributeOrObjectProperty(Object, "OperationKind") Then
			TypeOfOperationOfDebtOffsetting = Object.OperationKind;
		EndIf;
	EndIf;	
	If ObjectReferenceType = Type("DocumentRef.GiftCertificateSale")
		Or ObjectReferenceType = Type("DocumentRef.CashAccountReceiptNote")
		Or ObjectReferenceType = Type("DocumentRef.BankAccountReceiptNote")
		Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction") 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer")
		Or ObjectReferenceType = Type("DocumentRef.ARAPSettlement") 
			And TypeOfOperationOfDebtOffsetting = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties") Then
		TypeOfOperationForGiftCertificates = 1;
	ElsIf ObjectReferenceType = Type("DocumentRef.OBEntry")
		Or ObjectReferenceType = Type("DocumentRef.OBEntryARAP")
		Or ObjectReferenceType = Type("DocumentRef.OBEntrySalesForPastPeriods") Then
		TypeOfOperationForGiftCertificates = 1;
	ElsIf ObjectReferenceType = Type("DocumentRef.ReturnOfGiftCards")
		Or ObjectReferenceType = Type("DocumentRef.CashVoucher")
		Or ObjectReferenceType = Type("DocumentRef.BankAccountIssue")
		Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction") 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer")
		Or ObjectReferenceType = Type("DocumentRef.PaymentRequest") Then
		TypeOfOperationForGiftCertificates = 2;
	ElsIf ObjectReferenceType = Type("DocumentRef.CashRegisterReceipt") 
		Or ObjectReferenceType = Type("DocumentRef.CustomerInvoice")
		Or ObjectReferenceType = Type("DocumentRef.CustomerInvoiceServices")
		Or ObjectReferenceType = Type("DocumentRef.ARAPSettlement")
		Or ObjectReferenceType = Type("DocumentRef.RetailSalesReport") Then
		TypeOfOperationForGiftCertificates = 3;
	ElsIf ObjectReferenceType = Type("DocumentRef.GiftCertificateCancellation") Then
		TypeOfOperationForGiftCertificates = 4;
	EndIf;
	Return TypeOfOperationForGiftCertificates;
EndFunction

// Calculates an array of valid Statuses for gift certificates, depending on the type of document.
// 
// Parameters:
//  Object - DocumentObject, FormDataStructure, Structure - The Cur document that has the link property..
// Returns:
//  Array of EnumRef.GiftCertificateStatuses
//
Function AcceptableStatusesOfGiftCertificates(Object) Export
	AcceptableStatuses = New Array;
	
	ObjectReferenceType = TypeOf(Object.Ref);
	If ObjectReferenceType = Type("DocumentRef.GiftCertificateSale")
		Or ObjectReferenceType = Type("DocumentRef.CashAccountReceiptNote")
		Or ObjectReferenceType = Type("DocumentRef.BankAccountReceiptNote")
		Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction") 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.CashReceiptFromCustomer")
		Or ObjectReferenceType = Type("DocumentRef.ARAPSettlement") 
			And Object.OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties") Then
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.NotActivated"));
	ElsIf ObjectReferenceType = Type("DocumentRef.OBEntry")
		Or ObjectReferenceType = Type("DocumentRef.OBEntryARAP")
		Or ObjectReferenceType = Type("DocumentRef.OBEntrySalesForPastPeriods") Then
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.NotActivated"));
	ElsIf ObjectReferenceType = Type("DocumentRef.ReturnOfGiftCards")
		Or ObjectReferenceType = Type("DocumentRef.CashVoucher")
		Or ObjectReferenceType = Type("DocumentRef.BankAccountIssue")
		Or ObjectReferenceType = Type("DocumentRef.PaymentCardTransaction") 
			And Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.RefundToCustomer")
		Or ObjectReferenceType = Type("DocumentRef.PaymentRequest") Then
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
	ElsIf ObjectReferenceType = Type("DocumentRef.CashRegisterReceipt") 
		Or ObjectReferenceType = Type("DocumentRef.CustomerInvoice")
		Or ObjectReferenceType = Type("DocumentRef.CustomerInvoiceServices")
		Or ObjectReferenceType = Type("DocumentRef.ARAPSettlement")
		Or ObjectReferenceType = Type("DocumentRef.RetailSalesReport") Then
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
	ElsIf ObjectReferenceType = Type("DocumentRef.GiftCertificateCancellation") Then
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.Returned__"));
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
		AcceptableStatuses.Add(PredefinedValue("Enum.GiftCertificateStatuses.FullyRepaid"));
	EndIf;
	
	Return AcceptableStatuses;
EndFunction

// The data required to calculate the Status of the certificate of the new sample.
//
// Returns:
//	 Structure:
//  	* Balance - Number -
//  	* Nominal - Number -
//  	* PartialPayment - Boolean -
//  	* ActivationStatus - Boolean -
//  	* RefundIssued - Boolean -
//  	* Canceled_ - Boolean - 
//
Function DataForCalculatingStatus() Export
	Data = New Structure;
	Data.Insert("Balance", 0);
	Data.Insert("Nominal", 0);
	Data.Insert("PartialPayment", False);
	Data.Insert("ActivationStatus", False);
	Data.Insert("RefundIssued", False);
	Data.Insert("Canceled_", False);
	Return Data;
EndFunction

// Based on the transmitted data, it calculates the Status value of the gift certificate 
// in the form of which the sign Accounting for gift certifications2_5 is set.
// 
// Parameters:
//  Data - See DataForCalculatingStatus
// 
// Returns:
//	EnumRef.GiftCertificateStatuses
Function CalculateStatusOfGiftCertificate2_5(Data) Export
	
	Status = PredefinedValue("Enum.GiftCertificateStatuses.NotActivated");
	If Data.ActivationStatus Then
		Status = PredefinedValue("Enum.GiftCertificateStatuses.Activated");
		If Data.Canceled_ Then
			Status = PredefinedValue("Enum.GiftCertificateStatuses.Canceled_");
		ElsIf Data.RefundIssued Then
			Status = PredefinedValue("Enum.GiftCertificateStatuses.Returned__");
		ElsIf Data.Balance <= 0 Or
				Data.PartialPayment = False And Data.Balance < Data.Nominal Then
			Status = PredefinedValue("Enum.GiftCertificateStatuses.FullyRepaid");
		ElsIf Data.Balance < Data.Nominal Then
			Status = PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid");
		EndIf;
	EndIf;
	
	Return Status;
EndFunction

// The function determines the need for special processing of input data (in the case of using a magnetic card reader).
//
// Parameters:
//  CardCode - String, Array of String - Received gift certificate code.
//  CodeType - EnumRef.CardCodeTypes - Code type of the received gift certificate.
//
// Returns:
//  Boolean - 
//
Function DataPreprocessingIsRequired(CardCode, CodeType) Export
	Preprocessing = False;
	If  CodeType = PredefinedValue("Enum.CardCodeTypes.MagneticCode")
		And TypeOf(CardCode) = Type("Array") Then
		Preprocessing = True;
	EndIf;
	Return Preprocessing;
EndFunction

// According to the transmitted data about the gift certificate, it determines the possibility of making a refund of this gift certificate.
//
// Parameters:
//  GiftCertificateDetails - See GiftCertificatesServerCall.InitializeGiftCertificateDescription 
//  CurrentSessionDate - Date - The date on which the expiration date of the gift certificate is checked.
// Returns:
//  Boolean - 
//
Function GiftCertificateCanBeReturned(GiftCertificateDetails, CurrentSessionDate) Export
	Result = False;

	If Not GiftCertificateDetails.GiftCardAccounting25
			And GiftCertificateDetails.StatusFromHistoryOfGiftCertificates = PredefinedValue("Enum.GiftCertificateStatuses.Activated") 
		Or
			(GiftCertificateDetails.GiftCardAccounting25
			And GiftCertificateDetails.ActivationStatus
			And GiftCertificateDetails.ValidityEndDate >= CurrentSessionDate
			And (GiftCertificateDetails.PartialPayment And GiftCertificateDetails.Balance > 0
				Or Not GiftCertificateDetails.PartialPayment And GiftCertificateDetails.Balance = GiftCertificateDetails.Nominal)) Then
		Result = True;
	EndIf;

	Return Result;
EndFunction

#EndRegion
