#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; // used by the series mechanism

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);

	SupportedPeripheralTypes = "BarcodeScanner";
	TMCommonUse.CustomizePeripherals(ThisObject);
	CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(Object.CashRegister);
	
	UseDiscountAdjustmentsInSales = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	
	UpdateItemsVisibility(CashRegisterDetails.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters);
	
	Items.GoodsNumberOfPackages.AutoMarkIncomplete = Not Object.ByPhysicalCountResults;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	EndIf;
	
	If CashRegisterDetails.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters Then
		TMCommonUseClientServer.SetFormItemProperty(Items, "FormCopy", "Enabled", False);
	EndIf;
	
	Items.PaymentWithPaymentCardsPaymentKind_.ChoiceList.LoadValues(PaymentByPaymentCardsAvailableTypesOfPayment());
	ProcessingOfTabularForms.InitializeRowCache(Items.PaymentWithPaymentCards);
	
	If Object.ByPhysicalCountResults Then
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False))));
		Items.GoodsProducts.ChoiceParameters = New FixedArray(NewSelectionOptions);
	Else
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes)));
		Items.GoodsProducts.ChoiceParameters = New FixedArray(NewSelectionOptions);
		
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.GroupInTotal.BackColor = New Color();
	EndIf;
	
	Items.GoodsPartner.Visible = AccessRight("View", Metadata.Catalogs.Partners);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, SupportedPeripheralTypes);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
EndProcedure

&AtClient
Procedure OnClose()
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActions.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	SetsServer.FillInServiceDetails(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.InventoryKinds.Form.InventoryOwnerAttributesForm" Then	
		GetStockTypesFromStorage(ValueSelected);
	EndIf;
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		ProductsSeriesRecalculatePrices();
		
	EndIf;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// Peripherals
	If IsInputAvailable()
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
	If EventName = "Write_RetailSalesReport" Then
		Read();
	EndIf;
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
		KitParameters.Insert("DialColumns", DialColumns(ThisObject));
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", Parameter.DocumentSalesOfGoodsAndServices);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("PriceKind", Object.PriceKind);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	FormEventsClient.URLProcessing(ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtServer
Procedure CheckoutWhenChangesAreMadeOnServer()
	
	CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(Object.CashRegister);
	
	If CashRegisterDetails.PriceKind <> Object.PriceKind Then
		// Resetting the prices of the item.
		
		FillPropertyValues(Object, CashRegisterDetails);
		FillInPricesByPriceKind(CashRegisterDetails.PriceKind);
		
	Else
		FillPropertyValues(Object, CashRegisterDetails);
	EndIf;
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	FillInAttributesOnChangingElementATServerLocalization(Items.CashRegister);
	
	UpdateItemsVisibility(CashRegisterDetails.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RetailSalesReport));
	SetVisibilityOfSeriesElements();
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
EndProcedure

&AtClient
Procedure CashAccountOnChange(Item)
	
	CheckoutWhenChangesAreMadeOnServer();
	
EndProcedure

&AtClient
Procedure PriceKindOnChange(Item)
	
	PriceViewWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ByPhysicalCountResultsOnChange(Item)
	
	If Object.Goods.Count() > 0 And Object.ByPhysicalCountResults Then
		ShowQueryBox(New CallbackDescription("ByPhysicalCountResultsOnChangeCompletion", ThisObject), 
			NStr("vi = 'Dữ liệu về số lượng có thể bị mất, tiếp tục?';
				|ru = 'Данные о количестве могут быть потеряны, продолжить?';
				|en = 'Quantity data may be lost, continue?'; fa = 'Quantity data may be lost, continue?';
				|it = 'I dati relativi alla quantità potrebbero andare persi, continuare?';
				|pl = 'Dane ilości mogą zostać utracone, kontynuować?';
				|tr = 'Miktarlara ilişkin veriler kaybolabilir, devam edilsin mi?'"), QuestionDialogMode.YesNo);
        Return;
	Else
		BasedOnInventoryResultsOnServer();
	EndIf;
	
	AccordingToResultsOfInventoryWhenChangingFragment();
EndProcedure

&AtClient
Procedure ByPhysicalCountResultsOnChangeCompletion(QuestionResult, AdditionalParameters) Export
    
    Result = QuestionResult;
    If Result = DialogReturnCode.Yes Then
        BasedOnInventoryResultsOnServer();
    Else
        Object.ByPhysicalCountResults = Not Object.ByPhysicalCountResults;
    EndIf;
    
    AccordingToResultsOfInventoryWhenChangingFragment();

EndProcedure

&AtClient
Procedure AccordingToResultsOfInventoryWhenChangingFragment()
	
	Items.GoodsNumberOfPackages.AutoMarkIncomplete = Not Object.ByPhysicalCountResults;
	If Object.ByPhysicalCountResults Then
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ProductsClientServer.SelectionByProductMultiTurnContainer(False))));
		Items.GoodsProducts.ChoiceParameters = New FixedArray(NewSelectionOptions);
	Else
		
		ArrayOfProductTypes = New Array;
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OperationService"));
		
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes)));
		Items.GoodsProducts.ChoiceParameters = New FixedArray(NewSelectionOptions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DateOnChangeServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)
	
	DepartmentOnChangeServer();
	
EndProcedure

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	FillInAttributesOnChangingElementATServerLocalization(Items.Warehouse);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Item.CurrentData;
	If Not ValueIsFilled(CurrentData.Partner) Then
		CurrentData.Partner = PredefinedValue("Catalog.Partners.RetailCustomer");
	EndIf;
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
				Item,CachedValues,SeriesSpecificationParameters, Copy);

EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters,True) Then
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Undefined, CachedValues);
		ProductsClient.UpdateCachedValuesToAccountForSeries(
					Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	CurrentData = Items.Goods.CurrentData;
	
	If ProductsClient.SeriesStatusesNeedToBeUpdated(
		Item,CachedValues,SeriesSpecificationParameters) Then
		
		IDCurrentRow = CurrentData.GetID();
		
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues);	
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item,CachedValues,SeriesSpecificationParameters);
		
	EndIf;
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner",    CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	
	OnDate = ?(ValueIsFilled(Object.Ref), Object.Date, Undefined);
	
	FillingStructure = New Structure();
	FillingStructure.Insert("Recorder", Object.Ref);
	FillingStructure.Insert("Warehouse", Object.Warehouse);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("PointInTime", OnDate);
	
	StructureOfActions.Insert("FillInAccountingQuantityOfProductItem", FillingStructure);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange",
			BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		//
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.Warehouse;
		AssortmentInspectionStructure.Date = Object.Date;
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc danh điểm của cửa hàng hoặc đã bị cấm bán.';
														|ru = 'Товар %1 не включен в ассортимент магазина или запрещен к продаже.';
														|en = 'Product %1 is not included in the store''s product range or prohibited for sale.'; fa = 'Product %1 is not included in the store''s product range or prohibited for sale.';
														|it = 'Il prodotto %1 non è incluso nell''inventario del negozio o ne è vietata la vendita.';
														|pl = 'Towar %1 nie jest zawarty w asortymencie sklepu lub jego sprzedaż jest zabroniona.';
														|tr = 'Ürün %1 mağazanın ürün yelpazesine dahil değildir veya satışına izin verilmemektedir.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "SalesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		
		StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
 	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Goods"));

	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActions.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	
	FillingStructure = New Structure();
	FillingStructure.Insert("Recorder", Object.Ref);
	FillingStructure.Insert("Warehouse", Object.Warehouse);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("PointInTime", ?(ValueIsFilled(Object.Ref), Object.Date, Undefined));
	
	StructureOfActions.Insert("FillInAccountingQuantityOfProductItem", FillingStructure);
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName", FormName, "Goods"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ValueIsFilled(Object.PriceKind) Then
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	
	FillingStructure = New Structure();
	FillingStructure.Insert("Recorder", Object.Ref);
	FillingStructure.Insert("Warehouse", Object.Warehouse);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("PointInTime", ?(ValueIsFilled(Object.Ref), Object.Date, Undefined));
	
	StructureOfActions.Insert("FillInAccountingQuantityOfProductItem", FillingStructure);
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	CurrentRow.ManualDiscount = Round(CurrentRow.Count *CurrentRow.Price * CurrentRow.PercentRateOfManualDiscount / 100, 2);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	If CurrentRow.Count *CurrentRow.Price <> 0 Then
		CurrentRow.PercentRateOfManualDiscount = Round(100*CurrentRow.ManualDiscount / (CurrentRow.Count *CurrentRow.Price), 2);
	EndIf;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesRealOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackagesAfterFact");
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	ProductsSeriesRecalculatePrices(Items.Goods.CurrentData);
	
EndProcedure

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet", CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsByCorrectionReceiptOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	If Not CurrentRow.ByCorrectionReceipt And ValueIsFilled(CurrentRow.DocumentSalesOfGoodsAndServices) Then
		CurrentRow.DocumentSalesOfGoodsAndServices = PredefinedValue("Document.RetailSalesReport.EmptyRef");	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPaymentWithPaymentCards

&AtClient
Procedure PaymentWithPaymentCardsOnEditEnd(Item, NewRow, CancelEdit)
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure PaymentWithPaymentCardsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.PaymentWithPaymentCards, ThisObject);
	CurrentData = Items.PaymentWithPaymentCards.CurrentData;
	
	If NewRow And Not Copy Then
		
		If Not ValueIsFilled(CurrentData.POSTerminal) 
			And ValueIsFilled(DefaultPOSTerminal) Then
			CurrentData.POSTerminal = DefaultPOSTerminal;
			CurrentData.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard"); 
		EndIf;
		
	EndIf;
	
	ManagingFieldsInPaymentByCreditCardTable(CurrentData);
	
EndProcedure

&AtClient
Procedure PaymentWithPaymentCardsPaymentKind_OnChange(Item)
	
	CurrentData = Items.PaymentWithPaymentCards.CurrentData;
	If CurrentData.PaymentKind_ <> CachedLines[Items.PaymentWithPaymentCards.Name].PaymentKind_ Then
		
		ManagingFieldsInPaymentByCreditCardTable(CurrentData);
		ProcessingOfTabularFormsClient.CacheCurLine(Items.PaymentWithPaymentCards, ThisObject);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure OpenInventoryKinds(Command)
	
	OptionsForEditingInventoryTypes = PutGoodsAndStockTypesInStorage();
	FinancesClient.OpenInventoryKinds(ThisObject, OptionsForEditingInventoryTypes);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure FillInByAccountingData(Command)
	If Object.Goods.Count() > 0 Then
		ShowQueryBox(New CallbackDescription("FillInByAccountingDataCompletion", ThisObject), 
			NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa, tiếp tục?';
				|ru = 'Перед заполнением табличная часть будет очищена, продолжить?';
				|en = 'The table will be cleared. Do you want to continue?'; fa = 'جدول پاک خواهد شد. آیا می‌خواهید ادامه دهید؟';
				|it = 'Prima della compilazione, la parte tabulare sarà cancellata, continuare?';
				|pl = 'Przed wypełnieniem część tabelaryczna zostanie wyczyszczona, kontynuować?';
				|tr = 'Doldurmadan önce tablo kısmı temizlenecek, devam edilsin mi?'"), QuestionDialogMode.YesNo);
	Else
		FillInAccordingToAccountingDataOnServer();
		CalculateTotalsOfRetailSalesReport(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure FillInByAccountingDataCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	If Result = DialogReturnCode.Yes Then
		FillInAccordingToAccountingDataOnServer();
		CalculateTotalsOfRetailSalesReport(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInActualQuantityByAccountingData(Command)
	
	FillInActualQuantityAccordingToAccountingDataOnServer();
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtClient
Procedure Refill(Command)
	
	If ValueIsFilled(Object.CashRegisterShift) Then
		ReFillOnServer();
		
		ShowUserNotification(
			NStr("vi = 'Báo cáo được điền lại';
				|ru = 'Отчет перезаполнен';
				|en = 'Report is refilled'; fa = 'Report is refilled';
				|it = 'Il report è ricompilato';
				|pl = 'Raport jest wypełniony ponownie';
				|tr = 'Rapor yeniden dolduruldu'"),
			,
			NStr("vi = 'Bảng kê bán lẻ hàng hóa được điền lại theo dữ liệu phiên thu ngân';
				|ru = 'Отчет о розничных продажах перезаполнен по данным кассовой смены';
				|en = 'Retail sales report is refilled by POS shift data'; fa = 'Retail sales report is refilled by POS shift data';
				|it = 'Report di vendite al dettaglio è ricompilato in base ai dati del turno di cassa';
				|pl = 'Raport o sprzedaży detalicznej został wypełniony ponownie w oparciu o dane kasowej zmiany';
				|tr = 'Perakende satış raporu nakit vardiya verileriyle yeniden dolduruldu'"),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetWeight(Command)
	
	ClearMessages();
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		StructureOfActions = New Structure;
		
		If Object.ByPhysicalCountResults Then
			CurrentRow.NumberOfPackagesReal = ExecutionResult.Weight;
			
			If CurrentRow.NumberOfPackagesReal < CurrentRow.NumberOfPackagesAccounting Then
				CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackagesReal;
			Else
				CurrentRow.NumberOfPackages = 0;
			EndIf;
			
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
			
		Else
			CurrentRow.NumberOfPackages = ExecutionResult.Weight;
			
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
			
		EndIf;
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	OpenSelectionOfSeries();
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RowSelected = Items.Goods.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	CurrentRow = Object.Goods.FindByID(RowSelected);
	
	If Not ValueIsFilled(CurrentRow.ProductsInSet) Then
		ShowMessageBox(,NStr("vi = 'Chỉ có thể mở thành phần bộ sản phẩm đối với bộ sản phẩm.';
							|ru = 'Открытие состава набора возможно только для набора.';
							|en = 'You can open a set only for the set.'; fa = 'You can open a set only for the set.';
							|it = 'L''apertura della composizione del kit è possibile solo per il kit.';
							|pl = 'Otwarcie składu zestawu jest możliwe tylko dla zestawu.';
							|tr = 'Set kompozisyonunun açılması sadece bir set için mümkündür.'"));
		Return;
	EndIf;
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	KitParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
	OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	OpeningParameters.Insert("DocumentSalesOfGoodsAndServices", CurrentRow.DocumentSalesOfGoodsAndServices);
	OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
	OpeningParameters.Insert("Currency", Object.Currency);
	OpeningParameters.Insert("TypesOfPrice", Object.PriceKind);
	OpeningParameters.Insert("Date", Object.Date);
	OpeningParameters.Insert("Ref", Object.Ref);
	OpeningParameters.Insert("Warehouse", Object.Warehouse);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
		"Document.RetailSalesReport.DocumentForm.Command.OpenSelection");
	
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'bảng kê bán lẻ hàng hóa';
																			|ru = 'отчет о розничных продажах';
																			|en = 'retail sales report'; fa = 'retail sales report';
																			|it = 'report sulle vendite al dettaglio';
																			|pl = 'raport o sprzedażach detalicznych';
																			|tr = 'perakende satış raporu'"));
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("PriceKind", Object.PriceKind);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("SelectionModeWithoutAgreementsWithCustomers", True);
	FormParameters.Insert("AnalysisOptionOfProductsSoldTogether", PredefinedValue("Enum.AnalysisOptionsForItemsSoldTogether.RetailSale"));
	FormParameters.Insert("SelectionModeByProductRange", ControlProductRange);
	
	FormParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
	FormParameters.Insert("VATTaxation", Object.VATTaxation);
	FormParameters.Insert("SelectionModeUseWarehousesInTabularSection", False);
	FormParameters.Insert("UseShipmentDates",                      False);
	FormParameters.Insert("Warehouse",                                   Object.Warehouse);
	FormParameters.Insert("Currency",                                  Object.Currency);
	FormParameters.Insert("Title",                               HeaderParameter_);
	FormParameters.Insert("Date",                                    Object.Date);
	FormParameters.Insert("Document",                                Object.Ref);
	FormParameters.Insert("HideTheViewPriceColumn",                  True);
	FormParameters.Insert("SeriesSpecificationParameters",                  SeriesSpecificationParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	InventoriesServer.EstablishConditionalAppearanceOfDivisionForTypesOfStocks(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ExcisableGoods");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsSubjectToUTII;

	Item.Appearance.SetParameterValue("ReadOnly", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATRate.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsVATAmount.Name);

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsSubjectToUTII;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.VATTaxation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.VATTaxationTypes.SaleIsNotSubjectToVAT;

	Item.Appearance.SetParameterValue("Visible", False);


	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPartner.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ByPhysicalCountResults");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsDocumentSalesOfGoodsAndServices.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ByCorrectionReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentWithPaymentCardsPaymentKind_.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentWithPaymentCards.PaymentKind_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentWithPaymentCardsConnectionContract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentWithPaymentCards.PaymentKind_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ValueList = New ValueList;
	ValueList.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
	ValueList.Add(Enums.TypesOfCashRegisterPaymentSystem.NSPKCertificate);
	ItemFilter.RightValue = ValueList;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentWithPaymentCardsPOSTerminal.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentWithPaymentCards.PaymentKind_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfCashRegisterPaymentSystem.InstantPayments;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Không bắt buộc>';
													|ru = '<не требуется>';
													|en = '<not required>'; fa = '<الزامی نیست>';
													|it = '<non richiesto>';
													|pl = '<nie jest wymagane>';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentWithPaymentCardsPOSTerminal.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PaymentWithPaymentCardsConnectionContract.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.PaymentWithPaymentCards.PaymentKind_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra dạng thanh toán>';
													|ru = '<укажите вид оплаты>';
													|en = '<specify payment kind>'; fa = '<specify payment kind>';
													|it = '<укажите вид оплаты>';
													|pl = '<specify payment kind>';
													|tr = '<ödeme türünü belirtin>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure PriceViewWhenChangedOnServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TypesOfPrices.PriceIncludesVAT AS PriceIncludesVAT
	|FROM
	|	Catalog.TypesOfPrices AS TypesOfPrices
	|WHERE
	|	TypesOfPrices.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.PriceKind);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		FillPropertyValues(Object, Selection);
	EndDo;
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
	ResponsiblePersonsServer.WhenChangingRelatedDocumentDetails(Object);
	Items.GoodsPremise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
EndProcedure

&AtServer
Procedure DepartmentOnChangeServer()
	
	FillInSalesVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer(CachedValues = Undefined)
	
	CachedValuesInternal = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("AdjustVATRate",  BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions, CachedValuesInternal);
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount",);
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		CachedValuesInternal.ProcessedRows,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If ControlProductRange Then
		StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("FillInForm");
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActionsWithAddedStrings.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	If Object.ByPhysicalCountResults Then
		ColumnNameQuantity = "NumberOfPackagesReal";
		StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfPackagesAfterFact");
		StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfPackagesAfterFact");
	Else
		ColumnNameQuantity = "NumberOfPackages";
	EndIf;
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ColumnNameQuantity                   = ColumnNameQuantity;
	StructureOfActions.CalculateSets                     = True;
	
	If ControlProductRange Then
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.Warehouse;
		AssortmentInspectionStructure.Date = Object.Date;
		AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc danh điểm cửa hàng hoặc đã bị cấm bán.';
														|ru = 'Товар %1 не включен в ассортимент магазина или запрещен к продаже.';
														|en = 'Product %1 is not included in the store''s product range or prohibited for sale.'; fa = 'Product %1 is not included in the store''s product range or prohibited for sale.';
														|it = 'Il prodotto %1 non è incluso nell''inventario del negozio o ne è vietata la vendita.';
														|pl = 'Towar %1 nie jest zawarty w asortymencie sklepu lub jego sprzedaż jest zabroniona.';
														|tr = 'Ürün %1 mağazanın ürün yelpazesine dahil değildir veya satışına izin verilmemektedir.'");
		AssortmentInspectionStructure.NameOfAssortmentResource = "SalesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = True;
		
		StructureOfActions.AssortmentVerificationParameters = AssortmentInspectionStructure;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions, CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(StructureOfActions) Then
		CurDataId = StructureOfActions.ArrayOfRowsWithSeries_[0];
		
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
	If StructureOfActions.CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = StructureOfActions.CurrentRow;	
	EndIf;

EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSpecifySeries.Visible        = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible				 = SeriesSpecificationParameters.UseCostAccountingByBatches;
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	StructureOfActions = New Structure;
	StructureOfActions.Insert("UpdateNumberOfProductsWhenRegistering", True);
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	ProductsServer.ProcessSeriesIndication_(Object,SeriesSpecificationParameters,ParametersOfSeriesIndicationForm,StructureOfActions);
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, 
				SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Procedure FillInStatusesForSpecifyingSeriesServer()
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
EndProcedure

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()

	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);

EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject ,SeriesSpecificationParameters, Text, CurrentData) Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		OpenForm(ParametersOfSeriesIndicationForm.FormName,ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			New CallbackDescription("OpenSelectionOfSeriesCompletion",
				ThisObject,
				New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm)),
			FormWindowOpeningMode.LockOwnerWindow
		);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	ReturnValue_1 = Result;
	If ReturnValue_1 <> Undefined Then
		
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
		ProductsSeriesRecalculatePrices();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePrices(CurrentRow = Undefined)
	
	If CurrentRow = Undefined Then
		CurrentRow = Items.Goods.CurrentData;
	EndIf;
	
	If PriceManagementSystemClient.ItIsNecessaryToRecalculatePriceWhenChanging(CurrentRow.Products, "Series", Object.Date) Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CurrentRow", CurrentRow);
		ProductsSeriesRecalculatePricesCompletion(AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductsSeriesRecalculatePricesCompletion(AdditionalParameters) Export
	
	CurrentRow = AdditionalParameters.CurrentRow;
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	PriceFillingParameters_ = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object, True);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInSalePrice", PriceFillingParameters_);
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithVAT", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns(Form)
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	If Form.UseDiscountAdjustmentsInSales Then
		Columns.Add("PercentRateOfManualDiscount");
		Columns.Add("ManualDiscount");
	EndIf;
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("Sum");

	Columns.Add("DocumentSalesOfGoodsAndServices");

	
	Return Columns;
	
EndFunction

&AtClient
// Called via the description of the message from the general module setclient 
Procedure WhenRemovingComponents(Action, AdditionalParameter) Export
	
	If SetsClient.EditSetAction(Action) Then
		SetsClient.WhenRemovingComponents(ThisObject, "Goods", AdditionalParameter);
	ElsIf SetsClient.DeleteEntireSetAction(Action) Then
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter);
	EndIf;
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActionsWithAddedStrings.Insert("FillInForm");
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActionsWithAddedStrings.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	UseWarerooms = WarehousesServer.UseWarerooms(Object.Warehouse,
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	StructureOfActions = New Structure;
	
	FillingStructure = New Structure();
	FillingStructure.Insert("Recorder", Object.Ref);
	FillingStructure.Insert("Warehouse", Object.Warehouse);
	FillingStructure.Insert("Organization", Object.Organization);
	FillingStructure.Insert("PointInTime", ?(ValueIsFilled(Object.Ref), Object.Date, Undefined));
	
	StructureOfActions.Insert("FillInAccountingQuantityOfProductItem", FillingStructure);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculatePriceDiscountByAmountInSales");
	StructureOfActions.Insert("RecalculateVATAmount",
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	
 	StructureOfActions.Insert("CheckSeriesCalculateStatus",
 		New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
		
	StructureOfActions.Insert("CheckCharacteristicsByOwner",);
	StructureOfActions.Insert("CheckFillPackageByOwner",);
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActions.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	
	If UseWarerooms Then
		StructureOfActions.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Goods", StructureOfActions);
	
	ListOfProperties = "ProductsInSet,
					|ItemVariantOfSet,
					|Products,
					|Characteristic,
					|Package,
					|Sum,
					|NumberOfPackages,
					|PercentRateOfManualDiscount,
					|Series";
	
	RowsToProcess = New Array();
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		CurrentRow.Partner = PredefinedValue("Catalog.Partners.RetailCustomer");
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Procedure UpdateItemsVisibility(CheckoutFiscalRegistrar)

	Items.CashRegisterShift.Visible                     = CheckoutFiscalRegistrar;
	Items.CashRegister.ReadOnly                     = CheckoutFiscalRegistrar;
	
	Items.ByPhysicalCountResults.Visible       = Not CheckoutFiscalRegistrar;
	Items.DiscountAmount.Visible                       = Not CheckoutFiscalRegistrar;
	
	Items.GoodsPremise.Visible = WarehousesServer.UseWarerooms(Object.Warehouse,Object.Date);
	
	Items.GroupFillIn.Enabled = ValueIsFilled(Object.Organization) And ValueIsFilled(Object.Currency);
	
	If CheckoutFiscalRegistrar Then
		Items.GoodsPercentRateOfManualDiscount.Visible                = False;
		Items.GoodsManualDiscount.Visible                  = False;
		Items.GoodsNumberOfPackagesAccounting.Visible             = False;
		Items.GoodsNumberOfPackagesReal.Visible             = False;
		Items.GoodsNumberOfPackages.AutoMarkIncomplete = True;
		Items.GoodsFillInByAccountingData.Visible                      = False;
		Items.GoodsFillInActualQuantityByAccountingData.Visible = False;
	Else
		Items.GoodsPercentRateOfManualDiscount.Visible                = True;
		Items.GoodsManualDiscount.Visible                  = True;
		Items.GoodsNumberOfPackagesAccounting.Visible             = Object.ByPhysicalCountResults;
		Items.GoodsNumberOfPackagesReal.Visible             = Object.ByPhysicalCountResults;
		Items.GoodsNumberOfPackages.AutoMarkIncomplete = Not Object.ByPhysicalCountResults;
		Items.GoodsNumberOfPackages.Enabled               = Not Object.ByPhysicalCountResults;
		Items.GoodsFillInByAccountingData.Visible                      = Object.ByPhysicalCountResults;
		Items.GoodsFillInActualQuantityByAccountingData.Visible = Object.ByPhysicalCountResults;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPricesByPriceKind(TypeOfFillingPrice)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	VTProducts_.LineNumber AS LineNumber,
	|	VTProducts_.Products AS Products,
	|	VTProducts_.Characteristic AS Characteristic
	|INTO Goods
	|FROM
	|	&VTProducts_ AS VTProducts_
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS LineNumber,
	|	Goods.Products,
	|	Goods.Characteristic,
	|	CAST(ISNULL(ItemsPrices.Price, 0) * CASE
	|			WHEN &Currency <> ItemsPrices.Currency
	|				THEN CASE
	|						WHEN ISNULL(RatesCutCurrencyPrices.CourseDenominator, 0) > 0
	|								AND ISNULL(RatesCutCurrencyPrices.CourseNumerator, 0) > 0
	|								AND ISNULL(CrossSectionRatesDocumentCurrency.CourseDenominator, 0) > 0
	|								AND ISNULL(CrossSectionRatesDocumentCurrency.CourseNumerator, 0) > 0
	|							THEN RatesCutCurrencyPrices.CourseNumerator * CrossSectionRatesDocumentCurrency.CourseDenominator / (CrossSectionRatesDocumentCurrency.CourseNumerator * RatesCutCurrencyPrices.CourseDenominator)
	|						ELSE 0
	|					END
	|			ELSE 1
	|		END AS NUMBER(31,2)) AS Price
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN InformationRegister.ItemsPrices.SliceLast(
	|				ENDOFPERIOD(&DocumentDate, DAY),
	|				PriceKind = &PriceKind
	|					AND (Products, Characteristic) IN
	|						(SELECT
	|							Goods.Products,
	|							Goods.Characteristic
	|						FROM
	|							Goods AS Goods)) AS ItemsPrices
	|		ON Goods.Products = ItemsPrices.Products
	|			AND Goods.Characteristic = ItemsPrices.Characteristic
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, BaseCurrency = &BaseCurrency) AS RatesCutCurrencyPrices
	|		ON (RatesCutCurrencyPrices.Currency = ItemsPrices.Currency)
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(&DocumentDate, Currency = &Currency AND BaseCurrency = &BaseCurrency) AS CrossSectionRatesDocumentCurrency
	|		ON (TRUE)
	|
	|ORDER BY
	|	LineNumber";
	
	Query.SetParameter("DocumentDate", Object.Date);
	Query.SetParameter("Currency",        Object.Currency);
	Query.SetParameter("PriceKind",       TypeOfFillingPrice);
	Query.SetParameter("VTProducts_",      Object.Goods.Unload());
	Query.SetParameter("BaseCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization));

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	RowsToProcess = New Array();
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
	
		TSRow = Object.Goods[Selection.LineNumber - 1];
		TSRow.Price = Selection.Price;
		RowsToProcess.Add(TSRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
		
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Function PutGoodsAndStockTypesInStorage()
	
	TableTypesOfStocks_ = Object.InventoryKinds.Unload();
	
	CollapsedTableTypesOfStocks = TableTypesOfStocks_.Copy();
	CollapsedTableTypesOfStocks.GroupBy("ItemsLocationAttributes,SetAccountingDimension,InventoryOwnerAttribute,CCDNumber,VATRate","Count,QuantityByGBRN,AmountIncludingVAT,VATAmount,ManualDiscount");
	Object.InventoryKinds.Load(CollapsedTableTypesOfStocks);
	
	GoodsTable = Object.Goods.Unload();
	CollapsedProductsTable = GoodsTable.Copy();
	CollapsedProductsTable.GroupBy("Products,Characteristic,Package,Price,VATRate,PercentRateOfManualDiscount,BatchesIndicationStatus,Partner,Seller,Premise,Series,ItemsLocationAttributes,ProductsInSet,ItemVariantOfSet,SetAccountingDimension","Count,NumberOfPackages,Sum,VATAmount,ManualDiscount,NumberOfPackagesReal,NumberOfPackagesAccounting");
	Object.Goods.Load(CollapsedProductsTable);
	
	OptionsForEditingInventoryTypes = InventoriesServer.PutGoodsAndStockTypesInStorage(ThisObject);
	
	Object.Goods.Load(GoodsTable);	
	Object.InventoryKinds.Load(TableTypesOfStocks_);
	
	Return OptionsForEditingInventoryTypes;
		
EndFunction

&AtServer
Procedure GetStockTypesFromStorage(ValueSelected)
	
	InventoriesServer.ProcessInputOfInventoryTypesManually(ValueSelected, ThisObject);
	
EndProcedure

&AtServer
Procedure FillInAccordingToAccountingDataOnServer()
	
	SetPrivilegedMode(True);
	
	Object.Goods.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductStock.Products    AS Products,
	|	ProductStock.Characteristic  AS Characteristic,
	|	ProductStock.Premise       AS Premise,
	|	ProductStock.InStockBalance AS NumberOfDays_1
	|INTO TempTable
	|FROM
	|	AccumulationRegister.ProductStock.Balance(&PointInTime, Warehouse = &Warehouse) AS ProductStock
	|
	|UNION ALL
	|
	|SELECT
	|	ProductStock.Products,
	|	ProductStock.Characteristic,
	|	ProductStock.Premise,
	|	-ProductStock.InStock
	|FROM
	|	AccumulationRegister.ProductStock AS ProductStock
	|WHERE
	|	ProductStock.Recorder = &Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TempTable.Products          AS Products,
	|	TempTable.Characteristic        AS Characteristic,
	|	TempTable.Premise             AS Premise,
	|	SUM(TempTable.NumberOfDays_1) AS NumberOfDays_1
	|FROM
	|	TempTable AS TempTable
	|
	|GROUP BY
	|	TempTable.Products,
	|	TempTable.Characteristic,
	|	TempTable.Premise";
	
	Query.SetParameter("Recorder",   Object.Ref);
	Query.SetParameter("Warehouse",         Object.Warehouse);
	Query.SetParameter("PointInTime", ?(ValueIsFilled(Object.Ref), Object.Date, Undefined));
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActions.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActions);
	
	RowsToProcess = New Array();
	Result = Query.Execute();
	Selection = Result.Select();
	While Selection.Next() Do
		
		NewRow = Object.Goods.Add();
		NewRow.Products   = Selection.Products;
		NewRow.Characteristic = Selection.Characteristic;
		NewRow.Premise      = Selection.Premise;
		NewRow.NumberOfPackagesAccounting = Selection.NumberOfDays_1;
		NewRow.NumberOfPackagesReal = Selection.NumberOfDays_1;
		NewRow.Partner = Catalogs.Partners.RetailCustomer;
		
		RowsToProcess.Add(NewRow);
		
	EndDo;

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);

EndProcedure

&AtServer
Procedure ReFillAccountingDataOnServer()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TSGoods.Products AS Products,
	|	TSGoods.Characteristic AS Characteristic,
	|	TSGoods.Premise AS Premise,
	|	CAST(TSGoods.Package AS Catalog.PackagesAndUnitsOfMeasure) AS Package
	|INTO TSGoods
	|FROM
	|	&TSGoods AS TSGoods
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductStockBalance.Products AS Products,
	|	ProductStockBalance.Characteristic AS Characteristic,
	|	ProductStockBalance.Premise AS Premise,
	|	ProductStockBalance.InStockBalance AS NumberOfDays_1
	|INTO TempTable
	|FROM
	|	AccumulationRegister.ProductStock.Balance(&PointInTime, Warehouse = &Warehouse) AS ProductStockBalance
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsInTrafficWarehouses.Products,
	|	GoodsInTrafficWarehouses.Characteristic,
	|	GoodsInTrafficWarehouses.Premise,
	|	-GoodsInTrafficWarehouses.InStock
	|FROM
	|	AccumulationRegister.ProductStock AS GoodsInTrafficWarehouses
	|WHERE
	|	GoodsInTrafficWarehouses.Recorder = &Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.Products AS Products,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Package AS Package,
	|	Goods.Premise AS Premise,
	|	SUM(ISNULL(TempTable.NumberOfDays_1, 0) / ISNULL(&QueryTextPackagingFactor, 1)) AS NumberOfDays_1
	|FROM
	|	TSGoods AS Goods
	|		LEFT JOIN TempTable AS TempTable
	|		ON (TempTable.Products = Goods.Products)
	|			AND (TempTable.Characteristic = Goods.Characteristic)
	|			AND (TempTable.Premise = Goods.Premise)
	|
	|GROUP BY
	|	Goods.Products,
	|	Goods.Package,
	|	Goods.Premise,
	|	Goods.Characteristic";
	
	Query.Text = StrReplace(Query.Text, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"Goods.Package",
			"Goods.Products"));
	Query.SetParameter("Recorder",   Object.Ref);
	Query.SetParameter("TSGoods",      Object.Goods.Unload(,"Products, Characteristic, Premise, Package"));
	Query.SetParameter("Warehouse",         Object.Warehouse);
	Query.SetParameter("PointInTime", ?(ValueIsFilled(Object.Ref), Object.Date, Undefined));
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	
	Result = Query.Execute();
	Selection = Result.Select();
	RowsToProcess = New Array();
	While Selection.Next() Do
		
		Filter = New Structure();
		Filter.Insert("Products",   Selection.Products);
		Filter.Insert("Characteristic", Selection.Characteristic);
		Filter.Insert("Package",       Selection.Package);
		Filter.Insert("Premise",      Selection.Premise);
		
		FoundRows = Object.Goods.FindRows(Filter);
			
		If FoundRows.Count() > 0 Then
			
			NewRow = FoundRows[0];
			NewRow.NumberOfPackagesAccounting = Selection.NumberOfDays_1;
			If NewRow.NumberOfPackages > Selection.NumberOfDays_1 Then
				NewRow.NumberOfPackagesReal = Selection.NumberOfDays_1;
			Else
				NewRow.NumberOfPackagesReal = Selection.NumberOfDays_1 - NewRow.NumberOfPackages;
			EndIf;
			
			If NewRow.NumberOfPackagesReal < NewRow.NumberOfPackagesAccounting Then
				NewRow.NumberOfPackages = NewRow.NumberOfPackagesAccounting - NewRow.NumberOfPackagesReal;
			Else
				NewRow.NumberOfPackages = 0;
			EndIf;
			
			RowsToProcess.Add(NewRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtServer
Procedure FillInActualQuantityAccordingToAccountingDataOnServer()
	
	StructureOfActions = New Structure;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
	RowsToProcess = New Array();
	
	For Each LineProducts_ In Object.Goods Do
		
		LineProducts_.NumberOfPackages = 0;
		LineProducts_.NumberOfPackagesReal = LineProducts_.NumberOfPackagesAccounting;
		RowsToProcess.Add(LineProducts_);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Procedure BasedOnInventoryResultsOnServer()
	
	CashRegisterDetails = Catalogs.CashRegisters.CashRegisterDetails(Object.CashRegister);
	
	If Object.ByPhysicalCountResults Then
		ReFillAccountingDataOnServer();
	EndIf;
	
	UpdateItemsVisibility(CashRegisterDetails.CashRegisterType = Enums.CashRegisterTypes.FiscalCashRegisters);
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
EndProcedure

&AtServer
Procedure ReFillOnServer()
	
	ErrorDescription = "";
	
	// We will get the status of the cash shift
	RegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister, Object.CashRegisterShift);
	
	TempTablesManager = New TempTablesManager;		
	TypesOfVATTaxationByCashShift = RetailSales.PrepareDataOnCashShiftReceipts(RegisterShiftState, TempTablesManager);
	
	// Fill out a Report on retail returns 
	RetailSales.FillOutRetailSalesReport(Object, RegisterShiftState, Object.VATTaxation, TempTablesManager, True, ErrorDescription);
	
	FillInStatusesForSpecifyingSeriesServer();
	
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateTotalsOfRetailSalesReport(Form)
	
	Form.AmountTotal        = Form.Object.Goods.Total("Sum");
	Form.ManualDiscount = Form.Object.Goods.Total("ManualDiscount");
	Form.DiscountAmount       = Form.ManualDiscount;
		
	If Form.AmountTotal > 0 Then
		
		Form.PercentRateOfManualDiscount = Form.ManualDiscount * 100 / (Form.AmountTotal + Form.DiscountAmount);
		Form.DiscountPercentage       = Form.PercentRateOfManualDiscount;
		
	ElsIf Form.DiscountAmount > 0 Then
		
		Form.PercentRateOfManualDiscount = 100;
		Form.DiscountPercentage       = 100;
		
	Else
		
		Form.PercentRateOfManualDiscount = 0;
		Form.DiscountPercentage       = 0;
		
	EndIf;
	
	If Not Form.Object.PriceIncludesVAT Then
		Form.AmountTotal = Form.AmountTotal + Form.Object.Goods.Total("VATAmount");
	EndIf;
	
	SaleIsSubjectToVAT = VATAccountingERPClientServer.DisplayNDSInResultsOfSalesDocument(Form.Object.VATTaxation); 
	If SaleIsSubjectToVAT Then
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.TotalSNDSPage;
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageVAT;
	Else
		Form.Items.PagesTotalGroup.CurrentPage = Form.Items.PageTotalWithoutVAT;
		Form.Items.VATPageGroup.CurrentPage   = Form.Items.PageExcludingVAT;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.RetailSalesReport));
	SetVisibilityOfSeriesElements();
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Object.Warehouse));
	
	Items.GoodsPremise.Visible = AccessRight("Read", Metadata.Catalogs.Warerooms);
	
	UseExcisableGoods = GetFunctionalOption("UseExcisableGoods");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	If UseExcisableGoods Then
		FillParameters =
			BatchProcessingOfTablePartClientServer.ParametersForFillingInExcisableItemAttribute(Object);
		StructureOfActions.Insert("FillInExcisableItemAttribute", FillParameters);
	EndIf;
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Goods", StructureOfActions);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	SetsServer.FillInServiceDetails(ThisObject);
	
	CalculateTotalsOfRetailSalesReport(ThisObject);
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	DefaultPOSTerminal = Catalogs.POSTerminals.DefaultPOSTerminal(Object.Organization);
	
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
EndProcedure

&AtServer
Procedure FillInSalesVATTaxation()
	
	FillParameters = Documents.RetailSalesReport.ParametersForFillingInSalesVATTaxation(Object);
	VATAccountingERP.FillInSalesVATTaxation(Object.VATTaxation, FillParameters);
	
EndProcedure

&AtClient
Procedure ManagingFieldsInPaymentByCreditCardTable(CurrentData)
	
		If CurrentData.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard")
			Or CurrentData.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.NSPKCertificate") Then

			CurrentData.ConnectionContract = PredefinedValue("Catalog.AcquiringContracts.EmptyRef");
			Items.PaymentWithPaymentCardsConnectionContract.ChoiceParameters = New FixedArray(New Array);

			ParametersOfAcquiringTerminalSelection = New Array;
			If CurrentData.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.NSPKCertificate") Then
				CurrentData.POSTerminal = PredefinedValue("Catalog.POSTerminals.EmptyRef");
				ParametersOfAcquiringTerminalSelection.Add(New ChoiceParameter("Filter.SupportsESFSSPayment", True));
			EndIf;
			Items.PaymentWithPaymentCardsPOSTerminal.ChoiceParameters = New FixedArray(ParametersOfAcquiringTerminalSelection);
			
		ElsIf CurrentData.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.InstantPayments") Then
			
			CurrentData.POSTerminal = PredefinedValue("Catalog.POSTerminals.EmptyRef");
			ParametersForSelectingActivationContract = New Array;
			ParametersForSelectingActivationContract.Add(New ChoiceParameter("Filter.MakingPaymentMethod", PredefinedValue("Enum.MakingPaymentMethods.InstantPayments")));
			Items.PaymentWithPaymentCardsConnectionContract.ChoiceParameters = New FixedArray(ParametersForSelectingActivationContract);
			
		Else
			CurrentData.ConnectionContract = PredefinedValue("Catalog.AcquiringContracts.EmptyRef");
			CurrentData.POSTerminal = PredefinedValue("Catalog.POSTerminals.EmptyRef");
		EndIf;	
	
EndProcedure

&AtServerNoContext
Function PaymentByPaymentCardsAvailableTypesOfPayment()
	
	SelectionListPaymentType = New Array;
	If GetFunctionalOption("UsePaymentByCards") Then
		SelectionListPaymentType.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);
	EndIf;
	
	Return SelectionListPaymentType;
EndFunction

#Region Localization

&AtServer
Procedure FillInAttributesOnChangingElementATServerLocalization(Item)
	
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
