#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	Author = Users.CurrentUser();
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
	InitializeDocument(FillingData);
	
	If Not ValueIsFilled(EmployeeResponsible) Then
		EmployeeResponsible = Users.CurrentUser();
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	// We will clear the details of the document that are not used for the business operation.
	ArrayOfAllProps = New Array;
	ArrayOfOperationDetails = New Array;
	Documents.PlannedCashReceipt.FillInNamesOfBusinessTransactionDetails(
		PaymentMethod, ArrayOfAllProps, ArrayOfOperationDetails);
	CashServer.ClearUnusedProps(
		ThisObject, ArrayOfAllProps, ArrayOfOperationDetails);
		
	If PaymentMethod = Enums.PaymentForms.BankAccountPayment And ValueIsFilled(BankAccount) Then
		CashAccountBankAccount = BankAccount;
	ElsIf PaymentMethod = Enums.PaymentForms.CashAccountPayment_ And ValueIsFilled(CashAccount) Then
		CashAccountBankAccount = CashAccount;
	Else
		CashAccountBankAccount = Undefined;
	EndIf;
	
	PaymentDate = Date;
	
	PreviousDate = Common.ObjectAttributeValue(Ref, "Date");
	If ValueIsFilled(PreviousDate) And PreviousDate <> Date Then
		AdditionalProperties.Insert("PreviousDate", BegOfDay(PreviousDate));
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	SettlementDates_ = New Array;
	SettlementDates_.Add(BegOfDay(Date));
	If AdditionalProperties.Property("PreviousDate") Then
		SettlementDates_.Add(AdditionalProperties.PreviousDate);
	EndIf;
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForExpectedCashReceipts(SettlementDates_);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	SettlementDates_ = New Array;
	SettlementDates_.Add(BegOfDay(Date));
	If AdditionalProperties.Property("PreviousDate") Then
		SettlementDates_.Add(AdditionalProperties.PreviousDate);
	EndIf;
	
	InvalidPaymentDocuments = New Array;
	InvalidPaymentDocuments.Add(Ref);
	
	InformationRegisters.ScheduleOfPayments.CalculatePaymentScheduleForExpectedCashReceipts(
		SettlementDates_, InvalidPaymentDocuments);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible = Users.CurrentUser();
	Author = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillingData = Undefined)
	
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	EndIf;
	
	If ValueIsFilled(Organization) Then
		CashAccount = Catalogs.CashAccounts.GetCheckoutByDefault(Organization, Currency);
		ParametersStructure = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersStructure.Currency = Currency;
		BankAccount = Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersStructure);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf
