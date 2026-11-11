#Region Internal

// Complements the array of exceptions for notification sources.
// 
// Parameters:
//  Exceptions - Array of String - Sources of Alerts Exceptions
Procedure AddSourcesOfNotificationExceptions(Exceptions) Export
	UserNotificationsOfEventsLocalization.AddSourcesOfNotificationExceptions(Exceptions);
EndProcedure

// Complements the array with objects describing the types of alerts.
// 
// Parameters:
//  ObjectsArray - Array of String - Sources of Alerts Exceptions
Procedure AddObjectsWithDescriptionOfTypesOfNotifications(ObjectsArray) Export
	
	ObjectsArray.Add(Metadata.Catalogs.CounterpartyContracts.FullName());
	ObjectsArray.Add(Metadata.Catalogs.TermsOfSale.FullName());
	ObjectsArray.Add(Metadata.Catalogs.TermsOfPurchaseFromVendors.FullName());
	
	ObjectsArray.Add(Metadata.Documents.PaymentRequest.FullName());
	
	ObjectsArray.Add(Metadata.AccumulationRegisters.CashToBePaid.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.PurchaseOrders.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.ShipmentAndReturnReferences.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.CustomersARAPAccounting.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.CustomersARAPAccountingCashFlowPlan.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.VendorsARAPAccounting.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.VendorsARAPAccountingCashFlowPlan.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.GoodsForIssue.FullName());
	ObjectsArray.Add(Metadata.AccumulationRegisters.GoodsToReceive.FullName());
	
	ObjectsArray.Add(Metadata.InformationRegisters.SalesOrderStates.FullName());
	ObjectsArray.Add(Metadata.InformationRegisters.PurchaseOrderStates.FullName());
	
	UserNotificationsOfEventsLocalization.AddObjectsWithDescriptionOfTypesOfNotifications(ObjectsArray);
	
EndProcedure

// Generates an array of objects with a description of the types of alerts.
// 
// Parameters:
//  GroupsOfNotificationKinds - See UserNotificationsOfEvents.GroupsOfNotificationKinds
Procedure AddGroupsOfNotificationKinds(GroupsOfNotificationKinds) Export
	
	GroupsOfNotificationKinds.Insert("Sales",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("9ca9ef1c-d839-4fae-b1e9-ec578486c184", 
			NStr("vi = 'Bán hàng';
				|ru = 'Продажи';
				|en = 'Sales'; fa = 'فروش';
				|it = 'Vendite';
				|pl = 'Sprzedaż';
				|tr = 'Satış'", Common.DefaultLanguageCode())));
	
	GroupsOfNotificationKinds.Insert("Purchases",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("9ed8539b-1da7-4801-966d-bab6969a3968", 
			NStr("vi = 'Mua hàng';
				|ru = 'Закупки';
				|en = 'Purchasing'; fa = 'تدارکات';
				|it = 'Acquisti';
				|pl = 'Zakupy';
				|tr = 'Satın alımlar'", Common.DefaultLanguageCode())));
	
	GroupsOfNotificationKinds.Insert("TreasuryAndARAPAccounting",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("dee8a453-b373-40cc-9096-830f95f0f4fd", 
			NStr("vi = 'Ngân quỹ';
				|ru = 'Казначейство';
				|en = 'Treasury'; fa = 'خزانه‌داری';
				|it = 'Tesoreria';
				|pl = 'Środki pieniężne';
				|tr = 'Hazine'", Common.DefaultLanguageCode())));

	GroupsOfNotificationKinds.Insert("SettlementsWithClients",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("b2f42f53-94a6-4f6d-99f9-ab78f91074d6", 
			NStr("vi = 'Hạch toán công nợ với khách hàng';
				|ru = 'Взаиморасчеты с клиентами';
				|en = 'Customer AR/AP'; fa = 'دریافتنی/پرداختنی مشتری';
				|it = 'Customer AR/AP';
				|pl = 'Customer AR/AP';
				|tr = 'Müşterilerle alacak/borç muhasebesi'", Common.DefaultLanguageCode())));
	
	GroupsOfNotificationKinds.Insert("SettlementsWithSuppliers",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("105818a5-b852-4e3a-aeff-60487133f51d", 
			NStr("vi = 'Hạch toán công nợ với nhà cung cấp';
				|ru = 'Взаиморасчеты с поставщиками';
				|en = 'Vendor AR/AP'; fa = 'دریافتنی/پرداختنی تأمین‌کننده';
				|it = 'Vendor AR/AP';
				|pl = 'Vendor AR/AP';
				|tr = 'Tedarikçilerle alacak/borç muhasebesi'", Common.DefaultLanguageCode())));
			
	GroupsOfNotificationKinds.Insert("CounterpartyContracts",
		UserNotificationsOfEvents.DescriptionOfGroupOfNotificationKinds("75d39378-7656-4717-816c-494b8f04cc47", 
			NStr("vi = 'Hợp đồng đối tác';
				|ru = 'Договоры контрагентов';
				|en = 'Counterparty contracts'; fa = 'قراردادهای طرف حساب';
				|it = 'Contratti delle controparti';
				|pl = 'Kontrakty kontrahentów';
				|tr = 'Cari hesap sözleşmeleri'", Common.DefaultLanguageCode())));
	
	UserNotificationsOfEventsLocalization.AddGroupsOfNotificationKinds(GroupsOfNotificationKinds);
	
EndProcedure

// Complements the supported types of metadata.
// 
// Parameters:
//  SupportedTypesOfMetadata - See UserNotificationsOfEvents.SupportedTypesOfMetadata
Procedure AddSupportedTypesOfMetadata(SupportedTypesOfMetadata) Export
	
EndProcedure

// Overriding the receipt of user alerts by the author.
// 
// Parameters:
//  Author - Undefined, CatalogRef.Users - Author of User Alerts
Procedure OnGettingUserNotificationAuthor(Author) Export
	
EndProcedure

#Region InfobaseUpdate

#EndRegion

#EndRegion