#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
// 		NewStatus - String - Name of the status that will be set for orders
// 		AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
// 		Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	Status = Enums.CashTransferOrderStatuses[NewStatus];
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
		
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("Organization") Then
			Organization = FillingData.Organization;
		EndIf;
		If FillingData.Property("Currency") Then
			Currency = FillingData.Currency;
		EndIf;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	AdditionalProperties.Insert("NeedToFillInCashRegisterWhenUsingMultipleCashRegistersIsFalse", False);
	AdditionalProperties.Insert("NeedToFillOutAccountWhenFOUseMultipleAccountsIsFalse", False);
	
	InitializeDocument(FillingData);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.CashTransferOrderStatuses.NotApproved;
	PaymentDate = Date(1, 1, 1);
	WhoDecided = Undefined;
	Author = Users.CurrentUser();
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If (Status = Enums.CashTransferOrderStatuses.AmountDue
		Or Status = Enums.CashTransferOrderStatuses.Approved)
		And ValueIsFilled(PaymentDate)
		And PaymentDate < BegOfDay(Date) Then
		
		ErrorText = NStr("vi = 'Ngày thanh toán không thể nhỏ hơn ngày chứng từ';
						|ru = 'Дата платежа не может быть меньше даты документа';
						|en = 'Payment date cannot be earlier than the document date'; fa = 'Payment date cannot be earlier than the document date';
						|it = 'La data del pagamento non può essere antecedente alla data del documento';
						|pl = 'Data płatności nie może być mniejsza niż data dokumentu';
						|tr = 'Ödeme tarihi belgenin tarihinden daha önce olamaz'");
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"PaymentDate",,
			Cancel);
	EndIf;
	
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	NotCheckedAttributeArray = New Array;
	
	Documents.CashTransferReferenceOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	TMCommonUseClientServer.FillInArrayOfUnverifiableBankingDetails(
		ArrayOfAllProps,
		ArrayOfOperationDetails,
		NotCheckedAttributeArray);
		
	CashServer.CheckRecipientSCashRegister(ThisObject, Cancel);
	CashServer.CheckRecipientSBankAccount(ThisObject, Cancel);
	
	If Status = Enums.CashTransferOrderStatuses.Approved Then
		
		ApprovalRight = UserRightsCached.ApproveCashTransferOrders();
		If Not ApprovalRight Then
			ErrorText = NStr("vi = 'Bạn không có quyền đồng ý về các lệnh chuyển tiền mặt.';
							|ru = 'У вас нет права согласования распоряжений на перемещение денежных средств.';
							|en = 'You are not authorized to approve cash transfer orders.'; fa = 'You are not authorized to approve cash transfer orders.';
							|it = 'Non vi sono diritti di concordare le disposizioni per il trasferimento dei mezzi finanziari.';
							|pl = 'Nie masz uprawnień do uzgodnienia zamówień w sprawie poleceń przelewu.';
							|tr = 'Nakit transferine ilişkin emirler üzerinde anlaşmaya yetkiniz yoktur.'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,,,
				Cancel);
		EndIf;
		
	ElsIf Status = Enums.CashTransferOrderStatuses.AmountDue Then
		
		ConfirmationRight = UserRightsCached.ApprovalOfCashTransferReferencesForPayment();
		If Not ConfirmationRight Then
			ErrorText = NStr("vi = 'Bạn không có quyền phê duyệt thanh toán đối với lệnh chuyển tiền.';
							|ru = 'У вас нет права утверждения к оплате распоряжений на перемещение денежных средств.';
							|en = 'You are not authorized to confirm payments upon cash transfer orders.'; fa = 'You are not authorized to confirm payments upon cash transfer orders.';
							|it = 'Non vi sono diritti di approvare al pagamento le disposizioni di trasferimento dei mezzi finanziari.';
							|pl = 'Nie masz uprawnień do zatwierdzania zamówień w sprawie poleceń przelewu.';
							|tr = 'Ödenecek nakit transfer emirlerini onaylama yetkiniz yoktur.'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject,,,
				Cancel);
		EndIf;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	CashTransferReferenceOrderLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
	If WriteMode = DocumentWriteMode.Posting Then
		If Status = Enums.CashTransferOrderStatuses.Approved Then
			If WhoDecided <> Users.CurrentUser() Then
				WhoDecided = Users.CurrentUser();
			EndIf;
		ElsIf Status = Enums.CashTransferOrderStatuses.AmountDue Then
			If Not ValueIsFilled(WhoDecided) Then
				WhoDecided = Users.CurrentUser();
			EndIf;
		EndIf;
	EndIf;
	
	CashFlowItem = Catalogs.CashFlowReportItems.PredefinedCFItem(BusinessOperation, Currency);
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.CashTransferReferenceOrder.FillInNamesOfBusinessTransactionDetails(
		BusinessOperation,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject,
		ArrayOfAllProps,
		ArrayOfOperationDetails);
		
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure InitializeDocument(FillingData = Undefined)
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;

	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If ValueIsFilled(Organization) Then
		CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Organization, Currency);
		CashAccountRecipient = CashAccount;
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.Currency = Currency;
		BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount);
		BankAccountBeneficiary = BankAccount;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
