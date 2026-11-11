#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	Var Errors;
	
	NotCheckedAttributeArray = New Array;
	
	// The start date of the contract must be no less than the date of the contract.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityStartDate) Then
		
		If BegOfDay(Date) > ValidityStartDate Then
			
			ErrorText = NStr("vi = 'Ngày bắt đầu hiệu lực của hợp đồng không được nhỏ hơn ngày hợp đồng';
							|ru = 'Дата начала действия договора должна быть не меньше даты договора';
							|en = 'Contract effective date cannot be less than the contract date'; fa = 'Contract effective date cannot be less than the contract date';
							|it = 'La data di inizio dell''accordo non può essere antecedente la data dell''accordo';
							|pl = 'Data wejścia w życie umowy nie może być wcześniejsza od daty umowy';
							|tr = 'Sözleşmenin başlangıç tarihi, sözleşme tarihinden daha önce olmamalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityStartDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// The expiration date of the contract must not be less than the date of the contract.
	If ValueIsFilled(Date) And ValueIsFilled(ValidityEndDate) Then	
		
		If BegOfDay(Date) > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày hợp đồng';
							|ru = 'Дата окончания действия договора должна быть не меньше даты договора';
							|en = 'Contract expiration date cannot be less than the contract date'; fa = 'Contract expiration date cannot be less than the contract date';
							|it = 'La data di scadenza dell''accordo non può essere antecedente la data dell''accordo';
							|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty umowy';
							|tr = 'Sözleşmenin sona erme tarihi, sözleşme tarihinden daha önce olmamalıdır'");
			
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
	// The expiration date of the contract must not be less than the start date.
	If ValueIsFilled(ValidityStartDate) And ValueIsFilled(ValidityEndDate) Then	
		
		If ValidityStartDate > ValidityEndDate Then
			
			ErrorText = NStr("vi = 'Ngày hết hiệu lực của hợp đồng không được nhỏ hơn ngày bắt đầu hiệu lực';
							|ru = 'Дата окончания действия договора должна быть не меньше даты начала действия';
							|en = 'Contract expiration date cannot be less than contract effective date'; fa = 'Contract expiration date cannot be less than contract effective date';
							|it = 'La data di scadenza dell''accordo non può essere antecedente la data di inizio dell''accordo';
							|pl = 'Data wygaśnięcia umowy nie może być wcześniejsza od daty wejścia w życie';
							|tr = 'Sözleşmenin sona erme tarihi, sözleşmenin başlangıç tarihinden daha önce olmamalıdır'");
			CommonClientServer.MessageToUser(
				ErrorText,
				ThisObject, 
				"ValidityEndDate",
				,
				Cancel);
			
		EndIf;
		
	EndIf;
	
		
	If Organization = CompanyRecipient Then
		
		If ContractType = Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
			ErrorText = NStr("vi = 'Người mua và người bán không thể là cùng một doanh nghiệp.';
							|ru = 'Покупателем и продавцом не может являться одна и та же организация.';
							|en = 'The same company cannot be both a customer and a seller.'; fa = 'The same company cannot be both a customer and a seller.';
							|it = 'La stessa società non può essere sia venditore che compratore.';
							|pl = 'Nabywcą i sprzedawcą nie może być ta sama firma.';
							|tr = 'Alıcı ve satıcı aynı iş yeri olamaz.'");
		Else
			ErrorText = NStr("vi = 'Người đặt ký gửi và người nhận ký gửi không thể là cùng một doanh nghiệp.';
							|ru = 'Комитентом и комиссионером не может являться одна и та же организация.';
							|en = 'The same company cannot be a consignor and a consignee.'; fa = 'The same company cannot be a consignor and a consignee.';
							|it = 'La stessa società non può essere sia committente che commissionario.';
							|pl = 'Komitentem i komisantem nie może być ta sama firma.';
							|tr = 'Aynı iş yeri hem gönderici hem de konsinye olamaz.'");
		EndIf;
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject, 
			"CompanyRecipient",
			,
			Cancel);
			
	EndIf;
	
	If VATTaxationIsDeterminedInDocuments  Then
		NotCheckedAttributeArray.Add("VATTaxation");
	EndIf;
	
	If PurchaseForActivityIsDeterminedInDocument
		Or ContractType <> Enums.TypesOfIntercompanyContracts.PurchaseAndSale Then
		NotCheckedAttributeArray.Add("PurchaseForActivity");
	EndIf;
	CommonClientServer.ReportErrorsToUser(Errors);

	IntercompanyContractsLocalization.FillCheckProcessing(Cancel, CheckedAttributes, NotCheckedAttributeArray, ThisObject);
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not ValueIsFilled(NameForPrinting) Then
		NameForPrinting = TrimAll(Description);
	EndIf;

	TMCommonUse.ChangeCatalogConsistencyFlag(
		ThisObject,
		Enums.CounterpartyContractStatuses.NotApproved);
		
	If ValueIsFilled(Date) And ValueIsFilled(Number) Then
		PaymentID = TMCommonUse.GetUniquePaymentID(ThisObject);
	Else
		PaymentID = Undefined;
	EndIf;
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	IntercompanyContractsLocalization.BeforeWrite(Cancel, ThisObject);
	
	ARAPAccountingServer.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure OnCopy(CopiedObject)

	Approved              = False;
	ValidityStartDate      = '00010101';
	ValidityEndDate   = '00010101';
	PaymentID	= Undefined;

	InitializeCatalog(, False);

EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	InitializeCatalog(FillingData);
	
EndProcedure

#EndRegion

#Region Private

#Region InitializationAndFilling

// The procedure fills in the directory details with the "default" values.
//
Procedure InitializeCatalog(FillingData = Undefined, FillInAllDetails = True) Export
	
	Manager    = Users.CurrentUser();
	Status      = Enums.CounterpartyContractStatuses.Valid;
	ContractType = ?(TypeOf(FillingData) = Type("Structure")
						And FillingData.Property("ContractType"),
					FillingData.ContractType,
					?(ValueIsFilled(ContractType), ContractType, Enums.TypesOfIntercompanyContracts.PurchaseAndSale));
	
	If FillInAllDetails Then
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("Organization") Then
			Organization = SettingsValueCached.GetDefaultOrganization(Organization);
		Else
			Organization = FillingData.Organization;
		EndIf;
		
		If TypeOf(FillingData) = Type("Structure") And FillingData.Property("CompanyRecipient") Then
			CompanyRecipient = FillingData.CompanyRecipient;
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ARAPCurrency") Then
			ARAPCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
		Else
			ARAPCurrency = FillingData.ARAPCurrency;
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("ForeignCurrencyTransaction") Then
			ForeignCurrencyTransaction = ARAPAccountingServer.GetPaidInDefaultCurrency();
		Else
			ForeignCurrencyTransaction = FillingData.ForeignCurrencyTransaction;
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccount") Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = Organization;
			ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
			ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			BankAccount = CashServer.GetOrganizationSDefaultBankAccount(ParametersOfAccount,
				BankAccount);
		EndIf;
		
		If TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("BankAccountOfBeneficiary") Then
			ParametersOfAccount = CashServer.ParametersForFillingOutOrganizationSBankAccount();
			ParametersOfAccount.Organization = CompanyRecipient;
			ParametersOfAccount.ExcludeCurrencyAccounts = ForeignCurrencyTransaction;
			ParametersOfAccount.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
			BankAccountOfBeneficiary = CashServer.GetOrganizationSDefaultBankAccount(
				ParametersOfAccount, BankAccountOfBeneficiary);
		EndIf;
		
		ObjectsFillingByStatistics.FillObjectAttributes(ThisObject, FillingData);
		
	EndIf;
	
	CompleteVATTaxation();
	FillOutPurchaseForActivity();
	
EndProcedure

Procedure FillOutPurchaseForActivity()
	
	FillParameters = Catalogs.IntercompanyContracts.ParametersForFillingInVATActivityType(ThisObject);
	VATAccountingERP.FillInTypeOfActivityVAT(PurchaseForActivity, FillParameters);
	
EndProcedure

Procedure CompleteVATTaxation()
	
	FillParameters = Catalogs.IntercompanyContracts.ParametersForFillingInVATTaxation_(ThisObject);
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
	If Not VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(VATTaxation) Then
		VATRate = Catalogs.VATRates.EXCLUDINGVAT;
	EndIf;
	
EndProcedure

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.DimensionKeysOfAccountingByPartners", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
