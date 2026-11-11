////////////////////////////////////////////////////////////////////////////////
//THE MODULE CONTAINS PROCEDURES AND FUNCTIONS FOR WORKING WITH EXCHANGE PACKAGES WITH THE 1C: ORDERS MOBILE APPLICATION
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region AuxiliaryDevices

// Returns the currency of the mobile app.
//
// Returns:
//  CatalogRef.Currencies - the currency of the order.
//
Function CurrencyOfOrders() Export
	
	CurrencySet = Constants.CreateSet("LocalAccountingCurrency, ManagementAccountingCurrency");
	CurrencySet.Read();
	CurrencyOfOrders = ?(ValueIsFilled(CurrencySet.LocalAccountingCurrency),
		CurrencySet.LocalAccountingCurrency, CurrencySet.ManagementAccountingCurrency);
	
	Return CurrencyOfOrders;
	
EndFunction

// Returns a string representation of the currency ID.
//
// Returns:
//  String - currency ID.
//
Function OrderCurrencyID() Export
	
	Currency = CurrencyOfOrders();
	
	Return TrimAll(Currency.UUID());
	
EndFunction

// Returns the layout settings for the exchange node
// Parameters:
//  ExchangeNode - ExchangePlanRef - exchange node with the mobile app.
//
// Returns:
//  DataCompositionSettingsComposer - exchange settings.
//
Function ExchangeSettings(ExchangeNode) Export
	
	KindExchangeSettings = Common.ObjectAttributeValue(ExchangeNode, "KindExchangeSettings");
	If ValueIsFilled(KindExchangeSettings) Then
		SettingsStorage = Common.ObjectAttributeValue(KindExchangeSettings, "ExchangeSettings"); // ValueStorage
	Else
		SettingsStorage = Common.ObjectAttributeValue(ExchangeNode, "ExchangeSettings"); // ValueStorage
	EndIf;
	Return SettingsStorage.Get();
	
EndFunction

// Returns the correspondence of data names between ERP and 1C Replacement orders in the final message
//
// Parameters:
//  Upload0 - Boolean - Unloading Is True, Loading Is False
// 
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingForReplacement(Upload0 = True) Export
	
	Result = New Map;
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian Then
		Return Result;
	EndIf;
	
	If Upload0 Then
		Result.Insert(Metadata.ExchangePlans.MobileApplicationSalesOrders.Name, "МобильноеПриложениеЗаказыКлиентов"); //@NON-NLS-1
		Result.Insert("CatalogRef." + Metadata.Catalogs.Partners.Name, "CatalogRef.Клиенты"); //@NON-NLS-1 @NON-NLS-2
		Result.Insert("CatalogRef." + Metadata.Catalogs.ContactPersonsForPartners.Name, "CatalogRef.КонтактныеЛицаКлиентов"); //@NON-NLS-1 @NON-NLS-2
	Else
		Result.Insert("МобильноеПриложениеЗаказыКлиентов", Metadata.ExchangePlans.MobileApplicationSalesOrders.Name); //@NON-NLS-1
		Result.Insert("CatalogRef.Клиенты", "CatalogRef." + Metadata.Catalogs.Partners.Name); //@NON-NLS-1 @NON-NLS-2
		Result.Insert("CatalogRef.КонтактныеЛицаКлиентов", "CatalogRef." + Metadata.Catalogs.ContactPersonsForPartners.Name); //@NON-NLS-1 @NON-NLS-2
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the correspondence of data names between ERP and 1C Orders
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingPartnerAndCustomerNames() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Result = New Map;
	
	Result.Insert(Common.ObjectAttributeValue(
			Catalogs.ContactInformationKinds.CatalogPartners, "PredefinedDataName"),
		"СправочникКлиенты"); //@NON-NLS-2
	Result.Insert(Common.ObjectAttributeValue(
			Catalogs.ContactInformationKinds.CatalogContactPersonsForPartners, "PredefinedDataName"),
		"СправочникКонтактныеЛицаКлиентов"); //@NON-NLS-2
	Result.Insert(Common.ObjectAttributeValue(
			Catalogs.ContactInformationKinds.CatalogWarehouses, "PredefinedDataName"),
		"СправочникСклады"); //@NON-NLS-2
	Result.Insert(Common.ObjectAttributeValue(
			Catalogs.ContactInformationKinds.CatalogCompanies, "PredefinedDataName"),
		"СправочникОрганизации"); //@NON-NLS-2
	
	LocalName = NStr("vi = 'Thông tin liên lạc của danh mục ""Người liên hệ của bạn hàng""';
					|ru = 'Контактная информация справочника ""Контактные лица партнеров""';
					|en = '""Partner contacts"" catalog contact information'; fa = '""Partner contacts"" catalog contact information';
					|it = 'Informazioni di contatto della query ""Contatti dei partner""';
					|pl = 'Dane kontaktowe katalogu „Osoby kontaktowe partnerów”';
					|tr = '""Ortakların İrtibat Kişileri"" dizininin iletişim bilgileri'", DefaultLanguageCode);
	OrdersLocalName = "Контактная информация справочника ""Контактные лица клиентов"""; //@NON-NLS-1
	Result.Insert(LocalName, OrdersLocalName);

	LocalName = NStr("vi = 'Thông tin liên hệ của danh mục ""Bạn hàng""';
					|ru = 'Контактная информация справочника ""Партнеры""';
					|en = '""Partners"" catalog contact information'; fa = '""Partners"" catalog contact information';
					|it = 'Informazioni di contatto della query ""Partner""';
					|pl = 'Dane kontaktowe katalogu „Partnerzy”';
					|tr = '""Ortaklar"" dizininin iletişim bilgileri'", DefaultLanguageCode);
	OrdersLocalName = "Контактная информация справочника ""Клиенты"""; //@NON-NLS-1
	Result.Insert(LocalName, OrdersLocalName);

	LocalName = "CatalogTabularSectionRow.КонтактныеЛицаПартнеров.КонтактнаяИнформация"; //@NON-NLS-1
	OrdersLocalName = "CatalogTabularSectionRow.КонтактныеЛицаКлиентов.КонтактнаяИнформация"; //@NON-NLS-1
	Result.Insert(LocalName, OrdersLocalName);
	
	LocalName = "CatalogTabularSectionRow.Партнеры.КонтактнаяИнформация"; //@NON-NLS-1
	OrdersLocalName = "CatalogTabularSectionRow.Клиенты.КонтактнаяИнформация"; //@NON-NLS-1
	Result.Insert(LocalName, OrdersLocalName);
	
	Return Result;
	
EndFunction

// Returns the correspondence of data names between the XDTO type and the Legal Entity Enumeration
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function ComplianceWithTypesOfLegalEntityIndividual() Export
	
	Result = New Map;
	
	Result.Insert(Enums.LegalEntityIndividual.Entity, "ЮрЛицо"); //@NON-NLS-1
	Result.Insert(Enums.LegalEntityIndividual.Person, "ФизЛицо"); //@NON-NLS-1
	Result.Insert(Enums.LegalEntityIndividual.LegalEntityNonResident, "ЮрЛицоНеРезидент"); //@NON-NLS-1
	Result.Insert(Enums.LegalEntityIndividual.IndividualEntrepreneur, "ИндивидуальныйПредприниматель"); //@NON-NLS-1
	
	Result.Insert("ЮрЛицо", Enums.LegalEntityIndividual.Entity); //@NON-NLS-1
	Result.Insert("ФизЛицо", Enums.LegalEntityIndividual.Person); //@NON-NLS-1
	Result.Insert("ЮрЛицоНеРезидент", Enums.LegalEntityIndividual.LegalEntityNonResident); //@NON-NLS-1
	Result.Insert("ИндивидуальныйПредприниматель", Enums.LegalEntityIndividual.IndividualEntrepreneur); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type XDTO and the Enumeration of Contact Information types
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingContactInformationTypes() Export
	
	Result = New Map;
	
	Result.Insert(Enums.ContactInformationTypes.Address, "Адрес"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.Email, "АдресЭлектроннойПочты"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.Fax, "Факс"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.Other, "Другое"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.Phone, "Телефон"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.Skype, "Skype"); //@NON-NLS-1
	Result.Insert(Enums.ContactInformationTypes.WebPage, "ВебСтраница"); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type of XDTO and the Enumeration of the payment form
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingPaymentFormTypes() Export
	
	Result = New Map;
	
	Result.Insert(Enums.PaymentForms.CashAccountPayment_, "Наличная"); //@NON-NLS-1
	Result.Insert(Enums.PaymentForms.BankAccountPayment, "Безналичная"); //@NON-NLS-1
	Result.Insert(Enums.PaymentForms.PaymentCard, "ПлатежнаяКарта"); //@NON-NLS-1
	Result.Insert(Enums.PaymentForms.SettlementOfARAP, "Взаимозачет"); //@NON-NLS-1

	Result.Insert("Наличная", Enums.PaymentForms.CashAccountPayment_); //@NON-NLS-1
	Result.Insert("Безналичная", Enums.PaymentForms.BankAccountPayment); //@NON-NLS-1
	Result.Insert("ПлатежнаяКарта", Enums.PaymentForms.PaymentCard); //@NON-NLS-1
	Result.Insert("Взаимозачет", Enums.PaymentForms.SettlementOfARAP); //@NON-NLS-1
	
	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type XDTO and the Enumeration of the tax system
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function ComplianceOfTypesOfTaxationSystem() Export
	
	Result = New Map;
	
	Result.Insert(Enums.TaxationSystems.Shared3, "Общая"); //@NON-NLS-1
	Result.Insert(Enums.TaxationSystems.Simplified, "Упрощенная"); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the names of predefined values of the directory "Types of contact information"
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function CompliancePredefinedTypesOfContactInformation() Export
	
	Result = New Map;
	
	Result.Insert("CatalogContactPersonsForPartners", "СправочникКонтактныеЛицаПартнеров"); //@NON-NLS-2
	Result.Insert("CatalogCounterparties", "СправочникКонтрагенты"); //@NON-NLS-2
	Result.Insert("CatalogCompanies", "СправочникОрганизации"); //@NON-NLS-2
	Result.Insert("CatalogPartners", "СправочникПартнеры"); //@NON-NLS-2
	Result.Insert("CatalogUsers", "СправочникПользователи"); //@NON-NLS-2
	Result.Insert("CatalogRegistrationsInTaxAuthority", "СправочникРегистрацииВНалоговомОргане"); //@NON-NLS-2
	Result.Insert("CatalogWarehouses", "СправочникСклады"); //@NON-NLS-2
	Result.Insert("CatalogRetailOutlets", "СправочникТорговыеТочки"); //@NON-NLS-2
	Result.Insert("CatalogPersons", "СправочникФизическиеЛица"); //@NON-NLS-2
	Result.Insert("OutletAddress", "АдресТорговойТочки"); //@NON-NLS-2
	Result.Insert("ContactPersonSMobilePhoneNumber", "МобильныйТелефонКонтактногоЛица"); //@NON-NLS-2
	Result.Insert("ContactPersonSPhoneNumber", "ТелефонКонтактногоЛица"); //@NON-NLS-2
	Result.Insert("EmailContactPerson", "EmailКонтактногоЛица"); //@NON-NLS-2
	Result.Insert("OtherInformationOfCounterparties", "ДругаяИнформацияКонтрагенты"); //@NON-NLS-2
	Result.Insert("InternationalAddressOfCounterparty", "МеждународныйАдресКонтрагента"); //@NON-NLS-2
	Result.Insert("PostalAddressOfCounterparty", "ПочтовыйАдресКонтрагента"); //@NON-NLS-2
	Result.Insert("CounterpartySPhoneNumber", "ТелефонКонтрагента"); //@NON-NLS-2
	Result.Insert("FaxCounterparties", "ФаксКонтрагенты"); //@NON-NLS-2
	Result.Insert("ActualDataCounterpartyAddress", "ФактАдресКонтрагента"); //@NON-NLS-2
	Result.Insert("EmailCounterparty_", "EmailКонтрагента"); //@NON-NLS-2
	Result.Insert("LegalAddressOfCounterparty", "ЮрАдресКонтрагента"); //@NON-NLS-2
	Result.Insert("OtherInformationOfCompany", "ДругаяИнформацияОрганизации"); //@NON-NLS-2
	Result.Insert("InternationalAddressOfCompany", "МеждународныйАдресОрганизации"); //@NON-NLS-2
	Result.Insert("CompanyPostalAddress", "ПочтовыйАдресОрганизации"); //@NON-NLS-2
	Result.Insert("CompanyPhone", "ТелефонОрганизации"); //@NON-NLS-2
	Result.Insert("CompanyFax", "ФаксОрганизации"); //@NON-NLS-2
	Result.Insert("ActualDataAddressOfCompany", "ФактАдресОрганизации"); //@NON-NLS-2
	Result.Insert("EmailCompanies", "EmailОрганизации"); //@NON-NLS-2
	Result.Insert("LegalAddressOfCompany", "ЮрАдресОрганизации"); //@NON-NLS-2
	Result.Insert("PartnerAddress", "АдресКлиента"); //@NON-NLS-2
	Result.Insert("PartnerSPhoneNumber", "ТелефонКлиента"); //@NON-NLS-2
	Result.Insert("EmailPartner_", "EmailКлиента"); //@NON-NLS-2
	Result.Insert("UserPhone", "ТелефонПользователя"); //@NON-NLS-2
	Result.Insert("UserEmail", "EmailПользователя"); //@NON-NLS-2
	Result.Insert("TaxAuthorityAddress", "АдресНалоговогоОргана"); //@NON-NLS-2
	Result.Insert("TaxAuthorityPhone", "ТелефонНалоговогоОргана"); //@NON-NLS-2
	Result.Insert("ActualAddressOfBranchOffice", "ФактАдресОбособленногоПодразделения"); //@NON-NLS-2
	Result.Insert("WarehouseAddress", "АдресСклада"); //@NON-NLS-2
	Result.Insert("WarehousePhone", "ТелефонСклада"); //@NON-NLS-2
	Result.Insert("EMailPersons", "EMailФизическиеЛица"); //@NON-NLS-2
	Result.Insert("AddressForInformingPersons", "АдресДляИнформированияФизическиеЛица"); //@NON-NLS-2
	Result.Insert("AddressOutsideRussianFederationPersons", "АдресЗаПределамиРФФизическиеЛица"); //@NON-NLS-2
	Result.Insert("ResidentialAddressPersons", "АдресМестаПроживанияФизическиеЛица"); //@NON-NLS-2
	Result.Insert("RegistrationAddressPersons", "АдресПоПропискеФизическиеЛица"); //@NON-NLS-2
	Result.Insert("HomePhoneNumberOfPerson", "ТелефонДомашнийФизическиеЛица"); //@NON-NLS-2
	Result.Insert("MobilePhoneOfPerson", "ТелефонМобильныйФизическиеЛица"); //@NON-NLS-2
	Result.Insert("WorkingPhoneNumberOfPerson", "ТелефонРабочийФизическиеЛица"); //@NON-NLS-2
	
	Return Result;
	
EndFunction

// Returns the correspondence of the data names between the type XDTO and the Enumeration of the statussaccidents
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingTypesCustomerOrderStatuses() Export
	
	Result = New Map;
	
	Result.Insert(Enums.SalesOrderStatuses.NotApproved, "НеСогласован"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStatuses.ToSupply, "КОбеспечению"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStatuses.ToShip, "КОтгрузке"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStatuses.Closed, "Закрыт"); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type XDTO and the Enumeration of the state of the Callback
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingStatusTypesOfRefundRequests() Export
	
	Result = New Map;
	
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingApproval, 
			"ОжидаетсяСогласование"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForReturn, 
			"ГотоваКВозврату"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingAdvanceOrReturnBeforeSupply,
			"ОжидаетсяАвансИлиВозвратДоОбеспечения"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForSupply_,
			"ГотоваКОбеспечению"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPrepaymentOrReturnBeforeShipment,
			"ОжидаетсяПредоплатаИлиВозвратДоОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingSupply,
			"ОжидаетсяОбеспечение"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.ReadyForShipment,
			"ГотоваКОтгрузке"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.DuringShipment,
			"ВПроцессеОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingPaymentOrReturnAfterShipment,
			"ОжидаетсяОплатаИлиВозвратПослеОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.PendingExecution_,
			"ОжидаетсяВыполнение"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.Executed,
			"Выполнена"); //@NON-NLS-1
	Result.Insert(Enums.StatesOfRequestsForReturnOfGoodsFromCustomers.IsRejected,
			"Отклонена"); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the XDTO type and the Enumeration of the states of the customers
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingStatusTypesOfCustomerOrders() Export
	
	Result = New Map;
	
	Result.Insert(Enums.SalesOrderStates.PendingApproval, "ОжидаетсяСогласование"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.PendingAdvanceBeforeSupply, "ОжидаетсяАвансДоОбеспечения"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.ReadyForSupply, "ГотовКОбеспечению"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.PendingPrepaymentBeforeShipment, "ОжидаетсяПредоплатаДоОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.PendingSupply, "ОжидаетсяОбеспечение"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.ReadyToShip, "ГотовКОтгрузке"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.DuringShipment, "ВПроцессеОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.TransferOfTitleToGoodsIsExpected, "ОжидаетсяПереходПраваСобственности"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.PendingPaymentAfterShipment, "ОжидаетсяОплатаПослеОтгрузки"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.ReadyForClosure, "ГотовКЗакрытию"); //@NON-NLS-1
	Result.Insert(Enums.SalesOrderStates.Closed, "Закрыт"); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of the data names between the type XDTO and the Enumeration of the methods of compensation for the return of goods
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingTypesMethodsOfCompensationForReturnsOfGoods() Export
	
	Result = New Map;
	
	Result.Insert(Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods, "ЗаменитьТовары"); //@NON-NLS-1
	Result.Insert(Enums.CompensationMethodsForReturnsOfGoods.ReturnCash, "ВернутьДенежныеСредства"); //@NON-NLS-1
	Result.Insert(Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment, "ОставитьВКачествеАванса"); //@NON-NLS-1

	Result.Insert("ЗаменитьТовары", Enums.CompensationMethodsForReturnsOfGoods.ToSubstituteGoods); //@NON-NLS-1
	Result.Insert("ВернутьДенежныеСредства", Enums.CompensationMethodsForReturnsOfGoods.ReturnCash); //@NON-NLS-1
	Result.Insert("ОставитьВКачествеАванса", Enums.CompensationMethodsForReturnsOfGoods.LeaveAsPrepayment); //@NON-NLS-1
	
	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type of XDTO and the Enumeration of the statussadjustment to trade representatives
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingTaskStatusesToSalesRepresentatives() Export
	
	Result = New Map;
	
	Result.Insert(Enums.SalesRepresentativeTaskStatuses.NotPrepared2, "НеПодготовлено"); //@NON-NLS-1
	Result.Insert(Enums.SalesRepresentativeTaskStatuses.ToProcessing, "КОтработке"); //@NON-NLS-1
	Result.Insert(Enums.SalesRepresentativeTaskStatuses.Processed_, "Отработано"); //@NON-NLS-1
	Result.Insert(Enums.SalesRepresentativeTaskStatuses.NotProcessed_, "НеОтработано"); //@NON-NLS-1
	Result.Insert(Enums.SalesRepresentativeTaskStatuses.Canceled, "Отменено"); //@NON-NLS-1

	Result.Insert("НеПодготовлено", Enums.SalesRepresentativeTaskStatuses.NotPrepared2); //@NON-NLS-1
	Result.Insert("КОтработке", Enums.SalesRepresentativeTaskStatuses.ToProcessing); //@NON-NLS-1
	Result.Insert("Отработано", Enums.SalesRepresentativeTaskStatuses.Processed_); //@NON-NLS-1
	Result.Insert("НеОтработано", Enums.SalesRepresentativeTaskStatuses.NotProcessed_); //@NON-NLS-1
	Result.Insert("Отменено", Enums.SalesRepresentativeTaskStatuses.Canceled); //@NON-NLS-1

	Return Result;
	
EndFunction

// Returns the correspondence of data names between the type of XDTO and the Enumeration of the statusreferences of clients
//
// Returns:
// Map of KeyAndValue:
// * Key - String
// * Value - String
Function MatchingTypesStatusesOfRequestsForReturnOfGoodsFromCustomers() Export
	
	Result = New Map;
	
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon, "НеСогласована"); //@NON-NLS-1
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn, "КВозврату"); //@NON-NLS-1
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply, "КОбеспечению"); //@NON-NLS-1
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip, "КОтгрузке"); //@NON-NLS-1
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.Executed, "Выполнена"); //@NON-NLS-1
	Result.Insert(Enums.StatusesOfRequestsForReturnOfGoodsFromCustomers.IsRejected, "Отклонена"); //@NON-NLS-1

	Return Result;
	
EndFunction

#EndRegion

#EndRegion
