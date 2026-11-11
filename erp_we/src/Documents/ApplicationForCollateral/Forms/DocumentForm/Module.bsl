#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

&AtClient
Var ParametersForRecording Export;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	#EndRegion
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForCollateral.ItemsAndDimensionsSelectionParameters(Object.SuppliedByPurchase);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	#Region IntegratedSubsystems
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// BarcodesAndTradeEquipment
	TMCommonUse.CustomizePeripherals(ThisObject);
	// End BarcodesAndTradeEquipment
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// Handler of the "Properties" mechanism
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	ItemsAndDimensionsSelectionParameters = Documents.ApplicationForCollateral.ItemsAndDimensionsSelectionParameters(Object.SuppliedByPurchase);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	If Object.Ref.IsEmpty() Then
		OnReadCreateAtServer();
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ActivateLineOfSinglePosition();
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(
		Undefined,
		ThisObject,
		"BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	AttributesNotToCheck = New Array;
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	#EndRegion
	
	// Redefining the check in the object module:
	AttributesNotToCheck.Add("Object"); 
	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.AdditionalProperties.Insert("OnePosition", OnePosition(ThisObject));
	
	If Not DocumentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	WriteParameters.WriteMode = ValueFromTheCache(FormCache, "WriteMode");
	WriteParameters.Insert("InteractiveRecord", True);
	
	If NotExecuteCheck1BeforeWrite Then
		NotExecuteCheck1BeforeWrite = False;
		Return;
	EndIf;
	
	TMCommonUseClient.RecordObjectIfNecessary(ThisObject, WriteParameters, Cancel);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	#Region IntegratedSubsystems
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
		
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	#EndRegion
	
	FillInFormDetails();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ActivateLineOfSinglePosition();
	Notify("Write_ApplicationForCollateral", WriteParameters, Object.Ref);
	
	#Region IntegratedSubsystems
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	ForceCloseTheForm = True;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	#Region IntegratedSubsystems
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	#Region IntegratedSubsystems
	
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
	
	// Handler of the "Properties" mechanism
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, True);
		
	EndIf;
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
	#EndRegion
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetAssortmentControlInCache(FormCache,
		Object.Date,
		Object.Warehouse);
		
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	
	If Not ValueIsFilled(Object.Currency) Then
		Object.Currency = DocumentCurrency;
		
		Return;
	EndIf;
	
	RecalculateAmounts = PriceManagementSystemClient.CurrencyConversionRequired(Object, DocumentCurrency);
	CurrencyWhenChangedOnServer(Object.Currency, RecalculateAmounts);
	
	PriceManagementSystemClient.NotifyAboutEndOfConversionOfAmountsIntoCurrency(DocumentCurrency, Object.Currency);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	SetAssortmentControlInCache(FormCache,
		Object.Date,
		Object.Warehouse);
		
EndProcedure

&AtClient
Procedure ItemSwitchOnChange(Item)
	
	If Object.Goods.Count() = 0 Then
		// The table can be empty only when working with multiple positions.
		// When switching, you need to add a line and position yourself on it:
		Items.Goods.CurrentRow = Object.Goods.Add().GetID();
	EndIf;
	
	If Object.Goods.Count() > 1
		And ItemSwitch = Items.ItemPage.Name Then
		
		ItemSwitch = Items.ItemsTablePage.Name;
		ShowMessageBox(, NStr("vi = 'Không thể chuyển sang chế độ một mặt hàng nếu đã nhập nhiều hơn một hàng hóa.';
								|ru = 'Переключение в режим одной позиции невозможен, если введено более одного товара.';
								|en = 'Switching to a single item mode is not available if more than one item is entered.'; fa = 'Switching to a single item mode is not available if more than one item is entered.';
								|it = 'Switching to a single item mode is not available if more than one item is entered.';
								|pl = 'Switching to a single item mode is not available if more than one item is entered.';
								|tr = 'Birden fazla ürün girilmişse tek ürün moduna geçilemez'"));
		Return;
		
	EndIf;
	
	SetItemsPage(ThisObject);
	
EndProcedure

&AtClient
Procedure SuppliedByPurchaseOnChange(Item)
	ProvidedByPurchaseOnChangeATServer();
EndProcedure

#Region Protocol

&AtClient
Procedure StatusPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	OperationsWithDocumentProtocolClient.ProcessProtocolNavigationLink(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure ArtistPresentationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	OperationsWithDocumentProtocolClient.ProcessProtocolNavigationLink(
		ThisObject,
		FormattedStringURL,
		StandardProcessing);
	
EndProcedure

#EndRegion

#EndRegion

//@skip-check module-structure-form-event-regions -- Handlers are the same for one product, and for the list
#Region FormTableItemsEventHandlersGoods

&AtClient
Procedure GoodsNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	StructureOfActions = New Structure;
	AddActionsOnChangingNumberOfPackages(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsPriceOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsPackageOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculatePricePerPackage", CurrentData.Count);
	StructureOfActions.Insert("RecalculateAmount");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure GoodsSumOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	StructureOfActions = New Structure;
	PriceCalculationParameters = BatchProcessingOfTablePartClientServer.GetStructureForRecalculatingDiscountPriceInVHFPurchases(
		Object,
		True); // Disabling manual discounts
	StructureOfActions.Insert("RecalculatePriceDiscountForAmountInPurchases", PriceCalculationParameters);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure GoodsExpenseItemOnChange(Item)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure GoodsExpenseItemStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	// Selection of articles and analytics.
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

#Region ProductsAsAString

&AtClient
Procedure GoodsProductsAsAStringAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Waiting = 0 Then
		Return; // We do not display the entire list or the message <"" not found> (if something has already been entered)
	EndIf;
	
	// Simulation of text input in the input field with the type "Reference link.Items":
	ChoiceData = ItemSelectionData(DataGetParameters.SearchString);
	
	// If there is no data, then we do not reset the standard processing so as not to display "not found" to the user.
	If ValueIsFilled(ChoiceData) Then
		StandardProcessing = False;
	EndIf; 
	
EndProcedure

&AtClient
Procedure GoodsProductsAsAStringStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter", FilterOfProductItem());
	OpeningParameters.Insert("CurrentRow", Items.Goods.CurrentData.Products);
	
	OpenForm("Catalog.Products.Form.ChoiceForm",
		OpeningParameters,
		Item);
		
EndProcedure

&AtClient
Procedure GoodsProductsAsAStringTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
		
	SetValueInCache(FormCache, "NameOfItemChangeEvent", "TextEditEnd");
	Items.Goods.CurrentData.ProductsAsAString = Text; // For the input field of a single product, you must explicitly set the value.

EndProcedure

&AtClient
Procedure GoodsProductsAsAStringOpening(Item, StandardProcessing)
	
	CurrentData = Items.Goods.CurrentData;
	
	If ValueIsFilled(CurrentData.Products) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf IsBlankString(Item.EditText) Then
		
		StandardProcessing = False;
		
	ElsIf ValueFromTheCache(FormCache, "ItemAddendum") Then
		
		StandardProcessing = False;
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("FillingText", Item.EditText);
		OpeningParameters.Insert("FillingValues", FilterOfProductItem());
		OpeningParameters.Insert("ChoiceMode", True);
		
		OpenForm("Catalog.Products.ObjectForm", OpeningParameters, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsProductsAsAStringChoiceProcessing(Item, ValueSelected, AdditionalData, ChoiceByAdding, StandardProcessing)
	
	// The user selected a value from the list / selection form / created a new item:
	If Not ItemCorrespondsToSelectionParameters(ValueSelected) Then
		StandardProcessing = False;
		ShowMessageBox(, NStr("vi = 'Giá trị đã chọn không đáp ứng các điều kiện lựa chọn';
								|ru = 'Выбранное значение не соответствует условиям выбора';
								|en = 'The selected value does not match the selection criteria'; fa = 'The selected value does not match the selection criteria';
								|it = 'The selected value does not match the selection criteria';
								|pl = 'The selected value does not match the selection criteria';
								|tr = 'Seçilen değer seçim koşullarına uygun değil'"));
		Return;
	EndIf;
	
	CurrentData = Items.Goods.CurrentData;
	CurrentData.Products = ValueSelected;
	SetValueInCache(FormCache, "NameOfItemChangeEvent", "ChoiceProcessing");
	
EndProcedure

&AtClient
Procedure GoodsProductsAsAStringOnChange(Item)
	
	CurrentData = Items.Goods.CurrentData;
	
	// Processing events that do not allow server calls:
	NameOfItemChangeEvent = ValueFromTheCache(FormCache, "NameOfItemChangeEvent");
	If NameOfItemChangeEvent = "TextEditEnd" Then

		ItemToBeInstalled = Undefined;
		ItemSelectionData = ItemSelectionData(CurrentData.ProductsAsAString);
		If ItemSelectionData.Count() = 1 Then
			// Perhaps the text matches the name of the item:
			Products = ItemSelectionData[0].Value.Value;
			ProductPresentation = ProductsAsAString(
				CommonClientServer.ValueInArray(Products)).Get(Products);
			
			If Upper(ProductPresentation) = Upper(CurrentData.ProductsAsAString) Then
				
				ItemToBeInstalled = Products;
				
			EndIf;
			
		EndIf;
		
		CurrentData.Products = ItemToBeInstalled;
		
	EndIf;
	
	WhenChangingProducts(CurrentData);
	SetValueInCache(FormCache, "NameOfItemChangeEvent", "");
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

#Region DocumentRecording

&AtClient
Procedure WriteAndClose(Command)
	
	TMCommonUseClient.WriteAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure SetDeletionMarkForADocument(Command)
	
	TMCommonUseClient.SetDeletionMarkForADocument(ThisObject);
	
EndProcedure

#EndRegion

#Region TypesOfPrices
 
&AtClient
Procedure FillInPricesByPriceKind(Command)

	If Not CheckForSelectedLines() Then
		Return;
	EndIf;

	If Not ItemIsFilledInAtOnlyPosition() Then
		ShowMessageBox(, NStr("vi = 'Để điền giá, cần phải chọn mặt hàng từ danh mục';
								|ru = 'Для заполнения цены необходимо выбрать номенклатуру из справочника';
								|en = 'To fill in the price, select an item from the catalog'; fa = 'To fill in the price, select an item from the catalog';
								|it = 'To fill in the price, select an item from the catalog';
								|pl = 'To fill in the price, select an item from the catalog';
								|tr = 'Fiyatın girilmesi için katalogdan ürün seçilmelidir'"));
		Return;
	EndIf;
	
	If Not EnterprisePricesFillingClient.ItIsNecessaryToFillInPricesByTypeOfPrices(Object, "Goods", NStr("vi = 'Hàng hóa';
																										|ru = 'Товары';
																										|en = 'Goods'; fa = 'کالاها';
																										|it = 'Goods';
																										|pl = 'Goods';
																										|tr = 'Mallar'")) Then
		Return;
	EndIf;
		
	PriceSelectionOptions = EnterprisePricesFillingClient.NewFillOptionsSelectPriceType();
	PriceSelectionOptions.CallbackDescription = DescriptionOfPriceTypeSelectionNotification(False);
		
	EnterprisePricesFillingClient.ChooseTypeOfPrices(PriceSelectionOptions);
	
EndProcedure

&AtClient
Procedure FillInPricesBySupplierPriceType(Command)
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	If Not ItemIsFilledInAtOnlyPosition() Then
		ShowMessageBox(, NStr("vi = 'Để điền giá, cần phải chọn mặt hàng từ danh mục';
								|ru = 'Для заполнения цены необходимо выбрать номенклатуру из справочника';
								|en = 'To fill in the price, select an item from the catalog'; fa = 'To fill in the price, select an item from the catalog';
								|it = 'To fill in the price, select an item from the catalog';
								|pl = 'To fill in the price, select an item from the catalog';
								|tr = 'Fiyatın girilmesi için katalogdan ürün seçilmelidir.'"));
		Return;
	EndIf;
	
	If Not PartnerPricesFillingClient.ItIsNecessaryToFillInPricesAccordingToSupplierSPriceType(Object, "Goods", NStr("vi = 'Hàng hóa';
																													|ru = 'Товары';
																													|en = 'Goods'; fa = 'کالاها';
																													|it = 'Goods';
																													|pl = 'Goods';
																													|tr = 'Mallar'")) Then
		Return;
	EndIf;
	
	CallbackDescription = DescriptionOfPriceTypeSelectionNotification(True);
	
	PartnerPricesFillingClient.SelectVendorsPriceType(CallbackDescription);
	
EndProcedure

#EndRegion
 
#Region CommercialProposals

&AtClient
Procedure StartFillingInPricesForCommercialOffers(Command)
	
	ClearMessages();
	
	If Not CheckForSelectedLines() Then
		Return;
	EndIf;
	
	FillingResult = FillInPricesForCommercialOffers(Items.Goods.SelectedRows);
	
	OnePosition = OnePosition(ThisObject);
	
	For Each ItemsLineNumber In FillingResult.LineNumbersWithBlankPurchaseConditions Do
		
		If OnePosition Then
			
			ErrorText = NStr("vi = 'Không thể điền giá. Vui lòng kiểm tra sự tương ứng của hàng hóa trong giấy đề nghị và đề xuất thương mại';
							|ru = 'Не удалось заполнить цену. Проверьте соответствие номенклатуры в заявке и запросе коммерческого предложения';
							|en = 'Cannot fill in the price. Check whether the items in the request and the request for quotation match'; fa = 'Cannot fill in the price. Check whether the items in the request and the request for quotation match';
							|it = 'Cannot fill in the price. Check whether the items in the request and the request for quotation match';
							|pl = 'Cannot fill in the price. Check whether the items in the request and the request for quotation match';
							|tr = 'Fiyat girilmedi. Talep ve satış teklifi sorgusundaki ürünlerin eşleştiğini kontrol edin'");
			
			PathToItem = TMCommonUseClientServer.PathToElementOfCurrentRowOfFormTable(
				"Goods",
				"Price");
				
			CommonClient.MessageToUser(
				ErrorText,
				,// When an error is displayed, an object cannot be specified in the "element".
				PathToItem);
				
		Else
			
			ErrorText = StrTemplate(
				NStr("vi = 'Đối với dòng %1 danh sách ""Hàng hóa"" không tìm thấy giá trong các đề xuất thương mại đã chọn. ';
					|ru = 'Для строки %1 списка ""Товары"" не найдена цена в выбранных коммерческих предложениях.';
					|en = 'No price is found for line %1 of the ""Goods"" list in the selected sales quotations.'; fa = 'No price is found for line %1 of the ""Goods"" list in the selected sales quotations.';
					|it = 'No price is found for line %1 of the ""Goods"" list in the selected sales quotations.';
					|pl = 'No price is found for line %1 of the ""Goods"" list in the selected sales quotations.';
					|tr = '""Mallar"" listesindeki %1 satırı için seçili satış tekliflerinde fiyat bulunamadı.'"),
				ItemsLineNumber);
				
			PathToItem = CommonClientServer.PathToTabularSection(
				"Object.Goods",
				ItemsLineNumber,
				"Price");
				
			CommonClient.MessageToUser(
				ErrorText,
				,
				PathToItem);
			
		EndIf;
		
	EndDo;
	
	If FillingResult.Cancel Then
		
		ShowMessageBox(, FillingResult.ErrorText);
		
	ElsIf Not OnePosition(ThisObject) Then
		
		NumberOfRawRows = FillingResult.LineNumbersWithBlankPurchaseConditions.Count();
		
		ThereAreFilledLines = Items.Goods.SelectedRows.Count() > NumberOfRawRows;
		If ThereAreFilledLines Then
			MessageText = NStr("vi = 'Đã điền đơn giá.';
								|ru = 'Цены заполнены.';
								|en = 'Prices are filled in.'; fa = 'Prices are filled in.';
								|it = 'Prices are filled in.';
								|pl = 'Prices are filled in.';
								|tr = 'Fiyatlar girildi.'");
		Else
			MessageText = NStr("vi = 'Không thể điền đơn giá.';
								|ru = 'Не удалось заполнить цены.';
								|en = 'Cannot fill in prices.'; fa = 'Cannot fill in prices.';
								|it = 'Cannot fill in prices.';
								|pl = 'Cannot fill in prices.';
								|tr = 'Fiyatlar girilemedi.'");
		EndIf;
		
		ExplanationText = StrTemplate(NStr("vi = 'Đơn giá đã được điền trong %1 trên %2 dòng.';
											|ru = 'Цены заполнены в %1 из %2 строк.';
											|en = 'Prices are filled in %1 of %2 lines.'; fa = 'Prices are filled in %1 of %2 lines.';
											|it = 'Prices are filled in %1 of %2 lines.';
											|pl = 'Prices are filled in %1 of %2 lines.';
											|tr = 'Fiyatlar %2 satırın %1''nde girildi.'"),
			Items.Goods.SelectedRows.Count() - NumberOfRawRows,
			Items.Goods.SelectedRows.Count());
			
		ShowUserNotification(MessageText,, ExplanationText, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region IntegratedSubsystems

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeExecute(Command)
	ClearMessages();
	Notification = New CallbackDescription("SearchByBarcodeCompletion", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
EndProcedure

&AtClient
Procedure ImportDataFromPDT(Command)
	
	ClearMessages();
	PeripheralsPortableDataTerminalsServerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

#EndRegion

#Region FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region Properties

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure InsertRows(Command)
	
	NumberOfProductsBeforeInsertion = Object.Goods.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.Goods.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.Goods.SelectedRows.Count());
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure ProvidedByPurchaseOnChangeATServer()
	
	DisplayPurchaseAttributes = Documents.ApplicationForCollateral.DisplayPurchaseAttributes(Object);
	
	SetValueInCache(FormCache,
		"DisplayPurchaseAttributes",
		DisplayPurchaseAttributes);
	UseBDRLimits = GetFunctionalOption("UseIEBLimitsOnConsumption")
		Or GetFunctionalOption("UseIEBLimitsOnPurchases") And Object.SuppliedByPurchase;
	SetValueInCache(FormCache, "UseBDRLimits", UseBDRLimits);
	
	If Not UseBDRLimits Then
		Object.LineOfBusiness = Undefined;
		For Each TSRow In Object.Goods Do
			TSRow.BudgetFlowItem = Undefined;
		EndDo;
	EndIf;
	ArticleSelectionOptions = Documents.ApplicationForCollateral.ItemsAndDimensionsSelectionParameters(Object.SuppliedByPurchase);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ArticleSelectionOptions);
	
	If DisplayPurchaseAttributes And Not ValueIsFilled(Object.Currency) Then
		// We don't overfill it if the user already specified the value earlier when working with the form and re-selects the flag value.
		Object.Currency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	EndIf;
	
	If DisplayPurchaseAttributes And Not ValueIsFilled(Object.Currency) Then
		// Repeated attempt to fill in the currency if the company is not filled in.
		Object.Currency = SettingsValueCached.DefaultBaseCurrency();
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
	IssuePurchaseSupplyFields();
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	
EndProcedure

&AtServer
Procedure CurrencyWhenChangedOnServer(NewCurrency, RecalculateAmounts)
	
	If RecalculateAmounts Then
		ExecuteRecalculateDocumentAmounts(DocumentCurrency, NewCurrency);
	EndIf;
	
	DocumentCurrency = Object.Currency;
	
EndProcedure

&AtServer
Procedure ExecuteRecalculateDocumentAmounts(OldCurrency, NewCurrency)
	
	If OldCurrency <> NewCurrency Then
		
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculateAmount");
		
		DocumentDate = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
		BaseCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		StructureOfOldCurrencyRates = ProcessingOfExchangeRatesTM.GetCurrencyRate(OldCurrency, DocumentDate, BaseCurrency);
		StructureOfNewCurrencyRates  = ProcessingOfExchangeRatesTM.GetCurrencyRate(NewCurrency,  DocumentDate, BaseCurrency);
		
		For Each CurRow In Object.Goods Do
			
			CurRow.Price = ProcessingOfExchangeRatesTM.ConvertAtRate(
				CurRow.Price,
				StructureOfOldCurrencyRates,
				StructureOfNewCurrencyRates);
			
		EndDo;
		
		BatchProcessingOfTablePartServer.TreatTS(
			Object.Goods,
			StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ActivateLineOfSinglePosition()
	
	If Items.GroupPages.CurrentPage <> Items.ItemPage Then 
		Return;
	EndIf;
	
	If Items.Goods.CurrentRow <> Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Goods) Then
		Return;
	EndIf;
	
	Items.Goods.CurrentRow = Object.Goods.Get(0).GetID();
		
EndProcedure

&AtClient
Function CheckForSelectedLines(MultipleSelectionMode = True)
	
	WarningText = "";
	
	If Object.Goods.Count() = 0 Then
		
		WarningText = NStr("vi = 'Chưa điền bảng hàng hóa.';
							|ru = 'Таблица товаров не заполнена.';
							|en = 'Add items to the order.'; fa = 'Add items to the order.';
							|it = 'La tabella delle merci non è compilata.';
							|pl = 'Nie wypełniono tabeli towarów.';
							|tr = 'Mal tablosu eksiktir.'");
		
	ElsIf Items.Goods.SelectedRows.Count() = 0 Then
		
		If MultipleSelectionMode Then
			WarningText = NStr("vi = 'Trong bảng hàng hóa không có dòng đã chọn';
								|ru = 'В таблице товаров отсутствуют выделенные строки.';
								|en = 'Select at least one item.'; fa = 'Select at least one item.';
								|it = 'Nella tabella delle merci non ci sono righe selezionate.';
								|pl = 'Brak wybranych wierszy w tabeli towarów.';
								|tr = 'Mallar tablosunda seçili satır yoktur.'");
		Else
			WarningText = NStr("vi = 'Cần chọn dòng hàng hóa.';
								|ru = 'Необходимо выделить строку товаров.';
								|en = 'Select the goods line.'; fa = 'Select the goods line.';
								|it = 'Select the goods line.';
								|pl = 'Select the goods line.';
								|tr = 'Ürün satırı seçilmelidir.'");
		EndIf;
		
	EndIf;
	
	CheckPassed = IsBlankString(WarningText);
	If Not CheckPassed Then
		ShowMessageBox(Undefined, WarningText);
	EndIf;
	
	Return CheckPassed;
	
EndFunction

&AtClient
Function ItemIsFilledInAtOnlyPosition()
	
	Return Not OnePosition(ThisObject)
		Or ValueIsFilled(Items.Goods.CurrentData.Products);
	
EndFunction

&AtClientAtServerNoContext
Function OnePosition(Form)
	
	Return Form.Items.GroupPages.CurrentPage = Form.Items.ItemPage;
	
EndFunction

#Region TypesOfPrices

&AtClient
Function DescriptionOfPriceTypeSelectionNotification(TheseArePurchasePrices)
	Return New CallbackDescription("FillInPricesByPriceKindCompletion", ThisObject, TheseArePurchasePrices);
EndFunction

&AtClient
Procedure FillInPricesByPriceKindCompletion(PriceKind, TheseArePurchasePrices) Export
	
	If Not ValueIsFilled(PriceKind) Then
		Return;
	EndIf;
	
	ClearMessages();
	
	PricesCalculated = True;
	FillInPricesByPriceKindServer(PriceKind, TheseArePurchasePrices);
	
	If TheseArePurchasePrices Then
		PartnerPricesFillingClient.NotifyAboutEndOfFillingInPricesByTypeOfSupplierSPrice(PricesCalculated, PriceKind);
	Else
		SalesClient.NotifyAboutEndOfFillingInPricesByTypeOfPrices(PricesCalculated, PriceKind);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPricesByPriceKindServer(PriceKind, TheseArePurchasePrices)
	
	SelectedRows = New Array;
	For Each RowID In Items.Goods.SelectedRows Do
		RowOfGoods = Object.Goods.FindByID(RowID);
		SelectedRows.Add(RowOfGoods);
	EndDo;
	
	ObjectWithPriceType = New Structure;
	ObjectWithPriceType.Insert("Date", Object.Date);
	ObjectWithPriceType.Insert("Organization", Object.Organization);
	ObjectWithPriceType.Insert("Currency", Object.Currency);
	ObjectWithPriceType.Insert("PriceKind", PriceKind);
	ObjectWithPriceType.Insert("Partner", Catalogs.Partners.EmptyRef());
	
	StructureOfActions = New Structure;
	
	If TheseArePurchasePrices Then
		
		ObjectWithPriceType.Partner = Catalogs.VendorPriceTypes.OwnerOfPriceType(PriceKind);
		FillParameters = BatchProcessingOfTablePartClientServer.GetStructureForFillingInPurchasePriceInTSLine(
			ObjectWithPriceType,
			"PriceKind");
			
		StructureOfActions.Insert("FillInPurchasePrice", FillParameters);
		
	Else
		
		FillParameters = BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(
			ObjectWithPriceType,
			True);
		
		StructureOfActions.Insert("FillInSalePrice", FillParameters);
		
	EndIf;
	
	StructureOfActions.Insert("RecalculateAmount");
	BatchProcessingOfTablePartServer.ProcessTSStrings(SelectedRows, StructureOfActions, Object.Goods);
	
EndProcedure

#EndRegion

#Region CommercialProposals

&AtServer
Function FillInPricesForCommercialOffers(Val RowsIDs)
	
	LineNumbers = New Array;
	For Each RowID In RowsIDs Do
		RowOfGoods = Object.Goods.FindByID(RowID);
		LineNumbers.Add(RowOfGoods.LineNumber);
	EndDo;
	
	FillParameters = CommercialProposalsDocumentsTM.ParametersForFillingInTermsOfPurchaseForCommercialOffers();
	FillParameters.Document = Object.Ref;
	FillParameters.DateOfCourse = ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate());
	FillParameters.Currency = Object.Currency;
	
	FillParameters.ThereIsItemLine = True;
	FillParameters.LineNumbers = LineNumbers;
	
	FillParameters.ActionsWithModifiedStrings.Insert("RecalculateAmount");
	
	FillingResult = CommercialProposalsDocumentsTM.FillInTermsOfPurchaseBasedOnCommercialOffers(Object.Goods, FillParameters);
	
	// Switching the page if new lines have been added:
	FillInValueOfGoodsSwitch();
	SetItemsPage(ThisObject);
	
	ReturnValue = New Structure;
	ReturnValue.Insert("Cancel", FillingResult.Cancel);
	ReturnValue.Insert("ErrorText", FillingResult.ErrorText);
	ReturnValue.Insert("LineNumbersWithBlankPurchaseConditions", FillingResult.LineNumbersWithBlankPurchaseConditions);
	
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region Protocol

&AtClient
Procedure Attachable_ONChangeOfProtocol(ChangesDetails, AdditionalParameters = Undefined) Export
	
	StatusChangedOnServer();
	
EndProcedure

&AtServer
Procedure StatusChangedOnServer()
	SetCacheRecordingMode();
	FormControl();
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#Region DocumentRecording

&AtServer
Procedure SetCacheRecordingMode()
	
	SetValueInCache(
		FormCache,
		"WriteMode",
		Documents.ApplicationForCollateral.WriteMode(Object));
	
EndProcedure

&AtClient
Procedure Attachable_ProcessObjectEntry()
	
	TMCommonUseClient.ProcessObjectEntryInForm(ThisObject, ParametersForRecording);
	
EndProcedure

&AtClient
Procedure Attachable_CloseForm()
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region ProductsAsAString

&AtClient
Function ItemSelectionData(Val SearchString)
	
	PickingParameters = New Structure;
	PickingParameters.Insert("Filter", FilterOfProductItem());
	PickingParameters.Insert("SearchString", SearchString);
	
	Return GetChoiceData(Type("CatalogRef.Products"), PickingParameters);
	
EndFunction

&AtServerNoContext
Function ItemCorrespondsToSelectionParameters(Products)
	
	Filter = FilterOfProductItem();
	AttributesNames = CommonClientServer.StructureKeysToString(Filter, ",");
	AttributesValues = Common.ObjectAttributesValues(Products, AttributesNames);
	
	ThereIsDiscrepancy_ = False;
	For Each KeyAndValue In Filter Do
		AttributeName = KeyAndValue.Key;
		FilterValue = KeyAndValue.Value;
		
		If TypeOf(FilterValue) = Type("Array") Then
			ThereIsDiscrepancy_ = FilterValue.Find(AttributesValues[AttributeName]) = Undefined;
		Else
			ThereIsDiscrepancy_ = FilterValue <> AttributesValues[AttributeName];
		EndIf;
		
		If ThereIsDiscrepancy_ Then
			Break;
		EndIf;
		
	EndDo;
	
	Return Not ThereIsDiscrepancy_;
	
EndFunction

&AtClientAtServerNoContext
Function FilterOfProductItem()
	
	Filter = New Structure;
	Filter.Insert("ItemsType", ProductsClientServer.SelectionByProductReusablePackagingServiceWork(False));
	
	Return Filter;
	
EndFunction

&AtClient
Procedure WhenChangingProducts(TableRow)
	
	ClearMessages();
	
	FillInItemSpecifiedAttribute(TableRow);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", TableRow.Package);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	IssueItemDescription(ThisObject);
	FillInGoodsMeasurementUnitsPrompt(ThisObject);
	
EndProcedure

&AtServer
Procedure FillInItemWithLine(ReadyForProcessing_)
	
	Products = Object.Goods.Unload(ReadyForProcessing_).UnloadColumn("Products");
	ProductsAsAString = ProductsAsAString(Products);
	
	For Each RowOfGoods In ReadyForProcessing_ Do
		RowOfGoods.ProductsAsAString = ProductsAsAString.Get(RowOfGoods.Products);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function ProductsAsAString(Products)

	ReturnValue = New Map;

	Query = New Query;
	Query.Text =
	"SELECT
	|	Products.Ref AS Products,
	|	PRESENTATION(Products.Ref) AS ProductsAsAString
	|FROM
	|	Catalog.Products AS Products WHERE Ref IN (&Products)";

	Query.SetParameter("Products", Products);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ReturnValue.Insert(Selection.Products, Selection.ProductsAsAString);
	EndDo;

	Return ReturnValue;

EndFunction

#Region ProductPicture

&AtServer
Procedure MarkSpecifiedItem()
	
	For Each LineProducts_ In Object.Goods Do
		FillInItemSpecifiedAttribute(LineProducts_);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInItemSpecifiedAttribute(TableRow)
	TableRow.ItemIsSpecified = ValueIsFilled(TableRow.Products);	
EndProcedure

#EndRegion

#EndRegion

#Region FormControl

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInValueOfGoodsSwitch(); // It is not called after recording, so as not to switch the form.
	FillInFormDetails();
	FormControl();

EndProcedure

&AtServer
Procedure FillInFormDetails()
	
	// It is used as the previous value and is displayed even when the F.O. "Use as much as possible" is turned off: 
	DocumentCurrency = Object.Currency; 
	
	OperationsWithDocumentProtocol.FillInFormDetails(ThisObject);
	
	InitializeFormCache();
	MarkSpecifiedItem();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods, StructureOfActions);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject);
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject);
	
EndProcedure

&AtServer
Procedure FormControl()
	
	IssueItemDescription(ThisObject);
	IssueLimitFields();
	IssuePurchaseSupplyFields();
	SetItemsPage(ThisObject);
	
	CheckingHeader = Enums.ProvisionRequestStatuses.AgreedUpon(Object.Status);
	HeaderProperties = New Structure;
	HeaderProperties.Insert("AutoMarkIncomplete", CheckingHeader);
	If Not HeaderProperties.AutoMarkIncomplete Then
		HeaderProperties.Insert("MarkIncomplete", False);
	EndIf;
	
	For Each AttributeName In Documents.ApplicationForCollateral.NamesOfHeaderDetails() Do
		SetAttributeProperties(AttributeName, HeaderProperties);
	EndDo;
	
EndProcedure

&AtServer
Procedure SetAttributeProperties(Var_AttributeName, Properties)
	
	ItemsNames = New Array;
	PrefixOfDetailsOfTablePart = "Goods.";
	If StrStartsWith(Var_AttributeName, PrefixOfDetailsOfTablePart) Then
		
		ItemsNames.Add(StrReplace(Var_AttributeName, PrefixOfDetailsOfTablePart, "OwnGoods"));
		ItemsNames.Add(StrReplace(Var_AttributeName, PrefixOfDetailsOfTablePart, "Goods"));
		
	Else 
		
		ItemsNames.Add(Var_AttributeName);
		
	EndIf;
	
	// Duplicates of elements:
	If Var_AttributeName = "Currency" Then
		ItemsNames.Add(Items.CurrencyLimits.Name);
	EndIf;
	
	For Each TagName In ItemsNames Do
		
		Item = Items.Find(TagName);
		If Item = Undefined Then
			Continue;
		EndIf;
		
		FillPropertyValues(Item, Properties);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure IssuePurchaseSupplyFields()
	
	If Documents.ApplicationForCollateral.UseBDRLimits() Then
		// The currency is always displayed.
		Items.PagesAreProvidedByPurchase.CurrentPage = Items.PageIsProvidedByPurchaseLimits;
	Else
		Items.PagesAreProvidedByPurchase.CurrentPage = Items.PageIsProvidedByPurchase;
	EndIf;
	UseBDRLimits = ValueFromTheCache(FormCache, "UseBDRLimits");
	Items.LineOfBusiness.Visible = UseBDRLimits;
	Items.ItemBudgetFlowItem.Visible = UseBDRLimits;
	Items.GoodsBudgetFlowItem.Visible = UseBDRLimits;
	
	Items.SuppliedByPurchase.Title = 
		?(Object.SuppliedByPurchase And ValueFromTheCache(FormCache, "UseMultipleCurrencies"),
		NStr("vi = 'Được đáp ứng bằng mua hàng bằng loại tiền:';
			|ru = 'Обеспечивается закупкой в валюте:';
			|en = 'Supplied by purchase in foreign currency:'; fa = 'تأمین‌شده با خرید به ارز خارجی:';
			|it = 'Supplied by purchase in foreign currency:';
			|pl = 'Supplied by purchase in foreign currency:';
			|tr = 'Para birimi cinsinden satın almayla sağlanır:'"),
		NStr("vi = 'Được đáp ứng bằng mua hàng';
			|ru = 'Обеспечивается закупкой';
			|en = 'Supplied by purchase'; fa = 'تأمین‌شده با خرید';
			|it = 'Supplied by purchase';
			|pl = 'Supplied by purchase';
			|tr = 'Satın almayla sağlanır'"));
	
	VisibilityStatusesOfCommandFillInPrices = New Array;
	VisibilityStatusesOfCommandFillInPrices.Add(Enums.ProvisionRequestStatuses.AwaitingApproval);
	VisibilityStatusesOfCommandFillInPrices.Add(Enums.ProvisionRequestStatuses.OnExecution);
	
	ItemVisibility =
		ValueFromTheCache(FormCache, "UseRequestsForCommercialOffersFromSuppliers")
		And VisibilityStatusesOfCommandFillInPrices.Find(Object.Status) <> Undefined
		And Object.SuppliedByPurchase;
	
	Items.GoodsFillInPricesForCommercialOffers.Visible = ItemVisibility;
	Items.ItemFillInPricesForCommercialOffers.Visible = ItemVisibility;
	
	CheckAttributes = Documents.ApplicationForCollateral.CheckPurchaseAttributes(Object);
	Display_Attributes = ValueFromTheCache(FormCache, "DisplayPurchaseAttributes");
	
	Items.ItemFillInPricesByTypeOfPrices.Visible = Display_Attributes;
	Items.GoodsFillInPricesByPriceKind.Visible = Display_Attributes;
	Items.ItemFillInPricesAccordingToTypeOfPricesOfSupplier.Visible = Display_Attributes;
	Items.GoodsFillInPricesBySupplierSPriceType.Visible = Display_Attributes;
	
	MutableProperties = New Structure;
	MutableProperties.Insert("Visible", Display_Attributes); 
	MutableProperties.Insert("AutoMarkIncomplete", CheckAttributes);
	If Not MutableProperties.AutoMarkIncomplete Then
		MutableProperties.Insert("MarkIncomplete", False);
	EndIf;

	For Each AttributeName In Documents.ApplicationForCollateral.NamesOfPurchaseDetails() Do
		SetAttributeProperties(AttributeName, MutableProperties);
	EndDo;
	
	SetVisibilityOfTotals(ThisObject);
	
EndProcedure

&AtServer
Procedure IssueLimitFields()
	
	// The visibility of the fields is regulated by the functional option, we change only the verification of the values:
	CheckAttributes = Documents.ApplicationForCollateral.CheckAttributesOfLimitAnalyst(Object);
	MutableProperties = New Structure; 
	MutableProperties.Insert("AutoMarkIncomplete", CheckAttributes);
	If Not MutableProperties.AutoMarkIncomplete Then
		MutableProperties.Insert("MarkIncomplete", False);
	EndIf;
	
	For Each AttributeName In Documents.ApplicationForCollateral.NamesOfDetailsOfLimitingAnalyst() Do
		SetAttributeProperties(AttributeName, MutableProperties);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure IssueItemDescription(Form)
	
	ItemVariantsAreUsed = False;
	If ValueIsFilled(Form.Object.Goods) Then
		ItemVariantsAreUsed = Form.Object.Goods[0].ItemVariantsAreUsed;
	EndIf;
	
	Items = Form.Items;
	Items.ProductCharacteristics_.AutoMarkIncomplete = ItemVariantsAreUsed;
	Items.ProductCharacteristics_.ReadOnly = Not ItemVariantsAreUsed;
	If ItemVariantsAreUsed Then
		Items.ProductCharacteristics_.InputHint = "";
	Else
		Items.ProductCharacteristics_.InputHint = NStr("vi = '<không sử dụng đặc tính>';
														|ru = '<характеристики не используются>';
														|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
														|it = '<le caratteristiche non vengono usate>';
														|pl = '<charakterystyki nie dotyczą>';
														|tr = '<varyantlar kullanılmamaktadır>'");
		Items.ProductCharacteristics_.MarkIncomplete = False;
	EndIf;

EndProcedure

#Region UnitOfMeasure

&AtClientAtServerNoContext
// There is a server call!
Procedure FillInGoodsMeasurementUnitsPrompt(Form)
	
	Items = Form.Items;
	If Items.GroupPages.CurrentPage = Items.ItemPage Then
		Items.ItemPackagingUnit.InputHint = HintOfItemSUnitOfMeasurement(Form.Object.Goods[0].Products);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function HintOfItemSUnitOfMeasurement(Products)
	
	If Not ValueIsFilled(Products) Then
		Return "";
	EndIf;
	
	Return Common.ObjectAttributesValues(
		Products,
		New Structure("UnitOfMeasure", "UnitOfMeasure.Presentation")).UnitOfMeasure;
	
EndFunction

#EndRegion

&AtClientAtServerNoContext
Procedure SetItemsPage(Form)
	
	Items = Form.Items;
	Items.GroupPages.CurrentPage = Items.Find(Form.ItemSwitch);
	SetVisibilityOfTotals(Form);
	FillInGoodsMeasurementUnitsPrompt(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfTotals(Form)
	
	Items = Form.Items;
	DisplaySummaryTotals = ValueFromTheCache(Form.FormCache, "DisplayPurchaseAttributes")
		// For one line, the result is the line itself:
		And Items.GroupPages.CurrentPage = Items.ItemsTablePage; 
		
	Items.TotalAmount_5.Visible = DisplaySummaryTotals;
	Items.CurrencyLabel.Visible = DisplaySummaryTotals;
	
EndProcedure

#Region ItemPages

&AtServer
Procedure FillInValueOfGoodsSwitch()
	
	ItemSwitch = ?(Object.Goods.Count() = 1,
		Items.ItemPage.Name,
		Items.ItemsTablePage.Name);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCache

&AtServer
Procedure InitializeFormCache()

	FormCache = New Structure;
	
	SetValueInCache(FormCache,
		"UseMultipleCurrencies",
		GetFunctionalOption("UseMultipleCurrencies"));
	
	SetValueInCache(FormCache,
		"ItemAddendum",
		AccessRight("Insert", Metadata.Catalogs.Products));
		
	SetValueInCache(FormCache,
		"NameOfItemChangeEvent",
		"");
		
	SetAssortmentControlInCache(FormCache,
		Object.Date,
		Object.Warehouse);
	
	UseBDRLimits = False; // The default value for UT.
	UseBDRLimits = GetFunctionalOption("UseIEBLimitsOnConsumption")
		Or GetFunctionalOption("UseIEBLimitsOnPurchases") And Object.SuppliedByPurchase;
	SetValueInCache(FormCache,
		"UseBDRLimits",
		UseBDRLimits);
	
	SetValueInCache(FormCache,
		"DisplayPurchaseAttributes",
		Documents.ApplicationForCollateral.DisplayPurchaseAttributes(Object));
	
	SetValueInCache(FormCache,
		"UseRequestsForCommercialOffersFromSuppliers",
		CommercialProposalsDocumentsTM.UseRequestsForCommercialOffersFromSuppliers());
	
	SetCacheRecordingMode();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetValueInCache(FormCache, PropertyName, PropertyValue)
	
	If Not FormCache.Property(PropertyName) Then
		
		FormCache.Insert(PropertyName);
		
	EndIf;
	
	FormCache[PropertyName] = PropertyValue;
	
EndProcedure

// The value from the cache.
// 
// Parameters:
//  FormCache - Structure - Form Attributes of the same name
//  PropertyName - String - The name of the property in the cache, set via "Set the value of the cache"
// 
// Returns:
//  Arbitrary - Previously saved value
&AtClientAtServerNoContext
Function ValueFromTheCache(FormCache, PropertyName)
	
	Return FormCache[PropertyName];
	
EndFunction

&AtServerNoContext
Procedure SetAssortmentControlInCache(FormCache, Date, Warehouse)
	
	SetValueInCache(FormCache,
		"ControlProductRange",
		ProductRangeServerCached.ControlProductRange(Warehouse, Date));
	
EndProcedure

#EndRegion

#Region IntegratedSubsystems

#Region BarcodesAndTradeEquipment

&AtClient
Procedure SearchByBarcodeCompletion(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
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
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	StructureOfActionsWithAddedStrings = New Structure;
	StructureOfActionsWithAddedStrings.Insert("FillInFeatureAttribute", 
		New Structure("Products", "ItemVariantsAreUsed"));
	AddActionsOnChangingNumberOfPackages(StructureOfActionsWithAddedStrings, ThisObject);
	
	StructureOfActionsWithModifiedStrings = New Structure;
	AddActionsOnChangingNumberOfPackages(StructureOfActionsWithModifiedStrings, ThisObject);
	
	StructureOfActions = BarcodingOfItemsClient.BarcodeProcessingParameters();
	StructureOfActions.Barcodes                              = BarcodeData_5;
	StructureOfActions.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	StructureOfActions.StructureOfActionsWithModifiedStrings  = StructureOfActionsWithModifiedStrings;
	
	If ValueFromTheCache(FormCache, "ControlProductRange") Then
		AssortmentVerificationParameters = ProductRangeClientServer.AssortmentVerificationParameters();
		AssortmentVerificationParameters.Ref                  = Object.Ref;
		AssortmentVerificationParameters.Warehouse                   = Object.Warehouse;
		AssortmentVerificationParameters.Date                    = Object.Date;
		AssortmentVerificationParameters.NameOfAssortmentResource  = "PurchasesAreAllowed";
		AssortmentVerificationParameters.CheckedYouCanAdd = True;
		AssortmentVerificationParameters.AllowAdding     = True;
		AssortmentVerificationParameters.MessageText =
			NStr("vi = 'Hàng hóa %1 không thuộc phân loại của cửa hàng. Không nên đặt mặt hàng này.';
				|ru = 'Товар %1 не включен в ассортимент магазина. Заказывать его не рекомендуется.';
				|en = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.'; fa = 'Item ""%1"" is not in this selling point''s product range. Please reconsider adding it to the order.';
				|it = 'Il prodotto %1 non è incluso nell''assortimento del negozio. Ordinarlo non è consigliabile.';
				|pl = 'Towar %1 nie jest włączony do asortymentu sklepu. Nie zaleca się zamawiać go.';
				|tr = 'Ürün%1 mağazanın ürün yelpazesine dahil değildir. Sipariş edilmesi tavsiye edilmez.'");
		
		StructureOfActions.AssortmentVerificationParameters = AssortmentVerificationParameters;
	EndIf;
	
	ProcessBarcodesServer(StructureOfActions, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(StructureOfActions,
		CachedValues,
		ThisObject);
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ItemRowIds = ItemRowIds();
	
	BarcodingOfItemsServer.ProcessBarcodes(
		ThisObject,
		Object,
		StructureOfActionParameters,
		CachedValues);
	
	IdsOfAddedRows = CommonClientServer.ArraysDifference(
		ItemRowIds(),
		ItemRowIds);
	
	AddedRows = New Array;
	For Each AddedRowID In IdsOfAddedRows Do
		
		RowOfGoods = Object.Goods.FindByID(AddedRowID);
		AddedRows.Add(RowOfGoods);
		FillInItemSpecifiedAttribute(RowOfGoods);
		
	EndDo;
	
	FillInItemWithLine(AddedRows);
	
EndProcedure

&AtServer
Function ItemRowIds()
	
	ReturnValue = New Array;
	For Each RowOfGoods In Object.Goods Do
		ReturnValue.Add(RowOfGoods.GetID());
	EndDo;
	Return ReturnValue;
	
EndFunction

#EndRegion

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
    AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
    AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Properties

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region IntegrationWith1CDocumentManagementSubsystem

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.Goods, Items.Goods.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	
	BufferColumns = New Array;
	BufferColumns.Add("Products");
	BufferColumns.Add("Characteristic");
	BufferColumns.Add("Package");
	BufferColumns.Add("NumberOfPackages");
	BufferColumns.Add("Price");
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, BufferColumns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	RowsToProcess = New Array;
	For Each SourceRow In TableOfGoods Do
		
		RowOfGoods = Object.Goods.Add();
		FillPropertyValues(RowOfGoods, SourceRow);
		FillInItemSpecifiedAttribute(RowOfGoods);
		RowsToProcess.Add(RowOfGoods);
		
	EndDo;
	
	FillInItemWithLine(RowsToProcess);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", 
		New Structure("Products", "ItemVariantsAreUsed"));
	AddActionsOnChangingNumberOfPackages(StructureOfActions, ThisObject);
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AccessibilityValue)
	
	ItemsNames = New Array;
	ItemsNames.Add("GoodsInsertRows");
	ItemsNames.Add("GoodsContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Form.Items,
		ItemsNames,
		"Enabled",
		AccessibilityValue);
	
EndProcedure

#EndRegion

#EndRegion

#Region BatchProcessingOfTablePart

&AtClientAtServerNoContext
Procedure AddActionsOnChangingNumberOfPackages(StructureOfActions, Form)
	
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("RecalculateAmount");
	
EndProcedure

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
