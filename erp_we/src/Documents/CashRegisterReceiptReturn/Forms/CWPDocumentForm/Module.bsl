&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; // used by the series mechanism

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UseGiftCards      = GetFunctionalOption("UseGiftCards");
	UsePaymentByCards    = GetFunctionalOption("UsePaymentByCards");
	UseLoyaltyCards            = GetFunctionalOption("UseLoyaltyCards");
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseItemsBatch          = GetFunctionalOption("UseItemsBatch");
	UseSets                     = GetFunctionalOption("UseSets");
	
	If ValueIsFilled(Object.CashRegisterShift) Then
		UsedByKKTFZ54 = RetailSalesServerCall.UsedByKKTFZ54(Object.CashRegisterShift);
	Else
		UsedByKKTFZ54 = False;
	EndIf;
	
	FiscalOperationData = RetailSales.StructureOfFiscalTransactionData();

	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	SupportedPeripheralTypes = "BarcodeScanner,
	                                              |CustomerDisplay,
	                                              |FiscalCashRegisters,
	                                              |CREWITHDATATRANSFER,
	                                              |ReceiptPrinter,
	                                              |POSTerminal,
	                                              |DigitalRetailScales,
	                                              |MagneticStripeCardReaders";
	TMCommonUse.CustomizePeripherals(ThisObject, "");
	RetailSales.FillInEquipmentTable(ThisObject, SupportedPeripheralTypes);
	
	If Not Catalogs.CashRegisters.CashRegisterHasBeenSetUpForCWP() Then
		Items.GroupBottomCommandBarPayment.Enabled = False;
	EndIf;
	
	If UsePeripherals Then
		EquipmentAttached = EquipmentManagerServerCall.EquipmentByParameters(
			Undefined,
			Undefined,
			EquipmentManagerServerCall.GetClientSWorkplace()).Count() > 0;
		MeaningOpenFormWithConnectedHardware = Common.CommonSettingsStorageLoad(
			"CashRegisterReceipt", "OpenFormWithPeripherals");
		If MeaningOpenFormWithConnectedHardware = Undefined Then
			OpenFormWithPeripherals = EquipmentAttached;
		Else
			OpenFormWithPeripherals = MeaningOpenFormWithConnectedHardware And EquipmentAttached;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
		SetVisibilityOfSeriesElements();
		FillInServiceDetailsForProductRange();
		CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
		FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	EndIf;

	GetHardwareLinks();
	FillInCashRegisterReceiptDetails();
	SetFormItemsVisibility();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);
	
	GetStatusOfSBPPaymentByReceiptKMM();
	
	WhenCreatingReceipt();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If UsePeripherals Then
		
		If OpenFormWithPeripherals And FormOwner = Undefined Then
			
			AttachIdleHandler("OpenConnectedHardwareWaitHandlerForm", 0.5, True);
			
		Else
			
			AttachIdleHandler("StartHardwareConnectionHandlerWaiting", 0.1, True);
			
		EndIf;
		
	EndIf;
	
	RecalculateDocumentOnClient();
	
	If ForcefullyAuthorize And FormOwner = Undefined Then
		AttachIdleHandler("OpenAuthorizationWindow", 0.5, True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	StandardProcessing = False;
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Return;
	EndIf;
	
	If ForcedShutdown Or Exit Then
		Return;
	EndIf;
	
	BeforeClosingReceipt(Cancel);
	
EndProcedure

&AtClient
Procedure OnClose()

	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessingNotificationOnServer(EventName, Parameter, Source)

	AdditionalParameters = New Structure("EventName, Parameter, Source", EventName, Parameter, Source);
	FormEvents.WhenChangingElement(ThisObject, "Event", AdditionalParameters);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CachedValues",    CachedValues);
	AdditionalParameters.Insert("StandardProcessing",    True);
	AdditionalParameters.Insert("ServerCallRequired__", False);
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source, AdditionalParameters);
	CachedValues = AdditionalParameters.CachedValues;
	If AdditionalParameters.ServerCallRequired__ Then
		ProcessingNotificationOnServer(EventName, Parameter, Source);
	EndIf;
	If Not AdditionalParameters.StandardProcessing Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable()
		And Not ReadOnly Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			NotificationParameters = New Structure;
			NotificationParameters.Insert("EventName", EventName);
			NotificationParameters.Insert("Parameter", Parameter);
			NotificationParameters.Insert("Source", Source);
			DescriptionOfConfirmationNotification = New CallbackDescription("NotificationProcessingConfirmationEnd", ThisObject, NotificationParameters);
			ConfirmationOfChangesInCompositionOfPositions(DescriptionOfConfirmationNotification);
		EndIf;
	EndIf;
	// End Peripherals
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		RecalculateDocumentOnClient();
	EndIf;
	
	If EventName = "QuickProductSelected"
		And Parameter.OwnerForm = UUID Then
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		FillPropertyValues(ProductParameters_1, Parameter);
		ProductParameters_1.Seller = CurrentSeller;
		If CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller Then
			ProductParameters_1.Seller = Object.Cashier;
		EndIf;
		ProductParameters_1.NumberOfPackages = Parameter.NumberOfPackages;
		
		ProductParameters_1.Price = GetPriceBySelection(ProductParameters_1.Products, ProductParameters_1.Characteristic, ProductParameters_1.Series, ProductParameters_1.Package);
		
		AddToCart(ProductParameters_1);
		
	EndIf;
	
	If EventName = "UserIsAuthorized" Then
		
		If Parameter.Mode = "ChangeRights" Then
			ConfigureRightsForUser(Parameter.User);
			RecalculateDocumentOnClient();
		ElsIf Parameter.Mode = "CloseCashReceipt" Then
			ForcedShutdown = True;
			If IsOpen() Then
				Close();
			EndIf;
		EndIf;
		
	EndIf;
	
	If EventName = "ReadingFormCommands"
		And Parameter.Form = UUID Then
		
		Notify("ReadingFormCommands", New Structure("Form, OwnerForm, AddressInTempStorage", Parameter.OwnerForm, UUID, GetFormCommands(Parameter.OwnerForm)));
		
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns());
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet",   Parameter.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("PriceKind", Object.PriceKind);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	If EventName = "EquipmentAttached" Then
		RetailSalesClient.ProcessHardwareConnectedEvent(ThisObject, Parameter, Source);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 1, True);
	EndIf;
	
	If EventName = "ChangingCashShift" Then
		StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
		FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		ProductsSeriesRecalculatePrices();
		
		AdditionalParameters = New Structure;
		FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalParameters);
		If AdditionalParameters.Property("ServerCallRequired__") Then
			CachedValues.Insert("FormEvents");
			GoodsAtEndOfEditingOnServer(Items.Goods.CurrentData.GetID(), CachedValues);
		EndIf;
		
	EndIf;
	
	If ChoiceSource.FormName = "Document.CashRegisterReceiptReturn.Form.SelectDeferredReceipt" Then
		UploadNewReceipt(ValueSelected);
	EndIf;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then
		RetailSalesClient.UnblockForm(ThisObject);
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		RecalculateDocumentOnClient();
	EndIf;
	
	If Window <> Undefined Then
		Window.Activate();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
	
	SetVisibilityOfSeriesElements();
	FillInServiceDetailsForProductRange();
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);

	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CashRegisterReceiptReturn", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(CurrentObject, Documents.CashRegisterReceiptReturn));
	
	FillInServiceDetailsForProductRange();
	FillInServiceAttributesForReceipt();
	Items.FillInAmountByReceipt.Enabled = (Not Object.Status = Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
	RetailSalesClientServer.RecoverDataFromCacheOfDynamicDetailsOfFormTables(ThisObject);
	
	If Not WriteParameters.Property("TransactionMode") Or Not WriteParameters.TransactionMode Then
		// StandardSubsystems.AccessManagement
		AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
		// End StandardSubsystems.AccessManagement
		
		FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	FormEvents.BeforeWriteAtServer(ThisObject, CurrentObject, Cancel, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) 
		Or AdditionallyLockableElementOfSets(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm",        UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	FormEventsClient.OnActivateCell(ThisObject, Item);
	
	If Not Item.CurrentItem = Items.GoodsBarcode Then
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	If CurrentData = Undefined Then
		Items.GoodsBarcode.ChoiceList.Clear();
		Return;
	EndIf;
	
	ProductData_8 = New Structure;
	ProductData_8.Insert("Products",   CurrentData.Products);
	ProductData_8.Insert("Characteristic", CurrentData.Characteristic);
	ProductData_8.Insert("Package",       CurrentData.Package);
	ProductData_8.Insert("Series",          CurrentData.Series);
	
	Items.GoodsBarcode.ChoiceList.LoadValues(
		RetailSalesServerCall.GetProductBarcodes(ProductData_8));
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		Cancel = True;
		OpenSelection(Undefined);	
	Else
		If Copy Then
			SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRow(Item)
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	EstablishAvailabilityOfCWPElements(ThisObject, RetailSalesClientServer.AvailablePaymentMethods(ThisObject));
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);

	ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters, Copy);
	
	If Copy Then
		CurrentData = Item.CurrentData;
		If ValueIsFilled(CurrentData.RowID) Then
			CurrentData.RowID = String(New UUID);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	If UsePaymentByCards Then
		If Object.PaymentWithPaymentCards.Count() = 1 
			And TotalAmountOfPaymentByCreditCards > DocumentAmount - Items.Goods.CurrentData.Sum Then
			MessageText = NStr("vi = 'Không thể xóa dòng này. Số tiền thanh toán bằng thẻ nhiều hơn số tiền của hàng hóa. Không hỗ trợ giao dịch.';
								|ru = 'Нельзя удалить эту строку. Сумма оплаты платежными картами станет больше суммы товарных позиций. Операция не поддерживается.';
								|en = 'Cannot delete the line. Amount of payment by payment cards will be greater than the goods item amount. The transaction is unavailable.'; fa = 'Cannot delete the line. Amount of payment by payment cards will be greater than the goods item amount. The transaction is unavailable.';
								|it = 'Impossibile eliminare questa riga. L''importo di pagamento tramite carte di credito sarà maggiore dell''importo delle posizioni degli articoli. Operazione non supportata.';
								|pl = 'Nie można usunąć tego wiersza. Kwota płatności kartami płatniczymi będzie większa niż kwota pozycji towarowych. Operacja nie jest obsługiwana.';
								|tr = 'Bu satırı silemezsiniz. Kredi kartı ile ödenen tutar, ticari mal kalemlerinin toplamından daha fazla olacaktır. İşlem desteklenmemektedir.'");
			Message(MessageText);
			Cancel = True;
			Return;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		Cancel = True;
		
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters, False);
		
		CurrentRow = Items.Goods.CurrentData;
		If CurrentRow.NumberOfPackages <> 0 Then
			CurrentRow.NumberOfPackages = 0;
			GoodsNumberOfPackagesOnChange(Items.Goods);
			RecalculateDocumentOnClient();
		EndIf;
	Else
		ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
		ProductsClient.UpdateCachedValuesToAccountForSeries(Item, CachedValues, SeriesSpecificationParameters);
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
		AdditionalAttributes = New Structure("BeforeDeleteRow");
		FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalAttributes);
	EndIf;
		
	RetailSalesClient.ClearMessageWindow(ThisObject);
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	RecalculateDocumentOnClient();
	
	AdditionalAttributes = New Structure("ServerCallRequired__, AfterDeleteRow", False);
	FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalAttributes);
	If AdditionalAttributes.ServerCallRequired__ Then
		CachedValues.Insert("FormEvents");
	EndIf;

	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		AdditionalAttributes.ServerCallRequired__ = True;
		CachedValues.Insert("SeriesStatusesNeedToBeUpdated");
	EndIf;

	If AdditionalAttributes.ServerCallRequired__ Then
		GoodsAtEndOfEditingOnServer(Undefined, CachedValues);
	EndIf;

	If TypeOf(CachedValues) = Type("Structure")
		And CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		CachedValues.Delete("SeriesStatusesNeedToBeUpdated");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	RecalculateDocumentOnClient();
	
	curData = Item.CurrentData;
	If curData <> Undefined 
			And CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller
			And curData.Seller <> Object.Cashier Then
		curData.Seller = Object.Cashier;
	EndIf;
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalParameters);

	If AdditionalParameters.Property("ServerCallRequired__") Then
		CachedValues.Insert("FormEvents");
	EndIf;
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		CachedValues.Insert("SeriesStatusesNeedToBeUpdated");
		AdditionalParameters.Insert("ServerCallRequired__");
	EndIf;

	If AdditionalParameters.Property("ServerCallRequired__") Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()

	CurrentData = Items.Goods.CurrentData;
	If CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		IDCurrentRow = CurrentData.GetID();
	EndIf;

	GoodsAtEndOfEditingOnServer(IDCurrentRow, CachedValues);

	If CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		CachedValues.Delete("SeriesStatusesNeedToBeUpdated");
	EndIf;

EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(RowID, CachedValues)

	If CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues);
	EndIf;

	If CachedValues.Property("FormEvents") Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		CachedValues.Delete("FormEvents");
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	GoodsProductsOnChangeServer(CurrentRowID);
	
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisObject.FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);

	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);

EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	
	GoodsCharacteristicOnChangeServer(CurrentRowID);
	
EndProcedure

&AtServer
Procedure GoodsCharacteristicOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfActions = New Structure;
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		ThisObject.FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Characteristic", StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	If CurrentRow.Package <> CachedLines[Items.Goods.Name].Package Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Item", Item);
		AdditionalParameters.Insert("RowID", CurrentRow.GetID());		

		DescriptionOfConfirmationNotification = New CallbackDescription("GoodsPackagingUnitsInCaseOfChangeConfirmationEnd", ThisObject, AdditionalParameters);
		ConfirmationOfChangesInCompositionOfPositions(DescriptionOfConfirmationNotification);
	EndIf;
			
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;

	If ExceededNumberOfPackagingUnitsOfNonReturnedItemsAccordingToCurrentLine(CurrentRow) Then
		NumberOfPackagesByReceipt = ?(ValueIsFilled(CachedLines[Items.Goods.Name].NumberOfPackagesByReceipt), CachedLines[Items.Goods.Name].NumberOfPackagesByReceipt,
									CachedLines[Items.Goods.Name].NumberOfPackages);
		CurrentRow.NumberOfPackages = NumberOfPackagesByReceipt;
	EndIf;
	
	If CurrentRow.NumberOfPackages <> CachedLines[Items.Goods.Name].NumberOfPackages Then
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Item", Item);
		AdditionalParameters.Insert("RowID", CurrentRow.GetID());		

		DescriptionOfConfirmationNotification = New CallbackDescription("GoodsNumberOfPackagingUnitsInCaseOfChangeConfirmationEnd", ThisObject, AdditionalParameters);
		ConfirmationOfChangesInCompositionOfPositions(DescriptionOfConfirmationNotification);
	EndIf
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsVATRateOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value            		 = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
	ProductsSeriesRecalculatePrices(Items.Goods.CurrentData);

EndProcedure

&AtClient
Procedure GoodsPremiseOnChange(Item)
	RetailSalesClient.UpdateRoomInRowsOfTabularPartOfSeries(ThisObject, Items.Goods.CurrentData, CachedLines[Items.Goods.Name].Premise);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GetWeight(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	CurrentRow = EquipmentManagerTMClient.CurrentRow(ThisObject);
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	EquipmentManagerClient.StartGettingWeightWithElectronicScales(
		New CallbackDescription("GetWeightCompletion", ThisObject, CurrentRow),
		UUID);
	
EndProcedure

// Called from the other operations menu
&AtClient
Procedure CheckQuantityInTheDocument(Result, AdditionalParameters) Export
	
	If ReadOnly Then // The receipt has been punched. Changing information is prohibited.
		Return;
	EndIf;
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, "CheckQuantityInTheDocument", OpeningParameters);

	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	
	OpenForm(
		"CommonForm.CheckDocumentPopulation",
		OpeningParameters,
		ThisForm,,,,
		New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, 
		?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		
		RecalculateDocumentOnClient();
		
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	DescriptionOfConfirmationNotification = New CallbackDescription("BarcodeSearchPerformConfirmationEnd", ThisObject, Undefined);
	ConfirmationOfChangesInCompositionOfPositions(DescriptionOfConfirmationNotification);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure SetComposition(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
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
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Command", Command);
	AdditionalParameters.Insert("RowID", RowSelected);

	DescriptionOfConfirmationNotification = New CallbackDescription("SetCompositionConfirmationEnd", ThisObject, AdditionalParameters);
	ConfirmationOfChangesInCompositionOfPositions(DescriptionOfConfirmationNotification);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined, NotificationOnCompletion = Undefined)
	
	If ProductsClient.YouNeedServerCallToSpecifySeries(ThisObject,SeriesSpecificationParameters,Text, CurrentData)Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;

		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		AdditionalParameters.Insert("NotificationOnCompletion", NotificationOnCompletion);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,,,,
			New CallbackDescription("OpenSelectionOfSeriesCompletion", ThisObject, AdditionalParameters),
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	
	If Result <> Undefined Then
		ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm);
		ProductsSeriesRecalculatePrices();
	EndIf;
	
	If AdditionalParameters.Property("NotificationOnCompletion") Then
		RunCallback(AdditionalParameters.NotificationOnCompletion);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenTheSCCMOperationsMenu(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister", Object.CashRegister);
	FormOpenParameters.Insert("Cashier",   Object.Cashier);
	FormOpenParameters.Insert("ChangeTheCashRegisterOfTheKKM", True);
	FormOpenParameters.Insert("RestrictAvailableCashRegistersToOneCompany", ValueIsFilled(Object.CashRegisterReceipt));
	
	OpenForm("Document.CashRegisterReceipt.Form.CashRegisterTransactions", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTheOtherOperationsMenu(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister",       Object.CashRegister);
	FormOpenParameters.Insert("Cashier",         Object.Cashier);
	FormOpenParameters.Insert("ReadOnly", ReadOnly);
	FormOpenParameters.Insert("Document",       Object.Ref);
	FormOpenParameters.Insert("Organization",    Object.Organization);
	
	FormOpenParameters.Insert("CheckQuantityInTheDocument",         True);
	FormOpenParameters.Insert("SellingAGiftCertificate",         UseGiftCards);
	FormOpenParameters.Insert("GiftCertificateRefund",         UseGiftCards);
	FormOpenParameters.Insert("Lock",                         ForcefullyAuthorize);
	FormOpenParameters.Insert("PrintCommandAddressInTheTemporaryStorage", PrintCommandAddressInTheTemporaryStorage);
	
	OpenForm("Document.CashRegisterReceipt.Form.OtherTransactions", FormOpenParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure QuickGoods(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	OpenForm("Document.CashRegisterReceipt.Form.QuickGoods", New Structure("KeyboardShortcuts", KeyboardShortcuts), ThisObject);
	
EndProcedure

&AtClient
Procedure Peripherals_(Command)
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, False);
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)

	If ValueIsFilled(Object.CashRegisterReceipt) Then
		Return;
	EndIf;

	// &PerformanceMeasurement
	PerformanceMonitorClient.StartTimeMeasurement(True,
	"Document.CashRegisterReceiptReturn.CWPDocumentForm.Command.OpenSelection");
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	FormParameters = New Structure;

	PickingFormName = "DataProcessor.SelectGoodsToSalesDocument.Form";
	ClosingNotification1 = Undefined;
	HeaderParameter_ = NStr("vi = 'Chọn hàng hóa vào %Document%';
							|ru = 'Подбор товаров в %Document%';
							|en = 'Pick goods in %Document%'; fa = 'Pick goods in %Document%';
							|it = 'Selezione merci in %Document%';
							|pl = 'Wybór towarów w %Document%';
							|tr = '%Document% içindeki ürünlerin seçimi'");
	If ValueIsFilled(Object.Ref) Then
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", Object.Ref);
	Else
		HeaderParameter_ = StrReplace(HeaderParameter_, "%Document%", NStr("vi = 'Phiếu tính tiền';
																			|ru = 'чек ККМ';
																			|en = 'Receipt'; fa = 'دریافت';
																			|it = 'Scontrino fiscale';
																			|pl = 'Paragon kasy fiskalnej';
																			|tr = 'Yazar kasa makbuzu'"));
	EndIf;

	FormParameters.Insert("PriceKind", Object.PriceKind);
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

	OpenForm(PickingFormName, 
					FormParameters, 
					ThisObject, 
					UUID,
					,
					,
					ClosingNotification1
					,
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ChangeSeller(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	OpenForm(
		"Document.CashRegisterReceipt.Form.SelectSeller",,
		ThisObject,,,,
		New CallbackDescription("ChangeSellerCompletion", ThisObject));
	
EndProcedure

&AtClient
Procedure ChangeWareroom(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	If Items.Goods.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	TSRow = Object.Goods.FindByID(Items.Goods.SelectedRows[0]);
	
	Filter = New Structure("Owner", Object.Warehouse);
	OpeningParameters = New Structure();
	OpeningParameters.Insert("ChoiceMode", True);
	OpeningParameters.Insert("Filter", Filter);
	OpeningParameters.Insert("Products", TSRow.Products);
	OpeningParameters.Insert("Characteristic", TSRow.Characteristic);
	
	OpenForm(
		"Catalog.Warerooms.Form.ChoiceFormWithBalance",
		OpeningParameters,,,,,
		New CallbackDescription("ChangeWareroomCompletion", ThisObject, New Structure("TSRow", TSRow)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PayInCash(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PayInCashHandlingAlerts", ThisObject));
	
EndProcedure

&AtClient
Procedure PayByPaymentCard(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	If TotalAmountOfPaymentByCreditCards > DocumentAmount Then
		MessageText = NStr("vi = 'Số tiền thanh toán bằng thẻ lớn hơn số tiền hàng hóa. Không hỗ trợ giao dịch.';
							|ru = 'Сумма оплаты платежными картами больше суммы товарных позиций. Операция не поддерживается.';
							|en = 'The amount of payment by payment cards exceeds the goods item amount. The transaction is not supported.'; fa = 'The amount of payment by payment cards exceeds the goods item amount. The transaction is not supported.';
							|it = 'Importo del pagamento tramite carte di credito di più importi di posizioni di articoli. Operazione non supportata.';
							|pl = 'Kwota płatności kartami płatniczymi pozycji towarowych. Operacja nie jest obsługiwana.';
							|tr = 'Kredi kartıyla ödenen tutar, ticari ürün tutarından büyüktür. İşlem desteklenmiyor.'");
		CommonClient.MessageToUser(MessageText);
    Else
		RetailSalesClient.ProcessShiftState(
			ThisObject,
			New CallbackDescription("CancelPaymentUsingPaymentCardsProcessingNotifications", ThisObject));
	EndIf;
		
EndProcedure

&AtClient
Procedure MixedPayment(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);

	SelectedPaymentMethod = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("MixedPaymentNotificationProcessing", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure OpenPaymentCardPayments(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	AdditionalParameters = New Structure;
	RunCallback(
		New CallbackDescription("CancelPaymentsByPaymentCards", ThisObject, AdditionalParameters));

EndProcedure

&AtClient
Procedure PayForESFSS(Command)
	
	PayForESFSSLocalization();
	
EndProcedure

&AtClient
Procedure PayForSBP(Command)
	
	PayForSBPLocalization();
	
EndProcedure

&AtClient
Procedure ShowOnlyReturnedPositions(Command)
	
	Items.ShowOnlyReturnedPositions.Check = Not Items.ShowOnlyReturnedPositions.Check;
	DisplayModeOfProductsByReceipt = Not Items.ShowOnlyReturnedPositions.Check;

	Items.GoodsNumberOfPackagesByReceipt.Visible = DisplayModeOfProductsByReceipt;
	Items.GoodsNumberOfPackages.Title = NStr("vi = 'Cần trả lại';
											|ru = 'К возврату';
											|en = 'For return'; fa = 'برای برگشت';
											|it = 'In restituzione';
											|pl = 'Do zwrotu';
											|tr = 'İade edilecek'");
	If Not DisplayModeOfProductsByReceipt Then
		Items.GoodsNumberOfPackages.Title = NStr("vi = 'Số lượng';
												|ru = 'Количество';
												|en = 'Quantity'; fa = 'مقدار';
												|it = 'Количество';
												|pl = 'Quantity';
												|tr = 'Miktar'");
	EndIf;
	SetSelectionOfGoodsTableRows(DisplayModeOfProductsByReceipt, Items.Goods);
	
EndProcedure

&AtClient
Procedure FillInNumberOfPackagesByReceipt(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	CallbackOnCompletion = New CallbackDescription("FillInNumberOfPackagesByReceiptCompletion", ThisObject);
	MessageText = NStr("vi = 'Trong các dòng, sẽ điền số lượng cần trả lại bằng dữ liệu theo phiếu. Tiếp tục?';
						|ru = 'В строках количество к возврату будет заполнено данными по чеку. Продолжить?';
						|en = 'In the lines, the quantity to return will be filled with the receipt data. Continue?'; fa = 'In the lines, the quantity to return will be filled with the receipt data. Continue?';
						|it = 'В строках количество к возврату будет заполнено данными по чеку. Продолжить?';
						|pl = 'In the lines, the quantity to return will be filled with the receipt data. Continue?';
						|tr = 'Satırlarda, iade edilecek tutar fiş verilerine göre doldurulacaktır. Devam edilsin mi?'");
	ShowQueryBox(CallbackOnCompletion, MessageText, QuestionDialogMode.YesNo, 15,,,DialogReturnCode.No);
	
EndProcedure

&AtClient
Procedure FillInNumberOfPackagesByReceiptCompletion(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		RecountIsRequired = False;
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);	
		For Each TableRow In Object.Goods Do
			If Not TableRow.NumberOfPackages = TableRow.NumberOfPackagesByReceipt Then
				RecountIsRequired = True;
				TableRow.NumberOfPackages = TableRow.NumberOfPackagesByReceipt;
				TableRow.Count = TableRow.QuantityByReceipt;				
				TableRow.ReturnedPosition = True;
				BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
			EndIf;
		EndDo;
		If RecountIsRequired Then
			RecalculateDocumentOnClient();
		EndIf;
	EndIf;
	
EndProcedure

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

// Parameters:
// 	Command - FormCommand - 
&AtClient
Procedure QuickProductSelected(Command)
	
	FoundRows = QuickGoods.FindRows(New Structure("CommandName", Command.Name));
	
	NotificationParameters = New Structure();
	NotificationParameters.Insert("Products", FoundRows[0].Products);
	NotificationParameters.Insert("Characteristic", FoundRows[0].Characteristic);
	NotificationParameters.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	NotificationParameters.Insert("Package", FoundRows[0].Package);
	NotificationParameters.Insert("ItemsType", FoundRows[0].ItemsType);
	NotificationParameters.Insert("NumberOfPackages", 1);
	NotificationParameters.Insert("OwnerForm", UUID);
	
	If FoundRows.Count() > 0 Then
		Notify("QuickProductSelected", NotificationParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CloseInformationPanelErrorsWhenPrintingReceipt(Command)
	Items.InformationPanelErrorWhenPrintingReceipt.Title = "";
	InformationPanelErrorWhenPrintingReceiptText = "";
	Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible = False;
EndProcedure

#EndRegion

#Region Private

&AtClient
Function AdditionallyLockableElementOfSets(Field)
	Result = False;
	If Field.Name = Items.GoodsNumberOfPackagesByReceipt.Name Then
		Result = True;
	EndIf;
	Return Result;
EndFunction

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//
	
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsSum.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashRegisterReceipt");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsNumberOfPackages.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsPackage.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ProductsInSet");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	ThisIsReturnByReceipt = ValueIsFilled(Object.CashRegisterReceipt);
	Items.FormQuickGoods.Enabled = Not ThisIsReturnByReceipt;
	Items.FormKeyboardShortcutsQuickGoods.Enabled = Not ThisIsReturnByReceipt;
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, LoadingFromPDT = False)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ChangeQuantity = Not (Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"));
	
	StructureOfActionsWithAddedStrings = New Structure;
	If ControlProductRange Then
		StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	StructureOfActions.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
	StructureOfActions.ChangeQuantity                     = ChangeQuantity;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.LabelledWHProducts                = True;
	StructureOfActions.WHBarcodes                           = True;
	StructureOfActions.LoadingFromPDT                          = LoadingFromPDT;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	DataForProcessing = StructureOfActions;
	Attachable_AfterProcessingBarcodes();
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters,CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject,Object,StructureOfActionParameters,CachedValues);
	
EndProcedure

&AtServer
Procedure GetHardwareLinks()
	
	Workplace = EquipmentManagerServerCall.CustomerWorkplace();
	
	POSTerminals.Clear();
	POSTerminals = Catalogs.POSTerminals.ParametersOfAcquiringTerminalsByOrganization(Object.Organization, Workplace, UsePeripherals);
	
	If UsePeripherals Then
		Displays.LoadValues(EquipmentManagerServerCall.EquipmentByParameters("CustomerDisplay"));
	EndIf;
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	
EndProcedure

&AtClient
Procedure OpenConnectedHardwareWaitHandlerForm()
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, True);
	
EndProcedure

&AtClient
Procedure StartHardwareConnectionHandlerWaiting()
	
	CompletionDetails = New CallbackDescription("StartConnectingDevicesWhenYouOpenFormCompletion", RetailSalesClient, New Structure("Form", ThisObject));
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(CompletionDetails, ThisObject, SupportedPeripheralTypes);
	
EndProcedure

&AtClient
Procedure DisplayInformationOnBuyerSDisplay()

	If Not IsInputAvailable() Then
		Return;
	EndIf;
	
	NumberOfWHLines = Object.Goods.Count();
	
	CurrentRow = Items.Goods.CurrentRow;
	If CurrentRow = Undefined And NumberOfWHLines > 0 Then
		CurrentData = Object.Goods[NumberOfWHLines - 1];
		Items.Goods.CurrentRow = CurrentData.GetID();
	ElsIf CurrentRow = Undefined And NumberOfWHLines = 0 Then
		CurrentData = Undefined;
	Else
		CurrentData = Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	Dptext1 = NStr("vi = 'Xin chào!';
					|ru = 'Здравствуйте!';
					|en = 'Hello!'; fa = 'Hello!';
					|it = 'Salve!';
					|pl = 'Dzień dobry!';
					|tr = 'Merhaba!'");
	If CurrentData <> Undefined Then
		Dptext1 = ProductsClientServer.ProductPresentation(
				CurrentData.Products,
				CurrentData.Characteristic,
				,
				CurrentData.Series);
	EndIf;
	
	Dptext2 = RetailSalesClient.PrepareLineForDisplay(
		NStr("vi = 'Tổng cộng:';
			|ru = 'Итог:';
			|en = 'Total:'; fa = 'جمع:';
			|it = 'Totale:';
			|pl = 'Wyniki:';
			|tr = 'Toplam:'"), DocumentAmount);
	
	RetailSalesClient.DisplayTextOnBuyerSDisplays(
		ThisObject,
		Displays,
		Dptext1 + Chars.LF + Dptext2);
	
EndProcedure

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_1, AdditionalParameters) Export
	
	RetailSalesClient.UnblockForm(ThisObject);
	If BarcodeData_1 = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("StandardProcessing",    True);
	AdditionalParameters.Insert("BarcodeData_1",         BarcodeData_1);
	AdditionalParameters.Insert("CachedValues",    CachedValues);
	AdditionalParameters.Insert("ServerCallRequired__", False);
	
	FormEventsClient.WhenChangingElement(ThisObject, "GoodsSearchByBarcode", AdditionalParameters);
	
	If AdditionalParameters.ServerCallRequired__ Then
		BarcodeSearchCompletionOnServer(AdditionalParameters);
		FormEventsClient.WhenChangingElement(ThisObject, "CompleteBarcodeProcessing", AdditionalParameters);
	EndIf;
	
	If Not AdditionalParameters.StandardProcessing Then
		If Not (Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_")) Then
			RecalculateDocumentOnClient();
		EndIf;
		Return;
	EndIf;
	
	BarcodeData_5 = New Array;
	BarcodeData_5.Add(BarcodeData_1);
	ProcessBarcodes(BarcodeData_5);
	
EndProcedure

&AtServer
Procedure BarcodeSearchCompletionOnServer(AdditionalParameters)
	
	FormEvents.WhenChangingElement(ThisObject, "ProcessBarcodeData", AdditionalParameters);
	AfterProcessingBarcodes(AdditionalParameters);

	AdditionalParameters.BarcodeProcessingResult.AddedRows = New Array;
	AdditionalParameters.BarcodeProcessingResult.ModifiedRows  = New Array;
	
EndProcedure

// Parameters:
// 	Result - Arbitrary - result of processing the marking code
// 	AdditionalParameters - Undefined - not used
// 
&AtClient
Procedure ProcessingCodeMarkingPerformAction(Result, AdditionalParameters) Export
	
	FormEventsClient.WhenChangingElement(ThisObject, "ProcessingCodeMarkingPerformAction", Result);
	ProcessingCodeMarkingPerformActionServer(Result);
	FormEventsClient.WhenChangingElement(ThisObject, "CompleteBarcodeProcessing", Result);
	
EndProcedure

&AtClient
Procedure Attachable_OpenDataClarificationForm()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataForProcessing", DataForProcessing());

	FormEventsClient.WhenChangingElement(ThisObject, "Attachable_OpenDataClarificationForm", AdditionalParameters);

EndProcedure

&AtClient
Procedure Attachable_AfterProcessingBarcodes()
	
	ChangeQuantity = Not (Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"));
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(DataForProcessing(), CachedValues, ThisObject);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CachedValues", CachedValues);
	AdditionalParameters.Insert("DataForProcessing", DataForProcessing);
	AdditionalParameters.Insert("StandardProcessing", True);
	FormEventsClient.WhenChangingElement(ThisObject, "AfterProcessingBarcodes", AdditionalParameters);
	CachedValues = AdditionalParameters.CachedValues;

	If Not AdditionalParameters.StandardProcessing Then
		Return;
	EndIf;
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(DataForProcessing()) Then
		CurDataId = DataForProcessing().ArrayOfRowsWithSeries_[0];
		
		If CurDataId <> Undefined Then
			
			CurrentData = Object.Goods.FindByID(CurDataId);
			Items.Goods.CurrentRow = CurDataId;
			
			ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
			OpenSelectionOfSeries(, CurrentData);
		
		EndIf;
	EndIf;
	
	If ChangeQuantity Then
		RecalculateDocumentOnClient();
	EndIf;
	
	If DataForProcessing().CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = DataForProcessing().CurrentRow;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessTSStrings(AddedRows, ModifiedRows, CachedValues = Undefined, ActionsWhenChangingQuantity = Undefined) Export

	If ActionsWhenChangingQuantity = Undefined Then
		ActionsWhenChangingQuantity = New Structure;
		AddActionsToStructureWhenChangingNumberOfUnits(ActionsWhenChangingQuantity, Object);
	EndIf;
		
	ArraysForDifferentBatchProcessingOfStrings = RetailSales.SplitArrayOfStringsForDifferentTypesOfBatchProcessing(ThisObject, AddedRows);

	StructureOfActionsWithAddedStrings = New Structure;
	
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	UseWarerooms = WarehousesServer.UseWarerooms(Object.Warehouse,
		?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	If UseWarerooms Then
		StructureOfActionsWithAddedStrings.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
		
	CommonClientServer.SupplementStructure(StructureOfActionsWithAddedStrings, 
		ActionsWhenChangingQuantity, True);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject,
		"Products", StructureOfActionsWithAddedStrings);

	StructureOfActionsWithModifiedStrings = New Structure;
	CommonClientServer.SupplementStructure(StructureOfActionsWithModifiedStrings,
		ActionsWhenChangingQuantity, True);
	
	If ArraysForDifferentBatchProcessingOfStrings.NotItIsRequiredToFillInPrice.Count() Then
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ArraysForDifferentBatchProcessingOfStrings.NotItIsRequiredToFillInPrice,
			StructureOfActionsWithAddedStrings,
			Object.Goods);
	EndIf;

	If ArraysForDifferentBatchProcessingOfStrings.ItIsRequiredToFillInPrice.Count() Then
		If ControlProductRange Then
			StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActionsWithAddedStrings.Insert("FillInSalePrice",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ArraysForDifferentBatchProcessingOfStrings.ItIsRequiredToFillInPrice,
			StructureOfActionsWithAddedStrings,
			Object.Goods);
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		StructureOfActionsWithModifiedStrings,
		Object.Goods,
		CachedValues);
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	If AddedRows.Count() > 0 Then
		Items.Goods.CurrentRow = AddedRows[AddedRows.Count() - 1].GetID();
	ElsIf ModifiedRows.Count() > 0 Then
		Items.Goods.CurrentRow = ModifiedRows[ModifiedRows.Count() - 1].GetID();
	EndIf;
	
	If AddedRows.Count()>0 Or ModifiedRows.Count()>0 Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;

EndProcedure

&AtServer
Function AfterProcessingBarcodes(AdditionalParameters)
	
	BarcodeProcessingResult = AdditionalParameters.BarcodeProcessingResult; // - Structure
	CachedValues        = AdditionalParameters.CachedValues;
	
	If BarcodeProcessingResult.Property("BarcodeProcessingRequired") And BarcodeProcessingResult.BarcodeProcessingRequired Then
		
		LoadingFromPDT = False;
		
		If TypeOf(BarcodeProcessingResult.RawData) = Type("Structure") Then
			BarcodeData_5 = New Array;
			BarcodeData_5.Add(BarcodeProcessingResult.RawData);
		Else
			BarcodeData_5 = BarcodeProcessingResult.RawData;
		EndIf;
		
		ChangeQuantity = Not (Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"));

		StructureOfActionsWithAddedStrings = New Structure;
		If ControlProductRange Then
			StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		Else
			StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
		StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		StructureOfActionsWithAddedStrings.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
		
		StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);

		StructureOfActionsWithModifiedStrings = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
		
		DataForProcessing = BarcodingOfItemsClientServer.BarcodeProcessingParameters();
		DataForProcessing.Barcodes                              = BarcodeData_5;
		DataForProcessing.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
		DataForProcessing.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
		DataForProcessing.SeriesSpecificationParameters                 = SeriesSpecificationParameters;
		DataForProcessing.ChangeQuantity                     = ChangeQuantity;
		DataForProcessing.CalculateSets                     = True;
		DataForProcessing.LabelledWHProducts                = True;
		DataForProcessing.WHBarcodes                           = True;
		DataForProcessing.LoadingFromPDT                          = LoadingFromPDT;
		
		ProcessBarcodesServer(DataForProcessing, CachedValues);
		
		ModifiedRows = CorrectExcessOfNumberOfPackagingUnitsAccordingToNonReturnedItems(AdditionalParameters);
		If ModifiedRows.Count() Then
			ActionsWhenChangingQuantity = New Structure;
			AddActionsToStructureWhenChangingPackagesNumber(ActionsWhenChangingQuantity, Object);
			ProcessTSStrings(
				New Array,
				ModifiedRows,
				CachedValues,
				ActionsWhenChangingQuantity);
		EndIf;
		
	Else
		
		ProcessTSStrings(
			BarcodeProcessingResult.AddedRows,
			BarcodeProcessingResult.ModifiedRows,
			CachedValues);
		
		If ValueIsFilled(Object.CashRegisterReceipt) 
			And BarcodeProcessingResult.Property("ComparisonOfNomenclatureIsRequired") 
			And BarcodeProcessingResult.ComparisonOfNomenclatureIsRequired
			And BarcodeProcessingResult.BarcodesOfProductsForComparison.Count() Then
			For Each BarcodeForMatching In BarcodeProcessingResult.BarcodesOfProductsForComparison Do
				InformUserThatBarcodeWasNotFoundInSalesReceipt(BarcodeForMatching.Barcode);
			EndDo;
		EndIf;
		
	EndIf;
	
	FillInServiceDetailsForProductRange();
	FillInServiceAttributesForReceipt();
		
	Return BarcodeProcessingResult;
	
EndFunction

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
		StructureOfActions.Insert("RecalculateAmount");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, Var_Parameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods, True);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

// Returns:
// 	See BarcodingOfItemsClientServer.BarcodeProcessingParameters
&AtClient
Function DataForProcessing()
	
	Return DataForProcessing;
	
EndFunction

&AtServer
Procedure ProcessingCodeMarkingPerformActionServer(Result)
	
	FormEvents.WhenChangingElement(ThisObject, "ProcessingCodeMarkingPerformActionServer", Result);
	AfterProcessingBarcodes(Result);
	FormEvents.WhenChangingElement(ThisObject, "ProcessingCodeMarkingPerformActionCompletionServer", Result);
	
EndProcedure

#EndRegion

#Region SetOfSeries

&AtServer
Procedure SetVisibilityOfSeriesElements()
	
	Items.GoodsBatchesIndicationStatus.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.SpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseCostAccountingByBatches;
	Items.ProductsSeriesOptional.Visible = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	FormEvents.WhenChangingElement(ThisObject, "SetOfSeries");
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(Object, SeriesSpecificationParameters, IDCurrentRow, CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

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
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Series", StructureOfActions);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region Sets

&AtClientAtServerNoContext
Function DialColumns()
	
	Columns = New Array;
	Columns.Add("Products");
	Columns.Add("Characteristic");
	
	Columns.Add("Price");
	Columns.Add("Package");
	Columns.Add("Count");
	Columns.Add("NumberOfPackages");
	
	Columns.Add("VATRate");
	Columns.Add("VATAmount");
	Columns.Add("Sum");
	
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
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter)
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	AddressInTempStorage = SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "Goods");
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		// It is necessary to remove the lines with zero number of packages.
		Components = GetFromTempStorage(AddressInTempStorage);
		LinesWithZeroPackagingUnits = Components.FindRows(New Structure("NumberOfPackages", 0));
		If LinesWithZeroPackagingUnits.Count() Then
			For Each RowWithZeroCount In LinesWithZeroPackagingUnits Do
				Components.Delete(RowWithZeroCount);
			EndDo;
			AddressInTempStorage = PutToTempStorage(Components, AddressInTempStorage);
		EndIf;
	EndIf;	
	Return AddressInTempStorage;

EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	Data = GetFromTempStorage(AddressInTempStorage);
	FillInServiceDetails = False;
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		// We do not allow you to untie components from the kit
		Data.UntieFromSet = False;
		
		ChangedNumberOfPackagingUnits = False;
		// We check whether the number of packages of non-returned goods exceeds the sales receipt
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		StructureOfActionsForRecalculation = New Structure;
		StructureOfActionsForRecalculation.Insert("RecalculateNumberOfPackages");
		ArrayOfStringsToProcess = New Array;
		
		For Each ComponentString In Data.Components Do
			FilterRemainingGoodsByShelfLives = SelectionForSearchingByItem(ComponentString, UseItemVariants, False, UseSets);
			
			ProductLines_2 = Object.Goods.FindRows(FilterRemainingGoodsByShelfLives);
			If ProductLines_2.Count() 
				And ComponentString.Package <> ProductLines_2[0].Package Then
				ArrayOfStringsToProcess.Add(ProductLines_2[0]);
			EndIf;
		EndDo;
		
		RowsForDeletion = New Array;
		For Each ComponentString In Data.Components Do
			
			FilterRemainingGoodsByShelfLives = SelectionForSearchingByItem(ComponentString, UseItemVariants, False, UseSets);
			
			ProductLines_2 = Object.Goods.FindRows(FilterRemainingGoodsByShelfLives);
			If ProductLines_2.Count() Then
				GoodsStringFound = ProductLines_2[0];
				If Not ArrayOfStringsToProcess.Find(GoodsStringFound) = Undefined Then
					// Recalculate the number of packages according to the receipt
					DataToRecalculate = New Structure;
					DataToRecalculate.Insert("Package", ComponentString.Package);
					DataToRecalculate.Insert("Products", ComponentString.Products);
					DataToRecalculate.Insert("Count", GoodsStringFound.QuantityByReceipt);
					DataToRecalculate.Insert("NumberOfPackages", GoodsStringFound.NumberOfPackagesByReceipt);
					BatchProcessingOfTablePartServer.ProcessTSString(
						DataToRecalculate, StructureOfActionsForRecalculation, CachedValues);
					GoodsStringFound.NumberOfPackagesByReceipt = DataToRecalculate.NumberOfPackages;
				EndIf;
			EndIf;
			
			CheckingExcess = NumberOfPackagingUnitsOfNonReturnedItemsHasBeenExceeded(Object, FilterRemainingGoodsByShelfLives, ComponentString.NumberOfPackages, False);
			If CheckingExcess.Result Then
				If CheckingExcess.FoundRow = Undefined Then
					RowsForDeletion.Add(ComponentString);
				Else
					ChangedNumberOfPackagingUnits = True;
					ComponentString.NumberOfPackages = CheckingExcess.FoundRow.NumberOfPackagesByReceipt;
					ComponentString.Count = CheckingExcess.FoundRow.QuantityByReceipt;
				EndIf;
			EndIf;
			If Not CheckingExcess.FoundRow = Undefined
				And ComponentString.DocumentRowNumber = 0 Then
				ComponentString.DocumentRowNumber = CheckingExcess.FoundRow.LineNumber;
				If ComponentString.Price <> CheckingExcess.FoundRow.Price Then
					ChangedNumberOfPackagingUnits = True;
					ComponentString.Price = CheckingExcess.FoundRow.Price;
				EndIf;
				If ComponentString.Package <> CheckingExcess.FoundRow.Package Then
					ComponentString.Package = CheckingExcess.FoundRow.Package;
				EndIf;
			EndIf;
		EndDo;
		For Each RowForDeletion In RowsForDeletion Do
			Data.Components.Delete(RowForDeletion);
		EndDo;
    	If ChangedNumberOfPackagingUnits Then
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings, Object);
		EndIf;
		
		// It is necessary to add lines of components with zero number of packages.
		CompositionOfOriginalSet = Object.Goods.FindRows(New Structure("ProductsInSet,ItemVariantOfSet", Data.ProductsInSet, Data.ItemVariantOfSet));
		If CompositionOfOriginalSet.Count() <> Data.Components.Count() Then
			For Each AccessoriesOfOriginalSet In CompositionOfOriginalSet Do
				FilterRemainingGoodsByShelfLives = SelectionForSearchingByItem(AccessoriesOfOriginalSet, UseItemVariants, False, UseSets);
				FoundComponentStrings = Data.Components.FindRows(FilterRemainingGoodsByShelfLives);
				If FoundComponentStrings.Count() = 0 Then
					// Adding lines with zero number of packages
					FillInServiceDetails = True;
					AccessoriesOfOriginalSet.NumberOfPackages = 0;
					AccessoriesOfOriginalSet.Count = 0;
					AccessoriesOfOriginalSet.Sum = 0;
					AccessoriesOfOriginalSet.VATAmount = 0;
					NewAccessories = Data.Components.Add();
					FillPropertyValues(NewAccessories, AccessoriesOfOriginalSet);
					NewAccessories.DocumentRowNumber = AccessoriesOfOriginalSet.LineNumber;
				EndIf;
			EndDo;
		EndIf;
	EndIf;

	DataParameters = New Structure;
	DataParameters.Insert("Data", Data);
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns());
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);

	If ValueIsFilled(Object.CashRegisterReceipt) And FillInServiceDetails Then
		FillInServiceDetailsForProductRange();
		FillInServiceAttributesForReceipt();		
	EndIf;
	
EndProcedure

#EndRegion

#Region PrintingReceipt

&AtServer
Function ParametersOfReceiptFiscalizationOperationOnServer()
	
	Return ParametersOfReceiptFiscalizationOperationOnServerLocalization();
	
EndFunction

&AtClient
Function ParametersOfReceiptFiscalizationOperation()
	
	Return ParametersOfReceiptFiscalizationOperationOnServer();
	
EndFunction

&AtClient
Procedure IssueCashReceipt()
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	HasErrors = False;
	
	If Object.DeletionMark Then
		CommonClient.MessageToUser(NStr("vi = 'Chứng từ được đặt dấu xóa';
										|ru = 'Документ помечен на удаление';
										|en = 'The document is marked for deletion'; fa = 'The document is marked for deletion';
										|it = 'Il documento è stato contrassegnato per la cancellazione';
										|pl = 'Dokument zaznaczono do usunięcia';
										|tr = 'Belge silinmek üzere işaretlendi'"), Object.Ref,,,HasErrors);
	EndIf;
	
	Modified = True;
	
	If HasErrors Or Not CheckFilling() Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	ParametersOfReceiptFiscalizationOperation = ParametersOfReceiptFiscalizationOperation();
	PrintingReceiptAfterRecordingChangesLocalization(ParametersOfReceiptFiscalizationOperation);
	
EndProcedure

#Region FiscalTransaction

&AtServer
Function RecordFiscalTransactionOnServer(RetryRecordingIsRequired, DetailsOfCashNodeSFiscalOperation)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
	WriteParameters.Insert("TransactionMode", True);

	Result = RetailSales.RecordFiscalTransactionOnServer(ThisObject, DetailsOfCashNodeSFiscalOperation, WriteParameters);
	
	If Result Then
		WriteParameters.Insert("TransactionMode", False);
		AfterWriteAtServer(FormAttributeToValue("Object"), WriteParameters);
	Else
		RetryRecordingIsRequired = True;
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
		FillInServiceDetailsForProductRange();
	EndIf;
		
	Return Result;
EndFunction

#EndRegion

#EndRegion

#Region Other

&AtClient
Procedure OpenAuthorizationWindow()
	
	OpenForm("Document.CashRegisterReceipt.Form.Authorization", New Structure("Mode", "ChangeRights"), ThisObject);
	
EndProcedure

&AtClient
Procedure ConfirmationOfChangesInCompositionOfPositions(CallbackDescriptionOnCompletion)

	If ValueIsFilled(Object.CashRegisterReceipt) And ThisIsFullReturnOnSalesShift And TotalAmountOfPaymentByCreditCards <> 0 Then
		MessageText = NStr("vi = 'Theo phiếu trả lại, có thể thực hiện hủy bỏ thanh toán. Việc thay đổi mục sản phẩm sẽ khiến thao tác này không khả dụng. Tiếp tục thay đổi?';
							|ru = 'По чеку возврата можно выполнить отмену оплаты. Изменение товарных позиций сделает эту операцию недоступной. Продолжить изменение?';
							|en = 'You can use the refund receipt to cancel the payment. If you change the items, this operation will be unavailable. Continue?'; fa = 'You can use the refund receipt to cancel the payment. If you change the items, this operation will be unavailable. Continue?';
							|it = 'По чеку возврата можно выполнить отмену оплаты. Изменение товарных позиций сделает эту операцию недоступной. Продолжить изменение?';
							|pl = 'You can use the refund receipt to cancel the payment. If you change the items, this operation will be unavailable. Continue?';
							|tr = 'İade makbuzundaki ödeme iptal edilebilir. Ürün pozisyonlarının değiştirilmesi bu işlemi kullanılamaz hale getirecektir. Değişikliğe devam edilsin mi?'");
		ShowQueryBox(CallbackDescriptionOnCompletion, MessageText, QuestionDialogMode.YesNo);
	Else
		RunCallback(CallbackDescriptionOnCompletion, DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtClient
Procedure BarcodeSearchPerformConfirmationEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
		BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	EndIf;
	
EndProcedure

&AtClient
Procedure SetCompositionConfirmationEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		CurrentRow = Object.Goods.FindByID(AdditionalParameters.RowID);
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns());
		
		SetAddressInTemporaryStorage = SetAddressInTemporaryStorage(KitParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("AddressInTempStorage", SetAddressInTemporaryStorage);
		OpeningParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
		OpeningParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
		OpeningParameters.Insert("PriceIncludesVAT", Object.PriceIncludesVAT);
		OpeningParameters.Insert("VATTaxation", Object.VATTaxation);
		OpeningParameters.Insert("Currency", Object.Currency);
		OpeningParameters.Insert("PriceKind", Object.PriceKind);
		OpeningParameters.Insert("Date", Object.Date);
		OpeningParameters.Insert("Ref", Object.Ref);
		OpeningParameters.Insert("Warehouse", Object.Warehouse);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsNumberOfPackagingUnitsInCaseOfChangeConfirmationEnd(Result, AdditionalParameters) Export

	CurrentRow = Object.Goods.FindByID(AdditionalParameters.RowID);
	If Result = DialogReturnCode.Yes Then
		CurrentRow.ReturnedPosition = (CurrentRow.NumberOfPackages > 0);
		SetSelectionOfGoodsTableRows(DisplayModeOfProductsByReceipt, Items.Goods);

		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		RecalculateDocumentOnClient();
	Else
		CurrentRow.NumberOfPackages = CachedLines[Items.Goods.Name].NumberOfPackages;
		CurrentRow.Count = CachedLines[Items.Goods.Name].Count;
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsPackagingUnitsInCaseOfChangeConfirmationEnd(Result, AdditionalParameters) Export
	
	CurrentRow = Object.Goods.FindByID(AdditionalParameters.RowID);
	If Result = DialogReturnCode.Yes Then
		
		If ValueIsFilled(Object.CashRegisterReceipt) Then
			// Recalculate the number of packages according to the receipt
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfPackages");
			DataToRecalculate = New Structure;
			DataToRecalculate.Insert("Package", CurrentRow.Package);
			DataToRecalculate.Insert("Products", CurrentRow.Products);
			DataToRecalculate.Insert("Count", CurrentRow.QuantityByReceipt);
			DataToRecalculate.Insert("NumberOfPackages", CurrentRow.NumberOfPackagesByReceipt);
			BatchProcessingOfTablePartClient.ProcessTSString(DataToRecalculate, StructureOfActions, CachedValues);
			
			CurrentRow.NumberOfPackagesByReceipt = DataToRecalculate.NumberOfPackages;
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
			
			CurrentRow.NumberOfPackages = DataToRecalculate.NumberOfPackages;
			If CurrentRow.NumberOfPackages > CurrentRow.NumberOfPackagesByReceipt Then
				CurrentRow.NumberOfPackages = CurrentRow.NumberOfPackagesByReceipt;
			EndIf;
		EndIf;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		
		If CurrentRow.Count > 0 And Not ValueIsFilled(Object.CashRegisterReceipt) Then
			StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
		ElsIf ValueIsFilled(Object.PriceKind) Then
			If ControlProductRange Then
				StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
			Else
				StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
			EndIf;
		EndIf;
		
		StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
		StructureOfActions.Insert("RecalculateAmount");
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		RecalculateDocumentOnClient();
		
	Else
		CurrentRow.Package = CachedLines[Items.Goods.Name].Package;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessingConfirmationEnd(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		BarcodeData_5 = EquipmentManagerTMClient.ConvertDataFromScannerToArray(AdditionalParameters.Parameter);
		ProcessBarcodes(BarcodeData_5);
	EndIf;
	
EndProcedure

&AtClient
Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetailSalesClient.ClearMessageWindow(ThisObject);
		RetryRecordingIsRequired = False;
		If AdditionalParameters.ProcedureName = "WriteAtServer" Then
			OperationResult = WriteAtServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "PostponeOnServer" Then
			OperationResult = PostponeOnServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "RecordFiscalTransactionOnServer" Then
			OperationResult = RecordFiscalTransactionOnServer(RetryRecordingIsRequired, AdditionalParameters.DetailsOfCashNodeSFiscalOperation);
		EndIf;
		
		If OperationResult Then
			
			RunCallback(
				AdditionalParameters.CallbackDescription,
				?(AdditionalParameters.ReturnFunctionResult, OperationResult, AdditionalParameters.ResultOfSuccessfulImplementation));
			
		Else
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
				AdditionalParameters.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			
		EndIf;
		
	Else
		
		RunCallback(
			AdditionalParameters.CallbackDescription,
			?(AdditionalParameters.ReturnFunctionResult, AdditionalParameters.OperationResult, AdditionalParameters.CancellationResult_));
		
	EndIf;
	
EndProcedure

&AtServer
Function WriteAtServer(RetryRecordingIsRequired = Undefined)
	
	Object.Date = CurrentSessionDate();
	RetailSalesClientServer.SaveDataOfDynamicAttributesOfFormTablesToCache(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Value = FormAttributeToValue("Object", Type("DocumentObject.CashRegisterReceiptReturn"));
		Value.SetNewObjectRef(Documents.CashRegisterReceiptReturn.GetRef());
		ValueToFormData(Value, Object);
	EndIf;
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add();
		LockItem.Region = "Document.CashRegisterReceiptReturn";
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Ref", Object.Ref);
		Block.Lock();
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
		WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
		WriteParameters.Insert("TransactionMode", True);
		
		Result = Write(WriteParameters);
		
		CommitTransaction();
		
		WriteParameters.Insert("TransactionMode", False);
		AfterWriteAtServer(FormAttributeToValue("Object"), WriteParameters);
		
	Except
		
		RollbackTransaction();
		RetryRecordingIsRequired = True;
		Return False;
		
	EndTry;
	
	If Not Result Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
		
		FillInServiceDetailsForProductRange();
		RetailSalesClientServer.RecoverDataFromCacheOfDynamicDetailsOfFormTables(ThisObject);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function WriteAtClient(RetryRecordingIsRequired = Undefined)
	
	If Modified Then
		
		If Object.Goods.Total("NumberOfPackages") = 0 Then
			MessageText = NStr("vi = 'Cần chỉ ra ít nhất một mặt hàng bị trả lại.';
								|ru = 'Необходимо указать хотя бы одну возвращаемую позицию.';
								|en = 'Specify at least one item to return.'; fa = 'Specify at least one item to return.';
								|it = 'Необходимо указать хотя бы одну возвращаемую позицию.';
								|pl = 'Specify at least one item to return.';
								|tr = 'En az bir iade pozisyonu belirtmeniz gerekmektedir.'");
			CommonClient.MessageToUser(MessageText);
			
			Return False;
		EndIf;
		
		Result = WriteAtServer(RetryRecordingIsRequired);
		
		If Result Then
			Notify("Write_CashRegisterReceiptReturn", New Structure, Undefined);
		EndIf;
		
		Return Result;
		
	Else
		Return True;
	EndIf;
	
EndFunction

&AtServer
Function PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded = False)
	
	TabularPartProducts = Object.Goods.Unload();
	If TabularPartProducts.Columns.Find("MarkedProducts") <> Undefined Then
		CurrentRowNumber = TabularPartProducts.Count()-1;
		While CurrentRowNumber >= 0 Do
			If TabularPartProducts[CurrentRowNumber].MarkedProducts Then
				TabularPartProducts.Delete(CurrentRowNumber);
				OnlyNonLabeledProductsHaveBeenUnloaded = True;
			EndIf;
			CurrentRowNumber = CurrentRowNumber - 1;
		EndDo;
	EndIf;

	TabularPartProducts.GroupBy("RowID, ProductsInSet, ItemVariantOfSet, USAISProducts, Products, Characteristic, Series, BatchesIndicationStatus, ItemsType, ItemVariantsAreUsed, Package, NumberOfPackages, Count");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete              = New Array;
	ModifiedRowsToProcess = New Array;
	AddedRowsForProcessing = New Array;
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure("ProductsInSet, ItemVariantOfSet, Products, Characteristic, Series, ItemVariantsAreUsed, Package");
		FillPropertyValues(Filter, SourceRow);
		FoundRows = Object.Goods.FindRows(Filter);
		
		For Each TSRow In FoundRows Do

			If SourceRow.NumberOfPackages = 0 Then
				Break;
			EndIf;
			
			If TSRow.NumberOfPackages = 0
				And SourceRow.NumberOfPackages < 0 Then
				Continue;
			EndIf;
			
			If SourceRow.NumberOfPackages >= 0 Then
				
				TSRow.NumberOfPackages = TSRow.NumberOfPackages + SourceRow.NumberOfPackages;
				SourceRow.NumberOfPackages = 0;
				
			Else
				
				QuantityToWriteOff = -SourceRow.NumberOfPackages;
				QuantityPerLine   = TSRow.NumberOfPackages;
				
				If QuantityToWriteOff > QuantityPerLine Then
					SourceRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
					TSRow.NumberOfPackages       = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages       = QuantityPerLine - QuantityToWriteOff;
				EndIf;
				
			EndIf;
			
			If TSRow.NumberOfPackages = 0 Then
				
				If LinesToDelete.Find(TSRow) = Undefined Then
					LinesToDelete.Add(TSRow);
				EndIf;

			Else
				ModifiedRowsToProcess.Add(TSRow);
			EndIf;
			
		EndDo;
		
		If FoundRows.Count() = 0 Then
			TSRow = Object.Goods.Add();
			FillPropertyValues(TSRow, SourceRow);
			AddedRowsForProcessing.Add(TSRow);
		EndIf;
		
	EndDo;
	
	CachedValuesForBatchProcessing = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillOutSellerSForm",  New Structure("Seller", CurrentSeller));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValuesForBatchProcessing);

	CachedValuesForBatchProcessing = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRowsForProcessing,
		StructureOfActions,
		Object.Goods,
		CachedValuesForBatchProcessing);

	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	FillInServiceDetailsForProductRange();
	
	FormEvents.WhenChangingElement(ThisObject, "QuantityVerificationCompleted", ReturnParameters);

EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingNumberOfUnits(StructureOfActions, Object)
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInFeatureAttribute      = New Structure("Products", "ItemVariantsAreUsed");
	FillInProductTypeAttribute_                 = New Structure("Products", "ItemsType");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products_2", StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	SetsServer.FillInServiceDetails(ThisObject);

EndProcedure

&AtClientAtServerNoContext
Function PaymentInformation(Form)
	
	PaymentWithPaymentCardsCanceled = 0;
	
	PaymentCards_ = RetailSalesClientServer.PaymentLinesWithPaymentCards(Form.Object.PaymentWithPaymentCards);
	For Each TSRow In PaymentCards_ Do
		If TSRow.PaymentIsCanceled Then
			PaymentWithPaymentCardsCanceled = PaymentWithPaymentCardsCanceled + TSRow.Sum;
		EndIf;
	EndDo;
	
	Form.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Form.Object.Goods, Form.Object.PriceIncludesVAT);
	
	If Form.Object.PriceIncludesVAT Then
		AmountWithoutADiscount = Form.DocumentAmount;
	Else
		AmountWithoutADiscount = Form.DocumentAmount - Form.Object.Goods.Total("VATAmount");
	EndIf;
	
	PaymentInformation = New Structure;
	PaymentInformation.Insert("Document",               Form.Object.Ref);
	
	PaymentInformation.Insert("CashPayment",               Form.Object.IssueInCash);
	PaymentInformation.Insert("PaymentCards",         Form.TotalAmountOfPaymentByCreditCards);

	PaymentInformation.Insert("PaymentCardsCanceled", PaymentWithPaymentCardsCanceled);
	PaymentInformation.Insert("GiftCertificates",  0);
	PaymentInformation.Insert("BonusPoints",          0);
	
	PaymentInformation.Insert("DocumentAmount",        Form.DocumentAmount);
	PaymentInformation.Insert("AmountToPay",          AmountWithoutADiscount);
	PaymentInformation.Insert("DiscountAmount",           0);
	
	PaymentInformation.Insert("AvailablePaymentMethods",   RetailSalesClientServer.AvailablePaymentMethods(Form));
	
	PaymentInformation.Insert("TotalPaid_", PaymentInformation.CashPayment + PaymentWithPaymentCardsCanceled);
	
	PaymentInformationLocalization(Form, PaymentInformation);

	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	Form.TotalAmountOfPaymentByCreditCards = 0;
	If Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		Form.TotalAmountOfPaymentByCreditCards = PaymentWithPaymentCardsCanceled;
	Else
		For Each CombinationOfUndeliveredPaymentAmounts In Form.CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards Do
			If CombinationOfUndeliveredPaymentAmounts <= AmountOfSurchargeIsEstimated
				And CombinationOfUndeliveredPaymentAmounts > Form.TotalAmountOfPaymentByCreditCards Then
				Form.TotalAmountOfPaymentByCreditCards = CombinationOfUndeliveredPaymentAmounts;
			EndIf;	
		EndDo;
	EndIf;	
	Return PaymentInformation;
	
EndFunction

&AtClientAtServerNoContext
Procedure SetSelectionOfGoodsTableRows(DisplayModeOfProductsByReceipt, GoodsItems)
	GoodsLineSelection = New Structure;
	If Not DisplayModeOfProductsByReceipt Then
		GoodsLineSelection.Insert("ReturnedPosition", True);	
	EndIf;
	GoodsItems.RowFilter = New FixedStructure(GoodsLineSelection);	
EndProcedure

&AtServer
Procedure FillInServiceAttributesForReceipt()

	NonReturnedPositionsByReceipt = Undefined;
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		NonReturnedPositionsByReceipt = GetFromTempStorage(CashRegisterReceiptDetails.AddressOfTableOfNonReturnedItems);
	EndIf;
	
	NumericTypeDescriptions = New TypeDescription("Number",,,
		New NumberQualifiers(15, 3, AllowedSign.Nonnegative));
	
	DataTableForRecalculation = New ValueTable();
	DataTableForRecalculation.Columns.Add("Package", New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	DataTableForRecalculation.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
	DataTableForRecalculation.Columns.Add("Count", NumericTypeDescriptions);
	DataTableForRecalculation.Columns.Add("NumberOfPackages", NumericTypeDescriptions);
	DataTableForRecalculation.Columns.Add("RowID", New TypeDescription("Number",,,New NumberQualifiers(10)));
	
	If Not NonReturnedPositionsByReceipt = Undefined Then

		For Each LineProducts_ In Object.Goods Do
			If LineProducts_.NumberOfPackages > 0 Then
				DataOfNonReturnedPosition = NonReturnedPositionsByReceipt[LineProducts_.GetID()];
				If Not DataOfNonReturnedPosition = Undefined 
					And DataOfNonReturnedPosition.Package <> LineProducts_.Package Then
					DataToRecalculate = DataTableForRecalculation.Add();
					DataToRecalculate.Package = LineProducts_.Package;
					DataToRecalculate.Products = LineProducts_.Products;
					DataToRecalculate.Count = DataOfNonReturnedPosition.Count;
					DataToRecalculate.NumberOfPackages = DataOfNonReturnedPosition.NumberOfPackages;
					DataToRecalculate.RowID = LineProducts_.GetID();
				EndIf;
			EndIf;
		EndDo;
		
		If DataTableForRecalculation.Count() Then
			DataTableForRecalculation.Indexes.Add("RowID");

			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfPackages");

			BatchProcessingOfTablePartServer.TreatTS(DataTableForRecalculation, StructureOfActions, CachedValues);
		EndIf;
	
	EndIf;
	
	For Each LineProducts_ In Object.Goods Do
		NewValueNumberOfPackagingUnitsByReceipt = 0;
		NewValueQuantityByReceipt = 0;
		NewValueReturnedPosition = True;
		If Not NonReturnedPositionsByReceipt = Undefined Then
			RowID = LineProducts_.GetID();
			DataOfNonReturnedPosition = NonReturnedPositionsByReceipt[RowID];
			If Not DataOfNonReturnedPosition = Undefined Then
				NewValueNumberOfPackagingUnitsByReceipt = DataOfNonReturnedPosition.NumberOfPackages;
				NewValueQuantityByReceipt = DataOfNonReturnedPosition.Count;
				DataFoundForRecalculation = DataTableForRecalculation.FindRows(New Structure("RowID", RowID));
				If DataFoundForRecalculation.Count() > 0 Then
					NewValueNumberOfPackagingUnitsByReceipt = DataFoundForRecalculation[0].NumberOfPackages;
				EndIf;
			EndIf;
			NewValueReturnedPosition = (LineProducts_.NumberOfPackages > 0);
		EndIf;
		If LineProducts_.NumberOfPackagesByReceipt <> NewValueNumberOfPackagingUnitsByReceipt Then
			LineProducts_.NumberOfPackagesByReceipt = NewValueNumberOfPackagingUnitsByReceipt;
		EndIf;
		If LineProducts_.QuantityByReceipt <> NewValueQuantityByReceipt Then
			LineProducts_.QuantityByReceipt = NewValueQuantityByReceipt;
		EndIf;
		If LineProducts_.ReturnedPosition <> NewValueReturnedPosition Then
			LineProducts_.ReturnedPosition = NewValueReturnedPosition;
		EndIf;
	EndDo;
	
EndProcedure

#Region CancellationOfPaymentByPaymentCards

&AtClient
Procedure AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters)
	
	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("DocumentBasis", Object.Ref);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	
	If ThisIsFullReturnOnSalesShift 
		And CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards > 0 Then
		AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	Else
		AdditionalParameters.Insert("TransactionType",     "AuthorizeRefund");
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentsByPaymentCards(Result, AdditionalParameters) Export
	
	PaymentInformation = PaymentInformation(ThisObject);

	FormParameters = New Structure;
	FormParameters.Insert("AddressInStorage", CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards);
	
	FormParameters.Insert("ShowCancelPaymentsButtonSequentially", True);
	If DocumentAmount < TotalAmountOfPaymentByCreditCards Then
		FormParameters.Insert("ShowCancelPaymentButton", False);
		FormParameters.Insert("ShowCancelPaymentsButtonSequentially", False);
		FormParameters.Insert("ReadOnly", True);
	EndIf;
	FormParameters.Insert("ShowPaymentCanceledColumn", True);
	FormParameters.Insert("ThisIsReturn", True);
	FormParameters.Insert("ThisIsFullReturnOnSalesShift", ThisIsFullReturnOnSalesShift);
	
	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	FormParameters.Insert("DocumentAmount", AmountOfSurchargeIsEstimated);
	
	If AdditionalParameters.Property("ReceivedInCash") Then
		Object.IssueInCash = AdditionalParameters.ReceivedInCash;
	EndIf;
	
	OwnerForm = ThisObject;
	If AdditionalParameters.Property("Form") Then
		OwnerForm = AdditionalParameters.Form;
	EndIf;
	
	AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.TabularFormPaymentWithPaymentCards",
		FormParameters,OwnerForm,,,,
		New CallbackDescription("AddCardPaymentCancellationCompletion", ThisObject, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
//  Result - Structure -
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef
// 		* CurrentData - Structure -
//
&AtClient
Procedure CancelPaymentsByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
	AdditionalParameters.Insert("ResultOfCancellationOfPaymentByPaymentCards", Result);
	NotificationAfterRecording = New CallbackDescription("CancelPaymentByPaymentCardsEndAfterRecording", ThisObject, AdditionalParameters);
	
	If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then		
		FormParameters = New Structure;
		FormParameters.Insert("Data", AdditionalParameters.Form.Object.Ref);
		FormParameters.Insert("DataForEventLog", AdditionalParameters.Form.DataForEventLog);
		FormParameters.Insert("MessageText",
			NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
			|Chưa ghi nhận việc hủy thanh toán trong hệ thống.';
			|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
			|Отмена оплаты не зафиксирована в системе.';
			|en = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.'; fa = 'WARNING! An exception is thrown.
			|Payment cancellation was not recorded in the application.';
			|it = 'ATTENZIONE! Si è verificata una situazione eccezionale:
			| l''annullamento del pagamento non è stato registrato nel sistema.';
			|pl = 'UWAGA! Wystąpiła sytuacja wyjątkowa:
			|Anulowanie płatności nie zostało zarejestrowane w systemie.';
			|tr = 'UYARI! İstisnai bir durum meydana geldi:
			| Ödeme iptali sisteme kaydedilemedi.'"));
		
		OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, AdditionalParameters.Form);
	ElsIf Not Result.OperationPerformedOnDevice And Result.Property("CardPaymentCancellationData") Then
		If Result.CardPaymentCancellationData.Property("PaymentLine_") Then
			Object.PaymentWithPaymentCards.Delete(Result.CardPaymentCancellationData.PaymentLine_);
		ElsIf Result.CardPaymentCancellationData.Property("CurrentData") Then
			Object.PaymentWithPaymentCards.Delete(Result.CardPaymentCancellationData.CurrentData.LineNumber-1);
		EndIf;
		If Result.Property("TerminalUsedCorrespondsToSettings")
			And Not Result.TerminalUsedCorrespondsToSettings Then
			MessageTemplate = NStr("vi = 'Thiết bị thanh toán qua thẻ hiện tại (%1) đã bị ngắt kết nối hoặc đã được thay đổi.
			|Nếu đã thay đổi các cài đặt thiết, thì để áp dụng chúng, cần đóng quầy thu ngân và mở lại nó.';
			|ru = 'Текущий эквайринговый терминал (%1) отключен или изменен.
			|Если настройки оборудования изменены, то для их применения следует закрыть РМК и открыть заново.';
			|en = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.'; fa = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|it = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|pl = 'The current POS terminal (%1) is disabled or changed.
			|If the peripherals settings are changed, close the point of sale workplace and reopen it to apply them.';
			|tr = 'PoS terminali (%1) kapatılmış veya değiştirilmiştir.
			|Ekipman ayarları değiştirilmişse, değişiklikleri uygulamak için KİY''yi kapatın ve yeniden açın.'");
			MessageText = StrTemplate(MessageTemplate, AdditionalParameters.CurrentData.POSTerminal);

			FormParameters = New Structure;
			FormParameters.Insert("Data", Object.Ref);
			FormParameters.Insert("DataForEventLog", AdditionalParameters.Form.DataForEventLog);
			FormParameters.Insert("MessageText", MessageText);
			OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, AdditionalParameters.Form);
			Return;
		EndIf;
		PerformActionAfterRecording(NotificationAfterRecording, NStr("vi = 'Trước khi mở hình thức trả lại thanh toán, không thể ghi chứng từ.';
																	|ru = 'Перед открытием формы возврата оплаты не удалось записать документ.';
																	|en = 'Cannot save the document before opening the refund form.'; fa = 'Cannot save the document before opening the refund form.';
																	|it = 'Перед открытием формы возврата оплаты не удалось записать документ.';
																	|pl = 'Cannot save the document before opening the refund form.';
																	|tr = 'Geri iade formu açılmadan önce belge kaydedilemedi.'"));
	Else
		RunCallback(NotificationAfterRecording, True);	
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentByPaymentCardsEndAfterRecording(Result, AdditionalParameters) Export

	If Result Then
		If ValueIsFilled(Object.CashRegisterReceipt)
			And ValueIsFilled(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards)
			And CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards Then
			If AdditionalParameters.Property("ResultOfCancellationOfPaymentByPaymentCards")
				And AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.OperationPerformedOnDevice
				And AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.Property("CardPaymentCancellationData") Then
				
				IdOfPaymentLine = AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.CardPaymentCancellationData.PaymentLine_.GetID();
				LineNumberOfPaymentCardBeingCancelled = CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard[IdOfPaymentLine];
				AmountOfCancelledPayment = AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards.CardPaymentCancellationData.PaymentLine_.Sum;
				
				ResultOfRecalculation = RetailSalesServerCall.RecalculateDataOfNonCanceledPaymentsByPaymentCards(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards, LineNumberOfPaymentCardBeingCancelled, AmountOfCancelledPayment);				
				CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards = ResultOfRecalculation.DataOfFirstNonCancelledPaymentByPaymentCards;
				CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = ResultOfRecalculation.NumberOfOutstandingPaymentsByPaymentCards;
				CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards = ResultOfRecalculation.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards;
				CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard = ResultOfRecalculation.LowestAmountOfNonCancelledPaymentByPaymentCard;
				CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Delete(IdOfPaymentLine);
				
			EndIf;
		EndIf;
		
		If AdditionalParameters.Property("Action") And AdditionalParameters.Action = "CancelPaymentsSequentially"
				And AdditionalParameters.Property("PaymentLinesWithPaymentCards") And AdditionalParameters.PaymentLinesWithPaymentCards.Count() Then
			RunCallback(New CallbackDescription("CancelPaymentByCreditCardsSequentially", RetailSalesClient, AdditionalParameters)
										, AdditionalParameters.ResultOfCancellationOfPaymentByPaymentCards);
		Else
			NotificationToMixedPaymentForm	= Undefined;
			NotificationParameters = AdditionalParameters;
			While ValueIsFilled(NotificationParameters) Do
				If NotificationParameters.Property("NotificationToPaymentForm", NotificationToMixedPaymentForm) Then
					Break;
				ElsIf NotificationParameters.Property("NotificationOnCompletion") Then
					NotificationParametersNotificationAtEnd = NotificationParameters.NotificationOnCompletion; // CallbackDescription
					NotificationParameters = NotificationParametersNotificationAtEnd.AdditionalParameters;
				Else
					NotificationParameters = Undefined;
				EndIf;
			EndDo;
			If NotificationToMixedPaymentForm = Undefined Then
				MixedPayment(Undefined);
			Else
				RunCallback(NotificationToMixedPaymentForm, PaymentInformation(ThisObject));
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCard(Result, AdditionalParameters) Export
	
	PerformActionAfterRecording(
		New CallbackDescription("CancelCardPayment", RetailSalesClient, AdditionalParameters),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCardCompletion(Result, AdditionalParameters) Export
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  AdditionalParameters.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", AdditionalParameters.ReferenceNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    AdditionalParameters.ReceiptNumber);
	
	PaymentLine_ = Object.PaymentWithPaymentCards.Get(Object.PaymentWithPaymentCards.IndexOf(AdditionalParameters.PaymentLine_));
	PaymentLine_.PaymentIsCanceled = True;

	// Additional filling of operation acquisition data in case of a refund of an arbitrary amount
	If AdditionalParameters.Property("AnyAmountReturnedToPaymentCard") And AdditionalParameters.AnyAmountReturnedToPaymentCard = True Then
		PaymentLine_.PaymentCardNumber = AdditionalParameters.CardNumber;
		PaymentLine_.ReferenceNumber		 = AdditionalParameters.ReferenceNumber;
		PaymentLine_.POSTerminalReceiptNumber		 = AdditionalParameters.ReceiptNumber;
		PaymentLine_.AuthorizationCode		 = AdditionalParameters.AuthorizationCode;
	EndIf;

	Modified = True;
		
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParametersRepeatRecording = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersRepeatRecording.CallbackDescription = AdditionalParameters.NotificationOnCompletion;
		AdditionalParametersRepeatRecording.MessageText                 = NStr("vi = 'Sau khi hoàn thành thao tác thanh toán hủy, Chứng từ không thể được ghi.';
																				|ru = 'После выполнения операции отмены оплаты не удалось записать документ.';
																				|en = 'Cannot save the document after payment cancellation transaction has been executed.'; fa = 'Cannot save the document after payment cancellation transaction has been executed.';
																				|it = 'Dopo aver annullato il pagamento non è stato possibile registrare il documento.';
																				|pl = 'Po wykonaniu operacji odwołania płatności nie udało się zapisać dokumentu.';
																				|tr = 'Bir ödeme iptal işlemi gerçekleştirildikten sonra belge kaydedilemedi.'");
		AdditionalParametersRepeatRecording.ReturnFunctionResult     = False;
		AdditionalParametersRepeatRecording.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData", True, True, AdditionalParameters);
		AdditionalParametersRepeatRecording.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData", True, False, AdditionalParameters);
		AdditionalParametersRepeatRecording.ProcedureName                   = "WriteAtServer";
		AdditionalParametersRepeatRecording.OperationResult              = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersRepeatRecording);
			Return;
		EndIf;
	
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersRepeatRecording),
			AdditionalParametersRepeatRecording.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(
			AdditionalParameters.NotificationOnCompletion,
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded, CardPaymentCancellationData",
				True, True, AdditionalParameters));
		
	EndIf;
	
EndProcedure

// Called from the complex payment form
&AtClient
Procedure PaymentCancel(Result, AdditionalParameters) Export
	
	RunCallback(
		New CallbackDescription("AddCardPaymentCancellation", ThisObject, AdditionalParameters));
	
EndProcedure

// Called from the complex payment form
&AtClient
Procedure CancelPaymentReverse(Result, AdditionalParameters) Export
	
	// Delete the lines added for canceling payments with payment cards
	TheStructureOfTheSearch = New Structure("PaymentKind_", PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard"));
	FoundRows = Object.PaymentWithPaymentCards.FindRows(TheStructureOfTheSearch);
	NeedToWrite = False;
	If FoundRows.Count() Then
		NeedToWrite = True;
		For Each FoundRow In FoundRows Do
			Object.PaymentWithPaymentCards.Delete(FoundRow);	
		EndDo;
		FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt();
	EndIf;

	// We'll click in the lines to indicate that the payment was canceled.
	TheStructureOfTheSearch = New Structure("PaymentIsCanceled", True);
	FoundRows = Object.PaymentWithPaymentCards.FindRows(TheStructureOfTheSearch);
	If FoundRows.Count() Then
		NeedToWrite = True;
		For Each FoundRow In FoundRows Do
			FoundRow.PaymentIsCanceled = False;
		EndDo;
	EndIf;
	
	NotificationOnCompletion = New CallbackDescription("PaymentCancelCompletion", ThisObject, AdditionalParameters);
	If NeedToWrite Then
		Modified = True;
		PerformActionAfterRecording(NotificationOnCompletion
									, NStr("vi = 'Trước khi đóng hình thức trả lại thanh toán, không thể ghi chứng từ.';
											|ru = 'После закрытия формы возврата оплаты не удалось записать документ.';
											|en = 'Cannot save the document after closing the refund form.'; fa = 'Cannot save the document after closing the refund form.';
											|it = 'После закрытия формы возврата оплаты не удалось записать документ.';
											|pl = 'Cannot save the document after closing the refund form.';
											|tr = 'Geri iade formu kapandıktan sonra belge kaydedilemedi.'"));
	Else
		RunCallback(NotificationOnCompletion);
	EndIf;
		
EndProcedure

&AtClient
Procedure AddCardPaymentCancellation(Result, CompletionParameters) Export
		
	CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Clear();
	If Result = False Then
		RetailSalesClient.UnblockForm(ThisObject);
		MessageText = NStr("vi = 'Trước khi thêm dữ liệu để hủy bỏ thao tác thanh toán bằng thẻ, không thể ghi lại chứng từ.';
							|ru = 'Перед добавлением данных для отмены операции оплаты картой не удалось записать документ.';
							|en = 'Cannot save the document before adding data to cancel the payment by card.'; fa = 'Cannot save the document before adding data to cancel the payment by card.';
							|it = 'Перед добавлением данных для отмены операции оплаты картой не удалось записать документ.';
							|pl = 'Cannot save the document before adding data to cancel the payment by card.';
							|tr = 'Kart ödemesi işlemini iptal etmek için veri eklenmeden önce belge kaydedilemedi.'");
		RetailSalesServerCall.LogEntry(
		MessageText, "CashRegisterReceiptReturns.CWPDocumentForm.AddCardPaymentCancellation", Object.Ref);
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	PaymentInformation = PaymentInformation(ThisObject);
	AmountOfSurchargeIsEstimated = Max(PaymentInformation.DocumentAmount - PaymentInformation.TotalPaid_, 0);
	
	ResultForContinuation = Undefined;
	
	AdditionalParameters = CompletionParameters;
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("AnyAmountReturnedToPaymentCard", False);
	If CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards <= 1 
		Or CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard > AmountOfSurchargeIsEstimated Then

		If CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = 1
			And CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards <> Undefined
			And CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.Sum <= AmountOfSurchargeIsEstimated Then
			// If there is one undone card payment and the amount on it is less than or equal to the return amount according to the document
			
			SequentialCancellation = False;
			ResultForContinuation = New Structure;
			
			CardPaymentLine = Object.PaymentWithPaymentCards.Add();
			CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
			CardPaymentLine.POSTerminal = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.POSTerminal;
			CardPaymentLine.PaymentCardNumber	 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.PaymentCardNumber;
			CardPaymentLine.Sum				 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.Sum;
			CardPaymentLine.ReferenceNumber		 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.ReferenceNumber;
			CardPaymentLine.POSTerminalReceiptNumber			 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.POSTerminalReceiptNumber;
			CardPaymentLine.AuthorizationCode		 = CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.AuthorizationCode;
			
			ResultForContinuation.Insert("Action", "PaymentCancel");
			ResultForContinuation.Insert("RowSelected", CardPaymentLine);

			CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Insert(CardPaymentLine.GetID(), CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards.LineNumber);
			
			AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
			ContinueNotification = New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters);
			
		Else
			// if the return amount according to the document exceeds the smallest amount of the non-cancelled card payment
			// or if there is not a single non-cancelled card payment
			CallbackOnCompletion = New CallbackDescription("AddCardPaymentCancellationCompletion", ThisObject, CompletionParameters);
			If ValueIsFilled(CompletionParameters) Then 
				If CompletionParameters.Property("CallbackOnCompletion") Then
					CallbackOnCompletion = CompletionParameters.CallbackOnCompletion;
				EndIf;
			EndIf;
			AdditionalParameters.Insert("CallbackOnCompletion", CallbackOnCompletion);
			
			AdditionalParameters.Insert("Form",                  ThisObject);
			AdditionalParameters.Insert("POSTerminals", POSTerminals);
			AdditionalParameters.Insert("CashRegisterParameters",      CashRegisterParameters);
			AdditionalParameters.Insert("Currency",                       Object.Currency);
			AdditionalParameters.Insert("StructureAcquiringTerminal");
			AdditionalParameters.Insert("IDOfETDevice");
			AdditionalParameters.Insert("JustFillInResultOfCardPayment", True);

			IndicatedAmountDueInCash = 0;
			If AdditionalParameters.Property("ReceivedInCash") Then
				IndicatedAmountDueInCash = AdditionalParameters.ReceivedInCash;
			EndIf;
			
			AdditionalParameters.Insert("AuthorizationForm_Amount",       PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_ - IndicatedAmountDueInCash);
			AdditionalParameters.Insert("AuthorizationForm_AmountLimit", PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_);
			
			ContinueNotification = New CallbackDescription("AddCardPayment", RetailSalesClient, AdditionalParameters);
			ResultForContinuation = True;
		EndIf;
	Else
		ContinueNotification = New CallbackDescription("CancelPaymentsByPaymentCards", ThisObject, AdditionalParameters);
	EndIf;
	
	RunCallback(ContinueNotification, ResultForContinuation);		
	
EndProcedure

&AtClient
Procedure AddCardPaymentCancellationCompletion(Result, AdditionalParameters) Export

	CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Clear();
	
	If Not ValueIsFilled(Result) Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;

	If Not ValueIsFilled(AdditionalParameters) Then
		AdditionalParameters = New Structure;
	EndIf;
	AdditionalParameters.Insert("AnyAmountReturnedToPaymentCard", False);
	
	SequentialCancellation = False;
	SelectionResult = New Structure;
	ArrayOfRowsOfCanceledPaymentsByPaymentCards = New Array;
	
	// Adding the lines for canceling the payment to the table part
	If Not Result.Property("Action") Then
		// Cancellation of payment from the CWP form or from the mixed payment form, 
		// The structure of the result of cancellation of payment by card differs from the Attributes of the tabular part.
		// Add a row to the table part
		CardPaymentLine = Object.PaymentWithPaymentCards.Add();
		CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
		CardPaymentLine.POSTerminal = Result.POSTerminal;
		CardPaymentLine.PaymentCardNumber	 = Result.CardNumber;
		CardPaymentLine.Sum				 = Result.TransactionAmount;
		CardPaymentLine.ReferenceNumber		 = Result.ReferenceNumber;
		CardPaymentLine.POSTerminalReceiptNumber			 = Result.ReceiptNumber;
		CardPaymentLine.AuthorizationCode		 = Result.AuthorizationCode;
		ArrayOfRowsOfCanceledPaymentsByPaymentCards.Add(CardPaymentLine);
		
		AdditionalParameters.AnyAmountReturnedToPaymentCard = True;
		SelectionResult.Insert("Action", "PaymentCancel");
	Else
		// Cancellation of payment from the form of the tabular part Payment by payment cards
		SelectedPaymentCancellationLinesToAdd = New Array;	
		SelectionResult.Insert("Action", Result.Action);
		If Result.Action = "PaymentCancel" Then
			// Save card payment data in the table
			SelectedPaymentCancellationLinesToAdd.Add(Result.RowSelected);
		ElsIf Result.Action = "CancelPaymentsSequentially" Then
			SequentialCancellation = True;
			SelectedPaymentCancellationLinesToAdd = Result.RowsSelected;
		EndIf;
		
		// Add rows to the table part
		If SelectedPaymentCancellationLinesToAdd.Count() Then
			For Each LineToCancel In SelectedPaymentCancellationLinesToAdd Do
				CardPaymentLine = Object.PaymentWithPaymentCards.Add();
				CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
				CardPaymentLine.POSTerminal = LineToCancel.POSTerminal;
				CardPaymentLine.PaymentCardNumber	 = LineToCancel.PaymentCardNumber;
				CardPaymentLine.Sum				 = LineToCancel.Sum;
				CardPaymentLine.ReferenceNumber		 = LineToCancel.ReferenceNumber;
				CardPaymentLine.POSTerminalReceiptNumber			 = LineToCancel.POSTerminalReceiptNumber;
				CardPaymentLine.AuthorizationCode		 = LineToCancel.AuthorizationCode;
				ArrayOfRowsOfCanceledPaymentsByPaymentCards.Add(CardPaymentLine);
				
       			CashRegisterReceiptDetails.LineNumbersOfCancelledPaymentsByPaymentCard.Insert(CardPaymentLine.GetID(), LineToCancel.LineNumber);
			EndDo;
		Else
			RetailSalesClient.UnblockForm(ThisObject);
			Return;
		EndIf;
	EndIf;
	
	If SequentialCancellation Then
		SelectionResult.Insert("RowSelected", ArrayOfRowsOfCanceledPaymentsByPaymentCards);
	Else
		SelectionResult.Insert("RowSelected", ArrayOfRowsOfCanceledPaymentsByPaymentCards[0]);
	EndIf;
	
	AddPaymentCancellationParametersWithPaymentCards(AdditionalParameters);
	
	CallbackDescription = New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters);
	RunCallback(CallbackDescription, SelectionResult);
	
EndProcedure

&AtClient
Procedure PaymentCancelCompletion(Result, AdditionalParameters) Export
	
	RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation(ThisObject));
	
EndProcedure

#EndRegion

&AtClient
Procedure RecalculateDocumentOnClient()
	
	Items.Goods.ChangeRowSet    = AccessRights.LineAdjustment;
	
	Items.ContextMenuShoppingCartAreaProductsAdd.Enabled    = Not ValueIsFilled(Object.CashRegisterReceipt) And AccessRights.LineAdjustment;
	Items.ContextMenuShoppingCartAreaProductsCopy.Enabled = Not ValueIsFilled(Object.CashRegisterReceipt) And AccessRights.LineAdjustment;

	Items.GoodsNumberOfPackages.ReadOnly = Not AccessRights.LineAdjustment;
	Items.GoodsPrice.ReadOnly = Not AccessRights.LineAdjustment
									Or ValueIsFilled(Object.CashRegisterReceipt)
									Or Not AccessRights.AllowPriceChangesWhenReturningWithoutReceipt;
	
	OnlyViewingGoodsTableFields = (Not AccessRights.LineAdjustment Or ValueIsFilled(Object.CashRegisterReceipt));
	Items.GoodsProducts.ReadOnly       = OnlyViewingGoodsTableFields;
	Items.GoodsBarcode.ReadOnly           = OnlyViewingGoodsTableFields;
	Items.GoodsCharacteristic.ReadOnly     = OnlyViewingGoodsTableFields;
	Items.GoodsSeller.ReadOnly           = OnlyViewingGoodsTableFields;
	Items.GoodsPremise.ReadOnly          = OnlyViewingGoodsTableFields;
	
	FormEventsClient.WhenChangingElement(ThisObject, "AccessRights");
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	UpdateDashboardData(ThisObject, True = ReadOnly);

	UpdateFormButtonHeaders();
	
	EstablishAvailabilityOfCWPElements(ThisObject, RetailSalesClientServer.AvailablePaymentMethods(ThisObject));
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateDashboardData(Form, DisplayChange = False)
	
	PaymentInformation = PaymentInformation(Form);
	
	ThisIsFullReturnToSalesShiftOfOldValue = Form.ThisIsFullReturnOnSalesShift; 
	Form.ThisIsFullReturnOnSalesShift = (ValueIsFilled(Form.Object.CashRegisterReceipt) 
										And Form.DocumentAmount = Form.CashRegisterReceiptDetails.DocumentAmount
										And Form.Object.CashRegisterShift = Form.CashRegisterReceiptDetails.CashRegisterShift);
										
	If Form.ButtonHeadersAreConfigured Then
		Form.ButtonHeadersAreConfigured = (ThisIsFullReturnToSalesShiftOfOldValue = Form.ThisIsFullReturnOnSalesShift);
	EndIf;

	Form.RefundAmountInformationPanel                  = PaymentInformation.AmountToPay;

	Form.InformationPanelAmountToBeRefundedByPaymentCards = 0;   
	AmountByTypeOfPaymentPaymentCard = ?(Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_"),
											PaymentInformation.PaymentCardsCanceled, PaymentInformation.PaymentCards);
	If AmountByTypeOfPaymentPaymentCard = 0 Then
		Form.InformationPanelAmountToBeRefundedInCash         = PaymentInformation.AmountToPay;
	Else
		Form.InformationPanelAmountToBeRefundedInCash         = PaymentInformation.AmountToPay - AmountByTypeOfPaymentPaymentCard;
		Form.InformationPanelAmountToBeRefundedByPaymentCards = AmountByTypeOfPaymentPaymentCard;
	EndIf;
	InfoBarLocalization(Form, PaymentInformation);
	
	NumberOfWHLines = Form.Object.Goods.Count();
	
	CurrentRow = Form.Items.Goods.CurrentRow;
	If CurrentRow = Undefined And NumberOfWHLines > 0 Then
		CurrentData = Form.Object.Goods[NumberOfWHLines - 1];
		Form.Items.Goods.CurrentRow = CurrentData.GetID();
	ElsIf CurrentRow = Undefined And NumberOfWHLines = 0 Then
		CurrentData = Undefined;
	Else
		CurrentData = Form.Object.Goods.FindByID(CurrentRow);
	EndIf;
	
	ProductName = "";
	If CurrentData <> Undefined Then
		ProductName = ProductsClientServer.ProductPresentation(
			CurrentData.Products,
			CurrentData.Characteristic,
			,
			CurrentData.Series);
	EndIf;
	
	RequiredDetails_ = New Array;
	RowData = New Structure;
	SellerOnlyCashier = Form.CashierCanBeASeller And Not Form.SellingAreaManagerMayActAsASeller;
	If Not SellerOnlyCashier And CurrentData <> Undefined Then
		NameOfDashboardDetails = "Seller";
		RequiredDetails_.Add(NameOfDashboardDetails);
		RowData.Insert(NameOfDashboardDetails, CurrentData.Seller);
	EndIf;
	If Form.CashRegisterParameters.UseWarerooms And CurrentData <> Undefined Then
		NameOfDashboardDetails = "Premise";
		RequiredDetails_.Add(NameOfDashboardDetails);
		RowData.Insert(NameOfDashboardDetails, CurrentData.Premise);
	EndIf;
	If Form.UseLoyaltyCards And CurrentData <> Undefined Then
		NameOfDashboardDetails = "Map";
		RowData.Insert(NameOfDashboardDetails, Form.Object.LoyaltyCard);
	EndIf;
	
	SummaryParameters = New Structure;
	SummaryParameters.Insert("Count",                0);
	SummaryParameters.Insert("Price",                      0);
	SummaryParameters.Insert("ManualDiscount",         0);
	SummaryParameters.Insert("DiscountMarkupAmount", 0);
	SummaryParameters.Insert("Sum",                     0);
	If CurrentData <> Undefined Then
		FillPropertyValues(SummaryParameters, CurrentData);
	EndIf;
	
	Data = New Structure;
	Data.Insert("ProductName",    ProductName);
	Data.Insert("RowData",          RowData);
	Data.Insert("SummaryParameters",     SummaryParameters);
	Data.Insert("RequiredDetails_", RequiredDetails_);
	
	If DisplayChange Then
		
		TextDelivery = New FormattedString(
			StrTemplate(NStr("vi = 'Nhận trả lại: %1';
							|ru = 'Получить сдачу: %1';
							|en = 'Receive change: %1'; fa = 'Receive change: %1';
							|it = 'Ricevere resto: %1';
							|pl = 'Otrzymać resztę: %1';
							|tr = 'Para üstünü al: %1'"),
				Format(PaymentInformation.TotalPaid_ - PaymentInformation.AmountToPay, "NFD=2; NZ=0.00")));
		
		Data.Insert("DisplayChange", True);
		Data.Insert("TextDelivery",      TextDelivery);
		
	Else
		Data.Insert("DisplayChange", False);
	EndIf;
	
	RetailSalesClientServer.UpdateDashboardData(Form, Data);
	
EndProcedure

&AtServer
Procedure ConfigureRightsForUser(User)
	
	AccessRights = SalesSettingsForUsersServer.CWPAccessRights(User);
	
	Object.Cashier = User;
	DetailsOfTheCashier = RetailSales.DetailsOfTheCashier(User, Object.Organization);
	
	If CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller Then
		CurrentSeller = User;
		For Each TSRow In Object.Goods Do
			TSRow.Seller = User;
		EndDo;
	EndIf;
	
	RefreshFormTitle();
	
EndProcedure

&AtServer
Procedure RefreshFormTitle()
	
	Title = NStr("vi = 'Trả lại (Thu ngân: %Cashier%, Người bán: %Seller%)';
				|ru = 'Возврат (Кассир: %Cashier%, Продавец: %Seller%)';
				|en = 'Return (Cashier: %Cashier%, Sales associate: %Seller%)'; fa = 'Return (Cashier: %Cashier%, Sales associate: %Seller%)';
				|it = 'Возврат (Кассир: %Cashier%, Продавец: %Seller%)';
				|pl = 'Return (Cashier: %Cashier%, Sales associate: %Seller%)';
				|tr = 'İade (Kasiyer: %Cashier%, Satıcı: %Seller%)'");
	Title = StrReplace(Title, "%Cashier%", Object.Cashier);
	Title = StrReplace(Title, "%Seller%", ?(ValueIsFilled(CurrentSeller),CurrentSeller, NStr("vi = '<Chưa chọn>';
																							|ru = '<Не выбран>';
																							|en = '<Not selected>'; fa = '<Not selected>';
																							|it = '<non è selezionato>';
																							|pl = '<Nie wybrany>';
																							|tr = '<seçilmedi>'")));
	
EndProcedure

&AtClient 
Procedure UpdateFormButtonHeaders()
	
	If ButtonHeadersAreConfigured Then
		Return;
	EndIf;
	
	UpdateFormButtonHeadersOnServer();
	
EndProcedure

&AtServer
Procedure UpdateFormButtonHeadersOnServer(SignHotkeysOnButtons = True)
	
	Command = Commands.PayByPaymentCard;
	ShortcutPresentation = TMCommonUse.KeyboardShortcutPresentation(Command.Shortcut);
	TitleLines = New Array;
	TitleLines.Add(NStr("vi = 'Quay lại';
						|ru = 'Вернуть';
						|en = 'Return'; fa = 'مرجوعی';
						|it = 'Вернуть';
						|pl = 'Return';
						|tr = 'Karta iade'"));
	TitleLines.Add(NStr("vi = 'thanh toán đến thẻ';
						|ru = 'оплату на карту';
						|en = 'payment to card'; fa = 'payment to card';
						|it = 'оплату на карту';
						|pl = 'payment to card';
						|tr = 'edilecek ödeme'"));
	ToolTipText = NStr("vi = 'Trả lại thanh toán vào thẻ thanh toán';
						|ru = 'Вернуть оплату на платежную карту';
						|en = 'Return the payment to the payment card'; fa = 'برگشت پرداخت به کارت پرداخت';
						|it = 'Annullare il pagamento con le carte di pagamento';
						|pl = 'Return the payment to the payment card';
						|tr = 'Ücreti ödeme kartına iade et'");
	If ThisIsFullReturnOnSalesShift And TotalAmountOfPaymentByCreditCards <> 0 Then
		TitleLines.Clear();
		TitleLines.Add(NStr("vi = 'Hủy bỏ';
							|ru = 'Отменить';
							|en = 'Cancel'; fa = 'انصراف';
							|it = 'Отменить';
							|pl = 'Cancel';
							|tr = 'İptal edilecek'"));
		TitleLines.Add(NStr("vi = 'thanh toán bằng thẻ';
							|ru = 'оплату картами';
							|en = 'payment by cards'; fa = 'payment by cards';
							|it = 'оплату картами';
							|pl = 'payment by cards';
							|tr = 'kart ödemesi'"));
		ToolTipText = NStr("vi = 'Hủy thanh toán bằng thẻ';
							|ru = 'Отменить оплату платежными картами';
							|en = 'Void payment by cards'; fa = 'ابطال پرداخت با کارت‌ها';
							|it = 'Annullare il pagamento con le carte di pagamento';
							|pl = 'Anuluj płatność kartami płatniczymi';
							|tr = 'Ödeme kartıyla ödemeyi iptal et'");
	EndIf;
	
	Command.ToolTip                 = ToolTipText;
	Command.Title                 = StrConcat(TitleLines, Chars.LF);
	
	If SignHotkeysOnButtons Then
		RetailSales.SignHotkeyOnButton(Command);
	EndIf;
		
	ButtonHeadersAreConfigured = True;
	
EndProcedure

&AtServer
Procedure WhenCreatingReceipt()

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	If UsePriceManagementSystem25 Then
		ObjectForStoringSalesTermsAndConditions = ProductRangeServerCached.StoreFormatByWarehouse(Object.Warehouse, Object.Date);
	Else
		ObjectForStoringSalesTermsAndConditions = Object.Warehouse;
	EndIf;

	If Not ValueIsFilled(Object.Ref) Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters); 
		
		SetVisibilityOfSeriesElements();
		
	EndIf;

	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
	FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	RefreshFormTitle();
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	ConfigureCWP();
	
EndProcedure

&AtServer 
Procedure GetStatusOfSBPPaymentByReceiptKMM()
	
	StatusOfSBPPaymentOfSalesReceipt = Enums.TypesOfSBPPaymentStatuses.EmptyRef();
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED
		|	CashRegisterReceiptPaymentWithPaymentCards.SBPPaymentStatus AS SBPPaymentStatus
		|FROM
		|	Document.CashRegisterReceipt.PaymentWithPaymentCards AS CashRegisterReceiptPaymentWithPaymentCards
		|WHERE
		|	CashRegisterReceiptPaymentWithPaymentCards.Ref = &Ref
		|	AND CashRegisterReceiptPaymentWithPaymentCards.PaymentKind_ = &PaymentKind_";
		
		Query.SetParameter("Ref", Object.CashRegisterReceipt);
		Query.SetParameter("PaymentKind_", Enums.TypesOfCashRegisterPaymentSystem.InstantPayments);
		
		SBPPaymentTable = Query.Execute().Select();
		If  SBPPaymentTable.Next() Then
			StatusOfSBPPaymentOfSalesReceipt = SBPPaymentTable.SBPPaymentStatus;
		EndIf; 
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformActionAfterRecording(NotificationOnCompletion, MessageText)
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParameters = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParameters.CallbackDescription         = NotificationOnCompletion;
		AdditionalParameters.MessageText             = MessageText;
		AdditionalParameters.ReturnFunctionResult = True;
		AdditionalParameters.ProcedureName               = "WriteAtServer";
		AdditionalParameters.OperationResult          = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParameters);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParameters),
			AdditionalParameters.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(NotificationOnCompletion, True);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PayInCashHandlingAlerts(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CallbackOnCompletion", New CallbackDescription("OpenCashPaymentForm", ThisObject));
	CallbackOnCompletion = New CallbackDescription("StartPerformingAdditionalActionsBeforeReturningPaymentEnd", ThisObject, NotificationParameters);
	
	StartPerformingAdditionalActionsBeforeReturningLocalizationPayment(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure OpenCashPaymentForm(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.PaymentMethodByCash",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject));
	
EndProcedure

&AtClient
Procedure CancelPaymentByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
	ProcessPaymentAddition(AdditionalParameters);

EndProcedure

&AtClient
Procedure CancelPaymentUsingPaymentCardsProcessingNotifications(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	AdditionalParameters = New Structure;
	
	UpdateTheStateOfRegisterShift();
	
	NotificationParameters = New Structure;
	// Calling the FormaAuthorizatiON of this connected equipment
	NotificationParameters.Insert("CallbackOnCompletion", New CallbackDescription("AddCardPaymentCancellation", ThisObject));
	CallbackOnCompletion = New CallbackDescription("StartPerformingAdditionalActionsBeforeReturningPaymentEnd", ThisObject, NotificationParameters);
	
	StartPerformingAdditionalActionsBeforeReturningLocalizationPayment(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure MixedPaymentNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	NotificationParameters = New Structure;
	NotificationParameters.Insert("CallbackOnCompletion", New CallbackDescription("OpenMixedPaymentForm", ThisObject));
	CallbackOnCompletion = New CallbackDescription("StartPerformingAdditionalActionsBeforeReturningPaymentEnd", ThisObject, NotificationParameters);
	
	StartPerformingAdditionalActionsBeforeReturningLocalizationPayment(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure OpenMixedPaymentForm(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	FormOpenParameters.Insert("ThisIsFullReturnOnSalesShift", ThisIsFullReturnOnSalesShift);
	FormOpenParameters.Insert("StatusOfSBPPaymentOfSalesReceipt", StatusOfSBPPaymentOfSalesReceipt);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.MixedPaymentForm",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject));
	
EndProcedure

&AtClient
Procedure CompletionOfPayment(PaymentResult, AdditionalParameters) Export

	If TypeOf(PaymentResult) = Type("Structure")
		And PaymentResult.Property("ReceivedInCash")
		And PaymentResult.Property("ElectronicReceiptData") Then
		
		Object.IssueInCash = PaymentResult.ReceivedInCash;
		Object.Partner         = PaymentResult.ElectronicReceiptData.Partner;
		
		FiscalOperationData.OptionOfSendingElectronicReceipt  = PaymentResult.ElectronicReceiptData.OptionOfSendingElectronicReceipt;
		FiscalOperationData.ContactDetailsOfElectronicReceipt = PaymentResult.ElectronicReceiptData.ContactDetailsOfElectronicReceipt;
		
	ElsIf PaymentResult = "Cancel" Then
		RetailSalesClient.UnblockForm(ThisObject);
		UnlockFormDataForEdit();
		RecalculateDocumentOnClient();
		Return;
		
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Exit") 
		And AdditionalParameters.Exit = True Then
		
		RetailSalesClient.UnblockForm(ThisObject);
		UnlockFormDataForEdit();
		Return;
	EndIf;
	
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ProcessPaymentAddition(AdditionalParameters)
	
	PaymentInformation = PaymentInformation(ThisObject);
	
	// The card payment command was called from the RMK form
	If AdditionalParameters = Undefined Then
		
		If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
			
			UpdateDashboardData(ThisObject, True);
			RetailSalesClient.UnblockForm(ThisObject);
			
		Else
			
			If PaymentInformation.TotalPaid_ >= PaymentInformation.AmountToPay
				And ValueIsFilled(FiscalOperationData.OptionOfSendingElectronicReceipt) Then
				
				UpdateDashboardData(ThisObject, True);
				
				IssueCashReceipt();
				
			ElsIf PaymentInformation.TotalPaid_ > 0 Then
				
				PerformActionAfterRecording(
					New CallbackDescription("OpenMixedPaymentForm", ThisObject),
					NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
						|ru = 'Перед открытием формы оплаты не удалось записать документ.';
						|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
						|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
						|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
						|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
				
				AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
				
			Else
				
				RetailSalesClient.UnblockForm(ThisObject);
				AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
				
			EndIf;
			
		EndIf;
		
	Else
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation);
	EndIf;
	
EndProcedure

&AtServer
Function GetFormCommands(Var_UUID)
	
	FormCommands = New Array;
	For Each FormCommand In Commands Do
		If Not FormCommand.Shortcut.Key = Key.None Then
			FormCommands.Add(New Structure("CommandName, Title, Shortcut", FormCommand.Name, FormCommand.Title, FormCommand.Shortcut));
		EndIf;
	EndDo;
	
	Return PutToTempStorage(FormCommands, Var_UUID);
	
EndFunction

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("FillOutSellerSForm",  New Structure("Seller", CurrentSeller));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
	StructureOfActions.Insert("RecalculateVATAmount",
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
		
	StructureOfActions.Insert("CheckSeriesCalculateStatus",	
		New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", ThisObject.FormName, "Goods"));
		
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	RowsToProcess = New Array;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		ListOfProperties = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Price, NumberOfPackages, Series";
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		If CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller
			And CurrentRow.Seller <> Object.Cashier Then
			CurrentRow.Seller = Object.Cashier;
		EndIf;
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	If CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	FillInServiceDetailsForProductRange();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	If TableOfGoods.Count() Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessPrintCommand(CommandName, AdditionalParameters) Export

	AttachableCommandsClient.ExecuteCommand(ThisObject, Commands[CommandName], Object);

EndProcedure

&AtClient
Procedure InformationPanelOtherParametersValueURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "SellerValueNotFilledIn"
		Or FormattedStringURL = "Seller" Then
		OpenForm(
			"Catalog.Users.ChoiceForm",
			New Structure("ChoiceMode", True),,,,,
			New CallbackDescription("ChangeSellerCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
	If FormattedStringURL = "RoomValueNotFilled"
		Or FormattedStringURL = "Premise" Then
		ChangeWareroom(Undefined);
	EndIf;
	
	If FormattedStringURL = "Map" Then
		ShowValue(,Object.LoyaltyCard);
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationPanelErrorWhenPrintingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ShowCompleteErrorWhenPrintingReceipt" Then
		ShowValue(Undefined, InformationPanelErrorWhenPrintingReceiptText);	
	EndIf;
EndProcedure

&AtClient
Procedure ChangeWareroomCompletion(Result, AdditionalParameters) Export
	
	TSRow = AdditionalParameters.TSRow;
	
	Premise = Result;
	If Not ValueIsFilled(Premise) Then
		Return;
	EndIf;
	
	OldRoomValue = TSRow.Premise;	
	TSRow.Premise = Premise;
	
	RetailSalesClient.UpdateRoomInRowsOfTabularPartOfSeries(ThisObject, TSRow, OldRoomValue);
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
EndProcedure

&AtClient
Procedure UploadNewReceipt(Ref)
	
	If Object.Status <> PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Ref", Ref);
		
		Cancel = False;
		BeforeClosingReceipt(
			Cancel,
			New CallbackDescription("UploadNewReceiptCompletion", ThisObject, AdditionalParameters));
		If Cancel Then
			Return;
		EndIf;
		
	Else
		
		NewReceiptOnServer(Ref);
		UploadNewReceiptFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadNewReceiptFragment()
	
	RecalculateDocumentOnClient();
	
EndProcedure

// Parameters:
//  Result - Boolean, Undefined - 
// 	AdditionalParameters - Structure:
// 		* Ref - DocumentRef
&AtClient
Procedure UploadNewReceiptCompletion(Result, AdditionalParameters) Export
	
	NewReceiptOnServer(AdditionalParameters.Ref);
	
	UploadNewReceiptFragment();
	
EndProcedure

&AtServer
Function PostponeOnServer(RetryRecordingIsRequired)
	
	PostponeCompleted = True;
	
	OldStatus = Object.Status;
	Object.Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	
	Try
		
		PostponeCompleted = WriteAtServer(RetryRecordingIsRequired);
		
		If Not PostponeCompleted Then
			Object.Status = OldStatus;
		EndIf;
		
	Except
		
		Object.Status = OldStatus;
		PostponeCompleted = False;
		
	EndTry;
	
	Return PostponeCompleted;
	
EndFunction

&AtClient
Procedure DeferOnClient(NotificationOnCompletion)
	
	Modified = True;
	
	RetryRecordingIsRequired = False;
	Result = PostponeOnServer(RetryRecordingIsRequired);
	
	If Not Result Then
		
		AdditionalParametersAttempt = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersAttempt.CallbackDescription         = NotificationOnCompletion;
		AdditionalParametersAttempt.MessageText             = NStr("vi = 'Không thể ghi chứng từ.';
																	|ru = 'Не удалось записать документ.';
																	|en = 'Cannot save the document.'; fa = 'Cannot save the document.';
																	|it = 'Non è stato possibile registrare il documento.';
																	|pl = 'Nie udało się zapisać dokumentu.';
																	|tr = 'Belge kaydedilemedi.'");
		AdditionalParametersAttempt.ReturnFunctionResult = True;
		AdditionalParametersAttempt.ProcedureName               = "PostponeOnServer";
		AdditionalParametersAttempt.OperationResult          = Result;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersAttempt);
			Return;
		EndIf;
		
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersAttempt),
			AdditionalParametersAttempt.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		RunCallback(NotificationOnCompletion, Result);
		
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(ThisObject.UUID, CashRegisterParameters.DeviceID);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingReceipt(Cancel, CallbackDescription = Undefined)
	
	Buttons = New ValueList;
	
	If Not ReadOnly And (Modified Or ValueIsFilled(Object.Ref)) Then
		
		If Modified And AccessRights.Snooze Then
			Buttons.Add(1, NStr("vi = 'Hoãn lại';
								|ru = 'Отложить';
								|en = 'Put on hold'; fa = 'نگه‌داشتن';
								|it = 'Rinvia';
								|pl = 'Put on hold';
								|tr = 'Ertele'"));
		EndIf;
		
		If AccessRights.LineAdjustment Then		
			If ValueIsFilled(Object.Ref) Then
				Buttons.Add(4, NStr("vi = 'Xóa bỏ phiếu';
									|ru = 'Удалить чек';
									|en = 'Remove receipt'; fa = 'Remove receipt';
									|it = 'Elimina scontrino';
									|pl = 'Usuń paragon';
									|tr = 'Makbuzu sil'"));
			EndIf;
			
			If Modified Then
				Buttons.Add(3, NStr("vi = 'Đóng không lưu';
									|ru = 'Закрыть без сохранения';
									|en = 'Close without saving'; fa = 'بستن بدون ذخیره';
									|it = 'Chiudi senza salvare';
									|pl = 'Zamknij bez zapisywania';
									|tr = 'Kaydetmeden kapat'"));
			Else
				Buttons.Add(3, NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Zamknij';
									|tr = 'Kapat'"));
			EndIf;
		EndIf;
		
		Buttons.Add(99, NStr("vi = 'Hủy bỏ';
							|ru = 'Отмена';
							|en = 'Cancel'; fa = 'انصراف';
							|it = 'Annulla';
							|pl = 'Anuluj';
							|tr = 'İptal'"));
		
	EndIf;
	
	If Buttons.Count() > 0 Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("QuestionBeforeClosingCheckEnds", ThisObject, AdditionalParameters),
			NStr("vi = 'Chọn một hành động trước khi đóng.';
				|ru = 'Выберите действие перед закрытием.';
				|en = 'Select an action before closing.'; fa = 'Select an action before closing.';
				|it = 'Scegliere operazione prima della chiusura.';
				|pl = 'Wybierz czynność przed zamknięciem';
				|tr = 'Kapatmadan önce bir eylem seçin.'"),
			Buttons);
		
	Else
		
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingOperationCompletion(Result, AdditionalParameters) Export
	
	Notify("Write_CashRegisterReceiptReturn", New Structure, Undefined);
	
	If Result Then
		
		If AdditionalParameters.CallbackDescription = Undefined Then
			ForcedShutdown = True;
			Close(Undefined);
		Else
			RunCallback(AdditionalParameters.CallbackDescription, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingCheckEnds(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = 1 Then
		
		// Postpone the receipt without reservation
		DeferOnClient(New CallbackDescription("QuestionBeforeClosingOperationCompletion", ThisObject, AdditionalParameters));
		
	ElsIf QuestionResult = 3 Then
		
		// Close without saving.
		If AdditionalParameters.CallbackDescription = Undefined Then
			ForcedShutdown = True;
			Close(Undefined);
		Else
			RunCallback(AdditionalParameters.CallbackDescription, Undefined);
		EndIf;
		
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(ThisObject.UUID, CashRegisterParameters.DeviceID);
		
	ElsIf QuestionResult = 4 Then
		
		// Delete the receipt.
		DeletionCompleted_ = RetailSalesServerCall.DeleteDocumentWhenCancelingFiscalTransaction(Object.Ref);
		
		If DeletionCompleted_ Then
			
			Notify("Write_CashRegisterReceiptReturn", New Structure, Undefined);
			
			If AdditionalParameters.CallbackDescription = Undefined Then
				ForcedShutdown = True;
				Close(Undefined);
			Else
				RunCallback(AdditionalParameters.CallbackDescription, Undefined);
			EndIf;
			
			// Close the KM check session on the CCT if it was opened
			RetailSalesClient.CloseKmVerificationSessionOnCCT(ThisObject.UUID, CashRegisterParameters.DeviceID);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure NewReceiptOnServer(Ref = Undefined)
	
	NewReceipt = Ref.GetObject();
	
	NewReceipt.Date = CurrentSessionDate();
	UnlockFormDataForEdit();
	ValueToFormData(NewReceipt, Object);
	
	ReadOnly = False;
	Modified = False;
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));

	FillInCashRegisterReceiptDetails();
	
	WhenCreatingReceipt();
	
EndProcedure

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfCWPElements(Form, AvailablePaymentMethods)
	
	ThereAreReturnablePositions = (Form.Object.Goods.Count() > 0);
	Form.Items.PayInCash.Enabled = ThereAreReturnablePositions;
	Form.Items.PaymentByCard.Enabled    = ThereAreReturnablePositions;
	Form.Items.MixedPayment.Enabled   = ThereAreReturnablePositions;
	
	If AvailablePaymentMethods.PaymentCards Then
		If Form.TotalAmountOfPaymentByCreditCards > Form.DocumentAmount Then
			Form.Items.PaymentByCard.Enabled = False;
		EndIf;
	EndIf;
	
	EstablishAvailabilityOfCWPElementsLocalization(Form, AvailablePaymentMethods);
	
EndProcedure

&AtClient
// Called from the MENUOPERATIONISKKM form
Procedure ChangeTheCashRegisterOfTheKKMCompletion(CashRegister, AdditionalParameters) Export
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If Object.CashRegister <> CashRegister Then
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
		
		ChangeTheCashRegisterOfTheKKM(CashRegister);
		RecalculateDocumentOnClient();
	EndIf;
	
EndProcedure

&AtServer
Procedure ChangeTheCashRegisterOfTheKKM(CashRegister)
	
	Object.CashRegister = CashRegister;
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		// We change only the Attributes associated with the cashier (except the Cashier), the composition of the returned items does not change.
		RegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
		FillPropertyValues(Object, RegisterShiftState,,"Cashier");
	Else
		NewReceipt = Documents.CashRegisterReceiptReturn.CreateDocument();
		NewReceipt.Partner = Catalogs.Partners.RetailCustomer;
		NewReceipt.Filling(New Structure("CashRegister", Object.CashRegister), True);
		NewReceipt.Date = CurrentSessionDate();
		
		Cashier = ?(ValueIsFilled(Object.Cashier), Object.Cashier, NewReceipt.Cashier);
		ValueToFormData(NewReceipt, Object);
		Read();
		
		FormEvents.OnReadAtServer(ThisObject, NewReceipt);
		Object.Cashier = Cashier;
	EndIf;
	
	ReadOnly = False;
	Modified = False;
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceiptReturn));
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	RefreshFormTitle();
	UpdateDashboardData(ThisObject, True = ReadOnly);

	ConfigureCWP();
	
EndProcedure

&AtClient
Function ExceededNumberOfPackagingUnitsOfNonReturnedItemsAccordingToCurrentLine(CurrentRowData)
	
	Result = False;
	If ValueIsFilled(Object.CashRegisterReceipt) And Not CurrentRowData = Undefined Then
		ItemSelectionBasedOnLineData = SelectionForSearchingByItem(CurrentRowData, UseItemVariants, UseItemsBatch, UseSets);
		Result = NumberOfPackagingUnitsOfNonReturnedItemsHasBeenExceeded(Object, ItemSelectionBasedOnLineData).Result;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Function CorrectExcessOfNumberOfPackagingUnitsAccordingToNonReturnedItems(AdditionalParameters)

	ModifiedRows = New Array;
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		// It is necessary to perform a check after changing the data in the table part
		NonReturnedPositionsByReceipt = GetFromTempStorage(CashRegisterReceiptDetails.AddressOfTableOfNonReturnedItems);
		RowsForDeletion = New Array;
		For Each LineProducts_ In Object.Goods Do
			DataOfNonReturnedPosition = NonReturnedPositionsByReceipt[LineProducts_.GetID()]; 
			If DataOfNonReturnedPosition = Undefined Then
				FilterRemainingGoodsByShelfLives = SelectionForSearchingByItem(LineProducts_, UseItemVariants, UseItemsBatch, UseSets);
				InformUserThatItemIsNotSpecifiedInSalesReceipt(FilterRemainingGoodsByShelfLives);
				RowsForDeletion.Add(LineProducts_);
			ElsIf ExceededNumberOfPackagingUnitsOfNonReturnedItemsInLine(LineProducts_, LineProducts_.NumberOfPackages) Then
				LineProducts_.NumberOfPackages = DataOfNonReturnedPosition.NumberOfPackages;
				LineProducts_.Count = DataOfNonReturnedPosition.Count;
				ModifiedRows.Add(LineProducts_);
			EndIf;
		EndDo;
		For Each RowForDeletion In RowsForDeletion Do
			Object.Goods.Delete(RowForDeletion);
		EndDo;		
	EndIf;
	
	Return ModifiedRows;	
EndFunction

&AtClientAtServerNoContext
Function NumberOfPackagingUnitsOfNonReturnedItemsHasBeenExceeded(Object, FilterRemainingGoodsByShelfLives, NumberOfPackages = 0, ThisIsAddedQuantity = True)
	
	CheckingExcess = New Structure("Result,FoundRow", False, Undefined);
	ProductLines_2 = Object.Goods.FindRows(FilterRemainingGoodsByShelfLives);
	If ProductLines_2.Count() Then
		CheckingExcess.FoundRow = ProductLines_2[0];
		// Check the excess in the table of returned goods of the document Receipt Cash register Return
		NumberOfPackagingUnitsToCheck = NumberOfPackages;
		If ThisIsAddedQuantity = True Then
			NumberOfPackagingUnitsToCheck = ProductLines_2[0].NumberOfPackages + NumberOfPackages;
		EndIf;
		CheckingExcess.Result = ExceededNumberOfPackagingUnitsOfNonReturnedItemsInLine(CheckingExcess.FoundRow, NumberOfPackagingUnitsToCheck); 
	Else
		CheckingExcess.Result = True;
		InformUserThatItemIsNotSpecifiedInSalesReceipt(FilterRemainingGoodsByShelfLives);
	EndIf;
	
	Return CheckingExcess;
EndFunction

&AtClientAtServerNoContext
Function ExceededNumberOfPackagingUnitsOfNonReturnedItemsInLine(StringToCheck, NumberOfPackagingUnitsToCheck)

	Result = False;
	If NumberOfPackagingUnitsToCheck > StringToCheck.NumberOfPackagesByReceipt Then
		Result = True;
		ErrorText = NStr("vi = 'Số lượng trả lại ""%Products%"" không thể lớn hơn số lượng đã chỉ ra trong phiếu bán hàng.';
						|ru = 'Возвращаемое количество ""%Products%"" не может быть больше, чем указано в чеке продажи.';
						|en = 'The quantity of %Products% to return cannot be greater than specified in the sales receipt.'; fa = 'The quantity of %Products% to return cannot be greater than specified in the sales receipt.';
						|it = 'Возвращаемое количество ""%Products%"" не может быть больше, чем указано в чеке продажи.';
						|pl = 'The quantity of %Products% to return cannot be greater than specified in the sales receipt.';
						|tr = 'İade edilen ""%Products%"" tutarı, satış fişinde gösterilenden fazla olamaz.'");
		ErrorText = StrReplace(ErrorText, "%Products%", StringToCheck.Products);

		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,);
	EndIf;
	
	Return Result;
EndFunction

&AtClientAtServerNoContext
Function SelectionForSearchingByItem(DataToFill, UseItemVariants, UseItemsBatch, UseSets)
	
	FilterForSearch = New Structure;
	FilterForSearch.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	If UseItemVariants Then
		FilterForSearch.Insert("Characteristic",  PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	EndIf;
	If UseItemsBatch Then
		FilterForSearch.Insert("Series", PredefinedValue("Catalog.ItemsBatches.EmptyRef"));
	EndIf;
	If UseSets Then
		FilterForSearch.Insert("ProductsInSet", PredefinedValue("Catalog.Products.EmptyRef"));
		FilterForSearch.Insert("ItemVariantOfSet", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	EndIf;
	
	FillPropertyValues(FilterForSearch, DataToFill);
	
	Return FilterForSearch;
EndFunction

&AtClientAtServerNoContext
Procedure InformUserThatItemIsNotSpecifiedInSalesReceipt(FilterRemainingGoodsByShelfLives)

		ErrorText = NStr("vi = 'Không thể trả lại mặt hàng ""%Products%"", bởi vì chưa chỉ ra nó trong phiếu bán hàng.';
						|ru = 'Нельзя вернуть позицию ""%Products%"", так как она не указана в чеке продажи.';
						|en = 'Cannot return the %Products% item as it is not specified in the sales receipt.'; fa = 'Cannot return the %Products% item as it is not specified in the sales receipt.';
						|it = 'Нельзя вернуть позицию ""%Products%"", так как она не указана в чеке продажи.';
						|pl = 'Cannot return the %Products% item as it is not specified in the sales receipt.';
						|tr = 'Satış fişinden belirtilmediğinden dolayı ""%Products%"" pozisyonu iade edilemez.'");
		ErrorText = StrReplace(ErrorText, "%Products%", FilterRemainingGoodsByShelfLives.Products);
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,);
			
EndProcedure

&AtClientAtServerNoContext
Procedure InformUserThatBarcodeWasNotFoundInSalesReceipt(Barcode)

		ErrorText = NStr("vi = 'Chưa tìm thấy mặt hàng có mã vạch ""%Barcode%"" trong phiếu bán hàng.';
						|ru = 'Позиция со штрихкодом ""%Barcode%"" не найдена в чеке продажи.';
						|en = 'The item with barcode %Barcode% is not found in the sales receipt.'; fa = 'The item with barcode %Barcode% is not found in the sales receipt.';
						|it = 'Позиция со штрихкодом ""%Barcode%"" не найдена в чеке продажи.';
						|pl = 'The item with barcode %Barcode% is not found in the sales receipt.';
						|tr = '""%Barcode%"" barkodlu pozisyon satış fişinde bulunamadı.'");
		ErrorText = StrReplace(ErrorText, "%Barcode%", Barcode);
		CommonClientServer.MessageToUser(
			ErrorText,
			,
			,
			,);
			
EndProcedure

// Returns an indication that the warehouse is using premises on the specified date.
//
// Parameters:
// 	Warehouse - CatalogRef.Warehouses - warehouse.
// 	Date - Date - date the attribute was received.
//
// Returns:
// 	Boolean
//
&AtServerNoContext
Function UseWarerooms(Warehouse, Date)
	
	Return WarehousesServer.UseWarerooms(Warehouse,
		?(ValueIsFilled(Date), Date, CurrentSessionDate()));
	
EndFunction

&AtServer
Function GetPriceBySelection(Products, Characteristic, Series, Package)
	
	FilterParameterStructure = New Structure;
	FilterParameterStructure.Insert("Currency", Object.Currency);
	FilterParameterStructure.Insert("Date", CurrentSessionDate());
	FilterParameterStructure.Insert("PriceKind", Object.PriceKind);
	FilterParameterStructure.Insert("Products", Products);
	FilterParameterStructure.Insert("Characteristic", Characteristic);
	FilterParameterStructure.Insert("Series", Series);
	FilterParameterStructure.Insert("Package", Package);
	
	Return EnterprisePricesFillingServer.GetPriceBySelection(FilterParameterStructure);
	
EndFunction

&AtServer
Procedure AddAssortmentCheckToActionStructure(StructureOfActions)
	
	AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
	AssortmentInspectionStructure.Ref = Object.Ref;
	AssortmentInspectionStructure.Warehouse = Object.Warehouse;
	AssortmentInspectionStructure.Date = Object.Date;
	AssortmentInspectionStructure.MessageText = NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng hoặc đã bị cấm bán.';
													|ru = 'Товар %1 не включен в ассортимент магазина или запрещен к продаже.';
													|en = 'Product %1 is not included in the store''s product range or prohibited for sale.'; fa = 'Product %1 is not included in the store''s product range or prohibited for sale.';
													|it = 'Il prodotto %1 non è incluso nell''inventario del negozio o ne è vietata la vendita.';
													|pl = 'Towar %1 nie jest zawarty w asortymencie sklepu lub jego sprzedaż jest zabroniona.';
													|tr = 'Ürün %1 mağazanın ürün yelpazesine dahil değildir veya satışına izin verilmemektedir.'");
	AssortmentInspectionStructure.NameOfAssortmentResource = "SalesAreAllowed";
	AssortmentInspectionStructure.CheckedYouCanAdd = True;
	AssortmentInspectionStructure.AllowAdding = False;
	
	StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
	
EndProcedure

#EndRegion

&AtServer
Procedure ConfigureCWP()
	
	SetPrivilegedMode(True);
	
	GetHardwareLinks();
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.AmountToReturn.Width                  = 22;
		Items.AmountToReturnByPaymentCards.Width = 22;
		Items.AmountToRefundInCash.Width         = 22;
	EndIf;

	UpdateFormButtonHeadersOnServer(False);	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
	Query = New Query(
	"SELECT TOP 1
	|	ISNULL(CWPSettings.KeyboardShortcuts, UNDEFINED)               AS KeyboardShortcuts,
	|	ISNULL(CWPSettings.KeyboardShortcuts.QuickGoods, UNDEFINED) AS QuickGoods,
	|	ISNULL(CWPSettings.KeyboardShortcuts.FormCommands, UNDEFINED)  AS FormCommands,
	|	CWPSettings.CashierCanBeASeller                             AS CashierCanBeASeller,
	|	CWPSettings.SellingAreaManagerMayActAsASeller              AS SellingAreaManagerMayActAsASeller,
	|	CWPSettings.UseAuthorization                              AS UseAuthorization
	|FROM
	|	Catalog.CWPSettings AS CWPSettings
	|WHERE
	|	CWPSettings.Workplace = &Workplace
	|	AND CWPSettings.Ref IN (SELECT DISTINCT T.Ref FROM Catalog.CWPSettings.CashRegisters AS T WHERE T.CashRegister = &CashRegister)
	|");
	
	Query.SetParameter("Workplace", EquipmentManagerServerCall.CustomerWorkplace());
	Query.SetParameter("CashRegister", Object.CashRegister);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		
		KeyboardShortcuts            = Selection.KeyboardShortcuts;
		SellingAreaManagerMayActAsASeller = Selection.SellingAreaManagerMayActAsASeller;
		CashierCanBeASeller  = Selection.CashierCanBeASeller;
		ForcefullyAuthorize = Selection.UseAuthorization;
		
		If ValueIsFilled(KeyboardShortcuts) Then
			RetailSales.ConfigureQuickItemsAndHotkeys(ThisObject, Selection);
		EndIf;
		
	Else
		
		KeyboardShortcuts                          = Undefined;
		ForcefullyAuthorize               = False;
		SellingAreaManagerMayActAsASeller = False;
		CashierCanBeASeller                = True;
		
	EndIf;
	
	ConfigureRightsForUser(Object.Cashier);
	
	SellerOnlyCashier = CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller;
	Items.GoodsSeller.Visible = Not SellerOnlyCashier;
	
	Items.QuickGoods.Visible     = ThisObject.QuickGoods.Count() > 0;
	
	Items.ChangeSeller.Visible  = Not SellerOnlyCashier;
	Items.ChangeWareroom.Visible = CashRegisterParameters.UseWarerooms;
	Items.GoodsPremise.Visible   = CashRegisterParameters.UseWarerooms;
	Items.SetComposition.Visible      = GetFunctionalOption("UseSets");
	Items.SpecifySeries.Visible      = SeriesSpecificationParameters.UseItemsBatch;
	// Setting the visibility of the "Get Weight" command
	TMCommonUse.CustomizePeripherals(ThisObject, "");
	
	AvailablePaymentMethods = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	
	If Object.PaymentWithPaymentCards.Count() > 0 
		And Not (Object.PaymentWithPaymentCards.Count() = 1 And TotalAmountOfPaymentByCreditCards < DocumentAmount) Then
		Items.Goods.ReadOnly        = True;
		Items.SearchByBarcode.Enabled = False;
		Items.OpenSelection.Enabled    = False;
	EndIf;
	
	EstablishAvailabilityOfCWPElements(ThisObject, AvailablePaymentMethods);
	
	Items.PayInCash.Visible = AvailablePaymentMethods.CashPayment;
	Items.PaymentByCard.Visible    = AvailablePaymentMethods.PaymentCards;
	Items.MixedPayment.Visible   = AvailablePaymentMethods.PaymentCards;
	
	Items.ShowOnlyReturnedPositions.Visible = False;
	Items.FillInAmountByReceipt.Visible = False;
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		
 		SetSelectionOfGoodsTableRows(DisplayModeOfProductsByReceipt, Items.Goods);
		Items.OpenSelection.Visible = False;
		Items.ShowOnlyReturnedPositions.Visible = True;
		Items.FillInAmountByReceipt.Visible = True;
		
		If Not Items.Goods.ContextMenu.ChildItems.Find("ProductsContextMenuAdd") = Undefined Then
			Items.Goods.ContextMenu.ChildItems.ProductsContextMenuAdd.Visible = False;
		EndIf;
		If Not Items.Goods.ContextMenu.ChildItems.Find("ProductItemsContextMenuCopy") = Undefined Then
			Items.Goods.ContextMenu.ChildItems.ProductItemsContextMenuCopy.Visible = False;
		EndIf;
		
		For Each SubordinateElementOfGoodsTable In Items.Goods.ChildItems Do
			If SubordinateElementOfGoodsTable = Items.GoodsNumberOfPackages
				Or SubordinateElementOfGoodsTable = Items.GoodsPackagingUnitOfMeasure
				Or SubordinateElementOfGoodsTable = Items.GoodsPackage Then
				Continue;
			EndIf;	
			SubordinateElementOfGoodsTable.ReadOnly = True;
		EndDo;
		
	Else
		DisplayModeOfProductsByReceipt = True;
	EndIf;
	Items.CancelPaymentsByPaymentCards.Enabled = (CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard > 0);

	Items.DecorativeFieldGroupRefundAmount1.Visible = Not Items.PaymentByCard.Visible;
	Items.DecorativeFieldGroupRefundAmount2.Visible = True;
	Items.AmountToReturnByPaymentCards.Visible = Items.PaymentByCard.Visible;
	
	ElementsToRegroup = New Array;
	ElementsToRegroup.Add(Items.QuickGoods);
	
	For Each Subgroup In Items.GroupBottomCommandBarContextCommands.ChildItems Do
		For Each Item In Subgroup.ChildItems Do
			ElementsToRegroup.Add(Item);
		EndDo;
	EndDo;
	
	ElementsToRegroup.Add(Items.PayInCash);
	ElementsToRegroup.Add(Items.PaymentByCard);
	ElementsToRegroup.Add(Items.MixedPayment);
	
	ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup);
	
	RetailSales.RearrangeFormButtons(ThisObject, ElementsToRegroup);
	
	RetailSales.ConfigurePrintCommands(ThisObject, Items.MovableButtons);
	
EndProcedure

// Called when you click on a hyperlink in the dashboard and click the "change Seller" command.
&AtClient
Procedure ChangeSellerCompletion(Seller, AdditionalParameters) Export
	
	If Not ValueIsFilled(Seller) Then
		Return;
	EndIf;
	
	CurrentSeller = Seller;
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		TSRow = Object.Goods.FindByID(SelectedRow);
		TSRow.Seller = CurrentSeller;
		
	EndDo;
	
	RefreshFormTitle();
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure UpdateTheStateOfRegisterShift()
	
	If ValueIsFilled(Object.CashRegister)
		And Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then

		StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
		If Object.CashRegisterShift <> StructureRegisterShiftState.CashRegisterShift Then
			FillPropertyValues(Object, StructureRegisterShiftState,,"Cashier");
		EndIf;

		CurrentUser = Users.CurrentUser();
		If Object.Cashier <> CurrentUser 
			And Not ValueIsFilled(Object.Cashier) Then

			Object.Cashier = CurrentUser;
		EndIf;

	EndIf;
	
EndProcedure

&AtServer
Procedure FillInCashRegisterReceiptDetails()

	CashRegisterReceiptDetails = New Structure;
	CashRegisterReceiptDetails.Insert("CashRegisterShift", PredefinedValue("Document.CashRegisterShift.EmptyRef"));
	CashRegisterReceiptDetails.Insert("CashRegisterShiftStatus", PredefinedValue("Enum.CashRegisterShiftStatuses.EmptyRef"));	
	CashRegisterReceiptDetails.Insert("DocumentAmount", 0);
	CashRegisterReceiptDetails.Insert("AddressOfTableOfNonCancelledPaymentsByPaymentCards", "");
	CashRegisterReceiptDetails.Insert("AddressOfTableOfNonReturnedItems", "");
	CashRegisterReceiptDetails.Insert("CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards", New Array);	
	CashRegisterReceiptDetails.Insert("LowestAmountOfNonCancelledPaymentByPaymentCard", 0);
	CashRegisterReceiptDetails.Insert("NumberOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("DataOfFirstNonCancelledPaymentByPaymentCards", Undefined);
	CashRegisterReceiptDetails.Insert("LineNumbersOfCancelledPaymentsByPaymentCard", New Map);
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
	
		AttributesOfCashRegisterReceipt = Common.ObjectAttributesValues(Object.CashRegisterReceipt, "CashRegisterShift,DocumentAmount");
		CashRegisterReceiptDetails.CashRegisterShift = AttributesOfCashRegisterReceipt.CashRegisterShift;
		CashRegisterReceiptDetails.DocumentAmount = AttributesOfCashRegisterReceipt.DocumentAmount;
		
		//@skip-check bsl-legacy-check-string-literal
		CashRegisterShiftStatus = Common.ObjectAttributeValue(CashRegisterReceiptDetails.CashRegisterShift, "Status");
		CashRegisterReceiptDetails.CashRegisterShiftStatus = CashRegisterShiftStatus;

		TableOfNonReturnedGoods = New ValueTable;
		ThisIsPendingReceiptCashRegisterReturn = (ValueIsFilled(Object.Ref) And Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_);
		If ThisIsPendingReceiptCashRegisterReturn Then
			FilterParameters = Documents.CashRegisterReceipt.ParametersForReceivingNonReturnedItemsByCashRegisterReceipt();
			FilterParameters.UsedByKKTFZ54 = UsedByKKTFZ54;
			FilterParameters.CashRegisterIsUsedWithoutConnectionOfEquipment = CashRegisterParameters.UseWithoutConnectingPeripherals;
			FilterParameters.CashRegisterShift = Object.CashRegisterShift;
			FilterParameters.CashRegisterReceipt = Object.CashRegisterReceipt;
			
			TableOfNonReturnedGoods = Documents.CashRegisterReceipt.TableOfNonReturnedItemsByCashRegisterReceipt(FilterParameters);

		EndIf;
		
		NonReturnedPositionsByReceipt = New Map;
		
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
		ArrayOfStringsToProcess = New Array;
		
		For Each TableRow In Object.Goods Do
			TableRow.ReturnedPosition = (TableRow.NumberOfPackages > 0);
			TableRow.NumberOfPackagesByReceipt = TableRow.NumberOfPackages;
			TableRow.QuantityByReceipt = TableRow.Count;
			If ThisIsPendingReceiptCashRegisterReturn Then
				ItemSelectionBasedOnLineData = SelectionForSearchingByItem(TableRow, UseItemVariants, UseItemsBatch, UseSets);
				RowsOfNonReturnedGoods = TableOfNonReturnedGoods.FindRows(ItemSelectionBasedOnLineData);
				If RowsOfNonReturnedGoods.Count() Then
					TableRow.NumberOfPackagesByReceipt = RowsOfNonReturnedGoods[0].NumberOfPackages;
					TableRow.QuantityByReceipt = RowsOfNonReturnedGoods[0].Count;
					If RowsOfNonReturnedGoods[0].Package <> TableRow.Package Then
						ArrayOfStringsToProcess.Add(TableRow);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateNumberOfPackages");

		For Each TableRow In Object.Goods Do
			If Not ArrayOfStringsToProcess.Find(TableRow) = Undefined Then
				DataToRecalculate = New Structure;
				DataToRecalculate.Insert("Package", TableRow.Package);
				DataToRecalculate.Insert("Products", TableRow.Products);
				DataToRecalculate.Insert("Count", TableRow.QuantityByReceipt);
				DataToRecalculate.Insert("NumberOfPackages", TableRow.NumberOfPackagesByReceipt);
				BatchProcessingOfTablePartServer.ProcessTSString(
					DataToRecalculate, StructureOfActions, CachedValues);
					
				TableRow.NumberOfPackagesByReceipt = DataToRecalculate.NumberOfPackages;
			EndIf;
			DataOfNonReturnedPosition = New Structure("Package,NumberOfPackages,Count", TableRow.Package, TableRow.NumberOfPackagesByReceipt, TableRow.QuantityByReceipt);
			NonReturnedPositionsByReceipt.Insert(TableRow.GetID(), DataOfNonReturnedPosition);
		EndDo;
		
		CashRegisterReceiptDetails.AddressOfTableOfNonReturnedItems = PutToTempStorage(NonReturnedPositionsByReceipt, UUID);
		
		FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.PayForESFSS.Visible = False;
	Items.PayForSBP.Visible = False;
	
EndProcedure

&AtServer
Procedure FillInDetailsOfNonCancelledPaymentsWithPaymentCardsByCashRegisterReceipt()

	CashRegisterReceiptDetails.Insert("CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards", New Array);
	CashRegisterReceiptDetails.Insert("LowestAmountOfNonCancelledPaymentByPaymentCard", 0);
	CashRegisterReceiptDetails.Insert("NumberOfOutstandingPaymentsByPaymentCards", 0);
	CashRegisterReceiptDetails.Insert("DataOfFirstNonCancelledPaymentByPaymentCards", Undefined);
	CashRegisterReceiptDetails.Insert("LineNumbersOfCancelledPaymentsByPaymentCard", New Map);
	
	If ValueIsFilled(Object.CashRegisterReceipt) Then
		
		ArrayOfPaymentKinds = New Array;
		ArrayOfPaymentKinds.Add(Enums.TypesOfCashRegisterPaymentSystem.PaymentCard);

		Query = New Query(Documents.CashRegisterReceipt.QueryTextForReceivingUndeliveredPaymentsByCashRegisterReceipt(True, False));
		Query.SetParameter("Ref", Object.CashRegisterReceipt);
		Query.SetParameter("TypesOfPayments", ArrayOfPaymentKinds);
		
		TableOfNonCancelledPaymentsByPaymentCards = Query.Execute().Unload();
		
		// Checking that the acquiring terminals used for payment by sales receipt are configured.
		ConfiguredAcquiringTerminals = New Map;
		For Each Terminal In POSTerminals Do
			TerminalValue = Terminal.Value; // Structure
			ConfiguredAcquiringTerminals.Insert(TerminalValue.Ref, Terminal.Value);
		EndDo;
		ArrayOfRowsToDelete = New Array;
		For Each NonCancelledPaymentByPaymentCard In TableOfNonCancelledPaymentsByPaymentCards Do
			If NonCancelledPaymentByPaymentCard.Sum > Object.DocumentAmount 
				Or ConfiguredAcquiringTerminals[NonCancelledPaymentByPaymentCard.POSTerminal] = Undefined Then
				ArrayOfRowsToDelete.Add(NonCancelledPaymentByPaymentCard);
			EndIf;
		EndDo;
		For Each RowForDeletion In ArrayOfRowsToDelete Do
			TableOfNonCancelledPaymentsByPaymentCards.Delete(RowForDeletion);
		EndDo;
		
		TableOfNonCancelledPaymentsByPaymentCards.Columns.Add("LineNumber");
		LineNumberOfUndonePayment = 0;
		For Each LineOfUndeliveredPayments In TableOfNonCancelledPaymentsByPaymentCards Do
			LineOfUndeliveredPayments.LineNumber = LineNumberOfUndonePayment;
			LineNumberOfUndonePayment = LineNumberOfUndonePayment + 1;
		EndDo;
		
		CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards = PutToTempStorage(TableOfNonCancelledPaymentsByPaymentCards, UUID);
		
		ResultOfRecalculation = RetailSalesServerCall.RecalculateDataOfNonCanceledPaymentsByPaymentCards(CashRegisterReceiptDetails.AddressOfTableOfNonCancelledPaymentsByPaymentCards);
		CashRegisterReceiptDetails.DataOfFirstNonCancelledPaymentByPaymentCards = ResultOfRecalculation.DataOfFirstNonCancelledPaymentByPaymentCards;
		CashRegisterReceiptDetails.NumberOfOutstandingPaymentsByPaymentCards = ResultOfRecalculation.NumberOfOutstandingPaymentsByPaymentCards;
		CashRegisterReceiptDetails.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards = ResultOfRecalculation.CombinationsOfAmountsOfNonCancelledPaymentsByPaymentCards;
		CashRegisterReceiptDetails.LowestAmountOfNonCancelledPaymentByPaymentCard = ResultOfRecalculation.LowestAmountOfNonCancelledPaymentByPaymentCard;
		
	EndIf;
	
EndProcedure

#Region QuickGoodsAndQuantityCheckingProcessing

&AtServer
Procedure AddToCartOnServer(ProductParameters_1, NewLines)
	
	UseWarerooms = UseWarerooms(Object.Warehouse, Object.Date);
	
	// Restricts the rows used to prepare the source data when performing batch processing of rows in the table part.
	AddedRowsForProcessing = New Array;
	// It is used to obtain data on the error in calculating the sums from the New line parameter in relation to the added rows of the table part of the Products.
	RelationshipOfAddedAndNewLines = New Map;
	
	Errors_ = New Map();
	
	ModifiedRowsToProcess = New Array;
	For Each RowOfProduct In NewLines Do
		
		If RowOfProduct.Package.IsEmpty() Then
			RowOfProduct.Package = SelectGoodsServerCall.GetStoragePackaging(RowOfProduct.Products);
		EndIf;
		
		If Not ValueIsFilled(RowOfProduct.Price) And ProductParameters_1.ItemsType <> Enums.ItemsTypes.Set Then
			RowOfProduct.Price = GetPriceBySelection(RowOfProduct.Products, RowOfProduct.Characteristic, RowOfProduct.Series, RowOfProduct.Package);
		EndIf;
		
		Filter = New Structure;
		Filter.Insert("ProductsInSet",   RowOfProduct.ProductsInSet);
		Filter.Insert("ItemVariantOfSet", RowOfProduct.ItemVariantOfSet);
		Filter.Insert("Products",   RowOfProduct.Products);
		Filter.Insert("Characteristic", RowOfProduct.Characteristic);
		Filter.Insert("Package",       RowOfProduct.Package);
		Filter.Insert("Price",           RowOfProduct.Price);
		Filter.Insert("Premise",      RowOfProduct.Premise);
		
		SearchResult = Object.Goods.FindRows(Filter);
		
		If SearchResult.Count() = 0 Or RowOfProduct.Error_ <> 0 Then
			
			CurrentRow = Object.Goods.Add();
			
			FillPropertyValues(CurrentRow, ProductParameters_1);
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
			AddedRowsForProcessing.Add(CurrentRow);
			Errors_.Insert(CurrentRow, RowOfProduct.Error_);
			RelationshipOfAddedAndNewLines.Insert(CurrentRow, RowOfProduct);
		Else
			
			CurrentRow = SearchResult[0];
			
			CurrentRow.NumberOfPackages = RowOfProduct.NumberOfPackages + CurrentRow.NumberOfPackages;
			ModifiedRowsToProcess.Add(CurrentRow);
			
		EndIf;
		
	EndDo;
	
	If AddedRowsForProcessing.Count() Or	ModifiedRowsToProcess.Count() Then
		If AddedRowsForProcessing.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			
			StructureOfActions = New Structure;
			
			If UseWarerooms Then
				StructureOfActions.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
			EndIf;
			
			If CashierCanBeASeller And Not SellingAreaManagerMayActAsASeller Then
				StructureOfActions.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
			EndIf;

			StructureOfActions.Insert("FillInVATRate",
				BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
			If ControlProductRange Then
				AddAssortmentCheckToActionStructure(StructureOfActions);
			EndIf;
			
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
			BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
			
			StructureOfActions.Insert("CheckCharacteristicsByOwner");
			StructureOfActions.Insert("CheckFillPackageByOwner");
			StructureOfActions.Insert("RecalculateAmountTakingIntoAccountRoundingError",
				New Structure("ErrorsByLines", Errors_));
			
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				AddedRowsForProcessing,
				StructureOfActions,
				Object.Goods,
				CachedValues);
			
		EndIf;
		
		If ModifiedRowsToProcess.Count() Then
			CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			
			StructureOfActions = New Structure;
			AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);
			If ControlProductRange Then
				AddAssortmentCheckToActionStructure(StructureOfActions);
			EndIf;
			BatchProcessingOfTablePartServer.ProcessTSStrings(
				ModifiedRowsToProcess,
				StructureOfActions,
				Object.Goods,
				CachedValues);
		EndIf;
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	EndIf;
		
	If CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	If NewLines.Count() Then
		FillInServiceDetailsForProductRange();
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;

EndProcedure

&AtClient
Procedure AddToCart(ProductParameters_1)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	NewLines = New Array;
	
	If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
		
		ComponentParameters = SelectGoodsClientServer.ProductParameters_1();
		FillPropertyValues(ComponentParameters, ProductParameters_1);
		ComponentParameters.ProductsInSet   = ProductParameters_1.Products;
		ComponentParameters.ItemVariantOfSet = ProductParameters_1.Characteristic;
		ComponentParameters.Insert("ItemKitConfiguration", Undefined);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Date",    Object.Date);
		AdditionalParameters.Insert("Currency",  Object.Currency);
		AdditionalParameters.Insert("PriceKind", Object.PriceKind);
		AdditionalParameters.Insert("Price",    ProductParameters_1.Price);
		AdditionalParameters.Insert("Organization", Object.Organization);
		SelectedGoods = SetsServerCall.Components(ComponentParameters, AdditionalParameters);
		
		For Each SelectedGoodItem In SelectedGoods Do
			NewLines.Add(SelectedGoodItem);
		EndDo;
		
	Else
		
		If Not ValueIsFilled(ProductParameters_1.Package) Then
			ProductParameters_1.Package = SelectGoodsServerCall.GetStoragePackaging(ProductParameters_1.Products);	
		EndIf;
		
		NewLines.Add(ProductParameters_1);
		
	EndIf;
	
	DataParameters = New Structure;
	DataParameters.Insert("NewLines", NewLines);
	DataParameters.Insert("ProductParameters_1", ProductParameters_1);
	
	AddFragmentToCart(DataParameters);
		
EndProcedure

&AtClient
Procedure AddToCartAfterSelectingQuantity(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	NewLines = New Array;

	For Each SelectedGoodItem In Result.SelectedGoods Do

		NewRow = SelectGoodsClientServer.ProductParameters_1();

		FillPropertyValues(NewRow, AdditionalParameters);
		FillPropertyValues(NewRow, SelectedGoodItem);

		NewLines.Add(NewRow);

	EndDo;

	DataParameters = New Structure;
	DataParameters.Insert("NewLines", NewLines);
	DataParameters.Insert("ProductParameters_1", AdditionalParameters.ProductParameters_1);

	AddFragmentToCart(DataParameters);

EndProcedure

&AtClient
Procedure AddFragmentToCart(DataParameters)
	
	NewLines = DataParameters.NewLines;
	ProductParameters_1 = DataParameters.ProductParameters_1;
	
	AddToCartOnServer(ProductParameters_1, NewLines);
	
	RecalculateDocumentOnClient();
	
	Modified = True;
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

&AtClientAtServerNoContext
Procedure EstablishAvailabilityOfCWPElementsLocalization(Form, AvailablePaymentMethods)
	
	
EndProcedure

&AtServer
Procedure ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup)
	
	
EndProcedure

&AtClient
Procedure PayForESFSSLocalization()
	
	
EndProcedure

&AtClient
Procedure PayForSBPLocalization()
	
	
EndProcedure

&AtClientAtServerNoContext
Procedure PaymentInformationLocalization(Form, PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure PrintingReceiptAfterRecordingChangesLocalization(ParametersOfReceiptFiscalizationOperation)
	
	
	//@skip-warning
	SetFiscalStatusBroken();
	
	RetailSalesClient.UnblockForm(ThisObject);
	
EndProcedure

&AtServer
Function ParametersOfReceiptFiscalizationOperationOnServerLocalization()
	
	ParametersOfReceiptFiscalizationOperation = New Structure;
	
	
	Return ParametersOfReceiptFiscalizationOperation;
	
EndFunction

&AtClient
Procedure SetFiscalStatusBroken()
	
	Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_");
	RetailSalesClientServer.SaveDataOfDynamicAttributesOfFormTablesToCache(ThisObject);
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
	
	Write(WriteParameters);
	
	ReadOnly = True;
	
	CommonClient.MessageToUser(
		NStr("vi = 'Chưa triển khai tính năng in phiếu đối với chứng từ. Hãy liên hệ với nhà phát triển.';
			|ru = 'Функционал печати чека для документа не реализован. Обратитесь к разработчикам.';
			|en = 'Printing a receipt for the document is not implemented. Contact the developers.'; fa = 'Printing a receipt for the document is not implemented. Contact the developers.';
			|it = 'Il funzionale di stampa dello scontrino per il documento non è venduto. Rivolgersi agli elaboratori.';
			|pl = 'Funkcja drukowania paragonu dla dokumentu nie jest zaimplementowana. Zwróć się do deweloperów.';
			|tr = 'Belge için makbuz yazdırma işlevi uygulanmamıştır. Geliştiricilerle iletişime geçin.'"));
	
EndProcedure

&AtClientAtServerNoContext
Procedure InfoBarLocalization(Form, PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure StartPerformingAdditionalActionsBeforeReturningLocalizationPayment(CallbackOnCompletion)
	

	RunCallback(CallbackOnCompletion, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure StartPerformingAdditionalActionsBeforeReturningPaymentEnd(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		PerformActionAfterRecording(
			AdditionalParameters.CallbackOnCompletion,
			NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi lại chứng từ.';
				|ru = 'Перед открытием формы оплаты не удалось записать документ.';
				|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
				|it = 'Перед открытием формы оплаты не удалось записать документ.';
				|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
				|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	EndIf;
		
EndProcedure


#EndRegion
