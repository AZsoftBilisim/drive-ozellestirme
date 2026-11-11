
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If IsBlankString(PurposeUseKey) And Parameters.GroupFillingIn Then
		PurposeUseKey = "GroupFillingIn";
	EndIf;
	
	// Filling in the parameters of dynamic lists.
	CommonClientServer.SetDynamicListParameter(Warehouses, "Products",   Parameters.Products,   True);
	CommonClientServer.SetDynamicListParameter(Warehouses, "Characteristic", Parameters.Characteristic, True);
	CommonClientServer.SetDynamicListParameter(Warehouses, "Warehouse",          Parameters.Warehouse,          True);
	
	// Customize the appearance of the form.
	If Parameters.SupplyType = Enums.SupplyTypes.Purchase
		Or Parameters.SupplyType = Enums.SupplyTypes.ProductionByThirdParty Then
		
		SetRequestTextForListOfSuppliers();
		
		Items.MoveGroup_2.Visible = False;
		Items.DivisionGroup.Visible = False;
		
		If Parameters.GroupFillingIn Then
			
			Title = NStr("vi = 'Lựa chọn nhà cung cấp';
						|ru = 'Выбор поставщика';
						|en = 'Select a vendor'; fa = 'یک تأمین‌کننده انتخاب کنید';
						|it = 'Selezione del fornitore';
						|pl = 'Wybór dostawcy';
						|tr = 'Tedarikçi seçimi'");
			Items.SupplierSelectionGroup.Visible = False;
			
			Vendors.Order.Items.Clear();
			Vendors.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
			
		Else
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				TextTemplate1 = NStr("vi = 'Chọn nhà cung cấp (Mặt hàng: %1, Đặc tính: %2, Kho bãi: %3)';
									|ru = 'Выбор поставщика (Номенклатура: %1, Характеристика: %2, Склад: %3)';
									|en = 'Select vendor (Product: %1, Variant: %2, Warehouse: %3)'; fa = 'Select vendor (Product: %1, Variant: %2, Warehouse: %3)';
									|it = 'Selezione del fornitore (Articolo: %1, Caratteristica: %2, Magazzino: %3)';
									|pl = 'Wybór dostawcy (Pozycja: %1, Charakterystyka: %2, Magazyn: %3)';
									|tr = 'Tedarikçi seçimi (Ürün gamı: %1, Özellik: %2, Ambar: %3)'");
				Title = StrTemplate(TextTemplate1, Parameters.Products, Parameters.Characteristic, Parameters.Warehouse);
				
			Else
				
				TextTemplate1 = NStr("vi = 'Lựa chọn nhà cung cấp (hàng tồn kho: %1, hàng tồn kho: %2)';
									|ru = 'Выбор поставщика (Номенклатура: %1, Склад: %2)';
									|en = 'Select vendor(Items: %1, Warehouse: %2)'; fa = 'Select vendor(Items: %1, Warehouse: %2)';
									|it = 'Selezione del fornitore (Articolo: %1, Magazzino: %2)';
									|pl = 'Wybór dostawcy (Nomenklatura: %1, Magazyn: %2)';
									|tr = 'Tedarikçi seçimi (Ürün gamı: %1, Ambar: %2)'");
				Title = StrTemplate(TextTemplate1, Parameters.Products, Parameters.Warehouse);
				
			EndIf;
			
			CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
			Items.VendorsPriceManAccounting.Title = StrTemplate(NStr("vi = 'Đơn giá (%1)';
																	|ru = 'Цена (%1)';
																	|en = 'Price (%1)'; fa = 'Price (%1)';
																	|it = 'Prezzo (%1)';
																	|pl = 'Cena (%1)';
																	|tr = 'Fiyat (%1)'"), CurrencyOfManAccounting);
			
		EndIf;
		
	ElsIf Parameters.SupplyType = Enums.SupplyTypes.Move Then
		
		Items.SuppliersGroup.Visible = False;
		Items.DivisionGroup.Visible = False;
		
		If Parameters.GroupFillingIn Then
			
			Title = NStr("vi = 'Lựa chọn kho hàng';
						|ru = 'Выбор склада';
						|en = 'Select warehouse'; fa = 'انتخاب انبار';
						|it = 'Selezione del magazzino';
						|pl = 'Wybór magazynu';
						|tr = 'Ambar seçimi'");
			Items.WarehousesAvailable.Visible = False;
			
			Warehouses.Order.Items.Clear();
			Warehouses.Order.Items.Add(Type("DataCompositionAutoOrderItem"));
			
		Else
			
			If ValueIsFilled(Parameters.Characteristic) Then
				
				TextTemplate1 = NStr("vi = 'Lựa chọn kho (Mặt hàng: %1, Đặc tính: %2)';
									|ru = 'Выбор склада (Номенклатура: %1, Характеристика: %2)';
									|en = 'Select warehouse (Product: %1, Variant: %2)'; fa = 'Select warehouse (Product: %1, Variant: %2)';
									|it = 'Selezione del magazzino (Articolo: %1, Caratteristica: %2)';
									|pl = 'Wybór magazynu (Pozycja: %1, Charakterystyka: %2)';
									|tr = 'Ambar seçimi (Ürün gamı: %1, Özellik: %2)'");
				Title = StrTemplate(TextTemplate1, Parameters.Products, Parameters.Characteristic);
				
			Else
				
				Title = StrTemplate(NStr("vi = 'Lựa chọn kho (Mặt hàng: %1)';
										|ru = 'Выбор склада (Номенклатура: %1)';
										|en = 'Select warehouse (Items: %1)'; fa = 'Select warehouse (Items: %1)';
										|it = 'Selezione del magazzino (Articolo: %1)';
										|pl = 'Wybór magazynu (Nomenklatura: %1)';
										|tr = 'Ambar seçimi (Ürün gamı: %1)'"), Parameters.Products);
				
			EndIf;
			
			UnitOfMeasure = Common.ObjectAttributeValue(Parameters.Products, "UnitOfMeasure");
			Items.WarehousesAvailable.Title = StrTemplate(NStr("vi = 'Được phép (%1)';
																|ru = 'Доступно (%1)';
																|en = 'Available (%1)'; fa = 'Available (%1)';
																|it = 'Disponibile (%1)';
																|pl = 'Dostępne (%1)';
																|tr = 'Erişilebilir (%1)'"), UnitOfMeasure);
			
		EndIf;
	ElsIf Parameters.SupplyType = Enums.SupplyTypes.Production Then
		
		SetRequestTextForListOfDivisions();
		
		Items.SuppliersGroup.Visible = False;
		Items.MoveGroup_2.Visible = False;
		
		Title = NStr("vi = 'Chọn bộ phận';
					|ru = 'Выбор подразделения';
					|en = 'Select business unit'; fa = 'Select business unit';
					|it = 'Selezione del reparto';
					|pl = 'Wybór działu';
					|tr = 'Departman seçimi'");
	EndIf;
	
	Items.VendorsPriceManAccounting.Visible           = False;
	Items.VendorsRegistered1.Visible      = False;
	Items.VendorsPriceKind.Visible               = False;
	Items.VendorsLastDelivery.Visible     = False;
	Items.VendorsTotalDeliveries.Visible         = False;
	Items.ThePackagingGroupCurrency.Visible            = False;
	Items.ThereWereDeliveries.Visible = AccessRight("Read", Metadata.AccumulationRegisters.Purchases);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure PricesWhenChanging(Item)
	
	SetRequestTextForListOfSuppliers();
	
EndProcedure

&AtClient
Procedure DeliveriesWhenChanging(Item)
	
	SetRequestTextForListOfSuppliers();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVendors

&AtClient
Procedure VendorsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectOnClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersWarehouses

&AtClient
Procedure WarehousesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectOnClient();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDepartments

&AtClient
Procedure DepartmentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	SelectOnClient();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	SelectOnClient();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetRequestTextForListOfSuppliers()
	
	Items.VendorsPriceManAccounting.Visible               = False;
	Items.VendorsRegistered1.Visible          = False;
	Items.VendorsPriceKind.Visible                   = False;
	Items.VendorsLastDelivery.Visible         = False;
	Items.VendorsTotalDeliveries.Visible             = False;
	Items.ThePackagingGroupCurrency.Visible                = False;
	Items.VendorsOrderPackage.Visible            = False;
	Items.VendorsMinimumDeliveryLot.Visible = False;
	
	// Setting the properties and parameters of the dynamic list of "Suppliers".
	If PricesRegistered And ThereWereDeliveries Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.MainTable              = "InformationRegister.ItemsPricesOfVendor.SliceLast";
		ListProperties.DynamicDataRead = True;
		ListProperties.QueryText =
			"SELECT
			|	Inpayment.Partner                                        AS Partner,
			|	MAX(Inpayment.Period)                               AS LastDelivery,
			|	COUNT(DISTINCT Recorder)                          AS TotalDeliveries,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS OrderPackage,
			|	0                                                          AS MinimumDeliveryLot
			|INTO Purchases
			|FROM
			|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
			|		
			|		LEFT JOIN AccumulationRegister.Purchases AS Inpayment
			|		ON Inpayment.BusinessOperation IN (&BsnsTransactions)
			|		 AND Inpayment.Warehouse = &Warehouse
			|		 AND Inpayment.ItemsLocationAttributes = DimensionKeys.Ref
			|		 AND Inpayment.Active
			|WHERE
			|	NOT Inpayment.Partner IS NULL
			|		AND DimensionKeys.Products = &Products
			|		AND DimensionKeys.Characteristic = &Characteristic
			|	
			|GROUP BY
			|	Inpayment.Partner
			|INDEX BY
			|	Partner
			|;
			|
			|//////////////////////////////////////
			|SELECT
			|	Prices.Partner              AS Vendor,
			|	Prices.VendorPriceKind    AS PriceKind,
			|	Prices.Package             AS Package,
			|	Prices.Price                 AS Price,
			|	Prices.Currency               AS Currency,
			|	Prices.Period               AS Registered1,
			|	Purchases.LastDelivery AS LastDelivery,
			|	Purchases.TotalDeliveries     AS TotalDeliveries,
			|	ISNULL(Prices.Price * PriceCurrency.CourseNumerator / PriceCurrency.CourseDenominator, 0) / ISNULL(&QueryTextPackagingFactor, 1) * &PriceConversionFactor AS PriceManAccounting,
			|	PurchaseConditions.OrderPackage            AS OrderPackage,
			|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot
			|FROM
			|	InformationRegister.ItemsPricesOfVendor.SliceLast(&PriceDate_, Products = &Products AND Characteristic = &Characteristic) AS Prices
			|		
			|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&PriceDate_, BaseCurrency = &BaseCurrency) AS PriceCurrency
			|		ON Prices.Currency = PriceCurrency.Currency
			|		
			|		LEFT JOIN Purchases AS Purchases
			|		ON Purchases.Partner = Prices.Partner
			|
			|		LEFT JOIN InformationRegister.PurchaseConditions.SliceLast(&PriceDate_, Products = &Products AND Characteristic = &Characteristic) AS PurchaseConditions
			|		ON Prices.VendorPriceKind = PurchaseConditions.VendorPriceKind
			|		AND Prices.Products = PurchaseConditions.Products
			|		AND Prices.Characteristic = PurchaseConditions.Characteristic
			|WHERE
			|	Prices.Partner.Vendor
			|		AND NOT Prices.Partner.DeletionMark
			|		AND NOT Purchases.Partner IS NULL";
		
		ConsiderFunctionalOptionsWhenChoosingPartner(ListProperties.QueryText, "Prices.Partner");
		
		ListProperties.QueryText = StrReplace(ListProperties.QueryText, "&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("Prices.Package","Prices.Products"));
		
		Common.SetDynamicListProperties(Items.Vendors, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(Vendors, "Products",   Parameters.Products,   True);
		CommonClientServer.SetDynamicListParameter(Vendors, "Characteristic", Parameters.Characteristic, True);
		CommonClientServer.SetDynamicListParameter(Vendors, "Warehouse",          Parameters.Warehouse,          True);
		CommonClientServer.SetDynamicListParameter(Vendors, "PriceDate_",       CurrentSessionDate(),      True);
		CommonClientServer.SetDynamicListParameter(Vendors, "BaseCurrency", SettingsValueCached.DefaultBaseCurrency(), True);
		
		BsnsTransactions = Documents.PurchaseOrder.BusinessOperationsOfDocument(False);
		CommonClientServer.SetDynamicListParameter(Vendors, "BsnsTransactions", BsnsTransactions, True);
		
		CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyRate(Constants.ManagementAccountingCurrency.Get(), CurrentSessionDate());
		PriceConversionFactor = 1 / (CurrencyExchangeRateManAccounting.CourseNumerator / CurrencyExchangeRateManAccounting.CourseDenominator);
		CommonClientServer.SetDynamicListParameter(Vendors, "PriceConversionFactor", PriceConversionFactor, True);
		
		Items.VendorsPriceManAccounting.Visible               = True;
		Items.VendorsRegistered1.Visible          = True;
		Items.VendorsPriceKind.Visible                   = True;
		Items.VendorsLastDelivery.Visible         = True;
		Items.VendorsTotalDeliveries.Visible             = True;
		Items.ThePackagingGroupCurrency.Visible                = True;
		Items.VendorsOrderPackage.Visible            = True;
		Items.VendorsMinimumDeliveryLot.Visible = True;
		
	ElsIf PricesRegistered And Not ThereWereDeliveries Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.MainTable              = "InformationRegister.ItemsPricesOfVendor.SliceLast";
		ListProperties.DynamicDataRead = True;
		ListProperties.QueryText =
			"SELECT
			|	Prices.Partner           AS Vendor,
			|	Prices.VendorPriceKind AS PriceKind,
			|	Prices.Package          AS Package,
			|	Prices.Price              AS Price,
			|	Prices.Currency            AS Currency,
			|	Prices.Period            AS Registered1,
			|	DATETIME(1,1,1)       AS LastDelivery,
			|	0                      AS TotalDeliveries,
			|	
			|	ISNULL(Prices.Price * PriceCurrency.CourseNumerator / PriceCurrency.CourseDenominator, 0) / ISNULL(&QueryTextPackagingFactor, 1) * &PriceConversionFactor AS PriceManAccounting,
			|	PurchaseConditions.OrderPackage            AS OrderPackage,
			|	PurchaseConditions.MinimumDeliveryLot AS MinimumDeliveryLot
			|FROM
			|	InformationRegister.ItemsPricesOfVendor.SliceLast(&PriceDate_, Products = &Products AND Characteristic = &Characteristic) AS Prices
			|		
			|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&PriceDate_, BaseCurrency = &BaseCurrency) AS PriceCurrency
			|		ON Prices.Currency = PriceCurrency.Currency
			|		LEFT JOIN InformationRegister.PurchaseConditions.SliceLast(&PriceDate_, Products = &Products AND Characteristic = &Characteristic) AS PurchaseConditions
			|		ON Prices.VendorPriceKind = PurchaseConditions.VendorPriceKind
			|		AND Prices.Products = PurchaseConditions.Products
			|		AND Prices.Characteristic = PurchaseConditions.Characteristic
			|WHERE
			|	Prices.Partner.Vendor
			|		AND NOT Prices.Partner.DeletionMark";
		
		ConsiderFunctionalOptionsWhenChoosingPartner(ListProperties.QueryText, "Prices.Partner");
		
		ListProperties.QueryText = StrReplace(ListProperties.QueryText, "&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("Prices.Package","Prices.Products"));
		
		Common.SetDynamicListProperties(Items.Vendors, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(Vendors, "Products",   Parameters.Products,   True);
		CommonClientServer.SetDynamicListParameter(Vendors, "Characteristic", Parameters.Characteristic, True);
		CommonClientServer.SetDynamicListParameter(Vendors, "PriceDate_",       CurrentSessionDate(),      True);
		CommonClientServer.SetDynamicListParameter(Vendors, "BaseCurrency", SettingsValueCached.DefaultBaseCurrency(), True);
		
		CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyRate(Constants.ManagementAccountingCurrency.Get(), CurrentSessionDate());
		PriceConversionFactor = 1 / (CurrencyExchangeRateManAccounting.CourseNumerator / CurrencyExchangeRateManAccounting.CourseDenominator);
		CommonClientServer.SetDynamicListParameter(Vendors, "PriceConversionFactor", PriceConversionFactor, True);
		
		Items.VendorsPriceManAccounting.Visible               = True;
		Items.VendorsRegistered1.Visible          = True;
		Items.VendorsPriceKind.Visible                   = True;
		Items.ThePackagingGroupCurrency.Visible                = True;
		Items.VendorsOrderPackage.Visible            = True;
		Items.VendorsMinimumDeliveryLot.Visible = True;
		
	ElsIf Not PricesRegistered And ThereWereDeliveries Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.MainTable              = "Catalog.Partners";
		ListProperties.DynamicDataRead = True;
		ListProperties.QueryText =
			"SELECT
			|	Inpayment.Partner                                        AS Partner,
			|	MAX(Inpayment.Period)                               AS LastDelivery,
			|	COUNT(DISTINCT Recorder)                          AS TotalDeliveries,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS OrderPackage,
			|	0                                                          AS MinimumDeliveryLot
			|INTO Purchases
			|FROM
			|	Catalog.InventoryLocationAttributeKeys AS DimensionKeys
			|		
			|		LEFT JOIN AccumulationRegister.Purchases AS Inpayment
			|		ON Inpayment.BusinessOperation IN (&BsnsTransactions)
			|		 AND Inpayment.Warehouse = &Warehouse
			|		 AND Inpayment.ItemsLocationAttributes = DimensionKeys.Ref
			|		 AND Inpayment.Active
			|WHERE
			|	NOT Inpayment.Partner IS NULL
			|		AND DimensionKeys.Products = &Products
			|		AND DimensionKeys.Characteristic = &Characteristic
			|	
			|GROUP BY
			|	Inpayment.Partner
			|INDEX BY
			|	Partner
			|;
			|
			|//////////////////////////////////////
			|SELECT
			|	Partners.Ref                                            AS Vendor,
			|	VALUE(Catalog.VendorPriceTypes.EmptyRef)       AS PriceKind,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|	VALUE(Catalog.Currencies.EmptyRef)                   AS Currency,
			|	DATETIME(1,1,1)                                           AS Registered1,
			|	0.00                                                       AS Price,
			|	0.00                                                       AS PriceManAccounting,
			|	Purchases.LastDelivery                                  AS LastDelivery,
			|	Purchases.TotalDeliveries                                      AS TotalDeliveries,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS OrderPackage,
			|	0                                                          AS MinimumDeliveryLot
			|FROM
			|	Catalog.Partners AS Partners
			|		
			|		LEFT JOIN Purchases AS Purchases
			|		ON Purchases.Partner = Partners.Ref
			|WHERE
			|	Partners.Vendor
			|		AND NOT Partners.DeletionMark
			|		AND NOT Purchases.Partner IS NULL";
		
		ConsiderFunctionalOptionsWhenChoosingPartner(ListProperties.QueryText, "Partners.Ref");
		
		Common.SetDynamicListProperties(Items.Vendors, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(Vendors, "Products",   Parameters.Products,   True);
		CommonClientServer.SetDynamicListParameter(Vendors, "Characteristic", Parameters.Characteristic, True);
		CommonClientServer.SetDynamicListParameter(Vendors, "Warehouse",          Parameters.Warehouse,          True);
		BsnsTransactions = Documents.PurchaseOrder.BusinessOperationsOfDocument(False);
		CommonClientServer.SetDynamicListParameter(Vendors, "BsnsTransactions", BsnsTransactions, True);
		
		Items.VendorsLastDelivery.Visible      = True;
		Items.VendorsTotalDeliveries.Visible          = True;
		
	Else // No prices were registered and no deliveries were made
		
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.MainTable              = "Catalog.Partners";
		ListProperties.DynamicDataRead = True;
		ListProperties.QueryText =
			"SELECT
			|	Partners.Ref                                            AS Vendor,
			|	VALUE(Catalog.VendorPriceTypes.EmptyRef)       AS PriceKind,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|	VALUE(Catalog.Currencies.EmptyRef)                   AS Currency,
			|	DATETIME(1,1,1)                                           AS Registered1,
			|	0.00                                                       AS Price,
			|	0.00                                                       AS PriceManAccounting,
			|	DATETIME(1,1,1)                                           AS LastDelivery,
			|	0                                                          AS TotalDeliveries,
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS OrderPackage,
			|	0                                                          AS MinimumDeliveryLot
			|FROM
			|	Catalog.Partners AS Partners
			|WHERE
			|	Partners.Vendor
			|	AND NOT Partners.DeletionMark";
		
		ConsiderFunctionalOptionsWhenChoosingPartner(ListProperties.QueryText, "Partners.Ref");
		
		Common.SetDynamicListProperties(Items.Vendors, ListProperties);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure ConsiderFunctionalOptionsWhenChoosingPartner(QueryText, NameOfPaulPatner)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		QueryText = QueryText + "	And " + NameOfPaulPatner + " <> Value(Catalog.Partners.UnknownPartner)";
	EndIf;
	
	If Not GetFunctionalOption("UseCustomerInvoiceIntercompany") Then
		QueryText = QueryText + "	And " + NameOfPaulPatner + " <> Value(Catalog.Partners.OurEnterprise)";
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectOnClient()
	
	DeliveryParametersOptimal = New Structure("SupplySource");
	DeliveryParametersOptimal.Insert("Terms", PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	DeliveryParametersOptimal.Insert("PriceInTheCurrencyOfManagementAccounting", 0);
	DeliveryParametersOptimal.Insert("PriceInTheCurrencyOfAgreement",           0);
	DeliveryParametersOptimal.Insert("MinimumOrderAmount",          0);
	DeliveryParametersOptimal.Insert("MinimumDeliveryLot",       0);
	DeliveryParametersOptimal.Insert("AgreementCurrency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	DeliveryParametersOptimal.Insert("PriceKind", PredefinedValue("Catalog.VendorPriceTypes.EmptyRef"));
	DeliveryParametersOptimal.Insert("OrderPackage", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	
	If Parameters.SupplyType = PredefinedValue("Enum.SupplyTypes.Purchase")
		Or Parameters.SupplyType = PredefinedValue("Enum.SupplyTypes.ProductionByThirdParty") Then
			
			If Items.Vendors.CurrentData = Undefined Then
				Return;
			EndIf;
			
			CurrentRow = Items.Vendors.CurrentData;
			
			Partner = CurrentRow.Vendor;
			
			If PricesRegistered Then
				
				PurchaseConditions = PartnerSTermsOfPurchase(Partner, CurrentRow.PriceManAccounting);
				
			Else
				
				PurchaseConditions = PartnerSTermsOfPurchase(Partner, 0);
				
			EndIf;
			
			DeliveryParametersOptimal.Insert("SupplySource",    Partner);
			DeliveryParametersOptimal.Insert("Terms",             PurchaseConditions.Terms);
			DeliveryParametersOptimal.Insert("AgreementCurrency",       PurchaseConditions.Currency);
			DeliveryParametersOptimal.Insert("MinimumOrderAmount", PurchaseConditions.MinimumOrderAmount);
			
			If PricesRegistered Then
				
				DeliveryParametersOptimal.Insert("PriceInTheCurrencyOfAgreement",           PurchaseConditions.Price);
				DeliveryParametersOptimal.Insert("PriceInTheCurrencyOfManagementAccounting", CurrentRow.PriceManAccounting);
				DeliveryParametersOptimal.Insert("PriceKind",                         CurrentRow.PriceKind);
				DeliveryParametersOptimal.Insert("OrderPackage",                  CurrentRow.OrderPackage);
				DeliveryParametersOptimal.Insert("MinimumDeliveryLot",       CurrentRow.MinimumDeliveryLot);
				
			EndIf;
			
	ElsIf Parameters.SupplyType = PredefinedValue("Enum.SupplyTypes.Move") Then
		
		If Items.Warehouses.CurrentData = Undefined Then
			Return;
		EndIf;
		
		DeliveryParametersOptimal.Insert("SupplySource", Items.Warehouses.CurrentData.Warehouse);
	Else
		
		If Items.Departments.CurrentData = Undefined Then
			Return;
		EndIf;
		
		DeliveryParametersOptimal.Insert("SupplySource", Items.Departments.CurrentData.Department);
	EndIf;
	
	Result = New Structure("DeliveryParametersOptimal", DeliveryParametersOptimal);
	NotifyChoice(Result);
	
EndProcedure

&AtServerNoContext
Function PartnerSTermsOfPurchase(Partner, Price)
	
	Return SupplyServer.PartnerSTermsOfPurchase(Partner, Price);
	
EndFunction

&AtServer
Procedure SetRequestTextForListOfDivisions()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	FillPropertyValues(ListProperties, Departments);
	ListProperties.QueryText =
		"SELECT
		|	BusinessStructure.Ref AS Department
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.ProductionDispatcherBusinessUnit
		|	AND NOT BusinessStructure.DeletionMark
		|	AND BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)";
	
	Common.SetDynamicListProperties(Items.Departments, ListProperties);
	
EndProcedure
#EndRegion
