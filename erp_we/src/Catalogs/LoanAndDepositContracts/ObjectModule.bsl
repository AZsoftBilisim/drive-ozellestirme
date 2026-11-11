#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.Partners") Then
		
		FillInBasedOnPartner(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		FillInByPicking(FillingData);
		
		FillInCounterpartySDefaultBankAccount(FillingData);
		FillInOrganizationSDefaultBankAccount(FillingData);
		
	EndIf;
	
	InitializeCatalog(FillingData);

	If FillingData = Undefined Then
		
		FillingData = New Structure;

		CatalogAttributes = Metadata.Catalogs.LoanAndDepositContracts.Attributes;
		ParametersForFillingInBankingDetails = Catalogs.LoanAndDepositContracts.ParametersOfDetailsToFillInBasedOnStatistics();
		For Each StatisticsCollectionSection In StrSplit(ParametersForFillingInBankingDetails.StatisticsCollectionSections.UseAlways, ",", False) Do
			AttributeName = TrimAll(StatisticsCollectionSection);
			ThisObject[AttributeName] = CatalogAttributes[AttributeName].FillValue;
		EndDo;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		BankAccount = Catalogs.CompaniesBankAccounts.EmptyRef();
		CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.EmptyRef();
		InterestBankAccount = CounterpartyBankAccount;
		BankAccountOfFee = CounterpartyBankAccount;
	Else
		CashAccount = Catalogs.CashAccounts.EmptyRef();
	EndIf;
	
	If FeeType = Enums.LoanAndDepositFeeTypes.None Then
		CashFlowItemOfFeePayment = Catalogs.CashFlowReportItems.EmptyRef();
		If ContractKind = Enums.ContractKindsOfFinancialInstruments.LoanOrBorrowing Then
			IncomeExpenseItemForFeeAccruals = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		Else
			IncomeExpenseItemForFeeAccruals = ChartsOfCharacteristicTypes.IncomeItems.EmptyRef();
		EndIf;
	EndIf;
	
	Approved = (Status = Enums.CounterpartyContractStatuses.Valid
		Or Status = Enums.CounterpartyContractStatuses.Closed);
	LoanAndDepositContractsLocalization.BeforeWrite(Cancel, ThisObject);
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.CounterpartyContractStatuses.NotApproved;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var Errors;
	
	NotCheckedAttributeArray = New Array;
	If PaymentMethod = Enums.PaymentForms.CashAccountPayment_ Then
		NotCheckedAttributeArray.Add("BankAccount");
		NotCheckedAttributeArray.Add("CounterpartyBankAccount");
	Else
		NotCheckedAttributeArray.Add("CashAccount");
	EndIf;

	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	LoanAndDepositContractsLocalization.FillCheckProcessing(Cancel, CheckedAttributes, NotCheckedAttributeArray, ThisObject);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	
EndProcedure

// The procedure fills in the directory details with the "default" values.
//
Procedure InitializeCatalog(FillingData = Undefined) Export
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			BankAccount);
	Else
		BankAccount = FillingData.BankAccount;
	EndIf;
	
	If ValueIsFilled(BankAccount) Then
		ARAPCurrency = Common.ObjectAttributeValue(BankAccount, "CashCurrency");
	Else
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ARAPCurrency") Then
			If Not ValueIsFilled(ARAPCurrency) Then
				ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnPartner(Val Partner, FillingData)
	
	CheckPossibilityOfEnteringBasedOnPartner(Partner);
	
	FillingData = New Structure;
	
	FillingData.Insert("Partner", Partner);
	FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner));
	
	FillInCounterpartySDefaultBankAccount(FillingData);
	
EndProcedure

Procedure FillInByPicking(Val FillingData)
	
	If FillingData.Property("Partner") Then
		FillingData.Insert("Partner", FillingData.Partner);
		
	ElsIf FillingData.Property("Counterparty") Then
		Partner = Common.ObjectAttributeValue(FillingData.Counterparty, "Partner");
		FillingData.Insert("Partner", Partner);
		
	EndIf;
	
	If FillingData.Property("Partner") Then
		
		CheckPossibilityOfEnteringBasedOnPartner(FillingData.Partner);
		If Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
			FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FillingData.Partner));
		EndIf;
		If Not (FillingData.Property("ContactPerson") And ValueIsFilled(FillingData.ContactPerson)) Then
			FillingData.Insert("ContactPerson", PartnersAndCounterparties.GetDefaultPartnerContactPerson(FillingData.Partner));
		EndIf;
	EndIf;
	
EndProcedure

Procedure CheckPossibilityOfEnteringBasedOnPartner(Partner)
	
	If Not ValueIsFilled(Partner) Then
		Return;
	EndIf;
	
	OtherRelations = Common.ObjectAttributeValue(Partner, "OtherRelations");
	
	If Not OtherRelations Then
		
		ErrorText = NStr("vi = 'Không cho phép mối quan hệ khác với bạn hàng ""%Partner%"". 
		|Chỉ có thể nhập trên cơ sở đối với bạn hàng mà cho phép các mối quan hệ khác.';
		|ru = 'С партнером ""%Partner%"" не разрешены прочие отношения. 
		|Ввод на основании доступен только для партнеров, с которыми разрешены прочие отношения.';
		|en = 'Other relations with the ""%Partner%"" partner are not allowed. 
		|Generation from base documents is available only for partners with whom other relations are allowed.'; fa = 'Other relations with the ""%Partner%"" partner are not allowed. 
		|Generation from base documents is available only for partners with whom other relations are allowed.';
		|it = 'Nessun altro rapporto è consentito con il partner ""%Partner%"". 
		| L''iscrizione in base alla causale è disponibile solo per i partner con i quali sono consentite altre relazioni.';
		|pl = 'Inne stosunki z partnerem ""%Partner%"" są niedozwolone. 
		|Wprowadzanie na podstawie jest dostępne tylko dla partnerów, inne stosunki z którymi są dozwolone.';
		|tr = '""%Partner%"" iş ortağıyla başka hiçbir ilişkiye izin verilmez. 
		|dayalı giriş, yalnızca başka ilişkilere izin verilen iş ortakları için mevcuttur.'");
		ErrorText = StrReplace(ErrorText, "%Partner%", Partner);
		
		Raise ErrorText;
		
	EndIf;
	
EndProcedure

Procedure FillInOrganizationSDefaultBankAccount(FillingData)
	
	If FillingData.Property("BankAccount") And ValueIsFilled(FillingData.BankAccount)
		Or Not (FillingData.Property("Organization") And ValueIsFilled(FillingData.Organization)) Then
		Return;
	EndIf;
	
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersOfAccount.Organization = FillingData.Organization;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	FillingData.Insert("BankAccount",
		Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount));
	
EndProcedure

Procedure FillInCounterpartySDefaultBankAccount(FillingData)
	
	If FillingData.Property("CounterpartyBankAccount")
		And ValueIsFilled(FillingData.CounterpartyBankAccount)
		Or Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
		Return;
	EndIf;
	
	If FillingData.Property("Organization") And ValueIsFilled(FillingData.Organization) Then
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	Else
		ComplCurrency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	FillingData.Insert("CounterpartyBankAccount");
	FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		FillingData.Counterparty, ComplCurrency, , ForeignCurrencyTransaction);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf