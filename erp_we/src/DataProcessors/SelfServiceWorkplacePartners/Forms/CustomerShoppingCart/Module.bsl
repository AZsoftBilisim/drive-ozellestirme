#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	BalanceViewIsAvailable = SelfServiceServer.YouCanViewBalancesInSelection();
	TMCommonUseClientServer.SetFormItemProperty(Items, "CustomerShoppingCartAvailableNow", "Visible", BalanceViewIsAvailable);
	TMCommonUseClientServer.SetFormItemProperty(Items, "CustomerShoppingCartStockAvailability", "Visible", 
	                                                               AccessRight("View", Metadata.Reports.StockAvailability));
	ToUseTermsOfSales = GetFunctionalOption("ToUseTermsOfSales");
	
	FillPropertyValues(ThisObject, PartnersAndCounterpartiesServerCall.DataOfAuthorizedExternalUser());
	
	If Partner = Undefined Or Partner.IsEmpty() Then
		Cancel = True;
		Return;
		
		If Not PartnerAuthorized
			And (ContactPerson = Undefined Or ContactPerson.IsEmpty()) Then
			Return;
		EndIf;
		
	EndIf;
	
	If ToUseTermsOfSales Then
		
		TMCommonUseClientServer.SetFormItemProperty(Items, "WarningGroup", "Visible", False);
		
		LoadSettings();
		
		If Terms.IsEmpty() Then
			SetFormDetailsForSelection(SelfServiceServer.GetDefaultPartnerAgreement(Partner, BusinessOperation));
		EndIf;
		
	EndIf;
	
	FillInBasketTableAccordingToRegister();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	RecalcTotals();
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And Exit Then
		Cancel = True;
		WarningText = NStr("vi = 'Đã thay đổi dữ liệu của giỏ hàng. Sẽ mất tất cả thay đổi.';
							|ru = 'Данные корзины были изменены. Все изменения будут потеряны.';
							|en = 'Cart data has changed. All changes will be lost.'; fa = 'Cart data has changed. All changes will be lost.';
							|it = 'I dati del carrello sono stati modificati. Tutte le modifiche verranno perse.';
							|pl = 'Dane koszyka zostały zmienione. Wszystkie zmiany zostaną utracone.';
							|tr = 'Sepet verileri değiştirildi. Tüm değişiklikler kaybolacaktır.'");
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If Not Exit Then
		PerformActionsWhenClosingFormOnServer();
		NotifyAboutChangesToBuyerSShoppingCart();
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		
		If TypeOf(ValueSelected) = Type("Structure") And ValueSelected.Property("GoodsAddressInStorage") Then
			CustomerProductSelectionProcessing(ValueSelected.GoodsAddressInStorage);
			Modified = True;
			ProcessBucketDataChanges()
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_SalesOrder" 
		And Parameter.Property("AuthorizationObject") 
		And Parameter.AuthorizationObject = ?(PartnerAuthorized, Partner, ContactPerson) Then
		FillInBasketTableAccordingToRegister();
		ShowMessageBox( ,NStr("vi = 'Đã tạo đơn hàng, có thể tham khảo với trạng thái này trong các đơn hàng của bạn trong phần Đơn hàng.';
								|ru = 'Ваш заказ оформлен, ознакомиться с текущим состоянием ваших заказов можно в разделе Заказы.';
								|en = 'Your order is registered; you can find out the current state of your orders in the Orders section.'; fa = 'Your order is registered; you can find out the current state of your orders in the Orders section.';
								|it = 'Il vostro ordine è stato formalizzato, è possibile prendere visione dello stato corrente dei vostri ordini nella sezione Ordini.';
								|pl = 'Twoje zamówienie utworzono, zaznajomić się z biezącym statusem twoich zamówień można w rozdziale Zamówienia.';
								|tr = 'Siparişiniz düzenlendi, siparişlerinizin güncel durumunu Siparişler bölümünden görüntüleyebilirsiniz.'"));
		ProcessBucketDataChanges();
		Modified = False;
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		Modified = True;
		ProcessBucketData();
		ProcessBucketDataChanges();
	EndIf;
	
	If EventName = "EditSet" Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns());
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", VATTaxation);
		OpeningParameters.Insert("Currency", Currency);
		OpeningParameters.Insert("Terms", Terms);
		OpeningParameters.Insert("Date", CommonClient.SessionDate());
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("ProhibitionOfSetContent", True);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TermsStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	SelectionResult = Undefined;

	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.SelectTermsOfSales",
	            New Structure("Partner,Terms",Partner,Terms),
	            ThisForm,,,, New CallbackDescription("TermsStartChoiceCompletion", ThisObject),
	            FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtClient
Procedure TermsClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	AvailabilityControl();
	FillInBucketTableWhenChangingHeaderDetails();
	
EndProcedure

&AtClient
Procedure PurchaseByCommissionOnChange(Item)
	
	If PurchaseByCommission Then
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent");
	Else
		BusinessOperation = PredefinedValue("Enum.BusinessTransactions.SaleToCustomer");
	EndIf;
	PurchaseByCommissionOnChangeServer();
	
EndProcedure

&AtClient
Procedure WarehouseClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCustomerShoppingCart

&AtClient
Procedure CustomerShoppingCartPackageOnChange(Item)
	
	CurrentRow = Items.CustomerShoppingCart.CurrentData;
	
	VATStructure = New Structure("PriceIncludesVAT",PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert("FillInSalePrice",New Structure("Currency,Date",Currency,CommonClient.SessionDate()));
	EndIf;
	
	StructureOfActions.Insert("RecalculateVATAmount", VATStructure);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", VATStructure);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure CustomerShoppingCartNumberOfPackagesOnChange(Item)
	
	CurrentSessionDate = CommonClient.SessionDate();
	
	CurrentRow = Items.CustomerShoppingCart.CurrentData;
	
	VATStructure = New Structure("PriceIncludesVAT",PriceIncludesVAT);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", VATStructure);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", VATStructure);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

	If CurrentRow.Enabled = NStr("vi = 'Có sẵn';
								|ru = 'В наличии';
								|en = 'In stock'; fa = 'موجود در انبار';
								|it = 'In disposizione';
								|pl = 'Dostępny towar';
								|tr = 'Stokta'")
		Or CurrentRow.Enabled = NStr("vi = 'Cần làm chính xác';
									|ru = 'Требует уточнения';
									|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
									|it = 'Richiede chiarimenti';
									|pl = 'Wymaga uściślenia';
									|tr = 'Netleştirme gerekiyor'") And CurrentRow.Available > 0 Then

		If CurrentRow.Available > 0 Then

			If CurrentRow.Period = BegOfDay(CurrentSessionDate) Then

				If CurrentRow.Count/CurrentRow.Available < 0.5 Then
					CurrentRow.Enabled = NStr("vi = 'Có sẵn';
												|ru = 'В наличии';
												|en = 'In stock'; fa = 'موجود در انبار';
												|it = 'In disposizione';
												|pl = 'Dostępny towar';
												|tr = 'Stokta'");
				Else
					CurrentRow.Enabled = NStr("vi = 'Cần làm chính xác';
												|ru = 'Требует уточнения';
												|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
												|it = 'Richiede chiarimenti';
												|pl = 'Wymaga uściślenia';
												|tr = 'Netleştirme gerekiyor'");
				EndIf;

			Else
				CurrentRow.Enabled = NStr("vi = 'Đang chờ';
											|ru = 'Ожидается';
											|en = 'Expected'; fa = 'مورد انتظار';
											|it = 'Previsto';
											|pl = 'Oczekiwane';
											|tr = 'Beklenen'") + " " + Format(CurrentRow.Period,"DLF=D");
			EndIf;

		Else

			If CurrentRow.ShipmentDate < BegOfDay(CurrentSessionDate) Then
				CurrentRow.Enabled = NStr("vi = 'Không có trong kho';
											|ru = 'Нет на складе';
											|en = 'Out of stock'; fa = 'Out of stock';
											|it = 'Non in magazzino';
											|pl = 'Niema w magazynie';
											|tr = 'Ambarda mevcut değil'");
			Else
				CurrentRow.Enabled = NStr("vi = 'Đang chờ';
											|ru = 'Ожидается';
											|en = 'Expected'; fa = 'مورد انتظار';
											|it = 'Previsto';
											|pl = 'Oczekiwane';
											|tr = 'Beklenen'") + " " + Format(CurrentRow.ShipmentDate,"DLF=D");
			EndIf;

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure CustomerShoppingCartOnChange(Item)
	
	ProcessBucketDataChanges();
	
EndProcedure

&AtClient
Procedure CustomerShoppingCartToRegisterOnChange(Item)
	
	CurrentData = Items.CustomerShoppingCart.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.ProductsInSet) Then
		
		SetParameters = New Structure;
		SetParameters.Insert("ProductsInSet",   CurrentData.ProductsInSet);
		SetParameters.Insert("ItemVariantOfSet", CurrentData.ItemVariantOfSet);
		
		FoundRows = CustomerShoppingCart.FindRows(SetParameters);
		For Each FoundRow In FoundRows Do
			 FoundRow.ToRegister = CurrentData.ToRegister;
		EndDo;
		
	EndIf;
	
	AvailabilityControl();
	
EndProcedure

&AtClient
Procedure CustomerShoppingCartBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	
EndProcedure

&AtClient
Procedure CustomerShoppingCartSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "CustomerShoppingCartProducts" 
		Or Field.Name = "CustomerShoppingCartCharacteristic" Then
		
		OpenProductItemCard();
		
	ElsIf Field.Name = "CustomerShoppingCartProductsInSet" 
		Or Field.Name = "CustomerShoppingCartItemVariantOfSet" Then
		
		OpenRecruitmentCard();
		
	ElsIf SetsClient.ItemToLock(Field) Then
		
		CurrentRow = CustomerShoppingCart.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			Notify("EditSet", NotificationParameter1, ThisForm);
			
		EndIf;
		
	ElsIf Field = Items.CustomerShoppingCartProductsInSet Then
		
		ShowValue(Undefined, Items.CustomerShoppingCart.CurrentData.ProductsInSet);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CustomerShoppingCartBeforeDeleteRow(Item, Cancel)
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisForm, "CustomerShoppingCart", Cancel);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectGoods(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"DataProcessor.SelfServiceWorkplacePartners.CustomerShoppingCart.Command.SelectGoods");
	
	FormParameters = New Structure;
	FormParameters.Insert("TransferHeader",       NStr("vi = 'Chuyển vào giỏ hàng';
														|ru = 'Перенести в корзину';
														|en = 'Put into the shopping cart'; fa = 'Put into the shopping cart';
														|it = 'Spostare nel carrello';
														|pl = 'Przenieś do koszyka';
														|tr = 'Sepete taşı'"));
	FormParameters.Insert("Document",                 "SelfServiceWorkplacePartners");
	FormParameters.Insert("Terms",               Terms);
	FormParameters.Insert("Warehouse",                    Warehouse);
	FormParameters.Insert("Currency",                   Currency);
	FormParameters.Insert("Title",                NStr("vi = 'Chọn hàng vào giỏ';
														|ru = 'Подбор товаров в корзину';
														|en = 'Add goods to the shopping cart'; fa = 'Add goods to the shopping cart';
														|it = 'Selezione delle merci nel carrello';
														|pl = 'Wybór towarów do koszyka';
														|tr = 'Sepete ürünlerin seçimi'"));
	FormParameters.Insert("ProductSegment",      ProductSegment);
	FormParameters.Insert("BusinessOperation",    BusinessOperation);
	FormParameters.Insert("VATTaxation",       VATTaxation);
	FormParameters.Insert("HideCommandRemainingQuantityInWarehouses", ?(BalanceViewIsAvailable, False, True));
	FormParameters.Insert("PriceIncludesVAT",          PriceIncludesVAT);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form",
	             SelfServiceClient.StructureOfParametersForSelection(FormParameters),
	             ThisForm, UUID);
	
	ProcessBucketDataChanges();
	
EndProcedure

&AtClient
Procedure ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.Organization = Organization;
	ImportParameters.AmountsRecalculate = False;
	ImportParameters.FilterParameters.Insert("ProductSegment", ProductSegment);
	If BusinessOperation = PredefinedValue("Enum.BusinessTransactions.TransferToCommissionAgent") Then
		ImportParameters.FilterParameters.Insert("ItemsType",
			ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	EndIf;
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		GetUploadedProductsFromStorage(ImportedDataAddress);
		Modified = True;
		ProcessBucketDataChanges();
	EndIf;
	
EndProcedure

&AtClient
Procedure RegisterOrder(Command)
	
	PerformRegisterEntryShoppingCartBuyer();
	
	FormParameters = New Structure;
	FormParameters.Insert("Partner",Partner);
	FormParameters.Insert("ContactPerson", ContactPerson);
	FormParameters.Insert("PartnerAuthorized", PartnerAuthorized);
	FormParameters.Insert("Terms",Terms);
	FormParameters.Insert("Warehouse",Warehouse);
	AddressTrashTemporaryStorage =AddressOfTemporaryStorageWithBucket();
	FormParameters.Insert("BucketAddress",AddressTrashTemporaryStorage);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.OrderGenerationWizard",FormParameters,ThisForm);
	
EndProcedure

&AtClient
Procedure SaveCartData(Command)
	
	If Modified Then
		PerformRegisterEntryShoppingCartBuyer();
		NotifyAboutChangesToBuyerSShoppingCart();
		Modified = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetMarksForRegistration(Command)
	
	For Each String In CustomerShoppingCart Do
		String.ToRegister = True;
	EndDo;
	ProcessBucketDataChanges()
	
EndProcedure

&AtClient
Procedure ClearMarksForRegistration(Command)
	
	For Each String In CustomerShoppingCart  Do
		String.ToRegister = False;
	EndDo;
	ProcessBucketDataChanges();
	
EndProcedure

&AtClient
Procedure StockInWarehouses(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BucketData",CustomerShoppingCart);
	FormParameters.Insert("Terms",Terms);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.StockInWarehouses", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure PricesAmountsByTermsOfSales(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("BucketData",CustomerShoppingCart);
	FormParameters.Insert("Partner",Partner);
	FormParameters.Insert("Terms",Terms);
	FormParameters.Insert("Currency",Currency);
	FormParameters.Insert("PriceIncludesVAT",PriceIncludesVAT);
	FormParameters.Insert("VATTaxation",VATTaxation);
	
	OpenForm("DataProcessor.SelfServiceWorkplacePartners.Form.PricesAmountsByTermsOfSales", FormParameters, ThisForm);
	
EndProcedure

&AtClient
Procedure OpenGoodsProfile(Command)
	
	OpenProductItemCard()
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.CustomerShoppingCart.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = CustomerShoppingCart.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Küme kompozisyonunun açılması sadece bir küme için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns());
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("PriceIncludesVAT", PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", VATTaxation);
	OpeningParameters.Insert("Currency", Currency);
	OpeningParameters.Insert("Terms", Terms);
	OpeningParameters.Insert("Date", CommonClient.SessionDate());
	OpeningParameters.Insert("ProhibitPriceEditing", True);
	OpeningParameters.Insert("ProhibitionOfSetContent", True);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisForm, UUID);
	
EndProcedure

&AtClient
Procedure StockAvailability(Command)
	
	SelfServiceClient.OpenProductBalancesAndAvailabilityReport(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CustomerShoppingCartPrice.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CustomerShoppingCart.Price");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	FilterGroup2 = FilterGroup1.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup2.GroupType = DataCompositionFilterItemsGroupType.AndGroup;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CustomerShoppingCart.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = FilterGroup2.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsSubjectToUTII;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.SpecialTextColor);

	//

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "CustomerBasketUnitOfMeasurement";
	ConditionalDesignParameters.PathToPackagingUnitField = "CustomerShoppingCart.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisForm, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CustomerShoppingCartCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CustomerShoppingCart.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));

	//
	
	SetsServer.SetConditionalAppearance(ThisForm, "CustomerShoppingCart", True);
	
EndProcedure

#Region Settings

&AtServer
Procedure ShouldSaveSettings()
	
	Settings = New Structure;
	Settings.Insert("Terms",Terms);
	Settings.Insert("Warehouse",Warehouse);
	
	Common.CommonSettingsStorageSave("DataProcessors.SelfServiceWorkplacePartners", "CustomerShoppingCart", Settings);
	
EndProcedure

&AtServer
Procedure LoadSettings()
	
	Var SavedSettingsAgreement;
	Var StoreSavedSettings;
	
	SettingsValue = Common.CommonSettingsStorageLoad("DataProcessors.SelfServiceWorkplacePartners", "CustomerShoppingCart");
	If TypeOf(SettingsValue) = Type("Structure") And SettingsValue.Property("Terms") Then
		SettingsValue.Property("Terms",SavedSettingsAgreement);
	EndIf;
	
	If Not ValueIsFilled(BusinessOperation) Then
		BusinessOperation = Enums.BusinessTransactions.SaleToCustomer;
	EndIf; 
	
	If SavedSettingsAgreement <> Undefined
		And Not SavedSettingsAgreement.IsEmpty() Then
		
		UseStandardTermsOfSalesWithCustomers			= GetFunctionalOption("UseStandardTermsOfSalesWithCustomers");
		UseCustomerTermsOfSales	= GetFunctionalOption("UseCustomerTermsOfSales");
		OnlyStandard = UseStandardTermsOfSalesWithCustomers And Not UseCustomerTermsOfSales;
		OnlyPersonal = Not UseStandardTermsOfSalesWithCustomers And UseCustomerTermsOfSales;
		
		If OnlyStandard And Not SavedSettingsAgreement.Standard_
			Or OnlyPersonal And SavedSettingsAgreement.Standard_ Then
			SavedSettingsAgreement = Undefined;
			SettingsValue.Property("Terms",SavedSettingsAgreement);
			Return;
		EndIf;
		
		SetFormDetailsForSelection(SelfServiceServer.AgreementIsValidForPartner(SavedSettingsAgreement,Partner));
		
		SettingsValue.Property("Warehouse",StoreSavedSettings); 
		If Not WarehouseIsDeterminedByTheAgreement And StoreSavedSettings <> Undefined 
			And Not StoreSavedSettings.IsEmpty() And Not StoreSavedSettings = Warehouse Then
			
			Query = New Query;
			Query.Text = "
			|SELECT ALLOWED
			|	Warehouses.Ref
			|FROM
			|	Catalog.Warehouses AS Warehouses
			|WHERE
			|	Warehouses.Ref = &Warehouse
			|	AND CASE
			|			WHEN &WarehouseIsDeterminedByTheAgreement
			|				THEN Warehouses.Ref IN HIERARCHY (&AgreementWarehouse_)
			|			ELSE TRUE
			|		END";
			
			Query.SetParameter("Warehouse",StoreSavedSettings);
			Query.SetParameter("AgreementWarehouse_",Warehouse);
			Query.SetParameter("WarehouseIsDeterminedByTheAgreement", WarehouseIsDeterminedByTheAgreement);
			
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				Warehouse = StoreSavedSettings;
			EndIf;
		EndIf;
		
	EndIf;
	
	PurchaseByCommission = (BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent);
	
EndProcedure

#EndRegion

#Region GeneratingRequests

&AtServer
Function RequestTextBucketDataByCase()
	
	QueryText=
	"SELECT ALLOWED
	|	CustomerShoppingCart.ProductsInSet,
	|	CustomerShoppingCart.ItemVariantOfSet,
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic,
	|	CustomerShoppingCart.Package,
	|	CustomerShoppingCart.NumberOfPackages,
	|	CustomerShoppingCart.Price AS BasketPrice,
	|	CustomerShoppingCart.PutFileDate,
	|	CustomerShoppingCart.Currency,
	|	&VATRate AS VATRate,
	|	CAST(&VATRate AS Catalog.VATRates).Rate1 / 100 AS ValueOfVATRate,
	|	CatProducts.PriceGroup,
	|	CustomerShoppingCart.ToRegister,
	|	ISNULL(ExcisableGoodsCategories.ExcisableGoods, FALSE) AS ExcisableGoods
	|INTO BucketData
	|FROM
	|	InformationRegister.CustomerShoppingCart AS CustomerShoppingCart
	|		LEFT JOIN Catalog.Products AS CatProducts
	|		ON CustomerShoppingCart.Products = CatProducts.Ref
	|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
	|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
	|		ON CustomerShoppingCart.Products = ProductsVATRates.Products
	|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
	|		ON (TRUE)
	|		LEFT JOIN InformationRegister.ExcisableGoodsCategories.SliceLast(&Date,
	|			&UseExcisableGoods AND Country = &RegistrationCountry) AS ExcisableGoodsCategories
	|		ON CustomerShoppingCart.Products = ExcisableGoodsCategories.Products
	|WHERE
	|	CustomerShoppingCart.AuthorizationObject = &AuthorizationObject
	|
	|;
	|//////////////////////////////////////////////////////////////////////////////////////////////////////
	|";
	
	QueryText = StrReplace(QueryText, "&VATRate", VATAccountingERP.QueryTextVATRate("&VATTaxation", "CatProducts"));
	
	Return QueryText;
	
EndFunction

&AtServer
Function RequestTextDataOnAvailabilityOfGoodsInStock()
	
	QueryText =
	"SELECT
	|	DataOnIMUZAvailability.Warehouse AS Warehouse,
	|	DataOnIMUZAvailability.ProductsInSet AS ProductsInSet,
	|	DataOnIMUZAvailability.ItemVariantOfSet AS ItemVariantOfSet,
	|	DataOnIMUZAvailability.Products AS Products,
	|	DataOnIMUZAvailability.Characteristic AS Characteristic,
	|	DataOnIMUZAvailability.Period AS Period,
	|	DataOnIMUZAvailability.Available AS Available,
	|	ISNULL(DatesOfScheduledDelivery.Date, DATETIME(1, 1, 1))  AS ShipmentDate,
	|	CASE
	|		WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN &SelectWarehouseLine
	|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|			THEN &ThisServiceIsAvailable
	|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|			THEN &JobLineIsAvailable
	|		WHEN DataOnIMUZAvailability.MUSES = VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
	|			THEN &StringAvailableOnOrder
	|		WHEN NOT CAST(DataOnIMUZAvailability.Warehouse AS Catalog.Warehouses).AvailableStockControl
	|			THEN &LineNeedsToBeClarified
	|		ELSE &LineAccordingToGraph
	|	END AS Enabled,
	|	CustomerShoppingCart.Package AS Package,
	|	CustomerShoppingCart.NumberOfPackages AS NumberOfPackages,
	|	CatalogProducts.UnitOfMeasure AS UnitOfMeasure,
	|	CASE
	|		WHEN ProductPackages.Ref IS NULL 
	|			THEN CustomerShoppingCart.NumberOfPackages
	|		ELSE CustomerShoppingCart.NumberOfPackages * &QueryTextPackagingFactor
	|	END AS Count
	|INTO AvailabilityData_
	|FROM
	|	DataOnIMUZAvailability AS DataOnIMUZAvailability
	|
	|		LEFT JOIN Warehouses AS Warehouses
	|		ON DataOnIMUZAvailability.Warehouse = Warehouses.Ref
	|
	|		INNER JOIN BucketData AS CustomerShoppingCart
	|			LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
	|			ON CustomerShoppingCart.Package = ProductPackages.Ref
	|		ON DataOnIMUZAvailability.Products = CustomerShoppingCart.Products
	|		 AND DataOnIMUZAvailability.Characteristic = CustomerShoppingCart.Characteristic
	|		 AND DataOnIMUZAvailability.ProductsInSet = CustomerShoppingCart.ProductsInSet
	|		 AND DataOnIMUZAvailability.ItemVariantOfSet = CustomerShoppingCart.ItemVariantOfSet
	|
	|		INNER JOIN Catalog.Products AS CatalogProducts
	|			LEFT JOIN Catalog.ItemKinds AS ItemKinds
	|			ON CatalogProducts.ProductKind = ItemKinds.Ref
	|		ON DataOnIMUZAvailability.Products = CatalogProducts.Ref
	|
	|		LEFT JOIN TTScheduledDeliveryDate AS DatesOfScheduledDelivery
	|		ON DatesOfScheduledDelivery.Products = DataOnIMUZAvailability.Products
	|			AND DatesOfScheduledDelivery.Characteristic = DataOnIMUZAvailability.Characteristic
	|			AND DatesOfScheduledDelivery.Warehouse = DataOnIMUZAvailability.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"CatalogProducts"));
	Return QueryText;
EndFunction

&AtServer
Function QueryTextBucketDataByTablePart(ThereIsLoadingTableData)
	
	If Not ThereIsLoadingTableData Then
		
		QueryText=
		"SELECT
		|	BucketData.ProductsInSet,
		|	BucketData.ItemVariantOfSet,
		|	BucketData.Products,
		|	BucketData.Characteristic,
		|	BucketData.Package,
		|	BucketData.NumberOfPackages,
		|	BucketData.Price,
		|	BucketData.ToRegister,
		|	BucketData.PutFileDate,
		|	BucketData.Currency,
		|	BucketData.ExcisableGoods
		|INTO CustomerShoppingCart
		|FROM
		|	&BucketData AS BucketData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|"
		+ ExcisableGoodsAccounting.QueryTextTTExcisableItems("CustomerShoppingCart", , "RegistrationCountry")
		+ Common.QueryBatchSeparator() + "
		|SELECT
		|	CustomerShoppingCart.ProductsInSet,
		|	CustomerShoppingCart.ItemVariantOfSet,
		|	CustomerShoppingCart.Products,
		|	CustomerShoppingCart.Characteristic,
		|	CustomerShoppingCart.Package,
		|	CustomerShoppingCart.NumberOfPackages,
		|	CustomerShoppingCart.Price,
		|	CustomerShoppingCart.ToRegister,
		|	CustomerShoppingCart.PutFileDate,
		|	CustomerShoppingCart.Currency,
		|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods,
		|	&VATRate AS VATRate,
		|	CAST(&VATRate AS Catalog.VATRates).Rate1 / 100 AS ValueOfVATRate,
		|	CatProducts.PriceGroup
		|INTO BucketData
		|FROM
		|	CustomerShoppingCart AS CustomerShoppingCart
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON CustomerShoppingCart.Products = CatProducts.Ref
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON CustomerShoppingCart.Products = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)
		|		LEFT JOIN TTExcisableItems AS TTExcisableItems
		|		ON CustomerShoppingCart.Products = TTExcisableItems.Products
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		QueryText = StrReplace(QueryText, "&VATRate", VATAccountingERP.QueryTextVATRate("&VATTaxation", "CatProducts"));
		
		Return QueryText;
		
	Else
		
		QueryText =
		"SELECT
		|	BucketData.ProductsInSet,
		|	BucketData.ItemVariantOfSet,
		|	BucketData.Products,
		|	BucketData.Characteristic,
		|	BucketData.Package,
		|	BucketData.NumberOfPackages,
		|	BucketData.Price,
		|	BucketData.ToRegister,
		|	BucketData.PutFileDate,
		|	BucketData.Currency,
		|	BucketData.ExcisableGoods
		|INTO BasketTable
		|FROM
		|	&BucketData AS BucketData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DownloadData.ProductsInSet,
		|	DownloadData.ItemVariantOfSet,
		|	DownloadData.Products,
		|	DownloadData.Characteristic,
		|	DownloadData.Package,
		|	DownloadData.NumberOfPackages,
		|	DownloadData.Price
		|INTO TableOfLoadedProducts
		|FROM
		|	&DownloadData AS DownloadData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|"
		+ ExcisableGoodsAccounting.QueryTextTTExcisableItems("TableOfLoadedProducts", , "RegistrationCountry")
		+ Common.QueryBatchSeparator() + "
		|SELECT
		|	BasketTable.ProductsInSet,
		|	BasketTable.ItemVariantOfSet,
		|	BasketTable.Products,
		|	BasketTable.Characteristic,
		|	BasketTable.Package,
		|	BasketTable.NumberOfPackages + ISNULL(TableOfLoadedProducts.NumberOfPackages, 0) AS NumberOfPackages,
		|	BasketTable.Price,
		|	BasketTable.ToRegister,
		|	BasketTable.PutFileDate,
		|	BasketTable.Currency,
		|	BasketTable.ExcisableGoods
		|INTO CustomerShoppingCart
		|FROM
		|	BasketTable AS BasketTable
		|		LEFT JOIN TableOfLoadedProducts AS TableOfLoadedProducts
		|		ON BasketTable.ProductsInSet = TableOfLoadedProducts.ProductsInSet
		|			AND BasketTable.ItemVariantOfSet = TableOfLoadedProducts.ItemVariantOfSet
		|			AND BasketTable.Products = TableOfLoadedProducts.Products
		|			AND BasketTable.Characteristic = TableOfLoadedProducts.Characteristic
		|			AND BasketTable.Package = TableOfLoadedProducts.Package
		|
		|UNION ALL
		|
		|SELECT
		|	TableOfLoadedProducts.ProductsInSet,
		|	TableOfLoadedProducts.ItemVariantOfSet,
		|	TableOfLoadedProducts.Products,
		|	TableOfLoadedProducts.Characteristic,
		|	TableOfLoadedProducts.Package,
		|	TableOfLoadedProducts.NumberOfPackages,
		|	0,
		|	TRUE,
		|	&CurrentDate,
		|	&Currency,
		|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods
		|FROM
		|	TableOfLoadedProducts AS TableOfLoadedProducts
		|		LEFT JOIN BasketTable AS BasketTable
		|		ON TableOfLoadedProducts.ProductsInSet = BasketTable.ProductsInSet
		|			AND TableOfLoadedProducts.ItemVariantOfSet = BasketTable.ItemVariantOfSet
		|			AND TableOfLoadedProducts.Products = BasketTable.Products
		|			AND TableOfLoadedProducts.Characteristic = BasketTable.Characteristic
		|			AND TableOfLoadedProducts.Package = BasketTable.Package
		|		LEFT JOIN TTExcisableItems AS TTExcisableItems
		|		ON TableOfLoadedProducts.Products = TTExcisableItems.Products
		|WHERE
		|	BasketTable.Products IS NULL 
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CustomerShoppingCart.ProductsInSet,
		|	CustomerShoppingCart.ItemVariantOfSet,
		|	CustomerShoppingCart.Products,
		|	CustomerShoppingCart.Characteristic,
		|	CustomerShoppingCart.Package,
		|	CustomerShoppingCart.NumberOfPackages,
		|	CustomerShoppingCart.Price,
		|	CustomerShoppingCart.ToRegister,
		|	CustomerShoppingCart.PutFileDate,
		|	CustomerShoppingCart.Currency,
		|	CustomerShoppingCart.ExcisableGoods,
		|	&VATRate AS VATRate,
		|	CAST(&VATRate AS Catalog.VATRates).Rate1 / 100 AS ValueOfVATRate,
		|	CatProducts.PriceGroup
		|INTO BucketData
		|FROM
		|	CustomerShoppingCart AS CustomerShoppingCart
		|		LEFT JOIN Catalog.Products AS CatProducts
		|		ON CustomerShoppingCart.Products = CatProducts.Ref
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON CustomerShoppingCart.Products = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)
		|";
		
		QueryText = StrReplace(QueryText, "&VATRate", VATAccountingERP.QueryTextVATRate("&VATTaxation", "CatProducts"));
		
		Return QueryText;
		
	EndIf;
	
EndFunction

&AtServer
Function QueryTextResultingFrom()
	
	If BalanceViewIsAvailable Then
		
		QueryText =
		"SELECT ALLOWED
		|	WarehouseStockBalance.Products AS Products,
		|	WarehouseStockBalance.Characteristic AS Characteristic,
		|	SUM(WarehouseStockBalance.Count) AS AvailableForInventoryAllocation
		|INTO TTAvailableProducts
		|FROM
		|	InformationRegister.InventoryAllocation AS WarehouseStockBalance
		|WHERE
		|	WarehouseStockBalance.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|	AND WarehouseStockBalance.InventoryState = VALUE(Enum.InventoryStates.InStock)
		|	AND WarehouseStockBalance.DemandCharacteristic IN(
		|		VALUE(Enum.DemandCharacteristics.SnoozeReservation),
		|		VALUE(Enum.DemandCharacteristics.ToSupply),
		|		VALUE(Enum.DemandCharacteristics.Surplus))
		|	AND WarehouseStockBalance.Warehouse IN
		|			(SELECT
		|				Warehouses.Ref
		|			FROM
		|				Warehouses AS Warehouses)
		|	AND (WarehouseStockBalance.Products, WarehouseStockBalance.Characteristic) IN
		|			(SELECT DISTINCT
		|				CustomerShoppingCart.Products AS Products,
		|				CustomerShoppingCart.Characteristic AS Characteristic
		|			FROM
		|				BucketData AS CustomerShoppingCart)
		|
		|GROUP BY
		|	WarehouseStockBalance.Products,
		|	WarehouseStockBalance.Characteristic
		|
		|INDEX BY
		|	Products,
		|	Characteristic
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	BucketData.ProductsInSet AS ProductsInSet,
		|	BucketData.ItemVariantOfSet AS ItemVariantOfSet,
		|	BucketData.Products AS Products,
		|	BucketData.Characteristic AS Characteristic,
		|	BucketData.Package AS Package,
		|	BucketData.NumberOfPackages AS NumberOfPackages,
		|	BucketData.ToRegister AS ToRegister,
		|	BucketData.VATRate AS VATRate,
		|	BucketData.Currency AS Currency,
		|	BucketData.PutFileDate AS PutFileDate,
		|	BucketData.ExcisableGoods AS ExcisableGoods,
		|	AvailabilityData_.Period AS Period,
		|	AvailabilityData_.ShipmentDate AS ShipmentDate,
		|	AvailabilityData_.Available AS Available,
		|	AvailabilityData_.Enabled AS Enabled,
		|	CASE
		|		WHEN ProductPackages.Ref IS NULL
		|			THEN BucketData.NumberOfPackages
		|		ELSE BucketData.NumberOfPackages * &QueryTextPackagingFactor
		|	END AS Count,
		|	CAST(ISNULL(AvailableStock.AvailableForInventoryAllocation, 0) / ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15, 3)) AS AvailableNow
		|FROM
		|	BucketData AS BucketData
		|		INNER JOIN AvailabilityData_ AS AvailabilityData_
		|		ON BucketData.Products = AvailabilityData_.Products
		|			AND BucketData.Characteristic = AvailabilityData_.Characteristic
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON BucketData.Package = ProductPackages.Ref
		|		LEFT JOIN TTAvailableProducts AS AvailableStock
		|		ON BucketData.Products = AvailableStock.Products
		|			AND BucketData.Characteristic = AvailableStock.Characteristic
		|
		|ORDER BY
		|	PutFileDate DESC
		|TOTALS BY
		|	ProductsInSet,
		|	ItemVariantOfSet,
		|	Products,
		|	Characteristic,
		|	Package,
		|	Enabled,
		|	Available,
		|	Period";
		
	Else
		
		QueryText = "
		|SELECT
		|	BucketData.ProductsInSet AS ProductsInSet,
		|	BucketData.ItemVariantOfSet AS ItemVariantOfSet,
		|	BucketData.Products AS Products,
		|	BucketData.Characteristic AS Characteristic,
		|	BucketData.Package AS Package,
		|	BucketData.NumberOfPackages,
		|	BucketData.ToRegister,
		|	BucketData.VATRate,
		|	BucketData.Currency,
		|	BucketData.PutFileDate AS PutFileDate,
		|	BucketData.ExcisableGoods,
		|	AvailabilityData_.Period AS Period,
		|	AvailabilityData_.ShipmentDate AS ShipmentDate,
		|	AvailabilityData_.Available AS Available,
		|	AvailabilityData_.Enabled AS Enabled,
		|	CASE
		|		WHEN ProductPackages.Ref IS NULL 
		|			THEN BucketData.NumberOfPackages
		|		ELSE BucketData.NumberOfPackages * &QueryTextPackagingFactor
		|	END AS Count,
		|	0 AS AvailableNow
		|FROM
		|	BucketData AS BucketData
		|		INNER JOIN AvailabilityData_ AS AvailabilityData_
		|		ON BucketData.Products = AvailabilityData_.Products
		|			AND BucketData.Characteristic = AvailabilityData_.Characteristic
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON BucketData.Package = ProductPackages.Ref
		|
		|ORDER BY
		|	PutFileDate DESC
		|TOTALS BY
		|	ProductsInSet,
		|	ItemVariantOfSet,
		|	Products,
		|	Characteristic,
		|	Package,
		|	Enabled,
		|	Available,
		|	Period";
		
	EndIf;
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductPackages",
			"BucketData.Products"));
	Return QueryText;
EndFunction

#EndRegion

#Region Other

&AtClient
Procedure AvailabilityControl()
	
	Items.Warehouse.Enabled = (ValueIsFilled(Terms) And Not WarehouseIsDeterminedByTheAgreement);
	ProductSelectionIsAvailable = ValueIsFilled(Terms) And ValueIsFilled(Warehouse);
	
	Items.CustomerShoppingCartStockInWarehouses.Enabled           = ProductSelectionIsAvailable;
	Items.CustomerShoppingCartStockAvailability.Enabled = ProductSelectionIsAvailable;
	Items.SelectGoods.Enabled                             = ProductSelectionIsAvailable;
	Items.ImportFromExternalFile.Enabled                    = ProductSelectionIsAvailable;
	
	CheckoutIsAvailable = CheckoutIsAvailable();
	Items.CustomerShoppingCartRegisterOrder.Enabled = CheckoutIsAvailable;
	Items.CustomerShoppingCartPricesAmountsByTermsOfSales.Enabled = CheckoutIsAvailable();
	
EndProcedure


// Fills in the form details based on the received data
// 
// Parameters:
// Selection - Undefined, Boolean, QueryResultSelection - LongDesc:
//  * Ref - DocumentRef -
//
&AtServer
Procedure SetFormDetailsForSelection(Selection)
	
	If Not Selection = Undefined Then
		
		Terms                       = Selection.Ref;
		FillPropertyValues(ThisForm, Selection);
		WarehouseIsDeterminedByTheAgreement        = ValueIsFilled(Selection.Warehouse) And Not Selection.ThisIsWarehouseGroup;
		TextPriceIncludesVAT             = SelfServiceServer.TextPriceIncludesVAT(ThisForm.PriceIncludesVAT);
		FillInSalesVATTaxation();
	Else
		Terms                       = Catalogs.TermsOfSale.EmptyRef();
		AgreementLine                 = "";
		Warehouse                            = Catalogs.Warehouses.EmptyRef();
		Currency                           = Catalogs.Currencies.EmptyRef();
		PriceIncludesVAT                  = False;
		ContractsAreUsed = False;
		WarehouseIsDeterminedByTheAgreement        = False;
		PurchaseByCommission                = False;
		BusinessOperation            = Enums.BusinessTransactions.SaleToCustomer;
		TextPriceIncludesVAT             = SelfServiceServer.TextPriceIncludesVAT(Undefined);
	EndIf;
	
	Items.PriceIncludesVAT.Visible = Not IsBlankString(TextPriceIncludesVAT);
	
	FillInDefaultValues(Selection);
	
EndProcedure

&AtServer
Procedure WhenChangingAgreementAtServer(SelectionResult)
	
	FillPropertyValues(ThisForm,SelectionResult,,"Warehouse");
	TextPriceIncludesVAT                = SelfServiceServer.TextPriceIncludesVAT(ThisForm.PriceIncludesVAT);
	Items.PriceIncludesVAT.Visible = Not IsBlankString(TextPriceIncludesVAT);
	
	WarehouseIsDeterminedByTheAgreement = ValueIsFilled(SelectionResult.Warehouse) And (Not SelectionResult.ThisIsWarehouseGroup);
	FillInDefaultValues(SelectionResult);
	If Not (ValueIsFilled(Warehouse) And Items.Warehouse.ChoiceList.FindByValue(Warehouse) <> Undefined) Then
		Warehouse = SelectionResult.Warehouse;
	EndIf;
	FillInSalesVATTaxation();
	If CustomerShoppingCart.Count() > 0 Then
		FillInBucketTableWhenChangingHeaderDetails();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInDefaultValues(Selection)

	SelfServiceServer.ManagingWarehouseFormElement(ThisForm, Selection, Items.Warehouse);
	Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	If Not ValueIsFilled(Currency) Then
		Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(
					Common.ObjectAttributeValue(Terms, "Organization"));
	EndIf;

EndProcedure

&AtClient
Function CheckoutIsAvailable()
	
	If Not ValueIsFilled(Terms) Or Not ValueIsFilled(Warehouse) Then
		Return False;
	EndIf;
	
	For Each String In CustomerShoppingCart Do
		If String.ToRegister And String.Price > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure ProductSelectionProcessingServer(GoodsAddressInStorage)
	
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage);
	
	If TableOfGoods.Count() > 0 Then
		
		ProcessAddingProducts(TableOfGoods);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessBucketData()

	For Each String In CustomerShoppingCart Do

		If ValueIsFilled(String.ProductsInSet) Then
			String.SetIndex = 1;
		EndIf;
		
		If String.Enabled = NStr("vi = 'Theo biên';
								|ru = 'Согласно графика';
								|en = 'According to the schedule'; fa = 'According to the schedule';
								|it = 'In conformità del grafico';
								|pl = 'Zgodnie z harmonogramem';
								|tr = 'Programa göre'") Then

			If String.Available > 0 Then

				If String.Period = BegOfDay(CurrentSessionDate()) Then

					If String.Count/String.Available < 0.5 Then
						String.Enabled = NStr("vi = 'Có sẵn';
												|ru = 'В наличии';
												|en = 'In stock'; fa = 'موجود در انبار';
												|it = 'In disposizione';
												|pl = 'Dostępny towar';
												|tr = 'Stokta'");
					Else
						String.Enabled = NStr("vi = 'Cần làm chính xác';
												|ru = 'Требует уточнения';
												|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
												|it = 'Richiede chiarimenti';
												|pl = 'Wymaga uściślenia';
												|tr = 'Netleştirme gerekiyor'");
					EndIf;

				Else
					String.Enabled = NStr("vi = 'Đang chờ';
											|ru = 'Ожидается';
											|en = 'Expected'; fa = 'مورد انتظار';
											|it = 'Previsto';
											|pl = 'Oczekiwane';
											|tr = 'Beklenen'") + " " + Format(String.Period,"DLF=D");
				EndIf;

			Else

				If String.ShipmentDate < BegOfDay(CurrentSessionDate()) Then
					String.Enabled = NStr("vi = 'Không có trong kho';
											|ru = 'Нет на складе';
											|en = 'Out of stock'; fa = 'Out of stock';
											|it = 'Non in magazzino';
											|pl = 'Niema w magazynie';
											|tr = 'Ambarda mevcut değil'");
				Else
					String.Enabled = NStr("vi = 'Đang chờ';
											|ru = 'Ожидается';
											|en = 'Expected'; fa = 'مورد انتظار';
											|it = 'Previsto';
											|pl = 'Oczekiwane';
											|tr = 'Beklenen'") + " " + Format(String.ShipmentDate,"DLF=D");
				EndIf;

			EndIf;

		EndIf;

	EndDo;

EndProcedure

&AtClient
Procedure CustomerProductSelectionProcessing(GoodsAddressInStorage)
	
	ProductSelectionProcessingServer(GoodsAddressInStorage);
	RecalcTotals();
	
EndProcedure

&AtServer
Procedure FillInBasketTableAccordingToRegister()
	
	If ValueIsFilled(Terms) Then
		SetParameterValuesRunRequest(True);
	Else
		
		Query = New Query;
		Query.Text = "SELECT ALLOWED
		|	CustomerShoppingCart.AuthorizationObject,
		|	CustomerShoppingCart.ProductsInSet,
		|	CustomerShoppingCart.ItemVariantOfSet,
		|	CustomerShoppingCart.Products,
		|	CustomerShoppingCart.Characteristic,
		|	CustomerShoppingCart.Package,
		|	CustomerShoppingCart.NumberOfPackages,
		|	CustomerShoppingCart.Price,
		|	CustomerShoppingCart.PutFileDate,
		|	CustomerShoppingCart.Currency,
		|	CustomerShoppingCart.ToRegister
		|FROM
		|	InformationRegister.CustomerShoppingCart AS CustomerShoppingCart
		|WHERE
		|	CustomerShoppingCart.AuthorizationObject = &AuthorizationObject";
		
		Query.SetParameter("AuthorizationObject",?(PartnerAuthorized, Partner, ContactPerson));
		
		CustomerShoppingCart.Load(Query.Execute().Unload());
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInBucketTableWhenChangingHeaderDetails()
	
	SetParameterValuesRunRequest(False);
	
EndProcedure

&AtServer
Procedure SetParameterValuesRunRequest(ByCase = True, TableOfGoods = Undefined)

	Query = New Query;
	Query.SetParameter("BucketData",FormAttributeToValue("CustomerShoppingCart"));
	Query.SetParameter("VATTaxation",VATTaxation);
	Query.SetParameter("PriceIncludesVAT",PriceIncludesVAT);
	Query.SetParameter("Terms",Terms);
	Query.SetParameter("Currency",Currency);
	Query.SetParameter("CurrentDate",BegOfDay(CurrentSessionDate()));
	Query.SetParameter("CurrentDayStart",BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("AuthorizationObject", ?(PartnerAuthorized, Partner, ContactPerson));
	Query.SetParameter("Partner",Partner);
	Query.SetParameter("SelectWarehouseLine",NStr("vi = 'Hãy chọn kho';
													|ru = 'Выберите склад';
													|en = 'Select warehouse'; fa = 'انتخاب انبار';
													|it = 'Seleziona un magazzino';
													|pl = 'Wybierz magazyn';
													|tr = 'Ambar seç'"));
	Query.SetParameter("StringAvailableOnOrder",NStr("vi = 'Được phép theo đơn hàng';
													|ru = 'Доступно под заказ';
													|en = 'Available to order'; fa = 'Available to order';
													|it = 'Disponibile su richiesta';
													|pl = 'Dostępne do zamówienia';
													|tr = 'Sipariş üzerine mevcut'"));
	Query.SetParameter("LineAccordingToGraph",NStr("vi = 'Theo biên';
													|ru = 'Согласно графика';
													|en = 'According to the schedule'; fa = 'According to the schedule';
													|it = 'In conformità del grafico';
													|pl = 'Zgodnie z harmonogramem';
													|tr = 'Programa göre'"));
	Query.SetParameter("LineNeedsToBeClarified",NStr("vi = 'Cần làm chính xác';
													|ru = 'Требует уточнения';
													|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
													|it = 'Richiede chiarimenti';
													|pl = 'Wymaga uściślenia';
													|tr = 'Netleştirme gerekiyor'"));
	Query.SetParameter("ThisServiceIsAvailable",NStr("vi = 'Dịch vụ sử dụng được';
													|ru = 'Услуга доступна';
													|en = 'The service is available'; fa = 'The service is available';
													|it = 'Servizio accessibile';
													|pl = 'Usługa jest dostępna';
													|tr = 'Hizmet erişilebilir'"));
	Query.SetParameter("JobLineIsAvailable",NStr("vi = 'Công việc khả dụng';
												|ru = 'Работа доступна';
												|en = 'Operation is available'; fa = 'Operation is available';
												|it = 'Lavoro accessibile';
												|pl = 'Praca jest dostępna';
												|tr = 'İş erişilebilir'"));
	Query.SetParameter("UseItemVariants",
		GetFunctionalOption("UseItemVariants"));
	Query.SetParameter("CurrentDayStart",BegOfDay(CurrentSessionDate()));
	Query.SetParameter("UseExcisableGoods",
		GetFunctionalOption("UseExcisableGoods"));
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Organization, CurrentSessionDate());

	If ByCase Then
		Query.Text = RequestTextBucketDataByCase();
	Else
		If TableOfGoods = Undefined Or TableOfGoods.Count() = 0 Then
			Query.Text = QueryTextBucketDataByTablePart(False);
		Else
			Query.Text = QueryTextBucketDataByTablePart(True);
			Query.SetParameter("DownloadData", TableOfGoods);
		EndIf;
	EndIf;
	
	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	Query.Text ="
	|SELECT ALLOWED
	|	Warehouses.Ref,
	|	Warehouses.Description
	|INTO Warehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	CASE
	|		WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			THEN FALSE
	|		ELSE Warehouses.Ref IN HIERARCHY (&Warehouse)
	|	END
	|	AND NOT Warehouses.IsFolder
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.Warehouses.EmptyRef),
	|	""""
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Warehouses.Ref AS Warehouse,
	|	CustomerShoppingCart.ProductsInSet,
	|	CustomerShoppingCart.ItemVariantOfSet,
	|	CustomerShoppingCart.Products,
	|	CustomerShoppingCart.Characteristic
	|INTO AllGoodsAndWarehouses
	|FROM
	|	Warehouses AS Warehouses,
	|	BucketData AS CustomerShoppingCart
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
	
	Query.Execute();
	
	Texts = New Array();
	
	Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE");
	Text = StrReplace(Text, "TTProducts_1", "AllGoodsAndWarehouses");
	Text = StrReplace(Text, "ALLOWED", "");
	Texts.Add(Text);
	
	Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
	
	Text =
		"SELECT ALLOWED
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS Date
		|INTO TTScheduledDeliveryDate
		|FROM
		|	TTWaysToEnsure AS Table
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|INDEX BY
		|	Products, Characteristic, Warehouse
		|;
		|DROP TTWaysToEnsure";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		"Table.ProcurementStrategy",
		"&CurrentDayStart",
		"Table.Products",
		"Table.Warehouse");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);
	
	Query.Text =
		DataProcessors.SelfServiceWorkplacePartners.TemporaryTablesForCalculatingAvailableBalances("AllGoodsAndWarehouses")
		+ "SELECT
		|	AllGoodsAndWarehouses.ProductsInSet,
		|	AllGoodsAndWarehouses.ItemVariantOfSet,
		|	AllGoodsAndWarehouses.Products,
		|	AllGoodsAndWarehouses.Characteristic,
		|	AllGoodsAndWarehouses.Warehouse AS Warehouse,
		|	ISNULL(AvailableBalancesByDate.Count, 0) AS Available,
		|	ISNULL(UpcomingAvailabilityDates.Date, DATETIME(1, 1, 1)) AS Period,
		|	ISNULL(ProductRestrictions.InventoryReplenishmentMethod, VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)) AS MUSES
		|INTO DataOnIMUZAvailability
		|FROM
		|	AllGoodsAndWarehouses AS AllGoodsAndWarehouses
		|		
		|		LEFT JOIN TTUpcomingAvailabilityDates AS UpcomingAvailabilityDates
		|		ON UpcomingAvailabilityDates.Products   = AllGoodsAndWarehouses.Products
		|		 AND UpcomingAvailabilityDates.Characteristic = AllGoodsAndWarehouses.Characteristic
		|		 AND UpcomingAvailabilityDates.Warehouse          = AllGoodsAndWarehouses.Warehouse
		|		
		|		LEFT JOIN TTAvailableBalancesByDate AS AvailableBalancesByDate
		|		ON AvailableBalancesByDate.Products   = AllGoodsAndWarehouses.Products
		|		 AND AvailableBalancesByDate.Characteristic = AllGoodsAndWarehouses.Characteristic
		|		 AND AvailableBalancesByDate.Warehouse          = AllGoodsAndWarehouses.Warehouse
		|		 AND AvailableBalancesByDate.Period         = UpcomingAvailabilityDates.Date
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|"
		+ RequestTextDataOnAvailabilityOfGoodsInStock();

	ConnectionFields = "AllGoodsAndWarehouses.Products,AllGoodsAndWarehouses.Characteristic,AllGoodsAndWarehouses.Warehouse";
	Query.Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Query.Text, "SubstituteGoodsRestriction", ConnectionFields);
	
	SetPrivilegedMode(True);
		Query.Execute();
	SetPrivilegedMode(False);

	Query.Text = QueryTextResultingFrom();
	
	ArrayOfAccessibilityTexts = SelfServiceServer.ArrayOfAccessibilityTexts();
	
	CustomerShoppingCart.Clear();
	QueryResult = Query.Execute();
	SelectionSetProducts = QueryResult.Select(QueryResultIteration.ByGroups);
	Query.TempTablesManager.Close();
	
	While SelectionSetProducts.Next() Do
		SelectionCharacteristicsOfSet = SelectionSetProducts.Select(QueryResultIteration.ByGroups);
		While SelectionCharacteristicsOfSet.Next() Do
			SelectionOfProducts = SelectionCharacteristicsOfSet.Select(QueryResultIteration.ByGroups);
	
			While SelectionOfProducts.Next() Do
				SampleCharacteristics = SelectionOfProducts.Select(QueryResultIteration.ByGroups);
				While SampleCharacteristics.Next() Do
					SamplePackaging = SampleCharacteristics.Select(QueryResultIteration.ByGroups);
					While SamplePackaging.Next() Do
						NewRow = CustomerShoppingCart.Add();
						SampleAvailability = SamplePackaging.Select(QueryResultIteration.ByGroups);
						While SampleAvailability.Next() Do
							SampleAvailable = SampleAvailability.Select(QueryResultIteration.ByGroups);
							While SampleAvailable.Next() Do
								SamplePeriod = SampleAvailable.Select(QueryResultIteration.ByGroups);
								While SamplePeriod.Next() Do
									DetailsSelection = SamplePeriod.Select(QueryResultIteration.ByGroups);
									While DetailsSelection.Next() Do
										If NewRow.Products = Catalogs.Products.EmptyRef() Then
											FillPropertyValues(NewRow, DetailsSelection);
										Else
											NumberInArrayString  = ArrayOfAccessibilityTexts.Find(NewRow.Enabled);
											NumberInArrayIsCur = ArrayOfAccessibilityTexts.Find(DetailsSelection.Enabled);
											If NumberInArrayString = Undefined Or NumberInArrayIsCur = Undefined Then
												Continue;
											EndIf;
											If NumberInArrayIsCur  <= NumberInArrayString Then
												FillPropertyValues(NewRow, DetailsSelection, "Available, Enabled, Period, ShipmentDate, AvailableNow");
												If NewRow.AvailableNow < 0 Then
													NewRow.AvailableNow = 0;
												EndIf;
											Else
												Continue;
											EndIf;
											
										EndIf;
									EndDo;
								EndDo;
							EndDo;
						EndDo;
					EndDo;
				EndDo;
			EndDo;
	
		EndDo;
	EndDo;
	
	LineNumber = 1;
	For Each TSRow In CustomerShoppingCart Do
		TSRow.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	FillParameters = New Structure;
	FillParameters.Insert("Date", CurrentSessionDate());
	FillParameters.Insert("Currency", Currency);
	FillParameters.Insert("Organization", Organization);
	FillParameters.Insert("Terms", Terms);
	FillParameters.Insert("VATTaxation", VATTaxation);
	FillParameters.Insert("CalculateSets", True);
	FillParameters.Insert("PopulationFields", "Price, PriceKind");
	
	PricesCalculated = EnterprisePricesFillingServer.FillInPrices(
		CustomerShoppingCart,
		Undefined, // Array of rows or selection structure
		FillParameters);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(ThisForm);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartServer.TreatTS(CustomerShoppingCart, StructureOfActions);
	
	ProcessBucketData();
	
EndProcedure

&AtServer
Procedure PerformRegisterEntryShoppingCartBuyer()
	
	RecordSet = InformationRegisters.CustomerShoppingCart.CreateRecordSet();
	RecordSet.Filter.AuthorizationObject.Set(?(PartnerAuthorized,Partner, ContactPerson),True);
	
	Query = New Query;
	Query.Text = "SELECT
	|	BasketTable.ProductsInSet,
	|	BasketTable.Products,
	|	BasketTable.ToRegister,
	|	BasketTable.ItemVariantOfSet,
	|	BasketTable.Characteristic,
	|	BasketTable.Package,
	|	BasketTable.NumberOfPackages,
	|	BasketTable.Price,
	|	BasketTable.PutFileDate,
	|	BasketTable.Currency
	|INTO BasketTable
	|FROM
	|	&BasketTable AS BasketTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BasketTable.ProductsInSet,
	|	BasketTable.ItemVariantOfSet,
	|	BasketTable.Products,
	|	BasketTable.Characteristic,
	|	BasketTable.Package,
	|	SUM(BasketTable.NumberOfPackages) AS NumberOfPackages,
	|	MAX(BasketTable.Price) AS Price,
	|	MAX(BasketTable.ToRegister) AS ToRegister,
	|	MIN(BasketTable.PutFileDate) AS PutFileDate,
	|	&AuthorizationObject,
	|	&Currency
	|FROM
	|	BasketTable AS BasketTable
	|
	|GROUP BY
	|	BasketTable.ProductsInSet,
	|	BasketTable.ItemVariantOfSet,
	|	BasketTable.Products,
	|	BasketTable.Characteristic,
	|	BasketTable.Package";
	
	Query.SetParameter("AuthorizationObject",?(PartnerAuthorized,Partner, ContactPerson));
	Query.SetParameter("Currency",Currency);
	Query.SetParameter("BasketTable",FormAttributeToValue("CustomerShoppingCart"));
	
	RecordSet.Load(Query.Execute().Unload());
	RecordSet.Write();
	
EndProcedure

&AtServer
Procedure PerformActionsWhenClosingFormOnServer()
	
	ShouldSaveSettings();
	PerformRegisterEntryShoppingCartBuyer();
	
EndProcedure

&AtClient
Procedure RecalcTotals()
	
	TotalInShoppingCart = 0;
	TotalForRegistration = 0;
	
	For Each String In CustomerShoppingCart Do
		
		TotalInShoppingCart = TotalInShoppingCart + String.AmountIncludingVAT;
		If String.ToRegister Then
			TotalForRegistration = TotalForRegistration + String.AmountIncludingVAT;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ProcessBucketDataChanges()
	
	RecalcTotals();
	AvailabilityControl();
	
EndProcedure

&AtServer
Function AddressOfTemporaryStorageWithBucket()

	Return PutToTempStorage(CustomerShoppingCart.Unload(), UUID); 

EndFunction

&AtServer
Procedure PurchaseByCommissionOnChangeServer()
	
	SetFormDetailsForSelection(SelfServiceServer.GetDefaultPartnerAgreement(Partner, BusinessOperation));
	
EndProcedure

&AtClient
Procedure OpenProductItemCard()

	CurrentData = Items.CustomerShoppingCart.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtClient
Procedure TermsStartChoiceCompletion(Result, AdditionalParameters) Export
	
	SelectionResult = Result;
	If SelectionResult <> Undefined And SelectionResult.Terms <> Terms Then
		WhenChangingAgreementAtServer(SelectionResult);
	EndIf;
	
	ProcessBucketDataChanges();
	
EndProcedure

#EndRegion

#Region Sets

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters) Export
	
	LineNumber = 1;
	For Each TSRow In CustomerShoppingCart Do
		TSRow.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
	EndDo;
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisForm, Var_Parameters, "CustomerShoppingCart");
	
EndFunction

&AtClientAtServerNoContext
Function DialColumns()
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("PriceKind");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("AmountIncludingVAT");
	Columns.Add("Sum");
	
	Return Columns;
	
EndFunction

&AtClient
Procedure OpenRecruitmentCard()

	CurrentData = Items.CustomerShoppingCart.CurrentData;
	
	If CurrentData <> Undefined Then
		FormParameters = New Structure("Key", CurrentData.Products);
		OpenForm("Catalog.Products.Form.ItemForm", FormParameters);
	EndIf;

EndProcedure

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithModifiedStrings = New Structure;
	StructureOfActionsWithAddedStrings = New Structure;
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns());
	
	SetsServer.AtEndOfEditingSet(ThisForm, "CustomerShoppingCart", DataParameters);
	
EndProcedure

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisForm, "CustomerShoppingCart", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("CustomerShoppingCart", AdditionalParameter);
	EndIf;
	
	ProcessBucketDataChanges();
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisForm, TSName, AdditionalParameter);
EndProcedure

&AtServer
Procedure ProcessAddingProducts(TableOfGoods)
	
	BasketTable = FormAttributeToValue("CustomerShoppingCart");
	
	Query = New Query;
	Query.SetParameter("SelectionData_1",TableOfGoods);
	Query.SetParameter("BucketData",BasketTable);
	Query.SetParameter("Currency",Currency);
	Query.SetParameter("VATTaxation",VATTaxation);
	Query.SetParameter("PriceIncludesVAT",PriceIncludesVAT);
	Query.SetParameter("CurrentDate",CurrentSessionDate());
	Query.SetParameter("Warehouse",Warehouse);
	Query.SetParameter("SelectWarehouseLine",NStr("vi = 'Hãy chọn kho';
													|ru = 'Выберите склад';
													|en = 'Select warehouse'; fa = 'انتخاب انبار';
													|it = 'Seleziona un magazzino';
													|pl = 'Wybierz magazyn';
													|tr = 'Ambar seç'"));
	Query.SetParameter("StringAvailableOnOrder",NStr("vi = 'Được phép theo đơn hàng';
													|ru = 'Доступно под заказ';
													|en = 'Available to order'; fa = 'Available to order';
													|it = 'Disponibile su richiesta';
													|pl = 'Dostępne do zamówienia';
													|tr = 'Sipariş üzerine mevcut'"));  
	Query.SetParameter("LineAccordingToGraph",NStr("vi = 'Theo biên';
													|ru = 'Согласно графика';
													|en = 'According to the schedule'; fa = 'According to the schedule';
													|it = 'In conformità del grafico';
													|pl = 'Zgodnie z harmonogramem';
													|tr = 'Programa göre'"));
	Query.SetParameter("LineNeedsToBeClarified",NStr("vi = 'Cần làm chính xác';
													|ru = 'Требует уточнения';
													|en = 'Requires clarification'; fa = 'نیاز به شفاف‌سازی دارد';
													|it = 'Richiede chiarimenti';
													|pl = 'Wymaga uściślenia';
													|tr = 'Netleştirme gerekiyor'"));
	Query.SetParameter("ThisServiceIsAvailable",NStr("vi = 'Dịch vụ sử dụng được';
													|ru = 'Услуга доступна';
													|en = 'The service is available'; fa = 'The service is available';
													|it = 'Servizio accessibile';
													|pl = 'Usługa jest dostępna';
													|tr = 'Hizmet erişilebilir'"));
	Query.SetParameter("JobLineIsAvailable",NStr("vi = 'Công việc khả dụng';
												|ru = 'Работа доступна';
												|en = 'Operation is available'; fa = 'Operation is available';
												|it = 'Lavoro accessibile';
												|pl = 'Praca jest dostępna';
												|tr = 'İş erişilebilir'"));
	Query.SetParameter("UseItemVariants",
		GetFunctionalOption("UseItemVariants"));
	Query.SetParameter("CurrentDayStart",BegOfDay(CurrentSessionDate()));
	Query.SetParameter("Country", SettingsValueClientServerCached.CountryOfOrganizationRegistration(Organization));

	Query.Text = "
	|SELECT
	|	SelectionData_1.ProductsInSet,
	|	SelectionData_1.ItemVariantOfSet,
	|	SelectionData_1.Products,
	|	SelectionData_1.Characteristic,
	|	SelectionData_1.Package,
	|	SelectionData_1.NumberOfPackages AS Count,
	|	SelectionData_1.Price,
	|	SelectionData_1.PriceKind
	|INTO UngroupedSelectionData
	|FROM
	|	&SelectionData_1 AS SelectionData_1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BucketData.ProductsInSet,
	|	BucketData.ItemVariantOfSet,
	|	BucketData.Products,
	|	BucketData.Characteristic,
	|	BucketData.Package,
	|	BucketData.NumberOfPackages,
	|	BucketData.Price,
	|	BucketData.PutFileDate,
	|	BucketData.ToRegister,
	|	BucketData.PriceKind
	|INTO BucketData
	|FROM
	|	&BucketData AS BucketData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UngroupedSelectionData.ProductsInSet,
	|	UngroupedSelectionData.ItemVariantOfSet,
	|	UngroupedSelectionData.Products,
	|	UngroupedSelectionData.Characteristic,
	|	UngroupedSelectionData.Package,
	|	SUM(UngroupedSelectionData.Count) AS Count,
	|	MAX(UngroupedSelectionData.Price) AS Price,
	|	MAX(UngroupedSelectionData.PriceKind) AS PriceKind
	|INTO SelectionData_1
	|FROM
	|	UngroupedSelectionData AS UngroupedSelectionData
	|
	|GROUP BY
	|	UngroupedSelectionData.ProductsInSet,
	|	UngroupedSelectionData.ItemVariantOfSet,
	|	UngroupedSelectionData.Products,
	|	UngroupedSelectionData.Characteristic,
	|	UngroupedSelectionData.Package
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BucketData.ProductsInSet AS ProductsInSet,
	|	BucketData.ItemVariantOfSet AS ItemVariantOfSet,
	|	BucketData.Products AS Products,
	|	BucketData.Characteristic AS Characteristic,
	|	BucketData.Package AS Package,
	|	BucketData.ToRegister AS ToRegister,
	|	CASE
	|		WHEN SelectionData_1.Products IS NULL 
	|			THEN BucketData.Price
	|		ELSE SelectionData_1.Price
	|	END AS Price,
	|	CASE
	|		WHEN SelectionData_1.Products IS NULL 
	|			THEN BucketData.NumberOfPackages
	|		ELSE BucketData.NumberOfPackages + SelectionData_1.Count
	|	END AS NumberOfPackages,
	|	BucketData.PutFileDate,
	|	&Currency,
	|	CASE
	|		WHEN SelectionData_1.Products IS NULL 
	|			THEN BucketData.PriceKind
	|		ELSE SelectionData_1.PriceKind
	|	END AS PriceKind
	|INTO SharedData
	|FROM
	|	BucketData AS BucketData
	|		LEFT JOIN SelectionData_1 AS SelectionData_1
	|		ON BucketData.Products = SelectionData_1.Products
	|			AND BucketData.Characteristic = SelectionData_1.Characteristic
	|			AND BucketData.ProductsInSet = SelectionData_1.ProductsInSet
	|			AND BucketData.ItemVariantOfSet = SelectionData_1.ItemVariantOfSet
	|			AND BucketData.Package = SelectionData_1.Package
	|
	|UNION ALL
	|
	|SELECT
	|	SelectionData_1.ProductsInSet,
	|	SelectionData_1.ItemVariantOfSet,
	|	SelectionData_1.Products,
	|	SelectionData_1.Characteristic,
	|	SelectionData_1.Package,
	|	TRUE,
	|	SelectionData_1.Price,
	|	SelectionData_1.Count,
	|	&CurrentDayStart,
	|	&Currency,
	|	SelectionData_1.PriceKind
	|FROM
	|	SelectionData_1 AS SelectionData_1
	|		LEFT JOIN BucketData AS BucketData
	|		ON SelectionData_1.Products = BucketData.Products
	|			AND SelectionData_1.Characteristic = BucketData.Characteristic
	|			AND SelectionData_1.ProductsInSet = BucketData.ProductsInSet
	|			AND SelectionData_1.ItemVariantOfSet = BucketData.ItemVariantOfSet
	|			AND SelectionData_1.Package = BucketData.Package
	|WHERE
	|	BucketData.Products IS NULL 
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Warehouses.Ref,
	|	Warehouses.Description
	|INTO Warehouses
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|WHERE
	|	Warehouses.Ref IN HIERARCHY (&Warehouse)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SharedData.ProductsInSet,
	|	SharedData.ItemVariantOfSet,
	|	SharedData.Products    AS Products,
	|	SharedData.Characteristic  AS Characteristic,
	|	&Warehouse                      AS Warehouse
	|INTO TTProducts_1
	|FROM
	|	SharedData AS SharedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SharedData.Products    AS Products,
	|	SharedData.Characteristic  AS Characteristic,
	|	Warehouses.Ref               AS Warehouse
	|INTO TTAllGoodsAndWarehouses
	|FROM
	|	SharedData AS SharedData,
	|	Warehouses AS Warehouses
	|;
	|
	|";

	Query.TempTablesManager = New TempTablesManager();
	Query.Execute();
	
	Texts = New Array();
	
	Text = InformationRegisters.SupplySchemes.TemporaryTableWaysToEnsure("CALCULATE");
	Texts.Add(Text);
	
	Texts.Add(ProvisionInDocumentsServer.TempTableYearsOfEnterpriseSchedule());
	
	Text =
		"SELECT ALLOWED
		|	Table.Products AS Products,
		|	Table.Characteristic AS Characteristic,
		|	Table.Warehouse AS Warehouse,
		|	CalculationOfDeliveryDateOverridable.PlannedDeliveryDate AS Date
		|INTO TTScheduledDeliveryDate
		|FROM
		|	TTWaysToEnsure AS Table
		|		
		|		LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE
		|		
		|INDEX BY
		|	Products,Characteristic,Warehouse
		|;
		|DROP TTWaysToEnsure";
	
	Substitutions = ProvisionInDocumentsServer.SubstitutionsOfPlannedDeliveryDate(
		"Table.ProcurementStrategy",
		"&CurrentDayStart",
		"Table.Products",
		"Table.Warehouse");
	
	Text = StrReplace(Text, "CalculationOfDeliveryDateOverridable.PlannedDeliveryDate", Substitutions.Field);
	Text = StrReplace(Text, "LEFT JOIN CalculationOfDeliveryDateOverridable ON TRUE", Substitutions.Joins);
	
	Texts.Add(Text);
	
	Query.Text = StrConcat(Texts, Common.QueryBatchSeparator());
	SetPrivilegedMode(True);
	Query.Execute();
	SetPrivilegedMode(False);

	Query.Text = DataProcessors.SelfServiceWorkplacePartners.TemporaryTablesForCalculatingAvailableBalances("TTAllGoodsAndWarehouses")
		+ "SELECT
		|	Goods.ProductsInSet,
		|	Goods.ItemVariantOfSet,
		|	Goods.Products,
		|	Goods.Characteristic,
		|	Goods.Warehouse AS Warehouse,
		|	ISNULL(AvailableBalancesByDate.Count, 0)             AS Available,
		|	ISNULL(UpcomingAvailabilityDates.Date, DATETIME(1, 1, 1)) AS Period,
		|	ISNULL(DatesOfScheduledDelivery.Date, DATETIME(1, 1, 1))     AS ShipmentDate,
		|	ISNULL(ProductRestrictions.InventoryReplenishmentMethod, VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)) AS MUSES
		|INTO DataOnIMUZAvailability
		|FROM
		|	TTProducts_1 AS Goods
		|		
		|		LEFT JOIN TTUpcomingAvailabilityDates AS UpcomingAvailabilityDates
		|		ON UpcomingAvailabilityDates.Products   = Goods.Products
		|		 AND UpcomingAvailabilityDates.Characteristic = Goods.Characteristic
		|		 AND UpcomingAvailabilityDates.Warehouse          = Goods.Warehouse
		|		
		|		LEFT JOIN TTAvailableBalancesByDate AS AvailableBalancesByDate
		|		ON AvailableBalancesByDate.Products   = Goods.Products
		|		 AND AvailableBalancesByDate.Characteristic = Goods.Characteristic
		|		 AND AvailableBalancesByDate.Warehouse          = Goods.Warehouse
		|		 AND AvailableBalancesByDate.Period         = UpcomingAvailabilityDates.Date
		|		
		|		LEFT JOIN InformationRegister.ProductRestrictions AS ProductRestrictions
		|		ON &SubstituteGoodsRestriction
		|		
		|		LEFT JOIN TTScheduledDeliveryDate AS DatesOfScheduledDelivery
		|		ON DatesOfScheduledDelivery.Products = Goods.Products
		|		 AND DatesOfScheduledDelivery.Characteristic = Goods.Characteristic
		|		 AND DatesOfScheduledDelivery.Warehouse = Goods.Warehouse
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	DataOnIMUZAvailability.ProductsInSet AS ProductsInSet,
		|	DataOnIMUZAvailability.ItemVariantOfSet AS ItemVariantOfSet,
		|	DataOnIMUZAvailability.Products AS Products,
		|	DataOnIMUZAvailability.Characteristic AS Characteristic,
		|	DataOnIMUZAvailability.Period AS Period,
		|	DataOnIMUZAvailability.Available AS Available,
		|	CASE
		|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
		|			THEN &ThisServiceIsAvailable
		|		WHEN ItemKinds.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN &JobLineIsAvailable
		|		WHEN &Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
		|			THEN &SelectWarehouseLine
		|		WHEN DataOnIMUZAvailability.MUSES = VALUE(Enum.InventoryReplenishmentMethods.OrderAgainstOrder)
		|			THEN &StringAvailableOnOrder
		|		WHEN NOT CAST(DataOnIMUZAvailability.Warehouse AS Catalog.Warehouses).AvailableStockControl
		|			 THEN &LineNeedsToBeClarified
		|		ELSE &LineAccordingToGraph
		|	END AS Enabled,
		|	DataOnIMUZAvailability.ShipmentDate AS ShipmentDate
		|INTO AvailabilityData_
		|FROM
		|	DataOnIMUZAvailability AS DataOnIMUZAvailability
		|		INNER JOIN Warehouses AS Warehouses
		|		ON DataOnIMUZAvailability.Warehouse = Warehouses.Ref
		|		INNER JOIN SharedData AS SharedData
		|		ON DataOnIMUZAvailability.Products = SharedData.Products
		|		 AND DataOnIMUZAvailability.Characteristic = SharedData.Characteristic
		|		 AND DataOnIMUZAvailability.ProductsInSet = SharedData.ProductsInSet
		|		 AND DataOnIMUZAvailability.ItemVariantOfSet = SharedData.ItemVariantOfSet
		|		LEFT JOIN Catalog.Products AS CatalogProducts
		|			LEFT JOIN Catalog.ItemKinds AS ItemKinds
		|			ON CatalogProducts.ProductKind = ItemKinds.Ref
		|		ON DataOnIMUZAvailability.Products = CatalogProducts.Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SharedData.ProductsInSet,
		|	SharedData.ItemVariantOfSet,
		|	SharedData.Products,
		|	SharedData.Characteristic,
		|	SharedData.Package,
		|	SharedData.ToRegister,
		|	SharedData.NumberOfPackages,
		|	SharedData.Price,
		|	SharedData.PutFileDate,
		|	SharedData.Currency,
		|	&VATRate AS VATRate,
		|	CAST(&VATRate AS Catalog.VATRates).Rate1 / 100 AS ValueOfVATRate,
		|	SharedData.PriceKind
		|INTO WithVATData
		|FROM
		|	SharedData AS SharedData
		|		INNER JOIN Catalog.Products AS CatProducts
		|		ON SharedData.Products = CatProducts.Ref
		|		LEFT JOIN InformationRegister.ProductsVATRates.SliceLast(&Date,
		|			Country = &RegistrationCountry OR Country = VALUE(Catalog.WorldCountries.EmptyRef)) AS ProductsVATRates
		|		ON SharedData.Products = ProductsVATRates.Products
		|		LEFT JOIN InformationRegister.BasicVATRates.SliceLast(&Date, Country = &RegistrationCountry) AS BasicVATRates
		|		ON (TRUE)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
	
	Query.Text = StrReplace(Query.Text,"&VATRate", VATAccountingERP.QueryTextVATRate("&VATTaxation", "CatProducts"));
		
	ConnectionFields = "Goods.Products,Goods.Characteristic,Goods.Warehouse";
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Organization, CurrentSessionDate());
	
	Query.Text = InformationRegisters.ProductRestrictions.SubstituteConnection(Query.Text, "SubstituteGoodsRestriction", ConnectionFields);
	
	If BalanceViewIsAvailable Then
		
		Query.Text = Query.Text
		+ DataProcessors.SelfServiceWorkplacePartners.TemporaryTableAvailableForSaleTotalByWarehouse("TTAllGoodsAndWarehouses")
		+ Common.QueryBatchSeparator()
		+ ExcisableGoodsAccounting.QueryTextTTExcisableItems("WithVATData", "CurrentDate")
		+ Common.QueryBatchSeparator()
		+"SELECT
		|	WithVATData.ProductsInSet,
		|	WithVATData.ItemVariantOfSet,
		|	WithVATData.Products,
		|	WithVATData.Characteristic,
		|	WithVATData.Package,
		|	WithVATData.ToRegister,
		|	WithVATData.NumberOfPackages AS NumberOfPackages,
		|	WithVATData.Price AS Price,
		|	WithVATData.PutFileDate AS PutFileDate,
		|	WithVATData.Currency AS Currency,
		|	WithVATData.VATRate AS VATRate,
		|	WithVATData.Price * WithVATData.NumberOfPackages AS Sum,
		|	CASE
		|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			THEN CASE
		|					WHEN &PriceIncludesVAT
		|						THEN WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate / (1 + WithVATData.ValueOfVATRate)
		|					ELSE WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate
		|				END
		|		ELSE 0
		|	END AS VATAmount,
		|	WithVATData.NumberOfPackages * WithVATData.Price + CASE
		|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			THEN CASE
		|					WHEN &PriceIncludesVAT
		|						THEN 0
		|					ELSE WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate
		|				END
		|		ELSE 0
		|	END AS AmountIncludingVAT,
		|	WithVATData.PriceKind AS PriceKind,
		|	CASE
		|		WHEN ProductPackages.Ref IS NULL 
		|			THEN WithVATData.NumberOfPackages
		|		ELSE WithVATData.NumberOfPackages * &QueryTextPackagingFactor
		|	END AS Count,
		|	AvailabilityData_.Period,
		|	AvailabilityData_.Available,
		|	AvailabilityData_.Enabled,
		|	AvailabilityData_.ShipmentDate,
		|	CAST(ISNULL(BalanceTable.AvailableForInventoryAllocation, 0) / ISNULL(&QueryTextPackagingFactor, 1) AS NUMBER(15, 3)) AS AvailableNow,
		|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods
		|FROM
		|	WithVATData AS WithVATData
		|		INNER JOIN AvailabilityData_ AS AvailabilityData_
		|			ON WithVATData.Products = AvailabilityData_.Products
		|			AND WithVATData.Characteristic = AvailabilityData_.Characteristic
		|			AND WithVATData.ProductsInSet = AvailabilityData_.ProductsInSet
		|			AND WithVATData.ItemVariantOfSet = AvailabilityData_.ItemVariantOfSet
		|		
		|		LEFT JOIN TTFreeForSale AS BalanceTable
		|		ON BalanceTable.Products   = WithVATData.Products
		|		 AND BalanceTable.Characteristic = WithVATData.Characteristic
		|		
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON WithVATData.Package = ProductPackages.Ref
		|		LEFT JOIN Catalog.Products AS CatalogProducts
		|		ON WithVATData.Products = CatalogProducts.Ref
		|		LEFT JOIN TTExcisableItems AS TTExcisableItems
		|		ON WithVATData.Products = TTExcisableItems.Products";
		
	Else
		
		Query.Text = Query.Text
		+ ExcisableGoodsAccounting.QueryTextTTExcisableItems("WithVATData", "CurrentDate")
		+ Common.QueryBatchSeparator() + "
		|SELECT
		|	WithVATData.ProductsInSet,
		|	WithVATData.ItemVariantOfSet,
		|	WithVATData.Products,
		|	WithVATData.Characteristic,
		|	WithVATData.Package,
		|	WithVATData.ToRegister,
		|	WithVATData.NumberOfPackages AS NumberOfPackages,
		|	WithVATData.Price AS Price,
		|	WithVATData.PutFileDate AS PutFileDate,
		|	WithVATData.Currency AS Currency,
		|	WithVATData.VATRate AS VATRate,
		|	WithVATData.Price * WithVATData.NumberOfPackages AS Sum,
		|	CASE
		|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			THEN CASE
		|					WHEN &PriceIncludesVAT
		|						THEN WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate / (1 + WithVATData.ValueOfVATRate)
		|					ELSE WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate
		|				END
		|		ELSE 0
		|	END AS VATAmount,
		|	WithVATData.NumberOfPackages * WithVATData.Price + CASE
		|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
		|			THEN CASE
		|					WHEN &PriceIncludesVAT
		|						THEN 0
		|					ELSE WithVATData.Price * WithVATData.NumberOfPackages * WithVATData.ValueOfVATRate
		|				END
		|		ELSE 0
		|	END AS AmountIncludingVAT,
		|	WithVATData.PriceKind AS PriceKind,
		|	CASE
		|		WHEN ProductPackages.Ref IS NULL 
		|			THEN WithVATData.NumberOfPackages
		|		ELSE WithVATData.NumberOfPackages * &QueryTextPackagingFactor
		|	END AS Count,
		|	AvailabilityData_.Period,
		|	AvailabilityData_.Available,
		|	AvailabilityData_.Enabled,
		|	AvailabilityData_.ShipmentDate,
		|	ISNULL(TTExcisableItems.ExcisableGoods, FALSE) AS ExcisableGoods
		|FROM
		|	WithVATData AS WithVATData
		|		INNER JOIN AvailabilityData_ AS AvailabilityData_
		|		   ON WithVATData.Products = AvailabilityData_.Products
		|			AND WithVATData.Characteristic = AvailabilityData_.Characteristic
		|			AND WithVATData.ProductsInSet = AvailabilityData_.ProductsInSet
		|			AND WithVATData.ItemVariantOfSet = AvailabilityData_.ItemVariantOfSet
		|		LEFT JOIN Catalog.PackagesAndUnitsOfMeasure AS ProductPackages
		|		ON WithVATData.Package = ProductPackages.Ref
		|		LEFT JOIN Catalog.Products AS CatalogProducts
		|		ON WithVATData.Products = CatalogProducts.Ref
		|		LEFT JOIN TTExcisableItems AS TTExcisableItems
		|		ON WithVATData.Products = TTExcisableItems.Products";
		
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
				"ProductPackages",
				"CatalogProducts"));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	Query.TempTablesManager.Close();

	CustomerShoppingCart.Load(Result.Unload());
	
	ProcessBucketData();
	
EndProcedure

&AtClient
Procedure NotifyAboutChangesToBuyerSShoppingCart()

	Notify("Write_CustomerShoppingCart", New Structure("AuthorizationObject", ?(PartnerAuthorized, Partner, ContactPerson)));

EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(GoodsAddressInStorage)
	
	TableOfGoods = GetFromTempStorage(GoodsAddressInStorage);
	If TableOfGoods.Count() > 0 Then
		SetParameterValuesRunRequest(False, TableOfGoods);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	VATTaxation = Enums.VATTaxationTypes.EmptyRef();
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	
	FillParameters.Organization = Organization;
	FillParameters.Warehouse       = Warehouse;
	FillParameters.ThisIsOrder    = True;
	
	If BusinessOperation = Enums.BusinessTransactions.SaleToCustomer Or
		BusinessOperation = Enums.BusinessTransactions.SaleWithDeferredTransferOfTitle  Then
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		
		FillParameters.TransferToCommissionAgent = True;
		
	EndIf;
	
	VATAccountingERP.FillInSalesVATTaxation(VATTaxation, FillParameters);
	
EndProcedure

#EndRegion

#EndRegion
