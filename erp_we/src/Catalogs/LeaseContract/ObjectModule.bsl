#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If TypeOf(FillingData) = Type("CatalogRef.Partners") Then
		
		FillInBasedOnPartner(FillingData, FillingData);
		
	ElsIf TypeOf(FillingData) = Type("Structure") Then
		
		FillInByPicking(FillingData);
		
	EndIf;
	
	InitializeCatalog(FillingData);
	
	ItemsAndDimensionsSelectionParameters = Catalogs.LeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.Filling(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	ItemDetailsParameters = 
		LeasedAssetAccountingClientServer.PropertyValuesForDependentDetails_LeaseAgreements(ThisObject, AuxiliaryAttributes());
	TMCommonUse.DisableVerificationOfObjectDetails(ItemDetailsParameters, NotCheckedAttributeArray);
	
	CheckObject(Cancel);	
	
	ItemsAndDimensionsSelectionParameters = Catalogs.LeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes, ItemsAndDimensionsSelectionParameters);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Approved              = False;
	ValidityStartDate      = '00010101';
	ValidityEndDate   = '00010101';

	InitializeCatalog();

EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.ChangeCatalogConsistencyFlag(
		ThisObject, Enums.CounterpartyContractStatuses.NotApproved);
		
	ContractKind = Enums.ContractKindsOfFinancialInstruments.Lease;
	
	If ContractType = Enums.TypesOfLeaseContracts.Leasing Then
		RecognizeLeasedItemsInLocalAccounting = True;
		RecognizeLeasedAssetsInManagementAccounting = True;
	EndIf;
	
		
	ItemsAndDimensionsSelectionParameters = Catalogs.LeaseContract.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.BeforeWrite(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

Procedure FillInBasedOnPartner(Val Partner, FillingData)
	
	FillingData = New Structure;
	
	FillingData.Insert("Partner", Partner);
	FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(Partner));
	FillingData.Insert("ContactPerson", PartnersAndCounterparties.GetDefaultPartnerContactPerson(Partner));
	
	FillInCounterpartySDefaultBankAccount(FillingData);
	
EndProcedure

Procedure FillInByPicking(Val FillingData)
	
	If FillingData.Property("DefaultPartner") Then
		FillingData.Insert("Partner", FillingData.DefaultPartner);
	ElsIf FillingData.Property("Partner") Then
		
	ElsIf FillingData.Property("Counterparty") Then
		FillingData.Insert("Partner", Common.ObjectAttributeValue(FillingData.Counterparty, "Partner"));
	EndIf;
	
	If FillingData.Property("Partner") Then
		If Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
			FillingData.Insert("Counterparty", PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FillingData.Partner));
		EndIf;
		If Not (FillingData.Property("ContactPerson") And ValueIsFilled(FillingData.ContactPerson)) Then
			FillingData.Insert("ContactPerson", PartnersAndCounterparties.GetDefaultPartnerContactPerson(FillingData.Partner));
		EndIf;
	EndIf;	
	
	If FillingData.Property("Organization") Then
		If LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(FillingData.Organization) Then
			ContractType = Enums.TypesOfLeaseContracts.Lease;
		Else
			ContractType = Enums.TypesOfLeaseContracts.Leasing;
		EndIf;
	EndIf;
	
	FillInOrganizationSDefaultBankAccount(FillingData);
	FillInCounterpartySDefaultBankAccount(FillingData);
	
	If FillingData.Property("ARAPCurrency") And Not FillingData.Property("ForeignCurrencyTransaction") Then
		FillingData.Insert("ForeignCurrencyTransaction",
			ARAPAccountingServer.GetPaidInDefaultCurrency());
	EndIf;
	
EndProcedure

Procedure FillInOrganizationSDefaultBankAccount(FillingData)
	
	If FillingData.Property("BankAccount") And ValueIsFilled(FillingData.BankAccount)
	 Or Not (FillingData.Property("Organization") And ValueIsFilled(FillingData.Organization)) Then
		Return;
	EndIf;
	
	ForeignCurrencyTransaction = FillingData.Property("ForeignCurrencyTransaction") And FillingData.ForeignCurrencyTransaction;
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Organization);
	
	ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
	ParametersOfAccount.Organization = FillingData.Organization;
	ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
	ParametersOfAccount.Currency = ComplCurrency;
	
	FillingData.Insert("BankAccount",
		Catalogs.CompaniesBankAccounts.GetDefaultBankAccount(ParametersOfAccount));
	
EndProcedure

Procedure FillInCounterpartySDefaultBankAccount(FillingData)
	
	If FillingData.Property("CounterpartyBankAccount") And ValueIsFilled(FillingData.CounterpartyBankAccount)
	 Or Not (FillingData.Property("Counterparty") And ValueIsFilled(FillingData.Counterparty)) Then
		Return;
	EndIf;
	
	ForeignCurrencyTransaction = FillingData.Property("ForeignCurrencyTransaction") And FillingData.ForeignCurrencyTransaction;
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);

	FillingData.Insert("CounterpartyBankAccount");
	FillingData.CounterpartyBankAccount = Catalogs.CounterpartyBankAccounts.GetDefaultBankAccount(
		FillingData.Counterparty, ComplCurrency, , ForeignCurrencyTransaction);
	
EndProcedure

// The procedure fills in the directory details with the "default" values.
//
Procedure InitializeCatalog(FillingData = Undefined) Export
	
	EmployeeResponsible = Users.CurrentUser();
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
		Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ARAPCurrency") Then
		If Not ValueIsFilled(ARAPCurrency) Then
			ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		EndIf;
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ForeignCurrencyTransaction") Then
		ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
	EndIf;
	
	If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
		ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount(Organization);
		ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
		ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
			BankAccount);
	EndIf;
	
	Status = Enums.CounterpartyContractStatuses.Valid;
	
	If (ContractType = Enums.TypesOfLeaseContracts.Lease
			Or ContractType = Enums.TypesOfLeaseContracts.EmptyRef()) 
		And Not LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization) Then
		ContractType = Enums.TypesOfLeaseContracts.Leasing;
	EndIf;
	
	ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
	
EndProcedure

#EndRegion

#Region FillChecking

Procedure CheckObject(Cancel)
	
	If ValueIsFilled(Date) 
		And ValueIsFilled(ValidityStartDate)
		And BegOfDay(Date) > ValidityStartDate Then
			
		ErrorText = NStr("vi = 'Ngày bắt đầu hiệu lực của hợp đồng không được nhỏ hơn ngày hợp đồng';
						|ru = 'Дата начала действия договора должна быть не меньше даты договора';
						|en = 'Contract effective date cannot be less than the contract date'; fa = 'Contract effective date cannot be less than the contract date';
						|it = 'La data di inizio dell''accordo non può essere antecedente la data dell''accordo';
						|pl = 'Data wejścia w życie umowy nie może być wcześniejsza od daty umowy';
						|tr = 'Sözleşmenin başlangıç tarihi, sözleşme tarihinden daha önce olmamalıdır'");
		Common.MessageToUser(ErrorText, ThisObject, "ValidityStartDate",, Cancel);
	EndIf;
	
	If ValueIsFilled(Date) 
		And ValueIsFilled(ValidityEndDate)
		And BegOfDay(Date) > ValidityEndDate Then
			
		ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày hợp đồng';
						|ru = 'Дата окончания действия договора должна быть не меньше даты договора';
						|en = 'Contract expiration date cannot be less than the contract date'; fa = 'Contract expiration date cannot be less than the contract date';
						|it = 'La data di scadenza dell''accordo non può essere antecedente la data dell''accordo';
						|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty umowy';
						|tr = 'Sözleşmenin sona erme tarihi, sözleşme tarihinden daha önce olmamalıdır'");
		Common.MessageToUser(ErrorText, ThisObject, "ValidityEndDate",, Cancel);
	EndIf;
	
	If ValueIsFilled(ValidityStartDate) 
		And ValueIsFilled(ValidityEndDate)	
		And ValidityStartDate > ValidityEndDate Then
			
		ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày bắt đầu hiệu lực';
						|ru = 'Дата окончания действия договора должна быть не меньше даты начала действия';
						|en = 'Contract expiration date cannot be less than contract effective date'; fa = 'Contract expiration date cannot be less than contract effective date';
						|it = 'La data di scadenza dell''accordo non può essere antecedente la data di inizio dell''accordo';
						|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty wejścia w życie';
						|tr = 'Sözleşmenin sona erme tarihi, sözleşmenin başlangıç tarihinden daha önce olmamalıdır'");
		Common.MessageToUser(ErrorText, ThisObject, "ValidityEndDate",, Cancel);
	EndIf;
	

EndProcedure

#EndRegion

#Region Other

Function AuxiliaryAttributes()
	
	AuxiliaryAttributes = New Structure;
	
	If ValueIsFilled(ValidityEndDate) Then
		CheckDate = ValidityEndDate;
	Else
		CheckDate = ?(ValidityStartDate < CurrentSessionDate(), '000101010000', ValidityStartDate);
	EndIf;
	
	AuxiliaryAttributes.Insert(
		"LeaseAccountingAccordingToFSB25_2018IsUsed", 
		LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Organization, CheckDate, False));
	
	PropertyValue = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		Organization, EndOfMonth(?(ValidityStartDate <> '000101010000', ValidityStartDate, CurrentSessionDate())));
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		PropertyValue);
	
	Return AuxiliaryAttributes;

EndFunction

#EndRegion

#EndRegion

#EndIf
