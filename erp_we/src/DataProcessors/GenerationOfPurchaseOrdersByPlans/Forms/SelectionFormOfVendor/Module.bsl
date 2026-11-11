
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	// Filling in the parameters of dynamic lists.
	ListParameters = New Structure("Products, Characteristic, Warehouse");
	FillPropertyValues(ListParameters, Parameters);

	SetListParameters(Vendors,      ListParameters);
	SetListParameters(SupplierPrices, ListParameters);

	CurrentDate = CurrentSessionDate();
	CurrencyExchangeRateManAccounting = ProcessingOfExchangeRatesTM.GetCurrencyRate(Constants.ManagementAccountingCurrency.Get(), CurrentDate);
	PriceConversionFactor = 1 / (CurrencyExchangeRateManAccounting.CourseNumerator / CurrencyExchangeRateManAccounting.CourseDenominator);

	Attributes = Common.ObjectAttributesValues(Parameters.Products, "VATRate, UnitOfMeasure");
	VATRate_2 = 1 + PriceManagementSystemClientServer.GetVATRateAsNumber(Attributes.VATRate)/100;
	UnitOfMeasure = Attributes.UnitOfMeasure;
	CurrencyOfManAccounting = Constants.ManagementAccountingCurrency.Get();
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.ItemsPricesOfVendor.SliceLast";
	ListProperties.DynamicDataRead = False;
	ListProperties.QueryText = StrReplace(SupplierPrices.QueryText,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"PricesOverridable.Package",
		"PricesOverridable.Products"));
	Common.SetDynamicListProperties(Items.SupplierPrices,
	ListProperties);
		
	SupplierPrices.Parameters.SetParameterValue("PriceDate_",                 CurrentDate);
	SupplierPrices.Parameters.SetParameterValue("PriceConversionFactor", PriceConversionFactor);
	SupplierPrices.Parameters.SetParameterValue("VATRate_2",           VATRate_2);
	
	// Customize the appearance of the form.
	Items.PriceManAccounting.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đơn giá (%1)';
			|ru = 'Цена (%1)';
			|en = 'Price (%1)'; fa = 'Price (%1)';
			|it = 'Prezzo (%1)';
			|pl = 'Cena (%1)';
			|tr = 'Fiyat (%1)'"), String(CurrencyOfManAccounting));
	
	Position = String(Parameters.Products) +
		?(ValueIsFilled(Parameters.Characteristic), ", " + String(Parameters.Characteristic), "");
		
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chọn nhà cung cấp cho mặt hàng: %1';
			|ru = 'Выбор поставщика для позиции: %1';
			|en = 'Select vendor for item: %1'; fa = 'Select vendor for item: %1';
			|it = 'Selezione del fornitore per la voce: %1';
			|pl = 'Wybór dostawcy dla pozycji: %1';
			|tr = 'Pozisyon için tedarikçi seçimi: %1'"), Position);
	
	SetDefaultButton();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)

	SetDefaultButton();

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplierPrices

&AtClient
Procedure SupplierPricesSelection(Item, RowSelected, Field, StandardProcessing)

	StandardProcessing = False;
	SelectOnClient();

EndProcedure

&AtClient
Procedure VendorStartChoice(Item, ChoiceData, StandardProcessing)

	StandardProcessing = False;

EndProcedure

&AtClient
Procedure VendorClearing(Item, StandardProcessing)

	StandardProcessing = False;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersVendors

&AtClient
Procedure VendorsSelection(Item, RowSelected, Field, StandardProcessing)

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

&AtClient
Procedure SelectOnClient()

	ProviderParameters = New Structure("Partner");
	ProviderParameters.Insert("Terms", PredefinedValue("Catalog.TermsOfPurchaseFromVendors.EmptyRef"));
	ProviderParameters.Insert("PriceInTheCurrencyOfManagementAccounting", 0);
	ProviderParameters.Insert("PriceInTheCurrencyOfAgreement",           0);
	ProviderParameters.Insert("Currency", PredefinedValue("Catalog.Currencies.EmptyRef"));
	ProviderParameters.Insert("VendorPriceKind", PredefinedValue("Catalog.VendorPriceTypes.EmptyRef"));
	ProviderParameters.Insert("OrderPackage", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	ProviderParameters.Insert("MinimumDeliveryLot",       0);
	
	If Items.Pages.CurrentPage = Items.SuppliersPage Then
		
		If Items.Vendors.CurrentData = Undefined Then
			Return;
		EndIf;
		
		Partner = Items.Vendors.CurrentData.Vendor;
		PurchaseConditions = PartnerSTermsOfPurchase(Partner);
		
		ProviderParameters.Insert("Partner",     Partner);
		ProviderParameters.Insert("Terms",  PurchaseConditions.Terms);
		ProviderParameters.Insert("Currency",      PurchaseConditions.Currency);
		
	Else
		
		If Items.SupplierPrices.CurrentData = Undefined Then
			Return;
		EndIf;
		
		CurrentRow = Items.SupplierPrices.CurrentData;
		PurchaseConditions = PartnerSTermsOfPurchase(CurrentRow.Partner, CurrentRow.PriceManAccounting);
		
		ProviderParameters.Insert("Partner",               CurrentRow.Partner);
		ProviderParameters.Insert("Terms",            PurchaseConditions.Terms);
		ProviderParameters.Insert("Currency",                PurchaseConditions.Currency);
		ProviderParameters.Insert("PriceInTheCurrencyOfAgreement", PurchaseConditions.Price);
		
		ProviderParameters.Insert("PriceInTheCurrencyOfManagementAccounting", CurrentRow.PriceManAccounting);
		ProviderParameters.Insert("VendorPriceKind",               CurrentRow.PriceKind);
		ProviderParameters.Insert("Package",                        CurrentRow.OrderPackage);
		ProviderParameters.Insert("MinimumDeliveryLot",       CurrentRow.MinimumDeliveryLot);
		
	EndIf;
	
	Result = New Structure("ProviderParameters", ProviderParameters);
	NotifyChoice(Result);

EndProcedure

&AtClientAtServerNoContext
Procedure SetListParameters(List, Parameters)

	For Each Property In Parameters Do
		CommonClientServer.SetDynamicListParameter(List, Property.Key, Property.Value, True);
	EndDo;

EndProcedure

&AtServer
Procedure SetDefaultButton()

	Button = ?(Items.Pages.CurrentPage = Items.PageSelectionByPrice, Items.SelectASupplierWithAnAgreement,
		?(Items.Pages.CurrentPage = Items.SuppliersPage, Items.SelectASupplier, Undefined));
	Button.DefaultButton = True;

EndProcedure

&AtServerNoContext
Function PartnerSTermsOfPurchase(Partner, Price = 0)

	CurrencyOfManAccounting_ = Constants.ManagementAccountingCurrency.Get();
	Result = New Structure("Terms, Currency, Price",
		Catalogs.TermsOfPurchaseFromVendors.EmptyRef(), CurrencyOfManAccounting_, Price);

	ZoomRatio = 1;
	PurchaseConditions = PurchasesServer.GetDefaultPurchaseTerms(Partner);
	If PurchaseConditions <> Undefined And ValueIsFilled(PurchaseConditions.Terms) Then
		Result.Terms = PurchaseConditions.Terms;
		Result.Currency = PurchaseConditions.Currency;
		ZoomRatio = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
			CurrencyOfManAccounting_, PurchaseConditions.Currency, CurrentSessionDate());
		Result.Price = Result.Price * ZoomRatio;
	EndIf;

	Return Result;

EndFunction

#EndRegion
