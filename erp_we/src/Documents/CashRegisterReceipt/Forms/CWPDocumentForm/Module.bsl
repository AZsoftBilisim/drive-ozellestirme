#Region Variables

&AtClient
Var CachedValues;//used by the mechanism for processing changes in PM details

&AtClient
Var CurDataId; //used to pass the current line to the wait handler


&AtClient
Var UIDOfMeasurementVerificationOfMarkingCodeByMeansOfKKT;

&AtClient
Var MeasurementUIDPrintingOfSlipReceipt;

&AtClient
Var MeasurementUIDStartFiscalizationOfReceiptOnFiscalDevice;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	UseDiscountsMarkupsInSales = GetFunctionalOption("UseDiscountsMarkupsInSales");
	UseDiscountAdjustmentsInSales         = GetFunctionalOption("UseDiscountAdjustmentsInSales");
	ProvideDiscountsByCalculationInCashReceiptButton     = GetFunctionalOption("ProvideDiscountsByCalculationInCashReceiptButton");
	UsePaymentByCards       = GetFunctionalOption("UsePaymentByCards");
	UseGiftCards         = GetFunctionalOption("UseGiftCards");
	UseItemVariants    = GetFunctionalOption("UseItemVariants");
	UseSeveralWarehouses              = GetFunctionalOption("UseSeveralWarehouses");
	UseLoyaltyCards               = GetFunctionalOption("UseLoyaltyCards");
	UsePriceManagementSystem25             = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	UsePurchaseCommission           = GetFunctionalOption("UsePurchaseCommission");
	
	FiscalOperationData = RetailSales.StructureOfFiscalTransactionData();

	ControlProductRange                 = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	SupportedPeripheralTypes = "BarcodeScanner,
	                                              |CustomerDisplay,
	                                              |FiscalCashRegisters,
	                                              |POSTerminal,
	                                              |DigitalRetailScales,
	                                              |MagneticStripeCardReaders,
	                                              |ReceiptPrinter,
	                                              |CREWITHDATATRANSFER";
	TMCommonUse.CustomizePeripherals(ThisObject, "");
	RetailSales.FillInEquipmentTable(ThisObject, SupportedPeripheralTypes);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		If Object.Goods.Count() > 0 Then
			For Each TSRow In Object.Goods Do
				TSRow.SSFCertificateIsUsed = False;
			EndDo;
		EndIf;
		
	EndIf;
	
	If Not Catalogs.CashRegisters.CashRegisterHasBeenSetUpForCWP() Then
		Items.GroupBottomCommandBarPayment.Enabled = False;
		
		MessageText = NStr("vi = 'Đối với chỗ làm việc hiện tại, chưa chỉ ra quầy thu ngân. Không cho phép đánh phiếu tính tiền.';
							|ru = 'Для текущего рабочего места не указана Касса ККМ. Пробитие чека недоступно.';
							|en = 'The cash register is not specified for the current workplace. Cannot issue a sales slip.'; fa = 'The cash register is not specified for the current workplace. Cannot issue a sales slip.';
							|it = 'Для текущего рабочего места не указана Касса ККМ. Пробитие чека недоступно.';
							|pl = 'The cash register is not specified for the current workplace. Cannot issue a sales slip.';
							|tr = 'Mevcut çalışma alanı için yazar kasa belirtilmedi. Fiş kesimi mevcut değildir.'");
		Common.MessageToUser(MessageText);
	EndIf;
	
	If UsePeripherals Then
		EquipmentAttached = EquipmentManagerServerCall.EquipmentByParameters(
			Undefined,
			Undefined,
			EquipmentManagerServerCall.CustomerWorkplace()).Count() > 0;
		MeaningOpenFormWithConnectedHardware = Common.CommonSettingsStorageLoad(
			"CashRegisterReceipt", "OpenFormWithPeripherals");
		If MeaningOpenFormWithConnectedHardware = Undefined Then
			OpenFormWithPeripherals = EquipmentAttached;
		Else
			OpenFormWithPeripherals = MeaningOpenFormWithConnectedHardware And EquipmentAttached;
		EndIf;
	EndIf;
	
	UpdateCacheInformationOnOpenedPackages();
	
	SetValuesBySettings();
	SetFormItemsVisibility();
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	OnCreateAtServerLocalization(ThisObject, Cancel, StandardProcessing);
	
	ProcessingOfTabularForms.InitializeRowCache(Items.Goods);

	WhenCreatingReceipt();
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Object.PriceKind)
		And Not PriceTypeIncludesVATAmount(Object.PriceKind) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Dạng đơn giá được dùng để bán lẻ, đơn giá phải bao gồm thuế GTGT.';
										|ru = 'Вид цены, используемый для продажи в розницу, должен включать в цене НДС.';
										|en = 'The price type used for retail sales must include VAT in price.'; fa = 'The price type used for retail sales must include VAT in price.';
										|it = 'Tipo di prezzo usato per la vendita al dettaglio deve includere IVA.';
										|pl = 'Rodzaj ceny, używany do sprzedaży detalicznej, powinien być zawierany w cenie VAT.';
										|tr = 'Perakende satışlar için kullanılan fiyat türünde fiyata KDV dahil edilmelidir.'"));
			
		ReadOnly = True;
		
		Return;
		
	EndIf;
	
	If UsePeripherals Then
		
		If OpenFormWithPeripherals Then
			
			AttachIdleHandler("OpenConnectedHardwareWaitHandlerForm", 0.5, True);
			
		Else
			
			AttachIdleHandler("StartHardwareConnectionHandlerWaiting", 0.1, True);
			
			CheckItemPricesLocalization();
			
		EndIf;
		
	Else
		
		CheckItemPricesLocalization();
		
	EndIf;
	
	RecalculateDocumentOnClient();
	
	If ForcefullyAuthorize Then
		AttachIdleHandler("OpenAuthorizationWindow", 0.5, True);
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
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

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
		
		CurrentRow = Object.Goods.FindByID(ValueSelected.CurrentRowID);
		ProcessRowONChangingSeries(CurrentRow);
		
		AdditionalParameters = New Structure;
		FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalParameters);
		If AdditionalParameters.Property("ServerCallRequired__") Then
			If CachedValues = Undefined Then
				CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
			EndIf;
			CachedValues.Insert("FormEvents");
			GoodsAtEndOfEditingOnServer(Items.Goods.CurrentData.GetID(), CachedValues);
		EndIf;
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		RecalculateDocumentOnClient();
		
	EndIf;
	
	If ChoiceSource.FormName = "DataProcessor.SelectGoodsToSalesDocument.Form.Form" Then

		RetailSalesClient.UnblockForm(ThisObject);
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		RecalculateDocumentOnClient();
		AttachIdleHandler("SetCurrentElementToTabularPartOfProducts", 0.1, True);
	EndIf;
	
	If ChoiceSource.FormName = "Document.CashRegisterReceipt.Form.SelectDeferredReceipt" Then
		UploadNewReceipt(ValueSelected);
	EndIf;
	
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
	If IsInputAvailable()
		And Not ReadOnly
		And Source = "Peripherals" Then
		
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
			
		EndIf;
		
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If Not ReadOnly
		And EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		If ValueIsFilled(CachedValues)
			And CachedValues.Property("Barcodes") Then
			
			CachedValues.Barcodes.Clear();
			
		EndIf;
		
		If CommonClientServer.HasAttributeOrObjectProperty(ThisObject, "MarkingCodeForClarification") 
			And ValueIsFilled(CommonClientServer.GetFormAttributeByPath(ThisObject, "MarkingCodeForClarification")) Then
			
			CommonClient.MessageToUser(NStr("vi = 'Có mã dán nhãn để làm rõ. Không thể tự động thêm các mặt hàng mới.';
											|ru = 'Есть код маркировки для уточнения. Автоматическое добавление новых позиций невозможно.';
											|en = 'There is a marking code for specification. You cannot automatically add new items.'; fa = 'There is a marking code for specification. You cannot automatically add new items.';
											|it = 'Esiste un codice di marcatura per la precisazione. Impossibile aggiungere nuove voci automaticamente.';
											|pl = 'Jest kod oznakowania do uściślenia. Automatyczne dodawanie nowych pozycji jest niemożliwe.';
											|tr = 'Açıklama için bir işaretleme kodu vardır. Otomatik olarak yeni kalemler eklemek mümkün değildir.'"));
			
			Return;
			
		EndIf;
		
		BarcodeData_5 = New Array;
		
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5, False, True);
		
	EndIf;
	
	If EventName = "LoyaltyCardIsRead"
		And Parameter.OwnerForm = UUID Then
		
		LoyaltyCardIsRead(Parameter.LoyaltyCard);
		
	EndIf;
	
	If EventName = "MessagesReceived"
		And Parameter.OwnerForm = UUID Then
		
		MessagesReceived(Parameter.Messages);
		RecalculateDocumentOnClient();
		
	EndIf;
	
	If EventName = "QuickProductSelected"
		And Parameter.OwnerForm = UUID Then
		
		ProductParameters_1 = SelectGoodsClientServer.ProductParameters_1();
		FillPropertyValues(ProductParameters_1, Parameter);
		ProductParameters_1.Seller = CurrentSeller;
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
	
	If EventName = "Closing_EditingSet"
		And Parameter.OwnerForm = UUID Then
		AtEndOfEditingSet(Parameter.AddressInTempStorage);
		RecalculateDocumentOnClient();
	EndIf;
	
	If EventName = "EditSet"
		And Parameter.OwnerForm = UUID Then
		
		KitParameters = New Structure;
		KitParameters.Insert("ProductsInSet", Parameter.ProductsInSet);
		KitParameters.Insert("ItemVariantOfSet", Parameter.ItemVariantOfSet);
		KitParameters.Insert("DialColumns", DialColumns(ThisObject));
		
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
		OpeningParameters.Insert("ProhibitPriceEditing", True);
		OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
		OpeningParameters.Insert("Organization", Object.Organization);
		
		OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
		
	EndIf;
	
	If EventName = "EquipmentAttached" Then
		RetailSalesClient.ProcessHardwareConnectedEvent(ThisObject, Parameter, Source);
		AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 1, True);
	EndIf;
	
	If EventName = "ChangedCurSessionWorkplace" Then
		
		ConfigureCWP();
		If (Not CashRegisterParameters.UseWithoutConnectingPeripherals And Not ValueIsFilled(CashRegisterParameters.DeviceID))
			Or Not ValueIsFilled(CashRegisterParameters.CWPSettings) Then
			
			ShowMessageBox(
				New CallbackDescription("AlertProcessingChangedCurSessionWorkplace", ThisObject, New Structure("EventName, Parameter", EventName, Parameter)),
				NStr("vi = 'Đã thay đổi chỗ làm việc của thiết bị kết nối. Chỗ làm việc này chưa tùy chỉnh thiết bị.';
					|ru = 'Изменено рабочее место подключаемого оборудования. Для данного рабочего места не настроено оборудование.';
					|en = 'Peripherals workplace has been changed. Equipment is not configured for this workplace.'; fa = 'Peripherals workplace has been changed. Equipment is not configured for this workplace.';
					|it = 'Il posto di lavoro dell''attrezzatura collegata è stato modificato. Nessuna apparecchiatura è stata configurata per questo posto di lavoro.';
					|pl = 'Zmieniono miejsce pracy podłączonego sprzętu. Dla tego miejsca pracy nie skonfigurowano żadnego sprzętu.';
					|tr = 'Bağlanacak ekipmanın çalışma alanı değiştirildi. Bu çalışma alanı için hiçbir ekipman yapılandırılmadı.'"));
			Return;
			
		EndIf;
		
	EndIf;
	
	If EventName = "ChangingCashShift" Then
		StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
		FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
	
	SetVisibilityOfSeriesElements();
	
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	ControlProductRange = ProductRangeServerCached.ControlProductRange(Object.Warehouse, Object.Date);
	
	FillInServiceDetailsForProductRange();
	UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	UpdateStatusesAndAllowedItemsLocalization();
	ProcessPermitsForSaleOfGoodsLocalization(ThisObject);


EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	FormEvents.BeforeWriteAtServer(ThisObject, CurrentObject, Cancel, WriteParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(CurrentObject, Documents.CashRegisterReceipt));
	
	FillInServiceDetailsForProductRange();
	RetailSalesClientServer.RecoverDataFromCacheOfDynamicDetailsOfFormTables(ThisObject);
	
	If Not WriteParameters.Property("TransactionMode") Or Not WriteParameters.TransactionMode Then
		// StandardSubsystems.AccessManagement
		AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
		// End StandardSubsystems.AccessManagement
		FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
		ProvisionInDocumentsServer.CheckToRunBackgroundInventoryAllocationJob();
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_CashRegisterReceipt", WriteParameters, Object.Ref);

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InformationPanelOtherParametersValueURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	If FormattedStringURL = "SellerValueNotFilledIn"
		Or FormattedStringURL = "Seller" Then
		OpenForm(
			"Catalog.Users.ChoiceForm",
			New Structure("ChoiceMode", True),,,,,
			New CallbackDescription("EditSellerHyperlinkCompletion", ThisObject), FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
	If FormattedStringURL = "RoomValueNotFilled"
		Or FormattedStringURL = "Premise" Then
		ChangeWareroom(Undefined);
	EndIf;
	
	If FormattedStringURL = "Map" Then
		ShowValue(,Object.LoyaltyCard);
	EndIf;
	
	If FormattedStringURL = "Messages" Then
		DiscountsMarkupsFillingClient.OpenMessageForm(TheStructureOfTheMessages, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationPanelCalculationOfTheAmountURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

	If FormattedStringURL = "ManualDiscount" Then
		OpenFormForAssigningManualDiscounts();
	EndIf;
	
	If FormattedStringURL = "AutomaticDiscount" Then
		If Not Object.DiscountsAreCalculated Then
			ShowQueryBox(
				New CallbackDescription("OpenInformationAboutDiscountsCompletion", ThisObject),
				NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
					|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
					|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
					|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
					|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
					|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
		Else
			OpenDiscountInformationFragment();
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure InformationPanelErrorWhenPrintingNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	StandardProcessing = False;
	If FormattedStringURL = "ShowCompleteErrorWhenPrintingReceipt" Then
		ShowValue(Undefined, InformationPanelErrorWhenPrintingReceiptText);	
	EndIf;
EndProcedure


#EndRegion

#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If SetsClient.ItemToLock(Field) Then
		
		CurrentRow = Object.Goods.FindByID(RowSelected);
		If ValueIsFilled(CurrentRow.ProductsInSet) Then
			
			NotificationParameter1 = New Structure;
			NotificationParameter1.Insert("ProductsInSet",   CurrentRow.ProductsInSet);
			NotificationParameter1.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
			NotificationParameter1.Insert("OwnerForm", UUID);
			
			Notify("EditSet", NotificationParameter1, ThisObject);
			
		EndIf;
		
	ElsIf Field = Items.GoodsProductsInSet Then
		ShowValue(Undefined, Items.Goods.CurrentData.ProductsInSet);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure GoodsOnActivateCell(Item)
	
	FormEventsClient.OnActivateCell(ThisObject, Item);
	
	If Item.CurrentItem = Items.GoodsNumberOfPackages Then
		QuantityColumnIsActivated = True;
	Else
		QuantityColumnIsActivated = False;
	EndIf;
	
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
Procedure GoodsOnActivateRow(Item)
	
	If ForcedShutdown Then
		Return;
	EndIf;
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	GoodsOnActivateRowLocalization(Item);
	
EndProcedure

&AtClient
Procedure GoodsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsOnChange(Item)
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	
	RecalculateDocumentOnClient();
	
	GoodsOnChangeLocalization(Item);
	
EndProcedure

&AtClient
Procedure GoodsOnStartEdit(Item, NewRow, Copy)
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters,
		Copy);
	
	If Copy Then
		CurrentData = Item.CurrentData;
		If ValueIsFilled(CurrentData.RowID) Then
			CurrentData.RowID = String(New UUID);
		EndIf;
	EndIf;
	
	GoodsOnStartEditLocalization(Item, NewRow, Copy);
	
EndProcedure

&AtClient
Procedure GoodsOnEditEnd(Item, NewRow, CancelEdit)
	
	RecalculateDocumentOnClient();
	
	AdditionalParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalParameters);

	If AdditionalParameters.Property("ServerCallRequired__") Then
		CachedValues.Insert("FormEvents");
	EndIf;
	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters) Then
		CachedValues.Insert("SeriesStatusesNeedToBeUpdated");
		AdditionalParameters.Insert("ServerCallRequired__", True);
	EndIf;

	GoodsOnEditEndLocalization(
		Item, NewRow, CancelEdit, CachedValues, AdditionalParameters);
	
	If AdditionalParameters.Property("ServerCallRequired__") And AdditionalParameters.ServerCallRequired__ = True Then
		AttachIdleHandler("GoodsAtEndOfEditingForServerCall", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure GoodsAtEndOfEditingForServerCall()
	
	CurrentData = Items.Goods.CurrentData;
	If TypeOf(CachedValues) = Type("Structure") And CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		IDCurrentRow = CurrentData.GetID();
	EndIf;
	
	GoodsAtEndOfEditingOnServer(IDCurrentRow, CachedValues);
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	If TypeOf(CachedValues) = Type("Structure") And CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		CachedValues.Delete("SeriesStatusesNeedToBeUpdated");
	EndIf;
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServer(RowID, CachedValues)
	
	If Not TypeOf(CachedValues) = Type("Structure") Then
		Return;
	EndIf;
	
	If CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(RowID, CachedValues);
	EndIf;

	If CachedValues.Property("FormEvents") Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
		CachedValues.Delete("FormEvents");
	EndIf;
	
	GoodsAtEndOfEditingOnServerLocalization(RowID, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsBeforeDeleteRow(Item, Cancel)
	
	If Not AccessRights.LineAdjustment Then
		Cancel = True;
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);

	ProductsClient.UpdateCachedValuesToAccountForSeries(
		Item,
		CachedValues,
		SeriesSpecificationParameters);
	
	SetsClient.BeforeDeletingRowOfTablePart(ThisObject, "Goods", Cancel);
	
	AdditionalAttributes = New Structure("BeforeDeleteRow");
	FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalAttributes);
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	CheckPermissionToDeleteRowInTablePart("Goods", Cancel);

EndProcedure

&AtClient
Procedure GoodsAfterDeleteRow(Item)
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();
	
	AdditionalAttributes = New Structure("ServerCallRequired__, AfterDeleteRow", False);
	FormEventsClient.WhenChangingElement(ThisObject, "Goods", AdditionalAttributes);
	If TypeOf(CachedValues) = Type("Structure")
		And AdditionalAttributes.ServerCallRequired__ Then
		
		CachedValues.Insert("FormEvents");
	EndIf;

	If ProductsClient.SeriesStatusesNeedToBeUpdated(Item, CachedValues, SeriesSpecificationParameters, True) Then
		AdditionalAttributes.ServerCallRequired__ = True;
		
		If TypeOf(CachedValues) = Type("Structure") Then
			CachedValues.Insert("SeriesStatusesNeedToBeUpdated");
		EndIf;
	EndIf;

	If AdditionalAttributes.ServerCallRequired__ Then
		GoodsAtEndOfEditingOnServer(Undefined, CachedValues);
	EndIf;

	If TypeOf(CachedValues) = Type("Structure")
		And CachedValues.Property("SeriesStatusesNeedToBeUpdated") Then
		
		ProductsClient.UpdateCachedValuesToAccountForSeries(Items.Goods, CachedValues, SeriesSpecificationParameters);
		CachedValues.Delete("SeriesStatusesNeedToBeUpdated");
	EndIf;
	
	GoodsAfterDeleteRowLocalization(Item);
	
EndProcedure

&AtClient
Procedure GoodsProductsOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	
	GoodsProductsOnChangeServer(CurrentRowID);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();
	
	GoodsProductsOnChangeLocalization(Item);
	
EndProcedure

&AtServer
Procedure GoodsProductsOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	ElsIf UsePriceManagementSystem25 Then 
		StructureOfActions.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	If UseWarerooms(Object.Warehouse, Object.Date) Then
		StructureOfActions.Insert("FillRoom", New Structure("Warehouse, Products, Characteristic", Object.Warehouse, CurrentRow.Products, CurrentRow.Characteristic));
	EndIf;
	
	StructureOfActions.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	If ControlProductRange Then
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
	EndIf;
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
	If Not SelectMarkingCodesForOpenedConsumerPackagesByFIFOLocalization() Then
		ProcessOpenedConsumerPackagingUnitsAccordingToItemTableLocalization(Object.Goods.Unload());
	EndIf;
	
	RetailSalesLocalization.UpdateStatusAndPermissionToSell(CurrentRow, Object);
	RetailSalesLocalization.DeletePermissionToSellWithoutLinkedProduct(CurrentRow, ThisObject);
	
EndProcedure

&AtClient
Procedure GoodsCharacteristicOnChange(Item)
	
	CurrentRowID = Items.Goods.CurrentData.GetID();
	
	GoodsCharacteristicOnChangeServer(CurrentRowID);
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure GoodsCharacteristicOnChangeServer(CurrentRowID)
	
	CurrentRow = Object.Goods.FindByID(CurrentRowID);
	
	StructureOfActions = New Structure;
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	ElsIf UsePriceManagementSystem25 Then 
		StructureOfActions.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateAmount");
	
	If UseWarerooms(Object.Warehouse, Object.Date) Then
		StructureOfActions.Insert("FillRoom", New Structure("Warehouse, Products, Characteristic", Object.Warehouse, CurrentRow.Products, CurrentRow.Characteristic));
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	StructureOfActions.Insert("CharacteristicOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Characteristic", StructureOfActions);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If ValueIsFilled(Object.PriceKind) Then
		If ControlProductRange Then
			StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		ElsIf UsePriceManagementSystem25 Then 
			StructureOfActions.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
		Else
			StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);

EndProcedure

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();

EndProcedure

&AtClient
Procedure GoodsSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure GoodsSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value                   = Items.Goods.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters, ValueSelected);
	
	CurrentData = Items.Goods.CurrentData;
	ProcessRowONChangingSeries(CurrentData);
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure GoodsPercentRateOfManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure GoodsManualDiscountOnChange(Item)
	
	CurrentRow = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculatePercentageOfManualDiscount");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure GoodsBeforeRowChange(Item, Cancel)
	
	
EndProcedure

&AtClient
Procedure GoodsPremiseOnChange(Item)
	RetailSalesClient.UpdateRoomInRowsOfTabularPartOfSeries(ThisObject, Items.Goods.CurrentData, CachedLines[Items.Goods.Name].Premise);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure AssignAutomaticDiscounts(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	Object.PaymentMethod = PredefinedValue("Enum.PaymentForms.EmptyRef");
	
	Notification = New CallbackDescription("AssignAutomaticDiscountsCompletion", ThisObject);
	If ParametersOfDiscountApplication.AssignedManagedDiscounts Then
		DiscountsMarkupsFillingClient.OpenManagedDiscountMarkUpAssignmentForm(
			PerformPreliminaryCalculationOfDiscountsOnServer(),
			Notification);
	Else
		RunCallback(Notification, ManagedDiscounts);
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintTheLastSalesSlip(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	SlipReceiptLine = "";
	
	If Not EquipmentManagerClient.Peripherals().Property("LastSlipCheck", SlipReceiptLine)
		Or TypeOf(SlipReceiptLine) <> Type("String") 
		Or IsBlankString(SlipReceiptLine) Then
		
		MessageText = 
			NStr("vi = 'Không có phiếu cuối.
			         |Có thể là đối với phiên làm việc này vẫn chưa thực hiện giao dịch thẻ thanh toán.';
			         |ru = 'Слип-чек отсутствует.
			         |Возможно для данного сеанса еще не выполнялась эквайринговая операция.';
			         |en = 'Sales slip is missing.
			         |Probably, the acquiring transaction has not been performed for this session yet.'; fa = 'Sales slip is missing.
			         |Probably, the acquiring transaction has not been performed for this session yet.';
			         |it = 'Non è previsto il controllo di scorrimento.
			         | Per la sessione corrente probabilmente ancora nessuna operazione di acquisizione è stata effettuata.';
			         |pl = 'Brakuje slipu.
			         |Możliwe, że dla tej sesji jeszcze nie wykonano operacji acquiringu.';
			         |tr = 'PoS fişi bulunmamaktadır.
			         |Bu oturum için henüz bir PoS işlemi yapılmamış olabilir.'");
		RetailSalesServerCall.LogEntry(
		MessageText, "PrintTheLastSalesSlip", Object.Ref);
		CommonClient.MessageToUser(MessageText);
		
		Return;
		
	EndIf;
	
	EquipmentAttached = EquipmentManagerTMClient.EquipmentAttached(CashRegisterParameters.DeviceID);
	If EquipmentAttached Then
		
		MeasurementUIDPrintingOfSlipReceipt = PerformanceMonitorClient.TimeMeasurement("Document.CashRegisterReceipt.Form.CWPDocumentForm.PrintTheLastSalesSlip");
		
		NotificationOnCompletion = New CallbackDescription("AfterPrintingSlipReceiptIsComplete", ThisObject);
		
		OperationParametersList = PeripheralsReceiptPrintersClientServer.TextPrintingOptions(SlipReceiptLine);
		
		PeripheralsReceiptPrintersClient.Start_PrintingText(
			NotificationOnCompletion,
			UUID,
			CashRegisterParameters.DeviceID,
			OperationParametersList);
		
	Else
		
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa kết nối máy tính tiền';
				|ru = 'Фискальное устройство не подключено.';
				|en = 'Fiscal device is not connected.'; fa = 'Fiscal device is not connected.';
				|it = 'Dispositivo fiscale non collegato.';
				|pl = 'Urządzenie fiskalne nie jest podłączone.';
				|tr = 'Mali cihaz bağlı değil.'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReturnOfGoodsWithoutReceipt(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	NotificationProcessing = New CallbackDescription("ReturnOfGoodsWithoutReceiptNotificationProcessing", ThisObject);
	
	RetailSalesClient.ProcessShiftState(ThisObject, NotificationProcessing);
	
EndProcedure

&AtClient
Procedure NewReceipt(Command)
	
	UploadNewReceipt();
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscounts(Command)
	
	If Not Object.DiscountsAreCalculated Then
		ShowQueryBox(
			New CallbackDescription("OpenInformationAboutDiscountsCompletion", ThisObject),
			NStr("vi = 'Chưa tính chiết khấu (phụ thu), tính chiết khấu (phụ thu)?';
				|ru = 'Скидки (наценки) не рассчитаны, рассчитать?';
				|en = 'Discounts (markups) are not calculated, calculate?'; fa = 'Discounts (markups) are not calculated, calculate?';
				|it = 'Gli sconti (sovrapprezzi) non sono stati calcolati, calcolare?';
				|pl = 'Rabaty (marże) nie są obliczane, obliczyć?';
				|tr = 'İndirimler uygulanmadı. Uygulamak istiyor musunuz?'"), QuestionDialogMode.YesNo);
	Else
		OpenDiscountInformationFragment();
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchByBarcodeExecute(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure ShowMessages(Command)
	
	DiscountsMarkupsFillingClient.OpenMessageForm(TheStructureOfTheMessages(), ThisObject);
	
EndProcedure

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

&AtClient
Procedure ToReadLoyaltyCard(Command)
	
	If ReadOnly Then // The receipt has been punched. Changing information is prohibited.
		Return;
	EndIf;
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Organization", Object.Organization);
	OpeningParameters.Insert("DoNotUseManualInput", Not AccessRights.ChangingLoyaltyCards);
	OpeningParameters.Insert("DoNotConnectTheEquipment", True);
	
	OpenForm(
		"Catalog.LoyaltyCards.Form.ReadLoyaltyCard",
		OpeningParameters,
		ThisObject,
		UUID);
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	OpenSelectionOfSeries();
	
EndProcedure

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
Procedure QuickGoods(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	OpenForm("Document.CashRegisterReceipt.Form.QuickGoods", New Structure("KeyboardShortcuts", KeyboardShortcuts), ThisObject);
	
EndProcedure

// Parameters:
// 	Command - FormCommand
&AtClient
Procedure GoodsReturn(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	NotificationProcessing = New CallbackDescription("ReturnOfGoodsProcessingOfNotification", ThisObject);
	
	RetailSalesClient.ProcessShiftState(ThisObject, NotificationProcessing);
	
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
Procedure ChangeSeller(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	OpenForm(
		"Document.CashRegisterReceipt.Form.SelectSeller",,
		ThisObject,,,,
		New CallbackDescription("ChangeSellerCompletion", ThisObject));
	
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
	
	KitParameters = New Structure;
	KitParameters.Insert("ProductsInSet", CurrentRow.ProductsInSet);
	KitParameters.Insert("ItemVariantOfSet", CurrentRow.ItemVariantOfSet);
	KitParameters.Insert("DialColumns", DialColumns(ThisObject));
	
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
	OpeningParameters.Insert("ProhibitPriceEditing", True);
	OpeningParameters.Insert("HideCommandRemainingQuantityInWarehouses", False);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("DataProcessor.EditSet.Form.Form", OpeningParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure Peripherals_(Command)
	
	RetailSalesClient.OpenConnectedHardwareForm(ThisObject, False);
	
EndProcedure

&AtClient
Procedure OpenTheSCCMOperationsMenu(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("CashRegister", Object.CashRegister);
	FormOpenParameters.Insert("Cashier",   Object.Cashier);
	FormOpenParameters.Insert("ChangeTheCashRegisterOfTheKKM", True);
	
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
Procedure PayUsingGiftCertificate(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
		
	SelectedPaymentMethod = StructureOfPaymentForm();
	SelectedPaymentMethod.Insert("GiftCertificates", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PayWithGiftCertificateProcessingNotification", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure PayByPaymentCard(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
		
	SelectedPaymentMethod = StructureOfPaymentForm();
	SelectedPaymentMethod.Insert("PaymentCards", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PayByCreditCardProcessingNotifications", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure MixedPayment(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("MixedPaymentNotificationProcessing", ThisObject));
	
EndProcedure

&AtClient
Procedure PayInCash(Command)
	
	RetailSalesClient.LockForm(ThisObject);
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	SelectedPaymentMethod = StructureOfPaymentForm();
	SelectedPaymentMethod.Insert("CashPayment", True);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	
	RetailSalesClient.ProcessShiftState(
		ThisObject,
		New CallbackDescription("PayInCashHandlingAlerts", ThisObject, AdditionalParameters));
	
EndProcedure

&AtClient
Procedure OpenSelection(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("Document.CashRegisterReceipt.CWPDocumentForm.Command.OpenSelection");
	
	RetailSalesClient.ClearMessageWindow(ThisObject);

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
	
	FormParameters = New Structure;
	FormParameters.Insert("PriceKind", Object.PriceKind);
	FormParameters.Insert("SelectionModeWithoutAgreementsWithCustomers", True);
	FormParameters.Insert("AnalysisOptionOfProductsSoldTogether", PredefinedValue("Enum.AnalysisOptionsForItemsSoldTogether.RetailSale"));
	FormParameters.Insert("SelectionModeByProductRange", ControlProductRange);
	FormParameters.Insert("ObjectForStoringSalesTermsAndConditions", ObjectForStoringSalesTermsAndConditions);
	If UsePriceManagementSystem25 Then
		FormParameters.Insert("SelectionModeForRetailSales", True);
	EndIf;
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
	
	AddLocalizationFormParameters(FormParameters);
	
	OpenForm("DataProcessor.SelectGoodsToSalesDocument.Form", FormParameters, ThisObject, UUID);
	
EndProcedure

&AtClient
Procedure ManualDiscounts(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	OpenFormForAssigningManualDiscounts();
	
EndProcedure

&AtClient
Procedure AppliedDiscounts(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	If Not Object.DiscountsAreCalculated Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa tính chiết khấu. Trước khi mở báo cáo, cần tính chiết khấu.';
										|ru = 'Скидки не рассчитаны. Перед открытием отчета необходимо рассчитать скидки.';
										|en = 'Discounts are not calculated. Before opening the report, calculate the discounts.'; fa = 'Discounts are not calculated. Before opening the report, calculate the discounts.';
										|it = 'Discounts are not calculated. Before opening the report, calculate the discounts.';
										|pl = 'Discounts are not calculated. Before opening the report, calculate the discounts.';
										|tr = 'İndirimler hesaplanmadı. Rapor açılmadan önce indirimlerin hesaplanması gerekmektedir.'"));
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("OpenReportFormForAppliedDiscounts", ThisObject),
		NStr("vi = 'Trước khi mở báo cáo chiết khấu được áp dụng, không thể ghi lại chứng từ.';
			|ru = 'Перед открытием отчета примененных скидок не удалось записать документ.';
			|en = 'Cannot save the document before opening the applied discounts report.'; fa = 'Cannot save the document before opening the applied discounts report.';
			|it = 'Cannot save the document before opening the applied discounts report.';
			|pl = 'Cannot save the document before opening the applied discounts report.';
			|tr = 'Uygulanan indirimler raporu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure OpenReportFormForAppliedDiscounts(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("CommandParameter", Object.Ref);
	
	OpenForm("Report.DiscountsAppliedInDocument.Form.ReportForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenPaymentCardPayments(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	AdditionalParameters = New Structure;
	RunCallback(
		New CallbackDescription("CancelPaymentsByPaymentCards", ThisObject, AdditionalParameters));
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
Procedure PayForESFSS(Command)
	
	PayForESFSSLocalization();
	
EndProcedure

&AtClient
Procedure PayForSBP(Command)
	
	PayForSBPLocalization();
	
EndProcedure

&AtClient
Procedure SpecifySalesPermit(Command)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	SpecifySalesPermitLocalization();
	
EndProcedure

&AtClient
Procedure CloseInformationPanelErrorsWhenPrintingReceipt(Command)
	Items.InformationPanelErrorWhenPrintingReceipt.Title = "";
	InformationPanelErrorWhenPrintingReceiptText = "";
	Items.InformationPanelGroupErrorWhenPrintingReceipt.Visible = False;
EndProcedure


#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.GoodsCharacteristic.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Goods.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không sử dụng đặc tính>';
													|ru = '<характеристики не используются>';
													|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
													|it = '<le caratteristiche non vengono usate>';
													|pl = '<charakterystyki nie dotyczą>';
													|tr = '<varyantlar kullanılmamaktadır>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	

	//

	ProductsServer.EstablishConditionalAppearanceOfProductSeries(ThisObject, False);

	//

	ProductsServer.SetConditionalAppearanceOfStatusIndicationSeries(ThisObject, False);
	
	//

	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);

	//
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	
	//
	
	SetsServer.SetConditionalAppearance(ThisObject, "Goods");

EndProcedure

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
	If Form.UseDiscountsMarkupsInSales Then
		Columns.Add("PercentRateOfAutomaticDiscountMarkup");
		Columns.Add("DiscountMarkupAmount");
	EndIf;
	
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
		WhenRemovingComponentsOnServer("Goods", AdditionalParameter, CachedValues);
	EndIf;
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure WhenRemovingComponentsOnServer(TSName, AdditionalParameter, CachedValues)
	
	SetsServer.WhenRemovingComponents(ThisObject, TSName, AdditionalParameter);
	
	CachedValues.Insert("FormEvents");
	GoodsAtEndOfEditingOnServer(Undefined, CachedValues);
	
EndProcedure

&AtServer
Function SetAddressInTemporaryStorage(Var_Parameters)
	
	Return SetsServer.SetAddressInTemporaryStorage(ThisObject, Var_Parameters, "Goods");
	
EndFunction

&AtServer
Procedure AtEndOfEditingSet(AddressInTempStorage)

	StructureOfActionsWithAddedStrings = New Structure;
	
	If UseWarerooms(Object.Warehouse, Object.Date) Then
		StructureOfActionsWithAddedStrings.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	
	StructureOfActionsWithModifiedStrings = New Structure;
	
	DataParameters = New Structure;
	DataParameters.Insert("Data", GetFromTempStorage(AddressInTempStorage));
	DataParameters.Insert("StructureOfActionsWithModifiedStrings", StructureOfActionsWithModifiedStrings);
	DataParameters.Insert("StructureOfActionsWithAddedStrings", StructureOfActionsWithAddedStrings);
	DataParameters.Insert("DialColumns", DialColumns(ThisObject));
	
	SetsServer.AtEndOfEditingSet(ThisObject, "Goods", DataParameters);
	
EndProcedure

#EndRegion

#Region CalculationOfDiscounts

&AtClient
Procedure CalculateDiscountsMarginsAndOpenPaymentForm(AdditionalParameters)
	
	CurrentItem = Items.More;
	
	If UseDiscountsMarkupsInSales
		And (ParametersOfDiscountApplication.FormOfPaymentAffectsCalculationOfDiscounts Or ParametersOfDiscountApplication.PaymentInPointsAffectsScoringOfPoints)
		And ParametersOfDiscountApplication.DiscountsAssigned Then
		
		If Not AdditionalParameters.Property("SelectedPaymentMethod") Then
			
			If Not CheckFilling() Then
				Return;
			EndIf;
			
			AvailablePaymentMethods = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
			
			FormOpenParameters = New Structure;
			FormOpenParameters.Insert(
				"CashPayment",
				New Structure("Value, Visible", True, AvailablePaymentMethods.CashPayment));
			FormOpenParameters.Insert(
				"PaymentCards",
				New Structure("Value, Visible", False, AvailablePaymentMethods.PaymentCards));
			FormOpenParameters.Insert(
				"BonusPoints",
				New Structure("Value, Visible, Parameter", False, AvailablePaymentMethods.BonusPoints, Object.LoyaltyCard));
			FormOpenParameters.Insert(
				"GiftCertificates",
				New Structure("Value, Visible", False, AvailablePaymentMethods.GiftCertificates));
			
			OpenForm(
				"Document.CashRegisterReceipt.Form.ChoosingAPaymentForm",
				New Structure("Parameter", FormOpenParameters),
				ThisObject,
				UUID,,,
				New CallbackDescription("ChoosingFormOfPaymentPaymentCompletion", ThisObject, AdditionalParameters));
			
		Else
			
			UpdatePaymentFormData(ThisObject, AdditionalParameters.SelectedPaymentMethod);
			CalculationFragment(AdditionalParameters);
			
		EndIf;
		
	Else
		
		// The form of payment does not affect the calculation of discounts (margins)
		If Not AdditionalParameters.Property("SelectedPaymentMethod") Then
			SelectedPaymentMethod = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
		Else
			SelectedPaymentMethod = AdditionalParameters.SelectedPaymentMethod;
		EndIf;
		
		UpdatePaymentFormData(ThisObject, SelectedPaymentMethod);
		AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
		CalculationFragment(AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformTheCalculation(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		If ParametersOfDiscountApplication <> Undefined
			And ParametersOfDiscountApplication.DiscountsAssigned
			And Not Object.DiscountsAreCalculated
			And Object.Goods.Count() > 0 Then
			
			CallbackDescription = New CallbackDescription(
				"NeedToCalculateDiscountMarkUpQuestion",
				ThisObject,
				AdditionalParameters);
			
			TesktQuestion = NStr("vi = 'Đầu tiên bạn cần tính toán giảm giá (tỷ suất lợi nhuận). Làm phép tính?';
								|ru = 'Предварительно необходимо рассчитать скидки (наценки). Выполнить расчет?';
								|en = 'It is required to calculate discounts (markups) beforehand. Calculate?'; fa = 'It is required to calculate discounts (markups) beforehand. Calculate?';
								|it = 'È necessario innanzitutto calcolare gli sconti (sovrapprezzi). Calcolare?';
								|pl = 'Musisz najpierw obliczyć rabaty (marże). Wykonać obliczenia?';
								|tr = 'İndirimler (ek ücretler) önceden hesaplanmalıdır. Hesaplansın mı?'");
			ShowQueryBox(CallbackDescription, TesktQuestion, QuestionDialogMode.YesNo);
		Else
			CalculateDiscountsMarginsAndOpenPaymentForm(AdditionalParameters);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure StartPerformingAdditionalActionsBeforePayingLocalization(CallbackOnCompletion)
	
	RunCallback(CallbackOnCompletion, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure NeedToCalculateDiscountMarkUpQuestion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Yes Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	CalculateDiscountsMarginsAndOpenPaymentForm(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure ChoosingFormOfPaymentPaymentCompletion(SelectedPaymentMethod, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedPaymentMethod) Then
		Return;
	EndIf;
	
	Modified = True;
	
	SelectedPaymentMethodLocalization(SelectedPaymentMethod);
	
	AdditionalParameters.Insert("SelectedPaymentMethod", SelectedPaymentMethod);
	UpdatePaymentFormData(ThisObject, SelectedPaymentMethod);
	CalculationFragment(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CalculationFragment(AdditionalParameters)
	
	If UseDiscountsMarkupsInSales
		And ParametersOfDiscountApplication.DiscountsAssigned
		And (ParametersOfDiscountApplication.AssignedManagedDiscounts And Not Object.DiscountsAreCalculated)
		And ProvideDiscountsByCalculationInCashReceiptButton Then
		
		Notification = New CallbackDescription("CalculationAfterSelectingManagedDiscounts", ThisObject, AdditionalParameters);
		DiscountsMarkupsFillingClient.OpenManagedDiscountMarkUpAssignmentForm(
			PerformPreliminaryCalculationOfDiscountsOnServer(),
			Notification);
		
	Else
		CalculationOfDiscountsOnClient(ManagedDiscounts, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculationAfterSelectingManagedDiscounts(Result, AdditionalParameters) Export 
	
	If Result = Undefined Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	CalculationOfDiscountsOnClient(Result, AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CalculationOfDiscountsOnClient(ReturnValueManagedDiscounts, AdditionalParameters)
	
	Object.UsePaymentWithBonusPoints = AdditionalParameters.SelectedPaymentMethod.BonusPoints;
	
	If (UseDiscountsMarkupsInSales
		And ParametersOfDiscountApplication.DiscountsAssigned)
		Or (Not ControlIsDisabledForTheWarehouse) Then
		
		MeasurementUUID = PerformanceMonitorClient.TimeMeasurement(
			"Document.CashRegisterReceipt.Form.CWPDocumentForm.CalculationOfDiscountsOnClient",, False);
			
		RetryRecordingIsRequired = False;
		Result = PerformPartOfCalculationOnServer(ReturnValueManagedDiscounts, RetryRecordingIsRequired);
		
		PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID, Not Result.CalculationCompletedSuccessfully);
		
		If Not Result.CalculationCompletedSuccessfully Then
			
			AdditionalParametersWriteAttempt = RetailSalesClientServer.RecordingRepeatStructure();
			AdditionalParametersWriteAttempt.CallbackDescription         = New CallbackDescription("CalculationOfDiscountsOnClientReRecordingCompletion", ThisObject, AdditionalParameters);
			AdditionalParametersWriteAttempt.MessageText             = NStr("vi = 'Các hoạt động sao lưu không thể ghi chứng từ.';
																			|ru = 'При выполнении операции резервирования не удалось записать документ.';
																			|en = 'Cannot save the document during the reservation.'; fa = 'Cannot save the document during the reservation.';
																			|it = 'Durante l''operazione di prenotazione non è stato possibile registrare il documento.';
																			|pl = 'Podczas wykonywania operacji tworzenia kopii zapasowej nie udało się zapisać dokumentu.';
																			|tr = 'Bir rezervasyon işlemi sırasında bir belge kaydedilemedi.'");
			AdditionalParametersWriteAttempt.ReturnFunctionResult = True;
			AdditionalParametersWriteAttempt.ProcedureName               = "PerformPartOfCalculationOnServer";
			AdditionalParametersWriteAttempt.ProcedureParameters         = ReturnValueManagedDiscounts;
			AdditionalParametersWriteAttempt.OperationResult          = Result;
			
			If Not RetryRecordingIsRequired Then
				ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersWriteAttempt);
				Return;
			EndIf;
			
			ShowQueryBox(
				New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersWriteAttempt),
				AdditionalParametersWriteAttempt.MessageText,
				QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
			Return;
			
		EndIf;
		
		If Result.TheStructureOfTheMessages <> Undefined And Result.TheStructureOfTheMessages.Messages.Count() > 0 And Result.TheStructureOfTheMessages.AutomaticallyOpen Then
			Items.ShowMessages.Visible = Result.TheStructureOfTheMessages.Messages.Count() > 0;
			
			FormOpeningData = Result.TheStructureOfTheMessages;
			FormOpeningData.Insert("BeforeMakingThePaymentInTheKKMReceipt", True);
			FormOpeningData.Insert("SelectedPaymentMethod", AdditionalParameters.SelectedPaymentMethod);
			
			OpenForm(
				"CommonForm.MessagesOfDiscountsMarkups",
				FormOpeningData,
				ThisObject,
				UUID,,,
				New CallbackDescription("MessagesOfDiscountsMarkupsCompletion", ThisObject, AdditionalParameters));
			Return;
			
		EndIf;
		
	EndIf;
	
	RunCallback(AdditionalParameters.CallbackOnCompletion, AdditionalParameters.SelectedPaymentMethod);
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure MessagesOfDiscountsMarkupsCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined And Result <> False Then
		
		RunCallback(AdditionalParameters.CallbackOnCompletion, Result);
		
	Else
		
		RunCallback(AdditionalParameters.CallbackOnCompletion, False);
		
	EndIf;
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure CalculationOfDiscountsOnClientReRecordingCompletion(Result, AdditionalParameters) Export
	
	If Not Result.CalculationCompletedSuccessfully Then
		RunCallback(AdditionalParameters.CallbackOnCompletion, False);
		Return;
	EndIf;
	
	If Result.TheStructureOfTheMessages <> Undefined And Result.TheStructureOfTheMessages.Messages.Count() > 0 And Result.TheStructureOfTheMessages.AutomaticallyOpen Then
		Items.ShowMessages.Visible = Result.TheStructureOfTheMessages.Messages.Count() > 0;
		OpenForm("CommonForm.MessagesOfDiscountsMarkups", Result.TheStructureOfTheMessages, ThisObject, UUID);
	EndIf;
	
	RunCallback(AdditionalParameters.CallbackOnCompletion, True);
	
	RecalculateDocumentOnClient();
	
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
	
	PerformActionAfterRecording(
		New CallbackDescription("PrintingReceiptAfterRecordingChanges", ThisObject),
		NStr("vi = 'Trước khi thực hiện thao tác đánh phiếu, không thể ghi lại chứng từ.';
			|ru = 'Перед выполнением операции пробития чека не удалось записать документ.';
			|en = 'Cannot save the document before issuing the receipt.'; fa = 'Cannot save the document before issuing the receipt.';
			|it = 'Prima dell''emissione dello scontrino non è stato possibile salvare il documento.';
			|pl = 'Przed wykonaniem operacji wybicia paragonu nie udało się zapisać dokumentu.';
			|tr = 'Fiş kesim işlemi gerçekleştirilmeden önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure PrintingReceiptAfterRecordingChanges(ExecutionParameters, AdditionalParameters) Export
	
	ParametersOfReceiptFiscalizationOperation = ParametersOfReceiptFiscalizationOperation();
	PrintingReceiptAfterRecordingChangesLocalization(ParametersOfReceiptFiscalizationOperation);
	
EndProcedure

#Region FiscalTransaction

&AtServer
Function RecordFiscalTransactionOnServer(RetryRecordingIsRequired, FiscalizationParameters)
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
	WriteParameters.Insert("TransactionMode", True);

	Result = RetailSales.RecordFiscalTransactionOnServer(ThisObject, FiscalizationParameters, WriteParameters);
	
	If Result Then
		WriteParameters.Insert("TransactionMode", False);
		AfterWriteAtServer(FormAttributeToValue("Object"), WriteParameters);
	Else
		RetryRecordingIsRequired = True;
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
		FillInServiceDetailsForProductRange();
	EndIf;
		
	Return Result;
EndFunction

#EndRegion

#EndRegion

#Region OnChangeAttributes

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingNumberOfUnits(StructureOfActions,Object)
	
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	
EndProcedure

&AtClient
Procedure ProcessRowONChangingSeries(CurrentRow)
	
	StructureOfActions = New Structure;
	If ControlProductRange Then
		StructureOfActions.Insert("FillInSalePriceByProductRange",
			BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	ElsIf UsePriceManagementSystem25 Then 
		StructureOfActions.Insert("FillInRetailSalesTermsAndConditions",
			BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(
				Object, ObjectForStoringSalesTermsAndConditions));
	Else
		StructureOfActions.Insert("FillInSalePrice",
			BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount",
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));

	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Series", StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, Undefined);
	
EndProcedure

#EndRegion

#Region PricingAndDiscounts

&AtServer
Procedure AssignManualDiscountOnServer(AmountOfDiscountMarkUp, Val SelectedRows, AddressInTempStorage)
	
	DiscountParameters = DiscountsMarkupsFillingServer.NewOptionsAssignManualDiscount();
	DiscountParameters.AutomaticDiscountsAreUsed = True;
	DiscountParameters.SelectedRows				 = SelectedRows;
	DiscountParameters.AddressInTempStorage		 = AddressInTempStorage;
	
	AddDiscountParametersLocalization(DiscountParameters);
	
	DiscountsMarkupsFillingServer.AssignAManualDiscount(Object, "Goods", AmountOfDiscountMarkUp, DiscountParameters);
	
EndProcedure

&AtServer
Function PlaceTabularPartOfPaymentByPaymentCardsInVault()
	
	Return PutToTempStorage(Object.PaymentWithPaymentCards.Unload(), UUID);
	
EndFunction

&AtServer
Procedure CalculateDiscountsWithoutApplyingToObject()
	
	Object.Date = CurrentSessionDate();
	
	CalculationParameters = DiscountsMarkupsFillingServer.NewParametersCalculate();
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, CalculationParameters);
	AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	
EndProcedure

&AtServer
Function PerformPreliminaryCalculationOfDiscountsOnServer()
	
	Object.Date = CurrentSessionDate();
	
	ParametersStructure1 = DiscountsMarkupsFillingServer.NewParametersCalculate();
	ParametersStructure1.ApplyToObject				 = False;
	ParametersStructure1.OnlyPreliminaryCalculation		 = True;
	ParametersStructure1.RestoreManagedDiscounts	 = True;;
	ParametersStructure1.ManagedDiscounts				 = ManagedDiscounts;
	
	Return PutToTempStorage(
			DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1), UUID);
	
EndFunction

&AtServer
Function CalculateDiscountsMarginsOnServer(ParametersStructure1)
	
	Object.Date = CurrentSessionDate();
	
	AppliedDiscounts = DiscountsMarkupsFillingServer.Calculate(Object, ParametersStructure1);
	
	AddressOfAppliedDiscountsInTheTemporaryStorage = PutToTempStorage(AppliedDiscounts, UUID);
	
	Modified = True;
	
	Return DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	
EndFunction

&AtServer
Procedure CancelDiscountsMarginsOnServer()
	
	For Each TSRow In Object.Goods Do
		TSRow.AmountOfBonusPointsToDeduction = 0;
		TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
	EndDo;
	
	DiscountsMarkupsFillingServer.CancelDiscounts(Object, "Goods", False,, True);
	Modified = True;
	
EndProcedure

&AtServer
Function ParametersForApplyingDiscountsMarkups(Object, Date)
	
	SetPrivilegedMode(True);
	
	WarehouseGroups = New Array;
	If UseSeveralWarehouses Then
		Query = New Query(
		"SELECT DISTINCT
		|	T.Ref.Parent AS Ref
		|FROM
		|	Catalog.Warehouses AS T
		|WHERE
		|	T.Ref IN (&Warehouse)
		|TOTALS BY
		|	Ref ONLY HIERARCHY
		|");
		Query.Parameters.Insert("Warehouse", Object.Warehouse);
		WarehouseGroups = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	QueryText = "
	|SELECT DISTINCT
	|	ListOfDiscounts.DiscountMarkup AS DiscountMarkup,
	|	ListOfDiscounts.Managed AS Managed
	|INTO ListOfDiscounts
	|FROM
	|	(SELECT DISTINCT
	|		Table.DiscountMarkup AS DiscountMarkup,
	|		Table.DiscountMarkup.Managed AS Managed
	|	FROM
	|		InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|				&CurrentDate,
	|				Source = VALUE(Catalog.Warehouses.EmptyRef)
	|				OR &UseSeveralWarehouses
	|		) AS Table
	|	WHERE
	|		Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|) AS ListOfDiscounts
	|";
	
	If UseSeveralWarehouses Then
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", " OR Source = &Warehouse OR Source IN (&WarehouseGroups)");
	Else	
		QueryText = StrReplace(QueryText, "OR &UseSeveralWarehouses", "");
	EndIf;
	
	If UseLoyaltyCards Then
		QueryText = StrReplace(QueryText, ") AS ListOfDiscounts", "");
		QueryText = QueryText + "
		|UNION ALL
		|
		|SELECT
		|	Table.DiscountMarkup,
		|	Table.DiscountMarkup.Managed
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source REFS Catalog.LoyaltyCardKinds) AS Table
		|		INNER JOIN Catalog.LoyaltyCards AS LoyaltyCards
		|		ON (LoyaltyCards.Owner = Table.Source)
		|			AND (LoyaltyCards.Ref = &LoyaltyCard)
		|WHERE
		|	LoyaltyCards.Owner.ValidityStartDate <= &CurrentDate
		|	AND CASE
		|			WHEN LoyaltyCards.Owner.ValidityEndDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE ENDOFPERIOD(LoyaltyCards.Owner.ValidityEndDate, DAY) >= &CurrentDate
		|		END
		|	AND Table.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|";

		QueryText = QueryText + "
		|) AS ListOfDiscounts
		|";
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ListOfDiscounts.DiscountMarkup
	|FROM
	|	ListOfDiscounts AS ListOfDiscounts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ListOfDiscounts.DiscountMarkup
	|FROM
	|	ListOfDiscounts AS ListOfDiscounts
	|WHERE
	|	ListOfDiscounts.Managed
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	DiscountsMarkupsDiscountMarkupConditions.DiscountMarkupCondition AS DiscountMarkupCondition
	|FROM
	|	Catalog.DiscountsMarkups.DiscountMarkupConditions AS DiscountsMarkupsDiscountMarkupConditions
	|		INNER JOIN ListOfDiscounts AS ListOfDiscounts
	|		ON DiscountsMarkupsDiscountMarkupConditions.Ref = ListOfDiscounts.DiscountMarkup
	|WHERE
	|	DiscountsMarkupsDiscountMarkupConditions.DiscountMarkupCondition.DiscountMarkupCondition = &DiscountMarkupCondition
	|";
	
	If UseLoyaltyPrograms And UseLoyaltyCards Then
		QueryText = QueryText + "
		|;
		|
		|SELECT
		|	ISNULL(LoyaltyCards.Owner.LoyaltyProgram.DoNotAccruePointsWhenPayingWithBonuses, FALSE) AS DoNotAccruePointsWhenPayingWithBonuses
		|FROM
		|	Catalog.LoyaltyCards AS LoyaltyCards
		|WHERE
		|	LoyaltyCards.Ref = &LoyaltyCard
		|	AND ISNULL(LoyaltyCards.Owner.LoyaltyProgram.DoNotAccruePointsWhenPayingWithBonuses, FALSE) = TRUE
		|";
	EndIf;
	
	Query = New Query(QueryText);
	
	Query.Parameters.Insert("CurrentDate", Date);
	Query.Parameters.Insert("DiscountMarkupCondition", Enums.DiscountMarkupTerms.ForPaymentForm);
	
	If UseSeveralWarehouses Then
		Query.Parameters.Insert("Warehouse",         Object.Warehouse);
		Query.Parameters.Insert("WarehouseGroups", WarehouseGroups);
	EndIf;
	
	If UseLoyaltyCards Then
		Query.Parameters.Insert("LoyaltyCard", Object.LoyaltyCard);
	EndIf;
	
	Result = Query.ExecuteBatch();
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("DiscountsAssigned",                       False);
	ParametersStructure.Insert("AssignedManagedDiscounts",            False);
	ParametersStructure.Insert("FormOfPaymentAffectsCalculationOfDiscounts",       False);
	ParametersStructure.Insert("PaymentInPointsAffectsScoringOfPoints", False);
	
	ParametersStructure.DiscountsAssigned                 = Not Result[1].IsEmpty();
	ParametersStructure.AssignedManagedDiscounts      = Not Result[2].IsEmpty();
	ParametersStructure.FormOfPaymentAffectsCalculationOfDiscounts = Not Result[3].IsEmpty();
	
	If UseLoyaltyPrograms And UseLoyaltyCards Then
		ParametersStructure.PaymentInPointsAffectsScoringOfPoints = Not Result[4].IsEmpty() And (ValueIsFilled(Object.LoyaltyCard));
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

&AtServer
Procedure SetUpAutomaticMarkUpDiscounts()
	
	ParametersOfDiscountApplication = ParametersForApplyingDiscountsMarkups(Object, Object.Date);
	
	Items.GoodsPercentRateOfAutomaticDiscountMarkup.Visible = ParametersOfDiscountApplication.DiscountsAssigned;
	Items.GoodsDiscountMarkupAmount.Visible   = ParametersOfDiscountApplication.DiscountsAssigned;
	
	Items.GoodsContextMenuOpenInformationAboutDiscounts.Visible = ParametersOfDiscountApplication.DiscountsAssigned;
	
EndProcedure

&AtServer
Function LoyaltyCardReadOnServer(LoyaltyCard)
	
	Result = True;
	
	LoyaltyCardDetails = LoyaltyCardServerCall.GetLoyaltyCardDetails(LoyaltyCard, False);
	If ValueIsFilled(LoyaltyCardDetails.Ref) Then
		
		Object.LoyaltyCard = LoyaltyCard;
		
		If ValueIsFilled(LoyaltyCardDetails.Partner) And LoyaltyCardDetails.Partner <> Object.Partner Then
			Object.Partner = LoyaltyCardDetails.Partner;
		ElsIf Not ValueIsFilled(LoyaltyCardDetails.Partner) Then
			Object.Partner = PredefinedValue("Catalog.Partners.RetailCustomer");
		EndIf;
		
		AnalysisOfPossibilityOfPaymentWithBonusPoints(True);
		
		SetUpAutomaticMarkUpDiscounts();
		
	Else
		Result = False;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure LoyaltyCardIsRead(LoyaltyCard)
	
	If LoyaltyCardReadOnServer(LoyaltyCard) Then
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
		UpdateDashboardData(ThisObject, True = ReadOnly);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AssignAutomaticDiscountsCompletion(ReturnedValue, AdditionalParameters) Export 
	
	If ReturnedValue <> Undefined Then
		
		ManagedDiscounts = ReturnedValue;
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject", True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation", False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", False);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		Items.ShowMessages.Visible = TheStructureOfTheMessages.Messages.Count() > 0;
		
		RecalculateDocumentOnClient();
		
		ShowUserNotification(
			NStr("vi = 'Chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки)';
				|en = 'Discounts (markups)'; fa = 'تخفیف‌ها (افزایش قیمت‌ها)';
				|it = 'Sconti (sovrapprezzo)';
				|pl = 'Rabaty (marże)';
				|tr = 'İndirim (marj)'"),
			,
			NStr("vi = 'Đã tính chiết khấu (phụ thu)';
				|ru = 'Скидки (наценки) рассчитаны';
				|en = 'Discounts (markups) are calculated'; fa = 'Discounts (markups) are calculated';
				|it = 'Sconti (sovrapprezzi) sono calcolati';
				|pl = 'Rabaty (marże) są obliczone';
				|tr = 'İndirim (marj) uygulandı'"),
			PictureLib.Information32);
		
		If TheStructureOfTheMessages.Messages.Count() > 0 
			And TheStructureOfTheMessages.AutomaticallyOpen Then
			
			OpenForm(
				"CommonForm.MessagesOfDiscountsMarkups",
				TheStructureOfTheMessages,
				ThisObject,
				UUID);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenInformationAboutDiscountsCompletion(QuestionResult, AdditionalParameters) Export
	
	Result = QuestionResult;
	
	If Result = DialogReturnCode.No Then
		Return;
	Else
		
		ParametersStructure1 = New Structure;
		ParametersStructure1.Insert("ApplyToObject", True);
		ParametersStructure1.Insert("OnlyPreliminaryCalculation", False);
		ParametersStructure1.Insert("RestoreManagedDiscounts", True);
		ParametersStructure1.Insert("ManagedDiscounts", ManagedDiscounts);
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		Items.ShowMessages.Visible = TheStructureOfTheMessages.Messages.Count() > 0;
		
		RecalculateDocumentOnClient();
		
		If TheStructureOfTheMessages.Messages.Count() > 0 And TheStructureOfTheMessages.AutomaticallyOpen Then
			OpenForm("CommonForm.MessagesOfDiscountsMarkups", TheStructureOfTheMessages, ThisObject, UUID);
		EndIf;
		
	EndIf;
	
	OpenDiscountInformationFragment();
	
EndProcedure

&AtClient
Procedure OpenDiscountInformationFragment()
	
	Var CurrentData;
	
	If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		CalculateDiscountsWithoutApplyingToObject();
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	
	DiscountsMarkupsFillingClient.OpenAppliedDiscountsForm(CurrentData, Object, ThisObject);
	
EndProcedure

&AtClient
Procedure AssignAManualDiscountForSelectedLinesCompletion(AmountOfManualDiscountMarkUp, AdditionalParameters) Export 
	
	AddressInTempStorage = AdditionalParameters.AddressInTempStorage;
	
	If AmountOfManualDiscountMarkUp <> Undefined Then
		
		Modified = True;
		AssignManualDiscountOnServer(AmountOfManualDiscountMarkUp, Items.Goods.SelectedRows, AddressInTempStorage);
		DiscountsMarkupsFillingClient.NotifyAboutEndOfAssignmentOfManualDiscountsMargins(AmountOfManualDiscountMarkUp, Object.Currency);
		
	EndIf;
	
	RecalculateDocumentOnClient();

EndProcedure

&AtServer
Function TheStructureOfTheMessages()
	
	Return DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	
EndFunction

&AtServer
Procedure MessagesReceived(Messages)
	
	DiscountsMarkupsFillingServer.SaveSpentMessages(Object, Messages);
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	Items.ShowMessages.Visible = TheStructureOfTheMessages.Messages.Count() > 0;
	
EndProcedure

&AtServer
Function AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(SelectedLinesOnly)
	
	ParametersStructure = DiscountsMarkupsFillingServer.NewParametersAddressDataForCalculatingManualDiscounts();
	ParametersStructure.TableName = "Goods";
	ParametersStructure.OnlyForSelectedLines = SelectedLinesOnly;
	ParametersStructure.TableNameOfSelectedRows = "Goods";
	Return DiscountsMarkupsFillingServer.AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(
		ThisObject, UUID, ParametersStructure);
	
EndFunction

&AtClient
Procedure OpenFormForAssigningManualDiscounts()
	
	If Not DiscountsMarkupsFillingClient.ItIsPossibleToAssignManualDiscountMarkUp(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Merci';
																										|pl = 'Towary';
																										|tr = 'Ürünler'")) Then
		Return;
	EndIf;
	
	AddressInTempStorage = AddressOfDataForCalculatingManualDiscountsInTemporaryStorage(True);
	
	Notification = New CallbackDescription(
		"AssignAManualDiscountForSelectedLinesCompletion", 
		ThisObject, 
		New Structure("AddressInTempStorage", AddressInTempStorage));
	
	DiscountsMarkupsFillingClient.OpenFormForAssigningManualDiscounts(
		AddressInTempStorage,
		Object.Currency,
		Notification);
	
EndProcedure

&AtServer
Function AddressTablePartGiftCertificates()
	
	Return PutToTempStorage(Object.GiftCertificates.Unload(), UUID);
	
EndFunction

&AtServer
Procedure DownloadTablePartGiftCertificatesFromRepository(AddressInStorage)
	
	Object.GiftCertificates.Load(GetFromTempStorage(AddressInStorage));
	
EndProcedure

&AtServer
Procedure ApplyPaymentWithBonusPoints(AddressInTempStorage)
	
	DeletingPayment = False;
	If AddressInTempStorage <> Undefined Then
		TableOfGoods = GetFromTempStorage(AddressInTempStorage);
	Else
		TableOfGoods = Object.Goods;
		DeletingPayment = True;
	EndIf;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount",
		New Structure("Clear, RecalculateAmountOfManualDiscount_", False, False));
		
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount",
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
		
	RowsToProcess = New Array;
	
	For Each TableRow In TableOfGoods Do
		
		If DeletingPayment Then
			TSRow = TableRow;
			TSRow.AmountOfBonusPointsToDeduction        = 0;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = 0;
		Else
			TSRow = Object.Goods.FindRows(New Structure("ConnectionKey", TableRow.ConnectionKey))[0];
			TSRow.AmountOfBonusPointsToDeduction        = TableRow.AmountOfBonusPointsToDeduction;
			TSRow.AmountOfBonusPointsToDeductionInCurrency = TableRow.AmountOfBonusPointsToDeductionInCurrency;
		EndIf;
		
		RowsToProcess.Add(TSRow);
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	If Not ValueIsFilled(AddressOfAppliedDiscountsInTheTemporaryStorage) Then
		CalculateDiscountsWithoutApplyingToObject();
	EndIf;
	
	AppliedDiscounts = GetFromTempStorage(AddressOfAppliedDiscountsInTheTemporaryStorage);
	DiscountsMarkupsFillingServer.ApplyCalculationResult(Object, AppliedDiscounts);
	
EndProcedure

#EndRegion

#Region QuickGoodsAndQuantityCheckingProcessing

&AtServer
Function AddToCartOnServer(ProductParameters_1, NewLines)
	
	UseWarerooms = UseWarerooms(Object.Warehouse, Object.Date);
	
	ActionStructureExistingString = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureExistingString, Object);
	If ControlProductRange Then
		AddAssortmentCheckToActionStructure(ActionStructureExistingString);
	EndIf;
	
	ActionStructureNewLine = New Structure;
	
	ActionStructureNewLine.Insert("CheckCharacteristicsByOwner");
	ActionStructureNewLine.Insert("CheckFillPackageByOwner");
	
	If UseWarerooms Then
		ActionStructureNewLine.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	ActionStructureNewLine.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	ActionStructureNewLine.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	If ControlProductRange Then
		AddAssortmentCheckToActionStructure(ActionStructureNewLine);
	EndIf;
	
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureNewLine,Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", ActionStructureNewLine);
	
	Filter = New Structure;
	Filter.Insert("ProductsInSet");
	Filter.Insert("ItemVariantOfSet");
	Filter.Insert("Products");
	Filter.Insert("Characteristic");
	Filter.Insert("Package");
	Filter.Insert("Price");
	Filter.Insert("Premise");

	GTINToIndicateOpenedPackage = Undefined;
	NumberOfMissingLines = 0;
	
	RowsToProcess = New Array;
	LinesToAdd = New Array;
	Errors_ = New Map();
	
	For Each RowOfProduct In NewLines Do
		
		If ThisIsMarkedItemWithPartialDisposalLocalization(RowOfProduct.Products)
			And Not SelectMarkingCodesForOpenedConsumerPackagesByFIFOLocalization() Then
			
			Result = OpenedConsumerPackagingUnitsByItemLocalization(RowOfProduct);
			GTINToIndicateOpenedPackage = Result.GTINToIndicateOpenedPackage;
			
			If Not Result.AddToTablePart Then
				NumberOfMissingLines = NumberOfMissingLines + 1;
				Continue;
			EndIf;
			
		EndIf;
		
		If RowOfProduct.Package.IsEmpty() Then
			RowOfProduct.Package = SelectGoodsServerCall.GetStoragePackaging(RowOfProduct.Products);
		EndIf;
		
		If Not ValueIsFilled(RowOfProduct.Price) And ProductParameters_1.ItemsType <> Enums.ItemsTypes.Set Then
			RowOfProduct.Price = GetPriceBySelection(RowOfProduct.Products, RowOfProduct.Characteristic, RowOfProduct.Series, RowOfProduct.Package);
		EndIf;
		
		FillPropertyValues(Filter, RowOfProduct);
		
		SearchResult = Object.Goods.FindRows(Filter);
		
		If SearchResult.Count() = 0 Or RowOfProduct.Error_ <> 0 Then
			
			CurrentRow = Object.Goods.Add();
			
			FillPropertyValues(CurrentRow, ProductParameters_1);
			FillPropertyValues(CurrentRow, RowOfProduct);
			CurrentRow.SetIndex = ?(ValueIsFilled(CurrentRow.ProductsInSet), 1, 0);
			
			Errors_.Insert(CurrentRow, RowOfProduct.Error_);
			
			LinesToAdd.Add(CurrentRow);
			
		Else
			
			CurrentRow = SearchResult[0];
			
			CurrentRow.NumberOfPackages = RowOfProduct.NumberOfPackages + CurrentRow.NumberOfPackages;
			
			RowsToProcess.Add(CurrentRow);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		ActionStructureExistingString,
		Object.Goods);
		
	ActionStructureNewLine.Insert("RecalculateAmountTakingIntoAccountRoundingError",
		New Structure("ErrorsByLines", Errors_));
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		LinesToAdd,
		ActionStructureNewLine,
		Object.Goods);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
	
	If CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	ProcessPermitsForSaleOfGoodsLocalization(ThisObject);
	
	If (NewLines.Count() - NumberOfMissingLines) > 0 Then
		FillInServiceDetailsForProductRange();
		WhenChangingNomenclatureOfQuantityCharacteristicLocalization();
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
	Return GTINToIndicateOpenedPackage;
	
EndFunction

&AtClient
Procedure AddToCart(ProductParameters_1)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	NewLines = New Array;
	
	If RequestQuantity Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Warehouse");
		FormParameters.Insert("Products");
		FormParameters.Insert("Characteristic");
		FormParameters.Insert("PriceKind");
		FormParameters.Insert("Package");
		FormParameters.Insert("Price");
		FormParameters.Insert("Date");
		FormParameters.Insert("Currency");
		FormParameters.Insert("Organization");
		FormParameters.Insert("EditThePrice");
		FormParameters.Insert("EditPriceType");
			
		FillPropertyValues(FormParameters, ProductParameters_1);
		
		FormParameters.Warehouse = Object.Warehouse;
		FormParameters.Date = Object.Date;
		FormParameters.Currency = Object.Currency;
		FormParameters.Organization = Object.Organization;
		FormParameters.EditThePrice = False;
		FormParameters.EditPriceType = False;
		FormParameters.PriceKind = Object.PriceKind;
		
		If ProductParameters_1.ItemsType = PredefinedValue("Enum.ItemsTypes.Set") Then
			NameOfQuantityRequestForm = "Document.CashRegisterReceipt.Form.QuantityRequestSet";
		Else
			NameOfQuantityRequestForm = "Document.CashRegisterReceipt.Form.QuantityRequest";
		EndIf;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("NewLines", NewLines);
		AdditionalParameters.Insert("ProductParameters_1", ProductParameters_1);
		OpenForm(
			NameOfQuantityRequestForm,
			FormParameters,
			ThisObject,
			UUID,,,
			New CallbackDescription("AddToCartAfterSelectingQuantity", ThisObject, AdditionalParameters));
		
	Else
		
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
		
	EndIf;
	
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
	
	GTINToIndicateOpenedPackage = AddToCartOnServer(ProductParameters_1, NewLines);
	If GTINToIndicateOpenedPackage <> Undefined Then
		SearchByBarcodeCompletion(
			New Structure("Count, Barcode", 1, GTINToIndicateOpenedPackage),
			Undefined);
	EndIf;
	
	DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	RecalculateDocumentOnClient();
	
	Modified = True;
	
EndProcedure

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

	TabularPartProducts.GroupBy("RowID, ProductsInSet, ItemVariantOfSet, USAISProducts, Products, Characteristic, Series, Premise, BatchesIndicationStatus, ItemsType, ItemVariantsAreUsed, Package, NumberOfPackages, Count");
	
	AddressInTempStorage = PutToTempStorage(TabularPartProducts, UUID);
	
	Return AddressInTempStorage;
	
EndFunction

&AtServer
Procedure ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, CachedValues)
	
	GoodsTable = GetFromTempStorage(ReturnParameters.Goods);
	
	LinesToDelete              = New Array;
	ModifiedRowsToProcess = New Array;
	AddedRowsForProcessing = New Array;
	
	UseWarerooms = UseWarerooms(Object.Warehouse, Object.Date);
	
	For Each SourceRow In GoodsTable Do
		
		Filter = New Structure;
		Filter.Insert("ProductsInSet");
		Filter.Insert("ItemVariantOfSet");
		Filter.Insert("Products");
		Filter.Insert("Characteristic");
		Filter.Insert("Series");
		Filter.Insert("ItemVariantsAreUsed");
		Filter.Insert("Package");

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
					TSRow.NumberOfPackages = 0;
				Else
					SourceRow.NumberOfPackages = 0;
					TSRow.NumberOfPackages = QuantityPerLine - QuantityToWriteOff;
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
			
			If TSRow.Package.IsEmpty() Then
				TSRow.Package = SelectGoodsServerCall.GetStoragePackaging(TSRow.Products);
			EndIf;
			
			AddedRowsForProcessing.Add(TSRow);
			
		EndIf;
		
	EndDo;
	
	StructureOfActions = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRowsToProcess,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	StructureOfActions = StructureOfActionsWhenChangingNomenclatureOfTabularItems();
	AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions, Object);

	BatchProcessingOfTablePartServer.ProcessTSStrings(
		AddedRowsForProcessing,
		StructureOfActions,
		Object.Goods,
		CachedValues);
	
	For Each TSRow In LinesToDelete Do
		Object.Goods.Delete(TSRow);
	EndDo;

	ProductsServer.FillInStatusesForSpecifyingSeries(Object,SeriesSpecificationParameters);
	
	FillInServiceDetailsForProductRange();
	WhenChangingNomenclatureOfQuantityCharacteristicLocalization();
	FormEvents.WhenChangingElement(ThisObject, "QuantityVerificationCompleted", ReturnParameters);
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ProcessBarcodes(BarcodeData_5, LoadingFromPDT = False, UnknownBarcodes = False)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	ChangeQuantity = Not ReadOnly;
	
	StructureOfActionsWithAddedStrings = New Structure;
	If ControlProductRange Then
		StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	ElsIf UsePriceManagementSystem25 Then 
		StructureOfActionsWithAddedStrings.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
	Else
		StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	If UseWarerooms(Object.Warehouse, Object.Date) Then
		StructureOfActionsWithAddedStrings.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
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
	StructureOfActions.ChangeQuantity                     = ChangeQuantity
																And Not UnknownBarcodes;
	StructureOfActions.CalculateSets                     = True;
	StructureOfActions.LabelledWHProducts                = True;
	StructureOfActions.WHBarcodes                           = True;
	StructureOfActions.LoadingFromPDT                          = LoadingFromPDT;
	
	If ControlProductRange Then
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
		
		StructureOfActions.AssortmentVerificationParameters = AssortmentInspectionStructure;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	DataForProcessing = StructureOfActions;
	Attachable_AfterProcessingBarcodes();
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject, Object, StructureOfActionParameters, CachedValues);
	
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
Procedure StartConnectingDevicesWhenYouOpenFormCompletion(Result, Var_Parameters) Export
	
	CheckItemPricesLocalization();
	
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
	
	If ShowForPaymentOnACustomerDisplay Then
	
		PaymentInformation = PaymentInformation(ThisObject);
		Dptext1 = RetailSalesClient.PrepareLineForDisplay(
			NStr("vi = 'Cần thanh toán:';
				|ru = 'К оплате:';
				|en = 'Amount due:'; fa = 'Amount due:';
				|it = 'Da pagare:';
				|pl = 'Do płatności:';
				|tr = 'Ödenecek:'"), PaymentInformation.AmountToPay);
		Dptext2 = "";
		
	Else
		
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
		
	EndIf;
	
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
	
	If AdditionalParameters.StandardProcessing Then
		BarcodeData_5 = New Array;
		BarcodeData_5.Add(BarcodeData_1);
		ProcessBarcodes(BarcodeData_5);
	EndIf;
	
	If CommonClientServer.HasAttributeOrObjectProperty(AdditionalParameters, "BarcodeProcessingResult") Then
		ActivateLineWithPosition(AdditionalParameters.BarcodeProcessingResult);
	EndIf;
	
	ProcessingOfTabularFormsClient.CacheCurLine(Items.Goods, ThisObject);
	
	If Not AdditionalParameters.StandardProcessing 
		And AdditionalParameters.BarcodeProcessingResult.OpenFormForEnteringMarkingCode = False
		And ValueIsFilled(DataForProcessing()) Then
		Attachable_AfterProcessingBarcodes();
	Else
		RecalculateDocumentOnClient();
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivateLineWithPosition(Val ProcessingResult)
	
	If ProcessingResult.BarcodeData_1 = Undefined Then
		Return;
	EndIf;

	Filter = New Structure;
	Filter.Insert("Products", ProcessingResult.BarcodeData_1.Products);
	Filter.Insert("Barcode", ProcessingResult.BarcodeData_1.Barcode);
	
	RowsArray = Object.Goods.FindRows(Filter);
	If RowsArray.Count() > 0 Then
		Items.Goods.CurrentRow = RowsArray[0].GetID();
	EndIf;
	
	If RowsArray.Count() = 0 Then
		Filter.Delete("Barcode");
		
		RowsArray = Object.Goods.FindRows(Filter);
		If RowsArray.Count() > 0 Then
			Items.Goods.CurrentRow = RowsArray[0].GetID();
		EndIf;
	EndIf;

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
	ProcessPermitsForSaleOfGoodsLocalization(ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_OpenDataClarificationForm()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataForProcessing", DataForProcessing());
	
	FormEventsClient.WhenChangingElement(ThisObject, "Attachable_OpenDataClarificationForm", AdditionalParameters);
	
EndProcedure

&AtClient
Procedure Attachable_AfterProcessingBarcodes()
	
	ChangeQuantity = Not ReadOnly;
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(DataForProcessing(),CachedValues,ThisObject);
	
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
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
	EndIf;
	
	If DataForProcessing().CurrentRow <> Undefined Then  
		Items.Goods.CurrentRow = DataForProcessing().CurrentRow;
	EndIf;
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure ProcessTSStrings(AddedRows, ModifiedRows, CachedValues = Undefined) Export
	
	FillInFeatureAttribute      = New Structure("Products", "ItemVariantsAreUsed");
	FillInProductTypeAttribute_                 = New Structure("Products", "ItemsType");
	
	ArraysForDifferentBatchProcessingOfStrings = SplitArrayOfStringsForDifferentTypesOfBatchProcessing(AddedRows);
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	If UseWarerooms(Object.Warehouse, Object.Date) Then
		StructureOfActionsWithAddedStrings.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute",
		FillInFeatureAttribute);
		
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	AddActionsToStructureWhenChangingNumberOfUnits(StructureOfActionsWithAddedStrings, Object);
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActionsWithAddedStrings);

	ActionStructureRounding = New Structure;
	AddActionsToStructureWhenChangingPackagesNumber(ActionStructureRounding, Object);
	
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
		ElsIf UsePriceManagementSystem25 Then 
			StructureOfActionsWithAddedStrings.Insert("FillInRetailSalesTermsAndConditions",
				BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(
					Object, ObjectForStoringSalesTermsAndConditions));
		Else
			StructureOfActionsWithAddedStrings.Insert("FillInSalePrice",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			ArraysForDifferentBatchProcessingOfStrings.ItIsRequiredToFillInPrice,
			StructureOfActionsWithAddedStrings,
			Object.Goods);
	EndIf;
	
	LinesWithRounding = New Array();

	For Each TSRow In AddedRows Do
		If TSRow.NumberOfPackages > TSRow.Count And TSRow.NumberOfPackages <> Round(TSRow.NumberOfPackages) Then
			PackagingFactor = (TSRow.NumberOfPackages / TSRow.Count);
			If Round(Round(TSRow.NumberOfPackages) / PackagingFactor, 3) = TSRow.Count Then
				TSRow.NumberOfPackages = Round(TSRow.NumberOfPackages);
					LinesWithRounding.Add(TSRow);
			EndIf;
		EndIf;
	EndDo;
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsToStructureWhenChangingNumberOfUnits(StructureOfActionsWithModifiedStrings, Object);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ModifiedRows,
		StructureOfActionsWithModifiedStrings,
		Object.Goods);
			
	For Each TSRow In ModifiedRows Do
		If TSRow.NumberOfPackages > TSRow.Count And TSRow.NumberOfPackages <> Round(TSRow.NumberOfPackages) Then
			PackagingFactor = (TSRow.NumberOfPackages / TSRow.Count);
			If Round(Round(TSRow.NumberOfPackages) / PackagingFactor, 3) = TSRow.Count Then
				TSRow.NumberOfPackages = Round(TSRow.NumberOfPackages);
					LinesWithRounding.Add(TSRow);
			EndIf;
		EndIf;
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		LinesWithRounding,
		ActionStructureRounding,
		Object.Goods);
	
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

// Returns:
//	Structure -
//
&AtServer
Function AfterProcessingBarcodes(AdditionalParameters)
	
	BarcodeProcessingResult = AdditionalParameters.BarcodeProcessingResult;
	CachedValues        = AdditionalParameters.CachedValues;
	
	If CachedValues = Undefined Then
		CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	EndIf;
	
	If CachedValues.ProductBarcodeRegistrationRightIsAvailable = Undefined Then
		RightOfRegistration = BarcodingOfItemsServer.ProductBarcodeRegistrationRightIsAvailable();
		CachedValues.ProductBarcodeRegistrationRightIsAvailable = RightOfRegistration;
	EndIf;
	
	If BarcodeProcessingResult.BarcodeProcessingRequired Then
		
		LoadingFromPDT = False;
		
		If TypeOf(BarcodeProcessingResult.RawData) = Type("Structure") Then
			BarcodeData_5 = New Array;
			BarcodeData_5.Add(BarcodeProcessingResult.RawData);
		Else
			BarcodeData_5 = BarcodeProcessingResult.RawData;
		EndIf;

		ChangeQuantity = Not ReadOnly;
		
		StructureOfActionsWithAddedStrings = New Structure;
		If ControlProductRange Then
			StructureOfActionsWithAddedStrings.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		ElsIf UsePriceManagementSystem25 Then 
			StructureOfActionsWithAddedStrings.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
		Else
			StructureOfActionsWithAddedStrings.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
		StructureOfActionsWithAddedStrings.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
		
		If UseWarerooms(Object.Warehouse, Object.Date) Then
			StructureOfActionsWithAddedStrings.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
		EndIf;
		
		StructureOfActionsWithAddedStrings.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithAddedStrings, Object);
		BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActionsWithAddedStrings);

		StructureOfActionsWithModifiedStrings = New Structure;
		
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActionsWithModifiedStrings,Object);
		
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
		
		If ControlProductRange Then
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
			
			DataForProcessing.AssortmentVerificationParameters = AssortmentInspectionStructure;
		EndIf;
		
		ProcessBarcodesServer(DataForProcessing, CachedValues);
		
	Else
		
		ProcessAdditionOfLinesWithOpenedConsumerPackagesLocalization(
			BarcodeProcessingResult.AddedRows,
			BarcodeProcessingResult.ModifiedRows);
		
		ProcessTSStrings(
			BarcodeProcessingResult.AddedRows,
			BarcodeProcessingResult.ModifiedRows,
			CachedValues);
		
	EndIf;
	
	FillInServiceDetailsForProductRange();
	
	Return BarcodeProcessingResult;
	
EndFunction

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods, True);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure GetWeightCompletion(ExecutionResult, CurrentRow) Export
	
	If ExecutionResult.Result Then
		CurrentRow.NumberOfPackages = ExecutionResult.Weight;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingPackagesNumber(StructureOfActions,Object);
		
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		
		RecalculateDocumentOnClient();
	Else
		EquipmentManagerTMClient.ReportError(ExecutionResult);
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
	Items.GoodsSeries.Visible = SeriesSpecificationParameters.UseCostAccountingByBatches;
	Items.ProductsSeriesOptional.Visible = SeriesSpecificationParameters.UseCostAccountingByBatches;
	
	Items.SpecifySeries.Visible = SeriesSpecificationParameters.UseItemsBatch;
	
EndProcedure

&AtServer
Procedure FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(IDCurrentRow, CachedValues)
	
	ProductsServer.FillInStatusesOfSpecifyingSeriesWhenEditingLineTS(
		Object, 
		SeriesSpecificationParameters, 
		IDCurrentRow, 
		CachedValues);
	
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
	EndIf;
	
	If AdditionalParameters.Property("NotificationOnCompletion") Then
		RunCallback(AdditionalParameters.NotificationOnCompletion);
	EndIf;
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(Object, SeriesSpecificationParameters, CurDataId, ThisObject);
	
EndFunction

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm)
	
	ProductsServer.ProcessSeriesIndication_(Object, SeriesSpecificationParameters, ParametersOfSeriesIndicationForm);
	FormEvents.WhenChangingElement(ThisObject, "SetOfSeries");
	
EndProcedure

#EndRegion

//
#Region ReceiptProcessingCommands

&AtServer
Function ReserveOnServer(RetryRecordingIsRequired, DocumentStatus, BeforeClose = False)
	
	ReservationCompleted = True;
	
	OldStatusValue = Object.Status;
	OldValueReceivedInCash = Object.ReceivedInCash;
	
	Object.Status = Enums.CashRegisterReceiptStatuses[DocumentStatus];
	If BeforeClose Then
		Object.ReceivedInCash = 0;
	EndIf;
	
	If UseDiscountsMarkupsInSales 
		And ParametersOfDiscountApplication.DiscountsAssigned
		And Not BeforeClose Then
		
		CancelDiscountsMarginsOnServer();
		
	EndIf;
	
	ReservationCompleted = WriteAtServer(RetryRecordingIsRequired);
	
	If Not ReservationCompleted Then 
		Object.Status = OldStatusValue;
		Object.ReceivedInCash = OldValueReceivedInCash;
	EndIf;
	
	Return ReservationCompleted;
	
EndFunction

&AtClient
Procedure ReserveOnClient(ResultDeferredUntil, AdditionalParameters) Export
	
	If Not ValueIsFilled(ResultDeferredUntil) Then
		Return;
	ElsIf ResultDeferredUntil < Object.Date Then
		WarningText = NStr("vi = 'Ngày dự phòng không được ít hơn ngày kiểm tra %ReceiptDate_%';
							|ru = 'Дата резерва должна быть не меньше даты чека %ReceiptDate_%';
							|en = 'Reserve date should be at least the date of receipt %ReceiptDate_%'; fa = 'Reserve date should be at least the date of receipt %ReceiptDate_%';
							|it = 'La data della riserva non deve essere antecedente alla data dello scontrino %ReceiptDate_%';
							|pl = 'Data rezerwy powinna być nie mniejsza niż data paragonu %ReceiptDate_%';
							|tr = 'Rezervasyon tarihi %ReceiptDate_%makbuz tarihinden daha önce olmamalıdır '");
		WarningText = StrReplace(WarningText, "%ReceiptDate_%", Object.Date);
		ShowMessageBox(, WarningText);
		Return;
	EndIf;
	
	Object.DeferredUntil = ResultDeferredUntil;
	
	RetryRecordingIsRequired = False;
	DocumentStatus = "DeferredWithReservation";
	Result = ReserveOnServer(RetryRecordingIsRequired, DocumentStatus, True);
	
	If Not Result Then
		
		AdditionalParametersRepeatRecording = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersRepeatRecording.CallbackDescription         = AdditionalParameters.NotificationOnCompletion;
		AdditionalParametersRepeatRecording.MessageText             = NStr("vi = 'Sau khi hoàn thành thao tác thanh toán hủy, Chứng từ không thể được ghi.';
																			|ru = 'После выполнения операции отмены оплаты не удалось записать документ.';
																			|en = 'Cannot save the document after payment cancellation transaction has been executed.'; fa = 'Cannot save the document after payment cancellation transaction has been executed.';
																			|it = 'Dopo aver annullato il pagamento non è stato possibile registrare il documento.';
																			|pl = 'Po wykonaniu operacji odwołania płatności nie udało się zapisać dokumentu.';
																			|tr = 'Bir ödeme iptal işlemi gerçekleştirildikten sonra belge kaydedilemedi.'");
		AdditionalParametersRepeatRecording.ReturnFunctionResult = True;
		AdditionalParametersRepeatRecording.ProcedureName               = "ReserveOnServer";
		AdditionalParametersRepeatRecording.OperationResult          = Result;
		
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
		
		RunCallback(AdditionalParameters.NotificationOnCompletion, Result);
		
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
		
	EndIf;
	
EndProcedure

&AtServer
Function PostponeOnServer(RetryRecordingIsRequired)
	
	PostponeCompleted = True;
	
	OldStatus = Object.Status;
	Object.Status = Enums.CashRegisterReceiptStatuses.DeferredWithoutReservation;
	
	If UseDiscountsMarkupsInSales 
		And ParametersOfDiscountApplication.DiscountsAssigned
		And SBPAmountHasBeenCompleted = 0 
		And SBPAmountPending = 0 Then
		
		CancelDiscountsMarginsOnServer();
		
	EndIf;
	
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
	
	Object.DeferredUntil = Date(1,1,1);
	Modified = True;
	
	RetryRecordingIsRequired = False;
	Result = PostponeOnServer(RetryRecordingIsRequired);
	
	If Not Result Then
		
		AdditionalParametersAttempt = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersAttempt.CallbackDescription         = NotificationOnCompletion;
		AdditionalParametersAttempt.MessageText             = NStr("vi = 'Sau khi hoàn thành thao tác thanh toán hủy, Chứng từ không thể được ghi.';
																	|ru = 'После выполнения операции отмены оплаты не удалось записать документ.';
																	|en = 'Cannot save the document after payment cancellation transaction has been executed.'; fa = 'Cannot save the document after payment cancellation transaction has been executed.';
																	|it = 'Dopo aver annullato il pagamento non è stato possibile registrare il documento.';
																	|pl = 'Po wykonaniu operacji odwołania płatności nie udało się zapisać dokumentu.';
																	|tr = 'Bir ödeme iptal işlemi gerçekleştirildikten sonra belge kaydedilemedi.'");
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
		RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
		
	EndIf;
	
EndProcedure

&AtServer
Function PerformPartOfCalculationOnServer(ReturnValueManagedDiscounts, RetryRecordingIsRequired)

	Result = True;
	TheStructureOfTheMessages = Undefined;
	
	If Not ControlIsDisabledForTheWarehouse Then
		DocumentStatus = "AmountDue";
		GoodsIsReserved = ReserveOnServer(RetryRecordingIsRequired, DocumentStatus);
		If Not GoodsIsReserved Then
			Result = False;
		EndIf;
		
	EndIf;
	
	If Result
		And UseDiscountsMarkupsInSales
		And ParametersOfDiscountApplication.DiscountsAssigned Then
		
		If ParametersOfDiscountApplication.AssignedManagedDiscounts Then
			
			ManagedDiscounts = ReturnValueManagedDiscounts;
			
			ParametersStructure1 = New Structure;
			ParametersStructure1.Insert("ApplyToObject",                True);
			ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
			ParametersStructure1.Insert("RestoreManagedDiscounts", True);
			ParametersStructure1.Insert("ManagedDiscounts",                ManagedDiscounts);
			
		Else
			
			ParametersStructure1 = New Structure;
			ParametersStructure1.Insert("ApplyToObject",                True);
			ParametersStructure1.Insert("OnlyPreliminaryCalculation",      False);
			ParametersStructure1.Insert("RestoreManagedDiscounts", False);
			ParametersStructure1.Insert("ManagedDiscounts",                Undefined);
			
		EndIf;
		
		TheStructureOfTheMessages = CalculateDiscountsMarginsOnServer(ParametersStructure1);
		
		If ValueIsFilled(Object.Ref) Then
			
			For Each TSRow In Object.Goods Do
				If TSRow.Sum = 0 And TSRow.Price * TSRow.NumberOfPackages > 0  Then
					Common.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Đã tùy chỉnh chiết khấu chưa chính xác. Sau khi tính chiết khấu, số tiền trong dòng %1 bằng 0.';
																						|ru = 'Не корректно настроены скидки (наценки). После расчета скидок (наценок) сумма в строке %1 равна нулю.';
																						|en = 'Discounts (markups) are set up incorrectly. When discounts (markups) are calculated, the amount in line %1 is zero.'; fa = 'Discounts (markups) are set up incorrectly. When discounts (markups) are calculated, the amount in line %1 is zero.';
																						|it = 'Gli sconti (sovrapprezzi)non sono stati configurati correttamente. Dopo aver calcolato gli sconti (sovrapprezzi) la somma nella riga %1è zero.';
																						|pl = 'Rabaty (marże) nie są poprawnie skonfigurowane. Po obliczeniu zniżek (dopłaty) kwota w wierszu %1 wynosi zero.';
																						|tr = 'İndirimler (marjlar) doğru şekilde ayarlanmamıştır. İndirimler (marjları) hesaplandıktan sonra, %1 satırındaki tutar sıfırdır.'"), TSRow.LineNumber), Object.Ref, "Object.Goods");
					Result = False;
				EndIf;
			EndDo;
			
			If Not Result Then
				CancelDiscountsMarginsOnServer();
			EndIf;
			
		EndIf;
		
	EndIf;

	Return New Structure("CalculationCompletedSuccessfully, TheStructureOfTheMessages", Result, TheStructureOfTheMessages);
	
EndFunction

&AtClient
Procedure RecalculateDocumentOnClient()
	
	Items.GoodsReturn.Enabled			= AccessRights.GoodsReturn;
	Items.ReturnOfGoodsWithoutReceipt.Enabled 	= AccessRights.GoodsReturn;
	
	Items.SearchByBarcode.Enabled = True;
	Items.ToReadLoyaltyCard.Enabled = True;
	Items.OpenSelection.Enabled = True;
	Items.CancelPaymentsByPaymentCards.Enabled = True;
	Items.FormQuickGoods.Enabled = True;
	Items.QuickGoods.Enabled = True;
	Items.CalculateDiscounts.Enabled = True;
	
	Items.GroupBottomCommandBarContextCommands.Enabled = True;

	Items.ContextMenuShoppingCartAreaProductsAdd.Enabled    = True;
	Items.ContextMenuShoppingCartAreaProductsCopy.Enabled = True;
	
	Items.Goods.ChangeRowSet    = AccessRights.LineAdjustment;
	
	Items.GoodsNumberOfPackages.ReadOnly = Not AccessRights.LineAdjustment;
	Items.GoodsProducts.ReadOnly       = Not AccessRights.LineAdjustment;
	Items.GoodsBarcode.ReadOnly           = Not AccessRights.LineAdjustment;
	Items.GoodsCharacteristic.ReadOnly     = Not AccessRights.LineAdjustment;
	Items.GoodsSeller.ReadOnly           = Not AccessRights.LineAdjustment;
	
	FormEventsClient.WhenChangingElement(ThisObject, "AccessRights");
	ProcessPermitsForSaleOfGoodsLocalization(ThisObject);
	
	PaymentInformation = PaymentInformation(ThisObject);
	ManagingAvailabilityOfPaymentButtons(ThisObject, PaymentInformation);
	
	RecalculateDocumentOnClientLocalization(PaymentInformation);
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
EndProcedure

&AtServer
Procedure NewReceiptOnServer(Ref = Undefined)
	
	If Ref = Undefined Then
		NewReceipt = Documents.CashRegisterReceipt.CreateDocument();
		NewReceipt.Partner = Catalogs.Partners.RetailCustomer;
		NewReceipt.Filling(New Structure("CashRegister", Object.CashRegister), True);
	Else
		NewReceipt = Ref.GetObject();
	EndIf;
	
	NewReceipt.Date = CurrentSessionDate();
	UnlockFormDataForEdit();
	
	Cashier = ?(ValueIsFilled(Object.Cashier), Object.Cashier, NewReceipt.Cashier);
	
	ValueToFormData(NewReceipt, Object);
	Read();

	If Ref = Undefined Then
		FormEvents.OnReadAtServer(ThisObject, NewReceipt);
	EndIf;
	
	Object.Cashier = Cashier;
	
	ReadOnly = False;
	Modified = False;
	ShowForPaymentOnACustomerDisplay = False;
	SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
	
	WhenCreatingReceipt();
	
EndProcedure

#EndRegion

#Region Payment

&AtClient
Procedure PayInCashHandlingAlerts(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	UpdateTheStateOfRegisterShift();
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("CallbackOnCompletion", New CallbackDescription("PayInCashPaymentCompletion", ThisObject));
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("SelectedPaymentMethod") Then
		CalculationParameters.Insert("SelectedPaymentMethod", AdditionalParameters.SelectedPaymentMethod);
	EndIf;
	CallbackOnCompletion = New CallbackDescription("PerformTheCalculation", ThisObject, CalculationParameters);	
	StartPerformingAdditionalActionsBeforePayingLocalization(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure PayInCashPaymentCompletion(Result, AdditionalParameters) Export
	
	// The selected form of payment or Boolean
	If Result = False Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("OpenCashPaymentForm", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure OpenCashPaymentForm(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	
	// The cash payment command is called from the CWP Form
	AdditionalParametersOfNotification = New Structure("CallFromCWPForm", True);
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.PaymentMethodByCash",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject, AdditionalParametersOfNotification));
	
EndProcedure


&AtClient
Procedure MixedPaymentNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("CallbackOnCompletion", New CallbackDescription("MixedPaymentSettlementCompletion", ThisObject));
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("SelectedPaymentMethod") Then
		CalculationParameters.Insert("SelectedPaymentMethod", AdditionalParameters.SelectedPaymentMethod);
		UpdatePaymentFormData(ThisObject, AdditionalParameters.SelectedPaymentMethod);
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("PerformTheCalculation", ThisObject, CalculationParameters);	
	StartPerformingAdditionalActionsBeforePayingLocalization(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure MixedPaymentSettlementCompletion(Result, AdditionalParameters) Export
	
	// The selected form of payment or Boolean
	If Result = False Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("OpenMixedPaymentForm", ThisObject, Result),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure OpenMixedPaymentForm(ModifiedDataIsRecorded, AvailablePaymentMethods) Export
	
	If Not ModifiedDataIsRecorded = True Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("PaymentInformation",     PaymentInformation(ThisObject));
	FormOpenParameters.Insert("Partner",                Object.Partner);
	FormOpenParameters.Insert("DataTransferAvailable", CashRegisterParameters.DataTransferAvailable);
	If AvailablePaymentMethods <> Undefined Then
		FormOpenParameters.PaymentInformation.AvailablePaymentMethods = AvailablePaymentMethods;
	EndIf;
	
	// The card payment command was called from the RMK form
	AdditionalParametersOfNotification = New Structure("CallFromCWPForm", True); 
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.MixedPaymentForm",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("CompletionOfPayment", ThisObject, AdditionalParametersOfNotification));
	
EndProcedure


&AtClient
Procedure PayByCreditCardProcessingNotifications(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("CallbackOnCompletion", New CallbackDescription("PayWithPaymentCardPaymentCompletion", ThisObject));
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("SelectedPaymentMethod") Then
		CalculationParameters.Insert("SelectedPaymentMethod", AdditionalParameters.SelectedPaymentMethod);
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("PerformTheCalculation", ThisObject, CalculationParameters);	
	StartPerformingAdditionalActionsBeforePayingLocalization(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure PayWithPaymentCardPaymentCompletion(Result, AdditionalParameters) Export
	
	// The selected form of payment or Boolean
	If Result = False Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("AddCardPayment", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure


&AtServer
Procedure AnalysisOfPossibilityOfPaymentWithBonusPoints(ConfigureCWP = False)
	
	Query = New Query;
	Query.Text = "SELECT
	|	LoyaltyCards.Owner.LoyaltyProgram AS LoyaltyProgram
	|FROM
	|	Catalog.LoyaltyCards AS LoyaltyCards
	|WHERE
	|	LoyaltyCards.Ref = &LoyaltyCard";
	
	Query.SetParameter("LoyaltyCard", Object.LoyaltyCard);
	
	BonusProgramIsFull = False;
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		BonusProgramIsFull = ValueIsFilled(Selection.LoyaltyProgram);
	EndIf;
	
	UseLoyaltyPrograms = GetFunctionalOption("UseLoyaltyPrograms") And BonusProgramIsFull;
	
	If ConfigureCWP Then
		ConfigureCWP();
	EndIf;
	
EndProcedure

&AtClient
Procedure PayWithBonusPointsProcessingAlerts(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("AddPaymentWithBonusPoints", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

// Called from the complex payment form
// 
// Parameters:
//  ModifiedDataIsRecorded - Boolean - 
//  CompletionParameters - Structure - advanced setting
//
&AtClient
Procedure AddPaymentWithBonusPoints(ModifiedDataIsRecorded, CompletionParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	If CompletionParameters <> Undefined Then
		Object.ReceivedInCash = CompletionParameters.ReceivedInCash;
	EndIf;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("Partner",                   Object.Partner);
	FormOpenParameters.Insert("LoyaltyCard",           Object.LoyaltyCard);
	FormOpenParameters.Insert("AddressOfTheTablePartProducts", AddressOfTheTablePartProducts());
	FormOpenParameters.Insert("Currency",                    Object.Currency);
	AddPriceControlParameterForIDCLocalizationToForm(ThisObject, FormOpenParameters);
	
	OpenForm(
		"Catalog.LoyaltyPrograms.Form.PaymentWithBonusPoints",
		FormOpenParameters,
		ThisObject,,,,
		New CallbackDescription("AddPaymentWithBonusPointsCompletion", ThisObject, CompletionParameters));
	
EndProcedure

&AtClient
Procedure AddPaymentWithBonusPointsCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		RetailSalesClient.UnblockForm(ThisObject);
		ProcessPaymentAddition(AdditionalParameters);
		Return;
	EndIf;
	
	ApplyPaymentWithBonusPoints(Result.AddressInTempStorage);
	
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure


&AtClient
Procedure PayWithGiftCertificateProcessingNotification(Result, AdditionalParameters) Export
	
	If Not Result Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	CalculationParameters = New Structure;
	CalculationParameters.Insert("CallbackOnCompletion", New CallbackDescription("PayWithGiftCertificateCompletionOfPayment", ThisObject));
	
	If AdditionalParameters <> Undefined And AdditionalParameters.Property("SelectedPaymentMethod") Then
		CalculationParameters.Insert("SelectedPaymentMethod", AdditionalParameters.SelectedPaymentMethod);
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("PerformTheCalculation", ThisObject, CalculationParameters);	
	StartPerformingAdditionalActionsBeforePayingLocalization(CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure PayWithGiftCertificateCompletionOfPayment(Result, AdditionalParameters) Export
	
	// The selected form of payment or Boolean
	If Result = False Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	PerformActionAfterRecording(
		New CallbackDescription("AddGiftCertificatePayment", ThisObject),
		NStr("vi = 'Trước khi mở hình thức thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед открытием формы оплаты не удалось записать документ.';
			|en = 'Cannot save the document before opening a payment form.'; fa = 'Cannot save the document before opening a payment form.';
			|it = 'Prima della definizione del metodo di pagamento non è stato possibile registrare il documento.';
			|pl = 'Przed otwarciem formy płatności nie udało się zapisać dokumentu.';
			|tr = 'Ödeme formu açılmadan önce belge kaydedilemedi.'"));
	
EndProcedure

// Called from the complex payment form
// 
// Parameters:
//  ModifiedDataIsRecorded - Boolean - 
//  CompletionParameters - Structure - advanced setting
//
&AtClient
Procedure AddGiftCertificatePayment(ModifiedDataIsRecorded, CompletionParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	If CompletionParameters <> Undefined Then
		Object.ReceivedInCash = CompletionParameters.ReceivedInCash;
	EndIf;
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	PaymentInformation = PaymentInformation(ThisObject);
	AddressOfTableOfProductsForAnalyzingPossibilityOfPayment = GiftCertificatesServerCall.AddressOfProductsTabularPartForAnalyzingPossibilityOfPayingWithGiftCertificates(Object.Ref, UUID);
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("AddressInStorage", AddressTablePartGiftCertificates());
	If ValueIsFilled(AddressOfTableOfProductsForAnalyzingPossibilityOfPayment) Then
		FormOpenParameters.Insert("AddressInStorageGoods", AddressOfTableOfProductsForAnalyzingPossibilityOfPayment);
	EndIf;
	FormOpenParameters.Insert("Currency", Object.Currency);
	FormOpenParameters.Insert("Organization", Object.Organization);
	FormOpenParameters.Insert("PayInAddition", PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_);
	FormOpenParameters.Insert("ShowResultItRemainsToPayExtra", True);
	FormOpenParameters.Insert("RegisterNewOnes", False);
	FormOpenParameters.Insert("Filter", New Structure);
	
	FilterArray = New Array();
	FilterArray.Add(PredefinedValue("Enum.GiftCertificateStatuses.PartiallyRepaid"));
	FilterArray.Add(PredefinedValue("Enum.GiftCertificateStatuses.Activated"));
	
	FormOpenParameters.Filter.Insert("Status", FilterArray);
	FormOpenParameters.Filter.Insert("Organization", Object.Organization);
	FormOpenParameters.Filter.Insert("OperationType", GiftCertificatesClientServer.TypeOfOperationForGiftCertificates(Object));

	FormOpenParameters.Insert("OnCloseNotifyDescription", New CallbackDescription("AddGiftCertificatePaymentCompletion", ThisObject, CompletionParameters));
	
	GiftCertificatesClient.OpenGiftCertificateSelectionForm(ThisObject, FormOpenParameters);
	
EndProcedure

&AtClient
Procedure AddGiftCertificatePaymentCompletion(AddressInStorage, AdditionalParameters) Export
	
	If ValueIsFilled(AddressInStorage) Then
		
		DownloadTablePartGiftCertificatesFromRepository(AddressInStorage);
		
	EndIf;
	
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CompletionOfPayment(PaymentResult, AdditionalParameters) Export

	If PaymentResult <> Undefined And PaymentResult <> "Cancel" Then
		
		Object.ReceivedInCash = PaymentResult.ReceivedInCash;
		Object.Partner           = PaymentResult.ElectronicReceiptData.Partner;
		
		FiscalOperationData.OptionOfSendingElectronicReceipt  = PaymentResult.ElectronicReceiptData.OptionOfSendingElectronicReceipt;
		FiscalOperationData.ContactDetailsOfElectronicReceipt = PaymentResult.ElectronicReceiptData.ContactDetailsOfElectronicReceipt;
		
	ElsIf PaymentResult = "Cancel" Then
		
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
		
	ElsIf TypeOf(AdditionalParameters) = Type("Structure")
		And AdditionalParameters.Property("Exit") 
		And AdditionalParameters.Exit = True Then
		
		ForcedShutdown = True;
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
		
	EndIf;
	
	UpdatePaymentFormData(ThisObject, PaymentInformation(ThisObject));
	ProcessPaymentAddition(AdditionalParameters);
	
EndProcedure

#Region PaymentServiceFees

&AtClientAtServerNoContext
Function PaymentInformation(Form)
	
	Form.DocumentAmount = PriceManagementSystemClientServer.GetDocumentAmount(Form.Object.Goods, Form.Object.PriceIncludesVAT);
	
	DiscountAmount = Form.Object.Goods.Total("ManualDiscount")
	            + Form.Object.Goods.Total("DiscountMarkupAmount");
	DiscountAmountBonusPoints = Form.Object.Goods.Total("AmountOfBonusPointsToDeductionInCurrency");
	
	If Form.Object.PriceIncludesVAT Then
		AmountWithoutADiscount = Form.DocumentAmount + DiscountAmount + DiscountAmountBonusPoints;
	Else
		AmountWithoutADiscount = Form.DocumentAmount - Form.Object.Goods.Total("VATAmount") + DiscountAmount + DiscountAmountBonusPoints;
	EndIf;
	
	AmountToPay = AmountWithoutADiscount - DiscountAmount;
	
	PaymentInformation = New Structure;
	PaymentInformation.Insert("Document",              Form.Object.Ref); // - DocumentRef.CashRegisterReceipt
	
	PaymentInformation.Insert("CashPayment",              Form.Object.ReceivedInCash);
	PaymentInformation.Insert("PaymentCards",        RetailSalesClientServer.AmountOfPaymentByPaymentCards(Form.Object.PaymentWithPaymentCards));
	PaymentInformation.Insert("GiftCertificates", Form.Object.GiftCertificates.Total("Sum"));
	PaymentInformation.Insert("BonusPoints",         DiscountAmountBonusPoints);
	
	PaymentInformation.Insert("DocumentAmount",        Form.DocumentAmount);
	PaymentInformation.Insert("AmountWithoutADiscount",        AmountWithoutADiscount);
	PaymentInformation.Insert("AmountToPay",          AmountToPay);
	PaymentInformation.Insert("DiscountAmount",           DiscountAmount);
	
	PaymentInformation.Insert("AvailablePaymentMethods",   RetailSalesClientServer.AvailablePaymentMethods(Form));
	
	Form.TotalAmountPaid = PaymentInformation.CashPayment
		+ PaymentInformation.PaymentCards
		+ PaymentInformation.GiftCertificates
		+ PaymentInformation.BonusPoints;
	PaymentInformation.Insert("TotalPaid_", Form.TotalAmountPaid);
	
	PaymentInformationLocalization(Form, PaymentInformation);
	
	Return PaymentInformation;
	
EndFunction

#Region PaymentWithPaymentCards

// Called from the complex payment form
&AtClient
Procedure AddCardPayment(ModifiedDataIsRecorded, CompletionParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	If CompletionParameters <> Undefined Then
		Object.ReceivedInCash = CompletionParameters.ReceivedInCash;
	EndIf;
	
	ShowForPaymentOnACustomerDisplay = True;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	PaymentInformation = PaymentInformation(ThisObject);
	
    TheAmountOfTheSurcharge = PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_;
	If TheAmountOfTheSurcharge <= 0 Then
		CommonClient.MessageToUser(NStr("vi = 'Phiếu tính tiền đã thanh toán';
										|ru = 'Чек оплачен';
										|en = 'The Receipt is paid'; fa = 'The Receipt is paid';
										|it = 'Scontrino pagato';
										|pl = 'Paragon został opłacony';
										|tr = 'Ödenen makbuz'"));
		RetailSalesClient.UnblockForm(ThisObject);
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CallbackOnCompletion", New CallbackDescription("AddCardPaymentCompletion", ThisObject, CompletionParameters));
	
	AdditionalParameters.Insert("Form",                  ThisObject);
	AdditionalParameters.Insert("DocumentBasis",      Object.Ref);
	AdditionalParameters.Insert("POSTerminals", POSTerminals);
	AdditionalParameters.Insert("CashRegisterParameters",      CashRegisterParameters);
	AdditionalParameters.Insert("AuthorizationForm_Amount",       PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_);
	AdditionalParameters.Insert("AuthorizationForm_AmountLimit", PaymentInformation.AmountToPay - PaymentInformation.TotalPaid_); // + Information about the payment.Cash);
	AdditionalParameters.Insert("Currency",                       Object.Currency);
	AdditionalParameters.Insert("StructureAcquiringTerminal");
	AdditionalParameters.Insert("IDOfETDevice");
	
	PerformActionAfterRecording(
		New CallbackDescription("AddCardPayment", RetailSalesClient, AdditionalParameters),
		NStr("vi = 'Trước khi thanh toán bằng thẻ thanh toán, không thể ghi chứng từ.';
			|ru = 'Перед оплатой платежной картой не удалось записать документ.';
			|en = 'Cannot save the document before paying by payment card.'; fa = 'Cannot save the document before paying by payment card.';
			|it = 'Prima del pagamento tramite carta non è stato possibile registrare il documento.';
			|pl = 'Przed płatnością kartą płatniczą nie udało się zapisać dokumentu.';
			|tr = 'Ödeme kartı ile ödeme yapmadan önce belge kaydedilemedi.'"));
	
EndProcedure

&AtClient
Procedure AddCardPaymentCompletion(Result, AdditionalParameters) Export
	
	If Not ValueIsFilled(Result) Then
		ProcessPaymentAddition(AdditionalParameters);
		Return;
	EndIf;
	
	// Save card payment data in the table
	CardPaymentLine = Object.PaymentWithPaymentCards.Add();
	
	CardPaymentLine.PaymentKind_			 = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard");
	CardPaymentLine.POSTerminal = Result.POSTerminal;
	CardPaymentLine.PaymentCardNumber   = Result.CardNumber; // It is possible to record an empty card number or a type number "****************"
	CardPaymentLine.Sum                 = Result.TransactionAmount;
	CardPaymentLine.ReferenceNumber        = Result.ReferenceNumber;
	CardPaymentLine.POSTerminalReceiptNumber           = Result.ReceiptNumber;
	CardPaymentLine.AuthorizationCode        = Result.AuthorizationCode;
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  Result.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", Result.ReferenceNumber);
	DataForEventLog.Insert("CardNumber",     Result.CardNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    Result.ReceiptNumber);
	DataForEventLog.Insert("AuthorizationCode", Result.AuthorizationCode);
	
	Modified = True;
	
	RecalculateDocumentOnClient();
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParametersCompletion = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersCompletion.CallbackDescription             = New CallbackDescription("AddCardPaymentEntryCompletion", ThisObject, AdditionalParameters);
		AdditionalParametersCompletion.MessageText                 = NStr("vi = 'Sau khi thanh toán bằng thẻ thanh toán, Chứng từ không thể được lưu.';
																			|ru = 'После проведения оплаты платежной картой не удалось сохранить документ.';
																			|en = 'Cannot save the document after payment by payment card.'; fa = 'Cannot save the document after payment by payment card.';
																			|it = 'Dopo l''esecuzione del pagamento tramite carta non è stato possibile salvare il documento.';
																			|pl = 'Po zaksięgowaniu płatności kartą płatniczą nie udało się zapisać dokumentu.';
																			|tr = 'Ödeme kartı ile ödeme yapıldıktan sonra belge kaydedilemedi.'");
		AdditionalParametersCompletion.ReturnFunctionResult     = False;
		AdditionalParametersCompletion.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True);
		AdditionalParametersCompletion.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False);
		AdditionalParametersCompletion.ProcedureName                   = "WriteAtServer";
		AdditionalParametersCompletion.OperationResult              = ModifiedDataIsRecorded;
		
		If Not RetryRecordingIsRequired Then
			ErrorDuringReceiptIssueCompletion(DialogReturnCode.Cancel, AdditionalParametersCompletion);
			Return;
		EndIf;
	
		ShowQueryBox(
			New CallbackDescription("ErrorDuringReceiptIssueCompletion", ThisObject, AdditionalParametersCompletion),
			AdditionalParametersCompletion.MessageText,
			QuestionDialogMode.RetryCancel, 10, DialogReturnCode.Retry,,DialogReturnCode.Retry);
		Return;
		
	Else
		
		ProcessPaymentAddition(AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AddCardPaymentEntryCompletion(Result, AdditionalParameters) Export
	
	ProcessPaymentAddition(AdditionalParameters);
	
	If Result.OperationPerformedOnDevice And Not Result.ModifiedDataIsRecorded Then
		
		FormParameters = New Structure;
		FormParameters.Insert("Data", Object.Ref);
		FormParameters.Insert("DataForEventLog", DataForEventLog);
		FormParameters.Insert("MessageText",
			NStr("vi = 'CHÚ Ý! Đã xảy ra tình huống đặc biệt:
			|Đã thực hiện thanh toán, nhưng chưa được ghi nhận trong hệ thống.';
			|ru = 'ВНИМАНИЕ! Произошла исключительная ситуация:
			|Оплата произведена, но не зафиксирована в системе.';
			|en = 'WARNING! An exception is thrown. 
			|The payment is made but it was not recorded in the application.'; fa = 'WARNING! An exception is thrown. 
			|The payment is made but it was not recorded in the application.';
			|it = 'ATTENZIONE! si è verificata una situazione eccezionale: 
			|il pagamento è stato effettuato, ma non è stato registrato nel sistema.';
			|pl = 'UWAGA! Wystąpiła sytuacja wyjątkowa:
			|Płatność wykonana, ale nie została zarejestrowana w systemie.';
			|tr = 'UYARI! İstisnai bir durum meydana geldi:
			| Ödeme yapıldı ancak sisteme kaydedilmedi.'"));
		
		OpenForm("Document.CashRegisterReceipt.Form.WritingError", FormParameters, ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessPaymentAddition(AdditionalParameters)
	
	ShowForPaymentOnACustomerDisplay = False;
	AttachIdleHandler("DisplayInformationOnBuyerSDisplay", 0.1, True);
	
	PaymentInformation = PaymentInformation(ThisObject);
	
	// The card payment command was called from the RMK form
	If AdditionalParameters = Undefined 
		Or TypeOf(AdditionalParameters) = Type("Structure") 
			And AdditionalParameters.Property("CallFromCWPForm")
			And AdditionalParameters.CallFromCWPForm = True Then
		
		If Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.ReceiptIsIssued_") Then
			
			ShowForPaymentOnACustomerDisplay = True;
			
			UpdateDashboardData(ThisObject, True);
			RetailSalesClient.UnblockForm(ThisObject);
			
		Else
			
			If PaymentInformation.TotalPaid_ >= PaymentInformation.AmountToPay
				And ValueIsFilled(FiscalOperationData.OptionOfSendingElectronicReceipt) Then
				
				ShowForPaymentOnACustomerDisplay = True;
				
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
					
			ElsIf RequiredToPostponeReceiptWhenAddingPaymentLocalization(PaymentInformation) Then
				
				DeferOnClient(Undefined);
				ConfigureCWP();
				
			Else
				
				RetailSalesClient.UnblockForm(ThisObject);
				
			EndIf;
			
		EndIf;
		
	Else
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation);
	EndIf;
	
EndProcedure

#EndRegion

#Region CancellationOfPaymentByPaymentCards

&AtClient
Procedure CancelPaymentsByPaymentCards(Result, AdditionalParameters) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInStorage", PlaceTabularPartOfPaymentByPaymentCardsInVault());
	
	If AdditionalParameters.Property("ReceivedInCash") Then
		Object.ReceivedInCash = AdditionalParameters.ReceivedInCash;
	EndIf;

	AdditionalParameters.Insert("ShowCancelPaymentsButtonSequentially", False);
	AdditionalParameters.Insert("ShowOnlyPaymentsWithPaymentCards", True);
	AdditionalParameters.Insert("DocumentAmount", DocumentAmount);

	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	
	OpenForm(
		"Document.CashRegisterReceipt.Form.TabularFormPaymentWithPaymentCards",
		FormParameters,,,,,
		New CallbackDescription("CancelPaymentByPaymentCardsSelectingPaymentLineCompletion", RetailSalesClient, AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// Parameters:
//  Result - Structure -
// 	AdditionalParameters - Structure:
// 		* Form - ClientApplicationForm:
// 			** Object - FormDataStructure:
// 				*** Ref - DocumentRef.CashRegisterReceipt
//
&AtClient
Procedure CancelPaymentsByPaymentCardsCompletion(Result, AdditionalParameters) Export
	
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
		
	EndIf;
	
	If AdditionalParameters.Property("NotificationToPaymentForm") Then
		RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation(ThisObject));
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
Procedure CancelPaymentByPaymentCards(CallbackOnCompletion)
	
	PaymentLinesWithPaymentCards = New Array;
	For Each PaymentLine_ In Object.PaymentWithPaymentCards Do
		If PaymentLine_.PaymentKind_ = PredefinedValue("Enum.TypesOfCashRegisterPaymentSystem.PaymentCard") Then
			PaymentLinesWithPaymentCards.Add(PaymentLine_);
		EndIf;
	EndDo;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("NotificationOnCompletion",       CallbackOnCompletion);
	AdditionalParameters.Insert("PaymentLinesWithPaymentCards", PaymentLinesWithPaymentCards);
	
	AdditionalParameters.Insert("Form",             ThisObject);
	AdditionalParameters.Insert("Currency",            Object.Currency);
	AdditionalParameters.Insert("CashRegisterParameters", CashRegisterParameters);
	AdditionalParameters.Insert("TransactionType",     "AuthorizeVoid");
	
	RetailSalesClient.CancelPaymentByCreditCardsSequentially(
		Undefined,
		AdditionalParameters);
	
EndProcedure

&AtClient
Procedure CancelPaymentByCreditCardCompletion(Result, AdditionalParameters) Export
	
	DataForEventLog = New Structure;
	DataForEventLog.Insert("TransactionAmount",  AdditionalParameters.TransactionAmount);
	DataForEventLog.Insert("ReferenceNumber", AdditionalParameters.ReferenceNumber);
	DataForEventLog.Insert("POSTerminalReceiptNumber",    AdditionalParameters.ReceiptNumber);
	
	Object.PaymentWithPaymentCards.Delete(Object.PaymentWithPaymentCards.IndexOf(AdditionalParameters.PaymentLine_));
	Modified = True;
	
	RecalculateDocumentOnClient();
	
	RetryRecordingIsRequired = False;
	ModifiedDataIsRecorded = WriteAtClient(RetryRecordingIsRequired);
	If Not ModifiedDataIsRecorded Then
		
		AdditionalParametersRepeatRecording = RetailSalesClientServer.RecordingRepeatStructure();
		AdditionalParametersRepeatRecording.CallbackDescription             = AdditionalParameters.NotificationOnCompletion;
		AdditionalParametersRepeatRecording.MessageText                 = NStr("vi = 'Sau khi hoàn thành thao tác thanh toán hủy, Chứng từ không thể được ghi.';
																				|ru = 'После выполнения операции отмены оплаты не удалось записать документ.';
																				|en = 'Cannot save the document after payment cancellation transaction has been executed.'; fa = 'Cannot save the document after payment cancellation transaction has been executed.';
																				|it = 'Dopo aver annullato il pagamento non è stato possibile registrare il documento.';
																				|pl = 'Po wykonaniu operacji odwołania płatności nie udało się zapisać dokumentu.';
																				|tr = 'Bir ödeme iptal işlemi gerçekleştirildikten sonra belge kaydedilemedi.'");
		AdditionalParametersRepeatRecording.ReturnFunctionResult     = False;
		AdditionalParametersRepeatRecording.ResultOfSuccessfulImplementation = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, True);
		AdditionalParametersRepeatRecording.CancellationResult_             = New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded", True, False);
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
			New Structure("OperationPerformedOnDevice, ModifiedDataIsRecorded",
				True, True));
		
	EndIf;
	
EndProcedure

// Called from the complex payment form
// Parameters:
//  ModifiedDataIsRecorded - Boolean -
//  AdditionalParameters - Structure -
//
&AtClient
Procedure PaymentCancel(ModifiedDataIsRecorded, AdditionalParameters) Export
	
	If Not ModifiedDataIsRecorded = True Then
		Return;
	EndIf;
	
	Object.ReceivedInCash = 0;
	Object.GiftCertificates.Clear();
	
	If Object.DiscountsAreCalculated  And Object.Goods.Count() > 0 Then
		ApplyPaymentWithBonusPoints(Undefined);
	EndIf;
	
	PaymentCancelLocalization(AdditionalParameters);
	
EndProcedure

&AtClient
Procedure PaymentCancelCompletion(Result, AdditionalParameters) Export
	
	PaymentInformation = PaymentInformation(ThisObject);
	If RequiredToPostponeReceiptWhenPaymentCancellationEndingLocalization(PaymentInformation) Then
		DeferOnClient(Undefined);
		ConfigureCWP();
	EndIf;

	RunCallback(AdditionalParameters.NotificationToPaymentForm, PaymentInformation);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region OtherItems

&AtClient
Procedure ErrorDuringReceiptIssueCompletion(Result, AdditionalParameters) Export
	
	If Result <> DialogReturnCode.Cancel Then
		
		RetryRecordingIsRequired = False;
		If AdditionalParameters.ProcedureName = "WriteAtServer" Then
			OperationResult = WriteAtServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "RecordFiscalTransactionOnServer" Then
			OperationResult = RecordFiscalTransactionOnServer(RetryRecordingIsRequired, AdditionalParameters.DetailsOfCashNodeSFiscalOperation);
		ElsIf AdditionalParameters.ProcedureName = "PostponeOnServer" Then
			OperationResult = PostponeOnServer(RetryRecordingIsRequired);
		ElsIf AdditionalParameters.ProcedureName = "ReserveOnServer" Then
			OperationResult = ReserveOnServer(RetryRecordingIsRequired, "DeferredWithReservation");
		ElsIf AdditionalParameters.ProcedureName = "PerformPartOfCalculationOnServer" Then
			OperationResult = PerformPartOfCalculationOnServer(AdditionalParameters.ProcedureParameters, RetryRecordingIsRequired);
		EndIf;
		
		If (TypeOf(OperationResult) = Type("Boolean") And OperationResult)
			Or (TypeOf(OperationResult) = Type("Structure") And OperationResult.Property("CalculationCompletedSuccessfully") And OperationResult.CalculationCompletedSuccessfully) Then
			
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

&AtServer
Function WriteAtServer(RetryRecordingIsRequired = Undefined)
	
	RetailSalesClientServer.SaveDataOfDynamicAttributesOfFormTablesToCache(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		Value = FormAttributeToValue("Object", Type("DocumentObject.CashRegisterReceipt"));
		Value.SetNewObjectRef(Documents.CashRegisterReceipt.GetRef());
		ValueToFormData(Value, Object);
	EndIf;
	
	Object.Date = CurrentSessionDate();
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		LockItem = Block.Add();
		LockItem.Region = "Document.CashRegisterReceipt";
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Ref", Object.Ref);
		Block.Lock();
		
		WriteParameters = New Structure;
		WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
		WriteParameters.Insert("PostingMode", DocumentPostingMode.RealTime);
		WriteParameters.Insert("TransactionMode", True);
		
		Result = Write(WriteParameters);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();

		Template = NStr("vi = 'Không thể ghi phiếu tính tiền do: %1';
						|ru = 'Не удалось записать чек ККМ по причине: %1';
						|en = 'Cannot save the receipt. Reason: %1'; fa = 'Cannot save the receipt. Reason: %1';
						|it = 'Non è stato possibile sregistrare lo scontrino del registratore di cassa a causa di: %1';
						|pl = 'Nie udało się zapisać paragon kasy fiskalnej z powodu: %1';
						|tr = 'Kasa fişi şu nedenle kaydedilemedi: %1'");
		BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
		MessageText = StrTemplate(Template, BriefErrorDescription);
	
		WriteLogEvent(
			NStr("vi = 'Quầy thu ngân';
				|ru = 'РМК';
				|en = 'Point of sale workplace'; fa = 'میز کار نقطه فروش';
				|it = 'Posto del lavoro del cassiere';
				|pl = 'Point of sale workplace';
				|tr = 'Kasiyer çalışma alanı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,
			Metadata.Documents.CashRegisterReceipt,,
			MessageText);
		RetryRecordingIsRequired = True;

		Result = False;
		
	EndTry;
	
	If Not Result Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
		
		FillInServiceDetailsForProductRange();
		RetailSalesClientServer.RecoverDataFromCacheOfDynamicDetailsOfFormTables(ThisObject);
		
	Else
		
		WriteParameters.Insert("TransactionMode", False);
		AfterWriteAtServer(FormAttributeToValue("Object"), WriteParameters);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Function WriteAtClient(RetryRecordingIsRequired = Undefined)
	
	If Modified Then
		
		MeasurementUUID = PerformanceMonitorClient.TimeMeasurement(
			"Document.CashRegisterReceipt.Form.CWPDocumentForm.WriteAtClient",, False);
		
		Result = WriteAtServer(RetryRecordingIsRequired);
		
		PerformanceMonitorClient.StopTimeMeasurement(MeasurementUUID, Not Result);
		If Result Then
			Notify("Write_CashRegisterReceipt", New Structure, Undefined);
		EndIf;
		
		Return Result;
		
	Else
		Return True;
	EndIf;
	
EndFunction

&AtClient
Procedure AlertProcessingChangedCurSessionWorkplace(AdditionalParameters) Export
	
	ForcedShutdown = True;
	
	Close();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsForProductRange()
	
	FillInFeatureAttribute      = New Structure("Products", "ItemVariantsAreUsed");
	FillInProductTypeAttribute_                 = New Structure("Products", "ItemsType");
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",   FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_",              FillInProductTypeAttribute_);
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products_2", StructureOfActions);
	ProductsServer.FillInServiceDetailsForProductInCollection(Object.Goods, StructureOfActions);
	
	FormEvents.WhenChangingElement(ThisObject, "Goods");
	
	SetsServer.FillInServiceDetails(ThisObject);

EndProcedure

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

&AtClientAtServerNoContext
Procedure UpdatePaymentFormData(Form, PaymentInformation)
	
	PaymentForms = PredefinedValue("Enum.PaymentForms.EmptyRef");
	
	CashPayment              = PaymentInformation.CashPayment;
	PaymentCards        = PaymentInformation.PaymentCards;
	GiftCertificates = PaymentInformation.GiftCertificates;
	BonusPoints         = PaymentInformation.BonusPoints;
	
	If CashPayment > 0 And PaymentCards = 0 And GiftCertificates = 0 And BonusPoints = 0 Then
		PaymentForms = PredefinedValue("Enum.PaymentForms.CashAccountPayment_");
	ElsIf CashPayment = 0 And PaymentCards > 0 And GiftCertificates = 0 And BonusPoints = 0 Then
		PaymentForms = PredefinedValue("Enum.PaymentForms.PaymentCard");
	ElsIf CashPayment = 0 And PaymentCards = 0 And GiftCertificates > 0 And BonusPoints = 0 Then
		PaymentForms = PredefinedValue("Enum.PaymentForms.GiftCertificate");
	ElsIf CashPayment = 0 And PaymentCards = 0 And GiftCertificates = 0 And BonusPoints > 0 Then
		PaymentForms = PredefinedValue("Enum.PaymentForms.BonusPoints");
	EndIf;
	
	Form.Object.PaymentMethod = PaymentForms;
	
EndProcedure

&AtServer
Function AddressOfTheTablePartProducts()
	
	Return PutToTempStorage(Object.Goods.Unload(), UUID);
	
EndFunction

&AtClient
Procedure UploadNewReceipt(Ref = Undefined)
	
	RetailSalesClient.ClearMessageWindow(ThisObject);
	
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
		
		NewReceiptOnServer();
		UploadNewReceiptFragment();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadNewReceiptFragment()
	
	AddressOfAppliedDiscountsInTheTemporaryStorage = "";
	ManagedDiscounts = New ValueList;
	
	RecalculateDocumentOnClient();
	
EndProcedure

// Parameters:
//  Result - Boolean, Undefined -
// 	AdditionalParameters - Structure:
// 		* Ref - DocumentRef.CashRegisterReceipt
// 
&AtClient
Procedure UploadNewReceiptCompletion(Result, AdditionalParameters) Export
	
	NewReceiptOnServer(AdditionalParameters.Ref);
	
	UploadNewReceiptFragment();
	
EndProcedure

// Update the dashboard data.
// 
// Parameters:
//  Form - ClientApplicationForm - the form of the document
//  DisplayChange - Boolean - Display Change
&AtClientAtServerNoContext
Procedure UpdateDashboardData(Form, DisplayChange = False)
	
	PaymentInformation = PaymentInformation(Form);
	
	Form.InformationPanelAmountToBePaid   = PaymentInformation.AmountToPay;
	Form.InfoBarAmountWithoutDiscount = PaymentInformation.AmountWithoutADiscount;
	Form.InfoBarDiscountAmount    = PaymentInformation.DiscountAmount;
	
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
		
		AdditionalDetails = AdditionalDescriptionTextForDraftBeer(
			Form.InformationOnOpenedPackagingUnits,
			Form.Object.ExciseStamps,
			CurrentData);
		If AdditionalDetails.Count() > 0 Then
			AdditionalDetails.Insert(0, ProductName);
			ProductName = New FormattedString(AdditionalDetails);
		EndIf;
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
	If Form.UseLoyaltyCards Then
		NameOfDashboardDetails = "Map";
		RowData.Insert(NameOfDashboardDetails, Form.Object.LoyaltyCard);
	EndIf;
	
	SummaryParameters = New Structure;
	SummaryParameters.Insert("Count",                  0);
	SummaryParameters.Insert("Price",                        0);
	SummaryParameters.Insert("ManualDiscount",           0);
	SummaryParameters.Insert("PercentRateOfManualDiscount",         0);
	SummaryParameters.Insert("DiscountMarkupAmount",   0);
	SummaryParameters.Insert("PercentRateOfAutomaticDiscountMarkup", 0);
	SummaryParameters.Insert("Sum",                       0);
	If CurrentData <> Undefined Then
		FillPropertyValues(SummaryParameters, CurrentData);
		SummaryParameters.Count = CurrentData.NumberOfPackages;
	EndIf;
	
	Data = New Structure;
	Data.Insert("ProductName",    ProductName);
	Data.Insert("RowData",          RowData);
	Data.Insert("SummaryParameters",     SummaryParameters);
	Data.Insert("RequiredDetails_", RequiredDetails_);
	If DisplayChange Then
		
		TextAccruedBonusPoints = StrTemplate(
			NStr("vi = 'Đã tính điểm thưởng: %1 %2';
				|ru = 'Начислено бонусных баллов: %1 %2';
				|en = 'Earned bonus points: %1 %2'; fa = 'Earned bonus points: %1 %2';
				|it = 'Punti bonus acculumati: %1 %2';
				|pl = 'Naliczono punktów bonusowych: %1 %2';
				|tr = 'Tahakkuk eden bonus puanlar: %1 %2'"),
			Form.Object.Goods.Total("AmountOfEarnedBonusPointsInCurrency"),
			Form.Object.Currency);
		
		TextDelivery = New FormattedString(
			StrTemplate(NStr("vi = 'Thay đổi: %1';
							|ru = 'Сдача: %1';
							|en = 'Change: %1'; fa = 'Change: %1';
							|it = 'Resto: %1';
							|pl = 'Reszta: %1';
							|tr = 'Para üstü: %1'"),
				Format(PaymentInformation.TotalPaid_ - PaymentInformation.AmountToPay, "NFD=2; NZ=0.00")));
		
		Data.Insert("DisplayChange",               True);
		Data.Insert("TextDelivery",                    TextDelivery);
		Data.Insert("TextAccruedBonusPoints", TextAccruedBonusPoints);
		
	Else
		Data.Insert("DisplayChange", False);
	EndIf;
	Data.Insert("TheStructureOfTheMessages", Form.TheStructureOfTheMessages);
	
	RetailSalesClientServer.UpdateDashboardData(Form, Data);
	
EndProcedure

// Called from the other operations menu
// 
// Parameters:
//  Result - Boolean - 
//  AdditionalParameters - Structure - advanced setting
//
&AtClient
Procedure CheckQuantityInTheDocument(Result, AdditionalParameters) Export
	
	If ReadOnly Then // The receipt has been punched. Changing information is prohibited.
		Return;
	EndIf;
	
	OnlyNonLabeledProductsHaveBeenUnloaded = False;
	
	OpeningParameters = New Structure;
	FormEventsClient.WhenChangingElement(ThisObject, "CheckQuantityInTheDocument", OpeningParameters);
	ProcessPermitsForSaleOfGoodsLocalization(ThisObject);

	OpeningParameters.Insert("AddressInTempStorage",            PutTablePartOfGoodsInTemporaryStorageToCheckQuantity(OnlyNonLabeledProductsHaveBeenUnloaded));
	OpeningParameters.Insert("GoodsQuantityExcessIsAllowed", True);
	OpeningParameters.Insert("SeriesSpecificationParameters",               SeriesSpecificationParameters);
	OpeningParameters.Insert("Warehouse",                                Object.Warehouse);
	OpeningParameters.Insert("TabularSectionName",                    "Goods");
	OpeningParameters.Insert("Ref",                               Object.Ref);
	OpeningParameters.Insert("OnlyNonLabeledProductsHaveBeenUnloaded", OnlyNonLabeledProductsHaveBeenUnloaded);
	
	OpenForm(
		"CommonForm.CheckDocumentPopulation",
		OpeningParameters,
		ThisObject,,,,
		New CallbackDescription("CheckQuantityInTheDocumentCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SnoozeCompletion(Result, AdditionalParameters) Export
	
	Notify("Write_CashRegisterReceipt", New Structure, Undefined);
	
	If Result Then
		
		UploadNewReceipt();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)
	
	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	UseWarerooms = UseWarerooms(Object.Warehouse, Object.Date);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	StructureOfActions.Insert("FillInVATRate",
		BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	StructureOfActions.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", False));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount",
		BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus",
		New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	If ControlProductRange Then
		
		AssortmentInspectionStructure = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentInspectionStructure.Ref = Object.Ref;
		AssortmentInspectionStructure.Warehouse = Object.Warehouse;
		AssortmentInspectionStructure.Date = Object.Date;
		AssortmentInspectionStructure.MessageText 
			= NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng hoặc đã bị cấm bán.';
					|ru = 'Товар %1 не включен в ассортимент магазина или запрещен к продаже.';
					|en = 'Product %1 is not included in the store''s product range or prohibited for sale.'; fa = 'Product %1 is not included in the store''s product range or prohibited for sale.';
					|it = 'Il prodotto %1 non è incluso nell''inventario del negozio o ne è vietata la vendita.';
					|pl = 'Towar %1 nie jest zawarty w asortymencie sklepu lub jego sprzedaż jest zabroniona.';
					|tr = 'Ürün %1 mağazanın ürün yelpazesine dahil değildir veya satışına izin verilmemektedir.'");
			
		AssortmentInspectionStructure.NameOfAssortmentResource = "SalesAreAllowed";
		AssortmentInspectionStructure.CheckedYouCanAdd = True;
		AssortmentInspectionStructure.AllowAdding = False;
		
		StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
		
	EndIf;

	StructureOfActions.Insert("ProductsOnChangeOverridable",
		New Structure("FormName, TabularSectionName", FormName, "Goods"));
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	
	If UseWarerooms Then
		StructureOfActions.Insert("FillRoom", New Structure("Warehouse", Object.Warehouse));
	EndIf;
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(
		ThisObject, "Products", StructureOfActions);
	
	ListOfProperties = "ProductsInSet, ItemVariantOfSet, Products, Characteristic, Package, Series, Price, 
		|NumberOfPackages, PercentRateOfManualDiscount";
	
	RowsToProcess = New Array();
	
	If Not SelectMarkingCodesForOpenedConsumerPackagesByFIFOLocalization() Then
		ProcessOpenedConsumerPackagingUnitsAccordingToItemTableLocalization(TableOfGoods);
	EndIf;
	
	For Each RowOfProduct In TableOfGoods Do
		
		CurrentRow = Object.Goods.Add();
		FillPropertyValues(CurrentRow, RowOfProduct, ListOfProperties);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
	FillInServiceDetailsForProductRange();
	WhenChangingNomenclatureOfQuantityCharacteristicLocalization();
	ProductsServer.FillInStatusesForSpecifyingSeries(Object,ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
	
	If CurrentRow <> Undefined Then
		Items.Goods.CurrentRow = CurrentRow.GetID();
	EndIf;
	
	UpdateDashboardData(ThisObject, True = ReadOnly);
	
	If TableOfGoods.Count() Then
		FormEvents.WhenChangingElement(ThisObject, "Goods");
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeSellerCompletion(Seller, AdditionalParameters) Export
	
	If Not ValueIsFilled(Seller) Then
		Return;
	EndIf;
	
	CurrentSeller = Seller;
	FillInFormInTablePart();
	RefreshFormTitle();
	
EndProcedure

// Called when a hyperlink is clicked in the dashboard
&AtClient
Procedure EditSellerHyperlinkCompletion(Result, AdditionalParameters) Export
	
	Seller = Result;
	If Not ValueIsFilled(Seller) Then
		Return;
	EndIf;
	
	For Each SelectedRow In Items.Goods.SelectedRows Do
		
		TSRow = Object.Goods.FindByID(SelectedRow);
		TSRow.Seller = Seller;
		
	EndDo;
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtServer
Procedure FillInFormInTablePart()
	
	For Each TSRow In Object.Goods Do
		If Not ValueIsFilled(TSRow.Seller) Then
			TSRow.Seller = CurrentSeller;
		EndIf;
	EndDo;
	
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
// Called from the MENUOPERATIONISKKM form
Procedure ChangeTheCashRegisterOfTheKKMCompletion(CashRegister, AdditionalParameters) Export
	
	If Not ValueIsFilled(CashRegister) Then
		Return;
	EndIf;
	
	If Object.CashRegister <> CashRegister Then
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
	EndIf;
	
	ChangeTheCashRegisterOfTheKKM(CashRegister);
	
	RecalculateDocumentOnClient();
	
EndProcedure

&AtClient
Procedure ReturnOfGoodsProcessingOfNotification(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CashRegister", Object.CashRegister);
	OpeningParameters.Insert("Cashier", Object.Cashier);
	OpeningParameters.Insert("Organization", Object.Organization);
	
	OpenForm("Document.CashRegisterReceipt.Form.RegisterReturnOnSameDayBasis", OpeningParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure CheckQuantityInTheDocumentCompletion(Result, AdditionalParameters) Export
	
	ReturnParameters = Result;
	
	If ReturnParameters <> Undefined Then
		
		ChangeTablePartBasedOnResultsOfCheck(ReturnParameters, ?(CachedValues = Undefined, BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues(), CachedValues));
		
		Modified = True;
		DiscountsMarkupsFillingClient.ResetDiscountsCalculatedFlag(ThisObject);
		RecalculateDocumentOnClient();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetValuesBySettings()
	
	If ValueIsFilled(Object.Ref) Then
		
		SelectionBasedOnCashRegisterOfDeferredReceipt = Equipment.FindRows(New Structure("Object", Object.CashRegister));
		If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_
			And SelectionBasedOnCashRegisterOfDeferredReceipt.Count() = 0
			And Equipment.Count() > 0 Then
			Object.CashRegister = Equipment[0].Object;
		EndIf;
		
		StructureRegisterShiftState = RetailSales.GetCashShiftState(Object.CashRegister);
		CurrentUser = Users.CurrentUser();
		
		If Object.Status <> Enums.CashRegisterReceiptStatuses.ReceiptIsIssued_ Then
			
			If Object.CashRegisterShift <> StructureRegisterShiftState.CashRegisterShift Then
				Object.CashRegisterShift = StructureRegisterShiftState.CashRegisterShift;
			EndIf;
			
			If Object.Organization <> StructureRegisterShiftState.Organization Then
				Object.Organization = StructureRegisterShiftState.Organization;
			EndIf;
			
			If Object.Cashier <> CurrentUser Then
				Object.Cashier = CurrentUser;
			EndIf;
			
		EndIf;
		
	Else
		
		FillInServiceDetailsForProductRange();
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
		SetVisibilityOfSeriesElements();
		
		If Parameters.Property("CopyingValue")
			And ValueIsFilled(Parameters.CopyingValue)
			And SeriesSpecificationParameters.UseItemsBatch Then
			
			Object.SetOfSeries.Clear();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFormItemsVisibility()
	
	Items.PayForESFSS.Visible = False;
	Items.PayForSBP.Visible = False;
	
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
Procedure RefreshFormTitle()
	
	Title = NStr("vi = 'Bán hàng (Thu ngân: %Cashier%, Người bán: %Seller%)';
				|ru = 'Продажа (Кассир: %Cashier%, Продавец: %Seller%)';
				|en = 'Sale (Cashier: %Cashier%, Sales associate: %Seller%)'; fa = 'Sale (Cashier: %Cashier%, Sales associate: %Seller%)';
				|it = 'Vendita (Operatore di cassa: %Cashier%, venditore: %Seller%)';
				|pl = 'Sprzedaż (Kasjer: %Cashier%, Sprzedawca: %Seller%)';
				|tr = 'Satış (Kasiyer: %Cashier%, Satıcı: %Seller%)'");
	Title = StrReplace(Title, "%Cashier%", Object.Cashier);
	Title = StrReplace(Title, "%Seller%", ?(ValueIsFilled(CurrentSeller),CurrentSeller, NStr("vi = '<Chưa chọn>';
																							|ru = '<Не выбран>';
																							|en = '<Not selected>'; fa = '<Not selected>';
																							|it = '<non è selezionato>';
																							|pl = '<Nie wybrany>';
																							|tr = '<seçilmedi>'")));
	
EndProcedure

&AtServer
Procedure WhenCreatingReceipt()
	
	If UsePriceManagementSystem25 Then
		ObjectForStoringSalesTermsAndConditions = ProductRangeServerCached.StoreFormatByWarehouse(Object.Warehouse, Object.Date);
	Else
		ObjectForStoringSalesTermsAndConditions = Object.Warehouse;
	EndIf;
	
	TheStructureOfTheMessages = DiscountsMarkupsFillingServer.TheStructureOfTheMessages(Object);
	Items.ShowMessages.Visible = TheStructureOfTheMessages.Messages.Count() > 0;
	
	AnalysisOfPossibilityOfPaymentWithBonusPoints();
	
	If Not ValueIsFilled(Object.Ref) Then
		
		SeriesSpecificationParameters = New FixedStructure(ProductsServer.SeriesSpecificationParameters(Object, Documents.CashRegisterReceipt));
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters);
		
		SetVisibilityOfSeriesElements();
		
	EndIf;
	
	StructureRegisterShiftState = RetailSalesServerCall.RegisterShiftState(Object.CashRegister);
	FillPropertyValues(Object, StructureRegisterShiftState,, "Cashier");
	RetailSales.ClearFiscalTransactionData(FiscalOperationData);
	
	Object.Date = CurrentSessionDate();
	
	RefreshFormTitle();
	
	ConfigureCWP();
	
EndProcedure

&AtClient
Procedure BeforeClosingReceipt(Cancel, CallbackDescription = Undefined)
	
	If SBPAmountHasBeenCompleted > 0 Or SBPAmountPending > 0 Then
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Undefined);
		EndIf;
		
		Return;
	EndIf;
	
	Buttons = New ValueList;
	
	ReserveUpTo = EndOfDay((Object.Date + 24*60*60));
	
	If Not ReadOnly And (Modified Or ValueIsFilled(Object.Ref)) Then
		
		QueryText = NStr("vi = 'Dữ liệu phiếu tính tiền đã thay đổi';
						|ru = 'Данные чека ККМ были изменены.';
						|en = 'Cash register receipt data has changed.'; fa = 'Cash register receipt data has changed.';
						|it = 'I dati dello scontrino sono stati cambiati.';
						|pl = 'Dane paragonu fiskalnego zostały zmienione.';
						|tr = 'Yazar kasa fişinin ayrıntıları değiştirildi.'");
		
		If ControlIsDisabledForTheWarehouse Then
			If AccessRights.Snooze Then
				Buttons.Add(1, NStr("vi = 'Hoãn lại';
									|ru = 'Отложить';
									|en = 'Put on hold'; fa = 'نگه‌داشتن';
									|it = 'Rinvia';
									|pl = 'Put on hold';
									|tr = 'Ertele'"));
			EndIf;
		Else
			If AccessRights.Snooze Then
				Buttons.Add(1, NStr("vi = 'Hoãn lại không dự phòng';
									|ru = 'Отложить без резервирования';
									|en = 'Put on hold without reservation'; fa = 'Put on hold without reservation';
									|it = 'Rinvia senza prenotazione';
									|pl = 'Odłóż bez rezerwowania';
									|tr = 'Rezervasyon olmadan erteleyin'"));
			EndIf;
			If AccessRights.Reserve_ Then
				Buttons.Add(2, NStr("vi = 'Dự phòng cho đến khi ...';
									|ru = 'Зарезервировать до...';
									|en = 'Reserve until...'; fa = 'Reserve until...';
									|it = 'Prenota fino a...';
									|pl = 'Zarezerwować do...';
									|tr = '...kadar ayırın.'"));
			EndIf;
		EndIf;
		
		If ValueIsFilled(Object.Ref) And AccessRights.LineAdjustment Then
			Buttons.Add(4, NStr("vi = 'Xóa bỏ phiếu';
								|ru = 'Удалить чек';
								|en = 'Remove receipt'; fa = 'Remove receipt';
								|it = 'Elimina scontrino';
								|pl = 'Usuń paragon';
								|tr = 'Makbuzu sil'"));
		EndIf;
		
		TitleOfCloseButton = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Close';
									|pl = 'Close';
									|tr = 'Kapat'");
		If AccessRights.LineAdjustment And Modified Then
			TitleOfCloseButton = NStr("vi = 'Đóng không lưu';
										|ru = 'Закрыть без сохранения';
										|en = 'Close without saving'; fa = 'بستن بدون ذخیره';
										|it = 'Chiudi senza salvare';
										|pl = 'Zamknij bez zapisywania';
										|tr = 'Kaydetmeden kapat'");
		EndIf;
		Buttons.Add(3, TitleOfCloseButton);
		
		Buttons.Add(99, NStr("vi = 'Hủy bỏ';
							|ru = 'Отмена';
							|en = 'Cancel'; fa = 'انصراف';
							|it = 'Annulla';
							|pl = 'Anuluj';
							|tr = 'İptal'"));
		
	EndIf;

	BeforeClosingReceiptLocalization(Cancel, Buttons);
	
	If Buttons.Count() > 0 Then
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("ReserveUpTo", ReserveUpTo);
		AdditionalParameters.Insert("CallbackDescription", CallbackDescription);
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("QuestionBeforeClosingCheckEnds", ThisObject, AdditionalParameters),
			QueryText,
			Buttons);
		
	Else
		
		If CallbackDescription <> Undefined Then
			RunCallback(CallbackDescription, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuestionBeforeClosingOperationCompletion(Result, AdditionalParameters) Export
	
	Notify("Write_CashRegisterReceipt", New Structure, Undefined);
	
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

	RetailSalesClient.ClearMessageWindow(ThisObject);
	
	If QuestionResult = 1 Then
		
		// Postpone the receipt without reservation
		Notification = New CallbackDescription("QuestionBeforeClosingOperationCompletion", ThisObject, AdditionalParameters);
		DeferOnClient(Notification);
		
	ElsIf QuestionResult = 2 Then
		
		ReserveUpTo = EndOfDay((Object.Date + 24*60*60));
		Notification = New CallbackDescription("QuestionBeforeClosingOperationCompletion", ThisObject, AdditionalParameters);
		AdditionalParameters = New Structure("NotificationOnCompletion", Notification);
		
		CallbackDescription = New CallbackDescription(
				"ReserveOnClient",
				ThisObject,
				AdditionalParameters);
			
		// Postpone the reservation receipt
		ShowInputDate(
			CallbackDescription,
			ReserveUpTo,
			NStr("vi = 'Dự phòng cho đến khi:';
				|ru = 'Зарезервировать до:';
				|en = 'Reserve until:'; fa = 'Reserve until:';
				|it = 'Prenota fino a:';
				|pl = 'Zarezerwować do...';
				|tr = 'Şuna kadar ayırın:'"),
			DateFractions.DateTime);
		
	ElsIf QuestionResult = 3 Then
		
		// Close without saving.
		If AdditionalParameters.CallbackDescription = Undefined Then
			ForcedShutdown = True;
			Close(Undefined);
		Else
			RunCallback(AdditionalParameters.CallbackDescription, Undefined);
		EndIf;
		
		// Close the KM check session on the CCT if it was opened
		RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
		
	ElsIf QuestionResult = 4 Then
		
		// Delete the receipt.
		DeletionCompleted_ = RetailSalesServerCall.DeleteDocumentWhenCancelingFiscalTransaction(Object.Ref);
		
		If DeletionCompleted_ Then
			
			Notify("Write_CashRegisterReceipt", New Structure, Undefined);
			
			If AdditionalParameters.CallbackDescription = Undefined Then
				ForcedShutdown = True;
				Close(Undefined);
			Else
				RunCallback(AdditionalParameters.CallbackDescription, Undefined);
			EndIf;
			
			// Close the KM check session on the CCT if it was opened
			RetailSalesClient.CloseKmVerificationSessionOnCCT(UUID, CashRegisterParameters.DeviceID);
			
		EndIf;
		
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
Procedure ChangeTheCashRegisterOfTheKKM(CashRegister)
	
	Object.CashRegister = CashRegister;
	CashRegisterParameters = New FixedStructure(Catalogs.CashRegisters.CashRegisterParameters(Object.CashRegister));
	FDFVersion = EquipmentManagerServerCall.FiscalDeviceSupportsFFDVersion(CashRegisterParameters.DeviceID);
	
	NewReceiptOnServer();
	
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
Procedure ConfigureCWP()
	
	SetPrivilegedMode(True);
	
	GetHardwareLinks();
	
	// Run-time parameters.
	ControlIsDisabledForTheWarehouse = ValueIsFilled(Object.Warehouse)
	                           And Catalogs.Warehouses.InventoryControlDisabled(Object.Warehouse)
	                           And Not Common.ObjectAttributeValue(Object.Warehouse, "RealTimeStockControl");

	If UseDiscountsMarkupsInSales Then
		SetUpAutomaticMarkUpDiscounts();
	EndIf;
	
	If ClientApplication.CurrentInterfaceVariant() = ClientApplicationInterfaceVariant.Version8_2 Then
		Items.AmountWithoutADiscount.Width = 22;
		Items.DiscountAmount.Width    = 22;
		Items.AmountToPay.Width   = 22;
	EndIf;
	
	RetailSales.SignHotkeysOnButtons(ThisObject);
	
	Query = New Query(
	"SELECT TOP 1
	|	ISNULL(CWPSettings.KeyboardShortcuts, UNDEFINED)               AS KeyboardShortcuts,
	|	ISNULL(CWPSettings.KeyboardShortcuts.QuickGoods, UNDEFINED) AS QuickGoods,
	|	ISNULL(CWPSettings.KeyboardShortcuts.FormCommands, UNDEFINED)  AS FormCommands,
	|	CWPSettings.CashierCanBeASeller                             AS CashierCanBeASeller,
	|	CWPSettings.SellingAreaManagerMayActAsASeller              AS SellingAreaManagerMayActAsASeller,
	|	CWPSettings.UseAuthorization
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
		ForcefullyAuthorize = Selection.UseAuthorization;
		SellingAreaManagerMayActAsASeller = Selection.SellingAreaManagerMayActAsASeller;
		CashierCanBeASeller  = Selection.CashierCanBeASeller;
		
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
	
	Items.QuickGoods.Visible    = QuickGoods.Count() > 0;
	Items.CalculateDiscounts.Visible = UseDiscountsMarkupsInSales;
	
	Items.ChangeSeller.Visible  = Not SellerOnlyCashier;
	Items.ChangeWareroom.Visible = CashRegisterParameters.UseWarerooms;
	Items.GoodsPremise.Visible   = CashRegisterParameters.UseWarerooms;
	Items.SetComposition.Visible      = GetFunctionalOption("UseSets");
	Items.SpecifySeries.Visible      = SeriesSpecificationParameters.UseItemsBatch;
	Items.ManualDiscounts.Visible      = UseDiscountAdjustmentsInSales;
	// Setting the visibility of the "Get Weight" command
	TMCommonUse.CustomizePeripherals(ThisObject, "");
	
	AvailablePaymentMethods = RetailSalesClientServer.AvailablePaymentMethods(ThisObject);
	Items.PayInCash.Visible              = AvailablePaymentMethods.CashPayment;
	Items.PaymentByCard.Visible                 = AvailablePaymentMethods.PaymentCards;
	Items.MixedPayment.Visible                = AvailablePaymentMethods.PaymentCards Or AvailablePaymentMethods.GiftCertificates Or AvailablePaymentMethods.BonusPoints;
	Items.PayUsingGiftCertificate.Visible = AvailablePaymentMethods.GiftCertificates;
	
	ElementsToRegroup = New Array;
	
	ElementsToRegroup.Add(Items.QuickGoods);
	ElementsToRegroup.Add(Items.CalculateDiscounts);
	
	For Each Subgroup In Items.GroupBottomCommandBarContextCommands.ChildItems Do
		For Each Item In Subgroup.ChildItems Do
			ElementsToRegroup.Add(Item);
		EndDo;
	EndDo;
	
	ElementsToRegroup.Add(Items.PayInCash);
	ElementsToRegroup.Add(Items.PaymentByCard);
	ElementsToRegroup.Add(Items.PayUsingGiftCertificate);
	ElementsToRegroup.Add(Items.MixedPayment);

	ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup);
	ManagingAvailabilityOfPaymentButtons(ThisObject);
	
	RetailSales.RearrangeFormButtons(ThisObject, ElementsToRegroup);
	
	RetailSales.ConfigurePrintCommands(ThisObject, Items.MovableButtons);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ManagingAvailabilityOfPaymentButtons(Form, PaymentInformation = Undefined)
	
	If PaymentInformation = Undefined Then
		PaymentInformation = PaymentInformation(Form);
	EndIf;
	
	Items = Form.Items;
	Items.MixedPayment.Enabled              = True;

	CardPaymentStartedReceiptNotPunched = ((Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.DeferredWithReservation") 
										Or Form.Object.Status = PredefinedValue("Enum.CashRegisterReceiptStatuses.AmountDue"))
										And PaymentInformation.PaymentCards <> 0);

	Items.PayInCash.Enabled            = Not CardPaymentStartedReceiptNotPunched;
	Items.PaymentByCard.Enabled               = Not CardPaymentStartedReceiptNotPunched;
	Items.PayUsingGiftCertificate.Enabled = Not CardPaymentStartedReceiptNotPunched;
	
	ManagingAvailabilityOfPaymentButtonsLocalization(Form, PaymentInformation);
	
EndProcedure

&AtClient
Procedure OpenAuthorizationWindow()
	
	OpenForm("Document.CashRegisterReceipt.Form.Authorization", New Structure("Mode", "ChangeRights"), ThisObject);
	
EndProcedure

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

&AtClient
Procedure ProcessPrintCommand(CommandName, AdditionalParameters) Export

	AttachableCommandsClient.ExecuteCommand(ThisObject, Commands[CommandName], Object);

EndProcedure

&AtClient
Procedure SetCurItemToNewReceiptButton()
	
	CurrentItem = Items.NewReceipt;
	
EndProcedure

&AtClient
Procedure SetCurrentElementToTabularPartOfProducts()
	
	CurrentItem = Items.Goods;
	
EndProcedure

&AtClient
Procedure AfterPrintingSlipReceiptIsComplete(ExecutionResult, AdditionalParameters) Export
	
	If MeasurementUIDPrintingOfSlipReceipt <> Undefined Then
		PerformanceMonitorClient.StopTimeMeasurement(MeasurementUIDPrintingOfSlipReceipt, Not ExecutionResult.Result);
		MeasurementUIDPrintingOfSlipReceipt = Undefined;
	EndIf;
	
	If Not ExecutionResult.Result Then
		
		MessageText = StrTemplate(
			NStr("vi = 'Khi in phiếu cạnh phiếu cuối đã xảy ra lỗi:
			           |""%1"".';
			           |ru = 'При печати слип-чека возникла ошибка:
			           |""%1"".';
			           |en = 'An error occurred when printing a sales slip:
			           |""%1"".'; fa = 'An error occurred when printing a sales slip:
			           |""%1"".';
			           |it = 'Durante la stampa del controllo di scorrimento si è verificato un errore:
			           |""%1"".';
			           |pl = 'Podczas drukowania slipu wystąpił błąd:
			           |""%1"".';
			           |tr = 'Slip fişi yazdırılırken bir hata oluştu:
			           |""%1"".'"),
			ExecutionResult.ErrorDescription);
		
		RetailSalesServerCall.LogEntry(
			MessageText, "AfterPrintingSlipReceiptIsComplete", Object.Ref);
		CommonClient.MessageToUser(MessageText);
		
	EndIf;

EndProcedure

&AtServerNoContext
Function PriceTypeIncludesVATAmount(PriceKind)
	
	Return Common.ObjectAttributeValue(PriceKind, "PriceIncludesVAT");
	
EndFunction

&AtClient
Procedure ReturnOfGoodsWithoutReceiptNotificationProcessing(Result, AdditionalParameters) Export
	
	If Not Result Then
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("CashRegisterShift", Object.CashRegisterShift);
	
	OpenForm("Document.CashRegisterReceiptReturn.Form.CWPDocumentForm", New Structure("Basis", OpeningParameters), FormOwner);
	
EndProcedure

&AtClient
Function StructureOfPaymentForm()
	
	PaymentMethod = New Structure;
	PaymentMethod.Insert("CashPayment",              False);
	PaymentMethod.Insert("BonusPoints",         False);
	PaymentMethod.Insert("PaymentCards",        False);
	PaymentMethod.Insert("ESFSS",                 False);
	PaymentMethod.Insert("GiftCertificates", False);
	
	Return PaymentMethod;
	
EndFunction

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
Function StructureOfActionsWhenChangingNomenclatureOfTabularItems()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If ControlProductRange Then
		AddAssortmentCheckToActionStructure(StructureOfActions);
		StructureOfActions.Insert("FillInSalePriceByProductRange", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
	ElsIf UsePriceManagementSystem25 Then 
		StructureOfActions.Insert("FillInRetailSalesTermsAndConditions", BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
	Else
		StructureOfActions.Insert("FillInSalePrice", BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	
	StructureOfActions.Insert("FillOutSellerSForm", New Structure("Seller", CurrentSeller));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountAutomaticDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountManualDiscount", New Structure("Clear", True));
	StructureOfActions.Insert("RecalculateAmountTakingIntoAccountDiscountWithBonusPoints");
	StructureOfActions.Insert("RecalculateVATAmount", BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckSeriesCalculateStatus", New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters));
	
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "Goods"));
	
	BatchProcessingOfTablePartClientServerLocalization.CompleteActionStructureWhenChangingElement(ThisObject, "Products", StructureOfActions);
	
	Return StructureOfActions;
EndFunction

&AtClient
Procedure CheckPermissionToDeleteRowInTablePart(TabularSectionName, Cancel)
	
	CheckPermissionToDeleteRowInTablePartLocalization(TabularSectionName, Cancel);
	
EndProcedure

#EndRegion

#Region Localization

&AtServer
Procedure ConfigureCWPLocalization(AvailablePaymentMethods, ElementsToRegroup)
	
	
EndProcedure

&AtServer
Procedure OnCreateAtServerLocalization(Form, Cancel, StandardProcessing)
	
	
EndProcedure

&AtClient
Procedure GoodsOnStartEditLocalization(Item, NewRow, Copy)
	
	
EndProcedure

&AtClient
Procedure GoodsOnActivateRowLocalization(Item)
EndProcedure

&AtClient
Procedure GoodsOnChangeLocalization(Item)
EndProcedure

&AtClient
Procedure GoodsAfterDeleteRowLocalization(Item)
EndProcedure

&AtClient
Procedure GoodsProductsOnChangeLocalization(Item)
EndProcedure

&AtServer
Function SplitArrayOfStringsForDifferentTypesOfBatchProcessing(OriginalLines)
	
	Result = New Structure;
	Result.Insert("ItIsRequiredToFillInPrice", OriginalLines);
	Result.Insert("NotItIsRequiredToFillInPrice", New Array);
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure ManagingAvailabilityOfPaymentButtonsLocalization(Form, PaymentInformation)

	
EndProcedure

&AtClient
Procedure RecalculateDocumentOnClientLocalization(PaymentInformation)
EndProcedure

&AtClient
Procedure SelectedPaymentMethodLocalization(SelectedPaymentMethod)
	
	
	RetailSalesClientServerLocalization.SupplementAvailablePaymentMethods(ThisObject, SelectedPaymentMethod);

EndProcedure

&AtClientAtServerNoContext
Procedure PaymentInformationLocalization(Form, PaymentInformation)
	
	
EndProcedure

&AtClient
Procedure PayForESFSSLocalization()
	
	
EndProcedure

&AtClient
Procedure PayForSBPLocalization()
	
	
EndProcedure

&AtClient
Function RequiredToPostponeReceiptWhenAddingPaymentLocalization(PaymentInformation)
	Result = False;
	
	
	Return Result;
EndFunction

&AtClient
Function RequiredToPostponeReceiptWhenPaymentCancellationEndingLocalization(PaymentInformation)
	Result = False;
	
	
	Return Result;
EndFunction

&AtClient
Procedure PaymentCancelLocalization(AdditionalParameters)
	
	
	//@skip-warning
	CancelPaymentByPaymentCards(
		New CallbackDescription("PaymentCancelCompletion", ThisObject, AdditionalParameters));
	
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
		
	AttachIdleHandler("SetCurItemToNewReceiptButton", 0.1, True);
	
	CommonClient.MessageToUser(
		NStr("vi = 'Chưa triển khai tính năng in phiếu đối với chứng từ. Hãy liên hệ với nhà phát triển.';
			|ru = 'Функционал печати чека для документа не реализован. Обратитесь к разработчикам.';
			|en = 'Printing a receipt for the document is not implemented. Contact the developers.'; fa = 'Printing a receipt for the document is not implemented. Contact the developers.';
			|it = 'Il funzionale di stampa dello scontrino per il documento non è venduto. Rivolgersi agli elaboratori.';
			|pl = 'Funkcja drukowania paragonu dla dokumentu nie jest zaimplementowana. Zwróć się do deweloperów.';
			|tr = 'Belge için makbuz yazdırma işlevi uygulanmamıştır. Geliştiricilerle iletişime geçin.'"));
	
EndProcedure

&AtServer
Procedure WhenChangingNomenclatureOfQuantityCharacteristicLocalization()
	
	Return;
	
EndProcedure

&AtClient
Procedure GoodsOnEditEndLocalization(
	Item,
	NewRow,
	CancelEdit,
	CachedValues,
	AdditionalParameters)
	
	
EndProcedure

&AtServer
Procedure GoodsAtEndOfEditingOnServerLocalization(RowID, CachedValues)
	
	
EndProcedure

&AtServer
Procedure UpdateCacheInformationOnOpenedPackages()
	
	
EndProcedure

&AtServerNoContext
Function ThisIsMarkedItemWithPartialDisposalLocalization(Products)
	
	ThisIsMarkedItemWithPartialDisposal = False;
	
	
	Return ThisIsMarkedItemWithPartialDisposal;
	
EndFunction

&AtServer
Function SelectMarkingCodesForOpenedConsumerPackagesByFIFOLocalization()
	
	
	Return True;
	
EndFunction

&AtServer
Function OpenedConsumerPackagingUnitsByItemLocalization(DataBiItem)
	
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure ProcessOpenedConsumerPackagingUnitsAccordingToItemTableLocalization(TableOfGoods)
	
	
EndProcedure

&AtServer
Procedure ProcessAdditionOfLinesWithOpenedConsumerPackagesLocalization(AddedRows, ModifiedRows)
	
	
EndProcedure

&AtClient
Procedure BeforeClosingReceiptLocalization(Cancel, Buttons)
	
	
EndProcedure

&AtClient
Procedure SpecifySalesPermitLocalization()
	
	
EndProcedure

&AtClient
Procedure AddPriceControlParameterForIDCLocalizationToForm(Form, FormParameters)
	
	
EndProcedure

&AtClient
Procedure CheckPermissionToDeleteRowInTablePartLocalization(TabularSectionName, Cancel)
	
	
EndProcedure

&AtClient
Procedure AddLocalizationFormParameters(FormParameters)
	
	
EndProcedure

&AtServer
Procedure AddDiscountParametersLocalization(DiscountParameters)
	
	
EndProcedure

&AtClient
Procedure CheckItemPricesLocalization()
	
	CheckPriceChangesInPriceList = True;
	
	
	If CheckPriceChangesInPriceList Then
		CheckPricesOnLocalizationPriceList();
	EndIf;
	
EndProcedure

&AtServer
Procedure CheckPricesOnLocalizationPriceList()
	
	If ValueIsFilled(Object.Ref) Then
		
		StructureOfActions = New Structure;
		
		If ControlProductRange Then
			StructureOfActions.Insert(
				"FillInSalePriceByProductRange",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInPriceByAssortmentInTSLine(Object));
		ElsIf UsePriceManagementSystem25 Then 
			StructureOfActions.Insert(
				"FillInRetailSalesTermsAndConditions",
				BatchProcessingOfTablePartClientServer.GetStructureForFillingInRetailSalesTermsInTSLine(Object, ObjectForStoringSalesTermsAndConditions));
		Else
			StructureOfActions.Insert(
				"FillInSalePrice",
				BatchProcessingOfTablePartClientServer.GetStructureOfFillingInRetailPriceInTSLine(Object));
		EndIf;
		
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
			AssortmentInspectionStructure.AllowAdding = False;
			
			StructureOfActions.Insert("CheckRowAssortment", AssortmentInspectionStructure);
		EndIf;
		
		TableOfGoods = Object.Goods.Unload();
		
		RowsToProcess = New Array;
		For Each TableRow In TableOfGoods Do
			RowsToProcess.Add(TableRow);
		EndDo;
		
		BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess,
			StructureOfActions,
			TableOfGoods);
		
		For Each LineWithPriceListPrice In RowsToProcess Do
			
			
			LineNumber = LineWithPriceListPrice.LineNumber;
			StringTSGoods = Object.Goods[LineNumber - 1];
			
			If LineWithPriceListPrice.Price <> StringTSGoods.Price Then
				
				MessageText = StrTemplate(
					NStr("ru = 'В строке №%1 для ""%2"" цена позиции чека - ""%3"" отличается от цены прайс-листа - ""%4""';
						|vi = 'In line %1 for ""%2"", the receipt item price (%3) differs from the price list price (%4)';
						|en = 'In line %1 for ""%2"", the receipt item price (%3) differs from the price list price (%4)'; fa = 'In line %1 for ""%2"", the receipt item price (%3) differs from the price list price (%4)';
						|it = 'In line %1 for ""%2"", the receipt item price (%3) differs from the price list price (%4)';
						|pl = 'In line %1 for ""%2"", the receipt item price (%3) differs from the price list price (%4)';
						|tr = '""%2"" için %1 numaralı satırdaki birim fiyat ""%3""  fiyat listesindekinden ""%4"" farklıdır'"),
					LineNumber,
					StringTSGoods.Products,
					StringTSGoods.Price,
					LineWithPriceListPrice.Price);
				
				RetailSalesServerCall.LogEntry(
					MessageText, "OpeningDeferredReceipt", Object.Ref);
				Common.MessageToUser(MessageText);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#Region AdditionalDescriptionOfKegs

// Returns an additional description for the item if the item is a different beer in kegs.
// 
// Parameters:
//  InformationOnOpenedPackagingUnits - FormDataCollection - Cache of opened packages data
//  ExciseStamps - FormDataCollection - Barcodes are packaged
// 	LineProducts_ - ValueTableRow - A line with data on the product for which an additional description is displayed
// 
// Returns:
//  Array of String - Formatted hint text for all kegs depending on the Balance in the kegs. If 
//                                  it is greater than the minimum value, an empty array is returned.
&AtClientAtServerNoContext
Function AdditionalDescriptionTextForDraftBeer(InformationOnOpenedPackagingUnits, ExciseStamps, LineProducts_)
	
	DetailsParts = New Array;
	
	
	Return DetailsParts;
	
EndFunction


#EndRegion


&AtClientAtServerNoContext
Procedure ProcessPermitsForSaleOfGoodsLocalization(Form)
	
	
EndProcedure

&AtServer
Procedure UpdateSalesTagForTobaccoProductsOnlyByMRCLocalization(Form)
	
	
EndProcedure

&AtServer
Procedure UpdateStatusesAndAllowedItemsLocalization()
	
	
EndProcedure

#EndRegion

#EndRegion
